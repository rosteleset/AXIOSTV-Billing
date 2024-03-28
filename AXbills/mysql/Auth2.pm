package Auth2 v7.10.0;

=head1 NAME

  Auth functions

=cut

use strict;
use parent qw(main Exporter);

our @EXPORT  = qw(
  check_chap
  check_company_account
  rad_pairs_former
  ex_traffic_params
  ipv6_2_long
);

our @EXPORT_OK = qw(
  check_chap
  check_company_account
  rad_pairs_former
  ex_traffic_params
  ipv6_2_long
);

use AXbills::Base qw(in_array);
use Billing;
my $Billing;
my $CONF;
my $debug = 0;

our %connect_errors_ids = (
  1 => 'WRONG_PASS',
  2 => 'USER_NOT_EXIST',
  3 => 'AUTH_ERROR',
  4 => 'NEG_DEPOSIT',
  5 => 'NOT_ALLOW_SERVICE',
  6 => 'DISABLE',
  7 => 'WRONG_PORT',
  8 => 'WRONG_CID',
  9 => 'TRAFFIC_EXPIRED',
  10=> 'TIME_EXPIRED',
  11=> 'NOT_ALLOW_TIME',
  12=> 'WRONG_IP', # WRONG_REQUEST_IP
  13=> 'SERVICE_DISABLE',
  14=> 'ACCOUNT_DISABLE'
);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($CONF)   = @_;

  my $self = {};
  bless($self, $class);

  if (!defined($CONF->{KBYTE_SIZE})) {
    $CONF->{KBYTE_SIZE} = 1024;
  }

  $self->{db} = $db;
  $self->{conf} = $CONF;
  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
  $Billing = Billing->new($db, $CONF);

  return $self;
}

#**********************************************************
=head auth($RAD, $NAS, $attr) - VPN / IPoE / Dialup auth

  Arguments:
    $RAD_HASH_REF  - RADIUS PAIRS
    $NAS_HASH_REF  - NAS information object
    $attr          - Extra attributes

  Returns:

=cut
#**********************************************************
sub auth {
  my $self = shift;
  my ($RAD, $NAS, $attr) = @_;

  my ($ret, $RAD_PAIRS);
  if ($NAS->{NAS_TYPE} eq 'accel_ipoe') {
    ($ret, $RAD_PAIRS) = $self->internet_auth($RAD, $NAS, $attr);

    if($ret == 2) {
      $self->{USER_NAME}=$RAD->{'User-Name'};

      return $self->neg_deposit_filter_former($RAD, $NAS, 'IPOE_LOGIN_NOT_EXIST',
        {
          RAD_PAIRS   => $RAD,
          FILTER_TYPE => 'IPOE_LOGIN_NOT_EXIST',
          MESSAGE     => "IPOE_LOGIN_NOT_EXIST ", #. $self->{INFO}
          VLAN        => $self->{VLAN},
          PORT        => $self->{PORT},
          NAS_MAC     => $self->{NAS_MAC}
        });
    }
  }
  else {
    ($ret, $RAD_PAIRS) = $self->authentication($RAD, $NAS, $attr);
  }

  if ($ret == 1) {
    return 1, $RAD_PAIRS;
  }

  if(! $NAS->{NAS_ID}) {
  	`echo "$NAS->{NAS_ID} / $RAD->{'NAS-IP-Address'} / $RAD->{'User-Name'}" >> /tmp/nas_error`;
  }

  my $cid = $RAD->{'Calling-Station-Id'} || q{};
  my $ipv6 = q{};

  if($CONF->{IPV6}) {
    $ipv6 = ", INET6_NTOA(internet.ipv6) AS ipv6, INET6_NTOA(internet.ipv6_prefix) AS ipv6_prefix,
    internet.ipv6_mask, internet.ipv6_prefix_mask";
  }

  my $WHERE = "internet.uid='$self->{UID}'
       AND cid IN ('$cid', '', 'ANY', 'any')";

  if($self->{SERVICE_ID}) {
    $WHERE = "internet.id='$self->{SERVICE_ID}'";
  }

  $self->query2("SELECT
  IF(internet.logins=0, IF(tp.logins IS NULL, 0, tp.logins), internet.logins) AS logins,
  IF(internet.filter_id != '', internet.filter_id, IF(tp.filter_id IS NULL, '', tp.filter_id)) AS filter,
  tp.total_time_limit,
  tp.day_time_limit,
  tp.week_time_limit,
  tp.month_time_limit,
  UNIX_TIMESTAMP(DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01')) - UNIX_TIMESTAMP() AS time_limit,

  tp.total_traf_limit,
  tp.day_traf_limit,
  tp.week_traf_limit,
  tp.month_traf_limit,
  tp.octets_direction,

  IF (COUNT(un.uid) + COUNT(tp_nas.tp_id) = 0, 0,
    IF (COUNT(un.uid)>0, 1, 2)) AS nas,

  UNIX_TIMESTAMP() AS session_start,
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_week,
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year,
  tp.max_session_duration,
  tp.payment_type,
  tp.credit_tresshold,
  tp.rad_pairs AS tp_rad_pairs,
  COUNT(i.id) AS intervals,
  tp.age AS account_age,
  tp.traffic_transfer_period,
  tp.neg_deposit_filter_id,
  tp.ext_bill_account,
  tp.credit AS tp_credit,
  tp.ippool AS tp_ippool,
  tp.tp_id,
  tp.active_day_fee,
  tp.neg_deposit_ippool,
  internet.activate,
  IF(internet.ip>0, INET_NTOA(internet.ip), 0) AS ip,
  internet.disable AS internet_disable,
  internet.id AS service_id,
  internet.cid,
  internet.speed AS user_speed,
  internet.port,
  UNIX_TIMESTAMP(internet.expire) AS internet_expire
  $ipv6
     FROM internet_main internet
     LEFT JOIN tarif_plans tp ON (internet.tp_id=tp.tp_id)
     LEFT JOIN users_nas un ON (un.uid = internet.uid)
     LEFT JOIN tp_nas ON (tp_nas.tp_id = tp.tp_id)
     LEFT JOIN intervals i ON (tp.tp_id = i.tp_id)
     WHERE $WHERE
       AND (internet.expire='0000-00-00' OR internet.expire > CURDATE())
     GROUP BY internet.uid;",
  undef,
  { INFO => 1 }
  );

  if ($self->{errno}) {
    if($self->{errno} == 2) {
      $RAD_PAIRS->{'Reply-Message'} = 'NOT_ALLOW_SERVICE_EXPIRE';
    }
    else {
      $RAD_PAIRS->{'Reply-Message'} = 'SQL_ERROR';
    }
    return 1, $RAD_PAIRS;
  }

  $self->{USER_NAME}=$RAD->{'User-Name'};

  if ($attr->{GET_USER}) {
    return $self;
  }

  #DIsable
  if ($self->{INTERNET_DISABLE}) {
    #Change status from not active to active
    if ($self->{INTERNET_DISABLE} == 2 && ! $CONF->{INTERNET_DISABLE_AUTO_ACTIVATE}) {
      my $params = '';
      if ($CONF->{INTERNET_USER_ACTIVATE_DATE}) {
        $params = ',activate=NOW()';
      }

      $self->query2("UPDATE internet_main SET disable=0 $params WHERE uid='$self->{UID}' AND disable>0;", 'do');

      $self->query2("INSERT INTO admin_actions SET
        AID         = 2,
        IP          = INET_ATON('127.0.0.5'),
        DATETIME    = NOW(),
        ACTIONS     = '2->0',
        UID         = '$self->{UID}',
        MODULE      = 'Internet',
        ACTION_TYPE = 8;",
      'do');
    }
    else {
      return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID},
      {
        RAD_PAIRS   => $RAD_PAIRS,
        FILTER_TYPE => 'SERVICE_DISABLE',
        MESSAGE     => "SERVICE_DISABLED: $self->{INTERNET_DISABLE}"
      });
    }
  }
#  elsif (!$self->{JOIN_SERVICE} && $self->{TP_NUM} < 1) {
#    $RAD_PAIRS->{'Reply-Message'} = "No Tarif Selected";
#    return 1, $RAD_PAIRS;
#  }
  elsif (!defined($self->{PAYMENT_TYPE})) {
    $RAD_PAIRS->{'Reply-Message'} = "SERVICE_NOT_ALLOW";
    return 1, $RAD_PAIRS;
  }

  #Check allow nas server
  # $nas 1 - See user nas
  #      2 - See tp nas
  if ($self->{NAS} > 0) {
    my $sql;
    if ($self->{NAS} == 1) {
      $sql = "SELECT un.uid FROM users_nas un WHERE un.uid='$self->{UID}' and un.nas_id='$NAS->{NAS_ID}'";
    }
    else {
      $sql = "SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TP_ID}' and nas_id='$NAS->{NAS_ID}'";
    }

    $self->query2($sql);
    if ($self->{TOTAL} < 1) {
      $RAD_PAIRS->{'Reply-Message'} = "NOT_ALLOW_NAS: $NAS->{NAS_ID} (". $RAD->{'NAS-IP-Address'} .")";
      return 1, $RAD_PAIRS;
    }
  }

  my $pppoe_pluse = '';
  my $ignore_cid  = 0;

  if ($CONF->{INTERNET_PPPOE_PLUSE_PARAM}) {
    my $pppo_pluse_param = $CONF->{INTERNET_PPPOE_PLUSE_PARAM};

  	if($RAD->{$pppo_pluse_param}) {
      $pppoe_pluse = $RAD->{$pppo_pluse_param};

      if ($self->{PORT} && $self->{PORT} !~ /any/i) {
        $ignore_cid  = 1;
      }
      elsif (! $self->{PORT}) {
        $self->query2("UPDATE internet_main SET port='$pppoe_pluse' WHERE uid='$self->{UID}';", 'do');
        $self->{PORT}=$pppoe_pluse;
      }
    }
    else {
      $pppoe_pluse = $RAD->{'NAS-Port'} || '';
    }
  }

  #Check port
  if ($pppoe_pluse && $self->{PORT} && $self->{PORT} !~ m/any/i && $self->{PORT} ne $pppoe_pluse) {
    $RAD_PAIRS->{'Reply-Message'} = "WRONG_PORT '$pppoe_pluse'";
    return 1, $RAD_PAIRS;
  }

  #Check CID (MAC)
  if ($self->{CID} ne '' && $self->{CID} !~ /ANY/i) {
    if ($NAS->{NAS_TYPE} eq 'cisco' && !$cid || $CONF->{INTERNET_CID_SKIP}) {
    }
    elsif (! $ignore_cid) {
      my ($ret_, $ERR_RAD_PAIRS_) = $self->auth_cid($RAD);
      return $ret_, $ERR_RAD_PAIRS_ if ($ret == 1);
    }
  }

  #Check  simultaneously logins if needs
  if ($self->{LOGINS} > 0) {
    # SELECT cid, INET_NTOA(framed_ip_address) AS ip, nas_id, status FROM internet_online WHERE user_name= ? AND (status <> 2)
    $self->query2("SELECT cid, INET_NTOA(framed_ip_address) AS ip, nas_id, status FROM internet_online
    WHERE user_name= ? AND (status <> 2) AND guest=0;", undef, { Bind => [ $RAD->{'User-Name'} ] });

    my ($active_logins)  = $self->{TOTAL};
    if (length($cid) > 20) {
      $cid = substr($cid, 0, 20);
    }

    if (! $CONF->{hard_simultaneously_control}) {
      foreach my $line (@{ $self->{list} }) {
        # If exist reserv add get it
        if ($line->[3] == 11 && $line->[2] eq $NAS->{NAS_ID}) {
          $self->{IP}       = $line->[1];
          $self->{REASSIGN} = 1;
          $active_logins--;
        }
        # Zap session with same CID
        elsif ( $line->[0] ne ''
          && ($line->[0] eq $cid && ($line->[2] eq $NAS->{NAS_ID} || $CONF->{hard_simultaneously_control_skip_nas}) )
          #&& $NAS->{NAS_TYPE} ne 'ipcad'
          )
        {
          $self->query2("UPDATE internet_online SET status=6 WHERE user_name= ? AND cid= ? AND status <> 2;",
           'do',
          { Bind => [
             $RAD->{'User-Name'} || '',
             $cid
            ]
            });

          $self->{IP} = $line->[1] if ($line->[2] eq $NAS->{NAS_ID});
          $active_logins--;
        }
      }
    }

    if ($active_logins >= $self->{LOGINS}) {
      $RAD_PAIRS->{'Reply-Message'} = "MORE_THEN_ALLOW_LOGIN ($self->{LOGINS}/$self->{TOTAL})";
      return 1, $RAD_PAIRS;
    }
  }

  my @time_limits    = ();
  my $remaining_time = 0;
  my $ATTR;

  #Chack Company account if ACCOUNT_ID > 0
  if ($self->{PAYMENT_TYPE} == 0) {
    #if not defined user credit use TP credit
    $self->{CREDIT} = $self->{TP_CREDIT} if ($self->{CREDIT} == 0);
    $self->{DEPOSIT} = $self->{DEPOSIT} + $self->{CREDIT} - $self->{CREDIT_TRESSHOLD};

    #Check EXT_BILL_ACCOUNT
    if ($self->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_DEPOSIT} < 0 && $self->{DEPOSIT} > 0) {
      $self->{DEPOSIT} = $self->{EXT_BILL_DEPOSIT} + $self->{CREDIT};
    }

    #Check deposit
    if ($self->{DEPOSIT} <= 0) {
      return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID},
        {
          RAD_PAIRS   => $RAD_PAIRS,
          MESSAGE     => "NEG_DEPOSIT: '$self->{DEPOSIT}'",
          FILTER_TYPE => 'NEG_DEPOSIT'
        });
    }
  }
  else {
    $self->{DEPOSIT} = 0;
  }

  if ($self->{INTERVALS} > 0) {
    ($self->{TIME_INTERVALS}, $self->{INTERVAL_TIME_TARIF}, $self->{INTERVAL_TRAF_TARIF}) = $Billing->time_intervals($self->{TP_ID});

    ($remaining_time, $ATTR) = $Billing->remaining_time(
      $self->{DEPOSIT},
      {
        TIME_INTERVALS      => $self->{TIME_INTERVALS},
        INTERVAL_TIME_TARIF => $self->{INTERVAL_TIME_TARIF},
        INTERVAL_TRAF_TARIF => $self->{INTERVAL_TRAF_TARIF},
        SESSION_START       => $self->{SESSION_START},
        DAY_BEGIN           => $self->{DAY_BEGIN},
        DAY_OF_WEEK         => $self->{DAY_OF_WEEK},
        DAY_OF_YEAR         => $self->{DAY_OF_YEAR},
        REDUCTION           => $self->{REDUCTION},
        POSTPAID            => $self->{PAYMENT_TYPE},
      }
    );

    print "RT: $remaining_time\n" if ($debug == 1);
  }

  if (defined($ATTR->{TT})) {
    $self->{TT_INTERVAL} = $ATTR->{TT};
  }
  else {
    $self->{TT_INTERVAL} = 0;
  }

  #check allow period and time out
  if ($remaining_time == -1) {
    $RAD_PAIRS->{'Reply-Message'} = "NOT_ALLOW_DAY";
    return 1, $RAD_PAIRS;
  }
  elsif ($remaining_time == -2) {
#    if ($self->{NEG_DEPOSIT_FILTER_ID}) {
    return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID},
        {
          RAD_PAIRS   => $RAD_PAIRS,
          MESSAGE     => "Not Allow time" . (($ATTR->{TT}) ? " Interval: $ATTR->{TT}" : q{}),
          FILTER_TYPE => 'NOT_ALLOW_TIME'
        });
