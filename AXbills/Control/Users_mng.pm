=head1 NAME

  User manage

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array date_diff
  gen_time check_time show_hash int2byte load_pmodule mk_unique_value date_inc vars2lang urlencode);
use AXbills::Defs;

require AXbills::Misc;

our (
  $db,
  %lang,
  $admin,
  %conf,
  %permissions,
  @MONTHES,
  @WEEKDAYS,
  %uf_menus,
  %module,
  %COOKIES,
  $ui,
  @bool_vals,
  @state_colors,
  @state_icon_colors,
  @status
);

our AXbills::HTML $html;
our Users $users;
my @priority_colors = ('btn-secondary', 'btn-info', 'btn-success', 'btn-warning', 'btn-danger');


#**********************************************************
=head2 form_user_profile($attr) - User account managment form

  Arguments:
    $attr
      USER_INFO

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub form_user_profile {
  my ($attr) = @_;

  my Users $user_info = $attr->{USER_INFO};

  if (_error_show($user_info, { ID => 111 })) {
    return 0;
  }
  elsif (!$user_info->{UID}) {
    return 0;
  }

  if (in_array('Multidoms', \@MODULES) && $user_info->{GID}) {
    my $group_list = $users->groups_list({
      GID            => $user_info->{GID},
      COLS_NAME      => 1,
      NAME           => '_SHOW',
      DESCR          => '_SHOW',
      ALLOW_CREDIT   => '_SHOW',
      DISABLE_PAYSYS => '_SHOW',
      DISABLE_CHG_TP => '_SHOW',
      USERS_COUNT    => '_SHOW',
    });
    if ($users->{TOTAL} > 0 && $user_info->{DOMAIN_ID} != $group_list->[0]->{domain_id}) {
      $user_info->{GRP_ERR} = "style='background-color:#FF0000' data-tooltip='$lang{DOMAIN} $lang{ERROR}'";
    }
  }

  #Make service menu
  if (defined($FORM{newpassword})) {
    if (!form_passwd({ USER_INFO => $user_info })) {
      return 0;
    }
  }
  elsif ($FORM{Shedule} || $FORM{holdup}) {
    print form_user_holdup($users);
    return 0;
  }

  if ($FORM{change}) {
    if (!form_user_change({ USER_INFO => $user_info, FORM => \%FORM })) {
      return 0;
    }
  }
  elsif ($FORM{del_user} && $FORM{COMMENTS} && $index == 15 && $permissions{0}{5}) {
    user_del({ USER_INFO => $user_info });
    return 0;
  }
  elsif ($conf{userside_like} && $permissions{0}{1}) {
    require Userside::Userside_web;
    Userside::Userside_web::userside_page($user_info->{UID});
  }
  else {
    delete($FORM{add});
    require Control::Services;
    my $service_info = get_services($user_info, {});
    my $pre_info = '';

    foreach my $service (@{$service_info->{list}}) {
      my $calculated_discount = $service->{ORIGINAL_SUM} - $service->{SUM};
      my $formatted_sum = sprintf("%.2f", $service->{SUM} || 0);
      my $formatted_discount = sprintf("%.2f", $calculated_discount || 0);
      my $labeled_service = "$service->{SERVICE_NAME} $service->{SERVICE_DESC}: ";
      my $labeled_discount = $calculated_discount ? " ($lang{REDUCTION}: $formatted_discount)" : '';

      $pre_info .= $labeled_service
        . $formatted_sum
        . $labeled_discount . "\n";
    }

    $pre_info .= "$lang{TOTAL}: " . sprintf("%.2f", $service_info->{total_sum} || 0);

    if ($service_info->{distribution_fee} && $service_info->{distribution_fee} > 0 && $user_info->{REDUCTION} < 100 && defined($user_info->{DEPOSIT})) {
      my $days_to_end = int(($user_info->{DEPOSIT} || 0) / $service_info->{distribution_fee});
      $pre_info .= " $lang{REMAIN} $lang{DAYS_2}: " . sprintf("%d", $days_to_end);
      if ($days_to_end > 0) {
        my ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime(time + 86400 * $days_to_end)));
        $pre_info .= " / $lang{TO} $Y-$M-$D ";
      }
    }

    my ($service_info0, $service_info1, $service_info2, $service_info3) = user_services({ USER_INFO => $user_info, PROFILE_MODE => 1 });

    my $l_schema = $Conf->config_info({
      PARAM     => 'LSCHEMA_FOR_' . $admin->{AID},
      COLS_NAME => 1
    });

    my $left_info = $l_schema->{VALUE};
    if (!$left_info || $left_info eq '') {
      $left_info = 'form_1,form_3';
    }

    my @lsch_value = split(/,/, $left_info);
    my $r_schema = $Conf->config_info({
      PARAM     => 'RSCHEMA_FOR_' . $admin->{AID},
      COLS_NAME => 1
    });

    my $right_info = $r_schema->{VALUE};
    if (!$right_info || $right_info eq '') {
      $right_info = 'form_2,form_4';
    }

    # return;
    if (in_array('Info', \@MODULES)) {
      load_module('Info', $html);
    }

    my @rsch_value = split(/,/, $right_info);
    my %TOTAL_FNC = (
      form_1 => user_form({ USER_INFO => $user_info }),
      form_2 => user_pi({ %$attr, USER_INFO => $user_info, PROFILE_MODE => 1 }),
      form_3 => $service_info1 || '',
      form_4 => $service_info2 || '',
      form_5 => $service_info0 || '',
      form_6 => (in_array('Info', \@MODULES) &&
        (!$admin->{MODULES} || $admin->{MODULES}{'Info'})) ? info_comments_show('form_user_profile', $user_info->{UID}, { OUTPUT2RETURN => 1, WITH_BOX => 1 }) : '',
    );

    foreach my $fn (keys %TOTAL_FNC) {
      if (!in_array($fn, \@lsch_value) && !in_array($fn, \@rsch_value)) {
        push(@rsch_value, $fn);
      }
    }

    my $left_panel = '';
    my $right_panel = '';
    foreach my $l_item (@lsch_value) {
      next if ($l_item eq 'empty' || $l_item eq '');
      $left_panel .= $TOTAL_FNC{$l_item} || q{};
    }

    foreach my $r_item (@rsch_value) {
      next if ($r_item eq 'empty' || $r_item eq '');
      $right_panel .= $TOTAL_FNC{$r_item} || q{};
    }

    $html->tpl_show(templates('form_user_profile'), {
      DASHBOARD      => (defined $service_info->{total_sum}) ? $html->message('info', '', $pre_info, { OUTPUT2RETURN => 1 }) : q{},
      LEFT_PANEL     => $left_panel,
      RIGHT_PANEL    => $right_panel,
      SERVICE_INFO_3 => $service_info3,
    },
      {
        ID => 'form_user_profile'
      });
  }

  return 1;
}

#**********************************************************
=head2 form_user_info($attr) - User account add

  Arguments:
    $attr
      USER_INFO - $user_info
      FORM      - \%FORM

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub form_user_info {
  my ($attr) = @_;

  my Users $user_info = $attr->{USER_INFO};

  $FORM{UID} = $user_info->{UID} || 0;
  my $uid = $user_info->{UID} || 0;
  $user_info->{COMPANY_NAME} = "$lang{NOT_EXIST} ID: $user_info->{COMPANY_ID}" if ($user_info->{COMPANY_ID} && !$user_info->{COMPANY_NAME});

  if ($permissions{0} && $permissions{0}{15}) {
    $user_info->{BILL_CORRECTION} = $html->button('', "index=$index&UID=$uid&bill_correction=1",
      { ADD_ICON => 'fa fa-wrench', class => 'btn input-group-button', TITLE => $lang{CHANGE} });
  }

  if ($permissions{0}{3}) {
    my $show_btn = $html->button("", "qindex=$index&header=2&UID=$uid&SHOW_PASSWORD=1",
      { class         => 'btn btn-sm btn-default', ICON => 'fa fa-eye',
        ex_params     => "data-tooltip='$lang{SHOW} $lang{PASSWD}' data-tooltip-position='top'",
        LOAD_TO_MODAL => 1
      });

    my $chg_btn = $html->button("", "index=" . get_function_index('form_passwd') . "&UID=$uid",
      { class => 'btn btn-sm btn-default', ICON => 'fa fa-pencil-alt', ex_params =>
        "data-tooltip='$lang{CHANGE} $lang{PASSWD}' data-tooltip-position='top'" });

    my $portal_btn = $html->button("", "qindex=$index&header=2&UID=$uid&USER_PORTAL=1&SHOW_PASSWORD=1",
      { class     => 'btn btn-sm btn-default', ICON => 'fa fa-sign-in-alt',
        ex_params => "data-tooltip='$lang{USER_PORTAL}' data-tooltip-position='top' target='_blank'"
      });

    my Users $user_i = $users->info($uid, { SHOW_PASSWORD => 1 });
    my $copy_btn = $html->button("", "", {
      class     => 'btn btn-sm btn-default',
      ICON      => 'fa fa-copy',
      ex_params => "data-tooltip='$lang{COPY} $lang{PASSWD}' data-tooltip-position='top'",
      COPY      => $user_i->{PASSWORD},
    });

    $user_info->{PASSWORD} = $html->element('div', $show_btn . $chg_btn . $copy_btn . $portal_btn, { class => 'btn-group' });
  }
  else {
    $user_info->{PASSWORD} = '';
    $user_info->{HIDE_PASSWORD} = "style='display: none;'";
  }

  if (!$permissions{0}{12}) {
    $user_info->{DEPOSIT} = '--';
  }
  else {
    if ($permissions{1}) {
      $user_info->{PAYMENTS_BUTTON} = $html->button('', "index=2&UID=" . $uid,
        { class     => 'btn btn-sm btn-secondary',
          ICON      => 'fa fa-plus',
          ex_params => "data-tooltip='$lang{PAYMENTS}' data-tooltip-position='top'"
        });

      $user_info->{PRINT_BUTTON} = $html->button('', "qindex=$index&STATMENT_ACCOUNT=$uid&UID=$uid&header=2",
        { class     => 'btn btn-sm btn-secondary',
          ICON      => 'fas fa-print',
          target    => '_new',
          ex_params => "data-tooltip='$lang{STATMENT_OF_ACCOUNT}' data-tooltip-position='top'"
        });
    }

    if ($permissions{2}) {
      $user_info->{FEES_BUTTON} = $html->button('', "index=3&UID=$uid",
        { class     => 'btn btn-sm btn-secondary',
          ICON      => 'fa fa-minus',
          ex_params => "data-tooltip='$lang{FEES}' data-tooltip-position='top'" });
    }

    if ($permissions{1} && $permissions{2}) {
      require Finance;
      Finance->import();
      my $Fees = Finance->fees($db, $admin, \%conf);
      my $Payments = Finance->payments($db, $admin, \%conf);

      my $last_payments = $Payments->list({
        DATETIME  => '_SHOW',
        SUM       => '_SHOW',
        DESCRIBE  => '_SHOW',
        UID       => $uid,
        DESC      => 'desc',
        SORT      => 1,
        PAGE_ROWS => 1,
        COLS_NAME => 1
      });

      my $last_date_payments = '';
      my $last_sum_payments = 0;
      foreach my $key (@$last_payments) {
        $last_date_payments = $key->{datetime};
        $last_sum_payments = $key->{sum};
      }

      my $last_fees = $Fees->list({
        DATETIME  => '_SHOW',
        SUM       => '_SHOW',
        DESCRIBE  => '_SHOW',
        UID       => $uid,
        DESC      => 'desc',
        SORT      => 1,
        PAGE_ROWS => 1,
        COLS_NAME => 1
      });

      my $last_date_fees = '';
      my $last_sum_fees = 0;
      foreach my $key (@$last_fees) {
        $last_date_fees = $key->{datetime};
        $last_sum_fees = $key->{sum};
      }

      if ($last_date_payments gt $last_date_fees) {
        $user_info->{BUTTON_SHOW_LAST} = $html->button('', "index=2&UID=" . $uid,
          { ICON => 'fa fa-arrow-up text-primary', ex_params =>
            "data-tooltip='$lang{LAST_PAYMENT}: $last_date_payments </br> $lang{SUM}: $last_sum_payments ' data-tooltip-position='top' class=''" });
      }
      else {
        $user_info->{BUTTON_SHOW_LAST} = $html->button('', "index=3&UID=" . $uid,
          { ICON => 'fa fa-arrow-down text-white', ex_params =>
            "data-tooltip='$lang{LAST_FEES}: $last_date_fees </br>  $lang{SUM}: $last_sum_fees ' data-tooltip-position='top' class=''" });
      }
    }

    if (defined($user_info->{DEPOSIT})) {
      if ($conf{DEPOSIT_FORMAT}) {
        $user_info->{SHOW_DEPOSIT} = sprintf($conf{DEPOSIT_FORMAT}, $user_info->{DEPOSIT}) if ($user_info->{DEPOSIT} =~ /\d+/);
      }
      else {
        $user_info->{SHOW_DEPOSIT} = sprintf("%.2f", $user_info->{DEPOSIT}) if ($user_info->{DEPOSIT} =~ /\d+/);
      }

      if ($user_info->{DEPOSIT} =~ /\d+/ && $user_info->{DEPOSIT} > 0) {
        $user_info->{DEPOSIT_MARK} = 'badge badge-success';
      }
      elsif ($user_info->{DEPOSIT} =~ /\d+/ && $user_info->{DEPOSIT} < 0) {
        $user_info->{DEPOSIT_MARK} = 'badge badge-danger';
      }
      else {
        $user_info->{DEPOSIT_MARK} = 'badge badge-warning';
      }
    }
    else {
      $user_info->{DEPOSIT_MARK} = 'label-warning';
      $user_info->{DEPOSIT} = $html->button($lang{ADD}, "index=" . get_function_index('form_bills') . "&UID=$uid");
    }
  }

  if ($conf{EXT_BILL_ACCOUNT} && $user_info->{EXT_BILL_ID}) {
    if (defined($user_info->{EXT_BILL_DEPOSIT})) {
      if ($conf{DEPOSIT_FORMAT}) {
        $user_info->{EXT_BILL_DEPOSIT} = sprintf("$conf{DEPOSIT_FORMAT}", $user_info->{EXT_BILL_DEPOSIT});
      }

      if ($user_info->{EXT_BILL_DEPOSIT} > 0) {
        $user_info->{EXT_DEPOSIT_MARK} = 'badge badge-success';
      }
      elsif ($user_info->{EXT_BILL_DEPOSIT} < 0) {
        $user_info->{EXT_DEPOSIT_MARK} = 'badge badge-danger';
      }
      else {
        $user_info->{EXT_DEPOSIT_MARK} = 'badge badge-warning';
      }
    }
    else {
      $user_info->{EXT_DEPOSIT_MARK} = 'badge badge-warning';
      $user_info->{EXT_BILL_DEPOSIT} = $html->button($lang{ADD}, "index=" . get_function_index('form_bills') . "&UID=$uid");
    }
  }
  else {
    $user_info->{EXT_DEPOSIT_MARK} = 'badge badge-warning';
    $user_info->{EXT_BILL_DEPOSIT} = ($conf{EXT_BILL_ACCOUNT}) ? $html->button($lang{ADD}, "index=" . get_function_index('form_bills') . "&UID=$uid") : '--';
  }

  $user_info->{REGISTRATION_FORM} = $html->tpl_show(templates('form_row'), {
    ID    => '',
    NAME  => $lang{REGISTRATION},
    VALUE => $user_info->{REGISTRATION} },
    { OUTPUT2RETURN => 1 });

  if ($conf{HOLDUP_ALL}) {
    my $user_status_list = $user_info->user_status_list({ NAME => '_SHOW', COLOR => '_SHOW', COLS_NAME => 1 });
    my %user_status_hash = ();
    my @user_status_style = ();
    foreach my $line (@$user_status_list) {
      my $color = $line->{color} || '';
      $user_status_hash{$line->{id}} = ((exists $line->{name}) ? _translate($line->{name}) : '');

      if (!$attr->{SKIP_COLORS}) {
        $user_status_hash{$line->{id}} .= ":$color" if $attr->{HASH_RESULT};
        $user_status_style[$line->{id}] = '#' . $color;
      }
    }
    $user_info->{FORM_DISABLE} = $html->form_select('DISABLE', {
      SELECTED     => $user_info->{DISABLE},
      SEL_HASH     => \%user_status_hash,
      STYLE        => \@user_status_style,
      SORT_KEY_NUM => 1,
      NO_ID        => 1,
      EXT_BUTTON   => $html->button('', "UID=$uid&Shedule=status&index=$index", {
        class    => 'btn-sm hidden-print text-blue badge',
        ADD_ICON => 'fa fa-calendar',
      })
    });
  }
  else {
    $user_info->{FORM_DISABLE} = "<input class='custom-control-input' type='checkbox' name='DISABLE' id='DISABLE' value='1' data-checked='%DISABLE%' style='display: none;'>
  <label class='custom-control-label' for='DISABLE' id='DISABLE_LABEL'>%DISABLE_LABEL%</label>";
  }

  if ($user_info->{DISABLE} && $user_info->{DISABLE} =~ /\d+/) {
    if ($user_info->{DISABLE} == 1) {
      $user_info->{DISABLE_MARK} = $html->color_mark($html->b($lang{DISABLE}), $_COLORS[6]);
      $user_info->{DISABLE_CHECKBOX} = 'checked';
      $user_info->{DISABLE_COLOR} = 'bg-danger';
      my $list = $admin->action_list({
        UID        => $uid,
        ACTIONS    => '*:*',
        TYPE       => 9,
        PAGE_ROWS  => 1,
        SORT       => 1,
        DESC       => 'DESC',
        SKIP_TOTAL => 1,
        COLS_NAME  => 1
      });

      if ($admin->{TOTAL} > 0) {
        my (undef, $disable_comments) = split(':', $list->[0]->{actions}, 2);
        $user_info->{DISABLE_COMMENTS} = $disable_comments;
      }
    }
    elsif ($user_info->{DISABLE} == 2) {
      if ($permissions{0}{13}) {
        $user_info->{DISABLE_MARK} = $html->button($html->color_mark($html->b("$lang{REGISTRATION} $lang{CONFIRM}"), $_COLORS[8]),
          "index=$index&DISABLE=0&UID=$uid&change=1", { BUTTON => 1 });
      }
      else {
        $user_info->{DISABLE_MARK} = $html->color_mark($html->b("$lang{REGISTRATION} $lang{CONFIRM}"), $_COLORS[8]);
      }
    }

    $user_info->{DISABLE} = ' checked';
    $user_info->{DISABLE_LABEL} = $lang{DISABLE};
  }
  else {
    $user_info->{DISABLE} = '';
    $user_info->{DISABLE_LABEL} = $lang{ACTIV};
  }

  $user_info->{EXDATA} = $html->tpl_show(templates('form_user_exdata'), $user_info, { OUTPUT2RETURN => 1, ID => 'form_user_exdata' });

  if ($conf{EXT_BILL_ACCOUNT}) {
    $user_info->{EXDATA} .= $html->tpl_show(templates('form_ext_bill'), $user_info, { OUTPUT2RETURN => 1 });
  }

  if ($user_info->{EXPIRE} && $user_info->{EXPIRE} ne '0000-00-00') {
    if (date_diff($user_info->{EXPIRE}, $DATE) > 1) {
      $user_info->{EXPIRE_COLOR} = 'badge badge-danger';
      $user_info->{EXPIRE_COMMENTS} = "$lang{EXPIRE}";
    }
  }

  $user_info->{ACTION} = 'change';
  $user_info->{LNG_ACTION} = $lang{CHANGE};

  if ($permissions{5}) {
    my $info_field_index = get_function_index('form_info_fields');
    $user_info->{ADD_INFO_FIELD} = $html->button("$lang{ADD} $lang{INFO_FIELDS}", "index=$info_field_index", { class => 'add', ex_params => ' target=_info_fields' });
  }

  $user_info->{AID} = $admin->{AID};
  $user_info->{A_LOGIN} = $admin->{A_LOGIN};

  if (in_array('Sms', \@MODULES)) {
    # FIXME: check if admin should can send SMS without permission
    $user_info->{PASSWORD} .= $html->button("", "index=$index&header=1&UID=$uid&SHOW_PASSWORD=1&SEND_SMS_PASSWORD=1",
	### START KTK-39
      { class   => 'btn btn-sm btn-info ml-3',
	### END KTK-39
        MESSAGE => "$lang{SEND} $lang{PASSWD} SMS ?",
        ICON    => 'fa fa-envelope',
        TITLE   => "$lang{SEND} $lang{PASSWD} SMS"
      });
  }
	### START KTK-39
  $user_info->{DEPOSIT_MESSAGE} .= $html->button("", "index=$index&header=1&UID=$uid&DEPOSIT_MESSAGE=1",
      { class   => 'btn btn-sm btn-warning',
        MESSAGE => "$lang{SEND} $lang{DEPOSIT} SMS ?",
        ICON    => 'fa fa-money-bill',
        TITLE   => "$lang{SEND} $lang{DEPOSIT} SMS"
      });
	### END KTK-39

  $user_info->{MONTH_NAMES} = "'" . join("', '", @MONTHES) . "'";
  $user_info->{WEEKDAY_NAMES} = "'" . join("', '", $WEEKDAYS[7], @WEEKDAYS[1 .. 6]) . "'";

  if ($attr->{REGISTRATION}) {
    my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr }, { ID => 'form_user', OUTPUT2RETURN => 1 });
    $main_account =~ s/<FORM.+>//ig;
    $main_account =~ s/<\/FORM>//ig;
    $main_account =~ s/<input.+type=submit.+>//ig;
    $main_account =~ s/<input.+index.+>//ig;
    $main_account =~ s/user_form/users_pi/ig;
    user_pi({ MAIN_USER_TPL => $main_account, %$attr });
  }
  elsif ($permissions{0}{24} || ($index && $index != 15)) {
    return $html->tpl_show(templates('form_user'), $user_info, { ID => 'form_user', OUTPUT2RETURN => 1 });
  }
  else {
    if ($permissions{1}) {
      $user_info->{PAYMENTS_BUTTON} = $html->button('', "index=2&UID=" . $uid,
        { ICON      => 'fa fa-plus',
          ex_params => "data-tooltip='$lang{PAYMENTS}' data-tooltip-position='top' class='btn btn-sm btn-secondary'" });
    }

    if ($permissions{2}) {
      $user_info->{FEES_BUTTON} = $html->button('', "index=3&UID=$uid",
        { ICON      => 'fa fa-minus',
          ex_params => "data-tooltip='$lang{FEES}' data-tooltip-position='top' class='btn btn-sm btn-secondary'" });
    }

    if ($permissions{1}) {
      $user_info->{PRINT_BUTTON} = $html->button('', "qindex=$index&STATMENT_ACCOUNT=$uid&UID=$uid&header=2",
        { ICON => 'fas fa-print', target => '_new', ex_params =>
          "data-tooltip='$lang{STATMENT_OF_ACCOUNT}' data-tooltip-position='top' class='btn btn-sm btn-secondary'" });
    }

    if (($user_info->{DEPOSIT_MARK}) && $user_info->{DEPOSIT_MARK} eq 'label-primary') {
      $user_info->{DEPOSIT_MARK} = 'alert-success';
    }

    if (($user_info->{DEPOSIT_MARK}) && $user_info->{DEPOSIT_MARK} eq 'bg-warning') {
      $user_info->{DEPOSIT_MARK} = 'alert-danger';
    }

    if ($permissions{0} && !$permissions{0}{28}) {
      $user_info->{GROUP_PERMISSION} = 'display: none;';
    }

    return $html->tpl_show(templates('form_user_lite'), $user_info, { ID => 'form_user', OUTPUT2RETURN => 1 });
  }

  return 1;
}

