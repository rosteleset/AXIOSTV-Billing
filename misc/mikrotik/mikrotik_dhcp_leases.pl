#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

our $libpath;
BEGIN {
  use FindBin '$Bin';
  
  our $Bin;
  use FindBin '$Bin';
  
  $libpath = $Bin . '/../'; #assuming we are in /usr/axbills/libexec/
  if ( $Bin =~ m/\/axbills(\/)/ ) {
    $libpath = substr($Bin, 0, $-[1]);
  }
  
  unshift (@INC, $libpath,
    $libpath . '/AXbills/',
    $libpath . '/AXbills/mysql/',
    $libpath . '/AXbills/Control/',
    $libpath . '/lib/'
  );
}

our (%conf, @MODULES);

do "libexec/config.pl";

use Admins;
use AXbills::SQL;
use AXbills::Base qw(parse_arguments _bp in_array);

use AXbills::Nas::Mikrotik;
use Nas;

#use Dhcphosts;
#use Internet::DhcphostsAdapter;

# System initialization
my $db = AXbills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/}, \%conf);
my $admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : $conf{SYSTEM_ADMIN_ID},
  { IP => '127.0.0.1', SHORT => 1 });

# Modules initialisation
my $Nas = Nas->new($db, \%conf);

my $Dhcphosts;
if ( in_array('Internet', \@MODULES) ) {
  $Dhcphosts = Internet::DhcphostsAdapter->new($db, $admin, \%conf);
}
else {
  $Dhcphosts = Dhcphosts->new($db, $admin, \%conf);
}

# Local globals
my %ARGS = ();
my $debug = 0;

my $networks_list = [];
my @all_networks_list = ();

exit main() ? 0 : 1;

#**********************************************************
=head2 main() - Parse arguments, check parameters, etc

=cut
#**********************************************************
sub main {
  %ARGS = %{ parse_arguments(\@ARGV) };
  die ("Need NAS_IDS") unless ( $ARGS{NAS_IDS} );
  
  $debug = $ARGS{DEBUG} if ( defined $ARGS{DEBUG} );
  $ARGS{VERBOSE} = $ARGS{VERBOSE} || 0;
  
  if ( $ARGS{NAS_IDS} =~ /-/ ) {
    die("Setting NAS_ID via range is not implemented");
  }
  
  #  $Nas->{debug} = 1;
  my $nas_list = $Nas->list({ NAS_ID => $ARGS{NAS_IDS}, DISABLED => '0', COLS_NAME => 1 });
  
  unless ( defined $nas_list && scalar(@{$nas_list}) > 0 ) {
    die (" !!! NAS not found");
  }
  
  prepare($ARGS{NAS_IDS});
  
  my $result = 0;
  foreach my $nas ( @{$nas_list} ) {
    # Skip non-mikrotik NASes
    next unless ( $nas->{nas_type} =~ 'mikrotik' );
    
    my AXbills::Nas::Mikrotik $mikrotik = AXbills::Nas::Mikrotik->new($nas, \%conf, { DEBUG => $debug });
    unless ( $mikrotik->has_access() ) {
      print ("!!! $nas->{nas_name} (ID: $nas->{nas_id}) is not accessible\n");
      return 0;
    };
    
    my $operation_type = 'Syncing';
    if ( $ARGS{CLEAN} ) {
      $operation_type = "Removing all generated";
      $result = ($mikrotik->leases_remove_all_generated());
    }
    elsif ( $ARGS{RECONFIGURE} ) {
      $operation_type = "Reconfiguring all generated";
      $result = ($mikrotik->leases_remove_all_generated() && sync_leases($mikrotik, $nas));
    }
    else {
      $result = sync_leases($mikrotik, $nas, \%ARGS);
    }
    
    my $res = "$operation_type leases for NAS $nas->{nas_id} fininished ";
    $res .= (($result) ? "successfully" : "with errors !!! ");
    
    print " $res \n\n" if ($ARGS{VERBOSE});
  }
  
  return $result;
}

#**********************************************************
=head2 prepare($nas_id) - get all shared params

  Arguments:
    $nas_id - hash_ref

  Returns:
    1;
    
=cut
#**********************************************************
sub prepare {
  my ($nas_id) = @_;

  $networks_list = $Dhcphosts->networks_list({
    DISABLE          => 0,
    NAS_ID           => $nas_id,
    NAME             => '_SHOW',
    PAGE_ROWS        => 10000,
    SORT             => 2,
    SHOW_ALL_COLUMNS => 1,
    COLS_NAME        => 1
  });
  
  if ( !$networks_list || scalar @{$networks_list} < 1 ) {
    die "No dhcphosts networks configured \n";
  };

  @all_networks_list = @{$networks_list};
  
  return 1;
}

