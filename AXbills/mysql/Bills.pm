package Bills;

=head1 NAME

  Bills accounts manage functions

=cut

use strict;
our $VERSION = 2.00;
use parent qw(dbcore);
my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 create($attr) - Create bill account

=cut
#**********************************************************
sub create {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('bills', { %$attr, 
  	                          REGISTRATION => 'NOW()' 
  	                        });

  $self->{BILL_ID} = $self->{INSERT_ID} if (!$self->{errno});

  return $self;
}

#**********************************************************
=head2 action($type, $BILL_ID, $SUM, $attr) - Bill account action

  Arguments:
   $type
       add
       take
   $BILL_ID
   $SUM
   $SUM
   $attr

  Return:
    $self

=cut
#**********************************************************
sub action {
  my $self = shift;
  my ($type, $BILL_ID, $SUM) = @_;
  my $value = '';

  if ($SUM == 0) {
    $self->{errstr} = 'WRONG_SUM 0';
    return $self;
  }
  elsif ($type eq 'take') {
    $value = '-';
  }
  elsif ($type eq 'add') {
    $value = '+';
  }
  else {
    $self->{errstr} = 'Select action';
    return $self;
  }

  $self->query("UPDATE bills SET deposit=deposit$value ? WHERE id= ? ;", 'do', { Bind => [ $SUM, $BILL_ID ] });

  return $self;
}

#**********************************************************
=head2 change($attr) -  Change bill account

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    BILL_ID    => 'id',
    UID        => 'uid',
    COMPANY_ID => 'company_id',
    DEPOSIT    => 'deposit'
  );

  my $bills_old_info = $self->info({ BILL_ID => $attr->{BILL_ID} });

  delete $admin->{MODULE};
  $self->changes({
    CHANGE_PARAM    => 'BILL_ID',
    TABLE           => 'bills',
    FIELDS          => \%FIELDS,
    OLD_INFO        => $self->info({ BILL_ID => $attr->{BILL_ID} }),
    DATA            => $attr,
    EXT_CHANGE_INFO => "BILL_ID: $attr->{BILL_ID} DEPOSIT: $bills_old_info->{DEPOSIT} -> $attr->{DEPOSIT}",
    ACTION_ID       => 40
  });

  return $self;
}

#**********************************************************
=head2 list($attr) - list bill accounts

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';
  if (defined($attr->{COMPANY_ONLY})) {
    $WHERE = "WHERE b.company_id>0";
    if (defined($attr->{UID})) {
      $WHERE .= " OR b.uid='$attr->{UID}'";
    }
  }
  elsif ($attr->{UID}) {
    $WHERE .= "WHERE b.uid='$attr->{UID}'";
    if ($attr->{BILL_ID}) {
      $WHERE .= " AND b.id='$attr->{BILL_ID}'";
    }
  }
  elsif ($attr->{COMPANY_ID}) {
    $WHERE .= "WHERE b.company_id='$attr->{COMPANY_ID}'";
    if ($attr->{BILL_ID}) {
      $WHERE .= " AND b.id='$attr->{BILL_ID}'";
    }
  }

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->query("SELECT b.id,
     b.deposit,
     u.id AS login,
     c.name AS company_name,
     b.uid,
     b.company_id
     FROM bills b
     LEFT JOIN users u ON  (b.uid=u.uid) 
     LEFT JOIN companies c ON (b.company_id=c.id) 
     $WHERE 
     GROUP BY 1
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 del($attr) - Dell bill account

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM bills WHERE id= ? ;", 'do', { Bind => [ $attr->{BILL_ID} ] });

  return $self;
}

#**********************************************************
=head2 info($attr) - Bill account information

  Arguments:
    $attr
      BILL_ID

  Returns:
    $self

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT b.id AS bill_id, 
     b.deposit AS deposit, 
     u.id AS login, 
     b.uid, 
     b.company_id
    FROM bills b
    LEFT JOIN users u ON (u.uid = b.uid)
    WHERE b.id= ? ;",
    undef,
    { INFO => 1,
    	Bind => [ $attr->{BILL_ID} ] }
  );

  return $self;
}

1
