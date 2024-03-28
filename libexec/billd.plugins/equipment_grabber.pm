=head1 NAME

  equipment grab

  Params:
    SEARCH_MAC

  Arguments:

   CLEAN=1
   IP_RANGE='192.168.1.0/24'
   SNMP_VERSION=1 - Default:1
   INFO_ONLY=1 

=cut


use strict;
use warnings "all";
use AXbills::Base qw(in_array startup_files _bp);
use Nas;
use Equipment;
require Equipment::Snmp_cmd;

use SNMP_util;
use SNMP_Session;
use Events;
use Events::API;
use AXbills::Misc qw(snmp_get host_diagnostic);

our (
  $db,
  %conf,
  $argv,
  $debug,
  $var_dir,
  %lang
);

our Admins $Admin;
my $comments = '';

$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $Equipment = Equipment->new($db, $Admin, \%conf);
my $Nas = Nas->new($db, \%conf, $Admin);
my $Log = Log->new($db, $Admin);
my $Events = Events::API->new($db, $Admin, \%conf);

if ($debug > 2) {
  $Log->{PRINT} = 1;
}
else {
  $Log->{LOG_FILE} = $var_dir . '/log/equipment_check.log';
}

if ($argv->{GET_FW}) {
  equipment_get_version();
}
elsif ($argv->{SCAN_EQUIPMENT_PORTS}) {
  equipment_scan_equipment();
}
elsif ($argv->{DELETE_EQUIPMENT_PORTS}) {
  equipment_delete_ports();
}
else {
  equipment_grab();
}

