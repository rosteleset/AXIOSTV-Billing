package Mac_auth2;

=head1 NAME

   Mac_auth

 Cisco_isg AAA functions
 FreeRadius DHCP  functions
 http://www.cisco.com/en/US/docs/ios/12_2sb/isg/coa/guide/isgcoa4.html

 Options
 $conf{INTERNET_ISG}=1; - Activate ISG service

 $conf{ISG_SERVICES}='TURBO_SPEED1:N;TURBO_SPEED2:N;BILLING_ACCESS:A'; - ISG Services list
  service_name:status[A|N|T]
 $conf{ISG_ACCOUNTING_GROUP} - ISG Accounting group
  Default: ISG-AUTH-1

 $conf{ISG_ACCESS_LIST}='196';

 $conf{ISG_DHCP_UID} - Quick auth ISG by dhcp uid

=head1 VERSION

  VERSION: 8.15
  REVISION: 20201124

=cut

use strict;

our $VERSION = 8.15;
use Auth2;
use parent qw(main Auth2);
use POSIX qw(strftime);
use AXbills::Base qw(in_array _bp);
use Billing;

my ($conf, $Billing);

my %NAS_INFO    = ();
my %RAD_REPLY   = ();
my %GUEST_POOLS = ();
my @SWITCH_MAC_AUTH = ();

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($conf)   = @_;

  my $self = {
    db   => $db,
    conf => $conf
  };

  bless($self, $class);

  $Billing = Billing->new($db, $conf);

  #Make guest pool hash
  if ($conf->{INTERNET_GUEST_POOLS}) {
    $conf->{INTERNET_GUEST_POOLS} =~ s/[\r\n]+//g;
    my @guest_nets_arr = split(/;/, $conf->{INTERNET_GUEST_POOLS});
    foreach my $line (@guest_nets_arr) {
      my ($vid, $pool_id, $rad_reply) = split(/:/, $line);
      $GUEST_POOLS{$vid}{POOL_ID} = $pool_id;
      if ($rad_reply && $rad_reply ne '') {
        my @arr = split(/,/, $rad_reply);
        foreach my $param (@arr) {
          my ($k, $v) = split(/=/, $param, 2);
          $GUEST_POOLS{$vid}{RAD_REPLY}{$k} = $v;
        }
      }
    }
  }

  if ($conf->{INTERNET_SWITCH_MAC_AUTH}) {
    @SWITCH_MAC_AUTH = ();
    my @arr_switch_ids = split(/,/, $conf->{INTERNET_SWITCH_MAC_AUTH});
    foreach my $ids (@arr_switch_ids) {
      if ($ids =~ /^(\d+)-(\d+)$/) {
        for (my $i=$1; $i <= $2 ; $i++) {
          push @SWITCH_MAC_AUTH, $i;
        }
      }
      else {
        push @SWITCH_MAC_AUTH, $ids;
      }
    }
  }

  # Radius Parameter:Expr:Return Values:attributes
  # depricated
  #if ($conf->{DHCPHOSTS_EXPR}) {
  #  $conf->{DHCPHOSTS_EXPR} =~ s/\n//g;
  #  @o82_expr_arr    = split(/;/, $conf->{DHCPHOSTS_EXPR});
  #}

  $conf->{MB_SIZE} = $conf->{KBYTE_SIZE} * $conf->{KBYTE_SIZE};
  $conf->{DHCPHOSTS_SESSSION_TIMEOUT}=300 if(! $conf->{DHCPHOSTS_SESSSION_TIMEOUT});

  return $self;
}

#**********************************************************
=head2 pre_auth($self, $RAD, $attr) - Pre_auth

=cut
#**********************************************************
sub pre_auth {
  my ($self) = @_;

  $self->{'RAD_CHECK'}{'Auth-Type'} = "Accept";
  return 0;
}

#**********************************************************
=head2 user_info($RAD_REQUEST, $attr)

  Arguments:
    $RAD_REQUEST
    $attr
      UID
      SERVICE_ID

  Returns:

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($RAD_REQUEST, $attr) = @_;

  my $WHERE;
  if ($attr->{UID}) {
    $WHERE = " AND internet.uid='$attr->{UID}'";
    if($attr->{SERVICE_ID}) {
      $WHERE .= " AND internet.id='$attr->{SERVICE_ID}'";
    }
  }
  elsif ($RAD_REQUEST->{'Framed-Protocol'} && $RAD_REQUEST->{'Framed-Protocol'} eq 'PPP') {
    $WHERE = " AND u.id='" . $RAD_REQUEST->{'User-Name'} . "'";
  }
#  elsif ($RAD_REQUEST->{'DHCP-Message-Type'}) {
#    $WHERE = " AND internet.cid='" . $RAD_REQUEST->{'User-Name'} . "'";
#  }
#  elsif ($RAD_REQUEST->{'User-Name'}) {
#    $WHERE = " AND internet.cid <> '' AND internet.cid='" . $RAD_REQUEST->{'User-Name'} . "'";
#  }
  else {
    $WHERE = " AND internet.cid <> '' AND internet.cid='" . $RAD_REQUEST->{'User-Name'} . "'";
  }

  if($attr->{DOMAIN_ID}) {
    $WHERE .= " AND u.domain_id=$attr->{DOMAIN_ID}"
  }

  $self->query2("SELECT
   u.id AS user_name,
   internet.uid,
   internet.tp_id AS tp_num,
   INET_NTOA(internet.ip) AS ip,
   internet.logins AS simultaneously,
   internet.speed,
   internet.disable AS internet_disable,
   u.disable AS user_disable,
   u.reduction,
   u.bill_id,
   u.company_id,
   u.credit,
   u.activate,
   UNIX_TIMESTAMP() AS session_start,
   UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
   DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_week,
   DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year,

   tp.payment_type,
   tp.neg_deposit_filter_id,
   tp.credit AS tp_credit,
   tp.credit_tresshold,
   tp_int.id AS interval_id,
   COUNT(DISTINCT tp_int.id) AS interval_counts,
   COUNT(DISTINCT tt.id) AS tt_counts,
   IF (u.expire > '0000-00-00' AND u.expire <= CURDATE(), u.expire,
   IF (internet.expire > '0000-00-00' AND internet.expire <= CURDATE(), internet.expire, 0)) AS expired,
   IF(internet.filter_id != '', internet.filter_id, IF(tp.filter_id IS NULL, '', tp.filter_id)) AS filter,
   tp.tp_id,
   tp.rad_pairs AS tp_rad_pairs,
   tp.neg_deposit_ippool,
   tp.ippool as tp_ippool,

   tp.day_traf_limit,
   tp.week_traf_limit,
   tp.month_traf_limit,
   tp.octets_direction,
   internet.id AS service_id,
   IF (COUNT(un.uid) + COUNT(tp_nas.tp_id) = 0, 0,
   IF (COUNT(un.uid)>0, 1, 2)) AS nas,
   internet.cid

  FROM internet_main internet
  INNER JOIN users u ON (u.uid=internet.uid)
  LEFT JOIN tarif_plans tp ON (internet.tp_id=tp.tp_id)
  LEFT JOIN intervals tp_int ON (tp_int.tp_id=tp.tp_id)
  LEFT JOIN trafic_tarifs tt ON (tt.interval_id=tp_int.id)
  LEFT JOIN users_nas un ON (un.uid = internet.uid)
  LEFT JOIN tp_nas ON (tp_nas.tp_id = tp.tp_id)

  WHERE u.deleted=0
   $WHERE
   GROUP BY u.uid;",
    undef,
    { INFO => 1 }
  );

  if ($self->{TOTAL} < 1) {
    return $self;
  }
  elsif ($self->{errno}) {
    return $self;
  }

  #Chack Company account if ACCOUNT_ID > 0
  $self->check_company_account() if ($self->{COMPANY_ID} > 0);
  $self->check_bill_account();

  $self->{JOIN_SERVICE}=0;

  if ($self->{errno}) {
    $RAD_REPLY{'Reply-Message'} = $self->{errstr};
    return 1, \%RAD_REPLY;
  }

  return $self;
}

#**********************************************************
=head2 auth($RAD_REQUEST, $NAS, $attr)

  Client        -> Server     -> Client       ->  Server
  DHCP-Discover -> DHCP Offer -> DHCP-Request ->  DHCP ACK (OK) / DHCP NAK (Not found)

