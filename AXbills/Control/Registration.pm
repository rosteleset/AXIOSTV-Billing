=head1 NAME

   Old Registration logic

=cut


use strict;
use warnings FATAL => 'all';
no warnings 'layer';

use AXbills::Base qw(sendmail in_array load_pmodule);
use AXbills::Fetcher qw(web_request);

our (
  %OUTPUT,
  @REGISTRATION,
  %lang,
  %LANG,
  $base_dir,
  $CONTENT_LANGUAGE,
  $admin,
  $db,
  %conf,
  $sid,
  $users,
);

our AXbills::HTML $html;

require AXbills::Templates;
require AXbills::Misc;
require Control::Address_mng;

my $CAPTCHA_DIR = $base_dir . 'cgi-bin/captcha/';
my %INFO_HASH = ();

#**********************************************************
=head2 _start()

=cut
#**********************************************************
sub _start {
  $INFO_HASH{SEL_LANGUAGE} = $html->form_select('language', {
    EX_PARAMS => 'onChange="selectLanguage()"',
    SELECTED  => $html->{language},
    SEL_HASH  => \%LANG,
    NO_ID     => 1
  });

  get_sn_info() if ($FORM{external_auth});

  $INFO_HASH{CHECKED_ADDRESS_MESSAGE} = get_address_connected_message() if ($FORM{check_address});

  if ($conf{REGISTRATION_VERIFY_PHONE}) {
    $html->tpl_show(templates('modal_form'));
    if ($FORM{PHONE} && $FORM{PIN}) {
      verify_phone($FORM{PHONE}, $FORM{PIN});
    }
    elsif ($FORM{reg} || $FORM{add}) {
      $html->message('err', $lang{REG_PHONE});
      delete $FORM{reg};
      delete $FORM{add};
    }
  }

  if ($conf{FB_REGISTRATION} && !$FORM{LOCATION_ID}) {
    my $log_url = "external_auth=Facebook";
    $log_url .= "&module=$FORM{module}" if ($FORM{module});
    $log_url .= "&user_registration=1" if ($FORM{user_registration});
    $INFO_HASH{FB_INFO} = $html->button("<i class='fab fa-facebook'></i>Facebook", $log_url, { class => 'btn btn-social btn-facebook' });
    $INFO_HASH{FB_INFO_BLOCK} = $html->button("Facebook", $log_url, { class => 'btn btn-primary btn-block' });
  }

  my %lang_module = (
    Employees => $lang{JOBS},
    Internet  => $lang{INTERNET},
    Iptv      => $lang{IPTV},
    Msgs      => $lang{APPLICATIONS},
    Crm       => $lang{LEAD},
    Multidoms => $lang{REGISTRATION}
  );

  my $choose_module_buttons = '';

  # Check modules for registration are enabled
  if (@REGISTRATION) {
    @REGISTRATION = grep {in_array($_, \@MODULES)} @REGISTRATION;
  }

  if ($FORM{send_pin}) {
    send_pin();
  }
  elsif ($FORM{FORGOT_PASSWD} || $FORM{CHANGE_PASSWORD}) {
    if ($conf{PASSWORD_RECOVERY}) {
      password_recovery();
    }
    else {
      print "Content-Type: text/html\n\n";
      print "Unknown operation";
      exit 1;
    }
  }
  elsif (!@REGISTRATION) {
    print "Content-Type: text/html\n\n";
    print "Can't find modules services for registration";
    exit;
  }
  elsif ($FORM{get_index} && $FORM{get_index} eq 'form_address_select2') {
    print "Content-Type: text/html\n\n";
    form_address_select2(\%FORM);
    exit 1;
  }
  elsif (!$FORM{no_addr}
    && !$FORM{reg}
    && !$FORM{add}
    && !$FORM{LOCATION_ID}
    && $conf{REGISTRATION_REQUEST}
    && (in_array('Internet', \@MODULES) || in_array('Iptv', \@MODULES))) {
    my $address_buttons .= "<button type='button' class='btn btn-lg btn-success' data-toggle='modal' data-target='#checkAddress'>" . $lang{CHECK_ADDRESS} . "</button>";
    $html->{HEADER_ROW} = $html->element('div', $address_buttons, { class => 'row' });
  }
  elsif ($#REGISTRATION > -1) {
    @REGISTRATION = ('Msgs') if ($FORM{no_addr} && $conf{REGISTRATION_REQUEST});
    @REGISTRATION = ('Internet') if ($FORM{LOCATION_ID} && $conf{REGISTRATION_REQUEST} && in_array('Internet', \@MODULES));
    @REGISTRATION = ('Iptv') if ($FORM{LOCATION_ID} && $conf{REGISTRATION_REQUEST} && in_array('Iptv', \@MODULES));
    my $m = ($FORM{module} && $FORM{module} =~ /^[a-z\_0-9]+$/i && in_array($FORM{module}, \@MODULES))
      ? $FORM{module}
      : $REGISTRATION[0];

    if ($m eq 'Osbb' || $m eq 'Expert') {
      $INFO_HASH{user_registration} = $FORM{user_registration} || '';
    }
    else {
      $choose_module_buttons = "<nav class='mt-2'><ul class='nav nav-pills nav-sidebar flex-column nav-child-indent' data-card-widget='tree'>";
      if (defined $#REGISTRATION > 0 && !$FORM{registration}) {
        foreach my $registration_module (@REGISTRATION) {
          my $active = $FORM{module} && $FORM{module} eq $registration_module ? 'active' : '';
          $choose_module_buttons .= "<li class='nav-item'><a class='nav-link $active' href='?module=$registration_module'><p>" .
            ($lang_module{ $registration_module } || $registration_module) . "</p></a></li>"
        }
      }
      if (!$FORM{LOCATION_ID} && !$FORM{no_addr} && $conf{CHECK_ADDRESS_REGISTRATION}) {
        $choose_module_buttons .= "<li class='nav-item'><a data-toggle='modal' class='nav-link' data-target='#checkAddress'><p>" . $lang{CHECK_ADDRESS} . "</p></a></li>";
      }
      $choose_module_buttons .= "</ul></nav>";
    }

    $INFO_HASH{CAPTCHA} = get_captcha();

    $INFO_HASH{RULES} = $html->tpl_show(templates('form_accept_rules'), {}, { OUTPUT2RETURN => 1 });
    $INFO_HASH{language} = $html->{language};

    if (!$FORM{DOMAIN_ID}) {
      $FORM{DOMAIN_ID} = 0;
      $INFO_HASH{DOMAIN_ID} = 0;
    }

    if ($conf{REGISTRATION_CAPTCHA} && ($FORM{reg} || $FORM{add})) {
      unless (check_captcha(\%FORM)) {
        delete $FORM{reg};
        delete $FORM{add};
      }
    }

    _module_registration($m);
  }

  $admin->{SETTINGS}->{SKIN} = 'navbar-light navbar-orange';
  $admin->{SETTINGS}->{FIXED_LAYOUT} = '';
  $admin->{MENU_HIDDEN} = '';
  $admin->{RIGHT_MENU_OPEN} = '';

  if (!($FORM{header} && $FORM{header} == 2)) {
    print $html->header();

    my $address_modal_form = '';

    unless ($FORM{FORGOT_PASSWD}) {
      $address_modal_form = form_address_select2({
        REGISTRATION_MODAL => 1,
        DISTRICT_SELECT_ID => 'REG_DISTRICT_ID',
        STREET_SELECT_ID   => 'REG_STREET_ID',
        BUILD_SELECT_ID    => 'REG_BUILD_ID',
      });
    }

    $OUTPUT{HTML_STYLE} = 'default';
    $OUTPUT{CONTENT_LANGUAGE} = lc $CONTENT_LANGUAGE;
    $OUTPUT{INDEX_NAME} = 'registration.cgi';
    $OUTPUT{CHECK_ADDRESS_MODAL} = $html->tpl_show(templates('form_address_modal'), { ADDRESS => $address_modal_form }, { OUTPUT2RETURN => 1 });
    $OUTPUT{TITLE} = "$conf{WEB_TITLE} - $lang{REGISTRATION}";
    $OUTPUT{SELECT_LANGUAGE} = $INFO_HASH{SEL_LANGUAGE};
    $OUTPUT{REG_LOGIN} = "style='display:none !important;'";
    $OUTPUT{REG_STATE} = "style='display:none !important;'";
    $OUTPUT{REG_IP} = "style='display:none;'";
    $OUTPUT{DATE} = $DATE;
    $OUTPUT{TIME} = $TIME;
    $OUTPUT{IP} = $ENV{'REMOTE_ADDR'};
    $OUTPUT{BODY} = $html->{OUTPUT};
    $html->{OUTPUT} = '';
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
    $OUTPUT{MENU} = $choose_module_buttons;
    $OUTPUT{BODY} = $html->tpl_show(templates('form_client_main'), \%OUTPUT);
    $OUTPUT{DOMAIN_ID} = $FORM{DOMAIN_ID} || q{};


    if ($conf{user_background}) {
      $OUTPUT{BACKGROUND_COLOR} = $conf{user_background};
    }
    elsif ($conf{user_background_url}) {
      $OUTPUT{BACKGROUND_URL} = $conf{user_background_url};
    }

    print $html->tpl_show(templates('registration'), { %OUTPUT, TITLE_TEXT => $lang{REGISTRATION} });
    print $html->tpl_show(templates('form_client_start'), { %OUTPUT });
  }
  else {
    print "Content-Type: text/html\n\n";
    print $html->{OUTPUT};
  }
}

