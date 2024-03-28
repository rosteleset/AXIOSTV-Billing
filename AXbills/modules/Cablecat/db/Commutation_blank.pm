package Commutation_blank;

=head2

  Commutation_blank

=cut

use strict;
use parent 'dbcore';
use warnings;


#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {};
  $self->{admin} = $admin;
  $self->{conf} = $CONF;
  bless($self, $class);

  $self->{db} = $db;

  return $self;
}

#**********************************************************
=head2 select_cable_types($attr) - list of cable_types

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub select_cable_types {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT id, color_scheme_id, fibers_count, modules_count, modules_color_scheme_id
    FROM cablecat_cable_types WHERE id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_cable($attr) - list of cable

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub select_cable {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT id, type_id, name FROM cablecat_cables WHERE id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_cross($attr) - list of crosses

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub select_cross {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT cc.id, cc.type_id, cc.name, cct.ports_type_id, cct.ports_count FROM cablecat_crosses cc
    LEFT JOIN cablecat_cross_types cct ON (cc.type_id=cct.id)
    WHERE cc.id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_cross_types($attr) - list of cross_types

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub select_cross_types {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT id, ports_count
    FROM cablecat_cross_types  WHERE id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_splitter($attr) - list of splitters

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub select_splitter {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT id, type_id, color_scheme_id, attenuation FROM cablecat_splitters WHERE id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_splitter_types($attr) - list of splitter_types

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub select_splitter_types {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT id, name, fibers_in, fibers_out
    FROM cablecat_splitter_types WHERE id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_links_info($attr) - list of links

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub select_links_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT element_1_id, element_2_id, fiber_num_1, fiber_num_2, element_1_type, element_2_type
    FROM cablecat_links WHERE commutation_id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{COMMUTATION_ID} ] }
  );

  return $self->{list};
}

#**********************************************************
=head2 select_color_schemes($attr) - list of color schemes

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub select_color_schemes {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT id, colors FROM cablecat_color_schemes WHERE id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_equipment($attr) - list of equipment_type

  Arguments:
    $attr
      ID

  Results:
    Equipment where nas_id = ID;

=cut
#**********************************************************
sub select_equipment {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT ports, model_id FROM equipment_infos WHERE nas_id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_equipment_name($attr) - list of equipment_type

  Arguments:
    $attr
      ID

  Results:
    Equipment modal name where id = ID;

=cut
#**********************************************************
sub select_equipment_name {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT model_name FROM equipment_models WHERE id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_cablecat_commutations($attr) -

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub select_cablecat_commutations {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT connecter_id FROM cablecat_commutations WHERE id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_cablecat_well($attr) -

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub select_cablecat_well {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT name FROM cablecat_wells WHERE id = ?;",
    undef,
    { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0];
}

#**********************************************************
=head2 select_cablecat_well($attr) -

  Arguments:
    $attr
      ID

  Results:

=cut
#**********************************************************
sub get_commutation_elements {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{ID};

  $self->query(
    "SELECT  element_1_id as element_id, element_1_type AS element_type FROM cablecat_links
     WHERE commutation_id=$attr->{ID}
     UNION
     SELECT element_2_id, element_2_type FROM cablecat_links
     WHERE commutation_id=$attr->{ID};",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

1;