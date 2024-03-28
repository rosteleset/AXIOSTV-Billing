package Voip_aaa;
=head2

 VoIP AAA functions

=cut

use strict;
our $VERSION     = 7.04;

use base qw(main Auth);
use Billing;

my ($conf, $Billing);

my %RAD_PAIRS = ();
my %ACCT_TYPES = (
  'Start' =>          1,
  'Stop'  =>          2,
  'Alive' =>          3,
  'Interim-Update'=>  3,
  'Accounting-On' =>  7,
  'Accounting-Off'=>  8
);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($conf)   = @_;

  my $self = {};
  bless($self, $class);

  $self->{db}=$db;

  $Billing = Billing->new($self->{db}, $conf);

  return $self;
}

#**********************************************************
=head2 pre_auth($RAD, $attr)

=cut
#**********************************************************
sub pre_auth {
  my ($self) = @_;

  $self->{'RAD_CHECK'}{'Auth-Type'} = "Accept";

  return 0;
}

#**********************************************************
=head2 preproces($RAD)

=cut
#**********************************************************
sub preproces {
  my ($RAD) = @_;

  my %CALLS_ORIGIN = (
    answer    => 0,
    originate => 1,
    proxy     => 2
  );

  (undef, $RAD->{'h323-conf-id'}) = split(/=/, $RAD->{'h323-conf-id'}, 2) if ($RAD->{'h323-conf-id'} =~ /=/);
  $RAD->{'h323-conf-id'} =~ s/ //g;

  if ($RAD->{'h323-call-origin'}) {
    (undef, $RAD->{'h323-call-origin'}) = split(/=/, $RAD->{'h323-call-origin'}, 2) if ($RAD->{'h323-call-origin'} =~ /=/);
    $RAD->{'h323-call-origin'} = $CALLS_ORIGIN{ $RAD->{'h323-call-origin'} } if ($RAD->{'h323-call-origin'} ne 1);
  }

  (undef, $RAD->{'h323-disconnect-cause'}) = split(/=/, $RAD->{'h323-disconnect-cause'}, 2) if (defined($RAD->{'h323-disconnect-cause'}));

  $RAD->{'Client-IP-Address'} = $RAD->{'Framed-IP-Address'} if ($RAD->{'Framed-IP-Address'});

  return 1;
}

#**********************************************************
=head2 user_info($RAD, $NAS) - get user information

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($RAD) = @_;

  my $WHERE = '';
  if (defined($RAD->{'h323-call-origin'}) && $RAD->{'h323-call-origin'} == 0) {
    $WHERE = "(voip.number='". $RAD->{'Called-Station-Id'} ."' OR alias.number='". $RAD->{'Called-Station-Id'} ."' ) ";
    $RAD->{'User-Name'} = $RAD->{'Called-Station-Id'};
  }
  else {
    $WHERE = "(voip.number='". $RAD->{'User-Name'} ."' OR alias.number='". $RAD->{'User-Name'} ."' )";
  }

  $self->query2("SELECT 
   voip.uid, 
   voip.number,
   voip.tp_id, 
   INET_NTOA(voip.ip) AS ip,
   DECODE(password, '$conf->{secretkey}') AS password,
   IF(voip.logins=0, IF(voip.logins is null, 0, tp.logins), voip.logins) AS logins,
   voip.allow_answer,
   voip.allow_calls,
   voip.disable AS voip_disable,
   u.disable AS user_disable,
   u.reduction,
   u.bill_id,
   u.company_id,
   u.credit,
  UNIX_TIMESTAMP() AS session_start,
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_week,
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year,
   IF(voip.filter_id<>'', voip.filter_id, tp.filter_id) AS filter_id,
   tp.payment_type,
   tp.uplimit,
   tp.age AS account_age,
   voip.expire AS voip_expire,
   tp.max_session_duration
   FROM voip_main voip 
   INNER JOIN users u ON (u.uid=voip.uid)
   LEFT JOIN tarif_plans tp ON (tp.tp_id=voip.tp_id)
   LEFT JOIN voip_phone_aliases alias ON (alias.uid=voip.uid)
   WHERE
   $WHERE
   AND (voip.expire='0000-00-00' OR voip.expire > CURDATE());",
  undef,
  { INFO => 1 }
  );

  if($self->{errno}) {
    if($self->{errno} == 2) {
    }
    return $self;
  }

  #Chack Company account if ACCOUNT_ID > 0
  $self->check_company_account() if ($self->{COMPANY_ID} > 0);

  $self->check_bill_account();
  if ($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'} = $self->{errstr};
    return 1, \%RAD_PAIRS;
  }

  return $self;
}

