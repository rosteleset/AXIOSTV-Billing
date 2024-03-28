package AXbills::Nas::Mikrotik;
use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(_bp cmd);
require "AXbills/Misc.pm";

our $CONNECTION_TYPE_FREERADIUS_DHCP = 'freeradius_dhcp';
our $CONNECTION_TYPE_HOTSPOT = 'hotspot';
our $CONNECTION_TYPE_PPPOE = 'pppoe';
our $CONNECTION_TYPE_PPPTP = 'ppptp';
our $CONNECTION_TYPE_IPN = 'ipn';

my %BP_ARGS = (TO_CONSOLE => 1);
#**********************************************************
=head2 new($host, $CONF, $attr) - Constructor

  Arguments:
    $host
    $CONF
    $attr
      API_BACKEND

  Return:
    $executor

=cut
#**********************************************************
sub new($;$) {
  my $class = shift;
  my ($host, $CONF, $attr) = @_;

  my $self = {};
  bless($self, $class);

  $self->{nas_id} = $host->{NAS_ID} || $host->{nas_id};

  $self->{nas_mng_password} = $host->{NAS_MNG_PASSWORD} || $host->{nas_mng_password};
  $self->{password}=$self->{nas_mng_password};
  my $nas_ip_mng_port = $host->{NAS_MNG_IP_PORT} || $host->{nas_mng_ip_port} || q{};

  if (!$nas_ip_mng_port) {
    return 0;
  }

  my ($nas_ip, $coa_port, $management_port) = split(":", $nas_ip_mng_port);

  if($attr->{API_BACKEND}) {
    $management_port = '8728';
  }
  else {
    $management_port ||= $coa_port || '22';
  }

  $self->{backend} = $attr->{backend} || (($management_port eq '8728') ? 'api' : 'ssh');

  $self->{ip_address} = $nas_ip || $host->{NAS_IP};
  $self->{port} = $management_port;
  $self->{coa_port} = (!defined $coa_port || $coa_port eq $management_port)
    ? '1700'
    : $coa_port;

  $self->{admin} = $host->{NAS_MNG_USER} || $host->{nas_mng_user} || '';

  if ($self->{backend} eq 'ssh') {
    require AXbills::Nas::Mikrotik::SSH;
    AXbills::Nas::Mikrotik::SSH->import();
    $self->{executor} = AXbills::Nas::Mikrotik::SSH->new($host, $CONF, $attr);
  }
  elsif ($self->{backend} eq 'api') {
    require AXbills::Nas::Mikrotik::API;
    AXbills::Nas::Mikrotik::API->import();
    $self->{executor} = AXbills::Nas::Mikrotik::API->new($host, $CONF, $attr);
  }
  else {
    return $self;
  }

  $self->{nas_type} = $host->{nas_type} || $host->{NAS_TYPE};

  # Allowing to use custom message functions
  if ($attr->{MESSAGE_CALLBACK} && ref $attr->{MESSAGE_CALLBACK} eq 'CODE') {
    $self->{message_cb} = $attr->{MESSAGE_CALLBACK};
  }
  else {
    $self->{message_cb} = sub {print shift};
  }
  # Allowing to use custom error message functions
  if ($attr->{ERROR_CALLBACK} && ref $attr->{ERROR_CALLBACK} eq 'CODE') {
    $self->{error_cb} = $attr->{ERROR_CALLBACK};
  }
  else {
    $self->{error_cb} = sub {print shift};
  }

  # Configuring debug options
  $self->{debug} = 0;
  if ($attr->{DEBUG}) {
    $self->{debug} = $attr->{DEBUG};
    if ($attr->{FROM_WEB}) {
      delete $BP_ARGS{TO_CONSOLE};
      $BP_ARGS{TO_WEB_CONSOLE} = 1;
    }
  }

  if (!ref($self->{executor}) && !$self->{executor}) {
    return $self;
  }

  return $self;
}

#**********************************************************
=head2 execute($command) -

  Arguments:
    $cmd - array ref. command to run with attributes and queries: [$cmd, \%attributes_attr, \%queries_attr]
           or array of such commands.
    $attr - hash_ref
      SKIP_ERROR - do not finish execution if error on one of commands. ignored if SIMULTANEOUS, because it never finishes execution on error
      SIMULTANEOUS - only if backend is API. run commands simultaneous, by starting multiple tagged queries at once

  Returns:
    1
    $results - if $cmd is one command. array ref, one result.
    $results - if SIMULTANEOUS is set. array ref of results in the same order as in $cmd


