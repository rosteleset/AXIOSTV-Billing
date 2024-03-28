package Msgs::Plugins::Tasks_msgs;

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw/in_array/;

my (
  $admin,
  $CONF,
  $db
);

my AXbills::HTML $html;
my $lang;
my $Msgs;

my $Tasks;
my $states = {};

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;

  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = { MODULE => 'Tasks', PLUGIN_NAME => 'Tasks_msgs' };

  $Msgs = $attr->{MSGS} if $attr->{MSGS};

  require Tasks::db::Tasks;
  Tasks->import();
  $Tasks = Tasks->new($db, $admin, $CONF);

  bless($self, $class);

  if ($html) {
    $states = {
      0 => $html->color_mark($lang->{OPEN}, 'text-primary mb-0'),
      1 => $html->color_mark($lang->{CLOSED_SUCCESSFUL}, 'text-success mb-0'),
      2 => $html->color_mark($lang->{CLOSED_UNSUCCESSFUL}, 'text-danger mb-0')
    };
  }
  else {
    $states = { 0 => $lang->{OPEN}, 1 => $lang->{CLOSED_SUCCESSFUL}, 2 => $lang->{CLOSED_UNSUCCESSFUL} };
  }

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME     => "Tasks",
    POSITION => 'BOTTOM',
    DESCR    => $lang->{TASKS}
  };
}

#**********************************************************
=head2 plugin_show($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub plugin_show {
  my $self = shift;
  my ($attr) = @_;

  $attr->{UID} ||= '';
  $attr->{chg} ||= $attr->{ID};
  return '' if !$attr->{chg} || !$attr->{index} || !$attr->{UID};
  
  my $add_form_index = ::get_function_index('task_web_add');
  my $tasks_list_index = ::get_function_index('tasks_list');
  return '' if !$add_form_index;

  my $add_url = "?qindex=$add_form_index&header=2&SHORT_FORM=1&MSG_ID=$attr->{chg}";
  my $add_button = $html->button($lang->{ADD}, undef, {
    class          => 'add',
    ex_params      => qq/onclick=loadToModal('$add_url'\,''\,'') class='ml-3 cursor-pointer'/,
    NO_LINK_FORMER => 1,
    SKIP_HREF      => 1
  });

  my $tasks = $Tasks->list({ MSG_ID => $attr->{chg}, COLS_NAME => 1 });
  my $table = $html->table({
    width     => '100%',
    title     => [ 'ID', $lang->{TYPE}, $lang->{NAME}, $lang->{STATUS}, $lang->{RESPONSIBLE}, $lang->{DUE_DATE}, '' ],
    caption   => $lang->{TASKS},
    qs        => 1,
    ID        => 'MSGS_TASKS_ITEMS',
    MENU      => [ $add_button ],
    DATA_TABLE => 1
  });
  
  foreach my $task (@{$tasks}) {
    my $show_button = $html->button('', "index=$tasks_list_index&show_task=$task->{id}", {
      ADD_ICON  => "fa fa-eye mr-2",
      ex_params => "target='_blank'"
    });
    $table->addrow($task->{id}, $task->{type_name}, $task->{name}, $states->{$task->{state}} || '',
      $task->{responsible_name}, $task->{control_date}, $show_button);
  }

  return $table->show();
}

1;