package Crm::Maps_info;

=head1 NAME

  Crm::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20210210

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);

our $VERSION = 1.00;

our (
  $admin,
  $CONF,
  $lang,
  $html,
  $db
);
my ($Crm, $Maps, $Auxiliary, $Tags);
my @priority_colors = ('', '#6c757d', '#17a2b8', '#28a745', '#ffc107', '#dc3545');

use AXbills::Base qw(in_array);

#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless($self, $class);

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  require Crm::db::Crm;
  Crm->import();
  $Crm = Crm->new($db, $admin, $CONF);

  require Maps;
  Maps->import();
  $Maps = Maps->new($db, $admin, $CONF);

  require Maps::Auxiliary;
  Maps::Auxiliary->import();
  $Auxiliary = Maps::Auxiliary->new($db, $admin, $CONF, { HTML => $html, LANG => $lang });

  return $self;
}

#**********************************************************
=head2 maps_layers()

=cut
#**********************************************************
sub maps_layers {
  return {
    LAYERS => [ {
      id                       => '36',
      name                     => 'LEAD',
      lang_name                => $lang->{LEADS},
      module                   => 'Crm',
      structure                => 'MARKER',
      export_function          => 'maps_leads',
      multiple_update_function => 'crm_lead_map_multiple_update'
    }, {
      id              => '37',
      name            => 'LEAD_TAGS',
      lang_name       => "$lang->{CRM_SHORT_LEADS} ($lang->{TAGS})",
      module          => 'Crm',
      structure       => 'MARKER',
      export_function => 'maps_leads_by_tags',
      filter          => 'TAGS',
      sublayers       => [],
      tooltip_content => '<span style=\"background-color: %color%; border-color: %color%\" ' .
        'class=\"label new-tags m-1\">%name%</span>'
    }, {
      id              => '38',
      name            => 'LEAD_COMPETITORS',
      lang_name       => "$lang->{CRM_SHORT_LEADS} ($lang->{COMPETITORS})",
      module          => 'Crm',
      structure       => 'MARKER',
      export_function => 'maps_leads_by_competitors'
    } ]
  }
}

#**********************************************************
=head2 maps_leads()

=cut
#**********************************************************
sub maps_leads {
  my $self = shift;
  my ($attr) = @_;

  my $leads = $Crm->crm_lead_points_list();

  return $Crm->{TOTAL} if $attr->{ONLY_TOTAL};

  my @objects_to_show = ();
  my %build_info = ();

  foreach my $lead (@{$leads}) {
    if ($lead->{UID}) {
      $lead->{STEP} = $lang->{USER};
      $lead->{COLOR} = '#28a745';
    }

    push @{$build_info{$lead->{BUILD_ID}}}, {
      id_btn       => $html->button($lead->{ID}, 'index=' . ::get_function_index('crm_lead_info') . "&LEAD_ID=$lead->{ID}"),
      id           => $lead->{ID},
      fio          => $lead->{FIO},
      address_flat => $lead->{ADDRESS_FLAT},
      address_full => $lead->{ADDRESS_FULL},
      step         => $html->color_mark(::_translate($lead->{STEP}), $lead->{COLOR}),
      comments     => $lead->{COMMENTS},
      uid          => $lead->{UID} ? $html->button($lead->{UID}, 'index=' . ::get_function_index('form_users') . "&UID=$lead->{UID}") : '',
      competitor   => $lead->{COMPETITOR} ? $html->button($lead->{COMPETITOR}, 'index=' . 
        ::get_function_index('crm_competitors') . "&chg=$lead->{COMPETITOR_ID}") : ''
    };
  }

  foreach my $lead (@{$leads}) {
    next if !$build_info{$lead->{BUILD_ID}} || !$lead->{color};

    my $type = _crm_get_icon($lead->{COLOR});

    my $marker_info = $Auxiliary->maps_point_info_table({
      TABLE_TITLE       => $lang->{LEADS},
      OBJECTS           => $build_info{$lead->{BUILD_ID}},
      TABLE_TITLES      => [ 'ID_BTN', 'FIO', 'PHONE', 'STEP', 'UID', 'COMPETITOR', 'ADDRESS_FULL', 'ADDRESS_FLAT', 'COMMENTS' ],
      TABLE_LANG_TITLES => [ 'ID', $lang->{FIO}, $lang->{PHONE}, $lang->{STEP}, $lang->{USER},
        $lang->{COMPETITOR}, $lang->{ADDRESS}, $lang->{FLAT}, $lang->{COMMENTS} ],
      EDITABLE_FIELDS   => [ 'FIO', 'PHONE' ],
      CHANGE_FUNCTION   => 'crm_leads'
    });

    delete $build_info{$lead->{BUILD_ID}};
    my %marker = (
      MARKER    => {
        LAYER_ID     => 36,
        ID           => $lead->{id},
        OBJECT_ID    => $lead->{build_id},
        COORDX       => $lead->{coordy} || $lead->{coordy_2},
        COORDY       => $lead->{coordx} || $lead->{coordx_2},
        SVG          => $type,
        INFOWINDOW   => $marker_info,
        NAME         => $lead->{ADDRESS_FULL},
        FIO          => $lead->{FIO},
        DISABLE_EDIT => 1
      },
      LAYER_ID  => 36,
      ID        => $lead->{id},
      OBJECT_ID => $lead->{build_id}
    );

    push @objects_to_show, \%marker;
  }

  return \@objects_to_show if $attr->{RETURN_OBJECTS};

  my $export_string = JSON::to_json(\@objects_to_show, { utf8 => 0 });
  if ($attr->{RETURN_JSON}) {
    print $export_string;
    return 1;
  }

  return $export_string;
}

