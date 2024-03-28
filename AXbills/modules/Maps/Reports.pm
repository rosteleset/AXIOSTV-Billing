use strict;
use warnings FATAL => 'all';

=head1 NAME

  Maps::Reports - maps reports

=cut

our (
  $Maps,
  $html,
  %lang,
  %conf,
  $admin,
  $db,
  %permissions,
  %LIST_PARAMS
);

use AXbills::Base qw(in_array _bp);
require Maps::Auxiliary;
Maps::Auxiliary->import();
my $Auxiliary = Maps::Auxiliary->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

#**********************************************************
=head2 maps_objects_reports()

=cut
#**********************************************************
sub maps_objects_reports {

  return if _maps_full_report_info();

  my $objects = ();

  foreach my $module_name (@main::MODULES) {
    my $module = $Auxiliary->maps_load_module($module_name);

    next if !$module;
    next if !$module->can('new') || !$module->can('maps_layers');

    my $module_object = $module->new($db, $admin, \%conf, { LANG => \%lang, HTML => $html });
    my $layer = $module_object->maps_layers();

    next if !$layer->{LAYERS} || ref $layer->{LAYERS} ne 'ARRAY';

    foreach (@{$layer->{LAYERS}}) {
      next if (!$_->{export_function} || (!$_->{lang_name} && !$_->{name}));

      my $function_ref = $module_object->can($_->{export_function});
      next if !$function_ref;

      my $result = $module_object->$function_ref({ ONLY_TOTAL => 1 });
      next if !$result;

      $objects->{$_->{lang_name} ? _translate($_->{lang_name}) : _translate($_->{name})} = {
        COUNT    => $result,
        LAYER_ID => $_->{id},
        MODULE   => $module_name,
        LAYER_ID => $_->{id}
      };
    }
  }

  my $objects_info = $html->table({
    width      => '100%',
    caption    => "Maps: " . $lang{DISPLAYED_ITEMS},
    title      => [ $lang{TYPE}, $lang{COUNT}, "Maps" ],
    ID         => 'MAPS_ITEMS',
    DATA_TABLE => 1,
  });

  foreach my $key (sort keys %{$objects}) {
    my $maps_btn = $Auxiliary->maps_show_object_button($objects->{$key}{LAYER_ID});
    my $full_info_btn = $html->button($key, "index=$index&MODULE=$objects->{$key}{MODULE}&LAYER_ID=$objects->{$key}{LAYER_ID}");
    $objects_info->addrow($full_info_btn, $objects->{$key}{COUNT}, $maps_btn);
  }

  print $objects_info->show();
}

#**********************************************************
=head2 _maps_full_report_info()

=cut
#**********************************************************
sub _maps_full_report_info {

  return 0 if !$FORM{MODULE} || !$FORM{LAYER_ID};

  my $module = $Auxiliary->maps_load_module($FORM{MODULE});
  return 0 if !$module;

  my $module_object = $module->new($db, $admin, \%conf, { LANG => \%lang, HTML => $html });

  my $function_ref = $module_object->can('maps_report_info');
  return 0 if !$function_ref;

  my $result = $module_object->maps_report_info($FORM{LAYER_ID});
  return 0 if !$result;

  print $result;
  return 1;
}

1;

