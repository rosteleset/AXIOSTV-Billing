package Poll;

=head1 Poll

  Poll - moudle for polls
  VERSION 0.03

=head1 Synopsis

  use Poll;
  my $Poll = Poll->new($db, $admin, \%conf);

=cut

use strict;
use parent qw(dbcore);

my ($admin, $CONF);

#*******************************************************************
=head2 function new() - initialize Poll object

  Arguments:
    $db    -
    $admin -
    %conf  -
  Returns:
    $self object

  Examples:
    $Poll = Poll->new($db, $admin, \%conf);

=cut
#*******************************************************************
sub new {
	my $class = shift;
	my $db = shift;
	($admin, $CONF) = @_;

	my $self = {};
	bless($self, $class);

	$self->{db} = $db;
	$self->{admin} = $admin;
	$self->{conf} = $CONF;

	return $self;
}

#**********************************************************
=head2 add_poll($attr) - add new poll

  Arguments:
    subject     - poll's subject
    description - poll's description
    status      - poll's status
    
  Returns:
	  $self object
	
  Examples:
    $Poll->add_poll({%FORM});

    $Poll->add_poll({
      SUBJECT     => 'Test poll',
      DESCRIPTION => 'Test adding poll',
      STATUS      => 0
    })
  
=cut
#**********************************************************
sub add_poll {
	my $self = shift;
	my ($attr) = @_;

	$self->query_add('poll_polls', {
		DATE => 'NOW()',
		%{$attr}
	});

	return $self;
}

#**********************************************************
=head2 change_poll($attr) - change poll

  Arguments:
    ID          - poll's ID
    SUBJECT     - poll's subject
    DESCRIPTION - poll's description
    
  Returns:
    $self object;

  Examples:
    $Poll->change_poll({ ID => $FORM{id}, %FORM });
  
=cut
#**********************************************************
sub change_poll {
	my $self = shift;
	my ($attr) = @_;

	$self->changes(
		{
			CHANGE_PARAM => 'ID' || 'poll',
			TABLE        => 'poll_polls',
			DATA         => $attr
		}
	);

	return $self;
}

#**********************************************************
=head2 del_poll($attr) - delete poll

  Arguments:
    ID   - poll's ID;
    
  Returns:
    $self object;

  Examples:
    $Poll->del_poll({ID => $FORM{del}});
  
=cut
#**********************************************************
sub del_poll {
	my $self = shift;
	my ($attr) = @_;

	$self->query_del('poll_polls', $attr);

	return $self;
}

#**********************************************************
=head2 info_poll($attr) - get information about poll

  Arguments:
    ID      - tp's ID
    
  Returns:

  Examples:
    $poll_info = $Poll->info_poll({COLS_NAME => 1, ID => 1});
  
=cut
#**********************************************************
sub info_poll {
	my $self = shift;
	my ($attr) = @_;

	if ($attr->{ID} && $attr->{ID} ne '_SHOW') {
		$self->query(
			"SELECT pp.id,
    pp.subject,
    pp.date,
    pp.description,
    pp.status,
    pp.expiration_date,
    pp.domain_id
    FROM poll_polls as pp
      WHERE id = ?;", undef, {
			COLS_NAME => 1,
			Bind      => [
				$attr->{ID}
			]
		});
	}

	return $self->{list}->[0];
}

#**********************************************************
=head2 list_poll($attr) - return list of polls

  Arguments:
    STATUS - poll's status
    
  Returns:
    $self object;

  Examples:
    all polls
    my $tp_list = $Triplay->list_tp({COLS_NAME => 1});

    polls with status eq 2
    my $tp_list = $Triplay->list_tp({COLS_NAME => 1, STATUS => 2});
  
