=head2 NAME

  Cams Reports

=cut

use strict;
use warnings FATAL => 'all';

our(
  $Cams,
  %lang,
  %conf,
  $admin,
  $db,
  $html,
  $Cams_service
);

#***********************************************************
=head2 cams_service_report()

=cut
#***********************************************************
sub cams_service_report {

  my $services = $html->form_main({
    CONTENT => cams_services_sel(),
    HIDDEN  => { index => $index },
    class   => 'form-inline ml-auto flex-nowrap',
  });

  func_menu({ $lang{NAME} => $services });

  _cams_get_service_report($FORM{SERVICE_ID});
}

#**********************************************************
=head2 _cams_get_service_report($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _cams_get_service_report {
  my ($service_id) = @_;

  return 0 if !$service_id;

  $Cams_service = cams_load_service('', { SERVICE_ID => $service_id });
  return 0 if !$Cams_service;
  return 0 if !$Cams_service->can('service_report');

  print $Cams_service->service_report();

  return 1;
}

1;