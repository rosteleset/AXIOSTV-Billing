#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
=head1 NAME

  db_check.pl - console utility to check DB consistency

=head1 SYNOPSIS

  db_check.pl - checks .sql schema files and current DB scheme to find incosistency

=head2 ARGUMENTS

  --help, help, ?    - show this help and exit

  FROM_CACHE=1           - Use cache from previous
  ALLOW_DATA_STRIP=1     - Will show commands that can cause stripping current values ( use with caution )
  SHOW_CREATE=1          - Try to check enabled modules and tables that have module like name
  BATCH=1                - no confirm ( print all found ALTER and MODIFY statements to STDOUT )
  APPLY_ALL=1 -a         - no confirm ( apply all found ALTER and MODIFY statements )
  SKIP_DISABLED_MODULES  - skip comparing tables we know it's module specific and module is disabled
  CREATE_NOT_EXIST_TABLES
  SKIP_DB_CHECK          - skip db_check (example: load only config variables)
  SKIP_CONFIG_UPDATE     - skip config variables update

  Debug options are used for debug only:
    DEBUG            - debug_level (0..5)
    FILE             - parse only one .sql file
    SKIP_DUMP        - skip parsing .sql files
    D_TABLE          - when DEBUG=5, show table structure from dump
    D_FIELD          - when DEBUG=5, show D_TABLE field structure from dump
    S_TABLE          - when DEBUG=5, show table structure from DB
    S_FIELD          - when DEBUG=5, show S_TABLE field structure from DB

=head1 AUTHORS

  ABillS Team

=cut


our $libpath;
our ($Bin, %conf, $base_dir, @MODULES);
BEGIN {
  use FindBin '$Bin';
  # Assuming we are in '/usr/axbills/misc/db_check/'
  # Should point to axbills root dir
  $libpath = $Bin . '/../../';
}
use lib $Bin;
use lib $libpath;
use lib $libpath . 'lib';
use lib $libpath . 'AXbills/mysql';

do 'libexec/config.pl';
$base_dir //= $libpath;

# Enable Autoflush
$| = 1;

use Pod::Usage qw/&pod2usage/;

eval {require Carp::Always};

use AXbills::Base qw/_bp parse_arguments in_array/;
use AXbills::Misc;
use AXbills::Experimental;

use AXbills::SQL;
use Admins;

use Parser::Dump;
use Parser::Scheme;

my $db = AXbills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => $conf{dbcharset} });
my $Admin = Admins->new($db, \%conf);
$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1', SHORT => 1 });

my $argv = parse_arguments(\@ARGV);

if ($argv->{'--help'} || $argv->{-help} || $argv->{-help} || $argv->{'-?'} || $argv->{'t'}) {
  pod2usage(1);
}

my $debug = 0;
if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
  Parser::Dump::set_debug($debug);
  _bp(undef, undef, { SET_ARGS => { TO_CONSOLE => 1 } });
}

my %cached = ();
my %create_defined = ();
my %tables_keys = ();
my %tables_unique_keys = ();

if ($argv->{FROM_CACHE}) {
  $cached{$base_dir . 'db'} = 1;

  #  map { $cached{$_} = 1; } split(',\s?', $ARGS->{FROM_CACHE});
}

if ($argv->{CREATE_NOT_EXIST_TABLES}) {
  create_not_exist_tables();
}

if (!$argv->{SKIP_DB_CHECK}) {
  db_check();
}

if (!$argv->{SKIP_CONFIG_UPDATE}) {
  update_config_variables()
}

exit 0;

#**********************************************************
=head2 db_check()

