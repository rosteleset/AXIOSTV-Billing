=head1 NAME
  billd plugin custom_bonus

  DESCRIBE: User bonuses not provided by the original billing system
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

if ($conf{CUSTOM_BONUS_DISC}) {
	add_discount();
	dell_discount();
}

#**********************************************************
=head2 add_discount();

  DESCRIBE: Set a discount depending on the period of use of services without debt
 
=cut
#**********************************************************

sub add_discount {

my $reduction = 0;
my $new_reduction = 0;
my $tp_ids = $conf{CUSTOM_BONUS_DISC_TP_ID} || 0;
my $interval_pay_months = $conf{CUSTOM_BONUS_DISC_PAY_INTERVAL} || 12;
my $min_reduction = $conf{CUSTOM_BONUS_DISC_MIN_DISCOUNT} || 1;
my $max_reduction = $conf{CUSTOM_BONUS_DISC_MAX_DISCOUNT} || 50;
my $fees_check = $conf{CUSTOM_BONUS_DISC_FEES} || 100;

my $dbh = DBI->connect($dsn, $user, $password) or die "Unable to connect to database: $DBI::errstr";

print "<<< Clients for add discounts >>>\n";

my $sql_arr = "SELECT fs.uid, DATEDIFF(NOW(), MIN(fs.date)) AS days_since_first_deposit, COUNT(last_deposit) AS count_fees
           FROM fees fs
           JOIN internet_main im ON fs.uid = im.uid
           JOIN tarif_plans tp ON im.tp_id = tp.tp_id AND tp.id IN ($tp_ids)
           JOIN users us ON fs.uid = us.uid AND us.reduction = $reduction
           WHERE fs.uid IN (
               SELECT fs2.uid
               FROM fees fs2
               WHERE fs2.date >= DATE_SUB(NOW(), INTERVAL $interval_pay_months MONTH)
               GROUP BY fs2.uid
               HAVING SUM(CASE WHEN fs2.last_deposit < 0 THEN 1 ELSE 0 END) = 0
           )
           GROUP BY fs.uid";
		   
my $sth_arr = $dbh->prepare($sql_arr) or die "Failed to prepare request: $DBI::errstr";
$sth_arr->execute() or die "Failed to execute the request: $DBI::errstr";

foreach my $row (@{$sth_arr->fetchall_arrayref({})}) {
	
    my $uid = $row->{'uid'};
    my $days = $row->{'days_since_first_deposit'} + 1;
	my $interval = $row->{'interval_pay_months'};
	my $count_fees = $row->{'count_fees'};
	
	if ($conf{CUSTOM_BONUS_DISC_CHECK}) {
		if ((($count_fees / $days) * 100) < $fees_check) {
			next;
			}
		}
	
	if (! $conf{CUSTOM_BONUS_DISC_MULTIPLY}) {
		$new_reduction = int($days / 365);
    if ($new_reduction > $max_reduction) {
        $new_reduction = $max_reduction;
		}
	} else {
		$new_reduction = $min_reduction * int($days / 365);
    if ($new_reduction > $max_reduction) {
        $new_reduction = $max_reduction;
		}
	}
	
	print "USER: $uid, ACTIVE_DAYS: $days, COUNT_FEES: $count_fees, REDUCTION: $new_reduction%\n";

     my $update_sql = "UPDATE users us SET us.reduction = $new_reduction WHERE us.uid = $uid";
     $dbh->do($update_sql) or die "Failed to execute the request: $DBI::errstr";	
}

$dbh->disconnect();

return 1;

}

#**********************************************************
=head2 dell_discount();

DESCRIBE: Remove a discount depending on the period of use of services without debt

=cut
#**********************************************************