#**********************************************************
=head2 maps_leads_by_tags()

=cut
#**********************************************************
sub maps_leads_by_tags {
  my $self = shift;
  my ($attr) = @_;

  my $leads = $Crm->crm_lead_points_list();

  return $Crm->{TOTAL} if $attr->{ONLY_TOTAL};
  return 0 if !in_array('Tags', \@::MODULES);

  require Tags;
  Tags->import();
  $Tags = Tags->new($self->{db}, $self->{admin}, $self->{conf});

  my @objects_to_show = ();
  my %build_info = ();

  foreach my $lead (@{$leads}) {
    next if !$lead->{TAG_IDS};

    $lead->{TAG_IDS} =~ s/,/;/g;
    my $tags_list = $Tags->list({
      ID        => $lead->{TAG_IDS},
      NAME      => '_SHOW',
      PRIORITY  => '_SHOW',
      COLOR     => '_SHOW',
      COMMENTS  => '_SHOW',
      COLS_NAME => 1,
      SORT      => 't.priority',
      DESC      => 'desc'
    });

    next if $Tags->{TOTAL} < 1;

    my $tags_container = '';
    for my $tag (@{$tags_list}) {
      my $priority_color = ($priority_colors[$tag->{priority}]) ? $priority_colors[$tag->{priority}] : $priority_colors[1];
      $tag->{color} ||= $priority_color;
      $tags_container .= ' ' . $html->element('span', $tag->{name}, {
        class => 'label new-tags m-1',
        style => "background-color: $tag->{color}; border-color: $tag->{color}"
      });
    }

    push @{$build_info{$lead->{BUILD_ID}}}, {
      id_btn       => $html->button($lead->{ID}, 'index=' . ::get_function_index('crm_lead_info') . "&LEAD_ID=$lead->{ID}"),
      id           => $lead->{ID},
      fio          => $lead->{FIO},
      step         => $html->color_mark(::_translate($lead->{STEP}), $lead->{color}),
      phone        => $lead->{PHONE},
      address_flat => $lead->{ADDRESS_FLAT},
      address_full => $lead->{ADDRESS_FULL},
      comments     => $lead->{COMMENTS},
      icon_color   => $tags_list->[0]{color},
      name         => $tags_list->[0]{name},
      tags         => $tags_container,
      tags_list    => $tags_list,
      competitor   => $lead->{COMPETITOR} ? $html->button($lead->{COMPETITOR}, 'index=' . ::get_function_index('crm_competitors') . "&chg=$lead->{COMPETITOR_ID}") : ''
    };
  }

  foreach my $lead (@{$leads}) {
    next if !$build_info{$lead->{BUILD_ID}} || !$lead->{color};

    my $type = _crm_get_icon($build_info{$lead->{BUILD_ID}}[0]{icon_color});

    my $marker_info = $Auxiliary->maps_point_info_table({
      TABLE_TITLE       => "$lang->{LEADS} ($lang->{TAGS})",
      OBJECTS           => $build_info{$lead->{BUILD_ID}},
      TABLE_TITLES      => [ 'ID_BTN', 'FIO', 'PHONE', 'STEP', 'TAGS', 'COMPETITOR', 'ADDRESS_FULL', 'ADDRESS_FLAT', 'COMMENTS' ],
      TABLE_LANG_TITLES => [ 'ID', $lang->{FIO}, $lang->{PHONE}, $lang->{STEP}, $lang->{TAGS},
        $lang->{COMPETITOR}, $lang->{ADDRESS}, $lang->{FLAT}, $lang->{COMMENTS} ],
      EDITABLE_FIELDS   => [ 'FIO', 'PHONE' ],
      CHANGE_FUNCTION   => 'crm_leads'
    });

    my %marker = (
      MARKER    => {
        LAYER_ID     => 37,
        ID           => $lead->{id},
        OBJECT_ID    => $lead->{build_id},
        COORDX       => $lead->{coordy} || $lead->{coordy_2},
        COORDY       => $lead->{coordx} || $lead->{coordx_2},
        SVG          => $type,
        INFOWINDOW   => $marker_info,
        NAME         => "<b>$build_info{$lead->{BUILD_ID}}[0]{name}</b>" . ': ' . $lead->{fio},
        FIO          => $lead->{fio},
        DISABLE_EDIT => 1
      },
      LAYER_ID  => 37,
      ID        => $lead->{id},
      OBJECT_ID => $lead->{build_id},
      TAGS      => $build_info{$lead->{BUILD_ID}}[0]{tags_list}
    );

    delete $build_info{$lead->{BUILD_ID}};
    push @objects_to_show, \%marker;
  }

  return \@objects_to_show if $attr->{RETURN_OBJECTS};

  my $export_string = JSON::to_json(\@objects_to_show, { utf8 => 0 });
  if ($attr->{RETURN_JSON}) {
    print $export_string;
    return 1;
  }

  return $export_string;
}

