package AXbills::Backend::PubSub;
use strict;
use warnings FATAL => 'all';

use AXbills::Backend::Log;
our AXbills::Backend::Log $Log;

#use AXbills::Backend::Defs;

#**********************************************************
=head2 new() - constructor for PubSub

=cut
#**********************************************************
sub new {
  my $class = shift;
  
  my $self = {
    topics => {},
    debug  => 0
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 debug($level)

  Arguments:
    $level|undef - getter/setter
  
  Returns:
    current log level
    
=cut
#**********************************************************
sub debug {
  my $self = shift;
  my ($level) = @_;
  
  if ( defined $level ) {
    $self->{debug} = $level;
  }
  
  return $self->{debug};
}

#**********************************************************
=head2 on($topic, $listener)
 
 Sets callback for '$topic' event

=cut
#**********************************************************
sub on {
  my $self = shift;
  my ($topic, $handler) = @_;
  
  $self->{topics}->{$topic} //= [];
  push(@{$self->{topics}->{$topic}}, $handler);
  
  return;
}

#**********************************************************
=head2 once($topic, $handler)
 
 Sets callback for '$topic' that will be runned only once

=cut
#**********************************************************
sub once {
  my $self = shift;
  my ($topic, $handler) = @_;
  
  # Defining wrapper for handler to remove it from self scope
  my $sub;
  $sub = sub {
    # Run original handler
    $handler->(shift);
    
    # Then remove it
    $self->off($topic, $sub);
  };
  
  return $self->on($topic, $sub);
}

#**********************************************************
=head2 off($topic, $handler)
 
 Removes '$handler' for '$topic' or all if $topic is undef

=cut
#**********************************************************
sub off {
  my $self = shift;
  my ($topic, $handler) = @_;
  
  if ( !defined $handler ) {
    $self->{topics}->{$topic} = [];
  }
  else {
    @{$self->{topics}->{$topic}} = grep {$_ ne $handler} @{$self->{topics}->{$topic}};
  }
  
  return;
}

#**********************************************************
=head2 emit($topic, $data)

  Runs all handlers for '$topic' with '$data' as first arg
  
=cut
#**********************************************************
sub emit {
  my $self = shift;
  my ($topic, $data) = @_;
  
  if ( $self->{debug} && $Log ) {
    $Log->debug(' PubSub ', 'emitted ' . $topic);
  }
  
  if ( $self->{topics}->{$topic} ) {
    $_->($data) foreach ( @{$self->{topics}->{$topic}} );
  }
  
  return;
}

1;
