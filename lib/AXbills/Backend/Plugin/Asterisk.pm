package AXbills::Backend::Plugin::Asterisk;
use strict;
use warnings FATAL => 'all';

use parent 'AXbills::Backend::Plugin::BasePlugin';

use AXbills::Base qw/in_array/;
use Encode;
use Users;
use Callcenter;
use Admins;

my Users $Users;
my Callcenter $Callcenter;
my Admins $Admins;


# Used in local thread and can't be global
my (
  $db,
  %conf
);

our (@MODULES);

use AXbills::Backend::Log;
our AXbills::Backend::Log $Log;
my $log_user = ' Asterisk ';

# DEBUGGING EVENTS ( Will be removed )
my $Event_log = AXbills::Backend::Log->new('FILE', 7, 'Asterisk debug', {
  FILE => ('/usr/axbills/var/log/event_asterisk.log'),
});
# DEBUGGING EVENTS

use AXbills::Backend::Defs;
use AXbills::Backend::Plugin::Websocket::API;
my AXbills::Backend::Plugin::Websocket::API $websocket_api = get_global('WEBSOCKET_API');

# Cache
my %calls_statuses = ();
my @skip_nums = ();

#**********************************************************
=head2 new($db, $admin, $CONF)
 
  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    
  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($CONF) = @_;

  %conf = %{$CONF};

  $db = AXbills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'}, {
    CHARSET => $conf{dbcharset},
    SCOPE   => 2
  });

  require Service;
  Service->import();

  $Admins = Admins->new($db, $CONF);
  $Users = Users->new($db, $Admins, $CONF);
  $Callcenter = Callcenter->new($db, $Admins, $CONF);

  my $self = {
    db    => $db,
    admin => $Admins,
    conf  => $CONF,
  };

  if ($conf{CALLCENTER_SKIP_LOG}) {
    @skip_nums = split(/,\s?/, $conf{CALLCENTER_SKIP_LOG});
  }

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 init() - inits Asterisk events listener
    
=cut
#**********************************************************
sub init {
  my $self = shift;

  $self->init_connection();

  return 1;
}

#**********************************************************
=head2 init_connection() - new thread for asterisk

  Setting up Asterisk connection. Will die on error.
  All events will be passed to process_asterisk_event()

=cut
#**********************************************************
sub init_connection {
  my $self = shift;

  eval {require Asterisk::AMI};
  if ($@) {
    $Log->critical($log_user, "Can't load Asterisk::AMI perl module");
    die "Can't load Asterisk::AMI perl module";
  }

  Asterisk::AMI->import();

  $Log->info("Connecting to asterisk ");

  $self->connect_to_asterisk();
}

#**********************************************************
=head2 connect_to_asterisk() -

=cut
#**********************************************************
sub connect_to_asterisk {
  my $self = shift;

  $self->{connection_num} //= 0;

  delete $self->{astman_guard} if (exists $self->{astman_guard});

  $self->{astman_guard} = Asterisk::AMI->new(
    PeerAddr   => $conf{ASTERISK_AMI_IP},
    PeerPort   => $conf{ASTERISK_AMI_PORT},
    Username   => $conf{ASTERISK_AMI_USERNAME},
    Secret     => $conf{ASTERISK_AMI_SECRET},
    Events     => 'on', # Give us something to proxy
    Timeout    => 1,
    Blocking   => 0,
    Handlers   => { # Install handler for new calls
      Newchannel => \&process_asterisk_newchannel,
      Hangup     => \&process_asterisk_softhangup,
      Newstate   => \&process_asterisk_newstate,
      default    => \&process_default
    },
    Keepalive  => 3, # Send a keepalive every 3 seconds
    on_connect => sub {
      # Counter for connections
      $self->{connection_num}++;
      $Log->info("Connected to Asterisk::AMI (Connection #$self->{connection_num})");

      # Clear counter of unsuccessful tries
      $self->{connection_tries} = 0;
    },
    on_error   => sub {
      $Log->critical("Error occured on Asterisk::AMI socket : $_[1]");
      $self->reconnect_to_asterisk_in(3) or $self->exit_with_error("Unable to connect to Asterisk");
    },
    on_timeout => sub {
      $Log->critical("Connection $self->{connection_num} to Asterisk timed out");
      $self->reconnect_to_asterisk_in(1) or $self->exit_with_error("Unable to connect to Asterisk");
    }
  );

  return $self->{astman_guard};
}

