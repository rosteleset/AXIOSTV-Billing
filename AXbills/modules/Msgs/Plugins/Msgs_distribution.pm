package Msgs::Plugins::Msgs_distribution;

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw/in_array/;

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;
my $Msgs;

my $Employees;

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

  my $self = { MODULE => 'Msgs', PLUGIN_NAME => 'Msgs_ticket_distribution' };

  $Msgs = $attr->{MSGS} if $attr->{MSGS};

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME         => "Ticket distribution by chapter",
    DESCR        => $lang->{TICKET_DISTRIBUTION_BY_CHAPTER} || "Ticket distribution by chapter",
    AFTER_CREATE => [ 'msgs_distribute_ticket' ]
  };
}

#**********************************************************
=head2 msgs_distribute_ticket($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub msgs_distribute_ticket {
  my $self = shift;
  my ($attr) = @_;

  return {} if !$attr->{ID};

  my $chapter = $Msgs->chapter_info($attr->{CHAPTER});
  return {} if !$Msgs->{TOTAL} || !$chapter->{RESPONSIBLE};

  $Msgs->message_change({ ID => $attr->{ID}, RESPOSIBLE => $chapter->{RESPONSIBLE} });

  return {};
}

1;
