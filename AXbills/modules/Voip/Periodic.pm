=head1 NAME

  Voip Periodic

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(days_in_month in_array sendmail sec2time);
use Voip;
use Voip::Users;

our(
	$db,
	$admin,
	%conf,
	%ADMIN_REPORT,
	%lang,
);

our AXbills::HTML $html;

my $Voip     = Voip->new($db, $admin, \%conf);
my $Fees     = Fees->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Voip_users = Voip::Users->new($db, $admin, \%conf, {
	html => $html,
	lang => \%lang
});

#**********************************************************
=head2 voip_daily_fees($attr) daily_fees

=cut
#**********************************************************
sub voip_daily_fees {
	my ($attr) = @_;

	my $debug = $attr->{DEBUG} || 0;
	my $debug_output = '';
	$debug_output .= "Voip: Daily periodic\n" if ($debug > 1);

	$LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});
	my %VOIP_LIST_PARAMS = ();
	$VOIP_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
	$VOIP_LIST_PARAMS{EXT_BILL} = 1 if ($conf{BONUS_EXT_FUNCTIONS});

	$ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
	#my ($y, $m, $d) = split( /-/, $ADMIN_REPORT{DATE}, 3 );

	if($debug > 5) {
		$Tariffs->{debug}=1;
		$Voip->{debug}=1;
	}

	my $FEES_METHODS = get_fees_types({ SHORT => 1 });
	my $tp_list = $Tariffs->list({
		%LIST_PARAMS,
		MODULE    => 'Voip',
		COLS_NAME => 1
	});

	foreach my $tp ( @{$tp_list} ){
		my $TP_ID = $tp->{id};
		my $postpaid = $tp->{payment_type} || $tp->{postpaid_daily_fee};
		my $daily_fee = $tp->{day_fee};

		$debug_output .= "TP ID: $tp->{id} DF: $daily_fee POSTPAID: $postpaid\n" if ($debug > 1);
		if ( $daily_fee > 0 ){
			my $ulist = $Voip->user_list({
				ACTIVATE       => "<=$DATE",
				EXPIRE         => "0000-00-00,>$DATE",
				VOIP_EXPIRE    => "0000-00-00,>$DATE",
				LOGIN          => '_SHOW',
				SERVICE_STATUS => '0',
				LOGIN_STATUS   => 0,
				TP_ID          => $tp->{tp_id},
				COLS_NAME      => 1,
				REDUCTION      => '_SHOW',
				BILL_ID        => '_SHOW',
				DEPOSIT        => '_SHOW',
				CREDIT         => '_SHOW',
				STATUS         => '_SHOW',
				COLS_UPPER     => 1
			});

			foreach my $u ( @{$ulist} ){
				$debug_output .= " Login: $u->{LOGIN} ($u->{UID}) REDUCTION: $u->{REDUCTION} DEPOSIT: $u->{DEPOSIT} CREDIT $u->{CREDIT} ACTIVE: $u->{ACTIVATE}\n" if ($debug > 3);

				if ( $postpaid || ($u->{DEPOSIT} + $u->{CREDIT} > 0)){
					my %FEES_DSC = (
						MODULE          => 'Voip',
						SERVICE_NAME    => 'Voip',
						TP_NUM          => $tp->{id},
						TP_ID           => $tp->{tp_id},
						TP_NAME         => $tp->{name},
						FEES_PERIOD_DAY => $lang{DAY_FEE_SHORT},
						FEES_METHOD     => $FEES_METHODS->{$tp->{fees_method}},
					);

					my %FEES_PARAMS = (
						DESCRIBE => fees_dsc_former(\%FEES_DSC),
						DATE     => "$ADMIN_REPORT{DATE} $TIME",
						METHOD   => $tp->{fees_method} || 1
					);

					$Fees->take( $u, $daily_fee, \%FEES_PARAMS);
				}
			}
		}
	}

	my $users_list = $Voip->user_list({
		ACTIVATE                => "<=$DATE",
		EXPIRE                  => "0000-00-00,>$DATE",
		VOIP_EXPIRE             => "0000-00-00,>$DATE",
		SERVICE_STATUS          => 0,
		LOGIN_STATUS            => 0,
		LOGIN                   => '_SHOW',
		BILL_ID                 => '_SHOW',
		DEPOSIT                 => '_SHOW',
		CREDIT                  => '_SHOW',
		UID                     => '_SHOW',
		%VOIP_LIST_PARAMS,
		EXTRA_NUMBER            => '<>',
		EXTRA_NUMBERS_DAY_FEE => '>0',
		PAGE_ROWS               => 100000,
		COLS_NAME               => 1,
		COLS_UPPER              => 1
	});

	foreach my $user_info (@$users_list) {
		$Fees->take(
			$user_info,
			$user_info->{EXTRA_NUMBERS_DAY_FEE},
			{
				DESCRIBE => "$lang{ACTIVATE}: $user_info->{EXTRA_NUMBER}",
				DATE     => $ADMIN_REPORT{DATE},
			}
		);

		if ($Fees->{errno}) {
			print "ERROR: $Fees->{errno} $Fees->{errstr}\n";
		}

		if ($debug > 2) {
			$debug_output .= "MAIN_NUMBER: $user_info->{LOGIN} EXTRA_NUMBER: $user_info->{EXTRA_NUMBER} SUM: $user_info->{EXTRA_NUMBERS_DAY_FEE}\n";
			exit;
		}
	}

	$DEBUG .= $debug_output;
	return $debug_output;
}

