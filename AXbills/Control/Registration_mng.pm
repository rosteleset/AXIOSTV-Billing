package Control::Registration_mng;

=head1 NAME

  Registration service manage functions

=cut

use strict;
use warnings FATAL => 'all';

use JSON qw(decode_json);

use AXbills::Base qw(in_array mk_unique_value vars2lang escape_for_sql);
use AXbills::Filters qw($EMAIL_EXPR _utf8_encode);
use AXbills::Fetcher qw(web_request);
use Users;

my Users $Users;
my AXbills::HTML $html;

my (%lang, %conf);

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
    html      => $attr->{html} || $attr->{HTML},
    lang      => $attr->{lang} || $attr->{LANG},
    is_portal => $attr->{is_portal} || 0,
  };

  bless($self, $class);

  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  %lang = %{$self->{lang} || {}};
  %conf = %{$self->{conf} || {}};
  $html = $self->{html};

  return $self;
}

#**********************************************************
=head2 password_recovery()

=cut
#**********************************************************
sub password_recovery {
  my $self = shift;
  my ($attr) = @_;

  my $captcha_check = $self->reCaptchaV3($attr);
  return $captcha_check if ($captcha_check->{errno});

  return {
    errno      => 10003,
    errstr     => 'Service not available',
    errstr_lng => $lang{ERR_WRONG_DATA},
  } if (!$conf{PASSWORD_RECOVERY});

  return {
    errno      => 10004,
    errstr     => 'No phone or email field',
    errstr_lng => $lang{ERR_WRONG_DATA},
  } if (!$attr->{PHONE} && !$attr->{EMAIL});

  return {
    errno      => 10005,
    errstr     => 'No uid, login or contractId field',
    errstr_lng => $lang{ERR_WRONG_DATA},
  } if (!$attr->{UID} && !$attr->{CONTRACT_ID} && !$attr->{LOGIN});

  my %fields = ();
  $fields{$_} = 1 for split ',\s?', ($conf{PASSWORD_RECOVERY_REQUIRED_PARAMS} || 'LOGIN,EMAIL');

  foreach my $param ('UID', 'PHONE', 'EMAIL', 'CONTRACT_ID', 'LOGIN') {
    $attr->{$param} = '' if (!$fields{$param});
  }

  foreach my $field (keys %fields) {
    return {
      errno      => 10081,
      errstr     => 'No field ' . lc($field),
      errstr_lng => $lang{ERR_WRONG_DATA},
    } if (!$attr->{$field});
  }

  my $users_list = $Users->list({
    EMAIL       => $attr->{EMAIL} || '_SHOW',
    PHONE       => $attr->{PHONE} ? "*$attr->{PHONE}*" : '_SHOW',
    UID         => $attr->{UID} || '_SHOW',
    CONTRACT_ID => $attr->{CONTRACT_ID} || '_SHOW',
    LOGIN       => $attr->{LOGIN} || '_SHOW',
    COLS_NAME   => 1
  });

  if (!$Users->{TOTAL} || $Users->{TOTAL} < 1) {
    my $search_param = ($attr->{PHONE} && $attr->{PHONE} ne '') ? 'cell phone' : 'email';
    my $search_param_lng = ($attr->{PHONE} && $attr->{PHONE} ne '') ? $lang{PHONE} : 'Email';

    return {
      errno      => 10006,
      errstr     => "User not exists with this $search_param",
      errstr_lng => "$lang{USER} $lang{NOT_EXIST} $lang{OR} $search_param_lng $lang{NOT_EXIST}",
    };
  }

  my $user = $users_list->[0];

  if ($attr->{PHONE}) {
    require Contacts;
    Contacts->import();
    my $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});
    $Contacts->contacts_list({ VALUE => "$attr->{PHONE},+$attr->{PHONE}", UID => $user->{uid} });

    if ($Contacts->{TOTAL} < 1) {
      return {
        errno      => 10007,
        errstr     => "User not exists with cell phone $attr->{PHONE}",
        errstr_lng => "$lang{CELL_PHONE} $attr->{PHONE} $lang{NOT_EXIST}"
      };
    }
  }

  my $pi = $Users->pi({ UID => $user->{uid} });
  my $user_info = $Users->info($user->{uid}, { SHOW_PASSWORD => 1 });

  my $mess = "$self->{lang}->{PASSWD}: $Users->{PASSWORD}";
  my $code = q{};
  my $url = q{};
  if ($conf{PASSWORD_RECOVERY_URL}) {
    $code = mk_unique_value(64);
    $url = $conf{PASSWORD_RECOVERY_URL} || '';
    $url =~ s/%CODE%/$code/gm;
    $mess = "$self->{lang}->{PASSWD_RESET_LINK}: $url"
  }

  ::load_module("AXbills::Templates", { LOAD_PACKAGE => 1 }) if (!exists($INC{"AXbills/Templates.pm"}));
  my $message = $self->{html}->tpl_show(::templates('msg_passwd_recovery'), {
    MESSAGE => $mess,
    URL     => $url,
    %{$user_info},
    %{$pi},
  }, { OUTPUT2RETURN => 1 });

  require AXbills::Sender::Core;
  AXbills::Sender::Core->import();
  my $Sender = AXbills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

  if ($attr->{PHONE} && $attr->{SEND_SMS} && in_array('Sms', \@main::MODULES)) {
    require Sms;
    Sms->import();
    my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});

    my $sms_limit = $conf{USER_LIMIT_SMS} || 5;

    my $current_mount = POSIX::strftime("%Y-%m-01", localtime(time));
    $Sms->list({
      COLS_NAME => 1,
      DATETIME  => ">=$current_mount",
      UID       => $user->{uid},
      NO_SKIP   => 1,
      PAGE_ROWS => 1000
    });

    my $sent_sms = $Sms->{TOTAL} || 0;

    if ($sms_limit <= $sent_sms) {
      return {
        errno      => 10008,
        errstr     => "User sms limit has been reached - $conf{USER_LIMIT_SMS} sms",
        errstr_lng => "SMS $lang{LIMIT} $conf{USER_LIMIT_SMS}",
      };
    }

    $message =~ s/[\r\n]/ /gm if ($message);

    my $status = $Sender->send_message({
      TO_ADDRESS  => $attr->{PHONE},
      MESSAGE     => $message,
      SENDER_TYPE => 'Sms',
      UID         => $user->{uid}
    });

    if ($status) {
      $self->{admin}->action_add($user->{uid}, "Send recovery password code:$code", { TYPE => 51 });
      return {
        result      => "Success sent sms to phone $attr->{PHONE}",
        destination => $attr->{PHONE}
      };
    }
    else {
      return {
        errno      => 10009,
        errstr     => "Failed to send sms to phone $attr->{PHONE}",
        errstr_lng => "SMS $lang{NOT} $lang{SENDED}"
      };
    }
  }
  else {
    if ($user->{email} && $user->{email} ne '') {
      my $status = $Sender->send_message({
        TO_ADDRESS   => $user->{email},
        MESSAGE      => $message,
        SUBJECT      => "$main::PROGRAM $lang{PASSWORD_RECOVERY}",
        SENDER_TYPE  => 'Mail',
        QUITE        => 1,
        CONTENT_TYPE => $conf{PASSWORD_RECOVERY_MAIL_CONTENT_TYPE} ? $conf{PASSWORD_RECOVERY_MAIL_CONTENT_TYPE} : '',
      });

      if ($status && $status eq '1') {
        $self->{admin}->action_add($user->{uid}, "Send recovery password code:$code", { TYPE => 51 });

        return {
          result      => "Success sent message to email $user->{email}",
          destination => $user->{email}
        };
      }
      else {
        return {
          errno      => 10031,
          errstr     => "Failed to send email to $user->{email}",
          errstr_lng => "Email $lang{NOT} $lang{SENDED}",
          status     => $status
        };
      }
    }
    else {
      return {
        errno      => 10010,
        errstr     => "User not exists with email $user->{email}",
        errstr_lng => "E-mail $attr->{EMAIL} $lang{NOT_EXIST}"
      };
    }
  }
}

