package Msgs::Plugins::Msgs_dispatches;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;
my $Msgs;

require Users;
Users->import();
my $users;

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
    PLUGIN_NAME => 'Msgs_dispatches'
  };

  if ($attr->{MSGS}) {
    $Msgs = $attr->{MSGS};
  }
  else {
    require Msgs;
    Msgs->import();
    $Msgs = Msgs->new($db, $admin, $CONF);
  }

  $users = Users->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME          => "Adding a work order",
    DESCR         => $lang->{ADDING_WORK_ORDER},
    BEFORE_CREATE => ['_msgs_create_dispatch']
  };
}

#**********************************************************
=head2 _msgs_create_dispatch($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_create_dispatch {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{DISPATCH_CREATE};

  $attr->{COMMENTS} = $attr->{DISPATCH_COMMENTS};
  $Msgs->dispatch_add({ %{$attr}, PLAN_DATE => $attr->{DISPATCH_PLAN_DATE} });
  $attr->{DISPATCH_ID} = $Msgs->{DISPATCH_ID};
  $html->message('info', $lang->{INFO}, "$lang->{DISPATCH} $lang->{ADDED}") if (!$Msgs->{errno});

  return 0;
}

1;