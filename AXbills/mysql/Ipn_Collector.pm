package Ipn_Collector v7.0.1;

=head1 NAME
 
 Ipn Collector functions

=cut

use strict;
our (@ISA, @EXPORT_OK, %EXPORT_TAGS);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use parent qw( dbcore Exporter );

our @EXPORT = qw(
  ip_in_zone
  );

use Billing;
use Tariffs;
use AXbills::Base qw( int2ip ip2int in_array );

my $Billing;
my $Tariffs;
my %ips = ();
#my $CONF;
my %intervals = ();
my %tp_interval = ();
my %ip_range = ();
my %ip_user_hash = ();
my %ip_class_tables = ();

my $traffic_details = 0;

#**********************************************************
# Init
#**********************************************************
sub new{
  my $class = shift;
  my ($db, $CONF) = @_;

  my $self = { };
  bless( $self, $class );

  if ( $CONF->{DELETE_USER} ){
    return $self;
  }

  if ( !defined( $CONF->{KBYTE_SIZE} ) ){
    $CONF->{KBYTE_SIZE} = 1024;
  }

  $self->{db}   = $db;
  $self->{conf} = $CONF;

  $CONF->{IPN_DETAIL_MIN_SIZE} = 0 if (!$CONF->{IPN_DETAIL_MIN_SIZE});
  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
  $self->{TRAFFIC_ROWS} = 0;
  $self->{UNKNOWN_TRAFFIC_ROWS} = 0;

  #alternative host for detail
  if ( $CONF->{IPN_DBHOST} ){
    require AXbills::SQL;
    AXbills::SQL->import();

    my $sql = AXbills::SQL->connect( 'mysql', $CONF->{IPN_DBHOST}, $CONF->{IPN_DBNAME}, $CONF->{IPN_DBUSER},
      $CONF->{IPN_DBPASSWD}, { CHARSET => ($CONF->{IPN_DBCHARSET}) ? $CONF->{IPN_DBCHARSET} : 'utf8' } );

    if ( !$sql->{db} ){
      exit;
    }
    $self->{db2} = $sql->{db};
  }

  $traffic_details = $self->{conf}->{IPN_DETAIL} || $self->{conf}->{INTERNET_TRAFFIC_DETAIL};
  $Billing = Billing->new( $self->{db}, $CONF );

  return $self;
}

#**********************************************************
=head2 user_ips($DATA)

