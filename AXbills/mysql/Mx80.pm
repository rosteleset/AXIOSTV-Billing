package Mx80 v1.23.0;

=head1 NAME

  Juniper MX80 (mx80)
     PPPoE
     IPoE MAC auth
     IPoE switch port + switch mac auth

=head1 VERSION

  VERSION: 1.23
  REVISION: 20170924

=cut

use strict;
use parent qw(main Auth);
use Billing;
use AXbills::Base qw(in_array);

my %ACCT_TYPES = (
  'Start'          => 1,
  'Stop'           => 2,
  'Alive'          => 3,
  'Interim-Update' => 3,
  'Accounting-On'  => 7,
  'Accounting-Off' => 8
);

my ($CONF, $Billing);

my %_RAD_REPLY         = ();
my %GUEST_POOLS        = ();
my %profiles           = ();
#my @o82_expr_arr       = ();
my $profile_prefix     = 'svc';
my $default_guest_pool = 0;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($CONF) = @_;

  my $self = {};
  bless($self, $class);
  $self->{db}=$db;

#  my $Auth = Auth->new($self->{db}, $conf);
  $Billing = Billing->new($self->{db}, $CONF);

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

#  if ($CONF->{MX80_O82_EXPR}) {
#    $CONF->{MX80_O82_EXPR} =~ s/\n//g;
#    @o82_expr_arr = split(/;/, $CONF->{MX80_O82_EXPR});
#  }

  if($CONF->{MX80_PROFILE_PREFIX}) {
    $profile_prefix=$CONF->{MX80_PROFILE_PREFIX};
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
=head2 user_info($RAD_REQUEST, $NAS, $attr) - get user info

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($RAD_REQUEST, $NAS, $attr) = @_;

  my $WHERE;
  my @binding_vals = ();

  if ($attr->{UID}) {
    $WHERE = " AND dv.uid='$attr->{UID}'";
  }
  elsif ($CONF->{MX80_AUTH_PORT_ID}) {
    $WHERE = " AND u.id= ? ";
    push @binding_vals, $RAD_REQUEST->{'User-Name'} ;
  }
  elsif ($RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    $WHERE = " AND dv.CID= ? ";
    push @binding_vals, $RAD_REQUEST->{'User-Name'} ;
  }
  else {
    $WHERE = " AND u.id= ? ";
    push @binding_vals, $RAD_REQUEST->{'User-Name'} ;
  }

  $self->query2("SELECT 
   u.id AS user_name,
   dv.uid, 
   dv.tp_id AS tp_num, 
   INET_NTOA(dv.ip) AS ip,
   INET_NTOA(dv.netmask) AS netmask,
   IF (dv.logins=0, IF(tp.logins is null, 0, tp.logins), dv.logins) AS simultaneously,
   dv.speed,
   dv.disable AS dv_disable,
   u.disable AS user_disable,
   u.reduction AS discount,
   u.bill_id,
   u.company_id,
   u.credit,
   u.activate AS account_activate,
  UNIX_TIMESTAMP() AS session_start,
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) as day_of_week,
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) as day_of_year,

  IF(dv.filter_id != '', dv.filter_id, IF(tp.filter_id is null, '', tp.filter_id)) AS filter,
  tp.payment_type,
  tp.neg_deposit_filter_id,
  tp.credit AS tp_credit,
  tp.credit_tresshold,
  DECODE(u.password, '$CONF->{secretkey}') AS password,
  dv.CID,
  tp.neg_deposit_ippool,
  tp.ippool AS tp_ippool,
  tp.tp_id,
  tp.rad_pairs AS tp_rad_pairs,
  dv.port,
  tp.age AS account_age,
  dv.expire AS dv_expire,
  tp_int.id AS interval_id
   FROM (dv_main dv, users u)
   LEFT JOIN tarif_plans tp ON (dv.tp_id=tp.id)
   LEFT JOIN intervals tp_int ON (tp_int.tp_id=tp.tp_id)
   WHERE u.uid=dv.uid AND (dv.expire='0000-00-00' OR dv.expire > CURDATE())
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
  if ($self->{DISABLE} || ($self->{DV_DISABLE} && $self->{DV_DISABLE} != 5) || $self->{USER_DISABLE}) {
    $_RAD_REPLY{'Reply-Message'} = "ACCOUNT_DISABLE";
    $self->{errno}              = 6;
    $self->{errstr}             = $_RAD_REPLY{'Reply-Message'};
    return 6, \%_RAD_REPLY;
  }

  if (! $RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    if ($RAD_REQUEST->{'CHAP-Password'} && $RAD_REQUEST->{'CHAP-Challenge'}) {
      if (Auth::check_chap($RAD_REQUEST->{'CHAP-Password'}, $self->{PASSWORD}, $RAD_REQUEST->{'CHAP-Challenge'}, 0) == 0) {
        $_RAD_REPLY{'Reply-Message'} = "WRONG_CHAP_PASSWORD";
        $self->{errno}              = 1;
        $self->{errstr}             = $_RAD_REPLY{'Reply-Message'};
        return 1, \%_RAD_REPLY;
      }
    }
    #If don't athorize any above methods auth PAP password
    else {
      if (defined($RAD_REQUEST->{'User-Password'}) && $self->{PASSWORD} ne $RAD_REQUEST->{'User-Password'}) {
        $_RAD_REPLY{'Reply-Message'} = "WRONG_PASSWORD '" . $RAD_REQUEST->{'User-Password'} . "'";
        $self->{errno}              = 1;
        $self->{errstr}             = $_RAD_REPLY{'Reply-Message'};
        return 1, \%_RAD_REPLY;
      }
    }

    my $pppoe_pluse = ''; 
    my $ignore_cid  = 0;
    if ($CONF->{DV_PPPOE_PLUSE_PARAM} && $RAD_REQUEST->{$CONF->{DV_PPPOE_PLUSE_PARAM}}) {
      $pppoe_pluse = $RAD_REQUEST->{$CONF->{DV_PPPOE_PLUSE_PARAM}} ;
      if ($self->{PORT} && $self->{PORT} !~ /any/i) {
        $ignore_cid  = 1;
      }
      elsif (! $self->{PORT}) {
        $self->query2("UPDATE dv_main SET port='$RAD_REQUEST->{$CONF->{DV_PPPOE_PLUSE_PARAM}}' WHERE uid='$self->{UID}';", 'do');
        $self->{PORT}=$RAD_REQUEST->{$CONF->{DV_PPPOE_PLUSE_PARAM}};
      }
    }
    else {
      $pppoe_pluse = $RAD_REQUEST->{'Nas-Port'} || '';
    }

    #Check port
    if ($self->{PORT} && $self->{PORT} !~ m/any/i && $self->{PORT} ne $pppoe_pluse) {
      $_RAD_REPLY{'Reply-Message'} = "WRONG_PORT '$pppoe_pluse'";
      $self->{errno}              = 7;
      $self->{errstr}             = $_RAD_REPLY{'Reply-Message'};
      return 7, \%_RAD_REPLY;
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

  #Check  simultaneously logins if needs
  if ($self->{SIMULTANEOUSLY} > 0) {
    my ($ret, $RAD_REPLY) = $self->check_simultaneously(\%_RAD_REPLY, $NAS, {
      CALLING_STATION_ID => $RAD_REQUEST->{'Mac-Addr'} || $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} || ''
    });

    if ($ret == 1) {
      return 1, $RAD_REPLY;
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

  $self->query2("SELECT CID, INET_NTOA(framed_ip_address) AS ip, nas_id FROM dv_calls WHERE user_name='$self->{USER_NAME}' and (status <> 2 and status < 11);");
  my $active_logins = $self->{TOTAL} || 0;

  foreach my $line (@{ $self->{list} }) {
    # Zap session with same CID
    if ( $line->[0] 
      && $line->[0] eq $attr->{CALLING_STATION_ID}
      && $line->[2] eq $NAS->{NAS_ID})
    {
      $self->query2("UPDATE dv_calls SET status=6 WHERE user_name='$self->{USER_NAME}' and CID='$attr->{CALLING_STATION_ID}' and status <> 2;", 'do');
      $self->{IP} = $line->[1];
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
#=head2 add_rad_pairs($RAD_REPLY, $pairs)
#
#=cut
#**********************************************************
#sub add_rad_pairs {
#  my $self = shift;
#  my ($RAD_REPLY, $pairs) = @_;
#
#  $pairs =~ tr/\n\r//d;
#  my @pairs_arr = split(/,/, $pairs);
#  foreach my $line (@pairs_arr) {
#    if ($line =~ /([a-zA-Z0-9\-\:]{6,25})\+\=(.{1,200})/) {
#      my $left  = $1;
#      my $right = $2;
#      push @{ $RAD_REPLY->{$left} }, $right;
#    }
#    else {
#      my ($left, $right) = split(/=/, $line, 2);
#      if ($left =~ s/^!//) {
#        delete $RAD_REPLY->{$left};
#      }
#      else {
#        $RAD_REPLY->{$left} = "$right";
#      }
#    }
#  }
#}

#**********************************************************
=head2 guest_mode($RAD_REQUEST, $NAS, $message, $attr)

  Arguments:
    USER_AUTH_PARAMS


=cut
#**********************************************************
sub guest_mode {
  my $self = shift;
  my ($RAD_REQUEST, $NAS, $message, $attr) = @_;

  my $redirect_profile = ($attr->{GUEST_MODE_TYPE} && $profiles{$attr->{GUEST_MODE_TYPE}}) ? $profiles{$attr->{GUEST_MODE_TYPE}} : $CONF->{MX80_DEFAULT_GUEST_PROFILE};

  $_RAD_REPLY{'Reply-Message'} = $message;
  $self->{INFO} = $message;

  if($self->{NEG_DEPOSIT_FILTER_ID}) {
    #$self->neg_deposit_filter_former_old($RAD_REQUEST, $NAS, $self->{NEG_DEPOSIT_FILTER_ID});
    $self->neg_deposit_filter_former($RAD_REQUEST, $NAS, $self->{NEG_DEPOSIT_FILTER_ID}, { RAD_PAIRS => \%_RAD_REPLY });
  }
  elsif (! $redirect_profile )  {
    return 7, \%_RAD_REPLY;
  }

  my $user_auth_params = $attr->{USER_AUTH_PARAMS};

  if ($redirect_profile) {
    $redirect_profile =~ s/pppoe/ipoe/ if (! $RAD_REQUEST->{'Framed-Protocol'} );
    $_RAD_REPLY{'ERX-Service-Activate:1'} = $redirect_profile if($redirect_profile);
  }

  my $neg_ip_pool = $self->{NEG_DEPOSIT_IPPOOL} || $self->{tp_ippool} || $default_guest_pool || 0;

  if (! $self->{IP} || $self->{IP} eq '0.0.0.0') {
    my $ip = $self->Auth::get_ip($NAS->{NAS_ID}, $RAD_REQUEST->{'NAS-IP-Address'}, {
      TP_IPPOOL    => $neg_ip_pool,
      CONNECT_INFO => $RAD_REQUEST->{'NAS-Port-Id'} || '',
      CID          => $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'},
      GUEST        => 1
    });

    if ($ip eq '-1') {
      $_RAD_REPLY{'Reply-Message'} = "Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS})";
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
    if ($_RAD_REPLY{'Framed-IP-Address'} && ! $_RAD_REPLY{'Framed-IP-Netmask'}) {
      $_RAD_REPLY{'Framed-IP-Netmask'} = $self->{NETMASK} if ($self->{NETMASK}) ;
    }
  }
  elsif($self->{IP}) {
    $_RAD_REPLY{'Framed-IP-Address'} = $self->{IP};
    #Add guest start dvcalls_ip
    $self->Auth::online_add({
      %{ ($attr) ? $attr : {} },
      %{ ($user_auth_params) ? $user_auth_params : {} },
      NAS_ID            => $NAS->{NAS_ID},
      FRAMED_IP_ADDRESS => "INET_ATON('$self->{IP}')",
      NAS_IP_ADDRESS    => $RAD_REQUEST->{'NAS-IP-Address'},
      CONNECT_INFO      => $RAD_REQUEST->{'NAS-Port-Id'} || '',
      CID               => $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'},
      GUEST             => 1
    });
  }

  $self->Auth::leases_add({
    %{ ($attr) ? $attr : {} },
    %{ ($user_auth_params) ? $user_auth_params : {} },
    LEASES_TIME => 300,
    USER_MAC    => $user_auth_params->{USER_MAC} || $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'},
    UID         => $self->{UID},
    IP          => $self->{IP},
    PORT        => $user_auth_params->{PORT} || $RAD_REQUEST->{'NAS-Port-Id'} || '',
    },
  $NAS);


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

#  if ($NAS->{NAS_ALIVE}) {
#    $RAD_REPLY{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE} if ($NAS->{NAS_ALIVE});
#  }

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
  my $user_auth_params;

  # IPoE Context
  if ($RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    $_RAD_REPLY{'Service-Type'} = 'Framed';
  }

  if ($RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}) {
    $self->{INFO} = " $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}/$RAD_REQUEST->{'NAS-Port-Id'}";
  }

  #Action for freeradius DHCP
  if ($RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    #print "// $CONF->{MX80_O82_EXPR} //\n\n";
    $user_auth_params = $self->opt82_parse($RAD_REQUEST, { AUTH_EXPR => $CONF->{MX80_O82_EXPR} });

    #print %$user_auth_params;
    #print "\n";

    # If this is DHCP-Discover, we must offer to user ip-address, and if he'll accept it, he will send DHCP-Request to us
    if ($CONF->{MX80_IPOE_SWITCH_PORT}) {
      if($RAD_REQUEST->{'User-Name'} =~ /([a-f0-9]{2})([a-f0-9]{2})\.([a-f0-9]{2})([a-f0-9]{2})\.([a-f0-9]{2})([a-f0-9]{2})/) {
        $user_auth_params->{USER_MAC} = "$1:$2:$3:$4:$5:$6";
      }
      elsif($RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} && $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} =~ /([a-f0-9]{2})([a-f0-9]{2})\.([a-f0-9]{2})([a-f0-9]{2})\.([a-f0-9]{2})([a-f0-9]{2})/) {
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

      #Get user from dhcphosts
      $user_auth_params->{SWITCH_PORT_AUTH} = $CONF->{MX80_IPOE_SWITCH_PORT};
      $self->get_dhcp_info($user_auth_params, $NAS);

      #If exist make static IP
      if ($self->{TOTAL} > 0) {
        $uid                              = $self->{UID};
        $RAD_REQUEST->{'User-Name'}       = $self->{LOGIN};
        $_RAD_REPLY{'Framed-IP-Netmask'}  = $self->{NETMASK};
        # Split by nas
        #$NAS->{NAS_ID}                    = $self->{NAS_ID} if ($self->{NAS_ID} > 0);

        if ($self->{ROUTERS} && $self->{ROUTERS} ne '0.0.0.0') {
          $_RAD_REPLY{'ERX-Dhcp-Options'}=sprintf("0x0304%.2x%.2x%.2x%.2x", split(/\./, $self->{ROUTERS}));
          $_RAD_REPLY{'Session-Timeout'}=$NAS->{NAS_ALIVE};
          #$RAD_REPLY{'ERX-Dhcp-Gi-Address'}=$self->{ROUTERS};
        }

        if($self->{DNS}) {
          $self->{DNS}=~s/ //g;
          my @dns_arr = split(/,/, $self->{DNS});
          push @dns_arr, $self->{DNS2} if ($self->{DNS2});
          $_RAD_REPLY{'ERX-Primary-Dns'}=$dns_arr[0] if ($dns_arr[0]);
          $_RAD_REPLY{'ERX-Secondary-Dns'}=$dns_arr[1] if ($dns_arr[1]);
        }
      }
      #Else add to guest NET
      else {
        if ($CONF->{MX80_DEFAULT_GUEST_PROFILE} || $profiles{USER_NOT_EXIST}) {
          return $self->guest_mode($RAD_REQUEST, $NAS, "USER_NOT_EXIST $self->{INFO}",
            {
              USER_AUTH_PARAMS => $user_auth_params,
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
      $self->get_dhcp_info($user_auth_params, $NAS);
      if ($self->{TOTAL} > 0) {
        $uid                              = $self->{UID};
        $RAD_REQUEST->{'User-Name'}       = $self->{LOGIN};
        $_RAD_REPLY{'Framed-IP-Netmask'}   = $self->{NETMASK} if ($self->{DHCP_STATIC_IP} && $self->{DHCP_STATIC_IP} ne '0.0.0.0');
        # Split by nas
        #$NAS->{NAS_ID}                    = $self->{NAS_ID} if ($self->{NAS_ID} > 0);

        if ($self->{ROUTERS} && $self->{ROUTERS} ne '0.0.0.0') {
          $_RAD_REPLY{'ERX-Dhcp-Options'}=sprintf("0x0304%.2x%.2x%.2x%.2x", split(/\./, $self->{ROUTERS}));
          $_RAD_REPLY{'Session-Timeout'}=$NAS->{NAS_ALIVE};
          #$RAD_REPLY{'ERX-Dhcp-Gi-Address'}=$self->{ROUTERS};
        }

        if($self->{DNS}) {
          $self->{DNS}=~s/ //g;
          my @dns_arr = split(/,/, $self->{DNS});
          push @dns_arr, $self->{DNS2} if ($self->{DNS2});
          $_RAD_REPLY{'ERX-Primary-Dns'}=$dns_arr[0] if ($dns_arr[0]);
          $_RAD_REPLY{'ERX-Secondary-Dns'}=$dns_arr[1] if ($dns_arr[1]);
        }
      }
      #Else add to guest NET
      else {
        #print "// $profiles{USER_NOT_EXIST} || $CONF->{MX80_DEFAULT_GUEST_PROFILE} //\n";
        #if ($conf->{MX80_DEFAULT_GUEST_PROFILE} || $profiles{USER_NOT_EXIST}) {
          return $self->guest_mode($RAD_REQUEST, $NAS,
            "USER_NOT_EXIST $self->{INFO} $user_auth_params->{NAS_MAC}/$user_auth_params->{PORT}",
            { GUEST_MODE_TYPE  => $profiles{USER_NOT_EXIST} || $CONF->{MX80_DEFAULT_GUEST_PROFILE},
              USER_AUTH_PARAMS => $user_auth_params
            }
            #{ GUEST_MODE_TYPE => 'USER_NOT_EXIST' }
          );
        #}
        #else {
        #  $RAD_REPLY{'User-Name'}     = $RAD_REQUEST->{'Mac-Addr'} if ($RAD_REQUEST->{'Mac-Addr'});
        #  $RAD_REPLY{'Reply-Message'} = "Can't find $self->{INFO} $switch_mac/$port";
        #  return 7, \%RAD_REPLY;
        #}
      }
    }
  }

  #Get user info
  $self->user_info($RAD_REQUEST, $NAS, { UID => $uid });
  if ($self->{USER_NAME}) {
    $RAD_REQUEST->{'User-Name'} = $self->{USER_NAME};
  }

  if ($self->{errno}) {
    if ($self->{errno} == 2) {
      return $self->guest_mode($RAD_REQUEST, $NAS, "USER_NOT_EXIST '" . $RAD_REQUEST->{'User-Name'}
          . "' $user_auth_params->{NAS_MAC}/$user_auth_params->{PORT}", { GUEST_MODE_TYPE => 'USER_NOT_EXIST' });
    }
    elsif ($self->{errno} == 3) {
      $_RAD_REPLY{'Reply-Message'}=$self->{errstr}."$self->{INFO}";
      return 1, \%_RAD_REPLY;
    }
    else {
      #print %connect_errors_ids;
      #print "// $self->{errno} / $Auth::connect_errors_ids{$self->{errno}} //\n\n";
      return $self->guest_mode($RAD_REQUEST, $NAS, "$self->{errstr} $self->{INFO}", {
        GUEST_MODE_TYPE => $Auth::connect_errors_ids{$self->{errno}},
        USER_AUTH_PARAMS => $user_auth_params,
      });
    }
  }
  elsif (!defined($self->{PAYMENT_TYPE})) {
    return $self->guest_mode($RAD_REQUEST, $NAS, "NOT_ALLOW_SERVICE", { GUEST_MODE_TYPE => 'NOT_ALLOW_SERVICE' });
  }

  if ($attr->{GET_USER}) {
   return $self;
  }

#  my $service = '';

  #Get balance state
  if ($self->{PAYMENT_TYPE} == 0) {
    $self->{CREDIT} = $self->{TP_CREDIT} if ($self->{CREDIT} == 0);
    $self->{DEPOSIT} = $self->{DEPOSIT} + $self->{CREDIT} - $self->{CREDIT_TRESSHOLD};
    #Check deposit
    if ($self->{DEPOSIT} <= 0 || $self->{DV_DISABLE} == 5) {
      return $self->guest_mode($RAD_REQUEST, $NAS, "NEG_DEPOSIT '$self->{DEPOSIT}'", { GUEST_MODE_TYPE => 'NEG_DEPOSIT' });
    }
  }

  if($self->{DHCP_STATIC_IP} && $self->{DHCP_STATIC_IP} ne '0.0.0.0') {
    $_RAD_REPLY{'Framed-IP-Address'} = $self->{DHCP_STATIC_IP};
    $self->Auth::online_add({ %$attr,
                        NAS_ID            => $NAS->{NAS_ID},
                        FRAMED_IP_ADDRESS => "INET_ATON('$self->{DHCP_STATIC_IP}')",
                        NAS_IP_ADDRESS    => $RAD_REQUEST->{'NAS-IP-Address'},
                        CONNECT_INFO      => $RAD_REQUEST->{'NAS-Port-Id'} || '',
                        CID               => $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}
                      }); 
  }
  #IP
  elsif ($self->{IP} ne '0.0.0.0') {
    $_RAD_REPLY{'Framed-IP-Address'} = $self->{IP};
    $self->Auth::online_add({ %$attr,
                        NAS_ID            => $NAS->{NAS_ID},
                        FRAMED_IP_ADDRESS => "INET_ATON('$self->{IP}')",
                        NAS_IP_ADDRESS    => $RAD_REQUEST->{'NAS-IP-Address'},
                        CONNECT_INFO      => $RAD_REQUEST->{'NAS-Port-Id'} || '',
                        CID               => $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}
                      }); 
  }
  else {
    my $ip = $self->Auth::get_ip($NAS->{NAS_ID}, $RAD_REQUEST->{'NAS-IP-Address'}, { TP_IPPOOL    => $self->{NEG_DEPOSIT_IP_POOL} || $self->{TP_IPPOOL},
                                                                               CONNECT_INFO => $RAD_REQUEST->{'NAS-Port-Id'} || '',
                                                                               CID          => $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}
                                                                             });

    if ($ip eq '-1') {
      $_RAD_REPLY{'Reply-Message'} = "Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS})";
      return 1, \%_RAD_REPLY;
    }
    elsif ($ip eq '0') {
     #my $m = `echo "ADD_CALLS Session  Port: $RAD_REQUEST->{'NAS-Port-Id'} U: $RAD_REQUEST->{'User-Name'}" >> /tmp/mx80`;
      my $sql = "INSERT INTO dv_calls
       (status, user_name, started, nas_ip_address, nas_port_id, framed_ip_address, 
         CID, CONNECT_INFO, nas_id, tp_id, uid, guest, lupdated)
       VALUES
        ('11','" . ($self->{USER_NAME} || $_RAD_REPLY{'User-Name'}) . "', now(),
         INET_ATON('" . $RAD_REQUEST->{'NAS-IP-Address'} . "'),
         '" . $RAD_REQUEST->{'NAS-Port'} . "',
         INET_ATON('" . (($_RAD_REPLY{'Framed-IP-Address'}) ? $_RAD_REPLY{'Framed-IP-Address'} : '0.0.0.0') . "'),
         '" . $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} . "', '" . $RAD_REQUEST->{'NAS-Port-Id'} . "',
         '$NAS->{NAS_ID}',
         '$self->{TP_NUM}',
         '$self->{UID}',
         '$self->{GUEST_MODE}',
         UNIX_TIMESTAMP());";

      $self->query2($sql, 'do');
    }
    else {
      $_RAD_REPLY{'Framed-IP-Address'} = "$ip";
    }
  }

  if ($_RAD_REPLY{'Framed-IP-Address'} && ! $_RAD_REPLY{'Framed-IP-Netmask'}) {
    $_RAD_REPLY{'Framed-IP-Netmask'} = "$self->{NETMASK}" ;
  }

  # SET ACCOUNT expire date
  if ($self->{ACCOUNT_AGE} > 0 && $self->{DV_EXPIRE} eq '0000-00-00') {
    $self->query2("UPDATE dv_main SET expire=curdate() + INTERVAL $self->{ACCOUNT_AGE} day
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
          if ($tp->{out_speed} + $tp->{in_speed} > 0) {
            $speeds{$tp->{net_id}}{OUT} = $tp->{out_speed} * 1024;
            $speeds{$tp->{net_id}}{IN} = $tp->{in_speed} * 1024;
            my $profile_name = ($CONF->{MX80_GLOBAL_PROFILE} && $tp->{traffic_class_id} == 0) ? $CONF->{MX80_GLOBAL_PROFILE} : "$profile_prefix-$traffic_class_name-$profile_sufix";
            my $service_id = $traffic_types_count - $tp->{traffic_class_id};
            #push @{ $RAD_REPLY{'ERX-Service-Activate:'.$tp->{traffic_class_id}} },  "$profile_name("
            $_RAD_REPLY{'ERX-Service-Activate:'.$service_id} = "$profile_name("
              .$speeds{$tp->{net_id}}{OUT}.','
              .$speeds{$tp->{net_id}}{IN}.')';
          }
        }
      }
    }
  }
#  #NAT section
#  if ( $RAD_REPLY{'Framed-IP-Address'} ) {
#    my @nets = (
#      '10.0.0.0/8',
#      '172.16.0.0/12',
#      '192.168.0.0/16',
#      '100.64.0.0/10'
#    );
#    foreach my $ip_range (@nets) {
#      $ip_range =~ /(.+)\/(\d+)/;
#      my $ip_ = $1;
#      my $IP = unpack( "N", pack( "C4", split( /\./, $ip_ ) ) );
#      my $NETMASK =  unpack "N", pack( "B*", ("1" x $2 . "0" x (32 - $2)) );
#      my $client_ip_num = unpack( "N", pack( "C4", split( /\./, $RAD_REPLY{'Framed-IP-Address'}  ) ) );
#      `echo " $ip_ $IP " >> /tmp/x`;
#      if ( ($client_ip_num & $NETMASK) == ($IP & $NETMASK)) {
#        my $nat_profile = ( $RAD_REQUEST->{'Framed-Protocol'} ) ? 'svc-cgn-nat-pppoe' : 'svc-cgn-nat-ipoe';
#        $RAD_REPLY{'ERX-Service-Activate:2'} = $nat_profile;
#      }
#    }
#  }


  if ($self->{TP_RAD_PAIRS}) {
    #$self->add_rad_pairs(\%RAD_REPLY, $self->{TP_RAD_PAIRS});
    Auth::rad_pairs_former($self->{TP_RAD_PAIRS}, { RAD_PAIRS => \%_RAD_REPLY });
  }

  if (length($self->{FILTER}) > 0) {
    #$self->neg_deposit_filter_former_old($RAD_REQUEST, $NAS, $self->{FILTER}, { USER_FILTER => 1, RAD_PAIRS => \%RAD_REPLY });
    $self->neg_deposit_filter_former($RAD_REQUEST, $NAS, $self->{NEG_DEPOSIT_FILTER_ID}, { USER_FILTER => 1, RAD_PAIRS => \%_RAD_REPLY  });
  }

  #Auto assing MAC in first connect
  if ( $CONF->{MAC_AUTO_ASSIGN}
    && $self->{CID} eq '') {
    my $cid = $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'};

    if ($RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} =~ /([0-9a-f]{2})([0-9a-f]{2})\.([0-9a-f]{2})([0-9a-f]{2})\.([0-9a-f]{2})([0-9a-f]{2})/) {
      $cid = "$1:$2:$3:$4:$5:$6";
    }

    $self->query2("UPDATE dv_main SET cid='$cid'
     WHERE uid='$self->{UID}';", 'do');
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
    $RAD_PAIRS->{'Reply-Message'} = "Wrong CID ''";
    return 1, $RAD_PAIRS, "Wrong CID ''";
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

  $RAD_PAIRS->{'Reply-Message'} = "Wrong CID '$calling_station_id'";
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
  $RAD->{'Acct-Input-Gigawords'}  = 0 if (! $RAD->{'Acct-Input-Gigawords'});
  $RAD->{'Acct-Output-Gigawords'} = 0 if (! $RAD->{'Acct-Output-Gigawords'});

  if (length($RAD->{'Acct-Session-Id'}) > 25) {
    $RAD->{'Acct-Session-Id'} = substr($RAD->{'Acct-Session-Id'}, 0, 24);
  }

  #Start
  if ($acct_status_type == 1) {
    $self->query2("UPDATE dv_calls SET
     status=1, 
     started=NOW() - INTERVAL ? SECOND, 
     lupdated=UNIX_TIMESTAMP(), 
     acct_session_id=?,
     framed_ip_address=INET_ATON( ? )
    WHERE 
      nas_id= ?
      AND CID= ?
      AND CONNECT_INFO=?
      AND status>3 LIMIT 1;", 
      'do', 
      { Bind => [
      	$RAD->{'Acct-Session-Time'} || 0,
      	$RAD->{'Acct-Session-Id'},
      	$RAD->{'Framed-IP-Address'} || $RAD->{'Assigned-IP-Address'} || '0.0.0.0',
      	$NAS->{NAS_ID},
      	$RAD->{'ERX-Dhcp-Mac-Addr'},
      	$RAD->{'NAS-Port-Id'}
      ]});
  }

  # Stop status
  elsif ($acct_status_type == 2) {
    #my $Billing = Billing->new($self->{db}, $conf);
    $CONF->{rt_billing}=1;
    if ($CONF->{rt_billing}) {
      $self->rt_billing($RAD, $NAS);

      if (!$self->{errno}) {
        $self->query2("INSERT INTO dv_log SET 
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
          CID= ? , 
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
                    $self->{TARIF_PLAN}, 
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
                    $RAD->{'Acct-Session-Id'},
                    $self->{BILL_ID},
                    $RAD->{'Acct-Terminate-Cause'},
                    $RAD->{'Acct-Input-Gigawords'},
                    $RAD->{'Acct-Output-Gigawords'}
                     ] }
        );

      }
      else {
        #DEbug only
        if ($CONF->{ACCT_DEBUG}) {
          use POSIX qw(strftime);
          my $DATE_TIME = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time));
          `echo "$DATE_TIME $self->{UID} - $RAD->{'User-Name'} / $RAD->{'Acct-Session-Id'} / Time: $RAD->{'Acct-Session-Time'} / $self->{errstr}" >> /tmp/unknown_session.log`;
          #DEbug only end
        }
      }
    }

    # Delete from session
    $self->query2("DELETE FROM dv_calls WHERE 
      (acct_session_id= ? OR (CONNECT_INFO= ? AND status=11)) 
      and nas_id= ? ;", 'do', { 
      	  Bind =>  [ $RAD->{'Acct-Session-Id'},
      	             $RAD->{'NAS-Port-Id'},
      	             $NAS->{NAS_ID}
      	               ] });
  }

  #Alive status 3
  elsif ($acct_status_type eq 3) {
    $self->{SUM} = 0 if (!$self->{SUM});
    if ($NAS->{NAS_EXT_ACCT}) {
      my $ipn_fields = '';
      if ($NAS->{IPN_COLLECTOR}) {
        $ipn_fields = "sum=sum+$self->{SUM},
      acct_input_octets='$RAD->{INBYTE}',
      acct_output_octets='$RAD->{OUTBYTE}',
      ex_input_octets=ex_input_octets + $RAD->{INBYTE2},
      ex_output_octets=ex_output_octets + $RAD->{OUTBYTE2},
      acct_input_gigawords='". $RAD->{'Acct-Input-Gigawords'} ."',
      acct_output_gigawords='". $RAD->{'Acct-Output-Gigawords'} ."',";
      }

      $self->query2("UPDATE dv_calls SET
      $ipn_fields
      status='$acct_status_type',
      acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
      lupdated=UNIX_TIMESTAMP()
    WHERE
      acct_session_id='" . $RAD->{'Acct-Session-Id'} . "' 
      AND nas_id='$NAS->{NAS_ID}';", 'do'
      );
      return $self;
    }

    $self->rt_billing($RAD, $NAS);

    # Can't find online records
    if ($self->{errno} && $self->{errno}  == 2) {

     #Lost session debug
     my $info_rr = '';
     while(my($k,$v) = each %$RAD) {
      $info_rr .= "$k, $v\n";
     }

     `echo "Lost session  //$RAD->{'User-Name'}//\n $info_rr" >> /tmp/lost_session`;
     #=== Lost session debug

     if (!$RAD->{'Framed-Protocol'} || $RAD->{'Framed-Protocol'} ne 'PPP') {
       $self->auth($RAD, $NAS, { GET_USER => 1, 
                                 #RAD_REQUEST => $RAD_REQUEST 
                                });

       $RAD->{'User-Name'}=$self->{LOGIN};
     }
     else {
       $self->query2("SELECT u.uid, dv.tp_id, dv.join_service 
          FROM users u
          INNER JOIN dv_main dv ON (u.uid=dv.uid)
          WHERE u.id= ? ;", 
          undef,
         { INFO  => 1, Bind => [ $RAD->{'User-Name'} ] });
     }

     $self->query2("REPLACE INTO dv_calls SET
            status= ? , 
            user_name= ? , 
            started=NOW() - INTERVAL ? SECOND, 
            lupdated=UNIX_TIMESTAMP(), 
            nas_ip_address=INET_ATON( ? ), 
            nas_port_id= ? , 
            acct_session_id= ? , 
            framed_ip_address=INET_ATON( ? ), 
            CID= ? , 
            CONNECT_INFO= ? ,
            acct_input_octets= ? ,
            acct_output_octets= ? ,
            acct_input_gigawords= ? ,
            acct_output_gigawords= ? ,
            nas_id= ? , 
            tp_id= ? ,
            uid= ? , 
            join_service = ? ;", 
          'do', 
          { Bind => [
           '9',
           $RAD->{'User-Name'} || '',
           $RAD->{'Acct-Session-Time'} || 0,
           $RAD->{'NAS-IP-Address'},
           $RAD->{'NAS-Port'} || 0,
           $RAD->{'Acct-Session-Id'},
           $RAD->{'Framed-IP-Address'} || '0.0.0.0',
           $RAD->{'ERX-Dhcp-Mac-Addr'} || $RAD->{'Calling-Station-Id'} || '',
           $RAD->{'NAS-Port-Id'} || $RAD->{'Connect-Info'},
           $RAD->{'INBYTE'},
           $RAD->{'OUTBYTE'},
           $RAD->{'Acct-Input-Gigawords'},
           $RAD->{'Acct-Output-Gigawords'},
           $NAS->{NAS_ID},
           $self->{TP_NUM} || 0, 
           $self->{UID} || 0,
           $self->{JOIN_SERVICE} || 0
           ]});
      return $self;
    }
    else {
      my $ex_octets = '';
      if ($RAD->{INBYTE2} || $RAD->{OUTBYTE2}) {
        $ex_octets = "ex_input_octets='$RAD->{INBYTE2}',  ex_output_octets='$RAD->{OUTBYTE2}', ";
      }

      $self->query2("UPDATE dv_calls SET
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
      and nas_id= ? ;", 
      'do',
      { Bind => [
      	 $acct_status_type,
      	 $RAD->{INBYTE},
      	 $RAD->{OUTBYTE},
      	 $self->{SUM},
      	 $RAD->{'Framed-IP-Address'} || $RAD->{'Assigned-IP-Address'},
      	 $RAD->{'Acct-Input-Gigawords'},
      	 $RAD->{'Acct-Output-Gigawords'},
      	 $RAD->{'Acct-Session-Id'},
      	 $NAS->{NAS_ID}
      	] });
    }
  }
  else {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [".$RAD->{'User-Name'}."] Unknown accounting status: "> $RAD->{'Acct-Status-Type'} ." (". $RAD->{'Acct-Session-Id'} .")";
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
         $RAD->{'Acct-Session-Id'},
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
# Alive accounting
#**********************************************************
sub rt_billing {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  if (! $RAD->{'Acct-Session-Id'}) {
    $self->{errno}  = 2;
    $self->{errstr} = "Session account rt Not Exist '$RAD->{'Acct-Session-Id'}'";
    return $self;
  }

  $self->query2("SELECT lupdated, UNIX_TIMESTAMP()-lupdated,
   if($RAD->{INBYTE}   >= acct_input_octets AND ". $RAD->{'Acct-Input-Gigawords'} ."=acct_input_gigawords,
        $RAD->{INBYTE} - acct_input_octets,
        if(". $RAD->{'Acct-Input-Gigawords'} ." - acct_input_gigawords > 0, 4294967296 * (". $RAD->{'Acct-Input-Gigawords'} ." - acct_input_gigawords) - acct_input_octets + $RAD->{INBYTE}, 0)),
   if($RAD->{OUTBYTE}  >= acct_output_octets AND ". $RAD->{'Acct-Output-Gigawords'} ."=acct_output_gigawords,
        $RAD->{OUTBYTE} - acct_output_octets,
        if(". $RAD->{'Acct-Output-Gigawords'} ." - acct_output_gigawords > 0, 4294967296 * (". $RAD->{'Acct-Output-Gigawords'} ." - acct_output_gigawords) - acct_output_octets + $RAD->{OUTBYTE}, 0)),
   if($RAD->{INBYTE2}  >= ex_input_octets, $RAD->{INBYTE2}  - ex_input_octets, ex_input_octets),
   if($RAD->{OUTBYTE2} >= ex_output_octets, $RAD->{OUTBYTE2} - ex_output_octets, ex_output_octets),
   sum,
   tp_id,
   uid
   FROM dv_calls
  WHERE nas_id='$NAS->{NAS_ID}' and acct_session_id='". $RAD->{'Acct-Session-Id'} ."';");

  if ($self->{errno}) {
    return $self;
  }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = "Session account rt Not Exist '$RAD->{'Acct-Session-Id'}'";
    return $self;
  }

  ($RAD->{INTERIUM_SESSION_START},
  $RAD->{INTERIUM_ACCT_SESSION_TIME},
  $RAD->{INTERIUM_INBYTE},
  $RAD->{INTERIUM_OUTBYTE},
  $RAD->{INTERIUM_INBYTE1},
  $RAD->{INTERIUM_OUTBYTE1},
  $self->{CALLS_SUM},
  $self->{TP_NUM},
  $self->{UID}) = @{ $self->{list}->[0] };

  my $out_byte = $RAD->{OUTBYTE} + $RAD->{'Acct-Output-Gigawords'} * 4294967296;
  my $in_byte  = $RAD->{INBYTE} + $RAD->{'Acct-Input-Gigawords'} * 4294967296;

  ($self->{UID}, 
  $self->{SUM}, 
  $self->{BILL_ID}, 
  $self->{TARIF_PLAN}, 
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
      TP_NUM     => $self->{TP_NUM},
      UID        => ($self->{TP_NUM}) ? $self->{UID} : undef,
      DOMAIN_ID  => ($NAS->{DOMAIN_ID}) ? $NAS->{DOMAIN_ID} : 0,
    }
  );

  $self->query2("SELECT traffic_type FROM dv_log_intervals 
     WHERE acct_session_id= ?
           AND interval_id= ?
           AND uid= ? ;",
     undef,
     { Bind => [ $RAD->{'Acct-Session-Id'}, $Billing->{TI_ID}, $self->{UID}  ] }
  );

  my %intrval_traffic = ();
  foreach my $line (@{ $self->{list} }) {
    $intrval_traffic{ $line->[0] } = 1;
  }

  my @RAD_TRAFF_SUFIX = ('', '1');
  $self->{SUM} = 0 if ($self->{SUM} < 0);

  for (my $traffic_type = 0 ; $traffic_type <= $#RAD_TRAFF_SUFIX ; $traffic_type++) {
    next if ($RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } + $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } < 1);

    if ($intrval_traffic{$traffic_type}) {
      $self->query2("UPDATE dv_log_intervals SET
                sent=sent+ ? , 
                recv=recv+ ? , 
                duration=duration + ?, 
                sum=sum + ?
              WHERE interval_id= ?
                AND acct_session_id= ?
                AND traffic_type= ?
                AND uid= ? ;", 'do',
       { Bind => [ $RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] },
                   $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] },
                   $RAD->{'INTERIUM_ACCT_SESSION_TIME'},
                   $self->{SUM},
                   $Billing->{TI_ID},
                   $RAD->{'Acct-Session-Id'},
                   $traffic_type,
                   $self->{UID}
                     ] }
      );
    }
    else {
      $self->query2("INSERT INTO dv_log_intervals (interval_id, sent, recv, duration, traffic_type, sum, acct_session_id, uid, added)
        VALUES ( ? , ? , ? , ? , ? , ? , ? , ?, now());", 'do',
        { Bind => [ 
           $Billing->{TI_ID}, 
           $RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] }, 
           $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] }, 
           $RAD->{INTERIUM_ACCT_SESSION_TIME}, 
           $traffic_type, 
           $self->{SUM}, 
           $RAD->{'Acct-Session-Id'}, 
           $self->{UID}
          ] });
    }
  }

  #  return $self;
  if ($self->{UID} == -2) {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{'User-Name'}] Not exist";
  }
  elsif ($self->{UID} == -3) {
    my $filename = "$RAD->{'User-Name'}.$RAD->{'Acct-Session-Id'}";
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{'User-Name'}] Not allow start period '$filename'";
    $Billing->mk_session_log($RAD);
  }
  elsif ($self->{UID} == -5) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{'User-Name'}] Can't find TP: $self->{TP_NUM} Session id: $RAD->{'Acct-Session-Id'}";
    $self->{errno}     = 1;
    print "ACCT [$RAD->{'User-Name'}] Can't find TP: $self->{TP_NUM} Session id: $RAD->{'Acct-Session-Id'}\n";
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
      $self->query2("UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id= ? ;", 'do', { Bind => [ $self->{BILL_ID} ]});
    }
  }
}


