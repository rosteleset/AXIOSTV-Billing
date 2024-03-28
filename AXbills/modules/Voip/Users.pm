package Voip::Users;

=head1 NAME

  Voip users function

  ERROR ID: 310xx

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(dirname cmd next_month);
use Fees;
use Voip;
use Users;
use Nas;

my Voip $Voip;
my Users $Users;
my Nas $Nas;
my Fees $Fees;

my AXbills::HTML $html;

my %lang;
my %permissions = ();

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
  };

  %lang = %{$attr->{lang} || {}};
  $html = $attr->{html};
  %permissions = %{$attr->{permissions} || {}};

  bless($self, $class);
  $Voip = Voip->new($db, $admin, $conf);
  $Users = Users->new($db, $admin, $conf);
  $Fees = Fees->new($db, $admin, $conf);
  $Nas = Nas->new($db, $conf, $admin);

  return $self;
}

#**********************************************************
=head2 voip_user_preprocess($attr, $user) Validate voip

  attr: hash    - form

=cut
#**********************************************************
sub voip_alias_add {
  my $self = shift;
  my ($attr) = @_;

  my $validate_res = $self->voip_user_preprocess($attr, { SET => 1 });
  return $validate_res if ($validate_res->{errno});

  return {
    errstr  => 'Wrong data, field number not valid',
    errno   => 31028,
    element => $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} $lang{PHONE}", { OUTPUT2RETURN => 1, ID => 31028 })
  } if (!$attr->{NUMBER});

  return {
    errstr  => 'Wrong data, field uid not valid',
    errno   => 31031,
    element => $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} UID", { OUTPUT2RETURN => 1, ID => 31031 })
  } if (!$attr->{UID});

  $Voip->phone_aliases_add($attr);
  if (!$Voip->{errno}) {
    my $fee_res = $self->voip_user_pa_fee({
      UID    => $attr->{UID},
      NUMBER => $attr->{NUMBER}
    });
    return $fee_res if ($fee_res->{errno} && ($fee_res->{element} || $fee_res->{object}));
  }
  else {
    if ($Voip->{errno} == 7) {
      my $list = $Voip->phone_aliases_list({
        NUMBER    => $attr->{NUMBER},
        UID       => '_SHOW',
        COLS_NAME => 1,
      });

      return {
        errno  => 31030,
        element => $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} $lang{NUMBER} $lang{EXIST} UID $list->[0]->{uid}", { OUTPUT2RETURN => 1, ID => 31030 }),
        errstr => "Phone alias $attr->{NUMBER} already has user with uid $list->[0]->{uid}"
      };
    }
    else {
      return {
        errno  => 31029,
        errstr => "Failed add voip tariff for user - Voip error $Voip->{errno}/$Voip->{errstr}",
        object => $Voip,
      };
    }
  }

  return {
    result => "Added phone alias $attr->{NUMBER} for uid $attr->{UID}",
    element => $html->message('info', $lang{INFO}, $lang{ADDED}, { OUTPUT2RETURN => 1 }),
  };
}

#**********************************************************
=head2 voip_user_preprocess($attr) Validate voip

  attr: hash    - form
  params: hash
    ADMIN_RIGHTS_CHECK: boolean - basic validation of permissions and is real user
    SKIP_SERVICE_CHECK: boolean - skip checking has user service or not

