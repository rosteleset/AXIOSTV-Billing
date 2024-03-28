=head1 NAME


=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(sendmail decode_base64 mk_unique_value in_array check_ip);

require AXbills::Misc;

our(
  $db,
  %conf,
  %lang,
  %err_strs,
  %LANG,
  %permissions,
  %OUTPUT,
  %FORM,
  $index,
  %COOKIES
);

our Admins $admin;
our AXbills::HTML $html;

#**********************************************************
=head2 admin_auth() - Primary auth form

=cut
#**********************************************************
sub auth_admin {
  my $lang_loaded = 0;

  #Cookie auth
  if ($conf{AUTH_METHOD}) {
    if ($index == 10) {
      $admin->online_del({ SID => $COOKIES{admin_sid} });
    }

    load_lang();
    $lang_loaded = 1;

    my $res = check_permissions($FORM{user}, $FORM{passwd}, $COOKIES{admin_sid}, \%FORM);

    if (! $res) {
      if ($FORM{REFERER} && $FORM{REFERER} =~ /$SELF_URL/ && $FORM{REFERER} !~ /index=10/) {
        $html->set_cookies('admin_sid', $admin->{SID}, '', '');
        $COOKIES{admin_sid} = $admin->{SID};
        $admin->online({ SID => $admin->{SID}, TIMEOUT => $conf{web_session_timeout} });
        print "Location: $FORM{REFERER}\n\n";
      }

      #      if ($FORM{API_INFO}) {
      #        require Control::Api;
      #        form_system_info($FORM{API_INFO});
      #        return 0;
      #      }
    }
    else {
      my $cookie_sid = ($COOKIES{admin_sid} || '');
      my $admin_sid = ($admin->{SID} || '');

      if ($FORM{AJAX} || $FORM{json}){
        print "Content-Type:application/json\n\n";

        print qq{{"TYPE":"error","errstr":"Access Deny","sid":"$cookie_sid","aid":"$admin_sid","errno":"$res"}};
      }
      elsif( $FORM{xml}){
        print "Content-Type:application/xml\n\n";
        print qq{<?xml version="1.0" encoding="UTF-8"?>
        <error>
          <TYPE>error</TYPE>
          <errstr>Access Deny</errstr>
          <errno>$res</errno>
          <sid>$cookie_sid</sid>
          <aid>$admin_sid</aid>
        </error>
        };
      }
      else {
        $html->{METATAGS} = templates('metatags');
        print $html->header();
        my $err = '';

        if ( $admin->{errno} ) {
          if ( $admin->{errno} == 4 ) {
            $err = $lang{ERR_WRONG_PASSWD};
          }
          else {
            if ($FORM{user} && $FORM{passwd}) {
              $err = $admin->{errstr};
            }
          }
        }

        form_login({ ERROR => $err });
        print "<!-- Access Deny. Auth cookie: $cookie_sid System: $admin_sid .$res -->";
      }

      if ($ENV{DEBUG}) {
        die();
      }
      else {
        exit 0;
      }
    }
  }

  #**********************************************************
  #IF Mod rewrite enabled Basic Auth
  #
  #    <IfModule mod_rewrite.c>
  #        RewriteEngine on
  #        RewriteCond %{HTTP:Authorization} ^(.*)
  #        RewriteRule ^(.*) - [E=HTTP_CGI_AUTHORIZATION:%1]
  #        Options Indexes ExecCGI SymLinksIfOwnerMatch
  #    </IfModule>
  #    Options Indexes ExecCGI FollowSymLinks
  #
  #**********************************************************
  else {
    if (defined($ENV{HTTP_CGI_AUTHORIZATION})){
      $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
      my ($REMOTE_USER, $REMOTE_PASSWD) = split( /:/, decode_base64( $ENV{HTTP_CGI_AUTHORIZATION} ) );

      if ( $REMOTE_USER ){
        $REMOTE_USER = substr( $REMOTE_USER, 0, 20 );
        $REMOTE_USER =~ s/\\//g;
      }
      else {
        $REMOTE_USER = q{};
      }
      if ($REMOTE_PASSWD) {
        $REMOTE_PASSWD = substr($REMOTE_PASSWD, 0, 20);
        $REMOTE_PASSWD=~s/\\//g;
      }

      my $res = check_permissions($REMOTE_USER, $REMOTE_PASSWD);
      if ($res == 1) {
        print "WWW-Authenticate: Basic realm=\"$conf{WEB_TITLE} Billing System\"\n";
        print "Status: 401 Unauthorized\n";
      }
      elsif ($res == 2) {
        print "WWW-Authenticate: Basic realm=\"Billing system / '$REMOTE_USER' Account Disabled\"\n";
        print "Status: 401 Unauthorized\n";
      }
    }
    else {
      print "'mod_rewrite' not install";
    }

    if ($admin->{errno}) {
      load_lang();
      $html->{METATAGS} = templates('metatags');
      print $html->header();

      my $message = $lang{ERR_ACCESS_DENY};

      if ($admin->{errno} == 2) {
        $message = "$lang{ACCOUNT_DISABLE} $lang{OR} $admin->{errstr}";
      }
      elsif ($admin->{errno} == 3) {
        $message = $lang{ERR_UNALLOW_IP};
      }
      elsif ($admin->{errno} == 4) {
        $message = $lang{ERR_WRONG_PASSWD} || 'ERR_WRONG_PASSWD';
      }
      else {
        $message = $err_strs{ $admin->{errno} };
      }

      print $html->element('div',
        $html->message('err', $lang{ERROR}, $message, { OUTPUT2RETURN => 1 }),
        { class => 'p-5' }
      );
      exit;
    }
  }

  if (!$lang_loaded) {
    load_lang();
  }

  return 1;
}

