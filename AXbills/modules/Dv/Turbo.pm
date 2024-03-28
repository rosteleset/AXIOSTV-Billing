=head1 NAME

  Dv Turbo mode

=cut

use strict;
use warnings FATAL => 'all';

our(
  $db,
  %conf,
  $admin,
  %lang,
  $html,
  %permissions,

);

my $Sessions = Dv_Sessions->new($db, $admin, \%conf);

#**********************************************************
=head2 dv_turbo_mode_report()

=cut
#**********************************************************
sub dv_turbo_mode_report {
  dv_turbo_mode({ REPORT => 1 });

  return 1;
}

#**********************************************************
=head2 dv_turbo_mode($attr)

=cut
#**********************************************************
sub dv_turbo_mode {
  my ($attr) = @_;

  if (form_purchase_module({
    HEADER           => $user->{UID},
    MODULE           => 'Turbo',
    REQUIRE_VERSION  => 2.20
  })) {
    return 0;
  }

  my $Turbo    = Turbo->new($db, $admin, \%conf);
  #my $sessions = Turbo->new($db, $admin, \%conf);

  if ($FORM{del} && defined($FORM{COMMENTS})) {
    $Turbo->del({ ID => $FORM{del} });
    if (!_error_show($Turbo)) {
      $html->message('info', $lang{INFO}, "Torbo $lang{DELETED}");
    }
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 4;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  $LIST_PARAMS{ACTIVE} = 1 if (!$attr->{REPORT});

  my $list = $Turbo->list({%LIST_PARAMS, COLS_NAME => 1 });

  if ($Turbo->{TOTAL} < 1) {
    $html->message('info', $lang{INFO}, "$lang{NO_RECORD}");
    return 0;
  }

  my @caption = ("$lang{USER}", "$lang{TARIF_PLAN}", "$lang{REMAIN} $lang{TIME}", "$lang{START}", "$lang{DURATION}", "$lang{SPEED}");

  if ($Sessions->{SEARCH_FIELDS_COUNT}) {
    push @caption, 'TC';
  }

  my $table = $html->table(
    {
      width        => '100%',
      caption      => "TURBO $lang{SESSIONS}",
      title        => [ @caption, "-" ],
      qs           => $pages_qs,
      pages        => $Turbo->{TOTAL},
      recs_on_page => $LIST_PARAMS{PAGE_ROWS},
      ID           => 'DV_TURBO_SESSIONS'
    }
  );

  my $delete = '';
  require Billing;
  Billing->import();
  Billing->new($db, \%conf);

  foreach my $line (@$list) {
    if ($permissions{3}{1}) {
      $delete = $html->button($lang{DEL}, "index=" . $index . "$pages_qs&del=$line->{id}", { MESSAGE => "$lang{DEL} $lang{SESSIONS} $line->{id} ", class => 'del' });
    }

    $table->addrow($html->button("$line->{login}", "index=11&UID=$line->{uid}"),
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