#**********************************************************
=head2 number_expr($RAD) - Make number expr

=cut
#**********************************************************
sub number_expr {
  my ($RAD) = @_;
  my @num_expr = split(/;/, $conf->{VOIP_NUMBER_EXPR});

  #Dont comment its reserv for expr
  my $number = $RAD->{'Called-Station-Id'};
  for (my $i = 0 ; $i <= $#num_expr ; $i++) {
    my ($left, $right) = split(/\//, $num_expr[$i]);
    my $r = eval "\"$right\"";
    if ($RAD->{'Called-Station-Id'} =~ s/$left/$r/) {
      last;
    }
  }

  return 0;
}

#**********************************************************
=head auth()

=cut
#**********************************************************
sub auth {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  if (defined($RAD->{'h323-conf-id'})) {
    preproces($RAD);
  }

  # For Cisco
  if ($RAD->{'User-Name'} =~ /(\S+):(\d+)/) {
    $RAD->{'User-Name'} = $2;
  }

  if ($conf->{VOIP_NUMBER_EXPR}) {
    number_expr($RAD);
  }

  %RAD_PAIRS = ();
  $self->user_info($RAD, $NAS);

  if ($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'} = $self->{errstr} .' '. $RAD->{'User-Name'};
    $RAD_PAIRS{'h323-return-code'}=1;
    return 1, \%RAD_PAIRS;
  }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST ' . $RAD->{'User-Name'};
    if (!$RAD->{'h323-call-origin'}) {
      $RAD_PAIRS{'Reply-Message'} = "ANSWER_NUMBER_NOT_EXIST '$RAD->{'User-Name'}'";
      $RAD_PAIRS{'Filter-Id'}='answer_not_exist';
    }
    else {
      $RAD_PAIRS{'Reply-Message'} = "CALLER_NUMBER_NOT_EXIST '$RAD->{'User-Name'}'";
      $RAD_PAIRS{'Filter-Id'}='call_not_exist';
    }
    $RAD_PAIRS{'h323-return-code'}=8;
    return 1, \%RAD_PAIRS;
  }

  if (defined($RAD->{'CHAP-Password'}) && defined($RAD->{'CHAP-Challenge'})) {
    if (Auth::check_chap($RAD->{'CHAP-Password'}, "$self->{PASSWORD}", $RAD->{'CHAP-Challenge'}, 0) == 0) {
      $RAD_PAIRS{'Reply-Message'} = "WRONG_CHAP_PASSWORD";
      $RAD_PAIRS{'h323-return-code'}=2;
      return 1, \%RAD_PAIRS;
    }
  }
  else {
    if ($self->{IP} ne '0.0.0.0' && $self->{IP} ne $RAD->{'Framed-IP-Address'}) {
      $RAD_PAIRS{'Reply-Message'} = "NOT_ALLOW_IP '$RAD->{'Framed-IP-Address'}' / $self->{IP} ";
      $RAD_PAIRS{'Filter-Id'}='not_allow_ip';
      $RAD_PAIRS{'h323-return-code'}=4;
      return 1, \%RAD_PAIRS;
    }
  }

  #DIsable
  if ($self->{VOIP_DISABLE}) {
    if ($self->{VOIP_DISABLE} == 2 && $RAD->{'h323-call-origin'} == 1) {
      $RAD_PAIRS{'Reply-Message'} = "Incoming only";
      $RAD_PAIRS{'Filter-Id'} = 'incoming_only';
      $RAD_PAIRS{'h323-return-code'}=8;
      return 1, \%RAD_PAIRS;
    }
    else {
      $RAD_PAIRS{'Reply-Message'} = "Service Disable";
      $RAD_PAIRS{'Filter-Id'} = 'service_disabled';
      $RAD_PAIRS{'h323-return-code'}=7;
      return 1, \%RAD_PAIRS;
    }
  }
  elsif ($self->{USER_DISABLE}) {
    $RAD_PAIRS{'Reply-Message'} = "Account Disable";
    $RAD_PAIRS{'Filter-Id'} = 'user_disable';
    $RAD_PAIRS{'h323-return-code'}=4;
    return 1, \%RAD_PAIRS;
  }

  # 
  if ($self->{LOGINS} > 0) {
    $self->query2("SELECT COUNT(*) FROM voip_calls
       WHERE (calling_station_id='". $RAD->{'Calling-Station-Id'} ."' OR called_station_id='". $RAD->{'Calling-Station-Id'}."')
       AND status<>2;");

    if ($self->{TOTAL} && $self->{list}->[0]->[0] >= $self->{LOGINS}) {
      $RAD_PAIRS{'Reply-Message'} = "More then allow calls ($self->{LOGINS}/$self->{list}->[0]->[0])";
      $RAD_PAIRS{'Filter-Id'} = 'more_then_allow_calls';
      $RAD_PAIRS{'h323-return-code'}=115;
      return 1, \%RAD_PAIRS;
    }
  }

  if ($self->{FILTER_ID}) {
    $RAD_PAIRS{'Filter-Id'} = $self->{FILTER_ID};
  }

  #$self->{PAYMENT_TYPE} = 0;
  if ($self->{PAYMENT_TYPE} == 0) {
    $self->{DEPOSIT}           = $self->{DEPOSIT} + $self->{CREDIT};    #-$self->{CREDIT_TRESSHOLD};
    $RAD->{'h323-credit-amount'} = $self->{DEPOSIT};

    #One month freeperiod
    if ($conf->{VOIP_ONEMONTH_INCOMMING_ALLOW} && ! $self->{VOIP_DISABLE}) {

    }
    #Check deposit
    elsif ($self->{DEPOSIT} <= 0 && ! $conf->{VOIP_ALLOW_ZERO_ROUTE}) {
      $RAD_PAIRS{'Reply-Message'} = "NEGATIV_DEPOSIT '$self->{DEPOSIT}'. Rejected!";
      $RAD_PAIRS{'Filter-Id'}='neg_deposit';
      $RAD_PAIRS{'h323-return-code'}=4;
      return 1, \%RAD_PAIRS;
    }

    if ($self->{DEPOSIT} < $self->{UPLIMIT}) {
      $RAD_PAIRS{'Reply-Message'} = "Too small deposit please recharge balace";
      $RAD_PAIRS{'Filter-Id'}='deposit_alert';
    }
  }
  else {
    $self->{DEPOSIT} = 0;
  }

  #  $self->check_bill_account();
  # if call
  if (defined($RAD->{'h323-conf-id'})) {
    if(defined($RAD->{'h323-call-origin'})) {
      if ($self->{ALLOW_ANSWER} < 1 && $RAD->{'h323-call-origin'} == 0) {
        $RAD_PAIRS{'Reply-Message'} = "NOT_ALLOW_ANSWER";
        $RAD_PAIRS{'Filter-Id'} = 'not_allow_answer';
        $RAD_PAIRS{'h323-return-code'}=9;
        return 1, \%RAD_PAIRS;
      }
      elsif ($self->{ALLOW_CALLS} < 1 && $RAD->{'h323-call-origin'} == 1) {
        $RAD_PAIRS{'Reply-Message'} = "NOT_ALLOW_CALLS";
        $RAD_PAIRS{'Filter-Id'} = 'not_allow_call';
        $RAD_PAIRS{'h323-return-code'}=9;
        return 1, \%RAD_PAIRS;
      }
    }

    $self->get_route_prefix($RAD);
    if ($self->{TOTAL} < 1) {
      $RAD_PAIRS{'Reply-Message'} = "NO_ROUTE '" . $RAD->{'Called-Station-Id'} . "'";
      $RAD_PAIRS{'Filter-Id'}='no_route';
      $RAD_PAIRS{'h323-return-code'}=8;
      return 1, \%RAD_PAIRS;
    }
    elsif ($self->{ROUTE_DISABLE} == 1) {
      $RAD_PAIRS{'Reply-Message'} = "ROUTE_DISABLED '" . $RAD->{'Called-Station-Id'} . "'";
      $RAD_PAIRS{'Filter-Id'}='route_disable';
      $RAD_PAIRS{'h323-return-code'}=8;
      return 1, \%RAD_PAIRS;
    }

    #Get intervals and prices
    #originate
    my $session_timeout = 0;
    if ($RAD->{'h323-call-origin'} == 1) {
      $self->{INFO} = $RAD->{'Called-Station-Id'};
      $self->get_intervals();

      if ($self->{TOTAL} < 1) {
        $RAD_PAIRS{'Reply-Message'} = "NO_PRICE_FOR_ROUTE PREFIX '$self->{PREFIX}' NUMBER '" . $RAD->{'Called-Station-Id'} . "'";
        $RAD_PAIRS{'Filter-Id'}='no_price_for_route';
        $RAD_PAIRS{'h323-return-code'}=8;
        return 1, \%RAD_PAIRS;
      }

      ($session_timeout) = $Billing->remaining_time(
        $self->{DEPOSIT},
        {
          TIME_INTERVALS      => $self->{TIME_PERIODS},
          INTERVAL_TIME_TARIF => $self->{PERIODS_TIME_TARIF},
          SESSION_START       => $self->{SESSION_START},
          DAY_BEGIN           => $self->{DAY_BEGIN},
          DAY_OF_WEEK         => $self->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $self->{DAY_OF_YEAR},
          REDUCTION           => $self->{REDUCTION},
          POSTPAID            => $self->{PAYMENT_TYPE},
          PRICE_UNIT          => 'Min',
          FULL_COUNT          => 1
        }
      );

      if ($session_timeout > 0) {
        #$RAD_PAIRS{'h323-credit-time'}=$session_timeout;
      }
      elsif ($self->{PAYMENT_TYPE} == 0 && $session_timeout == 0) {
        $RAD_PAIRS{'Reply-Message'} = "TOO_SMALL_DEPOSIT_FOR_CALL: $self->{DEPOSIT}";
        $RAD_PAIRS{'Filter-Id'}='too_small_deposit';
        $RAD_PAIRS{'h323-return-code'}=4;
        return 1, \%RAD_PAIRS;
      }

      #Make trunk data for asterisk
      if ($NAS->{NAS_TYPE} eq 'asterisk' && $self->{TRUNK_PROTOCOL}) {
        $self->{prepend} = '';

        my $number = $RAD->{'Called-Station-Id'};
        if (defined($self->{REMOVE_PREFIX})) {
          $number =~ s/^$self->{REMOVE_PREFIX}//;
        }

        if (defined($self->{ADDPREFIX})) {
          $number = $self->{ADDPREFIX} . $number;
        }

        if ($self->{TRUNK_PROTOCOL} eq "Local") {
          $RAD_PAIRS{'next-hop-ip'} = "Local/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER} . "/n";
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "IAX2") {
          $RAD_PAIRS{'next-hop-ip'} = "IAX2/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $number;
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "Zap") {
          $RAD_PAIRS{'next-hop-ip'} = "Zap/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $number;
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "SIP") {
          $RAD_PAIRS{'next-hop-ip'} = "SIP/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER};
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "local") {
          $RAD_PAIRS{'next-hop-ip'} = "local/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER};
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "OH323") {
          $RAD_PAIRS{'next-hop-ip'} = "OH323/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $number;
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "OOH323C") {
          $RAD_PAIRS{'next-hop-ip'} = "OOH323C/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER};
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "H323") {
          $RAD_PAIRS{'next-hop-ip'} = "H323/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER};
        }

        $RAD_PAIRS{'session-protocol'} = $self->{TRUNK_PROTOCOL};
      }
    }
    else {
      $RAD->{'User-Name'} = $RAD->{'Called-Station-Id'};
    }

    if($self->{MAX_SESSION_DURATION} && (! $session_timeout || $session_timeout > $self->{MAX_SESSION_DURATION})) {
      $session_timeout = $self->{MAX_SESSION_DURATION};
    }

    if ($session_timeout > 0) {
      $RAD_PAIRS{'Session-Timeout'} = $session_timeout;
      $RAD_PAIRS{'h323-credit-time'} = $session_timeout;
    }

    #Make start record in voip_calls
    $self->query2("INSERT INTO voip_calls 
     (  status, user_name, started, lupdated,
        calling_station_id, called_station_id, nas_id,
        client_ip_address, conf_id, call_origin, uid,
        bill_id, tp_id, route_id, reduction
     )
     VALUES ('0', ?, NOW(), UNIX_TIMESTAMP(),
       ?, ?, ?, INET_ATON( ? ), ?, ?, ?, ?, ?, ?, ?);", 'do',
     {
       Bind => [
          $RAD->{'User-Name'},
          $RAD->{'Calling-Station-Id'} || q{},
          $RAD->{'Called-Station-Id'} || q{},
          $NAS->{NAS_ID} || 0,
          $RAD->{'Client-IP-Address'} || '0.0.0.0',
          $RAD->{'h323-conf-id'},
          $RAD->{'h323-call-origin'} || 0,
          $self->{UID} || 0,
          $self->{BILL_ID} || 0,
          $self->{TP_ID} || 0,
          $self->{ROUTE_ID} || 0,
          $self->{REDUCTION} || 0
         ]
     });
  }

  if ($self->{ACCOUNT_AGE} && $self->{ACCOUNT_AGE} > 0 && $self->{VOIP_EXPIRE} eq '0000-00-00') {
    $self->query2("UPDATE voip_main SET expire=curdate() + INTERVAL $self->{ACCOUNT_AGE} day 
     WHERE uid='$self->{UID}';", 'do');
  }

  $RAD_PAIRS{'h323-return-code'}=0;
  return 0, \%RAD_PAIRS;
}

#**********************************************************
=head2 get_route_prefix($RAD) - Get route prefix

   Arguments:
     $RAD

   Results:
     $self->{ROUTE_ID}

=cut
#**********************************************************
sub get_route_prefix {
  my $self = shift;
  my ($RAD) = @_;

  # Get route
  my @query_params_arr = ();

  for (my $i = 1 ; $i <= length($RAD->{'Called-Station-Id'}) ; $i++) {
    push @query_params_arr, substr($RAD->{'Called-Station-Id'}, 0, $i);
  }

  if($#query_params_arr < 0) {
    return $self;
  }

  my $query_params = "'". join("', '", @query_params_arr) ."'";

  $self->query2("SELECT r.id AS route_id,
      r.prefix AS prefix,
      r.gateway_id AS gateway_id,
      r.disable AS route_disable
     FROM voip_routes r
      WHERE r.prefix in ($query_params)
      ORDER BY 2 DESC LIMIT 1;",
      undef,
      {INFO => 1}
  );

  #if ($self->{TOTAL} < 1) {
  #  return $self;
  #}
  #($self->{ROUTE_ID}, $self->{PREFIX}, $self->{GATEWAY_ID}, $self->{ROUTE_DISABLE}, $self->{TRUNK_PROTOCOL}, $self->{TRUNK_PATH}) = @{ $self->{list}->[0] };

  return $self;
}

#**********************************************************
=head2 get_intervals()

=cut
#**********************************************************
 sub get_intervals {
  my $self = shift;

  $self->query2("SELECT i.day, TIME_TO_SEC(i.begin), TIME_TO_SEC(i.end), 
    rp.price, i.id, rp.route_id,
    IF (t.protocol IS NULL, '', t.protocol),
    IF (t.protocol IS NULL, '', t.provider_ip),
    IF (t.protocol IS NULL, '', t.addparameter),
    IF (t.protocol IS NULL, '', t.removeprefix),
    IF (t.protocol IS NULL, '', t.addprefix),
    IF (t.protocol IS NULL, '', t.failover_trunk),
    rp.extra_tarification
      FROM intervals i, voip_route_prices rp
      LEFT JOIN voip_trunks t ON (rp.trunk=t.id)
      WHERE
         i.id=rp.interval_id 
         AND i.tp_id  = '$self->{TP_ID}'
         AND rp.route_id = '$self->{ROUTE_ID}';"
  );

  my $list                = $self->{list};
  my %time_periods        = ();
  my %periods_time_tarif  = ();
  $self->{TRUNK_PATH}     = '';
  $self->{TRUNK_PROVIDER} = '';

  foreach my $line (@$list) {
    #$time_periods{INTERVAL_DAY}{INTERVAL_START}="INTERVAL_ID:INTERVAL_END";
    $time_periods{ $line->[0] }{ $line->[1] } = "$line->[4]:$line->[2]";

    #$periods_time_tarif{INTERVAL_ID} = "INTERVAL_PRICE";
    $periods_time_tarif{ $line->[4] } = $line->[3];
    $self->{TRUNK_PROTOCOL}           = $line->[6];
    $self->{TRUNK_PROVIDER}           = $line->[7];
    $self->{ADDPARAMETER}             = $line->[8];
    $self->{REMOVE_PREFIX}            = $line->[9];
    $self->{ADDPREFIX}                = $line->[10];
    $self->{FAILOVER_TRUNK}           = $line->[11];
    $self->{EXTRA_TARIFICATION}       = $line->[12];
  }
  $self->{TIME_PERIODS}       = \%time_periods;
  $self->{PERIODS_TIME_TARIF} = \%periods_time_tarif;

  return $self;
}

#**********************************************************
=head2 accounting($RAD, $NAS) - Accounting functions

=cut
#**********************************************************
sub accounting {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my $acct_status_type = $ACCT_TYPES{ $RAD->{'Acct-Status-Type'} };
  #my $SESSION_START    = (defined($RAD->{SESSION_START}) && $RAD->{SESSION_START} > 0) ? "FROM_UNIXTIME($RAD->{SESSION_START})" : 'NOW()';
  my $sesssion_sum     = 0;
  $RAD->{'Client-IP-Address'} = '0.0.0.0' if (!$RAD->{'Client-IP-Address'});

  preproces($RAD);

  if ($NAS->{NAS_TYPE} eq 'cisco_voip') {
    if ($RAD->{'User-Name'} =~ /(\S+):(\d+)/) {
      $RAD->{'User-Name'} = $2;
    }
  }

  if ($conf->{VOIP_NUMBER_EXPR}) {
    number_expr($RAD);
  }

  #Start
  if ($acct_status_type == 1) {
    if ($NAS->{NAS_TYPE} eq 'cisco_voip') {
      # For Cisco
      $self->user_info($RAD, $NAS);

      $self->query2("INSERT INTO voip_calls 
      (  status,
       user_name,
       started,
       lupdated,
       calling_station_id,
       called_station_id,
       nas_id,
       conf_id,
       call_origin,
       uid,
       bill_id,
       tp_id,
       reduction,
       acct_session_id
      )
     VALUES (?, ?, NOW() - INTERVAL ? SECOND, UNIX_TIMESTAMP(),
       ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);", 'do',
       { Bind => [
        $acct_status_type, 
        $RAD->{'User-Name'},
        $RAD->{'Acct-Session-Time'} || 0,
        $RAD->{'Calling-Station-Id'} || q{},
        $RAD->{'Called-Station-Id'} || q{},
        $NAS->{NAS_ID},
        $RAD->{'h323-conf-id'},
        $RAD->{'h323-call-origin'},
        $self->{UID},
        $self->{BILL_ID},
        $self->{TP_ID} || 0,
        $self->{REDUCTION} || 0,
        $RAD->{'Acct-Session-Id'},
     ]});
    }
    else {
      $self->query2("UPDATE voip_calls SET
      status= ? ,
      acct_session_id= ?
      WHERE conf_id= ? ;", 'do',
        { Bind => [
            $acct_status_type,
            $RAD->{'Acct-Session-Id'},
            $RAD->{'h323-conf-id'}
          ]
        }
      );
    }
  }

  # Stop status
  elsif ($acct_status_type == 2) {
    if ($RAD->{'Acct-Session-Time'} > 0) {
      $self->query2("SELECT 
      UNIX_TIMESTAMP(started) AS session_start,
      lupdated AS last_update,
      acct_session_id,
      calling_station_id,
      called_station_id,
      nas_id,
      client_ip_address,
      conf_id,
      call_origin,
      uid,
      reduction,
      bill_id,
      c.tp_id,
      route_id,
      tp.time_division,
      UNIX_TIMESTAMP() AS session_stop,
      UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
      DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_week,
      DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year
    FROM voip_calls c
    INNER JOIN voip_tps tp ON (c.tp_id=tp.id)
      WHERE conf_id= ?
      AND call_origin= ? ;",
      undef,
      { INFO => 1,
        Bind => [
          $RAD->{'h323-conf-id'},
          $RAD->{'h323-call-origin'}
       ] }
      );

      if ($self->{TOTAL} < 1) {
        $self->{errno}  = 1;
        $self->{errstr} = "CALL_NOT_EXISTS CONF_ID: $RAD->{'h323-conf-id'} ORIGIN:  $RAD->{'h323-call-origin'} ";
        return $self;
      }
      elsif ($self->{errno}) {
        $self->{errno}  = 1;
        $self->{errstr} = "SQL_ERROR";
        return $self;
      }

      if ($self->{UID} == 0) {
        $self->{errno}  = 110;
        $self->{errstr} = "Number not found '" . $RAD->{'User-Name'} . "'";
        return $self;
      }
      elsif ($RAD->{'h323-call-origin'} == 1) {
        if (!$self->{ROUTE_ID}) {
          $self->get_route_prefix($RAD);
        }

        $self->get_intervals();
        if ($self->{TOTAL} < 1) {
          $self->{errno}  = 111;
          $self->{errstr} = "NO_PRICE_FOR_ROUTE_PREFIX '$self->{PREFIX}' NUMBER '" . $RAD->{'Called-Station-Id'} . "'";
          return $self;
        }

        # Extra tarification
        if ($self->{EXTRA_TARIFICATION}) {
          $self->query2("SELECT prepaid_time FROM voip_route_extra_tarification WHERE id='$self->{EXTRA_TARIFICATION}';");
          $self->{PREPAID_TIME} = $self->{list}->[0]->[0];
          if ($self->{PREPAID_TIME} > 0) {
            $self->{LOG_DURATION} = 0;
            my $sql = "SELECT SUM(duration) FROM voip_log l, voip_route_prices rp WHERE l.route_id=rp.route_id
               AND uid='$self->{UID}' AND rp.extra_tarification='$self->{EXTRA_TARIFICATION}'";
            $self->query2("$sql");
            $self->{LOG_DURATION} = 0;
            if ($self->{TOTAL} > 0) {
              $self->{LOG_DURATION} = $self->{list}->[0]->[0];
            }
            if ($RAD->{'Acct-Session-Time'} + $self->{LOG_DURATION} < $self->{PREPAID_TIME}) {
              $self->{PERIODS_TIME_TARIF} = undef;
            }
            elsif ($self->{LOG_DURATION} < $self->{PREPAID_TIME} && $RAD->{'Acct-Session-Time'} + $self->{LOG_DURATION} > $self->{PREPAID_TIME}) {
              $self->{PAID_SESSION_TIME} = $RAD->{'Acct-Session-Time'};
            }
          }
        }

        #Id defined time tarif
        if ($self->{PERIODS_TIME_TARIF}) {
          my $duration = $self->{PAID_SESSION_TIME} || $RAD->{'Acct-Session-Time'};

          if ($self->{TIME_DIVISION}) {
            my $periods = $duration / $self->{TIME_DIVISION};
            if ($periods != int($periods)) {
              $duration = $self->{TIME_DIVISION} * (int($periods) + 1);
            }
          }

          $Billing->time_calculation(
            {
              REDUCTION          => $self->{REDUCTION},
              TIME_INTERVALS     => $self->{TIME_PERIODS},
              PERIODS_TIME_TARIF => $self->{PERIODS_TIME_TARIF},
              SESSION_START      => $self->{SESSION_STOP} - $RAD->{'Acct-Session-Time'},
              ACCT_SESSION_TIME  => $duration,
              DAY_BEGIN          => $self->{DAY_BEGIN},
              DAY_OF_WEEK        => $self->{DAY_OF_WEEK},
              DAY_OF_YEAR        => $self->{DAY_OF_YEAR},
              PRICE_UNIT         => 'Min',
            }
          );

          $sesssion_sum = $Billing->{SUM};
          if ($Billing->{errno}) {
            $self->{errno}  = $Billing->{errno};
            $self->{errstr} = $Billing->{errstr};
            return $self;
          }
        }
      }

      my $filename;
      $self->query2("INSERT INTO voip_log (uid, start, duration, calling_station_id, called_station_id,
              nas_id, client_ip_address, acct_session_id, tp_id, bill_id, sum, terminate_cause, route_id) 
        VALUES (?, NOW() - INTERVAL ? SECOND, ?, ?, ?, ?, INET_ATON( ? ), ?, ?, ?, ?, ?, ?);", 'do',
        { 
          Bind => [
            $self->{UID},
            $RAD->{'Acct-Session-Time'} || 0,
            $RAD->{'Acct-Session-Time'} || 0,
            $RAD->{'Calling-Station-Id'} || q{},
            $RAD->{'Called-Station-Id'} || q{},
            $NAS->{NAS_ID}, 
            $RAD->{'Client-IP-Address'} || '0.0.0.0',
            $RAD->{'Acct-Session-Id'}, 
            $self->{TP_ID}, 
            $self->{BILL_ID}, 
            $sesssion_sum,
            $RAD->{'Acct-Terminate-Cause'} || 0, 
            $self->{ROUTE_ID}
          ] 
        }
      );

      if ($self->{errno}) {
        $filename = $RAD->{'User-Name'}.'.'.$RAD->{'Acct-Session-Id'};
        $self->{LOG_WARNING} = "ACCT [". $RAD->{'User-Name'} ."] Making accounting file '$filename'";
        $Billing->mk_session_log($RAD);
      }

      # If SQL query filed
      else {
        if ($Billing->{SUM} > 0) {
          $self->query2("UPDATE bills SET deposit=deposit-$Billing->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
        }
      }
    }
    else {

    }

    # Delete from session wtmp
    $self->query2("DELETE FROM voip_calls 
     WHERE acct_session_id = ? 
     and nas_id= ?
     and conf_id= ? ;", 'do',
     { Bind => [
         $RAD->{'Acct-Session-Id'},
         $NAS->{NAS_ID},
         $RAD->{'h323-conf-id'}
       ]
     }
    );
  }
  #Alive status 3
  elsif ($acct_status_type eq 3) {
    $self->query2("UPDATE voip_calls SET
    status= ? ,
    client_ip_address = INET_ATON( ? ),
    lupdated=UNIX_TIMESTAMP()
   WHERE
    acct_session_id = ? AND
    user_name= ?
    );", 'do',
    { Bind => [
        $acct_status_type,
        $RAD->{'Framed-IP-Address'},
        $RAD->{'Acct-Session-Id'},
        $RAD->{'User-Name'}
      ]
    }
    );
  }
  else {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [". $RAD->{'User-Name'} ."] Unknown accounting status: ". $RAD->{'Acct-Status-Type'} ." (". $RAD->{'Acct-Session-Id'} .")";
  }

  if ($self->{errno}) {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT ". $RAD->{'Acct-Status-Type'} ."SQL Error ". $RAD->{'Acct-Session-Id'} ." [$self->{errno}] $self->{errstr}";
  }

  return $self;
}

1