#**********************************************************
=head3 form_login() - Admin http login page

  Arguments:
    $attr
      ERROR

  Returns:

=cut
#**********************************************************
sub form_login {
  my ($attr) = @_;

  if ($FORM{forgot_passwd} && $conf{ADMIN_PASSWORD_RECOVERY}) {
    if ($FORM{email}) {
      require Digest::SHA;
      Digest::SHA->import('sha256_hex');
      $admin->list({ EMAIL => $FORM{email} });
      if ($admin->{TOTAL} > 0) {
        my $digest = Digest::SHA::sha256_hex("$FORM{email}$DATE 1234567890");
        my $message = "Go to the following link to change your password. \n $SELF_URL?index=10&recovery_passwd=$digest";
        sendmail("$conf{ADMIN_MAIL}", "$FORM{email}", "$PROGRAM Password Repair", "$message", "$conf{MAIL_CHARSET}", "");
        $html->message('info', 'E-mail sended.');
      }
      else {
        $html->message('error', 'Wrong e-mail.');
      }
      exit;
    }
    else {
      $html->tpl_show(templates('form_admin_forgot_passwd'), \%FORM);
      exit;
    }
  }
  elsif ($FORM{recovery_passwd}) {
    require Digest::SHA;
    Digest::SHA->import('sha256_hex');
    my $admins_list = $admin->list({
      EMAIL     => '_SHOW',
      COLS_NAME => 1
    });
    foreach (@$admins_list) {
      my $digest = Digest::SHA::sha256_hex("$_->{email}$DATE 1234567890");
      if ($digest eq $FORM{recovery_passwd}) {
        if ($FORM{newpassword}) {
          my $admin_form = Admins->new($db, \%conf);
          $admin_form->info($_->{aid});
          $admin_form->change({ PASSWORD => $FORM{newpassword}, AID => $_->{aid} });
          if (!$admin_form->{errno}) {
            $html->message('info', $lang{CHANGED}, "$lang{CHANGED} ");
          }
        }
        else {
          my $password_form;
          $password_form->{PW_CHARS}      = $conf{PASSWD_SYMBOLS} || "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ";
          $password_form->{PW_LENGTH}     = $conf{PASSWD_LENGTH}  || 6;
          $password_form->{ACTION}        = 'change';
          $password_form->{LNG_ACTION}    = "$lang{CHANGE}";
          $password_form->{HIDDDEN_INPUT} = $html->form_input('recovery_passwd', $digest, { TYPE => 'hidden', OUTPUT2RETURN => 1 });
          $html->tpl_show(templates('form_password'), $password_form);
        }
        last;
      }
    }
    exit;
  }

  my %first_page = ();

  # if ($conf{tech_works}) {
  #   $html->message( 'info', $lang{INFO}, $conf{tech_works} );
  #   return 0;
  # }

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

  $first_page{SEL_LANGUAGE} = $html->form_select('language', {
    SELECTED   => $html->{language},
    SEL_HASH   => \%LANG,
    NO_ID      => 1,
    EXT_PARAMS => { qt_locale => \%QT_LANG }
  });

  $first_page{TITLE} = $lang{AUTH};

  if (! $FORM{REFERER} && $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER}  =~ /$SELF_URL/) {
    $FORM{REFERER} = $ENV{HTTP_REFERER};
  }

  if($attr->{ERROR}) {
    $first_page{ERROR_MSG} = $html->message( 'danger text-center', $lang{ERROR}, $attr->{ERROR}, {
        OUTPUT2RETURN => 1
      } );
  }

  if ($conf{TECH_WORKS}){
    $first_page{TECH_WORKS_BLOCK_VISIBLE} = 1;
    $first_page{TECH_WORKS_MESSAGE} = $conf{TECH_WORKS};
  }

  if ($conf{ADMIN_PASSWORD_RECOVERY}) {
    $first_page{PSWD_BTN} = $html->button("$lang{FORGOT_PASSWORD}?", "index=10&forgot_passwd=1");
  }

  $first_page{G2FA_hidden} = 'hidden';
  if($FORM{G2FA}){
    $first_page{G2FA_hidden} = '';
    $first_page{password} = $FORM{password};
  }

  $html->tpl_show(templates('form_login'), \%first_page, $attr);

  return 1;
}

