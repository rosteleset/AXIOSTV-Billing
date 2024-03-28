#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

=head1 NAME

  facebook_unreg.cgi

=head1 SYNOPSIS

  facebook_unreg.cgi Facebook Data Deletion Request Callback
  Doc: https://developers.facebook.com/docs/development/create-an-app/app-dashboard/data-deletion-callback/

=cut

BEGIN {
  our $Bin;
  use FindBin '$Bin';
  if ($Bin =~ m/\/axbills(\/)/) {
    my $libpath = substr($Bin, 0, $-[1]);
    unshift (@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/axbills dir \n";
  }
}

use AXbills::Init qw/$db $admin %conf $users @MODULES $DATE $TIME/;
use AXbills::HTML;
use AXbills::Base qw(_bp);
use MIME::Base64;
use JSON qw/decode_json encode_json/;
use Digest::SHA qw(hmac_sha256);

print "Content-Type: application/json\n\n";


our %FORM;
%FORM = form_parse();

if($FORM{id}){
  print "Your data successfully deleted!";
  exit;
}

my $signed_request = $FORM{signed_request};
my $data = parse_signed_request($signed_request);


my $user = $users->list({
  _FACEBOOK            => '*'.$data->{user_id},
  DELETED              => 0,
  COLS_NAME            => 1
});

$user = $user->[0];
$users->pi_change({ UID => $user->{uid}, '_FACEBOOK' => '' });

my $id = int(rand(999999));
my $url = $conf{FACEBOOK_DELETE_INFO} || "";
my %resutl = (
  'url'               => $url."?id=$id",
  'confirmation_code' => $id
);

print encode_json(\%resutl);


#**********************************************************
=head2 parse_signed_request()

=cut
#**********************************************************
sub parse_signed_request{
  my $request = shift;

  my($encoded_sig, $payload) = split('\.', $request);

  my $secret = $conf{AUTH_FACEBOOK_SECRET};

  my $sig = base64_url_decode($encoded_sig);

  my $new_data =  decode_json(base64_url_decode($payload));

  my $expected_sig = hmac_sha256($payload, $secret);

  if ($sig ne $expected_sig) {
    print('Bad Signed JSON signature!');
    exit;
  }

  return $new_data;
}

#**********************************************************
=head2 base64_url_decode()

=cut
#**********************************************************
sub base64_url_decode {
  my $input = shift;

  $input = $input =~ s/-/+/rg;
  $input = $input =~ s/_/\//rg;
  return decode_base64($input);

}

1;