=cut
#**********************************************************
sub voip_user_preprocess {
  my $self = shift;
  my ($attr, $params) = @_;

  $params = $params || {};

  return {
    result => 'OK'
  } if ($params->{SKIP_ADMIN_RIGHTS_CHECK});

  return {
    fatal   => 1,
    errno   => 31008,
    errstr  => 'Access denied',
    element => $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY}, { OUTPUT2RETURN => 1, ID => 31008 })
  } if (!$permissions{0}{4});

  return {
    fatal   => 1,
    errno   => 31032,
    errstr  => 'Access denied',
    element => $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY}, { OUTPUT2RETURN => 1, ID => 31032 })
  } if (!$permissions{0}{10});

  return {
    fatal   => 1,
    errno   => 31010,
    errstr  => 'No field uid',
    element => $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST}, { OUTPUT2RETURN => 1, ID => 31010 })
  } if (!$attr->{UID} && !($attr->{USER_INFO} && ref $attr->{USER_INFO} eq 'Users' && $attr->{USER_INFO}->{UID}));

  return {
    result => 'OK'
  } if ($params->{ADMIN_RIGHTS_CHECK});

  my $uid = $attr->{UID} || $attr->{USER_INFO}->{UID};
  $attr->{UID} = $uid;
  $Voip->user_info($uid);
  delete $Voip->{errno};

  if (!$params->{SKIP_SERVICE_CHECK}) {
    return {
      fatal   => 1,
      errno   => 31015,
      errstr  => "User doesn't have a voip service",
      element => $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE}, { OUTPUT2RETURN => 1, ID => 31015 })
    } if ($Voip->{TOTAL} < 1);
  }

  if ((!$attr->{NUMBER} && !$params->{SET}) || (defined $attr->{NUMBER} && $attr->{NUMBER} < 1)) {
    return {
      errstr  => 'Wrong data, field number not valid',
      errno   => 31001,
      element => $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} $lang{NUM}", { OUTPUT2RETURN => 1, ID => 31001 })
    };
  }

  if ($attr->{NUMBER}) {
    $attr->{NUMBER} =~ s/\s//g;
  }

  if ($attr->{CID}) {
    $attr->{CID} =~ s/\s//g;
  }

  if ($attr->{PROVISION_PORT}) {
    my $list = $Voip->user_list({
      PROVISION_PORT   => $attr->{PROVISION_PORT},
      PROVISION_NAS_ID => $attr->{PROVISION_NAS_ID},
      COLS_NAME        => 1
    });

    if ($Voip->{TOTAL} > 0 && $list->[0]{uid} != $attr->{UID}) {
      return {
        errstr  => "Port $attr->{PROVISION_PORT} exists login - $list->[0]{login}",
        errno   => 31002,
        element => $html->message('err', $lang{ERROR},
          "$lang{PORT}: $attr->{PROVISION_PORT}  $lang{EXIST}. $lang{LOGIN}: " . $html->button("$list->[0]{login}",
            "index=15&UID=" . $list->[0]{uid}), { OUTPUT2RETURN => 1, ID => 31002 })
      };
    }
  }

  if ($attr->{TP_ID}) {
    require Tariffs;
    Tariffs->import();
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});
    $Tariffs->info($attr->{TP_ID});

    return {
      fatal   => 0,
      errno   => 31013,
      errstr  => 'Unknown tpId, check available tp list',
      element => $html->message('warn', $lang{WARNING}, "$lang{ERR_WRONG_DATA}: $lang{TARIF_PLAN} ID", { OUTPUT2RETURN => 1, ID => 31013 })
    } if (!$Tariffs->{MODULE} || $Tariffs->{MODULE} ne 'Voip');
  }

  if ($attr->{DATE} && $attr->{DATE} !~ /(\d{4})-(\d{2})-(\d{2})/) {
    return {
      fatal   => 0,
      errno   => 31017,
      errstr  => 'Wrong field date, dose not match regex (\d{4})-(\d{2})-(\d{2})',
      element => $html->message('warn', $lang{WARNING}, "$lang{ERR_WRONG_DATA}: $lang{DATE}", { OUTPUT2RETURN => 1, ID => 31017 })
    };
  }

  return {
    result => 'OK'
  };
}

#**********************************************************
=head2 voip_user_add()

    TP_ID: int              - tariff id
    UID: int                - unique id of user
    USER_INFO: Users object - user object with user info

    AND another fields which can be used in Voip->user_add({ ATTR })

=cut
#**********************************************************
sub voip_user_add {
  my $self = shift;
  my ($attr) = @_;

  my $validate_res = $self->voip_user_preprocess($attr, { SKIP_SERVICE_CHECK => 1 });
  return $validate_res if ($validate_res->{errno});

  return {
    fatal   => 0,
    errno   => 31026,
    errstr  => 'No field tpId',
    element => $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} $lang{NUM}", { OUTPUT2RETURN => 1, ID => 31026 })
  } if (!$attr->{TP_ID});

  $attr->{UID} = $attr->{UID} || $attr->{USER_INFO}->{UID};

  $Voip->user_info($attr->{UID});
  return {
    errno   => 31027,
    errstr  => 'Failed add user already has voip service',
    element => $html->message('err', $lang{ERROR}, "$lang{ERR_ALREADY_ACTIVE} Voip", { OUTPUT2RETURN => 1, ID => 31027 })
  } if (!$Voip->{errno});
  $self->voip_provision();
  $Voip = Voip->new($self->{db}, $self->{admin}, $self->{conf});

  $self->voip_provision();
  $Voip->user_add({ %$attr });

  if (!$Voip->{errno}) {
    $Voip->user_info($attr->{UID});
    ::service_get_month_fee($Voip, { UID => $attr->{UID} }) if (!$attr->{DISABLE});

    if ($self->{conf}->{VOIP_ASTERISK_USERS}) {
      $self->voip_mk_users_conf($attr);
    }

    return {
      result  => 'OK',
      element => $html->message('info', $lang{INFO}, "$lang{ADDED}", { OUTPUT2RETURN => 1 })
    };
  }
  else {
    return {
      errno  => 30011,
      errstr => "Failed add voip tariff for user - Voip error $Voip->{errno}/$Voip->{errstr}",
      object => $Voip,
    };
  }
}

