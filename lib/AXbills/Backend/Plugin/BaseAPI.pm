package AXbills::Backend::Plugin::BaseAPI;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Backend::Plugin::BaseAPI - 

=head2 SYNOPSIS

  This package  

=cut

#**********************************************************
=head2 new($conf, $plugin_object) - constructor for AXbills::Backend::Plugin::API

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($CONF, $plugin_object) = @_;
  
  my $self = {
    conf          => $CONF,
    plugin_object => $plugin_object
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 process_internal_message($data) - dummy for sub

  Arguments:
    $data - hash_ref
    
  Returns:
    this one returns error string
    
=cut
#**********************************************************
sub process_internal_message {
  return { "TYPE" => "ERROR", "ERROR" => "NOT IMPLEMENTED" };
}

1;