=cut
#**********************************************************
sub user_ips{
  my $self = shift;
  my ($DATA) = @_;

  my $sql;

  if ( $DATA->{NAS_ID} =~ /(\d+)-(\d+)/ ){
    my $first = $1;
    my $last = $2;
    my @nas_arr = ();
    for ( my $i = $first; $i <= $last; $i++ ){
      push @nas_arr, $i;
    }
    $DATA->{NAS_ID} = join( ',', @nas_arr );
  }

  #Tarifs dv.tp_id -> tp.tp_id
  my %tp_ids = ();
  $self->query( "SELECT id, tp_id FROM tarif_plans;" );

  foreach my $line ( @{ $self->{list} } ){
    $tp_ids{$line->[0]} = $line->[1];
  }

  if ( $self->{conf}->{IPN_STATIC_IP} ){
    $sql = "select u.uid, dv.ip, u.id AS login, 
     if(calls.acct_session_id, calls.acct_session_id, '') AS acct_session_id,
     dv.tp_id, 
     if (u.company_id > 0, cb.id, b.id) AS bill_id,
     if (c.name IS NULL, b.deposit, cb.deposit)+if(u.credit>0, u.credit, tp.credit) AS deposit,
     tp.payment_type,
     tp.octets_direction,
     u.reduction,
     u.activate,
     dv.netmask,
     calls.acct_input_gigawords,
     calls.acct_output_gigawords,
     dv.join_service
     FROM (users u, dv_main dv)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)
     LEFT JOIN dv_calls calls ON (u.id=calls.user_name)
     LEFT JOIN users_nas un ON(u.uid=un.uid)
     WHERE u.uid=dv.uid and u.domain_id=0
      and dv.ip > 0 and u.disable=0 and dv.disable=0
      and (un.nas_id IN ($DATA->{NAS_ID}) or un.nas_id IS NULL)
     GROUP BY u.uid;";
  }
  elsif ( $self->{conf}->{IPN_DEPOSIT_OPERATION} ){
    $sql = "SELECT u.uid, calls.framed_ip_address AS ip, 
      calls.user_name AS login,
      calls.acct_session_id,
      calls.acct_input_octets,
      calls.acct_output_octets,
      dv.tp_id,
      if(u.company_id > 0, cb.id, b.id) AS bill_id,
      if(c.name IS NULL, b.deposit, cb.deposit)+if(u.credit>0, u.credit, tp.credit) AS deposit,
      tp.payment_type,
      UNIX_TIMESTAMP() - calls.lupdated AS interim_time,
      calls.nas_id,
      tp.octets_direction,
      u.reduction,
      CONNECT_INFO,
      u.activate,
      dv.netmask,
      calls.acct_input_gigawords,
      calls.acct_output_gigawords,
      dv.join_service
    FROM (dv_calls calls, users u)
      LEFT JOIN companies c ON (u.company_id=c.id)
      LEFT JOIN bills b ON (u.bill_id=b.id)
      LEFT JOIN bills cb ON (c.bill_id=cb.id)
      LEFT JOIN dv_main dv ON (u.uid=dv.uid)
      LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)
    WHERE u.id=calls.user_name
      AND u.domain_id=0
      AND calls.status<11
    and calls.nas_id IN ($DATA->{NAS_ID}) ;";
  }
  else{
    $sql = "SELECT u.uid, 
    calls.framed_ip_address AS ip, 
    calls.user_name AS login, 
    calls.acct_session_id,
    calls.acct_input_octets,
    calls.acct_output_octets,
    calls.tp_id,
    UNIX_TIMESTAMP() - calls.lupdated AS interim_time,
    calls.nas_id,
    u.reduction,
    CONNECT_INFO,
    u.activate,
    dv.netmask,
    dv.join_service
    FROM (dv_calls calls, users u)
    LEFT JOIN dv_main dv ON (u.uid=dv.uid)
   WHERE u.id=calls.user_name AND u.domain_id=0 AND calls.status<11
   and calls.nas_id IN ($DATA->{NAS_ID});";
  }

  $self->query( $sql, undef, { COLS_NAME => 1 } );

  if ( $self->{errno} ){
    print "SQL Error: Get online users\n";
    exit;
  }

  my $list = $self->{list};
  my %session_ids = ();
  my %users_info = ();
  my %interim_times = ();
  my %connect_info = ();

  $ips{0} = '0';
  $self->{0}{IN} = 0;
  $self->{0}{OUT} = 0;

  foreach my $line ( @{$list} ){
    my $ip = $line->{ip};

    #Get IP/mask
    if ( $line->{netmask} && $line->{netmask} < 4294967295 ){
      my $count = 4294967295 - $line->{netmask};
      my $ip2hash = $ip;
      $ip = pack( 'N4N4', $ip, $count );
      $ip_range{ $line->{uid} } = $ip;
      for ( my $i = 0; $i <= $count; $i++ ){
        $ip_user_hash{$ip2hash + $i} = $line->{uid};
      }
    }
    $ips{$ip} = $line->{uid};

    #IN / OUT octets
    $self->{$ip}{IN} = $line->{acct_input_octets} || 0;
    $self->{$ip}{OUT} = $line->{acct_output_octets} || 0;

    $self->{$ip}{ACCT_INPUT_GIGAWORDS} = $line->{acct_input_gigawords} || 0;
    $self->{$ip}{ACCT_OUTPUT_GIGAWORDS} = $line->{acct_output_gigawords} || 0;

    #user NAS
    $self->{$ip}{NAS_ID} = $line->{nas_id} || 0;

    #Octet direction
    $self->{$ip}{OCTET_DIRECTION} = $line->{octets_direction} || 0;

    if ( $tp_ids{$line->{tp_id}} ){
      $line->{tp_id} = $tp_ids{$line->{tp_id}};
    }

    $users_info{TPS}{ $line->{uid} } = $line->{tp_id};

    #User login
    $users_info{LOGINS}{ $line->{uid} } = $line->{login} || '';

    #Session ID
    $session_ids{$ip} = $line->{acct_session_id} || '';
    $interim_times{ $line->{ip} } = $line->{interim_time} || 0;
    $connect_info{ $line->{ip} } = $line->{CONNECT_INFO} || '';

    #$self->{INTERIM}{$line->[3]}{TIME}=$line->[10];
    $users_info{PAYMENT_TYPE}{ $line->{uid} } = $line->{payment_type};
    $users_info{DEPOSIT}{ $line->{uid} } = $line->{deposit};
    $users_info{REDUCTION}{ $line->{uid} } = $line->{reduction};
    $users_info{ACTIVATE}{ $line->{uid} } = $line->{activate};
    $users_info{BILL_ID}{ $line->{uid} } = $line->{bill_id};
    $users_info{JOIN_SERVICE}{ $line->{uid} } = $line->{join_service} if ( $line->{join_service} );
  }

  $self->{USERS_IPS} = \%ips;
  $self->{USERS_INFO} = \%users_info;
  $self->{SESSIONS_ID} = \%session_ids;
  $self->{INTERIM_TIME} = \%interim_times;
  $self->{CONNECT_INFO} = \%connect_info;

  return $self;
}

#**********************************************************
=head2 traffic_agregate_clean()

=cut
#**********************************************************
sub traffic_agregate_clean{
  my $self = shift;

  delete $self->{AGREGATE_USERS};
  delete $self->{INTERIM};
  delete $self->{IN};
}

#**********************************************************
=head2 traffic_agregate_users($DATA) - Get Data and agregate it by users

  Arguments:
    $DATA  - Data hash_ref
      SRC_IP
      DST_IP
      SRC_PORT
      DST_PORT
      PROTOCOL
      SIZE
      NAS_ID
      UID
      START
      STOP

  Returns:

=cut
#**********************************************************
sub traffic_agregate_users{
  my $self = shift;
  my ($DATA) = @_;

  my $users_ips = $self->{USERS_IPS};
  my $y = 0;
  if ( defined( $users_ips->{ $DATA->{SRC_IP} } ) ){
    my $uid = $users_ips->{ $DATA->{SRC_IP} };
    if ( defined( $DATA->{TRAFFIC_CLASS} ) ){
      $self->{INTERIM}{ $DATA->{SRC_IP} }{ $DATA->{TRAFFIC_CLASS} }{OUT} += $DATA->{SIZE};
    }
    else{
      push @{ $self->{AGREGATE_USERS}{$uid}{OUT} }, { %{$DATA} };
    }

    $DATA->{UID} = $uid;
    $y++;
  }
  else{
    if ( $ip_user_hash{$DATA->{SRC_IP}} ){
      my $uid = $ip_user_hash{$DATA->{SRC_IP}};
      push @{ $self->{AGREGATE_USERS}{$uid}{OUT} }, { %{$DATA} };
      $DATA->{UID} = $uid;
      $y++;
    }
  }

  if ( defined( $users_ips->{ $DATA->{DST_IP} } ) ){
    if ( defined( $DATA->{TRAFFIC_CLASS} ) ){
      $self->{INTERIM}{ $DATA->{DST_IP} }{ $DATA->{TRAFFIC_CLASS} }{IN} += $DATA->{SIZE};
    }
    else{
      push @{ $self->{AGREGATE_USERS}{ $users_ips->{ $DATA->{DST_IP} } }{IN} }, { %{$DATA} };
    }
    $DATA->{UID} = $users_ips->{ $DATA->{DST_IP} };

    $y++;
  }
  else{
    if ( defined( $ip_user_hash{$DATA->{DST_IP}} ) ){
      my $uid = $ip_user_hash{$DATA->{DST_IP}};
      push @{ $self->{AGREGATE_USERS}{$uid}{IN} }, { %{$DATA} };
      $DATA->{UID} = $uid;
      $y++;
    }

    #Unknown Ips
    if ( $y < 1 ){
      $DATA->{UID} = 0;
      if ( $self->{conf}->{UNKNOWN_IP_LOG} ){
        $self->{INTERIM}{ $DATA->{UID} }{OUT} += $DATA->{SIZE};
        push @{ $self->{IN} }, "$DATA->{SRC_IP}/$DATA->{DST_IP}/$DATA->{SIZE}";
      }

      if ( $DATA->{DEBUG} ){
        $self->{UNKNOWN_TRAFFIC_ROWS}++;
        $self->{UNKNOWN_TRAFFIC_SUM} += $DATA->{SIZE};
      }

      return $self;
    }
  }

  if ( $DATA->{DEBUG} ){
    $self->{TRAFFIC_ROWS}++;
    $self->{TRAFFIC_SUM} += $DATA->{SIZE};
  }

  #Make user detalization
  if ( $traffic_details && $DATA->{UID} > 0 ){
    return $self if ($self->{conf}->{IPN_DETAIL_MIN_SIZE} > $DATA->{SIZE});
    $self->traffic_add( $DATA );
  }

  return $self;
}

#**********************************************************
=head2 traffic_agregate_nets($DATA)