#**********************************************************
=head2 voip_user_chg($attr) voip user change tp

    TP_ID: int              - tariff id
    UID: int                - unique id of user
    USER_INFO: Users object - user object with user info

    AND another fields which can be used in Voip->user_change({ ATTR })

=cut
#**********************************************************
sub voip_user_chg {
  my $self = shift;
  my ($attr) = @_;

  my $validate_res = $self->voip_user_preprocess($attr, { SET => 1 });
  return $validate_res if ($validate_res->{errno});

  $self->voip_provision($attr);

  if (!$attr->{DISABLE}) {
    $attr->{TP_ID} = $Voip->{TP_ID};
  }
  else {
    delete $attr->{TP_ID};
  }

  $self->voip_provision();
  my $status = $Voip->{DISABLE};
  $Voip->user_change({ %$attr, UID => $Voip->{UID} });

  if (!$Voip->{errno}) {
    ::service_get_month_fee($Voip, { UID => $Voip->{UID} }) if (!$attr->{DISABLE} && $status);

    if ($self->{conf}->{VOIP_ASTERISK_USERS}) {
      $self->voip_mk_users_conf($attr);
    }

    return {
      result  => "OK, successfully changed tp info for user with uid $Voip->{UID}",
      element => $html->message('info', $lang{CHANGED}, $lang{CHANGED}, { OUTPUT2RETURN => 1 })
    };
  }
  else {
    return {
      fatal  => 0,
      errno  => 31019,
      errstr => "Voip error $Voip->{errno}/$Voip->{errstr}",
      object => $Voip,
    };
  }
}

#**********************************************************
=head2 voip_user_chg()

    UID: int                - unique id of user

=cut
#**********************************************************
sub voip_user_del {
  my $self = shift;
  my ($attr) = @_;

  my $validate_res = $self->voip_user_preprocess($attr, { SET => 1 });
  return $validate_res if ($validate_res->{errno});

  $self->voip_provision();
  $attr->{UID} = $attr->{UID} || $attr->{USER_INFO}->{UID};
  $Voip->{UID} = $attr->{UID};
  $Voip->user_del();

  if (!$Voip->{errno}) {
    if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
      if ($self->{conf}->{VOIP_ASTERISK_USERS}) {
        $self->voip_mk_users_conf($attr);
      }

      require Shedule;
      Shedule->import();
      my $shedule = Shedule->new($self->{db}, $self->{admin});

      $shedule->info({
        UID    => $attr->{UID},
        TYPE   => 'tp',
        MODULE => 'Voip'
      });

      if ($shedule->{TOTAL} && $shedule->{TOTAL} > 0 && $shedule->{SHEDULE_ID}) {
        $shedule->del({ ID => $shedule->{SHEDULE_ID}, UID => $attr->{UID} });
      }

      return {
        result  => 'Successfully deleted',
        element => $html->message('info', $lang{INFO}, "$lang{DELETED}", { OUTPUT2RETURN => 1 })
      };
    }
    else {
      return {
        errno   => 31037,
        errstr  => "User with uid $attr->{UID} already hasn't got a service",
        element => $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST}, { OUTPUT2RETURN => 1, ID => 31037 })
      };
    }
  }
  return $Voip;
}

#**********************************************************
=head2 voip_user_chg_tp($attr) voip user change tp

    TP_ID: int              - tariff id
    UID: int                - unique id of user
    USER_INFO: Users object - user object with user info
    PERIOD: int             - period type of change
    DATE: string            - if period bigger than 0, will be used, if undefined will be used next month period