#**********************************************************
=head2 get_dhcp_info($attr, $NAS)

=cut
#**********************************************************
sub get_dhcp_info {
  my $self = shift;
  my ($attr, $NAS) = @_;

  my @WHERE_RULES = ();

  # Do nothing if port is magistral, i.e. 25.26.27.28
  # Apply only for reserv ports
  if ($attr->{PORT} && $NAS->{RAD_PAIRS} && $NAS->{RAD_PAIRS} =~ /Assign-Ports=\"(.+)\"/) {
    my @allow_ports = split(/,/, $1);
    if (! in_array($attr->{PORT}, \@allow_ports)) {
      $self->{error}=7;
      $self->{error_str}="WRONG_PORT '$attr->{PORT}'";
      return $self;
    }
  }

  if($attr->{SERVER_VLAN}) {
    push @WHERE_RULES, "dh.vid='$attr->{VLAN}' AND dh.server_vid='$attr->{SERVER_VLAN}'";
    #push @WHERE_RULES, "(dh.mac='$attr->{USER_MAC}' OR dh.mac='00:00:00:00:00:00')";
    $self->{INFO} = "q2q: $attr->{SERVER_VLAN}-$attr->{VLAN} MAC: $attr->{USER_MAC}";
  }
  elsif ($CONF->{DHCPHOSTS_AUTH_PARAMS}) {
    push @WHERE_RULES, "((n.mac='$attr->{NAS_MAC}' OR n.mac IS null)
      AND (dh.mac='$attr->{USER_MAC}' OR dh.mac='00:00:00:00:00:00')
      AND (dh.vid='$attr->{VLAN}' OR dh.vid='')
      AND (dh.ports='$attr->{PORT}' OR dh.ports=''))";
    $self->{INFO} = "NAS_MAC: $attr->{NAS_MAC} PORT: $attr->{PORT} VLAN: $attr->{VLAN} MAC: $attr->{USER_MAC}";
  }
  elsif ($attr->{SWITCH_PORT_AUTH}) {
    push @WHERE_RULES, "n.mac='$attr->{NAS_MAC}' AND dh.ports='$attr->{PORT}'";
    $self->{INFO} = "NAS_MAC: $attr->{NAS_MAC} PORT: $attr->{PORT} VLAN: $attr->{VLAN} MAC: $attr->{USER_MAC}";
  }
  elsif ($attr->{USER_MAC}) {
    push @WHERE_RULES, "dh.mac='$attr->{USER_MAC}'";
    $self->{INFO} = "USER MAC '$attr->{USER_MAC}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT u.uid, 
        INET_NTOA(dh.ip) AS dhcp_static_ip, 
        u.id AS login, 
        n.id AS nas_id, 
        INET_NTOA(dh_nets.mask) AS netmask, 
        INET_NTOA(dh_nets.routers) AS routers, 
        dh_nets.dns, 
        dh_nets.dns2, 
        dh_nets.suffix, 
        dh_nets.ntp,
        dh.mac
   FROM dhcphosts_hosts dh
   INNER JOIN users u ON (u.uid=dh.uid) 
   INNER JOIN dhcphosts_networks dh_nets ON (dh.network=dh_nets.id)
   LEFT JOIN nas n ON (dh.nas=n.id)
   WHERE $WHERE;",
  undef,
  { COLS_NAME => 1,
    COLS_UPPER=> 1 
  } 
      );

  if ($self->{TOTAL} < 1) {
    $self->{error}    = 2;
    $self->{error_str}= 'USER_NOT_EXIST '.$self->{INFO};
  }
  elsif ($self->{TOTAL} > 1) {
    my $i = 0;
    foreach my $host (@{ $self->{list} }) {
     if ($attr->{USER_MAC} && uc($attr->{USER_MAC}) eq uc($host->{MAC})) {
        foreach my $p ( keys %{ $self->{list}->[$i] }) {
         $self->{$p} = $self->{list}->[$i]->{$p};
       }
       return $self;
     }
     $i++
    }

    $self->{error}    = 2;
    $self->{error_str}= 'USER_NOT_EXIST '.$self->{INFO};
    $self->{TOTAL}    = 0;
  }
  elsif($self->{TOTAL}==1) {
    foreach my $p ( keys %{ $self->{list}->[0] }) {
      $self->{$p} = $self->{list}->[0]->{$p};
    }
  }

  return $self;
}


