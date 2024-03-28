#!/usr/bin/perl

=head1 NAME

  Test base syntax and execute functions

=cut


use strict;
use warnings;
use FindBin '$Bin';

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
   unshift(@INC, $libpath . 'AXbills/');
  unshift(@INC, $libpath . 'AXbills/modules/');
  eval { require Time::HiRes; };
  our $global_begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $global_begin_time = Time::HiRes::gettimeofday();
  }
}

our (
  $Bin,
  %conf,
  @MODULES,
  %functions,
  %module,
  %FORM,
  $users,
  $global_begin_time,
  $admin
);

open( my $HOLE, '>', '/dev/null' );

use Test::Simple tests => 390;

require $Bin ."/../libexec/config.pl";

$ENV{DEBUG}=1;
#Detalisation lavel
# 5 - check true return
# 4 - speed and queries
# 3 - show function name
# 2 - show inputs %FORM
# 1 - show function end and warnings
# 0 - Only show function status
my $detail = 2;
my $brutal_check = 0;

$ENV{'REQUEST_METHOD'} = "GET";
$ENV{'REMOTE_ADDR'} = "127.0.0.2";
if ($ARGV[0] && $ARGV[0] eq 'ui'){
  #client interface
  $ENV{'QUERY_STRING'}="user=test&passwd=123456";
  eval { require "../cgi-bin/index.cgi" };
}
else {
  if ($ARGV[0] && $ARGV[0] eq 'brutal') {
    $brutal_check=1;
  }
  #admin interface
  my $admin_login    = 'axbills';
  my $admin_password = 'axbills';
  if(-f '.test') {
    my $file_info = '';
    if (open(my $fh, '<', ".test")) {
      $file_info = <$fh>;
      close($fh)
    }
    chomp($file_info);
    ($admin_login, $admin_password) = split(/:/, $file_info);
  }
  $ENV{'QUERY_STRING'} = "user=$admin_login&passwd=$admin_password";
  #disable_output( 1 );
  eval { do "../cgi-bin/admin/index.cgi" };
  #enable_otput();
}

if ($@) {
  print "Error index:";
  print $@;
}

#Add modules
#foreach my $m (@MODULES) {
#  print "$m \n";
#  ok( require "AXbills/modules/$m/webinterface" );
#}

our $libpath='../';

my $function_count = scalar keys %functions;
print "function test: $function_count\n";

#test speed of execution
my %speed_test   = ();
my %queries_error= ();
my %queries_test = ();
my $query        = 0;
my %fn_status    = ();

foreach my $fn_id (sort keys %functions) {
  my $function_name = $functions{$fn_id};

  print "$fn_id : $function_name : User: ". ($users || 'N/D')." Admin: $admin Q: $admin->{db}->{queries_count}\n";
  disable_output( 1 );
  enable_otput();

  if ($module{$fn_id}) {
    load_module( $module{$fn_id} );
  }

  next if ($detail == 3);

  #show inputs
  if ($detail > 1) {
    foreach my $key (sort keys %FORM) {
      print "  '$key' -> ". ((defined($FORM{$key})) ? "'$FORM{$key}'" : 'undef') ."\n";
    }
  }

  #Check admin obj exists
  if (! $admin ) {
    print "No admin.\n";
    exit;
  }

  #Speed test start
  our $begin_time = Time::HiRes::gettimeofday;

  delete($admin->{errstr});
  delete($admin->{sql_errstr});

  my @operation = ('');

  if($brutal_check) {
    @operation = ('add', 'chg', 'change', 'del', 'set');
  }

  disable_output( 3 );
  my $ret;
  foreach my $action_key (@operation) {
    if ($action_key) {
      for(my $i=0; $i<=$#operation; $i++) {
        delete($FORM{$operation[$i]});
      }

      $FORM{$action_key}=1;
    }
    $ret = ok( _function($fn_id) );
  }

  enable_otput();

  #Speed_test stop
  if ($begin_time > 0) {
    my $end_time = Time::HiRes::gettimeofday;
    my $gen_time = $end_time - $begin_time;
    $speed_test{$function_name}=$gen_time;
  }

  #query counts
  $queries_test{$function_name} = ($admin->{db}->{queries_count} || 0 ) - ($query || 0);

  if ($admin->{db}->{db}->err) {
    $queries_error{$function_name} = ($admin->{db}->{db}->err) . '  ' . ($admin->{db}->{db}->errstr);
  }
  else {
 #   $queries_error{$function_name} = '';
  }

  $query = $admin->{db}->{queries_count} || 0;

  $fn_status{$function_name}=$ret;

  if($detail == 5 && ! $ret ) {
    print "Error: $function_name\n";
    exit;
  }
}

