#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use lib '../../';
use lib '../../lib/';

use AXbills::Base qw(parse_arguments);

my $base_dir = '/usr/axbills/';

my $argv = parse_arguments(\@ARGV);

get_docs();

#**********************************************************
=head2 get_docs() - parse swagger code

   Arguments:

  Return:
   generate yaml file

=cut
#**********************************************************
sub get_docs {
  my $base_swagger = q{};

  if ($argv->{admin}) {
    $base_swagger = _read_swagger('misc/api/admin.yaml');
  }
  else {
    $base_swagger = _read_swagger('misc/api/user.yaml');
  }

  my $swagger = _parse_swagger({
    swagger  => $base_swagger,
    spaces   => '',
    root_dir => '',
  });

  if ($argv->{admin}) {
    _write_swagger('misc/api/bundle_admin.yaml', $swagger);
  }
  else {
    _write_swagger('misc/api/bundle_user.yaml', $swagger);
  }

  print "OK\n";
}

#**********************************************************
=head2 _parse_swagger() - parse swagger code

   Arguments:
    swagger   - base swagger code
    spaces    - number of spaces before string
    root_dir  - flag for first call

  Return:
   parsed swagger yaml string

=cut
#**********************************************************
sub _parse_swagger {
  my ($attr) = @_;

  my $swagger = $attr->{swagger};
  my @matches = $swagger =~ /^\s+\-?\s?\$ref: "\.\.?.+/gm;

  foreach my $match (@matches) {
    my ($_spaces) = $match =~ /^\s+/g;
    my $root_dir = $attr->{root_dir} || '';
    $match =~ s/^\s+//g;
    my ($path) = $match =~ /(?:(?<=\.\.)|(?<=\.))\/(.*)(?=\")/gm;

    if (!$attr->{root_dir}) {
      my @params = split('/', $path);
      $root_dir = "$params[0]/$params[1]"
    }
    else {
      $path = "$root_dir/$path"
    }

    my $new_swagger = _read_swagger("misc/api/$path");

    my $parsed_swagger = _parse_swagger({
      spaces   => $_spaces,
      swagger  => $new_swagger,
      root_dir => $root_dir
    });

    $match = quotemeta($match);
    $swagger =~ s/(?:(?<=\n)|(?<=\r\n))\s+$match/$parsed_swagger/gm;
  }

  if ($attr->{spaces}) {
    my (@raws) = $swagger =~ /.*\r?\n?/gm;
    my $new_swagger = q{};
    foreach my $raw (@raws) {
      next if (!$raw);
      $new_swagger .= "$attr->{spaces}$raw";
    }

    return $new_swagger;
  }
  else {
    return $swagger;
  }
}

#**********************************************************
=head2 _read_swagger() - read swagger file from misc swagger yaml file

  Arguments:
    path - path of file of yaml swagger specification

  Return:
   return ADMIN or USER REST API

=cut
#**********************************************************
sub _read_swagger {
  my ($path) = @_;
  my $content = '';

  open(my $fh, '<', $base_dir . $path) or die "Can't open '$base_dir$path': $!";
  while (<$fh>) {
    $content .= $_;
  }
  close($fh);

  return $content;
}

#**********************************************************
=head2 _write_swagger() - write new file of swagger

  Arguments:
    path - path of file of yaml swagger specification

=cut
#**********************************************************
sub _write_swagger {
  my ($path, $swagger) = @_;

  open(my $fh, '>', $base_dir . $path) or die "Can't open '$base_dir$path': $!";
  print $fh $swagger;
  close($fh);
}

1;