#**********************************************************
=head2 equipment_check($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub equipment_grab {

  if ($debug > 3) {
    print "Equipment grab\n";
  }

  my @equipment_info = ();
  if ($argv->{FILENAME}) {
    @equipment_info = @{equipment_from_file($argv->{FILENAME})};
  }
  elsif ($argv->{IP_RANGE}) {
    @equipment_info = @{equipment_scan($argv->{IP_RANGE})};
  }
  else {
    print "Show help\n";
  }
  return 1 if ($argv->{INFO_ONLY});
  foreach my $info (@equipment_info) {
    if ($debug > 1) {
      print "$info->{IP}\n";
      foreach my $key (keys %$info) {
        print "$key - $info->{$key}\n";
      }
      print "\n";
    }

    if (!$info->{IP}) {
      next;
    }

    my $nas_list = $Nas->list({
      NAS_IP    => $info->{IP},
      COLS_NAME => 1,
      PAGE_ROWS => 3
    });

    if (!$Nas->{TOTAL}) {
      if ($debug > 2) {
        print "Not exists \n";
      }

      if (!$info->{NAS_TYPE}) {
        $info->{NAS_TYPE} = 'other';
      }

      $Nas->add($info);

      $info->{NAS_ID} = $Nas->{NAS_ID};
    }
    else {
      $info->{NAS_ID} = $nas_list->[0]{nas_id};
    }

    #Check equipment
    $Equipment->_list({ NAS_ID => $info->{NAS_ID} });

    if (!$Equipment->{TOTAL}) {
      $info->{MODEL_ID} = equipment_model_detect($info->{MODEL}) unless ($argv->{IP_RANGE});
      if ($info->{MODEL_ID}) {
        $Equipment->_add($info);
        next;
      }
      elsif ($info->{MODEL}) {
        $comments = "Can't find model '$info->{MODEL}'\n";
        print $comments;
        _generate_new_event('Can\'t find model', $comments);

        next;
      }
    }
    else {
      print "Equipment exist\n" if ($debug);
    }
  }

  return 1;
}


#**********************************************************
=head2 equipment_from_file($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub equipment_from_file {
  my ($filename) = @_;

  my @equipment_info = ();
  my $content = '';
  if (open(my $fh, '<', $filename)) {
    while (<$fh>) {
      $content .= $_;
    }
    close($fh);
  }

  my @rows = split(/[\r]\n/, $content);
  my @cols_name = ();

  if ($argv->{COLS_NAME}) {
    @cols_name = split(/,\s?/, $argv->{COLS_NAME});
  }

  foreach my $line (@rows) {
    my @cols = split(/\t/, $line);
    my %equipment_info = ();

    for (my $i = 0; $i <= $#cols; $i++) {
      my $col_name = ($cols_name[$i]) ? $cols_name[$i] : $i;
      $equipment_info{$col_name} = $cols[$i];
    }

    push @equipment_info, \%equipment_info;
  }

  return \@equipment_info;
}

#**********************************************************
=head2 equipment_model_detect($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub equipment_model_detect {
  my ($model) = @_;
  my $model_id = 0;

  return 0 unless ($model);

  my $list = $Equipment->model_list({
    MODEL_NAME => $model,
    COLS_NAME  => 1
  });

  if ($Equipment->{TOTAL}) {
    $model_id = $list->[0]->{id};
  }

  return $model_id;
}

#**********************************************************
=head2 equipment_scan($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub equipment_scan {
  my ($ip_range) = @_;

  my ($ip, $mask) = split /\//, $ip_range;
  die "Wrong mask: '$mask'" unless ($mask > 0 && $mask < 32);
  my $ip_count = 2 ** (32 - $mask);
  my $split_ip = my ($w, $x, $y, $z) = split /\./, $ip;
  die "Wrong ip: '$ip'" unless ($split_ip == 4);

  my $i = 0;
  my @info = ();

  my $list = $Equipment->model_list({
    MODEL_NAME => '_SHOW',
    COLS_NAME  => 1,
  });

  while (++$i < $ip_count) {
    my %host = ();
    $z++;
    if ($z > 255) {
      $z = 1;
      $y++;
    }
    last if ($y > 255);

    print "check $w.$x.$y.$z\n" if ($argv->{DEBUG} || $argv->{INFO_ONLY});

    my $ping = host_diagnostic("$w.$x.$y.$z", {
      QUITE         => 1,
      RETURN_RESULT => 1,
    });

    next if (!$ping);

    $host{IP} = "$w.$x.$y.$z";
    $host{NAS_NAME} = join('_', $w, $x, $y, $z);

    $host{COMMENTS} = snmp_get({
      SNMP_COMMUNITY => $host{IP},
      OID            => ".1.3.6.1.2.1.1.1.0",
      SILENT         => 1,
      VERSION        => $argv->{SNMP_VERSION} || 1
    });

    if ($host{COMMENTS}) {
      print "SNMP answer: '$host{COMMENTS}'\n" if ($argv->{DEBUG} || $argv->{INFO_ONLY});
      $host{MULTY_RESULT} = '';
      foreach (@$list) {
        next unless ($_->{model_name});
        if ($host{COMMENTS} =~ m/$_->{model_name}/) {
          print "Found matches:\n model_id: '$_->{id}'\n model_name: '$_->{model_name}'\n" if ($argv->{DEBUG} || $argv->{INFO_ONLY});

          if ($host{MODEL_ID}) {
            $host{MULTY_RESULT} .= "$_->{id}, "
          }
          else {
            $host{MODEL_ID} = $_->{id};
          }
        }
      }
    }
    $host{COMMENTS} .= "\n Also found matches $host{MULTY_RESULT}" if ($host{MULTY_RESULT});

    push @info, \%host;
  }
  return \@info;
}

#**********************************************************
=head2 equipment_get_version()

  Arguments:

=cut
#**********************************************************
sub equipment_get_version {

  my $Equipment_List = $Equipment->_list({
    COLS_NAME        => 1,
    NAS_MNG_HOST_PORT=> '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    PAGE_ROWS        => 65000,
  });

  foreach my $element (@$Equipment_List) {
    if ($element->{nas_mng_ip_port} && $element->{nas_mng_ip_port} ne '') {
      my $snmp_com = "$element->{nas_mng_password}" . "@" . "$element->{nas_mng_ip_port}";
      my $Version = snmp_get({
        SNMP_COMMUNITY => $snmp_com,
        OID            => ".1.3.6.1.4.1.14988.1.1.4.4.0",
        SILENT         => 1,
        VERSION        => $argv->{SNMP_VERSION} || 1
      });

      if ($Version) {
        $Equipment->_change({
          NAS_ID   => $element->{nas_id},
          FIRMWARE => $Version,
        });
      }
    }
  }
}


#**********************************************************
=head2 equipment_scan_equipment()

  Arguments:

=cut
#**********************************************************
sub equipment_scan_equipment {

  my $Equipment_List = $Equipment->_list({
    NAS_ID           => $argv->{NAS_ID} || '',
    COLS_NAME        => 1,
    NAS_MNG_HOST_PORT=> '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    PORTS            => '_SHOW',
    PAGE_ROWS        => 65000,
    STATUS           => '!5;!1;!4'
  });

  my %Port_id = ();

  foreach my $element (@$Equipment_List) {
    print "Scanning devices: $element->{nas_id}\n";
    my $ports_list = $Equipment->port_list({
      COLS_NAME => 1,
      ID        => '_SHOW',
      NAS_ID    => $element->{nas_id},
      PAGE_ROWS => 65000,
    });

    my $snmp_com = "$element->{nas_mng_password}" . "@" . "$element->{nas_mng_ip_port}";
#    my $snmp_com = "snmppass" . "@" . "$element->{nas_mng_ip_port}";
    my $all_ports = snmp_get({
      SNMP_COMMUNITY => $snmp_com,
      OID            => ".1.3.6.1.2.1.2.2.1.8",
      WALK           => 1,
      VERSION        => $argv->{SNMP_VERSION} || 2,
    });

    if (@$all_ports) {
      my @exPorts = ();
      foreach my $port (@$ports_list) {
        push @exPorts, $port->{port};
        $Port_id{"$port->{port}"} = $port->{id};
      }

      foreach my $port (@$all_ports) {
        my ($port_number, $port_status) = split(/:/, $port);
        if (!in_array($port_number, \@exPorts)) {
          $Equipment->port_add({
            NAS_ID => $element->{nas_id},
            STATUS => $port_status,
            PORT   => $port_number,
          });
        }
        else {
          $Equipment->port_change({
            ID     => $Port_id{$port_number},
            STATUS => $port_status,
          });
        }
      }
    }

    $ports_list = $Equipment->port_list({
      COLS_NAME => 1,
      ID        => '_SHOW',
      NAS_ID    => $element->{nas_id},
      PAGE_ROWS => 65000,
    });

    foreach my $port (@$ports_list) {
      $Port_id{"$port->{port}"} = $port->{id};
    }

    _equipment_port_vlan($snmp_com, \%Port_id);
    _equipment_port_description($snmp_com, \%Port_id);
  }

  return 1;
}


#**********************************************************
=head2 _equipment_port_vlan()

  Arguments:
    $snmp_com,   - SNMP_COMMUNITY string
    $Port_id     - hash with current port

=cut
#**********************************************************
sub _equipment_port_vlan {
  my ($snmp_com, $Port_id) = @_;

  my $All_ports = snmp_get({
    SNMP_COMMUNITY => $snmp_com,
    OID            => ".1.3.6.1.2.1.17.7.1.4.5.1.1",
    WALK           => 1,
    VERSION        => $argv->{SNMP_VERSION} || 2,
  });

  if (@$All_ports) {
    foreach my $port (@$All_ports) {
      my ($port_number, $port_vlan) = split(/:/, $port);

      $Equipment->port_change({
        ID   => $Port_id->{$port_number},
        VLAN => $port_vlan,
      });
    }
  }
}

#**********************************************************
=head2 _equipment_port_description()

  Arguments:
    $snmp_com,   - SNMP_COMMUNITY string
    $Port_id     - hash with current port

=cut
#**********************************************************
sub _equipment_port_description {
  my ($snmp_com, $Port_id) = @_;

  my $All_ports = snmp_get({
    SNMP_COMMUNITY => $snmp_com,
    OID            => ".1.3.6.1.2.1.2.2.1.2",
    WALK           => 1,
    VERSION        => $argv->{SNMP_VERSION} || 2,
  });

  if (@$All_ports) {
    foreach my $port (@$All_ports) {
      my ($port_number, $port_description) = split(/:/, $port);

      $Equipment->port_change({
        ID       => $Port_id->{$port_number},
        COMMENTS => $port_description,
      });
    }
  }
}

#**********************************************************
=head2 equipment_delete_ports()

  Arguments:

=cut
#**********************************************************
sub equipment_delete_ports {

  if ($argv->{NAS_ID}){
    $Equipment->port_del_nas({
      NAS_ID => $argv->{NAS_ID},
    })
  }
}

#**********************************************************
=head2 _generate_new_event($title_event, $comments)

  Arguments:
    $title_event - title of message
    $comments - text of message to show

  Returns:

=cut
#**********************************************************
sub _generate_new_event {
  my ($title_event, $comments) = @_;

  $Events->add_event({
    MODULE      => 'Equipment',
    TITLE       => $title_event,
    COMMENTS    => "equipment_grabber - $comments",
    PRIORITY_ID => 3
  });

  return 1;
}

1;
