=head1 NAME

  Quick reports for start page and other maintains

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array);

our (
  $db,
  %lang,
  $admin,
  %permissions
);

our AXbills::HTML $html;

#**********************************************************
=head2 form_quick_reports($attr)

=cut
#**********************************************************
sub form_quick_reports {
  my %START_PAGE_F = ();

  my %quick_reports = ();

  $quick_reports{last_payments} = $lang{LAST_PAYMENT} if ($permissions{1}{0} || $permissions{1}{3});
  $quick_reports{add_users} = $lang{REGISTRATION} if ($permissions{0}{2});
  $quick_reports{fin_summary} = $lang{DEBETORS} if ($permissions{1}{0} || $permissions{1}{3});
  $quick_reports{users_summary} = $lang{USERS} if (($permissions{1}{0} || $permissions{1}{3}) && $permissions{0}{2});
  $quick_reports{payments_types} = $lang{PAYMENT_TYPE} if (($permissions{1}{0} || $permissions{1}{3}) && $permissions{0}{2});
  $quick_reports{payments_self} = "$lang{PAYMENTS} $lang{TODAY}, $lang{YESTERDAY}" if (($permissions{1}{0} || $permissions{1}{3}) && $permissions{0}{2});

  foreach my $mod_name (@MODULES) {
    load_module($mod_name, $html);

    next if ($admin->{MODULES} && !$admin->{MODULES}{$mod_name});
    my $check_function = lc($mod_name) . '_start_page';

    if (defined(&{$check_function})) {
      my $START_PAGE_F = &{\&$check_function}();

      while (my ($k, $v) = each %{$START_PAGE_F}) {
        $quick_reports{"$mod_name:$k"} = $v if ($k);
      }

      %START_PAGE_F = ();
    }
  }

  if ($FORM{show_reports}) {
    $html->{METATAGS} = templates('metatags');
    print $html->header();

    if ($quick_reports{$FORM{show_reports}}) {
      my ($mod, $fn) = split(/:/, $FORM{show_reports});
      $fn = 'start_page_' . $mod if (!$fn);

      print &{\&$fn}();
    }

    return 0;
  }

  my $table = $html->table({
    width   => '640',
    caption => "$lang{QUICK} $lang{REPORTS}",
    title   => [ ' ', "$lang{NAME}", '-', "$lang{SHOW}" ],
    ID      => 'QR_LIST'
  });

  my @qr_arr = ();
  if ($admin->{SETTINGS} && $admin->{SETTINGS}{QUICK_REPORTS}) {
    @qr_arr = split(/, /, $admin->{SETTINGS}{QUICK_REPORTS});
  }

  foreach my $key (sort keys %quick_reports) {
    $table->addrow(
      $html->form_input('QUICK_REPORTS', "$key",
        { TYPE => 'checkbox', STATE => (in_array($key, \@qr_arr)) ? 'checked' : undef }),
      $key,
      $quick_reports{$key},
      $html->button("$lang{SHOW}", "qindex=4&show_reports=$key", { class => 'show' })
    );
  }

  return $table->show();
}

#**********************************************************
=head2 start_page_add_users() - quick reports for start page

