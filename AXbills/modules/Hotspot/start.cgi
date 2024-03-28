#!/usr/bin/perl

=head1 NAME

  ABillS Hotspot start page

  Error ID: 15xx

=cut

use strict;
use warnings;

BEGIN {
  our $libpath = '../';
  our $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "AXbills/mysql/",
    $libpath . "AXbills/",
    $libpath . 'lib/',
    $libpath . 'AXbills/modules/');

  eval {require Time::HiRes;};
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

our (
  $base_dir,
  %LANG,
  %lang,
  $Cards,
  %COOKIES
);

use AXbills::Defs;
use AXbills::Base qw();
use Users;
use Nas;
use Admins;
use Tariffs;
use Conf;
use Log;
use Hotspot;
use Internet;

do "../libexec/config.pl";

$conf{base_dir} = $base_dir if (!$conf{base_dir});

require AXbills::Templates;
require AXbills::Misc;

our $html = AXbills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
    METATAGS => templates('metatags'),
    COLORS   => $conf{UI_COLORS},
    STYLE    => 'default',
  }
);

our $VERSION = '0.23';
#Revision

my $sql = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
our $db = ($conf{VERSION} && $conf{VERSION} < 0.70) ? $sql->{db} : $sql;

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

$html->{show_header} = 1;

do "../language/english.pl";
if (-f "../language/$html->{language}.pl") {
  do "../language/$html->{language}.pl";
}

$sid = $FORM{sid} || ''; # Session ID
$lang{MINUTES} = 'Mins';

my $PHONE_PREFIX = $conf{DEFAULT_PHONE_PREFIX} || '';
my $auth_cookie_time = $conf{AUTH_COOKIE_TIME} || 86400;

mk_cookie();

my $debug = $conf{HOTSPOT_DEBUG_MODE} || 0;
if ($debug) {
  my $debug_ = qq{=============================\n};
  foreach my $key (sort keys %FORM) {
    $debug_ .= "$key -> $FORM{$key}\n";
  }
  $debug_ .= qq{-----------------------\n};
  foreach my $key (sort keys %COOKIES) {
    $debug_ .= "$key -> $COOKIES{$key}\n";
  }

  `echo "$debug_" >> hotspot_debug.log`;
}

#===========================================================
our $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} });

my %OUTPUT = ();
my %INFO_HASH = ();
our $CONTENT_LANGUAGE = '';
our $DOMAIN_ID = 0;
our $users = Users->new($db, $admin, \%conf);
our $Internet = Internet->new($db, $admin, \%conf);
my $Log = Log->new($db, \%conf);
my $Hotspot = Hotspot->new($db, $admin, \%conf,);
$user = $users;

if ($FORM{DOMAIN_ID}) {
  $admin->info($conf{SYSTEM_ADMIN_ID}, { DOMAIN_ID => $FORM{DOMAIN_ID} });
  $DOMAIN_ID = $admin->{DOMAIN_ID} || $FORM{DOMAIN_ID};
  $html->{WEB_TITLE} = $admin->{DOMAIN_NAME};
  if ($admin->{errno}) {
    print $html->header({ CONTENT_LANGUAGE => $CONTENT_LANGUAGE });
    print "Unknown domain admin: $admin->{errno}";
    exit;
  }
}
# Loads config values from DB
Conf->new($db, $admin, \%conf);

my $Nas = Nas->new($db, \%conf, $admin);

my %PARAMS = ();

if ($FORM{BUY_CARD}) {

}
elsif ($FORM{NAS_ID}) {
  $PARAMS{NAS_ID} = $FORM{NAS_ID};
}
elsif ($FORM{NAS_IP}) {
  $PARAMS{IP} = $FORM{NAS_IP};
}
else {
  $PARAMS{IP} = $ENV{REMOTE_ADDR};
}

$Nas->info({ %PARAMS });

if ($Nas->{TOTAL} > 0) {
  $INFO_HASH{CITY} = $Nas->{CITY};
  $INFO_HASH{ADDRESS_STREET} = $Nas->{ADDRESS_STREET};
  $INFO_HASH{ADDRESS_BUILD} = $Nas->{ADDRESS_BUILD};
  $INFO_HASH{ADDRESS_FLAT} = $Nas->{ADDRESS_FLAT};
  $INFO_HASH{NAS_GID} = $Nas->{GID};
  $FORM{NAS_GID} = $Nas->{GID};
}

my $login_url = $conf{HOTSPOT_LOGIN_URL} || 'http://192.168.182.1:3990/prelogin?lang=' . $html->{language};
if (($FORM{external_auth} || $conf{HOTSPOT_SN_LOGIN}) && !$FORM{next}) {
  fast_login() if ($FORM{error});
  $FORM{external_auth} ||= $conf{HOTSPOT_SN_LOGIN};
  form_social_nets();
  $FORM{GUEST_ACCOUNT} = 1;
}

if ($FORM{ajax} && $FORM{mac} && $FORM{PHONE}) {
  check_auth();
  exit;
}

if ($conf{HOTSPOT_AUTO_LOGIN}) {
  fast_login();
}

if ($FORM{uamport} && $FORM{uamport} eq 'mikrotik') {
  $login_url = 'http://192.168.182.1/login';
  #mikrotik_();
}
elsif ($FORM{GUEST_ACCOUNT}) {
  get_hotspot_account();
}
elsif ($FORM{PIN}) {
  check_card();
}
elsif ($FORM{PAYMENT_SYSTEM} || $FORM{BUY_CARDS}) {
  my $output = buy_cards();
  $html->{OUTPUT} ||= $output;
}
elsif ($FORM{hotspot_advert}) {
  load_module('Hotspot', $html);
  hotspot_redirect($FORM{hotspot_advert}, $FORM{link_orig}, $FORM{username});
  exit;
}
else {
  print "Content-Type: text/html\n\n";

  $login_url = get_login_url();

  $INFO_HASH{PAGE_QS} = "&language=$FORM{language}" if ($FORM{language});

  $INFO_HASH{SELL_POINTS} = $html->tpl_show(_include('multidoms_sell_points', 'Multidoms'), \%OUTPUT,
    { OUTPUT2RETURN => 1 });
  $INFO_HASH{CARDS_BUY} = buy_cards();

  $html->tpl_show(
    templates('form_client_hotspot_start'),
    {
      DOMAIN_ID        => $DOMAIN_ID,
      DOMAIN_NAME      => $admin->{DOMAIN_NAME},
      CONTENT_LANGUAGE => $CONTENT_LANGUAGE,
      LOGIN_URL        => $login_url,
      LANG_LIST        => get_language_flags_list(\%LANG),
      LANG_CURRENT     => $html->{language},
      HTML_STYLE       => $html->{STYLE},
      SHOW_PAYSYS_BUY  => in_array('Paysys', \@MODULES),
      %INFO_HASH
    },
    { MAIN               => 1,
      SKIP_DEBUG_MARKERS => 1
    }
  );

  print $html->{OUTPUT};
  exit;
}

print $html->header({ CONTENT_LANGUAGE => $CONTENT_LANGUAGE });
$OUTPUT{BODY} = $html->{OUTPUT};
print $html->tpl_show(templates('form_base'), \%OUTPUT, { OUTPUT2RETURN => 1 });

$html->test() if ($conf{debugmods} && $conf{debugmods} =~ /LOG_DEBUG/);

#**********************************************************
=head2 get_login_url($attr)

 http://10.5.50.1/login?fastlogin=true&login=test&password=123456

 Arguments:
   $attr

=cut
#**********************************************************
sub get_login_url {
  my ($attr) = @_;

  if ($FORM{login_return_url} && $FORM{login_return_url} ne '') {
    $login_url = urldecode($FORM{login_return_url});
  }
  elsif ($FORM{GUEST_ACCOUNT} && $conf{HOTSPOT_GUEST_LOGIN_URL}) {
    $login_url = $conf{HOTSPOT_GUEST_LOGIN_URL};
  }
  elsif ($conf{HOTSPOT_LOGIN_URL}) {
    $login_url = $conf{HOTSPOT_LOGIN_URL};
  };

  if ($FORM{LOGIN}) {
    $login_url =~ s/%LOGIN%/$FORM{LOGIN}/g;
  };
  if ($FORM{PASSWORD}) {
    $login_url =~ s/%PASSWORD%/$FORM{PASSWORD}/g;
  };

  if (defined $attr && $attr->{NAS_IP}) {
    $login_url =~ s/%NAS_IP%/$attr->{NAS_IP}/g;
  };

  if ($FORM{UNIFI_SITENAME}) {
    $login_url =~ s/\%UNIFI_SITENAME\%/$FORM{UNIFI_SITENAME}/g;
  }

  if ($conf{HOTSPOT_REDIRECT_URL}) {
    $login_url .= "&dst=$conf{HOTSPOT_REDIRECT_URL}";
  }

  return $login_url;
}

#**********************************************************
=head2 form_social_nets()