=cut
#**********************************************************
sub auth {
  my $self = shift;
  my ($RAD_REQUEST, $NAS) = @_;

  my $uid       = 0;
  $self->{INFO} = '';
  my $USER_MAC  = $RAD_REQUEST->{'DHCP-Client-Hardware-Address'} || '';
  my $USER_IP   = $RAD_REQUEST->{'DHCP-Client-IP-Address'}       || '';

  delete @RAD_REPLY{ qw(Reply-Message Framed-IP-Address DHCP-Your-IP-Address DHCP-Client-IP-Address) };
  #  delete($RAD_REPLY{'Reply-Message'});
  #  delete($RAD_REPLY{'Framed-IP-Address'});
  #  delete($RAD_REPLY{'DHCP-Your-IP-Address'});
  #  delete($RAD_REPLY{'DHCP-Client-IP-Address'});
  $NAS->{NAS_ALIVE}   = 86000 if (! $NAS->{NAS_ALIVE});
  # Session type 0 Work 1 guest
  $self->{GUEST_MODE}  = 0;
  #Last leases if exist
  $self->{GUEST_LEASES}= 0;
  my %user_auth_params = ();

  #Mikrotik http://wiki.mikrotik.com/wiki/Manual:IP/DHCP_Server
  if ($NAS->{NAS_TYPE} eq 'mikrotik_dhcp') {
    %RAD_REPLY = ();
    #$self->{db}{db}->{AutoCommit} = 0;
    my $auth_params = $self->opt82_parse($RAD_REQUEST);
    %user_auth_params = (
      USER_MAC        => $RAD_REQUEST->{'User-Name'},
      HOSTNAME        => $RAD_REQUEST->{'DHCP-Hostname'},
      AGENT_REMOTE_ID => $RAD_REQUEST->{'Agent-Remote-Id'},
      CIRCUIT_ID      => $RAD_REQUEST->{'Agent-Circuit-Id'},
      %$auth_params
    );

    $NAS->{MAIN_NAS_ID} = $NAS->{NAS_ID} if(! $NAS->{MAIN_NAS_ID});
    $self->dhcp_info(\%user_auth_params, $NAS);
    if (! $NAS->{NAS_ID} || ! $auth_params->{NAS_MAC} ) {
      $NAS->{NAS_ID} = $NAS->{MAIN_NAS_ID};
    }

    if ($self->{error}) {
      my ($ret, $R_REPLY) = $self->guest_mode($RAD_REQUEST, $NAS, $self->{error_str} || "USER_NOT_FOUND",
        \%user_auth_params);

      if($ret == 1) {
        $ret = 6;
      }

      return $ret, $R_REPLY;
#      if ($GUEST_POOLS{$user_auth_params{VLAN}} || $GUEST_POOLS{0}) {
#        return $self->guest_mode($RAD_REQUEST, $NAS, $self->{error_str} || "USER_NOT_FOUND",
#          \%user_auth_params);
#      }
#      else {
#        $self->{INFO} = $self->{error_str} . $self->{INFO};
#        $RAD_REPLY{'Reply-Message'}=$self->{INFO};
#        return 6, \%RAD_REPLY;
#      }
    }

    # Auth user / Get user info
    $self->user_info($RAD_REQUEST, {
      UID       => $self->{UID},
      SERVICE_ID=> $self->{SERVICE_ID},
      DOMAIN_ID => $NAS->{DOMAIN_ID},
    });

    if ($self->{USER_NAME}) {
      $user_auth_params{LOGIN} = $self->{USER_NAME};
      $user_auth_params{USER_NAME} = $RAD_REQUEST->{'User-Name'};
      $RAD_REQUEST->{'User-Name'} = $self->{USER_NAME};
    }

    $self->{GUEST} = $self->{GUEST_MODE} || 0;
    if ($self->{errno} && $self->{errno} != 2 ) {
      $RAD_REPLY{'Reply-Message'} = $self->{errstr};
      return 1, \%RAD_REPLY;
    }
    elsif ($self->{TOTAL} < 1) {
      return $self->guest_mode($RAD_REQUEST, $NAS,
        'USER_NOT_FOUND', #"USER_NOT_EXIST '" . $RAD_REQUEST->{'User-Name'} . "' $user_auth_params{NAS_MAC}/$user_auth_params{PORT}",
        \%user_auth_params);
    }
    elsif ($self->{EXPIRED}) {
      return $self->guest_mode($RAD_REQUEST, $NAS,
          "ACCOUNT_EXPIRED '$self->{EXPIRED}'",
          \%user_auth_params);
    }
    #DIsable
    elsif ($self->{INTERNET_DISABLE} || $self->{USER_DISABLE}) {
      #if ($conf->{INTERNET_STATUS_NEG_DEPOSIT}) {
        return $self->guest_mode($RAD_REQUEST, $NAS, "ACCOUNT_DISABLE: $self->{INTERNET_DISABLE}/$self->{USER_DISABLE}",
          \%user_auth_params);
      #}
      #else {
      #  $RAD_REPLY{'Reply-Message'} = "ACCOUNT_DISABLE $self->{INTERNET_DISABLE}/$self->{USER_DISABLE}";
      #}
      #return 1, \%RAD_REPLY;
    }
    elsif (!defined($self->{PAYMENT_TYPE})) {
      $RAD_REPLY{'Reply-Message'} = "SERVICE_NOT_ALLOW";
      return 1, \%RAD_REPLY;
    }
    elsif ($self->{NAS}) {
      my $sql;
      if ($self->{NAS} == 1) {
        $sql = "SELECT un.uid FROM users_nas un WHERE un.uid='$self->{UID}' and un.nas_id='$NAS->{NAS_ID}'";
      }
      else {
        $sql = "SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TP_ID}' and nas_id='$NAS->{NAS_ID}'";
      }

      $self->query2("$sql");

      if ($self->{TOTAL} < 1) {
        $RAD_REPLY{'Reply-Message'} = "You are not authorized to log in $NAS->{NAS_ID} (". $RAD_REQUEST->{'NAS-IP-Address'} .")";
        return 1, \%RAD_REPLY;
      }
    }

    #Check deposit
    if ($self->{PAYMENT_TYPE} == 0) {
      $self->{CREDIT}  = $self->{TP_CREDIT} if ($self->{CREDIT} == 0);
      $self->{DEPOSIT} = $self->{DEPOSIT} + $self->{CREDIT} - $self->{CREDIT_TRESSHOLD};

      #Check deposit
      if ($self->{DEPOSIT} <= 0) {
        return $self->guest_mode($RAD_REQUEST, $NAS, "NEGATIVE_DEPOSIT '$self->{DEPOSIT}'",
            \%user_auth_params);
      }
      else {
        $self->{GUEST_LEASES}=0;
      }
    }

    #$self->leases_get({ %user_auth_params, GUEST => $self->{GUEST_MODE} }, $NAS);
#    if ($self->{DHCP_STATIC_IP} ne '0.0.0.0') {
#      $self->{IP}=$self->{DHCP_STATIC_IP};
#    }
    if ($self->{IP} eq '0.0.0.0') {
      $self->query2("SELECT INET_NTOA(framed_ip_address) FROM internet_online
      WHERE cid='". ($user_auth_params{USER_MAC} || $user_auth_params{USER_NAME}) ."' AND guest='$self->{GUEST_MODE}' ;");

      if($self->{TOTAL} > 0) {
        $self->{IP} = $self->{list}->[0]->[0];
      }
      else {
        $self->{IP} = $self->Auth2::get_ip($NAS->{NAS_ID}, $RAD_REQUEST->{'NAS-IP-Address'},
          { TP_IPPOOL => $self->{TP_IPPOOL} });
      }

      if ($self->{IP} eq '-1') {
        $RAD_REPLY{'Reply-Message'} = "Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS})";
        return 1, \%RAD_REPLY;
      }
      elsif ($self->{IP} eq '0') {
      }
      else {
        $RAD_REPLY{'Framed-IP-Address'}     = $self->{IP};
        $RAD_REPLY{'Mikrotik-Address-List'} = "CLIENTS_$self->{TP_ID}";
      }
    }
    else {
      $RAD_REPLY{'Framed-IP-Address'}     = $self->{IP};
      $RAD_REPLY{'Mikrotik-Address-List'} = "CLIENTS_$self->{TP_ID}";
    }

    if (! $conf->{INTERNET_EXTERNAL_SHAPPER}) {
      if ($self->{SPEED}) {
        $RAD_REPLY{'Mikrotik-Rate-Limit'} = "$self->{SPEED}k";
      }
      else {
        my $speeds = $self->get_speed();
        if ($speeds->{0} && ! $speeds->{1}) {
          # Only fo mikrotik < 6.44
          #$RAD_REPLY{'Ascend-Xmit-Rate'}=$speeds->{0}->{IN} * 1024 if ($speeds->{0}->{IN});
          #$RAD_REPLY{'Ascend-Data-Rate'}=$speeds->{0}->{OUT} * 1024 if ($speeds->{0}->{OUT});

          $RAD_REPLY{'Mikrotik-Rate-Limit'} =
            $speeds->{0}->{OUT}.'K/'.$speeds->{0}->{IN}.'K ';

          if($speeds->{0}->{BURST_LIMIT_UL}) {
            $RAD_REPLY{'Mikrotik-Rate-Limit'} .= $speeds->{0}->{BURST_LIMIT_UL} . 'K/' . $speeds->{0}->{BURST_LIMIT_UL} . 'K ' .
              $speeds->{0}->{BURST_THRESHOLD_UL} . 'K/' . $speeds->{0}->{BURST_THRESHOLD_DL} . 'K ' .
              $speeds->{0}->{BURST_TIME_UL} . '/' . $speeds->{0}->{BURST_TIME_DL} . ' 5';
          }
        }
      }
    }

    $RAD_REPLY{'Session-Timeout'}=$NAS->{NAS_ALIVE};

    if ($self->{FILTER}) {
      $self->neg_deposit_filter_former($RAD_REQUEST, $NAS, $self->{FILTER}, { USER_FILTER => 1, RAD_PAIRS => \%RAD_REPLY });
    }

    rad_pairs_former($self->{TP_RAD_PAIRS} || $NAS->{NAS_RAD_PAIRS}, { RAD_PAIRS => \%RAD_REPLY });

    $self->calls_update(\%user_auth_params, $NAS);
    #    $self->{db}{db}->commit();
    #    $self->{db}{db}->{AutoCommit} = 1;
    return 0, \%RAD_REPLY;
  }
  elsif ($NAS->{NAS_TYPE} ne 'cisco_isg') {
    # Decline http://www.freesoft.org/CIE/RFC/2131/25.htm
    if ($RAD_REQUEST->{'DHCP-Message-Type'} eq 'DHCP-Decline') {
      $RAD_REPLY{'Reply-Message'} = "DECLINE";
#      $self->query2("UPDATE dhcphosts_leases SET state=4
#       WHERE hardware='$USER_MAC';");
      $self->{INFO} .= 'Decline '. $RAD_REQUEST->{'DHCP-Client-IP-Address'};
      #  return 1, \%RAD_REPLY;
    }

    $RAD_REPLY{'User-Name'} = $USER_MAC;

    #User renew old ip
    if ($RAD_REQUEST->{'DHCP-Requested-IP-Address'}) {
      $USER_IP = $RAD_REQUEST->{'DHCP-Requested-IP-Address'};
    }

    # If this is DHCP-Discover, we must offer to user ip-address, and if he'll accept it, he will send DHCP-Request to us

    %user_auth_params = (
      REQUEST_TYPE    => $RAD_REQUEST->{'DHCP-Message-Type'},
      USER_MAC        => lc($USER_MAC),
      HOSTNAME        => $RAD_REQUEST->{'DHCP-Hostname'},
      AGENT_REMOTE_ID => $RAD_REQUEST->{'DHCP-Agent-Remote-Id'} ||  $RAD_REQUEST->{'DHCP-Relay-Remote-Id'}  || '',
      CIRCUIT_ID      => $RAD_REQUEST->{'DHCP-Agent-Circuit-Id'} || $RAD_REQUEST->{'DHCP-Relay-Circuit-Id'} || '',
    );

    # If re request ip
    if($USER_IP ne '0.0.0.0') {
      $user_auth_params{REQUIRE_USER_IP}=$USER_IP;
    }

    #Option 82 request get PORT AND Switch MAC
    if ($RAD_REQUEST->{'DHCP-Relay-Circuit-Id'} || $RAD_REQUEST->{'DHCP-Relay-Remote-Id'}) {
      my $auth_params = $self->opt82_parse($RAD_REQUEST);
      %user_auth_params = (%user_auth_params, %$auth_params);
      if ($#SWITCH_MAC_AUTH > -1 && $user_auth_params{NAS_MAC}) {
        if (!$NAS_INFO{$user_auth_params{NAS_MAC}}) {
          my $nas = Nas->new($self->{db}, $conf);
          $nas->info({ CALLED_STATION_ID => $user_auth_params{NAS_MAC} });
          if (!$nas->{errno}) {
            $nas->{NAS_TYPE} = $NAS->{NAS_TYPE};
            $nas->{MAIN_NAS_ID} = $nas->{MAIN_NAS_ID} = $NAS->{MAIN_NAS_ID} || $NAS->{NAS_ID};
            $NAS_INFO{$user_auth_params{NAS_MAC}} = $nas;
          }
          else {
            delete $NAS_INFO{$user_auth_params{NAS_MAC}};
          }
        }

        my $nas_id=$NAS_INFO{$user_auth_params{NAS_MAC}}->{NAS_ID};
        if(in_array($nas_id, \@SWITCH_MAC_AUTH)) {
          $user_auth_params{MAC_AUTH} = 1;
        }
      }

      $self->dhcp_info(\%user_auth_params, $NAS);

      if ($self->{error}) {
        if ($self->{error} != 3 && ($GUEST_POOLS{$user_auth_params{VLAN}} || $GUEST_POOLS{0})) {
          my ($ret, $R_REPLY) =  $self->guest_mode($RAD_REQUEST, $NAS, $self->{error_str} || "Not found", \%user_auth_params);
          ($ret, $R_REPLY) = $self->dhcp_rad_reply($RAD_REQUEST, $NAS, \%user_auth_params);

          return $ret, $R_REPLY;
        }
        else {
          $RAD_REPLY{'Reply-Message'} = $self->{error_str};
          return 7, \%RAD_REPLY;
        }
      }
      #If exist make static IP
      elsif ($self->{TOTAL} > 0) {
        $uid                              = $self->{UID};
        $RAD_REQUEST->{'User-Name'}       = $self->{USER_NAME};
        $RAD_REPLY{'User-Name'}           = $self->{USER_NAME};

        $RAD_REPLY{'DHCP-Subnet-Mask'}    = $self->{NETMASK};
        #Fixme depricated
        #$RAD_REPLY{'DHCP-Router-Address'} = $self->{ROUTERS} if($self->{ROUTERS});
        $RAD_REPLY{'DHCP-Router-Address'} = $self->{GATEWAY} if($self->{GATEWAY});
        $RAD_REPLY{'DHCP-NTP-Servers'}    = $self->{NTP} if ($self->{NTP});
        $NAS->{NAS_ID}                    = $self->{NAS_ID} if ($self->{NAS_ID});

        my @dns_arr                       = split(/,/, $self->{DNS});
        if ($self->{DNS2}) {
          push @dns_arr, $self->{DNS2};
        }
        $RAD_REPLY{'DHCP-Domain-Name-Server'} = \@dns_arr;
      }
      #Else add to guest NET
      else {
        if ($self->{error} != 3 && $conf->{INTERNET_GUEST_POOLS}) {
          my ($ret, $R_REPLY) = $self->guest_mode($RAD_REQUEST, $NAS, "DHCP_HOST_NOT_FOUND", \%user_auth_params);

          ($ret, $R_REPLY) = $self->dhcp_rad_reply($RAD_REQUEST, $NAS, \%user_auth_params);
          return $ret, $R_REPLY;
        }
        else {
          $RAD_REPLY{'Reply-Message'} = "Can't find ".$self->{INFO};
          return 7, \%RAD_REPLY;
        }
      }
    }
    else {
      $self->dhcp_info(\%user_auth_params, $NAS);
      $self->{INFO} .= " NOT OPTION82";

      if(! $self->{error}) {
        $uid                             = $self->{UID};
        $RAD_REQUEST->{'User-Name'}      = $self->{USER_NAME};
        $NAS->{NAS_ID}                   = $self->{NAS_ID} if ($self->{NAS_ID});
        $RAD_REPLY{'DHCP-Subnet-Mask'}   = $self->{NETMASK};
        #Old notification
        #$RAD_REPLY{'DHCP-Router-Address'}= $self->{ROUTERS} if($self->{ROUTERS});
        $RAD_REPLY{'DHCP-Router-Address'}= $self->{GATEWAY} if($self->{GATEWAY});
        $RAD_REPLY{'DHCP-NTP-Servers'}   = $self->{NTP};
        if($self->{DNS}) {
          my @dns_arr = split(/,/, $self->{DNS});
          if ($self->{DNS2}) {
            push @dns_arr, $self->{DNS2};
          }
          $RAD_REPLY{'DHCP-Domain-Name-Server'} = \@dns_arr;
        }
      }
      else {
        if (($user_auth_params{VLAN} && $GUEST_POOLS{$user_auth_params{VLAN}}) || $GUEST_POOLS{0}) {
          my ($ret, $R_REPLY) = $self->guest_mode($RAD_REQUEST, $NAS, "Dhcp host not found", \%user_auth_params);
          ($ret, $R_REPLY) = $self->dhcp_rad_reply($RAD_REQUEST, $NAS, \%user_auth_params);
          return $ret, $R_REPLY;
          #goto DHCP_REQUEST_SEND;
        }
        else {
          return 7, \%RAD_REPLY;
        }
      }
    }

    # FIRST OF ALL, we search existing lease with such mac+ip as in request.
    # Only check for work nets (flag=0)
    if ($USER_IP ne '0.0.0.0') {
      $self->leases_get({ %user_auth_params, IP => $USER_IP }, $NAS);
      if ($self->{RESERVED_IP}) {
        #If work net leases
        if ($self->{GUEST_LEASES} == 0) {
          if ($conf->{DHCPHOSTS_ISG}) {
            $RAD_REPLY{'DHCP-Your-IP-Address'}       = $self->{IP}; #USER_IP;
            $RAD_REPLY{'DHCP-Client-IP-Address'}     = $self->{IP}; #USER_IP;
            $RAD_REPLY{'DHCP-Subnet-Mask'}           = '255.255.255.255' if (!$RAD_REPLY{'DHCP-Subnet-Mask'});
            $RAD_REPLY{'DHCP-IP-Address-Lease-Time'} = $self->{LEASES_TIME};
          }
          else {
            my $CALLS_WHERE = ($conf->{NAS_PORT_AUTH} && ! in_array($NAS->{NAS_ID}, \@SWITCH_MAC_AUTH)) ? "c.nas_port_id='$user_auth_params{PORT}'" : "c.cid='$USER_MAC'";

            if($NAS->{NAS_ID}) {
              $CALLS_WHERE .= " AND nas_id='$NAS->{NAS_ID}'";
            }

            #Check internet_online for active session
            my $sql = "SELECT c.user_name FROM internet_online c
              WHERE c.framed_ip_address=INET_ATON('$self->{IP}') AND $CALLS_WHERE;";

            $self->query2($sql);

            if ($self->{TOTAL}) {
              $RAD_REPLY{'User-Name'}                  = $self->{list}->[0]->[0];
              $RAD_REPLY{'DHCP-Your-IP-Address'}       = $self->{IP}; #USER_IP;
              $RAD_REPLY{'DHCP-Client-IP-Address'}     = $self->{IP}; #USER_IP;
              $RAD_REPLY{'DHCP-Subnet-Mask'}           = '255.255.255.255' if (!$RAD_REPLY{'DHCP-Subnet-Mask'});
              $RAD_REPLY{'DHCP-IP-Address-Lease-Time'} = $self->{LEASES_TIME};
              $self->query2("UPDATE internet_online c SET
                lupdated=UNIX_TIMESTAMP(),
                status=3
                WHERE framed_ip_address=INET_ATON('$self->{IP}') AND $CALLS_WHERE;", 'do');
            }
            #else {
            #$user_auth_params{MESSAGE} = ' Dv not found'. $sql;
            #$self->mk_rad_log(\%user_auth_params);
            #return 6, \%RAD_REPLY;
            #}
          }

          $self->query2("SELECT INET_NTOA(netmask) AS netmask,
             dns,
             ntp,
             INET_NTOA(gateway) AS gateway,
             id
          FROM ippools
          WHERE ip<=INET_ATON('$self->{IP}') AND INET_ATON('$self->{IP}')<=ip+counts
          ORDER BY netmask
          LIMIT 1", undef, { INFO => 1 });

          $RAD_REPLY{'DHCP-Router-Address'}= $self->{GATEWAY} if($self->{GATEWAY});
          $RAD_REPLY{'DHCP-NTP-Servers'}   = $self->{NTP} if($self->{NTP});
          if($self->{DNS}) {
            my @dns_arr = split(/,/, $self->{DNS});
            if ($self->{DNS2}) {
              push @dns_arr, $self->{DNS2};
            }
            $RAD_REPLY{'DHCP-Domain-Name-Server'} = \@dns_arr;
          }

          rad_pairs_former($NAS->{NAS_RAD_PAIRS}, { RAD_PAIRS => \%RAD_REPLY });
          $user_auth_params{IP}                    = $USER_IP;
          $user_auth_params{MESSAGE}               = ' RENEW REQUEST';
          $user_auth_params{LOGIN}                 = $RAD_REPLY{'User-Name'};
          $self->{INFO} .= ' RENEW REQUEST';

          $self->mk_rad_log(\%user_auth_params);
          return 2, \%RAD_REPLY;
        }
        else {
          $self->{IP}='0.0.0.0';
          $self->{RESERVED_IP}=0;
        }
      }
      #if request not in dhcp_leases
      elsif($user_auth_params{REQUEST_TYPE} eq 'DHCP-Request') {
        $self->{INFO} .= $user_auth_params{REQUEST_TYPE};
        return 6, \%RAD_REPLY;
      }
    }
  }
  #===== ISG Section
  #Make TP
  elsif ($RAD_REQUEST->{'User-Name'} && $RAD_REQUEST->{'User-Name'} =~ /^TP_|^CUSTOM_SPEED_/) {
    %RAD_REPLY = ();
    return $self->make_tp($RAD_REQUEST, $NAS);
  }
  #Cisco ISG IP auth
  elsif ($RAD_REQUEST->{'User-Name'} && $RAD_REQUEST->{'User-Name'} =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
    #Get static DHCP address
    %RAD_REPLY = ();
    $RAD_REQUEST->{'Calling-Station-Id'}= $RAD_REQUEST->{'User-Name'};
    $RAD_REQUEST->{'Framed-IP-Address'} = $RAD_REQUEST->{'User-Name'};

    $self->query2("SELECT internet.cid,
      INET_NTOA(internet.netmask),
      uid
      FROM internet_main internet
    WHERE internet.ip=INET_ATON( ? );",
      undef,
      { Bind => [ $RAD_REQUEST->{'User-Name'} ] }
    );

    $conf->{INTERNET_AUTH_IP}=1;
    if ($self->{TOTAL} > 0
       && ($self->{list}->[0]->[0] ne '00:00:00:00:00:00' || $conf->{INTERNET_AUTH_IP})) {
      if($self->{list}->[0]->[0] && $self->{list}->[0]->[0] ne '00:00:00:00:00:00') {
        ($RAD_REQUEST->{'User-Name'}) = $self->{list}->[0]->[0];
      }
      else {
        $uid = $self->{list}->[0]->[2];
      }
    }
    else {
      #$self->query2("SELECT hardware, UNIX_TIMESTAMP(ends)-UNIX_TIMESTAMP(), uid FROM dhcphosts_leases
      #    WHERE ip=INET_ATON( ? )", undef, { Bind => [ $RAD_REQUEST->{'User-Name'} ] } );
      $self->query2("SELECT cid, 600, uid, service_id FROM internet_online
          WHERE framed_ip_address=INET_ATON( ? )", undef, { Bind => [ $RAD_REQUEST->{'User-Name'} ] } );

      if ($self->{TOTAL} > 0) {
        ($RAD_REQUEST->{'User-Name'}, $RAD_REPLY{'Session-Timeout'}) = @{ $self->{list}->[0] };
        delete $RAD_REPLY{'Session-Timeout'} if ($RAD_REPLY{'Session-Timeout'} <= 0);
        if ($conf->{ISG_DHCP_UID}) {
          $uid =  $self->{list}->[0]->[2];
        }
      }
      else {
        $RAD_REPLY{'Reply-Message'} = "NOT_REGISTER";
        return 1, \%RAD_REPLY;
      }
    }

    if ($RAD_REQUEST->{'User-Name'} eq '') {
      $RAD_REPLY{'Reply-Message'} = "Can't find MAC in DHCP";
      return 1, \%RAD_REPLY;
    }
  }
  elsif ($RAD_REQUEST->{'User-Name'} !~ /\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}/) {
    if ($NAS->{NAS_ALIVE}) {
      $RAD_REPLY{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE};
    }
    if (! $RAD_REQUEST->{'Service-Type'} ) {
      return 0, \%RAD_REPLY;
    }
  }
  #===== Freeradius dhcp
  elsif ($USER_MAC) {
    $RAD_REQUEST->{'User-Name'} = $USER_MAC;
  }

  my $service='';
  if (! $conf->{DHCPHOSTS_ISG} || ! $uid) {
    #Get user info
    $self->user_info($RAD_REQUEST, {
      SERVICE_ID => $self->{SERVICE_ID},
      UID        => $uid
    });

    if ($self->{errno} && $self->{errno} ne 2) {
      if (! $self->{USER_NAME}) {
        %RAD_REPLY=();
      }

      $RAD_REPLY{'Reply-Message'} = $self->{errstr} .' PI '. $RAD_REQUEST->{'User-Name'};
      $RAD_REQUEST->{'User-Name'} = $RAD_REQUEST->{'Calling-Station-Id'} if ($RAD_REQUEST->{'Calling-Station-Id'});
      return 1, \%RAD_REPLY;
    }
    elsif ($self->{TOTAL} < 1) {
#      if ($conf->{INTERNET_GUEST_POOLS}) {
        my ($ret, $R_REPLY) =  $self->guest_mode($RAD_REQUEST, $NAS, "USER_NOT_FOUND", \%user_auth_params);

        if($NAS->{NAS_TYPE} eq 'dhcp') {
          ($ret, $R_REPLY) = $self->dhcp_rad_reply($RAD_REQUEST, $NAS, \%user_auth_params);
          $RAD_REPLY{'DHCP-Router-Address'} = $self->{GATEWAY} if ($self->{GATEWAY});
        }

        return $ret, $R_REPLY;
        #goto DHCP_REQUEST_SEND;
#      }
#      else {
#        $self->{errno}  = 2;
#        $self->{errstr} = 'ERROR_NOT_EXIST';
#
#        $RAD_REPLY{'Reply-Message'} = "User Not Exist '" . $RAD_REQUEST->{'User-Name'} . "' $user_auth_params{NAS_MAC}/$user_auth_params{PORT}";
#        return 1, \%RAD_REPLY;
#      }
    }
    elsif ($self->{EXPIRED}) {
      if ($conf->{INTERNET_GUEST_POOLS}) {
        my ($ret, $R_REPLY) =  $self->guest_mode($RAD_REQUEST, $NAS, "ACCOUNT_EXPIRED",
          \%user_auth_params);
        ($ret, $R_REPLY) = $self->dhcp_rad_reply($RAD_REQUEST, $NAS, \%user_auth_params);
        return $ret, $R_REPLY;
        #goto DHCP_REQUEST_SEND;
      }
      else {
        $RAD_REPLY{'Reply-Message'} = "ACCOUNT_EXPIRED";
      }

      return 1, \%RAD_REPLY;
    }
    elsif (! defined($self->{PAYMENT_TYPE})) {
      $RAD_REPLY{'Reply-Message'} = "Service not allow";
      return 1, \%RAD_REPLY;
    }

    $RAD_REPLY{'User-Name'}  = $self->{USER_NAME};
    $user_auth_params{LOGIN} = $self->{USER_NAME};

    #DIsable
    if ($self->{INTERNET_DISABLE} || $self->{USER_DISABLE}) {
      if ($conf->{INTERNET_STATUS_NEG_DEPOSIT}) {
        my ($ret, $R_REPLY) =  $self->guest_mode($RAD_REQUEST, $NAS, "ACCOUNT_DISABLE: $self->{INTERNET_DISABLE}/$self->{USER_DISABLE}",
          \%user_auth_params);
        ($ret, $R_REPLY) = $self->dhcp_rad_reply($RAD_REQUEST, $NAS, \%user_auth_params);
        return $ret, $R_REPLY;
      }
      else {
        $RAD_REPLY{'Reply-Message'} = "ACCOUNT_DISABLE $self->{INTERNET_DISABLE}/$self->{USER_DISABLE}";
      }

      return 1, \%RAD_REPLY;
    }

    $service = "TP_$self->{TP_ID}";

    #Get balance state
    if ($self->{PAYMENT_TYPE} == 0) {
      $self->{CREDIT}  = $self->{TP_CREDIT} if ($self->{CREDIT} == 0);
      $self->{DEPOSIT} = $self->{DEPOSIT} + $self->{CREDIT} - $self->{CREDIT_TRESSHOLD};

      #Check deposit
      if ($self->{DEPOSIT} <= 0) {
        #my $mac = $RAD_REQUEST->{'DHCP-Client-Hardware-Address'} || 'unknown_mac';
        if ($conf->{INTERNET_GUEST_POOLS} || $self->{NEG_DEPOSIT_IPPOOL}) {
          my ($ret, $R_REPLY) = $self->guest_mode($RAD_REQUEST, $NAS, "-NEGATIVE_DEPOSIT", \%user_auth_params);
#          my $info = ''; #"-RET: $ret / $user_auth_params{REQUEST_TYPE} ";
#          while(my($k, $v)=each %$R_REPLY) {
#            $info .= "$k=$v,";
#          }

          %RAD_REPLY = ( %RAD_REPLY, %$R_REPLY );
          if (! $ret) {
            ($ret, $R_REPLY) = $self->dhcp_rad_reply($RAD_REQUEST, $NAS, \%user_auth_params);
          }
          elsif($user_auth_params{REQUEST_TYPE} eq 'DHCP-Request') {
            $ret = 6;
          }
          #          my $info = "-RET: $ret / $user_auth_params{REQUEST_TYPE} ";
          #          while(my($k, $v)=each %$R_REPLY) {
          #            $info .= "$k=$v,";
          #          }
          #           `echo "\n=============\n\n$info " >> /tmp/neg`
          return $ret, $R_REPLY;
        }
        elsif (!$self->{NEG_DEPOSIT_FILTER_ID}) {
          $RAD_REPLY{'Reply-Message'} = "Negativ deposit '$self->{DEPOSIT}'. Rejected!";
          return 1, \%RAD_REPLY;
        }
        $self->{GUEST_MODE}=1;
        $service = $self->{NEG_DEPOSIT_FILTER_ID};
      }
      else {
        $self->{GUEST_LEASES}=0;
      }
    }
    else {
      $self->{DEPOSIT} = 0;
    }
  }

  if ($NAS->{NAS_TYPE} ne 'cisco_isg') {
    #If discover check exist ip
    if ($user_auth_params{REQUEST_TYPE} eq 'DHCP-Discover') {
#      if ($self->{GUEST_MODE} == 0 && $self->{DHCP_STATIC_IP} && $self->{DHCP_STATIC_IP} ne '0.0.0.0') {
#        $self->{IP} = $self->{DHCP_STATIC_IP}
#      }
#      else {
#        $self->leases_get({ %user_auth_params, GUEST => $self->{GUEST_MODE} }, $NAS);
#      }
      if ($self->{IP} && $self->{GUEST_MODE} == 0) {

      }
      else {
        $self->leases_get({ %user_auth_params, GUEST => $self->{GUEST_MODE} }, $NAS);
      }
    }

    # Get dynamic IP
    if (! $self->{IP} || $self->{IP} eq '0.0.0.0') {
      if ($user_auth_params{REQUEST_TYPE} eq "DHCP-Request") {
        $user_auth_params{MESSAGE}  = " RENEW_REQUEST_CLIENT_IP: $USER_IP";
        $self->mk_rad_log(\%user_auth_params);
        $RAD_REPLY{'Reply-Message'}=$user_auth_params{MESSAGE}.' ';
        return 6, \%RAD_REPLY;
      }

      $self->{IP} = $self->Auth2::get_ip($NAS->{NAS_ID}, $RAD_REQUEST->{'NAS-IP-Address'}, { TP_IPPOOL => $self->{TP_IPPOOL} });

      $RAD_REPLY{'DHCP-Subnet-Mask'}    = $self->{NETMASK} if ($self->{NETMASK});
      $RAD_REPLY{'DHCP-Router-Address'} = $self->{GATEWAY} if ($self->{GATEWAY});
      $RAD_REPLY{'DHCP-NTP-Servers'}    = $self->{NTP}     if ($self->{NTP});
      if($self->{DNS}) {
        my @dns_arr = split(/,/, $self->{DNS});
        if ($self->{DNS2}) {
          push @dns_arr, $self->{DNS2};
        }
        $RAD_REPLY{'DHCP-Domain-Name-Server'} = \@dns_arr;
      }

      if ($self->{IP} eq '-1') {
        $RAD_REPLY{'Reply-Message'} = "Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS})";
        return 1, \%RAD_REPLY;
      }
      elsif ($self->{IP} eq '0') {
      }
    }
#    else {
#
#    }

    #DHCP_REQUEST_SEND:
    my ($ret, $R_REPLY) = $self->dhcp_rad_reply($RAD_REQUEST, $NAS, \%user_auth_params);
    return $ret, $R_REPLY;
  }
  #Cisco ISG section
  else {
    $self->{GUEST}=0;
    $self->user_info($RAD_REQUEST, {
      UID       => $uid,
      SERVICE_ID=> $self->{SERVICE_ID},
    });

    $service = "TP_$self->{TP_ID}";
    if ($self->{EXPIRED}) {
      $RAD_REPLY{'Reply-Message'} = "Account Expired";
      return 1, \%RAD_REPLY;
    }
    elsif (! defined($self->{PAYMENT_TYPE})) {
      $RAD_REPLY{'Reply-Message'} = "ISG Service not allow UID: $uid";
      return 1, \%RAD_REPLY;
    }
    #Mac registration
    elsif ($conf->{ISG_CHECK_MAC} && ! $self->{CID}) {
      $RAD_REPLY{'Reply-Message'} = "CID NOT FILLED UID: $uid ID: $self->{SERVICE_ID}";
      return 1, \%RAD_REPLY;
    }
    # DISABLE
    elsif ($self->{INTERNET_DISABLE} || $self->{USER_DISABLE}) {
      if (!$self->{NEG_DEPOSIT_FILTER_ID}) {
        $RAD_REPLY{'Reply-Message'} = "ACCOUNT_DISABLE2 $self->{INTERNET_DISABLE} / $self->{USER_DISABLE}";
        return 1, \%RAD_REPLY;
      }
      $self->{GUEST}=1;
      $service = $self->{NEG_DEPOSIT_FILTER_ID};
    }
    elsif ($self->{PAYMENT_TYPE} == 0) {
      $self->{CREDIT}  = $self->{TP_CREDIT} if ($self->{CREDIT} == 0);
      $self->{DEPOSIT} = $self->{DEPOSIT} + $self->{CREDIT} - $self->{CREDIT_TRESSHOLD};

      #Check deposit
      if ($self->{DEPOSIT} <= 0) {
        if (!$self->{NEG_DEPOSIT_FILTER_ID}) {
          $RAD_REPLY{'Reply-Message'} = "Negativ deposit '$self->{DEPOSIT}'. Rejected!";
          return 1, \%RAD_REPLY;
        }
        $self->{GUEST}=1;
        $service = $self->{NEG_DEPOSIT_FILTER_ID};
      }
    }

    #Traffic limit section
    my @time_limits    = ();
    #Periods Time and traf limits
    # 0 - Total limit
    # 1 - Day limit
    # 2 - Week limit
    # 3 - Month limit
    #my @traf_limits = ();
    my $time_limit = $self->{TIME_LIMIT};
    my $traf_limit;
    my @direction_sum = ("SUM(sent + recv) / $conf->{MB_SIZE} + SUM(acct_output_gigawords) * 4096 + SUM(acct_input_gigawords) * 4096", "SUM(recv) / $conf->{MB_SIZE} + SUM(acct_input_gigawords) * 4096", "SUM(sent) / $conf->{MB_SIZE} + SUM(acct_output_gigawords) * 4096");
    push @time_limits, $self->{MAX_SESSION_DURATION} if ($self->{MAX_SESSION_DURATION} > 0);

    my @periods = ('TOTAL', 'DAY', 'WEEK', 'MONTH');
    my %SQL_params = (
      TOTAL => '',
      DAY   => "AND DATE_FORMAT(start, '%Y-%m-%d')=CURDATE()",
      WEEK  => "AND (YEAR(CURDATE())=YEAR(start)) AND (WEEK(CURDATE()) = WEEK(start))",
      MONTH => "AND DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m')"
    );

    my $WHERE = "uid='$self->{UID}'";

    foreach my $line (@periods) {
      if ($self->{ $line . '_TRAF_LIMIT' } > 0) {
        my $session_time_limit = $time_limit;
        my $session_traf_limit = $traf_limit;
        $self->query2("SELECT IF("
          . ($self->{ $line . '_TIME_LIMIT' } || 0)
          . " > 0, "
          . ($self->{ $line . '_TIME_LIMIT' } || 0)
          . " - SUM(duration), 0),
                                  IF(" . $self->{ $line . '_TRAF_LIMIT' } . " > 0, " . $self->{ $line . '_TRAF_LIMIT' } . " - $direction_sum[$self->{OCTETS_DIRECTION}], 0),
                                  1
            FROM internet_log
            WHERE $WHERE $SQL_params{$line}
            GROUP BY 3;"
        );

        if ($self->{TOTAL} == 0) {
          push(@time_limits, $self->{ $line . '_TIME_LIMIT' }) if ($self->{ $line . '_TIME_LIMIT' } > 0);
          $session_traf_limit = $self->{ $line . '_TRAF_LIMIT' } if ($self->{ $line . '_TRAF_LIMIT' } && $self->{ $line . '_TRAF_LIMIT' } > 0);
        }
        else {
          ($session_time_limit, $session_traf_limit) = @{ $self->{list}->[0] };
          push(@time_limits, $session_time_limit) if ($self->{ $line . '_TIME_LIMIT' } && $self->{ $line . '_TIME_LIMIT' } > 0);
        }

        if ($self->{ $line . '_TRAF_LIMIT' } && $self->{ $line . '_TRAF_LIMIT' } > 0 && (! $traf_limit || $traf_limit > $session_traf_limit )) {
          $traf_limit = $session_traf_limit;
        }

        if (defined($traf_limit) && $traf_limit <= 0) {
          $RAD_REPLY{'Reply-Message'} = "Rejected! $line Traffic limit utilized '$traf_limit Mb'";
          if ($self->{NEG_DEPOSIT_FILTER_ID}) {
            rad_pairs_former($self->{NEG_DEPOSIT_FILTER_ID} || $NAS->{NAS_RAD_PAIRS}, { RAD_PAIRS => \%RAD_REPLY });
            #return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID}, { MESSAGE => $RAD_PAIRS->{'Reply-Message'} });
            return 0, \%RAD_REPLY;
          }

          return 1, \%RAD_REPLY;
        }
      }
    }

    #IP
    if ($self->{IP} ne '0.0.0.0') {
      $RAD_REPLY{'Framed-IP-Address'} = $self->{IP};
    }

    delete $RAD_REPLY{'Cisco-Account-Info'}, $RAD_REPLY{'Cisco-Service-Info'}, $RAD_REPLY{'Cisco-Control-Info'};

    #$traf_tarif
    my $EX_PARAMS = $self->ex_traffic_params({
      traf_limit  => $traf_limit,
      deposit     => $self->{DEPOSIT},
      TT_INTERVAL => $self->{INTERVAL_ID}
    });

    if ($EX_PARAMS->{ex_speed}) {
      $service = "CUSTOM_SPEED_$EX_PARAMS->{ex_speed}";
      push @{ $RAD_REPLY{'Cisco-Account-Info'} }, "A$service";
    }
    elsif ($self->{TT_COUNTS} > 0) {
      $self->query2("SELECT tt.id, i.id AS interval_id, TIME_TO_SEC(TIMEDIFF(i.end, DATE_FORMAT(NOW(), '%H:%i:%S' )))
        FROM trafic_tarifs tt
        INNER JOIN intervals i ON (tt.interval_id=i.id)
        WHERE i.tp_id='$self->{TP_ID}'
          AND (i.begin <= DATE_FORMAT( NOW(), '%H:%i:%S' )
               AND i.end >= DATE_FORMAT( NOW(), '%H:%i:%S' )
          );");

      foreach my $line (@{ $self->{list} }) {
        if (!$RAD_REPLY{'Cisco-Service-Info'}) {
          $RAD_REPLY{'Cisco-Service-Info'} = "ATP_$self->{TP_ID}_$line->[0]_$line->[1]";
          push @{ $RAD_REPLY{'Cisco-Account-Info'} }, "NTP_$self->{TP_ID}_$line->[0]_$line->[1]";
          push @{ $RAD_REPLY{'Cisco-Control-Info'} }, "QV1000000";
        }

        $RAD_REPLY{'Session-Timeout'}=$line->[2] if ($self->{TOTAL} > 1);
        push @{ $RAD_REPLY{'Cisco-Account-Info'} }, "ATP_$self->{TP_ID}_$line->[0]_$line->[1]";
      }
    }
    else {
      push @{ $RAD_REPLY{'Cisco-Account-Info'} }, "A$service";
    }

    if ($conf->{ISG_SERVICES}) {
      my @services_arr = split(/;/, $conf->{ISG_SERVICES});
      foreach my $service_ (@services_arr) {
        push @{ $RAD_REPLY{'Cisco-Account-Info'} }, "$service_";
      }
    }

    $RAD_REPLY{'Service-Type'} = "Dialout-Framed-User";
    $RAD_REPLY{'User-Name'}    = $self->{USER_NAME};
    $RAD_REPLY{'Idle-Timeout'} = 120;
    $RAD_REQUEST->{'User-Name'}= $self->{USER_NAME};
    # Accounting group defined in
    my $accounting_group = $conf->{ISG_ACCOUNTING_GROUP} || 'ISG-AUTH-1';
    push @{ $RAD_REPLY{'cisco-avpair'} }, "subscriber:accounting-list=$accounting_group";
    if ($NAS->{NAS_ALIVE}) {
      $RAD_REPLY{'Acct-Interim-Interval'}=$NAS->{NAS_ALIVE};
    }

    $self->online_add({
      #%$attr,
      NAS_ID            => $NAS->{NAS_ID},
      FRAMED_IP_ADDRESS => "INET_ATON('". ($RAD_REQUEST->{'Framed-IP-Address'} || $self->{IP} ) ."')",
      USER_NAME         => $self->{USER_NAME},
      UID               => $self->{UID},
      NAS_IP_ADDRESS    => $RAD_REQUEST->{'NAS-IP-Address'},
      CONNECT_INFO      => ($RAD_REPLY{'Cisco-Account-Info'}[0] || '') .'_s',
      #CID               => $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'},
      GUEST             => $self->{GUEST} || 0
    });
  }

  #Access grant
  return 0, \%RAD_REPLY;
}

#**********************************************************
=head2 make_tp($RAD_REQUEST, $NAS) - Make Cisco ISG TP


=cut
#**********************************************************
sub make_tp {
  my $self = shift;
  my ($RAD_REQUEST, $NAS) = @_;

  my %speeds = ();
  my %expr   = ();
  my %names  = ();
  my $TP_ID  = 0;
  my $TT_ID  = 0;
  my $WHERE  = '';
  my $RAD_REPLY;

  if ($RAD_REQUEST->{'User-Name'} =~ /TP_(\d+)_(\d+)_(\d+)/) {
    $TP_ID = $1;
    $TT_ID = $2;
    my $INTERVAL_ID = $3;
    $WHERE = "AND tt.id='$TT_ID' AND i.id='$INTERVAL_ID'";
  }
  elsif ($RAD_REQUEST->{'User-Name'} =~ /TP_(\d+)_(\d+)/) {
    $TP_ID = $1;
    $TT_ID = $2;
    $WHERE = "AND tt.id='$TT_ID'";
  }
  elsif ($RAD_REQUEST->{'User-Name'} =~ /TP_(\d+)/) {
    $TP_ID = $1;
  }
  elsif($RAD_REQUEST->{'User-Name'} =~ /^CUSTOM_SPEED_(\d+)/) {
    my $speed = $1;
    $RAD_REPLY->{'Cisco-Service-Info'} = "Q$speed;$speed";
    return 0, $RAD_REPLY;
  }

  $self->query2("SELECT
  UNIX_TIMESTAMP() AS session_start ,
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) as day_of_week,
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year,
  tp.payment_type,
  tp.rad_pairs AS tp_rad_reply,
  tt.in_speed,
  tt.out_speed,
  tp.tp_id,
  tt.id AS traffic_class,
  tt.prepaid AS traffic_prepaid
     FROM tarif_plans tp
     LEFT JOIN intervals i ON (tp.tp_id = i.tp_id)
     LEFT JOIN trafic_tarifs tt ON (tt.interval_id = i.id)
     WHERE tp.tp_id='$TP_ID' $WHERE;",
    undef,
    { INFO => 1 }
  );

  if ($self->{errno}) {
    if ($self->{errno} == 2) {
      $RAD_REPLY->{'Reply-Message'} = "Can't find TP '$TP_ID' TT: '$TT_ID'";
    }
    else {
      $RAD_REPLY->{'Reply-Message'} = 'SQL error';
    }
    return 1, $RAD_REPLY;
  }

  my $default_access_list = $conf->{ISG_ACCESS_LIST} || 196;

  if ($self->{IN_SPEED} && $self->{TRAFFIC_CLASS}) {
    my $traffic_priority = ($conf->{ISG_TRAFFIC_PRIORITY}) ? $conf->{ISG_TRAFFIC_PRIORITY} : (6 - $self->{TRAFFIC_CLASS});

    push @{ $RAD_REPLY->{'cisco-avpair'} }, "ip:traffic-class=in access-group " .  (100 + $self->{TRAFFIC_CLASS} + 1) . " priority " . $traffic_priority;
    push @{ $RAD_REPLY->{'cisco-avpair'} }, "ip:traffic-class=out access-group " . (100 + $self->{TRAFFIC_CLASS} + 1) . " priority " . $traffic_priority;
  }
  else {
    my $traffic_priority = ($conf->{ISG_TRAFFIC_PRIORITY}) ? $conf->{ISG_TRAFFIC_PRIORITY} : (6 - $self->{TRAFFIC_CLASS});

    push @{ $RAD_REPLY->{'cisco-avpair'} }, "ip:traffic-class=in access-group $default_access_list priority $traffic_priority";
    push @{ $RAD_REPLY->{'cisco-avpair'} }, "ip:traffic-class=out access-group $default_access_list priority $traffic_priority";
    push @{ $RAD_REPLY->{'cisco-avpair'} }, "ip:traffic-class=out default drop";
    push @{ $RAD_REPLY->{'cisco-avpair'} }, "ip:traffic-class=in default drop";

    my $accounting_group = $conf->{ISG_ACCOUNTING_GROUP} || 'ISG-AUTH-1';
    push @{ $RAD_REPLY->{'cisco-avpair'} }, "subscriber:accounting-list=$accounting_group";
    push @{ $RAD_REPLY->{'cisco-avpair'} }, "prepaid-config=TRAFFIC_PREPAID" if ($self->{TRAFFIC_PREPAID});
  }

  if ($NAS->{NAS_ALIVE}) {
    $RAD_REPLY->{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE};
  }

  #$self->get_rad_pairs(\%RAD_REPLY, $NAS, { RAD_PAIRS => $self->{TP_RAD_PAIRS} });
  rad_pairs_former($self->{TP_RAD_PAIRS} || $NAS->{NAS_RAD_PAIRS}, { RAD_PAIRS => \%RAD_REPLY });

  ($self->{TIME_INTERVALS}, $self->{INTERVAL_TIME_TARIF}, $self->{INTERVAL_TRAF_TARIF}) = $Billing->time_intervals($self->{TP_ID});

  my (undef, $ret_attr) = $Billing->remaining_time(
    0,
    {
      TIME_INTERVALS      => $self->{TIME_INTERVALS},
      INTERVAL_TIME_TARIF => $self->{INTERVAL_TIME_TARIF},
      INTERVAL_TRAF_TARIF => $self->{INTERVAL_TRAF_TARIF},
      SESSION_START       => $self->{SESSION_START},
      DAY_BEGIN           => $self->{DAY_BEGIN},
      DAY_OF_WEEK         => $self->{DAY_OF_WEEK},
      DAY_OF_YEAR         => $self->{DAY_OF_YEAR},
      REDUCTION           => 0,
      POSTPAID            => 1,
      GET_INTERVAL        => 1
    }
  );

  my %TT_IDS = %$ret_attr;

  if (keys %TT_IDS > 0) {
    require Tariffs;
    Tariffs->import();
    my $tariffs = Tariffs->new($self->{db}, $conf, undef);

    #Get intervals
    while (my ($k, $v) = each(%TT_IDS)) {
      next if ($k ne 'TT');
      my $list = $tariffs->tt_list({ TI_ID => $v });
      foreach my $line (@$list) {
        $speeds{ $line->[0] }{IN}  = "$line->[4]";
        $speeds{ $line->[0] }{OUT} = "$line->[5]";
        $names{ $line->[0] }       = ($line->[6]) ? "$line->[6]" : "Service_$line->[0]";
        $expr{ $line->[0] }        = "$line->[8]" if (length($line->[8]) > 5);
      }
    }
  }

  my $speed          = $speeds{$TT_ID};
  my $speed_in       = (defined($speed->{IN})) ? $speed->{IN} : 0;
  my $speed_out      = (defined($speed->{OUT})) ? $speed->{OUT} : 0;
  my $speed_in_rule  = '';
  my $speed_out_rule = '';

  if ($speed_in > 0) {
    $speed_in_rule = "D;" . ($speed_in * 1000) . ";" . ($speed_in / 8 * 1000) . ';' . ($speed_in / 4 * 1000) . ';';
  }

  if ($speed_out > 0) {
    $speed_out_rule = "U;" . ($speed_out * 1000) . ";" . ($speed_out / 8 * 1000) . ';' . ($speed_out / 4 * 1000);
  }

  if ($speed_in_rule ne '' || $speed_out_rule ne '') {
    $RAD_REPLY->{'Cisco-Service-Info'} = "Q$speed_out_rule;$speed_in_rule";
  }

  return 0, $RAD_REPLY;
}

#**********************************************************
=head2 guest_mode($RAD_REQUEST, $NAS, $message, $attr) - Enable guest mode

  Arguments:
    $RAD_REQUEST
    $NAS
    $message
    $attr

  Returns:
    0, \%RAD_REPLY;

=cut
#**********************************************************
sub guest_mode {
  my $self = shift;
  my ($RAD_REQUEST, $NAS, $message, $attr) = @_;

  my $ip_pool;

  if($conf->{INTERNET_GUEST_POOLS}) {
    # Add extra radius params
    if ($attr->{VLAN} && $GUEST_POOLS{$attr->{VLAN}}{RAD_REPLY}) {
      %RAD_REPLY = (%RAD_REPLY, %{ $GUEST_POOLS{$attr->{VLAN}}{RAD_REPLY} });
      $ip_pool  = $GUEST_POOLS{$attr->{VLAN}}{POOL_ID};
    }
    elsif ($GUEST_POOLS{0}{RAD_REPLY}) {
      %RAD_REPLY = (%RAD_REPLY, %{ $GUEST_POOLS{0}{RAD_REPLY} });
      $ip_pool  = $GUEST_POOLS{0}{POOL_ID};
    }
#NOw take Guest pools from servers
#       else {
#      $self->{errno}  = 2;
#      $self->{errstr} = $message. " GUEST_POOLS not defined";
#      $RAD_REPLY{'Reply-Message'} = $message;
#      return 1, \%RAD_REPLY;
#    }
  }
  elsif( $self->{NEG_DEPOSIT_IPPOOL}) {
    $ip_pool  = $self->{NEG_DEPOSIT_IPPOOL};
  }
#  elsif($conf->{INTERNET_GUEST_STATIC_IP}) {
#
#  }
  #Cna't find neg deposit params
  elsif(! $self->{NEG_DEPOSIT_FILTER_ID} && $message ne 'USER_NOT_FOUND') {
    $RAD_REPLY{'Reply-Message'}=$message;
    return 1, \%RAD_REPLY;
  }
  #NOw take Guest pools from servers
#  else {
#    $self->{errno}  = 2;
#    $self->{errstr} = $message. " GUEST_POOLS not defined";
#    $RAD_REPLY{'Reply-Message'} = $message;
#    return 1, \%RAD_REPLY;
#  }

  $self->{GUEST_MODE} = 1;
  $self->{GUEST}      = 1;
  $self->{INFO}      .= " $message";

  # my $WHERE           = '';
  # if ($conf->{NAS_PORT_AUTH} && ! in_array($NAS->{NAS_ID}, \@SWITCH_MAC_AUTH)) {
  #   $WHERE = ($attr->{PORT} > 0) ? "AND switch_port='$attr->{PORT}' " : '';
  #   $WHERE .= "AND switch_mac='$attr->{NAS_MAC}' ";
  # }
  # else {
  #   $WHERE .= "AND hardware='$attr->{USER_MAC}' ";
  # }

  if ( $conf->{INTERNET_GUEST_STATIC_IP}) {
#    $WHERE .= "AND hardware='$attr->{USER_MAC}' ";
  }
  else {
#    $WHERE .= "AND ends > NOW() ";
    $self->{IP}=0;
  }

  $self->query2("SELECT INET_NTOA(framed_ip_address) AS ip, guest, 300 AS leases_time FROM internet_online
      WHERE cid='". $attr->{USER_MAC} ."' AND guest='$self->{GUEST_MODE}' ;", undef, { COLS_NAME => 1 });

  # In leases
  if ($self->{TOTAL} > 0) {
    if ($self->{TOTAL} == 1 && $self->{list}->[0]->{leases_time} <= 0) {
#      $self->query2("UPDATE dhcphosts_leases SET ends=NOW() + INTERVAL " . (($self->{LEASES_TIME} || $NAS->{NAS_ALIVE}) + 60) . " SECOND
#        WHERE flag=1 AND ip=INET_ATON('$self->{list}->[0]->{ip}') $WHERE;",
#        'do');
    }
    else {
      $attr->{LEASES_TIME} = $self->{list}->[0]->{leases_time};
      $self->{IP}          = $self->{list}->[0]->{ip};
      $self->{GUEST_LEASES}= $self->{list}->[0]->{guest};
      $self->{RESERVED_IP} = 1;
      $self->query2("SELECT INET_NTOA(netmask) AS netmask,
        dns,
        ntp,
        INET_NTOA(gateway) AS gateway,
        id
      FROM ippools
      WHERE ip<=INET_ATON('$self->{IP}') AND INET_ATON('$self->{IP}')<=ip+counts
      ORDER BY netmask
      LIMIT 1", undef, { INFO => 1 });
    }

    rad_pairs_former( $self->{NEG_DEPOSIT_FILTER_ID}, { RAD_PAIRS => \%RAD_REPLY } );
  }
  elsif((! $conf->{INTERNET_GUEST_STATIC_IP} && ! $self->{IP}) || ($message eq 'USER_NOT_FOUND')) {
    #}if($ip_pool) {
    # Send NAK if require not same leases
    #if ( $attr->{REQUIRE_USER_IP} && $attr->{REQUIRE_USER_IP} ne '0.0.0.0'  ) {
    #  return 1, \%RAD_REPLY;
    #}
#    $self->{IP} = $self->get_guest_ip($ip_pool,
#      { %$attr,
#        NAS => $NAS
#      });
    $self->{USER_NAME}=$attr->{USER_MAC};
    $self->{IP} = $self->Auth2::get_ip($NAS->{NAS_ID}, $RAD_REQUEST->{'NAS-IP-Address'}, {
      TP_IPPOOL => $ip_pool,
      GUEST     => 1
    });

    if ($self->{IP} eq '-1') {
      $RAD_REPLY{'Reply-Message'} = "Rejected! There is no free IPs in address pools $ip_pool (USED: $self->{USED_IPS})";
      return 1, \%RAD_REPLY;
    }
    elsif ($self->{IP} eq '0') {
      $RAD_REPLY{'Reply-Message'}="NO_GUEST_IP POOL: $ip_pool $self->{errstr} (NAS: $NAS->{NAS_ID})" . $self->{INFO};
      return 1, \%RAD_REPLY;
    }

    if($self->{NEG_DEPOSIT_FILTER_ID}) {
      rad_pairs_former($self->{NEG_DEPOSIT_FILTER_ID}, { RAD_PAIRS => \%RAD_REPLY });
    }

    # Add IP to leases
    if (! $attr->{LEASES_TIME}) {
      $attr->{LEASES_TIME}=$conf->{DHCPHOSTS_SESSSION_TIMEOUT} || 600;
    }
    elsif ($RAD_REPLY{'Session-Timeout'}) {
      $attr->{LEASES_TIME}=$RAD_REPLY{'Session-Timeout'};
    }
    else {
      $attr->{LEASES_TIME}=$NAS->{NAS_ALIVE} || $conf->{INTERNET_SESSSION_TIMEOUT};
    }

    $RAD_REPLY{'Reply-Message'}=$message. ", Pool: $ip_pool";
  }

  if(! $RAD_REPLY{'Session-Timeout'}) {
    $RAD_REPLY{'Session-Timeout'} = $NAS->{NAS_ALIVE} || $conf->{INTERNET_SESSSION_TIMEOUT};
  }

  $RAD_REPLY{'Framed-IP-Address'} = $self->{IP} if ($self->{IP} && $self->{IP} !~ /0\.0\.0\.0/);
  #$self->{UID}   = 0 if (! $self->{UID});
  #$self->{TP_ID} = 0 if (! $self->{TP_ID});

  $self->calls_update($attr, $NAS);
  return 0, \%RAD_REPLY;
}

#**********************************************************
=head2 get_speed()

=cut
#**********************************************************
sub get_speed {
  my $self = shift;

  #Get Speed
  $self->query2("SELECT tp.tp_id, tt.in_speed, tt.out_speed, tt.net_id, tt.expression,
     tt.id AS traffic_class_id,
     burst_limit_ul,
     burst_limit_dl,
     burst_threshold_ul,
     burst_threshold_dl,
     burst_time_ul,
     burst_time_dl

     FROM trafic_tarifs tt
     LEFT JOIN intervals intv ON (tt.interval_id = intv.id)
     LEFT JOIN tarif_plans tp ON (tp.tp_id = intv.tp_id)

    WHERE intv.begin <= DATE_FORMAT( NOW(), '%H:%i:%S' )
      AND intv.end >= DATE_FORMAT( NOW(), '%H:%i:%S' )
      AND tp.tp_id='$self->{TP_ID}'
      AND intv.day IN (SELECT IF ( intv.day=8,
      (SELECT if ((SELECT COUNT(*) FROM holidays WHERE DATE_FORMAT( NOW(), '%c-%e' ) = day)>0, 8,
                (SELECT if (intv.day=0, 0, (SELECT intv.day FROM intervals AS intv WHERE DATE_FORMAT(NOW(), '%w')+1 = intv.day LIMIT 1))))),
       (SELECT IF (intv.day=0, 0,
                (SELECT intv.day FROM intervals AS intv WHERE DATE_FORMAT( NOW(), '%w')+1 = intv.day LIMIT 1)))))
   GROUP BY tp.tp_id, tt.id
   ORDER by tp.tp_id, tt.id DESC; ",
    undef,
    { COLS_NAME => 1 }
  );

  my %speeds = ();
  if ($self->{TOTAL} > 0) {
    foreach my $tp (@{ $self->{list} }) {
      if ($tp->{out_speed} +  $tp->{in_speed} > 0) {
        $speeds{$tp->{traffic_class_id}}{OUT}=$tp->{out_speed} if ($tp->{out_speed} > 0);
        $speeds{$tp->{traffic_class_id}}{IN}=$tp->{in_speed} if ($tp->{in_speed} > 0);

        $speeds{$tp->{traffic_class_id}}{BURST_LIMIT_UL}=$tp->{burst_limit_ul} if ($tp->{burst_limit_ul} > 0);
        $speeds{$tp->{traffic_class_id}}{BURST_LIMIT_DL}=$tp->{burst_limit_dl} if ($tp->{burst_limit_dl} > 0);

        $speeds{$tp->{traffic_class_id}}{BURST_THRESHOLD_UL}=$tp->{burst_threshold_ul} if ($tp->{burst_threshold_ul} > 0);
        $speeds{$tp->{traffic_class_id}}{BURST_THRESHOLD_DL}=$tp->{burst_threshold_dl} if ($tp->{burst_threshold_dl} > 0);

        $speeds{$tp->{traffic_class_id}}{BURST_TIME_UL}=$tp->{burst_time_ul} if ($tp->{burst_time_ul} > 0);
        $speeds{$tp->{traffic_class_id}}{BURST_TIME_DL}=$tp->{burst_time_dl} if ($tp->{burst_time_dl} > 0);
      }
    }
  }

  return \%speeds;
}


#**********************************************************
=head2 leases_get($attr, $NAS) - Get active leases

  Arguments:
    $attr
      NAS_MAC
      USER_MAC
      IP
      GUEST    - Guest  Mode

    $NAS
  Results:

=cut
#**********************************************************
sub leases_get {
  my $self   = shift;
  my ($attr, $NAS) = @_;

  $self->{LEASES_TIME} = 0;
  $self->{RESERVED_IP} = 0;

  my $WHERE   = '';
  if ($conf->{NAS_PORT_AUTH} && ! in_array($NAS->{NAS_ID}, \@SWITCH_MAC_AUTH)) {
    $WHERE = ($attr->{PORT}) ? " switch_port='$attr->{PORT}' AND " : '';
    $WHERE .= "switch_mac='$attr->{NAS_MAC}'";
  }
  else {
    $WHERE .= "cid='$attr->{USER_MAC}'";
  }

  if ($attr->{IP}) {
    $WHERE .= " AND framed_ip_address=INET_ATON('$attr->{IP}')";
  }

  if (defined($attr->{GUEST})) {
    $WHERE .= " AND guest=". (($attr->{GUEST}) ? 1 : 0);
  }

  if ($self->{UID}) {
    $WHERE .= " AND uid='$self->{UID}'";
  }
  else {
    $WHERE .= " AND uid='0'";
  }

  # check work IP
  $self->query2("SELECT 600 AS leases_time,
    INET_NTOA(framed_ip_address) AS ip,
    guest
    FROM internet_online
    WHERE $WHERE
    ORDER BY 1 FOR UPDATE;",
   undef, { COLS_NAME => 1 });

  if ($self->{TOTAL} > 0) {
    $self->{RESERVED_IP} = 1;
    $self->{LEASES_TIME} = $NAS->{NAS_ALIVE} || $conf->{DHCP_SESSSION_TIMEOUT}; # $self->{list}->[0]->{leases_time};
    $self->{IP} = $self->{list}->[0]->{ip};
    $self->{GUEST_LEASES} = $self->{list}->[0]->{guest};

#    $self->query2("UPDATE dhcphosts_leases SET
#          ends=NOW() + INTERVAL " . ($self->{LEASES_TIME} + 30) . " SECOND,
#          hardware='$attr->{USER_MAC}'
#          WHERE ends > NOW() AND ip=INET_ATON('$self->{IP}') AND $WHERE LIMIT 1;", 'do');
  }


  #  # check work IP
#  $self->query2("SELECT UNIX_TIMESTAMP(ends)-UNIX_TIMESTAMP() AS leases_time,
#      INET_NTOA(ip) AS ip, flag FROM dhcphosts_leases
#      WHERE ends > NOW() AND $WHERE
#      ORDER BY 1 FOR UPDATE;",
#    undef, { COLS_NAME => 1 });
#
#  if ($self->{TOTAL} > 0) {
#    $self->{RESERVED_IP} = 1;
#    $self->{LEASES_TIME} = $NAS->{NAS_ALIVE} || $conf->{DHCPHOSTS_SESSSION_TIMEOUT}; # $self->{list}->[0]->{leases_time};
#    $self->{IP}          = $self->{list}->[0]->{ip};
#    $self->{GUEST_LEASES}= $self->{list}->[0]->{flag};
#
#    $self->query2("UPDATE dhcphosts_leases SET
#        ends=NOW() + INTERVAL " . ($self->{LEASES_TIME} + 30) . " SECOND,
#        hardware='$attr->{USER_MAC}'
#        WHERE ends > NOW() AND ip=INET_ATON('$self->{IP}') AND $WHERE LIMIT 1;", 'do');
#  }

  return $self;
}

#**********************************************************
=head2 calls_update($attr, $NAS) - update calls

  Arguments:
    $attr
    $NAS

=cut
#**********************************************************
sub calls_update {
  my $self   = shift;
  my ($attr, $NAS) = @_;

  $conf->{SKIP_UID_CHECK}=1;
  if (! $self->{UID} && ! $conf->{SKIP_UID_CHECK}) {
    return $self;
  }

  my $WHERE = "uid='$self->{UID}'";

  if ($conf->{NAS_PORT_AUTH} && ! in_array($NAS->{NAS_ID}, \@SWITCH_MAC_AUTH)) {
    $WHERE .= " AND nas_port_id='$attr->{PORT}' AND nas_id='$NAS->{NAS_ID}'";
  }
  else {
    $WHERE .= " AND (cid='$attr->{USER_MAC}' OR (cid='' AND status=11))";
  }

  my $acct_session_id = $attr->{SESSION_ID} || "dhcp_$attr->{USER_MAC}_$attr->{PORT}";

  my $sql = "SELECT uid FROM internet_online
    WHERE guest= ?
     AND framed_ip_address=INET_ATON( ? )
     AND $WHERE FOR UPDATE;";

  $self->query2($sql, undef,
    {
      Bind => [
        $self->{GUEST_MODE} || 0,
        $self->{IP}
      ]
    });
  my $guest_mode = $self->{GUEST_MODE} || 0;

  my $o82_params=q{};
  if($attr->{AGENT_REMOTE_ID}) {
    $o82_params = " ,remote_id='$attr->{AGENT_REMOTE_ID}',
       circuit_id='$attr->{CIRCUIT_ID}',
       hostname='$attr->{HOSTNAME}',
       switch_port='$attr->{PORT}',
       vlan='$attr->{VLAN}',
       server_vlan='$attr->{SERVER_VLAN}',
       switch_mac='$attr->{NAS_MAC}'
       ";
  }

  if ($self->{TOTAL}) {
    $sql = "UPDATE internet_online SET
     cid='$attr->{USER_MAC}',
     status=3,
     lupdated=UNIX_TIMESTAMP(),
     nas_port_id='$attr->{PORT}',
     acct_session_id='$acct_session_id',
     connect_info='vlan:$attr->{VLAN}/$attr->{NAS_MAC}'
     $o82_params
     WHERE framed_ip_address=INET_ATON('$self->{IP}') AND $WHERE;";
  }
  else {
    #$self->query2("DELETE FROM internet_online WHERE $WHERE AND (guest <> ? OR guest=1)", 'do', { Bind => [ $self->{GUEST_MODE} || 0 ] });
    $self->query2("UPDATE internet_online SET status = 2 WHERE $WHERE AND guest <> '$guest_mode';", 'do');

    $sql = "INSERT INTO internet_online SET
      status='1',
      user_name='$self->{USER_NAME}',
      started=NOW(),
      lupdated=UNIX_TIMESTAMP(),
      nas_ip_address=INET_ATON('$NAS->{NAS_IP}'),
      nas_port_id='$attr->{PORT}',
      acct_session_id='$acct_session_id',
      framed_ip_address=INET_ATON('". ($self->{IP} || '0.0.0.0'). "'),
      cid='$attr->{USER_MAC}',
      connect_info='vlan:$attr->{VLAN}/$attr->{NAS_MAC}',
      nas_id='$NAS->{NAS_ID}',
      tp_id='". ($self->{TP_NUM} || 0) ."',
      uid='$self->{UID}',
      service_id='$self->{SERVICE_ID}',
      guest='$guest_mode'
      $o82_params;";
  }

  $self->query2($sql, 'do');
  if($self->{errno}) {
    print "Error: INSERT INTO internet_online  !!!!!!!!!!\n ";
  }

  return $self;
}

#**********************************************************
=head2 dhcp_rad_reply($RAD_REQUEST, $NAS, $user_auth_params)

  Arguments:
    $RAD_REQUEST
    $NAS
    $user_auth_params

  Returns:
    result_id, \%RAD_REPLY

=cut
#**********************************************************
sub dhcp_rad_reply {
  my $self = shift;
  my ($RAD_REQUEST, $NAS, $user_auth_params) = @_;

  $RAD_REPLY{'DHCP-Your-IP-Address'}       = $self->{IP} if ($self->{IP} && $self->{IP} ne '0.0.0.0');
  $RAD_REPLY{'DHCP-Subnet-Mask'}           = $self->{NETMASK} || '255.255.255.255' if (!$RAD_REPLY{'DHCP-Subnet-Mask'});
  $RAD_REPLY{'DHCP-IP-Address-Lease-Time'} = $NAS->{NAS_ALIVE} if (! $RAD_REPLY{'DHCP-IP-Address-Lease-Time'});

  $self->{INFO} .= ' '.$user_auth_params->{REQUEST_TYPE};

    #  if(defined($RAD_REPLY{'PORT_SPEED:0'})) {
  #    `echo "$RAD_REPLY{'PORT_SPEED:0'} $RAD_REPLY{'User-Name'}" >> /tmp/bad`;
  #    delete $RAD_REPLY{'PORT_SPEED:0'};
  #  }
  if (! $RAD_REPLY{'DHCP-Your-IP-Address'} ) {
    $RAD_REPLY{'Reply-Message'} = "Not defined nas ip pools or user ip ". ($user_auth_params->{VLAN} || q{});
    return 1, \%RAD_REPLY;
  }

  #1 step. ASK DHCP for address
  $user_auth_params->{IP}           = $RAD_REPLY{'DHCP-Your-IP-Address'};
  if ($user_auth_params->{REQUEST_TYPE} eq 'DHCP-Discover') {
    $user_auth_params->{LEASES_TIME} = $RAD_REPLY{'DHCP-IP-Address-Lease-Time'};
    #$self->leases_add($user_auth_params, $NAS);
    # Writing lease to internet_online and dhcp_leases
    $user_auth_params->{MESSAGE}.=(($self->{RESERVED_IP}) ? ' reserved ip' : ''). " M: ". (($self->{GUEST_MODE}) ? 'GUEST' : '') . " GL: ". (($self->{GUEST_LEASES}) ? 'yes' : 1 );
    $self->mk_rad_log($user_auth_params);
    #Skip
    if (! $self->{GUEST_MODE}) {
      #Get NAS Rad Pairs
      #$self->get_rad_pairs(\%RAD_REPLY, $NAS);
      rad_pairs_former($NAS->{NAS_RAD_PAIRS}, { RAD_PAIRS => \%RAD_REPLY });
    }

    if (! $conf->{DHCPHOSTS_ISG}) {
      $self->calls_update({
        %$user_auth_params,
        SESSION_ID => $RAD_REQUEST->{'DHCP-Transaction-Id'},
      }, $NAS);
    }

    if($conf->{DHCP_FREERADIUS_DEBUG} && $conf->{DHCP_FREERADIUS_DEBUG} > 1) {
      my $mk_log = 1;
      if ($conf->{DHCP_DEBUG_FILTER}) {
        my ($id, $value) = split(/:/, $conf->{DHCP_DEBUG_FILTER}, 2);
        if (($self->{$id} && $self->{$id} eq $value)
          || ($RAD_REQUEST->{$id} && $RAD_REQUEST->{$id} eq $value)) {

        }
        else {
          $mk_log = 0
        }
      }

      if($mk_log) {
        my $out = "== $self->{IP} ($user_auth_params->{REQUEST_TYPE})\n";
        while(my ($k, $v) = each %RAD_REPLY) {
          $out .= "$self->{IP} $k, $v\n";
        }
        if (open( my $fh, '>>', '/tmp/rad_reply' )) {
          print $fh $out;
          close( $fh );
        }
      }
    }
  }
  # 2 step.
  elsif ($user_auth_params->{REQUEST_TYPE} eq "DHCP-Request") {
    $user_auth_params->{MESSAGE}= " REQ IP: $user_auth_params->{REQUIRE_USER_IP}";

    # if negative flag
    if ($self->{GUEST_LEASES}) {
      $user_auth_params->{MESSAGE} .= ' GUEST';
    }

    if ($user_auth_params->{REQUIRE_USER_IP} && $user_auth_params->{REQUIRE_USER_IP} ne $self->{IP}) {
      $self->mk_rad_log($user_auth_params);
      return 6, \%RAD_REPLY;
    }

    $self->mk_rad_log($user_auth_params);
  }

  return 2, \%RAD_REPLY;
}

#**********************************************************
=head2 mk_rad_log($attr) Make log

=cut
#**********************************************************
sub mk_rad_log {
  my $self = shift;
  my ($attr) = @_;

  return 0 if (! $conf->{DHCP_FREERADIUS_DEBUG});

  my $DATE = POSIX::strftime( "%Y-%m-%d", localtime(time));
  my $TIME = POSIX::strftime( "%H:%M:%S", localtime(time));

  my $message = (($attr->{REQUEST_TYPE}) ? "$attr->{REQUEST_TYPE} " : '').
    (( $attr->{LOGIN}) ? "$attr->{LOGIN} " : 'unknown ' ).
    "MAC: $attr->{USER_MAC} ".
    "PORT: $attr->{PORT} ".
    "VLAN: ". (($attr->{VLAN}) ? $attr->{VLAN} : '') .
    "IP: ". (($attr->{IP})? $attr->{IP} : '-') .'/'. (($self->{IP}) ? $self->{IP}: '-');

  if ($attr->{MESSAGE}) {
    $message .= " $attr->{MESSAGE}";
  }

  if (open(my $fh, '>>', '/tmp/rad_dhcp')) {
    print $fh "$DATE $TIME $message";
    close ($fh)
  }

  return 0;
}

#**********************************************************
=head2 accounting($RAD, $NAS) Accounting section

=cut
#**********************************************************
sub accounting {
  my $self = shift;
  #my ($RAD, $NAS) = @_;

  # #my $RAD_REQUEST;
  # #if ($attr->{RAD_REQUEST}) {
  # #  $RAD_REQUEST = $attr->{RAD_REQUEST};
  # #}
  # $self->{SUM} = 0 if (!$self->{SUM});
  # my $acct_status_type = $ACCT_TYPES{ $RAD->{'Acct-Status-Type'} };
  # my $acct_session_id  = $RAD->{'Acct-Session-Id'};
  # $RAD->{'Acct-Input-Gigawords'}  = 0 if (! $RAD->{'Acct-Input-Gigawords'});
  # $RAD->{'Acct-Output-Gigawords'} = 0 if (! $RAD->{'Acct-Output-Gigawords'});
  #
  # if($RAD->{'ERX-Service-Session'}) {
  #   if($acct_session_id =~ /(\d+):/) {
  #     $acct_session_id = $1;
  #   }
  #
  #   #my $ss = `echo "$RAD->{'ERX-Service-Session'}  ses: $RAD->{'Acct-Session-Id'}  $RAD->{INBYTE}  $RAD->{OUTBYTE} EX:  $RAD->{INBYTE2};  $RAD->{OUTBYTE2}" >> /tmp/mx.accc`;
  #   #    $RAD->{INBYTE}=0;
  #   #    $RAD->{OUTBYTE}=0;
  #   #    $RAD->{INBYTE2}= 0;
  #   #    $RAD->{OUTBYTE2}=0;
  #   return $self;
  # }
  #
  # if (length($acct_session_id) > 25) {
  #   $acct_session_id = substr($acct_session_id, 0, 24);
  # }
  #
  # #Start
  # if ($acct_status_type == 1) {
  #   $self->query2("UPDATE internet_online SET
  #    status=1,
  #    started=NOW() - INTERVAL ? SECOND,
  #    lupdated=UNIX_TIMESTAMP(),
  #    acct_session_id=?,
  #    framed_ip_address=INET_ATON( ? )
  #   WHERE
  #     nas_id= ?
  #     AND cid= ?
  #     AND connect_info=?
  #     AND status>3 LIMIT 1;",
  #     'do',
  #     { Bind => [
  #       $RAD->{'Acct-Session-Time'} || 0,
  #       $acct_session_id,
  #       $RAD->{'Framed-IP-Address'} || $RAD->{'Assigned-IP-Address'} || '0.0.0.0',
  #       $NAS->{NAS_ID},
  #       $RAD->{'ERX-Dhcp-Mac-Addr'},
  #       $RAD->{'NAS-Port-Id'}
  #     ]});
  # }
  #
  # # Stop status
  # elsif ($acct_status_type == 2) {
  #   #my $Billing = Billing->new($self->{db}, $conf);
  #   $conf->{rt_billing}=1;
  #   if ($conf->{rt_billing}) {
  #     $self->rt_billing($RAD, $NAS);
  #
  #     if (!$self->{errno}) {
  #       $self->query2("INSERT INTO internet_log SET
  #         uid= ? ,
  #         start=NOW() - INTERVAL ? SECOND,
  #         tp_id= ? ,
  #         duration= ? ,
  #         sent= ? ,
  #         recv= ? ,
  #         sum= ? ,
  #         nas_id= ? ,
  #         port_id= ? ,
  #         ip=INET_ATON( ? ),
  #         cid= ? ,
  #         sent2= ? ,
  #         recv2= ? ,
  #         acct_session_id= ? ,
  #         bill_id= ? ,
  #         terminate_cause= ? ,
  #         acct_input_gigawords= ? ,
  #         acct_output_gigawords= ? ",
  #         'do',
  #         { Bind => [ $self->{UID},
  #           $RAD->{'Acct-Session-Time'},
  #           $self->{TARIF_PLAN} || $self->{TP_ID},
  #           $RAD->{'Acct-Session-Time'},
  #           $RAD->{OUTBYTE},
  #           $RAD->{INBYTE},
  #           $self->{CALLS_SUM}+$self->{SUM},
  #           $NAS->{NAS_ID},
  #           $RAD->{'NAS-Port'},
  #           $RAD->{'Framed-IP-Address'},
  #           $RAD->{'ERX-Dhcp-Mac-Addr'} || $RAD->{'Calling-Station-Id'} || '',
  #           $RAD->{OUTBYTE2},
  #           $RAD->{INBYTE2},
  #           $acct_session_id,
  #           $self->{BILL_ID},
  #           $RAD->{'Acct-Terminate-Cause'},
  #           $RAD->{'Acct-Input-Gigawords'},
  #           $RAD->{'Acct-Output-Gigawords'}
  #         ] }
  #       );
  #     }
  #     else {
  #       #DEbug only
  #       if ($conf->{ACCT_DEBUG}) {
  #         use POSIX qw(strftime);
  #         my $DATE_TIME = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time));
  #         `echo "$DATE_TIME $self->{UID} - $RAD->{'User-Name'} / $acct_session_id / Time: $RAD->{'Acct-Session-Time'} / $self->{errstr}" >> /tmp/unknown_session.log`;
  #         #DEbug only end
  #       }
  #     }
  #   }
  #
  #   # Delete from session
  #   $self->query2("DELETE FROM internet_online WHERE
  #     (acct_session_id= ? OR (connect_info= ? AND status=11))
  #     AND nas_id= ? ;", 'do', {
  #     Bind =>  [
  #       $acct_session_id,
  #       $RAD->{'NAS-Port-Id'},
  #       $NAS->{NAS_ID}
  #     ] });
  # }
  #
  # #Alive status 3
  # elsif ($acct_status_type eq 3) {
  #   $self->{SUM} = 0 if (!$self->{SUM});
  #
  #   if($RAD->{'ERX-Service-Session'}) {
  #     $self->query2("UPDATE internet_online SET
  #     ex_input_octets=$RAD->{INBYTE},
  #     ex_output_octets=$RAD->{OUTBYTE},
  #     ex_input_octets_gigawords='". $RAD->{'Acct-Input-Gigawords'} ."',
  #     ex_output_octets_gigawords='". $RAD->{'Acct-Output-Gigawords'} ."',
  #     status='$acct_status_type'
  #   WHERE
  #     acct_session_id='" . $acct_session_id . "'
  #     AND nas_id='$NAS->{NAS_ID}' LIMIT 1;", 'do'
  #     );
  #
  #     return $self;
  #   }
  #   elsif ($NAS->{NAS_EXT_ACCT}) {
  #     my $ipn_fields = '';
  #     if ($NAS->{IPN_COLLECTOR}) {
  #       $ipn_fields = "
  #     sum=sum+$self->{SUM},
  #     acct_input_octets='$RAD->{INBYTE}',
  #     acct_output_octets='$RAD->{OUTBYTE}',
  #     ex_input_octets=ex_input_octets + $RAD->{INBYTE2},
  #     ex_output_octets=ex_output_octets + $RAD->{OUTBYTE2},
  #     acct_input_gigawords='". $RAD->{'Acct-Input-Gigawords'} ."',
  #     acct_output_gigawords='". $RAD->{'Acct-Output-Gigawords'} ."',";
  #     }
  #
  #     $self->query2("UPDATE internet_online SET
  #     $ipn_fields
  #     status='$acct_status_type',
  #     acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
  #     lupdated=UNIX_TIMESTAMP()
  #   WHERE
  #     acct_session_id='" . $acct_session_id . "'
  #     AND nas_id='$NAS->{NAS_ID}' LIMIT 1;", 'do'
  #     );
  #     return $self;
  #   }
  #
  #   $self->rt_billing($RAD, $NAS);
  #
  #   # Can't find online records
  #   if ($self->{errno} && $self->{errno}  == 2) {
  #     if (!$RAD->{'Framed-Protocol'} || $RAD->{'Framed-Protocol'} ne 'PPP') {
  #       $self->auth($RAD, $NAS, { GET_USER => 1 });
  #       $RAD->{'User-Name'}= $self->{LOGIN} || $self->{USER_NAME} || $RAD->{'ERX-Dhcp-Mac-Addr'};
  #     }
  #     else {
  #       $self->query2("SELECT u.uid, internet.tp_id, internet.id AS service_id
  #         FROM users u
  #         INNER JOIN internet_main internet ON (u.uid=internet.uid)
  #         WHERE u.id= ? ;",
  #         undef,
  #         { INFO  => 1, Bind => [ $RAD->{'User-Name'} ] });
  #     }
  #
  #     #Lost session debug
  #     my $debug = 0;
  #     if($debug) {
  #       my $info_rr = '';
  #       if(! $self->{UID}) {
  #         foreach my $k(sort keys %$RAD) {
  #           my $v = $RAD->{$k};
  #           $info_rr .= "$k, $v\n";
  #         }
  #       }
  #       `echo "Lost session USER_NAME: $RAD->{'User-Name'} UID: $self->{UID} TIME: $RAD->{'Acct-Session-Time'}\n$info_rr" >> /tmp/lost_session`;
  #       #=== Lost session debug
  #     }
  #
  #     $self->query2("REPLACE INTO internet_online SET
  #           status= ? ,
  #           user_name= ? ,
  #           started=NOW() - INTERVAL ? SECOND,
  #           lupdated=UNIX_TIMESTAMP(),
  #           nas_ip_address=INET_ATON( ? ),
  #           nas_port_id= ? ,
  #           acct_session_id= ? ,
  #           framed_ip_address=INET_ATON( ? ),
  #           cid= ? ,
  #           connect_info= ? ,
  #           acct_input_octets= ? ,
  #           acct_output_octets= ? ,
  #           acct_input_gigawords= ? ,
  #           acct_output_gigawords= ? ,
  #           nas_id= ? ,
  #           tp_id= ? ,
  #           uid= ? ,
  #           guest = ?,
  #           acct_session_time = ?,
  #           service_id = ? ;",
  #       'do',
  #       { Bind => [
  #         '9',
  #         $RAD->{'User-Name'} || '',
  #         $RAD->{'Acct-Session-Time'} || 0,
  #         $RAD->{'NAS-IP-Address'},
  #         $RAD->{'NAS-Port'} || 0,
  #         $acct_session_id,
  #         $RAD->{'Framed-IP-Address'} || '0.0.0.0',
  #         $RAD->{'ERX-Dhcp-Mac-Addr'} || $RAD->{'Calling-Station-Id'} || '',
  #         $RAD->{'NAS-Port-Id'} || $RAD->{'Connect-Info'},
  #         $RAD->{'INBYTE'},
  #         $RAD->{'OUTBYTE'},
  #         $RAD->{'Acct-Input-Gigawords'},
  #         $RAD->{'Acct-Output-Gigawords'},
  #         $NAS->{NAS_ID},
  #         $self->{TP_ID} || 0,
  #         $self->{UID} || 0,
  #         ($self->{UID}) ? 0 : 1,
  #         $RAD->{'Acct-Session-Time'} || 0,
  #         $self->{SERVICE_ID} || 0
  #       ]});
  #     return $self;
  #   }
  #   else {
  #     my $ex_octets = '';
  #     if ($RAD->{INBYTE2} || $RAD->{OUTBYTE2}) {
  #       $ex_octets = "ex_input_octets='$RAD->{INBYTE2}',  ex_output_octets='$RAD->{OUTBYTE2}', ";
  #     }
  #
  #     $self->query2("UPDATE internet_online SET
  #     status=?,
  #     acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
  #     acct_input_octets=?,
  #     acct_output_octets=?,
  #     $ex_octets
  #     lupdated=UNIX_TIMESTAMP(),
  #     sum=sum + ?,
  #     framed_ip_address=INET_ATON( ? ),
  #     acct_input_gigawords= ?,
  #     acct_output_gigawords= ?
  #    WHERE
  #     acct_session_id=?
  #     AND nas_id= ?
  #    LIMIT 1;",
  #       'do',
  #       { Bind => [
  #         $acct_status_type,
  #         $RAD->{INBYTE},
  #         $RAD->{OUTBYTE},
  #         $self->{SUM},
  #         $RAD->{'Framed-IP-Address'} || $RAD->{'Assigned-IP-Address'},
  #         $RAD->{'Acct-Input-Gigawords'},
  #         $RAD->{'Acct-Output-Gigawords'},
  #         $acct_session_id,
  #         $NAS->{NAS_ID}
  #       ] });
  #   }
  # }
  # else {
  #   $self->{errno}  = 1;
  #   $self->{errstr} = "ACCT [".$RAD->{'User-Name'}."] Unknown accounting status: "> $RAD->{'Acct-Status-Type'} ." (". $acct_session_id .")";
  # }
  #
  # if ($self->{errno}) {
  #   $self->{errno}  = 1;
  #   $self->{errstr} = "ACCT ". $RAD->{'Acct-Status-Type'} ." SQL Error";
  #   return $self;
  # }
  #
  # #detalization for Exppp
  # if ($conf->{s_detalization} && $self->{UID}) {
  #   $self->query2("INSERT INTO s_detail (acct_session_id, nas_id, acct_status, last_update, sent1, recv1, sent2, recv2, id, uid, sum)
  #      VALUES ( ? , ?, ? , UNIX_TIMESTAMP(), ? , ? , ? , ? , ? , ?, ?);",
  #     'do',
  #     { Bind => [
  #       $acct_session_id,
  #       $NAS->{NAS_ID},
  #       $acct_status_type,
  #       $RAD->{INBYTE} +  (($RAD->{'Acct-Input-Gigawords'})  ? $RAD->{'Acct-Input-Gigawords'} * 4294967296  : 0),
  #       $RAD->{OUTBYTE} + (($RAD->{'Acct-Output-Gigawords'}) ? $RAD->{'Acct-Output-Gigawords'} * 4294967296 : 0),
  #       $RAD->{INBYTE2}  || 0,
  #       $RAD->{OUTBYTE2} || 0,
  #       $RAD->{'User-Name'} || q{},
  #       $self->{UID} || 0,
  #       $self->{SUM}
  #     ]}
  #   );
  # }

  return $self;
}


1;

#=comments
#
#Dhcp messages
#Following are the important messages exchanged between a Dynamic Host Configuration Protocol (DHCP) client and a DHCP Server.
#DHCPDiscover Message
#
#DHCP client sends a DHCP Discover broadcast on the network for finding a DHCP server. If there is no respond from a DHCP server, the client assigns itself an automatic private IP address (APIPA).
#DHCPOffer Message
#
#DHCP servers on a network that receive a DHCP Discover message respond with a DHCP Offer message, which offers the client an IP address lease.
#DHCPRequest Message
#
#Clients accept the first offer received by broadcasting a DHCP Request message for the offered IP address.
#DHCPAcknowledgment Message
#
#The server accepts the request by sending the client a DHCP Acknowledgment message.
#DHCPNak Message
#
#If the IP address requested by the DHCP client cannot be used (another device may be using this IP address), the DHCP server responds with a DHCPNak (Negative Acknowledgment) packet. After this, the client must begin the DHCP lease process again.
#DHCPDecline Message
#
#If the DHCP client determines the offered TCP/IP configuration parameters are invalid, it sends a DHCPDecline packet to the server. After this, the client must begin the DHCP lease process again.
#DHCPRelease Message
#
#A DHCP client sends a DHCPRelease packet to the server to release the IP address and cancel any remaining lease.
#DHCPInform Message
#
#DHCPInform is a new DHCP message type, defined in RFC 2131. DHCPInform is used by DHCP clients to obtain DHCP options.
#
#
#eXTReMe Tracker
#
#
#
#Frame 5 (347 bytes on wire, 347 bytes captured)
#Ethernet II, Src: Cisco_94:1d:44 (00:0e:38:94:1d:44), Dst: IntelCor_9d:cf:3e (00:15:17:9d:cf:3e)
#Internet Protocol, Src: 193.107.112.129 (193.107.112.129), Dst: 10.1.0.2 (10.1.0.2)
#User Datagram Protocol, Src Port: bootps (67), Dst Port: bootps (67)
#Bootstrap Protocol
#    Message type: Boot Request (1)
#    Hardware type: Ethernet
#    Hardware address length: 6
#    Hops: 1
#    Transaction ID: 0x832675c7
#    Seconds elapsed: 0
#    Bootp flags: 0x8000 (Broadcast)
#    Client IP address: 0.0.0.0 (0.0.0.0)
#    Your (client) IP address: 0.0.0.0 (0.0.0.0)
#    Next server IP address: 0.0.0.0 (0.0.0.0)
#    Relay agent IP address: 193.107.112.129 (193.107.112.129)
#    Client MAC address: Internet_98:4f:5e (00:e0:4d:98:4f:5e)
#    Client hardware address padding: 00000000000000000000
#    Server host name not given
#    Boot file name not given
#    Magic cookie: (OK)
#    Option: (t=53,l=1) DHCP Message Type = DHCP Discover
#    Option: (t=61,l=7) Client identifier
#    Option: (t=12,l=6) Host Name = "\216\253\357-\217\212"
#    Option: (t=60,l=8) Vendor class identifier = "MSFT 5.0"
#    Option: (t=55,l=12) Parameter Request List
#    Option: (t=82,l=18) Agent Information Option
#    End Option
#
#No.     Time        Source                Destination           Protocol Info
#      6 9.462149    10.1.0.2              193.107.112.129       DHCP     DHCP Offer    - Transaction ID 0x832675c7
#
#Frame 6 (342 bytes on wire, 342 bytes captured)
#Ethernet II, Src: IntelCor_9d:cf:3e (00:15:17:9d:cf:3e), Dst: Cisco_94:1d:44 (00:0e:38:94:1d:44)
#Internet Protocol, Src: 10.1.0.2 (10.1.0.2), Dst: 193.107.112.129 (193.107.112.129)
#User Datagram Protocol, Src Port: bootps (67), Dst Port: bootps (67)
#Bootstrap Protocol
#    Message type: Boot Reply (2)
#    Hardware type: Ethernet
#    Hardware address length: 6
#    Hops: 1
#    Transaction ID: 0x832675c7
#    Seconds elapsed: 0
#    Bootp flags: 0x8000 (Broadcast)
#    Client IP address: 0.0.0.0 (0.0.0.0)
#    Your (client) IP address: 193.107.112.132 (193.107.112.132)
#    Next server IP address: 0.0.0.0 (0.0.0.0)
#    Relay agent IP address: 193.107.112.129 (193.107.112.129)
#    Client MAC address: Internet_98:4f:5e (00:e0:4d:98:4f:5e)
#    Client hardware address padding: 00000000000000000000
#    Server host name not given
#    Boot file name not given
#    Magic cookie: (OK)
#    Option: (t=53,l=1) DHCP Message Type = DHCP Offer
#    Option: (t=54,l=4) DHCP Server Identifier = 10.1.0.2
#    Option: (t=51,l=4) IP Address Lease Time = 10 minutes
#    Option: (t=1,l=4) Subnet Mask = 255.255.255.128
#    Option: (t=82,l=18) Agent Information Option
#    End Option
#    Padding
#
#No.     Time        Source                Destination           Protocol Info
#      7 9.470146    193.107.112.129       10.1.0.2              DHCP     DHCP Request  - Transaction ID 0x832675c7
#
#Frame 7 (370 bytes on wire, 370 bytes captured)
#Ethernet II, Src: Cisco_94:1d:44 (00:0e:38:94:1d:44), Dst: IntelCor_9d:cf:3e (00:15:17:9d:cf:3e)
#Internet Protocol, Src: 193.107.112.129 (193.107.112.129), Dst: 10.1.0.2 (10.1.0.2)
#User Datagram Protocol, Src Port: bootps (67), Dst Port: bootps (67)
#Bootstrap Protocol
#    Message type: Boot Request (1)
#    Hardware type: Ethernet
#    Hardware address length: 6
#    Hops: 1
#    Transaction ID: 0x832675c7
#    Seconds elapsed: 0
#    Bootp flags: 0x8000 (Broadcast)
#    Client IP address: 0.0.0.0 (0.0.0.0)
#    Your (client) IP address: 0.0.0.0 (0.0.0.0)
#    Next server IP address: 0.0.0.0 (0.0.0.0)
#    Relay agent IP address: 193.107.112.129 (193.107.112.129)
#    Client MAC address: Internet_98:4f:5e (00:e0:4d:98:4f:5e)
#    Client hardware address padding: 00000000000000000000
#    Server host name not given
#    Boot file name not given
#    Magic cookie: (OK)
#    Option: (t=53,l=1) DHCP Message Type = DHCP Request
#    Option: (t=61,l=7) Client identifier
#    Option: (t=50,l=4) Requested IP Address = 193.107.112.132
#    Option: (t=54,l=4) DHCP Server Identifier = 10.1.0.2
#    Option: (t=12,l=6) Host Name = "\216\253\357-\217\212"
#    Option: (t=81,l=9) Client Fully Qualified Domain Name
#    Option: (t=60,l=8) Vendor class identifier = "MSFT 5.0"
#    Option: (t=55,l=12) Parameter Request List
#    Option: (t=82,l=18) Agent Information Option
#    End Option
#
#No.     Time        Source                Destination           Protocol Info
#      8 9.470150    10.1.0.2              193.107.112.129       DHCP     DHCP ACK      - Transaction ID 0x832675c7
#
#Frame 8 (342 bytes on wire, 342 bytes captured)
#Ethernet II, Src: IntelCor_9d:cf:3e (00:15:17:9d:cf:3e), Dst: Cisco_94:1d:44 (00:0e:38:94:1d:44)
#Internet Protocol, Src: 10.1.0.2 (10.1.0.2), Dst: 193.107.112.129 (193.107.112.129)
#User Datagram Protocol, Src Port: bootps (67), Dst Port: bootps (67)
#Bootstrap Protocol
#    Message type: Boot Reply (2)
#    Hardware type: Ethernet
#    Hardware address length: 6
#    Hops: 1
#    Transaction ID: 0x832675c7
#    Seconds elapsed: 0
#    Bootp flags: 0x8000 (Broadcast)
#    Client IP address: 0.0.0.0 (0.0.0.0)
#    Your (client) IP address: 193.107.112.132 (193.107.112.132)
#    Next server IP address: 0.0.0.0 (0.0.0.0)
#    Relay agent IP address: 193.107.112.129 (193.107.112.129)
#    Client MAC address: Internet_98:4f:5e (00:e0:4d:98:4f:5e)
#    Client hardware address padding: 00000000000000000000
#    Server host name not given
#    Boot file name not given
#    Magic cookie: (OK)
#    Option: (t=53,l=1) DHCP Message Type = DHCP ACK
#    Option: (t=54,l=4) DHCP Server Identifier = 10.1.0.2
#    Option: (t=51,l=4) IP Address Lease Time = 10 minutes
#    Option: (t=1,l=4) Subnet Mask = 255.255.255.128
#    Option: (t=82,l=18) Agent Information Option
#    End Option
#    Padding
#
#=cut


