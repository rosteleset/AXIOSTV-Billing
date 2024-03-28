#!/usr/bin/perl

use strict;
use warnings;
use JSON;
use Encode qw/encode_utf8 decode_utf8/;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
  %lang
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../../libexec/config.pl';

  $conf{TELEGRAM_LANG} = 'russian' unless($conf{TELEGRAM_LANG});

  do $Bin . "/../../language/$conf{TELEGRAM_LANG}.pl";
  do $Bin . "/../../AXbills/modules/Telegram/lng_$conf{TELEGRAM_LANG}.pl";
  do $Bin . "/../../AXbills/modules/Msgs/lng_$conf{TELEGRAM_LANG}.pl";
  do $Bin . "/../../AXbills/modules/Paysys/lng_$conf{TELEGRAM_LANG}.pl";

  unshift(@INC,
    $Bin . '/../../',
    $Bin . '/../../lib/',
    $Bin . '/../../AXbills',
    $Bin . '/../../AXbills/mysql',
    $Bin . '/../../AXbills/modules',
    $Bin . '/../../AXbills/modules/Telegram',
  );

}

use AXbills::Base qw/_bp/;
use AXbills::SQL;
use Admins;
use Users;
use Contacts;
use API::Botapi;
use db::Telegram;
use Buttons;
use Tauth;
use AXbills::Misc;
use Msgs;
use AXbills::Sender::Core;

our $db = AXbills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : 3, {
  IP    => $ENV{REMOTE_ADDR},
  SHORT => 1
});
our $Bot_db = Telegram->new($db, $admin, \%conf);
our $Users = Users->new($db, $admin, \%conf);
our $Contacts = Contacts->new($db, $admin, \%conf);

use Crm::Dialogue;
my $Dialogue = Crm::Dialogue->new($db, $admin, \%conf, { SOURCE => 'telegram' });

use AXbills::Misc;
use AXbills::Templates;

my $message = ();
my $fn_data = "";
my $debug   = 0;
our $Bot = ();

print "Content-type:text/html\n\n";
$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/ if ($ENV{'REQUEST_METHOD'});
if (!$ENV{'REQUEST_METHOD'}) {
  $message->{text} = join(' ', @ARGV);
  $message->{chat}{id} = 403536999;
  $debug = 1;
  $Bot = Botapi->new($conf{TELEGRAM_TOKEN}, 403536999, 'curl');
}
elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
  my $buffer = '';
  read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
  `echo '$buffer' >> /tmp/telegram.log`;
  my $hash = decode_json($buffer);

  exit 0 unless ($hash && ref($hash) eq 'HASH' && ($hash->{message} || $hash->{callback_query}));
  if ($hash->{callback_query}) {
    $message = $hash->{callback_query}->{message};
    $fn_data = $hash->{callback_query}->{data};
  }
  else {
    $message = $hash->{message};
  }

  my $bot_addr = "https://" . ($ENV{SERVER_NAME} || $ENV{SERVER_ADDR}) . ":$ENV{SERVER_PORT}";
  $Bot = Botapi->new($conf{TELEGRAM_TOKEN}, $message->{chat}{id}, ($conf{FILE_CURL} || 'curl'), $bot_addr);
}
else {
  my ($command) = $ENV{'QUERY_STRING'} =~ m/command=([^&]*)/;
  $command //= '';
  $command =~ tr/+/ /;
  $command =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
  $message->{text} = decode_utf8($command);
  $message->{chat}{id} = 'test_id';
  ($fn_data) = $ENV{'QUERY_STRING'} =~ m/fn_data=([^&]*)/;
  $fn_data =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
  $fn_data =~ decode_utf8($fn_data);
  require API::Webtest;
  $Bot = Webtest->new();
}

$Bot->{lang} = \%lang;
my %buttons_list = %{buttons_list({ bot => $Bot, bot_db => $Bot_db })};
my %commands_list = reverse %buttons_list;

message_process();
exit 1;

#**********************************************************
=head2 message_process()