=cut
#**********************************************************
sub start_page_add_users {
  return '' if (!$permissions{0}{2});

  my @priority_colors = ('btn-secondary', 'btn-info', 'btn-success', 'btn-warning', 'btn-danger');
  my $table = $html->table({
    width       => '100%',
    caption     => $html->button($lang{REGISTRATION}, "index=11&sort=uid&desc=DESC"),
    title_plain => [ $lang{LOGIN}, $lang{REGISTRATION}, $lang{ADDRESS}, $lang{DEPOSIT}, $lang{TAGS} ],
    ID          => 'QR_REGISTRATION'
  });

  my $list = $users->list({
    LOGIN        => '_SHOW',
    REGISTRATION => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    DEPOSIT      => '_SHOW',
    TAGS         => '_SHOW',
    SORT         => 'uid',
    DESC         => 'desc',
    PAGE_ROWS    => 5,
    COLS_NAME    => 1
  });


  foreach my $line (@{$list}) {
    my $tags = '';
    if ($line->{tags}) {
      my @tags_name = split(/,\s?/, $line->{tags});
      my @tags_priority = split(/,\s?/, $line->{priority});
      my @tags_colors = split(/,\s?/, $line->{tags_colors});

      for (my $tag_index= 0; $tag_index < scalar @tags_name; $tag_index++) {
        my $color = $tags_colors[$tag_index] || '';
        my $priority_color = $tags_priority[$tag_index] ? $priority_colors[$tags_priority[$tag_index]] : '';
        
        $tags .= $html->element('span', $tags_name[$tag_index], {
          class => $color ? 'label new-tags mb-1' : "btn btn-xs $priority_color",
          style => $color ? "background-color: $color; border-color: $color" : ''
        });
      }
    }

    $table->addrow(
      $html->button($line->{login}, "index=11&UID=$line->{uid}"),
      $line->{registration},
      $line->{address_full},
      $line->{deposit},
      $tags
    );
  }

  return $table->show();
}


#**********************************************************
=head2 start_page_last_payments($attr)

=cut
#**********************************************************
sub start_page_last_payments {
  return '' if (!$permissions{1}{0} && !$permissions{1}{3});

  my $table = $html->table({
    width       => '100%',
    caption     => "$lang{LAST_PAYMENT}",
    title_plain => [ "$lang{LOGIN}", "$lang{DATE}", "$lang{SUM}", "$lang{ADMIN}" ],
    ID          => 'LAST_PAYMENTS'
  });

  my $Payments = Finance->payments($db, $admin, \%conf);

  my $list = $Payments->list({
    LOGIN      => '_SHOW',
    DATETIME   => '_SHOW',
    SUM        => '_SHOW',
    ADMIN_NAME => '_SHOW',
    SORT       => 'date',
    DESC       => 'desc',
    PAGE_ROWS  => 5,
    COLS_NAME  => 1
  });

  foreach my $line (@{$list}) {
    $table->addrow(
      $html->button($line->{login}, "index=11&UID=$line->{uid}"),
      $line->{datetime},
      $line->{sum},
      $line->{admin_name}
    );
  }

  return $table->show();
}


#**********************************************************
=head2 start_page_fin_summary($attr)

=cut
#**********************************************************
sub start_page_fin_summary {
  return '' if (!$permissions{1}{0} && !$permissions{1}{3});

  my $Payments = Finance->payments($db, $admin, \%conf);
  $Payments->reports_period_summary();

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{PAYMENTS},
    title_plain => [ "$lang{PERIOD}", "$lang{COUNT}", "$lang{SUM}" ],
    ID          => 'FIN_SUMMARY',
    rows        => [
      [ $html->button($lang{DAY}, "index=2&DATE=$DATE&search=1"),
        $Payments->{DAY_COUNT}, $Payments->{DAY_SUM} ],
      [ $lang{WEEK}, $Payments->{WEEK_COUNT}, $Payments->{WEEK_SUM} ],
      [ $lang{MONTH}, $Payments->{MONTH_COUNT}, $Payments->{MONTH_SUM} ],
    ]
  });
  my $reports = $table->show();

  return $reports;
}

#**********************************************************
=head2 start_page_payments_types($attr)

