#!perl

=head1 NAME

  Userside

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(days_in_month);
use Finance;
use Internet::Sessions;
our Users $users;

our (
  %lang, 
  %permissions, 
  @MONTHES, 

  $db, 
  $admin, 
);

our AXbills::HTML $html;
my $Internet = Internet->new($db, $admin, \%conf);
my $Int_sessions = Internet::Sessions->new($db, $admin, \%conf);
my $Payments = Finance->payments($db, $admin, \%conf);

#**********************************************************

=head2 page($attr) 

=cut

#**********************************************************
sub userside_page {
  my ($uid) = @_;
  my $Internet_info = $Internet->user_info($uid);
  if ($Internet_info->{errno}) {
    $html->message("err", $lang{ERROR}, $lang{NOTABLES});
    return 1;
  }
  my Users $user_info = $users->pi({ UID => $uid });
  if ($users->{errno}) {
    $html->message("err", $lang{ERROR}, $lang{NOTABLES});
    return 1;
  }
  my $Int_sessions_info = $Int_sessions->list(
    {
      UID            => $uid,
      COLS_NAME      => 1,
      DURATION       => '_SHOW',
      BILL_ID        => '_SHOW',
      START_UNIXTIME => '_SHOW',
      SORT           => 'l.start',
      DESC           => 'DESC',
      START          => '_SHOW',
      END            => '_SHOW'
    }
  );
  if ($Int_sessions->{errno}) {
    $html->message("err", $lang{ERROR}, $lang{NOTABLES});
    return 1;
  }

  my $sessions_info = $Int_sessions->list(
    {
      UID       => $uid,
      COLS_NAME => 1,
      START     => '_SHOW',
      END       => '_SHOW'
    }
  );
  if ($Int_sessions->{errno}) {
    $html->message("err", $lang{ERROR}, $lang{NOTABLES});
    return 1;
  }

  my $online_sessions_info = $Int_sessions->online(
    {
      UID       => $uid,
      COLS_NAME => 1,
      STARTED     => '_SHOW',
    }
  );
  if ($Int_sessions->{errno}) {
    $html->message("err", $lang{ERROR}, $lang{NOTABLES});
    return 1;
  }

  my $list = $Payments->list(
    {
      %LIST_PARAMS,
      DATETIME  => '_SHOW',
      SUM       => '_SHOW',
      COLS_NAME => 1
    }
  );

  if ($Payments->{errno}) {
    $html->message("err", $lang{ERROR}, $lang{NOTABLES});
    return 1;
  }

  if($FORM{COMMENTS}){
    if($permissions{0}{4}){
      $users->pi_change({%FORM});
      if ( !$users->{errno} ){
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
      }
    }
    else
    {
      $html->message('err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");
    }
  }
  $user_info->{NOTES} = ($user_info->{COMMENTS}) ? $user_info->{COMMENTS} : '';

  my $user_pi       = get_function_index('user_pi');
  my $internet_user = get_function_index('internet_user');
  my $form_payments = get_function_index('form_payments');
  my $form_users    = get_function_index('form_users');

  $user_info->{FIO}   = ($permissions{0}{4}) 
   ? $html->button($user_info->{FIO}  || $lang{NO_DATAS}, "index=$user_pi&UID=$uid") 
   : $user_info->{FIO}   || $lang{NO_DATAS};
  $user_info->{LOGIN} = ($permissions{0}{4}) 
   ? $html->button($user_info->{LOGIN} || $lang{NO_DATAS}, "index=$user_pi&UID=$uid") 
   : $user_info->{LOGIN} || $lang{NO_DATAS};
  $user_info->{PHONE} = ($permissions{0}{4}) 
   ? $html->button($user_info->{PHONE} || $lang{NO_DATAS}, "index=$user_pi&UID=$uid") 
   : $user_info->{PHONE} || $lang{NO_DATAS};
  $user_info->{EMAIL} = ($permissions{0}{4}) 
   ? $html->button($user_info->{EMAIL} || $lang{NO_DATAS}, "index=$user_pi&UID=$uid") 
   : $user_info->{EMAIL} || $lang{NO_DATAS};
  $user_info->{SPEED_U} = $html->button($Internet_info->{SPEED} || 0, "index=$internet_user&UID=$uid");
  $user_info->{IP_MAC} =($Internet_info->{IP} && $Internet_info->{CID})
   ? $html->button("$Internet_info->{IP} $Internet_info->{CID}", "index=$internet_user&UID=$uid")
   : $html->button("$lang{NO_DATAS}", "index=" . $internet_user . "&UID=$uid");
  $user_info->{ADDRESS} =($permissions{0}{4}) 
   ? $html->button(($user_info->{CITY} || '') . ($user_info->{ADDRESS_STREET} || '') 
    . (" $lang{HOUSE_SMALL} $user_info->{ADDRESS_BUILD}" || '') . (" $lang{APRTAMENT_SMALL} $user_info->{ADDRESS_FLAT}" || ''),
    "index=$user_pi&UID=$uid")
   : ($user_info->{CITY} || '') . ($user_info->{ADDRESS_STREET} || '') . (" $lang{HOUSE_SMALL} $user_info->{ADDRESS_BUILD}" || '') 
    . (" $lang{APRTAMENT_SMALL} $user_info->{ADDRESS_FLAT}" || '');
  $user_info->{END} = $Int_sessions_info->[0]->{end} || "$lang{NEVER}";
  $user_info->{STATUS_NAME_USER} = ($user_info->{DISABLE}) 
   ? $html->color_mark("$lang{DISABLE}", $_COLORS[6])
   : $html->color_mark($lang{ENABLE}, '#00a65a');
  $user_info->{STATUS_USER} = $html->button($user_info->{STATUS_NAME_USER},
   "index=" . get_function_index('internet_form_shedule') . "&Shedule=status&UID=$uid");

  if (!$user_info->{CONTRACT_ID}) {
    $user_info->{NO_CONTRACT_MSG} = "$lang{NO_DATAS}";
    $user_info->{NO_DISPLAY}      = "style='display : none'";
  }

  #ADDITIONAL_DATA
  $user_info->{STATEMENT_OF_ACCOUNT} = $html->button("", "qindex=$form_users&STATMENT_ACCOUNT=10&UID=10&header=2",
   { class => '', ICON => 'fa fa-list-alt' });
  $user_info->{CONTRACT}             = $html->button("", "qindex=$form_users&UID=$uid&PRINT_CONTRACT=2&pdf=1",
   { class => '', ICON => 'fa fa-list-alt' });
  $user_info->{MEMO}                 = $html->button("", "qindex=$internet_user&UID=2&REGISTRATION_INFO=1",
   { class => '', ICON => 'fa fa-list-alt' });
  $user_info->{MEMO_PDF}             = $html->button("", "qindex=$internet_user&UID=2&REGISTRATION_INFO=1&pdf=1",
   { class => '', ICON => 'fa fa-list-alt' });

  $user_info->{PAYMENTS_BTN_NAME} = ($list->[0]->{sum} && $list->[0]->{datetime})
   ? $html->element('strong', "$list->[0]->{sum}") . $html->element('i', " ($list->[0]->{datetime})")
   : 0;
  $user_info->{PAYMENTS} = ($permissions{0}{15}) 
   ? $html->button($user_info->{PAYMENTS_BTN_NAME}, "index=$form_payments&UID=$uid")
   : $user_info->{PAYMENTS_BTN_NAME};

  $user_info->{DEPOSIT} = ($permissions{0}{15})
   ? $html->button($html->element('b', $user_info->{DEPOSIT}), "index=$form_payments&UID=$uid")
   : $html->element('b', $user_info->{DEPOSIT});

  $user_info->{REDUCTION} = ($permissions{0}{11})
    ? $html->button($html->element('strong', "$user_info->{REDUCTION}%") . $html->element('i', "($user_info->{REDUCTION_DATE})"),
     "index=" . $form_payments . "&UID=$uid")
    : $html->element('strong', "$user_info->{REDUCTION}%") . $html->element('i', "($user_info->{REDUCTION_DATE})");

  if (exists $conf{MONEY_UNIT_NAMES} && defined $conf{MONEY_UNIT_NAMES} && ref $conf{MONEY_UNIT_NAMES} eq 'ARRAY') {
    $user_info->{MONEY_UNIT_NAMES} = $conf{MONEY_UNIT_NAMES}->[0] || '';
  }

  $user_info->{CREDIT} = ($permissions{0}{9}) 
   ? $html->button($user_info->{CREDIT} || $lang{NO},
    "index=" . $form_payments . "&UID=$uid") . $html->element('i', "( $user_info->{CREDIT_DATE} )" || '')
   : $user_info->{CREDIT} || $lang{NO};

  $user_info->{TARIFF} = ($permissions{0}{10})
   ? $html->button($Internet_info->{TP_NAME} || $lang{NO}, 
    "index=" . get_function_index('internet_chg_tp') . "&UID=$uid") 
   : $Internet_info->{TP_NAME} || $lang{NO};

  if ( in_array( 'Info', \@MODULES ) ){
    load_module( 'Info', $html );
    $user_info->{INFO_COMMENTS_SHOW} = info_comments_show('admins', 25, { OUTPUT2RETURN => 1 });
  }

  $user_info->{PASSWD_BTN} = ($permissions{0}{3}) 
   ? $html->button("", "index=" . get_function_index('form_passwd') . "&UID=$uid", { class => '', ICON => 'fa fa-pencil-alt' })
   : $lang{NO_DATAS};

  $user_info->{GROUP_BTN} = ($permissions{0}{10})
   ? $html->button($user_info->{G_NAME} || $lang{NO},
    "index=" . get_function_index('user_group') . "&UID=$uid", { class => '', ICON => '' })
   : $user_info->{G_NAME} || $lang{NO};

  my @days = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31);

  my $table = $html->table(
    {
      width   => "100%",
      caption => $lang{ABON_ACTIVITY},
      title   => [ $lang{MONTH}, @days ],
      qs      => $pages_qs,
      ID      => "TABLE_ID",
      export  => 1
    }
  );

  my ($year, $month, $day) = split(/-/, $DATE);
  my %hash = ();
  my $start_month = '';
  my $start_day   = '';
  my $end_month   = '';
  my $end_day     = '';

  foreach my $item (@$sessions_info) {

    next if (!$item->{end} =~ m/$year/);

    ($start_month) = $item->{start} =~ m/^\d{4}-(\d{2})-\d{2}/;
    ($start_day)   = $item->{start} =~ m/^\d{4}-\d{2}-(\d{2})/;

    ($end_month) = $item->{end} =~ m/^\d{4}-(\d{2})-\d{2}/;
    ($end_day)   = $item->{end} =~ m/^\d{4}-\d{2}-(\d{2})/;

    while (($start_month != $end_month && $start_day != $end_day) && ($end_month != 1 && $end_day != 1)) {
      $hash{ $MONTHES[ $end_month - 1 ] }{$end_day} = 1;
      if ($end_day > 1) {
        $end_day--;
      }
      else {
        $end_month--;
        $end_day = days_in_month({ DATE => "$year-" . sprintf("%02s", $end_month) . "" });
      }
    }
    $hash{ $MONTHES[ $start_month - 1 ] }{$start_day} = 1;

  }

  my $online_month = '';
  my $online_day = '';
  if($Int_sessions->{TOTAL}>0)
  {
    ($online_month) = $online_sessions_info->[0]->{started} =~ m/^\d{4}-(\d{2})-\d{2}/;
    ($online_day)   = $online_sessions_info->[0]->{started} =~ m/^\d{4}-\d{2}-(\d{2})/;
    $hash{ $MONTHES[ $online_month - 1 ] }{$online_day} = 1;
    while($online_month != $month && $online_day != $day){
      if ($online_day != days_in_month({ DATE => "$year-" . sprintf("%02s", $online_month) . "" })) {
        $online_day++;
      }
      else {
        $online_month++;
      }
      $hash{ $MONTHES[ $online_month - 1 ] }{$online_day} = 1;
    }
  }

  my @data = ();
  foreach my $c_month (@MONTHES) {
    @data = ();
    foreach my $c_day (@days) {
      if ($hash{$c_month}{"0$c_day"} || $hash{$c_month}{$c_day}) {
        push @data, $html->element('span', '', { class => "fa fa-check-circle text-green", title => "$c_day" });
      }
      else {
        push @data, $html->element('span', '', { class => "fa fa-times-circle text-red", title => "$c_day" });
      }
    }
    $table->addrow($c_month, @data);
  }

  $user_info->{TABLE} = $table->show();
  return $html->tpl_show(templates('form_user_userside_like'), { %$user_info, %$Internet_info });
}