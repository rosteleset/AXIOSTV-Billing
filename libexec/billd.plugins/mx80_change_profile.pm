#**********************************************************
=head1 NAME

  Change MX80 profile

=head1 PARAMETERS

  SPEED=IN:OUT  Cusctom speed Kb
  PROFILE=  - Profile name
  START=1   - Start custom profile
  NAT       - Use nat profile
  DEPOSIT   - Deposit filter

=cut
#**********************************************************

use warnings;
use strict;
use AXbills::Base qw(cmd startup_files);

our (
  $debug,
  $db,
  $argv
);


our Internet::Sessions $Sessions;
our Internet $Internet;
our Nas $Nas;

mx80_change_profile();

#**********************************************************
=head2 mx80_change_profile()

=cut
#**********************************************************
sub mx80_change_profile {
  #my ($attr)=@_;
  #my $Nas_cmd = AXbills::Nas::Control->new( $db, \%conf );

  my $Nas_cmd = AXbills::Nas::Control->new($db, \%conf);
  my $files = startup_files({ TPL_DIR => $conf{TPL_DIR} });
  my $RADCLIENT = $files->{RADCLIENT} || $conf{FILE_RADCLIENT} || '/usr/local/bin/radclient';

  print "mx80_change_profile\n" if ($debug > 1);
  my $debug_output = '';

  if (!$LIST_PARAMS{NAS_IDS}) {
    $LIST_PARAMS{TYPE} = 'mx80';
  }

  if ($argv->{TP_ID}) {
    $LIST_PARAMS{TP_ID}=$argv->{TP_ID};
  }

  if ($argv->{DEPOSIT}) {
    $LIST_PARAMS{DEPOSIT}=$argv->{DEPOSIT};
  }

  if ($debug > 6) {
    $Nas->{debug} = 1;
    $Internet->{debug} = 1;
    $Sessions->{debug} = 1;
  }

  #Tps  speeds
  my %TPS_SPEEDS = ();
  my $tp_speed_list = $Internet->get_speed({ COLS_NAME => 1, DESC => 'DESC' });

  foreach my $tp (@$tp_speed_list) {
    if (defined($tp->{tt_id}) && $tp->{tp_id}) {
      my $in_speed = $tp->{in_speed} || 0;
      my $out_speed = $tp->{out_speed} || 0;

      if($argv->{SPEED}) {
        ($in_speed,$out_speed) = split(/:/, $argv->{SPEED});
      }

      $TPS_SPEEDS{$tp->{tp_id}}{$tp->{tt_id}} = ($out_speed * 1024) . "," . ($in_speed * 1024);
    }
  }

  $Sessions->online({
    USER_NAME    => '_SHOW',
    NAS_PORT_ID  => '_SHOW',
    CONNECT_INFO => '_SHOW',
    TP_ID        => '_SHOW',
    SPEED        => '_SHOW',
    UID          => '_SHOW',
    JOIN_SERVICE => '_SHOW',
    CLIENT_IP    => '_SHOW',
    DURATION_SEC => '_SHOW',
    STARTED      => '_SHOW',
    CID          => '_SHOW',
    ACCT_SESSION_ID => '_SHOW',
    NAS_ID       => $LIST_PARAMS{NAS_IDS},
    %LIST_PARAMS
  });

  my $online_list = $Sessions->{nas_sorted};

  my %nas_speeds = ();
  my $nas_list = $Nas->list({
    %LIST_PARAMS,
    NAS_TYPE   => 'mx80',
    COLS_NAME  => 1,
    COLS_UPPER => 1
  });

  foreach my $nas_info (@$nas_list) {
    $debug_output .= "NAS ID: $nas_info->{NAS_ID} MNG_INFO: " . ($nas_info->{NAS_MNG_USER} || q{}) . "\@$nas_info->{NAS_MNG_IP_PORT}\n" if ($debug > 2);

    #if don't have online users skip it
    my $l = $online_list->{ $nas_info->{NAS_ID} };

    next if ($#{$l} < 0);
    my @coa_action = ();
    foreach my $online (@$l) {
      my $connection_info = $online->{'connect_info'} || q{};
      print "User: $online->{user_name} TP: $online->{tp_id} Connect info: $connection_info\n" if ($debug > 0);
      my $profile_sufix = 'pppoe';

      if ($connection_info !~ /demux/) {
        $profile_sufix = 'ipoe';
        $online->{'user_name'} = $online->{cid} || $online->{user_name};
      }

      if (($online->{tp_id} && $TPS_SPEEDS{$online->{tp_id}}) || $argv->{PROFILE}) {
        my $num = scalar(keys %{ $TPS_SPEEDS{$online->{tp_id}} } ); # old static value 3;
        my %RAD_REPLY_DEACTIVATE = ();
        my %RAD_REPLY_ACTIVATE = ();

        foreach my $tt_id (keys %{$TPS_SPEEDS{$online->{tp_id}}}) {
          print "TT_ID: tt_id -> " . $TPS_SPEEDS{$online->{tp_id}}{$tt_id} . "\n" if ($debug > 3);

          my $traffic_class_name = ($tt_id > 0) ? "local_$tt_id" : 'global';
          if ($TPS_SPEEDS{$online->{tp_id}}{$tt_id}) {
            my $profile_num = $num - $tt_id;
            push @{$RAD_REPLY_DEACTIVATE{'ERX-Service-Deactivate'}}, "svc-$traffic_class_name-$profile_sufix";
            push @{$RAD_REPLY_ACTIVATE{'ERX-Service-Activate:' . $profile_num }}, "svc-$traffic_class_name-$profile_sufix(" . $TPS_SPEEDS{$online->{tp_id}}{$tt_id} . ")";
          }
        }

        if ($debug > 2) {
          #          while(my($k, $v)=each %{ \%RAD_REPLY_DEACTIVATE, \%RAD_REPLY_ACTIVATE }) {
          #            print "$k -> \n";
          #            foreach my $val (@$v) {
          #              print "       $val\n";
          #            }
          #          }
        }

        if($argv->{OLD_FORMWARE}) {
          $RAD_REPLY_DEACTIVATE{'User-Name'} = $online->{'user_name'};
          $RAD_REPLY_ACTIVATE{'User-Name'} = $online->{'user_name'};
        }

        $RAD_REPLY_DEACTIVATE{'Acct-Session-Id'} = $online->{'acct_session_id'};
        $RAD_REPLY_ACTIVATE{'Acct-Session-Id'}   = $online->{'acct_session_id'};
        if (! $argv->{OLD_VERSION}) {
          my $profile = $argv->{PROFILE};
          if ($argv->{START}) {
            $RAD_REPLY_DEACTIVATE{'ERX-Service-Deactivate'}[0] =~ /(.+)\(?/;
            my $sub_profile = $1;

            @coa_action = ({
              'ERX-Service-Deactivate' => $sub_profile,
              'Acct-Session-Id'        => $online->{acct_session_id}
            });

            if ($argv->{NAT}) {
              $argv->{NAT} =~ /(.+)\(?/;
              $sub_profile = $1;

              push @coa_action, {
                'ERX-Service-Deactivate' => $sub_profile,
                'Acct-Session-Id'        => $online->{acct_session_id}
              };
            }

            push @coa_action, {
                'ERX-Service-Activate:1' => $profile,
                'Acct-Session-Id'        => $online->{acct_session_id}
              };
          }
          else {
            $profile =~ /(.+)\(/;
            my $sub_profile = $1;

            @coa_action = (
              { 'ERX-Service-Deactivate' => $sub_profile,
                'Acct-Session-Id'        => $online->{acct_session_id}
              }
            );

            if ($RAD_REPLY_ACTIVATE{'ERX-Service-Activate:'.1}[0]) {
              push @coa_action, {
                'ERX-Service-Activate:1' => $RAD_REPLY_ACTIVATE{'ERX-Service-Activate:'.1}[0],
                'Acct-Session-Id'        => $online->{acct_session_id}
              }
            }

            if ($argv->{NAT}) {
              $sub_profile = $argv->{NAT};

              push @coa_action, {
                'ERX-Service-Deactivate' => $sub_profile,
                'Acct-Session-Id'        => $online->{acct_session_id}
              };
            }

          }

          $Nas_cmd->hangup(
            $nas_info,
            $online->{nas_port_id},
            $online->{user_name},
            {
              %{$nas_info},
              ACCT_SESSION_ID      => $online->{acct_session_id},
              CALLING_STATION_ID   => $online->{CID} || $online->{cid},
              FRAMED_IP_ADDRESS    => $online->{client_ip},
              NETMASK              => $online->{netmask},
              UID                  => $online->{uid},
              DEBUG                => $debug,
              FILTER_ID            => $online->{filter_id},
              OLD_TP_ID            => $online->{tp_id},
              ACCT_TERMINATE_CAUSE => 15,
              GUEST                => $online->{guest},
              #INTERNET             => 1,
              COA_ACTION           => \@coa_action
            }
          );

          print @coa_action;
        }
        else {
          my $rad_vals = make_rad_pairs(\%RAD_REPLY_DEACTIVATE);
          my $run = "echo \"$rad_vals\" | $RADCLIENT $nas_info->{NAS_MNG_IP_PORT} coa $nas_info->{NAS_MNG_PASSWORD}";
          cmd($run, { DEBUG => $debug });

          $rad_vals = make_rad_pairs(\%RAD_REPLY_ACTIVATE);
          $run = "echo \"$rad_vals\" | $RADCLIENT $nas_info->{NAS_MNG_IP_PORT} coa $nas_info->{NAS_MNG_PASSWORD}";
          cmd($run, { DEBUG => $debug });
        }
      }
    }
  }

  print $debug_output;
  return \%nas_speeds;
}

#***********************************************************
=head2 make_rad_request($request)

  Arguments:
    $request   - Request hash
  Results:
    rad_pairs

ERX-Service-Activate:3 = svc-global-ipoe(73400320,73400320)

        Acct-Interim-Interval = 90
        ERX-Service-Activate:2 = "svc-local_1-ipoe(5148672,4120576)"
        Framed-IP-Address = 192.168.109.189
        Framed-IP-Netmask = 255.255.255.255
        ERX-Service-Activate:3 = "svc-global-ipoe(2076672,1048576)"


=cut
#***********************************************************
sub make_rad_request {


  return 1;
}

#***********************************************************
=head2 make_rad_pairs($request)

  Arguments:
    $request   - Request hash
  Results:
    rad_pairs

=cut
#***********************************************************
sub make_rad_pairs {
  my ($request) = @_;

  my @rad_pairs = ();

  while (my ($k, $v) = each %$request) {
    if (ref $v eq 'ARRAY') {
      foreach my $val (@$v) {
        push @rad_pairs, "$k=\\\"$val\\\"";
      }
    }
    else {
      push @rad_pairs, "$k=\\\"$v\\\"";
    }
  }

  return join(', ', @rad_pairs);
}

1
