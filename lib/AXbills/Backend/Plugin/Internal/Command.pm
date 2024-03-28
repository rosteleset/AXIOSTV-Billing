package AXbills::Backend::Plugin::Internal::Command;
use strict;
use warnings FATAL => 'all';
use threads 'exit' => 'threads_only';

use AXbills::Backend::Log;
our AXbills::Backend::Log $Log;
my $log_user = ' Internal::Command ';
use AXbills::Backend::Defs;

use AXbills::Base qw/cmd _bp/;

use AnyEvent;

#**********************************************************
=head2 new($prog_name, $args) - constructor for AXbills::Backend::Plugin::Internal::Command

  Arguments
    $prog_name - string, full name of program to run
    $args      - AXbills::Base::cmd arguments

=cut 
#**********************************************************
sub new {
  my $class = shift;
  my ($prog_name, $args) = @_;
  
  my $self = {};
  
  $self->{program} = $prog_name;
  $self->{args} = $args || {};
  
  # Ignore AXbills::Base::cmd alarm timeout system
  
  # Default timeout : 10 minutes
  $self->{timeout} = $args->{timeout} || 600;
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 run() - 

  Arguments:
     $cb->($status, $output) - code_ref will be called with $result
    
  Returns:
    1
    
=cut
#**********************************************************
sub run {
  my ($self, $cb) = @_;
  
  # Construct what thread will do
  $self->{runnable} //= sub {
    my $result = '';
    
    $SIG{STOP} = sub {exit 1};
    
    # Run cmd
    eval {
      $result = cmd($self->{program}, $self->{args})
    };
    
    # Return result
    $cb->(0, $result);
  };
  
  # Create thread
  my $thread = threads->new({ 'exit' => 'thread_only' }, $self->{runnable});
  
  # Delete thread when done
  $thread->detach();
  
  # Owerwrite AXbills::Base::cmd SIGALRM
  $SIG{ALRM} = sub {
    $Log->debug($self->{program} . " exit on timeout ");
    
    # Callback as error
    $cb->(1, 'Timeout');
    
    # Kill thread
    $thread->kill('STOP');
  };
  
  return 1;
}

1;
