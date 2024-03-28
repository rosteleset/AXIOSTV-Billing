#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

=head1 NAME

  sms_callback.cgi

=head1 SYNOPSIS

  sms_callback.cgi is to receive incoming SMS from gateway

=cut

BEGIN {
  print "Content-Type: text/html\n\n";
  our $Bin;
  use FindBin '$Bin';
  if ($Bin =~ m/\/axbills(\/)/) {
    my $libpath = substr($Bin, 0, $-[1]);
    unshift (@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/axbills dir \n";
  }
}

use AXbills::Init qw/$db $admin %conf $users @MODULES $DATE $TIME/;
use AXbills::HTML;
use AXbills::Base qw/_bp startup_files cmd ssh_cmd int2byte in_array/;
use AXbills::Misc;
use AXbills::Defs;
use AXbills::Templates qw/_include/;
use Companies;
use Internet;
use Internet::Sessions;
use Log;

our %lang;

our $html = AXbills::HTML->new({
  IMG_PATH => 'img/',
  NO_PRINT => 1,
  CONF     => \%conf,
  CHARSET  => $conf{default_charset},
});

if ($conf{SMS_CALLBACK_LANGUAGE}) {
  $html->{language} = $conf{SMS_CALLBACK_LANGUAGE};
}

return 0 unless (in_array('Sms', \@MODULES));

load_module('Sms');

do "../language/english.pl";
do "../language/$html->{language}.pl";
do "../AXbills/modules/Sms/lng_$html->{language}.pl";

my $Log = Log->new($db, \%conf, {LOG_FILE => '/usr/axbills/var/log/sms_callback.log', SILENT => 1});
my $Ureports;

if (in_array('Ureports', \@MODULES)) {
  use Ureports;

  $Ureports = Ureports->new($db, $admin, \%conf);
}

my %STATUSES = (
  '0' => 'active',
  '3' => 'hold up',
);

our %FORM;
%FORM = form_parse();
$FORM{text} //= $FORM{content};
$FORM{sender} //= $FORM{from};

# Check required params
for my $param_name ('apikey', 'sender', 'text') {
  exit_with_error(400, "No $param_name given") if (!$FORM{$param_name});
}

# Do auth
$admin->info(undef, { API_KEY => $FORM{apikey} });
exit_with_error(401, "Invalid apikey") unless $admin->{AID};

my @sms_args = ();
if ($FORM{text} && $FORM{text} =~ /\+/) {
  @sms_args = split('\+', $FORM{text});
}
else {
  @sms_args = split(' ', $FORM{text});
}

#Hotspot
if ($sms_args[0] eq "ICNFREEHS" || $sms_args[0] eq "ICNHS") {
  my $cid = $sms_args[1];
  if ($cid !~ /^[0-9A-F]{12}$/) {
    show_command_result(0, '');
    exit;
  }
  $cid =~ s/(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})/$1:$2:$3:$4:$5:$6/;
  my ($uid, $phone) = get_user_info($cid);
  use Hotspot;
  my $Hotspot = Hotspot->new($db, $admin, \%conf);
  if ($sms_args[0] eq "ICNFREEHS" && $uid && !$phone) {
    set_user_phone($uid, $FORM{sender});
    sms_payment($uid, 1);

    $Hotspot->log_add({
      HOTSPOT  => '',
      CID      => $cid,
      ACTION   => 22,
      PHONE    => $FORM{sender},
      COMMENTS => "User $uid use $sms_args[0]"
    });
  }
  elsif ($sms_args[0] eq "ICNHS" && $uid) {
    sms_payment($uid, 2);

    $Hotspot->log_add({
      HOTSPOT  => '',
      CID      => $cid,
      ACTION   => 23,
      PHONE    => $FORM{sender},
      COMMENTS => "User $uid use $sms_args[0]"
    });
  }
  show_command_result(0, '');

  exit;
}

my $uid = $sms_args[0];
my $additional_info = $sms_args[2];

# Find user
my $user_object = check_user($FORM{sender}, $sms_args[0]);

