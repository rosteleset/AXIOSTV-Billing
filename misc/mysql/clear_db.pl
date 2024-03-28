#!/usr/bin/perl
#**********************************************************
=head1 NAME

 Clear db

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';

BEGIN {
  our (%conf, @MODULES);
  use FindBin '$Bin';
  require $Bin.'/../../libexec/config.pl';
  unshift(@INC,
    $Bin.'/../../',
    $Bin.'/../../AXbills/modules/',
    $Bin.'/../../lib/',
    $Bin."/../../AXbills/$conf{dbtype}"
  );
}

our ( %conf, $DATE, $TIME, @MODULES );

my $debug = 1;
my $version = 0.12;

use AXbills::SQL;
use Admins;
use AXbills::Base qw(check_time parse_arguments gen_time in_array);

my $begin_time = check_time();

my $argv = parse_arguments(\@ARGV);
if ($argv->{DB_NAME}) {
  $conf{dbname} = $argv->{DB_NAME};
}

my $db = AXbills::SQL->connect( $conf{dbtype},
  $conf{dbhost},
  $conf{dbname},
  $conf{dbuser},
  $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} :
      undef } );

my $Admin = Admins->new( $db, \%conf );

if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
  print  "DEBUG: $debug \n";
}

my $action = 'SELECT * ';
if (defined($argv->{DEL})) {
  $action = "DELETE";
}

if (defined($argv->{'-h'}) || defined($argv->{'help'})) {
  help();
  exit;
}

my $internet_module_enabled = in_array('Internet', \@MODULES);

if (!$argv->{ACTIONS}) {
  $argv->{ACTIONS} = 'payments,fees';
  if ($internet_module_enabled){
    $argv->{ACTIONS} .= ',internet_log';
  }
  else {
    $argv->{ACTIONS} .= ',dv_log';
  }
}

if (!$argv->{DATE}) {
  print "use DATE=  argument\n";
  exit;
}

my $drop_exist_table = 1;

$Admin->{debug} = 1 if ( $debug > 6 );

$argv->{ACTIONS} =~ s/ //g;
my @actions = split(/,/, $argv->{ACTIONS});

my $CUR_DATE = $argv->{DATE};
$CUR_DATE =~ s/\-/\_/g;

# MAYBE should delete arg in else branch?
if ($argv->{DATE} =~ /^\d{4}\-\d{2}\-\d{2}$/) {
  $argv->{DATE} = "$argv->{DATE}";
}

db_action();

if ($begin_time > 0 && $debug > 0) {
  print gen_time($begin_time)
}


#**********************************************************
=head2 db_action()

=cut
#**********************************************************
sub db_action {
  #my ($attr) = @_;

  my DBI $db_ = $db->{db};

  foreach my $log (@actions) {
    my $fn = $log.'_rotate';

    my $sql_arr = &{ \&$fn }( { %$argv,
      DATE => ($argv->{DATE} !~ m/[<>]/) ? "<$argv->{DATE}" : "$argv->{DATE}"
    });

    if (defined($argv->{'ROTATE'})) {
      $action = 'DELETE ';
      push @{ $sql_arr }, @{ &{ \&$fn }( {
        DELETE => 1,
        DATE   => "<$argv->{DATE}" } )
      };
      $action = 'SELECT * ';
    }

    if ($debug > 1) {
      print "\n==> $fn\n";
    }

    $db_->{AutoCommit} = 0;

    foreach my $sql (@$sql_arr) {
      if ($debug > 3 || defined($argv->{SHOW}) || defined($argv->{SHOW_SUMMARY})) {
        if($argv->{SHOW_SUMMARY}) {
          $Admin->query( "$sql" );
          print "$fn Total: $Admin->{TOTAL}\n";
          next;
        }
        print $sql."\n";
        if(defined($argv->{SHOW})) {
          next;
        }
      }

      if ($debug < 5) {
        $Admin->query( "$sql", (($action eq 'DELETE' || defined($argv->{'ROTATE'})) ? 'do' : undef) );

        if ($Admin->{errno}) {
          print "SQL Error: [$Admin->{errno}] $Admin->{errstr} / $Admin->{sql_errno} $Admin->{sql_errstr}\n";

          if ($Admin->{sql_errno} == 1050 && $drop_exist_table) {
            if ($Admin->{sql_errstr} =~ /\'(\S+)\'/) {
              my $table = $1;
              print "Drop table: $table\n";
              $Admin->query( "DROP TABLE $1", 'do' );
            }
          }
          else {
            exit;
          }
        }

        print "$fn Rows: $Admin->{TOTAL}/$Admin->{AFFECTED}\n" if ($debug > 0);
      }
    }
    $db_->commit();
    $db_->{AutoCommit} = 1;
  }

  return 1;
}

#**********************************************************
=head2 payments_list($attr)

