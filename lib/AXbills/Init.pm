package AXbills::Init;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Init

=head2 SYNOPSIS

  This package contains boilerplate code to use in scripts to load %config init $db and $admin objects

=head2 USAGE

 Of course to init this you need to know libraries location, so you can use this code to load
 
 BEGIN {
    our $Bin;
    use FindBin '$Bin';
    if ( $Bin =~ m/\/axbills(\/)/ ){
      my $libpath = substr($Bin, 0, $-[1]);
      unshift (@INC, "$libpath/lib");
    }
    else {
      die " Should be inside /usr/axbills dir \n";
    }
  }
  
  use AXbills::Init qw/$db $admin %conf/;
 
=cut

our $libpath;
BEGIN {
  our $Bin;
  use FindBin '$Bin';

  $libpath = $Bin . '/../'; #assuming we are in /usr/axbills/whatever
  if ( $Bin =~ m/\/axbills(\/)/ ) {
    $libpath = substr($Bin, 0, $-[1]);
  }
  
  die "No \$libpath \n" if ( !$libpath );
  
  unshift(@INC,
    "$libpath",
    "$libpath/AXbills",
    "$libpath/lib",
    "$libpath/AXbills/modules",
    "$libpath/AXbills/mysql"
  );
}

use parent 'Exporter';

our $VERSION = 0.01;

our ($admin, $db, $users);

our @EXPORT = qw(
  $db $admin %conf $base_dir $DATE $TIME $users @MODULES $var_dir
  );
our @EXPORT_OK = qw($db $admin %conf);


# Declare vars we should read from config.pl
our (
  %conf,
  @MODULES,
  $DATE, $TIME,
  $base_dir,
  $lang_path,
  $lib_path,
  $var_dir,
  $curtime,
  $year,
);
eval {
  do "$libpath/libexec/config.pl";
};
if ( $@ ) {
  print "Content-Type: text/html\n\n";
  print "Can't load config file 'config.pl' <br>";
  print "Check ABillS config file /usr/axbills/libexec/config.pl";
  die;
}

use Admins;
use Users;
require AXbills::SQL;

# TODO: implement sub import, analyze what we have to import and init only needed objects

$db = AXbills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'}, {
    CHARSET => $conf{dbcharset}
  });
$admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

use Conf;
Conf->new($db, $admin, \%conf);


$users = Users->new($db, $admin, \%conf);

1;