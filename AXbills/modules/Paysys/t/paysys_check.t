#!/usr/bin/perl -w
=head1 NAME

 Paysys tests

=cut

BEGIN {
  our $libpath = '../../../../';
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "AXbills/$sql_type/",
    $libpath . "AXbills/modules/",
    $libpath . '/lib/');

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use AXbills::Defs;
use AXbills::Base;
use AXbills::Misc;
use Users;

do "../../../../libexec/config.pl";

our $html = AXbills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
  });

do "../lng_$html->{language}.pl";
do "../../../../language/$html->{language}.pl";

my $argv = parse_arguments(\@ARGV);

my $host         = $argv->{HOST} ? $argv->{HOST} : 'https://127.0.0.1:9443/paysys_check.cgi';
my ($billing_ip) = $host =~ /.+\/(\d+.\d+.\d+.\d+):?.+/;
my $filename     = $argv->{FILE} ? $argv->{FILE} : '';
my $curl         = `which curl`;
my $push         = ($argv->{XML} && $argv->{XML} == 1 ) ? 1 : 0;
my $debug        = $argv->{DEBUG} ? $argv->{DEBUG} : 0;

chomp($curl);
if( !(-e $curl) ) {
  print "Please install curl\n";
  exit;
}

my $user_password = '';
if ( $argv->{USER_PASSWD} ) {
  $user_password = "-u $argv->{USER_PASSWD}";
}

if ($#ARGV >= 0) {
  test();
}
else {
  help();
}

#********************************************
#
#********************************************
sub test {

  my $content = '';
  my %requests = ();
  #my %result  = ();

  # if filename set
  if( $filename ne '' ){
    load_module('Paysys', $html);
    my @pay_systems = paysys_settings({ONLY_SYSTEMS => 1});
    my ($system_name) = $filename =~ /(.+).txt/;

    $system_name = ucfirst($system_name);

    if( !(in_array($system_name, \@pay_systems))){
      print "\nERROR:\nSeems your forgot to setting your payment system. Do it before test.\n\n";
      return 0;
    }
    $content = read_file($filename); # read file's content
    if($debug == 1){
      print "\nContent = $content\n";
    }

    %requests = parse_content($content); # parse content from file
    if($push != 1){
      foreach my $request_type (keys %requests){
        $requests{$request_type} .= "PAYSYS_TEST_SYSTEM=$billing_ip:$system_name";
      }
    }

    make_request(%requests);  # make request and print output
  }
  # interactive mode
  else{
    load_module('Paysys', $html);
    my @pay_systems = paysys_settings({ ONLY_SYSTEMS => 1 });

    print "\nChoose system from below and enter number:\n";
    print "\n0.Exit\n";

    if($conf{PAYSYS_WEBMONEY_ACCOUNTS}){
      push @pay_systems, 'Webmoney';
    }

    for (my $i = 0; $i <= $#pay_systems; $i++){
      print $i + 1 . ".$pay_systems[$i]\n";
    }

    print "Enter the system number for test:";
    my $selected_system = '';
    $selected_system = <STDIN>;
    chomp($selected_system);
    # check the right inputs
    while (!($selected_system =~ /^\d+$/) || $selected_system eq '' || $selected_system - 1 > $#pay_systems){

      if( !($selected_system =~ /^\d+$/) ){
        print "This is not numeric!\n";
      }
      elsif( $selected_system eq '' ){
        print "Not right input!\n";
      }
      elsif( $selected_system - 1 > $#pay_systems ){
        print "Not right payment system number!\n";
      }
      print "Enter the system number for test:";
      $selected_system = <STDIN>;
      chomp($selected_system);
    }
    chomp($selected_system);

    if($selected_system == 0){
      return 1;
    }

    $filename = lc($pay_systems[$selected_system - 1]) . ".txt";
    $content = read_file($filename);     # read file content
    %requests = parse_content($content); # parse content from file
    if ($push != 1){
      foreach my $request_type (keys %requests){
        if($pay_systems[$selected_system - 1] ne 'Webmoney'){
          $requests{$request_type} .= "PAYSYS_TEST_SYSTEM=$billing_ip:$pay_systems[$selected_system - 1]";
        }
      }
    }
    make_request(%requests);  # make request and print output
    $filename = '';
    test();
  }
}

#**********************************************************
=head2 parse_content() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub parse_content {
  my ($content) = @_;
  #my ($attr) = @_;

  my @rows = split(/\r\n/, $content);
  my %requests;
  my $request_type;

  if ($push == 1) {
    foreach my $line (@rows){
      if ($line =~ m/^=====/){
        ($request_type) = $line =~ /==== (.+) =====/;
        next;
      }
      $requests{$request_type} .= $line;
    }
  }
  else {
    foreach my $line (@rows) {
      if($line =~ m/^=====/){
        ($request_type) = $line =~ /==== (.+) =====/;
        next;
      }
      my ($key, $val) = split(/ -> /, $line);
      $val = '' if (! defined($val));
      $val =~ s/\+/\%2B/g;
      $val =~ s/\=/\%3D/;
      $requests{$request_type} .= "$key=$val&";
    }
  }

  if($debug == 1){
    _bp("Requests", \%requests, {TO_CONSOLE=>1});
  }

  return %requests;
}

#**********************************************************
=head2 make_request() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub make_request {
  my (%requests) = @_;
  #my ($attr) = @_;

  my $debuging = '';
  $debuging = '-#' if ($debug == 0);

  foreach my $request_type (keys %requests){
    my $cmd = "$curl $debuging -k $user_password -N $host/ -d \"$requests{$request_type}\" ";

    if($debug == 1){
      print "\nCommand = $cmd\n";
    }

    my $res = `$cmd`;

  print "
\n############## R E S U L T  FOR $request_type #################\n
$res
############################################\n\n\n";

  }

  return 1;
}

#**********************************************************
=head2 read_file() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub read_file {
  #my ($attr) = @_;
  my $file_content;

  open(my $fh, '<', $filename);
    while(<$fh>) {
      $file_content .= $_;
    }
  close($fh);

  return $file_content;
}


#***************************************************
#
#***************************************************
sub help  {

print << "[END]";
**************************************************************************************
*                       paysys_check.cgi testing program
*
*  Command for test running:
*
*        perl paysys_test.pl HOST=[billing_url] FILE=[filename] XML=[xml] DEBUG=[debug]
*
*  Test parameters:
*
*    [billing_url] - your billing url(necessarily field!)
*
*        EXAMPLE: HOST=http://192.168.0.112:9443/paysys_check.cgi
*
*    [filename]    - file for payment sysmte test(if absent - interactive mode)
*
*        EXAMPLE: FILE=fondy.txt
*
*    [xml]         - if payment system works with xml data
*
*        EXAMPLE: XML=1
*
*    [debug]       - output debug info
*
*        EXAMPLE: DEBUG=1
*
**************************************************************************************
[END]

}


