=head1 NAME

  Turbo mode control

=cut


use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(cmd sec2time in_array);
use Internet;
use Fees;
use Nas;

our (
  $db,
  $admin,
  %conf,
  %lang,
  %permissions,
  $Sessions
);

our AXbills::HTML $html;
my $Internet = Internet->new($db, $admin, \%conf);
my $Fees     = Fees->new($db, $admin, \%conf);

#**********************************************************
=head2 internet_turbo_control($attr)

=cut
#**********************************************************
sub internet_turbo_control {
  my Internet $Internet_ = shift;
  if($Internet_->{TURBO_MODE}) {
    return 1;
  }
  elsif($Internet_->{STATUS}) {
    #$html->message('err', $lang{ERROR}, "$lang{SERVICE} $lang{DISABLED}");
    return 1;
  }

  $conf{INTERNET_TURBO_MODE} //= q{};
  $conf{INTERNET_TURBO_MODE} =~ s/\n//;

  my (@turbo_mods) = split(/;/, $conf{INTERNET_TURBO_MODE});
  my @turbo_mods_full = ();

  my $i = 1;
  my ($speed, $time, $price, $name, $bonus);

  foreach my $line (@turbo_mods) {
    ($speed, $time, $price, $name, $bonus) = split(/:/, $line, 5);

    if ($bonus && ! $Internet->{FREE_TURBO_MODE} ) {
      next;
    }

    push @turbo_mods_full, sprintf("$name\n $lang{SPEED}: $speed\n $lang{TIME}: %s\n $lang{PRICE}: %.2f %s",
      sec2time($time, { format => 1 }), $price, (($bonus) ? "($lang{BONUS})" : ''));

    if ($FORM{SPEED} && $FORM{SPEED} == $i) {
      $FORM{MODE_ID} = $i - 1;
      $FORM{SPEED}   = $speed;
      $FORM{TIME}    = $time;
      last;
    }
    $i++;
  }

  if (form_purchase_module({
    HEADER           => $user->{UID},
    MODULE           => 'Turbo',
    REQUIRE_VERSION  => 2.20
  })) {
    return 0;
  }

  my $Turbo = Turbo->new($db, $admin, \%conf);

  my $list = $Turbo->list({
    UID      => $LIST_PARAMS{UID},
    ACTIVE   => 1,
    GROUP_BY => q{}
  });

  if ($Turbo->{TOTAL} > 0 || $Internet_->{TURBO_MODE_RUN}) {
    my $last = $list->[0]->[2] || $Internet_->{TURBO_MODE_RUN} || 0;
    $html->message('info', $lang{INFO}, $html->b($turbo_mods_full[$list->[0]->[1] || 0]) . "\n $lang{TURBO} $lang{REMAIN} $lang{TIME}: $last sec.");
  }
  elsif ($FORM{change} && $FORM{SPEED}) {
    if ($user->{DEPOSIT} + $user->{CREDIT} > $price) {
      $Turbo->add({
        UID        => $LIST_PARAMS{UID},
        MODE_ID    => $FORM{SPEED} || $FORM{MODE_ID} || 0,
        SPEED      => int($FORM{SPEED} || 0),
        SPEED_TYPE => 0,
        TIME       => $FORM{TIME},
      });

      if (_error_show($Turbo, { SILENT_MODE => 1 })) {
        return 0;
      }

      if ($price > 0) {
        $Fees->take($user, $price, { DESCRIBE => "$lang{TURBO}: $Turbo->{INSERT_ID}" });
      }

      if ($bonus) {
        if ($Internet_->{FREE_TURBO_MODE} < 1) {
          $html->message('err', "$lang{ERROR}", "$lang{BONUS} $lang{TURBO} $lang{EXPIRE}");
          return 0;
        }
        else {
          $Internet_->user_change({
            UID             => $user->{UID},
            FREE_TURBO_MODE => ($Internet_->{FREE_TURBO_MODE}-1)
          });
        }
      }

      my $ip = $ENV{REMOTE_ADDR};

      # if($conf{INTERNET_TURBO_STATIC_IP}) {
      #   if(in_array('Dhcphosts', \@MODULES)) {
      #     require Dhcphosts;
      #     Dhcphosts->import();
      #     my $Dhcphosts = Dhcphosts->new($db, $admin, \%conf);
      #
      #     my $dhcp_list = $Dhcphosts->hosts_list({
      #       UID       => $Internet_->{UID},
      #       IP        => '_SHOW',
      #       PAGE_ROWS => 1,
      #       COLS_NAME => 1
      #     });
      #
      #     if($Dhcphosts->{TOTAL}) {
      #       $ip = $dhcp_list->[0]->{ip};
      #     }
      #   }
      #
      #   if ($Internet_->{IP} && $Internet_->{IP} ne '0.0.0.0') {
      #     $ip = $Internet_->{IP};
      #   }
      # }

      my %online_info = ();

      require Internet::Sessions;
      Internet::Sessions->import();
      $Sessions = Internet::Sessions->new($db, $admin, \%conf);

      my $sessions_list = $Sessions->online({
        UID        => $user->{UID},
        NAS_ID    => '_SHOW',
        COLS_NAME => 1
      });

      if ($Sessions->{TOTAL}) {
        $online_info{ACCT_SESSION_ID}= $sessions_list->[0]->{acct_session_id};
        $online_info{NAS_ID}         = $sessions_list->[0]->{nas_id};

        my $Nas = Nas->new($db, \%conf);

        $Nas->info({ NAS_ID => $online_info{NAS_ID} });

        if($Nas->{NAS_ID}) {
          $online_info{NAS_MNG_IP_PORT} = $Nas->{NAS_MNG_IP_PORT} || '';
          $online_info{NAS_MNG_USER} = $Nas->{NAS_MNG_USER} || '';
          $online_info{NAS_MNG_PASSWORD} = $Nas->{NAS_MNG_PASSWORD} || q{};
        }
      }

      if ($conf{INTERNET_TURBO_CMD}) {
        cmd($conf{INTERNET_TURBO_CMD}, {
          PARAMS => { %$user,
            IP     => $ip,
            %online_info
          },
          DEBUG  => $conf{INTERNET_TURBO_CMD_DEBUG},
        });
      }

      $html->message('info', $lang{INFO}, $html->b($turbo_mods_full[$FORM{SPEED} || $FORM{MODE_ID} || 0])
        . "\n$lang{REMAIN} $lang{TIME}: ". ($FORM{TIME} || 0). " sec."
      );
    }
    else {
      $html->message('err', "$lang{ERROR}:$lang{TURBO}", $lang{ERR_SMALL_DEPOSIT});
    }
  }
  else {
    if (defined($FORM{SPEED} && $FORM{SPEED} == 0)) {
      $html->message('err', "$lang{ERROR}:$lang{TURBO}", $lang{NO_TARIFF_SELECTED});
    }
    $Internet_->{SPEED_SEL} = $html->form_select(
      'SPEED',
      {
        SELECTED     => $FORM{SPEED},
        SEL_ARRAY    => [ '--', @turbo_mods_full ],
        ARRAY_NUM_ID => 1
      }
    );

    $html->tpl_show(_include('internet_user_speed', 'Internet'), $Internet_, { ID => 'INTERNET_TURBO_SPEED' });
  }

  return 1;
}