#**********************************************************
=head2 form_user_change($attr) - User account add

  Arguments:
    $attr
      USER_INFO - $user_info
      FORM      - \%FORM

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub form_user_change {
  my ($attr) = @_;

  my Users $user_info = $attr->{USER_INFO};
  my $form = $attr->{FORM};

  if ((defined $form->{PASSWORD} && !$permissions{0}{4})) {
    $html->message('err', $lang{ERROR}, "$lang{CHANGE} $lang{PASSWD} : $lang{ERR_ACCESS_DENY}");
    return 0;
  }
  elsif ($form->{g2fa_remove}) {
    $users->pi_change({ UID => $user_info->{UID}, _G2FA => '' });
    $html->message('info', $lang{CHANGED}, $lang{CHANGED} . ' ' . ($users->{info} || ''));
    return 0;
  }

  if (!$permissions{0}{9} && defined($user_info->{CREDIT}) && defined($form->{CREDIT}) && $user_info->{CREDIT} != $form->{CREDIT}) {
    $html->message('err', $lang{ERROR}, "! $lang{CHANGE} $lang{CREDIT} $lang{ERR_ACCESS_DENY}");
    delete($form->{CREDIT});
  }

  if ($admin->{CREDIT_DAYS} && defined($form->{CREDIT}) && sprintf('%.2f', $form->{CREDIT} || 0) > 0) {
    my $max_credit = POSIX::strftime("%Y-%m-%d", localtime(time + 86400 * $admin->{CREDIT_DAYS}));
    if ($form->{CREDIT_DATE} && $form->{CREDIT_DATE} ne '0000-00-00' && date_diff($DATE, $form->{CREDIT_DATE}) > $admin->{CREDIT_DAYS}) {
      $form->{CREDIT_DATE} = $max_credit;
      $html->message('warn', $lang{ERROR}, "Maximum date $max_credit ($admin->{CREDIT_DAYS})");
    }
    elsif ($form->{CREDIT_DATE} && $form->{CREDIT_DATE} eq '0000-00-00') {
      $form->{CREDIT_DATE} = $max_credit;
      $html->message('warn', $lang{ERROR}, "Maximum date $max_credit ($admin->{CREDIT_DAYS})");
    }
  }

  if ($admin->{MAX_CREDIT} && $admin->{MAX_CREDIT} > 0 && $form->{CREDIT} && ($user_info->{CREDIT} != $form->{CREDIT}) && ($admin->{MAX_CREDIT} < $form->{CREDIT})) {
    $html->message('err', $lang{ERROR}, "$lang{CHANGE} $lang{CREDIT} $lang{ERR_ACCESS_DENY}", { ID => 131 });
    delete($form->{CREDIT});
    return 1;
  }

  if (!$permissions{0}{11} && defined($form->{REDUCTION}) && $form->{REDUCTION} > 0 && $user_info->{REDUCTION} != $form->{REDUCTION}) {
    $html->message('err', $lang{ERROR}, "$lang{REDUCTION} $lang{ERR_ACCESS_DENY}", { ID => 132 });
    delete($form->{REDUCTION});
  }

  if (!$permissions{0}{19}) {
    delete($form->{ACTIVATE});
  }
  if (!$permissions{0}{20}) {
    delete($form->{EXPIRE});
  }

  if (!$permissions{0}{13} && $user_info->{DISABLE} =~ /\d+/ && $user_info->{DISABLE} == 2) {
    $form->{DISABLE} = 2;
  }

  if ($conf{FIXED_FEES_DAY} && $form->{ACTIVATE} && $form->{ACTIVATE} ne '0000-00-00') {
    my $d = (split(/-/, $form->{ACTIVATE}))[2];
    if (in_array($d, [ '1', '01', '29', '30', '31' ])) {
      $html->message('info', $lang{CHANGE}, "$lang{ACTIVATE} $form->{ACTIVATE}->0000-00-00");
      $form->{ACTIVATE} = '0000-00-00';
    }
  }

  $FORM{DISABLE_DATE} = ($user_info->{DISABLE} == 0) ? $DATE : '0000-00-00';

  $user_info->change($user_info->{UID}, { %FORM });

  if ($form->{COMPANY_ID}) {
    require Customers;
    Customers->import();
    my $Customer = Customers->new($db, $admin, \%conf);
    my $Company = $Customer->company();

    my $company_info = $Company->list({
      COMPANY_ID  => $form->{COMPANY_ID},
      USERS_COUNT => '_SHOW',
      COLS_NAME   => 1,
    });

    if ($Company->{TOTAL} > 0 && $company_info->[0]->{users_count} == 1) {
      $Company->admins_change({
        COMPANY_ID => $form->{COMPANY_ID},
        IDS        => $user_info->{UID},
      });
      if (!$Company->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{NEW} $lang{ADMIN}");
      }
    }
  }

  if ($user_info->{errno}) {
    _error_show($user_info);
    user_form();
    return 0;
  }
  else {
    $html->message('info', $lang{CHANGED}, $lang{CHANGED} . ' ' . ($users->{info} || ''));
    if (defined($form->{FIO})) {
      $users->pi_change({ %FORM });
    }

    my $credit_changed = 0;
    if ($form->{CREDIT} && defined($user_info->{CREDIT}) && $user_info->{CREDIT} != $form->{CREDIT}) {
      $user_info->{CREDIT} = $form->{CREDIT};
      $credit_changed = 1;
    }

    if ($user_info->{DISABLE} && $user_info->{DISABLE} == 3 && $form->{DISABLE} == 0) {
      require Control::Services;
      my $action = 0;
      service_status_change({ UID => $user_info->{UID}, BILL_ID => $user_info->{BILL_ID} },
        $action,
        { #DEBUG => 4,
          DATE      => $DATE,
          USER_INFO => $user_info
        });
    }
    else {
      cross_modules('payments_maked', { USER_INFO => $user_info, CHANGE_CREDIT => $credit_changed, FORM => \%FORM });
    }
    #External scripts
    if ($conf{external_userchange}) {
      if (!_external($conf{external_userchange}, \%FORM)) {
        return 0;
      }
    }

    if ($attr->{REGISTRATION}) {
      return 1;
    }
  }

  return 1;
}


#**********************************************************
=head2 form_user_add($attr) - User account add

  Argumenst:
    $attr

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub form_user_add {
  my ($attr) = @_;

  if (!$permissions{0}{1}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return 0;
  }

  if ($FORM{newpassword}) {

    $conf{PASSWD_LENGTH} //= 6;

    if (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_SHORT_PASSWD} $conf{PASSWD_LENGTH}");
      return 0;
    }
    elsif ($conf{PASSWD_POLICY_USERS} && $conf{CONFIG_PASSWORD}
      && !Conf::check_password($FORM{newpassword}, $conf{CONFIG_PASSWORD})
    ) {
      load_module('Config', $html);
      my $explain_string = config_get_password_constraints($conf{CONFIG_PASSWORD});

      $html->message('err', $lang{ERROR}, "$lang{ERR_PASSWORD_INSECURE} $explain_string");
      return 0;
    }
    elsif ($FORM{newpassword} eq $FORM{confirm}) {
      $FORM{PASSWORD} = $FORM{newpassword};
    }
    elsif ($FORM{newpassword} ne $FORM{confirm}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_CONFIRM}");
      return 0;
    }
    else {
      $FORM{PASSWORD} = $FORM{newpassword};
    }
  }

  $FORM{REDUCTION} = 100 if ($FORM{REDUCTION} && $FORM{REDUCTION} =~ /\d+/ && $FORM{REDUCTION} > 100);

  # Add not confirm status
  if (!$permissions{0}{13}) {
    $FORM{DISABLE} = 2;
  }

  if ($conf{FIXED_FEES_DAY} && $FORM{ACTIVATE} && $FORM{ACTIVATE} ne '0000-00-00') {
    my $d = (split(/-/, $FORM{ACTIVATE}))[2];

    if (in_array($d, [ 1, 29, 30, 31 ])) {
      $html->message('info', $lang{CHANGE}, "$lang{ACTIVATE} $FORM{ACTIVATE}->0000-00-00");
      $FORM{ACTIVATE} = '0000-00-00';
    }
  }

  if ($conf{AUTH_G2FA} && $conf{G2FA_USER_AUTH}) {
    $FORM{_G2FA} = unique_token_generate(32);
  }

  my Users $user_info = $users->add({ %FORM });

  if (_error_show($users, { MESSAGE =>
    "$lang{LOGIN}: " . (($users->{errno} && $users->{errno} == 7) ? $html->button($FORM{LOGIN}, "index=11&LOGIN=" . ($FORM{LOGIN} || q{})) : '$FORM{LOGIN}')
  })) {
    if ($FORM{NOTIFY_FN}) {
      my $fn = $FORM{NOTIFY_FN};
      if (defined(&$fn)) {
        &{\&{$fn}}({ %FORM, NOTIFY_ID => $FORM{NOTIFY_ID} });
      }
    }

    delete($FORM{add});
    return 0;
  }

  $html->message('info', $lang{ADDED}, "$lang{ADDED} '$user_info->{LOGIN}' / [$user_info->{UID}]");

  if ($FORM{REFERRAL_REQUEST}) {
    require Referral;
    Refferal->import();
    my $Referral = Referral->new($db, $admin, \%conf);

    my $request_list = $Referral->request_list({
      ID        => $FORM{REFERRAL_REQUEST},
      REFERRER  => '_SHOW',
      TP_ID     => '_SHOW',
      COLS_NAME => 1,
    });

    my $tp = $Referral->tp_info($request_list->[0]->{referral_tp});
    my $referrer = $request_list->[0]->{referrer};

    if ($tp->{MULTI_ACCRUAL}) {
      require Referral::Users;
      Referral::Users->import();
      my $Referral_users = Referral::Users->new($db, $admin, \%conf, {
        html => $html,
        lang => \%lang,
      });

      $Referral_users->_referral_add_bonus({
        REFERRER    => $referrer,
        UID         => $user_info->{UID},
        FIO         => $FORM{FIO},
        TOTAL_BONUS => $tp->{BONUS_AMOUNT},
        BONUSES     => [ {
          'FEE_ID'     => 0,
          'UID'        => $user_info->{UID},
          'REFERRER'   => $referrer,
          'SUM'        => $tp->{BONUS_AMOUNT},
          'PAYMENT_ID' => 0,
        } ]
      });

      _error_show($Referral_users);
    }

    $Referral->change_request({
      ID           => $FORM{REFERRAL_REQUEST},
      REFERRAL_UID => $user_info->{UID},
    });
  }

  if ($conf{external_useradd}) {
    if (!_external($conf{external_useradd}, { %FORM })) {
      return 0;
    }
  }

  $user_info = $users->info($user_info->{UID}, { SHOW_PASSWORD => 1 });
  $LIST_PARAMS{UID} = $user_info->{UID};
  $FORM{UID} = $user_info->{UID};
  user_pi({ %$attr, REGISTRATION => 1 });

  $user_info->pi({ UID => $users->{UID} });
  $html->tpl_show(templates('form_user_info'), $user_info, { ID => 'USER_INFORMATION' });

  if ($FORM{NOTIFY_FN}) {
    my $fn = $FORM{NOTIFY_FN};
    if (defined(&$fn)) {
      &{\&{$fn}}({ %FORM, NOTIFY_ID => $FORM{NOTIFY_ID} });
    }
  }

  if ($FORM{COMPANY_ID}) {
    require Control::Companies_mng;
    form_companie_admins($attr);
  }

  return 1;
}


#**********************************************************
=head2 form_users_multiuser($attr) - Multiuser operation

