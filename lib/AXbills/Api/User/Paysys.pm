package AXbills::Api::User::Paysys;
use strict;
use warnings FATAL => 'all';

sub list {
  return [
    {
      method              => 'GET',
      path                => '/user/:uid/paysys/systems/',
      handler             => 'paysys_connect_system_list({
          SHOW_ALL_COLUMNS  => 1,
          STATUS            => 1,
          COLS_NAME         => 1,
        });',
      module      => 'Paysys',
      credentials => [
        'USER'
      ]
    },
    {
      method              => 'POST',
      path                => '/user/:uid/paysys/pay/liqpay/',
      handler             => 'user_portal(
          {}, {
            API             => 1,
            UID             => :uid
          }
        );',
      module      => 'Paysys::systems::Liqpay',
      credentials => [
        'USER'
      ]
    },
  ]
}

1;