=head1 NAME

  billd plugin equipment_onu_disabled_status

  DESCRIPTION: Disables or enables ONUs according to attached users statuses

  If (payment type is "Prepaid" and (user.deposit + user.credit + tarif_plan.credit <= 0)) or Internet status is not "Active", then ONU will be disabled, else it will be enabled

  Supported OLTs: ZTE (GPON)

  You may want to run this as INTERNET_EXTERNAL_CMD, so ONU will be enabled right after user's status changes.
  conf example:
  $conf{INTERNET_EXTERNAL_CMD} = "$lib_path/billd equipment_onu_disabled_status SKIPPID=1 RUN_AS_EXTERNAL=1 UIDS=%UID%";

  Arguments:
    UIDS            - UIDs, separated by ';'. if set, NAS_IDS is ignored
    NAS_IDS         - NAS IDs, separated by ';'
    DRY_RUN         - Only print what ONUs it's going to enable/disable, will not do any changes on OLT
    RUN_AS_EXTERNAL - Will output in format required by sub _external (*_EXTERNAL_CMD): exit status, colon (':'), actual output
                      Also will set DEBUG to 1 if it is not set
    TIMEOUT         - SNMP timeout, in seconds
    DEBUG           - Debug level

=cut

use strict;
use warnings;

use Equipment;
use Internet;
use Events;
use Events::API;
use AXbills::Base qw(in_array);

our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
);

my $comments = '';
our $Equipment = Equipment->new($db, $Admin, \%conf);
my $Internet = Internet->new($db, $Admin, \%conf);
my $Events = Events::API->new($db, $Admin, \%conf);

require Equipment::Pon_mng;

my $run_as_external_output;
if ($argv->{RUN_AS_EXTERNAL}) {
  open(my $fh, '>', \$run_as_external_output);
  select($fh);

  $argv->{DEBUG} //= 1;
}

