=head2 NAME

  Internet+ User portal

=cut

use warnings;
use strict;
use AXbills::Base qw(sec2time in_array convert int2byte ip2int int2ip date_diff show_hash date_inc next_month check_ip);
use AXbills::Filters qw(_mac_former $MAC);

require Internet::Stats;
require Control::Service_control;

our (
  $db,
  $admin,
  %conf,
  %lang,
  @WEEKDAYS,
  @MONTHES
);

our Users $user;
our AXbills::HTML $html;

my $Internet = Internet->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Sessions = Internet::Sessions->new($db, $admin, \%conf);
my $Nas      = Nas->new($db, \%conf, $admin);
my $Shedule  = Shedule->new($db, $admin, \%conf);
my $Log      = Log->new($db, \%conf);
my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

#**********************************************************
=head2 internet_user_info()

=cut
#**********************************************************
sub internet_user_info {
  my $uid = $LIST_PARAMS{UID};

  if (!$FORM{ID}) {
    my $list = $Internet->user_list({
      GROUP_BY  => 'internet.id',
      UID       => $uid,
      DOMAIN_ID => $user->{DOMAIN_ID},
      COLS_NAME => 1,
    });

    if ($Internet->{TOTAL_SERVICES} > 1) {
      foreach my $line (@$list) {
        $FORM{ID} = $line->{id};
        $Internet->{PAYMENT_MESSAGE} = '';
        $Internet->{NEXT_FEES_WARNING} = '';
        $Internet->{TP_CHANGE_WARNING} = '';
        $Internet->{SERVICE_EXPIRE_DATE} = '';
        internet_user_info_proceed({ ID => $line->{id}, UID => $uid });
      }
      return 1;
    }
  }

  internet_user_info_proceed({ UID => $uid,  ID => $FORM{ID} });

  return 1;
}

#**********************************************************
=head2 internet_user_info_proceed($attr)

  Arguments:
    $attr
      UID
      ID

  Return:

