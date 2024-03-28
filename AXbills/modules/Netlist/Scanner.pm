package Netlist::Scanner;
use strict;
use warnings FATAL => 'all';

use Nmap::Parser;
use AXbills::Base qw/cmd _bp startup_files/;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
    nmap  => $CONF->{NMAP_LOCATION} || q{}
  };

  unless ( $self->{nmap} ) {
    my @predefined_nmap_locations = (
      '/usr/bin/nmap',
      '/usr/bin/snmap',
      '/usr/local/bin/nmap',
      '/usr/local/sbin/nmap'
    );
    foreach my $location ( @predefined_nmap_locations ) {
      if ( -f $location ) {
        $self->{nmap} = $location;
        last;
      }
    }
    
    if (!$self->{nmap}){
      my $which = `which nmap`;
      if ($which){
        chomp $which;
        $self->{nmap} = $which;
      }
    }
    
    return { errno => 404, errstr => "Nmap not found. Set \$conf{NMAP_LOCATION}" } if (!$self->{nmap});
  }

  bless( $self, $class );

  return $self;
}

#**********************************************************
=head2 set_nmap_location($filename) - sets nmap location

  Arguments:
    $filename - filename for nmap

  Returns:
    1

=cut
#**********************************************************
sub set_nmap_location {
  my $self = shift;
  my ($filename) = @_;

  $self->{nmap} = $filename;

  return 1;
}

#**********************************************************
=head2 set_target($target) - Sets target for this scan

  Arguments:
    $target - corect ip range in CIDR notation

  Returns:
    boolean - 1

=cut
#**********************************************************
sub set_target {
  my $self = shift;
  my ($target) = @_;

  $self->{target} = $target;

  return 1;
}

#**********************************************************
=head2 set_timeout($ms) - sets timeout

  Arguments:
    $ms - milliseconds

  Returns:
    1

=cut
#**********************************************************
sub set_timeout {
  my $self = shift;
  my ($ms) = @_;
  $self->{timeout} = $ms . 'ms';
  return 1;
}

#**********************************************************
=head2 scan() - start_scan

  Runs nmap scan, parses results using Nmap::Parser, and returns parsed results

  Returns:
    hash_ref -
      %IP_ADDRESS%
        STATUS
        ...

=cut
#**********************************************************
sub scan {
  my $self = shift;

  my $ping_only_option = ' -sP -n ';
  my $timeout_option = '--max-rtt-timeout ' . ($self->{timeout} || 1);
  my $command = "$ping_only_option $timeout_option";

  my $parser = Nmap::Parser->new;
  
  my $start_programs = startup_files();
  
  if (!$start_programs->{SUDO} || !-e $start_programs->{SUDO}){
    return {
      errno => 1,
      errstr => 'No sudo in AXbills/programs'
    }
  }
  
  my $sudo_name = $start_programs->{SUDO};
  eval{  $parser->parsescan( "$sudo_name $self->{nmap}", $command, $self->{target} ) };
  if ($@) {
    return {errstr => "$@", errno=>2301};
  }

  # Saving reference to save scan results
  $self->{parser} = $parser;

  return $self->_prepare_results( $parser );
}

#**********************************************************
=head2 _prepare_results($parser) - Collects results from Nmap::Parser to pure parl hash

  Arguments:
    $parser - Nmap::Parser containing results

  Returns:
    hash_ref - 'up' hosts state with gathered information
      IP_ADDRESS
        hash_ref
=cut
#**********************************************************
sub _prepare_results {
  my $self = shift;
  my Nmap::Parser $parser = shift;

  my %results = ();
  _bp('Hosts', $parser, $self->{bp_args}) if ($self->{debug});
  my @hosts = $parser->all_hosts( 'up' );
  _bp('Hosts', \@hosts, $self->{bp_args} ) if ($self->{debug});
  foreach my Nmap::Parser::Host $host ( @hosts ) {

    my %host_info = ();
    $host_info{mac_addr} = $host->mac_addr;
    $host_info{mac_vendor} = $host->mac_vendor;
    $host_info{hostname} = $host->hostname;

    $results{$host->ipv4_addr} = \%host_info;

    _bp('Host ' . $host->ipv4_addr, $host, $self->{bp_args}) if ($self->{debug});
    _bp('Host ' . $host->ipv4_addr, \%host_info, $self->{bp_args}) if ($self->{debug});
  }

  return \%results;
}



1;