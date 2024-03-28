# billd plugin
#**********************************************************
=head1

 billd plugin

 Standart execute
    /usr/axbills/libexec/billd payments_pool

 DESCRIBE:  Folclor - Sync users and update balance

 Arguments:

=cut
#*********************************************************
use strict;
use warnings FATAL => 'all';
unshift(@INC, '/usr/axbills/', '/usr/axbills/AXbills/'); #/usr/axbills/AXbills/
use Users;
#use Paysys;

our $html = AXbills::HTML->new({ CONF => \%conf });
our (
  $db,
  %conf,
  %lang,
  $debug,
  $argv,
  $libpath,
  $DATE,
);

our Admins $Admin;
our $admin = $Admin;
require AXbills::Misc;

our $users = Users->new($db, $Admin, \%conf);

do "/usr/axbills/language/$conf{default_language}.pl";

#load_module('Paysys', $html);
#my $Paysys = Paysys->new($db, $Admin, \%conf);

payments_pool();

#**********************************************************
=head2 payments_pool($attr)

=cut
#**********************************************************
sub payments_pool {

  my $Payments = Finance->payments($db, $Admin, \%conf);

  if ($debug > 6) {
    $Payments->{debug} = 1;
  }

  my %params = (
    PAYMENT_ID => '_SHOW',
    DATETIME   => '_SHOW',
    EXT_ID     => '_SHOW',
    UID        => '_SHOW',
    SUM        => '_SHOW',
    DSC        => '_SHOW',
    METHOD     => '_SHOW',
    STATUS     => 0,
    PAGE_ROWS  => 100000,
    COLS_NAME  => 1
  );

  if ($argv->{LIMIT}) {
    $params{PAGE_ROWS} = $argv->{LIMIT};
  }

  if ($argv->{PAYMENT_ID}) {
    $params{PAYMENT_ID} = $argv->{PAYMENT_ID};
  }

  my $list_payments = $Payments->pool_list({
    %params
  });

  foreach my $payments_pool (@$list_payments) {
    my $user = $users->info($payments_pool->{uid});

    if ($debug > 1) {
      print "UID: $payments_pool->{uid} EXT_ID: $payments_pool->{ext_id}";
    }

    if ($payments_pool->{status} != 1) {
      cross_modules('pre_payment', {
        USER_INFO    => $user,
        SKIP_MODULES => 'Sqlcmd, Cards',
        #SILENT       => 1,
        SUM          => $payments_pool->{sum},
        AMOUNT       => $payments_pool->{sum},
        EXT_ID       => $payments_pool->{ext_id},
        METHOD       => $payments_pool->{method},
        DEBUG        => ($debug > 3) ? 1 : undef,
        timeout      => $conf{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
      });

      if ($debug > 1) {
        print "SPOOL_ID: $payments_pool->{payment_id} PAYMENTS_ID: $payments_pool->{payment_id} pre_payment\n";
      }

      cross_modules('payments_maked', {
        USER_INFO  => $user,
        PAYMENT_ID => $payments_pool->{payment_id},
        SUM        => $payments_pool->{sum},
        SILENT     => 1,
        QUITE      => 1,
        timeout    => $conf{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
      });

      if ($debug < 6) {
        $Payments->pool_change({
          ID     => $payments_pool->{id},
          STATUS => 1,
        });

        if ($debug > 0) {
          print "SPOOL_ID: $payments_pool->{payment_id} PAYMENTS_ID: $payments_pool->{payment_id} change STATUS = 1\n";
        }
      }
    }

    #my $system_info = 0;
    #my $method = 0;
    # $system_info = $Paysys->paysys_connect_system_list({
    #   PAYSYS_ID      => $payments_pool->{method},
    #   PAYMENT_METHOD => '_SHOW',
    #   COLS_NAME      => 1,
    # });

    #$method = $system_info->[0]{payment_method} || 0;

    #if(defined $method){
    #  paysys_pool($payments_pool);
    #}
  }

  return 1;
}

1;