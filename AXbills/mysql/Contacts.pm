package Contacts;

=head1 NAME

  Users contacts manage functions

=cut

use strict;
use parent 'dbcore';
use v5.16;
use Conf;
my $admin;
my $CONF;
# my $SORT = 1;
# my $DESC = '';
# my $PG   = 1;
# my $PAGE_ROWS = 25;

our %TYPES = (
  'CELL_PHONE'  => 1,
  'PHONE'       => 2,
  'SKYPE'       => 3,
  'ICQ'         => 4,
  'VIBER'       => 5,
  'TELEGRAM'    => 6,
  'FACEBOOK'    => 7,
  'VK'          => 8,
  'EMAIL'       => 9,
  'GOOGLE PUSH' => 10,
);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db)  = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = '';

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 contacts_list($attr)

  Arguments:
    $attr - hash_ref
      UID
      VALUE
      PRIORITY
      TYPE
      TYPE_NAME

  Returns:
    list

=cut
#**********************************************************
sub contacts_list {
  my $self = shift;
  my ($attr) = @_;

  $self->{errno} = 0;
  $self->{errstr} = '';

  return [] if ( !$attr->{UID} );

  my @search_columns = (
    [ 'UID',       'INT',     'uc.uid'        ,1 ],
    [ 'VALUE',     'STR',     'uc.value'      ,1 ],
    [ 'PRIORITY',  'INT',     'uc.priority'   ,1 ],
    [ 'COMMENTS',  'STR',     'uc.comments'   ,1 ],
    [ 'TYPE',      'INT',     'uc.type_id'    ,1 ],
    [ 'DEFAULT',   'INT',     'uct.is_default',1 ],
    [ 'TYPE_NAME', 'STR',     'uct.name'      ,1 ],
    [ 'HIDDEN',    'INT',     'uct.hidden'       ]
  );

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map {$attr->{$_->[0]} = '_SHOW' unless ( exists $attr->{$_->[0]} )} @search_columns;
  }

  my $WHERE = $self->search_former($attr, \@search_columns,{ WHERE => 1 });

  my $EXT_TABLES = '';
  if ( $self->{SEARCH_FIELDS} =~ /uct\./ ) {
    $EXT_TABLES = "LEFT JOIN users_contact_types uct ON (uc.type_id=uct.id)"
  }

  $self->query("
    SELECT $self->{SEARCH_FIELDS} uc.id
    FROM users_contacts uc
    $EXT_TABLES
    $WHERE ORDER BY priority;",
    undef,
    { COLS_NAME => 1, %{ $attr ? $attr : {} } }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 contacts_info($id)

  Arguments:
    $id - id for contacts

  Returns:
    hash_ref

=cut
#**********************************************************
sub contacts_info{
  my $self = shift;
  my ($id) = @_;

  my $list = $self->contacts_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0] || {};
}

#**********************************************************
=head2 contacts_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub contacts_add{
  my $self = shift;
  my ($attr) = @_;

  $attr->{value} =~ s/(.*?)\t//g if ($attr->{value});

  $self->query_add('users_contacts', $attr, { REPLACE => 1 });

  if (!$self->{errno}) {
    if (! $self->{OLD_INFO}{$attr->{TYPE_ID}}
      || ($attr->{VALUE} && $attr->{TYPE_ID} && $attr->{VALUE} ne $self->{OLD_INFO}{$attr->{TYPE_ID}})) {
      $self->{admin}->action_add($attr->{UID},
        "CONTACTS_CHANGED. " .  $self->contact_name_for_type_id($attr->{TYPE_ID}||0)
          . ": ". ($self->{OLD_INFO}{$attr->{TYPE_ID}||0} || q{}) ." -> ". ($attr->{VALUE} || q{}), { TYPE=> 2 });
    }
  }

  return $self;
}

#**********************************************************
=head2 contacts_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub contacts_del{
  my $self = shift;
  my ($attr) = @_;

  my $old_info = {};
  if($attr->{TYPE_ID}){
    $old_info = $self->contacts_list({
      UID  => $attr->{UID},
      TYPE => $attr->{TYPE_ID},
      VALUE => '_SHOW',
    });
  }
  else{
    $old_info = $self->contacts_list({
      UID  => $attr->{UID},
      TYPE => join(';', map {$TYPES{$_}} keys %TYPES),
      VALUE => '_SHOW',
    });
  }

  foreach my $old_ (@$old_info){
    $self->{OLD_INFO}{$old_->{type_id}} = $old_->{value};
  }
  $self->query_del('users_contacts', undef, $attr);

  return 1;
}

