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
  do $Bin . "/../../AXbills/modules/Equipment/lng_$conf{TELEGRAM_LANG}.pl";

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

our $db = AXbills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/}, { CHARSET => $conf{dbcharset} });
our $admin = Admins->new($db, \%conf);

our $Bot_db = Telegram->new($db, $admin, { %conf,
  TELEGRAM_BOT_NAME => $conf{TELEGRAM_ADMIN_BOT_NAME},
  TELEGRAM_TOKEN    => $conf{TELEGRAM_ADMIN_TOKEN},
});

my %SEARCH_KEYS = (
  '\/[E|e]quipment\s*([^\n\r]+)$' => 'Admin_equipment&search',
  '\/msgs\s*([^\n\r]+)$'          => 'Admin_msgs&search'
);

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
  $Bot = Botapi->new($conf{TELEGRAM_ADMIN_TOKEN}, 403536999, 'curl');
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
  $Bot = Botapi->new($conf{TELEGRAM_ADMIN_TOKEN}, $message->{chat}{id}, ($conf{FILE_CURL} || 'curl'), $bot_addr);
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
my %buttons_list = %{buttons_list({ bot => $Bot, bot_db => $Bot_db, for_admins => 1 })};
my %commands_list = reverse %buttons_list;

message_process();

exit 1;

#**********************************************************
=head2 message_process()

=cut
#**********************************************************
sub message_process {

  my $aid = get_aid('e_' . $message->{chat}{id});
  if ($message->{text} && $message->{text} =~ m/^\/start/ && !$aid) {
    subscribe($message);
    main_menu();
    exit 1;
  }

  return if !$aid;

  my $admin_info = $admin->info($aid);
  if ($admin_info->{DISABLE} != 0) {
    $Bot->send_message({ text => $lang{YOU_FRIED} });
    exit 1;
  }

  my $text = $message->{text} ? encode_utf8($message->{text}) : "";

  _check_search_commands();

  if($fn_data) {
    my @fn_argv = split('&', $fn_data);

    telegram_button_fn({
      button     => $fn_argv[0],
      fn         => $fn_argv[1],
      argv       => \@fn_argv,
      bot        => $Bot,
      bot_db     => $Bot_db,
      text       => $message->{text} || $message->{caption},
      message_id => $message->{message_id}
    });
    return 1;
  }
  elsif ($commands_list{$text}) {
    telegram_button_fn({
      button => $commands_list{$text},
      fn     => 'click',
      bot    => $Bot,
      bot_db => $Bot_db,
    });
    return;
  }

  main_menu();

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
      resize_keyboard => "true",
    },
  });

  return 1;
}

#**********************************************************
=head2 _check_search_commands()

=cut
#**********************************************************
sub _check_search_commands {

  foreach my $key (keys %SEARCH_KEYS) {
    if ($message->{text} =~ $key) {
      $fn_data = $SEARCH_KEYS{$key} . "&$1";
      return;
    }
  }
}

1;
