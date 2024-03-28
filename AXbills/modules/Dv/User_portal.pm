=head2 NAME

  Dv User portal

=cut

use warnings;
use strict;

use AXbills::Base qw(sec2time in_array convert int2byte ip2int int2ip date_diff show_hash);
use AXbills::Filters qw(_mac_former);

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  @WEEKDAYS,
  @MONTHES
);

our Users $user;

my $Dv       = Dv->new($db, $admin, \%conf);
my $Fees     = Fees->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Sessions = Dv_Sessions->new($db, $admin, \%conf);
my $Nas      = Nas->new($db, \%conf, $admin);
my $Shedule  = Shedule->new($db, $admin, \%conf);
my $Log      = Log->new($db, \%conf);


#**********************************************************
=head2 dv_user_info()

=cut
#**********************************************************
sub dv_user_info {

  my $service_status = sel_status({ HASH_RESULT => 1 });
  our $Isg;
  if ($conf{DV_ISG}) {
    require Dv::Cisco_isg;
    #Check deposit and disable STATUS
    my $list = $Dv->list(
      {
        LOGIN         => $user->{LOGIN},
        CREDIT        => '_SHOW',
        DEPOSIT       => '_SHOW',
        DV_STATUS     => '_SHOW',
        TP_NAME       => '_SHOW',
        TP_CREDIT     => '>0',
        PAYMENTS_TYPE => 0,
        COLS_NAME     => 1
      }
    );

    if ($Dv->{TOTAL} < 1) {

    }
    elsif (($list->[0]->{credit} > 0 && ($list->[0]->{deposit} + $list->[0]->{credit} < 0))
      || ($list->[0]->{credit} == 0 && $list->[0]->{deposit} + $list->[0]->{credit}) < 0)
    {
      form_neg_deposit($user);
      return 0;
    }
    elsif ($list->[0]->{dv_status} && $list->[0]->{dv_status} == 1) {
      $html->message('err', $lang{ERROR}, "$lang{SERVICES} '$list->[0]->{tp_name}' $lang{DISABLE}", { ID => 15 });
      return 0;
    }

    if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "account-status-query", { USER_NAME => $user->{LOGIN} })) {
      return 0;
    }

    if ($Isg->{ISG_CID_CUR}) {
      #change speed (active turbo mode)
      if ($FORM{SPEED}) {
        if ($Isg->{CURE_SERVICE} =~ /TP/ || !$Isg->{TURBO_MODE_RUN}) {
          my $service_name = 'TURBO_SPEED' . $FORM{SPEED};

          #Deactive cure service (TP Service)
          if ($Isg->{CURE_SERVICE} =~ /TP/) {
            if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "deactivate-service", { USER_NAME    => $user->{LOGIN},
                CURE_SERVICE => $Isg->{CURE_SERVICE},
                SERVICE_NAME => $service_name  })) {

            }
          }

          #Activate service
          if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "deactivate-service", { USER_NAME => $user->{LOGIN}, SERVICE_NAME => $service_name })) {
            return 0;
          }
        }
        elsif ($Isg->{TURBO_MODE_RUN}) {
          $html->message('info', $lang{INFO}, "TURBO $lang{MODE} $lang{ENABLE}");
        }
      }
    }
  }
  # Users autoregistrations
  elsif ($conf{DV_IP_DISCOVERY} && ! $Dv->{STATUS}) {
    if(! dv_discovery($user->{REMOTE_ADDR})) {
      return 0;
    }
  }
  $Dv->info($LIST_PARAMS{UID}, { DOMAIN_ID => $user->{DOMAIN_ID} });

  if ($FORM{activate}) {
    my $old_status = $Dv->{STATUS};
    $Dv->change(
      {
        UID    => $LIST_PARAMS{UID},
        STATUS => 0,
        CID    => ($Isg->{ISG_CID_CUR}) ? $Isg->{ISG_CID_CUR} : undef,
      }
    );

    if (!$Dv->{errno}) {
      $Dv->{ACCOUNT_ACTIVATE}=$user->{ACTIVATE};
      $html->message('info', $lang{INFO}, "$lang{ACTIVATE} CID: $Isg->{ISG_CID_CUR}") if ($Isg->{ISG_CID_CUR});
      service_get_month_fee($Dv) if (!$Dv->{STATUS});
      if($conf{DV_USER_ACTIVATE_DATE} && $old_status == 2) {
        $user->change($LIST_PARAMS{UID}, { ACTIVATE => $DATE, UID => $LIST_PARAMS{UID} });
        $html->message('info', $lang{INFO}, "$lang{ACTIVATE} $DATE");
      }
    }
    else {
      $html->message('err', $lang{ACTIVATE}, "$lang{ERROR} CID: $Isg->{ISG_CID_CUR}", { ID => 102 });
    }

    #Log on
    if($conf{DV_ISG}) {
      if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "account-logoff",
        { USER_NAME => $user->{LOGIN},
          #'User-Password' => '123456'
        })) {
        return 0;
      }
    }
  }
  elsif ($FORM{logon}) {
    #Logon
    if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "account-logoff",
      { USER_NAME => $user->{LOGIN},
      })) {
      return 0;
    }
  }
  elsif ($FORM{hangup}) {
    require AXbills::Nas::Control;
    AXbills::Nas::Control->import();
    my $Nas_cmd = AXbills::Nas::Control->new($db, \%conf);

    $Nas_cmd->hangup(
      $Nas,
      0,
      $user->{LOGIN},
      {
        ACCT_SESSION_ID      => '',
        FRAMED_IP_ADDRESS    => $user->{REMOTE_ADDR},
        UID                  => $user->{UID},
        USER_INFO            => $user->{LOGIN},
        CID                  => 'User hangup',
        ACCT_TERMINATE_CAUSE => 1
      }
    );
  }

  $user->{DV_STATUS} = $Dv->{STATUS};

  if ($Dv->{TOTAL} < 1) {
    $html->message('info', "Internet $lang{SERVICE}", "$lang{NOT_ACTIVE}", { ID => 17 });
    return 0;
  }

  ($Dv->{NEXT_FEES_WARNING}, $Dv->{NEXT_FEES_MESSAGE_TYPE}) = dv_warning({ USER => $user,
    DV   => $Dv
  });

  if ($Dv->{NEXT_FEES_WARNING}) {
    $Dv->{NEXT_FEES_WARNING}=$html->message("$Dv->{NEXT_FEES_MESSAGE_TYPE}", "", $Dv->{NEXT_FEES_WARNING}, { OUTPUT2RETURN => 1 }) ;
  }
  
  # Check for sheduled tp change
  my $sheduled_tp_actions_list = $Shedule->list(
    {
      UID       => $user->{UID},
      TYPE      => 'tp',
      MODULE    => 'Dv',
      COLS_NAME => 1
    }
  );
  
  if ($sheduled_tp_actions_list && ref $sheduled_tp_actions_list eq 'ARRAY' && scalar @$sheduled_tp_actions_list){
    my $next_tp_action = $sheduled_tp_actions_list->[0];
    my $next_tp_id = $next_tp_action->{action};
    my $next_tp_date = "$next_tp_action->{y}-$next_tp_action->{m}-$next_tp_action->{d}";
    
    # Get info about next TP
    my $tp_list = $Tariffs->list({
      TP_ID     => $next_tp_id,
      NAME      => '_SHOW',
      COLS_NAME => 1
    });
    
    if ($tp_list && ref $tp_list eq 'ARRAY' && scalar @$tp_list){
      my $next_tp_name = $tp_list->[0]{name};
      $Dv->{TP_CHANGE_WARNING} = $html->message('callout', $lang{TP_CHANGE_SHEDULED}, "$next_tp_name ($next_tp_date)", {OUTPUT2RETURN => 1});
    }
  }

  my ($status, $color) = split(/:/, $service_status->{ $Dv->{STATUS} });
  $user->{SERVICE_STATUS} = $Dv->{STATUS};

  if ($Dv->{STATUS} == 2) {
    $Dv->{STATUS_VALUE} = $html->color_mark($status, $color) . ' ';
    $Dv->{STATUS_VALUE} .= ($user->{DISABLE} > 0) ? $html->b("($lang{ACCOUNT} $lang{DISABLE})")
                                            : $html->button($lang{ACTIVATE}, "&index=$index&sid=$sid&activate=1", { ID => 'ACTIVATE', class => 'btn btn-success float-right' });
  }
  elsif ($Dv->{STATUS} == 5) {
    $Dv->{STATUS_VALUE} = $html->color_mark($status, $color) . ' ';

    if ($Dv->{MONTH_ABON} && $user->{DEPOSIT} && $Dv->{MONTH_ABON} <= $user->{DEPOSIT}) {
      $Dv->{STATUS_VALUE} .= ($user->{DISABLE} > 0) ? $html->b("($lang{ACCOUNT} $lang{DISABLE})")
                                              : $html->button($lang{ACTIVATE}, "&index=$index&sid=$sid&activate=1", { ex_params => ' ID="ACTIVATE"', BUTTON => 1 });
    }
    else {
      if ($functions{$index} && $functions{$index} eq 'dv_user_info') {
        form_neg_deposit($user);
      }
    }
  }
  else {
    $Dv->{STATUS_VALUE} = $html->color_mark($status, $color);
  }
  
  $index = get_function_index('dv_user_info');
  if ($index && $index =~ /sub(\d+)/){
    $index = $1;
  }

  if ($conf{DV_USER_CHG_TP}) {
    $Dv->{TP_CHANGE} = $html->button("$lang{CHANGE}", 'index=' . get_function_index('dv_user_chg_tp') . '&sid=' . $sid, { class => 'change rightAlignText' });
  }

  #Activate Cisco ISG Account
  if ($conf{DV_ISG}) {
    if ($user->{DISABLE}) {
      $html->message('err', $lang{ERROR}, "$lang{USER}  $lang{DISABLE}", { ID => 16 });
    }
    elsif ($Dv->{CID} ne $Isg->{ISG_CID_CUR} || $Dv->{CID} eq '') {
      $html->message('info', $lang{INFO}, "$lang{NOT_ACTIVE}\n\n CID: $Isg->{ISG_CID_CUR}\n IP: $user->{REMOTE_ADDR} ", { ID => 121  });
      $html->form_main(
        {
          CONTENT => '',
          HIDDEN  => {
            index => $index,
            CID   => $Isg->{ISG_CID_CUR},
            sid   => $sid
          },
          SUBMIT => { activate => "$lang{ACTIVATE}" }
        }
      );

      $Dv->{CID} = $Isg->{ISG_CID_CUR};
      $Dv->{IP}  = $user->{REMOTE_ADDR};
      $Dv->{CID} .= ' ' . $html->color_mark($lang{NOT_ACTIVE}, $_COLORS[6]);
    }

    #Self hangup
    elsif ($Dv->{CID} eq $Isg->{ISG_CID_CUR}) {
      my $table = $html->table(
        {
          width    => '600',
          rowcolor => 'row_active',
          rows     => [
            [
                ($Isg->{ISG_SESSION_DURATION}) ? "$lang{SESSIONS} $lang{DURATION}: " . sec2time($Isg->{ISG_SESSION_DURATION}, { str => 1 }) : '',
                ($Isg->{CURE_SERVICE} && $Isg->{CURE_SERVICE} !~ /TP/ && !$Isg->{TURBO_MODE_RUN}) ? $html->form_input('logon', "$lang{LOGON} ", { TYPE => 'submit', OUTPUT2RETURN => 1 }) : '',
              #$html->form_input('hangup', $lang{HANGUP}, { TYPE => 'submit', OUTPUT2RETURN => 1 })
            ]
          ],
        }
      );

      print $html->form_main(
        {
          CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
          HIDDEN  => {
            index => $index,
            CID   => $Isg->{ISG_CID_CUR},
            sid   => $sid
          },
        }
      );
    }
  }

  #Turbo mode Enable function
  if ($conf{DV_TURBO_MODE}) {
    dv_turbo_control($Dv);
  }

  if ($Dv->{IP} eq '0.0.0.0') {
    $Dv->{IP} = $lang{NO};
  }

  if ($conf{DV_USER_SERVICE_HOLDUP}) {
    $Dv->{HOLDUP_BTN} = dv_holdup_service($Dv);
  }

  if($Dv->{PERSONAL_TP} && $Dv->{PERSONAL_TP} != 0.00){
    $Dv->{MONTH_ABON} = $Dv->{PERSONAL_TP};
  }

  if($Dv->{REDUCTION_FEE} && $user->{REDUCTION} > 0) {
    if ($user->{REDUCTION} < 100) {
      $Dv->{DAY_ABON}   = sprintf('%.2f', $Dv->{DAY_ABON} * (100 - $user->{REDUCTION}) / 100) if ($Dv->{DAY_ABON} > 0);
      $Dv->{MONTH_ABON} = sprintf('%.2f', $Dv->{MONTH_ABON} * (100 - $user->{REDUCTION}) / 100) if($Dv->{MONTH_ABON} > 0);
    }
  }

  my $money_name = '';
  if (exists $conf{MONEY_UNIT_NAMES} && defined $conf{MONEY_UNIT_NAMES} && ref $conf{MONEY_UNIT_NAMES} eq 'ARRAY'){
    $money_name = $conf{MONEY_UNIT_NAMES}->[0] || '';
  }
  
  #Extra fields
  $Dv->{EXTRA_FIELDS} = '';
  my @check_fields = (
    "MONTH_ABON:0.00:\$_MONTH_FEE:$money_name",
    "DAY_ABON:0.00:\$_DAY_FEE:$money_name",
    "TP_ACTIVATE_PRICE:0.00:\$_ACTIVATE_TARIF_PLAN:$money_name",
    "DV_EXPIRE:0000-00-00:\$_EXPIRE",
    "TP_AGE:0:\$_AGE",
    #'ACTIVATE_CHANGE_PRICE:0.00:\$_ACTIVE',
    "IP:0.0.0.0:\$_STATIC IP",
    "CID::MAC",
  );

  foreach my $param ( @check_fields ) {
    my($id, $default_value, $lang_, $value_prefix )=split(/:/, $param);
    if(! defined($Dv->{$id}) || $Dv->{$id} eq $default_value) {
      next;
    }

    $Dv->{EXTRA_FIELDS} .= $html->tpl_show(templates('form_row_client'), {
      ID    => '$id',
      NAME  => _translate($lang_),
      VALUE => $Dv->{$id} . ( $value_prefix ? (' ' . $value_prefix) : '' ),
    }, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(_include('dv_user_info', 'Dv'), $Dv,
    {  ID => 'dv_user_info' });

  if($conf{DV_ALERT_REDIRECT_FILTER} && $conf{DV_ALERT_REDIRECT_FILTER} eq $Dv->{FILTER_ID}) {
    $Dv->change({
      UID       => $user->{UID},
      FILTER_ID => ''
    });
  }

  return 1;
}


#**********************************************************
=head2 dv_discovery($attr)

=cut
#**********************************************************
sub dv_discovery {
  my ($user_ip)=@_;

  $conf{DV_IP_DISCOVERY}=~s/[\r\n ]//g;
  my @dhcp_nets         = split(/;/, $conf{DV_IP_DISCOVERY});

  my $discovery_ip = 0;
  foreach my $nets (@dhcp_nets) {
    my (undef, $net_ips, undef) = split(/:/, $nets);
    if(check_ip($user_ip, $net_ips) ) {
      $discovery_ip = 1;
      last;
    }
  }

  if(! $discovery_ip) {
    return 1;
  }

  my $session_list = $Sessions->online(
    {
      CLIENT_IP => $user_ip,
      #USER_NAME => $user->{LOGIN},
      ACCT_SESSION_ID => '_SHOW',
      NAS_ID    => '_SHOW',
      GUEST     => '_SHOW'
    }
  );

  if ($Sessions->{TOTAL} < 1 || $session_list->[0]->{guest} ) {
    my $DHCP_INFO = dv_dhcp_get_mac($user_ip, { CHECK_STATIC => 1 });
    if (!$DHCP_INFO->{MAC}) {
      my $log_type = 'LOG_WARNING';
      my $error_id = 112;

      $html->message('err', $lang{ERROR}, "DHCP $lang{ERROR}\n MAC: $lang{NOT_EXIST}\n IP: '$user_ip'", { ID => 112 });
      $Log->log_print($log_type, $user->{LOGIN},
        show_hash($DHCP_INFO, { OUTPUT2RETURN => 1 }). (($error_id) ? "Error: $error_id" : ''),
        { ACTION => 'REG', NAS => { NAS_ID => $session_list->[0]->{nas_id} } });

      return 0;
    }
    elsif ($DHCP_INFO->{STATIC}) {
      if ($DHCP_INFO->{IP} ne $user_ip) {
        my $log_type = 'LOG_WARNING';
        my $error_id = 114;

        $html->message('err', $lang{ERROR}, "$lang{ERR_IP_ADDRESS_CONFLICT}\n MAC: $lang{NOT_EXIST}\n IP: '$user_ip' ", { ID => 114 });

        $Log->log_print($log_type, $user->{LOGIN},
          show_hash($DHCP_INFO, { OUTPUT2RETURN => 1 }). (($error_id) ? "Error: $error_id" : ''),
          { ACTION => 'REG', NAS => { NAS_ID => $session_list->[0]->{nas_id} } });
      }
    }
    else {
      if($FORM{discovery}) {
        if (dv_dhcp_get_mac_add($user_ip, $DHCP_INFO, { NAS_ID => $session_list->[0]->{nas_id} })) {
          $html->message('info', $lang{INFO}, "$lang{ACTIVATE}\n\n "
           . (($Dv->{NEW_IP} && $Dv->{NEW_IP} ne '0.0.0.0') ? "IP: $Dv->{NEW_IP}\n" : q{})
           .  "CID: $DHCP_INFO->{MAC}");

          if ($session_list->[0]->{acct_session_id}) {
            $Nas->info({ NAS_ID => $session_list->[0]->{nas_id} });
            $Sessions->online_info( { ACCT_SESSION_ID  => $session_list->[0]->{acct_session_id}, NAS_ID => $session_list->[0]->{nas_id} });

            #              END {
            require AXbills::Nas::Control;
            AXbills::Nas::Control->import();

            my $Nas_cmd = AXbills::Nas::Control->new($db, \%conf);
            sleep 1;
            $Nas_cmd->hangup($Nas, 0, '',
              {
                #DEBUG  => $FORM{DEBUG} || undef,
                %$Sessions
              }
            );
            #`echo "hangup" >> /tmp/hagup`;
            #              }
            #              if ($ret == 0) {
            #                $message = "$lang{NAS} ID:  $nas_id\n $lang{NAS} IP: $Nas->{NAS_IP}\n $lang{PORT}: $nas_port_id\n SESSION_ID: $acct_session_id\n\n  $ret";
            #                sleep 3;
            #                $admin->action_add($FORM{UID}, "$user_name", { MODULE => 'Dv', TYPE => 15 });
            #              }
          }
        }
      }

      if (! $Dv->{NEW_IP}) {
        $html->tpl_show(_include('dv_guest_mode', 'Dv'), {
          %$Dv,
          %$DHCP_INFO,
          IP => $user_ip,
          ID => 'dv_guest_mode'
        });
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 dv_user_chg_tp($attr)

=cut
#**********************************************************
sub dv_user_chg_tp {
  my ($attr) = @_;

  my $period = $FORM{period} || 0;

  if (!$conf{DV_USER_CHG_TP}) {
    $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", "$lang{NOT_ALLOW}", { ID => 140 });
    return 0;
  }

  if ($LIST_PARAMS{UID}) {
    $Dv = $Dv->info($LIST_PARAMS{UID}, { DOMAIN_ID => $user->{DOMAIN_ID} });
    if ($Dv->{TOTAL} < 1) {
      $html->message('info', $lang{INFO}, "$lang{NOT_ACTIVE}", { ID => 22 });
      return 0;
    }
  }
  else {
    $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST}, { ID => 19 });
    return 0;
  }

  if ($conf{FEES_PRIORITY} && $conf{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
    $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
  }
  my %CHANGE_PARAMS = ();

  if ($user->{GID}) {
    #Get user groups
    $user->group_info($user->{GID});
    if ($user->{DISABLE_CHG_TP}) {
      $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", "$lang{NOT_ALLOW}", { ID => 143 });
      return 0;
    }
  }

  #Get TP groups
  $Tariffs->tp_group_info($Dv->{TP_GID});
  if (!$Tariffs->{USER_CHG_TP}) {
    $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", "$lang{NOT_ALLOW}", { ID => 140 });
    return 0;
  }

  #Get next abon day
  if (
    $Dv->{MONTH_ABON} > 0
      && !$Dv->{STATUS}
      && !$user->{DISABLE}
      && ( $user->{DEPOSIT} + $user->{CREDIT} > 0
      || $Dv->{POSTPAID_ABON}
      || $Dv->{PAYMENT_TYPE} == 1)
  )
  {
    if ($user->{ACTIVATE} ne '0000-00-00') {
      my ($Y, $M, $D) = split(/-/, $user->{ACTIVATE}, 3);
      $M--;
      $Dv->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400 + (($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} * 86400 : 0))));
    }
    else {
      my ($Y, $M, $D) = split(/-/, $DATE, 3);

      if ($conf{START_PERIOD_DAY} && $conf{START_PERIOD_DAY} > $D) {
        $D = $conf{START_PERIOD_DAY};
      }
      else {
        $M++;
        $D = '01';
      }

      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      $Dv->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
    }
  }

  if ($FORM{set} && $FORM{ACCEPT_RULES}) {
    if (!$FORM{TP_ID} || $FORM{TP_ID} < 1) {
      $html->message('err', "$lang{ERROR}", "$lang{ERR_WRONG_DATA}: $lang{TARIF_PLAN}", { ID => 141 });
    }
    elsif ($conf{DV_USER_CHG_TP_NPERIOD}) {
      my ($CUR_Y, $CUR_M, $CUR_D) = split(/-/, $DATE);

      # Get next month
      my ($Y, $M, $D);
      if ($user->{ACTIVATE} eq '0000-00-00') {
        # Get next month
        ($Y, $M, $D) = split(/-/, $DATE, 3);
      }
      else {
        ($Y, $M, $D) = split(/-/, $user->{ACTIVATE}, 3);
      }

      # Renew expired accounts
      if ($user->{EXPIRE} ne '0000-00-00' && $Dv->{TP_AGE} > 0) {
        ($Y, $M, $D) = split(/-/, $user->{EXPIRE});
        my $seltime = POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900));
        my $tp_age = $Dv->{TP_INFO}->{AGE};
        # REnew expire tarif
        if ($seltime < time()) {
          my ($EXPIRE_Y, $EXPIRE_M, $EXPIRE_D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $CUR_D, ($CUR_M), ($CUR_Y - 1900), 0, 0, 0) + $tp_age * 86400))));
          $CHANGE_PARAMS{EXPIRE} = "$EXPIRE_Y-$EXPIRE_M-$EXPIRE_D";
          ($Y, $M, $D) = split(/-/, $DATE, 3);
          $Dv->{TP_INFO} = $Tariffs->info($FORM{TP_ID});
          goto CHG_TP;
        }
        else {
          ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M), ($Y - 1900), 0, 0, 0) + $tp_age * 86400))));
        }
      }

      if ($Dv->{STATUS} == 5) {

      }
      # For daily fees or moth distribution next day fees
      elsif (!$conf{DV_USER_CHG_TP_NEXT_MONTH} && ($Dv->{MONTH_ABON} == 0 || $Dv->{ABON_DISTRIBUTION})) {
        ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 86400))));
      }
      else {
        if ($user->{ACTIVATE} ne '0000-00-00') {
          ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 30 * 86400))));
        }
        else {
          if ($conf{START_PERIOD_DAY} && $conf{START_PERIOD_DAY} > $D) {
            $D = $conf{START_PERIOD_DAY};
          }
          else {
            $M++;
            if ($M == 13) {
              $M = 1;
              $Y++;
            }
            $D = '01';
          }
        }
      }

      CHG_TP:
      $M = sprintf("%02d", $M);
      $D = sprintf("%02d", $D);
      my $seltime = POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900));

      if ($seltime > time()) {
        $Shedule->add(
          {
            UID      => $LIST_PARAMS{UID},
            TYPE     => 'tp',
            ACTION   => $FORM{TP_ID},
            D        => $D,
            M        => $M,
            Y        => $Y,
            MODULE   => 'Dv',
            COMMENTS => "$lang{FROM}: $Dv->{TP_ID}:$Dv->{TP_NAME}"
          }
        );
      }
      else {
        $FORM{UID} = $LIST_PARAMS{UID};
        $FORM{STATUS} = 0 if ($Dv->{STATUS} == 5);
        $Dv->change({%FORM});
        $user->change(
          $LIST_PARAMS{UID},
          {
            ACTIVATE => ($user->{ACTIVATE} ne '0000-00-00') ? "$DATE" : undef,
            UID => $LIST_PARAMS{UID},
            %CHANGE_PARAMS
          }
        );

        if (! _error_show($user)) {
          $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
          $Dv->info($user->{UID});
          service_get_month_fee($Dv) if (!$FORM{DV_NO_ABON});
        }
      }
    }
    elsif ($period == 1 && $conf{DV_USER_CHG_TP_SHEDULE}) {
      my ($year, $month, $day) = split(/-/, $FORM{DATE}, 3);
      my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

      if ($seltime <= time()) {
        $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA}");
        return 0;
      }

      $Shedule->add(
        {
          UID      => $LIST_PARAMS{UID},
          TYPE     => 'tp',
          ACTION   => $FORM{TP_ID},
          D        => sprintf("%02d", $day),
          M        => sprintf("%02d", $month),
          Y        => $year,
          MODULE   => 'Dv',
          COMMENTS => "$lang{FROM}: $Dv->{TP_ID}:$Dv->{TP_NAME}"
        }
      );

      if (! _error_show($Shedule)) {
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
        $Dv->info($user->{UID});
      }
    }

    #Imidiatly change TP
    else {
      if ($user->{CREDIT} + $user->{DEPOSIT} < 0) {
        $html->message('err', "$lang{ERROR}", "$lang{ERR_SMALL_DEPOSIT} - $lang{DEPOSIT}: $user->{DEPOSIT} $lang{CREDIT}: $user->{CREDIT}", { ID => 15 });
        return 0;
      }

      $FORM{UID} = $LIST_PARAMS{UID};

      $Dv->{ABON_DATE} = undef;
      if ($Dv->{MONTH_ABON} > 0 && !$Dv->{STATUS} && !$user->{DISABLE}) {
        if ($user->{ACTIVATE} ne '0000-00-00') {
          my ($Y, $M, $D) = split(/-/, $user->{ACTIVATE}, 3);
          $M--;
          $Dv->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400 + (($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} * 86400 : 0))));
        }
        else {
          my ($Y, $M, $D) = split(/-/, $DATE, 3);
          $M++;
          if ($M == 13) {
            $M = 1;
            $Y++;
          }

          if ($conf{START_PERIOD_DAY}) {
            $D = sprintf("%02d", $conf{START_PERIOD_DAY});
          }
          else {
            $D = '01';
          }
          $Dv->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
        }
      }

      if ($Dv->{ABON_DATE}) {
        my ($year, $month, $day) = split(/-/, $Dv->{ABON_DATE}, 3);
        my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

        if ($seltime <= time()) {
          $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA} ($year, $month, $day)/" . $seltime . "-" . time());
          return 0;
        }
        elsif ($FORM{date_D} && $FORM{date_D} > ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 : (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28))) {
          $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA} ($year-$month-$day)");
          return 0;
        }

        $Shedule->add(
          {
            UID      => $LIST_PARAMS{UID},
            TYPE     => 'tp',
            ACTION   => $FORM{TP_ID},
            D        => $day,
            M        => $month,
            Y        => $year,
            MODULE   => 'Dv',
            COMMENTS => "$lang{FROM}: $Dv->{TP_ID}:$Dv->{TP_NAME}"
          }
        );

        if (! _error_show($Shedule->{errno})) {
          $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
        }
      }
      else {
        $Dv->change({%FORM});

        if (! _error_show($Dv)) {
          #Take fees
          if (!$Dv->{STATUS}) {
            service_get_month_fee($Dv) if (!$FORM{DV_NO_ABON});
            $user->change(
              $user->{UID},
              {
                ACTIVATE => "$DATE",
                UID      => $user->{UID}
              }
            );
          }

          $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
          $Dv->info($Dv->{UID});
        }
      }

      $Dv->info($Dv->{UID});
    }
  }
  elsif ($FORM{del}) {
    $Shedule->del(
      {
        UID => $LIST_PARAMS{UID} || '-',
        ID  => $FORM{SHEDULE_ID}
      }
    );

    $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]");
  }

  my $message='';
  my $date_ = ($FORM{date_y} || ''). '-' . ($FORM{date_m} || '') .'-'. ($FORM{date_d} || '');
  $Shedule->info(
    {
      UID      => $user->{UID},
      TYPE     => 'tp',
      DESCRIBE => "$message\n$lang{FROM}: '$date_'",
      MODULE   => 'Dv'
    }
  );

  my $table;
  if ($Shedule->{TOTAL} > 0) {
    $Tariffs->info(0, { ID => $Shedule->{ACTION}, MODULE => 'Dv' });

    $table = $html->table({
      width      => '100%',
      caption    => $lang{SHEDULE},
      rows       => [ [ "$lang{TARIF_PLAN}:", "$Shedule->{ACTION} : $Tariffs->{NAME}" ], [ "$lang{DATE}:", "$Shedule->{Y}-$Shedule->{M}-$Shedule->{D}" ], [ "$lang{ADDED}:", "$Shedule->{DATE}" ], [ "ID:", "$Shedule->{SHEDULE_ID}" ] ]
    });

    $Tariffs->{TARIF_PLAN_SEL} = $table->show({ OUTPUT2RETURN => 1 }) . $html->form_input('SHEDULE_ID', "$Shedule->{SHEDULE_ID}", { TYPE => 'HIDDEN', OUTPUT2RETURN => 1 });
    $Tariffs->{TARIF_PLAN_TABLE} = $Tariffs->{TARIF_PLAN_SEL};
    if (!$Shedule->{ADMIN_ACTION}) {
      $Tariffs->{ACTION}     = 'del';
      $Tariffs->{LNG_ACTION} = "$lang{DEL}  $lang{SHEDULE}";
      #$Tariffs->{ACTION_FLAG}= $html->form_input('del', "1", { TYPE => 'text', OUTPUT2RETURN => 1 });
    }
  }
  else {
    $Tariffs->{TARIF_PLAN_SEL} = $html->form_select(
      'TP_ID',
      {
        SELECTED   => $Dv->{TP_ID},
        SEL_LIST   => $Tariffs->list(
          {
            TP_GID       => $Dv->{TP_GID},
            CHANGE_PRICE => '<=' . ($user->{DEPOSIT} + $user->{CREDIT}),
            MODULE       => 'Dv',
            NEW_MODEL_TP => 1,
            TP_CHG_PRIORITY => $Dv->{TP_PRIORITY},
            COLS_NAME    => 1
          }
        ),
      }
    );

    $table = $html->table(
      {
        width      => '100%',
        caption    => $lang{TARIF_PLANS},
      }
    );

    my $tp_list = $Tariffs->list(
      {
        TP_GID       => $Dv->{TP_GID},
        CHANGE_PRICE => '<=' . ($user->{DEPOSIT} + $user->{CREDIT}),
        MODULE       => 'Dv',
        MONTH_FEE    => '_SHOW',
        DAY_FEE      => '_SHOW',
        CREDIT       => '_SHOW',
        COMMENTS     => '_SHOW',
        TP_CHG_PRIORITY => $Dv->{TP_PRIORITY},
        REDUCTION_FEE=> '_SHOW',
        NEW_MODEL_TP => 1,
        COLS_NAME    => 1,
        DOMAIN_ID    => $user->{DOMAIN_ID}
      }
    );

    my @skip_tp_changes = ();
    if ($conf{DV_SKIP_CHG_TPS}) {
      @skip_tp_changes = split(/,\s?/, $conf{DV_SKIP_CHG_TPS});
    }

    foreach my $tp (@$tp_list) {
      next if (in_array($tp->{id}, \@skip_tp_changes));
      next if ($tp->{id} == $Dv->{TP_ID} && $user->{EXPIRE} eq '0000-00-00');
      #   $table->{rowcolor} = ($table->{rowcolor} && $table->{rowcolor} eq $_COLORS[1]) ? $_COLORS[2] : $_COLORS[1];
      my $radio_but = '';

      my $tp_fee = $tp->{day_fee} + $tp->{month_fee};

      if($tp->{reduction_fee} && $user->{REDUCTION} && $user->{REDUCTION} > 0) {
        $tp_fee = $tp_fee - (($tp_fee / 100) *  $user->{REDUCTION});
      }

      $user->{CREDIT}=($user->{CREDIT}>0)? $user->{CREDIT}  : (($tp->{credit} > 0) ? $tp->{credit} : 0);

      if ($tp_fee < $user->{DEPOSIT} + $user->{CREDIT} || $tp->{abon_distribution}) {
        $radio_but = $html->form_input('TP_ID', "$tp->{id}", { TYPE => 'radio', OUTPUT2RETURN => 1 });
      }
      else {
        $radio_but = $conf{DV_USER_CHG_TP_SMALL_DEPOSIT} || $lang{ERR_SMALL_DEPOSIT};
      }

      $table->addrow($tp->{id}, $html->b($tp->{name}) . $html->br() . convert($tp->{comments}, { text2html => 1 }), $radio_but);
    }
    $Tariffs->{TARIF_PLAN_TABLE} = $table->show({ OUTPUT2RETURN => 1 });

    if ($Tariffs->{TOTAL} == 0) {
      $html->message('info', $lang{INFO}, $lang{ERR_SMALL_DEPOSIT}, { ID => 142 });
      return 0;
    }

    $Tariffs->{PARAMS} .= form_period($period, { ABON_DATE => $Dv->{ABON_DATE}, TP => $Tariffs }) if ($conf{DV_USER_CHG_TP_SHEDULE} && !$conf{DV_USER_CHG_TP_NPERIOD});
    $Tariffs->{ACTION} = 'set';
    $Tariffs->{LNG_ACTION} = $lang{CHANGE};
    #$html->form_input('hold_up_window', '--'.$lang{CHANGE}, { TYPE          => 'submit',
    #                                 OUTPUT2RETURN => 1 });
  }

  $Tariffs->{UID}     = $attr->{USER_INFO}->{UID};
  $Tariffs->{TP_ID}   = $Dv->{TP_ID};
  $Tariffs->{TP_NAME} = "$Dv->{TP_ID}:$Dv->{TP_NAME}";
  $html->tpl_show(templates('form_client_chg_tp'), $Tariffs);

  return 1;
}

