=head1 NAME

  Mikrotik: Check speed and reconfigure

  Argumnets:
   RECONFIGURE=1
   NAT=1
   DOMAIN_ID=1
   EXPORT_FILE=export.rsh - Export rules to file
   SHOW_SPEED  - Show list ips
   SKIP_NAT_IPS="xxx,xxx"
   NAT_LIST="xx.xx.xx.xx-xx.xx.xx.xx"
   SINGLE_THREAD - Make all commands in one connection
   SIMPLE - Check simple quese (By API)

   SSH_CMD
   SSH_PORT

=cut
#**********************************************************

use warnings;
use strict;
require AXbills::Nas::Mikrotik;
AXbills::Nas::Mikrotik->import();

our (
  $Nas,
  $debug,
  $db,
  $argv,
  $Admin,
  $base_dir
);

if($argv->{SIMPLE}) {
  if($debug > 3) {
    print "Mikrotik simple check\n";
  }

  check_speed2({
    NAS_TYPE     => 'mikrotik',
    SET_SPEED_FN => 'mikrotik_set_speed'
  });
}
else {
  mikrotik_check_speed();
}

#**********************************************************
=head2 check_speed_mikrotik($attr) Manage mikrotik bandwidth

  Arguments:
    ARGV
      SSH_PORT
      SSH_CMD
      MIKROTIK6
      RECONFIGURE  - Reconfigure shaper
      SHOW_SPEED   - Show current speed
      NAT          - Configure NAT (Autoconfigure from: $base_dir/libexec/mikrotik.nat)
      SKIP_NAT_IPS - Skip Nat ips
      EXPORT_FILE

  Actions:
    up
    down
    check

