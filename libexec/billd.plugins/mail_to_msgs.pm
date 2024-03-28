use Msgs;
use AXbills::Base;
use Mail::POP3Client;

my $Msgs = Msgs->new($db, $admin, \%conf);



mail_to_msgs();

#**********************************************************
=head2 mail_to_msgs() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub mail_to_msgs {
  my ($attr) = @_;

  if(!$conf{MAIL_TO_MSGS}){
    print "Add mail_to_msgs config param\n";
    return 0;
  }

  my ($username, $password, $host, $use_ssl) = split(':', $conf{MAIL_TO_MSGS});

  my $pop = new Mail::POP3Client( USER     => "$username",
                                  PASSWORD => "$password",
                                  HOST     => "$host",
                                  USESSL   => "$use_ssl",
                                );
  my $Msgs = Msgs->new($db, $admin, \%conf);

  my $messages_couunt = $pop->Count();

  for (my $i = 1; $i <= $messages_couunt; $i++ ){
    my $message_body   = $pop->Body($i);
    my $message_header = $pop->Head($i);
    my $boundary;

    if($message_header =~ /Content-Type: text\/plain/i){
      # my ($id) = $plain_text =~ />ID: (\d+)/gm;
      # my ($text_to_axbills) = $plain_text =~ /(.+)\n\n\n/gm;

      # print "$message_body";
    }
    elsif($message_header =~ /Content-Type: multipart\/alternative/i){
      print "Html + plain text";
      if($message_header =~ /boundary="(.+)"/i){
        $boundary = $1;
        # print "Boundary = $boundary";
      }

      my @messages = split($boundary, $message_body);
      my $plain_text;
      foreach my $message (@messages){
        my ($content_type, $text_plain_base64) = split('\n\r\n', $message);
        if($content_type =~ /text\/plain/){
          $plain_text = decode_base64($text_plain_base64);
        }
      }
      
      my ($id) = $plain_text =~ />ID: (\d+)/gm;
      my ($text_to_axbills) = $plain_text =~ /((.|\s)*?)\>/m;
      
      if($id ne '' && $text_to_axbills ne ''){
        $Msgs->message_reply_add({  ID => $id, 
                                  REPLY_TEXT => $text_to_axbills, 
                                  STATE => 0});

        if(!$Msgs->{errno}){
          $pop->Delete($i);
        }
      }
    }
    else{ 
      print "ok" 
    }
  }

  $pop->Close();

  return 1;
}


1