=cut
#**********************************************************
sub traffic_agregate_nets{
  my $self = shift;
  #my ($DATA) = @_;

  my $AGREGATE_USERS = $self->{AGREGATE_USERS};
  #Get user and session TP
  while (my ($uid, $session_tp) = each( %{ $self->{USERS_INFO}->{TPS} } )) {
    my $TP_ID = $session_tp;

    if ( !defined( $tp_interval{$TP_ID} ) ){
      my $user;
      my ($TIME_INTERVALS,
        $INTERVAL_TIME_TARIF,
        $INTERVAL_TRAF_TARIF) = $Billing->time_intervals( $TP_ID );

      my (undef, $ret_attr) = $Billing->remaining_time(
        0,
        {
          TIME_INTERVALS      => $TIME_INTERVALS,
          INTERVAL_TIME_TARIF => $INTERVAL_TIME_TARIF,
          INTERVAL_TRAF_TARIF => $INTERVAL_TRAF_TARIF,
          SESSION_START       => $user->{SESSION_START},
          DAY_BEGIN           => $user->{DAY_BEGIN},
          DAY_OF_WEEK         => $user->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $user->{DAY_OF_YEAR},
          REDUCTION           => $user->{REDUCTION} || 0,
          POSTPAID            => 1
        }
      );

      $tp_interval{$TP_ID} = ($ret_attr->{FIRST_INTERVAL}) ? $ret_attr->{FIRST_INTERVAL} : 0;
      $intervals{ $tp_interval{$TP_ID} }{TIME_TARIFF} = ($ret_attr->{TIME_PRICE}) ? $ret_attr->{TIME_PRICE} : 0;
    }

    print "\nUID: $uid\n####TP $TP_ID Interval: $tp_interval{$TP_ID}  ####\n" if ($self->{debug});

    if ( !defined( $intervals{ $tp_interval{$TP_ID} }{ZONES} ) ){
      $self->get_zone( { TP_INTERVAL => $tp_interval{$TP_ID} } );
    }
    else{
      $self->{ZONES} = $intervals{ $tp_interval{$TP_ID} }{ZONES};
    }

    my $data_hash;

    #Get agrigation data
    if ( defined( $AGREGATE_USERS->{$uid} ) ){
      $data_hash = $AGREGATE_USERS->{$uid};
    }
    # Go to next user
    else{
      next;
    }

    my %zones;
    my $zoneids_ref = $intervals{ $tp_interval{$TP_ID} }{ZONEIDS};
    my $user_ip;
    if ( $ip_range{$uid} ){
      $user_ip = $ip_range{$uid};
    }

    if ( defined( $data_hash->{OUT} ) ){
      #Get User data array
      my $DATA_ARRAY_REF = $data_hash->{OUT};

      foreach my $DATA ( @{$DATA_ARRAY_REF} ){
        if ( $#{ $zoneids_ref } > -1 ){
          foreach my $zid ( @{ $zoneids_ref } ){
            if ( ip_in_zone( $DATA->{DST_IP}, $DATA->{DST_PORT}, $self->{ZONES}{$zid}{TRAFFIC_CLASS},
              \%ip_class_tables ) ){
              $self->{INTERIM}{ (($user_ip) ? $user_ip : $DATA->{SRC_IP}) }{"$zid"}{OUT} += $DATA->{SIZE};
              print " $zid " . int2ip( $DATA->{SRC_IP} ) . ":$DATA->{SRC_PORT} -> " . int2ip( $DATA->{DST_IP} ) . ":$DATA->{DST_PORT}  $DATA->{SIZE} / " . (($zones{$zid}{PriceOut}) ? $zones{$zid}{PriceOut} : 0.00) . "\n" if ($self->{debug});
              last;
            }
          }
        }
        else{
          print " < $DATA->{SIZE} " . int2ip( $DATA->{SRC_IP} ) . ":$DATA->{SRC_PORT} -> " . int2ip( $DATA->{DST_IP} ) . ":$DATA->{DST_PORT}\n" if ($self->{debug});
          $self->{INTERIM}{ $DATA->{SRC_IP} }{"0"}{OUT} += $DATA->{SIZE};
        }
      }
    }

    if ( defined( $data_hash->{IN} ) ){

      #Get User data array
      my $DATA_ARRAY_REF = $data_hash->{IN};
      foreach my $DATA ( @{$DATA_ARRAY_REF} ){
        if ( $#{ $zoneids_ref } > -1 ){
          foreach my $zid ( @{ $zoneids_ref } ){
            if ( ip_in_zone( $DATA->{SRC_IP}, $DATA->{SRC_PORT}, $self->{ZONES}{$zid}{TRAFFIC_CLASS},
              \%ip_class_tables ) ){
              $self->{INTERIM}{ (($user_ip) ? $user_ip : $DATA->{DST_IP}) }{"$zid"}{IN} += $DATA->{SIZE};
              print " $zid " . int2ip( $DATA->{DST_IP} ) . ":$DATA->{DST_PORT} <- " . int2ip( $DATA->{SRC_IP} ) . ":$DATA->{SRC_PORT}  $DATA->{SIZE} / $zones{$zid}{PriceIn}\n" if ($self->{debug});
              last;
            }
          }
        }
        else{
          print " > $DATA->{SIZE} " . int2ip( $DATA->{SRC_IP} ) . ":$DATA->{SRC_PORT} -> " . int2ip( $DATA->{DST_IP} ) . ":$DATA->{DST_PORT}\n" if ($self->{debug});
          $self->{INTERIM}{ $DATA->{DST_IP} }{"0"}{IN} += $DATA->{SIZE};
        }
      }
    }
  }

  return 1
}

#**********************************************************
=head2 get_interval_params()

=cut
#**********************************************************
sub get_interval_params{
  #my $self = shift;

  return \%intervals, \%tp_interval;
}

