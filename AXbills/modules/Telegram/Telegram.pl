#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use lib '../';
use FindBin '$Bin';
use JSON;
use File::Find;

BEGIN {
  our $libpath = $Bin . '/../../../';

  require $libpath . 'libexec/config.pl';
  our %conf;
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'AXbills/');
  unshift(@INC, $libpath . 'AXbills/modules/');
}

use AXbills::Defs;
use AXbills::Base qw(parse_arguments);
use Admins;
use Users;
use Conf;
use AXbills::Fetcher;

my $TELEGRAM_API_URL = 'https://api.telegram.org';

my $ARGS = parse_arguments(\@ARGV);

my $db = AXbills::SQL->connect(
  $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  }
);
our $admin = Admins->new($db, \%conf);
# Just init Tokens from Config
my $Conf = Conf->new($db, $admin, \%conf);

_start();
sub _start {
  if ($ARGS->{help}) {
    help();
  } else {
    integration();
  }
}


#*******************************************************************
=head2 integration() - Start bot integration

=cut
#*******************************************************************
sub integration {
  my $token = $conf{TELEGRAM_TOKEN};
  my $billing_url = $conf{BILLING_URL};
  my $cert_path = $conf{TELEGRAM_CERT_PATH};

  if (!$token) {
    print "There is no Telegram token. Fill \$conf{TELEGRAM_TOKEN} and try again.\n";
    return;
  }

  if (!$billing_url) {
    print "There is no billing url. Fill \$conf{BILLING_URL} and try again.\n";
    return;
  }

  if ($billing_url =~ /http:\/\// || $billing_url =~ /:9443/) {
    print << "[END]";
    Your \$conf{BILLING_URL} is not valid for Telegram.
    Change it due to requirements and change web server config.

    Requirements:
    - https
    - port 443 or 8443
[END]
    return;
  }

  my $bot_api_base = "$TELEGRAM_API_URL/bot$token";

  my $bot_info = web_request("$bot_api_base/getMe", { CURL => 1, JSON_RETURN => 1 });
  if (!$bot_info || $bot_info->{error_code}) {
    print "Bot is not exist.\nRecheck your \$conf{TELEGRAM_TOKEN} and try again.\n";
    return;
  }

  my $webhook_info = web_request("$bot_api_base/getWebhookInfo", { CURL => 1, JSON_RETURN => 1 });

  if (!$webhook_info || $webhook_info->{error_code}) {
    print "Error with webhook request, try again.\n";
    return;
  }

  if ($webhook_info->{result}->{url}) {
    # when webhook url already exist
  }

  my $cutted_token = substr($token, 0, 10);
  my $executable_path = $Bin . '/telegram_bot.cgi';
  my $base_dir = $main::base_dir || '/usr/axbills/';
  my $generated_folder = "Telegram$cutted_token";
  my $generated_append = "$generated_folder/telegram_bot.cgi";

  my $folder_path = $base_dir . '/cgi-bin/' . $generated_folder;
  my $symlink_end = $base_dir . '/cgi-bin/' . $generated_append;

  my $create_folder_and_symlink = sub {
    my $folder_res = mkdir($folder_path);

    if ($folder_res) {
      my $ret = `ln -s $executable_path $symlink_end`;
      `chmod +x $symlink_end`;
      # No output = success
      return !$ret;
    }

    return 0;
  };

  if (-f $symlink_end) {
    # print in debug that symlink exist
  }
  elsif (!$create_folder_and_symlink->()) {
    print << "[END]";
ERROR Cannot create folder and symlink.

Create it manually with commands:
  mkdir $folder_path
  ln -s $executable_path $symlink_end
  chmod +x $symlink_end

And start this script again.
[END]
    return;
  }
  else {
    print 'Folder and symlink successfully created.';
  }

  my $generated_url = $billing_url . '/' . $generated_append;

  my $endpoint_result = web_request($generated_url, { MORE_INFO => 1, CURL => 1, INSECURE => 1 });

  if (!($endpoint_result->{http_code} && $endpoint_result->{http_code} == 200)) {
    print "Telegram endpoint is not working!\n\nTry command:\nchmod +x $symlink_end\n";
    return;
  }

  my $cert = '';
  if ($cert_path && -f $cert_path && open(my $fh, '<', $cert_path)) {
    while(<$fh>) {
      $cert .= $_;
    }
    close($fh);
  };

  my $subscribe_result = web_request("$bot_api_base/setWebhook",
    {
      CURL => 1,
      REQUEST_PARAMS => {
        url  => $generated_url,
        cert => $cert,
      },
      JSON_RETURN => 1
    }
  );

  if (!($subscribe_result && $subscribe_result->{ok})) {
    print "Telegram subscribe failed! Try again or later.\n";
    return;
  }

  my $fresh_webhook_info = web_request("$bot_api_base/getWebhookInfo",
    {
      CURL => 1,
      JSON_RETURN => 1
    }
  );

  if ($fresh_webhook_info && $fresh_webhook_info->{result}->{last_error_message}) {
    print "ERROR I have error from Telegram:\n" . $fresh_webhook_info->{result}->{last_error_message} . "\n";
    if ($fresh_webhook_info->{result}->{last_error_message} =~ /SSL/) {
      print "That means, Telegram recognized your SSL is not good.\n";
      if ($cert_path) {
        print "Regenerate your self-signed certificate with right ip and domain.\n";
      } else {
        print << "[END]";
  You need to have a signed certificate like Let's Encrypt
    OR
  You can use \$conf{TELEGRAM_CERT_PATH} option - fill path of your public pem self-signed certificate.
[END]
      }
      print "And try again.\n"
    }
  }

  _load_telegram_db();

  print << "[END]";
  Congratulations!
  ABillS Telegram bot successfully subscribed.

[END]
  print "Do you want configure Telegram modules?\n";
  print "Apply? (y/N): ";
  chomp(my $ok = <STDIN>);

  if (lc($ok) eq 'y') {
    _configure_telegram_modules();
  }

  # Fill config variables
  $Conf->config_add({ PARAM => 'TELEGRAM_BOT_NAME', VALUE => $bot_info->{result}->{username}, REPLACE => 1 });
  $Conf->config_add({ PARAM => 'TELEGRAM_WEBHOOK_URL', VALUE => $generated_url, REPLACE => 1 });
}

