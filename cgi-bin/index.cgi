#!/usr/bin/perl

=head1 NAME

  ABillS User Web interface
  billing.axiostv.ru

=cut

use strict;
use warnings;

BEGIN {
  our $libpath = '../';
  eval { do "$libpath/libexec/config.pl" };
  our %conf;

  if (!%conf) {
    print "Content-Type: text/plain\n\n";
    print "Error: Can't load config file 'config.pl'\n";
    print "Create ABillS config file /usr/axbills/libexec/config.pl\n";
    exit;
  }

  my $sql_type = $conf{dbtype} || 'mysql';
  unshift(@INC,
    $libpath . "AXbills/modules/",
    $libpath . "AXbills/$sql_type/",
    $libpath . '/lib/',
    $libpath . 'AXbills/',
    $libpath
  );

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use AXbills::Defs;
use AXbills::Base qw(gen_time in_array mk_unique_value load_pmodule sendmail cmd decode_base64
  encode_base64 json_former date_inc);
use Users;
use Finance;
use Admins;
use Conf;

our (%LANG,
  %lang,
  @MONTHES,
  @WEEKDAYS,
  $base_dir,
  @REGISTRATION
);

$conf{web_session_timeout} = ($conf{web_session_timeout}) ? $conf{web_session_timeout} : '86400';

our $html = AXbills::HTML->new({
  IMG_PATH  => 'img/',
  NO_PRINT  => 1,
  CONF      => \%conf,
  CHARSET   => $conf{default_charset},
  HTML_STYLE=> $conf{UP_HTML_STYLE},
  LANG      => \%lang,
});

our $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET   => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug   => $conf{dbdebug},
    db_engine => 'dbcore'
  });

if ($html->{language} ne 'english') {
  do $libpath . "/language/english.pl";
}

if (-f $libpath . "/language/$html->{language}.pl") {
  do $libpath . "/language/$html->{language}.pl";
}

our $sid = $FORM{sid} || $COOKIES{sid} || ''; # Session ID
$html->{CHARSET} = $CHARSET if ($CHARSET);

our $admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : 3,
  { DOMAIN_ID => $FORM{DOMAIN_ID},
    IP        => $ENV{REMOTE_ADDR},
    SHORT     => 1
  });

# Load DB %conf;
our $Conf = Conf->new($db, $admin, \%conf);

$admin->{SESSION_IP} = $ENV{REMOTE_ADDR};
$conf{WEB_TITLE} = $admin->{DOMAIN_NAME} if ($admin->{DOMAIN_NAME});
$conf{TPL_DIR} //= $base_dir . '/AXbills/templates/';

do 'AXbills/Misc.pm';
require AXbills::Templates;
require AXbills::Result_former;

if (!in_array('Events', \@MODULES)) {
  $conf{USER_PORTAL_EVENTS_DISABLED} = 1;
};
$html->{METATAGS} = templates('metatags_client');

my $uid = 0;
our %OUTPUT = ();
my $login = $FORM{user} || '';
my $passwd = $FORM{passwd} || '';
my $default_index;
our %module = ();
my %menu_args = ();

delete($conf{PASSWORDLESS_ACCESS}) if ($FORM{xml});

our Users $user = Users->new($db, $admin, \%conf);

_start();

#**********************************************************
=head2 _start()

=cut
#**********************************************************
sub _start {

  if ($FORM{SHOW_MESSAGE}) {
    ($uid, $sid, $login) = auth($login, $passwd, $sid, { PASSWORDLESS_ACCESS => 1 });

    $admin->{sid} = $sid;

    if ($uid) {
      load_module('Msgs', $html);
      msgs_show_last({ UID => $uid });

      print $html->header();
      $OUTPUT{BODY} = $html->{OUTPUT};
      $OUTPUT{INDEX_NAME} = 'index.cgi';
      print $html->tpl_show(templates('form_client_start'), \%OUTPUT, {
        MAIN => 1,
        ID   => 'form_client_start' });

      return 1;
    }
    else {
      $html->message('err', $lang{ERROR}, "IP_NOT_FOUND");
    }
  }

  require Control::Auth;
  ($uid, $sid, $login) = auth_user($login, $passwd, $sid);

  # if after auth user $uid not exist - show message about wrong password
  if (!$uid && exists $FORM{logined}) {
    $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD}, { OUTPUT2RETURN => 1 });
  }

  # if uid defined set GLOBAL $ENV{DOMAIN_ID} and enabled Multidoms
  if ($uid && in_array('Multidoms', \@MODULES) && $conf{MULTIDOMS_DOMAIN_ID}) {
    my $user_info = $user->info($uid);
    $ENV{DOMAIN_ID} = $user_info->{DOMAIN_ID} if ($user_info);

    # Load DB %conf;
    $Conf = Conf->new($db, $admin, \%conf);
  }

  #Cookie section ============================================
  $html->set_cookies('OP_SID', $FORM{OP_SID}, '', $html->{web_path}, { SKIP_SAVE => 1 }) if ($FORM{OP_SID});
  if ($sid) {
    $html->set_cookies('sid', $sid, '', $html->{web_path});
    $FORM{sid} = $sid;
    $COOKIES{sid} = $sid;
    $html->{SID} = $sid;
  }
  #===========================================================
  elsif ($FORM{AJAX} || $FORM{json}) {
    print qq{Content-Type:application/json\n\n{"TYPE":"error","errstr":"Access Deny"}};
    return 0;
  }
  elsif ($FORM{xml}) {
    print qq{Content-Type:application/xml\n\n<?xml version="1.0" encoding="UTF-8"?>
        <error><TYPE>error</TYPE><errstr>Access Deny</errstr></error>};
    return 0;
  }

  # Obvious PORTAL login page handling, but it works
  if (
    ($conf{PORTAL_START_PAGE}
      && !$conf{tech_works}
      && !$uid
      && !$FORM{login_page}
      && $ENV{REQUEST_METHOD} eq "GET")
      || $FORM{article}
      || $FORM{menu_category}
  ) {
    print $html->header();
    load_module('Portal', $html);
    my $wrong_auth = 0;

    # wrong passwd
    if ($FORM{user} && $FORM{passwd}) {
      $wrong_auth = 1;
    }
    # wrong social acc
    if ($FORM{code} && !$login) {
      $wrong_auth = 2;
    }
    portal_s_page($wrong_auth);

    $html->fetch({ DEBUG => $ENV{DEBUG} });
    return 1;
  }

  quick_functions();

  if ($conf{USER_FN_LOG}) {
    require Log;
    Log->import();
    my $user_fn_log = $conf{USER_FN_LOG} || '/tmp/fn_speed';
    my $Log = Log->new($db, \%conf, { LOG_FILE => $user_fn_log });
    if (defined($functions{$index})) {
      my $time = gen_time($begin_time, { TIME_ONLY => 1 });
      $Log->log_print('LOG_INFO', '', "$sid : $functions{$index} : $time", { LOG_LEVEL => 6 });
    }
    $html->test() if ($conf{debugmods} && $conf{debugmods} =~ /LOG_DEBUG/);
  }

  return 1;
}

#**********************************************************
=head2 logout()

=cut
#**********************************************************
sub logout {

  return 1;
}

#**********************************************************
=head2 quick_functions()

