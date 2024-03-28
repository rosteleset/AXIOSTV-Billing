=head1 NAME

 create ISC DHCP conf file

=head1 ARGUMENTS

  CONFIG=/etc/dhcp.conf
  DEBUG=1..5
  STATIC_ONLY=1

=cut

use strict;
use warnings FATAL => 'all';

use Socket;
use FindBin '$Bin';
use AXbills::Base qw(int2ip ip2int);
use AXbills::HTML;
require AXbills::Misc;

our (
  $db,
  %conf,
  $admin,
  %lang,
  %permissions,
  %FORM,
  $argv,
  $Bin
);

my $Internet = Internet->new($db, $admin, \%conf);
my $Nas = Nas->new($db, \%conf, $admin);
push @INC, $Bin.'/../';

isc_dhcp_config();

#**********************************************************
=head2 isc_dhcp_config() - make_config

=cut
#**********************************************************
sub isc_dhcp_config {

  our $html = AXbills::HTML->new(
    {
      CONF => \%conf,
    }
  );

  my $static_networks;

  if ($argv->{STATIC_ONLY}) {
    $static_networks = 1;
  }

  $html->{language} = '';
  require AXbills::Templates;

  my $debug = 0;
  my $filename = $conf{INTERNET_ISC_DHCP_CONFIG};

  if ($argv->{DEBUG}) {
    $debug = $argv->{DEBUG};
    if ($debug > 6) {
      $Nas->{debug} = 1;
    }
  }

  if ($argv->{CONFIG}) {
    $filename = $argv->{CONFIG};
  }

  if (!$filename) {
    print 'ERROR: $conf{INTERNET_ISC_DHCP_CONFIG} is empty';
    exit;
  }

  my $networks = $Nas->nas_ip_pools_list({
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    IP         => '_SHOW',
    STATIC     => $static_networks,
    NETMASK    => '_SHOW',
    GATEWAY    => '_SHOW',
    NAME       => '_SHOW',
    FIRST_IP   => '_SHOW',
    LAST_IP    => '_SHOW',
    PAGE_ROWS  => 60000,
  });

  _error_show($Nas);

  my $subnet_tpls //= '';
  my %subnet_params = ();

  foreach my $subnet (@{$networks}) {
    $subnet->{RANGE} = 'range ' . $subnet->{FIRST_IP} . ' ' . $subnet->{LAST_IP} . ';';
    my $mask_num = $subnet->{NETMASK};
    my $address_int = 0 + $subnet->{IP} & 0 + $mask_num;

    $subnet->{SUBNET}  = int2ip($address_int);
    $subnet->{NETMASK} = int2ip($mask_num);
    $subnet->{GATEWAY} = int2ip($subnet->{GATEWAY}) if ($subnet->{GATEWAY});
    $subnet_params{$subnet->{ID}}{FIRST_IP}=$subnet->{IP};
    $subnet_params{$subnet->{ID}}{LAST_IP}=ip2int($subnet->{LAST_IP});
    $subnet_params{$subnet->{ID}}{NETMASK}=$subnet->{NETMASK};
    $subnet_params{$subnet->{ID}}{GATEWAY}=$subnet->{GATEWAY};
    $subnet_params{$subnet->{ID}}{SUBNET_ID}=$subnet->{ID};

    if($mask_num == 4294967295) {
      next;
    }
    if($debug > 1) {
      print "SUBNET: " . int2ip($address_int) . " MASK: " . $subnet->{NETMASK} . "\n";
    }

    $subnet_tpls .= $html->tpl_show(_include('internet_isc_dhcp_conf_subnet', 'Internet'), { %$subnet }, { OUTPUT2RETURN => 1 }) . "\n";
  }

  my $hosts = $Internet->user_list({
    COLS_NAME      => 1,
    COLS_UPPER     => 1,
    LOGIN          => '_SHOW',
    INTERNET_LOGIN => '_SHOW',
    CID            => '*',
    IP_NUM         => '>0',
    GROUP_BY       => 'internet.id',
    PAGE_ROWS      => 100000,
  });
  _error_show($Internet);

  my $hosts_tpls //= '';

  foreach my $host (@{$hosts}) {
    if($host->{CID} !~ /^[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}$/i) {
      next;
    }
    $host->{IP} = int2ip($host->{IP_NUM});
    my $subnet_info = subnet_params($host->{IP}, \%subnet_params);
    $hosts_tpls .= $html->tpl_show(_include('internet_isc_dhcp_conf_host', 'Internet'),
      { %$subnet_info, %$host },
      { OUTPUT2RETURN => 1 });
  }

  my $conf_main = $html->tpl_show(_include('internet_isc_dhcp_conf_main', 'Internet'),
    {
      SUBNETS => $subnet_tpls,
      HOSTS   => $hosts_tpls,
      DATE    => $DATE
    },
    { OUTPUT2RETURN => 1 }
  ) . "\n";

  if ($debug > 7) {
    print $conf_main;
  }
  else {
    open(my $fh, '>', $filename) or die "ERROR: Can`t open filename. Edit " . '$conf{INTERNET_ISC_DHCP_CONFIG}.' . " $!\n";
    print $fh $conf_main;
    close $fh;
  }

  if ($debug > 1) {
    print 'The configuration file was successfully created' . "\n";
  }

  return 1;
}


#**********************************************************
=head2 subnet_params($ip, $subnets_hash) - make_config

  Arguments:
    $ip
    $subnets_hash

  Results:
    subnet_info

=cut
#**********************************************************
sub subnet_params {
  my($ip, $subnet)=@_;

  my $id = 0;
  my $ip_num = ip2int($ip);

  foreach my $subnet_id ( keys %$subnet ) {
    my $first_ip = $subnet->{$subnet_id}->{FIRST_IP};
    my $last_ip  = $subnet->{$subnet_id}->{LAST_IP};
    if($first_ip <= $ip_num && $ip_num <= $last_ip) {
      $id = $subnet_id;
      last;
    }
  }

  if (! $id) {
    print "$id - $ip\n";
  }

  return ($id)  ? $subnet->{$id} : {};
}

1;