=cut
#**********************************************************
sub form_social_nets {

  use AXbills::Auth::Core;
  my $Auth;

  if ($FORM{external_auth}) {
    $Auth = AXbills::Auth::Core->new({
      CONF      => \%conf,
      AUTH_TYPE => $FORM{external_auth},
      SELF_URL  => $SELF_URL,
      DOMAIN_ID => $DOMAIN_ID
    });

    $Auth->check_access(\%FORM);

    if ($Auth->{auth_url}) {
      print "Location: $Auth->{auth_url}\n\n";
      exit;
    }
    elsif ($Auth->{USER_ID}) {
      my $users_list = $users->list({
        $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
        LOGIN                => '_SHOW',
        PASSWORD             => '_SHOW',
        FIO                  => '_SHOW',
        COLS_NAME            => 1
      });

      if ($users->{TOTAL}) {
        $users->{LOGIN} = $users_list->[0]->{login};
        $users->{UID} = $users_list->[0]->{uid};
        $COOKIES{hotspot_username} = $users_list->[0]->{login};
        $COOKIES{hotspot_password} = $users_list->[0]->{password};

        mk_cookie({
          hotspot_username => $COOKIES{hotspot_username},
          hotspot_password => $COOKIES{hotspot_password},
        });
        return 1;
      }
      #For user registration
      else {
        $FORM{'3.' . $Auth->{CHECK_FIELD}} = $Auth->{USER_ID};
        $FORM{'3.EMAIL'} = $Auth->{EMAIL};
        $FORM{'3.FIO'} = $Auth->{USER_NAME};
        #UID                  => $user->{UID}
        #print "Content-Type: text/html\n\n";
        #print "/ $Auth->{CHECK_FIELD} / $Auth->{USER_ID} //";
      }
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{ERR_SN_ERROR}
        . ' Start registration' . "\n ID: "
        . ($Auth->{USER_ID} || q{})
        . (($Auth->{errno}) ? "\n Error: " . $Auth->{errstr} : ''),
        { ID => 1530 }
      );
      $FORM{external_auth_failed} = 1;
    }
  }

  my %first_page = ();
  if ($conf{AUTH_VK_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK} = $html->element('li',
      $html->button('', "external_auth=Vk&DOMAIN_ID=$DOMAIN_ID", { class => 'icon-vk', ICON => 'fab fa-vk' }),
      { OUTPUT2RETURN => 1 }
    )
  }

  if ($conf{AUTH_FACEBOOK_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK} .= $html->element('li',
      $html->button('', "external_auth=Facebook&DOMAIN_ID=$DOMAIN_ID", { class => 'icon-facebook', ICON => 'fab fa-facebook' }),
      { OUTPUT2RETURN => 1 }
    );
  }

  if ($conf{AUTH_GOOGLE_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK} .= $html->element('li',
      $html->button('', "external_auth=Google&DOMAIN_ID=$DOMAIN_ID", { class => 'icon-google', ICON => 'fab fa-google' }),
      { OUTPUT2RETURN => 1 }
    );
  }

  if ($conf{AUTH_INSTAGRAM_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK} .= $html->element('li',
      $html->button('', "external_auth=Instagram&DOMAIN_ID=$DOMAIN_ID", { class => 'icon-instagram', ICON => 'fab fa-instagram' }),
      { OUTPUT2RETURN => 1 }
    );
  }

  $OUTPUT{BODY} = $html->tpl_show(templates('form_ext_auth'),
    \%first_page,
    { MAIN => 1,
      ID   => 'form_client_login'
    });

  return 1;
}

#**********************************************************
=head2 get_hotspot_account()

