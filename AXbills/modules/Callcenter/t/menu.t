
use strict;
use warnings FATAL => 'all';
use FindBin '$Bin';

use Benchmark qw/:all/;

BEGIN {
  my $libpath = $Bin . '/../../../../';
  my $sql_type = 'mysql';

  unshift(@INC, $libpath . "AXbills/$sql_type/",
    $libpath . '/lib/',
    $libpath,
    $libpath . 'AXbills/',
    $libpath . 'AXbills/mysql/',
    $libpath . 'AXbills/modules/'
  );
}

our %conf;
use AXbills::SQL;
use Admins;
use Callcenter;
use Callcenter::Menu;
require 'libexec/config.pl';

our $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

my $Admin = Admins->new($db, \%conf);
$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

require $Bin . "/../../Callcenter/Ivr.pm";
Ivr->import();

my $Ivr = Callcenter::Ivr->new($db, $Admin, \%conf, {
  language => 'russian'
});

my $debug=0;
if ($debug > 6) {
  $Ivr->{debug}=1;
}


if ($#ARGV > -1 && $ARGV[0] eq 'message') {
  use Asterisk::AGI;
  my $AGI = Asterisk::AGI->new();
  $Ivr->{AGI}=$AGI;
  $Ivr->message("TEXT");
  exit;
}

my $test_main_menu = $Ivr->get_menu();

#show_hash($main_menu, { DELIMITER => "\n", SPACE_SHIFT => 1 });
show_menu($test_main_menu, 0, 0, []);

#timethis(100000, sub{ acct => show_menu2($main_menu, 0, 0, \@last_array); });
menu($test_main_menu);

print "\n===END===\n";


#**********************************************************
=head2 show_menu($main_menu_, $parent, $level, $last_array) - Show menu

  Arguments:
    $main_menu_
    $parent
    $level
    $last_array

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub show_menu {
  my ($main_menu, $parent, $level, $last_array) = @_;

  if (defined($main_menu->{$parent})) {
    $level++;
    my $prefix .= "";
    for(my $i=0; $i<=$#{ $last_array }+1; $i++) {
      $prefix .= "  ";
    }

    while (my ($k, $val) = each %{ $main_menu->{$parent} }) {
      $val = $main_menu->{$parent}{$k};
      print "$prefix $k -> $val\n";

      if (defined($main_menu->{$k})) {
        $level++;
        $prefix .= '  ';
        push @$last_array, $parent;
        $parent = $k;
      }
      #delete($main_menu->{$parent}{$k});
    }

    if ($#{ $last_array } > -1) {
      $parent = pop @$last_array;
      $level--;

      if ($level > 0) {
        $prefix = substr($prefix, 0, $level * 1 * 2);
      }

      show_menu($main_menu, $parent, $level, $last_array);
    }

    #delete($main_menu->{0}{$parent});
  }

  return 1;
}


1;