#**********************************************************
=head2 form_stats($attr)

  Arguments:
    $attr
      UID

=cut
#**********************************************************
sub dv_user_stats {
  my ($attr) = @_;

  my %TRAFFIC_NAMES = ();

  my $uid = $LIST_PARAMS{UID} || $attr->{UID};
  if (defined($FORM{SESSION_ID})) {
    $pages_qs .= "&SESSION_ID=$FORM{SESSION_ID}";
    dv_session_detail({ LOGIN => $LIST_PARAMS{LOGIN} });
    return 0;
  }

  _error_show($Sessions);

  #Join Service
  if ($user->{COMPANY_ID}) {
    if ($FORM{COMPANY_ID}) {
      $users = Users->new($db, $admin, \%conf);
      dv_report_use();
      return 0;
    }

    require Customers;
    Customers->import();
    my $customer = Customers->new($db, $admin, \%conf);
    my $company  = $customer->company();
    my $ulist    = $company->admins_list(
      {
        COMPANY_ID => $user->{COMPANY_ID},
        UID        => $uid
      }
    );

    if ($company->{TOTAL} > 0 && $ulist->[0]->[0] > 0) {
      $Dv->{JOIN_SERVICES_USERS} = $html->button($lang{COMPANY}, "&sid=$sid&index=$index&COMPANY_ID=$user->{COMPANY_ID}", { BUTTON => 1 }) . ' ';
    }

    $Dv->info($uid);

    if ($Dv->{JOIN_SERVICE}) {
      my @uids = ();
      my $list = $Dv->list(
        {
          JOIN_SERVICE => ($Dv->{JOIN_SERVICE}==1) ? $uid : $Dv->{JOIN_SERVICE},
          COMPANY_ID   => $attr->{USER_INFO}->{COMPANY_ID},
          LOGIN        => '_SHOW',
          PAGE_ROWS    => 1000,
          COLS_NAME    => 1
        }
      );

      if ($Dv->{JOIN_SERVICE} == 1) {
        $Dv->{JOIN_SERVICES_USERS} .= (!$FORM{JOIN_STATS}) ? $html->b("$lang{ALL} $lang{USERS}") . ' :: '
                                                           : $html->button("$lang{ALL}", "&sid=$sid&index=$index&JOIN_STATS=" . $uid, { BUTTON => 1 }) . ' ';
      }
      #elsif ($Dv->{JOIN_SERVICE} > 1) {
      #  $Dv->{JOIN_SERVICES_USERS} .= $html->button("$lang{MAIN}", "index=$index&UID=$Dv->{JOIN_SERVICE}", { BUTTON => 1 });
      #}

      foreach my $line (@$list) {
        if ($FORM{JOIN_STATS} && $FORM{JOIN_STATS} == $line->{uid}) {
          $Dv->{JOIN_SERVICES_USERS} .= $html->b($line->{login}) . ' ';
          $uid = $FORM{JOIN_STATS};
        }
        elsif($Dv->{JOIN_SERVICE} == 1) {
          $Dv->{JOIN_SERVICES_USERS} .= $html->button($line->{login}, "&sid=$sid&index=$index&JOIN_STATS=" . $line->{uid}, { BUTTON => 1 }) . ' ';
        }

        push @uids, $line->{uid};
      }

      $LIST_PARAMS{UIDS}  = ($Dv->{JOIN_SERVICE} > 1) ? $Dv->{JOIN_SERVICE} : $uid;
      $LIST_PARAMS{UIDS} .= ',' . join(', ', @uids) if ($#uids > -1 && !$FORM{JOIN_STATS});
    }

    my $table = $html->table(
      {
        width => '100%',
        rows  => [ [ "$lang{JOIN_SERVICE}: ", $Dv->{JOIN_SERVICES_USERS} ] ]
      }
    );
    $Sessions->{JOIN_SERVICE_STATS} .= $table->show();
  }

  if ($FORM{rows}) {
    $LIST_PARAMS{PAGE_ROWS} = $FORM{rows};
    $LIST_PARAMS{PG}        = $FORM{pg};
    $LIST_PARAMS{FROM_DATE} = $FORM{FROM_DATE};
    $LIST_PARAMS{TO_DATE}   = $FORM{TO_DATE};
    $conf{list_max_recs}    = $FORM{rows} if($FORM{rows} && $FORM{rows} =~ /^\d+$/);
    $pages_qs .= "&rows=$conf{list_max_recs}";
  }

  #online sessions
  my $list = $Sessions->online(
    {
      CLIENT_IP          => '_SHOW',
      CID                => '_SHOW',
      DURATION_SEC2      => '_SHOW',
      ACCT_INPUT_OCTETS  => '_SHOW',
      ACCT_OUTPUT_OCTETS => '_SHOW',
      UID                => $user->{UID}
    }
  );

  if ($Sessions->{TOTAL} > 0) {
    my $table = $html->table(
      {
        caption     => 'Online',
        width       => '100%',
        title_plain => [ "IP", "CID", $lang{DURATION}, $lang{RECV}, $lang{SENT} ],
        ID          => 'ONLINE'
      }
    );

    foreach my $line (@$list) {
      $table->addrow($line->{client_ip},
        $line->{CID},
        sec2time_str($line->{duration_sec2}),
        int2byte($line->{acct_input_octets}),
        int2byte($line->{acct_output_octets})
      );
    }
    $Sessions->{ONLINE} = $table->show({ OUTPUT2RETURN => 1 });
  }

  #PEriods totals
  $Sessions->{PERIOD_STATS} = dv_stats_periods({ UID => $LIST_PARAMS{UID} });
  $Sessions->{PERIOD_SELECT}= dv_period_select({ UID => $LIST_PARAMS{UID} });

  $Dv->info($user->{UID});
  $Tariffs->ti_list({ TP_ID => $Dv->{TP_NUM} });
  if ($Tariffs->{TOTAL} > 0) {
    $list = $Tariffs->tt_list({ TI_ID => $Tariffs->{list}->[0]->[0], COLS_NAME => 1 });
    foreach my $line ( @$list ) {
      $TRAFFIC_NAMES{ $line->{id} } = $line->{descr};
    }
  }

  if (defined($FORM{show})) {
    $pages_qs .= "&show=1&FROM_DATE=$FORM{FROM_DATE}&TO_DATE=$FORM{TO_DATE}";
  }
  elsif (defined($FORM{PERIOD}) && $FORM{PERIOD}=~/^\d+$/) {
    $LIST_PARAMS{PERIOD} = $FORM{PERIOD};
    $pages_qs .= "&PERIOD=$FORM{PERIOD}";
  }

  #Show rest of prepaid traffic
  if (
    $Sessions->prepaid_rest({
      UID  => ($Dv->{JOIN_SERVICE} && $Dv->{JOIN_SERVICE} > 1) ? $Dv->{JOIN_SERVICE} : $LIST_PARAMS{UID},
      UIDS => $LIST_PARAMS{UIDS}
    })
  )
  {
    $list  = $Sessions->{INFO_LIST};
    my $table = $html->table(
      {
        caption     => "$lang{PREPAID}",
        width       => '100%',
        title_plain => [ "$lang{TRAFFIC} $lang{TYPE}", $lang{BEGIN}, $lang{END}, $lang{START}, "$lang{TOTAL} (MB)", "$lang{REST} (MB)", "$lang{OVERQUOTA} (MB)" ],
        ID          => 'DV_STATS_PREPAID'
      }
    );

    foreach my $line (@$list) {
      my $traffic_rest = ($conf{DV_INTERVAL_PREPAID}) ? $Sessions->{REST}->{ $line->{interval_id} }->{ $line->{traffic_class} }  :  $Sessions->{REST}->{ $line->{traffic_class} };

      $table->addrow(
        $line->{traffic_class} . ':' . (($TRAFFIC_NAMES{ $line->{traffic_class} }) ? $TRAFFIC_NAMES{ $line->{traffic_class} } : '').
          ($conf{DV_INTERVAL_PREPAID} ? "/ $line->{interval_id}" : '') ,
        $line->{interval_begin},
        $line->{interval_end},
        $line->{activate},
        $line->{prepaid},
          ($line->{prepaid} > 0 && $traffic_rest > 0) ? $traffic_rest      : 0,
          ($line->{prepaid} > 0 && $traffic_rest < 0) ? $html->color_mark(abs($traffic_rest), 'red') : 0,
      );
    }

    $Sessions->{PREPAID_INFO} = $table->show({ OUTPUT2RETURN => 1 });
  }

  $pages_qs .= "&DIMENSION=$FORM{DIMENSION}" if ($FORM{DIMENSION});

  #Session List
  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 2;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  $list  = $Sessions->list({
    %LIST_PARAMS,
    COLS_NAME => 1
  });

  my $table = $html->table(
    {
      caption     => $lang{SUM},
      width       => '100%',
      title_plain => [
        $lang{SESSIONS},
        $lang{DURATION},
        (($TRAFFIC_NAMES{0}) ? $TRAFFIC_NAMES{0} : $lang{TRAFFIC}) . " $lang{RECV}",
        (($TRAFFIC_NAMES{0}) ? $TRAFFIC_NAMES{0} : $lang{TRAFFIC}) . " $lang{SENT}",

        (($TRAFFIC_NAMES{0}) ? $TRAFFIC_NAMES{0} : $lang{TRAFFIC}) . " $lang{SUM}",

        (($TRAFFIC_NAMES{1}) ? $TRAFFIC_NAMES{1} : $lang{TRAFFIC}) . " $lang{RECV}",
        (($TRAFFIC_NAMES{1}) ? $TRAFFIC_NAMES{1} : $lang{TRAFFIC}) . " $lang{SENT}",

        (($TRAFFIC_NAMES{1}) ? $TRAFFIC_NAMES{1} : $lang{TRAFFIC}) . " $lang{SUM}",
        "$lang{SUM}"
      ],
      rows       => [
        [
          $Sessions->{TOTAL},
          sec2time_str($Sessions->{DURATION}),
          int2byte($Sessions->{TRAFFIC_OUT},                             { DIMENSION => $FORM{DIMENSION} }),
          int2byte($Sessions->{TRAFFIC_IN},                              { DIMENSION => $FORM{DIMENSION} }),

          int2byte(($Sessions->{TRAFFIC_OUT} || 0) + ($Sessions->{TRAFFIC_IN} || 0),   { DIMENSION => $FORM{DIMENSION} }),

          int2byte($Sessions->{TRAFFIC2_OUT},                            { DIMENSION => $FORM{DIMENSION} }),
          int2byte($Sessions->{TRAFFIC2_IN},                             { DIMENSION => $FORM{DIMENSION} }),

          int2byte(($Sessions->{TRAFFIC2_OUT} || 0) + ($Sessions->{TRAFFIC2_IN}  || 0), { DIMENSION => $FORM{DIMENSION} }),
          $Sessions->{SUM}
        ]
      ]
    }
  );

  $Sessions->{TOTALS_FULL} = $table->show({ OUTPUT2RETURN => 1 });
  
  if ( $LIST_PARAMS{UID} && (-f '../charts.cgi' || -f 'charts.cgi') ) {
    $Sessions->{GRAPHS} = dv_get_chart_iframe("UID=$LIST_PARAMS{UID}", '1,2');
  }

  $Sessions->{SESSIONS} = dv_sessions($list, $Sessions, { OUTPUT2RETURN => 1 }) if ($Sessions->{TOTAL} > 0);

  $html->tpl_show(_include('dv_user_stats', 'Dv'), $Sessions);

  return 1;
}

#**********************************************************
=head2 dv_dhcp_get_mac_add($ip, $DHCP_INFO, $attr) - Add discovery mac to Dhcphosts

  Arguments:
    $ip
    $DHCP_INFO
    $attr

    $conf{DV_IP_DISCOVERY}

  Returns:

=cut
#**********************************************************
sub dv_dhcp_get_mac_add {
  my ($ip, $DHCP_INFO, $attr) = @_;

  require Dhcphosts;
  Dhcphosts->import();
  my $Dhcphosts         = Dhcphosts->new($db, $admin, \%conf);

  $conf{DV_IP_DISCOVERY}=~s/[\r\n ]//g;
  my @dhcp_nets         = split(/;/, $conf{DV_IP_DISCOVERY});
  my $default_params    = "IP,MAC";
  load_module('Dhcphosts', $html);

  foreach my $nets (@dhcp_nets) {
    my %PARAMS_HASH = ();

    my ($net_id, $net_ips, $params) = split(/:/, $nets);
    $params                 = $default_params if (!$params);
    my @params_arr          = split(/,/, $params);

    foreach $params (@params_arr) {
      my ($param, $value)=split(/=/, $params);
      $PARAMS_HASH{$param} = $value || $DHCP_INFO->{$param};
    }

    my $start_ip           = '0.0.0.0';
    my $bit_mask           = 0;
    ($start_ip, $bit_mask) = split(/\//, $net_ips) if ($net_ips);
    my $mask               = 0b0000000000000000000000000000001;
    my $address_count      = sprintf("%d", $mask << (32 - $bit_mask));

    if (ip2int($ip) >= ip2int($start_ip) && ip2int($ip) <= ip2int($start_ip) + $address_count) {
      $PARAMS_HASH{IP} = dhcphosts_get_static_ip($net_id);

      if($PARAMS_HASH{IP} !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        if ($PARAMS_HASH{IP} == -1) {
          return 0;
        }
        elsif ($PARAMS_HASH{IP} == 0) {
          $PARAMS_HASH{IP} = '0.0.0.0';
        }
      }

      my $list = $Dhcphosts->hosts_list({
        NAS_ID    => $PARAMS_HASH{NAS_ID},
        UID       => $user->{UID},
        PORTS     => $PARAMS_HASH{PORTS},
        COLS_NAME => 1,
        PAGE_ROWS => 1
      });
      if ($Dhcphosts->{TOTAL} > 0) {
        $Dhcphosts->host_change(
          {
            %PARAMS_HASH,
            ID     => $list->[0]->{id},
            NETWORK=> $net_id,
            #MAC    => $PARAMS_HASH{MAC}
          }
        );
      }
      else {
        $Dhcphosts->host_add({
          NETWORK     => $net_id,
          HOSTNAME    => "$user->{LOGIN}_$net_id",
          UID         => $user->{UID},
          %PARAMS_HASH
        });
      }

      my $log_type = 'LOG_INFO';
      my $error_id = 0;
      if ($Dhcphosts->{errno}) {
        $log_type = 'LOG_WARNING';
        if ($Dhcphosts->{errno} == 7) {
          $html->message('err', $lang{ERROR} . ' ' . $lang{ACTIVATE},
            $html->b($lang{ERR_HOST_REGISTRED})
            . "\n $lang{RENEW_IP}\n\n MAC: '$DHCP_INFO->{MAC}'\n IP: '$DHCP_INFO->{IP}'\n HOST: '$user->{LOGIN}_$net_id'",
            { ID => 118 });
          $error_id = 118;
        }
        else {
          $html->message('err', $lang{ACTIVATE}, "$lang{ERROR}: DHCP add hosts error", { ID => 119 });
          $error_id = 119;
        }
      }
      else {
        dhcphosts_config({
          NETWORKS => $net_id,
          reconfig => 1,
          QUITE    => 1,
          %PARAMS_HASH
        });
        $Dv->{NEW_IP} = $PARAMS_HASH{IP};
      }

      $Log->log_print($log_type, $user->{LOGIN},
        show_hash(\%PARAMS_HASH, { OUTPUT2RETURN => 1 }). (($error_id) ? "Error: $error_id" : ''),
        { ACTION => 'REG', NAS => { NAS_ID => $attr->{NAS_ID} } });

      return ($log_type eq 'LOG_INFO') ? 1 : 0;
    }
  }

  $html->message('err', $lang{ACTIVATE}, "$lang{ERROR}: Can't find assign network IP: '$ip' ", { ID => 120 });

  return 0;
}

#**********************************************************
=head2 dv_dhcp_get_mac($ip, $attr) - Get MAC from dhcp leaseds

IP discovery function

  Arguments:
    $ip     - User IP
    $attr   - Extra attributes
      CHECK_STATIC - Check static IP in dhcphosts

  Returns:
    Hash_ref
      IP
      MAC
      NAS_ID
      PORTS
      VLAN

=cut
#**********************************************************
sub dv_dhcp_get_mac {
  my ($ip, $attr) = @_;

  require Dhcphosts;
  Dhcphosts->import();
  my $Dhcphosts = Dhcphosts->new($db, $admin, \%conf);

  $Dhcphosts->host_info(0, { IP => $ip });
  #my $MAC    = '';
  my %PARAMS = ();

  if ($Dhcphosts->{TOTAL} > 0) {
    %PARAMS = (
      IP     => $Dhcphosts->{IP},
      MAC    => $Dhcphosts->{MAC},
      NAS_ID => $Dhcphosts->{NAS_ID},
      PORTS  => $Dhcphosts->{PORTS},
      VID    => $Dhcphosts->{VID},
      UID    => $Dhcphosts->{UID},
      SERVER_VID => $Dhcphosts->{SERVER_VID}
    );

    if ($attr->{CHECK_STATIC}) {
      $PARAMS{STATIC} = 1;
    }
    if ($PARAMS{MAC} ne '00:00:00:00:00:00') {
      return \%PARAMS;
    }
  }

  #Get mac from DB
  if ($conf{DHCPHOSTS_LEASES} && $conf{DHCPHOSTS_LEASES} eq 'db') {
    my $list = $Dhcphosts->leases_list({
      IP          => $ip,
      VLAN        => '_SHOW',
      SERVER_VLAN => '_SHOW',
      UID         => '_SHOW',
      STATE       => 2,
      COLS_NAME   => 1,
      COLS_UPPER  => 1
    });

    if ($Dhcphosts->{TOTAL} > 0) {
      %PARAMS        = %{ $list->[0] };
      $PARAMS{MAC}   = _mac_former($list->[0]->{HARDWARE});
      $PARAMS{PORTS} = $list->[0]->{PORT};
      $PARAMS{VID}   = $list->[0]->{VLAN};
      $PARAMS{UID}   = $list->[0]->{UID};
      $PARAMS{IP}    = int2ip($list->[0]->{IP});
      $PARAMS{SERVER_VID} = $list->[0]->{SERVER_VLAN};
    }

    load_module('Dhcphosts', $html);
    $PARAMS{CUR_IP}=$ip;
    if (defined($PARAMS{NAS_ID}) && $PARAMS{NAS_ID} == 0 && $PARAMS{CIRCUIT_ID} ) {
      ($PARAMS{NAS_ID}, $PARAMS{PORTS}, $PARAMS{VLAN}, $PARAMS{NAS_MAC})=dhcphosts_o82_info({ %PARAMS });
    }

    return \%PARAMS;
  }

  #Get mac from leases file
  else {
    my $logfile = $conf{DHCPHOSTS_LEASES} || '/var/db/dhcpd/dhcpd.leases';
    my %list    = ();
    my $l_ip    = '';

    if(open(my $fh, '<', $logfile)) {
      while (<$fh>) {
        next if /^#|^$/;

        if (/^lease (\d+\.\d+\.\d+\.\d+)/) {
          $l_ip = $1;
          $list{$ip}{ip} = sprintf("%-17s", $ip);
        }
        elsif (/^\s*hardware ethernet (.*);/) {
          my $mac = $1;
          if ($ip eq $l_ip) {
            $list{$ip}{hardware} = sprintf("%s", $mac);
            if ($list{$ip}{active}) {
              $PARAMS{MAC} = $list{$ip}{hardware};
              return \%PARAMS;
            }
          }
        }
        elsif (/^\s+binding state active/) {
          $list{$ip}{active} = 1;
        }
      }
      close($fh);
    }
    else {
      $html->message('err', $lang{ERROR}, "Can't read file '$logfile' $!")
    }
    $PARAMS{MAC} = ($list{$ip} && $list{$ip}{hardware}) ? $list{$ip}{hardware} : '';
  }

  $PARAMS{CUR_IP}=$ip;
  return \%PARAMS;
}

#**********************************************************
=head2 dv_holdup_service($attr)

=cut
#**********************************************************
sub dv_holdup_service {
  #my ($attr) = @_;

  my ($hold_up_min_period, $hold_up_max_period, $hold_up_period, $hold_up_day_fee,
    undef, $active_fees, $holdup_skip_gids) = split(/:/, $conf{DV_USER_SERVICE_HOLDUP});

  if ($holdup_skip_gids) {
    my @holdup_skip_gids_arr = split(/,\s?/, $holdup_skip_gids);
    if (in_array($user->{GID}, \@holdup_skip_gids_arr)) {
      return '';
    }
  }

  if ($hold_up_day_fee && $hold_up_day_fee > 0) {
    $Dv->{DAY_FEES}="$lang{DAY_FEE}: ". sprintf("%.2f", $hold_up_day_fee);
  }

  if ($FORM{del}) {
    $Shedule->del(
      {
        UID => $user->{UID},
        IDS => $FORM{del},
      }
    );

    $Dv->{STATUS_DAYS}=1;

    if ( $user->{DV_STATUS} == 3) {
      $Dv->change(
        {
          UID    => $user->{UID},
          STATUS => 0,
        }
      );

      service_get_month_fee($Dv, { QUITE => 1 });
      $html->message('info', $lang{SERVICE}, "$lang{ACTIVATE}");
      return '';
    }
    elsif($conf{DV_HOLDUP_COMPENSATE}) {
      $Dv->{TP_INFO} = $Tariffs->info(0, { ID => $Dv->{TP_ID} });
      service_get_month_fee($Dv, { QUITE => 1 });
    }

    $html->message('info', $lang{HOLD_UP}, "$lang{DELETED}");
  }

  my $list = $Shedule->list(
    {
      UID    => $user->{UID},
      MODULE => 'Dv',
      TYPE   => 'status',
      COLS_NAME=>1
    }
  );

  my %Shedule_val = ();
  my @del_arr     = ();

  foreach my $line (@$list) {
    $Shedule_val{ $line->{action} } = ($line->{y} || '*') .'-'. ($line->{m} || '*') .'-'. ($line->{d} || '*');
    push @del_arr, $line->{id};
  }

  my $del_ids = join(', ', @del_arr);

  if ($Shedule->{TOTAL}) {
    $html->message('info', $lang{INFO}, "$lang{HOLD_UP} ". ($Shedule_val{3} || '-') ." $lang{TO} ". ($Shedule_val{0} || '-') .
        (($Shedule->{TOTAL} > 1) ? $html->br() . $html->button($lang{DEL}, "index=$index&del=$del_ids". (($sid) ? "&sid=$sid" : q{}), { class => 'btn btn-primary', MESSAGE => "$lang{DEL} $lang{HOLD_UP}?" }) : ''));
    return '';
  }

  if ($FORM{add} && $FORM{ACCEPT_RULES}) {
    my ($from_year, $from_month, $from_day) = split(/-/, $FORM{FROM_DATE}, 3);
    my ($to_year,   $to_month,   $to_day)   = split(/-/, $FORM{TO_DATE},   3);
    my $block_days = date_diff($FORM{FROM_DATE}, $FORM{TO_DATE});

    if ($block_days < $hold_up_min_period) {
      $html->message('err', "$lang{ERR_WRONG_DATA}", "$lang{MIN} $lang{HOLD_UP}   $hold_up_min_period $lang{DAYS}");
    }
    elsif ($block_days > $hold_up_max_period) {
      $html->message('err', "$lang{ERR_WRONG_DATA}", "$lang{MAX} $lang{HOLD_UP}   $hold_up_max_period $lang{DAYS}");
    }
    elsif (date_diff($DATE, $FORM{FROM_DATE}) < 1) {
      $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA}\n $lang{FROM}: $FORM{FROM_DATE}");
    }
    elsif ($block_days < 1) {
      $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA}\n $lang{TO}: $FORM{TO_DATE}");
    }
    else {
      $Shedule->add(
        {
          UID    => $user->{UID},
          TYPE   => 'status',
          ACTION => '3',
          D      => $from_day,
          M      => $from_month,
          Y      => $from_year,
          MODULE => 'Dv'
        }
      );

      $Shedule->add(
        {
          UID    => $user->{UID},
          TYPE   => 'status',
          ACTION => '0',
          D      => $to_day,
          M      => $to_month,
          Y      => $to_year,
          MODULE => 'Dv'
        }
      );

      if (!_error_show($Shedule)) {
        #compensate period
        if ($conf{DV_HOLDUP_COMPENSATE}) {
          dv_compensation({ QUITE => 1, HOLD_UP => 1 });
        }

        if($active_fees) {
          $Fees->take($user, $active_fees, { DESCRIBE => $lang{HOLD_UP} });
        }

        $html->message('info', $lang{INFO}, "$lang{HOLD_UP}\n $lang{DATE}: $FORM{FROM_DATE} -> $FORM{TO_DATE}\n  $lang{DAYS}: " . sprintf("%d", $block_days));
        return '';
      }
    }
  }

  if ($hold_up_period) {
    $admin->action_list(
      {
        UID       => $user->{UID},
        TYPE      => 14,
        FROM_DATE => POSIX::strftime("%Y-%m-%d", localtime(time - 86400 * $hold_up_period)),
        TO_DATE   => "$DATE",
      }
    );

    if ($admin->{TOTAL} > 0) {
      return '';
    }
  }

  if (($user->{DV_STATUS} && $user->{DV_STATUS} == 3) || $user->{DISABLE}) {
    $html->message('info', $lang{INFO}, "$lang{HOLD_UP}\n " . $html->button("$lang{ACTIVATE}", "index=$index&del=1&sid=$sid", { BUTTON => 1, MESSAGE => "$lang{ACTIVATE}?" }) );
    return '';
  }

  $Dv->{DATE_FROM} = $html->date_fld2(
    'FROM_DATE',
    {
      FORM_NAME => 'holdup',
      WEEK_DAYS => \@WEEKDAYS,
      MONTHES   => \@MONTHES,
      NEXT_DAY  => 1
    }
  );

  $Dv->{DATE_TO} = $html->date_fld2(
    'TO_DATE',
    {
      FORM_NAME => 'holdup',
      WEEK_DAYS => \@WEEKDAYS,
      MONTHES   => \@MONTHES,
    }
  );

  return (! $user->{DV_STATUS}) ? $html->tpl_show(_include('dv_hold_up', 'Dv'), $Dv, { OUTPUT2RETURN => 1 }) : q{};
}