##**********************************************************
#=head2 parse_opt82($RAD_REQUEST)
#
## http://tools.ietf.org/html/rfc4243
## http://tools.ietf.org/html/rfc3046#section-7
#
#=cut
##**********************************************************
#sub parse_opt82 {
#  my ($RAD_REQUEST) = @_;
#
#  #my ($switch_mac, $port, $vlan);
#  my %result      =  ();
#
#  if ($#o82_expr_arr > -1) {
#    my $expr_debug  =  "";
#    foreach my $expr (@o82_expr_arr) {
#      my ($parse_param, $expr_, $values, $attribute)=split(/:/, $expr);
#      my @EXPR_IDS = split(/,/, $values);
#
#      if ($RAD_REQUEST->{$parse_param}) {
#        my $input_value = $RAD_REQUEST->{$parse_param};
#        if ($attribute && $attribute eq 'hex2ansii') {
#          $input_value =~ s/^0x//;
#          $input_value = pack 'H*', $input_value;
#        }
#
#        $expr_debug  .=  "$RAD_REQUEST->{$parse_param}: $parse_param, $expr_, $RAD_REQUEST->{$parse_param}/$input_value\n";
#
#        if (my @res = ("$input_value" =~ /$expr_/)) {
#          for (my $i=0; $i <= $#res ; $i++) {
#            $expr_debug .= "$EXPR_IDS[$i] / $res[$i]\n" if ($conf->{DHCP_FREERADIUS_DEBUG});
#            $result{$EXPR_IDS[$i]}=$res[$i];
#          }
#          #last;
#        }
#      }
#
#      if ($parse_param eq 'DHCP-Relay-Agent-Information') {
#        $result{AGENT_REMOTE_ID} = substr($RAD_REQUEST->{$parse_param},0,25);
#        $result{CIRCUIT_ID} = substr($RAD_REQUEST->{$parse_param},25,25);
#      }
#      else {
#        $result{AGENT_REMOTE_ID}='-';
#        $result{CIRCUIT_ID}='-';
#      }
#    }
#
#    if ($result{MAC} && $result{MAC} =~ /([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})/) {
#      $result{MAC} = "$1:$2:$3:$4:$5:$6";
#    }
#
#    if ($conf->{DHCP_FREERADIUS_DEBUG} && $conf->{DHCP_FREERADIUS_DEBUG} > 2) {
#       `echo "$expr_debug" >> /tmp/dhcphosts_expr`;
#       if ($conf->{DHCP_FREERADIUS_DEBUG} > 3) {
#         print $expr_debug."-- \n";
#       }
#    }
#  }
#  # FreeRadius DHCP default
#  elsif($RAD_REQUEST->{'DHCP-Relay-Agent-Information'}) {
#    my @relayid = unpack('a10 a4 a2 a2 a4 a16 (a2)*', $RAD_REQUEST->{'DHCP-Relay-Agent-Information'});
#    $result{VLAN}            = $relayid[1];
#    $result{PORT}            = $relayid[3];
#    $result{MAC}             = $relayid[5];
#    $result{AGENT_REMOTE_ID} = substr($RAD_REQUEST->{'DHCP-Relay-Agent-Information'},0,25);
#    $result{CIRCUIT_ID}      = substr($RAD_REQUEST->{'DHCP-Relay-Agent-Information'},25,25);
#  }
#  #Default o82 params
#  else {
#    $result{MAC} = $RAD_REQUEST->{'ADSL-Agent-Remote-Id'} || '';
#    #  Switch MAC
#    if (length($result{MAC}) == 16) {
#      $result{MAC} .= '00';
#    }
#    if ($result{MAC} =~ /0x[a-f0-9]{0,20}([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})/) {
#      $result{MAC} = "$1:$2:$3:$4:$5:$6";
#    }
#
#    #  Switch port
#    if ($RAD_REQUEST->{'ADSL-Agent-Circuit-Id'}) {
#      if($RAD_REQUEST->{'ADSL-Agent-Circuit-Id'} =~ /0x0006(\S{4})\d{6}([a-f0-9]{2})/i) {
#        $result{VLAN} = $1;
#        $result{PORT} = $2;
#      }
#      elsif($RAD_REQUEST->{'ADSL-Agent-Circuit-Id'} =~ /0x0004([a-f0-9]{4})[0-9a-f]{2}([a-f0-9]{2})/i) {
#        $result{VLAN} = $1;
#        $result{PORT} = $2;
#      }
#    }
#  }
#
#  $result{VLAN} = $result{VLAN_DEC} || hex($result{VLAN} || 0);
#  $result{PORT} = $result{PORT_DEC} || hex($result{PORT} || 0);
#
#  return $result{MAC}, $result{PORT}, $result{VLAN}, $result{AGENT_REMOTE_ID}, $result{CIRCUIT_ID};
#}


