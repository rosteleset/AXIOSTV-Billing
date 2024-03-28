#!/usr/bin/perl

# Верификация телефона с помощью звонка на указанный номер
# Авторизация по номеру телефона
# Регистрация только после оплаты тарифа

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 required_fields()

=cut
#**********************************************************
sub required_fields {
  my @keys = (
    'AUTH_NUMBER', #Number for verification phone
    'PAYMENT_URL', #url for fast online pay
  );

  return \@keys;
}

#**********************************************************
=head2 scheme_radius_error()

=cut
#**********************************************************
sub scheme_radius_error {
  my ($error) = @_;
  recharge_balance() if ($error =~ /NEG_DEPOSIT/);
  return 1;
}

#**********************************************************
=head2 scheme_pre_auth()

=cut
#**********************************************************
sub scheme_pre_auth {
  return 1 if check_phone_verify();
  ask_phone();
  verify_call();
  return 1;
}

#**********************************************************
=head2 scheme_auth()

=cut
#**********************************************************
sub scheme_auth {
  cookie_login();
  phone_login();
  return 1;
}

#**********************************************************
=head2 scheme_registration()

=cut
#**********************************************************
sub scheme_registration {
  choose_tp();
  hotspot_user_registration({ANY_MAC => 1, RECHARGE => 1});
  return 1;
}

1;