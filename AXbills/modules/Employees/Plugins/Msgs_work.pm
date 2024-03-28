package Employees::Plugins::Msgs_work;

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

my $Employees;
my $Employees_work;

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

  my $self = { MODULE => 'Msgs', PLUGIN_NAME => 'Msgs_work' };

  $Msgs = $attr->{MSGS} if $attr->{MSGS};

  require Employees;
  Employees->import();
  $Employees = Employees->new($db, $admin, $CONF);

  require Employees::Employees_work;

  Employees::Employees_work->import();
  $Employees_work = Employees::Employees_work->new($db, $admin, $CONF, {
    LANG      => $lang,
    EMPLOYEES => $Employees,
    HTML      => $html
  });

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME     => "Ticket works",
    POSITION => 'BOTTOM',
    DESCR    => $lang->{TICKET_WORKS}
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

  $Msgs->{ID} = $Msgs->{ID} || $attr->{chg} || 0;

  return '' if !$Msgs->{ID};

  if ($attr->{PLUGIN} && $attr->{PLUGIN} eq $self->{PLUGIN_NAME}) {
    my $hidden_inputs = $html->form_input('PLUGIN', $attr->{PLUGIN}, { TYPE => 'hidden' });
    $hidden_inputs .= $html->form_input('chg', $Msgs->{ID}, { TYPE => 'hidden' });
    $hidden_inputs .= $html->form_input('WORK_ID', $attr->{WORK_ID}, { TYPE => 'hidden' }) if $attr->{WORK_ID};
    $Employees_work->employees_works({
      %$attr,
      INDEX         => $attr->{index},
      EXT_ID        => $attr->{ID},
      UID           => $attr->{UID},
      HIDDEN_INPUTS => $hidden_inputs
    });

    return '' if ($attr->{change_work} || $attr->{add_work} || $attr->{del_work});
    return { RETURN_VALUE => 1 };
  }

  return $Employees_work->employees_works_list({
    EXT_ID        => $Msgs->{ID},
    UID           => $attr->{UID},
    INDEX         => $attr->{index},
    chg           => $attr->{chg},
    pages_qs      => $attr->{pages_qs},
    WORK_ID       => $attr->{ID},
    CHANGE_PARAMS => "&PLUGIN=$self->{PLUGIN_NAME}&chg=$Msgs->{ID}",
    DEL_PARAMS    => "&PLUGIN=$self->{PLUGIN_NAME}&chg=$Msgs->{ID}",
    ADD_PARAMS    => "&PLUGIN=$self->{PLUGIN_NAME}&chg=$Msgs->{ID}"
  });
}

1;
