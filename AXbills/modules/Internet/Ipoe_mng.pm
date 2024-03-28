=head1 NAME

  IPoE manage functions

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(mk_unique_value int2byte ip2int int2ip sec2time cmd);
use AXbills::Filters;
use Internet::Ipoe;
use Internet::Collector;
use Internet::Sessions;

our(
  $db,
  $admin,
  %conf,
  %LIST_PARAMS,
  $IPV4,
  %lang,
  $user,
  %FORM,
  $users,
  $pages_qs,
  $DATE,
  $index,
  $sid,
  %CHARTS,
);

our AXbills::HTML $html;

my $Internet       = Internet->new( $db, $admin, \%conf );
my $Internet_ipoe  = Internet::Ipoe->new( $db, $admin, \%conf );
my $Sessions       = Internet::Sessions->new($db, $admin, \%conf);
my $Tariffs        = Tariffs->new($db, \%conf, $admin);

my $Ipoe_collector = Internet::Collector->new( $db, $admin, \%conf );
my $Nas            = Nas->new( $db, \%conf, $admin );
my $Log            = Log->new($db, \%conf);

#**********************************************************
=head2 internet_ipoe_activate($attr) - Activate ipoe session

  Arguments:
   $attr
     IP
     UID
     ID    - Internet service ID
     ACTIVE- Active sassions

  Results:


=cut
#**********************************************************
sub internet_ipoe_activate{
  my ($attr) = @_;

  my $ip       = '0.0.0.0';
  my $IP_INPUT = '';

  $Internet->user_info( $LIST_PARAMS{UID}, $attr );
  my $static_ip= $Internet->{IP};

  if ( $Internet->{STATUS} && $Internet->{STATUS} > 0 && !$conf{INTERNET_IPOE_NEGATIVE}){
    my $service_status = sel_status({ HASH_RESULT => 1 });

    if ( $user->{UID} ){
      internet_user_info();
    }
    else{
      my ($status_text, undef)=split(/:/, $service_status->{$Internet->{STATUS}});
      $html->message( 'err', $lang{ERROR}, $status_text, { ID => 362 } );
    }

    if (!$FORM{activate}) {
      return 1;
    }
  }

  if ( !$user->{UID} && !$attr->{IP} ){
    $ENV{REMOTE_ADDR} = $static_ip if ($static_ip && $static_ip ne '0.0.0.0');
    $IP_INPUT = $html->form_input( 'REMOTE_ADDR', "$ENV{REMOTE_ADDR}", { OUTPUT2RETURN => 1 } );
    $ip = ($FORM{REMOTE_ADDR}) ? $FORM{REMOTE_ADDR} : $ENV{REMOTE_ADDR};
  }
  else{
    if ( !$conf{IPN_SKIP_IP_WARNING}
      && $static_ip
      && $static_ip ne '0.0.0.0'
      && ($static_ip ne $ENV{REMOTE_ADDR} && $user->{UID} && ! $attr->{ADMIN_ACTIVATE})){
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_UNALLOW_IP} '$ENV{REMOTE_ADDR}'\n $lang{STATIC} IP: $static_ip", { ID => 320 } );
      return 1;
    }
    $ip = $attr->{IP} || $ENV{REMOTE_ADDR};
  }

  $ip =~ s/\s+//g;
  my $nas_id = 0;
  if ( !$user->{UID} && $FORM{NAS_ID} ){
    $nas_id = int( $FORM{NAS_ID} );
  }
  else{
    my $poll_list = $Nas->nas_ip_pools_list({ SHOW_ALL_COLUMNS => 1, COLS_NAME => 1, PAGE_ROWS => 65000 });
    my $ip_num = unpack( "N", pack( "C4", split( /\./, $ip ) ) );

    # Get valid NAS
    foreach my $line ( @{$poll_list} ){
      if ( ($line->{ip} <= $ip_num) && ($ip_num <= $line->{last_ip_num}) ){
        if ( $line->{nas_id} ){
          $nas_id = $line->{nas_id};
          last;
        }
      }
    }
  }

  if ( $nas_id < 1 ){
    if ( !$FORM{LOGOUT} ){
      $html->message( 'err', $lang{ERROR}, "$lang{NOT_EXIST} IP '$ip' ", { ID => 361 } );
    }

    if ( !$user->{UID} ){
      my %NAS_PARAMS_LIST = ();
      if ( $admin->{DOMAIN_ID} ){
        $NAS_PARAMS_LIST{DOMAIN_ID} = $admin->{DOMAIN_ID};
      }

      $Internet->{NAS_SEL} = $html->form_select(
        'NAS_ID',
        {
          SELECTED  => $nas_id,
          SEL_LIST  => $Nas->list( { DISABLE => 0, COLS_NAME => 1, NAS_NAME => '_SHOW', %NAS_PARAMS_LIST, SHORT => 1 } ),
          SEL_KEY   => 'nas_id',
          SEL_VALUE => 'nas_name',
          MAIN_MENU => get_function_index( 'form_nas' )
        }
      );
    }
    else{
      return 1;
    }
  }

  if ( $FORM{CONNECT_INFO} && $FORM{CONNECT_INFO} =~ /Amon/ ){
    $FORM{CONNECT_INFO} = time();
    if ( $ENV{HTTP_USER_AGENT} =~ /^AMon \[(\S+)\]/ ){
      $FORM{CONNECT_INFO} .= ":" . $1;
    }
  }
  else{
    $FORM{CONNECT_INFO} = '';
  }

  if ( $FORM{ALIVE} ){
    if ( $FORM{REMOTE_ADDR} !~ /^$IPV4$/ ){
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}", { ID => 321 } );
      return 1;
    }

    $Internet_ipoe->online_alive( { %FORM, LOGIN => $LIST_PARAMS{LOGIN} } );
    if ( $Internet_ipoe->{TOTAL} < 1 ){
      $html->message( 'err', $lang{ERROR}, $lang{NOT_ACTIVE}, { ID => 322 } );
    }
    elsif ( $Internet_ipoe->{errno} ){
      _error_show( $Internet_ipoe );
    }
    else{
      $html->message( 'info', $lang{INFO}, "ALIVED" );
    }
    return 0;
  }
  elsif ( $attr->{ACTIVE} ){

    if ( int( $nas_id ) < 1 ){
      $html->message( 'err', $lang{ERROR}, $lang{ERR_UNKNOWN_IP}, { ID => 323 } );
    }
    else{
      my $user = $users->info( $LIST_PARAMS{UID} );
      $Internet_ipoe->online_alive(
        {
          LOGIN       => $user->{LOGIN} || $users->{LOGIN},
          REMOTE_ADDR => $ip,
        }
      );

      if ( $Internet_ipoe->{TOTAL} < 1 ){
        $Nas->info( { NAS_ID => $nas_id } );

        if ( $Internet->{SIMULTANEONSLY} && $Internet->{SIMULTANEONSLY} == 1 ){
          $Ipoe_collector->acct_stop(
            {
              USER_NAME            => $user->{LOGIN},
              NAS_ID               => $nas_id,
              STATUS               => 2,
              CALLING_STATION_ID   => $Internet->{CID} || $ip,
              ACCT_TERMINATE_CAUSE => $attr->{ACCT_TERMINATE_CAUSE} || 6
            }
          );
        }

       ($Nas->{NAS_MNG_IP}, undef, $Nas->{NAS_MNG_PORT})=split(/:/, $Nas->{NAS_MNG_IP_PORT} || q{});

        my %DATA = (
          ACCT_STATUS_TYPE   => 1,
          USER_NAME          => $user->{LOGIN},
          SESSION_START      => 0,
          ACCT_SESSION_ID    => mk_unique_value( 10 ),
          FRAMED_IP_ADDRESS  => $ip,
          NETMASK            => $Internet->{NETMASK},
          NAS_ID             => $nas_id,
          NAS_TYPE           => $Nas->{NAS_TYPE},
          NAS_IP_ADDRESS     => $Nas->{NAS_IP},
          NAS_MNG_USER       => $Nas->{NAS_MNG_USER},
          NAS_MNG_IP_PORT    => $Nas->{NAS_MNG_IP_PORT},
          NAS_MNG_IP         => $Nas->{NAS_MNG_IP},
          NAS_MNG_PORT       => $Nas->{NAS_MNG_PORT} || 22,
          NAS_MNG_PASSWORD   => $Nas->{NAS_MNG_PASSWORD} || q{},
          TP_ID              => $Internet->{TP_ID},
          CALLING_STATION_ID => $Internet->{CID} || $ip,
          NAS_PORT           => $Internet->{PORT},
          FILTER_ID          => $Internet->{FILTER_ID} || $Internet->{TP_FILTER_ID},
          CONNECT_INFO       => $FORM{CONNECT_INFO},
          UID                => $user->{UID},
          SERVICE_ID         => $attr->{ID} || 0
        );

        my %RAD_REQUEST = (
          'Acct-Status-Type'   => 1,
          'User-Name'          => $user->{LOGIN},
          'Acct-Session-Id'    => $DATA{ACCT_SESSION_ID},
          'Framed-IP-Address'  => $ip,
          'Calling-Station-Id' => $Internet->{CID} || $ip,
          'NAS-IP-Address'     => $Nas->{NAS_IP},
          'NAS-Port'           => $Internet->{PORT},
          'Filter-Id'          => $Internet->{FILTER_ID} || $Internet->{TP_FILTER_ID},
          'Connect-Info'       => $FORM{CONNECT_INFO},
        );

        require Auth2;
        Auth2->import();
        my $Auth = Auth2->new( $db, \%conf );
        $Auth->{SERVICE_ID}=$attr->{ID};
        my ($r, $RAD_PAIRS) = $Auth->auth( \%RAD_REQUEST, $Nas);
        delete ( $RAD_PAIRS->{'Session-Timeout'} );

        my $debug = $FORM{DEBUG} || 0;
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

        if ( $r == 1 ){
          $html->message( 'err', $lang{ERROR}, $RAD_PAIRS->{'Reply-Message'}, { ID => 324 } );
          $Log->log_add({
            LOG_TYPE  => $Log::log_levels{'LOG_WARNING'},
            ACTION    => 'AUTH',
            USER_NAME => $user->{LOGIN} || '-',
            MESSAGE   => $RAD_PAIRS->{'Reply-Message'},
            NAS_ID    => $nas_id
          });
        }
        else{
          $Internet_ipoe->user_status( { %DATA } );
          $DATA{NAS_PORT} = $Internet_ipoe->{PORT} || $DATA{NAS_PORT} || 0;

          internet_ipoe_change_status( { STATUS => 'ONLINE_ENABLE', %DATA } );

          if ( $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER} !~ /index.cgi/ && $html->{SID} ){
            print "Location: $ENV{HTTP_REFERER}" . "\n\n";
            exit;
          }
        }
      }
      else{
      #  $html->message( 'info', $lang{INFO}, "$lang{ACTIVATE}" );
      }
    }
  }

  return 1;
}


