=head1 NAME

 Internet turbo control

=cut

our (
	$argv,
	$db,
	$Admin,
	$debug,
	%conf,
);

our Nas $Nas;

turbo_control();

#***********************************************************
=head2 turbo_control()

=cut
#***********************************************************
sub turbo_control {

	require Turbo;
	Turbo->import();
	require AXbills::Nas::Control;
	AXbills::Nas::Control->import();
	my $Turbo = Turbo->new($db, $Admin, \%conf);
	my $Nas_cmd = AXbills::Nas::Control->new( $db, \%conf );

	if($debug > 6) {
		$Turbo->{debug}=1;
	}

	my $turbo_list = $Turbo->list({
		ONLINE              => 1,
		ONLINE_DURATION_SEC => '_SHOW',
		TURBO_END           => '_SHOW',
		ONLINE_START        => '_SHOW',
		CLIENT_IP           => '_SHOW',
		ACCT_SESSION_ID     => '_SHOW',
		NAS_ID              => '_SHOW',
		COLS_NAME           => 1
	});

	foreach my $session (@$turbo_list) {
		if ($debug > 3) {
			print "LOGIN: $session->{login} LAST_TIME: $session->{last_time} ONLINE_DURATION: $session->{online_duration_sec}"
				. "TURBO_END: $session->{turbo_end} ONLINE_START: $session->{online_start}\n";
		}

		if($session->{online_start} < $session->{turbo_end}) {
      print "HANGUP: $session->{login} SESSION_ID: $session->{acct_session_id}\n" if ($debug > 0);
			$Nas->info({ NAS_ID => $session->{nas_id} });
			$Nas_cmd->hangup($Nas,
				'',
				$session->{login},
				{
					ACCT_SESSION_ID   => $session->{acct_session_id},
					FRAMED_IP_ADDRESS => $session->{client_ip},
					debug             => $debug,
				}
			);
	  }
	}

	return 1;
}