#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Time::Piece;
use Time::Seconds;

BEGIN {
  our $Bin;
  use FindBin '$Bin';
  if ($Bin =~ m/\/axbills(\/)/) {
    our $libpath = substr($Bin, 0, $-[1]);
    unshift(@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/axbills dir \n";
  }
}

our (
  %lang,
);

use AXbills::Init qw/$db $admin %conf/;
use AXbills::Defs;
use AXbills::HTML;
use AXbills::Base qw(_bp json_former check_ip);
use POSIX qw(strftime);
use Log qw(log_add log_print);
use Iptv;
use Shedule;
use AXbills::Sender::Core;
require AXbills::Misc;
require Iptv::User_portal;
require Iptv::Base;
use JSON qw/decode_json encode_json/;

our $DATE = strftime("%Y-%m-%d", localtime(time));
our $TIME = strftime("%H:%M:%S", localtime(time));

our $html = AXbills::HTML->new({
  CONF     => \%conf,
  NO_PRINT => 0,
  PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
  CHARSET  => $conf{default_charset},
  LANG     => \%lang,
});

if ($html->{language} ne 'english') {
  do $libpath . "/language/english.pl";
}

if (-f $libpath . "/language/$html->{language}.pl") {
  do $libpath . "/language/$html->{language}.pl";
}

my $Iptv = Iptv->new($db, $admin, \%conf);
my $Log = Log->new($db, \%conf);
my $Tariff = Tariffs->new($db, $admin, \%conf);
my $Shedule = Shedule->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);
my $Iptv_base = Iptv::Base->new($db, $admin, \%conf, { LANG => \%lang });

iptv_check_service();
exit;

if ($FORM{type}) {
  print "Content-type:text/html\n\n";
  if ($FORM{type} eq 'user') {
    check_user(\%FORM);
  }
  elsif ($FORM{type} eq 'tp') {
    show_user_tp(\%FORM);
  }
  exit;
}

#SmartUp Start

if ($FORM{action} && $FORM{duid} && $FORM{ip}) {
  print "Content-type:text/html\n\n";
  if (($FORM{action} eq "login") || ($FORM{action} eq "confirm") && $FORM{phone}) {
    smartup_activation();
  }
  elsif ($FORM{action} eq "verify") {
    smartup_activation();
  }
  elsif ($FORM{action} eq "info") {
    smartup_activation();
  }
  elsif ($FORM{action} eq "pin") {
    if ($FORM{set}) {
      smartup_pin({ ACTION => "set" });
    }
    else {
      smartup_pin({ ACTION => "pin" });
    }
  }
  exit;
}

#SmartUp End

if ($conf{IPTV_PASSWORDLESS_ACCESS} && $ENV{REMOTE_ADDR}) {

  my $iptv_online = $Iptv->online(
    {
      FRAMED_IP_ADDRESS => $ENV{REMOTE_ADDR},
      TP_ID             => '_SHOW',
      COLS_NAME         => 1,
      PAGE_ROWS         => 1,
    }
  );
  _error_show($Iptv);

  if (!$iptv_online || ref $iptv_online ne 'ARRAY' && !scalar(@$iptv_online) || !$iptv_online->[0]->{tp_id}) {
    print "Content-type:text/html\n\n";
    print $html->element('h3', 'WARNING') . $html->element('p', 'This address ' . $ENV{REMOTE_ADDR} . ' is not connected to the TP');
    $Log->log_print('LOG_WARNING', '', 'Address ' . $ENV{REMOTE_ADDR} . ' not connected to the TP', { ACTION => 'AUTH' });
    exit;
  }
  else {
    $FORM{m3u_download} = 1;
    iptv_m3u($iptv_online->[0]->{tp_id});
  }
  exit;
}

#Folclor
if ($FORM{ip} || $FORM{phone} || $FORM{mbr_id}) {
  print "Content-type:text/html\n\n";
  check_user(\%FORM);
  exit;
}

if ($FORM{user_id} || $FORM{sum} || $FORM{cont_id} || $FORM{trf_id} || $FORM{message} || $FORM{start}) {
  print "Content-type:text/html\n\n";
  transfer_service(\%FORM);
  exit;
}

if (!$FORM{mac} && !$FORM{pin}) {
  print "Content-type:text/html\n\n";
  print $html->element('h3', 'WARNING') . $html->element('p', 'No mac or pin specified. No user found');
  exit;
}

mac_pin_auth();


#**********************************************************
=head2 mac_pin_auth($attr) - Mac PIN Auth

  Arguments:

  Returns:

  Example:
    check_user(/%FORM);

=cut
#**********************************************************
sub mac_pin_auth {

  if ($FORM{mac}) {
    $FORM{mac} =~ s/_SHOW//;
    $FORM{mac} =~ s/\*//;
  }

  if ($FORM{pin}) {
    $FORM{pin} =~ s/_SHOW//;
    $FORM{pin} =~ s/\*//;
  }

  my $iptv_list = $Iptv->user_list(
    {
      CID            => $FORM{mac},
      PIN            => $FORM{pin},
      SERVICE_STATUS => '_SHOW',
      LOGIN          => '_SHOW',
      TP_ID          => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      COLS_NAME      => 1,
      PAGE_ROWS      => 1,
    }
  );
  _error_show($Iptv);

  if (!$iptv_list || ref $iptv_list ne 'ARRAY' && !scalar(@$iptv_list)) {
    print "Content-type:text/html\n\n";
    if ($FORM{mac}) {
      print $html->element('h3', 'WARNING') . $html->element('p', 'Wrong CID:' . $FORM{mac} . '. No user found');
      $Log->log_print('LOG_WARNING', '', "Wrong CID: $FORM{mac}. No user found", { ACTION => 'AUTH' });
    }
    elsif ($FORM{pin}) {
      print $html->element('h3', 'WARNING') . $html->element('p', 'Wrong PIN:' . $FORM{pin} . '. No user found');
      $Log->log_print('LOG_WARNING', '', "Wrong PIN: $FORM{pin}. No user found", { ACTION => 'AUTH' });
    }
    exit 0;
  }

  my $service = $iptv_list->[0];
  if (!$service->{login} || !$service->{tp_id}) {
    print "Content-type:text/html\n\n";
    print $html->element('h3', 'WARNING') . $html->element('p',
      'TP_ID:' . $service->{tp_id} . '. No activated service');
    $Log->log_print('LOG_WARNING', $service->{login},
      "TP_ID: $service->{tp_id}. No activated service", { ACTION => 'AUTH' });
  }

  # service_status 1 means it is disabled
  if ($service->{service_status}) {
    $Log->log_print('LOG_WARNING', $service->{login},
      "SERVICE_STATUS: $service->{service_status}. No activated service. ", { ACTION => 'AUTH' });
  }
  if (($service->{deposit} + $service->{credit}) <= 0) {
    $Log->log_print('LOG_WARNING', $service->{login},
      "DEPOSIT: $service->{deposit}. Too small deposit. ", { ACTION => 'AUTH' });
  }
  else {
    $FORM{m3u_download} = 1;
    iptv_m3u($service->{tp_id});
  }

  return 1;
}

#**********************************************************
=head2 check_user($attr) - search uid by ip or uid

  Arguments:
    $attr{ip}  - user ip
    $attr{uid} - user ip

  Returns:
   UID

  Example:

    check_user(/%FORM);

=cut
#**********************************************************
sub check_user {
  my ($params) = @_;

  my %result = ();

  if ($params->{uid} || $params->{mbr_id}) {
    my $iptv_list = $Iptv->user_list(
      {
        UID            => $params->{uid} || '_SHOW',
        LOGIN          => '_SHOW',
        SERVICE_STATUS => '_SHOW',
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        TP_ID          => '_SHOW',
        SUBSCRIBE_ID   => $params->{mbr_id} || '_SHOW',
        COLS_NAME      => 1,
        PAGE_ROWS      => 1,
      }
    );
    _error_show($Iptv);

    if (!$iptv_list || ref $iptv_list ne 'ARRAY' && !scalar(@$iptv_list) || !$iptv_list->[0]->{uid}) {
      $result{status} = '-1';
      $result{err} = '-1';
      $result{errmsg} = "User is not found";
      #      $Log->log_print('LOG_WARNING', '', 'No user found', { ACTION => 'AUTH' });
      print json_former(\%result);
      exit;
    }

    my $service = $iptv_list->[0];
    # service_status 1 means it is disabled
    if ($service->{service_status}) {
      $result{ERROR} .= "SERVICE_STATUS: $service->{service_status}. No activated service. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "SERVICE_STATUS: $service->{service_status}. No activated service. ", { ACTION => 'AUTH' });
    }
    if (($service->{deposit} + $service->{credit}) <= 0) {
      $result{ERROR} .= "DEPOSIT: $service->{deposit}. Too small deposit. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "DEPOSIT: $service->{deposit}. Too small deposit. ", { ACTION => 'AUTH' });
    }

    $result{user_id} = $service->{uid};
  }
  elsif ($params->{ip}) {

    my $iptv_online = $Iptv->online(
      {
        FRAMED_IP_ADDRESS => $params->{ip},
        UID               => '_SHOW',
        COLS_NAME         => 1,
        PAGE_ROWS         => 1,
      }
    );

    if (!$iptv_online || ref $iptv_online ne 'ARRAY' && !scalar(@$iptv_online) || !$iptv_online->[0]->{uid}) {
      $result{ERROR} .= 'Address ' . $params->{ip} . ' is not connected to any uid';
      $Log->log_print('LOG_WARNING', '', 'Address ' . $params->{ip} . ' not connected to any uid', { ACTION => 'AUTH' });
    }
    else {
      $result{UID} = $iptv_online->[0]->{uid};
    }
  }

  print json_former(\%result);
}

