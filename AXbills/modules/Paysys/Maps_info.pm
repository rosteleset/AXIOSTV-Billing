package Paysys::Maps_info;

=head1 NAME

  Paysys::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20201021

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
my $Paysys;
my $Auxiliary;

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

  require Paysys;
  Paysys->import();
  $Paysys = Paysys->new($db, $admin, $CONF);

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
      id              => '35',
      name            => 'TERMINALS',
      lang_name       => $lang->{TERMINALS},
      module          => 'Paysys',
      structure       => 'MARKER',
      export_function => 'paysys_terminals_show'
    } ]
  };
}

#**********************************************************
=head2 paysys_terminals_show()

=cut
#**********************************************************
sub paysys_terminals_show {
  my $self = shift;
  my ($attr) = @_;

  my $terminals = $Paysys->terminal_list_with_coords({
    COORDX_CENTER => '_SHOW',
    COORDY_CENTER => '_SHOW',
    COORDX        => '_SHOW',
    COORDY        => '_SHOW',
    TYPE_ID       => '_SHOW',
    TYPE          => '_SHOW',
    START_WORK    => '_SHOW',
    END_WORK      => '_SHOW',
    WORK_DAYS     => '_SHOW',
    ADDRESS_FULL  => '_SHOW',
    DESCRIPTION   => '_SHOW',
    LOCATION_ID   => '!',
    COLS_NAME     => 1,
    PAGE_ROWS     => 10000
  });

  return $Paysys->{TOTAL} if $attr->{ONLY_TOTAL};

  my @objects_to_show = ();

  foreach my $terminal (@{$terminals}) {
    my @start_work = split(":", $terminal->{start_work}) if $terminal->{start_work};
    my @end_work = split(":", $terminal->{end_work}) if $terminal->{end_work};

    $terminal->{start_work} = ($start_work[0] || "00") . ":" . ($start_work[1] || "00");
    $terminal->{end_work} = ($end_work[0] || "00") . ":" . ($end_work[1] || "00");

    my @works_days = ();
    my @WEEKDAYS_WORK = ();
    if ($terminal->{work_days}) {
      my $bin = sprintf("%b", int $terminal->{work_days});
      @WEEKDAYS_WORK = split(//, $bin);
    }

    my $count = 1;
    foreach my $day (@WEEKDAYS_WORK) {
      push @works_days, $main::WEEKDAYS[$count] if $day;
      $count++;
    }
    $terminal->{work_days} = join(', ', @works_days) || '';

    my $info_array = [
      [ $lang->{TYPE}, $terminal->{name} ],
      [ $lang->{ADDRESS}, $terminal->{address_full} ],
      [ $lang->{WORK_DAYS}, $terminal->{work_days} ],
      [ $lang->{WORK_TIME}, "$terminal->{start_work} - $terminal->{end_work}" ],
      [ $lang->{DESCRIBE}, $terminal->{description} || '' ],
    ];

    my $line_info = '<table class="table table-hover">';
    $line_info .= join('', map {"<tr><td><strong>$_->[0]</strong></td><td>" . ($_->[1] || q{}) . ' </td></tr>'} @{$info_array});
    $line_info .= '</table>';

    $line_info =~ s/\"/\\\"/g if $attr->{ESCAPE};

    my %marker = (
      MARKER    => {
        LAYER_ID      => 35,
        ID            => $terminal->{id},
        OBJECT_ID     => $terminal->{location_id},
        COORDX        => $terminal->{coordy} || $terminal->{coordx_center},
        COORDY        => $terminal->{coordx} || $terminal->{coordy_center},
        FULL_TYPE_URL => 1,
        TYPE          => "/images/terminals/terminal_$terminal->{type_id}.png",
        INFOWINDOW    => $line_info,
        NAME          => ($terminal->{name} || q{}) .' : '. ($terminal->{address_full} || q{}),
        TERMINAL_NAME => $terminal->{name},
        ADDRESS       => $terminal->{address_full},
        DISABLE_EDIT  => 1
      },
      LAYER_ID  => 35,
      ID        => $terminal->{id},
      OBJECT_ID => $terminal->{location_id}
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
=head2 maps_report_info()

=cut
#**********************************************************
sub maps_report_info {
  my $self = shift;
  my $layer_id = shift;

  return '' if !$layer_id;

  my $terminals = $self->paysys_terminals_show({ RETURN_OBJECTS => 1 });

  my $report_table = $html->table({
    width       => '100%',
    caption     => $lang->{TERMINALS},
    title_plain => [ '#', $lang->{NAME}, $lang->{CREATED}, $lang->{LOCATION} ],
    DATA_TABLE  => 1
  });

  foreach my $terminals (@{$terminals}) {
    my $terminal_info = $terminals->{MARKER};
    my $location_btn = $Auxiliary->maps_show_object_button(35, $terminal_info->{OBJECT_ID});

    $report_table->addrow($terminal_info->{ID}, $terminal_info->{TERMINAL_NAME}, $terminal_info->{ADDRESS}, $location_btn);
  }

  return $report_table->show();
}

1;