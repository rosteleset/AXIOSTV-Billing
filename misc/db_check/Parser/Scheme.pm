package Parser::Scheme;
use strict;
use warnings FATAL => 'all';

use AXbills::Base qw/_bp/;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    
  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  
  my ($db, $admin, $CONF) = @_;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 parse() - returns info for current DB scheme

  Arguments:
     -
    
  Returns:
    hash_ref
    
=cut
#**********************************************************
sub parse {
  my $self = shift;
  
  return $self->get_tables_struct();
  #  return hash_ref;
}

#**********************************************************
=head2 tables_list() -

    
=cut
#**********************************************************
sub tables_list {
  my $self = shift;
  
  $self->{admin}->query("SHOW TABLES", undef);
  return 0 if ( $self->{admin}->{errno} );
  
  my $tables = $self->{admin}->{list};
  my @tables_list = map {$_->[0]} @{$tables};
  
  return \@tables_list;
}

#**********************************************************
=head2 table_info($table_name) -

  Arguments:
    $table_name -
    
  Returns:
    hash_ref -
    
=cut
#**********************************************************
sub table_info {
  my $self = shift;
  my ($table_name) = @_;
  
  $self->{admin}->query("DESCRIBE `$table_name`;", undef, { COLS_NAME => 1 });
  return 0 if ( $self->{admin}->{errno} );
  
  return _parse_columns($self->{admin}->{list});
}

#**********************************************************
=head2 _parse_columns($table_info) - formats columns to usual format

=cut
#**********************************************************
sub _parse_columns {
  my ($table_info) = @_;
  
  my %table_columns = (
    columns => {}
  );
  
  foreach ( @{ $table_info } ) {
    # Skipping service columns
    next if ( $_->{Field} =~ /^_/ );
  
    my %column = ();
  
    if ( $_->{Null} && $_->{Null} !~ /NO/i ) {
      $column{Null} = 'Yes';
    }
    elsif ( $_->{Type} !~ /text|blob/i ) {
      $column{Null} = 'No';
    }
  
    $column{Type} = lc $_->{Type};
  
    $column{Default} = $_->{Default};# if ( defined $_->{Default} );
    $column{Type} .= ' auto_increment' if ( $_->{Extra} && $_->{Extra} =~ /auto_increment/ );
    
    $column{_raw} = $_;
  
    $table_columns{columns}->{$_->{Field}} = \%column;
  
  };
  
  return \%table_columns;
}

#**********************************************************
=head2 get_tables_struct()

=cut
#**********************************************************
sub get_tables_struct {
  my ($self) = @_;
  
  my %table_info = ();
  
  # Get list of all tables in schema
  my $tables_list = $self->tables_list();
  return 0 unless ( $tables_list );
  
  # For each table, get columns describe
  foreach my $table_name ( @{$tables_list} ) {
    # Skip '_*';
    next if ( $table_name =~ /^\_\w+/ );
    
    $table_info{$table_name} = $self->table_info($table_name);
  }
  
  return \%table_info;
}


1;