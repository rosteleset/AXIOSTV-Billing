package Card_payment;
use strict;
use warnings FATAL => 'all';
use Cards;
use Encode qw/encode_utf8/;

#**********************************************************
=head2 new($db, $admin, $conf, $bot_api, $bot_db)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $bot, $bot_db) = @_;

  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $conf,
    bot    => $bot,
    bot_db => $bot_db
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return $self->{bot}->{lang}->{ICARDS};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my @keyboard = ();

  my $button = {
    text => "$self->{bot}->{lang}->{CANCEL_TEXT}",
  };
  push (@keyboard, [$button]);

  my $message = $self->{conf}->{TELEGRAM_CARDS_MESSAGE} || $self->{bot}->{lang}->{ENTER_CARD_DATA};

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
    parse_mode   => 'HTML'
  });

  $self->{bot_db}->add({
    UID    => $self->{bot}->{uid},
    BUTTON => "Card_payment",
    FN     => "check_serial",
    ARGS   => '{"serial":"", "pin":""}',
  });

  return 1;
}


#**********************************************************
=head2 click()

=cut
#**********************************************************
sub check_serial {
  my $self = shift;
  my ($attr) = @_;

  my %lang = %{$self->{bot}->{lang}};

  my @status    = ($lang{ENABLE}, $lang{DISABLE}, $lang{USED}, $lang{DELETED}, $lang{RETURNED}, $lang{PROCESSING}, $lang{TRANSFERRED_TO_PRODUCTION});

  if ($attr->{message}->{text}) {
    my $text = encode_utf8($attr->{message}->{text});
    if($text eq $self->{bot}->{lang}->{CANCEL_TEXT}){

      $self->{bot_db}->del($self->{bot}->{uid});
      $self->{bot}->send_message({
        text => "$self->{bot}->{lang}->{SEND_CANCEL}",
      });

      return 0;
    }

    my $user = Users->new($self->{db}, $self->{admin}, $self->{conf});
    $user->info($self->{bot}->{uid});

    if ($self->{conf}->{CARDS_SKIP_COMPANY} && $user->{COMPANY_ID}) {
      $self->{bot}->send_message({
        text         => "$lang{INFO} $lang{ERR_COMPANY_DISABLE}",
        parse_mode   => 'HTML'
      });
      return 0;
    }

    my ($serial, $pin);

    if($self->{conf}->{CARDS_PIN_ONLY}) {
      $pin = $text if ($self->{conf}->{CARDS_PIN_ONLY});
    } else {
      ($serial, $pin) = split '/', $text;
    }
    my $Cards = Cards->new($self->{db}, $self->{admin}, $self->{conf});

    my $BRUTE_LIMIT = ($self->{conf}->{CARDS_BRUTE_LIMIT}) ? $self->{conf}->{CARDS_BRUTE_LIMIT} : 5;
    $Cards->bruteforce_list({ UID => $self->{bot}->{uid} });
    if ($Cards->{BRUTE_COUNT} && $Cards->{BRUTE_COUNT} >= $BRUTE_LIMIT) {

      $self->{bot}->send_message({
        text         => "$self->{bot}->{lang}->{ERROR} $self->{bot}->{lang}->{BRUTE_ATACK}",
        parse_mode   => 'HTML'
      });

      return 0;
    }

    $Cards->cards_info({
      SERIAL => $self->{conf}->{CARDS_PIN_ONLY} ? '_SHOW' : $serial,
      PIN => $pin,
      PAYMENTS => 1,
      COLS_NAME => 1
    });

    if ($Cards->{errno}) {
      if ($Cards->{errno} == 2) {

        $self->{bot}->send_message({
          text         => "$lang{ERROR}: $lang{NOT_EXIST}",
          parse_mode   => 'HTML'
        });

        $Cards->bruteforce_add({ UID => $self->{bot}->{uid}, PIN => $pin });
      }

    } elsif ($Cards->{EXPIRE_STATUS} == 1) {
      $self->{bot}->send_message({
        text         => "$lang{ERROR}: $lang{EXPIRE} '$Cards->{EXPIRE}'",
        parse_mode   => 'HTML'
      });

    }
    elsif ($Cards->{UID} == $self->{bot}->{uid}) {

      $self->{bot}->send_message({
        text         => "$lang{ERROR}: $lang{ERR_WRONG_DATA}",
        parse_mode   => 'HTML'
      });

    }
    elsif ($Cards->{STATUS} != 0) {
      if ($Cards->{STATUS} == 5) {
        $self->{bot}->send_message({
          text         => "$lang{INFO}: $status[$Cards->{STATUS}]",
          parse_mode   => 'HTML'
        });
      }
      else {
        $self->{bot}->send_message({
          text         => "$lang{ERROR}: $status[$Cards->{STATUS}]",
          parse_mode   => 'HTML'
        });
      }

    }
    else {

      my DBI $_db = $self->{db}->{db};
      my $payments  = Payments->new($self->{db}, $self->{admin}, $self->{conf});


      #Sucsess
      main::cross_modules_call('_pre_payment', {
        USER_INFO    => $user,
        SUM          => $Cards->{SUM},
        SKIP_MODULES => 'Cards,Sqlcmd',
        QUITE        => 1,
        SILENT       => 1,
        METHOD       => 2,
        timeout      => 8
      });

      my $cards_number_length = $self->{conf}->{CARDS_NUMBER_LENGTH} || 11;
      $payments->add(
        $user,
        {
          SUM          => $Cards->{SUM},
          METHOD       => 2,
          DESCRIBE     => sprintf("%s%." . $cards_number_length . "d", $Cards->{SERIAL}, $Cards->{NUMBER}),
          EXT_ID       => "$Cards->{SERIAL}$Cards->{NUMBER}",
          CHECK_EXT_ID => "$Cards->{SERIAL}$Cards->{NUMBER}",
          TRANSACTION  => 1
        }
      );

      if (!$payments->{errno}) {

        $Cards->cards_change(
          {
            ID       => $Cards->{ID},
            STATUS   => 2,
            UID      => $self->{bot}->{uid},
            DATETIME => "$main::DATE $main::TIME",
          }
        );

        if ($Cards->{errno}) {
          $_db->rollback();
          $self->{bot}->send_message({
            text         => "$lang{ERROR}: $status[$Cards->{STATUS}]",
            parse_mode   => 'HTML'
          });
          $self->{bot_db}->del($self->{bot}->{uid});
          return 0;
        }

        $self->{bot}->send_message({
          text         => "$lang{ADDED}\n$lang{SUM}: $Cards->{SUM} \n " . (($Cards->{COMMISSION} > 0) ? "$lang{COMMISSION} $Cards->{COMMISSION}\n" : '') . "\n $lang{DEPOSIT}: $user->{DEPOSIT}\n",
          parse_mode   => 'HTML'
        });

        #Make external script
        if ($self->{conf}->{CARDS_PAYMENTS_EXTERNAL}) {
         main::_external("$self->{conf}->{CARDS_PAYMENTS_EXTERNAL}", { %$Cards, %$user });
        }

        if ($Cards->{COMMISSION}) {
          my $Fees = Finance->fees($self->{db}, $self->{admin}, $self->{conf});
          $Fees->take(
            $user,
            $Cards->{COMMISSION},
            {
              DESCRIBE => "$lang{COMMISSION} $lang{ICARDS}: $Cards->{SERIAL}$Cards->{NUMBER}",
              METHOD   => 0,
            }
          );
        }

        #Disable universal card after payment
        if ($Cards->{UID} > 0) {
          my $user_new = Users->new($self->{db}, $self->{admin}, $self->{conf});
          $user_new->info($Cards->{UID});
          $user_new->del();
        }

        if ($Cards->{DILLER_ID}) {
          my $Diller = Dillers->new($self->{db}, $self->{admin}, $self->{conf});
          $Diller->diller_info({ ID => $Cards->{DILLER_ID} });
          my $diller_fees = 0;
          if ($Diller->{PAYMENT_TYPE} && $Diller->{PAYMENT_TYPE} == 2 && $Diller->{OPERATION_PAYMENT} > 0) {
            $diller_fees=$Cards->{SUM} / 100 * $Diller->{OPERATION_PAYMENT};
          }
          elsif ($Diller->{DILLER_PERCENTAGE} && $Diller->{DILLER_PERCENTAGE} > 0) {
            $diller_fees=$Diller->{DILLER_PERCENTAGE};
          }

          if ($diller_fees > 0) {
            my $user_new = Users->new($self->{db}, $self->{admin}, $self->{conf});
            $user_new->info($Diller->{UID});

            my $Fees = Finance->fees($self->{db}, $self->{admin}, $self->{conf});
            $Fees->take(
              $user_new,
              $diller_fees,
              {
                DESCRIBE => "CARD_ACTIVATE: $Cards->{ID} CARD: $Cards->{SERIAL}$Cards->{NUMBER}",
                METHOD   => 0,
              }
            );
          }
        }

        # Check if not card exist
        $payments->list({ EXT_ID => "$Cards->{SERIAL}$Cards->{NUMBER}", TOTAL_ONLY => 1 });
        if ($payments->{TOTAL} <= 1) {
          $_db->commit();
        }


        $_db->{AutoCommit} = 1;
        main::cross_modules_call('_payments_maked', {
          USER_INFO    => $user,
          SUM          => $Cards->{SUM},
          SKIP_MODULES => 'Cards,Sqlcmd',
          QUITE        => 1,
          SILENT       => 1,
          METHOD       => 2,
          timeout      => 8
        });
        $self->{bot_db}->del($self->{bot}->{uid});
        return 0;
      }
      elsif ($payments->{errno}) {
        $_db->rollback();
        if ($payments->{errno} == 7) {
          $self->{bot}->send_message({
            text         => "$lang{ERROR}: $status[2]",
            parse_mode   => 'HTML'
          });

          if ($Cards->{STATUS} != 2) {
            $Cards->cards_change(
              {
                ID       => $Cards->{ID},
                STATUS   => 2,
                UID      => $self->{bot}->{uid},
                DATETIME => "$main::DATE $main::TIME",
              }
            );
          }
        }
        else {
          $self->{bot}->send_message({
            text         => "$lang{ERROR}: ". (($self->{bot}->{uid}) ? '' : "$payments->{errno} $payments->{errstr}"),
            parse_mode   => 'HTML'
          });
        }
      }


      $self->{bot_db}->del($self->{bot}->{uid});
      return 0;
    }
  }

  my $message = $self->{conf}->{TELEGRAM_CARDS_MESSAGE} || $self->{bot}->{lang}->{ENTER_CARD_DATA};

  $self->{bot}->send_message({
    text         => $message,
    parse_mode   => 'HTML'
  });


  return 1;
}

1;