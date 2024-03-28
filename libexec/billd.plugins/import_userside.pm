#!perl

=head1 import_userside

  Import userside plugins

  Arguments:
      USER_ID  - id of user if need
      REQUEST  - name of request
   conf Argumetns
      USER_SIDE_LINK   - Link to the userside
      USER_SIDE_APIKEY - Api key
      USER_SIDE_CAT    - Type of reqest
=cut

use AXbills::Base qw/cmd in_array convert startup_files _bp int2ip/;
use AXbills::Fetcher qw/web_request/;
use Users;
use Finance;
use AXbills::Misc qw/form_purchase_module _function get_function_index/;
use utf8;
use Log qw/log_print/;
use Contacts;

our ($db, $debug, $Admin, %permissions, $argv);

my $Payments = Finance->payments($db, $admin, \%conf);
my $Users = Users->new($db, $Admin, \%conf);
my $Log = Log->new($db, $Admin, \%conf);
my $Fees = Finance->fees($db, $admin, \%conf);
my $Contacts = Contacts->new($db, $admin, \%conf);

our %date_key_hash;

binmode STDOUT, ":utf8";

$date_key_hash{USERS} = {
  'login'       => 'LOGIN',
  'credit'      => 'CREDIT',
  'date_create' => 'REGISTRATION',
  'password'    => 'PASSWORD',
  'discount'    => 'REDUCTION',
  'state_id'    => 'DISABLE',

  # 'account_number'      => 'BILL_ID',
  # 'id'                  => 'ID',
  # 'full_name'           => 'FIO',
  # 'phone.number'        => 'PHON        E_NUMBER',
  #'balance'             => 'BALANCE',
  # 'password'
  # 'REDUCTION' => '',
  # 'REG' => '',
  # 'TP_ID' => '',
  # 'NOTIFY_FN' => '',
  # 'ACTION_COMMENTS' => '',
  # 'CREDIT_DATE' => '',
  # 'ACTIVATE' => '',
  # 'LOGIN' => 'aaaaaaaasds',
  # 'GID' => '',
  # 'NOTIFY_ID' => '',
  # 'REDUCTION_DATE' => '',
  # 'CREATE_BILL' => ' checked',
  # 'EXT_BILL_ID' => '',
  # 'COMP' => '',
  # 'step' => '',
  # 'BILL' => '',
  # 'EXPIRE' => '',
  # 'COMPANY_ID' => '',
  # 'DISABLE' => 2
};

$date_key_hash{USERS_PI} = {
  'address.apartment.number' => 'ADDRESS_FLAT',
  'address.house_id'         => 'ADDRESS_BUILD',
  'comment'                  => 'COMMENTS',
  'agreement.number'         => 'CONTRACT_ID',
  'agreement.date'           => 'CONTRACT_DATE',
  'email.address'            => 'EMAIL',
  'phone.number'             => 'PHONE:_phone_structure',
  'full_name'                => 'FIO',
};

$date_key_hash{DHCPHOSTS_HOSTS} = { 'ip_mac' => 'MAC:_mac_structure', };

$date_key_hash{USERS_PAYMENTS} = { 'balance' => 'SUM', };

import();

sub import {
  my $request_link = '';
  $LIST_PARAMS{USER_ID} = $argv->{USER_ID} ? "&customer_id=$argv->{USER_ID}" : '';
  my $us_link      = $conf{USER_SIDE_LINK}   || 'http://demo.userside.eu';
  my $us_apikey    = $conf{USER_SIDE_APIKEY} || 'keyus';
  my $us_cat       = $conf{USER_SIDE_CAT}    || 'module';
  $argv->{REQUEST} = $argv->{REQUEST} || 'get_user_list';

  $request_link = "$us_link/api.php?key=$us_apikey&cat=$us_cat&request=$argv->{REQUEST}$LIST_PARAMS{USER_ID}",

  my $users_list = web_request(
    $request_link,
    {
      JSON_RETURN => 1,
      JSON_UTF8   => 1,
      CURL        => 1,
    }
  );

  die "Couldn't get date info in Userside it!" unless defined $users_list;

  foreach my $user (sort keys %$users_list) {
    my %info;
    foreach my $param1 (keys %{ $users_list->{$user} }) {
      info_structure($users_list->{$user}->{$param1}, $param1, undef, \%info);
    }

    if ($debug > 10) {
      _bp('Data Structure', \%info, { TO_CONSOLE => 2 });
    }
    insert_user(\%info);
  }

  return 1;
}

