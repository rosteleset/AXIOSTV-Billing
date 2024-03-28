#!/usr/bin/perl 

=head1 NAME

  ABillS Dillers Web interface

=head2 VERSION

  VERSION: 0.31
  REVISION: 2020.01.13

=cut

use strict;
use warnings;

BEGIN {
  my $libpath = '../';

  our $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/",
    $libpath . 'lib/',
    $libpath . 'AXbills/modules/',
    $libpath . 'libexec/',
  );

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}
our (
  @ones,
  @twos,
  @fifth,
  @one,
  @onest,
  @ten,
  @tens,
  @hundred,
  @money_unit_names,
  %conf,
  %lang,
  %LANG,
  %err_strs,
  $Cards,
  %menu_args,
  @MONTHES,
  %module
);


do "config.pl";
use AXbills::Defs;
use AXbills::Base qw(in_array mk_unique_value);
use AXbills::SQL;
use AXbills::HTML;
use Users;
use Finance;
use Dillers;
require AXbills::Templates;
require AXbills::Misc;

our $html = AXbills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
  }
);

our $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
do "../language/$html->{language}.pl";
our $sid = $FORM{sid} || '';    # Session ID

if ($COOKIES{sid} && (!$FORM{passwd})) {
  $COOKIES{sid} =~ s/\"//g;
  $COOKIES{sid} =~ s/\'//g;
  $sid = $COOKIES{sid};
}
elsif ($COOKIES{sid} && (length($COOKIES{sid}) > 1) && (defined($FORM{passwd}))) {
  $html->set_cookies('sid', "", "Fri, 1-Jan-2038 00:00:01");
  $COOKIES{sid} = undef;
}

$html->{METATAGS} = templates('metatags_client');

#Cookie section ============================================
if (defined($FORM{colors})) {
  my $cook_colors = (defined($FORM{default})) ? '' : $FORM{colors};
  $html->set_cookies('colors', "$cook_colors", "Fri, 1-Jan-2038 00:00:01");
}

#Operation system ID
$html->set_cookies('OP_SID',   $FORM{OP_SID},   "Fri, 1-Jan-2038 00:00:01", '/', { SKIP_SAVE => 1 }) if (defined($FORM{OP_SID}));

if (defined($FORM{sid})) {
  $html->set_cookies('sid', $FORM{sid}, "Fri, 1-Jan-2038 00:00:01");
}

#===========================================================

require Admins;
Admins->import();
our $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} || '127.0.0.1' });

if ($FORM{cmd}) {
  cards_terminal_service();
  exit;
}
elsif ($FORM{registration}) {
  print $html->header();
  form_registration();
  print $html->{OUTPUT};
  exit;
}

my $uid = 0;
my $pages_qs;
my %OUTPUT = ();
my $login  = $FORM{user} || '';
my $passwd = $FORM{passwd} || '';
my $diller;

my @m = (
  "10:0:$lang{USER_INFO}:form_info:::",
  "20:0:$lang{FINANCES}:form_finance:::",
  "21:20:$lang{FEES}:form_fees:::",
  "22:20:$lang{PAYMENTS}:form_payments_list:::",
  "24:0:$lang{SEARCH}:cards_diller_search:defaultindex",
);

my $users = Users->new($db, $admin, \%conf);
($uid, $sid, $login) = auth($login, $passwd, $sid);
my %uf_menus = ();

