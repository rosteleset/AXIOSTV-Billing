package MTSBY;
=head1 NAME

   MTSBY
   HTTP API

=cut

=head1 VERSION

  VERSION: 8.04
  REVISION: 2023.05.11

=cut

use strict;
use warnings FATAL => 'all';
use Encode qw(decode_utf8);
#use Data::Dumper;
use JSON::MaybeXS;
use LWP::UserAgent;
use HTTP::Request::Common;
use MIME::Base64;

use AXbills::Base qw(_bp urlencode load_pmodule);
use AXbills::Fetcher;

our $VERSION = 8.05;
my $MODULE = 'MTSBY';
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
    DEBUG           => $CONF->{SMS_MTSSMS_DEBUG} || 0,
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

  my $send_url   = $self->{conf}->{SMS_MTSSMS_URL};
  my $user       = $self->{conf}->{SMS_MTSSMS_LOGIN};
  my $password   = $self->{conf}->{SMS_MTSSMS_PASSWORD};
  my $sender     = $self->{conf}->{SMS_MTSSMS_SENDER} || q{};
  my $alpha_name = $self->{conf}->{SMS_MTSSMS_ALPHA_NAME};
  my $client_id  = $self->{conf}->{SMS_MTSSMS_CLID};

  my $message = $attr->{MESSAGE};
  $message =~ s/\n/\\n/g;
  $message = decode_utf8($attr->{MESSAGE});
  $message =~ s/ %20/ /g;

  my $valid_number = _valid_phone({ 
    WEBSMS_EXT => $self->{conf}->{SMS_MTSSMS_EXT},
    NUMBER     => $attr->{NUMBER} || '',
    NUMBERS    => $attr->{NUMBERS} || '',
  });

  my $number = _create_tpl_mess({
    NUMBERS => $attr->{NUMBERS} || '',
    NUMBER  => $attr->{NUMBER} || '',
  });

  my $result = _send_request($send_url, $user, $password,
                             $number, $message, $sender, $alpha_name,$client_id);

  $self->{INSERT_ID} = $result || '';
  
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
  my ($send_url, $user, $password, $number,$message,
         $sender, $alpha_name,$client_id) = @_;
  
  my $method = $client_id . '/json2/simple';

  $send_url .= $method;

  $user     =~ s/\@/%40/g;
  $number   =~ s/\+/%2B/g;

# -- my json -- 

my $channels = [ 'sms' ];
my $channel_options = {
    'sms' => {
        'text' => $message,
        'alpha_name' => $alpha_name,
        'ttl' => 259200
    }
};

my $json_obj = {
    'phone_number' => $number,
#    'extra_id' => $extra_id,
#    'tag' => $sender,
    'channels' => $channels,
    'channel_options' => $channel_options
};
#=================my json end =======================
my $token = encode_base64("$user:$password");
chomp($token);
my $authorization_header = "Basic $token";
my $content_type_header = 'application/json';

my $headers = HTTP::Headers->new(
    'Authorization' => $authorization_header,
    'Content-Type' => $content_type_header
);

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new('POST', $send_url, $headers, encode_json($json_obj));

	my $result = $ua->request($req);
	# if ($result->is_success) {
		# print "Response: ", $result->content, "\n";
	# } else {
		# die "Failed to execute web_request: ", $result->status_line, "\n";
	# }

  my $decoded_data = decode_json($result->content);
  $result = $decoded_data->{message_id};

  return $result;
}


#**********************************************************
=head2 get_status($attr)

=cut
#**********************************************************
sub get_status{
  my $self = shift;
  my ($attr) = @_;

  return 0 if(!$attr->{EXT_ID});

  my $send_url   = $self->{conf}->{SMS_MTSSMS_URL};
  my $user       = $self->{conf}->{SMS_MTSSMS_LOGIN};
  my $password   = $self->{conf}->{SMS_MTSSMS_PASSWORD};
  my $sender     = $self->{conf}->{SMS_MTSSMS_SENDER} || q{};
  my $alpha_name = $self->{conf}->{SMS_MTSSMS_ALPHA_NAME};
  my $client_id  = $self->{conf}->{SMS_MTSSMS_CLID};

  my $method = $client_id . '/dr/'. $attr->{EXT_ID} .'/simple';
    $send_url .= $method;
  my $token = encode_base64("$user:$password");
  chomp($token);
  my $authorization_header = "Basic $token";

  my $headers = HTTP::Headers->new(
    'Authorization' => $authorization_header
  );

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new('GET', $send_url, $headers);
    my $result = $ua->request($req);
	
	# if ($result->is_success) {
		# print "Response: ", $result->content, "\n";
	# } else {
		# die "Failed to execute web_request: ", $result->status_line, "\n";
	# }
	
	if (! $result->is_success) {
		return 0;
	}
	  
  my $decoded_data = decode_json($result->content);
  
  if(defined($decoded_data->{status})){
    my $new_status = 0;
    
    my $status = $decoded_data->{msg_status} || $decoded_data->{error_code};
    $new_status = 110 if($status == 36011);
    $new_status = 111 if($status == 23011);
    $new_status = 112 if($status == 35015);
    $new_status = 113 if($status == 36021);
    $new_status = 114 if($status == 36031);
    $new_status = 115 if($status == 12011);
    $new_status = 116 if($status == 36041);
    $new_status = 117 if($status == 36051);

    $self->{status} = $new_status;

  }

  return $self->{status};

}

1;