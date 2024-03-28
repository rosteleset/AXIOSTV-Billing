package Multidoms;

=head1 NAME

   Multidomain system

=head1 VERSION

  VERSION: 9.00
  REVISION: 20210223

=cut

use strict;
use parent qw(dbcore);
use Tariffs;
use Users;
use Fees;

our $VERSION = 9.21;
my $MODULE   = 'Multidoms';
my $admin;
my $CONF;


#++********************************************************
# Init
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

  return $self;
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
    push @WHERE_RULES, " (c.diller_sold_date='$attr->{DATE}' or date_format(c.datetime, '%Y-%m-%d')='$attr->{DATE}' or  date_format(c.diller_date, '%Y-%m-%d')='$attr->{DATE}')";
    $active_date      = "u.activate = '$attr->{DATE}'";
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
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "(DATE_FORMAT(c.datetime, '%Y-%m')='$attr->{MONTH}' or DATE_FORMAT(diller_date, '%Y-%m')='$attr->{MONTH}')";
    $active_date = 'DATE_FORMAT(u.activate, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
    $diller_date = 'DATE_FORMAT(c.diller_date, \'%Y-%m\') <> ' . "'$attr->{MONTH}\'";
  }
  else {
    push @WHERE_RULES, "(DATE_FORMAT(c.datetime, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m') or DATE_FORMAT(diller_date, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m') )";
  }

  my $GROUP = ($attr->{GROUP}) ? $attr->{GROUP} : 'cd.name';

  my $WHERE =  $self->search_former($attr, [
      ['SERIA',       'STR', 'cu.serial',                ],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
    );

  #By cards
  my $list;
  if ($attr->{GROUP}) {
    $self->query("SELECT $GROUP,
       sum(if(c.status=0, 1, 0)),
        sum(if(c.status=0, c.sum, 0)),
       sum(if(c.status=1, 1, 0)),
        sum(if(c.status=1, c.sum, 0)),
       sum(if(c.status=2, 1, 0)),
        sum(if(c.status=2, c.sum, 0)),
       sum(if($active_date, 1, 0)),
        sum(if($active_date, c.sum, 0)),
       sum(if($diller_date, 1, 0)),
        sum(if($diller_date, c.sum, 0)),
       sum(if($diller_sold_date, 1, 0)),
        sum(if($diller_sold_date, c.sum, 0)),
         sum(if($diller_sold_date, c.sum / 100 * cd.percentage, 0)), 
       sum(if(c.status=4, 1, 0)),
        sum(if(c.status=4, c.sum, 0)),
       count(*),
        sum(c.sum)

    FROM cards_users c
    LEFT join cards_dillers cd ON (c.diller_id = cd.id)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     GROUP BY 1
     ORDER BY 1;",
     undef,
     $attr
    );

    return $self if ($self->{errno});
    $list = $self->{list};

    $self->query("SELECT
       sum(if(c.status=0, 1, 0)) AS enable_total,
        sum(if(c.status=0, c.sum, 0)) AS enable_total_sum,
       sum(if(c.status=1, 1, 0)) AS disable_total,
        sum(if(c.status=1, c.sum, 0)) AS disable_total_sum,
       sum(if(c.status=2, 1, 0)) AS payment_total,
        sum(if(c.status=2, c.sum, 0)) AS payment_total_sum,
       sum(if($active_date, 1, 0)) AS login_total,
        sum(if($active_date, c.sum, 0)) AS login_total_sum,
       sum(if($diller_date, 1, 0)) as take_total,
        sum(if($diller_date, c.sum, 0)) as take_total_sum,
       sum(if($diller_sold_date, 1, 0)) as sold_total,
        sum(if($diller_sold_date, c.sum, 0)) as sold_total_sum,
         sum(if($diller_sold_date, c.sum / 100 * cd.percentage, 0)) as sold_total_percentage, 
       sum(if(c.status=4, 1, 0)) as return_total,
        sum(if(c.status=4, c.sum, 0)) as return_total_sum,
       count(*) as count_total,
        sum(c.sum) as count_total_sum

    FROM (cards_users c)
    LEFT join cards_dillers cd ON (c.diller_id = cd.id)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     ORDER BY 1;",
     undef,
     { INFO => 1 }
    );

  }

  # By dillers
  else {
    $WHERE = "WHERE c.diller_id = cd.id ";
    $WHERE .= ($#WHERE_RULES > -1) ? " and " . join(' and ', @WHERE_RULES) : '';

    $self->query("SELECT $GROUP,
       sum(if(c.status=0, 1, 0)),
        sum(if(c.status=0, c.sum, 0)),
       sum(if(c.status=1, 1, 0)),
        sum(if(c.status=1, c.sum, 0)),
       sum(if(c.status=2, 1, 0)),
        sum(if(c.status=2, c.sum, 0)),
       sum(if($active_date, 1, 0)),
        sum(if($active_date, c.sum, 0)),
       sum(if($diller_date, 1, 0)),
        sum(if($diller_date, c.sum, 0)),
       sum(if($diller_sold_date, 1, 0)),
        sum(if($diller_sold_date, c.sum, 0)),
         sum(if($diller_sold_date, c.sum / 100 * cd.percentage, 0)),
       sum(if(c.status=4, 1, 0)),
        sum(if(c.status=4, c.sum, 0)),
       count(*),
        sum(c.sum),
       c.diller_id
    FROM (cards_dillers cd, cards_users c)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     GROUP BY 1
     ORDER BY 1;",
     undef,
     $attr
    );

    return $self if ($self->{errno});
    $list = $self->{list};

    $self->query("SELECT
       sum(if(c.status=0, 1, 0)) as enable_total,
        sum(if(c.status=0, c.sum, 0)) as enable_total_sum,
       sum(if(c.status=1, 1, 0)) as disable_total,
        sum(if(c.status=1, c.sum, 0)) as disable_total_sum,
       sum(if(c.status=2, 1, 0)) as payment_total,
        sum(if(c.status=2, c.sum, 0)) as payment_total_sum,
       sum(if($active_date, 1, 0)) as take_total,
        sum(if($active_date, c.sum, 0)) as take_total_sum,
       sum(if($diller_date, 1, 0)) as sold_total,
        sum(if($diller_date, c.sum, 0)) as sold_total_sum,
       sum(if($diller_sold_date, 1, 0)) as sold_total_percentage,
        sum(if($diller_sold_date, c.sum, 0)) as return_total,
         sum(if($diller_sold_date, c.sum / 100 * cd.percentage, 0)) as return_total_sum,
       sum(if(c.status=4, 1, 0)) as count_total,
        sum(if(c.status=4, c.sum, 0)) ,
       count(*) as count_total,
        sum(c.sum) as count_total_sum

    FROM (cards_dillers cd, cards_users c)
    LEFT JOIN users u ON (c.uid = u.uid)
     $WHERE
     ORDER BY 1;",
     undef,
     { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 multidoms_domain_add($attr)

=cut
#**********************************************************
sub multidoms_domain_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('domains', { %$attr,
  	                            CREATED => 'NOW()' });

  $admin->system_action_add("DOMAIN:$attr->{NAME}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 multidoms_domain_info($attr)

=cut
#**********************************************************
sub multidoms_domain_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM domains
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 multidoms_domain_change($attr)

=cut
#**********************************************************
sub multidoms_domain_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;

  $attr->{ID} = $attr->{chg};

  $admin->{MODULE} = $MODULE;
  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'domains',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 multidoms_domains_list($attr)

=cut
#**********************************************************
sub multidoms_domains_list {
  my $self   = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG   = ($attr->{PG})   ? $attr->{PG}   : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $WHERE =  $self->search_former($attr, [
      ['NAME',           'STR', 'd.name',                 1 ],
      ['STATE',          'INT', 'd.state',                1 ],
      ['COMMENTS',       'STR', 'd.comments'                ],
      ['ID',             'INT', 'd.id'                      ]
    ],
    { WHERE => 1,
    }
  );

  $self->query("SELECT d.id, d.name, d.state, d.created
         FROM domains d
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return $self if ($self->{errno});
  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(d.id) AS total FROM domains d
      $WHERE ",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 multidoms_domain_del(attr);

=cut
#**********************************************************
sub multidoms_domain_del {
  my $self = shift;
  my ($attr) = @_;
  
  $self->query_del('domains', $attr);

  $admin->system_action_add("DOMAIN:$attr->{ID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
=head2 nas_tp_info($attr)

=cut
#**********************************************************
sub nas_tp_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM multidoms_nas_tps
    WHERE nas_id= ? AND domain_id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{NAS_ID}, $attr->{DOMAIN_ID} ] }
  );

  return $self;
}

#**********************************************************
=head nas_tp_add($attr)

=cut
#**********************************************************
sub nas_tp_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('multidoms_nas_tps', { %$attr, DATETIME => 'NOW()' });

  return $self->{result};
}

#**********************************************************
=head2 nas_tp_change($attr);

=cut
#**********************************************************
sub nas_tp_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE multidoms_nas_tps SET bonus_cards=bonus_cards+1
    WHERE nas_id= ? AND domain_id= ? ;", 
    'do',
    { Bind => [ $attr->{NAS_ID}, $attr->{DOMAIN_ID}  ] }
  );

  return $self->{result};
}


#**********************************************************
=head2 admins_list($attr) - Admin domain list

=cut
#**********************************************************
sub admins_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{ALL}) {

  }
  else {
    $WHERE = ($attr->{AID}) ? "AND ad.aid='$attr->{AID}'" : "AND ad.aid='$self->{AID}'";
  }

  $self->query("SELECT ad.domain_id, ad.aid, d.name
    FROM domains_admins ad, domains d
    WHERE d.id=ad.domain_id $WHERE;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 admins_change($attr)

  Arguments:
    $attr
      AID
      DOMAIN_ID

=cut
#**********************************************************
sub admin_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('domains_admins', undef, { aid => $attr->{AID} });
  my @groups = split(/,\s?/, $attr->{DOMAIN_ID});
  my @MULTI_QUERY = ();

  foreach my $gid (@groups) {
    push @MULTI_QUERY, [ $attr->{AID}, $gid ];
  }

  $self->query("INSERT INTO domains_admins (aid, domain_id) VALUES (?, ?);",
    undef,
    { MULTI_QUERY =>  \@MULTI_QUERY });

  $self->{admin}->system_action_add("AID:$attr->{AID} DOMAIN_ID: " . (join(',', @groups)), { TYPE => 2 });

  return $self;
}


#**********************************************************
=head2 domain_modules_change($id, @modules_array)
    $id             - domain id
    @modules_array  - array of modules name

=cut
#**********************************************************
sub domain_modules_change {
  my $self = shift;
  my ($id, @modules_list) = @_;
 
  $self->query_del('domains_modules', { ID => $id });
  
  foreach (@modules_list) {
    $self->query_add('domains_modules', { ID => $id, MODULE => $_ } );
  }
  
  $admin->system_action_add("DOMAIN: modules_change", { TYPE => 2 });

  return $self;
}

#**********************************************************
=head domain_modules_info($attr)
  Attr
    ID => Domain_id
    
  Return
    array of modules name

=cut
#**********************************************************
sub domain_modules_info {
  my $self = shift;
  my ($attr) = @_;

  my @dm_modules = ();

  if(! $attr->{ID}) {
    return \@dm_modules;
  }

  $self->query("SELECT module FROM domains_modules
    WHERE id = ? ;",
    undef,
    {
      Bind => [ $attr->{ID} ]
    }
  );

  my $module_list = $self->{list} || [ ];

  foreach my $line (@$module_list) {
    push @dm_modules, $line->[0];
  }

  return \@dm_modules;
}

1