#**********************************************************
=head2 reconnect_to_asterisk_in($seconds) - Controls number of tries to reconnect

  Arguments:
    $seconds - delay beetween next try
    
  Returns:
    1 if below connection tries treshold
    
=cut
#**********************************************************
sub reconnect_to_asterisk_in {
  my ($self, $seconds) = @_;

  $self->{connection_tries} //= 0;

  return 0 if ($self->{connection_tries} >= 20);

  $Log->notice("Set timer in $seconds seconds to reestablish connection to Asterisk ");

  # Create delayed action
  $self->{guard_timer} = AnyEvent->timer(
    after => $seconds,
    cb    => sub {
      $self->{connection_tries} = $self->{connection_tries} + 1;
      $Log->notice("Trying to connect again (Try #$self->{connection_tries})");
      $self->{astman_guard} = $self->connect_to_asterisk();
    }
  );

}

#**********************************************************
=head2 process_asterisk_newchannel($asterisk, $event)

  Default handler for asterisk AMI events

=cut
#**********************************************************
sub process_asterisk_newchannel {
  my ($asterisk, $event) = @_;

  if ($event->{Event} && $event->{Event} eq 'Newchannel') {
    my $caller_number_param =  $conf{CALLCENTER_ASTERISK_CALLER} || 'CallerIDNum';
    my $called_number = $event->{Exten} || q{};
    my $caller_number = $event->{$caller_number_param} || q{};

    return unless $caller_number && $called_number;

    return 0 if ($caller_number =~ /unknown/);

    if ($conf{CALLCENTER_ASTERISK_PHONE_PREFIX}) {
      $caller_number =~ s/^$conf{CALLCENTER_ASTERISK_PHONE_PREFIX}//;
    }

    if ($conf{CALLCENTER_SKIP_LOG}) {
      if (in_array($caller_number, \@skip_nums)) {
        #`echo "$caller_number calling to $called_number (Skip)" >> /tmp/a`;
        $Log->info("Got Newchannel event. $caller_number calling to $called_number (Skip)");
        return 1;
      }
    }

    # CALLCENTER CODE
    if (in_array('Callcenter', \@MODULES)) {
      if ($caller_number && $called_number) {
        my ($call_id, undef) = split('\.', $event->{Uniqueid} || q{});

        my $newchannel_handler = sub {

          my $user = $Users->list({
            UID       => '_SHOW',
            PHONE     => "*$caller_number",
            COLS_NAME => 1
          });

          my $uid = 0;
          if ($Users->{TOTAL} && $Users->{TOTAL} > 0) {
            $uid = $user->[0]->{uid};
          }

          $Callcenter->callcenter_add_calls({
            USER_PHONE     => $caller_number,
            OPERATOR_PHONE => $called_number,
            ID             => $call_id,
            UID            => $uid || 0,
            STATUS         => 1,
          });

          if (!$Callcenter->{errno}) {
            $Log->info("NEW_CALL ID: ". ( $call_id || 'UNKNOWN'));
          }
          else {
            $Log->info("ERR_CANT_ADD_CALL ID: ". ($call_id || 'UNKNOWN'));
          }
        };

        # check if its in IVR
        my $ivr_is_exist = 0;
        $asterisk->{guard_timer} = AnyEvent->timer(
          after => 1,
          cb    => sub {
            $Callcenter->log_list({
              COLS_NAME => 1,
              UID       => '_SHOW',
              UNIQUE_ID => $call_id
            });

            print "Total - $Callcenter->{TOTAL}\n";
            if (!$Callcenter->{TOTAL}) {
              $newchannel_handler->();
            }
          }
        );

        # $Callcenter->{debug}=1;

        # my $ivr_call_info = $Callcenter->log_list({COLS_NAME => 1, UID=> '_SHOW', UNIQUE_ID => $call_id});

        # use AXbills::Base;
        # _bp("ivr", $ivr_call_info, {TO_CONSOLE=>1});
      }
    }

    $Log->info("Got Newchannel event. $caller_number calling to $called_number ");

    notify_admin_about_new_call($called_number, $caller_number, $event);
  }

  return 1;
}

