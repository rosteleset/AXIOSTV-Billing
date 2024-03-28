=head1 Msgs_address

  Msgs Msgs_address

=cut

use strict;
use warnings FATAL => 'all';

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html
);

my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_address($attr)

  Argument:
    ID
    DISTRICT_ID
    STREET_ID
    BUILD_ID
    ADDRESS_FLAT
  
  Return:
    -

=cut
#**********************************************************
sub msgs_address {
  my ($attr) = @_;
  my $info_address = $Msgs->msgs_address_info($attr->{chg} || $attr->{ID}) if ($attr->{chg} || $attr->{ID});

  if ($attr->{change}) {
    my $id_ticket = $attr->{ID};
    my $district_id = $attr->{DISTRICT_ID};
    my $street_id = $attr->{STREET_ID};
    my $build_id = $attr->{BUILD_ID};
    my $flat = $attr->{ADDRESS_FLAT};

    $Msgs->msgs_address_change({
      ID        => $id_ticket,
      DISTRICTS => $district_id,
      STREET    => $street_id,
      BUILD     => $build_id,
      FLAT      => $flat
    });

    if ($Msgs->{errno} && $Msgs->{errno} == 4) {
      $Msgs->msgs_address_add({
        ID        => $id_ticket,
        DISTRICTS => $district_id,
        STREET    => $street_id,
        BUILD     => $build_id,
        FLAT      => $flat
      });

      if (!_error_show($Msgs)) {
        $html->message('success', $lang{ADDED});
      }
    }
  }

  my $address = form_address_select2({
    HIDE_ADD_BUILD_BUTTON => 1,
    LOCATION_ID           => $info_address->[0]{build} || 0,
    DISTRICT_ID           => $info_address->[0]{districts} || 0,
    STREET_ID             => $info_address->[0]{street} || 0,
    ADDRESS_FLAT          => $info_address->[0]{flat} || ''
  });

  return $html->tpl_show(_include('msgs_address', 'Msgs'), { ADDRESS_FORM => $address }, { OUTPUT2RETURN => 1 });
}

1