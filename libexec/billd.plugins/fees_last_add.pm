# billd plugin
#**********************************************************
=head1

 billd plugin

 Standart execute
    /usr/axbills/libexec/billd fees_last_add

 DESCRIBE:  Add last payment to table 'fees_last' with replace by uid

=cut
#*********************************************************
use strict;
use warnings FATAL => 'all';
use Fees;


our (
  $db,
  %conf
);

our Admins $Admin;
our $admin = $Admin;

my $Fees = Fees->new($db, $admin, \%conf);


fees_pool();

#**********************************************************
=head2 fees_pool($attr)

=cut
#**********************************************************
sub fees_pool {

  my $fees_list = $Fees->list({
    UID       => '_SHOW',
    ID        => '_SHOW',
    SUM       => '_SHOW',
    LAST_DATE => '_SHOW',
    GROUP_BY  => 'f.uid',
    COLS_NAME => 1,
    SORT      => 'id',
    PAGE_ROWS => 1000000
  }) ;

  return 1 if (!$fees_list);

  foreach my $fee (@$fees_list) {
    $Fees->fees_last_add({
      UID       => $fee->{uid},
      FEES_ID   => $fee->{id},
      SUM       => $fee->{sum},
      DATE      => $fee->{date},
      COLS_NAME => 1,
    })
  }

  return 1;
}