#**********************************************************
=head2 show_user_tp($attr) - search tp by ip or uid

  Arguments:
    $attr{ip}  - user ip
    $attr{uid} - user ip

  Returns:
   UID

  Example:

    show_user_tp(/%FORM);

=cut
#**********************************************************
sub show_user_tp {
  my ($params) = @_;

  my %result = ();

  if ($params->{uid} || $params->{user_id}) {
    my $iptv_list = $Iptv->user_list(
      {
        UID            => $params->{user_id} || $params->{uid},
        LOGIN          => '_SHOW',
        SERVICE_STATUS => '_SHOW',
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        TP_ID          => '_SHOW',
        COLS_NAME      => 1,
        PAGE_ROWS      => 1,
      }
    );
    _error_show($Iptv);

    if (!$iptv_list || ref $iptv_list ne 'ARRAY' && !scalar(@$iptv_list) || !$iptv_list->[0]->{tp_id}) {
      $result{ERROR} .= 'Wrong UID. No user found. ';
      $Log->log_print('LOG_WARNING', '', 'No user found', { ACTION => 'AUTH' });
      print json_former(\%result);
      exit;
    }

    my $service = $iptv_list->[0];
    # service_status 1 means it is disabled
    if ($service->{service_status}) {
      $result{ERROR} .= "SERVICE_STATUS: $service->{service_status}. No activated service. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "SERVICE_STATUS: $service->{service_status}. No activated service. ", { ACTION => 'AUTH' });
    }
    if (($service->{deposit} + $service->{credit}) <= 0) {
      print "OKK";
      $result{ERROR} .= "DEPOSIT: $service->{deposit}. Too small deposit. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "DEPOSIT: $service->{deposit}. Too small deposit. ", { ACTION => 'AUTH' });
    }
    else {
      print "12222";
    }
  }
  #  elsif($params->{ip}){
  #
  #    my $iptv_online = $Iptv->online(
  #      {
  #        FRAMED_IP_ADDRESS => $params->{ip},
  #        UID               => '_SHOW',
  #        COLS_NAME         => 1,
  #        PAGE_ROWS         => 1,
  #      }
  #    );
  #
  #    if(!$iptv_online || ref $iptv_online ne 'ARRAY' && !scalar(@$iptv_online) || !$iptv_online->[0]->{tp_id}){
  #      $result{ERROR} .= 'Address ' . $params->{ip} . ' is not connected to any tp';
  #      $Log->log_print('LOG_WARNING', '', 'Address ' . $params->{ip} . ' is not connected to any tp', { ACTION => 'AUTH' });
  #    }
  #    else{
  #      $result{TP_ID} = $iptv_online->[0]->{tp_id};
  #    }
  #  }

  print json_former(\%result);
}

#**********************************************************
=head2 transfer_service($attr)

  Arguments:
    $attr{user_id}  - user ip
    $attr{sum} - user ip
    $attr{cont_id}
    $attr{trf_id}
    $attr{message}
    $attr{start}

  Returns:
   UID

  Example:

    transfer_service(/%FORM);

=cut
#**********************************************************
sub transfer_service {
  my ($params) = @_;

  my %result = ();
  my $tarrifs = ();

  if ($params->{user_id}) {
    my $iptv_list = $Iptv->user_info($params->{user_id});
    _error_show($Iptv);

    if (!$iptv_list) {
      $result{status} = '-1';
      print json_former(\%result);
      exit;
    }

    my $iptv_user = $Iptv->user_list(
      {
        ID             => $iptv_list->{ID},
        LOGIN          => '_SHOW',
        SERVICE_STATUS => '_SHOW',
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        TP_ID          => '_SHOW',
        COLS_NAME      => 1,
        PAGE_ROWS      => 1,
      }
    );
    my $service = $iptv_user->[0];

    if (($service->{deposit} + $service->{credit}) <= 0) {
      $result{status} = '-2';
      print json_former(\%result);
      exit;
    }
    else {
      require Tariffs;
      Tariffs->import();
      my $Tariff = Tariffs->new($db, \%conf, $admin);

      $tarrifs = $Tariff->list({
        NAME        => "_SHOW",
        ACTIV_PRICE => "_SHOW",
        MODULE      => 'Iptv',
        SERVICE_ID  => $iptv_list->{SERVICE_ID},
        FILTER_ID   => $params->{trf_id},
        COLS_NAME   => 1
      });

      $Iptv->{TP_INFO}->{PERIOD_ALIGNMENT} = $Iptv->{PERIOD_ALIGNMENT} || 0;
      $Iptv->{TP_INFO}->{MONTH_FEE} = $Iptv->{MONTH_FEE};
      $Iptv->{TP_INFO}->{DAY_FEE} = $Iptv->{DAY_FEE};
      $Iptv->{TP_INFO}->{TP_ID} = $Iptv->{TP_ID};
      $Iptv->{TP_INFO}->{ABON_DISTRIBUTION} = $Iptv->{ABON_DISTRIBUTION};
      $Iptv->{TP_INFO}->{ACTIV_PRICE} = $tarrifs->[0]{activate_price};

      service_get_month_fee($Iptv, {
        SERVICE_NAME => $iptv_list->{SERVICE_MODULE},
        QUITE        => 1,
      });
    }
  }

  $result{id} = $Iptv->{FEES_ID}[0] || 0;
  $result{status} = '1';
  print json_former(\%result);

  return 1;
}

#**********************************************************
=head2 smartup_activation($attr)

  Arguments:

  Returns:


