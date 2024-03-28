use strict;
use warnings;

our ($db,
  %lang,
  $admin,
  %permissions,
);

#**********************************************************
=head2 company_users_total_info($company_id)
    Show company users total info, and services count.

    Arguments:
      $company_id - company id, exactly

    Returns:
      $result
        TOTAL - number of all services
        SUM - sum of all services

=cut
#**********************************************************
sub company_users_total_info {
  my ($company_id) = @_;

  my $user = Users->new($db, $admin, \%conf);
  require Control::Services;

  my $sum_total = 0;
  my $total     = 0;

  my $users_list = $user->list({
    COMPANY_ID => $company_id,
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    REDUCTION  => '_SHOW'
  });

  my $sum_for_pay = 0;

  foreach my $line (@$users_list) {
    my $service_info = get_services({
      UID          => $line->{UID},
      REDUCTION    => $line->{REDUCTION},
      PAYMENT_TYPE => 0
    });

    foreach my $service ( @{ $service_info->{list} } ) {
      $sum_total += $service->{SUM};
      $total++;
      if ($service->{STATUS} eq '5') {
        $sum_for_pay += $service->{SUM};
      }
    }
  }

  if (defined($user->{DEPOSIT}) && $user->{DEPOSIT} != 0) {
    $sum_for_pay = $sum_for_pay - $user->{DEPOSIT};
  }

  return {
    TOTAL => $total,
    SUM   => sprintf("%.2f", $sum_total)
  };
}
