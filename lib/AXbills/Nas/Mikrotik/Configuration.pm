package AXbills::Nas::Mikrotik::Configuration;
use strict;
use warnings FATAL => 'all';

use POSIX qw/strftime/;

our ($DATE, $TIME, $base_dir);

$base_dir ||= '/usr/axbills';

#**********************************************************
=head2 new($nas_id, \%conf, $attr)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($nas_id, $conf, $attr) = @_;

  return 0 if (!$nas_id);

  my $self = {
    nas_id => $nas_id
  };
  bless($self, $class);

  my $print_args = sub {print join('', @_)};
  $self->{MESSAGE_CB} = $attr->{MESSAGE_CB} || $print_args;
  $self->{ERROR_CB} = $attr->{ERROR_CB} || $print_args;

  # Check configuration directory
  my $tpl_dir = $conf->{TPL_DIR} || ($base_dir . '/AXbills/templates');
  my $config_dir = $tpl_dir . '/mikrotik_configs';
  if ((!-d $config_dir) && !mkdir ($config_dir)) {
    $self->{ERROR_CB}->('Error', "Can't create configuration dir $config_dir : " . ($! || ''));
    return 0;
  }

  $self->{config_dir} = $config_dir;
  $self->{config_file} = $self->{config_dir} . '/' . $self->{nas_id} . '.conf';

  $self->{fields} = [
    qw/CONNECTION_TYPE
    PPPOE_INTERFACE
    RADIUS_IP
    RADIUS_HANGUP
    IP_POOL
    IP_POOL_RANGE
    FLOW_COLLECTOR
    FLOW_PORT
    FLOW_INTERFACE
    DNS
    USE_NAT
    NAS_ID
    ALIVE
    SSH_BRUTEFORCE
    DNS_FLOOD
    INTERNAL_NETWORK
    NEGATIVE_BLOCK
    NEGATIVE_REDIRECT/
  ];

  $self->read();

  return $self;
}


#**********************************************************
=head2 read() - reads current configuration from file
  
  Returns:
    boolean
    
=cut
#**********************************************************
sub read {
  my ($self) = @_;

  our $VAR1 = {};

  if (-e $self->{config_file}) {
    eval {
      require $self->{config_file};
    };
  }

  $self->{config} = $VAR1;

  return 1;
}

#**********************************************************
=head2 save() - saves current configuration to file
  
  Returns:
    boolean
    
=cut
#**********************************************************
sub save {
  my $self = shift;

  open (my $config_file, '>', $self->{config_file}) or do {
    $self->{ERROR_CB}->('ERROR', "Can't save config to $self->{config_file} : $!");
    return 0;
  };

  $DATE //= POSIX::strftime "%Y-%m-%d", localtime(time);;
  $TIME //= POSIX::strftime "%H:%M:%S", localtime(time);;

  $self->{config}->{UPDATED} = "$DATE $TIME";

  require Data::Dumper;
  my $dumped_config = Data::Dumper::Dumper($self->{config});

  print $config_file $dumped_config;

  return 1;
}

#**********************************************************
=head2 set($params_hash_ref) - updates config with new values

  Arguments:
    $params_hash_ref
    
  Returns:
    1
    
=cut
#**********************************************************
sub set {
  my ($self, %params) = @_;

  return if (!%params);

  # Filter necessary params from %FORM
  my %new_config = ();
  foreach my $field_name (@{$self->{fields}}) {
    next if (!exists $params{$field_name});
    $new_config{$field_name} = $params{$field_name . '_ADD'} || $params{$field_name};
  }

  foreach my $param_name (keys %new_config) {
    $self->{config}->{$param_name} = $new_config{$param_name};
  }

  return 1;
}

#**********************************************************
=head2 get() - returns current configuration

  Arguments:
     -
    
  Returns:
  
  
=cut
#**********************************************************
sub get {
  my ( $self, $param ) = @_;

  return (defined $param)
    ? $self->{config}->{$param}
    : $self->{config};
}

#**********************************************************
=head2 clear()

=cut
#**********************************************************
sub clear {
  my ($self) = @_;

  $self->{config} = {};
  unlink $self->{config_file};

  return 1;
}


1;