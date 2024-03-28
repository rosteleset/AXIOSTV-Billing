package GPS;
=head1 NAME

GPS - module for DB support `gps_locations` table

=head1 VERSION

  Version 1.02

=head1 SYNOPSIS


=cut

use strict;
use POSIX qw(strftime);
use Admins;

use Time::Local qw(timelocal);
use AXbills::Base qw/days_in_month date_inc/;

our $VERSION = 1.03;
use parent qw(dbcore);

my $admin;

# Singleton reference;
my $instance;

#**********************************************************
=head2 new

Instantiation of singleton db object

=cut
#**********************************************************
sub new {

  unless (defined $instance) {
    my $class = shift;
    my ($db) = shift;
    $admin = shift;
    my $CONF = shift;

    my $self = {};
    bless($self, $class);
    $self->{db} = $db;
    $self->{admin} = $admin;
    $self->{conf} = $CONF;

    $instance = $self;

    #$Admins = Admins->new( $db, $CONF );
    #$Admins->info( $CONF->{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1', SHORT => 1 } );
  }

  return $instance;
}

#**********************************************************
=head2 - location_add

=cut
#**********************************************************
sub location_add {
  my $self = shift;
  my ($attr) = @_;

  #All entities has autoincrement ID. If it was passed here that would cause error writing to DB
  delete $attr->{ID};

  # Revert X and Y coordinates due to ABillS DB specific
  my $coordx = $attr->{COORD_X};
  $attr->{COORD_X} = $attr->{COORD_Y};
  $attr->{COORD_Y} = $coordx;

  if ($attr->{GPS_TIME}) {
    $attr->{GPS_TIME} = POSIX::strftime('%F %T', localtime($attr->{GPS_TIME}));
  }

  $self->query_add('gps_tracker_locations', $attr);

  return $self;
}

#**********************************************************
=head2 - location_info

=cut
#**********************************************************
sub location_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',       'INT',  'gtl.id',              1 ],
    [ 'AID',      'INT',  'gtl.aid',             1 ],
    [ 'GPS_TIME', 'DATE', 'gtl.gps_time',        1 ],
    [ 'COORD_X',  'INT',  'gtl.coord_x',         1 ],
    [ 'COORD_Y',  'INT',  'gtl.coord_y',         1 ],
    [ 'SPEED',    'INT',  'gtl.speed',           1 ],
    [ 'ALTITUDE', 'INT',  'gtl.altitude',        1 ],
    [ 'BEARING',  'INT',  'gtl.bearing',         1 ],
    [ 'BATTERY',  'INT',  'gtl.batt AS battery', 1 ],
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} gtl.id
      FROM gps_tracker_locations gtl
      $WHERE ORDER BY gtl.gps_time DESC LIMIT 1;",
    undef,
    $attr
  );

  my $list = $self->{list};
  return $list;
}

#**********************************************************
=head2 - location_list