#**********************************************************
=head2 sync_leases($attr)

  Arguments:
  $nas - hash_ref (line from DB list)
  $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub sync_leases {
  my AXbills::Nas::Mikrotik $mikrotik = shift;
  my ($nas, $attr) = @_;
  
  my $nas_id = $nas->{nas_id};
  @{$networks_list} = @all_networks_list;
  $networks_list = $mikrotik->dhcp_servers_check($networks_list, $attr);
  
  my $db_leases = db_leases_list($nas_id);
  return 0 if ( scalar @{$db_leases} <= 0 );
  
  my $mikrotik_leases = $mikrotik->leases_list($attr);
  
  # Sort mikrotik leases by MAC
  my %mikrotik_leases_by_mac = ();
  foreach my $line ( @{$mikrotik_leases} ) {
    $mikrotik_leases_by_mac{lc $line->{"mac-address"}} = $line;
  }
  
  my %db_leases_by_mac = ();
  foreach my $line ( @{$db_leases} ) {
    $db_leases_by_mac{lc $line->{mac}} = $line;
  }

  # Compare leases from mikrotik and DB
  my @mikrotik_to_add_leases = ();
  foreach my $host_mac ( keys (%db_leases_by_mac) ) {
    print "$host_mac - ipn_activated $db_leases_by_mac{$host_mac}->{ipn_activate} \n" if ( $ARGS{VERBOSE} > 1 );
    if ( !defined $mikrotik_leases_by_mac{$host_mac} ) {
      print "Mikrotik don't have lease $host_mac\n" if ( $ARGS{VERBOSE} );
      push (@mikrotik_to_add_leases, $db_leases_by_mac{$host_mac});
    }
    else {
      my (undef, $mikrotik_tp_id) = split('_', $mikrotik_leases_by_mac{$host_mac}{'address-lists'});
      if ($mikrotik_tp_id && $mikrotik_tp_id != $db_leases_by_mac{$host_mac}{tp_id}) {
        print "Address-list was changed: $host_mac\n" if ( $ARGS{VERBOSE} );
        push (@mikrotik_to_add_leases, $db_leases_by_mac{$host_mac});
      }
      else {
        delete $mikrotik_leases_by_mac{$host_mac};
      }
    }
  }
  
  # Delete all other leases
  my @mikrotik_to_remove_leases = values %mikrotik_leases_by_mac;

  _bp("Leases to delete", \@mikrotik_to_remove_leases, { TO_CONSOLE => 1, EXIT => 0 }) if ( $debug );
  _bp("Leases to add", \@mikrotik_to_add_leases, { TO_CONSOLE => 1, EXIT => 0 }) if ( $debug );
  
  return 1 if ( $debug > 6 );
  
  my $number_to_remove = scalar @mikrotik_to_remove_leases;
  my $number_to_add = scalar @mikrotik_to_add_leases;

  print "Removing $number_to_remove leases \n" if ( $ARGS{VERBOSE} );

  if ($ARGS{BEFORE_REMOVE}) {
    if (!(-f $ARGS{BEFORE_REMOVE})) {
      print "BEFORE_REMOVE doesnt  exists\n";
      exit 1;
    }

    require AXbills::Templates;
    my $tpl_contenet = tpl_content($ARGS{BEFORE_REMOVE});

    foreach my $lease(@mikrotik_to_remove_leases) {
      my $mac = $lease->{"mac-address"};
      my $hosts = $Dhcphosts->hosts_list({ CID => $mac });

      if ($hosts && ref $hosts eq 'ARRAY') {
        my $user   = $hosts->[0];
        my $vlan   = $user->{vlan};
        my $cmd    = _tpl_show($tpl_contenet, { VLAN_ID => $vlan, });
        my @commands_before_remove = split(/\n/, $cmd);
        foreach my $command (@commands_before_remove){
          my $before_remove_result = $mikrotik->execute($command);
          _bp("Before remove result", $before_remove_result, { TO_CONSOLE => 1, EXIT => 0 }) if ($debug);
        }
      }
    }
  }

  my $remove_result = $mikrotik->leases_remove([ map { $_->{id} } @mikrotik_to_remove_leases], \%ARGS);
  
  print "Adding $number_to_add new leases \n" if ( $ARGS{VERBOSE} );

  if ($ARGS{BEFORE_ADD}) {
    if (!(-f $ARGS{BEFORE_ADD})) {
      print "BEFORE_ADD doesnt  exists\n";
      exit 1;
    }

    require AXbills::Templates;
    my $tpl_contenet = tpl_content($ARGS{BEFORE_ADD});

    foreach my $lease (@mikrotik_to_add_leases) {
      my $cmd = _tpl_show($tpl_contenet, {
          VLAN_ID    => $lease->{vlan},
          LOGIN      => $lease->{login},
          GATEWAY_IP => $lease->{gateway_ip},
          CLIENT_IP  => $lease->{ip},
        });
      print "CMD - $cmd\n" if ( $debug );
      my @commands_before_add = split(/\n/, $cmd);
      foreach my $command (@commands_before_add){
        my $before_add_result = $mikrotik->execute($command);
        _bp("Before add result", $before_add_result, { TO_CONSOLE => 1, EXIT => 0 }) if ($debug);
      }
    }

  }

  my $add_result = $mikrotik->leases_add(\@mikrotik_to_add_leases, \%ARGS);
  
  return ($remove_result && $add_result);
}

