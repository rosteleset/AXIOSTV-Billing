package Sinfo;

=head1 NAME

  Info about next payment

=cut

use strict;
use parent qw( dbcore );
use AXbills::Base qw( _bp in_array );
use Time::Piece;
my @days_in_month = (29,31,28,31,30,31,30,31,31,30,31,30,31);

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf) = @_;

  my $self = {
    db          => $db,
    admin       => $admin,
    conf        => $conf
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 services_warning ($uid)

=cut
#**********************************************************
sub services_warning {
  my $self = shift;
  my $uid = shift;
  
  my $hash = $self->show_services_stop_date($uid);
  return $hash;
}

#**********************************************************
=head2 show_services_stop_date ($uid)

=cut
#**********************************************************
sub show_services_stop_date {
  my $self = shift;
  my $uid = shift;

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);

  my $deposit = $Users->{DEPOSIT};
  my $credit  = $Users->{CREDIT};
  my $date = Time::Piece->strptime($main::DATE, "%Y-%m-%d");
  my %service_hash = ();
  my $end_date = '';
  my $hash = $self->get_all_fees($uid);

  foreach my $key (sort keys %$hash) {
    foreach my $line (@{$hash->{$key}}) {
      next if ($service_hash{$line->{service}});
      if ($line->{sum} > $deposit + $credit) {
        my $sd = Time::Piece->strptime($key, "%Y-%m-%d");
        my %service_line = %$line;
        $service_line{end_date} = $key;
        $service_line{end_days} = ($sd - $date) / 86400;
        $service_hash{$line->{service}} = \%service_line;
        $end_date = $key unless ($end_date);
      }
      else {
        $deposit -= $line->{sum};
      }
    }
  }

  return (\%service_hash, $end_date);
}


#**********************************************************
=head2 get_all_fees ($uid)

=cut
#**********************************************************
sub get_all_fees {
  my $self = shift;
  my $uid = shift;
  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);
  my $reduction = 1 - $Users->{REDUCTION}/100;

  my $hash1 = $self->get_daily_fees($uid, $reduction);
  my $hash2 = $self->get_distrib_fees($uid, $reduction);
  my $hash3 = $self->get_monthly_fees($uid, $reduction);

  foreach my $key (keys %$hash2) {
    foreach my $line (@{$hash2->{$key}}) {
      push (@{$hash1->{$key}}, $line);
    }
  }

  foreach my $key (keys %$hash3) {
    foreach my $line (@{$hash3->{$key}}) {
      push (@{$hash1->{$key}}, $line);
    }
  }

  return $hash1;
}

#**********************************************************
=head2 get_daily_fees ($uid)

=cut
#**********************************************************
sub get_daily_fees {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;
  my %fees_hash = ();

  my $list = $self->daily_fees_list($uid, $reduction);
  my $date = Time::Piece->strptime($main::DATE, "%Y-%m-%d");
  my $d2 = $date + $date->month_last_day * 86400;
  foreach my $line (@$list) {
    my $d = $date + 86400;
    while ($d->mon == $date->mon || $d->mon == $d2->mon) {
      my %hash_line = %$line;
      $hash_line{sum} = $line->{day_abon};
      push (@{$fees_hash{$d->ymd}}, \%hash_line);
      $d = $d + 86400;
    }
  }
  return \%fees_hash;
}

#**********************************************************
=head2 daily_fees_list ($uid)

=cut
#**********************************************************
sub daily_fees_list {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;

  my $list = $self->internet_daily_fees_list($uid, $reduction);
  if (in_array('Iptv', \@main::MODULES)) {
    my $iptv_list = $self->iptv_daily_fees_list($uid, $reduction);
    @$list = (@$list, @$iptv_list);
  }

  return $list;
}

#**********************************************************
=head2 internet_daily_fees_list ($uid)

=cut
#**********************************************************
sub internet_daily_fees_list {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;

  $self->query("SELECT
    CONCAT_WS('_', 'Internet', im.id) as service,
    tp.name AS tp_name,
    tp.tp_id AS tp_id,
    tp.day_fee AS day_abon,
    tp.month_fee AS month_abon,
    tp.abon_distribution,
    tp.reduction_fee
    FROM internet_main im
    LEFT JOIN tarif_plans tp ON (tp.tp_id = im.tp_id)
    WHERE im.uid = ?
    AND im.disable = 0
    AND (im.expire = '0000-00-00' OR im.expire > CURDATE())
    AND (im.activate = '0000-00-00' OR im.activate <= CURDATE())
    AND (tp.day_fee > 0 OR (tp.abon_distribution = 1 AND im.activate <> '0000-00-00'));",
    undef,
    { COLS_NAME => 1, Bind => [ $uid ] }
  );
  my $list = $self->{list};
  foreach my $line (@$list) {
    my $distrib_sum = ($line->{abon_distribution} && $line->{month_abon} > 0) ? $line->{month_abon} / 30 : 0;
    $line->{sum} = ($line->{day_abon} + $distrib_sum) * ($line->{reduction_fee} ? $reduction : 1);
  }

  return $list;
}