=cut
#**********************************************************
sub smartup_activation {

  my %result;
  my $code = 10000000 + int rand(89999999);
  my $exist_device = 0;
  my $Users = Users->new($db, $admin, \%conf);
  my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);

  my $device = $Iptv->device_list({
    UID         => '_SHOW',
    SERVICE_ID  => '_SHOW',
    DEV_ID      => $FORM{duid},
    ENABLE      => '_SHOW',
    IP_ACTIVITY => '_SHOW',
    CODE        => '_SHOW',
  });

  if (!$Iptv->{TOTAL}) {
    $result{uid} = '';
    $result{status} = '';
    $result{tid} = '';
    my $service_list = $Iptv->services_list({
      MODULE    => "SmartUp",
      COLS_NAME => 1,
    });
    if ($Iptv->{TOTAL}) {
      $Iptv->device_add({
        DEV_ID        => $FORM{duid},
        UID           => 0,
        ENABLE        => 1,
        DATE_ACTIVITY => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime()),
        IP_ACTIVITY   => '',
        SERVICE_ID    => $service_list->[0]{id},
        CODE          => $code,
      });

      $exist_device = 1;
    }
  }

  my $params = $Iptv->extra_params_list({
    SERVICE_ID => $device->[0]{SERVICE_ID},
    GROUP_ID   => '_SHOW',
    TP_ID      => '_SHOW',
    SMS_TEXT   => '_SHOW',
    SEND_SMS   => '_SHOW',
    IP_MAC     => '_SHOW',
    BALANCE    => '_SHOW',
    MAX_DEVICE => '_SHOW',
    PIN        => '_SHOW',
  });

  my $default_params = $Iptv->extra_params_list({
    SERVICE_ID => $device->[0]{SERVICE_ID},
    GROUP_ID   => '_SHOW',
    TP_ID      => '_SHOW',
    SMS_TEXT   => '_SHOW',
    SEND_SMS   => '_SHOW',
    IP_MAC     => "0.0.0.0/0",
    BALANCE    => '_SHOW',
    MAX_DEVICE => '_SHOW',
    PIN        => '_SHOW',
  });
  my $default_count = @$default_params;

  $device = $Iptv->device_list({
    UID         => '_SHOW',
    SERVICE_ID  => '_SHOW',
    DEV_ID      => $FORM{duid},
    ENABLE      => '_SHOW',
    IP_ACTIVITY => '_SHOW',
    CODE        => '_SHOW',
  });

  if ($Iptv->{TOTAL} == 1) {
    if ($FORM{action} eq "login" || $FORM{action} eq "confirm") {
      $result{uid} = '';
      $result{status} = '';
      $result{tid} = '';
      if ($FORM{action} eq "confirm") {
        if ($device->[0]{UID} && $device->[0]{CODE} && $device->[0]{CODE} eq $FORM{code}) {
          $device->[0]{ENABLE} = 0;
          $Iptv->device_change({
            ID            => $device->[0]{id},
            ENABLE        => 0,
            DATE_ACTIVITY => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime()),
          });

          my $main_params = 0;
          foreach my $element (@$params) {
            if (check_ip($FORM{ip}, $element->{IP_MAC}) && $element->{IP_MAC} ne "0.0.0.0/0") {
              $Sender->send_message({
                TO_ADDRESS  => $FORM{phone},
                MESSAGE     => $element->{SMS_TEXT},
                SENDER_TYPE => 'Sms',
                UID         => $device->[0]{UID}
              });
              $main_params = 1;
              last;
            }
          }
          if ($default_count && !$main_params) {
            $Sender->send_message({
              TO_ADDRESS  => $FORM{phone},
              MESSAGE     => $default_params->[0]{SMS_TEXT},
              SENDER_TYPE => 'Sms',
              UID         => $device->[0]{UID}
            });
          }
        }
      }
      my $user = $Iptv->user_list({
        TP_FILTER  => '_SHOW',
        UID        => $device->[0]{UID},
        SERVICE_ID => $device->[0]{SERVICE_ID},
        COLS_NAME  => 1,
      });

      $result{status} = ($device->[0]{ENABLE} == 1) ? "unverified" : "active";

      if ($Iptv->{TOTAL} > 0) {
        $result{uid} = $device->[0]{UID};
        $result{tid} = $user->[0]{filter_id};
        print json_former(\%result);
        exit;
      }
      else {
        my $res = _ip_user_search($device->[0]{SERVICE_ID}, $device->[0]{ID}, $device->[0]{CODE}, $exist_device);
        if ($res && $res->{uid}) {
          my %final_result;
          $final_result{status} = $result{status};
          $final_result{tid} = $res->{tid};
          $final_result{uid} = $res->{uid};
          print json_former(\%final_result);
          exit;
        }

        my $user_info = $Users->list({
          LOGIN     => "tv" . substr($FORM{phone}, 2, 10),
          FIO       => '_SHOW',
          PHONE     => '_SHOW',
          COLS_NAME => 1,
          PAGE_ROWS => 1,
        });

        if ($Users->{TOTAL}) {
          foreach my $element (@$params) {
            if (check_ip($FORM{ip}, $element->{IP_MAC})) {
              $user = $Iptv->user_list({
                TP_FILTER  => '_SHOW',
                UID        => $user_info->[0]{uid} || $user_info->[0]{UID},
                SERVICE_ID => $element->{SERVICE_ID},
                COLS_NAME  => 1,
              });

              $Iptv->device_list({
                UID         => $user_info->[0]{uid} || $user_info->[0]{UID},
                SERVICE_ID  => '_SHOW',
                DEV_ID      => '_SHOW',
                ENABLE      => '_SHOW',
                IP_ACTIVITY => '_SHOW',
              });

              if ($element->{MAX_DEVICE} > $Iptv->{TOTAL}) {
                $result{tid} = $user->[0]{filter_id} || '';
                $result{uid} = $user_info->[0]{uid} || $user_info->[0]{UID};
                $Iptv->device_change({
                  ID  => $device->[0]{ID},
                  UID => $user_info->[0]{uid} || $user_info->[0]{UID},
                });
                if ($exist_device) {
                  $Sender->send_message({
                    TO_ADDRESS  => $FORM{phone},
                    MESSAGE     => $device->[0]{CODE},
                    SENDER_TYPE => 'Sms',
                    UID         => $result{uid}
                  });
                }
              }

              print json_former(\%result);
              return 1;
              last;
            }
          }

          if ($default_count) {
            $user = $Iptv->user_list({
              TP_FILTER  => '_SHOW',
              UID        => $user_info->[0]{uid} || $user_info->[0]{UID},
              SERVICE_ID => $default_params->[0]{SERVICE_ID},
              COLS_NAME  => 1,
            });

            $Iptv->device_list({
              UID         => $user_info->[0]{uid} || $user_info->[0]{UID},
              SERVICE_ID  => '_SHOW',
              DEV_ID      => '_SHOW',
              ENABLE      => '_SHOW',
              IP_ACTIVITY => '_SHOW',
            });

            if ($default_params->[0]{MAX_DEVICE} > $Iptv->{TOTAL}) {
              $result{tid} = $user->[0]{filter_id} || '';
              $result{uid} = $user_info->[0]{uid} || $user_info->[0]{UID};
              $Iptv->device_change({
                ID  => $device->[0]{ID},
                UID => $user_info->[0]{uid} || $user_info->[0]{UID},
              });
              if ($exist_device) {
                $Sender->send_message({
                  TO_ADDRESS  => $FORM{phone},
                  MESSAGE     => $device->[0]{CODE},
                  SENDER_TYPE => 'Sms',
                  UID         => $device->[0]{UID}
                });
              }
            }
            print json_former(\%result);
            return 1;
          }
        }
        else {
          foreach my $element (@$params) {
            if (check_ip($FORM{ip}, $element->{IP_MAC}) && $element->{IP_MAC} ne "0.0.0.0/0") {
              #              my $user_phone = '';
              #              if ($FORM{phone} =~ /^380\d{9}$/) {
              #                $user_phone = substr($FORM{phone}, 2, 10);
              #              }
              #              else {
              #                $result{status} = '';
              #                $result{tid} = '';
              #                $result{uid} = '';
              #                print json_former(\%result);
              #                return 1;
              #              }
              #              my $Payments = Finance->payments($db, $admin, \%conf);
              #              $Users->add({
              #                CREATE_BILL => 1,
              #                LOGIN       => "tv$user_phone",
              #                GID         => $element->{GROUP_ID},
              #              });
              #              my $uid = $Users->{INSERT_ID};
              #              $Users->info($uid);
              #              $Users->pi_add({ UID => $uid, PHONE => $FORM{phone} });
              #
              #              $Payments->add($Users, {
              #                SUM => $element->{BALANCE},
              #              });
              #
              #              $Iptv->user_add({
              #                UID        => $uid,
              #                TP_ID      => $element->{TP_ID},
              #                SERVICE_ID => $element->{SERVICE_ID},
              #                PIN        => $element->{PIN},
              #              });
              #
              #              $result{uid} = $uid;
              #              $user = $Iptv->user_list({
              #                TP_FILTER  => '_SHOW',
              #                UID        => $uid,
              #                SERVICE_ID => $element->{SERVICE_ID},
              #                COLS_NAME  => 1,
              #              });
              #              $result{tid} = $user->[0]{filter_id} || '';

              $Iptv->device_change({
                ID  => $device->[0]{ID},
                UID => '0',
              });

              $result{tid} = '';
              $result{uid} = '';
              print json_former(\%result);
              return 1;
              last;
            }
          }
          if ($default_count) {
            my $user_phone = '';
            if ($FORM{phone} =~ /^380\d{9}$/) {
              $user_phone = substr($FORM{phone}, 2, 10);
            }
            else {
              $result{status} = '';
              $result{tid} = '';
              $result{uid} = '';
              print json_former(\%result);
              return 1;
            }
            my $Payments = Finance->payments($db, $admin, \%conf);
            $Users->add({
              CREATE_BILL => 1,
              LOGIN       => "tv$user_phone",
              GID         => $default_params->[0]{GROUP_ID},
            });
            my $uid = $Users->{INSERT_ID};
            $Users->info($uid);
            $Users->pi_add({ UID => $uid, PHONE => $FORM{phone} });

            $Payments->add($Users, {
              SUM => $default_params->[0]{BALANCE},
            });

            $Iptv->user_add({
              UID        => $uid,
              TP_ID      => $default_params->[0]{TP_ID},
              SERVICE_ID => $default_params->[0]{SERVICE_ID},
              PIN        => $default_params->[0]{PIN},
            });

            $result{uid} = $uid;
            $user = $Iptv->user_list({
              TP_FILTER  => '_SHOW',
              UID        => $uid,
              SERVICE_ID => $default_params->[0]{SERVICE_ID},
              COLS_NAME  => 1,
            });
            $result{tid} = $user->[0]{filter_id} || '';

            $Iptv->device_change({
              ID  => $device->[0]{ID},
              UID => $uid,
            });

            if ($exist_device) {
              $Sender->send_message({
                TO_ADDRESS  => $FORM{phone},
                MESSAGE     => $device->[0]{CODE},
                SENDER_TYPE => 'Sms',
                UID         => $uid,
              });
            }

            print json_former(\%result);
            return 1;
          }
        }
      }
    }
    elsif ($FORM{action} eq "verify") {
      $Iptv->{TOTAL} = 0;
      $result{status} = '';
      $result{tid} = '';
      my $user = $Iptv->user_list({
        TP_FILTER  => '_SHOW',
        UID        => $device->[0]{UID},
        SERVICE_ID => $device->[0]{SERVICE_ID},
        COLS_NAME  => 1,
      });

      if ($Iptv->{TOTAL} > 0) {
        $result{tid} = $user->[0]{filter_id};
        $result{status} = $device->[0]{ENABLE} eq 1 ? "unverified" : "active";
      }
      else {
        my $res = _ip_user_search($device->[0]{SERVICE_ID}, $device->[0]{ID}, $device->[0]{CODE}, $exist_device);
        if ($res && $res->{uid}) {
          my %final_result;
          $final_result{tid} = $res->{tid};
          $final_result{status} = $device->[0]{ENABLE} eq 1 ? "unverified" : "active";
          print json_former(\%final_result);
          exit;
        }
        else {
          my %final_result;
          $final_result{tid} = '';
          $final_result{status} = '';
          print json_former(\%final_result);
          exit;
        }
      }
    }
    else {
      my $user = $Users->info($device->[0]{UID});
      $result{login} = $user->{LOGIN};
      $result{balance} = $user->{DEPOSIT};
      if (!$Users->{TOTAL}) {
        my $res = _ip_user_search($device->[0]{SERVICE_ID}, $device->[0]{ID}, $device->[0]{CODE}, $exist_device);
        if ($res && $res->{uid}) {
          my %final_result;
          $final_result{login} = $res->{login};
          $final_result{balance} = $res->{balance};
          print json_former(\%final_result);
          exit;
        }
        else {
          my %final_result;
          $final_result{login} = '';
          $final_result{balance} = '';
          print json_former(\%final_result);
          exit;
        }
      }
      print json_former(\%result);
      exit;
    }
  }

  print json_former(\%result);
}