sub info_coincidence {
  my ($attr) = @_;

  if (!defined($attr->{ELEMENT})) {
    return 0;
  }

  my $name_of_date = $attr->{LAST_KEY_ELEMENT} ? $attr->{LAST_KEY_ELEMENT} : $attr->{FULL_KEY};
  foreach my $key2 (keys %date_key_hash) {

    if ($date_key_hash{$key2}{$name_of_date}) {
      if (!defined($info->{$key2}->{ $date_key_hash{$key2}{$name_of_date} })) {
        return $attr->{ELEMENT};
      }

    }

  }

  return 0;
}

sub info_structure {
  my ($elemnt, $elemnt_last_key, $last_key, $info) = @_;

  my $coincidence_on = info_coincidence(
    {
      ELEMENT          => $elemnt,
      FULL_KEY         => $elemnt_last_key || '',
      LAST_KEY_ELEMENT => $last_key,
      INFO             => $info,
    }
  );

  if (ref($elemnt) eq 'HASH' && !$coincidence_on) {
    my $del_element = 0;
    foreach my $key (keys %{$elemnt}) {
      if ($del_element == 1) {
        ($elemnt_last_key) = $elemnt_last_key =~ /(.+)\./g;
      }
      if (ref($elemnt->{$key}) eq 'ARRAY' || ref($elemnt->{$key}) eq 'HASH') {
        $del_element = 1;
        $elemnt_last_key .= ".$key";
        info_structure($elemnt->{$key}, $elemnt_last_key, undef, $info);
      }
      else {
        $del_element = 0;
        info_structure($elemnt->{$key}, $elemnt_last_key, $key, $info);
      }
    }
  }
  elsif (ref($elemnt) eq 'ARRAY' && !$coincidence_on) {

    foreach my $value (@{$elemnt}) {

      info_structure($value, $elemnt_last_key, undef, $info);
    }
  }

  if ((ref($elemnt) ne 'ARRAY' && ref($elemnt) ne 'HASH') || $coincidence_on) {
    $elemnt_last_key = $last_key ? $elemnt_last_key . ".$last_key" : $elemnt_last_key;

    if (ref($elemnt) ne 'ARRAY' && ref($elemnt) ne 'HASH') {
      $elemnt = $elemnt ? "$elemnt" : "";
    }
    else {
      $elemnt = $coincidence_on ? $coincidence_on : $elemnt_last_key;
    }

    if ($debug > 10) {
      print $elemnt_last_key . " = ";
      print $elemnt . "\n";
    }

    if ($elemnt) {
      foreach my $key2 (keys %date_key_hash) {

        if ($date_key_hash{$key2}{$elemnt_last_key}) {
          my ($element_name, $func_name) = split(':', $date_key_hash{$key2}{$elemnt_last_key}, 2);

          if (!defined($func_name)) {
            $info->{$key2}->{$element_name} = $elemnt;
          }
          else {
            $info->{$key2}->{$element_name} = $func_name->($elemnt, $info->{$key2}->{$element_name});
          }
        }

      }
    }
  }

  return 1;
}

sub _mac_structure {
  my ($mac_list, $hash_ref, $attr) = @_;

  foreach my $mac_info (%{$mac_list}) {

    if ($mac_info->{mac} && $mac_info->{ip}) {
      my $usr_mac = join(':', unpack("(A2)*", $mac_info->{mac}));

      return { MAC => $usr_mac, IP => int2ip($mac_info->{ip}) };
    }
  }

  return 0;
}

