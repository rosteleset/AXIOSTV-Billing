package AXbills::Auth::Apple;

=head1 NAME

  Apple auth module

=cut

use strict;
use warnings FATAL => 'all';

use Crypt::JWT qw(encode_jwt decode_jwt);
use Digest::SHA qw(sha256_hex);

use AXbills::Base qw(urlencode mk_unique_value json_former in_array);
use AXbills::Fetcher qw(web_request);

my $endpoint_auth = 'https://appleid.apple.com/auth/authorize';
my $endpoint_keys = 'https://appleid.apple.com/auth/keys';

#**********************************************************
=head2 check_access($attr)

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr) = @_;

  my $token = $attr->{token};

  if ($attr->{API} && $token) {
    my $result = $self->validate_token({ TOKEN => $attr->{token}, NONCE => $attr->{nonce} || '' });
    return $result;
  }
  elsif (!$attr->{code}) {
    my $redirect_uri = $self->{conf}->{AUTH_APPLE_URL} || q{};
    $redirect_uri =~ s/\%SELF_URL\%/$self->{self_url}/g;

    $redirect_uri = urlencode($redirect_uri);

    my $client_id = $self->{conf}->{AUTH_APPLE_ID} || q{};
    my $nonce = mk_unique_value(36);

    my %session_state = (
      session_state => mk_unique_value(36),
    );

    $session_state{referrer} = $attr->{REFERRER} if ($attr->{REFERRER});
    my $session_state = urlencode(json_former(\%session_state));

    $self->{auth_url} = join('', "$endpoint_auth?",
      "client_id=$client_id",
      "&redirect_uri=$redirect_uri",
      "&response_mode=form_post",
      "&response_type=id_token%20code",
      "&scope=name%20email",
      "&nonce=$nonce",
      "&state=$session_state",
    );
  }
  else {
    $self->validate_token({
      TOKEN => $attr->{id_token},
      NONCE => $attr->{nonce} || '',
    });
  }

  return $self;
}

#**********************************************************
=head2 validate_token() - check identify token

  Arguments:

  Return:

=cut
#**********************************************************
sub validate_token {
  my $self = shift;
  my ($attr) = @_;

  my $token = $attr->{TOKEN} || q{};

  my $ids = $self->{conf}->{AUTH_APPLE_IDS} ? "$self->{conf}->{AUTH_APPLE_IDS}" : '';
  $ids .= $self->{conf}->{AUTH_APPLE_ID} ? ",$self->{conf}->{AUTH_APPLE_ID}" : '';
  my @ids = split(',\s?', $ids);

  return {
    errno  => 901,
    errstr => 'Unknown token'
  } if (!$token);

  my $keys = web_request($endpoint_keys, {
    JSON_RETURN => 1
  });

  return {
    errno  => 906,
    errstr => 'Unknown token'
  } if ($keys->{errno} || $keys->{error} || !exists $keys->{keys});

  $keys = $keys->{keys};
  my $token_info;

  foreach my $key (@{$keys}) {
    $@ = undef;
    $token_info = eval {decode_jwt(token => $token, key => $key, alg => 'RS256');};
    last if (!$@);
  }

  return {
    errno  => 902,
    errstr => 'Unknown token'
  } if ($@);

  return {
    errno  => 903,
    errstr => 'Unknown token'
  } if (!$token_info->{aud} || !in_array($token_info->{aud}, \@ids));

  return {
    errno  => 904,
    errstr => 'Unknown token'
  } if ('https://appleid.apple.com' ne $token_info->{iss});

  my $nonce = sha256_hex($attr->{NONCE}) if ($attr->{NONCE});

  return {
    errno  => 905,
    errstr => 'Unknown token'
  } if ($nonce && $token_info->{nonce} && $nonce ne $token_info->{nonce});

  $self->{USER_ID}     = 'apple, ' . $token_info->{sub};
  $self->{USER_NAME}   = $token_info->{user} ?
    ($token_info->{user}->{lastName} || q{}) . ($token_info->{user}->{firstName} || q{}) : '';
  $self->{CHECK_FIELD} = '_APPLE';
  $self->{USER_EMAIL}  = $token_info->{email} || '';

  return $self;
}

1;
