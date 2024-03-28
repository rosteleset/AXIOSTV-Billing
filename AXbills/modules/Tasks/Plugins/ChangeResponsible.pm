package ChangeResponsible;

use strict;
use warnings FATAL => 'all';

my $html;
my $lang;

#**********************************************************
=head2 new($Tasks, $html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $Tasks = shift;
  $html = shift;
  $lang = shift;
  
  my $self = { Tasks => $Tasks };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return "Разрешает ответственному передать задачу другому администратору.";
}

#**********************************************************
=head2 html_for_task_show
  return button for MyTasks->showTask window
=cut
#**********************************************************
sub html_for_task_show {
  my $self = shift;
  my ($attr) = @_;

  return $html->button($lang->{CHANGE_RESPONSIBLE},
    "index=$main::index&plugin=ChangeResponsible&fn=change_responsible&ID=$attr->{ID}&" . ($attr->{qs} || ""),
    { class => 'btn btn-default btn-block' });
}


#**********************************************************
=head2 change_responsible

=cut
#**********************************************************
sub change_responsible {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{chg}) {
    $self->{Tasks}->chg($attr);
    $html->redirect("?index=$attr->{index}");
    return 'stop';
  }

  my $task_info = $self->{Tasks}->info({ ID => $attr->{ID} });

  my $submit_button = $html->form_input('chg', $lang->{CHANGE}, { TYPE => 'submit', OUTPUT2RETURN => 1 });
  my $responsible_select = $html->element('div',
    $html->element('div', main::_responsible_select({ SELECTED => $task_info->{RESPONSIBLE} }), { class => 'col-md-12' }),
    { class => 'form-group' }
  );

  my $hidden_inputs = $html->form_input('index', $attr->{index}, { TYPE => 'hidden', OUTPUT2RETURN => 1 });
  $hidden_inputs .= $html->form_input('plugin', $attr->{plugin}, { TYPE => 'hidden', OUTPUT2RETURN => 1 });
  $hidden_inputs .= $html->form_input('fn', $attr->{fn}, { TYPE => 'hidden', OUTPUT2RETURN => 1 });
  $hidden_inputs .= $html->form_input('ID', $attr->{ID}, { TYPE => 'hidden', OUTPUT2RETURN => 1 });

  my $output = $html->tpl_show('', {
    BOX_TITLE     => $lang->{CHANGE_RESPONSIBLE},
    HIDDEN_INPUTS => $hidden_inputs,
    BOX_BODY      => $responsible_select,
    BOX_FOOTER    => $submit_button,
  }, { TPL => 'box', MODULE => 'Tasks' });

  return $output;
}
1;