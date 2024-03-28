package Crm::Api;
=head NAME

  Crm::Api - Crm api functions

=head VERSION

  DATE: 20221130
  UPDATE: 20221130
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Crm::db::Crm;

my Crm $Crm;

our %lang;
require 'AXbills/modules/Crm/lng_english.pl';

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type, $html) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

  my %LANG = (%{$lang}, %lang);

  $Crm = Crm->new($db, $admin, $conf);
  $Crm->{debug} = $self->{debug};

  $self->{routes_list} = ();

  if ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  return $self;
}

#**********************************************************
=head2 admin_routes() - Returns available API paths

  ARGUMENTS
    admin_routes: boolean - if true return all admin routes, false - user

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
                        # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

          ->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler a. optional.

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
sub admin_routes {
  my $self = shift;

  return [
    {
      method      => 'POST',
      path        => '/crm/leads/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        if ($query_params->{CURRENT_STEP} && $query_params->{CURRENT_STEP} =~ /\D/g) {
          my $steps = $Crm->crm_progressbar_step_list({
            ID          => '_SHOW',
            NAME        => $query_params->{CURRENT_STEP},
            STEP_NUMBER => '_SHOW',
            COLS_NAME   => 1
          });

          $query_params->{CURRENT_STEP} = $Crm->{TOTAL} > 0 ? $steps->[0]{step_number} : 1;
        }

        $Crm->crm_lead_add($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/leads/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_lead_change({ ID => $path_params->{id}, %{$query_params} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/leads/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_lead_info({ ID => $path_params->{id} });
        if ($Crm->{TOTAL} < 1) {
          return {
            errno  => 104003,
            errstr => "No lead with id $path_params->{id}"
          };
        }

        $Crm->crm_lead_delete({ ID => $path_params->{id} });

        if (!$Crm->{errno}) {
          return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
          return {
            errno  => 104002,
            errstr => "No lead with id $path_params->{id}"
          };
        }
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/leads/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_lead_info({ ID => $path_params->{id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/leads/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ?
            $query_params->{$param} : '_SHOW';
        }

        $query_params->{COLS_NAME} = 1;
        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
        $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
        $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
        $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

        $Crm->crm_lead_list($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/dialogue/:id/message/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        use AXbills::Sender::Core;
        my $Sender = AXbills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

        my $ex_params = {};
        my $dialog = $Crm->crm_dialogue_info({ ID => $path_params->{id} });
        my $lead = $Crm->crm_lead_info({ ID => $dialog->{LEAD_ID} });
        my $lead_address = $lead->{"_crm_$dialog->{SOURCE}"};

        if ($dialog->{SOURCE} eq 'mail') {
          $ex_params->{MAIL_HEADER} = [ "References: <$lead_address>", "In-Reply-To: <$lead_address>" ];
          $lead_address = $lead->{EMAIL};
        }

        return {
          errno  => 101,
          errstr => 'No found address to send'
        } if !$lead_address;

        my $result = $Sender->send_message({
          TO_ADDRESS  => $lead_address,
          MESSAGE     => Encode::encode_utf8($query_params->{MESSAGE}),
          SENDER_TYPE => ucfirst $dialog->{SOURCE},
          %{$ex_params}
        });
        return {
          errno  => 102,
          errstr => 'The message was not sent'
        } if !$result;

        $Crm->crm_dialogue_messages_add({
          MESSAGE     => $query_params->{MESSAGE},
          AID         => $self->{admin}{AID},
          DIALOGUE_ID => $path_params->{id}
        });

        return $result;
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/dialogue/:id/messages/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return $Crm->crm_dialogue_messages_list({
          MESSAGE     => '_SHOW',
          DAY         => '_SHOW',
          TIME        => '_SHOW',
          AID         => '_SHOW',
          PAGE_ROWS   => 99999,
          %{$query_params},
          DIALOGUE_ID => $path_params->{id},
          SORT        => 'cdm.date',
          DESC        => 'DESC',
          COLS_NAME   => 1
        });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/dialogue/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        if ($query_params->{AID}) {
          $Crm->crm_dialogue_info({ ID => $path_params->{id} });
          return { affected => $Crm->{AID} eq $query_params->{AID} ? 1 : undef } if $Crm->{AID};
        }

        $Crm->crm_dialogues_change({ %{$query_params}, ID => $path_params->{id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/sections/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_sections_add({ %{$query_params}, AID => $self->{admin}{AID} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/sections/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_sections_change({ %{$query_params}, ID => $path_params->{id}, AID => $self->{admin}{AID} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/sections/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_sections_info({ ID => $path_params->{id} });
        if ($Crm->{TOTAL} < 1) {
          return {
            errno  => 104008,
            errstr => 'Section not found'
          };
        }

        $Crm->crm_sections_del({ ID => $path_params->{id} });

        if (!$Crm->{errno}) {
          return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
          return {
            errno  => 104009,
            errstr => 'Section not found'
          };
        }
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/deals/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_deals_change({ %{$query_params}, ID => $path_params->{id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/progressbar/messages/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->progressbar_comment_add({ %{$query_params}, DOMAIN_ID => $self->{admin}{DOMAIN_ID} || 0 });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/progressbar/messages/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return $Crm->progressbar_comment_change({ %{$query_params}, ID => $path_params->{id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/progressbar/messages/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->progressbar_comment_delete({ ID => $path_params->{id} });

        if (!$Crm->{errno}) {
          return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
          return {
            errno  => 104001,
            errstr => "No message with id $path_params->{id}"
          };
        }
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/action/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_actions_add($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/action/:action_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_actions_change({ ID => $path_params->{action_id}, %{$query_params} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/action/:action_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_actions_info({ ID => $path_params->{action_id} });
        if ($Crm->{TOTAL} < 1) {
          return {
            errno  => 104004,
            errstr => 'Action not found'
          };
        }

        $Crm->crm_actions_delete({ ID => $path_params->{action_id} });

        if (!$Crm->{errno}) {
          return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
          return {
            errno  => 104007,
            errstr => 'Action not found'
          };
        }
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/action/:action_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_actions_info({ ID => $path_params->{action_id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/actions/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ?
            $query_params->{$param} : '_SHOW';
        }

        $query_params->{COLS_NAME} = 1;
        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
        $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
        $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
        $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

        $Crm->crm_actions_list($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/step/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_progressbar_step_add($query_params);
      },
      credentials => [ 'ADMIN' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/step/:step_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_progressbar_step_change({ ID => $path_params->{step_id}, %{$query_params} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/step/:step_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_progressbar_step_info({ ID => $path_params->{step_id} });
        if ($Crm->{TOTAL} < 1) {
          return {
            errno  => 104005,
            errstr => 'Step not found'
          };
        }

        $Crm->crm_progressbar_step_delete({ ID => $path_params->{step_id} });

        if (!$Crm->{errno}) {
          return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
          return {
            errno  => 104006,
            errstr => 'Step not found'
          };
        }
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/step/:step_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_progressbar_step_info({ ID => $path_params->{step_id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/steps/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ?
            $query_params->{$param} : '_SHOW';
        }

        $query_params->{COLS_NAME} = 1;
        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
        $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
        $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
        $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

        $Crm->crm_progressbar_step_list($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/workflow/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_workflow_add($query_params);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/workflow/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_workflow_change({ %{$query_params}, ID => $path_params->{id} });
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ];
}

1;