=cut
#**********************************************************
sub voip_user_chg_tp {
  my $self = shift;
  my ($attr) = @_;

  my $validate_res = $self->voip_user_preprocess($attr, { SET => 1 });
  return $validate_res if ($validate_res->{errno});

  return {
    fatal   => 0,
    errno   => 31011,
    errstr  => 'No field tpId',
    element => $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} $lang{NUM}", { OUTPUT2RETURN => 1, ID => 31011 })
  } if (!$attr->{TP_ID});

  return {
    fatal   => 0,
    errno   => 31035,
    errstr  => 'Same tpId which already active',
    element => $html->message('warn', $lang{WARNING}, "$lang{TARIF_PLANS} $lang{EXIST}", { OUTPUT2RETURN => 1, ID => 31035 })
  } if ($attr->{TP_ID} eq ($Voip->{TP_ID} || ''));

  $attr->{PERIOD} //= 0;

  require Shedule;
  Shedule->import();
  my $Schedule = Shedule->new($self->{db}, $self->{admin});

  $Schedule->info({
    UID    => $Voip->{UID},
    TYPE   => 'tp',
    MODULE => 'Voip'
  });

  if ($attr->{PERIOD}) {
    my ($year, $month, $day);
    if ($attr->{DATE}) {
      ($year, $month, $day) = split(/-/, $attr->{DATE}, 3);
    }
    else {
      my $date = next_month({ DATE => $main::DATE });
      ($year, $month, $day) = split(/-/, $date, 3);
    }

    my $selected_time = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

    if ($selected_time <= time()) {
      return {
        fatal   => 0,
        errno   => 31036,
        errstr  => "Wrong field date, date in less than available, must be bigger than $main::DATE",
        element => $html->message('warn', $lang{WARNING}, "$lang{ERR_WRONG_DATA} $lang{DATE}", { OUTPUT2RETURN => 1, ID => 31036 })
      };
    }

    $Schedule->add({
      UID      => $Voip->{UID},
      TYPE     => 'tp',
      ACTION   => $attr->{TP_ID},
      D        => $day,
      M        => $month,
      Y        => $year,
      DESCRIBE => "Voip FROM: '$year-$month-$day'",
      MODULE   => 'Voip',
    });

    if ($Schedule->{errno}) {
      return {
        errno  => 31020,
        errstr => "Failed to set voip tariff change $Schedule->{errno}/$Schedule->{errstr}",
        object => $Schedule,
      };
    }
    else {
      return {
        result    => "OK, successfully changed tp info for user with uid $Voip->{UID}",
        holdup_id => $Schedule->{INSERT_ID},
        element   => $html->message('info', $lang{CHANGED}, $lang{CHANGED}, { OUTPUT2RETURN => 1 })
      };
    }
  }
  else {
    delete $attr->{ID} if (!$attr->{ID});
    $Voip->user_change({ TP_ID => $attr->{TP_ID}, UID => $Voip->{UID} });
    if (!$Voip->{errno}) {
      ::service_get_month_fee($Voip, { UID => $Voip->{UID} }) if ($attr->{GET_ABON});
      if ($self->{conf}->{VOIP_ASTERISK_USERS}) {
        $self->voip_mk_users_conf($attr);
      }

      return {
        result  => "OK, successfully changed tp info for user with uid $Voip->{UID}",
        element => $html->message('info', $lang{CHANGED}, $lang{CHANGED}, { OUTPUT2RETURN => 1 })
      };
    }
    else {
      return {
        errno  => 31021,
        errstr => "Failed change voip tariff for user - Voip error $Voip->{errno}/$Voip->{errstr}",
        object => $Voip,
      };
    }
  }
}

#**********************************************************
=head2 voip_user_phone_aliases($attr) User phone alias fee

  UID: int - unique user id