if ($sms_args[1] eq '01') {
  send_user_memo_callback($user_object);
}
elsif ($sms_args[1] eq '02') {
  send_internet_info($user_object);
}
elsif ($sms_args[1] eq '03') {
  start_external_command($user_object);
}
elsif ($sms_args[1] eq '04') {
  hold_up_user($user_object)
}
elsif ($sms_args[1] eq '05') {
  activate_user($user_object);
}
elsif ($sms_args[1] eq '06') {
  money_transfer($user_object, $sms_args[2], $sms_args[3]);
  show_command_result(0, '');
}
elsif ($sms_args[1] eq '07') {
  active_sms_service($sms_args[3], { UID => $sms_args[0], TP_ID => $sms_args[2] });
}
elsif ($sms_args[1] eq '08') {
  _set_credit($sms_args[0], { CREDIT => $sms_args[2], PHONE => $FORM{sender} });
}

if ($conf{SMS_UNIVERSAL_URL}) {
  print "ACK/Jasmin\n";

  exit 0;
}

exit 0;

#**********************************************************
=head2 exit_with_error($code, $string)

=cut
#**********************************************************
sub exit_with_error {
  my ($code, $string) = @_;

  if ($conf{SMS_UNIVERSAL_URL}) {
    print "ACK/Jasmin\n";

    exit 0;
  }

  my %error_explanation = (
    400 => 'Bad request',
    401 => 'Unauthorized',
  );

  print "Status: $code " . ($error_explanation{$code} || '') . "\n";
  print "Content-Length: " . length($string) . "\n";
  print "Content-Type: text/html\n\n";
  print $string;

  $Log->log_print('LOG_ERR', '', $string);

  exit 0;
}

#**********************************************************
=head2 send_user_memo_callback($user)

  Arguments:
    $user - user Object

  Returns:

=cut
#**********************************************************
sub send_user_memo_callback {
  my ($user) = @_;
  my $code   = 0;

  my $Internet = Internet->new($db, $admin, \%conf);
  my $company_info = {};

  if ($user->{COMPANY_ID}) {
    my $Company = Companies->new($db, $admin, \%conf);

    $company_info = $Company->info($user->{company_id});
  }

  my $internet_info = $Internet->user_info($user->{uid});
  my $pi = $users->pi({ UID => $uid });

  $internet_info->{PASSWORD} = $user->{PASSWORD} if (!$internet_info->{PASSWORD});
  $internet_info->{LOGIN} = $user->{LOGIN} if (!$internet_info->{LOGIN});

  my $message = $html->tpl_show('', { %$user, %$internet_info, %$pi, %$company_info }, {
    TPL                 => 'internet_user_memo_sms',
    MODULE              => 'Internet',
    OUTPUT2RETURN       => 1,
    SKIP_DEBUG_MARKSERS => 1
  });

  load_module('Sms');

  my $sms_id = sms_send({
    NUMBER  => $user->{phone},
    MESSAGE => $message,
    UID     => $user->{uid},
  });

  if(!$sms_id) {
    $code = 2;
    $message = $lang{ERROR_SENDING}
  }

  show_command_result($code, $message);

  exit 0;
}


#**********************************************************
=head2 send_internet_info($user)

  Arguments:
    $user - user Object

  Returns:

=cut
#**********************************************************
sub send_internet_info {
  my ($user) = @_;

  my %INFO_HASH;
  my $code = 0;

  my $Internet = Internet->new($db, $admin, \%conf);
  my $internet_info = $Internet->user_info($user->{uid});
  my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

  $Sessions->prepaid_rest({
    UID  => ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} > 1) ? $Internet->{JOIN_SERVICE} : $user->{uid},
    UIDS => $user->{uid}
  });

  my $list = $Sessions->{INFO_LIST};
  my $rest = $Sessions->{REST};

  if ($rest) {
    my $traffic_rest = ($conf{INTERNET_INTERVAL_PREPAID}) ? $rest->{ $list->[0]{interval_id} }->{ $list->[0]{traffic_class} }  :  $rest->{ $list->[0]{traffic_class} };
    $INFO_HASH{REST_TRAFFIC} = int2byte($traffic_rest * 1024 * 1024);
  }

  if ($list) {
    $INFO_HASH{PREPAID} = int2byte($list->[0]{prepaid} * 1024 * 1024);
  }

  my $hash_statuses = sel_status({ HASH_RESULT => 1 });
  my $status_describe;

  $status_describe = $hash_statuses->{$internet_info->{STATUS}} if ($hash_statuses->{$internet_info->{STATUS}});
  my ($status, undef) = split('\:', $status_describe);

  $INFO_HASH{DEPOSIT}      = sprintf("%.3f", $user->{deposit});
  $INFO_HASH{TP_NAME}      = $internet_info->{TP_NAME};
  $INFO_HASH{STATUS_NAME}  = $status;

  require Control::Service_control;
  my $Service = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

  my $warning_info = $Service_control->service_warning({
    UID          => $user->{uid},
    ID           => $Internet->{ID},
    MODULE       => 'Internet',
    SERVICE_INFO => $Internet,
    USER_INFO    => $user
  });

  if (defined $warning_info->{WARNING}) {
    $INFO_HASH{NEXT_FEES_WARNING} = $warning_info->{WARNING};
    $INFO_HASH{NEXT_FEES_MESSAGE_TYPE} = $warning_info->{MESSAGE_TYPE};
  }

  my $message = $html->tpl_show('', { %$user, %$internet_info, %INFO_HASH}, {
    TPL                 => 'sms_callback_user_info',
    MODULE              => 'Sms',
    OUTPUT2RETURN       => 1,
    SKIP_DEBUG_MARKSERS => 1
  });

  load_module('Sms');

  my $sms_id = sms_send({
    NUMBER  => $user->{phone},
    MESSAGE => $message,
    UID     => $user->{uid},
  });

  if(!$sms_id) {
    $code = 3;
    $message = $lang{ERROR_SENDING}
  }

  show_command_result($code, $message);

  exit 0;
}


