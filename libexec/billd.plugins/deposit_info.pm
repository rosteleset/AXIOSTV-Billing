=head1 NAME

  billd plugin

=head2  DESCRIBE

  Deposit user information
    - drop filter for positive deposit

  Arguments:
    FILTER_ID - Filter ID for erase
    DEPOSIT   - Deposit limit for erase

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';

our (
  $debug,
  %conf,
  $admin,
  $argv,
  $db,
  $OS,
);

our Dv $Internet;

deposit_info();


#**********************************************************
=head2 deposit_info() - Deposit info

=cut
#**********************************************************
sub deposit_info {

  if ($debug > 1) {
    print "Deposit info\n";
  }

  my $filter_id = $argv->{FILTER_ID} || q{};
  my $deposit_limit = $argv->{DEPOSIT} || 0;

  if($debug > 6) {
    $Internet->{debug}=1;
  }

  my $list = $Internet->user_list({
    LOGIN     => '_SHOW',
    DEPOSIT   => '_SHOW',
    TP_CREDIT => '_SHOW',
    FILTER_ID => $filter_id || '!',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });

  my $total = 0;
  foreach my $line ( @$list ) {
    if($line->{deposit} < 0) {
      next;
    }
    elsif(! $line->{tp_credit}){
      next;
    }
    elsif($line->{deposit}+($line->{tp_credit} || 0) < $deposit_limit) {
      next;
    }

    if($debug > 2) {
      print "Login: $line->{login} DEPOSIT: $line->{deposit} TP_CREDIT: $line->{tp_credit} FILTER_ID: $line->{filter_id}\n";
    }

    if ($debug > 6) {
      next;
    }

    $Internet->user_change({
      UID => $line->{uid},
      FILTER_ID => ''
    });

    $total++;
  }

  if ($debug > 1) {
    print "Total: $total\n";
  }

  return 1;
}



1;