=cut
#**********************************************************
sub execute {
  my $self = shift;

  _bp("DEBUG", ("Was called from " . join(", ", caller) . "\n"), \%BP_ARGS) if($self->{debug});

  return $self->{executor}->execute(@_);
}

#**********************************************************
=head2 start_tagged_query($cmd, \%attributes_attr, \%queries_attr) - Start tagged query. Only supported with API

  Warning: don't use tagged queries with untagged on the same time

    Arguments:
      $cmd - command to run. example: "/ip address print"
      \%attributes_attr - command attributes. example: {'.proplist' => 'interface,address'}
      \%queries_attr - command queries. example: {'interface' => 'ether1'}

    Returns:
      $tag - tag of started query

=cut
#**********************************************************
sub start_tagged_query {
  my $self = shift;
  my ($cmd, $attributes_attr, $queries_attr) = @_;

  if ($self->{backend} ne 'api') {
    print "Tagged queries only supported with Mikrotik API\n" if ($self->{debug});
    return 0;
  }

  return $self->{executor}->mtik_query($cmd, $attributes_attr, $queries_attr, {TAGGED => 1});
}

#**********************************************************
=head2 get_tagged_query_result($tag) - Wait for selected tagged query(ies) to complete and return result(s). Only supported with API

  Arguments:
    $tag - number or array ref

  Returns:
    ($retval, @results) - if $tag is a number
    hashref { $tag => [$retval, @results] } - if $tag is an array ref

  Examples:
    get_tagged_query_result($tag);
    get_tagged_query_result(\@tags);

=cut
#**********************************************************
sub get_tagged_query_result {
  my $self = shift;
  my ($tag) = @_;

  if ($self->{backend} ne 'api') {
    print "Tagged queries only supported with Mikrotik API\n" if ($self->{debug});
    return 0;
  }

  return $self->{executor}->mtik_get_tagged_query_result($tag);
}

#**********************************************************
=head2 get_all_tagged_query_results() - Wait for all tagged queries to complete and return results. Only supported with API

  Returns:
    hashref { $tag => [$retval, @results] }

=cut
#**********************************************************
sub get_all_tagged_query_results {
  my $self = shift;

  if ($self->{backend} ne 'api') {
    print "Tagged queries only supported with Mikrotik API\n" if ($self->{debug});
    return 0;
  }

  return $self->{executor}->mtik_get_all_tagged_query_results();
}

#**********************************************************
=head2 has_access()

=cut
#**********************************************************
sub has_access {
  my $self = shift;

  if (! $self->{executor}) {
    return 0;
  }

  my $has_access = $self->{executor}->check_access();
  if ($has_access == -5 && $self->{backend} eq 'ssh') {
    $self->generate_key($self->{admin});
  }

  $self->{errstr}=$self->{executor}->{errstr};

  return $has_access;
}

#**********************************************************
=head2 generate_key($admin_name) - generates SSH key

  Arguments:
    $admin_name - name for admin ( for key name )

  Returns:
    1 - if generated

=cut
#**********************************************************
sub generate_key {
  my $self = shift;
  my ($admin_name) = @_;

  our $base_dir;
  $base_dir ||= '/usr/axbills';

  cmd(qq{ $base_dir/misc/certs_create.sh ssh $admin_name SKIP_CERT_UPLOAD -silent }, { SHOW_RESULT => 1 });

  return 1;
}

#**********************************************************
=head2 upload_key($attr) - uploads key for remote ssh management

  Arguments:
    $attr - hash_ref
      ADMIN_NAME    - admin to upload key for. Will be created if not exists
      SYSTEM_ADMIN  - current active admin
      SYSTEM_PASSWD - current password

  Returns:
    1 - if success

=cut
#**********************************************************
sub upload_key {
  my $self = shift;
  my ($attr) = @_;

  if (!$self->{backend} eq 'api') {
    print " !!! Only API supported \n";
    return 0;
  }

  return $self->{executor}->upload_key($attr);
}

#**********************************************************
=head2 get_error() - returns inner executor error

=cut
#**********************************************************
sub get_error {
  my $self = shift;

  return $AXbills::Nas::Mikrotik::API::errstr || $self->{executor}->{errstr} || '';
}

#**********************************************************
=head2 has_list_command($list_name) - checks if executor has command for list

  Arguments:
    $list_name -
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub has_list_command {
  my ($self, $list_name) = @_;

  return $self->{executor}->has_list_command($list_name);
}