=cut
#**********************************************************
sub list_poll {
	my $self = shift;
	my ($attr) = @_;

	delete $self->{COL_NAMES_ARR};

	my @WHERE_RULES = ();
	my $EXT_TABLES = $self->{EXT_TABLES} || '';
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
	my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

	if (defined($attr->{STATUS})) {
		push @WHERE_RULES, "pp.status = '$attr->{STATUS}' OR pp.status = "
			. ($attr->{ADDITIONAL_STATUS} ? $attr->{ADDITIONAL_STATUS} : $attr->{STATUS});
	}

	if ($attr->{REJECTED_STATUS}) {
		push @WHERE_RULES, "pp.status != '$attr->{REJECTED_STATUS}'";
	}

	if (defined($attr->{EXPIRATION_DATE})) {
		push @WHERE_RULES, "DATE_FORMAT(pp.expiration_date, '%Y-%m-%d')>'$attr->{EXPIRATION_DATE}'"
	}

	if ($self->{admin}{DOMAIN_ID}) {
		push @WHERE_RULES, "pp.domain_id = '$self->{admin}{DOMAIN_ID}'"
	}

	if ($attr->{COUNT_OPEN_POLLS}) {
		$EXT_TABLES .= "LEFT JOIN poll_votes pv ON pp.id = pv.poll_id";
		push @WHERE_RULES, "pv.answer_id IS NULL";
	}

	my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

	$self->query(
		"SELECT
    pp.id,
    pp.subject,
    pp.date,
    pp.description,
    pp.status,
    pp.expiration_date,
    pp.domain_id
    FROM poll_polls as pp
    $EXT_TABLES
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
		undef,
		$attr
	);

	my $list = $self->{list};

	return $self->{list} if ($attr->{TOTAL} < 1);

	$self->query(
		"SELECT count(*) AS total
     FROM poll_polls",
		undef,
		{
			INFO => 1
		}
	);

	return $list;
}

#**********************************************************
=head2 add_answers($attr) - add answers for poll

  Arguments:
    POLL_ID    - poll's id
    ANSWER     - answer
    
  Returns:
    $self object
  
  Examples:
    $Poll->add_answer(
      {
        POLL_ID => 1,
        ANSWER  => a1
      }
    );
  
=cut
#**********************************************************
sub add_answer {
	my $self = shift;
	my ($attr) = @_;

	$self->query_add('poll_answers', { %$attr });

	return $self;
}

#**********************************************************
=head2 info_answer($attr) - get list of answers for poll

  Arguments:
    POLL_ID      - poll's ID
    
  Returns:
    list of answers

  Examples:
    my $answer_info  = $Poll->info_answer({ COLS_NAME => 1, POLL_ID => 1 });
  
=cut
#**********************************************************
sub info_answer {
	my $self = shift;
	my ($attr) = @_;

	if ($attr->{POLL_ID}) {
		$self->query(
			"SELECT pa.id,
    pa.poll_id,
    pa.answer
    FROM poll_answers as pa
    WHERE poll_id = ?;", undef, {
			COLS_NAME => 1,
			Bind      => [
				$attr->{POLL_ID}
			]
		});
	}

	return $self->{list};
}

#**********************************************************
=head2 add_vote($attr) - add vote for answer

  Arguments:
    ANSWER_ID   - answer's id
    POLL_ID     - poll's id
    VOTER       - user's id
    
  Returns:
  
  
  Examples:
    $Poll->add_vote(
      {
        ANSWER_ID => a1,
        POLL_ID   => 1,
        VOTER     => 66
      }
    );
  
=cut
#**********************************************************
sub add_vote {
	my $self = shift;
	my ($attr) = @_;

	$self->query_add('poll_votes', { %$attr });

	return $self;
}


#**********************************************************
=head2 list_vote($attr) - return list of polls

  Arguments:
    ANSWER_ID - answer's id
    POLL_ID   - poll's id
    VOTER     - user's id
    
  Returns:
    $self list;

  Examples:
    my $votes_for_answer = $Poll->list_vote({ COLS_NAME => 1, ANSWER_ID => 1 });
    my $votes_in_poll = $Poll->list_vote({ COLS_NAME => 1, POLL_ID => 1 });
    my $user_voter = $Poll->list_vote({ COLS_NAME => 1, VOTER => 66, POLL_ID => 1 });
  