=cut
#**********************************************************
sub voip_schedule_tp_del {
  my $self = shift;
  my ($attr) = @_;

  my $validate_res = $self->voip_user_preprocess($attr, { SET => 1 });
  return $validate_res if ($validate_res->{errno});

  require Shedule;
  Shedule->import();
  my $Schedule = Shedule->new($self->{db}, $self->{admin});

  $attr->{UID} = $Voip->{UID};

  $Schedule->info({
    UID    => $attr->{UID},
    TYPE   => 'tp',
    MODULE => 'Voip'
  });

  if ($Schedule->{TOTAL} > 0) {
    my $id = $Schedule->{SHEDULE_ID};
    $Schedule->del({ ID => $Schedule->{SHEDULE_ID}, UID => $attr->{UID} });

    if (!$Schedule->{errno}) {
      return {
        result  => "Ok successfully deleted schedule id $id for user with uid $attr->{UID}",
        element => $html->message('info', $lang{INFO}, "$lang{DELETED}", { OUTPUT2RETURN => 1 }),
      };
    }
    else {
      return {
        errno  => 31022,
        errstr => "Failed to set voip tariff change $Schedule->{errno}/$Schedule->{errstr}",
        object => $Schedule,
      };
    };
  }
  else {
    return {
      errno   => 30023,
      errstr  => "No tp change schedule for user with uid $attr->{UID}",
      element => $html->message('warn', $lang{WARNING}, "$lang{NO} $lang{SHEDULE}", { OUTPUT2RETURN => 1, ID => 30023 }),
    };
  }
}

#**********************************************************
=head2 voip_user_phone_aliases($attr) User phone alias fee

=cut
#**********************************************************
sub voip_user_pa_fee {
  shift;
  my ($attr) = @_;

  return {
    errstr  => "No field uid",
    errno   => 31003,
    element => $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST}, { OUTPUT2RETURN => 1, ID => 31003 })
  } if (!$attr->{UID});

  my $user_info = $Voip->user_info($attr->{UID});

  if ($user_info->{EXTRA_NUMBERS_DAY_FEE} && $user_info->{EXTRA_NUMBERS_DAY_FEE} > 0) {
    $Fees->take(
      $Users->info($attr->{UID}),
      $user_info->{EXTRA_NUMBERS_DAY_FEE},
      {
        DESCRIBE => "$lang{ACTIVATE}: $attr->{NUMBER}",
        DATE     => "$main::DATE $main::TIME"
      }
    );
  }

  if ($user_info->{EXTRA_NUMBERS_MONTH_FEE} && $user_info->{EXTRA_NUMBERS_MONTH_FEE} > 0) {
    $Fees->take(
      $Users->info($attr->{UID}),
      $user_info->{EXTRA_NUMBERS_MONTH_FEE},
      {
        DESCRIBE => "$lang{ACTIVATE}: $attr->{NUMBER}",
        DATE     => "$main::DATE $main::TIME"
      }
    );
  }

  if ($Fees->{errno}) {
    return {
      errstr => "Fees error",
      errno  => 31004,
      object => $Fees,
    };
  }

  return {
    result => 'OK'
  };
}

#***********************************************************
=head2 voip_mk_users_conf($attr) - Add asterisk user

=cut
#***********************************************************
sub voip_mk_users_conf {
  my $self = shift;
  my ($attr) = @_;

  ::load_module('AXbills::Templates', { LOAD_PACKAGE => 1 }) if (!exists($INC{"AXbills/Templates.pm"}));

  my $content = '';

  my $list = $Voip->user_list({
    PAGE_ROWS => 100000,
    CID       => '_SHOW',
    NUMBER    => '_SHOW',
    PASSWORD  => '_SHOW',
    IP        => '_SHOW',
    FIO       => '_SHOW',
    REDUCTION => '_SHOW',
    BILL_ID   => '_SHOW',
    ACTIVATE  => '_SHOW',
    DEPOSIT   => '_SHOW',
    CREDIT    => '_SHOW',
    STATUS    => '_SHOW',
    CID       => '_SHOW',
    COLS_NAME => 1
  });

  foreach my $line (@{$list}) {
    my %info = (
      LOGIN     => $line->{login},
      FIO       => $line->{fio},
      NUMBER    => $line->{number},
      CALLER_ID => $line->{cid},
      PASSWORD  => $line->{password},
      HOST      => ($line->{ip} eq '0.0.0.0') ? 'dynamic' : $line->{ip},
      DATE      => $main::DATE,
      TIME      => $main::TIME
    );
    $content .= $html->tpl_show(::_include('voip_users_conf', 'Voip'), \%info,
      { OUTPUT2RETURN => 1, CONFIG_TPL => 1 });
  }

  if ($self->{conf}->{VOIP_ASTERISK_USERS}) {
    my $dir_name = dirname($self->{conf}->{VOIP_ASTERISK_USERS});
    my $filename = $self->{conf}->{VOIP_ASTERISK_USERS};
    $filename =~ s/$dir_name\///;
    ::file_op({
      WRITE    => 1,
      FILENAME => $filename,
      PATH     => $dir_name,
      CONTENT  => $content
    });
  }

  if ($self->{conf}->{VOIP_ASTERISK_RESTART}) {
    cmd($self->{conf}->{VOIP_ASTERISK_RESTART}, {
      PARAMS  => { %{($attr) ? $attr : {}}, },
      SET_ENV => 1
    });
  }

  return 1;
}