#**********************************************************
=head2 process_asterisk_newstate() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub process_asterisk_newstate {
  my ($asterisk, $event) = @_;

  if ($event->{ConnectedLineNum} && $event->{ChannelStateDesc} eq 'Up') {
    my ($call_id, undef) = split('\.', $event->{Uniqueid} || q{UNKNOWN});

    if ($call_id) {
      $Callcenter->callcenter_change_calls({
          STATUS => 2,
          ID     => $call_id
      });

      if (!$Callcenter->{errno}) {
        $Log->info("CALL_IN_PROCESS. ID: $call_id");
      }
      else {
        $Log->info("CAN_T_CHANGE_STATUS_CALL ($Callcenter->{errno}/$Callcenter->{errstr})");
      }

      $calls_statuses{$call_id} = 2;
    }
  }

  return 1;
}


#**********************************************************
=head2 process_asterisk_softhangup($asterisk, $event) -

  Arguments:
    $asterisk
    $event

  Returns:

  Examples:

=cut
#**********************************************************
sub process_asterisk_softhangup {
  my ($asterisk, $event) = @_;

  my $called_number = $event->{Exten} || q{};
  my ($call_id, undef) = split('\.', $event->{Uniqueid} || q{UNKNOWN});

  if (defined($calls_statuses{$call_id}) && $calls_statuses{$call_id} == 2) {
    $Callcenter->callcenter_change_calls({
      STATUS => 3,
      ID     => $call_id,
      STOP   => 'NOW()'
    });

    delete $calls_statuses{$call_id};
    $Log->info("CALL_PROCESSED ID: $call_id NUMBER: $called_number");
  }
  else {
    $Callcenter->callcenter_info_calls({
      ID => $call_id
    });

    if ($Callcenter->{STATUS} && $Callcenter->{STATUS} < 3) {
      $Callcenter->callcenter_change_calls({
        STATUS => 4,
        ID     => $call_id,
        STOP   => 'NOW()'
      });
      $Log->warning("CALL_NOT_PROCEESSED ID: $call_id NUMBER: $called_number");
    }
  }

  return 1
}


#**********************************************************
=head2 get_admin_by_sip_number($sip_number)

  Arguments:
    $sip_number

  Returns:
    AID_ARRAY_REF

=cut
#**********************************************************
sub get_admin_by_sip_number {
  my ($sip_number) = @_;

  my %params = (SIP_NUMBER => $sip_number);

  if ($conf{CALLCENTER_ASTERISK_ADMIN_EXPR}) {
    $params{SIP_NUMBER} = '*' . $sip_number . '*';
  }

  my $admins_for_number_list = $Admins->list({
    %params,
    COLS_NAME => 1,
    PAGE_ROWS => 50,
  });

  my @admins = ();
  if ($Admins->{TOTAL}) {
    foreach my $admin_ (@$admins_for_number_list) {
      push @admins, $admin_->{aid};
    }
  }

  return \@admins;
}

#**********************************************************
=head2 notify_admin_about_new_call($called_number, $caller_number) - notifies admin in new thread

  Arguments:
    $called_number - call receiver (Admin)
    $caller_numer  - call initiatior
    
  Returns:
    1
    