#    }
#
#    $RAD_PAIRS->{'Reply-Message'} = "Not Allow time";
#    $RAD_PAIRS->{'Reply-Message'} .= " Interval: $ATTR->{TT}" if ($ATTR->{TT});
#    return 1, $RAD_PAIRS;
  }
  elsif ($remaining_time > 0) {
    push(@time_limits, $remaining_time);
  }

  #Periods Time and traf limits
  # 0 - Total limit
  # 1 - Day limit
  # 2 - Week limit
  # 3 - Month limit
  my @periods = ('TOTAL', 'DAY', 'WEEK', 'MONTH');
  my $time_limit = $self->{TIME_LIMIT};
  $self->{TRAF_LIMIT} = undef;

  my @direction_sum = ("SUM(sent + recv) / $CONF->{MB_SIZE} + SUM(acct_output_gigawords) * 4096 + SUM(acct_input_gigawords) * 4096",
                       "SUM(recv) / $CONF->{MB_SIZE} + SUM(acct_input_gigawords) * 4096",
                       "SUM(sent) / $CONF->{MB_SIZE} + SUM(acct_output_gigawords) * 4096");

  push @time_limits, $self->{MAX_SESSION_DURATION} if ($self->{MAX_SESSION_DURATION} > 0);

  my %SQL_params = (
    TOTAL => '',
    DAY   => "AND (start >= CONCAT(CURDATE(), ' 00:00:00') AND start<=CONCAT(CURDATE(), ' 24:00:00'))",
    WEEK  => "AND (YEAR(CURDATE())=YEAR(start)) AND (WEEK(CURDATE()) = WEEK(start))",
    MONTH => "AND (start >= DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00') AND start<=DATE_FORMAT(CURDATE(), '%Y-%m-31 24:00:00'))"
  );

  $WHERE = "uid='$self->{UID}' AND tp_id='$self->{TP_ID}'";
  if ($self->{UIDS}) {
    $WHERE = "uid IN ($self->{UIDS})";
  }
  elsif ($self->{PAYMENT_TYPE} == 2) {
    $WHERE = "cid='". $cid ."'";
    $attr->{GUEST}=1;
  }
  my $online_time;

  foreach my $period (@periods) {
    if (($self->{ $period . '_TIME_LIMIT' } > 0) || ($self->{ $period . '_TRAF_LIMIT' } > 0)) {
      my $session_time_limit = $time_limit;
      my $session_traf_limit = $self->{TRAF_LIMIT};
      #Get online time
      if(! defined($online_time)) {
        $self->query2("SELECT SUM(UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started))
         FROM internet_online WHERE $WHERE GROUP BY uid;"
        );
        if($self->{TOTAL}) {
          $online_time = $self->{list}->[0]->[0];
        }
        else {
          $online_time = 0;
        }
      }

      $self->query2("SELECT if(" . $self->{ $period . '_TIME_LIMIT' } . " > 0, " . $self->{ $period . '_TIME_LIMIT' } . "- $online_time - SUM(duration), 0),
          if(" . $self->{ $period . '_TRAF_LIMIT' } . " > 0, " . $self->{ $period . '_TRAF_LIMIT' } . "- $direction_sum[$self->{OCTETS_DIRECTION}], 0),
          1
         FROM internet_log
         WHERE $WHERE $SQL_params{$period}
         GROUP BY 3;"
      );

      if ($self->{TOTAL} == 0) {
        push(@time_limits, $self->{ $period . '_TIME_LIMIT' } - $online_time) if ($self->{ $period . '_TIME_LIMIT' } > 0);
        $session_traf_limit = $self->{ $period . '_TRAF_LIMIT' } if ($self->{ $period . '_TRAF_LIMIT' } && $self->{ $period . '_TRAF_LIMIT' } > 0);
      }
      else {
        ($session_time_limit, $session_traf_limit) = @{ $self->{list}->[0] };
        push(@time_limits, $session_time_limit) if ($self->{ $period . '_TIME_LIMIT' } && $self->{ $period . '_TIME_LIMIT' } > 0);
      }

      if ($self->{ $period . '_TRAF_LIMIT' } && $self->{ $period . '_TRAF_LIMIT' } > 0 && (! $self->{TRAF_LIMIT} || $self->{TRAF_LIMIT} > $session_traf_limit )) {
        $self->{TRAF_LIMIT} = $session_traf_limit;
      }

      if (defined($self->{TRAF_LIMIT}) && $self->{TRAF_LIMIT} <= 0) {
        $RAD_PAIRS->{'Reply-Message'} = "TRAFFIC_LIMIT_UTILIZED '$self->{TRAF_LIMIT} Mb' $period";
        #if ($self->{NEG_DEPOSIT_FILTER_ID}) {
        #  return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID}, { MESSAGE => $RAD_PAIRS->{'Reply-Message'} });
        #}
        return 1, $RAD_PAIRS;
      }
    }
  }

  if ($self->{ACTIVE_DAY_FEE}) {
    push @time_limits, 86400 - ($self->{SESSION_START} - $self->{DAY_BEGIN});
  }

  #set time limit
  for (my $i = 0 ; $i <= $#time_limits ; $i++) {
    if ($time_limit > $time_limits[$i]) {
      $time_limit = $time_limits[$i];
    }
  }

  if ($self->{INTERNET_EXPIRE}) {
    my $to_expire = $self->{INTERNET_EXPIRE} - $self->{SESSION_START};
    if ($to_expire < $time_limit) {
      $time_limit = $to_expire;
    }
  }

  if ($time_limit > 0) {
    $RAD_PAIRS->{'Session-Timeout'} = ($self->{NEG_DEPOSIT_FILTER_ID} && $time_limit < 5) ? int($time_limit + 600) : $time_limit+1;
  }
  elsif ($time_limit < 0) {
    return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID},
       {
         MESSGE     => $RAD_PAIRS->{'Reply-Message'},
         RAD_PAIRS  => $RAD_PAIRS,
         MESSAGE    => "TIME_LIMIT_UTILIZED '$time_limit'",
         FILTER_TYPE=> 'TIME_EXPIRED'
       });
  }

  if ($NAS->{NAS_TYPE} && $NAS->{NAS_TYPE} eq 'ipcad') {
    # SET ACCOUNT expire date
    if ($self->{ACCOUNT_AGE} > 0 && ! $self->{INTERNET_EXPIRE}) {
       $self->query2("UPDATE internet_main SET expire=CURDATE() + INTERVAL $self->{ACCOUNT_AGE} day
       WHERE uid='$self->{UID}';", 'do'
       );
    }
    return 0, $RAD_PAIRS, '';
  }

  if ($CONF->{AUTH_SKIP_GUEST_IPV6} && $self->{GUEST}) {
  }
  else {
    if ($self->{IPV6}) {
      my ($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8) = split(/:/, ipv6_2_long($self->{IPV6}));

      $RAD_PAIRS->{'Framed-IPv6-Prefix'} = ($p1 || q{}) . ':' . ($p2 || q{}) . ':' . ($p3 || q{}) . ':' . ($p4 || q{}) . '::/' . $self->{IPV6_MASK};
      $RAD_PAIRS->{'Framed-Interface-Id'} = ($p5 || q{}) . ':' . ($p6 || q{}) . ':' . ($p7 || q{}) . ':' . ($p8 || q{});
    }

    if ($self->{IPV6_PREFIX}) {
      $RAD_PAIRS->{'Delegated-IPv6-Prefix'} = $self->{IPV6_PREFIX} . '/' . $self->{IPV6_PREFIX_MASK};
    }
  }

  # Return radius attr
  if ($self->{IP} ne '0') {
    $RAD_PAIRS->{'Framed-IP-Address'} = $self->{IP};

    if (! $self->{REASSIGN}) {
      $self->online_add({
        %{ ($attr) ? $attr : {} },
        NAS_ID             => $NAS->{NAS_ID},
        FRAMED_IP_ADDRESS  => "INET_ATON('$self->{IP}')",
        NAS_IP_ADDRESS     => $RAD->{'NAS-IP-Address'},
        FRAMED_IPV6_PREFIX => ($self->{IPV6}) ? "INET6_ATON('". $self->{IPV6} ."')" : undef,
        DELEGATED_IPV6_PREFIX=>($self->{IPV6_PREFIX}) ? "INET6_ATON('". $self->{IPV6_PREFIX} ."')" : undef,
        #FRAMED_INTERFACE_ID=> ($RAD_PAIRS->{'Framed-Interface-Id'}) ? "INET6_ATON('". $RAD_PAIRS->{'Framed-Interface-Id'}. "')" : undef,
      });
    }

    delete $self->{REASSIGN};
  }
  else {
    my $ip = $self->get_ip($NAS->{NAS_ID}, $RAD->{'NAS-IP-Address'}, {
      TP_IPPOOL => $self->{TP_IPPOOL},
      NAS_MAC   => $self->{NAS_MAC}
    });

    if ($ip eq '-1') {
      $RAD_PAIRS->{'Reply-Message'} = "NO_FREE_POOL_IP: (USED: $self->{USED_IPS})";
      return 1, $RAD_PAIRS;
    }
    elsif ($ip eq '0') {
      #$RAD_PAIRS->{'Reply-Message'}="$self->{errstr} ($NAS->{NAS_ID})";
      #return 1, $RAD_PAIRS;
    }
    else {
      $RAD_PAIRS->{'Framed-IP-Address'} = $ip;
    }
  }

  if ($RAD_PAIRS->{'Framed-IP-Address'} && $self->{NETMASK}) {
    $RAD_PAIRS->{'Framed-IP-Netmask'} = $self->{NETMASK}
  }

  $self->nas_pair_former({
    RAD_PAIRS => $RAD_PAIRS,
    RAD       => $RAD,
    NAS       => $NAS
  });

  #Auto assing MAC in first connect
  if ( $CONF->{MAC_AUTO_ASSIGN}
    && $self->{CID} eq ''
    && ($cid =~ /:|\-/ )
    && ! $self->{NAS_PORT})
  {
  	if ($cid =~ /\/\s+([A-Za-z0-9:]+)\s+\//) {
  		$cid = $1;
  	}

    $self->query2("UPDATE internet_main SET cid='$cid' WHERE uid='$self->{UID}';", 'do');
  }

  # SET ACCOUNT expire date
  if ($self->{ACCOUNT_AGE} > 0 && ! $self->{INTERNET_EXPIRE}) {
    $self->query2("UPDATE internet_main SET expire=CURDATE() + INTERVAL $self->{ACCOUNT_AGE} day
      WHERE uid='$self->{UID}';", 'do'
    );
  }

  $RAD_PAIRS->{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE} if ($NAS->{NAS_ALIVE});

  #check TP Radius Pairs
  if ($self->{TP_RAD_PAIRS}) {
    rad_pairs_former($self->{TP_RAD_PAIRS}, { RAD_PAIRS => $RAD_PAIRS });
  }

  if (length($self->{FILTER}) > 0) {
    $self->neg_deposit_filter_former($RAD, $NAS, $self->{FILTER}, { USER_FILTER => 1, RAD_PAIRS => $RAD_PAIRS });
  }

  delete $self->{IP};
  #OK
  return 0, $RAD_PAIRS, '';
}

#*********************************************************
=head2 nas_pair_former($attr) - NAS pair formers

  Arguments:
    $attr
      RAD_PAIRS
      NAS
      RAD

  Results:
    $self

