=head1 NAME

   MySQL partitioning

Arguments:

  TABLES="fees,payments" - List of part tables
  SKIP_TABLES="payments,fees" - SKip tables
  DEBUG=0..7

Options:

  $conf{PARTITIONING_FIN}=1;

=cut

use strict;
use warnings FATAL => 'all';

use DBI;
use Sys::Syslog qw(:standard :macros);
use POSIX qw(strftime);
use AXbills::Base qw(load_pmodule in_array);

our (
  $Admin,
  %conf,
  $argv,
  $debug
);

my $db_schema = $conf{dbname};
my $amount_partitions = 10;
my $curr_tz = 'Europe/London';

my %tables = (
  'ipn_traf_detail' => { 'period' => 'day', 'keep_history' => '30', main_field => 's_time' },
  's_detail'        => { 'period' => 'day', 'keep_history' => '30', main_field => 'start' },
  'errors_log'      => { 'period' => 'day', 'keep_history' => '7', main_field  => 'date' },
  'internet_log'    => { 'period' => 'month', 'keep_history' => '30', main_field => 'start' },
);

if ($conf{API_LOG}) {
  $tables{'api_log'} = { 'period' => 'day', 'keep_history' => '14', main_field => 'date' };
}

if ($conf{PARTITIONING_FIN}) {
  $tables{'fees'}    = { 'period' => 'month', 'keep_history' => '60', main_field => 'date' };
  $tables{'payments'}= { 'period' => 'month', 'keep_history' => '60', main_field => 'date' };
}


load_pmodule('DateTime');

my $query_cmd='query2';
if($Admin->can('query')) {
  $query_cmd='query';
}

if($debug > 4) {
  $Admin->{debug}=1;
}

if(defined($argv->{INFO})) {
  db_info();
  exit;
}
elsif(defined($argv->{help})) {

print << "[END]";

  MySQL partitioning

  TABLES = List of part tables
  DEBUG

[END]

}
else {
  partitioning();
}


#**********************************************************
=head2 partitioning()

=cut
#**********************************************************
sub partitioning {

  my $part_tables;

  unless (check_have_partition()) {
    print "Your installation of MySQL does not support table partitioning.\n";
    syslog(LOG_CRIT, 'Your installation of MySQL does not support table partitioning.');
    exit 1;
  }

  if ($debug > 6) {
    $Admin->{debug}=1;
  }

  my @skip_tables = ();
  if ($argv->{SKIP_TABLES}) {
    @skip_tables = split(/,\s?/, $argv->{SKIP_TABLES});
  }

  $Admin->$query_cmd(qq{SELECT lower(table_name) as table_name,
     lower(partition_name) as partition_name,
     lower(partition_method) AS partition_method,
     RTRIM(LTRIM(partition_expression)) AS partition_expression,
     lower(partition_description) as partition_description,
     lower(table_rows) as table_rows
   FROM information_schema.partitions
   WHERE partition_name IS NOT NULL AND table_schema = '$conf{dbname}';}, undef, { COLS_NAME => 1, COLS_UPPER => 1 });

  foreach my $line (@{ $Admin->{list} }) {
    $part_tables->{$line->{'table_name'}}->{$line->{'partition_name'}} = $line;

    print "$line->{'table_name'}: $line->{'partition_name'} = $line->{'table_rows'}\n" if ($debug > 1);
  }

  my @tables_ = keys %tables;

  if($argv->{TABLES}) {
    @tables_ = split(/,\s?/, $argv->{TABLES});
  }

  foreach my $table (sort @tables_) {
    print "Table: $table\n" if ($debug > 0);
    if (in_array($table, \@skip_tables)) {
      print "Skip\n" if ($debug > 0);
      next;
    }
    if (!defined($part_tables->{$table})) {
      syslog(LOG_ERR, 'Partitioning for "' . $table . '" is not found! The table might be not partitioned.');
      if (!init_partition($table, $tables{$table}->{'period'}, $tables{$table}->{'main_field'})) {
        next;
      }
    }

    create_next_partition($table, $part_tables->{$table}, $tables{$table}->{'period'});
    remove_old_partitions($table, $part_tables->{$table}, $tables{$table}->{'period'}, $tables{$table}->{'keep_history'})
  }

  return 1;
}

