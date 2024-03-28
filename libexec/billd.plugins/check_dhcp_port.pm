# billd plugin
#
# DESCRIBE: Check dhcp port
#
#**********************************************************

check_dhcp_port();

#**********************************************************
#
#
#**********************************************************
sub check_dhcp_port {
  use Data::Dumper;
  require Dhcphosts;
  $Dhcphosts = Dhcphosts->new($db, $Admin, \%conf);
  my $leases_list = $Dhcphosts->leases_list({STATE => 2, COLS_NAME => 1, PAGE_ROWS => 10000  });
  my $hosts_list = $Dhcphosts->hosts_list({STATE => 2, COLS_NAME => 1, PAGE_ROWS => 10000, VID => _SHOW, MAC => _SHOW, NAS_ID => _SHOW, PORTS => _SHOW, IP => _SHOW });

  my %hosts_hash = ();
  foreach my $line (@$hosts_list) {
    $hosts_hash{ $line->{ip} }->{id} = $line->{id};
    $hosts_hash{ $line->{ip} }->{nas_id} = $line->{nas_id} || '0';
    $hosts_hash{ $line->{ip} }->{vlan} = $line->{vid} || '0';
    $hosts_hash{ $line->{ip} }->{port} = $line->{ports} || '0';
    $hosts_hash{ $line->{ip} }->{mac} = $line->{mac};

  }
  foreach my $line (@$leases_list) {
    if ($line->{uid} > 0 && !$line->{flag} && ($line->{nas_id} ne $hosts_hash{ $line->{ip} }->{nas_id} ||
        $line->{vlan} ne $hosts_hash{ $line->{ip} }->{vlan} ||
         $line->{port} ne $hosts_hash{ $line->{ip} }->{port} ||
         $line->{hardware} ne $hosts_hash{ $line->{ip} }->{mac})) {
      print "UID : $line->{uid} IP : $line->{ip} NAS_ID : $hosts_hash{ $line->{ip} }->{nas_id} VLAN : $hosts_hash{ $line->{ip} }->{vlan} PORT : $hosts_hash{ $line->{ip} }->{port} \n" if ($debug > 3);

      if ($line->{nas_id} ne $hosts_hash{ $line->{ip} }->{nas_id}) {
        $admin->action_add("$line->{uid}", "CHANGE NAS_ID : $hosts_hash{ $line->{ip} }->{nas_id} -> $line->{nas_id} ", { MODULE => 'Dhcphosts', TYPE => 1 }) if ($debug < 3);
        print  "CHANGE NAS_ID : $hosts_hash{ $line->{ip} }->{nas_id} -> $line->{nas_id}\n" if ($debug > 3);
      }
      if ($line->{vlan} ne $hosts_hash{ $line->{ip} }->{vlan}) {
        $admin->action_add("$line->{uid}", "CHANGE VLAN : $hosts_hash{ $line->{ip} }->{vlan} -> $line->{vlan}", { MODULE => 'Dhcphosts', TYPE => 1 }) if ($debug < 3);
        print  "CHANGE VLAN : $hosts_hash{ $line->{ip} }->{vlan} ->  $line->{vlan}\n" if ($debug > 3);
      }
      if ($line->{port} ne $hosts_hash{ $line->{ip} }->{port}) {
        $admin->action_add("$line->{uid}", "CHANGE PORT : $hosts_hash{ $line->{ip} }->{port} -> $line->{port}", { MODULE => 'Dhcphosts', TYPE => 1 }) if ($debug < 3);
        print  "CHANGE PORT : $hosts_hash{ $line->{ip} }->{port} ->  $line->{port}\n" if ($debug > 3);
      }
#      if ($line->{hardware} ne $hosts_hash{ $line->{ip} }->{mac}) {
#        $admin->action_add("$line->{ip}", "CHANGE MAC : $hosts_hash{ $line->{ip} }->{mac} -> $line->{hardware}", { MODULE => 'Dhcphosts', TYPE => 1 }) if ($debug < 3);
#        print  "CHANGE MAC : $hosts_hash{ $line->{ip} }->{mac} ->  $line->{hardware}\n" if ($debug > 3);
#      }
      if ($debug < 3) {
        $Dhcphosts->host_change(
          {
            ID     => $hosts_hash{ $line->{ip} }->{id},
            NAS_ID => $line->{nas_id},
            VID    => $line->{vlan},
            PORTS  => $line->{port},
#            MAC    => $line->{hardware}
          }
        );
      }
      print "***************\n" if ($debug > 3);
    } 
  }
}

1


