#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

our (
  %FORM,
  %COOKIES,
  $DATE,
  $TIME,
  %conf,
  %lang,
  $base_dir,
  $db,
  $html,
);

our Users  $users;
our Users  $user;
our Admins $admin;
our Tariffs  $Tariffs;
our Internet $Internet;
our Hotspot $Hotspot;
use AXbills::Base qw/_bp/;
use Time::Piece;

#**********************************************************
=head2 hotspot_init()

=cut
#**********************************************************
sub hotspot_init {
  #check params
  if (!$FORM{server_name} && !$COOKIES{server_name}) {
    errexit("Unknown hotspot.");
  }
  elsif (!$FORM{mac} || $FORM{mac} !~ /^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$/) {
    errexit("Unknown mac.");
  }

  #load hotspot conf
  $Hotspot->load_conf($FORM{server_name} || $COOKIES{server_name});

  #domain info
  if ( $Hotspot->{HOTSPOT_CONF}->{DOMAIN_ID} ){
    $Hotspot->{admin}->info( '', { DOMAIN_ID => $Hotspot->{HOTSPOT_CONF}->{DOMAIN_ID} } );
    if($Hotspot->{admin}->{errno}) {
      errexit("Unknown domain admin.");
    }
  }

  #set cookie
  my %new_cookies = ();
  $new_cookies{mac}         = $FORM{mac}             if ($FORM{mac});
  $new_cookies{server_name} = $FORM{server_name}     if ($FORM{server_name});
  $new_cookies{link_login}  = $FORM{link_login_only} if ($FORM{link_login_only});
  mk_cookie(\%new_cookies);

  #load scheme
  if (!$Hotspot->{HOTSPOT_CONF}->{SCHEME}) {
    errexit("Unknown scheme.");
  }
  my $scheme_name = $Hotspot->{HOTSPOT_CONF}->{SCHEME};
  eval { require "Hotspot/Scheme/$scheme_name.pm"; 1; };
  if ($@) {
    errexit("Cant load scheme $scheme_name.<br>$@");
  }
  if (!$Hotspot->{HOTSPOT_CONF}->{HOTSPOT_TPS}) {
    errexit("Miss required config key HOTSPOT_TPS for $FORM{server_name}");
  }
  ($Hotspot->{DEFAULT_TP}) = split('\;', $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_TPS});
  check_config();
  return 1;
}

#**********************************************************
=head2 check_config()
  Check required config fields

=cut
#**********************************************************
sub check_config {
  my $key_list = required_fields();
  foreach (@$key_list) {
    errexit("Miss required config key $_ for $FORM{server_name}") unless $Hotspot->{HOTSPOT_CONF}->{$_};
  }
  return 1;
}

#**********************************************************
=head2 hotspot_radius_error()

=cut
#**********************************************************
sub hotspot_radius_error {
  if ($FORM{error} =~ /USER_NOT_EXIST/) {
    delete_old_cookie();
    return 1;
  }
  scheme_radius_error($FORM{error});
  errexit($FORM{error});
}

#**********************************************************
=head2 hotspot_pre_auth()

=cut
#**********************************************************
sub hotspot_pre_auth {
  if ($FORM{ajax}) {
    hotspot_ajax();
  }
  else {
    scheme_pre_auth();
  }

  return 1;
}

#**********************************************************
=head2 hotspot_auth()

=cut
#**********************************************************
sub hotspot_auth {
  scheme_auth();
  return 1;
}

#**********************************************************
=head2 hotspot_registration()

=cut
#**********************************************************
sub hotspot_registration {
  scheme_registration();
  return 1;
}

#**********************************************************
=head2 hotspot_user_registration()