if ($uid > 0) {
  my $default_index = 10;
  push @m, "17:0:$lang{PASSWD}:form_passwd:::" if ($conf{user_chg_passwd});
  mk_menu2();

  $html->{SID} = $sid;
  (undef, $OUTPUT{MENU}) = $html->menu(
    \%menu_items,
    \%menu_args,
    undef,
    {
      EX_ARGS         => "&sid=$sid",
      ALL_PERMISSIONS => 1,
      FUNCTION_LIST   => \%functions
    }
  );

  if ($html->{ERROR}) {
    $html->message('err', $lang{ERROR}, "$html->{ERROR}");
    exit;
  }
  $OUTPUT{DATE}       = $DATE;
  $OUTPUT{TIME}       = $TIME;
  $OUTPUT{LOGIN}      = $login;
  $OUTPUT{IP}         = $ENV{'REMOTE_ADDR'};
  $OUTPUT{STATE}      = ($users->{DISABLE}) ? $html->color_mark($lang{DISABLE}, $_COLORS[6]) : $lang{ENABLE};
  $pages_qs           = "&UID=$users->{UID}&sid=$sid";
  $LIST_PARAMS{UID}   = $users->{UID};
  $LIST_PARAMS{LOGIN} = $users->{LOGIN};

  $index = $FORM{qindex} if ($FORM{qindex});
  load_module('Cards', $html);

  my $Dillers = Dillers->new($db, $admin, \%conf);
  $Dillers->diller_info({ UID => $user->{UID} });
  $diller = $Dillers->diller_info({ UID => $users->{UID} });

  if ($FORM{qindex}) {
    if (defined($module{ $FORM{qindex} })) {
      load_module($module{ $FORM{qindex} }, $html);
#      $Cards = Cards->new($db, $admin, \%conf);
#      $diller = $Cards->cards_diller_info({ UID => $users->{UID} });
    }

    if ($functions{ $FORM{qindex} }){
      my $fn = $functions{ $FORM{qindex} };
      &{ \&$fn }({ USER_INFO => $users });
    }
    print $html->{OUTPUT};
    exit;
  }

  if (defined($module{$index})) {
    load_module($module{$index}, $html);
  }

  my $fn;
  if ($index != 0 && defined($functions{$index})) {
    $fn = $functions{$index};
  }
  else {
    $fn = $functions{$default_index};
  }

  &{ \&$fn }({ USER_INFO => $users });

  $OUTPUT{BODY}   = $html->{OUTPUT};
  $html->{OUTPUT} = '';
  $OUTPUT{BODY}   = $html->tpl_show(templates('form_client_main'), \%OUTPUT);
  $OUTPUT{SKIN} = 'skin-blue';
}
else {
  form_login();
}

print $html->header();
$OUTPUT{STATE} = ($users->{SERVICE_STATUS}) ? $users->{SERVICE_STATUS} : $OUTPUT{STATE};
$OUTPUT{BODY}  = $html->{OUTPUT};
$OUTPUT{INDEX_NAME} = 'dillers.cgi';

print $html->tpl_show(templates('form_client_start'), { %OUTPUT, TITLE_TEXT => 'Diller interface' });

$html->test() if ($conf{debugmods} =~ /LOG_DEBUG/);

#==========================================================
#
#==========================================================
sub mk_menu2 {
  my $maxnumber = 0;
  foreach my $line (@m) {
    my ($ID, $PARENT, $NAME, $FUNTION_NAME) = split(/:/, $line);
    $menu_items{$ID}{$PARENT} = $NAME;
    $menu_names{$ID} = $NAME;
    $functions{$ID} = $FUNTION_NAME if ($FUNTION_NAME ne '');
    $maxnumber = $ID if ($maxnumber < $ID);
  }

  #my $m              = 'Cards';
  my @DILLER_MODULES = ('Cards');
  push @DILLER_MODULES, 'Paysys' if (in_array('Paysys', \@MODULES));

  %USER_FUNCTION_LIST = (
      "01:0:$lang{ICARDS}:cards_diller_face:"                    => 0,
      "02:1:$lang{LOG}:cards_diller_stats:"                      => 1,
      "03:1:$lang{LIST_OF_LOGS}:cards_diller_operations_log:"    => 2,
      "04:0:$lang{SEARCH}:cards_diller_search:defaultindex"      => 3,
  );

  foreach my $m (@DILLER_MODULES) {

#    if ($m eq 'Cards') {
#    }
#    elsif (my $return = do "AXbills/modules/$m/config") {
#
#    }

    load_module($m, $html);
    my %module_fl = ();

    #next if (keys %USER_FUNCTION_LIST < 1);
    my @sordet_module_menu = sort keys %USER_FUNCTION_LIST;

    foreach my $line (@sordet_module_menu) {
      $maxnumber++;
      my ($ID, $SUB, $NAME, $FUNTION_NAME, $ARGS) = split(/:/, $line, 5);
      $ID = int($ID);
      my $v = $USER_FUNCTION_LIST{$line};

      $module_fl{"$ID"} = $maxnumber;

      if ($index < 1 && $ARGS eq 'defaultindex') {
        my $default_index = $maxnumber;
        $index         = $default_index;
      }
      elsif ($ARGS ne '' && $ARGS ne 'defaultindex') {
        $menu_args{$maxnumber} = $ARGS;
      }

      if ($SUB > 0) {
        $menu_items{$maxnumber}{ $module_fl{$SUB} } = $NAME;
      }
      else {
        $menu_items{$maxnumber}{$v} = $NAME;
        if ($SUB == -1) {
          $uf_menus{$maxnumber} = $NAME;
        }
      }

      $menu_names{$maxnumber} = $NAME;
      $functions{$maxnumber}  = $FUNTION_NAME if ($FUNTION_NAME ne '');
      $module{$maxnumber}     = $m;
    }

    %USER_FUNCTION_LIST = ();
  }

  $menu_names{1000}    = $lang{LOGOUT};
  $functions{1000}     = 'logout';
  $menu_items{1000}{0} = $lang{LOGOUT};
}

