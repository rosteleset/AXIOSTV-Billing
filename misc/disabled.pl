#!/usr/bin/perl

#*****************************************************************************

=pod 
  Parameters:
    User UID;

  Return:
    IS the user blocked or not
=cut
#*****************************************************************************

use strict;
use warnings;
use DBI;

BEGIN {
  our %conf;
  use FindBin '$Bin';
  require $Bin . '/../libexec/config.pl';
}

our %conf;
my $uid = $ARGV[0] || '';
#my %enabled = ();

my $host   = $conf{dbhost};
my $db     = $conf{dbname};
my $dbtype = 'mysql';
my $dbuser = $conf{dbuser};
my $dbpw   = $conf{dbpasswd};

my $dbh     = DBI->connect("DBI:$dbtype:$db:$host", $dbuser, $dbpw);
my $query   = "SELECT dv.disable,
    IF(company.id IS NULL, b.deposit, b.deposit) + IF(u.credit > 0, u.credit, tp.credit)
    FROM dv_main dv
    INNER JOIN users u ON(u.uid=dv.uid)
    INNER JOIN tarif_plans tp ON(tp.id=dv.tp_id)
    LEFT JOIN bills b ON (u.bill_id = b.id)
    LEFT JOIN companies company ON  (u.company_id=company.id)
    LEFT JOIN bills cb ON  (company.bill_id=cb.id)
    WHERE u.uid = '$uid'
    GROUP BY u.uid
    LIMIT 1;";

my @row_ary = $dbh->selectrow_array($query);

if (@row_ary) {
  if ($row_ary[0] > 0 || $row_ary[1] <= 0 ) {
    #print $uid. ":Доступ в Интернет ограничен. Воспользуйтесь <a href='/index.cgi?index=10'>кредитом </a>\n";
    print "1:Доступ в Интернет ограничен. Воспользуйтесь кредитом";
  }

  #elsif ($row_ary[0] eq 0) {
  #  print $uid.":enabled\n";
  #}
}
else {
  die "No user with this UID $uid\n";
}
