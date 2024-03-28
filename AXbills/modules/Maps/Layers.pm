#package Layers;
use strict;
use warnings FATAL => 'all';
use v0.02;

=head1 NAME

  Maps::Layers - maps layer objects serializing functions

=head2 SYNOPSIS

  This is part of webinterface that transforms DB objects to JSON

=cut

use AXbills::Base qw/_bp in_array/;

our ($MAPS_ENABLED_LAYERS);
use Maps::Shared;
use AXbills::Experimental;

our (
  $db,
  $admin,
  %conf,
  $html,
  %lang,
  %permissions,
  $Address,
  $Maps
);

require Maps::Auxiliary;
Maps::Auxiliary->import();
my $Auxiliary = Maps::Auxiliary->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

require JSON;
JSON->import(qw/to_json from_json encode_json decode_json/);

#**********************************************************
=head2 maps_districts_main()

=cut
#**********************************************************
sub maps_districts_main {

  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    my $new_point_id = $Auxiliary->maps_add_external_object(LAYER_ID_BY_NAME->{DISTRICT}, \%FORM);
    show_result($Maps, $lang{ADDED} . ' ' . $lang{OBJECT}) unless !$FORM{ADD_ON_NEW_MAP};
    $FORM{OBJECT_ID} = $new_point_id;

    $Maps->districts_add({ %FORM });
    $show_add_form = show_result($Maps, $lang{ADDED}) unless !$FORM{ADD_ON_NEW_MAP};

    if ($FORM{ADD_ON_NEW_MAP}) {
      $Maps->polygons_add({
        OBJECT_ID => $new_point_id,
        LAYER_ID  => 4,
        COLOR     => $FORM{COLOR}
      });

      my @points_array = split(/,/, $FORM{coords});

      if ($Maps->{INSERT_ID}) {
        my $polygon_id = $Maps->{INSERT_ID};
        foreach my $point (@points_array) {
          my ($coordx, $coordy) = split(':', $point);
          $Maps->polygon_points_add({
            POLYGON_ID => $polygon_id,
            COORDX     => $coordx,
            COORDY     => $coordy
          });
        }
      }

      $html->message('info', "$lang{ADDED} $lang{DISTRICT}");
      return 1;
    }

    if ($FORM{RETURN_FORM} && $html->{TYPE} eq 'json') {
      foreach (split(',\s?', $FORM{RETURN_FORM})) {
        push(@{$html->{JSON_OUTPUT}}, {
          $_ => '"' . ($FORM{$_} || q{}) . '"'
        });
      }
    }
  }
  elsif ($FORM{change}) {
    $Maps->districts_change({ %FORM });
    show_result($Maps, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{del}) {
    $Maps->districts_del({}, { district_id => $FORM{del} });
    show_result($Maps, $lang{DELETED});
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Maps->districts_info($FORM{chg});
    if (!_error_show($Maps)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;
    }
  }

  return 1 if ($FORM{MESSAGE_ONLY});

  if ($show_add_form) {
    my $districts = $Address->district_list({ PAGE_ROWS => 1000, COLS_NAME => 1 });
    my $used_districts_list = $Maps->districts_list({
      OBJECT_ID   => $FORM{LAST_OBJECT_ID} ? "> $FORM{LAST_OBJECT_ID}" : $FORM{ID} || '_SHOW',
      DISTRICT_ID => $FORM{DISTRICT_ID} || '_SHOW',
      DISTRICT    => '_SHOW',
      LIST2HASH   => 'object_id,district_id'
    });
    my @used_districts_ids = ();
    
    foreach (@{$used_districts_list}) {
      my $t = $Maps->polygons_list({ OBJECT_ID => $_->{object_id} });
      next if !$Maps->{TOTAL};

      push(@used_districts_ids, $_->{district_id});
    }

    my $not_used_districts_list = ();

    foreach (@{$districts}) {
      next if in_array($_->{id}, \@used_districts_ids);
      push @{$not_used_districts_list}, $_;
    }

    $TEMPLATE_ARGS{DISTRICT_ID_SELECT} = $html->form_select("DISTRICT_ID", {
      SELECTED    => $TEMPLATE_ARGS{DISTRICT_ID},
      SEL_LIST    => $not_used_districts_list,
      SEL_OPTIONS => { '' => '--' },
      NO_ID       => 1
    });
    $TEMPLATE_ARGS{COLOR} ||= '#ffffff';

    $html->tpl_show(_include('maps_district', 'Maps'), {
      %TEMPLATE_ARGS,
      %FORM,
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });
  }

  return 1 if ($FORM{TEMPLATE_ONLY});

  my AXbills::HTML $table;
  ($table) = result_former({
    INPUT_DATA      => $Maps,
    FUNCTION        => 'districts_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'DISTRICT_ID,DISTRICT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      district_id => '#',
      district    => $lang{DISTRICT},
      object_id   => $lang{MAP},
    },
    FILTER_VALUES   => {
      district_id => sub {
        my ($district_id, $line) = @_;
        $line->{id} = $district_id;
        return $district_id;
      }
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{DISTRICTS},
      ID      => 'DISTRICTS_TABLE'
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Maps',
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 maps_add_external_points($attr)

  Arguments:

  Returns:

=cut

#**********************************************************
sub maps_add_external_points {

  return 0 if !$FORM{POINT_ID} || !$FORM{COORDX} || !$FORM{COORDY};

  $Maps->points_change({
    ID     => $FORM{POINT_ID},
    COORDX => $FORM{COORDX},
    COORDY => $FORM{COORDY},
  });

  return 0;
}

#**********************************************************
=head2 maps_get_objects($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub maps_get_objects {
  my ($attr) = @_;

  return if (!$FORM{MODULE} || !$FORM{FUNCTION});
  
  my $module = $Auxiliary->maps_load_module($FORM{MODULE});

  return if !$module;

  my $function_ref = $module->can($FORM{FUNCTION});
  return if !$module->can('new') || !$function_ref;
  
  my $module_object = $module->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });
  $module_object->$function_ref(\%FORM);
  
  return;
}

1;