#**********************************************************
=head2 current_leases_list($nas_id) - Get leases from Dhcphosts for given NAS

  Arguments:
    $nas_id - NAS_ID
    $attr

  Returns:
    list

=cut
#**********************************************************
sub db_leases_list {
  my ($nas_id) = @_;
  
  # Get leases from DB
  my @db_leases = ();
  foreach ( @{$networks_list} ) {
    my $network_hosts_list = $Dhcphosts->hosts_list({
      NETWORK      => '_SHOW',
      NETWORK_NAME => '_SHOW',
      STATUS       => '_SHOW',
      USER_DISABLE => 0,
      LOGIN        => '_SHOW',
      TP_TP_ID     => '_SHOW',
      TP_NAME      => '_SHOW',
      IPN_ACTIVATE => 1,
      MAC          => '_SHOW',
      IP           => '_SHOW',
      NAS_ID       => $nas_id,
      NAS_NAME     => '_SHOW',
      OPTION_82    => '_SHOW',
      DELETED      => 0,
      COLS_NAME    => 1,
      PAGE_ROWS    => 100000,
    });
    
    unless ( defined $network_hosts_list ) {
      print " !!! No hosts configured for NAS_ID: $nas_id \n";
      return [];
    }
    
    push @db_leases, @{$network_hosts_list};
  };
  
  _bp("Network leases", \@db_leases, { TO_CONSOLE => 1 }) if ( $debug );
  
  return \@db_leases;
}

#**********************************************************
=head2 tpl_show($tpl, $variables_ref, $attr) - Show templates

  Arguments:

    $tpl             - Template text
    $variables_ref   - Variables hash_ref
    $attr            - Extra atributes
      EXPORT_CONTENT
      SKIP_DEBUG_MARKERS - do not show "<!-- START: >" markers
      OUTPUT2RETURN
      SKIP_VARS
      SKIP_QUOTE
      TPL         - Template Name after defined variable $tpl ignored
      MODULE      - Module
      ID

  Examples:

    print $html->tpl_show(templates('form_user'), { LOGIN => 'Pupkin' });

=cut
#**********************************************************
sub _tpl_show {
  my ($tpl, $variables_ref, $attr) = @_;

  while ($tpl =~ /\%(\w{1,60})(\=?)([A-Za-z0-9\_\.\/\\\]\[:\-]{0,50})\%/g) {
    my $var = $1;
    my $delimiter = $2;
    my $default = $3;

    #    if ($var =~ /$\{exec:.+\}$/) {
    #      my $exec = $1;
    #      if ($exec !~ /$\/usr/axbills\/\misc\/ /);
    #      my $exec_content = system("$1");
    #      $tpl =~ s/\%$var\%/$exec_content/g;
    #     }
    #    els

    if (defined($variables_ref->{$var})) {
      $variables_ref->{$var} =~ s/\%$var\%//g;
    }
    else {
      $variables_ref->{$var} = q{};
    }

    if (defined($variables_ref->{$var})) {
      if ($variables_ref->{$var} !~ /\=\'|\' | \'/ && !$attr->{SKIP_QUOTE}) {
        $variables_ref->{$var} =~ s/\'/&rsquo;/g;
      }
      $tpl =~ s/\%$var$delimiter$default%/$variables_ref->{$var}/g;
    }
    else {
      $tpl =~ s/\%$var$delimiter$default\%/$default/g;
    }
  }

  return $tpl;
}

##**********************************************************
#=head2 add_single_lease($ip, $mac)
#
#  Arguments:
#    $ip, $mac -
#
#  Returns:
#
#=cut
##**********************************************************
#sub add_single_lease{
#  my ($ip, $mac) = @_;
#
#}
#
##**********************************************************
#=head2 disable_single_lease($mac)
#
#  Arguments:
#    $mac -
#
#  Returns:
#
#=cut
##**********************************************************
#sub disable_single_lease{
#  my ($mac) = @_;
#
#}

