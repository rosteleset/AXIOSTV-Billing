package AXbills::Backend::Log::File;
use strict;
use warnings FATAL => 'all';

our $VERSION = 1.0;

use AnyEvent;
use AnyEvent::Handle;

use POSIX qw/sprintf/;

my %file_handles = ();
#**********************************************************
=head2 new($file_qualifier, $current_level, $attr)

  Arguments:
    $file_qualifier
    $current_level
    $attr
    
  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  
  my ($file_qualifier) = @_;
  
  $file_qualifier //= \*STDOUT;
  
  my $self = {
    file => $file_qualifier,
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 log($time, $label, $level, $message)

  Arguments:
    $level, $label, $message -
    
  Returns:
  
=cut
#**********************************************************
sub log {
  my ($self, $time, $label, $level, $message) = @_;
  
  my $hdl = _get_handle_for_file($self->{file});
  
  $hdl->push_write(
    POSIX::sprintf(
      "[%s] [ %-10s ]%-6s: %s\n",
      $time,
      $label,
      $AXbills::Backend::Log::STR_LEVEL{$level} // 'DEBUG',
      $message
    )
  );

  # Set timeout, so connection to file is opened once a minute
  $self->{timeout} //= AnyEvent->timer(
    after => 60,
    cb => sub {
      my $file_name = $self->{file};
      if (exists $file_handles{$file_name} && ($file_handles{$file_name} && !$file_handles{$file_name}->destroyed())){
        # This will destroy fh and forces to recreate it on next log operation
        $file_handles{$file_name}->destroy();
      }
    }
  );
}



#**********************************************************
=head2 _get_handle_for_file($file_name) -

  Arguments:
    $file_name -
    
  Returns:
  
  
=cut
#**********************************************************
#@returns AnyEvent::Handle
sub _get_handle_for_file {
  my ($file_name) = @_;
  
  if ( !exists $file_handles{$file_name} || ($file_handles{$file_name} && $file_handles{$file_name}->destroyed()) ) {
    
    my $log_fh;
    if ( !ref $file_name ) {
      open ($log_fh, '>>', $file_name) or die "Content-Type:text/html;\n\nCan't open $file_name : $@";
    }
    elsif ( ref $file_name eq 'GLOB' ) {
      $log_fh = $file_name
    }
    
    my AnyEvent::Handle $handle = AnyEvent::Handle->new(
      fh       => $log_fh,
      no_delay => 1,
      on_error => sub {
        print "Error on log ";
      }
    );
    
    $file_handles{$file_name} = $handle;
  }
  
  return $file_handles{$file_name};
}

1;