#**********************************************************
=head2 smartup_pin($attr)

  Arguments:

  Returns:


=cut
#**********************************************************
sub smartup_pin {
  my ($attr) = @_;

  my $device = $Iptv->device_list({
    UID         => '_SHOW',
    SERVICE_ID  => '_SHOW',
    DEV_ID      => $FORM{duid},
    ENABLE      => '_SHOW',
    IP_ACTIVITY => '_SHOW',
    CODE        => '_SHOW',
  });

  my $code = 10000000 + int rand(89999999);
  my $exist_device = 0;
  my %result;
  $result{pin} = '';

  if (!$Iptv->{TOTAL}) {
    my $service_list = $Iptv->services_list({
      MODULE    => "SmartUp",
      COLS_NAME => 1,
    });
    if ($Iptv->{TOTAL}) {
      $Iptv->device_add({
        DEV_ID        => $FORM{duid},
        UID           => 0,
        ENABLE        => 1,
        DATE_ACTIVITY => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime()),
        IP_ACTIVITY   => '',
        SERVICE_ID    => $service_list->[0]{id},
        CODE          => $code,
      });

      $device = $Iptv->device_list({
        UID         => '_SHOW',
        SERVICE_ID  => '_SHOW',
        DEV_ID      => $FORM{duid},
        ENABLE      => '_SHOW',
        IP_ACTIVITY => '_SHOW',
        CODE        => '_SHOW',
      });
      $exist_device = 1;
    }
  }

  my $user = $Iptv->user_list({
    PIN        => '_SHOW',
    UID        => $device->[0]{UID},
    SERVICE_ID => $device->[0]{SERVICE_ID},
    COLS_NAME  => 1,
  });

  if ($Iptv->{TOTAL} > 0) {
    if ($attr->{ACTION} eq "pin") {
      $result{pin} = $user->[0]{pin};
      print json_former(\%result);
      exit;
    }
    if ($attr->{ACTION} eq "set") {
      $Iptv->user_change({
        ID  => $user->[0]{id},
        PIN => $FORM{set},
      });
      if (!$Iptv->{error} && $Iptv->{PIN}) {
        $result{pin} = $Iptv->{PIN};
        print json_former(\%result);
      }
      exit;
    }
  }
  else {
    my $res = _ip_user_search($device->[0]{SERVICE_ID}, $device->[0]{ID}, $device->[0]{CODE}, $exist_device);
    if ($res && $res->{uid}) {
      my %final_result;

      if ($attr->{ACTION} eq "pin") {
        $final_result{pin} = $res->{pin};
        print json_former(\%final_result);
        exit;
      }
      if ($attr->{ACTION} eq "set") {
        $user = $Iptv->user_list({
          PIN        => '_SHOW',
          UID        => $res->{uid},
          SERVICE_ID => $device->[0]{SERVICE_ID},
          COLS_NAME  => 1,
        });
        $Iptv->user_change({
          ID  => $user->[0]{id},
          PIN => $FORM{set},
        });
        if (!$Iptv->{error} && $Iptv->{PIN}) {
          $final_result{pin} = $Iptv->{PIN};
          print json_former(\%final_result);
        }
        exit;
      }
      print json_former(\%final_result);
      exit;
    }
  }

  print json_former(\%result);
}

#**********************************************************
=head2 _ip_user_search($attr)

  Arguments:

  Returns:


=cut
#**********************************************************
sub _ip_user_search {
  my ($service_id, $device_id, $code, $new_device) = @_;

  my %result;
  use Internet;
  use AXbills::Sender::Core;
  my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf);
  my $Internet = Internet->new($db, $admin, \%conf);
  my $Users = Users->new($db, $admin, \%conf);

  my $params = $Iptv->extra_params_list({
    SERVICE_ID => $service_id,
    GROUP_ID   => '_SHOW',
    TP_ID      => '_SHOW',
    SMS_TEXT   => '_SHOW',
    SEND_SMS   => '_SHOW',
    IP_MAC     => '_SHOW',
    BALANCE    => '_SHOW',
    MAX_DEVICE => '_SHOW',
    PIN        => '_SHOW',
  });

  my $default_params = $Iptv->extra_params_list({
    SERVICE_ID => $service_id,
    GROUP_ID   => '_SHOW',
    TP_ID      => '_SHOW',
    SMS_TEXT   => '_SHOW',
    SEND_SMS   => '_SHOW',
    IP_MAC     => "0.0.0.0/0",
    BALANCE    => '_SHOW',
    MAX_DEVICE => '_SHOW',
    PIN        => '_SHOW',
  });

  my $default_count = @$default_params;

  my $Internet_user_list = $Internet->user_list({
    LOGIN      => '_SHOW',
    UID        => '_SHOW',
    FIO        => '_SHOW',
    ONLINE     => '_SHOW',
    ONLINE_IP  => $FORM{ip},
    ONLINE_CID => '_SHOW',
    TP_NAME    => '_SHOW',
    IP         => '_SHOW',
    COLS_NAME  => 1,
    PAGE_ROWS  => 1000000
  });

  if ($Internet->{TOTAL}) {
    $user = $Iptv->user_list({
      TP_FILTER  => '_SHOW',
      PIN        => '_SHOW',
      UID        => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
      SERVICE_ID => $service_id,
      COLS_NAME  => 1,
    });

    if ($Iptv->{TOTAL}) {
      $result{uid} = $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID};
      $result{tid} = $user->[0]{filter_id} || '';
      $result{pin} = $user->[0]{pin} || '';

      $Iptv->device_change({
        ID  => $device_id,
        UID => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
      });

      my $user = $Users->info($result{uid});
      my $logins_list = $Users->list({
        PHONE     => '_SHOW',
        UID       => $result{uid},
        COLS_NAME => 1,
        PAGE_ROWS => 1000000
      });

      if (($logins_list->[0]{PHONE} || $logins_list->[0]{phone}) && $new_device && $code) {
        $Sender->send_message({
          TO_ADDRESS  => $logins_list->[0]{PHONE} || $logins_list->[0]{phone},
          MESSAGE     => $code,
          SENDER_TYPE => 'Sms',
          UID         => $result{uid},
        });
      }

      $result{login} = $user->{LOGIN};
      $result{balance} = $user->{DEPOSIT};
      return \%result;
    }

    foreach my $element (@$params) {
      if (check_ip($FORM{ip}, $element->{IP_MAC}) && $element->{IP_MAC} ne "0.0.0.0/0") {
        $Iptv->user_add({
          UID        => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
          TP_ID      => $element->{TP_ID},
          SERVICE_ID => $element->{SERVICE_ID},
          PIN        => $element->{PIN},
        });

        $result{uid} = $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID};
        $user = $Iptv->user_list({
          TP_FILTER  => '_SHOW',
          PIN        => '_SHOW',
          UID        => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
          SERVICE_ID => $element->{SERVICE_ID},
          COLS_NAME  => 1,
        });
        $result{tid} = $user->[0]{filter_id} || '';
        $result{pin} = $user->[0]{pin} || '';

        $Iptv->device_change({
          ID  => $device_id,
          UID => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
        });
        my $logins_list = $Users->list({
          PHONE     => '_SHOW',
          UID       => $result{uid},
          COLS_NAME => 1,
          PAGE_ROWS => 1000000
        });

        if (($logins_list->[0]{PHONE} || $logins_list->[0]{phone}) && $new_device && $code) {
          $Sender->send_message({
            TO_ADDRESS  => $logins_list->[0]{PHONE} || $logins_list->[0]{phone},
            MESSAGE     => $code,
            SENDER_TYPE => 'Sms',
            UID         => $result{uid},
          });
        }

        my $user = $Users->info($result{uid});
        $result{login} = $user->{LOGIN};
        $result{balance} = $user->{DEPOSIT};
        return \%result;

        last;
      }
    }

    if ($default_count) {
      $Iptv->user_add({
        UID        => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
        TP_ID      => $default_params->[0]{TP_ID},
        SERVICE_ID => $default_params->[0]{SERVICE_ID},
        PIN        => $default_params->[0]{PIN},
      });

      $result{uid} = $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID};
      $user = $Iptv->user_list({
        TP_FILTER  => '_SHOW',
        PIN        => '_SHOW',
        UID        => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
        SERVICE_ID => $default_params->[0]{SERVICE_ID},
        COLS_NAME  => 1,
      });
      $result{tid} = $user->[0]{filter_id} || '';
      $result{pin} = $user->[0]{pin} || '';

      $Iptv->device_change({
        ID  => $device_id,
        UID => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
      });
      my $logins_list = $Users->list({
        PHONE     => '_SHOW',
        UID       => $result{uid},
        COLS_NAME => 1,
        PAGE_ROWS => 1000000
      });

      if (($logins_list->[0]{PHONE} || $logins_list->[0]{phone}) && $new_device && $code) {
        $Sender->send_message({
          TO_ADDRESS  => $logins_list->[0]{PHONE} || $logins_list->[0]{phone},
          MESSAGE     => $code,
          SENDER_TYPE => 'Sms',
          UID         => $result{uid},
        });
      }

      my $user = $Users->info($result{uid});
      $result{login} = $user->{LOGIN};
      $result{balance} = $user->{DEPOSIT};
      return \%result;
    }
  }

  return 0;
}