=cut
#**********************************************************
sub locations_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} ? $attr->{SORT} : 'gtl.gps_time';
  my $DESC = $attr->{DESC} ? 'DESC' : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 10000;

  my $WHERE = '';

  # Additional search expression if filtering time interval
  my $WHERE_TIME = '';

  if ($attr->{GPS_TIME} && ref($attr->{GPS_TIME}) eq 'HASH') {
    my $date = $attr->{GPS_TIME}->{DATE};
    my $from_time = $attr->{GPS_TIME}->{FROM_TIME};
    my $to_time = $attr->{GPS_TIME}->{TO_TIME};

    delete $attr->{GPS_TIME};

    $WHERE_TIME = " gtl.gps_time BETWEEN TIMESTAMP('$date $from_time:00')
    AND TIMESTAMP('$date $to_time:59') ";
  }

  my $search_columns = [
    [ 'ID',                'INT',  'gtl.id',                                            1 ],
    [ 'AID',               'INT',  'gtl.aid',                                           1 ],
    [ 'GPS_TIME',          'DATE', 'gtl.gps_time',                                      1 ],
    [ 'GPS_DATE',          'DATE', 'DATE_FORMAT(gtl.gps_time, "%Y-%m-%d") AS gps_date', 1 ],
    [ 'COORD_X',           'INT',  'gtl.coord_x',                                       1 ],
    [ 'COORD_Y',           'INT',  'gtl.coord_y',                                       1 ],
    [ 'SPEED',             'INT',  'gtl.speed',                                         1 ],
    [ 'ALTITUDE',          'INT',  'gtl.altitude',                                      1 ],
    [ 'BEARING',           'INT',  'gtl.bearing',                                       1 ],
    [ 'BATTERY',           'INT',  'gtl.batt AS battery',                               1 ],
    [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(gtl.gps_time, '%Y-%m-%d')"                ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]}} @$search_columns;
  }

  $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  # Glue for two search expressions
  my $WHERE_CONCAT = ($WHERE ne '' && $WHERE_TIME ne '') ? ' AND ' :(($WHERE_TIME ne '') ? "WHERE" : '');

  $self->query("SELECT $self->{SEARCH_FIELDS} gtl.id
      FROM gps_tracker_locations gtl
      $WHERE $WHERE_CONCAT $WHERE_TIME ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 - location_del

=cut
#**********************************************************
sub location_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('gps_tracker_locations', undef, $attr);
  return 1;
}

#**********************************************************
=head2

  Returns a list of admins who has attached gps_tracker;

=cut
#**********************************************************
sub tracked_admins_list {
  my $self = shift;

  my ($admin_id) = @_;

  my $list_options = { COLS_NAME => 1, GPS_IMEI => '!' };

  if ($admin_id) {
    $list_options->{AID} = $admin_id;
  }

  return $admin->list($list_options);
};

#**********************************************************
=head2

  Returns last row from gps_tracker_locations for given AID;

  Arguments
    $attr - hash_ref
      AID - admin ID

=cut
#**********************************************************
sub tracked_admin_info {
  my $self = shift;
  my ($admin_id) = @_;

  my $location = $self->location_info({
    AID       => $admin_id,
    BATTERY   => '_SHOW',
    GPS_TIME  => '_SHOW',
    COORD_X   => '_SHOW',
    COORD_Y   => '_SHOW',
    COLS_NAME => 1,
    DESC      => 1
  });

  return ref $location eq 'ARRAY' ? $location->[0] : 0;
};


#**********************************************************
=head2 tracked_admin_route_info($aid, $date, $attr)

  Returns route of admin for given date

  Arguments:
    $aid  - Administrator id
    $date - date for routes to show. If you need a period, use $attr parameters. Default to $DATE
    $attr
      DATE_START - Date in YYYY-MM-DD format
      DATE_END   - Date in YYYY-MM-DD format

  Returns:
    hash_ref
      list - array of points if some
      admin - hash_ref for admin info

    0 - if no points

=cut
#**********************************************************
sub tracked_admin_route_info {
  my ($self, $aid, $date, $attr) = @_;

  return 0 if !$aid;

  $self->locations_list({ (
    AID                 => $aid,
    COLS_NAME           => 1,
    BATTERY             => '_SHOW',
    'FROM_DATE|TO_DATE' => ($attr->{FROM_DATE} && $attr->{TO_DATE}) ? "$attr->{FROM_DATE}|$attr->{TO_DATE}" : '_SHOW',
    SHOW_ALL_COLUMNS    => 1,
    PAGE_ROWS           => 86400,
    %{$attr}
  ), });

  return $self->{list} || 0;
}


#**********************************************************
=head2 - tracked_admin_id_by_imei

=cut
#**********************************************************
sub tracked_admin_id_by_imei {
  my $self = shift;
  my ($gps_id) = @_;

  $self->query("SELECT a.aid FROM admins a WHERE a.gps_imei= ?", undef,
    { Bind => [ $gps_id ], COLS_NAME => 1, INFO => 1 });

  return $self->{errno} ? 0 : $self->{list}[0]->{aid};
}

#**********************************************************
=head2

=cut
#**********************************************************
sub thumbnail_add {
  my $self = shift;
  my ($attr) = (@_);

  my $aid = $attr->{AID};
  my $thumnail_path = $attr->{THUMBNAIL_PATH};

  $self->query_add("gps_admins_thumbnails", {
    AID            => $aid,
    THUMBNAIL_PATH => $thumnail_path
  });

  return $self->{errno} ? 0 : 1;
}

#**********************************************************
=head2 thumbnail_get($aid)

  Arguments:
    $aid - Administrator ID

  Returns:
    string - path to file if exists, 0 otherwise

=cut
#**********************************************************
sub thumbnail_get {
  my $self = shift;
  my ($aid) = (@_);

  $self->query("SELECT thumbnail_path FROM gps_admins_thumbnails WHERE aid= ? ", undef,
    { Bind => [ $aid ], COLS_NAME => 1 });

  my $list = $self->{list};

  return $list && scalar @{$list} == 1 ? @{$list}[0]->{thumbnail_path} : 0;
}

#**********************************************************
=head2 thumbnail_del($aid)

  Arguments:
    $aid - Administrator ID for thumbnail to delete

  Returns:
    1

=cut
#**********************************************************
sub thumbnail_del {
  my $self = shift;
  my ($aid) = (@_);

  $self->query_del("gps_admins_thumbnails", undef, { AID => $aid });

  return 1;
}


#**********************************************************
=head2 - unregistered_trackers_add($attr)

=cut
#**********************************************************
sub unregistered_trackers_add {
  my ($self, $attr) = @_;

  $attr->{GPS_TIME} = POSIX::strftime('%F %T', localtime());

  $self->query_add('gps_unregistered_trackers', $attr, { REPLACE => 1 });

  return 1;
}


#**********************************************************
=head2 - unregistered_trackers_del

=cut
#**********************************************************
sub unregistered_trackers_del {
  my ($self, $attr) = @_;

  my $gps_imei = $attr->{GPS_IMEI};

  $self->query_del('gps_unregistered_trackers', undef, { "GPS_IMEI" => $gps_imei });

  return 1;
}


#**********************************************************
=head2 - unregistered_trackers_list

=cut
#**********************************************************
sub unregistered_trackers_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *, INET_NTOA(gut.ip) as ip FROM gps_unregistered_trackers gut ORDER BY gut.gps_time",
    undef, $attr
  );

  my $list = $self->{list};
  $list = $self->check_unregistered($list);

  return $list;
}

