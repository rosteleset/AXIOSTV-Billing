=head1 NAME

  Модуль sorm для Yahon

=cut
#package Sorm::Yahon;


use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Time::Piece;
use Users;
use Internet;
use Abon;
use Companies;
use Finance;
use Nas;
use Hotspot;
use AXbills::Base qw/cmd _bp in_array int2ip/;
use AXbills::Misc qw/translate_list/;

my ($User, $Company, $Payments, $Internet, $Nas, $Abon, $Hotspot);
my $start_date = "01.08.2017 12:00:00";

#**********************************************************
=head2 new($conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $conf, $db, $Admin, $attr) = @_;

  my $self = {
    DEBUG            => $attr->{DEBUG} || 0,
    ADMIN            => $Admin,
    DB               => $db,
    conf             => $conf,
    argv             => $attr
  };

  bless($self, $class);

  $self->init();

  return $self;
}

#**********************************************************
=head2 init()

=cut
#**********************************************************
sub init {
  my $self = shift;

  $User = Users->new($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Company = Companies->new($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Payments = Finance->payments($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Internet = Internet->new($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Nas = Nas->new($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Abon = Abon->new($self->{DB}, $self->{ADMIN}, $self->{conf});
  $Hotspot = Hotspot->new($self->{DB}, $self->{ADMIN}, $self->{conf});

  my $argv = $self->{argv};

  if ($argv->{DICTIONARIES}) {
    $self->supplement_services_dictionary();
    $self->payments_type_dictionary();
    $self->docs_dictionary();
    $self->gates_dictionary();
    $self->ippool_dictionary();
    $self->dictionary_telcos();
  }
  elsif ($argv->{DICTIONARIE}) {
    my $fn = $argv->{DICTIONARIE};
    &{\&$fn}();
  }
  elsif ($argv->{START}) {

    my @dirs = ('/sorm/',
      '/sorm/Yahon/',
      '/sorm/Yahon/abonents/',
      '/sorm/Yahon/payments/',
      '/sorm/Yahon/wi-fi/',
      '/sorm/Yahon/dictionaries/'
    );

    foreach my $dir ( @dirs ) {
      if($self->{DEBUG} > 1) {
        print "Create dir: $main::var_dir$dir\n";
      }
      mkdir($main::var_dir. $dir);
    }

    system(qq{echo "2018-01-01 00:00:01" > $main::var_dir/sorm/Yahon/last_admin_action});
    system(qq{echo "2018-01-01 00:00:01" > $main::var_dir/sorm/Yahon/last_payments});

    my $users_list = $User->list({
      COLS_NAME => 1,
      PAGE_ROWS => 99999,
      DELETED   => 0,
      DISABLE   => 0,
    });

    foreach my $u (@$users_list) {
      $self->user_info_report($u->{uid});
    }
  }
  elsif ($argv->{SHOW_ERRORS}) {
    $self->sorm_errors();
    exit;
  }
  elsif ($argv->{WIFI}) {
    $self->check_wifi();
  }
  else {
    $self->check_admin_actions();
    $self->check_system_actions();
    $self->check_payments();
  }

  $self->send_changes();

  return 1;
}


#**********************************************************
=head2 user_info_report($uid)

=cut
#**********************************************************
sub user_info_report {
  my $self = shift;
  my ($uid) = @_;

  delete @{$User}{ qw(FIO EMAIL PHONE CELL_PHONE CONTRACT_ID ADDRESS_DISTRICT CITY ADDRESS_STREET ADDRESS_BUILD ADDRESS_FLAT) };
  #ID; REGION_ID; CONTRACT_DATE; CONTRACT; ACCOUNT; ACTUAL_FROM; ACTUAL_TO; ABONENT_TYPE;
  #
  $User->info($uid);
  if ($User->{errno}) {
    delete $User->{errno};
    return 0;
  }

  delete $User->{_GIVE_NETWORK};
  $User->pi({ UID => $uid });

  delete $Internet->{IP};
  delete $Internet->{CID};
  delete $Internet->{NETMASK};
  $Internet->user_info($uid);

  my ($family, $name, $surname) = split(' ', $User->{FIO} || q{});

  my @arr;
  my $ip = q{};
  my $bitmask = q{};

  $arr[0] = $self->{conf}->{SORM_ISP_ID};        # идентификатор филиала (справочник филиалов)
  $arr[1] = $User->{LOGIN}; # login
  $arr[2] = "";

  if ($User->{_GIVE_NETWORK}) {
    ($ip, $bitmask) = split(/\//, $User->{_GIVE_NETWORK}, 2);
    $arr[2] = 0;
  }
  elsif ($Internet->{IP} && $Internet->{IP} ne '0.0.0.0') {
    $ip = $Internet->{IP};
    if ($Internet->{NETMASK}) {
      $bitmask = unpack("B32", pack("N*", ip2int($Internet->{NETMASK})));
      $bitmask =~ s/0+$//g;
      $bitmask = length($bitmask);
    }
    $arr[2] = 0;
  }

  $arr[3] = $ip;      # static IP
  $arr[4] = "";       # Static ipv6
  $arr[5] = $bitmask; # Mask

  if ($Internet->{CID}) {
    $Internet->{CID} =~ s/[\r\n]+//g;
  }
  else {
    $Internet->{CID} = q{};
  }

  $arr[6] = $Internet->{CID}; # MAC

  # $arr[5] = $User->{EMAIL};                             # e-mail
  # $arr[4] = $User->{PHONE} || "";                       # телефон
  # $arr[5] = "";                                         # MAC-адрес
  $arr[7] = main::_date_format($User->{REGISTRATION}) . ' 12:00:00';                                                   # дата договора
  $arr[8] = $User->{CONTRACT_ID} || $User->{LOGIN};                                                              # номер договора
  $arr[9] = $User->{DISABLE};                                                                                    # статус абонента (0 - подключен, 1 - отключен)
  $arr[10] = main::_date_format($User->{REGISTRATION}) . ' 12:00:00';                                                  # дата активации основной услуги
  $arr[11] = ($User->{EXPIRE} ne '0000-00-00' && $User->{EXPIRE} lt $main::DATE) ? main::_date_format($User->{EXPIRE}) : ""; # дата отключения основной услуги

  #физ лицо
  if (!$User->{COMPANY_ID}) {

    $arr[12] = 0; # тип абонента (0 - физ лицо, 1 - юр лицо)
    $User->{PASPORT_NUM} //= q{};
    $User->{PASPORT_GRANT} //= q{};

    my ($passport_ser, $passport_num) = $User->{PASPORT_NUM} =~ m/(.*)\s(\d+)/;
    $passport_ser =~ s/\s//g if ($passport_ser);
    $User->{PASPORT_GRANT} =~ s/\n//g;
    $User->{PASPORT_GRANT} =~ s/\r//g;

    if ($name && $surname && $family) {
      $arr[13] = '0';      # тип ФИО (0-структурировано, 1 - одной строкой)
      $arr[14] = $name;    # имя
      $arr[15] = $surname; # отчество
      $arr[16] = $family;  # фамилия
      $arr[17] = "";       # ФИО строкой
    }
    else {
      $arr[13] = '1'; # тип ФИО (0-структурировано, 1 - одной строкой)
      $arr[14] = "";  # имя
      $arr[15] = "";  # отчество
      $arr[16] = "";  # фамилия
      #fixme
      $arr[17] = $User->{FIO} || "UNKNOWN"; # ФИО строкой
    }

    $arr[18] = ""; # дата рождения

    if ($passport_ser && $passport_num && $User->{PASPORT_GRANT}) {
      $arr[19] = '0';                                                                # тип паспортных данных (0-структурировано, 1-одной строкой)
      $arr[20] = $passport_ser;                                                      # серия паспорта
      $arr[21] = $passport_num;                                                      # номер паспорта
      $arr[22] = $User->{PASPORT_GRANT} . " " . main::_date_format($User->{PASPORT_DATE}); # кем и когда выдан
      $arr[23] = "";                                                                 # паспортные данные строкой
    }
    else {
      $arr[19] = '1';                                                                               # тип паспортных данных (0-структурировано, 1-одной строкой)
      $arr[20] = "";                                                                                # серия паспорта
      $arr[21] = "";                                                                                # номер паспорта
      $arr[22] = "";                                                                                # кем и когда выдан
      $arr[23] = $User->{PASPORT_NUM} . " " . $User->{PASPORT_GRANT} . " " . $User->{PASPORT_DATE}; # паспортные данные строкой
    }
    $arr[24] = 1;  # тип документа (спровочник видов документов)
    $arr[25] = ""; # банк абонента
    $arr[26] = ""; # номер счета абонента

    $arr[27] = ""; #
    $arr[28] = ""; #
    $arr[29] = ""; # поля остаются пустыми если абонент физ. лицо
    $arr[30] = ""; #
    $arr[31] = ""; #
    $arr[32] = ""; #
  }

  #юр лицо
  else {
    $arr[12] = 1; # тип абонента (0 - физ лицо, 1 - юр лицо)

    $arr[13] = ""; #
    $arr[14] = ""; #
    $arr[15] = ""; #
    $arr[16] = ""; #
    $arr[17] = ""; #
    $arr[18] = ""; #
    $arr[19] = ""; #
    $arr[20] = ""; # поля остаются пустыми если абонент юр. лицо
    $arr[21] = ""; #
    $arr[22] = ""; #
    $arr[23] = ""; #
    $arr[24] = ""; #
    $arr[25] = ""; #
    $arr[26] = ""; #

    $Company->info($User->{COMPANY_ID});
    $arr[27] = $Company->{NAME};           # abonent-jur-fullname  наименование компании
    $arr[28] = $Company->{TAX_NUMBER};     # abonent-jur-inn ИНН
    $arr[29] = $Company->{REPRESENTATIVE}; # контактное лицо
    $arr[30] = $Company->{PHONE};          # контактный телефон
    $arr[31] = $Company->{BANK_NAME};      # банк абонента
    $arr[32] = $Company->{BANK_ACCOUNT};   # номер счета абонента
  }

  #адрес абонента
  #my $address = ($User->{ADDRESS_FULL} || "") . ", " . ($User->{CITY} || "") . ", " . ($User->{ZIP} || "");
  my $build_delimiter = $self->{conf}->{BUILD_DELIMITER} || ', ';
  my $address = ($User->{ADDRESS_DISTRICT} || q{}) . $build_delimiter
    . ($User->{CITY} || q{}) . $build_delimiter
    . ($User->{ADDRESS_STREET} || q{}) . $build_delimiter
    . ($User->{ADDRESS_BUILD} || q{}) . $build_delimiter
    . ($User->{ADDRESS_FLAT} || q{}) . " ";

  $arr[33] = 1;        # тип данных адреса (0 - структурировано, 1 - одной строкой)
  $arr[34] = "";       # индекс
  $arr[35] = "";       # страна
  $arr[36] = "";       # область
  $arr[37] = "";       # район
  $arr[38] = "";       # город
  $arr[39] = "";       # улица
  $arr[40] = "";       # дом
  $arr[41] = "";       # корпус
  $arr[42] = "";       # квартира
  $arr[43] = $address; # адрес строкой

  #адрес устройства
  $arr[44] = 1;        # тип данных адреса устройства (0 - структурировано, 1 - одной строкой)
  $arr[45] = "";       # индекс
  $arr[46] = "";       # страна
  $arr[47] = "";       # область
  $arr[48] = "";       # район
  $arr[49] = "";       # город
  $arr[50] = "";       # улица
  $arr[51] = "";       # дом
  $arr[52] = "";       # корпус
  $arr[53] = "";       # квартира
  $arr[54] = $address; # адрес строкой

  #почтовый адрес Error: address-3-unstruct
  #  $arr[55] = ($user->{COMPANY_ID})  ? "1" : ""; #		тип данных по  почтовому адресу (0 - структурированные данные, 1 - неструктурированные) (число):	Обязательное поле 0 или 1
  #   $arr[56] = "";		# почтовый индекс, zip-код (строка, 1..32)	Обязательное поле если запись структурированная
  #   $arr[57] = "";		# страна (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[58] = "";		# область (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[59] = "";		# район, муниципальный округ (строка, 1..128)	Опциональное поле если запись структурированная
  #   $arr[60] = "";		# город/поселок/деревня/аул (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[61] = "";		# улица (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[62] = "";		# номер дома, строения (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[63] = "";		# корпус (строка, 1..128)	Опциональное поле если запись структурированная
  #   $arr[64] = "";		# квартира, офис (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[65] = ($user->{COMPANY_ID}) ? $address :  "";		# неструктурированный адрес (строка, 1..1024)	Обязательное поле если запись неструктурированная
  #
  # # адрес доставки корреспонденции
  #   $arr[66] = ($user->{COMPANY_ID})  ? "1" : "";	 #	тип данных по адресу доставки счета (0 - структурированные данные, 1 - неструктурированные) (число)(пустое поле, если отсутствует*):	Обязательное поле 0 или 1
  #   $arr[67] = "";	#	почтовый индекс, zip-код (строка, 1..32)	Обязательное поле если запись структурированная
  #   $arr[68] = "";	#		страна (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[69] = "";	#		область (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[70] = "";	#		район, муниципальный округ (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[71] = "";	#		город/поселок/деревня/аул (строка, 1..128)	Опциональное поле если запись структурированная
  #   $arr[72] = "";	#		улица (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[73] = "";	#		номер дома, строения (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[74] = "";	#		корпус (строка, 1..128)	Опциональное поле если запись структурированная
  #   $arr[75] = "";	#		квартира, офис (строка, 1..128)	Обязательное поле если запись структурированная
  #   $arr[76] = ($user->{COMPANY_ID}) ? $address :  "";	#		неструктурированный адрес (строка, 1..1024)	Обязательное поле если запись неструктурированная

  my $string = "";
  foreach (@arr) {
    $string .= '"' . ($_ // "") . '";';
  }
  $string =~ s/;$/\n/;

  _add_report('user', $string);

  return 1;
}

#**********************************************************
=head2 supplement_services_dictionary();($attr)

=cut
#**********************************************************
sub supplement_services_dictionary {
  my $self = shift;
  my $list = $Abon->tariff_list({ COLS_NAME => 1 });

  foreach (@$list) {
    my $string = '"' . $self->{conf}->{SORM_ISP_ID} .'";';
    $string .= '"' . $_->{tp_id} . '";';      # номер услуги
    $string .= '"' . $_->{tp_name} . '";';    # название услуги
    $string .= '"' . $start_date . '";';      # дата начала действия услуги
    $string .= '"";';                         # дата окончания действия услуги
    $string .= '"' . $_->{name} . '"' . "\n"; # описание
    _add_report('sup_s', $string);
  }

  print "supplement_services dictionary formed.\n";

  return 1;
}

#**********************************************************
=head2 payments_type_dictionary($attr)

=cut
#**********************************************************
sub payments_type_dictionary {
  my $self = shift;
  do ("/usr/axbills/language/russian.pl");
  my $types = translate_list($Payments->payment_type_list({ COLS_NAME => 1 }));

  if ($self->{conf}->{PAYSYS_PAYMENTS_METHODS}) {
    foreach my $line (split (';', $self->{conf}->{PAYSYS_PAYMENTS_METHODS})) {
      my($id, $type) = split (':', $line);
      push (@$types, {id => $id, name => $type} );
    }
  }

  foreach (@$types) {
    my $string = '"' . $self->{conf}->{SORM_ISP_ID} .'";';
    $string .= '"' . $_->{id} . '";';
    $string .= '"' . $start_date . '";';
    $string .= '"";';
    $string .= '"' . $_->{name} . '"' . "\n";
    _add_report('p_type', $string);
  }

  print "Payments types dictionary formed.\n";
  return 1;
}

#**********************************************************
=head2 docs_dictionary()

=cut
#**********************************************************
sub docs_dictionary {
  my $self = shift;

  my $string = '"' . $self->{conf}->{SORM_ISP_ID} .'";"1";"01.08.2017";"";"паспорт"' . "\n";
  _add_report('d_type', $string);

  print "Docs dictionary formed.\n";

  return 1;
}

#**********************************************************
=head2 gates_dictionary()

=cut
#**********************************************************
sub gates_dictionary {
  my $self = shift;

  my $string = '"' . $self->{conf}->{SORM_ISP_ID} .'";"1.1.1.1";"01.08.2017";"";"Radius";"Страна";"Область";" ";"город";"улица";"7";"7"' . "\n";
  _add_report('gates', $string);

  print "Gates dictionary formed.\n";

  return 1;
}



#**********************************************************
=head2 ippool_dictionary($attr)

=cut
#**********************************************************
sub ippool_dictionary {
  my $self = shift;

  if ($self->{DEBUG} > 6) {
    $Nas->{debug}=1;
    $User->{debug}=1;
  }

  my $isp_id = $self->{conf}->{SORM_ISP_ID};

  my $pools_list = $Nas->nas_ip_pools_list({
    IP_COUNT         => '_SHOW',
    POOL_NAME        => '_SHOW',
    IP               => '_SHOW',
    COLS_NAME        => 1,
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS        => 99999,
  });

  foreach my $pool (@$pools_list) {
    next unless ($pool->{ip});
    my $ip = int2ip($pool->{ip});

    my $mask = 32 - length(sprintf ("%b", $pool->{ip_count}));

    my $string = '"' . $isp_id .'";';
    $string .= '"' . $pool->{pool_name} . '";';
    $string .= '"' . $ip . '";';
    $string .= '"' . $mask . '";';
    $string .= '"' . $start_date . '";';
    $string .= '""' . "\n";

    _add_report('pool', $string);
  }

  #Clients pool dictionary
  my $users_list = $User->list({
    _GIVE_NETWORK => '*',
    COMPANY_NAME  => '_SHOW',
    COLS_NAME     => 1,
    PAGE_ROWS     => 99999,
  });

  foreach my $pool (@$users_list) {
    if(! $pool->{_give_network}) {
      next;
    }
    my ($ip, $bitmask)=split(/\//, $pool->{_give_network});

    my $string = '"' . $isp_id .'";';
    $string .= '"' . (($pool->{company_name}) ? $pool->{company_name} : $pool->{login}) .'";';
    $string .= '"' . $ip . '";';
    $string .= '"' . $bitmask . '";';
    $string .= '"' . $start_date . '";';
    $string .= '""' . "\n";

    _add_report('pool', $string);
  }

  print "IP pool dictionary formed.\n";
  return 1;
}

#**********************************************************
=head2 dictionary_telcos()

=cut
#**********************************************************
sub dictionary_telcos {
  my $self = shift;
  my $string = '' . "\n";

  _add_report('telcos', $string);

  print "telcos dictionary formed.\n";

  return 1;
}

#**********************************************************
=head2 check_wifi()

=cut
#**********************************************************
sub check_wifi {
  my $self = shift;

  my $filename = $main::var_dir . "sorm/Yahon/last_wifi_action";
  open (my $fh, '<', $filename) or die "Could not open file '$filename' $!";
  my $last_wifi_date = <$fh>;
  chomp $last_wifi_date;
  close $fh;

  my $wifi_list = $Hotspot->log_list({
    DATE        => ">$last_wifi_date",
    ACTION      => '_SHOW',
    PHONE       => '_SHOW',
    CID         => '_SHOW',
    ACTION      => "2,3,5",
    COLS_NAME   => 1,
    PAGE_ROWS   => 99999,
    SORT        => 'date',
    DESC        => 'DESC',
  });

  foreach my $line (@$wifi_list) {
    $self->wifi_report($line);
  }

  return 1 if ($Hotspot->{TOTAL} < 1);

  $last_wifi_date = $wifi_list->[0]->{date} . "\n";

  # open ($fh, '>', $filename) or die "Could not open file '$filename' $!";
  # print $fh $last_wifi_date;
  # close $fh;

  return 1;
}

#**********************************************************
=head2 wifi_report($attr)

=cut
#**********************************************************
sub wifi_report {
  my $self = shift;
  my ($attr) = @_;

  require Internet::Sessions;
  Internet::Sessions->import();
  my $Sessions = Internet::Sessions->new($self->{DB}, $self->{ADMIN}, $self->{conf});

  my $online_list = $Sessions->online({
    CLIENT_IP   => '_SHOW',
    UID         => '_SHOW',
    STARTED     => ">$attr->{date}",
    CID         => $attr->{CID},
    COLS_NAME   => 1,
    COLS_UPPER  => 1,
    SORT        => 'started',
    PAGE_ROWS   => 1
  });

  if ($Sessions->{TOTAL}) {
    $attr->{uid}  = $online_list->[0]->{uid};
    $attr->{ip}   = $online_list->[0]->{client_ip};
    $attr->{date} = $online_list->[0]->{started};
  }
  else {
    my $sessions_list = $Sessions->list({
      IP          => '_SHOW',
      UID         => '_SHOW',
      DATE        => ">$attr->{date}",
      CID         => $attr->{CID},
      COLS_NAME   => 1,
      COLS_UPPER  => 1,
      SORT        => 1,
      PAGE_ROWS   => 1
    });

    if ($Sessions->{TOTAL}) {
      $attr->{uid}  = $sessions_list->[0]->{uid};
      $attr->{ip}   = $sessions_list->[0]->{ip};
      $attr->{date} = $sessions_list->[0]->{date};
    }
    else {
      print "Can't find session info for $attr->{CID}, $attr->{id} line, hotspot_log\n";
      return 1;
    }
  }

  if (!$attr->{phone}) {
    $User->pi({ UID => $attr->{uid} });
    $attr->{phone} = $User->{PHONE};
  }

  if (!$attr->{phone}) {
    print "Can't find phone for $attr->{CID} Skip line $attr->{id}.\n";
    return 1;
  }

  if (!$attr->{login}) {
    print "Can't find user with $attr->{CID} Skip line $attr->{id}.\n";
    return 1;
  }

  my $string = '"' . $self->{conf}->{SORM_ISP_ID} .'";';                             # идентификатор филиала из справочника
  $string   .= '"' . $attr->{phone} . '";';                     # телефон
  $string   .= '"' . $attr->{login} . '";';                     # логин
  $string   .= '"' . $attr->{ip} . '";';                        # IP
  $string   .= '"' . $attr->{CID} . '";';                       # МАС-адрес
  $string   .= '"' . $attr->{date} . '";';                      # дата и время подключения
  $string   .= '"1"' . "\n";                                    # номер антены (из справочника)

  _add_report('wifi', $string);

  return 1;
}

#**********************************************************
=head2 check_admin_actions()

=cut
#**********************************************************
sub check_admin_actions {
  my $self = shift;

  my $filename = $main::var_dir . "sorm/Yahon/last_admin_action";
  open (my $fh, '<', $filename) or die "Could not open file '$filename' $!";
  my $last_action_date = <$fh>;
  chomp $last_action_date;
  close $fh;

  my $action_list = $self->{ADMIN}->action_list({
    COLS_NAME => 1,
    ACTIONS   => '_SHOW',
    TYPE      => '1,2', # Only add'_SHOW',
    MODULE    => '_SHOW',
    DATETIME  => ">$last_action_date",
    SORT      => 'aa.datetime',
    DESC      => 'DESC',
    PAGE_ROWS => 99999,
  });

  return 1 if ($self->{ADMIN}->{TOTAL} < 1);

  $last_action_date = $action_list->[0]->{datetime} . "\n";

  foreach my $action (@$action_list) {
    if ($action->{module} eq 'Msgs') {

    }
    elsif ($action->{module} && $action->{module} eq 'Abon' && $action->{action_type} && $action->{action_type} eq '3') {
      my (@services) = $action->{actions} =~ m/ADD\:(\d+)/g;
      foreach (@services) {
        $self->abon_info_report($action->{uid}, $action->{datetime}, $_);
      }
    }
    else {
      $self->user_info_report($action->{uid}) if ($action->{uid});
    }
  }

  open ($fh, '>', $filename) or die "Could not open file '$filename' $!";
  print $fh $last_action_date;
  close $fh;

  return 1;
}

#**********************************************************
=head2 check_system_actions($attr)

=cut
#**********************************************************
sub check_system_actions {
  my $self = shift;
  return 1;
}

#**********************************************************
=head2 abon_info_report($uid, $date, $tp)

=cut
#**********************************************************
sub abon_info_report {
  my $self = shift;
  my ($uid, $datetime, $tp_id) = @_;
  $User->info($uid);

  my $string = '"' . $self->{conf}->{SORM_ISP_ID} .'";';                                      # идентификатор филиала из справочника
  $string   .= '"' . $User->{LOGIN} . '";';                              # логин
  $string   .= '"' . ($User->{CONTRACT_ID} || $User->{LOGIN} ) . '";';   # номер договора
  $string   .= '"' . $tp_id . '";';                                      # идентификатор услуги
  $string   .= '"' . main::_date_format($datetime) . '";';                     # дата подключения
  $string   .= '"";';                                                    # дата отключения
  $string   .= '""' . "\n";                                              # дополнительная информация

  _add_report('abon', $string);

  return 1;
}



#**********************************************************
=head2 check_payments($attr)

=cut
#**********************************************************
sub check_payments {
  my $self = shift;

  my $filename = $main::var_dir . "sorm/Yahon/last_payments";
  open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
  my $last_payment_date = <$fh>;
  chomp $last_payment_date;
  close $fh;

  my $payment_list = $Payments->list({
    DATETIME    => ">$last_payment_date",
    LOGIN       => '_SHOW',
    SUM         => '_SHOW',
    METHOD      => '_SHOW',
    CONTRACT_ID => '_SHOW',
    UID         => '_SHOW',

    COLS_NAME   => 1,
    PAGE_ROWS   => 99999,

    SORT        => 'p.date',
    DESC        => 'DESC',
  });

  return 1 if ($Payments->{TOTAL} < 1);

  $last_payment_date = $payment_list->[0]->{datetime} . "\n";

  foreach my $payment (@$payment_list) {
    $self->payment_report($payment);
  }

  open($fh, '>', $filename) or die "Could not open file '$filename' $!";
  print $fh $last_payment_date;
  close $fh;

  return 1;
}

#**********************************************************
=head2 payment_report($attr)

=cut
#**********************************************************
sub payment_report {
  my $self = shift;
  my ($attr) = @_;

  $Internet->user_info($attr->{uid});
  my $ip = ($Internet->{IP} ne '0.0.0.0') ? $Internet->{IP} : "";

  my $string = '"' . $self->{conf}->{SORM_ISP_ID} .'";';                             # идентификатор филиала из справочника
  $string   .= '"' . $attr->{method} . '";';                    # тип оплаты из сравочника
  $string   .= '"' . ($attr->{login} || "") . '";';             # номер договора
  $string   .= '"' . $ip . '";';                                # статический IP
  $string   .= '"' . main::_date_format($attr->{datetime}) . '";';    # дата пополнения
  $string   .= '"' . $attr->{sum} . '";';                       # сумма пополнения
  $string   .= '"' . ($attr->{dsc} || "") . '"' . "\n";         # дополнительная информация

  _add_report('payment', $string);

  return 1;
}


#**********************************************************
=head2 _add_report($type, $string)

  Arguments:
    $type
    $string

  Results:
   TRUE or FALSE

=cut
#**********************************************************
sub _add_report {
  my ($type, $string) = @_;

  my %reports = (
    user    => "$main::var_dir/sorm/Yahon/abonents/abonents.csv.utf",
    abon    => "$main::var_dir/sorm/Yahon/abonents/services.csv.utf",
    payment => "$main::var_dir/sorm/Yahon/payments/payments.csv.utf",
    p_type  => "$main::var_dir/sorm/Yahon/dictionaries/pay-types.csv.utf",
    d_type  => "$main::var_dir/sorm/Yahon/dictionaries/doc-types.csv.utf",
    gates   => "$main::var_dir/sorm/Yahon/dictionaries/gates.csv.utf",
    pool    => "$main::var_dir/sorm/Yahon/dictionaries/ip-numbering-plan.csv.utf",
    sup_s   => "$main::var_dir/sorm/Yahon/dictionaries/supplement-services.csv.utf",
    wifi    => "$main::var_dir/sorm/Yahon/wi-fi/wifi.csv.utf",
    telcos  => "$main::var_dir/sorm/Yahon/dictionaries/telcos.csv.utf"
  );

  my $filename = $reports{$type};

  if ($type ne 'payment' && -e $filename) {
    open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
    while (<$fh>) {
      return 1 if ($_ eq $string);
    }
    close $fh;
  }

  open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
  print $fh $string;
  close $fh;

  return 1;
}



#**********************************************************
=head2 send_changes($attr)

=cut
#**********************************************************
sub send_changes {
  my $self = shift;

  my $t = localtime;

  #Docname:dirname
  my @export_docs = (
    'abonents/abonents:/abonents/abonents:/abonents',
    'payments/payments:/payments/balance-fillup:/payments',
    'abonents/services:abonents/services',
    'gates:/dictionaries/gates:/dictionaries',
    'dictionaries/doc-types:/dictionaries/doc-types:/dictionaries',
    'dictionaries/pay-types:/dictionaries/pay-types:/dictionaries',
    'dictionaries/ip-numbering-plan:/dictionaries/ip-numbering-plan:/dictionaries',
    'dictionaries/supplement-services:/dictionaries/supplement-services:/dictionaries',
    'wi-fi/wifi:/wi-fi'
  );

  foreach my $line (@export_docs) {
    my ($doc_name, $dirname, $error_dir)=split(/:/, $line);

    if (-e $main::var_dir . '/sorm/Yahon/'. $doc_name .'.csv.utf') {
      my $file = join('_',  $main::var_dir.'/sorm/Yahon/'. $doc_name,
        $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
      $file .= ".csv";
      print $main::var_dir . '/sorm/Yahon/'. $doc_name .'.csv.utf' ." -> $dirname/". $dirname.".cvs\n";
      main::_ftp_upload({
        ICONV => "$main::var_dir/sorm/Yahon/$doc_name.csv.utf > $file",
        DIR   => $dirname,
        FILE  => $file
      });
      # unlink $file;
      unlink $main::var_dir . '/sorm/Yahon/'. $doc_name . '.csv.utf';
      $self->sorm_errors({
        DIR   => $error_dir,
        FILE  => $file
      });
    }
  }

  # if (-e $var_dir . "/sorm/payments/payments.csv.utf") {
  #   my $file = join('_',  "$var_dir/sorm/payments/payments",
  #     $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
  #   $file .= ".csv";
  #
  #   _ftp_upload({
  #     ICONV => "$var_dir/sorm/payments/payments.csv.utf > $file",
  #     DIR   => "/payments/balance-fillup",
  #     FILE  => $file
  #   });
  #
  #   # unlink $file;
  #   unlink $var_dir.'/sorm/payments/payments.csv.utf';
  # }

  # if (-e $var_dir . "/sorm/abonents/services.csv.utf") {
  #   my $file = join('_', "$var_dir/sorm/abonents/services",
  #     $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
  #   $file .= ".csv";
  #
  #   _ftp_upload({
  #     ICONV => "$var_dir/sorm/abonents/services.csv.utf > $file",
  #     DIR   => "/abonents/services",
  #     FILE  => $file
  #   });
  #
  #   # unlink $file;
  #   unlink '$var_dir/sorm/services/services.csv.utf';
  # }
  # if (-e $var_dir . "/sorm/dictionaries/gates.csv.utf") {
  #   my $file = join('_',
  #     "$var_dir/sorm/dictionaries/gates",
  #     $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
  #   $file .= ".csv";
  #
  #   _ftp_upload({
  #     ICONV => "$var_dir/sorm/dictionaries/gates.csv.utf > $file",
  #     DIR   => "/dictionaries/gates",
  #     FILE  => $file
  #   });
  #
  #   # unlink $file;
  #   unlink $var_dir .'/sorm/dictionaries/gates.csv.utf';
  # }
  #
  # if (-e "$var_dir/sorm/dictionaries/doc-types.csv.utf") {
  #   my $file = join('_',
  #     "$var_dir/sorm/dictionaries/doc-types",
  #     $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
  #   $file .= ".csv";
  #
  #   _ftp_upload({
  #     ICONV => "$var_dir/sorm/dictionaries/doc-types.csv.utf > $file",
  #     DIR   => "/dictionaries/doc-types",
  #     FILE  => $file
  #   });
  #
  #   # unlink $file;
  #   unlink $var_dir.'/sorm/dictionaries/doc-types.csv.utf';
  # }
  #
  # if (-e "$var_dir/sorm/dictionaries/pay-types.csv.utf") {
  #   my $file = join('_',
  #     "$var_dir/sorm/dictionaries/pay-types",
  #     $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
  #   $file .= ".csv";
  #   print "Send $file\n";
  #   system("iconv -f UTF-8 -t CP1251 $var_dir/sorm/dictionaries/pay-types.csv.utf > $file");
  #   my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
  #   $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
  #   $ftp->cwd("/dictionaries/pay-types") or die "Cannot change working directory ", $ftp->message;
  #   $ftp->put($file) or die "$file put failed ", $ftp->message;
  #   print $ftp->message;
  #   $ftp->quit;
  #   # unlink $file;
  #   unlink '$var_dir/sorm/dictionaries/pay-types.csv.utf';
  # }
  #
  # if (-e "$var_dir/sorm/dictionaries/ip-numbering-plan.csv.utf") {
  #   my $file = join('_',
  #     "$var_dir/sorm/dictionaries/ip-numbering-plan",
  #     $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
  #   $file .= ".csv";
  #   print "Send $file\n";
  #   system("iconv -f UTF-8 -t CP1251 $var_dir/sorm/dictionaries/ip-numbering-plan.csv.utf > $file");
  #   my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
  #   $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
  #   $ftp->cwd("/dictionaries/ip-numbering-plan") or die "Cannot change working directory ", $ftp->message;
  #   $ftp->put($file) or die "$file put failed ", $ftp->message;
  #   print $ftp->message;
  #   $ftp->quit;
  #   # unlink $file;
  #   unlink '$var_dir/sorm/dictionaries/ip-numbering-plan.csv.utf';
  # }
  #
  # if (-e "$var_dir/sorm/dictionaries/supplement-services.csv.utf") {
  #   my $file = join('_',
  #     "$var_dir/sorm/dictionaries/supplement-services",
  #     $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
  #   $file .= ".csv";
  #   print "Send $file\n";
  #   system("iconv -f UTF-8 -t CP1251 $var_dir/sorm/dictionaries/supplement-services.csv.utf > $file");
  #   my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
  #   $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
  #   $ftp->cwd("/dictionaries/supplement-services") or die "Cannot change working directory ", $ftp->message;
  #   $ftp->put($file) or die "$file put failed ", $ftp->message;
  #   print $ftp->message;
  #   $ftp->quit;
  #   # unlink $file;
  #   unlink '$var_dir/sorm/dictionaries/supplement-services.csv.utf';
  # }
  #
  # if (-e "$var_dir/sorm/wi-fi/wifi.csv.utf") {
  #   my $file = join('_',
  #     "$var_dir/sorm/wi-fi/wifi",
  #     $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
  #   $file .= ".csv";
  #   print "Send $file\n";
  #   system("iconv -f UTF-8 -t CP1251 $var_dir/sorm/wi-fi/wifi.csv.utf > $file");
  #   my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
  #   $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
  #   $ftp->cwd("/wi-fi") or die "Cannot change working directory ", $ftp->message;
  #   $ftp->put($file) or die "$file put failed ", $ftp->message;
  #   print $ftp->message;
  #   $ftp->quit;
  #   # unlink $file;
  #   unlink '$var_dir/sorm/wi-fi/wifi.csv.utf';
  # }

  return 1;
}


#**********************************************************
=head2 sorm_errors() - Show sorm errors

  Arguments:
    $attr
      DIR
      FILE

  Retuens:

=cut
#**********************************************************
sub sorm_errors {
  my $self = shift;
  my ($attr)=@_;

  sleep 2;
  print "\n__________ERROR________________\n" if($self->{DEBUG} > 0);
  my $file         = $attr->{FILE};
  my $ftp_login    = $self->{conf}->{SORM_ERR_LOGIN};
  my $ftp_password = $self->{conf}->{SORM_ERR_PASSWORD};
  my $ftp = Net::FTP->new($self->{conf}->{SORM_SERVER}, Debug => 0,
    Passive => $self->{conf}->{FTP_PASSIVE_MODE} || 0) or die "Cannot connect to $self->{conf}->{SORM_SERVER}: $@";

  $ftp->login($ftp_login, $ftp_password) or die "Cannot login ", $ftp->message;

  if($attr->{DIR}) {
    $ftp->cwd('/'.$attr->{DIR}) or die "Cannot change working directory ", $ftp->message;
  }

  my @files = $ftp->ls();
  foreach my $ftp_file (@files) {
    #$ftp->mget($file) or die "$file get failed ", $ftp->message;
    print "Error: ". ($ftp_file || '-') .' -> '. ($file || '-') ."\n";
  }

  print $ftp->message;
  $ftp->quit;

  return 1;
}

1;