=cut
#**********************************************************
sub notify_admin_about_new_call {
  my ($called_number, $caller_number, $event) = @_;

  $called_number //= q{};
  $caller_number //= q{};
  my $admin_aids = get_admin_by_sip_number($called_number);
  my @online_aids = ();

  foreach my $aid (@$admin_aids) {
    if ($websocket_api->has_connected('admin', $aid)) {
      push @online_aids, $aid;
    }
    else {
      $Log->notice("CANT_NOTIFY AID: '". ($aid || q{-}) ."', no connection");
    }
  }

  if ($#online_aids == -1) {
    $Log->notice("ONLINE_ADMIN_NOT_PRESENT NUMBER: $called_number");
    return 1;
  }

  if ($conf{CALLCENTER_ASTERISK_PHONE_PREFIX}) {
    $caller_number =~ s/$conf{CALLCENTER_ASTERISK_PHONE_PREFIX}//;
  }

  my $search_list = $Users->list({
    PHONE        => "*$caller_number*",
    UID          => '_SHOW',
    FIO          => '_SHOW',
    DEPOSIT      => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    CITY         => '_SHOW',
    COMPANY_NAME => '_SHOW',
    COLS_UPPER   => 1,
    PAGE_ROWS    => 5,
    COLS_NAME    => 1
  });

  if (!$Users->{TOTAL} || $Users->{TOTAL} < 1) {
    # That's not an ABillS registered number
    $Log->warning("UNKNOWN_NUMBER: '$caller_number'");
    my $notification = _create_lead_notification($caller_number);
    foreach my $aid (@online_aids) {
      $websocket_api->notify_admin($aid, $notification);
    }
    return 1;
  }

  foreach my $user_info (@$search_list) {
    $Log->info("USER_INFO: $user_info->{UID} NUMBER: $caller_number ");
    my $notification = _create_user_notification({ %{$user_info}, });
    $Log->info("END Notification");
    # Notify admin by messageChecker.ParseMessage
    foreach my $aid (@online_aids) {
      $websocket_api->notify_admin($aid, $notification);
      #$Log->info("STOP AID: '$aid' <<< NUM: $i/$count  " . join(', ', @online_aids));
    }
  }

  return 1;
}


#**********************************************************
=head2 exit_with_error($error) - notifies admins, writes to log and finishes thread

  Arguments:
    $error - text for message
    
  Returns:
    
    
=cut
#**********************************************************
sub exit_with_error {
  my ($self, $error) = @_;

  $websocket_api->notify_admin('*', {
    TITLE  => 'ASTERISK',
    TEXT   => $error || 'Unable connect to asterisk',
    MODULE => 'Callcenter'
  });

  $Log->critical("Unable to connect to Asterisk ");

  return 1;
}

#**********************************************************
=head2 _create_user_notification($user_info) -  Create JSON message from %user_info

  Arguments:
    $user_info

  Return:
    \%result

=cut
#**********************************************************
sub _create_user_notification {
  my ($user_info) = @_;

  my $tp_name = '';
  my $internet_status = 0;

  if (in_array('Internet', \@MODULES)) {
    require Internet;
    Internet->import();
    my $Internet = Internet->new($db, $Admins, \%conf);

    my $user_internet_main = $Internet->user_list({
      UID             => $user_info->{UID},
      TP_NAME         => '_SHOW',
      INTERNET_STATUS => '_SHOW',
      SORT            => 2,
      DESC            => 'DESC',
      COLS_NAME       => 1,
      #COLS_UPPER      => 1,
      PAGE_ROWS       => 1
    });

    if ($Internet->{TOTAL} && $Internet->{TOTAL} > 0) {
      $tp_name = $user_internet_main->[0]->{tp_name} || '';
      $internet_status = $user_internet_main->[0]->{internet_status} || 0;
    }
  }

  my $title = ($user_info->{FIO} || '')
    . ' ( '
    . (($user_info->{COMPANY_NAME}) ? $user_info->{COMPANY_NAME} . ' : ' . ($user_info->{LOGIN} || q{})
    : ($user_info->{LOGIN} || q{}) )
    . ' )';

  our %lang;
  do "$base_dir/language/" . ($conf{default_language} || 'english') . ".pl";

  my $Service = Service->new($db, $admin, \%conf);
  my $status_list = $Service->status_list({ NAME => '_SHOW', COLOR => '_SHOW', COLS_NAME => 1 });
  my %service_status = ();
  foreach my $line (@$status_list) {
    my $name = $line->{name} || q{};
    if ($name =~ /\$lang\{(.+)\}/) {
      $name = $lang{$1} || $1 || q{};
    }
    $service_status{$line->{id} || 0} = $name || q{};
  }

  my $money_name = '';
  if ($conf{MONEY_UNIT_NAMES}) {
    $money_name = $conf{MONEY_UNIT_NAMES} ? (split(/;/, $conf{MONEY_UNIT_NAMES}))[0] : '';
  }

  my $build_delimiter = $conf{BUILD_DELIMITER} || ', ';
  my $deposit = sprintf('%.2f', $user_info->{DEPOSIT} || 0);

  if ($deposit < 0) {
    $deposit = "<span class='badge badge-danger'>$deposit</span>";
  }

  my $status = $service_status{$internet_status} || q{};
  if ($internet_status == 0) {
    $status = "<b class='text-success'>$status</b>";
  }
  else {
    $status = "<b class='text-warning'>$status</b>";
  }

  my $text = "$lang{DEPOSIT} : " . $deposit . " $money_name"
    . '<br>'
    . "$lang{ADDRESS} : " . ($user_info->{CITY} || '') . $build_delimiter . ($user_info->{ADDRESS_FULL} || '')
    . '<br>'
    . "$lang{TARIF_PLAN} : " . sprintf('%.25s', $tp_name)
    . '<br>'
    . "$lang{STATUS} : $status";

  my $result = {
    TITLE  => Encode::decode('utf8', $title),
    TEXT   => Encode::decode('utf8', $text),
    EXTRA  => '?index=15&UID=' . ($user_info->{UID} || 0),
    ICON   => 'fa fa-user text-success',
    CLIENT => {
      UID   => $user_info->{UID},
      LOGIN => $user_info->{LOGIN},
    }
  };

  return $result;
}