#*******************************************************************
=head2 _configure_telegram_modules() - modules configuration

=cut
#*******************************************************************
sub _configure_telegram_modules {
  my $buttons_available_folder = $Bin . '/buttons-avaiable';
  my $buttons_enabled_folder = $Bin . '/buttons-enabled';
  if (!-d $buttons_enabled_folder && !mkdir($buttons_enabled_folder)) {
    print "ERROR Folder $buttons_enabled_folder not created.\nCreate it manually and try again.\n";
    return;
  }

  my @AVAILABLE_MODULES = ();
  my @ENABLED_MODULES = ();

  my $process_modules = sub {
    my $LINK = shift;
    my $function = sub {
      my $name = $File::Find::name;
      if (-d $name) {
        return 1;
      }
      if ($_ && $_ ne '.') {
        push(@$LINK, $_);
      }
    };
    return $function;
  };
  find($process_modules->(\@AVAILABLE_MODULES), $buttons_available_folder);
  find($process_modules->(\@ENABLED_MODULES), $buttons_enabled_folder);

  my $i = 0;
  my $n = scalar(@AVAILABLE_MODULES);
  for my $available_module (sort @AVAILABLE_MODULES) {
    $i++;
    if (grep { $_ eq $available_module } @ENABLED_MODULES) {
      print "($i/$n) Module $available_module already enabled.\n";
      next;
    };
    print "($i/$n) Enable $available_module? (y/N)\n";
    chomp(my $ok = <STDIN>);
    if (lc($ok) eq 'y') {
      `ln -s $buttons_available_folder/$available_module $buttons_enabled_folder/$available_module`;
    }
  }
}

#*******************************************************************
=head2 _load_telegram_db() - load Telegram.sql

=cut
#*******************************************************************
sub _load_telegram_db {
  my $content = '';
  if (open(my $fh, '<', $Bin . '/Telegram.sql')) {
    while (<$fh>) {
      $content .= $_;
    }
    close($fh);
  };

  eval { $admin->query($content, 'do', {}) };
}
#*******************************************************************
=head2 help() - Help

=cut
#*******************************************************************
sub help {

  print << "[END]";
ABillS Telegram bot setup in one click

  Required config params:
    \$conf{TELEGRAM_TOKEN}
    \$conf{BILLING_URL}

  Params:
    help - show this message

[END]
}