#**********************************************************
# form_stats
#**********************************************************
sub form_info {

  if ($conf{user_chg_pi}) {
    if ($FORM{chg}) {
      $users->pi();
      $users->{ACTION}     = 'change';
      $users->{LNG_ACTION} = $lang{CHANGE};
      $html->tpl_show(templates('form_chg_client_info'), $users);
      return 0;
    }
    elsif ($FORM{change}) {
      $users->pi_change({ %FORM, UID => $users->{UID} });
      if (!$users->{errno}) {
        $html->message('info', $lang{CHANGED}, $lang{CHANGED});
      }
    }
  }

  $users->pi();

  my $payments = Finance->payments($db, $admin, \%conf);
  $LIST_PARAMS{PAGE_ROWS} = 1;
  $LIST_PARAMS{DESC}      = 'desc';
  $LIST_PARAMS{SORT}      = 1;
  my $list = $payments->list({%LIST_PARAMS});

  $users->{PAYMENT_DATE} = $list->[0]->[2];
  $users->{PAYMENT_SUM}  = $list->[0]->[3];
  if ($conf{EXT_BILL_ACCOUNT} && $users->{EXT_BILL_ID} > 0) {
    $users->{EXT_DATA} = $html->tpl_show(templates('form_ext_bill'), $users, { OUTPUT2RETURN => 1 });
  }
  $html->tpl_show(templates('form_client_info'), $users);

  if ($conf{user_chg_pi}) {
    $html->form_main(
      {
        CONTENT => $html->form_input('chg', $lang{CHANGE}, { TYPE => 'SUBMIT', OUTPUT2RETURN => 1 }),
        HIDDEN  => {
          sid   => $sid,
          index => $index
        }
      }
    );
  }

  return 1;
}