=cut
#**********************************************************
sub start_page_payments_types {
  return '' if (!$permissions{1}{0} && !$permissions{1}{3});

  my $PAYMENT_METHODS = get_payment_methods();

  my $Payments = Finance->payments($db, $admin, \%conf);

  my $date_ = $FORM{yesterday} ? POSIX::strftime("%Y-%m-%d", localtime(time - int(1) * 86400)) : $DATE;

  my $list = $Payments->reports({
    TYPE      => 'PAYMENT_METHOD',
    INTERVAL  => "$date_/$date_",
    GID       => $admin->{GID} || undef,
    COLS_NAME => 1
  });

  my $today_class = "btn btn-primary " . ($FORM{today} ? "active" : "") . " btn-xs ml-2 my-n1";
  my $yesterday_class = "btn btn-primary " . ($FORM{yesterday} ? "active" : "") . " btn-xs my-n1";

  my $today_btn = $html->button($lang{TODAY}, "today=1", { class => "$today_class" });
  my $yesterday_btn = $html->button($lang{YESTERDAY}, "yesterday=1", { class => "$yesterday_class" });

  my $table = $html->table({
    width       => '100%',
    caption     => "$lang{PAYMENT_TYPE} " . $today_btn . " " . $yesterday_btn,
    title_plain => [ "$lang{TYPE}", "$lang{COUNT}", "$lang{SUM}" ],
    ID          => 'PAYMENTS_TYPES',
  });

  foreach my $line (@{$list}) {
    $table->addrow(
      $html->button($PAYMENT_METHODS->{$line->{method}}, "index=2&METHOD=$line->{method}&search=1"),
      $line->{count},
      $line->{sum},
    );
  }

  my $reports = $table->show();

  return $reports;
}


#**********************************************************
=head2 start_page_users_summary($attr)

=cut
#**********************************************************
sub start_page_users_summary {
  return '' if (!($permissions{1}{0} || $permissions{1}{3}) || !$permissions{0}{2});
  $users->report_users_summary({});

  my $table = $html->table({
    width   => '100%',
    caption => "$lang{USERS}",
    ID      => 'USERS_SUMMARY',
    rows    => [
      [ $html->button($lang{TOTAL}, "index=11"),
        $users->{TOTAL_USERS}, '' ],

      [ $html->button($lang{DISABLE}, "index=11&USERS_STATUS=3"),
        $users->{DISABLED_USERS}, '' ],

      [ $html->button($lang{DEBETORS}, "index=11&USERS_STATUS=2"),
        $users->{DEBETORS_COUNT}, $users->{DEBETORS_SUM} ],

      [ $html->button($lang{CREDIT}, "index=11&USERS_STATUS=5"),
        $users->{CREDITORS_COUNT}, $users->{CREDITORS_SUM} ],
    ]
  });

  return $table->show();
}


#**********************************************************
=head2 start_page_payments_self($attr)

=cut
#**********************************************************
sub start_page_payments_self {
  return '' if (!$permissions{1}{0} && !$permissions{1}{3});
  my $PAYMENT_METHODS = get_payment_methods();
  my $count = 0;
  my $all_sum = 0;

  my $Payments = Finance->payments($db, $admin, \%conf);
  my $list = $Payments->payment_report_admin({
    AID       => $admin->{AID},
    DATE      => $DATE,
    COLS_NAME => 1
  });

  $admin->info($admin->{AID});

  my $table = $html->table({
    width   => '100%',
    caption => "$lang{PAYMENTS} $lang{TODAY}, $lang{YESTERDAY}",
    ID      => 'TODAY_PAYMENTS',
    EXPORT  => 1,
  });

  $table->addrow($lang{DATE}, $DATE);
  $table->addrow($lang{ADMIN}, $admin->{A_FIO});
  $table->addrow(
    $html->b($lang{PAYMENT_TYPE}),
    $html->b($lang{SUM})
  );

  foreach (@$list) {
    $table->addrow(($PAYMENT_METHODS->{$_->{method}} || ''), ($_->{sum} || ''));

    $count += $_->{total} || 0;
    $all_sum += $_->{sum} || 0;
  }

  $table->addrow($lang{COUNT}, $count);
  $table->addrow($lang{TOTAL}, $all_sum);

  return $table->show();
}

1