#Result
print "Functions: $function_count Queries: ". (($admin->{db}->{queries_count}) ? $admin->{db}->{queries_count} : '') ."\n";

my $global_time = 0;
if ($global_begin_time > 0) {
  my $end_time = Time::HiRes::gettimeofday;
  $global_time = $end_time - $global_begin_time;
}


&show_speed_report(\%speed_test);


#************************************************
=head2 show_speed_report()

=cut
#************************************************
sub show_speed_report  {
  my ($speed_hash_ref)=@_;

  printf("%25s | %.5s| %12s | %6s |\n", 'function', 'Time', 'Queries', 'Status');
  print "---------------------------------------------------------\n";

  foreach my $fn ( sort { $speed_hash_ref->{$a} <=> $speed_hash_ref->{$b} } keys %$speed_hash_ref ) {
    my $time_ = $speed_hash_ref->{$fn} || 0;
    $query = $queries_test{$fn} || 0;
    my $query_error = $queries_error{$fn} || '';
    printf("%25s | %.5f| %12d|%6s|%10s\n", $fn, $time_, $query, (($fn_status{$fn}) ? 'ok' : ''), $query_error);
  }

  print "Total: --------------------------------------------------\n";
  printf("%25s| %.5f| %12s|%6s\n",
     $function_count, $global_time, $admin->{db}->{queries_count} || 0, '' );

  my @q_errors = sort keys %queries_error;
  if ($#q_errors > -1){
    print "Queries error:$#q_errors\n";

    foreach my $q ( sort keys %queries_error ){
      print "\n====> $q:\n";
      print $queries_error{$q};
    }
    print "\n";
  }

  show_all_vars();
  #show_isa();

  return 1;
}

#************************************************
=head2 show_all_vars() - Show global vars

=cut
#************************************************
sub show_all_vars {
  print "\nGlobal Vars: ";

  eval { require Devel::Size; };
  my $top = ($ARGV[0] && ($ARGV[0] ne 'ui' || $ARGV[0] ne 'brutal')) ? $ARGV[0] : 0;

  if ($@){
    print "Install perl module Devel::Size \n";
    return 0;
  }
  else {
    Devel::Size->import( qw/size total_size/ );
  }

  my %info_ = ();
  foreach my $ps ( keys %:: ) {
    #next if ($ps eq 'ps' || $ps eq 'info');
    #$info = sprintf("%30s: %d\n", $ps, total_size( $::{ $ps } ));
    my $size = total_size( $ps );
    if ($size) {
      $info_{$ps}=$size;
    }
  }

  my $i          = 0;
  my $info       = '';
  my $total_size = 0;
  my $report_limit = 10;
  foreach my $ps ( sort { $info_{$b} <=> $info_{$a} } keys %info_) {
    my $size = size($ps);
    $total_size += $size;
    if ($top){
      $info .= sprintf( " %30s: %d / %d\n", $ps, $info_{$ps}, size( $ps ) );
      if ( $top =~ /\d+/ && $i > $top ){
        last;
      }
    }
    $i++;
    if ($report_limit < $i) {
      last;
    }
  }

  print $info;
  print "Count: $i Size: $total_size\n";

  return 1;
}

#************************************************
=head2 show_isa() - Show @ISA

=cut
#************************************************
sub show_isa {

  our @ISA;

  print "================== ISA:\n";
  foreach my $value (sort @ISA) {
    print $value ."\n";
  }

}

#**********************************************************
=head2 disable_output($level) - redirect STDOUT to /dev/null

  Arguments:
    $level - threshold of $detail for disabling

=cut
#**********************************************************
sub disable_output{
  my ($level) = @_;

  select $HOLE if ($level <= $detail);

  return 1;
}

#**********************************************************
=head2 enable_otput() - restore STDOUT

=cut
#**********************************************************
sub enable_otput{
  select STDOUT;

  return 1;
}

1;
