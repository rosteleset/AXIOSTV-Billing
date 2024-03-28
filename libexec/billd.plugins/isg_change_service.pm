# billd plugin

=head1 NAME

 DESCRIBE: A module to change ISG (Cisco) services dynamically
 VERSION:  0.02

 Documentation used:
   - https://www.cisco.com/c/en/us/td/docs/ios/12_2sb/isg/coa/guide/isg_ig/isgcoa3.html
   - https://community.cisco.com/t5/service-providers-documents/using-coa-change-of-authorization-for-access-and-bng-platforms/ta-p/3121215
   - https://metacpan.org/pod/Authen::Radius

=cut
#**********************************************************


use strict;
use warnings FATAL => 'all';
use Radius;

my $max_attempts = 3;   # number of attempts to reach a silent NAS
my $max_int_age = 1800; # ignore changing services if the interval
# started a long time ago. The value 1800
# is good for running the script once an hour.

our (
  $Admin,
  $Nas,
  %conf,
  $debug
);


sub log_info {
  if ($debug and $debug > 0) {
    my @text = @_;
    print @text;
  }
}


sub compare_services {
  my ($tp_svc, $user_svc) = @_;
  my %count = ();
  my (@disable_svc, @enable_svc);

  # Load package services to start counting
  for my $element (@{$tp_svc}) {$count{$element}++};

  for my $element (@{$user_svc}) {
    if ($count{$element}) {
      $count{$element}++;
    }
    else {
      # Mark unique user services as candidates for deactivation
      push @disable_svc, $element;
    }
  };

  for my $element (keys %count) {
    push @enable_svc, $element if $count{$element} == 1;
  }

  return \@disable_svc, \@enable_svc;
}


sub send_reliably {
  my ($r, $nas) = @_;
  my $type;

  for (my $i = 0; $i < $max_attempts; $i++) {
    $r->send_packet(COA_REQUEST) and $type = $r->recv_packet;
    if (!$type) {
      print "No response from $nas->{ip_port}\n";
    }
    else {
      return $type;
    }
  }

  print "Giving up on attempting to contact $nas->{ip_port}\n";
  return $type;
}


sub pick_services {
  my ($r, $services) = @_;

  for my $a ($r->get_attributes()) {
    if ($a->{Name} eq 'Cisco-Account-Info' and $a->{Value} =~ /^N1([\w-]+)/) {
      push @{$services}, $1;
      log_info "Found active service [$1]\n";
    }
  }
}


sub set_attributes {
  my ($r, $username, $sid, $avpairs) = @_;

  $r->clear_attributes;
  $r->add_attributes({ Name => 'User-Name', Value => $username });
  $r->add_attributes({ Name => 'Acct-Session-Id', Value => $sid });
  foreach my $avpair (@{$avpairs}) {
    $r->add_attributes({ Name => 'Cisco-AVPair', Value => $avpair });
  }
}


my $curdate = localtime;
log_info "\n$curdate\n";

if ($debug and $debug > 1) {
  print "Read-only mode activated. All destructive operations are ignored.\n";
}

# We need to fix current time to get more stable query output
my $curtime = time;

# Return RADIUS pairs and associated package ID for currently active intervals
my $select = "
  SELECT
    ti.tp_id,
    ti2.started_secs_ago,
    ti.rad_pairs
  FROM
    intervals AS ti JOIN
    (
      SELECT
        tp_id,
        MIN($curtime - UNIX_TIMESTAMP(begin)) AS started_secs_ago
      FROM
        intervals
      WHERE $curtime >= UNIX_TIMESTAMP(begin)
      GROUP BY tp_id
    ) AS ti2 ON ti.tp_id = ti2.tp_id AND $curtime - UNIX_TIMESTAMP(ti.begin) = ti2.started_secs_ago
  WHERE
    ti.rad_pairs != '' AND
    ti2.started_secs_ago < $max_int_age
";

$Admin->query($select, undef, { COLS_NAME => 1 });


# Store packages and their parameters
my %plans = ();
if ($Admin->{TOTAL} > 0) {
  foreach (@{$Admin->{list}}) {
    #$plans{$_->{tp_id}} = { radpairs => $_->{rad_pairs} };
    my @subattrs = split(/,\s+/, $_->{rad_pairs});
    foreach my $subattr (@subattrs) {
      if ($subattr =~ /Cisco-Account-Info.?=A([\w-]+)/) {
        push @{$plans{$_->{tp_id}}->{services}}, $1;
      }
    }
  }
}
else {
  log_info "There are no packages in need of changing services. Exit.\n";
  return 1;
}


# Pick subscribers and relevant info to change ISG service
my $tp_ids = join(',', keys %plans);
$select = "
  SELECT
    tp_id,
    user_name,
    acct_session_id,
    INET_NTOA(nas_ip_address) AS nas_ip
  FROM
    internet_online
  WHERE
    tp_id IN ($tp_ids) AND
    guest = 0
";

$Admin->query($select, undef, { COLS_NAME => 1 });