sub dell_discount {
    
    my $tp_ids = $conf{CUSTOM_BONUS_DISC_TP_ID} || 0;
	my $interval_pay_months = $conf{CUSTOM_BONUS_DISC_PAY_INTERVAL} || 12;
    my $min_reduction = $conf{CUSTOM_BONUS_DISC_MIN_DISCOUNT} || 1;
    my $max_reduction = $conf{CUSTOM_BONUS_DISC_MAX_DISCOUNT} || 50;
    
    my $dbh = DBI->connect($dsn, $user, $password) or die "Unable to connect to database: $DBI::errstr";
    
    my $sql_arr = "SELECT fs.uid FROM fees fs
						JOIN internet_main im ON fs.uid = im.uid
						JOIN tarif_plans tp ON im.tp_id = tp.tp_id AND tp.id IN ($tp_ids)
						JOIN users us2 ON fs.uid = us2.uid
						WHERE us2.reduction BETWEEN $min_reduction AND $max_reduction AND fs.date >= DATE_SUB(NOW(), INTERVAL $interval_pay_months MONTH) AND fs.last_deposit < 0 
						GROUP BY fs.uid";
    
    my $sth_arr = $dbh->prepare($sql_arr) or die "Failed to prepare request: $DBI::errstr";
    $sth_arr->execute() or die "Failed to execute the request: $DBI::errstr";
    
foreach my $row (@{$sth_arr->fetchall_arrayref({})}) {
        my $uid = $row->{'uid'};
        my $update_sql = "UPDATE users us SET us.reduction = $min_reduction WHERE us.uid = $uid";
		
        my $sth_update = $dbh->prepare($update_sql) or die "Failed to prepare request: $DBI::errstr";
        $sth_update->execute() or die "Failed to execute the request: $DBI::errstr";
        $sth_update->finish;
    }
    
    $dbh->disconnect();
    
    return 1;
    
}

if ($conf{CUSTOM_BONUS_ACCUM}) {
	add_bonus_accumulation();
	dell_bonus_accumulation();
}

#**********************************************************
=head2 add_bonus_accumulation();

  DESCRIBE: Accumulates a bonus depending on the period of use of services without debt
 
=cut
#**********************************************************

sub add_bonus_accumulation {

	my $tp_ids = $conf{CUSTOM_BONUS_ACCUM_TP_ID} || 0;
	my $bonus_amount = $conf{CUSTOM_BONUS_ACUMM_AMOUNT} = 1;
	my $interval_pay_months = $conf{CUSTOM_BONUS_ACCUM_PAY_INTERVAL} || 12;
	my $fees_check = $conf{CUSTOM_BONUS_ACCUM_FEES} || 100;
	
	my $dbh = DBI->connect($dsn, $user, $password) or die "Unable to connect to database: $DBI::errstr";

	print "<<< Clients for bonus accumulation >>>\n";

	my $sql_arr = "SELECT fs.uid, DATEDIFF(NOW(), MIN(fs.date)) AS days_since_first_deposit, COUNT(last_deposit) AS count_fees, us.ext_bill_id
                    FROM fees fs
                    JOIN internet_main im ON fs.uid = im.uid
                    JOIN tarif_plans tp ON im.tp_id = tp.tp_id AND tp.id IN ($tp_ids)
                    JOIN users us ON fs.uid = us.uid
                        WHERE fs.uid IN (
                            SELECT fs2.uid
                            FROM fees fs2
                            WHERE fs2.date >= DATE_SUB(NOW(), INTERVAL $interval_pay_months MONTH)
                            GROUP BY fs2.uid
                            HAVING SUM(CASE WHEN fs2.last_deposit < 0 THEN 1 ELSE 0 END) = 0
                        )
                    GROUP BY fs.uid";
		   
	my $sth_arr = $dbh->prepare($sql_arr) or die "Failed to prepare request: $DBI::errstr";
	$sth_arr->execute() or die "Failed to execute the request: $DBI::errstr";
	
foreach my $row (@{$sth_arr->fetchall_arrayref({})}) {
	
    my $uid = $row->{'uid'};
    my $days = $row->{'days_since_first_deposit'} + 1;
	my $interval = $row->{'interval_pay_months'};
	my $count_fees = $row->{'count_fees'};
	my $ext_bill_id = $row->{'ext_bill_id'};
	
	if ($conf{CUSTOM_BONUS_DISC_ACCUM_CHECK}) {
		if ((($count_fees / $days) * 100) < $fees_check) {
			next;
			}
		}
		
    if ($ext_bill_id == 0) {
        eval {
            my $insert_sql = "INSERT INTO bills (uid, registration) VALUES ($uid, CURRENT_DATE)";
            my $sth_insert = $dbh->prepare($insert_sql);
            $sth_insert->execute();
            
            my $new_bill_id = $dbh->{mysql_insertid};

            my $update_sql_1 = "UPDATE users SET ext_bill_id = $new_bill_id WHERE uid = $uid";
            my $sth_update = $dbh->prepare($update_sql_1);
            $sth_update->execute();
            
            $dbh->commit;

            $ext_bill_id = $new_bill_id;
        };

        if ($@) {
            $dbh->rollback;
            warn "Error update users $@";
        }
    }

	print "USER: $uid, ACTIVE_DAYS: $days, COUNT_FEES: $count_fees\n";
	
    my $update_sql_2 = "UPDATE bills SET deposit = deposit + $bonus_plus WHERE id = $ext_bill_id";
    my $sth_update_2 = $dbh->prepare($update_sql_2);
    $sth_update_2->execute(); 
    $sth_update_2->finish;
	
	}

$dbh->disconnect();

return 1;

}

