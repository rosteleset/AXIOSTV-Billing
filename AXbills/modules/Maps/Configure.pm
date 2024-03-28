use strict;
use warnings FATAL => 'all';
use v0.02;

=head1 NAME

  Maps::Configure - forms for webinterface

=cut

require JSON;
JSON->import(qw/to_json from_json/);

use AXbills::Base qw/_bp in_array/;
use AXbills::Experimental;
use Maps::Shared qw/:all MAPS_ICONS_DIR MAPS_ICONS_DIR_WEB_PATH LAYER_ID_BY_NAME CLOSE_OUTER_MODAL_SCRIPT/;

our ($db,
  $admin,
  %conf,
  $html,
  %lang,
  %permissions,
  $Nas
);

my $Address = Address->new($db, $admin, \%conf);
require Control::Address_mng;

our ($Maps, @MAPS_CUSTOM_ICONS);

#**********************************************************
=head2 maps_auto_coords()

=cut
#**********************************************************
sub maps_auto_coords {

  $html->tpl_show(_include('maps_coords_form', 'Maps'), {
    DISTRICTS_SELECT => _maps_address_districts(\%FORM),
    STREETS_SELECT   => _maps_address_streets(\%FORM)
  });

  return 0 if !$FORM{STREET_ID};

  my $builds = $Maps->build_list_without_coords({
    STREET_ID          => $FORM{STREET_ID},
    FULL_ADDRESS       => '_SHOW',
    STREET_NAME        => '_SHOW',
    DISTRICT_NAME      => '_SHOW',
    NUMBER             => '_SHOW',
    LOCATION_ID        => '_SHOW',
    STREET_SECOND_NAME => '_SHOW'
  });

  return 0 if $Maps->{TOTAL} < 1;

  my $feel_all_btn = $html->button($lang{FEEL_ALL}, '', {
    class     => 'btn btn-sm btn-primary',
    SKIP_HREF => 1,
    ex_params => "onClick='feelAllCoords()'"
  });

  my $table = $html->table({
    width   => '100%',
    caption => $lang{BUILDS},
    title   => [ $lang{DISTRICT}, $lang{STREET}, $lang{SECOND_NAME}, $lang{NUMBER}, $lang{STATUS}, '' ],
    pages   => $Maps->{TOTAL},
    ID      => 'BUILDS',
    MENU    => [ $feel_all_btn ]
  });

  foreach (@{$builds}) {
    my $status = $html->element('span', $lang{NO_COORDINATES_SPECIFIED}, {
      class => 'badge badge-default',
      id    => "number_$_->{location_id}"
    });

    my $find_button = $html->button($lang{SEARCH}, '', {
      class     => 'btn btn-sm btn-primary search-btn',
      SKIP_HREF => 1,
      ex_params => "onClick='findLocation(\"$_->{district_name}\", \"$_->{street_name}\", \"$_->{street_second_name}\", \"$_->{number}\", \"$_->{location_id}\")' " .
        "id='button_number_$_->{location_id}'"
    });
    $table->addrow($_->{district_name}, $_->{street_name}, $_->{street_second_name}, $_->{number}, $status, $find_button);
  }

  print $table->show;

  return 1;
}

#**********************************************************
=head2 _maps_address_districts()

=cut
#**********************************************************
sub _maps_address_districts {
  my ($attr) = @_;

  #  Districts
  my $districts = $Address->district_list({
    COLS_NAME => 1,
    PAGE_ROWS => 999999,
    SORT      => 'd.name'
  });

  my $districts_select = $html->form_select('DISTRICT_ID', {
    ID          => $attr->{DISTRICT_SELECT_ID},
    SELECTED    => $attr->{DISTRICT_ID} || 0,
    SEL_LIST    => $districts,
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name',
    NO_ID       => 1,
    SEL_OPTIONS => { 0 => '--' },
    EX_PARAMS   => 'onChange="GetStreets(this)"',
  });

  return $districts_select;
}

#**********************************************************
=head2 _maps_address_streets()

=cut
#**********************************************************
sub _maps_address_streets {
  my ($attr) = @_;

  my $streets = $Address->street_list({
    DISTRICT_ID => $attr->{DISTRICT_ID},
    STREET_NAME => '_SHOW',
    SORT        => 's.name',
    COLS_NAME   => 1,
    PAGE_ROWS   => 999999
  });

  my $streets_select = $html->form_select('STREET_ID', {
    ID          => 'STREET_ID',
    SELECTED    => $attr->{STREET_ID} || 0,
    SEL_LIST    => $attr->{DISTRICT_ID} ? $streets : '',
    SEL_KEY     => 'id',
    SEL_VALUE   => 'street_name',
    NO_ID       => 1,
    SEL_OPTIONS => { 0 => '--' },
  });

  return $streets_select;
}