=cut
#**********************************************************
sub list_vote {
	my $self = shift;
	my ($attr) = @_;

	delete $self->{COL_NAMES_ARR};

	my @WHERE_RULES = ();
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
	my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

	if (defined($attr->{ANSWER_ID})) {
		push @WHERE_RULES, "pv.answer_id = '$attr->{ANSWER_ID}'";
	}

	if (defined($attr->{POLL_ID})) {
		push @WHERE_RULES, "pv.poll_id = '$attr->{POLL_ID}'";
	}

	if (defined($attr->{VOTER})) {
		push @WHERE_RULES, "pv.voter = '$attr->{VOTER}' and pv.poll_id = '$attr->{POLL_ID}'";
	}

	my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

	$self->query(
		"SELECT
    pv.answer_id,
    pv.poll_id,
    pv.voter
    FROM poll_votes as pv
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
		undef,
		$attr
	);

	my $list = $self->{list} || [];

	return $list if (!$attr->{TOTAL});

	$self->query(
		"SELECT COUNT(*) AS total
     FROM poll_votes",
		undef,
		{ INFO => 1 }
	);

	return $list;
}

#**********************************************************
=head2 add_message($attr) - add message for poll

  Arguments:
    
    
  Returns:
    self object
  
  Examples:
    $Poll->add_message(
      {
        POLL_ID => 1,
        VOTER   => test,
        MESSAGE => 'test message',
      }
    );
  
=cut
#**********************************************************
sub add_message {
	my $self = shift;
	my ($attr) = @_;

	$self->query_add('poll_discussion', { DATE => 'NOW()', %{$attr} });

	return $self;
}

#**********************************************************
=head2 list_message($attr) - return list of messages for poll

  Arguments:
    POLL_ID - poll's id
    
  Returns:
    $self object;

  Examples:
    my $list_message = $Poll->list_message({COLS_NAME => 1, POLL_ID => 2});
  
=cut
#**********************************************************
sub list_message {
	my $self = shift;
	my ($attr) = @_;

	delete $self->{COL_NAMES_ARR};

	my @WHERE_RULES = ();
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
	my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

	if (defined($attr->{POLL_ID})) {
		push @WHERE_RULES, "pd.poll_id='$attr->{POLL_ID}'";
	}

	if (defined($attr->{VOTER})) {
		push @WHERE_RULES, "pd.voter = '$attr->{VOTER}' and pd.poll_id = '$attr->{POLL_ID}'";
	}

	my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

	$self->query(
		"SELECT
    pd.id,
    pd.date,
    pd.message,
    pd.poll_id,
    pd.voter
    FROM poll_discussion as pd
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
		undef,
		$attr
	);

	my $list = $self->{list};

	return $self->{list} if ($attr->{TOTAL} < 1);

	$self->query(
		"SELECT count(*) AS total
     FROM poll_discussion",
		undef,
		{ INFO => 1 }
	);

	return $list;
}

#**********************************************************
=head2 open_poll($attr) - return list of messages for poll

  Arguments:
    DOMAIN_ID - user domain_id
    UID       - user UI

  Returns:
    $self object;

  Examples:
    my $list_open_polls = $Poll->open_poll({
      DOMAIN_ID     => ($admin->{DOMAIN_ID} || 0),
      COLS_NAMES    => 1,
      UID           => ($user->{UID} || 1)
    });

=cut
#**********************************************************
sub open_poll {
	my $self = shift;
	my ($attr) = @_;

	$self->query(
		"SELECT COUNT(*) AS total_count
         FROM poll_polls pp
         LEFT JOIN (SELECT pv.poll_id, pv.voter FROM poll_votes pv WHERE pv.voter = ?) AS count_votes
                   ON pp.id = count_votes.poll_id
         WHERE count_votes.voter IS NULL
         AND pp.status = 0
         AND pp.expiration_date > NOW()
         AND pp.domain_id = ?;",
		undef,
		{
			COLS_NAME => 1,
			INFO      => 1,
			Bind      => [
				$attr->{UID},
				$attr->{DOMAIN_ID}
			]
		}
	);

	return $self->{list}[0];
}

1
