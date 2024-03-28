package AXbills::Auth::Telegram;

=head1 NAME

  Telegram OAuth module

=cut

use strict;
use warnings FATAL => 'all';

use Digest::SHA;
use AXbills::Base qw(urlencode);

#**********************************************************
=head2 check_access($attr)

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{hash}) {
    my $hash = $attr->{hash} || '';

    delete @{$attr}{qw/external_auth hash language/};

    my $hash_string = '';
    foreach my $param (sort keys %{$attr}) {
      $hash_string .= "$param=$attr->{$param}\n";
    }
    chomp($hash_string);

    my $sign_key = Digest::SHA::sha256($self->{conf}->{TELEGRAM_TOKEN});
    my $sha_hash = Digest::SHA::hmac_sha256_hex($hash_string, $sign_key);

    if ($sha_hash eq $hash) {
      $self->{USER_ID}     = $attr->{id};
      $self->{USER_NAME}   = $attr->{first_name};
      $self->{CHECK_FIELD} = 'TELEGRAM';
    }
  }
  else {
    my $bot_id = urlencode($self->{conf}->{AUTH_TELEGRAM_ID} || '');
    my $origin_url = urlencode($self->{self_url});
    my $request_access = urlencode('write');
    my $return_to = urlencode('?external_auth=Telegram');
    $self->{auth_url} = qq{ https://oauth.telegram.org/auth?bot_id=$bot_id&origin=$origin_url&request_access=$request_access&embed=1&return_to=$return_to };
  }

  return $self;
}

1;