#**********************************************************
=head2 check_permissions() - Checkadmin permission

  Arguments:
    $login
    $password
    $session_sid
    $attr
      API_KEY

  Returns:

    0 - Access
    1 - Deny
    2 - Disable
    3 - Deny IP
    4 - Wrong passwd
    5 - Wrong LDAP Auth
    6 - Deny IP/Time

=cut
#**********************************************************
sub check_permissions {
  my ($login, $password, $session_sid, $attr) = @_;

  $login    = '' if (!defined($login));
  $password = '' if (!defined($password));

  if ($conf{ADMINS_ALLOW_IP}) {
    $conf{ADMINS_ALLOW_IP} =~ s/ //g;
    my @allow_ips_arr = split(/,/, $conf{ADMINS_ALLOW_IP});
    my %allow_ips_hash = ();
    foreach my $ip (@allow_ips_arr) {
      $allow_ips_hash{$ip} = 1;
    }
    if (!$allow_ips_hash{ $ENV{REMOTE_ADDR} }) {
      if($conf{HIDE_WRONG_PASSWORD}) {
        $password = '****';
      }
      $admin->system_action_add("$login:$password DENY IP: $ENV{REMOTE_ADDR}", { TYPE => 11 });
      $admin->{errno} = 3;
      return 3;
    }
  }

  my %PARAMS = (
    IP    => $ENV{REMOTE_ADDR} || '0.0.0.0',
    SHORT => 1
  );

  if($PARAMS{IP} eq '::1') {
    $PARAMS{IP} = '0.0.0.1';
  }

  $login    =~ s/"/\\"/g;
  $login    =~ s/'/\\'/g;
  $password =~ s/"/\\"/g;
  $password =~ s/'/\\'/g;

  if ($session_sid && ! $login && (! $attr->{API_KEY} && ! $attr->{key})) {
    $admin->online_info({ SID => $session_sid });
    if ($admin->{TOTAL} > 0 && $ENV{REMOTE_ADDR} eq $admin->{IP}) {
      $admin->{SID} = $session_sid;
    }
    else {
      $admin->online_del({ SID => $session_sid });
    }
  }
  else {
    if (! $session_sid) {
      AXbills::HTML::get_cookies();
      $admin->{SID} = $COOKIES{admin_sid};
    }
    else {
      $admin->{SID} = mk_unique_value(14);
    }

    if($attr->{API_KEY}
      || ($conf{US_API} && $attr->{key})) {
      $PARAMS{API_KEY}   = $attr->{API_KEY} || $attr->{key} || q{123};
    }
    #LDAP auth
    elsif($conf{LDAP_IP}) {
      require AXbills::Auth::Core;
      AXbills::Auth::Core->import();
      my $Auth = AXbills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => 'Ldap'
      });

      my $result = $Auth->check_access({
        LOGIN    => $login,
        PASSWORD => $password
      });

      if ($result) {
        $PARAMS{LOGIN}   = $login;
        $PARAMS{EXTERNAL_AUTH} = 'ldap';
      }
      else {
        $admin->{errno} = 5;
        $admin->{errstr}= $Auth->{errstr};

        if (! $conf{AUTH_CASCADE}) {
          return 2;
        }
        $PARAMS{LOGIN}   = $login;
        $PARAMS{PASSWORD}= $password;
      }
    }
    else {
      $PARAMS{LOGIN}   = $login;
      $PARAMS{PASSWORD}= $password;
    }
  }

  $admin->info($admin->{AID}, \%PARAMS);

  if ($login && $password) {
    if (!$FORM{g2fa}) {
      if ($admin->{G2FA}) {
        $FORM{user} = $login;
        $FORM{password} = $password;
        $FORM{G2FA} = 1;
        return 1;
      }
    }
    else {
      require AXbills::Auth::Core;
      AXbills::Auth::Core->import();
      my $Auth = AXbills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => 'OATH',
        FORM      => \%FORM
      });

      if (!$Auth->check_access({ SECRET => $admin->{G2FA}, PIN => $FORM{g2fa} })) {
        $admin->{errno}  = 5;
        $admin->{errstr} = 'ERROR_WRONG_PIN';
        $FORM{G2FA} = 1;
        return 2;
      }
    }
  }

  if ($admin->{errno}) {
    if ($admin->{errno} == 4) {
      if($conf{HIDE_WRONG_PASSWORD}) {
        $password = '****';
      }
      $admin->system_action_add("$login:$password", { TYPE => 11 });
      $admin->{errno} = 4;
    }
    elsif ($admin->{errno} == 2) {
      return 2;
    }

    return 1;
  }
  elsif ($admin->{DISABLE} == 1) {
    $admin->system_action_add("Disabled admin $login tried to login", { TYPE => 11 });
    $admin->{errno}  = 2;
    $admin->{errstr} = 'DISABLED';
    return 2;
  }
  elsif ($admin->{DISABLE} == 2) {
    $admin->system_action_add("Fired admin $login tried to login", { TYPE => 11 });
    $admin->{errno}  = 2;
    $admin->{errstr} = 'FIRED';
    return 2;
  }
  elsif ($admin->{EXPIRE} && $admin->{EXPIRE} ne '0000-00-00 00:00:00' && $admin->{EXPIRE} lt $DATE ) {
    $admin->system_action_add("Expired admin $login tried to login", { TYPE => 11 });
    $admin->{errno}  = 2;
    $admin->{errstr} = 'EXPIRED';
    return 2;
  }

  if ($admin->{WEB_OPTIONS}) {
    my @WO_ARR = split(/;/, $admin->{WEB_OPTIONS});
    foreach my $line (@WO_ARR) {
      my ($k, $v) = split(/=/, $line, 2);
      next if(! $k);
      $admin->{SETTINGS}{$k} = $v;

      if ($html)  {
        if($k eq 'language' && $attr->{language}) {
          $v = $attr->{language};
        }
        $html->{$k}=$v;
      }
    }

    if($admin->{SETTINGS}{PAGE_ROWS} ) {
      $PAGE_ROWS = $FORM{PAGE_ROWS} || $admin->{SETTINGS}{PAGE_ROWS};
      $LIST_PARAMS{PAGE_ROWS}=$PAGE_ROWS;
    }
  }

  if ($admin->{ADMIN_ACCESS}) {
    my $list = $admin->access_list({
      AID       => $admin->{AID},
      DISABLE   => 0,
      COLS_NAME => 1
    });

    my $deny = ($admin->{TOTAL}) ? 1 : 0;
    foreach my $line (@$list) {
      my $time       = $TIME;
      $time          =~ s/://g;
      $line->{begin} =~ s/://g;
      $line->{end}   =~ s/://g;
      my $wday = (localtime(time))[6];

      if ((! $line->{day} || $wday+1 == $line->{day})
        && $time > $line->{begin} && $time < $line->{end}) {
        if ($line->{bit_mask} && check_ip($ENV{REMOTE_ADDR}, "$line->{ip}/$line->{bit_mask}")) {
          $deny = 0;
          last;
        }
        elsif ($line->{ip} eq '0.0.0.0' || !$line->{bit_mask} && check_ip($ENV{REMOTE_ADDR}, $line->{ip})) {
          $deny = 0;
          last;
        }
      }
    }

    if ($deny) {
      $admin->{MODULE}='';
      $admin->system_action_add("DENY IP: $ENV{REMOTE_ADDR}", { TYPE => 50 });
      return 6;
    }
  }

  %permissions = %{ $admin->get_permissions() };

  if($permissions{0} && $permissions{0}{17}) {
    $html->{EXPORT_LIST}=1;
  }
  if (defined($permissions{4}) && $permissions{4}{7}) {
    $html->{CHANGE_TPLS}=1;
  }

  if ($password && $login) {
    $admin->full_log_add( {
      FUNCTION_INDEX => 0,
      AID            => $admin->{AID},
      FUNCTION_NAME  => 'ADMIN_AUTH',
      DATETIME       => 'NOW()',
      IP             => $ENV{REMOTE_ADDR},
      SID            => $admin->{SID},
      # FIXME: This takes possible crash in Paranoid log, because dbcore sets '' value to NULL
      PARAMS         => '',
    });
  }

  if (!$admin->{SID}) {
    $admin->{SID} = mk_unique_value(14);
  }

  return 0;
}