#**********************************************************
=head2 get_list($list_name, $attr) - forwarding request to executor

  Arguments:
    $list_name - one of predefined commands

  Returns:
   list

=cut
#**********************************************************
sub get_list {
  my $self = shift;
  return $self->{executor}->get_list(@_);
}

#**********************************************************
=head2 interfaces_list($filter)

  Arguments:
    $filter - hash_ref

  Returns:
  list of interfaces (filtered if filter defined)

=cut
#**********************************************************
sub interfaces_list {
  my $self = shift;
  my ($filter) = @_;

  my $interfaces_list = $self->get_list('interfaces', { FILTER => $filter });
  return [] unless ($interfaces_list);

  #  Moved to mikrotik query
  #  if ( defined $filter && ref $filter eq 'HASH' ) {
  #
  #    my @result_list = @{$interfaces_list};
  #    foreach my $filter_key ( keys %{$filter} ) {
  #      @result_list = grep { $_->{$filter_key} && $_->{$filter_key} eq $filter->{$filter_key} } @result_list;
  #    }
  #
  #    return \@result_list;
  #  }

  return $interfaces_list;
}

#**********************************************************
=head2 addresses_list()

=cut
#**********************************************************
sub addresses_list {
  my $self = shift;

  return $self->get_list('addresses');
}

#**********************************************************
=head2 adverts_list($attr) - get hotspot adverts for default user profile

=cut
#**********************************************************
sub adverts_list {
  my $self = shift;
  my $attr = shift;
  return $self->get_list('adverts', $attr);
}

#**********************************************************
=head2 leases_list() - returns leases from mikrotik

  Arguments:
    $mikrotik - Mikrotik object

  Returns:
    list

=cut
#**********************************************************
sub leases_list {
  my ($self, $attr) = @_;

  my $mikrotik_leases_list = $self->{executor}->get_list('dhcp_leases_generated', $attr);
  _bp("leases arr", $mikrotik_leases_list, \%BP_ARGS) if ($attr->{DEBUG});

  return $mikrotik_leases_list;
}

#**********************************************************
=head2 leases_remove($leases_ids_list, $attr)

  Arguments:
    $leases_ids_list - array_ref of IDs to delete
    $attr - hash_ref
    
  Returns:
    boolean

=cut
#**********************************************************
sub leases_remove {
  my ($self, $leases_ids_list, $attr) = @_;

  return 1 if (scalar(@{$leases_ids_list} == 0));

  my @cmd_arr = ();
  my $del_cmd_chapter = 'ip dhcp-server lease remove';
  foreach my $lease_id (@{$leases_ids_list}) {
    print "Removing lease id $lease_id \n" if ($attr->{VERBOSE});
    push(@cmd_arr, [ $del_cmd_chapter, undef, { numbers => $lease_id } ]);
  }

  return $self->{executor}->execute(\@cmd_arr, { CHAINED => 1, SKIP_ERROR => 1, DEBUG => $attr->{DEBUG} });
}


#**********************************************************
=head2 leases_add($leases_list, $attr)

  Arguments:
    $leases_list - list of leases in DB format
      [
       {
         tp_tp_id
         network
         mac
         ip
       }
      ]
    $attr
      SKIP_DHCP_NAME - add lease for all DHCP servers
      VERBOSE - be verbose
      DEBUG

  Returns:
    1

=cut
#**********************************************************
sub leases_add {
  my ($self, $leases_list, $attr) = @_;

  return 1 if (scalar(@{$leases_list} == 0));

  my @cmd_arr = ();

  foreach my $lease (@{$leases_list}) {

    my $address_list_arg = "";
    #    if ( !$lease->{active} || $lease->{active} != 1 ){
    #      $address_list_arg .= "negative";
    #    }
    if (!$lease->{tp_tp_id}) {
      print " !!! Tarriff plan not selected for $lease->{login}. Skipping \n";
      next;
    }
    else {
      $address_list_arg = "address-list=CLIENTS_$lease->{tp_tp_id}";
    }

    my $dhcp_server_name = "dhcp_axbills_network_$lease->{network}";

    if ($attr->{SKIP_DHCP_NAME}) {
      $dhcp_server_name = 'all';
    }
    else {
      if ($attr->{USE_NETWORK_NAME}) {
        $dhcp_server_name = $lease->{network_name};
      }
      elsif ($attr->{DHCP_NAME_PREFIX}) {
        $dhcp_server_name = "$attr->{DHCP_NAME_PREFIX}_$lease->{network}";
      }
    }

    print "Adding new lease address=$lease->{ip} mac-address=$lease->{mac} \n" if ($attr->{VERBOSE});

    my $cmd = "/ip dhcp-server lease add address=$lease->{ip} mac-address=$lease->{mac} server=$dhcp_server_name disabled=no $address_list_arg comment=\"ABillS generated\"";
    push(@cmd_arr, $cmd);
  }

  return $self->{executor}->execute(\@cmd_arr, { CHAINED => 1, DEBUG => $attr->{DEBUG} });
}