#**********************************************************
=head2 voip_provision($attr) -  Provision

=cut
#**********************************************************
sub voip_provision {
  shift;

  my $list = $Nas->list({ TYPE => 'ls_pap2t;ls_spa8000', COLS_NAME => 1 });
  ::load_module('AXbills::Templates', { LOAD_PACKAGE => 1 }) if (!exists($INC{"AXbills/Templates.pm"}));

  my $hosts = '';
  foreach my $line (@{$list}) {
    $hosts .= $html->tpl_show(
      ::_include('voip_provision_dhcp_host', 'Voip'),
      {
        NAS_ID   => $line->{nas_id},
        HOSTNAME => $line->{nas_name},
        MAC      => $line->{mac},
        IP       => $line->{nas_ip},
        ROUTERS  => '',
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  my $conf = $html->tpl_show(::_include('voip_provision_dhcp_conf', 'Voip'), { HOSTS => $hosts },
    { OUTPUT2RETURN => 1 });

  if (open(my $fh, '>', "$main::base_dir/AXbills/templates/provision_dhcp.conf")) {
    print $fh "$conf\n";
    close($fh);
  }

  return 1;
}

#**********************************************************
=head voip_recalculate_sum - Recalculate sessions sum

=cut
#**********************************************************
sub voip_recalculate_sum {
  my $self = shift;
  my ($user_info, $attr) = @_;

  my Users $users = $user_info;
  $attr->{UID} = $users->{UID};

  return {
    errstr  => "Fees error",
    errno   => 31007,
    element => $html->message('err', $lang{ERROR}, "$lang{USER_NOT_EXIST}", { OUTPUT2RETURN => 1, ID => 31007 })
  } unless ($attr->{UID});

  require Voip_Sessions;
  Voip_Sessions->import();
  my $Sessions = Voip_Sessions->new($self->{db}, $self->{admin}, $self->{conf});

  my $sessions_list = $Sessions->list({
    LOGIN            => '_SHOW',
    START            => '_SHOW',
    START_UNIXTIME   => '_SHOW',
    ASSTART_UNIXTIME => '_SHOW',
    DURATION         => '_SHOW',
    DURATION_SEC     => '_SHOW',
    SUM              => '_SHOW',
    TP_ID            => '_SHOW',
    ROUTE_ID         => '_SHOW',
    CALL_ORIGIN      => '_SHOW',
    PAGE_ROWS        => 1000000,
    COLS_NAME        => 1,
    %{$attr || {}},
  });

  require Finance;
  Finance->import();
  my $Payments = Finance->payments($self->{db}, $self->{admin}, $self->{conf});
  require Billing;
  Billing->import();
  my $Billing = Billing->new($self->{db}, $self->{conf});
  require Voip_aaa;
  Voip_aaa->import();
  my $Voip_aaa = Voip_aaa->new($self->{db}, $self->{conf});
  my $user = $Voip->user_info($attr->{UID});
  my $params = ();
  $params->{NEWSUM} = 0;
  $params->{OLDSUM} = 0;

  foreach my $line (@$sessions_list) {
    $Voip_aaa->{TP_ID} = $line->{tp_id};
    $Voip_aaa->{ROUTE_ID} = $line->{route_id};
    $Voip_aaa->get_intervals();

    if ($line->{call_origin} == 1) {
      $Billing->time_calculation({
        REDUCTION          => $user->{REDUCTION},
        TIME_INTERVALS     => $Voip_aaa->{TIME_PERIODS},
        PERIODS_TIME_TARIF => $Voip_aaa->{PERIODS_TIME_TARIF},
        SESSION_START      => $line->{asstart_unixtime},
        ACCT_SESSION_TIME  => $line->{duration_sec},
        DAY_BEGIN          => $line->{day_begin},
        DAY_OF_WEEK        => $line->{day_of_week},
        DAY_OF_YEAR        => $line->{day_of_year},
        PRICE_UNIT         => 'Min',
        DEBUG              => 1,
      });
      my $newsum = sprintf("%.6f", $Billing->{SUM});
      $params->{NEWSUM} += $newsum;
      $params->{OLDSUM} += $line->{sum};

      if ($line->{sum} != $newsum) {
        $Sessions->change_sum({
          SUM             => $newsum,
          ACCT_SESSION_ID => $line->{acct_session_id},
          UID             => $user->{UID}
        });
      }
    }
  }

  if ($params->{NEWSUM} == $params->{OLDSUM}) {
    return {
      result => 'OK',
      element => $html->message('info', $lang{RECALCULATE}, $lang{NO_CHANGES}, { OUTPUT2RETURN => 1 })
    };
  }
  elsif ($params->{NEWSUM} > $params->{OLDSUM}) {
    $Fees->take(
      $users,
      sprintf("%.2f", $params->{NEWSUM} - $params->{OLDSUM}),
      {
        DESCRIBE => "Voip $lang{RECALCULATE}: $attr->{FROM_DATE}/$attr->{TO_DATE}"
      }
    );
    $self->{admin}->action_add($users->{UID}, "$lang{RECALCULATE} Voip: $attr->{FROM_DATE}/$attr->{TO_DATE}, $lang{GETED}: "
      . sprintf("%.2f", $params->{NEWSUM} - $params->{OLDSUM}), {});

    if ($Payments->{errno}) {
      return {
        errstr => "Fees error",
        errno  => 31006,
        object => $Fees,
      };
    }
    else {
      return {
        result => 'OK',
        element => $html->message('info', $lang{RECALCULATE}, "$lang{GETED}: " . sprintf("%.2f", $params->{NEWSUM} - $params->{OLDSUM}), { OUTPUT2RETURN => 1 }),
      };
    }
  }
  elsif ($params->{NEWSUM} < $params->{OLDSUM}) {
    $Payments->add(
      {
        BILL_ID => $users->{BILL_ID} || $user->{BILL_ID},
        UID     => $users->{UID} || $attr->{UID},
      },
      {
        SUM      => sprintf("%.2f", $params->{OLDSUM} - $params->{NEWSUM}),
        METHOD   => 6,
        DESCRIBE => "Voip $lang{COMPENSATION}: $attr->{FROM_DATE}/$attr->{TO_DATE}",
      }
    );
    $self->{admin}->action_add($users->{UID}, "Voip : $attr->{FROM_DATE}/$attr->{TO_DATE}, $lang{COMPENSATION}: "
      . sprintf("%.2f", $params->{OLDSUM} - $params->{NEWSUM}), {});

    if ($Payments->{errno}) {
      return {
        errstr => "Payment error",
        errno  => 31005,
        object => $Payments,
      };
    }
    else {
      return {
        result => 'OK',
        element => $html->message('info', "$lang{COMPENSATION}", "$lang{COMPENSATION} $lang{SUM}: " . sprintf("%.2f", $params->{OLDSUM} - $params->{NEWSUM}), { OUTPUT2RETURN => 1 }),
      };
    }
  }
}

#**********************************************************
=head2 voip_user_number_add ($attr) - add voip number to user from pool $conf{VOIP_NUM_POOL} after registration

     $attr:
       uid - user id

=cut
#**********************************************************
sub voip_user_number_add {
  my $self = shift;
  my ($uid) = @_;

  my $pool_numbers = $self->{conf}->{VOIP_NUM_POOL};
  $pool_numbers =~ s/ //g;
  my @pool_numbers = split(/;\s?/, $pool_numbers);

  my $voip_user_list = $Voip->user_list({
    NUMBER    => $pool_numbers,
    COLS_NAME => 1
  });

  foreach my $voip_user (@$voip_user_list){
    @pool_numbers = grep {$_ ne $voip_user->{number}} @pool_numbers;
  }

  my $available_number = $pool_numbers[0] || '';

  if ($available_number){
    $Voip->user_add({
        UID     => $uid,
        DISABLE => 0,
        NUMBER  => $available_number
    });
    $html->message('info', "VoIP: $lang{SUCCESS}", "$lang{ADDED} $lang{NUMBER} $available_number");
  }
  else {
    $html->message('danger', "VoIP: $lang{ERROR}", $lang{NOT_AVAILABLE_NUMBER_FROM_POOL});
  }

  return 1;
}

1;
