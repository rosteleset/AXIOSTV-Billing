#package Paysys::UserPortal;
=head1 NAME

  User Portal

=cut

use strict;
use warnings FATAL => 'all';
use Paysys::Init;
use Users;
use Paysys;
use AXbills::Base qw(ip2int in_array mk_unique_value cmd);

our (
  $base_dir,
  $admin,
  $db,
  %conf,
  %lang,
  @status,
  @status_color,
  %FORM
);

our Paysys $Paysys;
our AXbills::HTML $html;

#**********************************************************
=head2 paysys_payment($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub paysys_payment {
  my ($attr) = @_;
  my $index = get_function_index('paysys_payment');

  my %TEMPLATES_ARGS = ();
  $user->pi({ UID => $user->{UID} });

  $FORM{OPERATION_ID} =~ s/[<>]//gm if ($FORM{OPERATION_ID});
  $FORM{DESCRIBE} =~ s/[<>]//gm if ($FORM{DESCRIBE});

  if ($FORM{SUM}) {
    $FORM{SUM} = 0 if ($FORM{SUM} !~ /^[\.\,0-9]+$/);
    $FORM{SUM} = sprintf("%.2f", $FORM{SUM});
  }
  else {
    $FORM{SUM} = 0;
  }

  if ($FORM{SUM} == 0 && $user && defined &recomended_pay) {
    $FORM{SUM} = recomended_pay($user) || 1;
  }

  my $paysys_id = $FORM{PAYMENT_SYSTEM};
  if ($FORM{PAYMENT_SYSTEM} && $conf{PAYSYS_MIN_SUM} && $FORM{SUM} > 0 && $conf{PAYSYS_MIN_SUM} > $FORM{SUM}) {
    $html->message('err', $lang{ERROR}, "$lang{PAYSYS_MIN_SUM_MESSAGE} $conf{PAYSYS_MIN_SUM}");
    delete $FORM{PAYMENT_SYSTEM};
  }
  elsif ($FORM{PAYMENT_SYSTEM} && $conf{PAYSYS_MAX_SUM} && $FORM{SUM} > 0 && $conf{PAYSYS_MAX_SUM} < $FORM{SUM}) {
    $html->message('err', $lang{ERROR}, "ERR_BIG_SUM: $conf{PAYSYS_MAX_SUM}");
    delete $FORM{PAYMENT_SYSTEM};
  }

  if ($user->{GID}) {
    $user->group_info($user->{GID});
    if ($user->{DISABLE_PAYSYS}) {
      $html->message('err', $lang{ERROR}, "$lang{DISABLE}");
      return 0;
    }
  }

  if ($conf{PAYSYS_IPAY_FAST_PAY}) {
    if ($FORM{ipay_pay}) {
      if ($FORM{ipay_pay} && $FORM{SUM} <= 0) {
        $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_SUM});
        return 1;
      }

      if ($conf{PAYSYS_MIN_SUM} && $FORM{SUM} > 0 && $conf{PAYSYS_MIN_SUM} > $FORM{SUM}) {
        return $html->message('err', $lang{ERROR}, "$lang{PAYSYS_MIN_SUM_MESSAGE} $conf{PAYSYS_MIN_SUM}");
      }
      elsif ($conf{PAYSYS_MAX_SUM} && $FORM{SUM} > 0 && $conf{PAYSYS_MAX_SUM} < $FORM{SUM}) {
        return $html->message('err', $lang{ERROR}, "ERR_BIG_SUM: $conf{PAYSYS_MAX_SUM}");
      }

      my $paysys_plugin = _configure_load_payment_module('Ipay_mp.pm');
      my $Paysys_plugin = $paysys_plugin->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang, INDEX => $index, SELF_URL => $SELF_URL });
      $TEMPLATES_ARGS{IPAY_HTML} .= $Paysys_plugin->user_portal_special($user, { %FORM, %{($attr) ? $attr : {}} });
      return 1;
    }
  }

  if ($FORM{PAYMENT_SYSTEM}) {
    if (paysys_external_cmd()) {
      return 1;
    }

    my $payment_system_info = $Paysys->paysys_connect_system_info({
      PAYSYS_ID => $FORM{PAYMENT_SYSTEM},
      MODULE    => '_SHOW',
      NAME      => '_SHOW',
      COLS_NAME => '_SHOW'
    });

    if ($Paysys->{errno}) {
      print $html->message('err', $lang{ERROR}, 'Payment system not exist');
    }
    else {
      my $Module = _configure_load_payment_module($payment_system_info->{module});
      my $Paysys_plugin = $Module->new($db, $admin, \%conf, {
        HTML        => $html,
        lang        => \%lang,
        CUSTOM_NAME => $payment_system_info->{name},
        CUSTOM_ID   => $payment_system_info->{paysys_id}
      });
      $attr->{EXTRA_DESCRIPTIONS} = q{};
      my $params = $Paysys->gid_params({
        GID       => $user->{GID} || 0,
        PAYSYS_ID => $FORM{PAYMENT_SYSTEM},
        LIST2HASH => 'param,value'
      });

      if (scalar keys %{$params}) {
        my ($payment_description) = grep {/PORTAL_DESCRIPTION/g} keys %{$params};
        if ($payment_description && $params->{$payment_description}) {
          my @descriptions = split /;/, $params->{$payment_description};

          foreach my $description (@descriptions) {
            my ($title, $desc) = split (/:/, ($description || ''));
            $attr->{EXTRA_DESCRIPTIONS} .= $html->tpl_show(_include('paysys_portal_payment_description', 'Paysys'),
              { DESCRIPTION => $desc, TITLE => $title }, { OUTPUT2RETURN => 1 });
          }
        }
      }

      return $Paysys_plugin->user_portal($user, { %FORM, %{($attr) ? $attr : {}} });
    }
  }

  my $connected_systems = $Paysys->paysys_connect_system_list({
    PAYSYS_ID    => '_SHOW',
    NAME         => '_SHOW',
    MODULE       => '_SHOW',
    SUBSYSTEM_ID => '_SHOW',
    STATUS       => 1,
    COLS_NAME    => 1,
    SORT         => 'priority',
  });

  my $list = $Paysys->paysys_merchant_to_groups_info({
    COLS_NAME => 1,
    DOMAIN_ID => $ENV{DOMAIN_ID} || $user->{DOMAIN_ID} || '_SHOW'
  });

  foreach my $system (@$connected_systems) {
    foreach my $merchant (@$list) {
      next unless ($merchant->{gid} && $merchant->{system_id} && $system->{id} && $user->{GID});
      if ($merchant->{system_id} == $system->{id} && $merchant->{gid} == $user->{GID}) {
        $system->{merchant_name} = $merchant->{merchant_name};
      }
    }
  }

  $TEMPLATES_ARGS{OPERATION_ID} = mk_unique_value(8, { SYMBOLS => '0123456789' });
  if ($conf{PAYSYS_USER_PORTAL_MAP} && in_array('Maps', \@MODULES) && !$FORM{json}) {
    require Paysys::Maps;
    $TEMPLATES_ARGS{MAP} = paysys_maps_new();
  }

  my $groups_settings = $Paysys->groups_settings_list({
    PAYSYS_ID => '_SHOW',
    GID       => '_SHOW',
    DOMAIN_ID => $ENV{DOMAIN_ID} || $user->{DOMAIN_ID} || '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 9999,
  });

  my %group_to_paysys_id = ();
  foreach my $group_settings (@$groups_settings) {
    push(@{$group_to_paysys_id{$group_settings->{gid}}}, $group_settings->{paysys_id});
  }

  my $count = 1;
  my @payment_systems = ();

  foreach my $payment_system (@$connected_systems) {
    next if (defined($user->{GID})
      && exists $group_to_paysys_id{$user->{GID}}
      && !(in_array($payment_system->{paysys_id}, $group_to_paysys_id{$user->{GID}})));

    next if (defined($user->{GID}) && !$group_to_paysys_id{$user->{GID}});

    my $Plugin = _configure_load_payment_module($payment_system->{module});
    if ($Plugin->can('user_portal')) {
      my $checked = ($paysys_id) ?
        (($paysys_id == $payment_system->{paysys_id}) ?
          'checked' : '') : $count == 1 ? 'checked' : '';

      my $subsystem_name = q{};
      if ($payment_system->{subsystem_id}) {
        my %SETTINGS = $Plugin->get_settings();
        if ($SETTINGS{SUBSYSTEMS} && ref $SETTINGS{SUBSYSTEMS} eq 'HASH' &&  exists($SETTINGS{SUBSYSTEMS}{$payment_system->{subsystem_id}})) {
          $subsystem_name = $SETTINGS{SUBSYSTEMS}{$payment_system->{subsystem_id}};
        }
      }

      push @payment_systems, _paysys_system_radio({
        NAME           => $payment_system->{merchant_name} || $payment_system->{name},
        SUBSYSTEM_NAME => $subsystem_name,
        MODULE         => $payment_system->{module},
        ID             => $payment_system->{paysys_id},
        CHECKED        => $checked,
        GID            => $user->{GID},
      });
      $count++;
    }
    elsif ($Plugin->can('user_portal_special')) {
      my $Paysys_plugin = $Plugin->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang, INDEX => $index, SELF_URL => $SELF_URL });
      my $portal = $Paysys_plugin->user_portal_special($user, { %FORM });
      $TEMPLATES_ARGS{IPAY_HTML} .= $portal if ($portal);
    }
  }

  if ($#payment_systems > -1) {
    my $delimiter = q{};
    if ($FORM{json}) {
      $delimiter = ',';
    }
    $TEMPLATES_ARGS{PAY_SYSTEM_SEL} = join($delimiter, @payment_systems);
  }

  if ($attr->{HOTSPOT}) {
    return $TEMPLATES_ARGS{PAY_SYSTEM_SEL};
  }

  return $html->tpl_show(_include('paysys_main', 'Paysys'), {
    %TEMPLATES_ARGS,
    SUM => $FORM{SUM}
  }, {
    OUTPUT2RETURN => $attr->{OUTPUT2RETURN},
    ID            => 'PAYSYS_FORM'
  });
}