#**********************************************************
=head2 auth_user($user_name, $password, $session_id, $attr) - AUth user sessions

  Arguments:
    $user_name
    $password
    $session_id
    $attr

  Returns:
    ($ret, $session_id, $login)

=cut
#**********************************************************
sub auth_user {
  my ($login, $password, $session_id, $attr) = @_;

  if($attr->{USER}) {
    $user = $attr->{USER};
  }

  my $ret                  = 0;
  my $res                  = 0;
  my $REMOTE_ADDR          = $ENV{'REMOTE_ADDR'} || '';
  my $uid                  = 0;
  require AXbills::Auth::Core;
  AXbills::Auth::Core->import();

  my $Auth;

  # request from apple only POST without custom own prop, we dont handle query params in POST request
  $FORM{external_auth} = 'Apple' if ($conf{AUTH_APPLE_ID} && $ENV{QUERY_STRING} && $ENV{QUERY_STRING} =~ /external_auth=Apple/);

  if ($FORM{external_auth}) {
    $Auth = AXbills::Auth::Core->new({
      CONF      => \%conf,
      AUTH_TYPE => $FORM{external_auth},
      USERNAME  => $login,
      SELF_URL  => $SELF_URL,
      FORM      => \%FORM
    });

    $Auth->check_access(\%FORM);

    if($Auth->{auth_url}) {
      print "Location: $Auth->{auth_url}\n\n";
      exit;
    }
    elsif($Auth->{USER_ID}) {
      $user->list({
        $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
        LOGIN                => '_SHOW',
        DELETED              => 0,
        COLS_NAME            => 1
      });

      if ($conf{AUTH_EMAIL} && $Auth->{USER_EMAIL} && !$user->{TOTAL} && !$sid && !($attr->{API} && $session_id)) {
        $user->list({
          EMAIL     => $Auth->{USER_EMAIL} || '--',
          LOGIN     => '_SHOW',
          DELETED   => 0,
          COLS_NAME => 1
        });
        $Auth->{EXTERNAL_AUTH_EMAIL} = 1;
      }

      if ($user->{TOTAL}) {
        $uid = $user->{list}->[0]->{uid};
        $user->{LOGIN} = $user->{list}->[0]->{login};
        $user->{UID} = $uid;
        $res = $uid;
        $Auth->{USER_EXISTS} = 1;
        $OUTPUT{PUSH_STATE} = "<script>history.pushState(null, null, 'index.cgi?index=10&sid=$sid');</script>" if (!$attr->{API});

        if ($conf{AUTH_EMAIL} && $Auth->{EXTERNAL_AUTH_EMAIL}) {
          $user->pi_change({
            $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
            UID                  => $user->{UID}
          });
        }
      }
      else {
        if (!$sid && !($attr->{API} && $session_id)) {
          $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message('err', $lang{ERROR}, $lang{ERR_UNKNOWN_SN_ACCOUNT}, { OUTPUT2RETURN => 1 });
          return 0;
        }
      }
    }
    else {
      $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message('err', $lang{ERROR}, $lang{ERR_SN_ERROR}, {OUTPUT2RETURN => 1});
      return 0;
    }
  }

  if (!$conf{PASSWORDLESS_ACCESS}) {
    if($ENV{USER_CHECK_DEPOSIT}) {
      $conf{PASSWORDLESS_ACCESS} = $ENV{USER_CHECK_DEPOSIT};
    }
    elsif($attr->{PASSWORDLESS_ACCESS}) {
      $conf{PASSWORDLESS_ACCESS}=1;
    }
  }

  #Passwordless Access
  if ($conf{PASSWORDLESS_ACCESS} && !$login && !$password && !$session_id) {
    ($ret, $session_id, $login) = passwordless_access($REMOTE_ADDR, $session_id, $login,
      { PASSWORDLESS_GUEST_ACCESS => $conf{PASSWORDLESS_GUEST_ACCESS} });

    if($ret) {
      return ($ret, $session_id, $login);
    }
  }

  if ($index == 1000) {
    $user->web_session_del({ SID => $session_id });
    return 0;
  }
  elsif ($session_id) {
    $user->web_session_info({ SID => $session_id });

    if ($user->{TOTAL} < 1) {
      delete $FORM{REFERER};
      delete $user->{errno};
      #$html->message('err', "$lang{ERROR}", "$lang{NOT_LOGINED}");
      #return 0;
    }
    elsif ($user->{errno}) {
      $html->message( 'err', $lang{ERROR} );
    }
    elsif ( $conf{web_session_timeout} < $user->{SESSION_TIME} ){
      $html->message( 'info', "$lang{INFO}", 'Session Expire' );
      $user->web_session_del({ SID => $session_id });
      return 0;
    }
    elsif (! $conf{USERPORTAL_MULTI_SESSIONS} && $user->{REMOTE_ADDR} ne $REMOTE_ADDR) {
      $html->message( 'err', "$lang{ERROR}", 'WRONG IP' );
      $user->web_session_del({ SID => $session_id });
      return 0;
    }
    else {
      $user->info($user->{UID}, { USERS_AUTH => 1 });
      $admin->{DOMAIN_ID} = $user->{DOMAIN_ID};
      $user->web_session_update({ SID => $session_id, REMOTE_ADD => $REMOTE_ADDR  });
      #Add social id
      if ($Auth->{USER_ID}) {
        if (!$Auth->{USER_EXISTS}) {
          $user->pi_change({
            $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
            UID                  => $user->{UID}
          });
        }
        else {
          return {
            errno  => 10002,
            errstr => 'You already linked this social auth account to another account identifier.',
          } if ($attr->{API});
        }
      }

      return ($user->{UID}, $session_id, $user->{LOGIN});
    }
  }

  if ($login && $password) {
    if ($conf{wi_bruteforce}) {
      $user->bruteforce_list({
        LOGIN    => $login,
        PASSWORD => $password,
        CHECK    => 1
      });

      if ($user->{TOTAL} > $conf{wi_bruteforce}) {
        if ($attr->{API}) {
          return {
            errno  => 10000,
            errstr => 'You try to brute password and system block your account. Please contact system administrator.'
          };
        }
        $OUTPUT{BODY} = $html->tpl_show(templates('form_bruteforce_message'), undef);
        return 0;
      }
    }

    #check password from RADIUS SERVER if defined $conf{check_access}
    if ($conf{check_access}) {
      $Auth = AXbills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => 'Radius',
        FORM      => \%FORM
      });

      $res = $Auth->check_access({
        LOGIN    => $login,
        PASSWORD => $password
      });
    }
    #check password direct from SQL
    else {
      $res = auth_sql($login, $password) if ($res < 1);
    }
  }
  elsif ($login && !$password) {
    $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD}, {OUTPUT2RETURN => 1} );
  }
  #Get user ip
  if (defined($res) && $res > 0) {
    $user->info($user->{UID} || 0, {
      LOGIN      => ($user->{UID}) ? undef : $login,
      DOMAIN_ID  => $FORM{DOMAIN_ID},
      USERS_AUTH => 1
    });

    if($conf{AUTH_G2FA}) {
      $user->pi();
      if(!$FORM{g2fa}){
        if ($user->{_G2FA}) {
          $FORM{user} = $login;
          $FORM{password} = $password;
          $FORM{G2FA} = 1;
          delete $FORM{logined};
          return (0, $session_id, $login);
        }
      }
      else {
        my $OATH = AXbills::Auth::Core->new({
          CONF      => \%conf,
          AUTH_TYPE => 'OATH'
        });

        if (!$OATH->check_access({SECRET => $user->{_G2FA}, PIN => $FORM{g2fa}})) {
          $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message( 'err', $lang{ERROR}, $lang{G2FA_WRONG_CODE}, {OUTPUT2RETURN => 1} );
          $FORM{G2FA} = 1;
          delete $FORM{logined};
          return (0, $session_id, $login);
        }
      }
    }

    if ($user->{TOTAL} > 0) {
      $session_id          = mk_unique_value(16);
      $ret                 = $user->{UID};
      $user->{REMOTE_ADDR} = $REMOTE_ADDR;
      $admin->{DOMAIN_ID}  = $user->{DOMAIN_ID};
      $login               = $user->{LOGIN};

      if (!$conf{SKIP_GROUP_ACCESS_CHECK}) {
        $user->group_info($user->{GID});

        if ($user->{DISABLE_ACCESS}) {
          delete $FORM{logined};

          if ($attr->{API}) {
            return {
              errno  => 10440,
              errstr => 'Access denied.',
            };
          }

          $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY}, { OUTPUT2RETURN => 1 });
          return 0;
        }
      }

      $user->web_session_add({
        UID         => $user->{UID},
        SID         => $session_id,
        LOGIN       => $login,
        REMOTE_ADDR => $REMOTE_ADDR,
        EXT_INFO    => $ENV{HTTP_USER_AGENT},
        COORDX      => $FORM{coord_x} || '',
        COORDY      => $FORM{coord_y} || ''
      });
    }
    else {
      $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD}, {OUTPUT2RETURN => 1} );
    }
  }
  else {
    if ($login || $password) {
      $user->bruteforce_add({
        LOGIN       => $login,
        PASSWORD    => $password,
        REMOTE_ADDR => $REMOTE_ADDR,
        AUTH_STATE  => $ret
      });

      $OUTPUT{MESSAGE} = $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD},
        { OUTPUT2RETURN => 1, ID => 900 } );
    }
    $ret = 0;
  }

  return ($ret, $session_id, $login);
}

