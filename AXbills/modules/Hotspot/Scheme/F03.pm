#!/usr/bin/perl

# Верификация телефона с помощью отправки смс с пин-кодом
# Авторизация по номеру телефона
# Регистрация с тарифом по умолчанию

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 required_fields()

=cut
#**********************************************************
sub required_fields {
  my @keys = ();

  return \@keys;
}

#**********************************************************
=head2 scheme_radius_error()

=cut
#**********************************************************
sub scheme_radius_error {
  return 1;
}

#**********************************************************
=head2 scheme_pre_auth()

=cut
#**********************************************************
sub scheme_pre_auth {
  return 1 if check_phone_verify();
  ask_phone();
  ask_pin();
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
  hotspot_user_registration({ ANY_MAC => 1 });
  return 1;
}

1;