#**********************************************************
=head2 iptv_check_service($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub iptv_check_service {

  my $extra_params = $Iptv->extra_params_list({
    SERVICE_ID => '_SHOW',
    GROUP_ID   => '_SHOW',
    TP_ID      => '_SHOW',
    SMS_TEXT   => '_SHOW',
    SEND_SMS   => '_SHOW',
    IP_MAC     => '_SHOW',
    BALANCE    => '_SHOW',
    MAX_DEVICE => '_SHOW',
    PIN        => '_SHOW',
  });

  return 0 if !$Iptv->{TOTAL};

  foreach my $param (@{$extra_params}) {
    if ($param->{SERVICE_ID} && check_ip($ENV{REMOTE_ADDR}, "$param->{IP_MAC}")) {
      my $function_name = "iptv_" . (lc $param->{SERVICE_MODULE} || "");
      next if (!defined(&{$function_name}));

      print "Content-Type: text/json\n\n" if $param->{SERVICE_MODULE} ne 'Smotreshka';
      &{\&{$function_name}}($param);
      return 1;
    }
  }

  return 0;
}

#**********************************************************
=head2 print_result($result, $attr)

=cut
#**********************************************************
sub print_result {
  my $result = shift;
  my ($attr) = @_;

  print "Status: $attr->{STATUS}\n" if $attr->{STATUS};
  print "Content-Type: text/json\n\n";

  print json_former($result);
}

#**********************************************************
=head2 iptv_smotreshka($attr)

=cut
#**********************************************************
sub iptv_smotreshka {
  my ($attr) = @_;

  my $params = $FORM{__BUFFER} ? decode_json($FORM{__BUFFER}) : ();

  if (!$params->{id} || !$params->{offerId}) {
    print_result({ id => 'error_bad_request', message => 'Не переданы обязательные поля' }, { STATUS => 400 });
    return;
  }

  my $user_info = _smotreshka_get_user($params->{id}, $attr->{SERVICE_ID});
  return if !$user_info;

  my $tariff = _smotreshka_get_tp($params->{offerId}, $attr->{SERVICE_ID});
  return if !$tariff;

  my $tp_price = $tariff->{month_fee} || $tariff->{day_fee};
  if ($tp_price && $user_info->{deposit} < $tp_price) {
    print_result({
      id      => 'no_sufficient_balance',
      message => 'Не не хватает денежных средств на лицевом счёте'
    }, { STATUS => 400 });
    return;
  }

  _smotreshka_change_tp($tariff, $user_info, { %{$attr}, QUERY_ARGS => $params->{queryArgs} ? $params->{queryArgs}[0] : () });
}

#**********************************************************
=head2 _smotreshka_change_tp($tariff, $user_info, $attr)

=cut
#**********************************************************
sub _smotreshka_change_tp {
  my ($tariff, $user_info, $attr) = @_;

  load_module('Iptv', $html);
  my $Tv_service = tv_load_service($attr->{SERVICE_MODULE}, { SERVICE_ID => $attr->{SERVICE_ID} });
  if (!$Tv_service || !$Tv_service->can('user_change')) {
    print_result({ id => 'internal_error', message => 'Сервис не найден' }, { STATUS => 500 });
    return 0;
  }

  $Iptv->{db}{db}->{AutoCommit} = 0;
  $Iptv->{db}->{TRANSACTION} = 1;

  $Iptv->user_change({
    TP_ID  => $tariff->{tp_id},
    ID     => $user_info->{id},
    UID    => $user_info->{uid},
    STATUS => 0
  });

  if ($Iptv->{errno}) {
    print_result({ id => 'internal_error', message => 'Ошибка при подключении сервиса' }, { STATUS => 500 });
    $Iptv->{db}{db}->rollback();
    return 0;
  }

  _iptv_get_service_fee({ INSERT_ID => $user_info->{id}, GET_FEE => 1 });

  $Tv_service->user_change({
    TP_FILTER_ID => $tariff->{filter_id},
    SUBSCRIBE_ID => $user_info->{subscribe_id},
    ID           => $user_info->{id},
    TP_INFO_OLD  => { FILTER_ID => $user_info->{filter_id} },
    QUERY_ARGS   => $attr->{QUERY_ARGS}
  });

  if ($Tv_service->{errno}) {
    print_result({ id => 'internal_error', message => 'Ошибка при подключении сервиса' }, { STATUS => 500 });
    $Iptv->{db}{db}->rollback();
    return 0;
  }

  $Iptv->{db}{db}->commit();

  use Fees;
  my $Fees = Fees->new($db, $admin, \%conf);

  my $last_fee = $Fees->list({ UID => $user_info->{uid}, DESC => 'DESC', PAGE_ROWS => 1, COLS_NAME => 1 });

  print_result({ id => 'subscription_added', transaction => { id => $last_fee->[0]{id} } }, { STATUS => 200 });
}

#**********************************************************
=head2 _smotreshka_get_user($subscribe_id, $service_id))

=cut
#**********************************************************
sub _smotreshka_get_user {
  my ($subscribe_id, $service_id) = @_;

  my $users_list = $Iptv->user_list({
    UID          => '_SHOW',
    LOGIN        => '_SHOW',
    TP_FILTER    => '_SHOW',
    SUBSCRIBE_ID => $subscribe_id,
    SERVICE_ID   => $service_id,
    COLS_NAME    => 1,
    PAGE_ROWS    => 99999,
  });

  if ($Iptv->{TOTAL} < 1 || !$users_list->[0]{uid}) {
    print_result({
      id      => 'error_no_account',
      message => 'Аккаунт не найден в БД биллинга',
      details => "Не удалось найти аккаунт с идентификатором $subscribe_id"
    }, { STATUS => 400 });
    return;
  }

  return $users_list->[0] || {};
}

#**********************************************************
=head2 _smotreshka_get_user($tp, $service_id)

=cut
#**********************************************************
sub _smotreshka_get_tp {
  my ($tp, $service_id) = @_;

  my $tariff = $Tariff->list({
    FILTER_ID  => $tp,
    SERVICE_ID => $service_id,
    MONTH_FEE  => '_SHOW',
    DAY_FEE    => '_SHOW',
    COLS_NAME  => 1
  });

  if ($Tariff->{TOTAL} < 1) {
    print_result({
      id      => 'error_bad_request',
      message => 'Услуга не найдена в БД биллинга',
      details => "Не удалось найти ТП с идентификатором $tp"
    }, { STATUS => 400 });
    return;
  }

  return $tariff->[0] || {};
}

#**********************************************************
=head2 iptv_wink($attr)