#**********************************************************
=head2 password_reset()

=cut
#**********************************************************
sub password_reset {
  my $self = shift;
  my ($attr) = @_;

  return {
    errno      => 10025,
    errstr     => 'Service not available',
    errstr_lng => $lang{ERR_WRONG_DATA}
  } if (!$conf{PASSWORD_RECOVERY} || !$conf{PASSWORD_RECOVERY_URL});

  return {
    errno      => 10026,
    errstr     => 'No fields code or password',
    errstr_lng => $lang{ERR_WRONG_DATA}
  } if (!$attr->{PASSWORD} || !$attr->{CODE});

  $conf{PASSWD_LENGTH} //= 6;

  return {
    errno      => 10027,
    errstr     => "Length of password not valid minimum $conf{PASSWD_LENGTH}",
    errstr_lng => "$lang{ERR_SHORT_PASSWD} $conf{PASSWD_LENGTH}",
  } if ($conf{PASSWD_LENGTH} && $conf{PASSWD_LENGTH} > length($attr->{PASSWORD}));

  $conf{PASSWD_SYMBOLS} //= 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ';

  return {
    errno      => 10028,
    errstr     => "Password not valid, allowed symbols $conf{PASSWD_SYMBOLS}",
    errstr_lng => $lang{ERR_SYMBOLS_PASSWD},
  } if ($conf{PASSWD_SYMBOLS} && $attr->{PASSWORD} !~ /^[$conf{PASSWD_SYMBOLS}]+$/g);

  my $list = $self->{admin}->action_list({
    FROM_DATE => $main::DATE,
    TO_DATE   => $main::DATE,
    TYPE      => 51,
    ACTIONS   => "Send recovery password code:$attr->{CODE}",
    COLS_NAME => 1
  });

  return {
    errno      => 10029,
    errstr     => 'Not valid recoverable code',
    errstr_lng => "$lang{WRONG} URL",
  } if ($self->{admin}->{TOTAL} < 1);

  $Users->change($list->[0]->{uid}, {
    PASSWORD => $attr->{PASSWORD},
    UID      => $list->[0]->{uid},
  });

  return {
    errno      => 10030,
    errstr     => 'Failed to change user password',
    errstr_lng => $lang{ERR_UNKNOWN},
  } if ($Users->{errno});

  $self->{admin}->action_del($list->[0]->{id});
  $self->{admin}->action_add($list->[0]->{uid}, 'Finished password recovery process', { TYPE => 52 });

  my $users_info = $Users->list({
    UID        => $list->[0]->{uid},
    EMAIL      => '_SHOW',
    PHONE      => '_SHOW',
    COLS_UPPER => 1,
    COLS_NAME  => 1
  });

  $Users->info($list->[0]->{uid});
  $Users->pi({ UID => $list->[0]->{uid} });

  ::load_module('AXbills::Templates', { LOAD_PACKAGE => 1 }) if (!exists($INC{"AXbills/Templates.pm"}));

  require AXbills::Sender::Core;
  AXbills::Sender::Core->import();
  my $Sender = AXbills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

  if ($users_info->[0]->{email}) {
    my ($email) = split(/:/, $users_info->[0]->{email});
    my $message = $html->tpl_show(::templates('email_password_recovery'), {
      %$Users, %$attr,
    }, { OUTPUT2RETURN => 1 });

    $Sender->send_message({
      TO_ADDRESS   => $email,
      MESSAGE      => $message,
      SUBJECT      => "$main::PROGRAM $lang{PASSWORD_RECOVERY}",
      SENDER_TYPE  => 'Mail',
      QUITE        => 1,
      UID          => $Users->{UID},
      CONTENT_TYPE => $conf{PASSWORD_RECOVERY_MAIL_CONTENT_TYPE} ? $conf{PASSWORD_RECOVERY_MAIL_CONTENT_TYPE} : '',
    });
  }
  else {
    my ($phone) = split(/:/, $users_info->[0]->{phone});
    my $message = $html->tpl_show(::templates('sms_password_recovery'), {
      %$Users, %$attr,
    }, { OUTPUT2RETURN => 1 });

    $Sender->send_message({
      TO_ADDRESS  => $phone,
      MESSAGE     => $message,
      SENDER_TYPE => 'Sms',
      UID         => $Users->{UID},
    });
  }

  return {
    result => 'Successfully changed password',
  };
}

