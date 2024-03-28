=head1 NAME

  Userside API

  VERSION: 0.38
  UPDATED: 2021.01.26

  USERSIDE API:
  VERSION: 1.7
  DATE: 06.10.2017
  URL: http://wiki.userside.eu/%D0%A3%D0%BD%D0%B8%D0%B2%D0%B5%D1%80%D1%81%D0%B0%D0%BB%D1%8C%D0%BD%D0%BE%D0%B5_API

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw();
use AXbills::Misc;
our ($html, %FORM, $db, %conf, $admin, %lang, $DATE);

my $max_page_rows = $conf{US_API_MAX_PAGE_ROWS} || 10000;
my $start_page = 0;
my $debug = $conf{US_API_DEBUG} || 0;

require AXbills::JSON;

$FORM{json} = 1;
$html = AXbills::JSON->new(
  {
    CONF     => \%conf,
    NO_PRINT => 1,
    CHARSET  => $conf{default_charset},
  }
);

#**********************************************************
=head2 _json_former($request) - Format JSON curl string  from different date

=cut
#**********************************************************
sub _json_former {
  my ($request) = @_;
  my @text_arr = ();

  if (ref $request eq 'ARRAY') {
    foreach my $key (@{$request}) {
      push @text_arr, _json_former($key);
    }
    return '[' . join(', ', @text_arr) . "]";
  }
  elsif (ref $request eq 'HASH') {
    foreach my $key (keys %{$request}) {
      my $val = _json_former($request->{$key});
      push @text_arr, qq{ \"$key\" : $val };
    }
    return '{' . join(', ', @text_arr) . "}";
  }
  else {
    $request //= '';
    if ($request =~ '^[0-9]+$') {
      return qq{$request};
    }
    else {
      $request =~ s/<str_>//;
      $request =~ s/\\/\\\\/g;
      $request =~ s/\"/\\\"/g;
      #$request =~ s/[\r\n\t]//g;
      #$request =~ s/\w//g;
      $request =~ s/[\x{00}-\x{1f}]+//ig;

      return qq{ \"$request\" };
    }
  }
}

#*******************************************************************
=head2 userside_api($request, $attr)

  Arguments:
    $request
    $attr
      MAX_ROWS
      START_PAGE
      UID

  Returns:
    True or FALSE

=cut
#*******************************************************************
sub userside_api {
  my ($request, $attr) = @_;

  if($attr->{MAX_ROWS}) {
    $max_page_rows=$attr->{MAX_ROWS};
  }

  if ($attr->{START_PAGE}) {
    $start_page = $attr->{START_PAGE};
  }

  if($attr->{DEBUG}) {
    $debug=$attr->{DEBUG};
  }

  if (!$request) {
    push @{$html->{JSON_OUTPUT}}, qq/  { "ERROR" : "Userside API function: can't find request parameter" } /;
  }
  elsif ($request && defined(&$request)) {
    my $return = &{\&$request}($attr);
    push @{$html->{JSON_OUTPUT}}, $return;
  }
  else {
    push @{$html->{JSON_OUTPUT}}, qq/  { "ERROR" : "Userside API function: $request not defined" } /;
  }

  if (!$ENV{DEBUG}) {
    print $html->header();
  }

  $html->fetch({ FULL_RESULT => 1, DEBUG => $ENV{DEBUG} });

  return 1;
}

#*******************************************************************
=head2 get_api_information()

=cut
#*******************************************************************
sub get_api_information {

  my $version = get_version();
  my $date = $DATE;

  my %hash = (
    version => $version,
    date    => $date
  );

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_city_district_list()

=cut
#*******************************************************************
sub get_city_district_list {
  require Address;

  my $Address = Address->new($db, $admin, \%conf);
  my $list = $Address->district_list({ COLS_NAME => 1, PAGE_ROWS => 100000 });
  my %hash = ();

  foreach my $district (@$list) {
    $hash{$district->{id}}{id} = $district->{id};
    $hash{$district->{id}}{name} = '<str_>' . $district->{name};
    $hash{$district->{id}}{city_id} = $district->{id};
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_city_list()

=cut
#*******************************************************************
sub get_city_list {
  require Address;
  my $Address = Address->new($db, $admin, \%conf);
  my $list = $Address->district_list({ COLS_NAME => 1, PAGE_ROWS => 100000 });
  my %hash = ();
  foreach my $district (@$list) {
    $hash{$district->{id}}{id} = $district->{id};
    $hash{$district->{id}}{name} = '<str_>' . $district->{city};
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_device_list()

=cut
#*******************************************************************
sub get_device_list {
  require Equipment;
  my $Equipment = Equipment->new($db, $admin, \%conf);

  my $list = $Equipment->_list(
    {
      NAS_NAME     => '_SHOW',
      MODEL_NAME   => '_SHOW',
      MAC          => '_SHOW',
      NAS_IP       => '_SHOW',
      SNMP_VERSION => '_SHOW',
      NAS_ID       => '_SHOW',
      LOCATION_ID  => '_SHOW',
      COLS_NAME    => 1,
      PAGE_ROWS    => 100000,
    }
  );

  my %hash = ();
  foreach my $equipment (@$list) {
    $hash{$equipment->{id}}{id} = $equipment->{id};
    $hash{$equipment->{id}}{model_id} = $equipment->{nas_id};
    $hash{$equipment->{id}}{mac} = $equipment->{mac};
    $hash{$equipment->{id}}{ip} = $equipment->{nas_ip};
    $hash{$equipment->{id}}{snmp_version} = '<str_>'.$equipment->{snmp_version};
    $hash{$equipment->{id}}{house_id} = $equipment->{location_id} || 0;
    $hash{$equipment->{id}}{mac} = $equipment->{mac};
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_device_list()

=cut
#*******************************************************************
sub get_device_model {

  require Equipment;
  my $Equipment = Equipment->new($db, $admin, \%conf);
  my $list = $Equipment->model_list({
    TYPE_ID   => '_SHOW',
    PORTS     => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => $max_page_rows
  });

  my %hash = ();
  foreach my $model (@$list) {
    $hash{$model->{id}}{id} = $model->{id};
    $hash{$model->{id}}{type_id} = '<str_>'.$model->{type_id};
    $hash{$model->{id}}{name} = '<str_>' . ($model->{model_name} || q{});
    $hash{$model->{id}}{iface_count} = $model->{ports};
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_device_list()

=cut
#*******************************************************************
sub get_device_type {

  require Equipment;
  my $Equipment = Equipment->new($db, $admin, \%conf);
  my $list = $Equipment->type_list({
    COLS_NAME => 1,
    PAGE_ROWS => $max_page_rows
  });

  my %hash = ();
  foreach my $type (@$list) {
    $hash{$type->{id}}{id} = '<str_>'.$type->{id};
    $hash{$type->{id}}{name} = '<str_>'.$type->{name};
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_house_list()

=cut
#*******************************************************************
sub get_house_list {

  require Address;
  my $Address = Address->new($db, $admin, \%conf);

  if($debug > 5) {
    $Address->{debug}=1;
  }

  my $list = $Address->build_list(
    {
      LOCATION_ID   => '_SHOW',
      CITY          => '_SHOW',
      DISTRICT_NAME => '_SHOW',
      STREET_NAME   => '_SHOW',
      STREET_ID     => '_SHOW',
      NUMBER        => '_SHOW',
      FLORS         => '_SHOW',
      ENTRANCES     => '_SHOW',
      COORDX        => '_SHOW',
      COORDY        => '_SHOW',
      DISTRICT_ID   => '_SHOW',
      ZIP           => '_SHOW',
      WITH_STREETS_ONLY => 1,
      COLS_NAME     => 1,
      PAGE_ROWS     => $max_page_rows,
    }
  );

  my %hash = ();
  foreach my $build (@$list) {
    $hash{$build->{location_id}}{id} = $build->{id} || 0;
    $hash{$build->{location_id}}{city} = '<str_>' . ($build->{city} || q{});
    $hash{$build->{location_id}}{full_name} = '<str_>' . ($build->{city} || q{}) . ', '
      . ($build->{district_name} || q{}) . ', ' . ($build->{street_name} || q{}) . ', ' . ($build->{number} || q{});
    $hash{$build->{location_id}}{city_district_id} = $build->{district_id} || 0;
    $hash{$build->{location_id}}{street_id} = $build->{street_id} || 0;
    $hash{$build->{location_id}}{postcode} = $build->{zip} || 0;
    $hash{$build->{location_id}}{floor} = $build->{flors} || 0;
    $hash{$build->{location_id}}{entrance} = $build->{entrances} || 0;
    $hash{$build->{location_id}}{number} = '<str_>' . ($build->{number} || q{}); # ($build->{number} =~ /^\d+$/) ? $build->{number} : 0;
    if($build->{coordx} && $build->{coordy}  && $build->{coordx} + $build->{coordy} > 0) {
      $hash{$build->{location_id}}{coordinates} = [ ($build->{coordx} || 0), ($build->{coordy} || 0) ];
    }
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_street_list()

=cut
#*******************************************************************
sub get_street_list {

  require Address;
  my $Address = Address->new($db, $admin, \%conf);

  if($debug > 5) {
    $Address->{debug}=1;
  }

  my $list = $Address->address_list();
  my %hash = ();

  foreach my $address (@$list) {
    $hash{$address->{street_id}}{id}      = $address->{street_id};
    $hash{$address->{street_id}}{city_id} = $address->{district_id};
    $hash{$address->{street_id}}{name}    = $address->{street_name};
    #$hash{$address->{STREET_ID}}{type_name} = '';
    $hash{$address->{street_id}}{full_name} = $address->{street_name};
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_system_information()

=cut
#*******************************************************************
sub get_system_information {

  my $version = get_version();

  my %hash = (
    date => "$DATE $TIME",
    os   => 'Unix',
    billing  => {
      name    => 'ABillS',
      version => $version,
    }
  );

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_tariff_list()

=cut
#*******************************************************************
sub get_tariff_list {

  require Tariffs;
  my $Tariffs = Tariffs->new($db, $admin, \%conf);
  if($debug > 5) {
    $Tariffs->{debug}=1;
  }
  my $list = $Tariffs->list({
    MONTH_FEE => '_SHOW',
    DAY_FEE   => '_SHOW',
    IN_SPEED  => '_SHOW',
    OUT_SPEED => '_SHOW',
    NAME      => '_SHOW',
    NEW_MODEL_TP => 1,
    COLS_NAME => 1,
    PAGE_ROWS => $max_page_rows
  });

  my $payment_interval = 0;
  my %hash = ();

  foreach my $tariff (@$list) {
    $payment_interval = 0;
    if ($tariff->{month_fee} && $tariff->{month_fee} > 0) {
      $payment_interval = 30;
    }
    elsif ($tariff->{day_fee} && $tariff->{day_fee} > 0) {
      $payment_interval = 1;
    }

    $hash{$tariff->{tp_id}}{id} = $tariff->{tp_id};
    $hash{$tariff->{tp_id}}{name} = '<str_>'.$tariff->{name};
    $hash{$tariff->{tp_id}}{payment} = $tariff->{month_fee} || $tariff->{day_fee};
    $hash{$tariff->{tp_id}}{payment_interval} = $payment_interval;
    $hash{$tariff->{tp_id}}{speed}{up} = ($tariff->{in_speed} || 0);
    $hash{$tariff->{tp_id}}{speed}{down} = ($tariff->{out_speed} || 0);
    $hash{$tariff->{tp_id}}{traffic} = 0;
    $hash{$tariff->{tp_id}}{service_type} = 0;
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_user_additional_data_type_list()

=cut
#*******************************************************************
sub get_user_additional_data_type_list {
  require Info_fields;

  my $Info_fields = Info_fields->new($db, $admin, \%conf);
  my $list = $Info_fields->fields_list({
    COLS_NAME => 1,
    PAGE_ROWS => $max_page_rows
  });

  my %hash = ();
  foreach my $field (@$list) {
    $hash{$field->{id}}{id} = $field->{id};
    $hash{$field->{id}}{name} = "<str_>" . $field->{name};
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_user_messages()

=cut
#*******************************************************************
sub get_user_messages {
  require Msgs;

  my $Msgs = Msgs->new($db, $admin, \%conf);
  my $list = $Msgs->messages_list(
    {
      SUBJECT   => '_SHOW',
      MESSAGE   => '_SHOW',
      DATE      => '_SHOW',
      COLS_NAME => 1,
      PAGE_ROWS => $max_page_rows,
    }
  );
  my %hash = ();

  foreach my $message (@$list) {
    $hash{$message->{id}}{id} = $message->{id};
    $hash{$message->{id}}{user_id} = $message->{uid};
    $hash{$message->{id}}{msg_date} = $message->{date};
    $hash{$message->{id}}{subject} = "<str_>" . ($message->{subject} || q{});
    $hash{$message->{id}}{text} = "<str_>" . ($message->{message} || q{});
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_user_group_list()

=cut
#*******************************************************************
sub get_user_group_list {
  require Users;

  my $users = Users->new($db, $admin, \%conf);

  if($debug > 5) {
    $users->{debug}=1;
  }

  my $list = $users->groups_list({
    NAME      => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => $max_page_rows
  });

  my %hash = ();

  foreach my $group (@$list) {
    $hash{$group->{id}}{id} = $group->{id};
    $hash{$group->{id}}{name} = '<str_>' . ($group->{name} || q{});
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_user_list($attr)

  Arguments:
    $attr
      UID
      SKIP_TRAFFIC

  Results:


=cut
#*******************************************************************
sub get_user_list {
  my($attr) = @_;

  my $skip_traffic = $attr->{SKIP_TRAFFIC} || $conf{USERSIDE_SKIP_TRAFFIC} || 0;

  require Internet;
  my $Internet = Internet->new($db, $admin, \%conf);

  if($debug > 6) {
    $Internet->{debug}=1;
  }

  my %users_list_params = (
    UID                => $attr->{UID},
    PASSWORD           => '_SHOW',
    PHONE              => '_SHOW',
    EMAIL              => '_SHOW',
    LOGIN              => '_SHOW',
    ADDRESS_FLAT       => '_SHOW',
    DEPOSIT            => '_SHOW',
    PASSWORD           => '_SHOW',
    CREDIT             => '_SHOW',
    FIO                => '_SHOW',
    DEPOSIT            => '_SHOW',
    COMMENTS           => '_SHOW',
    REDUCTION          => '_SHOW',
    BILL_ID            => '_SHOW',
    REGISTRATION       => '_SHOW',
    ACTIVATE           => '_SHOW',
    CREDIT             => '_SHOW',
    COMPANY_ID         => '_SHOW',
    BILL_ID            => '_SHOW',
    INTERNET_STATUS_ID => '_SHOW',
    IP_NUM             => '_SHOW',
    CID                => '_SHOW',
    CPE_MAC            => '_SHOW',
    ADDRESS_BUILD      => '_SHOW',
    ADDRESS_FLAT       => '_SHOW',
    FLOOR              => '_SHOW',
    ENTRANCE           => '_SHOW',
    GID                => '_SHOW',
    ONLINE             => '_SHOW',
    LOCATION_ID        => '_SHOW',
    CONTRACT_ID        => '_SHOW',
    CONTRACT_DATE      => '_SHOW',
    TAGS               => '_SHOW',
    TAGS_DATE          => '_SHOW',
    TAGS_ID            => '_SHOW',
    PG                 => $start_page,
    COLS_NAME          => 1,
    PAGE_ROWS          => $max_page_rows,
    SKIP_DEL_CHECK     => $conf{US_API_SYNC_DELETED} || 0
  );

  if(! $skip_traffic) {
    $users_list_params{MONTH_TRAFFIC_IN}  = '_SHOW';
    $users_list_params{MONTH_TRAFFIC_OUT} = '_SHOW';
    $users_list_params{LAST_ACTIVITY}     = '_SHOW';
  }

  my $list = $Internet->list(\%users_list_params);

  my %hash = ();
  foreach my $user (@$list) {
    $hash{$user->{uid}}{id} = "<str_>" . ($user->{uid} || '');
    $hash{$user->{uid}}{login} = "<str_>" . ($user->{login} || '');
    $hash{$user->{uid}}{full_name} = "<str_>" . ($user->{fio} || '');
    $hash{$user->{uid}}{flag_corporate} = ($user->{company_id} || 0);
    if ($user->{tp_id}) {
      $hash{$user->{uid}}{tariff}{current}{$user->{tp_id}}{id} = $user->{tp_id};
    }

    $hash{$user->{uid}}{state_id} = $user->{internet_status_id} || 0;
    $hash{$user->{uid}}{traffic}{month}{up} = $user->{month_traffic_in} || 0;
    $hash{$user->{uid}}{traffic}{month}{down} = $user->{month_traffic_out} || 0;

    my $build_number = 0;

    if ($user->{address_build} && $user->{address_build} =~ /\d+/) {
      $build_number = $1;
    }

    $hash{$user->{uid}}{address} = [
      {
        house_id  => $user->{build_id} || 0, #($build_number || 0),
        type      => "connect",
        apartment => {
          full_name => "<str_>" . ($user->{address_flat} || ''),
          number    => "<str_>" . ($user->{address_flat} || '')
        },
      }
    ];

    if ($user->{floor}) {
      $hash{$user->{uid}}{address}[0]{floor} = "<str_>" . ($user->{floor} || ""),
    }

    if ($user->{entrance}) {
      $hash{$user->{uid}}{address}[0]{entrance} = $user->{entrance} || 0,
    }

    $hash{$user->{uid}}{agreement} = [
      {
        number => '<str_>'.($user->{contract_id} || ''),
        date   => $user->{contract_date}
      }
    ];

    if($user->{comments}) {
      $user->{comments} =~ s/\n/\\n/g;
    }

    $hash{$user->{uid}}{comment} = "<str_>" . ($user->{comments} || '');
    $hash{$user->{uid}}{balance} = "<str_>" . sprintf("%.2f", ($user->{deposit} || 0));
    $hash{$user->{uid}}{credit} = ($user->{credit} || 0);

    $hash{$user->{uid}}{discount} = "<str_>" . $user->{reduction};
    $hash{$user->{uid}}{phone} = [ { number => "<str_>" . ($user->{phone} || ''), flag_main => 1 } ];
    $hash{$user->{uid}}{email} = [ { address => "<str_>" . ($user->{email} || ''), flag_main => 1 } ];

    my $password = $user->{password};

    #if ($password && $password !~ /^[a-z0-9\!\@\#\$\%\^\&\*\(\)\_\-\+\=\[\{\]\};:<>\|\,\.\?]+$/ig) {
    #  $password = q{no word symbols};
    #}

    $hash{$user->{uid}}{password}      = "<str_>" . ($password || '');
    $hash{$user->{uid}}{billing_id}    = "<str_>" . ($user->{uid} || '');
    $hash{$user->{uid}}{date_create}   = $user->{registration}. ' 00:00:00';
    $hash{$user->{uid}}{date_connect}  = $hash{$user->{uid}}{date_create};

    if ($user->{ip_num}) {
      $hash{$user->{uid}}{ip_mac}{$user->{ip_num}}{ip} = "<str_>" . ($user->{ip_num} || '');
    }

    if ($user->{cid}) {
      my $cid = $user->{cid} || '';
      $cid = lc($cid);
      $cid =~ s/[:\-\.]+//g;
      $hash{$user->{uid}}{ip_mac}{$user->{ip_num}}{mac} = "<str_>" . $cid;
    }

    if ($user->{cpe_mac}) {
      my $cpe_mac = $user->{cpe_mac} || '';
      $cpe_mac = lc($cpe_mac);
      $cpe_mac =~ s/[:\-\.]+//g;

      $hash{$user->{uid}}{ip_mac}{$user->{ip_num}}{cpe_mac} = "<str_>" . $cpe_mac;
    }

    if($user->{online}) {
      $hash{$user->{uid}}{date_activity} = "$DATE $TIME";
    }
    elsif($user->{last_updated}) {
      $hash{$user->{uid}}{date_activity} = $user->{last_updated};
    }

    $hash{$user->{uid}}{account_number}="<str_>" . ($user->{uid} || '');
    $hash{$user->{uid}}{group}{$user->{gid}}{id} = $user->{gid};

    my @tags = ();

    if($user->{tags}) {
      my @tags_date = split(/, /, $user->{tags_date});
      my @tags_id   = split(/, /, $user->{tags_id});

      my $i=0;
      foreach my $tag_id ( @tags_id ) {
        push @tags, { id => "<str_>" . ($tag_id || ''), date_add => $tags_date[$i] };
        $i++;
      }

      $hash{$user->{uid}}{tag}=[ @tags ];
    }
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_user_state_list()

=cut
#*******************************************************************
sub get_user_state_list {
  require Service;

  my %axbills2userside_status = (
    0 => "work",
    1 => "disable",
    2 => "new",
    3 => "pause",
    4 => "nomoney",
    5 => "nomoney",
    6 => "stop",
    7 => "stop",
    8 => "stop",
    9 => "stop",
    10=> "stop",
  );

  my $Service = Service->new($db, $admin, \%conf);
  my $list = $Service->status_list({
    COLS_NAME => 1,
    PAGE_ROWS => $max_page_rows,
    NAME      => '_SHOW'
  });

  my %hash = ();

  foreach my $status (@$list) {
    $hash{$status->{id}}{id}         = $status->{id};
    $hash{$status->{id}}{name}       = _translate($status->{name});
    $hash{$status->{id}}{functional} = $axbills2userside_status{$status->{id}};
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_user_tags()

=cut
#*******************************************************************
sub get_user_tags {
  require Tags;
  Tags->import();
  my $Tags = Tags->new($db, $admin, \%conf);
  my $list = $Tags->list({
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    NAME      => '_SHOW'
  });

  my %hash = ();

  foreach my $tag (@$list) {
    $hash{$tag->{id}}{id}   = $tag->{id};
    $hash{$tag->{id}}{name} = $tag->{name};
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_user_history()

=cut
#*******************************************************************
sub get_user_history {
  require Admins;

  my $Admins = Admins->new($db, $admin, \%conf);
  my $list = $Admins->action_list({
    TYPE      => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => $max_page_rows,
  });

  my %hash = ();

  foreach my $action (@$list) {
    $hash{$action->{id}}{id} = $action->{id};
    $hash{$action->{id}}{date} = $action->{datetime};
    $hash{$action->{id}}{customer_id} = $action->{uid};
    $hash{$action->{id}}{type} = ($action->{action_type} || 0);
    $hash{$action->{id}}{name} = '<str_>' . ($action->{action_type} || q{});
    my $action_text = $action->{actions};
    $hash{$action->{id}}{data} = '<str_>' . ($action_text || q{});
    $hash{$action->{id}}{comment} = $action->{aid};
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_services_list()

=cut
#*******************************************************************
sub get_services_list {
  require Users;
  my $users = Users->new($db, $admin, \%conf);
  my %hash = ();
  my $hash_id = 0;

  my $users_list = $users->list({
    UID        => 1,
    COLS_NAME  => 1,
    PAGE_ROWS  => 100000,
    COLS_UPPER => 1,
    REDUCTION  => '_SHOW'
  });

  foreach my $line (@$users_list) {
    my $cross_modules_return = cross_modules_call('_docs', { });

    foreach my $module (sort keys %$cross_modules_return) {
      if (ref $cross_modules_return->{$module} eq 'ARRAY') {
        next if ($#{$cross_modules_return->{$module}} == -1);
        foreach my $module_return (@{$cross_modules_return->{$module}}) {
          my $serv_desc = '';
          ($hash{$hash_id}{name}, $serv_desc, $hash{$hash_id}{cost}) = split(/\|/, $module_return);

          $hash{$hash_id}{cost} = "<str_>". $hash{$hash_id}{cost};

          $hash{$hash_id}{id} = $hash_id;
          $hash_id++;
        }
      }
    }
  }

  return _json_former(\%hash);
}

#*******************************************************************
=head2 get_supported_method_list()

=cut
#*******************************************************************
sub get_supported_method_list {

  my %hash = ();

  $hash{get_supported_method_list}{comment} = 'Return Supported Method List';
  $hash{get_api_information}{comment} = 'Return API Version';
  $hash{get_system_information}{comment} = 'Return System Information';
  $hash{get_tariff_list}{comment} = 'Return List Of Tariffs';
  $hash{get_user_group_list}{comment} = 'Return List Of Users Group';
  $hash{get_user_state_list}{comment} = 'Return List Of Users State';
  $hash{get_city_list}{comment} = 'Return List Of Cities';
  $hash{get_city_district_list}{comment} = 'Return List Of City Districts';
  $hash{get_street_list}{comment} = 'Return List Of Streets';
  $hash{get_service_list}{comment} = 'Return List Of Services';
  $hash{get_house_list}{comment} = 'Return List Of Houses';
  $hash{get_user_additional_data_type_list}{comment} = 'Return List Of Users Additional Data Types';
  $hash{get_user_list}{comment} = 'Return List Of Users';
  $hash{get_user_tags}{comment} = 'Return List Of Tags';
  $hash{get_user_messages}{comment} = 'Return Users Messages';
  $hash{get_user_history}{comment} = 'Return User History';

  return _json_former(\%hash);
}

#*******************************************************************
=head2 change_user_data()

=cut
#*******************************************************************
sub change_user_data {

  require Users;
  my $users = Users->new($db, $admin, \%conf);
  $users->pi(
    {
      UID        => 2,
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      PAGE_ROWS  => $max_page_rows,
    }
  );

  my %hash = ();
  $users->pi_change({ %FORM });

  if (!$users->{errno}) {
    $hash{result} = 'ok';
  }
  else {
    $hash{result} = 'error';
    $hash{error} = $users->{errno};
  }

  print _json_former(\%hash);

  return 1;
}

#*******************************************************************
=head2 get_supported_change_user_data_list()

=cut
#*******************************************************************
sub get_supported_change_user_data_list {

  my %hash = ();

  $hash{COMMENTS}{comment} = 'chg COMMENTS';
  $hash{PHONE}{comment} = 'chg PHONE';
  $hash{EMAIL}{comment} = 'chg EMAIL';
  $hash{FIO}{comment} = 'chg FIO';

  return _json_former(\%hash);
}


1;