=cut
#**********************************************************
sub internet_user_info_proceed {
  my ($attr) = @_;

  my $service_id = $attr->{ID} || 0;
  my $uid = $attr->{UID} || $LIST_PARAMS{UID} || 0;

  my $service_status = sel_status({ HASH_RESULT => 1 });
  our $Isg;
  if ($conf{INTERNET_ISG}) {
    require Internet::Cisco_isg;

    $Nas->list({
      NAS_TYPE  => 'cisco_isg',
      PAGE_ROWS => 10000,
      LIST2HASH => 'nas_id,nas_name'
    });

    my $nas_list = $Nas->{list_hash};
    #Check deposit and disable STATUS
    my $list = $Internet->user_list({
      LOGIN          => $user->{LOGIN},
      CREDIT         => '_SHOW',
      DEPOSIT        => '_SHOW',
      INTERNET_STATUS=> '_SHOW',
      TP_NAME        => '_SHOW',
      ONLINE_NAS_ID  => join(';', keys %$nas_list),
      PAYMENTS_TYPE  => 0,
      COLS_NAME      => 1
    });

    if ($Internet->{TOTAL} < 1) {

    }
    elsif (($list->[0]->{credit} > 0 && ($list->[0]->{deposit} + $list->[0]->{credit} < 0))
      || ($list->[0]->{credit} == 0 && $list->[0]->{deposit} + $list->[0]->{credit}) < 0)
    {
      form_neg_deposit($user);
      return 0;
    }
    elsif ($list->[0]->{internet_status} && $list->[0]->{internet_status} == 1) {
      $html->message('err', $lang{ERROR}, "$lang{SERVICES} '$list->[0]->{tp_name}' $lang{DISABLE}", { ID => 15 });
      return 0;
    }

    if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "account-status-query", { USER_NAME => $user->{LOGIN}, NAS_ID => $list->[0]->{online_nas_id} })) {
      return 0;
    }

    if ($Isg->{ISG_CID_CUR}) {
      #change speed (active turbo mode)
      if ($FORM{SPEED}) {
        if ($Isg->{CURE_SERVICE} =~ /TP/ || !$Isg->{TURBO_MODE_RUN}) {
          my $service_name = 'TURBO_SPEED' . $FORM{SPEED};

          #Deactive cure service (TP Service)
          if ($Isg->{CURE_SERVICE} =~ /TP/) {
            if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "deactivate-service", {
                USER_NAME    => $user->{LOGIN},
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
  elsif ($conf{INTERNET_IP_DISCOVERY} || $FORM{DISCOVERY_MAC}) {
    if(! internet_discovery($user->{REMOTE_ADDR}, { %FORM, UID => $uid, ID => $service_id })) {
      return 0;
    }
  }

  $Internet->user_info($uid, {
    ID        => $service_id,
    DOMAIN_ID => $user->{DOMAIN_ID}
  });

  if ($FORM{activate}) {
    #TODO: Create normal fix if present activate param in FORM activating in any status
    return 0 unless ($Internet->{STATUS} && ($Internet->{STATUS} == 2 || $Internet->{STATUS} == 5));
    $Internet->user_change({
      UID      => $uid,
      ID       => $service_id,
      STATUS   => 0,
      CID      => ($Isg->{ISG_CID_CUR}) ? $Isg->{ISG_CID_CUR} : undef,
      ACTIVATE => ($conf{INTERNET_USER_ACTIVATE_DATE}) ? $DATE : undef
    });

    if (!$Internet->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ACTIVATE} CID: $Isg->{ISG_CID_CUR}") if ($Isg->{ISG_CID_CUR});
      if (!$Internet->{STATUS}) {
        service_get_month_fee($Internet, { USER_INFO => $user });
      }
    }
    else {
      $html->message('err', $lang{ACTIVATE}, "$lang{ERROR} CID: $Isg->{ISG_CID_CUR}", { ID => 102 });
    }

    #Log on
    if($conf{INTERNET_ISG}) {
      if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "account-logoff",
        { USER_NAME => $user->{LOGIN} })) {
        return 0;
      }
    }
  }
  elsif ($FORM{logon}) {
    #Logon
    if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "account-logoff",
      { USER_NAME => $user->{LOGIN} })) {
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

  $user->{INTERNET_STATUS} = $Internet->{STATUS};

  if ($Internet->{TOTAL} < 1) {
    $html->message('info', "Internet $lang{SERVICE}", $lang{NOT_ACTIVE}, { ID => 17 });
    return 0;
  }

  my $warning_info = $Service_control->service_warning({
    MODULE       => 'Internet',
    DATE         => $DATE,
    SERVICE_INFO => $Internet,
    USER_INFO    => $user,
    USER_PORTAL  => 1
  });

  if (defined $warning_info->{WARNING}) {
    $Internet->{NEXT_FEES_WARNING} = $warning_info->{WARNING};
    $Internet->{NEXT_FEES_MESSAGE_TYPE} = $warning_info->{MESSAGE_TYPE};
  }

  if ($Internet->{NEXT_FEES_WARNING}) {
    $Internet->{NEXT_FEES_WARNING} = $html->message("$Internet->{NEXT_FEES_MESSAGE_TYPE}",
      $Internet->{TP_NAME},
      $Internet->{NEXT_FEES_WARNING},
      { OUTPUT2RETURN => 1 }
    );
  }

  internet_payment_message($Internet, $user, { NO_PAYMENT_BTN => 1 });

  # Check for sheduled tp change
  my $sheduled_tp_actions_list = $Shedule->list({
    SERVICE_ID => $service_id,
    UID        => $user->{UID},
    TYPE       => 'tp',
    MODULE     => 'Internet',
    COLS_NAME  => 1
  });

  if ($Shedule->{TOTAL} && $Shedule->{TOTAL} > 0){
    my $next_tp_action = $sheduled_tp_actions_list->[0];
    my $next_tp_date   = "$next_tp_action->{y}-$next_tp_action->{m}-$next_tp_action->{d}";

    my $next_tp_id = $next_tp_action->{action};
    $service_id = 0;
    if ($next_tp_id =~ /:/) {
      ($service_id, $next_tp_id) = split(/:/, $next_tp_id);
    }

    # Get info about next TP
    my $tp_list = $Tariffs->list({
      INNER_TP_ID => $next_tp_id,
      NAME        => '_SHOW',
      COLS_NAME   => 1
    });

    if ($Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0){
      my $next_tp_name = $tp_list->[0]{name};
      $Internet->{TP_CHANGE_WARNING} = $html->message("info", $lang{TP_CHANGE_SHEDULED}." ($next_tp_date)", $next_tp_name, { OUTPUT2RETURN => 1 });
    }
  }

  my ($status, $color) = split(/:/, $service_status->{ $Internet->{STATUS} });
  $user->{SERVICE_STATUS} = $Internet->{STATUS};

  if ($Internet->{STATUS} == 2) {
    $Internet->{STATUS_VALUE} = $status;
    $Internet->{STATUS_FIELD} = 'text-warning';
    $Internet->{STATUS_BTN} = ($user->{DISABLE} > 0) ? $html->b("($lang{ACCOUNT} $lang{DISABLE})")
                                                  : $html->button($lang{ACTIVATE}, "&index=$index&sid=$sid&activate=1", { ID=>'ACTIVATE', class=> 'btn btn-sm btn-success float-right' });
  }
  elsif ($Internet->{STATUS} == 5) {
    $Internet->{STATUS_VALUE} = $status;
    $Internet->{STATUS_FIELD} = 'text-danger';

    if ($Internet->{MONTH_ABON} && $user->{DEPOSIT} && $Internet->{MONTH_ABON} <= $user->{DEPOSIT}) {
      $Internet->{STATUS_BTN} = ($user->{DISABLE} > 0) ? $html->b("($lang{ACCOUNT} $lang{DISABLE})")
                                                    : $html->button($lang{ACTIVATE}, "&index=$index&sid=$sid&activate=1", { ex_params => ' ID="ACTIVATE"', class=> 'btn btn-sm btn-success float-right' });
    }
    else {
      if ($functions{$index} && $functions{$index} eq 'internet_user_info') {
        form_neg_deposit($user);
      }
    }
  }
  else {
    $Internet->{STATUS_VALUE} = $status;
    $Internet->{STATUS_FIELD} = 'text-success';
  }

  $index = get_function_index('internet_user_info');
  if ($index && $index =~ /sub(\d+)/){
    $index = $1;
  }

  if ($conf{INTERNET_USER_CHG_TP}) {
    $Internet->{TP_CHANGE} = $html->button($lang{CHANGE},
      'index=' . get_function_index('internet_user_chg_tp')
        . '&ID=' . $Internet->{ID}
        . '&sid=' . $sid, { class => 'float-right', ICON => 'fa fa-pencil-alt' });

  }

  #Activate Cisco ISG Account
  if ($conf{INTERNET_ISG}) {
    internet_isg($Internet)
  }

  #Turbo mode Enable function
  if ($conf{INTERNET_TURBO_MODE}) {
    eval { require Internet::Turbo_mode; };
    if (! $@) {
      internet_turbo_control($Internet);
    }
  }

  internet_service_info($Internet);

  if($conf{INTERNET_ALERT_REDIRECT_FILTER} && $conf{INTERNET_ALERT_REDIRECT_FILTER} eq $Internet->{FILTER_ID}) {
    $Internet->user_change({
      UID       => $user->{UID},
      FILTER_ID => ''
    });
  }

  internet_filters_control($Internet);

  return 1;
}


#**********************************************************
=head2 internet_isg($Service)

  Arguments:
    $Service

  Returns:


=cut
#**********************************************************
sub internet_isg {
  my ($Service) = @_;

  my Internet $Internet_ = $Service;
  our $Isg;
  if ($user->{DISABLE}) {
    $html->message('err', $lang{ERROR}, "$lang{USER}  $lang{DISABLE}", { ID => 16 });
  }
  elsif ($Internet_->{CID} ne $Isg->{ISG_CID_CUR} || ! $Internet_->{CID}) {
    $html->message('info', $lang{INFO}, "$lang{NOT_ACTIVE}\n\n CID: ". ($Isg->{ISG_CID_CUR} || q{n/d})
      ."\n IP: $user->{REMOTE_ADDR} ", { ID => 121  });

    $html->form_main(
      {
        CONTENT => '',
        HIDDEN  => {
          index => $index,
          CID   => $Isg->{ISG_CID_CUR},
          sid   => $sid
        },
        SUBMIT => { activate => $lang{ACTIVATE} }
      }
    );

    $Internet_->{CID} = $Isg->{ISG_CID_CUR};
    $Internet_->{IP}  = $user->{REMOTE_ADDR};
    $Internet_->{CID} .= ' ' . $html->color_mark($lang{NOT_ACTIVE}, $_COLORS[6]);
  }

  #Self hangup
  elsif ($Internet_->{CID} eq $Isg->{ISG_CID_CUR}) {
    my $table = $html->table(
      {
        width    => '600',
        rows     => [
          [
              ($Isg->{ISG_SESSION_DURATION}) ? "$lang{SESSIONS} $lang{DURATION}: " . sec2time($Isg->{ISG_SESSION_DURATION}, { str => 1 }) : '',
              ($Isg->{CURE_SERVICE} && $Isg->{CURE_SERVICE} !~ /TP/ && !$Isg->{TURBO_MODE_RUN}) ? $html->form_input('logon', "$lang{LOGON} ", { TYPE => 'submit', OUTPUT2RETURN => 1 }) : '',
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

  return 1;
}

#**********************************************************
=head2 internet_service_info($Service)

=cut
#**********************************************************
sub internet_service_info {
  my ($Service) = @_;
  
## START КТК-39 ###  
  my ($attr) = @_;

  my $uid = $FORM{UID} || $LIST_PARAMS{UID} || 0;
  my Internet $Internet_ = $Service;

  delete($Internet->{errno});


if ($conf{INTERNET_USER_SERVICE_HOLDUP}) {
## START КТК-39 ###
    $Internet_->{HOLDUP_BTN} = internet_holdup_service($Internet);
  }

  if ($Internet_->{IP} eq '0.0.0.0') {
    $Internet_->{IP} = $lang{NO};
  }

  if($Internet_->{PERSONAL_TP} && $Internet_->{PERSONAL_TP} != 0.00){
    $Internet_->{MONTH_ABON} = $Internet_->{PERSONAL_TP};
  }

  if($Internet_->{REDUCTION_FEE} && $user->{REDUCTION} > 0) {
    if ($user->{REDUCTION} < 100) {
      $Internet_->{DAY_ABON}   = sprintf('%.2f', $Internet_->{DAY_ABON} * (100 - $user->{REDUCTION}) / 100) if ($Internet_->{DAY_ABON} > 0);
      $Internet_->{MONTH_ABON} = sprintf('%.2f', $Internet_->{MONTH_ABON} * (100 - $user->{REDUCTION}) / 100) if($Internet_->{MONTH_ABON} > 0);
    }
  }

  my $money_name = '';
  if ($conf{MONEY_UNIT_NAMES}) {
    if (ref $conf{MONEY_UNIT_NAMES} eq 'ARRAY') {
      $money_name = $conf{MONEY_UNIT_NAMES}->[0] || '';
    }
    else {
      $money_name = (split(/;/, $conf{MONEY_UNIT_NAMES}))[0];
    }
  }

  #Extra fields
  $Internet_->{EXTRA_FIELDS} = '';
  my @check_fields = (
    "MONTH_ABON:0.00:MONTH_FEE:$money_name",
    "DAY_ABON:0.00:DAY_FEE:$money_name",
    "TP_ACTIVATE_PRICE:0.00:ACTIVATE_TARIF_PLAN:$money_name",
    "SERVICE_EXPIRE:0000-00-00:EXPIRE",
    "TP_AGE:0:AGE:DAYS",
    "IP:0.0.0.0:STATIC_IP",
    "IPV6::STATIC IPv6",
    "IPV6_PREFIX::IPv6 Prefix",
    "CID::MAC:"
      . (($conf{INTERNET_MAC_DICOVERY}) ? $html->button($lang{CHANGE}, "index=". get_function_index('internet_user_info')
      ."&DISCOVERY_MAC=1", { BUTTON => 1 }) :  ''),
    'ACTIVATE:0000-00-00:ACTIVATE',
  );

  my @extra_fields = ();
  foreach my $param ( @check_fields ) {
    my($id, $default_value, $lang_, $value_prefix )=split(/:/, $param, 4);

    if(! defined($Internet_->{$id}) || $Internet_->{$id} eq $default_value) {
      next;
    }
    elsif ($Internet_->{TP_AGE} && $id =~/MONTH_ABON|DAY_ABON/) {
      next;
    }

    if ($value_prefix && $lang{$value_prefix}) {
      $value_prefix=$lang{$value_prefix};
    }

    push @extra_fields,$html->tpl_show(templates('form_row_client'), {
        ID    => $id,
        NAME  => $lang{$lang_},
        VALUE => $Internet_->{$id} . ( $value_prefix ? (' ' . $value_prefix) : '' ),
      }, { OUTPUT2RETURN => 1, ID => $id });
  }

  $Internet_->{EXTRA_FIELDS} = join(($FORM{json} ? ',' : ''), @extra_fields);

  $Internet->{PREPAID_INFO} = internet_traffic_rest({
    UID => $Service->{UID},
    SERVICE_ID => $Service->{ID}
  });
 ## START КТК-39 ### 
	$Internet->{ONLINE_TABLE} = internet_user_online($uid);
		if (!$Internet->{ONLINE_TABLE}) {
	$Internet->{LAST_LOGIN_MSG} = internet_user_error($Internet_);
	}
  
## END КТК-39 ###

  my $internet_user_info = $html->tpl_show(_include('internet_user_info', 'Internet'), $Internet_,
    {  ID => 'internet_user_info' });

  return 1;
}


#**********************************************************
=head2 internet_discovery($user_ip)

  Arguments:
    $user_ip

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub internet_discovery {
  my ($user_ip, $attr)=@_;

  if($conf{INTERNET_IP_DISCOVERY_IP}) {
    my ($user_name, $discovery_user_ip) = split(/:/, $conf{INTERNET_IP_DISCOVERY_IP});
    if($user_name eq $user->{LOGIN}) {
      $user_ip = $discovery_user_ip;
    }
  }

  if ($FORM{DISCOVERY_MAC}) {
    if ($FORM{discovery} && $attr->{CID} && $attr->{CID} =~ /^$MAC$/) {
      $Internet->user_list({ CID => $FORM{CID} });
      if (defined($Internet->{TOTAL}) && $Internet->{TOTAL} < 1) {
        $Internet->user_change({
          ID  => $attr->{ID},
          UID => $attr->{UID},
          CID => $FORM{CID}
        });

        internet_hangup({
          #UID => $attr->{UID}
          #FRAMED_IP_ADDRESS=>$user->{REMOTE_ADDR}
          CID   => $FORM{CID},
          GUEST => 1
        });

      }
    }

    my $DHCP_INFO = internet_dhcp_get_mac($user_ip, { CHECK_STATIC => 1 });
    $html->tpl_show(_include('internet_discovery_manual', 'Internet'), {
      %$Internet,
      IP  => $user_ip,
      ID  => 'internet_discovery_manual',
      CID => $DHCP_INFO->{CID}
    });

    return 1;
  }
  else {
    $conf{INTERNET_IP_DISCOVERY} =~ s/[\r\n ]//g;
    my @dhcp_nets = split(/;/, $conf{INTERNET_IP_DISCOVERY});

    my $discovery_ip = 0;
    foreach my $nets (@dhcp_nets) {
      my (undef, $net_ips, undef) = split(/:/, $nets);
      if (check_ip($user_ip, $net_ips)) {
        $discovery_ip = 1;
        last;
      }
    }

    if (!$discovery_ip) {
      return 1;
    }
  }

  my $session_list = $Sessions->online({
    CLIENT_IP => $user_ip,
    #USER_NAME => $user->{LOGIN},
    ACCT_SESSION_ID => '_SHOW',
    NAS_ID    => '_SHOW',
    UID       => '_SHOW',
    GUEST     => '_SHOW',
    SORT      => 'guest',
    DESC      => 'DESC',
  });

  if ($Sessions->{TOTAL} < 1 || $session_list->[0]->{guest} && ! $session_list->[0]->{uid}) {

    my $DHCP_INFO = internet_dhcp_get_mac($user_ip, { CHECK_STATIC => 1 }); 

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
        if (internet_dhcp_get_mac_add($user_ip, $DHCP_INFO, { NAS_ID => $session_list->[0]->{nas_id} })) {
          $html->message('info', $lang{INFO}, "$lang{ACTIVATE}\n\n "
              . (($Internet->{NEW_IP} && $Internet->{NEW_IP} ne '0.0.0.0') ? "IP: $Internet->{NEW_IP}\n" : q{})
              .  "CID: $DHCP_INFO->{MAC}");

          if ($session_list->[0]->{acct_session_id}) {
            internet_hangup({
              ACCT_SESSION_ID => $session_list->[0]->{acct_session_id},
              UID             => $session_list->[0]->{uid},
            });
          }
        }
      }

      if (! $Internet->{NEW_IP}) {
        $html->tpl_show(_include('internet_guest_mode', 'Internet'), {
          %$Internet,
          %$DHCP_INFO,
          IP => $user_ip,
          ID => 'internet_guest_mode'
        });
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 internet_user_chg_tp($attr)

=cut
#**********************************************************
sub internet_user_chg_tp {
  my ($attr) = @_;

  my $period = $FORM{period} || 0;
  if (!$conf{INTERNET_USER_CHG_TP}) {
    $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", $lang{NOT_ALLOW}, { ID => 140 });
    return 0;
  }

  my $uid = $LIST_PARAMS{UID};

  if (!$uid) {
    $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST}, { ID => 19 });
    return 0;
  }

  $Internet = $Internet->user_info($uid, { DOMAIN_ID => $user->{DOMAIN_ID}, ID => $FORM{ID} });

  if ($Internet->{TOTAL} < 1) {
    $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE}, { ID => 22 });
    return 0;
  }

  if($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} > 0) {
    $html->message('err', $lang{ERROR}, "$lang{PERSONAL} $lang{TARIF_PLAN}  $lang{ENABLED}", { ID => 23 });
    return 0;
  }

  if ($conf{FEES_PRIORITY} && $conf{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
    $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
  }

  if ($user->{GID}) {
    #Get user groups
    $user->group_info($user->{GID});
    if ($user->{DISABLE_CHG_TP}) {
      $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", $lang{NOT_ALLOW}, { ID => 143 });
      return 0;
    }
  }

  #Get TP groups
  $Tariffs->tp_group_info($Internet->{TP_GID});
  if (!$Tariffs->{USER_CHG_TP}) {
    $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", $lang{NOT_ALLOW}, { ID => 144 });
    return 0;
  }

  my $next_abon = $Service_control->get_next_abon_date({ SERVICE_INFO => $Internet });
  $Internet->{ABON_DATE} = $next_abon->{ABON_DATE};

  if ($FORM{set} && $FORM{ACCEPT_RULES}) {
    my $add_result = $Service_control->user_chg_tp({ %FORM, UID => $uid, SERVICE_INFO => $Internet, MODULE => 'Internet' });
    $html->message('info', $lang{CHANGED}, "$lang{CHANGED}") if !_message_show($add_result);
  }
  elsif ($FORM{del} && $FORM{ACCEPT_RULES}) {
    my $del_result = $Service_control->del_user_chg_shedule({ %FORM, UID => $uid });
    $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]") if (!_message_show($del_result));
  }

  $Shedule->info({ UID => $user->{UID}, TYPE => 'tp', MODULE => 'Internet' });

  my $table;
  if ($Shedule->{TOTAL} > 0) {
    my $action = $Shedule->{ACTION};
    my $service_id = 0;
    if ($action =~ /:/) {
      ($service_id, $action) = split(/:/, $action);
    }

    $Tariffs->info(0, { TP_ID => $action });

    $table = $html->table({
      width      => '100%',
      caption    => $lang{SHEDULE},
      ID         => 'INTERNET_TP_SHEDULE',
      rows       => [
        [ "$lang{TARIF_PLAN}:", "$Tariffs->{ID} : $Tariffs->{NAME}" ],
        [ "$lang{DATE}:", "$Shedule->{Y}-$Shedule->{M}-$Shedule->{D}" ],
        [ "$lang{ADDED}:", $Shedule->{DATE} ],
        [ "ID:", $Shedule->{SHEDULE_ID} ] ]
    });

    $Tariffs->{TARIF_PLAN_SEL} = $table->show({ OUTPUT2RETURN => 1 }) . $html->form_input('SHEDULE_ID', "$Shedule->{SHEDULE_ID}", { TYPE => 'HIDDEN', OUTPUT2RETURN => 1 });
    $Tariffs->{TARIF_PLAN_TABLE} = $Tariffs->{TARIF_PLAN_SEL};
    if (!$Shedule->{ADMIN_ACTION}) {
      $Tariffs->{ACTION} = 'del';
      $Tariffs->{LNG_ACTION} = "$lang{DEL}  $lang{SHEDULE}";
    }
  }
  else {
    $Tariffs->{TARIF_PLAN_SEL} = $html->form_select('TP_ID', {
      SELECTED => $Internet->{TP_ID},
      SEL_LIST => $Tariffs->list({
        TP_GID          => $Internet->{TP_GID},
        CHANGE_PRICE    => '<=' . ($user->{DEPOSIT} + $user->{CREDIT}),
        MODULE          => 'Dv;Internet',
        STATUS          => '<1',
        NEW_MODEL_TP    => 1,
        TP_CHG_PRIORITY => $Internet->{TP_PRIORITY},
        COLS_NAME       => 1
      }),
    });

    my $available_tariffs = $Service_control->available_tariffs({ %FORM, MODULE => 'Internet', UID => $uid });

    if (ref($available_tariffs) ne 'ARRAY' || $#{$available_tariffs} < 0) {
      $html->message('info', $lang{INFO}, $lang{ERR_NO_AVAILABLE_TP}, { ID => 142 });
      return 0;
    }

    $table = $html->table({
      width   => '100%',
      ID      => 'INTERNET_TP',
      title   => [ 'ID', $lang{NAME}, '-' ],
      FIELDS_IDS => $Tariffs->{COL_NAMES_ARR},
      caption => $lang{TARIF_PLANS},
    });

    foreach my $tp (@{$available_tariffs}) {
      my $radio_but = $tp->{ERROR} ? $tp->{ERROR} : $html->form_input('TP_ID', $tp->{tp_id}, { TYPE => 'radio', OUTPUT2RETURN => 1 });

      my $text = '';
      if ($tp->{popular}) {
        $table->{rowcolor} = 'table-info';
        $text .= ' ' . $html->badge("$lang{POPULAR}!", { TYPE => 'badge-warning', OUTPUT2RETURN => 1 }) . $html->br();
      } else {
        undef $table->{rowcolor};
      }

      $text .= $html->b($tp->{name} || q{});

      if ($tp->{comments}) {
        $text .= $html->br() . $tp->{comments};
      }
      $table->addrow($tp->{id}, $text, $radio_but);
    }

    $Tariffs->{TARIF_PLAN_TABLE} = $table->show({ OUTPUT2RETURN => 1 });

    if (($conf{INTERNET_USER_CHG_TP_SHEDULE} && !$conf{INTERNET_USER_CHG_TP_NPERIOD}) || $conf{INTERNET_USER_CHG_TP_NOW}) {
      $Tariffs->{PARAMS} .= form_period($period, {
        ABON_DATE => $Internet->{ABON_DATE},
        TP        => $Tariffs,
        NOW       => $conf{INTERNET_USER_CHG_TP_NOW},
        SHEDULE   => $conf{INTERNET_USER_CHG_TP_SHEDULE},
        PERIOD    => $FORM{period},
        DATE      => $FORM{DATE}
      });
    }

    $Tariffs->{ACTION} = 'set';
    $Tariffs->{LNG_ACTION} = $lang{CHANGE};
  }

  $Tariffs->{UID} = $attr->{USER_INFO}->{UID};
  $Tariffs->{TP_ID} = $Internet->{TP_ID};
  $Tariffs->{TP_NAME} = "$Internet->{TP_NUM}:$Internet->{TP_NAME}";

  $Tariffs->{CHG_TP_RULES} = $html->tpl_show(_include('internet_chg_tp_rule', 'Internet'), {}, { OUTPUT2RETURN => 1 });

  $html->tpl_show(templates('form_client_chg_tp'), { %$Tariffs,
    ID => $Internet->{ID}
  }, { ID => 'INTERNET_CHG_TP' });

  return 1;
}

#**********************************************************
=head2 form_stats($attr)

  Arguments:
    $attr
      UID

=cut
#**********************************************************
sub internet_user_stats {
  my ($attr) = @_;

  my $uid = $LIST_PARAMS{UID} || $user->{UID} || $attr->{UID};
  if (defined($FORM{SESSION_ID})) {
    $pages_qs .= "&SESSION_ID=$FORM{SESSION_ID}";
    internet_session_detail({ LOGIN => $LIST_PARAMS{LOGIN} });
    return 0;
  }

  _error_show($Sessions);

  #Join Service
  if ($user->{COMPANY_ID}) {
    if ($FORM{COMPANY_ID}) {
      $users = Users->new($db, $admin, \%conf);
      require Internet::Reports;
      internet_report_use();
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
      $Internet->{JOIN_SERVICES_USERS} = $html->button($lang{COMPANY}, "&sid=$sid&index=$index&COMPANY_ID=$user->{COMPANY_ID}", { BUTTON => 1 }) . ' ';
    }

    $Internet->user_info($uid);

    if ($Internet->{JOIN_SERVICE}) {
      my @uids = ();
      my $list = $Internet->user_list(
        {
          JOIN_SERVICE => ($Internet->{JOIN_SERVICE}==1) ? $uid : $Internet->{JOIN_SERVICE},
          COMPANY_ID   => $attr->{USER_INFO}->{COMPANY_ID},
          LOGIN        => '_SHOW',
          PAGE_ROWS    => 1000,
          COLS_NAME    => 1
        }
      );

      if ($Internet->{JOIN_SERVICE} == 1) {
        $Internet->{JOIN_SERVICES_USERS} .=
          (!$FORM{JOIN_STATS}) ? $html->b("$lang{ALL} $lang{USERS}") . ' :: '
            : $html->button("$lang{ALL}", "&sid=$sid&index=$index&JOIN_STATS=" . $uid, { BUTTON => 1 }) . ' ';
      }

      foreach my $line (@$list) {
        if ($FORM{JOIN_STATS} && $FORM{JOIN_STATS} == $line->{uid}) {
          $Internet->{JOIN_SERVICES_USERS} .= $html->b($line->{login}) . ' ';
          $uid = $FORM{JOIN_STATS};
        }
        elsif($Internet->{JOIN_SERVICE} == 1) {
          $Internet->{JOIN_SERVICES_USERS} .= $html->button($line->{login}, "&sid=$sid&index=$index&JOIN_STATS=" . $line->{uid}, { BUTTON => 1 }) . ' ';
        }

        push @uids, $line->{uid};
      }

      $LIST_PARAMS{UIDS}  = ($Internet->{JOIN_SERVICE} > 1) ? $Internet->{JOIN_SERVICE} : $uid;
      $LIST_PARAMS{UIDS} .= ',' . join(', ', @uids) if ($#uids > -1 && !$FORM{JOIN_STATS});
    }

    my $table = $html->table(
      {
        width => '100%',
        rows  => [ [ "$lang{JOIN_SERVICE}: ", $Internet->{JOIN_SERVICES_USERS} ] ]
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

    if($FORM{ONLINE}) {
      $LIST_PARAMS{ONLINE}=$FORM{ONLINE};
    }
  }

  #online sessions
  my $list = $Sessions->online(
    {
      CLIENT_IP          => '_SHOW',
      CID                => '_SHOW',
      DURATION_SEC2      => '_SHOW',
      ACCT_INPUT_OCTETS  => '_SHOW',
      ACCT_OUTPUT_OCTETS => '_SHOW',
      UID                => $uid
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
        _sec2time_str($line->{duration_sec2}),
        int2byte($line->{acct_input_octets}),
        int2byte($line->{acct_output_octets})
      );
    }
    $Sessions->{ONLINE} = $table->show({ OUTPUT2RETURN => 1 });
  }

  #PEriods totals
  $Sessions->{PERIOD_STATS} = internet_stats_periods({ UID => $uid });
  $Sessions->{PERIOD_SELECT}= internet_period_select({ UID => $uid });
  $Internet->user_info($uid);

  my $TRAFFIC_NAMES = internet_traffic_names($Internet->{TP_ID});

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
      UID  => ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} > 1) ? $Internet->{JOIN_SERVICE} : $uid,
      UIDS => $uid
    })
  )
  {
    $list  = $Sessions->{INFO_LIST};
    my $table = $html->table(
      {
        caption     => $lang{PREPAID},
        width       => '100%',
        title_plain => [ "$lang{TRAFFIC} $lang{TYPE}", $lang{BEGIN}, $lang{END}, $lang{START}, "$lang{TOTAL} (MB)", "$lang{REST} (MB)", "$lang{OVERQUOTA} (MB)" ],
        ID          => 'INTERNET_STATS_PREPAID'
      }
    );

    foreach my $line (@$list) {
      my $traffic_rest = ($conf{INTERNET_INTERVAL_PREPAID}) ? $Sessions->{REST}->{ $line->{interval_id} }->{ $line->{traffic_class} }  :  $Sessions->{REST}->{ $line->{traffic_class} };

      $table->addrow(
        $line->{traffic_class} . ':' . (($TRAFFIC_NAMES->{ $line->{traffic_class} }) ? $TRAFFIC_NAMES->{ $line->{traffic_class} } : '').
          ($conf{INTERNET_INTERVAL_PREPAID} ? "/ $line->{interval_id}" : '') ,
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
        (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : $lang{TRAFFIC}) . " $lang{RECV}",
        (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : $lang{TRAFFIC}) . " $lang{SENT}",

        (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : $lang{TRAFFIC}) . " $lang{SUM}",

        (($TRAFFIC_NAMES->{1}) ? $TRAFFIC_NAMES->{1} : $lang{TRAFFIC}) . " $lang{RECV}",
        (($TRAFFIC_NAMES->{1}) ? $TRAFFIC_NAMES->{1} : $lang{TRAFFIC}) . " $lang{SENT}",

        (($TRAFFIC_NAMES->{1}) ? $TRAFFIC_NAMES->{1} : $lang{TRAFFIC}) . " $lang{SUM}",
        $lang{SUM}
      ],
      rows        => [
        [
          $Sessions->{TOTAL},
          _sec2time_str($Sessions->{DURATION}),
          int2byte($Sessions->{TRAFFIC_OUT}, { DIMENSION => $FORM{DIMENSION} }),
          int2byte($Sessions->{TRAFFIC_IN}, { DIMENSION => $FORM{DIMENSION} }),

          int2byte(($Sessions->{TRAFFIC_OUT} || 0) + ($Sessions->{TRAFFIC_IN} || 0), { DIMENSION => $FORM{DIMENSION} }),

          int2byte($Sessions->{TRAFFIC2_OUT}, { DIMENSION => $FORM{DIMENSION} }),
          int2byte($Sessions->{TRAFFIC2_IN}, { DIMENSION => $FORM{DIMENSION} }),

          int2byte(($Sessions->{TRAFFIC2_OUT} || 0) + ($Sessions->{TRAFFIC2_IN} || 0), { DIMENSION => $FORM{DIMENSION} }),
          $Sessions->{SUM}
        ]
      ],
      ID          => 'TRAFFIC_SUM'
    }
  );

  $Sessions->{TOTALS_FULL} = $table->show({ OUTPUT2RETURN => 1 });

  if (-f '../charts.cgi' || -f 'charts.cgi') {
    if ($user->{UID}) {
      $Sessions->{GRAPHS} = internet_get_chart_iframe("UID=$uid", '1,2');
    }
  }

  if ($Sessions->{TOTAL} > 0) {
    $Sessions->{SESSIONS} = internet_sessions($list, $Sessions, {
      OUTPUT2RETURN        => 1,
      INTERNET_UP_SESSIONS => $conf{INTERNET_UP_SESSIONS},
      PAGES_QS             => $pages_qs
    });
  }

  $html->tpl_show(_include('internet_user_stats', 'Internet'), $Sessions, { ID => 'internet_user_stats' });

  return 1;
}