#**********************************************************
=head2 user_registration()

=cut
#**********************************************************
sub user_registration {
  my $self = shift;
  my ($attr) = @_;

  my $password = q{};
  my %extra_params = ();
  my $is_social_auth = 0;
  my $user_status = 0;
  delete $attr->{UID};

  my $captcha_check = $self->reCaptchaV3($attr);
  return $captcha_check if ($captcha_check->{errno});

  return {
    errno      => 10201,
    errstr     => 'Service not available',
    errstr_lng => $lang{ERR_UNKNOWN}
  } if ($conf{REGISTRATION_PORTAL_SKIP});

  return {
    errno      => 10202,
    errstr     => 'Service not available',
    errstr_lng => $lang{ERR_UNKNOWN}
  } if (!$conf{NEW_REGISTRATION_FORM});

  if ($attr->{external_auth} && $self->{is_portal}) {
    my $result = $self->_social_registration($attr);
    return $result if ($result->{errno} || $result->{location});

    $is_social_auth = 1;
    $attr->{LOGIN} = $result->{login};
    $attr->{EMAIL} = $result->{email} || '';
    $attr->{FIO} = $result->{name} || '';
    $attr->{PHONE} = '';
    $password = $result->{password};
    $extra_params{$result->{field}} = $result->{id};
  }
  elsif ($attr->{SOCIAL_NETWORK} && $attr->{TOKEN}) {
    $attr->{external_auth} = $attr->{social_network};
    my $result = $self->_social_registration({
      API           => 1,
      external_auth => $attr->{SOCIAL_NETWORK},
      token         => $attr->{TOKEN}
    });
    return $result if ($result->{errno});

    $is_social_auth = 1;
    $attr->{LOGIN} = $result->{login};
    $attr->{EMAIL} = $result->{email} || '';
    $attr->{FIO} = $result->{name} || '';
    $attr->{PHONE} = '';
    $password = $result->{password};
    $extra_params{$result->{field}} = $result->{id};
  }
  else {
    my $result = $self->_registration_validation($attr);
    return $result if ($result->{errno} || $result->{warnings});
    $user_status = 2 if ($conf{REGISTRATION_VERIFY_PHONE} || $conf{REGISTRATION_VERIFY_EMAIL});
    $password = $result->{password};
  }

  $Users->add({
    LOGIN       => $attr->{LOGIN},
    CREATE_BILL => 1,
    PASSWORD    => $password,
    GID         => $conf{REGISTRATION_GID},
    PREFIX      => $conf{REGISTRATION_PREFIX},
    DISABLE     => $user_status,
  });

  if ($Users->{errno}) {
    return {
      errno      => 10208,
      errstr     => 'Invalid login of user',
      login      => $attr->{LOGIN},
      errstr_lng => "$lang{ERR_WRONG_DATA} $lang{LOGIN}",
    } if ($Users->{errno} == 10);

    return {
      errno      => 10209,
      errstr     => 'User already exist',
      errstr_lng => "$lang{USER_EXIST}"
    } if ($Users->{errno} == 7);

    return {
      errno      => 10215,
      errstr     => "Invalid login too long. Allowed $conf{MAX_USERNAME_LENGTH}",
      errstr_lng => "$lang{ERR_NAME_TOOLONG} $conf{MAX_USERNAME_LENGTH}",
    } if ($Users->{errno} == 9);

    return {
      errno  => 10210,
      errstr => 'Error occurred during creation of user',
      errstr => "$lang{ERR_UNKNOWN}"
    };
  }

  my $uid = $Users->{UID};
  $Users->info($uid);

  $Users->pi_add({
    %extra_params,
    UID   => $uid,
    FIO   => $attr->{FIO} || '',
    EMAIL => $attr->{EMAIL},
    PHONE => $attr->{PHONE} || ''
  });

  if ($Users->{errno}) {
    $Users->del({ UID => $uid, FULL_DELETE => 1 });

    return {
      errno      => 10019,
      errstr     => 'Error occurred during add pi info of user',
      errstr_lng => $lang{ERR_UNKNOWN},
    };
  }

  if ($conf{REGISTRATION_DEFAULT_TP}) {
    my $internet_registration = $self->_registration_default_tp({
      %$attr,
      UID => $uid
    });

    return $internet_registration if ($internet_registration->{errno});
  }

  if ($conf{AUTH_ROUTE_TAG} && in_array('Tags', \@main::MODULES)) {
    require Tags;
    Tags->import();

    my $Tags = Tags->new($self->{db}, $self->{conf}, $self->{admin});
    $Tags->tags_user_change({
      IDS => $conf{AUTH_ROUTE_TAG},
      UID => $uid,
    });
  }

  $attr->{PASSWORD} = $password;

  my %result = (
    result => "Successfully created user with uid: $uid",
  );

  $result{social_auth} = 1 if (($attr->{social_network} && $attr->{token}) || ($attr->{external_auth} && $self->{is_portal}));
  $result{redirect_url} = $conf{REGISTRATION_REDIRECT} if ($conf{REGISTRATION_REDIRECT});
  $result{password} = $password if ($conf{REGISTRATION_SHOW_PASSWD});
  $result{uid} = $uid;

  if ($self->{is_portal} && $attr->{state}) {
    my ($state) = $attr->{state} =~ s/\\"/"/g;
    $state = eval {decode_json($attr->{state})};
    $state = escape_for_sql($state);

    $attr->{REFERRER} = $state->{referrer} if (!$@ && $state->{referrer});
  }

  if ($attr->{REFERRER}) {
    ::load_module('Referral', $html);
    ::referral_link_registered({ REFERRED => $attr->{REFERRER}, UID => $uid, QUITE => 1 });
  }

  if (!($attr->{SOCIAL_NETWORK} && $attr->{TOKEN}) && ($conf{REGISTRATION_VERIFY_PHONE} || $conf{REGISTRATION_VERIFY_EMAIL})) {
    my $pin_result = $self->_send_pin(undef, $attr);
    if ($pin_result->{warning}) {
      $result{warning} = $pin_result->{warning};
      $result{send_status} = $pin_result->{send_status};
    }
    else {
      $Users->registration_pin_add({
        UID         => $uid,
        PIN_CODE    => $pin_result->{pin} || '--',
        DESTINATION => $pin_result->{destination},
        SEND_COUNT  => 1
      });
      $result{verify_message} = $pin_result->{result};
      $result{verify_need} = 'true';
    }
  }
  else {
    my $message_info = $self->_send_registration_message($attr);
    if ($message_info->{code}) {
      $result{warning} = $message_info->{warning} || '';
      $result{code} = $message_info->{code} || '';
    }
  }

  return \%result;
}

