package Expert;

=head1 NAME

 Expert pm

=cut

use strict;
use parent qw(dbcore);

my $MODULE = 'Expert';

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

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
=head2 question_info($question_id)

=cut
#**********************************************************
sub question_info {
  my $self = shift;
  my ($question_id) = @_;

  $self->query("SELECT *
    FROM expert_question
    WHERE id = ?",
    undef,
    { INFO => 1, Bind => [ $question_id ] }
  );

  return $self;
}

#**********************************************************
=head2 question_list()

=cut
#**********************************************************
sub question_list {
  my $self = shift;

  $self->query("SELECT *
    FROM expert_question;",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 question_add($attr)

=cut
#**********************************************************
sub question_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('expert_question', $attr);

  return $self;
}

#**********************************************************
=head2 question_change($id, $question, $description)

=cut
#**********************************************************
sub question_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'expert_question',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 answers_info($answer_id)

=cut
#**********************************************************
sub answers_info {
  my $self = shift;
  my ($answer_id) = @_;

  $self->query("SELECT *
    FROM expert_answer
    WHERE id = ?",
    undef,
    { INFO => 1, Bind => [ $answer_id ] }
  );

  return $self;
}


#**********************************************************
=head2 answers_list($question_id)

=cut
#**********************************************************
sub answers_list {
  my $self = shift;
  my ($question_id) = @_;

  $self->query("SELECT *
    FROM expert_answer
    WHERE question_id = ?",
    undef,
    { COLS_NAME => 1, Bind => [ $question_id ] }
  );

  return $self->{list};
}

#**********************************************************
=head2 answer_add($attr)

=cut
#**********************************************************
sub answer_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('expert_answer', $attr);

  return $self;
}

#**********************************************************
=head2 answer_change($id, $answer)

=cut
#**********************************************************
sub answer_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{ID} = $attr->{ANSWER_ID};

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'expert_answer',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 faq_add() - add info

=cut
#**********************************************************
sub faq_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('expert_faq', $attr);

  return $self;
}

#**********************************************************
=head2 faq_del() - delete faq

=cut
#**********************************************************
sub faq_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('expert_faq', { ID => $id });

  return $self;
}

#**********************************************************
=head2 faq_change() - change info of faq

=cut
#**********************************************************
sub faq_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'expert_faq',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 faq_list() - list of faq

=cut
#**********************************************************
sub faq_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @search_columns = (
    [ 'ID',        'INT',    'ef.id',     1],
    [ 'TITLE',     'STR',    'ef.title',  1],
    [ 'BODY',      'STR',    'ef.body',   1],
    [ 'TYPE',      'INT',    'ef.type',   1],
    [ 'ICON',      'STR',    'ef.icon',   1],
  );

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @search_columns;
  }

  my $WHERE = $self->search_former($attr, \@search_columns,
    { WHERE => 1 }
  );

  $self->query("
    SELECT
      $self->{SEARCH_FIELDS}
      ef.id
    FROM expert_faq ef
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    { %$attr,
      COLS_NAME  => 1,
    }
  );

  my $list = $self->{list};

  return [] if ($self->{errno} || $self->{TOTAL} < 1);

  $self->query("SELECT COUNT(ef.id) AS total
   FROM expert_faq ef
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

1;
