package Notepad;

=head2 NAME

  Notepad

=cut

use strict;
use warnings 'FATAL' => 'all';

use parent 'dbcore';

use constant {
  MONTH_DAY => 'MONTH_DAY',
  WEEK_DAY  => 'WEEK_DAY',
  MONTH     => 'MONTH',
  YEAR      => 'YEAR',
  HOUR      => 'HOUR',
  MINUTE    => 'MINUTE'
};

#**********************************************************
=head2 new($db, $admin, \%conf) - constructor

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $self->{db}    = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

  return $self;
}

#**********************************************************
=head2 notes_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub notes_list{
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'n.id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $attr->{AID} ||= $self->{admin}{AID};
  delete $attr->{NOTE_STATUS} if ($attr->{NOTE_STATUS} && $attr->{NOTE_STATUS} eq 'ALL');
  
  #ID,SUBJECT,STATUS,SHOW_AT,CREATED,PERIODIC_RULE_ID
  my $search_columns = [
    [ 'ID',                  'INT',   'n.id'                            ,1],
    [ 'SUBJECT',             'STR',   'n.subject'                       ,1],
    [ 'STATUS',              'INT',   'n.status'                        ,1],
    [ 'STATUS_ST',           'INT',   'n.status_st'                     ,1],
    [ 'SHOW_AT',             'DATE',  'n.show_at'                       ,1],
    [ 'START_STAT',          'TIME',  'n.start_stat'                    ,1],
    [ 'END_STAT',            'TIME',  'n.end_stat'                      ,1],
    [ 'NEW',                 'DATE',  'IF(n.show_at < NOW(), 1, 0) AS new', '(n.show_at < NOW()) AS new' ,1],
    [ 'TEXT',                'STR',   'n.text'                          ,1],
    [ 'PERIODIC_RULE_ID',    'INT',   'nr.rule_id AS periodic_rule_id'  ,1],
    [ 'IS_PERIODIC',         'INT',   'IF(nr.id IS NULL, 0, 1) AS is_periodic'  ,'IF(nr.id IS NULL, 0, 1) AS is_periodic'],
    [ 'CREATED',             'STR',   'n.create_date AS created'        ,1],
    ['HAVE_CHECKLIST',       'INT',   'IF(COUNT(ncl.id) > 0, 1,0) AS have_checklist', 1],
    [ 'AID',                 'INT',   'n.aid'                           ,1],
    [ 'NAME',                'STR',   'IF(adm.name, adm.name, adm.id) AS name' ,1],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  
  my $WHERE =  $self->search_former($attr, $search_columns, {  WHERE => 1 } );

  $self->query( "SELECT $self->{SEARCH_FIELDS} n.id
              FROM notepad n
              LEFT JOIN notepad_reminders nr FORCE INDEX FOR JOIN (`PRIMARY`) ON ( n.id = nr.id )
              LEFT JOIN notepad_checklist_rows ncl ON (n.id = ncl.note_id)
              LEFT JOIN admins adm ON ( adm.aid = n.aid )
   $WHERE
    GROUP BY n.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{ $attr // {}}
    }
  );

  return [] if $self->{errno};

  return $self->{list} || [];
}

#**********************************************************
=head2 notes_info($id)

  Arguments:
    $id - id for notes

  Returns:
    hash_ref

=cut
#**********************************************************
sub notes_info{
  my $self = shift;
  my ($id, $attr) = @_;

  my $list = $self->notes_list( {
    ID               => $id,
    COLS_NAME        => 1,
    SHOW_ALL_COLUMNS => 1,
    COLS_UPPER       => 1,
    %{ $attr // { } }
  } );

  return $list->[0] || {};
}

#**********************************************************
=head2 notes_add($attr)  - Add note

=cut
#**********************************************************
sub notes_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('notepad', {
    %{$attr},
    AID         => $attr->{AID} || $self->{admin}->{AID},
    CREATE_DATE => 'NOW()',
  });

  return 1;
}

#**********************************************************
=head2 notepad_note_change($attr) - Change note

=cut
#**********************************************************
sub notes_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'notepad',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 note_del($attr) -  Del Note

=cut
#**********************************************************
sub notes_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'notepad', $attr );

  return $self->{result};
}


#**********************************************************
=head2 periodic_rules_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub periodic_rules_list{
  my $self = shift;
  my ($attr) = @_;
  
  delete $self->{COL_NAMES_ARR};
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  
  $attr->{AID} ||= $self->{admin}{AID};
  delete $attr->{NOTE_STATUS} if ($attr->{NOTE_STATUS} && $attr->{NOTE_STATUS} eq 'ALL');
  
  my $search_columns = [
    [ 'ID',          'INT',   'id'                    ,1],
    [ 'RULE_ID',     'INT',   'rule_id'               ,1],
    [ 'WEEK_DAY',    'STR',   'week_day'              ,1],
    [ 'MONTH_DAY',   'STR',   'month_day'             ,1],
    [ 'MONTH',       'INT',   'month'                 ,1],
    [ 'HOLIDAYS',    'INT',   'holidays'              ,1],
  ];
  
  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  
  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );
  
  $self->query( "SELECT $self->{SEARCH_FIELDS} id FROM notepad_reminders
   $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
      COLS_NAME => 1,
      COLS_UPPER => 1,
      %{ $attr ? $attr : {}}}
  );
  
  return [] if $self->{errno};
  
  
  return $self->{list};
}