#**********************************************************
=head2 reCaptchaV3()

=cut
#**********************************************************
sub reCaptchaV3 {
  my $self = shift;
  my ($attr) = @_;

  return {
    result => 'OK'
  } unless ($conf{GOOGLE_CAPTCHA_SECRET} && $conf{GOOGLE_CAPTCHA_KEY});

  my $response = $attr->{'g-recaptcha-response'} || $attr->{CAPTCHA} || q{};
  my $url = "https://www.google.com/recaptcha/api/siteverify?secret=$conf{GOOGLE_CAPTCHA_SECRET}&response=$response";
  my $result = web_request($url, {
    JSON_RETURN => 1,
  });

  ($result && ref $result eq 'HASH' && $result->{success} && $result->{success} ne 'false') ?
    return {
      result => 'OK',
    } :
    return {
      errno      => 10235,
      errstr     => 'Wrong captcha',
      errstr_lng => $lang{ERR_WRONG_CAPTCHA},
    };
}

#**********************************************************
=head2 _registration_validation()

=cut
#**********************************************************
sub _registration_validation {
  my $self = shift;
  my ($attr) = @_;

  return {
    errno      => 10203,
    errstr     => 'Invalid login',
    errstr_lng => "$lang{ERR_WRONG_DATA} $lang{LOGIN}",
  } if (!$attr->{LOGIN});

  return {
    errno      => 10211,
    errstr     => "Invalid login too long. Allowed $conf{MAX_USERNAME_LENGTH}",
    errstr_lng => "$lang{ERR_NAME_TOOLONG} $conf{MAX_USERNAME_LENGTH}",
  } if (length($attr->{LOGIN}) > $self->{conf}->{MAX_USERNAME_LENGTH});

  $conf{USERNAMEREGEXP} //= "^[a-z0-9_][a-z0-9_-]*\$";

  return {
    errno      => 10212,
    errstr     => "Invalid login, not allowed symbols. Allowed: $conf{USERNAMEREGEXP}",
    errstr_lng => "$lang{ERR_WRONG_DATA} $lang{LOGIN}",
  } if ($attr->{LOGIN} !~ /$conf{USERNAMEREGEXP}/);

  return {
    errno      => 10204,
    errstr     => 'Invalid email',
    errstr_lng => "$lang{ERR_WRONG_DATA} Email",
  } if (!$attr->{EMAIL});

	### START KTK-39 ###
    my $email_format = $self->{conf}->{EMAIL_FORMAT} || '';
	return {
    errno      => 10237,
    errstr     => 'Invalid email',
    errstr_lng => "$lang{ERR_WRONG_DATA} Email",
  } if ($attr->{EMAIL} !~ /$EMAIL_EXPR/ && $attr->{EMAIL} !~ /$email_format/);
  ### END KTK-39 ###

  $conf{EMAIL_DOMAIN_VALIDATION} //= 1;

  if ($conf{EMAIL_DOMAIN_VALIDATION}) {
    my $domain_temp = ($conf{EMAIL_DOMAIN_VALIDATION} == 1) ? 'mail_whitelist' : 'mail_blacklist';
    ::load_module("AXbills::Templates", { LOAD_PACKAGE => 1 }) if (!exists($INC{"AXbills/Templates.pm"}));
    my $domains = $html->tpl_show(::templates($domain_temp), {}, { OUTPUT2RETURN => 1 });

    my @domains = split('\r?\n', $domains);
    my ($domain) = $attr->{EMAIL} =~ /(?<=@).+/g;

    if (in_array($domain, \@domains)) {
      return {
        errno      => 10232,
        errstr     => 'Unknown email domain, please use valid email',
        errstr_lng => $lang{ERR_EMAIL_DOMAIN},
      } if ($conf{EMAIL_DOMAIN_VALIDATION} != 1);
    }
    else {
      return {
        errno      => 10238,
        errstr     => 'Unknown email domain, please use valid email',
        errstr_lng => $lang{ERR_EMAIL_DOMAIN},
      } if ($conf{EMAIL_DOMAIN_VALIDATION} == 1);
    }
  }

  $Users->list({
    EMAIL     => $attr->{EMAIL},
    DESC      => 'DESC',
    COLS_NAME => 1
  });

  return {
    errno      => 10234,
    errstr     => 'Email already registered',
    errstr_lng => "Email $lang{EXIST}"
  } if ($Users->{TOTAL});

  $Users->list({
    EMAIL     => $attr->{LOGIN},
    DESC      => 'DESC',
    COLS_NAME => 1
  });

  return {
    errno      => 10233,
    errstr     => 'Login already registered',
    errstr_lng => "$lang{LOGIN} $lang{EXIST}"
  } if ($Users->{TOTAL});

  if ($conf{REGISTRATION_VERIFY_PHONE} || $attr->{PHONE}) {
    return {
      errno      => 10240,
      errstr     => 'No param phone',
      errstr_lng => "$lang{ERR_WRONG_DATA} $lang{PHONE}",
    } if (!$attr->{PHONE});

    my $phone_format = $self->{conf}->{PHONE_FORMAT} || $self->{conf}->{CELL_PHONE_FORMAT} || '';

    return {
      errno      => 10241,
      errstr     => 'No param phone',
      errstr_lng => "$lang{ERR_WRONG_DATA} $lang{PHONE}",
    } if ($phone_format && $attr->{PHONE} !~ /$phone_format/);
  }

  my $password = q{};

  if ($conf{REGISTRATION_PASSWORD}) {
    return {
      errno      => 10205,
      errstr     => 'No field password',
      errstr_lng => "$lang{ERR_WRONG_DATA} $lang{PASSWD}",
    } if (!$attr->{PASSWORD});

    $conf{PASSWD_LENGTH} //= 6;

    return {
      errno      => 10206,
      errstr     => "Length of password not valid minimum $conf{PASSWD_LENGTH}",
      errstr_lng => "$lang{ERR_SYMBOLS_PASSWD} $lang{MIN} $conf{PASSWD_LENGTH}",
    } if ($conf{PASSWD_LENGTH} && $conf{PASSWD_LENGTH} > length($attr->{PASSWORD}));

    $conf{PASSWD_SYMBOLS} //= 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ';

    return {
      errno      => 10207,
      errstr     => "Password not valid, allowed symbols $conf{PASSWD_SYMBOLS}",
      errstr_lng => "$lang{ERR_WRONG_DATA} $lang{PASSWD}",
    } if ($conf{PASSWD_SYMBOLS} && $attr->{PASSWORD} !~ /^[$conf{PASSWD_SYMBOLS}]+$/g);

    $password = $attr->{PASSWORD};
  }

  if (!$password) {
    $password = mk_unique_value($conf{PASSWD_LENGTH} || 6, { SYMBOLS => $conf{PASSWD_SYMBOLS} || undef });
  }

  if ($conf{REGISTRATION_VERIFY_PHONE} || $conf{REGISTRATION_VERIFY_EMAIL}) {
    my $check_field = $conf{REGISTRATION_VERIFY_PHONE} ? 'phone' : 'email';
    my $destination = $attr->{uc($check_field)} || '--';
    delete $Users->{UID};
    $Users->registration_pin_info({ DESTINATION => $destination });

    return {
      warnings => "Already send a code to $check_field $destination",
      code     => 10099
    } if $Users->{UID};
  }

  return {
    result   => 'OK',
    password => $password
  };
}