#**********************************************************
=head2 _module_registration()

=cut
#**********************************************************
sub _module_registration {
  my $m = shift;

  load_module($m, $html);

  $m = lc($m);

  my $function = $m . '_registration';

  if (defined(&$function)) {
    my $return = &{ \&{$function} }(\%INFO_HASH);

    # Send E-mail to admin after registration
    if ($return && $return > 1) {
      my $message = $html->tpl_show(templates('registration_admin_notification'),
        {
          LOGIN       => $FORM{LOGIN},
          FIO         => $FORM{FIO},
          DATE        => $DATE,
          TIME        => $TIME,
          REMOTE_ADDR => $ENV{REMOTE_ADDR},
          MODULE      => $m,
          PHONE       => $FORM{PHONE},
          EMAIL       => $FORM{EMAIL},
          UID         => '--',
          COMMENT     => $FORM{COMMENTS},
          TIME_CONECT => $FORM{CONNECTION_TIME},
        },
        { OUTPUT2RETURN => 1});

      if(! sendmail(
        $conf{ADMIN_MAIL},
        $conf{ADMIN_MAIL},
        'New registration request',
        $message,
        $conf{MAIL_CHARSET},
        ''
      )) {
        $html->message('err', $lang{@REGISTRATION}, 'Request sending error');
      }

      if ($conf{REGISTRATION_REDIRECT}) {
        $html->redirect($conf{REGISTRATION_REDIRECT}, { MESSAGE => $lang{SENDED} });
        exit 0;
      }
    }
  }
  else {
    $html->message('err', $FORM{module}, 'No registration for module');
  }
}

