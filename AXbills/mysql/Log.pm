package Log;

=head1 NAME
  Make logs DB or File mode

  Error levels

    LOG_EMERG   => 0
    LOG_ALERT   => 1
    LOG_CRIT    => 2
    LOG_ERR     => 3
    LOG_WARNING => 4
    LOG_NOTICE  => 5
    LOG_INFO    => 6
    LOG_DEBUG   => 7
    LOG_SQL     => 8

=cut

use strict;
use base qw(Exporter dbcore);
use POSIX qw(strftime);
our @EXPORT_OK = qw(log_add log_print);

# Log levels. For details see <syslog.h>
our %log_levels = (
  'LOG_EMERG'   => 0, # system is unusable
  'LOG_ALERT'   => 1, # action must be taken immediately
  'LOG_CRIT'    => 2, # critical conditions
  'LOG_ERR'     => 3, # error conditions
  'LOG_WARNING' => 4, # warning conditions
  'LOG_NOTICE'  => 5, # normal but significant condition
  'LOG_INFO'    => 6, # informational
  'LOG_DEBUG'   => 7, # debug-level messages
  'LOG_SQL'     => 8, # SQL debuginf
  'LOG_UNKNOWN' => 10 # For unknow log message
);

#**********************************************************
=head2 new($db, $CONF, $attr) Log new

  Arguments:
    $db
    $CONF
    $attr
      DEBUG_LEVEL
      LOG_FILE

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $CONF, $attr) = @_;

  my $self = {
    db   => $db,
    conf => $CONF
  };

  bless($self, $class);

  if ($attr->{DEBUG_LEVEL}) {
    my %rev_log_level = reverse %log_levels;
    for(my $i=0; $i<=$attr->{DEBUG_LEVEL}; $i++) {
      $self->{debugmods} .= "$rev_log_level{$i} ";
    }
  }

  if ($attr->{LOG_FILE}) {
    $self->{LOG_FILE} = $attr->{LOG_FILE};
  }
  
  if ($attr->{USER_NAME}){
    $self->{USER_NAME} = $attr->{USER_NAME};
  }

  #if ($CONF->{LOGFILE}) {
  #  $self->{LOG_FILE} = $CONF->{LOGFILE};
  #}

  return $self;
}

#**********************************************************
=head2 log_list($attr) - Log list

=cut
#**********************************************************
sub log_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{TEXT}) {
    push @WHERE_RULES, "message REGEXP '$attr->{TEXT}'";
  }

  my $WHERE =  $self->search_former($attr, [
      ['DATE',              'DATE', "DATE_FORMAT(l.date, '%Y-%m-%d')", 1 ],
      ['LOG_TYPE',          'INT',  'l.log_type',                      1 ],
      ['ACTION',            'STR',  'l.action',                        1 ],
      ['LOGIN',             'STR',  'l.user',                          1 ],
      ['USER',              'STR',  'l.user',                          1 ],
      ['MESSAGE',           'STR',  'l.message',                       1 ],
      ['NAS_ID',            'INT',  'l.nas_id',                        1 ],
      ['REQUEST_COUNT',     'INT',  'l.request_count',                 1 ],
      ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(l.date, '%Y-%m-%d')",   ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query("SELECT l.date, l.log_type, l.action, l.user, l.message, $self->{SEARCH_FIELDS} l.nas_id
  FROM errors_log l
  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list} || [];
  $self->{OUTPUT_ROWS} = $self->{TOTAL};

  $self->query("SELECT l.log_type, COUNT(*) AS count
  FROM errors_log l
  $WHERE
  GROUP BY 1
  ORDER BY 1;",
  undef,
  $attr
  );

  return $list;
}

#**********************************************************
=head2 log_print($LOG_TYPE, $USER_NAME, $MESSAGE, $attr) - Make log records

  Arguments:
    $LOG_TYPE   -
    $USER_NAME  -
    $MESSAGE    -
    $attr       -
      LOG_FILE  - Log file
      ACTION    -
      NAS       - NAS object
      PRINT     - Print message
      LOG_LEVEL - Current log level for system

  Results:
    $self

  Examples:
  DB save
    $Log->log_print('LOG_WARNING', $online->{user_name}, "Last Alive: $online->{last_alive}, Session-ID: $online->{acct_session_id}", { ACTION => 'CALCULATION', NAS => $Nas });

  File save
    $Log->log_print('LOG_ERR', '', "Some SQL error", { LOG_FILE => "/usr/axbills/var/log/sql_errors" });