=cut
#**********************************************************
sub mikrotik_check_speed {
  my ($attr) = @_;
  
  my $Tariffs = Tariffs->new($db, \%conf, $Admin);
  
  if ( !$LIST_PARAMS{NAS_IDS} ) {
    $LIST_PARAMS{NAS_TYPE} = 'mikrotik,mikrotik_dhcp';
  }
  
  if ( $argv->{DOMAIN_ID} ) {
    $LIST_PARAMS{DOMAIN_ID} = $argv->{DOMAIN_ID};
  }
  
  my $result = '';
  my $parent_in = 'global-in';
  my $parent_out = 'global-out';
  
  $Nas->{debug} = 1 if ( $debug > 5 );
  my $nas_list = $Nas->list({
    %LIST_PARAMS,
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    PAGE_ROWS  => 50000,
    DOMAIN_ID  => '_SHOW',
  });
  
  foreach my $nas_info ( @{$nas_list} ) {
    my @commands = ();
    if ( $debug > 0 ) {
      print "NAS: ($nas_info->{NAS_ID}) $nas_info->{NAS_IP} NAS_TYPE: $nas_info->{NAS_TYPE} STATUS: $nas_info->{NAS_DISABLE} Alive: $nas_info->{NAS_ALIVE}\n";
      $nas_info->{DEBUG} = $debug;
    }

    #Get TP speed
    my ($TARIF_SPEEDS, $class2nets) = get_tp_cure_speed({
      %{ ($attr) ? $attr : {} },
      DOMAIN_ID => $nas_info->{DOMAIN_ID}
    });
    
    my %TARIF_SPEEDS = %{ $TARIF_SPEEDS };
    my %class2nets = %{ $class2nets };
    
    $nas_info->{EXPORT_FILE} = $argv->{EXPORT_FILE};
    
    if ( $argv->{SSH_PORT} ) {
      $nas_info->{SSH_PORT} = int($argv->{SSH_PORT});
    }
    else {
      my (undef, undef, $ssh_port, undef) = split(/:/, $nas_info->{NAS_MNG_IP_PORT} || q{});
      $nas_info->{SSH_PORT} = $ssh_port || 22;
    }
    
    if ( $argv->{SSH_CMD} ) {
      $nas_info->{SSH_CMD} = $argv->{SSH_CMD}
    }
    
    if ( $argv->{MIKROTIK6} ) {
      $parent_in = 'global';
      $parent_out = 'global';
    }
    #Get mikrotik version
    elsif ( !$argv->{EXPORT_FILE} ) {
      my $soft_line = get_mikrotik_value(qq{ /system package print where name~"system" }, $nas_info);
      
      my @mikrotik_os_version = split(/\s+/, $soft_line->[2] || q{});
      if ( $mikrotik_os_version[3] && $mikrotik_os_version[3] =~ /^6/ ) {
        $parent_in = 'global';
        $parent_out = 'global';
      }
      
      if ( $debug > 0 && $mikrotik_os_version[3] ) {
        print "Mikrotik Version: $mikrotik_os_version[3]\n";
      }
    }
    
    if ( $argv->{RECONFIGURE} ) {
      if ( $argv->{TP_ID} ) {
        foreach my $tp_id  ( keys %{$TARIF_SPEEDS} ) {
          $tp_id .= '_';
          push @commands, qq{/ip firewall mangle remove [find new-packet-mark~"^ALLOW_TRAFFIC_CLASS"]},
            qq{/queue tree remove [find name~"^TP_$tp_id"]},
            qq{/queue type remove [find name~"^TP_$tp_id"]};
        }
      }
      else {
        push @commands, qq{/ip firewall mangle remove [find new-packet-mark~"^ALLOW_TRAFFIC_CLASS"]},
          qq{/queue tree remove [find name~"^TP"]},
          qq{/queue type remove [find name~"^TP"]};
      }
      
      if ( $argv->{NAT} ) {
        push @commands, qq{/ip firewall nat remove [find src-address-list~"^CLIENTS"]},
          qq{/ip firewall nat remove [find src-address-list~"CUSTOM_SPEED"]},
          qq{/ip firewall nat add chain=srcnat src-address-list="CUSTOM_SPEED" action=masquerade comment="ABillS Masquerade CUSTOM"};
      }
    }
    
    # Get mikrotik speed
    #show ips
    if ( $argv->{SHOW_SPEED} ) {
      my $ip_list = get_mikrotik_value(qq{ /ip firewall address-list print }, $nas_info);
      foreach my $line ( @{$ip_list} ) {
        $line =~ s/[\r\n]+//g;
        if ( $line ) {
          my ($id, $list_name, $ip) = split(/\s+/, $line);
          print "id: $id Listname: $list_name IP: $ip\n";
        }
      }
      next;
    }
    
    my $count;
=comments

> /queue tree print
Flags: X - disabled, I - invalid
 0   name="TP_102_in_global" parent=global-in packet-mark=ALLOW_GLOBAL_102
     limit-at=5242880 queue=default priority=5 max-limit=5242880 burst-limit=0
     burst-threshold=0 burst-time=0s

 1   name="TP_102_out_global" parent=global-out packet-mark=ALLOW_GLOBAL_102
     limit-at=5242880 queue=default priority=5 max-limit=5242880 burst-limit=0
     burst-threshold=0 burst-time=0s
=cut
    
    #Apply speed for all mikrotik NAS
    foreach my $tp_id ( sort keys %TARIF_SPEEDS ) {
      my $speeds = $TARIF_SPEEDS{$tp_id};
      
      foreach my $traf_type ( sort keys %{$speeds} ) {
        my $speed = $speeds->{$traf_type};
        my $speed_in = (defined($speed->{IN})) ? $speed->{IN} * 1024 : 0;
        my $speed_out = (defined($speed->{OUT})) ? $speed->{OUT} * 1024 : 0;
        my $priority = 5 - $traf_type;
        
        print "Add shaper: TP_ID: $tp_id Class: $traf_type IN: $speed_in  OUT: $speed_out\n" if ( $debug > 0 );
        
        #Burst limit
        my $speed_bt_in = 0;
        my $speed_bt_out = 0;
        my $speed_bl_in = 0;
        my $speed_bl_out = 0;
        my $burst_time_in = 0;
        my $burst_time_out = 0;
        
        #Enable burst
        if ( $conf{MIKROTIK_BURST} ) {
          $conf{MIKROTIK_BURST_COEF} = '2' if ( !($conf{MIKROTIK_BURST_COEF}) );
          $conf{MIKROTIK_BURST_COEF_THRESHOLD} = '0.75' if ( !($conf{MIKROTIK_BURST_COEF_THRESHOLD}) );
          $conf{MIKROTIK_BURST_TIME} = '8' if ( !($conf{MIKROTIK_BURST_TIME}) );
          
          $speed_bl_in = sprintf("%d", $speed_in * $conf{MIKROTIK_BURST_COEF});
          $speed_bl_out = sprintf("%d", $speed_out * $conf{MIKROTIK_BURST_COEF});
          $speed_bt_in = sprintf("%d", $speed_in * $conf{MIKROTIK_BURST_COEF_THRESHOLD});
          $speed_bt_out = sprintf("%d", $speed_out * $conf{MIKROTIK_BURST_COEF_THRESHOLD});
          $burst_time_in = $conf{MIKROTIK_BURST_TIME};
          $burst_time_out = $conf{MIKROTIK_BURST_TIME};
        }
        else {
          #Burst
          # out - from client
          if ( $speed->{BURST_LIMIT_DL} ) {
            if ( $debug > 1 ) {
              print "  Burst: BURST_LIMIT_DL: $speed->{BURST_LIMIT_DL} BURST_THRESHOLD_DL: $speed->{BURST_THRESHOLD_DL} BURST_TIME_DL: $speed->{BURST_TIME_DL}\n";
            }
            
            $speed_bl_out = $speed->{BURST_LIMIT_DL} * 1024;
            $speed_bt_out = $speed->{BURST_THRESHOLD_DL} * 1024;
            $burst_time_out = $speed->{BURST_TIME_DL};
          }
          
          # in  - to client
          if ( $speed->{BURST_LIMIT_UL} ) {
            if ( $debug > 1 ) {
              print "  Burst: BURST_LIMIT_UL: $speed->{BURST_LIMIT_UL} BURST_THRESHOLD_UL: $speed->{BURST_THRESHOLD_UL} BURST_TIME_UL: $speed->{BURST_TIME_UL}\n";
            }
            
            $speed_bl_in = $speed->{BURST_LIMIT_UL} * 1024;
            $speed_bt_in = $speed->{BURST_THRESHOLD_UL} * 1024;
            $burst_time_in = $speed->{BURST_TIME_UL};
          }
        }
        
        my $burst_time_option_in = '';
        my $burst_time_option_out = '';
        
        if ( $burst_time_in ) {
          $burst_time_option_in = "pcq-burst-time=" . $burst_time_in . 's';
        }
        
        if ( $burst_time_out ) {
          $burst_time_option_out = "pcq-burst-time=" . $burst_time_out . 's';
        }
        
        #Global Shapper
        if ( $traf_type == 0 ) {
          $count = ($argv->{RECONFIGURE}) ? [ 0 ] : get_mikrotik_value(
              '/ip firewall mangle print count-only where new-packet-mark=ALLOW_TRAFFIC_CLASS_' . $tp_id . '_in',
              $nas_info);
          
          if ( !$count->[0] || $count->[0] == 0 ) {
            push @commands,
              "/ip firewall mangle add chain=forward action=mark-packet new-packet-mark=ALLOW_TRAFFIC_CLASS_" . $tp_id . '_out' . " passthrough=yes src-address-list=CLIENTS_$tp_id dst-address=0.0.0.0/0";
            push @commands,
              "/ip firewall mangle add chain=forward action=mark-packet new-packet-mark=ALLOW_TRAFFIC_CLASS_" . $tp_id . '_in'
                . " passthrough=yes src-address=0.0.0.0/0 dst-address-list=CLIENTS_$tp_id";
            push @commands,
              "/queue type add name=" . 'TP_' . $tp_id . "_out_global_speed kind=pcq pcq-rate=$speed_in pcq-classifier=src-address pcq-burst-rate=$speed_bl_in pcq-burst-threshold=$speed_bt_in $burst_time_option_in";
            push @commands,
              "/queue type add name=" . 'TP_' . $tp_id . "_in_global_speed kind=pcq pcq-rate=$speed_out pcq-classifier=dst-address pcq-burst-rate=$speed_bl_out pcq-burst-threshold=$speed_bt_out $burst_time_option_out";
            
            push @commands,
              "/queue tree add name=" . 'TP_' . $tp_id . "_in_global parent=$parent_out queue=" . 'TP_' . $tp_id . "_in_global_speed packet-mark=ALLOW_TRAFFIC_CLASS_" . $tp_id . '_in' . " priority=$priority";
            push @commands,
              "/queue tree add name=" . 'TP_' . $tp_id . "_out_global parent=$parent_out queue=" . 'TP_' . $tp_id . "_out_global_speed packet-mark=ALLOW_TRAFFIC_CLASS_" . $tp_id . '_out' . " priority=$priority";
          }
        }
        #Peering shapper
        else {
          #Check TP,
          $count = ($argv->{RECONFIGURE}) ? [ 0 ] : get_mikrotik_value(
              "/ip firewall mangle print count-only where new-packet-mark=ALLOW_TRAFFIC_CLASS_" . $tp_id . '_' . $traf_type . '_in'
              , $nas_info);
          my $net_id = $class2nets{$tp_id}->{$traf_type};
          if ( !$count->[0] || $count->[0] == 0 ) {
            push @commands,
              "/ip firewall mangle add chain=forward action=mark-packet new-packet-mark=ALLOW_TRAFFIC_CLASS_"
                . $tp_id . '_'
                . $traf_type . '_out'
                . " passthrough=yes src-address-list=CLIENTS_$tp_id dst-address-list=TRAFFIC_CLASS_$net_id ";
            push @commands,
              "/ip firewall mangle add chain=forward action=mark-packet new-packet-mark=ALLOW_TRAFFIC_CLASS_"
                . $tp_id . '_'
                . $traf_type . '_in'
                . " passthrough=yes src-address-list=TRAFFIC_CLASS_$net_id dst-address-list=CLIENTS_$tp_id ";
            push @commands,
              "/queue type add name=\"" . 'TP_' . $tp_id . "_in_traffic_class_" . $traf_type . "\" kind=pcq pcq-rate=$speed_out pcq-classifier=dst-address ";
            push @commands,
              "/queue type add name=\"" . 'TP_' . $tp_id . "_out_traffic_class_" . $traf_type . "\" kind=pcq pcq-rate=$speed_in pcq-classifier=src-address ";
            push @commands,
              "/queue tree add name=\"" . 'TP_'
                . $tp_id
                . "_in_traffic_class_"
                . $traf_type
                . "\" parent=$parent_out queue=\"" . 'TP_'
                . $tp_id
                . "_in_traffic_class_"
                . $traf_type
                . "\" packet-mark=ALLOW_TRAFFIC_CLASS_"
                . $tp_id . '_'
                . $traf_type . '_in'
                . " priority=$priority burst-limit=$speed_bl_in burst-threshold=$speed_bt_in $burst_time_option_in";
            push @commands,
              "/queue tree add name=\"" . 'TP_'
                . $tp_id
                . "_out_traffic_class_"
                . $traf_type
                . "\" parent=$parent_out queue=\"" . 'TP_'
                . $tp_id
                . "_out_traffic_class_"
                . $traf_type
                . "\" packet-mark=ALLOW_TRAFFIC_CLASS_"
                . $tp_id . '_'
                . $traf_type . '_out'
                . " priority=$priority burst-limit=$speed_bl_out burst-threshold=$speed_bt_in $burst_time_option_out";
          }
        }
      }
      
      #Add nat rules
      if ( $argv->{NAT} && !-f "$base_dir/libexec/mikrotik.nat" ) {
        my $skip_nat_ips = ($argv->{SKIP_NAT_IPS}) ? " dst-address=!$argv->{SKIP_NAT_IPS}" : '';
        my $nat_ips = q{};
        my $action = q{masquerade};

        if($argv->{NAT_LIST}) {
          $nat_ips = " to-addresses=$argv->{NAT_LIST}";
          $action = 'same';
        }

        push @commands,
          qq{/ip firewall nat add chain=srcnat action=$action $skip_nat_ips comment="ABillS Masquerade TP_$tp_id" src-address-list=CLIENTS_$tp_id $nat_ips };
      }
    }
    
    #Add/Check Nets
    my $list = $Tariffs->traffic_class_list();
    foreach my $line ( @{$list} ) {
      my $id = $line->[0];
      my $nets = $line->[2];
      if ( !$argv->{EXPORT_FILE} ) {
        $count = get_mikrotik_value(qq{/ip firewall address-list print count-only where list=TRAFFIC_CLASS_$id },
          $nas_info);
      }
      
      #Add traffic_class nets
      my @nets_arr = ();
      $nets =~ s/[\r\n]+//g;
      $nets =~ s/;/,/g;
      $nets =~ s/ //g;
      @nets_arr = split(/,/, $nets);
      
      if ( !$count->[0] || $count->[0] < $#nets_arr + 1 ) {
        foreach my $address ( @nets_arr ) {
          push @commands, qq{ /ip firewall address-list add list=TRAFFIC_CLASS_$id address=$address };
        }
      }
    }
    
    #add external nat
    if ( $argv->{NAT} && -f "$base_dir/libexec/mikrotik.nat" ) {
      my $skip_nat_ips = ($argv->{SKIP_NAT_IPS}) ? " dst-address=!$argv->{SKIP_NAT_IPS}" : '';
      
      my @nat_cmd = ();
      
      if ( open(my $fh, '<', "$base_dir/libexec/mikrotik.nat") ) {
        my $content = '';
        
        while ( <$fh> ) {
          $content .= $_;
        }
  
        # Remove all previous rules for file
        push @nat_cmd, qq{/ip firewall nat remove [find comment="ABillS Extended NAT"]};
        
        my @rows = split(/[\r\n]+/, $content);
        foreach my $line ( @rows ) {
          chomp($line);
          my ($nas_id, $external_ip, $nets) = split(/\s+/, $line, 3);
          if ( $nas_id eq $nas_info->{nas_id} ) {
            print "NAT: $nets -> $external_ip \n" if ( $debug > 1 );
            
            my $params = '';
            # If tp per external ip
            if ( $nets =~ /^CLIENTS_/ ) {
              $params = " src-address-list=$nets";
            }
            # If net per external ip
            else {
              $params = " src-address=$nets";
            }
            
            push @nat_cmd,
              qq{/ip firewall nat add chain=srcnat action=netmap $skip_nat_ips $params to-addresses=$external_ip comment="ABillS Extended NAT" };
          }
        }
        
        close($fh);
      }
      
      @commands = (@nat_cmd, @commands);
    }

    if (-f "$base_dir/libexec/mikrotik.fw") {

      if (open(my $fh, '<', "$base_dir/libexec/mikrotik.fw")) {
        my $content = '';

        while (<$fh>) {
          $content .= $_;
        }

        my @rows = split(/[\r\n]+/, $content);
        foreach my $line (@rows) {
          chomp($line);
          push @commands, $line;
        }
        close($fh);
      }
    }

    push @commands, qq{/queue tree disable [find name~"^TP"]};
    push @commands, qq{/queue tree enable [find name~"^TP"]};

    if($argv->{SINGLE_THREAD}) {
      $nas_info->{SINGLE_THREAD}=1;
    }

    #Make ssh command
    get_mikrotik_value(\@commands, $nas_info);
    if ( $nas_info->{EXPORT_FILE} ) {
      last;
    }
  }
  
  print $result;
  
  return 1;
}

