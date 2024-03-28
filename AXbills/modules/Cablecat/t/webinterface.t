#!/usr/bin/perl
use strict;
use warnings;
use v5.16;
use utf8;

use Test::More;
use Carp qw/carp/;
use JSON qw/encode_json decode_json/;

use AXbills::Base qw/_bp/;

my $entities_count = 8;
my $generic_operations_for_each_entity = 5;
my $non_generic_operations = ( 7 + 3 + 2) + (5 + 2) + 1;
plan tests => 4 + ($entities_count * $generic_operations_for_each_entity) + $non_generic_operations;

my $BP_ARGS = { TO_CONSOLE => 1 };

our ($db, $admin, %conf, %FORM, $DATE, $TIME);
require_ok 'libexec/config.pl';
#use_ok('Cams');


open(my $null_fh, '>', '/dev/null') or die('Open /dev/null');
select $null_fh;
#admin interface
$ENV{'REQUEST_METHOD'} = "GET";
$ENV{'QUERY_STRING'} = "user=axbills&passwd=axbills";
require_ok( "../cgi-bin/admin/index.cgi" );
require_ok( "../AXbills/modules/Cablecat/webinterface" );
select STDOUT;

use Cablecat;
my Cablecat $Cablecat = new_ok('Cablecat' => [ $db, $admin, \%conf ]);

do "AXbills/Misc.pm";
my %added_ids = ();

my $test_color_scheme = sub {
  {
    NAME   => 'TEST_COLOR_SCHEME',
    COLORS => 'fc0204,fcfe04,048204,0402fc'
  }
};

my $test_cable_type = sub {
  {
    NAME                    => 'TEST_CABLE_TYPE',
    COLOR_SCHEME_ID         => 1,
    MODULES_COLOR_SCHEME_ID => 1,
    FIBERS_COUNT            => 48,
    MODULES_COUNT           => 8,
    FIBERS_TYPE_NAME        => 'SL',
    COMMENTS                => 'Generated',
  }
};

my $test_connecter_type = sub {
  {
    NAME       => 'TEST_CONNECTER_TYPE',
    CARTRIDGES => 8,
  }
};

my $test_splitter_type = sub {
  {
    NAME       => 'TEST_SPLITTER_TYPE',
    FIBERS_IN  => 1,
    FIBERS_OUT => 2
  }
};

my $test_cable = sub {
  state $number = 0;
  {
    NAME     => 'TEST_CABLE_' . $number++,
    TYPE_ID  => $added_ids{cable_type}->[0],
    COMMENTS => 'GENERATED'
  }
};
my $test_well = sub {
  state $number = 0;
  {
    NAME      => 'TEST_WELL_' . $number++,
    PLANNED   => 1,
    INSTALLED => "$DATE $TIME",
    POINT_ID  => 1,
    PARENT_ID => 1,
  }
};

my $test_connecter = sub {
  state $number = 0;
  {
    TYPE_ID   => $added_ids{connecter_type}->[0],
    NAME      => 'TEST_CONNECTER_' . $number++,
    PLANNED   => 1,
    INSTALLED => "$DATE $TIME",
    WELL_ID   => $added_ids{'cablecat_well'}->[0],
  }
};
my $test_splitter = sub {
  {
    TYPE_ID   => $added_ids{splitter_type}->[0],
    PLANNED   => 1,
    INSTALLED => "$DATE $TIME",
    WELL_ID   => $added_ids{cablecat_well}->[0],
  }
};

my @entities = (
  { NAME => 'color_scheme', FORM => $test_color_scheme },
  { NAME => 'cable_type', FORM => $test_cable_type },
  { NAME => 'connecter_type', FORM => $test_connecter_type },
  { NAME => 'splitter_type', FORM => $test_splitter_type },
  { NAME => 'cable', FORM => $test_cable },
  { NAME => 'well', FORM => $test_well },
  { NAME => 'connecter', FORM => $test_connecter },
  { NAME => 'splitter', FORM => $test_splitter },
);

foreach my $entity ( @entities ) {
  test_generic_add($entity->{NAME}, &{$entity->{FORM}}());
}
foreach my $entity ( @entities ) {
  test_generic_change($entity->{NAME}, &{$entity->{FORM}}());
}
foreach my $entity ( @entities ) {
  test_generic_del($entity->{NAME}, &{$entity->{FORM}}());
}

test_cablecat_wells_cable();
test_cablecat_connecters_links();
test_cablecat_cables_to_struct();

#**********************************************************
=head2 test_cablecat_wells_cable()

=cut
#**********************************************************
sub test_cablecat_wells_cable {
  # Test cable can link two wells : tests + 7
  my $test_cable_id = test_generic_add('cable', $test_cable->());
  my $first_well_id = test_generic_add('well', $test_well->());
  my $second_well_id = test_generic_add('well', $test_well->());
  ok($Cablecat->set_cable_well_link( $test_cable_id, $first_well_id, $second_well_id ), 'Cable can link two wells');
  
  # Cable can't link more than 2 wells : tests + 3
  my $third_well_id = test_generic_add('well', $test_well->());
  ok(!$Cablecat->set_cable_well_link( $test_cable_id, $first_well_id, $third_well_id ),
    'Cable can\'t link more than 2 wells');
  
  # Inserting well creates 2 new cables : tests + 2
  my ($new_cable_id_1, $new_cable_id_2) = $Cablecat->break_cable( $test_cable_id, $third_well_id );
  ok($new_cable_id_1 && $new_cable_id_2, 'Inserting well breaks cable in two cables');
  
  # Check broken cable was deleted
  my $old_cable_info = $Cablecat->cables_info( $test_cable_id );
  ok( ref $old_cable_info eq 'HASH' && scalar keys %{ $old_cable_info } == 0, 'Inserted cable was deleted ');
}

