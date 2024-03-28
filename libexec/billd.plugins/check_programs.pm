=head1 NAME

  billd plugin

=head2  DESCRIBE

 Check run programs and run if they shutdown

=cut
#**********************************************************


our (
  $debug,
  %conf,
  $Admin,
  $db,
  $OS,
  $argv,
  $base_dir
);

use strict;
use warnings;
use AXbills::Base qw(startup_files cmd);

use Events::API;
my Events::API $Events_api = Events::API->new($db, $Admin, \%conf);

check_programs();


#**********************************************************
=head2 check_programs()

=cut
#**********************************************************
sub check_programs {
  print "Check run programs\n" if ($debug > 1);

  if (! $argv->{PROGRAMS}) {
    print "Select programs: PROGRAMS=...\n";
    return 0;
  }

  my @programs = split(/;/, $argv->{PROGRAMS});

  my %START_PROGRAM = (
    RESTART_RADIUSD     => '/usr/local/etc/rc.d/radiusd start',
    RESTART_IPCAD       => '/usr/local/bin/ipcad -d',
    RESTART_FLOWCAPTURE => '/usr/local/etc/rc.d/flow-capture start',
    RESTART_WEBSOCKET   => $base_dir . 'libexec/websocket_backend.pl start',
    %{ startup_files() }
  );

  foreach my $line (@programs) {
    my ($name, $start_cmd) = split(/:/, $line, 2);
    if ($debug > 1) {
      print "Program: $name, Start cmd: ". ($start_cmd || q{--}) ."\n";
    }

    my @ps;
    if ($name eq 'websocket') {
      @ps = split m|$/|, qx/ps ax | grep $name | grep -v grep/;
    }
    else {
      @ps = split m|$/|, qx/ps axc | grep $name/;
    }
    
    if ($debug > 1) {
      print join("\n", @ps)."\n";
    }

    if ($#ps < 0) {
      if (! $start_cmd && $START_PROGRAM{'RESTART_'.uc($name)}) {
        $start_cmd=$START_PROGRAM{'RESTART_'.uc($name)};
      }
      elsif ($name eq 'radiusd' && ! $start_cmd) {
        if ($OS eq 'freebsd') {
          $start_cmd="/usr/local/etc/rc.d/radiusd start";
        }
      }

      my $cmd_result = cmd($start_cmd, { SHOW_RESULT => 1 });
      
      $Events_api->add_event({
        TITLE       => "_{PROCESSES}_ : $name",
        COMMENTS    => '_{PROCESS_RESTARTED_MESSAGE}_',
        MODULE      => 'SYSTEM',
        PRIORITY_ID => 5,
      });
      
      print "$name Program not running: $cmd_result\n";
    }
  }

  return 1;
}


1
