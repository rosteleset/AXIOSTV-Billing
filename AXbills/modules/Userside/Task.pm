=head1 NAME

  Task API

  VERSION: 0.02
  UPDATED: 2021.08.17

  Task API:
  DATE: 16.04.2021
  URL: https://wiki.userside.eu/API_task

=cut

use strict;
use warnings FATAL => 'all';
our ($html, %FORM, $db, %conf, $admin, %lang, $DATE);

my $max_page_rows = $conf{US_API_MAX_PAGE_ROWS} || 10000;

use Userside::Api;
use Msgs;

my $Msgs = Msgs->new($db, $admin, \%conf);

my %PARAMS = (
  COLS_NAME     => 1,
  PAGE_ROWS     => $max_page_rows,
  COLS_UPPER    => 1
);

#**********************************************************
=head2 get_list()

  Results:
    _json_former(\%hash)
=cut
#**********************************************************
sub get_list {
  my %fields = (
    author_id            => 'AID',           # Operator ID - the author of the task (can be separated by commas) (up to version 3.16dev2)
    author_employee_id   => 'AID',           # ID of the employee - the author of the task (can be separated by commas)
    closer_employee_id   => 'RESPOSIBLE',    # ID of the employee who closed (completed) the task (can be separated by commas)
    closer_operator_id   => 'AID',           # ID of the operator who closed (completed) the task (can be separated by commas) (up to version 3.16dev2)
    customer_id          => 'UID',           # ID user
    # date_add_from          => 'RUN_TIME',  # task creation date (since)
    # date_add_to            => 'DONE_DATE', # task creation date (to)
    # date_change_from       => 'NONE',      # task update date (since)
    # date_change_to         => 'NONE',      # task update date (to)
    # date_do_from           => 'FROM_DATE', # the date on which the task is scheduled to be completed (since)
    date_do_to           => 'DONE_DATE',     # the date on which the task is scheduled to be completed (to)
    # date_finish_from       => 'RUN_TIME',  # date of the assignment (since)
    date_finish_to       => 'CLOSED_DATE',   # date of the assignment (to)
    # division_id            => 'GID',       # Subdivision ID (can be separated by commas)
    # division_id_with_staff => 'GID',       # Subdivision ID (with tasks of employees of this department) (can be separated by commas)
    employee_id          => 'RESPOSIBLE',    # performer ID
    house_id             => 'LOCATION_ID',   # house id
    # is_expired             => 'NONE',      # flag - display only overdue tasks
    # node_id                => 'NONE',      # ID object position
    staff_id             => 'RESPOSIBLE',    # performer ID
    state_id             => 'STATE',         # ID task status
    task_position        => 'PLAN_POSITION', # job coordinates
    task_position_tadius => 'PLAN_INTERVAL', # radius from task_position
    # type_id                => 'SEND_TYPE', # ID task type
    watcher_id           => 'DELIGATION',    # ID of the operator observer of the task (can be separated by commas) (up to version 3.16dev2)
    watcher_employee_id  => 'RESPOSIBLE',    # ID of the employee observer of the task (can be separated by commas)
    # order_by               => 'NONE',      # sorting field
    # limit                  => 'NONE',      # record selection limit
    # offset                 => 'NONE'       # sampling bias
  );

  %LIST_PARAMS = (
    RESPOSIBLE    => '_SHOW',
    LOCATION_ID   => '_SHOW',
    UID           => '_SHOW',
    DONE_DATE     => '_SHOW',
    CLOSED_DATE   => '_SHOW',
    ADMIN_LOGIN   => '_SHOW',
    STATE         => '_SHOW',
    PLAN_POSITION => '_SHOW',
    PLAN_INTERVAL => '_SHOW',
    ADMIN_DISABLE => '_SHOW',
    %PARAMS
  );

  my $msgs_list = $Msgs->messages_list({ %LIST_PARAMS });

  my %hash = ();
  foreach my $msgs (@$msgs_list) {
    foreach my $key (sort keys %fields) {
      $hash{$msgs->{id}}{$key} = $msgs->{$fields{$key}};
    }
  }

  return _json_former(\%hash);
}

#**********************************************************
=head2 change_state($attr)

  Arguments:
    $attr
      id
      employee_id || staff_id
  Results:
    _json_former(\%hash)
=cut
#**********************************************************
sub change_state {
  my ($attr) = @_;

  $Msgs->message_change({
    ID    => $attr->{id},
    STATE => $attr->{state_id}
  });

  my %hash = ();

  return _json_former(\%hash);
}

#**********************************************************
=head2 get_related_task_id($attr)

  Arguments:
    $attr
      id
  Results:
    _json_former(\%hash)
=cut
#**********************************************************
sub get_related_task_id {
  my ($attr) = @_;

  my $msg = $Msgs->message_info($attr->{id}, { %PARAMS });

  my %hash = ();
  $hash{$msg->{ID}}{id}              = $msg->{ID};
  $hash{$msg->{ID}}{related_task_id} = $msg->{PAR};

  return _json_former(\%hash);
}

