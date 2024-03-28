#!/usr/bin/perl

package AXbills::Backend::Plugin::Telegram::Extension::User_interface;
use strict;
use warnings FATAL => 'all';

=head2 NAME

  AXbills::Backend::Plugin::Telegram::Extension::Example
  
=head2 SYNOPSIS

  UI for ABillS Telegram bot.
   
=cut

use AXbills::Backend::Log;
use AXbills::Backend::Defs;

use AXbills::Backend::Plugin::Telegram;
use AXbills::Backend::Plugin::Telegram::Extension;
use parent 'AXbills::Backend::Plugin::Telegram::Extension';
use POSIX qw/strftime/;

use AXbills::Backend::Plugin::Telegram::Operation;

my $Internet;
if ($MODULES[0] eq 'Internet' ) {
  require Internet;
  $Internet = Internet->new($db, $admin, \%conf);
}

use Users;
use Tariffs;
use Shedule;
use Msgs;

my $Msgs     = Msgs->new($db, $admin, \%conf);
my $Users    = Users->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Shedule  = Shedule->new($db, $admin, \%conf);

my $EXTENSION = 'User_interface';

my AXbills::Backend::Log $Log =
  AXbills::Backend::Plugin::Telegram::Extension::build_log_for(
    $EXTENSION,
    '/usr/axbills/var/log/telegram_example.log'
  );

my AXbills::Backend::Plugin::Telegram $Telegram_Bot;

use AXbills::Base qw/_bp/;

#**********************************************************
=head2 add_extensions()

=cut
#**********************************************************
sub add_extensions {
  $Telegram_Bot = shift;

  $Telegram_Bot->add_callback('/info', \&info_callback);
  $Telegram_Bot->add_callback('/help', \&help_callback);
  $Telegram_Bot->add_callback('/message', \&message_callback);
  $Telegram_Bot->add_callback('/credit', \&credit_callback) if ($conf{user_credit_change});
  $Telegram_Bot->add_callback('/tarif', \&change_tp_callback) if ($conf{INTERNET_USER_CHG_TP});
   
  return 1;
}

#**********************************************************
=head2 next_payments()

=cut
#**********************************************************
sub next_payments {
  my ($uid) = @_;
  my $DATE = strftime "%Y-%m-%d", localtime(time);
  my ($year, $month, $day) = split(/-/, $DATE, 3);
  $Internet->user_info($uid);
  $Users->info($uid);

  if($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} > 0) {
    $Internet->{MONTH_ABON} = $Internet->{PERSONAL_TP};
  }

  my $reduction_division = ($Users->{REDUCTION} >= 100) ? 0 : ((100 - $Users->{REDUCTION}) / 100);
  return "\n" unless ($reduction_division);

  return "\n" if (!$Internet->{MONTH_ABON} && !$Internet->{DAY_ABON});

  if ($Internet->{ABON_DISTRIBUTION} && $Internet->{MONTH_ABON} > 0) {
    $Internet->{DAY_ABON} ||= 0;
    $Internet->{DAY_ABON} += $Internet->{MONTH_ABON} / 30;
  }

  if ($Internet->{DAY_ABON} && $Internet->{DAY_ABON} > 0) {
    my $days = int(($Users->{DEPOSIT} + $Users->{CREDIT} > 0) ?  ($Users->{DEPOSIT} + $Users->{CREDIT}) / ($Internet->{DAY_ABON} * $reduction_division) : 0);
    my $str = "Услуга завершится через $days дней.";
    return "$str\n";
  }

  my $payment_date = '';
  my $activate_day = (split(/-/, $Users->{ACTIVATE}, 3))[2];
  $activate_day = 0 if ($activate_day eq '00');
  my $payment_day = $activate_day || $conf{START_PERIOD_DAY} || 1;
  if ($payment_day <= $day) {
    $year++ if ($month == 12);
    $month = $month % 12;
    $month++;
  }
  $payment_date = sprintf("%02d.%02d.%04d", $payment_day, $month, $year);

  my $message = "_{NEXT_FEES}_ $payment_date\n";
  $message .= "_{SUM}_: " . int($Internet->{MONTH_ABON} * $reduction_division) if ($Internet->{MONTH_ABON});
  return $message;
}

#**********************************************************
=head2 message_callback()

