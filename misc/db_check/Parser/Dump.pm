package Parser::Dump;
use strict;
use warnings FATAL => 'all';

use autodie;
use v5.16;

BEGIN {
  use AXbills::Misc;
  use AXbills::PModules qw(load_perl_module);

  load_perl_module('SQL::Translator');
  load_perl_module('Parser::Dump::MySQL');
}

use AXbills::Base qw/_bp/;
use AXbills::Experimental;

use Data::Dumper;

my $debug = 0;

my $translator_main = SQL::Translator->new(
  #    debug => 1,
  #    trace               => 1,
  parse_mysql_version => '5.7',
);

# Accumulated
my %table_info = ();
my %alter_defined = ();

#**********************************************************
=head2 parse($file, $attr) -

  Arguments:
    $file - filepath or directory
    $attr - hash ref
      CACHED - read from cached file. treats $file as Dumper structure
    
  Returns:
    $parsed_info - hash_ref
      table_name => {
        columns => {
          col1 => {
            Type    => type1,
            Null    => 'No',
            Default => 'default'
          }
        },
        ...
        file => $file - file table was defined
      },
      ...
    
=cut
#**********************************************************
sub parse {
  my ($file, $attr) = @_;

  if (!-e $file) {
    return 0;
  }

  # Clear cache
  renew_translator();

  parse_accumulate($file);
  my $res = get_accumulated($attr);

  # Clear cache
  renew_translator();

  return $res;
}

#**********************************************************
=head2 parse_accumulate($files_list, $attr)

  Arguments:
    $files_list
    $attr

=cut
#**********************************************************
sub parse_accumulate {
  my ($file, $attr) = @_;

  my @files_list = (-d $file) ? sort @{main::_get_files_in($file, { FULL_PATH => 1, FILTER => '\.sql$' })} : ($file);
  my %FINDED_MODULES = ();

  foreach my $filepath (@{files_list}) {
    next if ($filepath =~ /Multidoms\.sql/);

    my (undef, $sql_file) = split('db\/', $filepath);
    my ($module_name, undef) = split('\.', $sql_file);
    $FINDED_MODULES{$module_name} = 1;

    if ($attr->{MODULE_DB}) {
      if ($module_name && $sql_file && (-e $attr->{MODULE_DB} . $module_name . '/' . $sql_file)) {
        $filepath = $attr->{MODULE_DB} . $module_name . '/' . $sql_file;
      }
    }

    print "Parsing $filepath \n" if ($debug);

    my $content = get_file_content($filepath);

    filter_alter($content, \%alter_defined);
    $content =~ s/^ALTER TABLE (.*?);$//gms;

    next if (!$content);

    Parser::Dump::MySQL::parse($translator_main, $content, { SKIP_DUPLICATE_CREATE => 1 });
  }

  if ($attr->{ALL_MODULES} && ref $attr->{ALL_MODULES} eq 'ARRAY' && $attr->{MODULE_DB}) {
    foreach my $module (@{$attr->{ALL_MODULES}}) {
      next if ($FINDED_MODULES{$module} || !$module);

      if (-e $attr->{MODULE_DB} . $module . '/' . $module . '.sql') {
        $module = $attr->{MODULE_DB} . $module . '/' . $module . '.sql';
        print "Parsing $module \n" if ($debug);

        my $content = get_file_content($module);

        filter_alter($content, \%alter_defined);
        $content =~ s/^ALTER TABLE (.*?);$//gms;

        next if (!$content);

        Parser::Dump::MySQL::parse($translator_main, $content, { SKIP_DUPLICATE_CREATE => 1 });
      }
    }
  }

  if ($attr->{SAVE_TO}) {
    if (open(my $fh, '>', $attr->{SAVE_TO})) {
      require Data::Dumper;
      print $fh Data::Dumper::Dumper(get_accumulated());
    }
  }

  #return 1;
}

#**********************************************************
=head2 get_accumulated()

  Arguments:
     $attr -
       USE_CACHE - gives function hash_ref for tables defined in cache
    
  Returns:
    \%table_info - information for tables in schema parsed earlier
    