#**********************************************************
# Get zones from db
#**********************************************************
sub get_zone{
  my $self = shift;
  my ($attr) = @_;

  my %zones = ();
  my @zoneids = ();

  my $tariff = $attr->{TP_INTERVAL} || 0;

  #Get traffic classes and prices
  $Tariffs = Tariffs->new( $self->{db}, $self->{conf}, ($attr->{ADMIN} || undef) );
  my $list = $Tariffs->tt_list( { TI_ID => $tariff } );

  foreach my $line ( @{$list} ){
    my $zoneid = $line->[0];
    $zones{$zoneid}{PriceIn} = $line->[1] + 0;
    $zones{$zoneid}{PriceOut} = $line->[2] + 0;
    $zones{$zoneid}{PREPAID_TSUM} = $line->[3] + 0;
    $zones{$zoneid}{TRAFFIC_CLASS} = $line->[9];
    push @zoneids, $zoneid;
  }

  @{ $intervals{$tariff}{ZONEIDS} } = @zoneids;
  %{ $intervals{$tariff}{ZONES} } = %zones;

  $self->{ZONES_IDS} = $intervals{$tariff}{ZONEIDS};
  $self->{ZONES} = $intervals{$tariff}{ZONES};

  #Get IP addresse for each traffic zones
  if ( !%ip_class_tables ){
    $self->query( "SELECT id, nets FROM traffic_classes;" );
    foreach my $line ( @{ $self->{list} } ){
      my $zoneid = $line->[0];
      $line->[1] =~ s/\n//g;
      my @ip_list_array = split( /;/, $line->[1] );

      my $i = 0;

      foreach my $ip_full ( @ip_list_array ){
        if ( $ip_full =~ /([!]{0,1})(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\/{0,1})(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\d{1,2})(:{0,1})(\S{0,100})/ ){
          my $NEG = $1 || '';
          my $IP = unpack( "N", pack( "C4", split( /\./, $2 ) ) );
          my $NETMASK = (length( $4 ) < 3) ? unpack("N", pack( "B*", ("1" x $4 . "0" x (32 - $4)) )) : unpack( "N",
              pack( "C4", split( /\./, "$4" ) ) );

          print "REG $i ID: $zoneid NEGATIVE: $NEG IP: " . int2ip( $IP ) . " MASK: " . int2ip( $NETMASK ) . " Ports: $6\n" if ($self->{debug});

          $ip_class_tables{$zoneid}[$i]{IP} = $IP;
          $ip_class_tables{$zoneid}[$i]{Mask} = $NETMASK;
          $ip_class_tables{$zoneid}[$i]{Neg} = $NEG;

          #Get ports
          @{ $ip_class_tables{$zoneid}[$i]{'Ports'} } = ();
          if ( $6 ne '' ){
            my @PORTS_ARRAY = split( /,/, $6 );
            foreach my $port ( @PORTS_ARRAY ){
              push @{ $ip_class_tables{$zoneid}[$i]{Ports} }, $port;
            }
          }
          $i++;
        }
      }
    }

    $self->{ZONES_IPS} = \%ip_class_tables;
  }

  print " Tariff Interval: $tariff\n" . " Zone Ids:" . @{ $intervals{$tariff}{ZONEIDS} } . "\n" . " Zones:" . %{ $intervals{$tariff}{ZONES} } . "\n" if ($self->{debug});

  return $self;
}

#**********************************************************
=head2 ip_in_zone($ip_num, $port, $zoneid, $zone_data) - Check IP in zone

  Arguments:
    $ip_num,    - IP in NUm format
    $port       - Port
    $zoneid     - Zone ID
    $zone_data  - Zone hash_ref
       IP    - IP in num format;
       Mask  - NETMASK in num format
       Neg   - Negative result
       Ports - Array of ports

  Result:
    0 - True
    1 - False

