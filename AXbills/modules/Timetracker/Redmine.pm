package Redmine;

=head1 NAME

  Redmine

=head2 FILENAME

  Redmine.pm

=head2 VERSION

  VERSION: 0.2
  REVISION: 20200806

=head2 SYNOPSIS

=cut

use warnings FATAL => 'all';
use strict;
use AXbills::Fetcher qw/web_request/;


#**********************************************************
=head2 new

  Instantiation object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 get_closed_issues($attr) - returns array closed issues from redmine
  Arguments:
    $attr = {
      FROM_DATE => '2020-01-01',
      TO_DATE => '2020-02-20',
      DEBUG => 0,
      ADMIN_AIDS => [1, 2, 3],
    };

  Returns:
    $issues

  Example:
    get_closed_issues($attr);
=cut
#**********************************************************
sub get_closed_issues {
  my $self = shift;
  my ($attr) = @_;
  if (!$attr->{DEBUG}) {
    $attr->{DEBUG} = 0;
  }
  my %issues_list = ();
  for my $aid (@{$attr->{ADMIN_AIDS}}) {
    my $url =
     $self->{conf}{TIMETRACKER_REDMINE_URL}
       ."/issues.json?offset=0&limit=100&status_id=closed&assigned_to.cf_8=$aid";
    my $json = web_request($url, { CURL => 1, JSON_RETURN => 1, DEBUG => $attr->{DEBUG} });
    $issues_list{$aid}            = $json->{issues};
    $issues_list{'closed->'.$aid} = $json->{total_count};
  }

  return \%issues_list;
}


#**********************************************************
=head2 get_spent_hours($attr) - return spend hours for admin
  Arguments:
    $attr = {
      FROM_DATE => '2020-01-01',
      TO_DATE => '2020-02-20',
      DEBUG => 0,
      ADMIN_AIDS => [1, 2, 3],
    };
  
  Returns:
    $hours
  
  Examples:
    get_spent_hours($attr);
=cut
#**********************************************************
sub get_spent_hours {
  my $self = shift;
  my ($attr) = @_;
  my %hours = ();
  my $issues_list = $self->get_closed_issues($attr);

  for my $aid (@{$attr->{ADMIN_AIDS}}) {
    for my $admin_issue (@{$issues_list->{$aid}}) {
      my $issue_id = $admin_issue->{id};
      my $issue_url =
        $self->{conf}{TIMETRACKER_REDMINE_URL} . "/issues/$issue_id.json";
      my $json = web_request($issue_url, { CURL => 1, JSON_RETURN => 1, DEBUG => 0 });
      my $issue = $json->{issue};
      $hours{$aid} += sprintf("%.3f", $issue->{spent_hours});
    }
  }

  return \%hours;
}


#**********************************************************
=head2 get_closed_tasks($attr) - get count closed tasks
  Arguments:
    $attr = {
      FROM_DATE => '2020-01-01',
      TO_DATE => '2020-02-20',
      DEBUG => 0,
      ADMIN_AIDS => [1, 2, 3],
    };

  Returns:
    $closed_tasks

  Example:
    get_closed_tasks($attr);
=cut
#**********************************************************
sub get_closed_tasks {
  my $self = shift;
  my ($attr) = @_;
  my %closed_tasks = ();
  my $issues_list = $self->get_closed_issues($attr);
  for my $aid (@{$attr->{ADMIN_AIDS}}) {
    $closed_tasks{$aid} = $issues_list->{'closed->'.$aid};
  }

  return \%closed_tasks;
}

=head2 get_scheduled_hours_on_complexity($attr) - return scheduled_hours_on_complexity for admin
  Arguments:
    $attr = {
      FROM_DATE => '2020-01-01',
      TO_DATE => '2020-02-20',
      DEBUG => 0,
      ADMIN_AIDS => [1, 2, 3],
    };

  Returns:
    $result

  Examples:
    get_scheduled_hours_on_complexity($attr);
