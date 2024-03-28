package AXbills::Auth::Twitter;


use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(_bp mk_unique_value urlencode load_pmodule);
use AXbills::Fetcher;
use Digest::HMAC_SHA1;

my $request_token_url = 'https://api.twitter.com/oauth/request_token';
my $access_token_url  = 'https://api.twitter.com/oauth/access_token';
my $authorize_url     = 'https://api.twitter.com/oauth/authorize';
my $account_data_url  = 'https://api.twitter.com/1.1/users/show.json';

#**********************************************************
=head2 request_token() get tokens

  Arguments:
    nothing

  Returns:
    authorize url
	token

=cut
#**********************************************************
sub request_tokens {
  my ($attr) = @_;
  
  my $consumer_key = $attr->{conf}{AUTH_TWITTER_ID} || q{};
  my $consumer_secret = $attr->{conf}{AUTH_TWITTER_SECRET} || q{};
  my $callback_url = $attr->{conf}{AUTH_TWITTER_URL} || q{};
  $callback_url =~ s/\%SELF_URL\%/$attr->{self_url}/g;

  # make signature
  my $oauth_nonce = mk_unique_value(32);
  my $oauth_timestamp = time();
  my $base_text = urlencode(join('&',
    'oauth_callback=' . urlencode($callback_url),
    'oauth_consumer_key=' . $consumer_key,
    'oauth_nonce=' . $oauth_nonce,
    'oauth_signature_method=HMAC-SHA1',
    'oauth_timestamp=' . $oauth_timestamp,
    'oauth_version=1.0'
  ));
  
  my $cript_key = $consumer_secret . '&';
  my $oauth_base_text = 'GET&' . urlencode($request_token_url) . '&' . $base_text;
  
  my $hmac = Digest::HMAC_SHA1->new($cript_key);
  $hmac->add($oauth_base_text);
  my $oauth_signature = $hmac->b64digest;
  $oauth_signature .= '=' x ((4 - length($oauth_signature) % 4) % 4);
  
  # get tokens
  my $params = join('&',
    'oauth_consumer_key=' . $consumer_key,
    'oauth_nonce=' . $oauth_nonce,
    'oauth_signature=' . urlencode($oauth_signature),
    'oauth_signature_method=HMAC-SHA1',
    'oauth_timestamp=' . $oauth_timestamp,
    'oauth_version=1.0'
  );
  
  my $url = $request_token_url . '?oauth_callback=' . urlencode($callback_url) . '&' . $params;
  my $response = web_request($url);

  my @resp = split ('&', $response);
  my %resp = ();
  foreach my $pair (@resp){
    my ($key, $value) = split('=', $pair);
    $resp{$key} = $value;
  }
  my $oauth_token = $resp{oauth_token} || '';
  my $oauth_token_secret = $resp{oauth_token_secret} || '';
    
  # generate url for user auth
  my $auth_url = $authorize_url.'?oauth_token='.$oauth_token;
  return {
    url => $auth_url,
    token => $oauth_token_secret
  };
  
}
#**********************************************************
=head2 check_access($attr) - authorize via twitter function
  
  if args contains oauth_verifier, its mean user redirected after
  authorisation on twitter. In this case function get and return user info.
  
  In other cases function return authorize link.
  
