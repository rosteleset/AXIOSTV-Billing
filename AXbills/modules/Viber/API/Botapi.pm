package Botapi;
=head NAME

  Viber Bot API

=head DOCUMENTATION

  ALL API
    https://developers.viber.com/docs/api/
  REST Bot API
    https://developers.viber.com/docs/api/rest-bot-api/

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Fetcher qw(web_request);

#**********************************************************
=head2 new($class, $token, $receiver)

    Arguments:
    $class    -
    $token    - Viber bot token
    $receiver - Receiver of message

  Returns:
    object

=cut
#**********************************************************
sub new {
  my ($class, $token, $receiver, $SELF_URL) = @_;

  $receiver //= "";

  my $self = {
    token    => $token,
    receiver => $receiver,
    SELF_URL => $SELF_URL,
    api_url  => 'https://chatapi.viber.com/pa/'
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 send_message() send message to Viber

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  $attr->{receiver} ||= $self->{receiver};
  $attr->{min_api_version} = 7;

  my $url = $self->{api_url} . 'send_message';
  my @headers = ('Content-Type: application/json', "X-Viber-Auth-Token: $self->{token}");

  web_request($url, {
    HEADERS   => \@headers,
    JSON_BODY => $attr,
    METHOD    => 'POST',
  });

  return 1;
}

#**********************************************************
=head2 get_file($file_id)

=cut
#**********************************************************
sub get_file {
  shift;
  my ($file_id) = @_;

  my ($file_path, $file_name, $file_size) = $file_id =~ /(.*)\|(.*)\|(.*)/;
  my $file_content = web_request($file_path, {
    CURL         => 1,
    CURL_OPTIONS => '-s',
  });

  return ($file_name, $file_size, $file_content);
}

#**********************************************************
=head2 fetch_api($attr)

=cut
#**********************************************************
sub fetch_api {
  my $self = shift;
  my ($attr) = @_;

  my @req_headers = ('Content-Type: application/json', 'USERBOT: VIBER', "USERID: $self->{receiver}");
  my $req_body = q{};

  if ($attr->{method} ne 'GET') {
    $req_body = $attr->{body};
  }

  my $result = web_request($attr->{url}, {
    HEADERS     => \@req_headers,
    JSON_BODY   => $req_body,
    JSON_RETURN => 1,
    INSECURE    => 1,
    METHOD      => $attr->{method}
  });

  return $result;
}

1;
