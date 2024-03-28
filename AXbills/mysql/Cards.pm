package Cards;

=head1 NAME

  Cards system

=head1 VERSION

  VERSION: 8.01;
  REVISION: 20211122

=cut

use strict;
use parent qw(dbcore);
use Tariffs;
use Users;
use Fees;

our $VERSION = 8.01;
my $uid;
my $MODULE   = 'Cards';
my ($admin, $CONF);
my $internet_user_table = 'internet_main';


#**********************************************************
=head1 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  if ($CONF->{DELETE_USER}) {
    $self->{UID} = $CONF->{DELETE_USER};

    require Dillers;
    Dillers->import();
    my $Diller = Dillers->new($db, $admin, $CONF);
    $Diller->diller_del({ UID => $CONF->{DELETE_USER} });
  }

  $self->{CARDS_NUMBER_LENGTH} = (!$CONF->{CARDS_NUMBER_LENGTH}) ? 0 : $CONF->{CARDS_NUMBER_LENGTH};

  return $self;
}

#**********************************************************
=head2 cards_service_info($attr) - Cards service information

=cut
#**********************************************************
sub cards_service_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';
  if ($admin->{DOMAIN_ID}) {
    $WHERE = "AND tp.domain_id='$admin->{DOMAIN_ID}'";
  }

  $self->query("SELECT u.id AS login,
    DECODE(u.password, '$CONF->{secretkey}') AS password,
    tp.name AS tp_name,
    tp.age,
    tp.total_time_limit AS time_limit,
    tp.total_traf_limit AS traf_limit
    FROM users u
    INNER JOIN $internet_user_table internet ON (internet.uid=u.uid)
    INNER JOIN tarif_plans tp ON (internet.tp_id=tp.id $WHERE)
    WHERE
          u.deleted=0
      AND u.uid= ? ",
    undef,
    { INFO => 1,
      Bind => [ $attr->{UID} || 0 ]
    }
  );

  return $self;
}

#**********************************************************
=head2 cards_info() - Cards information

=cut
#**********************************************************
sub cards_info {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, "c.domain_id='$admin->{DOMAIN_ID}'";
  }

  my $WHERE = $self->search_former($attr, [
      ['ID',           'INT',  'c.id'                                ],
      ['PIN',          'STR',  "DECODE(c.pin, '$CONF->{secretkey}')" ],
      ['SERIAL',       'STR',  "CONCAT(c.serial, IF($self->{CARDS_NUMBER_LENGTH}>0, MID(c.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), c.number))",  ],
      ['CARD_GID',     'INT',  'c.gid', 'c.gid AS card_gid' ]
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
    );

  $self->query("SELECT
      c.serial,
      IF($self->{CARDS_NUMBER_LENGTH}>0, MID(c.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), c.number) AS number,
      c.sum,

      IF(c.status = 1 or c.status = 2 or c.status = 4  or c.status = 5, c.status,
              IF(c.uid > 0 && u.activate <> '0000-00-00', 2,
                IF(c.uid > 0 && u.activate IS NULL, 3, 0)
              )
        ) AS status,
      c.datetime,
      c.expire,
      c.pin,
      IF (c.expire<CURDATE() && c.expire != '0000-00-00', 1, 0) AS expire_status,
      c.uid,
      c.diller_id,
      c.id,
      c.commission,
      c.gid AS card_gid,
      GROUP_CONCAT(cg.gid SEPARATOR ',') AS allow_gid
    FROM cards_users c
    LEFT JOIN users u ON (c.uid = u.uid)
    LEFT JOIN cards_gids cg ON (cg.serial=c.serial)
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    SERIAL           => '',
    BEGIN            => 0,
    COUNT            => 0,
    LOGIN_BEGIN      => 0,
    LOGIN_COUNT      => 0,
    PASSWD_SYMBOLS   => '1234567890',
    PASSWD_LENGTH    => 8,
    SUM              => '0.00',
    LOGIN_LENGTH     => 5,
    EXPIRE           => '0000-00-00',
    DILLER_ID        => 0,
    UID              => 0,
    DOMAIN_ID        => 0,
    ID               => 0,
    COMMISSION       => '0.00'
  );

  while (my ($k, $v) = each %DATA) {
    $self->{$k} = $v;
  }

  return $self;
}

#**********************************************************
=head2 _generate_pin($attr)

=cut
#**********************************************************
sub _generate_pin {
  my $self = shift;
  my ($attr) = @_;

  my $pin_length = $attr->{PASSWD_LENGTH} || $CONF->{CARDS_PAYMENT_PIN_LENGTH};
  my $pin_symbols = $attr->{PASSWD_SYMBOLS} || $CONF->{CARDS_PIN_SYMBOLS};
  my $symbols_length = length($attr->{PASSWD_SYMBOLS}) - 1;
  my @substrings = ('substring("' . $pin_symbols . '", rand(@seed:=round(rand(id)*4294967296))*' . $symbols_length . '+1, 1)');

  push @substrings, (' substring("' . $pin_symbols . '", rand(@seed:=round(rand(@seed)*4294967296))*' . 
    $symbols_length . '+1, 1)') x ($pin_length - 2);
  push @substrings, 'substring("' . $pin_symbols . '", rand(@seed)*' . $symbols_length . '+1, 1)';

  return 'ENCODE(concat(' . join(',', @substrings) . '), ?)';
}

#**********************************************************
=head2 cards_add($attr)

=cut
#**********************************************************
sub cards_add {
  my $self = shift;
  my ($attr) = @_;

  my $total = 0;
  if ($attr->{MULTI_ADD}) {
    $self->query("INSERT INTO cards_users (
       serial, number, login, pin, status, expire,aid,
       diller_id, diller_date, sum, uid, domain_id, created, commission, gid)
     VALUES (?,?,?,ENCODE(?, '$CONF->{secretkey}'),?,?,?,?,if (? > 0, NOW(), '0000-00-00'),?,?,?,NOW(),?,?);",
     undef, { MULTI_QUERY =>  $attr->{MULTI_ADD} }
    );
    return $self if $self->{errno};
    $total = $self->{TOTAL};

    $self->query("SELECT MAX(id) AS LAST_ID FROM cards_users;", undef, { INFO => 1 });
    my $last_id = $self->{LAST_ID};
    my $first_id = $last_id - scalar(@{$attr->{MULTI_ADD}}) + 1;

    $self->query('UPDATE cards_users  SET pin = ' . $self->_generate_pin($attr) . '
      WHERE id >= ' . $first_id . ' AND id <= ' . $last_id . ';', 'do', {
      Bind => [ $CONF->{secretkey} ]
    });
  }
  else {
    $self->query("INSERT INTO cards_users (
       serial, number, login, pin, status, expire,aid,
       diller_id, diller_date, sum, uid, domain_id, created, commission, gid)
     VALUES (?,?,?,ENCODE(?, ?),?,?,?,?,if (? > 0, NOW(), '0000-00-00'),
       ?,?,?,NOW(),?, ?);",
     'do',
     {
       Bind => [
        $attr->{SERIAL} || '',
        $attr->{NUMBER} || 0,
        $attr->{LOGIN} || '',
        $attr->{PIN} || '',
        $CONF->{secretkey},
        $attr->{STATUS} || 0,
        $attr->{EXPIRE} || '0000-00-00',
        $admin->{AID},
        $attr->{DILLER_ID} || 0,
        $attr->{DILLER_ID} || 0,
        $attr->{SUM} || 0,
        $attr->{UID} || 0,
        $admin->{DOMAIN_ID} || 0,
        $attr->{COMMISSION} || 0,
        $attr->{GID} || 0
       ]
     });
  }

  $admin->action_add($attr->{UID}, "ADDED $self->{TOTAL} cards, $self->{SERIAL}", { TYPE => 1 });

  $self->{CARD_ID} = $self->{INSERT_ID};
  $self->{CARD_NUMBER} = $self->{NUMBER};
  $self->{TOTAL} ||= $total;

  return $self;
}

