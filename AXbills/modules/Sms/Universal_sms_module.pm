package Universal_sms_module;
=head1 NAME

  Universal_sms_module

=head2 SYNOPSIS

  This package for making requests to sms server

  Needs to be in config.pl:
    $conf{SMS_UNIVERSAL_URL} = 'http://URL?number=%NUMBER%&message=%MESSAGE%';

=head2 VERSION

  VERSION: 1.00
  REVISION: 31.05.2019

=cut
use strict;
use warnings FATAL => 'all';
use Encode qw(decode_utf8);

use AXbills::Base qw(_bp urlencode);
use AXbills::Fetcher;

my $MODULE = 'Universal_sms_module';
our $VERSION = 1.00;

#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;

  my $self = {
    db              => $db,
    admin           => $admin,
    conf            => $CONF,
    SERVICE_NAME    => $MODULE,
    SERVICE_VERSION => $VERSION,
    DEBUG           => $CONF->{SMS_UNIVERSAL_DEBUG} || 0,
  };
  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 send_sms()

=cut
#**********************************************************
sub send_sms {
  my $self = shift;
  my ($attr) = @_;

  my $request_url_tpl = $self->{conf}->{SMS_UNIVERSAL_URL} || q{};
  my $result = q{};
  my $message = urlencode($attr->{MESSAGE});
  my $hexstr = decode_utf8($attr->{MESSAGE});
  $hexstr =~ s/(.)/sprintf("%04x",ord($1))/eg;
  $hexstr =~ s/\n/000a/g;
  $hexstr =~ s/\r//g;

  my @numbers;
  if ($attr->{NUMBER} && $attr->{NUMBER} ne '') {
    @numbers = split(/,\s?/, $attr->{NUMBER});
  }
  elsif ($attr->{NUMBERS} && $attr->{NUMBERS} ne '') {
    @numbers = sort keys %{$attr->{NUMBERS}};
  }

  foreach my $number (@numbers) {
    my $request_url = $request_url_tpl;

    $request_url =~ s/\%MESSAGE\%/$message/g;
    $request_url =~ s/\%HEX_MESSAGE\%/$hexstr/g;

    $number =~ s/ //g;
    $number =~ s/-//g;
    $request_url =~ s/\%NUMBER\%/$number/g;
    $result = web_request($request_url, { DEBUG => $self->{DEBUG}, CURL => 1});
  }

  return $result;
}

#**********************************************************
=head2 account_info($attr)

=cut
#**********************************************************
sub account_info{
  #my $self = shift;

  return [ ];
}

1;