#**********************************************************
=head2 get_mikrotik_speed_list($attr) Manage mikrotik bandwidth

  Arguments:
    ARGV

  Actions:

=cut
#**********************************************************
sub get_mikrotik_speed_list {
  my ($attr) = @_;

  if($debug > 2) {
    print "Get shapers from mikrotik\n";
  }

  my $Mikrotik = AXbills::Nas::Mikrotik->new(
    $attr,
    \%conf,
    {
      FROM_WEB         => 1,
      MESSAGE_CALLBACK => sub { print('info', $_[0], $_[1]) },
      ERROR_CALLBACK   => sub { print('err', $_[0], $_[1]) },
      DEBUG            => ($debug && $debug > 2) ? $debug : 0,
      API_BACKEND      => $conf{MIKROTIK_API}
    }
  );

  if(! $Mikrotik) {
    print "ERROR: Not defined NAS IP address and Port\n";
    return 0;
  }
  elsif ($Mikrotik->has_access() != 1){
    print "ERROR: No access to $Mikrotik->{ip_address}:$Mikrotik->{port} ($Mikrotik->{backend})"
      . (($Mikrotik->{errstr}) ? "\n $Mikrotik->{errstr}\n" : q{});
    return 0;
  }

  my $cmd = q{/queue simple};

  my (undef, @rules ) = $Mikrotik->{executor}->mtik_query( $cmd . ' print',
    {'.proplist' => '.id,name,max-limit,target' },
    {}
  );

  my %simple_rules = ();
  foreach my $rule ( @rules ) {
    if($debug > 1) {
      print "ID: $rule->{'.id'} NAME: $rule->{'name'} IN/OUT $rule->{'max-limit'} IP: $rule->{'target'}\n";
    }

    my $username = $rule->{'name'};
    my ($in,$out)=split(/\//, $rule->{'max-limit'});
    $simple_rules{$username}{IN} = $in / 1000;
    $simple_rules{$username}{OUT} = $out / 1000;
    $simple_rules{$username}{ID}  = $rule->{'.id'};
  }

  return \%simple_rules;
}

#**********************************************************
=head2 mikrotik_set_speed($nas_info, $port, $user_name, $speed_in, $speed_out, $attr) Manage mikrotik bandwidth

  Arguments:
    $nas_info,
    $port,
    $user_name,
    $speed_in,
    $speed_out,
    $attr

  Actions:

=cut
#**********************************************************
sub mikrotik_set_speed {
  my ($nas_info, $port, $user_name, $speed_in, $speed_out, $attr)=@_;

  if($debug > 1) {
    print "Set speed:\n";
  }

  my $Mikrotik = AXbills::Nas::Mikrotik->new(
    $nas_info,
    \%conf,
    {
      FROM_WEB         => 1,
      MESSAGE_CALLBACK => sub { print('info', $_[0], $_[1]) },
      ERROR_CALLBACK   => sub { print('err', $_[0], $_[1]) },
      DEBUG            => ($debug && $debug > 2) ? $debug : 0,
      API_BACKEND      => $conf{MIKROTIK_API}
    }
  );

  if(! $Mikrotik) {
    print "ERROR: Not defined NAS IP address and Port\n";
    return 0;
  }
  elsif ($Mikrotik->has_access() != 1){
    print "ERROR: No access to $Mikrotik->{ip_address}:$Mikrotik->{port} ($Mikrotik->{backend})"
      . (($Mikrotik->{errstr}) ? "\n$Mikrotik->{errstr}" : q{});
    return 0;
  }

  if($attr->{ID}) {
    print "Try to del: $attr->{ID} USER_NAME: $user_name\n" if ($debug > 1);
    my $cmd = '/queue simple';
    my %list_params = ( name => $user_name );
    my (undef, @rules ) = $Mikrotik->{executor}->mtik_query( $cmd . ' print',
      {'.proplist' => '.id,name' },
      \%list_params
    );
    foreach my $rule ( @rules ) {
      if($attr->{list_expr} && $rule->{'list'} !~ /$attr->{list_expr}/) {
        next;
      }

      print "DEL ID: $rule->{'.id'} NAME: $rule->{'name'}\n" if($debug > 3);

      $Mikrotik->{executor}->mtik_cmd( $cmd . ' remove', {
        '.id' => $rule->{'.id'},
      });
    }
  }

  my %list_params = (
    'name'      => $user_name,
    'target'    => $attr->{FRAMED_IP_ADDRESS},
    'max-limit' => $speed_in.'000/'. $speed_out .'000'
  );

  $Mikrotik->execute([
    [
      qq{/queue simple add },
      \%list_params
    ]
  ]);

  return 1;
}

1;