#**********************************************************
=head2 leases_remove_all_generated($nas, $attr)

  Arguments:
    $nas - nases table line
    $attr - hash_ref

  Returns:
   1 if success

=cut
#**********************************************************
sub leases_remove_all_generated {
  my ($self, $attr) = @_;

  # Skipping non-mikrotik NASes
  return 0 unless ($self->{nas_type} =~ /mikrotik/);

  my $mikrotik_leases = $self->leases_list($attr);
  _bp("Leases to delete", $mikrotik_leases, \%BP_ARGS) if ($attr->{DEBUG});

  my @leases_to_delete_ids = ();
  foreach my $lease (@{$mikrotik_leases}) {
    push(@leases_to_delete_ids, $lease->{id});
  }

  return $self->leases_remove(\@leases_to_delete_ids, $attr);
}

#**********************************************************
=head2 ppp_accounts_list() - Returns list of current ppp accounts

  Arguments:
     -
    
  Returns:
  
  
=cut
#**********************************************************
sub ppp_accounts_list {
  my ($self) = @_;
  return $self->get_list('ppp_accounts');
}

#**********************************************************
=head2 ppp_accounts_add($account) -

  Arguments:
    $account -
      name      - LOGIN
      password
      caller-id  - MAC (CID)
      remote-address
    
  Returns:
    1
  
=cut
#**********************************************************
sub ppp_accounts_add {
  my ($self, $account) = @_;

  my @accounts_add_commands = ();
  if (ref $account eq 'ARRAY') {
    @accounts_add_commands = map {
      [ '/ppp/secret/add', $_ ]
    } @{$account};
  }
  else {
    @accounts_add_commands = (
      [ '/ppp/secret/add', $account ]
    );
  }

  return $self->execute(\@accounts_add_commands, {});
}

#**********************************************************
=head2 ppp_accounts_remove($query) - removes account by query

  Arguments:
    $query -
    
  Returns:
  
  
=cut
#**********************************************************
sub ppp_accounts_remove {
  my ($self, $query) = @_;

  return $self->execute([
    [ '/ppp/secret/remove', $query ]
  ]);
}

#**********************************************************
=head2 ppp_accounts_change($id, $key_values) - changes account by id

  Arguments:
    $id         - unique key (numbers). In this menu can use "name"
    $key_values - hash_ref of new_values
    
  Returns:
    1
    
=cut
#**********************************************************
sub ppp_accounts_change {
  my ($self, $id, $key_values) = @_;

  return $self->execute([
    [ '/ppp/secret/set', $key_values, { numbers => $id } ]
  ]);

  #  return 1;
}

#**********************************************************
=head2 dhcp_servers_check($networks, $attr)

  Arguments:
    $mikrotik - Mikrotik object
    $networks - networks list from DB

  Returns:
    1