#**********************************************************
=head2 _social_registration()

=cut
#**********************************************************
sub _social_registration {
  my $self = shift;
  my ($attr) = @_;

  my $social_net_name = $attr->{external_auth} || $attr->{SOCIAL_NETWORK};

  my $conf_key_name = 'AUTH_' . uc($social_net_name) . '_ID';
  my $conf_reg = uc($social_net_name) . '_REGISTRATION';

  return {
    errno      => 10229,
    errstr     => 'Unknown social network',
    errstr_lng => $lang{ERR_UNKNOWN},
  } unless ($conf{$conf_key_name} && $conf{$conf_reg});

  if ($attr->{SOCIAL_NETWORK}) {
    $attr->{API} = 1;
    $attr->{token} = $attr->{TOKEN} || q{};
  }

  require AXbills::Auth::Core;
  AXbills::Auth::Core->import();

  my $Auth = AXbills::Auth::Core->new({
    CONF      => \%conf,
    AUTH_TYPE => ucfirst(lc($social_net_name)),
    SELF_URL  => $main::SELF_URL,
    FORM      => $attr
  });

  $Auth->check_access($attr);

  if ($Auth->{auth_url}) {
    return {
      result   => 'OK',
      location => $Auth->{auth_url},
    };
  }
  elsif ($Auth->{USER_ID}) {
    my $captcha_check = $self->reCaptchaV3($attr);
    return $captcha_check if ($captcha_check->{errno});

    $Users->list({
      $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
      LOGIN                => '_SHOW',
      PASSWORD             => '_SHOW',
      FIO                  => '_SHOW',
      COLS_NAME            => 1
    });

    if ($Users->{TOTAL}) {
      return {
        errno      => 10231,
        errstr     => 'Sorry user already present in system try login with this social account',
        errstr_lng => $lang{ERR_SOCIAL_REGISTER},
      };
    }
    else {
      my $password = mk_unique_value($conf{PASSWD_LENGTH} || 6, { SYMBOLS => $conf{PASSWD_SYMBOLS} || undef });
      my $login = q{};

      $conf{USERNAMEREGEXP} //= "^[a-z0-9_][a-z0-9_-]*\$";
      if ($Auth->{USER_EMAIL} && $Auth->{USER_EMAIL} =~ /$conf{USERNAMEREGEXP}/) {
        $login = $Auth->{USER_EMAIL};
      }
      else {
        my $pattern = qr/$conf{USERNAMEREGEXP}/;
        my $_login = q{};

        if ('example@gmail.com' =~ /$conf{USERNAMEREGEXP}/) {
          $_login = mk_unique_value(15, { SYMBOLS => 'qwertyupasdfghjikzxcvbnm123456789' }) . '@unknown.com';
        }
        else {
          my $length = ($conf{MAX_USERNAME_LENGTH} || 10) - 1;
          require AXbills::Random;
          AXbills::Random->import();
          my $string_gen = AXbills::Random->new({ length => $length });
          for (1 .. 10) {
            $_login = $string_gen->randregex($conf{USERNAMEREGEXP});
            last if $_login =~ $pattern;
          }
        }

        my $list = $Users->list({
          LOGIN     => $_login,
          PAGE_ROWS => 2
        });

        if (scalar @$list) {
          if ($_login . 'a' =~ /$conf{USERNAMEREGEXP}/) {
            $login = $_login . 'a';
          }
          else {
            $login = $_login . '1';
          }
        }
        else {
          $login = $_login;
        }
      }

      return {
        id       => $Auth->{USER_ID},
        name     => $Auth->{USER_NAME},
        email    => $Auth->{USER_EMAIL},
        password => $password,
        login    => $login,
        field    => $Auth->{CHECK_FIELD},
      };
    }
  }
  else {
    return {
      errno      => 10230,
      errstr     => 'Social network error unknown token',
      errstr_lng => $lang{ERR_UNKNOWN},
    };
  }
}

