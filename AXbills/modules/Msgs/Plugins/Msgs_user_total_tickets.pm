package Msgs::Plugins::Msgs_user_total_tickets;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;
my Msgs $Msgs;

use AXbills::Base qw/in_array/;

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

  my $self = {
    MODULE      => 'Msgs',
    PLUGIN_NAME => 'Msgs_user_total_tickets'
  };

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
    NAME     => "Total user tickets",
    POSITION => 'RIGHT',
    DESCR    => $lang->{THE_NUMBER_OF_USER_TICKETS_IN_THE_CURRENT_MONTH}
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

  return '' unless $attr->{UID};

  $Msgs->total_tickets_by_current_month({ UID => $attr->{UID} });

  return '' if $Msgs->{TOTAL} < 1;

  my $time_title = $html->element('span', $lang->{TIME_SPENT_ON_APPLICATIONS_IN_THE_CURRENT_MONTH});
  my $spent_time = $html->element('h4', AXbills::Base::sec2time($Msgs->{TOTAL_TIME}, { str => 1 }) || '+0 00:00:00', { class => 'h4' });
  my $time_inner_div = $html->element('div', $spent_time . $time_title, { class => 'inner text-center' });

  my $count_title = $html->element('span', $lang->{NUMBER_OF_PROCESSED_REQUESTS_IN_THE_CURRENT_MONTH});
  my $count = $html->element('h4', $Msgs->{TOTAL_TICKETS} || 0, { class => 'h4' });
  my $count_inner_div = $html->element('div', $count . $count_title, { class => 'inner text-center' });

  return $html->element('div', $time_inner_div, { class => 'small-box' }) .
    $html->element('div', $count_inner_div, { class => 'small-box' });
}


1;
