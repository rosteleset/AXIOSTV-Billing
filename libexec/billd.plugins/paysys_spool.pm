# billd plugin
#**********************************************************
=head1

 billd plugin

 Standart execute
    /usr/axbills/libexec/billd paysys_spool

 DESCRIBE:  Folclor - Sync users and update balance

 Arguments:

=cut
#*********************************************************
use strict;
use warnings FATAL => 'all';
unshift(@INC, '/usr/axbills/', '/usr/axbills/AXbills/'); #/usr/axbills/AXbills/

our $html = AXbills::HTML->new( { CONF => \%conf } );
our (
  $db,
  $admin,
  $Admin,
  %conf,
  %lang,
  $debug,
  $argv,
  $libpath,
  $DATE,
);

require AXbills::Misc;
require AXbills::Base;
use Users;
use Paysys;

$admin = $Admin;

$debug = $argv->{DEBUG} || 1;

our $users = Users->new($db, $admin, \%conf);

do "/usr/axbills/language/$conf{default_language}.pl";

load_module('Paysys', $html);
my $version = 7.0;

payments_spool();

#**********************************************************
=head2 payments_spool($attr)

=cut
#**********************************************************
sub payments_spool {
  my $self = shift;

  my $Payments = Finance->payments($db, $admin, \%conf);

  my $system_info = 0;
  my $method = 0;

  my $list_payments = $Payments->list_spool({
    SUM                 => '_SHOW',
    DSC                 => '_SHOW',
    EXT_ID              => '_SHOW',
    UID                 => '_SHOW',
    COLS_NAME => 1
  });

  foreach my $payments_spool (@$list_payments) {
    my $user = $users->info($payments_spool->{uid});

    cross_modules_call('_pre_payment', {
       USER_INFO    => $user,
       SKIP_MODULES => 'Sqlcmd, Cards',
       SILENT       => 1,
       SUM          => $payments_spool->{sum},
       AMOUNT       => $payments_spool->{sum},
       EXT_ID       => "$payments_spool->{ext_id}",
       METHOD       => $payments_spool->{method},
       timeout      => $conf{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
    });

    $system_info = $Paysys->paysys_connect_system_list({
      PAYSYS_ID      => $payments_spool->{method},
      PAYMENT_METHOD => '_SHOW',
      COLS_NAME      => 1,
    });

    $method = $system_info->[0]{payment_method} || 0;

    if(defined $method){
      paysys_spool($payments_spool);
    }
  }

  return 1;
}

#**********************************************************
=head2 paysys_spool($attr)

=cut
#**********************************************************
sub paysys_spool {
  my $self = shift;
  my ($payments_spool) = '';

  my $Paysys = Paysys->new($db, $admin, \%conf);

  my $ext_info = '';
  my $paysys_id      = 0;

  my $list = $Paysys->list({ TRANSACTION_ID => "$payments_spool->{ext_id}", STATUS => '_SHOW', COLS_NAME => 1 });

  if ($Paysys->{TOTAL} == 0) {
    $ext_info = "PAYSYS_ID => $payments_spool->{method}, REQUEST => 'Request'";

    $Paysys->add(
      {
        SYSTEM_ID      => $payments_spool->{method},
        DATETIME       => "$DATE $TIME",
        SUM            => $payments_spool->{sum},
        UID            => $payments_spool->{uid},
        TRANSACTION_ID => "$payments_spool->{ext_id}",
        INFO           => "$ext_info",
        PAYSYS_IP      => '127.0.0.1',
        STATUS         => 2,
        USER_INFO      => $user
      }
    );

    $paysys_id = $Paysys->{INSERT_ID};

    if (!$Paysys->{errno}) {
      cross_modules_call('_payments_maked', {
        USER_INFO    => $user,
        PAYMENT_ID   => $payments_spool->{method},
        SUM          => $payments_spool->{sum},
        AMOUNT       => $payments_spool->{sum},
        SILENT       => 1,
        QUITE        => 1,
        timeout      => $conf{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
        SKIP_MODULES => 'Cards',
      });
    }
  }
  else {
    $paysys_id = $list->[0]->{id};
    if ($paysys_id && $list->[0]->{status} != 2) {

      $Paysys->change(
        {
          ID        => $paysys_id,
          STATUS    => 2,
          PAYSYS_IP => '127.0.0.1',
          INFO      => $ext_info,
          USER_INFO => $user
        }
      );
    }
  }
  return 1;
}

1;