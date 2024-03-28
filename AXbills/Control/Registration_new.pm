package Control::Registration_new;
=head1 NAME

   New Registration logic

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(in_array);
use AXbills::Filters qw(_utf8_encode);
use Control::Registration_mng;

my AXbills::HTML $html;
my Users $Users;
my Control::Registration_mng $Registration_mng;

my (%lang, %conf, %params, %patterns);

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db        => $db,
    admin     => $admin,
    conf      => $conf,
  };

  %lang = %{$attr->{lang} || {}};
  %conf = %{$conf || {}};
  $html = $attr->{html};
  $Users = $attr->{users};

  $Registration_mng = Control::Registration_mng->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang, is_portal => 1 });

  bless($self, $class);

  my $pass_symbols = $conf{PASSWD_SYMBOLS} || "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ";
  $patterns{PHONE_NUMBER_PATTERN} = $conf{PHONE_NUMBER_PATTERN} || '';
  $patterns{LOGIN_PATTERN} = $conf{USERNAMEREGEXP} || "^[a-z0-9_][a-z0-9_-]*\$";
  $patterns{LOGIN_MAX_LENGTH} = $conf{MAX_USERNAME_LENGTH} || 15;
  $patterns{PASSWORD_PATTERN} = "^[$pass_symbols]+\$";
  $patterns{PASSWORD_MIN_LENGTH} = $conf{PASSWD_LENGTH} || 6;

  return $self;
}

#**********************************************************
=head2 _start()

=cut
#**********************************************************
sub _start {
  my $self = shift;
  my ($attr) = @_;

  $attr->{external_auth} = 'Apple' if ($conf{AUTH_APPLE_ID} && $ENV{QUERY_STRING} && $ENV{QUERY_STRING} =~ /external_auth=Apple/);
  $attr->{USER_IP} //= $ENV{REMOTE_ADDR} if ($conf{REGISTRATION_IP} && $conf{REGISTRATION_DEFAULT_TP});

  if ($conf{GOOGLE_CAPTCHA_KEY}) {
    $params{CAPTCHA} = qq{
      <script>function onSubmit() { jQuery('form').submit(); } </script>
      <script src='https://www.google.com/recaptcha/api.js'></script>
    };
    $params{CAPTCHA_BTN} = "data-sitekey='$conf{GOOGLE_CAPTCHA_KEY}' data-callback='onSubmit' data-action='submit'";
  }

  my %extra_params = ();

  $attr->{PASSWORD} = $attr->{newpassword} if ($attr->{newpassword});
  if ($attr->{FORGOT_PASSWD} || $attr->{CHANGE_PASSWORD}) {
    my $result = $self->password_recovery($attr);
    $extra_params{redirect} = $result->{redirect} if ($result->{redirect});
  }
  else {
    my $result =$self->user_registration($attr);
    $extra_params{location} = $result->{location} if ($result->{location});
    $extra_params{redirect} = $result->{redirect} if ($result->{redirect});
  }

  return {
    %extra_params,
    output   => $html->{OUTPUT},
  };
}

#**********************************************************
=head2 password_recovery()