#**********************************************************
=head2 paysys_external_cmd() - Make external cmd

  Arguments:
    $attr

  Return:

=cut
#**********************************************************
sub paysys_external_cmd {

  my $uid = $user->{UID};

  if ($conf{PAYSYS_EXTERNAL_START_COMMAND}) {
    my $start_command = $conf{PAYSYS_EXTERNAL_START_COMMAND} || q{};
    my $attempts = $conf{PAYSYS_EXTERNAL_ATTEMPTS} || 0;
    my $user_info = $Paysys->user_info({ UID => $uid });

    if (!$user_info->{TOTAL}) {
      $Paysys->user_add({
        ATTEMPTS         => 1,
        UID              => $uid,
        EXTERNAL_USER_IP => $ENV{REMOTE_ADDR}
      });
    }
    else {
      my (undef, $now_month) = split('-', $DATE);
      my (undef, $last_month) = split('-', $user_info->{EXTERNAL_LAST_DATE});

      if (int($now_month) > int($last_month)
        || ($user_info->{ATTEMPTS} && (!$attempts || $user_info->{ATTEMPTS} < $attempts))) {
        my $paysys_id = $user_info->{PAYSYS_ID};
        if (int($now_month) > int($last_month)) {
          $Paysys->user_change({
            ATTEMPTS           => 1,
            UID                => $uid,
            PAYSYS_ID          => $paysys_id,
            EXTERNAL_LAST_DATE => "$DATE $TIME",
            EXTERNAL_USER_IP   => ip2int($ENV{REMOTE_ADDR}),
            CLOSED             => (int($now_month) > int($last_month)) ? 0 : 1
          });
        }
        else {
          my $user_attempts = $user_info->{ATTEMPTS} + 1;
          $Paysys->user_change({
            ATTEMPTS           => $user_attempts,
            UID                => $uid,
            PAYSYS_ID          => $paysys_id,
            CLOSED             => 0,
            EXTERNAL_LAST_DATE => "$DATE $TIME",
            EXTERNAL_USER_IP   => ip2int($ENV{REMOTE_ADDR}),
          });
        }
      }
    }

    my $result = cmd($start_command, {
      PARAMS => { %$user, IP => $ENV{REMOTE_ADDR} },
    });

    if ($result && $result =~ /(\d+):(.+)/) {
      my $code = $1;
      my $text = $2;

      if ($code == 1) {
        my $button = $html->button("$lang{SET} $lang{CREDIT}", "OPEN_CREDIT_MODAL=1", { class => 'btn btn-success' });
        $html->message('warn', $text, $button,);
        return 1;
      }

      if ($code) {
        $html->message('warn', $lang{INFO}, $text, { ID => 1730 });
        return 1;
      }
    }
  }

  return 0;
}

