package Cards::Api;
=head NAME

  Cards::Api - Cards api functions

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(in_array);

use Users;
use Cards;

my Users $Users;
my Cards $Cards;

my @status = ('enable', 'disable', 'used', 'deleted', 'returned', 'processing', 'Transferred to production');

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Cards = Cards->new($self->{db}, $self->{admin}, $self->{conf});

  $self->{routes_list} = ();

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }

  return $self;
}

#**********************************************************
=head2 user_routes() - Returns available API paths

  Returns:
    {
      $resource_1_name => [ # $resource_1_name, $resource_2_name - names of API resources. always equals to first path segment
        {
          method  => 'GET',          # HTTP method. Path can be queried only with this method

          path    => '/users/:uid/', # API path. May contain variables like ':uid'.
                                     # these variables will be passed to handler function as argument ($path_params).
                                     # variables are always numerical.
                                     # example: if route's path is '/users/:uid/', and queried URL
                                     # is '/users/9/', $path_params will be { uid => 9 }.
                                     # if credentials is 'USER', variable :uid will be checked to contain only
                                     # authorized user's UID.

          handler => sub {           # handler function, coderef. Arguments that are passed to handler:
            my (
                $path_params,        # params from path. look at docs of path. hashref.
                $query_params,       # params from query. for details look at AXbills::Api::Router::new(). hashref.
                                     # keys will be converted from camelCase to UPPER_SNAKE_CASE
                                     # using AXbills::Base::decamelize unless no_decamelize_params is set
                $module_obj          # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

            $module_obj->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler as $module_obj. optional.

          type    => 'HASH',         # type of returned data. may be 'HASH' or 'ARRAY'. by default (if not set) it is 'HASH'. optional.

          credentials => [           # arrayref of roles required to use this path. if API user is authorized as at least one of
                                     # these roles access to this path will be granted. optional.
            'ADMIN'                  # may be 'ADMIN' or 'USER'
          ],

          no_decamelize_params => 0, # if set, $query_params for handler will not be converted to UPPER_SNAKE_CASE. optional.

          conf_params => [ ... ]     # variables from $conf to be returned in result. arrayref.
                                     # experimental feature, currently disabled
        },
        ...
      ],
      $resource_2_name => [
        ...
      ],
      ...
    }

=cut
#**********************************************************
sub user_routes {
  my $self = shift;

  return [
    {
      method      => 'POST',
      path        => '/user/cards/payment/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $user_info = $Users->info($path_params->{uid});

        return {
          errno  => 10050,
          errstr => 'Operation not allowed',
        } if ($self->{conf}->{CARDS_SKIP_COMPANY} && $user_info->{COMPANY_ID});

        return {
          errno  => 10051,
          errstr => 'No field pin',
        } if (!$query_params->{PIN});

        return {
          errno  => 10052,
          errstr => 'No field serial',
        } if (!$query_params->{SERIAL} && !$self->{conf}->{CARDS_PIN_ONLY});

        my $bruteforce_lim = $self->{conf}->{CARDS_BRUTE_LIMIT} ? $self->{conf}->{CARDS_BRUTE_LIMIT} : 5;
        $Cards->bruteforce_list({ UID => $user_info->{UID} });

        return {
          errno  => 10053,
          errstr => "Bruteforce pin, $Cards->{BRUTE_COUNT} >= $bruteforce_lim",
        } if ($Cards->{BRUTE_COUNT} && $Cards->{BRUTE_COUNT} >= $bruteforce_lim);

        my DBI $db = $self->{db}->{db};
        $db->{AutoCommit} = 0;

        $Cards->cards_info({
          SERIAL    => $self->{conf}->{CARDS_PIN_ONLY} ? '_SHOW' : $query_params->{SERIAL},
          PIN       => $query_params->{PIN},
          PAYMENTS  => 1,
        });

        if ($Cards->{errno}) {
          if ($Cards->{errno} == 2) {
            $Cards->bruteforce_add({ UID => $user_info->{UID}, PIN => $query_params->{PIN} });
            $db->commit();
            $db->{AutoCommit} = 1;
            return {
              errno  => 10054,
              errstr => 'Unknown card',
            };
          }
          else {
            $db->{AutoCommit} = 1;
            return {
              errno  => 10055,
              errstr => "Unknown error happened - $Cards->{errno}",
            };
          }
        }
        elsif ($Cards->{EXPIRE_STATUS} == 1) {
          $db->{AutoCommit} = 1;
          return {
            errno  => 10056,
            errstr => "Card expired. Expire date - $Cards->{EXPIRE}",
          };
        }
        elsif ($Cards->{TOTAL} < 1 || !$Cards->{NUMBER}) {
          $Cards->bruteforce_add({ UID => $user_info->{UID}, PIN => $query_params->{PIN} });
          $db->commit();
          $db->{AutoCommit} = 1;
          return {
            errno  => 10057,
            errstr => 'Unknown card',
          };
        }
        elsif ($user_info->{GID} && $Cards->{ALLOW_GID} && !in_array($user_info->{GID}, [ split(/,\s?/, $Cards->{ALLOW_GID}) ])) {
          $db->{AutoCommit} = 1;
          return {
            errno  => 10058,
            errstr => 'Operation not allowed',
          };
        }
        elsif ($Cards->{SUM} < 1) {
          $db->{AutoCommit} = 1;
          return {
            errno  => 10059,
            errstr => 'Card has wrong sum',
          };
        }
        elsif ($Cards->{UID} && $Cards->{UID} == $user_info->{UID}) {
          $db->{AutoCommit} = 1;
          return {
            errno       => 10060,
            errstr      => 'You already used this card',
            card_status => 'used'
          };
        }
        elsif ($Cards->{STATUS} != 0) {
          $db->{AutoCommit} = 1;
          return {
            errno       => 10060,
            errstr      => 'Card status is ' . ($status[$Cards->{STATUS}] || ''),
            card_status => $status[$Cards->{STATUS}] || ''
          };
        }
        else {
          if ($Cards->{UID}) {
            my $user = Users->new($self->{db}, $self->{admin}, $self->{conf});
            $user->info($Cards->{UID});

            require Log;
            Log->import();
            my $Log = Log->new($self->{db}, $self->{conf});

            $Log->log_list({ USER => $user->{LOGIN} });
            if ($Log->{TOTAL} > 0) {
              $db->{AutoCommit} = 1;
              return {
                errno       => 10061,
                errstr      => 'Card status is used',
                card_status => 'used'
              };
            }
          }

          require Payments;
          Payments->import();
          my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});

          ::cross_modules('pre_payment', {
            USER_INFO    => $user_info,
            SUM          => $Cards->{SUM},
            SKIP_MODULES => 'Cards,Sqlcmd',
            QUITE        => 1,
            SILENT       => 1,
            METHOD       => 2,
            timeout      => 8,
            FORM         => {}
          });

          my $cards_number_length = $self->{conf}->{CARDS_NUMBER_LENGTH} || 11;
          $Payments->add($user_info,{
            SUM          => $Cards->{SUM},
            METHOD       => 2,
            DESCRIBE     => sprintf("%s%." . $cards_number_length . "d", $Cards->{SERIAL}, $Cards->{NUMBER}),
            EXT_ID       => "$Cards->{SERIAL}$Cards->{NUMBER}",
            CHECK_EXT_ID => "$Cards->{SERIAL}$Cards->{NUMBER}",
            TRANSACTION  => 1
          });

          if (!$Payments->{errno}) {
            $Cards->cards_change({
              ID       => $Cards->{ID},
              STATUS   => 2,
              UID      => $user_info->{UID},
              DATETIME => "$main::DATE $main::TIME",
            });

            if ($Cards->{errno}) {
              $db->rollback();
              $db->{AutoCommit} = 1;
              return {
                errno  => 10062,
                errstr => "Unknown error happened - $Cards->{errno}",
              };
            }

            if ($self->{conf}->{CARDS_PAYMENTS_EXTERNAL}) {
              ::_external("$self->{conf}->{CARDS_PAYMENTS_EXTERNAL}", { %$Cards, %$user_info });
            }

            if ($Cards->{COMMISSION}) {
              require Fees;
              Fees->import();
              my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});
              $Fees->take(
                $user_info,
                $Cards->{COMMISSION},
                {
                  DESCRIBE => "Commission $Cards->{SERIAL}$Cards->{NUMBER}",
                  METHOD   => 0,
                }
              );
            }

            if ($Cards->{UID} > 0) {
              my $user_new = Users->new($self->{db}, $self->{admin}, $self->{conf});
              $user_new->info($Cards->{UID});
              $user_new->del();
            }

            if ($Cards->{DILLER_ID}) {
              require Dillers;
              Dillers->import();
              my $Diller = Dillers->new($self->{db}, $self->{admin}, $self->{conf});
              $Diller->diller_info({ ID => $Cards->{DILLER_ID} });
              my $diller_fees = 0;
              if ($Diller->{PAYMENT_TYPE} && $Diller->{PAYMENT_TYPE} == 2 && $Diller->{OPERATION_PAYMENT} > 0) {
                $diller_fees = $Cards->{SUM} / 100 * $Diller->{OPERATION_PAYMENT};
              }
              elsif ($Diller->{DILLER_PERCENTAGE} && $Diller->{DILLER_PERCENTAGE} > 0) {
                $diller_fees = $Diller->{DILLER_PERCENTAGE};
              }

              if ($diller_fees > 0) {
                my $user_new = Users->new($self->{db}, $self->{admin}, $self->{conf});
                $user_new->info($Diller->{UID});

                require Fees;
                Fees->import();
                my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});

                $Fees->take($user_new, $diller_fees, {
                  DESCRIBE => "CARD_ACTIVATE: $Cards->{ID} CARD: $Cards->{SERIAL}$Cards->{NUMBER}",
                  METHOD   => 0,
                });
              }
            }

            $Payments->list({ EXT_ID => "$Cards->{SERIAL}$Cards->{NUMBER}", TOTAL_ONLY => 1 });
            if ($Payments->{TOTAL} <= 1) {
              $db->commit();
            }

            $db->{AutoCommit} = 1;
            ::load_module("AXbills::Templates", { LOAD_PACKAGE => 1 }) if (!exists($INC{"AXbills/Templates.pm"}));
            ::cross_modules('payments_maked', {
              USER_INFO    => $user_info,
              SUM          => $Cards->{SUM},
              SKIP_MODULES => 'Cards,Sqlcmd',
              QUITE        => 1,
              SILENT       => 1,
              METHOD       => 2,
              FORM         => {}
            });

            return {
              result     => "Success payment, ID $Payments->{INSERT_ID}",
              amount     => $Cards->{SUM},
              payment_id => $Payments->{INSERT_ID}
            };
          }
          elsif ($Payments->{errno}) {
            $db->rollback();
            if ($Payments->{errno} == 7) {
              if ($Cards->{STATUS} != 2) {
                $Cards->cards_change({
                  ID       => $Cards->{ID},
                  STATUS   => 2,
                  UID      => $user_info->{UID},
                  DATETIME => "$main::DATE $main::TIME",
                });
              }

              $db->{AutoCommit} = 1;

              return {
                errno       => 10063,
                errstr      => 'Card status is used',
                card_status => 'used'
              };
            }
            else {
              $db->{AutoCommit} = 1;

              return {
                errno       => 10064,
                errstr      => "Payment error $Payments->{errno}",
              };
            }
          }
          else {
            $db->{AutoCommit} = 1;

            return {
              errno       => 10065,
              errstr      => 'Unknown operation happened',
            };
          }
        }
      },
      credentials => [
        'USER'
      ]
    },
  ]
}

1;
