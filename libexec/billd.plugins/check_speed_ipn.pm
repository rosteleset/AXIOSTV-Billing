#!/usr/bin/perl -w
=head1 NAME

 IPN3 Shaper

=cut


use Data::Dumper;
use strict;
use warnings;
use AXbills::Base qw(in_array);

our (
  $argv,
  $db,
  $Admin,
  $debug,
  %conf,
  $Nas,
  $Sessions
);

if ($argv->{LINUX_IPN2}) {
  checkspeed_ipn2();
}
elsif ($argv->{LINUX_IPN3}) {
  checkspeed_ipn3();
}


#***********************************************************
=head2 checkspeed_ipn3()

=cut
#***********************************************************
sub checkspeed_ipn3 {
  #my ($attr) = @_;

  my $WAN_IF = $argv->{WAN_IF};

  $Sessions->{debug} = 1 if ($debug > 6);

  $Sessions->online(
    {
      NAS_ID       => $LIST_PARAMS{NAS_IDS},
      USER_NAME    => '_SHOW',
      NAS_PORT_ID  => '_SHOW',
      TP_ID        => '_SHOW',
      SHOW_TP_ID   => '_SHOW',
      SPEED        => '_SHOW',
      JOIN_SERVICE => '_SHOW',
      CLIENT_IP    => '_SHOW',
      DURATION_SEC => '_SHOW',
      STARTED      => '_SHOW',
      TYPE         => $LIST_PARAMS{NAS_TYPES},
      %LIST_PARAMS
    }
  );

  my $online = $Sessions->{nas_sorted};
  my $nas_list = $Nas->list({ %LIST_PARAMS, COLS_NAME => 1 });
  my %USER_INFO = ();
  my @interfaces_arr = ();
  my ($TARIF_SPEEDS, undef) = get_tp_cure_speed();

  # Check turbo mode
  my %TURBO_SPEEDS = ();
  if ($conf{DV_TURBO_MODE}) {
    require Turbo;
    Turbo->import();
    my $Turbo = Turbo->new($db, $Admin, \%conf);
    my $list = $Turbo->list({ ACTIVE => 1, });

    foreach my $line (@$list) {
      $TURBO_SPEEDS{ $line->[0] } = $line->[5];
    }
  }
  if (!$WAN_IF) {
    $WAN_IF = `/sbin/ip route get 1.1.1.1 | head -1 | sed s/.*dev// |awk '{ print \$1 }'`;
    chop($WAN_IF);
  }
  foreach my $nas_info (@$nas_list) {
    next if (!$online->{ $nas_info->{nas_id} });

    my $l = $online->{ $nas_info->{nas_id} };
    foreach my $user (@$l) {

      my $INTERFACE = `/sbin/ip route get $user->{client_ip} | head -1 | sed s/.*dev// |awk '{ print \$1 }'`;
      if (!in_array($INTERFACE, \@interfaces_arr)) {
        push @interfaces_arr, "$INTERFACE";
      }
      my $user_speed = ($TURBO_SPEEDS{ $user->{user_name} }) ? $TURBO_SPEEDS{ $user->{user_name} } : $user->{speed};

      my $speed_in = ($user_speed > 0) ? $user_speed : ($TARIF_SPEEDS->{$user->{real_tp_id}}->{0}->{IN} || 0);
      my $speed_out = ($user_speed > 0) ? $user_speed : ($TARIF_SPEEDS->{$user->{real_tp_id}}->{0}->{OUT} || 0);
      my @ip_arr = split(/\./, $user->{client_ip});
      my $ip1 = sprintf("%02x", $ip_arr[2]);
      my $ip2 = sprintf("%02x", $ip_arr[3]);
      my $hex_id = "$ip1$ip2";
      $hex_id =~ s/^0//g;
      $USER_INFO{$hex_id}{NAME} = $user->{user_name};
      $USER_INFO{$hex_id}{UID} = $user->{uid};
      $USER_INFO{$hex_id}{IP} = $user->{client_ip};
      $USER_INFO{$hex_id}{TP_ID} = $user->{tp_id};
      $USER_INFO{$hex_id}{REAL_SPEED_IN} = $speed_in;
      $USER_INFO{$hex_id}{REAL_SPEED_OUT} = $speed_out;
      $INTERFACE =~ s/\n//g;
      $USER_INFO{$hex_id}{SPEED_OUT}{$INTERFACE} = 0;
      my @wan_interfaces_arr = split(/,/, $WAN_IF);
      foreach my $interface (@wan_interfaces_arr) {
        $interface =~ s/\n//g;
        $USER_INFO{$hex_id}{SPEED_IN}{$interface} = 0;
      }
    }
  }
  # Get tc rules
  #my %TC_INFO = ();

  foreach my $interface (@interfaces_arr) {
    $interface =~ s/\n//g;
    my $cmd = '/sbin/tc -s class ls dev ' . $interface . ' parent 1:';
    print "$cmd\n" if ($debug > 5);
    my $tc_output = '';
    open(my $PROCS, '-|', "$cmd") || die "Can't open file '$cmd' $!\n";
    while (<$PROCS>) {
      $tc_output .= $_;
    }
    close($PROCS);

    my @file_rows = split(/[\r\n]/, $tc_output);
    foreach my $file_row (@file_rows) {
      print $file_row . "\n" if ($debug > 4);
      if ($file_row =~ /class htb 1:([0-9a-z]+) root prio 1 rate (\d+)([A-Za-z]+)/ || $file_row =~ /class htb 1:([0-9a-z]+) parent 1: prio 1 rate (\d+)([A-Za-z]+)/) {
        my $sp = ($3 eq 'bit') ? substr($2, 0, - 3) : $2;
        $USER_INFO{$1}{SPEED_OUT} = $sp;
      }
    }
  }
  my @wan_interfaces_arr = split(/,/, $WAN_IF);

  foreach my $interface (@wan_interfaces_arr) {
    $interface =~ s/\n//g;
    my $cmd = '/sbin/tc -s class ls dev ' . $interface . ' parent 1:';
    print "$cmd\n" if ($debug > 5);
    my $tc_output = '';
    open(my $PROCS, '-|', "$cmd") || die "Can't open file '$cmd' $!\n";
    while (<$PROCS>) {
      $tc_output .= $_;
    }
    close($PROCS);

    my @file_rows = split(/[\r\n]/, $tc_output);

    foreach my $file_row (@file_rows) {
      print $file_row . "\n" if ($debug > 4);
      if ($file_row =~ /class htb 1:([0-9a-z]+) root prio 1 rate (\d+)([A-Za-z]+)/ || $file_row =~ /class htb 1:([0-9a-z]+) parent 1: prio 1 rate (\d+)([A-Za-z]+)/) {
        if ($USER_INFO{$1}) {
          my $sp = ($3 eq 'bit') ? substr($2, 0, - 3) : $2;
          $USER_INFO{$1}{SPEED_IN}{$interface} = $sp;
        }
      }
    }
  }

  if ($argv->{SHOW_SPEED}) {
    print "LOGIN | UID | IP | SPEED_OUT |SPEED_IN | \n";
    foreach my $line (keys %USER_INFO) {
      print "$USER_INFO{$line}{NAME} | $USER_INFO{$line}{UID} | $USER_INFO{$line}{IP} | ";

      if ($USER_INFO{$line}{SPEED_OUT}) {
        foreach my $line1 (keys %{ $USER_INFO{$line}{SPEED_OUT} }) {
          print "$line1 -> $USER_INFO{$line}{SPEED_OUT}{$line1}Kbit, ";
        }
      }
      else {
        print "Speed not defined ";
      }
      print "| ";
      if ($USER_INFO{$line}{SPEED_IN}) {
        foreach my $line1 (keys %{ $USER_INFO{$line}{SPEED_IN} }) {
          print "$line1 -> $USER_INFO{$line}{SPEED_IN}{$line1}Kbit, ";
        }
      }
      else {
        print "Speed not defined ";
      }
      print "| \n";
    }
  }

  if ($argv->{RECONFIGURE}) {
    my @FW_ACTIONS = ();
    my $SCOUNT = 'Kbit';
    foreach my $line (keys %USER_INFO) {
      if ($USER_INFO{$line}{SPEED_OUT}) {
        foreach my $line1 (keys %{ $USER_INFO{$line}{SPEED_OUT} }) {
          if ($USER_INFO{$line}{SPEED_OUT}{$line1} != $USER_INFO{$line}{REAL_SPEED_OUT}) {
            push @FW_ACTIONS, "/sbin/tc class del dev $line1 parent 1: classid 1:$line";
            push @FW_ACTIONS,
              "/sbin/tc class replace dev $line1 parent 1: classid 1:$line htb rate $USER_INFO{$line}{REAL_SPEED_OUT}$SCOUNT burst 100k cburst 100k prio 1";
          }
        }
      }

      if ($USER_INFO{$line}{SPEED_IN}) {
        foreach my $line1 (keys %{ $USER_INFO{$line}{SPEED_IN} }) {
          if ($USER_INFO{$line}{SPEED_IN}{$line1} != $USER_INFO{$line}{REAL_SPEED_IN}) {
            push @FW_ACTIONS, "/sbin/tc class del dev $line1 parent 1: classid 1:$line";
            push @FW_ACTIONS,
              "/sbin/tc class replace dev $line1 parent 1: classid 1:$line htb rate $USER_INFO{$line}{REAL_SPEED_IN}$SCOUNT burst 100k cburst 100k prio 1";
          }
        }
      }

      if ($#FW_ACTIONS > -1) {
        print "Change speed: $USER_INFO{$line}{NAME} | SPEED_OUT:  $USER_INFO{$line}{REAL_SPEED_OUT} | SPEED_IN: $USER_INFO{$line}{REAL_SPEED_IN} \n";
        make_rule_speed(\@FW_ACTIONS);
        @FW_ACTIONS = ();
      }
    }
  }

  return 1;
}

