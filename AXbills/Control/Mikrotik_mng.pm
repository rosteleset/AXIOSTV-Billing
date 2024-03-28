use strict;
use warnings FATAL => 'all';

our ($db, %lang, $base_dir, %conf);
our AXbills::HTML $html;
our Admins $admin;

use Nas;
use AXbills::Base qw(in_array load_pmodule cmd);
use AXbills::Experimental;
require AXbills::Nas::Mikrotik;

my $Nas = Nas->new($db, \%conf, $admin);

#**********************************************************
=head2 form_mikrotik_check_access()

=cut
#**********************************************************
sub form_mikrotik_check_access {
  my ($Nas_) = @_;

  $Nas_->{nas_mng_user} = $FORM{USERNAME};
  $Nas_->{nas_mng_password} = $FORM{PASSWORD};

  my $mt = AXbills::Nas::Mikrotik->new( $Nas_, \%conf, {
      backend          => 'api',
      FROM_WEB         => 1,
#      DEBUG => 5,
      MESSAGE_CALLBACK => sub { $html->message('info', @_[0 ... 1]) },
      ERROR_CALLBACK   => sub { $html->message('err', @_[0 ... 1]) },
    });

  if ( !$mt->has_access() ) {
    $html->message('err', $lang{ERR_ACCESS_DENY}, "API: " . ($mt->get_error() || ''));
    return 0;
  }

  my $version_res = $mt->execute(['/system/package/print', undef, { name => 'security'}]);
  if ($version_res && ref $version_res eq 'ARRAY' && $version_res->[0]) {
    my $version = $version_res->[0]->{version};
    $html->message('info', $lang{SUCCESS} , "VERSION : " . $version);
  }

  return 1;
}

#**********************************************************
=head2 form_mikrotik_configure()

