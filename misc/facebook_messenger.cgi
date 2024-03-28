#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

=head1 NAME

=head1 SYNOPSIS

=cut

BEGIN {
  our $Bin;
  use FindBin '$Bin';
  if ($Bin =~ m/\/axbills(\/)/) {
    my $libpath = substr($Bin, 0, $-[1]);
    unshift(@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/axbills dir \n";
  }
}

use AXbills::Init qw/$db $admin %conf $users @MODULES $DATE $TIME/;
use AXbills::HTML;
use AXbills::Base qw(_bp load_pmodule in_array);
use MIME::Base64;
use JSON qw/decode_json encode_json/;
use Digest::SHA qw(hmac_sha256);
use AXbills::Fetcher qw/web_request/;

print "Content-Type: application/json\n\n";

our %FORM;
%FORM = form_parse();
print $FORM{'hub.challenge'} if $FORM{'hub.challenge'};

_send_request();

#**********************************************************
=head2 _send_request($attr)

=cut
#**********************************************************
sub _send_request {
  my $request_url = 'https://graph.facebook.com/v15.0';

  load_pmodule('JSON');
  my $json = JSON->new->allow_nonref;
  my $perl_scalar = $json->decode($FORM{__BUFFER});

  my $sender = $perl_scalar->{entry}[0]{messaging}[0]{sender}{id};
  return if !$sender;

  my $message = $perl_scalar->{entry}[0]{messaging}[0]{message}{text};
  return if !$message;

  my $is_instagram = $perl_scalar->{object} eq 'instagram';
  my $fields = $is_instagram ? 'id,name' : 'id,name,email,picture';

  $request_url .= "/$sender?fields=$fields&access_token=$conf{FACEBOOK_ACCESS_TOKEN}";

  my $result = web_request($request_url, { CURL => 1 });

  my $json_result = $json->decode($result);
  return '' if $json_result->{error};

  if ($conf{INSTAGRAM_ADMIN_USERS} && $is_instagram) {
    my @instagram_users = split(';\s?', $conf{INSTAGRAM_ADMIN_USERS});
    return '' if in_array($json_result->{id}, \@instagram_users);
  }

  use Crm::Dialogue;
  my $Dialogue = Crm::Dialogue->new($db, $admin, \%conf, { SOURCE => $is_instagram ? 'instagram' : 'facebook' });

  my $lead_id = $Dialogue->crm_lead_by_source({
    USER_ID => $json_result->{id},
    FIO     => $json_result->{name},
    EMAIl   => $json_result->{email} || '',
    AVATAR  => $json_result->{picture}{data}{url} || '',
  });
  return '' if !$lead_id;

  my $dialogue_id = $Dialogue->crm_get_dialogue_id($lead_id);
  return '' if !$dialogue_id;

  $Dialogue->crm_send_message($message, { DIALOGUE_ID => $dialogue_id });

  return '';
}

exit();