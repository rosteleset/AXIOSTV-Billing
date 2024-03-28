#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use v5.16;

my $dir_path;
my $axbills_base_path;

BEGIN {
  use FindBin '$Bin';
  $dir_path = $Bin . '/';
  
  ($axbills_base_path) = $Bin =~ /(.*\/)cgi-bin\//;
  
}

die qq{No base path} if (!$axbills_base_path);
use lib $axbills_base_path . 'lib';
use AXbills::Fetcher qw/web_request/;

open(my $font_list_fh, '<', $dir_path . '/fonts.txt') or die $!;

while (my $line = <$font_list_fh>){
  chomp $line;
  my ($name, $url) = split (' ', $line, 2);
  print "Downloading $name '$url'";
  download_file($name, $url);
}


sub download_file {
  my ($name, $url) = @_;
  
  #Download font
  my $result = web_request($url, {
      GET    => 1,
      RETURN => 1
    });
  
  say qq{Can't load $name  $url} if (!$result);
  
  open (my $fh, '>', $dir_path . $name . '.woff2' ) or die qq{Can't open file $name $!};
  
  print ' ' . length ($result) . "\n";
  # Save result
  print $fh $result;
  
  close $fh;
  
  return 1;
};


exit 1;