package Internet::DhcphostsAdapter;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Internet::DhcphostsAdapter

=head2 SYNOPSIS

  This package implements Dhcphosts interface for Internet module

=cut

use Internet;
use Internet::Sessions;
use Nas;
use AXbills::Base qw/int2ip/;

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
  };
  
  bless($self, $class);
  
  $self->{Internet} //= Internet->new($db, $admin, $CONF);
  $self->{Sessions} //= Internet::Sessions->new($db, $admin, $CONF);
  $self->{Nas} //= Nas->new($db, $CONF, $admin);
  
  return $self;
}


#**********************************************************
=head2 hosts_list($attr) -

  Arguments:
    $attr -
    
  Returns:
  
  
=cut
#**********************************************************
sub hosts_list {
  my ($self, $attr) = @_;
  
  #  NETWORK      => '_SHOW',
  #    NETWORK_NAME => '_SHOW',
  #    STATUS       => '_SHOW',
  #    USER_DISABLE => 0,
  #    LOGIN        => '_SHOW',
  #    TP_TP_ID     => '_SHOW',
  #    TP_NAME      => '_SHOW',
  #    IPN_ACTIVATE => 1,
  #    MAC          => '_SHOW',
  #    IP           => '_SHOW',
  #    NAS_ID       => $nas_id,
  #    NAS_NAME     => '_SHOW',
  #    OPTION_82    => '_SHOW',
  #    DELETED      => 0,
  #    COLS_NAME    => 1,
  #    PAGE_ROWS    => 100000,
  
  my Internet $Internet = $self->{Internet};
  
  #  $Internet->{debug} =1;
  my $users_with_mac_on_nas = $Internet->user_list({
    
    USER_DISABLE => 0,
    LOGIN        => '_SHOW',
    TP_ID        => '_SHOW',
    TP_NAME      => '_SHOW',
    VLAN         => '_SHOW',
    IPN_ACTIVATE => 1,
    CID          => $attr->{CID} || '!',
    IP           => '_SHOW',
    NAS_ID       => $attr->{NAS_ID},
    NAS_NAME     => '_SHOW',
    
    DELETED      => 0,
    COLS_NAME    => 1,
    PAGE_ROWS    => 100000,
  });
  
  my $find_pool_for_ip = sub {
    my $ip_num = shift;
    $self->{Internet}->query("SELECT
        p.id, p.name, INET_NTOA(p.gateway) as gateway
      FROM ippools p
      LEFT JOIN nas_ippools np ON (np.pool_id = p.id AND np.nas_id=?)
      WHERE ip<=? AND ?<=ip+counts
      ORDER BY netmask
      LIMIT 1", undef, {COLS_NAME => 1, Bind => [ $attr->{NAS_ID}, $ip_num, $ip_num ]});
    
    $self->{Internet}{errno} ? $self->{Internet}{errno} : $self->{Internet}{list}[0];
  };
  
  use AXbills::Base qw/_bp/;
  my @normalized = map {
    
    my $pool_params = $find_pool_for_ip->($_->{ip_num});
    
    {
      mac          => $_->{cid},
      ipn_activate => 1,
      ip           => int2ip($_->{ip_num}),
      tp_tp_id     => $_->{tp_id},
      gateway_ip   => $pool_params->{gateway},
      network      => $pool_params->{id},
      network_name => $pool_params->{name},
      
      %{$_}
    }
    
  } grep {$_->{ip_num} && $_->{ip_num} ne '0.0.0.0'}  @{$users_with_mac_on_nas};
  
  return \@normalized;
}

#**********************************************************
=head2 networks_list($attr) - returns ip pools as networks list

  Arguments:
    $attr -
      NAS_ID filter
    
  Returns:
  
  
=cut
#**********************************************************
sub networks_list {
  my ($self, $attr) = @_;
  
  # Should return ip_pools
  my $ip_pools_list = $self->{Nas}->nas_ip_pools_list({
    SHOW_ALL_COLUMNS => 1,
    COLS_NAME        => 1,
    %{ $attr // {} }
  });
  
  my @normalized = map {
    {
      id      => $_->{id},
      name    => $_->{pool_name},
      network_name    => $_->{pool_name},
      disable => '0'
    }
  } # When pool is not linked to NAS, $_->{nas_id} will be undef
    grep { $_->{nas_id} || $_->{static} }  @{$ip_pools_list};
  
  return \@normalized;
}


1;