=cut
#**********************************************************
sub ip_in_zone($$$$){
  my ($ip_num, $port, $zoneid, $zone_data) = @_;

  my $res = 0;

  return 0 if (!$zone_data->{$zoneid});

  for ( my $i = 0; $i <= $#{ $zone_data->{$zoneid} }; $i++ ){
    my $adr_hash = \%{ $zone_data->{$zoneid}[$i] };
    # compare zone with ip
    if ( (($adr_hash->{'IP'} & $adr_hash->{'Mask'}) == ($ip_num & $adr_hash->{'Mask'}))
      && ($#{$$adr_hash{'Ports'}} == -1 || $port ~~ @{ $adr_hash->{'Ports'} } )
    ){
      if ( $adr_hash->{'Neg'} ){
        $res = 0;
      }
      else {
        $res = 1;
        next;
      }
    }
  }

  return $res;
}

#**********************************************************
=head2 traffic_add_user($DATA) - Add traffic to DB

=cut
#**********************************************************
sub traffic_add_user{
  my $self = shift;
  my ($DATA) = @_;

  if ( $DATA->{MULTI_QUERY} ){
    $self->query( "INSERT INTO ipn_log (
         uid, start, stop, traffic_class, traffic_in, traffic_out,
         nas_id, ip, interval_id, sum, session_id
       )
     VALUES (
       ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
      '',
      { MULTI_QUERY => $DATA->{MULTI_QUERY} }
    );
  }
  elsif ( $DATA->{INBYTE} + $DATA->{OUTBYTE} > 0 ){
    $self->query( "INSERT INTO ipn_log (
         uid, start, stop, traffic_class, traffic_in, traffic_out,
         nas_id, ip, interval_id, sum, session_id
       )
     VALUES (
       ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
      'do',
      { Bind => [
          $DATA->{UID},
          $DATA->{START} || 'NOW()',
          $DATA->{STOP} || 'NOW()',
          $DATA->{TARFFIC_CLASS},
          $DATA->{INBYTE} || 0,
          $DATA->{OUTBYTE} || 0,
          $DATA->{NAS_ID},
          $DATA->{IP},
          $DATA->{INTERVAL},
          $DATA->{SUM},
          $DATA->{SESSION_ID}
        ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 traffic_user_get2($attr) - Get used traffic from DB

=cut
#**********************************************************
sub traffic_user_get2{
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID};
  #my $from   = $attr->{FROM} || '';
  my %result = ();
  my $WHERE = '';

  if ( $attr->{JOIN_SERVICE} ){
    my @uids_arr = ();
    if ( $attr->{JOIN_SERVICE} == 1 ){
      push @uids_arr, $uid;
      $attr->{JOIN_SERVICE} = $uid;
    }

    $self->query( "SELECT uid FROM dv_main WHERE join_service='$attr->{JOIN_SERVICE}'" );

    foreach my $line ( @{ $self->{list} } ){
      push @uids_arr, $line->[0];
    }

    $WHERE = "uid IN (" . join( ', ', @uids_arr ) . ") AND ";
  }
  else{
    $WHERE = " uid='$uid' AND ";
  }

  if ( $attr->{DATE_TIME} ){
    $WHERE .= "start>=$attr->{DATE_TIME}";
  }
  elsif ( $attr->{INTERVAL} ){
    my ($from, $to) = split( /\//, $attr->{INTERVAL} );
    $from = ($from eq '0000-00-00') ? 'DATE_FORMAT(started, \'%Y-%m\')>=DATE_FORMAT(CURDATE(), \'%Y-%m\')' : "DATE_FORMAT(started, '\%Y-\%m-\%d')>='$from'";
    $WHERE = "( $from AND started<'$to') ";
  }
  elsif ( $attr->{ACTIVATE} ){
    if ( $attr->{ACTIVATE} eq '0000-00-00' ){
      $attr->{ACTIVATE} = "DATE_FORMAT(CURDATE(), '%Y-%m-01')";
    }
    else{
      $attr->{ACTIVATE} = "'$attr->{ACTIVATE}'";
    }
    $WHERE .= "DATE_FORMAT(started, '%Y-%m-%d')>=$attr->{ACTIVATE}";
  }
  else{
    $WHERE .= "DATE_FORMAT(started, '%Y-%m')>=DATE_FORMAT(CURDATE(), '%Y-%m')";
  }

  if ( defined( $attr->{TRAFFIC_ID} ) ){
    $WHERE .= "AND traffic_class='$attr->{TRAFFIC_ID}'";
  }

  $self->query( "SELECT started,
   uid,
   traffic_class,
   traffic_in / $self->{conf}->{MB_SIZE},
   traffic_out / $self->{conf}->{MB_SIZE}
    FROM traffic_prepaid_sum
    WHERE $WHERE;"
  );

  if ( $self->{TOTAL} < 1 ){
    $self->query( "INSERT INTO traffic_prepaid_sum (uid, started, traffic_class, traffic_in, traffic_out)
        VALUES ('$uid', $attr->{ACTIVATE}, '$attr->{TRAFFIC_ID}', '$attr->{TRAFFIC_IN}', '$attr->{TRAFFIC_OUT}')", 'do'
    );

    $result{ $attr->{TRAFFIC_ID} }{TRAFFIC_IN} = 0;
    $result{ $attr->{TRAFFIC_ID} }{TRAFFIC_OUT} = 0;

    return \%result;
  }

  foreach my $line ( @{ $self->{list} } ){
    #Traffic class
    $result{ $line->[2] }{TRAFFIC_IN} = $line->[3];
    $result{ $line->[2] }{TRAFFIC_OUT} = $line->[4];
  }

  $self->query( "UPDATE traffic_prepaid_sum SET
     traffic_in=traffic_in+$attr->{TRAFFIC_IN},
     traffic_out=traffic_out+$attr->{TRAFFIC_OUT}
    WHERE uid='$uid'
        AND $WHERE;", 'do'
  );

  return \%result;
}

#**********************************************************
=head2 traffic_user_get($attr) - Get used traffic from DB

=cut
#**********************************************************
sub traffic_user_get{
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID};
  #my $traffic_id = $attr->{TRAFFIC_ID} || 0;
  #my $from       = $attr->{FROM} || '';
  my %result = ();
  my $WHERE = '';
  my $GROUP_BY = 'traffic_class';

  if ( $attr->{JOIN_SERVICE} ){
    my @uids_arr = ();
    if ( $attr->{JOIN_SERVICE} == 1 ){
      push @uids_arr, $uid;
      $attr->{JOIN_SERVICE} = $uid;
    }

    $self->query( "SELECT uid FROM dv_main WHERE join_service='$attr->{JOIN_SERVICE}'" );

    foreach my $line ( @{ $self->{list} } ){
      push @uids_arr, $line->[0];
    }

    $WHERE = " uid IN (" . join( ', ', @uids_arr ) . ") AND ";
    $GROUP_BY = 'uid, traffic_class';
  }
  else{
    $WHERE = " uid='$uid' AND ";
  }

  if ( $attr->{DATE_TIME} ){
    $WHERE .= "start>=$attr->{DATE_TIME}";
  }
  elsif ( $attr->{INTERVAL} ){
    my ($from, $to) = split( /\//, $attr->{INTERVAL} );
    $from = ($from eq '0000-00-00') ? 'DATE_FORMAT(start, \'%Y-%m\')>=DATE_FORMAT(curdate(), \'%Y-%m\')' : "DATE_FORMAT(start, '\%Y-\%m-\%d')>='$from'";
    $WHERE .= "( $from AND start<'$to') ";
  }
  elsif ( $attr->{ACTIVATE} && $attr->{ACTIVATE} ne '0000-00-00' ){
    $WHERE .= "DATE_FORMAT(start, '%Y-%m-%d')>='$attr->{ACTIVATE}'";
  }
  else{
    $WHERE .= "DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(curdate(), '%Y-%m')";
  }

  $self->query( "SELECT traffic_class, SUM(traffic_in) / $self->{conf}->{MB_SIZE}, sum(traffic_out) / $self->{conf}->{MB_SIZE}
    FROM ipn_log
        WHERE $WHERE
        GROUP BY $GROUP_BY",
    undef,
    $attr
  );

  foreach my $line ( @{ $self->{list} } ){
    #Trffic class
    $result{ $line->[0] }{TRAFFIC_IN} = $line->[1];
    $result{ $line->[0] }{TRAFFIC_OUT} = $line->[2];
  }

  return \%result;
}

#**********************************************************
=head2 traffic_add($DATA) - Add traffic to DB

  Arguments:
    $DATA  - Data hash_ref
      SRC_IP
      DST_IP
      SRC_PORT
      DST_PORT
      PROTOCOL
      SIZE
      NAS_ID
      UID
      START
      STOP

  Returns:
    Object

=cut
#**********************************************************
sub traffic_add{
  my $self = shift;
  my ($DATA) = @_;

  $self->query( "INSERT INTO ipn_traf_detail (src_addr,
       dst_addr,
       src_port, 
       dst_port, 
       protocol, 
       size, 
       s_time, 
       f_time, 
       nas_id, 
       uid)
     VALUES (
        ?, ?, ?, ?, ?, ?, 
        if('$DATA->{START}' = '', NOW(), '$DATA->{START}'), 
        if('$DATA->{STOP}' = '', NOW(), '$DATA->{STOP}'), 
        ?, 
        ?);", 'do',
    { Bind   => [
        $DATA->{SRC_IP},
        $DATA->{DST_IP},
        $DATA->{SRC_PORT} || 0,
        $DATA->{DST_PORT} || 0,
        $DATA->{PROTOCOL} || 0,
        $DATA->{SIZE},
        $DATA->{NAS_ID} || 0,
        $DATA->{UID} || 0,
      ],
      DB_REF => $self->{db2}
    }
  );

  return $self;
}

#**********************************************************
=head2 acct_update($DATA) Acct_update

=cut
#**********************************************************
sub acct_update{
  my $self = shift;
  my ($DATA) = @_;

  $self->query( "UPDATE dv_calls SET
      sum=sum + ?,
      acct_input_octets=acct_input_octets + ?,
      acct_output_octets=acct_output_octets+ ?,
      ex_input_octets=ex_input_octets + ?,
      ex_output_octets=ex_output_octets + ?,
      acct_input_gigawords=  ? ,
      acct_output_gigawords= ? ,
      status='3',
      acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
      framed_ip_address=INET_ATON( ? ),
      lupdated=UNIX_TIMESTAMP()
    WHERE
      acct_session_id= ?
      AND uid= ?
      AND nas_id= ? ;",
    'do',
    { Bind => [
        $DATA->{SUM},
        $DATA->{INTERIUM_INBYTE},
        $DATA->{INTERIUM_OUTBYTE},
        $DATA->{INBYTE2} || 0,
        $DATA->{OUTBYTE2} || 0,
        $DATA->{ACCT_INPUT_GIGAWORDS},
        $DATA->{ACCT_OUTPUT_GIGAWORDS},
        $DATA->{FRAMED_IP_ADDRESS},
        $DATA->{ACCT_SESSION_ID},
        $DATA->{UID},
        $DATA->{NAS_ID}
      ] }
  );

  if ( $self->{USERS_INFO}->{DEPOSIT}->{ $DATA->{UID} } ){
    #Take money from bill
    if ( $DATA->{SUM} > 0 ){
      $self->query( "UPDATE bills SET deposit=deposit- ? WHERE id= ? ;", 'do', { Bind => [
            $DATA->{SUM},
            $self->{USERS_INFO}->{BILL_ID}->{$DATA->{UID}}
          ] } );
    }

    #If negative deposit hangup
    if ( $self->{USERS_INFO}->{DEPOSIT}->{ $DATA->{UID} } - $DATA->{SUM} < 0 ){
      $self->{USERS_INFO}->{DEPOSIT}->{ $DATA->{UID} } = $self->{USERS_INFO}->{DEPOSIT}->{ $DATA->{UID} } - $DATA->{SUM};
    }
  }

  return $self;
}

#**********************************************************
=head1 acct_stop($attr) - Stop accounting
  Arguments:
    $attr
      ACCT_SESSION_ID
      GUEST

  Returns:

=cut
#**********************************************************
sub acct_stop{
  my $self = shift;
  my ($attr) = @_;

  if ( !$attr->{ACCT_SESSION_ID} && $attr->{SESSION_ID} ){
    $attr->{ACCT_SESSION_ID} = $attr->{SESSION_ID};
  }

  if ( !defined( $attr->{ACCT_SESSION_ID} ) ){
    return $self;
  }

  my $internet_online = 'dv_calls';
  my $internet_main = 'dv_main';

  if($attr->{INTERNET}) {
    $internet_online = 'internet_online';
    $internet_main = 'internet_main';
  }

  my $WHERE = '';
  if(defined($attr->{GUEST})) {
    $WHERE = " AND guest = '$attr->{GUEST}' "
  }

  $self->query( "SELECT u.uid, calls.framed_ip_address,
      calls.user_name,
      calls.acct_input_octets AS input_octets,
      calls.acct_output_octets AS output_octets,
      acct_input_gigawords, 
      acct_output_gigawords,
      dv.tp_id,
      IF(u.company_id > 0, cb.id, b.id) AS bill_id,
      IF(c.name IS NULL, b.deposit, cb.deposit)+u.credit AS deposit,
      calls.started AS start,
      UNIX_TIMESTAMP()-UNIX_TIMESTAMP(calls.started) AS acct_session_time,
      calls.nas_id,
      calls.nas_port_id AS nas_port,
      calls.guest
    FROM $internet_online calls
      LEFT JOIN users u ON (u.uid=calls.uid)
      LEFT JOIN companies c ON (u.company_id=c.id)
      LEFT JOIN bills b ON (u.bill_id=b.id)
      LEFT JOIN bills cb ON (c.bill_id=cb.id)
      LEFT JOIN $internet_main dv ON (u.uid=dv.uid)
    WHERE acct_session_id= ? $WHERE;",
    undef, {
      INFO => 1,
      Bind => [ $attr->{ACCT_SESSION_ID} ]
    } );

  my $guest //= $self->{GUEST} || 0;

  if ( $self->{TOTAL} < 1 ){
    $self->query( "DELETE FROM `$internet_online` WHERE acct_session_id= ? AND guest = ?;", 'do',
      { Bind => [
          $attr->{ACCT_SESSION_ID},
          $guest
        ] } );
    return $self;
  }

  if( $self->{UID}) {
    if ( $self->{OUTPUT_OCTETS} && $self->{OUTPUT_OCTETS} > 4294967296 ){
      $self->{ACCT_OUTPUT_GIGAWORDS} = int( $self->{OUTPUT_OCTETS} / 4294967296 );
      $self->{OUTPUT_OCTETS} = $self->{OUTPUT_OCTETS} - ($self->{ACCT_OUTPUT_GIGAWORDS} * 4294967296);
    }
    elsif ( !$self->{OUTPUT_OCTETS} ){
      $self->{OUTPUT_OCTETS} = 0;
    }

    if ( $self->{INPUT_OCTETS} && $self->{INPUT_OCTETS} > 4294967296 ){
      $self->{ACCT_INPUT_GIGAWORDS} = int( $self->{INPUT_OCTETS} / 4294967296 );
      $self->{INPUT_OCTETS} = $self->{INPUT_OCTETS} - ($self->{ACCT_INPUT_GIGAWORDS} * 4294967296);
    }
    elsif ( !$self->{INPUT_OCTETS} ){
      $self->{INPUT_OCTETS} = 0;
    }

    my @insert_params = (
      $self->{UID},
      $self->{START},
      $self->{TP_ID} || 0,
      $self->{ACCT_SESSION_TIME},
      $self->{OUTPUT_OCTETS} || 0,
      $self->{INPUT_OCTETS} || 0,
      $self->{ACCT_OUTPUT_GIGAWORDS} || 0,
      $self->{ACCT_INPUT_GIGAWORDS} || 0,
        ($self->{SUM}) ? $self->{SUM} : 0,
      $self->{NAS_ID} || 0,
      $self->{NAS_PORT} || 0,
      $self->{FRAMED_IP_ADDRESS} || '0.0.0.0',
      $attr->{ACCT_SESSION_ID},
      $self->{BILL_ID} || 0,
        (defined($attr->{ACCT_TERMINATE_CAUSE})) ? $attr->{ACCT_TERMINATE_CAUSE} : 17,
      $attr->{CID} || $attr->{CALLING_STATION_ID} || '-'
    );

    if ($attr->{INTERNET}) {
      $self->query("INSERT INTO internet_log (uid, start, tp_id, duration,
    sent, recv, acct_output_gigawords, acct_input_gigawords,
    sum, nas_id, port_id,
    ip,
    acct_session_id,
    bill_id,
    terminate_cause,
    cid)
        VALUES (?, ?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
        'do',
        { Bind => \@insert_params }
      );
    }
    else {
      $self->query("INSERT INTO dv_log (uid, start, tp_id, duration,
    sent, recv, acct_output_gigawords, acct_input_gigawords, 
    sum, nas_id, port_id,
    ip, 
    acct_session_id, 
    bill_id,
    terminate_cause,
    CID) 
        VALUES (?, ?, ?, ?, ?, ?, 
        ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
        'do',
        { Bind => \@insert_params }
      );
    }
  }

  if ( !$self->{errno} ){
    $self->query( "DELETE FROM `$internet_online` WHERE acct_session_id= ? AND guest = ?;", 'do',
      { Bind => [
          $attr->{ACCT_SESSION_ID},
          $guest
       ] } );
  }

  return $self;
}

#**********************************************************
=head2 unknown_add($attr) - Add unknown ip address

=cut
#**********************************************************
sub unknown_add{
  my $self = shift;
  my ($attr) = @_;

  my @MULTI_QUERY = ();

  foreach my $line ( @{ $attr->{UNKNOWN_IPS} } ){
    my ($from, $to, $size) = split( /\//, $line, 3 );
    push @MULTI_QUERY, [ $from, $to, $size, $attr->{NAS_ID} || 0 ];
  }

  $self->query( "INSERT INTO ipn_unknow_ips (src_ip, dst_ip, size, nas_id, datetime)
        VALUES (?, ?, ?, ?, now());",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY } );

  return $self;
}

1