#**********************************************************
=head2 internet_turbo_mode_report()

=cut
#**********************************************************
sub internet_turbo_mode_report {
  internet_turbo_mode({ REPORT => 1 });

  return 1;
}

#**********************************************************
=head2 internet_turbo_mode($attr)

=cut
#**********************************************************
sub internet_turbo_mode {
  my ($attr) = @_;

  if (form_purchase_module({
    HEADER           => $user->{UID},
    MODULE           => 'Turbo',
    REQUIRE_VERSION  => 7.51
  })) {
    return 0;
  }

  my $Turbo    = Turbo->new($db, $admin, \%conf);
  #my $sessions = Turbo->new($db, $admin, \%conf);

  if ($FORM{del} && defined($FORM{COMMENTS})) {
    $Turbo->extra_hangup({ ID => $FORM{del} });
    if (!_error_show($Turbo)) {
      $html->message('info', $lang{INFO}, "$lang{TURBO} $lang{DELETED}");
    }
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 4;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  $LIST_PARAMS{ACTIVE} = 1 if (!$attr->{REPORT});

  my $list = $Turbo->list({
    %LIST_PARAMS,
    GROUP_BY => q{},
    COLS_NAME => 1
  });

  if ($Turbo->{TOTAL} < 1) {
    $html->message('info', $lang{INFO}, "$lang{NO_RECORD}");
    return 0;
  }

  my @caption = ($lang{USER}, $lang{TARIF_PLAN}, "$lang{REMAIN} $lang{TIME}", $lang{START}, $lang{DURATION}, $lang{SPEED});

  if ($Sessions->{SEARCH_FIELDS_COUNT}) {
    push @caption, 'TC';
  }

  my $table = $html->table({
    width        => '100%',
    caption      => "$lang{TURBO} $lang{SESSIONS}",
    title        => [ @caption, "-" ],
    qs           => $pages_qs,
    pages        => $Turbo->{TOTAL},
    recs_on_page => $LIST_PARAMS{PAGE_ROWS},
    ID           => 'INTERNET_TURBO_SESSIONS'
  });

  my $delete = '';
  require Billing;
  Billing->import();
  Billing->new($db, \%conf);

  foreach my $line (@$list) {
    if ($permissions{3} && $permissions{3}{1}) {
      $delete = $html->button($lang{DEL}, "index=" . $index . "$pages_qs&del=$line->{id}", { MESSAGE => "$lang{DEL} $lang{SESSIONS} $line->{id} ", class => 'del' });
    }

    $table->addrow($html->button($line->{login}, "index=11&UID=$line->{uid}"),
      $line->{mode_id},
      $line->{last_time},
      $line->{start},
      $line->{time},
      $line->{speed},
      $delete
    );
  }

  print $table->show();

  return 1;
}


1;