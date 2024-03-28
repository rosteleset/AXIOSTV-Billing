package Msgs::Plugins::Msgs_task_board;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my AXbills::HTML $html;
my $lang;
my $Msgs;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;

  $db       = shift;
  $admin    = shift;
  $CONF     = shift;

  my $attr  = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = { MODULE => 'Msgs' };

  _msgs_init($db, $admin, $CONF, { 
    MSGS => $attr->{MSGS} 
  });

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 _msgs_init()

=cut
#**********************************************************
sub _msgs_init {
  my ($db, $admin, $CONF, $attr) = @_;

  if ($attr->{MSGS}) {
    $Msgs = $attr->{MSGS};
  }
  else {
    require Msgs;
    Msgs->import();
   
    $Msgs = Msgs->new($db, $admin, $CONF);
  }
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME     => "Set ticket to the task board",
    POSITION => 'RIGHT',
    DESCR    => $lang->{SET_TICKET_TO_THE_TASK_BOARD}
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

  my $info = $self->_get_info();

  return $info || '';
}

#**********************************************************
=head2 _get_info($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_info {

  my %data_datepicker = (
    ICON           => 1,
    TIME_HIDDEN_ID => 'PLAN_TIME',
    DATE_HIDDEN_ID => 'PLAN_DATE',
    # EX_PARAMS      => q{pattern='^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01]) (00|0?[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9])$'},
  );

  my $date = $html->form_datetimepicker('PLAN_DATETIME', _generated_datetime(), { %data_datepicker });

  my $link_task_board = "index=" . ::get_function_index('msgs_task_board');

  my $date_picker_tpl = $html->tpl_show(::_include('msgs_plan_datepicker', 'Msgs'), {
    PLAN_DATETIME_INPUT => $date,
    SHEDULE_TABLE_OPEN  => $link_task_board
  }, { notprint => 1 });

  return $date_picker_tpl;
}

#**********************************************************
=head2 _generated_datetime($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _generated_datetime {
  my $date_set_picker = '';

  if ($Msgs->{PLAN_DATE} && $Msgs->{PLAN_DATE} ne '0000-00-00') {
    $date_set_picker = $Msgs->{PLAN_DATE};

    if ($Msgs->{PLAN_TIME} && $Msgs->{PLAN_TIME} ne '00:00:00') {
      $date_set_picker .= ' ' . $Msgs->{PLAN_TIME};
    }
    else {
      $date_set_picker .= ' ' . '00:00';
    }
  }

  return $date_set_picker;
}

1;