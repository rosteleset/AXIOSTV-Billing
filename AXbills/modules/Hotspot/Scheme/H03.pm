#!/usr/bin/perl

# Авторизация по мак-адресу
# Регистрация с триал-тарифом
# После завершения срока действия тестового тарифа, тариф изменяется на основной
# При недостаточном депозите - пользователя перенаправляет в кабинет

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 required_fields()

=cut
#**********************************************************
sub required_fields {
  my @keys = (
    'TRIAL_TP',    #Trial tariff
  );

  return \@keys;
}

#**********************************************************
=head2 scheme_radius_error()

=cut
#**********************************************************
sub scheme_radius_error {
  my $uid = get_user_uid();
  trial_tp_change($uid);
  user_portal_redirect();
  return 1;
}

#**********************************************************
=head2 scheme_pre_auth()

=cut
#**********************************************************
sub scheme_pre_auth {
  return 1;
}

#**********************************************************
=head2 scheme_auth()

=cut
#**********************************************************
sub scheme_auth {
  mac_login();
  return 1;
}

#**********************************************************
=head2 scheme_registration()

=cut
#**********************************************************
sub scheme_registration {
  hotspot_user_registration();
  return 1;
}

1;