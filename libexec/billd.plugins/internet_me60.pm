=head1 NAME

 billd plugin

 DESCRIBE: СoA Request

 #MB : DAYS (DEFAULT: 1) : SPEED_IN : SPEED_OUT)
 $conf{INTERNET_DAY_QUOTA} = '10:1:1024:1024';


 Recomended use with Internet module

=head1 ARGUMENTS

  CHANGE_TP_SPEED - Set tp profile ID
  SPEED           - Set default speed for all

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Nas::Control;
use AXbills::Filters qw(_mac_former);
use Radius;

our (
  $Nas,
  $argv,
  $debug,
  $Sessions,
  $Internet,
  %LIST_PARAMS,
  $debug_output,
  %conf,
  $base_dir,
  $db,
  $admin
);

change_profile();

#**********************************************************
=head2 change_tp_profile($attr) - CoA request

=cut
#**********************************************************
sub change_profile {

  my $default_filter_id = 'after-auth-ug';
  my Internet $Internet = $Internet;

  if ($debug > 6) {
    $Sessions->{debug} = 1;
    $Internet->{debug} = 1;
  }

  $Sessions->online(
    {
      'USER_NAME'           => '_SHOW',
      'LOGIN'               => '_SHOW',
      'NAS_PORT_ID'         => '_SHOW',
      'CLIENT_IP'           => '_SHOW',
      'DURATION'            => '_SHOW',
      'ACCT_INPUT_OCTETS'   => '_SHOW',
      'ACCT_OUTPUT_OCTETS'  => '_SHOW',
      'ACCT_SESSION_ID'     => '_SHOW',
      'LAST_ALIVE'          => '_SHOW',
      'ACCT_SESSION_TIME'   => '_SHOW',
      'DURATION_SEC'        => '_SHOW',
      'TP_ID'               => '_SHOW',
      'TP_NUM'              => '_SHOW',
      'TP_CREDIT_TRESSHOLD' => '_SHOW',
      'ONLINE_TP_ID'        => '_SHOW',
      'CONNECT_INFO'        => '_SHOW',
      'FILTER_ID'           => '_SHOW',
      'SKIP_DEL_CHECK'      => 1,
      'NAS_TYPE'            => 'huawei_me60',
      %LIST_PARAMS,
    }
  );

  my $online_session = $Sessions->{nas_sorted};
  my $nas_list = $Nas->list({
    %LIST_PARAMS,
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    PAGE_ROWS  => 65000
  });

  $conf{MB_SIZE} = 1024 * 1024;

  foreach my $nas (@{$nas_list}) {
    #if don't have online users skip it
    my $l = $online_session->{ $nas->{NAS_ID} };
    next if ($#{$l} < 0);

    foreach my $online (@{$l}) {
      if (!$online->{uid}) {
        my $internet_user_list = $Internet->user_list({
          LOGIN         => '_SHOW',
          ALL_FILTER_ID => '_SHOW',
          CID           => _mac_former($online->{user_name}),
          COLS_NAME     => 1
        });

        if($Internet->{TOTAL}) {
          my $login = $internet_user_list->[0]->{login};
          my $filter_id = $internet_user_list->[0]->{filter_id};
          coa_request({
            NAS_ID          => $nas->{NAS_ID},
            USER_NAME       => $login,
            #CLIENT_IP       => $online->{client_ip},
            ACCT_SESSION_ID => $online->{acct_session_id},
            PROFILE         => $filter_id
          });

          coa_request({
            NAS_ID          => $nas->{NAS_ID},
            USER_NAME       => $login,
            CLIENT_IP       => $online->{client_ip},
            ACCT_SESSION_ID => $online->{acct_session_id},
            FILTER_ID       => $default_filter_id
          });

          # coa_request({
          #    NAS_ID          => $nas->{NAS_ID},
          #    USER_NAME       => $login,
          #    #CLIENT_IP       => $online->{client_ip},
          #    ACCT_SESSION_ID => $online->{acct_session_id},
          #    PROFILE         => $filter_id
          # });
        }
        else {
          print "Can't find user User-Name: $online->{user_name} ACCT_SESSION_ID: $online->{acct_session_id}\n";
        }
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 coa_request($attr) - CoA request

   Arguments:
     $attr
       USER_NAME
       CLIENT_IP
       COMMAND
       SPEED   - IN:OUT
       PROFILE - LOgon user profile
       SESSION_ID
       PROFILE
       DEBUG

   Results:


=cut
#**********************************************************
sub coa_request {
  my ($attr) = @_;

  print "CoA Request\n";

  my $user_name = $attr->{USER_NAME} || q{};
  #my $user_ip   = $attr->{CLIENT_IP} || q{};
  #my $command   = $attr->{COMMAND} || q{account-status-query};

  my @request = (
    { 'Acct-Session-Id' => $attr->{ACCT_SESSION_ID} },
  );

  if ($attr->{FILTER_ID}) {
    push @request, { 'Filter-Id' => $attr->{FILTER_ID} };
  }

  if ($attr->{PROFILE}) {
    push @request, { 'Huawei-Qos-Profile-Name' => $attr->{PROFILE} };
  }
  push @request, { 'User-Name' => $user_name };

  if (!$attr->{NAS_ID}) {
    print "Select NAS: NAS_IDS=2\n";
    return 1;
  }

  $Nas->info({ NAS_ID => $attr->{NAS_ID} });

  my $nas_control = {};
  bless($nas_control, 'nas_control');

  _coa_request($nas_control, \@request, {
    %$Nas,
    COA => 1
  });

  if ($nas_control->{errno}) {
    print "Error: $nas_control->{message}\n";
  }

  my $rad_reply = $nas_control->{responce};

  foreach my $r (@$rad_reply) {
    print "> $r->{Name} -> $r->{Name}\n";
  }

  return 1;
}

#**********************************************************
=head2 coa_request($attr) - CoA request

  Arguments:


=cut
#**********************************************************
sub _coa_request {
  my $self = shift;
  my ($request, $attr) = @_;

  if (!$request) {
    $self->{message} = 'No CoA request';
    $self->{errno} = 1;
    return $self
  }

  my $ip = $attr->{NAS_MNG_IP_PORT} || '127.0.0.1';
  my $password = $attr->{NAS_MNG_PASSWORD} || 'secretpass';

  my $type;

  my $r = Radius->new(
    Host   => $ip,
    Secret => $password,
    Debug  => $attr->{DEBUG} || 0
  ) or print "Can't connect '$ip' $!\n";

  $conf{'dictionary'} = $base_dir . '/lib/dictionary' if (!$conf{'dictionary'});

  if (!-f $conf{'dictionary'}) {
    print "Can't find radius dictionary: $conf{'dictionary'}";
    return 0;
  }

  $r->load_dictionary($conf{'dictionary'});

  foreach my $request_param (@$request) {
    my ($k, $v) = each %$request_param;
    if ($debug > 2) {
      print "Request:  $k, $v\n";
    }

    $r->add_attributes({ Name => $k, Value => $v });
  }

  my $request_type = ($attr->{COA}) ? 'COA' : 'POD';
  if ($attr->{COA}) {
    $r->send_packet(COA_REQUEST) and $type = $r->recv_packet;
  }
  else {
    $r->send_packet(POD_REQUEST) and $type = $r->recv_packet;
  }

  my $result;
  if (!defined $type) {
    # No responce from COA/POD server
    my $message = "No responce from $request_type server '$ip'";
    $result .= $message;
    #$Log->log_print( 'LOG_DEBUG', "$USER", $message, { ACTION => 'CMD' } );
  }

  for my $rad_pair (sort $r->get_attributes) {
    $result .= "  $rad_pair->{'Name'} -> $rad_pair->{'Value'}\n";
  }

  print "RESULT: \n".$result;

  return $self;
}

1;