#**********************************************************
=head2 _send_registration_message()

=cut
#**********************************************************
sub _send_registration_message {
  my $self = shift;
  my ($attr) = @_;

  my $prot = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $addr = (defined($ENV{HTTP_HOST})) ? "$prot://$ENV{HTTP_HOST}/index.cgi" : '';

  $attr->{FIO} = _utf8_encode($attr->{FIO}) if ($attr->{FIO});

  ::load_module('AXbills::Templates', { LOAD_PACKAGE => 1 }) if (!exists($INC{"AXbills/Templates.pm"}));
  my $message = $html->tpl_show(::templates('form_registration_complete'), {
    %$Users, %$attr,
    PASSWORD => $attr->{PASSWORD},
    BILL_URL => $addr
  }, { OUTPUT2RETURN => 1 });

  require AXbills::Sender::Core;
  AXbills::Sender::Core->import();
  my $Sender = AXbills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

  if (in_array('Sms', \@main::MODULES) && $conf{REGISTRATION_VERIFY_PHONE} && $conf{REGISTRATION_SEND_SMS} && $attr->{PHONE}) {
    $Sender->send_message({
      TO_ADDRESS  => $attr->{PHONE},
      MESSAGE     => $message,
      SENDER_TYPE => 'Sms',
      UID         => $Users->{UID},
    });
  }
  else {
    return {
      warning => 'Email not send with registration information. Parameter email not found in social network info. Can login via linked social network.',
      code    => 10083
    } if !$attr->{EMAIL};

    $Sender->send_message({
      TO_ADDRESS   => $attr->{EMAIL},
      MESSAGE      => $message,
      SUBJECT      => "$main::PROGRAM $lang{REGISTRATION}",
      SENDER_TYPE  => 'Mail',
      QUITE        => 1,
      UID          => $Users->{UID},
      CONTENT_TYPE => $conf{REGISTRATION_MAIL_CONTENT_TYPE} ? $conf{REGISTRATION_MAIL_CONTENT_TYPE} : '',
    });
  }

  return {
    result => 'OK',
  };
}