#**********************************************************
=head2 iptv_daily_fees_list ($uid)

=cut
#**********************************************************
sub iptv_daily_fees_list {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;

  $self->query("SELECT
    CONCAT_WS('_', 'Iptv', im.id) as service,
    tp.name AS tp_name,
    tp.tp_id AS tp_id,
    tp.day_fee AS day_abon,
    tp.month_fee AS month_abon,
    tp.abon_distribution,
    tp.reduction_fee
    FROM iptv_main im
    LEFT JOIN tarif_plans tp ON (tp.tp_id = im.tp_id)
    WHERE im.uid = ?
    AND im.disable = 0
    AND (im.expire = '0000-00-00' OR im.expire > CURDATE())
    AND (im.activate = '0000-00-00' OR im.activate <= CURDATE())
    AND (tp.day_fee > 0 OR (tp.abon_distribution = 1 AND im.activate <> '0000-00-00'));",
    undef,
    { COLS_NAME => 1, Bind => [ $uid ] }
  );
  my $list = $self->{list};
  foreach my $line (@$list) {
    my $distrib_sum = ($line->{abon_distribution} && $line->{month_abon} > 0) ? $line->{month_abon} / 30 : 0;
    $line->{sum} = ($line->{day_abon} + $distrib_sum) * ($line->{reduction_fee} ? $reduction : 1);
  }

  return $list;
}

#**********************************************************
=head2 get_distrib_fees ($uid)

=cut
#**********************************************************
sub get_distrib_fees {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;
  my %fees_hash = ();

  my $list = $self->distrib_fees_list($uid, $reduction);
  my $date = Time::Piece->strptime($main::DATE, "%Y-%m-%d");
  my $d2 = $date + $date->month_last_day * 86400;
  foreach my $line (@$list) {
    my $d = $date + 86400;
    while ($d->mon == $date->mon || $d->mon == $d2->mon) {
      my %hash_line = %$line;
      $hash_line{sum} = $line->{month_abon} / $d->month_last_day;
      push (@{$fees_hash{$d->ymd}}, \%hash_line);
      $d = $d + 86400;
    }
  }
  return \%fees_hash;
}

#**********************************************************
=head2 distrib_fees_list ($uid)

=cut
#**********************************************************
sub distrib_fees_list {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;

  my $list = $self->internet_distrib_fees_list($uid, $reduction);
  if (in_array('Iptv', \@main::MODULES)) {
    my $iptv_list = $self->iptv_distrib_fees_list($uid, $reduction);
    @$list = (@$list, @$iptv_list);
  }

  return $list;
}

#**********************************************************
=head2 internet_distrib_fees_list ($uid)

=cut
#**********************************************************
sub internet_distrib_fees_list {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;

  $self->query("SELECT
    CONCAT_WS('_', 'Internet', im.id) as service,
    tp.name AS tp_name,
    tp.tp_id AS tp_id,
    tp.day_fee AS day_abon,
    tp.month_fee AS month_abon,
    tp.abon_distribution,
    tp.reduction_fee
    FROM internet_main im
    LEFT JOIN tarif_plans tp ON (tp.tp_id = im.tp_id)
    WHERE im.uid = ?
    AND im.disable = 0
    AND (im.expire = '0000-00-00' OR im.expire > CURDATE())
    AND (im.activate = '0000-00-00' OR im.activate <= CURDATE())
    AND tp.month_fee > 0
    AND tp.abon_distribution = 1
    AND im.activate = '0000-00-00';",
    undef,
    { COLS_NAME => 1, Bind => [ $uid ] }
  );
  my $list = $self->{list};

  return $list || [ ];
}

#**********************************************************
=head2 iptv_distrib_fees_list ($uid)

=cut
#**********************************************************
sub iptv_distrib_fees_list {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;

  $self->query("SELECT
    CONCAT_WS('_', 'Iptv', im.id) as service,
    tp.name AS tp_name,
    tp.tp_id AS tp_id,
    tp.day_fee AS day_abon,
    tp.month_fee AS month_abon,
    tp.abon_distribution,
    tp.reduction_fee
    FROM iptv_main im
    LEFT JOIN tarif_plans tp ON (tp.tp_id = im.tp_id)
    WHERE im.uid = ?
    AND im.disable = 0
    AND (im.expire = '0000-00-00' OR im.expire > CURDATE())
    AND (im.activate = '0000-00-00' OR im.activate <= CURDATE())
    AND tp.month_fee > 0
    AND tp.abon_distribution = 1
    AND im.activate = '0000-00-00';",
    undef,
    { COLS_NAME => 1, Bind => [ $uid ] }
  );
  my $list = $self->{list};

  return $list || [ ];
}

