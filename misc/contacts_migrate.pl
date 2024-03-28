#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';


our ($libpath, %conf, $base_dir, @MODULES, %lang, %FORM);

BEGIN {
  use FindBin '$Bin';

  # Assuming we are in '/usr/axbills/misc/'
  $libpath = $Bin . '/../';

  unshift( @INC,
    $libpath,
    $libpath . "AXbills/mysql/",
    $libpath . 'AXbills/',
    $libpath . 'lib/'
  );
}

do 'libexec/config.pl';
$base_dir //= $libpath;

use AXbills::Defs;
use AXbills::Base qw/_bp parse_arguments in_array/;
use AXbills::SQL;
use Admins;

require AXbills::Misc;

my $db = AXbills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => $conf{dbcharset} });

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

our $html = AXbills::HTML->new({ CONF => \%conf, NO_PRINT => 1, });

my $argv = parse_arguments(\@ARGV);
my $debug = 0;
if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
  _bp(undef, undef, { SET_ARGS => { TO_CONSOLE => 1 } });
}

do 'language/english.pl';

contact_migrate();
exit 0;

#**********************************************************
=head2 main()

=cut
#**********************************************************
sub contact_migrate {
  require Users;
  Users->import();

  my $Users = Users->new($db, $admin, \%conf);

  # First should save old contacts
  if (!$argv->{SKIP_BACKUP}) {
    return unless save_old_contacts();
  }

  if($debug>5) {
    $Users->{debug}=1;
  }
  my $migrate_contacts = $Users->contacts_migrate({ IGNORE_DUPLICATE => $argv->{IGNORE_DUPLICATE} }) && !$Users->{errno};

  if ($migrate_contacts) {
    print "Contacts migrated successfully \n";
    print "You should now enable \$conf{CONTACTS_NEW} \n";
  }
  else {
    print "\nSomething was wrong during migrate, so we've to rollback operation \n";
    print "No need to worry, operation was canceled, your contacts are in the same state as before migrate \n";
    print "Maybe you have duplicates (same phone/email for different users). You can use IGNORE_DUPLICATE=1 option. \n";
  }

  return 1;
}

#**********************************************************
=head2 save_old_contacts()

  Arguments:
     -
    
  Returns:
  
=cut
#**********************************************************
sub save_old_contacts {

  use Control::System qw/form_sql_backup/;
  my $backup_result = form_sql_backup({
    mk_backup => 1,
    TABLES    => 'users_pi',
    EXTERNAL  => 1
  });

  if ($backup_result && ref $backup_result) {
    print "\n$backup_result->{result}\n\n";
  }
  else {
    return 0;
  }

  return 1;
}