#**********************************************************
=head2 cards_change($attr)

=cut
#**********************************************************
sub cards_change {
  my $self = shift;
  my ($attr) = @_;

  my %IDS_HASH    = ();
  my $WHERE       = '';
  my $action_info = '';

  if ($attr->{IDS}) {
    if ($attr->{IDS} =~ /:/) {
      my @IDS = split(/, /, $attr->{IDS});

      foreach my $line (@IDS) {
        my ($k, $v) = split(/:/, $line, 2);
        push @{ $IDS_HASH{$k} }, $v;
      }

      my @where_arr = ();
      while (my ($k, $v) = each %IDS_HASH) {
        my $ids = "'" . join('\', \'', @$v) . "'";
        push @where_arr, "(serial='$k' and number in ($ids))";
        $ids =~ s/\'//g;
        $action_info .= "$k $ids;";
      }

      $WHERE = join(' AND ', @where_arr);
    }
    else {
      $WHERE = " id in ($attr->{IDS}) ";
    }
  }

  $action_info = "$attr->{SERIAL}/$attr->{NUMBER}";

  if ($attr->{SERIAL} && $attr->{NUMBER} && $attr->{STATUS}) {
    my $status_date = ($attr->{STATUS} == 2) ? ", datetime=now()" : '';

    $self->query("UPDATE cards_users SET
      status=? $status_date
       WHERE serial=? and number= ? ; ", 'do',
      { Bind => [
          $attr->{STATUS} || 0,
          $attr->{SERIAL} || '',
          $attr->{NUMBER} || 0
        ]
      }
    );

    $admin->action_add($attr->{UID}, "USE id:$attr->{IDS}, STATUS:$attr->{STATUS}, $action_info",{ TYPE=>2 });
    return $self;
  }
  elsif ($attr->{IDS} && $attr->{SOLD}) {
    $self->query("UPDATE cards_users SET
        diller_sold_date=NOW(),
        aid='$admin->{AID}'
       WHERE diller_id='$attr->{DILLER_ID}' AND $WHERE; ", 'do'
    );

    $admin->action_add($attr->{UID}, "SOLD $action_info", { TYPE=>2 });

    return $self;
  }
  elsif ($attr->{IDS} && (defined($attr->{STATUS}) && $attr->{STATUS} ne '')) {
    # Sattus 3 return cards USER ID
    if ($attr->{STATUS} == 3) {
      $self->{CARDS_INFO} = $self->cards_list(
        {
          %$attr,
          STATUS    => undef,
          PAGE_ROWS => 100000,
          DOMAIN_ID => $admin->{DOMAIN_ID}
        }
      );

      $self->query("DELETE FROM cards_users
          WHERE domain_id='$admin->{DOMAIN_ID}' AND $WHERE; ", 'do'
      );
      $admin->action_add(0, "DELETE $action_info",{ TYPE=>10 });
      return $self;
    }

    my $dillers = '';
    if ($attr->{DILLER_ID}) {
      $dillers = "diller_id='$attr->{DILLER_ID}',
                  diller_date=NOW(),";
    }

    my $status_date = ($attr->{STATUS} == 2) ? "datetime=now()," : '';
    $self->query("UPDATE cards_users SET
        status='$attr->{STATUS}',
        $status_date
        $dillers
        aid='$admin->{AID}'
       WHERE domain_id='$admin->{DOMAIN_ID}' AND $WHERE; ", 'do'
    );

    $admin->action_add(0, "STATUS: $attr->{STATUS}, $action_info",{ TYPE=>2 });

    return $self;
  }
  elsif ($attr->{IDS} && $attr->{DILLER_ID}) {
    $self->query("UPDATE cards_users SET
      diller_id='$attr->{DILLER_ID}',
      diller_date=NOW(),
      aid='$admin->{AID}'
      WHERE domain_id='$admin->{DOMAIN_ID}' AND $WHERE; ", 'do'
    );

    $admin->action_add(0, "DILLER ADD $attr->{DILLER_ID} $action_info", { TYPE=>1 });

    return $self;
  }

  if (!$attr->{ID}) {
    $self->{error}  = 2;
    $self->{errno}  = 2;
    return $self;
  }

  my %FIELDS = (
    SERIAL           => 'serial',
    NUMBER           => 'number',
    SUM              => 'sum',
    STATUS           => 'status',
    DATETIME         => 'datetime',
    DILLER_ID        => 'diller_id',
    DILLER_SOLD_DATE => 'diller_sold_date',
    ID               => 'id',
    UID              => 'uid'
    #DOMAIN_ID => 'domain_id'
  );

  my $old_info = $self->cards_info({ ID => $attr->{ID} });
  $attr->{PIN}     = $old_info->{PIN};
  $admin->{MODULE} = $MODULE;

  $self->changes({
    CHANGE_PARAM    => 'ID',
    TABLE           => 'cards_users',
    FIELDS          => \%FIELDS,
    OLD_INFO        => $old_info,
    DATA            => $attr,
    EXT_CHANGE_INFO => (($attr->{STATUS} == 2) ? $self->{ID} : "ID:$self->{ID} $attr->{SERIAL}$attr->{NUMBER}"),
    ACTION_ID       => (($attr->{STATUS} == 2) ? 31 : undef)
  });

  if(! $self->{AFFECTED}) {
    $self->{error}  = 11;
    $self->{errno}  = 11;
    $self->{errstr} = 'ERROR_NOT_CHANGED';
  }

  return $self;
}

#**********************************************************
=head cards_del($attr) - Delete user info from all tables

=cut
#**********************************************************
sub cards_del {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ("domain_id='$admin->{DOMAIN_ID}'");

  my $WHERE = '';
  if ($attr->{ID}) {
    push @WHERE_RULES, " id='$attr->{ID}' ";
  }
  elsif (defined($attr->{SERIA})) {
    push @WHERE_RULES, "serial='$attr->{SERIA}'";
  }

  if ($attr->{IDS}) {
    push @WHERE_RULES, " id IN ($attr->{IDS}) ";
  }
  elsif ($attr->{NUMBER}) {
    push @WHERE_RULES, " number='$attr->{NUMBER}' ";
  }

  if (defined($attr->{DILLER_ID})) {
    push @WHERE_RULES, "diller_id='$attr->{DILLER_ID}'";
  }

  if ($#WHERE_RULES > -1) {
    $WHERE = join(' AND ', @WHERE_RULES);
    $self->query("DELETE from cards_users WHERE $WHERE;", 'do');
  }

  $admin->action_add($uid, "DELETE $attr->{SERIA}/$attr->{NUMBER}", { TYPE=>10 });
  return $self->{result};
}

