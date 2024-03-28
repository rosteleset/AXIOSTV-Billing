package AXbills::Auth::Instagram;

=head1 NAME

  Instagram OAuth module

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(urlencode mk_unique_value _bp);
do 'AXbills/Misc.pm';

my $auth_endpoint_url = 'https://api.instagram.com/oauth/authorize';
my $access_token_url = 'https://api.instagram.com/oauth/access_token';
my $get_me_url = 'https://www.googleapis.com/userinfo/v2/me';
my $get_public_info_url = 'https://api.instagram.com/v1/users/';


#**********************************************************
=head2 check_access($attr)

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr) = @_;

  my $client_id = $self->{conf}->{AUTH_INSTAGRAM_ID} || q{};
  my $redirect_uri = $self->{conf}->{AUTH_INSTAGRAM_URL} || q{};
  $redirect_uri    =~ s/\%SELF_URL\%/$self->{self_url}/g;
  $self->{debug} = $self->{conf}->{AUTH_INSTAGRAM_DEBUG} || 0;

  if ( $self->{debug} ) {
    print "Content-Type: text/html\n\n";
  }

  if ( !exists $attr->{code} ) {
    # Form redirect_url;
    $self->{auth_url} = join('', "$auth_endpoint_url?",
      "&response_type=code",
      "&client_id=$client_id",
      "&redirect_uri=$redirect_uri",    );

    return $self;
  }
  else {
    my $token = $self->get_token( $attr->{code} );
    if ( defined $token ) {
      my $user_info = $token->{user};
      print $user_info->{id};
      if ( $user_info->{username} ) {
        $self->{USER_ID} = 'instagram, ' . $user_info->{id};
        $self->{USER_NAME} = $user_info->{username};
        $self->{CHECK_FIELD} = '_INSTAGRAM';
      }
    }
    else {
      _bp('Error getting token','',{HEADER=> 1});
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

  my $client_id = $self->{conf}->{AUTH_INSTAGRAM_ID} || q{};
  my $client_secret = $self->{conf}->{AUTH_INSTAGRAM_SECRET} || q{};
  my $redirect_uri = $self->{conf}->{AUTH_INSTAGRAM_URL} || q{};
  $self->{debug} = $self->{conf}->{AUTH_INSTAGRAM_DEBUG} || 0;
  $redirect_uri    =~ s/\%SELF_URL\%/$self->{self_url}/g;

  my $post_params = join('',
    "code=$code",
    "&client_id=$client_id",
    "&client_secret=$client_secret",
    "&redirect_uri=$redirect_uri",
    '&grant_type=authorization_code'
  );

  my $result = web_request($access_token_url, {
      POST        => $post_params,
      HEADERS     => [ 'Content-Type: application/x-www-form-urlencoded' ],
      JSON_RETURN => 1,
      DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
    }
  );

  # _bp('Result', $result, {HEADER => 1});

  if ( $result->{access_token} ) {
    print "Ok <br/>" if ( $self->{debug} );
    return $result;
  }
  elsif ( $result->{error} ) {
    print "Error getting token: $result->{error} <br/>" if ( $self->{debug} );
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

  my $token = $attr->{TOKEN};
  my $client_id = $attr->{CLIENT_ID};
  
  unless ( defined $token ) {
    my $result = web_request($get_public_info_url . $client_id, {
        JSON_RETURN => 1,
        DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
      });

    $self->{result} = $result;
    return $result;
  };

  #my $token_type = $token->{token_type};
  #my $access_token = $token->{access_token};

  my $result = web_request($get_public_info_url . "$client_id/", {
      JSON_RETURN => 1,
      REQUEST_PARAMS => {'access_token' => $token},
      GET => 1,
      #HEADERS     => [ "Authorization: $token_type $access_token" ],
      DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
    });

  if ( $result->{error} ) {
  show_hash($result->{error});
  $self->{errno} = $result->{error}->{code};
  $self->{errstr} = $result->{error}->{message};
  }

  $self->{result} = $result;

  return $result;
}

1;
