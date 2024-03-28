#!/usr/bin/perl

#*******************************************
use warnings;
use strict;
use Data::Dumper;

my %hash;
my %file;

find_files("/usr/axbills");

foreach my $key (keys %hash) {
  if($hash{$key}>1){
    print "$file{$key} $key\n";
  } 
}

sub find_files {

  my ($base_dir) = @_;
  my $path;

  opendir(my $dh, $base_dir) or die "Can't opendir $base_dir: $!";

  while (my $fname = readdir $dh) {


    next if (($fname eq '.') || ($fname eq '..'));

    if (-d "$base_dir/$fname") { 
      find_files("$base_dir/$fname");
    }

    if (-f "$base_dir/$fname" && ($fname eq "lng_english.pl" || $fname eq "english.pl") ) {
      parse_file($base_dir, $fname); 
    }

  }
  closedir $dh;
}


sub parse_file {

  my ($base_dir, $fname) = @_;
  my $lang;

  open(my $fh, '<', "$base_dir/$fname")
    or die "Can't open < $base_dir/$fname: $!";

  while (my $line = <$fh>) {

    if ($line =~ /^\$lang\{.*\}/) {
      my ($lang) = $line =~ /\$lang\{(.*)\}/; 
      $hash{$lang}++;
      my ($module) = $base_dir =~ /.*\/(.*)/;
      $file{$lang}.= $module;
    }
  }
  close $fh;

}