#**********************************************************
=head2 _create_lead_notification($number) -  Create JSON message from %user_info

  Arguments:
    $number

  Return:
    \%result

=cut
#**********************************************************
sub _create_lead_notification {
  my ($number) = @_;

  my %lead_info = ();

  if (in_array('Crm', \@MODULES)) {
    require Crm::db::Crm;
    Crm->import();
    my $Crm = Crm->new($db, $Admins, \%conf);
    my $crm_leads = $Crm->crm_lead_list({
      PHONE           => '*' . $number . '*',
      FIO             => '_SHOW',
      DATE            => '_SHOW',
      ADDRESS         => '_SHOW',
      ADDRESS_FULL    => '_SHOW',
      SKIP_RESPOSIBLE => 1,
      SKIP_DEL_CHECK  => 1,
      COLS_NAME       => 1,
      PAGE_ROWS       => 10
    });

    foreach my $lead (@$crm_leads) {
      $lead_info{FIO} = $lead->{fio};
      $lead_info{ID} = $lead->{id};
      $lead_info{ADDRESS_FULL} = $lead->{address_full} || $lead->{address};
      $lead_info{DATE} = $lead->{date};
      $Log->info("LEAD_FOUND: '". ($lead->{id} || 0) ."'");
    }
  }

  our %lang;
  do "$base_dir/language/" . ($conf{default_language} || 'english') . ".pl";
  my $text = qq{$lang{PHONE} : $number};
  my $icon = 'fa fa-user text-danger';
  my $link = '?get_index=crm_leads&full=1&add_form=1&PHONE=' . $number;

  if ($lead_info{'ID'}) {
    $text = " $lang{FIO} : " .($lead_info{FIO} || q{})
      .'<br/>'. "$lang{ADDRESS} : ". ($lead_info{ADDRESS_FULL} || q{})
      .'<br/>'. "$lang{DATE} : ". ($lead_info{DATE} || q{});
    $icon = 'fa fa-user text-warning';
    $link = '?get_index=crm_lead_info&full=1&LEAD_ID=' . ($lead_info{'ID'} || q{}) .'&PHONE=' . $number;
  }

  my %result = (
    TITLE  => Encode::decode('utf8', ($lead_info{'ID'}) ? $lang{LEAD} : "$lang{UNKNOWN} $lang{USER}"),
    TEXT   => Encode::decode('utf8', $text),
    EXTRA  => $link,
    ICON   => $icon,
    CLIENT => {
      FIO          => $lead_info{FIO} || q{},
      ADDRESS_FULL => $lead_info{ADDRESS_FULL} || q{},
      ID           => $lead_info{ID} || q{},
      DATE         => $lead_info{DATE} || q{},
      PHONE        => $lead_info{PHONE} || $number,
    }
  );

  return \%result;
}

#**********************************************************
=head2 process_default() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub process_default {
  my ($asterisk, $event) = @_;

  # Start debuging events, Will be removed
  my $debug_event = "\n================EVENT START=================\n";
  foreach my $key (sort keys %{$event}) {
    $debug_event .= ($key || '') . ": " . ($event->{$key} || '') . "\n";
  }
  $debug_event .= "================EVENT END=================\n";
  $Event_log->info($debug_event);
  # End debuging events

  return 1;
}


1;