=cut
#**********************************************************
sub get_accumulated {
  my ($attr) = @_;

  my SQL::Translator::Schema $schema = $translator_main->schema;
  my @tables = $schema->get_tables;

  if ($attr->{USE_CACHE}) {
    %table_info = (%table_info, %{$attr->{USE_CACHE}});
  }

  foreach (@tables) {
    my SQL::Translator::Schema::Table $table = $_;
    my $name = $table->name;

    my %parsed = (columns => _parse_columns($table));

    # Checking tables wath created in db/update
    if (exists $table_info{$name}) {
      if (exists $alter_defined{$name}) {
        foreach my $new_column (keys %{$alter_defined{$name}->{columns}}) {
          $parsed{columns}->{$new_column} = $alter_defined{$name}->{columns}{$new_column};
        }
      }
    }
    else {
      $table_info{$name} = \%parsed;
    }
  }

  foreach my $table_name (sort keys %alter_defined) {

    print " Found `$table_name` in alter defined \n" if ($debug);

    my @alter_columns = keys %{$alter_defined{$table_name}->{columns}};
    foreach my $new_col_name (@alter_columns) {

      print " Checking $table_name.$new_col_name \n" if ($debug);

      # Exists in alter but not in original create
      if (!exists $table_info{$table_name}->{columns}{$new_col_name}) {

        print "  Wrong CREATE definition for $table_name.$new_col_name\n" if ($debug);
        print "   `$new_col_name` exists in alter but not in original create \n" if ($debug);

        # Save to main hash
        $table_info{$table_name}->{columns}->{$new_col_name}
          = $alter_defined{$table_name}->{columns}->{$new_col_name};
      }

    } # Foreach end

  }

  return \%table_info;
}

#**********************************************************
=head2 parse_statement($statement)

  Arguments:
    $statement -
    
  Returns:
    hash_ref
    
=cut
#**********************************************************
sub parse_statement {
  my ($statement) = @_;

  # parse statement
  my %single_statement_table_info = ();

  my $translator = SQL::Translator->new(
    #    debug => 1,
    #    trace               => 1,
    # to quote or not to quote, thats the question
    quote_identifiers   => 1,
    # Validate schema object
    #    validate            => 1,
    parse_mysql_version => '5.7',
  );

  if (!Parser::Dump::MySQL::parse($translator, $statement)) {
    return 0;
  }

  my SQL::Translator::Schema $schema = $translator->schema;
  my @tables = $schema->get_tables;

  foreach (@tables) {
    my SQL::Translator::Schema::Table $table = $_;
    my $name = $table->name;
    $single_statement_table_info{$name} = { columns => _parse_columns($table) };
  }

  return \%single_statement_table_info;
}

#**********************************************************
=head2 _parse_columns($table) - parses SQL::Translator::Table to desired format

=cut
#**********************************************************
sub _parse_columns {
  # http://search.cpan.org/~ilmari/SQL-Translator-0.11021/lib/SQL/Translator/Schema/Table.pm
  my SQL::Translator::Schema::Table $table = shift;
  my %columns = ();

  my @fields = $table->get_fields;
  foreach (@fields) {
    my SQL::Translator::Schema::Field $field = $_;
    #http://search.cpan.org/~ilmari/SQL-Translator-0.11021/lib/SQL/Translator/Schema/Field.pm
    #    _bp('', $_);
    my $name = $field->name;
    my $type = lc $field->data_type;
    my $size = $field->size;

    $type = 'int' if (lc $type eq 'integer');

    my $type_str = $type . (
      $type !~ /text|blob/i
        ? ($size ? "($size)" : '')
        : ''
    );

    #    _bp('', $_, {EXIT => 1, TO_CONSOLE => 1});

    if (exists $field->{extra} && exists $field->{extra}->{unsigned} && $field->{extra}->{unsigned}) {
      $type_str .= ' unsigned';
    }

    if (exists $field->{extra} && exists $field->{extra}->{zerofill} && $field->{extra}->{zerofill}) {
      $type_str .= ' zerofill';
    }

    if (exists $field->{is_auto_increment} && $field->{is_auto_increment}) {
      $type_str .= ' auto_increment';
    }

    if (exists $field->{extra} && exists $field->{extra}{list} && $field->{extra}{list} && ref $field->{extra}{list} eq 'ARRAY') {
      $type_str = $type . "(\'" . join('\',\'', @{$field->{extra}{list}}) . "\')";
    }

    my %column = (
      Type => lc $type_str,
    );

    if ($field->is_nullable) {
      $column{Null} = 'Yes';
    }
    elsif ($type !~ /text|blob/i) {
      $column{Null} = 'No';
    }

    if (defined $field->default_value) {
      $column{Default} = $field->default_value;
    }

    $column{_raw} = $field;
    delete $field->{table};

    $columns{$name} = \%column;
  }

  return \%columns;
}