=cut
#**********************************************************
sub dhcp_servers_check {
  my $self = shift;
  my ($networks, $attr) = @_;

  return $networks if ($attr->{SKIP_DHCP_NAME});
  my $DHCP_server_name_prefix = ($attr->{DHCP_NAME_PREFIX}) ? $attr->{DHCP_NAME_PREFIX} : "dhcp_axbills_network_";

  my $servers_list = $self->{executor}->get_list('dhcp_servers');

  my %servers_by_name = ();
  foreach my $server (@{$servers_list}) {
    $servers_by_name{ lc $server->{name}} = $server;
  }

  for (my $i = 0; $i < scalar @{$networks}; $i++) {
    my $network = $networks->[$i];

    my $network_identifier = ($attr->{USE_NETWORK_NAME}) ? $network->{name} : "$DHCP_server_name_prefix$network->{id}";

    print "Checking for existence of $network_identifier \n" if ($attr->{VERBOSE} && $attr->{VERBOSE} > 1);

    unless (defined $servers_by_name{lc $network_identifier}) {
      print " !!! You should add '$network_identifier' DHCP server at mikrotik or use SKIP_DHCP_NAME=1
                You also can use DHCP_NAME_PREFIX=\"\" to specify prefix
                or use USE_NETWORK_NAME=1 to use network names as identifier
                Leases for this network will be skipped!\n";
      splice @{$networks}, $i, 1;
      $i--;
    }
  }

  if ($attr->{USE_ARP} || $attr->{DISABLE_ARP}) {
    my $numbers = '';

    if ($attr->{USE_NETWORK_NAME}) {
      $numbers = join(',', map {$_->{name}} @{$networks});
    }
    else {
      foreach my $network (@{$networks}) {
        $numbers .= $servers_by_name{"$DHCP_server_name_prefix$network->{id}"}->{number};
      }
    }

    my $set_value = ($attr->{USE_ARP}) ? 'yes' : 'no';

    my $command = "/ip dhcp-server set add-arp=$set_value numbers=$numbers";

    if (my $result = $self->{executor}->execute($command)) {
      print "  add-arp set to: $set_value \n";
    }
    else {
      print "  !!! add-arp set failed : $result";
    };
  }

  _bp("size of network list", scalar @{$networks}, \%BP_ARGS) if ($attr->{DEBUG});

  return $networks;
}

sub check_defined_networks {
  my ($self, $networks, $attr) = @_;

  my $mikrotik_networks = $self->{executor}->get_list('dhcp_servers');

  #Sort by network address
  my %networks_by_address = ();
  foreach my $network (@{$mikrotik_networks}) {
    $networks_by_address{$network->{address}} = $network;
  }

  for (my $i = 0; $i < scalar @{$networks}; $i++) {
    my $network = $networks->[$i];

    #    unless ( defined $servers_by_name{lc "dhcp_axbills_network_$network->{id}"} ){
    #      print " !!! You should add 'dhcp_axbills_network_$network->{id}' DHCP server at mikrotik or use SKIP_DHCP_NAME=1 \n     Leases for this network will be skipped!\n";
    #      splice @{$networks}, $i, 1;
    #      $i--;
    #    }
  }
}
#**********************************************************
=head2 hotspot_configure(\%arguments)

  Arguments:
    $arguments - hash_ref
      INTERFACE            - interface to apply hotspot firewall rules
      DHCP_RANGE           - range of client addresses
      ADDRESS              - local IP address for hotspot interface
      NETWORK              - hotspot network
      NETMASK              - hotspot network bits length
      GATEWAY              - WAN interface gateway
      DNS
      DNS_NAME             - name that clients are redirected to
      BILLING_IP_ADDRESS   - radius IP address
      RADIUS_SECRET