=cut
#**********************************************************
sub message_process {
  my $aid = get_aid($message->{chat}{id});

  if ($aid) {
    my $admin_info = $admin->info($aid);
    if($admin_info->{DISABLE} != 0){
      $Bot->send_message({ text => $lang{YOU_FRIED} });
      exit 1;
    }
    admin_fast_replace($message, $fn_data);
    return 1;
  }

  my $uid = get_uid($message->{chat}{id});
  if (!$uid) {
    my $message_text = encode_utf8($message->{text}) || '';

    my $lead_id = $Dialogue->crm_get_lead_id_by_chat_id($message->{chat}{id});
    if ($lead_id) {
      $Dialogue->crm_send_message($message->{text}, { LEAD_ID => $lead_id });
      exit 1;
    }

    if ($message->{text} && $message->{text} =~ m/^\/start/) {
      subscribe($message);
      main_menu();
      exit 1;
    }

    if ($message_text eq $lang{INVITE_A_FRIEND}) {
      if ($commands_list{$message_text} && $fn_data) {
        my @fn_argv = split('&', $fn_data);
        telegram_button_fn({
          button => $fn_argv[0],
          fn     => $fn_argv[1],
          text   => $message_text,
          argv   => \@fn_argv,
          user   => $message->{chat} || {},
          bot    => $Bot,
          bot_db => $Bot_db,
        });
      }
      exit 1;
    }
    elsif ($message->{contact}) {
      if ($message->{contact}{user_id} eq $message->{chat}{id}) {
        subscribe_phone($message);
        main_menu();
      }
    }
    else {
      subscribe_info();
    }
    return 1;
  }

  $Bot->{uid} = $uid;
  my $text = $message->{text} ? encode_utf8($message->{text}) : "";

  my $info = $Bot_db->info($uid);
  if ($Bot_db->{TOTAL} > 0 && $info->{button} && $info->{fn}) {
    #Игнорирование нажатия старых инлайн-кнопок.
    return 1 if ($fn_data);

    my $ret = telegram_button_fn({
      button    => $info->{button},
      fn        => $info->{fn},
      step_info => $info,
      uid       => $uid,
      bot       => $Bot,
      bot_db    => $Bot_db,
      message   => $message,
    });

    main_menu() if(!$ret);
    return 1;
  }
  elsif($fn_data) {
    my @fn_argv = split('&', $fn_data);

    telegram_button_fn({
      button => $fn_argv[0],
      fn     => $fn_argv[1],
      argv   => \@fn_argv,
      uid    => $uid,
      bot    => $Bot,
      bot_db => $Bot_db,
      text   => $message->{text} || $message->{caption},
      photo  => $message->{photo}[0]{file_id},
    });
  }
  elsif ($commands_list{$text}) {
    telegram_button_fn({
      button => $commands_list{$text},
      fn     => 'click',
      bot    => $Bot,
      bot_db => $Bot_db,
    });
  }
  elsif (length($message->{text}) >= 20 || $message->{photo}[0]{file_id}) {
    my @fn_argv = split('&', $fn_data);
    telegram_button_fn({
      button => $fn_argv[0],
      fn     => $fn_argv[1],
      text   => $message->{text} || $message->{caption},
      photo  => $message->{photo}[0]{file_id},
      uid    => $uid,
      bot    => $Bot,
      bot_db => $Bot_db,
    });
  }
  else {
    main_menu();
  }
  return 1;
}

#**********************************************************
=head2 main_menu()

=cut
#**********************************************************
sub main_menu {
  my ($attr) = @_;
  my @line = ();
  my $i = 0;
  my $text = $lang{USE_BUTTON};

  foreach my $button (sort keys %commands_list) {
    push (@{$line[$i%4]}, { text => $button });
    $i++;
  }

  my $keyboard = [$line[0] || [], $line[1] || [], $line[2] || [], $line[3] || []];

  $Bot->send_message({
    text         => $text,
    reply_markup => {
      keyboard        => $keyboard,
      resize_keyboard => 'true',
    },
  });

  return 1;
}

#**********************************************************
=head2 admin_fast_replace()

