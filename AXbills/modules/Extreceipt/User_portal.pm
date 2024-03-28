=head1 NAME

  Extreceipt User portal

=cut

use strict;
use warnings FATAL => 'all';

use Extreceipt::db::Extreceipt;
use Extreceipt::Base;

our (
  $db,
  $admin,
  %conf,
  %lang,
);

our AXbills::HTML $html;
my $Receipt = Extreceipt->new($db, $admin, \%conf);

#**********************************************************
=head2 extreceipts_list()

  Show checks for user

=cut
#**********************************************************
sub extreceipts_list {
  my $list = $Receipt->list({
    UID  => $user->{UID},
  });

  my $Receipt_api = receipt_init($Receipt, { SKIP_INIT => 1 });
  $Receipt->{API} = $Receipt_api;

  my $table = $html->table({
    width      => '100%',
    caption    => $lang{CHECKS},
    title      => [ $lang{DATE}, $lang{CHECK}, "$lang{CHECK} $lang{RETURN}" ],
    ID         => 'Extreceipts',
    DATA_TABLE => { lengthMenu => [ [ 50, 100, -1 ], [ 50, 100, $lang{ALL} ] ] },
  });

  foreach my $check (@{$list}) {
    my @columns = ();
    push @columns, $check->{DATE};

    if ($Receipt->{API}->{$check->{api_id}}->can('get_receipt')) {
      $check->{command_id} ? push @columns, $html->button("$lang{REVIEW} $lang{CHECK}", '',
        { GLOBAL_URL => $Receipt->{API}->{$check->{api_id}}->get_receipt($check), class => 'btn btn-xs btn-info' })
        : push @columns, '';

      if ($check->{cancel_id}) {
        $check->{command_id} = $check->{cancel_id};
        $check->{command_id} ? push @columns, $html->button("$lang{REVIEW} $lang{CHECK}", '',
          { GLOBAL_URL => $Receipt->{API}->{$check->{api_id}}->get_receipt($check), class => 'btn btn-xs btn-warning' })
          : push @columns, '';
      }
      else {
        push @columns, '';
      }
    }
    $table->addrow(@columns);
  }

  return print $table->show();
}

1;