=cut
#**********************************************************
sub hotspot_configure {
  my $self = shift;
  my ($arguments) = @_;

  my $interface = $arguments->{INTERFACE};
  my $range = $arguments->{DHCP_RANGE};
  my $address = $arguments->{ADDRESS};
  my $network = $arguments->{NETWORK};
  my $netmask = $arguments->{NETMASK};
  my $gateway = $arguments->{GATEWAY};
  my $dns_server = $arguments->{DNS};

  my $dns_name = $arguments->{DNS_NAME};
  my $pool_name = "hotspot-pool-1";

  my $radius_address = $arguments->{BILLING_IP_ADDRESS};
  my $radius_secret = $arguments->{RADIUS_SECRET};

  $self->execute([ [
    '/ip address add', {
    address   => "$address/$netmask",
    comment   => "HOTSPOT",
    disabled  => "no",
    interface => $interface,
    network   => $network
  }
  ],
  ]);

  $self->execute([
    [ '/ip dhcp-server network add', {
      address => "$network/$netmask",
      comment => "Hotspot network",
      gateway => $address
    }
    ]
  ]);
  $self->execute([
    [ '/ip firewall nat add', {
      chain         => 'pre-hotspot',
      'dst-address' => $radius_address,
      action        => 'accept'
    }
    ],
  ]);
  $self->execute([
    [
      '/ip pool add',
      { name => 'hotspot-pool-1', ranges => $range }
    ],

  ]);
  $self->execute([
    [ '/ip dns set', {
      'allow-remote-requests' => 'yes',
      'cache-max-ttl'         => "1w",
      'cache-size'            => '10000KiB',
      'max-udp-packet-size'   => 512,
      'servers'               => "$address,$dns_server"
    }
    ],
  ]);

  if ($dns_name) {
    $self->execute([
      [
        '/ip dns static add', {
        name    => $dns_name,
        address => $address
      }
      ],
    ]);
  }

  $self->execute([
    [ '/ip dhcp-server config set', { 'store-leases-disk' => '5m' } ],
  ]);
  $self->execute([
    [
      '/ip dhcp-server add', {
      'address-pool'  => 'hotspot-pool-1',
      authoritative   => 'after-2sec-delay',
      'bootp-support' => 'static',
      'disabled'      => 'no',
      interface       => $interface,
      'lease-time'    => '1h',
      name            => 'hotspot_dhcp'
    }
    ]
  ],
  );

  $self->show_message("\n Configuring Hotspot \n");

  $self->execute([ [ '/ip hotspot profile add',
    { name                   => 'hsprof1',
      'hotspot-address'      => $address,
      'html-directory'       => 'hotspot',
      'http-cookie-lifetime' => '1d',
      'http-proxy'           => "0.0.0.0:0",
      'login-by'             => "http-pap",
      'rate-limit'           => "",
      'smtp-server'          => "0.0.0.0",
      'split-user-domain'    => "no",
      'use-radius'           => "yes"
    }
  ] ]);
  $self->execute([
    [ '/ip hotspot add',
      { name                => 'hotspot1',
        'address-pool'      => 'none',
        'addresses-per-mac' => 2,
        disabled            => "no",
        'idle-timeout'      => "5m",
        interface           => $interface,
        'keepalive-timeout' => "none",
        profile             => "hsprof1" }
    ],
  ]);
  $self->execute([
    [ '/ip hotspot user profile set',
      {
        'idle-timeout'       => 'none',
        'keepalive-timeout'  => '2m',
        'shared-users'       => 1,
        'status-autorefresh' => '1m',
        'transparent-proxy'  => 'no'
      },
      {
        name => 'default',
      }
    ],
  ]);
  $self->execute([ [ '/ip hotspot service-port set',
    {
      disabled => "yes",
      ports    => 21
    },
    {
      name => "ftp",
    }
  ], ]);
  $self->execute([
    [ '/ip hotspot walled-garden ip add', {
      action        => "accept",
      disabled      => "no",
      'dst-address' => $radius_address
    }
    ],
  ]);
  $self->execute([
    [ '/ip firewall nat add', {
      action   => "masquerade",
      chain    => "srcnat",
      disabled => "no"
    }
    ]
  ]);

  $self->show_message("\n  Configuring RADIUS\n");

  $self->execute([
    [ "/radius add", { address => $radius_address, secret => $radius_secret, service => "hotspot" } ],
  ]);
  $self->execute([
    [ "/ip hotspot profile set", { 'use-radius' => 'yes' }, { name => 'hsprof1' } ],
  ]);
  $self->execute(
    [
      [ "/radius set timeout=00:00:01 numbers=0" ]
    ],
  );

  $self->show_message("\n Configuring Hotspot walled-garden \n");

  my @walled_garden_hosts = (
    $radius_address,
    $dns_server
  );

  if ($arguments->{WALLED_GARDEN} && ref $arguments->{WALLED_GARDEN} eq 'ARRAY') {
    push(@walled_garden_hosts, @{$arguments->{WALLED_GARDEN}});
  };

  my @walled_garden_commands = ();
  foreach my $host (@walled_garden_hosts) {
    if ($host) {
      push(@walled_garden_commands, [ '/ip hotspot walled-garden add', { 'dst-host' => $host,  'server' => 'hotspot1'  } ]);
    }
  }

  $self->execute(
    \@walled_garden_commands,
  );

  $self->show_message("\n Uploading custom captive portal \n");

  #First of all we need move files to /tmp to prevent access restrictions

  my $hotspot_temp_dir = '/tmp/axbills_';
  cmd("mkdir $hotspot_temp_dir");

  my $command = "/bin/cp $main::base_dir/misc/hotspot/hotspot.tar.gz $hotspot_temp_dir/hotspot.tar.gz";
  $command .= " && cd $hotspot_temp_dir && /bin/tar -xvf hotspot.tar.gz;";

  _bp("Unpacking portal files", "$command", \%BP_ARGS) if ($self->{debug} > 1);

  cmd($command);

  if ($radius_address ne '10.0.0.2') {

    $self->show_message("\n  Renaming Billing URL \n");

    my $temp_file = '/tmp/hotspot_temp';
    my $login_page = "$hotspot_temp_dir/hotspot/login.html";

    # Cat and sed to temp file
    $command = "cat $login_page | sed 's/10\.0\.0\.2/$radius_address/g' > $temp_file";
    _bp("renaming 1", "$command", \%BP_ARGS) if ($self->{debug} > 1);
    print cmd($command);

    # Cat back to normal file
    $command = "cat $temp_file > $login_page";
    _bp("Renaming 2", "$command", \%BP_ARGS) if ($self->{debug} > 1);
    print cmd($command);
  }

  my $ssh_remote_admin = $self->{executor}->{admin} || 'axbills_admin';
  my $ssh_remote_host = $self->{executor}->{host};
  my $ssh_remote_port = $self->{executor}->{ssh_port} || 22;
  my $ssh_cert = $self->{executor}->{ssh_key} || '';

  my $scp_file = $arguments->{SCP_FILE};
  unless ($scp_file) {
    $scp_file = cmd("which scp");
    chomp($scp_file);
  }

  my $port_option = '';
  if ($ssh_remote_port != 22) {
    $port_option = "-P $ssh_remote_port";
  }

  my $cert_option = '';
  if ($ssh_cert ne '') {
    $cert_option = "-i $ssh_cert -o StrictHostKeyChecking=no";
  }

  $command = "cd $hotspot_temp_dir && ";
  $command .= "$scp_file $port_option $cert_option -B -r hotspot $ssh_remote_admin\@$ssh_remote_host:/ && rm -rf hotspot";

  $self->show_message("\n  Uploading captive portal files \n");

  _bp("Upload files", "Executing cmd : $command \n", \%BP_ARGS) if ($self->{debug} > 1);

  cmd($command);

  return 1;

}