#**********************************************************
=head2 maps_leads_by_tags()

=cut
#**********************************************************
sub maps_leads_by_competitors {
  my $self = shift;
  my ($attr) = @_;

  my $leads = $Crm->crm_lead_points_list({ COMPETITOR_ID => '!0' });
  return $Crm->{TOTAL} if $attr->{ONLY_TOTAL};

  my @objects_to_show = ();
  my %build_info = ();

  foreach my $lead (@{$leads}) {
    if ($lead->{UID}) {
      $lead->{STEP} = $lang->{USER};
      $lead->{COLOR} = '#28a745';
    }

    push @{$build_info{$lead->{BUILD_ID}}}, {
      id_btn       => $html->button($lead->{ID}, 'index=' . ::get_function_index('crm_lead_info') . "&LEAD_ID=$lead->{ID}"),
      id           => $lead->{ID},
      fio          => $lead->{FIO},
      address_flat => $lead->{ADDRESS_FLAT},
      address_full => $lead->{ADDRESS_FULL},
      step         => $html->color_mark(::_translate($lead->{STEP}), $lead->{COLOR}),
      phone        => $lead->{PHONE},
      comments     => $lead->{COMMENTS},
      uid          => $lead->{UID} ? $html->button($lead->{UID}, 'index=' . ::get_function_index('form_users') . "&UID=$lead->{UID}") : '',
      competitor   => $lead->{COMPETITOR} ? $html->button($lead->{COMPETITOR}, 'index=' .
        ::get_function_index('crm_competitors') . "&chg=$lead->{COMPETITOR_ID}") : ''
    };
  }

  foreach my $lead (@{$leads}) {
    next if !$build_info{$lead->{BUILD_ID}} || !$lead->{competitor_color};

    my $type = _crm_get_icon($lead->{competitor_color});

    my $marker_info = $Auxiliary->maps_point_info_table({
      TABLE_TITLE       => "$lang->{LEADS} ($lang->{COMPETITORS})",
      OBJECTS           => $build_info{$lead->{BUILD_ID}},
      TABLE_TITLES      => [ 'ID_BTN', 'FIO', 'PHONE', 'STEP', 'TAGS', 'COMPETITOR', 'ADDRESS_FULL', 'ADDRESS_FLAT', 'COMMENTS' ],
      TABLE_LANG_TITLES => [ 'ID', $lang->{FIO}, $lang->{PHONE}, $lang->{STEP}, $lang->{TAGS},
        $lang->{COMPETITOR}, $lang->{ADDRESS}, $lang->{FLAT}, $lang->{COMMENTS} ],
      EDITABLE_FIELDS   => [ 'FIO', 'PHONE' ],
      CHANGE_FUNCTION   => 'crm_leads'
    });

    my %marker = (
      MARKER    => {
        LAYER_ID     => 38,
        ID           => $lead->{id},
        OBJECT_ID    => $lead->{build_id},
        COORDX       => $lead->{coordy} || $lead->{coordy_2},
        COORDY       => $lead->{coordx} || $lead->{coordx_2},
        SVG          => $type,
        INFOWINDOW   => $marker_info,
        NAME         => $lead->{competitor},
        DISABLE_EDIT => 1
      },
      LAYER_ID  => 38,
      ID        => $lead->{id},
      OBJECT_ID => $lead->{build_id}
    );

    delete $build_info{$lead->{BUILD_ID}};
    push @objects_to_show, \%marker;
  }

  return \@objects_to_show if $attr->{RETURN_OBJECTS};

  my $export_string = JSON::to_json(\@objects_to_show, { utf8 => 0 });
  if ($attr->{RETURN_JSON}) {
    print $export_string;
    return 1;
  }

  return $export_string;
}

