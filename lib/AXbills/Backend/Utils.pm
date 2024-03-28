package AXbills::Backend::Utils;
use strict;
use warnings FATAL => 'all';

our (@ISA, @EXPORT, @EXPORT_OK);
BEGIN {
  require Exporter;
  @ISA = qw(Exporter);
  
  @EXPORT = ();
  
  @EXPORT_OK = qw(
    json_decode_safe
    json_encode_safe
    );  # symbols to export on request
}

use JSON;

my $json = JSON->new->utf8(1)->allow_nonref(1);

#**********************************************************
=head2 json_decode_safe($json_string)

  Arguments:
    $json_string -
    $return_error_flag - will return error string if any
    
  Returns:
  
=cut
#**********************************************************
sub json_decode_safe {
  my ($json_string, $return_error_flag) = @_;
  
  my $res = 0;
  
  eval {
    $res = $json->decode($json_string);
  };
  if ($@ && $return_error_flag){
    return $@;
  }
  
  
  return $res;
}



#**********************************************************
=head2 json_encode_safe()

=cut
#**********************************************************
sub json_encode_safe {
  my ($data) = @_;
  
  my $res = '';
  eval {
    $res = $json->encode($data);
  };
  
  if ( $@ ) {
    print $@;
    return 0;
  }
  
  return $res;
}

1;