=head1 NAME equipment_netmap_render

   getting neighbours from core and add:

   nas servers
   equipment
   equipent_ports

   ATTRIBUTES:
    SNMP_VERSION=v2c
    DEBUG
    CORE=192.168.23.13 - ip addres of main switch
    COMMUNITY - SNMP community (default publick)


=cut

use warnings FATAL => 'all';
use strict;
use AXbills::Base qw(in_array startup_files _bp in_array);
use Net::SNMP;
use Equipment;
use Nas;
require Equipment::Snmp_cmd;
use feature qw(say);

use SNMP_util;
use SNMP_Session;
use AXbills::Misc qw(snmp_get);

our (
  $db,
  %conf,
  $argv,
  $debug,
  $var_dir,
  %lang
);

our Admins $Admin;

$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $Nas = Nas->new($db, \%conf, $Admin);
my $Equipment = Equipment->new($db, $Admin, \%conf);


my @serials = ();
my @ips = ();
my @info = ();

equipment_grab();


#***************************************************************************
=heade2 equipment_grab() - main function

=cut
#***************************************************************************
sub equipment_grab {

  my @equipment_info = @{equipment_scan($argv->{CORE})};

  foreach my $info (@equipment_info) {

    my $nas_list = $Nas->list({
      NAS_IP    => $info->{IP},
      COLS_NAME => 1,
      PAGE_ROWS => 3
    });

    if (!$Nas->{TOTAL}) {
      if ($argv->{DEBUG}) {
        print "Not exists \n";
      }

      if (!$info->{NAS_TYPE}) {
        $info->{NAS_TYPE} = 'other';
      }
      if ($argv->{DEBUG}) {
        _bp('NAS ADD', $info, { TO_CONSOLE => 1 });
      }
      $info->{NAS_MNG_IP_PORT} = $info->{IP}.':::';
      $info->{NAS_MNG_PASSWORD} = $argv->{COMMUNITY} || 'public';
      $Nas->add($info);

      $info->{NAS_ID} = $Nas->{NAS_ID};
    }
    else {
      $info->{NAS_ID} = $nas_list->[0]{nas_id};
    }

  }
  foreach my $info (@equipment_info) {

    my $nas_list = $Nas->list({
      NAS_IP    => $info->{IP},
      COLS_NAME => 1,
      PAGE_ROWS => 3
    });

    if (!$Nas->{TOTAL}) {
      if ($argv->{DEBUG}) {
        say 'NAS not exist';
      }
      next;
    }

    $info->{NAS_ID} = $nas_list->[0]{nas_id};

    $Equipment->_info($info->{NAS_ID});

    if (!$Equipment->{list}) {
      if ($info->{MODEL_ID}) {
        my ($snmp_version) = $argv->{SNMP_VERSION} =~ /(\d)/;
        my %equipment_attr = ('NAS_ID' => $info->{NAS_ID}, COMMENTS => $info->{COMMENTS}, MODEL_ID => $info->{MODEL_ID}, SNMP_VERSION => $snmp_version);
        $Equipment->_add(\%equipment_attr);
        if ($argv->{DEBUG}) {
          _bp('Equipment ADD', \%equipment_attr, { TO_CONSOLE => 1 });
        }
      }
    }
    else {
      if ($argv->{DEBUG}) {
        say "Equipment exist";
      }
    }

    if ($info->{NAS_ID} && defined $info->{PORT} && $info->{UPLINK}) {

      my $uplink = $Nas->list({
        NAS_IP    => $info->{UPLINK},
        COLS_NAME => 1,
      });

      $uplink = $uplink->[0]{id};
      my %port_attr = ('NAS_ID' => $info->{NAS_ID}, 'PORT' => $info->{PORT}, COMMENTS => $info->{COMMENTS}, 'UPLINK' => $uplink);
      $Equipment->port_info({
        NAS_ID => $info->{NAS_ID},
        PORT   => $info->{PORT},
      });
      if (!$Equipment->{TOTAL}) {
        $Equipment->port_add(\%port_attr);
      }
      if ($argv->{DEBUG}) {
        _bp('PORT ADD', \%port_attr, { TO_CONSOLE => 1 });
      }
    }
  }

}

#***************************************************************************
=heade2 equipment_scan() - getting neighbours of $core

  Arguments:
    $core - ip of main switch
    $uplink - parent (optional)
    $port - uplink port(optional)

=cut
#***************************************************************************
sub equipment_scan {
  my $core = shift;
  my $uplink = shift;
  my $port = shift;
  my $oid = "1.0.8802.1.1.2.1.4.2.1.5";
  my $community = $argv->{COMMUNITY} || 'public';

  my $list = $Equipment->model_list({
    MODEL_NAME => '_SHOW',
    COLS_NAME  => 1,
  });

  my $serial = snmp_get({
    SNMP_COMMUNITY => $community.'@'.$core,
    OID            => "1.3.6.1.2.1.47.1.1.1.1.11.1",
    SILENT         => 1,
    TIMEOUT        => 1,
    VERSION        => $argv->{SNMP_VERSION} || 1
  });
  if (in_array($serial, \@serials)) {
    if ($argv->{DEBUG}) {
      say "SERIAL EXIST  " . $core;
    }
    return \@info;
  }

  push @serials, $serial;
  push @ips, $core;

  my %host = ();

  say "CHECKING " . $core;

  $host{IP} = $core;
  $host{PORT} = $port if($port);
  $host{COMMENTS} = snmp_get({
    SNMP_COMMUNITY => $community.'@'.$core,
    OID            => ".1.3.6.1.2.1.1.1.0",
    SILENT         => 1,
    TIMEOUT        => 1,
    VERSION        => $argv->{SNMP_VERSION} || 1
  });

  $host{NAS_NAME} = snmp_get({
    SNMP_COMMUNITY => $community.'@'.$core,
    OID            => ".1.3.6.1.2.1.1.5.0",
    SILENT         => 1,
    TIMEOUT        => 1,
    VERSION        => $argv->{SNMP_VERSION} || 1
  });

  if ($host{COMMENTS}) {
    print "SNMP answer: '$host{COMMENTS}'\n" if ($argv->{DEBUG} || $argv->{INFO_ONLY});
    foreach (@$list) {
      next unless ($_->{model_name});
      if ($argv->{DEBUG}) {
        if ($host{COMMENTS} =~ m/$_->{model_name}/) {
          print "Found matches:\n model_id: '$_->{id}'\n model_name: '$_->{model_name}'\n";

          $host{MODEL_ID} = $_->{id};
        }
      }
    }
  }
  if ($host{COMMENTS}) {

    my ($session, $error) = Net::SNMP->session(
      -hostname  => $core,
      -version   => $argv->{SNMP_VERSION} || 1,
      -community => $community
    );

    if (!$session) {
      print "ERROR: " . $error . "\n";
      return;
    }
    if ($uplink) {
      $host{UPLINK} = $uplink
    }

    my $neighbours = $session->get_table($oid);
    for my $oid_ (keys %{$neighbours}) {
      my $regex = '(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b$)';
      if ($oid_ =~ /$regex/) {
        $oid_ =~ qr/$regex/;
        my $ip = $1;
        my ($port_) = $oid_ =~ /^\d+.\d+.\d+.\d+.\d+.\d+.\d+.\d+.\d+.\d+.\d+.\d+.(\d+)/;
        if (in_array($ip, \@ips)) {
          next;
        }
        equipment_scan($ip, $core, $port_);
      }
    }

    push @info, \%host;
  }
  else {
    say "NO RESPONSE";
  }

  return \@info;
}

1;