#**********************************************************
=head2 check_have_partition()

=cut
#**********************************************************
sub check_have_partition {
  #my $result = 0;
  # MySQL 5.5
  $Admin->$query_cmd(qq{ SELECT VERSION(); });

  my $version;
  if($Admin->{list}->[0]->[0]) {
    $version = $Admin->{list}->[0]->[0];
    $version =~ /^(\d+\.\d+)/;
    $version = $1;
  }

  if($version < 5.6) {
    print "Update DB to 5.7 cur version: $version\n";
  }

  #For ald version
  #$sth_ = $dbh->prepare(qq{SELECT variable_value FROM information_schema.global_variables WHERE variable_name = 'have_partitioning'});

  #MySQL 5.6
  $Admin->$query_cmd(qq{SELECT plugin_status FROM information_schema.plugins WHERE plugin_name = 'partition'});

  # MySQL 5.5
  #return 1 if ($row && $row eq 'YES');
  # MySQL 5.6

  if ($Admin->{list}->[0]->[0] && $Admin->{list}->[0]->[0] eq 'ACTIVE') {
    return 1;
  }
  elsif (!$Admin->{list}->[0]->[0] && $version >= 8) {
    return 1;
  }

  return 0;
}

#**********************************************************
=head2 create_next_partition($table_name, $table_part);

=cut
#**********************************************************
sub create_next_partition {
  my ($table_name, $table_part) = @_;

  for (my $curr_part = 0; $curr_part < $amount_partitions; $curr_part++) {
    my $next_name = name_next_part($tables{$table_name}->{'period'}, $curr_part);
    my $found = 0;

    foreach my $partition (sort keys %{$table_part}) {
      if ($next_name eq $partition) {
        syslog(LOG_INFO, "Next partition for $table_name table has already been created. It is $next_name");
        $found = 1;
      }
    }

    if ( $found == 0 ) {
      syslog(LOG_INFO, "Creating a partition for $table_name table ($next_name)");
      my $query = 'ALTER TABLE '."$db_schema.$table_name".' ADD PARTITION (PARTITION '.$next_name.
        ' VALUES less than (UNIX_TIMESTAMP("'.date_next_part($tables{$table_name}->{'period'}, $curr_part).'") div 1))';
      syslog(LOG_DEBUG, $query);

      $Admin->$query_cmd($query, 'do');
    }
  }

  return 1;
}

#**********************************************************
=head2 remove_old_partitions($table_name, $table_part, $period, $keep_history);

=cut
#**********************************************************
sub remove_old_partitions {
  my ($table_name, $table_part, $period, $keep_history) = @_;

  my $curr_date = DateTime->now();
  $curr_date->set_time_zone( $curr_tz );

  if ( $period eq 'day' ) {
    $curr_date->add(days => -$keep_history);
    $curr_date->add(hours => -$curr_date->strftime('%H'));
    $curr_date->add(minutes => -$curr_date->strftime('%M'));
    $curr_date->add(seconds => -$curr_date->strftime('%S'));
  }
  elsif ( $period eq 'week' ) {
  }
  elsif ( $period eq 'month' ) {
    $curr_date->add(months => -$keep_history);

    $curr_date->add(days => -$curr_date->strftime('%d')+1);
    $curr_date->add(hours => -$curr_date->strftime('%H'));
    $curr_date->add(minutes => -$curr_date->strftime('%M'));
    $curr_date->add(seconds => -$curr_date->strftime('%S'));
  }

  foreach my $partition (sort keys %{$table_part}) {
    if ($table_part->{$partition}->{'partition_description'} <= $curr_date->epoch) {
      syslog(LOG_INFO, "Removing old $partition partition from $table_name table");

      my $query = "ALTER TABLE $db_schema.$table_name DROP PARTITION $partition";

      syslog(LOG_DEBUG, $query);
      $Admin->$query_cmd($query, 'do');
    }
  }

  return 1;
}