#**********************************************************
=head2 get_catalog_type()

  Results:
    _json_former(\%hash)
=cut
#**********************************************************
sub get_catalog_type {

  my %fields = (
    id   => 'ID',
    name => 'NAME'
  );

  %LIST_PARAMS = (
    ID         => '_SHOW',
    NAME       => '_SHOW',
    %PARAMS
  );

  my $status_list = $Msgs->status_list({ %LIST_PARAMS });

  my %hash = ();
  foreach my $status_raw (@$status_list) {
    foreach my $key (sort keys %fields) {
      $hash{$status_raw->{id}}{$key} = $status_raw->{$fields{$key}};
    }
  }

  return _json_former(\%hash);
}

#**********************************************************
=head2 show($attr)

  Arguments:
    $attr
      id
  Results:
    _json_former(\%hash)
=cut
#**********************************************************
sub show {
  my ($attr) = @_;

  my $msg = $Msgs->message_info($attr->{id}, { %PARAMS });

  my %hash = ();
  $hash{$msg->{ID}}{id}          = $msg->{ID};
  $hash{$msg->{ID}}{employee_id} = $msg->{AID};
  $hash{$msg->{ID}}{operator_id} = $msg->{AID};

  return _json_former(\%hash);
}

#**********************************************************
=head2 watcher_add($attr)

  Arguments:
    $attr
      id
      employee_id || staff_id
  Results:
    _json_former(\%hash)
=cut
#**********************************************************
sub watcher_add {
  my ($attr) = @_;

  $Msgs->msg_watch({
    ID  => $attr->{id},
    AID => $attr->{employee_id} || $attr->{staff_id}
  });

  my %hash = ();

  return _json_former(\%hash);
}

#**********************************************************
=head2 watcher_delete($attr)

  Arguments:
    $attr
      id
      employee_id || staff_id
  Results:
    _json_former(\%hash)
=cut
#**********************************************************
sub watcher_delete {
  my ($attr) = @_;

  $Msgs->msg_watch_del({
    ID  => $attr->{id},
    AID => $attr->{employee_id} || $attr->{staff_id}
  });

  my %hash = ();

  return _json_former(\%hash);
}

#**********************************************************
=head2 comment_add($attr)

  Arguments:
    $attr
      id
      comment
  Results:
    _json_former(\%hash)
=cut
#**********************************************************
sub comment_add {
  my ($attr) = @_;

  $Msgs->message_reply_add({
    ID         => $attr->{id},
    REPLY_TEXT => $attr->{comment},
    AID        => $attr->{employee_id} || $attr->{operator_id}
  });

  my %hash = ();

  return _json_former(\%hash);
}

#**********************************************************
=head2 add($attr)

  Arguments:
    $attr
      work_datedo
      address_id
      author_employee_id
      author_operator_id
      employee_id
      opis
      parent_task_id
      unit_id
      usercode
  Results:
    _json_former(\%hash)
=cut
#**********************************************************
sub add {
  my ($attr) = @_;
  # fileds :
  # work_datedo        => the date on which the task is scheduled to be completed;
  # work_typer         => ID task type;
  # apart              => apartment number;
  # address_id         => address ID;
  # author_employee_id => ID of the employee who created the task;
  # author_operator_id => ID of the operator who created the task;
  # citycode           => id of the settlement. If not specified, it is taken from (housecode) data;
  # division_id        => Department ID (multiple values are allowed, separated by commas);
  # dopf_N             => the value of the additional field for the ID_N field;
  # employee_id        => performer ID (multiple values are allowed, separated by commas);
  # fio                => Full name of the client (meaning that the "client" is not yet a subscriber);
  # housecode          => If not specified, then it is taken from the subscriber data - usercode, or from the data on the communication center - uzelcode;
  # opis               => assignment notes;
  # parent_task_id     => parent task ID;
  # unit_id            => performer ID (multiple values are allowed, separated by commas) (up to version 3.16dev2);
  # usercode           => id subscriber;
  # uzelcode           => ID communication center;
  # work_amount        => scope of work;

  $Msgs->message_add({
    REPLY_TEXT  => $attr->{comment},
    AID         => $attr->{author_employee_id} || $attr->{author_operator_id},
    PAR         => $attr->{parent_task_id},
    MESSAGE     => $attr->{opis},
    LOCATION_ID => $attr->{address_id},
    UID         => $attr->{usercode},
    PLAN_DATE   => $attr->{work_datedo},
    RESPOSIBLE  => $attr->{employee_id} || $attr->{unit_id},
  });

  my %hash = ();

  return _json_former(\%hash);
}

#**********************************************************
=head2 get_msg_id()

  Arguments:

  Results:
    $id
=cut
#**********************************************************
sub get_msg_id {
  my $msgs_list = $Msgs->messages_list({ %PARAMS });

  my $id;
  foreach my $msgs (@$msgs_list) {
    $id = $msgs->{id};
  }
  return $id;
}


1;