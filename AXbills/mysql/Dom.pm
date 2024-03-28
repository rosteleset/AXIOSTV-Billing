package Dom;
=name2

  Dom

=VERSION

  VERSION = 0.02
=cut

use strict;
use warnings FATAL => 'all';

use parent qw( dbcore );
my $MODULE = 'Dom';

use Dom;

my $admin;
my $CONF;

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
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $admin->{MODULE} = $MODULE;

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 list($attr) - List user info and status

  Arguments:
    $attr

  Returns
    array_of_hash

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();
  my $WHERE = $self->search_former($attr, [
    [ 'FIO', 'STR', 'pi.fio', 1 ],
    [ 'ADDRESS_BUILD', 'INT', 'pi.address_build', 1 ],
    [ 'UID', 'INT', 'pi.uid', 1 ],
    [ 'CITY', 'STR', 'pi.city', 1 ],
    [ 'COMPANY_ID', 'INT', 'u.company_id', 1 ],
    [ 'DISABLE', 'INT', 'u.disable', 1 ],
    [ 'ADDRESS_FLAT', 'STR', 'pi.address_flat', 1 ],
    [ 'LOCATION_ID', 'INT', 'pi.location_id', 1 ],
    [ 'CREDITOR', 'INT', 'creditor', "IF(u.credit>0, 1, 0) AS creditor ", 1 ],
    [ 'DEBETOR', 'INT', 'debetor', "IF(IF(company.id IS NULL, b.deposit, b.deposit)<0, 1, 0) AS debetor", 1 ],
    [ 'ADDRESS_STREET', 'STR', 'pi.address_street', 1 ],
  ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    });
  $self->query("SELECT $self->{SEARCH_FIELDS} pi.email
     FROM users_pi pi
      LEFT JOIN users u ON (pi.uid=u.uid)
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id)
    $WHERE
      GROUP BY pi.uid
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
     FROM users_pi pi
     $WHERE;",
    undef, { INFO => 1 }
  );
  return $list;
}

#**********************************************************
=head2 list_internet($attr) - List user_internet info and status

  Arguments:
    $attr

  Returns
    array_of_hash

=cut
#**********************************************************
sub list_internet {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();
  my $WHERE = $self->search_former($attr, [
    [ 'FIO', 'STR', 'pi.fio', 1 ],
    [ 'ADDRESS_BUILD', 'INT', 'pi.address_build', 1 ],
    [ 'UID', 'INT', 'pi.uid', 1 ],
    [ 'CITY', 'STR', 'pi.city', 1 ],
    [ 'COMPANY_ID', 'INT', 'u.company_id', 1 ],
    [ 'DISABLE', 'INT', 'u.disable', 1 ],
    [ 'ADDRESS_FLAT', 'STR', 'pi.address_flat', 1 ],
    [ 'LOCATION_ID', 'INT', 'pi.location_id', 1 ],
    [ 'CREDITOR', 'INT', 'creditor', "IF(u.credit>0, 1, 0) AS creditor ", 1 ],
    [ 'DEBETOR', 'INT', 'debetor', "IF(IF(company.id IS NULL, b.deposit, b.deposit)<0, 1, 0) AS debetor", 1 ],
    [ 'ADDRESS_STREET', 'STR', 'pi.address_street', 1 ],
  ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    });
  $self->query("SELECT $self->{SEARCH_FIELDS} pi.email
     FROM internet_main im
      LEFT JOIN users_pi pi ON (im.uid = pi.uid)
      LEFT JOIN users u ON (pi.uid=u.uid)
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id)
    $WHERE
      GROUP BY im.uid
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
     FROM internet_main im
      LEFT JOIN users_pi pi ON (im.uid = pi.uid)
     $WHERE;",
    undef, { INFO => 1 }
  );
  return $list;
}

#**********************************************************
=head2 list_iptv($attr) - List user_iptv info and status

  Arguments:
    $attr

  Returns
    array_of_hash

=cut
#**********************************************************
sub list_iptv {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();
  my $WHERE = $self->search_former($attr, [
    [ 'FIO', 'STR', 'pi.fio', 1 ],
    [ 'ADDRESS_BUILD', 'INT', 'pi.address_build', 1 ],
    [ 'UID', 'INT', 'pi.uid', 1 ],
    [ 'CITY', 'STR', 'pi.city', 1 ],
    [ 'COMPANY_ID', 'INT', 'u.company_id', 1 ],
    [ 'DISABLE', 'INT', 'u.disable', 1 ],
    [ 'ADDRESS_FLAT', 'STR', 'pi.address_flat', 1 ],
    [ 'LOCATION_ID', 'INT', 'pi.location_id', 1 ],
    [ 'CREDITOR', 'INT', 'creditor', "IF(u.credit>0, 1, 0) AS creditor ", 1 ],
    [ 'DEBETOR', 'INT', 'debetor', "IF(IF(company.id IS NULL, b.deposit, b.deposit)<0, 1, 0) AS debetor", 1 ],
    [ 'ADDRESS_STREET', 'STR', 'pi.address_street', 1 ],
  ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    });
  $self->query("SELECT $self->{SEARCH_FIELDS} pi.email
     FROM iptv_main im
      LEFT JOIN users_pi pi ON (im.uid = pi.uid)
      LEFT JOIN users u ON (pi.uid=u.uid)
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id)
    $WHERE
      GROUP BY im.uid
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
     FROM iptv_main im
      LEFT JOIN users_pi pi ON (im.uid = pi.uid)
     $WHERE;",
    undef, { INFO => 1 }
  );
  return $list;
}

