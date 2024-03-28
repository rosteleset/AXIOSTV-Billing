use strict;
use warnings FATAL => 'all';

=head1 NAME

  mikrotik_check_clients - billd plugin

=head2  DESCRIBE

  Checks current online sessions and address_list entries on mikrotik

=head2 ARGUMENTS

  MIKROTIK_DEBUG


=head2 EXAMPLE

  billd mikrotik_check_clients DEBUG=1 NAS_IDS=5

=cut
#**********************************************************

our (
  $Admin,
  $db,
  %conf,
  $debug,
  $argv,
  %LIST_PARAMS,
  $DATE,
  $TIME,
  @MODULES
);

use Internet::Sessions;
use Dv_Sessions;
use Nas;
use AXbills::Nas::Mikrotik;
use AXbills::Base qw(int2ip _bp in_array parse_arguments);

#_bp('', '', { SET_ARGS => { TO_CONSOLE => 1 } });

my Internet::Sessions $Sessions;

if (!$argv->{NAS_IDS}) {
  print "Error: No NAS_IDS given \n";
  exit 2;
}

if ($argv->{USE_DV}) {
  $Sessions = Dv_Sessions->new($db, $Admin, \%conf);
}
else {
  $Sessions = Internet::Sessions->new($db, $Admin, \%conf);
}

mikrotik_check_clients();

#**********************************************************
=head2 mikrotik_check_clients()

=cut
#**********************************************************
sub mikrotik_check_clients {

  if ($argv->{NAS_IDS}) {
    $argv->{NAS_IDS} =~ s/,/;/;
  }
  my @nas_ids = split(',\s', $argv->{NAS_IDS} || '');

  foreach my $nas_id (@nas_ids) {

    print "[ $DATE $TIME ] Checking sessions for NAS $nas_id \n" if ($debug);

    # Open mikrotik connection
    my AXbills::Nas::Mikrotik $Mt = mikrotik_init_and_check_access($nas_id);
    next if (!$Mt);

    # Get entries from address list
    my $address_list_entries = get_address_list_hash($Mt);
    if (!$address_list_entries) {
      next;
    }
    print "There is " . (scalar @{$address_list_entries}) . " address-list entries \n" if ($debug);

    # Get sessions
    my $sorted_by_nas = get_online_list({ NAS_ID => $nas_id });

    if (! $sorted_by_nas->{ $nas_id }) {
      next;
    }

    my $online_for_nas = $sorted_by_nas->{ $nas_id };

    print "There is " . (scalar @{$online_for_nas}) . " online sessions \n" if ($debug);

    # Compare
    my @addresses_to_delete = get_not_in_online_address_list_entries($online_for_nas, $address_list_entries);

    print "Going to delete " . (scalar @addresses_to_delete) . " address_list entries \n" if ($debug);
    # Delete unexistant
    foreach my $entry (@addresses_to_delete) {

      if ($debug >= 4) {
        print " Simulate deleting $entry->{id} $entry->{list} $entry->{address} \n";
        next;
      }

      my $deleted = $Mt->firewall_address_list_del($entry->{id});
      if ($deleted) {
        print " Deleted $entry->{id} $entry->{list} $entry->{address} \n" if ($debug);
      }
      else {
        print " Error deleting $entry->{id} $entry->{list} $entry->{address} \n" if ($debug);
      }
    }
  }
  return 1;
}


# #**********************************************************
# =head2 get_online_list($nas_id)
#
#   Arguments:
#     $nas_id
#
# =cut
# #**********************************************************
# sub get_online_list {
#   my ($nas_id) = @_;
#
#   my $online_list = [];
#
#   if ($argv->{USE_DV}) {
#     $online_list = $Sessions->online({
#       NAS_ID    => $nas_id,
#       LOGIN     => '_SHOW',
#       CID       => '_SHOW',
#       CLIENT_IP => '_SHOW',
#       TP_ID     => '_SHOW',
#       PAGE_ROWS => 100000,
#       COLS_NAME => 1,
#     });
#
#     if ($Sessions->{errno}) {
#       print "  Can't get online sessions : " . ($Sessions->{errstr} || 'Unknown error') . "\n";
#       return 0;
#     }
#     elsif (!$Sessions->{TOTAL} && $debug) {
#       print "  No online sessions for NAS_ID $nas_id \n";
#     }
#   }
#   else {
#     $online_list = $Sessions->online({
#       NAS_ID    => $nas_id,
#       LOGIN     => '_SHOW',
#       CID       => '_SHOW',
#       CLIENT_IP => '_SHOW',
#       TP_ID     => '_SHOW',
#       PAGE_ROWS => 100000,
#       COLS_NAME => 1,
#     });
#
#     if ($Sessions->{errno}) {
#       print "  Can't get online sessions : " . ($Sessions->{errstr} || 'Unknown error') . "\n";
#       return 0;
#     }
#     elsif (!$Sessions->{TOTAL} && $debug) {
#       print "  No online sessions for NAS_ID $nas_id \n";
#     }
#   }
#
#   return $online_list || [];
# }

#**********************************************************
=head2 get_address_list_hash()

=cut
#**********************************************************
sub get_address_list_hash {
  my AXbills::Nas::Mikrotik $mt = shift;

  # Get list
  my $address_list = $mt->firewall_address_list_list({ LIST => '~CLIENTS_' });
  if (my $error = $mt->get_error) {
    print "Error. Can't get Firewall > Address-list : $error \n";
    return 0;
  }

  # Return
  return $address_list;
}

#**********************************************************
=head2 get_not_in_online_address_list_entries($online_list, $address_list_list)

  Argumnets:
    $online_list
    $address_list_list

  Return:
    result

=cut
#**********************************************************
sub get_not_in_online_address_list_entries {
  my ($online_list, $address_list_list) = @_;

  my @result = ();

  # Build hash for address_list
  my %online_lookup = map {$_->{client_ip} => $_} @{$online_list};

  foreach my $address_list_entry (@{$address_list_list}) {
    next if (exists $online_lookup{$address_list_entry->{address}});
    # MAYBE check other params
    push(@result, $address_list_entry);
  }

  return wantarray ? @result : \@result;
}

#**********************************************************
=head2 mikrotik_init_and_check_access($nas_id)

=cut
#**********************************************************
sub mikrotik_init_and_check_access {
  my ($nas_id) = @_;

  my $Nas = Nas->new($db, \%conf, $Admin);

  # Get nas_info from db
  $Nas->info({ NAS_ID => $nas_id });

  # Create mikrotik object
  my $mt = AXbills::Nas::Mikrotik->new($Nas, \%conf, {
    DEBUG => $argv->{MIKROTIK_DEBUG} || 0
  });

  if (!$mt) {
    print "Error. Can't instantiate AXbills::Nas:Mikrotik for $nas_id. Check NAS management params \n";
    return 0;
  }

  # Check access
  if (!$mt->has_access) {
    print "Error. No access to $nas_id ($mt->{backend} ; $mt->{admin}\@$mt->{host} ; port - $mt->{port}) \n";
    return 0;
  }

  return $mt;
}

1;
