=head1 NAME

  Documentation helper for get link for documentation in console

=head1 ARGUMENTS

  WORD - word which you want to find in Confluence
  HELP - read how to use

=cut
use strict;
no warnings 'layer';

BEGIN {
  our $libpath = '../';
  unshift(@INC,
    $libpath . '/lib/',
    $libpath
  );
}

use AXbills::Base qw(parse_arguments);
use JSON qw(decode_json);
use HTTP::Request::Common;
use LWP::Simple;

my $argv = parse_arguments(\@ARGV);

if ($argv->{help} || $argv->{HELP}) {
  print "To do a documentation search write: 'Internet'\n";
  print "To do search through documentation pages: 'Internet on page'\n";
}
elsif (!$argv->{WORD}) {
  print "No param WORD please try again with it\n\n";
}
else {
  my $doc_url = q{};
  if ($argv->{WORD} =~ /on\s+page/) {
    $argv->{WORD} .= ' ';
    $argv->{WORD} =~ s/\s+on\s+page\s+//g;
    $doc_url = "http://axbills.net.ua/wiki/rest/api/content/search?limit=500&cql=text~'$argv->{WORD}'";
  }
  else {
    $doc_url = "http://axbills.net.ua/wiki/rest/api/content/search?limit=500&cql=title~'$argv->{WORD}'";
  }

  my $Ua = LWP::UserAgent->new(
    ssl_opts => {
      verify_hostname => 0,
      SSL_verify_mode => 0
    },
  );
  my $get_request = HTTP::Request->new('GET', $doc_url);

  my $response = $Ua->request($get_request);
  $response = decode_json($response->{_content});

  my $count = 0;
  my $text = q{};
  foreach my $result (@{$response->{results}}) {
    next if ($result->{type} ne 'page');
    $count++;
    my $link = $result->{_links}->{webui};
    $text .= "$result->{title} URL: http://axbills.net.ua:/wiki$link\n"
  }
  print "Found $count matches with $argv->{WORD}\n$text";
}

1;