#**********************************************************
=head2 list_cams($attr) - List user_cams info and status

  Arguments:
    $attr

  Returns
    array_of_hash

=cut
#**********************************************************
sub list_cams {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();
  my $WHERE = $self->search_former($attr, [
    [ 'FIO', 'STR', 'pi.fio', 1 ],
    [ 'ADDRESS_BUILD', 'INT', 'pi.address_build', 1 ],
    [ 'UID', 'INT', 'pi.uid', 1 ],
    [ 'CITY', 'STR', 'pi.city', 1 ],
    [ 'COMPANY_ID', 'INT', 'u.company_id', 1 ],
    [ 'DISABLE', 'INT', 'u.disable', 1 ],
    [ 'ADDRESS_FLAT', 'STR', 'pi.address_flat', 1 ],
    [ 'LOCATION_ID', 'INT', 'pi.location_id', 1 ],
    [ 'CREDITOR', 'INT', 'creditor', "IF(u.credit>0, 1, 0) AS creditor ", 1 ],
    [ 'DEBETOR', 'INT', 'debetor', "IF(IF(company.id IS NULL, b.deposit, b.deposit)<0, 1, 0) AS debetor", 1 ],
    [ 'ADDRESS_STREET', 'STR', 'pi.address_street', 1 ],
  ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    });
  $self->query("SELECT $self->{SEARCH_FIELDS} pi.email
     FROM cams_main im
      LEFT JOIN users_pi pi ON (im.uid = pi.uid)
      LEFT JOIN users u ON (pi.uid=u.uid)
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id)
    $WHERE
      GROUP BY im.uid
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total
     FROM cams_main im
      LEFT JOIN users_pi pi ON (im.uid = pi.uid)
     $WHERE;",
    undef, { INFO => 1 }
  );
  return $list;
}

#**********************************************************
=head2 users_online_by_builds() - show users online by builds

=cut
#**********************************************************
sub users_online_by_builds {
  my $self = shift;

  my $online_list = $self->query("SELECT b.id AS id, u.uid, u.fio, i.status, b.number
    FROM internet_online AS i
    LEFT JOIN users_pi u ON (u.uid=i.uid)
    LEFT JOIN builds AS b ON (b.id=u.location_id)
    GROUP BY u.uid;",
    undef, { COLS_NAME => 1 }
  );

  return $online_list->{list} || [];
}

#**********************************************************
=head2 users_offline_by_builds() - show users offline by builds

=cut
#**********************************************************
sub users_offline_by_builds {
  my $self = shift;

  my $online_list = $self->query("SELECT b.id AS id, up.uid, up.fio, b.number, i.status
    FROM users u
    LEFT JOIN internet_online i ON (i.uid = u.uid)
    LEFT JOIN users_pi up ON (up.uid=u.uid)
    LEFT JOIN builds AS b ON (b.id=up.location_id)
    WHERE i.status IS NULL
    GROUP BY u.uid;",
    undef, { COLS_NAME => 1 }
  );

  return $online_list->{list} || [];
}

#**********************************************************
=head2 streets_list_with_builds($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub streets_list_with_builds {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [ [ 'DISTRICT_ID', 'INT', 'st.district_id', 1 ], ], { WHERE => 1 });

  $self->query("SET SESSION group_concat_max_len = 1000000;", 'do');
  $self->query("SELECT st.id AS street_id, st.name as street_name, st.second_name AS second_name,
    GROUP_CONCAT(DISTINCT CONCAT(b.number, '|', b.id, '|', b.users_count) ORDER BY b.number + 0) as builds_number
    FROM streets st
    LEFT JOIN (
      SELECT b.number as number, b.id as id, b.street_id as street_id, COUNT(pi.uid) AS users_count
      FROM builds b
      LEFT JOIN users_pi pi ON (b.id=pi.location_id)
      GROUP BY b.id
    ) b ON (b.street_id=st.id)
    $WHERE GROUP BY st.id ORDER BY street_name;",
    undef, { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

1