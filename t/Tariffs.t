#!/usr/bin/perl

=head1 NAME

  Tariffs Test

    DEBUG
    TP_PATH

=cut

BEGIN {
  our $libpath = '../';
  eval { do "$libpath/libexec/config.pl" };
  our %conf;

  if(!%conf){
    print "Content-Type: text/plain\n\n";
    print "Error: Can't load config file 'config.pl'\n";
    print "Create ABillS config file /usr/axbills/libexec/config.pl\n";
    exit;
  }

  my $sql_type = $conf{dbtype} || 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/",
    $libpath . '/lib/',
    $libpath,
    $libpath . 'AXbills/',
    $libpath . 'AXbills/mysql/',
    $libpath . 'AXbills/modules/'
  );

  eval { require Time::HiRes; };
  our $begin_time;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}


use strict;
use warnings FATAL => 'all';
use Users;
use Admins;
use AXbills::SQL;
use AXbills::Base qw( parse_arguments );
use AXbills::HTML;

our(
  %conf
);

require '/usr/axbills/libexec/config.pl';
require '/usr/axbills/language/english.pl';

our $db    = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { %conf, CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
our $admin = Admins->new($db, \%conf);
our $Conf  = Conf->new($db, $admin, \%conf);
our $html  = AXbills::HTML->new(
  {
    CONF     => \%conf,
    NO_PRINT => 0,
    PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
    CHARSET  => $conf{default_charset},
    COLORS   => $conf{DEFAULT_ADMIN_WEBCOLORS},
    %{ ($admin->{SETTINGS}) ? $admin->{SETTINGS} : {} }
  }
);

my $argv = parse_arguments(\@ARGV);

require AXbills::Misc;

my %test = (
  ACCOUNT_ACTIVATE => '0000-00-00',
  EXPIRE     => '0000-00-00',
  DEPOSIT    => 0,
  CREDIT     => 0,
  REDUCTION  => 0,
  UID        => 1,
  TP_ID      => 1,
  OLD_STATUS => 0, #Old user status
  STATUS     => 0, #user status
  TP_INFO => {
    ID                 => 1,
    NAME               => 'Test TP',
    TP_ID              => 1,
    MONTH_FEE          => 10,
    DAY_FEE            => 0,
    POSTPAID_MONTH_FEE => 1,
    ABON_DISTRIBUTION  => 0,
    PERIOD_ALIGNMENT   => 0,
    ACTIV_PRICE        => 0,
    FEES_METHOD        => 0,
  },
  TP_INFO_OLD  => {

  },
);

if($argv->{FILENAME}) {
  get_tps($argv);
}

$test{db} = $db;

service_get_month_fee(\%test, {
  DEBUG => $argv->{DEBUG} || 6,
  DATE  => '2017-02-03'
});


#********************************************************
=head2 get_tps($attr) - Get tps

  Arguments:
    $attr

=cut
#********************************************************
sub get_tps {
  my ($attr) = @_;

  my $content  = '';
  my $filename = $attr->{FILENAME};

  if(open(my $fh, '<', $filename)) {
    while(<$fh>) {
      $content .= $_;
    }
    close($fh);
  }
  else {
    print "filename: $filename $!\n";
  }

  my @rows = split(/\r?\n/, $content);
  my $category = 0;
  foreach my $line (@rows) {
    if($line =~ /^===([A-Z\_]+)/) {
      $category = $1;
      next;
    }
    my($key, $val)=split(/\s{0,100}\=\s{0,100}/, $line);
    if($key) {
      $key =~ s/^\s+//g;
      $key =~ s/\s+$//g;
      $val =~ s/^\s+//g;
      $val =~ s/\s+$//g;

      if($category) {
        $test{$category}{$key} = $val;
      }
      else {
        $test{$key} = $val;
      }
    }
  }

  return 1;
}


1;