=cut
#**********************************************************
sub quick_functions {

  if ($uid > 0) {
    $default_index = 10;
    #  #Quick Amon Alive Update
    if ($FORM{REFERER} && $FORM{REFERER} =~ /$SELF_URL/ && $FORM{REFERER} !~ /index=1000/) {
      print "Location: $FORM{REFERER}\n\n";
      return 1;
    }

    my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{HOLD_UP},
      "$lang{DISABLE}: $lang{NON_PAYMENT}", $lang{ERR_SMALL_DEPOSIT},
      $lang{VIRUS_ALERT});

    accept_rules() if ($conf{ACCEPT_RULES});

    fl();

    $menu_names{1000} = $lang{LOGOUT};
    $functions{1000} = 'logout';
    $menu_items{1000}{0} = $lang{LOGOUT};

    if (exists $conf{MONEY_UNIT_NAMES} && defined $conf{MONEY_UNIT_NAMES} && ref $conf{MONEY_UNIT_NAMES} eq 'ARRAY') {
      $user->{MONEY_UNIT_NAME} = $conf{MONEY_UNIT_NAMES}->[0] || '';
    }

    if ($FORM{get_index}) {
      $index = get_function_index($FORM{get_index});
      $FORM{index} = $index;
    }

    if (!$FORM{pdf} && -f '../AXbills/templates/_form_client_custom_menu.tpl') {
      $OUTPUT{MENU} = $html->tpl_show(templates('form_client_custom_menu'), $user, {
        OUTPUT2RETURN => 1,
        ID            => 'form_client_custom_menu'
      });
    }
    else {
      $OUTPUT{MENU} = $html->menu2(
        \%menu_items,
        \%menu_args, #XXX always empty
        undef,
        {
          EX_ARGS         => "&sid=$sid",
          ALL_PERMISSIONS => 1,
          FUNCTION_LIST   => \%functions,
          SKIP_HREF       => 1
        }
      );
    }

    if ($html->{ERROR}) {
      $html->message('err', $lang{ERROR}, $html->{ERROR});
      return 0;
    }

    $OUTPUT{DATE} = $DATE;
    $OUTPUT{TIME} = $TIME;
    $OUTPUT{LOGIN} = $login;
    $OUTPUT{IP} = $ENV{REMOTE_ADDR};
    $pages_qs = "&UID=$user->{UID}&sid=$sid";
    $OUTPUT{STATE} = ($user->{DISABLE}) ? $html->color_mark($lang{DISABLE}, $_COLORS[6]) : $lang{ENABLE};
    $OUTPUT{STATE_CODE} = $user->{DISABLE};
    $OUTPUT{SID} = $sid || '';

    if ($COOKIES{lastindex}) {
      $index = int($COOKIES{lastindex});
      $html->set_cookies('lastindex', '', "Fri, 1-Jan-2038 00:00:01", $html->{web_path});
    }

    $LIST_PARAMS{UID} = $user->{UID};
    $LIST_PARAMS{LOGIN} = $user->{LOGIN};

    $index = int($FORM{qindex}) if ($FORM{qindex} && $FORM{qindex} =~ /^\d+$/);
    print $html->header(\%FORM) if ($FORM{header});

    if ($FORM{qindex}) {
      if ($FORM{qindex} eq '100002') {
        form_events();
        return 0;
      }
      elsif ($FORM{qindex} eq '30') {
        require Control::Address_mng;
        our $users = $user;
        form_address_sel();
      }
      else {
        if (defined($module{ $FORM{qindex} })) {
          load_module($module{ $FORM{qindex} }, $html);
        }

        _function($FORM{qindex});
      }

      print($html->{OUTPUT} || q{});
      return 0;
    }

    if (defined($functions{$index})) {
      if ($default_index && $functions{$default_index} eq 'msgs_admin') {
        $index = $default_index;
      }
    }
    else {
      $index = $default_index;
    }

    if (defined($module{$index})) {
      load_module($module{$index}, $html);
    }

    print "Quick// $index //" if ($ENV{DEBUG});
    _function($index || 10);
    print "Quick" if ($ENV{DEBUG});

    $OUTPUT{BODY} = $html->{OUTPUT};
    $html->{OUTPUT} = '';

    $OUTPUT{STATE} = (!$user->{DISABLE} && $user->{SERVICE_STATUS}) ? $service_status[$user->{SERVICE_STATUS}] : $OUTPUT{STATE};

    $OUTPUT{SELECT_LANGUAGE} = language_select('language');
    $OUTPUT{SELECT_LANGUAGE_MOBILE} = language_select('language_mobile');

    $OUTPUT{PUSH_SCRIPT} = (($conf{PUSH_ENABLED} && $conf{PUSH_USER_PORTAL})
      ? "<script src='https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js'></script>"
      . "<script src='https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js'></script>"
      . "<script>window['FIREBASE_CONFIG']='" . (json_former($conf{FIREBASE_CONFIG}) // '') . "'</script>"
      . "<script>window['FIREBASE_VAPID_KEY']='" . ($conf{FIREBASE_VAPID_KEY} // '') . "'</script>"
      : '<!-- PUSH DISABLED -->'
    );

    my $global_chat = '';
    my $fn_index = 0;
    if ($conf{MSGS_CHAT}) {
      $fn_index = get_function_index('show_user_chat');
      $global_chat .= $html->tpl_show(templates('msgs_global_chat'), {
        FN_INDEX => $fn_index,
        SCRIPT   => 'chat_user_notification.js',
        SIDE_ID  => 'uid=' . $user->{UID},
      },
        { OUTPUT2RETURN => 1 });
      $OUTPUT{GLOBAL_CHAT} = $global_chat || '';
    }

    $OUTPUT{USER_SID} = $user->{SID};

    if (exists $conf{client_theme} && defined $conf{client_theme}) {
      my ($theme_type, $theme_color) = split('-', $conf{client_theme});
      $theme_type ||= 'dark';
      $theme_color ||= 'primary';
      $OUTPUT{NAVBAR_SKIN} = "navbar-dark navbar-$theme_color";
      $OUTPUT{SIDEBAR_SKIN} = "sidebar-$theme_type-$theme_color";
    }
    else {
      $OUTPUT{NAVBAR_SKIN} = 'navbar-dark navbar-lightblue';
      $OUTPUT{SIDEBAR_SKIN} = 'sidebar-dark-lightblue';
    }

    $OUTPUT{BODY} = $html->tpl_show(templates('form_client_main'), \%OUTPUT, {
      MAIN               => 1,
      ID                 => 'form_client_main',
      SKIP_DEBUG_MARKERS => 1,
    });
  }
  else {
    form_login_clients();
  }

  print $html->header();
  $OUTPUT{BODY} = $html->{OUTPUT};
  $OUTPUT{SIDEBAR_HIDDEN} = ($COOKIES{menuHidden} && $COOKIES{menuHidden} eq 'true')
    ? 'sidebar-collapse'
    : '';
  $OUTPUT{INDEX_NAME} = 'index.cgi';

  if ($conf{HOLIDAY_SHOW_BACKGROUND}) {
    $OUTPUT{BACKGROUND_HOLIDAY_IMG} = user_login_background();
  }

  if (!$OUTPUT{BACKGROUND_HOLIDAY_IMG}) {
    if ($conf{user_background}) {
      $OUTPUT{BACKGROUND_COLOR} = $conf{user_background};
    }
    elsif ($conf{user_background_url}) {
      $OUTPUT{BACKGROUND_URL} = $conf{user_background_url};
    }
  }

  if ($conf{user_confirm_changes}) {
    $OUTPUT{CONFIRM_CHANGES} = 1;
  }

  print $html->tpl_show(templates('form_client_start'), \%OUTPUT, {
    MAIN               => 1,
    SKIP_DEBUG_MARKERS => 1,
    ID                 => 'FORM_CLIENT_START'
  });

  $html->fetch({ DEBUG => $ENV{DEBUG} });

  if ($conf{dbdebug} && $admin->{db}->{queries_count} && $conf{PORTAL_DB_DEBUG}) {
    #$admin->{VERSION} .= " q: $admin->{db}->{queries_count}";

    if ($admin->{db}->{queries_list}) {
      my $output_text = '<br><textarea class="form-control" rows=28 style="width: 100%">';

      my $i = 0;
      my $query_list = $Conf->{db}->{queries_list};
      my $is_hash = (ref $query_list eq 'HASH');
      my @q_arr = $is_hash ? keys %{$query_list} : @{$query_list};

      foreach my $k (@q_arr) {
        $i++;
        my $is_dbcore_query = ref $k eq 'ARRAY';

        my $text = $is_dbcore_query ? $k->[0] : $k;
        my $time = sprintf("%.5f",
          $is_dbcore_query ? $k->[1] || 0 : 0
        );

        my $count = $is_hash ? " ($query_list->{$k})" : '';
        $output_text .= "$i $count";
        $output_text .= " =================================== $time s\n      $text\n";
      }
      $output_text .= '</textarea>';
      $admin->{FOOTER_DEBUG} .= $html->tpl_show(
        templates('form_show_hide'),
        {
          CONTENT => $output_text,
          NAME    => "$lang{QUERIES}: ".$i,
          ID      => 'QUERIES',
          PARAMS  => 'mx-n1',
          BUTTON_ICON => 'plus'
        },
        { OUTPUT2RETURN => 1 }
      );
    }

    print $admin->{FOOTER_DEBUG};
    print $admin->{VERSION} || 0;
  }

  return 1;
}


#**********************************************************
=head2 form_info($attr) User main information

=cut
#**********************************************************
sub form_info {

  $admin->{SESSION_IP} = $ENV{REMOTE_ADDR};

  #  For address ajax
  if ($FORM{get_index} && $FORM{get_index} eq 'form_address_select2') {
    require Control::Address_mng;
    form_address_select2(\%FORM);
    exit 1;
  }

  if (defined($FORM{PRINT_CONTRACT})) {
    if ($FORM{PRINT_CONTRACT}) {
      $FORM{UID} = $LIST_PARAMS{UID};
      load_module('Docs', $html);
      docs_contract();
    }
    else {
      print $html->header();
      $html->message('info', $lang{INFO}, $lang{NOT_EXIST});
    }
    return 1;
  }
  elsif ($FORM{print_add_contract}) {
    $user->pi();
    my $list = $user->contracts_list({ UID => $user->{UID}, ID => $FORM{print_add_contract}, COLS_UPPER => 1 });
    return 1 if ($user->{TOTAL} != 1);
    my $sig_img = "$conf{TPL_DIR}/sig.png";
    if ($list->[0]->{SIGNATURE}) {
      open(my $fh, '>', $sig_img);
      binmode $fh;
      my ($data) = $list->[0]->{SIGNATURE} =~ m/data:image\/png;base64,(.*)/;
      print $fh decode_base64($data);
      close $fh;
    }

    $html->tpl_show("$conf{TPL_DIR}/$list->[0]->{template}", { %$user, %{$list->[0]}, FIO_S => $user->{FIO} }, { TITLE => "Contract" });
    unlink $sig_img;
    return 1;
  }
  elsif ($FORM{signature}) {
    $user->contracts_change($FORM{sign}, { SIGNATURE => $FORM{signature} });
    $html->message('info', $lang{SIGNED});
  }
  elsif ($FORM{sign}) {
    $html->tpl_show(templates('signature'), {});
    return 1;
  }
  elsif (defined $FORM{PHOTO} && $FORM{UID} && $user->{UID} eq $FORM{UID}) {
    print "Content-Type: image/jpeg\n\n";
    print file_op({
      FILENAME => "$FORM{UID}.jpg",
      PATH     => "$conf{TPL_DIR}/if_image"
    });
    return 1;
  }
  elsif (defined $FORM{ATTACHMENT} && $FORM{UID} && $user->{UID} eq $FORM{UID}) {
    return form_show_attach({ UID => $user->{UID} });
  }

  #Activate dashboard
  if ($conf{USER_START_PAGE} && !$FORM{index} && !$FORM{json} && !$FORM{xml}) {
    form_custom();
    return 1;
  }

  $user->{CREDIT} //= 0;
  my $deposit = ($user->{CREDIT} == 0) ? ($user->{DEPOSIT} || 0) + ($user->{TP_CREDIT} || 0) : ($user->{DEPOSIT} || 0) + $user->{CREDIT};

  if ($deposit < 0) {
    form_neg_deposit($user);
  }
  
  ### START KTK-39
  service_info();
  ### END KTK-39
  if (!$conf{DOCS_SKIP_NEXT_PERIOD_INVOICE}) {
    if (in_array('Docs', \@MODULES) && (!$user->{GID} || $user->{DOCUMENTS_ACCESS})) {
      $FORM{ALL_SERVICES} = 1;
      load_module('Docs', $html);
      docs_invoice({ UID => $user->{UID}, USER_INFO => $user });
    }
  }

  form_credit();

  $user->pi();

  if ($FORM{REMOVE_SUBSCRIBE} && in_array($FORM{REMOVE_SUBSCRIBE}, [ qw/Push Telegram Viber/ ])) {
    require Contacts;
    Contacts->import();

    my $Contacts = Contacts->new($db, $admin, \%conf);
    $Contacts->contacts_del({
      UID     => $user->{UID},
      TYPE_ID => $Contacts->contact_type_id_for_name(uc($FORM{REMOVE_SUBSCRIBE}))
    });

    $html->redirect('/index.cgi');
    return 1;
  }

  _user_pi() if $conf{user_chg_pi};

  $user->{STATUS_CHG_BUTTON} = form_holdup(\%FORM) if $conf{HOLDUP_ALL};

  my $Payments = Finance->payments($db, $admin, \%conf);
  my $payment_list = $Payments->list({
    %LIST_PARAMS,
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    PAGE_ROWS => 1,
    DESC      => 'desc',
    SORT      => 1,
    COLS_NAME => 1
  });

  $user->{PAYMENT_DATE} = $payment_list->[0]->{datetime};
  $user->{PAYMENT_SUM} = $payment_list->[0]->{sum};
  if ($conf{EXT_BILL_ACCOUNT} && $user->{EXT_BILL_ID} > 0) {
    $user->{EXT_DATA} = $html->tpl_show(templates('form_client_ext_bill'), $user, { OUTPUT2RETURN => 1 });
  }

  $user->{STATUS} = ($user->{DISABLE}) ? $html->color_mark($lang{DISABLE}, $_COLORS[6]) : $lang{ENABLE};
  $deposit = sprintf("%.2f", $user->{DEPOSIT} || 0);

  $user->{DEPOSIT} = $deposit;

  my $sum = 0;
  if ($user && defined &recomended_pay) {
    $sum = recomended_pay($user) || 1;
  }

  $pages_qs = "&SUM=$sum&sid=$sid";

  if (in_array('Docs', \@MODULES) && !$conf{DOCS_SKIP_USER_MENU}) {
    if (!$user->{GID} || $user->{DOCUMENTS_ACCESS}) {
      my $fn_index = get_function_index('docs_invoices_list');
      $user->{DOCS_ACCOUNT} = $html->button($lang{INVOICE_CREATE}, "index=$fn_index$pages_qs", {
        ex_params => "class='btn btn-secondary btn-lg'"
      });
      $user->{DOCS_VISIBLE} = 1;
    }
  }

  if (in_array('Paysys', \@MODULES)) {
    if (defined $user->{GID} && !$conf{PAYMENT_HIDE_USER_MENU}) {
      my $group_info = $user->group_info($user->{GID});
      if ((exists($group_info->{DISABLE_PAYSYS}) && $group_info->{DISABLE_PAYSYS} == 0) || $group_info->{TOTAL} == 0) {
        my $fn_index = get_function_index('paysys_payment');
        $user->{PAYSYS_PAYMENTS} = $html->button("$lang{BALANCE_RECHARCHE}", "index=$fn_index$pages_qs", {
          ex_params => "class='btn btn-primary btn-lg'"
        });
      }
    }
  }

  if (in_array('Cards', \@MODULES)) {
    my $fn_index = get_function_index('cards_user_payment');
    $user->{CARDS_PAYMENTS} = $html->button($lang{ICARDS}, "index=$fn_index$pages_qs", {
      ex_params => "class='btn btn-secondary btn-lg'"
    });
  }

  ## Show users info fields
  require Control::Portal_mng;
  Control::Portal_mng->import();

  my $Portal_mng = Control::Portal_mng->new($db, $admin, \%conf, {
    html  => $html,
    lang  => \%lang,
    index => $index,
  });

  my $info_fields_view = $Portal_mng->get_info_fields_read_only_view({
    %FORM,
    VALUES                => $user,
    CALLED_FROM_CLIENT_UI => 1,
    RETURN_AS_ARRAY       => 1,
    USERS                 => (!$users && $user) ? $user : $users,
    SELF_URL              => $SELF_URL,
  });

  foreach my $info_field_view (@$info_fields_view) {
    my $name = $info_field_view->{NAME};
    my $view = $info_field_view->{VIEW};

    $user->{INFO_FIELDS_RAWS} .= $html->element('tr', $html->element('td', ($name || q{}), { class => 'font-weight-bold text-right', OUTPUT2RETURN => 1 }) .
        $html->element('td', ($view || q{}), { OUTPUT2RETURN => 1 }),{ OUTPUT2RETURN => 1 });
  }

  if ($conf{user_chg_pi}) {
    $user->{FORM_CHG_INFO} = $html->form_main({
      CONTENT       => $html->form_input('chg', "$lang{CHANGE}", { TYPE => 'SUBMIT', OUTPUT2RETURN => 1 }),
      HIDDEN        => {
        sid   => $sid,
        index => "$index"
      },
      OUTPUT2RETURN => 1
    });

    $user->{FORM_CHG_INFO} = $html->button($lang{CHANGE}, "index=$index&sid=$sid&chg=1", {
      class         => 'btn btn-success btn-xs',
      OUTPUT2RETURN => 1
    });
  }
  $user->{ACCEPT_RULES} = $html->tpl_show(templates('form_accept_rules'), { FIO => $user->{FIO}, HIDDEN => "style='display:none;'", CHECKBOX => "checked" }, { OUTPUT2RETURN => 1 });
  if (in_array('Portal', \@MODULES)) {
    load_module('Portal', $html);
    $user->{NEWS} = portal_user_cabinet();
  }

  if ($conf{user_chg_passwd} || ($conf{group_chg_passwd} && $conf{group_chg_passwd} eq $user->{GID})) {
    $user->{CHANGE_PASSWORD} = $html->button($lang{CHANGE_PASSWORD}, "index=17&sid=$sid", { class => 'btn btn-sm btn-primary' });
  }

  $user->{SOCIAL_AUTH_BUTTONS_BLOCK} = make_social_auth_manage_buttons($user);
  if ($user->{SOCIAL_AUTH_BUTTONS_BLOCK} eq '') {
    $user->{INFO_CARD_CLASS} = 'col-md-12';
  }
  else {
    $user->{INFO_CARD_CLASS} = 'col-md-10';
    $user->{HAS_SOCIAL_BUTTONS} = '1';
  }

  $user->{SENDER_SUBSCRIBE_BLOCK} = make_sender_subscribe_buttons_block();
  $user->{SHOW_SUBSCRIBE_BLOCK} = ($user->{SENDER_SUBSCRIBE_BLOCK}) ? 1 : 0;

  $user->{SHOW_REDUCTION} = ($user->{REDUCTION} && int($user->{REDUCTION}) > 0
    && !(exists $conf{user_hide_reduction} && $conf{user_hide_reduction})) ? '' : 'hidden';

  if (!$user->{CONTRACT_ID}) {
    $user->{NO_CONTRACT_MSG} = "$lang{NO_DATA}";
    $user->{NO_DISPLAY} = "style='display : none'";
  }

  $user->{SHOW_ACCEPT_RULES} = (exists $conf{ACCEPT_RULES} && $conf{ACCEPT_RULES}) ? 'd-inline-block' : 'd-none';

  my %contacts = ();
  my @phones = ();

  if ($user->{PHONE_ALL}) {push @phones, $user->{PHONE_ALL};}
  if ($user->{CELL_PHONE_ALL}) {push @phones, $user->{CELL_PHONE_ALL};}

  $contacts{PHONE} = ($#phones > -1) ? join(', ', @phones) : q{};
  $contacts{EMAIL} = $user->{EMAIL_ALL} || q{};

  if (in_array('Accident', \@MODULES) && $conf{USER_ACCIDENT_LOG}) {
    load_module('Accident', $html);
    accident_dashboard_mess();
  }

  if ($conf{MONEY_UNIT_NAMES}) {
    $user->{MONEY_UNIT_NAME} = (split(/;/, $conf{MONEY_UNIT_NAMES}))[0];
  }

  $html->tpl_show(templates('form_client_info'), { %$user, %contacts }, { ID => 'form_client_info' });

  if ($FORM{CONTRACT_LIST}) {
    require Control::Contracts_mng;
    $html->{OUTPUT} .= _user_contracts_table($user->{UID}, { UI => 1, USER_INFO => $user });
  }

  if (in_array('Internet', \@MODULES)) {
    load_module('Internet', $html);
    $LIST_PARAMS{UID} = $user->{UID};
    internet_user_info();
  }

  cross_modules('promotional_tp', { USER => $user });

  return 1;
}

#**********************************************************
=head2 form_holdup()

=cut
#**********************************************************
sub form_holdup {

  require Control::Service_control;
  Control::Service_control->import();
  my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

  my $holdup_info = $Service_control->user_holdup({
    %FORM,
    UID       => $user->{UID},
    USER_INFO => $user
  });

  if ($holdup_info->{error}) {
    my $error_message = $lang{$holdup_info->{errstr}} // $holdup_info->{errstr};
    $html->message('err', $lang{ERROR}, $error_message, { ID => $holdup_info->{error} })
  }

  if (!$holdup_info->{DEL}) {
    return '' if ($holdup_info->{error} || _error_show($holdup_info) || $holdup_info->{success});
    if (($user->{STATUS} && $user->{STATUS} == 3) || $user->{DISABLE}) {
      $html->message('info', $lang{INFO}, "$lang{HOLD_UP}\n " .
        $html->button($lang{ACTIVATE}, "index=$index&del=1&ID=". ($FORM{ID} || q{}) ."&sid=$sid",
          { BUTTON => 2, MESSAGE => "$lang{ACTIVATE}?" }) );
      return '';
    }

    $holdup_info->{FROM_DATE} = date_inc($DATE);
    $holdup_info->{TO_DATE} = $Service_control->{TO_DATE} || next_month({ DATE => $DATE });
    if ($Service_control->{HOLDUP_INFOS}) {
      foreach my $holdup ( @{ $Service_control->{HOLDUP_INFOS} } ) {
        $holdup_info->{HOLDUP_INFO} .= "$lang{MAX} $lang{DAYS}: " .$holdup->{MAX_PERIOD} ." - $lang{PRICE}: "
          . sprintf("%.2f", $holdup->{PRICE}) . $html->br();

        $holdup_info->{HOLDUP_PRICE} = sprintf("%.2f", $holdup->{PRICE} || 0) if (! $holdup_info->{HOLDUP_PRICE});
      }
    }


    return $html->tpl_show(templates('form_holdup'), $holdup_info, { OUTPUT2RETURN => 1 });
  }
  else {
    $html->message('info', $lang{INFO}, "$lang{HOLD_UP}: $holdup_info->{DATE_FROM} $lang{TO} $holdup_info->{DATE_TO}"
      . ($holdup_info->{DEL_IDS} ? ($html->br() . $html->button($lang{DEL},
      "index=$index&ID=". ($FORM{ID} || q{}) ."&del=1&IDS=$holdup_info->{DEL_IDS}". (($sid) ? "&sid=$sid" : q{}),
      { class => 'btn btn-primary', MESSAGE => "$lang{DEL} $lang{HOLD_UP}?" })) : q{}));
  }

  return q{};
}

#**********************************************************
=head2 _user_pi()

=cut
#**********************************************************
sub _user_pi {

  require Control::Address_mng;
  if($conf{ADDRESS_REGISTER}){
    if (defined($user->{FLOOR}) || defined($user->{ENTRANCE})) {
      $user->{EXT_ADDRESS} = $html->tpl_show(templates('form_ext_address'),
        { ENTRANCE => $user->{ENTRANCE} || '', FLOOR => $user->{FLOOR} || '' },
        { OUTPUT2RETURN => 1 });
    }
    $user->{ADDRESS_SEL} = form_address_select2($user,{ HIDE_ADD_BUILD_BUTTON => 1});
  }
  else{
    my $countries_hash;

    ($countries_hash, $user->{COUNTRY_SEL}) = sel_countries({
      NAME    => 'COUNTRY_ID',
      COUNTRY => $user->{COUNTRY_ID},
    });

    $user->{ADDRESS_SEL} = $html->tpl_show(templates('form_address'), { %$user  }, { OUTPUT2RETURN => 1 });
  }

  if ($FORM{chg}) {
    my $user_pi = $user->pi();
    $user->{ACTION} = 'change';
    $user->{LNG_ACTION} = $lang{CHANGE};

    if ($conf{user_chg_info_fields}) {
      require Control::Users_mng;
      $user->{INFO_FIELDS} = form_info_field_tpl({
        VALUES                => $user_pi,
        CALLED_FROM_CLIENT_UI => 1,
        COLS_LEFT             => 'col-md-3',
        COLS_RIGHT            => 'col-md-12'
      });
    }

    my %contacts = ();
    $contacts{PHONE} = $user_pi->{PHONE_ALL};
    $contacts{CELL_PHONE} = $user_pi->{CELL_PHONE_ALL};
    $contacts{EMAIL} = $user_pi->{EMAIL_ALL};

    $user_pi->{FIO_READONLY} = 'readonly' if $user_pi->{FIO2} && $user_pi->{FIO3};

    if ($conf{CHECK_CHANGE_PI}) {
      my @all_fields = ('FIO', 'PHONE', 'ADDRESS', 'EMAIL', 'CELL_PHONE');
      my @fields_allow_to_change = split(',\s?', $conf{CHECK_CHANGE_PI});
      foreach my $key (@all_fields) {
        next if in_array($key, \@fields_allow_to_change);

        $contacts{$key . '_DISABLE'} = 'disabled';
      }

      $user_pi->{ADDRESS_SEL} = '' if ($contacts{ADDRESS_DISABLE});
    }

    $html->tpl_show(templates('form_chg_client_info'), { %$user_pi, %contacts }, { SKIP_DEBUG_MARKERS => 1 });

    return 1;
  }
  elsif ($FORM{change}) {
    user_pi_change(\%FORM);
  }
  elsif ($conf{CHECK_CHANGE_PI}) {
    $user->{TEMPLATE_BODY} = change_pi_popup();
  }
  elsif (!$user->{FIO}
    || !$user->{PHONE}
    || !$user->{CELL_PHONE}
    || !$user->{ADDRESS_STREET}
    || !$user->{ADDRESS_BUILD}
    || !$user->{EMAIL}) {
    # scripts for address
    $user->{MESSAGE_CHG} = $html->message('info', '', $lang{INFO_CHANGE_MSG}, { OUTPUT2RETURN => 1 });

    $user->{PINFO} = 1;
    $user->{ACTION} = 'change';
    $user->{LNG_ACTION} = $lang{CHANGE};

    #mark or disable input
    (! $user->{FIO} || $user->{FIO} eq '') ? ($user->{FIO_HAS_ERROR} = 'has-error') : ($user->{FIO_DISABLE} = 'disabled');
    (! $user->{PHONE} || $user->{PHONE} eq '') ? ($user->{PHONE_HAS_ERROR} = 'has-error') : ($user->{PHONE_DISABLE} = 'disabled');
    (! $user->{EMAIL} || $user->{EMAIL} eq '') ? ($user->{EMAIL_HAS_ERROR} = 'has-error') : ($user->{EMAIL_DISABLE} = 'disabled');

    # Instead of hiding, just not printing address form
    if ($user->{ADDRESS_HIDDEN}) {
      delete $user->{ADDRESS_SEL};
    }
    # template to modal
    $user->{TEMPLATE_BODY} = $html->tpl_show(templates('form_chg_client_info'), $user, { OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });
  }

  return 1;
}

#**********************************************************
=head2 user_pi_change($attr)

=cut
#**********************************************************
sub user_pi_change {
  my ($attr)=@_;

  if ($FORM{REMOVE_SUBSCRIBE}) {
    require Contacts;
    Contacts->import();

    my $Contacts = Contacts->new($db, $admin, \%conf);
    $Contacts->contacts_del({
      UID     => $user->{UID},
      TYPE_ID => $Contacts->contact_type_id_for_name(uc($attr->{REMOVE_SUBSCRIBE}))
    });

    $html->redirect('/index.cgi');
    return 1;
  }

  my $title = '';
  if ($conf{user_chg_pi_verification}) {
    #PHONE VERIFY
    if (in_array('Sms', \@MODULES) && $attr->{PHONE} && $attr->{PHONE} ne $user->{PHONE}) {
      if ($attr->{CONFIRMATION_PHONE} && $attr->{CONFIRMATION_PHONE} eq string_encoding($attr->{PHONE}, $user->{UID})) {
        $user->pi_change({ PHONE => $attr->{PHONE}, UID => $user->{UID} });
        if (_error_show($user)) {
          return 1;
        }
        $html->message('info', $lang{CHANGED}, "$lang{YOUR_PHONE_NUMBER}: $attr->{PHONE}");
        $user->pi();
      }
      else {
        if ($attr->{enter_more} && $attr->{enter_more} eq 'CONFIRMATION_PHONE') {
          $title = $lang{DO_AGAIN};
        }
        else {
          load_module('Sms', $html);
          sms_send({
            NUMBER     => $attr->{PHONE},
            MESSAGE    => '$lang{YOUR_VERIFICATION_CODE}: ',
            UID        => string_encoding($attr->{PHONE}, $user->{UID}),
            RIZE_ERROR => $user->{UID},
          });
          $title = $lang{PHONE_VERIFICATION};
        }
        $user->{FORM_CONFIRMATION_CLIENT_PHONE} = $html->tpl_show(
          templates('form_confirmation_client_info'),
          {
            INPUT_NAME => 'CONFIRMATION_PHONE',
            PHONE      => $attr->{PHONE},
            EMAIL      => $attr->{EMAIL},
            TITLE      => $title
          },
          { OUTPUT2RETURN => 1 }
        );

        $user->{CONFIRMATION_CLIENT_PHONE_OPEN_INFO} = 1;
        delete $attr->{PHONE};
      }
    }
    else {
      $user->{CONFIRMATION_CLIENT_PHONE_OPEN_INFO} = 0;
    }

    #MAIL VERIFY
    if ($attr->{EMAIL} && $attr->{EMAIL} ne $user->{EMAIL}) {
      if ($attr->{CONFIRMATION_EMAIL} && $attr->{CONFIRMATION_EMAIL} eq string_encoding($attr->{EMAIL}, $user->{UID})) {
        $user->pi_change({ EMAIL => $attr->{EMAIL}, UID => $user->{UID} });
        if (_error_show($user)) {
          return 1;
        }
        $html->message('info', $lang{CHANGED}, "$lang{YOUR_MAIL}: $attr->{EMAIL}");
        $user->pi();
      }
      else {
        if ($attr->{enter_more} && $attr->{enter_more} eq 'CONFIRMATION_EMAIL') {
          $title = $lang{DO_AGAIN};
        }
        else {
          sendmail("$conf{ADMIN_MAIL}", "$attr->{EMAIL}", "$conf{WEB_TITLE}",
            "$lang{YOUR_VERIFICATION_CODE}: " . string_encoding($attr->{EMAIL}, $user->{UID}) . "",
            "$conf{MAIL_CHARSET}", '', {});

          $title = $lang{EMAIL_VERIFICATION};
        }

        $user->{FORM_CONFIRMATION_CLIENT_EMAIL} = $html->tpl_show(
          templates('form_confirmation_client_info'),
          {
            INPUT_NAME => 'CONFIRMATION_EMAIL',
            EMAIL      => $attr->{EMAIL},
            PHONE      => $attr->{PHONE},
            TITLE      => $title
          },
          { OUTPUT2RETURN => 1 }
        );
        $user->{CONFIRMATION_EMAIL_OPEN_INFO} = 1;
        delete $attr->{EMAIL};
      }
    }
    else {
      $user->{CONFIRMATION_EMAIL_OPEN_INFO} = 0;
    }
  }

  if ($conf{user_confirm_changes}) {
    return 1 unless ($attr->{PASSWORD});
    $user->info($user->{UID}, { SHOW_PASSWORD => 1 });
    if ($attr->{PASSWORD} ne $user->{PASSWORD}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD});
      return 1;
    }
  }

  $attr->{FIO} = $attr->{FIO1} if ($attr->{FIO1});

  if($conf{CHECK_CHANGE_PI}){
    my @fields_allow_to_change = split(',\s?', $conf{CHECK_CHANGE_PI});
    foreach my $key (keys %FORM){
      if(!(in_array($key, \@fields_allow_to_change))){
        delete $attr->{$key};
      }
    }
  }

  $user->pi_change({ %FORM, UID => $user->{UID} });
  if ($user->{errno}) {
    if ($user->{errno} == 21) {
      $html->message('err', $lang{ERROR}, $user->{errstr});
    }
    else {
      $html->message('err', $lang{ERROR}, $user->{errno});
    }
    return 1;
  }

  $html->message('info', $lang{CHANGED}, $lang{CHANGED});

  $user->pi();

  return 1;
}