#**********************************************************
=head2 _paysys_system_radio($attr) - Show availeble payment system

  Arguments:
    $attr
      ID
      NAME
      MODULE

  Return:

=cut
#**********************************************************
sub _paysys_system_radio {
  my ($attr) = @_;

  my $commission = 0;
  my $radio_paysys;
  my $paysys_logo_path = $base_dir . 'cgi-bin/styles/default/img/paysys_logo/';
  my $file_path = q{};

  my $paysys_name = $attr->{NAME};
  my ($paysys_module) = $attr->{MODULE} =~ /(.+)\.pm$/;
  $paysys_module =~ s/ /_/g;
  $paysys_module = lc($paysys_module);

  if ($attr->{SUBSYSTEM_NAME} && -e "$paysys_logo_path" . lc($attr->{SUBSYSTEM_NAME}) . '-logo.png') {
    $file_path = '/styles/default/img/paysys_logo/' . lc($attr->{SUBSYSTEM_NAME}) . '-logo.png';
  }
  elsif (-e "$paysys_logo_path" . lc($paysys_module) . '-logo.png') {
    $file_path = '/styles/default/img/paysys_logo/' . lc($paysys_module) . '-logo.png';
  }

  my $params = $Paysys->gid_params({
    GID       => $attr->{GID},
    PAYSYS_ID => $attr->{ID},
    LIST2HASH => 'param,value'
  });

  if (scalar keys %{$params}) {
    my ($payment_commission) = grep {/PORTAL_COMMISSION/g} keys %{$params};
    $commission = $params->{$payment_commission} if ($payment_commission && $params->{$payment_commission});
  }

  $radio_paysys .= $html->tpl_show(_include('paysys_system_select', 'Paysys'),
    {
      PAY_SYSTEM_LC     => $file_path,
      PAY_SYSTEM        => $attr->{ID},
      PAY_SYSTEM_NAME   => $paysys_name,
      CHECKED           => $attr->{CHECKED},
      HIDDEN            => $conf{PAYSYS_USER_PORTAL_BTN_TEXT} ? '' : 'hidden hidden-btn-text',
      COMMISSION_HIDDEN => $commission ? '' : 'hidden',
      COMMISSION        => $commission
    },
    {
      OUTPUT2RETURN => 1,
      ID            => 'PAYSYS_' . $attr->{ID}
    }
  );

  return $radio_paysys;
}