=cut
#**********************************************************
sub payments_list {
  my ($attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{GID}) {
    push @WHERE_RULES, @{ $Admin->search_expr( "$attr->{GID}", 'INT', 'groups.gid' ) };
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $Admin->search_expr( "$attr->{DATE}", 'DATE', 'payments.date' ) };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE ".join(' and ', @WHERE_RULES) : '';

  my $sql_expr = "(SELECT payments.id FROM payments 
    LEFT JOIN users u ON (u.uid=payments.uid)
    LEFT JOIN groups ON (u.gid=groups.gid)
  $WHERE
  GROUP BY payments.id)";

  my $sql_expr2 = " LEFT JOIN users u ON (u.uid=payments.uid)
    LEFT JOIN groups ON (u.gid=groups.gid)
  $WHERE";

  return ($sql_expr, $sql_expr2);
}



#**********************************************************
=head2 payments_rotate($attr)

=cut
#**********************************************************
sub payments_rotate {
  my ($attr) = @_;

  my ($payments_list, $payments_list2) = payments_list($attr);

  my $action_ = $action;

  if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE docs_invoice2payments_'.$CUR_DATE."  DEFAULT CHARSET=$conf{dbcharset} ".$action;
    $action_ =~ s/\*/docs_invoice2payments\.\*/g;
  }

  my @SQL_array = (
    "$action_ FROM docs_invoice2payments  WHERE payment_id IN $payments_list;  ");

  if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE docs_invoices_'.$CUR_DATE."  DEFAULT CHARSET=$conf{dbcharset} ".$action;
    $action_ =~ s/\*/docs_invoices\.\*/g;
  }

  push @SQL_array,
    "$action_ FROM docs_invoices WHERE id IN (SELECT invoice_id FROM docs_invoice2payments WHERE payment_id IN $payments_list);";

  if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE docs_receipt_orders_'.$CUR_DATE."  DEFAULT CHARSET=$conf{dbcharset} ".$action;
    $action_ =~ s/\*/docs_receipt_orders\.\*/g;
  }
  push @SQL_array,
    "$action_ FROM docs_receipt_orders WHERE receipt_id IN (SELECT id FROM docs_receipts WHERE payment_id IN $payments_list);";

  if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE docs_receipts_'.$CUR_DATE."  DEFAULT CHARSET=$conf{dbcharset} ".$action;
    $action_ =~ s/\*/docs_receipts\.\*/g;
  }
  push @SQL_array, "$action_ FROM docs_receipts WHERE payment_id IN $payments_list;";

  if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE payments_'.$CUR_DATE."  DEFAULT CHARSET=$conf{dbcharset} ".$action;
    $action_ =~ s/\*/payments\.\*/g;
  }
  elsif ($action =~ /DELETE/) {
    $action_ .= ' payments ';
  }

  push @SQL_array, "$action_ FROM payments $payments_list2;";

  return \@SQL_array;
}


#**********************************************************
=head2 fees2_rotate($attr)