#**********************************************************
# Search form
#**********************************************************
sub form_search {
  my ($attr) = @_;

  my %SEARCH_DATA = $admin->get_data(\%FORM);

  if (defined($attr->{HIDDEN_FIELDS})) {
    my $SEARCH_FIELDS = $attr->{HIDDEN_FIELDS};
    while (my ($k, $v) = each(%$SEARCH_FIELDS)) {
      $SEARCH_DATA{HIDDEN_FIELDS} .= $html->form_input(
        "$k", "$v",
        {
          TYPE          => 'hidden',
          OUTPUT2RETURN => 1
        }
      );
    }
  }

  $SEARCH_DATA{HIDDEN_FIELDS} .= $html->form_input("GID", "$FORM{GID}", { TYPE => 'hidden', OUTPUT2RETURN => 1 }) if ($FORM{GID});

  if (defined($attr->{SIMPLE})) {
    my $SEARCH_FIELDS = $attr->{SIMPLE};
    while (my ($k, $v) = each(%$SEARCH_FIELDS)) {
      $SEARCH_DATA{SEARCH_FORM} .= "<tr><td>$k:</td><td>";
      $SEARCH_DATA{SEARCH_FORM} .= $html->form_input("$v", '%' . $v . '%');
      $SEARCH_DATA{SEARCH_FORM} .= "</td></tr>\n";
    }

    $html->tpl_show(templates('form_search_simple'), \%SEARCH_DATA, { notprint => 1 });
  }
  elsif ($attr->{TPL}) {

    #defined();
  }
  else {

    if (defined($attr->{SEARCH_FORM})) {
      $SEARCH_DATA{SEARCH_FORM} = $attr->{SEARCH_FORM};
    }

    $SEARCH_DATA{FROM_DATE} = $html->date_fld2('FROM_', { MONTHES => \@MONTHES });
    $SEARCH_DATA{TO_DATE}   = $html->date_fld2('TO_',   { MONTHES => \@MONTHES });

    $html->tpl_show(templates('form_search'), \%SEARCH_DATA, { notprint => 1 });

  }

  if ($FORM{search}) {
    $LIST_PARAMS{LOGIN_EXPR} = $FORM{LOGIN_EXPR};
    $pages_qs = "&search=y";
    $pages_qs .= "&type=$FORM{type}" if ($pages_qs !~ /&type=/);

    if (defined($FORM{FROM_D}) && defined($FORM{TO_D})) {
      $FORM{FROM_DATE} = "$FORM{FROM_Y}-" . sprintf("%.2d", ($FORM{FROM_M} + 1)) . "-$FORM{FROM_D}";
      $FORM{TO_DATE}   = "$FORM{TO_Y}-" . sprintf("%.2d",   ($FORM{TO_M} + 1)) . "-$FORM{TO_D}";
    }

    while (my ($k, $v) = each %FORM) {
      if ($k =~ /([A-Z0-9]+|_[a-z0-9]+)/ && $v ne '' && $k ne '__BUFFER') {

        #print "$k, $v<br>";
        $LIST_PARAMS{$k} = $v;
        $pages_qs .= "&$k=$v";
      }
    }

    if ($FORM{type} ne $index) {
      #print "$index = $FORM{type}";
      #$functions{$FORM{type}}->();
    }
  }

}

#**********************************************************
# form_login
#**********************************************************
sub form_login {
  my %first_page = ();

  #Make active lang list
  if ($conf{LANGS}) {
    $conf{LANGS} =~ s/\n//g;
    my (@lang_arr) = split(/;/, $conf{LANGS});
    %LANG = ();
    foreach my $l (@lang_arr) {
      my ($lang, $lang_name) = split(/:/, $l);
      $lang =~ s/^\s+//;
      $LANG{$lang} = $lang_name;
    }
  }

  $first_page{SEL_LANGUAGE} = $html->form_select(
    'language',
    {
      EX_PARAMS => 'onChange="selectLanguage()"',
      SELECTED  => $html->{language},
      SEL_HASH  => \%LANG,
      NO_ID     => 1
    }
  );

  $OUTPUT{BODY} = $html->tpl_show(templates('form_client_login'), \%first_page);
}