#**********************************************************
=head2 maps_report_info()

=cut
#**********************************************************
sub maps_report_info {
  my $self = shift;
  my $layer_id = shift;

  return '' if !$layer_id;

  return $self->_maps_leads_report_info() if ($layer_id eq '36');
  return $self->_maps_leads_by_tags_report_info() if ($layer_id eq '37');
}

#**********************************************************
=head2 _maps_leads_report_info()

=cut
#**********************************************************
sub _maps_leads_report_info {
  my $self = shift;

  my $leads = $self->maps_leads({ RETURN_OBJECTS => 1 });

  my $report_table = $html->table({
    width       => '100%',
    caption     => $lang->{LEADS},
    title_plain => [ '#', $lang->{FIO}, $lang->{ADDRESS}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  my $lead_index = ::get_function_index('crm_lead_info');
  foreach my $lead (@{$leads}) {
    my $lead_info = $lead->{MARKER};
    my $location_btn = $Auxiliary->maps_show_object_button(36, $lead_info->{OBJECT_ID});
    my $lead_btn = $html->button($lead_info->{ID}, "index=$lead_index&LEAD_ID=$lead_info->{ID}");

    $report_table->addrow($lead_btn, $lead_info->{FIO}, $lead_info->{NAME}, $location_btn);
  }

  return $report_table->show();
}

#**********************************************************
=head2 _maps_leads_by_tags_report_info()

=cut
#**********************************************************
sub _maps_leads_by_tags_report_info {
  my $self = shift;

  my $leads = $self->maps_leads_by_tags({ RETURN_OBJECTS => 1 });

  my $report_table = $html->table({
    width       => '100%',
    caption     => $lang->{LEADS},
    title_plain => [ '#', $lang->{FIO}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  my $lead_index = ::get_function_index('crm_lead_info');
  foreach my $lead (@{$leads}) {
    my $lead_info = $lead->{MARKER};
    my $location_btn = $Auxiliary->maps_show_object_button(37, $lead_info->{OBJECT_ID});
    my $lead_btn = $html->button($lead_info->{ID}, "index=$lead_index&LEAD_ID=$lead_info->{ID}");

    $report_table->addrow($lead_btn, $lead_info->{FIO}, $location_btn);
  }

  return $report_table->show();
}

#**********************************************************
=head2 _crm_get_icon()

=cut
#**********************************************************
sub _crm_get_icon {
  my $color = shift;

  return qq{
    <svg style="width:23px; height:38" xmlns="http://www.w3.org/2000/svg" viewBox="10 10 44 44" aria-labelledby="title"
    aria-describedby="desc" role="img" xmlns:xlink="http://www.w3.org/1999/xlink">
      <title>Person</title>
      <desc>A color styled icon from Orion Icon Library.</desc>
      <circle data-name="layer1"
      cx="32" cy="9" r="7" fill="$color"></circle>
      <path data-name="layer1" d="M43 22h-5l-6 10-6-10h-5a3 3 0 0 0-3 3v16a3 3 0 0 0 3 3h3v15a3 3 0 0 0 3 3h10a3 3 0 0 0 3-3V44h3a3 3 0 0 0 3-3V25a3 3 0 0 0-3-3z"
      fill="$color"></path>
      <path data-name="opacity" d="M32 16a7 7 0 0 0 2-.3 7 7 0 0 1 0-13.4A7 7 0 1 0 32 16zm-4 43V44h-3a3 3 0 0 1-3-3V25a3 3 0 0 1 3-3h-4a3 3 0 0 0-3 3v16a3 3 0 0 0 3 3h3v15a3 3 0 0 0 3 3h4a3 3 0 0 1-3-3z"
      fill="#000064" opacity=".15"></path>
      <circle data-name="stroke" cx="32" cy="9" r="7" fill="none" stroke="#000000"
      stroke-linecap="round" stroke-linejoin="round" stroke-width="2"></circle>
      <path data-name="stroke" d="M43 22h-5l-6 10-6-10h-5a3 3 0 0 0-3 3v16a3 3 0 0 0 3 3h3v15a3 3 0 0 0 3 3h10a3 3 0 0 0 3-3V44h3a3 3 0 0 0 3-3V25a3 3 0 0 0-3-3z"
      fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"
      stroke-width="2"></path>
    </svg>
  };
}
1;