=cut
#**********************************************************
sub hotspot_user_registration {
  my ($attr) = @_;

  if ($Hotspot->{TP_ID}) {
    $Tariffs->info($Hotspot->{TP_ID});
  }
  else {
    my $tp = $Hotspot->{HOTSPOT_CONF}->{TRIAL_TP} || $Hotspot->{DEFAULT_TP};
    $Tariffs->info( '', { ID => $tp} );
  }
  my $tp_id = $Tariffs->{TP_ID};

  if (!$tp_id) {
    errexit("Sorry, can't find tarif for new users.");
  }
  
  my $activate = '0000-00-00';
  my $expire   = '0000-00-00';
  if ($Tariffs->{AGE}) {
    $activate = $DATE;
    my $e_time = Time::Piece->strptime($DATE, "%Y-%m-%d") + $Tariffs->{AGE} * 86400;
    $expire = $e_time->ymd;
  }

  my $domain_id = $Hotspot->{HOTSPOT_CONF}->{DOMAIN_ID} || $admin->{DOMAIN_ID} || 0;

  my $login = $Hotspot->next_login({
    LOGIN_LENGTH => $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_LOGIN_LENGTH} || 6,
    LOGIN_PREFIX => $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_LOGIN_PREFIX} || '',
    DOMAIN_ID    => $domain_id,
  });
  my $password = int(rand(90000000)) + 10000000;
  my $cid = uc($attr->{ANY_MAC} ? 'ANY' : $FORM{mac});
  my $group_id = 0;

  if ( $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_GUESTS_GROUP} && $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_GUESTS_GID} ) {
    my $group_name = $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_GUESTS_GROUP};
    $group_id = $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_GUESTS_GID};
    $users->group_info($group_id);
    if ($users->{errno}) {
      $users->group_add({
        GID       => $group_id,
        NAME      => $group_name,
        DOMAIN_ID => $domain_id,
        DESCR     => 'Hotspot guest group'
      });
    }
  }

  $users->add({
    LOGIN       => $login,
    PASSWORD    => $password,
    GID         => $group_id,
    DOMAIN_ID   => $domain_id,
    ACTIVATE    => $activate,
    EXPIRE      => $expire,
    CREATE_BILL => 1,
  });
  if ($users->{errno}) {
    errexit("Sorry, can't add user.");
  }
  my $uid = $users->{UID};
  $users->pi_add({ UID => $uid, PHONE => ($FORM{PHONE} || '') });

  $Internet->user_add({
    INTERNET_SKIP_FEE => ($Hotspot->{SKIP_FEE} || ''),
    UID               => $uid,
    TP_ID             => $tp_id,
    CID               => $cid,
    SERVICE_ACTIVATE  => $activate,
    SERVICE_EXPIRE    => $expire,
  });
  if ($Internet->{errno}) {
    errexit("Sorry, can't add internet service. $Internet->{errstr}");
  }

  $Hotspot->log_add({
    HOTSPOT  => $COOKIES{server_name},
    CID      => $FORM{mac},
    ACTION   => 1,
    PHONE    => $FORM{PHONE} || '',
    COMMENTS => "$login registred, UID:$uid"
  });

  if ($attr->{RECHARGE}) {
    use Finance;
    my $Fees = Finance->fees($db, $admin, \%conf);
    $Fees->take(
      $users,
      $Tariffs->{ACTIV_PRICE},
      { 
        DESCRIBE => "Take hotspot activation sum",
        METHOD   => 0
      },
    );
    recharge_balance($uid);
  }

  mikrotik_login({ LOGIN => $login, PASSWORD => $password });
  
  exit;
}

#**********************************************************
=head2 mac_login()
  Search user with CID = $FORM(mac) and redirect to 
  Hotspot login page.