#**********************************************************
=head2 _send_pin()

=cut
#**********************************************************
sub _send_pin {
  my $self = shift;
  my ($pin, $attr) = @_;

  require AXbills::Sender::Core;
  AXbills::Sender::Core->import();
  my $Sender = AXbills::Sender::Core->new($self->{db}, $self->{admin}, \%conf);

  $pin = $pin || int(rand(9999)) + 10000;

  my $prot = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $addr = (defined($ENV{HTTP_HOST})) ? "$prot://$ENV{HTTP_HOST}/index.cgi" : '';

  ::load_module('AXbills::Templates', { LOAD_PACKAGE => 1 }) if (!exists($INC{"AXbills/Templates.pm"}));
  my $message = $html->tpl_show(::templates('form_registration_pin'), {
    %$Users, %$attr,
    PIN      => $pin,
    BILL_URL => $addr
  }, { OUTPUT2RETURN => 1 });

  if ($conf{REGISTRATION_VERIFY_PHONE} && in_array('Sms', \@main::MODULES)) {
    my $send_status = $Sender->send_message({
      TO_ADDRESS  => $attr->{PHONE},
      MESSAGE     => $message,
      SENDER_TYPE => 'Sms',
    });

    if ($send_status) {
      return {
        result      => "Successfully send code to phone $attr->{PHONE}",
        send_pin    => 1,
        pin         => $pin,
        destination => $attr->{PHONE}
      };
    }
    else {
      return {
        warning     => "Failed send pin to code $attr->{PHONE}",
        send_status => $send_status,
      };
    }
  }
  else {
    my $send_status = $Sender->send_message({
      TO_ADDRESS   => $attr->{EMAIL},
      MESSAGE      => $message,
      SUBJECT      => "$main::PROGRAM $lang{REGISTRATION}",
      SENDER_TYPE  => 'Mail',
      QUITE        => 1,
      CONTENT_TYPE => $conf{REGISTRATION_MAIL_CONTENT_TYPE} ? $conf{REGISTRATION_MAIL_CONTENT_TYPE} : '',
    });

    if ($send_status && $send_status eq '1') {
      return {
        result      => "Successfully send pin to email $attr->{EMAIL}",
        send_pin    => 1,
        pin         => $pin,
        destination => $attr->{EMAIL}
      };
    }
    else {
      return {
        warning     => "Failed send pin to email $attr->{EMAIL}",
        send_status => $send_status,
      };
    }
  }
}

#**********************************************************
=head2 resend_pin()

=cut
#**********************************************************
sub resend_pin {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_pin_process_validation($attr);
  return $result if ($result->{errno} || $result->{uid});

  my $sms_limit = $conf{USER_LIMIT_SMS} || 5;

  if ($Users->{SEND_COUNT} && $Users->{SEND_COUNT} > $sms_limit) {
    return {
      errno      => 10246,
      errstr     => 'Sorry you reached limit for resend verification code, please write to technical support',
      errstr_lng => "$lang{LIMIT} $lang{MESSAGE}",
    };
  }
  else {
    my $send_result = $self->_send_pin(($result->{pin} || ''), $attr);

    $Users->registration_pin_change({
      UID        => $Users->{UID} || '--',
      SEND_COUNT => $Users->{SEND_COUNT} ? $Users->{SEND_COUNT} + 1 : 1,
    });

    delete $send_result->{pin};
    return $send_result;
  }
}

