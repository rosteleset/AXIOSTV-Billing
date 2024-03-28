#!/usr/bin/perl
use strict;
use warnings;
use Crypt::OpenSSL::Random;
use CGI;
my $c;
$c = CGI->new();

my $data = Crypt::OpenSSL::Random::random_pseudo_bytes(1048576);
my $chunks;

  print "Content-Type: text/html\n\n";

# Deliver chunks of 1048576 bytes
  if ($c->param('ckSize')) {   #$c->param('ckSize')
    $chunks = $c->param('ckSize');
  }
  else{
    $chunks = 4;
  }

  if ($chunks == 0) {
    $chunks = 4;
  }
  if ($chunks>1024) {
    $chunks = 1024;
  }
  for(my $i=0; $i < $chunks; $i++){
    print $data;
  }
  #
  # print $data;
1;