=cut
#**********************************************************
sub mac_login {
  my $list = $Internet->user_list({
    PASSWORD       => '_SHOW',
    LOGIN          => '_SHOW',
    PHONE          => '_SHOW',
    SERVICE_EXPIRE => "0000-00-00,>$DATE",
    CID            => $FORM{mac},
    TP_NUM         => $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_TPS},
    COLS_NAME      => 1,
  });

  if ( $Internet->{TOTAL} > 0 ){
    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 2,
      PHONE    => $FORM{PHONE} || $list->[0]->{phone},
      COMMENTS => "$list->[0]->{login} $FORM{mac} MAC login"
    });

    mikrotik_login({LOGIN => $list->[0]->{login}, PASSWORD => $list->[0]->{password}});
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
    errexit("Wrong phone.");
  }
  my $list = $Internet->user_list({
    PASSWORD       => '_SHOW',
    LOGIN          => '_SHOW',
    PHONE          => $FORM{PHONE},
    SERVICE_EXPIRE => "0000-00-00,>$DATE",
    TP_NUM         => $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_TPS},
    COLS_NAME      => 1,
  });
  if ( $Internet->{TOTAL} > 0 ){
    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 5,
      PHONE    => $FORM{PHONE},
      COMMENTS => "$list->[0]->{login} $FORM{PHONE} PHONE login"
    });

    mikrotik_login({LOGIN => $list->[0]->{login}, PASSWORD => $list->[0]->{password}});
    exit;
  }
  return 1;
}

#**********************************************************
=head2 check_phone_verify()

=cut
#**********************************************************
sub check_phone_verify {
  my $hot_log = $Hotspot->log_list({
    CID       => $FORM{mac},
    INTERVAL  => "$DATE/$DATE",
    ACTION    => 12,
    PHONE     => '_SHOW',
    COLS_NAME => 1,
  });

  if ($Hotspot->{TOTAL} > 0) {
    $FORM{PHONE} = $hot_log->[0]->{phone};
    return 1;
  }
  return 0;
}

#**********************************************************
=head2 ask_phone()

=cut
#**********************************************************
sub ask_phone {
  return 1 if ($FORM{PHONE});
  my $phone_tpl = $Hotspot->{HOTSPOT_CONF}->{PHONE_TPL} || 'form_client_hotspot_phone';
  print $html->header();
  print $html->tpl_show(templates($phone_tpl), \%FORM);
  exit;
}

#**********************************************************
=head2 ask_pin()

=cut
#**********************************************************
sub ask_pin {
  return 1 if ($FORM{PIN});

  $Hotspot->log_list({
    PHONE     => $FORM{PHONE},
    CID       => $FORM{mac},
    INTERVAL  => "$DATE/$DATE",
    ACTION    => 11,
    COMMENTS  => '_SHOW',
    COLS_NAME => 1,
  });
  if ($Hotspot->{TOTAL} < 1 || $FORM{send_pin}) {
    send_pin();
  }
  my $pin_tpl = $Hotspot->{HOTSPOT_CONF}->{PIN_TPL} || 'hotspot_pin';
  print $html->header();
  print $html->tpl_show(_include($pin_tpl, 'Hotspot'), \%FORM);
  exit;
}

#**********************************************************
=head2 send_pin()

=cut
#**********************************************************
sub send_pin {
  my $pin = int(rand(900)) + 100;
  use Sms::Init;
  my $Sms_service = init_sms_service($db, $admin, \%conf);
  $Sms_service->send_sms({
    NUMBER     => $FORM{PHONE},
    MESSAGE    => "CODE: $pin",
  });

  $Hotspot->log_add({
    HOTSPOT  => $COOKIES{server_name},
    CID      => $FORM{mac},
    ACTION   => 11,
    PHONE    => $FORM{PHONE},
    COMMENTS => "Send PIN: $pin"
  });
  return 1;
}

#**********************************************************
=head2 verify_pin()

=cut
#**********************************************************
sub verify_pin {
  my $hot_log = $Hotspot->log_list({
    PHONE     => $FORM{PHONE},
    INTERVAL  => "$DATE/$DATE",
    ACTION    => 11,
    COMMENTS  => '_SHOW',
    COLS_NAME => 1,
  });

  if (($Hotspot->{TOTAL} > 0) && ($hot_log->[0]->{comments} eq "Send PIN: $FORM{PIN}" )) {
    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 12,
      PHONE    => $FORM{PHONE},
      COMMENTS => 'Phone confirmed.'
    });
  }
  else {
    errexit("Wrong PIN.");
  }
  return 1;
}

