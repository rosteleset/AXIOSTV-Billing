=head1 NAME

  billd plugin

  DESCRIBE: Change speed via mpd CoA

=cut
#**********************************************************

use strict;
use warnings;

require Tariffs;
Tariffs->import();

our (
  $argv,
  $db,
  $Admin,
  $debug,
  %conf,
  $Nas,
  $Sessions
);

#my $Tariffs = Tariffs->new($db, \%conf, $Admin);

change_mpd_speed();

#**********************************************************
=head2 change_speed($attr)

=cut
#**********************************************************
sub change_mpd_speed {
  my ($attr) = @_;
  #my $result = '';

  if ($debug > 3) {
    print "Check speed mpd5\n";
  }

  my ($TARIF_SPEEDS, $class2nets) = get_tp_cure_speed($attr);
  my $TURBO_SPEEDS = get_turbo_speed();

  if ($argv->{LOGINS}) {
    $LIST_PARAMS{USER_NAME} = $argv->{LOGINS};
  }
  if ($argv->{NAS_IDS}) {
	$LIST_PARAMS{NAS_ID} = $argv->{NAS_IDS};
  }
  if ($argv->{TP_IDS}) {
	$LIST_PARAMS{ONLINE_TP_ID} = $argv->{TP_IDS};
  }
  if ($debug > 6) {
    $Sessions->{debug} = 1;
    $Nas->{debug} = 1;
  }

  $Sessions->online(
    {
      USER_NAME       => '_SHOW',
      NAS_PORT_ID     => '_SHOW',
      SHOW_TP_ID      => '_SHOW',
      SPEED           => '_SHOW',
      ACCT_SESSION_ID => '_SHOW',
      GUEST           => '_SHOW',
      ONLINE_TP_ID     => '_SHOW',
      NAS_ID          => '_SHOW',
      GUEST           => 0,
      %LIST_PARAMS,
    });

  if ($Sessions->{errno}) {
    print "[$Sessions->{errno}] $Sessions->{err_str}\n";
    exit;
  }

  my $online = $Sessions->{nas_sorted};

  my $nas_list = $Nas->list({ %LIST_PARAMS, COLS_NAME => 1 });

  foreach my $nas_info (@$nas_list) {
    if (!$online->{ $nas_info->{nas_id} }) {
      if ($debug > 3) {
        print "No active sessions\n";
      }
      next;
    }
	
    my $l = $online->{ $nas_info->{nas_id} };

    foreach my $line (@$l) {

      #Get speed
      my $user_speed = ($TURBO_SPEEDS->{ $line->{user_name} }) ? $TURBO_SPEEDS->{ $line->{user_name} } : $line->{speed};
      my $speed_in  = ($user_speed > 0) ? $user_speed : ($TARIF_SPEEDS->{ $line->{real_tp_id} }->{0}->{IN}  || 0);
      my $speed_out = ($user_speed > 0) ? $user_speed : ($TARIF_SPEEDS->{ $line->{real_tp_id} }->{0}->{OUT} || 0);

      if ($TARIF_SPEEDS->{ $line->{real_tp_id} }->{0}->{EXPRESSION}) {
        my $RESULT = get_speed_expr($TARIF_SPEEDS->{ $line->{real_tp_id} }->{0}->{EXPRESSION}, $line);

        if ($RESULT->{SPEED_IN}) {
          $speed_in = $RESULT->{SPEED_IN};
        }

        if ($RESULT->{SPEED_OUT}) {
          $speed_out = $RESULT->{SPEED_OUT};
        }

        if ($RESULT->{SPEED}) {
          $speed_in  = $RESULT->{SPEED};
          $speed_out = $RESULT->{SPEED};
        }
      }

      my $ret = setspeed_mpd(
        {
          NAS_TYPE         => $nas_info->{nas_type},
          NAS_MNG_IP_PORT  => $nas_info->{nas_mng_ip_port},
          NAS_MNG_PASSWORD => $nas_info->{nas_mng_password}
        },
        $line->{nas_port_id},
        $line->{user_name},
        $speed_out,
        $speed_in,
        {
          ACCT_SESSION_ID => $line->{acct_session_id} || '--',
          FRAMED_IP_ADDRESS => $line->{client_ip},
          UID               => $line->{uid},
          debug             => $debug
        }
      );

      print "Change speed: $line->{user_name} SESSION_ID: $line->{acct_session_id}, SPEED: $speed_in/$speed_out" . (($ret > -1) ? ", ERROR: $ret" : "") . "\n" if ($debug > 0);
    }
  }

  return 1;
}

#**********************************************************
# setspeed_mpd
# Radius-CoA messages for mpd5
#**********************************************************
sub setspeed_mpd {
  my ($NAS, $PORT, $UNAME, $UPSPEED, $DOWNSPEED, $attr) = @_;

	my ($ip, $mng_port, undef, undef) = split(/:/, $NAS->{NAS_MNG_IP_PORT}, 4);
  if ($debug > 0){
  	print "SETSPEED: NAS_MNG: $ip:$mng_port $NAS->{NAS_MNG_PASSWORD}";
  }

  if (!$mng_port) {
    $mng_port = 3799;
  }

  #my %RAD_PAIRS = ();
  my $type;
  my $result = 0;
  my $r      = Radius->new(
    Host   => "$ip:$mng_port",
    Secret => "$NAS->{NAS_MNG_PASSWORD}"
  ) or return "Can't connect '$ip:$mng_port' $!";

  my $up_speed   = shape_speed($UPSPEED);
  my $down_speed = shape_speed($DOWNSPEED);
  $conf{'dictionary'} = '/usr/axbills/lib/dictionary' if (!$conf{'dictionary'});

  $r->load_dictionary($conf{'dictionary'});

  $r->add_attributes({ Name => 'Framed-Protocol', Value => 'PPP' },{ Name => 'NAS-Port', Value => "$PORT" });
	if ( $NAS->{NAS_TYPE} eq 'mikrotik') {
		$r->add_attributes( { Name => 'Mikrotik-Rate-Limit', Value => $DOWNSPEED .'K/'. $UPSPEED . 'K '} );
	} else {
		$r->add_attributes({ Name => 'mpd-limit', Value => "out#1#0=all $up_speed pass" },
											 { Name => 'mpd-limit', Value => "in#1#0=all $down_speed pass" });
	}

  $r->add_attributes({ Name => 'Framed-IP-Address', Value => "$attr->{FRAMED_IP_ADDRESS}" }) if $attr->{FRAMED_IP_ADDRESS};
  $r->send_packet(43) and $type = $r->recv_packet;

  if (!defined $type) {

    # No responce from CoA server
    #log_print('LOG_DEBUG',
    print "No responce from CoA server '$NAS->{NAS_MNG_IP_PORT}'";
    return 1;
  }

  return $result;
}

#**********************************************************
=head2 shape_speed($ci_speed)

=cut
#**********************************************************
sub shape_speed {
  my ($cl_speed) = @_;

  my $shapper_type = ($cl_speed > 4048) ? 'rate-limit' : 'shape';
  my $cir          = $cl_speed * 1024;
  my $nburst       = int($cir * 1.5 / 8);
  my $eburst       = 2 * $nburst;

  my $sp_param = $shapper_type . ' ' . $cir . ' ' . $nburst . ' ' . $eburst;

  return $sp_param;
}
