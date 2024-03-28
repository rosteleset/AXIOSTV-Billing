package AXbills::Backend::Plugin::Satellite::API;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Backend::Plugin::Satellite::API

=head2 SYNOPSIS

  API to Satellite plugin

=cut

use base 'AXbills::Backend::Plugin::BaseAPI';
use AXbills::Backend::Plugin::Satellite::Server;


#**********************************************************
=head2 process_internal_message($data) -

  Arguments:
    $data -
      TYPE
      CLIENT_ID
      DATA
      
  Returns:
  
  
=cut
#**********************************************************
sub process_internal_message {
  my ($self, $data) = @_;

  my $control_plugin = $self->{plugin_object};
  
  my $check_keys = sub {
    my (@keys) = @_;
    if ( my $missing_keys = _check_data_keys($data, @keys) ) {
      return qq/{"TYPE":"ERROR","ERROR":"NO REQUIRED KEYS:$missing_keys"}/;
    }
  };
  
  if ( !$data->{TYPE} ) {
    return q/{"TYPE":"ERROR","ERROR":"NO TYPE SPECIFIED"}/;
  }
  #  elsif ($data->{TYPE} eq 'CALL'){
  #    $check_keys->(qw//);
  #
  #  }
  #  elsif ($data->{TYPE} eq 'REMOTE_CALL'){
  #    $check_keys->(qw//);
  #
  #  }
  elsif ( $data->{TYPE} eq 'SERVICE_REBOOT' ) {
    $check_keys->(qw/SERVICE_NAME SERVER_ID/);
    
    my AXbills::Backend::Plugin::Satellite::Server $server = $control_plugin->{server};
    $server->postpone_service_restart($data->{SERVER_ID}, $data->{SERVICE_NAME});
    
    return {
      TYPE   => "RESPONSE",
      RESULT => "OK",
    };
  }
  elsif ( $data->{TYPE} eq 'SERVICE_STATUS' ) {
    $check_keys->(qw/SERVICE_NAME/);
    
    my AXbills::Backend::Plugin::Satellite::Server $server = $control_plugin->{server};
    return {
      TYPE   => "RESPONSE",
      RESULT => "OK",
      STATUS => $server->{statuses}->{$data->{SERVICE_NAME}}
    };
  }
  
  return 0;
}

#**********************************************************
=head2 _check_data_keys()

=cut
#**********************************************************
sub _check_data_keys {
  my ($data, @required_keys) = @_;
  return join (', ', grep {!exists $data->{$_}} @required_keys);
}

1;