#**********************************************************
=head2 verify_call()

=cut
#**********************************************************
sub verify_call {
  $Hotspot->log_add({
    HOTSPOT  => $COOKIES{server_name},
    CID      => $FORM{mac},
    ACTION   => 11,
    PHONE    => $FORM{PHONE},
    COMMENTS => "Waiting for client call."
  });

  my $auth_tpl = $Hotspot->{HOTSPOT_CONF}->{CALL_AUTH_TPL} || 'form_client_hotspot_call_auth';
  my $reload_btn = $html->button($lang{CONTINUE}, '',
    { GLOBAL_URL => $COOKIES{link_login} || $FORM{link_login_only}, class => 'btn btn-success' });
  print $html->header();
  print $html->tpl_show(templates($auth_tpl), {
    AUTH_NUMBER => $Hotspot->{HOTSPOT_CONF}->{AUTH_NUMBER},
    mac         => $FORM{mac},
    PHONE       => $FORM{PHONE},
    BUTTON      => $reload_btn,
  });
  exit;
}

#**********************************************************
=head2 hotspot_sms_pay()

=cut
#**********************************************************
sub hotspot_sms_pay{
  my ($uid) = @_;
  $users->info($uid);
  exit if ($users->{errno});
  $users->pi();
  my $sms_pay_tpl = $Hotspot->{HOTSPOT_CONF}->{SMS_PAY_TPL} || 'hotspot_sms_pay';
  my $mac = uc($FORM{mac});
  $mac =~ s/://g;
  my $params = ();
  $params->{SMS_CODE} = "ICNHS+$mac";
  $params->{mac}  = $FORM{mac};
  $params->{date} = "$DATE $TIME";  
  if ($users->{PHONE}) {
    $params->{HIDE_BUTTON} = 'style="display:none"';
  }
  else {
    $params->{SMS_FREE_CODE} = "ICNFREEHS+$mac";
  }
  print $html->header();
  print $html->tpl_show(_include($sms_pay_tpl, 'Hotspot'), \%FORM);
  exit;
}

#**********************************************************
=head2 user_portal_redirect()

=cut
#**********************************************************
sub user_portal_redirect {
  my $hotspot_username = $FORM{hotspot_username} || $COOKIES{hotspot_username};
  my $hotspot_password = $FORM{hotspot_password} || $COOKIES{hotspot_password};
  if ($hotspot_username && $hotspot_password) {
    my $user_portal_url = "index.cgi?user=$hotspot_username&passwd=$hotspot_password";
    print "Location: $user_portal_url\n\n";
    exit;
  }
  elsif ($FORM{mac}) {
    my $list = $Internet->user_list({
      PASSWORD       => '_SHOW',
      LOGIN          => '_SHOW',
      PHONE          => '_SHOW',
      SERVICE_EXPIRE => "0000-00-00,>$DATE",
      CID            => $FORM{mac},
      TP_NUM         => $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_TPS},
      COLS_NAME      => 1,
    });
    my $user_portal_url = "index.cgi?user=" . $list->[0]->{login} . "&passwd=" . $list->[0]->{password};
    print "Location: $user_portal_url\n\n";
    exit;
  }
  errexit("Something wrong");
  return 1;
}

#**********************************************************
=head2 cookie_login()

=cut
#**********************************************************
sub cookie_login {
  return 1 if (!$COOKIES{hotspot_username} || !$COOKIES{hotspot_password});
  $Hotspot->log_add({
    HOTSPOT  => $COOKIES{server_name},
    CID      => $FORM{mac},
    ACTION   => 3,
    COMMENTS => "User:$COOKIES{hotspot_username} cookies login"
  });
  mikrotik_login({LOGIN => $COOKIES{hotspot_username}, PASSWORD => $COOKIES{hotspot_password}});
  exit;
}

#**********************************************************
=head2 mikrotik_login()
    
