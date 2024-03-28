=head1 NAME
  billd plugin clear_db

  DESCRIBE: Clearing the database of errors and residual information
=cut
#**********************************************************

use warnings FATAL => 'all';
use strict;
use DBI;

our (
  %conf,
  $argv,
  $debug
);

do '/usr/axbills/libexec/config.pl';
my $dsn = "DBI:mysql:database=$conf{dbname}:host=$conf{dbhost}";
my $user = $conf{dbuser};
my $password = $conf{dbpasswd};
my @tables = ("abon_user_list",
              "admin_actions",
#              "bills",
              "cams_main",
              "cams_streams",
              "cards_bruteforce",
              "cards_dillers",
              "cards_users",
              "companie_admins",
              "crm_leads",
              "docs_acts",
              "docs_invoices",
              "docs_main",
              "docs_receipts",
              "docs_tax_invoices",
              "fees",
              "hotspot_advert_shows",
              "hotspot_logins",
              "info_change_comments",
              "internet_log",
              "internet_log_intervals",
              "internet_log_intervals_old",
              "internet_main",
              "internet_online",
              "ipn_log",
              "ipn_log_backup",
              "ipn_traf_detail",
              "iptv_calls",
              "iptv_devices",
              "iptv_main",
              "iptv_users_channels",
              "msgs_chat",
              "msgs_delivery_users",
              "msgs_messages",
              "msgs_reply",
              "msgs_survey_answers",
#              "msgs_unreg_requests",
              "payments",
              "payments_spool",
              "paysys_easypay_report",
              "paysys_global_money_report",
       	      "triplay_users",
	      "ureports_main",
              "users_phone_pin",
              "users",
              "users_social_info",
              "viber_tmp",
              "web_users_sessions"
              );
			  
if ($argv->{CLEAR_MAX} || $argv->{CLEAR_MAX} eq 'ALL') {
	clear_db_biil_id0();
	clear_db_uuid_NULL();
} else {
	clear_db_biil_id0();
}

#**********************************************************
=head2 clear_db_biil_id0();

=cut
#**********************************************************
sub clear_db_biil_id0 {

my $dbh = DBI->connect($dsn, $user, $password) or die "Unable to connect to database: $DBI::errstr";

print "<<< Result clear_db_biil_id0 >>>\n";

foreach my $table (@tables) {
	my $quoted_table = $dbh->quote_identifier($table);
	my $sth = $dbh->prepare("SHOW TABLES LIKE ?");
	$sth->execute($table);
	my $table_exists = $sth->fetchrow_array;
		if ($table_exists) {
	my $sql_arr = "DELETE FROM `$table` WHERE uid = '0'";
	$sql_arr = "DELETE FROM `$table` WHERE uid = '0'";
	my $sth = $dbh->prepare($sql_arr) or die "Failed to prepare request: $DBI::errstr";
	$sth->execute() or die "Failed to execute the request: $DBI::errstr";

	my $rows_count = $sth->rows;
		print "$table clear rows: $rows_count \n";
		} else {
	warn "Table $table not exist in database! \n";
	next;
	}
}

print "\n";

$dbh->disconnect();

return 1;

}

#**********************************************************
=head2 clear_db_uuid_NULL();

=cut
#**********************************************************

sub clear_db_uuid_NULL {

my $dbh = DBI->connect($dsn, $user, $password) or die "Unable to connect to database: $DBI::errstr";

print "<<< Result clear_db_uuid_NULL >>>\n" ;

foreach my $table (@tables) {
	my $quoted_table = $dbh->quote_identifier($table);
	my $sth = $dbh->prepare("SHOW TABLES LIKE ?");
	$sth->execute($table);
	my $table_exists = $sth->fetchrow_array;
		if ($table_exists) {
	my $sql_arr = "DELETE FROM `$table` WHERE uid = '0'";
	$sql_arr = "DELETE FROM `$table` WHERE uid = '0'";
	my $sth = $dbh->prepare($sql_arr) or die "Failed to prepare request: $DBI::errstr";
	$sth->execute() or die "Failed to execute the request: $DBI::errstr";

	my $rows_count = $sth->rows;
		print "$table clear rows: $rows_count \n";
		} else {
	warn "Table $table not exist in database! \n";
	next;
	}
}

print "\n";

$dbh->disconnect();

return 1;

}

1;
