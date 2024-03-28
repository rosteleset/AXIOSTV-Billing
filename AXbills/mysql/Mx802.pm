package Mx802 v1.8.15;

=head1 NAME

   Juniper MX80 (mx80)
     PPPoE
     IPoE MAC auth
     IPoE switch port + switch mac auth

=head1 OPRIONS

MX80_NAT_PROFILE - Enable nat profile for privat networks

=head1 VERSION

  VERSION: 1.8.15
  REVISION: 20201214

=cut

use strict;
use Billing;
use AXbills::Base qw(in_array);
use base qw(main Auth2);

my %ACCT_TYPES = (
  'Start'          => 1,
  'Stop'           => 2,
  'Alive'          => 3,
  'Interim-Update' => 3,
  'Accounting-On'  => 7,
  'Accounting-Off' => 8
);


my %ACCT_TERMINATE_CAUSES = (
  'User-Request'             => 1,
  'Lost-Carrier'             => 2,
  'Lost-Service'             => 3,
  'Idle-Timeout'             => 4,
  'Session-Timeout'          => 5,
  'Admin-Reset'              => 6,
  'Admin-Reboot'             => 7,
  'Port-Error'               => 8,
  'NAS-Error'                => 9,
  'NAS-Request'              => 10,
  'NAS-Reboot'               => 11,
  'Port-Unneeded'            => 12,
  'Port-Preempted'           => 13,
  'Port-Suspended'           => 14,
  'Service-Unavailable'      => 15,
  'Callback'                 => 16,
  'User-Error'               => 17,
  'Host-Request'             => 18,
  'Supplicant-Restart'       => 19,
  'Reauthentication-Failure' => 20,
  'Port-Reinit'              => 21,
  'Port-Disabled'            => 22,
  'Lost-Alive'               => 23,
);

my ($CONF, $Billing);

my %_RAD_REPLY         = ();
my %GUEST_POOLS        = ();
my %profiles           = ();
my $profile_prefix     = 'svc';
my $default_guest_pool = 0;

#++********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($CONF) = @_;

  my $self = {};
  bless($self, $class);
  $self->{db}=$db;
  $self->{conf}=$CONF;

  $Billing = Billing->new($self->{db}, {});

  if ($CONF->{MX80_PROFILES}) {
    $CONF->{MX80_DEFAULT_GUEST_PROFILE} = 'NOAUTH' if (!$CONF->{MX80_DEFAULT_GUEST_PROFILE});
    $CONF->{MX80_PROFILES}=~s/[\r\n]//g;
    foreach my $l (split(/;/, $CONF->{MX80_PROFILES})) {
      my($v, $k)=split(/:/, $l);
      $profiles{$v}=$k;
    }
  }

  if ($CONF->{MX80_GUEST_POOLS_PARAMS}) {
    $CONF->{MX80_GUEST_POOLS_PARAMS} =~ s/[\r\n]+//g;
    my @guest_nets_arr = split(/;/, $CONF->{MX80_GUEST_POOLS_PARAMS});
    foreach my $line (@guest_nets_arr) {
      my ($pool_id, $rad_reply) = split(/:/, $line);

      if (! $default_guest_pool) {
        $default_guest_pool = $pool_id;
      }

      if ($rad_reply && $rad_reply ne '') {
        my @arr = split(/,/, $rad_reply);
        foreach my $param (@arr) {
          my ($k, $v) = split(/=/, $param, 2);
          $GUEST_POOLS{$pool_id}{RAD_REPLY}{$k} = $v;
        }
      }
    }
  }

  if($CONF->{MX80_PROFILE_PREFIX}) {
    $profile_prefix=$CONF->{MX80_PROFILE_PREFIX}.'--GUEST';
  }

  return $self;
}

#**********************************************************
=head2 pre_auth($self, $RAD, $attr)

=cut
#**********************************************************
sub pre_auth {
  my ($self) = @_;

  $self->{'RAD_CHECK'}{'Auth-Type'} = "Accept";
  return 0;
}

#**********************************************************
=head2 user_info($RAD_REQUEST, $attr) - get user info

  Arguments: 
   $RAD_REQUEST, 
   $attr

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($RAD_REQUEST, $attr) = @_;

  my $WHERE;
  my @binding_vals = ();

  if($attr->{SERVICE_ID}) {
    $WHERE = " AND internet.id='$attr->{SERVICE_ID}'";
  }
  elsif ($attr->{UID}) {
    $WHERE = " AND internet.uid='$attr->{UID}'";
  }
  elsif ($CONF->{MX80_AUTH_PORT_ID}) {
    $WHERE = " AND u.id= ? ";
    push @binding_vals, $RAD_REQUEST->{'User-Name'} ;
  }
  elsif ($RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    $WHERE = " AND internet.cid= ? ";
    push @binding_vals, $RAD_REQUEST->{'User-Name'} ;
  }
  else {
    $WHERE = " AND u.id= ? ";
    push @binding_vals, $RAD_REQUEST->{'User-Name'} ;
  }

  my $ipv6 = q{};
  if($CONF->{IPV6}) {
    $ipv6 = ", INET6_NTOA(internet.ipv6) AS ipv6, INET6_NTOA(internet.ipv6_prefix) AS ipv6_prefix,
    internet.ipv6_mask, internet.ipv6_prefix_mask";
  }

  $self->query2("SELECT
   u.id AS user_name,
   internet.tp_id,
   IF (internet.logins=0, IF(tp.logins IS NULL, 0, tp.logins), internet.logins) AS simultaneously,
   internet.speed,
   internet.disable AS internet_disable,
   u.disable AS user_disable,
   u.reduction AS discount,
   u.bill_id,
   u.company_id,
   u.credit,
   u.activate AS account_activate,
  UNIX_TIMESTAMP() AS session_start,
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_week,
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year,

  IF(internet.filter_id != '', internet.filter_id, IF(tp.filter_id IS NULL, '', tp.filter_id)) AS filter,
  tp.payment_type,
  tp.neg_deposit_filter_id,
  tp.credit AS tp_credit,
  tp.credit_tresshold,
  DECODE(u.password, '$CONF->{secretkey}') AS password,
  internet.cid,
  tp.neg_deposit_ippool,
  tp.ippool AS tp_ippool,
  tp.rad_pairs AS tp_rad_pairs,
  internet.port,
  tp.age AS account_age,
  internet.expire AS internet_expire,
  tp_int.id AS interval_id,
  internet.uid,
  IF(internet.ip>0, INET_NTOA(internet.ip), 0) AS ip,
  internet.id AS service_id
  $ipv6
   FROM internet_main internet
   INNER JOIN users u ON (u.uid=internet.uid)
   LEFT JOIN tarif_plans tp ON (internet.tp_id=tp.tp_id)
   LEFT JOIN intervals tp_int ON (tp_int.tp_id=tp.tp_id)
   WHERE (internet.expire='0000-00-00' OR internet.expire > CURDATE())
   $WHERE
   GROUP BY u.id;",
    undef,
    { INFO => 1,
      Bind => \@binding_vals }
  );

  if ($self->{errno}) {
    return $self;
  }

  #DIsable
  if (($self->{INTERNET_DISABLE} && $self->{INTERNET_DISABLE} != 5) || $self->{USER_DISABLE}) {
    $_RAD_REPLY{'Reply-Message'} = "ACCOUNT_DISABLE: $self->{USER_DISABLE}/$self->{INTERNET_DISABLE}";
    $self->{errno}              = 6;
    $self->{errstr}             = $_RAD_REPLY{'Reply-Message'};
    return 6, \%_RAD_REPLY;
  }

  if (! $RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    if ($RAD_REQUEST->{'CHAP-Password'} && $RAD_REQUEST->{'CHAP-Challenge'}) {
      if (Auth2::check_chap($RAD_REQUEST->{'CHAP-Password'}, $self->{PASSWORD}, $RAD_REQUEST->{'CHAP-Challenge'}, 0) == 0) {
        $_RAD_REPLY{'Reply-Message'} = "WRONG_CHAP_PASSWORD:";
        $self->{errno}              = 1;
        $self->{errstr}             = $_RAD_REPLY{'Reply-Message'};
        return 1, \%_RAD_REPLY;
      }
    }
    #If don't athorize any above methods auth PAP password
    else {
      if (defined($RAD_REQUEST->{'User-Password'}) && $self->{PASSWORD} ne $RAD_REQUEST->{'User-Password'}) {
        $_RAD_REPLY{'Reply-Message'} = "WRONG_PASSWORD: '" . $RAD_REQUEST->{'User-Password'} . "'";
        $self->{errno}              = 1;
        $self->{errstr}             = $_RAD_REPLY{'Reply-Message'};
        return 1, \%_RAD_REPLY;
      }
    }

    my $pppoe_pluse = '';
    my $ignore_cid  = 0;
    if($CONF->{INTERNET_PPPOE_PLUSE_PARAM}) {
      if ($RAD_REQUEST->{$CONF->{INTERNET_PPPOE_PLUSE_PARAM}}) {
        $pppoe_pluse = $RAD_REQUEST->{$CONF->{INTERNET_PPPOE_PLUSE_PARAM}};
        if ($self->{PORT} && $self->{PORT} !~ /any/i) {
          $ignore_cid = 1;
        }
        elsif (!$self->{PORT}) {
          $self->query2(
            "UPDATE internet_main SET port='$RAD_REQUEST->{$CONF->{INTERNET_PPPOE_PLUSE_PARAM}}' WHERE uid='$self->{UID}';"
            , 'do');
          $self->{PORT} = $RAD_REQUEST->{$CONF->{INTERNET_PPPOE_PLUSE_PARAM}};
        }
      }
      else {
        $pppoe_pluse = $RAD_REQUEST->{'Nas-Port'} || '';
      }

      #Check port
      if ($self->{PORT} && $self->{PORT} !~ m/any/i && $self->{PORT} ne $pppoe_pluse) {
        $_RAD_REPLY{'Reply-Message'} = "1WRONG_PORT '$pppoe_pluse'";
        $self->{errno} = 7;
        $self->{errstr} = $_RAD_REPLY{'Reply-Message'};
        return 7, \%_RAD_REPLY;
      }
    }

    #Check CID (MAC) for pppoe
    if ($self->{CID} && $self->{CID} !~ /ANY/i && ! $ignore_cid) {
      my ($ret, $ERR_RAD_PAIRS) = $self->Auth_CID($RAD_REQUEST);

      %_RAD_REPLY = %{ $ERR_RAD_PAIRS } if ($ERR_RAD_PAIRS);
      if ($ret == 1) {
        $self->{errno}  = 8;
        $self->{errstr} = $_RAD_REPLY{'Reply-Message'};
        return 8, $ERR_RAD_PAIRS ;
      }
    }
  }

  #Chack Company account if ACCOUNT_ID > 0
  $self->check_company_account() if ($self->{COMPANY_ID} > 0);
  $self->check_bill_account();

  if ($self->{errno}) {
    $_RAD_REPLY{'Reply-Message'} = $self->{errstr};
    return 1, \%_RAD_REPLY;
  }

  return 1, \%_RAD_REPLY;
}