=cut
#**********************************************************
sub db_check {

  # Get list of modules
  my $all_modules = existing_modules_list();

  # Parse dump
  my %dump_info = ();
  if ($argv->{SKIP_DUMP}) {
    ## Do nothing
  }
  elsif ($argv->{FILE}) {
    Parser::Dump::parse_accumulate($argv->{FILE});
  }
  else {
    # Get hash for all existing tables structure
    for my $dir ('db') {
      #, 'db/update' ) {
      my $dir_path = $base_dir . $dir;

      my $cache_path = $dir_path . '/parser_dump.cache';

      if (exists $cached{$dir_path}) {

        if (-e $cache_path) {
          print " Use cache for $dir_path \n" if ($debug);
          %dump_info = (%dump_info, %{Parser::Dump::read_from_file($cache_path)});
        }
        else {
          print " No cache for $dir_path \n" if ($debug);
          Parser::Dump::parse_accumulate($dir_path, { SAVE_TO => $cache_path, MODULE_DB => $base_dir . 'AXbills/modules/',
            ALL_MODULES => $all_modules })
        };
      }
      else {
        Parser::Dump::parse_accumulate($dir_path, { SAVE_TO => $cache_path, MODULE_DB => $base_dir . 'AXbills/modules/',
          ALL_MODULES => $all_modules })
      };
    }
  }

  %dump_info = %{Parser::Dump::get_accumulated({ USE_CACHE => \%dump_info })};

  if ($debug > 4 && $argv->{D_TABLE}) {
    if (!exists $dump_info{$argv->{D_TABLE}}) {
      die "TABLE $argv->{D_TABLE} was not found in dump";
    }
    _bp($argv->{D_TABLE}, $dump_info{$argv->{D_TABLE}});
    if ($argv->{D_FIELD} && exists $dump_info{ $argv->{D_TABLE} }->{columns}->{ $argv->{D_FIELD} }) {
      _bp($argv->{D_FIELD}, $dump_info{$argv->{D_TABLE}}->{columns}->{$argv->{D_FIELD}});
    }
  }

  print "Found " . scalar(keys %dump_info) . " tables\n" if ($debug);

  # Get info for tables from DB
  my $scheme_parser = Parser::Scheme->new($db, $Admin, \%conf);
  my %scheme_info = %{$scheme_parser->parse()};

  if ($debug > 4 && $argv->{S_TABLE}) {
    if (!exists $scheme_info{$argv->{S_TABLE}}) {
      die "TABLE $argv->{S_TABLE} was not found in scheme";
    }
    _bp($argv->{S_TABLE}, $scheme_info{$argv->{S_TABLE}});
    if ($argv->{S_FIELD} && exists $scheme_info{ $argv->{S_TABLE} }->{columns}->{ $argv->{S_FIELD} }) {
      _bp($argv->{S_FIELD}, $scheme_info{$argv->{S_TABLE}}->{columns}->{$argv->{S_FIELD}});
    }
  }

  # Get all tables from files
  _get_tables_from_file();
  # Get keys from files
  get_table_keys_from_files();

  # Get all tables from DB
  my @existing_tables = sort keys %scheme_info;
  foreach my $table (@existing_tables) {
    # Filter tables with module name but not enabled
    if ($argv->{SKIP_DISABLED_MODULES} && $table =~ /^([a-z]+)\_/) {
      my $name = ucfirst $1;
      # Skip if it is module name and not enabled module
      next if (is_disabled_module_name($name, $all_modules));
    }

    if (exists $dump_info{$table}) {
      # Compare columns and types
      compare_tables($table, $dump_info{$table}, $scheme_info{$table});
      check_table_keys($table, $scheme_info{$table}) if $debug;
    }
  }

  return 1;
}

#**********************************************************
=head2 compare_tables($table_name, $dump_table, $sql_table)

  Arguments:
    $table_name
    $dump_table
    $sql_table

