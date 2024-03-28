=head1 NAME

 DHCP server managment

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(cmd);
use Dhcphosts;

our (
  $db,
  %conf,
  $admin,
  $html,
  #  %AUTH,
  %lang,
  #  $var_dir,
  #  @bool_vals,
  #  @status,
  #  %permissions,
);

my $Dhcphosts = Dhcphosts->new($db, $admin, \%conf);


#**********************************************************
=head2 dhcp_config($attr) - Generate ISC host config

=cut
#**********************************************************
sub dhcp_config {
  my ($attr) = @_;

  # If not set reconfigure command
  if (!$conf{INTERNET_DHCP_RECONFIGURE}) {
    if ($FORM{web_reconfig}) {
      $html->message('err', $lang{ERORR}, "Not defined  \$conf{DHCPHOSTS_RECONFIGURE}");
    }
    return '';
  }

  my %INFO = ();
  my %NAS_MACS = ();

  my $xml_output = 0;
  if ($FORM{xml}) {
    $FORM{xml} = undef;
    $xml_output = 1;
  }

  my $Nas       = Nas->new( $db, \%conf, $admin );
  # Nas CSI
  my $nas_list = $Nas->list({
    COLS_NAME     => 1,
    SHORT         => 1,
    MAC           => '_SHOW',
    NAS_RAD_PAIRS => '_SHOW',
    NAS_NAME      => '_SHOW',
    PAGE_ROWS     => 60000,
  });

  foreach my $line (@{$nas_list}) {
    if ($line->{mac}) {
      $NAS_MACS{ $line->{id} } = ($line->{nas_name} || q{}) . ',' . ($line->{mac} || q{});
    }
  }

  my $list = $Dhcphosts->networks_list({
    DISABLE    => 0,
    NET_PARENT => '_SHOW',
    PAGE_ROWS  => 10000,
    COLS_NAME  => 1,
    SORT       => 2
  });

  my %SUBNETS = ();

  foreach my $net (@{$list}) {
    my $NET_ID = $net->{id};
    $INFO{OPTION82_POOLS} = '';
    $Dhcphosts->network_info($NET_ID);

    $INFO{DNS} = ($Dhcphosts->{DNS}) ? "option domain-name-servers $Dhcphosts->{DNS}" : undef;
    $INFO{DNS} .= ",$Dhcphosts->{DNS2}" if ($Dhcphosts->{DNS2});
    $INFO{DNS} .= ';' if ($INFO{DNS});
    $INFO{NTP} = "option ntp-servers $Dhcphosts->{NTP};" if ($Dhcphosts->{NTP});

    $INFO{DOMAINNAME} = ($Dhcphosts->{DOMAINNAME}) ? "option domain-name \"$Dhcphosts->{DOMAINNAME}\";" : undef;

    $INFO{ROUTERS} = ($Dhcphosts->{ROUTERS} ne '0.0.0.0') ? "option routers $Dhcphosts->{ROUTERS};" : '';
    $INFO{DATETIME} = "$DATE $TIME / Dhcphosts";

    $INFO{NETWORK_ID} = $Dhcphosts->{ID};
    $INFO{NETWORK_NAME} = $Dhcphosts->{NAME} || 'NETWORK_NAME';
    $INFO{BLOCK_NETWORK} = $Dhcphosts->{BLOCK_NETWORK};
    $INFO{BLOCK_MASK} = $Dhcphosts->{BLOCK_MASK};
    $INFO{NETWORK} = $Dhcphosts->{NETWORK};
    $INFO{NETWORK_MASK} = $Dhcphosts->{MASK};
    $INFO{DESCRIBE} = $Dhcphosts->{NAME};
    $INFO{DESCRIBE} = $Dhcphosts->{COMMENTS};
    $INFO{AUTHORITATIVE} = ($Dhcphosts->{AUTHORITATIVE}) ? 'authoritative;' : '';
    $INFO{DENY_UNKNOWN_CLIENTS} = ($Dhcphosts->{DENY_UNKNOWN_CLIENTS}) ? 'deny unknown-clients;' : '';

    if (!$Dhcphosts->{STATIC} && $Dhcphosts->{IP_RANGE_FIRST} ne '0.0.0.0') {
      $INFO{RANGE} = "range $Dhcphosts->{IP_RANGE_FIRST} $Dhcphosts->{IP_RANGE_LAST};";
    }
    else {
      $INFO{RANGE} = '';
    }

    #Add static route
    $list = $Dhcphosts->routes_list({ NET_ID => $NET_ID });
    $INFO{NET_ROUTES} = '';
    $INFO{NET_ROUTES_RFC3442} = '';
    if ($Dhcphosts->{TOTAL} > 0) {
      my $routes = "";

      foreach my $line2 (@{$list}) {
        my $src = $line2->[2];
        my $mask = $line2->[3];
        my $router = $line2->[4];

        my @ip = split(/\./, $src);
        my @ip2 = split(/\./, $router);
        $mask = mask2bitlen($mask);
        $routes .= $mask;

        for (my $i = 0; $i < $mask / 8; $i++) {
          $routes .= ", $ip[$i]";
        }
        $routes .= ", " . join(", ", @ip2) . ",\n";
      }

      chop $routes;
      chop $routes;
      $routes .= ";";

      # MS routes: adds extras to supplement routers option
      $INFO{NET_ROUTES} = "option ms-classless-static-routes $routes";

      # RFC3442 routes: overrides routers option
      $INFO{NET_ROUTES_RFC3442} = "option rfc3442-classless-static-routes $routes";
    }

    #Make hosts
    #$INFO{NETWORK} = '';

    my %PARAMS = ();

    if (defined($conf{DHCPHOSTS_DEPOSITCHECK})) {
      $PARAMS{DEPOSIT} = '_SHOW';
    }

    if (defined($conf{DHCPHOSTS_EXT_DEPOSITCHECK})) {
      $PARAMS{EXT_DEPOSIT} = '_SHOW';
    }

    $list = $Dhcphosts->hosts_list({
      NETWORK      => $NET_ID,
      STATUS       => 0,
      CREDIT       => '_SHOW',
      USER_DISABLE => 0,
      LOGIN        => '_SHOW',
      HOSTNAME     => '_SHOW',
      MAC          => '_SHOW',
      IP           => '_SHOW',
      PORTS        => '_SHOW',
      NAS_ID       => '_SHOW',
      OPTION_82    => '_SHOW',
      VID          => '_SHOW',
      BOOT_FILE    => '_SHOW',
      DELETED      => 0,
      NEXT_SERVER  => '_SHOW',
      COLS_NAME    => 1,
      %PARAMS,
      PAGE_ROWS    => 100000,
    });

    foreach my $host (@{$list}) {
      my $deposit = ($host->{deposit} && $host->{deposit} =~ /^\d+$/) ? $host->{deposit} : 0;
      if (defined($conf{DHCPHOSTS_DEPOSITCHECK})
        && $conf{DHCPHOSTS_DEPOSITCHECK} =~ /^\d+$/
        && ($deposit + ($host->{credit} || 0)) < $conf{DHCPHOSTS_DEPOSITCHECK}) {
        next;
      }
      elsif (defined($conf{DHCPHOSTS_EXT_DEPOSITCHECK}) && defined($host->{ext_deposit}) && ($host->{ext_deposit} || 0) < $conf{DHCPHOSTS_EXT_DEPOSITCHECK}) {
        next;
      }

      $INFO{LOGIN} = $host->{login};
      $INFO{CLIENT_MAC} = $host->{mac};
      $INFO{CLIENT_IP} = $host->{ip};

      #Option 82
      if ($host->{option_82}) {
        $INFO{CLIENT_MAC} =~ s/^00/0/;
        $INFO{CLIENT_MAC} =~ s/:0/:/g;
        $INFO{CLIENT_MAC} = lc($INFO{CLIENT_MAC});
        $INFO{OPTION82_NAS_PORT} = $host->{ports};
        $INFO{CLIENT_VLAN} = $host->{vid};
        my @OPTION82_MATCHES = ();

        #Check swich
        if ($NAS_MACS{ $host->{nas_id} }) {
          ($INFO{OPTION82_NAS_NAME}, $INFO{OPTION82_NAS_MAC}) = split(/,/, $NAS_MACS{ $host->{nas_id} }, 2);
          if ($INFO{OPTION82_NAS_MAC} =~ /:/) {
            $INFO{OPTION82_NAS_MAC} =~ s/^00/0/;
            $INFO{OPTION82_NAS_MAC} =~ s/:0/:/g;
          }

          $INFO{OPTION82_NAS_MAC} = lc($INFO{OPTION82_NAS_MAC});
          $INFO{OPTION82_NAS_NAME} =~ s/ /\_/g;
          push @OPTION82_MATCHES,
            "binary-to-ascii(16, 8, \":\", substring(option agent.remote-id, 2, 6)) = \"$INFO{OPTION82_NAS_MAC}\"";
        }
        else {
          if (!$attr->{QUITE} && $host->{nas_id}) {
            #            if(! $AUTH{dhcp} && ! $AUTH{mikrotik_dhcp}){
            #              print "Can't find NAS MAC NAS: '$host->{nas_id}' MAC: $INFO{CLIENT_MAC} LOGIN: $INFO{LOGIN}\n";
            #            }
          }
          $INFO{OPTION82_NAS_NAME} = '';
          $INFO{OPTION82_NAS_MAC} = '';
        }

        #Check nas port
        push @OPTION82_MATCHES,
          "binary-to-ascii(10, 8, \":\", substring(option agent.circuit-id, 5, 1)) = \"$INFO{OPTION82_NAS_PORT}\"" if ($INFO{OPTION82_NAS_PORT} && $INFO{OPTION82_NAS_PORT} ne '');

        #Client MAC
        push @OPTION82_MATCHES,
          "binary-to-ascii (16, 8, \":\", substring(hardware, 1, 7))=\"$INFO{CLIENT_MAC}\"" if ($INFO{CLIENT_MAC} ne '0:0:0:0:0:0' && $conf{DHCPHOSTS_O82_USE_MAC});

        #Vlan option
        push @OPTION82_MATCHES,
          "binary-to-ascii (10, 16, \"\", substring( option agent.circuit-id, 2, 2)) = \"$INFO{CLIENT_VLAN}\" " if ($INFO{CLIENT_VLAN} > 0);

        my $matches = join(' and ', @OPTION82_MATCHES);
        $INFO{DHCPHOSTS_O82_CLASS_NAME} = "$INFO{OPTION82_NAS_NAME}-$INFO{OPTION82_NAS_MAC}-port-$INFO{OPTION82_NAS_PORT}";

        if ($conf{DHCPHOSTS_O82_USE_MAC}) {
          $INFO{OPTION82_CLASS_NAME} .= "-$INFO{CLIENT_MAC}";
        }

        # make custom option 82 tpl
        if ($conf{DHCPHOSTS_O82_CLASS_TPL}) {
          $INFO{OPTION82_CLASS} .= $html->tpl_show(_include('dhcphosts_dhcp_conf_o82_class', 'Dhcphosts'), \%INFO,
            { OUTPUT2RETURN => 1, CONFIG_TPL => 1 });
        }
        else {
          $INFO{OPTION82_CLASS} .= "# LOGIN: $host->{login}\nclass \"$INFO{DHCPHOSTS_O82_CLASS_NAME}\" { match if $matches ;  \n }\n\n";
        }

        $INFO{OPTION82_POOLS} .= "pool { range $host->{ip}; allow members of \"$INFO{DHCPHOSTS_O82_CLASS_NAME}\"; }\n";
      }
      else {
        #Static hosts
        #Skip empty mac or ip
        if ($INFO{CLIENT_MAC} eq '00:00:00:00:00:00' || $INFO{CLIENT_IP} eq '0.0.0.0') {
          next;
        }

        $INFO{HOSTS} .= $html->tpl_show(
          _include('dhcphosts_dhcp_conf_host', 'Dhcphosts',),
          {
            MAC         => $INFO{CLIENT_MAC},
            IP          => $INFO{CLIENT_IP},
            ROUTERS     =>
              ($Dhcphosts->{ROUTERS} ne '0.0.0.0') ? $Dhcphosts->{ROUTERS} : convert_ip("0.0.0.1", '', $Dhcphosts),
            LOGIN       => $host->{login},
            HOSTNAME    => $host->{hostname},
            BOOT_FILE   => ($host->{boot_file}) ? "filename \"" . $host->{boot_file} . "\";" : '',
            NEXT_SERVER => ($host->{next_server}) ? "next-server $host->{next_server};" : '',
          },
          { OUTPUT2RETURN => 1, CONFIG_TPL => 1 }
        );
      }
    }

    $SUBNETS{ $net->{net_parent} }{ $net->{id} } .= $html->tpl_show(_include('dhcphosts_dhcp_conf_subnet', 'Dhcphosts'),
      \%INFO,
      { OUTPUT2RETURN => 1,
        CONFIG_TPL    => 1
      });

    $INFO{SUBNETS} .= $html->tpl_show(_include('dhcphosts_dhcp_conf_subnet', 'Dhcphosts'),
      \%INFO,
      { OUTPUT2RETURN => 1,
        CONFIG_TPL    => 1 });
  }

  $INFO{NETWORKS} = '';
  foreach my $id (sort keys %{ $SUBNETS{0} }) {
    my $net_content = $SUBNETS{0}{$id};
    $INFO{NETWORKS} .= "#share network ID: $id
shared-network $INFO{NETWORK_NAME}_$id {
$net_content";

    #Add subnets
    while (my ($id_sub, $subnet_content) = each %{ $SUBNETS{$id} }) {
      $INFO{NETWORKS} .= "\n# SUBNET ID: $id_sub\n $subnet_content";
    }

    $INFO{NETWORKS} .= "}
#========================\n";
  }

  $conf{DHCPHOSTS_CONFIG} = "/usr/local/etc/dhcpd.conf" if (!$conf{DHCPHOSTS_CONFIG});
  $INFO{LEASES_FILE} = ($conf{DHCPHOSTS_LEASES} && $conf{DHCPHOSTS_LEASES} ne 'db') ? "lease-file-name \"$conf{DHCPHOSTS_LEASES}\";" : "lease-file-name \"/var/db/dhcpd/dhcpd.leases\";";

  if (($attr->{reconfig} || $FORM{reconfig})) {
    my $tpl = $html->tpl_show(_include('dhcphosts_dhcp_conf_main', 'Dhcphosts'), \%INFO,
      { OUTPUT2RETURN => 1,
        CONFIG_TPL    => 1 });

    if (open(my $fh, '>', "$conf{DHCPHOSTS_CONFIG}")) {
      print $fh $tpl;
      close($fh);
    }
    else {
      print "Can't open file '$conf{DHCPHOSTS_CONFIG}' $!";
      return 0;
    }

    $html->message('info', $lang{INFO}, "DHCP $lang{RECONFIGURE} '$conf{DHCPHOSTS_CONFIG}'") if (!$attr->{QUITE});
  }
  else {
    my $conf_content = $html->tpl_show(_include('dhcphosts_dhcp_conf_main', 'Dhcphosts'), \%INFO,
      { OUTPUT2RETURN => 1,
        CONFIG_TPL    => 1 });

    $html->pre($conf{DHCPHOSTS_CONFIG});
    print $html->element('textarea', $conf_content, { cols => 90, rows => 20 });
    print $html->form_main(
      {
        HIDDEN => {
          index  => $index,
          IDS    => $FORM{IDS},
          config => 'dhcp.conf'
        },
        SUBMIT => { reconfig => $lang{RECONFIGURE} },
        METHOD => 'GET'
      }
    );
  }

  dhcphosts_reconfigure({ DEBUG => $FORM{DEBUG} });

  if ($xml_output) {
    $FORM{xml} = 1;
  }

  return 1;
}

#**********************************************************
=head2 dhcphosts_reconfigure($attr) - DHCP server reconfigure

=cut
#**********************************************************
sub dhcphosts_reconfigure {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  if ($conf{INTERNET_DHCP_RECONFIGURE}) {
#    if (-e "/usr/local/etc/rc.d/ipguard.sh" || -e "$var_dir/ipguard") {
#      dhcphosts_mac_block_make() if (!$AUTH{dhcp});
#    }

    my $res = cmd($conf{INTERNET_DHCP_RECONFIGURE},
      { PARAMS  => { %FORM, %{$attr}, },
        SET_ENV => 1
      });
    print $res if ($debug > 2);
  }
  else {
    if ($debug > 0) {
      print $html->message('err', $lang{ERROR},
        "Can't find reconfiguration command " . '"$conf{DHCPHOSTS_RECONFIGURE}"');
    }
  }

  return 1;
}


1;