=cut
#**********************************************************
sub get_hotspot_account {

  my $Tariffs = Tariffs->new($db, \%conf, $admin);

  load_module('Internet', $html);
  load_module('Cards', $html);

  if ($FORM{external_auth_failed}) {
    return 0;
  }

  my $extra_auth = 1;
  my $nas_id = $FORM{NAS_ID} || '';

  $login_url = get_login_url();
  if ($FORM{PIN}) {
    my $login = $FORM{LOGIN} || q{};
    my $pin = $FORM{PIN} || q{};
    cards_card_info({ PIN => $FORM{PIN}, INFO_ONLY => 1 });
    if ($login eq $FORM{LOGIN} && $pin eq $FORM{PASSWORD}) {
      $login_url = get_login_url();
      print "Location: $login_url\n\n";
      exit;
    }
    else {
      $html->message('warn', $lang{GUEST_ACCOUNT}, "Wrong pin", { ID => 1531 });
      $html->tpl_show(templates('form_client_hotspot_pin'), { %FORM });
      if ($conf{HOTSPOT_LOG}) {
        $Log->log_print('LOG_ERR', $FORM{LOGIN}, "Wrong pin: $login <> $FORM{LOGIN} or $pin <> $FORM{PASSWORD}", { LOG_FILE => "$conf{HOTSPOT_LOG}" });
      }
      return 0;
    }
  }
  elsif ($COOKIES{hotspot_username}) {
    if ($conf{HOTSPOT_LOG}) {
      $Log->log_print('LOG_INFO', $COOKIES{hotspot_username}, "He has a cookie!", { LOG_FILE => "$conf{HOTSPOT_LOG}" });
    }
    $html->message('info', "$lang{GUEST_ACCOUNT}", "$lang{USER} : '$COOKIES{hotspot_username}' ", { ID => 1532 });
    if ($conf{HOTSPOT_CHECK_PHONE}) {
      $extra_auth = cards_card_info({
        PIN         => $COOKIES{hotspot_password},
        FOOTER_TEXT => $html->button($lang{LOGIN_IN_TO_HOTSPOT}, '',
          { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' }),
        HEADER_TEXT => $html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
          { class => 'btn btn-secondary btn-xs' }),
        INFO_ONLY   => 1,
        UID         => $users->{UID}
      });

      if ($extra_auth) {
        $login_url = get_login_url();
        print "Location: $login_url\n\n";
        exit;
      }
    }
    else {
      $extra_auth = cards_card_info({
        PIN         => $COOKIES{hotspot_password},
        FOOTER_TEXT => $html->button($lang{LOGIN_IN_TO_HOTSPOT}, '',
          { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' }),
        HEADER_TEXT =>
          $html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
            { class => 'btn btn-secondary btn-xs' }),
        UID         => $users->{UID}
      });
    }

    if ($extra_auth) {
      return 1;
    }
    else {
      $extra_auth = 1;
      #      mk_cookie({
      #        hotspot_username=> '',
      #        hotspot_password=> '',
      #        hotspot_card_id => '',
      #      });

      delete $COOKIES{qw(hotspot_username hotspot_password hotspot_card_id)};

      $html->message('warn', $lang{GUEST_ACCOUNT}, $lang{DELETED}, { ID => 1533 });
    }
  }
  elsif ($FORM{mac}) {
    my $list = $Internet->user_list({
      #DATE => $DATE,
      PASSWORD  => '_SHOW',
      CID       => $FORM{mac},
      COLS_NAME => 1,
    });

    if ($Internet->{TOTAL} == 1) {
      cards_card_info({
        PIN         => "$list->[0]->{PASSOWRD}",
        FOOTER_TEXT => $html->button($lang{LOGIN_IN_TO_HOTSPOT}, '',
          { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' }),
        HEADER_TEXT => $html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
          { class => 'btn btn-secondary btn-xs' })
      });

      return 0;
    }
  }
  else {
    #    my $a = `echo "$DATE $TIME Can't find MAC: $FORM{mac} // $COOKIES{hotspot_user_id}" >> /tmp/mac_test`;
  }

  my $tp_list = $Tariffs->list({
    PAGE_ROWS    => 1,
    SORT         => 1,
    NAME         => '_SHOW',
    DOMAIN_ID    => $DOMAIN_ID,
    PAYMENT_TYPE => 2,
    COLS_NAME    => 1,
    NEW_MODEL_TP => 1,
  });

  if ($Internet->{TOTAL}) {
    $html->message('info', "$lang{ERROR}", "Guest mode disable for mac '$FORM{mac}'", { ID => 1533 });
    $Log->log_print('LOG_ERR', $FORM{mac}, "Guest mode disable for mac '$FORM{mac}'", { NAS => $Nas });
    #    my $a = `echo "$DATE $TIME Guest mode disable: $FORM{mac} // $COOKIES{hotspot_user_id}" >> /tmp/mac_test`;
    return 0;
  }

  my $user_mac = $FORM{mac} || $COOKIES{hotspot_user_id} || '';
  #  my $a = `echo "REG GUEST: $DATE $TIME: $FORM{mac} COOKIES: $COOKIES{hotspot_user_id} user_mac: $user_mac" >> /tmp/mac_test`;

  if ($Tariffs->{TOTAL} < 1) {
    $html->message('info', "$lang{INFO}", "$lang{GUEST_ACCOUNT} $lang{DISABLE}", { ID => 1534 });
    $Log->log_print('LOG_ERR', $FORM{mac}, "$lang{GUEST_ACCOUNT} $lang{DISABLE}", { NAS => $Nas });
    return 0;
  }

  #Check SOCIAL_NETS for guest connection
  if ($conf{HOTSPOT_CHECK_SOCIAL_NETS}) {
    if (!$FORM{external_auth} && form_social_nets()) {
      $extra_auth = 0;
    }
  }

  #Check phone for guest connection
  if ($conf{HOTSPOT_CHECK_PHONE}) {
    if ($FORM{PIN}) {
      $extra_auth = 0;
    }
    elsif (defined($FORM{PHONE})
      && (!$FORM{PHONE} || ($conf{PHONE_FORMAT} && $FORM{PHONE} !~ /$conf{PHONE_FORMAT}/))) {
      _error_show({ errno => 21, err_str => 'ERR_WRONG_PHONE' }, { ID => 1505 });
    }

    if (!$FORM{PHONE}) {
      $html->tpl_show(templates('form_client_hotspot_phone'),
        { %FORM, PHONE_PREFIX => $PHONE_PREFIX },
      );
      $extra_auth = 0;
    }
    else {
      $extra_auth = 1;
      #Check register phone
      my $internet_list = $Internet->user_list({
        #DATE => $DATE,
        PASSWORD  => '_SHOW',
        CID       => '_SHOW',
        PHONE     => $FORM{PHONE},
        LOGIN     => '_SHOW',
        COLS_NAME => 1,
      });

      if ($Internet->{TOTAL} == 1) {
        # $extra_auth = cards_card_info( {
        # FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
        # { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
        # HEADER_TEXT => $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
        # { class => 'btn btn-secondary btn-xs' } ),
        # INFO_ONLY => 1,
        # UID       => $dv_list->[0]->{uid}
        # } );

        # if($extra_auth) {
        # if ($FORM{send_pin}) {
        # _send_sms_with_pin($FORM{UID});
        # }
        # else
        # {
        # $html->message( 'info', '', "Этот телефон уже зарегистрирован, введите PIN");
        # }
        # my $button = $html->button( "Выслать PIN повторно",
        # "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id&send_pin=1&PHONE=$FORM{PHONE}&UID=$dv_list->[0]->{uid}&GUEST_ACCOUNT=1",
        # { class => 'btn btn-secondary btn-xs' } );
        # $html->tpl_show( templates( 'form_client_hotspot_pin' ), { %FORM, BUTTON => $button } );

        # }

        if ($FORM{send_pin}) {
          _send_sms_with_pin($internet_list->[0]);

          if ($conf{HOTSPOT_LOG}) {
            $Log->log_print('LOG_INFO', $internet_list->[0]->{login}, "Ask to send sms with pin to $internet_list->[0]->{phone}", { LOG_FILE => "$conf{HOTSPOT_LOG}" });
          }

        }
        my $button = $html->button("Remind PIN",
          "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id&send_pin=1&PHONE=$FORM{PHONE}&UID=$internet_list->[0]->{uid}&GUEST_ACCOUNT=1",
          { class => 'btn btn-secondary btn-xs' });
        $html->tpl_show(templates('form_client_hotspot_pin'), {
          LOGIN     => $internet_list->[0]->{login},
          BUTTON    => $button,
          DOMAIN_ID => $DOMAIN_ID,
          UID       => $internet_list->[0]->{uid},
        });

        return 0;
      }
    }
  }

  if (!$extra_auth) {
    return 0;
  }

  foreach my $line (@{$tp_list}) {
    $FORM{'TP_NAME'} = $line->{name};
    $FORM{'4.TP_ID'} = $line->{id};
  }

  $FORM{create} = 1;
  $FORM{COUNT} = 1;
  $FORM{SERIAL} = 'G';

  $FORM{PASSWD_LENGTH} = $FORM{PASSWD_LENGTH}
    || $conf{HOTSPOT_PASSWD_LENGTH}
    || $conf{PASSWD_LENGTH}
    || 6;

  my $return = cards_users_add({ NO_PRINT => 1 });
  $FORM{add} = 1;

  if (ref($return) eq 'ARRAY') {
    foreach my $line (@{$return}) {
      $FORM{'1.LOGIN'} = $line->{LOGIN};
      $FORM{'1.PASSWORD'} = $line->{PASSWORD};
      $FORM{'4.CID'} = $user_mac;
      $FORM{'1.CREATE_BILL'} = 1;
      if ($FORM{PHONE}) {
        $FORM{'3.PHONE'} = $PHONE_PREFIX . $FORM{PHONE};
      }

      if ($conf{HOTSPOT_GUESTS_GROUP} && $conf{HOTSPOT_GUESTS_GID}) {
        my $group_name = $conf{HOTSPOT_GUESTS_GROUP} . '_' . $DOMAIN_ID;
        my $group_id = $conf{HOTSPOT_GUESTS_GID} + $DOMAIN_ID;
        $user->group_info($group_id);
        if ($user->{errno}) {
          $user->group_add({ GID => $group_id, NAME => $group_name, DESCR => 'Hotspot guest group' });
        }
        $FORM{'1.GID'} = $group_id;
      }
      $line->{UID} = internet_wizard_user({ SHORT_REPORT => 1 });

      if ($line->{UID} < 1) {
        $html->message('err', "$lang{ERROR}", "$lang{LOGIN}: '$line->{LOGIN}'", { ID => 1506 });

        last if (!$line->{SKIP_ERRORS});
      }
      else {

        if ($conf{HOTSPOT_LOG}) {
          $Log->log_print('LOG_INFO', $line->{LOGIN}, "New guest account create. UID:$line->{UID}", { LOG_FILE => "$conf{HOTSPOT_LOG}" });
        }

        #Confim card creation
        if (cards_users_gen_confim({ %{$line}, SUM => ($FORM{'5.SUM'}) ? $FORM{'5.SUM'} : 0 }) == 0) {
          return 0;
        }

        #Sendsms
        if ($FORM{PHONE} && in_array('Sms', \@MODULES)) {
          load_module('Sms', $html);
          my $message = $html->tpl_show(_include('internet_reg_complete_sms', 'Internet'), { %FORM, %{$line} },
            { OUTPUT2RETURN => 1 });

          my $phone = $PHONE_PREFIX . $FORM{PHONE};

          my $sms_result = sms_send({
            NUMBER     => $phone,
            MESSAGE    => $message,
            UID        => $line->{UID},
            RIZE_ERROR => 1,
          });
          if (!$sms_result) {
            $users->change($line->{UID},
              { UID             => $line->{UID},
                DISABLE         => 1,
                ACTION_COMMENTS => 'Unknown phone',
              });

            $html->message('info', '',
              $html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
                { BUTTON => 2 }));
            return 0;
          }
        }

        # 24 hours login
        mk_cookie({
          hotspot_username => $line->{LOGIN},
          hotspot_password => $line->{PASSWORD},
          hotspot_card_id  => $line->{PASSWORD},
        });

        $login_url = get_login_url();
        #Send email
        if ($FORM{EMAIL}) {
          my $message = $html->tpl_show(_include('internet_reg_complete_mail', 'Internet'), { %FORM }, { OUTPUT2RETURN => 1 });
          sendmail("$conf{ADMIN_MAIL}", "$FORM{EMAIL}", "$lang{REGISTRATION}", "$message", "$conf{MAIL_CHARSET}", '');
        }

        if ($conf{HOTSPOT_CHECK_PHONE}) {
          cards_card_info({
            SERIAL      => "$line->{SERIAL}" . sprintf("%.11d", $line->{NUMBER}),
            FOOTER_TEXT => $html->button($lang{LOGIN_IN_TO_HOTSPOT}, '',
              { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' }),
            HEADER_TEXT => $html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
              { class => 'btn btn-secondary btn-xs' }),
            INFO_ONLY   => 1
          });

          $html->tpl_show(templates('form_client_hotspot_pin'),
            { %FORM },
          );
        }
        else {
          cards_card_info({
            SERIAL      => "$line->{SERIAL}" . sprintf("%.11d", $line->{NUMBER}),
            UID         => $line->{UID},
            FOOTER_TEXT => $html->button($lang{LOGIN_IN_TO_HOTSPOT}, '',
              { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' }),
            HEADER_TEXT => $html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
              { class => 'btn btn-secondary btn-xs' })
          });
        }
        #$html->{OUTPUT} .= $html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$nas_id", { BUTTON => 1 }) . ' ' . $html->button($lang{LOGIN_IN_TO_HOTSPOT}, '', { GLOBAL_URL => "$login_url", BUTTON => 1 });
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 check_card()

=cut
#**********************************************************
sub check_card {
  load_module('Cards', $html);

  if ($FORM{PIN}) {
    our $line;
    cards_card_info({ PIN => $FORM{PIN} });

    my $buttons = '';

    if ($FORM{LOGIN}) {
      mk_cookie({
        hotspot_username => $FORM{LOGIN},
        hotspot_password => $FORM{PASSWORD},
        hotspot_card_id  => ($line->{PASSWORD}) ? $line->{PASSWORD} : undef,
      });

      $login_url = get_login_url();

      $buttons = $html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$FORM{NAS_ID}",
        { BUTTON => 1 })
        . ' ' . $html->button($lang{LOGIN_IN_TO_HOTSPOT}, '',
        { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' });
    }
    else {
      $buttons = $html->button($lang{RETURN_TO_START_PAGE},
        "$SELF_URL/start.cgi?DOMAIN_ID=$DOMAIN_ID&NAS_ID=$FORM{NAS_ID}", { BUTTON => 1 });
    }

    $html->{OUTPUT} .= $buttons;
    return 0;
  }

  return 1;
}

##**********************************************************
#=head2 mikrotik_($attr) Mikrotik
#
#=cut
##**********************************************************
#sub mikrotik_{
#  #my ($attr) = @_;
#
#  print << "[END]";
#<form method="get" action="/hotspotlogin.cgi">
#   <input name="chal" value="" type="HIDDEN">
#   <input name="uamip" value="$FORM{uamip}" type="HIDDEN">
#   <input name="uamport" value="mikrotik" type="HIDDEN">
#   <input name="nasid" value="$FORM{nasid}" type="HIDDEN">
#   <input name="mac" value="$FORM{mac}" type="HIDDEN">
#   <input name="userurl" value="$FORM{userurl}" type="HIDDEN">
#   <input name="login" value="login" type="HIDDEN">
#
#   <input name="skin_id" id="skin_id" value="" type="hidden">
#   <input name="uid" value="$FORM{mac_id}" type="hidden">
#   <input name="pwd" value="password" type="hidden">
#   <input name="submit" value="LOG IN TO HOTSPOT" class="formbutton" type="submit">
#</form>
#[END]
#
#}

#**********************************************************
=head2 buy_cards($attr) - Buy cards

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub buy_cards {
  #my ($attr) = @_;

  my $Tariffs = Tariffs->new($db, \%conf, $admin);
  $LIST_PARAMS{UID} = $FORM{UID};

  load_module('Paysys');
  if ($FORM{BUY_CARDS} || $FORM{PAYMENT_SYSTEM}) {

    if ($FORM{PAYMENT_SYSTEM} && $conf{HOTSPOT_CHECK_PHONE} && !$FORM{PHONE}) {
      _error_show({ errno => 21, err_str => 'ERR_WRONG_PHONE' }, { ID => 1504 });
      $FORM{PAYMENT_SYSTEM_SELECTED} = $FORM{PAYMENT_SYSTEM};
      $FORM{PAYMENT_SYSTEM} = undef;
    }

    if ($FORM{PAYMENT_SYSTEM}) {

      my $ret = paysys_payment({
        OUTPUT2RETURN     => 1,
        QUITE             => 1,
        REGISTRATION_ONLY => 1,
        UID               => $FORM{UID},
        SUS_URL_PARAMS    => ($FORM{UNIFI_SITENAME}) ? "&UNIFI_SITENAME=$FORM{UNIFI_SITENAME}" : q{},
        RETURN_URL        => $COOKIES{link_login} || $SELF_URL,
      });

      $Tariffs->info($FORM{TP_ID});

      $FORM{'5.SUM'} = $Tariffs->{ACTIV_PRICE} || $FORM{PAYSYS_SUM};
      $FORM{'5.DESCRIBE'} = ($FORM{SYSTEM_SHORT_NAME} || q{}) . "# $FORM{OPERATION_ID}";
      $FORM{'5.EXT_ID'} = ($FORM{SYSTEM_SHORT_NAME} || q{}) . ":$FORM{OPERATION_ID}";
      $FORM{'5.METHOD'} = 2;
      $FORM{'3.EMAIL'} = $FORM{EMAIL};

      if ($FORM{TRUE}) {

        if ($ret) {
          load_module('Internet', $html);
          load_module('Cards', $html);
          $FORM{'4.TP_ID'} = $Tariffs->{ID};

          $FORM{create} = 1;
          $FORM{COUNT} = 1;
          $FORM{SERIAL} = "$FORM{TP_ID}";
          my $return = cards_users_add({ NO_PRINT => 1 });
          $FORM{add} = 1;

          if (ref($return) eq 'ARRAY') {
            foreach my $line (@{$return}) {
              #password gen by Cards
              $FORM{'1.LOGIN'} = $FORM{OPERATION_ID};
              $FORM{'1.PASSWORD'} = $FORM{OPERATION_ID};
              $FORM{'1.CREATE_BILL'} = 1;
              $line->{UID} = internet_wizard_user({
                SHORT_REPORT => 1,
                SHOW_USER    => 1
              });

              if ($line->{UID} < 1) {
                $html->message('err', "$lang{ERROR}", "$lang{LOGIN}: '$FORM{OPERATION_ID}'", { ID => 1507 });
                last if (!$line->{SKIP_ERRORS});
              }
              else {
                #Confim card creation
                if (cards_users_gen_confim({ %{$line},
                  LOGIN    => $FORM{'1.LOGIN'},
                  PASSWORD => $FORM{'1.PASSWORD'},
                  PIN      => $FORM{'1.PASSWORD'},
                  SUM      => ($FORM{'5.SUM'}) ? $FORM{'5.SUM'} : 0 }) == 0) {
                  return 0;
                }

                # 24 hours login
                mk_cookie(
                  {
                    hotspot_username => $line->{LOGIN},
                    hotspot_password => $line->{PASSWORD},
                    hotspot_card_id  => $line->{PASSWORD}
                  },
                  { COOKIE_TIME => gmtime(time() + $auth_cookie_time) . " GMT" }
                );

                #Attach UID to payment
                if ($FORM{PAYSYS_ID}) {
                  if (form_purchase_module({
                    HEADER => $user->{UID},
                    MODULE => 'Paysys',
                  })) {
                    exit;
                  }

                  my $Paysys = Paysys->new($db, $admin, \%conf);
                  $Paysys->change({
                    ID     => $FORM{PAYSYS_ID},
                    UID    => $line->{UID},
                    STATUS => ($FORM{TRUE}) ? 2 : undef
                  });
                }

                $FORM{LOGIN} = $FORM{'1.LOGIN'};
                $FORM{PASSWORD} = $FORM{'1.PASSWORD'};

                #Sendsms
                if ($FORM{PHONE} && in_array('Sms', \@MODULES)) {
                  load_module('Sms', $html);

                  my $message = $html->tpl_show(_include('internet_reg_complete_sms', 'Internet'),
                    { %{($Cards) ? $Cards : {}}, %FORM },
                    { OUTPUT2RETURN => 1 });

                  sms_send({
                    NUMBER  => $FORM{PHONE},
                    MESSAGE => $message,
                    UID     => $line->{UID},
                  });
                }

                #Send email
                if ($FORM{EMAIL}) {
                  my $message = $html->tpl_show(_include('internet_reg_complete_mail', 'Internet'), { %FORM },
                    { OUTPUT2RETURN => 1 });
                  sendmail("$conf{ADMIN_MAIL}", "$FORM{EMAIL}", "$lang{REGISTRATION}", "$message", "$conf{MAIL_CHARSET}",
                    '');
                }

                $login_url = get_login_url();
                cards_card_info({ #SERIAL => "$line->{SERIAL}" . sprintf("%.11d", $line->{NUMBER}),
                  ID          => $FORM{CARD_ID},
                  FOOTER_TEXT => $html->button($lang{LOGIN_IN_TO_HOTSPOT}, '',
                    { GLOBAL_URL => $login_url, class => 'btn btn-success btn-lg' })
                });


                #`echo "$DATE $TIME Login to hotspot MAC: $FORM{mac} / $COOKIES{hotspot_user_id} Card: $FORM{CARD_ID} Login: $user->{LOGIN}  UID: $line->{UID} ($login_url)" >> /tmp/mac_test`;
                #$html->{OUTPUT} .= '<center>' . $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
                #  { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ) . '</center>';
                #$html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$FORM{NAS_ID}",  { BUTTON => 1}).' '.
                return '';
              }
            }

          }

          return $ret;
        }
      }
      elsif ($FORM{FALSE}) {
        $html->message('err', $lang{ERROR}, $html->button($lang{ERR_TRY_AGAIN}, "$SELF_URL", { BUTTON => 1 }), { ID => 1509 });
      }

      return ($ret) ? $ret : '';
    }
    else {
      $INFO_HASH{UNIFI_SITENAME} = $FORM{UNIFI_SITENAME} if ($FORM{UNIFI_SITENAME});

      $Tariffs->info($FORM{TP_ID});
      my $unique = mk_unique_value(8, { SYMBOLS => '0123456789' });
      return $html->tpl_show(
        templates('form_buy_cards_paysys'),
        {
          %INFO_HASH,
          SUM               => $Tariffs->{ACTIV_PRICE},
          DESCRIBE          => '',
          OPERATION_ID      => $unique,
          UID               => ($FORM{UID} || $unique),
          TP_ID             => $FORM{TP_ID},
          DOMAIN_ID         => $DOMAIN_ID,
          PAYSYS_SYSTEM_SEL => paysys_system_sel({ PAYMENT_SYSTEM => $FORM{PAYMENT_SYSTEM_SELECTED} })
        },
        { OUTPUT2RETURN => 1 }
      );
    }
  }

  if ($conf{INTERNET_REGISTRATION_TP_GIDS}) {
    $LIST_PARAMS{TP_GID} = $conf{INTERNET_REGISTRATION_TP_GIDS};
  }
  #else {
  #  $LIST_PARAMS{TP_GID} = '>0';
  #}

  $LIST_PARAMS{DOMAIN_ID} = $DOMAIN_ID;

  my $list = $Tariffs->list(
    {
      PAYMENT_TYPE     => '<2',
      TOTAL_TIME_LIMIT => '_SHOW',
      TOTAL_TRAF_LIMIT => '_SHOW',
      ACTIV_PRICE      => '_SHOW',
      AGE              => '_SHOW',
      NAME             => '_SHOW',
      IN_SPEED         => '_SHOW',
      OUT_SPEED        => '_SHOW',
      %LIST_PARAMS,
      TP_ID            => $conf{HOTSPOT_TPS},
      COLS_NAME        => 1,
    }
  );

  foreach my $line (@{$list}) {
    #    my $ti_list = $Tariffs->ti_list( { TP_ID => $line->{tp_id} } );
    #    if ( $Tariffs->{TOTAL} > 0 ){
    #      $Tariffs->ti_info( $ti_list->[0]->[0] );
    #      if ( $Tariffs->{TOTAL} > 0 ){
    #        $Tariffs->tt_info( { TI_ID => $ti_list->[0]->[0], TT_ID => 0 } );
    #      }
    #    }

    $INFO_HASH{CARDS_TYPE} .= $html->tpl_show(
      templates('form_buy_cards_card'),
      {
        TP_NAME         => $line->{name},
        ID              => $line->{id},
        TP_ID           => $line->{tp_id},
        AGE             => $line->{age} || $lang{UNLIM},
        DOMAIN_ID       => $DOMAIN_ID,
        SPEED_IN        => $line->{in_speed} || $lang{UNLIM},
        SPEED_OUT       => $line->{out_speed} || $lang{UNLIM},
        PREPAID_MINS    => ($line->{total_time_limit}) ? sprintf("%.1f", $line->{total_time_limit} / 60 / 60) : $lang{UNLIM},
        PREPAID_TRAFFIC => $line->{total_traf_limit} || $lang{UNLIM},
        PRICE           => $line->{activate_price} || 0.00,
        UNIFI_SITENAME  => ($FORM{UNIFI_SITENAME}) ? "&UNIFI_SITENAME=$FORM{UNIFI_SITENAME}" : q{},
        USER_PHONE      => ($FORM{PHONE}) ? "&PHONE=$FORM{PHONE}" : q{},
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  return $html->tpl_show(templates('form_buy_cards'), { %INFO_HASH }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 mk_cookie($cookie_hash, $attr) - Make cookie

  Arguments:
    $cookie_vals - Cookie pairs
    $attr
       COOKIE_TIME

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub mk_cookie {
  my ($cookie_vals, $attr) = @_;

  if ($conf{HOTSPOT_DEBUG}) {
    return 1;
  }

  if(! $cookie_vals) {
    if ($ENV{REQUEST_URI}) {
      $cookie_vals->{'hotspot_userurl'} = "http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/$ENV{REQUEST_URI}";
    }

    if ($FORM{sid}) {
      $cookie_vals->{'sid'} = $FORM{sid};
    }
    if ($FORM{mac}) {
      $cookie_vals->{'mac'} = $FORM{mac};
    }

    if ($FORM{link_login_only}) {
      $cookie_vals->{'link_login'} = $FORM{link_login_only};
    }

    if ($FORM{server_name}) {
      $cookie_vals->{'server_name'} = $FORM{server_name};
    }
  }

  my $cookies_time = ($attr->{COOKIE_TIME}) ? $attr->{COOKIE_TIME} : gmtime(time() + $auth_cookie_time) . " GMT";
  foreach my $key (keys %$cookie_vals) {
    $html->set_cookies($key, $cookie_vals->{$key}, $cookies_time, $html->{web_path});
  }

  return 1;
}

#**********************************************************
=head2 get_language_flags_list(\%LANG)

=cut
#**********************************************************
sub get_language_flags_list {
  my ($languages) = @_;
  my $result = '';
  my $href_base = "$SELF_URL?&NAS_ID=" . ($FORM{NAS_ID} || '') . "&DOMAIN_ID=" . ($FORM{DOMAIN_ID} || '');

  for my $name (sort keys %$languages) {
    my $short_name = uc(substr($name, 0, 2));
    $result .= qq{
      <li>
        <a href="$href_base&language=$name"><img src='/styles/default/img/flags/$name.png' alt='$name'/>&nbsp;$short_name</a>
      </li>
    }
  }

  return $result;
}

#**********************************************************
=head2 _send_pin(phone, pin)

=cut
#**********************************************************
sub _call_pin {
  my ($attr) = @_;

  my $result = cmd("/usr/axbills/AXbills/modules/Hotspot/call.sh %PHONE% %PIN%", { SHOW_RESULT => 1, PARAMS => { PHONE => $attr->{phone}, PIN => $attr->{pin} } });

  return 1;
}

#**********************************************************
=head2 _send_sms_with_pin($attr)

=cut
#**********************************************************
sub _send_sms_with_pin {
  my ($attr) = @_;

  if (in_array('Sms', \@MODULES)) {
    load_module('Sms', $html);
    my $message = "Пин код: $attr->{password}";
    my $phone = $PHONE_PREFIX . $attr->{phone};
    my $sms = Sms->new($db, $admin, \%conf);
    my $phone_sms_list = $sms->list({
      SMS_PHONE => $conf{SMS_NUMBER_EXPR} ? _expr($phone, $conf{SMS_NUMBER_EXPR}) : $phone,
      INTERVAL  => "$DATE/$DATE",
    });
    if ($phone_sms_list && scalar(@$phone_sms_list) >= 3) {
      $html->message('err', $lang{ERROR}, "Too many SMS on this number.", { ID => 1540 });
      if ($conf{HOTSPOT_LOG}) {
        $Log->log_print('LOG_ERR', $attr->{login}, "Too many SMS on $attr->{phone}, rejected.", { LOG_FILE => "$conf{HOTSPOT_LOG}" });
      }

      return 0;
    }

    # my $uid_sms_list = $sms->list({ 
    # UID      => $attr->{uid},
    # INTERVAL => "$DATE/$DATE",
    # });
    # _bp('uid', $uid_sms_list, {HEADER => 1});
    # if ( $uid_sms_list && scalar(@$uid_sms_list) >= 3 ) {
    # $html->message( 'err', $lang{ERROR}, "Превышен лимит СМС для этого пользователя" );
    # return 0;
    # }

    sms_send({
      NUMBER     => $phone,
      MESSAGE    => $message,
      UID        => $attr->{uid},
      RIZE_ERROR => 1,
    });
  }
  else {
    if ($conf{HOTSPOT_LOG}) {
      $Log->log_print('LOG_ERR', $attr->{login}, "No SMS module, can't send pin!", { LOG_FILE => "$conf{HOTSPOT_LOG}" });
    }
    $html->message('err', $lang{ERROR}, "Sorry, can't send SMS", { ID => 1541 });
  }
  return 1;
}

#**********************************************************
=head2 fast_login()

=cut
#**********************************************************
sub fast_login {

  if ($FORM{error}) {
    if ($FORM{error} =~ /USER_NOT_EXIST/) {
      mk_cookie({
        hotspot_username => '',
        hotspot_password => '',
      },
        { COOKIE_TIME => gmtime(time() - $auth_cookie_time) . " GMT" }
      );
      print "Location: $FORM{link_login_only}\n\n";
      exit 1;
    }
    elsif ($conf{HOTSPOT_USER_PORTAL} && $COOKIES{hotspot_username} && $COOKIES{hotspot_password}) {
      my $user_portal_url = $SELF_URL;
      $user_portal_url =~ s/start/index/;
      $user_portal_url .= "?user=$COOKIES{hotspot_username}&passwd=$COOKIES{hotspot_password}";
      print "Location: $user_portal_url\n\n";
      exit 1;
    }
    elsif ($conf{HOTSPOT_USE_PIN}) {
      #ask user for card pin
      #TODO: filter errors
      print $html->header();
      my $use_card_tpl = advert_page('use_card_tpl') || 'form_client_hotspot_use_card';
      print $html->tpl_show(templates($use_card_tpl), \%FORM);
      exit;
    }
    elsif ($FORM{error} =~ /NEG_DEPOSIT/) {
      my $list = $Internet->user_list({
        LOGIN     => ($COOKIES{hotspot_username} || $FORM{username}),
        UID       => '_SHOW',

        COLS_NAME => 1,
      });
      my $Tariffs = Tariffs->new($db, \%conf, $admin);
      $Tariffs->info(undef, { ID => $list->[0]->{tp_id} });
      $FORM{TP_ID} = $Tariffs->{TP_ID};
      $FORM{recharge} = 1;
      $FORM{BUY_CARDS} = 1;
      $FORM{SUM} = 1;
      $FORM{UID} = $list->[0]->{uid};
    }
    else {
      mk_cookie({
        hotspot_username => '',
        hotspot_password => '',
      },
        { COOKIE_TIME => gmtime(time() - $auth_cookie_time) . " GMT" }
      );
      print $html->header();
      print $html->message('err', $lang{ERROR}, $FORM{error}, { ID => 1529 });
      exit;
    }
  }

  if ($FORM{CARD_NUM}) {
    #user use recharge card, proceed
    my $result = hotspot_card({
      PIN     => $FORM{CARD_NUM},
      LOGIN   => ($FORM{username} || $COOKIES{hotspot_username}),
      HOTSPOT => ($FORM{server_name} || $COOKIES{server_name}),
    });

    if ($result) {
      $Hotspot->log_add({
        HOTSPOT  => $COOKIES{server_name},
        CID      => $FORM{mac},
        ACTION   => 4,
        COMMENTS => "User:$COOKIES{hotspot_username} use pin:$FORM{CARD_NUM}",
      });
      print $html->header();
      print $html->message('info', $lang{ICARD} . ' ' . $lang{USED}, $result, { ID => 1535 });
    }
  }

  if ($FORM{TRUE}) {
    # Online payment success, looking for confirm
    if (!$FORM{OPERATION_ID}) {
      delete $FORM{TRUE};
    }
    else {
      load_module('Paysys', $html);
      unless (paysys_show_result({ TRANSACTION_ID => $FORM{OPERATION_ID} })) {
        print $html->header();
        print $html->{OUTPUT};
        exit;
      }
    }
  }

  if ($FORM{external_auth_failed}) {
    print $html->header();
    print $html->message('err', $lang{ERROR}, $lang{ERR_SN_ERROR}, { ID => 1536 });
    exit;
  }

  $FORM{mac} = $FORM{mac} || $COOKIES{mac} || '';
  if ($FORM{mac} !~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/) {
    print $html->header();
    print $html->message('err', $lang{ERROR}, "ERR_WRONG_MAC_FORMAT", { ID => 1537 });
    exit;
  }

  $FORM{DST} = $conf{HOTSPOT_REDIRECT_URL} || 'https://www.google.com';

  #===== CHECK PHONE =====
  if ($conf{HOTSPOT_CHECK_PHONE}) {
    my $hot_log = $Hotspot->log_list({
      CID       => $FORM{mac},
      INTERVAL  => "$DATE/$DATE",
      ACTION    => 12,
      PHONE     => '_SHOW',
      COLS_NAME => 1,
    });

    if ($Hotspot->{TOTAL} > 0) {
      #User with this mac already virifed phone today.
      $FORM{PHONE} = $hot_log->[0]->{phone};
      if ($conf{HOTSPOT_MAC_CHANGE} && $FORM{PHONE} && $FORM{mac}) {
        change_user_mac();
      }
      $FORM{'3.PHONE'} = $FORM{PHONE};
    }
    else {
      phone_verifycation();
    }
  }

  if ($FORM{recharge}) {
    # Online payment proceed
    my $output = buy_cards();
    print $html->header();
    print $output;
    exit;
  }

  #===== SHOW FB PAGE =====
  if ($conf{HOTSPOT_SHOW_FB} && $FORM{external_auth}) {
    $FORM{FACEBOOK} = $FORM{'3._FACEBOOK'} || '';
    $FORM{EMAIL} = $FORM{'3.EMAIL'} || '';
    $FORM{FIO} = $FORM{'3.FIO'} || '';
    my $encoded_url = urlencode($conf{HOTSPOT_SHOW_FB});
    #FB page widget
    print $html->header();
    print "<iframe 
            src='https://www.facebook.com/plugins/page.php?href=$encoded_url&width=340&height=214&small_header=false&adapt_container_width=true&hide_cover=false&show_facepile=true&appId=$conf{AUTH_FACEBOOK_ID}'
            width='340' 
            height='214' 
            style='border:none;overflow:hidden' 
            scrolling='no' 
            frameborder='0' 
            allowTransparency='true'>
          </iframe>";

    #FB like button    
    # print "<iframe 
    # src='https://www.facebook.com/plugins/like.php?href=$encoded_url&width=450&layout=standard&action=like&size=large&show_faces=true&share=false&height=80&appId=$conf{AUTH_FACEBOOK_ID}'
    # width='450'
    # height='80'
    # style='border:none;overflow:hidden'
    # scrolling='no'
    # frameborder='0'
    # allowTransparency='true'>
    # </iframe>";

    print $html->tpl_show(templates('hotspot_fb_like'), \%FORM);
    exit;
  }

  #===== COOKIES =====
  if ($COOKIES{hotspot_username} && $COOKIES{hotspot_password}) {
    if ($conf{HOTSPOT_LOG}) {
      $Log->log_print('LOG_INFO', $COOKIES{hotspot_username}, "Cookie $COOKIES{hotspot_password}", { LOG_FILE => "$conf{HOTSPOT_LOG}" });
    }

    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 3,
      COMMENTS => "User:$COOKIES{hotspot_username} cookies login"
    });
    mikrotik_login({ LOGIN => $COOKIES{hotspot_username}, PASSWORD => $COOKIES{hotspot_password} });
    exit;
  }

    #===== AUTH =====
  if ($conf{HOTSPOT_ONE_LOGIN_FOR_ALL}) {
    my ($login, $password) = split(/:/, $conf{HOTSPOT_ONE_LOGIN_FOR_ALL});
    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 3,
      COMMENTS => "User:$login($FORM{mac}) auto login"
    });
    mikrotik_login({ LOGIN => $login, PASSWORD => $password });
    exit;
  }
  elsif ($conf{HOTSPOT_PHONE_LOGIN} && $FORM{PHONE}) {
    phone_login();
  }
  elsif ($conf{HOTSPOT_MAC_LOGIN} && $FORM{mac}) {
    fast_mac_login();
  }
  elsif ($conf{PASSWD_LOGIN}) {
    print $html->header();
    print $html->tpl_show(templates('hotspot_passwd_login'), {
      DST                => redirect_page(),
      HOTSPOT_AUTO_LOGIN => $COOKIES{link_login} || $conf{HOTSPOT_AUTO_LOGIN},
    });
    exit;
  }
  elsif ($conf{HOTSPOT_SN_LOGIN}) {
    #new FB user, go to registration
  }
  else {
    #TODO Universal form
    print $html->header();
    print $html->message('warn', $lang{WARNING}, "Under construction.", { ID => 1538 });
    exit;
  }

  #===== BUY CARDS =====
  if ($conf{HOTSPOT_BUY_CARDS}) {
    if (!$FORM{TRUE}) {
      my $hot_log = $Hotspot->log_list({
        CID       => $FORM{mac},
        INTERVAL  => "$DATE/$DATE",
        ACTION    => 21,
        PHONE     => $FORM{PHONE},
        COMMENTS  => '_SHOW',
        COLS_NAME => 1,
      });
      if ($Hotspot->{TOTAL} > 0) {
        my ($op_id) = $hot_log->[0]->{comments} =~ m/op_id\:\'(.*)\'/;
        require Paysys;
        my $Paysys = Paysys->new($db, $admin, \%conf);
        my $list = $Paysys->list({
          TRANSACTION_ID => "*:$op_id",
          STATUS         => 2,
          SKIP_DEL_CHECK => 1,
          COLS_NAME      => 1,
          COLS_UPPER     => 1,
        });
        if ($Paysys->{TOTAL} > 0) {
          $FORM{TRUE} = 1;
          $FORM{OPERATION_ID} = $list->[0]->{TRANSACTION_ID};
        }
      }
    }

    if ($FORM{TRUE}) {
      $conf{HOTSPOT_REGISTRATION} = 'YES';
    }
    else {
      # Online payment proceed
      $INFO_HASH{PHONE} = $FORM{PHONE};
      my $output = buy_cards();
      print $html->header();
      print $output;

      if ($FORM{OPERATION_ID}) {
        $Hotspot->log_add({
          HOTSPOT  => $COOKIES{server_name},
          CID      => $FORM{mac},
          PHONE    => $FORM{PHONE},
          ACTION   => 21,
          COMMENTS => "New user initiate online payment op_id:'$FORM{OPERATION_ID}' tp_id:$FORM{TP_ID}",
        });
      }
      exit;
    }
  }

  #===== REGISTRATION =====
  if ($conf{HOTSPOT_REGISTRATION} && $conf{HOTSPOT_REGISTRATION} eq 'NO') {
    print $html->header();
    print $html->message('warn', $lang{WARNING}, "Registration not allowed.", { ID => 1539 });
    exit;
  }

  hotspot_registration();
  exit;
}

#**********************************************************
=head2 hotspot_registration()
  Add new user, save cookies and redirect to login page.
=cut
#**********************************************************
sub hotspot_registration {
  my $Tariffs = Tariffs->new($db, \%conf, $admin);

  if ($FORM{TRUE}) {
    # Online payments success.
    unless ($FORM{TP_ID} && $FORM{'3.PHONE'}) {
      my $hot_log = $Hotspot->log_list({
        CID       => $FORM{mac},
        INTERVAL  => "$DATE/$DATE",
        ACTION    => 21,
        PHONE     => '_SHOW',
        COMMENTS  => '_SHOW',
        COLS_NAME => 1,
      });

      if ($Hotspot->{TOTAL} > 0) {
        ($FORM{TP_ID}) = $hot_log->[0]->{comments} =~ m/tp_id\:(\d+)/;
        $FORM{"3.PHONE"} = $hot_log->[0]->{phone};
      }
    }
    $Tariffs->info($FORM{TP_ID});
    $FORM{'4.TP_ID'} = $Tariffs->{TP_ID};
    $FORM{'5.SUM'} = $Tariffs->{ACTIV_PRICE} || $FORM{PAYSYS_SUM};
    $FORM{'5.DESCRIBE'} = ($FORM{SYSTEM_SHORT_NAME} || q{}) . "# $FORM{OPERATION_ID}";
    $FORM{'5.EXT_ID'} = ($FORM{SYSTEM_SHORT_NAME} || q{}) . ":$FORM{OPERATION_ID}";
    $FORM{'5.METHOD'} = 2;
  }
  elsif ($conf{HOTSPOT_TPS}) {
    my ($tp_id) = split('\,', $conf{HOTSPOT_TPS});
    $Tariffs->info('', { ID => $tp_id });
    $FORM{'4.TP_ID'} = $Tariffs->{TP_ID};
  }
  else {
    my $tp_list = $Tariffs->list({
      TP_ID        => '_SHOW',
      PAGE_ROWS    => 1,
      SORT         => 1,
      NAME         => '_SHOW',
      DOMAIN_ID    => $DOMAIN_ID,
      MODULE       => 'Internet',
      PAYMENT_TYPE => 2,
      COLS_NAME    => 1,
      NEW_MODEL_TP => 1,
    });

    if ($Tariffs->{TOTAL} < 1) {
      print $html->header();
      print $html->message('err', $lang{ERROR}, "ERR_NO_GUEST_TP", { ID => 1545 });
      exit;
    }

    $FORM{'4.TP_ID'} = $tp_list->[0]->{tp_id};
    $FORM{'4.REGISTRATION'}=1;
    `echo "> TP_ID: $FORM{'4.TP_ID'} //" >> /usr/axbills/cgi-bin/hotspot_debug.log`;
  }

  $FORM{create} = 1;
  $FORM{COUNT} = 1;
  $FORM{SERIAL} = 'G';
  $FORM{PASSWD_LENGTH} = 6;
  $FORM{LOGIN_LENGTH} = $conf{HOTSPOT_LOGIN_LENGTH} || 6;
  $FORM{LOGIN_PREFIX} = $conf{HOTSPOT_LOGIN_PREFIX} || '';

  load_module('Cards', $html);
  my $return = cards_users_add({ NO_PRINT => 1 });
  $FORM{add} = 1;

  $FORM{'1.LOGIN'} = $return->[0]->{LOGIN};
  $FORM{'1.PASSWORD'} = $return->[0]->{PASSWORD};
  $FORM{'4.CID'} = $FORM{mac};
  $FORM{'1.CREATE_BILL'} = 1;

  if ($conf{HOTSPOT_PHONE_LOGIN}) {
    $FORM{'4.CID'} = 'ANY';
  }

  if ($conf{HOTSPOT_GUESTS_GROUP} && $conf{HOTSPOT_GUESTS_GID}) {
    my $group_name = $conf{HOTSPOT_GUESTS_GROUP} . '_' . $DOMAIN_ID;
    my $group_id = $conf{HOTSPOT_GUESTS_GID} + $DOMAIN_ID;
    $user->group_info($group_id);
    if ($user->{errno}) {
      $user->group_add({ GID => $group_id, NAME => $group_name, DESCR => 'Hotspot guest group' });
    }
    $FORM{'1.GID'} = $group_id;
  }

  load_module('Internet', $html);
  $return->[0]->{UID} = internet_wizard_add({ SHORT_REPORT => 1, %FORM });

  `echo "TP_ID: $FORM{'4.TP_ID'} // UID: $return->[0]->{UID}" >> /usr/axbills/cgi-bin/hotspot_debug.log`;

  if ($conf{HOTSPOT_LOG}) {
    $Log->log_print('LOG_INFO', $return->[0]->{LOGIN}, "New guest account create. UID:$return->[0]->{UID}", { LOG_FILE => "$conf{HOTSPOT_LOG}" });
  }

  #Confim card creation
  cards_users_gen_confim({ %{$return->[0]}, SUM => 0 });

  $Hotspot->log_add({
    HOTSPOT  => $COOKIES{server_name},
    CID      => $FORM{mac},
    ACTION   => 1,
    PHONE    => $FORM{PHONE} || '',
    COMMENTS => "$return->[0]->{LOGIN} registred, UID:$return->[0]->{UID}"
  });

  mikrotik_login({ LOGIN => $return->[0]->{LOGIN}, PASSWORD => $return->[0]->{PASSWORD} });

  exit;
}

#**********************************************************
=head2 fast_mac_login()
  Search user with CID = $FORM(mac) and redirect to 
  Hotspot login page.
=cut
#**********************************************************
sub fast_mac_login {
  if ($FORM{mac} !~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/) {
    print $html->header();
    print $html->message('err', $lang{ERROR}, "Wrong MAC format.", { ID => 1546 });
    exit;
  }

  my $list = $Internet->user_list({
    PASSWORD       => '_SHOW',
    LOGIN          => '_SHOW',
    PHONE          => '_SHOW',
    SERVICE_EXPIRE => "0000-00-00,>$DATE",
    CID            => $FORM{mac},
    $conf{HOTSPOT_TPS} ? (TP_NUM => $conf{HOTSPOT_TPS}) : (PAYMENT_TYPE => 2),
    COLS_NAME      => 1,
  });

  if ($Internet->{TOTAL} > 0) {
    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 2,
      PHONE    => $FORM{PHONE} || $list->[0]->{phone},
      COMMENTS => "$list->[0]->{login} $FORM{mac} MAC login"
    });

    if ($conf{HOTSPOT_LOG}) {
      $Log->log_print('LOG_INFO', $list->[0]->{login}, "$FORM{mac} MAC login", { LOG_FILE => "$conf{HOTSPOT_LOG}" });
    }

    mikrotik_login({ LOGIN => $list->[0]->{login}, PASSWORD => $list->[0]->{password} });
    exit;
  }
  return 1;
}

#**********************************************************
=head2 phone_login()
  Search user with PHONE = $FORM{PHONE} and redirect to 
  Hotspot login page.
=cut
#**********************************************************
sub phone_login {

  if ($FORM{PHONE} !~ /^\+?[0-9]+$/) {
    print $html->header();
    print $html->message('err', $lang{ERROR}, "Wrong PHONE.", { ID => 1547 });
    exit;
  }

  my $list = $Internet->user_list({
    PASSWORD       => '_SHOW',
    LOGIN          => '_SHOW',
    PHONE          => $FORM{PHONE},
    SERVICE_EXPIRE => "0000-00-00,>$DATE",
    ($conf{HOTSPOT_TPS} ? (TP_NUM => $conf{HOTSPOT_TPS}) : (PAYMENT_TYPE => 2)),
    COLS_NAME      => 1,
  });

  if ($Internet->{TOTAL} > 0) {
    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 5,
      PHONE    => $FORM{PHONE},
      COMMENTS => "$list->[0]->{login} $FORM{PHONE} PHONE login"
    });

    if ($conf{HOTSPOT_LOG}) {
      $Log->log_print('LOG_INFO', $list->[0]->{login}, "$FORM{PHONE} PHONE login", { LOG_FILE => $conf{HOTSPOT_LOG} });
    }

    mikrotik_login({ LOGIN => $list->[0]->{login}, PASSWORD => $list->[0]->{password} });

    exit;
  }

  return 1;
}

#**********************************************************
=head2 redirect_page()
  Page for redirect after success login.
=cut
#**********************************************************
sub redirect_page {
  my $dst = $conf{HOTSPOT_REDIRECT_URL} || 'https://www.google.com';;
  if ($COOKIES{server_name}) {
    my $pages_list = $Hotspot->advert_pages_list({
      HOSTNAME  => $COOKIES{server_name},
      ACTION    => 'redirect',
      PAGE      => '_SHOW',

      COLS_NAME => 1,
    });
    if (ref($pages_list) eq 'ARRAY' && scalar($pages_list) > 0) {
      $dst = $pages_list->[0]->{page} || $conf{HOTSPOT_REDIRECT_URL} || 'https://www.google.com';
    }
  }

  return $dst;
}

#**********************************************************
=head2 phone_verifycation() - Ask phone, send pin code, and wait for confirm.


=cut
#**********************************************************
sub phone_verifycation {

  my $phone_tpl = advert_page('phone');
  my $phone_replace_tpl = advert_page('phone_replace');
  my $auth_tpl = advert_page('call_auth');
  my $auth_replace_tpl = advert_page('call_auth_replace');

  if ($FORM{PHONE} && $conf{PHONE_FORMAT} && $FORM{PHONE} !~ /$conf{PHONE_FORMAT}/) {
    print $html->header();
    print $html->message('err', $lang{ERROR}, "WRONG_PHONE_FORMAT " . human_exp($conf{PHONE_FORMAT}), { ID => 1548 });
    _error_show({ errno => 21, err_str => 'ERR_WRONG_PHONE', MESSAGE => human_exp($conf{PHONE_FORMAT}) }, { ID => 1505 });

    if ($phone_replace_tpl) {
      print $html->tpl_show(templates($phone_replace_tpl), \%FORM);
    }
    else {
      print $html->tpl_show(templates($phone_tpl)) if ($phone_tpl);
      print $html->tpl_show(templates('form_client_hotspot_phone'), \%FORM);
    }

    exit;
  }

  if (!$FORM{PHONE}) {
    print $html->header();
    if ($phone_replace_tpl) {
      print $html->tpl_show(templates($phone_replace_tpl), \%FORM);
    }
    else {
      print $html->tpl_show(templates($phone_tpl)) if ($phone_tpl);
      print $html->tpl_show(templates('form_client_hotspot_phone'), \%FORM);
    }
    exit;
  }
  elsif ($conf{HOTSPOT_AUTH_NUMBER}) {
    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 11,
      PHONE    => $FORM{PHONE},
      COMMENTS => "Waiting for client call."
    });
    my $reload_btn = $html->button($lang{CONTINUE}, '',
      { GLOBAL_URL => "$COOKIES{link_login}", class => 'btn btn-success' });
    print $html->header();
    if ($auth_replace_tpl) {
      print $html->tpl_show(templates($auth_replace_tpl), {
        AUTH_NUMBER => $conf{HOTSPOT_AUTH_NUMBER},
        mac         => $FORM{mac},
        PHONE       => $FORM{PHONE},
        BUTTON      => $reload_btn,
      });
    }
    else {
      print $html->tpl_show(templates($auth_tpl)) if ($auth_tpl);
      print $html->tpl_show(templates('form_client_hotspot_call_auth'), {
        AUTH_NUMBER => $conf{HOTSPOT_AUTH_NUMBER},
        mac         => $FORM{mac},
        PHONE       => $FORM{PHONE},
        BUTTON      => $reload_btn,
      });
    }
    exit;
  }
  elsif (!$FORM{PIN}) {
    $Hotspot->log_list({
      PHONE     => $FORM{PHONE},
      CID       => $FORM{mac},
      INTERVAL  => "$DATE/$DATE",
      ACTION    => 11,
      COMMENTS  => '_SHOW',
      COLS_NAME => 1,
    });

    my $pin = '42';
    if ($Hotspot->{TOTAL} < 1 || $FORM{send_pin}) {
      $pin = int(rand(900)) + 100;
      if ($conf{HOTSPOT_SEND_PIN} && $conf{HOTSPOT_SEND_PIN} eq 'CALL') {
        _call_pin({
          pin   => $pin,
          phone => $FORM{PHONE}
        });
      }
      else {
        _send_sms_with_pin({
          password => $pin,
          phone    => $FORM{PHONE}
        });
      }

      $Hotspot->log_add({
        HOTSPOT  => $COOKIES{server_name},
        CID      => $FORM{mac},
        ACTION   => 11,
        PHONE    => $FORM{PHONE},
        COMMENTS => "Send PIN: $pin"
      });
    }
    print $html->header();
    print $html->tpl_show(templates('form_client_hotspot_pin'), \%FORM);

    exit;
  }
  else {
    my $hot_log = $Hotspot->log_list({
      PHONE     => $FORM{PHONE},
      INTERVAL  => "$DATE/$DATE",
      ACTION    => 11,
      COMMENTS  => '_SHOW',
      COLS_NAME => 1,
    });

    if (($Hotspot->{TOTAL} > 0) && ($hot_log->[0]->{comments} eq "Send PIN: $FORM{PIN}")) {
      $Hotspot->log_add({
        HOTSPOT  => $COOKIES{server_name},
        CID      => $FORM{mac},
        ACTION   => 12,
        PHONE    => $FORM{PHONE},
        COMMENTS => 'Phone confirmed.'
      });
      if ($conf{HOTSPOT_MAC_CHANGE} && $FORM{PHONE} && $FORM{mac}) {
        change_user_mac();
      }
      $FORM{'3.PHONE'} = $PHONE_PREFIX . $FORM{PHONE};
    }
    else {
      if ($conf{HOTSPOT_LOG}) {
        $Log->log_print('LOG_ERR', $FORM{PHONE}, "Do not confirmed, wrong pin $FORM{PIN}, $hot_log->[0]->{comments}.", { LOG_FILE => "$conf{HOTSPOT_LOG}" });
      }
      my $button = $html->button("Remind PIN",
        "&send_pin=1&PHONE=$FORM{PHONE}&mac=$FORM{mac}",
        { class => 'btn btn-secondary btn-xs' }
      );
      print $html->header();
      print $html->message('err', $lang{ERROR}, "Wrong pin. $button", { ID => 1549 });
      print $html->tpl_show(templates('form_client_hotspot_pin'), \%FORM);
      exit;
    }
  }
  return 1;
}

#**********************************************************
=head2 advert_page()
  Custom page for hotspot.
=cut
#**********************************************************
sub advert_page {
  my ($action) = @_;

  my $page = '';
  return $page unless ($COOKIES{server_name});

  my $pages_list = $Hotspot->advert_pages_list({
    HOSTNAME  => $COOKIES{server_name},
    ACTION    => $action,
    PAGE      => '_SHOW',

    COLS_NAME => 1,
  });

  if (ref($pages_list) eq 'ARRAY' && scalar($pages_list) > 0) {
    $page = $pages_list->[0]->{page};
  }

  return $page;
}

#**********************************************************
=head2 hotspot_card() -  Use card

  Arguments:
    $attr

=cut
#**********************************************************
sub hotspot_card {
  my ($attr) = @_;
  my @status = ($lang{ENABLE}, $lang{DISABLE}, $lang{USED}, $lang{DELETED}, $lang{RETURNED}, $lang{PROCESSING});
  use Cards;
  use Payments;
  $Cards = Cards->new($db, $admin, \%conf);
  my $payments = Payments->new($db, $admin, \%conf);
  my $diller = advert_page('diller_id');
  my DBI $_db = $db->{db};
  $_db->{AutoCommit} = 0;
  print $html->header();
  $user->info(undef, { LOGIN => $attr->{LOGIN}, DOMAIN_ID => $admin->{DOMAIN_ID} });
  my $BRUTE_LIMIT = ($conf{CARDS_BRUTE_LIMIT}) ? $conf{CARDS_BRUTE_LIMIT} : 5;
  $Cards->bruteforce_list({ UID => $user->{UID} });
  if ($Cards->{BRUTE_COUNT} && $Cards->{BRUTE_COUNT} >= $BRUTE_LIMIT) {
    print $html->message('err', $lang{ERROR}, "$lang{BRUTE_ATACK} $Cards->{BRUTE_COUNT}) >= $BRUTE_LIMIT", { ID => 601 });
    return 0;
  }

  $Cards->cards_info({ PIN => $attr->{PIN}, DILLER_ID => $diller });

  if ($Cards->{errno}) {
    if ($Cards->{errno} == 2) {
      $Cards->bruteforce_add({ UID => $user->{UID}, PIN => $attr->{PIN} });
      $_db->commit();
    }
    print $html->message('err', $lang{ERROR}, $Cards->{errstr}, { ID => 1561 });
    return 0;
  }
  elsif ($Cards->{EXPIRE_STATUS} == 1) {
    print $html->message('err', $lang{ERROR}, "$lang{EXPIRE} '$Cards->{EXPIRE}'", { ID => 1562 });
    return 0;
  }
  elsif ($Cards->{STATUS} != 0) {
    if ($Cards->{STATUS} == 5) {
      $html->message('info', $lang{INFO}, $status[$Cards->{STATUS}], { ID => 1565 });
    }
    else {
      $html->message('err', $lang{ERROR}, "$status[$Cards->{STATUS}]", { ID => 1566 });
    }
    return 0;
  }
  else {

    $payments->add(
      $user,
      {
        SUM          => $Cards->{SUM},
        METHOD       => 2,
        DESCRIBE     => "$Cards->{SERIAL}$Cards->{NUMBER}",
        EXT_ID       => "$Cards->{SERIAL}$Cards->{NUMBER}",
        CHECK_EXT_ID => "$Cards->{SERIAL}$Cards->{NUMBER}",
        TRANSACTION  => 1
      }
    );

    if (!$payments->{errno}) {
      $user->{DEPOSIT} += $Cards->{SUM} - $Cards->{COMMISSION};

      $Cards->cards_change(
        {
          ID       => $Cards->{ID},
          STATUS   => 2,
          UID      => $user->{UID},
          DATETIME => "$DATE $TIME",
        }
      );

      if ($Cards->{errno}) {
        $_db->rollback();
        $html->message('err', $lang{ERROR}, "$status[$Cards->{STATUS}]", { ID => 1567 });
        return 0;
      }

      $html->message('info', $lang{PAYMENTS}, "$lang{ADDED}\n$lang{SUM}: $Cards->{SUM} \n");

      use Dillers;
      my $Diller = Dillers->new($db, $admin, \%conf);
      $Diller->diller_info({ ID => $Cards->{DILLER_ID} });
      my $diller_fees = 0;
      if ($Diller->{PAYMENT_TYPE} == 2 && $Diller->{OPERATION_PAYMENT} > 0) {
        $diller_fees = $Cards->{SUM} / 100 * $Diller->{OPERATION_PAYMENT};
      }
      elsif ($Diller->{DILLER_PERCENTAGE} > 0) {
        $diller_fees = $Diller->{DILLER_PERCENTAGE};
      }

      if ($diller_fees > 0) {
        my $user_new = Users->new($db, $admin, \%conf);
        $user_new->info($Diller->{UID});

        my $Fees = Finance->fees($db, $admin, \%conf);
        $Fees->take(
          $user_new,
          $diller_fees,
          {
            DESCRIBE => "CARD_ACTIVATE: $Cards->{ID}",
            METHOD   => 0,
          }
        );
      }
    }

    $payments->list({ EXT_ID => "$Cards->{SERIAL}$Cards->{NUMBER}" });
    if ($payments->{TOTAL} <= 1) {
      $_db->commit();
    }

    $_db->{AutoCommit} = 1;
    cross_modules('payments_maked', {
      USER_INFO    => $user,
      SUM          => $Cards->{SUM},
      SKIP_MODULES => 'Cards,Sqlcmd',
      QUITE        => 1,
      SILENT       => 1,
      METHOD       => 2
    });
    return $Cards->{NUMBER};
  }

}

#**********************************************************
=head2 check_auth()

=cut
#**********************************************************
sub check_auth {
  $Hotspot->log_list({
    PHONE     => $FORM{PHONE},
    CID       => $FORM{mac},
    INTERVAL  => "$DATE/$DATE",
    ACTION    => 12,
    COMMENTS  => '_SHOW',
    COLS_NAME => 1,
  });

  print "Content-Type: text/html\n\n";
  if ($Hotspot->{TOTAL} < 1) {
    print 0;
  }
  else {
    print 1;
  }
  return 1;
}

#**********************************************************
=head2 change_user_mac()
    Update MAC for existing user.
=cut
#**********************************************************
sub change_user_mac {
  my $list = $Internet->user_list({
    LOGIN          => '_SHOW',
    UID            => '_SHOW',
    PHONE          => $FORM{PHONE},
    CID            => '_SHOW',
    SERVICE_EXPIRE => "0000-00-00,>$DATE",
    ($conf{HOTSPOT_TPS} ? (TP_NUM => $conf{HOTSPOT_TPS}) : (PAYMENT_TYPE => 2)),
    COLS_NAME      => 1,
  });

  if ($Internet->{TOTAL} > 0 && $list->[0]->{cid} ne $FORM{mac}) {
    $Internet->user_change({
      UID => $list->[0]->{uid},
      CID => $FORM{mac},
    });
  }
  return 1;
}

#**********************************************************
=head2 mikrotik_login($attr)

  Arguments:
    $attr
      LOGIN
      PASSWORD

  Results:

=cut
#**********************************************************
sub mikrotik_login {
  my ($attr) = @_;
  my $tpl = 'hotspot_auto_login';
  my $ad_to_show = ();

  mk_cookie({
    hotspot_username => $attr->{LOGIN},
    hotspot_password => $attr->{PASSWORD},
  });

  if ($conf{HOTSPOT_SHOW_AD}) {
    $ad_to_show = $Hotspot->request_random_ad({ COLS_NAME => 1 });
    my $user_info = $users->list({
      LOGIN     => $attr->{LOGIN},
      COLS_NAME => 1,
    });

    my $tp_info = $Internet->user_info($user_info->[0]->{uid});

    my @show_tp = split(';', ($conf{HOTSPOT_AD_TP_IDS} || ''));
    if ($ad_to_show->{id} && in_array($tp_info->{TP_ID}, \@show_tp)) {
      $Hotspot->advert_shows_add({ AD_ID => $ad_to_show->{id} });

      $tpl = 'hotspot_auto_login_advertisement';
    }
  }

  print $html->header();
  print $html->tpl_show(templates($tpl), {
    LOGIN              => $attr->{LOGIN},
    PASSWORD           => $attr->{PASSWORD},
    HOTSPOT_AUTO_LOGIN => $COOKIES{link_login} || '1',
    TIME               => $conf{HOTSPOT_AD_SHOW_TIME} || 10,
    ADVERTISEMENT      => $ad_to_show->{url} || '',
  });

  return 1;
}

1;
