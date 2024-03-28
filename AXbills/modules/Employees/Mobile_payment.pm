=head1 NAME

  Employees:Mobile_payment

=head2 SYNOPSIS

  This is code for replenishment of mobile account.
  Works with PrivatBank Api for mobile.

=cut


use strict;
use warnings FATAL => 'all';
use Employees;
use AXbills::Base qw(days_in_month mk_unique_value);
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha1_hex);
use AXbills::Fetcher qw/web_request/;

our (
  $db,
  %conf,
  $admin,
  %lang,
  $html,
);

my $Employees = Employees->new($db, $admin, \%conf);

#**********************************************************
=head2 employees_mobile_set($attr) - setting up the payments mobile account

    This function shows two forms for setting up the payments mobile account

  Arguments:
    $attr -

  Returns:
    true
=cut
#**********************************************************
sub employees_mobile_set {
  my %statuses = ('1' => $lang{ENABLE}, '2' => $lang{DISABLE});
  my %info = ();
  $info{ACTION} = 'add';
  $info{LNG_ACTION} = $lang{SAVE};

  if ($FORM{PAY_NOW}) {
    employees_mobile_pay(\%FORM);
  }

  if ($FORM{add}) {
    $Employees->employees_ext_params_add({ %FORM });

    unless ($Employees->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}");
    }
    else {
      $html->message('err', $lang{ERROR}, "$Employees->{errno} Wrong value or dublicate");
    }
  }
  elsif ($FORM{change}) {
    $Employees->employees_ext_params_change({ %FORM });

    if (!$Employees->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{chg}) {
    $Employees->employees_ext_params_info({ ID => $FORM{chg} });
    if (!$Employees->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGING}");
    }
    $info{ACTION} = 'change';
    $info{LNG_ACTION} = $lang{CHANGE};
    $info{ID} = $FORM{chg};
  }
  elsif ($FORM{del}) {
    $Employees->employees_ext_params_del($FORM{del});

    if (!$Employees->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }

  if ($FORM{add_form}) {
    $info{DAY_NUM} = $html->form_input(
      "DAY_NUM", $Employees->{DAY_NUM} || '', {
      class     => 'form-control',
      TYPE      => 'number',
      EX_PARAMS => 'min="1" max="28" step="1"'
    });
    $info{MOB_SUM} = $html->form_input(
      "SUM", $Employees->{SUM} || '', {
      class     => 'form-control',
      TYPE      => 'number',
      EX_PARAMS => 'step="0.01" min="0"'
    });
    $info{MOB_STATUS} = $html->form_select(
      "STATUS",
      {
        SELECTED => $Employees->{STATUS} || '2',
        SEL_HASH => \%statuses,
        NO_ID    => 1,
        SORT_KEY => 1
      });

    my $admin_list = $admin->list({
      ADMIN_NAME => '_SHOW',
      CELL_PHONE => '_SHOW',
      DISABLE    => 0,
      COLS_NAME  => 1,
      PAGE_ROWS  => 9999,
    });

    $info{ADMINS} = $html->form_select('AID',
      {
        SELECTED    => $Employees->{AID} || '0',
        SEL_LIST    => $admin_list,
        SEL_KEY     => 'aid',
        SEL_VALUE   => 'name',
        NO_ID       => 1,
        SEL_OPTIONS => { '0' => '--' },
      });
    $info{CELL_PHONE} = $html->form_input(
      "PHONE", $Employees->{PHONE} || '', {
      class => 'form-control',
      TYPE  => 'number',
    });
    $info{MOB_COMMENT} = $Employees->{MOB_COMMENT} || '';

    $html->tpl_show(_include('employees_mobile_add', 'Employees'), { %info });
  }

  my $table = $html->table({
    width      => '100%',
    caption    => $lang{MOBILE_PAY_SET} . " " . $lang{EMPLOYEES},
    title      => [ "#", $lang{EMPLOYEE}, $lang{CELL_PHONE}, $lang{DAY} . " " . $lang{MONTHES_A}, $lang{SUM}, $lang{STATUS}, $lang{COMMENTS}, '', '',],
    ID         => 'MOB_PAY_ID',
    DATA_TABLE => 1,
    MENU       => "$lang{ADD}:index=$index&add_form=1:add",
  });

  my $mob_info = $Employees->employees_ext_params_list({
    NAME        => '_SHOW',
    AID         => '_SHOW',
    PHONE       => '_SHOW',
    SUM         => '_SHOW',
    DAY_NUM     => '_SHOW',
    STATUS      => '_SHOW',
    MOB_COMMENT => '_SHOW',
    COLS_NAME   => 1
  });

  foreach (@$mob_info) {
    my $aid = $_->{aid} || '';
    my $phone = $_->{phone} || '';
    my $sum = $_->{sum} || '';
    my $change = $html->button($lang{CHANGE}, "index=$index&chg=$_->{id}&add_form=1", { class => 'change' });
    my $delete = $html->button($lang{DEL}, "index=$index&del=$_->{id}", { MESSAGE => "$lang{DEL} " . ($_->{name} || '') . "\n $lang{PHONE}: $phone?", class => 'del' });

    $table->addrow(
      $aid,
      $_->{name} || '',
      $phone,
      $_->{day_num} || '',
      $sum,
      $statuses{$_->{status}} || '',
      $_->{mob_comment} || '',
      $html->button($lang{PAY}, "index=$index&AID=$aid&CELL=$phone&SUM=$sum&PAY_NOW=1", { class => "btn btn-success active" }),
      $change . $delete
    );

  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 employees_mobile_report() - shows mobile payment report

  Arguments:
     -

  Returns:
    true
=cut
#**********************************************************
sub employees_mobile_report {

  require Control::Reports;
  reports(
    {
      DATE_RANGE       => 1,
      REPORT           => 'MOBILE_REPORT',
      PERIOD_FORM      => 1,
      NO_TAGS          => 1,
      NO_GROUP         => 1,
      EXT_SELECT        => sel_admins(),
      EXT_SELECT_NAME   => $lang{EMPLOYEE},
    },
  );

  my ($y, $m, undef) = split('-', $DATE);
  my $from_date = "$y-$m-01";
  my $to_date = "$y-$m-" . days_in_month({ DATE => $DATE });

  $LIST_PARAMS{AID} = $FORM{AID} || '';
  $LIST_PARAMS{FROM_DATE} = $FORM{FROM_DATE} || $from_date;
  $LIST_PARAMS{TO_DATE} = $FORM{TO_DATE} || $to_date;

  result_former({
    INPUT_DATA      => $Employees,
    FUNCTION        => 'employees_mobile_report_list',
    DEFAULT_FIELDS  => 'ID,EMPLOYEE_NAME,PHONE,SUM,DATE,TRANSACTION_ID,STATUS',
    BASE_FIELDS     => 0,
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id             => '#',
      employee_name  => $lang{EMPLOYEE},
      phone          => $lang{PHONE},
      sum            => $lang{SUM},
      date           => $lang{DATE},
      transaction_id => $lang{TRANSACTION_ID},
      status         => $lang{STATUS},
    },
    SELECT_VALUE    => {
      status => { 0 => "$lang{REJECTED}:text-danger",
        1           => "$lang{IN_WORK}:text-info",
        2           => "$lang{DONE}:text-primary",
        3           => "$lang{NOT_FOUND}:text-warning",
      },
    },
    TABLE           => {
      width      => '100%',
      caption    => "$lang{REPORTS} $lang{MOBILE_PAY}",
      ID         => 'MOBILE_PAY',
      DATA_TABLE => { 'order' => [ [ 0, 'desc' ] ] },
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  });

  return 1;
}
#**********************************************************
=head2 employees_mobile_pay($attr) - make payment and add info to report

  Arguments:
    $attr -
      AID - Employee aid
      CELL - Employee cell phone
      SUM - Needed sum for pay to mobile

  Returns:
    True

  Example:
    $Employees->employees_mobile_pay({
      AID            => $attr->{AID},
      SUM            => $attr->{SUM},
      CELL           => $attr->{CELL},
    });

=cut
#**********************************************************
sub employees_mobile_pay {
  my ($attr) = @_;

  if (!$attr->{CELL}) {
    $html->message('err', $lang{ERROR}, "The cell phone is empty.");
    return 0;
  }
  elsif (!$attr->{SUM} || $attr->{SUM} eq '0,00') {
    $html->message('err', $lang{ERROR}, "The payment sum is '0.00'.");
    return 0;
  }

  if (!$conf{MOBILE_PAY_ID_MERCHANT} || !$conf{MOBILE_PAY_PASS_MERCHANT}) {
    $html->message('err', $lang{ERROR}, "Wrong merchant id or password.");
    return 0;
  }

  if ($attr->{ADMIN_OBJECT}) {
    $admin = $attr->{ADMIN_OBJECT};
  }

  my $admin_list = $admin->list({
    AID      => $attr->{AID} || '',
    DISABLE  => '_SHOW',
    COLS_NAME => 1
  });

  if ($admin_list->[0]{disable} != 0) {
    if ($attr->{FOR_CONSOLE}) {
      print "ADMIN AID:$attr->{AID} is fired or disabled.\n";
      return 1;
    }
    else {
      $html->message('err', $lang{ERROR}, "ADMIN AID:$attr->{AID} is fired or disabled.");
      return 1;
    }
  }


  my $payment_id = 0;
  my $text = qq{};
  my $data = qq{};
  my $responce_state = q{};
  my $signature = qq{};
  my $url = qq{https://api.privatbank.ua/p24api/directfill};
  my $cell_phone = $attr->{CELL};
  $cell_phone =~ s/ //g;
  $cell_phone =~ s/-//g;
  $cell_phone =~ s/^0/+380/g;

  $payment_id = mk_unique_value(10, { SYMBOLS => '0123456789' });
  $text = qq{<oper>cmt</oper><wait>0</wait><test>0</test>};
  $text .= qq{<payment id="$payment_id"><prop name="phone" value="%2B$cell_phone"/><prop name="amt" value="$attr->{SUM}"/></payment>};

  $signature = md5_hex($text . $conf{MOBILE_PAY_PASS_MERCHANT});
  $signature = sha1_hex($signature);

  $data = qq{<?xml version="1.0" encoding="UTF-8"?>
            <request version="1.0">
                <merchant>
                    <id>$conf{MOBILE_PAY_ID_MERCHANT}</id>
                    <signature>$signature</signature>
                </merchant>
                <data>
                  $text
                </data>
            </request>};
  $data =~ s/"/\\\"/g;
  $data =~ s/\n//g;
  require XML::Simple;
  XML::Simple->import(/qw(:strict)/);

  my $result = web_request($url, { DEBUG => $attr->{DEBUG} || 0, POST => $data });
  my $responce = XML::Simple::XMLin($result, ForceArray => 1, KeyAttr => 1);
  $responce_state = $responce->{data}[0]{payment}[0]{state};

  $Employees->employees_mobile_report_add({
    AID            => $attr->{AID},
    SUM            => $attr->{SUM},
    PHONE          => $attr->{CELL},
    DATE           => "$DATE $TIME",
    TRANSACTION_ID => $payment_id,
    STATUS         => $responce_state,
  });

  if ($Employees->{errno}) {
    $html->message('err', "$lang{ERROR}", "Error with adding report: $Employees->{errno}");
    return 0;
  }
  return 1;
}
1;