=cut
#**********************************************************
sub form_users_multiuser {

  my @multiuser_arr = split(/, /, $FORM{IDS} || q{});

  my %CHANGE_PARAMS = (
    SKIP_STATUS_CHANGE => $FORM{DISABLE} ? undef : 1
  );

  if ($FORM{MU_COMMENTS}) {
    append_comments(\@multiuser_arr, $FORM{COMMENTS_TEXT});
    delete($FORM{MU_COMMENTS});
  }

  while (my ($k, undef) = each %FORM) {
    if ($k =~ /^MU_(\S+)/) {
      my $val = $1;
      $CHANGE_PARAMS{$val} = $FORM{$val};
    }
  }

  if (!defined($FORM{DISABLE})) {
    $CHANGE_PARAMS{UNCHANGE_DISABLE} = 1;
  }
  else {
    $CHANGE_PARAMS{DISABLE} = $FORM{MU_DISABLE} || 0;
  }

  if ($#multiuser_arr < 0) {
    $html->message('err', $lang{MULTIUSER_OP}, $lang{SELECT_USER});
  }
  elsif (defined($FORM{MU_TAGS} && in_array('Tags', \@MODULES))) {
    require Tags;

    my $Tags = Tags->new($db, $admin, \%conf);

    foreach my $id (@multiuser_arr) {
      $Tags->tags_user_change({
        IDS => $FORM{TAGS_IDS},
        UID => $id,
      });
      $html->message('err', $lang{INFO}, "$lang{TAGS} $lang{NOT} $lang{ADDED} UID:$id") if ($Tags->{errno});
    }
  }
  elsif (defined($FORM{MU_UREPORTS_TP} && in_array('Ureports', \@MODULES))) {
    require Ureports;
    my $Ureports = Ureports->new($db, $admin, \%conf);

    $Ureports->user_list_add({
      TP_ID  => $FORM{UREPORTS_TP},
      STATUS => $FORM{UREPORTS_STATUS},
      UIDS   => $FORM{IDS},
      TYPE   => $FORM{UREPORTS_TYPE}
    });

    $html->message('err', $lang{INFO}, "$lang{TARIF_PLAN} $lang{NOT} $lang{ADDED} UID:$Ureports->{errnostr}") if ($Ureports->{errnostr});
    $html->message('info', $lang{INFO}, "$Ureports->{TOTAL} $lang{ADDED}") if (!$Ureports->{errno});

    $Ureports->tp_user_reports_multi_change({ %FORM, UIDS => $FORM{IDS}, IDS => $FORM{R_IDS}, TP_ID => $FORM{UREPORTS_TP} });
    if (!$Ureports->{errno}) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
    }

  }
  elsif (defined($FORM{MU_BONUS} && in_array('Bonus', \@MODULES)) && $FORM{MU_BONUS} == 1) {
    load_module('Bonus', $html);
    bonus_multi_add(\%FORM);
  }
  elsif ($FORM{MU_DELIVERY} || $FORM{DELIVERY_CREATE}) {
    load_module('Msgs', $html);
    msgs_mu_delivery_add(\%FORM)
  }
  elsif (scalar keys %CHANGE_PARAMS < 1) {
    #$html->message('err', $lang{MULTIUSER_OP}, "$lang{SELECT_USER}");
  }
  else {
    foreach my $uid (@multiuser_arr) {
      if ($FORM{DEL} && $FORM{MU_DEL}) {
        my $user_info = $users->info($uid);
        user_del({ USER_INFO => $user_info });

        _error_show($users);
      }
      else {
        $users->change($uid, { UID => $uid, %CHANGE_PARAMS });
        if (_error_show($users)) {
          return 0;
        }
      }
    }
    $html->message('info', $lang{MULTIUSER_OP}, "$lang{TOTAL}: " . ($#multiuser_arr + 1) . " IDS: $FORM{IDS}");
  }

  return 1;
}

#**********************************************************
=head2 form_users($attr) - User account managment form

  Arguments:
    $attr
      USER_INFO

=cut
#**********************************************************
sub form_users {
  my ($attr) = @_;

  if ($FORM{LOGIN_ERROR}) {
    $html->message("err", $lang{ERROR}, "User with this login already exits");
  }

  if ($FORM{LOGIN_SUCCESS}) {
    $html->message("info", $lang{SUCCESS}, "Login successfully changed");
  }

  if ($FORM{PRINT_CONTRACT}) {
    load_module('Docs', $html);
    docs_contract({ SEND_EMAIL => ($FORM{SEND_EMAIL}) ? 1 : 0 });
    return 1;
  }
  elsif ($FORM{SEND_SMS_PASSWORD}) {
    if (!in_array('Sms', \@MODULES)) {
      $html->message('err', $lang{ERROR}, "SMS not connected");
      return 1;
    }

    load_module('Sms', $html);
    my Users $user_info = $users->info($FORM{UID}, { SHOW_PASSWORD => 1 });
    my $pi = $users->pi({ UID => $FORM{UID} });
    my $message = $html->tpl_show(_include('sms_password_recovery', 'Sms'), { %$user_info, %$pi }, { OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });
    my $sms_id;

    my $sms_number = ($conf{SMS_SEND_ALL})
      ? ($users->{CELL_PHONE_ALL} || $users->{PHONE_ALL})
      : ($users->{CELL_PHONE} || $users->{PHONE});

    $sms_id = sms_send({
      NUMBER  => $sms_number,
      MESSAGE => $message,
      UID     => $users->{UID},
    });

    if ($sms_id) {
      $html->message('info', $lang{INFO}, "$lang{PASSWD} SMS $lang{SENDED}" . (($sms_id > 1) ? "\n ID: $sms_id" : ''));
    }
    return 1;
  }
	### START KTK-39
  elsif ($FORM{DEPOSIT_MESSAGE}) {
    if (!in_array('Sms', \@MODULES)) {
      $html->message('err', $lang{ERROR}, "SMS not connected");
      return 1;
    }

    load_module('Sms', $html);
    my Users $user_info = $users->info($FORM{UID}, { SHOW_PASSWORD => 1 });
    my $pi = $users->pi({ UID => $FORM{UID} });
    my $message = $html->tpl_show(_include('internet_users_warning_messages_sms', 'Internet'), { %$user_info, %$pi }, { OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });
    my $sms_id;

    my $sms_number = ($conf{SMS_SEND_ALL})
      ? ($users->{CELL_PHONE_ALL} || $users->{PHONE_ALL})
      : ($users->{CELL_PHONE} || $users->{PHONE});

    $sms_id = sms_send({
      NUMBER  => $sms_number,
      MESSAGE => $message,
      UID     => $users->{UID},
    });

    if ($sms_id) {
      $html->message('info', $lang{INFO}, "$lang{DEPOSIT} SMS $lang{SENDED}" . (($sms_id > 1) ? "\n ID: $sms_id" : ''));
    }
    return 1;
  }
  ### END KTK-39
  elsif ($FORM{import}) {
    users_import();
    return 1;
  }
  elsif ($FORM{bill_correction}) {
    my $user_info = $attr->{USER_INFO};
    form_bill_correction($user_info);
    return 1;
  }
  elsif ($FORM{SUMMARY_SHOW}) {
    $users->info($FORM{UID});
    delete $FORM{UID};
    if ($users->{UID}) {
      $FORM{UID} = $users->{UID} || 0;
    }

    require Control::Users_slides;
    if ($FORM{EXPORT}) {
      print "Content-Type: application/json; charset=utf8\n\n";
      print user_full_info({ UID => $FORM{UID}, USER_INFO => $users });
    }
    else {
      my $user_info;
      $user_info->{METRO_PANELS} = user_full_info({ USER_INFO => $users });
      $user_info->{METRO_PANELS} =~ s/\r\n|\n//gm;
      $user_info->{HTML_STYLE} = $html->{HTML_STYLE} || 'default';
      $html->tpl_show(templates('form_client_view_metro'), $user_info);
    }
    return 1;
  }

  if ($attr->{USER_INFO}) {
    form_user_profile($attr);
    return 0;
  }
  elsif ($FORM{add}) {
    if (!form_user_add($attr)) {
      return 0;
    }
  }
  elsif ($FORM{MULTIUSER}) {
    form_users_multiuser($attr);
  }

  return 1;
}

#**********************************************************
=head2 form_bill_correction($attr) - Personal information form

=cut
#**********************************************************
sub form_bill_correction {
  my ($attr) = @_;

  if (!$permissions{0} || !$permissions{0}{15}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return 1;
  }

  $attr->{ACTION} = 'change_bill';
  $attr->{LNG_ACTION} = $lang{CHANGE};
  if ($FORM{change_bill}) {
    require Bills;
    Bills->import();
    my $Bill = Bills->new($db, $admin, \%conf);

    _change_bill_id($Bill);

    if ($FORM{DEPOSIT} || $FORM{BILL_ID}) {
      $Bill->change(\%FORM);
      if (!_error_show($Bill)) {
        $html->message('info', $lang{INFO}, $lang{CHANGED});
        $attr->{DEPOSIT} = sprintf("%.2f", $FORM{DEPOSIT} || 0);
        $attr->{BILL_ID} = $FORM{BILL_ID};
      }
    }
  }

  $html->tpl_show(templates('form_bill_deposit'), $attr);

  return 1;
}

#**********************************************************
=head2 _change_bill_id($Bill)

=cut
#**********************************************************
sub _change_bill_id {
  my $Bill = shift;

  return if !$FORM{NEW_BILL_ID} || $FORM{NEW_BILL_ID} eq $FORM{BILL_ID};
  return if ($FORM{NEW_BILL_ID} >= 4294967295);

  my Users $user = Users->new($db, $admin, \%conf);
  my $bill_info = $Bill->info({ BILL_ID => $FORM{NEW_BILL_ID} });

  if (defined $bill_info->{TOTAL} && $bill_info->{TOTAL} < 1) {
    $Bill->create({ ID => $FORM{NEW_BILL_ID}, UID => $FORM{UID} });
    $FORM{BILL_ID} = $FORM{NEW_BILL_ID} if (!_error_show($Bill));
    $user->change($FORM{UID}, { BILL_ID => $FORM{BILL_ID} });
    return;
  }

  if (!$bill_info->{UID} || $bill_info->{UID} eq $FORM{UID}) {
    $FORM{BILL_ID} = $FORM{NEW_BILL_ID};
    $FORM{DEPOSIT} = $bill_info->{DEPOSIT} || 0;

    $user->change($FORM{UID}, { BILL_ID => $FORM{BILL_ID} });
    return;
  }

  my $user_info = $user->info($bill_info->{UID});
  if (defined $user_info->{TOTAL} && $user_info->{TOTAL} < 1) {
    $FORM{BILL_ID} = $FORM{NEW_BILL_ID};
    $FORM{DEPOSIT} = $bill_info->{DEPOSIT} || 0;
    $user->change($FORM{UID}, { BILL_ID => $FORM{BILL_ID} });
  }
  else {
    $html->message('err', $lang{ERROR}, $lang{BILL_LINKED_TO_ANOTHER_USER});
  }
}

#**********************************************************
=head2 form_social_networks($attr)

=cut
#**********************************************************
sub form_social_networks {
  my ($network_info) = @_;

  my ($network, $id) = split(/, /, $network_info);
  $html->message('info', $lang{INFO}, $network_info);
  require AXbills::Auth::Core;
  AXbills::Sender::Core->import();
  my $Auth = AXbills::Auth::Core->new({
    CONF      => \%conf,
    AUTH_TYPE => ucfirst($network)
  });

  return 1 if !$Auth->can('get_info');

  $Auth->get_info({ CLIENT_ID => $id });
  $html->message('err', $lang{ERROR}, "$Auth->{errno} $Auth->{errstr}") if $Auth->{errno};

  my $table = $html->table({ width => '400' });

  foreach my $key (sort keys %{$Auth->{result}}) {
    my $result = '';
    if (ref $Auth->{result}->{$key} eq 'HASH') {
      $result = show_hash($Auth->{result}->{$key}, { OUTPUT2RETURN => 1, DELIMITER => $html->br() });
    }
    elsif (ref $Auth->{result}->{$key} eq 'ARRAY') {
      if ($Auth->{result}->{$key}->[0]->{url} && $Auth->{result}->{$key}->[0]->{url} !~ /.jpg/) {
        $result = join($html->br(), @{$Auth->{result}->{$key}});
      }
      else {
        $result = join($html->br(), $html->img($Auth->{result}->{$key}->[0]->{url}, '', {}));
      }
    }
    else {
      $result = $Auth->{result}->{$key};
    }
    Encode::_utf8_off($result);
    $table->addrow($key, $result);
  }
  print $table->show();

  return 1;
}

#**********************************************************
=head2 user_pi($attr) - Personal information form

  Arguments:
    $attr
      USER_INFO
      PROFILE_MODE


=cut
#**********************************************************
sub user_pi {
  my ($attr) = @_;

  require Attach;
  Attach->import();
  my $Attach = Attach->new($db, $admin, \%conf);
  my Users $user;

  if ($attr->{USER_INFO}) {
    $user = $attr->{USER_INFO};
  }
  elsif ($FORM{UID}) {
    $user = $users->info($FORM{UID});
  }
  elsif ($users) {
    $user = $users;
  }

  if ($FORM{REG} && $FORM{ALL_CONTACT_TYPES}) {
    my @default_types = split(/,/, $FORM{ALL_CONTACT_TYPES});
    require Contacts;
    Contacts->import();
    my $Contacts = Contacts->new($db, $admin, \%conf);

    foreach my $contact_type_id (@default_types) {
      my $contact = $FORM{"CONTACT_TYPE_$contact_type_id"};
      if ($contact && $contact ne '') {
        my @contacts_by_type = split(/,/, $contact);
        foreach my $item (@contacts_by_type) {
          $item =~ s/"//g;
          $item =~ s/'//g;
          $item =~ s/\\//g;
          $Contacts->contacts_add({
            TYPE_ID => $contact_type_id,
            VALUE   => $item,
            UID     => $FORM{UID}
          });
          _error_show($user);
        }
      }
    }
  }

  if ($FORM{SOCIAL_INFO}) {
    form_social_networks($FORM{SOCIAL_INFO});
  }
  elsif ($FORM{PHOTO}) {
    form_image_mng($user);
    return '';
  }
  elsif ($FORM{ATTACHMENT}) {
    if ($FORM{del}) {
      if ($FORM{ATTACHMENT} =~ /(.+):(.+)/) {
        $FORM{TABLE} = $1 . '_file';
        $FORM{ATTACHMENT} = $2;
      }

      $Attach->attachment_del({
        ID    => $FORM{ATTACHMENT},
        TABLE => $FORM{TABLE},
        UID   => $user->{UID}
      });

      if (!_error_show($Attach)) {
        $html->message('info', $lang{INFO}, "$lang{FILE}: '$FORM{ATTACHMENT}' $lang{DELETED}");
      }

      return '';
    }

    form_show_attach({ UID => $user->{UID} });
    return '';
  }
  elsif ($FORM{address}) {
    form_address_sel();
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return '';
    }
    if ($FORM{FIO1} || $FORM{FIO2} || $FORM{FIO3}) {
      $FORM{FIO} = $FORM{FIO1};
    }

    $user->pi_add({ %FORM });
    if (!$user->{errno}) {
      $html->message('info', $lang{ADDED}, $lang{ADDED}) if (!$attr->{REGISTRATION});
    }

    if (in_array('Info', \@MODULES) && $FORM{COMMENTS} && $conf{INFO_ADD_COMMENT_TO_STORY}) {
      _add_user_comment_to_info();
    }

    return '' if ($attr->{REGISTRATION});
  }
  elsif ($FORM{change}) {
    if (!$permissions{0}{4}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return '';
    }
    if ($FORM{FIO1} || $FORM{FIO2} || $FORM{FIO3}) {
      $FORM{FIO} = $FORM{FIO1};
    }
    $user->pi_change({ %FORM });

    if (in_array('Info', \@MODULES) && $FORM{COMMENTS} && $conf{INFO_ADD_COMMENT_TO_STORY}) {
      _add_user_comment_to_info();
    }

    if (!$user->{errno}) {
      $html->message('info', $lang{CHANGED}, $lang{CHANGED});
    }
  }
  elsif ($FORM{CONTACTS}) {
    return user_contacts_renew();
  }

  _error_show($user);

  my $user_pi = $users->pi({ SKIP_LOCATION => 1 });

  if ($user_pi->{TOTAL} < 1 && $permissions{0}{1}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION} = $attr->{ACTION};
      $user_pi->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user_pi->{ACTION} = 'add';
      $user_pi->{LNG_ACTION} = $lang{ADD};
    }
  }
  elsif ($permissions{0}{4}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION} = $attr->{ACTION};
      $user_pi->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user_pi->{ACTION} = 'change';
      $user_pi->{LNG_ACTION} = $lang{CHANGE};
    }
    $user_pi->{ACTION} = 'change';
  }

  $index = 30 if (!$attr->{MAIN_USER_TPL});
  #Info fields
  $user_pi->{INFO_FIELDS} = form_info_field_tpl({ VALUES => $user_pi });

  if (in_array('Docs', \@MODULES)) {
    if ($user_pi->{UID}) {
      $user_pi->{PRINT_CONTRACT} = $html->button($lang{PRINT},
        "qindex=15&UID=$user_pi->{UID}&PRINT_CONTRACT=$user_pi->{UID}" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
        { ex_params => ' target=new', class => 'btn input-group-button', ICON => "fa fa-print" });
    }

    if ($conf{DOCS_CONTRACT_TYPES}) {
      $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
      my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});

      my %CONTRACTS_LIST_HASH = ();
      $FORM{CONTRACT_SUFIX} = "|$user_pi->{CONTRACT_SUFIX}" if ($user_pi->{CONTRACT_SUFIX});
      $user_pi->{CONTRACT_SUFIX} = "($user_pi->{CONTRACT_SUFIX})" if ($user_pi->{CONTRACT_SUFIX});
      foreach my $line (@contract_types_list) {
        my ($prefix, $sufix, $name) = split(/:/, $line);
        $prefix =~ s/ //g;
        $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
      }

      $user_pi->{CONTRACT_TYPE} = $html->form_select('CONTRACT_TYPE', {
        SELECTED => $FORM{CONTRACT_SUFIX},
        SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
        NO_ID    => 1,
        ID       => 'CONTRACT_TYPE',
      });

      $user_pi->{CONTRACT_TYPE} = $html->tpl_show(templates('form_row'), {
        ID    => "CONTRACT_TYPE",
        NAME  => $lang{TYPE},
        VALUE => $user_pi->{CONTRACT_TYPE} },
        { OUTPUT2RETURN => 1 });
    }
  }

  if ($conf{ACCEPT_RULES}) {
    $user_pi->{ACCEPT_RULES_FORM} .= $html->tpl_show(templates('form_row'), {
      ID    => 'ACCEPT_RULES',
      NAME  => $lang{ACCEPT_RULES},
      VALUE => $html->element('span', ($user_pi->{ACCEPT_RULES}) ? $lang{YES} : $lang{NO}, { class => 'badge ' . (($user_pi->{ACCEPT_RULES}) ? 'badge-success' : 'badge-warning') }),
    },
      { OUTPUT2RETURN => 1 });
  }

  require Contacts;
  Contacts->import();
  my $Contacts = Contacts->new($db, $admin, \%conf);

  my $user_contacts_list = $Contacts->contacts_list({
    UID      => $FORM{UID},
    VALUE    => '_SHOW',
    DEFAULT  => '_SHOW',
    PRIORITY => '_SHOW',
    COMMENTS => '_SHOW',
    TYPE     => '_SHOW',
    HIDDEN   => '0'
  });
  _error_show($Contacts);

  my $user_contact_types = $Contacts->contact_types_list({
    SHOW_ALL_COLUMNS => 1,
    COLS_NAME        => 1,
    HIDDEN           => '0',
  });
  _error_show($Contacts);

  # Translate type names
  map {$_->{name} = $lang{$_->{name}} || $_->{name}} @{$user_contact_types};

  $user_pi->{CONTACTS} = _build_user_contacts_form($user_contacts_list, $user_contact_types);

  my @header_arr = (
    "$lang{MAIN}:#_user_main:data-toggle='tab' aria-expanded='true'",
    "$lang{ADDRESS}:#_address:data-toggle='tab'",
    "$lang{PASPORT}:#_pasport:data-toggle='tab'",
    "$lang{COMMENTS}:#_comment:data-toggle='tab'",
    "$lang{OTHER}:#__other:data-toggle='tab'",
    "$lang{CONTACTS}:#_contacts_content:data-toggle='tab'"
  );

  $user_pi->{HEADER} = $html->table_header(\@header_arr, { TABS => 1, ACTIVE => '#_user_main' });
  $user_pi->{HEADER2} = $html->table_header(\@header_arr, { TABS => 1, SHOW_ONLY => 2, ACTIVE => '#_main' });

  require Control::Contracts_mng;
  $user_pi->{CONTRACTS_TABLE} = _user_contracts_table($FORM{UID});

  if ($user_pi->{FIO2} && $user_pi->{FIO3}) {
    $user_pi->{FIO_READONLY} = 'disabled';
  }

  if (!$attr->{QUICK_FORM} && ($permissions{0}{24} || ($FORM{index} && $FORM{index} != 15))) {
    my $ext_address = $html->tpl_show(templates('form_ext_address'), { %$user_pi }, { ID => 'ext_address', OUTPUT2RETURN => 1 });
    $attr->{DISTRICT_SELECT_ID} = 'USER_DISTRICT_ID';
    $attr->{STREET_SELECT_ID} = 'USER_STREET_ID';
    $attr->{BUILD_SELECT_ID} = 'USER_BUILD_ID';

    $user_pi->{ADDRESS_TPL} = form_address({
      # Can be received from MSGS reg_request
      %$attr,
      %$user_pi,
      SHOW               => 0,
      SHOW_BUTTONS       => 1,
      SHOW_ADD_BUTTONS   => 1,
      ADDRESS_HIDE       => $conf{ADDRESS_FORM_OPEN} ? 0 : 1,
      EXT_ADDRESS        => $ext_address,
      CHECK_ADDRESS_FLAT => $conf{REG_CHECK_ADDRESS_FLAT}
    });

    #if (in_array('Docs', \@MODULES)) {
    $user_pi->{DOCS_TEMPLATE} = $html->tpl_show(_include('docs_form_pi_lite', 'Docs'), { %{$user_pi}, %{$attr} }, { OUTPUT2RETURN => 1 });
    #}

    my $pi_form = $html->tpl_show(templates('form_pi'), {
      FORM_ATTR => 'container-md pr-0 pl-0',
      UID       => $LIST_PARAMS{UID},
      %$attr,
      %$user_pi
    }, { ID => 'form_pi', OUTPUT2RETURN => 1 });

    if ($attr->{PROFILE_MODE}) {
      return $pi_form;
    }

    print $pi_form;
  }
  else {
    my $uid = $FORM{UID} || q{};
    if (-f "$conf{TPL_DIR}/if_image/" . $uid . '.jpg') {
      $user_pi->{PHOTO} = "/images/if_image/" . $uid . '.jpg';
    }
    else {
      $user_pi->{PHOTO} = "/styles/default/img/admin/avatar0.png";
    }

    my $location_id = $FORM{LOCATION_ID} || $user_pi->{LOCATION_ID};


    #if (in_array('Docs', \@MODULES)) {
    $user_pi->{DOCS_TEMPLATE} = $html->tpl_show(_include('docs_form_pi_lite', 'Docs'), { %{$user_pi} }, { OUTPUT2RETURN => 1 });
    #}

    if ($user_pi->{CONTRACT_ID}) {
      $user_pi->{CONTRACT_ID_DATE} = "$user_pi->{CONTRACT_ID}, $user_pi->{CONTRACT_DATE}";
    }

    my $user_contacts_list = $Contacts->contacts_list({
      UID       => $FORM{UID},
      TYPE      => '1;2',
      VALUE     => '_SHOW',
      COMMENTS  => '_SHOW',
      HIDDEN    => '_SHOW',
      SORT      => 'priority',
      COLS_NAME => 1,
    });
    _error_show($Contacts);

    if ($Contacts->{TOTAL} && $Contacts->{TOTAL} > 0) {
      $user_pi->{CALLTO_HREF} = "callto:" . ($user_contacts_list->[0]->{value} || q{});
    }
    $user_pi->{PHONE} = join(';', map {$_->{value} || q{}} @$user_contacts_list);

    $users->{conf}->{BUILD_DELIMITER} //= ', ';
    $user_pi->{ADDRESS_FLAT} //= q{};
    if ($conf{ADDRESS_REGISTER}) {
      $user_pi->{ADDRESS_STR} = full_address_name($location_id) . $users->{conf}->{BUILD_DELIMITER} . $user_pi->{ADDRESS_FLAT};
    }
    else {
      $user_pi->{ADDRESS_STR} = (($user_pi->{CITY}) ? "$user_pi->{CITY}, " : "") . ($user_pi->{ADDRESS_STREET} || q{}) . ' ' . ($user_pi->{ADDRESS_BUILD} || q{}) . '/' . ($user_pi->{ADDRESS_FLAT} || q{});
    }

    if (!$permissions{0}{26}) {
      $user_pi->{PHONE} = $lang{HIDE};
      $user_pi->{ADDRESS_STR} = $lang{HIDE};
      $user_pi->{PASPORT_NUM} = '';
      $user_pi->{PASPORT_DATE} = '';
      $user_pi->{PASPORT_GRANT} = '';
      $user_pi->{BIRTH_DATE} = '';
      $user_pi->{REG_ADDRESS} = '';
      $user_pi->{TAX_NUMBER} = '';
    }

    if ($permissions{0}{4}) {
      $user_pi->{EDIT_BUTTON} = $html->button('', "index=30&UID=" . ($user_pi->{UID} || q{}),
        { class => 'btn btn-tool', ICON => 'fa fa-edit' });
    }

    return $html->tpl_show(templates('form_pi_lite'), $user_pi, { OUTPUT2RETURN => 1, ID => 'user_pi' });
  }

  return '';
}

#**********************************************************
=head2 user_form($attr) - Main user form

  Arguments:
    $attr
      USER_INFO