=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr) = @_;
  
  my $consumer_key = $self->{conf}{AUTH_TWITTER_ID};
  my $consumer_secret = $self->{conf}{AUTH_TWITTER_SECRET};
  
  my $request_params = $self->request_tokens();

  my $oauth_token_secret = $request_params->{token};
  my $url = $request_params->{url};
  
  if (!exists $attr->{oauth_token} && !exists $attr->{oauth_verifier}) {
    $self->{auth_url} = $url;
    return $self;
  }
  else {
    # make signature
    my $oauth_nonce = mk_unique_value(32);
    my $oauth_timestamp = time();
    my $oauth_token = $attr->{oauth_token};
    my $oauth_verifier = $attr->{oauth_verifier};
    
    my $base_text = urlencode(join('&',
      'oauth_consumer_key=' . $consumer_key,
      'oauth_nonce=' . $oauth_nonce,
      'oauth_signature_method=HMAC-SHA1',
      'oauth_token=' . $oauth_token,
      'oauth_timestamp=' . $oauth_timestamp,
      'oauth_verifier=' . $oauth_verifier,
      'oauth_version=1.0'
    ));
    my $cript_key = $consumer_secret . '&' . $oauth_token_secret;
    my $oauth_base_text = 'GET&' . urlencode($access_token_url) . '&' . $base_text;
    my $hmac = Digest::HMAC_SHA1->new($cript_key);
    $hmac->add($oauth_base_text);
    my $oauth_signature = $hmac->b64digest;
    $oauth_signature .= '=' x ((4 - length($oauth_signature) % 4) % 4);
    
    # get access tokens and user's screen_name
    $url = join('&',
      $access_token_url . '?oauth_nonce=' . $oauth_nonce,
      'oauth_signature_method=HMAC-SHA1',
      'oauth_timestamp=' . $oauth_timestamp,
      'oauth_consumer_key=' . $consumer_key,
      'oauth_token=' . urlencode($oauth_token),
      'oauth_verifier=' . urlencode($oauth_verifier),
      'oauth_signature=' . urlencode($oauth_signature),
      'oauth_version=1.0'
    );
    my $response = web_request($url);
    my @resp = split ('&', $response);
    my %resp = ();
    foreach my $pair (@resp){
      my ($key, $value) = split('=', $pair);
      $resp{$key} = $value;
    }
    
    $oauth_token = $resp{oauth_token};
    $oauth_token_secret = $resp{oauth_token_secret};
    my $screen_name = $resp{screen_name};
    
    # make signature
    $oauth_nonce = mk_unique_value(32);
    $oauth_timestamp = time();
    
    $base_text = urlencode(join('&',
      'oauth_consumer_key=' . $consumer_key,
      'oauth_nonce=' . $oauth_nonce,
      'oauth_signature_method=HMAC-SHA1',
      'oauth_timestamp=' . $oauth_timestamp,
      'oauth_token=' . $oauth_token,
      'oauth_version=1.0',
      'screen_name=' . $screen_name
    ));
    $cript_key = $consumer_secret . '&' . $oauth_token_secret;
    $oauth_base_text = 'GET&' . urlencode($account_data_url) . '&' . $base_text;
    $hmac = Digest::HMAC_SHA1->new($cript_key);
    $hmac->add($oauth_base_text);
    $oauth_signature = $hmac->b64digest;
    $oauth_signature .= '=' x ((4 - length($oauth_signature) % 4) % 4);
    
    # get user info
    $url = join('&',
      $account_data_url . '?oauth_consumer_key=' . $consumer_key,
      'oauth_nonce=' . $oauth_nonce,
      'oauth_signature=' . urlencode($oauth_signature),
      'oauth_signature_method=HMAC-SHA1',
      'oauth_timestamp=' . $oauth_timestamp,
      'oauth_token=' . urlencode($oauth_token),
      'oauth_version=1.0',
      'screen_name=' . $screen_name
    );
    
    $response = web_request($url, {
        JSON_RETURN => 1,
        JSON_UTF8   => 1,
      });
    
    if ( $response->{name} ) {
      $self->{USER_ID} = 'twitter, ' . $response->{id};
      $self->{USER_NAME} = $response->{name};
      $self->{CHECK_FIELD} = '_TWITTER';
    }
    else {
      _bp('Error getting token', '', {HEADER => 1});
    }
    return $self;
    
  }
}

#**********************************************************
=head2 get_info($twitter_user_id) - get user's info from t#witter
  
  argument:
    twitter user's id
  
  returns:
    user data

=cut
#**********************************************************

sub get_info {
  my ($self, $attr) = @_;
  my $user_id = $attr->{CLIENT_ID};
  my $consumer_key = $self->{conf}{AUTH_TWITTER_ID};
  my $consumer_secret = $self->{conf}{AUTH_TWITTER_SECRET};
  
  # generate signature
  my $oauth_nonce = mk_unique_value(32);
  my $oauth_timestamp = time();
  
  my $base_text = urlencode(join('&',
    'oauth_consumer_key=' . $consumer_key,
    'oauth_nonce=' . $oauth_nonce,
    'oauth_signature_method=HMAC-SHA1',
    'oauth_timestamp=' . $oauth_timestamp,
    'oauth_version=1.0',
    'user_id=' . $user_id
  ));
  
  my $cript_key = $consumer_secret . '&';
  my $oauth_base_text = 'GET&' . urlencode($account_data_url) . '&' . $base_text;
  
  my $hmac = Digest::HMAC_SHA1->new($cript_key);
  $hmac->add($oauth_base_text);
  my $oauth_signature = $hmac->b64digest;
  $oauth_signature .= '=' x ((4 - length($oauth_signature) % 4) % 4);
  
  #get user info
  my $url = join('&',
    $account_data_url . '?oauth_consumer_key=' . $consumer_key,
    'oauth_nonce=' . $oauth_nonce,
    'oauth_signature=' . urlencode($oauth_signature),
    'oauth_signature_method=HMAC-SHA1',
    'oauth_timestamp=' . $oauth_timestamp,
    'oauth_version=1.0',
    'user_id=' . $user_id
  );
  
  my $response = web_request($url, {
      JSON_RETURN => 1,
      JSON_UTF8   => 1,
    });
  
  $self->{result} = $response;
  
  return $response;
}

1;
