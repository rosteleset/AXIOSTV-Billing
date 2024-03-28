package Sms;
=head1 NAME

  Sms  managment functions

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(dbcore);

my $MODULE = 'Sms';
my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;
  my $self = {};

  bless($self, $class);

  $self->{db}=$db;
  $self->{admin}=$admin;
  $self->{conf}=$CONF;

  return $self;
}

#**********************************************************
=head2 info($attr) - Sms status info

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *
     FROM sms_log
   WHERE id = ?;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ]}
  );

  return $self;
}

#**********************************************************
=head2 add($attr) - Add sms log records

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('sms_log', { %$attr });

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'sms_log',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 del(attr) - Del log record

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('sms_log',$attr);

  return $self;
}

#**********************************************************
=head2 list($attr) - Sms log list

=cut
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;

  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }

  my $skip_fields = 'UID';
  if ($attr->{NO_SKIP}) {
    $skip_fields = '';
  }

  my $WHERE =  $self->search_former($attr, [
      ['DATETIME',         'DATE','sms.datetime',               1 ],
      ['SMS_STATUS',       'INT', 'sms.status as sms_status',   1 ],
      ['SMS_PHONE',        'STR', 'sms.phone as sms_phone',     1 ],
      ['MESSAGE',          'STR', 'sms.message',                1 ],
      ['EXT_ID',           'STR', 'sms.ext_id',                 1 ],
      ['EXT_STATUS',       'STR', 'sms.ext_status',             1 ],
      ['STATUS_DATE',      'DATE','sms.status_date',            1 ],
      ['FROM_DATE|TO_DATE','DATE',"DATE_FORMAT(sms.datetime, '%Y-%m-%d')"],
      ['ID',               'INT', 'sms.id'                       ],
    ],
    { WHERE            => 1,
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ $skip_fields ]
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLES};

  $self->query("SELECT
      $self->{SEARCH_FIELDS}
      sms.uid,
      sms.id,
      sms.ext_id
     FROM sms_log sms
     LEFT JOIN users u ON (u.uid=sms.uid)
     $EXT_TABLE
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query("SELECT count( DISTINCT sms.id) AS total FROM sms_log sms
    LEFT JOIN users u ON (u.uid=sms.uid)
    $EXT_TABLE
    $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}


1;