#**********************************************************
=head2 string_encoding($string, $uid)

=cut
#**********************************************************
sub string_encoding {
  my ($string, $uid_) = @_;

  return length($string) * 21 * $uid_;
}

#**********************************************************
=head2 _make_mobile_app_link($link, $title, $img_path)

=cut
#**********************************************************
sub _make_mobile_app_link {
  my ($link, $title, $img_path) = @_;

  return $html->button(
    $html->img($img_path, "$title Badge", { class => 'w-100' }),
    '',
    { target => '_blank', title => $title, GLOBAL_URL => $link }
  );
}

#**********************************************************
=head2 _mobile_app_links()

=cut
#**********************************************************
sub _mobile_app_links {
  my ($page) = @_;
  my @supported_langs = (
    'ukrainian',
    'russian',
    'english',
  );

  my $supported = in_array($html->{language}, \@supported_langs)
    ? $html->{language}
    : 'english';


  if ($conf{APP_LINK_APP_STORE}) {
    $page->{APP_LINK_APP_STORE} = _make_mobile_app_link(
      $conf{APP_LINK_APP_STORE},
      'App Store',
      "/img/apple/store/$supported.png"
    );
  }

  if ($conf{APP_LINK_GOOGLE_PLAY}) {
    $page->{APP_LINK_GOOGLE_PLAY} = _make_mobile_app_link(
      $conf{APP_LINK_GOOGLE_PLAY},
      'Google Play',
      "/img/google/play/$supported.png"
    );
  }

  return 1;
}

