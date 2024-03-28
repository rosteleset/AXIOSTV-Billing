package Msgs::Plugins::Msgs_dispatches_select;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db, $msgs_permissions);
my $json;
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
  $msgs_permissions = $attr->{MSGS_PERMISSIONS};

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
    NAME     => "Dispatches select",
    POSITION => 'RIGHT',
    DESCR    => $lang->{CHOICE_OF_WORK_ORDER}
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

  return '' if !$msgs_permissions->{1} || !$msgs_permissions->{1}{26};

  my $dispatches_sel = $html->form_select('DISPATCH_ID', {
    SELECTED    => $Msgs->{DISPATCH_ID} || '',
    SEL_LIST    => $Msgs->dispatch_list({
      ID        => '_SHOW',
      COMMENTS  => '_SHOW',
      PLAN_DATE => '_SHOW',
      STATE     => 0,
      COLS_NAME => 1
    }),
    SEL_OPTIONS => { '' => '--' },
    SEL_KEY     => 'id',
    SEL_VALUE   => 'plan_date,comments'
  });

  my $col_div = $html->element('div', $dispatches_sel, { class => 'col-md-12' });
  my $label = $html->element('label', "$lang->{DISPATCH}:", { class => 'col-md-12' });

  return $html->element('div', $label . $col_div, { class => 'form-group' });;
}

1;