#**********************************************************
#
#**********************************************************
#sub neg_deposit_filter_former_old {
#  my $self = shift;
#  my ($RAD, $NAS, $NEG_DEPOSIT_FILTER_ID, $attr) = @_;
#
#  my $RAD_PAIRS;
#
#  if ($attr->{RAD_PAIRS}) {
#    $RAD_PAIRS = $attr->{RAD_PAIRS};
#  }
##  else {
##    undef $RAD_PAIRS;
##  }
#
#  $RAD_PAIRS->{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE} if ($NAS->{NAS_ALIVE});
#
#  if (!$attr->{USER_FILTER}) {
#    # Return radius attr
#    if ($self->{IP} ne '0' && !$self->{NEG_DEPOSIT_IP_POOL}) {
#      $RAD_PAIRS->{'Framed-IP-Address'} = "$self->{IP}";
#
#      $self->online_add({ %$attr,
#                          NAS_ID            => $NAS->{NAS_ID},
#                          FRAMED_IP_ADDRESS => "INET_ATON('$self->{IP}')",
#                          NAS_IP_ADDRESS    => $RAD->{'NAS-IP-Address'},
#                          GUEST             => 1
#                        });
#    }
#    else {
#      my $ip = $self->get_ip($NAS->{NAS_ID}, $RAD->{'NAS-IP-Address'}, { TP_IPPOOL => $self->{NEG_DEPOSIT_IP_POOL} || $self->{TP_IPPOOL}, GUEST => 1 });
#      if ($ip eq '-1') {
#        $RAD_PAIRS->{'Reply-Message'} = "Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS}) " . (($self->{TP_IPPOOL}) ? " TP_IPPOOL: $self->{TP_IPPOOL}" : '');
#        return 1, $RAD_PAIRS;
#      }
#      elsif ($ip eq '0') {
#        #$RAD_PAIRS->{'Reply-Message'}="$self->{errstr} ($NAS->{NAS_ID})";
#        #return 1, $RAD_PAIRS;
#        $self->online_add({ %$attr,
#                          NAS_ID            => $NAS->{NAS_ID},
#                          FRAMED_IP_ADDRESS => "INET_ATON('$self->{IP}')",
#                          NAS_IP_ADDRESS    => $RAD->{'NAS-IP-Address'},
#                          GUEST             => 1
#                         });
#      }
#      else {
#        $RAD_PAIRS->{'Framed-IP-Address'} = "$ip";
#      }
#    }
#  }
#
#  $NEG_DEPOSIT_FILTER_ID =~ s/{IP}/$RAD_PAIRS->{'Framed-IP-Address'}/g;
#  $NEG_DEPOSIT_FILTER_ID =~ s/{LOGIN}/$RAD->{'USER_NAME'}/g;
#  $self->{INFO} .= " Neg filter";
#  if ($NEG_DEPOSIT_FILTER_ID =~ /RAD:(.+)/) {
#    my $rad_pairs = $1;
#    rad_pairs_former2("$rad_pairs", $attr);
#  }
#  else {
#    $RAD_REPLY{'Filter-Id'} = "$NEG_DEPOSIT_FILTER_ID";
#  }
#
#  $self->{GUEST_MODE}=1 if (! $attr->{USER_FILTER});
#
#  if ($attr->{USER_FILTER}) {
#    return 0;
#  }
#
#  return 0, $RAD_PAIRS;
#}
#
#
##**********************************************************
##
##**********************************************************
#sub rad_pairs_former2 {
#  my ($content, $attr) = @_;
#
#  $content =~ s/\r|\n//g;
#  my @p = split(/,/, $content);
#
#  my $RAD_PAIRS;
#
#  if ($attr->{RAD_PAIRS}) {
#    $RAD_PAIRS = $attr->{RAD_PAIRS};
#  }
#
#  foreach my $line (@p) {
#    if ($line =~ /([a-zA-Z0-9\-\:]{6,25})\s?\+\=\s?(.{1,200})/) {
#      my $left  = $1;
#      my $right = $2;
#      #$right =~ s/\"//g;
#      push(@{ $RAD_REPLY{"$left"} }, $right);
#    }
#    else {
#      my ($left, $right) = split(/=/, $line, 2);
#      $left=~s/^ //g;
#      if ($left =~ s/^!//) {
#        delete $RAD_REPLY{"$left"};
#      }
#      else {
#        $right = '' if (!$right);
#        $RAD_REPLY{"$left"} = "$right";
#      }
#    }
#  }
#}


=head1 AUTHOR


  Fima
  ABIllS Team (https://billing.axiostv.ru/)
  2017

=cut



1

