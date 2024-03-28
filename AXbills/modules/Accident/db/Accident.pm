package Accident;
=head1 NAME

  Accident - module for Accident log

=head1 SYNOPSIS

  use Accident;
  my $Accident = Accident->new($db, $admin, \%conf);

=cut

use strict;
use parent qw(dbcore);

my ($admin, $CONF);

#*******************************************************************

=head2 new()

=cut

#*******************************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 add() - Add element accident log tables

  Arguments:
     attr - form attribute

  Returns:
    self - result operation

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('accident_log', $attr);

  return $self;
}

#**********************************************************
=head2  del() - Delete accident log tables

 Arguments:
     attr - form attribute

 Returns:
    self - result operation

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('accident_log', undef, $attr);

  return $self->{result};
}

#**********************************************************
=head2 change_element($attr) -  Change element

 Arguments:
     attr - form attribute date

 Returns:
    self - result operation

=cut
#**********************************************************
sub change_element {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'accident_log',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 list ($attr) - list for accident log

 Arguments:
     ID              - Accident id
     PRIORITY        - Accident priority status
     DATE            - Date accident
     STATUS          - Status accident
     NAME            - Accident name
     DESC            - Description
     ADDRESS_ID         - Districts accident
     FROM_DATE          -
     TO_DATE            -
     AID             - Administration id
     END_TIME        - Date end work
     REALY_TIME      - Date end realy work
     STREET             - Street accident
     TYPE_ID            - Address type
     SKIP_STATUS        - Skip status
     BUILD_ID           - Build id
     STREET_ID          - Streat id
     DISTRICT_ID        - District id

 Returns:
    list

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if ($attr->{SKIP_STATUS}) {
    push @WHERE_RULES, "al.status != $attr->{SKIP_STATUS}";
  }

  if ($attr->{BUILD_ID} && $attr->{STREET_ID} && $attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "(ad.type_id = 3 AND ad.address_id = $attr->{STREET_ID})
                        OR (ad.type_id = 1 AND ad.address_id = $attr->{DISTRICT_ID})
                        OR (ad.type_id = 4 AND ad.address_id = $attr->{BUILD_ID})";
  }
  elsif ($attr->{STREET_ID} && $attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "(ad.type_id = 3 AND ad.address_id = $attr->{STREET_ID})
                        OR (ad.type_id = 1 AND ad.address_id = $attr->{DISTRICT_ID})";
  }
  elsif ($attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "ad.type_id = 1 AND ad.address_id = $attr->{DISTRICT_ID}";
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',                      'INT',    'al.id',                  1 ],
      [ 'DATE',                    'DATE',   'al.date',                1 ],
      [ 'NAME',                    'STR',    'al.name',                1 ],
      [ 'DESCR',                   'STR',    'al.descr',               1 ],
      [ 'PRIORITY',                'INT',    'al.priority',            1 ],
      [ 'AID',                     'INT',    'al.aid',                 1 ],
      [ 'STATUS',                  'INT',    'al.status',              1 ],
      [ 'ADDRESS_ID',              'INT',    'ad.address_id',          1 ],
      [ 'END_TIME',                'DATE',   'al.end_time',            1 ],
      [ 'REALY_TIME',              'DATE',   'al.realy_time',          1 ],
      [ 'TYPE_ID',                 'INT',    'ad.type_id',             1 ],
      [ 'FROM_DATE|TO_DATE',       'DATE',   "DATE_FORMAT(al.date, '%Y-%m-%d')", ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} al.id
      FROM accident_log al
   LEFT JOIN admins a ON al.aid = a.aid
   LEFT JOIN districts di ON di.id
   LEFT JOIN accident_address ad ON ad.ac_id = al.id
   LEFT JOIN builds b ON b.id
    $WHERE
    UNION
    SELECT $self->{SEARCH_FIELDS} al.id
      FROM accident_log al
   LEFT JOIN admins a ON al.aid = a.aid
   LEFT JOIN districts di ON di.id
   RIGHT JOIN accident_address ad ON ad.ac_id = al.id
   LEFT JOIN builds b ON b.id
    $WHERE
    GROUP BY al.id
 HAVING AVG(ad.type_id != 4)
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 accident_info ($attr) - 

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
      FROM accident_log
      WHERE id = ?;",
    undef,
    { Bind => [ $id ], COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 accident_address_info ($attr) - 

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_address_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
      FROM accident_address
      WHERE ac_id = ?;",
    undef,
    { Bind => [ $id ], COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 change_address ($attr) - change accident address

 Arguments:

 Returns:

=cut
#**********************************************************
sub change_address {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'AC_ID',
      TABLE        => 'accident_address',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 address_add ($attr) - add accident address

 Arguments:

 Returns:

=cut
#**********************************************************
sub address_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('accident_address', $attr);

  return $self;
}

#**********************************************************
=head2 address_del ($attr) - del accident address

 Arguments:

 Returns:

=cut
#**********************************************************
sub address_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM accident_address WHERE ac_id = ?", 'do', {
    Bind => [ $attr->{ID} ]
  });

  return $self->{result};
}

#**********************************************************
=head2 accident_equipment_add ($attr) - equipment error add

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_equipment_add {
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add('accident_equipments', $attr);
}

#**********************************************************
=head2 accident_equipment_del ($attr) - equipment error del

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_equipment_del {
  my $self = shift;
  my ($attr) = @_;

  return $self->query_del('accident_equipments', $attr);
}

#**********************************************************
=head2 accident_equipment_info ($attr) - equipment error info

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_equipment_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
      FROM accident_equipments
      WHERE id = ?;",
    undef,
    { Bind => [ $id ], COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 accident_equipment_chg () - equipment error change

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_equipment_chg {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'accident_equipments',
      DATA         => $attr,
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 accident_equipment_list ($attr) - equipment error list

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_equipment_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',             'INT',    'ae.id',                          1 ],
      [ 'ID_EQUIPMENT',   'INT',    'ae.id_equipment',                1 ],
      [ 'DATE',           'DATE',   'ae.date',                        1 ],
      [ 'END_DATE',       'DATE',   'ae.end_date',                    1 ],
      [ 'AID',            'INT',    'ae.aid',                         1 ],
      [ 'STATUS',         'INT',    'ae.status',                      1 ],
      [ 'UID',            'INT',    'im.uid',                         1 ],
      [ 'NAS_ID',         'INT',    'im.nas_id',                      1 ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  my $ext_table = '';
  if ($attr->{EXT_TABLE}) {
    $ext_table .= 'LEFT JOIN internet_main AS im ON ae.id_equipment = im.nas_id';
  }

  $self->query("SELECT $self->{SEARCH_FIELDS} ae.id FROM 
                accident_equipments AS ae $ext_table $WHERE ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 accident_compensation ($attr) - 

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_compensation_add {
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add('accident_compensation', $attr);
}

#**********************************************************
=head2 accident_compensation_list ($attr) - 

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_compensation_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',             'INT',    'ac.id',                          1 ],
      [ 'PROCENT',        'INT',    'ac.procent',                     1 ],
      [ 'DATE',           'DATE',   'ac.date',                        1 ],
      [ 'SERVICE',        'INT',    'ac.service',                     1 ],
      [ 'TYPE_ID',        'INT',    'ac.type_id',                     1 ],
      [ 'ADDRESS_ID',     'INT',    'ac.address_id',                  1 ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} ac.id FROM 
                accident_compensation AS ac $WHERE ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 accident_date_compensation ($attr) - 

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_date_compensation {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT 
                SUM(IF( DATEDIFF(al.realy_time, al.date ) <> 0, DATEDIFF(al.realy_time, al.date ), 1 ) ) AS day_log 
                FROM accident_log AS al 
                WHERE al.id =  $id;",
    undef
  );

  my $day = @{$self->{list}}[0];

  return $day;
}

#**********************************************************
=head2 accident_compensation_del ($attr) -

 Arguments:

 Returns:

=cut
#**********************************************************
sub accident_compensation_del {
  my $self = shift;
  my ($attr) = @_;

  return $self->query_del('accident_compensation', $attr);
}

1;