#**********************************************************
# FTP authentification
# auth($login, $pass)
#**********************************************************
sub auth {
  my ($login_, $password, $sid_) = @_;

  my $ret                  = 0;
  my $res                  = 0;
  my $REMOTE_ADDR          = $ENV{'REMOTE_ADDR'} || '';
  #my $HTTP_X_FORWARDED_FOR = $ENV{'HTTP_X_FORWARDED_FOR'} || '';
  #my $ip                   = "$REMOTE_ADDR/$HTTP_X_FORWARDED_FOR";
  my $action;

  if ($index == 1000) {
    $users->web_session_del({ SID => $FORM{sid} });
    return 0;
  }
  elsif (length($sid_) > 1) {

    $users->web_session_info({ SID => $sid_ });

    if ($users->{TOTAL} < 1) {
      $html->message('err', "$lang{ERROR}", $lang{NOT_LOGINED});
      return 0;
    }
    elsif ($users->{errno}) {
      $html->message('err', "$lang{ERROR}", "$lang{ERROR}");
      return 0;
    }
    elsif ($conf{web_session_timeout} && $conf{web_session_timeout} < $users->{SESSION_TIME}) {
      $html->message('info', $lang{INFO}, 'Session Expire');
      $users->web_session_del({ SID => $sid_ });
      return 0;
    }
    elsif ($users->{REMOTE_ADDR} ne $REMOTE_ADDR) {
      $html->message('err', "$lang{ERROR}", 'WRONG IP');
      return 0;
    }

    $users->info($users->{UID});
    return ($users->{UID}, $sid_, $users->{LOGIN});
  }
  else {
    return 0 if (!$login_ || !$password);

    if ($conf{wi_bruteforce}) {
      $users->bruteforce_list(
        {
          LOGIN    => $login_,
          PASSWORD => $password,
          CHECK    => 1
        }
      );

      if ($users->{TOTAL} > $conf{wi_bruteforce}) {
        $OUTPUT{BODY} = $html->tpl_show(templates('form_bruteforce_message'), undef);
        return 0;
      }
    }

    $res = auth_sql("$login_", "$password") if ($res < 1);

  }

  #Get user ip
  if (defined($res) && $res > 0) {
    $users->info(0, { LOGIN => "$login_" });

    if ($users->{TOTAL} > 0) {
      $sid_                 = mk_unique_value(16);
      $ret                 = $users->{UID};
      $users->{REMOTE_ADDR} = $REMOTE_ADDR;
      $users->web_session_add(
        {
          UID         => $users->{UID},
          SID         => $sid_,
          LOGIN       => $login_,
          REMOTE_ADDR => $REMOTE_ADDR,
          EXT_INFO    => $ENV{HTTP_USER_AGENT}
        }
      );

      $action = 'Access';
    }
    else {
      $html->message('err', "$lang{ERROR}", $lang{ERR_WRONG_PASSWD});
      $action = 'Error';
    }
  }
  else {
    $users->bruteforce_add(
      {
        LOGIN       => $login_,
        PASSWORD    => $password,
        REMOTE_ADDR => $REMOTE_ADDR,
        AUTH_STATE  => $ret
      }
    );

    $html->message('err', "$lang{ERROR}", $lang{ERR_WRONG_PASSWD});
    $ret    = 0;
    $action = 'Error';
  }

  return ($ret, $sid_, $login_);
}

#**********************************************************
# Authentification from SQL DB
# auth_sql($login, $password)
#**********************************************************
sub auth_sql {
  my ($login_, $password) = @_;
  my $ret = 0;

  $users->info(
    0,
    {
      LOGIN    => "$login_",
      PASSWORD => "$password"
    }
  );

  if ($users->{TOTAL} < 1) {
    #$html->message('err', $lang{ERROR}, $lang{NOT_FOUND});
  }
  elsif ($users->{errno}) {
    $html->message('err', $lang{ERROR}, "$users->{errno} $users->{errstr}");
  }
  else {
    $ret = $users->{UID};
  }

  return $ret;
}

#**********************************************************
# form_passwd($attr)
#**********************************************************
sub form_passwd {
  #my ($attr) = @_;
#  my $hidden_inputs;

  my %INFO = ();
  if (! $FORM{newpassword}) {

  }
  elsif (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
    $html->message('err', $lang{ERROR}, $err_strs{6});
  }
  elsif ($FORM{newpassword} eq $FORM{confirm}) {
    %INFO = (
      PASSWORD => $FORM{newpassword},
      UID      => $users->{UID},
      DISABLE  => $users->{DISABLE}
    );

    $users->change($users->{UID}, \%INFO);

    if (!$users->{errno}) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
    }
    else {
      $html->message('err', $lang{ERROR}, "[$users->{errno}] $err_strs{$users->{errno}}");
    }
    return 0;
  }
  elsif ($FORM{newpassword} ne $FORM{confirm}) {
    $html->message('err', $lang{ERROR}, $err_strs{5});
  }

  my $password_form;
  $password_form->{ACTION}       = 'change';
  $password_form->{LNG_ACTION}   = $lang{CHANGE};
  $password_form->{GEN_PASSWORD} = mk_unique_value(8);
  $html->tpl_show(templates('form_password'), $password_form);

  return 0;
}

#**********************************************************
=head2 form_fees

