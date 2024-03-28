#!/usr/bin/perl
=head1 NAME

  websocket_backend.pl

=head2 VERSION

  VERSION: 1.10

=head1 SYNOPSIS

  This is main controlling script for running axbills related daemons
  
  http://axbills.net.ua/wiki/doku.php/axbills:docs:manual:websocket_backend
  
=head1 OPTIONS

  start
  stop
  restart
  status
  debug
  help

  LOG_FILE
  PLUGIN  - run only given plugins
  
=cut

use strict;
use warnings;
use utf8;

our (%conf, $base_dir, $debug, $ARGS, @MODULES, $db);

$debug ||= 3;

our $libpath;
BEGIN {
  our $Bin;
  use FindBin '$Bin';

  $libpath = $Bin . '/../'; # (default) assuming we are in /usr/axbills/libexec/
  if ($Bin =~ m/\/axbills(\/)/) {
    $libpath = substr($Bin, 0, $-[1]);
  }

  unshift @INC, $libpath . '/lib';
  unshift @INC, $libpath . '/AXbills/modules';
  unshift @INC, $libpath . '/AXbills/mysql';
}

# Localizing global variables
use AXbills::Backend::Defs;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::Impl::Perl;

use AXbills::Base qw/_bp/;
use AXbills::Server qw/make_pid daemonize stop_server is_running/;

use AXbills::Backend::Plugin::BaseAPI;
use AXbills::Backend::Plugin::BasePlugin;

# Setting up Log
use AXbills::Backend::Log;

if ($ARGS->{debug}) {
  $debug = $ARGS->{debug};
}

my $log_level = $conf{WEBSOCKET_DEBUG} || $debug;
my $log_file = $ARGS->{LOG_FILE}
  || $conf{WEBSOCKET_DEBUG_FILE}
  || ($base_dir || '/usr/axbills/') . '/var/log/websocket.log';

our $Log = AXbills::Backend::Log->new('FILE', $log_level, 'Main', {
  FILE => $log_file
});

_bp(undef, undef, { SET_ARGS => { TO_CONSOLE => 1 } });

# Daemon controls block
{
  my %daemon_args = (
    LOG_DIR      => $base_dir . '/var/log/',
    PROGRAM_NAME => 'websocket_backend'
  );

  my $start = sub {
    my $pid_file = daemonize(\%daemon_args);
    $Log->info("Started... $pid_file", 'Daemon');
    $pid_file;
  };

  my $stop = sub {
    stop_server(undef, \%daemon_args);
    $Log->info('Normal exit', 'Daemon');
  };

  #Starting
  if (defined($ARGS->{'-d'}) || defined($ARGS->{'start'})) {
    $start->();
  }
  # Stoppping
  elsif (defined($ARGS->{stop})) {
    $stop->();
    exit;
  }
  elsif (defined($ARGS->{restart})) {
    $Log->info('Restarting', 'Daemon');

    $stop->();
    my $pid_file = $start->();

    $Log->info("Restarted $pid_file", 'Daemon');
  }
  elsif (defined($ARGS->{status})) {
    my $running = is_running(\%daemon_args);
    print (($running) ?  'Not running' : 'Running');
    exit (($running) ? 0 : 1);
  }
  elsif (defined($ARGS->{help})) {
    help();
    exit 1;
  }
  # Checking if already running
  elsif (is_running(\%daemon_args)) {
    exit 1;
  }

  $SIG{INT} = sub {
    $stop->();
    $Log->info("Stop on signal INT", 'Daemon');
    print "Interrupted\n";
    exit 0;
  };
}

# This should be global so plugins live in event loop
my %LOADED_PLUGINS = ();

# Allow to start only one plugin
if ($ARGS->{PLUGIN}) {
  foreach my $plugin (split(',', $ARGS->{PLUGIN})) {
    start_plugin($plugin);
  };
}
else {
  # Load plugins that have been enabled in config
  start_plugin('Websocket') if (!$conf{WEBSOCKET_DISABLED});
  start_plugin('Internal') if (!$conf{WEBSOCKET_INTERNAL_DISABLED});

  if ($conf{TELEGRAM_TOKEN}) {
    start_plugin('Telegram');
  }

  if ($conf{SATELLITE_MODE}) {
    start_plugin('Satellite');
  }

  if ($conf{EVENTS_ASTERISK}) {
    start_plugin('Asterisk');
  }
}

$Log->info('Waiting for events');

AnyEvent::Impl::Perl::loop;
exit 0;

#**********************************************************
=head2 start_plugin($plugin_name, $attr)

  Arguments:
    $plugin_name, $attr -
    
  Returns:
  
=cut
#**********************************************************
sub start_plugin {
  my ($plugin_name) = @_;

  my $package_name = 'AXbills::Backend::Plugin::' . $plugin_name;
  my $file_name = 'AXbills/Backend/Plugin/' . $plugin_name . '.pm';

  eval { require $file_name };

  if($@) {
    $Log->alert("Csn't load plugin: $plugin_name ($@)", 'Daemon');
    return 0;
  }

  $package_name->import();

  eval {
    my AXbills::Backend::Plugin::BasePlugin $plugin_object = $package_name->new(\%conf);
    $LOADED_PLUGINS{$plugin_name} = $plugin_object;

    my AXbills::Backend::Plugin::BaseAPI $plugin_api = $plugin_object->init();
    register_global(uc($plugin_name) . '_API', $plugin_api);
  };

  if ($@) {
    $Log->alert("Failed to load $plugin_name : $@");
    return 0;
  }

  $Log->notice("Loaded $plugin_name");
  return 1;
}


#**********************************************************
=head2 help()

  Arguments:

  Returns:

=cut
#**********************************************************
sub help {

  print << "[END]";
  websocket_backend.pl start

Arguments:
  start
  stop
  restart
  status
  help

  debug=1..5 - Debug level (Default: 3)
  -d         - Demonize
  LOG_FILE
  PLUGIN     - run only given plugins


[END]

}

1;