=cut
#**********************************************************
sub admin_fast_replace {
  my ($msgs, $callback_data) = @_;

  my ($packed, $func_name, $msgs_id) = split(/\:/, $callback_data);

  my @msgs_text = [];
  if($msgs->{text} || $msgs->{caption}) {
    $msgs->{text} = $msgs->{caption} if ($msgs->{caption});
    @msgs_text = $msgs->{text} =~ /(MSGS_ID=[0-9]+)(\s|\n)*(.*)/gs;
  }

  unless (($msgs_text[0]) || ($msgs->{photo} || $msgs->{document})) {

    $Bot->send_message({ text => $lang{SEND_ERROR} });

    return 1;
  }

  my $Msgs = Msgs->new($db, $admin, \%conf);
  my $aid = get_aid($msgs->{chat}{id});

  if(!ref $msgs_text[0]) {
    $msgs_text[0] =~ s/MSGS_ID=//g;

    $Msgs->message_reply_add({
      ID         => $msgs_text[0],
      REPLY_TEXT => $msgs_text[2] || '',
      AID        => $aid,
    });

    $Bot_db->del_admin($aid);

    $Bot_db->add({
      AID  => $aid,
      ARGS => '{"message":{"id":"' . $Msgs->{INSERT_ID} . '", "msg_id":"' . $msgs_text[0] . '"}}',
    });

    $Msgs->message_change({
      ID    => $msgs_text[0],
      STATE => 6,
    });
  }

  my $info =$Bot_db->info_admin($aid);

  if($Bot_db->{TOTAL} > 0 && (defined $msgs->{caption} || !$#msgs_text)) {
    my $msg_hash = decode_json($info->{args});

    $Bot->send_message({ text => $lang{SEND_ERROR}, }) if !$msg_hash->{message}{id};

    my $message_id = $msg_hash->{message}->{id};
    my $original =  $msg_hash->{message}->{msg_id};

    my $file_id;

    if ($msgs->{photo}) {
      my $photo = pop @{$msgs->{photo}};
      $file_id = $photo->{file_id};
    }
    else {
      $file_id = $msgs->{document}->{file_id};
    }

    my $Attachments = Msgs::Misc::Attachments->new($db, $admin, \%conf);
    my ($file_path, $file_size, $file_content) = $Bot->get_file($file_id);
    my ($file_name, $file_extension) = $file_path =~ m/.*\/(.*)\.(.*)/;

    $Bot->send_message({
      text         => "$lang{SEND_ERROR}",
    }) unless ($file_content && $file_size && $file_name && $file_extension);

    my $file_content_type = file_content_type($file_extension);

    delete($Attachments->{save_to_disk});


    $Attachments->attachment_add({
      REPLY_ID     => $message_id,
      FILENAME     => "$file_name.$file_extension",
      CONTENT_TYPE => $file_content_type,
      FILESIZE     => $file_size,
      CONTENT      => $file_content,
      MESSAGE_TYPE => 1,
    });

    $Bot->send_message({
      text => "$lang{ADD_FILE} ($file_name.$file_extension) MSG_ID=$original",
    });
    return 1 if(ref $msgs_text[0]);
  }

  unless (_error_show($Msgs)) {
    $Bot->send_message({
      text         => "$lang{SEND_SUCCESS}",
    });

    use AXbills::HTML;
    use Msgs::Notify;

    my $html = AXbills::HTML->new({
      CONF     => \%conf,
      NO_PRINT => 0,
      PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
      CHARSET  => $conf{default_charset},
    });

    load_module('Msgs', { language => $conf{TELEGRAM_LANG} });

    my $Notify = Msgs::Notify->new($db, $admin, \%conf, { LANG => \%lang, HTML => $html });
    $Notify->notify_user({
      REPLY_ID  => $Msgs->{INSERT_ID},
      MSG_ID    => $msgs_text[0],
      MESSAGE   => $msgs_text[2] || '',
      FIND_USER => 1,
    });

  }

  return 1;
}

#**********************************************************
=head2 file_content_type()

=cut
#**********************************************************
sub file_content_type {
  my ($file_extension) = @_;

  my $file_content_type = "application/octet-stream";

  if ( $file_extension && $file_extension eq 'png'
    || $file_extension eq 'jpg'
    || $file_extension eq 'gif'
    || $file_extension eq 'jpeg'
    || $file_extension eq 'tiff'
  ) {
    $file_content_type = "image/$file_extension";
  }
  elsif ( $file_extension && $file_extension eq "zip" ) {
    $file_content_type = "application/x-zip-compressed";
  }

  return $file_content_type;
}

#**********************************************************
=head2 get_gid_conf($param, $git)

=cut
#**********************************************************
sub get_gid_conf{
  my $param = shift;
  my $gid = shift;

  use Conf;
  my $Conf = Conf->new($db, $admin, \%conf);

  my $conf_info = $Conf->config_info({PARAM => "LIKE'%1'"});
  $conf_info = $conf_info->{conf};

  return $conf_info->{$param."_$gid"} ?  $conf_info->{$param."_$gid"} : $conf_info->{"$param"};
}

1;