#**********************************************************
=head2 password_recovery() - Password recovery

=cut
#**********************************************************
sub password_recovery {

  if ($FORM{SEND} && (!$conf{REGISTRATION_CAPTCHA} || check_captcha(\%FORM))) {
    password_recovery_process();
  }

  if ($conf{PASSWORD_RECOVERY_URL}) {
    if ($FORM{CHANGE_PASSWORD}) {
      password_change_process();
    }

    if ($FORM{CODE}) {
      my $hidden_input = $html->form_input('CODE', $FORM{CODE}, { TYPE => 'hidden', OUTPUT2RETURN => 1 });
      $html->tpl_show(templates('form_password'), {
        G2FA_HIDDEN   => 'hidden',
        LNG_ACTION    => $lang{CHANGE},
        ACTION        => 'CHANGE_PASSWORD',
        PW_CHARS      => $conf{PASSWD_SYMBOLS} || "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ",
        PW_LENGTH     => $conf{PASSWD_LENGTH} || 6,
        HIDDDEN_INPUT => $hidden_input
      });

      return 1;
    }
  }

  my %info = ();
  if (in_array('Sms', \@MODULES)) {
    $info{EXTRA_PARAMS} = $html->tpl_show(_include('sms_check_form', 'Sms'), undef, { OUTPUT2RETURN => 1 });
  }

  $info{CAPTCHA} = get_captcha();

  $html->tpl_show(templates('form_forgot_passwd'), { %FORM, %info });

  return 1;
}

#**********************************************************
=head2 password_recovery_process()

