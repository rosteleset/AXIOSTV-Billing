package WebSms;
=head1 NAME

   WebSms
   HTTP API
   https://cabinet.websms.by/public/client/apidoc/

   API_VERSION = '1.1.2';

=cut

=head1 VERSION

  VERSION: 8.04
  REVISION: 2021.11.18

=cut

use strict;
use warnings FATAL => 'all';
use Encode qw(decode_utf8);

use AXbills::Base qw(_bp urlencode load_pmodule);
use AXbills::Fetcher;

our $VERSION = 8.04;
my $MODULE = 'WebSms';
#my ($admin, $CONF);

my %errors = (
  1 => 'Internal error',
  2 => 'Incorrect API call',
  3 => 'Missing user or apikey',
  4 => 'Error validation input data for function create and update',
  5 => 'Path not found',
  6 => 'Wrong query in api server',
  7 => 'Not found required parametr in request'
);

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
    DEBUG           => $CONF->{SMS_WEBSMS_DEBUG} || 0,
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

  my $send_url = $self->{conf}->{SMS_WEBSMS_URL};
  my $user     = $self->{conf}->{SMS_WEBSMS_USER} || q{};
  my $api_key  = $self->{conf}->{SMS_WEBSMS_APIKEY} || q{};
  my $sender   = $self->{conf}->{SMS_WEBSMS_SENDER} || q{};
  
  my $message = $attr->{MESSAGE};
  $message =~ s/\n/\\n/g;

  my $valid_number = _valid_phone({ 
    WEBSMS_EXT => $self->{conf}->{SMS_WEBSMS_EXT},
    NUMBER     => $attr->{NUMBER} || '',
    NUMBERS    => $attr->{NUMBERS} || '',
  });

  my $your_number = _create_tpl_mess({
    NUMBERS => $attr->{NUMBERS} || '',
    NUMBER  => $attr->{NUMBER} || '',
  });

  my $result = _send_request($send_url, $user, $api_key, $your_number, $message, $sender);

  $self->{id} = $result->{message_id} || '';

  return $result;
}

#**********************************************************
=head2 _valid_phone()

=cut
#**********************************************************
sub _valid_phone {
  my $self = shift;
  my ($attr) = @_;

  if (!$self->{NUMBER}) {
    $self->{errno} = 20;
    $self->{errstr} = "ERROR_PHONE_NOT_EXIST";
    
    return $self;
  }
  
  if ($self->{WEBSMS_EXT}){
    unless ($self->{NUMBER} =~ $self->{WEBSMS_EXT} ){
      $self->{errno} = 21;
      $self->{errstr} = "ERROR_WRONG_PHONE";

      return $self;
    }
  }
  else {
    $self->{errno} = 21;
    $self->{errstr} = "ERROR_WRONG_PHONE";

    return $self;
  }
}

#**********************************************************
=head2 _create_tpl_mess()

=cut
#**********************************************************
sub _create_tpl_mess {
  my ($attr) = @_;

  if ($attr->{NUMBERS} && $attr->{NUMBERS} ne '') {
    $attr->{NUMBERS} =~ s/ //g;
    $attr->{NUMBERS} =~ s/-//g;
    $attr->{NUMBERS} =~ s/;/,/g;
      
    return $attr->{NUMBERS};
  }
  elsif ($attr->{NUMBER} && $attr->{NUMBER} ne '') {
    $attr->{NUMBER} =~ s/ //g;
    $attr->{NUMBER} =~ s/-//g;
    $attr->{NUMBER} =~ s/;/,/g;

    return $attr->{NUMBER};
  }

  return '';
}

#**********************************************************
=head2 _send_request()

=cut
#**********************************************************
sub _send_request {
  my ($send_url, $user, $api_key, $number, $message, $sender) = @_;

  my @header = ("Content-Type: application/json");
  
  my $method = '/send/sms';

  #$method =~ s/\//%2F/g;
  $send_url .= $method;

  $user     =~ s/\@/%40/g;
  $number   =~ s/\+/%2B/g;
  $message  =~ s/ /%20/g;
  $message  =~ s/[\r\n]+/%20/;

  my $request_template = qq{$send_url?user=$user&apikey=$api_key&msisdn=$number&text=$message&sender=$sender};

  my $result = web_request($request_template, {
    CURL     => 1,
    HEADERS  => \@header,
    JSON_RETURN => 1
  });

  return $result;
}

#**********************************************************
=head2 account_info($attr)

=cut
#**********************************************************
sub account_info { #in future breaks old API
  my $self = shift;

  my %result = ();

  my $send_url = $self->{conf}->{SMS_WEBSMS_URL};
  my $user     = $self->{conf}->{SMS_WEBSMS_USER} || q{};
  my $api_key  = $self->{conf}->{SMS_WEBSMS_APIKEY} || q{};

  my @header = ("Content-Type: application/json");

  my $method = '/?r=api/user_balance';
 # $method =~ s/\//%2F/g;

  my $request_template = qq{$send_url$method&user=$user&apikey=$api_key};

  my $result = web_request($request_template, {
    CURL     => 1,
    HEADERS  => \@header,
    JSON_RETURN => 1
  });
 
  if($result->{status} && $result->{status} eq 'success'){
    $result{balance} = $result->{balance};
  }

  $method = '/senderNames';
  #$method =~ s/\//%2F/g;
  $request_template = qq{$send_url$method?user=$user&apikey=$api_key};
  
  #$result = web_request($request_template, {
  #  CURL     => 1,
  #  HEADERS  => \@header,
  #  JSON_RETURN => 1
  #});
  
  #if($result->{status} && $result->{status} eq 'success'){
  #  $result{default_name} = $result->{default_name};
  #}

  return [\%result];

}

#**********************************************************
=head2 get_status($attr)

=cut
#**********************************************************
sub get_status{
  my $self = shift;
  my ($attr) = @_;

  return 0 if(!$attr->{EXT_ID});

  my $send_url = $self->{conf}->{SMS_WEBSMS_URL};
  my $user     = $self->{conf}->{SMS_WEBSMS_USER} || q{};
  my $api_key  = $self->{conf}->{SMS_WEBSMS_APIKEY} || q{};

  my $method = '/status/sms';
#  $method =~ s/\//%2F/g;

  my @header = ("Content-Type: application/json");

  my $request_template = qq{$send_url$method?user=$user&apikey=$api_key&message_id=$attr->{EXT_ID}};

  my $result = web_request($request_template, {
    CURL     => 1,
    HEADERS  => \@header,
    JSON_RETURN => 1
  });
  if(defined($result->{status})){
    my $new_status = 0;
    
    my $status = $result->{message_status}{code} || $result->{error}{code};
    $new_status = 0 if($status == 0);
    $new_status = 0 if($status == 0);
    $new_status = 2 if($status == 1);
    $new_status = 103 if($status == 2);
    $new_status = 100 if($status == 3);
    $new_status = 101 if($status == 4);
    $new_status = 14 if($status == 12);

    $self->{status} = $new_status;

  }

  return $result;

}

1;
