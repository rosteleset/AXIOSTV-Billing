package AXbills::Auth::Vk;
=head1 NAME

  vk.com auth module

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(_bp urlencode show_hash);
use AXbills::Fetcher;
use Encode;

#**********************************************************
=head2 check_auth($attr)

  vk_auth
  http://vk.com/dev/auth_sites

  # https://oauth.vk.com/authorize?client_id=3458245&response_type=code&state=vkontakte&redirect_uri=https%3A%2F%2Fmy.lanet.ua%2Flogin.php

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr) = @_;

  my $client_id = $self->{conf}->{AUTH_VK_ID} || q{};
  my $redirect_uri = $self->{conf}->{AUTH_VK_URL} || q{};
  my $version = '5.62';
  my $client_secret = $self->{conf}->{AUTH_VK_SECRET} || q{};
  $self->{debug} = $self->{conf}->{AUTH_VK_DEBUG} || 0;
  $redirect_uri =~ s/\%SELF_URL\%/$self->{self_url}/g;

  my $redirect_encoded = urlencode($redirect_uri);

  if ($attr->{code}) {
    my $request = qq(https://oauth.vk.com/access_token?client_id=$client_id&client_secret=$client_secret&redirect_uri=$redirect_encoded&code=$attr->{code});
    my $result = web_request($request, { JSON_RETURN => 1 });
    if ($self->{debug}) {
      print "Content-Type: text/html\n\n";
      print "Ok";
      show_hash($result, DELIMITER => '<br>');
      print "Redirect: $redirect_uri //";
    }

    if ($result->{user_id}) {
      #      $self->{SID}         = $result->{access_token};
      $self->{EXPIRE} = $result->{expires_in};
      $self->{USER_ID} = 'vk, ' . $result->{user_id};
      $self->{CHECK_FIELD} = '_VK';
    }

    #Return
    # {"access_token":"0cbc06819f523fdbbd7e593afbb63509e2b6df75504da82f6a0a6d98e5e69fcff9dc551f481d598df9edd","expires_in":86376,"user_id":22089814}
  }
  else {
    $self->{auth_url} = qq{ https://oauth.vk.com/authorize?client_id=$client_id&display=page&redirect_uri=$redirect_encoded&scope=friends&response_type=code&v=$version };
  }

  return $self;
}

#**********************************************************
=head2 get_info($attr)

 https://api.vk.com/method/users.get?uids=22089814&fields=uid,first_name,last_name,screen_name,sex,bdate,photo_big

=cut
#**********************************************************
sub get_info {
  my $self = shift;
  my ($attr) = @_;

  my $client_id = $attr->{CLIENT_ID};
  my $request = qq{https://api.vk.com/method/users.get?uids=$client_id&fields=uid,first_name,last_name,screen_name,sex,bdate,photo_big};


  $request .= "&v=5.131&access_token=$self->{conf}{AUTH_VK_SERVICE_KEY}" if $self->{conf}{AUTH_VK_SERVICE_KEY};
  my $result = web_request($request, { JSON_RETURN => 1, JSON_UTF8 => 1 });

  if ($result->{error}) {
    $self->{errno} = $result->{error}{error_code};
    $self->{errstr} = $result->{error}{error_msg};
  }
  elsif ($result->{response}) {
    $self->{result} = $result->{response}->[0];
  }
  else {
    $self->{result} = $result;
  }
  return $self;
}

#**********************************************************
=head2 get_request($attr) work with VK API

  Arguments:
    METHOD - method
	PARAMS - params
	
  Returns:
    JSON data
	
=cut
#**********************************************************
sub get_request {
  my $self = shift;
  my ($request) = @_;

  unless ($request->{METHOD}) {return 1;}

  my $request_url = 'https://api.vk.com/method/' . ($request->{METHOD}) . '?'
    . ($request->{PARAMS} || q{}) . "&v=5.52";

  my $result = web_request($request_url, {
    JSON_RETURN => 1,
    DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
  });

  return $result;
}


#**********************************************************
=head2 count_vk_likes ($attr) count likes

  Arguments:
    owner_id, post_id
	
  Returns:
    (int) likes
	
=cut
#**********************************************************
sub count_vk_likes {
  my $self = shift;
  my ($attr) = @_;

  #my $client_id    = $self->{conf}->{AUTH_VK_ID} || q{};
  my $version = '5.62';
  #my $client_secret= $self->{conf}->{AUTH_VK_SECRET} || q{};

  unless ($attr->{OWNER_ID} && $attr->{POST_ID}) {return 1;}

  my $access_token = 'f0002012682259e2f9ff36765880ad14bd8c461817c9e243bd1eefe109118110afc853609991afcb1c354';

  my $request_url = 'https://api.vk.com/method/'
    . 'execute.GatherLikes?'
    . 'user=' . $attr->{OWNER_ID}
    . '&post=' . $attr->{POST_ID}
    . '&offset=0&v=' . $version
    . '&access_token=' . $access_token;

  my $result = web_request($request_url, {
    JSON_RETURN => 1,
    DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
  });

  return $result;
}

1;