#**********************************************************
=head2 test_cablecat_connecters_links()

=cut
#**********************************************************
sub test_cablecat_connecters_links {
  
  # Test cable can link two muffs : tests + 5
  my $muff1_id = test_generic_add('connecter', $test_connecter->());
  my $muff2_id = test_generic_add('connecter', $test_connecter->());
  my $added_link_id = $Cablecat->connecters_links_add( { CONNECTER_1 => $muff1_id, CONNECTER_2 => $muff2_id } );
  
  # tests + 1
  ok(!$Cablecat->{errno} && $added_link_id, 'Adding connecters link');
  
  # tests + 1
  test_generic_change('connecter', $test_connecter->());
  
  # tests + 2
  test_generic_del('connecter');
}

#**********************************************************
=head2 test_cablecat_cables_to_struct()

=cut
#**********************************************************
sub test_cablecat_cables_to_struct {
  my $cables = $Cablecat->cables_list({ROWS => 1, MODULES_COUNT => '!'});
  my $cable = $cables->[0];
  
  my $struct = _cablecat_commutation_cables_prepare_json($cable->{id});
    
  ok($struct->{id} && $struct->{id} eq $cable->{id}, 'Converted cable can be read and has same id');
}

#**********************************************************
=head2 test_generic_add($func_name, $form)

  Returns inserted ID

=cut
#**********************************************************
sub test_generic_add {
  my ($entity_name, $form) = @_;
  test_webinterface_func_call($entity_name, 'add', $form);
  
  ok((!$Cablecat->{errno} && $Cablecat->{INSERT_ID}), $entity_name . ' add');
  
  if ( exists $added_ids{$entity_name} ) {
    $added_ids{$entity_name} = [ $Cablecat->{INSERT_ID} ];
  }
  else {
    push @{$added_ids{$entity_name}}, $Cablecat->{INSERT_ID};
  }
  
  # Test it was really added
  my $info_func = $entity_name . 's_info';
  
  my $info = $Cablecat->$info_func( $Cablecat->{INSERT_ID} );
  ok (defined $info && $info && scalar keys %{$info} > 0, $entity_name . ' has been actually added');
  
  return $Cablecat->{INSERT_ID};
}

#**********************************************************
=head2 test_generic_change()

=cut
#**********************************************************
sub test_generic_change {
  my ($entity_name, $form) = @_;
  
  my $object_data = $form;
  
  if ( exists $object_data->{NAME} ) {
    $object_data->{NAME} .= '_CHANGED';
  }
  elsif ( exists $object_data->{PARENT_ID} ) {
    $object_data->{PARENT_ID} = ($object_data->{PARENT_ID} == 1) ? 2 : 1;
  }
  else {
    # Changing random entity value
    my @keys = keys %{ $object_data };
    my $rand_key;
    for (0..$#keys){
      if (defined $object_data->{ $keys[$_]}){
        $rand_key = $keys[$_];
      }
    }
    
    my $val = $object_data->{ $rand_key };
    if ( $val =~ /\d+/ ) {
      $object_data->{$rand_key}++;
    }
    elsif ( $val =~ /\w+/ ) {
      $object_data->{$rand_key} .= "_CHANGED";
    }
  }
  
  $object_data->{ID} = $added_ids{$entity_name}->[0];
  
  test_webinterface_func_call($entity_name, 'change', $form);
  
  ok((!$Cablecat->{errno}), $entity_name . ' change');
}

#**********************************************************
=head2 test_generic_del($func_name)

=cut
#**********************************************************
sub test_generic_del {
  my ($entity_name) = @_;
  
  map { test_webinterface_func_call($entity_name, 'del', { ID => $_ }) } @{$added_ids{$entity_name}};
  ok (!$Cablecat->{errno}, $entity_name . ' del');
  
  # Check entity was deleted
  my $info_func_name = $entity_name . 's_info';
  map {
    my $old_info = $Cablecat->$info_func_name( $_ );
    ok( ref $old_info eq 'HASH' && scalar keys %{ $old_info } == 0, "Inserted $entity_name was deleted");
  } @{$added_ids{$entity_name}};
  
}

#**********************************************************
=head2 test_webinterface_func_call($func_name, $operation_name, $form)

  Setups %FORM before calling a function,
  then disables output,
  calls a function and returns call result

=cut
#**********************************************************
sub test_webinterface_func_call {
  my ($entity_name, $operation_name, $form) = @_;
  %FORM = %{$form};
  $FORM{$operation_name} = $form->{ID} || 1;
  
  my $func_name = 'cablecat_' . $entity_name . 's';
  
  if ( !defined &{$func_name} ) {
    carp "$func_name is not defined";
    return undef;
  }
  
  select $null_fh;
  my $result = &{ \&{$func_name} }();
  select STDOUT;
  return $result;
}

1;