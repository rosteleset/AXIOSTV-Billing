package Yandex;
#**********************************************************
=head1 NAME
  Interface for "Yandex Money" payment system

  Access IP:

=head1 VERSION

  VERSION: 0.04
  REVISION: 20190307

=cut
#**********************************************************

use strict;
our ($VERSION);
$VERSION = 0.04;

#my $MODULE = 'Yandex';
#my $md5;

my ($admin, $CONF);
use Socket;
use IO::Socket;
use IO::Select;
use AXbills::Base qw(load_pmodule urlencode);

#Apllication ID
my ($paysys_yandex_id,
  $client_secret,
  $yandex_acccount,
  $redirecturi,
  $json,
  $debug);

do "AXbills/Misc.pm";

use constant YM_URI_API => 'https://money.yandex.ru/api';
use constant YM_URI_AUTH => 'https://sp-money.yandex.ru/oauth/authorize';
use constant YM_URI_TOKEN => 'https://sp-money.yandex.ru/oauth/token';
my $CURL;

#**********************************************************
=head2 new($db, $admin, $CONF)

=cut
#**********************************************************
sub ym_new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  my $mod_return = load_pmodule('JSON', { SHOW_RETURN => 1 });
  my $payment_system = 73;

  if ($mod_return) {
    #mk_log($mod_return, { PAYSYS_ID => $payment_system, SHOW => 1 });
  }

  $self->{db} = $db;
  $CURL = $CONF->{FILE_CURL} || `which curl` || '/usr/local/bin/curl';
  chomp($CURL);
  $json = JSON->new->allow_nonref;

  #Apllication ID
  $paysys_yandex_id= $CONF->{PAYSYS_YANDEX_ID} || '';
  # Client Secret
  $client_secret   = $CONF->{PAYSYS_YANDEX_CLIENT_SECRET} || '';
  $yandex_acccount = $CONF->{'PAYSYS_YANDEX_ACCCOUNT'} || '';
  $redirecturi     = $CONF->{'PAYSYS_YANDEX_REDIRECT_URI'} || '';
  $debug           = $CONF->{PAYSYS_DEBUG} || 0;

  return $self;
}

#yandex();

#**********************************************************
=head2 ym_requestor()