#**********************************************************
=head2 cards_list($attr) - List of cards


=cut
#**********************************************************
sub cards_list {
  my $self   = shift;
  my ($attr) = @_;

  delete($self->{COL_NAMES_ARR});

  my $GROUP = "cu.serial";
  my $GROUP_BY = (defined($attr->{SERIAL}) && $attr->{SERIAL} ne '_SHOW') ? '' : "GROUP BY $GROUP";

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}           : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}           : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}             : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? int($attr->{PAGE_ROWS}) : 25;

  my @WHERE_RULES = ();

  if ($attr->{NO_GROUP}) {
    push @WHERE_RULES, $attr->{SERIAL_DILLERS} ne '_SHOW' ? @{ $self->search_expr($attr->{SERIAL_DILLERS}, 'STR', 'cu.serial') } : 'cu.serial';
    $GROUP_BY='';
  }

  if ($admin->{DOMAIN_ID} == 0) {
    my @domain_id = split(/;/, $attr->{DOMAIN_ID});

    if ($#domain_id > 1) {
      push @domain_id, 0;
    }

    foreach my $element_id (@domain_id) {
      push @WHERE_RULES, "cu.domain_id = $element_id";
    }
    
  }

  if ($attr->{PAYMENTS}) {
    push @WHERE_RULES, @{ $self->search_expr(0, 'INT', 'cu.uid') };
  }

  if (defined($attr->{SERIAL}) && $attr->{SERIAL} ne '_SHOW') {
    if ($attr->{SERIAL} eq 'empty') {
      $attr->{SERIAL} = '';
    }
    push @WHERE_RULES, @{ $self->search_expr($attr->{SERIAL}, 'STR', 'cu.serial') };
    $GROUP_BY='';
  }

  if($attr->{USED_FROM_DATE_USED_TO_DATE}){
    ($attr->{USED_FROM_DATE}, $attr->{USED_TO_DATE}) = split '/', $attr->{USED_FROM_DATE_USED_TO_DATE};
  }

  if ($attr->{USED_FROM_DATE} || $attr->{USED_TO_DATE}) {
    $attr->{STATUS} = 2;
  }

  my $WHERE = $self->search_former($attr, [
    ['NUMBER',           'INT',  'cu.number',    "IF($self->{CARDS_NUMBER_LENGTH}>0, MID(cu.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), cu.number) AS number"],
    ['CARDS_COUNT',      '',     '', 'COUNT(*) AS cards_count' ],
    ['CARDS_SUM',        '',     '', 'SUM(sum) AS cards_sum'  ],
    ['CARDS_ACTIVE',     '',     '', "SUM(IF(cu.status=0 && cu.uid=0, 1,
                                IF (cu.uid>0 && u.activate='0000-00-00', 1, 0))) AS cards_active" ],
    ['CARDS_DILLERS',    '',     '', 'SUM(IF (cu.diller_id>0, 1, 0)) AS cards_dillers' ],
    ['SUM',              'INT',  'cu.sum',         1],
    ['LOGIN',            'STR',  'u.id AS login',  1],
    ['EXPIRE',           'DATE', 'cu.expire',      1],
    ['CREATED',          'DATE', "DATE_FORMAT(cu.created, '%Y-%m-%d')",  "DATE_FORMAT(cu.created, '%Y-%m-%d %H:%i:%s') AS created" ],
    ['LAST_CREATED',     'DATE', "DATE_FORMAT(MAX(cu.created), '%Y-%m-%d')",  "DATE_FORMAT(MAX(cu.created), '%Y-%m-%d') AS created" ],
    ['DILLER_NAME',      'STR',  "if(cd_users.fio<>'', cd_users.fio, cd.uid) AS diller_name", 1 ],
    ['DILLER_DATE',      'DATE', 'cu.diller_date', 1],
    ['DILLER_SOLD_DATE', 'DATE', "IF(cu.diller_sold_date='0000-00-00', '', cu.diller_sold_date) AS diller_sold_date", 1],
    ['DILLER_ID',        'INT',  'cu.diller_id',    ],
    ['AID',              'INT',  'cu.aid',         1],
    ['TP_ID',            'INT',  'tp.id',          1],
    ['ID',               'INT',  'cu.id'            ],
    ['IDS',              'INT',  'cu.id'            ],
    ['MONTH',            'INT',  'cu.datetime',    1],
    ['STATUS',           'INT',  'cu.status',      1],
    ['PIN',              'STR',  "DECODE(cu.pin, '$CONF->{secretkey}')", "DECODE(cu.pin, '$CONF->{secretkey}') AS pin"],

    #['DATE',             'DATE', "DATE_FORMAT(cu.datetime, '%Y-%m-%d')"                     ],
    ['CREATED_MONTH',    'DATE', "DATE_FORMAT(cu.created, '%Y-%m')"                         ],
    ['FROM_DATE|TO_DATE','DATE', "DATE_FORMAT(cu.created, '%Y-%m-%d')",                     ],
    ['CREATED_FROM_DATE|CREATED_TO_DATE',  'DATE',  "DATE_FORMAT(cu.created, '%Y-%m-%d')",  ],
    ['USED_DATE',        'DATE', "", "IF (cu.status=2, cu.datetime, '') AS used_date"       ],
    ['DILLER_UID',       'INT',  'cd.uid',    1],
    ['USED_FROM_DATE|USED_TO_DATE', 'DATE', "DATE_FORMAT(cu.datetime, '%Y-%m-%d')", ],
  ],
  {
    WHERE => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  my $list = [];

  if ($attr->{TYPE} && $attr->{TYPE} eq 'TP') {
    if ($attr->{TP_ID} && $attr->{TP_ID} ne '_SHOW' ) {
      $self->query("SELECT
        CONCAT(cu.serial,if($self->{CARDS_NUMBER_LENGTH}>0, MID(cu.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), cu.number)) AS sn,
        u.id AS login,
        DECODE(cu.pin, '$CONF->{secretkey}') AS pin,
        tp.name AS tp_name,
        IF(u.activate <> '0000-00-00', u.activate, '-') AS activate,
        cu.sum,
        tp.age,
        tp.total_time_limit
         FROM `cards_users` cu
      LEFT JOIN `admins` a ON (cu.aid = a.aid)
      LEFT JOIN `groups` g ON (cu.gid = g.gid)
      LEFT JOIN `cards_dillers` cd ON (cu.diller_id = cd.id)
      LEFT JOIN `users` u ON (cu.uid = u.uid)
      LEFT JOIN `$internet_user_table` internet ON (u.uid = internet.uid)
      LEFT JOIN `tarif_plans` tp ON (tp.domain_id='$admin->{DOMAIN_ID}' AND internet.tp_id = tp.tp_id)
      $WHERE
      GROUP BY 1,2
      ORDER BY $SORT $DESC
      LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
      );

      return $self if ($self->{errno});
      $list = $self->{list};

      $self->query("SELECT COUNT(*) AS total, SUM(cu.sum) AS total_sum
      FROM `cards_users` cu
      LEFT JOIN `admins` a ON (cu.aid = a.aid)
      LEFT JOIN `groups` g ON (cu.gid = g.gid)
      LEFT JOIN `cards_dillers` cd ON (cu.diller_id = cd.id)
      LEFT JOIN `users` u ON (cu.uid = u.uid)
      LEFT JOIN `$internet_user_table` internet ON (u.uid = internet.uid)
      LEFT JOIN `tarif_plans` tp ON (tp.domain_id='$admin->{DOMAIN_ID}' and internet.tp_id = tp.id)
      $WHERE;",
      undef, { INFO => 1 }
      );
    }
    else {
      $self->query("SELECT DATE_FORMAT(cu.created, '%Y-%m-%d') AS date,
         tp.name AS tp_name,
         COUNT(*) AS count,
         SUM(sum) AS sum,
         tp.id AS tp_id
         FROM `cards_users` cu
      LEFT JOIN `admins` a ON (cu.aid = a.aid)
      LEFT JOIN `groups` g ON (cu.gid = g.gid)
      LEFT JOIN `cards_dillers` cd ON (cu.diller_id = cd.id)
      LEFT JOIN `users` u ON (cu.uid = u.uid)
      LEFT JOIN `$internet_user_table` internet ON (u.uid = internet.uid)
      LEFT JOIN `tarif_plans` tp ON (tp.domain_id='$admin->{DOMAIN_ID}' and internet.tp_id = tp.tp_id)
      $WHERE
      GROUP BY 1,2
      ORDER BY $SORT $DESC
      LIMIT $PG, $PAGE_ROWS;",
      undef,
      $attr
      );

      return $self if ($self->{errno});
      $list = $self->{list};
    }
  }
  else {
    my $EXT_TABLES = '';
    if ($attr->{TP_ID}) {
      $EXT_TABLES = "LEFT JOIN `$internet_user_table` internet ON (u.uid = internet.uid)
        LEFT JOIN `tarif_plans` tp ON (tp.domain_id='$admin->{DOMAIN_ID}' and internet.tp_id = tp.id)";
    }

    $self->query("SELECT cu.serial, $self->{SEARCH_FIELDS}
        cu.id, cu.uid, cu.diller_id, cd.uid AS diller_uid
     FROM `cards_users` cu
     LEFT JOIN `admins` a ON (cu.aid = a.aid)
     LEFT JOIN `groups` g ON (cu.gid = g.gid)
     LEFT JOIN `cards_dillers` cd ON (cu.diller_id = cd.id)
     LEFT JOIN `users_pi` cd_users ON (cd.uid = cd_users.uid)
     LEFT JOIN `users` u ON (cu.uid = u.uid)
     $EXT_TABLES
     $WHERE
     $GROUP_BY
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );

    return [] if ($self->{errno});
    $list = $self->{list} || [];

    if ($attr->{SKIP_TOTALS}) {
      return $list;
    }

    $self->query("SELECT
       COUNT(*) AS total_cards,
       SUM(IF(cu.status=0, 1, 0)) AS enabled,
       SUM(IF(cu.status=1, 1, 0)) AS disabled,
       SUM(IF(cu.status=6, 1, 0)) AS transferred_to_production,
       SUM(IF(u.activate <> '0000-00-00' or cu.status=2, 1, 0)) AS used,
       SUM(IF(u.activate IS NULL, 1, 0)) AS deleted,
       SUM(IF(cu.status=4, 1, 0)) AS returned,
       SUM(IF(cu.diller_sold_date<>'0000-00-00', 1, 0)) AS diller_sold,

       SUM(cu.sum) AS total_sum,
       SUM(IF(cu.status=0, cu.sum, 0)) AS enabled_sum,
       SUM(IF(cu.status=1, cu.sum, 0)) AS disabled_sum,
       SUM(IF(cu.status=6, cu.sum, 0)) AS transferred_to_production_sum,
       SUM(IF(u.activate <> '0000-00-00'  or cu.status=2 , cu.sum, 0)) AS used_sum,
       SUM(IF(u.activate IS NULL, cu.sum, 0)) AS deleted_sum,
       SUM(IF(cu.status=4, cu.sum, 0)) AS returned_sum,
       SUM(IF(cu.diller_sold_date<>'0000-00-00', cu.sum, 0)) AS diller_sold_sum,

       COUNT(DISTINCT serial) AS serial

     FROM `cards_users` cu
     LEFT JOIN `admins` a ON (cu.aid = a.aid)
     LEFT JOIN `groups` g ON (cu.gid = g.gid)
     LEFT JOIN `cards_dillers` cd ON (cu.diller_id = cd.id)
     LEFT JOIN `users` u ON (cu.uid = u.uid)
     $EXT_TABLES
     $WHERE;",
     undef,
     { INFO => 1 }
    );
  }

  if (defined($attr->{SERIAL}) && $attr->{SERIAL} ne '_SHOW') {
    $self->{TOTAL}=$self->{TOTAL_CARDS};
  }
  elsif($self->{SERIAL}) {
    $self->{TOTAL}=$self->{SERIAL} ;
  }

  return $list;
}