#**********************************************************
=head2 start_external_opertaion($user)

  Arguments:
    $user -

  Returns:

=cut
#**********************************************************
sub start_external_command {
  my ($user) = @_;

  my $code    = 0;
  my $message = $html->tpl_show('', { %$user, PASSWORD => $additional_info }, {
    TPL                 => 'sms_callback_change_wifi_password',
    MODULE              => 'Sms',
    OUTPUT2RETURN       => 1,
    SKIP_DEBUG_MARKERS  => 1
  });

  if (!$additional_info || length($additional_info) < 8) {
    $message = $lang{SHORT_PASSWORD};
    load_module('Sms');

    my $sms_id = sms_send({
      NUMBER  => $user->{phone},
      MESSAGE => $message,
      UID     => $user->{uid},
    });

    if (!$sms_id) {
      $code = 3;
      $message = $lang{ERROR_SENDING}
    }

    show_command_result(5, $message);
  }

  my $Sessions = Internet::Sessions->new($db, $admin, \%conf);
  my $online_info = $Sessions->online_info({
    UID => $user->{uid}
  });

  if ($Sessions->{errno}) {
    $code = 1;
    $message = $lang{ERROR_SENDING};

    show_command_result($code, $message);
  }

  my $user_ip = $online_info->{FRAMED_IP_ADDRESS};

  my $ping_result = host_diagnostic($user_ip);

  if ($ping_result == 1) {
    my $ssh_command = qq{/interface wireless security-profiles set [ find default=yes ] authentication-types=wpa-psk,wpa2-psk eap-methods="" mode=dynamic-keys wpa-pre-shared-key="$additional_info" wpa2-pre-shared-key="$additional_info"};
    ssh_cmd("$ssh_command", {
      NAS_MNG_IP_PORT => "$user_ip:22",
      NAS_MNG_USER    => "axbills_admin",
      SSH_KEY         => "",
    });

    $users->pi_change({
      UID         => $user->{uid},
      _CPE_SERIAL => $additional_info,
    });

    load_module('Sms');

    my $sms_id = sms_send({
      NUMBER  => $user->{phone},
      MESSAGE => $message,
      UID     => $user->{uid},
    });

    if (!$sms_id) {
      $code = 3;
      $message = $lang{ERROR_SENDING}
    }

    show_command_result($code, $message);

    exit 0;
  }

  return 1;
}
#**********************************************************
=head2 check_user($phone, $uid)

  Arguments:
    $phone - user Phone
    $uid   - user Identifier


  Returns:

=cut
#**********************************************************
sub check_user {
  my ($phone, $uid) = @_;

  my $user = {};

  require Contacts;

  my $Contacts = Contacts->new($db, $admin, \%conf);
  my $users_list = $Contacts->contacts_list({
    TYPE_ID   => '2,3',
    VALUE     => "*$FORM{sender}*",
    UID       => $uid,
    PAGE_ROWS => 1,
  });

  if ($Contacts->{errno} || ref $users_list ne 'ARRAY' || !$users_list->[0]) {
    show_command_result(1, "User not found");

    exit 0;
  }
  my $users_list_by_uid = $users->list({
    LOGIN          => '_SHOW',
    FIO            => '_SHOW',
    DEPOSIT        => '_SHOW',
    CREDIT         => '_SHOW',
    PHONE          => '_SHOW',
    ADDRESS_FULL   => '_SHOW',
    GID            => '_SHOW',
    DOMAIN_ID      => '_SHOW',
    DISABLE_PAYSYS => '_SHOW',
    GROUP_NAME     => '_SHOW',
    COMPANY_ID     => '_SHOW',
    DISABLE        => '_SHOW',
    CONTRACT_ID    => '_SHOW',
    ACTIVATE       => '_SHOW',
    REDUCTION      => '_SHOW',
    PASSWORD       => '_SHOW',
    UID            => $uid,
    COLS_NAME      => 1,
    COLS_UPPER     => 1,
    PAGE_ROWS      => 1,
  });

  $user = $users_list_by_uid->[0];

  return $user;
}

#**********************************************************
=head2 hold_up_user($user)

  Arguments:
    $user -

  Returns:

=cut
#**********************************************************
sub hold_up_user {
  my ($user) = @_;

  my $code    = 0;
  my $message = $html->tpl_show('', { %$user, STATUS => $STATUSES{'3'} }, {
    TPL                 => 'internet_user_status_sms',
    MODULE              => 'Internet',
    OUTPUT2RETURN       => 1,
    SKIP_DEBUG_MARKERS  => 1
  });

  load_module('Sms');

  my $Internet = Internet->new($db, $admin, \%conf);

  my $user_services = $Internet->user_list({
    UID             => $user->{uid},
    INTERNET_STATUS => '0',
    COLS_NAME       => 1
  });

  if ($Internet->{TOTAL} == 0) {
    show_command_result(6, "$lang{ALL_SERVICE_NOT_ACTIVE} $user->{uid}");

    exit 0;
  }

  foreach my $service (@$user_services) {
    $Internet->user_change({ UID => $user->{uid}, ID => $service->{id}, STATUS => 3 });
  }

  if ($Internet->{errno}) {
    my $sms_id = sms_send({
      NUMBER  => $user->{phone},
      MESSAGE => $lang{SERVICE_NOT_HOLDING_UP},
      UID     => $user->{uid},
    });

    show_command_result(4, $lang{SERVICE_NOT_HOLDING_UP});

    exit 0;
  }

  my $sms_id = sms_send({
    NUMBER  => $user->{phone},
    MESSAGE => $message,
    UID     => $user->{uid},
  });

  if (!$sms_id) {
    $code = 5;
    $message = "$lang{SERVICE_NOT_HOLDING_UP}\n$lang{ERROR_SENDING}"
  }

  show_command_result($code, $message);

  exit 0;
}


#**********************************************************
=head2 activate_user($user)

  Arguments:
    $user -

  Returns:

=cut
#**********************************************************
sub activate_user {
  my ($user) = @_;

  my $code    = 0;
  my $message = $html->tpl_show('', { %$user, STATUS => $STATUSES{'0'} }, {
    TPL                 => 'internet_user_status_sms',
    MODULE              => 'Internet',
    OUTPUT2RETURN       => 1,
    SKIP_DEBUG_MARKERS  => 1
  });

  load_module('Sms');

  my $Internet = Internet->new($db, $admin, \%conf);

  my $user_services = $Internet->user_list({UID => $user->{uid}, INTERNET_STATUS => 3, COLS_NAME => 1});

  if ($Internet->{TOTAL} == 0) {
    show_command_result(7, "$lang{ALL_SERVICE_NOT_ACTIVE} $user->{uid}");

    exit 0;
  }

  foreach my $service (@$user_services) {
    $Internet->user_change({ UID => $user->{uid}, ID => $service->{id}, STATUS => 0 });
  }

  if ($Internet->{errno}) {
    my $sms_id = sms_send({
      NUMBER  => $user->{phone},
      MESSAGE => $lang{SERVICE_NOT_ACTIVE},
      UID     => $user->{uid},
    });

    show_command_result(4, $lang{SERVICE_NOT_ACTIVE});
    exit 0;
  }

  my $sms_id = sms_send({
    NUMBER  => $user->{phone},
    MESSAGE => $message,
    UID     => $user->{uid},
  });

  if (!$sms_id) {
    $code    = 5;
    $message = $lang{ERROR_SENDING}
  }

  show_command_result($code, $message);

  exit 0;
}