#**********************************************************
=head2 voip_monthly_fees($attr) - monthly_fees

=cut
#**********************************************************
sub voip_monthly_fees {
	my ($attr) = @_;

	my $debug = $attr->{DEBUG} || 0;
	my $debug_output = '';
	$debug_output .= "Voip: Monthly periodic payments\n" if ($debug > 1);

	use Users;
	my $users = Users->new($db, $admin, \%conf);

	$LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});
	my %VOIP_LIST_PARAMS = ();
	$VOIP_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
	$VOIP_LIST_PARAMS{EXT_BILL} = 1 if ($conf{BONUS_EXT_FUNCTIONS});

	$ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
	my ($y, $m, $d) = split(/-/, $ADMIN_REPORT{DATE}, 3);

	if ($debug > 6) {
		$Voip->{debug} = 1;
	}

	my $FEES_METHODS = get_fees_types({ SHORT => 1 });
	my $list = $Tariffs->list({
		%LIST_PARAMS,
		MODULE     => 'Voip',
		COLS_NAME  => 1,
		COLS_UPPER => 1
	});
	my $date_unixtime = POSIX::mktime(0, 0, 0, $d, ($m - 1), $y - 1900, 0, 0, 0);

	foreach my $TP_INFO (@{$list}) {
		$TP_INFO->{POSTPAID} = $TP_INFO->{PAYMENT_TYPE} || $TP_INFO->{POSTPAID_MONTHLY_FEE};
		$debug_output .= "TP ID: $TP_INFO->{TP_ID} MF: $TP_INFO->{MONTH_FEE} POSTPAID: $TP_INFO->{POSTPAID}\n" if ($debug > 1);

		if ($TP_INFO->{MONTH_FEE} > 0) {
			my $ulist = $Voip->user_list({
				ACTIVATE       => "<=$DATE",
				EXPIRE         => "0000-00-00,>$DATE",
				VOIP_EXPIRE    => "0000-00-00,>$DATE",
				SERVICE_STATUS => '0;2',
				LOGIN_STATUS   => 0,
				TP_ID          => $TP_INFO->{TP_ID},
				PAGE_ROWS      => 10000000,
				COLS_NAME      => 1,
				REDUCTION      => '_SHOW',
				BILL_ID        => '_SHOW',
				ACTIVATE       => '_SHOW',
				DEPOSIT        => '_SHOW',
				CREDIT         => '_SHOW',
				%VOIP_LIST_PARAMS,
				COLS_UPPER     => 1
			});

			foreach my $user (@{$ulist}) {
				$debug_output .= " Login: $user->{LOGIN} ($user->{UID}) REDUCTION: $user->{REDUCTION} DEPOSIT: $user->{deposit} CREDIT $user->{CREDIT} ACTIVE: $user->{ACTIVATE}\n" if ($debug > 3);

				my %FEES_DSC = (
					MODULE          => 'Voip',
					SERVICE_NAME    => 'Voip',
					TP_NUM          => $TP_INFO->{ID},
					TP_ID           => $TP_INFO->{TP_ID},
					TP_NAME         => $TP_INFO->{NAME},
					FEES_PERIOD_DAY => $lang{MONTH_FEE_SHORT},
					FEES_METHOD     => $FEES_METHODS->{$TP_INFO->{FEES_METHOD}},
				);

				my %FEES_PARAMS = (
					DESCRIBE => fees_dsc_former(\%FEES_DSC),
					DATE     => $ADMIN_REPORT{DATE},
					METHOD   => $TP_INFO->{FEES_METHOD} || 1
				);

				if ($user->{ACTIVATE} eq '0000-00-00' and $d == 1) {
					if ($TP_INFO->{POSTPAID} || $user->{DEPOSIT} + $user->{CREDIT} > 0) {
						$Fees->take($user, $TP_INFO->{MONTH_FEE}, \%FEES_PARAMS);
					}
					elsif ($conf{VOIP_ONEMONTH_INCOMMING_ALLOW}) {
						my $change_status = ($user->{VOIP_STATUS} == 0) ? 2 : 1;
						$Voip->user_change({ UID => $user->{UID}, DISABLE => $change_status });
						$debug_output .= " CHANGE STATUS: $user->{VOIP_STATUS} -> $change_status\n" if ($debug > 3);
					}
				}
				elsif ($user->{ACTIVATE} ne '0000-00-00') {
					if ($TP_INFO->{POSTPAID} || $user->{DEPOSIT} + $user->{CREDIT} > 0) {
						my ($activate_y, $activate_m, $activate_d) = split(/-/, $user->{ACTIVATE}, 3);
						my $active_unixtime = POSIX::mktime(0, 0, 0, $activate_d, ($activate_m - 1), $activate_y - 1900, 0, 0, 0);

						if ($date_unixtime - $active_unixtime > 30 * 86400) {
							$Fees->take($user, $TP_INFO->{MONTH_FEE}, \%FEES_PARAMS);
							$users->change($user->{UID}, { ACTIVATE => $DATE, UID => $user->{UID} });
						}
					}
					elsif ($conf{VOIP_ONEMONTH_INCOMMING_ALLOW}) {
						my $change_status = ($user->{VOIP_STATUS} == 0) ? 2 : 1;
						$Voip->user_change({ UID => $user->{UID}, DISABLE => $change_status });
						$debug_output .= " CHANGE STATUS: $user->{VOIP_STATUS} -> $change_status\n" if ($debug > 3);
					}
				}
			}
		}
	}

	if ($d == 1) {
		my $users_list = $Voip->user_list({
			ACTIVATE                => "<=$DATE",
			EXPIRE                  => "0000-00-00,>$DATE",
			VOIP_EXPIRE             => "0000-00-00,>$DATE",
			SERVICE_STATUS          => 0,
			LOGIN_STATUS            => 0,
			BILL_ID                 => '_SHOW',
			DEPOSIT                 => '_SHOW',
			CREDIT                  => '_SHOW',
			UID                     => '_SHOW',
			%VOIP_LIST_PARAMS,
			EXTRA_NUMBER            => '<>',
			EXTRA_NUMBERS_MONTH_FEE => '>0',
			PAGE_ROWS               => 100000,
			COLS_NAME               => 1,
			COLS_UPPER              => 1
		});

		foreach my $user_info (@$users_list) {
			$Fees->take(
				$user_info,
				$user_info->{EXTRA_NUMBERS_MONTH_FEE},
				{
					DESCRIBE => "$lang{ACTIVATE}: $user_info->{EXTRA_NUMBER}",
					DATE     => $ADMIN_REPORT{DATE},
				}
			);

			if ($Fees->{errno}) {
				print "ERROR: $Fees->{errno} $Fees->{errstr}\n";
			}

			if ($debug > 2) {
				$debug_output .= "MAIN_NUMBER: $user_info->{LOGIN} EXTRA_NUMBER: $user_info->{EXTRA_NUMBER} SUM: $user_info->{EXTRA_NUMBERS_MONTH_FEE}\n";
			}
		}
	}

	$DEBUG .= $debug_output;
	return $debug_output;
}