#**********************************************************
=head2 dell_bonus_accumulation();

  DESCRIBE: Accumulates a bonus depending on the period of use of services without debt
 
=cut
#**********************************************************

sub dell_bonus_accumulation {

my $method_pay = 4;
my $interval_dep = $conf{CUSTOM_BONUS_ACCUM_PAY_INTERVAL} || 6;

my $dbh = DBI->connect($dsn, $user, $password) or die "Unable to connect to database: $DBI::errstr";

	print "<<< Clients for del bonus accumulation >>>\n";

my $sql = "SELECT p.uid AS uid, SUM(p.sum) AS total_deposits, b.id, b.deposit, us.ext_bill_id
					FROM payments p
					JOIN users us ON p.uid = us.uid
					LEFT JOIN bills b ON p.bill_id = b.id and b.deposit > 0
					WHERE p.method = $method_pay and b.id = us.ext_bill_id
					AND p.date >= DATE_SUB(NOW(), INTERVAL $interval_dep MONTH)
					GROUP BY p.uid, b.deposit";

my $sth = $dbh->prepare($sql) or die "Failed to prepare request: $DBI::errstr";
$sth->execute() or die "Failed to execute the request: $DBI::errstr";

foreach my $row (@{$sth->fetchall_arrayref({})}) {
    my $uid = $row->{'uid'};
    my $total_deposits = $row->{'total_deposits'};
    my $ext_bill_id = $row->{'ext_bill_id'};
    my $deposit = $row->{'deposit'};
	
    if ($deposit > $total_deposits){
        my $sum = $deposit - $total_deposits;
        
        my $update_sql = "UPDATE bills SET deposit = deposit - $sum WHERE b.id = ext_bill_id = $ext_bill_id";
        my $update_sth = $dbh->prepare($update_sql);
        $update_sth->execute();
        $update_sth->finish();

        my $dsc = "Списание не исользуемых бонусов";
        my $ip = 0;
        my $last_deposit = $deposit;
        my $aid = 2;
        my $method_fees = 6;
        
        my $insert_sql = "INSERT INTO fees (sum, dsc, ip, last_deposit, uid, aid, method, bill_id) VALUES ($sum, $dsc, $ip, $last_deposit, $uid, $aid, $method_fees, $ext_bill_id)";
        my $insert_sql = "SELECT * FROM fees WHERE uid=25974";		        my $sth_log = $dbh->prepare($insert_sql) or die "Failed to prepare request: $DBI::errstr";
        $sth_log->execute() or die "Failed to execute the request: $DBI::errstr";
        $sth_log->finish;
    }
}

$dbh->disconnect();

}

1;