#**********************************************************
=head2 get_user_info ($mac)

=cut
#**********************************************************
sub get_user_info {
  my ($cid) = @_;

  my $Internet = Internet->new($db, $admin, \%conf);
  my $list = $Internet->user_list({
    PHONE          => '_SHOW',
    CID            => $cid,
    COLS_NAME      => 1,
  });

  return (0, 0) if ($Internet->{TOTAL} < 1);

  return ($list->[0]{uid}, $list->[0]{phone});
}

#**********************************************************
=head2 set_user_phone ($uid, $phone)

=cut
#**********************************************************
sub set_user_phone {
  my ($uid, $phone) = @_;

  require Contacts;

  my $Contacts = Contacts->new($db, $admin, \%conf);
  $Contacts->contacts_add({
    TYPE_ID => 2,
    VALUE   => $phone,
    UID     => $uid,
  });

  return 1;
}

#**********************************************************
=head2 sms_payment ($uid, $sum)

=cut
#**********************************************************
sub sms_payment {
  my ($uid, $sum) = @_;

  use Finance;

  my $Payments = Finance->payments($db, $admin, \%conf);
  my $user = Users->new($db, $admin, \%conf);
  $user->info($uid);

  $Payments->add($user, {
    SUM      => $sum,
    METHOD   => 11,
    DESCRIBE => $lang{PUBLIC_HOTSPOT_SMS},
  });

  load_module('Sms');

  my $message = $html->tpl_show('', {
    UID        => $uid,
    SUM        => $sum,
    PAYMENT_ID => $Payments->{PAYMENT_ID}
  }, {
    TPL                 => 'sms_callback_sms_pay_complete',
    MODULE              => 'Sms',
    OUTPUT2RETURN       => 1,
    SKIP_DEBUG_MARKERS  => 1
  });

  sms_send({
    NUMBER  => $FORM{sender},
    MESSAGE => $message,
    UID     => $uid,
  });

  return 1;
}

#**********************************************************
=head2 money_transfer($user, $target_uid, $sum)