=cut
#**********************************************************
sub message_callback {
  my ($first_message, $chat_id, $client_type, $client_id) = @_;

  if ($client_type eq 'AID') {
    $Telegram_Bot->send_text("Sorry, only for users.", $chat_id);
    return 1;
  };

  my $operation = AXbills::Backend::Plugin::Telegram::Operation->new({
    CHAT_ID    => $chat_id,
    TYPE       => $client_type,
    NAME       => 'MESSAGE_OPERATION',
    ON_START   => sub {
      my $message = "Введите текст сообщения.\n";
      $Telegram_Bot->send_text($message, $chat_id);
    },
    ON_MESSAGE => sub {
      my ($self, $msg) = @_;
      my $DATE = strftime "%Y-%m-%d", localtime(time);
      my $TIME = strftime "%H:%M:%S", localtime(time);
      my ($subject) = $msg->{text} =~ /^(.{1,50})/;
      $subject .= '...';

      $Msgs->message_add({
        UID       => $client_id,
        STATE     => 0,
        USER_READ => "$DATE $TIME",
        USER_SEND => 1,
        SUBJECT   => $subject,
        CHAPTER   => 1,
        PRIORITY  => 1,
        MESSAGE   => $msg->{text},
      });
      $Telegram_Bot->send_text("Сообщение <b>$subject</b> отправлено.\n\n_{HELP}_ /help\n", $chat_id, {parse_mode => 'HTML'});
      return 1;
    },
    ON_CALLBACK_QUERY => sub { }
  });

  return $operation;
}

#**********************************************************
=head2 credit_callback()

=cut
#**********************************************************
sub credit_callback {
  my ($first_message, $chat_id, $client_type, $client_id) = @_;

  my $operation = AXbills::Backend::Plugin::Telegram::Operation->new({
    CHAT_ID    => $chat_id,
    TYPE       => $client_type,
    NAME       => 'CREDIT_OPERATION',
    ON_START   => sub {
      my ($sum, $days, $price) = (split(':', $conf{user_credit_change}));
      my $message = "Кредит для доступа в интернет на $days дня.\n";
      $message .= "_{PRICE}_: <b>$price</b>\n" if ($price);

      my $inline_button1 = {text => "Взять кредит", callback_data => 'activate_credit'};
      my $inline_button2 = {text => "Отказаться", callback_data => '123'};
      my $inline_keyboard = [ [$inline_button1, $inline_button2] ];

      $Telegram_Bot->send_text($message, $chat_id, {
        reply_markup => { 
          inline_keyboard => $inline_keyboard
        },
        parse_mode   => 'HTML'
      });
    },
    ON_MESSAGE => sub {
      my ($self, $msg) = @_;
      $Telegram_Bot->send_text("1", $chat_id);
      return 1;
    },
    ON_CALLBACK_QUERY => sub {
      my ($self, $data) = @_;

      if ($data eq 'activate_credit') {
        my $cmd = "$base_dir/bin/abm_console INTERNET=1 CREDIT=1 UID=$client_id";
        my $output = `$cmd`;
        my ($result) = $output =~ m/Credit: (.*)/;
        $Telegram_Bot->send_text($result . "\n_{HELP}_ /help\n", $chat_id,  {parse_mode => 'HTML'});
      }
      else {
        $Telegram_Bot->send_text("\n_{HELP}_ /help\n", $chat_id);
      }
      return 1;
    }
  });

  return $operation;
}

#**********************************************************
=head2 change_tp_callback()

