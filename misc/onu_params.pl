#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Test::Simple tests => 2;

my %type_name = (
  1 => 'epon_olt_virtualIfBER',
  3 => 'epon-onu',
  6 => 'type6'
);

my $test_value1 = 811089920;
my $test_answer1 = 'epon-onu_0/11/1:64';

my $test_value2 = 807077120;
my $test_answer2 = 'epon-onu_0/3/4:5';

ok( decode_onu( $test_value1 ) eq $test_answer1,
  "'" . $test_answer1 . "\' decodes as \'" . decode_onu( $test_value1 ) . "'" );
ok( decode_onu( $test_value2 ) eq $test_answer2,
  "'" . $test_answer2 . "\' decodes as \'" . decode_onu( $test_value2 ) . "'" );


use Data::Dumper;

sub decode_onu {
  my ($dec) = @_;
  my %result = ();
  my $bin = sprintf( "%032b", $dec );

  my ($bin_type) = $bin =~ /^(\d{4})/;
  my $type = oct( "0b$bin_type" );

  if ( $type == 3 ) {
    @result{'type', 'shelf', 'slot', 'olt',
      'onu'} = map { oct( "0b$_" ) } $bin =~ /^(\d{4})(\d{4})(\d{5})(\d{3})(\d{8})(\d{8})/;
    return $type_name{$result{type}}
      . '_' . $result{shelf}
      . '/' . $result{slot}
      . '/' . ($result{olt} + 1)
      . ':' . $result{onu};
  }
  elsif ( $type == 1 ) {
    @result{'type', 'shelf', 'slot', 'olt'} = map { oct( "0b$_" ) } $bin =~ /^(\d{4})(\d{4})(\d{8})(\d{8})(\d{8})/;
    return $type_name{$result{type}}
      . '_' . $result{shelf}
      . '/' . $result{slot}
      . '/' . ($result{olt} + 1);
  }
  elsif ( $type == 6 ) {
    @result{'type', 'shelf', 'slot'} = map { oct( "0b$_" ) } $bin =~ /^(\d{4})(\d{4})(\d{8})/;
    return $type_name{$result{type}}
      . '_' . $result{shelf}
      . '/' . $result{slot};
  }


  return 0;
}

decode_onu( $test_value1 );
decode_onu( $test_value2 );
decode_onu( '268634112' );

print "\n";
