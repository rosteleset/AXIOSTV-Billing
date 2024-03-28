package AXbills::Sender::Hyber;
use strict;
use warnings;

use parent 'AXbills::Sender::Plugin';

use AXbills::Fetcher;
use AXbills::Base qw(_bp in_array);
use JSON qw/to_json from_json/;
our $VERSION = 0.01;

#**********************************************************
=head2 new($db, $admin, $CONF, $attr) - Create new Hyber object

  Arguments:
    $attr 
      CONF -     
  Returns:

  Examples:
    my $GWW = AXbills::Sender::Gmsworldwide->new($db, $admin, \%conf);

=cut
#**********************************************************
sub new {
  my $class  = shift;
  my ($conf) = @_;
  
  if (!$conf->{GMS_WORLDWIDE_CLIENT_ID}){
    die 'No $conf{GMS_WORLDWIDE_CLIENT_ID} in config.pl' . "\n";
  }
  
  my $self = {
    url          => 'https://api-v2.hyber.im/' . $conf->{GMS_WORLDWIDE_CLIENT_ID},
    CONTACT_TYPE => 1,
  };

  bless $self, $class;

  return $self;
}

#**********************************************************
=head2 send_message() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;
  
  my %message_params;
  `echo "SENDING MESSAGE" >> /tmp/buffer`;
  $message_params{phone_number}   = $attr->{TO_ADDRESS}; # user phone
  $message_params{is_promotional} = $attr->{IS_PROMOTIONAL} ? 'true' : 'false' ; # promotional or normal
  $message_params{channels}       = $attr->{CHANNELS} ? [split(',\s+', $attr->{CHANNELS})] : ['viber', 'sms', 'push']; # channels to send
  $message_params{start_time}     =  ''; # planning date time for send

  # PARAMS FOR SMS
  if(in_array('sms', $message_params{channels})){
    $message_params{channel_options}{sms}{text}       = $attr->{MESSAGE} || ''; # message text
    $message_params{channel_options}{sms}{aplha_name} = 'test'; # 
    $message_params{channel_options}{sms}{ttl}        = '15';   # min 15, max 86400
  }

  # PARAMS FOR PUSH
  if(in_array('push', $message_params{channels})){
    $message_params{channel_options}{push}{text}      = $attr->{MESSAGE} || ''; # message text
    $message_params{channel_options}{push}{ttl}       = '15'; # min 15, max 86400
    $message_params{channel_options}{push}{title}     = $attr->{SUBJECT} || '';
    $message_params{channel_options}{push}{img}       = $attr->{IMAGE}   || ''; # link to image
    $message_params{channel_options}{push}{caption}   = $attr->{CAPTION} || ''; # button name
    $message_params{channel_options}{push}{action}    = $attr->{ACTION}  || ''; # link to redirect on click
  }

  # PARAMS FOR VIBER
  if(in_array('viber', $message_params{channels})){
    $message_params{channel_options}{viber}{text}     = $attr->{MESSAGE} || '';
    $message_params{channel_options}{viber}{ttl}      = '15';
    $message_params{channel_options}{viber}{img}      = $attr->{IMAGE}   || '';
    $message_params{channel_options}{viber}{caption}  = $attr->{CAPTION} || '';
    $message_params{channel_options}{viber}{action}   = $attr->{ACTION}  || '';
    $message_params{channel_options}{viber}{ios_expirity_text} = $attr->{IOS_EXPIRITY_TEXT}  || ''; 
  }

  my $json_message_params = to_json(\%message_params);

  print $json_message_params;

  my $result_json = web_request($self->{url},
  {
     POST => { $json_message_params }
  });
  
  my $result = from_json($result_json);

  if($result->{message_id}){
    return 'OK';
  }
  else{
    return 'ERROR';
  }  

}

1;