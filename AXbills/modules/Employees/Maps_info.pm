package Employees::Maps_info;

=head1 NAME

  Employees::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20210928

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
my ($Employees, $Maps, $Auxiliary, $Tags);
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

  require Employees;
  Employees->import();
  $Employees = Employees->new($db, $admin, $CONF);

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
      id              => '39',
      name            => 'WORKS',
      lang_name       => $lang->{WORK},
      module          => 'Employees',
      structure       => 'MARKER',
      export_function => 'maps_works'
    } ]
  }
}

#**********************************************************
=head2 maps_works()

=cut
#**********************************************************
sub maps_works {
  my $self = shift;
  my ($attr) = @_;

  my $works = $Employees->employees_work_for_map({ COLS_NAME => 1 });
  return $Employees->{TOTAL} if $attr->{ONLY_TOTAL};

  my @objects_to_show = ();
  my %build_info = ();
  my %build_work_status = ();

  foreach my $work (@{$works}) {
    push @{$build_info{$work->{build_id}}}, {
      id        => $work->{id},
      work_done => $work->{work_done},
      sum       => $work->{sum},
      paid      => $work->{paid},
      date      => $work->{date},
      comments  => $work->{comments},
      work_id   => $work->{work_id},
      admin     => $work->{admin},
      name      => $work->{name},
      uid       => $work->{uid} ? $html->button($work->{uid}, 'index=' . ::get_function_index('form_users') . "&UID=$work->{uid}") : '',
      done      => $work->{work_done} ? $html->element('span', '', {
        class => 'fas fa-check-circle text-green',
        title => $lang->{DONE}
      }) : ''
    };

    if (!$build_work_status{$work->{build_id}}{$work->{work_done}}) {
      $build_work_status{$work->{build_id}}{$work->{work_done}} = 1;
    }
    else {
      $build_work_status{$work->{build_id}}{$work->{work_done}}++;
    }
  }

  foreach my $work (@{$works}) {
    next if !$build_info{$work->{build_id}};

    my $type = _work_get_icon($build_work_status{$work->{build_id}}{1} && (!$build_work_status{$work->{build_id}}{0} ||
      $build_work_status{$work->{build_id}}{1} > $build_work_status{$work->{build_id}}{0}) ? 'green' : 'black');

    my $marker_info = $Auxiliary->maps_point_info_table({
      TABLE_TITLE       => $lang->{WORK},
      OBJECTS           => $build_info{$work->{build_id}},
      TABLE_TITLES      => [ 'ID', 'NAME', 'DONE', 'UID', 'DATE', 'COMMENTS' ],
      TABLE_LANG_TITLES => [ 'ID', $lang->{WORK}, $lang->{DONE}, $lang->{USER}, $lang->{DATE}, $lang->{COMMENTS} ],
    });

    my %marker = (
      MARKER    => {
        LAYER_ID     => 39,
        ID           => $work->{id},
        OBJECT_ID    => $work->{build_id},
        COORDX       => $work->{coordy},
        COORDY       => $work->{coordx},
        SVG          => $type,
        INFOWINDOW   => $marker_info,
        NAME         => $work->{work_id},
        WORK_NAME    => $work->{name},
        CREATED      => $work->{date},
        DISABLE_EDIT => 1
      },
      LAYER_ID  => 38,
      ID        => $work->{id},
      OBJECT_ID => $work->{build_id}
    );

    delete $build_info{$work->{build_id}};
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

  my $works = $self->maps_works({ RETURN_OBJECTS => 1 });

  my $report_table = $html->table({
    width       => '100%',
    caption     => $lang->{WORK},
    title_plain => [ '#', $lang->{NAME}, $lang->{CREATED}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  foreach my $work (@{$works}) {
    my $work_info = $work->{MARKER};
    my $location_btn = $Auxiliary->maps_show_object_button(39, $work_info->{OBJECT_ID});

    $report_table->addrow($work_info->{ID}, $work_info->{NAME}, $work_info->{CREATED}, $location_btn);
  }

  return $report_table->show();
}

#**********************************************************
=head2 _crm_get_icon()

=cut
#**********************************************************
sub _work_get_icon {
  my $color = shift;

  return qq{<svg width="50" height="30" viewBox="0 0 75 55" xmlns="http://www.w3.org/2000/svg" version="1.1" class="svg-icon-svg">
    <path class="svg-icon-path" d="M 27 2 A 5 5 0 0 0 22 7 A 5 5 0 0 0 27 12 A 5 5 0 0 0 32 7 A 5 5 0 0 0 27 2 z M 10 11
    C 9.15 11 8.3603906 11.430391 7.9003906 12.150391 L 3.4003906 19.150391 C 2.6503906 20.310391 2.9903906 21.859609
     4.1503906 22.599609 C 5.0103906 23.149609 6.0808594 23.110078 6.8808594 22.580078 C 6.9108594 22.610078 6.9309375
     22.630625 6.9609375 22.640625 L 9.4296875 23.910156 L 10.560547 22.25 L 8.1503906 21 L 11.369141 16 L 14.830078 16
     L 10.560547 22.25 L 19.480469 26.849609 L 23.359375 21.029297 L 27.082031 32.105469 C 27.354031 33.191469 28.329
     34 29.5 34 C 30.881 34 32 32.881 32 31.5 C 32 31.301 31.971734 31.110781 31.927734 30.925781 C 31.926734 30.917781
     27.800781 18.150391 27.800781 18.150391 C 27.660781 17.580391 27.319844 17.070469 26.839844 16.730469 L 19.589844
     11.480469 C 19.169844 11.170469 18.649141 11 18.119141 11 L 10 11 z M 19.480469 26.849609 L 20.660156 29.720703 L
     24.90625 31.90625 C 24.72725 31.37425 24.439234 30.520594 23.990234 29.183594 L 19.480469 26.849609 z M 20.660156
     29.720703 L 9.4296875 23.910156 L 9.3203125 24.070312 C 9.1903125 24.250313 9.0897656 24.449922 9.0097656 24.669922
     L 2.2109375 44.509766 C 2.0729375 44.824766 2.0049531 45.154516 2.0019531 45.478516 C 1.9929531 46.451516 2.5567656
     47.384062 3.5097656 47.789062 C 3.8297656 47.929062 4.17 48 4.5 48 C 5.47 48 6.3890625 47.440234 6.7890625
     46.490234 L 13.630859 31.119141 L 18 37 L 19.009766 45.759766 C 19.149766 47.039766 20.23 48 21.5 48 C 21.58 48
     21.669766 48.000234 21.759766 47.990234 C 23.052766 47.848234 24.014 46.74375 24 45.46875 C 23.999 45.39275 23.998234
     45.317234 23.990234 45.240234 L 22.990234 35.619141 C 22.950234 35.289141 22.849453 34.959922 22.689453 34.669922
     L 20.660156 29.720703 z M 33.253906 33.970703 C 32.856906 34.572703 32.312641 35.059109 31.681641 35.412109 L 34.330078
     36.779297 L 39.072266 43.417969 L 40.029297 47.242188 A 1.0001 1.0001 0 0 0 41.640625 47.767578 L 47.640625 42.767578
     A 1.0001 1.0001 0 0 0 47.970703 41.757812 L 46.970703 37.757812 C 46.970039 37.755272 46.971389 37.752538 46.970703
     37.75 C 46.968871 37.743039 46.964863 37.737362 46.962891 37.730469 A 1.0001 1.0001 0 0 0 46.857422 37.486328 C
     46.856676 37.485101 46.856219 37.483645 46.855469 37.482422 A 1.0001 1.0001 0 0 0 46.107422 37.005859 L 35.330078
     35.039062 L 33.253906 33.970703 z M 37.25 37.419922 L 43.71875 38.599609 L 41.955078 40.070312 L 40.189453 41.539062
     L 37.25 37.419922 z M 45.416016 39.789062 L 45.876953 41.634766 L 41.583984 45.210938 L 41.123047 43.367188 L
     45.416016 39.789062 z" stroke-width="2"
    stroke="$color" stroke-opacity="1" fill="$color" fill-opacity="0.4"></path></svg>}
}

1;