my $exit_status = update_onus_disabled_statuses({%$argv, DEBUG => $argv->{DEBUG} // $debug});

if ($argv->{RUN_AS_EXTERNAL}) {
  select(STDOUT);
  print "$exit_status:$run_as_external_output";
}

#********************************************************
=head2 update_onus_disabled_statuses($attr) - Checks and changes ONUs disabled statuses according to attached users statuses

  Arguments:
    $attr
      UIDS    - UIDs, separated by ';'. if set, NAS_IDS is ignored
      NAS_IDS - NAS IDs, separated by ';'
      DRY_RUN - only print what ONUs it's going to enable/disable, will not do any changes on OLT
      DEBUG   - debug level

  Returns:
    true or false

=cut
#********************************************************
sub update_onus_disabled_statuses {
  my ($attr) = @_;

  my $return_value = 1;

  my $nas_ids_for_uids;
  if ($attr->{UIDS}) {
    my $users = $Internet->user_list({
      UID             => $attr->{UIDS},
      NAS_ID          => '_SHOW',
      GROUP_BY        => 'internet.id',
      PAGE_ROWS       => 10000000,
      COLS_NAME       => 1
    });

    if (!$users) {
      $comments = "Can't find any users with given UIDS\n";
      print $comments;
      _generate_new_event("Can't find any users", $comments);

      return 0;
    }

    my %nas_ids = map { $_->{nas_id} => 1 } @$users;

    $nas_ids_for_uids = join ';', keys %nas_ids;
  }

  my $Equipment_list = $Equipment->_list({
    NAS_ID           => $nas_ids_for_uids || $attr->{NAS_IDS} || '_SHOW',
    NAS_NAME         => '_SHOW',
    MODEL_NAME       => '_SHOW',
    STATUS           => '0',
    NAS_IP           => '_SHOW',
    NAS_MNG_HOST_PORT=> '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    SNMP_VERSION     => '_SHOW',
    TYPE_NAME        => '4',
    PAGE_ROWS        => 10000000,
    COLS_NAME        => 1,
  });

  if (!@$Equipment_list) {
    print "Can't find any PON equipment\n";
    return 0;
  }

  foreach my $equipment (@$Equipment_list) {
    my %disabled_statuses;

    my $users = $Internet->user_list({
      UID             => $attr->{UIDS} || '_SHOW',
      NAS_ID          => $equipment->{nas_id},
      PORT            => '_SHOW',
      LOGIN           => '_SHOW',
      DEPOSIT         => '_SHOW',
      CREDIT          => '_SHOW',
      TP_CREDIT       => '_SHOW',
      PAYMENT_TYPE    => '_SHOW',
      INTERNET_STATUS => '_SHOW',
      GROUP_BY        => 'internet.id',
      PAGE_ROWS       => 10000000,
      COLS_NAME       => 1
    });

    next if (!$users);

    if ($attr->{UIDS}) {
      my $port_ids = join(';', map { $_->{port} } @$users);
      $users = $Internet->user_list({ #if there are multiple users on single ONU, we need to know statuses of all users
        UID             => '_SHOW',
        NAS_ID          => $equipment->{nas_id},
        PORT            => $port_ids,
        LOGIN           => '_SHOW',
        DEPOSIT         => '_SHOW',
        CREDIT          => '_SHOW',
        TP_CREDIT       => '_SHOW',
        PAYMENT_TYPE    => '_SHOW',
        INTERNET_STATUS => '_SHOW',
        GROUP_BY        => 'internet.id',
        PAGE_ROWS       => 10000000,
        COLS_NAME       => 1
      });
    }

    my %users_by_dhcp_port;
    foreach my $user (@$users) {
      push @{$users_by_dhcp_port{$user->{port}}}, $user;
      if (($user->{deposit} + $user->{credit} + ($user->{tp_credit} || 0) <= 0) && defined $user->{payment_type} && $user->{payment_type} == 0 # 0 - prepaid
          || $user->{internet_status} > 0) { # 0 - active
        if (!$disabled_statuses{$user->{port}}->{USER}) { #if there are multiple users on single ONU, we will leave it enabled even if all but one users are disabled
          $disabled_statuses{$user->{port}}->{USER} = 'disabled';
        }
      }
      else {
        $disabled_statuses{$user->{port}}->{USER} = 'enabled';
      }
    }

    my $supported_vendors = ['ZTE'];
    if (!in_array($equipment->{vendor_name}, $supported_vendors)) {
      print "OLT $equipment->{nas_id}, $equipment->{nas_name}: $equipment->{vendor_name} is currently not supported\n" if ($attr->{DEBUG});
      next;
    }

    my $onu_list = $Equipment->onu_list({
      NAS_ID        => $equipment->{nas_id},
      DELETED       => 0,
      BRANCH        => '_SHOW',
      ONU_ID        => '_SHOW',
      SNMP_ID       => '_SHOW',
      ONU_SNMP_ID   => '_SHOW',
      ONU_DHCP_PORT => '_SHOW',
      PON_TYPE      => '_SHOW',
      COLS_NAME     => 1,
    });

    next if (!@$onu_list);

    my %onu_by_dhcp_port;
    my %pon_types;
    foreach my $onu (@$onu_list) {
      $onu_by_dhcp_port{$onu->{onu_dhcp_port}} = $onu;
      $pon_types{$onu->{pon_type}} = 1;
    }

    my $nas_type = equipment_pon_init({VENDOR_NAME => $equipment->{vendor_name}});

    if (!$nas_type) {
      next;
    }

    my $snmp = &{\&{$nas_type}}({MODEL => $equipment->{model_name}});

    my $SNMP_COMMUNITY = ($equipment->{nas_mng_password} || '')
      . '@'
      . ($equipment->{nas_mng_ip_port} || $equipment->{nas_ip} || '');

    foreach my $pon_type (sort keys %pon_types) {
      my $oid = $snmp->{$pon_type}->{disable_onu_manage};
      if (!$oid) {
        print "OLT $equipment->{nas_id}, $equipment->{nas_name}: " . uc($pon_type) . " on $equipment->{vendor_name} is currently not supported\n" if ($attr->{DEBUG});
        next;
      }

      if ($attr->{UIDS}) {
        my @users_oids;
        my @users_dhcp_ports;
        foreach my $dhcp_port (sort keys %users_by_dhcp_port) {
          my $onu = $onu_by_dhcp_port{$dhcp_port};
          if ($onu && $onu->{pon_type} eq $pon_type) {
            push @users_oids, "$oid->{OIDS}.$onu->{onu_snmp_id}";
            push @users_dhcp_ports, $dhcp_port;
          }
        }

        my $snmp_disable_statuses = snmp_get({
          OID            => \@users_oids,
          SNMP_COMMUNITY => $SNMP_COMMUNITY,
          VERSION        => $equipment->{snmp_version},
          TIMEOUT        => $argv->{TIMEOUT},
          DEBUG          => $attr->{DEBUG}
        });

        if (!$snmp_disable_statuses || !@$snmp_disable_statuses || $#$snmp_disable_statuses ne $#users_oids) {
          $comments = "OLT $equipment->{nas_id}, $equipment->{nas_name}: " . uc($pon_type) . ": failed to get current statuses of ONUs\n";
          print $comments;
          _generate_new_event("Failed to get current statuses of ONUs", $comments);

          $return_value = 0;
          next;
        }

        for (my $i = 0; $i <= $#$snmp_disable_statuses; $i++) {
          if (defined $snmp_disable_statuses->[$i]) {
            $disabled_statuses{$users_dhcp_ports[$i]}->{OLT} = $snmp_disable_statuses->[$i] == $oid->{ENABLE_VALUE} ? 'enabled' : 'disabled';
          }
          else {
            my $onu = $onu_by_dhcp_port{$users_dhcp_ports[$i]};
            my @users = @{$users_by_dhcp_port{$users_dhcp_ports[$i]}};
            my $users_string = ((scalar @users > 1) ? 'users' : 'user') . ' ' . join(', ', map { $_->{login} } @users);
            $comments = "OLT $equipment->{nas_id}, $equipment->{nas_name}: " . uc($pon_type) . ": failed to get current status of ONU $onu->{branch}:$onu->{onu_id} ($users_string)\n";
            print $comments;
            _generate_new_event('Failed to get current statuses of ONUs', $comments);

            $return_value = 0;
          }
        }
      }
      else {
        my $snmp_disable_statuses = snmp_get({
          OID            => $oid->{OIDS},
          SNMP_COMMUNITY => $SNMP_COMMUNITY,
          VERSION        => $equipment->{snmp_version},
          WALK           => 1,
          TIMEOUT        => $argv->{TIMEOUT},
          DEBUG          => $attr->{DEBUG}
        });

        if (!$snmp_disable_statuses || !@$snmp_disable_statuses || !defined $snmp_disable_statuses->[0]) {
          $comments = "OLT $equipment->{nas_id}, $equipment->{nas_name}: " . uc($pon_type) . ": failed to get current statuses of ONUs\n";
          print $comments;
          _generate_new_event('Failed to get current statuses of ONUs', $comments);

          $return_value = 0;
          next;
        }

        my %disable_status_on_olt_by_snmp_id = map { split(/:/, $_, 2) } @$snmp_disable_statuses;

        foreach my $onu (@$onu_list) {
          if (defined $disable_status_on_olt_by_snmp_id{$onu->{onu_snmp_id}}) {
            $disabled_statuses{$onu->{onu_dhcp_port}}->{OLT} = $disable_status_on_olt_by_snmp_id{$onu->{onu_snmp_id}} == $oid->{ENABLE_VALUE} ? 'enabled' : 'disabled';
          }
        }
      }
    }

    foreach my $dhcp_port (sort keys %disabled_statuses) {
      if ($disabled_statuses{$dhcp_port}->{OLT} &&
          $disabled_statuses{$dhcp_port}->{USER} &&
          $disabled_statuses{$dhcp_port}->{OLT} ne $disabled_statuses{$dhcp_port}->{USER}) {
        my $onu = $onu_by_dhcp_port{$dhcp_port};
        my @users = @{$users_by_dhcp_port{$dhcp_port}};
        my $users_string = ((scalar @users > 1) ? 'users' : 'user') . ' ' . join(', ', map { $_->{login} } @users);

        my $oid = $snmp->{$onu->{pon_type}}->{disable_onu_manage};
        next if (!$oid);

        if ($attr->{DRY_RUN}) {
          print "OLT $equipment->{nas_id}, $equipment->{nas_name}: will " . ($disabled_statuses{$dhcp_port}->{USER} eq 'enabled' ? 'enable' : 'disable') . " ONU $onu->{branch}:$onu->{onu_id} ($users_string)\n";
          next;
        }

        my $snmp_set_result = snmp_set({
          OID            => [ $oid->{OIDS} . '.' . $onu->{onu_snmp_id}, 'integer', $disabled_statuses{$dhcp_port}->{USER} eq 'enabled' ? $oid->{ENABLE_VALUE} : $oid->{DISABLE_VALUE} ],
          SNMP_COMMUNITY => $SNMP_COMMUNITY,
          VERSION        => $equipment->{snmp_version},
          TIMEOUT        => $argv->{TIMEOUT},
          DEBUG          => $attr->{DEBUG}
        });

        if ($snmp_set_result) {
          print "OLT $equipment->{nas_id}, $equipment->{nas_name}: successfully $disabled_statuses{$dhcp_port}->{USER} ONU $onu->{branch}:$onu->{onu_id} ($users_string)\n" if ($attr->{DEBUG});
        }
        else {
          $comments = "OLT $equipment->{nas_id}, $equipment->{nas_name}: failed to " . ($disabled_statuses{$dhcp_port}->{USER} eq 'enabled' ? 'enable' : 'disable') . " ONU $onu->{branch}:$onu->{onu_id} ($users_string)\n";
          print $comments;
          _generate_new_event('Failed status', $comments);

          $return_value = 0;
        }
      }
    }
  }

  return $return_value;
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
    COMMENTS    => "equipment_onu_disable_status - $comments",
    PRIORITY_ID => 3
  });

  return 1;
}

1
