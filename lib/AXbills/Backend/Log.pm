package AXbills::Backend::Log;
use strict;
use warnings FATAL => 'all';

our $VERSION = 1.0;

our $LEVEL_EMERG = 0;
our $LEVEL_ALERT = 1;
our $LEVEL_CRIT = 2;
our $LEVEL_ERR = 3;
our $LEVEL_WARNING = 4;
our $LEVEL_NOTICE = 5;
our $LEVEL_INFO = 6;
our $LEVEL_DEBUG = 7;

my %old_levels = (
  LOG_EMERG   => 0,
  LOG_ALERT   => 1,
  LOG_CRIT    => 2,
  LOG_ERR     => 3,
  LOG_WARNING => 4,
  LOG_NOTICE  => 5,
  LOG_INFO    => 6,
  LOG_DEBUG   => 7,
  LOG_SQL     => 8,
);

our %STR_LEVEL = (
  0 => 'EMERG',   #   KERN_EMERG             0        System is unusable
  1 => 'ALERT',   #   KERN_ALERT             1        Action must be taken immediately
  2 => 'CRIT',    #   KERN_CRIT              2        Critical conditions
  3 => 'ERR',     #   KERN_ERR               3        Error conditions
  4 => 'WARNING', #   KERN_WARNING           4        Warning conditions
  5 => 'NOTICE',  #   KERN_NOTICE            5        Normal but significant condition
  6 => 'INFO',    #   KERN_INFO              6        Informational
  7 => 'DEBUG',   #   KERN_DEBUG             7        Debug-level messages
);

use parent 'Exporter';

my @levels = qw/
  $LEVEL_EMERG
  $LEVEL_ALERT
  $LEVEL_CRIT
  $LEVEL_ERR
  $LEVEL_WARNING
  $LEVEL_NOTICE
  $LEVEL_INFO
  $LEVEL_DEBUG
  /;

our @EXPORT = (@levels);
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = ('levels' => \@levels);

use Data::Dumper;

#**********************************************************
=head2 new($type, $level, $label, $attr) - constructor for AXbills::Backend::Log

  Arguments:
    $type   - logging type (currently only 'FILE' and 'STDOUT' are supported)
    $level  - log level (using same levels as syslog)
    $label  - default log message label
    $attr   - hash_ref, attributes for specified type
      FILE - (type:FILE) filepath

=cut
#**********************************************************
sub new {
  my $class = shift;
  
  my ($type, $level, $label, $attr) = @_;
  
  $type //= 'STDOUT';
  $level //= $LEVEL_DEBUG;
  
  my $self = {
    type  => $type,
    level => $level,
    label => $label || @{[ caller() ]}[0]
  };
  
  if ( $type eq 'STDOUT' ) {
    require AXbills::Backend::Log::File;
    AXbills::Backend::Log::File->import();
    $self->{logger} = AXbills::Backend::Log::File->new(\*STDOUT);
  }
  elsif ( $type eq 'FILE' ) {
    require AXbills::Backend::Log::File;
    AXbills::Backend::Log::File->import();
    $self->{logger} = AXbills::Backend::Log::File->new($attr->{FILE});
  }
  else {
    die "Non supported log type specified at " . join(', ', caller) . "\n";
  }
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 _add_to_log($message) -

=cut
#**********************************************************
sub _add_to_log {
  my ($self, $level, $message, $label) = @_;
  
  if ( !$message ) {
    $message = "Empty log message at " . join(', ', caller[ 0, 2 ]);
  }
  
  # Construct time
  my $time = POSIX::strftime("%F %T", localtime(time()));
  $label //= $self->{label};
  
  if ( ref $message ) {
    $message = Dumper($message);
  }
  
  $self->{logger}->log($time, $label, $level, $message);
  
  return;
}

#**********************************************************
=head2 set_label($new_label) - changes label for log

  Arguments:
    $new_label - string, new default label
    
  Returns:
    1
    
=cut
#**********************************************************
sub set_label {
  my ($self, $new_label) =  @_;
  
  $self->{label} = $new_label if ($new_label);
  
  return 1;
}

#**********************************************************
=head2 log_print($level_str, $label, $message) - old style call

  Arguments:
    $level_str
    $label
    $message
    
=cut
#**********************************************************
sub log_print {
  my ($self, $level_str, $label, $message) = @_;
  
  $self->notice('Old style $Log->log_print called at ' . join(', ', caller));
  my $new_level = $old_levels{$level_str} || 0;
  
  return unless ( $self->{level} <= $new_level );
  
  $self->_add_to_log($new_level, $message, $label);
  
  return;
}

#**********************************************************
=head2 emergency($message) - adds string to log

=cut
#**********************************************************
sub emergency {
  my ($self, $message, $label) = @_;
#  return if ( $self->{level} < $LEVEL_EMERG );
  $self->_add_to_log($LEVEL_EMERG, $message, $label);
  return;
}


#**********************************************************
=head2 alert($message) - adds string to log if level is less than alert

=cut
#**********************************************************
sub alert {
  my ($self, $message, $label) = @_;
  return if ( $self->{level} < $LEVEL_ALERT );
  $self->_add_to_log($LEVEL_ALERT, $message, $label);
  return;
}


#**********************************************************
=head2 critical($message) - adds string to log if level is less than critical

=cut
#**********************************************************
sub critical {
  my ($self, $message, $label) = @_;
  return if ( $self->{level} < $LEVEL_CRIT );
  $self->_add_to_log($LEVEL_CRIT, $message, $label);
  return;
}


#**********************************************************
=head2 error($message) - adds string to log if level is less than error

=cut
#**********************************************************
sub error {
  my ($self, $message, $label) = @_;
  return if ( $self->{level} < $LEVEL_ERR );
  $self->_add_to_log($LEVEL_ERR, $message, $label);
  return;
}

#**********************************************************
=head2 warning($message) - adds string to log if level is less than warning

=cut
#**********************************************************
sub warning {
  my ($self, $message, $label) = @_;
  return if ( $self->{level} < $LEVEL_WARNING );
  $self->_add_to_log($LEVEL_ERR, $message, $label);
  return;
}

#**********************************************************
=head2 notice($message) - adds string to log if level is less than notice

=cut
#**********************************************************
sub notice {
  my ($self, $message, $label) = @_;
  return if ( $self->{level} < $LEVEL_NOTICE );
  $self->_add_to_log($LEVEL_NOTICE, $message, $label);
  return;
}


#**********************************************************
=head2 info($message) - adds string to log if level is less than info

=cut
#**********************************************************
sub info {
  my ($self, $message, $label) = @_;
  return if ( $self->{level} < $LEVEL_INFO );
  $self->_add_to_log($LEVEL_INFO, $message, $label);
  return;
}


#**********************************************************
=head2 debug($message) - adds string to log if level is less than debug

=cut
#**********************************************************
sub debug {
  my ($self, $message, $label) = @_;
  return if ( $self->{level} < $LEVEL_DEBUG );
  $self->_add_to_log($LEVEL_DEBUG, $message, $label);
  return;
}

1;