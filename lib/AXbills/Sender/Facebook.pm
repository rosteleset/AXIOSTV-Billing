package AXbills::Sender::Facebook;
use strict;
use warnings;

use AXbills::Fetcher qw/web_request/;
use parent 'AXbills::Sender::Plugin';
use AXbills::Base qw(_bp json_former);
use JSON qw/decode_json encode_json/;

our $VERSION = 0.02;
my %conf = ();

#**********************************************************
=head2 new($db, $admin, $CONF, $attr) - Create new Facebook object

  Arguments:
    $attr
      CONF

  Returns:

  Examples:
    my $Facebook = AXbills::Sender::Facebook->new($db, $admin, \%conf);

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf) = @_ or return 0;

  %conf = %{$conf};

  my $self = {
    token   => $conf{FACEBOOK_ACCESS_TOKEN},
    api_url => 'https://graph.facebook.com/v15.0/me/messages'
  };
  die 'No Facebook access token ($conf{FACEBOOK_ACCESS_TOKEN})' if (!$self->{token});

  bless $self, $class;

  return $self;
}


#**********************************************************
=head2 send_message() - Send message to user with his user_id or to channel with username(@<CHANNELNAME>)

  Arguments:
    $attr:
      TO_ADDRESS - Facebook ID
      MESSAGE    - text of the message
      PARSE_MODE - parse mode of the message. u can use 'markdown' or 'html'
      DEBUG      - debug mode

  Returns:

  Examples:
    $Facebook->send_message({
      AID        => "235570079",
      MESSAGE    => "testing",
      PARSE_MODE => 'markdown',
      DEBUG      => 1
    });

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr, $callback) = @_;

  my $send_message = $attr->{MESSAGE} || return 0;
  $self->{debug} = $attr->{DEBUG} if $attr->{DEBUG};

  my $message = {
    recipient => { id => $attr->{TO_ADDRESS} },
    message   => { text => $send_message },
  };

  my $result = $self->send_request($message, $callback);

  if ($attr->{DEBUG} && $attr->{DEBUG} > 1) {
    _bp("Result", $result, { TO_CONSOLE => 1 });
  }

  return $result if $attr->{RETURN_RESULT};

  return $result && $result->{message_id};
}


#**********************************************************
=head2 send_request()

=cut
#**********************************************************
sub send_request {
  my $self = shift;
  my ($attr, $callback) = @_;

  my $json_str = json_former($attr);

  my $url = $self->{api_url} . '?access_token=' . $self->{token};

  my @header = ('Content-Type: application/json');
  $json_str =~ s/\"/\\\"/g;

  my $result = web_request($url, {
    POST         => $json_str,
    HEADERS      => \@header,
    CURL         => 1,
    CURL_OPTIONS => '-X POST',
  });

  $result = decode_json($result);

  return $result;
}

1;