=cut
#**********************************************************
sub compare_tables {
  my ($table_name, $dump_table, $sql_table) = @_;

  return 0 if (!$sql_table);

  my $dump_cols_ref = $dump_table->{columns} || {};
  my $sql_cols_ref = $sql_table->{columns} || {};

  # If found global differences, than should check it more
  print "Checking table $table_name\n" if ($debug);

  my @dump_cols = sort keys %{$dump_cols_ref};
  my @sql_cols = sort keys %{$sql_cols_ref};

  my @existing_in_dump_but_not_sql = grep {!in_array($_, \@sql_cols)} @dump_cols;
  my @existing_in_sql_but_not_in_dump = grep {!in_array($_, \@dump_cols)} @sql_cols;

  for (@dump_cols) {
    if (!in_array($_, \@sql_cols)) {
      my $col_definition = get_column_definition($dump_cols_ref->{$_});
      show_tip("ALTER TABLE `$table_name` ADD COLUMN `$_` " . "$col_definition;");
    }
  }

  if (scalar @existing_in_dump_but_not_sql) {
    print "  Somebody have forgot to define (or execute) ALTER ADD COLUMN for columns:\n" if ($debug);
    print join('', map {"    $_ \n"} @existing_in_dump_but_not_sql) if ($debug);
  }

  if (scalar @existing_in_sql_but_not_in_dump) {
    print "  This columns was not found in Dump \n" if ($debug);
    do {print "$table_name.$_\n" for (@existing_in_sql_but_not_in_dump)} if ($debug);
  }

  # Getting only both existing cols for check
  my %hash_for_unique_keys = ();
  foreach (@dump_cols) {
    $hash_for_unique_keys{$_} = 1 if (exists $dump_cols_ref->{$_} && exists $sql_cols_ref->{$_});
  }
  my @both_existing = sort keys %hash_for_unique_keys;

  # Now can check types
  foreach my $col (@both_existing) {
    # TYPE
    my $dump_type = lc $dump_cols_ref->{$col}->{Type};
    my $sql_type = lc $sql_cols_ref->{$col}->{Type};

    # SIZE
    my ($dump_size) = $dump_type =~ /\((\d+)\)/;
    my ($sql_size) = $sql_type =~ /\((\d+)\)/;

    # NULLABLE
    my $dump_nullable = is_nullable($dump_cols_ref->{$col});
    my $sql_nullable = is_nullable($sql_cols_ref->{$col});

    # DEFAULT
    my $dump_default = is_nullable($dump_cols_ref->{Default});
    my $sql_default = is_nullable($sql_cols_ref->{Default});

    my $col_definition = get_column_definition($dump_cols_ref->{$col});
    my $current_def = get_column_definition($sql_cols_ref->{$col});

    if ($current_def ne $col_definition && $current_def ne 'TEXT') {

      my $type_equals = ($dump_type eq $sql_type);
      my $null_equals;
      my $defa_equals;
      $null_equals = $dump_nullable eq $sql_nullable if (defined($dump_nullable) && defined($sql_nullable));
      $defa_equals = $dump_default eq $sql_default if (defined($dump_default) && defined($sql_default));

      # Skip if type and nullable equals and can't check default (is undefined)
      next if ($type_equals && $null_equals && !defined $defa_equals);

      print "  Found wrong defined type for $table_name.$col \n" if ($debug);

      # Check if data will not be stripped in case of modification
      if ($dump_size && $sql_size && $sql_size > $dump_size && !$argv->{ALLOW_DATA_STRIP}) {
        print " Will truncate data if applied ($sql_size -> $dump_size). skipping. use \$ARGS->{ALLOW_DATA_STRIP} \n" if ($debug);
        next;
      };

      print "Expected: '$col_definition' . Got: '$current_def') \n" if ($debug);

      $col_definition =~ s/PRIMARY KEY//g;
      show_tip("ALTER TABLE `$table_name` MODIFY COLUMN `$col` " . "$col_definition;", {
        PREV => uc($current_def),
        NEW  => uc($col_definition)
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 get_column_definition($dump_col_info)

=cut
#**********************************************************
sub get_column_definition {
  my ($dump_col_info) = @_;

  my $default_def = '';
  my $nullable = '';
  my $primary_key = '';

  if (defined $dump_col_info->{Null} && $dump_col_info->{Null} eq 'No') {
    $nullable = ' NOT NULL';
  }

  if (defined $dump_col_info->{Default}) {
    my $default_val = undef;

    if (ref $dump_col_info->{Default} && ref $dump_col_info->{Default} eq 'SCALAR') {
      $default_val = qq{${$dump_col_info->{Default}}};
    }
    # True
    elsif ($dump_col_info->{Default}) {

      if ($dump_col_info->{Default} eq 'CURRENT_TIMESTAMP') {
        $default_val = q{CURRENT_TIMESTAMP};
      }
      elsif ($dump_col_info->{Default} eq 'NOW') {
        $default_val = q{NOW()};
      }
      elsif ($dump_col_info->{Default} eq 'NULL') {
        #        $default_val = q{NULL};
      }
      else {
        $default_val = qq{'$dump_col_info->{Default}'};
      }

    }
    # Falsy
    elsif ($dump_col_info->{Default} eq '0') {
      $default_val = q/0/;
    }

    # False
    else {
      $default_val = q/''/;
    }

    $default_def = defined $default_val
      ? (' DEFAULT ' . $default_val)
      : '';
  }

  if ($dump_col_info->{_raw} && $dump_col_info->{_raw}{is_primary_key}) {
    $primary_key = ' PRIMARY KEY ';
  }

  return uc($dump_col_info->{Type}) . $primary_key . $nullable . $default_def;
}

#**********************************************************
=head2 is_nullable($col_def)

=cut
#**********************************************************
sub is_nullable {
  my ($col_def) = @_;

  my $null_defined = exists $col_def->{Null} && defined $col_def->{Null};
  my $nullable = $null_defined && $col_def->{Null} && lc($col_def->{Null}) !~ /no/i;

  return $nullable
    ? 1
    : $null_defined
    ? 0
    : undef;
}

#**********************************************************
=head2 show_tip($tip)

=cut
#**********************************************************
sub show_tip {
  my ($tip, $attr) = @_;

  if ($argv->{BATCH}) {
    print "$tip\n";
    return 1;
  }

  if ($argv->{APPLY_ALL} || defined($argv->{'-a'})) {
    $Admin->query($tip, 'do', {});
    return 1;
  }

  my $text = ($attr->{PREV} && $attr->{NEW}) ? "Current: $attr->{PREV}\n Change to : $attr->{NEW} \n $tip" : $tip;
  print "\n $text \n Apply? (y/N/a): ";
  chomp(my $ok = <STDIN>);

  if ($ok eq 'a') {
    $ok = 'y';
    $argv->{APPLY_ALL} = 1;
  }

  if ($ok !~ /y/i) {
    print " Skipped \n";
    return 1;
  };

  $Admin->query($tip, 'do', {});
  if ($Admin->{errno}) {
    print "\n Error happened : " . ($Admin->{errno} || '') . "\n";
    return 0;
  }
  else {
    print "Applied successfully \n";
  }

  return 1;
}

#**********************************************************
=head2 existing_modules_list()

=cut
#**********************************************************
sub existing_modules_list {

  my $dirs_list = _get_files_in($base_dir . 'AXbills/modules', { WITH_DIRS => 1 });

  my @module_names = grep {-d $base_dir . 'AXbills/modules/' . $_} @{$dirs_list};

  return \@module_names;
}

#**********************************************************
=head2 is_disabled_module_name()

=cut
#**********************************************************
sub is_disabled_module_name {
  my ($name, $exisiting_modules) = @_;

  $name = 'Equipment' if ($name eq 'Pon');
  $name = 'Crm' if ($name eq 'Cashbox');

  return(in_array($name, $exisiting_modules) && !in_array($name, \@MODULES));
}

#**********************************************************
=head2 _get_create_commands()

=cut
#**********************************************************
sub _get_create_commands {
  my $module_sql_name = shift;
  my $module_sql_name_add = shift;

  $module_sql_name = $module_sql_name_add if ($module_sql_name_add && !(-e $module_sql_name));
  if (-e $module_sql_name) {
    my $content = Parser::Dump::get_file_content($module_sql_name);
    my @tables = $content =~ /((^|[^- ])CREATE TABLE [^;]*;)/sg;

    foreach my $table (@tables) {
      my $table_name = "";
      if ($table =~ /((EXISTS|TABLE).+`.+`)/) {
        (undef, $table_name, undef) = split('`', $1);
        next if $table_name eq "id";
        $create_defined{$table_name} = $table;
      }
    }
  }
}

#**********************************************************
=head2 create_not_exist_tables()

=cut
#**********************************************************
sub create_not_exist_tables {

  print "Create not exists tables...\n" if $debug;
  my $scheme_parser = Parser::Scheme->new($db, $Admin, \%conf);
  my %scheme_info = %{$scheme_parser->parse()};

  _get_tables_from_file();

  my $count_added_tables = 0;
  foreach my $key (keys %create_defined) {
    if (!exists $scheme_info{$key}) {
      $Admin->query($create_defined{$key}, 'do', {});
      if ($Admin->{errno}) {
        print "\n Error happened : " . ($Admin->{errno} || '') . "\n";
        return 0;
      }
      else {
        $count_added_tables++;
        print "Table `$key` successfully added\n" if ($debug);
      }
    }
  }

  if (!$count_added_tables) {
    print "Nothing to create\n" if ($debug);
  }

  return 1;

}

#**********************************************************
=head2 _get_tables_from_file()

=cut
#**********************************************************
sub _get_tables_from_file {

  my $base_db_dir = $base_dir . "db/";
  _get_create_commands($base_db_dir . "axbills.sql");
  foreach my $module (@MODULES) {
    next if $module eq "Multidoms";
    my $module_sql_name = $base_db_dir . $module . ".sql";
    _get_create_commands($module_sql_name, $base_dir . "AXbills/modules/$module/$module.sql");
  }

  return 1;
}

#**********************************************************
=head2 get_table_keys_from_files()

=cut
#**********************************************************
sub get_table_keys_from_files {

  foreach my $table_name (keys %create_defined) {
    $tables_keys{$table_name} = [];
    $tables_unique_keys{$table_name} = [];
    my @table_keys = $create_defined{$table_name} =~ /(`.+UNIQUE.+|`.+PRIMARY KEY|.+KEY.+\)|.+INDEX.+\)|.+UNIQUE.+\))/g;
    foreach my $key (@table_keys) {
      $key =~ s/^\s+//;
      push @{$tables_keys{$table_name}}, $key;

      next;
      # $key =~ s/^\s+//;
      # $key =~ /`(.*?)`/;
      # push @{$tables_keys{$table_name}}, $1 if $1;
      # if ($key =~ /UNIQUE KEY/ || $key =~ /PRIMARY KEY/ || $key =~ /KEY/ || $key =~ /INDEX/) {
      #   my @all_keys = $key =~ /(`\w+`)/g;
      #
      #   foreach my $key_ (@all_keys) {
      #     $key_ =~ /`(.*?)`/;
      #     push @{$tables_unique_keys{$table_name}}, $1 if $1;
      #   }
      # }
    }
  }

  return 1;
}

#**********************************************************
=head2 get_table_keys_from_files()

=cut
#**********************************************************
sub check_table_keys {
  my ($table_name, $sql_table) = @_;

  my @db_keys;
  foreach my $column (keys %{$sql_table->{columns}}) {
    if ($sql_table->{columns}{$column}{_raw}{Key}) {
      push @db_keys, $column;
    }
  }

  print "Keys in table `" . lc $table_name . "` in file:\n";
  foreach my $key (@{$tables_keys{$table_name}}) {
    print "\t`$key`\n";
  }

  print "\nKeys in table `" . lc $table_name . "` in DB:\n";
  foreach my $key (@db_keys) {
    print "\t`$key`\n";
  }

  print "\n";

  #  #Not exist keys
  #  foreach my $key (@{$tables_keys{$table_name}}) {
  #    if (!in_array($key, \@db_keys)) {
  #      print "Table`" . lc $table_name . "` has no index `$key`\n";
  #    }
  #  }
  #
  #  #Custom keys
  #  foreach my $key (@db_keys) {
  #    if (!in_array($key, $tables_keys{$table_name}) && !in_array($key, $tables_unique_keys{$table_name})) {
  #      print "Table`" . lc $table_name . "` has custom index `$key`\n";
  #    }
  #  }

  return 1;
}

#**********************************************************
=head2 update_config_variables()

  Update config variables from db/config_variables.sql

=cut
#**********************************************************
sub update_config_variables {
  my $ok = 'n';
  if ($argv->{APPLY_ALL} || defined($argv->{'-a'})) {
    $ok = 'y';
  } else {
    print "\nDo you want reload config variables?\n";
    print "Apply? (y/N): ";
    chomp($ok = <STDIN>);
  }

  if (lc($ok) eq 'y') {
    my $content = '';
    if (open(my $fh, '<', $libpath . 'db/config_variables.sql')) {
      while (<$fh>) {
        $content .= $_;
      }
      close($fh);
    }

    if ($content) {
      eval { $Admin->query('TRUNCATE TABLE config_variables;', 'do', {}); };
      eval { $Admin->query($content, 'do', {}) };
      if ($@) {
        print "\nABORTED! Error has occured with config variables loading.\n";
      } else {
        print "\nConfig variables reloaded successfully.\n";
      }
    } else {
      print "Config variables not found!\n";
    }
  } else {
    print "Skipped\n";
  }
}

1;