=cut
#**********************************************************
sub change_tp_callback {
  my ($first_message, $chat_id, $client_type, $client_id) = @_;

  $Users->info($client_id);
  $Internet->user_info($client_id);

  my $disable_chg_tp = 0;
  if ($Users->{GID}) {
    $Users->group_info($Users->{GID});
    $disable_chg_tp = 1 if ($Users->{DISABLE_CHG_TP});
  }

  $disable_chg_tp = 1 unless ($conf{INTERNET_USER_CHG_TP}) ;

  if ($disable_chg_tp) {
    $Telegram_Bot->send_text("_{NOT_ALLOW}_", $chat_id);
  }
  else {
    my $services_list = $Internet->user_list({
      UID       => $client_id,
      ID        => '_SHOW',
      TP_NAME   => '_SHOW',

      COLS_NAME => 1,
      GROUP_BY  => 'internet.id',
    });

    my @service_keyboard = ();
    foreach my $service (@$services_list) {
      my $inline_button = {text => "$service->{id}: $service->{tp_name}", callback_data => "service_id_$service->{id}"};
      push (@service_keyboard, [$inline_button]);
    }
    push (@service_keyboard, [{text => "Отказаться", callback_data => 'cancel123'}]);

    $Shedule->info({
      UID      => $client_id,
      TYPE     => 'tp',
      MODULE   => 'Internet'
    });
    my $shedule_exist = 0;
    my $shedule_message = "";
    if ($Shedule->{TOTAL} > 0) {
      $shedule_exist = 1;
      $shedule_message = "На $Shedule->{Y}-$Shedule->{M}-$Shedule->{D} уже запланировано изменение тарифа.\n";
      $shedule_message .= "\n\n_{HELP}_ /help\n";
    }
    if ($shedule_exist) {
      $Telegram_Bot->send_text($shedule_message, $chat_id);
      return 1;
    }

    my $operation = AXbills::Backend::Plugin::Telegram::Operation->new({
      CHAT_ID    => $chat_id,
      TYPE       => $client_type,
      NAME       => 'TP_CHANGE_OPERATION',
      ON_START   => sub {
        my $message = "Выберите сервис для изменения:\n\n";

        $Telegram_Bot->send_text($message, $chat_id, {
          reply_markup => { 
            inline_keyboard => \@service_keyboard
          }
        });
      },
      ON_MESSAGE => sub {
        my ($self, $msg) = @_;
        $Telegram_Bot->send_text("Message: $msg", $chat_id);
        return 1;
      },
      ON_CALLBACK_QUERY => sub {
        my ($self, $data) = @_;

        if ($data =~ /service_id_/) {
          my ($service) = $data =~ m/service_id_(\d+)/;
          my ($active_tp, $tp_keyboard) = avaiable_tp_for_change($client_id, $service);
          my $message = "_{ACTIVE_TP}_: <b>$active_tp</b>\n\n";
          $message .= "Изменить на:\n";

          $Telegram_Bot->send_text($message, $chat_id, {
            reply_markup => { 
              inline_keyboard => $tp_keyboard
            },
            parse_mode   => 'HTML'
          });
          return 0;
        }
        elsif ($data =~ /change_tp/) {
          my ($service, $tp) = $data =~ m/change_tp_(\d+)_(\d+)/;
          my @inline_keyboard = ();
          push (@inline_keyboard, [{text => "Да", callback_data => "accept_" . $service . "_$tp"}, {text => "Нет", callback_data => 'cancel123'}]);
          my $message = "Сменить тарифный план?\n";

          $Telegram_Bot->send_text($message, $chat_id, {
            reply_markup => { 
              inline_keyboard => \@inline_keyboard
            }
          });
          return 0;
        }
        elsif ($data =~ /accept/) {
          my ($service, $tp) = $data =~ m/accept_(\d+)_(\d+)/;
          my $cmd = "$base_dir/bin/abm_console INTERNET=1 CHANGE_TP=$tp UID=$client_id SERVICE=$service";
          my $output = `$cmd`;
          my ($result) = $output =~ m/Change_tp: (.*)/;

          $result .= "\n\n_{HELP}_ /help\n";
          $Telegram_Bot->send_text($result, $chat_id);
          return 1;
        }
        else {
          $Telegram_Bot->send_text("\n_{HELP}_ /help\n", $chat_id);
        }
        return 1;
      }
    });

    return $operation;
  }
}

#**********************************************************
=head2 info_callback()