=cut
#*********************************************************
sub nas_pair_former {
  my $self = shift;
  my ($attr) = @_;

  my $RAD_REPLY = $attr->{RAD_PAIRS};
  my $NAS       = $attr->{NAS};
  my $RAD       = $attr->{RAD};
  my $traf_limit= $self->{TRAF_LIMIT} || 0;

  my $nas_type = $NAS->{NAS_TYPE} || q{};
  #MPD5
  if ($nas_type eq 'mpd5') {
    if (!$CONF->{mpd_filters}) {

    }
    elsif (!$NAS->{NAS_EXT_ACCT}) {
      if ($self->{USER_SPEED}) {
        if (!$CONF->{ng_car}) {
          my $shapper_type = ($self->{USER_SPEED} > 4048) ? 'rate-limit' : 'shape';
          my $cir    = $self->{USER_SPEED} * 1024;
          my $nburst = int($cir * 1.5 / 8);
          my $eburst = 2 * $nburst;
          push @{ $RAD_REPLY->{'mpd-limit'} }, "out#1=all $shapper_type $cir $nburst $eburst";
          push @{ $RAD_REPLY->{'mpd-limit'} }, "in#1=all $shapper_type $cir $nburst $eburst";
        }
      }
      else {
        $self->query2("SELECT tt.id, tc.nets, in_speed, out_speed
             FROM trafic_tarifs tt
             LEFT JOIN traffic_classes tc ON (tt.net_id=tc.id)
             WHERE tt.interval_id='$self->{TT_INTERVAL}' ORDER BY 1 DESC;"
        );

        foreach my $line (@{ $self->{list} }) {
          my $class_id    = $line->[0];
          #          my $filter_name = 'flt';

          if ($self->{TOTAL} == 1 || ($class_id == 0 && $line->[1] && $line->[1] =~ /0.0.0.0/)) {
            my $shapper_type = ($line->[2] > 4048) ? 'rate-limit' : 'shape';

            if ($line->[2] == 0 || $CONF->{ng_car}) {
              push @{ $RAD_REPLY->{'mpd-limit'} }, "out#$self->{TOTAL}#0=all pass";
            }
            elsif (!$CONF->{ng_car}) {
              my $cir    = $line->[2] * 1024;
              my $nburst = int($cir * 1.5 / 8);
              my $eburst = 2 * $nburst;
              push @{ $RAD_REPLY->{'mpd-limit'} }, "out#$self->{TOTAL}#0=all $shapper_type $cir $nburst $eburst";
            }

            if ($line->[3] == 0 || $CONF->{ng_car}) {
              push @{ $RAD_REPLY->{'mpd-limit'} }, "in#$self->{TOTAL}#0=all pass";
            }
            elsif (!$CONF->{ng_car}) {
              my $cir    = $line->[3] * 1024;
              my $nburst = int($cir * 1.5 / 8);
              my $eburst = 2 * $nburst;
              push @{ $RAD_REPLY->{'mpd-limit'} }, "in#$self->{TOTAL}#0=all $shapper_type $cir $nburst $eburst";
            }
            next;
          }
          elsif ($line->[1]) {
            $line->[1] =~ s/[\n\r]//g;
            my @net_list = split(/;/, $line->[1]);

            my $i = 1;
            $class_id = $class_id * 2 + 1 - 2 if ($class_id != 0);

            foreach my $net (@net_list) {
              push @{ $RAD_REPLY->{'mpd-filter'} }, ($class_id) . "#$i=match dst net $net";
              push @{ $RAD_REPLY->{'mpd-filter'} }, ($class_id + 1) . "#$i=match src net $net";
              $i++;
            }

            push @{ $RAD_REPLY->{'mpd-limit'} }, "in#" .  ($self->{TOTAL} - $line->[0]) . "#$line->[0]=flt" . ($class_id) . " pass";
            push @{ $RAD_REPLY->{'mpd-limit'} }, "out#" . ($self->{TOTAL} - $line->[0]) . "#$line->[0]=flt" . ($class_id + 1) . " pass";
          }
        }
      }
    }

    #$RAD_PAIRS->{'Session-Timeout'}=604800;
  }
  elsif ($nas_type eq 'cisco') {
    #$traf_tarif
    if ($self->{USER_SPEED} > 0) {
      push @{ $RAD_REPLY->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit output " . ($self->{USER_SPEED} * 1024) . " 320000 320000 conform-action transmit exceed-action drop";
      push @{ $RAD_REPLY->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit input " .  ($self->{USER_SPEED} * 1024) . " 32000 32000 conform-action transmit exceed-action drop";
    }
    else {
      my $EX_PARAMS = $self->ex_traffic_params({
        traf_limit          => $traf_limit,
        deposit             => $self->{DEPOSIT},
      });

      if ($EX_PARAMS->{speed}->{1}->{OUT}) {
        push @{ $RAD_REPLY->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit output access-group 101 " . ($EX_PARAMS->{speed}->{1}->{IN} * 1024) . " 1000000  1000000 conform-action transmit exceed-action drop";
        push @{ $RAD_REPLY->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit input access-group 102 " .  ($EX_PARAMS->{speed}->{1}->{OUT} * 1024) . " 1000000 1000000 conform-action transmit exceed-action drop";
      }
      my $burst_normal = ($EX_PARAMS->{speed}->{0}->{IN} > 50000) ? 512000 : 320000;
      my $burst_max    = ($EX_PARAMS->{speed}->{0}->{IN} > 50000) ? 512000 : 320000;
      push @{ $RAD_REPLY->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit output "
          . ($EX_PARAMS->{speed}->{0}->{IN} * 1024)
          . ' '. $burst_normal
          . ' '. $burst_max
          . " conform-action transmit exceed-action drop" if ($EX_PARAMS->{speed}->{0}->{IN}  && $EX_PARAMS->{speed}->{0}->{IN} > 0);

      $burst_normal = ($EX_PARAMS->{speed}->{0}->{OUT} > 50000) ? 512000 : 320000;
      $burst_max    = ($EX_PARAMS->{speed}->{0}->{OUT} > 50000) ? 512000 : 320000;
      push @{ $RAD_REPLY->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit input "
          .  ($EX_PARAMS->{speed}->{0}->{OUT} * 1024)
          . ' '. $burst_normal
          . ' '. $burst_max
          . " conform-action transmit exceed-action drop" if ($EX_PARAMS->{speed}->{0}->{OUT} && $EX_PARAMS->{speed}->{0}->{OUT} > 0);
    }
  }
  # Mikrotik
  elsif ($nas_type eq 'mikrotik') {
    my $EX_PARAMS = $self->ex_traffic_params({
      traf_limit          => $traf_limit,
      deposit             => $self->{DEPOSIT},
    });

    if ($EX_PARAMS->{traf_limit} > 0) {
      #Gigaword limit
      $RAD_REPLY->{'Mikrotik-Total-Limit-Gigawords'} = 0;
      if ($EX_PARAMS->{traf_limit} > 4096) {
        my $giga_limit = int($EX_PARAMS->{traf_limit} / 4096);
        #$RAD_PAIRS->{'Mikrotik-Recv-Limit-Gigawords'}=int($giga_limit);
        #$RAD_PAIRS->{'Mikrotik-Xmit-Limit-Gigawords'}=int($giga_limit);
        $RAD_REPLY->{'Mikrotik-Total-Limit-Gigawords'} = $giga_limit;
        $EX_PARAMS->{traf_limit} = $EX_PARAMS->{traf_limit} - int($giga_limit) * 4096;
        #$RAD_PAIRS->{'Mikrotik-Recv-Limit-Gigawords'}=$giga_limit;
        #$RAD_PAIRS->{'Mikrotik-Xmit-Limit-Gigawords'}=$giga_limit;
      }
      $RAD_REPLY->{'Mikrotik-Total-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE});
      #$RAD_PAIRS->{'Mikrotik-Recv-Limit'}  = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE}); # / 2);
      #$RAD_PAIRS->{'Mikrotik-Xmit-Limit'}  = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE}); #/ 2);
    }

    if ($self->{IPV6_PREFIX}) {
      $RAD_REPLY->{'Mikrotik-Delegated-IPv6-Pool'} = $self->{IPV6_PREFIX} . '/' . $self->{IPV6_PREFIX_MASK};
    }

    #Shaper
    #global Traffic
    if ($self->{USER_SPEED} > 0) {
      $RAD_REPLY->{'Mikrotik-Rate-Limit'} = "$self->{USER_SPEED}k";
      $RAD_REPLY->{'Mikrotik-Address-List'} = "CUSTOM_SPEED";
    }
    elsif ($EX_PARAMS->{ex_speed}) {
      $RAD_REPLY->{'Mikrotik-Rate-Limit'} = "$EX_PARAMS->{ex_speed}k";
      $RAD_REPLY->{'Mikrotik-Address-List'} = "CUSTOM_SPEED";
    }
    elsif ($EX_PARAMS->{speed} && defined($EX_PARAMS->{speed}->{0})) {
      # Use mikrotik SIMPLE QUEUES
      if ($CONF->{MIKROTIK_QUEUES} || $RAD->{'WISPr-Logoff-URL'}) {
        #        $RAD_PAIRS->{'Ascend-Xmit-Rate'} = int($EX_PARAMS->{speed}->{0}->{IN}) * $CONF->{KBYTE_SIZE};
        #        $RAD_PAIRS->{'Ascend-Data-Rate'} = int($EX_PARAMS->{speed}->{0}->{OUT})* $CONF->{KBYTE_SIZE};
        # Mikrotik-Rate-Limit = 512K/1024K 1M/2M 256K/512K 32/32 5
        $RAD_REPLY->{'Mikrotik-Rate-Limit'} =
          $EX_PARAMS->{speed}->{0}->{OUT}.'K/'.$EX_PARAMS->{speed}->{0}->{IN}.'K '.
            $EX_PARAMS->{speed}->{0}->{OUT_BURST}.'K/'.$EX_PARAMS->{speed}->{0}->{IN_BURST}.'K '.
            $EX_PARAMS->{speed}->{0}->{OUT_BURST_THRESHOLD}.'K/'.$EX_PARAMS->{speed}->{0}->{IN_BURST_THRESHOLD}.'K '.
            $EX_PARAMS->{speed}->{0}->{OUT_BURST_TIME}.'/'.$EX_PARAMS->{speed}->{0}->{IN_BURST_TIME}.' 5';
      }

      $RAD_REPLY->{'Mikrotik-Address-List'} = "CLIENTS_$self->{TP_ID}";
    }
  }
  elsif ($nas_type eq 'accel_ipoe') {
    #$RAD_PAIRS->{'Framed-IP-Address'} = $self->{IP}; # if ($self->{IPOE_IP} && $self->{IPOE_IP} ne '0.0.0.0');
    if ($self->{IPOE_NETMASK}) {
      $RAD_REPLY->{'Framed-Netmask'} = $self->{IPOE_NETMASK};
      delete($RAD_REPLY->{'Framed-IP-Netmask'});
    }
    elsif($self->{NETMASK}) {
      $RAD_REPLY->{'Framed-Netmask'} = $self->{NETMASK};
    }

    if($self->{GATEWAY} && $self->{GATEWAY} ne '0.0.0.0') {
      $RAD_REPLY->{'DHCP-Router-IP-Address'} = $self->{GATEWAY};
    }

    if($self->{DNS}) {
      my @dns_arr = split(/,\s?/, $self->{DNS});
      foreach my $ip ( @dns_arr ) {
        push @{ $RAD_REPLY->{'DHCP-Domain-Name-Server'} }, '0x'.unpack("H*", pack("C4", split(/\./, $ip)));
      }
    }

    #$RAD_PAIRS->{'Session-Timeout'}   = 604800;

    if(! $attr->{GUEST}) {
      my $EX_PARAMS = $self->ex_traffic_params({
        traf_limit => $traf_limit,
        deposit    => $self->{DEPOSIT},
      });

      #Speed limit attributes
      if ($self->{USER_SPEED} > 0) {
        $RAD_REPLY->{'PPPD-Upstream-Speed-Limit'} = int($self->{USER_SPEED});
        $RAD_REPLY->{'PPPD-Downstream-Speed-Limit'} = int($self->{USER_SPEED});
      }
      elsif (defined($EX_PARAMS->{speed}->{0})) {
        $RAD_REPLY->{'PPPD-Downstream-Speed-Limit'} = int($EX_PARAMS->{speed}->{0}->{IN});
        $RAD_REPLY->{'PPPD-Upstream-Speed-Limit'} = int($EX_PARAMS->{speed}->{0}->{OUT});
      }
    }
  }
  # pppd + RADIUS plugin (Linux) http://samba.org/ppp/
  elsif ($nas_type eq 'accel_ppp'
    || $nas_type eq 'pppd')
  {
    my $EX_PARAMS = $self->ex_traffic_params({
      traf_limit          => $traf_limit,
      deposit             => $self->{DEPOSIT},
    });

    #global Traffic
    if ($EX_PARAMS->{traf_limit} > 0) {
      $RAD_REPLY->{'Session-Octets-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE});

      if ($CONF->{octets_direction} && $CONF->{octets_direction} eq 'user') {
        if ($self->{OCTETS_DIRECTION} == 1) {
          $RAD_REPLY->{'Octets-Direction'} = 2;
        }
        elsif ($self->{OCTETS_DIRECTION} == 2) {
          $RAD_REPLY->{'Octets-Direction'} = 1;
        }
        else {
          $RAD_REPLY->{'Octets-Direction'} = 0;
        }
      }
      else {
        $RAD_REPLY->{'Octets-Direction'} = $self->{OCTETS_DIRECTION};
      }
    }

    #Speed limit attributes
    if ($self->{USER_SPEED} > 0) {
      $RAD_REPLY->{'PPPD-Upstream-Speed-Limit'}   = int($self->{USER_SPEED});
      $RAD_REPLY->{'PPPD-Downstream-Speed-Limit'} = int($self->{USER_SPEED});
    }
    elsif (defined($EX_PARAMS->{speed}->{0})) {
      $RAD_REPLY->{'PPPD-Downstream-Speed-Limit'} = int($EX_PARAMS->{speed}->{0}->{IN});
      $RAD_REPLY->{'PPPD-Upstream-Speed-Limit'}   = int($EX_PARAMS->{speed}->{0}->{OUT});
    }

    if($self->{DNS}) {
      my @dns_arr = split(/,\s?/, $self->{DNS});
      if ($#dns_arr > -1) {
        $RAD_REPLY->{'MS-Primary-DNS-Server'} = $dns_arr[0];
        if ($#dns_arr > 0) {
          $RAD_REPLY->{'MS-Secondary-DNS-Server'} = $dns_arr[1];
        }
      }
    }

    if ($CONF->{ACCELPPP_IFNAME}) {
      $RAD_REPLY->{'NAS-Port-Id'}=$self->{LOGIN} || $RAD->{'User-Name'};
    }
  }
  #Chillispot
  elsif ($nas_type eq 'chillispot' || $nas_type eq 'unifi') {
    my $EX_PARAMS = $self->ex_traffic_params({
      traf_limit          => $traf_limit,
      deposit             => $self->{DEPOSIT},
    });

    #global Traffic
    if ($EX_PARAMS->{traf_limit} > 0) {
      $RAD_REPLY->{'ChilliSpot-Max-Total-Octets'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE});
    }

    #Shaper for chillispot
    if ($self->{USER_SPEED} > 0) {
      $RAD_REPLY->{'WISPr-Bandwidth-Max-Down'} = int($self->{USER_SPEED}) * $CONF->{KBYTE_SIZE};
      $RAD_REPLY->{'WISPr-Bandwidth-Max-Up'}   = int($self->{USER_SPEED}) * $CONF->{KBYTE_SIZE};
    }
    elsif ($EX_PARAMS->{speed} && $EX_PARAMS->{speed}->{0}) {
      $RAD_REPLY->{'WISPr-Bandwidth-Max-Down'} = int($EX_PARAMS->{speed}->{0}->{IN}) * $CONF->{KBYTE_SIZE};
      $RAD_REPLY->{'WISPr-Bandwidth-Max-Up'}   = int($EX_PARAMS->{speed}->{0}->{OUT}) * $CONF->{KBYTE_SIZE};
    }

    if(! $self->{IP} && $nas_type eq 'unifi') {
      $self->online_add({
        %$attr,
        CID               => $RAD->{'Calling-Station-Id'},
        ACCT_SESSION_ID   => $RAD->{'Acct-Session-Id'} || 'IP',
        NAS_ID            => $NAS->{NAS_ID},
        FRAMED_IP_ADDRESS => "INET_ATON('". $RAD->{'Framed-IP-Address'} ."')",
        NAS_IP_ADDRESS    => $NAS->{NAS_IP}
      });
    }
  }
  elsif ($nas_type eq 'zte_m6000') {
    my $EX_PARAMS = $self->ex_traffic_params({
      traf_limit => $traf_limit,
      deposit    => $self->{DEPOSIT},
    });

    if ($traf_limit && $traf_limit > 0) {
      $RAD_REPLY->{'ZTE-Session-Timeout-Type'}=4;
      $RAD_REPLY->{'Session-Timeout'}=int($traf_limit*1024);
      #$RAD_PAIRS->{'ZTE-QoS-Profile-Down'}='100M&1M';
    }

    #Speed limit attributes
    if ($self->{USER_SPEED} > 0) {
      $RAD_REPLY->{'ZTE-Rate-Ctrl-SCR-Down'} = int($self->{USER_SPEED});
      $RAD_REPLY->{'ZTE-Rate-Ctrl-SCR-Up'}   = int($self->{USER_SPEED});
    }
    elsif(defined($EX_PARAMS->{speed}->{1})) {
      $RAD_REPLY->{'ZTE-QoS-Profile-Down'}=int($EX_PARAMS->{speed}->{0}->{IN} / 1024). 'M&'.
        int($EX_PARAMS->{speed}->{1}->{IN} / 1024). 'M';
    }
    elsif (defined($EX_PARAMS->{speed}->{0})) {
      $RAD_REPLY->{'ZTE-Rate-Ctrl-SCR-Down'} = int($EX_PARAMS->{speed}->{0}->{IN});
      $RAD_REPLY->{'ZTE-Rate-Ctrl-SCR-Up'}   = int($EX_PARAMS->{speed}->{0}->{OUT});
    }
  }

  return $self;
}

#*********************************************************
=head2 auth_cid($RAD) - Auth_mac

  Mac auth function

=cut
#*********************************************************
sub auth_cid {
  my $self = shift;
  my ($RAD) = @_;

  my $RAD_PAIRS;
  if($CONF->{AUTH_IP}) {
    return 0, $RAD_PAIRS;
  }

  my @MAC_DIGITS_GET = ();
  if (!$RAD->{'Calling-Station-Id'}) {
    $RAD_PAIRS->{'Reply-Message'} = "WRONG_CID ''";
    return 1, $RAD_PAIRS, "WRONG_CID ''";
  }

  my @CID_POOL = split(/;/, $self->{CID});
  my $cid = $RAD->{'Calling-Station-Id'};

  foreach my $TEMP_CID (@CID_POOL) {
    if ($TEMP_CID) {
      if ($TEMP_CID =~ /:|\-/ && $TEMP_CID !~ /\./) {
        @MAC_DIGITS_GET = split(/:|\-/, $TEMP_CID);
        my @MAC_DIGITS_NEED = split(/:|\-/, $cid);
        my $error = 0;
        for (my $i = 0 ; $i <= 5 ; $i++) {
          if (defined($MAC_DIGITS_NEED[$i]) && hex($MAC_DIGITS_NEED[$i]) != hex($MAC_DIGITS_GET[$i])) {
            $error = 1;
            next;
          }
        }

        if (! $error) {
          return 0;
        }
      }
      # If like MPD CID
      # 192.168.101.2 / 00:0e:0c:4a:63:56
      elsif ($TEMP_CID =~ /\//) {
        $cid =~ s/ //g;
        my ($cid_ip, $cid_mac, undef) = split(/\//, $cid, 3);
        if ("$cid_ip/$cid_mac" eq $TEMP_CID) {
          return 0;
        }
      }
      elsif ($TEMP_CID eq $cid) {
        return 0;
      }
    }
  }

  $RAD_PAIRS->{'Reply-Message'} = "WRONG_CID '". $cid ."'";
  return 1, $RAD_PAIRS;
}

#**********************************************************
=head2 authentication($RAD_HASH_REF, $NAS_HASH_REF, $attr) - User authentication

=cut
#**********************************************************
sub authentication {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my $SECRETKEY = (defined($CONF->{secretkey})) ? $CONF->{secretkey} : '';
  my %RAD_PAIRS = ();

  if ($NAS->{NAS_TYPE} eq 'cid_auth' && $RAD->{'Calling-Station-Id'}) {
    my  ($ret, $RAD_PAIRS) = $self->mac_auth($RAD, $NAS);
    return $ret, $RAD_PAIRS;
  }
  else {
    if ($RAD->{'User-Name'} =~ / /) {
      $RAD_PAIRS{'Reply-Message'} = "USER_NOT_EXIST. Space in login '". $RAD->{'User-Name'} ."'";
      return 1, \%RAD_PAIRS;
    }

    my $WHERE = '';
    if ($NAS->{DOMAIN_ID}) {
      $WHERE = "AND u.domain_id='$NAS->{DOMAIN_ID}'";
    }
    else {
      $WHERE = "AND u.domain_id='0'";
    }

    if ($CONF->{INTERNET_LOGIN}) {
      $self->query2("SELECT uid, login, id AS service_id FROM internet_main WHERE login= ? ;",
          undef, { INFO => 1, Bind => [ $RAD->{'User-Name'} ] });
    }

    if ($self->{UID}) {
      $WHERE = "u.uid='$self->{UID}' " . $WHERE;
    }
    else {
      $WHERE = "u.id='". $RAD->{'User-Name'} ."'  " . $WHERE;
    }

    $self->query2("SELECT
  u.uid,
  DECODE(password, '$SECRETKEY') AS passwd,
  UNIX_TIMESTAMP() AS session_start,
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_bagin,
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_week,
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year,
  u.company_id,
  u.disable,
  u.bill_id,
  u.credit,
  u.activate AS account_activate,
  u.reduction,
  u.ext_bill_id,
  UNIX_TIMESTAMP(u.expire) AS account_expire
     FROM users u
     WHERE
        $WHERE
        AND (u.expire='0000-00-00' or u.expire > CURDATE())
        AND (u.activate='0000-00-00' or u.activate <= CURDATE())
        AND u.deleted='0'
       GROUP BY u.id;",
  undef,
  { INFO => 1 }
    );
  }

  if ($self->{errno}) {
    if($self->{errno} == 2) {
      $RAD_PAIRS{'Reply-Message'} = "USER_NOT_EXIST";
    }
    else {
      $RAD_PAIRS{'Reply-Message'} = 'SQL_ERROR';
    }
    return 1, \%RAD_PAIRS;
  }

  if ($CONF->{INTERNET_PASSWORD}) {
    my $WHERE = ($self->{SERVICE_ID}) ? "id='$self->{SERVICE_ID}'" : "uid='$self->{UID}'";
    $self->query2("SELECT DECODE(password, '$CONF->{secretkey}') AS password FROM internet_main WHERE $WHERE;");
    if($self->{list}->[0]->[0]) {
      $self->{PASSWD}=$self->{list}->[0]->[0];
    }
  }
  if ($RAD->{'CHAP-Password'} && $RAD->{'CHAP-Challenge'}) {
    if (check_chap($RAD->{'CHAP-Password'}, "$self->{PASSWD}", $RAD->{'CHAP-Challenge'}, 0) == 0) {
      $RAD_PAIRS{'Reply-Message'} = 'WRONG_CHAP_PASSWORD';
      return 1, \%RAD_PAIRS;
    }
  }
  #Auth MS-CHAP v1,v2
  elsif ($RAD->{'MS-CHAP-Challenge'}) {
  }
  #End MS-CHAP auth
#  elsif ($NAS->{NAS_AUTH_TYPE} && $NAS->{NAS_AUTH_TYPE} == 1) {
#    if (check_systemauth($RAD->{'User-Name'}, $RAD->{'User-Password'}) == 0) {
#      $RAD_PAIRS{'Reply-Message'} = "WRONG_PASSWORD '". $RAD->{'User-Password'} ."' $NAS->{NAS_AUTH_TYPE}";
#      $RAD_PAIRS{'Reply-Message'} .= " CID: " . $RAD->{'Calling-Station-Id'} if ($RAD->{'Calling-Station-Id'});
#      return 1, \%RAD_PAIRS;
#    }
#  }
  #If don't athorize any above methods auth PAP password
  else {
    if (defined($RAD->{'User-Password'}) && $self->{PASSWD} ne $RAD->{'User-Password'}) {
      $RAD_PAIRS{'Reply-Message'} = "WRONG_PASSWORD '". $RAD->{'User-Password'} ."'";
      return 1, \%RAD_PAIRS;
    }
  }

  if ($RAD->{'Cisco-AVPair'}) {
    if ($RAD->{'Cisco-AVPair'} =~ /client-mac-address=([a-f0-9\.\-\:]+)/) {
      $RAD->{'Calling-Station-Id'} = $1;
      if ($RAD->{'Calling-Station-Id'} =~ /(\S{2})(\S{2})\.(\S{2})(\S{2})\.(\S{2})(\S{2})/) {
        $RAD->{'Calling-Station-Id'} = "$1:$2:$3:$4:$5:$6";
      }
    }
  }
  elsif ($RAD->{'Tunnel-Client-Endpoint:0'}) {
    if($RAD->{'Calling-Station-Id'}) {
      $self->{INFO} = $RAD->{'Calling-Station-Id'};
    }

    $RAD->{'Calling-Station-Id'} = $RAD->{'Tunnel-Client-Endpoint:0'};
  }

  #DIsable
  if ($self->{DISABLE}) {
    $RAD_PAIRS{'Reply-Message'} = "ACCOUNT_DISABLE";
    return 1, \%RAD_PAIRS;
  }

  #Chack Company account if ACCOUNT_ID > 0
  $self->check_company_account() if ($self->{COMPANY_ID} > 0);
  if ($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'} = $self->{errstr};
    return 1, \%RAD_PAIRS;
  }

  $self->check_bill_account();
  if ($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'} = $self->{errstr};
    return 1, \%RAD_PAIRS;
  }

  return 0, \%RAD_PAIRS, '';
}


#**********************************************************
=head2 internet_auth($RAD_HASH_REF, $NAS_HASH_REF, $attr) - User authentication

  Attributes:
    $RAD_HASH_REF  - RADIUS PAIRS
    $NAS_HASH_REF  - NAS information object
    $attr          - Extra attributes

  Returns:
    ($r, $RAD_PAIRS_REF)
    $r             - 1 false (Not auth)
                     0 true  (auth)

    $RAD_PAIRS_REF - Reply rad pairs hash_ref

=cut
#**********************************************************
sub internet_auth {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my %RAD_PAIRS = ();
  if($self->{UID}) {
    $self->authentication($RAD, $NAS);
  }
  else {
    my $user_auth_params = $self->opt82_parse($RAD);
    $user_auth_params->{USER_MAC} = $RAD->{'Calling-Station-Id'} if (! $user_auth_params->{USER_MAC});
    $user_auth_params->{IP}       = $RAD->{'Framed-IP-Address'} if($RAD->{'Framed-IP-Address'});
    $user_auth_params->{USER_NAME}= $RAD->{'User-Name'};
    if ($CONF->{NAS_PORT_AUTH}) {
      $user_auth_params->{NAS_PORT_AUTH}=$CONF->{NAS_PORT_AUTH};
    }
    $self->dhcp_info($user_auth_params, $NAS);
    if($user_auth_params->{SERVER_VLAN}) {
      $self->{SERVER_VLAN}=$user_auth_params->{SERVER_VLAN};
    }
    $self->{VLAN}=$user_auth_params->{VLAN} if ($user_auth_params->{VLAN});
    $self->{PORT}=$user_auth_params->{PORT} if ($user_auth_params->{PORT});
    $self->{NAS_MAC}=$user_auth_params->{NAS_MAC} if ($user_auth_params->{NAS_MAC});
  }

  if ($self->{errno}) {
    if($self->{errno} == 2) {
      return 2, \%RAD_PAIRS;
    }
    elsif($self->{errno} == 12) {
      $RAD_PAIRS{'Reply-Message'} = 'WRONG_IP '. $self->{error_str};
      return 1, \%RAD_PAIRS;
    }
    else {
      $RAD_PAIRS{'Reply-Message'} = 'SQL_ERROR';
    }
    return 1, \%RAD_PAIRS;
  }

  if(defined($self->{PASSWORD})) {
    if ($RAD->{'CHAP-Password'} && $RAD->{'CHAP-Challenge'}) {
      if (check_chap($RAD->{'CHAP-Password'}, "$self->{PASSWD}", $RAD->{'CHAP-Challenge'}, 0) == 0) {
        $RAD_PAIRS{'Reply-Message'} = "WRONG_CHAP_PASSWORD";
        return 1, \%RAD_PAIRS;
      }
    }
    #Auth MS-CHAP v1,v2
    elsif ($RAD->{'MS-CHAP-Challenge'}) {
    }
    #If don't athorize any above methods auth PAP password
    else {
      if (defined($RAD->{'User-Password'}) && $self->{PASSWD} ne $RAD->{'User-Password'}) {
        $RAD_PAIRS{'Reply-Message'} = "WRONG_PASSWORD: //$self->{PASSWD}// '".$RAD->{'User-Password'}."'";
        return 1, \%RAD_PAIRS;
      }
    }
  }

  if($self->{USER_NAME}) {
    $self->{LOGIN}=$self->{USER_NAME};
    #$RAD->{'User-Name'}=$self->{USER_NAME};
  }

  if ($RAD->{'Cisco-AVPair'}) {
    if ($RAD->{'Cisco-AVPair'} =~ /client-mac-address=([a-f0-9\.\-\:]+)/) {
      $RAD->{'Calling-Station-Id'} = $1;
      if ($RAD->{'Calling-Station-Id'} =~ /(\S{2})(\S{2})\.(\S{2})(\S{2})\.(\S{2})(\S{2})/) {
        $RAD->{'Calling-Station-Id'} = "$1:$2:$3:$4:$5:$6";
      }
    }
  }
  elsif ($RAD->{'Tunnel-Client-Endpoint:0'}) {
    $RAD->{'Calling-Station-Id'} = $RAD->{'Tunnel-Client-Endpoint:0'};
  }

  #DIsable
  if ($self->{DISABLE}) {
    $RAD_PAIRS{'Reply-Message'} = "ACCOUNT_DISABLE";
    return 1, \%RAD_PAIRS;
  }

  #Chack Company account if ACCOUNT_ID > 0
  $self->check_company_account() if ($self->{COMPANY_ID} > 0);
  if ($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'} = $self->{errstr};
    return 1, \%RAD_PAIRS;
  }

  $RAD_PAIRS{'DHCP-Router-IP-Address'}=$self->{ROUTER_IP} if ($self->{ROUTER_IP} && $self->{ROUTER_IP} ne '0.0.0.0') ;

  $self->check_bill_account();
  if ($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'} = $self->{errstr};
    return 1, \%RAD_PAIRS;
  }

  return 0, \%RAD_PAIRS, '';
}


#*******************************************************************
=head2 check_bill_account() - Check Bill account

=cut
#*******************************************************************
sub check_bill_account {
  my $self = shift;

  if ($CONF->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_ID}) {
    $self->query2("SELECT id, ROUND(deposit, 2) FROM bills
     WHERE id='$self->{BILL_ID}' OR id='$self->{EXT_BILL_ID}';"
    );
    if ($self->{errno}) {
      return $self;
    }
    elsif ($self->{TOTAL} < 1) {
      $self->{errno}  = 2;
      $self->{errstr} = "EXT_BILL ACCOUNT NOT EXIST";
      return $self;
    }

    foreach my $l (@{ $self->{list} }) {
      if ($self->{EXT_BILL_ID} && $l->[0] == $self->{EXT_BILL_ID}) {
        $self->{EXT_BILL_DEPOSIT} = $l->[1];
      }
      else {
        $self->{DEPOSIT} = $l->[1];
      }
    }
  }
  else {
    #get sum from bill account
    $self->query2("SELECT ROUND(deposit, 2) FROM bills WHERE id='$self->{BILL_ID}';");
    if ($self->{errno}) {
      return $self;
    }
    elsif ($self->{TOTAL} < 1) {
      $self->{errno}  = 2;
      $self->{errstr} = "BILL ACCOUNT NOT EXIST '$self->{BILL_ID}'";
      return $self;
    }

    ($self->{DEPOSIT}) = $self->{list}->[0]->[0];
  }
  return $self;
}

#*******************************************************************
=head2 check_company_account() - Check Company account

=cut
#*******************************************************************
sub check_company_account {
  my $self = shift;

  $self->query2("SELECT bill_id, disable, credit
       FROM companies WHERE id='$self->{COMPANY_ID}';"
  );

  if ($self->{errno}) {
    return $self;
  }
  elsif ($self->{TOTAL} < 1) {
    $self->{errstr} = "COMPANY '$self->{COMPANY_ID}' NOT_EXIST";
    $self->{errno}  = 1;
    return $self;
  }

  ($self->{BILL_ID}, $self->{DISABLE}, $self->{COMPANY_CREDIT}) = @{ $self->{list}->[0] };
  $self->{CREDIT} = $self->{COMPANY_CREDIT} if ($self->{CREDIT} == 0);

  return $self;
}

#*******************************************************************
=head2 ex_traffic_params($attr) - Extended traffic parameters

  Arguments:
    $attr
      traf_limit
      deposit
      TT_INTERVAL
      BILLLING

  Require:
    $self->{TT_INTERVAL}

  Returns:
    \%EX_PARAMS
       ex_speed
       traf_limit_lo
       traf_limit
       speed->{XX}->{IN}
       speed->{XX}->{OUT}

       speed->{XX}->{IN_BURST}
       speed->{XX}->{OUT_BURST}
       speed->{XX}->{IN_BURST_THRESHOLD}
       speed->{XX}->{OUT_BURST_THRESHOLD}
       speed->{XX}->{IN_BURST_TIME}
       speed->{XX}->{OUT_BURST_TIME}

=cut
#*******************************************************************
sub ex_traffic_params {
  my $self = shift;
  my ($attr) = @_;

  my $deposit = (defined($attr->{deposit})) ? $attr->{deposit} : 0;
  my %EX_PARAMS = ();
  if ($attr->{TT_INTERVAL}) {
    $self->{TT_INTERVAL}=$attr->{TT_INTERVAL};
  }

  if($attr->{BILLING}) {
    $Billing = $attr->{BILLING};
  }

  if ($CONF->{INTERNET_TURBO_MODE}) {
    $self->query2("SELECT t.speed,  t.uid, t.id
     FROM turbo_mode t
     WHERE UNIX_TIMESTAMP(t.start)+t.time>UNIX_TIMESTAMP()
      AND t.uid='$self->{UID}';",
      undef,
      $attr
    );

    if ($self->{TOTAL} && $self->{TOTAL} > 0) {
      $EX_PARAMS{speed}->{0}->{IN} = $self->{list}->[0]->[0];
      $EX_PARAMS{speed}->{0}->{OUT} = $self->{list}->[0]->[0];

      return \%EX_PARAMS;
    }
  }

  $EX_PARAMS{traf_limit} = (defined($attr->{traf_limit})) ? $attr->{traf_limit} : 0;
  $EX_PARAMS{traf_limit_lo} = 4090;

  my %prepaids      = (0 => 0, 1 => 0);
  my %in_prices     = ();
  my %out_prices    = ();
  my %trafic_limits = ();
  my %expr          = ();

  $self->query2("SELECT id, in_price, out_price, prepaid, in_speed, out_speed, net_id, expression
    ,burst_limit_dl,burst_limit_ul,burst_threshold_dl,burst_threshold_ul,burst_time_dl,burst_time_ul
     FROM trafic_tarifs
     WHERE interval_id= ?;",
    undef,
    { Bind => [ $self->{TT_INTERVAL} ] }
  );

  if ($self->{TOTAL} < 1) {
    return \%EX_PARAMS;
  }
  elsif ($self->{errno}) {
    return \%EX_PARAMS;
  }

  my $list = $self->{list};
  foreach my $line (@$list) {
    $prepaids{ $line->[0] }              = $line->[3];
    $in_prices{ $line->[0] }             = $line->[1];
    $out_prices{ $line->[0] }            = $line->[2];
    $EX_PARAMS{speed}{ $line->[0] }{IN}  = $line->[4];
    $EX_PARAMS{speed}{ $line->[0] }{OUT} = $line->[5];
    $expr{ $line->[0] }                  = $line->[7] if (length($line->[7]) > 5);
    $EX_PARAMS{nets} = 1 if ($line->[6] > 0);
    $EX_PARAMS{speed}{ $line->[0] }{IN_BURST} = $line->[8];
    $EX_PARAMS{speed}{ $line->[0] }{OUT_BURST} = $line->[9];
    $EX_PARAMS{speed}{ $line->[0] }{IN_BURST_THRESHOLD} = $line->[10];
    $EX_PARAMS{speed}{ $line->[0] }{OUT_BURST_THRESHOLD} = $line->[11];
    $EX_PARAMS{speed}{ $line->[0] }{IN_BURST_TIME} = $line->[12];
    $EX_PARAMS{speed}{ $line->[0] }{OUT_BURST_TIME} = $line->[13];
  }

  #Get tarfic limit if prepaid > 0 or
  # expresion exist
  if ((defined($prepaids{0}) && $prepaids{0} > 0) || (defined($prepaids{1}) && $prepaids{1} > 0) || $expr{0} || $expr{1}) {
    my $start_period = undef;
    if ($expr{0} =~ /DAY_TRAFFIC/) {
      $start_period = "DATE_FORMAT(start, '%Y-%m-%d')>=CURDATE()";
    }
    elsif ($self->{ACTIVATE} ne '0000-00-00') {
      $start_period = "DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACTIVATE}'";
    }

    $Billing->{INTERNET}=1;
    $Billing->{TI_ID}=$self->{TT_INTERVAL};
    my $used_traffic = $Billing->get_traffic(
      {
        UID    => $self->{UID},
        UIDS   => $self->{UIDS},
        PERIOD => $start_period,
        TI_ID  => $self->{TT_INTERVAL}
      }
    );

    #Make trafiic sum only for diration
    #Recv / IN
    if ($self->{OCTETS_DIRECTION} == 1) {
      $used_traffic->{TRAFFIC_COUNTER}   = $used_traffic->{TRAFFIC_IN};
      $used_traffic->{TRAFFIC_COUNTER_2} = $used_traffic->{TRAFFIC_IN_2};
    }

    #Sent / OUT
    elsif ($self->{OCTETS_DIRECTION} == 2) {
      $used_traffic->{TRAFFIC_COUNTER}   = $used_traffic->{TRAFFIC_OUT};
      $used_traffic->{TRAFFIC_COUNTER_2} = $used_traffic->{TRAFFIC_OUT_2};
    }
    else {
      $used_traffic->{TRAFFIC_COUNTER}   = $used_traffic->{TRAFFIC_IN} + $used_traffic->{TRAFFIC_OUT};
      $used_traffic->{TRAFFIC_COUNTER_2} = $used_traffic->{TRAFFIC_IN_2} + $used_traffic->{TRAFFIC_OUT_2};
    }

    if ($self->{TRAFFIC_TRANSFER_PERIOD}) {
      my $interval = undef;
      if ($self->{ACTIVATE} ne '0000-00-00') {
        $interval = "(DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACTIVATE}' - INTERVAL $self->{TRAFFIC_TRANSFER_PERIOD} * 30 DAY &&
       DATE_FORMAT(start, '%Y-%m-%d')<='$self->{ACTIVATE}')";
      }
      else {
        $interval = "(DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(curdate() - INTERVAL $self->{TRAFFIC_TRANSFER_PERIOD} MONTH, '%Y-%m') AND
       DATE_FORMAT(start, '%Y-%m')<=DATE_FORMAT(curdate(), '%Y-%m') ) ";
      }

      # Traffic transfer
      my $transfer_traffic = $Billing->get_traffic(
        {
          UID      => $self->{UID},
          UIDS     => $self->{UIDS},
          INTERVAL => $interval,
          TP_ID    => $self->{TP_ID},
          TP_NUM   => $self->{TP_NUM},
          TI_ID    => $self->{TT_INTERVAL}
        }
      );


      if ($Billing->{TOTAL} > 0) {
        if ($self->{OCTETS_DIRECTION} == 1) {
          $prepaids{0} += $prepaids{0} * $self->{TRAFFIC_TRANSFER_PERIOD} - $transfer_traffic->{TRAFFIC_IN}   if ($prepaids{0} > $transfer_traffic->{TRAFFIC_IN});
          $prepaids{1} += $prepaids{1} * $self->{TRAFFIC_TRANSFER_PERIOD} - $transfer_traffic->{TRAFFIC_IN_2} if ($prepaids{1} > $transfer_traffic->{TRAFFIC_IN_2});
        }

        #Sent / OUT
        elsif ($self->{OCTETS_DIRECTION} == 2) {
          $prepaids{0} += $prepaids{0} * $self->{TRAFFIC_TRANSFER_PERIOD} - $transfer_traffic->{TRAFFIC_OUT}   if ($prepaids{0} > $transfer_traffic->{TRAFFIC_OUT});
          $prepaids{1} += $prepaids{1} * $self->{TRAFFIC_TRANSFER_PERIOD} - $transfer_traffic->{TRAFFIC_OUT_2} if ($prepaids{1} > $transfer_traffic->{TRAFFIC_OUT_2});
        }
        else {
          $prepaids{0} += $prepaids{0} * $self->{TRAFFIC_TRANSFER_PERIOD} - ($transfer_traffic->{TRAFFIC_IN} + $transfer_traffic->{TRAFFIC_OUT})     if ($prepaids{0} > ($transfer_traffic->{TRAFFIC_IN} + $transfer_traffic->{TRAFFIC_OUT}));
          $prepaids{1} += $prepaids{1} * $self->{TRAFFIC_TRANSFER_PERIOD} - ($transfer_traffic->{TRAFFIC_IN_2} + $transfer_traffic->{TRAFFIC_OUT_2}) if ($prepaids{1} > ($transfer_traffic->{TRAFFIC_IN_2} + $transfer_traffic->{TRAFFIC_OUT_2}));
        }
      }
    }

    if ($self->{TOTAL} == 0) {
      $trafic_limits{0} = $prepaids{0} || 0;
      $trafic_limits{1} = $prepaids{1} || 0;
    }
    else {
      #Check global traffic
      if ($used_traffic->{TRAFFIC_COUNTER} < $prepaids{0}) {
        $trafic_limits{0} = $prepaids{0} - $used_traffic->{TRAFFIC_COUNTER};
      }
      elsif ($in_prices{0} > 0 && $out_prices{0} > 0) {
        $trafic_limits{0} = ($deposit / (($in_prices{0} + $out_prices{0}) / 2));
      }
      elsif ($in_prices{0} > 0 && $out_prices{0} == 0) {
        $trafic_limits{0} = ($deposit / $in_prices{0});
      }
      elsif ($in_prices{0} == 0 && $out_prices{0} > 0) {
        $trafic_limits{0} = ($deposit / $out_prices{0});
      }

      # Check extended prepaid traffic
      if ($prepaids{1}) {
        if (($used_traffic->{TRAFFIC_COUNTER_2} < $prepaids{1})) {
          $trafic_limits{1} = $prepaids{1} - $used_traffic->{TRAFFIC_COUNTER_2};
        }
        elsif ($in_prices{1} > 0 && $out_prices{1} > 0) {
          $trafic_limits{1} = ($deposit / (($in_prices{1} + $out_prices{1}) / 2));
        }
        elsif ($in_prices{1} > 0 && $out_prices{1} == 0) {
          $trafic_limits{1} = ($deposit / $in_prices{1});
        }
        elsif ($in_prices{1} == 0 && $out_prices{1} > 0) {
          $trafic_limits{1} = ($deposit / $out_prices{1});
        }
      }
    }

    #Use expresion
    my $RESULT = $Billing->expression(
      $self->{UID},
      \%expr,
      {
        START_PERIOD => $self->{ACTIVATE},
        debug        => 0,
        TI_ID        => $self->{TT_INTERVAL}
      }
    );

    if ($RESULT->{TRAFFIC_LIMIT}) {
      $trafic_limits{0} = $RESULT->{TRAFFIC_LIMIT} - $used_traffic->{TRAFFIC_COUNTER};
    }

    if ($RESULT->{SPEED}) {
      $EX_PARAMS{speed}{0}{IN}  = $RESULT->{SPEED};
      $EX_PARAMS{speed}{0}{OUT} = $RESULT->{SPEED};
      $EX_PARAMS{ex_speed}      = $RESULT->{SPEED};
    }
    else {
      if ($RESULT->{SPEED_IN}) {
        $EX_PARAMS{speed}{0}{IN} = $RESULT->{SPEED_IN};
      }
      if ($RESULT->{SPEED_OUT}) {
        $EX_PARAMS{speed}{0}{OUT} = $RESULT->{SPEED_OUT};
      }
    }

    #End expresion
  }
  else {
    if ($in_prices{0} && $in_prices{0} > 0 && $out_prices{0} > 0) {
      $trafic_limits{0} = ($deposit / (($in_prices{0} + $out_prices{0}) / 2));
    }
    elsif ($in_prices{0} && $in_prices{0} > 0 && $out_prices{0} == 0) {
      $trafic_limits{0} = ($deposit / $in_prices{0});
    }
    elsif ($in_prices{0} && $in_prices{0} == 0 && $out_prices{0} > 0) {
      $trafic_limits{0} = ($deposit / $out_prices{0});
    }

    if (defined($in_prices{1})) {
      if ($in_prices{1} > 0 && $out_prices{1} > 0) {
        $trafic_limits{1} = ($deposit / (($in_prices{1} + $out_prices{1}) / 2));
      }
      elsif ($in_prices{1} > 0 && $out_prices{1} == 0) {
        $trafic_limits{1} = ($deposit / $in_prices{1});
      }
      elsif ($in_prices{1} == 0 && $out_prices{1} > 0) {
        $trafic_limits{1} = ($deposit / $out_prices{1});
      }
    }
    else {
      $trafic_limits{1} = 0;
    }
  }

  #Traffic limit
  #2Gb - (2048 * 1024 * 1024 ) - global traffic session limit
  if ($trafic_limits{0} && $trafic_limits{0} > 0) {
    if ($trafic_limits{0} < $EX_PARAMS{traf_limit}) {
      my $trafic_limit = $trafic_limits{0};
      $EX_PARAMS{traf_limit} = ($trafic_limit < 1 && $trafic_limit > 0) ? 1 : int($trafic_limit);
      if ($self->{REDUCTION} && $self->{REDUCTION} < 100) {
        $EX_PARAMS{traf_limit} = $EX_PARAMS{traf_limit} * (100 / (100 - $self->{REDUCTION}));
      }
    }
    elsif($EX_PARAMS{traf_limit} == 0) {
      $EX_PARAMS{traf_limit} = $trafic_limits{0};
    }
  }

  #Local Traffic limit
  if (defined($trafic_limits{1}) && $trafic_limits{1} > 0) {
    $EX_PARAMS{traf_limit_lo} = int($trafic_limits{1});
  }

  return \%EX_PARAMS;
}

#*******************************************************************
=head2 get_ip($nas_num, $nas_ip, $attr) - Get IP for user

  Arguments:
   $nas_num  - NAS id
   $nas_ip   - NAS IP
   $attr
     TP_IPPOOL - TP ip pool id
     GUEST
     SERVER_VLAN - Get Pool with VLAN
     VLAN

  Returns:

   -2 - No Free Address in TP pool
   -1 - No free address in nas pool
    0 - No address pool using nas servers ip address
   192.168.101.1 - assign ip address

=cut
#*******************************************************************
sub get_ip {
  my $self = shift;
  my ($nas_num, $nas_ip, $attr) = @_;
  my $guest_mode = $self->{GUEST} || $attr->{GUEST} || 0;

  if($self->{conf}->{GET_IP2}) {
    return $self->get_ip2($nas_num, $nas_ip, $attr);
  }

  my $guest = ($guest_mode) ? "AND guest=$guest_mode" : "AND guest=0" ;
  my $extra_params = '';
  if($attr->{SERVER_VLAN} && $attr->{VLAN}) {
    $extra_params = " AND (server_vlan='$attr->{SERVER_VLAN}' AND vlan='$attr->{VLAN}') ";
  }

  #Get reserved IP with status 11
  my $user_name = $self->{USER_NAME} || '';
  if (! $self->{LOGINS} || ($guest_mode && $user_name)) {
    my $status = ($guest_mode) ? q{AND status<>2} : q{AND status=11};
    $self->query2("SELECT INET_NTOA(framed_ip_address) AS ip
       FROM internet_online
       WHERE user_name='$user_name'
         $status
         AND nas_id='$nas_num'
         AND framed_ip_address > 0
         $guest $extra_params;");

    if ($self->{TOTAL} > 0) {
      my $ip = $self->{list}->[0]->[0];
      $self->query2("SELECT INET_NTOA(netmask) AS netmask,
        dns,
        ntp,
        INET_NTOA(gateway) AS gateway,
        id
      FROM ippools
      WHERE ip<=INET_ATON('$ip') AND INET_ATON('$ip')<=ip+counts
      ORDER BY netmask
      LIMIT 1", undef, { INFO => 1 });

      return $ip;
    }
  }

  delete $self->{GATEWAY};
  delete $self->{DNS};
  delete $self->{NTP};

  if ($self->{NETMASK} && $self->{NETMASK} eq '255.255.255.255') {
    delete $self->{NETMASK};
  }

  if ($attr->{TP_IPPOOL}) {
    $self->query2("SELECT ippools.ip, ippools.counts, ippools.id, ippools.next_pool_id,
      IF(ippools.gateway > 0, INET_NTOA(ippools.gateway), 0),
      IF(ippools.netmask > 0, INET_NTOA(ippools.netmask), ''), dns, ntp
    FROM ippools
    WHERE ippools.id='$attr->{TP_IPPOOL}'
    ORDER BY ippools.priority;"
    );

    delete ($attr->{TP_IPPOOL});
  }
  else {
    my $WHERE = q{};
    if($guest_mode) {
      #Only guest pool
      #$WHERE = "AND ippools.guest=1";
      if($attr->{SERVER_VLAN}) {
        $WHERE .= " AND (ippools.vlan='$attr->{SERVER_VLAN}' OR ippools.vlan=0)";
      }

      if(! $self->{UID}) {
        $WHERE .= $guest;
      }
      #Get Real NET IP for guest session
      else {
        $WHERE .= " AND guest=0";
      }
    }
    else {
      $WHERE .= $guest;

      if($CONF->{AUTH_VLAN_FOR_IP} && $attr->{SERVER_VLAN}) {
        $WHERE .= " AND (ippools.vlan='$attr->{SERVER_VLAN}')";
      }
    }

    $self->query2("SELECT ippools.ip, ippools.counts, ippools.id, ippools.next_pool_id,
       IF(ippools.gateway > 0, INET_NTOA(ippools.gateway), ''),
       IF(ippools.netmask > 0, INET_NTOA(ippools.netmask), ''), dns, ntp
     FROM ippools, nas_ippools
     WHERE ippools.id=nas_ippools.pool_id
       AND nas_ippools.nas_id='$nas_num'
       $WHERE
     ORDER BY ippools.priority;"
    );
  }

  if ($self->{TOTAL} < 1) {
    return 0;
  }

  my @pools_arr      = ();
  my $pool_list      = $self->{list};
  my @used_pools_arr = ();
  my $next_pool_id   = 0;
  my %poolss         = ();
  my %pool_info      = ();

  foreach my $line (@$pool_list) {
    my $sip   = $line->[0];
    my $count = $line->[1];
    my $id    = $line->[2];
    $next_pool_id = $line->[3];
    $pool_info{$id}{GATEWAY}=$line->[4];
    $pool_info{$id}{NETMASK}=$line->[5];
    $pool_info{$id}{DNS}=$line->[6];
    $pool_info{$id}{NTP}=$line->[7];

    push @used_pools_arr, $id;
    my %pools = ();

    for (my $i = $sip ; $i < $sip + $count ; $i++) {
      $pools{$i} = 1;
    }

    if ($CONF->{unite_ip_pools}) {
      %poolss = (%poolss, %pools)
    }
    else {
      push @pools_arr, \%pools;
      if($next_pool_id) {
        last;
      }
    }
  }

  if ($CONF->{unite_ip_pools}) {
    push @pools_arr, \%poolss;
  }

  my $used_pools = join(', ', @used_pools_arr);

  #Lock table for read
  my DBI $db_ =  $self->{db}{db};
  $db_->do('lock tables internet_online as c read, nas_ippools as np read, internet_online write');
  #get active address and delete from pool
  # Select from active users and reserv ips
  $self->query2("SELECT DISTINCT(c.framed_ip_address)
    FROM internet_online c
    INNER JOIN nas_ippools np ON (c.nas_id=np.nas_id)
    WHERE np.pool_id in ( $used_pools );"
  );

  my $list = $self->{list};
  $self->{USED_IPS} = 0;

  my %pool = %{ $pools_arr[0] };
  my $active_pool = 0;
  for (my $i = 0 ; $i <= $#pools_arr ; $i++) {
    %pool = %{ $pools_arr[$i] };
    foreach my $ip (@$list) {
      if (exists($pool{ $ip->[0] })) {
        delete($pool{ $ip->[0] });
        $self->{USED_IPS}++;
      }
    }
    $active_pool = $used_pools_arr[$i];
    last if (scalar(keys %pool) > 0);
  }

  my @ips_arr = keys %pool;
  my $assign_ip = ($#ips_arr > -1) ? $ips_arr[ rand($#ips_arr + 1) ] : undef;

  if ($assign_ip) {
    # Make reserv ip
    if (! $attr->{SKIP_RESERV}) {
      $self->online_add({
        %$attr,
        NAS_ID            => $nas_num,
        FRAMED_IP_ADDRESS => $assign_ip,
        NAS_IP_ADDRESS    => $nas_ip
      });
    }

    $db_->do('unlock tables');
    if( $self->{errno} ) {
      return -1;
    }
    else {
      my $w=($assign_ip/16777216)%256;
      my $x=($assign_ip/65536)%256;
      my $y=($assign_ip/256)%256;
      my $z=$assign_ip%256;

      if($pool_info{$active_pool}) {
        $self->{GATEWAY} = $pool_info{$active_pool}{GATEWAY};
        if(! $self->{NETMASK}) {
          $self->{NETMASK} = $pool_info{$active_pool}{NETMASK};
        }
        $self->{DNS} = $pool_info{$active_pool}{DNS};
        $self->{NTP} = $pool_info{$active_pool}{NTP};
      }

      return "$w.$x.$y.$z";
    }
  }
  else {    # no addresses available in pools
    $db_->do('unlock tables');
    if($next_pool_id) {
      return $self->get_ip($nas_num, $nas_ip, { TP_IPPOOL => $next_pool_id });
    }
    elsif ($attr->{TP_IPPOOL}) {
      return $self->get_ip($nas_num, $nas_ip, $attr);
    }
    else {
      return -1;
    }
  }
  #return 0;
}


#*******************************************************************
=head2 get_ip2($nas_num, $nas_ip, $attr) - Get IP for user

  Arguments:
   $nas_num  - NAS id
   $nas_ip   - NAS IP
   $attr
     TP_IPPOOL - TP ip pool id
     GUEST
     SERVER_VLAN

  Returns:

   -2 - No Free Address in TP pool
   -1 - No free address in nas pool
    0 - No address pool using nas servers ip address
   192.168.101.1 - assign ip address

=cut
#*******************************************************************
sub get_ip2 {
  my $self = shift;
  my ($nas_num, $nas_ip, $attr) = @_;

  my $guest_mode = $self->{GUEST} || $attr->{GUEST} || 0;
  my $guest = ($guest_mode) ? "AND guest=$guest_mode" : "AND guest=0" ;

  #Get reserved IP with status 11
  my $user_name = $self->{USER_NAME} || '';
  if (! $self->{LOGINS} || ($guest_mode && $user_name)) {
    my $status = ($guest_mode) ? q{AND status<>2} : q{AND status=11};
    $self->query2("SELECT INET_NTOA(framed_ip_address) AS ip
       FROM internet_online
       WHERE user_name='$user_name'
         $status
         AND nas_id='$nas_num'
         AND framed_ip_address > 0
         $guest;");

    if ($self->{TOTAL} > 0) {
      my $ip = $self->{list}->[0]->[0];
      $self->query2("SELECT INET_NTOA(netmask) AS netmask,
        dns,
        ntp,
        INET_NTOA(gateway) AS gateway,
        id
      FROM ippools
      WHERE ip<=INET_ATON('$ip') AND INET_ATON('$ip')<=ip+counts
      ORDER BY netmask
      LIMIT 1", undef, { INFO => 1 });

      return $ip;
    }
  }

  delete $self->{GATEWAY};
  delete $self->{NETMASK};
  delete $self->{DNS};
  delete $self->{NTP};
  my $WHERE = q{};

  if ($attr->{TP_IPPOOL}) {
    $WHERE = "ippools.id='$attr->{TP_IPPOOL}'";
    delete ($attr->{TP_IPPOOL});
  }
  else {
    $WHERE = "nas_ippools.nas_id = '$nas_num'";
    if($guest_mode) {
      #Only guest pool
      $WHERE .= " AND ippools.guest=$guest_mode";
      if($attr->{SERVER_VLAN}) {
        $WHERE .= " AND ippools.vlan='$attr->{SERVER_VLAN}'";
      }
    }
    else {
      $WHERE .= " AND ippools.guest=0";
    }
  }

  my $next_pool_id = 0;

  #Lock table for read
  my DBI $db_ =  $self->{db}{db};
  $db_->do('LOCK TABLES internet_online AS c read,
     internet_online write,
     ippools_ips AS pool read,
     ippools read,
     nas_ippools read');

  #get active address and delete from pool  Select from active users and reserv ips
  $self->query2("SELECT INET_NTOA(pool.ip) AS pool_ip,
       pool.ippool_id,
       IF(ippools.gateway > 0, INET_NTOA(ippools.gateway), ''),
       IF(ippools.netmask > 0, INET_NTOA(ippools.netmask), ''),
       dns,
       ntp
    FROM ippools_ips pool
    INNER JOIN ippools ON (pool.ippool_id = ippools.id)
    INNER JOIN nas_ippools ON (ippools.id = nas_ippools.pool_id)
    LEFT JOIN internet_online c ON (pool.ip = c.framed_ip_address)
    WHERE
      $WHERE
      AND c.framed_ip_address IS NULL
    ORDER BY ippools.priority
    LIMIT 1;");

  my $assign_ip = undef;

  if($self->{TOTAL} && $self->{TOTAL}  == 1) {
    $assign_ip = $self->{list}->[0]->[0];
    #$active_pool = $self->{list}->[0]->[1];
    $self->{GATEWAY} = $self->{list}->[0]->[2];
    $self->{NETMASK} = $self->{list}->[0]->[3];
    $self->{DNS} = $self->{list}->[0]->[4];
    $self->{NTP} = $self->{list}->[0]->[5];
  }
  else {
    $self->query2("SELECT COUNT(*) AS used_ips
    FROM ippools_ips pool
    LEFT JOIN internet_online c ON (pool.ip=c.framed_ip_address)
    WHERE c.framed_ip_address IS NOT NULL;");
    $self->{USED_IPS} = $self->{list}->[0]->[0];
  }

  if ($assign_ip) {
    # Make reserv ip
    if (! $attr->{SKIP_RESERV}) {
      $self->online_add({
        %$attr,
        NAS_ID            => $nas_num,
        FRAMED_IP_ADDRESS => "INET_ATON('". $assign_ip . "')",
        NAS_IP_ADDRESS    => $nas_ip
      });
    }

    $db_->do('UNLOCK TABLES');

    if( $self->{errno} ) {
      return -1;
    }
    else {
      return $assign_ip;
    }
  }
  else {    # no addresses available in pools
    $db_->do('UNLOCK TABLES');
    if($next_pool_id) {
      return $self->get_ip2($nas_num, $nas_ip, { TP_IPPOOL => $next_pool_id });
    }
    elsif ($attr->{TP_IPPOOL}) {
      return $self->get_ip2($nas_num, $nas_ip, $attr);
    }
    else {
      $self->{TOTAL}=-1;
      return 0;
      #return -1;
    }
  }
}

#*******************************************************************
=head2 online_add($attr) - Add session to internet_online

=cut
#*******************************************************************
sub online_add {
  my $self=shift;
  my ($attr)=@_;

  my %insert_hash = (
    user_name           => $self->{USER_NAME},
    uid                 => $self->{UID} || 0,
    nas_id              => $attr->{NAS_ID},
    nas_port_id         => $attr->{NAS_PORT_ID},
    tp_id               => $self->{TP_ID},
    join_service        => $self->{JOIN_SERVICE},
    guest               => $attr->{GUEST},
    cid                 => $attr->{CID},
    connect_info        => $attr->{CONNECT_INFO},
    #nas_ip_address  => $attr->{NAS_IP_ADDRESS},
    framed_ip_address   => $attr->{FRAMED_IP_ADDRESS},
    service_id          => $self->{SERVICE_ID},
    server_vlan         => $attr->{SERVER_VLAN} || $self->{SERVER_VLAN},
    vlan                => $attr->{VLAN} || $self->{VLAN},
    framed_ipv6_prefix  => $attr->{FRAMED_IPV6_PREFIX},
    framed_interface_id => $attr->{FRAMED_INTERFACE_ID},
    delegated_ipv6_prefix=>$attr->{DELEGATED_IPV6_PREFIX},
    dhcp_id             => $CONF->{DHCP_ID},
    switch_port         => $attr->{PORT} || $self->{PORT},
    switch_mac          => $attr->{NAS_MAC} || $self->{NAS_MAC}
  );

  # if (! $attr->{NAS_ID}) {
  #   `echo "$self->{USER_NAME} nas_id: $attr->{NAS_ID} guest:  $attr->{GUEST} " >> /tmp/nas_id`;
  # }

  my $sql = "INSERT INTO internet_online SET started=NOW(),
     lupdated        = UNIX_TIMESTAMP(),
     status          = '11',
     acct_session_id = '". ($attr->{ACCT_SESSION_ID} || 'IP') ."',
     nas_ip_address  = INET_ATON('". ($attr->{'NAS_IP_ADDRESS'} || '0.0.0.0') ."')";

  while(my ($k, $v) = each %insert_hash) {
    next if (! $v);
    if($k eq 'framed_ip_address') {
      $sql .= ", $k=$v";
    }
    elsif($k eq 'framed_ipv6_prefix') {
      $sql .= ", $k=$v";
    }
    elsif($k eq 'delegated_ipv6_prefix') {
      $sql .= ", $k=$v";
    }
    else {
      $sql .= ", $k='$v'";
    }
  }

  if($CONF->{AUTH_DEBUG}) {
    print $sql . "\n";
  }

  $self->query2($sql, 'do');

  return $self;
}


#********************************************************************
=head2 check_systemauth($user, $password) - System auth function

=cut
#********************************************************************
sub check_systemauth {
  my ($user, $password) = @_;

  if ($< != 0) {
    Log::log_print('LOG_ERR', "For system Authentification you need root privileges");
    return 1;
  }

  my @pw = getpwnam("$user");

  if ($#pw < 0) {
    return 0;
  }

  my $salt = "$pw[1]";
  my $ep = crypt($password, $salt);

  if ($ep eq $pw[1]) {
    return 1;
  }
  else {
    return 0;
  }
}

#*******************************************************************
=head2 check_chap($given_password,$want_password,$given_chap_challenge) - Check chap password

=cut
#*******************************************************************
sub check_chap {
  my ($given_password, $want_password, $given_chap_challenge) = @_;

  eval { require Digest::MD5; };
  if (!$@) {
    Digest::MD5->import();
  }
  else {
    Log::log_print('LOG_ERR', "Can't load 'Digest::MD5' check http://www.cpan.org");
    return 0;
  }

  $given_password       =~ s/^0x//;
  $given_chap_challenge =~ s/^0x//;
  my $chap_password  = pack("H*", $given_password);
  my $chap_challenge = pack("H*", $given_chap_challenge);
  my $md5            = Digest::MD5->new();
  $md5->reset;
  $md5->add(substr($chap_password, 0, 1));
  $md5->add($want_password);
  $md5->add($chap_challenge);
  my $digest = $md5->digest();

  if ($digest eq substr($chap_password, 1)) {
    return 1;
  }
  else {
    return 0;
  }

}

#*******************************************************************
=head2 pre_auth($RAD, $attr) - Authorization module

=cut
#*******************************************************************
sub pre_auth {
  my $self = shift;
  my ($RAD) = @_;

  if ($RAD->{'MS-CHAP-Challenge'} || $RAD->{'EAP-Message'}) {
    my $login = $RAD->{'User-Name'} || '';
    if ($login =~ /:(.+)/) {
      $login = $1;
    }

    if ($CONF->{INTERNET_PASSWORD}) {
      my $WHERE = '';
      if ($CONF->{INTERNET_LOGIN}) {
        $WHERE = "internet_main.login='". $login ."'";
      }
      else {
        $WHERE = "users.id='". $login ."'";
      }

      $self->query2("SELECT DECODE(internet_main.password, '$CONF->{secretkey}') AS password
        FROM internet_main
        LEFT JOIN users ON (users.uid=internet_main.uid)
        WHERE $WHERE;");

      if(! $self->{list}->[0]->[0]) {
        $self->query2("SELECT DECODE(password, '$CONF->{secretkey}') FROM users WHERE id= ?;",
          undef,
          { Bind => [ $login ] });
      }
    }
    else {
      $self->query2("SELECT DECODE(password, '$CONF->{secretkey}') FROM users WHERE id= ?;",
        undef,
        { Bind => [ $login ] });
    }

    if ($self->{TOTAL} > 0) {
      my $list     = $self->{list}->[0];
      my $password = $list->[0];

      $self->{'RAD_CHECK'}{'Cleartext-Password'} = "$password";

      return 0;
    }

    $self->{errno}  = 1;
    $self->{errstr} = "USER: '$login' NOT_EXIST";
    return 1;
  }

  $self->{'RAD_CHECK'}{'Auth-Type'} = "Accept";

  return 0;
}

#**********************************************************
=head2 neg_deposit_filter_former($RAD, $NAS, $NEG_DEPOSIT_FILTER_ID, $attr)

  Arguments:
    $RAD  -
    $NAS  -
    $NEG_DEPOSIT_FILTER_ID
    $attr -
       RAD_PAIRS   - Rad pairs
       MESSAGE     - Info message
       FILTER_TYPE - (see %connect_errors_ids)
       NEG_DEPOSIT_IPPOOL
       VLAN        - Guest pool by vlan

  Returns:
    result, $RAD_PAIRS

=cut
#**********************************************************
sub neg_deposit_filter_former {
  my $self = shift;
  my ($RAD, $NAS, $NEG_DEPOSIT_FILTER_ID, $attr) = @_;

  my $RAD_PAIRS;
  if ($attr->{RAD_PAIRS}) {
    $RAD_PAIRS = $attr->{RAD_PAIRS};
  }
  else {
    undef $RAD_PAIRS;
  }

  if(! $NEG_DEPOSIT_FILTER_ID) {
    $RAD_PAIRS->{'Reply-Message'} = $attr->{MESSAGE};
    return 1, $RAD_PAIRS;
  }

  $RAD_PAIRS->{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE} if ($NAS->{NAS_ALIVE});

  $self->{IP} //= 0;

  if (!$attr->{USER_FILTER}) {
    # Return radius attr
    if (($self->{IP} ne '0' && $CONF->{INTERNET_GUEST_STATIC_IP}) || $RAD->{'Framed-IP-Address'}) { # || !$self->{NEG_DEPOSIT_IPPOOL})) {
      #print "($self->{IP} ne '0' && ( $CONF->{INTERNET_GUEST_STATIC_IP} || !$self->{NEG_DEPOSIT_IPPOOL}))\n\n";
      if(! $attr->{SKIP_ADD_IP}) {
        $RAD_PAIRS->{'Framed-IP-Address'} = $RAD->{'Framed-IP-Address'} || $self->{IP};
        $self->online_add({
          %$attr,
          IP                 => $RAD_PAIRS->{'Framed-IP-Address'},
          NAS_ID             => $NAS->{NAS_ID},
          FRAMED_IP_ADDRESS  => "INET_ATON('$self->{IP}')",
          NAS_IP_ADDRESS     => $RAD->{'NAS-IP-Address'},
          #FRAMED_IPV6_PREFIX => $RAD->{'Framed-IPv6-Prefix'},
          #FRAMED_INTERFACE_ID=> $RAD->{'Framed-Interface-Id'},
          GUEST              => 1,
          CONNECT_INFO       => '-'
        });
      }
    }
    elsif(! $attr->{SKIP_ADD_IP}) {
      my $ip = $self->get_ip($NAS->{NAS_ID}, $RAD->{'NAS-IP-Address'},
        {
          %$attr,
          TP_IPPOOL    => $self->{NEG_DEPOSIT_IPPOOL} || $self->{TP_IPPOOL},
          GUEST        => 1,
          SERVER_VLAN  => $self->{SERVER_VLAN}, #$self->{VLAN}
          VLAN         => $self->{VLAN},
          CONNECT_INFO => $self->{IP}
        });

      if ($ip eq '-1') {
        $RAD_PAIRS->{'Reply-Message'} = "NO_FREE_NEG_POOL_IP (USED: $self->{USED_IPS}) " . (($self->{TP_IPPOOL}) ? " TP_IPPOOL: $self->{TP_IPPOOL}" : '');
        return 1, $RAD_PAIRS;
      }
      elsif ($ip eq '0') {
#        if($self->{IP}) {
#          $self->online_add({
#            %$attr,
#            NAS_ID            => $NAS->{NAS_ID},
#            FRAMED_IP_ADDRESS => "INET_ATON('$self->{IP}')",
#            NAS_IP_ADDRESS    => $RAD->{'NAS-IP-Address'},
#            GUEST             => 1
#          });
#        }
      }
      else {
        $RAD_PAIRS->{'Framed-IP-Address'} = $ip;
      }
    }

    $self->{INFO} .= ($self->{INFO}) ? ' NEG_FILTER' : 'NEG_FILTER';
    if($RAD_PAIRS->{'Reply-Message'}) {
      $RAD_PAIRS->{'Reply-Message'} .= ' GUEST';
    }

    if ($attr->{MESSAGE}) {
      $self->{INFO} .= ' '.$attr->{MESSAGE};
    }
  }

  $NEG_DEPOSIT_FILTER_ID =~ s/{IP}/$RAD_PAIRS->{'Framed-IP-Address'}/g;
  $NEG_DEPOSIT_FILTER_ID =~ s/{LOGIN}/$RAD->{'User-Name'}/g;

  if ($NEG_DEPOSIT_FILTER_ID =~ /RAD:/) {
    rad_pairs_former($NEG_DEPOSIT_FILTER_ID, $attr);
  }
  else {
    $RAD_PAIRS->{'Filter-Id'} = $NEG_DEPOSIT_FILTER_ID;
  }

  $self->{GUEST_MODE}=1 if (! $attr->{USER_FILTER});

  if ($attr->{USER_FILTER}) {
    return 0;
  }

  $self->nas_pair_former({
    RAD_PAIRS => $RAD_PAIRS,
    RAD       => $RAD,
    NAS       => $NAS,
    GUEST     => 1
  });

  return 0, $RAD_PAIRS;
}

#**********************************************************
=head2 rad_pairs_former($content, $attr) - Forming RAD pairs

  Arguments:
    $content - Filter content
    $attr
      RAD_PAIRS - HASH_REF of return rad pairs

  Returns:
    Result  TRUE or FALSE
    HAS_REF of formed rad reply

  Example:
    rad_pairs_former( $self->{NEG_DEPOSIT_FILTER_ID}, { RAD_PAIRS => \%RAD_REPLY } );

=cut
#**********************************************************
sub rad_pairs_former  {
  my ($content, $attr) = @_;

  $content =~ s/\r//g;
  $content =~ s/RAD://g;
  my @p = split(/,[ \n]+/, $content);

  my $RAD_PAIRS;
  if ($attr->{RAD_PAIRS}) {
    $RAD_PAIRS = $attr->{RAD_PAIRS};
  }

  foreach my $line (@p) {
    if ($line =~ /([a-zA-Z0-9\-:]{6,25})\s?\+\=\s?(.{1,200})/) {
      my $left  = $1;
      my $right = $2;
      #$right =~ s/\"//g;
      push(@{ $RAD_PAIRS->{"$left"} }, $right);
    }
    else {
      my ($left, $right) = split(/=/, $line, 2);
      $left=~s/^ //g;
      if ($left =~ s/^!//) {
        delete $RAD_PAIRS->{"$left"};
      }
      else {
        #next if (! $self->{"$left"});
        next if (! defined($right));
        $RAD_PAIRS->{"$left"} = $right;
      }
    }
  }

  return 0, $RAD_PAIRS;
}


#**********************************************************
=head1 opt82_parse($RAD_REQUEST, $attr) - Parse option 82

  Parsing information:
    Circuit-Id - VLAN,PORT
    Remote-Id  - NAS_MAC

  Arguments:
    $RAD_REQUEST
    $attr
      AUTH_EXPR
        NAS_MAC, PORT (convert from hex), PORT_MULTI (not converted), PORT_DEC (dec port value), VLAN,
        SERVER_VLAN, SERVER_VLAN_DEC, VLAN, VLAN_DEC, AGENT_REMOTE_ID, CIRCUIT_ID, LOGIN, USER_MAC

  Returns:
    RESULTS - hash_ref
      NAS_MAC, PORT, VLAN, SERVER_VLAN, AGENT_REMOTE_ID, CIRCUIT_ID, LOGIN, USER_MAC

  Conf:
    $conf{AUTH_EXPR}='';

  Usefull info:
    http://tools.ietf.org/html/rfc4243
    http://tools.ietf.org/html/rfc3046#section-7

=cut
#**********************************************************
sub opt82_parse {
  my $self = shift;
  my ($RAD_REQUEST, $attr) = @_;

  my %result      =  ();
  #my $hex2ansii   = '';
  my @o82_expr_arr = ();

  if($self->{conf}) {
    $CONF = $self->{conf};
  }

  my $auth_expr = $attr->{AUTH_EXPR} || $CONF->{AUTH_EXPR} || q{};
  # if($attr->{AUTH_EXPR}) {
  #   $CONF->{AUTH_EXPR}=$attr->{AUTH_EXPR};
  # }

  if ($auth_expr) {
    $auth_expr =~ s/\n//g;
    @o82_expr_arr    = split(/;/, $auth_expr);
  }

  if ($#o82_expr_arr > -1) {
    my $expr_debug  =  "";
    foreach my $expr (@o82_expr_arr) {
      my ($parse_param, $expr_, $values, $attribute)=split(/:/, $expr);
      my @EXPR_IDS = split(/,/, $values);
      if ($RAD_REQUEST->{$parse_param}) {

        my $input_value = $RAD_REQUEST->{$parse_param};
        if ($attribute && $attribute eq 'hex2ansii') {
          #$hex2ansii   = 1;
          $input_value =~ s/^0x//;
          $input_value = pack 'H*', $input_value;
        }

        if ($CONF->{AUTH_EXPR_DEBUG} && $CONF->{AUTH_EXPR_DEBUG} > 3) {
          $expr_debug  .=  ($RAD_REQUEST->{'DHCP-Client-Hardware-Address'} || q{}) .": $parse_param, $expr_, $RAD_REQUEST->{$parse_param}/$input_value\n";
        }

        if (my @res = ($input_value =~ /$expr_/i)) {
          for (my $i=0; $i <= $#res ; $i++) {
            if ($CONF->{AUTH_EXPR_DEBUG} && $CONF->{AUTH_EXPR_DEBUG} > 3) {
              $expr_debug .= "  $EXPR_IDS[$i] / $res[$i]\n";
            }

            $result{$EXPR_IDS[$i]}=$res[$i];
          }

          if ($attribute && $attribute eq 'increment_port') { #for H3C: it sends port decremented by 1 (e. g. 6 instead of 7)
            my $port = $result{PORT_DEC} || hex($result{PORT} || 0);
            $port++;
            $result{PORT_MULTI} = $port; #sets PORT_MULTI (will be returned as is, without convertation)

            if ($CONF->{AUTH_EXPR_DEBUG} && $CONF->{AUTH_EXPR_DEBUG} > 3) {
              $expr_debug .= "  attribute increment_port: new port value is $port\n";
            }
          }

          #last;
        }
      }

#      if ($parse_param eq 'DHCP-Relay-Agent-Information') {
#        $result{AGENT_REMOTE_ID} = substr($RAD_REQUEST->{$parse_param},0,25);
#        $result{CIRCUIT_ID} = substr($RAD_REQUEST->{$parse_param},25,25);
#      }
#      else {
        $result{AGENT_REMOTE_ID}='-';
        $result{CIRCUIT_ID}='-';
#      }
    }

    if ($result{NAS_MAC} && $result{NAS_MAC} =~ /^([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/i) {
      $result{NAS_MAC} = "$1:$2:$3:$4:$5:$6";
    }

    if ($result{USER_MAC} && $result{USER_MAC} =~ /^([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/i) {
      $result{USER_MAC} = "$1:$2:$3:$4:$5:$6";
    }

    if ($CONF->{AUTH_EXPR_DEBUG} && $CONF->{AUTH_EXPR_DEBUG} > 2) {
      `echo "$expr_debug" >> /tmp/dhcphosts_expr`;
      if ($CONF->{AUTH_EXPR_DEBUG} > 3) {
        print $expr_debug."-- \n";
      }
    }
  }
  #Default o82 params
  else {
    $result{NAS_MAC} = $RAD_REQUEST->{'Agent-Remote-Id'} || '';
    #  Switch MAC
    if (length($result{NAS_MAC}) == 16) {
      $result{NAS_MAC} .= '00';
    }

    if ($result{NAS_MAC} =~ /0x[a-f0-9]{0,4}([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})/i) {
      $result{NAS_MAC} = "$1:$2:$3:$4:$5:$6";
    }

    #  Switch port
    if ($RAD_REQUEST->{'Agent-Circuit-Id'} && $RAD_REQUEST->{'Agent-Circuit-Id'} =~ /0x0004(\S{4})\d{2}([0-9a-f]{2})/i) {
      $result{VLAN} = $1;
      $result{PORT} = $2;
    }
  }

  $result{VLAN} = $result{VLAN_DEC} || hex($result{VLAN} || 0);
  $result{PORT} = $result{PORT_MULTI} || $result{PORT_DEC} || hex($result{PORT} || 0);
  $result{SERVER_VLAN} = $result{SERVER_VLAN_DEC} || hex($result{SERVER_VLAN} || 0);

  return \%result;
}

#**********************************************************
=head2 dhcp_info($attr, $NAS)

  Arguments:
    $attr
      MAC_AUTH
      IP
      USER_NAME
      NAS_PORT_AUTH

    $NAS


  Results:
    $self
       errno
         2 - Unauth
         3 - Wrong IP

=cut
#**********************************************************
sub dhcp_info {
  my $self = shift;
  my ($attr, $NAS) = @_;

  my @WHERE_RULES = ("u.deleted='0'");
  my $pass_fields = q{};
  # Do nothing if port is magistral, i.e. 25.26.27.28
  # Apply only for reserv ports
  if ($attr->{NAS_PORT} && $NAS->{RAD_PAIRS} && $NAS->{RAD_PAIRS} =~ /Assign-Ports=\"(.+)\"/) {
    my @allow_ports = split(/,/, $1);
    if (! in_array($attr->{NAS_PORT}, \@allow_ports)) {
      $self->{errno}=7;
      $self->{error_str}="WRONG_PORT '$attr->{NAS_PORT}'";
      return $self;
    }
  }

  if($self->{conf}) {
    $self->{conf} = $CONF;
  }

  if ($CONF->{AUTH_IP} && $attr->{IP}) {
    push @WHERE_RULES, "internet.ip=INET_ATON('$attr->{IP}')";
    $self->{INFO} = "AUTH IP '$attr->{IP}'";
  }
  elsif ($attr->{NAS_PORT_AUTH} && ! $attr->{MAC_AUTH}) {
    my $auth_options = "n.mac='$attr->{NAS_MAC}' AND internet.port<>'' AND internet.port='$attr->{PORT}'";

    if($CONF->{NAS_SECOND_MAC_AUTH}) {
      $auth_options = '('. $auth_options .') OR (internet.cid<>\'\' AND internet.cid=\''. $attr->{USER_MAC} ."')";
    }

    push @WHERE_RULES, '(' . $auth_options . ')';
    $self->{INFO} = "NAS_MAC: $attr->{NAS_MAC} PORT: $attr->{PORT} VLAN: $attr->{VLAN} MAC: $attr->{USER_MAC}";
  }
  elsif($attr->{SERVER_VLAN}) {
    push @WHERE_RULES, "internet.vlan='$attr->{VLAN}' AND internet.server_vlan='$attr->{SERVER_VLAN}'";
    $self->{INFO} = "q2q: $attr->{SERVER_VLAN}-$attr->{VLAN} MAC: $attr->{USER_MAC}";
    if ($attr->{NAS_NAME}) {
      push @WHERE_RULES, "n.descr='$attr->{NAS_NAME}'";
      $self->{INFO} .= " NAS_NAME: $attr->{NAS_NAME}";
    }
  }
  elsif ($CONF->{AUTH_PARAMS}) {
    if ($CONF->{AUTH_PARAMS} ne '1') {
      my %AUTH_PARAMS_VALUES = (
        NAS_MAC  => "n.mac",
        USER_MAC => "internet.cid",
        VLAN     => "internet.vlan",
        SERVER_VLAN => "internet.svlan",
        PORT     => "internet.port"
      );

      my @params = split(/,\s?/, $CONF->{AUTH_PARAMS});
      push @WHERE_RULES, join(' AND ',  map { $AUTH_PARAMS_VALUES{$_} .'=\''. $attr->{$_} .'\''  } @params);
    }
    else {
      push @WHERE_RULES, "((n.mac='$attr->{NAS_MAC}' OR n.mac IS null)
      AND (internet.cid='$attr->{USER_MAC}' OR internet.cid='')
      AND (internet.vlan='$attr->{VLAN}' OR internet.vlan='')
      AND (internet.port='$attr->{PORT}' OR internet.port=''))";
    }

    $self->{INFO} = "NAS_MAC: $attr->{NAS_MAC} PORT: $attr->{PORT} VLAN: $attr->{VLAN} MAC: $attr->{USER_MAC}";
  }
  elsif ($CONF->{INTERNET_LOGIN}) {
    push @WHERE_RULES, "internet.login='". $attr->{USER_NAME} ."'";
  }
  # elsif($CONF->{AUTH_INTERNET_CID}) {
  #   push @WHERE_RULES, "internet.cid='". $attr->{USER_MAC} ."'";
  # }
  #Depricated not used
  #  elsif ($attr->{LOGIN}) {
  #    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  #  }
  elsif ($attr->{USER_MAC}) {
    push @WHERE_RULES, "internet.cid='$attr->{USER_MAC}'";
    $self->{INFO} = "USER MAC '$attr->{USER_MAC}'";
    #$pass_fields = "DECODE(". (($CONF->{INTERNET_PASSWORD}) ? 'internet.password' : 'u.password') .", '$CONF->{secretkey}') AS password,";
  }
#  else {
#    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
#  }

  if ($NAS->{DOMAIN_ID}) {
    push @WHERE_RULES,  "u.domain_id='$NAS->{DOMAIN_ID}'";
  }

  my $WHERE = join(' AND ', @WHERE_RULES);

  $self->query2("SELECT
      u.uid,
      u.id AS user_name,
      n.id AS nas_id,
      u.company_id,
      u.disable AS user_disable,
      u.bill_id,
      u.credit,
      internet.activate,
      u.reduction,
      u.ext_bill_id,
      UNIX_TIMESTAMP(u.expire) AS account_expire,
      internet.tp_id,
      internet.disable AS internet_disable,
      IF(internet.ip>0, INET_NTOA(internet.ip), 0) AS ip,
      internet.cid,
      internet.logins,
      internet.filter_id,
      INET_NTOA(internet.netmask) AS netmask,
      $pass_fields
      internet.speed AS user_speed,
      internet.id AS service_id,
      u.disable,
      internet.port,
      internet.vlan

   FROM internet_main internet
   INNER JOIN users u ON (u.uid=internet.uid)
   LEFT JOIN nas n ON (internet.nas_id=n.id)
   WHERE $WHERE;",
    undef,
    { COLS_NAME => 1,
      COLS_UPPER=> 1
    }
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno}    = 2;
    $self->{error_str}= 'USER_NOT_EXIST '.$self->{INFO};
  }
  elsif ($self->{TOTAL} > 1) {
    my $i = 0;
    foreach my $host (@{ $self->{list} }) {
      if($CONF->{AUTH_PARAMS}
        && ! $host->{NAS_ID}
        && ! $host->{CID}
        && ! $host->{VLAN}
        && ! $host->{PORT}) {

      }
      elsif ($attr->{USER_MAC} && uc($attr->{USER_MAC}) eq uc($host->{CID})) {
        #Check IP
        foreach my $p ( keys %{ $self->{list}->[$i] }) {
          $self->{$p} = $self->{list}->[$i]->{$p};
        }

        if($self->{IP}) {
          $self->query2("SELECT INET_NTOA(netmask) AS netmask,
        dns,
        ntp,
        INET_NTOA(gateway) AS gateway,
        id
      FROM ippools
      WHERE ip<=INET_ATON('$self->{IP}') AND INET_ATON('$self->{IP}')<=ip+counts
      ORDER BY netmask
      LIMIT 1", undef, { INFO => 1 });
          #Remove error records if not exist pool
          if($self->{errno}==2) {
            delete $self->{errno};
          }
        }
        return $self;
      }
      $i++
    }

    $self->{errno}    = 2;
    $self->{error_str}= (($self->{error_str}) ? $self->{error_str} :  'USER_NOT_EXIST ') . $self->{INFO};
    $self->{TOTAL}    = 0;
  }
  elsif($self->{TOTAL}==1) {
    foreach my $p ( keys %{ $self->{list}->[0] }) {
      $self->{$p} = $self->{list}->[0]->{$p};
    }

    if($self->{IP}) {
      my $total = $self->{TOTAL};
      $self->query2("SELECT INET_NTOA(netmask) AS netmask,
        dns,
        ntp,
        INET_NTOA(gateway) AS gateway,
        id
      FROM ippools
      WHERE ip<=INET_ATON('$self->{IP}') AND INET_ATON('$self->{IP}')<=ip+counts
      ORDER BY netmask
      LIMIT 1", undef, { INFO => 1 });
      $self->{TOTAL} = $total;
      if($self->{errno}==2) {
        delete $self->{errno};
      }
    }
  }

  if($attr->{IP} && $self->{IP} ne $attr->{IP}) {
    #Validate active sessions
    $self->query2("SELECT uid FROM internet_online
      WHERE framed_ip_address=INET_ATON('$attr->{IP}') AND cid='$attr->{USER_MAC}';");

    if($self->{TOTAL} && $self->{TOTAL} > 0) {
      $self->{IP}=$attr->{IP};
    }
    else {
      $self->{errno} = 12;
      $self->{TOTAL} = 0;
      $self->{error_str} = "WRONG_REQUEST_IP: $attr->{IP}";
    }
  }

  return $self;
}

#**********************************************************
=head2 ipv6_2_long($ipv6) - Convert IPv6 to long format

  Arguments:
    $ipv6

  Returns:
    $ipv6 long format

=cut
#**********************************************************
sub ipv6_2_long {
  my $ipv6 = shift;

  my @list = $ipv6 =~ /([0-9a-f]{1,5})/g;
  my $octets_count = 7 - $#list;

  if($octets_count) {
    my $zero_octets = '';
    for (my $i = 0; $i < $octets_count; $i++) {
      $zero_octets .= ":0000";
    }

    $ipv6 =~ s/\:\:/$zero_octets\:/;
  }

  return $ipv6;
}

1;

