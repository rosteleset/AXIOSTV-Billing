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

my $Sessions = Dv_Sessions->new($db, $admin, \%conf);

#***************************************************************
=head2 dv_start_page($attr) - Start page summary

=cut
#***************************************************************
sub dv_start_page {

  my %START_PAGE_F = (
    'dv_sp_online' => "Online",
    'dv_sp_errors' => "$lang{ERROR}",
  );

  return \%START_PAGE_F;
}

#***************************************************************
=head2 dv_sp_online($attr) - Online summary

=cut
#***************************************************************
sub dv_sp_online {

  $Sessions->online({
    STATUS_COUNT => 1,
    DOMAIN_ID    => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef
  });

  my $dv_online_index = get_function_index('dv_online');

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "Internet - Online",
      ID         => 'DV_ONLINE',
      rows       => [
        [$html->button('Online', "index=$dv_online_index"   ),
          $Sessions->{ONLINE_COUNT}  ],
        [$html->button('Reconnect', "STATUS=6&index=$dv_online_index"),
          $Sessions->{RECONNECT_COUNT} ],
        [$html->button('Recovery',    "STATUS=9&index=$dv_online_index"),
          $Sessions->{RECOVER_COUNT}  ],
        [$html->button('Zaped',    "ZAPED=2&index=$dv_online_index"),
          $Sessions->{ZAPPED_COUNT}  ]
      ],
    }
  );

  my $reports = $table->show();

  return $reports;
}


#***************************************************************
=head2 dv_sp_errors($attr) - Quick menu errors

=cut
#***************************************************************
sub dv_sp_errors {
  #my ($attr)=@_;

  my $Log     = Log->new($db, \%conf);
  my $list = $Log->log_reports({
    RETRIES   => 10,
    COLS_NAME => 1
  });

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "DV $lang{ERROR}",
      ID         => 'DV_ERRORS',
      title_plain=> [ "$lang{USER}", "$lang{COUNT}" ],
    }
  );

  foreach my $line (@$list) {
    $table->addrow(
      $html->button($line->{user}, "index=". get_function_index('dv_error') ."&LOGIN=$line->{user}&search=1"),
      $line->{count},
    );
  }

  my $reports = $table->show();

  return $reports;
}


1;