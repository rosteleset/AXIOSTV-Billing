package Bonus_rating;

=head1 NAME

 Make rating for bonus tps

=cut

use strict;
use parent 'main';
our $VERSION = 2.18;
my $MODULE = 'Bonus_rating';
my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new{
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;
  my $self = { };

  bless( $self, $class );

  $self->{db} = $db;

  return $self;
}

#**********************************************************
=head2 info()

=cut
#**********************************************************
sub info{
  my $self = shift;
  my ($id) = @_;

  if ( !$id ){
    return $self;
  }

  $self->query2( "SELECT tp_id,
   rating_from,
   rating_to,
   action AS rating_action,
   comments,
   change_bonus,
   activate_bonus,
   ext_bill_account
  FROM tp_bonus_rating 
   WHERE tp_id = ? ;",
    undef,
    { INFO => 1, Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub change{
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "REPLACE INTO tp_bonus_rating (tp_id, 
   rating_from,
   rating_to,
   action,
   comments,
   change_bonus,
   activate_bonus,
   ext_bill_account 
   )
  VALUES ('$attr->{TP_ID}', '$attr->{RATING_FROM}', '$attr->{RATING_TO}', '$attr->{RATING_ACTION}', '$attr->{COMMENTS}',
   '$attr->{CHANGE_BONUS}', 
   '$attr->{ACTIVE_BONUS}', 
   '$attr->{EXT_BILL_ACCOUNT}');", 'do'
  );

  return $self;
}

#**********************************************************
# users_rating_info()
#**********************************************************
sub users_rating_info{
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  if ( $attr->{LOGIN} ){
    push @WHERE_RULES, @{ $self->search_expr( $attr->{LOGIN}, 'STR', 'u.id' ) };
  }

  if ( $attr->{UID} ){
    push @WHERE_RULES, @{ $self->search_expr( $attr->{UID}, 'STR', 'u.uid' ) };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join( ' and ', @WHERE_RULES ) : '';

  $self->query2(
    "SELECT u.uid AS uid,
 ROUND((100 / (DATEDIFF(CURDATE(), date_format(min(f.date), '%Y-%m-%d'))+1)) * count(f.id), 2) AS rating_per,
 ROUND(( SUM(f.sum) / COUNT(f.id)) * (DATEDIFF( CURDATE(), date_format(min(f.date), '%Y-%m-%d'))+1) - SUM(f.sum), 2) AS rating_fees_sum,
 SUM(f.sum) / COUNT(f.id) as one_percent_sum,
  (DATEDIFF(CURDATE(), date_format(min(f.date), '%Y-%m-%d'))+1) / 100 as one_percent_count
 FROM users u
INNER JOIN fees f ON (f.uid=u.uid)
$WHERE
GROUP BY u.uid
ORDER BY u.id
", undef, { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# change_users_rating()
#**********************************************************
sub change_users_rating{
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  if ( $attr->{LOGIN} ){
    push @WHERE_RULES, @{ $self->search_expr( $attr->{LOGIN}, 'STR', 'u.id' ) };
  }

  if ( $attr->{UID} ){
    push @WHERE_RULES, @{ $self->search_expr( $attr->{UID}, 'STR', 'u.uid' ) };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join( ' and ', @WHERE_RULES ) : '';

  $self->query2(
    "UPDATE users_pi pi, (SELECT u.uid AS uid,
 ROUND((100 / (DATEDIFF(CURDATE(), date_format(min(f.date), '%Y-%m-%d'))+1)) * count(f.id), 2) AS rating_per,
 ROUND(( SUM(f.sum) / COUNT(f.id)) * (DATEDIFF( CURDATE(), date_format(min(f.date), '%Y-%m-%d'))+1) - SUM(f.sum), 2) AS rating_fees_sum
 FROM users u
INNER JOIN fees f ON (f.uid=u.uid)
$WHERE
GROUP BY u.uid
ORDER BY u.id) AS rating
SET _rating=rating.rating_per
WHERE pi.uid=rating.uid
", 'do'
  );

  return $self;
}

#**********************************************************
# change_users_rating()
#**********************************************************
sub change_users_tps_list{
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  if ( $attr->{LOGIN} ){
    push @WHERE_RULES, @{ $self->search_expr( $attr->{LOGIN}, 'STR', 'u.id' ) };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "AND " . join( ' and ', @WHERE_RULES ) : '';

  $self->query2(
    "SELECT dv.uid, br_tp.id AS tp_id, 
pi._rating, br.rating_from, br.rating_to, 
tp.name, tp.tp_id AS old_tp_id
FROM tarif_plans tp
INNER JOIN tp_bonus_rating br ON (tp.tp_id=br.tp_id)
INNER JOIN tarif_plans br_tp ON (br_tp.tp_id=br.action)
INNER JOIN dv_main dv ON (tp.id=dv.tp_id)
INNER JOIN users_pi pi ON (pi.uid=dv.uid)
INNER JOIN users u ON (dv.uid=u.uid)
WHERE dv.disable=0 AND u.disable=0 AND
pi._rating > br.rating_from AND pi._rating < br.rating_to
$WHERE
GROUP BY dv.uid
ORDER BY dv.uid",
    undef, $attr
  );

  return $self->{list};
}

1