#**********************************************************
=head2 paysys_user_log()

=cut
#**********************************************************
sub paysys_user_log {

  my %PAY_SYSTEMS = ();

  my $connected_systems = $Paysys->paysys_connect_system_list({
    PAYSYS_ID => '_SHOW',
    NAME      => '_SHOW',
    MODULE    => '_SHOW',
    STATUS    => 1,
    COLS_NAME => 1,
  });

  foreach my $payment_system (@$connected_systems) {
    $PAY_SYSTEMS{$payment_system->{paysys_id}} = $payment_system->{name};
  }

  if ($FORM{info}) {
    $Paysys->info({ ID => $FORM{info} });

    my @info_arr = split(/\n/, $Paysys->{INFO});
    my $table = $html->table({ width => '100%' });
    foreach my $line (@info_arr) {
      if ($line) {
        my ($k, $v) = split(/,/, $line, 2);
        $table->addrow($k, $v) if ($k =~ /STATUS/);
      }
    }

    $Paysys->{INFO} = $table->show({ OUTPUT2RETURN => 1 });

    $table = $html->table({
      width => '500',
      rows  =>
        [ [ "ID", $Paysys->{ID} ],
          [ "$lang{LOGIN}", $Paysys->{LOGIN} ],
          [ "$lang{DATE}", $Paysys->{DATETIME} ],
          [ "$lang{SUM}", $Paysys->{SUM} ],
          [ "$lang{PAY_SYSTEM}", $PAY_SYSTEMS{ $Paysys->{SYSTEM_ID} } ],
          [ "$lang{TRANSACTION}", $Paysys->{TRANSACTION_ID} ],
          [ "$lang{USER} IP", $Paysys->{CLIENT_IP} ],
          [ "$lang{ADD_INFO}", $Paysys->{USER_INFO} ],
          [ "$lang{INFO}", $Paysys->{INFO} ] ],
    });

    print $table->show();
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $date_show = '';
  if ($conf{user_payment_journal_show}) {
    $LIST_PARAMS{SHOW_PAYMENT} = 1;
    use POSIX qw(strftime);

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();

    $mday = 1;
    $mon = $mon - $conf{user_payment_journal_show} + 1;
    if ($mon == 13) {
      $mon = 1;
      $year++;
    }
    $date_show = POSIX::strftime('%Y-%m-%d', ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst));
    $LIST_PARAMS{DATE} = ">$date_show";
  }

  my $list = $Paysys->list({ %LIST_PARAMS, COLS_NAME => 1 });

  my $table = $html->table(
    {
      width   => '100%',
      caption => "$lang{PAY_JOURNAL}",
      title   => [
        'ID',
        "$lang{DATE}",
        "$lang{SUM}",
        "$lang{PAY_SYSTEM}",
        "$lang{TRANSACTION}",
        "$lang{STATUS}",
        '-'
      ],
      qs      => $pages_qs,
      pages   => $Paysys->{TOTAL},
      ID      => 'PAYSYS',
    }
  );

  foreach my $line (@$list) {
    $table->addrow($line->{id},
      $line->{datetime},
      $line->{sum},
      $PAY_SYSTEMS{$line->{system_id}},
      $line->{transaction_id},
      $html->color_mark($status[$line->{status}], "$status_color[$line->{status}]"),
      $html->button($lang{INFO}, "index=$index&info=$line->{id}"));
  }
  print $table->show();

  $table = $html->table(
    {
      caption => $lang{ALL},
      width   => '100%',
      rows    => [
        [ "$lang{TOTAL}:", $html->b($Paysys->{TOTAL_COMPLETE}), "$lang{SUM}:", $html->b($Paysys->{SUM_COMPLETE}) ]
      ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 paysys_subscribe()

=cut
#**********************************************************
sub paysys_subscribe {

  my $paysys_subscribe = $Paysys->user_info({
    UID => $user->{UID},
  });

  my $table = $html->table({
    width   => '100%',
    caption => $lang{TOKEN_PAYMENTS},
    title   => [ $lang{DATE}, $lang{SUM}, $lang{PAY_SYSTEM}, $lang{TRANSACTION}, $lang{STATUS}, '-' ],
    qs      => $pages_qs,
    pages   => $Paysys->{TOTAL},
    ID      => 'PAYSYS_SUBSCRIBES',
  });

  if (defined($paysys_subscribe->{PAYSYS_ID}) && $paysys_subscribe->{PAYSYS_ID} == 0) {
    $Paysys->user_del({
      PAYSYS_ID => $paysys_subscribe->{PAYSYS_ID},
      UID       => $paysys_subscribe->{UID}
    });
  }

  if ($paysys_subscribe->{EXTERNAL_LAST_DATE}) {
    my $btn_index = 'index=' . get_function_index('paysys_payment') . '&PAYMENT_SYSTEM=' . $paysys_subscribe->{PAYSYS_ID} . '&SUM=1.00&UNTOKEN=1';
    my $Users = Users->new($db, $admin, \%conf);
    if ($paysys_subscribe->{PAYSYS_ID} == 62) {
      my $list = $Users->list({
        GID        => '_SHOW',
        COLS_NAME  => 1,
        COLS_UPPER => 1,
        UID        => $paysys_subscribe->{UID}
      });

      my $default_conf_token = $paysys_subscribe->{conf}->{"PAYSYS_LIQPAY_SUBSCRIBE_TOKEN"} || 0;
      my $default_conf_sub = $paysys_subscribe->{conf}->{"PAYSYS_LIQPAY_SUBSCRIBE"} || 0;
      my $gid_conf_token = $paysys_subscribe->{conf}->{"PAYSYS_LIQPAY_SUBSCRIBE_TOKEN_$list->[0]->{GID}"} || 0;
      my $gid_conf_sub = $paysys_subscribe->{conf}->{"PAYSYS_LIQPAY_SUBSCRIBE_$list->[0]->{GID}"} || 0;

      if ($gid_conf_sub == 1 || ($default_conf_sub == 1 && !$gid_conf_sub)) {
        $btn_index = 'index=' . get_function_index('paysys_payment') . '&PAYMENT_SYSTEM=' . $paysys_subscribe->{PAYSYS_ID} . '&SUM=1.00&UNSUBSRIBE=1&UID=' . $paysys_subscribe->{UID};
      }
      elsif ($gid_conf_token == 1 || ($default_conf_token == 1 && !$gid_conf_token)) {
        $btn_index = 'index=' . get_function_index('paysys_payment') . '&PAYMENT_SYSTEM=' . $paysys_subscribe->{PAYSYS_ID} . '&SUM=1.00&UNTOKEN=1&UID=' . $paysys_subscribe->{UID};
      }
    }

    $table->addrow($paysys_subscribe->{EXTERNAL_LAST_DATE},
      $paysys_subscribe->{SUM},
      $paysys_subscribe->{RECURRENT_MODULE},
      $paysys_subscribe->{ORDER_ID},
      $lang{ENABLED},
      $html->button($lang{DEL}, $btn_index));
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 paysys_system_sel()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_system_sel {
  return paysys_payment({ HOTSPOT => 1 });
}

#**********************************************************
=head2 paysys_recurrent_payment()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_recurrent_payment {
  my %data = ();

  if ($FORM{RECURRENT_CANCEL}) {
    my $Pasysy_plugin = _configure_load_payment_module("$FORM{PAYSYSTEM_NAME}.pm");
    my $result_code = q{};
    my $result = q{};
    if ($Pasysy_plugin->can('recurrent_cancel')) {
      my $PAYSYS_OBJECT = $Pasysy_plugin->new($db, $admin, \%conf);
      ($result_code, $result) = $PAYSYS_OBJECT->recurrent_cancel({ %FORM });
    }
    if ($result_code eq '200') {
      $html->message('info', $lang{INFO}, "The regular payment is canceled!");
      return 1;
    }
    else {
      $html->message('err', $lang{ERROR}, "The regular payment can not be canceled!");
      return 1;
    }
  }

  my $info = $Paysys->user_info({
    UID       => $user->{UID},
    COLS_NAME => 1
  });

  if (!$info->{RECURRENT_ID}) {
    $html->message('err', $lang{ERROR}, "No regular payment");
    return 0;
  }

  if ($Paysys->{errno}) {
    $html->message('err', $lang{ERROR}, "Error Paysys: $Paysys->{errstr}");
    return 0;
  }

  if (!$info->{RECURRENT_MODULE}) {
    $html->message('err', $lang{ERROR}, "No paysys system");
    return 0;
  }

  my ($recurrent_day) = $info->{RECURRENT_CRON} =~ /\d+\s\d+\s(\d+)/g;
  $data{MESSAGE} = qq{$lang{RECURRENT_MESSAGE} $recurrent_day $lang{RECURRENT_MESSAGE2}};
  $data{PAYSYSTEM_NAME} = qq{$info->{RECURRENT_MODULE}};
  $data{RECURRENT_ID} = qq{$info->{RECURRENT_ID}};
  $data{INDEX} = get_function_index('paysys_recurrent_payment');

  $html->tpl_show(_include('paysys_recurrent_payment', 'Paysys'), \%data);

  return 1;
}

1;