#**********************************************************
=head2 check_simultaneously($RAD_REPLY, $NAS, $attr) - Check logins

  Arguments:
    $RAR_REPLY_REF
    $NAS
    $attr
      CALLING_STATION_ID

=cut
#**********************************************************
sub check_simultaneously {
  my $self = shift;
  my ($RAD_REPLY, $NAS, $attr) = @_;

  $self->query2("SELECT cid, INET_NTOA(framed_ip_address) AS ip, nas_id FROM internet_online WHERE user_name='$self->{USER_NAME}' AND (status <> 2 AND status < 11);");
  my $active_logins = $self->{TOTAL} || 0;

  foreach my $line (@{ $self->{list} }) {
    # Zap session with same CID
    if ( $line->[0]
      && $line->[0] eq $attr->{CALLING_STATION_ID}
      && $line->[2] eq $NAS->{NAS_ID})
    {
      $self->query2("UPDATE internet_online SET status=6 WHERE user_name='$self->{USER_NAME}' AND cid='$attr->{CALLING_STATION_ID}' AND (status <> 2 AND status < 11);", 'do');
      $self->{IP} = $line->[1] if(! $self->{IP});
      $self->{ASSIGN_IP}=1;
      $active_logins--;
    }
  }

  if ($active_logins >= $self->{SIMULTANEOUSLY}) {
    $RAD_REPLY->{'Reply-Message'} = "More then allow login ($self->{SIMULTANEOUSLY}/$active_logins)";
    $self->{errno}              = 3;
    $self->{errstr}             = $RAD_REPLY->{'Reply-Message'};
    return 1, $RAD_REPLY;
  }

  return 0, $RAD_REPLY;
}

#**********************************************************
=head2 guest_mode($RAD_REQUEST, $NAS, $message, $attr)

  Arguments:
    $attr
      USER_AUTH_PARAMS
      GUEST_MODE_TYPE

=cut
#**********************************************************
sub guest_mode {
  my $self = shift;
  my ($RAD_REQUEST, $NAS, $message, $attr) = @_;

  my $redirect_profile = ($attr->{GUEST_MODE_TYPE} && $profiles{$attr->{GUEST_MODE_TYPE}}) ? $profiles{$attr->{GUEST_MODE_TYPE}} : $CONF->{MX80_DEFAULT_GUEST_PROFILE};
  $_RAD_REPLY{'Reply-Message'} = $message;
  $self->{INFO} = $message;
  if($self->{NEG_DEPOSIT_FILTER_ID}) {
    $self->Auth2::neg_deposit_filter_former($RAD_REQUEST, $NAS,
      $self->{NEG_DEPOSIT_FILTER_ID},
      { RAD_PAIRS   => \%_RAD_REPLY,
        USER_NAME   => 'neg',
        SKIP_ADD_IP => 1
      });
  }
  elsif (! $redirect_profile )  {
    return 7, \%_RAD_REPLY;
  }

  if(! $CONF->{INTERNET_GUEST_STATIC_IP}) {
    delete $self->{IP};
  }

  if ($redirect_profile) {
    $redirect_profile =~ s/pppoe/ipoe/ if (! $RAD_REQUEST->{'Framed-Protocol'} );
    $_RAD_REPLY{'ERX-Service-Activate:1'} = $redirect_profile if($redirect_profile);
  }

  my $neg_ip_pool = $self->{NEG_DEPOSIT_IPPOOL} || $self->{tp_ippool} || $default_guest_pool || 0;
  if (! $self->{IP} || $self->{IP} eq '0.0.0.0') {
    #$self->{GUEST}=1;
    $self->{USER_NAME} ||= $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} || q{};
    my $ip = $self->Auth2::get_ip($NAS->{NAS_ID},
      $RAD_REQUEST->{'NAS-IP-Address'}, {
      TP_IPPOOL    => $neg_ip_pool,
      CONNECT_INFO => $RAD_REQUEST->{'NAS-Port-Id'} || '',
      CID          => $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'},
      GUEST        => 1,
      SERVER_VLAN  => $attr->{SERVER_VLAN},
      VLAN         => $attr->{VLAN}
      #CONNECT_INFO => '!-'
    });
    #$self->{GUEST}=0;
#    $self->query2("SELECT INET_NTOA(netmask) AS netmask,
#        dns,
#        ntp,
#        INET_NTOA(gateway) AS gateway,
#        id
#      FROM ippools
#      WHERE ip<=INET_ATON('$self->{IP}') AND INET_ATON('$self->{IP}')<=ip+counts
#      ORDER BY netmask
#      LIMIT 1", undef, { INFO => 1 });

    if ($ip eq '-1') {
      $_RAD_REPLY{'Reply-Message'} = $attr->{GUEST_MODE_TYPE}." Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS})";
      return 1, \%_RAD_REPLY;
    }
    elsif ($ip eq '0') {
      #$RAD_PAIRS->{'Reply-Message'}="$self->{errstr} ($NAS->{NAS_ID})";
      #return 1, $RAD_PAIRS;
    }
    else {
      $_RAD_REPLY{'Framed-IP-Address'} = $ip;
    }

    $self->{IP}=$ip;
    #if ($_RAD_REPLY{'Framed-IP-Address'} && ! $_RAD_REPLY{'Framed-IP-Netmask'} && $RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    #  #$_RAD_REPLY{'Framed-IP-Netmask'} = $self->{NETMASK} if ($self->{NETMASK}) ;
    #}
  }
  elsif($self->{IP}) {
    $_RAD_REPLY{'Framed-IP-Address'} = $self->{IP};
    #if(! $self->{ASSIGN_IP}) {
      #Add guest start internet_online_ip
    $self->query2("SELECT uid FROM internet_online WHERE uid='$self->{UID}' AND framed_ip_address=INET_ATON('$self->{IP}') AND guest=1;");
    if(! $self->{TOTAL}) {
      $self->Auth2::online_add({
        %{ ($attr) ? $attr : {} },
        NAS_ID            => $NAS->{NAS_ID},
        FRAMED_IP_ADDRESS => "INET_ATON('$self->{IP}')",
        FRAMED_IPV6_PREFIX=> ($self->{IPV6}) ? "INET6_ATON('". $self->{IPV6} ."')" : undef,
        FRAMED_INTERFACE_ID=>$RAD_REQUEST->{'Framed-Interface-Id'},
        DELEGATED_IPV6_PREFIX => ($self->{IPV6_PREFIX}) ? "INET6_ATON('". $self->{IPV6_PREFIX} ."')" : undef,
        NAS_IP_ADDRESS    => $RAD_REQUEST->{'NAS-IP-Address'},
        CONNECT_INFO      => $RAD_REQUEST->{'NAS-Port-Id'} || '',
        CID               => $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'},
        GUEST             => 1
      });
    }
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

  delete $_RAD_REPLY{'Framed-IP-Netmask'};
  if ($self->{NETMASK} && $RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    $_RAD_REPLY{'Framed-IP-Netmask'} = $self->{NETMASK};
  }

  if ($self->{GATEWAY} && $self->{GATEWAY} ne '0.0.0.0') {
    $_RAD_REPLY{'ERX-Dhcp-Options'} = sprintf("0x0304%.2x%.2x%.2x%.2x", split(/\./, $self->{GATEWAY}));
    $_RAD_REPLY{'Session-Timeout'} = $NAS->{NAS_ALIVE};
    #$RAD_REPLY{'ERX-Dhcp-Gi-Address'}=$self->{ROUTERS};
  }

  if($self->{DNS}) {
    $self->{DNS}=~s/ //g;
    my @dns_arr = split(/,/, $self->{DNS});
    #push @dns_arr, $self->{DNS2} if ($self->{DNS2});
    $_RAD_REPLY{'ERX-Primary-Dns'}=$dns_arr[0] if ($dns_arr[0]);
    $_RAD_REPLY{'ERX-Secondary-Dns'}=$dns_arr[1] if ($dns_arr[1]);
  }

#  my $user_auth_params = $attr->{USER_AUTH_PARAMS};
#  $self->Auth2::leases_add({
#    %$attr,
#    LEASES_TIME => 300,
#    USER_MAC    => $user_auth_params->{USER_MAC} || $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'},
#    UID         => $self->{UID},
#    IP          => $self->{IP},
#    PORT        => $user_auth_params->{PORT} || $RAD_REQUEST->{'NAS-Port-Id'} || '',
#  },
#  $NAS);

  #  Some nat ideas
  #
  #  if ( $RAD_REPLY{'Framed-IP-Address'} ) {
  #    my @nets = (
  #      '10.0.0.0/8',
  #      '172.16.0.0/12',
  #      '192.168.0.0/16',
  #      '100.64.0.0/10'
  #    );
  #    foreach my $ip_range (@nets) {
  #      $ip_range =~ /(.+)\/(\d+)/;
  #      my $IP = unpack( "N", pack( "C4", split( /\./, $1 ) ) );
  #      my $NETMASK =  unpack "N", pack( "B*", ("1" x $2 . "0" x (32 - $2)) );
  #      my $client_ip_num = unpack( "N", pack( "C4", split( /\./, $RAD_REPLY{'Framed-IP-Address'}  ) ) );
  #      if ( ($client_ip_num & $NETMASK) == ($IP & $NETMASK)) {
  #        $RAD_REPLY{'ERX-Service-Activate:2'} = 'svc-cgn-nat';
  #      }
  #    }
  #  }


  #if(! $self->{UID} && $GUEST_POOLS{$neg_ip_pool}) {
  if($GUEST_POOLS{$neg_ip_pool}) {
    %_RAD_REPLY = (%_RAD_REPLY, %{ $GUEST_POOLS{$neg_ip_pool}{RAD_REPLY} });
  }

  if ($NAS->{NAS_ALIVE}) {
    $_RAD_REPLY{'Acct-Interim-Interval'}=$NAS->{NAS_ALIVE};
  }

  $self->{UID}   = 0 if (! $self->{UID});
  $self->{TP_ID} = 0 if (! $self->{TP_ID});
  $self->{GUEST_MODE}=1;

  return 0, \%_RAD_REPLY;
}

