=head1 NAME

  billd plugin

=head2  DESCRIBE

  Auth Export

=head2 EXAMPLE

  billd auth_export DEBUG=1 NAS_IDS=5

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use Nas;
use AXbills::Base qw(int2ip _bp in_array);

our (
  $debug,
  %conf,
  $admin,
  $db,
  $OS,
  $argv,
  %LIST_PARAMS,
  $Internet,
  $Nas
);

_bp('', '', { SET_ARGS => { TO_CONSOLE => 1 } });

if ($argv->{NAS_IDS}) {

  my @nas_ids = split(',\s?', $argv->{NAS_IDS});

  foreach my $nas_id (@nas_ids) {
    $Nas->info({ NAS_ID => $nas_id });

    $Nas->{NAS_TYPE} //= '';

    if ($Nas->{NAS_TYPE} =~ 'mikrotik') {
      $LIST_PARAMS{NAS_ID} = $nas_id;
      mikrotik_user_sync($Nas, get_user_accounts());
    }
    else {
      print "NAS_TYPE $Nas->{NAS_TYPE} ID : $nas_id This type is not supported";
      next;
    }
  }

}
else {
  print "Usage: ./billd auth_export NAS_IDS=<NAS_ID>";
  exit;
}


#**********************************************************
=head2 mikrotik_user_sync($Nas, $user_accounts) - Mikrotik

=cut
#**********************************************************
sub mikrotik_user_sync {
  my ($Nas_, $user_accounts) = @_;

  require AXbills::Nas::Mikrotik;
  AXbills::Nas::Mikrotik->import();

  my $mikrotik = AXbills::Nas::Mikrotik->new($Nas_, \%conf, {
    DEBUG => $argv->{MIKROTIK_DEBUG} || 0
  });

  if (!$mikrotik || !$mikrotik->has_access()) {
    print "No access to $Nas_->{NAS_NAME} ($Nas_->{NAS_IP}) \n";
    return 0;
  }

  # Compare remote and local users to prevent deletening/adding correct rows
  my $current_accounts_list = $mikrotik->ppp_accounts_list();

  # Transform to array of refs with same keys as user_accounts
  my @filtered_current_accounts_list = map {
    {
      LOGIN    => $_->{name},
      PASSWORD => $_->{password},
#      IP       => $_->{'remote-address'},
      CID      => $_->{'caller-id'},
      ID       => $_->{id}
    }
  } @$current_accounts_list;

  my $get_different_rows_from_two_lists = sub {
    my ($fresh, $checked, $compare_keys) = @_;

    # Build hash for both lists to find nonexisting rows
    my $unique_key = $compare_keys->[0];

    my %fresh_list_by_key = map {$_->{$unique_key} => $_} @{$fresh};
    my %checked_list_by_key = map {$_->{$unique_key} => $_} @{$checked};

    # Check for existance of entries in both lists
    my @removed_keys = grep {!exists $fresh_list_by_key{$_}} keys %checked_list_by_key;
    my @removed = map {$checked_list_by_key{$_}} @removed_keys;

    my @created_keys = grep {!exists $checked_list_by_key{$_}} keys %fresh_list_by_key;
    my @created = map {$fresh_list_by_key{$_}} @created_keys;

    # No necessary to compare what is new or will be removed
    my @do_not_compare = (@removed, @created);
    my @should_be_checked = grep {!in_array($_, \@do_not_compare)} @{$checked};

    my %entries_to_compare = map {$_->{$unique_key} => 1} @should_be_checked;
    my @changed = ();
    foreach my $entry_key (keys %entries_to_compare) {
      my $checked_entry = $checked_list_by_key{$entry_key};
      my $fresh_entry = $fresh_list_by_key{$entry_key};

      foreach my $key (@{$compare_keys}) {
        if ($key && $checked_entry->{$key} && $fresh_entry->{$key} && $checked_entry->{$key} ne $fresh_entry->{$key}) {
          $fresh_entry->{ID} = $checked_entry->{ID} if (defined $checked_entry->{ID});

          push(@changed, $fresh_entry);
          last;
        }
      }
    }

    (\@removed, \@created, \@changed);
  };

  my ($to_remove, $to_create, $to_change) = $get_different_rows_from_two_lists->(
    $user_accounts,
    \@filtered_current_accounts_list,
    [ 'LOGIN', 'PASSWORD', 'IP', 'CID' ]
  );

  for my $array_in_debug ( $to_create, $to_change ){
    for my $entry (@$array_in_debug){
      $entry->{$_} ||= '' for ('LOGIN', 'PASSWORD', 'IP', 'CID');
    }
  }

  foreach my $user_account (@{$to_remove}) {
    if (!$argv->{NO_DELETE}) {
      if ($debug) {
        print "Removing: $user_account->{LOGIN} \n";
      }

      $mikrotik->ppp_accounts_remove({
        numbers => $user_account->{LOGIN}
      });
    }
    else {
      $mikrotik->execute('/ppp secret remove [/ppp secret find  comment="KA3HA-39 Emergence" &&  name="'.$user_account->{LOGIN}.'"]');
    }
  }

  foreach (@{$to_create}){
    print "Adding: $_->{LOGIN} PASSWORD: $_->{PASSWORD} IP: $_->{IP} CID: $_->{CID}\n" if ($debug);

    $mikrotik->ppp_accounts_add([
      {
        'name'           => $_->{LOGIN},
        'password'       => $_->{PASSWORD},
        #'remote-address' => $_->{IP},
        'caller-id'      => $_->{CID},
        'profile'        => $argv->{PROFILE} || 'default',
        'disabled'       => 'yes',
        'comment'        => 'KA3HA-39 Emergence'
      }
    ]);
  }

  foreach my $user_account (@{$to_change}) {
    print "Changed: $user_account->{LOGIN} PASSWORD: $user_account->{PASSWORD} IP: $user_account->{IP} CID: $user_account->{CID}\n" if ($debug);
    $mikrotik->debug(3);
    $mikrotik->ppp_accounts_change($user_account->{ID}, {
      name             => $user_account->{LOGIN},
      password         => $user_account->{PASSWORD},
      #'remote-address' => $user_account->{IP},
      'caller-id'      => $user_account->{CID}
    });
  }

  return 1;
}


