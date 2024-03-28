=head1 NAME

   IPoE Periodic

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array mk_unique_value int2ip ip2int);

our(
  $db,
  $admin,
  %conf,
  %LIST_PARAMS,
  $html,
  %lang,
  %ADMIN_REPORT
);

use Internet::Ipoe;
use Internet::Sessions;
require Internet::Ipoe_mng;

my $Internet_ipoe = Internet::Ipoe->new( $db, $admin, \%conf );
my $Sessions      = Internet::Sessions->new($db, $admin, \%conf);
my $Tariffs       = Tariffs->new( $db, \%conf, $admin );
my $Nas           = Nas->new( $db, \%conf, $admin );

#**********************************************************
=head2 ipoe_periodic_session_restart($attr) - Periodic session restart

  execute from pariodic

  Arguments:
    $attr
      SRESTART
      TP_ID
      LOGIN
      GID
      IP
      NAS_TYPES
      LOCAL_NAS
      NAS_IDS

  Skip session restart
      INTERNET_SKIP_SESSION_RESTART  - Skip restarting
      LOGON_ACTIVE_USERS        -
      LOG_ROTATE

  Returns:

=cut
#**********************************************************
sub ipoe_periodic_session_restart{
  my ($attr) = @_;
  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  $DEBUG .= $debug_output . "Internet: IPoE sessions restart\n";

  my $d = (split( /-/, $ADMIN_REPORT{DATE}, 3 ))[2];
  if ( !$attr->{SRESTART} ){
    #Restart only 1

    if ( $conf{INTERNET_SKIP_SESSION_RESTART} ){
      $DEBUG .= $debug_output . "  INTERNET_SKIP_SESSION_RESTART\n";
      return $debug_output;
    }

    if ( $attr->{LOGON_ACTIVE_USERS}
      || ($d != 1 && !$conf{INTERNET_DAILY_RESTART})
    ){
      if($debug > 0) {
        print "Skip running "
          .'Day:' . $d
          .'LOGON_ACTIVE_USERS:' . ($attr->{LOGON_ACTIVE_USERS} || q{})
          .'INTERNET_DAILY_RESTART:' . ( $conf{INTERNET_DAILY_RESTART} || q{} )
          . "\n" ;
      }
      $DEBUG .= $debug_output;
      return $debug_output;
    }
  }

  if ( $attr->{LOG_ROTATE} ){
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  if ( $attr->{LOGIN} ){
    $LIST_PARAMS{LOGIN} = $attr->{LOGIN};
  }
  elsif ( $attr->{TP_ID} ){
    $LIST_PARAMS{TP_ID} = $attr->{TP_ID};
  }
  elsif ( $attr->{GID} ){
    $LIST_PARAMS{GID} = $attr->{GID};
  }
  elsif ( $attr->{IP} ){
    $LIST_PARAMS{IP} = $attr->{IP};
  }

  #Get online
  my $Internet = Internet->new( $db, $admin, \%conf );
  $Nas->{debug} = 1 if ($debug > 6);

  my @nas_types = ('ipcad', 'dhcp', 'ipn');

  if($conf{INTERNET_IPOE_NAS_TYPES}) {
    @nas_types = split(/,\s?/, $conf{INTERNET_IPOE_NAS_TYPES});
  }

  if ( $attr->{NAS_TYPES} ){
    @nas_types = split( /,/, $attr->{NAS_TYPES} );
  }

  my $nas_list = $Nas->list(
    {
      NAS_IDS    => $attr->{LOCAL_NAS} || $attr->{NAS_IDS},
      PAGE_ROWS  => 10000,
      COLS_NAME  => 1,
      COLS_UPPER => 1
    }
  );

  my %nas_info = ();
  foreach my $line ( @{$nas_list} ){
    if ( in_array( $line->{NAS_TYPE}, \@nas_types ) || $attr->{NAS_IDS} ){
      $nas_info{ $line->{NAS_ID} } = $line;
    }
  }

  my @nas_ids_arr = keys %nas_info;

  if ( $#nas_ids_arr < 0 ){
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  require Auth2;
  Auth2->import();
  my $Auth = Auth2->new( $db, \%conf );
  $Sessions->{debug} = 1 if ($debug > 6);
  my $list = $Sessions->online({
      USER_NAME       => '_SHOW',
      CLIENT_IP       => '_SHOW',
      NAS_ID          => '_SHOW',
      NAS_IP          => '_SHOW',
      CID             => '_SHOW',
      CONNECT_INFO    => '_SHOW',
      ACCT_SESSION_ID => '_SHOW',
      FILTER_ID       => '_SHOW',
      NAS_PORT_ID     => '_SHOW',
      NETMASK         => '_SHOW',
      NAS_ID          => join( '; ', @nas_ids_arr ),
      %LIST_PARAMS
  });

  my $count = 0;
  my %activated_ips = ();
  foreach my $online ( @{$list} ){
    $FORM{SESSION_ID} = $online->{acct_session_id};
    my $connect_info = $online->{connect_info} || q{};
    my $filter_id = $online->{filter_id} || q{};
    if ($debug > 3) {
      $debug_output .= "LOGIN: $online->{user_name} IP: $online->{client_ip} NAS_ID: $online->{nas_id} NAS_IP: $online->{nas_ip} "
        . "CONNECT_INFO: $connect_info UID: $online->{uid} FILTER_ID: $filter_id\n"
      ;
    }

    my $nas_id = $online->{nas_id};
    my $nas_id_switch = 0;
    #Connect info with switch id
    if ( $connect_info =~ /^\d+$/ ){
      $nas_id_switch = $nas_id;
      $nas_id = $online->{connect_info};
    }

    #Hangup and activate
    internet_ipoe_change_status(
      {
        STATUS               => 'HANGUP',
        USER_NAME            => $online->{user_name},
        FRAMED_IP_ADDRESS    => $online->{client_ip},
        ACCT_SESSION_ID      => $online->{acct_session_id},
        NETMASK              => $online->{netmask},
        ACCT_TERMINATE_CAUSE => 7,
        UID                  => $online->{uid},
        CALLING_STATION_ID   => $online->{CID},
        FILTER_ID            => $filter_id,
        QUICK                => 1,
        DEBUG                => $debug,
        NAS_PORT             => $online->{nas_port_id} || 0,
        NAS_ID_SWITCH        => $nas_id_switch || 0,
        NAS_ID               => $nas_id || 0,
        NAS_IP_ADDRESS       => (! $attr->{LOCAL_NAS}) ? $nas_info{$nas_id}{NAS_IP} : q{},
        NAS_TYPE             => $nas_info{$nas_id}{NAS_TYPE},
        NAS_MNG_USER         => $nas_info{$nas_id}{NAS_MNG_USER},
        NAS_MNG_IP_PORT      => (! $attr->{LOCAL_NAS}) ? $nas_info{$nas_id}{NAS_MNG_IP_PORT} : q{},
        NAS_MNG_PASSWORD     => $nas_info{$nas_id}{NAS_MNG_PASSWORD},
        CONNECT_INFO         => $connect_info
      }
    );

    $debug_output .= "DISABLE IP: $online->{client_ip}\n" if ($debug > 1);

    #Activate
    if ( $activated_ips{$online->{client_ip}} ){
      next;
    }
    elsif ( int( $nas_id ) < 1 ){
      $debug_output .= "IP: $online->{client_ip} (CONNECT_INFO: $connect_info) UNKNOWN_NAS\n";
    }
    else{
      $Internet->user_info( $online->{uid} );
      my %AUTH_REQUEST = (
        ACCT_STATUS_TYPE     => 1,
        'User-Name'          => $online->{user_name},
        USER_NAME            => $online->{user_name},
        SESSION_START        => 0,
        ACCT_SESSION_ID      => mk_unique_value( 10 ),
        'Acct-Session-Id'    => mk_unique_value( 10 ),
        FRAMED_IP_ADDRESS    => $online->{client_ip},
        'Framed-IP-Address'  => $online->{client_ip},
        NETMASK              => $online->{netmask},
        NAS_ID_SWITCH        => $nas_id_switch || 0,
        NAS_ID               => $nas_id || 0,
        NAS_TYPE             => $nas_info{$nas_id}{NAS_TYPE} || 'ipcad',
        NAS_IP_ADDRESS       => $nas_info{$nas_id}{NAS_IP},
        'NAS-IP-Address'     => $nas_info{$nas_id}{NAS_IP},
        NAS_MNG_USER         => $nas_info{$nas_id}{NAS_MNG_USER},
        NAS_MNG_IP_PORT      => (! $attr->{LOCAL_NAS}) ? $nas_info{$nas_id}{NAS_MNG_IP_PORT} : q{},
        NAS_MNG_PASSWORD     => $nas_info{$nas_id}{NAS_MNG_PASSWORD},
        TP_ID                => $Internet->{TP_ID},
        CALLING_STATION_ID   => $online->{CID} || $online->{client_ip},
        'Calling-Station-Id' => $online->{CID} || $online->{client_ip},
        CONNECT_INFO         => $connect_info,
        UID                  => $online->{uid},
        QUICK                => 1,
        NAS_PORT             => $online->{nas_port_id} || 0,
        'Nas-Port'           => $online->{nas_port_id} || 0,
        HINT                 => 'NOPASS',
        DEBUG                => $debug,
        FILTER_ID            => $filter_id,
      );

      $Auth->{UID} = $online->{uid};
      $Auth->{IPOE_IP} = $online->{client_ip};
      $Auth->{SERVICE_ID}=$online->{service_id};

      my ($r, $RAD_PAIRS) = $Auth->auth(\%AUTH_REQUEST, \%nas_info);

      if ( $r == 1 ){
        $debug_output .= "Hangup: LOGIN: $online->{user_name} $RAD_PAIRS->{'Reply-Message'}\n";
      }
      else{
        if ( $RAD_PAIRS->{'Filter-Id'} ){
          $AUTH_REQUEST{FILTER_ID} = $RAD_PAIRS->{'Filter-Id'};
        }
        else{
          while (my ($k, $v) = each %{$RAD_PAIRS}) {
            $AUTH_REQUEST{FILTER_ID} .= "$k=$v, ";
          }
        }

        $Internet_ipoe->user_status( { %AUTH_REQUEST } );
        internet_ipoe_change_status( { STATUS => 'ONLINE_ENABLE', %AUTH_REQUEST } );
        $debug_output .= "ACTIVATE IP: $online->{client_ip}\n" if ($debug > 1);
      }
      $activated_ips{$online->{client_ip}} = 1;
    }

    $count++;
  }

  $debug_output .= "Total: $count\n" if ($debug > 0);

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head2 ipoe_start_active($attr) - Start active users

  Arguments:
    $attr
      LOCAL_NAS           - Start as local NAS server
      NAS_IDS             - Star on specified NAS
      NAS_TYPES           - Start for specified NAS types
      LOGON_ACTIVE_USERS  - Force call function
      LOG_ROTATE          - Log rote mode, skip start sessions
      DEBUG               - Debug mode

=cut
#**********************************************************
sub ipoe_start_active{
  my ($attr) = @_;
  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  if ( !defined( $attr->{LOGON_ACTIVE_USERS} ) ){
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  if ( $attr->{LOG_ROTATE} ){
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  my @nas_types = ('ipcad', 'dhcp', 'ipn');

  if ( $attr->{NAS_TYPES} ){
    @nas_types = split( /,/, $attr->{NAS_TYPES} );
  }
  elsif($conf{INTERNET_IPOE_NAS_TYPES}) {
    @nas_types = split(/,\s?/, $conf{INTERNET_IPOE_NAS_TYPES});
  }


  #Get online
  my $Internet = Internet->new( $db, $admin, \%conf );
  if ($debug > 6) {
    $Nas->{debug} = 1;
    $Tariffs->{debug}=1;
  }

  my $nas_list = $Nas->list({
    NAS_IDS    => $attr->{LOCAL_NAS} || $attr->{NAS_IDS},
    PAGE_ROWS  => 100000,
    COLS_NAME  => 1,
    COLS_UPPER => 1
  });

  my %nas_info = ();
  foreach my $line ( @{$nas_list} ){
    if ( in_array( $line->{NAS_TYPE}, \@nas_types ) || $attr->{NAS_IDS} ){
      $nas_info{ $line->{NAS_ID} } = $line;
      ($nas_info{$line->{NAS_ID}}{NAS_MNG_IP}, undef, $nas_info{$line->{NAS_ID}}{NAS_MNG_PORT}) = split(/:/, $nas_info{$line->{NAS_ID}}{NAS_MNG_IP_PORT}, 4);
    }
  }

  my @nas_ids_arr = keys %nas_info;

  if ( $#nas_ids_arr < 0 ){
    $debug_output .= "Not found nas for user activation\n";
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  #Get pools for nas
  my $poll_list = $Nas->nas_ip_pools_list({
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS        => 60000,
    COLS_NAME        => 1
  });
  my %nas_pools_hash = ();

  # Get valid NAS
  foreach my $line ( @{$poll_list} ){
    if ( $line->{nas_id} && defined( $nas_info{ $line->{nas_id} } ) ){
      $nas_pools_hash{ $line->{ip} } = "$line->{last_ip_num}:$line->{nas_id}";
    }
  }

  #Get TPs
  my %TPS = ();
  my $tp_list = $Tariffs->list( {
    MODULES      => 'Dv;Internet',
    COLS_NAME    => 1,
    PAYMENT_TYPE => '_SHOW'
  } );

  foreach my $line ( @{$tp_list} ){
    $TPS{ $line->{tp_id} } = $line->{payment_type} if ($line->{payment_type});
  }

  if ( $attr->{LOGIN} ){
    $LIST_PARAMS{LOGIN} = $attr->{LOGIN};
  }
  elsif ( $attr->{TP_ID} ){
    $LIST_PARAMS{TP_ID} = $attr->{TP_ID};
  }
  elsif ( $attr->{GID} ){
    $LIST_PARAMS{GID} = $attr->{GID};
  }

  my $online_list = $Sessions->online({
    NAS_ID    => join( ';', @nas_ids_arr ),
    CLIENT_IP => '_SHOW',
    COLS_NAME => 1
  });

  my $count = 0;
  my %online_uids = ();
  my %online_ips = ();
  foreach my $online ( @{$online_list} ){
    if ( $online->{uid} ){
      $online_uids{ $online->{uid} } = 1;
      $online_ips{ $online->{client_ip} } = 1;
    }
  }
#  my %DHCP_IPS = ();
#
#  $Dhcphosts->{debug} = 1 if ($debug > 5);;
#  my $dhcp_list = $Dhcphosts->hosts_list(
#    {
#      STATUS       => 0,
#      PAGE_ROWS    => 1000000,
#      INTERNET_ACTIVATE => 1,
#      DISABLE      => 0,
#      USER_DISABLE => 0,
#      COLS_NAME    => 1,
#      IP           => '_SHOW',
#      NAS_ID       => '_SHOW',
#    }
#  );
#
#  foreach my $line ( @{$dhcp_list} ){
#    push @{ $DHCP_IPS{$line->{uid}} }, [ $line->{ip}, $line->{nas_id} ];
#  }

  $Internet->{debug} = 1 if ($debug > 5);

  $LIST_PARAMS{INTERNET_STATUS}=0;
  if($conf{INTERNET_IPOE_NEGATIVE}) {
    $LIST_PARAMS{INTERNET_STATUS}='0;3;5';
  }

  my $internet_list = $Internet->user_list(
    {
      INTERNET_ACTIVATE=> "<=$DATE",
      INTERNET_EXPIRE=> "0000-00-00,>$DATE",
      IP             => '>0.0.0.0',
      NETMASK        => '_SHOW',
      LOGIN_STATUS   => 0,
      ALL_FILTER_ID  => '_SHOW',
      PORT           => '_SHOW',
      TP_CREDIT      => '_SHOW',
      CREDIT         => '_SHOW',
      DEPOSIT        => '_SHOW',
      LOGIN          => '_SHOW',
      IPN_ACTIVATE   => 1,
      %LIST_PARAMS,
      GROUP_BY       => 'internet.id',
      COLS_NAME      => 1,
      PAGE_ROWS      => 1000000,
    }
  );

  require Auth2;
  Auth2->import();
  my $Auth = Auth2->new( $db, \%conf );

  foreach my $internet ( @{$internet_list} ){
    my $filter_id    = $internet->{filter_id} || '';
    my $login        = $internet->{login};
    my $ip           = $internet->{ip} || int2ip($internet->{ip_num});
    my $netmask      = $internet->{netmask};
    my $connect_info = '';
    my $uid          = $internet->{uid};
    my $nas_id       = 0;
    my $nas_id_switch= 0;
    my $tp_id        = $internet->{tp_id};
    my $port         = $internet->{port};
    my $deposit      = $internet->{deposit};
    my $credit       = ($internet->{credit} && $internet->{credit} > 0) ? $internet->{credit} : ($internet->{tp_credit} || 0);

    my $ip_num = ip2int($ip);

    if ( $ip eq '0.0.0.0' ){
      next;
    }
    elsif ( $online_ips{$ip} ){
      print "$login $ip Online\n" if ($debug > 3);
      next;
    }
    elsif ( !defined($deposit) ){
      print "Error: Can't finde bills  UID: '$uid'\n";
      next;
    }
    elsif ( ! $tp_id ){
      print "Error: TP_NOT_DEFINED TP_ID: $tp_id UID: '$uid'\n";
      next;
    }
    elsif (! $conf{INTERNET_IPOE_NEGATIVE} &&  sprintf( "%.2f", $deposit + $credit ) <= 0 && ! $TPS{$tp_id}) {
      print "$login SMALL_DEPOSIT DEPOSIT: $deposit CREDIT: $credit\n" if ($debug > 3);
      next;
    }
#    elsif ( !$TPS{$tp_id} ){
#      print "TP_NOT_DEFINED '$tp_id'\n" if ($debug > 3);
#      next;
#    }

    $debug_output .= "LOGIN: $login IP: $ip NAS_ID: $nas_id CONNECT_INFO: $connect_info UID: $uid FILTER_ID: $filter_id\n" if ($debug > 3);

    reset(%nas_pools_hash);
    foreach my $start_ip ( keys %nas_pools_hash ){
      my ($end_ip, $id) = split( /:/, $nas_pools_hash{$start_ip}, 2 );

      if ( $debug > 4 ){
        print "Pools: $start_ip > $ip_num < $end_ip nas_id: $id) \n";
        exit;
      }

      if ( ($start_ip <= $ip_num) && ($ip_num <= $end_ip) ){
        $nas_id = $id;
        $connect_info = $nas_id;
        last;
      }
    }

    #Activate
    if ( int( $nas_id ) < 1 ){
      $debug_output .= "IP: $ip  : $nas_id ($nas_id_switch) NAS NOT_EXIST\n";
    }
    else{
      $debug_output .= "$login $uid $ip -> $nas_id ($nas_id_switch)\n" if ($debug > 1);
      $count++;

      next if ($debug > 5);

      my %DATA = (
        ACCT_STATUS_TYPE   => 1,
        USER_NAME          => $login,
        SESSION_START      => 0,
        ACCT_SESSION_ID    => mk_unique_value( 10 ),
        FRAMED_IP_ADDRESS  => $ip,
        NETMASK            => $netmask,
        NAS_ID_SWITCH      => $nas_id_switch,
        NAS_ID             => $nas_id,
        NAS_TYPE           => $nas_info{$nas_id}{NAS_TYPE},
        NAS_IP_ADDRESS     => int2ip($nas_info{$nas_id}{NAS_IP}),
        NAS_MNG_USER       => $nas_info{$nas_id}{NAS_MNG_USER},
        NAS_MNG_IP_PORT    => $nas_info{$nas_id}{NAS_MNG_IP_PORT},
        NAS_MNG_PASSWORD   => $nas_info{$nas_id}{NAS_MNG_PASSWORD},
        TP_ID              => $tp_id,
        CALLING_STATION_ID => $ip,
        CONNECT_INFO       => 'IPoE:'.$connect_info,
        UID                => $uid,
        QUICK              => 1,
        NAS_PORT           => $port,
        HINT               => 'NOPASS',
        DEBUG              => $debug,
        FILTER_ID          => $filter_id,
        SERVICE_ID         => $internet->{id},
      );

      my %RAD_REQUEST = (
        'Acct-Status-Type'   => 1,
        'User-Name'          => $login,
        'Acct-Session-Id'    => $DATA{ACCT_SESSION_ID},
        'Framed-IP-Address'  => $ip,
        'Calling-Station-Id' => $ip,
        'NAS-IP-Address'     => $nas_info{$nas_id}{NAS_IP},
        'NAS-Port'           => $port,
        'Filter-Id'          => $filter_id,
        'Connect-Info'       => 'IPoE:'.$connect_info,
      );

      $Nas->{NAS_ID}=$nas_id;
      $Auth->{UID}=$uid;
      $Auth->{SERVICE_ID}=$internet->{id};
      my ($r, $RAD_PAIRS) = $Auth->auth( \%RAD_REQUEST, $Nas);
      delete ( $RAD_PAIRS->{'Session-Timeout'} );

      if($debug) {
        print "Result: $r\n";
        while(my($k, $v)=each %$RAD_PAIRS ) {
          print "  $k -> $v\n";
        }
      }

      if ( $RAD_PAIRS->{'Filter-Id'} ){
        $DATA{FILTER_ID} = $RAD_PAIRS->{'Filter-Id'};
      }
      else{
        while (my ($k, $v) = each %{$RAD_PAIRS}) {
          $DATA{FILTER_ID} .= "$k=$v, ";
        }
      }

      $Internet_ipoe->user_status( \%DATA );
      internet_ipoe_change_status( { STATUS => 'ONLINE_ENABLE', %DATA } );
      $debug_output .= "$lang{ACTIVATE} IP: $ip\n" if ($debug > 1);
    }

    #if ( $conf{IPN_DHCP_ACTIVE} && $#{ $DHCP_IPS{$uid} } > -1 ){
    #  goto DHCP_IP_ASSIGN;
    #}
  }

  $debug_output .= "Total: $count\n" if ($debug > 0);

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head2 ipoe_detail_rotate($attr);

=cut
#**********************************************************
sub ipoe_detail_rotate{
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  return '' if ($attr->{SRESTART});
  if ( $attr->{LOGON_ACTIVE_USERS} ){
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  $Internet_ipoe->{debug} = 1 if ($debug > 6);

  # Clean s_detail table
  my $d = (split( /-/, $ADMIN_REPORT{DATE}, 3 ))[2];

  $DEBUG .= "Make log rotate\n" if ($debug > 0);
  $Internet_ipoe->log_rotate(
    {
      DETAIL    => 1,
      LOG       => ($d == 1) ? 1 : undef,
      PERIOD    => $conf{IPN_DETAIL_CLEAN_PERIOD} || 180,
      LOG_KEEP_PERIOD => $conf{IPN_LOG_KEEP_PERIOD} || 1,
      DAILY_LOG => $conf{IPN_DAILY_LOG_ROTATE} || 0,
    }
  );

  $debug_output .= "Make IPN details rotate\n" if ($debug > 0);

  $DEBUG .= $debug_output;
  return $debug_output;
}

1;