#**********************************************************
=head2 radius_add($host, $attr) - adds first radius server

  Arguments:
    $host - ip address
    $attr - hash_ref
      RADIUS_SECRET - use special radius secret, instead of given in host params
      COA           - port for listening COA requests (3799)
      REPLACE       - if server exists, delete it and set with given params
      SERVICES      - services to use with this radius (hotspot, ppp, dhcp)
    
  Returns:
    1 - if success
    
=cut
#**********************************************************
sub radius_add {
  my $self = shift;
  my ($host, $attr) = @_;

  return 0 if (!$host);

  # Check if there's no radius servers yet
  my $existing_servers = $self->get_list('radius');

  my @same = grep {$_->{address} && $_->{address} eq $host} @{$existing_servers};

  if (@same) {
    # Already exists
    return 1 if (!$attr->{REPLACE});

    # Delete all
    my @delete_radius_commands = ();
    foreach (@same) {
      push(@delete_radius_commands, [ '/radius remove', { numbers => $_->{id} } ]);
    }

    $self->execute(
      \@delete_radius_commands,
      {
        SHOW_RESULT => 1
      }
    );
  }

  my $secret = $attr->{RADIUS_SECRET} || $self->{nas_mng_password} || 'secretpass';
  my $coa = $attr->{COA} || 3799;
  my $services = $attr->{SERVICES} || 'hotspot,ppp,dhcp';

  $self->execute(
    [
      [ "/radius add", { address => $host, secret => $secret, service => $services } ],
      [ "/radius incoming set", { accept => 'yes', port => $coa } ],
    ],
    {
      SHOW_RESULT => 1,
      SKIP_ERROR  => 1,
    }
  );

  return 1;
}

#**********************************************************
=head2 dns_set($new_dns, $attr) -

  Arguments:
    $new_dns - IP address of DNS server
    $attr    -
    
  Returns:
  
  
=cut
#**********************************************************
sub dns_set {
  my ($self, $new_dns, $attr) = @_;
  return 0 if (!$new_dns);

  $self->execute(
    [
      [ "/ip dns set", { servers => $new_dns } ]
    ],
    {
      SHOW_RESULT => 1,
      SKIP_ERROR  => 1,
    }
  );

  return 1;
}

#**********************************************************
=head2 routes_list() - returns list of configured routes
  
  Returns:
    list of routes
  
=cut
#**********************************************************
sub routes_list {
  my ($self) = @_;

  return $self->get_list('routes');
}

#**********************************************************
=head2 firewall_address_list_list($query) - get all entries in Firewall > Address-list

  Arguments:
    $query - (optional) filter list using query
    
  Returns:
    list
    