=cut
#**********************************************************
sub ym_requestor {
  my ($attr) = @_;

  my $YM_USER_AGENT = 'ym_axbills';
  my $url = $attr->{URL};
  my $request = $attr->{REQUEST};

  my $headers = qq{ -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" };
  if ($attr->{access_token}) {$headers .= qq{ -H "Authorization: Bearer $attr->{access_token}" };}
  $debug = $attr->{DEBUG} if ($attr->{DEBUG});
  my $curl_setopt = '-s --insecure';
  $curl_setopt .= " -A $YM_USER_AGENT";
  $curl_setopt .= " -E $attr->{CERT}" if ($attr->{CERT});

  my $cmd = "$CURL $curl_setopt $headers $url -d \"$request\"";
  my $rbody = '';

  if ($debug < 6) {
    open(my $CMD, '-|', "$cmd") or print "Can't open cmd $!";
    while (<$CMD>) {
      $rbody .= $_;
    }
    close($CMD);
  }

  if ($debug > 4) {
    print $cmd . "\n";

    open(my $CMD, '>>', "tmp/ym") or print "Can't open cmd $!";
    print $CMD $cmd;
    close($CMD);
  }

  return $rbody;
}


#**********************************************************   
=head2 ym_error($rbody)

=cut
#**********************************************************
sub ym_error {
  my $self = shift;
  my ($rbody) = @_;
  #my ($error_id, $error_txt);

  if ($rbody->{error}) {
    $self->{error} = 1;
    $self->{error_str} = $rbody->{error};
    $self->{status} = $rbody->{status};
    $self->{error_description} = $rbody->{error_description};
  }

  #        switch ($rcode) {
  #            case 400:
  #                throw new YM_ApiError("Invalid request error", $rcode, $rbody, $resp);
  #            case 401:
  #                throw new YM_InvalidTokenError("Nonexistent, expired, or revoked token specified.", $rcode, $rbody, $resp);
  #            case 403:
  #                throw new YM_InsufficientScopeError("The token does not have permissions for the requested operation.",
  #                    $rcode, $rbody, $resp);
  #            case 500:
  #                throw new YM_InternalServerError("It is a technical error occurs, the server responds with the HTTP code
  #                    500 Internal Server Error. The application should repeat the request with the same parameters later.",
  #                    $rcode, $rbody, $resp);
  #            default:
  #                throw new YM_ApiError("Unknown API response error. You should inform your software developer.",
  #                    $rcode, $rbody, $resp);
  #        }

  return $self;
}


#**********************************************************
#
#**********************************************************
sub receiveOAuthToken {
  my $self = shift;
  my ($attr) = @_;

  my %paramArray = ();

  $paramArray{grant_type} = 'authorization_code';
  $paramArray{client_id} = $paysys_yandex_id;
  $paramArray{code} = $attr->{code};
  $paramArray{redirect_uri} = $redirecturi;
  $paramArray{client_secret} = $client_secret;

  my $params = http_build_query(\%paramArray);

  #print "Content-Type: text/html\n\n";
  my $resp_hash;
  my $result = ym_requestor({ URL => YM_URI_TOKEN,
    REQUEST                       => $params,
    CERT                          => $CONF->{'PAYSYS_YANDEX_CERT'}
  });

  my $res_scalar = $json->decode($result);

  $self->ym_error($res_scalar);

  if (!$self->{error}) {
    $self->{token} = $res_scalar->{access_token};
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub ym_account_info {
  my $self = shift;
  my ($access_token) = @_;

  my $result = ym_requestor({ URL => YM_URI_API . '/account-info',
    access_token                  => $access_token,
  });
  my $res_scalar;
  if ($result eq '') {
    $self->{error} = 2;
    $self->{error_str} = 'Wrong token';
    return $res_scalar;
  }

  $res_scalar = $json->decode($result);
  $self->ym_error($res_scalar);

  return $res_scalar;
}


#**********************************************************
#
#**********************************************************
sub ym_process_payment {
  my $self = shift;
  my ($access_token, $request_id) = @_;

  #my $resp_hash;
  my $result = ym_requestor({ access_token => $access_token,
    URL                                    => YM_URI_API . '/process-payment',
    REQUEST                                => "request_id=$request_id",
    CERT                                   => $CONF->{'PAYSYS_YANDEX_CERT'},
    #                            DEBUG   => 6
  });

  my $res_scalar;
  if ($result eq '') {
    $self->{error} = 2;
    $self->{error_str} = 'Wrong token';
    return $res_scalar;
  }

  $res_scalar = $json->decode($result);

  $self->ym_error($res_scalar);

  if (!$self->{error}) {
    $self->{token} = $res_scalar->{access_token};
  }

  return $res_scalar;
}

#**********************************************************
#
#**********************************************************
sub ym_request_payment_p2p {
  my $self = shift;
  my ($access_token, $to, $amount, $comment, $message) = @_;

  my %paramArray = ();
  $paramArray{pattern_id} = 'p2p';
  $paramArray{to} = $to || $yandex_acccount;
  $paramArray{amount} = $amount;
  $paramArray{comment} = $comment;
  $paramArray{message} = $message;

  my $params = http_build_query(\%paramArray);

  #my $resp_hash;
  my $result = ym_requestor({ access_token => $access_token,
    URL                                    => YM_URI_API . '/request-payment',
    REQUEST                                => $params,
    CERT                                   => $CONF->{'PAYSYS_YANDEX_CERT'},
    #                            DEBUG   => 6
  });

  my $res_scalar;
  if ($result eq '') {
    $self->{error} = 2;
    $self->{error_str} = 'Wrong token';
    return $res_scalar;
  }

  $res_scalar = $json->decode($result);

  $self->ym_error($res_scalar);

  if (!$self->{error}) {
    $self->{token} = $res_scalar->{access_token};
  }

  return $res_scalar;
}


#**********************************************************
#
#**********************************************************
sub http_build_query {
  my ($params) = @_;
  my $response = '';

  foreach my $key (sort keys(%$params)) {
    $response .= "$key=$params->{$key}&";
  }

  return $response;
}

#**********************************************************
#
#**********************************************************
sub yandex_get_token {
  my $self = shift;
  #my ($attr) = @_;

  my $scope = "account-info " .
    "payment-shop " .
    "payment-p2p " .
    #"payment.to-account(\"$yandex_acccount\",\"account\").limit(30,$attr->{SUM}) " .
    "money-source(\"wallet\",\"card\")";

  my $res = authorizeUri($paysys_yandex_id, $redirecturi, $scope);

  print "Location: $res\n\n";
  return 0;
}


#**********************************************************
#
#**********************************************************
sub authorizeUri {
  my ($clientId, $redirectUri, $scope) = @_;

  if (!$scope) {
    $scope = 'account-info operation-history';
  }
  $scope = lc($scope);

  my $res = YM_URI_AUTH . "?client_id=$clientId&response_type=code&scope=" .
    urlencode($scope) . "&redirect_uri=" . urlencode($redirectUri);
  return $res;
}


#**********************************************************
=head2

=cut
#**********************************************************
# sub urlencode {
#   my ($text) = @_;
#
#   $text =~ s/ /+/g;
#   $text =~ s/([^A-Za-z0-9+\-\.])/sprintf("%%%02X", ord($1))/seg;
#
#   return $text;
# }


1