=cut
#**********************************************************
sub password_recovery_process {

  require Control::Registration_mng;
  Control::Registration_mng->import();

  my $Registration_mng = Control::Registration_mng->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang, is_portal => 1 });
  my $result = $Registration_mng->password_recovery(\%FORM);

  if ($result->{result}) {
    $html->message('info', $lang{INFO}, $lang{CHANGED});
    $html->redirect('/index.cgi', { WAIT => 3 });
  }
  else {
    my $error = $result->{errno} || 999999;
    my $message_err = $result->{errstr_lng} || "$lang{UNKNOWN} $lang{ERROR}";
    $html->message('err', $lang{ERROR}, $message_err, { ID => $error });
  }

  return 1;
}

#**********************************************************
=head2 password_change_process()

=cut
#**********************************************************
sub password_change_process {

  require Control::Registration_mng;
  Control::Registration_mng->import();

  $FORM{PASSWORD} = $FORM{newpassword} if ($FORM{newpassword});
  my $Registration_mng = Control::Registration_mng->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang, is_portal => 1 });
  my $result = $Registration_mng->password_reset(\%FORM);

  if ($result->{result}) {
    $html->message('info', $lang{INFO}, $lang{CHANGED});
  }
  else {
    my $error = $result->{errno} || 999999;
    my $message_err = $result->{errstr_lng} || "$lang{UNKNOWN} $lang{ERROR}";
    $html->message('err', $lang{ERROR}, "$lang{UNKNOWN} $lang{ERROR}", { ID => $result->{errno} });
    $html->message('err', $lang{ERROR}, $message_err, { ID => $error });
  }

  return 1;
}

#**********************************************************
=head2 get_address_connected_message()

=cut
#**********************************************************
sub get_address_connected_message {

  require Control::Address_mng;
  require Address;
  my $Address = Address->new($db, $admin, \%conf);

  my $info = $Address->build_info({ ID => $FORM{LOCATION_ID} });

  return ($info->{PLANNED_TO_CONNECT} && $info->{PLANNED_TO_CONNECT} == 1)
    ? "<div class='callout callout-info'>$lang{CHECK_ADDRESS_PLANNED_TO_CONNECT_MSG}</div>"
    : "<div class='callout callout-info'>$lang{CHECK_ADDRESS_CONNECTED_MSG}</div>";
}

#**********************************************************
=head2 get_captcha()

=cut
#**********************************************************
sub get_captcha {

  return if (!$conf{REGISTRATION_CAPTCHA});
  if ($conf{GOOGLE_CAPTCHA_KEY}) {
    return "<script src='https://www.google.com/recaptcha/api.js'></script><div class='g-recaptcha' data-sitekey='$conf{GOOGLE_CAPTCHA_KEY}'></div>";
  }

  my $captcha_module_load_error = load_pmodule('Authen::Captcha', { RETURN => 1, HEADER => 1 });

  if ($captcha_module_load_error) {
    print "Content-Type: text/html\n\n";
    print $captcha_module_load_error;
  };

  my $Captcha = Authen::Captcha->new(
    data_folder   => $CAPTCHA_DIR,
    output_folder => $CAPTCHA_DIR,
  );

  if (!(-d $CAPTCHA_DIR || mkdir($CAPTCHA_DIR))) {
    $html->message('err', $lang{ERROR}, "$lang{ERR_CANT_CREATE_FILE} '$CAPTCHA_DIR' $lang{ERROR}: $!\n");
    $html->message('info', $lang{INFO}, "$lang{NOT_EXIST} '$CAPTCHA_DIR'");
    return '';
  }
  else {
    my $number_of_characters = 5;
    my $md5sum = eval {return $Captcha->generate_code($number_of_characters)};

    if (!$md5sum) {
      print "Content-Type: text/html\n\n";
      print "Can't make captcha\n";
      print $@;
      exit;
    }

    $INFO_HASH{CAPTCHA} = $html->tpl_show(templates('form_captcha'), { MD5SUM => $md5sum }, { OUTPUT2RETURN => 1 });
  }

  return $INFO_HASH{CAPTCHA};
}

#**********************************************************
=head2 check_captcha($user_input, $md5hash)

  Arguments:
    $attr
      $user_input
      $md5hash

  Returns:
    boolean

