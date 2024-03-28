# mkdir /usr/axbills/var/sorm/abonents/
# mkdir /usr/axbills/var/sorm/payments/
# mkdir /usr/axbills/var/sorm/wi-fi/
# mkdir /usr/axbills/var/sorm/dictionaries/
# echo "2018-01-01 00:00:01" > /usr/axbills/var/sorm/last_admin_action
# echo "2018-01-01 00:00:01" > /usr/axbills/var/sorm/last_payments
#
# $conf{BILLD_PLUGINS} = 'sorm';
# $conf{ISP_ID} = '1'; # идентифакатор ИСП из "информация по операторам связи и их филалах"'
#
# iconv -f UTF-8 -t CP1251 abonents.csv.utf > abonents.csv
=head1 NAME

  SORM sync

=head1 VERSION

  VERSION: 0.19
  DATETIME: 20210616

  API_VERSION: КОМПЛЕКС «ЯХОНТ», «ФЕНИКС»
  API_VERSION: НИКА.466533.034.ТР.011.DMZ

=head1 ARGUMENTS

  INIT -  Init dirs
  START - START
  DICTIONARIES
  WIFI
  SHOW_ERRORS - Get errors
  REPORT - Add only one report
  TYPE=[Fenix(default)]


=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  unshift(@INC, '/usr/axbills/AXbills/modules/Sorm');
}


use Net::FTP;

our (
  %conf,
  $db,
  $users,
  $var_dir,
  $base_dir,
  $argv,
  @MODULES,
);

our Admins $Admin;

my $server_ip = $conf{SORM_SERVER} || '127.0.0.1';
my $login     = $conf{SORM_LOGIN}  || 'login';
my $pswd      = $conf{SORM_PASSWORD}   || 'password';

my $debug     = 0;

if($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
}


my $type = "Fenix";

$type = $argv->{TYPE} if($argv->{TYPE});

if (eval {
  require "$base_dir/AXbills/mysql/Sorm/$type.pm";
  1;
}) {
  $type = "Sorm::".$type;
  $type->new(\%conf, $db, $Admin, $argv);
}
else {
  print $@;
}

#**********************************************************
=head2 _ftp_upload($file, $attr) - Init base parameters

  Arguments:
    $attr
      FILE
      DIR
      ICONV - base_file:distination_file

  Retuens:
    TRUE FALSE

=cut
#**********************************************************
sub _ftp_upload {
  my ($attr) = @_;

  if($attr->{ICONV}) {
    my $cmd = "iconv -f UTF-8 -t CP1251 $attr->{ICONV}";
    if($debug > 2) {
      print " $cmd\n";
    }
    system($cmd);
  }

  if($debug > 1) {
    print "Connect: SERVER: $server_ip LOGIN: $login PASSWORD: $pswd\n";
  }

  my $file = $attr->{FILE} || q{};
  print "Send $file\n"; #if ($debug > 2);

  my $ftp = Net::FTP->new($server_ip, Debug => 0, Passive => $conf{FTP_PASSIVE_MODE} || 0) or die "Cannot connect to $server_ip: $@";
    $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
    if($attr->{DIR}) {
      $ftp->cwd($attr->{DIR}) or die "Cannot change working directory ", $ftp->message;
    }
    $ftp->put($file) or die "$file put failed ", $ftp->message;
    print $ftp->message;# if ($debug > 2);
  $ftp->quit;

  return 1;
}

#**********************************************************
=head2 _date_format($attr)

=cut
#**********************************************************
sub _date_format {
  my ($date) = @_;

  $date =~ s/(\d{4})-(\d{2})-(\d{2})(.*)/$3.$2.$1$4/;

  return $date;
}

1