#**********************************************************
=head2 form_login_clients()

=cut
#**********************************************************
sub form_login_clients {
  my %first_page = ();

  if ($FORM{LOGIN_BY_PHONE}) {
    _login_send_pin();
    _login_confirm_pin();
  }

  $first_page{LOGIN_ERROR_MESSAGE} = $OUTPUT{LOGIN_ERROR_MESSAGE} || '';
  $first_page{PASSWORD_RECOVERY} = $conf{PASSWORD_RECOVERY};
  $first_page{FORGOT_PASSWD_LINK} = '/registration.cgi&FORGOT_PASSWD=1';

  _mobile_app_links(\%first_page);

  if (!$conf{REGISTRATION_PORTAL_SKIP}) {
    $first_page{REGISTRATION_ENABLED} = scalar @REGISTRATION || $conf{NEW_REGISTRATION_FORM};
  }

  if ($conf{tech_works}) {
    $html->message('info', $lang{INFO}, $conf{tech_works});
    return 0;
  }

  $first_page{SEL_LANGUAGE} = language_select('language');

  if (!$FORM{REFERER} && $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER} =~ /$SELF_URL/) {
    $ENV{HTTP_REFERER} =~ s/sid=[a-z0-9\_]+//g;
    $FORM{REFERER} = $ENV{HTTP_REFERER};
  }
  elsif ($ENV{QUERY_STRING}) {
    $ENV{QUERY_STRING} =~ s/sid=[a-z0-9\_]+//g;
    $FORM{REFERER} = $ENV{QUERY_STRING};
  }

  $first_page{TITLE} = $lang{USER_PORTAL};

  %first_page = ( %first_page, %{ make_social_auth_login_buttons() } );

  if ($conf{TECH_WORKS}) {
    $first_page{TECH_WORKS_BLOCK_VISIBLE} = 1;
    $first_page{TECH_WORKS_MESSAGE} = $conf{TECH_WORKS};
  }

  if ($conf{COOKIE_POLICY_VISIBLE} && $conf{COOKIE_URL_DOC}) {
    $first_page{COOKIE_POLICY_VISIBLE} = 'block';
    $first_page{COOKIE_URL_DOC} = $conf{COOKIE_URL_DOC};
  }
  else {
    $first_page{COOKIE_POLICY_VISIBLE} = 'none';
  }

  $first_page{G2FA_hidden} = 'hidden';
  if($FORM{G2FA}){
    $first_page{G2FA_hidden} = '';
    $first_page{password} = $FORM{password};
    $first_page{user} = $FORM{user};
    $first_page{g2fa} = $FORM{g2fa};
  }

  $OUTPUT{S_MENU} = 'style="display: none;"';

  if ($conf{AUTH_BY_PHONE}) {
    $first_page{AUTH_BY_PHONE} = 'd-block' ;
    $first_page{LOGIN_BY_PHONE} = $html->tpl_show(templates('form_login_by_phone'), {
      PHONE_NUMBER_PATTERN => $conf{PHONE_NUMBER_PATTERN} || ''
    }, { OUTPUT2RETURN => 1 });
  }
  else {
    $first_page{AUTH_BY_PHONE} = 'd-none' ;
  }

  $OUTPUT{BODY} = $html->tpl_show(templates('form_client_login'), \%first_page, {
    MAIN => 1,
    ID   => 'form_client_login'
  });
}

#**********************************************************
=head2 form_passwd() - User password form

=cut
#**********************************************************
sub form_passwd {

  $conf{PASSWD_SYMBOLS} = 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ' if (!$conf{PASSWD_SYMBOLS});
  $conf{PASSWD_LENGTH} = 6 if (!$conf{PASSWD_LENGTH});

  $user->pi({ UID => $user->{UID} });
  my $g2fa_message = "";

  if ($conf{AUTH_G2FA}) {
    require AXbills::Auth::OATH;
    AXbills::Auth::OATH->import();

    if ($FORM{g2fa}) {
      require AXbills::Auth::Core;
      AXbills::Auth::Core->import();
      my $Auth = AXbills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => 'OATH'
      });

      if ($Auth->check_access({ PIN => $FORM{g2fa}, SECRET => $FORM{g2fa_secret} })) {
        if ($FORM{g2fa_remove}) {
          $user->pi_change({
            UID   => $user->{UID},
            _G2FA => ''
          });
        }
        else {
          $user->pi_change({
            UID   => $user->{UID},
            _G2FA => $FORM{g2fa_secret}
          });
        }
        $g2fa_message = $html->message('info', $lang{SUCCESS}, '', { OUTPUT2RETURN => 1 });
      }
      else {
        $g2fa_message = $html->message('err', $lang{ERROR}, $lang{G2FA_WRONG_CODE}, { OUTPUT2RETURN => 1 });
      }
      $user->pi({ UID => $user->{UID} });
    }
  }

  my $password_check_ok = 0;
  if (!$FORM{newpassword}) {

  }
  elsif (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {

    my $explain_string = $lang{ERR_SHORT_PASSWD};
    $explain_string =~ s/ 6 / $conf{PASSWD_LENGTH} /;

    $html->message('err', $lang{ERROR}, $explain_string);
  }
  elsif ($conf{PASSWD_POLICY_USERS} && $conf{CONFIG_PASSWORD}
    && defined $user->{UID}
    && !Conf::check_password($FORM{newpassword}, $conf{CONFIG_PASSWORD})
  ) {
    load_module('Config', $html);
    my $explain_string = config_get_password_constraints($conf{CONFIG_PASSWORD});

    $html->message('err', $lang{ERROR}, "$lang{ERR_PASSWORD_INSECURE} $explain_string");
  }
  else {
    $password_check_ok = 1;
  }

  if ($password_check_ok && $FORM{newpassword} eq $FORM{confirm}) {
    my %INFO = (
      PASSWORD => $FORM{newpassword},
      UID      => $user->{UID},
      DISABLE  => $user->{DISABLE}
    );

    $user->change($user->{UID}, \%INFO);

    if (!_error_show($user)) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
      cross_modules('payments_maked', { USER_INFO => $user });
    }

    return 0;
  }
  elsif ($FORM{newpassword} && $FORM{confirm} && $FORM{newpassword} ne $FORM{confirm}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_CONFIRM});
  }

  my %password_form = ();
  $password_form{PW_CHARS} = $conf{PASSWD_SYMBOLS};
  $password_form{PW_LENGTH} = $conf{PASSWD_LENGTH} || 6;
  $password_form{ACTION} = 'change';
  $password_form{LNG_ACTION} = $lang{CHANGE};
  $password_form{CONFIG_PASSWORD} = $conf{CONFIG_PASSWORD} || '';

  $password_form{G2FA_HIDDEN} = 'hidden';

  if ($conf{AUTH_G2FA} && !$user->{_G2FA}) {
    $password_form{G2FA_HIDDEN} = '';

    my $secret = $FORM{g2fa_secret} || uc(mk_unique_value(32));
    $password_form{G2FA_SECRET} = $secret;

    require Control::Qrcode;
    Control::Qrcode->import();
    my $QRCode = Control::Qrcode->new($db, $admin, \%conf, { html => $html });

    my $img_qr = $QRCode->_encode_url_to_img(AXbills::Auth::OATH::encode_base32($secret), {
      AUTH_G2FA_NAME => $conf{WEB_TITLE} || 'AXbills',
      AUTH_G2FA_MAIL => $user->{LOGIN},
      OUTPUT2RETURN  => 1,
    });

    $password_form{G2FA_QR} = "<img src='data:image/jpg;base64," . encode_base64($img_qr) . "'>";
    $password_form{G2FA_BUTTON} = $lang{ADD};
  }
  elsif ($conf{AUTH_G2FA} && $user->{_G2FA}) {
    $password_form{G2FA_BUTTON} = $lang{REMOVE};
    $password_form{G2FA_SECRET} = $user->{_G2FA};
    $password_form{G2FA_HIDDEN} = '';
    $password_form{G2FA_REMOVE} = 1;
  }

  if ($g2fa_message) {
    $password_form{G2FA_MESSAGE} = $g2fa_message;
  }

  $html->tpl_show(templates('form_password'), \%password_form);

  return 1;
}

#**********************************************************
=head2 accept_rules()

=cut
#**********************************************************
sub accept_rules {
  $user->pi({ UID => $user->{UID} });
  if ($FORM{ACCEPT} && $FORM{accept}) {
    if ($user->{TOTAL} == 0) {
      $user->pi_add({ UID => $user->{UID}, ACCEPT_RULES => 1 });
    }
    else {
      $user->pi_change({ UID => $user->{UID}, ACCEPT_RULES => 1 });
    }

    return 0;
  }

  if ($user->{ACCEPT_RULES}) {
    return 0;
  }

  $html->tpl_show(templates('form_accept_rules'), $user);

  print $html->header();
  $OUTPUT{BODY} = $html->{OUTPUT};
  print $OUTPUT{BODY};
  exit;
}

#**********************************************************
=head2 reports($attr) -  Report main interface

