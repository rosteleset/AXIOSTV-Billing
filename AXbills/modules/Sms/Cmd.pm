package Cmd;
=head1 NAME

  sms Cmd

=head2 SYNOPSIS

  This package use console sms sender

  Needs to be in config.pl:
    $conf{SMS_CMD} = '/path/to/file MESSAGE=%MESSAGE% NUMBER=%NUMBER%';

=head2 VERSION

  VERSION: 1.02
  UPDATED: 20220207

=cut
use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(_bp urlencode cmd);
use AXbills::Fetcher;
my $MODULE = 'Universal_sms_module';
our $VERSION = 1.01;

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
  my $request_url = $self->{conf}->{SMS_CMD} || q{};
  my $result = q{};

  if ($attr->{NUMBERS}) {
    foreach my $number (sort keys %{$attr->{NUMBERS}}) {
      my $message = urlencode($attr->{MESSAGE});
      $request_url =~ s/\%MESSAGE\%/$message/g;
      $attr->{NUMBER} =~ s/ //g;
      $attr->{NUMBER} =~ s/-//g;
      $request_url =~ s/\%NUMBER\%/$number/g;
      $result = cmd($request_url, { DEBUG => $self->{DEBUG}, CURL => 1});
      $request_url =~ s/$number/\%NUMBER\%/g;
    }
  }
  elsif ($attr->{NUMBER}) {
    foreach my $number ( split(/,\s?/, $attr->{NUMBER}) ) {
      my $message = urlencode($attr->{MESSAGE});
      $request_url =~ s/\%MESSAGE\%/$message/g;
      $attr->{NUMBER} =~ s/ //g;
      $attr->{NUMBER} =~ s/-//g;
      $request_url =~ s/\%NUMBER\%/$number/g;
      $result = cmd($request_url, { DEBUG => $self->{DEBUG}, CURL => 1});
      if($number) {
        $number =~ s/\+/\\\+/;
        $request_url =~ s/$number/\%NUMBER\%/gi;
      }
    }
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