sub _phone_structure {
  my ($phone, $hash_ref, $attr) = @_;

  if ($hash_ref && $hash_ref =~ s/\d//) {
    return $hash_ref;
  }
  elsif ($phone && $phone =~ s/\d//) {
    return $phone;
  }

}

sub insert_user {
  my ($user_info) = @_;

  my $Finance    = Finance->new($db, $admin, \%conf);
  my $uid        = 0;
  my $change_log = q{};
  my $login      = $user_info->{USERS}->{LOGIN} || q{};

  $user_info->{USERS}->{PASSWORD} = $user_info->{USERS}->{PASSWORD} || '';
  my $password = $user_info->{USERS}->{PASSWORD};

  $user_info->{USERS}->{DISABLE} = undef($user_info->{USERS}->{DISABLE}) && $user_info->{USERS}->{DISABLE} == 2 ? 0 : 1;

  if ($user_info->{USERS_PI}->{CONTRACT_DATE}) {
    $user_info->{USERS_PI}->{CONTRACT_DATE} = year_month_day_format($user_info->{USERS_PI}->{CONTRACT_DATE});
  }

  my Users $user = $Users->add({ %{ $user_info->{USERS} }, CREATE_BILL => 1, });

  if ($user->{errno} && $user->{errno} == 7) {

    change_user($user_info);

    return 1;
  }

  elsif ($user->{errno}) {
    print "Error " . $user->{errno} . " when add user into date base" . $user->{errstr} . "\n";
    return 1;
  }

  if (!$user->{errno}) {
    print "\n" . 'Add user UID = ' . $user->{UID} . "\n" if ($debug > 9);

    $uid  = $user->{UID};
    $user = $user->info($uid);

    #2 PASSWORD
    if (defined($password) && $password ne '') {
      if (length($password) < $conf{PASSWD_LENGTH}) {
        print 'Too big password length' . "\n" if ($debug > 9);
      }
      else {
        $user->change(
          $uid,
          {
            PASSWORD => $password,
            UID      => $uid,
            DISABLE  => $user_info->{USERS}->{DISABLE},
          }
        );

        if ($user->{errno}) {
          print "Error " . $user->{errno} . " when add user password " . $user->{errstr} . "\n";
          return 1;
        }

        if (!$user->{errno}) {
          print "\n" . 'Add user password  = ' . $password . "\n" if ($debug > 9);
        }

        if ($conf{external_useradd}) {
          if (
            !_external(
              $conf{external_useradd},
              {
                LOGIN    => $login,
                PASSWORD => $password,
                UID      => $uid,
                DISABLE  => $user_info->{USERS}->{DISABLE},
              }
            )
          )
          {
            return 0;
          }
        }
      }
    }

    #3 personal info
    $user->pi_add({ UID => $uid, %{ $user_info->{USERS_PI} }, });

    $Contacts->contacts_add({
      TYPE_ID => 1,
      VALUE   => $user_info->{USERS_PI}->{PHONE},
      UID     => $uid,
    }) if ($user_info->{USERS_PI}->{PHONE});

    $Contacts->contacts_add({
      TYPE_ID => 9,
      VALUE   => $user_info->{USERS_PI}->{EMAIL},
      UID     => $uid,
    }) if ($user_info->{USERS_PI}->{PHONE});

    #5 Payments section

    if ($user_info->{USERS_PAYMENTS}->{SUM}) {
      add_payment($user, $Fees, $user_info->{USERS_PAYMENTS});
    }

    #6 DHSP Hosts
    if ($user_info->{DHCPHOSTS_HOSTS}->{MAC}) {
      require Dhcphosts;

      my $Dhcphosts = Dhcphosts->new($db, $Admin, \%conf);

      $Dhcphosts->host_add(
        {
          UID      => $uid,
          HOSTNAME => $user_info->{USERS}->{LOGIN},
          IP       => $user_info->{DHCPHOSTS_HOSTS}->{MAC}->{IP},
          MAC      => $user_info->{DHCPHOSTS_HOSTS}->{MAC}->{MAC},
        }
      );
    }

    $Log->log_print('LOG_USER_ADD', $user_info->{USERS}->{LOGIN}, "UID:$uid", { LOG_FILE => "/usr/axbills/var/log/import_userside_log" });
  }
}