#**********************************************************
=head2 get_monthly_fees ($uid)

=cut
#**********************************************************
sub get_monthly_fees {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;
  my $date = Time::Piece->strptime($main::DATE, "%Y-%m-%d");
  my ($y, $m, $d) = split('-', $main::DATE);
  my %fees_hash = ();
  my $list = $self->monthly_fees_list($uid, $reduction);
  my $start_period_day = $self->{conf}{START_PERIOD_DAY} || 1;
  my $sd = Time::Piece->strptime("$y-$m-$start_period_day", "%Y-%m-%d");
  foreach my $line (@$list) {
    my $d1 = ($line->{activate} ne '0000-00-00')
           ? Time::Piece->strptime($line->{activate}, "%Y-%m-%d")
           : $sd;
    my $d2 = ($line->{activate} ne '0000-00-00' && !$line->{fixed_fees_day})
           ? $d1 + 86400 * 31
           : $d1 + 86400 * $d1->month_last_day;
    my $d3 = ($line->{activate} ne '0000-00-00' && !$line->{fixed_fees_day})
           ? $d2 + 86400 * 31
           : $d2 + 86400 * $d2->month_last_day;    
    push (@{$fees_hash{$d2->ymd}}, $line);
    if ($date->mon == $d2->mon) {
      push (@{$fees_hash{$d3->ymd}}, $line);
    }
  }
  return \%fees_hash;
}

#**********************************************************
=head2 monthly_fees_list ($uid)

=cut
#**********************************************************
sub monthly_fees_list {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;

  my $list = $self->internet_monthly_fees_list($uid, $reduction);
  if (in_array('Iptv', \@main::MODULES)) {
    my $iptv_list = $self->iptv_monthly_fees_list($uid, $reduction);
    @$list = (@$list, @$iptv_list);
  }

  return $list;
}

#**********************************************************
=head2 internet_monthly_fees_list ($uid)

=cut
#**********************************************************
sub internet_monthly_fees_list {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;

  $self->query("SELECT
    CONCAT_WS('_', 'Internet', im.id) as service,
    tp.name AS tp_name,
    tp.tp_id AS tp_id,
    tp.month_fee AS month_abon,
    tp.month_fee AS sum,
    tp.abon_distribution,
    tp.reduction_fee,
    tp.fixed_fees_day,
    im.activate
    FROM internet_main im
    LEFT JOIN tarif_plans tp ON (tp.tp_id = im.tp_id)
    WHERE im.uid = ?
    AND im.disable = 0
    AND (im.expire = '0000-00-00' OR im.expire > CURDATE())
    AND (im.activate = '0000-00-00' OR im.activate <= CURDATE())
    AND tp.month_fee > 0
    AND tp.abon_distribution = 0;",
    undef,
    { COLS_NAME => 1, Bind => [ $uid ] }
  );
  my $list = $self->{list};

  return $list || [ ];
}

#**********************************************************
=head2 iptv_monthly_fees_list ($uid)

=cut
#**********************************************************
sub iptv_monthly_fees_list {
  my $self = shift;
  my $uid = shift;
  my $reduction = shift;

  $self->query("SELECT
    CONCAT_WS('_', 'Iptv', im.id) as service,
    tp.name AS tp_name,
    tp.tp_id AS tp_id,
    tp.month_fee AS month_abon,
    tp.month_fee AS sum,
    tp.abon_distribution,
    tp.reduction_fee,
    tp.fixed_fees_day,
    im.activate
    FROM iptv_main im
    LEFT JOIN tarif_plans tp ON (tp.tp_id = im.tp_id)
    WHERE im.uid = ?
    AND im.disable = 0
    AND (im.expire = '0000-00-00' OR im.expire > CURDATE())
    AND (im.activate = '0000-00-00' OR im.activate <= CURDATE())
    AND tp.month_fee > 0
    AND tp.abon_distribution = 0;",
    undef,
    { COLS_NAME => 1, Bind => [ $uid ] }
  );
  my $list = $self->{list};

  return $list || [ ];
}


#**********************************************************
=head2 get_other_fees ($uid)

=cut
#**********************************************************

#**********************************************************
=head2 other_fees_list ($uid)

=cut
#**********************************************************

1