#**********************************************************
=head2 verify_pin($attr)

=cut
#**********************************************************
sub verify_pin {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_pin_process_validation($attr);
  return $result if ($result->{errno} || $result->{uid});

  my $code = $attr->{VERIFICATION_CODE} || $attr->{PIN} || '';
  my $is_valid = $code eq ($result->{pin} || '');
  my $uid = $Users->{UID} || '--';

  return {
    errno  => 10242,
    errstr => 'No code',
  } if !$code;

  if (!$is_valid) {
    $Users->registration_pin_change({
      UID      => $uid,
      ATTEMPTS => $Users->{ATTEMPTS} ? $Users->{ATTEMPTS} + 1 : 1,
    });
    return {
      errno      => 10082,
      errstr     => 'Wrong pin',
      errstr_lng => "$lang{ERR_WRONG_DATA} PIN",
    };
  }
  else {
    $Users->change($uid, {
      DISABLE => 0,
    });

    if (!$Users->{errno}) {
      my %parameters = (
        uid    => $uid,
        result => 'Successfully verified user',
      );
      $Users->info($uid, { SHOW_PASSWORD => 1 });
      my $message_info = $self->_send_registration_message({ %$attr, PASSWORD => $Users->{PASSWORD} });
      if ($message_info->{code}) {
        $parameters{warning} = $message_info->{warning} || '';
        $parameters{code} = $message_info->{code} || '';
      }

      $Users->registration_pin_change({
        UID      => $uid,
        VERIFY_DATE => 'NOW()',
      });

      return {
        uid    => $uid,
        result => 'Successfully verified user',
      };
    }
    else {
      return {
        errno      => 10239,
        errstr     => 'Failed to activate of user',
        user_error => $Users->{errno},
        errstr_lng => $lang{ERR_UNKNOWN},
      };
    }
  }
}

#**********************************************************
=head2 _pin_process_validation($attr)

=cut
#**********************************************************
sub _pin_process_validation {
  my $self = shift;
  my ($attr) = @_;

  return {
    errno  => 10252,
    errstr => 'Unknown operation'
  } if (!($self->{conf}->{REGISTRATION_VERIFY_PHONE} || $self->{conf}->{REGISTRATION_VERIFY_EMAIL}));

  my $check_field = $conf{REGISTRATION_VERIFY_PHONE} ? 'PHONE' : 'EMAIL';
  my $destination = $attr->{$check_field} || '--';

  $Users->registration_pin_info({ DESTINATION => $destination });

  return {
    errno      => 10243,
    errstr     => "No field $check_field or uid",
    errstr_lng => $lang{ERR_WRONG_DATA},
  } if !$destination;

  return {
    errno      => 10249,
    errstr     => 'User not found',
    errstr_lng => "$lang{ERR_WRONG_DATA} PIN",
  } if ($Users->{errno});

  my $uid = $Users->{UID} || '--';
  if ($Users->{VERIFY_DATE} ne '0000-00-00 00:00:00') {
    return {
      result => 'User already activated',
      uid    => $uid,
    };
  }

  return {
    result => 'OK',
    pin    => $Users->{VERIFICATION_CODE},
  };
}

#**********************************************************
=head2 _registration_default_tp($attr)

=cut
#**********************************************************
sub _registration_default_tp {
  my $self = shift;
  my ($attr) = @_;

  my $cid = q{};
  my $uid = $attr->{UID};

  if ($conf{REGISTRATION_IP}) {
    if (!$attr->{USER_IP} || $attr->{USER_IP} eq '0.0.0.0') {
      $Users->del({ UID => $uid, FULL_DELETE => 1 });
      return {
        errno      => 10015,
        errstr     => 'Invalid ip',
        errstr_lng => "$lang{ERR_WRONG_DATA} IP",
      };
    }

    require Internet::Sessions;
    Internet::Sessions->import();

    my $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});
    $Sessions->online({
      CLIENT_IP => $attr->{USER_IP},
      CID       => '_SHOW',
      GUEST     => 1,
      COLS_NAME => 1
    });

    if ($Sessions->{TOTAL}) {
      $cid = $Sessions->{list}->[0]->{cid};
    }

    if (!$cid) {
      $Users->del({ UID => $uid, FULL_DELETE => 1 });
      return {
        errno      => 10016,
        errstr     => 'IP address and MAC was not found',
        errstr_lng => "$lang{ERR_WRONG_DATA} IP",
      };
    }
  }

  require Internet;
  Internet->import();
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});

  $Internet->user_add({
    UID    => $uid,
    TP_ID  => $conf{REGISTRATION_DEFAULT_TP} || 0,
    STATUS => 2,
    CID    => $cid
  });

  return {
    result => 'OK',
  };
}

1;
