package Conf;

=head1 NAME

  Config

=cut

use strict;
use parent qw(dbcore Exporter);

our $VERSION = 7.00;

our @EXPORT = qw(
  config_list
);

my $admin;
my $CONF;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  $admin    = shift;
  $CONF     = shift;
  my $attr  = shift;

  $admin->{MODULE} = 'Config';
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  if (! $attr->{SKIP_CONF}) {
    $self->query("SELECT param, value FROM config WHERE domain_id = ?",
        undef,
        { Bind => [
          $ENV{DOMAIN_ID} || $admin->{DOMAIN_ID} || 0
        ] });
  }
  #my @non_changed_vars = ('TPL_DIR');

  foreach my $line (@{ $self->{list} }) {
    if($line->[0] eq 'TPL_DIR') {
      next;
    }

    $CONF->{$line->[0]}=$line->[1];
  }

  return $self;
}


#**********************************************************
=head2 config_list($attr) - Config option list

  Arguments:
    $attr
      PARAM
      VALUE
      DOMAIN_ID
      CONF_ONLY - do not show total

  Returns:
    \@list

=cut
#**********************************************************
sub config_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my @WHERE_RULES = ();

  if ($attr->{PARAM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PARAM}, 'STR', 'param') };
  }

  if ($attr->{VALUE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{VALUE}, 'STR', 'value') };
  }
  if($attr->{CUSTOM}){
    push @WHERE_RULES, "param LIKE 'ORGANIZATION_%'";
  }

  push @WHERE_RULES, 'domain_id=\'' . ($admin->{DOMAIN_ID} || $attr->{DOMAIN_ID} || 0) . '\'';

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $list;
  if($self->can('query2')) {
    $self->query2("SELECT param, value FROM config $WHERE ORDER BY $SORT $DESC", undef, $attr);
    $list = $self->{list};

    if (!$attr->{CONF_ONLY} || $self->{TOTAL} > 0) {
      $self->query2("SELECT COUNT(*) AS total FROM config $WHERE", undef, { INFO => 1 });
    }

  }
  else {
    $self->query("SELECT param, value FROM config $WHERE ORDER BY $SORT $DESC", undef, $attr);
    $list = $self->{list};

    if (!$attr->{CONF_ONLY} || $self->{TOTAL} > 0) {
      $self->query("SELECT COUNT(*) AS total FROM config $WHERE", undef, { INFO => 1 });
    }
  }

  return $list || [];
}

#**********************************************************
=head2 config_info($attr) - Get config information

  Arguments:
    $attr
      PARAM
      DOMAIN_ID

=cut
#**********************************************************
sub config_info {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DOMAIN_ID} = 0 if (!$attr->{DOMAIN_ID});

  $self->query("SELECT param, value, domain_id FROM config WHERE param= ? AND domain_id= ? ;",
    undef,
    { INFO => 1,
      Bind => [
      $attr->{PARAM},
      $attr->{DOMAIN_ID} ]
    });

  return $self;
}

#**********************************************************
=head2 config_change($param, $attr)

  Arguments:
    $param
    $attr
       PARAM
       VALUE
       WITHOUT_PARAM_CHANGE - Change without param

=cut
#**********************************************************
sub config_change {
  my $self = shift;
  my ($param, $attr) = @_;
  if ($attr->{WITHOUT_PARAM_CHANGE}) {
    $self->changes({
      CHANGE_PARAM => 'PARAM',
      TABLE        => 'config',
      DATA         => $attr
    });
  }
  else {
    #print "// PARAM => $param, DOMAIN_ID => $attr->{DOMAIN_ID} //<br>";
    $attr->{NAME}=$attr->{$param};
    $self->changes({
      CHANGE_PARAM => 'PARAM,DOMAIN_ID',
      TABLE        => 'config',
      #OLD_INFO     => $self->config_info({ PARAM => $param, DOMAIN_ID => $attr->{DOMAIN_ID} }),
      DATA         => $attr,
      %$attr
    });
  }
  $admin->action_add(0, "CONFIG:$attr->{PARAM}", { TYPE => 2 });

  return $self;
}

