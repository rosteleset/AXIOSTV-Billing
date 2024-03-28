=head1 NAME

  Dv Reports

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(int2byte time2sec sec2time);

our (
  %lang,
  $html,
  $db,
  $admin,
  %conf
);

my $Dv = Dv->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Sessions = Dv_Sessions->new($db, $admin, \%conf);

#**********************************************************
=head2 dv_use_all_monthes()

=cut
#**********************************************************
sub dv_use_allmonthes {
  
  $FORM{allmonthes} = 1;
  dv_use();
  
  return 1;
}

#**********************************************************
# dv_use();
#**********************************************************
#@deprecated
sub dv_use {
  
  my %CAPTIONS_HASH = (
    '1:DATE:right'          => $lang{DATE},
    '2:USERS:left'          => $lang{USERS},
    '3:USERS_FIO:left'      => $lang{FIO},
    '4:TP:left'             => $lang{TARIF_PLAN},
    '5:SESSIONS:right'      => $lang{SESSIONS},
    '6:TRAFFIC_RECV:right'  => "$lang{TRAFFIC} $lang{RECV}",
    '7:TRAFFIC_SENT:right'  => "$lang{TRAFFIC} $lang{SENT}",
    '8:TRAFFIC_SUM:right'   => $lang{TRAFFIC},
    '9:TRAFFIC_2_SUM:right' => $lang{TRAFFIC} . " 2",
    '91:DURATION:right'     => $lang{DURATION},
    '92:SUM:right'          => $lang{SUM}
  );
  
  my $ACCT_TERMINATE_CAUSES_REV = dv_terminate_causes({ REVERSE => 1 });
  my $i = 1;
  my $list = $Conf->config_list({ PARAM => 'ifu*' });
  my %INFO_LISTS = ();
  
  foreach my $line ( @{$list} ) {
    my $field_id = '';
    if ( $line->[0] =~ /ifu(\S+)/ ) {
      $field_id = $1;
    }
    
    my (undef, $type, $name) = split(/:/, $line->[1]);
    
    $CAPTIONS_HASH{ (90 + $i) . ':' . $field_id . ':left' } = $name;
    
    if ($type && $type =~ /^\d+$/ && $type == 2 ) {
      my $list2 = $users->info_lists_list({ LIST_TABLE => $field_id . '_list' });
      foreach my $line2 ( @{$list2} ) {
        $INFO_LISTS{$field_id}->{ $line2->[0] } = $line2->[1];
      }
    }
    $i++;
  }
  
  my %HIDDEN = ();
  
  $HIDDEN{COMPANY_ID} = $FORM{COMPANY_ID} if ( $FORM{COMPANY_ID} );
  $HIDDEN{sid} = $sid if ( $FORM{sid} );
  
  reports(
    {
      DATE        => $FORM{DATE},
      REPORT      => '',
      HIDDEN      => \%HIDDEN,
      EX_PARAMS   => {
        HOURS => "$lang{HOURS}",
        USERS => "$lang{USERS}"
      },
      EXT_TYPE    => {
        TP              => "$lang{TARIF_PLANS}",
        GID             => "$lang{GROUPS}",
        TERMINATE_CAUSE => 'TERMINATE_CAUSE',
        COMPANIES       => $lang{COMPANIES}
      },
      PERIOD_FORM => 1,
      FIELDS      => { %CAPTIONS_HASH },
      XML         => 1,
      EX_INPUTS   => [
        $html->form_select(
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
        )
      ]
    }
  );
  
  if ( $FORM{TP_ID} ) {
    $LIST_PARAMS{TP_ID} = $FORM{TP_ID};
    $pages_qs .= "&TP_ID=$FORM{TP_ID}";
  }
  
  if ( $FORM{COMPANY_ID} ) {
    $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
    $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";
  }
  
  my $output = '';
  
  my %TP_NAMES = ();
  my %GROUP_NAMES = ();
  
  my %DATA_HASH = ();
  my %DATA_HASH2 = ();
  my %CHART = ();
  my %AVG = (
    MONEY    => 0,
    TRAFFIC  => 0,
    DURATION => 0
  );
  
  my @CHART_TYPE = ('column', 'line');
  my @CHART_TYPE2 = ('area', 'area');
  my $graph_type = '';
  my $table_sessions;
  my $type = $FORM{TYPE} || '';
  
  #Day reposrt
  if ( $FORM{DATE} ) {
    #Used Traffic
    $table_sessions = $html->table(
      {
        width   => '100%',
        caption => $lang{SESSIONS},
        title   =>
        [ $lang{DATE}, $lang{USERS}, $lang{SESSIONS}, $lang{TRAFFIC}, "$lang{TRAFFIC} 2", $lang{DURATION}, $lang{SUM} ],
        qs      => $pages_qs,
        ID      => 'DV_REPORTS_SESSIONS'
      }
    );
    
    if ( $FORM{EX_PARAMS} && $FORM{EX_PARAMS} eq 'HOURS' ) {
      
      $list = $Sessions->reports({ %LIST_PARAMS });
      my $num;
      foreach my $line ( @{$list} ) {
        $table_sessions->addrow($html->b($line->[0]), $line->[1], $line->[2],
          int2byte($line->[3], { DIMENSION => $FORM{DIMENSION} }),
          int2byte($line->[4], { DIMENSION => $FORM{DIMENSION} }), $line->[5], $html->b($line));
        
        $AVG{USERS} = $line->[1] if ( $AVG{USERS} < $line->[1] );
        $AVG{TRAFFIC} = $line->[3] if ( $AVG{TRAFFIC} < $line->[3] );
        $AVG{DURATION} = time2sec($line->[5]) if ( $AVG{DURATION} < time2sec($line->[5]) );
        $AVG{MONEY} = $line->[6] if ( $AVG{MONEY} < $line->[6] );
        
        if ( $line->[0] =~ /(\d+)-(\d+)-(\d+) (\d+)/ ) {
          $num = $4 + 1;
        }
        elsif ( $line->[0] =~ /(\d+)-(\d+)/ ) {
          $CHART{X_LINE}->[$num] = $line->[0];
          $num++;
        }
        
        $DATA_HASH{USERS}->[$num] = $line->[1];
        $DATA_HASH2{TRAFFIC}->[$num] = $line->[3];
        $DATA_HASH2{DURATION}->[$num] = time2sec($line->[5]);
        $DATA_HASH{MONEY}->[$num] = $line->[6];
        
      }
      
      $graph_type = 'day_stats';
      $output = $html->make_charts(
        {
          PERIOD        => $graph_type,
          DATA          => \%DATA_HASH2,
          AVG           => \%AVG,
          TYPE          => [ 'area', 'area' ],
          TRANSITION    => 1,
          OUTPUT2RETURN => 1
        }
      );
      
    }
    else {
      $list = $Sessions->reports({ %LIST_PARAMS });
      foreach my $line ( @{$list} ) {
        $table_sessions->addrow($html->b($line->[0]),
          $html->button("$line->[1]", "index=15&UID=$line->[7]&DATE=$line->[0]"), $line->[2],
          int2byte($line->[3], { DIMENSION => $FORM{DIMENSION} }),
          int2byte($line->[4], { DIMENSION => $FORM{DIMENSION} }), $line->[5], $html->b($line->[6]));
      }
    }
  }
  else {
    #Used Traffic
    my @caption = ();
    my %fields_hash = ();
    my @fields_arr = ();
    
    if ( $FORM{FIELDS} ) {
      @fields_arr = split(/, /, $FORM{FIELDS});
      foreach my $line ( @fields_arr ) {
        $fields_hash{$line} = 1;
      }
      
      $i = 0;
      foreach my $line ( sort keys %CAPTIONS_HASH ) {
        my (undef, $val, undef) = split(/:/, $line);
        
        if ( $fields_hash{$val} ) {
          push @caption, $CAPTIONS_HASH{$line};
          #push @field_align, $align;
          $fields_arr[$i] = $val;
          $i++;
        }
      }
    }
    else {
      @caption = ("$lang{DATE}", "$lang{USERS}", "$lang{SESSIONS}", "$lang{TRAFFIC} ", "$lang{TRAFFIC} 2",
        $lang{DURATION}, $lang{SUM});
      #@field_align = ('right', 'right', 'right', 'right', 'right', 'right', 'right');
    }
    
    $graph_type = 'month_stats';
    
    if ( $type eq 'USER' ) {
      $caption[0] = "$lang{USER}";
    }
    if ( $type eq 'COMPANIES' ) {
      $caption[0] = "$lang{COMPANIES}";
    }
    elsif ( $type eq 'TERMINATE_CAUSE' ) {
      $caption[0] = "$lang{ERROR}";
      @CHART_TYPE = ('pie');
      $graph_type = 'pie';
    }
    elsif ( $type eq 'TP' ) {
      $caption[0] = "$lang{TARIF_PLAN}";
      @CHART_TYPE2 = ('column', 'line');
      $CHART{AXIS_CATEGORY_skip} = 0;
    }
    elsif ( $type eq 'GID' ) {
      @CHART_TYPE2 = ('column', 'line');
      $CHART{AXIS_CATEGORY_skip} = 0;
      
      $caption[0] = $lang{GROUPS};
      my $list2 = $users->groups_list({
        GID             => '_SHOW',
        NAME            => '_SHOW',
        DESCR           => '_SHOW',
        ALLOW_CREDIT    => '_SHOW',
        DISABLE_PAYSYS  => '_SHOW',
        DISABLE_CHG_TP  => '_SHOW',
        USERS_COUNT     => '_SHOW',
      });
      
      foreach my $line ( @{$list2} ) {
        $GROUP_NAMES{ $line->[0] } = $line->[1];
      }
      
    }
    elsif ( $FORM{TP_ID} ) {
      $caption[0] = "$lang{LOGINS}";
      #$field_align[0] = 'left';
    }
    
    $table_sessions = $html->table(
      {
        width   => '100%',
        caption => "$lang{SESSIONS}",
        title   => \@caption,
        #cols_align => \@field_align,
        qs      => $pages_qs,
        ID      => 'DV_REPORTS_SESSIONS'
      }
    );
    
    my $num = 0;
    $list = $Sessions->reports({ %LIST_PARAMS, COLS_NAME => undef });
    
    foreach my $line ( @{$list} ) {
      my @rows = ();
      if ( $FORM{FIELDS} ) {
        for ( $i = 0; $i <= $#caption; $i++ ) {
          if ( $fields_arr[$i] =~ /TRAFFIC/ ) {
            push @rows, int2byte($line->[$i], { DIMENSION => $FORM{DIMENSION} });
          }
          elsif ( $fields_arr[$i] =~ /USERS/ || $fields_arr[$i] =~ /USERS_FIO/ ) {
            push @rows, $html->button("$line->[$i]", "index=11&UID=" . ($line->[ $#fields_arr + 1 ]));
          }
          elsif ( $fields_arr[$i] =~ /^_/ && ref($INFO_LISTS{ $fields_arr[$i] }) eq 'HASH' ) {
            push @rows,
                ($INFO_LISTS{ $fields_arr[$i] }->{ $line->[$i] }) ? $INFO_LISTS{ $fields_arr[$i] }->{ $line->[$i] } : '';
          }
          elsif ( $fields_arr[$i] =~ 'TP' ) {
            if ( scalar keys %TP_NAMES == 0 ) {
              $list = $Tariffs->list({ MODULE => 'Dv', NEW_MODEL_TP => 1, COLS_NAME => 1 });
              foreach my $line2 ( @{$list} ) {
                $TP_NAMES{ $line2->{id} } = $line2->{name};
              }
            }
            
            push @rows, (($type eq 'TP') ? $line->{id} : $line->{name})
                . '. ' . $html->button($TP_NAMES{ (($type eq 'TP') ? $line->{id} : $line->{name}) },
                "index=$index&TP_ID=" . (($type eq 'TP') ? $line->{id} : $line->{name}) . "$pages_qs");
          }
          elsif ( $fields_arr[$i] =~ 'GID' ) {
            push @rows,
              $line->[0] . '. ' . $html->button($GROUP_NAMES{ $line->[0] }, "index=$index&GID=$line->[0]$pages_qs");
          }
          else {
            push @rows, $line->[$i];
          }
        }
      }
      else {
        my $button = '';
        if ( $type eq 'USER' ) {
          $button = $html->button($line->[0], "index=11&UID=$line->[7]");
        }
        elsif ( $type eq 'TP' ) {
          $button = $line->[0] . '. ' . $html->button($TP_NAMES{ $line->[0] },
            "index=$index&TP_ID=$line->[0]$pages_qs");
        }
        elsif ( $type eq 'COMPANIES' ) {
          $button = $html->button("$line->[0]", "index=13&COMPANY_ID=$line->[8]");
        }
        elsif ( $type eq 'GID' ) {
          $button = $line->[0] . '. ' . $html->button($GROUP_NAMES{ $line->[0] },
            "index=$index&GID=$line->[0]$pages_qs");
        }
        elsif ( $FORM{TP_ID} ) {
          $button = $html->button("$line->[0]", "index=11&$type=$line->[0]&UID=$line->[7]");
        }
        elsif ( $type eq 'TERMINATE_CAUSE' ) {
          $button = $html->button($ACCT_TERMINATE_CAUSES_REV->{ $line->[0] },
            "index=$index&$type=$line->[0]&TERMINATE_CAUSE=$line->[0]$pages_qs");
          
          $DATA_HASH{TYPE}->[ $num + 1 ] = $line->[3];
          $CHART{X_TEXT}->[$num] = $line->[0];
          
          $num++;
        }
        else {
          $button = $html->button($line->[0], "index=$index&$type=$line->[0]$pages_qs");
        }
        
        @rows = ($button, $line->[1], $line->[2], int2byte($line->[3], { DIMENSION => $FORM{DIMENSION} }),
          int2byte($line->[4], { DIMENSION => $FORM{DIMENSION} }), $line->[5], $html->b($line->[6]));
        
        if ( $type ne 'TERMINATE_CAUSE' ) {
          $AVG{USERS} = $line->[1] if ( $AVG{USERS} && $AVG{USERS} < $line->[1] );
          $AVG{TRAFFIC} = $line->[3] if ( $AVG{TRAFFIC} && $AVG{TRAFFIC} < $line->[3] );
          
          $AVG{DURATION} = time2sec($line->[5]) if ( $AVG{DURATION} < time2sec($line->[5]) );
          $AVG{MONEY} = $line->[6] if ( $AVG{MONEY} < $line->[6] );
          
          if ( $line->[0] =~ /(\d+)-(\d+)-(\d+)/ ) {
            $num = $3;
          }
          elsif ( $line->[0] =~ /(\d+)-(\d+)/ ) {
            $CHART{X_LINE}->[$num] = $line->[0];
            $num++;
          }
          else {
            $CHART{X_TEXT}->[$num] = $line->[0];
            $num++;
          }
          
          $DATA_HASH{USERS}->[$num] = $line->[1];
          $DATA_HASH2{TRAFFIC}->[$num] = $line->[3];
          $DATA_HASH2{DURATION}->[$num] = time2sec($line->[5]);
          $DATA_HASH{MONEY}->[$num] = $line->[6];
        }
      }
      
      $table_sessions->addrow(@rows);
    }
    
    if ( $graph_type ne 'pie' ) {
      
      $output = $html->make_charts(
        {
          PERIOD        => $graph_type,
          DATA          => \%DATA_HASH2,
          AVG           => \%AVG,
          TYPE          => \@CHART_TYPE2,
          TRANSITION    => 1,
          OUTPUT2RETURN => 1,
          %CHART
        }
      );
    }
  }
  
  my $table = $html->table(
    {
      width    => '100%',
      rows     => [
        [
          "$lang{USERS}: " . $html->b($Sessions->{USERS}),
          "$lang{SESSIONS}: " . $html->b($Sessions->{SESSIONS}),
          "$lang{TRAFFIC}: "
            . $html->b(int2byte($Sessions->{TRAFFIC}))
            . $html->br()
            . "$lang{TRAFFIC} IN: "
            . $html->b(int2byte($Sessions->{TRAFFIC_IN}))
            . $html->br()
            . "$lang{TRAFFIC} OUT: "
            . $html->b(int2byte($Sessions->{TRAFFIC_OUT}))
          ,
          
          "$lang{TRAFFIC} 2: " . $html->b(int2byte($Sessions->{TRAFFIC_2})) . $html->br() . "$lang{TRAFFIC} 2 IN: " . $html->b(int2byte($Sessions->{TRAFFIC_2_IN})) . $html->br() . "$lang{TRAFFIC} 2 OUT: " . $html->b(int2byte($Sessions->{TRAFFIC_2_OUT})),
          
          "$lang{DURATION}: " . $html->b($Sessions->{DURATION}),
          "$lang{SUM}: " . $html->b($Sessions->{SUM})
        ]
      ],
      rowcolor => 'even'
    }
  );
  
  print $table_sessions->show() . $table->show();
  
  $table = $html->table({ rows => [ [ $output ] ] });
  print $table->show();
  
  if ( $graph_type ne '' ) {
    $html->make_charts(
      {
        PERIOD     => $graph_type,
        DATA       => \%DATA_HASH,
        AVG        => \%AVG,
        TYPE       => \@CHART_TYPE,
        TRANSITION => 1,
        %CHART
      }
    );
  }
  
  return 1;
}

#**********************************************************
=head2 dv_report_use();

=cut
#**********************************************************
sub dv_report_use {
  
  my %HIDDEN = ();
  $HIDDEN{COMPANY_ID} = $FORM{COMPANY_ID} if ( $FORM{COMPANY_ID} );
  $HIDDEN{sid} = $sid if ( $FORM{sid} );
  
  my %ext_fields = (
    arpu            => $lang{ARPU},
    arpuu           => $lang{ARPPU},
    date            => $lang{DATE},
    month           => $lang{MONTH},
    login           => $lang{USER},
    fio             => $lang{FIO},
    hour            => $lang{HOURS},
    build           => $lang{ADDRESS_BUILD},
    district_name   => $lang{DISTRICT},
    street_name     => $lang{ADDRESS_STREET},
    login_count     => $lang{USERS},
    count           => $lang{COUNT},
    sum             => $lang{SUM},
    terminate_cause => "$lang{HANGUP} $lang{STATUS}",
    gid             => $lang{GROUPS},
    duration_sec    => $lang{DURATION},
    users_count     => $lang{USERS},
    sessions_count  => $lang{SESSIONS},
    traffic_recv    => $lang{SENT},
    traffic_sent    => $lang{RECV},
    traffic_sum     => $lang{TRAFFIC},
    traffic_2_sum   => "$lang{TRAFFIC} 2",
    company_name    => $lang{COMPANY}
  );
  
  reports(
    {
      DATE        => $FORM{DATE},
      HIDDEN      => \%HIDDEN,
      REPORT      => '',
      PERIOD_FORM => 1,
      EXT_TYPE    => {
        PER_MONTH       => $lang{PER_MONTH},
        DISTRICT        => $lang{DISTRICT},
        STREET          => $lang{STREET},
        BUILD           => $lang{BUILD},
        TP              => "$lang{TARIF_PLANS}",
        GID             => "$lang{GROUPS}",
        TERMINATE_CAUSE => 'TERMINATE_CAUSE',
        COMPANIES       => $lang{COMPANIES}
      },
    }
  );
  
  %CHARTS = (
    TYPES  => {
      login_count    => 'column',
      users_count    => 'column',
      sessions_count => 'column',
      traffic_recv   => 'column',
      traffic_sent   => 'column',
      duration_sec   => 'column'
    },
    PERIOD => (!$FORM{TYPE} && !$FORM{DATE}) ? 'month_stats' : ''
  );
  
  my %TP_NAMES = ();
  my $list = $Tariffs->list({ MODULE => 'Dv', NEW_MODEL_TP => 1, COLS_NAME => 1 });
  foreach my $line ( @{$list} ) {
    $TP_NAMES{ $line->{id} } = $line->{name};
  }
  
  if ( $FORM{TERMINATE_CAUSE} ) {
    $LIST_PARAMS{TERMINATE_CAUSE} = $FORM{TERMINATE_CAUSE};
  }
  elsif ( $FORM{TP_ID} ) {
    $LIST_PARAMS{TP_ID} = $FORM{TP_ID};
  }
  
  $Sessions->{debug} = 1 if ( $FORM{DBEUG} );
  my AXbills::HTML $table;
  our %DATA_HASH;
  ($table, $list) = result_former({
    INPUT_DATA      => $Sessions,
    FUNCTION        => 'reports2',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'USERS_COUNT,SESSIONS_COUNT,TRAFFIC_RECV,TRAFFIC_SENT,DURATION_SEC,SUM',
    SKIP_USER_TITLE => (!$FORM{TYPE} || $FORM{TYPE} ne 'USER') ? 1 : undef,
    SELECT_VALUE    => {
      terminate_cause => dv_terminate_causes({ REVERSE => 1 }),
      gid             => sel_groups({ HASH_RESULT => 1 }),
      tp_id           => \%TP_NAMES
    },
    # CHARTS          => 'users_count,sessions_count,traffic_recv,traffic_sent,duration_sec',
    # CHARTS_XTEXT    => 'auto', #$x_text,
    EXT_TITLES      => \%ext_fields,
    FILTER_COLS     => {
      duration_sec    => 'sec2time_str',
      traffic_recv    => 'int2byte',
      traffic_sent    => 'int2byte',
      traffic_sum     => 'int2byte',
      terminate_cause => "search_link:dv_report_use:TERMINATE_CAUSE,$pages_qs",
      company_name    => "search_link:dv_report_use:COMPANY_NAME,$pages_qs",
      tp_id           => "search_link:dv_report_use:TP_ID,$pages_qs",
      month           => "search_link:dv_report_use:MONTH,$pages_qs",
      gid             => "search_link:dv_report_use:GID,$pages_qs",
      date            => "search_link:dv_report_use:DATE,DATE",
      login           => "search_link:from_users:UID,type=1,$pages_qs",
      build           => "search_link:dv_report_use:LOCATION_ID,LOCATION_ID,TYPE=USER,$pages_qs",
      district_name   => "search_link:dv_report_use:DISTRICT_ID,DISTRICT_ID,TYPE=USER,$pages_qs",
      street_name     => "search_link:dv_report_use:STREET_ID,STREET_ID,TYPE=USER,$pages_qs",
    },
    TABLE           => {
      width            => '100%',
      caption          => "$lang{REPORTS}",
      qs               => $pages_qs,
      ID               => 'REPORTS_DV_USE',
      EXPORT           => 1,
      SHOW_COLS_HIDDEN => { TYPE => $FORM{TYPE},
        show                     => 1,
        FROM_DATE                => $FORM{FROM_DATE},
        TO_DATE                  => $FORM{TO_DATE},
      }
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    #TOTAL        => 1
  });
  
  print $html->make_charts(
    {
      DATA          => \%DATA_HASH,
      #AVG           => \%AVG,
      #TYPE          => \@CHART_TYPE,
      TITLE         => 'Internet',
      TRANSITION    => 1,
      OUTPUT2RETURN => 1,
      %CHARTS
    }
  );
  
  print $table->show();
  
  $table = $html->table(
    {
      width    => '100%',
      rows     => [
        [
          "$lang{USERS}: " . $html->b($Sessions->{USERS}),
          "$lang{SESSIONS}: " . $html->b($Sessions->{SESSIONS}),
          "$lang{TRAFFIC}: "
            . $html->b(int2byte($Sessions->{TRAFFIC}))
            . $html->br()
            . "$lang{TRAFFIC} IN: "
            . $html->b(int2byte($Sessions->{TRAFFIC_IN}))
            . $html->br()
            . "$lang{TRAFFIC} OUT: "
            . $html->b(int2byte($Sessions->{TRAFFIC_OUT}))
          ,
          
          "$lang{TRAFFIC} 2: " . $html->b(int2byte($Sessions->{TRAFFIC_2})) . $html->br() . "$lang{TRAFFIC} 2 IN: " . $html->b(int2byte($Sessions->{TRAFFIC_2_IN})) . $html->br() . "$lang{TRAFFIC} 2 OUT: " . $html->b(int2byte($Sessions->{TRAFFIC_2_OUT})),
          
          "$lang{DURATION}: " . $html->b(sec2time($Sessions->{DURATION_SEC}, { str => 1 })),
          "$lang{SUM}: " . $html->b($Sessions->{SUM})
        ]
      ],
      rowcolor => 'even'
    }
  );
  
  print $table->show();
  
  return 1;
}

#**********************************************************
=head2 dv_report_debetors($attr)

=cut
#**********************************************************
sub dv_report_debetors {
  
  result_former({
    INPUT_DATA      => $Dv,
    FUNCTION        => 'report_debetors',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'LOGIN,FIO,PHONE,TP_NAME,DEPOSIT,CREDIT,DV_STATUS',
    FUNCTION_FIELDS => '',
    EXT_TITLES      => {
      'ip'             => 'IP',
      'netmask'        => 'NETMASK',
      'speed'          => $lang{SPEED},
      'port'           => $lang{PORT},
      'cid'            => 'CID',
      'filter_id'      => 'Filter ID',
      'tp_name'        => "$lang{TARIF_PLAN}",
      'dv_status'      => "Internet $lang{STATUS}",
      'dv_status_date' => "$lang{STATUS} $lang{DATE}",
      'online'         => 'Online',
      'dv_expire'      => "Internet $lang{EXPIRE}",
      'dv_login'       => "$lang{SERVICE} $lang{LOGIN}",
      'dv_password'    => "$lang{SERVICE} $lang{PASSWD}"
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{DEBETORS}",
      qs      => $pages_qs,
      ID      => 'REPORT_DEBETORS',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    MODULE          => 'Dv',
    TOTAL           => "TOTAL:$lang{TOTAL};TOTAL_DEBETORS_SUM:$lang{SUM}"
  });
  
  return 1;
}

#**********************************************************
=head2 dv_report_tp()

=cut
#**********************************************************
sub dv_report_tp {
  
  my $list = $Dv->report_tp({
    %LIST_PARAMS,
    COLS_NAME => 1
  });
  
  my $table = $html->table(
    {
      caption => $lang{TARIF_PLANS},
      width   => '100%',
      title   => [ "#", $lang{NAME}, $lang{TOTAL}, $lang{ACTIV}, $lang{DISABLE},
        $lang{DEBETORS}, "ARPPU $lang{ARPPU}", "ARPU $lang{ARPU}" ],
      ID      => 'REPORTS_TARIF_PLANS'
    }
  );
  
  my $dv_users_list_index = get_function_index('dv_users_list') || 0;
  
  my ($total_users, $totals_active, $total_disabled, $total_debetors) = (0, 0, 0, 0);
  foreach my $line ( @{$list} ) {
    $line->{id} = 0 if ( !defined($line->{id}) );
    $table->addrow(
      $line->{id},
      $html->button($line->{name}, "index=$dv_users_list_index&TP_NUM=$line->{id}"),
      $html->button($line->{counts}, "index=$dv_users_list_index&TP_NUM=$line->{id}"),
      $html->button($line->{active}, "index=$dv_users_list_index&TP_NUM=$line->{id}&DV_STATUS=0"),
      $html->button($line->{disabled}, "index=$dv_users_list_index&TP_NUM=$line->{id}&DV_STATUS=1"),
      $html->button($line->{debetors}, "index=$dv_users_list_index&TP_NUM=$line->{id}&DEPOSIT=<0&search=1"),
      sprintf('%.2f', $line->{arppu} || 0),
      sprintf('%.2f', $line->{arpu} || 0)
    );
    
    $total_users += $line->{counts};
    $totals_active += $line->{active};
    $total_disabled += $line->{disabled};
    $total_debetors += $line->{debetors};
  }
  
  $table->addrow(
    '',
    $lang{TOTAL},
    $total_users,
    $totals_active,
    $total_disabled,
    $total_debetors
  );
  
  print $table->show();
  
  return 1;
}

#**********************************************************
=head2 dv_pools_report()

=cut
#**********************************************************
sub dv_pools_report {
  my ($attr) = @_;
  $attr //= \%FORM;
  
  use AXbills::Base qw/_bp/;
  my $DDebug = 0;
  
  require Nas;
  Nas->import();
  my Nas $Nas = Nas->new($db, \%conf, $admin);
  
  # Get dv static ips
  my $static_assigned_list = $Dv->list({
    IP_NUM    => '>0.0.0.0',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });
  _error_show($Dv);
  _bp('static raw', $static_assigned_list) if ( $DDebug > 2 );
  
  my @static_ips = map {$_->{ip_num}} @{$static_assigned_list};
  
  _bp('static array', \@static_ips) if ( $DDebug > 2 );
  # Get online ips
  my $active_assigned_list = $Sessions->online({
    CLIENT_IP_NUM => '_SHOW',
    NAS_ID        => '_SHOW',
    
    COLS_NAME     => 1,
    PAGE_ROWS     => 100000
  });
  _error_show($Sessions);
  
  _bp('active raw', $active_assigned_list) if ( $DDebug > 2 );
  my @online_ips = map {$_->{client_ip_num}} @{$active_assigned_list};
  _bp('active array', \@online_ips) if ( $DDebug > 2 );
  
  # Get pools
  my $pools_list = $Nas->nas_ip_pools_list({
    COLS_NAME => 1,
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS => 10000
  });
  _error_show($Nas);
  
  _bp('Pools', $pools_list) if ( $DDebug > 2 );
  
  my %pools_by_id = map {$_->{id} => $_} @{$pools_list};
  
  # Assign ips to pools
  my %ips_for_pool = ();
  # {
  #  '%pool_id%' => {
  #    ips => {
  #      'ip_address' => type # (0 - dynamic, 1 - static, static-in-dynamic - 2 )
  #    },
  #    static_count  => '%num%',
  #    dynamic_count => '%num%',
  #    count         => '%num%'  - total
  #  },
  #   ...
  #}
  
  my $find_pool_for_address = sub {
    my $ip_addr_num = shift;
    
    foreach my $pool ( @{$pools_list} ) {
      return $pool->{id} if ( $ip_addr_num >= $pool->{ip} && $ip_addr_num <= $pool->{last_ip_num} );
    }
    
    return 0;
  };
  
  my @static_without_pool = ();
  foreach my $static_addr ( @static_ips ) {
    my $pool_id = $find_pool_for_address->($static_addr);
    
    if ( !$pool_id ) {
      push (@static_without_pool, $static_addr);
      next;
    }
    
    $ips_for_pool{$pool_id}->{count} //= 0;
    $ips_for_pool{$pool_id}->{static_count} //= 0;
    $ips_for_pool{$pool_id}->{dynamic_count} //= 0;
    
    if ( !$pools_by_id{$pool_id}->{static} ) {
      # Showing errornous assigning static ip from dynamic pool
      $ips_for_pool{$pool_id}->{ip}->{$static_addr} = 2;
      $ips_for_pool{$pool_id}->{static_count} += 1;
    }
    else {
      $ips_for_pool{$pool_id}->{ip}->{$static_addr} = 1;
      $ips_for_pool{$pool_id}->{static_count} += 1;
    }
    
    $ips_for_pool{$pool_id}->{count} += 1;
  }
  
  my @dynamic_without_pool = ();
  foreach my $online_addr ( @online_ips ) {
    # Skip if found static ip in online
    next if ( grep {$_ == $online_addr} @static_ips );
    
    my $pool_id = $find_pool_for_address->($online_addr);
    
    if ( !$pool_id ) {
      push (@dynamic_without_pool, $online_addr);
      next;
    }
    
    $ips_for_pool{$pool_id}->{count} //= 0;
    $ips_for_pool{$pool_id}->{static_count} //= 0;
    $ips_for_pool{$pool_id}->{dynamic_count} //= 0;
    
    # Showing errornous assigning static ip from dynamic pool
    if ( $pools_by_id{$pool_id}->{static} ) {
      $ips_for_pool{$pool_id}->{ip}->{$online_addr} = 1;
      $ips_for_pool{$pool_id}->{dynamic_count} += 1;
    }
    else {
      $ips_for_pool{$pool_id}->{ip}->{$online_addr} = 0;
      $ips_for_pool{$pool_id}->{dynamic_count} += 1;
    }
    
    $ips_for_pool{$pool_id}->{count} += 1;
    
  }
  
  _bp('Pool using', \%ips_for_pool) if ( $DDebug > 2 );
  
  # Check pool sizes and build fillness data
  foreach my $pool_id ( sort keys %ips_for_pool ) {
    
    my $dynamic = $ips_for_pool{$pool_id}->{dynamic_count} / $pools_by_id{$pool_id}->{ip_count};
    my $static = $ips_for_pool{$pool_id}->{static_count} / $pools_by_id{$pool_id}->{ip_count};
    #    my $free = 1 - ($ips_for_pool{$pool_id}{count} / $pools_by_id{$pool_id}{ip_count});
    my $free = 1 - ($dynamic + $static);
    
    $ips_for_pool{$pool_id}->{usage}->{dynamic} = sprintf("%.2f", $dynamic * 100);
    $ips_for_pool{$pool_id}->{usage}->{static} = sprintf("%.2f", $static * 100);
    $ips_for_pool{$pool_id}->{usage}->{free} = sprintf("%.2f", $free * 100);
  }
  
  _bp('Pool using with percents', \%ips_for_pool) if ( $DDebug );
  return \%ips_for_pool if ( $attr->{RETURN_USAGE} );
  
  my %charts = ();
  
  foreach my $pool_id ( sort keys %pools_by_id ) {
    
    my $normal_fill = ($pools_by_id{$pool_id}->{static}) ? 'static' : 'dynamic';
    my $errornous_fill = ($pools_by_id{$pool_id}->{static}) ? 'dynamic' : 'static';
    
    if ( !$ips_for_pool{$pool_id} || !$ips_for_pool{$pool_id}->{usage} ) {
      $charts{$pool_id} = $html->chart({
        TYPE              => 'pie',
        X_LABELS          => [ $lang{FREE} ],
        DATA              => {
          'USAGE' => [ 100 ],
        },
        HIDE_LEGEND       => 1,
        BACKGROUND_COLORS => {
          'USAGE' => [ '#4CAF50' ],
        },
        OUTPUT2RETURN     => 1,
      });
      next;
    }
    
    my @usage = (
      $ips_for_pool{$pool_id}->{usage}->{free},
      $ips_for_pool{$pool_id}->{usage}->{$normal_fill},
    );
    push (@usage,
      $ips_for_pool{$pool_id}->{usage}->{$errornous_fill}) if ( $ips_for_pool{$pool_id}->{usage}->{$errornous_fill} > 0 );
    
    $charts{$pool_id} = $html->chart({
      TYPE              => 'pie',
      X_LABELS          => [ $lang{FREE}, $lang{USED}, $lang{ERROR} ],
      DATA              => {
        'USAGE' => \@usage,
      },
      HIDE_LEGEND       => 1,
      BACKGROUND_COLORS => {
        #        'USAGE' => [ 'rgb(255,205,86)', 'rgb(255,99,132)', 'rgb(54, 162, 235)' ],
        'USAGE' => [ '#4CAF50', '#FF9800', '#F44336' ],
      },
      OUTPUT2RETURN     => 1,
    });
  }
  
  my $pools_index = get_function_index('form_ip_pools');
  
  my @rows = ();
  my $result = '';
  my $wrap_size = ($attr->{WRAP_SIZE} || '3');
  my $charts_in_row = 12 / $wrap_size;
  my $current_charts_in_row = 0;
  foreach my $pool_id ( sort keys %pools_by_id ) {
    my $pool = $pools_by_id{$pool_id};
    my $errornous_fill = ($pools_by_id{$pool_id}->{static}) ? 'dynamic' : 'static';
    
    $result .= $html->tpl_show(_include('dv_pool_report_single', 'Dv'),
      {
        COLS_SIZE   => $wrap_size,
        NAME        => $html->button($pool->{pool_name}, "index=$pools_index&chg=$pool->{id}"),
        NAS_NAME    => $pool->{static} ? $lang{STATIC} : ($pool->{nas_name} || $lang{NO}),
        IP_RANGE    => $pool->{first_ip} . '-' . $pool->{last_ip},
        
        USED        => $ips_for_pool{$pool_id}->{count} // 0,
        FREE        => $ips_for_pool{$pool_id}->{usage}{free} // 100,
        ERROR       => $ips_for_pool{$pool_id}->{usage}{$errornous_fill} // 0,
        
        USAGE_CHART => $charts{$pool_id},
      },
      { OUTPUT2RETURN => 1 }
    );
    
    $current_charts_in_row += 1;
    if ( $current_charts_in_row >= $charts_in_row ) {
      push (@rows, $html->element('div', $result, { class => 'row' }));
      $result = '';
    }
  }
  # Wrap last row
  push (@rows, $html->element('div', $result, { class => 'row' })) if ( $result );
  
  my $return_html = ($attr->{RETURN_HTML} || $attr->{OUTPUT2RETURN});
  $result = $html->element('div', join('', @rows), {
      class         => 'row',
      OUTPUT2RETURN => $return_html
    }
  );
  return $result if ( $attr->{RETURN_HTML} );
  
  if ( !$attr->{OUTPUT2RETURN} ) {
    print $result;
  }
  
  return \%charts;
}

1;