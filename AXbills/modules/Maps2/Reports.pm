use strict;
use warnings FATAL => 'all';

=head1 NAME

  Maps2::Reports - maps reports

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
use Maps2::Auxiliary qw/maps2_load_module/;
my $Auxiliary = Maps2::Auxiliary->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

#**********************************************************
=head2 maps_objects_reports()

=cut
#**********************************************************
sub maps_objects_reports {

  my $layers = ();
  my $objects = ();

  foreach (@main::MODULES) {
    my $module = maps2_load_module($_);

    next if !$module;
    next if !$module->can('new') || !$module->can('maps_layers');

    my $module_object = $module->new($db, $admin, \%conf, { LANG => \%lang });
    my $layer = $module_object->maps_layers();

    next if !$layer->{LAYERS} || ref $layer->{LAYERS} ne 'ARRAY';

    foreach (@{$layer->{LAYERS}}) {
      next if !$_->{export_function} || (!$_->{lang_name} && !$_->{name});

      my $function_ref = $module_object->can($_->{export_function});
      next if !$function_ref;

      my $result = $module_object->$function_ref({ ONLY_TOTAL => 1 });
      next if !$result;

      $objects->{$_->{lang_name} ? _translate($_->{lang_name}) : _translate($_->{name})} = {
        COUNT    => $result,
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
    my $maps_btn = $Auxiliary->maps2_show_object_button($objects->{$key}{LAYER_ID});
    $objects_info->addrow($key, $objects->{$key}{COUNT}, $maps_btn);
  }

  print $objects_info->show();
}

1;

