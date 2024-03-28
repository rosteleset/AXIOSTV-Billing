=head1 NAME

 billd plugin

 DESCRIBE: Check MX80 lines

  http://www.oidview.com/mibs/2636/JUNIPER-SUBSCRIBER-MIB.html
=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use SNMP_Session;
use SNMP_util;
use BER;

our (
  $argv,
  $DATE,
  $TIME,
  $debug,
  $db,
);


our Nas $Nas;
our Internet::Sessions $Sessions;

mx80_checklines();


#**********************************************************
=head2 mx80_checklines($attr)

=cut
#**********************************************************
sub mx80_checklines {
  #my ($attr) = @_;

  my $Nas_cmd = AXbills::Nas::Control->new( $db, \%conf );

  if ($debug > 1) {
    print "mx80_checklines\n" ;
    if ($debug > 6) {
      $Sessions->{debug} = 1;
    }
  }

  my $SNMP_COMMUNITY = '';

  my %connectin_types = (
    1 => 'IPoE',
    2 => 'PPPoE'
  );

  my @state_staus = (
    'init',
    'configured',
    'active',
    'terminating',
    'terminated',
    'unknown'
  );

  my $total_billing = 0;
  my $total_mx80 = 0;

  #  my @connect_types   = ( 'none',
  #                          'dhcp',
  #                          'vlan',
  #                          'generic',
  #                          'mobileIp',
  #                          'vplsPw',
  #                          'ppp',
  #                          'ppppoe',
  #                          'l2tp',
  #                          'static',
  #                          'mlppp'
  #                        );

  if (! $debug) {
    $ENV{'MAX_LOG_LEVEL'} = 'none';
    $SNMP_Session::suppress_warnings = 2;
  }

  my $list = $Nas->list({
    %LIST_PARAMS,
    NAS_TYPE  => 'mx80',
    COLS_NAME => 1,
    DISABLE   => 0
  });

#  my %mx_extended_info = (
#    USER_NAME       => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.3',
#    CLIENT_TYPE     => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.4',
#    INTERFACE_TYPE  => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.10',
#    MAC             => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.11',
#    STATE           => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.12',
#    LOGIN_TIME      => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.13',
#    ACCT_SESSION_ID => '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.14',
#  );

  foreach my $nas_info (@$list) {
    # check ips
    if ($debug > 2) {
      print "NAS: $nas_info->{nas_id} MNG IP: $nas_info->{nas_mng_ip_port} MNG_PASS: $nas_info->{nas_mng_password}\n";
    }

    if (!$nas_info->{nas_mng_ip_port}) {
      print "Add managment ip and password for NAS id: $nas_info->{nas_id}\n";
      next;
    }

    my ($nas_ip, undef, undef, $snmp_port) = split(/:/, $nas_info->{nas_mng_ip_port});

    $snmp_port //= 161;

    $SNMP_COMMUNITY = $conf{MX80_SNMP_COMMUNITY} || $nas_info->{nas_mng_password} || 'public';

    #All leathes
    #my $jnxSubscriberIpAddress = '1.3.6.1.4.1.2636.3.64.1.1.1.3.1.5';

    #Subscribers
    my $jnxSubscriberIpAddress = '1.3.6.1.4.1.2636.3.64.1.1.1.6.1.5';

    if ($debug > 6) {
      print "oid -> $jnxSubscriberIpAddress\n";
    }
    my @result_ports = &snmpwalk($SNMP_COMMUNITY.'@'.$nas_ip, $jnxSubscriberIpAddress);

    if ($SNMP_Session::errmsg) {
      print "SNMP error: ".$SNMP_Session::errmsg;
      print "\n";
      next;
    }

    my %active_mx_ip = ();

    if ($#result_ports < 0) {
      print "NO active session in MX80 ($nas_ip $#result_ports)\n";
      next;
    }

    foreach my $line (@result_ports) {
      $total_mx80++;
      if ($debug > 5) {
        print "$line\n";
      }
      next if (!$line);
      my ($id, $ip) = split(/:/, $line);

      if ($ip ne '0.0.0.0') {
        $active_mx_ip{$ip} = $id;
        #print "$ip\n";
      }
    }

    # check billing
    $Sessions->online( {
      USER_NAME    => '_SHOW',
      NAS_PORT_ID  => '_SHOW',
      CONNECT_INFO => '_SHOW',
      TP_ID        => '_SHOW',
      SPEED        => '_SHOW',
      UID          => '_SHOW',
      JOIN_SERVICE => '_SHOW',
      CLIENT_IP    => '_SHOW',
      DURATION_SEC => '_SHOW',
      STARTED      => '_SHOW',
      CID          => '_SHOW',
      NAS_ID       => $LIST_PARAMS{nas_id},
      %LIST_PARAMS
    });

    my $online_sessions = $Sessions->{nas_sorted};
    my $l = $online_sessions->{ $nas_info->{nas_id} };
    next if ($#{$l} < 0);
    foreach my $online (@$l) {
      $total_billing++;
      if (!$active_mx_ip{$online->{client_ip}}) {
        print "!!! Not found on nas $online->{user_name} IP: $online->{client_ip} SID: $online->{acct_session_id}\n";
      }
      else {
        delete $active_mx_ip{$online->{client_ip}};
      }
    }

    while(my ($ip, $id) = each %active_mx_ip) {
      print "$DATE $TIME===================\nMX80 Unknown ip: $ip .$id\n" if ($debug > 1 || $argv->{SHOW});
      my $user_name = eval { return &snmpget($SNMP_COMMUNITY.'@'.$nas_ip, "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.3.".$id) };

      if (!$user_name) {
        next;
      }

      #my $client_type      = &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.4.".$id);
      my $acct_session_id  = &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.14.".$id);
      if(! $acct_session_id) {
        print "Error: cna;t get session id from MX80 ID: $id\n";
        next;
      }

      my $login_time       = eval { return &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip",
        "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.13.".$id) };
      my $state            = eval { return &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.12.".$id) };
      #my $mac = &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip", "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.11.".$id);
      my $connect_type     = eval { return &snmpget("$SNMP_COMMUNITY".'@'."$nas_ip",
        "1.3.6.1.4.1.2636.3.64.1.1.1.3.1.10.".$id) };

      if ($debug > 1 || defined($argv->{SHOW}) || defined($argv->{HANGUP})) {
        print "User: $user_name\n".
            " Connect: $connectin_types{$connect_type} Type:  STATE: $state_staus[$state]\n".
            " ACCT_SESSION_ID: ". ($acct_session_id || q{}) ."\n".
            #" MAC: ". sprintf("%x", $mac) ."\n".
            " Login time: $login_time\n";

        if (defined($argv->{HANGUP})) {
          $Nas_cmd->hangup(
            {
              NAS_MNG_IP_PORT  => $nas_info->{nas_mng_ip_port},
              NAS_MNG_PASSWORD => $nas_info->{nas_mng_password},
              NAS_TYPE         => 'mx80',
            },
            '',
            $user_name,
            {
              ACCT_SESSION_ID   => $acct_session_id,
              FRAMED_IP_ADDRESS => $ip,
              debug             => $debug,
            }
          );
          print ">>> hangup <<<\n\n";
        }
      }
    }

    if ($debug > 0) {
      print "Total: Billing: $total_billing MX80: $total_mx80\n";
    }
  }

  return 1;
}


1