sub change_user {
  my ($attr) = @_;

  my $change_log = '';

  # print '$attr->{USERS}->{LOGIN}' . $attr->{USERS}->{LOGIN} . "\n";

  my $user_old_info = $Users->info(undef, { LOGIN => $attr->{USERS}->{LOGIN}, });

  my $uid = $user_old_info->{UID};

  my $user_change_result = $Users->change(
    $uid,
    {
      UID => $uid,
      %{ $attr->{USERS} }
    }
  );

  $change_log .= "\n    *User main info:\n $Users->{CHANGES_LOG}" if ($Users->{CHANGES_LOG});
  $Users->{CHANGES_LOG} = '';

  my $user_pi_change_result = $Users->pi_change({
    UID => $uid,
    %{$attr->{USERS_PI}}
  });

  $Contacts->contacts_add({
    TYPE_ID => 1,
    VALUE   => $attr->{USERS_PI}->{PHONE},
    UID     => $uid,
  }) if ($attr->{USERS_PI}->{PHONE});

  $Contacts->contacts_add({
    TYPE_ID => 9,
    VALUE   => $attr->{USERS_PI}->{EMAIL},
    UID     => $uid,
  }) if ($attr->{USERS_PI}->{EMAIL});

  $change_log .= "\n   *User personal info:\n$Users->{CHANGES_LOG}" if ($Users->{CHANGES_LOG});
  $Users->{CHANGES_LOG} = '';

  #5 Payments section

  # if ($user_info->{USERS_PAYMENTS}->{SUM}) {
  #   $change_log  .= add_payment($user, $Fees, $user_info->{USERS_PAYMENTS});
  # }
  #  if($attr->{DHCPHOSTS_HOSTS}->{MAC}){
  #   require Dhcphosts;
  #   my $Dhcphosts = Dhcphosts->new($db, $Admin, \%conf);

  #   $Dhcphosts->host_change(
  #   {
  #    UID => $uid,
  #    HOSTNAME => $attr->{USERS}->{LOGIN},
  #    IP  => $attr->{DHCPHOSTS_HOSTS}->{MAC}->{IP},
  #    MAC => $attr->{DHCPHOSTS_HOSTS}->{MAC}->{MAC},
  #  }
  #  );

  # }
  $Log->log_print('LOG_USER_CHANGE', $user_old_info->{LOGIN}, "UID:$user_old_info->{UID} $change_log", { LOG_FILE => "/usr/axbills/var/log/import_userside.log" });

  return 1;
}

sub add_payment {
  my ($user, $Fees, $attr) = @_;
  my $change_log;

  $attr->{SUM} =~ s/,/\./g;
  if ($attr->{SUM} > 0) {
    $Payments->add($user, { %{$attr} });

    if ($Payments->{errno} && $debug > 9) {
      $change_log .= "\n   *User payments info:\n" . _error_show($Payments, { MODULE_NAME => $lang{PAYMENTS} });
      return $change_log;
    }
    else {
      $change_log .= "\n   *User payments info:\n$Payments->{CHANGES_LOG}" if ($Payments->{CHANGES_LOG});
    }
  }
  elsif ($attr->{SUM} < 0) {

    # my $er = ($FORM{'5.ER'}) ? $Finance->exchange_info($FORM{'5.ER'}) : { ER_RATE => 1 };
    $Fees->take($user, abs($attr->{SUM}), { DESCRIBE => 'MIGRATION' });

    if ($Fees->{errno} && $debug > 9) {
      $change_log .= "\n   *User payments info:\n" . $Fees->{errno};
      return $change_log;
    }
    else {
      $change_log .= "\n   *User payments info:\n$Fees->{CHANGES_LOG}" if ($Fees->{CHANGES_LOG});
    }
  }

  return $change_log;
}

sub year_month_day_format {
  my ($date) = @_;

  my ($contract_day, $contract_month, $contract_year) = split(/\./, $date, 3);

  return "$contract_year-$contract_month-$contract_day";
}

1