#***********************************************************
=head2 checkspeed_ipn2()

=cut
#***********************************************************
sub checkspeed_ipn2 {
  #my ($attr) = @_;

  my $WAN_IF = $argv->{WAN_IF};

  $Sessions->{debug} = 1 if ($debug > 6);

  $Sessions->online(
    {
      NAS_ID       => $LIST_PARAMS{NAS_IDS},
      USER_NAME    => '_SHOW',
      NAS_PORT_ID  => '_SHOW',
      TP_ID        => '_SHOW',
      SHOW_TP_ID   => '_SHOW',
      SPEED        => '_SHOW',
      JOIN_SERVICE => '_SHOW',
      CLIENT_IP    => '_SHOW',
      DURATION_SEC => '_SHOW',
      STARTED      => '_SHOW',
      %LIST_PARAMS
    }
  );

  my $online = $Sessions->{nas_sorted};
  my $nas_list = $Nas->list({ %LIST_PARAMS, COLS_NAME => 1 });
  my %USER_INFO = ();
  my @interfaces_arr = ();
  my ($TARIF_SPEEDS, undef) = get_tp_cure_speed();

  # Check turbo mode
  my %TURBO_SPEEDS = ();
  if ($conf{DV_TURBO_MODE}) {
    require Turbo;
    Turbo->import();
    my $Turbo = Turbo->new($db, $Admin, \%conf);
    my $list = $Turbo->list({ ACTIVE => 1, });

    foreach my $line (@$list) {
      $TURBO_SPEEDS{ $line->[0] } = $line->[5];
    }
  }
  if (!$WAN_IF) {
    $WAN_IF = `/sbin/ip route get 1.1.1.1 | head -1 | sed s/.*dev// |awk '{ print \$1 }'`;
    chop($WAN_IF);
  }
  foreach my $nas_info (@$nas_list) {
    next if (!$online->{ $nas_info->{nas_id} });

    my $l = $online->{ $nas_info->{nas_id} };
    foreach my $user (@$l) {

      my $INTERFACE = `/sbin/ip route get $user->{client_ip} | head -1 | sed s/.*dev// |awk '{ print \$1 }'`;
      if (!in_array($INTERFACE, \@interfaces_arr)) {
        push @interfaces_arr, "$INTERFACE";
      }
      my $user_speed = ($TURBO_SPEEDS{ $user->{user_name} }) ? $TURBO_SPEEDS{ $user->{user_name} } : $user->{speed};

      my $speed_in = ($user_speed > 0) ? $user_speed : ($TARIF_SPEEDS->{$user->{real_tp_id}}->{0}->{IN} || 0);
      my $speed_out = ($user_speed > 0) ? $user_speed : ($TARIF_SPEEDS->{$user->{real_tp_id}}->{0}->{OUT} || 0);

      $USER_INFO{$user->{uid}}{NAME} = $user->{user_name};
      $USER_INFO{$user->{uid}}{IP} = $user->{client_ip};
      $USER_INFO{$user->{uid}}{TP_ID} = $user->{tp_id};
      $USER_INFO{$user->{uid}}{REAL_SPEED_IN} = $speed_in;
      $USER_INFO{$user->{uid}}{REAL_SPEED_OUT} = $speed_out;
      $INTERFACE =~ s/\n//g;
      $USER_INFO{$user->{uid}}{SPEED_OUT}{$INTERFACE} = 0;
      my @wan_interfaces_arr = split(/,/, $WAN_IF);
      foreach my $interface (@wan_interfaces_arr) {
        $interface =~ s/\n//g;
        $USER_INFO{$user->{uid}}{SPEED_IN}{$interface} = 0;
      }
    }
  }

  # Get tc rules

  #my %TC_INFO = ();

  foreach my $interface (@interfaces_arr) {
    $interface =~ s/\n//g;
    my $cmd = '/sbin/tc class ls dev ' . $interface . ' parent 1:';
    print "$cmd\n" if ($debug > 5);
    my $tc_output = '';
    open(my $PROCS, '-|', "$cmd") || die "Can't open file '$cmd' $!\n";
    while (<$PROCS>) {
      $tc_output .= $_;
    }
    close($PROCS);

    my @file_rows = split(/[\r\n]/, $tc_output);
    foreach my $file_row (@file_rows) {
      print $file_row . "\n" if ($debug > 4);
      if ($file_row =~ /class htb 1:(\d+) parent 1:1 leaf \d+: prio 0 rate (\d+)([A-Za-z]+)/) {
        my $uid = $1 - 101;
        if ($USER_INFO{$uid}) {
          my $sp = ($3 eq 'bit') ? substr($2, 0, - 3) : $2;
          $USER_INFO{$uid}{SPEED_OUT}{$interface} = $sp;
        }
      }
    }
  }
  my @wan_interfaces_arr = split(/,/, $WAN_IF);

  foreach my $interface (@wan_interfaces_arr) {
    $interface =~ s/\n//g;
    my $cmd = '/sbin/tc class ls dev ' . $interface . ' parent 1:';
    print "$cmd\n" if ($debug > 5);
    my $tc_output = '';
    open(my $PROCS, '-|', "$cmd") || die "Can't open file '$cmd' $!\n";
    while (<$PROCS>) {
      $tc_output .= $_;
    }
    close($PROCS);

    my @file_rows = split(/[\r\n]/, $tc_output);

    foreach my $file_row (@file_rows) {
      print $file_row . "\n" if ($debug > 4);
      if ($file_row =~ /class htb 1:(\d+) parent 1:1 leaf \d+: prio 0 rate (\d+)([A-Za-z]+)/) {
        my $uid = $1 - 5101;
        if ($USER_INFO{$uid}) {
          my $sp = ($3 eq 'bit') ? substr($2, 0, - 3) : $2;
          $USER_INFO{$uid}{SPEED_IN}{$interface} = $sp;
        }
      }
    }
  }
  if ($argv->{SHOW_SPEED}) {
    print "LOGIN | UID | IP | SPEED_OUT |SPEED_IN | \n";
    foreach my $line (keys %USER_INFO) {
      print "$USER_INFO{$line}{NAME} | $line | $USER_INFO{$line}{IP} | ";
      if ($USER_INFO{$line}{SPEED_OUT}) {
        foreach my $line1 (keys %{ $USER_INFO{$line}{SPEED_OUT} }) {
          print "$line1 -> $USER_INFO{$line}{SPEED_OUT}{$line1}Kbit, ";
        }
      }
      else {
        print "Speed not defined ";
      }
      print "| ";
      if ($USER_INFO{$line}{SPEED_IN}) {
        foreach my $line1 (keys %{ $USER_INFO{$line}{SPEED_IN} }) {
          print "$line1 -> $USER_INFO{$line}{SPEED_IN}{$line1}Kbit, ";
        }
      }
      else {
        print "Speed not defined ";
      }
      print "| \n";
    }
  }
  if ($argv->{RECONFIGURE}) {
    my @FW_ACTIONS = ();
    my $SCOUNT = 'Kbit';

    foreach my $line (keys %USER_INFO) {
      my $ruleid_out = $line + 101;
      my $ruleid_in = $line + 5101;
      if ($USER_INFO{$line}{SPEED_OUT}) {
        foreach my $line1 (keys %{ $USER_INFO{$line}{SPEED_OUT} }) {
          if ($USER_INFO{$line}{SPEED_OUT}{$line1} != $USER_INFO{$line}{REAL_SPEED_OUT}) {
            push @FW_ACTIONS,
              "/sbin/tc filter del dev $line1 parent 1: protocol ip prio 3 handle $ruleid_out fw classid 1:$ruleid_out > /dev/null 2>&1";
            push @FW_ACTIONS, "/sbin/tc class del dev $line1 parent 1:1 classid 1:$ruleid_out > /dev/null 2>&1";
            push @FW_ACTIONS,
              "/sbin/tc class add dev $line1 parent 1:1 classid 1:$ruleid_out htb rate $USER_INFO{$line}{REAL_SPEED_OUT}$SCOUNT";
            push @FW_ACTIONS,
              "/sbin/tc filter add dev $line1 parent 1: protocol ip prio 3 handle $ruleid_out fw classid 1:$ruleid_out";
            push @FW_ACTIONS, "/sbin/tc qdisc add dev $line1 parent 1:$ruleid_out handle $ruleid_out: sfq perturb 10";
          }
        }
      }
      if ($USER_INFO{$line}{SPEED_IN}) {
        foreach my $line1 (keys %{ $USER_INFO{$line}{SPEED_IN} }) {
          if ($USER_INFO{$line}{SPEED_IN}{$line1} != $USER_INFO{$line}{REAL_SPEED_IN}) {
            push @FW_ACTIONS,
              "/sbin/tc filter del dev $line1 parent 1: protocol ip prio 3 handle $ruleid_in fw classid 1:$ruleid_in > /dev/null 2>&1";
            push @FW_ACTIONS, "/sbin/tc class del dev $line1 parent 1:1 classid 1:$ruleid_in > /dev/null 2>&1";
            push @FW_ACTIONS,
              "/sbin/tc class add dev $line1 parent 1:1 classid 1:$ruleid_in htb rate $USER_INFO{$line}{REAL_SPEED_IN}$SCOUNT";
            push @FW_ACTIONS,
              "/sbin/tc filter add dev $line1 parent 1: protocol ip prio 3 handle $ruleid_in fw classid 1:$ruleid_in";
            push @FW_ACTIONS, "/sbin/tc qdisc add dev $line1 parent 1:$ruleid_in handle $ruleid_in: sfq perturb 10";
          }
        }
      }
      if (@FW_ACTIONS) {
        print "Change speed: $USER_INFO{$line}{NAME} | SPEED_OUT:  $USER_INFO{$line}{REAL_SPEED_OUT} | SPEED_IN: $USER_INFO{$line}{REAL_SPEED_IN} \n";
        make_rule_speed(\@FW_ACTIONS);
        @FW_ACTIONS = ();
      }
    }
  }

  return 1;
}

#***********************************************************
=head2 make_rule_speed($attr) make speed actions

=cut
#***********************************************************
sub make_rule_speed {
  my ($attr) = @_;

  foreach my $line (@$attr) {
    if ($debug > 1) {
      print "$line\n";
    }
    else {
      if (system("$line")) {
        print "Error: $?/$! '$line' \n";
      }
    }
  }

  return 1;
}

1