=cut
#**********************************************************
sub fees2_rotate {
  my ($attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{DELETE}) {
    return [ ];
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $Admin->search_expr( "<$argv->{DATE}", 'DATE', 'f.date' ) };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE ".join(' AND ', @WHERE_RULES) : '';

  my @SQL_array = ('DROP TABLE IF EXISTS fees_new;',
    'CREATE TABLE fees_new LIKE fees;',
    'DROP TABLE IF EXISTS fees_backup;',
    'RENAME TABLE fees TO fees_backup, fees_new TO fees;',
    'CREATE TABLE IF NOT EXISTS fees_'.$CUR_DATE.' LIKE fees;');

  push @SQL_array, 'INSERT INTO fees_'.$CUR_DATE."
  SELECT DISTINCT f.* FROM fees_backup f 
    LEFT JOIN users ON (users.uid=f.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE
   GROUP BY f.id";

  if ($attr->{DATE}) {
    @WHERE_RULES = @{ $Admin->search_expr( ">=$argv->{DATE}", 'DATE', 'f.date' ) };
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE ".join(' AND ', @WHERE_RULES) : '';

  push @SQL_array, "INSERT INTO fees
    SELECT DISTINCT f.* FROM fees_backup f 
    LEFT JOIN users ON (users.uid=f.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE
   GROUP BY f.id";

  push  @SQL_array, 'DROP TABLE fees_backup;';

  return \@SQL_array;
}

#**********************************************************
=head2 fees_rotate($attr)

=cut
#**********************************************************
sub fees_rotate {
  my ($attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $Admin->search_expr( "$attr->{DATE}", 'DATE', 'f.date' ) };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE ".join(' AND ', @WHERE_RULES) : '';

  my $action_ = $action;

  if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE fees_'.$CUR_DATE.  " DEFAULT CHARSET=$conf{dbcharset} ".$action ;
    $action_ =~ s/\*/f\.\*/g;
  }
  elsif ($action_ =~ /DELETE/) {
    $action_ .= ' f ';
  }

  $Admin->query("SET character_set_client=$conf{dbcharset};", 'do');
  $Admin->query("SET character_set_connection=$conf{dbcharset};", 'do');
  $Admin->query("SET character_set_database=$conf{dbcharset};", 'do');
  $Admin->query("SET character_set_results=$conf{dbcharset};", 'do');
  $Admin->query("SET character_set_server=$conf{dbcharset};", 'do');

  my @SQL_array = ("$action_ FROM fees f
    LEFT JOIN users ON (users.uid=f.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE
     ");

  return \@SQL_array;
}


#**********************************************************
=head2 internet_log_rotate($attr)

=cut
#**********************************************************
sub internet_log_rotate {
  my ($attr) = @_;
  
  $attr->{TABLE_NAME} = 'internet_log';
  
  return dv_log_rotate($attr);
}

#**********************************************************
=head2 internet_log_group_rotate($attr)

=cut
#**********************************************************
sub internet_log_group_rotate {
  my ($attr) = @_;
  
  $attr->{TABLE_NAME} = 'internet_log';
  $attr->{SUBSTITUTE_FIELDS} = {
    CID => 'cid'
  };
  
  return dv_log_group_rotate($attr);
}

#**********************************************************
=head2 dv_log_rotate($attr)

=cut
#**********************************************************
sub dv_log_rotate {
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $table_name = $attr->{TABLE_NAME} || 'dv_log';
  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $Admin->search_expr( "$attr->{DATE}", 'DATE', 'l.start' ) };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE ".join(' and ', @WHERE_RULES) : '';
  my $action_ = $action;

  if (defined($attr->{ROTATE})) {
    $action_ = "CREATE TABLE $table_name\_$CUR_DATE DEFAULT CHARSET=$conf{dbcharset} ".$action;
    $action_ =~ s/\*/l\.\*/g;
  }
  elsif ($action_ =~ /DELETE/) {
    $action_ .= ' l ';
  }

  my @SQL_array = (  "$action_ FROM $table_name l
    LEFT JOIN users ON (users.uid=l.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE");

  return \@SQL_array;
}


#**********************************************************
=head2 dv_log_group_rotate()

=cut
#**********************************************************
sub dv_log_group_rotate {
  my ($attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $Admin->search_expr( "<$argv->{DATE}", 'DATE', 'l.start' ) };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE ".join(' AND ', @WHERE_RULES) : '';
  my $table_name = $attr->{TABLE_NAME} || 'dv_log';
  my $cid_col_name = ($attr->{SUBSTITUTE_FIELDS} && $attr->{SUBSTITUTE_FIELDS}{CID})
    ? $attr->{SUBSTITUTE_FIELDS}{CID}
    : 'CID';

  my @SQL_array = ('DROP TABLE IF EXISTS '.$table_name.'_new;',
    'CREATE TABLE '.$table_name.'_new LIKE '.$table_name.';',
    'DROP TABLE IF EXISTS '.$table_name.'_backup;',
    'RENAME TABLE '.$table_name.' TO '.$table_name.'_backup, '.$table_name.'_new TO '.$table_name.';',
    'CREATE TABLE IF NOT EXISTS '.$table_name.'_'.$CUR_DATE.' LIKE '.$table_name.';'
  );

  push @SQL_array, 'INSERT INTO '.$table_name."
    (
   start,
   tp_id,
   duration,
   sent,
   recv,
   sum,
   nas_id,
   sent2,
   recv2,
   $cid_col_name,
   bill_id,
   uid,
   acct_input_gigawords,
   acct_output_gigawords,
   ex_input_octets_gigawords,
   ex_output_octets_gigawords)
    SELECT DATE_FORMAT(l.start, '%Y-%m-%d 00:00:00'),
   l.tp_id,
   SUM(l.duration),
   SUM(l.sent),
   SUM(l.recv),
   SUM(l.sum),
   l.nas_id,
   SUM(l.sent2),
   SUM(l.recv2),
   l.$cid_col_name,
   l.bill_id,
   l.uid,
   SUM(l.acct_input_gigawords),
   SUM(l.acct_output_gigawords),
   SUM(l.ex_input_octets_gigawords),
   SUM(l.ex_output_octets_gigawords)
    FROM ".$table_name."_backup l
    LEFT JOIN users ON (users.uid=l.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE
   GROUP BY uid, 1";

  if ($attr->{DATE}) {
    @WHERE_RULES = @{ $Admin->search_expr( ">=$argv->{DATE}", 'DATE', 'l.start' ) };
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE ".join(' AND ', @WHERE_RULES) : '';

  push @SQL_array, "INSERT INTO ".$table_name."
    SELECT l.* FROM ".$table_name."_backup l
    LEFT JOIN users ON (users.uid=l.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE";

  push  @SQL_array, 'DROP TABLE '.$table_name.'_backup;';
  return \@SQL_array;
}

#**********************************************************
#
#**********************************************************
sub help {

  print << "[END]";
  Clear db utilite VERSION: $version
  Clear payments, fees, dv_log or internet_log
  ACTIONS=[payments, fees, dv_log or internet_log ] - default all tables
  GID           - Groups
  DATE          - Date time DATE="<YYYY-MM-DD"
  SHOW          - Show clear date (default)
  DEL           - Clear date
  ROTATE        - Add rows to rotate table
  DEBUG=1..8    - Debug mode
  DB_NAME       - DB name (default from config.pl)
  help          - Help
[END]

}


1;