#**********************************************************
=head2 internet_ipoe_change_status($attr)

  Arguments:
    $attr
      FRAMED_IP_ADDRESS
      NETMASK
      STATUS
      USER_NAME
      ACCT_SESSION_ID
      FILTER_ID
      UID
      NAS_PORT
      DEBUG

  Returns:

=cut
#**********************************************************
sub internet_ipoe_change_status{
  my ($attr) = @_;

  if ( $attr->{FRAMED_IP_ADDRESS} !~ /^$IPV4$/ ){
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}", { ID => 330 } );
    return 0;
  }

  my $ip        = $attr->{FRAMED_IP_ADDRESS};
  my $netmask   = $attr->{NETMASK} || '32';
  my $STATUS    = $attr->{STATUS} || '';
  my $USER_NAME = $attr->{USER_NAME} || '';
  my $ACCT_SESSION_ID = $attr->{ACCT_SESSION_ID} || '';
  my $FILTER_ID = $attr->{FILTER_ID} || '';
  my $uid       = $attr->{UID} || 0;
  my $PORT      = $attr->{NAS_PORT} || 0;
  my $DEBUG     = $attr->{DEBUG} || 0;

  my $speed_in = 0;
  my $speed_out = 0;

  my $list = $Internet->get_speed({ UID => $uid, COLS_NAME => 1 });
  if ( $Internet->{TOTAL} > 0 ){
    if($list->[0]->{speed}) {
      $speed_in = $list->[0]->{speed} || 0;
      $speed_out = $list->[0]->{speed} || 0;
    }
    else {
      $speed_in = $list->[0]->{in_speed} || 0;
      $speed_out = $list->[0]->{out_speed} || 0;
    }
  }

  #netmask to bitmask
  if ( $netmask ne '32' ){
    my $ips = 4294967296 - ip2int( $netmask );
    $netmask = 32 - length( sprintf( "%b", $ips ) ) + 1;
  }

  my $num = 0;
  if ( $uid && $conf{IPN_FW_RULE_UID} ){
    $num = $uid;
  }
  else{
    my @ip_array = split( /\./, $ip, 4 );
    $num = $ip_array[3];
  }

  my $rule_num = $conf{IPN_FW_FIRST_RULE} || 20000;
  $rule_num = $rule_num + 10000 + $num;
  my $cmd;

  #Enable IPN Session
  if ( $STATUS eq 'ONLINE_ENABLE' ){
    $cmd = $conf{INTERNET_IPOE_START};
    $html->message( 'info', $lang{INFO}, "$lang{ENABLE} IP: $ip" ) if (!$attr->{QUICK});
    $Sessions->online_update({
      USER_NAME       => $USER_NAME,
      ACCT_SESSION_ID => $ACCT_SESSION_ID,
      STATUS          => 10
    });

    $Log->log_add({
      LOG_TYPE  => $Log::log_levels{'LOG_INFO'},
      ACTION    => 'AUTH',
      USER_NAME => $USER_NAME || '-',
      MESSAGE   => "IPN IP: $ip",
      NAS_ID    => $attr->{NAS_ID}
    });

  }
  elsif ( $STATUS eq 'ONLINE_DISABLE' ){
    $cmd = $conf{INTERNET_IPOE_STOP};

    $html->message( 'info', $lang{INFO}, "$lang{DISABLE} IP: $ip" );
    $Sessions->online_update({
      USER_NAME       => $USER_NAME,
      ACCT_SESSION_ID => $ACCT_SESSION_ID,
      STATUS          => 11
    });
  }
  elsif ( $STATUS eq 'HANGUP' ){
    $Ipoe_collector->acct_stop( { %{$attr}, %FORM, ACCT_TERMINATE_CAUSE => $attr->{ACCT_TERMINATE_CAUSE} || 6 } );

    $cmd = $conf{INTERNET_IPOE_STOP};

    if ( !$attr->{QUICK} ){
      my $message =
        "\n IP:  "
          . int2ip( $Ipoe_collector->{FRAMED_IP_ADDRESS} )
          . "\n$lang{RECV}:  "
          . int2byte( $Ipoe_collector->{INPUT_OCTETS} )
          . "\n$lang{SENT}:  "
          . int2byte( $Ipoe_collector->{OUTPUT_OCTETS} )
          . "\n$lang{TOTAL}:  "
          . int2byte( $Ipoe_collector->{INPUT_OCTETS} + $Ipoe_collector->{OUTPUT_OCTETS} )
          . "\n$lang{DURATION}:  "
          . sec2time( $Ipoe_collector->{ACCT_SESSION_TIME}, { str => 1 } )
          . "\n$lang{SUM}:  "
          . ($Ipoe_collector->{SUM} || 0);

      $html->message( 'info', $lang{INFO}, $message );
    }
  }

  if ( !$cmd ){
    print "Error: Not defined external command for status: $STATUS\n";
    return 0;
  }
  else{
    $cmd =~ s/\%IP/$ip/g;
    $cmd =~ s/\%MASK/$netmask/g;
    $cmd =~ s/\%NUM/$rule_num/g;
    $cmd =~ s/\%SPEED_IN/$speed_in/g if ($speed_in > 0);
    $cmd =~ s/\%SPEED_OUT/$speed_out/g if ($speed_out > 0);
    $cmd =~ s/\%LOGIN/$USER_NAME/g;
    $cmd =~ s/\%PORT/$PORT/g;
    $cmd =~ s/\%DEBUG//g;

    if ( $attr->{NAS_IP_ADDRESS} ){
      $ENV{NAS_IP_ADDRESS}  = $attr->{NAS_IP_ADDRESS};
      $ENV{NAS_MNG_USER}    = $attr->{NAS_MNG_USER};
      $ENV{NAS_MNG_IP_PORT} = $attr->{NAS_MNG_IP_PORT};
      $ENV{NAS_MNG_PASSWORD}= $attr->{NAS_MNG_PASSWORD};
      $ENV{NAS_ID}          = $attr->{NAS_ID};
      $ENV{NAS_TYPE}        = $attr->{NAS_TYPE} || '';
      ($ENV{NAS_MNG_IP}, undef, $ENV{NAS_MNG_PORT}) = split(/:/, $attr->{NAS_MNG_IP_PORT}, 4);
      $ENV{NAS_MNG_PORT} ||= 22;
    }

    print $html->pre("IPN $STATUS: $cmd") if ($DEBUG > 4);
    cmd( $cmd );
  }

  if ( $conf{INTERNET_IPOE_FILTER} && ($STATUS ne 'ONLINE_ENABLE' || ($STATUS eq 'ONLINE_ENABLE' && $FILTER_ID ne '')) ){
    $cmd = $conf{INTERNET_IPOE_FILTER};
    $cmd =~ s/\%STATUS/$STATUS/g;
    $cmd =~ s/\%IP/$ip/g;
    $cmd =~ s/\%ACTION/$STATUS/g;
    $cmd =~ s/\%MASK/$netmask/g;
    $cmd =~ s/\%LOGIN/$USER_NAME/g;
    $cmd =~ s/\%FILTER_ID/$FILTER_ID/g;
    $cmd =~ s/\%UID/$uid/g;
    $cmd =~ s/\%PORT/$PORT/g;
    cmd( $cmd );
    print $html->pre("IPN FILTER: $cmd") if ($DEBUG > 4);
  }

  return 1;
}

