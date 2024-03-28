package AXbills::SQL;

use strict;

=head2 NAME
 
  SQL Connect engine

=cut

#**********************************************************
=head2 connect($sql_type, $dbhost, $dbname, $dbuser, $dbpasswd, $attr) - Connect to db

=cut
#**********************************************************
sub connect {
  my $class = shift;
  my ($sql_type, $dbhost, $dbname, $dbuser, $dbpasswd, $attr) = @_;

  my $self = { };
  bless($self, $class);
  my $db_engine = 'main';
  if ($attr->{db_engine}) {
    $db_engine = 'dbcore';
  }

  eval { require "$db_engine.pm"; };

  if (! $@) {
    $db_engine->import();
  }
  else {
    print "Module '$sql_type' not supported yet";
  }

  my $sql = $db_engine->connect($dbhost, $dbname, $dbuser, $dbpasswd, $attr);

  $self->{sql_type}  = $sql_type;
  $self->{db}        = $sql->{db};
  $self->{$sql_type} = $sql;
  $self->{dbo}       = $sql;
  if ( $attr->{dbdebug} ) {
  	$self->{db_debug}=$attr->{dbdebug};
  	if ( $attr->{dbdebug} > 10) {
  	  $self->{db}->trace(2);
    }
  }

  return $self;
}

#**********************************************************
=head2 disconnect()

=cut
#**********************************************************
sub disconnect {
 my $self = shift;

 $self->disconnect();

 return $self;
}


1
