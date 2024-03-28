=head1 NAME

  Paysys periodic functions

=cut

use strict;
use warnings;
use AXbills::Fetcher;
use Paysys;
use Payments;
use Users;
use Paysys::Init;

require Paysys::Configure;

our (
  %ADMIN_REPORT,
  $db,
  %conf,
  $admin,
  $html,
  %lang
);

my $Paysys = Paysys->new($db, $admin, \%conf);
#my $Payments = Finance->payments($db, $admin, \%conf);

#**********************************************************
=head2 paysys_periodic($attr)

  Arguments:
    $attr
      PAYSYS_ID

  Results:

=cut
#**********************************************************
sub paysys_periodic_new {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "Paysys: Daily periodic payments\n" if ($debug > 1);
  my $users = Users->new($db, $admin, \%conf);

  if (!$attr->{DATE_FROM}) {
    $attr->{DATE_FROM} = POSIX::strftime('%Y-%m-%d', localtime(time - 86400 * 3));
  }

  my $connected_systems_list = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
    PAYSYS_ID        => $attr->{PAYSYS_ID} ? $attr->{PAYSYS_ID} : '_SHOW',
  });

  foreach my $connected_system (@$connected_systems_list) {
    my $module = $connected_system->{module};
    my $name = $connected_system->{name};

    my $Module = _configure_load_payment_module($module);
    if ($Module->can('periodic')) {
      if ($debug > 2) {
        print "Paysys periodic: $module ($connected_system->{id}/$connected_system->{paysys_id})\n";
      }
      my $Paysys_module = $Module->new($db, $admin, \%conf, {
        USER        => $users,
        NAME        => $name,
        DEBUG       => $attr->{DEBUG},
        NAME        => $connected_system->{name},
        CUSTOM_NAME => $connected_system->{name},
        CUSTOM_ID   => $connected_system->{paysys_id},
      });

      $debug_output .= $Paysys_module->periodic($attr);

      if($Paysys_module->{errno}) {
        print "ERROR: $Paysys_module->{errno} $Paysys_module->{errstr}\n";
      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head paysys_monthly_new($attr) - Month periodic payments

  Arguments:
    $attr
      LOGIN
      PAYSYS_ID

  Results:

=cut
#**********************************************************
sub paysys_monthly_new {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "Paysys: Monthly periodic payments\n" if ($debug > 1);

  my %USERS_LIST_PARAMS = ();

  $USERS_LIST_PARAMS{LOGIN}     = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{GID}       = $attr->{GID} if ($attr->{GID});
  $USERS_LIST_PARAMS{UID}       = $attr->{UID} if ($attr->{UID});
  $USERS_LIST_PARAMS{DEPOSIT}   = $attr->{DEPOSIT} if ($attr->{DEPOSIT});

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
  my (undef, undef, $d) = split(/-/, $ADMIN_REPORT{DATE}, 3);
  my $START_PERIOD_DAY = $conf{START_PERIOD_DAY} || 1;

  if ($d != $START_PERIOD_DAY) {
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  if ($debug > 6) {
    $Paysys->{debug}=1;
  }

  my $connected_systems_list = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
    PAYSYS_ID        => $attr->{PAYSYS_ID} ? $attr->{PAYSYS_ID} : '_SHOW',
  });

  foreach my $connected_system (@$connected_systems_list) {
    my $module = $connected_system->{module};
    my $name = $connected_system->{name};

    my $Module = _configure_load_payment_module($module);
    if ($Module->can('subscribe_pay')) {
      if ($debug > 2) {
        print "Paysys periodic: $module ($connected_system->{id}/$connected_system->{paysys_id})\n";
      }
      my $Paysys_module = $Module->new($db, $admin, \%conf, {
        USER  => $users,
        NAME  => $name,
        DEBUG => $attr->{DEBUG}
      });

      my $paysys_user_list = $Paysys->user_list({
        PAYSYS_ID => $connected_system->{paysys_id},
        GID       => '_SHOW',
        DEPOSIT   => '_SHOW',
        %USERS_LIST_PARAMS,
        PAGE_ROWS => 100000,
        COLS_NAME => 1
      });

    foreach my $paysys_user (@$paysys_user_list) {
      my $token = $paysys_user->{token};
      my $sum = $paysys_user->{sum} || 0;
      my $paysys_id = $paysys_user->{paysys_id};
      my $order_id = $paysys_user->{order_id} || q{};

      print "UID: $paysys_user->{uid} PAYSYS_ID: $paysys_id SUM: $sum\n" if ($debug > 0);


        $Paysys_module->subscribe_pay({
          USER     => $paysys_user,
          SUM      => $sum,
          ORDER_ID => $order_id,
          TOKEN    => $token,
          PAYSYS   => $Paysys,
          DEBUG    => $debug
        });
    }

      if($Paysys_module->{errno}) {
        print "ERROR: $Paysys_module->{errno} $Paysys_module->{errstr}\n";
      }
    }

  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head paysys_periodic_electrum($attr) - P24 API

=cut
#**********************************************************
sub paysys_periodic_electrum {
  my ($attr) = @_;

  #my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  my $payment_system_id = 125;
  my $payment_system = 'Electrum';

  require Paysys::systems::Electrum;
  Paysys::systems::Electrum->import();
  my $Electrum = Paysys::systems::Electrum->new(\%conf);

  my $list = $Paysys->list({
    PAYMENT_SYSTEM => $payment_system_id,
    ID             => '_SHOW',
    SUM            => '_SHOW',
    TRANSACTION_ID => '_SHOW',
    STATUS         => 1,
    LIST2HASH      => 'transaction_id,status'
  });

  my $list2hash = $Paysys->{list_hash};

  my $list_requests = $Electrum->list_requests();

  foreach my $request (@$list_requests) {
    if ($list2hash->{"$payment_system:$request->{id}"}) {
      if ($request->{status} eq 'Paid') {
        my $paysys_status = paysys_pay(
          {
            PAYMENT_SYSTEM    => $payment_system,
            PAYMENT_SYSTEM_ID => $payment_system_id,
            #CHECK_FIELD       => $conf{PAYSYS_YANDEX_KASSA_ACCOUNT_KEY},
            #USER_ID           => $FORM{customerNumber},
            SUM               => ($request->{amount} / 100000000),
            ORDER_ID          => "$payment_system:$request->{id}",
            EXT_ID            => $request->{id},
            # REGISTRATION_ONLY => 1,
            DATA              => $request,
            MK_LOG            => 1,
            DEBUG             => 1,
          }
        );
      }
    }
  }

  return $debug_output;
}

1;