#**********************************************************
=head2 date_next_part($period, $curr_part);

=cut
#**********************************************************
sub name_next_part {
  my ($period, $curr_part) = @_;

  my $name_template;

  my $curr_date = DateTime->now;
  $curr_date->set_time_zone( $curr_tz );

  if ( $period eq 'day' ) {
    $curr_date = $curr_date->truncate( to => 'day' );
    $curr_date->add(days => 1 + $curr_part);

    $name_template = $curr_date->strftime('p%Y_%m_%d');
  }
  elsif ($period eq 'week') {
    $curr_date = $curr_date->truncate( to => 'week' );
    $curr_date->add(days => 7 * $curr_part);

    $name_template = $curr_date->strftime('p%Y_%m_w%W');
  }
  elsif ($period eq 'month') {
    $curr_date = $curr_date->truncate( to => 'month' );
    $curr_date->add(months => 1 + $curr_part);

    $name_template = $curr_date->strftime('p%Y_%m');
  }

  return $name_template;
}

#**********************************************************
=head2 date_next_part($period, $curr_part);

=cut
#**********************************************************
sub date_next_part {
  my $period = shift;
  my $curr_part = shift;

  my $period_date;

  my $curr_date = DateTime->now;
  $curr_date->set_time_zone( $curr_tz );

  if ( $period eq 'day' ) {
    $curr_date = $curr_date->truncate( to => 'day' );
    $curr_date->add(days => 2 + $curr_part);
    $period_date = $curr_date->strftime('%Y-%m-%d');
  }
  elsif ($period eq 'week') {
    $curr_date = $curr_date->truncate( to => 'week' );
    $curr_date->add(days => 7 * $curr_part + 1);
    $period_date = $curr_date->strftime('%Y-%m-%d');
  }
  elsif ($period eq 'month') {
    $curr_date = $curr_date->truncate( to => 'month' );
    $curr_date->add(months => 2 + $curr_part);

    $period_date = $curr_date->strftime('%Y-%m-%d');
  }

  return $period_date;
}

#**********************************************************
=head2 db_info();

=cut
#**********************************************************
sub db_info {
  my %variables = (
    have_symlink => "show variables like 'have_symlink'",
    event_scheduler => "SHOW GLOBAL VARIABLES LIKE 'event_scheduler'"
  );

  foreach my $key ( sort keys %variables ) {
    print "$key:";
    $Admin->$query_cmd($variables{$key}, undef, { COLS_NAME => 0 });
    foreach my $line ( @{ $Admin->{list} } ) {
      print "$line->[0]: $line->[1]\n";
    }
  }

  return 1;
}

#**********************************************************
=head2 init_partition($table, $period, $main_field)

=cut
#**********************************************************
sub init_partition {
  my($table, $period, $main_field)=@_;

  if($debug) {
    print "Init: $table Period: ". ($period || q{}). "\n";
  }

  if (! $period) {
    print "ERROR: period not selected";
    return 0;
  }

  my @queries = (
    "ALTER TABLE `$table` PARTITION BY RANGE (UNIX_TIMESTAMP($main_field)) (PARTITION ". name_next_part($period, -1)
      ." VALUES LESS THAN (UNIX_TIMESTAMP(\"". date_next_part($period, -1) ." 00:00:00\")));",
    #qq{ALTER TABLE `$table` ADD PARTITION (PARTITION p2017_10_28 VALUES LESS THAN (UNIX_TIMESTAMP("2017-11-29 00:00:00")) ENGINE = InnoDB);}
  );

  foreach my $query ( @queries ) {
    print "$query\n" if($debug > 2);
    if($debug < 5) {
      $Admin->$query_cmd($query, 'do');
      if($Admin->{errno}) {
        print "Error: $Admin->{errno} $Admin->{errstr}\n";
        return 0;
      }
    }
  }

  return 1;
}

1;