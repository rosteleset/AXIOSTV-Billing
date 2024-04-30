#!/usr/bin/perl
=head1 NAME

  ABillS Telegram deamon

=cut

use strict;
use warnings;

BEGIN {
  die "
    Deprecated. use websocket_backend.pl
    http://billing.axiostv.ru/wiki/doku.php/axbills:docs:manual:websocket_backend
  ";
  
  use FindBin '$Bin';

  our $libpath =  $Bin . '/../../';
  
  our $sql_type = 'mysql';
  unshift( @INC,
    $libpath ,
    $libpath . "AXbills/$sql_type/",
    $libpath . "AXbills/modules/",
    $libpath . 'lib/' );

  our $begin_time = 0;
  eval { require Time::HiRes; };
  if ( !$@ ){
    Time::HiRes->import( qw(gettimeofday) );
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use AXbills::Defs;
do $libpath . "libexec/config.pl";

use AXbills::Base;
use AXbills::Misc;
use AXbills::Server;
use AXbills::SQL;
my $sql  = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
 { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

my $db   = $sql->{db};

use AXbills::Sender::Telegram;
use Admins;
use Log;

my $Telegram = AXbills::Sender::Telegram->new(\%conf);
my $Admin    = Admins->new($db, \%conf);
my $Log      = Log->new(undef, \%conf, {LOG_FILE => "/usr/axbills/var/log/telegram.log", DEBUG_LEVEL => 1});

#our %ENV;

my $argv = parse_arguments(\@ARGV);

my $prog_name = "Telegram server";

# демонизация и ведение лога
if (defined($argv->{'-d'})) {
  daemonize();
  # ведение лога
  $Log->log_print('LOG_INFO', '', "$prog_name Daemonize...", );
}
#Стоп процесса
elsif (defined($argv->{stop})) {
  stop_server();
  $Log->log_print('LOG_INFO', '', "$prog_name Stoped...",);
  exit;
}
elsif (defined($argv->{restart})) {
  if(make_pid() == 1){
    stop_server();
  }
  print "Process started.\n";
  daemonize();

  $Log->log_print('LOG_INFO', '', "$prog_name Restarted...", );
}
#проверка не запущен ли уже
elsif (make_pid() == 1) {
  exit;
}

my $result = $Telegram->get_updates()->{result};
my $updateid = 0;

while (1) {

  if ( scalar $Telegram->get_updates()->{result} == 0 ) { sleep 1; next; }

  my $message = 'Got the message';

  for (my $i = 0; $i < scalar @$result; $i++){

    # _bp('msg', $result->[$i], {TO_CONSOLE => 1});

    my $user_chatid = $result->[$i]{message}{from}{id};  # get chat id of message

    my $admin_info = $Admin->info(undef, {TELEGRAM_ID => $user_chatid}); # check if chat id linked to admin
    
    # parse commands and send message to 
    if($result->[$i]{message}{entities}[0]{type} &&  $result->[$i]{message}{entities}[0]{type} eq 'bot_command'){
      my $command = $result->[$i]{message}{text};

      # print "Admin  \n$admin_info->{A_FIO} - $command\n";

      if($command eq '/help'){
        $message = "Это тестовый бот для ABillS\n";
        $message .= "Он поддерживает следующие команды\n";
        $message .= "*/hello* - Приветствие бота\n";
      }
      elsif ($command eq '/start'){
        if(!$Admin->{errno} && $admin_info->{A_FIO}){
          $message = "Добро пожаловать снова, $admin_info->{A_FIO}";
        }
        else{
          $message = "Вас приветствует Бот. Хотите подписаться на важные уведомления?\n";
          $message .= "Для этого нужно перейти по следующей ссылке [привязать аккаунт]($conf{TELEGRAM_SERVER_ADDRESS}/admin/index.cgi?index=50&REGISTER_TELEGRAM=1&telegram_id=$user_chatid)";
        }
      }
    }

    # send message to chat id
    my $answer = $Telegram->send_message({ TO_ADDRESS => $user_chatid, 
                                           MESSAGE    => $message, 
                                           PARSE_MODE => 'markdown',});
    print "answer - $answer";
    $updateid = $result->[$i]->{update_id};
  }

  # get new msgs from users to bot
  $result = $Telegram->get_updates( { OFFSET => $updateid + 1 } )->{result};
  next;
}

1