=cut
#**********************************************************
sub money_transfer {
  my ($user, $target_uid, $sum) = @_;

  my $error = 0;
  my $percentage = 0;

  my $user1 = Users->new($db, $admin, \%conf);
  my $user2 = Users->new($db, $admin, \%conf);

  $user1->info($user->{uid});
  $user2->info($target_uid);

  $error = 2 if ($user2->{errno});

  require Dillers;
  my $Diller = Dillers->new($db, $admin, \%conf);

  $Diller->diller_info({ UID => $target_uid });
  $error = 2 if ($Diller->{TOTAL} > 0);

  $Diller->diller_info({ UID => $user->{uid} });
  $error = 3 if ($Diller->{TOTAL} < 1 && $user1->{GID} != $user2->{GID});

  if ($error) {
    my $message = $html->tpl_show('', { UID => $target_uid }, {
      TPL                => 'sms_callback_user_not_exist',
      MODULE             => 'Sms',
      OUTPUT2RETURN      => 1,
      SKIP_DEBUG_MARKERS => 1
    });

    sms_send({
      NUMBER  => $user->{phone},
      MESSAGE => $message,
      UID     => $user->{uid},
    });

    return 1;
  }

  use Finance;

  my $Fees     = Finance->fees($db, $admin, \%conf);
  my $Payments = Finance->payments($db, $admin, \%conf);

  my $last_payments = $Payments->list({
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    DESCRIBE  => '_SHOW',
    UID       => $user->{uid},
    DESC      => 'desc',
    SORT      => 1,
    PAGE_ROWS => 1,
    COLS_NAME => 1
  });

  my $last_sum = $last_payments->[0]->{sum} || 0;

  if ($Diller->{TOTAL} < 1) {
    $percentage = 0;
  }
  elsif ($user1->{GID} && $user1->{GID} == $user2->{GID}) {
    $percentage = $Diller->{DILLER_PERCENTAGE} || 10;
  }
  elsif ($last_sum > 6000) {
    $percentage = 6;
  }
  elsif ($last_sum > 4000) {
    $percentage = 5;
  }
  elsif ($last_sum > 2000) {
    $percentage = 4;
  }
  elsif ($last_sum > 1000) {
    $percentage = 3;
  }
  else {
    $percentage = 0;
  }

  my $dillers_fee = $sum * (100 - $percentage) / 100;

  if ($user->{deposit} < $dillers_fee) {
    my $message = $html->tpl_show('', { DEPOSIT => $user->{deposit} }, {
      TPL                 => 'sms_callback_not_enough_money',
      MODULE              => 'Sms',
      OUTPUT2RETURN       => 1,
      SKIP_DEBUG_MARKERS  => 1
    });

    sms_send({
      NUMBER  => $user->{phone},
      MESSAGE => $message,
      UID     => $user->{uid},
    });

    return 1;
  }

  $Fees->take($user1, $dillers_fee, {
    DESCRIBE => "$lang{MONEY_TRANSFER} '$sum' -> '$user2->{LOGIN}'",
    METHOD   => 10,
  });

  $Payments->add($user2, {
    SUM      => $sum,
    METHOD    => 10,
    DESCRIBE => "$lang{USER} '$user1->{LOGIN}' $lang{ADD_SUM_TRANSFER}:'$sum' -> '$user2->{LOGIN}' $DATE $TIME",
  });

  if (!$Payments->{errno}) {
    cross_modules('payments_maked', {
      USER_INFO   => $user2,
      SUM         => $sum,
      SILENT      => 1,
      QUITE       => 1,
      timeout     => 4,
    });
  }

  my $deposit = sprintf("%.3f", ($user1->{DEPOSIT} - $dillers_fee));

  my $message = $html->tpl_show('', {
    %$user1,
    SUM        => $sum,
    TARGET_UID => $target_uid,
    DEPOSIT    => $deposit
  }, {
    TPL                => 'sms_callback_money_transfer',
    MODULE             => 'Sms',
    OUTPUT2RETURN      => 1,
    SKIP_DEBUG_MARKERS => 1
  });

  sms_send({
    NUMBER  => $user->{phone},
    MESSAGE => $message,
    UID     => $user->{uid},
  });

  return 1;
}

#**********************************************************
=head2 show_command_result($message)

  Arguments:
    $message - what will show on screen

  Returns:

=cut
#**********************************************************
sub show_command_result {
  my ($code, $message) = @_;

  if ($conf{SMS_UNIVERSAL_URL}) {
    print "ACK/Jasmin\n";

    exit 1;
  }

  print "$message<br>";

  $Log->log_print('LOG_INFO', '', $message) if($code == 0);

  $Log->log_print('LOG_ERR', '', $message);

  return 1;
}

#**********************************************************
=head2 active_sms_service($action, $attr)

  Arguments:
    $action - enabled/disabled sms service
    $attr:
      UID   - ID user enabled/disabled service
      TP_ID - Tarif plan id enabled/disabled

  Returns:
    1

=cut
#**********************************************************
sub active_sms_service {
  my ($action, $attr) = @_;

  return 0 unless ($attr->{UID});

  my $uid   = $attr->{UID};
  my $tp_id = $attr->{TP_ID};

  my $list = $Ureports->user_list({
    UID           => $uid,
    TP_ID         => $tp_id,
    REPORTS_COUNT => '_SHOW',
    COLS_NAME     => 1,
    COLS_UPPER    => 1
  });

  _check_service_date($uid, { TP_ID => $tp_id, ACTION => $action, SMS_TPS => $list });

  return 1;
}

#**********************************************************
=head2 _check_service_date($uid, $attr)

  Arguments:
    $uid    - User id check service
    $attr:
      SMS_TPS - user sms service list
      ACTION  - action enabled/disabled service in user
      TP_ID   - tarif plan id which enabled

  Returns:
    -

=cut
#**********************************************************
sub _check_service_date {
  my ($uid, $attr) = @_;

  my $sms_tps = $attr->{SMS_TPS};
  my $action  = $attr->{ACTION};
  my $tp_id   = $attr->{TP_ID};

  if ($action eq 'enabled') {
    $Ureports->user_add({ UID => $uid, TP_ID => $tp_id, STATUS => 1 });
    return 1;
  }

  foreach my $sms_tp (@{ $sms_tps }) {
    if ($action eq 'disabled') {
      $Ureports->{UID} = $uid;
      $Ureports->user_del({ %$sms_tp });
    }
  }
}