#**********************************************************
=head2 voip_users_warning_messages()

=cut
#**********************************************************
sub voip_users_warning_messages {

	my %LIST_PARAMS = (USERS_WARNINGS => 'y');
	my $list = $Voip->user_list( { %LIST_PARAMS } );

	$ADMIN_REPORT{USERS_WARNINGS} = sprintf( "%-14s| %4s|%-20s| %9s| %8s|\n", $lang{LOGIN}, 'TP', $lang{TARIF_PLAN},
		$lang{DEPOSIT},
		$lang{CREDIT} ) . "---------------------------------------------------------------\n";
	return 0 if ($Voip->{TOTAL} < 1);
	my %USER_INFO = ();

	foreach my $line ( @{$list} ){
		$USER_INFO{LOGIN} = $line->[0];
		$USER_INFO{TP_NAME} = $line->[5];
		$USER_INFO{TP_ID} = $line->[2];
		$USER_INFO{DEPOSIT} = $line->[4];
		$USER_INFO{CREDIT} = $line->[3];

		my $email = ((!defined( $line->[1] )) || $line->[1] eq '') ? (($conf{USERS_MAIL_DOMAIN}) ? "$line->[0]\@$conf{USERS_MAIL_DOMAIN}" : '') : "$line->[1]";

		if ($email eq '') {
			next;
		}

		$ADMIN_REPORT{USERS_WARNINGS} .= sprintf( "%-14s| %4d|%-20s| %9.4f| %8.2f|\n", $USER_INFO{LOGIN}, $USER_INFO{TP_ID},
			$USER_INFO{TP_NAME}, $USER_INFO{DEPOSIT}, $USER_INFO{CREDIT} );

		my $message = $html->tpl_show( _include( 'voip_users_warning_messages', 'Dv' ), \%USER_INFO, { notprint => 'yes' } );

		#TODO: fix text was unreadable text
		sendmail("$conf{ADMIN_MAIL}", "$email", "Voip warnings", "$message", "$conf{MAIL_CHARSET}", "2 (High)" );
	}

	$ADMIN_REPORT{USERS_WARNINGS} .= "---------------------------------------------------------------
$lang{TOTAL}: $Voip->{TOTAL}\n";

	return 1;
}