#**********************************************************
=head2 passwordless_access($remote_addr, $session_id, $login, $attr) - Get passwordless access info

   Arguments:
     $remote_addr
     $session_id
     $login
     $attr
       PASSWORDLESS_GUEST_ACCESS

   Return:
     $uid, $session_id, $login

=cut
#**********************************************************
sub passwordless_access {
  my ($remote_addr, $session_id, $login, $attr) = @_;
  my ($ret);

  require Internet::Sessions;
  Internet::Sessions->import();
  my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

  my %params = ();

  if($attr->{PASSWORDLESS_GUEST_ACCESS}) {
    $params{GUEST} = 1;
    if($attr->{PASSWORDLESS_GUEST_ACCESS} ne '1') {
      $params{SERVICE_STATUS} = $attr->{PASSWORDLESS_GUEST_ACCESS};
      $params{INTERNET_STATUS}= $attr->{PASSWORDLESS_GUEST_ACCESS};
      delete $conf{PASSWORDLESS_ACCESS};
    }
  }

  my $list = $Sessions->online({
    USER_NAME         => '_SHOW',
    FRAMED_IP_ADDRESS => $remote_addr,
    %params
  });

  if ($Sessions->{TOTAL} == 1) {
    $login     = $list->[0]->{user_name} || $login;
    $ret       = $list->[0]->{uid};
    $session_id= mk_unique_value(14);
    $user->info($ret, { USERS_AUTH => 1 });

    $user->{REMOTE_ADDR} = $remote_addr;

    if (!$conf{SKIP_GROUP_ACCESS_CHECK}) {
      $user->group_info($user->{GID});

      if ($user->{DISABLE_ACCESS}) {
        delete $FORM{logined};

        if ($attr->{API}) {
          return {
            errno  => 10500,
            errstr => 'Access denied.',
          };
        }

        $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY}, { OUTPUT2RETURN => 1 });
        return 0;
      }
    }
    # FIXME: very bad hardcode inside function check
    $user->web_session_add({
      UID         => $ret,
      SID         => $session_id,
      LOGIN       => $login,
      REMOTE_ADDR => $remote_addr,
      EXT_INFO    => $ENV{HTTP_USER_AGENT},
      COORDX      => $FORM{coord_x} || '',
      COORDY      => $FORM{coord_y} || ''
    });

    return ($ret, $session_id, $login);
  }
  else {
    require Internet;
    Internet->import();

    my $Internet = Internet->new($db, $admin, \%conf);

    my $internet_list = $Internet->user_list({
      IP        => $remote_addr,
      %params,
      LOGIN     => '_SHOW',
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} && $Internet->{TOTAL} == 1) {
      $login     = $internet_list->[0]->{login} || $login;
      $ret       = $internet_list->[0]->{uid} || 0;
      $session_id= mk_unique_value(14);
      $user->info($ret);
      $user->{REMOTE_ADDR} = $remote_addr;
      return ($ret, $session_id, $user->{LOGIN});
    }
  }

  return ($ret, $session_id, $login);
}