=cut
#**********************************************************
sub info_callback {
  my ($first_message, $chat_id, $client_type, $client_id) = @_;

  if ($client_type eq 'AID') {
    $Telegram_Bot->send_text("Sorry, only for users.", $chat_id);
    return 1;
  };

  my $list = $Users->list({
    UID       => $client_id,
    LOGIN     => '_SHOW',
    DEPOSIT   => '_SHOW',
    CREDIT    => '_SHOW',
    FIO       => '_SHOW',
    FIO2      => '_SHOW',
    FIO3      => '_SHOW',
    DISABLE   => '_SHOW',

    COLS_NAME => 1,
  });

  my $services_list = $Internet->user_list({
    UID       => $client_id,
    ID        => '_SHOW',
    TP_NAME   => '_SHOW',
    SPEED     => '_SHOW',
    MONTH_FEE => '_SHOW',
    DAY_FEE   => '_SHOW',

    COLS_NAME => 1,
    GROUP_BY  => (($MODULES[0] eq 'Internet' ) ? 'internet.id' : ''),
  });

  $list->[0]->{fio} .= " $list->[0]->{fio2} $list->[0]->{fio3}" if ($list->[0]->{fio2} && $list->[0]->{fio3});
  my $message = "_{USER}_: <b>" . ($list->[0]->{fio} || $list->[0]->{login} ) . "</b>\n";
  if ($list->[0]->{deposit} < 0) {
    $message .= "_{NEGATIVE_DEPOSIT}_.\n";
  }
  $message .= "_{DEPOSIT}_: <b>" . ($list->[0]->{deposit} || '' ) . "</b>\n\n";

  if ($Internet->{TOTAL}) {
    $message .= "Подключенные сервисы:\n";
    foreach (@$services_list) {
      $message .= "  Тарифный план: <b>$_->{tp_name}</b>\n";
      $message .= "  Скорость: <b>$_->{speed}</b>\n" if ($_->{speed});
      $message .= "  Стоимость за месяц: <b>$_->{month_fee}</b>\n" if ($_->{month_fee});
      $message .= "  Стоимость за день: <b>$_->{day_fee}</b>\n" if ($_->{day_fee});
      $message .= "  Лицевой счет: <b>$client_id</b>\n";
      $message .= "\n";
    }
  }

  $message .= next_payments($client_id) . "\n" if($list->[0]->{deposit} >= 0);
  
  $message .= "\n_{HELP}_ /help\n";

  $Telegram_Bot->send_text($message, $chat_id, {parse_mode => 'HTML'});
}

#**********************************************************
=head2 help_callback()

=cut
#**********************************************************
sub help_callback {
  my ($first_message, $chat_id, $client_type, $client_id) = @_;

  my $message = "_{MENU}_:\n\n";
  $message .= "/help    - _{HELP}_\n\n";
  $message .= "/info    - _{INFO}_\n\n";
  $message .= "/message - Отправить сообщение\n\n";
  $message .= "/credit  - _{CREDIT}_\n\n" if ($conf{user_credit_change});
  $message .= "/tarif   - _{CHANGE_}_ _{TARIF_PLAN}_\n\n" if ($conf{INTERNET_USER_CHG_TP});

  my @inline_keyboard = ();
  my $info_button = {text => "/info"};
  my $msg_button = {text => "/message"};
  push (@inline_keyboard, [$info_button, $msg_button]);
  my $credit_button = {text => "/credit"};
  my $tarif_button = {text => "/tarif"};
  push (@inline_keyboard, [$credit_button, $tarif_button]);

  $Telegram_Bot->send_text($message, $chat_id, {
    # reply_markup => { 
    #   keyboard => \@inline_keyboard,
    #   one_time_keyboard => \1,
    #   resize_keyboard   => \1
    # },
    parse_mode   => 'HTML'
  });
}

#**********************************************************
=head2 avaiable_tp_for_change($service_id)

=cut
#**********************************************************
sub avaiable_tp_for_change {
  my ($uid, $service_id) = @_;

  $Users->info($uid);
  $Internet->user_info($uid, { ID => $service_id });

  my $active_tp = $Internet->{TP_NAME};
  my %skip_tp;
  $skip_tp{$Internet->{TP_ID}} = 1;
  
  if ($conf{INTERNET_SKIP_CHG_TPS}) {
    foreach my $tp_id (split(/,\s?/, $conf{INTERNET_SKIP_CHG_TPS})) {
      $skip_tp{$tp_id} = 1;
    };
  }

  my $tp_list = $Tariffs->list({
    TP_GID          => $Internet->{TP_GID},
    CHANGE_PRICE    => '<=' . ($Users->{DEPOSIT} + $Users->{CREDIT}),
    MODULE          => 'Dv;Internet',
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    CREDIT          => '_SHOW',
    COMMENTS        => '_SHOW',
    TP_CHG_PRIORITY => $Internet->{TP_PRIORITY},
    REDUCTION_FEE   => '_SHOW',
    NEW_MODEL_TP    => 1,
    COLS_NAME       => 1,
    DOMAIN_ID       => $Users->{DOMAIN_ID}
  });

  my @inline_keyboard = ();

  foreach my $tp (@$tp_list) {
    next if ($skip_tp{$tp->{tp_id}});
    my $inline_button = {text => "$tp->{name}", callback_data => "change_tp_" . $service_id . "_$tp->{tp_id}"};
    push (@inline_keyboard, [$inline_button]);
    
  }

  push (@inline_keyboard, [{text => "Отказаться", callback_data => 'cancel123'}]);

  return $active_tp, \@inline_keyboard;
}

1;