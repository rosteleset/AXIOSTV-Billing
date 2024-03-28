package Msgs::Plugins::Msgs_address;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;
my $Msgs;

require Address;
Address->import();
my $Address;

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
    PLUGIN_NAME => 'Msgs_address'
  };

  if ($attr->{MSGS}) {
    $Msgs = $attr->{MSGS};
  }
  else {
    require Msgs;
    Msgs->import();
    $Msgs = Msgs->new($db, $admin, $CONF);
  }

  $Address = Address->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME          => "Checking message by address",
    DESCR         => $lang->{CHECKING_MESSAGE_BY_ADDRESS},
    BEFORE_CREATE => [ '_msgs_add_address_build', '_msgs_send_message_by_address' ]
  };
}

#**********************************************************
=head2 _msgs_add_address_build($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_add_address_build {
  my $self = shift;
  my ($attr) = @_;

  $attr->{LOCATION_ID} =~ s/,\s?//g if ($attr->{LOCATION_ID});
  $attr->{STREET_ID} =~ s/,\s?//g if ($attr->{STREET_ID});
  $attr->{DISTRICT_ID} =~ s/,\s?//g if ($attr->{DISTRICT_ID});
  $attr->{ADDRESS_FLAT} =~ s/,\s?//g if($attr->{ADDRESS_FLAT});

  return 0 if (!$attr->{ADD_ADDRESS_BUILD} || !$attr->{STREET_ID} || $attr->{LOCATION_ID});

  $Address->build_add({ STREET_ID => $attr->{STREET_ID}, ADD_ADDRESS_BUILD => $attr->{ADD_ADDRESS_BUILD} });
  $attr->{LOCATION_ID} = $Address->{LOCATION_ID} if !::_error_show($Address);

  return { RETURN_VARIABLES => { LOCATION_ID => $attr->{LOCATION_ID} } };
}

#**********************************************************
=head2 _msgs_send_message_by_address($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_send_message_by_address {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{UID} && !$attr->{LOCATION_ID} && $attr->{CHECK_FOR_ADDRESS} && $attr->{send_message}) {
    $html->message( 'err', $lang->{ERROR}, "Выберите дом к которому прикрепить сообщение" );

    return {
      RETURN_VALUE => 1,
      CALLBACK     => {
        FUNCTION     => 'msgs_admin_add_form',
        PARAMS       => { %{$attr} },
        PRINT_RESULT => 1
      }
    };
  }
  
  return 0;
}

1;