#**********************************************************
=head2 config_add($attr)

  Arguments:
    $attr - hash_ref
      PARAM   -
      VALUE   -
      REPLACE -

  Returns:
    Conf instance

=cut
#**********************************************************
sub config_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('config',
    { %$attr,
      DOMAIN_ID => $admin->{DOMAIN_ID}
    },
    { REPLACE => ($attr->{REPLACE}) ? 1 : undef });

  if (!$CONF->{MULTIDOMS_DOMAIN_ID} && $attr->{PAYSYS} && ($admin->{DOMAIN_ID} || $attr->{DOMAIN_ID}) && $attr->{PARAM} && $attr->{PARAM} =~ /_\d+$/g) {
    $self->query_add('config',
      { %$attr,
        DOMAIN_ID => 0
      },
      { REPLACE => ($attr->{REPLACE}) ? 1 : undef });
  }
  $admin->action_add(0, "CONFIG:$attr->{PARAM}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 config_del($id)

=cut
#**********************************************************
sub config_del {
  my $self = shift;
  my ($id, $attr) = @_;

  my %params = (
    param => $id
  );

  if ($attr->{DEL_WITH_DOMAIN}) {
    if (!$CONF->{MULTIDOMS_DOMAIN_ID} && $attr->{PAYSYS} && ($admin->{DOMAIN_ID} || $attr->{DOMAIN_ID}) && $attr->{PARAM} && $attr->{PARAM} =~ /_\d+$/g) {
      $self->query_del('config', undef,  { %params, domain_id => 0 });
    }

    $params{domain_id} = $admin->{DOMAIN_ID};
  }

  $self->query_del('config', undef,  { %params });
  $admin->action_add(0, "CONFIG:$id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 add() - Add config variables

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('config_variables', $attr);
  $admin->action_add(0, "CONFIG_VAR:$attr->{PARAM}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 del($id) - Del config variables

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('config_variables', undef, {  param=> $id });
  $admin->action_add(0, "CONFIG_VAR:$id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'PARAM',
    TABLE        => 'config_variables',
    DATA         => $attr
  });
  $admin->action_add(0, "CONFIG_VAR:$attr->{PARAM}", { TYPE => 2 });

  return $self;
}


#**********************************************************
=head2 info($attr)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM config_variables
    WHERE param= ? ;",
   undef,
   {
     INFO      => 1,
     Bind      => [ $attr->{ID} ],
   }
  );

  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{COMMENTS}) {
    $attr->{COMMENTS}='*'. $attr->{COMMENTS}. '*';
  }

  my $WHERE = $self->search_former($attr, [
      ['PARAM',     'STR',  'param',      ],
      ['COMMENTS',  'STR',  'comments',   ],
    ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT *
        FROM config_variables
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  my $list = $self->{list} || [];

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query("SELECT COUNT(*) AS total FROM config_variables $WHERE",
      undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 check_password($password) - checks for password security

  Arguments:
    $password - string to check
    $config_string - (optional) encoded password constraints
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub check_password {
  my ($password, $config_string) = @_;
  
  $config_string //= $CONF->{CONFIG_PASSWORD};
  
  my $length = $CONF->{PASSWD_LENGTH};
  my ($case, $special_chars) = split(':', $config_string);
  
  if ($case > 3){
    $case = 1;
  }
  if ($special_chars > 3){
    $special_chars = 3;
  }
  
  return 0 if (length $password < $length);
  
  # Construct regexp
  my $case_part = 'a-zA-Z';
  if ($case == 1){
    $case_part = 'A-Z'
  }
  elsif ($case == 2){
    $case_part = 'a-z'
  }
  elsif ($case == 3){
    $case_part = '';
  }
  
  my $special_chars_part = '-_!&%@#:0-9';
  if ($special_chars == 0) {
    $special_chars_part = '0-9'
  }
  elsif ($special_chars == 1) {
    $special_chars_part = '-_!&%@#:';
  }
  elsif ($special_chars == 3) {
    $special_chars_part = '';
  }

  if (
    ( !$case_part || $password =~ /[$case_part]+/ )
    && ( !$special_chars_part || $password =~ /[$special_chars_part]+/ )
  ){
    return 1;
  }
  
  return 0;
}

1;