#**********************************************************
=head2 ipoe_sessions() - Users traffic statistic

=cut
#**********************************************************
sub ipoe_sessions {

  my @TT_COLORS = ('FFFFFF', '#80FF80', '#FFFF80', '#BFBFFF');

  if (!$user->{UID}) {
    $LIST_PARAMS{UID} = $FORM{UID};
    ipoe_recalculate();
  }
  else {
    $LIST_PARAMS{UID} = $user->{UID};
  }

  $LIST_PARAMS{HOURS} = 1 if $FORM{HOURS};

  $pages_qs .= "&UID=" . ($LIST_PARAMS{UID} ? $LIST_PARAMS{UID} : q{});

  require Control::Reports;
  reports({
    PERIOD_FORM => 1,
    DATE_RANGE  => 1,
    NO_GROUP    => 1,
    HIDDEN      => { UID => $LIST_PARAMS{UID} },
    EX_INPUTS   => [
      $html->element('label', "$lang{HOURS}: ", { for => 'HOURS', class => 'col-md-2 control-label', OUTPUT2RETURN => 1 }) .
        $html->form_input('HOURS', 1, {
          TYPE          => 'checkbox',
          STATE         => ($FORM{HOURS}) ? 'checked' : undef,
          OUTPUT2RETURN => 1
        })
    ]
  });

  my %totals = ();
  our %DATA_HASH;
  my %CHART = ();
  my %AVG = (
    MONEY    => 0,
    TRAFFIC  => 0,
    DURATION => 0
  );

  $CHART{SUFFIX} = 'b';

  my $graph_type = '';
  my $table_sessions;
  #Day report
  if ( defined( $FORM{DATE} ) ){
    $LIST_PARAMS{INTERVAL_TYPE} = 2;
    $graph_type = 'day_stats';
  }
  else{
    if ( $Sessions->prepaid_rest( { UID => $LIST_PARAMS{UID}, INFO_ONLY => 1 } ) ){
      my $list = $Internet_ipoe->prepaid_rest({
        UID  => $LIST_PARAMS{UID},
        INFO => $Sessions->{INFO_LIST}
      });

      my $table = $html->table({
        caption     => $lang{PREPAID},
        width       => '100%',
        title_plain => [ "$lang{TRAFFIC} $lang{TYPE}", $lang{BEGIN}, $lang{END}, $lang{START}, "$lang{TOTAL} (MB)", "$lang{REST} (MB)", "$lang{OVERQUOTA} (MB)" ],
        ID          => 'IPN_PREPAID',
      });

      foreach my $line ( @{$list} ){
        $table->addrow(
          $line->{traffic_class},
          $line->{interval_begin},
          $line->{interval_end},
          $line->{activate},
          $line->{prepaid},
            ($line->{prepaid} > 0 && $Internet_ipoe->{TRAFFIC}->{ $line->{traffic_class} } && $line->{prepaid} - $Internet_ipoe->{TRAFFIC}->{ $line->{traffic_class} } > 0) ? $line->{prepaid} - $Internet_ipoe->{TRAFFIC}->{ $line->{traffic_class} } : 0,
            ($line->{prepaid} > 0 && $Internet_ipoe->{TRAFFIC}->{ $line->{traffic_class} } && $line->{prepaid} - $Internet_ipoe->{TRAFFIC}->{ $line->{traffic_class} } < 0) ? abs( $line->{prepaid} - $Internet_ipoe->{TRAFFIC}->{ $line->{traffic_class} } ) : 0
        );
      }
      print $table->show();
    }

    $graph_type = 'month_stats';
  }

  $LIST_PARAMS{CUR_DATE} = $DATE;
  if ($html->{FROM_DATE}) {
    $LIST_PARAMS{INTERVAL} = "$html->{FROM_DATE}/$html->{TO_DATE}";
  }

  my $list = $Internet_ipoe->reports_users( {
    TRAFFIC_IN  => '_SHOW',
    TRAFFIC_OUT => '_SHOW',
    SUM         => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME   => 1
  });

  #Used Traffic
  $table_sessions = $html->table({
    width   => '100%',
    caption => $lang{SESSIONS},
    title   => [ $lang{DATE}, $lang{TRAFFIC_CLASS}, $lang{NAME}, $lang{RECV}, $lang{SENT}, $lang{TOTAL}, $lang{SUM} ],
    qs      => $pages_qs,
    ID      => 'IPN_SESSIONS'
  });

  my %report = ();
  foreach my $line ( @{$list} ){
    push @{ $report{ $line->{start} || $line->{hours} || '' } }, $line;
  }

  my $num = 0;
  foreach my $k ( sort %report ){
    my $stats_array = $report{$k};
    next if (ref( $k ) eq 'ARRAY');
    $table_sessions->{rowcolor} = 'bg-info';
    my $user_total_in = 0;
    my $user_total_out = 0;
    my $user_sum = 0;

    my $period = $stats_array->[0]->{start} || $stats_array->[0]->{hours} || '-';

    if (!$FORM{DATE}) {
      my ($date) = split(/ /, $period);
      $period = $html->button($period, "index=$index&HOURS=1&DATE=$date$pages_qs");
    }

    my $traffic_class =   $stats_array->[0]->{traffic_class} || 0;
    $table_sessions->addtd(
      $table_sessions->td($period, { rowspan => ($#{$stats_array} > 0) ? $#{$stats_array} + 2 : 2 }),
      $table_sessions->td($traffic_class, { bgcolor => $TT_COLORS[ $traffic_class ] }),
      $table_sessions->td($stats_array->[0]->{descr}, { bgcolor => $TT_COLORS[ $traffic_class ] }),
      $table_sessions->td(int2byte($stats_array->[0]->{traffic_in}), { bgcolor => $TT_COLORS[ $traffic_class ] }),
      $table_sessions->td(int2byte($stats_array->[0]->{traffic_out}), { bgcolor => $TT_COLORS[ $traffic_class ] }),
      $table_sessions->td(int2byte($stats_array->[0]->{traffic_in} + $stats_array->[0]->{traffic_out}),
        { bgcolor => $TT_COLORS[ $traffic_class ] }),
      $table_sessions->td($stats_array->[0]->{sum}, { bgcolor => $TT_COLORS[ $traffic_class ] })
    );

    $user_total_in += $stats_array->[0]->{traffic_in};
    $user_total_out += $stats_array->[0]->{traffic_out};
    $user_sum += $stats_array->[0]->{sum};
    $totals{IN}{ $traffic_class } += $stats_array->[0]->{traffic_in};
    $totals{OUT}{ $traffic_class } += $stats_array->[0]->{traffic_out};
    $totals{SUM}{ $traffic_class } += $stats_array->[0]->{sum};


    for ( my $i = 1; $i < $#{ $stats_array } + 1; $i++ ){
      my $_traffic_class = $stats_array->[$i]->{traffic_class} || 0;
      if ($TT_COLORS[ $i ]) {
        if ($_traffic_class) {
          $table_sessions->{rowcolor} = $TT_COLORS[ $_traffic_class ];
        }
      }
      else {
        $table_sessions->{rowcolor} = undef;
      }

      $table_sessions->addrow(
        $_traffic_class,
        $stats_array->[$i]->{descr},
        int2byte( $stats_array->[$i]->{traffic_in} ),
        int2byte( $stats_array->[$i]->{traffic_out} ),
        int2byte( $stats_array->[$i]->{traffic_in} + $stats_array->[$i]->{traffic_out} ),
        $stats_array->[$i]->{sum}
      );

      $totals{IN}{ $_traffic_class } += $stats_array->[$i]->{traffic_in} || 0;
      $totals{OUT}{ $_traffic_class } += $stats_array->[$i]->{traffic_out} || 0;
      $totals{SUM}{ $_traffic_class } = $totals{SUM}{ $_traffic_class } + $stats_array->[$i]->{sum} if ($stats_array->[$i]->{sum} > 0);

      $user_total_in += $stats_array->[$i]->{traffic_in};
      $user_total_out += $stats_array->[$i]->{traffic_out};
      $user_sum += $stats_array->[$i]->{sum};
    }

    #Sub totals
    $table_sessions->{rowcolor} = 'bg-success';

    $table_sessions->addtd( $table_sessions->th( $lang{TOTAL}, { colspan => 2 } ),
      $table_sessions->th( int2byte( $user_total_in ) ),
      $table_sessions->th( int2byte( $user_total_out ) ),
      $table_sessions->th( int2byte( $user_total_in + $user_total_out ) ),
      $table_sessions->th( $user_sum ) );

    if ( $FORM{DATE} ){
      my (undef, $h) = split( / /, $stats_array->[0]->{start} || $stats_array->[0]->{hours}, 2 );
      $h++;
      $DATA_HASH{TRAFFIC_IN}[$h] = int( $user_total_in / 3600 );
      $DATA_HASH{TRAFFIC_OUT}[$h] = int( $user_total_out / 3600 );
      $DATA_HASH{MONEY}[$h] = 0;                             # $user_sum;
    }
    else{
      $AVG{TRAFFIC_IN} = $user_total_in if ($AVG{TRAFFIC_IN} && $AVG{TRAFFIC_IN} < $user_total_in);
      $AVG{TRAFFIC_OUT} = $user_total_out if ($AVG{TRAFFIC_IN} && $AVG{TRAFFIC_OUT} < $user_total_out);

      if ( $stats_array->[0]->{start} && $stats_array->[0]->{start} =~ /(\d+)-(\d+)-(\d+)/ ){
        $num = $3;
      }
      elsif ( $stats_array->[0]->{start} && $stats_array->[0]->{start} =~ /(\d+)-(\d+)/ ){
        $CHART{X_LINE}[$num] = $stats_array->[0][0];
        $num++;
      }

      $DATA_HASH{TRAFFIC_IN}[$num] = int( $user_total_in / (3600 * 24) );
      $DATA_HASH{TRAFFIC_OUT}[$num] = int( $user_total_out / (3600 * 24) );
      $DATA_HASH{MONEY}[$num] = $user_sum;
    }

    $AVG{MONEY} = $user_sum if ($AVG{MONEY} < $user_sum);
  }

  my $table = $html->table({
    width   => '100%',
    caption => $lang{TOTAL},
    title   => [ $lang{TRAFFIC_CLASS}, $lang{RECV}, $lang{SENT}, $lang{TOTAL}, $lang{SUM} ],
  });

  foreach my $tt (sort keys %{$totals{IN}}) {
    $table->addrow($tt,
      int2byte($totals{IN}{$tt}),
      int2byte($totals{OUT}{$tt}),
      int2byte($totals{OUT}{$tt} + $totals{IN}{$tt}),
      sprintf("%.6f", $totals{SUM}{$tt} || 0));
  }

  print $table_sessions->show() . $table->show();

  #$html->make_charts({
  #   PERIOD     => $graph_type,
  #   DATA       => \%DATA_HASH,
  #   AVG        => \%AVG,
  #   TYPE       => \@type,
  #   TRANSITION => 1,
  #   %CHART
  #  });

  return 1;
}


#**********************************************************
=head2 ipoe_recalculate()

=cut
#**********************************************************
sub ipoe_recalculate{

  my $recalculate_total_sum = 0;
  if ( $FORM{RECALCULATE} ){
    $LIST_PARAMS{INTERVAL} = "$FORM{FROM_DATE}/$FORM{TO_DATE}";
    $Internet_ipoe->recalculate( { %LIST_PARAMS } );

    if ( $Internet_ipoe->{TOTAL} > 0 ){
      my $TP_ID = 0;
      my $user = $users->info( $LIST_PARAMS{UID} );

      if ( !$FORM{TP_ID} ){
        print "NOT_FOUND_TP_ID";
        return 0;
      }
      else{
        $TP_ID = $FORM{TP_ID};
      }

      $Tariffs->info( $TP_ID );
      my $OCTETS_DIRECTION = $Tariffs->{OCTETS_DIRECTION};
      my @CAPTION = ($lang{START}, "$lang{TRAFFIC}  ID", $lang{RECV}, $lang{SEND}, 'NAS', 'IP',
        $lang{INTERVALS}, $lang{SUM}, 'SID', $lang{RECALCULATE});

      my $table = $html->table(
        {
          caption    => $lang{RECALCULATE},
          width      => '100%',
          title      => \@CAPTION,
          ID         => 'IPN_RECALCULATE'
        }
      );

      my $total_sum = 0;
      my %TIME_INTERVALS = ();

      foreach my $line ( @{ $Internet_ipoe->{list} } ){
        my $time_interval = $line->[6];
        my $traffic_class = $line->[1];
        if ( !defined( $TIME_INTERVALS{ $line->[6] } ) ){
          my $ti_interval = $TIME_INTERVALS{ $line->[6] };
          #if log don't have time_interval mark
          if ( !$ti_interval ){
            my $ti_list = $Tariffs->ti_list( { TP_ID => $TP_ID } );
            foreach my $line2 ( @{$ti_list} ){
              $time_interval = $line2->[0];
            }
          }

          my $tt_list = $Tariffs->tt_list( { TI_ID => $time_interval } );

          foreach my $tt_line ( @{$tt_list} ){
            $TIME_INTERVALS{$time_interval}{ $tt_line->[0] }{PRICE_IN} = $tt_line->[1];
            $TIME_INTERVALS{$time_interval}{ $tt_line->[0] }{PRICE_OUT} = $tt_line->[2];
            $TIME_INTERVALS{$time_interval}{ $tt_line->[0] }{PREPAID} = $tt_line->[3];
          }
        }

        my $recalculate_sum = 0;
        my $price_in = $TIME_INTERVALS{$time_interval}{$traffic_class}{PRICE_IN};
        my $price_out = $TIME_INTERVALS{$time_interval}{$traffic_class}{PRICE_OUT};
        my $prepaid = $TIME_INTERVALS{$time_interval}{$traffic_class}{PREPAID} || 0;
        my $in = $line->[2];
        my $out = $line->[3];
        my $sum_in = 0;
        my $sum_out = 0;

        # Work with prepaid traffic
        if ( $prepaid > 0 ){
          my ($used_traffic) = $Ipoe_collector->traffic_user_get(
            {
              UID      => $LIST_PARAMS{UID},
              ACTIVATE => $users->{ACTIVATE},
              INTERVAL => "0000-00-00/$line->[0]"
            }
          );
          my $online = 0;

          if ( $OCTETS_DIRECTION == 1 ){
            $used_traffic->{$traffic_class}{TRAFFIC_SUM} = ($used_traffic->{$traffic_class}{TRAFFIC_IN}) ? $used_traffic->{$traffic_class}{TRAFFIC_IN} : 0;
            $online = $in;
          }

          #Sent / Out
          elsif ( $OCTETS_DIRECTION == 2 ){
            $used_traffic->{$traffic_class}{TRAFFIC_SUM} = ($used_traffic->{$traffic_class}{TRAFFIC_OUT}) ? $used_traffic->{$traffic_class}{TRAFFIC_OUT} : 0;
            $online = $out;
          }
          else{
            $used_traffic->{$traffic_class}{TRAFFIC_SUM} = ($used_traffic->{$traffic_class}{TRAFFIC_IN}) ? $used_traffic->{$traffic_class}{TRAFFIC_OUT} + $used_traffic->{$traffic_class}{TRAFFIC_IN} : 0;
            $online = ($in + $out);
          }

          #          if ( $debug > 1 ){
          #            print "Prepaid traffic: $prepaid CLASS: $traffic_class USED: $used_traffic->{$traffic_class}{TRAFFIC_SUM}\n";
          #          }

          if ( $used_traffic->{$traffic_class}{TRAFFIC_SUM} < $prepaid ){
            $price_in = 0;
            $price_out = 0;
          }
          elsif ( $used_traffic->{$traffic_class}{TRAFFIC_SUM} + $online / $conf{MB_SIZE} > $prepaid
            && $used_traffic->{$traffic_class}{TRAFFIC_SUM} < $prepaid )
          {
            my $not_prepaid = ($used_traffic->{$traffic_class}{TRAFFIC_SUM} * $conf{MB_SIZE} + $online) - $prepaid * $conf{MB_SIZE};

            my $sent = ($OCTETS_DIRECTION == 2) ? $not_prepaid : $not_prepaid / 2;
            my $recv = ($OCTETS_DIRECTION == 1) ? $not_prepaid : $not_prepaid / 2;

            $sum_in = $recv / $conf{MB_SIZE} * $price_in if ($price_in > 0);
            $sum_out = $sent / $conf{MB_SIZE} * $price_out if ($price_out > 0);
            $price_in = 0;
            $price_out = 0;
          }
        }
        $sum_in = $in / $conf{MB_SIZE} * $price_in if ($price_in && $price_in > 0);
        $sum_out = $out / $conf{MB_SIZE} * $price_out if ($price_out && $price_out > 0);

        $recalculate_sum = $sum_in + $sum_out;

        $table->addrow(
          $line->[0],
          $line->[1],

          $line->[2],
          $line->[3],

          $line->[4],
          $line->[5],
          $line->[6],
          $line->[7],
          $line->[8],

          $recalculate_sum
        );

        if ( $FORM{ACTION} ){
          $Internet_ipoe->traffic_recalc(
            {
              UID           => $LIST_PARAMS{UID},
              START         => "$line->[0]",
              TRAFFIC_CLASS => "$traffic_class",
              IN            => "$line->[2]",
              OUT           => "$line->[3]",
              SESSION_ID    => "$line->[8]",
              SUM           => "$recalculate_sum"
            }
          );
        }
        $total_sum += $line->[7];
        $recalculate_total_sum += $recalculate_sum;
      }

      if ( $FORM{ACTION} ){
        my $recalculate = sprintf( "%.5f", $total_sum - $recalculate_total_sum );
        if ( $recalculate != 0 ){
          $Internet_ipoe->traffic_recalc_bill(
            {
              SUM     => $recalculate,
              BILL_ID => $user->{BILL_ID}
            }
          );

          print $html->message( 'info', $lang{RECALCULATE}, "$lang{SUM}: $recalculate, $lang{TARIF_PLAN}: $TP_ID" );
        }
      }

      $table->{rowcolor} = 'bg-success';
      $table->addtd( $table->td( $lang{TOTAL}, { colspan => 3 } ), $table->td( $total_sum, { colspan => 2 } ),
        $table->td( $lang{RECALCULATE}, { colspan => 3 } ), $table->td( $recalculate_total_sum, { colspan => 2 } ) );

      print $table->show();
    }
  }

  my $table = $html->table(
    {
      width    => '100%',
      rows     => [
        [
          $html->element( 'label', "$lang{DATE}: ")
          ,
          $html->form_daterangepicker({
            NAME      => 'FROM_DATE/TO_DATE',
            FORM_NAME => 'report_panel',
            VALUE     => $FORM{'FROM_DATE_TO_DATE'},
          }),
          $html->element('label', "$lang{TARIF_PLAN}:"),
          $html->form_select(
            'TP_ID',
            {
              SELECTED  => $FORM{TP_ID},
              SEL_LIST  => $Tariffs->list( { COLS_NAME => 1 } ),
              SEL_KEY   => 'id',
              SEL_VALUE => 'id,name',
            }
          ),

          $html->form_select(
            'ACTION',
            {
              SELECTED     => $FORM{ACTION} || 0,
              SEL_ARRAY    => [ $lang{SHOW}, $lang{RECALCULATE} ],
              ARRAY_NUM_ID => 1
            }
          ),

          $html->form_input( 'RECALCULATE', "$lang{RECALCULATE}", { TYPE => 'SUBMIT', class=> 'btn btn-danger', OUTPUT2RETURN => 1 } )
        ]
      ],
    }
  );

  print $html->form_main(
    {
      CONTENT => $table->show(),
      HIDDEN  => {
        index => "$index",
        UID   => $LIST_PARAMS{UID},
      },
      NAME    => 'recalculate'
    }
  );

  return 1;
}

#**********************************************************
=head2 ipoe_use() IPN traffic use

=cut
#**********************************************************
sub ipoe_use{

  my %HIDDEN = ();
  my @TT_COLORS = ('FFFFFF', "#80FF80", "#FFFF80", "#BFBFFF");
  $HIDDEN{COMPANY_ID} = $FORM{COMPANY_ID} if ($FORM{COMPANY_ID});
  $HIDDEN{sid} = $sid if ($FORM{sid});

  require Control::Reports;
  reports({
      DATE        => $FORM{DATE},
      REPORT      => '',
      HIDDEN      => \%HIDDEN,
      EX_PARAMS   => {
        HOURS => $lang{HOURS},
        USERS => $lang{USERS}
      },
      EXT_TYPE    => {
        DAYS_TCLASS => "$lang{DAYS} $lang{TRAFFIC_CLASS}",
        GID         => $lang{GROUPS},
        PER_MONTH   => $lang{PER_MONTH},
        DISTRICT    => $lang{DISTRICT},
        STREET      => $lang{STREET},
        BUILD       => $lang{BUILD},
      },
      PERIOD_FORM => 1,
      TIME_FORM   => 1,
      DATE_RANGE  => 1,
      EX_INPUTS   => [
        $html->element('label', " $lang{DIMENSION}: ", {class => 'col-md-2 control-label'})
          . $html->element('div', $html->form_select(
          'DIMENSION',
          {
            SELECTED => $FORM{DIMENSION},
            SEL_HASH => {
              ''   => 'Auto',
              'Bt' => 'Bt',
              'Kb' => 'Kb',
              'Mb' => 'Mb',
              'Gb' => 'Gb'
            },
            NO_ID    => 1
          }
        ), { class => 'col-md-8' })
      ]
  });

  my %totals = ();
  our %DATA_HASH;
  %CHARTS = (
    TYPES  => {
      date        => 'column',
      users_count => 'column',
      sum         => 'line',
      traffic_in  => 'column',
      traffic_out => 'column',
    },
    SUFFIC => '%'
  );

  my %AVG = (
    MONEY    => 0,
    TRAFFIC  => 0,
    DURATION => 0
  );

  my $graph_type = '';
  my $out        = '';
  my %TRAFFIC_CLASS = ();
  my $table_sessions;
  my AXbills::HTML $table;
  my $list;

  if($FORM{HOUR}) {
    $LIST_PARAMS{HOUR}=$FORM{HOUR};
  }

  #Day reports
  if ( (! $FORM{EX_PARAMS} || $FORM{EX_PARAMS} ne 'USERS')
    && ($FORM{DATE} || ($FORM{TYPE} && $FORM{TYPE} eq 'DAYS_TCLASS')) ){
    $LIST_PARAMS{INTERVAL_TYPE} = 2;
    $LIST_PARAMS{CUR_DATE} = $DATE;

    if ( $FORM{DATE} && !$FORM{TYPE} ){
      $LIST_PARAMS{HOURS} = 1;
    }

    $list = $Internet_ipoe->reports_users({
      TRAFFIC_IN  => '_SHOW',
      TRAFFIC_OUT => '_SHOW',
      TRAFFIC_SUM => '_SHOW',
      SUM         => '_SHOW',
      %LIST_PARAMS,
      COLS_NAME   => 1
    });

    if ( _error_show( $Internet_ipoe ) ){
      #return 0;
    }

    #Used Traffic
    $table_sessions = $html->table({
      width   => '100%',
      caption => $lang{SESSIONS},
      title   => [ $lang{DATE}, $lang{USERS}, $lang{TRAFFIC_CLASS}, $lang{NAME}, $lang{RECV}, $lang{SENT}, $lang{TOTAL}, $lang{SUM} ],
      qs      => $pages_qs,
      ID      => 'IPN_USERS_STATS',
      EXPORT  => 1,
    });

    my %report = ();

    if ( $FORM{EX_PARAMS} && $FORM{EX_PARAMS} eq 'HOURS' ){
      $graph_type = 'day_stats';

      foreach my $line ( @{$list} ){
        push @{ $report{"$line->{hours}"} }, $line;
      }

      foreach my $k ( sort %report ){
        my $stats_array = $report{$k};
        next if (ref( $k ) eq 'ARRAY');
        my $user_total_in = 0;
        my $user_total_out = 0;
        my $user_traffic_sum = 0;
        my $user_sum = 0;
        my $user_count = $stats_array->[0]->{users_count};

        $table_sessions->{rowcolor} = 'bg-info';
        my $traffic_class = $stats_array->[0]->{traffic_class} || 0;


        $table_sessions->addtd(
          $table_sessions->td( $stats_array->[0]->{hours}, { rowspan => ($#{ $stats_array } > 0) ? $#{ $stats_array } + 2 : 2 } )
          ,
          $table_sessions->td( $stats_array->[0]->{users_count},
            { rowspan => ($#{ $stats_array } > 0) ? $#{ $stats_array } + 2 : 2 } ),
          $table_sessions->td( $traffic_class,
            { bgcolor => $TT_COLORS[ $traffic_class ] } ),
          $table_sessions->td( $stats_array->[0]->{descr}, { bgcolor => $TT_COLORS[ $traffic_class ] } ),
          $table_sessions->td( int2byte( $stats_array->[0]->{traffic_in}, { DIMENSION => $FORM{DIMENSION} } ),
            { bgcolor => $TT_COLORS[ $traffic_class ] } ),
          $table_sessions->td( int2byte( $stats_array->[0]->{traffic_out}, { DIMENSION => $FORM{DIMENSION} } ),
            { bgcolor => $TT_COLORS[ $traffic_class ] } ),
          $table_sessions->td( int2byte( $stats_array->[0]->{traffic_in} + $stats_array->[0]->{traffic_out},
              { DIMENSION => $FORM{DIMENSION} } ), { bgcolor => $TT_COLORS[ $traffic_class ] } ),
          $table_sessions->td( $stats_array->[0]->{sum}, { bgcolor => $TT_COLORS[ $traffic_class ] } )
        );

        $user_total_in += $stats_array->[0]->{traffic_in};
        $user_total_out += $stats_array->[0]->{traffic_out};
        $user_traffic_sum += $stats_array->[0]->{traffic_in} + $stats_array->[0]->{traffic_out};
        $user_sum += $stats_array->[0]->{sum};

        for ( my $i = 1; $i < $#{ $stats_array } + 1; $i++ ){

          if ( $TT_COLORS[ $stats_array->[$i]->{traffic_class} ] ne '' ){
            $table_sessions->{rowcolor} = $TT_COLORS[ $stats_array->[$i]->{traffic_class} ];
          }
          else{
            $table_sessions->{rowcolor} = undef;
          }

          $table_sessions->addrow(
            $stats_array->[$i]->{traffic_class},
            $stats_array->[$i]->{descr},
            int2byte( $stats_array->[$i]->{traffic_in}, { DIMENSION => $FORM{DIMENSION} } ),
            int2byte( $stats_array->[$i]->{traffic_out}, { DIMENSION => $FORM{DIMENSION} } ),
            int2byte( $stats_array->[$i]->{traffic_in} + $stats_array->[$i]->{traffic_out},
              { DIMENSION => $FORM{DIMENSION} } ),
            $stats_array->[$i]->{sum}
          );

          $user_total_in += $stats_array->[$i]->{traffic_in};
          $user_total_out += $stats_array->[$i]->{traffic_out};
          $user_traffic_sum += $stats_array->[$i]->{traffic_in} + $stats_array->[$i]->{traffic_in};
          $user_sum += $stats_array->[$i]->{sum} || 0;
        }

        $table_sessions->{rowcolor} = 'bg-success';
        $table_sessions->addtd(
          $table_sessions->th( "$lang{TOTAL}:", { colspan => 2 } ),
          $table_sessions->td( int2byte( $user_total_in, { DIMENSION => $FORM{DIMENSION} } ) ),
          $table_sessions->td( int2byte( $user_total_out, { DIMENSION => $FORM{DIMENSION} } ) ),
          $table_sessions->td( int2byte( $user_traffic_sum, { DIMENSION => $FORM{DIMENSION} } ) ),
          $table_sessions->td( $user_sum )
        );

        $totals{SUM} += $user_sum;
        $totals{TRAFFIC_IN} += $user_total_in;
        $totals{TRAFFIC_OUT} += $user_total_out;

        #Chart
        my (undef, $h) = split( / /, $stats_array->[0]->{hours}, 2 );
        $h++;
        $AVG{MONEY} = $user_sum if ($AVG{TRAFFIC_IN} && $AVG{TRAFFIC_IN} < $user_sum);
        $DATA_HASH{traffic_in}[$h] = int( $user_total_in / 3600 );
        $DATA_HASH{traffic_out}[$h] = int( $user_total_out / 3600 );
        $DATA_HASH{USERS}[$h] = $user_count;
        $DATA_HASH{MONEY}[$h] = int( $user_sum );
      }

      $out = $html->make_charts({
        DEBUG         => 1,
        PERIOD        => $graph_type,
        DATA          => \%DATA_HASH,
        #AVG           => \%AVG,
        TRANSITION    => 1,
        %CHARTS,
        OUTPUT2RETURN => 1
      });
    }
    #Report by users
    else{
      foreach my $line ( @{$list} ){
        push @{ $report{"$line->{hours}$line->{users_count}"} }, $line;
      }

      foreach my $k ( sort keys %report ){
        my $stats_array = $report{$k};
        $table_sessions->{rowcolor} = 'bg-info';

        my $user_total_in = 0;
        my $user_total_out = 0;
        my $user_traffic_sum = 0;
        my $user_sum = 0;

        my $field2 = ($FORM{TYPE}) ? '' : ($LIST_PARAMS{HOURS}) ? $stats_array->[0]->{users_count} : $html->button(
              $stats_array->[0]->{login}, "index=11&UID=$stats_array->[0]->{uid}" );

        my $traffic_class = $stats_array->[0]->{traffic_class};
        #my ($date, undef)=split(/ /, $stats_array->[0]->{hours});

        $table_sessions->addtd(
          $table_sessions->td(
          $html->button( $stats_array->[0]->{hours}, "index=$index&HOUR=$stats_array->[0]->{hours}&EX_PARAMS=USERS" ),
            { rowspan => ($#{ $stats_array } > 0) ? $#{ $stats_array } + 2 : 2 } ),
          $table_sessions->td( $field2, { rowspan => ($#{ $stats_array } > 0) ? $#{ $stats_array } + 2 : 2 } ),
          $table_sessions->td( $traffic_class,
            { bgcolor => $TT_COLORS[ $traffic_class ] } ),
          $table_sessions->td( $stats_array->[0]->{descr},
            { bgcolor => $TT_COLORS[ $traffic_class ] } ),
          $table_sessions->td( int2byte( $stats_array->[0]->{traffic_in}, { DIMENSION => $FORM{DIMENSION} } ),
            { bgcolor => $TT_COLORS[ $traffic_class ] } ),
          $table_sessions->td( int2byte( $stats_array->[0]->{traffic_out}, { DIMENSION => $FORM{DIMENSION} } ),
            { bgcolor => $TT_COLORS[ $traffic_class ] } ),
          $table_sessions->td( int2byte( $stats_array->[0]->{traffic_in} + $stats_array->[0]->{traffic_out},
              { DIMENSION => $FORM{DIMENSION} } ), { bgcolor => $TT_COLORS[ $traffic_class ] } ),
          $table_sessions->td( $stats_array->[0]->{sum},
            { bgcolor => $TT_COLORS[ $traffic_class ] } )
        );

        $user_total_in += $stats_array->[0]->{traffic_in};
        $user_total_out += $stats_array->[0]->{traffic_out};
        $user_traffic_sum += $stats_array->[0]->{traffic_in} + $stats_array->[0]->{traffic_in};

        $TRAFFIC_CLASS{ $traffic_class }{IN} += $stats_array->[0]->{traffic_in};
        $TRAFFIC_CLASS{ $traffic_class }{OUT} += $stats_array->[0]->{traffic_out};
        $TRAFFIC_CLASS{ $traffic_class }{SUM} += ($stats_array->[0]->{traffic_in} + $stats_array->[0]->{traffic_out});

        for ( my $i = 1; $i < $#{ $stats_array } + 1; $i++ ){
          if ( $TT_COLORS[ $stats_array->[$i]->{traffic_class} ] ne '' ){
            $table_sessions->{rowcolor} = $TT_COLORS[ $stats_array->[$i]->{traffic_class} ];
          }
          else{
            $table_sessions->{rowcolor} = undef;
          }

          $table_sessions->addrow(
            $stats_array->[$i]->{traffic_class},
            $stats_array->[$i]->{descr},
            int2byte( $stats_array->[$i]->{traffic_in}, { DIMENSION => $FORM{DIMENSION} } ),
            int2byte( $stats_array->[$i]->{traffic_out}, { DIMENSION => $FORM{DIMENSION} } ),
            int2byte( $stats_array->[$i]->{traffic_in} + $stats_array->[$i]->{traffic_out},
              { DIMENSION => $FORM{DIMENSION} } ),
            $stats_array->[$i]->{sum}
          );

          $user_total_in += $stats_array->[$i]->{traffic_in};
          $user_total_out += $stats_array->[$i]->{traffic_out};
          $user_traffic_sum += $stats_array->[$i]->{traffic_in} + $stats_array->[$i]->{traffic_out};
          $user_sum += $stats_array->[$i]->{sum};

          $TRAFFIC_CLASS{ $stats_array->[$i]->{traffic_class} }{IN} += $stats_array->[$i]->{traffic_in};
          $TRAFFIC_CLASS{ $stats_array->[$i]->{traffic_class} }{OUT} += $stats_array->[$i]->{traffic_out};
          $TRAFFIC_CLASS{ $stats_array->[$i]->{traffic_class} }{SUM} += ($stats_array->[$i]->{traffic_in} + $stats_array->[$i]->{traffic_out});
        }

        $table_sessions->{rowcolor} = 'bg-success';
        my $speed = int2byte( $user_traffic_sum / 86400 );
        $table_sessions->addtd(
          "<th align=left>$lang{AVG} $lang{SPEED}: $speed/sec. </th><th> $lang{TOTAL}:</th>",
          "<th>" . int2byte( $user_total_in, { DIMENSION => $FORM{DIMENSION} } ) . "</th>",
          "<th>" . int2byte( $user_total_out, { DIMENSION => $FORM{DIMENSION} } ) . "</th>",
          "<th>" . int2byte( $user_traffic_sum, { DIMENSION => $FORM{DIMENSION} } ) . "</th>",
          "<th>" . $user_sum . "</th>"
        );

        $totals{SUM} += $user_sum;
        $totals{TRAFFIC_IN} += $user_total_in;
        $totals{TRAFFIC_OUT} += $user_total_out;
      }

      #Traffic Class summary
      my $table_classes_sum = $html->table(
        {
          width   => '100%',
          caption => $lang{TRAFFIC_CLASS},
          title   => [ $lang{TRAFFIC_CLASS}, $lang{RECV}, $lang{SENT}, $lang{SUM} ],
          qs      => $pages_qs,
          ID      => 'IPN_TRAFFIC_CLASS_SUM',
          EXPORT  => 1,
        }
      );

      foreach my $class ( sort keys %TRAFFIC_CLASS ){
        $table_classes_sum->addrow( $class, int2byte( $TRAFFIC_CLASS{$class}{IN} ),
          int2byte( $TRAFFIC_CLASS{$class}{OUT} ), int2byte( $TRAFFIC_CLASS{$class}{SUM} ) );
      }

      print $table_classes_sum->show();
    }
  }
  else{
    my $type = '';
    if ( $FORM{TYPE} ){
      $type = $FORM{TYPE};
      $pages_qs .= "&TYPE=$type";
    }

    my $x_text = 'date';

    if ( $type eq 'BUILD' ){
      $x_text = 'build';
    }
    elsif ( $type eq 'PER_MONTH' ){
      $x_text = 'month';
    }
    elsif ( $type eq 'DISTRICT' ){
      $x_text = 'district_name';
    }
    elsif ( $type eq 'STREET' ){
      $x_text = 'street_name';
    }
    elsif ( $type eq 'HOURS' ){
      $graph_type = 'hour_stats';
    }
    elsif ( $type eq 'DAYS_TCLASS' ){
      $x_text = "traffic_class";
    }
    elsif ( $type eq 'HOURS' ){
      $x_text = 'hours';
    }
    elsif ( $type eq 'GID' ){
      $x_text = "gid";
    }
    elsif ( $type eq 'USER' ){
      $x_text = "login";
    }
    elsif ( $type eq 'HOURS' ){
      $graph_type = 'hour_stats';
    }
    elsif ( !$type ){
      $graph_type = 'month_stats';
      $x_text = "date";
    }

    if ( $FORM{EX_PARAMS} && $FORM{EX_PARAMS} eq 'USERS' ){
      $x_text = "login";
      $LIST_PARAMS{TYPE} = 'USER';
      $FORM{TYPE} = 'USER';
      $graph_type = '';
    }

    ($table, $list) = result_former( {
      INPUT_DATA      => $Internet_ipoe,
      FUNCTION        => 'reports_users',
      #BASE_FIELDS     => 4,
      DEFAULT_FIELDS  => $x_text . ',TRAFFIC_IN,TRAFFIC_OUT,TRAFFIC_SUM,SUM',
      SKIP_USER_TITLE => 1,
      SELECT_VALUE    => {
        gid => sel_groups( { HASH_RESULT => 1 } ),
      },
      CHARTS          => 'users_count,traffic_in,traffic_out,sum',
      CHARTS_XTEXT    => $x_text,
      EXT_TITLES      => {
        traffic_in   => "$lang{TRAFFIC} $lang{RECV}",
        traffic_out  => "$lang{TRAFFIC} $lang{SENT}",
        traffic_sum  => "$lang{TRAFFIC} $lang{SUM}",

        traffic0_in  => "$lang{TRAFFIC} 1 $lang{RECV}",
        traffic0_out => "$lang{TRAFFIC} 1 $lang{SENT}",
        traffic0_sum => "$lang{TRAFFIC} 1 $lang{SUM}",

        traffic1_in  => "$lang{TRAFFIC} 2 $lang{RECV}",
        traffic1_out => "$lang{TRAFFIC} 2 $lang{SENT}",
        traffic1_sum => "$lang{TRAFFIC} 2 $lang{SUM}",

        users_count  => $lang{LOGINS},
        login        => $lang{LOGIN},
        hours        => $lang{HOURS},
        sum          => $lang{SUM},
        date         => $lang{DATE},
        ip           => 'IP'
      },
      FILTER_COLS     => {
        traffic_in    => 'int2byte',
        traffic_out   => 'int2byte',
        traffic_sum   => 'int2byte',

        traffic0_in   => 'int2byte',
        traffic0_out  => 'int2byte',
        traffic0_sum  => 'int2byte',

        traffic1_in   => 'int2byte',
        traffic1_out  => 'int2byte',
        traffic1_sum  => 'int2byte',

        login         => "search_link:from_users:UID,$type=1,$pages_qs",
        date          => "search_link:ipoe_use:DATE,DATE",
        hours         => "search_link:ipoe_use:HOURS,HOURS",

        build         => "search_link:report_payments:LOCATION_ID,LOCATION_ID,TYPE=USER,$pages_qs",
        district_name => "search_link:report_payments:DISTRICT_ID,DISTRICT_ID,TYPE=USER,$pages_qs",
        street_name   => "search_link:report_payments:STREET_ID,STREET_ID,TYPE=USER,$pages_qs",
      },
      TABLE           => {
        width            => '100%',
        caption          => "$lang{REPORTS}",
        qs               => $pages_qs,
        ID               => 'IPN_REPORTS_' . ($FORM{TYPE} || ''),

        SHOW_COLS_HIDDEN => {
          TYPE => $FORM{TYPE}
        },
        EXPORT           => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      #TOTAL        => 1
    } );

    print $html->make_charts(
      {
        PERIOD        => $graph_type,
        DATA          => \%DATA_HASH,
        AVG           => \%AVG,
        TITLE         => $lang{TRAFFIC},
        TRANSITION    => 1,
        OUTPUT2RETURN => 1,
        %CHARTS
      }
    );

    print $table->show();
  }

  $table = $html->table({
    width    => '100%',
    rows     => [
      [
        "$lang{USERS}: " . $html->b($Internet_ipoe->{USERS_COUNT}),
        "$lang{RECV}: " . $html->b(int2byte($Internet_ipoe->{TRAFFIC_IN_SUM}, { DIMENSION => $FORM{DIMENSION} })),
        "$lang{SENT}: " . $html->b(int2byte($Internet_ipoe->{TRAFFIC_OUT_SUM}, { DIMENSION => $FORM{DIMENSION} })),
        "$lang{TRAFFIC}: " . $html->b(int2byte(($Internet_ipoe->{TRAFFIC_IN_SUM} || 0) + ($Internet_ipoe->{TRAFFIC_OUT_SUM} || 0),
          { DIMENSION => $FORM{DIMENSION} })),
        "$lang{SUM}: " . $html->b($Internet_ipoe->{SUM})
      ]
    ],
    rowcolor => 'bg-success'
  });

  print ( ($table_sessions) ? $table_sessions->show() : '' );
  print $table->show() . $out;

  return 1;
}


1;