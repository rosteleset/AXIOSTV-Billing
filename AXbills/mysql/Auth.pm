package Auth v7.05.0;

=head1 NAME

  Auth functions

=cut

use strict;
use parent qw(main Exporter);

our @EXPORT  = qw(
  check_chap
  check_company_account
  check_bill_account
  rad_pairs_former
  ex_traffic_params
);

our @EXPORT_OK = qw(
  check_chap
  check_company_account
  check_bill_account
  rad_pairs_former
  ex_traffic_params
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
  10=> 'TIME_EXPIRED' 
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
=head dv_auth($RAD, $NAS, $attr) - VPN / IPoE / Dialup auth

  Arguments:
    $RAD_HASH_REF  - RADIUS PAIRS
    $NAS_HASH_REF  - NAS information object
    $attr          - Extra attributes

  Returns:

=cut
#**********************************************************
sub dv_auth {
  my $self = shift;
  my ($RAD, $NAS, $attr) = @_;

  my ($ret, $RAD_PAIRS);

  if ($NAS->{NAS_TYPE} eq 'accel_ipoe') {
    ($ret, $RAD_PAIRS) = $self->mac_auth($RAD, $NAS, $attr);
  }
  else {
    ($ret, $RAD_PAIRS) = $self->authentication($RAD, $NAS, $attr);
  }

  if ($ret == 1) {
    return 1, $RAD_PAIRS;
  }

  my $MAX_SESSION_TRAFFIC = $CONF->{MAX_SESSION_TRAFFIC} || 0;
  my $DOMAIN_ID = ($NAS->{DOMAIN_ID}) ? "AND tp.domain_id='$NAS->{DOMAIN_ID}'" : "AND tp.domain_id='0'";

  if(! $NAS->{NAS_ID}) {
  	`echo "$NAS->{NAS_ID} / $RAD->{'NAS-IP-Address'} / $RAD->{'User-Name'}" >> /tmp/nas_error`;
  }

  $self->query2("SELECT  IF(dv.logins=0, IF(tp.logins IS NULL, 0, tp.logins), dv.logins) AS logins,
  IF(dv.filter_id != '', dv.filter_id, IF(tp.filter_id IS NULL, '', tp.filter_id)) AS filter,
  IF(dv.ip>0, INET_NTOA(dv.ip), 0) AS ip,
  INET_NTOA(dv.netmask) AS netmask,
  dv.tp_id AS tp_num,
  dv.speed AS user_speed,
  dv.cid,

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

  if (COUNT(un.uid) + COUNT(tp_nas.tp_id) = 0, 0,
    if (COUNT(un.uid)>0, 1, 2)) AS nas,

  UNIX_TIMESTAMP() AS session_start,
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_week,
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year,
  dv.disable,
  tp.max_session_duration,
  tp.payment_type,
  tp.credit_tresshold,
  tp.rad_pairs AS tp_rad_pairs,
  COUNT(i.id) AS intervals,
  tp.age AS account_age,
  dv.callback,
  dv.port,
  tp.traffic_transfer_period,
  tp.neg_deposit_filter_id,
  tp.ext_bill_account,
  tp.credit AS tp_credit,
  tp.ippool AS tp_ippool,
  dv.join_service,
  tp.tp_id,
  tp.active_day_fee,
  tp.neg_deposit_ippool AS neg_deposit_ip_pool,
  dv.expire AS dv_expire
     FROM dv_main dv
     LEFT JOIN tarif_plans tp ON (dv.tp_id=tp.id $DOMAIN_ID)
     LEFT JOIN users_nas un ON (un.uid = dv.uid)
     LEFT JOIN tp_nas ON (tp_nas.tp_id = tp.tp_id)
     LEFT JOIN intervals i ON (tp.tp_id = i.tp_id)
     WHERE dv.uid='$self->{UID}'
       AND (dv.expire='0000-00-00' OR dv.expire > CURDATE())
     GROUP BY dv.uid;",
  undef,
  { INFO => 1 }
  );

  if ($self->{errno}) {
    if($self->{errno} == 2) {
      $RAD_PAIRS->{'Reply-Message'} = "Service not allow or expire";
    }
    else {
      $RAD_PAIRS->{'Reply-Message'} = 'SQL error';
    }
    return 1, $RAD_PAIRS;
  }

  $self->{USER_NAME}=$RAD->{'User-Name'};
  #DIsable
  if ($self->{DISABLE}) {
    #Change status from not active to active
    if ($self->{DISABLE} == 2 && ! $CONF->{DV_DISABLE_AUTO_ACTIVATE}) {
      $self->query2("UPDATE dv_main SET disable=0 WHERE uid='$self->{UID}'", 'do');
    }
    else {
      if ($CONF->{DV_STATUS_NEG_DEPOSIT} && $self->{NEG_DEPOSIT_FILTER_ID}) {
        return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID}, { RAD_PAIRS => $RAD_PAIRS  });
      }
      $RAD_PAIRS->{'Reply-Message'} = "Service Disabled $self->{DISABLE}";
      return 1, $RAD_PAIRS;
    }
  }
  elsif (!$self->{JOIN_SERVICE} && $self->{TP_NUM} < 1) {
    $RAD_PAIRS->{'Reply-Message'} = "No Tarif Selected";
    return 1, $RAD_PAIRS;
  }
  elsif (!defined($self->{PAYMENT_TYPE}) && !$self->{JOIN_SERVICE}) {
    $RAD_PAIRS->{'Reply-Message'} = "Service not allow";
    return 1, $RAD_PAIRS;
  }
  elsif (($RAD_PAIRS->{'Callback-Number'} || $RAD_PAIRS->{'Ascend-Callback'}) && $self->{CALLBACK} != 1) {
    $RAD_PAIRS->{'Reply-Message'} = "Callback disabled";
    return 1, $RAD_PAIRS;
  }

  # Make join service operations
  if ($self->{JOIN_SERVICE}) {
    if ($self->{JOIN_SERVICE} > 1) {
      $self->query2("SELECT
  IF($self->{LOGINS}>0, $self->{LOGINS}, tp.logins) AS logins,
  IF('$self->{FILTER}' != '', '$self->{FILTER}', tp.filter_id) AS filter,
  dv.tp_id AS tp_num,
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
  tp.max_session_duration,
  tp.payment_type,
  tp.credit_tresshold,
  tp.rad_pairs,
  COUNT(i.id) AS intervals,
  tp.age AS account_age,
  tp.traffic_transfer_period,
  tp.neg_deposit_filter_id,
  tp.ext_bill_account,
  tp.credit AS tp_credit,
  tp.ippool AS tp_ip_pool,
  tp.tp_id
     FROM (dv_main dv, tarif_plans tp)
     LEFT JOIN users_nas un ON (un.uid = dv.uid)
     LEFT JOIN tp_nas ON (tp_nas.tp_id = tp.tp_id)
     LEFT JOIN intervals i ON (tp.tp_id = i.tp_id)
     WHERE dv.tp_id=tp.id
         AND dv.uid='$self->{JOIN_SERVICE}'
     GROUP BY dv.uid;",
     undef,
     { INFO => 1 }
      );

      if ($self->{errno}) {
        if($self->{errno} == 2) {
          $RAD_PAIRS->{'Reply-Message'} = "Service not allow";
        }
        else {
          $RAD_PAIRS->{'Reply-Message'} = 'SQL error';
        }
        return 1, $RAD_PAIRS;
      }

      $self->{UIDS} = "$self->{JOIN_SERVICE}";
    }
    else {
      $self->{UIDS} = "$self->{UID}";
      $self->{JOIN_SERVICE}=$self->{UID};
    }

    $self->query2("SELECT uid FROM dv_main WHERE join_service= ? ;", undef, { Bind => [ $self->{JOIN_SERVICE} ] });
    foreach my $line (@{ $self->{list} }) {
      $self->{UIDS} .= ", $line->[0]";
    }
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

    $self->query2("$sql");

    if ($self->{TOTAL} < 1) {
      $RAD_PAIRS->{'Reply-Message'} = "You are not authorized to log in $NAS->{NAS_ID} (". $RAD->{'NAS-IP-Address'} .")";
      return 1, $RAD_PAIRS;
    }
  }

  my $pppoe_pluse = ''; 
  my $ignore_cid  = 0;

  if ($CONF->{DV_PPPOE_PLUSE_PARAM}) {
    my $pppo_pluse_param = $CONF->{DV_PPPOE_PLUSE_PARAM};

  	if($RAD->{$pppo_pluse_param}) {
      $pppoe_pluse = $RAD->{$pppo_pluse_param};

      if ($self->{PORT} && $self->{PORT} !~ /any/i) {
        $ignore_cid  = 1;
      }
      elsif (! $self->{PORT}) {
        $self->query2("UPDATE dv_main SET port='$RAD->{$pppo_pluse_param}' WHERE uid='$self->{UID}';", 'do');
        $self->{PORT}=$RAD->{$pppo_pluse_param};
      }
    }
  }
  else {
    $pppoe_pluse = $RAD->{'NAS-Port'} || '';
  }

  #Check port
  if ($self->{PORT} && $self->{PORT} !~ m/any/i && $self->{PORT} ne $pppoe_pluse) {
    $RAD_PAIRS->{'Reply-Message'} = "Wrong port '$pppoe_pluse'";
    return 1, $RAD_PAIRS;
  }
 
  #Check CID (MAC)
  if ($self->{CID} ne '' && $self->{CID} !~ /ANY/i) {
    if ($NAS->{NAS_TYPE} eq 'cisco' && !$RAD->{'Calling-Station-Id'}) {
    }
    elsif (! $ignore_cid) {
      my $ERR_RAD_PAIRS;
      ($ret, $ERR_RAD_PAIRS) = $self->Auth_CID($RAD);
      return $ret, $ERR_RAD_PAIRS if ($ret == 1);
    }
  }

  #Check  simultaneously logins if needs
  if ($self->{LOGINS} > 0) {
    $self->query2("SELECT CID, INET_NTOA(framed_ip_address) AS ip, nas_id, status FROM dv_calls WHERE user_name= ?
     AND (status <> 2);", undef, { Bind => [ $RAD->{'User-Name'} ] });

    my ($active_logins)  = $self->{TOTAL};
    my $cid              = $RAD->{'Calling-Station-Id'};
    if (length($RAD->{'Calling-Station-Id'}) > 20) {
      $cid = substr($RAD->{'Calling-Station-Id'}, 0, 20);
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
          && ($line->[0] eq $cid && $line->[2] eq $NAS->{NAS_ID})
          && $NAS->{NAS_TYPE} ne 'ipcad'
          )
        {
          $self->query2("UPDATE dv_calls SET status=6 WHERE user_name= ? and CID= ? and status <> 2;", 
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
      $RAD_PAIRS->{'Reply-Message'} = "More then allow login ($self->{LOGINS}/$self->{TOTAL})";
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
      $RAD_PAIRS->{'Reply-Message'} = "Negativ deposit '$self->{DEPOSIT}'";

      #Filtering with negative deposit
      if ($self->{NEG_DEPOSIT_FILTER_ID}) {
        return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID}, { RAD_PAIRS => $RAD_PAIRS });
      }
      else {
        $RAD_PAIRS->{'Reply-Message'} .= " Rejected!";
        return 1, $RAD_PAIRS;
      }
    }
  }
  else {
    $self->{DEPOSIT} = 0;
  }

  if ($self->{INTERVALS} > 0 && ($self->{DEPOSIT} > 0 || $self->{PAYMENT_TYPE} > 0)) {
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
    $RAD_PAIRS->{'Reply-Message'} = "Not Allow day";
    return 1, $RAD_PAIRS;
  }
  elsif ($remaining_time == -2) {
    if ($self->{NEG_DEPOSIT_FILTER_ID}) {
      return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID}, { RAD_PAIRS => $RAD_PAIRS });
    }

    $RAD_PAIRS->{'Reply-Message'} = "Not Allow time";
    $RAD_PAIRS->{'Reply-Message'} .= " Interval: $ATTR->{TT}" if ($ATTR->{TT});
    return 1, $RAD_PAIRS;
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
  my $traf_limit = $MAX_SESSION_TRAFFIC || undef;

  my @direction_sum = ("SUM(sent + recv) / $CONF->{MB_SIZE} + SUM(acct_output_gigawords) * 4096 + SUM(acct_input_gigawords) * 4096",
                       "SUM(recv) / $CONF->{MB_SIZE} + SUM(acct_input_gigawords) * 4096",
                       "SUM(sent) / $CONF->{MB_SIZE} + SUM(acct_output_gigawords) * 4096");

  push @time_limits, $self->{MAX_SESSION_DURATION} if ($self->{MAX_SESSION_DURATION} > 0);

  my %SQL_params = (
    TOTAL => '',
    DAY   => "AND (start >= CONCAT(CURDATE(), ' 00:00:00') AND start<=CONCAT(CURDATE(), ' 24:00:00'))",
    WEEK  => "AND (YEAR(CURDATE())=YEAR(start)) AND (WEEK(CURDATE()) = WEEK(start))",
    MONTH => "AND (start >= DATE_FORMAT(curdate(), '%Y-%m-01 00:00:00') AND start<=DATE_FORMAT(curdate(), '%Y-%m-31 24:00:00'))"
  );

  my $WHERE = "uid='$self->{UID}'";
  if ($self->{UIDS}) {
    $WHERE = "uid IN ($self->{UIDS})";
  }
  elsif ($self->{PAYMENT_TYPE} == 2) {
    $WHERE = "CID='". $RAD->{'Calling-Station-Id'} ."'";
  }
  my $online_time;

  foreach my $period (@periods) {
    if (($self->{ $period . '_TIME_LIMIT' } > 0) || ($self->{ $period . '_TRAF_LIMIT' } > 0)) {
      my $session_time_limit = $time_limit;
      my $session_traf_limit = $traf_limit;
      #Get online time
      if(! defined($online_time)) {
        $self->query2("SELECT SUM(UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started))
         FROM dv_calls WHERE $WHERE GROUP BY uid;"
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
         FROM dv_log
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

      if ($self->{ $period . '_TRAF_LIMIT' } && $self->{ $period . '_TRAF_LIMIT' } > 0 && (! $traf_limit || $traf_limit > $session_traf_limit )) {
        $traf_limit = $session_traf_limit;
      }

      if (defined($traf_limit) && $traf_limit <= 0) {
        $RAD_PAIRS->{'Reply-Message'} = "Rejected! $period Traffic limit utilized '$traf_limit Mb'";
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

  if ($self->{ACCOUNT_EXPIRE} && $self->{ACCOUNT_EXPIRE} != 0) {
    my $to_expire = $self->{ACCOUNT_EXPIRE} - $self->{SESSION_START};
    if ($to_expire < $time_limit) {
      $time_limit = $to_expire;
    }
  }

  if ($time_limit > 0) {
    $RAD_PAIRS->{'Session-Timeout'} = ($self->{NEG_DEPOSIT_FILTER_ID} && $time_limit < 5) ? int($time_limit + 600) : $time_limit+1;
  }
  elsif ($time_limit < 0) {
    $RAD_PAIRS->{'Reply-Message'} = "Rejected! Time limit utilized '$time_limit'";

    if ($self->{NEG_DEPOSIT_FILTER_ID}) {
      return $self->neg_deposit_filter_former($RAD, $NAS,
         $self->{NEG_DEPOSIT_FILTER_ID},
         { MESSGE    => $RAD_PAIRS->{'Reply-Message'},
           RAD_PAIRS => $RAD_PAIRS });
    }

    return 1, $RAD_PAIRS;
  }

  if ($NAS->{NAS_TYPE} && $NAS->{NAS_TYPE} eq 'ipcad') {
    # SET ACCOUNT expire date
    if ($self->{ACCOUNT_AGE} > 0 && $self->{DV_EXPIRE} eq '0000-00-00') {
      $self->query2("UPDATE dv_main SET expire=curdate() + INTERVAL $self->{ACCOUNT_AGE} day 
      WHERE uid='$self->{UID}';", 'do'
      );
    }
    return 0, $RAD_PAIRS, '';
  }

  $self->{IP} = $self->{IPOE_IP} if ($self->{IPOE_IP} && $self->{IPOE_IP} ne '0.0.0.0') ;

  # Return radius attr
  if ($self->{IP} ne '0') {
    $RAD_PAIRS->{'Framed-IP-Address'} = "$self->{IP}";
    if (! $self->{REASSIGN}) {
      $self->online_add({
        %$attr,
        NAS_ID            => $NAS->{NAS_ID},
        FRAMED_IP_ADDRESS => "INET_ATON('$self->{IP}')",
        NAS_IP_ADDRESS    => $RAD->{'NAS-IP-Address'},
      });
    }
    delete $self->{REASSIGN};
  }
  else {
    my $ip = $self->get_ip($NAS->{NAS_ID}, $RAD->{'NAS-IP-Address'}, { TP_IPPOOL => $self->{TP_IPPOOL} });
    if ($ip eq '-1') {
      $RAD_PAIRS->{'Reply-Message'} = "Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS})";
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

  $RAD_PAIRS->{'Framed-IP-Netmask'} = $self->{NETMASK} if (defined($RAD_PAIRS->{'Framed-IP-Address'}));

####################################################################
  # Vendor specific return
  #MPD5
  if ($NAS->{NAS_TYPE} eq 'mpd5') {

    if (!$CONF->{mpd_filters}) {

    }
    elsif (!$NAS->{NAS_EXT_ACCT}) {
      if ($self->{USER_SPEED}) {
        if (!$CONF->{ng_car}) {
           my $shapper_type = ($self->{USER_SPEED} > 4048) ? 'rate-limit' : 'shape';
           my $cir    = $self->{USER_SPEED} * 1024;
           my $nburst = int($cir * 1.5 / 8);
           my $eburst = 2 * $nburst;
           push @{ $RAD_PAIRS->{'mpd-limit'} }, "out#1=all $shapper_type $cir $nburst $eburst";
           push @{ $RAD_PAIRS->{'mpd-limit'} }, "in#1=all $shapper_type $cir $nburst $eburst";
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
              push @{ $RAD_PAIRS->{'mpd-limit'} }, "out#$self->{TOTAL}#0=all pass";
            }
            elsif (!$CONF->{ng_car}) {
              my $cir    = $line->[2] * 1024;
              my $nburst = int($cir * 1.5 / 8);
              my $eburst = 2 * $nburst;
              push @{ $RAD_PAIRS->{'mpd-limit'} }, "out#$self->{TOTAL}#0=all $shapper_type $cir $nburst $eburst";
            }

            if ($line->[3] == 0 || $CONF->{ng_car}) {
              push @{ $RAD_PAIRS->{'mpd-limit'} }, "in#$self->{TOTAL}#0=all pass";
            }
            elsif (!$CONF->{ng_car}) {
              my $cir    = $line->[3] * 1024;
              my $nburst = int($cir * 1.5 / 8);
              my $eburst = 2 * $nburst;
              push @{ $RAD_PAIRS->{'mpd-limit'} }, "in#$self->{TOTAL}#0=all $shapper_type $cir $nburst $eburst";
            }
            next;
          }
          elsif ($line->[1]) {
            $line->[1] =~ s/[\n\r]//g;
            my @net_list = split(/;/, $line->[1]);

            my $i = 1;
            $class_id = $class_id * 2 + 1 - 2 if ($class_id != 0);

            foreach my $net (@net_list) {
              push @{ $RAD_PAIRS->{'mpd-filter'} }, ($class_id) . "#$i=match dst net $net";
              push @{ $RAD_PAIRS->{'mpd-filter'} }, ($class_id + 1) . "#$i=match src net $net";
              $i++;
            }

             push @{ $RAD_PAIRS->{'mpd-limit'} }, "in#" .  ($self->{TOTAL} - $line->[0]) . "#$line->[0]=flt" . ($class_id) . " pass";
             push @{ $RAD_PAIRS->{'mpd-limit'} }, "out#" . ($self->{TOTAL} - $line->[0]) . "#$line->[0]=flt" . ($class_id + 1) . " pass";
          }
        }
      }
    }

    #$RAD_PAIRS->{'Session-Timeout'}=604800;
  }
  elsif ($NAS->{NAS_TYPE} eq 'cisco') {
    #$traf_tarif
    if ($self->{USER_SPEED} > 0) {
      push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit output " . ($self->{USER_SPEED} * 1024) . " 320000 320000 conform-action transmit exceed-action drop";
      push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit input " .  ($self->{USER_SPEED} * 1024) . " 32000 32000 conform-action transmit exceed-action drop";
    }
    else {
      my $EX_PARAMS = $self->ex_traffic_params(
        {
          traf_limit          => $traf_limit,
          deposit             => $self->{DEPOSIT},
          MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC
        }
      );

      if ($EX_PARAMS->{speed}->{1}->{OUT}) {
        push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit output access-group 101 " . ($EX_PARAMS->{speed}->{1}->{IN} * 1024) . " 1000000  1000000 conform-action transmit exceed-action drop";
        push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit input access-group 102 " .  ($EX_PARAMS->{speed}->{1}->{OUT} * 1024) . " 1000000 1000000 conform-action transmit exceed-action drop";
      }
      my $burst_normal = ($EX_PARAMS->{speed}->{0}->{IN} > 50000) ? 512000 : 320000;
      my $burst_max    = ($EX_PARAMS->{speed}->{0}->{IN} > 50000) ? 512000 : 320000;
      push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit output "
          . ($EX_PARAMS->{speed}->{0}->{IN} * 1024)
          . $burst_normal
          . ' '. $burst_max
          . " conform-action transmit exceed-action drop" if ($EX_PARAMS->{speed}->{0}->{IN}  && $EX_PARAMS->{speed}->{0}->{IN} > 0);

      $burst_normal = ($EX_PARAMS->{speed}->{0}->{OUT} > 50000) ? 512000 : 320000;
      $burst_max    = ($EX_PARAMS->{speed}->{0}->{OUT} > 50000) ? 512000 : 320000;
      push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit input "
          .  ($EX_PARAMS->{speed}->{0}->{OUT} * 1024)
          . $burst_normal
          . ' '. $burst_max
          . " conform-action transmit exceed-action drop" if ($EX_PARAMS->{speed}->{0}->{OUT} && $EX_PARAMS->{speed}->{0}->{OUT} > 0);
    }
  }
  # Mikrotik
  elsif ($NAS->{NAS_TYPE} eq 'mikrotik') {
    #$traf_tarif
    my $EX_PARAMS = $self->ex_traffic_params(
      {
        traf_limit          => $traf_limit,
        deposit             => $self->{DEPOSIT},
        MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC
      }
    );

    #global Traffic
    if ($EX_PARAMS->{traf_limit} > 0) {
      #Gigaword limit
      $RAD_PAIRS->{'Mikrotik-Total-Limit-Gigawords'} = 0;
      if ($EX_PARAMS->{traf_limit} > 4096) {
        my $giga_limit = int($EX_PARAMS->{traf_limit} / 4096);
        #$RAD_PAIRS->{'Mikrotik-Recv-Limit-Gigawords'}=int($giga_limit);
        #$RAD_PAIRS->{'Mikrotik-Xmit-Limit-Gigawords'}=int($giga_limit);
        $RAD_PAIRS->{'Mikrotik-Total-Limit-Gigawords'} = int($giga_limit);
        $EX_PARAMS->{traf_limit} = $EX_PARAMS->{traf_limit} - int($giga_limit) * 4096;
      }
      $RAD_PAIRS->{'Mikrotik-Total-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE});
      $RAD_PAIRS->{'Mikrotik-Recv-Limit'}  = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE}); # / 2);
      $RAD_PAIRS->{'Mikrotik-Xmit-Limit'}  = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE}); #/ 2);
    }

    #Shaper
    if ($EX_PARAMS->{ex_speed}) {
      $RAD_PAIRS->{'Mikrotik-Rate-Limit'}   = "$EX_PARAMS->{ex_speed}k";
      $RAD_PAIRS->{'Mikrotik-Address-List'} = "CUSTOM_SPEED";
  
      if ($EX_PARAMS->{speed}->{0}->{OUT_BURST}){
        $RAD_PAIRS->{'Mikrotik-Rate-Limit'} .= ' '
          . $EX_PARAMS->{speed}->{0}->{OUT_BURST}          .'K/'.$EX_PARAMS->{speed}->{0}->{IN_BURST}          .'K '
          . $EX_PARAMS->{speed}->{0}->{OUT_BURST_THRESHOLD}.'K/'.$EX_PARAMS->{speed}->{0}->{IN_BURST_THRESHOLD}.'K '
          . $EX_PARAMS->{speed}->{0}->{OUT_BURST_TIME}     . '/'.$EX_PARAMS->{speed}->{0}->{IN_BURST_TIME}
          .' 5' # Priority;
      }
    }
    elsif ($self->{USER_SPEED} > 0) {
      $RAD_PAIRS->{'Mikrotik-Rate-Limit'} = "$self->{USER_SPEED}k";
      $RAD_PAIRS->{'Mikrotik-Address-List'} = "CUSTOM_SPEED";
    }
    elsif (defined($EX_PARAMS->{speed}->{0})) {
      # old way Make speed
      if ($CONF->{MIKROTIK_QUEUES} || $RAD->{'WISPr-Logoff-URL'}) {
#        $RAD_PAIRS->{'Ascend-Xmit-Rate'} = int($EX_PARAMS->{speed}->{0}->{IN}) * $CONF->{KBYTE_SIZE};
#        $RAD_PAIRS->{'Ascend-Data-Rate'} = int($EX_PARAMS->{speed}->{0}->{OUT})* $CONF->{KBYTE_SIZE};
        # Mikrotik-Rate-Limit = 512K/1024K 1M/2M 256K/512K 32/32 5
        $RAD_PAIRS->{'Mikrotik-Rate-Limit'} =
          $EX_PARAMS->{speed}->{0}->{OUT}.'K/'.$EX_PARAMS->{speed}->{0}->{IN}.'K '.
          $EX_PARAMS->{speed}->{0}->{OUT_BURST}.'K/'.$EX_PARAMS->{speed}->{0}->{IN_BURST}.'K '.
          $EX_PARAMS->{speed}->{0}->{OUT_BURST_THRESHOLD}.'K/'.$EX_PARAMS->{speed}->{0}->{IN_BURST_THRESHOLD}.'K '.
          $EX_PARAMS->{speed}->{0}->{OUT_BURST_TIME}.'/'.$EX_PARAMS->{speed}->{0}->{IN_BURST_TIME}.' 5';
      }
      # New way add to address list
      else {
        $RAD_PAIRS->{'Mikrotik-Address-List'} = "CLIENTS_$self->{TP_ID}";
      }
    }
  }
  elsif ($NAS->{NAS_TYPE} eq 'accel_ipoe') {
    $RAD_PAIRS->{'Framed-IP-Address'} = $self->{IPOE_IP} if ($self->{IPOE_IP} && $self->{IPOE_IP} ne '0.0.0.0');
    if ($self->{IPOE_NETMASK}) {
      $RAD_PAIRS->{'Framed-Netmask'} = $self->{IPOE_NETMASK};
      delete($RAD_PAIRS->{'Framed-IP-Netmask'});
    }

    $RAD_PAIRS->{'Session-Timeout'}   = 604800;

    my $EX_PARAMS = $self->ex_traffic_params(
      {
        traf_limit          => $traf_limit,
        deposit             => $self->{DEPOSIT},
        MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC
      }
    );

    #Speed limit attributes
    if ($self->{USER_SPEED} > 0) {
      $RAD_PAIRS->{'PPPD-Upstream-Speed-Limit'}   = int($self->{USER_SPEED});
      $RAD_PAIRS->{'PPPD-Downstream-Speed-Limit'} = int($self->{USER_SPEED});
    }
    elsif (defined($EX_PARAMS->{speed}->{0})) {
      $RAD_PAIRS->{'PPPD-Downstream-Speed-Limit'} = int($EX_PARAMS->{speed}->{0}->{IN});
      $RAD_PAIRS->{'PPPD-Upstream-Speed-Limit'}   = int($EX_PARAMS->{speed}->{0}->{OUT});
    }
  }
  # MPD4
  elsif ($NAS->{NAS_TYPE} eq 'mpd4' && $RAD_PAIRS->{'Session-Timeout'} > 604800) {
    $RAD_PAIRS->{'Session-Timeout'} = 604800;
  }
###########################################################
  # pppd + RADIUS plugin (Linux) http://samba.org/ppp/
  # lepppd - PPPD IPv4 zone counters
  elsif ($NAS->{NAS_TYPE} eq 'accel_ppp'
    or ($NAS->{NAS_TYPE} eq 'lepppd')
    or ($NAS->{NAS_TYPE} eq 'pppd'))
  {
    my $EX_PARAMS = $self->ex_traffic_params(
      {
        traf_limit          => $traf_limit,
        deposit             => $self->{DEPOSIT},
        MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC
      }
    );

    #global Traffic
    if ($EX_PARAMS->{traf_limit} > 0) {
      $RAD_PAIRS->{'Session-Octets-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE});

      if ($CONF->{octets_direction} && $CONF->{octets_direction} eq 'user') {
        if ($self->{OCTETS_DIRECTION} == 1) {
          $RAD_PAIRS->{'Octets-Direction'} = 2;
        }
        elsif ($self->{OCTETS_DIRECTION} == 2) {
          $RAD_PAIRS->{'Octets-Direction'} = 1;
        }
        else {
          $RAD_PAIRS->{'Octets-Direction'} = 0;
        }
      }
      else {
        $RAD_PAIRS->{'Octets-Direction'} = $self->{OCTETS_DIRECTION};
      }
    }

    $RAD_PAIRS->{'User-Name'} = $self->{USER_NAME};

    #Speed limit attributes
    if ($self->{USER_SPEED} > 0) {
      $RAD_PAIRS->{'PPPD-Upstream-Speed-Limit'}   = int($self->{USER_SPEED});
      $RAD_PAIRS->{'PPPD-Downstream-Speed-Limit'} = int($self->{USER_SPEED});
    }
    elsif (defined($EX_PARAMS->{speed}->{0})) {
      $RAD_PAIRS->{'PPPD-Downstream-Speed-Limit'} = int($EX_PARAMS->{speed}->{0}->{IN});
      $RAD_PAIRS->{'PPPD-Upstream-Speed-Limit'}   = int($EX_PARAMS->{speed}->{0}->{OUT});
    }

    $RAD_PAIRS->{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE} if ($NAS->{NAS_ALIVE});
  }

  #Chillispot
  elsif ($NAS->{NAS_TYPE} eq 'chillispot' || $NAS->{NAS_TYPE} eq 'unifi') {
    my $EX_PARAMS = $self->ex_traffic_params(
      {
        traf_limit          => $traf_limit,
        deposit             => $self->{DEPOSIT},
        MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC
      }
    );

    #global Traffic
    if ($EX_PARAMS->{traf_limit} > 0) {
      $RAD_PAIRS->{'ChilliSpot-Max-Total-Octets'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE});
    }

    #Shaper for chillispot
    if ($self->{USER_SPEED} > 0) {
      $RAD_PAIRS->{'WISPr-Bandwidth-Max-Down'} = int($self->{USER_SPEED}) * $CONF->{KBYTE_SIZE};
      $RAD_PAIRS->{'WISPr-Bandwidth-Max-Up'}   = int($self->{USER_SPEED}) * $CONF->{KBYTE_SIZE};
    }
    elsif (defined($EX_PARAMS->{speed}->{0})) {
      $RAD_PAIRS->{'WISPr-Bandwidth-Max-Down'} = int($EX_PARAMS->{speed}->{0}->{IN}) * $CONF->{KBYTE_SIZE};
      $RAD_PAIRS->{'WISPr-Bandwidth-Max-Up'}   = int($EX_PARAMS->{speed}->{0}->{OUT}) * $CONF->{KBYTE_SIZE};
    }

    if(! $self->{IP} && $NAS->{NAS_TYPE} eq 'unifi') {
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
  #Auto assing MAC in first connect
  if ( $CONF->{MAC_AUTO_ASSIGN}
    && $self->{CID} eq ''
    && ($RAD->{'Calling-Station-Id'}&& $RAD->{'Calling-Station-Id'} =~ /:|\-/ )
    && ! $self->{NAS_PORT})
  {
    my $cid = $RAD->{'Calling-Station-Id'};
  	if ($RAD->{'Calling-Station-Id'} =~ /\/\s+([A-Za-z0-9:]+)\s+\//) {
  		$cid = $1;
  	}

    $self->query2("UPDATE dv_main SET cid='$cid'
     WHERE uid='$self->{UID}';", 'do'
    );
  }

  # SET ACCOUNT expire date
  if ($self->{ACCOUNT_AGE} > 0 && $self->{DV_EXPIRE} eq '0000-00-00') {
    $self->query2("UPDATE dv_main SET expire=curdate() + INTERVAL $self->{ACCOUNT_AGE} day 
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

  #OK
  return 0, $RAD_PAIRS, '';
}

#*********************************************************
=head2 Auth_CID($RAD) - Auth_mac

  Mac auth function

=cut
#*********************************************************
sub Auth_CID {
  my $self = shift;
  my ($RAD) = @_;

  my $RAD_PAIRS;

  my @MAC_DIGITS_GET = ();
  if (!$RAD->{'Calling-Station-Id'}) {
    $RAD_PAIRS->{'Reply-Message'} = "Wrong CID ''";
    return 1, $RAD_PAIRS, "Wrong CID ''";
  }

  my @CID_POOL = split(/;/, $self->{CID});

  #If auth from DHCP
  if ($CONF->{DHCP_CID_IP} || $CONF->{DHCP_CID_MAC} || $CONF->{DHCP_CID_MPD}) {
    $self->query2("SELECT INET_NTOA(dh.ip), dh.mac
         FROM dhcphosts_hosts dh
         LEFT JOIN users u ON u.uid=dh.uid
         WHERE  u.id='". $RAD->{'User-Name'} ."'
           AND dh.disable = 0
           AND dh.mac='". $RAD->{'Calling-Station-Id'} ."'"
    );
    if ($self->{errno}) {
      $RAD_PAIRS->{'Reply-Message'} = 'SQL error';
      return 1, $RAD_PAIRS;
    }
    elsif ($self->{TOTAL} > 0) {
      foreach my $line (@{ $self->{list} }) {
        my $ip  = $line->[0];
        my $mac = $line->[1];
        if ( ($RAD->{'Calling-Station-Id'} =~ /:/ || $RAD->{'Calling-Station-Id'} =~ /\-/)
          && $RAD->{'Calling-Station-Id'} !~ /\./
          && $CONF->{DHCP_CID_MAC})
        {
          #MAC
          push(@CID_POOL, $mac);
        }
        elsif ($RAD->{'Calling-Station-Id'} !~ /:/
          && $RAD->{'Calling-Station-Id'} !~ /\-/
          && $RAD->{'Calling-Station-Id'} =~ /\./
          && $CONF->{DHCP_CID_IP})
        {
          #IP
          push(@CID_POOL, $ip);
        }
        elsif ($RAD->{'Calling-Station-Id'} =~ /\// && $CONF->{DHCP_CID_MPD}) {
          #MPD IP+MAC
          push(@CID_POOL, "$ip/$mac");
        }
      }
    }
  }

  my $cid = $RAD->{'Calling-Station-Id'};

  foreach my $TEMP_CID (@CID_POOL) {
    if ($TEMP_CID ne '') {
      if (($TEMP_CID =~ /:/ || $TEMP_CID =~ /\-/)
        && $TEMP_CID !~ /\./)
      {
        @MAC_DIGITS_GET = split(/:|-/, $TEMP_CID);
        #NAS MPD 3.18 with patch
        if ($cid =~ /\//) {
          $cid =~ s/ //g;
          my ($cid_ip, $trash);
          ($cid_ip, $cid, $trash) = split(/\//, $cid, 3);
        }

        my @MAC_DIGITS_NEED = split(/:|\-|\./, $cid);
        my $counter = 0;

        for (my $i = 0 ; $i <= 5 ; $i++) {
          if (defined($MAC_DIGITS_NEED[$i]) && hex($MAC_DIGITS_NEED[$i]) == hex($MAC_DIGITS_GET[$i])) {
            $counter++;
          }
        }

        if ($counter eq '6') {
          #$RAD->{'Calling-Station-Id'}=join(/:/, @MAC_DIGITS_NEED);
          return 0 
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

  $RAD_PAIRS->{'Reply-Message'} = "Wrong CID '". $RAD->{'Calling-Station-Id'} ."'";
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
    #Get callback number
    if ($NAS->{NAS_TYPE} ne 'accel_ipoe' && $RAD->{'User-Name'} =~ /(\d+):(\S+)/) {
      my $number = $1;
      my $login  = $2;

      if ($CONF->{DV_CALLBACK_DENYNUMS} && $number =~ /$CONF->{DV_CALLBACK_DENYNUMS}/) {
        $RAD_PAIRS{'Reply-Message'} = "Forbidden Number '$number'";
        return 1, \%RAD_PAIRS;
      }

      if ($CONF->{DV_CALLBACK_PREFIX}) {
        $number = $CONF->{DV_CALLBACK_PREFIX} . $number;
      }
      if ($NAS->{NAS_TYPE} eq 'lucent_max') {
        $RAD_PAIRS{'Ascend-Dial-Number'}      = $number;
        $RAD_PAIRS{'Ascend-Data-Svc'}         = 'Switched-modem';
        $RAD_PAIRS{'Ascend-Send-Auth'}        = 'Send-Auth-None';
        $RAD_PAIRS{'Ascend-CBCP-Enable'}      = 'CBCP-Enabled';
        $RAD_PAIRS{'Ascend-CBCP-Mode'}        = 'CBCP-Profile-Callback';
        $RAD_PAIRS{'Ascend-CBCP-Trunk-Group'} = 5;
        $RAD_PAIRS{'Ascend-Callback-Delay'}   = 30;
      }
      else {
        $RAD_PAIRS{'Callback-Number'} = $number;
      }

      $RAD->{'User-Name'} = $login;
    }
    elsif ($RAD->{'User-Name'} =~ / /) {
      $RAD_PAIRS{'Reply-Message'} = "Login Not Exist or Expire. Space in login '". $RAD->{'User-Name'} ."'";
      return 1, \%RAD_PAIRS;
    }

    #AUTH:

    my $WHERE = '';
    if ($NAS->{DOMAIN_ID}) {
      $WHERE = "AND u.domain_id='$NAS->{DOMAIN_ID}'";
    }
    else {
      $WHERE = "AND u.domain_id='0'";
    }

    if ($CONF->{DV_LOGIN}) {
    	$self->query2("SELECT uid, dv_login AS login FROM dv_main WHERE dv_login= ? ;", undef, { INFO => 1, Bind => [ $RAD->{'User-Name'} ] });
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
      $RAD_PAIRS{'Reply-Message'} = "Login Not Exist or Expire";
    }
    else {
      $RAD_PAIRS{'Reply-Message'} = 'SQL error';
    }
    return 1, \%RAD_PAIRS;
  }

  if ($CONF->{DV_PASSWORD}) {
  	$self->query2("SELECT DECODE(password, '$CONF->{secretkey}') AS password FROM dv_main WHERE uid='$self->{UID}';");
  	if($self->{list}->[0]->[0]) {
  		$self->{PASSWD}=$self->{list}->[0]->[0];
  	}
  }
  if ($RAD->{'CHAP-Password'} && $RAD->{'CHAP-Challenge'}) {
    if (check_chap($RAD->{'CHAP-Password'}, "$self->{PASSWD}", $RAD->{'CHAP-Challenge'}, 0) == 0) {
      $RAD_PAIRS{'Reply-Message'} = "Wrong CHAP password";
      return 1, \%RAD_PAIRS;
    }
  }
  #Auth MS-CHAP v1,v2
  elsif ($RAD->{'MS-CHAP-Challenge'}) {
  }
  #End MS-CHAP auth
  elsif ($NAS->{NAS_AUTH_TYPE} && $NAS->{NAS_AUTH_TYPE} == 1) {
    if (check_systemauth($RAD->{'User-Name'}, $RAD->{'User-Password'}) == 0) {
      $RAD_PAIRS{'Reply-Message'} = "Wrong password '". $RAD->{'User-Password'} ."' $NAS->{NAS_AUTH_TYPE}";
      $RAD_PAIRS{'Reply-Message'} .= " CID: " . $RAD->{'Calling-Station-Id'} if ($RAD->{'Calling-Station-Id'});
      return 1, \%RAD_PAIRS;
    }
  }
  #If don't athorize any above methods auth PAP password
  else {
    if (defined($RAD->{'User-Password'}) && $self->{PASSWD} ne $RAD->{'User-Password'}) {
      $RAD_PAIRS{'Reply-Message'} = "Wrong password '". $RAD->{'User-Password'} ."'";
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
    $RAD->{'Calling-Station-Id'} = $RAD->{'Tunnel-Client-Endpoint:0'};
  }

  #DIsable
  if ($self->{DISABLE}) {
    $RAD_PAIRS{'Reply-Message'} = "Account Disable";
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
=head2 mac_auth($RAD_HASH_REF, $NAS_HASH_REF, $attr) - User authentication

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
sub mac_auth {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my %RAD_PAIRS = ();

  my $WHERE = '';
  if ($NAS->{DOMAIN_ID}) {
    $WHERE = "AND u.domain_id='$NAS->{DOMAIN_ID}'";
  }
  else {
    $WHERE = "AND u.domain_id='0'";
  }

  #my $auth_name = $RAD->{'User-Name'};

  if ($CONF->{DV_LOGIN}) {
    $self->query2("SELECT uid, dv_login AS login FROM dv_main WHERE dv_login= ? ;", undef, { INFO => 1, Bind => [ $RAD->{'User-Name'} ] });
  }
  elsif($CONF->{AUTH_DV_CID}) {
    $self->query2("SELECT dv.uid,
     u.id AS user_name,
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
    FROM dv_main dv
    INNER JOIN users u ON (dv.uid=u.uid)
    WHERE dv.CID = ? ;",
      undef, { INFO => 1, Bind => [ $RAD->{'Calling-Station-Id'} ] });
  }
  else{
    my $user_auth_params = $self->opt82_parse($RAD);
    $user_auth_params->{USER_MAC} = $RAD->{'Calling-Station-Id'};
    $self->dhcp_info($user_auth_params, $NAS);
#    if ($self->{DHCP_STATIC_IP} && $self->{DHCP_STATIC_IP} ne '0.0.0.0') {
#      $self->{IP}=$self->{DHCP_STATIC_IP};
#    }
  }

  if ($self->{errno}) {
    if($self->{errno} == 2) {
      $RAD_PAIRS{'Reply-Message'} = "IPoE Login Not Exist " . $self->{INFO};
    }
    else {
      $RAD_PAIRS{'Reply-Message'} = 'SQL error';
    }
    return 1, \%RAD_PAIRS;
  }
 
  $self->{LOGIN}=$self->{USER_NAME} if ($self->{USER_NAME});
  #$RAD->{'User-Name'} = $self->{USER_NAME};
  #DIsable
  if ($self->{DISABLE}) {
    $RAD_PAIRS{'Reply-Message'} = "Account Disable";
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
      $self->{errstr} = "Ext Bill account Not Exist";
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
      $self->{errstr} = "Bill account Not Exist '$self->{BILL_ID}'";
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
    $self->{errstr} = "Company ID '$self->{COMPANY_ID}' Not Exist";
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
  if ($attr->{TT_INTERVAL}) {
    $self->{TT_INTERVAL}=$attr->{TT_INTERVAL};
  }

  if($attr->{BILLING}) {
    $Billing = $attr->{BILLING};
  }

  my %EX_PARAMS = ();
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
    elsif ($self->{ACCOUNT_ACTIVATE} ne '0000-00-00') { 
      $start_period = "DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACCOUNT_ACTIVATE}'";
    }

    my $used_traffic = $Billing->get_traffic(
      {
        UID    => $self->{UID},
        UIDS   => $self->{UIDS},
        PERIOD => $start_period
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
      if ($self->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
        $interval = "(DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACCOUNT_ACTIVATE}' - INTERVAL $self->{TRAFFIC_TRANSFER_PERIOD} * 30 DAY && 
       DATE_FORMAT(start, '%Y-%m-%d')<='$self->{ACCOUNT_ACTIVATE}')";
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
        START_PERIOD => $self->{ACCOUNT_ACTIVATE},
        debug        => 0
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
      my $trafic_limit = $trafic_limits{0}; # ($CONF->{MAX_SESSION_TRAFFIC} && $trafic_limits{0} > $CONF->{MAX_SESSION_TRAFFIC}) ? $CONF->{MAX_SESSION_TRAFFIC} : $trafic_limits{0};
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

  #Get reserved IP with status 11
  if (! $self->{LOGINS}) {
    $self->{USER_NAME} = '' if (! $self->{USER_NAME});
    $self->query2("SELECT INET_NTOA(framed_ip_address) AS ip FROM dv_calls 
       WHERE user_name='$self->{USER_NAME}' 
         AND status=11 
         AND nas_id='$nas_num'
         AND framed_ip_address > 0;");

    if ($self->{TOTAL} > 0) {
      return $self->{list}->[0]->[0];
    }
  }

  delete $self->{GATEWAY};
  delete $self->{NETMASK};
  delete $self->{DNS};
  delete $self->{NTP};

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
    $self->query2("SELECT ippools.ip, ippools.counts, ippools.id, ippools.next_pool_id,
      IF(ippools.gateway > 0, INET_NTOA(ippools.gateway), ''),
      IF(ippools.netmask > 0, INET_NTOA(ippools.netmask), ''), dns, ntp
    FROM ippools, nas_ippools
     WHERE ippools.id=nas_ippools.pool_id AND nas_ippools.nas_id='$nas_num'
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

    for (my $i = $sip ; $i <= $sip + $count ; $i++) {
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
  $db_->do('lock tables dv_calls as c read, nas_ippools as np read, dv_calls write');
  #get active address and delete from pool
  # Select from active users and reserv ips
  $self->query2("SELECT c.framed_ip_address
    FROM dv_calls c
    INNER JOIN nas_ippools np ON (c.nas_id=np.nas_id)
    WHERE np.pool_id in ( $used_pools )
    GROUP BY c.framed_ip_address;"
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
        $self->{NETMASK} = $pool_info{$active_pool}{NETMASK};
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
}

#*******************************************************************
=head2 online_add($attr) - Add session to dv_calls

=cut
#*******************************************************************
sub online_add {
  my $self=shift;
  my ($attr)=@_;

  my %insert_hash = (
    user_name       => $self->{USER_NAME},
    uid             => $self->{UID} || 0,
    nas_id          => $attr->{NAS_ID},
    nas_port_id     => $attr->{NAS_PORT_ID},
    tp_id           => $self->{TP_NUM},
    join_service    => $self->{JOIN_SERVICE},
    guest           => $attr->{GUEST},
    CID             => $attr->{CID},
    CONNECT_INFO    => $attr->{CONNECT_INFO},
    #nas_ip_address  => $attr->{NAS_IP_ADDRESS},
    framed_ip_address => $attr->{FRAMED_IP_ADDRESS}
    #acct_session_id
  );

  if (! $attr->{NAS_ID}) {
    `echo "$self->{USER_NAME} nas_id: $attr->{NAS_ID} guest:  $attr->{GUEST} " >> /tmp/nas_id`;
  }

  my $sql = "INSERT INTO dv_calls SET started=NOW(),
       lupdated        = UNIX_TIMESTAMP(),
       status          = '11',
       acct_session_id = 'IP',
       nas_ip_address  = INET_ATON('". ($attr->{'NAS_IP_ADDRESS'} || '0.0.0.0') ."')";

  while(my ($k, $v) = each %insert_hash) {
    if($k eq 'framed_ip_address' && $v) {
      $sql .= ", $k=$v";
    }
    elsif ($v) {
      $sql .= ", $k='$v'";
    }
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

    $self->query2("SELECT DECODE(password, '$CONF->{secretkey}') FROM users WHERE id= ?;",
    undef,
    { Bind => [ $login ] } );

    if ($self->{TOTAL} > 0) {
      my $list     = $self->{list}->[0];
      my $password = $list->[0];

      $self->{'RAD_CHECK'}{'Cleartext-Password'} = "$password";

      return 0;
    }

    $self->{errno}  = 1;
    $self->{errstr} = "USER: '$login' not exist";
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
       RAD_PAIRS  - Rad pairs
       MESSAGE    - Info message

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

  $RAD_PAIRS->{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE} if ($NAS->{NAS_ALIVE});

  if (!defined($CONF->{NEG_DEPOSIT_USER_IP})) {
    $CONF->{NEG_DEPOSIT_USER_IP} = 0;
  }

  if (!$attr->{USER_FILTER}) {
    # Return radius attr
    if ($self->{IP} ne '0'
       && !$self->{NEG_DEPOSIT_IP_POOL}
       || $self->{IP} ne '0'
       && $CONF->{NEG_DEPOSIT_USER_IP}) {
      $RAD_PAIRS->{'Framed-IP-Address'} = "$self->{IP}";

      $self->online_add({ %$attr, 
                          NAS_ID            => $NAS->{NAS_ID},
                          FRAMED_IP_ADDRESS => "INET_ATON('$self->{IP}')",
                          NAS_IP_ADDRESS    => $RAD->{'NAS-IP-Address'},
                          GUEST             => 1
                        });
    }
    else {
      my $ip = $self->get_ip($NAS->{NAS_ID}, $RAD->{'NAS-IP-Address'}, { TP_IPPOOL => $self->{NEG_DEPOSIT_IP_POOL} || $self->{TP_IPPOOL}, GUEST => 1 });
      if ($ip eq '-1') {
        $RAD_PAIRS->{'Reply-Message'} = "Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS}) " . (($self->{TP_IPPOOL}) ? " TP_IPPOOL: $self->{TP_IPPOOL}" : '');
        return 1, $RAD_PAIRS;
      }
      elsif ($ip eq '0') {
        #$RAD_PAIRS->{'Reply-Message'}="$self->{errstr} ($NAS->{NAS_ID})";
        #return 1, $RAD_PAIRS;
        $self->online_add({
          %$attr,
          NAS_ID            => $NAS->{NAS_ID},
          FRAMED_IP_ADDRESS => "INET_ATON('$self->{IP}')",
          NAS_IP_ADDRESS    => $RAD->{'NAS-IP-Address'},
          GUEST             => 1
        });
      }
      else {
        $RAD_PAIRS->{'Framed-IP-Address'} = "$ip";
      }
    }

    $self->{INFO} .= "NEG_FILTER";
    if($RAD_PAIRS->{'Reply-Message'}) {
      $RAD_PAIRS->{'Reply-Message'} .= ' GUEST';
    }

    if ($attr->{MESSAGE}) {
      $self->{INFO} .= ' '.$attr->{MESSAGE};
    }
  }

  $NEG_DEPOSIT_FILTER_ID =~ s/{IP}/$RAD_PAIRS->{'Framed-IP-Address'}/g;
  $NEG_DEPOSIT_FILTER_ID =~ s/{LOGIN}/$RAD->{'User-Name'}/g;

  if ($NEG_DEPOSIT_FILTER_ID =~ /RAD:(.+)/) {
    my $rad_pairs = $1;
    rad_pairs_former($rad_pairs, $attr);
  }
  else {
    $RAD_PAIRS->{'Filter-Id'} = $NEG_DEPOSIT_FILTER_ID;
  }

  $self->{GUEST_MODE}=1 if (! $attr->{USER_FILTER});

  if ($attr->{USER_FILTER}) {
    return 0;
  }

  return 0, $RAD_PAIRS;
}

#**********************************************************
=head2 rad_pairs_former($content, $attr) - Forming RAD pairs

  Arguments:
    $attr
      RAD_PAIRS - HASH_REF of return rad pairs

  Returns:
    Result  TRUE or FALSE
    HAS_REF of formed rad reply

=cut
#**********************************************************
sub rad_pairs_former  {
  my ($content, $attr) = @_;

  $content =~ s/\r|\n//g;
  $content =~ s/RAD://g;
  my @p = split(/,/, $content);

  my $RAD_PAIRS;
  if ($attr->{RAD_PAIRS}) {
    $RAD_PAIRS = $attr->{RAD_PAIRS};
  }

  foreach my $line (@p) {
    if ($line =~ /([a-zA-Z0-9\-]{6,25})\s?\+\=\s?(.{1,200})/) {
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

  Arguments:
    $RAD_REQUEST
    $attr
      AUTH_EXPR
        NAS_MAC, PORT (convert from hex), PORT_MULTI (not converted), DEC_PORT (dec port value), VLAN,
        SERVER_VLAN, AGENT_REMOTE_ID, CIRCUIT_ID, LOGIN

  Returns:
    RESULTS - hash_ref
      NAS_MAC, PORT, VLAN, SERVER_VLAN, AGENT_REMOTE_ID, CIRCUIT_ID, LOGIN

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
  my $hex2ansii   = '';
  my @o82_expr_arr = ();

  if($self->{conf}) {
    $CONF = $self->{conf};
  }

  if($attr->{AUTH_EXPR}) {
    $CONF->{AUTH_EXPR}=$attr->{AUTH_EXPR};
  }

  if ($CONF->{AUTH_EXPR}) {
    $CONF->{AUTH_EXPR} =~ s/\n//g;
    @o82_expr_arr    = split(/;/, $CONF->{AUTH_EXPR});
  }

  if ($#o82_expr_arr > -1) {
    my $expr_debug  =  "";
    foreach my $expr (@o82_expr_arr) {
      my ($parse_param, $expr_, $values, $attribute)=split(/:/, $expr);
      my @EXPR_IDS = split(/,/, $values);
      if ($RAD_REQUEST->{$parse_param}) {

        my $input_value = $RAD_REQUEST->{$parse_param};
        if ($attribute && $attribute eq 'hex2ansii') {
          $hex2ansii   = 1;
          $input_value =~ s/^0x//;
          $input_value = pack 'H*', $input_value;
        }

        if ($CONF->{AUTH_EXPR_DEBUG} && $CONF->{AUTH_EXPR_DEBUG} > 3) {
          $expr_debug  .=  "$RAD_REQUEST->{'DHCP-Client-Hardware-Address'}: $parse_param, $expr_, $RAD_REQUEST->{$parse_param}/$input_value\n";
        }

        if (my @res = ($input_value =~ /$expr_/i)) {
          for (my $i=0; $i <= $#res ; $i++) {
            if ($CONF->{AUTH_EXPR_DEBUG} && $CONF->{AUTH_EXPR_DEBUG} > 3) {
              $expr_debug .= "$EXPR_IDS[$i] / $res[$i]\n";
            }

            $result{$EXPR_IDS[$i]}=$res[$i];
          }
          #last;
        }
      }

      if ($parse_param eq 'DHCP-Relay-Agent-Information') {
        $result{AGENT_REMOTE_ID} = substr($RAD_REQUEST->{$parse_param},0,25);
        $result{CIRCUIT_ID} = substr($RAD_REQUEST->{$parse_param},25,25);
      }
      else {
        $result{AGENT_REMOTE_ID}='-';
        $result{CIRCUIT_ID}='-';
      }
    }

    if ($result{NAS_MAC} && $result{NAS_MAC} =~ /([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})/i) {
      $result{NAS_MAC} = "$1:$2:$3:$4:$5:$6";
    }

    if ($CONF->{AUTH_EXPR_DEBUG} && $CONF->{AUTH_EXPR_DEBUG} > 2) {
      `echo "$expr_debug" >> /tmp/dhcphosts_expr`;
      if ($CONF->{AUTH_EXPR_DEBUG} > 3) {
        print $expr_debug."-- \n";
      }
    }
  }
  # FreeRadius DHCP default
#  elsif($RAD_REQUEST->{'DHCP-Relay-Agent-Information'}) {
#    my @relayid = unpack('a10 a4 a2 a2 a4 a16 (a2)*', $RAD_REQUEST->{'DHCP-Relay-Agent-Information'});
#    $result{VLAN}            = $relayid[1];
#    $result{PORT}            = $relayid[3];
#    $result{NAS_MAC}             = $relayid[5];
#    $result{AGENT_REMOTE_ID} = substr($RAD_REQUEST->{'DHCP-Relay-Agent-Information'},0,25);
#    $result{CIRCUIT_ID}      = substr($RAD_REQUEST->{'DHCP-Relay-Agent-Information'},25,25);
#  }
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

  if (! $result{SERVER_VLAN}) {
    $result{SERVER_VLAN} = '';
  }

  return \%result;
}

#**********************************************************
=head2 dhcp_info($attr, $NAS)

  Arguments:
    $attr
    $NAS

  Results:
    $self

=cut
#**********************************************************
sub dhcp_info {
  my $self = shift;
  my ($attr, $NAS) = @_;

  my @WHERE_RULES = ();

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

  if($attr->{SERVER_VLAN}) {
    push @WHERE_RULES, "dh.vid='$attr->{VLAN}' AND dh.server_vid='$attr->{SERVER_VLAN}'";
    $self->{INFO} = "q2q: $attr->{SERVER_VLAN}-$attr->{VLAN} MAC: $attr->{USER_MAC}";
  }
  elsif ($CONF->{AUTH_PARAMS}) {
    push @WHERE_RULES, "((n.mac='$attr->{NAS_MAC}' OR n.mac IS null)
      AND (dh.mac='$attr->{USER_MAC}' OR dh.mac='00:00:00:00:00:00')
      AND (dh.vid='$attr->{VLAN}' OR dh.vid='')
      AND (dh.ports='$attr->{PORT}' OR dh.ports=''))";
    $self->{INFO} = "NAS_MAC: $attr->{NAS_MAC} PORT: $attr->{PORT} VLAN: $attr->{VLAN} MAC: $attr->{USER_MAC}";
  }
  elsif ($CONF->{NAS_PORT_AUTH}) {
    push @WHERE_RULES, "n.mac='$attr->{NAS_MAC}' AND dh.ports='$attr->{PORT}'";
    $self->{INFO} = "NAS_MAC: $attr->{NAS_MAC} PORT: $attr->{PORT} VLAN: $attr->{VLAN} MAC: $attr->{USER_MAC}";
  }
  elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
  elsif ($CONF->{AUTH_IP}) {
    push @WHERE_RULES, "dh.ip=INET_ATON('$attr->{IP}')";
    $self->{INFO} = "AUTH IP '$attr->{IP}'";
    $self->{IPOE_IP} = $attr->{IP};
  }
  elsif ($attr->{USER_MAC}) {
    push @WHERE_RULES, "dh.mac='$attr->{USER_MAC}'";
    $self->{INFO} = "USER MAC '$attr->{USER_MAC}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? join(' AND ', @WHERE_RULES) : '';
  $self->query2("SELECT
      u.uid,
      INET_NTOA(dh.ip) AS dhcp_static_ip,
      u.id AS user_name,
      n.id AS nas_id,
      INET_NTOA(dh_nets.mask) AS netmask,
      INET_NTOA(dh_nets.routers) AS routers,
      dh_nets.dns,
      dh_nets.dns2,
      dh_nets.suffix,
      dh_nets.ntp,
      dh.mac,
      u.uid,
      UNIX_TIMESTAMP(),
      UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
      DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
      DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),
      u.company_id,
      u.disable,
      u.bill_id,
      u.credit,
      u.activate,
      u.reduction,
      u.ext_bill_id,
      UNIX_TIMESTAMP(u.expire) AS account_expire

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
    $self->{errno}    = 2;
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

    $self->{errno}    = 2;
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

#**********************************************************
=head2 leases_add($attr, $NAS) - Add IP to leases

  Arguments:
    $attr
      RESERVED_IP
      GUEST_MODE
      GUEST_LEASES

      LEASES_TIME
      USER_MAC
      UID
      CIRCUIT_ID
      AGENT_REMOTE_ID
      HOSTNAME
      IP
      PORT
      VLAN
      NAS_MAC

    $NAS

=cut
#**********************************************************
sub leases_add {
  my $self   = shift;
  my ($attr, $NAS) = @_;

  return $self if ($self->{RESERVED_IP} && $self->{GUEST_MODE} == $self->{GUEST_LEASES});

  # DELETE OLD leases
  $self->{UID}=0 if (! $self->{UID});
  $self->query2("DELETE FROM dhcphosts_leases WHERE (ip=INET_ATON( ? ) AND nas_id= ? )
    OR (uid= ?  AND flag<> ? );", 'do',
    { Bind => [
        $self->{IP},
        $NAS->{NAS_ID},
        $self->{UID},
        $self->{GUEST_MODE} || 0
      ]});

  #add to dhcp table
  $self->query2("INSERT INTO dhcphosts_leases
      (start, ends, state, next_state, hardware, uid,
       circuit_id, remote_id, hostname,
       nas_id, ip, port, vlan, server_vlan, switch_mac, flag,
       dhcp_id)
    VALUES (NOW(),
      NOW() + INTERVAL ? SECOND, 2, 1,
      ?, ?, ?, ?, ?, ?, INET_ATON( ? ), ?, ?, ?, ?, ?, ?)", 'do',
    { Bind => [
        ($attr->{LEASES_TIME} + 60),
        $attr->{USER_MAC},
        $self->{UID},
        $attr->{CIRCUIT_ID} || q{},
        $attr->{AGENT_REMOTE_ID} || q{},
        (($attr->{HOSTNAME}) ? $attr->{HOSTNAME} : '' ),
        $NAS->{NAS_ID} || 0,
        $self->{IP},
        $attr->{PORT} || '',
        $attr->{VLAN} || 0,
        $attr->{SERVER_VLAN} || 0,
        $attr->{NAS_MAC} || 0,
        (($self->{GUEST_MODE}) ? 1 : 0),
        $CONF->{DHCP_ID} || 0
      ]}
  );

  return $self;
}

1;

