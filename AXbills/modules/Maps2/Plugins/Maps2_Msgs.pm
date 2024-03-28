package Maps2::Plugins::Maps2_Msgs;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;

my $Msgs;
my $Maps_view;

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
  $Msgs = $attr->{MSGS} if $attr->{MSGS};

  my $self = { MODULE => 'Maps2' };

  use Maps2::Maps_view;
  $Maps_view = Maps2::Maps_view->new($db, $admin, $CONF, { HTML => $html, LANG => $lang });

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME     => 'Show msgs map',
    POSITION => 'RIGHT',
    DESCR    => $lang->{SHOW_MSGS_MAP}
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

  return if !$Msgs->{ID};

  if (!$Msgs->{LOCATION_ID}) {
    my $message = $Msgs->messages_list({
      MSG_ID          => $Msgs->{ID},
      LOGIN           => '_SHOW',
      FIO             => '_SHOW',
      UID             => '_SHOW',
      LOCATION_ID     => '_SHOW',
      LOCATION_ID_MSG => '_SHOW',
      COLS_NAME       => 1,
      COLS_UPPER      => 1
    });
    return '' if ($Msgs->{TOTAL} != 1);

    $Msgs->{LOCATION_ID} = $message->[0]{BUILD_ID} || $message->[0]{LOCATION_ID_MSG} || 0;
  }

  return '' if (!$Msgs->{LOCATION_ID});

  return $Maps_view->show_map($attr, {
    %{$attr},
    DATA                => {
      $Msgs->{LOCATION_ID} => [ {
        uid   => $Msgs->{UID},
        login => $Msgs->{LOGIN},
        fio   => $Msgs->{FIO}
      } ]
    },
    OBJECT_ID  => $Msgs->{LOCATION_ID},
    HIDE_CONTROLS       => 1,
    MAPS_DEFAULT_TYPE   => $CONF->{MAPS_DEFAULT_TYPE} || 'OSM',
    MAPS_DEFAULT_LATLNG => $CONF->{MAPS_DEFAULT_LATLNG} || '',
    MAP_HEIGHT          => 25,
    MAP_ZOOM            => 16,
    SMALL               => 1,
    MAP_HEIGHT          => 25,
    NAVIGATION_BTN      => 1,
    HIDE_EDIT_BUTTONS   => 1,
    MSGS_MAP            => 1
  });
}

1;