=cut
#**********************************************************
sub form_fees {
  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $FEES_METHODS = get_fees_types();

  my $Fees  = Finance->fees($db, $admin, \%conf);
  my $list  = $Fees->list({%LIST_PARAMS, 
    DSC       => '_SHOW',
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    DEPOSIT   => '_SHOW',
    METHOD    => '_SHOW',
    LAST_DEPOSIT => '_SHOW',
    UID       => '_SHOW',
    COLS_NAME => 1
  });

  my $Payment = Finance->payments($db, $admin, \%conf);
  my $list_user = $Payment->list({
    BILL_ID   => '_SHOW',
    EXT_ID    => '50',
    UID       => '_SHOW',
    SUM       => '_SHOW',
    COLS_NAME => 1
  });

  my $users_list = $users->list({
    UID       => '_SHOW',
    COLS_NAME => 1
  });

  my $table = $html->table(
    {
      width       => '100%',
      caption     => $lang{FEES},
      border      => 1,
      title       => [ $lang{DATE}, $lang{DESCRIBE}, 'UID', $lang{SUM}, $lang{DEPOSIT}, $lang{TYPE} ],
        qs          => $pages_qs,
      pages       => $Fees->{TOTAL},
      ID          => 'FEES'
    }
  );

  foreach my $line (@$list) {
    my $user_pay = '';
    foreach my $list_user_pay (@$list_user) {
      if ($line->{uid} == $users->{UID} && sprintf('%.2f', $line->{sum}) eq sprintf('%.2f', $list_user_pay->{sum})) {
        $user_pay = $list_user_pay->{uid};
      }
    }
    foreach my $element (@$users_list) {
      if ($user_pay eq $element->{uid}) {
        $user_pay = $element->{uid};
      }
    }

    my $sum_out = _format_sum($line->{sum});
    my $last_dep = _format_sum($line->{last_deposit});

    $table->addrow($line->{datetime},
      $line->{dsc},
      $user_pay,
      $sum_out,
      $last_dep,
      $FEES_METHODS->{ 4 });
  }

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       => [ [ "$lang{TOTAL}:", $html->b($Fees->{TOTAL}), "$lang{SUM}:", $html->b(sprintf('%.2f', $Fees->{SUM})) ] ],
    }
  );
  print $table->show();
}

#**********************************************************
=head2 form_registration()

=cut
#**********************************************************
sub form_registration {
  $Cards->{ACTION}     = 'registration';
  $Cards->{LNG_ACTION} = $lang{REGISTRATION};

  if ($FORM{registration}) {
    $html->message('info', $lang{INFO}, "$lang{REGISTRATION} $lang{DONE}");
  }

  $html->tpl_show(_include('cards_diller_registration', 'Cards'), $Cards);
}


#**********************************************************
=head2 form_payments_list()