#**********************************************************
=head2 dv_turbo_control($attr)

=cut
#**********************************************************
sub dv_turbo_control {
  my Dv $Dv_ = shift;

  if($Dv_->{TURBO_MODE}) {
    return 1;
  }

  my (@turbo_mods) = split(/;/, $conf{DV_TURBO_MODE});
  my @turbo_mods_full = ();

  my $i = 1;
  my ($speed, $time, $price, $name, $bonus);

  foreach my $line (@turbo_mods) {
    ($speed, $time, $price, $name, $bonus) = split(/:/, $line, 5);

    if ($bonus && ! $Dv->{FREE_TURBO_MODE} ) {
      next;
    }

    push @turbo_mods_full, sprintf("$name\n $lang{SPEED}: $speed\n $lang{TIME}: %s\n $lang{PRICE}: %.2f %s", sec2time($time, { format => 1 }), $price, (($bonus) ? "($lang{BONUS})" : ''));
    if ($FORM{SPEED} && $FORM{SPEED} == $i) {
      $FORM{MODE_ID} = $i - 1;
      $FORM{SPEED}   = $speed;
      $FORM{TIME}    = $time;
      last;
    }
    $i++;
  }

  if (form_purchase_module({
    HEADER           => $user->{UID},
    MODULE           => 'Turbo',
    REQUIRE_VERSION  => 2.20
  })) {
    return 0;
  }

  my $Turbo = Turbo->new($db, $admin, \%conf);
  my $list = $Turbo->list(
    {
      UID    => $LIST_PARAMS{UID},
      ACTIVE => 1,
    }
  );

  if ($Turbo->{TOTAL} > 0 || $Dv_->{TURBO_MODE_RUN}) {
    my $last = $list->[0]->[2] || $Dv_->{TURBO_MODE_RUN};
    $html->message('info', $lang{INFO}, $html->b("$turbo_mods_full[$list->[0]->[1]]") . "\n$lang{REMAIN} $lang{TIME}: $last sec.");
  }
  elsif ($FORM{change} && $FORM{SPEED}) {
    if ($user->{DEPOSIT} + $user->{CREDIT} > $price) {
      $Turbo->add(
        {
          UID        => $LIST_PARAMS{UID},
          MODE_ID    => $FORM{MODE_ID},
          SPEED      => int($FORM{SPEED}),
          SPEED_TYPE => 0,
          TIME       => $FORM{TIME},
        }
      );

      if (_error_show($Turbo, { SILENT_MODE => 1 })) {
        return 0;
      }

      if ($price > 0) {
        $Fees->take($user, $price, { DESCRIBE => "Turbo mode: $Turbo->{INSERT_ID}" });
      }

      if ($bonus) {
        if ($Dv_->{FREE_TURBO_MODE} < 1) {
          $html->message('err', "$lang{ERROR}", "$lang{BONUS} Turbo $lang{EXPIRE}");
          return 0;
        }
        else {
          $Dv_->change({
            UID             => $user->{UID},
            FREE_TURBO_MODE => ($Dv_->{FREE_TURBO_MODE}-1)
          });
        }
      }

      my $ip = $ENV{REMOTE_ADDR};

      if($conf{DV_TURBO_STATIC_IP}) {
        if(in_array('Dhcphosts', \@MODULES)) {
          require Dhcphosts;
          Dhcphosts->import();
          my $Dhcphosts = Dhcphosts->new($db, $admin, \%conf);

          my $dhcp_list = $Dhcphosts->hosts_list({
            UID       => $Dv_->{UID},
            IP        => '_SHOW',
            PAGE_ROWS => 1,
            COLS_NAME => 1
          });

          if($Dhcphosts->{TOTAL}) {
            $ip = $dhcp_list->[0]->{ip};
          }
        }

        if ($Dv_->{IP} && $Dv_->{IP} ne '0.0.0.0') {
          $ip = $Dv_->{IP};
        }
      }

      if ($conf{DV_TURBO_CMD}) {
        cmd($conf{DV_TURBO_CMD}, {
            PARAMS => { %$user,
              DEBUG  => $conf{DV_TURBO_CMD_DEBUG},
              IP     => $ip
            } });
      }

      $html->message('info', $lang{INFO}, $html->b("$turbo_mods_full[$FORM{MODE_ID}]") . "\n$lang{REMAIN} $lang{TIME}: $FORM{TIME} sec.");
    }
    else {
      $html->message('err', "$lang{ERROR}:Turbo", "$lang{ERR_SMALL_DEPOSIT}");
    }
  }
  else {
    $Dv_->{SPEED_SEL} = $html->form_select(
      'SPEED',
      {
        SELECTED     => $FORM{SPEED},
        SEL_ARRAY    => \@turbo_mods_full,
        SEL_OPTIONS  => { '' => '--' },
        ARRAY_NUM_ID => 1
      }
    );

    $html->tpl_show(_include('dv_user_speed', 'Dv'), $Dv);
  }

  return 1;
}

1;