#**********************************************************
=head2 _set_credit($uid, $attr)

  Arguments:
    $uid    - User id check service
    $attr:
      CREDIT        - User set value credit
      CREDIT_DATE   - Set credit date

  Returns:
    -

=cut
#**********************************************************
sub _set_credit {
  my ($uid, $attr) = @_;

  my $user_deposit = _get_user_bills($uid);

  _credit_allow($user_deposit, { PHONE => $attr->{PHONE}, UID => $uid });

  my $credit_date = _get_credit_date();

  my $credit = $attr->{CREDIT} + 1;

  $users->change($uid, {
    UID         => $uid,
    CREDIT      => $credit,
    CREDIT_DATE => $credit_date
  });

  unless (_error_show($users)) {

    my $user = Users->new($db, $admin, \%conf);
    $user->info($uid);


    cross_modules('payments_maked', {
      USER_INFO   => $user,
      SUM         => $attr->{CREDIT} + 2,
      SILENT      => 1,
      QUITE       => 1,
      timeout     => 4,
      SKIP_MODULES  => 'Ureports,Sqlcmd'
    });


    my $message = $html->tpl_show(_include('sms_set_credit', 'Sms'), {
      CREDIT      => $credit,
      EXPIRE_DATE => $credit_date
    });

    sms_send({
      NUMBER  => $attr->{PHONE},
      MESSAGE => $message,
      UID     => $uid,
    });

    return 1;
  }
}

#**********************************************************
=head2 _get_user_bills()

  Arguments:
    $uid    - User id

  Returns:
    User deposit

=cut
#**********************************************************
sub _get_user_bills {
  my ($uid) = @_;

  require Bills;
  Bills->import();
  my $Bills = Bills->new($db, $admin, \%conf);

  my $user_deposit = $Bills->list({
    UID           => $uid,
    COMPANY_ONLY  => 1,
    COLS_NAME     => 1
  });

  return $user_deposit->[0]->{deposit} || 0;
}

#**********************************************************
=head2 _credit_allow()

  Arguments:
    $deposit  - User deposit

  Returns:
    -

=cut
#**********************************************************
sub _credit_allow {
  my ($deposit, $attr) = @_;

  if ($deposit <= -5) {
    print "ACK/Jasmin\n" if ($conf{SMS_UNIVERSAL_URL});

    exit 0;
  }

  _check_credit($attr->{UID}, $attr->{PHONE});
}

#**********************************************************
=head2 _check_credit()

  Arguments:
    $uid    - User id
    $phone  - User phone

  Returns:
    -

=cut
#**********************************************************
sub _check_credit {
  my ($uid, $phone) = @_;

  my $credit = $users->info($uid);

  if ($credit->{CREDIT} > 0) {
    my $message = $html->tpl_show(_include('sms_set_credit_failed', 'Sms'), { });

    sms_send({
      NUMBER  => $phone,
      MESSAGE => $message,
      UID     => $uid,
    });

    print "ACK/Jasmin\n" if ($conf{SMS_UNIVERSAL_URL});
    exit 0;
  }
}

#**********************************************************
=head2 _get_credit_date()

  Arguments:
    -

  Returns:
    -

=cut
#**********************************************************
sub _get_credit_date {
  my (undef, $year, $month, $day) = split(/(\d{4})-(\d{1,2})-(\d{1,2})/, $DATE);

  $day += 3;

  my $credit_date = "$year-$month-$day";
  my $count_day_in_month = _get_month_count_day($year, $month);

  if ($day > $count_day_in_month) {
    if ($month == 12) {
      $year += 1;
      $month = '01';
    }
    else {
      $month += 1;
    }

    $day -= $count_day_in_month;

    $day = "0$day" if ($day < 10);

    $credit_date = "$year-$month-$day";
  }

  return $credit_date;
}

#**********************************************************
=head2 _get_month_count_day($uid, $attr)

  Arguments:
    $count_month - Month number

  Returns:
    Count days in month

=cut
#**********************************************************
sub _get_month_count_day {
  my ($year, $month) = @_;

  return 30 + ($month + ($month > 7)) % 2 - ($month == 2)
    * (2 - ($year % 4 == 0 && ($year % 100 != 0 || $year % 400 == 0)));
}

1;