=cut
#**********************************************************
sub mikrotik_login {
  my ($attr) = @_;
  my $tpl = 'hotspot_auto_login';
  my $ad_to_show = ();

  mk_cookie({
    hotspot_username=> $attr->{LOGIN},
    hotspot_password=> $attr->{PASSWORD},
  });

  print "Content-type:text/html\n\n";
  print $html->tpl_show(_include($tpl, 'Hotspot'), {
    LOGIN              => $attr->{LOGIN},
    PASSWORD           => $attr->{PASSWORD},
    HOTSPOT_AUTO_LOGIN => $COOKIES{link_login} || $FORM{link_login_only} || '1',
    DST                => 'http://google.com',
  });

  return 1;
}

#**********************************************************
=head2 hotspot_ajax()

=cut
#**********************************************************
sub hotspot_ajax {
  print "Content-type:text/html\n\n";
  if ($FORM{ajax} == 1) {
    # Check auth call
    my $hot_log = $Hotspot->log_list({
      PHONE     => $FORM{PHONE},
      CID       => $FORM{mac},
      INTERVAL  => "$DATE/$DATE",
      ACTION    => 12,
    });
    print ($Hotspot->{TOTAL} < 1 ? 0 : 1);
  }
  elsif ($FORM{ajax} == 2) {
    my $hot_log = $Hotspot->log_list({
      CID       => $FORM{mac},
      DATE      => ">$FORM{date}",
      ACTION    => '23,24',
    });
    print ($Hotspot->{TOTAL} < 1 ? 0 : 1);
  }
  else {
    print 0;
  }
  exit;
}

#**********************************************************
=head2 get_user_uid ()

=cut
#**********************************************************
sub get_user_uid {
  my %params;
  if ($COOKIES{hotspot_username}) {
    %params = (LOGIN => $COOKIES{hotspot_username});
  }
  elsif (check_phone_verify()) {
    %params = (PHONE => $FORM{PHONE});
  }
  else {
    %params = (CID => uc($FORM{mac}));
  }

  my $list = $Internet->user_list({
    %params,
    DOMAIN_ID      => $Hotspot->{HOTSPOT_CONF}->{DOMAIN_ID} || '',
    TP_NUM         => $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_TPS},
    SERVICE_EXPIRE => "0000-00-00,>$DATE",
    COLS_NAME      => 1,
  });
  
  if ( $Internet->{TOTAL} < 1 ){
    return 0;
  }

  return $list->[0]{uid};
}

#**********************************************************
=head2 trial_tp_change ()

=cut
#**********************************************************
sub trial_tp_change {
  my ($uid) = @_;

  return unless ($uid);
  $Internet->user_info($uid);
  if ($Internet->{TP_NUM} eq $Hotspot->{HOTSPOT_CONF}->{TRIAL_TP}) {
    $Tariffs->info( '', { ID => $Hotspot->{DEFAULT_TP} });
    $Hotspot->change_tp({
      UID   => $uid,
      TP_ID => $Tariffs->{TP_ID},
    });

    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name} || $FORM{server_name},
      CID      => $FORM{mac},
      ACTION   => 6,
      COMMENTS => "User:$uid change trial tp",
    });
  }
  return 1;
}

#**********************************************************
=head2 choose_tp ()

=cut
#**********************************************************
sub choose_tp {
  if (!$FORM{TP_ID}) {
    online_payment_tp_sel();
  }
  else {
    $Hotspot->{TP_ID} = $FORM{TP_ID};
    $Hotspot->{SKIP_FEE} = 1;
  }
  return 1;
}

#**********************************************************
=head2 online_payment_tp_sel()
  select tp for new user