#**********************************************************
=head2 _maps_icon_filename_select()

=cut
#**********************************************************
sub _maps_icon_filename_select {
  my ($attr) = @_;

  my $name = $attr->{NAME} || 'ICON';

  our $base_dir;
  $base_dir ||= '/usr/axbills';

  my $files = _get_files_in($base_dir . MAPS_ICONS_DIR, { FILTER => 'png' });

  return 0 if (!$files);

  if ($attr->{NO_EXTENSION} || $FORM{GET_SELECT}) {
    $_ =~ s/\.png// foreach (@{$files});
  }

  my $icons_select = $html->form_select($name, {
    SELECTED  => $attr->{$name} || $FORM{ICON},
    SEL_ARRAY => $files,
    NO_ID     => 1,
    ID        => 'ICON_SELECT'
  });

  print $icons_select if $FORM{GET_SELECT};

  return $icons_select;
}

#**********************************************************
=head2 maps_point_types_main()

=cut
#**********************************************************
sub maps_point_types_main {

  if ($FORM{change}) {
    $Maps->point_types_change({ %FORM, ID => $FORM{chg} });
    show_result($Maps, $lang{CHANGED});
  }
  elsif ($FORM{chg}) {
    my $type = $Maps->point_types_list({
      ID               => $FORM{chg},
      SHOW_ALL_COLUMNS => 1,
      DESC             => 1
    });

    my $open_upload_modal_btn = $html->button('UPLOAD', "get_index=_maps_icon_ajax_upload&header=2", {
      ICON          => 'fa fa-upload',
      LOAD_TO_MODAL => 1,
      class         => 'btn btn-success btn-sm',
      ID            => 'UPLOAD_BUTTON',
    });

    $html->tpl_show(_include('maps_point_types', 'Maps'), {
      NAME        => _translate($type->[0]{name}),
      COMMENTS    => $type->[0]{comments},
      ICON_SELECT => _maps_icon_filename_select({ NAME => 'ICON', NO_EXTENSION => 1, ICON => $type->[0]{icon} }),
      UPLOAD_BTN  => $open_upload_modal_btn,
      ID          => $FORM{chg}
    });
  }

  my $types_list = $Maps->point_types_list({
    SHOW_ALL_COLUMNS => 1,
    DESC             => 1
  });

  my $types_table = $html->table({
    caption => $lang{OBJECT_TYPES},
    title   => [ 'Id', $lang{NAME}, $lang{ICON}, $lang{COMMENTS}, '' ],
    ID      => 'POINT_TYPES'
  });

  foreach (@{$types_list}) {
    my $chg_button = $html->button('', "index=$index&chg=$_->{id}", { class => 'change' });
    $types_table->addrow($_->{id}, _translate($_->{name}),
      $_->{icon} ? _maps_get_icon_img($_->{icon}) : '', $_->{comments}, $chg_button);
  }

  print $types_table->show();

  return 1;
}

#**********************************************************
=head2 _maps_get_icon_img()

=cut
#**********************************************************
sub _maps_get_icon_img {
  my ($icon_name, $attr) = @_;

  my $folder = '/images/maps/icons/';

  $icon_name .= '.png' if ($icon_name !~ /\.png$/);

  return "$folder$icon_name" if $attr->{GET_SRC};

  return "<img src='$folder$icon_name' alt='$icon_name' />";
}

#**********************************************************
=head2 _maps_icon_ajax_upload()

=cut
#**********************************************************
sub _maps_icon_ajax_upload {

  return unless ($FORM{IN_MODAL});

  if (!$FORM{UPLOAD_FILE}) {
    $html->tpl_show(_include('maps_icon_upload_form', 'Maps'), {
      CALLBACK_FUNC => '_maps_icon_ajax_upload',
      TIMEOUT       => '0',
    });
    return 1;
  }

  # Remove TPL_DIR part
  my $upload_path = MAPS_ICONS_DIR;
  $upload_path =~ s/\/AXbills\/templates\///g;

  my $uploaded = upload_file($FORM{UPLOAD_FILE}, {
    PREFIX     => $upload_path,
    EXTENTIONS => 'jpg,jpeg,png,gif'
  });

  return 1;
}

1;