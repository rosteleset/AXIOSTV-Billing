#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
  our $Bin;
  use FindBin '$Bin';
  if ( $Bin =~ m/\/axbills(\/)/ ){
    my $libpath = substr($Bin, 0, $-[1]);
    unshift (@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/axbills dir \n";
  }
}
use AXbills::Init qw/$db $admin %conf/;

use AXbills::Base qw/_bp/;

#**********************************************************
=head2 TEST

=cut
#**********************************************************

use Cablecat;
use Maps;

my Cablecat $Cablecat = new_ok('Cablecat' => [ $db, $admin, \%conf ]);
my Maps $Maps = new_ok('Maps' => [ $db, $admin, \%conf ]);

my $coordx1 = '48';
my $coordy1 = '-2';

my $coordx2 = '48';
my $coordy2 = '2';

my $middle_coordx = ($coordx1 + $coordx2) / 2;
my $middle_coordy = ($coordy1 + $coordy2) / 2;

subtest maps_break_polyline => sub {
  my $polyline_id = create_polyline();
  set_polyline_points($polyline_id);
  
  # While we have only polyline can check Maps->break_polyline();
  my $result = $Maps->break_polyline($polyline_id, {
      COORDX => $middle_coordx,
      COORDY => $middle_coordy,
    });
    
  # Result should be [ $new_line_1_id, $new_line_2_id ]
  ok(ref $result eq 'ARRAY', 'Breaked polyline without error');
  if ( !ref $result ) {
    warn $result;
  }
  
  my $check_polyline_points = sub {
    my ($pl_id, $point_1, $point_2) = @_;
    
    my $polyline_info = $Maps->polylines_info({OBJECT_ID => $pl_id});
    # Now check new polylines coords
    my $pl_p = $Maps->polyline_points_list({ POLYLINE_ID => $polyline_info->{id}, COORDX => '_SHOW', COORDY => '_SHOW', COLS_UPPER => 0 });
    
    ok(ref $pl_p eq 'ARRAY' && scalar(@{$pl_p}) == 2, 'Got polyline_points');
    
    return scalar(grep { $_->{coordx} eq $point_1->{coordx} && $_->{coordy} eq $point_1->{coordy} } @$pl_p)
        && scalar(grep { $_->{coordx} eq $point_2->{coordx} && $_->{coordy} eq $point_2->{coordy} } @$pl_p)
  };
  
  ok($check_polyline_points->($result->[0],
      { coordx => $coordx2,       coordy => $coordy2 },
      { coordx => $middle_coordx, coordy => $middle_coordy },
    ), 'new polyline1 has right coordinates'
  );
  
  ok($check_polyline_points->($result->[1],
      { coordx => $middle_coordx, coordy => $middle_coordy },
      { coordx => $coordx1,       coordy => $coordy1 },
    ), 'new polyline2 has right coordinates'
  );
  

  
};

subtest cablecat_break_cable => sub {
    # Now reverting polyline changes and test cablecat->break_cable
    my ($well_1_id, $well_2_id) = create_wells();
    my $polyline_id = create_polyline();
    set_polyline_points($polyline_id);
    
    my $cable_object_id = $Maps->points_add({
        COORDX   => $middle_coordx,
        COORDY   => $middle_coordy,
        TYPE_ID  => 7,
        EXTERNAL => 1
      });
    
    # Create cable for test
    my $cable_id = $Cablecat->cables_add({
      NAME     => 'TEST_CABLE',
      POINT_ID => $cable_object_id,
      WELL_1   => $well_1_id,
      WELL_2   => $well_2_id
    });
    ok($cable_id, 'created cable');
    
    # To break cable should create one more well
    my $well_3_object_id = $Maps->points_add({
      COORDX   => ($coordx1 + $coordx2) / 2,
      COORDY   => ($coordy1 + $coordy2) / 2,
      TYPE_ID  => 1,
      EXTERNAL => 1
    });
    ok($well_3_object_id, 'Created well 3 point');
    
    my $well_3_id = $Cablecat->wells_add({
      NAME     => 'TEST_WELL_3',
      POINT_ID => $well_3_object_id
    });
    ok($well_3_id, 'Created well 3');
    
    my ($old_cable, $cable_2_id, $cable_3_id) = @{ $Cablecat->break_cable($cable_id, $well_3_id) };
    ok($cable_2_id && $cable_3_id, "Has new cable ids : $cable_2_id && $cable_3_id ");
  };

# Remove test data
#$Maps->points_del($_) for ( $cable_object_id, $well_1_object_id, $well_2_object_id, $well_3_object_id );
#delete_polyline($cable_polyline_id);
#$Cablecat->wells_del($_) for ( $well_1_id, $well_2_id, $well_3_id );
#$Cablecat->cables_del($_) for ( $cable_id );


#**********************************************************
=head2 create_wells()

=cut
#**********************************************************
sub create_wells {
  # Create wells for test
  my $well_1_object_id = $Maps->points_add({
    COORDX   => $coordx1,
    COORDX   => $coordy1,
    TYPE_ID  => 1,
    EXTERNAL => 1
  });
  ok($well_1_object_id, 'Created well 1 point');
  
  my $well_2_object_id = $Maps->points_add({
    COORDX   => $coordx2,
    COORDX   => $coordy2,
    TYPE_ID  => 1,
    EXTERNAL => 1
  });
  ok($well_2_object_id, 'Created well 2 point');
  
  my $well_1_id = $Cablecat->wells_add({
    NAME     => 'TEST_WELL_1',
    POINT_ID => $well_1_object_id
  });
  ok($well_1_id, 'Created well 1');
  
  my $well_2_id = $Cablecat->wells_add({
    NAME     => 'TEST_WELL_2',
    POINT_ID => $well_2_object_id
  });
  ok($well_2_id, 'Created well 2');
  
  return ($well_1_id, $well_2_id);
}

#**********************************************************
=head2 create_polyline()

=cut
#**********************************************************
sub create_polyline {
  my $cable_object_id = $Maps->points_add({
    EXTERNAL => 1,
    TYPE_ID  => 7
  });
  
  ok($cable_object_id, "Created cable maps object $cable_object_id");
  
  my $cable_polyline_id = $Maps->polylines_add({
    OBJECT_ID => $cable_object_id,
    LAYER_ID => 11
  });
  
  ok($cable_polyline_id, "Created cable polyline $cable_polyline_id");
  
  return $cable_polyline_id;
}

#**********************************************************
=head2 set_polyline_points($polyline_id)

=cut
#**********************************************************
sub set_polyline_points {
  my($pl_id) = @_;
  
  $Maps->polyline_points_del({}, { polyline_id =>  $pl_id});
  
  my $inserted = $Maps->polyline_points_add({
    POLYLINE_ID => $pl_id,
    POINTS      => [
      {
        COORDX => $coordx1,
        COORDY => $coordy1,
      },
      {
        COORDX => $coordx2,
        COORDY => $coordy2,
      }
    ]
  });
  
  return $inserted;
}

#**********************************************************
=head2 delete_polyline()

=cut
#**********************************************************
sub delete_polyline {
  my ($pl_id) = @_;
  $Maps->polyline_points_del({}, { polyline_id =>  $pl_id});
  $Maps->polylines_del($pl_id);
}


done_testing();