#**********************************************************
=head2 get_user_accounts() - Mikrotik

=cut
#**********************************************************
sub get_user_accounts {

  my @accounts = ();

  if ($debug > 6) {
    $Nas->{debug} = 1;
    $Internet->{debug} = 1;
  }

  my %nas_pool_ips = ();
  my %pool_used = ();

  if ($LIST_PARAMS{NAS_ID}) {
    my $pool_list = $Nas->ip_pools_list({
      COLS_NAME => 1,
      NAS_ID    => $LIST_PARAMS{NAS_ID}
    });

    foreach my $line (@{$pool_list}) {
      push @{$nas_pool_ips{$LIST_PARAMS{NAS_ID} }}, {
        ID    => $line->{id},
        FIRST => $line->{ip},
        COUNT => $line->{counts}
      }
    }
  }

  my $internet_list = $Internet->user_list({
    LOGIN     => '_SHOW',
    PASSWORD  => '_SHOW',
    CID       => '_SHOW',
    TP_ID     => '_SHOW',
    IP        => '_SHOW',
    PAGE_ROWS => 1000000,
    COLS_NAME => 1
  });

  foreach my $user_info (@{$internet_list}) {
    my $ip = $user_info->{ip} || '0.0.0.0';
    if ($LIST_PARAMS{NAS_ID} && $nas_pool_ips{ $LIST_PARAMS{NAS_ID} }) {
      foreach my $pool_info (@{$nas_pool_ips{ $LIST_PARAMS{NAS_ID} }}) {
        print "$pool_info->{ID} $pool_info->{FIRST} $pool_info->{COUNT}\n" if ($debug > 1);

        if (!$pool_used{$pool_info->{ID}}) {
          $pool_used{$pool_info->{ID}} = $pool_info->{FIRST};
        }
        elsif ($pool_used{$pool_info->{ID}} < $pool_info->{FIRST} + $pool_info->{COUNT}) {
          $pool_used{$pool_info->{ID}}++;
        }
        else {
          next;
        }

        print "Pool ip: $pool_used{$pool_info->{ID}}\n" if ($debug > 1);
        $ip = int2ip($pool_used{$pool_info->{ID}});
        last;
      }
    }

    push @accounts, {
      LOGIN    => $user_info->{login} || q{},
      PASSWORD => $user_info->{password} || q{},
      IP       => $ip,
      CID      => $user_info->{CID} || q{},
      TP_ID    => $user_info->{TP_ID} || 0,
    };
  }

  return \@accounts;
}


1;
