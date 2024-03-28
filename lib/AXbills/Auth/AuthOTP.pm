package AXbills::Auth::AuthOTP;

=head1 AuthOTP

  Sign in OTP (Auth 2FA)

=cut

use strict;
use warnings FATAL => 'all';

use Convert::Base32;
use Digest::HMAC_SHA1 qw/ hmac_sha1_hex /;

our (
    %lang,
    %conf,
    $html,
    $admin,
    %FORM,
    $db,
);

#**********************************************************
=head2  get_token() - Get token

  Arguments:
    token_key   - input token
    code        - personal user code field _G2FA

  Return:
    result token
    SUCCESS / FAILED

=cut
#**********************************************************
sub get_token {
  my $self = shift;
  my ($token_key, $code) = @_;

  unless ($code) {
    print $html->tpl_show(templates('form_g2fa'), {
      SKIP_DEBUG_MARKERS => 1,
      MAIN               => 1,
      ID                 => 'form_g2fa',
      G2FA_SUCCESS       => 'FORM_G2FA'
    });
  }
  else {
    my $token_result = 0;
    my $error_code = 0;

    if ($code) {
      ($token_result, $error_code) = totp_token($code, $token_key);
    }

    if($token_result) {
      return $token_result;
    }
    else {
      if ($error_code == 2) {
        return $token_result;
      }
    }
  }
}

#**********************************************************
=head2 check_auth($attr)

   Arguments:
    user      - user login

  Return:
    self

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr) = @_;

  $self->{USER_ID} = $attr->{user};
  $self->{CHECK_FIELD} = 'LOGIN';
  $self->{G2FA} = 1;

  return $self;
}

#**********************************************************
=head2 totp_token()

  Arguments:
    input_token     - input key user
    secret          - personal user code field _G2FA

  Return:
    SUCCESS   - token and code error 1
    FAILED    - empty string and code error 2

=cut
#**********************************************************
sub totp_token {
  my ($input_token, $secret) = @_;

  my $key = unpack("H*", decode_base32($secret));
  my $temp_time = sprintf("%016x", int(time()/30));
  my $hmac = hmac_sha1_hex_string($temp_time, $key);

  my $offset = sprintf("%d", hex(substr($hmac, -1)));

  my $part_left = 0 + sprintf("%d", hex(substr($hmac, $offset * 2, 8)));
  my $part_right = 0 + sprintf("%d", hex("7fffffff"));

  my $token = substr("" . ($part_left & $part_right), -6);

  if ($token == $input_token) {
    return ($token, 1);
  }
  else {
    return ('', 2);
  }
}

#**********************************************************
=head2 hmac_sha1_hex_string()

  Arguments:
    data      - timestamp and data 30 sec
    key       - hash user personal key

  Return:
    result sha1 hmac

=cut
#**********************************************************
sub  hmac_sha1_hex_string {
  my ($data, $key) = map pack('H*', $_), @_;

  return hmac_sha1_hex($data, $key);
}

1;