=cut
#**********************************************************
sub reports {
  my ($attr) = @_;

  my $EX_PARAMS;
  my ($y, $m, $d);
  my $type = 'DATE';

  if ($FORM{MONTH}) {
    $LIST_PARAMS{MONTH} = $FORM{MONTH};
    $pages_qs = "&MONTH=$LIST_PARAMS{MONTH}";
  }
  elsif ($FORM{allmonthes}) {
    $type = 'MONTH';
    $pages_qs = "&allmonthes=1";
  }
  else {
    ($y, $m, $d) = split(/-/, $DATE, 3);
    $LIST_PARAMS{MONTH} = "$y-$m";
    $pages_qs = "&MONTH=$LIST_PARAMS{MONTH}";
  }

  if ($LIST_PARAMS{UID}) {
    $pages_qs .= "&UID=$LIST_PARAMS{UID}";
  }
  else {
    if ($FORM{GID}) {
      $LIST_PARAMS{GID} = $FORM{GID};
      $pages_qs = "&GID=$FORM{GID}";
      delete $LIST_PARAMS{GIDS};
    }
  }

  my @rows = ();
  my $FIELDS = '';

  if ($attr->{FIELDS}) {
    my %fields_hash = ();
    if (defined($FORM{FIELDS})) {
      my @fileds_arr = split(/, /, $FORM{FIELDS});
      foreach my $line (@fileds_arr) {
        $fields_hash{$line} = 1;
      }
    }

    $LIST_PARAMS{FIELDS} = $FORM{FIELDS};
    $pages_qs = "&FIELDS=$FORM{FIELDS}";

    my $table2 = $html->table({ width => '100%' });
    my @arr = ();
    my $i = 0;

    foreach my $line (sort keys %{$attr->{FIELDS}}) {
      my (undef, $k) = split(/:/, $line);

      push @arr, $html->form_input("FIELDS", $k, { TYPE => 'checkbox', STATE => (defined($fields_hash{$k})) ? 'checked' : undef, OUTPUT2RETURN => 1 }) . " $attr->{FIELDS}{$line}";
      $i++;
      if ($#arr > 1) {
        $table2->addrow(@arr);
        @arr = ();
      }
    }

    if ($#arr > -1) {
      $table2->addrow(@arr);
    }
    $FIELDS .= $table2->show({ OUTPUT2RETURN => 1 });
  }

  if ($attr->{PERIOD_FORM}) {
    if ($attr->{DATE_RANGE}) {
      my $date = $attr->{DATE};

      if ($FORM{'FROM_DATE_TO_DATE'}) {
        $date = $FORM{'FROM_DATE_TO_DATE'};
      }
      elsif(! $attr->{DATE}) {
        ($y, $m, $d) = split(/-/, $DATE, 3) if (! $y);
        $date = "$y-$m-01/$DATE";
      }

      push @rows, $html->element('label', "$lang{DATE}: ", { class => 'col-md-2 control-label', OUTPUT2RETURN => 1 })
        . $html->element('div', $html->form_daterangepicker({
        NAME      => 'FROM_DATE/TO_DATE',
        FORM_NAME => 'report_panel',
        VALUE     => $date,
        WITH_TIME => $attr->{TIME_FORM} || 0,
      }), { class => 'col-md-8', OUTPUT2RETURN => 1 });
    }
    else {
      push @rows, $html->element('label', "$lang{DATE} $lang{FROM}: ", { class => 'col-md-2 control-label', OUTPUT2RETURN => 1 })
        . $html->element('div', $html->date_fld2('FROM_DATE', { FORM_NAME => 'report_panel' }), { class => 'col-md-8', OUTPUT2RETURN => 1 });

      push @rows, $html->element('label', "$lang{TO}: ", { class => 'col-md-2 control-label', OUTPUT2RETURN => 1 })
        . $html->element('div', $html->date_fld2('TO_DATE', { FORM_NAME => 'report_panel' }), { class => 'col-md-8', OUTPUT2RETURN => 1 });
    }

    if (!$attr->{NO_GROUP}) {
      push @rows, $html->element('label', "$lang{TYPE}: ", { class => 'col-md-2 control-label', OUTPUT2RETURN => 1 })
        . $html->element('div', $html->form_select('TYPE', {
        SELECTED => $FORM{TYPE},
        SEL_HASH => {
          DAYS  => $lang{DAYS},
          USER  => $lang{USERS},
          HOURS => $lang{HOURS},
          ($attr->{EXT_TYPE}) ? %{$attr->{EXT_TYPE}} : ''
        },
        NO_ID    => 1
      }), { class => 'col-md-8', OUTPUT2RETURN => 1 });
    }

    if ($attr->{EX_INPUTS}) {
      foreach my $line (@{$attr->{EX_INPUTS}}) {
        push @rows, $line;
      }
    }

    my %info = ();
    my $info_rows = '';
    foreach my $val (@rows) {
      $info{ROWS} = $html->element('div', ($val || q{ }), { class => 'form-group row', OUTPUT2RETURN => 1 });
      $info_rows .= $html->element('div', ($info{ROWS} || q{ }), { class => ($attr->{col_md} || 'col-md-6'), OUTPUT2RETURN => 1 });
    }
    my $row_body = $html->element('div', $info_rows, { class => 'row', OUTPUT2RETURN => 1});
    my $box_body = $html->element('div', $row_body . $FIELDS, { class => 'card-body', OUTPUT2RETURN => 1 });
    my $box_footer = $html->element('div', $html->form_input('show', $lang{SHOW}, {
      class => 'btn btn-primary btn-block', TYPE => 'submit', FORM_ID => 'form_reports', OUTPUT2RETURN => 1
    }), { class => 'card-footer', OUTPUT2RETURN => 1 });

    my $box_header = $html->element('div', $html->element('h4', $lang{SET_PARAMS}, {
      class => 'card-title table-caption', OUTPUT2RETURN => 1
    }) . '<div class="card-tools float-right">' . ($attr->{EXTRA_HEADER_BTN} || "") . '
      <button type="button" class="btn btn-tool" data-card-widget="collapse">
      <i class="fa fa-minus"></i></button></div>', { class => 'card-header with-border', OUTPUT2RETURN => 1 });
    my $report_form = $html->element('div', $box_header . $box_body . $box_footer, {
      class => 'card card-primary card-outline', OUTPUT2RETURN => 1
    });

    print $html->form_main({
      CONTENT => $report_form,
      NAME    => 'form_reports',
      ID    => 'form_reports',
      HIDDEN  => {
        'index' => $index,
        ($attr->{HIDDEN}) ? %{$attr->{HIDDEN}} : undef
      }
    });

    if (defined($FORM{show})) {
      $FORM{FROM_DATE} //= q{};
      $FORM{TO_DATE} //= q{};
      $pages_qs .= "&show=1&FROM_DATE=$FORM{FROM_DATE}&TO_DATE=$FORM{TO_DATE}";
      $LIST_PARAMS{TYPE} = $FORM{TYPE};
      $LIST_PARAMS{INTERVAL} = "$FORM{FROM_DATE}/$FORM{TO_DATE}";
    }
  }

  if (defined($FORM{DATE})) {
    ($y, $m, $d) = split(/-/, $FORM{DATE}, 3);

    $LIST_PARAMS{DATE} = "$FORM{DATE}";
    $pages_qs .= "&DATE=$LIST_PARAMS{DATE}";

    if (defined($attr->{EX_PARAMS})) {
      my $EP = $attr->{EX_PARAMS};
      while (my ($k, $v) = each(%$EP)) {
        if ($FORM{EX_PARAMS} eq $k) {
          $EX_PARAMS .= ' ' . $html->b($v);
          $LIST_PARAMS{$k} = 1;
          if ($k eq 'HOURS') {
            undef $attr->{SHOW_HOURS};
          }
        }
        else {
          $EX_PARAMS .= $html->button($v, "index=$index$pages_qs&EX_PARAMS=$k", { BUTTON => 1 }) . ' ';
        }
      }
    }

    my $days = '';
    for (my $i = 1; $i <= 31; $i++) {
      $days .= ($d == $i) ? ' ' . $html->b($i) : ' '
        . $html->button(
        $i,
        sprintf("index=$index&DATE=%d-%02.f-%02.f&EX_PARAMS=$FORM{EX_PARAMS}%s%s", $y, $m, $i, (defined($FORM{GID})) ? "&GID=$FORM{GID}" : '', (defined($FORM{UID})) ? "&UID=$FORM{UID}" : ''),
        { BUTTON => 1 }
      );
    }

    @rows = ([ "$lang{YEAR}:", $y ], [ "$lang{MONTH}:", $MONTHES[ $m - 1 ] ], [ "$lang{DAY}:", $days ]);

    if ($attr->{SHOW_HOURS}) {
      my (undef, $h) = split(/ /, $FORM{HOUR}, 2);
      my $hours = '';
      for (my $i = 0; $i < 24; $i++) {
        $hours .= ($h == $i) ? $html->b($i) : ' ' . $html->button($i, sprintf("index=$index&HOUR=%d-%02.f-%02.f+%02.f&EX_PARAMS=$FORM{EX_PARAMS}$pages_qs", $y, $m, $d, $i), { BUTTON => 1 });
      }
      $LIST_PARAMS{HOUR} = "$FORM{HOUR}";
      push @rows, [ "$lang{HOURS}", $hours ];
    }

    if ($attr->{EX_PARAMS}) {
      push @rows, [ ' ', $EX_PARAMS ];
    }

    my $table = $html->table(
      {
        width      => '100%',
        rowcolor   => $_COLORS[1],
        cols_align => [ 'right', 'left' ],
        rows       => [ @rows ]
      }
    );
    print $table->show();
  }

  return 1;
}


#**********************************************************
=head2 form_finance

=cut
#**********************************************************
sub form_finance {

  my $param = {
    rows       => 10,
    pagination => 0 # disable pagination
  };

  form_fees($param);

  form_payments_list($param);

  return 1;
}

#**********************************************************
=head2 form_fees($attr)

=cut
#**********************************************************
sub form_fees {
  my $attr = shift;

  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
    $LIST_PARAMS{PAGE_ROWS} = $attr->{rows} || '';
  }

  my $FEES_METHODS = get_fees_types();

  if ($conf{user_fees_methods}) {
    $LIST_PARAMS{METHOD}=$conf{user_fees_methods};
  }

  $conf{user_payment_journal_show}//=6;
  if($conf{user_payment_journal_show}) {
    $LIST_PARAMS{FEES_MONTHES} = $conf{user_payment_journal_show};
  }

  my $Fees = Finance->fees($db, $admin, \%conf);
  my $list = $Fees->list({
    METHOD       => '_SHOW',
    %LIST_PARAMS,
    DSC          => '_SHOW',
    DATETIME     => '_SHOW',
    SUM          => '_SHOW',
    DEPOSIT      => '_SHOW',
    LAST_DEPOSIT => '_SHOW',
    LOGIN        => undef,
    COLS_NAME    => 1
  });

  shift @{ $Fees->{COL_NAMES_ARR} };

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{FEES},
    title_plain => [
      $lang{DATE},
      $lang{DESCRIBE},
      $lang{SUM},
      $lang{DEPOSIT},
      $lang{TYPE}
    ],
    LITE_HEADER => 1,
    FIELDS_IDS  => $Fees->{COL_NAMES_ARR},
    qs          => $pages_qs,
    pages       => $Fees->{TOTAL},
    ID          => 'FEES'
  });
  my $summary = {
    TOTAL      => $Fees->{TOTAL},
    SUM        => sprintf($conf{DEPOSIT_FORMAT} || '%.2f', $Fees->{SUM}),
    PAGINATION => $attr->{pagination} && $attr->{pagination} == 0 ? '' : $table->{pagination}
  };

  $table->table_summary($html->tpl_show(templates('form_table_summary'), $summary, { OUTPUT2RETURN => 1 }));

  foreach my $line (@$list) {
    while ( $line->{dsc} =~ /([A-Z\_]+)/g) {
      my $res = $1;
      my $lang_res = $lang{$res};
      next if !$lang_res;
      $line->{dsc} =~ s/$1/$lang_res/g;
    }

    $table->addrow(
      $line->{datetime},
      $line->{dsc},
      sprintf($conf{DEPOSIT_FORMAT} || '%.2f', $line->{sum} || 0),
      sprintf($conf{DEPOSIT_FORMAT} || '%.2f', $line->{last_deposit} || 0),
      $FEES_METHODS->{ $line->{method} || 0}
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_payments_list()

=cut
#**********************************************************
sub form_payments_list {
  my $attr = shift;

  my $Payments = Finance->payments($db, $admin, \%conf);

  if (!$FORM{sort}) {
    $LIST_PARAMS{sort} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
    $LIST_PARAMS{PAGE_ROWS} = $attr->{rows} || '';
  }

  if ($conf{user_payments_methods}) {
    $LIST_PARAMS{METHOD}=$conf{user_payments_methods};
  }

  if($conf{user_payment_journal_show}) {
    $LIST_PARAMS{PAYMENTS_MONTHES} = $conf{user_payment_journal_show};
  }

  my $list = $Payments->list({
    %LIST_PARAMS,
    DATETIME     => '_SHOW',
    DSC          => '_SHOW',
    SUM          => '_SHOW',
    LAST_DEPOSIT => '_SHOW',
    LOGIN        => undef,
    COLS_NAME    => 1
  });

  shift  @{ $Payments->{COL_NAMES_ARR} };

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{PAYMENTS},
    title_plain => [
      $lang{DATE},
      $lang{DESCRIBE},
      $lang{SUM},
      $lang{DEPOSIT}
    ],
    LITE_HEADER => 1,
    FIELDS_IDS  => $Payments->{COL_NAMES_ARR},
    qs          => $pages_qs,
    pages       => $Payments->{TOTAL},
    ID          => 'PAYMENTS'
  });

  my $summary = {
    TOTAL      => $Payments->{TOTAL},
    SUM        => sprintf($conf{DEPOSIT_FORMAT} || '%.2f', $Payments->{SUM} || 0),
    PAGINATION => $attr->{pagination} && $attr->{pagination} == 0 ? '' : $table->{pagination}
  };

  $table->table_summary($html->tpl_show(templates('form_table_summary'), $summary, { OUTPUT2RETURN => 1 }));

  foreach my $line (@$list) {
    while ( $line->{dsc} =~ /([A-Z\_]+)/g) {
      my $res = $1;
      my $lang_res = $lang{$res};
      next if !$lang_res;
      $line->{dsc} =~ s/$1/$lang_res/g;
    }

    $table->addrow(
      $line->{datetime},
      $line->{dsc},
      sprintf($conf{DEPOSIT_FORMAT} || '%.2f', $line->{sum} || 0),
      sprintf($conf{DEPOSIT_FORMAT} || '%.2f', $line->{last_deposit} || 0),
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_period($period, $attr)

  Arguments:
    $period
    $attr
      SHEDULE  - SHedule form input
      NOW      - Now form input
      PERIOD   - Select period

  Return:
    $period_html_form

=cut
#**********************************************************
sub form_period {
  my ($period, $attr) = @_;

  if ($FORM{json}) {
    return q{};
  }

  my @periods = ($lang{NOW}, $lang{NEXT_PERIOD}, $lang{DATE});
  $attr->{TP}->{date_fld} = $html->date_fld2('DATE', { FORM_NAME => 'user', MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS, NEXT_DAY => 1 });
  my $form_period = '';
  $form_period .= "<label class='control-label col-md-2'>$lang{DATE}:</label>";
  $period = $attr->{PERIOD} || 1;

  if(! $attr->{SHEDULE}) {
    pop @periods;
  }

  $form_period .= "<div class='col-md-10'>";

  if($attr->{NOW}) {
    $period = $attr->{PERIOD} || 0;
    $form_period .= "<div class='row'><div class='control-element col-md-1'>" . $html->form_input(
      'period', "0",
      {
        TYPE          => "radio",
        STATE         => (0 eq $period) ? 1 : undef,
        OUTPUT2RETURN => 1
      }
    )
    . "</div>"
    . "<div class='col-md-11 control-element text-left'>" . $lang{NOW} . '</div>'
    . '</div>';
  }

  for (my $i = 1; $i <= $#periods; $i++) {
    my $t = $periods[$i];

    $form_period .= "<div class='row'><div class='control-element col-md-1'>" . $html->form_input(
      'period', "$i",
      {
        TYPE          => "radio",
        STATE         => ($i eq $period) ? 1 : undef,
        OUTPUT2RETURN => 1
      }
    );
    $form_period .= "</div>"; #control-element (radio)

    if ($i == 1) {
      if ($attr->{ABON_DATE}) {
        $form_period .= "<div class='col-md-11 text-left'><span class='control-element'>" . $t . "</span> ($attr->{ABON_DATE}) </div>";
      }
    }
    else {
      $form_period .= "<div class='control-element col-md-2'>" . $t . "</div><div class='col-md-4'> $attr->{TP}->{date_fld} </div><div class='col-md-4'></div>";
    }
    $form_period .= "</div>"; #row
  }

  $form_period .= "</div>";

  return $form_period;
}

#**********************************************************
=head2 form_money_transfer() transfer funds between users accounts

=cut
#**********************************************************
sub form_money_transfer {
  my $deposit_limit = 0;
  my $transfer_price = 0;
  my $no_companies = q{};

  $admin->{SESSION_IP} = $ENV{REMOTE_ADDR};

  if ($conf{MONEY_TRANSFER} =~ /:/) {
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
    elsif ($FORM{RECIPIENT} == $user->{UID}) {
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

          #Payments
          $html->tpl_show(templates('form_money_transfer_s3'), { %FORM, %$user2 });
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

#**********************************************************
=head1 form_neg_deposit($user, $attr)

  Arguments:
    $user
    $attr

=cut
#**********************************************************
sub form_neg_deposit {
  my ($user_) = @_;

  $user_->{TOTAL_DEBET} = recomended_pay($user_);

  #use dv warning expr
  if ($conf{PORTAL_EXTRA_WARNING}) {
    if ($conf{PORTAL_EXTRA_WARNING} =~ /CMD:(.+)/) {
      $user_->{EXTRA_WARNING} = cmd($1, {
        PARAMS => {
          language => $html->{language},
          %{$user_},
        }
      });
    }
  }

  $user_->{TOTAL_DEBET} = sprintf("%.2f", $user_->{TOTAL_DEBET});
  $pages_qs = "&SUM=$user_->{TOTAL_DEBET}&sid=$sid";

  if (in_array('Docs', \@MODULES) && !$conf{DOCS_SKIP_USER_MENU}) {
    my $fn_index = get_function_index('docs_invoices_list');
    $user_->{DOCS_BUTTON} = $html->button("$lang{INVOICE_CREATE}", "index=$fn_index$pages_qs", { BUTTON => 2 });
  }

  if (in_array('Paysys', \@MODULES)) {

    # check if user group has Disable Paysys mode
    unless ($conf{PAYMENT_HIDE_USER_MENU}) {
      if (defined $user->{GID}) {
        my $group_info = $user->group_info($user->{GID});

        if (!$group_info->{DISABLE_PAYSYS}) {
          my $fn_index = get_function_index('paysys_payment');
          $user->{PAYSYS_PAYMENTS} = $html->button($lang{BALANCE_RECHARCHE}, "index=$fn_index$pages_qs", { BUTTON => 2 });
        }
      }
      else {
        my $fn_index = get_function_index('paysys_payment');
        $user->{PAYSYS_PAYMENTS} = $html->button($lang{BALANCE_RECHARCHE}, "index=$fn_index$pages_qs", { BUTTON => 2 });
      }
    }
  }

  if (in_array('Cards', \@MODULES)) {
    my $fn_index = get_function_index('cards_user_payment');
    $user_->{CARDS_BUTTON} = $html->button("$lang{ICARDS}", "index=$fn_index$pages_qs", { BUTTON => 2 });
  }

  $user_->{DEPOSIT} = sprintf($conf{DEPOSIT_FORMAT} || "%.2f", $user_->{DEPOSIT});
  if ($conf{MONEY_UNIT_NAMES}) {
    $user->{MONEY_UNIT_NAME}=(split(/;/, $conf{MONEY_UNIT_NAMES}))[0];
  }

  $html->tpl_show(templates('form_neg_deposit'), $user_, { ID => 'form_neg_deposit' });

  return 1;
}

## START КТК-39 ###  
#**********************************************************
=head2 service_info($Service)

=cut
#**********************************************************
sub service_info {
  my ($Service) = @_;

  my $uid = $FORM{UID} || $LIST_PARAMS{UID} || 0;

	my $user_info = $user->info($uid);

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

  $html->message('info', $lang{SERVICES} ,$pre_info);

  return 1;
}
## END КТК-39 ###
#**********************************************************
=head2 user_login_background($attr)

=cut
#**********************************************************
sub user_login_background {

  require Tariffs;
  Tariffs->import();

  my $holidays = Tariffs->new($db, \%conf, $admin);
  my $holiday_path = "/images/holiday/";
  my $list = $holidays->holidays_list({ COLS_NAME => 1 });

  my (undef, $m, $d) = split('-', $DATE);

  my $simple_date = (int($m) . '-' . int($d));
  foreach my $line (@$list) {
    if ($line->{day} && $line->{day} eq $simple_date && $line->{file}) {
      if (-f $conf{TPL_DIR} . '/holiday/' . $line->{file}) {
        return $holiday_path . $line->{file};
      }
    }
  }

  return if ($conf{user_background} || $conf{user_background_url});

  my $holiday_background_image = '';

  if ($m == 12 || $m < 3) {
    $holiday_background_image = "/holiday/winter.jpg";
  }
  elsif ($m >= 3 && $m < 6) {
    $holiday_background_image = "/holiday/spring.jpg";
  }
  elsif ($m >= 6 && $m < 9) {
    $holiday_background_image = "/holiday/summer.jpg";
  }
  else {
    $holiday_background_image = "/holiday/autumn.jpg";
  }

  if (-f $conf{TPL_DIR} . $holiday_background_image) {
    return '/images' . $holiday_background_image;
  }

  return '';
}

#**********************************************************
=head2 form_events($attr) - Show system events

=cut
#**********************************************************
sub form_events {
  my @result_array = ();

  if($conf{SKIP_EVENTS}) {
    print "Content-Type: application/json;\n\n";
    print "[ " . join(", ", @result_array) . " ]";
    return 1;
  }

  my $first_stage = gen_time($begin_time, { TIME_ONLY => 1 });
  print "Content-Type: text/html\n\n";

  my $cross_modules_return = cross_modules('_events', {
    UID              => $user->{UID},
    CLIENT_INTERFACE => 1
  });

  foreach my $module (sort keys %{$cross_modules_return}) {
    my $result = $cross_modules_return->{$module};
    if ($result && $result ne '') {
      push(@result_array, $result);
    }
  }

  print "[ " . join(", ", @result_array) . " ]";

  if ($FORM{DEBUG}) {
    print "First: $first_stage Total: "
      .gen_time($begin_time, { TIME_ONLY => 1 });
  }

  return 1;
}

#**********************************************************
=head2 fl() -  Static menu former

=cut
#**********************************************************
sub fl {
  if ($user->{UID} && $conf{REVISOR_UID} && $user->{UID} == $conf{REVISOR_UID}) {
    if (!$conf{REVISOR_ALLOW_IP} || check_ip($ENV{REMOTE_ADDR}, $conf{REVISOR_ALLOW_IP})) {
      my $revisor_menu = custom_menu({ TPL_NAME => 'revisor_menu' });
      mk_menu($revisor_menu, { CUSTOM => 1 });
    }
    else {
      $html->message('err', $lang{ERROR}, "$lang{ERR_UNKNOWN_IP}");
    }
    return 1;
  }

  my $custom_menu = custom_menu({ TPL_NAME => 'client_menu' });

  if ($#{$custom_menu} > -1) {
    mk_menu($custom_menu, { CUSTOM => 1 });
    return 1;
  }

  my @m = ("10:0:$lang{USER_INFO}:form_info:::");

  if ($conf{user_finance_menu}) {
    push @m, "40:0:$lang{FINANCES}:form_finance:::";
    push @m, "41:40:$lang{PAYMENTS}:form_payments_list:::";
    push @m, "42:40:$lang{FEES}:form_fees:::";
    if ($conf{MONEY_TRANSFER}) {
      push @m, "43:40:$lang{MONEY_TRANSFER}:form_money_transfer:::";
    }

    if ($user->{COMPANY_ID}) {
      require Companies;
      Companies->import();
      my $Company = Companies->new($db, $admin, \%conf);
      my $company_list = $Company->admins_list({
        UID       => $user->{UID},
        COLS_NAME => 1
      });

      #TODO: do we really need it in finance operations?
      if ($Company->{TOTAL} > 0 && $company_list->[0]->{is_company_admin} eq '1'
      ) {
        push @m, "44:40:$lang{SERVICES}:form_company_list::";
        push @m, "45:0:$user->{COMPANY_NAME}:null::";
        push @m, "46:45:$lang{INFO}:form_company_info::";

      }
    }
  }

  # Should be 17 or you should change it at "CHANGE_PASSWORD" button in form_info()
  push @m, "17:0:$lang{PASSWD}:form_passwd:::" if (
    $conf{user_chg_passwd} ||
      ($conf{group_chg_passwd} && $conf{group_chg_passwd} eq $user->{GID})
  );

  mk_menu(\@m, { USER_FUNCTION_LIST => 1 });
  return 1;
}


#**********************************************************
=head2 form_custom() - Form start dashboard

=cut
#**********************************************************
sub form_custom {
  my %info = ();

  require Control::Users_slides;

  if ($conf{MONEY_UNIT_NAMES}) {
    $info{MONEY_UNIT_NAME}=(split(/;/, $conf{MONEY_UNIT_NAMES}))[0];
  }

  if (in_array('Accident', \@MODULES) && $conf{USER_ACCIDENT_LOG}) {
    load_module('Accident', $html);
    accident_dashboard_mess();
  }

  if (in_array('Portal', \@MODULES)) {
    load_module('Portal', $html);
    $info{NEWS} = portal_user_cabinet();
  }

  $info{RECOMENDED_PAY} = recomended_pay($user);

  my $json_info = user_full_info({ SHOW_ID => 1, USER_INFO => $user });
  if ($conf{WEB_DEBUG} && $conf{WEB_DEBUG} > 10) {
    $html->{OUTPUT} .= '<pre>';
    $html->{OUTPUT} .= $json_info;
    $html->{OUTPUT} .= '</pre>';
  }

  load_pmodule('JSON');

  my $json = JSON->new()->utf8(0);
  my $user_info = ();
  eval {
    $user_info = $json->decode($json_info);
    1;
  }
  or do {
    my $e = $@;
    $html->message('err', $lang{ERROR}, $e);
  };

  if (ref($user_info) eq 'ARRAY') {
    foreach my $key (@{$user_info}) {
      my $main_name = $key->{NAME};
      if ($key->{SLIDES}) {
        for (my $i = 0; $i <= $#{$key->{SLIDES}}; $i++) {
          foreach my $field_id (keys %{$key->{SLIDES}->[$i]}) {
            my $id = $main_name . '_' . $field_id . '_' . $i;
            $html->{OUTPUT} .= "$i  $id ---------------- $key->{SLIDES}->[$i]->{$field_id}<br>" if ($conf{WEB_DEBUG} && $conf{WEB_DEBUG} > 10);
            $info{$main_name . '' . $field_id. '' . $i} = $key->{SLIDES}->[$i]->{$field_id};
          }
        }
      }
      else {
        foreach my $field_id (keys %{$key->{CONTENT}}) {
          $html->{OUTPUT} .= $main_name . '_' . $field_id . " - $key->{CONTENT}->{$field_id}<br>" if ($conf{WEB_DEBUG} && $conf{WEB_DEBUG} > 10);
          $info{$main_name . '_' . $field_id} = $key->{CONTENT}->{$field_id};
        }
      }

      if ($key->{QUICK_TPL}) {
        $info{BIG_BOX} .= $html->tpl_show(_include($key->{QUICK_TPL}, $key->{MODULE}), \%info, { OUTPUT2RETURN => 1 });
      }
    }
  }

  require Control::Service_control;
  my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });
  my $credit_info = $Service_control->user_set_credit({ UID => $user->{UID}, REDUCTION => $user->{REDUCTION}, %FORM });

  if ($credit_info->{CREDIT_SUM}) {
    $info{SMALL_BOX} .= $html->tpl_show(templates('form_small_box'), $credit_info, { OUTPUT2RETURN => 1 });
  }

  if ($html->{NEW_MSGS}) {
    $info{SMALL_BOX} .= $html->tpl_show(templates('form_new_msgs_small_box'), \%info, { OUTPUT2RETURN => 1 });
  }

  if ($html->{HOLD_UP}) {
    $info{SMALL_BOX} .= $html->tpl_show(templates('form_hold_up_small_box'), \%info, { OUTPUT2RETURN => 1 });
  }

  if (defined($user->{_CONFIRM_PI})) {
    $info{SMALL_BOX} .= $html->tpl_show(templates('form_confirm_pi_small_box'), \%info, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(templates('form_client_custom'), \%info);

  return 1;
}

#**********************************************************
=head2 make_social_auth_login_buttons()

=cut
#**********************************************************
sub make_social_auth_login_buttons {

  my %result = ();

  foreach my $social_net_name ('Vk', 'Facebook', 'Google', 'Instagram', 'Twitter', 'Telegram', 'Apple') {
    my $conf_key_name = 'AUTH_' . uc($social_net_name) . '_ID';

    if (exists $conf{$conf_key_name} && $conf{$conf_key_name}) {
      $result{ $conf_key_name } = '';
      $result{ uc($social_net_name) } = "index.cgi?external_auth=$social_net_name";
    }
    else {
      $result{ $conf_key_name } = 'display: none;';
    }
  }

  if ($conf{AUTH_TELEGRAM_ID}) {
    $result{TELEGRAM_SCRIPT} = "<div class='hidden'><script async src='https://telegram.org/js/telegram-widget.js?21' data-telegram-login='test_axbills_bot' data-auth-url='?external_auth=Telegram' data-request-access='write'></script></div>";
  }

  return \%result;
}

#**********************************************************
=head2 make_social_auth_manage_buttons()

=cut
#**********************************************************
sub make_social_auth_manage_buttons {
  my $user_pi = shift || $user->pi();

  # Allow user to remove social network linkage
  if ($FORM{unreg}) {
    my $change_field = '_' . uc $FORM{unreg};
    if (defined($user_pi->{$change_field})) {
      delete $user->{errno} if ($user->{errno});
      $user->pi_change({ UID => $user->{UID}, $change_field => '' });
      undef $user_pi->{$change_field};
    }
  }
  my $result = '';

  #**********************************************************
  # Shorthand for forming social auth button block
  #**********************************************************
  my $make_button = sub {
    my ($name, $link, $attr) = ($_[0], $_[1], $_[2]);
    my $unreg_button = '';
    my $uc_name = uc($name);
    my $lc_name = lc($name);

    # If already registered, show 'unreg' button
    if (exists $user_pi->{'_' . $uc_name}
      && $user_pi->{'_' . $uc_name}
      && $user_pi->{'_' . $uc_name} ne ', ') {
      $unreg_button = $html->button('×', "index=$index&sid=$sid&unreg=$name", {
        class   => "btn btn-danger btn-social-unreg",
        CONFIRM => "$lang{UNLINK} $name?"
      });
    }
    my $reg_button = $html->button($name, $link, {
      class    => "btn btn-block btn-social btn-$lc_name",
      ADD_ICON => 'fab fa-' . $lc_name,
      %{$attr ? $attr : {}}
    });

    $html->element('div', $reg_button . $unreg_button, { class => 'btn-group', OUTPUT2RETURN => 1 });
  };

  if ($conf{AUTH_VK_ID}) {
    $result .= $make_button->('Vk', "external_auth=Vk");
  }

  if ($conf{AUTH_APPLE_ID}) {
    my $client_id = $conf{AUTH_APPLE_ID} || q{};
    my $redirect_uri = $conf{AUTH_APPLE_URL} || q{};
    $redirect_uri =~ s/\%SELF_URL\%/$SELF_URL/g;
    my $session_state = mk_unique_value(36);

    $result .= $make_button->('Apple', '', {
      GLOBAL_URL => "https://appleid.apple.com/auth/authorize?"
        . "&response_type=id_token%20code"
        . "&client_id=$client_id"
        . "&redirect_uri=$redirect_uri"
        . "&scope=name%20email"
        . "&response_mode=form_post"
        . "&state=$session_state"
        . "&nonce=n$session_state"
    });
  }

  if ($conf{AUTH_FACEBOOK_ID}) {
    my $client_id = $conf{AUTH_FACEBOOK_ID} || q{};
    my $redirect_uri = $conf{AUTH_FACEBOOK_URL} || q{};
    $redirect_uri =~ s/\%SELF_URL\%/$SELF_URL/g;
    my $scope = $conf{FACEBOOK_AUTH_SCOPE} || 'public_profile,email,user_birthday,user_likes,user_friends';

    $result .= $make_button->('Facebook', 'external_auth=Facebook', {
      GLOBAL_URL => 'https://www.facebook.com/dialog/oauth?'
        . "client_id=$client_id"
        . '&response_type=code'
        . '&redirect_uri=' . $redirect_uri
        . '&state=facebook'
        . '&scope=' . $scope
    });
  }

  if ($conf{AUTH_GOOGLE_ID}) {
    my $client_id = $conf{AUTH_GOOGLE_ID} || q{};
    my $redirect_uri = $conf{AUTH_GOOGLE_URL} || q{};
    $redirect_uri =~ s/\%SELF_URL\%/$SELF_URL/g;

    $result .= $make_button->('Google', '', {
      GLOBAL_URL => "https://accounts.google.com/o/oauth2/v2/auth?"
        . "&response_type=code"
        . "&client_id=$client_id"
        . "&redirect_uri=$redirect_uri"
        . "&scope=profile"
        . "&access_type=offline"
        . "&state=google"
    });
  }

  if ($conf{AUTH_INSTAGRAM_ID}) {
    my $client_id = $conf{AUTH_INSTAGRAM_ID} || q{};
    my $redirect_uri = $conf{AUTH_INSTAGRAM_URL} || q{};
    $redirect_uri =~ s/\%SELF_URL\%/$SELF_URL/g;

    $result .= $make_button->('Instagram', '', {
      GLOBAL_URL => "https://api.instagram.com/oauth/authorize?"
        . "&response_type=code"
        . "&client_id=$client_id"
        . "&redirect_uri=$redirect_uri"
        . "&state=instagram"
    });
  }

  if ($conf{AUTH_TWITTER_ID}) {
    my $client_id = $conf{AUTH_TWITTER_ID} || q{};
    my $redirect_uri = $conf{AUTH_TWITTER_URL} || q{};
    $redirect_uri =~ s/\%SELF_URL\%/$SELF_URL/g;

    require AXbills::Auth::Twitter;
    AXbills::Auth::Twitter->import();

    my $twitter_params = AXbills::Auth::Twitter::request_tokens({
      conf     => {
        AUTH_TWITTER_ID     => $client_id,
        AUTH_TWITTER_URL    => $redirect_uri,
        AUTH_TWITTER_SECRET => $conf{AUTH_TWITTER_SECRET}
      },
      self_url => $SELF_URL
    });

    $result .= $make_button->('Twitter', '', {
      GLOBAL_URL => $twitter_params->{url}
    });
  }

  return $result;
}

#**********************************************************
=head2 make_sender_subscribe_buttons_block()

=cut
#**********************************************************
sub make_sender_subscribe_buttons_block {
  my $buttons_block = '';

  my $make_subscribe_btn = sub {
    my ($name, $icon_classes, $lang_vars, $attr) = @_;

    my $button_text = (!$attr->{UNSUBSCRIBE}) ? "$lang{SUBSCRIBE_TO} $name" : "$lang{UNSUBSCRIBE_FROM} $name";

    my $icon_html = $html->element('span', '', { class => $icon_classes, OUTPUT2RETURN => 1 });
    my $text = $html->element('strong', $button_text, { class => $attr->{TEXT_CLASS}, OUTPUT2RETURN => 1 });

    my $button = '';
    if ($attr->{HREF}) {
      my $btn_class = $attr->{BUTTON_CLASSES} || ' btn-info ';
      my $same_button = $html->element('a', $icon_html . ' ' . $text, {
        href          => $attr->{HREF},
        class         => "btn form-control $btn_class",
        target        => '_blank',
        OUTPUT2RETURN => 1
      });


      my $qr_icon = $html->element('i', '', { class => 'fa fa-qrcode', OUTPUT2RETURN => 1 });
      my $qr_button = $html->element('a', $qr_icon,
        {
          class => "btn $btn_class border-left-1",
          # QR-Code by link
          onclick => "showImgInModal('$SELF_URL?qrcode=1&qindex=10010&QRCODE_URL=$attr->{HREF}', '$name $lang{QR_CODE}');",
          OUTPUT2RETURN => 1
        }
      );

      $button = $html->element('div',
        "$same_button $qr_button",
        {
          class => 'btn-group w-100',
          OUTPUT2RETURN => 1
        }
      );

    }
    else {
      $button = $html->element('button', $icon_html.' ' . $text, {
        class         => 'btn form-control ' . ($attr->{BUTTON_CLASSES} || ' btn-info '),
        OUTPUT2RETURN => 1
      });
    }

    my $lang_text = '';
    if ($lang_vars && ref $lang_vars eq 'HASH') {
      $lang_text = join "; \n", map {
        qq{window['$_'] = '$lang_vars->{$_}'};
      } keys %{$lang_vars};
    }

    my $lang_script = ($lang_text) ? $html->element('script', $lang_text) : '';

    $button . $lang_script;
  };

  if ($conf{PUSH_ENABLED} && $conf{PUSH_USER_PORTAL}) {
    $buttons_block .= $make_subscribe_btn->(
      'Push',
      'js-push-icon fa fa-bell',
      {
        ENABLE_PUSH           => $lang{ENABLE_PUSH},
        DISABLE_PUSH          => $lang{DISABLE_PUSH},
        PUSH_IS_NOT_SUPPORTED => $lang{PUSH_IS_NOT_SUPPORTED},
        PUSH_IS_DISABLED      => $lang{PUSH_IS_DISABLED},
      },
      {
        BUTTON_CLASSES => 'js-push-button btn-info',
        TEXT_CLASS     => 'js-push-text'
      }
    );
    # Unsubscribe is made via Javascript
  }
  if ($conf{TELEGRAM_TOKEN}) {
    # Check if subscribed
    require Contacts;
    Contacts->import();
    my $Contacts = Contacts->new($db, $admin, \%conf);
    my $list = $Contacts->contacts_list({
      TYPE  => 6,
      VALUE => '_SHOW',
      UID   => $user->{UID}
    });

    $user->{TELEGRAM} //= $list->[0]->{value};

    my $subscribed = (defined $user->{TELEGRAM} && $user->{TELEGRAM});

    if (!$subscribed) {
      # To build a subscribe link, should get bot name
      if (!$conf{TELEGRAM_BOT_NAME}) {
        require AXbills::Sender::Telegram;
        AXbills::Sender::Telegram->import();
        my $Telegram = AXbills::Sender::Telegram->new(\%conf);
        $conf{TELEGRAM_BOT_NAME} = $Telegram->get_bot_name(\%conf, $db);
      }

      if ($conf{TELEGRAM_BOT_NAME}) {
        my $link_url = 'https://t.me/' . $conf{TELEGRAM_BOT_NAME} . '?start=u_' . ($user->{SID} || $sid);
        $buttons_block .= $make_subscribe_btn->(
          'Telegram',
          'fab fa-telegram',
          undef,
          {
            HREF => $link_url
          }
        );
      }
    }
    else {
      $buttons_block .= $make_subscribe_btn->(
        'Telegram',
        'fa fa-bell-slash',
        undef,
        {
          HREF           => '/?index=10&change=1&REMOVE_SUBSCRIBE=Telegram',
          UNSUBSCRIBE    => 1,
          BUTTON_CLASSES => 'btn-success'
        }
      );
    }
  }
  if($conf{VIBER_TOKEN} && $conf{VIBER_BOT_NAME}){
    # Check if subscribed
    require Contacts;
    Contacts->import();
    my $Contacts = Contacts->new($db, $admin, \%conf);
    my $list = $Contacts->contacts_list({
      TYPE  => 5,
      VALUE => '_SHOW',
      UID   => $user->{UID}
    });

    $user->{VIBER} //= $list->[0]->{value};

    my $subscribed = (defined $user->{VIBER} && $user->{VIBER});
    if (!$subscribed) {
      if ($conf{VIBER_BOT_NAME}) {
        my $link_url = 'viber://pa?chatURI=' . $conf{VIBER_BOT_NAME} . '&context=u_' . ($user->{SID} || $sid).'&text=/start';
        $buttons_block .= $make_subscribe_btn->(
          'Viber',
          'fa fa-phone',
          undef,
          {
            HREF => $link_url
          }
        );
      }
    }    else {
      $buttons_block .= $make_subscribe_btn->(
        'Viber',
        'fa fa-phone',
        undef,
        {
          HREF           => '/?index=10&change=1&REMOVE_SUBSCRIBE=Viber',
          UNSUBSCRIBE    => 1,
          BUTTON_CLASSES => 'btn-success'
        }
      );
    }
  }
  return $buttons_block;
}

#**********************************************************
=head2 language_select()

=cut
#**********************************************************
sub language_select {
  my ($lang_name) = @_;

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

  my %QT_LANG = (
    byelorussian => 22,
    bulgarian    => 20,
    english      => 31,
    french       => 37,
    polish       => 90,
    russian      => 96,
    ukrainian    => 129,
  );

  return $html->form_select(
    $lang_name,
    {
      SELECTED     => $html->{language},
      SEL_HASH     => \%LANG,
      NO_ID        => 1,
      NORMAL_WIDTH => 1,
      EXT_PARAMS   => { qt_locale => \%QT_LANG }
    }
  );

}

#**********************************************************
=head2 form_company_list
    Show all company users, and all of this users services.

    Arguments:
      nothing

    Returns:
      print table.
=cut
#**********************************************************
sub form_company_list {

  require Control::Services;
  my $sum_total = 0;
  my $total     = 0;

  delete $user->{errno};

  my $users_list = $user->list({
    COMPANY_ID => $user->{COMPANY_ID},
    REDUCTION  => '_SHOW',
    COLS_NAME  => 1,
    COLS_UPPER => 1,
  });

  my $table = $html->table({
    width       => '100%',
    title_plain => [ $lang{USER}, $lang{SERVICE}, $lang{DESCRIBE}, $lang{SUM}, $lang{STATUS} ]
  });

  my $statuses = sel_status({ HASH_RESULT => 1 });
  my $sum_for_pay = 0;

  foreach my $line (@$users_list) {
    my $service_info = get_services({
      UID          => $line->{UID},
      REDUCTION    => $line->{REDUCTION},
      PAYMENT_TYPE => 0
    });

    foreach my $service ( @{ $service_info->{list} } ) {
      my ($status_name, $color_status) = split(/:/, $statuses->{$service->{STATUS}});
      $table->addrow($line->{LOGIN},
        $service->{SERVICE_NAME},
        $service->{SERVICE_DESC},
        sprintf("%.2f", $service->{SUM}),
        $html->color_mark($status_name, $color_status)
      );
      $sum_total += $service->{SUM};
      $total++;
      if ($service->{STATUS} eq '5') {
        $sum_for_pay += $service->{SUM};
      }
    }
  }

  if (defined($user->{DEPOSIT}) && $user->{DEPOSIT} != 0) {
    $sum_for_pay = $sum_for_pay - $user->{DEPOSIT};
  }

  $table->table_summary(
    $html->tpl_show(templates('form_table_summary'), {
      TOTAL => $total,
      SUM   => sprintf("%.2f", $sum_total),
    },
    { OUTPUT2RETURN => 1 })
  );

  if ($sum_for_pay > 0) {
    $html->message('warn', $lang{WARNING}, "$lang{ACTIVATION_PAYMENT}" . sprintf("%.2f", $sum_for_pay) . ".");
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 chang_pi_popup()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub change_pi_popup {

  my @check_fields = split(/,[\r\n\s]?/, $conf{CHECK_CHANGE_PI});
  my @all_fields = ('FIO', 'PHONE', 'ADDRESS', 'EMAIL', 'CELL_PHONE');

  $user->{PINFO} = 0; # param wich show modal window
  $user->{ACTION} = 'change';
  $user->{LNG_ACTION} = $lang{CHANGE};

  if ($conf{info_fields_new}) {
    require Info_fields;
    require Control::Users_mng;
    my $Info_fields = Info_fields->new($db, $admin, \%conf);
    my $info_fields_list = $Info_fields->fields_list({
      COMPANY     => 0,
      USER_CHG    => 1,
      ABON_PORTAL => 1
    });

    foreach my $info_field (@$info_fields_list) {
      if (($user->{uc($info_field->{SQL_FIELD})} eq ''
        || $user->{uc($info_field->{SQL_FIELD})} eq '0000-00-00'
        || $user->{uc($info_field->{SQL_FIELD})} eq 0)
        && in_array(uc($info_field->{SQL_FIELD}), \@check_fields)) {

        $user->{INFO_FIELDS_POPUP} .= form_info_field_tpl({
          VALUES                => $user,
          CALLED_FROM_CLIENT_UI => 1,
          COLS_LEFT             => 'col-md-3',
          COLS_RIGHT            => 'col-md-12',
          POPUP                 => { $info_field->{SQL_FIELD} => 1 }
        });
        $user->{PINFO} = 1;
      }
    }
  }

  foreach my $field (@all_fields) {
    if ($field eq 'ADDRESS' && (!(in_array('ADDRESS',
      \@check_fields)) || $user->{ADDRESS_STREET} && $user->{ADDRESS_BUILD})) {
      $user->{ADDRESS_SEL} = '';
      next;
    }

    $user->{PHONE} = '' if $field eq 'PHONE' && $user->{PHONE} && $user->{PHONE} eq $user->{CELL_PHONE};
    if (!$user->{$field} && in_array($field, \@check_fields)) {
      $user->{ $field . "_HAS_ERROR" } = 'has-error';
      $user->{PINFO} = 1;
    }
    else {
      $user->{ $field . "_DISABLE" } = 'disabled';
      $user->{ $field . "_HIDDEN" } = 'hidden';
    }
  }

  return $html->tpl_show(templates('form_chg_client_info'), $user, { OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });
}

#**********************************************************
=head2 form_credit()


=cut
#**********************************************************
sub form_credit {

  require Control::Service_control;
  my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

  my $credit_info = $Service_control->user_set_credit({ UID => $user->{UID}, REDUCTION => $user->{REDUCTION}, %FORM });

  if ($credit_info->{error}) {
    if ($credit_info->{errstr} eq 'ERR_CREDIT_CHANGE_LIMIT_REACH' && $credit_info->{MONTH_CHANGES}) {
      $user->{CREDIT_CHG_BUTTON} = $html->color_mark(
        "$lang{ERR_CREDIT_CHANGE_LIMIT_REACH}. " . "$lang{TOTAL}: $admin->{TOTAL}/$credit_info->{MONTH_CHANGES}",
        'bg-danger',
        {
          ID => "credit-button"
        }
      );
    }
    else {
      $html->message('err', $lang{ERROR}, _translate($credit_info->{errstr}), { ID => $credit_info->{error} });
    }
  }

  if( $credit_info->{CREDIT_RULES} ) {
    my $table = $html->table({
      width       => '100%',
      caption     => $lang{SETTING_CREDIT},
      title_plain => [ $lang{DAYS}, $lang{PRICE}, '-' ],
      ID          => 'CREDIT_FORM',
      HIDE_TABLE  => 1
    });

    for (my $i = 0; $i <= $#{$credit_info->{CREDIT_RULES}}; $i++) {
      my (undef, $days, $price, undef, undef) = split(/:/, $credit_info->{CREDIT_RULES}[$i]);
      $table->addrow($days, sprintf("%.2f", $price),
        $html->button("$lang{SET} $lang{CREDIT}", '#', {
          ex_params => "name='hold_up_window' data-toggle='modal' data-target='#changeCreditModal'
              onClick=\"document.getElementById('change_credit').value='1'; document.getElementById('CREDIT_RULE').value='$i'; document.getElementById('CREDIT_CHG_PRICE').textContent='" . sprintf("%.2f", $price || 0) . "'\"",
          class     => 'btn btn-xs btn-success',
          SKIP_HREF => 1
        })
      );
    }

    $table->show();
  }
  elsif (!$credit_info->{errstr} && !$FORM{change_credit}) {
    %{$user} = (%{$user}, %{$credit_info});
    $user->{CREDIT_CHG_BUTTON} = $html->button("$lang{SET} $lang{CREDIT}", '#', {
      ex_params => "name='hold_up_window' data-toggle='modal' data-target='#changeCreditModal'",
      class     => 'btn btn-success btn-lg',
      SKIP_HREF => 1,
      ID        => "credit-button"
    });
  }


  return 1;
}

#**********************************************************
=head2 _login_send_pin()

=cut
#**********************************************************
sub _login_send_pin() {

  return if !$FORM{PHONE} || $FORM{PIN_CODE};

  my $params = ();

  require Contacts;
  my $Contacts = Contacts->new($db, $admin, \%conf);
  my $contacts = $Contacts->contacts_list({ VALUE => "$FORM{PHONE},+$FORM{PHONE}", UID => '_SHOW' });

  foreach my $contact (@{$contacts}) {
    $user->info($contact->{uid});
    last if $user->{UID};
  }

  if ($Contacts->{TOTAL} < 1 || !in_array('Sms', \@MODULES) || !$user->{UID}) {
    $params->{message} = $lang{USER_NOT_FOUND};
    print "Content-Type: application/json\n\n";
    print json_former($params);
    exit;
  }

  if ($FORM{PIN_ALREADY_EXIST}) {
    my $pin_info = $user->phone_pin_info($user->{UID});

    if ($user->{TOTAL} != 1) {
      $params->{message} = $lang{CODE_EXPIRED};
    }
    else {
      $params->{uid} = $user->{UID};
    }

    print "Content-Type: application/json\n\n";
    print json_former($params);
    exit;
  }

  load_module('Sms', $html);
  my $pin_code = pin_code_generate();
  my $message = $html->tpl_show(_include('sms_login_by_phone', 'Sms'), {
    LOGIN    => $user->{LOGIN},
    PHONE    => $FORM{PHONE},
    PIN_CODE => $pin_code
  }, { OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });

  if ($conf{SMS_LIMIT}) {
    require Sms;
    Sms->import();
    my $Sms = Sms->new($db, $admin, \%conf);
    $Sms->list({
      UID      => $user->{UID},
      INTERVAL => "$DATE/$DATE",
      NO_SKIP  => 1,
    });

    if ($Sms->{TOTAL} && $Sms->{TOTAL} >= $conf{SMS_LIMIT}) {
      $params->{message} = $lang{EXCEEDED_SMS_LIMIT};
      print "Content-Type: application/json\n\n";
      print json_former($params);
      exit;
    }
  }

  my $sms_sent = sms_send({
    NUMBER  => $FORM{PHONE},
    MESSAGE => $message,
    UID     => $user->{UID}
  });

  if ($sms_sent) {
    $params->{uid} = $user->{UID};
    $user->phone_pin_add({ UID => $user->{UID}, PIN_CODE => $pin_code });
  }

  print "Content-Type: application/json\n\n";
  print json_former($params);
  exit;
}

#**********************************************************
=head2 _login_confirm_pin()

=cut
#**********************************************************
sub _login_confirm_pin {

  return if !$FORM{PIN_CODE} || !$FORM{UID} || !$FORM{PHONE};

  my $params = ();
  my $pin_info = $user->phone_pin_info($FORM{UID});

  if ($user->{TOTAL} != 1) {
    $params->{message} = $lang{CODE_EXPIRED};
  }
  elsif ($pin_info->{ATTEMPTS} > 4) {
    $user->phone_pin_del($FORM{UID});
    $params->{message} = $lang{USED_ALL_PIN_ATTEMPTS};
  }
  elsif ($pin_info->{PIN_CODE} ne $FORM{PIN_CODE}) {
    $user->phone_pin_update_attempts($FORM{UID});
    $params->{message} = $lang{CODE_IS_INVALID};
  }
  else {
    $user->phone_pin_del($FORM{UID});
    require Contacts;
    my $Contacts = Contacts->new($db, $admin, \%conf);
    my $contacts = $Contacts->contacts_list({ VALUE => "$FORM{PHONE},+$FORM{PHONE}", UID => '_SHOW' });
    $params->{buttons} = [];
    foreach my $contact (@{$contacts}) {
      $user->info($contact->{uid}, { SHOW_PASSWORD => 1 });
      my ($uid, $sid, undef) = auth_user($user->{LOGIN}, $user->{PASSWORD}, '');

      push @{$params->{users}}, { url => "/index.cgi?sid=$sid", login => $user->{LOGIN} } if $sid;
    }
  }

  print "Content-Type: application/json\n\n";
  print json_former($params);
  exit;
}

#**********************************************************
=head2 pin_code_generate()

=cut
#**********************************************************
sub pin_code_generate {
  my @alphanumeric = (0 .. 9);

  return join '', map $alphanumeric[rand @alphanumeric], 0 .. 4;
}


#**********************************************************
=head2 func_menu($f_args) - Functions menu

  Arguments:
    $f_args  -
    SILENT   -

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub func_menu {
  my ($f_args) = @_;
  if ($FORM{subf}) {
    if($index eq $FORM{subf}) {
      return 0;
    }
    if (defined($module{$FORM{subf}})) {
      load_module($module{$FORM{subf}}, $html);
    }
    _function($FORM{subf}, $f_args->{f_args});
  }

  return 1;
}


#**********************************************************
=head2 form_company_info - show info about company.

    Arguments:

    Returns:
      print table.
=cut
#**********************************************************
sub form_company_info {
  
  require Companies;
  Companies->import();
  my $Company = Companies->new($db, $admin, \%conf);

  my $company_info = $Company->list({
    COMPANY_ID       => $user->{COMPANY_ID},
    COMPANY_NAME     => '_SHOW',
    ADDRESS          => '_SHOW',
    USERS_COUNT      => '_SHOW',
    DEPOSIT          => '_SHOW',
    REGISTRATION     => '_SHOW',
    CONTRACT_ID      => '_SHOW',
    CONTRACT_DATE    => '_SHOW',
    TAX_NUMBER       => '_SHOW',
    BANK_ACCOUNT     => '_SHOW',
    BANK_NAME        => '_SHOW',
    COR_BANK_ACCOUNT => '_SHOW',
    BANK_BIC         => '_SHOW',
    EDRPOU           => '_SHOW',
    PHONE            => '_SHOW',
    VAT              => '_SHOW',
    REPRESENTATIVE   => '_SHOW',
    REPRESENTATIVE   => '_SHOW',
    CREDIT           => '_SHOW',
    CREDIT_DATE      => '_SHOW',
    COLS_NAME        =>  1
  });

  return if (!$company_info);

  my $money_unit_names = '';
  if ($conf{MONEY_UNIT_NAMES}) {
    $money_unit_names=(split(/;/, $conf{MONEY_UNIT_NAMES}))[0];
  }

  $html->tpl_show(templates('form_client_company_info'), {
    COMPANY_NAME    => $company_info->[0]->{name},
    ADDRESS         => $company_info->[0]->{address},
    USERS_COUNT     => $company_info->[0]->{users_count},
    DEPOSIT         => sprintf('%.2f',$company_info->[0]->{deposit})." $money_unit_names",
    REGISTRATION    => $company_info->[0]->{registration} || '',
    CONTRACT_ID     => $company_info->[0]->{contract_id} || '',
    CONTRACT_DATE   => $company_info->[0]->{contract_date} || '',
    TAX_NUMBER      => $company_info->[0]->{tax_number} || '',
    COR_BANK_ACCOUNT=> $company_info->[0]->{cor_bank_account} || '',
    BANK_ACCOUNT    => $company_info->[0]->{bank_account} || '',
    BANK_NAME       => $company_info->[0]->{bank_name} || '',
    VAT             => $company_info->[0]->{vat} || '',
    PHONE           => $company_info->[0]->{phone} || '',
    BANK_BIC        => $company_info->[0]->{bank_bic} || '',
    EDRPOU          => $company_info->[0]->{edrpou},
    REPRESENTATIVE  => $company_info->[0]->{representative},
    CREDIT          => ($company_info->[0]->{credit}) ? "$company_info->[0]->{credit} $money_unit_names $lang{TO} $company_info->[0]->{credit_date}" : '',
  });

  return 1;
}

1
