package AXbills::Auth::Google;

=head1 NAME

  Google OAuth module

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(urlencode mk_unique_value show_hash json_former in_array);
use AXbills::Fetcher qw(web_request);

my $auth_endpoint_url   = 'https://accounts.google.com/o/oauth2/v2/auth';
my $access_token_url    = 'https://www.googleapis.com/oauth2/v4/token';
my $get_me_url          = 'https://www.googleapis.com/userinfo/v2/me';
my $get_public_info_url = 'https://people.googleapis.com/v1/people/';
my $validate_token_url  = 'https://oauth2.googleapis.com/tokeninfo';

#**********************************************************
=head2 check_access($attr)

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr) = @_;

  my $client_id    = $self->{conf}->{AUTH_GOOGLE_ID} || q{};
  my $redirect_uri = $self->{conf}->{AUTH_GOOGLE_URL} || q{};

  $redirect_uri =~ s/\%SELF_URL\%/$self->{self_url}/g;
  $self->{debug} = $self->{conf}->{AUTH_GOOGLE_DEBUG} || 0;

  my $redirect_encoded = urlencode($redirect_uri);

  print "Content-Type: text/html\n\n" if ($self->{debug});

  if ($attr->{API} && $attr->{token}) {
    $self->validate_token({ TOKEN => $attr->{token} });
  }
  elsif (!exists $attr->{code}) {
    my %session_state = (
      session_state => mk_unique_value(10),
    );

    $session_state{referrer} = $attr->{REFERRER} if ($attr->{REFERRER});
    my $session_state = urlencode(json_former(\%session_state));

    $self->{auth_url} = join('', "$auth_endpoint_url?",
      "&response_type=code",
      "&client_id=$client_id",
      "&redirect_uri=$redirect_encoded",
      "&scope=profile%20email",
      "&access_type=offline",
      "&state=$session_state",
    );

    return $self;
  }
  else {
    my $token = $self->get_token($attr->{code});

    if ($token && $token->{access_token}) {
      $self->validate_token({ TOKEN => $token->{access_token} });
    }
    else {
      print "Content-Type: text/html\n\n";
      print "<code>Error getting token</code><br>";
    }
  }

  return $self;
}

#**********************************************************
=head2  get_token() - Get token

=cut
#**********************************************************
sub get_token {
  my $self = shift;
  my ($code) = @_;

  my $token = '';

  my $client_id     = $self->{conf}->{AUTH_GOOGLE_ID} || q{};
  my $client_secret = $self->{conf}->{AUTH_GOOGLE_SECRET} || q{};
  my $redirect_uri  = $self->{conf}->{AUTH_GOOGLE_URL} || q{};

  $redirect_uri =~ s/\%SELF_URL\%/$self->{self_url}/g;
  my $redirect_encoded = urlencode($redirect_uri);

  my $post_params = join('',
    "code=$code",
    "&client_id=$client_id",
    "&client_secret=$client_secret",
    "&redirect_uri=$redirect_encoded",
    '&grant_type=authorization_code'
  );

  my $result = web_request($access_token_url, {
    POST        => $post_params,
    HEADERS     => [ 'Content-Type: application/x-www-form-urlencoded' ],
    JSON_RETURN => 1,
    DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
  });

  return $result if ($result->{access_token});

  if ($result->{error}) {
    print "Error getting token: $result->{error} <br/>" if ($self->{debug});

    $token = undef;
  }

  return $token;
}

#**********************************************************
=head2 get_info($attr)

  Unless OAuth token specified will show public available info from Google+;

  Arguments:
  CLIENT_ID|TOKEN - Google services ID or OAuth 2.0 Token

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub get_info {
  my $self = shift;
  my ($attr) = @_;

  my $token     = $attr->{TOKEN};
  my $client_id = $attr->{CLIENT_ID};
  my $api_key    = $self->{conf}->{GOOGLE_API_KEY};

  $self->{debug} = $self->{conf}->{AUTH_GOOGLE_DEBUG} || 0;

  return { "Error", 'Undefined $conf{GOOGLE_API_KEY}' } unless (defined($api_key));

  my $result = '';
  my $url    = '';

  my %hash_params = (
    JSON_RETURN => 1,
    JSON_UTF8   => 1,
    DEBUG       => ($self->{debug} && $self->{debug} > 2) ? 2 : 0,
    DEBUG2FILE  => ($self->{debug} && $self->{debug} > 4) ? '/tmp/axbills_google_auth.log' : 0,
  );

  if (!defined($token)) {
    $url = $get_public_info_url . $client_id . "?personFields=photos,names,emailAddresses&key=$api_key";
    $hash_params{GET} = 1;
  }
  else {
    my $token_type    = $token->{token_type} || '';
    my $access_token  = $token->{access_token} || '';

    $url = $get_me_url;
    $hash_params{HEADERS} = [ "Authorization: $token_type $access_token" ];
  };

  $result = web_request($url, {
    %hash_params
  });

  return 0 unless $result;

  if ($result->{error}) {
    show_hash($result->{error});

    $self->{errno}  = $result->{error}->{code};
    $self->{errstr} = $result->{error}->{message};
  }

  $self->{result} = $result;

  return $result;
}

#**********************************************************
=head2 validate_token($attr)

  Check is OAUTH token is valid

  Arguments:
  TOKEN - Google services ID or OAuth 2.0 Token

  Returns:
    result_from_google

=cut
#**********************************************************
sub validate_token {
  my $self = shift;
  my ($attr) = @_;

  # validate user access token is belongs to us
  my $token = $attr->{TOKEN};
  my $url   = "$validate_token_url?access_token=" . ($token || q{});
  my $validation_result = web_request($url, {
    GET         => 1,
    JSON_RETURN => 1,
    JSON_UTF8   => 1,
  });

  return 0 unless $validation_result;

  # Accept tokens from few services
  my $ids = $self->{conf}->{AUTH_GOOGLE_IDS} || $self->{conf}->{AUTH_GOOGLE_ID} || '';
  my @ids = split(',\s?', $ids);

  if ($validation_result->{error} || $validation_result->{errno}) {
    if ($validation_result->{error}) {
      $self->{errno}  = $validation_result->{error};
      $self->{errstr} = $validation_result->{error_description};
    }
    else {
      $self->{errno}  = $self->{errno};
      $self->{errstr} = 'Unknown error';
    }
  }
  elsif (!$validation_result->{aud} || !in_array($validation_result->{aud}, \@ids)) {
    $self->{errno}  = 903;
    $self->{errstr} = 'Unknown token';
  }

  return if ($self->{errno});

  my $me_url   = "$get_me_url?access_token=" . ($token || q{});

  # get user info with user token
  my $result = web_request($me_url, {
    GET         => 1,
    JSON_RETURN => 1,
    JSON_UTF8   => 1,
  });

  if ($result->{error} || $result->{errno}) {
    if ($result->{error}) {
      $self->{errno}  = $result->{error};
      $self->{errstr} = $result->{error_description};
    }
    else {
      $self->{errno}  = $self->{errno};
      $self->{errstr} = 'Unknown error';
    }
  }
  else {
    # no error return user google id for look for
    $self->{USER_ID}     = 'google, ' . $result->{id};
    $self->{USER_NAME}   = $result->{name} || '';
    $self->{CHECK_FIELD} = '_GOOGLE';
    $self->{USER_EMAIL}  = $result->{email} || '';
  }

  return $result;
}

1;
