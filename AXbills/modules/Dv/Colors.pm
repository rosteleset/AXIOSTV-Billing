package Dv::Colors;
use strict;
use warnings 'FATAL' => 'all';

=head2 NAME
  
  Dv::Colors
  
=head2 SYNOPSYS

  This functions was splitted from Dv\webinterface because are used only on client page
  
=cut


#**********************************************************
=head2 color_hex_to_rgb($hex_color_string)

 Returns:
   arr ref of RGB

=cut
#**********************************************************
sub color_hex_to_rgb {
  my ($hex_color_string) = @_;
  
  return [] unless ($hex_color_string);
  
  my @symbols = split('', lc $hex_color_string);
  return [] unless ($symbols[0] eq '#');
  
  # Speed hack
  my %digits = (
    0 => 0,
    1 => 1,
    2 => 2,
    3 => 3,
    4 => 4,
    5 => 5,
    6 => 6,
    7 => 7,
    8 => 8,
    9 => 9,
    a => 10,
    b => 11,
    c => 12,
    d => 13,
    e => 14,
    f => 15
  );
  
  my @decimals = ();
  for (my $i = 1; $i < scalar @symbols; $i+=2){
    my $res = 0;
    $res = ($symbols[$i]) ? $digits{$symbols[$i]} * 16 : 0;
    $res += ($symbols[$i+1]) ? $digits{$symbols[$i+1]} : 0;
    
    push (@decimals, $res);
  }
  
  return \@decimals;
}

#**********************************************************
=head2 rgb_to_hex($rgb_ref) - get hex string from RGB

=cut
#**********************************************************
sub rgb_to_hex {
  my ($rgb_ref) = @_;
  # Speed hack
  my @hex = qw/ 0 1 2 3 4 5 6 7 8 9 a b c d e f /;
  
  my $hex_string = '#';
  
  foreach my $color (@$rgb_ref){
    my $low = $color % 16;
    my $high = ($color - $low) / 16;
    
    $hex_string .= "$hex[$high]" . "$hex[$low]";
  }
  
  return $hex_string;
}

#**********************************************************
=head2 darken_hex($hex_color_string, $increment_by) - darkens given color

  $hex_color_string : #a825c9  #color
  $increment_by     : coeff to change brightness

  Returns:
    #color or array (r, g, b)

=cut
#**********************************************************
sub darken_hex {
  my ($hex_color_string, $increment_by) = @_;
  
  $hex_color_string =~ s/[#]//g;                                # remove # symbol
  my @rgb = map $_, unpack 'C*', pack 'H*', $hex_color_string;  # make array
  my @hls = rgb2hls(@rgb);                                     # convert to HLS
  $hls[1] *= $increment_by;                                     # modify luninosity
  if ($hls[1] > 1) { $hls[1] = 1; }                             # luninosity [0..1]
  return rgb_to_hex2(hls2rgb(@hls));                                  # convert to RGB & out
}

#**********************************************************
=head2 rgb2hls($r, $g, $b)

  $r, $g, $b : 0..255
  Note special name '$bb' to avoid conflict
  with ($a,$b) in sort()

=cut
#**********************************************************
sub rgb2hls {
  my ( $r, $g, $bb ) = map { $_/255.0 } @_;         # Scale RGB to 0..1
  my ( $minc, $maxc ) = ( sort { $a <=> $b } ( $r, $g, $bb ) )[0,2];
  
  my $m = $minc + $maxc;                            # "Mean"
  if( $maxc == $minc ) { return ( 0, 0.5*$m, 0 ); } # Achromatic case
  my $d = $maxc - $minc;                            # "Delta"
  my $s = ( $m <= 1.0 ) ? $d/$m : $d/(2.0-$m );     # Saturation
  my $h = 0;                                        # Hue
  if(    $r  == $maxc ) { $h =     ( $g-$bb )/$d; }
  elsif( $g  == $maxc ) { $h = 2 + ( $bb-$r )/$d; }
  elsif( $bb == $maxc ) { $h = 4 + ( $r-$g )/$d; }
  else {    }                                       # Never get here!
  
  $h *= 60;                                         # Convert to degrees
  if( $h < 0 ) { $h += 360; }                       # Ensure positive hue
  return ( $h, 0.5*$m, $s );
}

#**********************************************************
=head2 hls2rgb( $h, $l, $s )

  $h     : 0..360 degrees
  $l, $s : 0..1   (inclusive)

=cut
#**********************************************************
sub hls2rgb {
  my ( $h, $l, $s ) = @_;
  if( $s == 0.0 ) {
    return rgb_to_hex2(255*$l, 255*$l, 255*$l); # achromatic (grey)
  }
  my $m2 = ( $l <= 0.5 ) ? ($l*(1+$s)) : ($l - $l*$s + $s);
  my $m1 = 2.0*$l - $m2;
  my $r = 255 * _value( $m1, $m2, $h + 120 );
  my $g = 255 * _value( $m1, $m2, $h );
  my $blue = 255 * _value( $m1, $m2, $h - 120 );
  return rgb_to_hex2( $r, $g, $blue );
}

#**********************************************************
=head2 _value($n1, $n2, $hue) - helper function for _hls2rgb()

=cut
#**********************************************************
sub _value {
  my ( $n1, $n2, $hue ) = @_;
  if(    $hue > 360 ) { $hue -= 360; }
  elsif( $hue <   0 ) { $hue += 360; }
  if(    $hue <  60 ) { return $n1 + $hue * ( $n2-$n1 )/60.0; }
  elsif( $hue < 180 ) { return $n2; }
  elsif( $hue < 240 ) { return $n1 + ( 240-$hue ) * ( $n2-$n1 )/60.0; }
  else                { return $n1; }
}

#**********************************************************
=head2 rgb_to_hex2( $r, $g, $b )

 Takes a (r,g,b) triple of numbers (possibly floats) and returns
 - a string like '#36fe25' in scalar context
 - a triple of corresponding integers in array context

=cut
#**********************************************************
sub rgb_to_hex2 {
  return wantarray ? map { int } @_ : sprintf( "#%02x%02x%02x", @_ );
}



1;