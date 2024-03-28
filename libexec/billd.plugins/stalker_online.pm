# billd plugin
=head1 NAME

  DESCRIBE:
    Add active users to online list
    hangup debetors
    block debetors

=head1 OPTIONS

  SERVICE_ID

=cut
#**********************************************************


use warnings FATAL => 'all';
use strict;
use AXbills::Base qw(mk_unique_value show_hash);
use POSIX;
use Iptv;
use Tariffs;
use Users;
use Shedule;

our (
  $argv,
  $db,
  $Admin,
  $Internet,
  %conf,
  $var_dir,
  $debug,
  $nas,
  %lang,
  $base_dir
);

my $main_file = $base_dir . '/language/english.pl';
require $main_file;

our $Iptv = Iptv->new($db, $Admin, \%conf);
require Iptv::Services;

stalker_online();


#**********************************************************
=head2 stalker_online($attr)

=cut
#**********************************************************
sub stalker_online {

  my %PARAMS = ();

  if ($argv->{SERVICE_ID}) {
    $PARAMS{ID} = $argv->{SERVICE_ID};
  }

  my $service_list = $Iptv->services_list({
    NAME      => '_SHOW',
    LOGIN     => '_SHOW',
    PASSOWRD  => '_SHOW',
    MODULE    => 'Stalker_api',
    COLS_NAME => 1,
    %PARAMS
  });

  foreach my $service (@$service_list) {
    if ($debug > 3) {
      print "Service ID: $service->{id} NAME: $service->{name}\n";
    }

    my $Stalker_api = tv_load_service('', { SERVICE_ID => $service->{id} });
    if ($argv->{BALANCE}) {
      stalker_balance($Stalker_api);
    }
    else {
      stalker_online_check($Stalker_api);
    }
  }

  return 1;
}

#**********************************************************
=head2 stalker_online_check($attr)

