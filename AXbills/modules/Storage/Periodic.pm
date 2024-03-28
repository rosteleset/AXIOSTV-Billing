use strict;
use warnings FATAL => 'all';

use Storage;
use Fees;

our (
  $db,
  %conf,
  %lang,
  $html,
  %permissions,
  %ADMIN_REPORT,
  %err_strs
);

our Storage $Storage;
our Fees $fees;

#***********************************************************
=head2 storage_monthly_fees($attr)

=cut
#***********************************************************
sub storage_monthly_fees{
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
  my $d = (split(/-/, $ADMIN_REPORT{DATE}, 3))[2];

  _storage_rent_fees({ DAY => $d, %{$attr}, DATE => $ADMIN_REPORT{DATE} });

  _storage_installments_fees({ DATE => $ADMIN_REPORT{DATE} }) if ($d == 1);

  return 1;
}

#**********************************************************
=head2 _storage_rent_fees($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _storage_rent_fees {
  my ($attr) = @_;

  my $list = $Storage->storage_rent_fees({ DATE => $attr->{DATE}, COLS_NAME => 1 });

  my $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;
  return 1 if !$attr->{DAY};

  foreach my $line (@{$list}) {
    $users->{BILL_ID} = $line->{bill_id};
    $users->{UID} = $line->{uid};
    $line->{rent_price} = $line->{rent_price} * $line->{count};

    next if !$users->{BILL_ID} || !$users->{UID};
    next if $attr->{DAY} != $START_PERIOD_DAY && !$line->{abon_distribution};

    _storage_get_fees({
      SUM               => $line->{rent_price},
      ABON_DISTRIBUTION => $line->{abon_distribution},
      DESCRIBE          => "$lang{PAY_FOR_RENT} $line->{article_name}",
      METHOD            => $line->{fees_method} || '',
      DEBUG             => $attr->{DEBUG} || 0
    });
  }

  return 0;
}

#**********************************************************
=head2 _storage_get_fees($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _storage_get_fees {
  my ($attr) = @_;

  if ($attr->{ABON_DISTRIBUTION}) {
    $attr->{SUM} = sprintf("%.6f", $attr->{SUM} / days_in_month({ DATE => $ADMIN_REPORT{DATE} }));
    $attr->{DESCRIBE} .= " - $lang{ABON_DISTRIBUTION}";
  }

  $fees->take($users, $attr->{SUM}, {
    DATE     => $ADMIN_REPORT{DATE},
    DESCRIBE => $attr->{DESCRIBE},
    METHOD   => $attr->{METHOD}
  });

  if ($fees->{errno}) {
    print "Storage Error: [ $users->{UID} ] SUM: $attr->{SUM} [$fees->{errno}] $fees->{errstr} \n";
  }
  elsif (defined $attr->{DEBUG} && $attr->{DEBUG} > 0) {
    print "$attr->{DESCRIBE}. UID: $users->{UID} SUM: $attr->{SUM}\n";
  }

  return 0;
}

#**********************************************************
=head2 _storage_installments_fees($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _storage_installments_fees {
  my ($attr) = @_;

  my $list = $Storage->storage_by_installments_fees({ DATE => $attr->{DATE}, COLS_NAME => 1 });

  foreach my $line (@{$list}) {
    $users->{BILL_ID} = $line->{bill_id};
    $users->{UID} = $line->{uid};

    next if !$users->{BILL_ID} || !$users->{UID};

    my $total_sum = $line->{amount_per_month} * $line->{count};

    $line->{article_name} ||= '';
    $fees->take($users, $total_sum, {
      DATE     => $ADMIN_REPORT{DATE},
      DESCRIBE => "$lang{BY_INSTALLMENTS} $line->{article_name}",
      METHOD   => $line->{fees_method} || ''
    });

    if ($fees->{errno}) {
      $html->message('err', $lang{ERROR}, "[$fees->{errno}] $err_strs{$fees->{errno}}");
    }
    else {
      $Storage->storage_installation_change({
        ID      => $line->{id},
        MONTHES => $line->{monthes} - 1,
      });
    }
  }

  return 0;
}

1;