#**********************************************************
=head2 check_unregistered($unregistered_list)

  Routine to check if any unregistered trackers were registered and so need to be deleted from unregistered trackers table

=cut
#**********************************************************
sub check_unregistered {
  my ($self, $unregistered_list) = @_;

  my @new_list = ();
  my $i = 0;
  foreach my $tracker (@{$unregistered_list}) {
    $i++;
    if ($self->tracked_admin_id_by_imei($tracker->{gps_imei})) {
      $self->unregistered_trackers_del({ GPS_IMEI => $tracker->{gps_imei} });
    }
    else {
      push @new_list, $tracker;
    }
  }

  return \@new_list;
}

#**********************************************************
=head2 - unregistered_trackers_info($attr)

=cut
#**********************************************************
sub unregistered_trackers_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'IP', 'INT', 'INET_NTOA(gut.ip)' ],
    [ 'GPS_IMEI', 'STR', 'gut.gps_imei', ],
    [ 'GPS_TIME', 'DATE', 'gut.gps_time', ],
  ], { WHERE => 1 });

  $self->query("SELECT * FROM gps_unregistered_trackers gut $WHERE ORDER BY gut.gps_time LIMIT 1", undef, $attr);

  return $self->{list}->[0];
}

#**********************************************************
=head2 admins_color_add($attr)

=cut
#**********************************************************
sub admins_color_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('gps_admins_color', $attr);

  return $self;
}

#**********************************************************
=head2 admins_color_info($attr)

=cut
#**********************************************************
sub admins_color_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM gps_admins_color WHERE aid=$attr->{AID}", undef,{ INFO => 1 });

  return $self;
}

#**********************************************************
=head2 admins_color_change($attr)

=cut
#**********************************************************
sub admins_color_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'gps_admins_color',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 admins_show_change

=cut
#**********************************************************
sub admins_show_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE gps_admins_color SET show_admin=0 WHERE id>0;", undef);
  my @admins = split(/, /, $attr->{AIDS});
  foreach my $aid (@admins) {
    $self->admins_color_info({ AID => $aid });

    if (!$self->{TOTAL}) {
      $self->admins_color_add({
        AID   => $aid,
        COLOR => "#0000ff",
      });
    }
    else {
      $self->query("UPDATE gps_admins_color SET show_admin=1 WHERE aid=$aid;");
    }
  }

  return $self;
}

1;