=cut
#**********************************************************
sub online_payment_tp_sel {

  my $list = $Tariffs->list({
    PAYMENT_TYPE     => '<2',
    TOTAL_TIME_LIMIT => '_SHOW',
    TOTAL_TRAF_LIMIT => '_SHOW',
    ACTIV_PRICE      => '_SHOW',
    AGE              => '_SHOW',
    NAME             => '_SHOW',
    IN_SPEED         => '_SHOW',
    OUT_SPEED        => '_SHOW',
    DOMAIN_ID        => ($Hotspot->{HOTSPOT_CONF}->{DOMAIN_ID} || ''),
    TP_ID            => $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_TPS},
    COLS_NAME        => 1,
  });

  my $cards = '';
  my $params = "&PHONE=$FORM{PHONE}&mac=$FORM{mac}&server_name=$FORM{server_name}&link_login_only=$FORM{link_login_only}";
  my $tpl = $Hotspot->{HOTSPOT_CONF}->{TP_CARD_TPL} || 'form_buy_cards_card';
  foreach my $line (@{$list}) {
    $cards .= $html->tpl_show(templates($tpl), {
      TP_NAME         => $line->{name},
      ID              => $line->{id},
      TP_ID           => $line->{tp_id},
      AGE             => $line->{age} || $lang{UNLIM},
      DOMAIN_ID       => $Hotspot->{HOTSPOT_CONF}->{DOMAIN_ID} || '',
      SPEED_IN        => $line->{in_speed} || $lang{UNLIM},
      SPEED_OUT       => $line->{out_speed} || $lang{UNLIM},
      PREPAID_MINS    => $line->{total_time_limit} ? sprintf("%.1f", $line->{total_time_limit} / 60 / 60) : $lang{UNLIM},
      PREPAID_TRAFFIC => $line->{total_traf_limit} || $lang{UNLIM},
      PRICE           => $line->{activate_price} || 0.00,
      HOTSPOT_PARAMS  => $params,
    }, { OUTPUT2RETURN => 1 });
  }
  print $html->header();
  print $cards;
  exit;
}

#**********************************************************
=head2 recharge_balance()
  fast redirect to $Hotspot->{HOTSPOT_CONF}{PAYMENT_URL}
=cut
#**********************************************************
sub recharge_balance {
  my ($uid) = @_;
  $uid = get_user_uid() unless ($uid);
  return 1 unless ($uid);

  my $internet_info = $Internet->user_info($uid);
  $Tariffs->info($internet_info->{TP_ID});
  my $payment_url = $Hotspot->{HOTSPOT_CONF}{PAYMENT_URL};
  $payment_url =~ s/%UID%/$uid/g;
  $payment_url =~ s/%SUM%/$Tariffs->{ACTIV_PRICE}/g;

  $Hotspot->log_add({
    HOTSPOT  => $COOKIES{server_name},
    CID      => $FORM{mac} || '',
    PHONE    => $FORM{PHONE} || '',
    ACTION   => 22,
    COMMENTS => "UID:$uid initiate fast online payment SUM:$Tariffs->{ACTIV_PRICE}",
  });

  print "Location: $payment_url\n\n";
  exit;
}

#**********************************************************
=head2 delete_old_cookie()

=cut
#**********************************************************
sub delete_old_cookie {
  mk_cookie({ hotspot_username => '', hotspot_password => '' }, { DELETE => 1 });
  return 1;
}

#**********************************************************
=head2 mk_cookie($hash)

=cut
#**********************************************************
sub mk_cookie {
  my ($cookie_vals, $attr) = @_;
  my $auth_cookie_time = $attr->{DELETE} ? 0 : ($conf{AUTH_COOKIE_TIME} || 86400);
  my $cookies_time = gmtime( time() + $auth_cookie_time ) . " GMT";
  foreach my $key (keys %$cookie_vals) {
    my $value = $cookie_vals->{$key};
    my $cookie = "Set-Cookie: $key=$value; expires=\"$cookies_time\"; SameSite=None; Secure\n";
    print $cookie;
  }
  return 1;
}

#**********************************************************
=head2 errexit($str)

=cut
#**********************************************************
sub errexit {
  my ($str) = @_;
  print "Content-type:text/html\n\n";
  print $str;
  exit;
}


# Code below - payment without uid, work only with liqpay, temporaly disabled

#**********************************************************
=head2 registration_payment()
  online payment operation
  Step 1: check old payments
  Step 2: select tp
  Step 3: select system
