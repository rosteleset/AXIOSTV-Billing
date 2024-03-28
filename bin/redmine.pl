#!/usr/bin/perl
#    restget : GET a representation of a REST resource
use strict;
use warnings;
use Getopt::Std;
use LWP::UserAgent;
use JSON;
use open ':locale';    # probe the locale environment variables like LANG

sub HELP_MESSAGE {
    print STDERR <<"EOM";
usage : $0 [-p] [-k API_KEY] url
        -p: pretty print
        -k API_KEY: API Access Key
EOM
    exit 0;
}
our ($opt_k);
getopts('pk:') or HELP_MESSAGE();
my $url = shift;
HELP_MESSAGE() unless $url;
#################################################
my $ua = LWP::UserAgent->new();
$ua->timeout(10);    # default: 180sec
$ua->default_header('X-Redmine-API-Key' => $opt_k) if $opt_k;

my $res = $ua->get($url);
print $url;
die $res->message if $res->is_error;
my $content =  $res->content;
print $content;
# utf8::decode($content);

exit 0;