#**********************************************************
=head2 auth($RAD_REQUEST, $NAS, $attr)

  Client        -> Server     -> Client       ->  Server
  DHCP-Discover -> DHCP Offer -> DHCP-Request ->  DHCP ACK/DHCP NAK (Not found)
=cut
#**********************************************************
sub auth {
  my $self = shift;
  my ($RAD_REQUEST, $NAS, $attr) = @_;

  if ($attr->{RAD_REQUEST}) {
    $RAD_REQUEST = $attr->{RAD_REQUEST};
  }

  %_RAD_REPLY     = ();
  my $uid        = 0;
  $self->{INFO}  = '';
  $NAS->{NAS_ALIVE} = 1800 if (!$NAS->{NAS_ALIVE});

  $self->{GUEST_MODE}  = 0;
  #Last leases if exist
  $self->{GUEST_LEASES}= 0;
  my $user_auth_params = {};

  # IPoE Context
  if ($RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    $_RAD_REPLY{'Service-Type'} = 'Framed';
  }

  if ($RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}) {
    $self->{INFO} = " $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}/$RAD_REQUEST->{'NAS-Port-Id'}";
  }


  #Action for freeradius DHCP
  if ($RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    $user_auth_params = $self->Auth2::opt82_parse($RAD_REQUEST, { AUTH_EXPR => $CONF->{MX80_O82_EXPR} });

    # If this is DHCP-Discover, we must offer to user ip-address, and if he'll accept it, he will send DHCP-Request to us
    if ($CONF->{MX80_IPOE_SWITCH_PORT}) {
      if(!$user_auth_params->{USER_MAC} && $RAD_REQUEST->{'User-Name'} =~ /([a-f0-9]{2})([a-f0-9]{2})\.([a-f0-9]{2})([a-f0-9]{2})\.([a-f0-9]{2})([a-f0-9]{2})/) {
        $user_auth_params->{USER_MAC} = "$1:$2:$3:$4:$5:$6";
      }
      elsif(!$user_auth_params->{USER_MAC} && $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} && $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} =~ /([a-f0-9]{2})([a-f0-9]{2})\.([a-f0-9]{2})([a-f0-9]{2})\.([a-f0-9]{2})([a-f0-9]{2})/) {
        $user_auth_params->{USER_MAC} = "$1:$2:$3:$4:$5:$6";
      }

      # Q-in-Q auth
      #print "/// if ($RAD_REQUEST->{'NAS-Port-Id'} =~ /:(\d+)\-(\d+)$/) { //\n\n";
      if ($RAD_REQUEST->{'NAS-Port-Id'} =~ /:(\d+)\-(\d+)$/) {
        my $server_vlan=$1;
        my $client_vlan=$2;

        $user_auth_params->{SERVER_VLAN}= $server_vlan;
        $user_auth_params->{VLAN}       = $client_vlan;

        if (! $user_auth_params->{NAS_MAC}) {
          if ($RAD_REQUEST->{'ERX-Dhcp-Options'} =~ /([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/) {
            $user_auth_params->{NAS_MAC} = "$1:$2:$3:$4:$5:$6";
          }
        }
      }
      #$user_auth_params->{SERVER_VLAN}=undef;
      #Get user from dhcphosts
      #$user_auth_params->{SWITCH_PORT_AUTH} = $CONF->{MX80_IPOE_SWITCH_PORT};
      $user_auth_params->{NAS_PORT_AUTH} = ($user_auth_params->{SERVER_VLAN} || $CONF->{AUTH_PARAMS} || $CONF->{MX80_MAC_AUTH}) ? 0 : 1;
      $self->Auth2::dhcp_info($user_auth_params, $NAS);

      #If exist make static IP
      if ($self->{TOTAL} > 0) {
        $uid                              = $self->{UID};
        $RAD_REQUEST->{'User-Name'}       = $self->{LOGIN};
        #Don't return mask
        $_RAD_REPLY{'Framed-IP-Netmask'}  = $self->{NETMASK};
        # Split by nas
        #$NAS->{NAS_ID}                    = $self->{NAS_ID} if ($self->{NAS_ID} > 0);

#        if ($self->{IP}) {
#          if ($self->{GATEWAY} && $self->{GATEWAY} ne '0.0.0.0') {
#            $_RAD_REPLY{'ERX-Dhcp-Options'} = sprintf("0x0304%.2x%.2x%.2x%.2x", split(/\./, $self->{GATEWAY}));
#            $_RAD_REPLY{'Session-Timeout'} = $NAS->{NAS_ALIVE};
#            #$RAD_REPLY{'ERX-Dhcp-Gi-Address'}=$self->{ROUTERS};
#          }
#          if ($self->{DNS}) {
#            $self->{DNS} =~ s/ //g;
#            my @dns_arr = split(/,/, $self->{DNS});
#            push @dns_arr, $self->{DNS2} if ($self->{DNS2});
#            $_RAD_REPLY{'ERX-Primary-Dns'} = $dns_arr[0] if ($dns_arr[0]);
#            $_RAD_REPLY{'ERX-Secondary-Dns'} = $dns_arr[1] if ($dns_arr[1]);
#          }
#        }
      }
      #Else add to guest NET
      else {
        if ($CONF->{MX80_DEFAULT_GUEST_PROFILE} || $profiles{USER_NOT_EXIST}) {
          return $self->guest_mode($RAD_REQUEST, $NAS, "USER_NOT_EXIST $self->{INFO}",
            {
              %$user_auth_params,
              GUEST_MODE_TYPE => 'USER_NOT_EXIST'
            });
        }
        else {
          $_RAD_REPLY{'User-Name'}     = $RAD_REQUEST->{'Mac-Addr'} if ($RAD_REQUEST->{'Mac-Addr'});
          $_RAD_REPLY{'Reply-Message'} = "Can't find ". $self->{INFO};
          $self->{INFO}                = "Can't find ". $self->{INFO};
          return 1, \%_RAD_REPLY;
        }
      }
    }
    #DHCP Mac auth
    else {
      if($RAD_REQUEST->{'User-Name'} =~ /([a-f0-9]{2})([a-f0-9]{2})\.([a-f0-9]{2})([a-f0-9]{2})\.([a-f0-9]{2})([a-f0-9]{2})/) {
        $user_auth_params->{USER_MAC} = "$1:$2:$3:$4:$5:$6";
      }

      #Get user from dhcphosts
      $self->Auth2::dhcp_info($user_auth_params, $NAS);
      if ($self->{TOTAL} > 0) {
        $uid                            = $self->{UID};
        $RAD_REQUEST->{'User-Name'}     = $self->{LOGIN};
        $_RAD_REPLY{'Framed-IP-Netmask'}= $self->{NETMASK} if ($self->{INTERNET_STATIC_IP} && $self->{INTERNET_STATIC_IP} ne '0.0.0.0');
        # Split by nas
        #$NAS->{NAS_ID}                    = $self->{NAS_ID} if ($self->{NAS_ID} > 0);

        if ($self->{GATEWAY} && $self->{GATEWAY} ne '0.0.0.0') {
          $_RAD_REPLY{'ERX-Dhcp-Options'}=sprintf("0x0304%.2x%.2x%.2x%.2x", split(/\./, $self->{GATEWAY}));
          $_RAD_REPLY{'Session-Timeout'}=$NAS->{NAS_ALIVE};
          #$RAD_REPLY{'ERX-Dhcp-Gi-Address'}=$self->{ROUTERS};
        }

        if($self->{DNS}) {
          $self->{DNS}=~s/ //g;
          my @dns_arr = split(/,/, $self->{DNS});
          #push @dns_arr, $self->{DNS2} if ($self->{DNS2});
          $_RAD_REPLY{'ERX-Primary-Dns'}=$dns_arr[0] if ($dns_arr[0]);
          $_RAD_REPLY{'ERX-Secondary-Dns'}=$dns_arr[1] if ($dns_arr[1]);
        }
      }
      #Else add to guest NET
      else {
        return $self->guest_mode($RAD_REQUEST, $NAS,
          "USER_NOT_EXIST $self->{INFO} $user_auth_params->{NAS_MAC}/$user_auth_params->{PORT}",
          { GUEST_MODE_TYPE  => $profiles{USER_NOT_EXIST} || $CONF->{MX80_DEFAULT_GUEST_PROFILE},
            %$user_auth_params
          }
        );
      }
    }

    if ($CONF->{MX80_DEBUG}) {
      `echo "$self->{UID} DHCP !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >> /tmp/mx80_`;
    }
  }

  #Get user info
  $self->user_info($RAD_REQUEST, { UID => $uid, SERVICE_ID => $self->{SERVICE_ID} });
  if ($self->{USER_NAME}) {
    $RAD_REQUEST->{'User-Name'} = $self->{USER_NAME};
  }

  if ($self->{errno}) {
    if ($self->{errno} == 2) {
      return $self->guest_mode($RAD_REQUEST, $NAS, "USER_NOT_EXIST '"
        . $RAD_REQUEST->{'User-Name'} . "' $user_auth_params->{NAS_MAC}/$user_auth_params->{PORT}",
        { GUEST_MODE_TYPE => 'USER_NOT_EXIST', %$user_auth_params });
    }
    elsif ($self->{errno} == 3) {
      $_RAD_REPLY{'Reply-Message'}=$self->{errstr}."$self->{INFO}";
      return 1, \%_RAD_REPLY;
    }
    else {
      return $self->guest_mode($RAD_REQUEST, $NAS, "$self->{errstr} $self->{INFO}",
        { GUEST_MODE_TYPE => $Auth2::connect_errors_ids{$self->{errno}}, %$user_auth_params });
    }
  }
  elsif (!defined($self->{PAYMENT_TYPE})) {
    return $self->guest_mode($RAD_REQUEST, $NAS, "NOT_ALLOW_SERVICE", {
      GUEST_MODE_TYPE  => 'NOT_ALLOW_SERVICE',
      %$user_auth_params
    });
  }

  if ($attr->{GET_USER}) {
    return $self;
  }

  #Get balance state
  if ($self->{PAYMENT_TYPE} == 0) {
    $self->{CREDIT} = $self->{TP_CREDIT} if ($self->{CREDIT} == 0);
    $self->{DEPOSIT} = $self->{DEPOSIT} + $self->{CREDIT} - $self->{CREDIT_TRESSHOLD};
    #Check deposit
    if ($self->{DEPOSIT} <= 0 || $self->{INTERNET_DISABLE} == 5) {
      return $self->guest_mode($RAD_REQUEST, $NAS, "NEG_DEPOSIT: '$self->{DEPOSIT}'", {
        GUEST_MODE_TYPE  => 'NEG_DEPOSIT',
        %$user_auth_params,
      });
    }
  }

  #Check  simultaneously logins if needs
  delete $self->{ASSIGN_IP};
  if ($self->{SIMULTANEOUSLY} > 0) {
    my ($ret, $RAD_REPLY) = $self->check_simultaneously(\%_RAD_REPLY, $NAS, {
        CALLING_STATION_ID => $RAD_REQUEST->{'Mac-Addr'} || $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} || ''
      });

    if ($ret == 1) {
      return 1, $RAD_REPLY;
    }
  }

  if ($self->{IP}) { # && $self->{IP} ne '0.0.0.0') {
    if(! $self->{ASSIGN_IP}) {
      $self->Auth2::online_add({
        %$attr,
        NAS_ID             => $NAS->{NAS_ID},
        FRAMED_IPV6_PREFIX => ($self->{IPV6}) ? "INET6_ATON('". $self->{IPV6} ."')" : undef,
        DELEGATED_IPV6_PREFIX => ($self->{IPV6_PREFIX}) ? "INET6_ATON('". $self->{IPV6_PREFIX} ."')" : undef,
        FRAMED_INTERFACE_ID=>$RAD_REQUEST->{'Framed-Interface-Id'},
        FRAMED_IP_ADDRESS  => "INET_ATON('$self->{IP}')",
        NAS_IP_ADDRESS     => $RAD_REQUEST->{'NAS-IP-Address'},
        CONNECT_INFO       => $RAD_REQUEST->{'NAS-Port-Id'} || '',
        CID                => $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}
      });
    }

    $_RAD_REPLY{'Framed-IP-Address'} = $self->{IP};

    if($self->{IPV6}) {
      my($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8)=split(/:/, Auth2::ipv6_2_long($self->{IPV6}));
      $_RAD_REPLY{'Framed-IPv6-Address'}= ($p1||q{}) .':'. ($p2||q{}) .':'. ($p3||q{}) .':'. ($p4||q{}) .':'.
        ($p5||q{}) .':'. ($p6||q{}) .':'. ($p7||q{}) .':'. ($p8||q{})
        .'/'. $self->{IPV6_MASK};

      $_RAD_REPLY{'Framed-IPv6-Prefix'}= ($p1 || q{}) .':'. ($p2 || q{}) .':'. ($p3 || q{}) . ':' . ($p4 ||q{}) .'::/'. $self->{IPV6_MASK};
      $_RAD_REPLY{'Framed-Interface-Id'} = ($p5 || q{}) .':'. ($p6 || q{}) .':'. ($p7 || q{}) . ':' . ($p8 ||q{});
    }

    if($self->{IPV6_PREFIX}) {
      $_RAD_REPLY{'Delegated-IPv6-Prefix'}=$self->{IPV6_PREFIX}.'/'.$self->{IPV6_PREFIX_MASK};
    }

    if ($RAD_REQUEST->{'ERX-Dhcp-Options'}) {
      $self->query2("SELECT INET_NTOA(netmask) AS netmask,
        dns,
        ntp,
        INET_NTOA(gateway) AS gateway,
        id
      FROM ippools
      WHERE ip<=INET_ATON('$self->{IP}') AND INET_ATON('$self->{IP}')<=ip+counts
      ORDER BY netmask
      LIMIT 1", undef, { INFO => 1 });

      $_RAD_REPLY{'Framed-IP-Netmask'} = $self->{NETMASK} if ($self->{NETMASK});
    }
  }
  else {
    my $ip = $self->Auth2::get_ip($NAS->{NAS_ID}, $RAD_REQUEST->{'NAS-IP-Address'}, {
      TP_IPPOOL    => $self->{TP_IPPOOL},
      CONNECT_INFO => $RAD_REQUEST->{'NAS-Port-Id'} || '',
      CID          => $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}
    });

    if ($ip eq '-1') {
      $_RAD_REPLY{'Reply-Message'} = "Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS})";
      return 1, \%_RAD_REPLY;
    }
    elsif ($ip eq '0') {
      #my $m = `echo "ADD_CALLS Session  Port: $RAD_REQUEST->{'NAS-Port-Id'} U: $RAD_REQUEST->{'User-Name'}" >> /tmp/mx80`;
      my $sql = "INSERT INTO `internet_online`
       (status, user_name, started, nas_ip_address, nas_port_id, framed_ip_address,
         cid, connect_info, nas_id, tp_id, uid, guest, lupdated, service_id)
       VALUES
        ('11','" . ($self->{USER_NAME} || $_RAD_REPLY{'User-Name'}) . "', now(),
         INET_ATON('" . $RAD_REQUEST->{'NAS-IP-Address'} . "'),
         '" . $RAD_REQUEST->{'NAS-Port'} . "',
         INET_ATON('" . (($_RAD_REPLY{'Framed-IP-Address'}) ? $_RAD_REPLY{'Framed-IP-Address'} : '0.0.0.0') . "'),
         '" . $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} . "', '" . $RAD_REQUEST->{'NAS-Port-Id'} . "',
         '$NAS->{NAS_ID}',
         '$self->{TP_ID}',
         '$self->{UID}',
         '$self->{GUEST_MODE}',
         UNIX_TIMESTAMP(),
         '". ($self->{SERVICE_ID} || 0). "');";

      $self->query2($sql, 'do');
    }
    else {
      $_RAD_REPLY{'Framed-IP-Address'} = $ip;
      if ($RAD_REQUEST->{'ERX-Dhcp-Options'}) {
        $_RAD_REPLY{'Framed-IP-Netmask'} = $self->{NETMASK} if ($self->{NETMASK});
      }

      if ($self->{GATEWAY} && $self->{GATEWAY} ne '0.0.0.0') {
        $_RAD_REPLY{'ERX-Dhcp-Options'} = sprintf("0x0304%.2x%.2x%.2x%.2x", split(/\./, $self->{GATEWAY}));
        $_RAD_REPLY{'Session-Timeout'} = $NAS->{NAS_ALIVE};
        #$RAD_REPLY{'ERX-Dhcp-Gi-Address'}=$self->{ROUTERS};
      }
      if ($self->{DNS}) {
        $self->{DNS} =~ s/ //g;
        my @dns_arr = split(/,/, $self->{DNS});
        #push @dns_arr, $self->{DNS2} if ($self->{DNS2});
        $_RAD_REPLY{'ERX-Primary-Dns'} = $dns_arr[0] if ($dns_arr[0]);
        $_RAD_REPLY{'ERX-Secondary-Dns'} = $dns_arr[1] if ($dns_arr[1]);
      }
    }
  }

  if ($_RAD_REPLY{'Framed-IP-Address'}
    && ! $_RAD_REPLY{'Framed-IP-Netmask'}
    && $RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    $_RAD_REPLY{'Framed-IP-Netmask'} = $self->{NETMASK};
  }

  # SET ACCOUNT expire date
  if ($self->{ACCOUNT_AGE} > 0 && $self->{INTERNET_EXPIRE} eq '0000-00-00') {
    $self->query2("UPDATE internet_main SET expire=CURDATE() + INTERVAL $self->{ACCOUNT_AGE} day
      WHERE uid='$self->{UID}';", 'do'
    );
  }

  if ($NAS->{NAS_ALIVE}) {
    $_RAD_REPLY{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE} if ($NAS->{NAS_ALIVE});
  }

  my $profile_sufix = ( $RAD_REQUEST->{'Framed-Protocol'} ) ? 'pppoe' : 'ipoe';
  my $traffic_class_name = 'global';

  my $traffic_types_count = 3; #$self->{TOTAL};

  if($CONF->{TRAFFIC_EXPR}) {
    #$traf_tarif
    my $EX_PARAMS = $self->ex_traffic_params({
      traf_limit  => 0,
      deposit     => $self->{DEPOSIT},
      TT_INTERVAL => $self->{INTERVAL_ID},
      BILLING     => $Billing
    });

    if ($EX_PARAMS->{ex_speed}) {
      $EX_PARAMS->{ex_speed} = $EX_PARAMS->{ex_speed} * 1024;
      $_RAD_REPLY{'ERX-Service-Activate:1'} = "$profile_prefix-$traffic_class_name-$profile_sufix($EX_PARAMS->{ex_speed},$EX_PARAMS->{ex_speed})";
    }
    elsif ($EX_PARAMS->{speed}) {
      my %speeds = ();
      foreach my $class_id (keys %{$EX_PARAMS->{speed}}) {
        $traffic_class_name = ($class_id > 0) ? "local_$class_id" : 'global';
        if ($EX_PARAMS->{speed}->{$class_id}->{IN} + $EX_PARAMS->{speed}->{$class_id}->{OUT} > 0) {
          $speeds{$class_id}{OUT} = $EX_PARAMS->{speed}->{$class_id}->{OUT} * 1024;
          $speeds{$class_id}{IN} = $EX_PARAMS->{speed}->{$class_id}->{IN} * 1024;

          my $profile_name = ($CONF->{MX80_GLOBAL_PROFILE} && $class_id == 0) ? $CONF->{MX80_GLOBAL_PROFILE} : "$profile_prefix-$traffic_class_name-$profile_sufix";
          my $service_id = $traffic_types_count - $class_id;
          #push @{ $RAD_REPLY{'ERX-Service-Activate:'.$class_id} },  "$profile_name("
          $_RAD_REPLY{'ERX-Service-Activate:'.$service_id} = "$profile_name("
            .$speeds{$class_id}{OUT}.','
            .$speeds{$class_id}{IN}.')';
        }
      }
    }
  }
  else {
    if ($self->{SPEED}) {
      $self->{SPEED} = $self->{SPEED} * 1024;
      $_RAD_REPLY{'ERX-Service-Activate:1'} = "$profile_prefix-$traffic_class_name-$profile_sufix($self->{SPEED},$self->{SPEED})";
    }
    else {
      #Get Speed
      $self->query2("SELECT tt.in_speed, tt.out_speed, tt.net_id, tt.expression, tt.id AS traffic_class_id
     FROM trafic_tarifs tt
     LEFT JOIN intervals intv ON (tt.interval_id = intv.id)
    WHERE intv.begin <= DATE_FORMAT( NOW(), '%H:%i:%S' )
      AND intv.end >= DATE_FORMAT( NOW(), '%H:%i:%S' )
      AND intv.tp_id='$self->{TP_ID}'
     AND intv.day IN (SELECT IF ( intv.day=8,
      (SELECT IF ((SELECT COUNT(*) FROM holidays WHERE DATE_FORMAT( NOW(), '%c-%e' ) = day)>0, 8,
                (SELECT IF(intv.day=0, 0, (SELECT intv.day FROM intervals AS intv WHERE DATE_FORMAT(NOW(), '%w')+1 = intv.day LIMIT 1))))),
       (SELECT IF (intv.day=0, 0,
                (SELECT intv.day FROM intervals AS intv WHERE DATE_FORMAT( NOW(), '%w')+1 = intv.day LIMIT 1)))))
   GROUP BY tt.id
   ORDER by tt.id DESC; ",
        undef,
        { COLS_NAME => 1 }
      );

      #      #Get Speed
      #      $self->query2("SELECT tp.tp_id, tt.in_speed, tt.out_speed, tt.net_id, tt.expression, tt.id AS traffic_class_id
      #     FROM trafic_tarifs tt
      #     LEFT JOIN intervals intv ON (tt.interval_id = intv.id)
      #     LEFT JOIN tarif_plans tp ON (tp.tp_id = intv.tp_id)
      #
      #    WHERE intv.begin <= DATE_FORMAT( NOW(), '%H:%i:%S' )
      #      AND intv.end >= DATE_FORMAT( NOW(), '%H:%i:%S' )
      #      AND tp.module='Dv'
      #      AND tp.tp_id='$self->{TP_ID}'
      #     AND intv.day IN (SELECT IF ( intv.day=8,
      #      (SELECT IF ((SELECT COUNT(*) FROM holidays WHERE DATE_FORMAT( NOW(), '%c-%e' ) = day)>0, 8,
      #                (SELECT IF(intv.day=0, 0, (SELECT intv.day FROM intervals AS intv WHERE DATE_FORMAT(NOW(), '%w')+1 = intv.day LIMIT 1))))),
      #       (SELECT IF (intv.day=0, 0,
      #                (SELECT intv.day FROM intervals AS intv WHERE DATE_FORMAT( NOW(), '%w')+1 = intv.day LIMIT 1)))))
      #   GROUP BY tp.tp_id, tt.id
      #   ORDER by tp.tp_id, tt.id DESC; ",
      #        undef,
      #        { COLS_NAME => 1 }
      #      );

      if ($self->{TOTAL} > 0) {
        my %speeds = ();
        #my $traffic_types_count = 3; #$self->{TOTAL};
        foreach my $tp (@{ $self->{list} }) {
          $traffic_class_name = ($tp->{traffic_class_id} > 0) ? "local_$tp->{traffic_class_id}" : 'global';
          my $service_id = $traffic_types_count - $tp->{traffic_class_id};
          if ($tp->{out_speed} + $tp->{in_speed} > 0) {
            $speeds{$tp->{net_id}}{OUT} = $tp->{out_speed} * 1024;
            $speeds{$tp->{net_id}}{IN} = $tp->{in_speed} * 1024;
            my $profile_name = ($CONF->{MX80_GLOBAL_PROFILE} && $tp->{traffic_class_id} == 0) ? $CONF->{MX80_GLOBAL_PROFILE} : "$profile_prefix-$traffic_class_name-$profile_sufix";
            #push @{ $RAD_REPLY{'ERX-Service-Activate:'.$tp->{traffic_class_id}} },  "$profile_name("
            $_RAD_REPLY{'ERX-Service-Activate:'.$service_id} = "$profile_name("
              .$speeds{$tp->{net_id}}{OUT}.','
              .$speeds{$tp->{net_id}}{IN}.')';
          }

          if($self->{TOTAL} > 1) {
            $_RAD_REPLY{'ERX-Service-Statistics:'.$service_id} = 'time-volume'
          }
        }
      }
    }
  }

  #NAT section
  if ($CONF->{MX80_NAT_PROFILE} && $_RAD_REPLY{'Framed-IP-Address'}) {
    my @nets = (
        '10.0.0.0/8',
        '172.16.0.0/12',
        '192.168.0.0/16',
        '100.64.0.0/10'
    );
    foreach my $ip_range (@nets) {
      $ip_range =~ /(.+)\/(\d+)/;
      my $ip_ = $1;
      my $IP = unpack("N", pack("C4", split(/\./, $ip_)));
      my $NETMASK = unpack "N", pack("B*", ("1" x $2 . "0" x (32 - $2)));
      my $client_ip_num = unpack("N", pack("C4", split(/\./, $_RAD_REPLY{'Framed-IP-Address'})));
      `echo " $ip_ $IP " >> /tmp/x`;
      if (($client_ip_num & $NETMASK) == ($IP & $NETMASK)) {
        my $nat_profile = ($RAD_REQUEST->{'Framed-Protocol'}) ? 'svc-cgn-nat-pppoe' : 'svc-cgn-nat-ipoe';
        $_RAD_REPLY{'ERX-Service-Activate:2'} = $nat_profile;
      }
    }
  }


  if ($self->{TP_RAD_PAIRS}) {
    Auth2::rad_pairs_former($self->{TP_RAD_PAIRS}, { RAD_PAIRS => \%_RAD_REPLY });
  }

  if (length($self->{FILTER}) > 1) {
    $self->Auth2::neg_deposit_filter_former($RAD_REQUEST, $NAS, $self->{FILTER},
      { USER_FILTER => 1, RAD_PAIRS => \%_RAD_REPLY  });
  }

  #Auto assing MAC in first connect
  if ( $CONF->{MAC_AUTO_ASSIGN}
    && ! $self->{CID}) {
    my $cid = $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'};

    if ($RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} =~ /([0-9a-f]{2})([0-9a-f]{2})\.([0-9a-f]{2})([0-9a-f]{2})\.([0-9a-f]{2})([0-9a-f]{2})/) {
      $cid = "$1:$2:$3:$4:$5:$6";
    }

    $self->query2("UPDATE internet_main SET cid='$cid'
     WHERE uid='$self->{UID}' AND cid='';", 'do');
  }

  #Other params
  return 0, \%_RAD_REPLY;
}