#**********************************************************
=head2 periodic_rules_info($id)

  Arguments:
    $id - id for notepad_reminders

  Returns:
    hash_ref

=cut
#**********************************************************
sub periodic_rules_info {
  my $self = shift;
  my ($id, $attr) = @_;

  my $list = $self->periodic_rules_list({
    ID               => $id,
    COLS_NAME        => 1,
    SHOW_ALL_COLUMNS => 1,
    COLS_UPPER       => 1,
    %{$attr // {}}
  });
  
  return $list->[0] || {};
}

#**********************************************************
=head2 periodic_rules_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub periodic_rules_add{
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_add('notepad_reminders', $attr, { REPLACE => 1 });
  
  return 1;
}

#**********************************************************
=head2 periodic_rules_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub periodic_rules_del{
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_del('notepad_reminders', undef, $attr);
  
  return 1;
}

#**********************************************************
=head2 periodic_rules_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub periodic_rules_change{
  my $self = shift;
  my ($attr) = @_;
  
  # Can save different rules with overlapping fields
  my @fields = qw(
    MINUTE
    HOUR
    WEEK_DAY
    MONTH_DAY
    MONTH
    YEAR
    HOLIDAYS
  );
  
  
  foreach (@fields){
    $attr->{$_} = (defined $attr->{$_}) ? "$attr->{$_}" : 0;
  };

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'notepad_reminders',
    DATA         => $attr,
  });
  
  return 1;
}

#**********************************************************
=head2 checklist_rows_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub checklist_rows_list{
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'ncl.id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    ['ID',             'INT',        'ncl.id'                          ,1 ],
    ['NOTE_ID',        'INT',        'ncl.note_id'                     ,1 ],
    ['NAME',           'STR',        'ncl.name'                        ,1 ],
    ['STATE',          'INT',        'ncl.state'                       ,1 ],
    ['DATETIME',       'DATE',       'ncl.datetime'                    ,1 ],
  ];
  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  $self->query( "SELECT $self->{SEARCH_FIELDS} ncl.id
   FROM notepad_checklist_rows ncl
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr // {}}}
  );

  return [] if $self->{errno};

  return $self->{list} || [];
}

#**********************************************************
=head2 checklist_rows_info($id)

  Arguments:
    $id - id for checklist_rows

  Returns:
    hash_ref

=cut
#**********************************************************
sub checklist_rows_info{
  my $self = shift;
  my ($id) = @_;
  
  my $list = $self->checklist_rows_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );
  
  return $list->[0] || {};
}

#**********************************************************
=head2 checklist_rows_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub checklist_rows_add{
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_add('notepad_checklist_rows', $attr, { REPLACE => 1 });
  
  return 1;
}

#**********************************************************
=head2 checklist_rows_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub checklist_rows_del{
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_del('notepad_checklist_rows', undef, $attr);
  
  return 1;
}

#**********************************************************
=head2 checklist_rows_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub checklist_rows_change{
  my $self = shift;
  my ($attr) = @_;
  
  $attr->{STATE} = (defined $attr->{STATE} && $attr->{STATE}) ? 1 : '0';

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'notepad_checklist_rows',
    DATA         => $attr,
  });
  
  return 1;
}

#**********************************************************
=head2 notepad_get_active_count($attr)

=cut
#**********************************************************
sub notepad_get_active_count{
  my $self = shift;
  my ($attr) = @_;

  $self->query( "SELECT SUM(IF(DATE_FORMAT(show_at, '%Y-%m-%d') = CURDATE(), 1, 0)) AS today,
    SUM(IF(status = 0, 1, 0)) AS active
    FROM notepad n
    WHERE n.aid= ?;",
    undef,
    { Bind => [ $attr->{AID} ],
      INFO => 1 }
  );

  $self->{TODAY} = 0 if (!$self->{TODAY});
  $self->{ACTIVE} = 0 if (!$self->{ACTIVE});

  return $self->{TODAY}, $self->{ACTIVE};
}