#***********************************************************
=head2 internet_sheduler($type, $action, $uid, $attr)

  Arguments:
    $type
    $action
    $uid
    $attr

  Returns:
    TRUE or FALSE

=cut
#***********************************************************
sub voip_sheduler {
	my ($type, $action, $uid, $attr) = @_;

	my $debug = $attr->{DEBUG} || 0;

	$Voip->user_info($uid);
	if ($type eq 'tp') {
		(undef, $action) = split(':', $action) if ($action && $action =~ /:/);
		$Voip->user_change({
			UID   => $uid,
			TP_ID => $action
		});

		if ($attr->{GET_ABON} && $attr->{GET_ABON} eq '-1' && $attr->{RECALCULATE} && $attr->{RECALCULATE} eq '-1') {
			print "Skip: GET_ABON, RECALCULATE\n" if ($debug > 1);
			return 0;
		}

		if ($Voip->{errno}) {
			return $Voip->{errno};
		}
		else {
			my $START_PERIOD_DAY = $conf{START_PERIOD_DAY} || 1;
			my $d  = (split(/-/, $ADMIN_REPORT{DATE}, 3))[2];

			if ($Voip->{TP_INFO}->{ABON_DISTRIBUTION} || $d == $START_PERIOD_DAY) {
				$Voip->{TP_INFO}->{MONTH_FEE} = 0;
			}

			$user = undef;
			$FORM{RECALCULATE} = 1 if ($attr->{RECALCULATE});
			service_get_month_fee($Voip, {
				QUITE        => 1,
				SHEDULER     => 1,
				SERVICE_NAME => 'Voip',
				DATE         => $attr->{DATE}
			});

			if ($conf{VOIP_ASTERISK_USERS}) {
				$Voip_users->voip_mk_users_conf({});
			}
		}
	}

	return 1;
}

1;