=cut
#**********************************************************
sub get_scheduled_hours_on_complexity {
  my $self = shift;
  my ($attr) = @_;
  my %result = ();
  my $issues_list = $self->get_closed_issues($attr);

  for my $aid (@{$attr->{ADMIN_AIDS}}) {
    for my $admin_issue (@{$issues_list->{$aid}}) {
      for my $custom_field (@{$admin_issue->{custom_fields}}) {
        if ($custom_field->{name} eq 'Сложность') {
          if ($custom_field->{value} && $admin_issue->{estimated_hours}) {
            $result{$aid} += ($custom_field->{value} * $admin_issue->{estimated_hours});
          }
        }
      }
    }
  }

  return \%result;
}

#**********************************************************
=head2 get_scheduled_hours($attr) - return scheduled hours for admin
  Arguments:
    $attr = {
      FROM_DATE => '2020-01-01',
      TO_DATE => '2020-02-20',
      DEBUG => 0,
      ADMIN_AIDS => [1, 2, 3],
    };

  Returns:
    $hours

  Examples:
    get_scheduled_hours($attr);  
=cut
#**********************************************************
sub get_scheduled_hours {
  my $self = shift;
  my ($attr) = @_;
  my $issues_list = $self->get_closed_issues($attr);
  my %hours = ();

  for my $aid (@{$attr->{ADMIN_AIDS}}) {
    for my $issue (@{$issues_list->{$aid}}) {
      $hours{$aid} += $issue->{estimated_hours} || 0;
    }
  }

  return \%hours;
}

#**********************************************************
=head2 get_list_sprints() - return list of the sprints

  Returns:
    $self

  Examples:
    get_list_sprints($attr);
=cut
#**********************************************************
sub get_list_sprints {
  my $self = shift;
  my ($attr) = @_;

  my $url = "$self->{conf}{TIMETRACKER_REDMINE_URL}/projects/$self->{conf}{TIMETRACKER_REDMINE_PROJECT_ID}/versions.json?status=open&key=$self->{conf}{TIMETRACKER_REDMINE_APIKEY}";
  my $json = web_request($url, { CURL => 1, JSON_RETURN => 1, DEBUG => $attr->{DEBUG} });

  if($json->{versions}){
    $self = ($json->{versions});
  }

  return $self;
}

#**********************************************************
=head2 get_list_issue($attr) - return list of the issues
  Arguments:
    $attr = {
      VERSION_ID => 174, # sprint id
    };

  Returns:
    $self

  Examples:
    get_list_issues($attr);
=cut
#**********************************************************
sub get_list_issues {
  my $self = shift;
  my ($attr) = @_;

  my $url = "$self->{conf}{TIMETRACKER_REDMINE_URL}/projects/$self->{conf}{TIMETRACKER_REDMINE_PROJECT_ID}/issues.json?status_id=*&limit=200&fixed_version_id=$attr->{VERSION_ID}&key=$self->{conf}{TIMETRACKER_REDMINE_APIKEY}";
  my $json = web_request($url, { CURL => 1, JSON_RETURN => 1, DEBUG => $attr->{DEBUG} });

  if($json->{issues}){
    $self = ($json->{issues});
  } else {
    $self = ($json);
  }

  return $self;
}

#**********************************************************
=head2 get_issue_by_id ($attr) - return issue
  Arguments:
    $attr = {
      ISSUE_ID => 3999, # issue id
    };

  Returns:
    $self

  Examples:
    get_issue_by_id($attr);
=cut
#**********************************************************
sub get_issue_by_id {
  my $self = shift;
  my ($attr) = @_;

  my $url = "$self->{conf}{TIMETRACKER_REDMINE_URL}/issues/$attr->{ISSUE_ID}.json";
  my $json = web_request($url, { CURL => 1, JSON_RETURN => 1, DEBUG => $attr->{DEBUG} });

  if($json->{issue}){
    $self = ($json->{issue});
  } else {
    $self = ($json);
  }

  return $self;
}

1;