#**********************************************************
=head2 show_reminders_list($attr) - returns list of periodic reminders

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub show_reminders_list {
  my $self = shift;
  my ($attr) = @_;

  return $self->notes_list({
    SHOW_ALL_COLUMNS => 1,
    COLS_UPPER       => $attr->{COLS_UPPER} || 1,
    COLS_NAME        => 1,
    STATUS           => 0,
    NEW              => 1,
    AID              => '_SHOW', # Can be overriden in $attr
    %{$attr // {}}
  });
}

#**********************************************************
=head2 _date_is($time, $attr) - checks given epoch timestamp

  checks given epoch timestamp

  Arguments:
    $time - epoch time to check
    $attr - hash_ref with params to check. params are checked one by one
      MONTH_DAY
      WEEK_DAY
      MONTH
      YEAR
      HOUR
      MINUTE
      WORKDAY - boolean
      HOLIDAY - boolean

  Returns:
    true or false

  Examples:
    my $is_holiday             = notepad_date_is( time, { HOLIDAY => 1 } );
    my $is_workday             = notepad_date_is( time, { WORKDAY => 1 } );
    my $is_weekday             = notepad_date_is( time, { WEEK_DAY => 3 } );
    my $is_not_weekday         = notepad_date_is( time, { WEEK_DAY => 1 } );
    my $is_second_month_day    = notepad_date_is( time, { MONTH_DAY => 2 } );
    my $is_second_day_of_march = notepad_date_is( time, { MONTH_DAY => 2, MONTH => 3 } );
    my $is_third_day_of_march  = notepad_date_is( time, { MONTH_DAY => 3, MONTH => 3 } );
    my $is_2016_year           = notepad_date_is( time, { YEAR => '2016' } );
    my $is_2017_year           = notepad_date_is( time, { YEAR => '2017' } );
    my $is_11_hour             = notepad_date_is( time, { HOUR => 11 } );

=cut
#**********************************************************
sub _date_is {
  shift;
  my ($time, $attr) = @_;

  my (undef, $min, $hour, $mday, $mon, $year, $wday) = localtime( $time );

  $wday = ($wday == 0) ? 7 : $wday;
  $mon = $mon + 1;
  my $is = 2;
  while (my ($date_type, $date_value) = each %{$attr}) {
    if ( $attr->{DEBUG} ){ print "<hr> current key:value $date_type = $date_value"}
    if ( !defined $date_value || $date_type eq 'HOLIDAY' || $date_type eq 'DEBUG'){ next }
    if ( $date_type eq HOUR ){
      $is = $date_value <= $hour
    }
    elsif ( $date_type eq MINUTE ){
      $is = $date_value <= $min
    }
    elsif ( $date_type eq MONTH_DAY && $date_value != 0 ){
      if ( $date_value =~ /\,/ ){
        my $result = 0;
        my @days_list = split ( /,\s?/, $date_value );
        foreach my $day ( @days_list ){
          print "Checking ($day == $mday) \n" if ($attr->{DEBUG});
          $result = ($day == $mday);
          print "result $result \n" if ($attr->{DEBUG});
          if ( $result == 1 ){ last };
        }
        $is = $result;
        print "result $result, $is \n" if ($attr->{DEBUG});
      }
      else{
        $is = ($date_value == $mday);
      }
    }
    elsif ( $date_type eq WEEK_DAY && $date_value != 0 ){
      $is = ($date_value == $wday)
    }
    elsif ( $date_type eq MONTH && $date_value != 0 ){
      $is = ($date_value == $mon)
    }
    elsif ( $date_type eq YEAR && $date_value != 0 ){
      $is = ($date_value == $year + 1900)
    }

    if ( $is == 2 ){
      if ($attr->{DEBUG}){
        print "<hr>Exit because not matched anything <br/>";
        require Data::Dumper;
        Data::Dumper->import();
        print Dumper {
              $attr->{MINUTE}    => $min,
              $attr->{HOUR}      => $hour,
              $attr->{MONTH_DAY} => $mday,
              $attr->{MONTH}     => $mon,
              $attr->{YEAR}      => $year,
              $attr->{WEEK_DAY}  => $wday
            };
      }
      return 0;
    }
    elsif ( $is == 0 ){
      if ( $attr->{DEBUG} ){
        print "<hr>Exit on $date_type: $date_value <br/>";
        require Data::Dumper;
        Data::Dumper->import();
        print Dumper [ $min, $hour, $mday, $mon, $year, $wday ];
      }
      return 0;
    };
  }

  if ( $is && $attr->{HOLIDAY} && $attr->{HOLIDAY} != 1 ){
    $is = $wday <= 5;
  }

  return $is;
}

#**********************************************************
=head2 notepad_now_is($attr)

  translates now to notepad_date_is(). See notepad_date_is() for comments

  Arguments:
    $attr - hash_ref

  Returns:
    true or false

=cut
#**********************************************************
sub _now_is{
  my $self = shift;
  return $self->_date_is( time, @_ );
}

#**********************************************************
=head2 function get_sticker() - get sticker data

  Arguments:
    $attr
      AID

  Returns:
    @list

  Examples:
    my $list = $Notepad->get_sticker({COLS_NAME=>1});

=cut
#**********************************************************
sub get_sticker {
  my $self = shift;
  my ($attr) = @_;

  $attr->{AID} //= 0;
  $self->query(
    "SELECT id,status,subject,text,status_st,aid
    FROM notepad
    WHERE aid = ?
    AND status <> 2",
    undef, {
      COLS_NAME => 1,
      Bind      => [ $attr->{AID} ]
    }
  );

  return $self->{list};
}

1;