=cut
#**********************************************************
# sub registration_payment {
#   load_module('Paysys');
#   registration_payment_check();
#   if (!$Hotspot->{TP_ID}) {
#     if ($FORM{TRUE}) {
#       errexit('Оплата еще не получена. Попробуйте подключиться позже.');
#     }
#     elsif ($FORM{PAYMENT_SYSTEM}) {
#       online_payment_make();
#     }
#     elsif ($FORM{TP_ID}) {
#       online_payment_system_sel();
#     }
#     else {
#       online_payment_tp_sel();
#     }
#   }

#   return 1;
# }

#**********************************************************
=head2 registration_payment_check()
  check activate payments
=cut
#**********************************************************
# sub registration_payment_check {
#   my $hot_log = $Hotspot->log_list({
#     CID       => $FORM{mac},
#     INTERVAL  => "$DATE/$DATE",
#     ACTION    => 21,
#     PHONE     => $FORM{PHONE},
#     COMMENTS  => '_SHOW',
#     COLS_NAME => 1,
#   });

#   if ($Hotspot->{TOTAL} > 0) {
#     my ($op_id) = $hot_log->[0]->{comments} =~ m/op_id\:\'(.*)\'/;
#     my $Paysys = Paysys->new($db, $admin, \%conf);
#     my $list = $Paysys->list({
#       TRANSACTION_ID => "*:$op_id",
#       STATUS         => 2,
#       SKIP_DEL_CHECK => 1,
#       COLS_NAME      => 1,
#       COLS_UPPER     => 1,
#     });
#     if ($Paysys->{TOTAL} > 0) {
#       ($Hotspot->{TP_ID}) = $hot_log->[0]->{comments} =~ m/tp_id\:(\d+)/;
#       $Hotspot->{SKIP_FEE} = 1;
#     }
#   }
#   return 1;
# }

#**********************************************************
=head2 online_payment_system_sel()
  user already select tp, next step choose system
=cut
#**********************************************************
# sub online_payment_system_sel {
#   my $tpl = $Hotspot->{HOTSPOT_CONF}->{PAYMENT_SYSTEM_TPL} || 'form_buy_cards_paysys';
#   my $unique = mk_unique_value(8, { SYMBOLS => '0123456789' });
#   $Tariffs->info($FORM{TP_ID});

#   print $html->header();
#   print $html->tpl_show(templates($tpl), { %FORM,
#     SUM               => $Tariffs->{ACTIV_PRICE},
#     DESCRIBE          => '',
#     OPERATION_ID      => $unique,
#     UID               => ($FORM{UID} || $unique),
#     TP_ID             => $FORM{TP_ID},
#     DOMAIN_ID         => ($Hotspot->{HOTSPOT_CONF}->{DOMAIN_ID} || ''),
#     MAC               => ($FORM{mac} || ''),
#     PAYSYS_SYSTEM_SEL => paysys_system_sel(),
#   });

#   exit;
# }

#**********************************************************
=head2 online_payment_make()
  select tp for new user
=cut
#**********************************************************
# sub online_payment_make {
#   $Hotspot->log_add({
#     HOTSPOT  => $COOKIES{server_name},
#     CID      => $FORM{mac},
#     PHONE    => $FORM{PHONE},
#     ACTION   => 21,
#     COMMENTS => "New user initiate online payment op_id:'$FORM{OPERATION_ID}' tp_id:$FORM{TP_ID}",
#   });
#   if (!$FORM{UID} && $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_GUESTS_GID}) {
#     $user->{GID} = $Hotspot->{HOTSPOT_CONF}->{HOTSPOT_GUESTS_GID};
#   }
#   my $ret = paysys_payment({
#     OUTPUT2RETURN     => 1,
#     QUITE             => 1,
#     REGISTRATION_ONLY => 1,
#     UID               => $FORM{UID} || $FORM{OPERATION_ID},
#     RETURN_URL        => $COOKIES{link_login} || $SELF_URL,
#   });
#   print $html->header();
#   print $ret;
#   exit;
# }

1;