#**********************************************************
=head2 contacts_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub contacts_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'users_contacts',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 contacts_change_all_of_type($type_id, $attr) - allows change multiple values at once

  Arguments:
    $type_id - id of contact_type
    $attr    - hash_ref
      UID   - user to change contact for
      VALUE - contact value ( may be comma separated )

  Returns:
    1

=cut
#**********************************************************
sub contacts_change_all_of_type {
  my ($self, $type_id, $attr) = @_;

  return unless $type_id && $attr->{UID};

  # Simplest way is to delete all contacts of this type, and add it again
  $self->contacts_del({
    UID     => $attr->{UID},
    TYPE_ID => $type_id
  });

  if ( $attr->{VALUE} ) {
    # Check if have multiple values in a row
    foreach ( split(/,\s/, $attr->{VALUE}) ) {
      $self->contacts_add({
        UID     => $attr->{UID},
        TYPE_ID => $type_id,
        VALUE   => $_
      });
    }
  }
  else {
    return 0;
  }

  return 1;
}

#**********************************************************
=head2 contact_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub contact_types_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  #!!! Important !!! Only first list will work without this
  delete $self->{COL_NAMES_ARR};

  my $WHERE = '';

  $WHERE = $self->search_former( $attr, [
    [ 'ID',         'INT', 'id',         1 ],
    [ 'NAME',       'STR', 'name',       1 ],
    [ 'IS_DEFAULT', 'INT', 'is_default', 1 ],
    [ 'HIDDEN',     'INT', 'hidden'        ]
  ],
    {
      WHERE => 1
    }
  );

  if ($attr->{SHOW_ALL_COLUMNS}){
    $self->{SEARCH_FIELDS} = '*,'
  }

  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM users_contact_types $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr );

  return [] if ($self->{errno});

  return $self->{list} || [];
}

#**********************************************************
=head2 contact_types_info($id)

  Arguments:
    $id - id for contact_types

  Returns:
    hash_ref

=cut
#**********************************************************
sub contact_types_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->contact_types_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************
=head2 contact_types_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub contact_types_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('users_contact_types', $attr);

  return $self;
}

#**********************************************************
=head2 contact_types_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub contact_types_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('users_contact_types', $attr);

  return $self;
}

#**********************************************************
=head2 contact_types_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub contact_types_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'users_contact_types',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 social_add_info() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub social_add_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('users_social_info', $attr, { REPLACE => ($attr->{REPLACE}) ? 1 : undef });

  return 1;
}

#**********************************************************
=head2 social_list_info($attr) -

  Arguments:
    $attr -

  Returns:
    $self object;

  Examples:

=cut
#**********************************************************
sub social_list_info {
  my $self = shift;
  my ($attr) = @_;

  #TODO: we using table users_social_info?
  delete $self->{COL_NAMES_ARR};

  my @WHERE_RULES = ();
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'uid';
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : 'desc';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 10000;

  #if ($attr->{UNRECOGNIZED} == 1) {
  #  push @WHERE_RULES, "cch.uid = '0'";
  #}

  my $WHERE = $self->search_former($attr, [
    # ['UID',               'INT',  'usi.uid',               1 ],
    ['SOCIAL_NETWORK_ID', 'INT',  'usi.social_network_id', 1 ],
    ['NAME',              'STR',  'usi.name',              1 ],
    ['EMAIL',             'STR',  'usi.email as social_email', 1 ],
    ['BIRTHDAY',          'DATE', 'usi.birthday',          1 ],
    ['GENDER',            'STR',  'usi.gender',            1 ],
    ['LIKES',             'STR',  'usi.likes',             1 ],
    ['PHOTO',             'STR',  'usi.photo',             1 ],
    ['LOCALE',            'STR',  'usi.locale',            1 ],
    ['FRIENDS_COUNT',     'STR',  'usi.friends_count',     1 ],
  ],
    {   WHERE            => 1,
      USE_USER_PI      => 1,
      USERS_FIELDS_PRE => 1,
      WHERE_RULES      => \@WHERE_RULES,
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLES} || '';

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    usi.uid
    FROM users_social_info as usi
    LEFT JOIN users u ON u.uid=usi.uid
    $EXT_TABLE
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list if ($attr->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
     FROM users_social_info",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 contact_type_id_for_name($name) - get contact_type_id for name

  Arguments:
    $name -

  Returns:


=cut
#**********************************************************
sub contact_type_id_for_name {
  my ($self, $name) = @_;

  if ($TYPES{$name}){
    return $TYPES{$name};
  }

  state $contact_types;
  if (!defined $contact_types){
    my $contact_types_list = $self->contact_types_list({ID => '_SHOW', 'NAME' => '_SHOW', COLS_NAME => 1});
    my %id_name_hash = ();
    map { $id_name_hash{uc $_->{name}} = $_->{id} } @{$contact_types_list};
    $contact_types = \%id_name_hash;
  }

  return $contact_types->{uc $name} || 0;
}

#**********************************************************
=head2 contact_name_for_type_id($type_id) - get name for contact_type_id

  Arguments:
    $type_id -

  Returns:
    name

=cut
#**********************************************************
sub contact_name_for_type_id {
  my ($self, $type_id) = @_;

  state $contact_types_by_id;
  if (!defined $contact_types_by_id){
    my $contact_types_list = $self->contact_types_list({ID => '_SHOW', 'NAME' => '_SHOW', COLS_NAME => 1});

    my %id_name_hash = ();
    map { $id_name_hash{$_->{id}} = uc $_->{name}} @{$contact_types_list};
    $contact_types_by_id = \%id_name_hash;

  }

  return $contact_types_by_id->{$type_id} || 0;
}

#**********************************************************
=head2 push_contacts_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub push_contacts_list {
  my ($self, $attr) = @_;

  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;

  my $search_columns = [
    [ 'AID',            'INT',  'pc.aid',                     1],
    [ 'UID',            'INT',  'pc.uid',                     1],
    [ 'TYPE_ID',        'INT',  'pc.type_id',                 1],
    [ 'PUSH_TYPE_ID',   'INT',  'pc.type_id as push_type_id', 1],
    [ 'VALUE',          'STR',  'pc.value',                   1],
    [ 'BADGES',         'INT',  'pc.badges',                  1],
    [ 'DATE',           'DATE', 'pc.date',                    1],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query( "SELECT $self->{SEARCH_FIELDS} id
   FROM push_contacts pc
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr // {}}}
  );

  return [] if $self->{errno};

  return $self->{list} || [];
}

#**********************************************************
=head2 push_contacts_info($id)

  Arguments:
    $id - id for contacts

  Returns:
    hash_ref

=cut
#**********************************************************
sub push_contacts_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->push_contacts_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************
=head2 push_contacts_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub push_contacts_add {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{INSERT_ID};

  $self->query_add('push_contacts', $attr, { REPLACE => 1 });

  return $self;
}

#**********************************************************
=head2 push_contacts_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub push_contacts_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('push_contacts', undef, $attr);

  return $self;
}

#**********************************************************
=head2 push_contacts_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub push_contacts_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'push_contacts',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 push_messages_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub push_messages_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;

  my $GROUP_BY = ($attr->{GROUP_BY}) ? $attr->{GROUP_BY} : 'id';

  my $search_columns = [
    [ 'ID',         'INT', 'id',        1],
    [ 'TYPE_ID',    'INT', 'type_id',   1],
    [ 'TITLE',      'STR', 'title',     1],
    [ 'MESSAGE',    'STR', 'message',   1],
    [ 'REQUEST',    'STR', 'request',   1],
    [ 'RESPONSE',   'STR', 'response',  1],
    [ 'CREATED',    'DATE','created',   1],
    [ 'STATUS',     'INT', 'status',    1],
    [ 'UID',        'INT', 'uid',       1],
    [ 'AID',        'INT', 'aid',       1],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} id
   FROM push_messages
   $WHERE GROUP BY $GROUP_BY ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{$attr || {}} }
  );

  return [] if ($self->{errno} || $self->{TOTAL} < 1);

  my $list = $self->{list};

  $self->query("SELECT COUNT(id) AS total
   FROM push_messages push_messages
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 push_messages_info($id)

  Arguments:
    $id - id for push_messages

  Returns:
    hash_ref

=cut
#**********************************************************
sub push_messages_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->push_messages_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0] || {};
}

#**********************************************************
=head2 push_messages_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub push_messages_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('push_messages', $attr, { REPLACE => 1 });

  return $self;
}

#**********************************************************
=head2 push_messages_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub push_messages_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('push_messages', undef, $attr);

  return $self;
}

#**********************************************************
=head2 push_messages_outdated_del() - deletes messages with TTL overdated

=cut
#**********************************************************
sub push_messages_outdated_del {
  my $self = shift;

  $self->query(
    'DELETE FROM `push_messages` WHERE UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(created) > ttl;', 'do'
  );

  return $self;
}

#**********************************************************
=head2 push_messages_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub push_messages_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'push_messages',
    DATA         => $attr,
  });

  return $self;
}

1;