# Assign subscribers to related package
if ($Admin->{TOTAL} > 0) {
  foreach (@{$Admin->{list}}) {
    $plans{$_->{tp_id}}->{users}->{$_->{user_name}} = {
      acct_session_id => $_->{acct_session_id},
      nas_ip          => $_->{nas_ip}
    };
  }
}
else {
  log_info "There are no active users in need for changing services. Exit.\n";
  return 1;
}

my $nas_list = $Nas->list({ COLS_NAME => 1 });
my %nas_params = ();
if ($nas_list) {
  foreach (@{$nas_list}) {
    $nas_params{$_->{nas_ip}} = {
      ip_port  => join(':', (split(':', $_->{nas_mng_ip_port}))[0, 1]),
      password => $_->{nas_mng_password}
    };
  }
}
else {
  print "Cannot access the params of access servers. Abort.\n";
  return 0;
}

while (my ($tp_id, $tp_data) = each %plans) {
  log_info "[Package ID $tp_id] Looking for active subscribers\n";
  if ($tp_data->{users}) {
    while (my ($username, $userinfo) = each $tp_data->{users}) {

      log_info "Found active subscriber [$username]\n";

      my $nas = $nas_params{$userinfo->{nas_ip}};

      if ($nas->{ip_port} !~ /^(\d+\.){3}\d+:\d+$/) {
        print "[$username] Wrong IP:Port for NAS. Skip to next user.\n";
        next;
      }

      my $r = Radius->new(
        Host   => $nas->{ip_port},
        Secret => $nas->{password}
      );

      $conf{dictionary} = '/usr/axbills/lib/dictionary' if (!$conf{dictionary});
      $r->load_dictionary($conf{dictionary});


      # Query the current state of a subscriber
      set_attributes(
        $r, $username, $userinfo->{acct_session_id},
        [ "subscriber:command=account-status-query" ]
      );

      my $reply_type = send_reliably($r, $nas);
      if (!$reply_type) {
        next;
      }
      elsif ($reply_type == 45) {
        print "[$username] Wrong session details supplied (SID: $userinfo->{acct_session_id}). ";
        print "Moving to next subscriber\n";
        next;
      }

      # Collect active services applied to subscriber
      pick_services($r, $userinfo->{applied_services} = []);

      # Prepare lists to deactivate/activate services
      my ($disable_svc, $enable_svc) = compare_services($tp_data->{services},
        $userinfo->{applied_services});
      if (!@{$disable_svc} and !@{$enable_svc}) {
        log_info "The subscriber has a proper set of services. ";
        log_info "Nothing to do\n";
        next;
      }


      # Outdated services deactivation code
      for my $svc (@{$disable_svc}) {

        set_attributes(
          $r, $username, $userinfo->{acct_session_id},
          [
            "subscriber:command=deactivate-service",
            "subscriber:service-name=$svc"
          ]
        );

        if ($debug and $debug > 1) {
          print "Sending a CoA request to deactivate the service [$svc]\n";
        }
        else {
          log_info "Sending a CoA request to deactivate the service [$svc]\n";
          $reply_type = send_reliably($r, $nas);
          if (!$reply_type) {
            next;
          }
          elsif ($reply_type == 45) {
            print "[$username] Cannot deactivate the service [$svc]. Moving to next subscriber\n";
            next;
          }
        }
      }


      # Fresh services activation code
      for my $svc (@{$enable_svc}) {

        set_attributes(
          $r, $username, $userinfo->{acct_session_id},
          [
            "subscriber:command=activate-service",
            "subscriber:service-name=$svc"
          ]
        );

        if ($debug and $debug > 1) {
          print "Sending a CoA request to activate the service [$svc]\n";
        }
        else {
          log_info "Sending a CoA request to activate the service [$svc]\n";
          $reply_type = send_reliably($r, $nas);
          if (!$reply_type) {
            next;
          }
          elsif ($reply_type == 45) {
            print "[$username] Cannot activate the service [$svc]. Moving to next subscriber\n";
            next;
          }
        }
      }


      # Query the final state of a subscriber
      set_attributes(
        $r, $username, $userinfo->{acct_session_id},
        [ "subscriber:command=account-status-query" ]
      );

      $reply_type = send_reliably($r, $nas);
      if (!$reply_type) {
        next;
      }
      elsif ($reply_type == 45) {
        print "[$username] Wrong session details supplied (SID: $userinfo->{acct_session_id}). ";
        print "Moving to next subscriber\n";
        next;
      }

      # Collect active services applied to subscriber
      pick_services($r, $userinfo->{applied_services} = []);

      # Prepare lists to deactivate/activate services
      ($disable_svc, $enable_svc) = compare_services($tp_data->{services},
        $userinfo->{applied_services});
      if (@{$disable_svc} or @{$enable_svc}) {
        print "[$username] Failed to change services.\n";
      }
      else {
        log_info "Successfully changed services for the subscriber.\n";
      }

    }
  }
}

1;