#**********************************************************
=head2 auth_sql($login, $password) - Authentification from SQL DB

=cut
#**********************************************************
sub auth_sql {
  my ($user_name, $password) = @_;
  my $ret = 0;

  $conf{WEB_AUTH_KEY}='LOGIN' if(! $conf{WEB_AUTH_KEY});

  if ($conf{WEB_AUTH_KEY} eq 'LOGIN') {
    $user->info(0, {
      LOGIN      => $user_name,
      PASSWORD   => $password,
      DOMAIN_ID  => $FORM{DOMAIN_ID} || 0,
      USERS_AUTH => 1
    });
  }
  else {
    my @a_method = split(/,/, $conf{WEB_AUTH_KEY});
    foreach my $auth_param (@a_method) {
      $user->list({
        $auth_param => $user_name,
        PASSWORD    => $password,
        DELETED     => 0,
        DOMAIN_ID   => $FORM{DOMAIN_ID} || 0,
        COLS_NAME   => 1
      });

      if ($user->{TOTAL}) {
        $user->info($user->{list}->[0]->{uid});
        last;
      }
    }
  }

  if ($user->{TOTAL} < 1) {
    if (! $conf{PORTAL_START_PAGE}) {
      $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message('err', $lang{ERROR},
        $lang{ERR_WRONG_PASSWD}, { OUTPUT2RETURN => 1 });
    }
  }
  elsif (_error_show($user)) {
  }
  elsif ($user->{DELETED}) {
  }
  else {
    $ret = $user->{UID} || $user->{list}->[0]->{uid};
  }

  $admin->{DOMAIN_ID}=$user->{DOMAIN_ID};

  return $ret;
}
#**********************************************************
=head2 load_lang() - Small lang loader

=cut
#**********************************************************
sub load_lang {
  my $fallback_locale = 'english';
  my $is_fallback = 0;

  if (!$html || !$html->{language}) {
    $html->{language} = $fallback_locale;
    $is_fallback = 1;
  }

  $is_fallback = 1 if (!$is_fallback && $html->{language} eq $fallback_locale);

  do "language/$fallback_locale.pl";
  if (!$is_fallback) {
    eval { do "language/$html->{language}.pl" };
  }

  if ($@) {
    print "Content-Type: text/plain\n\n";
    print "Can't load language\n";
    print $@;
    print ">> language/$html->{language}.pl << ";
    exit;
  }
}

1;