=cut
#**********************************************************
sub iptv_wink {
  my ($attr) = @_;

  my %paths = (
    '/activation-status'   => {
      METHOD   => 'GET',
      FUNCTION => '_wink_activation_status'
    },
    '/deactivation-status' => {
      METHOD   => 'GET',
      FUNCTION => '_wink_deactivation_status'
    },
    '/service/[^/]+/?$'    => {
      METHOD   => 'PUT',
      FUNCTION => '_wink_activate_deactivate_service'
    },
    '/service/[^/]+/?$'    => {
      METHOD   => 'POST',
      FUNCTION => '_wink_onetime_purchase'
    },
    '/account/[^/]+\?san=' => {
      METHOD   => 'GET',
      FUNCTION => '_wink_account_san'
    }
  );

  foreach my $path (keys %paths) {
    next if ($ENV{REQUEST_URI} !~ /$path/g || $paths{$path}{METHOD} ne $ENV{REQUEST_METHOD});

    my $function_name = $paths{$path}{FUNCTION};
    return if (!defined(&{$function_name}));

    &{\&{$function_name}}($ENV{REQUEST_URI}, { SERVICE_ID => $attr->{SERVICE_ID} });
  }
}

#**********************************************************
=head2 _wink_activation_status($request, $attr)

=cut
#**********************************************************
sub _wink_activation_status {
  my $request = shift;
  my ($attr) = @_;

  my (undef, undef, $uid, undef, $tp, undef) = split(/\//, $request);

  my ($tariff, $user_info) = _wink_check_user_and_tp($uid, $tp, $attr->{SERVICE_ID});
  return if !$tariff;

  my $tp_price = $tariff->{month_fee} || $tariff->{day_fee};
  if ($tp_price && $user_info->{DEPOSIT} < $tp_price) {
    print json_former({ code => 1, message => 'Не хватает средств для активации' });
    return;
  }

  # $Iptv->user_list({ SERVICE_ID => $attr->{SERVICE_ID}, UID => 1, TP_FILTER => '_SHOW', COLS_NAME => 1 });
  # if ($Iptv->{TOTAL} > 0) {
  #   print json_former({ code => 1, message => 'Уже активирован другой сервис' });
  #   return;
  # }

  print json_former({ code => 0, executionType => 'today' });
}

#**********************************************************
=head2 _wink_deactivation_status($request, $attr)

=cut
#**********************************************************
sub _wink_deactivation_status {
  my $request = shift;
  my ($attr) = @_;

  my (undef, undef, $uid, undef, $tp, undef) = split(/\//, $request);

  my ($tariff, $user_info) = _wink_check_user_and_tp($uid, $tp, $attr->{SERVICE_ID});
  return if !$tariff;

  my $iptv_info = $Iptv->user_list({ SERVICE_ID => $attr->{SERVICE_ID}, UID => $uid, TP_ID => $tariff->{tp_id}, COLS_NAME => 1 });
  if ($Iptv->{TOTAL} < 1) {
    print json_former({ code => 1, message => 'Услуга не найдена' });
    return;
  }

  print json_former({ code => 0, executionType => 'today' });
}

#**********************************************************
=head2 _wink_activate_deactivate_service($request, $attr)

=cut
#**********************************************************
sub _wink_activate_deactivate_service {
  my $request = shift;
  my ($attr) = @_;

  my (undef, undef, $uid, undef, $tp) = split(/\//, $request);

  my ($tariff, $user_info) = _wink_check_user_and_tp($uid, $tp, $attr->{SERVICE_ID});
  return if !$tariff;

  my $params = $FORM{__BUFFER} ? decode_json($FORM{__BUFFER}) : ();

  if (!$params->{operationType} || ($params->{operationType} ne 'signoff' && $params->{operationType} ne 'signon')) {
    print json_former({ code => 2, message => 'Не указан тип операции' });
    return;
  }

  my $iptv_info = $Iptv->user_list({
    SERVICE_ID => $attr->{SERVICE_ID},
    UID        => $uid,
    TP_FILTER  => '_SHOW',
    COLS_NAME  => 1
  });

  if ($params->{operationType} eq 'signoff') {
    if ($Iptv->{TOTAL} < 1) {
      print json_former({ code => 1, message => 'Услуга не найдена' });
      return;
    }

    $Iptv->user_del({ ID => $iptv_info->[0]{id} });
    if ($Iptv->{errno}) {
      print json_former({ code => 1, message => 'Ошибка при отключении' });
      return;
    }

    print json_former({ code => 0, executionType => 'today' });
    return;
  }

  if ($Iptv->{TOTAL} > 0 && $iptv_info->[0]{filter_id} eq $tp) {
    print json_former({ code => 1, message => 'Эта услуга уже подключена' });
    return;
  }

  my $tp_price = $tariff->{month_fee} || $tariff->{day_fee};
  if ($tp_price && $user_info->{DEPOSIT} < $tp_price) {
    print json_former({ code => 1, message => 'Не хватает средств для активации' });
    return;
  }

  $Iptv->{db}{db}->{AutoCommit} = 0;
  $Iptv->{db}->{TRANSACTION} = 1;
  $Iptv->user_del({ ID => $iptv_info->[0]{id} }) if ($Iptv->{TOTAL} > 0);

  $Iptv->user_add({ UID => $uid, TP_ID => $tariff->{tp_id}, SERVICE_ID => $attr->{SERVICE_ID} });
  if (!$Iptv->{errno}) {
    $Iptv->user_info($Iptv->{INSERT_ID});
    service_get_month_fee($Iptv, { SERVICE_NAME => $lang{TV}, MODULE => 'Iptv', QUITE => 1 });

    delete($Iptv->{db}->{TRANSACTION});
    $Iptv->{db}{db}->commit();
    $Iptv->{db}{db}->{AutoCommit} = 1;

    print json_former({ code => 0, executionType => 'today' });
    return;
  }

  $Iptv->{db}{db}->rollback();
  print json_former({ code => 1, message => 'Ошибка при подключении' });

  return 1;
}

#**********************************************************
=head2 _wink_account_san($request, $attr)

=cut
#**********************************************************
sub _wink_account_san {
  my $request = shift;
  my ($attr) = @_;

  my ($uid) = $request =~ /\/(\w+)\?/;
  my $user_info = $Users->info($uid);
  if ($Users->{TOTAL} < 1) {
    print json_former({ code => 1, message => 'Пользователь не найден' });
    return 0;
  }

  my $deposit = sprintf("%.2f", $user_info->{DEPOSIT}) * 100;
  print json_former({ code => 0, balance => $deposit });
}

#**********************************************************
=head2 _wink_onetime_purchase($request, $attr)

=cut
#**********************************************************
sub _wink_onetime_purchase {
  my $request = shift;
  my ($attr) = @_;

  my (undef, undef, $uid, undef, $tp) = split(/\//, $request);

  my ($tariff, $user_info) = _wink_check_user_and_tp($uid, $tp, $attr->{SERVICE_ID});
  return if !$tariff;

  my $iptv_info = $Iptv->user_list({ SERVICE_ID => $attr->{SERVICE_ID}, UID => $uid, TP_ID => $tariff->{tp_id}, COLS_NAME => 1 });
  if ($Iptv->{TOTAL} < 1) {
    print json_former({ code => 1, message => 'Услуга не найдена' });
    return;
  }

  my $params = $FORM{__BUFFER} ? decode_json($FORM{__BUFFER}) : ();
  if (!defined $params->{description} && !$params->{price}) {
    print json_former({ code => 1, message => 'Не переданы все параметры (цена или описание)' });
    return;
  }

  my $price = $params->{price} / 100;
  if ($price > $user_info->{DEPOSIT}) {
    print json_former({ code => 2, message => 'Не хватает средств' });
    return;
  }

  use Fees;
  my $Fees = Fees->new($db, $admin, \%conf);
  $Fees->take($user_info, $price, { DESCRIBE => $params->{description} });

  if ($Fees->{errno}) {
    print json_former({ code => 2, message => 'Ошибка при оплате' });
    return;
  }

  print json_former({ code => 0, transactionId => $Fees->{FEES_ID} });
}

#**********************************************************
=head2 _wink_check_user_and_tp($uid, $tp, $service_id)

=cut
#**********************************************************
sub _wink_check_user_and_tp {
  my ($uid, $tp, $service_id) = @_;

  if (!$uid || !$tp) {
    print json_former({ code => 1, message => 'Неверные данные' });
    return 0;
  }

  my $user_info = $Users->info($uid);
  if ($Users->{TOTAL} < 1) {
    print json_former({ code => 1, message => 'Пользователь не найден' });
    return 0;
  }

  my $tariff = $Tariff->list({
    FILTER_ID  => $tp,
    SERVICE_ID => $service_id,
    MONTH_FEE  => '_SHOW',
    DAY_FEE    => '_SHOW',
    COLS_NAME  => 1
  });
  if ($Tariff->{TOTAL} < 1) {
    print json_former({ code => 1, message => 'Тарифный план не найден' });
    return 0;
  }

  return $tariff->[0], $user_info;
}

#**********************************************************
=head2 iptv_24tv($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub iptv_24tv {
  my ($attr) = @_;

  my (@params) = split(/&/, $ENV{QUERY_STRING});
  foreach my $param (@params) {
    my ($key, $value) = split(/=/, $param);
    $FORM{$key} = $value if $key;
  }

  if ($FORM{ip} && $FORM{phone} && $FORM{mbr_id}) {
    _iptv_24tv_auth($attr);
    return 1;
  }

  if ($FORM{trf_id}) {
    _iptv_24tv_packet($attr);
    return 1;
  }

  if ($FORM{user_id} && $FORM{sub_id}) {
    _iptv_24tv_del_sub($attr);
    return 1;
  }

  return 0;
}

#**********************************************************
=head2 _iptv_24tv_auth($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _iptv_24tv_auth {
  my ($attr) = @_;

  my $Internet = Internet->new($db, $admin, \%conf);
  my $user_info = $Internet->user_list({
    PHONE      => "*$FORM{phone}",
    UID        => '_SHOW',
    COLS_NAME  => 1,
    COLS_UPPER => 1,
  });

  if ($Internet->{TOTAL}) {
    print json_former({ "user_id" => $user_info->[0]{uid}, });
    return 1;
  }

  print json_former({
    "status" => -1,
    "err"    => -1,
    "errmsg" => "Пользователь не найден"
  });

  return 1;
}

#**********************************************************
=head2 _iptv_24tv_packet($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _iptv_24tv_packet {
  my ($attr) = @_;

  load_module('Iptv', $html);
  my $params = decode_json($FORM{__BUFFER});

  #  Get user subscribe info
  my $user_info = $Iptv->user_list({
    UID          => $params->{user}{provider_uid},
    SERVICE_ID   => $attr->{SERVICE_ID},
    TP_FILTER    => '_SHOW',
    SUBSCRIBE_ID => $params->{user}{id},
    TP_ID        => '_SHOW',
    MONTH_FEE    => '_SHOW',
    PHONE        => '_SHOW',
    LOGIN        => '_SHOW',
    COLS_NAME    => 1,
    COLS_UPPER   => 1,
  });

  _iptv_24tv_print_err({ message => "Добаление дополнительного пакета возможно только при наличии основного пакета." }) if (!$Iptv->{TOTAL} && !$params->{packet}{is_base});
  return 0 if (!$Iptv->{TOTAL} && !$params->{packet}{is_base});

  my $Tv_service = tv_load_service($attr->{SERVICE_MODULE}, { SERVICE_ID => $attr->{SERVICE_ID} });
  if (!$Tv_service) {
    _iptv_24tv_print_err({ message => "Ошибка при подписке" });
    return 0;
  }

  if ($params->{packet}{is_base}) {
    _iptv_base_tariffs({
      TV_SERVICE        => $Tv_service,
      ID                => $Iptv->{TOTAL} > 0 ? $user_info->[0]{ID} : 0,
      FILTER_ID         => $params->{packet}{id},
      UID               => $params->{user}{provider_uid},
      SUBSCRIBE_ID      => $params->{user}{id},
      SERVICE_ID        => $attr->{SERVICE_ID},
      CURRENT_MONTH_FEE => $Iptv->{TOTAL} ? $user_info->[0]{MONTH_FEE} : 0,
      TP_ID             => $user_info->[0]{TP_ID},
      LOGIN             => $user_info->[0]{LOGIN},
      PHONE             => $user_info->[0]{PHONE}
    });
    return 1;
  }

  if (!$params->{packet}{is_base}) {
    _iptv_additional_tariffs({
      TV_SERVICE   => $Tv_service,
      UID          => $params->{user}{provider_uid},
      IDS          => $params->{packet}{id},
      TP_ID        => $user_info->[0]{TP_ID},
      ID           => $user_info->[0]{ID},
      SUBSCRIBE_ID => $params->{user}{id},
    });
    return 1;
  }

  return 0;
}

#**********************************************************
=head2 _iptv_24tv_print_err($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _iptv_24tv_print_err {
  my ($attr) = @_;

  print json_former({
    "status" => -2,
    "err"    => -2,
    "errmsg" => $attr->{message}
  });

  return 1;
}

#**********************************************************
=head2 _iptv_24tv_print_err($attr)

  Arguments:
    $attr->{INSERT_ID}

  Returns:

=cut
#**********************************************************
sub _iptv_get_service_fee {
  my ($attr) = @_;

  $Iptv->user_info($attr->{INSERT_ID});
  my $user_info = $Users->info($Iptv->{UID});

  my %users_services = ();
  my %FEES_DSC = (
    MODULE            => "Iptv",
    SERVICE_NAME      => $lang{TV},
    TP_ID             => $Iptv->{TP_NUM},
    TP_NAME           => $Iptv->{TP_NAME},
    FEES_PERIOD_MONTH => $lang{MONTH_FEE_SHORT},
  );

  push @{$users_services{$Iptv->{UID}}}, {
    SUM       => $Iptv->{MONTH_FEE},
    DESCRIBE  => fees_dsc_former(\%FEES_DSC),
    FILTER_ID => $Iptv->{TP_FILTER_ID},
    ID        => $Iptv->{ID}
  };

  $Iptv->{REDUCTION} = $Iptv->{REDUCTION_FEE} || 0;
  return get_service_fee($user_info, \%users_services, {
    DATE             => $DATE,
    METHOD           => 1,
    PERIOD_ALIGNMENT => $Iptv->{PERIOD_ALIGNMENT},
    GET_SUM          => $attr->{GET_FEE} ? 0 : 1
  });
}

#**********************************************************
=head2 _iptv_additional_tariffs($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _iptv_additional_tariffs {
  my ($attr) = @_;

  my $ti_list = $Tariff->ti_list({ TP_ID => $attr->{TP_ID} });

  if (!$Tariff->{TOTAL}) {
    _iptv_24tv_print_err({ message => "Тариф не найден (основной)" });
    return 0;
  }

  my $user_channels_list = $Iptv->user_channels_list({
    ID        => $attr->{ID},
    TP_ID     => $attr->{TP_ID},
    COLS_NAME => 1,
  });

  my $channels = $Iptv->channel_ti_list({
    COLS_NAME        => 1,
    USER_INTERVAL_ID => $ti_list->[0][0],
    FILTER_ID        => $attr->{IDS},
    ID               => '_SHOW',
  });

  if (!$Iptv->{TOTAL}) {
    _iptv_24tv_print_err({ message => "Тариф не найден (дополнительный)" });
    return 0;
  }

  my $Tv_service = $attr->{TV_SERVICE};

  if ($Tv_service && $Tv_service->can('user_sub')) {
    $Tv_service->{debug} = 0;
    my $result = $Tv_service->user_sub({
      UID => $attr->{SUBSCRIBE_ID},
      TP  => $attr->{IDS}
    });

    if (ref($result) eq 'HASH' && $result->{error}) {
      _iptv_24tv_print_err({ message => "Ошибка при подписке" });
      return 0;
    }

    $Iptv->user_channels({
      ID    => $attr->{ID},
      TP_ID => $attr->{TP_ID},
      IDS   => $channels->[0]{channel_id} || $channels->[0]{channel_id}
    });

    my %users_services = ();
    $Iptv->user_info($attr->{ID});
    if (!$Iptv->{errno}) {
      iptv_channels_fees({
        UID            => $Iptv->{UID},
        TP_ID          => $Iptv->{TP_ID},
        TP_NUM         => $Iptv->{TP_NUM},
        TP             => $Iptv,
        USERS_SERVICES => \%users_services,
      });

      my $ulist_main = $Iptv->user_list({
        ID           => $attr->{ID},
        LOGIN        => '_SHOW',
        SUBSCRIBE_ID => '_SHOW',
        DEPOSIT      => '_SHOW',
        CREDIT       => '_SHOW',
        BILL_ID      => '_SHOW',
        REDUCTION    => '_SHOW',
        TP_ID        => $attr->{TP_ID},
        COLS_NAME    => 1,
      });

      if ($Iptv->{TOTAL}) {
        my %user = (
          ID           => $ulist_main->[0]{id},
          LOGIN        => $ulist_main->[0]{login},
          UID          => $ulist_main->[0]{uid},
          BILL_ID      => $ulist_main->[0]{bill_id},
          DEPOSIT      => $ulist_main->[0]{deposit},
          CREDIT       => $ulist_main->[0]{credit},
          REDUCTION    => $ulist_main->[0]{reduction} || 0,
          IPTV_STATUS  => $ulist_main->[0]{service_status},
          SUBSCRIBE_ID => $ulist_main->[0]{subscribe_id},
        );

        get_service_fee(\%user, \%users_services, {
          DATE   => $DATE,
          METHOD => 1,
        });
      }
    }

    my $tariffs = "";
    foreach my $packet (@{$user_channels_list}) {
      $tariffs .= ($packet->{channel_id} || $packet->{channel_id}) . ", ";
    }

    $tariffs .= $channels->[0]{channel_id};

    $Iptv->user_channels({
      ID    => $attr->{ID},
      TP_ID => $attr->{TP_ID},
      IDS   => $tariffs
    });

    print json_former({ "status" => 1 });
    return 1;
  }

  _iptv_24tv_print_err({ message => "Ошибка при подписке" });
  return 0;
}

#**********************************************************
=head2 _iptv_base_tariffs($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _iptv_base_tariffs {
  my ($attr) = @_;

  my $tariff_info = $Tariff->list({
    NAME       => '_SHOW',
    TP_ID      => '_SHOW',
    MONTH_FEE  => '_SHOW',
    FILTER_ID  => $attr->{FILTER_ID},
    SERVICE_ID => $attr->{SERVICE_ID},
    COLS_NAME  => 1,
    COLS_UPPER => 1,
  });

  if (!$Tariff->{TOTAL}) {
    _iptv_24tv_print_err({ message => "Тариф не найден" });
    return 0;
  }

  my $more_expensive = $attr->{CURRENT_MONTH_FEE} > $tariff_info->[0]{month_fee} ? 1 : 0;

  if ($more_expensive) {
    my $change_date = Time::Piece->strptime($DATE, "%Y-%m-%d");
    $change_date += ONE_MONTH;
    $change_date = $change_date->ymd;
    my ($year, $month, undef) = split('-', $change_date);

    _iptv_del_shedulers({ UID => $attr->{UID} });
    $Shedule->add({
      UID          => $attr->{UID},
      TYPE         => 'tp',
      ACTION       => "$attr->{TP_ID}:$tariff_info->[0]{tp_id}",
      D            => 1,
      M            => $month,
      Y            => $year,
      COMMENTS     => "$lang{FROM}: $tariff_info->[0]{tp_id}:$tariff_info->[0]{name}",
      ADMIN_ACTION => 1,
      MODULE       => 'Iptv',
    });
    _iptv_24tv_print_err({ message => $Shedule->{errstr} }) if ($Shedule->{errno});
    return 0 if $Shedule->{errno};

    print json_former({
      "status" => 1,
      "errmsg" => "Переход на пакет запланирован после окончания текущего!"
    });
    return 0;
  }

  $Users->info($attr->{UID});
  if ($Users->{DEPOSIT} + $Users->{CREDIT} < $tariff_info->[0]{month_fee}) {
    _iptv_24tv_print_err({ message => 'Не хватает денег на подписку!' });
    return 0;
  }

  $Users->pi({ UID => $attr->{UID} });
  my $Tv_service = $attr->{TV_SERVICE};
  if ($Tv_service && $Tv_service->can('user_change') && $attr->{ID}) {
    $Tv_service->{debug} = 0;
    delete $Tv_service->{errno};

    my $result = $Tv_service->user_change({
      FIO           => $Users->{TOTAL} > 0 ? $Users->{FIO} : '',
      UID           => $attr->{UID},
      SUBSCRIBE_ID  => $attr->{SUBSCRIBE_ID},
      TP_FILTER_ID  => $attr->{FILTER_ID},
      STATUS        => 0,
      DEL_BASE_SUBS => 1,
    });
    if (ref $result eq "HASH" && $result->{errno}) {
      _iptv_24tv_print_err({ message => "Ошибка при подписке" });
      return 0;
    }
  }
  elsif ($Tv_service && $Tv_service->can('user_sub') && !$attr->{ID}) {
    $Tv_service->{debug} = 0;
    delete $Tv_service->{errno};
    my $result = $Tv_service->user_sub({
      FIO         => $Users->{TOTAL} > 0 ? $Users->{FIO} : '',
      UID         => $attr->{SUBSCRIBE_ID},
      LOGIN       => $attr->{LOGIN} || $Users->{LOGIN},
      PHONE       => $attr->{PHONE} || $Users->{PHONE},
      TP          => $attr->{FILTER_ID},
      STATUS      => 0,
      DEL_BASE    => 1,
      CHANGE_INFO => 1
    });
    if (ref $result eq "HASH" && $result->{errno}) {
      _iptv_24tv_print_err({ message => "Ошибка при подписке" });
      return 0;
    }
  }

  $Iptv->user_del({ ID => $attr->{ID} }) if $attr->{ID};

  #  Add user subscribe
  _iptv_del_shedulers({ UID => $attr->{UID} });
  $Iptv->user_add({
    SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID},
    UID          => $attr->{UID},
    SERVICE_ID   => $attr->{SERVICE_ID},
    TP_ID        => $tariff_info->[0]{tp_id}
  });

  if ($Iptv->{errstr} && $Iptv->{errstr} eq "TOO_SMALL_DEPOSIT") {
    $Iptv->{errstr} = "Не хватает денег на подписку.";
  }
  _iptv_24tv_print_err({ message => $Iptv->{errstr} }) if ($Iptv->{errno});
  return 0 if $Iptv->{errno};

  my $result = _iptv_get_service_fee({ INSERT_ID => $Iptv->{INSERT_ID} });

  if ($result) {
    if ($Tv_service && $Tv_service->can('_user_update_deposit')) {
      $Users->pi({ UID => $attr->{UID} });
      $Tv_service->_user_update_deposit({
        SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID},
        DEPOSIT      => $Users->{DEPOSIT} || 0
      });
    }

    print json_former({ "status" => 1 });
    return 1;
  }

  return 0;
}

#**********************************************************
=head2 _iptv_del_shedulers($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _iptv_del_shedulers {
  my ($attr) = @_;

  my $shedulers = $Shedule->list({
    UID       => $attr->{UID},
    MODULE    => "Iptv",
    TYPE      => "tp",
    COLS_NAME => 1
  });

  foreach my $shed (@{$shedulers}) {
    $Shedule->del({ ID => $shed->{id} });
  }

  return 1;
}

#**********************************************************
=head2 _iptv_del_shedulers($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _iptv_24tv_del_sub {
  my ($attr) = @_;

  load_module('Iptv', $html);
  my $Tv_service = tv_load_service($attr->{SERVICE_MODULE}, { SERVICE_ID => $attr->{SERVICE_ID} });
  if (!$Tv_service) {
    _iptv_24tv_print_err({ message => "Ошибка при отписке" });
    return 0;
  }
  my $params = decode_json($FORM{__BUFFER});

  if ($Tv_service && $Tv_service->can('user_unsub')) {
    $Tv_service->{debug} = 0;
    delete $Tv_service->{errno};
    my $result = $Tv_service->user_unsub({
      UID    => $params->{user}{id},
      SUB_ID => $FORM{sub_id},
    });

    if (ref $result eq "HASH" && $result->{errno}) {
      _iptv_24tv_print_err({ message => "Ошибка при отписке" });
      return 0;
    }

    my $packet_id = $params->{subscription}{packet}{is_base} ? $params->{subscription}{packet}{id} : '_SHOW';
    my $user_info = $Iptv->user_list({
      UID          => $params->{user}{provider_uid},
      SERVICE_ID   => $attr->{SERVICE_ID},
      TP_FILTER    => $packet_id,
      SUBSCRIBE_ID => $params->{user}{id},
      TP_ID        => '_SHOW',
      MONTH_FEE    => '_SHOW',
      COLS_NAME    => 1,
      COLS_UPPER   => 1,
    });

    if ($params->{subscription}{packet}{is_base}) {
      if ($Iptv->{TOTAL}) {
        $Iptv->user_del({
          ID => $user_info->[0]{ID}
        });
      }
    }

    if (!$params->{subscription}{packet}{is_base}) {
      if ($Iptv->{TOTAL}) {
        my $IDS = '';
        my $user_channels_list = $Iptv->user_channels_list({
          ID        => $user_info->[0]{ID},
          TP_ID     => $user_info->[0]{TP_ID},
          COLS_NAME => 1,
        });

        $packet_id = $params->{subscription}{packet}{id};
        my $channel_info = $Iptv->channel_list({
          NUM       => $packet_id,
          FILTER    => $packet_id,
          ID        => '_SHOW',
          COLS_NAME => 1,
        });

        if ($Iptv->{TOTAL}) {
          foreach my $user_channel (@{$user_channels_list}) {
            if ($user_channel->{channel_id} ne ($channel_info->[0]{id} || $channel_info->[0]{ID})) {
              $IDS .= $user_channel->{channel_id} . ", ";
            }
          }

          chop $IDS if ($IDS);
          $Iptv->user_channels({
            IDS   => $IDS || 0,
            ID    => $user_info->[0]{ID},
            TP_ID => $user_info->[0]{TP_ID},
          });
        }
      }
    }

    print json_former({ "status" => 1 });
    return 1;
  }

  return 0;
}

1;