#**********************************************************
=head2 cards_report_dillers($attr)

=cut
#**********************************************************
sub cards_report_dillers {
  my $self = shift;
  my ($attr) = @_;

  my $active_date      = 'u.activate <> \'0000-00-00\'';
  my $diller_date      = 'c.diller_date <> \'0000-00-00\'';
  my $diller_sold_date = 'c.diller_sold_date <> \'0000-00-00\'';
  my @WHERE_RULES      = ();

  if (defined($attr->{DATE})) {
    push @WHERE_RULES, " (c.diller_sold_date='$attr->{DATE}' or DATE_FORMAT(c.datetime, '%Y-%m-%d')='$attr->{DATE}' or  DATE_FORMAT(c.diller_date, '%Y-%m-%d')='$attr->{DATE}')";

    $active_date = "u.activate = '$attr->{DATE}'";

    $diller_date      = "c.diller_date = '$attr->{DATE}'";
    $diller_sold_date = "c.diller_sold_date = '$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "((DATE_FORMAT(c.datetime, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.datetime, '%Y-%m-%d')<='$to') or
    (DATE_FORMAT(c.diller_date, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.diller_date, '%Y-%m-%d')<='$to'))";

    $active_date = "(DATE_FORMAT(u.activate, '%Y-%m-%d')>='$from' and DATE_FORMAT(u.activate, '%Y-%m-%d')<='$to')";
    $diller_date = "(DATE_FORMAT(c.diller_date, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.diller_date, '%Y-%m-%d')<='$to')";
  }
  elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "(DATE_FORMAT(c.datetime, '%Y-%m')='$attr->{MONTH}' or DATE_FORMAT(diller_date, '%Y-%m')='$attr->{MONTH}')";
    $active_date = 'DATE_FORMAT(u.activate, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
    $diller_date = 'DATE_FORMAT(c.diller_date, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
  }

  if (defined($attr->{SERIA})) {
    $attr->{SERIA} =~ s/\*/\%/ig;
    push @WHERE_RULES, "cu.serial='$attr->{SERIA}'";
  }

  my $GROUP    = 'if (pi.fio<>\'\', pi.fio, pi.uid)';
  my $GROUP_BY = 'cd.id';

  if ($attr->{GROUP}) {
    $GROUP_BY = $attr->{GROUP};
    $GROUP    = 1;
  }

  #By cards
  my $list;
  if ($attr->{GROUP}) {

    my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

    $self->query("SELECT $GROUP,
       SUM(IF(c.status=0, 1, 0)),
        SUM(IF(c.status=0, c.sum, 0)),
       SUM(IF(c.status=1, 1, 0)),
        SUM(IF(c.status=1, c.sum, 0)),
       SUM(IF(c.status=2, 1, 0)),
        SUM(IF(c.status=2, c.sum, 0)),
       SUM(IF($active_date, 1, 0)),
        SUM(IF($active_date, c.sum, 0)),
       SUM(IF($diller_date, 1, 0)),
        SUM(IF($diller_date, c.sum, 0)),
       SUM(IF($diller_sold_date, 1, 0)),
        SUM(IF($diller_sold_date, c.sum, 0)),
         SUM(IF($diller_sold_date, c.sum / 100 * cd.percentage, 0)),
       SUM(IF(c.status=4, 1, 0)),
        SUM(IF(c.status=4, c.sum, 0)),
       COUNT(*),
        SUM(c.sum)

    FROM `cards_users` c
    LEFT JOIN `cards_dillers` cd ON (c.diller_id = cd.id)
    LEFT JOIN `users` u ON (c.uid = u.uid)
    LEFT JOIN `users_pi` pi ON (cd.uid = pi.uid)
     $WHERE
     GROUP BY $GROUP_BY
     ORDER BY 1;",
     undef, $attr
    );

    return $self if ($self->{errno});
    $list = $self->{list};

    $self->query("SELECT
       SUM(IF(c.status=0, 1, 0)) as enable_total,
        SUM(IF(c.status=0, c.sum, 0)) as enable_total_sum,
       SUM(IF(c.status=1, 1, 0)) as disable_total,
        SUM(IF(c.status=1, c.sum, 0)) as disable_total_sum,
       SUM(IF(c.status=2, 1, 0)) as payment_total,
        SUM(IF(c.status=2, c.sum, 0)) as payment_total_sum,
       SUM(IF($active_date, 1, 0)) as login_total,
        SUM(IF($active_date, c.sum, 0)) as login_total_sum,
       SUM(IF($diller_date, 1, 0)) as take_total,
        SUM(IF($diller_date, c.sum, 0)) as take_total_sum,
       SUM(IF($diller_sold_date, 1, 0)) as sold_total,
        SUM(IF($diller_sold_date, c.sum, 0)) as sold_total_sum,
         SUM(IF($diller_sold_date, c.sum / 100 * cd.percentage, 0)) as sold_total_percentage,
       SUM(IF(c.status=4, 1, 0)) as return_total,
        SUM(IF(c.status=4, c.sum, 0)) as return_total_sum,
       COUNT(*) as count_total,
        SUM(c.sum) as count_total_sum

    FROM `cards_users` c
    LEFT JOIN `cards_dillers` cd ON (c.diller_id = cd.id)
    LEFT JOIN `users` u ON (c.uid = u.uid)
     $WHERE
     ORDER BY 1;",
     undef, { INFO => 1 }
    );
  }

  # By dillers
  else {
    my $WHERE = "WHERE c.diller_id = cd.id ";
    $WHERE .= ($#WHERE_RULES > -1) ? " and " . join(' and ', @WHERE_RULES) : '';

    $self->query("SELECT $GROUP,
       SUM(IF(c.status=0, 1, 0)),
        SUM(IF(c.status=0, c.sum, 0)),
       SUM(IF(c.status=1, 1, 0)),
        SUM(IF(c.status=1, c.sum, 0)),
       SUM(IF(c.status=2, 1, 0)),
        SUM(IF(c.status=2, c.sum, 0)),
       SUM(IF($active_date, 1, 0)),
        SUM(IF($active_date, c.sum, 0)),
       SUM(IF($diller_date, 1, 0)),
        SUM(IF($diller_date, c.sum, 0)),
       SUM(IF($diller_sold_date, 1, 0)),
        SUM(IF($diller_sold_date, c.sum, 0)),
         SUM(IF($diller_sold_date, c.sum / 100 * cd.percentage, 0)),
       SUM(IF(c.status=4, 1, 0)),
        SUM(IF(c.status=4, c.sum, 0)),
       COUNT(*),
        SUM(c.sum),
       c.diller_id, cd.uid
    FROM (cards_dillers cd, cards_users c)
    LEFT JOIN users u ON (c.uid = u.uid)
    LEFT JOIN users_pi pi ON (cd.uid = pi.uid)
     $WHERE
     GROUP BY $GROUP_BY
     ORDER BY 1;",
     undef, $attr
    );

    return $self if ($self->{errno});
    $list = $self->{list};

    $self->query("SELECT
       SUM(IF(c.status=0, 1, 0)) AS ENABLE_TOTAL,
        SUM(IF(c.status=0, c.sum, 0)) AS ENABLE_TOTAL_SUM,
       SUM(IF(c.status=1, 1, 0)) AS DISABLE_TOTAL,
        SUM(IF(c.status=1, c.sum, 0)) AS DISABLE_TOTAL_SUM,
       SUM(IF(c.status=2, 1, 0)) AS PAYMENT_TOTAL,
        SUM(IF(c.status=2, c.sum, 0)) AS PAYMENT_TOTAL_SUM,
       SUM(IF($active_date, 1, 0)) AS LOGIN_TOTAL,
        SUM(IF($active_date, c.sum, 0)) AS LOGIN_TOTAL_SUM,
       SUM(IF($diller_date, 1, 0)) AS TAKE_TOTAL,
        SUM(IF($diller_date, c.sum, 0)) AS TAKE_TOTAL_SUM,
       SUM(IF($diller_sold_date, 1, 0)) AS SOLD_TOTAL,
        SUM(IF($diller_sold_date, c.sum, 0)) SOLD_TOTAL_SUM,
         SUM(IF($diller_sold_date, c.sum / 100 * cd.percentage, 0)) AS  SOLD_TOTAL_PERCENTAGE,
       SUM(IF(c.status=4, 1, 0)) AS RETURN_TOTAL,
        SUM(IF(c.status=4, c.sum, 0)) AS RETURN_TOTAL_SUM,
       COUNT(*) AS COUNT_TOTAL,
        SUM(c.sum) AS COUNT_TOTAL_SUM

    FROM (cards_dillers cd, cards_users c)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     ORDER BY 1;",
     undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 cards_report_days($attr)

=cut
#**********************************************************
sub cards_report_days {
  my $self = shift;
  my ($attr) = @_;

  my %RESULT                  = ();
  my @WHERE_RULES             = ("c.domain_id='$admin->{DOMAIN_ID}'");
  my @WHERE_RULES_DILLERS     = ("c.domain_id='$admin->{DOMAIN_ID}'");
  my @WHERE_RULES_USERS       = ("c.domain_id='$admin->{DOMAIN_ID}'");
  my @WHERE_RULES_DILLER_SOLD = ("c.domain_id='$admin->{DOMAIN_ID}'");

  #Short reports for dillers
  if ($attr->{CREATED_MONTH} || $attr->{CREATED_FROM_DATE} || $attr->{CREATED_MONTH}) {

    if ($attr->{DILLER_ID}) {
      push @WHERE_RULES, "c.diller_id='$attr->{DILLER_ID}'";
    }

    if ($attr->{STATUS}) {
      $attr->{STATUS}--;
      push @WHERE_RULES, @{ $self->search_expr($attr->{STATUS}, 'INT', 'c.status') };
    }

    if ($attr->{CREATED_DATE}) {
      push @WHERE_RULES, "DATE_FORMAT(c.created, '%Y-%m-%d')='$attr->{CREATED_DATE}'";
    }
    elsif ($attr->{CREATED_MONTH}) {
      push @WHERE_RULES, "DATE_FORMAT(c.created, '%Y-%m')='$attr->{CREATED_MONTH}'";
    }
    elsif ($attr->{CREATED_FROM_DATE}) {
      push @WHERE_RULES, "(DATE_FORMAT(c.created, '%Y-%m-%d')>='$attr->{CREATED_FROM_DATE}' and DATE_FORMAT(c.created, '%Y-%m-%d')<='$attr->{CREATED_TO_DATE}')";
    }

    my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

    $self->query("SELECT
    DATE_FORMAT(c.created, '%Y-%m-%d') AS date,
    COUNT(*) AS count,
    SUM(c.sum) AS sum
   FROM cards_users c
    $WHERE
   GROUP BY 1;", undef, $attr
    );

    return $self->{list};
  }

  if ($attr->{DILLER_ID}) {
    push @WHERE_RULES,             "c.diller_id='$attr->{DILLER_ID}'";
    push @WHERE_RULES_DILLERS,     "c.diller_id='$attr->{DILLER_ID}'";
    push @WHERE_RULES_USERS,       "c.diller_id='$attr->{DILLER_ID}'";
    push @WHERE_RULES_DILLER_SOLD, "c.diller_id='$attr->{DILLER_ID}'";
  }

  if (defined($attr->{DATE})) {
    push @WHERE_RULES,             " DATE_FORMAT(c.datetime, '%Y-%m-%d')='$attr->{DATE}'";
    push @WHERE_RULES_DILLERS,     "DATE_FORMAT(c.diller_date, '%Y-%m-%d')='$attr->{DATE}'";
    push @WHERE_RULES_USERS,       "DATE_FORMAT(u.activate, '%Y-%m-%d')='$attr->{DATE}'";
    push @WHERE_RULES_DILLER_SOLD, "c.diller_sold_date='$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES,             "DATE_FORMAT(c.datetime, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.datetime, '%Y-%m-%d')<='$to'";
    push @WHERE_RULES_DILLERS,     "DATE_FORMAT(c.diller_date, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.diller_date, '%Y-%m-%d')<='$to'";
    push @WHERE_RULES_USERS,       "DATE_FORMAT(u.activate, '%Y-%m-%d')>='$from' and DATE_FORMAT(u.activate, '%Y-%m-%d')<='$to'";
    push @WHERE_RULES_DILLER_SOLD, "c.diller_sold_date>='$from' and c.diller_sold_date<='$to'";
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES,             "DATE_FORMAT(c.datetime, '%Y-%m')='$attr->{MONTH}'";
    push @WHERE_RULES_DILLERS,     "DATE_FORMAT(c.diller_date, '%Y-%m')='$attr->{MONTH}'";
    push @WHERE_RULES_USERS,       "DATE_FORMAT(u.activate, '%Y-%m')='$attr->{MONTH}'";
    push @WHERE_RULES_DILLER_SOLD, "DATE_FORMAT(c.diller_sold_date, '%Y-%m')='$attr->{MONTH}'";
  }
  else {
    push @WHERE_RULES,             "DATE_FORMAT(c.datetime, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
    push @WHERE_RULES_DILLERS,     "DATE_FORMAT(c.diller_date, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
    push @WHERE_RULES_USERS,       "DATE_FORMAT(u.activate, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
    push @WHERE_RULES_DILLER_SOLD, "DATE_FORMAT(c.diller_sold_date, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
  }

  my $WHERE              = ($#WHERE_RULES > -1)             ? "WHERE " . join(' and ', @WHERE_RULES)             : '';
  my $WHERE_DILLERS      = ($#WHERE_RULES_DILLERS > -1)     ? "WHERE " . join(' and ', @WHERE_RULES_DILLERS)     : '';
  my $WHERE_DILLERS_SOLD = ($#WHERE_RULES_DILLER_SOLD > -1) ? "WHERE " . join(' and ', @WHERE_RULES_DILLER_SOLD) : '';

  # TO Diller
  #ENABLE, _DISABLE, _USED/logined, _DELETED, _RETURNED

  $self->query("select
 DATE_FORMAT(c.created, '%Y-%m-%d'),
 SUM(IF(c.status=0, 1, 0)),
  SUM(IF(c.status=0, c.sum, 0)),
 SUM(IF(c.status=1, 1, 0)),
  SUM(IF(c.status=1, c.sum, 0)),
 SUM(IF(c.status=2, 1, 0)),
  SUM(IF(c.status=2, c.sum, 0)),
 SUM(IF(c.status=4, 1, 0)),
  SUM(IF(c.status=4, c.sum, 0)),
 SUM(IF(c.status=6, 1, 0)),
  SUM(IF(c.status=6, c.sum, 0))
from cards_users c
 $WHERE
GROUP BY 1;"
  );

  return $self if ($self->{errno});

  foreach my $line (@{ $self->{list} }) {
    $RESULT{ $line->[0] }{ENABLE}     = $line->[1];
    $RESULT{ $line->[0] }{ENABLE_SUM} = $line->[2];

    $RESULT{ $line->[0] }{DISABLE}     = $line->[3];
    $RESULT{ $line->[0] }{DISABLE_SUM} = $line->[4];

    $RESULT{ $line->[0] }{USED}     = $line->[5];
    $RESULT{ $line->[0] }{USED_SUM} = $line->[6];

    $RESULT{ $line->[0] }{RETURNED}     = $line->[7];
    $RESULT{ $line->[0] }{RETURNED_SUM} = $line->[8];

    $RESULT{ $line->[0] }{TRANSFERRED_TO_PRODUCTION}     = $line->[7];
    $RESULT{ $line->[0] }{TRANSFERRED_TO_PRODUCTION_SUM} = $line->[8];
  }

  #TOtals
  $self->query("select
 SUM(IF(c.status=0, 1, 0)) as enable_total,
  SUM(IF(c.status=0, c.sum, 0)) as enable_total_sum,
 SUM(IF(c.status=1, 1, 0)) as disable_total,
  SUM(IF(c.status=1, c.sum, 0)) as disable_total_sum,
 SUM(IF(c.status=2, 1, 0)) as used_total,
  SUM(IF(c.status=2, c.sum, 0)) as used_total_sum,
 SUM(IF(c.status=3, 1, 0)) as returned_total,
  SUM(IF(c.status=3, c.sum, 0)) as returned_total_sum,
 SUM(IF(c.status=6, 1, 0)) as transferred_to_production_total,
  SUM(IF(c.status=6, c.sum, 0)) as transferred_to_production_total_sum
from cards_users c
 $WHERE ;",
 undef,
 { INFO => 1 }
  );

##Dillers
  $self->query("select c.diller_date, COUNT(*) AS count, SUM(c.sum) AS sum
from cards_users c
 $WHERE_DILLERS
GROUP BY 1;"
  );

  return $self if ($self->{errno});

  foreach my $line (@{ $self->{list} }) {
    $RESULT{ $line->[0] }{DILLERS}     = $line->[1];
    $RESULT{ $line->[0] }{DILLERS_SUM} = $line->[2];
  }

  #TOtals
  $self->query("SELECT COUNT(*) AS dillers_total, SUM(c.sum) AS dillers_total_sum FROM cards_users c
 $WHERE_DILLERS;",
   undef,
    {INFO => 1 }
  );

##Dillers sold
  $self->query("SELECT c.diller_sold_date, COUNT(*), SUM(c.sum)
FROM cards_users c
 $WHERE_DILLERS_SOLD
GROUP BY 1;"
  );

  return $self if ($self->{errno});

  foreach my $line (@{ $self->{list} }) {
    $RESULT{ $line->[0] }{DILLERS_SOLD}     = $line->[1];
    $RESULT{ $line->[0] }{DILLERS_SOLD_SUM} = $line->[2];
  }

  #TOtals
  $self->query("SELECT COUNT(*) AS dillers_sold_total, SUM(c.sum) AS dillers_sold_total_sum
    FROM cards_users c
    $WHERE_DILLERS_SOLD;",
    undef, { INFO => 1 }
  );

##Login
  my $WHERE_USERS = "WHERE c.uid = u.uid and " . join(' AND ', @WHERE_RULES_USERS);

  $self->query("SELECT
    u.activate,
    SUM(IF(u.activate <> '0000-00-00', 1, 0)),
    SUM(IF(u.activate <> '0000-00-00', c.sum, 0))
    FROM (cards_users c, users u)
    $WHERE_USERS
  GROUP BY 1;",
  undef,
  $attr
  );

  return $self if ($self->{errno});

  foreach my $line (@{ $self->{list} }) {
    $RESULT{ $line->[0] }{LOGIN}     = $line->[1];
    $RESULT{ $line->[0] }{LOGIN_SUM} = $line->[2];
  }

  #TOtals
  $self->query("SELECT
     SUM(IF(u.activate <> '0000-00-00', 1, 0)) As login_total,
     SUM(IF(u.activate <> '0000-00-00', c.sum, 0)) AS login_total_sum
    FROM (cards_users c, users u )
   $WHERE_USERS
    ;",
    undef, { INFO=>1 }
  );

  return \%RESULT;
}

#**********************************************************
=head2 cards_report_payments()

=cut
#**********************************************************
sub cards_report_payments {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    push @WHERE_RULES, "(DATE_FORMAT(p.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and DATE_FORMAT(p.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "DATE_FORMAT(p.date, '%Y-%m')='$attr->{MONTH}'";
  }
  else {
    push @WHERE_RULES, "DATE_FORMAT(p.date, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
  }

  my $WHERE .= ($#WHERE_RULES > -1) ? join(' AND ', @WHERE_RULES) : '';

  $self->query("SELECT p.date, u.id AS login, p.sum, pi.fio,
    CONCAT(c.serial,IF($self->{CARDS_NUMBER_LENGTH}>0, MID(c.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), c.number)) AS cards_count,
    pi_d.fio AS diller, u.uid
  FROM payments p
  INNER JOIN users u ON (u.uid=p.uid)
  INNER JOIN cards_users c ON (p.ext_id=CONCAT(c.serial,if($self->{CARDS_NUMBER_LENGTH}>0, MID(c.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), c.number)))
  LEFT JOIN users_pi pi ON (pi.uid=u.uid)
  LEFT JOIN cards_dillers cd ON (c.diller_id=cd.id)
  LEFT JOIN users_pi pi_d ON (pi_d.uid=cd.uid)
  WHERE $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
   undef,
   $attr
  );

  return $self if ($self->{errno});
  my $list = $self->{list};

  $self->query("SELECT COUNT(p.id) AS total, SUM(p.sum) AS TOTAL_SUM
  FROM payments p
  INNER JOIN cards_users c ON (p.ext_id=concat(c.serial,if($self->{CARDS_NUMBER_LENGTH}>0, MID(c.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), c.number)))
  WHERE $WHERE;",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 cards_report_seria($attr)

=cut
#**********************************************************
sub cards_report_seria {
  my $self = shift;
  my ($attr) = @_;

  my $active_date = 'u.activate <> \'0000-00-00\'';
  my $diller_date = 'c.diller_date <> \'0000-00-00\'';
  my @WHERE_RULES = ();

  if (defined($attr->{DATE})) {
    push @WHERE_RULES, " (DATE_FORMAT(c.datetime, '%Y-%m-%d')='$attr->{DATE}' or  DATE_FORMAT(c.diller_date, '%Y-%m-%d')='$attr->{DATE}')";
    $active_date = "u.activate = '$attr->{DATE}'";
    $diller_date = "c.diller_date = '$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "((DATE_FORMAT(c.datetime, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.datetime, '%Y-%m-%d')<='$to') or
    (DATE_FORMAT(c.diller_date, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.diller_date, '%Y-%m-%d')<='$to'))";

    $active_date = "(DATE_FORMAT(u.activate, '%Y-%m-%d')>='$from' and DATE_FORMAT(u.activate, '%Y-%m-%d')<='$to')";
    $diller_date = "(DATE_FORMAT(c.diller_date, '%Y-%m-%d')>='$from' and DATE_FORMAT(c.diller_date, '%Y-%m-%d')<='$to')";
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "(DATE_FORMAT(c.datetime, '%Y-%m')='$attr->{MONTH}' or DATE_FORMAT(diller_date, '%Y-%m')='$attr->{MONTH}')";
    $active_date = 'DATE_FORMAT(u.activate, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
    $diller_date = 'DATE_FORMAT(c.diller_date, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
  }
  else {
    push @WHERE_RULES, "(DATE_FORMAT(c.datetime, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m') or DATE_FORMAT(diller_date, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m') )";
    $active_date = 'DATE_FORMAT(u.activate, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
    $diller_date = 'DATE_FORMAT(c.diller_date, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
  }

  if (defined($attr->{SERIA})) {
    $attr->{SERIA} =~ s/\*/\%/ig;
    push @WHERE_RULES, "cu.serial='$attr->{SERIA}'";
  }

  my $WHERE = "WHERE c.diller_id = cd.id AND cu.domain_id='$admin->{DOMAIN_ID}' ";

  $WHERE .= ($#WHERE_RULES > -1) ? " and " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT cd.name,
       SUM(IF{c.status=0, 1, 0)),
        SUM(IF{c.status=0, c.sum, 0)),
       SUM(IF{c.status=1, 1, 0)),
        SUM(IF{c.status=1, c.sum, 0)),
       SUM(IF{c.status=2, 1, 0)),
        SUM(IF{c.status=2, c.sum, 0)),
       SUM(IF{$active_date, 1, 0)),
        SUM(IF{$active_date, c.sum, 0)),
       SUM(IF{$diller_date, 1, 0)),
        SUM(IF{$diller_date, c.sum, 0)),
       SUM(IF{c.status=4, 1, 0)),
        SUM(IF{c.status=4, c.sum, 0)),
       COUNT(*),
        SUM(c.sum)

    FROM (cards_dillers cd, cards_users c)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     GROUP BY cd.id
     ORDER BY 1;",
     undef,
     $attr
  );

  return $self if ($self->{errno});
  my $list = $self->{list};

  $self->query("SELECT
       SUM(IF{c.status=0, 1, 0)) AS ENABLE_TOTAL,
        SUM(IF{c.status=0, c.sum, 0)) AS ENABLE_TOTAL_SUM,
       SUM(IF{c.status=1, 1, 0)) AS DISABLE_TOTAL,
        SUM(IF{c.status=1, c.sum, 0)) AS DISABLE_TOTAL_SUM,
       SUM(IF{c.status=2, 1, 0)) AS PAYMENT_TOTAL,
        SUM(IF{c.status=2, c.sum, 0)) AS PAYMENT_TOTAL,
       SUM(IF{$active_date, 1, 0)) AS PAYMENT_TOTAL,
        SUM(IF{$active_date, c.sum, 0)) AS PAYMENT_TOTAL_SUM,
       SUM(IF{$diller_date, 1, 0)) AS TAKE_TOTAL,
        SUM(IF{$diller_date, c.sum, 0)) AS TAKE_TOTAL_SUM,
       SUM(IF{c.status=4, 1, 0)) AS LOGIN_TOTAL,
        SUM(IF{c.status=4, c.sum, 0)) AS LOGIN_TOTAL_SUM,
       COUNT(*) AS RETURN_TOTAL,
        SUM(c.sum) AS RETURN_TOTAL_SUM

    FROM (cards_dillers cd, cards_users c)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     ORDER BY 1;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 bruteforce_list($attr)

=cut
#**********************************************************
sub bruteforce_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $fields = "u.id,
               SUM(IF(DATE_FORMAT(cb.datetime, '%Y-%m-%d')=CURDATE(), 1, 0)),
               COUNT(*),
               MAX(datetime),
               cb.uid
               ";

  my $GROUP = "GROUP BY cb.uid";

  my @WHERE_RULES = ();

  if ($attr->{UID}) {
    push @WHERE_RULES, " cb.uid='$attr->{UID}'";

    $fields = "u.id,
               cb.pin,
               datetime";
    $GROUP = "";
  }
  elsif ($attr->{LOGIN}) {
    $attr->{LOGIN} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN}'";
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{DATE}", 'DATE', "DATE_FORMAT(cb.datetime, '%Y-%m-%d')") };
  }

  # if ($admin->{DOMAIN_ID}) {
  #   push @WHERE_RULES, "cb.domain_id='$admin->{DOMAIN_ID}'";
  # }

  if ($attr->{MONTH}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{MONTH}", 'DATE', "DATE_FORMAT(cb.datetime, '%Y-%m')") };
  }

  # Date intervals
  elsif ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(DATE_FORMAT(cb.datetime, '%Y-%m-%d')>='$attr->{FROM_DATE}' and DATE_FORMAT(cb.datetime, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

  if (defined($attr->{SERIA})) {
    $attr->{SERIA} =~ s/\*/\%/ig;
    push @WHERE_RULES, "cp.serial='$attr->{SERIA}'";

    $fields = "
    cp.serial,
              IF($self->{CARDS_NUMBER_LENGTH}>0, MID(cp.number, 11-$self->{CARDS_NUMBER_LENGTH}+1, $self->{CARDS_NUMBER_LENGTH}), cp.number),
              cp.sum,
              cp.status,
              cp.datetime,
              a.id";
    $GROUP = "cp.serial, cp.number";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT $fields
         FROM cards_bruteforce cb
     LEFT JOIN users u ON (cb.uid = u.uid)
     $WHERE
     $GROUP
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
     undef, $attr
  );

  return [] if ($self->{errno});
  my $list = $self->{list};
  $self->{BRUTE_COUNT} = $self->{TOTAL} || 0;

  $self->query("SELECT COUNT(*) AS total FROM cards_bruteforce cb
      LEFT JOIN users u ON (cb.uid = u.uid)
      $WHERE",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 bruteforce_add($attr)

=cut
#**********************************************************
sub bruteforce_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cards_bruteforce', {
    %$attr,
    DATETIME => 'NOW()'
  });

  return $self;
}

#**********************************************************
=head2 bruteforce_del($attr)

=cut
#**********************************************************
sub bruteforce_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{UID}) {
    $WHERE = "WHERE UID='$attr->{UID}'";
  }
  elsif ($attr->{PERIOD}) {
    $WHERE = "WHERE datetime <  now() - INTERVAL $attr->{PERIOD} day ";
  }
  else {
    $WHERE = '';
  }

  $self->query("DELETE FROM cards_bruteforce $WHERE;", 'do');
  return $self;
}

#**********************************************************
=head2  cards_chg_status()

=cut
#**********************************************************
sub cards_chg_status {
  my $self        = shift;

  $self->query("UPDATE cards_users cu, errors_log l SET
      cu.status=2,
      cu.datetime=NOW()
    WHERE cu.login<>''
    AND cu.status=0
    AND cu.login=l.user;",
    'do',
  );

  return $self;
}

#**********************************************************
=head2 cards_gids_change($attr)

=cut
#**********************************************************
sub cards_gids_change {
  my $self = shift;
  my ($attr)=@_;
  my $serial = $attr->{SERIAL};

  my @gids = split(/,\s?/, $attr->{GID});
  $self->query("DELETE FROM cards_gids WHERE serial='$serial';", 'do');

  foreach my $gid ( @gids ) {
    $self->query("INSERT INTO cards_gids (gid, serial) VALUES ('$gid', '$serial');", 'do');
  }

  $admin->action_add($uid, "CARDS_GIDS $serial,", { TYPE=>2 });

  return $self;
}


#**********************************************************
=head2 cards_gids_change($attr)

=cut
#**********************************************************
sub cards_gids_list {
  my $self = shift;
  my ($attr)=@_;

  my $JOIN_WHERE = q{};
  if ($attr->{SERIAL}) {
    $JOIN_WHERE = "AND cg.serial='$attr->{SERIAL}'";
  }

  $self->query("SELECT g.gid, g.name, cg.serial, cg.gid AS assign
   FROM `groups` g
   LEFT JOIN `cards_gids` cg ON (g.gid=cg.gid $JOIN_WHERE)
   GROUP BY g.gid
   ORDER BY 1;",
    undef, $attr);

  my $list = $self->{list} || [];

  return $list;
}

1