#**********************************************************
=head2 read_from_file($filepath, $attr)

=cut
#**********************************************************
sub read_from_file {
  my ($filepath) = @_;

  our $VAR1;
  require $filepath;

  return $VAR1;
}

#**********************************************************
=head2 set_debug()

=cut
#**********************************************************
sub set_debug {
  $debug = shift || 1;
}

#**********************************************************
=head2 renew_translator() - clear cache

=cut
#**********************************************************
sub renew_translator {
  $translator_main = SQL::Translator->new(
    #    debug => 1,
    #    trace               => 1,
    parse_mysql_version => '5.7',
  );

  %table_info = ();
  %alter_defined = ();
}

#**********************************************************
=head2 _print_debug_content($str) - prints with

=cut
#**********************************************************
sub _print_debug_content {
  my $i = 1;
  map {print $i++ . " : " . $_ . "\n"} split("\n", shift || '');

  return 1;
}

#**********************************************************
=head2 get_file_content($filepath)

=cut
#**********************************************************
sub get_file_content {
  my $filepath = shift;
  # Read file
  my $content = '';

  open(my $fh, '<', $filepath);
  while (<$fh>) {
    $_ = "\n" if ($_ =~ /(?:REPLACE|INSERT|SET SESSION|COMMIT).*;/);
    $_ = "\n" if ($_ =~ /^DELIMITER/);
    $content .= $_;
  }

  $content =~ s/^CREATE FUNCTION(.*?) END\|$//gms;
  $content =~ s/^CREATE UNIQUE(.*?);\s?$//gms;
  $content =~ s/^CREATE INDEX(.*?);\s?$//gms;
  $content =~ s/^REPLACE INTO(.*?);\s?$//gms;
  $content =~ s/^INSERT INTO(.*?);\s?$//gms;
  $content =~ s/^UPDATE(.*?);\s?$//gms;
  $content =~ s/^DELETE(.*?);\s?$//gms;
  $content =~ s/\,\s*FOREIGN KEY \(\`.*\`\) REFERENCES \`.*\` \(\`.*?\`\)(?: ON  ?(?:UPDATE|DELETE) ?(?:CASCADE|DELETE|RESTRICT))?//g;
  $content =~ s/\,\s*FOREIGN KEY(.*) ?(?:DELETE)? (?:CASCADE|DELETE|RESTRICT)//gms;

  $content =~ s/DEFAULT NOW\(\)/DEFAULT NOW/gms;

  if ($content !~ /CREATE TABLE/) {
    return ''
  }

  _print_debug_content($content) if ($debug > 3);

  return $content;
}

#**********************************************************
=head2 filter_alter(\$content, \%alter_defined)

=cut
#**********************************************************
sub filter_alter {
  my ($content, $alter_defined) = @_;

  # Get all alter rows
  if ($content =~ /^ALTER TABLE/) {
    my @alter = $content =~ /ALTER TABLE \`?(\w+)\`?\s* *ADD(?: COLUMN)? \`?(\w+)\`? (.*);$/gm;

    # Split to ($table, $column, $definition)
    while (@alter) {
      my ($table, $column, $definition) = (shift @alter, shift @alter, shift @alter);
      my $col = parse_field_definition($definition);

      $alter_defined->{$table}->{columns}->{$column} = $col;
    }
  }

}
#**********************************************************
=head2 parse_field_definition($field)

=cut
#**********************************************************
sub parse_field_definition {
  my ($definition) = @_;

  my $dummy_create = qq{
    CREATE TABLE `dummy`(
        `dummy_column` $definition
     );
  };

  my $dummy_table_info = parse_statement($dummy_create);

  return $dummy_table_info->{dummy}->{columns}->{dummy_column};
}

1;