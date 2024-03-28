package Confcontrol;

use strict;
use warnings FATAL => 'all';
use parent qw(dbcore);

my $MODULE = 'Conf_Control';

use POSIX;

my $files_table_name = 'confcontrol_controlled_files';
my $stats_table_name = 'confcontrol_stats';

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
=head2 controlled_files_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub controlled_files_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = '';

  $WHERE = $self->search_former($attr, [
    [ 'ID', 'INT', 'id', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'PATH', 'STR', 'path', 1 ],
    [ 'COMMENTS', 'STR', 'comments', 1 ],

  ],
    {
      WHERE => 1
    }
  );

  if ($attr->{SHOW_ALL_COLUMNS}) {
    $self->{SEARCH_FIELDS} = '*,'
  }

  $self->query("SELECT $self->{SEARCH_FIELDS} id FROM $files_table_name $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 controlled_files_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub controlled_files_count {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  $WHERE = $self->search_former($attr, [
    [ 'ID', 'INT', 'id', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'PATH', 'STR', 'path', 1 ],
  ],
    {
      WHERE => 1
    }
  );

  if ($attr->{SHOW_ALL_COLUMNS}) {
    $self->{SEARCH_FIELDS} = '*,'
  }

  $self->query("SELECT COUNT(*) id FROM $files_table_name $WHERE", undef, $attr);

  return 0 unless $self->{list};

  return $self->{list}->[0] || [];
}


#**********************************************************
=head2 controlled_files_info($id)

  Arguments:
    $id - id for controlled_files

  Returns:
    hash_ref

=cut
#**********************************************************
sub controlled_files_info {
  my $self = shift;
  my ($id) = @_;

  $self->query(" SELECT *
    FROM $files_table_name ft LEFT JOIN $stats_table_name st ON (st.file_id=ft.id)
    WHERE id= ?
     ", undef, { Bind => [ $id ], COLS_NAME => 1, COLS_UPPER => 1 }
  );

  my $info = $self->{list};

  return undef if !defined $info;
  return $info->[0];
}

#**********************************************************
=head2 controlled_files_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub controlled_files_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add($files_table_name, $attr);

  return 1;
}

#**********************************************************
=head2 controlled_files_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub controlled_files_del {
  my $self = shift;
  my ($attr) = @_;

  $attr->{ID} = $attr->{del} || return 0;

  $self->query_del($files_table_name, $attr);

  return 1;
}

#**********************************************************
=head2 controlled_files_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub controlled_files_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => $files_table_name,
    DATA         => $attr,
  });

  return 1;
}

#**********************************************************
=head2 stats_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub stats_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = '';

  $WHERE = $self->search_former($attr, [
    [ 'ID', 'INT', 'ccf.id', 1 ],
    [ 'NAME', 'STR', 'ccf.name', 1 ],
    [ 'PATH', 'STR', 'ccf.path', 1 ],
    [ 'LAST_CHANGE', 'DATE', 'ccs.last_chg', 1 ],
    [ 'CRC', 'STR', 'ccs.crc', 1 ],
  ],
    {
      WHERE => 1
    }
  );

  if ($attr->{SHOW_ALL_COLUMNS}) {
    $self->{SEARCH_FIELDS} = '*,'
  }

  $self->query("SELECT $self->{SEARCH_FIELDS} id
   FROM $stats_table_name ccs
      LEFT JOIN $files_table_name ccf ON (ccf.id=ccs.file_id)
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 stats_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub stats_last_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  $WHERE = $self->search_former($attr, [
    [ 'ID', 'INT', 'ccf.id', 1 ],
    [ 'NAME', 'STR', 'ccf.name', 1 ],
    [ 'PATH', 'STR', 'ccf.path', 1 ],
    [ 'LAST_CHANGE', 'DATE', 'ccs2.mtime', 1 ],
    [ 'CRC', 'STR', 'ccs2.crc', 1 ],
  ],
    {
      WHERE => 1
    }
  );

  $self->query("
SELECT ccf.id AS id, ccf.path, ccf.name, ccs2.mtime, ccs2.crc, UNIX_TIMESTAMP(ccs2.mtime) AS last_mtime
FROM (SELECT file_id, MAX(mtime) AS mtime FROM confcontrol_stats ccs1 GROUP BY file_id) ccs1
  LEFT JOIN confcontrol_stats ccs2 ON (ccs2.file_id = ccs1.file_id AND ccs1.mtime=ccs2.mtime)
  LEFT JOIN confcontrol_controlled_files ccf ON (ccf.id=ccs2.file_id)
 $WHERE"
    , undef, { COLS_NAME => 1, %{$attr ? $attr : {}} });

  return $self->{list} || [];
}


#**********************************************************
=head2 stats_info($id)

  Arguments:
    $id - id for stats

  Returns:
    hash_ref

=cut
#**********************************************************
sub stats_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->stats_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************
=head2 stats_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub stats_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{LAST_MTIME}) {
    $attr->{MTIME} = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($attr->{LAST_MTIME}));
  }

  $self->query_add($stats_table_name, $attr);

  return 1;
}

#**********************************************************
=head2 stats_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub stats_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del($stats_table_name, $attr);

  return 1;
}

#**********************************************************
=head2 stats_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub stats_change {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{LAST_MTIME}) {
    $attr->{MTIME} = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($attr->{LAST_MTIME}));
  }

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => $stats_table_name,
    DATA         => $attr,
  });

  return 1;
}



1;