=head1 NAME

 Maps Modules

=cut

use strict;
use warnings;
use Paysys::Maps_info;
use Maps::Maps_view;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html
);

#**********************************************************
=head2 paysys_maps_($attr)

=cut
#**********************************************************
sub paysys_maps_new {

  my $Paysys_maps = Paysys::Maps_info->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });
  my $Maps_info = Maps::Maps_view->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

  return $Maps_info->show_map(\%FORM, {
    QUICK          => 1,
    DATA           => $Paysys_maps->paysys_terminals_show({ RETURN_OBJECTS => 1, ESCAPE => 1 }),
    DONE_DATA      => 1,
    HIDE_CONTROLS  => 1,
    NAVIGATION_BTN => 0,
    OUTPUT2RETURN  => 1,
    BUILD_ROUTE    => 1
  });
}

1;