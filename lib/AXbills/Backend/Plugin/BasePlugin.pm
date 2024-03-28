package AXbills::Backend::Plugin::BasePlugin;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Backend::BasePlugin - hierarchical parent for all Backend Plugins

=head2 SYNOPSIS

  This package defines and describes interface for Backend plugins

=cut

use AXbills::Backend::Plugin::BaseAPI;

#**********************************************************
=head2 new($CONF)

  Arguments:
    $CONF  - ref to %conf
    
  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($CONF) = @_;
  
  my $self = {
    conf => $CONF,
  };
  
  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 init($attr)

  Init plugin (start servers, check params, etc)
  
  Returns:
    API to control plugin
    
=cut
#**********************************************************
sub init {
  my $self = shift;
  my ($attr) = @_;
  $self->{api} = AXbills::Backend::Plugin::BaseAPI->new($self->{conf}, $attr);
  return $self->{api};
};

1;