=cut
#**********************************************************
sub stalker_online_check {
  my $Stalker_api = shift;

  my $Tariffs = Tariffs->new($db, \%conf, $Admin);
  my $Shedule = Shedule->new($db, $Admin);
  my $Log = Log->new($db, $Admin);

  if ($debug > 2) {
    $Log->{PRINT} = 1;
  }
  # else {
    # $Log->{LOG_FILE} = $var_dir . '/log/stalker_online.log';
  # }
  elsif ($argv->{LOG_FILE} && $argv->{LOG_FILE} eq '1')
  {
	$Log->{LOG_FILE} = $var_dir . '/log/stalker_online.log';
	}

  my %hangup_desr = ();
  print "Stalker STB online\n" if ($debug > 1);

  if ($debug > 7) {
    $nas->{debug} = 1;
    $Internet->{debug} = 1;
    $Stalker_api->{DEBUG} = 1;
  }

  $Admin->{MODULE} = 'Iptv';
  #Get tp
  my %TP_INFO = ();
  my $list = $Tariffs->list({
    AGE             => '_SHOW',
    NEXT_TARIF_PLAN => '_SHOW',
    COLS_NAME       => 1,
    COLS_UPPER      => 1
  });

  foreach my $line (@$list) {
    $TP_INFO{$line->{TP_ID}} = $line;
  }

  $LIST_PARAMS{LOGIN} = $argv->{LOGINS} if ($argv->{LOGINS});

  # Get accounts
  my %USERS_LIST = ();
  $Iptv->{debug} = 1 if ($debug > 6);
  $list = $Iptv->user_list({
    COLS_NAME       => 1,
    LOGIN           => '_SHOW',
    CID             => '_SHOW',
    ACTIVATE        => '_SHOW',
    EXPIRE          => '_SHOW',
    LOGIN_STATUS    => '_SHOW',
    SERVICE_STATUS  => '_SHOW',
    NEXT_TARIF_PLAN => '_SHOW',
    IPTV_EXPIRE     => '_SHOW',
    TP_ID           => '_SHOW',
    CREDIT          => '_SHOW',
    DEPOSIT         => '_SHOW',
    ID              => '_SHOW',
    %LIST_PARAMS,
    PAGE_ROWS       => 1000000,
  });

  foreach my $line (@$list) {
    $line->{cid} =~ s/[\n\r ]//g;
    foreach my $cid (split(/;/, $line->{cid})) {
      $USERS_LIST{$cid} = $line;
    }
  }

  my %USERS_ONLINE_LIST = ();
  $Iptv->{debug} = 1 if ($debug > 6);
  $list = $Iptv->online({
    COLS_NAME       => 1,
    CID             => '_SHOW',
    UID             => '_SHOW',
    ACCT_SESSION_ID => '_SHOW',
    FIO             => '_SHOW',
    ID              => '_SHOW',
  });

  foreach my $line (@$list) {
    if (!$line->{id}) {
      print "ID no defined for UID: " . ($line->{uid} || 0) . " CID: " . ($line->{CID} || q{N/D}) . "\n";
      $line->{id} //= 0;
    }

    if ($debug > 2) {
      print "$line->{CID} -> ". ($line->{uid} || 'NO_UID' ).":"
        . ($line->{id} || 'NO_ID') .":"
        . ($line->{acct_session_id} || 'NO_SESSION_ID') ."\n";
    }

    if (!$line->{uid}) {
      if ($debug > 0) {
        print "Skip user: No uid, sid: $line->{acct_session_id}\n";
      }
      #next;
    }

    $USERS_ONLINE_LIST{$line->{CID}} = ($line->{uid} || 0) . ":" . ($line->{id} || '0') . ":$line->{acct_session_id}"; #\n";
  }

  #Get stalker info
  $Stalker_api->_send_request({
    ACTION => "stb",
    DEBUG  => ($debug > 6) ? $debug : undef
  });

  if ($Stalker_api->{error}) {
	  if ($argv->{LOG_PRINT} && $argv->{LOG_PRINT} eq '1') {
    $Log->log_print('LOG_ERR', '', "Stalker error: $Stalker_api->{error}/$Stalker_api->{errstr}");
	  }
    return 0;
  }

  foreach my $stalker_account_info (@{$Stalker_api->{RESULT}->{results}}) {
    my @row = ();
    while (my (undef, $val) = each %{$stalker_account_info}) {
      Encode::_utf8_off($stalker_account_info->{name}) if ($stalker_account_info->{name});

      if (ref $val eq 'ARRAY') {
        my $col_values = '';
        foreach my $v (@$val) {
          if (ref $v eq 'HASH') {
            while (my ($k, $v2) = each %$v) {
              $col_values .= " $k - $v2\n";
            }
          }
          else {
            $col_values .= $v . "\n";
          }
        }

        push @row, $col_values;
      }
      elsif (ref $val eq 'HASH') {
        my $col_values = '';
        while (my ($k, $v) = each %$val) {
          $col_values .= " $k - $v\n";
        }
        push @row, $col_values;
      }
      else {
        push @row, $val;
      }
    }
	if ($argv->{LOG_PRINT} && $argv->{LOG_PRINT} eq '1') {
    $Log->log_print('LOG_DEBUG', '', "Stalker ls: $stalker_account_info->{ls} IP: $stalker_account_info->{ip} MAC: $stalker_account_info->{mac} Online: $stalker_account_info->{online} Status: $stalker_account_info->{status}");
	}
	
    if (!$stalker_account_info->{online}) {
      my $user = $USERS_LIST{$stalker_account_info->{mac}};
      $hangup_desr{$user->{id}} = 'User log off' if ($user->{id});
      if ($debug > 2) {
        print "To hangup: MAC: " . ($stalker_account_info->{mac} || 'NO_MAC')
          . ' ACCOUNT_NUMBER: ' . ($stalker_account_info->{account_number} || q{})
          #   . ' STB_SN: ' . ($stalker_account_info->{stb_sn} || q{})
        ;

        if ($user) {
          print show_hash($user);
        }
        else {
          print " No user info";
        }
        print "\n";
      }
      next;
    }

    #block with negative deposite
    #Hangup modem
    if (!$stalker_account_info->{mac}) {
      #$Stalker_api->send_request({ ACTION => "STB",
      #                     });
      print "SKIP: No MAC STB_SN: $stalker_account_info->{stb_sn}\n" if ($debug > 1);
    }
    elsif (!$USERS_LIST{$stalker_account_info->{mac}}) {
		if ($argv->{LOG_PRINT} && $argv->{LOG_PRINT} eq '1') {
      $Log->log_print('LOG_WARNING', '', "UNKNOWN MAC: '$stalker_account_info->{mac}' add mac to account '$stalker_account_info->{login}'");
		}
      #Add mac to account
      if ($stalker_account_info->{login}) {
        my $u_list = $Iptv->user_list({ LOGIN => "$stalker_account_info->{login}", COLS_NAME => 1 });

        if ($Iptv->{TOTAL}) {
          $Iptv->user_change({
            ID  => $u_list->[0]->{id},
            CID => $stalker_account_info->{mac}
          });

          print " ADDED" if ($debug > 1);
        }
        else {
          print "LOGIN: $stalker_account_info->{login} MAC: $stalker_account_info->{mac} Not exist in billing" if ($debug > 1);
        }
      }
      print "\n" if ($debug > 1);
    }
    # Update online
    elsif ($USERS_ONLINE_LIST{$stalker_account_info->{mac}}) {
		if ($argv->{LOG_PRINT} && $argv->{LOG_PRINT} eq '1') {
      $Log->log_print('LOG_DEBUG', '', "UPDATE online: $USERS_ONLINE_LIST{$stalker_account_info->{mac}} mac: $stalker_account_info->{mac}");
		}
		
      my $user = $USERS_LIST{$stalker_account_info->{mac}};
      my $expire_unixdate = 0;
      if($user) {
        if ($user->{expire} ne '0000-00-00') {
          my ($expire_y, $expire_m, $expire_d) = split(/\-/, $user->{expire}, 3);
          $expire_unixdate = mktime(0, 0, 0, $expire_d, ($expire_m - 1), ($expire_y - 1900));
          $expire_unixdate = ($expire_unixdate < time) ? 1 : 0;
        }
        elsif ($user->{iptv_expire} ne '0000-00-00') {
          my ($expire_y, $expire_m, $expire_d) = split(/\-/, $user->{iptv_expire}, 3);
          $expire_unixdate = mktime(0, 0, 0, $expire_d, ($expire_m - 1), ($expire_y - 1900));
          $expire_unixdate = ($expire_unixdate < time) ? 1 : 0;
        }
      }
      else {
        print "ERROR NO USER: $stalker_account_info->{mac} // $user \n";
      }

      my $credit = ($user->{credit} > 0) ? $user->{credit} : $TP_INFO{$user->{tp_id}}->{CREDIT};

      #Neg deposit
      if (($TP_INFO{$user->{tp_id}}->{PAYMENT_TYPE} == 0 && $user->{deposit} + $credit <= 0)
        || $user->{login_status}
        || $user->{iptv_status}
        || $expire_unixdate
      ) {
        $hangup_desr{$user->{uid}} = "NEG_DEPOSIT " . sprintf("%.2f Credit: %.2f", $user->{deposit}, $credit);
        if ($stalker_account_info->{status} == 0) {
          delete($USERS_ONLINE_LIST{$stalker_account_info->{mac}});
          next;
        }
        $Admin->action_add($user->{uid}, $stalker_account_info->{mac}, { TYPE => 15 });

        print "Disable STB LOGIN: $user->{login} ID: $user->{id}"
          . " MAC: $stalker_account_info->{mac} ACCOUNT_NUMBER: " . ($stalker_account_info->{account_number} || 'n/d')
          . " STALKER: $stalker_account_info->{login}"
          . " Expire: $expire_unixdate "
          . " DEPOSIT: $user->{deposit}+$credit STATUS: $user->{login_status}/$user->{service_status}\n";

        if (!$conf{IPTV_STALKER_SINGLE_ACCOUNT} && $user->{login} && $user->{id}) {
          $user->{login} = $user->{id} . '_' . $user->{id};
        }

        my $login = $stalker_account_info->{login} || $user->{login};
        my $id = $stalker_account_info->{ls} || $user->{id};

        $Stalker_api->user_action({
          ID     => $id,
          FIO    => $user->{fio},
          LOGIN  => $login,
          STATUS => 1,
          change => 1
        });

        if ($Stalker_api->{errno}) {
          print "ERROR: Disable STB LOGIN: $user->{login} [$Stalker_api->{errno}] $Stalker_api->{errstr}\n";
        }
      }
      else {
        my ($uid, $id, $acct_session_id) = split(/:/, $USERS_ONLINE_LIST{$stalker_account_info->{mac}});

        if (! $uid ) {
          $uid ||= $user->{uid};
          $id ||= $user->{id};
          $USERS_ONLINE_LIST{$stalker_account_info->{mac}}="$uid:$id:$acct_session_id";
          next;
        }

        $Iptv->online_update({
          ACCT_SESSION_ID => $acct_session_id,
          UID             => $uid || $user->{uid},
          ID              => $id || $user->{id},
          CID             => $stalker_account_info->{mac},
          GUEST           => ($stalker_account_info->{status} == 0) ? 1 : 0
        });

        if ($user->{login} && $user->{id}) {
          $user->{login} = $user->{id} . '_' . $user->{id};
        }

        if ($stalker_account_info->{status} == 0) {
          $Stalker_api->{debug} = 1;
          $Stalker_api->user_action({
            ID     => $user->{id},
            FIO    => $user->{fio},
            #LOGIN  => $user->{login},
            STATUS => 0,
            change => 1
          });

          print "Enable STB LOGIN: $user->{login} MAC: $stalker_account_info->{mac} Expire: $expire_unixdate DEPOSIT: $user->{deposit}+$credit STATUS: $user->{login_status}/$user->{service_status}\n";
        }

        delete $USERS_ONLINE_LIST{$stalker_account_info->{mac}};
      }
    }
    #add online
    else {
      my $user = $USERS_LIST{$stalker_account_info->{mac}};

      if (!$user->{tp_id}) {
		  if ($argv->{LOG_PRINT} && $argv->{LOG_PRINT} eq '1') {
        $Log->log_print('LOG_WARNING', $USERS_LIST{$stalker_account_info->{mac}}->{login}, "ADD online: MAC: $stalker_account_info->{mac} Unknown TP");
	  }}
      else {
        $Iptv->online_add({
          UID             => $user->{uid},
          ID              => $user->{id},
          IP              => $stalker_account_info->{ip} || '0.0.0.0',
          NAS_ID          => 0,
          STATUS          => 1,
          TP_ID           => $user->{tp_id},
          CID             => $stalker_account_info->{mac},
          ACCT_SESSION_ID => mk_unique_value(12),
          GUEST           => ($stalker_account_info->{status} == 0) ? 1 : 0
        });
		if ($argv->{LOG_PRINT} && $argv->{LOG_PRINT} eq '1') {
        $Log->log_print('LOG_NOTICE', $user->{login}, "ADD online: MAC: $stalker_account_info->{mac} Online: $stalker_account_info->{online}");
		}

        if ($TP_INFO{$user->{tp_id}}->{AGE} && $user->{expire} eq '0000-00-00') {
          my $expire_date = POSIX::strftime("%Y-%m-%d", localtime(time + $TP_INFO{$user->{tp_id}}->{AGE} * 86400));
		if ($argv->{LOG_PRINT} && $argv->{LOG_PRINT} eq '1') {
          $Log->log_print('LOG_DEBUG', $user->{login}, "ADD EXPIRE: $expire_date TP_AGE: $TP_INFO{$user->{tp_id}}->{AGE}");
		}

          if ($TP_INFO{$user->{tp_id}}->{NEXT_TP_ID}) {
            my ($year, $month, $day) = split(/\-/, $expire_date, 3);

            print "
            UID          => $user->{uid},
              TYPE         => 'tp',
              ACTION       => $user->{tp_id}:$user->{id},
              D            => $day,
              M            => $month,
              Y            => $year,
              COMMENTS     => $lang{FROM}: $user->{tp_id}:$user->{TP_NAME},
              ADMIN_ACTION => 1,
              MODULE       => 'Iptv'
              ";

            $Shedule->add({
              UID          => $user->{uid},
              TYPE         => 'tp',
              ACTION       => "$user->{tp_id}:$user->{id}",
              D            => $day,
              M            => $month,
              Y            => $year,
              COMMENTS     => "$lang{FROM}: $user->{tp_id}:$user->{TP_NAME}",
              ADMIN_ACTION => 1,
              MODULE       => 'Iptv'
            });
          }
          else {
            $Iptv->user_change({
              ID     => $user->{id},
              #              UID    => $user->{uid},
              EXPIRE => $expire_date,
            });
          }
        }
      }
    }

    print join('; ', @row) . "\n" if ($debug > 5);
  }

  #Del old sessions
  if (scalar %USERS_ONLINE_LIST) {
    my $del_list = join(',', keys %USERS_ONLINE_LIST);
    $Iptv->online_del({ CID => [ keys %USERS_ONLINE_LIST ] });
	if ($argv->{LOG_PRINT} && $argv->{LOG_PRINT} eq '1') {
    $Log->log_print('LOG_DEBUG', undef, "Delete: $del_list");
	}

    foreach my $mac (keys %USERS_ONLINE_LIST) {
      my ($uid, $id, $acct_session_id) = split(/:/, $USERS_ONLINE_LIST{$mac});
      #Hangup stb box
      $Stalker_api->hangup({ ID => $id });
      # $Stalker_api->_send_request({
      #   ACTION => "send_event/" . $id,
      #   event  => 'cut_off',
      # });

      #Disable account
      #$Stalker_api->user_action({ UID    => $uid,
      #                            FIO    => $user->{fio},
      #                            LOGIN  => $user->{login},
      #                            STATUS => 1,
      #                            change => 1 });

      if ($Stalker_api->{errno}) {
		  if ($argv->{LOG_PRINT} && $argv->{LOG_PRINT} eq '1') {
        $Log->log_print('LOG_ERR', $uid, "HANGUP STB LOGIN: UID: $uid STB ID: $id MAC: $mac SESSION_ID: $acct_session_id [$Stalker_api->{errno}] $Stalker_api->{errstr}");
        print "ERROR: HANGUP STB LOGIN: " . ($user->{login} || q{-}) . "UID: $uid STB ID: $id MAC: $mac [$Stalker_api->{errno}] $Stalker_api->{errstr}\n";
      } 
      else {
		  if ($argv->{LOG_PRINT} && $argv->{LOG_PRINT} eq '1') {
        $Log->log_print('LOG_INFO', $uid, "Hangup: $mac ("
          . (($uid && $hangup_desr{$uid}) ? $hangup_desr{$uid} : $uid || q{--})
          . ") Session: " . ($acct_session_id || 'No session ID')
          . "ID: $id");
			}
		}
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 stalker_balance($attr)

=cut
#**********************************************************
sub stalker_balance {
  my $Stalker_api = shift;

  my $users = $Stalker_api->get_users();
  my $user_deposit = "";
  require Users;
  Users->import();

  my $Users = Users->new($db, $Admin, \%conf);

  foreach my $user ($users->{RESULT}{results}){
    foreach my $some_user (@$user) {
      if ($some_user->{account_number}) {
        my $Iptv_user = $Iptv->user_list({
          ID         => $some_user->{account_number},
          LOGIN      => '_SHOW',
          SERVICE_ID => '_SHOW',
          UID        => '_SHOW',
          COLS_NAME  => 1,
          PAGE_ROWS  => 99999,
        });
        $Iptv->services_list({
          ID        => $Iptv_user->[0]{service_id},
          NAME      => '_SHOW',
          MODULE    => 'Stalker_api',
          COLS_NAME => 1,
        });

        $user_deposit = $Users->info($Iptv_user->[0]{uid});
        if ($Iptv->{TOTAL}) {
          $Stalker_api->user_action({
            ID              => $some_user->{account_number},
            DEPOSIT         => $user_deposit->{DEPOSIT},
            change          => 1
          });
        }
      }
    }
  }

  return 1;
}


1