=cut
#**********************************************************
sub log_print {
  my $self = shift;
  my ($LOG_TYPE, $USER_NAME, $MESSAGE, $attr) = @_;
  my $Nas = $attr->{NAS} || undef;

  my $action = $attr->{'ACTION'} || $self->{ACTION} || '';

  if ($attr->{LOG_FILE}) {
    $self->{LOG_FILE} = $attr->{LOG_FILE};
  }

  if ($self->{debugmods}) {
    $self->{conf}->{debugmods}=$self->{debugmods};
  }

  if (! defined($LOG_TYPE)) {
    $LOG_TYPE = 'LOG_UNKNOWN';
  }

  my $make_log = 0;
  if ($attr->{LOG_LEVEL}) {
    if ($log_levels{$LOG_TYPE} <= $attr->{LOG_LEVEL}) {
      $make_log = 1;
    }
  }
  elsif(!$self->{conf}->{debugmods} || $self->{conf}->{debugmods} =~ /$LOG_TYPE/) {
    $make_log = 1;
  }

  if ($make_log) {
    if (!$self->{LOG_FILE}) {
      $self->log_add(
        {
          LOG_TYPE  => $log_levels{$LOG_TYPE},
          ACTION    => $action,
          USER_NAME => $USER_NAME || $self->{USER_NAME},
          MESSAGE   => $MESSAGE,
          NAS_ID    => $Nas->{NAS_ID} || 0
        }
      );
    }
    else {
      my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
      my $TIME = POSIX::strftime("%H:%M:%S", localtime(time));

      my $nas  = (defined($Nas->{NAS_ID})) ? "NAS: $Nas->{NAS_ID} ($Nas->{NAS_IP}) " : '';
      my $logfile = $self->{LOG_FILE};

      if (open(my $fh, '>>', "$logfile")) {
        my $user_name = ($USER_NAME) ? "[$USER_NAME]" : '';
        print $fh "$DATE $TIME $LOG_TYPE: $action $user_name $nas$MESSAGE\n";
        close($fh);
      }
      elsif (!$self->{SILENT}) {
        print "Content-Type: text/html\n\n";
        print "Can't open file '$logfile' $!\n";
      }
    }

    if ($self->{PRINT} || $attr->{PRINT}) {
      my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
      my $TIME = POSIX::strftime("%H:%M:%S", localtime(time));
      my $nas = (defined($Nas->{NAS_ID})) ? "NAS: $Nas->{NAS_ID} ($Nas->{NAS_IP}) " : '';
      print "$DATE $TIME $LOG_TYPE: $action [". ($USER_NAME || '') . "] $nas$MESSAGE\n";
    }
  }

  return $self;
}

#**********************************************************
=head2 log_add($attr) - Add log records to DB

  Arguments:
    $attr
      LOG_TYPE
      ACTION
        AUTH
        ACCT
        HANGUP
        LOST_ALIVE
        CALCULATIO
      USER_NAME
      MESSAGE
      NAS_ID

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub log_add {
  my $self = shift;
  my ($attr) = @_;

  if ($self->{conf}->{CONNECT_LOG}) {
    $self->query("SELECT request_count FROM errors_log
      WHERE
       date > CURDATE()
       AND user= ?
       AND message = ?
       AND nas_id= ?
      FOR UPDATE
      ;",
    undef,
    { Bind => [
      $attr->{USER_NAME},
      $attr->{MESSAGE},
      ($attr->{NAS_ID}) ? $attr->{NAS_ID} : 0
    ]});

    if ($self->{TOTAL}) {
      $self->query('UPDATE errors_log SET
          request_count = request_count + 1,
          date = NOW()
        WHERE
           date > curdate()
           AND action = ?
           AND user = ?
           AND message = ?
           AND nas_id =? ;
         ',
        'do',
        { Bind => [
          $attr->{ACTION},
          $attr->{USER_NAME} || '-',
          $attr->{MESSAGE},
          ($attr->{NAS_ID}) ? $attr->{NAS_ID} : 0
        ] }
      );
    }
    else {
      $self->query("INSERT INTO errors_log (date, log_type, action, user, message, nas_id, request_count)
  VALUES (NOW(), ?, ?, ?, ?, ?, 1);",
        'do',
        { Bind => [ $attr->{LOG_TYPE},
          $attr->{ACTION},
          $attr->{USER_NAME} || '-',
          $attr->{MESSAGE},
          (!$attr->{NAS_ID}) ? 0 : $attr->{NAS_ID}
        ] }
      );
    }
  }
  else {
    $self->query("INSERT INTO errors_log (date, log_type, action, user, message, nas_id)
  VALUES (NOW(), ?, ?, ?, ?, ?);",
      'do',
      { Bind => [ $attr->{LOG_TYPE},
        $attr->{ACTION},
        $attr->{USER_NAME} || '-',
        $attr->{MESSAGE},
        (!$attr->{NAS_ID}) ? 0 : $attr->{NAS_ID}
      ] }
    );
  }

  return 0;
}

#**********************************************************
=head2 log_del($attr) - Del log records

=cut
#**********************************************************
sub log_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM errors_log WHERE user= ? ;", 'do', { Bind => [ $attr->{LOGIN} ] });

  return 0;
}


#**********************************************************
=head2 log_reports() - Show log reports

  Arguments:
    $attr
      RETRIES

  Returns:
    hash_ref_array

=cut
#**********************************************************
sub log_reports {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{RETRIES}) {
    $self->query("SELECT user, COUNT(*) AS count FROM errors_log WHERE date>CURDATE()
      GROUP BY user
      ORDER BY 2 DESC
      LIMIT $attr->{RETRIES};", undef, $attr);
  }

  my $list = $self->{list};

  return $list;
}


1