=cut
#**********************************************************
sub form_payments_list {
  my @PAYMENT_METHODS = ("$lang{CASH}", "$lang{BANK}", "$lang{EXTERNAL_PAYMENTS}", 'Credit Card', "$lang{BONUS}",
    "$lang{CORRECTION}", "$lang{COMPENSATION}", "$lang{MONEY_TRANSFER}");
  push @PAYMENT_METHODS, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);

  my $Payments = Finance->payments($db, $admin, \%conf);

  if (!$FORM{sort}) {
    $LIST_PARAMS{sort} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $list  = $Payments->list({ %LIST_PARAMS,
      DSC           => '_SHOW',
      DATETIME      => '_SHOW',
      SUM           => '_SHOW',
      AFTER_DEPOSIT => '_SHOW',
      METHOD        => '_SHOW',
      PAGE_ROWS     => 10,
      COLS_NAME     => 1
  });

  my $PAYMENT_METHODS = get_payment_methods();

  my $table = $html->table(
    {
      width       => '100%',
      caption     => "$lang{PAYMENTS}",
      title_plain => [ $lang{DATE}, $lang{DESCRIBE}, $lang{SUM}, $lang{DEPOSIT}, $lang{TYPE} ],
      qs          => $pages_qs,
      pages       => $Payments->{TOTAL},
      ID          => 'PAYMENTS'
    }
  );

  foreach my $line (@$list) {
    my $sum_out = _format_sum($line->{sum});
    my $last_dep = _format_sum($line->{last_deposit});

    $table->addrow(
      $line->{datetime},
      $line->{dsc},
      $sum_out || 0.00,
      $last_dep || 0.00,
      ( defined $line->{method} && defined $PAYMENT_METHODS->{ $line->{method} } ) ? $PAYMENT_METHODS->{ $line->{method} } : q{}
    );
  }

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       => [ [ "$lang{TOTAL}:", $html->b( $Payments->{TOTAL} ), "$lang{SUM}:", $html->b( sprintf('%.2f', $Payments->{SUM} )) ] ],
      rowcolor   => $_COLORS[2]
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
#
# ���:
#/test.php?cmd=ping
#�������:
#<?php
#echo pong;
#?>
#
#���������� �������:
#/test.php?cmd=pay&term=1234567&pswd=password&date=29.09.2010&time=10:55&sum=15
#��:
#term - �� �������� (�������� ��� ������������)
#pswd - ������ (�������� ��� ������������)
#data - ����
#time - ���
#sum - ���� ����������
#
#�������
#<?php
#echo "err=no&";
#echo "series=14351431&";
#echo "pin=76543";
#?>
#
#��:
#err - ������� ��� ��������� (no - ���� �������)
#series -  ����.
#pin - ��.
# $conf{CARDS_TERMINAL_IP}='192.168.1.41';
#
# $conf{CARDS_TERMINAL_IDS}='1';
#
# $conf{CARDS_TERMINAL_PASSWD}='pass';
#
# $conf{CARDS_TERMINAL_UID}='pass';
#**********************************************************
sub cards_terminal_service {
  print "Content-Type: text/plain\n\n";

  my $return;
  if ($conf{CARDS_TERMINAL_IP} !~ /$ENV{REMOTE_ADDR}/) {
    $return = "Wrong IP";
  }
  elsif ($FORM{cmd} eq 'ping') {
    $return = "pong";
  }
  elsif ($FORM{cmd} eq 'pay') {
    my $error  = 'no';
    my $serial = '';
    my $pin    = '';
    my $other  = '';
    $conf{CARDS_TERMINAL_IDS} =~ s/ //g;
    my @terminal_ids_arr = split(/,/, $conf{CARDS_TERMINAL_IDS});

    if (!in_array($FORM{term}, \@terminal_ids_arr)) {
      $error = 'WRONG_TERMINAL_ID';
    }
    else {
    	my %term_info = ();
    	my @info_arr = split(/;/, $conf{CARDS_TERMINAL_IDS});
    	my ($terminal_id, $password);
    	foreach my $info (@info_arr) {
    		($terminal_id, $uid, $password) = split(/:/, $info, 3);
    		$term_info{$terminal_id}="$uid:$password";
    		if ($terminal_id == $FORM{term}) {
    			last;
    		}
    	}

      if ($FORM{pswd} ne $password) {
        $error = 'WRONG_PASSWORD';
      }
      else {
        $FORM{OP_SID} = rand();
        $FORM{EXPORT} = 'cards_server';
        $FORM{add}    = 1;
        $FORM{SUM}    = $FORM{sum};
        $users = Users->new($db, $admin, \%conf);
        load_module('Cards', $html);
        my $Dillers = Cards->new($db, $admin, \%conf);
        $users->info(int($uid));
        $diller = $Dillers->diller_info({ UID => int($conf{CARDS_TERMINAL_UID}) });

        if ($Cards->{TOTAL} < 1) {
          $error = 'DILLER_NOT_EXIST';
        }
        elsif (($users->{DEPOSIT} + $users->{CREDIT} > 0 && $Cards->{PAYMENT_TYPE} == 0) || $Cards->{PAYMENT_TYPE} > 0) {
          $return = cards_diller_add();
          if (!$return->{ERROR}) {
            $serial = $return->{NUMBER};
            $pin    = $return->{PIN};
            if ($return->{LOGIN} ne '-') {
              $other = "&login=$return->{LOGIN}";
            }
          }
          else {
            $error = $return->{ERROR};
          }
        }
        else {
         $error = 'SMALL_DEPOSIT';
        }

        $return = "err=$error&" . "series=$serial&" . "pin=$pin$other";
      }
    }
  }
  print "$return";
}

#**********************************************************
=head2 form_finance

=cut
#**********************************************************
sub form_finance {

  my @PAYMENT_METHODS = ("$lang{CASH}", "$lang{BANK}", "$lang{EXTERNAL_PAYMENTS}", 'Credit Card', "$lang{BONUS}",
    "$lang{CORRECTION}", "$lang{COMPENSATION}", "$lang{MONEY_TRANSFER}");
  push @PAYMENT_METHODS, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);

  my $Payments = Finance->payments($db, $admin, \%conf);

  if (!$FORM{sort}) {
    $LIST_PARAMS{sort} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $list = $Payments->list({ %LIST_PARAMS,
      DSC           => '_SHOW',
      DATETIME      => '_SHOW',
      SUM           => '_SHOW',
      AFTER_DEPOSIT => '_SHOW',
      METHOD        => '_SHOW',
      PAGE_ROWS     => 10,
      COLS_NAME     => 1
    });

  my $table = $html->table(
    {
      width       => '100%',
      caption     => "$lang{PAYMENTS}",
      title_plain => [ $lang{DATE}, $lang{DESCRIBE}, $lang{SUM}, $lang{DEPOSIT}, $lang{TYPE} ],
      qs          => $pages_qs,
      ID          => 'PAYMENTS'
    }
  );

  my $users_list = $users->list({
    UID       => '_SHOW',
    COLS_NAME => 1
  });


  my $PAYMENTS_METHODS = get_payment_methods();

  foreach my $line (@$list) {
    my $output_sum = _format_sum($line->{sum});
    my $output_pay = _format_sum($line->{after_deposit});

    $table->addrow(
      $line->{datetime},
      $line->{dsc},
      $output_sum,
      $output_pay,
      ( defined $line->{method} && defined $PAYMENTS_METHODS->{ $line->{method} } ) ? $PAYMENTS_METHODS->{ $line->{method} } : q{}
    );
  }

  print $table->show();

  my $FEES_METHODS = get_fees_types();

  my $Fees  = Finance->fees($db, $admin, \%conf);
  $list = $Fees->list({
      %LIST_PARAMS,
      DSC          => '_SHOW',
      DATETIME     => '_SHOW',
      SUM          => '_SHOW',
      DEPOSIT      => '_SHOW',
      METHOD       => '_SHOW',
      LAST_DEPOSIT => '_SHOW',
      PAGE_ROWS    => 10,
      COLS_NAME    => 1
  });

  $table = $html->table(
    {
      width       => '100%',
      caption     => $lang{FEES},
      title_plain => [ $lang{DATE}, $lang{DESCRIBE}, 'UID', $lang{SUM}, $lang{DEPOSIT}, $lang{TYPE} ],
      qs          => $pages_qs,
      ID          => 'FEES'
    }
  );

  my $list_user = $Payments->list({
    BILL_ID   => '_SHOW',
    EXT_ID    => '50',
    UID       => '_SHOW',
    SUM       => '_SHOW',
    COLS_NAME => 1
  });

  foreach my $line (@$list) {
    my $user_pay = '';
    foreach my $list_user_pay (@$list_user) {
      if ($line->{uid} == $users->{UID} && sprintf('%.2f', $line->{sum}) eq sprintf('%.2f', $list_user_pay->{sum})) {
        $user_pay = $list_user_pay->{uid};
      }
    }
    foreach my $element (@$users_list) {
      if ($user_pay eq $element->{uid}) {
        $user_pay = $element->{uid};
      }
    }

    my $output_sum = _format_sum($line->{sum});
    my $output_depost = _format_sum($line->{last_deposit});

    $table->addrow($line->{datetime},
      $line->{dsc},
      $user_pay,
      $output_sum,
      $output_depost,
      $FEES_METHODS->{ 4 }
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 format_sum($attr) - format sum number space

  Argument:


=cut
#**********************************************************
sub _format_sum {
  my ($attr) = @_;

  my $number_with_d = sprintf('%.2f', $attr);
  my ($main_part, $second_part) = split('\.', $number_with_d);

  my $last_deposit = substr($main_part, 0, length($main_part)%3);
  my $last_deposit_sectond = substr($main_part, length($main_part)%3);
  my @arrnum = $last_deposit_sectond =~ /.{1,3}/g;
  my $output_depost .= length($last_deposit) ? $last_deposit . " " : "";

  $output_depost .= join(' ', @arrnum);
  $output_depost .= '.' . $second_part;

  return $output_depost || '';
}


1


