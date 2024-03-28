package Msgs::Plugins::Msgs_additionally;

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
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = { MODULE => 'Msgs' };

  if ($attr->{MSGS}) {
    $Msgs = $attr->{MSGS};
  }
  else {
    require Msgs;
    Msgs->import();

    $Msgs = Msgs->new($db, $admin, $CONF);
  }

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME     => "Additional ticket information",
    POSITION => 'RIGHT',
    DESCR    => $lang->{ADDITIONAL_TICKET_INFORMATION}
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

  return $self->_get_additionally_info($attr);
}

#**********************************************************
=head2 _get_additionally_info($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_additionally_info {
  my $self = shift;
  my ($attr) = @_;

  my $message_info = $Msgs->message_info($attr->{chg});

  my @tag_name = (
    $lang->{ADMIN}, $lang->{UPDATED}, $lang->{CLOSED}, $lang->{DONE}, 
    $lang->{USER}, $lang->{ADMIN_READ}, $lang->{TIME_IN_WORK}
  );
  
  my @tag_data = (
    $message_info->{A_NAME}, $message_info->{LAST_REPLIE_DATE}, $message_info->{CLOSED_DATE},
    $message_info->{DONE_DATE}, $message_info->{USER_READ}, $message_info->{ADMIN_READ},
    $message_info->{TICKET_RUN_TIME}
  );
  
  my $label_str = '';

  for (my $i = 0; $i < 7; $i++) {
    my $label = $html->element('kbd', $tag_name[$i] . ':', { class => 'col-md-12' });
    my $p = $html->element('p', $tag_data[$i], { class => 'form-control-static' });
    my $div = $html->element('div', $p, { class => 'col-md-12' });
    my $form_group = $html->element('div', $label . $div, { class => 'form-group' });

    $label_str .= $form_group;
  }

  return _get_additionally_data($label_str);
}

#**********************************************************
=head2 _get_additionally_data($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_additionally_data {
  my ($label_str) = @_;

  my $icon_button = $html->element('i', '', { class => 'fa fa-plus' });
  my $button_plus = $html->element('button', $icon_button, { class => 'btn btn-tool', 'data-card-widget' => 'collapse' });
  my $button_collapse = $html->element('div', $button_plus, { class => 'card-tools float-right' });

  my $head_title = $html->element('h4', $lang->{EXTRA}, { class => 'card-title' });
  my $head_box = $html->element('div', $head_title . $button_collapse, { class => 'card-header' });

  my $box_body = $html->element('div', $label_str, { class => 'card-body' });

  my $title_box = $html->element('div', $head_box . $box_body, { class => 'card collapsed-card col-md-12' });

  my $form_group = $html->element('div', $title_box, { class => 'form-group' });

  return $form_group;
}

1;
