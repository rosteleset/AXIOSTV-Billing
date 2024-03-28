package Accident;
=head1 NAME

  Accident - module for Accident log

=head1 VERSION

  VERSION: 9.00
  UPDATE: 20212005

=cut

use strict;
use parent qw(dbcore);

my ($admin, $CONF);

our $VERSION = 9.00;
my $MODULE = 'Accident';

#++*****************************************************************
=head2 new()

=cut
#*******************************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = { };
  bless($self, $class);

  $self->{db}    = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

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
  my @domain_id_where = ();

  if ($attr->{SKIP_STATUS}) {
    push @WHERE_RULES, "al.status != '$attr->{SKIP_STATUS}'";
  }

  if ($attr->{BUILD_ID} && $attr->{STREET_ID} && $attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "(ad.type_id = 3 AND ad.address_id = '$attr->{STREET_ID}')
                        OR (ad.type_id = 1 AND ad.address_id = '$attr->{DISTRICT_ID}')
                        OR (ad.type_id = 4 AND ad.address_id = '$attr->{BUILD_ID}')";
  }
  elsif ($attr->{STREET_ID} && $attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "(ad.type_id = 3 AND ad.address_id = '$attr->{STREET_ID}')
                        OR (ad.type_id = 1 AND ad.address_id = '$attr->{DISTRICT_ID}')";
  }
  elsif ($attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "ad.type_id = 1 AND ad.address_id = '$attr->{DISTRICT_ID}'";
  }

  if ($self->{admin}{DOMAIN_ID}) {
    my $admin_domain = $self->{admin}{DOMAIN_ID};
    push @domain_id_where, ("AND di_b.domain_id = '$admin_domain'", "AND di_s.domain_id = '$admin_domain'", "AND di.domain_id = '$admin_domain'");
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

  $self->query("
  SELECT $self->{SEARCH_FIELDS} al.id, al.date, al.name, 
    al.descr, al.priority, al.aid, 
    al.status, ad.address_id, 
    al.end_time, al.realy_time, 
    GROUP_CONCAT(
      CASE
        WHEN ad.type_id= 1 
            THEN di.name
        WHEN ad.type_id= 2 
            THEN di.city
        WHEN ad.type_id= 3 
            THEN CONCAT(di_s.name, ', ', st.name)
        WHEN ad.type_id= 4 
            THEN CONCAT(di_b.name, ', ', st_b.name, ', ', b.number)
        ELSE ''
          END
      SEPARATOR ';'
    ) AS TYPE_IDS   

    FROM accident_log al
        LEFT JOIN admins a ON al.aid = a.aid
        LEFT JOIN accident_address ad ON ad.ac_id = al.id
        LEFT JOIN builds b ON b.id = ad.address_id
        LEFT JOIN streets st_b ON st_b.id = b.street_id
        LEFT JOIN districts di_b ON (di_b.id = st_b.district_id " . ($domain_id_where[0] || '') . " )

        LEFT JOIN streets st ON st.id = ad.address_id
        LEFT JOIN districts di_s ON (di_s.id = st.district_id " . ($domain_id_where[1] || '') . ")

        LEFT JOIN districts di ON (di.id = ad.address_id " . ($domain_id_where[2] || '') . ")
        $WHERE
    GROUP BY id
    HAVING TYPE_IDS <> '';",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 user_accident_list ($attr) - 

 Arguments:

 Returns:

=cut
#**********************************************************
sub user_accident_list {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID} || 0;

  $self->query(
    "SELECT id, name, descr, priority, aid, status, address_id, type_id, uid FROM (
      SELECT al.id as id3, al.name, al.descr, al.priority, al.aid, al.status, ad.address_id, ad.type_id,  al.id,  u.uid
        FROM accident_log al
          LEFT JOIN admins a ON al.aid = a.aid
          LEFT JOIN accident_address ad ON (ad.ac_id = al.id)
          LEFT JOIN districts d ON ((ad.type_id=1 OR ad.type_id=2) AND d.id=ad.address_id)
          LEFT JOIN streets s ON (s.district_id=d.id)
          LEFT JOIN builds b ON (b.street_id=s.id)
          LEFT JOIN users_pi pi ON (pi.location_id=b.id)
          LEFT JOIN users u ON (pi.uid=u.uid)
      WHERE u.uid = ?
      UNION ALL
      SELECT al.id as id1, al.name, al.descr, al.priority, al.aid, al.status, ad.address_id, ad.type_id,  al.id, u.uid
        FROM accident_log al
          LEFT JOIN admins a ON (al.aid = a.aid)
          LEFT JOIN accident_address ad ON (ad.ac_id = al.id)
          LEFT JOIN streets s ON (ad.type_id=3 AND s.id=ad.address_id)
          LEFT JOIN builds b ON (b.street_id=s.id)
          LEFT JOIN users_pi pi ON (pi.location_id=b.id)
          LEFT JOIN users u ON (pi.uid=u.uid)
        WHERE u.uid = ?
        UNION ALL
      SELECT al.id as id2, al.name, al.descr, al.priority, al.aid, al.status, ad.address_id, ad.type_id,  al.id,  u.uid
        FROM accident_log al
          LEFT JOIN admins a ON (al.aid = a.aid)
          LEFT JOIN accident_address ad ON (ad.ac_id = al.id)
          LEFT JOIN builds b ON (ad.type_id=4 AND b.id=ad.address_id)
          LEFT JOIN users_pi pi ON (pi.location_id=b.id)
          LEFT JOIN users u ON (pi.uid=u.uid)
      WHERE u.uid = ?
    ) as user_accident_cabinet
    GROUP BY user_accident_cabinet.id", undef, {
      %{ $attr },
      Bind => [ 
        $uid,
        $uid,
        $uid
      ]
    });

  return $self->{list} || [ ];
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
  my ($id, $type_id) = @_;

  if ($type_id) {
    $self->query("SELECT *
        FROM accident_address
        WHERE ac_id = ? AND type_id = ?;",
      undef,
      { Bind => [ $id, $type_id ], COLS_NAME => 1 }
    );  
  }
  else {
    $self->query("SELECT *
        FROM accident_address
        WHERE ac_id = ?;",
      undef,
      { Bind => [ $id ], COLS_NAME => 1 }
    );
  }

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

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',             'INT',    'ac.id',                          1 ],
      [ 'PROCENT',        'INT',    'ac.procent',                     1 ],
      [ 'DATE',           'DATE',   'ac.date',                        1 ],
      [ 'SERVICE',        'INT',    'ac.service',                     1 ],
      [ 'TYPE_ID',        'INT',    'ac.type_id',                     1 ],
      [ 'ADDRESS_ID',     'INT',    'ac.address_id',                    ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query("
  SELECT $self->{SEARCH_FIELDS} ac.id, ac.date,
  GROUP_CONCAT(
    CASE
      WHEN ac.type_id= 1 
          THEN di.name
      WHEN ac.type_id= 2 
          THEN di.city
      WHEN ac.type_id= 3 
          THEN CONCAT(di_s.name, ', ', st.name)
      WHEN ac.type_id= 4 
          THEN CONCAT(di_b.name, ', ', st_b.name, ', ', b.number)
      ELSE ''
      END
    SEPARATOR ';'
  ) AS ADDRESS_IDS   

    FROM accident_compensation ac
        LEFT JOIN builds b ON b.id = ac.address_id
        LEFT JOIN streets st_b ON st_b.id = b.street_id
        LEFT JOIN districts di_b ON di_b.id = st_b.district_id

        LEFT JOIN streets st ON st.id = ac.address_id
        LEFT JOIN districts di_s ON di_s.id = st.district_id

        LEFT JOIN districts di ON di.id = ac.address_id
        
    GROUP BY id;",
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
                WHERE al.id = ?;",
    undef, {
      Bind => [ $id ]
    }
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