=cut
#**********************************************************
sub user_form {
  my ($attr) = @_;
  $attr->{HIDE_COMPANY} = 'hidden'; #hide unused company fields in registration wizard

  if ($FORM{create_company}) {
    require Customers;
    Customers->import();
    my $Customer = Customers->new($db, $admin, \%conf);
    my $Company = $Customer->company();
    $FORM{COMPANY_NAME} = $FORM{COMPANY_NAME} || $FORM{FIO} || $FORM{LOGIN} || "";
    $Company->add({
      CREATE_BILL  => 1,
      NAME         => $FORM{COMPANY_NAME},
      LOCATION_ID  => $FORM{LOCATION_ID},
      ADDRESS_FLAT => $FORM{ADDRESS_FLAT},
    });
    if ($Company->{errno}) {
      $html->message('err', $lang{ERROR},
        "$lang{ERROR} " . "Can't create company '$FORM{COMPANY_NAME}'");
      return 0;
    }
    $FORM{COMPANY_ID} = $Company->{INSERT_ID};
  }

  $index = 15 if (!$attr->{ACTION} && !$attr->{REGISTRATION});
  my $user_info = $attr->{USER_INFO};

  if ($conf{ACT_EXP_BTN_HIDE}) {
    $user_info->{ACT_EXP_BTN_HIDE} = 'display: none;';
  }

  if ($index == 24) { #XXX is there template where disable form and password buttons should be displayed together?
    $user_info->{HIDE_PASSWORD} = "style='display: none;'";
  }
  else {
    $user_info->{HIDE_DISABLE_FORM} = "style='display: none;'";
  }

  if ($FORM{STATMENT_ACCOUNT}) {
    load_module('Docs', $html);
    docs_statement_of_account();
    exit;
  }
  elsif ($FORM{add} || $FORM{change}) {
    return form_users($attr);
  }
  elsif (!$attr->{USER_INFO}) {
    if ($conf{REG_SURELY_VALUE}) {
      map $attr->{$_ . '_REQ'} = 'required', split(/,\s?/, $conf{REG_SURELY_VALUE});
    }

    $user = Users->new($db, $admin, \%conf);

    if ($FORM{COMPANY_ID}) {
      require Customers;
      Customers->import();
      my $customers = Customers->new($db, $admin, \%conf);
      my $company = $customers->company->info($FORM{COMPANY_ID});
      $user_info->{COMPANY_ID} = $FORM{COMPANY_ID};
      $user_info->{EXDATA} = $html->tpl_show(templates('form_row'), {
        ID    => "",
        NAME  => "$lang{COMPANY} ",
        VALUE => $html->element('p', $company->{NAME}, { class => 'form-control-static', OUTPUT2RETURN => 1 }),
      }, { OUTPUT2RETURN => 1 });
    }

    if ($index == 24 && !$FORM{COMPANY_ID}) {
      $attr->{CREATE_COMPANY} = $html->element('div',
        $html->tpl_show(templates('form_row_checkbox'), {
          ID        => "create_company_wrapper",
          LABEL_FOR => 'create_company',
          CLASS     => 'col-md-6 col-xs-12',
          NAME      => "$lang{CREATE_COMPANY} ",
          INPUT     => $html->form_input('create_company', "1", { TYPE => 'checkbox', class => 'form-check-input', OUTPUT2RETURN => 1 }),
        }, { OUTPUT2RETURN => 1 }), { class => 'col-md-6 row', OUTPUT2RETURN => 1 });

      if ($conf{MAX_USERNAME_LENGTH} && $conf{USERNAMEREGEXP}) {
        my $leng = $conf{MAX_USERNAME_LENGTH};
        my $expr = $conf{USERNAMEREGEXP};
        $expr =~ s/\*/\{0,$leng\}/;
        $attr->{LOGIN_PATTERN} = $expr;
      }
    }

    if ($admin->{GID}) {
      $attr->{GID} = sel_groups({ SKIP_MULTISELECT => 1, EX_PARAMS => $attr->{GROUP_REQ} });
    }
    else {
      $FORM{GID} = $attr->{GID};
      $attr->{GID} = sel_groups({ SKIP_MULTISELECT => 1, EX_PARAMS => $attr->{GROUP_REQ} });
    }

    $user_info->{EXDATA} .= $html->tpl_show(templates('form_user_exdata_add'),
      { %$user_info, %$attr, CREATE_BILL => ' checked' }, { OUTPUT2RETURN => 1 });

    if ($conf{EXT_BILL_ACCOUNT}) {
      $user_info->{EXDATA} .= $html->tpl_show(templates('form_ext_bill_add'), $user_info, { OUTPUT2RETURN => 1 });
    }

    if ($user_info->{DISABLE} && $user_info->{DISABLE} > 0) {
      $user_info->{DISABLE} = ' checked';
      if ($user_info->{DISABLE} == 5) {
        $user_info->{DISABLE_MARK} = $html->color_mark($html->b("$lang{NOT} $lang{CONFIRM}"), $_COLORS[7]);
      }
      else {
        $user_info->{DISABLE_MARK} = $html->color_mark($html->b($lang{DISABLE}), $_COLORS[6]);
        $user_info->{DISABLE_COLOR} = 'bg-warning';
      }
    }

    $user_info->{MONTH_NAMES} = "'" . join("', '", @MONTHES) . "'";
    $user_info->{WEEKDAY_NAMES} = "'" . join("', '", $WEEKDAYS[7], @WEEKDAYS[1 .. 6]) . "'";

    my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1, ID => 'form_user' });

    $user_info->{PW_CHARS} = $conf{PASSWD_SYMBOLS} || "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ";
    $user_info->{PW_LENGTH} = $conf{PASSWD_LENGTH} || 6;
    $user_info->{CONFIG_PASSWORD} = $conf{CONFIG_PASSWORD} || '';

    if (!$FORM{generated_pw} || !$FORM{newpassword} || !$FORM{confirm}) {
      $user_info->{newpassword} = mk_unique_value($user_info->{PW_LENGTH}, {
        SYMBOLS     => $user_info->{PW_CHARS},
        EXTRA_RULES => defined($conf{PASSWD_SYMBOLS}) ? undef : $conf{CONFIG_PASSWORD},
      });
      $user_info->{confirm} = $user_info->{newpassword};
    }
    $attr->{G2FA_HIDDEN} = 'hidden';
    $main_account .= $html->tpl_show(templates('form_password'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1 });

    $main_account =~ s/<FORM.+>//ig;
    $main_account =~ s/<\/FORM>//ig;
    $main_account =~ s/<input.+type=submit.+>//ig;
    $main_account =~ s/<input.+index.+>//ig;
    $main_account =~ s/user_form/users_pi/ig;

    print user_pi({ MAIN_USER_TPL => $main_account, %$attr, CHECK_ADDRESS_FLAT => $conf{REG_CHECK_ADDRESS_FLAT} });
  }
  elsif ($FORM{USER_PORTAL} && $permissions{0}{3}) {
    my $login_url = $SELF_URL;
    $login_url =~ s/admin//;
    $conf{WEB_AUTH_KEY} = 'LOGIN' if (!$conf{WEB_AUTH_KEY});

    # delete old cookie if present
    $users->web_session_del({ SID => $COOKIES{sid} || '--' });

    my $_login = urlencode($user_info->{LOGIN} || q{});
    my $_password = urlencode($user_info->{PASSWORD} || q{});

    if ($conf{WEB_AUTH_KEY} eq 'LOGIN') {
      $html->redirect("$login_url?user=$_login&passwd=$_password", { WAIT => 0 });
      exit 0;
    }
    else {
      my @a_method = split(/,/, $conf{WEB_AUTH_KEY});
      my $method = $a_method[0];

      my $users_list = $users->list({
        $method   => '_SHOW',
        UID       => $user_info->{UID},
        COLS_NAME => 1
      });

      my $met = lc $method;
      my $info = $users_list->[0]->{$met};

      exit 0 unless ($info);

      if ($method eq "PHONE") {
        $info =~ s/\+/\%2B/g;
      }

      $html->redirect("$login_url?user=$info&passwd=$user_info->{PASSWORD}", { WAIT => 0 });
      exit 0;
    }
  }
  elsif ($FORM{SHOW_PASSWORD} && $permissions{0}{3}) {
    $conf{WEB_AUTH_KEY} = 'LOGIN' if (!$conf{WEB_AUTH_KEY});

    if ($conf{WEB_AUTH_KEY} eq 'LOGIN') {
      print _user_auth_data_modal_content(
        [ $user_info->{LOGIN}, $user_info->{PASSWORD} ],
        [ 'LOGIN', 'PASSWD' ]
      );
      exit 0;
    }
    else {
      my @a_method = split(/,/, $conf{WEB_AUTH_KEY});
      my $method = $a_method[0];

      my $users_list = $users->list({
        $method   => '_SHOW',
        UID       => $user_info->{UID},
        COLS_NAME => 1
      });

      my $met = lc $method;
      my $info = $users_list->[0]->{$met};
      if (defined $info) {
        print _user_auth_data_modal_content(
          [ $info, $user_info->{PASSWORD} ],
          [ $method, 'PASSWD' ]
        );
        exit 0;
      }
      else {
        $html->message('err', "$lang{ERROR}", "$lang{AUTH_WEB_ERROR} $method -- $lang{PASSWD}: '$user_info->{PASSWORD}'");
        exit 0;
      }
    }
  }
  else {
    my $credit_describe = $admin->action_list({
      TYPE       => 5,
      UID        => $user_info->{UID},
      DATETIME   => '_SHOW',
      COLS_NAME  => 1,
      PAGE_ROWS  => 1,
      SORT       => 'id DESC',
      PAGE_ROWS  => 1,
      SKIP_TOTAL => 1
    });

    if ($credit_describe->[0] && $credit_describe->[0]{datetime}) {
      $user_info->{DATE_CREDIT} = $credit_describe->[0]{datetime};
    }
    else {
      $user_info->{DATE_CREDIT} = '0000-00-00';
    }

    return form_user_info({ USER_INFO => $user_info, FORM => \%FORM });
  }

  return 1;
}


#**********************************************************
=head2 user_info_items($uid, $user_info)

=cut
#**********************************************************
sub user_info_items {
  my ($uid, $user_info) = @_;

  my @items_arr = ();

  my %userform_menus = (
    103 => $lang{SHEDULE},
    22  => $lang{LOG},
    21  => $lang{COMPANY},
    12  => $lang{GROUP},
    18  => $lang{NAS},
    19  => $lang{BILL}
  );

  $userform_menus{17} = $lang{PASSWD} if ($permissions{0}{3});

  while (my ($k, $v) = each %uf_menus) {
    $userform_menus{$k} = $v;
  }

  foreach my $k (sort {$b <=> $a} keys %userform_menus) {
    my $v = $userform_menus{$k};
    my $url = "index=$k&UID=$uid";
    my $active = (defined($FORM{$k})) ? $html->b($v) : $v;
    my $function_name = $functions{$k} || q{};

    my $info = '';
    if ($function_name eq 'msgs_admin') {
      require Msgs::New;
      my $count = msgs_new({ ADMIN_UNREAD => $uid });
      if ($count && $count > 0) {
        $info = $html->badge($count, { TYPE => 'badge badge-danger' });
      }
    }
    elsif ($function_name eq 'form_shedule') {
      require Shedule;
      Shedule->import();

      my $Shedule = Shedule->new($db, $admin, \%conf);

      $Shedule->list({ UID => $uid });
      if ($Shedule->{TOTAL}) {
        $info = $html->badge($Shedule->{TOTAL}, { TYPE => 'badge badge-warning' });
      }
    }

    push @items_arr, "$active $info:$url";
  }

  my $full_delete = '';
  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8} && ($user_info->{DELETED})) {
    push @items_arr, "$lang{UNDELETE}:index=15&del_user=1&UNDELETE=1&UID=$uid:MESSAGE=$lang{UNDELETE} $lang{USER}: $user_info->{LOGIN} / $uid";
    $full_delete = "&FULL_DELETE=1";
  }

  push @items_arr, "$lang{DEL}:index=15&del_user=1&UID=$uid$full_delete:MESSAGE=$lang{USER}: $user_info->{LOGIN} / $uid" if (defined($permissions{0}{5}));

  return @items_arr;
}
#**********************************************************
=head2 user_services($attr)

  Arguments:
    USER_INFO
    PROFILE_MODE

  Return:

=cut
#**********************************************************
sub user_services {
  my ($attr) = @_;

  my $user_info = $attr->{USER_INFO};

  my $active = ' active';
  delete($FORM{search_form});

  if ($FORM{json} || $FORM{xml}) {
    foreach my $module (@MODULES) {
      $FORM{MODULE} = $module;
      my $service_func_index = 0;
      foreach my $key (sort keys %menu_items) {
        if (defined($menu_items{$key}{20})) {
          $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
        }
      }

      if ($service_func_index) {
        $index = $service_func_index;
        if (defined($module{$index})) {
          load_module($module{$index}, $html);
        }
        _function($service_func_index, { USER_INFO => $user_info });
      }
    }

    return q{};
  }

  my $service_start = 0;
  if ($FORM{DEBUG} && $FORM{DEBUG} > 4) {
    $service_start = check_time();
  }

  my $service_func_index = 0;
  my $service_func_menu = '';

  my $uid = $user_info->{UID} || q{};

  foreach my $key (sort keys %menu_items) {
    if (defined($menu_items{$key}{20})) {
      $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
    }

    if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
      $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$uid&index=$key", {
        class     => 'btn btn-primary btn-xs',
        ex_params => 'style="margin: 0 0 3px 3px;"'
      });
    }
  }

  $service_func_menu = "<div class='form-group'>$service_func_menu</div>" if (!$FORM{json});

  my ($service_info0, $service_info1, $service_info2, $service_info3);
  my $module = $FORM{MODULE} || $module{$service_func_index} || $MODULES[0];
  load_module($module, $html);
  if ($service_func_index) {
    $active = '';
    $index = $service_func_index;
    ($service_info0, $service_info1, $service_info2, $service_info3) = _function($service_func_index, {
      USER_INFO    => $user_info,
      MENU         => $service_func_menu,
      PROFILE_MODE => $attr->{PROFILE_MODE}
    });

    $service_info3 .= gen_time($service_start) if ($FORM{DEBUG} && $FORM{DEBUG} > 4);
  }

  return $service_info0, $service_info1, $service_info2, $service_info3;
}

#**********************************************************
=head2 user_service_menu($attr) -

  Arguments:
    $attr
      SERVICE_FUNC_INDEX
      PAGES_QS
      UID

  Returns:
    $service_func_menu

=cut
#**********************************************************
sub user_service_menu {
  my ($attr) = shift;

  my $service_func_index = $attr->{SERVICE_FUNC_INDEX};
  my $uid = $attr->{UID} || 0;
  my $pages_qs = $attr->{PAGES_QS} || q{};
  my $service_func_menu = q{};

  if ($attr->{MK_MAIN}) {
    $service_func_menu .= $html->button("$lang{INFO}", "UID=$uid&index=$service_func_index$pages_qs", {
      class     => 'btn btn-xs ' . (($index == $service_func_index) ? 'btn-danger' : 'btn-primary'),
      ex_params => 'style="margin: 0 0 3px 3px;"'
    })
  }

  foreach my $key (sort keys %menu_items) {
    if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
      $service_func_menu .= $html->button("$menu_items{$key}{$service_func_index}", "UID=$uid&index=$key$pages_qs", {
        class     => 'btn btn-xs ' . (($index == $key) ? 'btn-danger' : 'btn-primary'),
        ex_params => 'style="margin: 0 0 3px 3px;"'
      });
    }
  }

  $attr->{SERVICE_FUNC_INDEX} = $service_func_index;

  return $service_func_menu;
}

#**********************************************************
=head2 user_right_menu($uid, $LOGIN, $attr) - User extra menu

  Arguments:
    $uid
    $LOGIN
    $attr

=cut
#**********************************************************
sub user_right_menu {
  my ($uid, $user_info, $attr) = @_;

  if (!$uid) {
    return '[unknown user]'
  }

  if ($FORM{xml} || $FORM{csv} || $FORM{json} || $FORM{EXPORT_CONTENT}) {
    return $user_info->{LOGIN};
  }

  my @user_info_arr = user_info_items($uid, $user_info);
  my @items_arr = ();

  my $html_content = "";
  my $qs = $ENV{QUERY_STRING};
  $qs =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
  my $section_title = '';
  my $i = 0;

  label:

  if ($section_title) {
    $html_content .= "<ul class='nav nav-sidebar mb-3'>";
    $html_content .= $html->element('h5', $section_title);
  }

  foreach my $element (@items_arr) {
    my ($name, $url, $extra) = split(/:/, $element, 3);
    my $active = '';
    if (!$url) {
      $active = 'active';
    }
    elsif ($url eq $qs) {
      $active = 'active';
    }
    else {
      my @url_argv = split(/&/, $url);
      my %params_hash = ();
      foreach my $line (@url_argv) {
        my ($k, $v) = split(/=/, $line);
        $params_hash{($k || '')} = $v;
      }

      if ($params_hash{index} && $FORM{index} && $params_hash{index} eq $FORM{index} && $attr->{USE_INDEX}) {
        $active = 'active';
      }
    }

    my %url_params = ();

    if ($extra) {
      if ($extra =~ /MESSAGE=(.+)/) {
        $url_params{MESSAGE} = $1;
      }

      if ($extra =~ /class=(.+)/) {
        $url_params{class} = $1;
      }
    }
    $html_content .= $html->li($html->button("<i class='nav-icon far fa-circle'></i>$name", $url, \%url_params), { class => "$active user-menu nav-item" });
  }

  if ($section_title) {
    $html_content .= "</ul>";
  }

  if ($i <= 1) {
    if ($i eq 0) {
      @items_arr = ();
      foreach my $key (sort {$a <=> $b} keys %menu_items) {
        if (defined($menu_items{$key}{20})) {
          if (in_array($module{$key}, \@MODULES)) {

            #Skip Docs for service
            if ($module{$key} && $module{$key} eq 'Docs') {
              next;
            }

            next if $module{$key} !~ /^[\w.]+$/;

            my $info = '';
            my $plugin_name = $module{$key} . '::Base';

            my $plugin_path = $plugin_name . '.pm';
            $plugin_path =~ s{::}{/}g;
            eval {require $plugin_path};

            my $function_name = lc $module{$key} . '_quick_info';

            if (!$@ && $plugin_name->can('new') && $plugin_name->can($function_name)) {
              my $plugin_api = $plugin_name->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

              eval {
                my $services = $plugin_api->$function_name({
                  LOGIN    => $FORM{LOGIN} || $user_info->{LOGIN},
                  FN_INDEX => $key,
                  FORM     => \%FORM
                });

                if ($services) {
                  my $badget_type = q{};
                  if ($services =~ s/^!//) {
                    $badget_type = 'badge-danger';
                  }
                  $info = $html->badge($services, { TYPE => $badget_type });
                }
              };
            }

            push @items_arr, "$menu_items{$key}{20} $info:UID=$uid&index=" . ($key || 0);
          }
        }
      }
      $section_title = $lang{SERVICES};
    }
    elsif ($i eq 1) {
      @items_arr = @user_info_arr;
      $section_title = $lang{OTHER};
    }

    $i++;
    goto label;
  }

  $html_content = $html->element('ul', $html_content, { class => 'nav nav-pills nav-sidebar' });

  $admin->{USER_MENU} = $html_content;

  return 1;
}


#**********************************************************
=head2 user_ext_menu($uid, $LOGIN, $attr) - User extra menu

  Arguments:
    $uid
    $LOGIN
    $attr
      class

=cut
#**********************************************************
sub user_ext_menu {
  my ($uid, $user_name, $attr) = @_;

  if (!$uid) {
    return '[unknown user]'
  }

  if ($FORM{xml} || $FORM{csv} || $FORM{json} || $FORM{EXPORT_CONTENT}) {
    return $user_name;
  }

  my $ex_params = ($attr->{dv_status_color}) ? "style='color:#$attr->{dv_status_color}'" : '';
  my $icon_class = (defined($attr->{login_status}) && $state_icon_colors[ $attr->{login_status} ]) ? $state_icon_colors[ $attr->{login_status} ] : '';
  my $btn_size = (defined($attr->{class}) && $attr->{class} eq 'profile-username') ? 'btn-sm' : 'btn-xs';

  my $ext_menu = $html->button("", "index=15&UID=$uid", {
    class     => "btn btn-default $btn_size btn-user mr-1 $icon_class" . (($attr->{deleted}) ? ' disabled' : ''),
    ICON      => 'fas fa-user',
    ex_params => $ex_params
  });

  my $return = $ext_menu;

  if ($permissions{0}{27} && !$attr->{NO_CHANGE}) {
    $return .= $html->button("$lang{CHANGE} $lang{LOGIN}", "qindex=15&UID=$uid&edit_login=" . ($attr->{LOGIN} || q{}) . "&header=2", {
      ICON          => 'fa fa-pencil-alt',
      LOAD_TO_MODAL => 1,
      MODAL_SIZE    => 'xl',
      class         => "btn btn-default $btn_size mr-1",
    });
  }

  if ($attr->{SHOW_UID}) {

    my $uid_text = $html->element('span',
      $html->b("UID: $uid"),
      { class => 'h6', style => 'line-height: 1.375' }
    );

    my $uid_title = $html->element('a',
      $uid_text,
      {
        class                   => 'btn btn-default btn-sm m-0 mx-1 align-middle',
        'onclick'               => "copyToBuffer('$uid', true)",
        'data-tooltip'          => "$lang{COPIED}!",
        'data-tooltip-position' => 'top',
        'data-tooltip-onclick'  => '1',
      }
    );

    $return .=
      $html->button($html->b($user_name), "index=15&UID=$uid",
        { class => 'h5 mx-3 text-lightblue align-middle', TITLE => $user_name })
        . $uid_title;
  }
  else {
    $return .= $html->button(
      ($user_name ? $user_name : q{}),
      "index=15&UID=$uid" . (($attr->{EXT_PARAMS}) ? "&$attr->{EXT_PARAMS}" : ''),
      {
        TITLE => $attr->{TITLE},
        class => $attr->{class}
      }
    );
  }

  return $return;
}

#**********************************************************
=head2 user_info($uid, $attr) - User info panel

  Arguments:
    $uid, $attr

  Results:
    $user_info->{TABLE_SHOW}


  Examples:


=cut
#**********************************************************
sub user_info {
  my ($uid, $attr) = @_;

  if ($FORM{edit_login}) {
    if ($FORM{new_login}) {
      $users->list({ LOGIN => $FORM{LOGIN} });
      if (($users->{TOTAL} == 1 && !($FORM{edit_login} eq $FORM{LOGIN})) || $users->{TOTAL} > 1) {
        $FORM{LOGIN_ERROR} = 1;
      }
      elsif (!$users->{TOTAL}) {
        $uid = $FORM{UID};
        $users->change($uid, {
          ID  => $FORM{LOGIN},
          UID => $uid
        });
        $FORM{LOGIN_SUCCESS} = 1;
      }
    }
    else {
      $html->tpl_show(templates('form_change_login'), {
        LOGIN      => $FORM{edit_login},
        BTN_LNG    => $lang{CHANGE},
        BTN_ACTION => 'new_login',
        %FORM
      });
      return 0;
    }
  }

  my $user_info = $users->info($uid, $attr);
  my @admin_groups = split(/,s?/, $admin->{GID});

  if ($uid && $users->{errno}) {
    if (!$attr || !$attr->{QUITE}) {
      _error_show($users, { MESSAGE => "$lang{USER} '$uid' ", ID => '005' });
    }
    return $users;
  }
  elsif (!$users->{TOTAL} && !$attr->{UID}) {
    return 0;
  }
  elsif ($#admin_groups > -1 && $admin_groups[0] && !in_array($users->{GID}, \@admin_groups)) {
    $html->message('err', $lang{ERROR}, "ACCESS_DENY GID: $users->{GID} NOT_ALLOW", { ID => 5 });
    return 0;
  }
  else {
    if ($users->{errno}) {
      if (!$attr || !$attr->{QUITE}) {
        _error_show($users, { MESSAGE => "$lang{USER} '" . ($uid || q{}) . "' " });
      }
      return $users;
    }
    $uid = $user_info->{UID};
  }

  if ($LIST_PARAMS{FIO} && $LIST_PARAMS{FIO} ne '_SHOW') {
    $LIST_PARAMS{FIO} = '_SHOW';
  }

  my $del_class = '';
  my $deleted = '';
  my $domain_id = '';

  if ($user_info->{DELETED}) {
    $deleted = $html->b($lang{DELETED});
    $del_class = ' alert-danger';
  }

  my $user_name = '';
  if ($conf{USER_PANEL}) {
    my @params = split(/,s?/, $conf{USER_PANEL});

    my %user_list_params = map {$_ => '_SHOW'} @params;

    my $user_list = $users->list({
      %user_list_params,
      UID       => $uid,
      COLS_NAME => 1
    });

    my $extra_user_info = $user_list->[0];

    my @arr = ();
    foreach my $info (@params) {
      push @arr, ($extra_user_info->{lc($info)} || '');
    }

    $user_name = join(' / ', @arr);
  }
  else {
    $user_name = $user_info->{LOGIN};
  }

  my $ext_menu = user_ext_menu($uid, $user_name, {
    SHOW_UID     => 1,
    login_status => $user_info->{DISABLE},
    deleted      => $user_info->{DELETED},
    LOGIN        => $user_info->{LOGIN},
    class        => 'profile-username'
  });

  if (!$admin->{DOMAIN_ID} && $user_info->{DOMAIN_ID}) {
    $domain_id = " DOMAIN: $user_info->{DOMAIN_ID}";
  }

  my $pre_button = $html->button(" ", "index=$index&UID=$uid&PRE=$uid",
    { class => 'float-left btn btn-default', ICON => 'fa fa-arrow-left', TITLE => $lang{BACK} });
  my $next_button = $html->button(" ", "index=$index&UID=$uid&NEXT=$uid",
    { class => 'float-right btn btn-default', ICON => 'fa fa-arrow-right', TITLE => $lang{NEXT} });

  #show tags
  my $user_tags = '';
  if (in_array('Tags', \@MODULES)) {
    if (!$admin->{MODULES} || $admin->{MODULES}{'Tags'}) {
      require Tags;
      Tags->import();
      my $Tags = Tags->new($db, $admin, \%conf);
      my $list = $Tags->tags_user({
        NAME      => '_SHOW',
        PRIORITY  => '_SHOW',
        DATE      => '_SHOW',
        UID       => $uid,
        COLS_NAME => 1
      });

      my @tags_arr = ();

      foreach my $line (@$list) {
        next if !$line->{date};
        push @tags_arr, $html->element('span', $line->{name}, {
          'class'                 => "btn btn-sm $priority_colors[$line->{priority}]",
          'data-tooltip'          => $line->{comments} || $line->{name},
          'data-tooltip-position' => 'top',
          'style'                 => $line->{color} ? "background-color: $line->{color}; border-color: $line->{color}" : ''
        }) . ' ';
      }

      $user_tags = ($#tags_arr > -1) ? join(" ", @tags_arr) : '';

      my $icon_tag = $html->element('span', '', { class => 'fa fa-tags p-1' });
      $user_tags .= $html->element('button', $icon_tag, {
        class                   => "btn btn-default btn-sm",
        'data-tooltip'          => "$lang{TAGS} ($lang{ADD})",
        'data-tooltip-position' => 'top',
        onclick                 => $permissions{0}{3} ? "loadToModal('$SELF_URL?qindex=" . get_function_index('tags_user')
          . "&UID=$uid&header=2&FORM_NAME=USERS_TAG')" : '',
      });
    }
  }

  my $full_info .= ($permissions{1}) ? $html->button('', "index=2&UID=$uid",
    { TITLE => $lang{PAYMENTS}, class => 'btn btn-default btn-sm', ICON => 'fa fa-plus', ex_params => 'style="color: green;"' }) : '';
  $full_info .= ' ' . (($permissions{2}) ? $html->button('', "index=3&UID=$uid",
    { TITLE => $lang{FEES}, class => 'btn btn-default btn-sm', ICON => 'fa fa-minus' }) : '');
  $full_info .= ' ' . $html->button('', "index=15&UID=$uid&SUMMARY_SHOW=1",
    { TITLE => $lang{INFO}, class => 'btn btn-default btn-sm', ICON => 'fa fa-th-large' });

  if ($conf{USERSIDE_LINK}) {
    my ($name, $us_link) = split(/:/, $conf{USERSIDE_LINK}, 2);
    $full_info .= ' ' . $html->button($name || 'USERSIDE', '', {
      class      => 'btn btn-success btn-sm',
      GLOBAL_URL => "$us_link$user_info->{LOGIN}",
      target     => '_blank',
      ex_params  => q{style='background-color: #4555a5; border-color: #4555a5;'},
    });
  }

  $pre_button = $html->element('div', $pre_button, { class => 'bd-highlight' });
  $next_button = $html->element('div', $next_button, { class => 'bd-highlight' });
  my $main_content = $html->element('div', "$ext_menu $full_info $domain_id $deleted $user_tags", { class => 'bd-highlight m-auto' });

  $user_info->{TABLE_SHOW} = $html->element('div', "$pre_button $main_content $next_button",
    { class => "user_header d-flex justify-content-between bd-highlight rounded mb-2 $del_class" });

  user_right_menu($uid, $user_info);

  $LIST_PARAMS{UID} = $uid;
  $FORM{UID} = $uid;
  $pages_qs = "&UID=$uid";
  $pages_qs .= "&subf=$FORM{subf}" if ($FORM{subf});

  return $user_info;
}


#**********************************************************
=head2 form_users_list()

=cut
#**********************************************************
sub form_users_list {
  my ($attr) = @_;
  return 0 if (!$permissions{0}{2});

  form_users() if ($FORM{MULTIUSER});

  my %col_hidden = ();
  $col_hidden{TYPE_PAGE} = $FORM{type} if ($FORM{type});

  if ($FORM{COMPANY_ID} && !$FORM{change}) {
    # print $html->br($html->b("$lang{COMPANY}:") . $FORM{COMPANY_ID});
    $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}" if ($pages_qs !~ /COMPANY_ID/);
    $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
    $col_hidden{COMPANY_ID} = $FORM{COMPANY_ID};
  }

  if ($FORM{letter}) {
    $LIST_PARAMS{LOGIN} = "$FORM{letter}*";
    $pages_qs .= "&letter=$FORM{letter}";
  }

  my @statuses = (
    $lang{ALL},
    $lang{ACTIV},
    $lang{DEBETORS},
    $lang{DISABLE},
    $lang{EXPIRE},
    $lang{CREDIT},
    $lang{NOT_ACTIVE},
    $lang{PAID},
    $lang{UNPAID}
  );

  push @statuses, $lang{DELETED} if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8});

  my $i = 0;
  my $users_status = 0;
  my @status_bar_arr = ();

  $FORM{USERS_STATUS} = 0 if (!defined($FORM{USERS_STATUS}));
  my $qs = '';
  foreach my $name (@statuses) {
    my $active = '';
    if (defined($FORM{USERS_STATUS}) && $FORM{USERS_STATUS} =~ /^\d+$/ && $FORM{USERS_STATUS} == $i) {
      $LIST_PARAMS{USER_STATUS} = 1;
      if ($i == 1) {
        $LIST_PARAMS{ACTIVE} = 1;
      }
      elsif ($i == 2) {
        $LIST_PARAMS{DEPOSIT} = '<0';
      }
      elsif ($i == 3) {
        $LIST_PARAMS{DISABLE} = 1;
      }
      elsif ($i == 4) {
        $LIST_PARAMS{EXPIRE} = "<=$DATE;>0000-00-00";
      }
      elsif ($i == 5) {
        $LIST_PARAMS{CREDIT} = ">0";
      }
      elsif ($i == 6) {
        $LIST_PARAMS{DISABLE} = 2;
      }
      elsif ($i == 7) {
        $LIST_PARAMS{PAID} = 1;
      }
      elsif ($i == 8) {
        $LIST_PARAMS{UNPAID} = 1;
      }
      elsif ($i == 9) {
        $LIST_PARAMS{DELETED} = 1;
      }
      $pages_qs =~ s/\&USERS_STATUS=\d//g;
      $pages_qs .= "&USERS_STATUS=$i";
      $users_status = $i;
      $active = 'active';
    }
    else {
      $qs = $pages_qs;
      $qs =~ s/\&USERS_STATUS=\d//g;
    }

    push @status_bar_arr, "$name:index=$index&USERS_STATUS=$i$qs";
    $i++;
  }
  my AXbills::HTML $table;
  my $list;

  if ($FORM{search}) {
    while (my ($k, $v) = each %FORM) {
      if ($v) {
        if ($k && ($k eq 'PHONE' || $k eq 'CELL_PHONE') && $v !~ m/\*/) {
          $v = qq{*$v*};
        }
        next if ($v eq ', ');
        $LIST_PARAMS{$k} = $v;
      }
    }
  }

  if ($FORM{json} && $FORM{API_KEY} && !$LIST_PARAMS{PAGE_ROWS}) {
    $LIST_PARAMS{PAGE_ROWS} = 100000;
  }

  my $ext_fields = '';
  $ext_fields .= 'DELETED' if ($permissions{0} && $permissions{0}{4});

  if ($FORM{EXPORT_CONTENT}) {
    my $buffer = $FORM{__BUFFER};
    my (undef, $value) = split(/(UID=([0-9].+;))/, $buffer);

    if ($value) {
      $value =~ s/UID=//g;
      $LIST_PARAMS{UID} = $value;
    }
  }

  $LIST_PARAMS{_MULTI_HIT} = ' OR ' if ($FORM{UID} && $FORM{UID} =~ /.*\,.*/);

  my $hidden_fields = 'PRIORITY';
  $hidden_fields .= ',BUILD_ID' if !in_array('Maps', \@MODULES) || ($admin->{MODULES} && !$admin->{MODULES}{Maps});

  ($table, $list) = result_former({
    INPUT_DATA      => $users,
    FUNCTION        => 'list',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => "LOGIN,FIO,DEPOSIT,CREDIT,LOGIN_STATUS,$ext_fields",
    HIDDEN_FIELDS   => $hidden_fields,
    FUNCTION_FIELDS => 'form_payments, form_fees',
    TABLE           => {
      width            => '100%',
      FIELDS_IDS       => $users->{COL_NAMES_ARR},
      caption          => "$lang{USERS} - " . $statuses[$users_status],
      qs               => $pages_qs,
      ID               => 'USERS_LIST',
      SELECT_ALL       => ($permissions{0}{7}) ? "users_list:IDS:$lang{SELECT_ALL}" : undef,
      SHOW_COLS_HIDDEN => \%col_hidden,
      header           => \@status_bar_arr,
      EXPORT           => 1,
      MAIN_BODY        => 1,
      IMPORT           => "$SELF_URL?get_index=form_users&import=1&header=2",
      MENU             => "$lang{ADD}:index=" . get_function_index('form_wizard') . (($FORM{COMPANY_ID}) ? '&COMPANY_ID=' . $FORM{COMPANY_ID} : '') .
        ':add' . ";$lang{SEARCH}:index=" . get_function_index('form_search') . ":search",
    }
  });

  return 0 if (_error_show($users));

  if ($users->{TOTAL} && $users->{TOTAL} == 1 && !$FORM{SKIP_FULL_INFO} && !$FORM{EXPORT_CONTENT}) {
    $FORM{index} = 15;

    if (!$FORM{UID}) {
      $FORM{UID} = $list->[0]->{uid};
      if (!$FORM{LOGIN} || $FORM{LOGIN} =~ /\*/) {
        delete $FORM{LOGIN};
        $ui = user_info($FORM{UID});
        print $ui->{TABLE_SHOW} if (!$FORM{xml} && $ui && $ui->{TABLE_SHOW});
      }
    }

    form_users({ USER_INFO => $ui });

    return 1;
  }
  elsif (!$users->{TOTAL}) {
    $html->message('err', $lang{ERROR}, "$lang{USER} $lang{NOT_EXIST}");
    return 0;
  }

  print $html->letters_list({ pages_qs => $pages_qs }) if ($conf{USER_LIST_LETTERS});

  my $search_color_mark;
  if ($FORM{UNIVERSAL_SEARCH}) {
    $search_color_mark = $html->color_mark($FORM{UNIVERSAL_SEARCH}, $_COLORS[6]);
  }

  my $countries_hash;

  if (!$conf{ADDRESS_REGISTER}) {
    ($countries_hash, undef) = sel_countries();
  }

  my $base_fields = 1;

  if ($FORM{UNIVERSAL_SEARCH}) {
    $FORM{UNIVERSAL_SEARCH} =~ s/\*//g;
  }

  foreach my $line (@$list) {
    my $uid = $line->{uid};
    my $payments = ($permissions{1}) ? $html->button($lang{PAYMENTS}, "index=2&UID=$uid", { class => 'payments' }) : '';
    my $fees = ($permissions{2}) ? $html->button($lang{FEES}, "index=3&UID=$uid", { class => 'fees' }) : '';

    if ($FORM{UNIVERSAL_SEARCH}) {
      $line->{fio} =~ s/(.*)$FORM{UNIVERSAL_SEARCH}(.*)/$1$search_color_mark$2/ if ($line->{fio});
      $line->{login} =~ s/(.*)$FORM{UNIVERSAL_SEARCH}(.*)/$1$search_color_mark$2/ if ($line->{login});
      $line->{comments} =~ s/(.*)$FORM{UNIVERSAL_SEARCH}(.*)/$1$search_color_mark$2/ if ($line->{comments});
    }

    my @fields_array = ();
    for ($i = $base_fields; $i < $base_fields + $users->{SEARCH_FIELDS_COUNT}; $i++) {
      my $col_name = $users->{COL_NAMES_ARR}->[$i] || '';

      next if $col_name eq 'build_id' && (!in_array('Maps', \@MODULES) || ($admin->{MODULES} && !$admin->{MODULES}{Maps}));
      if ($conf{EXT_BILL_ACCOUNT} && $col_name eq 'ext_bill_deposit') {
        $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit}, 'text-danger') : $line->{ext_bill_deposit};
      }
      elsif ($col_name eq 'deleted') {
        $table->{rowcolor} = ($line->{deleted} == 1) ? 'bg-danger' : '';
        $line->{_del} = $line->{deleted};
        $line->{deleted} = $html->color_mark(
          $bool_vals[ $line->{deleted} ],
          ($line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : ''
        );
      }
      elsif ($col_name =~ /deposit/) {
        if (!$permissions{0}{12}) {
          $line->{$col_name} = '--';
        }
        else {
          my $deposit = $line->{$col_name} || 0;
          if ($conf{DEPOSIT_FORMAT}) {
            $deposit = sprintf("$conf{DEPOSIT_FORMAT}", $deposit);
          }
          $line->{$col_name} = ($deposit + ($line->{credit} || 0) < 0) ? $html->color_mark($deposit, $_COLORS[6]) : $deposit,
        }
      }
      # elsif ($col_name eq 'deposit') {
      #   $line->{$col_name} = (!$permissions{0}{12}) ? '--' : (($line->{deposit} ? $line->{deposit} : 0) + ($line->{credit} || 0) < 0) ? $html->color_mark($line->{deposit}, 'text-danger') : $line->{deposit},
      # }
      elsif ($col_name eq 'tags') {
        if ($line->{tags} && $line->{tags} ne '') {
          my @tags_name = split(/,/, $line->{tags});
          my @tags_priority = split(/,/, $line->{priority});
          $line->{$col_name} = q{};
          for (my $tags_count = 0; $tags_count < scalar @tags_name; $tags_count++) {
            my $priority_color = ($tags_priority[$tags_count] && $priority_colors[$tags_priority[$tags_count]]) ? $priority_colors[$tags_priority[$tags_count]] : q{};
            $line->{$col_name} .= ' ' . $html->element('span', $tags_name[$tags_count], { class => "btn btn-xs $priority_color" });
          }
          delete $line->{priority};
        }
      }
      elsif (($col_name eq 'last_payment' || $col_name eq 'last_fees') && $line->{$col_name}) {
        my ($date, undef) = split(/ /, $line->{$col_name});

        if ($date && $DATE eq $date) {
          $line->{$col_name} = $html->color_mark($line->{$col_name}, 'text-danger');
        }
      }
      elsif ($col_name eq 'country_id') {
        $line->{$col_name} = $countries_hash->{$line->{$users->{COL_NAMES_ARR}->[$i]}};
      }
      elsif ($col_name eq 'build_id') {
        $line->{$col_name} = form_add_map(undef, { BUILD_ID => $line->{$col_name} });
      }
      elsif ($FORM{UNIVERSAL_SEARCH}) {
        if ($FORM{UNIVERSAL_SEARCH} && $line->{$col_name}) {
          $line->{$col_name} =~ s/(.{0,100})"$FORM{UNIVERSAL_SEARCH}"(.{0,100})/$1$search_color_mark$2/;
        }
      }

      if ($col_name eq 'login_status') {
        my $color = ($state_colors[ $line->{login_status} || 0 ]) ? $state_colors[ $line->{login_status} || 0 ] : '';
        push @fields_array, $table->td(
          $status[ $line->{login_status} || 0 ],
          { class => "text-$color", align => 'center' }
        );
      }
      else {
        push @fields_array, $table->td($line->{$col_name});
      }
    }

    @fields_array = ($table->td(user_ext_menu($uid, $line->{login}, {
      login_status => $line->{login_status},
      deleted      => $line->{_del},
      NO_CHANGE    => 1
    })), @fields_array);

    if ($permissions{0}{7}) {
      @fields_array = ($table->td($html->form_input('IDS', "$uid", { TYPE => 'checkbox', FORM_ID => 'users_list' })), @fields_array);
    }

    $table->addtd(
      @fields_array,
      $table->td($payments . ' ' . $fees)
    );
  }

  my @totals_rows = (
    [ $html->button("$lang{TOTAL}:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ],
    [ $html->button("$lang{EXPIRE}:", "index=$index&USERS_STATUS=4"), $html->b($users->{TOTAL_EXPIRED}) ],
    [ $html->button("$lang{DISABLE}:", "index=$index&USERS_STATUS=3"), $html->b($users->{TOTAL_DISABLED}) ]
  );

  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
    $users->{TOTAL} -= $users->{TOTAL_DELETED} || 0;
    $totals_rows[0] = [ $html->button("$lang{TOTAL}:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ];
    push @totals_rows, [ $html->button("$lang{DELETED}:", "index=$index&USERS_STATUS=9"), $html->b($users->{TOTAL_DELETED}) ],;
  }

  if (defined($attr->{ADD_ARGS}) && $attr->{ADD_ARGS}) {
    my $args = $attr->{ADD_ARGS};

    push @totals_rows, [ "$lang{DEPOSIT} " . lc($lang{COMPANIES}) . ":", $html->b($args->{COMPANY_DEPOSIT}) ];
    push @totals_rows, [ "$lang{SERVICES}: $lang{SUM}", $html->b($args->{SUM}) ];
    push @totals_rows, [ "$lang{SERVICES}: $lang{COUNT}", $html->b($args->{TOTAL}) ];
  }

  my $table2 = $html->table({
    width => '100%',
    rows  => \@totals_rows
  });

  if ($permissions{0}{7} && !$FORM{EXPORT_CONTENT} && !$FORM{xml}) {
    $html->{FORM_ID} = 'users_list';

    my $mu_comments_radio1_input = $html->form_input('optradio', 'append', { TYPE => 'radio', class => 'form-check-input', EX_PARAMS => 'id="radio1" checked' }) . "  $lang{APPEND}";
    my $mu_comments_radio2_input = $html->form_input('optradio', 'change', { TYPE => 'radio', class => 'form-check-input', EX_PARAMS => 'id="radio2"' }) . "  $lang{CHANGE}";
    my $mu_comments_radio1_label = $html->element('label', $mu_comments_radio1_input, { class => 'form-check-label', for => 'radio1' });
    my $mu_comments_radio2_label = $html->element('label', $mu_comments_radio2_input, { class => 'form-check-label', for => 'radio2' });
    my $mu_comments_radio1 = $html->element('div', $mu_comments_radio1_label, { class => 'form-check' });
    my $mu_comments_radio2 = $html->element('div', $mu_comments_radio2_label, { class => 'form-check' });
    my $mu_comments_radio_div = $html->element('div', $mu_comments_radio1 . $mu_comments_radio2, { class => 'col-md-6' });
    my $mu_comments_textarea = $html->element('textarea', $FORM{COMMENTS_TEXT}, { name => "COMMENTS_TEXT", rows => "4", cols => "50", form => "users_list" });
    my $mu_comments_textarea_div = $html->element('div', $mu_comments_textarea, { class => 'col-md-6' });
    my $mu_comments_row = $html->element('div', $mu_comments_textarea_div . $mu_comments_radio_div, { class => 'row' });

    my @multi_operation = (
      [ $html->form_input('MU_GID', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{GROUP},
        sel_groups({ SKIP_MULTISELECT => 1 }) ],
      [ $html->form_input('MU_DISABLE', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{DISABLE},
        $html->form_input('DISABLE', "1", { TYPE => 'checkbox', class => 'mr-1' }) . $lang{CONFIRM} ],
      [ $html->form_input('MU_DEL', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{DEL},
        $html->form_input('DEL', "1", { TYPE => 'checkbox', class => 'mr-1' }) . $lang{CONFIRM} ],
      [ $html->form_input('MU_ACTIVATE', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{ACTIVATE},
        $html->date_fld2('ACTIVATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1 }) ],
      [ $html->form_input('MU_EXPIRE', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{EXPIRE},
        $html->date_fld2('EXPIRE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1 }) ],
      [ $html->form_input('MU_CREDIT', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{CREDIT},
        $html->form_input('CREDIT', $FORM{CREDIT}) ],
      [ $html->form_input('MU_CREDIT_DATE', 1, { TYPE => 'checkbox', class => 'mr-1' }) . "$lang{CREDIT} $lang{DATE}",
        $html->date_fld2('CREDIT_DATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1, DATE => $FORM{CREDIT_DATE} }) ],
      [ $html->form_input('MU_REDUCTION', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{REDUCTION},
        $html->form_input('REDUCTION', $FORM{REDUCTION}, { TYPE => 'number', EX_PARAMS => "class='form-control' step='0.1'" }) ],
      [ $html->form_input('MU_REDUCTION_DATE', 1, { TYPE => 'checkbox', class => 'mr-1' }) . "$lang{REDUCTION} $lang{DATE}",
        $html->date_fld2('REDUCTION_DATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1, DATE => $FORM{CREDIT_DATE} }) ],
      [ $html->form_input('MU_COMMENTS', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{COMMENTS}, $mu_comments_row ],
      [ '', $html->form_input('MULTIUSER', $lang{APPLY}, { TYPE => 'submit' }) ],
    );

    if (in_array('Msgs', \@MODULES)) {
      load_module('Msgs', $html);
      my $delivery_form = msgs_mu_delivery_form();
      if ($delivery_form) {
        @multi_operation = ([ $html->form_input('MU_DELIVERY', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{DELIVERY}, $delivery_form ],
          @multi_operation);
      }
    }

    #Ureport muliuser select options
    if (in_array('Ureports', \@MODULES)) {
      load_module('Ureports', $html);

      my $load_to_modal_btn = $html->button($lang{ADD}, 'qindex=' . get_function_index('ureports_multiuser_sel') .
        '&header=2&FORM_ID=users_list', {
        LOAD_TO_MODAL => 1,
        class         => 'btn btn-default',
      });

      @multi_operation = (
        [
          $html->form_input('MU_UREPORTS_TP', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{NOTIFICATIONS},
          $load_to_modal_btn
        ],
        @multi_operation,
      );
    }

    #Tags muliuser select options
    if (in_array('Tags', \@MODULES)) {
      load_module('Tags', $html);
      my $load_to_modal_btn = $html->button($lang{ADD}, 'qindex=' . get_function_index('tags_multiuser_form') .
        "&header=2&MULTIUSER_INDEX=$index&FORM_ID=users_list", {
        LOAD_TO_MODAL => 1,
        class         => 'btn btn-default',
      });

      @multi_operation = (
        [
          $html->form_input('MU_TAGS', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{TAGS},
          $load_to_modal_btn
        ],
        @multi_operation,
      );
    }

    #Bonus muliuser select options
    if (in_array('Bonus', \@MODULES)) {
      load_module('Bonus', $html);

      @multi_operation = (
        [
          $html->form_input('MU_BONUS', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{BONUS},
          $html->form_input('BONUS', '', { TYPE => 'number', EX_PARAMS => "class='form-control' step='0.1'" }),
        ],
        @multi_operation,
      );
    }

    my $table3 = $html->table(
      {
        width      => '100%',
        caption    => $lang{MULTIUSER_OP},
        HIDE_TABLE => 1,
        rows       => \@multi_operation,
        ID         => 'USER_MANAGMENT'
      }
    );

    if ($FORM{json} && $FORM{API_KEY}) {
      print $table->show({ OUTPUT2RETURN => 1 });
    }
    else {
      print $html->form_main(
        {
          CONTENT => $table->show({ OUTPUT2RETURN => 1 })
            . ((!$admin->{MAX_ROWS}) ? $table2->show({ OUTPUT2RETURN => 1, DUBLICATE_DATA => 1 }) : '')
            . $table3->show({ OUTPUT2RETURN => 1, DUBLICATE_DATA => 1 }),
          HIDDEN  => {
            UID   => $FORM{UID},
            index => 11,
          },
          NAME    => 'users_list',
          class   => 'hidden-print',
          ID      => 'users_list',
        }
      );
    }
  }
  else {
    print $table->show();
    print $table2->show() if (!$admin->{MAX_ROWS});
  }

  return 1;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del {
  my ($attr) = @_;

  my Users $user_info = $attr->{USER_INFO};

  if ($FORM{UNDELETE}) {
    $user_info->change($user_info->{UID}, { UID => $user_info->{UID}, DELETED => 0 });
    $html->message('info', $lang{UNDELETE}, "UID: [$user_info->{UID}] $lang{UNDELETE} $user_info->{LOGIN}");
    return 0;
  }

  $user_info->del({ %FORM, DATE => $DATE });
  $conf{DELETE_USER} = $user_info->{UID};

  if ($conf{USER_DELETE_USE_SUFFIX}) {
    if ($user_info->{suffix_added}) {
      $html->message('info', $lang{INFO}, $lang{SUFFIX_ADDED});
    }
    else {
      $html->message('warn', $lang{WARNING}, $lang{NOE_ENOUGHT_SIZE_FOR_SUFFIX});
    }
  }

  if (!_error_show($user_info)) {
    if ($conf{external_userdel}) {
      if (!_external($conf{external_userdel}, { %FORM, %$user_info })) {
        $html->message('err', $lang{DELETED}, "External cmd: $conf{external_userdel}");
      }
    }
    $html->message('info', $lang{DELETED}, "UID: " . ($user_info->{UID} || q{n/d})
      . "\n $lang{DELETED} "
      . ($user_info->{LOGIN} || q{n/d}));
  }

  if ($FORM{FULL_DELETE}) {
    my $mods = '';
    $user_info->{COMMENTS} = $FORM{COMMENTS};
    foreach my $mod (@MODULES) {
      $mods .= "$mod,";
      load_module($mod, $html);

      my $function = lc($mod) . '_user_del';

      if (defined(&$function)) {
        &{\&$function}($user_info->{UID}, $user_info);
      }
    }

    if (!_error_show($user_info)) {
      if ($conf{external_userdel}) {
        if (!_external($conf{external_userdel}, { %FORM, %$user_info })) {
          $html->message('err', $lang{DELETED}, "External cmd: $conf{external_userdel}");
        }
      }

      $html->message('info', $lang{DELETED}, "UID: $user_info->{UID}\n $lang{MODULES}: $mods");
    }
  }

  return 1;
}

#**********************************************************
=head2 user_group($attr)

=cut
#**********************************************************
sub user_group {
  my ($attr) = @_;
  my $user = $attr->{USER_INFO};

  if (!$user) {
    $html->message('err', $lang{ERROR}, 'No user information');
    return 1;
  }

  $user->{SEL_GROUPS} = sel_groups({
    GID              => ($user && $user->{GID}) ? $user->{GID} : undef,
    SKIP_MULTISELECT => 1
  });

  $html->tpl_show(templates('form_chg_group'), $user);

  return 1;
}

#**********************************************************
=head2 user_company($attr)

=cut
#**********************************************************
sub user_company {
  my ($attr) = @_;

  my $user_info = $attr->{USER_INFO};

  require Customers;
  Customers->import();
  my $customer = Customers->new($db, $admin, \%conf);
  my $company = $customer->company();
  form_search(
    {
      SIMPLE        => { $lang{COMPANY} => 'COMPANY_NAME' },
      HIDDEN_FIELDS => { UID => $FORM{UID} }
    }
  );
  delete $LIST_PARAMS{UID};
  $LIST_PARAMS{SKIP_GID} = 1;
  my $list = $company->list({ %LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table({
    width => '100%',
    title => [ $lang{NAME}, $lang{DEPOSIT}, '-' ],
    qs    => $pages_qs,
    pages => $company->{TOTAL},
    ID    => 'COMPANY_LIST'
  });

  $FORM{UID} = 0 if (!$FORM{UID});
  my $user_index = get_function_index('form_users');
  $table->addrow($lang{DEFAULT}, '', $html->button("$lang{DEL}", "index=" . get_function_index('form_users') . "&change=1&UID=$FORM{UID}&COMPANY_ID=0", { class => 'del' }),);

  foreach my $line (@{$list}) {
    $table->{rowcolor} = ($user_info->{COMPANY_ID} && $user_info->{COMPANY_ID} == $line->{id}) ? 'active' : undef;
    $table->addrow(
      ($user_info->{COMPANY_ID} && $user_info->{COMPANY_ID} == $line->{id})
        ? $html->b($line->{name})
        : $line->{name},
      $line->{deposit},
      ($user_info->{COMPANY_ID} && $user_info->{COMPANY_ID} == $line->{id})
        ? ''
        : $html->button("$lang{CHANGE}",
        "index=" . $user_index . "&change=1&UID=$FORM{UID}&COMPANY_ID=$line->{id}", { class => 'add' }
      ),
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_wizard($attr) - User registration wizards

  Arguments:
    $attr

  Result:
    TRUE or FALSE


=cut
#**********************************************************
sub form_wizard {
  #  my ($attr) = @_;

  # Function name:module:describe
  my %steps = ();

  $index = get_function_index('form_wizard');
  my DBI $db_ = $db->{db};

  $users->{PRE_ADD} = 1;
  $users->check_params();

  if ($users->{errno}) {
    $html->message('warn', $lang{PLEASE_UPDATE_LICENSE});
  }

  if ($conf{REG_WIZARD}) {
    $conf{REG_WIZARD} =~ s/[\r\n]+//g;
  }
  else {
    $conf{REG_WIZARD} = "user_form::$lang{ADD} $lang{USER}";
    if ($permissions{1} && $permissions{1}{1}) {
      $conf{REG_WIZARD} .= ";form_payments:Control/Payments:$lang{PAYMENTS}";
    }

    $conf{REG_WIZARD} .= ';internet_user:Internet:Internet' if (in_array('Internet', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{Internet}));
    $conf{REG_WIZARD} .= ";abon_user:Abon:$lang{ABON}" if (in_array('Abon', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{Abon}));
    $conf{REG_WIZARD} .= ";form_fees_wizard::$lang{FEES}";
    $conf{REG_WIZARD} .= ";iptv_user:Iptv:$lang{TV}" if (in_array('Iptv', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{Iptv}));
    $conf{REG_WIZARD} .= ";msgs_admin_add:Msgs:$lang{MESSAGES}" if (in_array('Msgs', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{Msgs}));
  }

  if ($FORM{FIO}) {
    my ($last_name, $name, $second_name) = split(/ /, $FORM{FIO});
    $FORM{FIO1} = $last_name;
    $FORM{FIO2} = $name || '';
    $FORM{FIO3} = $second_name || '';
  }

  if (in_array('Sms', \@MODULES) && $conf{SMS_REG_GREETING}) {
    load_module('Sms', $html);
    send_user_memo({ %FORM, NEW_USER => 1 });
  }

  if (in_array('Crm', \@MODULES)) {
    if ($FORM{UID} && $FORM{LEAD_ID}) {
      require Crm::Leads;
      _crm_create_client($FORM{UID}, $FORM{LEAD_ID});
    }
    elsif ($FORM{LEAD_ID}) {
      require Crm::Leads;
      _crm_lead_to_client($FORM{LEAD_ID});
    }
  }

  if ($FORM{step} && $FORM{step} > 0 && $FORM{step} < 3 && $conf{REG_SURELY_VALUE}) {
    my %require_parameter_matching = (
      BUILD    => 'LOCATION_ID',
      STREET   => 'STREET_ID',
      DISTRICT => 'DISTRICT_ID',
      PHONE    => 'CONTACT_TYPE_2',
      EMAIL    => 'CONTACT_TYPE_9',
      GROUP    => 'GID'
    );
    my @empty_fields = ();

    foreach my $field (split(/,\s?/, $conf{REG_SURELY_VALUE})) {
      next if $FORM{$require_parameter_matching{$field} || $field};
      next if ($FORM{ADD_ADDRESS_BUILD} && $field eq 'BUILD');

      push @empty_fields, ($lang{$field} || $field);
    }

    if (scalar @empty_fields > 0) {
      $FORM{step} = 1;
      $html->message('err', $lang{ERROR}, vars2lang($lang{PLEASE_FILL_FIELDS}, { FIELDS => join(', ', @empty_fields) }));
    }
  }

  my @arr = split(/;\s?/, ';' . $conf{REG_WIZARD});
  for (my $i = 1; $i <= $#arr; $i++) {
    $steps{$i} = $arr[$i];
  }

  my $return = 0;
  my $reg_output = '';
  START:
  delete $FORM{OP_SID};
  if (!$FORM{step}) {
    $FORM{step} = 1;
  }
  elsif ($FORM{back}) {
    $FORM{step} = $FORM{step} - 2;
  }
  elsif ($FORM{update}) {
    $FORM{step}--;
    $FORM{back} = 1;
  }

  if ($FORM{UID}) {
    $LIST_PARAMS{UID} = $FORM{UID};
    $users->info($FORM{UID});
    $users->pi({ UID => $FORM{UID} });

    if (in_array('Voip', \@MODULES) && $conf{VOIP_NUM_POOL}) {
      if ($FORM{finish}) {
        require Voip::Users;
        Voip::Users->import();
        my $Voip_users = Voip::Users->new($db, $admin, \%conf, {
          html        => $html,
          lang        => \%lang,
          permissions => \%permissions
        });
        $Voip_users->voip_user_number_add($FORM{UID});
      }
    }
  }

  #Make functions
  if ($FORM{step} > 1 && !$FORM{back}) {
    $html->{NO_PRINT} = 1;
    #REG:
    $db->{TRANSACTION} = 1;
    $db_->{AutoCommit} = 0;

    my $step = $FORM{step} - 1;
    # $fn, $module, $describe
    my ($fn, $module, undef) = split(/:/, $steps{$step}, 3);
    if ($module) {
      #if (in_array($module, \@MODULES)) {
      load_module($module, $html);
      #}
      #else {
      #  print "ERROR: Unknow module: '$module' function: $fn";
      #  return 0;
      #}
    }

    if (!$FORM{change}) {
      $FORM{add} = 1;
    }
    else {
      $FORM{next} = 1;
    }

    $FORM{UID} = $LIST_PARAMS{UID} if (!$FORM{UID} && $LIST_PARAMS{UID});
    if ($FORM{DEBUG}) {
      print $html->br() . "Function: $fn " . $html->br();
      while (my ($k, $v) = each %FORM) {
        print "$k, $v" . $html->br();
      }
    }

    $return = &{\&$fn}({ REGISTRATION => 1, USER_INFO => ($FORM{UID}) ? $users : undef });
    $LIST_PARAMS{UID} = $FORM{UID};
    print "Return: " . $return . $html->br() if ($FORM{DEBUG});

    # Error
    if (!$return) {
      $db_->rollback();
      $FORM{step} += 1;
      $FORM{back} = 1;
      $html->{NO_PRINT} = undef;
      $FORM{add} = undef;
      $FORM{change} = undef;
      $reg_output = $html->{OUTPUT};
      goto START;
    }
    else {
      $db_->commit();
    }

    $FORM{add} = undef;
    $FORM{change} = undef;
    $html->{NO_PRINT} = undef;

    $reg_output = $html->{OUTPUT};
  }

  my ($fn, $module);
  if ($FORM{step} && $steps{ $FORM{step} }) {
    ($fn, $module) = split(/:/, $steps{ $FORM{step} }, 3);
  }

  if ($FORM{finish}) {
    $reg_output = '';
  }

  print _step_status_registration(\%steps);

  print $reg_output || q{} if ($fn && $fn ne 'form_payments');
  if (!$steps{ $FORM{step} } || $FORM{finish} || (!$FORM{next} && $FORM{step} == 2 && !$FORM{back})) {

    $html->message('info', $lang{INFO}, $lang{REGISTRATION_COMPLETE} . '!');
    delete $FORM{UID};
    delete $FORM{LOGIN};
    delete $FORM{add_form};
    form_users({ USER_INFO => $users });
    return 0;
  }

  if ($module) {
    if (in_array($module, \@MODULES) || $module =~ /\//) {
      load_module($module, $html);
    }
    else {
      $FORM{step}++;
      goto START;
    }
  }

  $FORM{step}++;

  if ($fn eq 'form_payments' && !$FORM{SUM}) {
    $FORM{SUM} = 0;
  }

  my @back_button = ();

  if ($FORM{TP_ID}) {
    push @back_button, $html->form_input('TP_ID', $FORM{TP_ID}, { TYPE => 'hidden' });
  }

  if ($FORM{step} > 2) {
    push @back_button,
      $html->form_input('finish', $lang{FINISH}, { TYPE => ($steps{ $FORM{step} }) ? 'submit' : 'hidden' }) . ' ',
      $html->form_input('back', $lang{BACK}, { TYPE => 'submit' });
  }
  else {
    if (!$FORM{back}) {
      push @back_button, $html->form_input('add', $lang{FINISH}, { TYPE => 'submit' });
    }
    else {
      push @back_button, $html->form_input('change', $lang{FINISH}, { TYPE => 'submit' })
    }
  }

  if (defined(\&$fn)) {
    &{\&$fn}(
      {
        %FORM,
        ACTION       => 'next',
        REGISTRATION => 1,
        USER_INFO    => ($FORM{UID}) ? $users : undef,
        LNG_ACTION   => ($steps{ $FORM{step} }) ? $lang{NEXT} : $lang{REGISTRATION_COMPLETE},
        BACK_BUTTON  => join(($FORM{json}) ? ',' : '', @back_button),
        UID          => $FORM{UID},
        SUBJECT      => $lang{REGISTRATION},
        EXT_HTML     => $reg_output,
      }
    );
  }
  else {
    $html->message('err', $lang{ERROR}, "Function not defined: $fn");
  }

  return 1;
}

#**********************************************************
=head2 _step_status_registration()

=cut
#**********************************************************
sub _step_status_registration {
  my ($steps) = @_;

  my $step_line = '';
  my $last_step = scalar keys %{$steps};

  foreach my $i (sort keys %{$steps}) {
    my $describe = _translate((split(/:/, $steps->{$i}, 3))[2] || q{});

    my $disabled = ($i > $FORM{step}) ? 'disabled' : '';

    my $bs_stepper_label = $html->element('span', ($describe || ''), { class => 'bs-stepper-label' });

    my $bs_stepper_circule = $html->element('span', $i, { class => 'bs-stepper-circle' });

    my $a_button = $html->element('a', $bs_stepper_circule . $bs_stepper_label, {
      href => "index.cgi?index=$index&back=1" . (($FORM{UID}) ? "&UID=$FORM{UID}" : '') . "&step=" . ($i + 2) });

    my $step_triggert = $html->element('button', $a_button, { class => 'step-trigger', type => 'button',
      role                                                          => 'tab', 'aria-controls' => 'information-part', id => 'information-part-trigger', $disabled => $disabled });

    my $step_div = $html->element('div', $step_triggert, { class => ($i == $FORM{step} ? 'step active' : 'step'), 'data-target' => '#logins-part' });

    my $div_line = $html->element('div', '', { class => 'line' });

    $step_line .= $step_div;
    $step_line .= $div_line if ($i != $last_step);
  }

  my $bs_stepper_header = $html->element('div', $step_line, { class => 'bs-stepper-header', role => 'tablist' });

  my $bs_stepper = $html->element('div', $bs_stepper_header, { class => 'bs-stepper' });

  return $bs_stepper;
}

#**********************************************************
=head2 form_contact_types()

=cut
#**********************************************************
sub form_contact_types {

  my $show_add_form = '';
  my $contact_type = {};

  require Contacts;
  Contacts->import();
  my $Contacts = Contacts->new($db, $admin, \%conf);

  if ($FORM{show_add_form}) {
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    $contact_type = $Contacts->contact_types_info($FORM{chg});
    _error_show($Contacts);

    $contact_type->{CHANGE_ID} = "ID";

    $show_add_form = 1;
  }
  elsif ($FORM{add}) {
    $Contacts->contact_types_add(\%FORM);
    $html->message('info', $lang{ADDED}) if (!_error_show($Contacts));
  }
  elsif ($FORM{change}) {
    $FORM{IS_DEFAULT} = '0' if (!$FORM{IS_DEFAULT});
    $Contacts->contact_types_change(\%FORM);
    $html->message('info', $lang{CHANGED}) if (!_error_show($Contacts));
  }
  elsif ($FORM{del}) {
    $Contacts->contact_types_del({ ID => $FORM{del} });
    $html->message('info', $lang{DELETED}) if (!_error_show($Contacts));
  }

  if ($show_add_form) {
    $contact_type->{IS_DEFAULT_CHECKED} = $contact_type->{IS_DEFAULT} ? 'checked="checked"' : q{};

    $html->tpl_show(templates("form_contact_types"), {
      %{$contact_type},
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? "$lang{CHANGE}" : "$lang{ADD}",
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? "change" : "add"
    });
  }

  my $default_fields = 'ID,NAME,IS_DEFAULT';
  my $filter_cols = { map {$_, '_translate'} split(",", uc $default_fields) };

  result_former({
    INPUT_DATA      => $Contacts,
    FUNCTION        => 'contact_types_list',
    DEFAULT_FIELDS  => $default_fields,
    FILTER_COLS     => $filter_cols,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
      is_default => $lang{DEFAULT}
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{CONTACTS} $lang{TYPE}",
      ID      => "CONTACT_TYPES_TABLE",
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&show_add_form=1:add"
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Events',
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 _build_user_contacts_form($user_contacts_list)

  Arguments:
    $user_contacts_list -

  Returns:

=cut
#**********************************************************
sub _build_user_contacts_form {
  my ($user_contacts_list, $user_contacts_types_list) = @_;

  my $in_reg_wizard = ($FORM{UID}) ? 0 : 1;
  my $default_types_string = q{};
  load_pmodule('JSON');
  my $json = JSON->new()->utf8(0);

  # In reg wizard, show default types
  if ($in_reg_wizard) {
    my %contact_types = ();
    my @all_contact_types = ();
    my @default_contact_types = ();
    my %contacts_entered = ();

    foreach my $item (@{$user_contacts_types_list}) {
      $contact_types{$item->{id}} = $item->{name};
      push @all_contact_types, $item->{id};
      push @default_contact_types, $item->{id} if $item->{is_default};

      next if !$FORM{'CONTACT_TYPE_' . $item->{id}};

      push @{$contacts_entered{$item->{id}}}, split(',\s?', $FORM{'CONTACT_TYPE_' . $item->{id}});
    }

    my $type_select = $html->form_select('TYPES_CONTACTS_', {
      SELECTED     => '2',
      SEL_HASH     => \%contact_types,
      NO_ID        => 1,
      NORMAL_WIDTH => 1,
      SORT_KEY_NUM => 1,
      EX_PARAMS    => "onchange='changeContactType(this)'"
    });
    $type_select =~ s/\n//g;

    return $html->tpl_show(templates('reg_wizard_contacts'), {
      TYPE_SELECT           => $type_select,
      ALL_CONTACT_TYPES     => join(',', @all_contact_types),
      EMAIL_FORMAT          => $conf{EMAIL_FORMAT} || $AXbills::Filters::EMAIL_EXPR,
      PHONE_FORMAT          => $conf{PHONE_FORMAT} ? $conf{PHONE_FORMAT} : '.+',
      PHONE_VALUE           => $FORM{phone} || '',
      CELL_PHONE_FORMAT     => $conf{CELL_PHONE_FORMAT} ? $conf{CELL_PHONE_FORMAT} : '.+',
      DEFAULT_CONTACT_TYPES => join(',', @default_contact_types),
      CONTACTS_ENTERED      => $FORM{CONTACTS_ENTERED} || $json->encode(\%contacts_entered)
    }, { OUTPUT2RETURN => 1 });
  }

  my $contacts_json = $json->encode({
    contacts => $user_contacts_list,
    options  => {
      callback_index => $index,
      types          => $user_contacts_types_list,
      uid            => $FORM{UID},
      in_reg_wizard  => $in_reg_wizard
    }
  });

  return $html->tpl_show(templates('form_contacts'), {
    DEFAULT_TYPES => $default_types_string,
    JSON          => $contacts_json
  }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 user_contacts_renew()

=cut
#**********************************************************
sub user_contacts_renew {

  my $message = $lang{ERROR};
  my $status = 1;

  return 0 unless ($FORM{uid} && $FORM{CONTACTS});
  require Contacts;
  Contacts->import();
  my $Contacts = Contacts->new($db, $admin, \%conf);

  if (my $error = load_pmodule("JSON", { RETURN => 1 })) {
    print $error;
    return '';
  }

  my $json = JSON->new()->utf8(1);
  $FORM{CONTACTS} =~ s/\\"/\"/g;

  my $contacts = $json->decode($FORM{CONTACTS});

  my ($validation_result, $val_message) = contacts_validation($contacts);
  my $contacts_json = '';

  if ($validation_result == 2) {
    $status = 1;
    $message = $val_message;
  }
  else {
    my DBI $db_ = $users->{db}->{db};
    if (ref $contacts eq 'ARRAY') {
      $db_->{AutoCommit} = 0;

      $Contacts->contacts_del({ UID => $FORM{uid} });

      if ($users->{errno}) {
        $db_->rollback();
        $status = $users->{errno};
        $message = $users->{sql_errstr};
      }
      else {
        foreach my $contact (@{$contacts}) {
          $Contacts->contacts_add({ %{$contact}, UID => $FORM{uid} });
        }

        if ($Contacts->{errno}) {
          $db_->rollback();
          $status = $Contacts->{errno};
          $message = $Contacts->{sql_errstr};
        }
        else {
          $db_->commit();
          $db_->{AutoCommit} = 1;
          $message = $lang{CHANGED};
          $status = 0;
        }
      }
    }
  }

  my $user_contacts_list = $Contacts->contacts_list({
    UID      => $FORM{uid},
    VALUE    => '_SHOW',
    DEFAULT  => '_SHOW',
    PRIORITY => '_SHOW',
    COMMENTS => '_SHOW',
    TYPE     => '_SHOW',
    HIDDEN   => '0'
  });

  $contacts_json = JSON->new()->utf8(0)->encode({
    contacts => $user_contacts_list,
  });

  print qq[
    {
      "contacts" : $contacts_json,
      "status" : $status,
      "message" :  "$message"
    }
  ];

  return '';
}

#**********************************************************
=head2 form_info_field_tpl($attr) - Info fields tp form

  Arguments:
    COMPANY                - Company info fields
    VALUES                 - Info field value hash_ref
    RETURN_AS_ARRAY        - returns hash_ref for name => $input (for custom design logic)
    CALLED_FROM_CLIENT_UI  - apply client_permission view/edit logic

  Returns:
    Return formed HTML

=cut
#**********************************************************
sub form_info_field_tpl {
  my ($attr) = @_;

  if (!$users && $user) {
    $users = $user;
  }

  my @field_result = ();
  my @name_view_arr = ();

  my $prefix = $attr->{COMPANY} ? 'ifc*' : 'ifu*';
  my $list;
  if (!$conf{info_fields_new}) {
    $list = $Conf->config_list({
      PARAM => $prefix,
      SORT  => 2
    });
  }
  else {
    require Info_fields;
    Info_fields->import();
    my $Info_fields = Info_fields->new($db, $admin, \%conf);
    #domain_id
    my $fields_list = $Info_fields->fields_list({
      COMPANY   => ($attr->{COMPANY} || 0),
      DOMAIN_ID => $users->{DOMAIN_ID} || ($admin->{DOMAIN_ID} ? $admin->{DOMAIN_ID} : '_SHOW'),
      SORT      => 5,
    });

    my $i = 0;
    foreach my $line (@$fields_list) {
      if ($attr->{POPUP} && !$attr->{POPUP}->{$line->{SQL_FIELD}}) {
        next;
      }
      $list->[$i]->[0] = ($attr->{COMPANY} ? 'ifc' : 'ifu') . $line->{SQL_FIELD};
      $list->[$i]->[1] = join(':',
        ($line->{PRIORITY} || 0),
        $line->{TYPE},
        $line->{NAME},
        $line->{ABON_PORTAL},
        $line->{USER_CHG},
        ($line->{PATTERN} || ''),
        ($line->{TITLE} || ''),
        ($line->{PLACEHOLDER} || ''),
        ($line->{REQUIRED} || ''),
      );
      $i++;
    }
  }
  my $uid = $FORM{UID} || q{};
  return '' if ($FORM{json} || $FORM{xml});

  my $row_template = templates('form_row');

  foreach my $line (@$list) {
    my $field_id = '';
    my $container_args = '';

    if ($line->[0] =~ /$prefix(\S+)/) {
      $field_id = $1;
    }
    my (undef, $type, $name, $user_portal, $can_be_changed_by_user, $pattern, $title, $placeholder, $required) = split(/:/, $line->[1]);
    next if ($attr->{CALLED_FROM_CLIENT_UI} && !$user_portal);

    $can_be_changed_by_user //= 0;

    my $input = '';
    my $field_name = uc($field_id);
    $type //= 0;

    my $disabled_ex_params = ($attr->{READ_ONLY} || ($attr->{CALLED_FROM_CLIENT_UI} && !$can_be_changed_by_user))
      ? ' disabled="disabled" readonly="readonly"'
      : '';

    # Select
    if ($type == 2) {
      my $selected = $FORM{$field_name};

      if ($attr->{VALUES} && $attr->{VALUES}->{$field_name}) {
        $selected = $attr->{VALUES}->{uc("$field_name\_id")} || $attr->{VALUES}->{$field_name};
      }

      $input = $html->form_select($field_name, {
        SELECTED      => $selected,
        SEL_LIST      => $users->info_lists_list({ LIST_TABLE => $field_id . '_list', COLS_NAME => 1 }),
        SEL_OPTIONS   => { '' => '--' },
        NO_ID         => 1,
        ID            => $field_id,
        EX_PARAMS     => $disabled_ex_params,
        REQUIRED      => !$attr->{SKIP_REQUIRED} && $required,
        OUTPUT2RETURN => 1
      });
    }

    #Checkbox
    elsif ($type == 4 || $type == 14) {
      $input = $html->form_input($field_name, 1, {
        TYPE          => 'checkbox',
        STATE         => (($attr->{VALUES} && $attr->{VALUES}->{$field_name}) || $FORM{$field_name}) ? 1 : undef,
        ID            => $field_id,
        EX_PARAMS     => $disabled_ex_params . ((!$attr->{SKIP_DATA_RETURN}) ? "data-return='1' " : ''),
        OUTPUT2RETURN => 1
      });
    }

    #'ICQ',
    elsif ($type == 8) {
      $input = $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, {
        SIZE          => 10,
        ID            => $field_id,
        EX_PARAMS     => $disabled_ex_params,
        OUTPUT2RETURN => 1
      });
      if ($attr->{VALUES}->{$field_name}) {
        $input .= " <a href=\"http://www.icq.com/people/about_me.php?uin=$attr->{VALUES}->{$field_name}\"><img  src=\"http://status.icq.com/online.gif?icq=$attr->{VALUES}->{$field_name}&img=21\" border='0'></a>";
      }
    }

    #'URL',
    elsif ($type == 9) {
      $input = $html->element(
        'div',
        $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, {
          ID            => $field_id,
          EX_PARAMS     => $disabled_ex_params . (!$attr->{SKIP_REQUIRED} && $required ? " required='required'" : ''),
          OUTPUT2RETURN => 1
        }) .
          $html->element('span', $html->button($lang{GO}, "", {
            class      => 'btn input-group-button',
            GLOBAL_URL => $attr->{VALUES}->{$field_name},
            ex_params  => ' target=' . ($attr->{VALUES}->{$field_name} || '_new'),
          }), { class => 'input-group-append' }), { class => 'input-group' }
      );
    }

    #'PHONE',
    #'E-Mail'
    #'SKYPE'
    elsif ($type == 12) {
      $input = $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, { SIZE => 20, ID => $field_name, EX_PARAMS => $disabled_ex_params, OUTPUT2RETURN => 1 });
      if ($attr->{VALUES}->{$field_name}) {
        $input .=
          qq{  <script type="text/javascript" src="http://download.skype.com/share/skypebuttons/js/skypeCheck.js"></script><a href="skype:axbills.support?call"><img src="http://mystatus.skype.com/smallclassic/$attr->{VALUES}->{$field_name}" style="border: none;" width="114" height="20"/></a>};
      }
    }
    elsif ($type == 3) {
      $input = $html->form_textarea($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name},
        { ID => $field_id, EX_PARAMS => $disabled_ex_params, REQUIRED => !$attr->{SKIP_REQUIRED} && $required ? "required='required'" : '', OUTPUT2RETURN => 1 });
    }
    elsif ($type == 13) {
      require Attach;
      Attach->import();
      my $Attach = Attach->new($db, $admin, \%conf);
      my $file_id = $attr->{VALUES}->{$field_name} || q{};

      $Attach->attachment_info({ ID => $file_id, TABLE => $field_id . '_file' });

      my $file_name = q{};
      if ($Attach->{TOTAL}) {
        $file_name = $Attach->{FILENAME};
      }

      my $file_input_content = '';
      my $file_download_url = "?qindex=" . get_function_index('user_pi')
        . "&ATTACHMENT=$field_id:$file_id"
        . (($uid) ? "&UID=$uid" : '');

      my $span = $html->element('span', ((!$FORM{xml}) ? '&hellip;' : q{}), { class => 'btn btn-secondary', OUTPUT2RETURN => 1 });
      my $file_input = $html->form_input($field_name, '', {
        TYPE          => 'file',
        EX_PARAMS     => 'style="display: none;"',
        class         => 'file-hidden',
        OUTPUT2RETURN => 1,
      });
      my $file_name_input = $html->form_input('', $file_name, {
        EX_PARAMS     => 'readonly="readonly" target="_blank" data-url="' . $file_download_url . '" ',
        class         => "form-control file-visible",
        OUTPUT2RETURN => 1
      });

      my $label = $html->element('label', $span . $file_input, { class => 'input-group-btn', OUTPUT2RETURN => 1 });
      $file_input_content .= $label . $file_name_input;

      if (exists $attr->{VALUES}->{$field_name}) {
        if ($Attach->{TOTAL} && $Attach->{FILENAME} && $permissions{0}->{5}) {
          $file_input_content .= $html->element(
            'span',
            $html->button(
              "$lang{DEL}",
              "index=" . get_function_index('user_pi') . "&ATTACHMENT=$field_id:$file_id&del=1" . (($uid) ? "&UID=$uid" : ''),
              { class => 'del', MESSAGE => "$lang{DELETED}: $Attach->{FILENAME} ?" }
            ),
            { class => 'input-group-addon' }
          );
        }
      }

      $input = $html->element('div', $file_input_content, { class => 'input-group file-input' });
    }

    #Photo
    elsif ($type == 15) {
      $input = $html->button('', "index=$index&PHOTO=$uid&UID=$uid", { ICON => 'fa fa-camera' });
      if (-f "$conf{TPL_DIR}/if_image/" . $uid . '.jpg') {
        $input .= $html->element('span', '', { class => 'fa fa-user' });
      }
    }

    #Social network
    #Icons
    # fab fa-facebook
    # fab fa-twitter
    # fab fa-vk
    # fab fa-google

    elsif ($type == 16) {
      next if ($attr->{CALLED_FROM_CLIENT_UI}); # Social icons already displaying in "Password" tab

      my $values = ($attr->{VALUES} && $attr->{VALUES}->{$field_name}) ? $attr->{VALUES}->{$field_name} : ($FORM{$field_id} || '');
      my ($k, $val) = split(/, /, $values || q{});

      my $select_social = $html->form_select($field_name, {
        SELECTED    => $k,
        SEL_ARRAY   => [ 'facebook', 'vk', 'twitter', 'ok', 'instagram', 'google', 'telegram', 'apple' ],
        SEL_OPTIONS => { '' => '--' },
      });

      my $input_social = $html->form_input($field_name || q{}, $val || q{}, {
        ID            => $field_id || q{},
        class         => 'form-control rounded-right-0 rounded-left-0',
        OUTPUT2RETURN => 1
      });

      my $global_url = $k && $k eq 'telegram' ? "https://t.me/$val" : '';
      my $info_btn = $val ? $html->button('', "index=" . get_function_index('user_pi') .
        "&UID=$uid&SOCIAL_INFO=$k, $val", { class => 'btn input-group-button rounded-left-0 info', GLOBAL_URL => $global_url, target => '_blank' }) : '';

      $input = "<div class='form-group mb-0 row'>
        <div class='col-md-12'>
          <div class='d-flex bd-highlight'>
            <div class='flex-fill bd-highlight'>
              <div class='select'>
                <div class='input-group-append select2-append'>
                  $select_social
                </div>
              </div>
            </div>
            <div class='bd-highlight'>
              $input_social
            </div>
            <div class='bd-highlight'>
              <div class='input-group-append h-100'>
                $info_btn
              </div>
            </div>
          </div>
        </div>
      </div>";
    }

    # language
    elsif ($type == 18) {
      my $val = $attr->{VALUES}->{$field_name} || $FORM{$field_name} || 0;
      $input = _lang_select($field_name, $val);
    }

    # Time zone
    elsif ($type == 19) {
      my $val = $attr->{VALUES}->{$field_name} || $FORM{$field_name} || 0;

      $input = $html->element('div', _time_zone_select($field_name, $val), { class => 'col-md-8' });
      $container_args = 'row';
      require Time::Piece unless $Time::Piece::VERSION;
      Time::Piece->import(qw(gmtime));
      my Time::Piece $t = Time::Piece::gmtime();
      $t = $t + 3600 * $val;
      $input .= $html->element('label', $t->hms, { class => 'control-label col-md-4' });
    }
    # Date field
    elsif ($type == 20) {
      my $val = $attr->{VALUES}->{$field_name} || $FORM{$field_name} || '';
      $input = $html->form_datepicker("$field_name", $val, { EX_PARAMS => !$attr->{SKIP_REQUIRED} && $required ? "required='required'" : '', TITLE => $title, OUTPUT2RETURN => 1 });
    }
    else {
      if ($attr->{VALUES}->{$field_name}) {
        $attr->{VALUES}->{$field_name} =~ s/\"/\&quot;/g;
      }

      $pattern //= q{};
      $title //= q{};
      $placeholder //= q{};

      $input = $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, {
        ID            => $field_id,
        EX_PARAMS     => "$disabled_ex_params title='" . ($title || q{})
          . ($pattern ? " pattern='$pattern'" : '')
          . "' placeholder='$placeholder'"
          . (!$attr->{SKIP_REQUIRED} && $required ? " required='required'" : ''),
        OUTPUT2RETURN => 1
      });
    }

    if ($attr->{RETURN_AS_ARRAY}) {
      push(@name_view_arr, {
        ID   => $field_id,
        TYPE => $type,
        NAME => _translate($name),
        VIEW => $input
      });
      next;
    }

    $attr->{VALUES}->{ 'FORM_' . $field_name } = $input;

    push @field_result,
      $html->tpl_show($row_template, {
        ID          => "$field_id",
        NAME        => (_translate($name)),
        VALUE       => $input,
        COLS_LEFT   => $attr->{COLS_LEFT},
        COLS_RIGHT  => $attr->{COLS_RIGHT},
        BG_COLOR    => $container_args,
        LABEL_CLASS => !$attr->{SKIP_REQUIRED} && $required ? 'required' : ''
      }, { OUTPUT2RETURN => 1, ID => "$field_id" });
  }

  if ($attr->{RETURN_AS_ARRAY}) {
    return \@name_view_arr;
  }

  my $info = join((($FORM{json}) ? ',' : ''), @field_result);

  return $info;
}

#**********************************************************
=head2 form_show_attach($attr)

=cut
#**********************************************************
sub form_show_attach {
  my ($attr) = @_;

  require Attach;
  Attach->import();
  my $Attach = Attach->new($db, $admin, \%conf);
  my $uid = $attr->{UID} || $user->{UID};

  if ($FORM{ATTACHMENT} =~ /(.+):(\d+)/) {
    $FORM{TABLE} = $1 . '_file';
    $FORM{ATTACHMENT} = $2;
  }

  $Attach->attachment_info(
    {
      ID    => $FORM{ATTACHMENT},
      TABLE => $FORM{TABLE},
      UID   => $uid
    }
  );

  if (!$Attach->{TOTAL}) {
    print "Content-Type: text/html\n\n";
    print "$lang{ERROR}: $lang{ATTACHMENT} $lang{NOT_EXIST}\n";
    return 0;
  }

  if ($conf{ATTACH2FILE} && $Attach->{CONTENT} =~ /FILE: (.+)/) {
    my $filepath = $1 || q{};

    # $conf{ATTACH2FILE} can be 1;
    my $attach_path = ($conf{ATTACH2FILE} eq '1')
      ? "$conf{TPL_DIR}/attach/"
      : $conf{ATTACH2FILE};

    # Separate dir for each UID
    if ($uid) {
      $attach_path .= "$uid/";
    }

    # Need to separate filename from full path
    my ($filename) = $filepath =~ /^.*\/([a-zA-z0-9_.-]+)$/;

    $Attach->{CONTENT} = file_op({
      FILENAME => $filename,
      PATH     => $attach_path,
    });
  }

  print "Content-Type: $Attach->{CONTENT_TYPE}; filename=\"$Attach->{FILENAME}\"\n";
  if ($Attach->{FILENAME} !~ /\.jpg|\.pdf|\.djvu|\.png|\.gif/i) {
    print "Content-Disposition: attachment; filename=\"$Attach->{FILENAME}\"; size=\"$Attach->{FILESIZE}\";\n"
      . "Content-Length: $Attach->{FILESIZE};\n";
  }
  print "\n";
  print $Attach->{CONTENT};

  return 1;
}

#**********************************************************
=head2 form_fees_wizard($attr)

=cut
#**********************************************************
sub form_fees_wizard {
  my ($attr) = @_;

  my $fees = Finance->fees($db, $admin, \%conf);
  my $output = '';
  my %FEES_METHODS = ();

  if ($FORM{add}) {
    %FEES_METHODS = %{get_fees_types({ SHORT => 1 })};

    my $i = 0;
    my $message = '';
    while (defined($FORM{ 'METHOD_' . $i }) && $FORM{ 'METHOD_' . $i } ne '') {
      my ($type_describe, $price) = split(/:/, $FEES_METHODS{ $FORM{ 'METHOD_' . $i } }, 2);

      if (!$FORM{ 'SUM_' . $i } && $price && $price > 0) {
        $FORM{ 'SUM_' . $i } = $price;
      }

      if (!$FORM{ 'SUM_' . $i } || $FORM{ 'SUM_' . $i } <= 0) {
        $i++;
        next;
      }

      $fees->take(
        $attr->{USER_INFO},
        $FORM{ 'SUM_' . $i },
        {
          DESCRIBE       => $FORM{ 'DESCRIBE_' . $i } || $FEES_METHODS{ $FORM{ 'METHOD_' . $i } },
          INNER_DESCRIBE => $FORM{ 'INNER_DESCRIBE_' . $i }
        }
      );

      $message .= "$type_describe $lang{SUM}: " . sprintf('%.2f',
        $FORM{ 'SUM_' . $i }) . ", " . $FORM{ 'DESCRIBE_' . $i } . "\n";

      $i++;
    }

    if ($message ne '') {
      $html->message('info', $lang{FEES}, "$message");
    }

    return 1;
  }

  %FEES_METHODS = %{get_fees_types()};

  my $table = $html->table({
    width   => '100%',
    caption => "$lang{FEES} $lang{TYPES}",
    title   => [ '#', $lang{TYPE}, $lang{SUM}, $lang{DESCRIBE}, "$lang{ADMIN} $lang{DESCRIBE}" ],
    qs      => $pages_qs,
    ID      => 'FEES_WIZARD',
  });

  for (my $i = 0; $i <= 6; $i++) {
    my $method = $html->form_select(
      'METHOD_' . $i,
      {
        SELECTED => $FORM{ 'METHOD_' . $i },
        SEL_HASH => { %FEES_METHODS },
        NO_ID    => 1,
        SORT_KEY => 1
      }
    );

    $table->addrow(($i + 1), $method, $html->form_input('SUM_' . $i, $FORM{ 'SUM_' . $i }, { SIZE => 8 }), $html->form_input('DESCRIBE_' . $i, $FORM{ 'DESCRIBE_' . $i }, { SIZE => 30 }), $html->form_input('INNER_DESCRIBE_' . $i, $FORM{ 'INNER_DESCRIBE_' . $i }, { SIZE => 30 }),);
  }

  if ($attr->{ACTION}) {

    $table->{extra} = 'colspan=5 align=center';
    $table->addrow($html->tpl_show(templates('form_fees_wizard_checkbox'), {}, { OUTPUT2RETURN => 1 }));

    my $action = $html->br() . $html->form_input('finish', "$lang{REGISTRATION_COMPLETE}", { TYPE => 'submit' })
      . ' ' . $html->form_input('back', "$lang{BACK}", { TYPE => 'submit' })
      . ' ' . $html->form_input('next', "$lang{NEXT}", { TYPE => 'submit' });

    $table->{extra} = 'colspan=5 align=center';
    $table->{rowcolor} = 'even';
    $table->addcardfooter($action);
    print $html->form_main(
      {
        CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
        ID      => "form_wizard",
        HIDDEN  => {
          index        => $index,
          step         => $FORM{step},
          UID          => $FORM{UID},
          LEAD_ID      => $FORM{LEAD_ID},
          LOCATION_ID  => $FORM{LOCATION_ID},
          DISTRICT_ID  => $FORM{DISTRICT_ID},
          STREET_ID    => $FORM{STREET_ID},
          ADDRESS_FLAT => $FORM{ADDRESS_FLAT}
        },
      }
    );
    require Control::Fees;
    form_fees($attr);
  }
  else {
    return $output;
  }

  return 1;
}


#**********************************************************
=head2 users_import()

=cut
#**********************************************************
sub users_import {
  if (!$permissions{0}{17}) {
    $html->message('err', $lang{ERROR}, "$lang{IMPORT} $lang{ERR_ACCESS_DENY}");
    return 0;
  }

  if ($FORM{add}) {
    my $import_accounts = import_former(\%FORM);
    my $total = $#{$import_accounts} + 1;

    my $main_id = 'UID';
    if (!$import_accounts->[0]->{UID}) {
      if ($import_accounts->[0]->{LOGIN}) {
        $main_id = 'LOGIN';
      }
      elsif ($import_accounts->[0]->{MAIN_ID}) {
        $main_id = $import_accounts->[0]->{MAIN_ID};
      }
    }

    require Bills;
    Bills->import();
    my $Bills = Bills->new($db, $admin, \%conf);
    foreach my $_user (@$import_accounts) {
      if (!$_user->{$main_id}) {
        next;
      }
      my $list = $users->list({
        LOGIN     => '_SHOW',
        $main_id  => $_user->{$main_id},
        BILL_ID   => ($_user->{DEPOSIT}) ? '_SHOW' : undef,
        COLS_NAME => 1
      });

      #change exists
      if ($users->{TOTAL} > 0) {
        if ($_user->{DEPOSIT}) {
          $_user->{DEPOSIT} =~ s/,/\./;
          $Bills->change({ BILL_ID => $list->[0]->{bill_id}, DEPOSIT => $_user->{DEPOSIT} });
        }

        my $uid = $list->[0]->{uid};
        $users->change($uid, { %$_user, UID => $uid });
        $users->pi_change({ %$_user, UID => $uid });
        if ($users->{errno} && $users->{errno} == 4) {
          $users->pi_add({ %$_user, UID => $uid });
        }

        print $html->button($list->[0]->{login}, "index=15&UID=$uid") . " ($uid)' Ok" . $html->br();
      }
      #add new user
      else {
        $users->add({ %$_user, CREATE_BILL => 1 });
        if ($users->{errno}) {
          _error_show($users);
        }
        elsif ($users->{UID}) {
          $users->pi_add({ %$_user, UID => $users->{UID} });
        }
      }
    }

    $html->message('info', $lang{INFO}, "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n Size: $FORM{UPLOAD_FILE}{Size}\n Count: $total");

    return 1;
  }

  my $import_fields = $html->form_select('IMPORT_FIELDS',
    {
      SELECTED  => $FORM{IMPORT_FIELDS},
      SEL_ARRAY => [
        'LOGIN',
        'FIO',
        'PHONE',
        'ADDRESS_STREET',
        'ADDRESS_BUILD',
        'ADDRESS_FLAT',
        'PASPORT_NUM',
        'PASPORT_DATE',
        'PASPORT_GRANT',
        'CONTRACT_ID',
        'CONTRACT_DATE',
        'EMAIL',
        'COMMENTS'
      ],
      EX_PARAMS => 'multiple="multiple"'
    });

  my $encode = $html->form_select(
    'ENCODE',
    {
      SELECTED  => $FORM{ENCODE},
      SEL_ARRAY => [ '', 'win2utf8', 'utf82win', 'win2koi', 'koi2win', 'win2iso', 'iso2win', 'win2dos', 'dos2win' ],
    }
  );

  my $extra_row = $html->tpl_show(templates('form_row'), {
    ID    => 'ENCODE',
    NAME  => $lang{ENCODE},
    VALUE => $encode },
    { OUTPUT2RETURN => 1 });

  $html->tpl_show(templates('form_import'), {
    IMPORT_FIELDS     => $conf{USER_IMPORT_FIELDS} || 'LOGIN,CONTRACT_ID,FIO,PHONE,ADDRESS_STREET,ADDRESS_BUILD,ADDRESS_FLAT,PASPORT_NUM,PASPORT_GRANT',
    CALLBACK_FUNC     => 'form_users',
    IMPORT_FIELDS_SEL => $import_fields,
    EXTRA_ROWS        => $extra_row,
  });

  return 1;
}

#**********************************************************
=head2 _time_zone_select($field_name, $selected)

=cut
#**********************************************************
sub _time_zone_select {
  my ($field_name, $selected) = @_;
  my @sel_list = map {{ id => $_, name => "UTC" . sprintf("%+.2d", $_) . ":00" }} (-12 ... 12);
  my $tz_select = $html->form_select($field_name,
    {
      SEL_LIST      => \@sel_list,
      SELECTED      => $selected,
      NO_ID         => 1,
      OUTPUT2RETURN => 1
    });
  return $tz_select;
}

#**********************************************************
=head2 _lang_select()

=cut
#**********************************************************
sub _lang_select {
  my ($field_name, $selected) = @_;
  my @sel_list = map {
    my ($language, $lang_name) = split(':', $_);
    { id => $language, name => $lang_name };
  } split(';\s*', $conf{LANGS});
  my $lang_select = $html->form_select($field_name,
    {
      SEL_LIST      => \@sel_list,
      SELECTED      => $selected,
      NO_ID         => 1,
      OUTPUT2RETURN => 1
    });
  return $lang_select;
}

#**********************************************************
=head2 user_modal_search($attr)

  Arguments:
    $attr - hash_ref
      TEMPLATE         - template content (default : 'form_search_users')
      CALLBACK_FN      - where to send search %FORM (default: send here)
      EXTRA_BTN_PARAMS - extra params string to include to button (e.g. 'subf=6')
      BTN_ATTR         - extra btn attr

  Returns:
    HTML code of button to open user modal search

=cut
#**********************************************************
sub user_modal_search {
  my ($attr) = @_;

  my $main_search_template = $attr->{TEMPLATE} || templates('form_search_users_simple');
  my $callback_fn = $attr->{CALLBACK_FN} || 'user_modal_search';

  if ($FORM{user_search_form}) {
    # First step : Show search form
    if ($FORM{user_search_form} == 1) {

      my $search_form = $html->tpl_show($main_search_template, {
        ADDRESS_FORM => $html->tpl_show(templates('form_address_search'), undef, { OUTPUT2RETURN => 1 })
      }, { OUTPUT2RETURN => 1 });

      $html->tpl_show(templates('form_popup_window'),
        {
          SUB_TEMPLATE     => $search_form,
          CALLBACK_FN_NAME => $callback_fn
        }
      );
      return 2;
    }
    # Second step: show results
    elsif ($FORM{user_search_form} == 2) {

      my $users_list = $users->list(
        {
          %FORM,
          FIO       => "*$FORM{FIO}*",
          PHONE     => ($FORM{PHONE} ? '*' : '_SHOW'),
          COLS_NAME => 1
        }
      );

      if (_error_show($users) || !defined $users_list) {
        $html->message("err", $lang{ERROR}, "$lang{USER}: $lang{NOT_EXIST}");
        return 2;
      }

      if (scalar @{$users_list} > 40) {
        $html->message("warn", $lang{ERROR}, $lang{ERR_SEARCH_VAL_TOSMALL});
        return 2;
      }

      my $table = $html->table(
        {
          width   => '100%',
          caption => $lang{USERS},
          title   => [ $lang{LOGIN}, $lang{FIO}, $lang{PHONE} ],
          qs      => $pages_qs,
          ID      => 'SEARCH_TABLE_ID'
        }
      );
      foreach my $user (@{$users_list}) {
        my $login_str = "<button class='btn btn-default clickSearchResult' "
          . "data-value='UID::$user->{uid}#@#LOGIN::$user->{login}'>$user->{login}</button>";
        $table->addrow(
          $login_str,
          $user->{fio} || '--',
          $user->{phone} || '--'
        );
      }

      print $table->show();
      return 2;
    }
  }

  if ($attr->{NUMERIC}) {
    return 1;
  }

  my $ex_params = ($attr->{EXTRA_BTN_PARAMS})
    ? '&' . $attr->{EXTRA_BTN_PARAMS}
    : '';

  my $search_button = $html->button('', '', {
    NO_LINK_FORMER => 1,
    JAVASCRIPT     => 1,
    SKIP_HREF      => 1,
    ex_params      => qq{onclick="loadRawToModal('?qindex=$index&header=2&user_search_form=1$ex_params')"},
    class          => 'btn btn-default',
    ICON           => 'fa fa-search',
    %{$attr->{BTN_ATTR} // {}}
  });

  return $search_button;
}

#**********************************************************
=head2 append_comments($user_arrey_ref, $comment) - append $comment, to users from array

  Arguments:
    $users_arr
    $comment

=cut
#**********************************************************
sub append_comments {
  my ($users_arr, $comment) = @_;

  foreach my $uid (@$users_arr) {
    my $new_comment = $comment || '';
    if ($FORM{optradio} && $FORM{optradio} eq 'append') {
      my $user_info = $users->pi({ UID => $uid });
      $new_comment = ($user_info->{COMMENTS} ? "$user_info->{COMMENTS}\n" : '') . $comment;
    }
    $users->pi_change({ UID => $uid, COMMENTS => $new_comment });
    if (_error_show($users)) {
      return 0;
    }
  }

  return 1;
}

#**********************************************************
=head2 check_login_availability()
  check $FORM{login_check}
  return "success" if login avaiable
      or "error" if login already used
=cut
#**********************************************************
sub check_login_availability {
  if ($FORM{login_check}) {
    if ($FORM{login_check} =~ / /) {
      print "error";
      return 1;
    }

    $users->list({ LOGIN => $FORM{login_check} });

    if ($users->{TOTAL} > 0) {
      print "error";
    }
    else {
      print "success";
    }
  }
  else {
    print "error";
  }

  return 1;
}

#**********************************************************
=head2 contacts_validation($attr)

  Status:
    1 - valid contacts
    2 - invalid contacts
  Arguments:

  Returns:

=cut
#**********************************************************
sub contacts_validation {
  my ($attr) = @_;
  my $val_message = qq{};
  my $result = 0;

  foreach my $item (@$attr) {
    next if (!$item->{VALUE});
    if ($item->{TYPE_ID} == 1 && $conf{CELL_PHONE_FORMAT}) {
      if ($item->{VALUE} =~ /$conf{CELL_PHONE_FORMAT}/) {
        $result = 1;
      }
      else {
        $result = 2;
        $val_message .= $lang{WRONG} . ' ' . $lang{CELL_PHONE} . ': ' . $item->{VALUE} . '. ';
        return $result, $val_message;
      }
    }
    elsif ($item->{TYPE_ID} == 2 && $conf{PHONE_FORMAT}) {
      if ($item->{VALUE} =~ /$conf{PHONE_FORMAT}/) {
        $result = 1;
      }
      else {
        $result = 2;
        $val_message .= $lang{WRONG} . ' ' . $lang{PHONE} . ': ' . $item->{VALUE} . '. ';
        return $result, $val_message;
      }
    }
	### START KTK-39 ###
	elsif ($item->{TYPE_ID} eq '9' && $conf{EMAIL_FORMAT}) {
	if ($item->{VALUE} =~ /$conf{EMAIL_FORMAT}/) {
		$result = 1;
		}
	### END KTK-39 ###
      else {
        $result = 2;
        $val_message .= $lang{ERR_WRONG_EMAIL} . ': ' . $item->{VALUE} . '. ';
        return $result, $val_message;
      }
    }
  }

  return $result, $val_message;
}

#**********************************************************
=head2 unique_token_generate($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub unique_token_generate {
  my ($tokensize) = @_;

  my @alphanumeric = ('A' .. 'Z', 3);
  my $randtoken = join '', map $alphanumeric[rand @alphanumeric], 0 .. $tokensize;

  return $randtoken;
}

#**********************************************************
=head2 form_user_holdup()

=cut
#**********************************************************
sub form_user_holdup {
  my ($user_) = @_;
  my $uid = $user_->{UID} || '--';

  require Control::Service_control;
  Control::Service_control->import();
  my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

  my $holdup_info = $Service_control->user_holdup({
    %FORM,
    UID       => $uid,
    USER_INFO => $user_
  });

  if ($holdup_info->{error}) {
    my $error_message = $lang{$holdup_info->{errstr}} // $holdup_info->{errstr};
    $html->message('err', $lang{ERROR}, $error_message, { ID => $holdup_info->{error} })
  }

  if (!$holdup_info->{DEL}) {
    return '' if ($holdup_info->{error} || _error_show($holdup_info) || $holdup_info->{success});
    if (($user_->{STATUS} && $user_->{STATUS} == 3) || $user_->{DISABLE}) {
      $html->message('info', $lang{INFO}, "$lang{HOLD_UP}\n " .
        $html->button($lang{ACTIVATE}, "index=$index&del=1&ID=" . ($FORM{ID} || q{}) . "&sid=" . ($sid || q{}),
          { BUTTON => 2, MESSAGE => "$lang{ACTIVATE}?" }));
      return '';
    }

    $holdup_info->{FROM_DATE} = date_inc($DATE);
    $holdup_info->{TO_DATE} = $Service_control->{TO_DATE} || next_month({ DATE => $DATE });
    $holdup_info->{UID} = $uid;

    return $html->tpl_show(templates('form_user_holdup'), $holdup_info, { OUTPUT2RETURN => 1 });
  }
  else {
    $html->message('info', $lang{INFO}, "$lang{HOLD_UP}: $holdup_info->{DATE_FROM} $lang{TO} $holdup_info->{DATE_TO}"
      . ($holdup_info->{DEL_IDS} ? ($html->br() . $html->button($lang{DEL},
      "index=$index&holdup=1&UID=$uid&ID=" . ($FORM{ID} || q{}) . "&del=1&IDS=$holdup_info->{DEL_IDS}" . (($sid) ? "&sid=$sid" : q{}),
      { class => 'btn btn-primary', MESSAGE => "$lang{DEL} $lang{HOLD_UP}?" })) : q{}));
  }

  return q{};
}

#**********************************************************
=head2 form_money_transfer()

=cut
#**********************************************************
sub form_money_transfer_admin {

  my $deposit_limit = 0;
  my $transfer_price = 0;
  my $no_companies = q{};

  my Users $user = Users->new($db, $admin, \%conf);
  $user->info(int($FORM{UID} || 0));

  if ($conf{MONEY_TRANSFER} && $conf{MONEY_TRANSFER} =~ /:/) {
    ($deposit_limit, $transfer_price, $no_companies) = split(/:/, $conf{MONEY_TRANSFER});

    if ($no_companies eq 'NO_COMPANIES' && $user->{COMPANY_ID}) {
      $html->message('info', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");
      return 0;
    }
  }
  $transfer_price = sprintf("%.2f", $transfer_price);

  if ($FORM{s2} || $FORM{transfer}) {
    $FORM{SUM} = sprintf("%.2f", $FORM{SUM});

    if ($user->{DEPOSIT} < $FORM{SUM} + $deposit_limit + $transfer_price) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_SMALL_DEPOSIT}");
    }
    elsif (!$FORM{SUM}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_SUM}");
    }
    elsif (!$FORM{RECIPIENT}) {
      $html->message('err', $lang{ERROR}, "$lang{SELECT_USER}");
    }
    elsif ($FORM{RECIPIENT} == $FORM{UID}) {
      $html->message('err', $lang{ERROR}, "$lang{USER_NOT_EXIST}");
    }
    else {
      my $user2 = Users->new($db, $admin, \%conf);

      $user2->info(int($FORM{RECIPIENT}));

      if ($user2->{TOTAL} < 1) {
        $html->message('err', $lang{ERROR}, "$lang{USER_NOT_EXIST}");
      }
      else {
        $user2->pi({ UID => $user2->{UID} });
        if (!$FORM{ACCEPT} && $FORM{transfer}) {
          $html->message('err', $lang{ERROR}, "$lang{ERR_ACCEPT_RULES}");
          $html->tpl_show(templates('form_money_transfer_s2'), { %$user2, %FORM });
        }
        elsif ($FORM{transfer}) {
          if ($conf{user_confirm_changes}) {
            return 1 unless ($FORM{PASSWORD});
            $user->info($user->{UID}, { SHOW_PASSWORD => 1 });
            if ($FORM{PASSWORD} ne $user->{PASSWORD}) {
              $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD});
              return 1;
            }
          }

          #Fees
          my $Fees = Finance->fees($db, $admin, \%conf);
          $Fees->take(
            $user,
            $FORM{SUM},
            {
              DESCRIBE => "$lang{USER}: $user2->{UID}",
              METHOD   => 4
            }
          );

          if (!_error_show($Fees)) {
            $html->message('info', $lang{FEES},
              "UID: $user->{UID}, $lang{SUM}: $FORM{SUM}" . (($transfer_price > 0) ? " $lang{COMMISSION} $lang{SUM}: $transfer_price" : ''));
            my $Payments = Finance->payments($db, $admin, \%conf);

            #Payments
            $Payments->add(
              $user2,
              {
                DESCRIBE       => "$lang{USER}: $user->{UID}",
                INNER_DESCRIBE => "$Fees->{INSERT_ID}",
                SUM            => $FORM{SUM},
                METHOD         => 7
              }
            );

            if (!_error_show($Payments)) {
              my $message = "$lang{MONEY_TRANSFER}\n #$Payments->{INSERT_ID}\n UID: $user2->{UID}, $lang{SUM}: $FORM{SUM}";
              if ($transfer_price > 0) {
                $Fees->take(
                  $user,
                  $transfer_price,
                  {
                    DESCRIBE => "$lang{USER}: $user2->{UID} $lang{COMMISSION}",
                    METHOD   => 4,
                  }
                );
              }

              $html->message('info', $lang{PAYMENTS}, $message);
              $user2->{PAYMENT_ID} = $Payments->{INSERT_ID};
              cross_modules('payments_maked', { USER_INFO => $user2, QUITE => 1 });
            }
          }

        }
        elsif ($FORM{s2}) {
          $user2->{COMMISSION} = $transfer_price;
          $html->tpl_show(templates('form_money_transfer_s2'), { %$user2, %FORM });
        }
        return 0;
      }
    }
  }

  $html->tpl_show(templates('form_money_transfer_s1'), \%FORM);

  return 1;
}

#********************************************************
=head2 _user_auth_data_modal_content($attr) - show user access data as modal content

  Arguments:
    $@auth_data = ['some_login', 'some_fsdf_password']
    $auth_keys = ['LOGIN', 'PASSWD'] - used for lang keys

  Returns:
    $output - html

=cut
#********************************************************
sub _user_auth_data_modal_content {
  my ($auth_data, $auth_keys) = @_;

  my $output = '';

  $output .= $html->element('div',
    $html->element('h5', $lang{AUTH_DATA}, { class => 'card-title' }),
    { class => 'card-header', style => 'display: none' }
  );

  my $i = 0;
  for my $key (@$auth_keys) {
    my $field_name = $lang{$key} || $key;
    my $checked_data = $auth_data->[$i];
    my $escaped_notify = '';
    if ($checked_data =~ / |\n|\r|\"|\'/) {
      $checked_data = qq{"$auth_data->[$i]"};
      my $message = vars2lang($lang{ERR_SYMBOLS_FIELD}, { FIELD => $field_name });
      $escaped_notify = $html->element('b', "$lang{ATTENTION}! $message", { class => 'text-danger' }) . $html->br();
    }
    $output .= $html->b($field_name) . ": $checked_data" . $html->br() . $escaped_notify;
    $i++;
  }

  $output .= $html->br();

  my $buttons = '';

  $i = 0;
  for my $key (@$auth_keys) {
    $buttons .= $html->element('button',
      $lang{COPY} . ' ' . ($lang{$key} || $key),
      {
        class                   => 'btn btn-success mr-2',
        onclick                 => qq{copyToBuffer('$auth_data->[$i]')},
        'data-tooltip-position' => 'top',
        'data-tooltip'          => "$lang{COPIED}!",
        'data-tooltip-onclick'  => '1'
      }
    );
    $i++;
  }

  $output .= $html->element('div', $buttons, { class => 'd-flex justify-content-end' });
  return $output;
}

#********************************************************
=head2 _add_user_comment_to_info($attr) - check and add comment from user_pi to user timeline


=cut
#********************************************************
sub _add_user_comment_to_info {
  require Info;
  Info->import();
  my $Info = Info->new($db, $admin, \%conf);

  my $comments_list = $Info->get_comments('form_user_profile', $FORM{UID}, { COLS_NAME => 1 });

  foreach my $comment (@$comments_list) {
    if ($comment->{text} eq $FORM{COMMENTS}) {
      return 1;
    }
  }

  $Info->add_comment({
    OBJ_TYPE => 'form_user_profile',
    OBJ_ID   => $FORM{UID},
    TEXT     => $FORM{COMMENTS}
  });

  return 1;
}

1;