=cut
#**********************************************************
sub firewall_address_list_list {
  my ($self, $query) = @_;

  my AXbills::Nas::Mikrotik::SSH $exec = $self->{executor};

  return $exec->get_list('firewall_address__list', {
    FILTER => $query
  });
}

#**********************************************************
=head2 firewall_address_list_add($ip, $list, $timeout) -

  Arguments:
    $ip, $list, $timeout -
    
  Returns:
    1 on success
    
=cut
#**********************************************************
sub firewall_address_list_add {
  my ($self, $ip, $list, $timeout) = @_;

  return 0;
}

#**********************************************************
=head2 firewall_address_list_del($id) -

  Arguments:
    $id
    
  Returns:
    1 on success
    
=cut
#**********************************************************
sub firewall_address_list_del {
  my ($self, $id) = @_;

  return $self->execute([
    [ '/ip/firewall/address-list/remove', { numbers => $id } ]
  ]);
}

#**********************************************************
=head2 add_firewall_rule($params) -

  Arguments:
     $params - options for rule, same as command attributes for Mikrotik

  Returns:
    1

=cut
#**********************************************************
sub add_firewall_rule {
  my ($self, $rule_params) = @_;
  return 0 unless $rule_params;

  return $self->execute([ [ '/ip firewall filter add', $rule_params ] ]);
}

#**********************************************************
=head2 add_nat_rule($params) -

  Arguments:
    $params - options for rule, same as command attributes for Mikrotik

  Returns:
    1

=cut
#**********************************************************
sub add_nat_rule {
  my ($self, $rule_params) = @_;
  return 0 unless $rule_params;

  return $self->execute([ [ '/ip firewall nat add', $rule_params ] ]);
}

#**********************************************************
=head2 add_ssh_bruteforce_protection($allowed_ips) -

  Arguments:
    $allowed_ips - IP addresses that will not be checked for bruteforce

  Returns:
    1

=cut
#**********************************************************
sub add_ssh_bruteforce_protection {
  my ($self, $allowed_ips) = @_;

  my %similar_params = (
    'connection-state' => 'new',
    action             => 'add-src-to-address-list',
    chain              => 'input',
    protocol           => 'tcp',
    'dst-port'         => '22',
  );

  $self->add_firewall_rule({
    %similar_params,
    'src-address'  => "!$allowed_ips",
    'address-list' => 'ssh_stage_1'
  });

  $self->add_firewall_rule({
    %similar_params,
    'src-address-list'     => 'ssh_stage_1',
    'address-list'         => 'ssh_stage_2',
    'address-list-timeout' => '20s',
  });

  $self->add_firewall_rule({
    %similar_params,
    'src-address-list'     => 'ssh_stage_2',
    'address-list'         => 'ssh_stage_3',
    'address-list-timeout' => '20s',
  });

  $self->add_firewall_rule({
    %similar_params,
    'src-address-list'     => 'ssh_stage_3',
    'address-list'         => 'ssh_blacklist',
    'address-list-timeout' => '20s',
  });

  $self->add_firewall_rule({
    %similar_params,
    'connection-state' => undef,
    'src-address-list' => 'ssh_blacklist',
    action             => 'drop',
    comment            => "ABillS. Drop ssh bruteforces"
  });

  return 1;
}

#**********************************************************
=head2 show_message($message) - Shows message

  Arguments:
    $message - string
    
=cut
#**********************************************************
sub show_message {
  my $self = shift;
  $self->{message_cb}(@_);
  return;
}

#**********************************************************
=head2 show_error($message) - Shows error

  Arguments:
    $message - string
    
=cut
#**********************************************************
sub show_error {
  my $self = shift;
  $self->{error_cb}(@_);
  return;
}

#**********************************************************
=head2 debug($value) - clears or sets debug

  Arguments:
    $value - if not defined, not set
    
  Returns:
    New debug value
    
=cut
#**********************************************************
sub debug {
  my ($self, $value) = @_;

  if (defined $value) {
    $self->{debug} = $value;
    $self->{executor}->{debug} = $value;
  }

  return $self->{debug};
}

##**********************************************************
#=head2 is_rechable($ip_address) - pings given address 3 times
#
#  Returns:
#    boolean - true if 3 packets received back
#
#=cut
##**********************************************************
#sub is_reachable{
#  my $self = shift;
#
#  my @cmd = ("ping", "-c 3", "-q",  "$self->{ip_address}");
#  my $res = system(@cmd);
#  my $is_rechable = $res =~ /3 received/;
#
#  return $is_rechable;
#}
1;
