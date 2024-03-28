=head1 NAME

  Quick reports for Dv

=cut

use strict;
use warnings FATAL => 'all';

our(
  $html,
  %lang,
  $admin,
  $db,
  %conf
);

my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

#***************************************************************
=head2 internet_start_page($attr) - Start page summary

=cut
#***************************************************************
sub internet_start_page {

  my %START_PAGE_F = (
    'internet_sp_online' => "$lang{INTERNET} - Online",
    'internet_sp_errors' => "$lang{INTERNET} $lang{ERROR}",
    'internet_users_summary' => "$lang{INTERNET} - $lang{ERR_SMALL_DEPOSIT}",
  );

  return \%START_PAGE_F;
}

#***************************************************************
=head2 internet_sp_online($attr) - Online summary

=cut
#***************************************************************
sub internet_sp_online {

  $Sessions->online({
    STATUS_COUNT => 1,
    DOMAIN_ID    => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef
  });

  my $internet_online_index = get_function_index('internet_online');

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{INTERNET} - Online",
      ID         => 'INTERNET_ONLINE',
      rows       => [
        [$html->button('Online', "index=$internet_online_index"   ),
          $Sessions->{ONLINE_COUNT}  ],
        [$html->button('Reconnect', "STATUS=6&index=$internet_online_index"),
          $Sessions->{RECONNECT_COUNT} ],
        [$html->button('Recovery',    "STATUS=9&index=$internet_online_index"),
          $Sessions->{RECOVER_COUNT}  ],
        [$html->button('Zaped',    "ZAPED=2&index=$internet_online_index"),
          $Sessions->{ZAPPED_COUNT}  ]
      ],
    }
  );

  my $reports = $table->show();

  return $reports;
}


#***************************************************************
=head2 internet_sp_errors($attr) - Quick menu errors

=cut
#***************************************************************
sub internet_sp_errors {

  my $Log     = Log->new($db, \%conf);
  my $list = $Log->log_reports({
    RETRIES   => 10,
    COLS_NAME => 1
  });

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{INTERNET} $lang{ERROR}",
      ID         => 'INTERNET_ERRORS',
      title_plain=> [ $lang{USER}, $lang{COUNT} ],
    }
  );

  foreach my $line (@$list) {
    $table->addrow(
      $html->button($line->{user}, "index=". get_function_index('internet_error') ."&LOGIN=$line->{user}&search=1"),
      $line->{count},
    );
  }

  my $reports = $table->show();

  return $reports;
}


#**********************************************************
=head2 internet_users_summary($attr)

=cut
#**********************************************************
sub internet_users_summary {

  require Internet;
  Internet->import();
  my $Internet = Internet->new($db, $admin, \%conf);
  my $index = get_function_index ('internet_users_list');
  my $deposit = 0;
  my $fee = 0;

  my $user_list = $Internet->user_list({
    DEPOSIT         => '_SHOW',
    MONTH_FEE       => '_SHOW',
    INTERNET_STATUS => 5,
    COLS_NAME       => 1
});

  foreach my $line (@$user_list) {
    $deposit += $line->{deposit} if ($line->{deposit});
    $fee += $line->{month_fee} if ($line->{month_fee});
  }
  
  my $table = $html->table({
    width   => '100%',
    caption => "$lang{INTERNET} - $lang{ERR_SMALL_DEPOSIT}",
    ID      => 'INTERNET_USERS_SUMMARY',
    rows    => [
      [ $html->button($lang{TOTAL}, "index=$index&INTERNET_STATUS=5"), $Internet->{TOTAL} ],
      [ $lang{DEPOSIT}, $deposit ],
      [ $lang{MONTH_FEE}, $fee ],
    ],
  });

  return $table->show();
}

1;