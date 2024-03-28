=head1 NAME

  Docs Periodic

=cut

use strict;
use warnings FATAL => 'all';
use Docs;

our(
  %lang,
  $Conf,
  $db,
  $admin,
  %conf,
  %ADMIN_REPORT,
  $Iptv,
  $html
);

my $Docs = Docs->new($db, $admin, \%conf);

#**********************************************************
=head2 docs_unpaid_invoice_del() Del unpaid invoice
  Arguments:
    $attr

  Returns:
    $attr

=cut
#**********************************************************
sub docs_unpaid_invoice_del {
  my ($attr) = @_;
  my $debug = $attr->{DEBUG} || 0;

  if($debug > 0){
    print "\nDebug mod = $attr->{DEBUG} \n";
  }

  if(!defined($conf{DOCS_ACCOUNT_EXPIRE_PERIOD_MULTIPLIER})){

    if($debug > 0){
      print 'No inicialize variables $conf{DOCS_ACCOUNT_EXPIRE_PERIOD_MULTIPLIER}'. "\n";
    }

    return 0;
  }
  my $date = $DATE;

  my $time_to_expore = ( $conf{DOCS_ACCOUNT_EXPIRE_DAY} || $conf{DOCS_ACCOUNT_EXPIRE_PERIOD} || 30 ) * ($conf{DOCS_ACCOUNT_EXPIRE_PERIOD_MULTIPLIER} || 1);

  my ($Y, $M, $D);
  ($Y, $M, $D) = split( /-/, $date );

  my $invoce_date = POSIX::strftime( "%Y-%m-%d",
    localtime( (POSIX::mktime( 0, 0, 0, $D-$time_to_expore, ($M - 1), ($Y - 1900), 0, 0, 0 )) ) );

  if($debug > 8){
    print 'PERIOD MULTIPLIER = '. $conf{DOCS_ACCOUNT_EXPIRE_PERIOD_MULTIPLIER}. "\n";
    print 'Date to expore = '.  "$invoce_date". "\n";
    print 'Date = '. $date. "\n";
    print 'Time to expore = '. $time_to_expore. "\n";
  }

  my $list = $Docs->invoices_list(
    {
      PAGE_ROWS           => 100000,
      DATE                => "<$invoce_date",
      DELL_UNPAID_INVOICE => 1,
      COLS_NAME           => 1,
    }
  );

  if(!$Docs->{TOTAL}){
    return 0;
  }

  my %infoce_id = ();
  my $infoce_id_string = ();

  #Create hash with name=invoice id , value=invoce date and string with id to insert into invoices2paynets list
  foreach my $invioce_info (@$list){

    if($infoce_id_string){
      $infoce_id_string .= ';'. $invioce_info->{id};
    }
    else{
      $infoce_id_string .= $invioce_info->{id}.";"
    }

    $infoce_id{ $invioce_info->{id} } = $invioce_info->{date};
  }

  my $inv2pey_list = $Docs->invoices2payments_list(
    {
      PAGE_ROWS  => 100000,
      INVOICE_ID => $infoce_id_string,
      COLS_NAME  => 1,
    }
  );

  if(!$Docs->{TOTAL}){
    return 0;
  }

  if($debug) {
    print 'Total = ' . $Docs->{TOTAL} . "\n";
  }

  #if hash have invoce2pey_list id initialize undef
  foreach my $invioce_paid_info (@$inv2pey_list){

    if( defined($infoce_id{ $invioce_paid_info->{invoice_id} } )){
      $infoce_id{ $invioce_paid_info->{invoice_id} } = undef;
    }
  }

  #delete if initialize
  foreach my $invioce_id_info (keys %infoce_id){
    if($infoce_id{$invioce_id_info}){
      $Docs->invoice_del( $invioce_id_info );
      if($debug) {
        print 'Invoice del result ID ' . $invioce_id_info . ' = ' . $infoce_id{$invioce_id_info} . "\n";
      }
    }
  }

  return 1;
}

1;