#**********************************************************
=head2 internet_dhcp_get_mac_add($ip, $DHCP_INFO, $attr) - Add discovery mac

  Arguments:
    $ip
    $DHCP_INFO
    $attr

    $conf{INTERNET_IP_DISCOVERY}

  Returns:

=cut
#**********************************************************
sub internet_dhcp_get_mac_add {
  my ($ip, $DHCP_INFO, $attr) = @_;

  $conf{INTERNET_IP_DISCOVERY}=~s/[\r\n ]//g;
  my @dhcp_nets         = split(/;/, $conf{INTERNET_IP_DISCOVERY});
  my $default_params    = "IP,MAC";
  foreach my $nets (@dhcp_nets) {
    my %PARAMS_HASH = ();

    my ($net_id, $net_ips, $params) = split(/:/, $nets);
    $params                 = $default_params if (!$params);
    my @params_arr          = split(/,/, $params);

    for(my $i=0; $i<=$#params_arr; $i++) {
      my ($param, $value)=split(/=/, $params_arr[$i]);
      $PARAMS_HASH{$param} = $value || $DHCP_INFO->{$param};
    }

    my $start_ip           = '0.0.0.0';
    my $bit_mask           = 0;
    ($start_ip, $bit_mask) = split(/\//, $net_ips) if ($net_ips);
    my $mask               = 0b0000000000000000000000000000001;
    my $address_count      = sprintf("%d", $mask << (32 - $bit_mask));

    if (ip2int($ip) >= ip2int($start_ip) && ip2int($ip) <= ip2int($start_ip) + $address_count) {
      require Internet::User_ips;
      if($net_id) {
        $PARAMS_HASH{IP} = get_static_ip($net_id);

        if ($PARAMS_HASH{IP} !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
          if ($PARAMS_HASH{IP} == -1) {
            return 0;
          }
          elsif ($PARAMS_HASH{IP} == 0) {
            $PARAMS_HASH{IP} = '0.0.0.0';
          }
        }
      }

      if ($PARAMS_HASH{MAC}) {
        $PARAMS_HASH{CID} = $PARAMS_HASH{MAC};
      }
      if ($PARAMS_HASH{PORTS}) {
        $PARAMS_HASH{PORT} = $PARAMS_HASH{PORTS};
      }
      my $list = $Internet->user_list({
        NAS_ID    => $PARAMS_HASH{NAS_ID},
        UID       => $user->{UID},
        PORT      => $PARAMS_HASH{PORTS},
        COLS_NAME => 1,
        PAGE_ROWS => 1
      });

      #my $discovery = join("\n", map { $_.'->'.$PARAMS_HASH{$_} } keys %PARAMS_HASH);

      if ($Internet->{TOTAL} > 0) {
        $Internet->user_change({
          %PARAMS_HASH,
          ID     => $list->[0]->{id},
          UID    => $list->[0]->{uid},
          NETWORK=> $net_id,
          #MAC    => $PARAMS_HASH{MAC}
        });
      }
      else {
        my $internet_list = $Internet->user_list({
          UID       => $user->{UID},
          PORT      => '_SHOW',
          NAS_ID    => '_SHOW',
          COLS_NAME => 1,
          PAGE_ROWS => 1
        });
        foreach my $service (@$internet_list) {
          if ((!$service->{nas_id} && !$service->{port}) || $Internet->{TOTAL} == 1) {
            $Internet->user_change({
              %PARAMS_HASH,
              ID     => $service->{id},
              UID    => $service->{uid},
              NETWORK=> $net_id,
              #MAC    => $PARAMS_HASH{MAC}
            });
          }
        }
      }

      my $log_type = 'LOG_INFO';
      my $error_id = 0;
      if ($Internet->{errno}) {
        $log_type = 'LOG_WARNING';
        if ($Internet->{errno} == 7) {
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
        require Internet::Dhcp;
        dhcp_config({
          NETWORKS => $net_id,
          reconfig => 1,
          QUITE    => 1,
          %PARAMS_HASH
        });
        $Internet->{NEW_IP} = $PARAMS_HASH{IP};
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
=head2 internet_dhcp_get_mac($ip, $attr) - Get MAC from dhcp leaseds

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
sub internet_dhcp_get_mac {
  my ($ip, $attr) = @_;

  #Get user by static IP
  $Internet->user_info(0, {
    IP => $ip
  });

  my %PARAMS = ();

  if ($Internet->{TOTAL} > 0) {
    %PARAMS = (
      IP     => $Internet->{IP},
      MAC    => $Internet->{CID},
      NAS_ID => $Internet->{NAS_ID},
      PORTS  => $Internet->{PORT},
      VLAN   => $Internet->{VLAN},
      UID    => $Internet->{UID},
      SERVER_VLAN => $Internet->{SERVER_VLAN}
    );

    if ($attr->{CHECK_STATIC}) {
      $PARAMS{STATIC} = 1;
    }

    if ($PARAMS{MAC} && $PARAMS{MAC} ne '00:00:00:00:00:00') {
      return \%PARAMS;
    }
  }

  my $list = $Sessions->online({
    FRAMED_IP_ADDRESS => $ip,
    VLAN              => '_SHOW',
    SERVER_VLAN       => '_SHOW',
    UID               => '_SHOW',
    CID               => '_SHOW',
    NAS_TYPE          => '!cisco_isg',
    SWITCH_ID         => '_SHOW',
    SWITCH_PORT       => '_SHOW',
    COLS_NAME         => 1,
    COLS_UPPER        => 1
  });

  if ($Sessions->{TOTAL} > 0) {
    %PARAMS = %{$list->[0]};
    $PARAMS{NAS_ID} = $list->[0]->{switch_id} || $list->[0]->{nas_id};
    $PARAMS{MAC} = _mac_former($list->[0]->{cid});
    $PARAMS{PORTS} = $list->[0]->{switch_port};
    $PARAMS{PORT} = $list->[0]->{switch_port};
    $PARAMS{UID} = $list->[0]->{uid};
    $PARAMS{IP} = int2ip($list->[0]->{framed_ip_address});

    $PARAMS{VLAN} = $list->[0]->{vlan};
    $PARAMS{SERVER_VLAN} = $list->[0]->{server_vlan};
  }

  $PARAMS{CUR_IP} = $ip;
  # if (defined($PARAMS{NAS_ID}) && $PARAMS{NAS_ID} == 0 && $PARAMS{CIRCUIT_ID} ) {
  #   ($PARAMS{NAS_ID}, $PARAMS{PORTS}, $PARAMS{VLAN}, $PARAMS{NAS_MAC})=dhcphosts_o82_info({ %PARAMS });
  # }

  return \%PARAMS;
}

#**********************************************************
=head2 internet_holdup_service($attr) - Hold up user service

=cut
#**********************************************************
sub internet_holdup_service {

  return '' if ($conf{HOLDUP_ALL});

  my $holdup_info = $Service_control->user_holdup({ %FORM, UID => $user->{UID}, ID => $Internet->{ID} });

  if ($holdup_info->{error}) {
    my $error_message = $lang{$holdup_info->{errstr}} // $holdup_info->{errstr};
    $html->message('err', $lang{ERROR}, $error_message, { ID => $holdup_info->{error} })
  }

  if (!$holdup_info->{DEL}) {
    return '' if ($holdup_info->{error} || _error_show($holdup_info) || $holdup_info->{success});

    if (($Internet->{STATUS} && $Internet->{STATUS} == 3)) { # || $Internet->{DISABLE}) {
      $html->message('info', $lang{INFO}, "$lang{HOLD_UP}\n " .
        $html->button($lang{ACTIVATE}, "index=$index&del=1&ID=". ($FORM{ID} || q{}) ."&sid=$sid",
          { BUTTON => 2, MESSAGE => "$lang{ACTIVATE}?" }) );
      return '';
    }

    $Internet->{FROM_DATE} = date_inc($DATE);
    $Internet->{TO_DATE} = $Service_control->{TO_DATE} || next_month({ DATE => $DATE });
    return $html->tpl_show(_include('internet_hold_up', 'Internet'), $Internet, { OUTPUT2RETURN => 1 })
  }
  else {
    $html->message('info', $lang{INFO}, "$lang{HOLD_UP}: $holdup_info->{DATE_FROM} $lang{TO} $holdup_info->{DATE_TO}"
      . ($holdup_info->{DEL_IDS} ? ($html->br() . $html->button($lang{DEL},
      "index=$index&ID=". ($FORM{ID} || q{}) ."&del=1&IDS=$holdup_info->{DEL_IDS}". (($sid) ? "&sid=$sid" : q{}),
      { class => 'btn btn-primary', MESSAGE => "$lang{DEL} $lang{HOLD_UP}?" })) : q{}));
  }

  return '';
}

#**********************************************************
=head2 internet_filters_control($attr) - Hold up user service

=cut
#**********************************************************
sub internet_filters_control {
  my ($Service) = @_;

  my Internet $Internet_ = $Service;

  if ($FORM{FILTER_DEL}) {
    $Internet_->user_change({
      FILTER_ID => '',
      UID       => $user->{UID}
    });

    internet_hangup({ UID => $user->{UID} });
  }
  elsif ($FORM{FILTER_ID}) {
    $Internet_->filters_info($FORM{FILTER_ID});

    $Internet_->user_change({
      FILTER_ID => $Internet_->{PARAMS},
      UID       => $user->{UID}
    });

    $html->message('info', $lang{PARENT_CONTROL}, $lang{ACTIVATE});
    internet_hangup({ UID => $user->{UID} });
    return 1;
  }

  my $filters_list = $Internet_->filters_list({
    USER_PORTAL => 1,
    FILTER      => '_SHOW',
    PARAMS      => '_SHOW'
  });

  my $buttons = q{};
  foreach my $filter (@$filters_list) {
    if($Internet_->{FILTER_ID} && $Internet_->{FILTER_ID} eq $filter->{params}) {
      $buttons .= $html->button($lang{DEL} .' '. $filter->{filter}, "index=$index&FILTER_DEL=1", { BUTTON => 1 });
    }
    else {
      $buttons .= $html->button($filter->{filter}, "index=$index&FILTER_ID=$filter->{id}", { BUTTON => 2 });
    }
  }

  if ($buttons) {
    $html->tpl_show(_include('internet_parental_control', 'Internet'), { BUTTONS => $buttons });
  }

  return 1;
}

#**********************************************************
=head2 internet_hangup($attr) - Hangup active sessions

  Arguments:
    $attr
      UID
      ACCT_SESSION_ID

  Results:
    TRUE or False

=cut
#**********************************************************
sub internet_hangup {
  #TODO: move to package
  my ($attr) = @_;

  $Sessions->online_info( $attr );
  $Nas->info({ NAS_ID => $Sessions->{NAS_ID} });

  require AXbills::Nas::Control;
  AXbills::Nas::Control->import();

  my $Nas_cmd = AXbills::Nas::Control->new($db, \%conf);
  sleep 1;
  $Nas_cmd->hangup($Nas, 0, '', $Sessions);
  `echo "$DATE $TIME hangup NAS_ID: $Sessions->{NAS_ID}  $attr->{UID} TYPE: $Nas->{NAS_TYPE} $Sessions->{ACCT_SESSION_ID}  " >> /tmp/hagup`;

  return 1;
}

1;