#*********************************************************
=head2 Auth_CID($RAD)

=cut
#*********************************************************
sub Auth_CID {
  my $self = shift;
  my ($RAD) = @_;

  my $RAD_PAIRS;
  my $calling_station_id = $RAD->{'ERX-Dhcp-Mac-Addr'};
  my @MAC_DIGITS_GET     = ();
  if (!$calling_station_id) {
    $RAD_PAIRS->{'Reply-Message'} = "WRONG_CID ''";
    return 1, $RAD_PAIRS, "WRONG_CID ''";
  }

  my @CID_POOL = split(/;/, $self->{CID});

  foreach my $TEMP_CID (@CID_POOL) {
    if ($TEMP_CID ne '') {

      if ($TEMP_CID =~ /([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2})/i) {
        $TEMP_CID = lc("$1$2.$3$4.$5$6");
      }

      if (($TEMP_CID =~ /:/ || $TEMP_CID =~ /\-/)
        && $TEMP_CID !~ /\./) {
        @MAC_DIGITS_GET = split(/:|-/, $TEMP_CID);
        my @MAC_DIGITS_NEED = split(/:|\-|\./, $RAD->{CALLING_STATION_ID});
        my $counter = 0;

        for (my $i = 0 ; $i <= 5 ; $i++) {
          if (defined($MAC_DIGITS_NEED[$i]) && hex($MAC_DIGITS_NEED[$i]) == hex($MAC_DIGITS_GET[$i])) {
            $counter++;
          }
        }
        return 0 if ($counter eq '6');
      }

      # If like MPD CID
      # 192.168.101.2 / 00:0e:0c:4a:63:56
      elsif ($TEMP_CID =~ /\//) {
        $calling_station_id =~ s/ //g;
        my ($cid_ip, $cid_mac) = split(/\//, $calling_station_id, 3);
        if ("$cid_ip/$cid_mac" eq $TEMP_CID) {
          return 0;
        }
      }
      elsif ($TEMP_CID eq $calling_station_id) {
        return 0;
      }
    }
  }

  $RAD_PAIRS->{'Reply-Message'} = "WRONG_CID '$calling_station_id'";
  return 1, $RAD_PAIRS;
}

#**********************************************************
=head2 accounting($RAD, $NAS) Accounting section

=cut
#**********************************************************
sub accounting {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  #my $RAD_REQUEST;
  #if ($attr->{RAD_REQUEST}) {
  #  $RAD_REQUEST = $attr->{RAD_REQUEST};
  #}
  $self->{SUM} = 0 if (!$self->{SUM});
  my $acct_status_type = $ACCT_TYPES{ $RAD->{'Acct-Status-Type'} };
  my $acct_session_id  = $RAD->{'Acct-Session-Id'};
  $RAD->{'Acct-Input-Gigawords'}  = 0 if (! $RAD->{'Acct-Input-Gigawords'});
  $RAD->{'Acct-Output-Gigawords'} = 0 if (! $RAD->{'Acct-Output-Gigawords'});
  $RAD->{'Acct-Terminate-Cause'} = ($RAD->{'Acct-Terminate-Cause'} && defined($ACCT_TERMINATE_CAUSES{$RAD->{'Acct-Terminate-Cause'}})) ? $ACCT_TERMINATE_CAUSES{$RAD->{'Acct-Terminate-Cause'}} : 0;

  if($RAD->{'ERX-Service-Session'}) {
    if($acct_session_id =~ /(\d+):/) {
      $acct_session_id = $1;
    }

    #my $ss = `echo "$RAD->{'ERX-Service-Session'}  ses: $RAD->{'Acct-Session-Id'}  $RAD->{INBYTE}  $RAD->{OUTBYTE} EX:  $RAD->{INBYTE2};  $RAD->{OUTBYTE2}" >> /tmp/mx.accc`;
#    $RAD->{INBYTE}=0;
#    $RAD->{OUTBYTE}=0;
#    $RAD->{INBYTE2}= 0;
#    $RAD->{OUTBYTE2}=0;
    return $self;
  }

  if (length($acct_session_id) > 25) {
    $acct_session_id = substr($acct_session_id, 0, 24);
  }

  #Start
  if ($acct_status_type == 1) {
    $self->query2("UPDATE internet_online SET
     status=1,
     started=NOW() - INTERVAL ? SECOND,
     lupdated=UNIX_TIMESTAMP(),
     acct_session_id=?,
     framed_ip_address=INET_ATON( ? )
    WHERE
      nas_id= ?
      AND cid= ?
      AND connect_info=?
      AND status>3 LIMIT 1;",
      'do',
      { Bind => [
          $RAD->{'Acct-Session-Time'} || 0,
          $acct_session_id,
          $RAD->{'Framed-IP-Address'} || $RAD->{'Assigned-IP-Address'} || '0.0.0.0',
          $NAS->{NAS_ID},
          $RAD->{'ERX-Dhcp-Mac-Addr'},
          $RAD->{'NAS-Port-Id'}
        ]});
  }

  # Stop status
  elsif ($acct_status_type == 2) {
    $CONF->{rt_billing}=1;
    if ($CONF->{rt_billing}) {
      $self->rt_billing($RAD, $NAS);

      if (!$self->{errno}) {
        $self->query2("INSERT INTO internet_log SET
          uid= ? ,
          start=NOW() - INTERVAL ? SECOND,
          tp_id= ? ,
          duration= ? ,
          sent= ? ,
          recv= ? ,
          sum= ? ,
          nas_id= ? ,
          port_id= ? ,
          ip=INET_ATON( ? ),
          cid= ? ,
          sent2= ? ,
          recv2= ? ,
          acct_session_id= ? ,
          bill_id= ? ,
          terminate_cause= ? ,
          acct_input_gigawords= ? ,
          acct_output_gigawords= ? ",
          'do',
          { Bind => [ $self->{UID},
              $RAD->{'Acct-Session-Time'},
              $self->{TP_ID} || 0,
              $RAD->{'Acct-Session-Time'},
              $RAD->{OUTBYTE},
              $RAD->{INBYTE},
              $self->{CALLS_SUM}+$self->{SUM},
              $NAS->{NAS_ID},
              $RAD->{'NAS-Port'},
              $RAD->{'Framed-IP-Address'},
              $RAD->{'ERX-Dhcp-Mac-Addr'} || $RAD->{'Calling-Station-Id'} || '',
              $RAD->{OUTBYTE2},
              $RAD->{INBYTE2},
              $acct_session_id,
              $self->{BILL_ID},
              $RAD->{'Acct-Terminate-Cause'},
              $RAD->{'Acct-Input-Gigawords'},
              $RAD->{'Acct-Output-Gigawords'}
            ] }
        );

        # Delete from session
        $self->query2("DELETE FROM internet_online WHERE
      (acct_session_id= ? OR (connect_info= ? AND status=11))
      AND nas_id= ? ;", 'do', {
          Bind =>  [
            $acct_session_id,
            $RAD->{'NAS-Port-Id'},
            $NAS->{NAS_ID}
          ] });

      }
      else {
        if ($self->{errno} == 2) {
          delete $self->{errno};
          return $self;
        }
        #DEbug only
        if ($CONF->{ACCT_DEBUG}) {
          use POSIX qw(strftime);
          my $DATE_TIME = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time));
          `echo "$DATE_TIME $self->{UID} - $RAD->{'User-Name'} / $acct_session_id / Time: $RAD->{'Acct-Session-Time'} / $self->{errstr}" >> /tmp/unknown_session.log`;
          #DEbug only end
        }
      }
    }
  }
  #Alive status 3
  elsif ($acct_status_type == 3) {
    $self->{SUM} = 0 if (!$self->{SUM});

    if($RAD->{'ERX-Service-Session'}) {
      $self->query2("UPDATE internet_online SET
      ex_input_octets=$RAD->{INBYTE},
      ex_output_octets=$RAD->{OUTBYTE},
      ex_input_octets_gigawords='". $RAD->{'Acct-Input-Gigawords'} ."',
      ex_output_octets_gigawords='". $RAD->{'Acct-Output-Gigawords'} ."',
      status='$acct_status_type'
    WHERE
      acct_session_id='" . $acct_session_id . "'
      AND nas_id='$NAS->{NAS_ID}' LIMIT 1;", 'do'
      );

      return $self;
    }
    elsif ($NAS->{NAS_EXT_ACCT}) {
      my $ipn_fields = '';
      if ($NAS->{IPN_COLLECTOR}) {
        $ipn_fields = "
      sum=sum+$self->{SUM},
      acct_input_octets='$RAD->{INBYTE}',
      acct_output_octets='$RAD->{OUTBYTE}',
      ex_input_octets=ex_input_octets + $RAD->{INBYTE2},
      ex_output_octets=ex_output_octets + $RAD->{OUTBYTE2},
      acct_input_gigawords='". $RAD->{'Acct-Input-Gigawords'} ."',
      acct_output_gigawords='". $RAD->{'Acct-Output-Gigawords'} ."',";
      }

      $self->query2("UPDATE internet_online SET
      $ipn_fields
      status='$acct_status_type',
      acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
      lupdated=UNIX_TIMESTAMP()
    WHERE
      acct_session_id='" . $acct_session_id . "'
      AND nas_id='$NAS->{NAS_ID}' LIMIT 1;", 'do'
      );
      return $self;
    }

    $self->rt_billing($RAD, $NAS);

    # Can't find online records
    if ($self->{errno} && $self->{errno}  == 2) {
      if (!$RAD->{'Framed-Protocol'} || $RAD->{'Framed-Protocol'} ne 'PPP') {
        $self->auth($RAD, $NAS, { GET_USER => 1 });
        $RAD->{'User-Name'}= $self->{LOGIN} || $self->{USER_NAME} || $RAD->{'ERX-Dhcp-Mac-Addr'};
      }
      else {
        $self->query2("SELECT u.uid, internet.tp_id, internet.id AS service_id
          FROM users u
          INNER JOIN internet_main internet ON (u.uid=internet.uid)
          WHERE u.id= ? ;",
          undef,
          { INFO  => 1, Bind => [ $RAD->{'User-Name'} ] });
      }

      #Lost session debug
      my $debug = 0;
      if($debug) {
        my $info_rr = '';
        if(! $self->{UID}) {
          foreach my $k(sort keys %$RAD) {
            my $v = $RAD->{$k};
            $info_rr .= "$k, $v\n";
          }
        }
        `echo "Lost session USER_NAME: $RAD->{'User-Name'} UID: $self->{UID} TIME: $RAD->{'Acct-Session-Time'}\n$info_rr" >> /tmp/lost_session`;
        #=== Lost session debug
      }

      $self->query2("REPLACE INTO internet_online SET
            status= ? ,
            user_name= ? ,
            started=NOW() - INTERVAL ? SECOND,
            lupdated=UNIX_TIMESTAMP(),
            nas_ip_address=INET_ATON( ? ),
            nas_port_id= ? ,
            acct_session_id= ? ,
            framed_ip_address=INET_ATON( ? ),
            cid= ? ,
            connect_info= ? ,
            acct_input_octets= ? ,
            acct_output_octets= ? ,
            acct_input_gigawords= ? ,
            acct_output_gigawords= ? ,
            nas_id= ? ,
            tp_id= ? ,
            uid= ? ,
            guest = ?,
            acct_session_time = ?,
            service_id = ? ;",
        'do',
        { Bind => [
            '9',
            $RAD->{'User-Name'} || '',
            $RAD->{'Acct-Session-Time'} || 0,
            $RAD->{'NAS-IP-Address'},
            $RAD->{'NAS-Port'} || 0,
            $acct_session_id,
            $RAD->{'Framed-IP-Address'} || '0.0.0.0',
            $RAD->{'ERX-Dhcp-Mac-Addr'} || $RAD->{'Calling-Station-Id'} || '',
            $RAD->{'NAS-Port-Id'} || $RAD->{'Connect-Info'},
            $RAD->{'INBYTE'},
            $RAD->{'OUTBYTE'},
            $RAD->{'Acct-Input-Gigawords'},
            $RAD->{'Acct-Output-Gigawords'},
            $NAS->{NAS_ID},
            $self->{TP_ID} || 0,
            $self->{UID} || 0,
            ($self->{UID}) ? 0 : 1,
            $RAD->{'Acct-Session-Time'} || 0,
            $self->{SERVICE_ID} || 0
          ]});
      return $self;
    }
    else {
      my $ex_octets = '';
      if ($RAD->{INBYTE2} || $RAD->{OUTBYTE2}) {
        $ex_octets = "ex_input_octets='$RAD->{INBYTE2}',  ex_output_octets='$RAD->{OUTBYTE2}', ";
      }

      $self->query2("UPDATE internet_online SET
      status=?,
      acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
      acct_input_octets=?,
      acct_output_octets=?,
      $ex_octets
      lupdated=UNIX_TIMESTAMP(),
      sum=sum + ?,
      framed_ip_address=INET_ATON( ? ),
      acct_input_gigawords= ?,
      acct_output_gigawords= ?
     WHERE
      acct_session_id=?
      AND nas_id= ?
     LIMIT 1;",
        'do',
        { Bind => [
            $acct_status_type,
            $RAD->{INBYTE},
            $RAD->{OUTBYTE},
            $self->{SUM},
            $RAD->{'Framed-IP-Address'} || $RAD->{'Assigned-IP-Address'},
            $RAD->{'Acct-Input-Gigawords'},
            $RAD->{'Acct-Output-Gigawords'},
            $acct_session_id,
            $NAS->{NAS_ID}
          ] });
    }
  }
  else {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [".$RAD->{'User-Name'}."] Unknown accounting status: "> $RAD->{'Acct-Status-Type'} ." (". $acct_session_id .")";
  }

  if ($self->{errno}) {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT ". $RAD->{'Acct-Status-Type'} ." SQL Error";
    return $self;
  }

  #detalization for Exppp
  if ($CONF->{s_detalization} && $self->{UID}) {
    $self->query2("INSERT INTO s_detail (acct_session_id, nas_id, acct_status, last_update, sent1, recv1, sent2, recv2, id, uid, sum)
       VALUES ( ? , ?, ? , UNIX_TIMESTAMP(), ? , ? , ? , ? , ? , ?, ?);",
      'do',
      { Bind => [
          $acct_session_id,
          $NAS->{NAS_ID},
          $acct_status_type,
          $RAD->{INBYTE} +  (($RAD->{'Acct-Input-Gigawords'})  ? $RAD->{'Acct-Input-Gigawords'} * 4294967296  : 0),
          $RAD->{OUTBYTE} + (($RAD->{'Acct-Output-Gigawords'}) ? $RAD->{'Acct-Output-Gigawords'} * 4294967296 : 0),
          $RAD->{INBYTE2}  || 0,
          $RAD->{OUTBYTE2} || 0,
          $RAD->{'User-Name'} || q{},
          $self->{UID} || 0,
          $self->{SUM}
        ]}
    );
  }

  return $self;
}

