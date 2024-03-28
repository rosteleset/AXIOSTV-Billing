=head1 NAME

  Msgs Tasks

=cut

use strict;
use warnings FATAL => 'all';

our(
  $db,
  $admin,
  %conf,
  %lang,
  $html
);


my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_tasks($attr) - Tasks

  Attributes:
    $attr

=cut
#**********************************************************
sub msgs_tasks {
  #my ($attr) = @_;

  if($FORM{send_message}) {
    $Msgs->message_add({
      %FORM
    });

    if(! $Msgs->{errno}) {
      $html->message('info', $lang{INFO}, $lang{ADDED} . "# ".
          $html->button($Msgs->{INSERT_ID}, 'index=' . $index . "&chg=$Msgs->{INSERT_ID}",
            { class => 'btn btn-xs btn-secondary text-right' }) );
    }
  }

  _error_show($Msgs);

  my $task_list = $Msgs->messages_list({ PAR => $FORM{TASK} });

  #print "Main message: $FORM{TASK} ($Msgs->{TOTAL})";
  print msgs_tasks_list($FORM{TASK});

#  delete $FORM{UID};
  print msgs_admin_add_form({
    ACTION     => 'send_message',
    LNG_ACTION => $lang{CREATE},
    PAR        => $FORM{TASK},
    TASK_ADD   => 1
  });

  return 1;
}

#**********************************************************
=head2 msgs_tasks_list($id) - Tasks

  Attributes:
    $id

  Reply:
    $tasks

=cut
#**********************************************************
sub msgs_tasks_list {
  my ($id) = @_;

  my $task_list = $Msgs->messages_list({
    PAR       => $id,
    SUBJECT   => '_SHOW',
    STATE     => '_SHOW',
    COLS_NAME => 1
  });
  my $tasks = q{};

  foreach my $line ( @$task_list ) {
    my $btn = 'btn-secondary';

    if($line->{state} == 2) {
      $btn = 'btn-success';
    }
    elsif($line->{state} == 1) {
      $btn = 'btn-danger';
    }

    $tasks .= $html->button($line->{id}.' : '. $line->{subject}, 'index=' . $index . "&chg=$line->{id}",
      { class => "btn btn-xs $btn text-right" });
  }

  return $tasks;
}

1;