=cut
#**********************************************************
sub check_captcha {
  my ($attr) = @_;

  if ($conf{GOOGLE_CAPTCHA_KEY}) {
    my $response = $attr->{'g-recaptcha-response'} || q{};
    my $url = "https://www.google.com/recaptcha/api/siteverify?secret=$conf{GOOGLE_CAPTCHA_SECRET}&response=$response";
    my $result = web_request($url, {
      JSON_RETURN => 1,
    });

    if ($result && ref $result eq 'HASH' && $result->{success} && $result->{success} ne 'false') {
      return 1;
    }
    $html->message('err', "Captcha: $lang{ERROR}");
    return 0;
  }

  my $user_input = $attr->{CCODE} || q{};
  my $md5hash = $attr->{C} || q{};

  load_pmodule('Authen::Captcha', { HEADER => 1 });

  my $Captcha = Authen::Captcha->new(
    data_folder   => $CAPTCHA_DIR,
    output_folder => $CAPTCHA_DIR,
    debug         => 0
  );

  my $result = $Captcha->check_code($user_input, $md5hash);

  if ($result == 0) {
    $html->message('err', "Captcha: $lang{ERROR}");
    #file error
  }
  elsif ($result == -1) {
    $html->message('err', "Captcha: has been expired");
    #code expired
  }
  elsif ($result == -2) {
    $html->message('err', "Captcha: invalid (-2)");
    #code invalid
  }
  elsif ($result == -3) {
    #code does not match crypt
    $html->message('err', "Captcha: invalid (-3)");
  }

  return $result == 1;
}

#**********************************************************
=head2 get_sn_info()
  Social network info

=cut
#**********************************************************
sub get_sn_info {
  require AXbills::Auth::Core;
  AXbills::Auth::Core->import();

  my $Auth = AXbills::Auth::Core->new({
    CONF      => \%conf,
    AUTH_TYPE => $FORM{external_auth},
    SELF_URL  => $SELF_URL,
  });
  $Auth->check_access(\%FORM);

  if ($Auth->{auth_url}) {
    print "Location: $Auth->{auth_url}\n\n";
    exit;
  }
  elsif ($Auth->{USER_ID}) {
    $users->list({
      $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
      LOGIN                => '_SHOW',
      PASSWORD             => '_SHOW',
      FIO                  => '_SHOW',
      COLS_NAME            => 1
    });

    Encode::_utf8_off($Auth->{USER_NAME});

    if ($users->{TOTAL}) {
      $html->message('warn', "$Auth->{USER_NAME} already registered");
    }
    else {
      $INFO_HASH{FIO} = $Auth->{USER_NAME};
      $INFO_HASH{EMAIL} = $Auth->{EMAIL};
      $INFO_HASH{USER_ID} = $Auth->{USER_ID};
      $INFO_HASH{$Auth->{CHECK_FIELD}} = $Auth->{USER_ID};
      my $login_url = $SELF_URL;
      $login_url =~ s/registration/index/;
      $login_url .= "?external_auth=Facebook";
      $INFO_HASH{login_url} = $login_url;
    }
  }

  return 1;
}

#**********************************************************
=head2 send_pin()

=cut
#**********************************************************
sub send_pin {
  print "Content-Type: text/html\n\n";

  $admin->action_list({
    FROM_DATE      => $DATE,
    TO_DATE        => $DATE,
    TYPE           => 50,
    ACTION         => "*$FORM{send_pin}*",
    SKIP_DEL_CHECK => 1,
  });
  if ($admin->{TOTAL} > 0) {
    $html->message('warn', $lang{MESSAGES});
    exit 0;
  }

  if (in_array('Sms', \@MODULES)) {
    require AXbills::Sender::Core;
    AXbills::Sender::Core->import();

    my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);

    my $pin = int(rand(900)) + 100;
    $Sender->send_message({
      TO_ADDRESS  => $FORM{send_pin},
      MESSAGE     => $pin,
      SENDER_TYPE => 'Sms',
      UID         => $user->{uid}
    });

    $admin->action_add(0, "Send registration pin $pin to phone $FORM{send_pin}", { TYPE => 50 });
  }

  exit 0;
}

#**********************************************************
=head2 verify_phone(phone, pin)

=cut
#**********************************************************
sub verify_phone {
  my ($phone, $pin) = @_;

  $admin->action_list({
    FROM_DATE => $DATE,
    TO_DATE   => $DATE,
    TYPE      => 50,
    ACTIONS   => "Send registration pin $pin to phone $phone",
  });

  if ($admin->{TOTAL} < 1) {
    $html->message('err', "$lang{WRONG} PIN");
    delete $FORM{reg};
    delete $FORM{add};
  }

  return 1;
}

1;