#**********************************************************
=head rt_billing($RAD, $NAS) Alive accounting

=cut
#**********************************************************
sub rt_billing {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  if (! $RAD->{'Acct-Session-Id'}) {
    $self->{errno}  = 2;
    $self->{errstr} = "Session account rt Not Exist '$RAD->{'Acct-Session-Id'}'";
    return $self;
  }

  my $acct_session_id = $RAD->{'Acct-Session-Id'};

  $self->query2("SELECT IF(UNIX_TIMESTAMP() > lupdated, UNIX_TIMESTAMP() - lupdated, 0), UNIX_TIMESTAMP()-lupdated,
   IF($RAD->{INBYTE}   >= acct_input_octets AND ". $RAD->{'Acct-Input-Gigawords'} ."=acct_input_gigawords,
        $RAD->{INBYTE} - acct_input_octets,
        IF(". $RAD->{'Acct-Input-Gigawords'} ." > acct_input_gigawords, 4294967296 * (". $RAD->{'Acct-Input-Gigawords'} ." - acct_input_gigawords) - acct_input_octets + $RAD->{INBYTE}, 0)),
   IF($RAD->{OUTBYTE}  >= acct_output_octets AND ". $RAD->{'Acct-Output-Gigawords'} ."=acct_output_gigawords,
        $RAD->{OUTBYTE} - acct_output_octets,
        IF(". $RAD->{'Acct-Output-Gigawords'} ." > acct_output_gigawords, 4294967296 * (". $RAD->{'Acct-Output-Gigawords'} ." - acct_output_gigawords) - acct_output_octets + $RAD->{OUTBYTE}, 0)),
   IF($RAD->{INBYTE2}  >= ex_input_octets, $RAD->{INBYTE2}  - ex_input_octets, ex_input_octets),
   IF($RAD->{OUTBYTE2} >= ex_output_octets, $RAD->{OUTBYTE2} - ex_output_octets, ex_output_octets),
   sum,
   tp_id,
   uid
   FROM internet_online
  WHERE nas_id='$NAS->{NAS_ID}' AND acct_session_id='". $acct_session_id ."';");

  if ($self->{errno}) {
    return $self;
  }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = "Session account rt Not Exist '$acct_session_id' ($RAD->{'Acct-Status-Type'}) ";
    return $self;
  }

  ($RAD->{INTERIUM_SESSION_START},
   $RAD->{INTERIUM_ACCT_SESSION_TIME},
   $RAD->{INTERIUM_INBYTE},
   $RAD->{INTERIUM_OUTBYTE},
   $RAD->{INTERIUM_INBYTE1},
   $RAD->{INTERIUM_OUTBYTE1},
   $self->{CALLS_SUM},
   $self->{TP_ID},
   $self->{UID}) = @{ $self->{list}->[0] };

  my $out_byte = $RAD->{OUTBYTE} + $RAD->{'Acct-Output-Gigawords'} * 4294967296;
  my $in_byte  = $RAD->{INBYTE} + $RAD->{'Acct-Input-Gigawords'} * 4294967296;

  ($self->{UID},
   $self->{SUM},
   $self->{BILL_ID},
   $self->{TP_ID},
   $self->{TIME_TARIF},
   $self->{TRAF_TARIF}) = $Billing->session_sum(
       $RAD->{'User-Name'},
       $RAD->{INTERIUM_SESSION_START},
       $RAD->{INTERIUM_ACCT_SESSION_TIME},
       {
         OUTBYTE  => ($out_byte == $RAD->{INTERIUM_OUTBYTE}) ? $RAD->{INTERIUM_OUTBYTE} : $out_byte - $RAD->{INTERIUM_OUTBYTE},
         INBYTE   => ($in_byte  == $RAD->{INTERIUM_INBYTE}) ? $RAD->{INTERIUM_INBYTE} : $in_byte - $RAD->{INTERIUM_INBYTE},
         OUTBYTE2 => $RAD->{OUTBYTE2} - $RAD->{INTERIUM_OUTBYTE1},
         INBYTE2  => $RAD->{INBYTE2} - $RAD->{INTERIUM_INBYTE1},
      #OUTBYTE  => $RAD->{INTERIUM_OUTBYTE},
      #INBYTE   => $RAD->{INTERIUM_INBYTE},
      #OUTBYTE2 => $RAD->{INTERIUM_OUTBYTE1},
      #INBYTE2  => $RAD->{INTERIUM_INBYTE1},
         INTERIUM_OUTBYTE  => $RAD->{INTERIUM_OUTBYTE},
         INTERIUM_INBYTE   => $RAD->{INTERIUM_INBYTE},
         INTERIUM_OUTBYTE1 => $RAD->{INTERIUM_INBYTE1},
         INTERIUM_INBYTE1  => $RAD->{INTERIUM_OUTBYTE1},
       },
    {
      FULL_COUNT => 1,
      TP_ID      => $self->{TP_ID},
      UID        => ($self->{TP_ID}) ? $self->{UID} : undef,
      DOMAIN_ID  => ($NAS->{DOMAIN_ID}) ? $NAS->{DOMAIN_ID} : 0,
    }
  );

  if($CONF->{INTERNET_INTERVAL_PREPAID}) {
    $self->query2("SELECT traffic_type FROM internet_log_intervals
     WHERE acct_session_id= ?
           AND interval_id= ?
           AND uid= ? ;",
      undef,
      { Bind => [ $acct_session_id, $Billing->{TI_ID}, $self->{UID} ] }
    );

    my %intrval_traffic = ();
    foreach my $line (@{$self->{list}}) {
      $intrval_traffic{ $line->[0] } = 1;
    }

    my @RAD_TRAFF_SUFIX = ('', '1');
    $self->{SUM} = 0 if ($self->{SUM} < 0);

    for (my $traffic_type = 0; $traffic_type <= $#RAD_TRAFF_SUFIX; $traffic_type++) {
      next if ($RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } + $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } < 1);

      if ($intrval_traffic{$traffic_type}) {
        $self->query2('UPDATE internet_log_intervals SET
                sent=sent+ ? ,
                recv=recv+ ? ,
                duration=duration + ?,
                sum=sum + ?
              WHERE interval_id= ?
                AND acct_session_id= ?
                AND traffic_type= ?
                AND uid= ? ;', 'do',
          { Bind => [
            $RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] },
            $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] },
            $RAD->{'INTERIUM_ACCT_SESSION_TIME'},
            $self->{SUM},
            $Billing->{TI_ID},
            $acct_session_id,
            $traffic_type,
            $self->{UID}
          ] }
        );
      }
      else {
        $self->query2('INSERT INTO internet_log_intervals (interval_id, sent, recv, duration, traffic_type, sum, acct_session_id, uid, added)
        VALUES ( ? , ? , ? , ? , ? , ? , ? , ?, now());', 'do',
          { Bind => [
            $Billing->{TI_ID},
            $RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] },
            $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] },
            $RAD->{INTERIUM_ACCT_SESSION_TIME},
            $traffic_type,
            $self->{SUM},
            $acct_session_id,
            $self->{UID}
          ] });
      }
    }
  }

  #  return $self;
  if ($self->{UID} == -2) {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{'User-Name'}] Not exist";
  }
  elsif ($self->{UID} == -3) {
    my $filename = "$RAD->{'User-Name'}.$acct_session_id";
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{'User-Name'}] Not allow start period '$filename'";
    $Billing->mk_session_log($RAD);
  }
  elsif ($self->{UID} == -5) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{'User-Name'}] Can't find TP: $self->{TP_ID} Session id: $acct_session_id";
    $self->{errno}     = 1;
    print "ACCT [$RAD->{'User-Name'}] Can't find TP: $self->{TP_ID} Session id: $acct_session_id\n";
  }
  elsif ($self->{SUM} < 0) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{'User-Name'}] small session (". $RAD->{'Acct-Session-Time'}.", $RAD->{INBYTE}, $RAD->{OUTBYTE})";
  }
  elsif ($self->{UID} <= 0) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{'User-Name'}] small session (". $RAD->{'Acct-Session-Time'} .", $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
    $self->{errno}     = 1;
  }
  else {
    if ($self->{SUM} > 0) {
      $self->query2('UPDATE bills SET deposit=deposit - ? WHERE id = ? ;', 'do', { Bind => [ $self->{SUM}, $self->{BILL_ID} ]});
    }
  }

  return $self;
}


=head1 AUTHOR

  Fima
  AXIOSTV (https://billing.axiostv.ru/)
  2012-2020

=cut



1