=cut
#**********************************************************
sub password_recovery {
  my $self = shift;
  my ($attr) = @_;

  my ($message, $redirect);

  if ($attr->{SEND_SMS}) {
    my $result = $self->password_recovery_process($attr);
    $message = $result->{element} if ($result->{element});
    $redirect = $result->{redirect} if ($result->{redirect});
  }

  if ($conf{PASSWORD_RECOVERY_URL}) {
    if ($attr->{CHANGE_PASSWORD}) {
      my $result = $self->password_change_process($attr);
      $message = $result->{element} if ($result->{element});
    }

    if ($attr->{CODE}) {
      $html->tpl_show(::templates('form_user_forgot_password_chg'), {
        %patterns,
        %$attr,
        CODE          => $attr->{CODE},
        ERROR_MESSAGE => $message,
      });

      return {
        result => 'OK'
      };
    }
  }

  my %extra_params = ();

  my %fields_list = (UID_HIDDEN => 'hidden', LOGIN_HIDDEN => 'hidden', CONTRACT_ID_HIDDEN => 'hidden', EMAIL_HIDDEN => 'hidden', PHONE_HIDDEN => 'hidden');
  my %fields = ();
  $fields{($_ || q{}) . '_HIDDEN'} = 1 for (split ',\s?', ($conf{PASSWORD_RECOVERY_PARAMS} || 'LOGIN,EMAIL'));
  delete @fields_list{keys %fields};

  my %required_fields = ();
  $required_fields{($_ || q{}) . '_REQUIRED'} = 'required' for (split ',\s?', ($conf{PASSWORD_RECOVERY_REQUIRED_PARAMS} || 'LOGIN,EMAIL'));

  if (in_array('Sms', \@main::MODULES) && !$fields_list{PHONE_HIDDEN}) {
    $extra_params{EXTRA_PARAMS} = $html->tpl_show(::_include('sms_check_form', 'Sms'), undef, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(::templates('form_user_forgot_password'), {
    %fields_list,
    %required_fields,
    %$attr,
    %extra_params,
    %params,
    %patterns,
    ERROR_MESSAGE => $message
  });

  return {
    result   => 'OK',
    redirect => $redirect
  };
}

#**********************************************************
=head2 password_recovery_process()

=cut
#**********************************************************
sub password_recovery_process {
  my $self = shift;
  my ($attr) = @_;

  my $result = $Registration_mng->password_recovery($attr);
  my $message_el = q{};
  my @redirect = ();

  if ($result->{result}) {
    $message_el = $html->message('info', $lang{INFO}, "$lang{SUCCESS} $lang{SENDED} $lang{TO} $result->{destination}", { OUTPUT2RETURN => 1 });
    push @redirect, ('/index.cgi', { WAIT => 3 });
  }
  else {
    my $error = $result->{errno} || 999999;
    my $message_err = $result->{errstr_lng} || "$lang{UNKNOWN} $lang{ERROR}";
    $message_el = $html->message('err', $lang{ERROR}, $message_err, { ID => $error, OUTPUT2RETURN => 1 });
  }

  return {
    result   => 'OK',
    element  => $message_el,
    redirect => \@redirect
  };
}

#**********************************************************
=head2 password_change_process()

=cut
#**********************************************************
sub password_change_process {
  my $self = shift;
  my ($attr) = @_;

  my $message_el = q{};

  if ($attr->{newpassword} && $attr->{confirm} && ($attr->{newpassword} ne $attr->{confirm})) {
    $message_el = $html->message('err', $lang{ERROR}, $lang{WRONG_PASSWORD}, { OUTPUT2RETURN => 1, ID => 19999 });
  }
  else {
    my $result = $Registration_mng->password_reset($attr);

    if ($result->{result}) {
      $message_el = $html->message('info', $lang{INFO}, $lang{CHANGED}, { OUTPUT2RETURN => 1 });
    }
    else {
      my $error = $result->{errno} || 999999;
      my $message_err = $result->{errstr_lng} || "$lang{UNKNOWN} $lang{ERROR}";
      $message_el = $html->message('err', $lang{ERROR}, $message_err, { ID => $error, OUTPUT2RETURN => 1 });
    }
  }

  return {
    result  => 'OK',
    element => $message_el
  };
}

#**********************************************************
=head2 user_registration()

=cut
#**********************************************************
sub user_registration {
  my $self = shift;
  my ($attr) = @_;

  my $message_el = '';
  my $result = {};
  my @redirect = ();

  if ($attr->{newpassword} && $attr->{confirm} && ($attr->{newpassword} ne $attr->{confirm})) {
    delete @{$attr}{qw/PIN_CONFIRM_FORM/};
    $message_el = $html->message('err', $lang{ERROR}, $lang{WRONG_PASSWORD}, { OUTPUT2RETURN => 1, ID => 19999 });
  }
  elsif ($attr->{external_auth} || $attr->{LOGIN} || $attr->{PIN}) {
    if ($attr->{PIN}) {
      $result = $Registration_mng->verify_pin($attr);
    }
    else {
      $result = $Registration_mng->user_registration($attr);
    }

    $attr->{FIO} = _utf8_encode($attr->{FIO}) if ($attr->{FIO});

    return $result if ($result->{location});

    if ($result->{result} && !$result->{verify_need}) {
      my $message = $lang{REGISTRATION_COMPLETE};
      $message .= $result->{password} ? "\n$lang{PASSWD} - $result->{password}" : "\n$lang{SEND_REG} E-mail";
      $message .= "\n$lang{SOCIAL_NETWORK_AUTH}" if ($result->{social_auth});
      $message_el = $html->message('info', $lang{SUCCESS}, $message, { OUTPUT2RETURN => 1 });
      push @redirect, ($conf{REGISTRATION_REDIRECT}, { WAIT => 3 }) if ($conf{REGISTRATION_REDIRECT});
    }
    elsif ($result->{errno}) {
      my $error = $result->{errno} || 999999;
      my $message_err = $result->{errstr_lng} || "$lang{UNKNOWN} $lang{ERROR}";
      $message_el = $html->message('err', $lang{ERROR}, $message_err, { ID => $error, OUTPUT2RETURN => 1 });
    }
  }

  my %social_btns = ();

  foreach my $social_net_name ('Facebook', 'Google', 'Apple') {
    my $conf_key_name = 'AUTH_' . uc($social_net_name) . '_ID';
    my $conf_reg = uc($social_net_name) . '_REGISTRATION';

    if (exists $conf{$conf_key_name} && $conf{$conf_key_name} && $conf{$conf_reg}) {
      $social_btns{$conf_key_name} = '';
      $social_btns{uc($social_net_name)} = "registration.cgi?external_auth=$social_net_name";
      $social_btns{uc($social_net_name)} .= "&REFERRER=$attr->{REFERRER}" if ($attr->{REFERRER});
    }
    else {
      $social_btns{ $conf_key_name } = 'display: none;';
    }
  }

  if (($conf{REGISTRATION_VERIFY_PHONE} || $conf{REGISTRATION_VERIFY_EMAIL}) && ($attr->{PIN_FORM} || (!$result->{errno} && $attr->{PIN_CONFIRM_FORM}))) {
    $html->tpl_show(::templates('form_registration_confirm_pin'), {
      %$attr,
      ERROR_MESSAGE => $message_el,
    });
  }
  else {
    $html->tpl_show(::templates('form_registration_user'), {
      %$attr,
      PASSWORD_RECOVERY => $conf{PASSWORD_RECOVERY} ? 1 : 0,
      HIDDEN_PASS       => $conf{REGISTRATION_PASSWORD} ? '' : 'hidden',
      REQUIRED_PASS     => $conf{REGISTRATION_PASSWORD} ? 'required' : '',
      ERROR_MESSAGE     => $message_el,
      HIDDEN_USER_IP    => $conf{REGISTRATION_IP} && $conf{REGISTRATION_DEFAULT_TP} ? '' : 'hidden',
      HIDDEN_PHONE      => $conf{REGISTRATION_VERIFY_PHONE} ? '' : 'hidden',
      REQUIRED_PHONE    => $conf{REGISTRATION_VERIFY_PHONE} ? 'required' : '',
      %params,
      %social_btns,
      %patterns
    });
  }

  return {
    result   => 'OK',
    redirect => \@redirect
  };
}

1;