=cut
#**********************************************************
sub form_mikrotik_configure {
  my ($Nas_, $attr) = @_;


  if ($attr->{import_users}) {
    $attr->{API_BACKEND} = 18728; #@Fixme port 8728
  }

  ### Step 0 : check access ###
  my AXbills::Nas::Mikrotik $mikrotik = _mikrotik_init_and_check_access($Nas_, {
    DEBUG     => $conf{mikrotik_debug} || 0,
    RETURN_TO => 'mikrotik_configure',
    %{ $attr // { } }
  });

  if ($attr->{import_users}) {
    _import_users($mikrotik, $attr);
    return 1;
  }

  if ( !$mikrotik || ref $mikrotik ne 'AXbills::Nas::Mikrotik' ) {
#    $html->message('err', $lang{ERROR}, "No connection to : " . $Nas_->{NAS_NAME});
    return 0;
  };

  require AXbills::Nas::Mikrotik::Configuration;
  AXbills::Nas::Mikrotik::Configuration->import();
  my $Configuration = AXbills::Nas::Mikrotik::Configuration->new($FORM{NAS_ID}, \%conf, {
      MESSAGE_CB => sub { $html->message('info', $_[0], $_[1]) },
      ERROR_CB   => sub { $html->message('err' , $_[0], $_[1]) },
  });

  if (!$Configuration) {
    $html->message('err', $lang{ERROR}, "No connection to : " . $Nas_->{NAS_NAME});
    return 0;
  }

  if ( $FORM{clean} ) {
    if ( $Configuration->clear() ) {
      $html->message('info', $lang{SUCCESS}, $lang{DELETED});
    }
  }

  #  check_set_default_gateway
  my $all_routes = $mikrotik->routes_list();
  if ( !$all_routes || ref $all_routes ne 'ARRAY' || !grep { $_->{'dst-address'} eq '0.0.0.0/0' } @{$all_routes} ) {
    $html->message('warn', $lang{TIP}, $lang{ERR_NO_DEFAULT_GATEWAY});
  }

  $FORM{CONNECTION_TYPE} //= $Configuration->get('CONNECTION_TYPE');
  $FORM{IP_POOL}         //= $Configuration->get('IP_POOL');

  ### Step 1 : Select connection type ###
  my $connection_type = _mikrotik_configure_get_connection_type();
  return 0 unless ($connection_type);

  if ( $FORM{action} ) {

    $Configuration->set(
      %FORM,
      INTERNAL_NETWORK => $FORM{INTERNAL_NETWORK_INPUT} || $FORM{INTERNAL_NETWORK},
      ALIVE            => $Nas_->{NAS_ALIVE} || '0',
      USE_NAT          => ($FORM{USE_NAT}) ? 1 : 0,
      RADIUS_HANGUP    => $mikrotik->{coa_port}
    );

    my $configuration_applied = mikrotik_configure($mikrotik, $connection_type, $Configuration->get());

    if ( $configuration_applied ) {
      $Configuration->save();

      my $had_errors = $mikrotik->get_error();
      my $message_class = $had_errors
        ? 'warn'
        : 'info';
      my $message_text = $had_errors
        ? $lang{CONFIGURATION_APPLIED_WITH_ERRORS}
        : $lang{CONFIGURATION_APPLIED_SUCCESSFULLY};

      $html->message($message_class, $lang{SUCCESS}, $message_text);
    }
    else {
      $html->message('warn', $lang{ERROR}, $lang{CONFIGURATION_APPLIED_WITH_ERRORS});
    }
  }

  ### Step 2 : show template ###
  my @ip_addresses = ();
  my $local_host = $ENV{HTTP_HOST};
  if ($local_host){
    $local_host =~ s/\:.*$// if $local_host;
     push (@ip_addresses, $local_host);
  }

  my $interfaces = local_network_interfaces_list();
  if ( $interfaces && ref $interfaces eq 'HASH' ) {
    foreach my $interface_name ( sort keys %{$interfaces} ) {
      if (
        $interfaces->{$interface_name}->{ADDR}
        && !in_array($interfaces->{$interface_name}->{ADDR}, \@ip_addresses)
      ) {
        push @ip_addresses, $interfaces->{$interface_name}->{ADDR};
      }
    }
  }

  my %template_args = (
    DNS           => '8.8.8.8',
    USE_NAT       => 1,
    FLOW_PORT     => '9996',
    EXTRA_INPUTS  => '',
    EXTRA_OPTIONS => '',
    %{ $Configuration->get() },
    %FORM
  );

  if ( $FORM{CONNECTION_TYPE} eq 'pppoe' ) {
    _mikrotik_configure_pppoe_fields($mikrotik, \%template_args);
  }
  elsif ( $FORM{CONNECTION_TYPE} eq 'ipn' ) {
    _mikrotik_configure_freeradius_fields($mikrotik, \%template_args, \@ip_addresses);
  }
  #  elsif ( $FORM{CONNECTION_TYPE} eq 'pptp' ) {
  #    TODO: pptp fields
  #    _mikrotik_configure_pptp_fields($mikrotik, \%template_args);
  #  }
  elsif ( $FORM{CONNECTION_TYPE} eq 'freeradius_dhcp' ) {
    _mikrotik_configure_freeradius_fields($mikrotik, \%template_args, \@ip_addresses);
  }

  my $radius_select = $html->form_select('RADIUS_IP', {
      SELECTED  => $template_args{RADIUS_IP},
      SEL_ARRAY => \@ip_addresses,
      NO_ID     => 1
    });
  my $radius_input = $html->form_input('RADIUS_IP_ADD', $template_args{RADIUS_IP} || '');
  $template_args{RADIUS_IP_SELECT} = $html->form_blocks_togglable($radius_select, $radius_input);

  # Ask user for internal network
  my $internal_network_select = $html->form_select("INTERNAL_NETWORK", {
      SELECTED  => $template_args{INTERNAL_NETWORK_SELECT},
      SEL_ARRAY => [
        '10.0.0.0/8',
        '172.16.0.0/12',
        '192.168.0.0/16',
      ]
    });
  my $internal_network_input = $html->form_input("INTERNAL_NETWORK_INPUT", $template_args{INTERNAL_NETWORK} || '');
  $template_args{INTERNAL_NETWORK_SELECT} = $html->form_blocks_togglable($internal_network_select, $internal_network_input);

  # SSH bruteforce
  $template_args{EXTRA_OPTIONS} .= _create_checkbox_form_group_row(
    "SSH_BRUTEFORCE", $Configuration->get('SSH_BRUTEFORCE'), "SSH $lang{BRUTEFORCE_PROTECTION}",
    { EX_PARAMS => 'data-tooltip="Only allow simultaneous SSH requests from ABillS (Radius) IP"' }
  );

  # DNS Flood protection
  $template_args{EXTRA_OPTIONS} .= _create_checkbox_form_group_row(
    "DNS_FLOOD", $Configuration->get("DNS_FLOOD"), "$lang{DNS_FLOOD_PROTECTION}",
    { EX_PARAMS => "data-tooltip='$lang{SERVE_ONLY_LOCAL_REQUESTS}'" }
  );

  # Negative deposit filter
  $template_args{EXTRA_OPTIONS} .= _create_checkbox_form_group_row(
    "NEGATIVE_BLOCK", $Configuration->get("NEGATIVE_BLOCK"), $lang{BLOCK_NEGATIVE},
    { EX_PARAMS => 'data-input-enables="NEGATIVE_REDIRECT"' }
  );

  # Redirect to user cabinet when negative filter
  $template_args{EXTRA_OPTIONS} .= _create_checkbox_form_group_row(
    "NEGATIVE_REDIRECT", $Configuration->get("NEGATIVE_REDIRECT"), $lang{REDIRECT_NEGATIVE},
    { EX_PARAMS => 'disabled="disabled"' }
  );

  if ( $Configuration->get('UPDATED') ) {
    $template_args{CLEAN_BTN} = $html->button('', "index=$index&NAS_ID=$FORM{NAS_ID}&mikrotik_configure=1&clean=1",
      {
        class   => 'del',
        CONFIRM => $lang{REMOVE_SAVED_CONFIGURATION} . '?',
        title   => $Configuration->get('UPDATED')
      }
    );
  }

  $html->tpl_show(templates('form_mikrotik_configure'), {
      %template_args
    }
  );

  return 1;
}

#**********************************************************
=head2 mikrotik_configure()

=cut
#**********************************************************
sub mikrotik_configure {
  my AXbills::Nas::Mikrotik $mikrotik = shift;
  my ($connection_type, $params) = @_;

  # Add radius
  my %connection_type_to_radius_services = (
    pppoe           => 'ppp',
    ppptp           => 'ppp',
    freeradius_dhcp => 'dhcp',
    hotspot         => 'hotspot'
  );

  if ( exists $connection_type_to_radius_services{$connection_type} ) {
    $mikrotik->radius_add($params->{RADIUS_IP}, {
        REPLACE  => 1,
        SERVICES => $connection_type_to_radius_services{$connection_type}
      });
  }

  if ( $connection_type eq 'pppoe' || $connection_type eq 'pptp' ) {

    $mikrotik->execute([
      # /radius incoming set accept=yes port=1700
      [ '/radius/incoming/set', { accept => 'yes', port => $params->{RADIUS_HANGUP} } ],

    ], {
      SHOW_RESULT => 1
    });

    $mikrotik->execute([
      # /ppp aaa set accounting=yes use-radius=yes interim-update=${RAD_ACCT_ALIVE}
      [ '/ppp/aaa/set', { accounting => 'yes', 'use-radius' => 'yes', 'interim-update' => $params->{ALIVE} } ],
    ], {
      SHOW_RESULT => 1
    });
    $mikrotik->execute([
        # /ppp profile set default local-address=${MIKROTIK_IP}
        [ '/ppp/profile/set', { 'local-address' => $mikrotik->{ip_address} }, { name => 'default' } ]

      ], {
        SHOW_RESULT => 1
      });

    if ( $connection_type eq 'pppoe' ) {
      # Add pppoe server
      $mikrotik->execute([
          # /interface pppoe-server server add interface=${PPPOE_INTERFACE} service-name=pppoe-in authentication=chap disabled=no
          [ '/interface/pppoe-server/server/add',
            {
              interface        => $params->{PPPOE_INTERFACE},
              'service-name'   => 'pppoe-in',
              'authentication' => 'chap',
              disabled         => 'no',
            }
          ]
        ],
        {
          SHOW_RESULT => 1
        }
      );
    }
    else {
      $mikrotik->execute([
          # /interface pptp-server server set enabled=yes authentication=chap
          [ '/interface/pptp-server/server/set', { enabled => 'yes', authentication => 'chap' } ],

          # /interface pptp-client set profile=default
          #        [ '/interface/pptp-client/set',        { profile => 'default' }                       ]
        ],
        {
          SHOW_RESULT => 1
        }
      );
    }
  }
  elsif ( $connection_type eq 'freeradius_dhcp' || $connection_type eq 'ipn' ) {

    $mikrotik->execute([
      # /ip traffic-flow set enabled=yes
      [ '/ip/traffic-flow/set', { enabled => 'yes' } ],

      # /ip traffic-flow target add address=${FLOW_COLLECTOR}:${FLOW_PORT} version=5
      [ '/ip/traffic-flow/target/add',
        { 'dst-address' => $params->{FLOW_COLLECTOR}, port => $params->{FLOW_PORT}, version => 5 } ],

      # /ip traffic-flow set interfaces=ether3 active-flow-timeout=30m inactive-flow-timeout=15s cache-entries=4k enabled=yes
      [ '/ip/traffic-flow/set', {
          'interfaces'            => $params->{FLOW_INTERFACE},
          'active-flow-timeout'   => '30m',
          'inactive-flow-timeout' => '15s',
          'cache-entries'         => '4k',
          'enabled'               => 'yes',
        }
      ]
    ]);

    # /ip dhcp-server add interface=ether2 address-pool=static-only authoritative=after-2sec-delay use-radius=yes lease-time=5min

    my %dhcp_server_params = ();
    if ( $connection_type eq 'freeradius_dhcp' ) {

      our %AUTH;
      if ( !exists $AUTH{mikrotik_dhcp} || $AUTH{mikrotik_dhcp} ne 'Mac_auth' ) {

        $dhcp_server_params{'use-radius'} = 'yes';

        $html->message('info', $lang{TIP},
          $lang{ADD} . " <code>\$AUTH{mikrotik_dhcp}='Mac_auth';</code> " . $lang{TO} . ' <b>libexec/config.pl</b>');
      }

    }
    else {

      if ( $mikrotik->{nas_type} ne 'mikrotik_dhcp' ) {

        $Nas->{NAS_ID} = $mikrotik->{nas_id};
        $Nas->change({
          NAS_ID   => $mikrotik->{nas_id},
          NAS_TYPE => 'mikrotik_dhcp',
        });
        _error_show($Nas);

        $html->message('info', '', "$lang{CHANGED} $lang{TYPE} -> 'mikrotik_dhcp'") if ( !$Nas->{errno} );
      }

      $html->message('info', $lang{EXTRA},
        $html->button("$lang{CONFIGURATION} IPN", '',
          { GLOBAL_URL => 'https://wiki.billing.axiostv.ru/?epkb_post_type_1=mikrotik', class => 'alert-link' })
      );
      $dhcp_server_params{name} = 'dhcp_axbills_' . $mikrotik->{nas_id};
    }

    $mikrotik->execute([
        [ '/ip/dhcp-server/add', {
            interface       => $params->{FLOW_INTERFACE},
            'address-pool'  => 'static-only',
            'authoritative' => 'after-2sec-delay',
            'lease-time'    => '5m',
            'disabled'      => 'no',
            %dhcp_server_params
          }
        ]
      ], {
        SHOW_RESULT => 1
      });
  }

  # Set DNS
  if ($params->{DNS}){
    $mikrotik->dns_set($params->{DNS});
  }

  # SSH Bruteforce protection
  if ($params->{SSH_BRUTEFORCE} && $params->{RADIUS_IP}){
    $mikrotik->add_ssh_bruteforce_protection($params->{RADIUS_IP});
  }

  # DNS Flood protection
  if ($params->{DNS_FLOOD} && $params->{INTERNAL_NETWORK}) {
    $mikrotik->add_firewall_rule({
      chain         => 'input',
      protocol      => 'tcp',
      'dst-port'    => '53',
      'src-address' => "!$params->{INTERNAL_NETWORK}",
      action        => 'drop',
      comment           => 'ABillS. Block negative forward'
    });
    $mikrotik->execute([[ '/ip dns set' , { 'allow-remote-requests' => 'yes' }]]);
  }

  # Negative deposit filter
  if ($params->{NEGATIVE_BLOCK} && $params->{RADIUS_IP}) {
    $mikrotik->add_firewall_rule({
      chain              => 'forward',
      'src-address-list' => "negative",
      'dst-address'      => "!$params->{RADIUS_IP}",
      action             => 'reject',
      comment           => 'ABillS. Serve DNS Only for local hosts'
    });
  }

  # Redirect to user cabinet when negative filter
#  NEGATIVE_CLIENT_REDIRECT
  if ($params->{NEGATIVE_REDIRECT} && $params->{RADIUS_IP}) {
    $mikrotik->add_nat_rule({
      chain              => 'dst-nat',
      'src-address-list' => "negative",
      'protocol'         => 'tcp',
      'dst-address'      => "!$params->{RADIUS_IP}",
      'dst-port'         => '80',
      action             => 'dst-nat',
      'to-addresses'     => "$params->{RADIUS_IP}",
      'to-ports'         => "80",
      'place-before'     => 0,
       comment           => 'ABillS. Redirect negative to portal'
    });
  }

  # Initialize shaper
  $params->{USE_NAT} //= '0';
  my $cmd = $base_dir . "libexec/billd checkspeed mikrotik"
    . " RECONFIGURE=1 NAS_IDS=$params->{NAS_ID} SSH_PORT=$mikrotik->{executor}->{ssh_port} NAT=$params->{USE_NAT}";

  # Try to run by ourselves
  my $res = 1;
  eval {
    $res = cmd($cmd, { SHOW_RESULT => 1, DEBUG => 5, timeout => 30});
  };
  if ($@){
    $res = 1;
  }

  #Normally should return nothing. If failed tell user to do it by himself
  if ( $res ) {
    $html->message('info', $lang{EXECUTE}, $html->pre('# ' . $cmd, { OUTPUT2RETURN => 1 }));
  }

  return 1;
}


#**********************************************************
=head2 form_mikrotik_hotspot($Nas)

  Arguments:
    $Nas - billing NAS object

  Returns:

=cut
#**********************************************************
sub form_mikrotik_hotspot {
  my ($Nas_) = @_;
  #  delete $Nas_->{conf};
  #  delete $Nas_->{db};
  #  delete $Nas_->{admin};
  #  _bp('as', $Nas_);

  ### Step 0 : check access ###
  my AXbills::Nas::Mikrotik $mikrotik = _mikrotik_init_and_check_access($Nas_, {
    DEBUG => $conf{mikrotik_debug} || 1,
    RETURN_TO => 'mikrotik_hotspot'
  });

  return 0 unless $mikrotik;

  my ($ip) = $ENV{HTTP_HOST} =~  /(.*):.*/;
  my %default_arguments = (
    #    'INTERFACE'        => 'wlan0',
    BILLING_IP_ADDRESS => $ip,
    'ADDRESS'          => '192.168.4.1',
    'NETWORK'          => '192.168.4.0',
    'NETMASK'          => '24',
#    'MIKROTIK_GATEWAY' => '192.168.1.1',
    'DHCP_RANGE'       => '192.168.4.3-192.168.4.254',
    'MIKROTIK_DNS'     => '8.8.8.8',
    'HOTSPOT_DNS_NAME' => lc ($Nas_->{NAS_NAME}) || 'hotspot.axbills.net'
  );

  if ( $FORM{action} ) {

    my @walled_garden_hosts = ();
    # Read walled garden hosts from FORM
    my $walled_garden_hosts_count = $FORM{WALLED_GARDEN_ENTRIES} || '';
    if ( $walled_garden_hosts_count && $walled_garden_hosts_count =~ /^\d+$/ ) {
      for ( my $i = 0; $i < $walled_garden_hosts_count; $i++ ) {
        push (@walled_garden_hosts, $FORM{"WALLED_GARDEN_$i"}) if ($FORM{"WALLED_GARDEN_$i"});
      }
    }
    $mikrotik->{debug} = 9;
    my $result = $mikrotik->hotspot_configure({
      INTERFACE          => $FORM{INTERFACE},
      DHCP_RANGE         => $FORM{DHCP_RANGE},
      ADDRESS            => $FORM{ADDRESS},
      NETWORK            => $FORM{NETWORK},
      NETMASK            => $FORM{NETMASK},
      GATEWAY            => $FORM{GATEWAY},
      DNS                => $FORM{DNS},
      DNS_NAME           => $FORM{DNS_NAME},
      BILLING_IP_ADDRESS => $FORM{BILLING_IP_ADDRESS},
      RADIUS_SECRET      => $Nas_->{NAS_MNG_PASSWORD},
      WALLED_GARDEN      => \@walled_garden_hosts
    });

    if ( $result ) {
      $html->message('info', $lang{SUCCESS});
    }

    return 1;
  }

  my $interfaces_list = $mikrotik->interfaces_list({ type => '~ether|bridge' });
  if ( defined $interfaces_list && ref $interfaces_list eq 'ARRAY' && scalar @{$interfaces_list} == 0 ) {
    $interfaces_list = [ { name => 'ether0' }, { name => 'ether1' }, { name => 'wlan0' } ];
  }
  my $interface_select = $html->form_select('INTERFACE', {
      SELECTED  => $FORM{HOTSPOT_INTERFACE} || '',
      SEL_LIST  => $interfaces_list,
      SEL_KEY   => 'name',
      SEL_VALUE => 'name',
      NO_ID     => 1
    });

  $html->tpl_show( templates( 'form_mikrotik_hotspot' ),
    { INTERFACE_SELECT => $interface_select, %default_arguments, %FORM } );

  return 1;
}

#**********************************************************
=head2 form_mikrotik_upload_key()

=cut
#**********************************************************
sub form_mikrotik_upload_key {
  my ($status, $Nas_, $attr) = @_;
  return unless (defined $status && defined $Nas_);

  my $upload_key_for_admin = $FORM{ADMIN} || $Nas_->{NAS_MNG_USER} || 'axbills_admin';
  my $system_admin = $FORM{SYSTEM_ADMIN} || 'admin';
  my $system_password = $FORM{SYSTEM_PASSWD} || '';

  # Check socket is opened
  my $no_io_portstate = load_pmodule("IO::Socket::PortState", { SHOW_RETURN => 1, IMPORT => 'check_ports' });
  if (!$no_io_portstate) {
    my ($nas__mng_ip, $coa_port, $nas_port) = split( ":", $Nas_->{nas_mng_ip_port} );
    my $host_hr = check_ports($Nas_->{$nas__mng_ip}, 1, '8728');

    if ($host_hr
      && exists $host_hr->{tcp}
      && exists $host_hr->{tcp}{8728}
      && !$host_hr->{tcp}{8728}{open})
    {
      $html->message('err', $lang{ERR_ACCESS_DENY}, "API $lang{DISABLED}");
      return 0;
    }
  }
#  elsif(!load_pmodule("Socket", { SHOW_RETURN => 1})) {
#    my ($nas__mng_ip, $coa_port, $nas_port) = split( ":", $Nas_->{nas_mng_ip_port} );
#
#    my $port    = '8728';  # random port
#    if ($port =~ /\D/) { $port = Socket::getservbyname($port, "tcp") }
#    die "No port" unless $port;
#
#    my $iaddr   = inet_aton($nas__mng_ip)       || die "no host: $nas__mng_ip";
#    my $paddr   = sockaddr_in($port, $iaddr);
#
#    my $proto   = getprotobyname("tcp");
#    socket($Socket::SOCK, $Socket::PF_INET, $Socket::SOCK_STREAM, $proto)  || die "socket: $!";
#    if (!CORE::connect($Socket::SOCK, $paddr)){
#      $html->message('err', $lang{ERR_ACCESS_DENY}, "API $lang{DISABLED}");
#      return 0;
#    };
#  }
#

  if ( $FORM{upload_key} ) {
    my ($old_adm, $old_pass) = ($Nas_->{nas_mng_user}, $Nas_->{nas_mng_password});
    $Nas_->{nas_mng_user} = $system_admin;
    $Nas_->{nas_mng_password} = $system_password;

    my $mt = AXbills::Nas::Mikrotik->new( $Nas_, \%conf, {
        backend          => 'api',
        FROM_WEB         => 1,
        MESSAGE_CALLBACK => sub { $html->message('info', @_[0 ... 1]) },
        ERROR_CALLBACK   => sub { $html->message('err', @_[0 ... 1]) },
      });

    if ( !$mt->has_access() ) {
      $html->message('err', $lang{ERR_ACCESS_DENY}, "API: " . ($mt->get_error() || ''));
      return 0;
    }
    else {
      my $uploaded_key = $mt->upload_key(\%FORM);

      if ( $uploaded_key ) {
        $html->message('info', "Upload SSH key", "$lang{SUCCESS}");

        $Nas_->{nas_mng_user} = $old_adm;
        $Nas_->{nas_mng_password} = $old_pass;

        my $mt2 = AXbills::Nas::Mikrotik->new( $Nas_, \%conf, {
            backend          => 'ssh',
            FROM_WEB         => 1,
            MESSAGE_CALLBACK => sub { $html->message('info', @_[0 ... 1]) },
            ERROR_CALLBACK   => sub { $html->message('err', @_[0 ... 1]) },
          });

        return $mt2;
      }
      else {
        $html->message('err', $lang{ERROR}, $mt->get_error() || "Can't upload key. Check errors above" );
        return 0;
      }
    }
  }

  $html->tpl_show( templates('form_mikrotik_upload_key'), {
      NAS_ID          => $FORM{NAS_ID},
      ADMIN           => $upload_key_for_admin,
      SYSTEM_ADMIN    => $system_admin,
      SYSTEM_PASSWORD => $system_password,
      %{ $attr // {} }
    } );

  return 0;
}

#**********************************************************
=head2 _mikrotik_init_and_check_access()

=cut
#**********************************************************
sub _mikrotik_init_and_check_access {
  my ($Nas_, $attr) = @_;

  my $mikrotik = AXbills::Nas::Mikrotik->new( $Nas_, \%conf, {
      FROM_WEB         => 1,
      MESSAGE_CALLBACK => sub { $html->message('info', @_[0 ... 1]) },
      ERROR_CALLBACK   => sub { $html->message('err', @_[0 ... 1]) },
      DEBUG            => 5,
      %{ $attr // { } }
    });

  if ( !$mikrotik ) {
    $html->message('err', $lang{ERR_WRONG_DATA}, "NAS_IP_PORT_MNG");
    return 0;
  }

  my $mikrotik_access = $mikrotik->has_access();

  if ($mikrotik_access > 0){
    return $mikrotik;
  }

  if ($mikrotik->{backend} eq 'ssh' ) {

    if ( !$FORM{upload_key} ) {
      my $wiki_mikrotik_ssh_access_link = $html->button( $lang{HELP}, undef, {
          GLOBAL_URL => 'http://axbills.net.ua/wiki/doku.php/axbills:docs:nas:mikrotik:ssh:key_upload',
          target     => '_blank',
          BUTTON     => 2
        } );

      $html->message( 'warn', $lang{ERR_ACCESS_DENY},
        "$Nas_->{NAS_NAME} : " . ($mikrotik->{ip_address} || '[No host defined]')
          . ':' . ($mikrotik->{port} || '[No management port defined]')
          . $html->br() . "User: ". ($Nas_->{NAS_MNG_USER} || q{Not defined})
          . $html->br() . "Backend : " . $mikrotik->{backend}
          . $html->br() . $wiki_mikrotik_ssh_access_link
      );
    }

    return form_mikrotik_upload_key($mikrotik_access, $Nas_, $attr);
  }

  $html->message( 'warn', $lang{ERR_ACCESS_DENY},
    "$Nas_->{NAS_NAME} : $Nas_->{NAS_MNG_IP_PORT}"
      . $html->br() . "User: $Nas_->{NAS_MNG_USER}. Password : $Nas_->{NAS_MNG_PASSWORD}"
      . $html->br() . "Backend : " . $mikrotik->{backend}
  );

  return 0;
}

#**********************************************************
=head2 local_network_interfaces_list()

=cut
#**********************************************************
sub local_network_interfaces_list {
  require AXbills::Filters;
  AXbills::Filters->import(qw/$IPV4 $MAC/);

  my %interfaces = ();
  my $os_name = $^O;

  if ( $os_name eq 'linux' ) {
    # Parse ifconfig
    my $raw = cmd("ifconfig -a");
    my @lines = split("\n", $raw);

    # Need to left 2 lines (1 with name and HWAddr, second with inet address)
    for ( my $i = 0; $i < $#lines; $i++ ) {
      if ( $lines[$i] =~ /^([a-z0-9]*) .* ($main::MAC) / ) {
        my $name = $1;
        $interfaces{$name}->{MAC} = $2;
        if ( $lines[$i + 1] =~ /inet +(.*)/ ) {
          my @other_params = split(' ', $1);
          foreach ( @other_params ) {
            my ($attribut_name, $attribut_value) = split(':', $_);
            $interfaces{$name}->{uc $attribut_name} = $attribut_value;
          }
        }
      }
    }
  }
  elsif ( $os_name eq 'freebsd' ) {
    # Use netstat
    my $raw = cmd("netstat -i -4 -n | awk -F ' ' '{ print \$1,\$4 }'");
    my @lines = split("\n", $raw);
    shift @lines; # Remove 'Address' line

    foreach my $if_line ( @lines ) {
      my ($name, $addr) = split(' ', $if_line);
      $interfaces{$name}->{ADDR} = $addr;
    }

  }
  return \%interfaces;
}

#**********************************************************
=head2 _mikrotik_configure_get_connection_type()

=cut
#**********************************************************
sub _mikrotik_configure_get_connection_type {

  return $FORM{CONNECTION_TYPE} if ($FORM{CONNECTION_TYPE});

  my %connection_types = (
    pppoe           => 'PPPoE',
    pptp            => 'PPTP(VPN)',
    freeradius_dhcp => 'Freeradius DHCP',
    ipn             => 'IPN (manual)'
  );

  my $connection_type_select = $html->form_select('CONNECTION_TYPE', {
      SEL_LIST => [ map { { id => $_, name => $connection_types{$_} } } sort keys %connection_types ],
      SELECTED => $FORM{CONNECTION_TYPE} || '',
      EX_PARAMS    => 'style="min-width : 300px"',
      NO_ID    => 1
    });
  my $connection_type_label = $html->element('label', $lang{CONNECTION_TYPE}, { class => 'control-label' });

  print $html->element('div', $html->form_main(
      {
        CONTENT => $connection_type_label . " : " . $connection_type_select,
        HIDDEN  => { index => "$index", subf => $FORM{subf} || 0, mikrotik_configure => 1, NAS_ID => $FORM{NAS_ID} },
        SUBMIT  => { go => $lang{CHOOSE} },
        METHOD  => 'GET',
        class   => 'form navbar-form'
      }
    ), { class => 'well well-sm' });

  return 0 if (!$FORM{CONNECTION_TYPE});
}

#**********************************************************
=head2 _mikrotik_configure_freeradius_fields($mikrotik, $template_args, $local_interfaces_select_args)

=cut
#**********************************************************
sub _mikrotik_configure_freeradius_fields {
  my AXbills::Nas::Mikrotik $mikrotik = shift;

  my ($template_args, $local_ips) = @_;

  # Interface at which should listen for traffic
  my $interfaces = $mikrotik->interfaces_list();

  my $interface_select = $html->form_select('FLOW_INTERFACE', {
      SELECTED => $template_args->{FLOW_INTERFACE} || '',
      SEL_LIST => $interfaces,
      SEL_KEY  => 'name',
      NO_ID    => 1
    });

  $template_args->{EXTRA_INPUTS} .=
    _create_form_group_row('FLOW_INTERFACE', "Flow/DHCP interface", $interface_select);

  my $flow_ip_select = $html->form_select('FLOW_COLLECTOR', {
      SELECTED  => $template_args->{FLOW_COLLECTOR} || '',
      SEL_ARRAY => $local_ips,
      NO_ID     => 1
    });
  my $flow_ip_input = $html->form_input('FLOW_COLLECTOR_ADD', $template_args->{FLOW_COLLECTOR},
    { ID => 'FLOW_COLLECTOR_CUSTOM' });
  my $flow_select_with_input = $html->form_blocks_togglable($flow_ip_select, $flow_ip_input);

  $template_args->{EXTRA_INPUTS} .=
    _create_form_group_row('FLOW_COLLECTOR', "Flow collector IP", $flow_select_with_input);

  $template_args->{EXTRA_INPUTS} .=
    _create_input_form_group_row('FLOW_PORT', $template_args->{FLOW_PORT} || '9996', "Flow $lang{PORT}");

  return $template_args;
}

#**********************************************************
=head2 _mikrotik_configure_pppoe_fields($template_args)

=cut
#**********************************************************
sub _mikrotik_configure_pppoe_fields {
  my AXbills::Nas::Mikrotik $mikrotik = shift;
  my ($template_args) = @_;

  # Get interfaces from mikrotik
  my $remote_interfaces = $mikrotik->interfaces_list();

  if ( $remote_interfaces && ref $remote_interfaces eq 'ARRAY' && scalar @{$remote_interfaces} ) {

    my $interface_select = $html->form_select('PPPOE_INTERFACE', {
        SELECTED => $template_args->{PPPOE_INTERFACE} || '',
        SEL_LIST => $remote_interfaces,
        SEL_KEY  => 'name',
        SEL_NAME => 'name',

        NO_ID    => 1
      });

    $template_args->{EXTRA_INPUTS} .=
      _create_form_group_row('PPPOE_INTERFACE', "PPPoE $lang{INTERFACE}", $interface_select);
  }
  else {
    $template_args->{EXTRA_INPUTS} .=
      _create_input_form_group_row('PPPOE_INTERFACE', $template_args->{PPPOE_INTERFACE}, $lang{INTERFACE});
  }

}

#**********************************************************
=head2 _create_form_group_row($id, $label, $input_html)

=cut
#**********************************************************
sub _create_form_group_row {
  return $html->tpl_show(templates('form_row_dynamic_size'),
    {
      COLS_LEFT  => 'col-md-3',
      COLS_RIGHT => 'col-md-9',
      ID         => $_[0],
      NAME       => $_[1],
      VALUE      => $_[2]
    }, {
      OUTPUT2RETURN => 1
    });
}

#**********************************************************
=head2 _create_input_form_group_row($name, $value, $label)

=cut
#**********************************************************
sub _create_input_form_group_row {
  my $input = $html->form_input($_[0], $_[1]);
  return _create_form_group_row( $_[0], $_[2], $input );
}

#**********************************************************
=head2 _create_checkbox_form_group_row($name, $state, $label, $extra_input_attr)

=cut
#**********************************************************
sub _create_checkbox_form_group_row {
  my ($name, $state, $label, $extra_input_attr) = @_;
  my $input = $html->form_input($name, 1, { TYPE => 'checkbox', STATE => $state, %{$extra_input_attr // {}} });
  my $label_html = $html->element('label', $input . $label );

  return $html->element('div', $label_html, { class => 'checkbox', OUTPUT2RETURN => 1});
}

#**********************************************************
=head2 _import_users($attr) -

=cut
#**********************************************************
sub _import_users {
  my ($Mikrotik, $attr) = @_;

  my (undef, @rules ) = $Mikrotik->{executor}->mtik_query( '/ppp secret' . ' print',
    {'.proplist' => '.id,name,service,password,caller-id,profile,remote-address,comment,list' },
  );

  my $nas_id = $attr->{NAS_ID} || 0;
  require Internet::Users;

  my @ppp_profiles = ();
  my $add_to_db = $attr->{pppoe} || 0;
  foreach my $rule ( @rules ) {
    my $comments = AXbills::Base::convert($rule->{'comment'}, { win2utf8 => 1 });

    push @ppp_profiles, [ ($rule->{'.id'} || q{}),
      ($rule->{'name'} | q{}),
      ($rule->{'service'} || q{}),
      ($rule->{'password'} || q{}),
      ($rule->{'caller-id'} || q{}),
      ($rule->{'profile'} || q{}),
      ($rule->{'remote-address'} || q{}),
      ($comments || q{}) ];


    if($add_to_db) {
      my %user_list = ();
      $user_list{'1.LOGIN'}=($rule->{'name'} | q{});
      $user_list{'1.PASSWORD'}=($rule->{'password'} || q{});
      $user_list{'1.GID'}=101;
      $user_list{'4.CID'}=($rule->{'caller-id'} || q{});
      $user_list{'4.TP_NAME'}=($rule->{'profile'} || q{});
      $user_list{'4.IP'}=($rule->{'remote-address'} || q{});
      $user_list{'3.COMMENTS'}=$comments;
      $user_list{'3.FIO'}=$comments;
      $user_list{'1.CREATE_BILL'} = 1;

      internet_wizard_add({
         %user_list,
         SHORT_REPORT => 1,
      });
    }
  }

  if ($add_to_db) {
    $html->message('info', $lang{INFO}, $lang{ADDED});
  }

  my $table = $html->table({
    caption => 'PPPoE (' . ($#rules + 1)  .') '. $html->button($lang{IMPORT},
      "index=$index&NAS_ID=$nas_id&mikrotik_configure=1&import_users=1&pppoe=1",
      { BUTTON => 2 }),
    width   => '100%',
    rows    => \@ppp_profiles
  });

  print $table->show();

  my (undef, @rules2 ) = $Mikrotik->{executor}->mtik_query( '/queue simple ' . ' print',
    {'.proplist' => '.id,name,target,max-limit,list' },
  );

  my @ipoe_profiles = ();
  $add_to_db = $attr->{ipoe} || 0;
  foreach my $rule ( @rules2 ) {
    my $comments = AXbills::Base::convert($rule->{'name'}, { win2utf8 => 1 });
    $rule->{'.id'} =~ s/\*/0x/;

    my $speed = ($rule->{'max-limit'} || q{});
    $speed =~ /(\d+)\//;
    $speed = $1 || 0;
    $speed = int($speed / 1024);

    $rule->{'target'} =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/;
    my $ip = $1;
    my $num = oct($rule->{'.id'} || 0);

    push @ipoe_profiles, [
      $num,
      $ip,
      $speed,
      ($comments || q{}) .' '. ($rule->{'max-limit'} || q{})
    ];

    if ($add_to_db && $comments) {
      my %user_list = ();
      $user_list{'1.LOGIN'}='ipoe_' . $num;
      $user_list{'1.GID'}=102;
      $user_list{'4.TP_NAME'}='IPOE_IMPORT';
      $user_list{'4.SPEED'}=$speed;
      $user_list{'4.IP'}=$ip;
      $user_list{'3.FIO'}=$comments;
      $user_list{'3.COMMENTS'}=$comments .' '. ($rule->{'max-limit'} || q{});
      $user_list{'1.CREATE_BILL'} = 1;

      internet_wizard_add({
        %user_list,
        SHORT_REPORT => 1,
      });
    }
  }

  if ($add_to_db) {
    $html->message('info', $lang{INFO}, $lang{ADDED});
  }

  $table = $html->table({
    caption => 'IPoE (' . ($#rules2 + 1)  .') '. $html->button($lang{IMPORT},
      "index=$index&NAS_ID=$nas_id&mikrotik_configure=1&import_users=1&ipoe=1",
      { BUTTON => 2 }),
    width   => '100%',
    rows    => \@ipoe_profiles
  });

  print $table->show();

  return 0;
}


1;
