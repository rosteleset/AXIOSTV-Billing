package AXbills::Sender::Viber_bot;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AXbills::Fetcher qw/web_request/;
use parent 'AXbills::Sender::Plugin';
use AXbills::Base qw(_bp);
use JSON;

our $VERSION = 0.02;
my %conf = ();

#**********************************************************
=head2 new($db, $admin, $CONF, $attr) - Create new Viber object

  Arguments:
    $attr
      CONF

  Returns:

  Examples:
    my $Telegram = AXbills::Sender::Viber_bot->new($db, $admin, \%conf);

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf) = @_ or return 0;

  %conf = %{$conf};

  my $self = {
    token   => $conf{VIBER_TOKEN},
    name    => $conf{VIBER_BOT_NAME},
    api_url => 'https://chatapi.viber.com/pa/'
  };
  die 'No Viber token ($conf{VIBER_TOKEN})' if (!$self->{token});

  bless $self, $class;

  return $self;
}


#**********************************************************
=head2 send_message() - Send message to user with his user_id or to channel with username(@<CHANNELNAME>)

  Arguments:
    $attr:
      TO_ADDRESS - Telegram ID
      MESSAGE    - text of the message
      PARSE_MODE - parse mode of the message. u can use 'markdown' or 'html'
      DEBUG      - debug mode

  Returns:

  Examples:
    $Telegram->send_message({
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

  my $text = $attr->{MESSAGE} || return 0;

  $text = $attr->{SUBJECT} . "\n\n" . $text if $attr->{SUBJECT};
  $self->{api}{debug} = $attr->{DEBUG} if $attr->{DEBUG};

  $text =~ s/\r//g;
  $text =~ s/\n/\\n/g;
  $text =~ s/<b>//g;
  $text =~ s/<\/b>//g;

  $self->send_attachments($attr);

  if ($attr->{MAKE_REPLY}) {
    $text .= "\\n\\n$attr->{LANG}->{MSGS_REPLY}: ";
    $text .= make_reply($attr->{MAKE_REPLY}, $attr);
  }
  my $message = {
    receiver        => $attr->{TO_ADDRESS},
    text            => $text,
    min_api_version => 7,
    type            => 'text',
  };

  my $result = $self->send_request($message, $callback);

  if ($attr->{DEBUG} && $attr->{DEBUG} > 1) {
    _bp("Result", $result, { TO_CONSOLE => 1 });
  }

  if ($attr->{RETURN_RESULT}) {
    return $result;
  }

  return $result && $result->{status_message} eq 'ok';
}


#**********************************************************
=head2 send_request()

=cut
#**********************************************************
sub send_request {
  my $self = shift;
  my ($attr, $callback) = @_;

  my $waiter = undef;
  if (!$callback) {
    $waiter = AnyEvent->condvar;
  }

  if ($@) {
    # $Log->alert('REQUEST PARAMS ERROR : ' . $@);
    # $Log->alert('REQUEST PARAMS ERROR : ' . $attr);

    my $res = { error => $@, ok => 0, type => 'on_write' };
    (!$callback) ? $waiter->send($res) : $callback->($res);
  }

  $attr->{min_api_version} = 7;

  my $json_str = $self->perl2json($attr);

  my $url = $self->{api_url} . 'send_message';

  my @header = ('Content-Type: application/json', 'X-Viber-Auth-Token: ' . $self->{token});
  $json_str =~ s/\"/\\\"/g;

  my $result = web_request($url, {
    POST         => $json_str,
    HEADERS      => \@header,
    CURL         => 1,
    CURL_OPTIONS => '-XPOST',
  });

  $result = decode_json($result);

  (!$callback) ? $waiter->send($result) : $callback->($result);

  return $result;
}

#**********************************************************
=head2 perl2json()

=cut
#**********************************************************
sub perl2json {
  my $self = shift;
  my ($data) = @_;
  my @json_arr = ();

  if (ref $data eq 'ARRAY') {
    foreach my $key (@{$data}) {
      push @json_arr, $self->perl2json($key);
    }
    return '[' . join(',', @json_arr) . "]";
  }
  elsif (ref $data eq 'HASH') {
    foreach my $key (sort keys %$data) {
      my $val = $self->perl2json($data->{$key});
      push @json_arr, qq{\"$key\":$val};
    }
    return '{' . join(',', @json_arr) . "}";
  }
  else {
    $data //= '';
    return "true" if ($data eq "true");
    return qq{\"$data\"};
  }
}

#**********************************************************
=head2 make_reply() - return reply url

  Returns:
    string - reply url

=cut
#**********************************************************
sub make_reply() {
  my ($message_id, $sender_attr) = @_;

  my $referer = (
    # Allow users to use their own portal URL
    ($sender_attr->{UID} ? $conf{CLIENT_INTERFACE_URL} : '')
      || $conf{BILLING_URL}
      || $ENV{HTTP_REFERER}
      || ''
  );

  if ($referer =~ /(https?:\/\/[a-zA-Z0-9:\.\-]+)\/?/g) {
    my $site_url = $1;

    if ($site_url) {
      my $link = $site_url;

      if ($sender_attr->{UID}) {
        $link .= "/index.cgi?get_index=msgs_user&ID=$message_id#last_msg";
      }
      elsif ($sender_attr->{AID}) {
        my $receiver_uid = $sender_attr->{SENDER_UID} ? '&UID=' . $sender_attr->{SENDER_UID} : '';
        $link .= "/admin/index.cgi?get_index=msgs_admin&full=1$receiver_uid&chg=$message_id#last_msg";
      }
      return $link;
    }

  }
  return "";
}

#**********************************************************
=head2 send_attachments() - send message with attachments

=cut
#**********************************************************
sub send_attachments {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{ATTACHMENTS} || ref $attr->{ATTACHMENTS} ne 'ARRAY';

  my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}/images" : '';

  foreach my $file (@{$attr->{ATTACHMENTS}}) {
    my $content = $file->{content} || '';
    next if $content !~ /FILE/ || $content !~ /AXbills\/templates/;
    
    my $content_type = $file->{'content_type'} || '';
    my $type = $content_type =~ /image/ ? 'picture' :
      $content_type =~ /video/ ? 'video' : 'file';

    my ($file_path) = $content =~ /AXbills\/templates(\/.+)/;

    my $message = {
      receiver        => $attr->{TO_ADDRESS},
      type            => $type,
      min_api_version => 7,
      media           => $SELF_URL . $file_path
    };

    $message->{size} = $file->{content_size} if $type ne 'picture';
    $message->{text} = $file->{filename} || '' if $type eq 'picture';

    $self->send_request($message);
  }
}

1;