#!/usr/bin/perl -w
=head1

 DHCP Log grabber

=cut


use strict;
our(%conf, $DATE, $TIME);

BEGIN {
  use FindBin '$Bin';
  our $libpath = $Bin . '/../';
  my $sql_type = 'mysql';
  unshift( @INC,
    $libpath,
    $libpath . "AXbills/$sql_type/",
    $libpath . 'AXbills/modules/',
    $libpath . 'lib/' );

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if ( !$@ ){
    Time::HiRes->import( qw(gettimeofday) );
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use warnings FATAL => 'all';

use FindBin '$Bin';
require $Bin . '/config.pl';
use AXbills::Base qw(check_time);
use POSIX qw(strftime);
use Admins;
use AXbills::SQL;
use Dhcphosts;

my $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $Dhcphosts = Dhcphosts->new($db, undef, \%conf);

my %DHCP_MESSAGE_TYPES = (
  DHCPDISCOVER          =>  1,
  DHCPOFFER             =>  2,
  DHCPREQUEST           =>  3,
  DHCPDECLINE           =>  4,
  DHCPACK               =>  5,
  DHCPNAK               =>  6,
  DHCPRELEASE           =>  7,
  DHCPINFORM            =>  8,
  DHCPLEASEQUERY        =>  10,
  DHCPLEASEUNASSIGNED   =>  11,
  DHCPLEASEUNKNOWN      =>  12,
  DHCPLEASEACTIVE       =>  13 
 );

my %month_names = (Jan => '01', 
Feb => '02', 
Mar => '03', 
Apr => '04', 
May => '05', 
Jun => '06', 
Jul => '07', 
Aug => '08', 
Sep => '09', 
Oct => '10', 
Nov => '11',	
Dec => '12');

add_logs2db();


#**********************************************************
#
#**********************************************************
sub add_logs2db {
	my $year = strftime "%Y", localtime(time);

  while (my $line=<>) {
    my ($month_name, $month_day, $time, $hostname, undef, $message_type, $log)=split(/\s+/, $line, 7);
    if ($message_type && $DHCP_MESSAGE_TYPES{$message_type}) {
      $Dhcphosts->log_add({
        DATETIME => sprintf("%s-%s-%.02d %s", $year, $month_names{$month_name}, $month_day, $time),
      	HOSTNAME     => "$hostname",
      	MESSAGE_TYPE => $DHCP_MESSAGE_TYPES{$message_type} || 0,
      	MESSAGE      => $log
      });
     }
   }
}

