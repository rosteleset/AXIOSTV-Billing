=head1 NAME

 billd plugin

 DESCRIBE: Odoo import accounts


 Arguments:
   FIELDS_INFO       - Show field info
   TYPE              - Synsc system type
      userside (default)
        URL="https://"
      odoo
   SYNCHRON_ODOO_FIELDS  - Odoo sync field
   DOMAIN_ID         - DOmain id
   ADD_GID           - Add users to GID
   GET_LOCATION      - Sync only locations (Discrict,streets,build,geo coords)
   SKIP_SERVICE      - Skip sync service
   SKIP_WRONG_MAIL
   SYNC_COMPANY      - Add company main account
   IMPORT_LIMIT      - Import limit count
   REQUEST_TIMEOUT   - Default (10 sec)

   ODOO_CUSTOM=1
   PRODUCT_TYPES
   CATEGORY_IDS



  if($attr->{CATEGORY_IDS})

 Config:
   $conf{SYNCHRON_ODOO_FIELDS}='odoo_field:axbills_field_id;';


=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use AXbills::Base qw(show_hash load_pmodule int2ip);
use AXbills::Filters qw(_utf8_encode);
use AXbills::Fetcher;
use Tariffs;
use Users;
use Internet;
use Companies;
use Shedule;
use Address;
use Encode;

our (
  $argv,
  $DATE,
  $TIME,
  $debug,
  $Nas,
  $db,
  %conf,
  $Admin,
  $base_dir,
  %lang
);

my $Users        = Users->new($db, $Admin, \%conf);
my $Companies    = Companies->new($db, $Admin, \%conf);
my $Address      = Address->new($db, $Admin, \%conf);
my $Tariffs      = Tariffs->new($db, \%conf, $Admin);
our $admin       = $Admin;
our $html        = AXbills::HTML->new( { CONF => \%conf } );
my $import_limit = $argv->{IMPORT_LIMIT} || 1000000000;
require Internet::Users;
require AXbills::Misc;

my $main_file = $base_dir . '/language/english.pl';
require $main_file;
my $userside_default_url = q{http://demo.ubilling.net.ua:9999/billing/?module=remoteapi&key=UB45fc024bbb2632be0b3de41ff8a8b15b&action=userside};
my $request_timeout   = $argv->{REQUEST_TIMEOUT} || 15;

if($argv->{ODOO_CUSTOM}) {
  odoo_custom();
}
elsif($argv->{FIELDS_INFO}) {
  fields_info();
}
else {
  sync_system({ TYPE => $argv->{TYPE} })
}

#**********************************************************
=head2 us_get_street_list();

  Arguments:

  Results:

=cut
#**********************************************************
sub us_get_street_list {

  _log('LOG_DEBUG', "Userside: get_street_list");

  my $url = $argv->{URL} || $userside_default_url;

  $url .= '&request=get_street_list';

  my $result = web_request($url, {
    JSON_RETURN => 1,
    CURL        => 1,
    JSON_UTF8   => 1,
    DEBUG       => ($debug > 4) ? 1 : 0,
    TIMEOUT     => $request_timeout,
    FILE_CURL   => $conf{FILE_CURL}
  });

  if (! $result || $result->{errno}) {
    print "ERROR:". ($result->{errstr} || q{});
    return {};
  }

  my %street_list = ();
  foreach my $street_id ( keys %{ $result } ) {
    $street_list{$street_id}{NAME} = $result->{$street_id}->{full_name};
  }

  return \%street_list;
}

#**********************************************************
=head2 us_get_city_district_list();

  Arguments:

  Results:

=cut
#**********************************************************
sub us_get_city_district_list {
  my %city_district = ();

  _log('LOG_DEBUG', "Userside: get_city_district_list");

  my $url = $argv->{URL} || $userside_default_url;

  $url .= '&request=get_city_district_list';

  my $result = web_request($url, {
    JSON_RETURN => 1,
    CURL        => 1,
    JSON_UTF8   => 1,
    DEBUG       => ($debug > 4) ? 1 : 0,
    TIMEOUT     => $request_timeout,
    FILE_CURL   => $conf{FILE_CURL}
  });

  if (! $result || $result->{errno}) {
    print "ERROR:". (($result) ? $result->{errstr} : q{NO_RESULT});
    return \%city_district;
  }

  foreach my $city_district (keys %{$result}) {
    if ($city_district && $city_district == -1) {
      next;
    }
    $city_district{$city_district}{NAME}    = $result->{$city_district}->{name};
    $city_district{$city_district}{CITY_ID} = $result->{$city_district}->{city_id};
  }

  return \%city_district;
}
#**********************************************************
=head2 us_get_house_list();

  Arguments:

  Results:

=cut
#**********************************************************
sub us_get_house_list {
  my %build_list = ();

  _log('LOG_DEBUG', "Userside: get_house_list");

  #Fixme
  #get_city_list

  my $city_district_list = us_get_city_district_list();
  my $street_list = us_get_street_list();

  my $url = $argv->{URL} || $userside_default_url;

  $url .= '&request=get_house_list';

  my $result = web_request($url, {
    JSON_RETURN => 1,
    CURL        => 1,
    JSON_UTF8   => 1,
    DEBUG       => ($debug > 4) ? 1 : 0,
    TIMEOUT     => $request_timeout,
    FILE_CURL   => $conf{FILE_CURL}
  });

  foreach my $build_id ( keys %{ $result } ) {
    $build_list{$build_id}{NAME}        = $result->{$build_id}->{full_name};
    $build_list{$build_id}{NUMBER}      = $result->{$build_id}->{number};
    $build_list{$build_id}{STREET_NAME} = $street_list->{$result->{$build_id}->{street_id}}->{NAME};
    $build_list{$build_id}{CITY}        = ($result->{$build_id}->{city_district_id}
      && $city_district_list->{$result->{$build_id}->{city_district_id}}) ? $city_district_list->{$result->{$build_id}->{city_district_id}}->{NAME} : q{};

    # if ($build_list{$build_id}{CITY})  {
    #   #Encode::_utf8_off($build_list{$build_id}{CITY});
    #   #print $build_list{$build_id}{CITY} ."\n";
    #   #decode('utf8', $build_list{$build_id}{CITY})
    # }

    my ($coordx, $coordy)=(0,0);
    my @poligon = ();
    if ($result->{$build_id}->{coordinates}) {
      ($coordx, $coordy, @poligon)=split(/, /, $result->{$build_id}->{coordinates});
    }

    $build_list{$build_id}{COORDX}      = $coordy;
    $build_list{$build_id}{COORDY}      = $coordx;

    $build_list{$build_id}{ZIP}       = $result->{$build_id}->{postcode};
    $build_list{$build_id}{FLORS}     = $result->{$build_id}->{floor};
    $build_list{$build_id}{ENTRANCES} = $result->{$build_id}->{entrance};
  }

  return \%build_list;
}

#**********************************************************
=head2 userside_import();

  Arguments:

  Results:

=cut
#**********************************************************
sub userside_import {
  my @users_info = ();

  _log('LOG_DEBUG', "Userside: userside_import");

  my $build_list = us_get_house_list();

  my $url = $argv->{URL} || $userside_default_url;
  $url .= '&request=get_user_list';

  my $result = web_request($url, {
    JSON_RETURN => 1,
    CURL        => 1,
    JSON_UTF8   => 1,
    DEBUG       => ($debug > 4) ? 1 : 0,
    TIMEOUT     => $request_timeout,
    FILE_CURL   => $conf{FILE_CURL}
  });

  if (! $result || $result->{errno}) {
    print "ERROR:". (($result) ? $result->{errstr} : q{NO RESULT});
    return {};
  }

  #_log('LOG_DEBUG', $result);
  my $imported = 1;
  foreach my $login ( keys %{ $result } ) {
    my $u = $result->{$login};

    my %services = ();
    my $tarif;
    my $ip_mac;
    if (ref $u->{tariff}->{current} eq 'ARRAY') {
      $tarif = $u->{tariff}->{current}->[0];
    }
    else {
      my $id = (keys %{ $u->{tariff}->{current} })[0] || q{};
      $tarif = $u->{tariff}->{current}->{$id}
    }

    if (ref $u->{ip_mac} eq 'ARRAY') {
      $ip_mac = $u->{ip_mac}->[0];
    }
    else {
      my $id = (keys %{ $u->{ip_mac} })[0] || q{};
      $ip_mac = $u->{ip_mac}->{$id}
    }

    if($tarif) {
      %services = (
        4 => {
          TP_NAME => $tarif->{name} || $tarif->{id} || q{},
          CID     => $ip_mac->{mac} || q{},
          IP      => int2ip($ip_mac->{ip} || 0),
        }
      );
    }

    my $group;
    if (ref $u->{group} eq 'ARRAY') {
      $group = $u->{group}->[0];
    }
    else {
      my $id = (keys %{ $group })[0] || q{};
      $group = $group->{$id}
    }

    my $house_id = $u->{address}->[0]->{house_id} || 0;
    # print "// $u->{login} //";
    # print "// $build_list->{$house_id}->{CITY} //\n\n";
    push @users_info, {
      LOGIN            => $u->{login},
      CITY             => $build_list->{$house_id}->{CITY} || q{},
      ADDRESS_STREET   => $build_list->{$house_id}->{STREET_NAME} || q{},
      ADDRESS_BUILD    => $build_list->{$house_id}->{NUMBER} || q{},
      ADDRESS_FLAT     => $u->{address}->[0]->{apartment}->{number} || q{},
      ADDRESS_FLOR     => $u->{address}->[0]->{floor} || q{},
      ADDRESS_ENTRANCE => $u->{address}->[0]->{entrance} || q{},
      ADDRESS_COORDX   => $build_list->{$house_id}->{COORDX} || q{},
      ADDRESS_COORDY   => $build_list->{$house_id}->{COORDY} || q{},
      PHONE            => $u->{phone}->[0]->{number} || q{},
      EMAIL            => $u->{email}->[0]->{address} || q{},
      FIO              => $u->{full_name} || q{},
      PASSWORD         => $u->{password} || q{},
      GID              => $group || 0,
      DEPOSIT          => $u->{balance} || 0,
      CREDIT           => $u->{credit} || 0,
      DISCOUNT         => $u->{discount} || 0,
      DISABLE          => $u->{state_id} || 0,
      CONTRACT_ID      => $u->{account_number} || 0,
      COMMENTS         => $u->{account_number} || 0,
      SERVICES         => \%services
    };

    #print "===============================\n";
    #print show_hash($u, { DELIMITER => "\n" });
    $imported++;
    if ($import_limit < $imported) {
      last;
    }
  }

  user_import(\@users_info);

  return 1;
}

#**********************************************************
=head2 fields_info();

=cut
#**********************************************************
sub fields_info {

  my $type = $argv->{TYPE} || q{odoo};
  my $fn = $type .'_field_info';
  &{ \&$fn }();

  return 1;
}


#**********************************************************
=head2 synsc_system ();

=cut
#**********************************************************
sub sync_system {

  my $type = $argv->{TYPE} || q{userside};
  my $fn = $type .'_import';
  &{ \&$fn }();

  return 1;
}


#**********************************************************
=head2 odoo_field_info();

=cut
#**********************************************************
sub odoo_field_info {

  odoo_import({ FIELDS_INFO => 1 });

  return 1;
}

#**********************************************************
=head2 odoo_custom($attr);

  Argumnets:
    $attr

  Results:

=cut
#**********************************************************
sub odoo_custom {

  if($debug > 1) {
    print "odoo_custom\n";
  }

  require Synchron::Odoo;
  Synchron::Odoo->import();
  require Frontier::Client;
  Frontier::Client->import();

  my Synchron::Odoo $Odoo = odoo_connect({ JSON => 1 });

  my $users_list_json  = $Odoo->read_partner_contracts({
    %$argv
  });

#  print "----------------------\n";
#  print "VERSION: $users_list_json->{version}\n";
#  print "\n----------------------\n";
#  #print "jsontext: ". $users_list_json->{jsontext};
#  print "\n----------------------\n";
#  print "is_success: ". $users_list_json->{is_success};
#  print "\n----------------------\n";
#  print "content: ". $users_list_json->{content};
#  print "\n----------------------\n";

  load_pmodule('JSON');
  my $json = JSON->new->allow_nonref;

  my $perl_scalar = $json->decode($users_list_json->{jsontext});
  #foreach my $country ( @{ $perl_scalar->{result} } ) {
  #  print $country->{id}."\n";
  #}

  company_import2($perl_scalar->{result});

  return 1;
}

#**********************************************************
=head2 odoo_connect($attr);

  Argumnets:
    $attr

  Results:

=cut
#**********************************************************
sub odoo_connect {
  my ($attr) = @_;

  my $url      = $conf{SYNCHRON_ODOO_URL} || 'https://demo.odoo.com:8069';
  my $dbname   = $conf{SYNCHRON_ODOO_DBNAME} || 'demo';
  my $username = $conf{SYNCHRON_ODOO_USERNAME} || 'admin';
  my $password = $conf{SYNCHRON_ODOO_PASSWORD} || 'admin';

  $url =~ s/\/$//;

  if($debug) {
    print "Odoo connect\n";
    if($debug > 2) {
      print "DOMAIN_ID: $admin->{DOMAIN_ID} URL: $url DB: $dbname USER: $username PASSWORD: $password\n";
    }
  }

  require Synchron::Odoo;
  Synchron::Odoo->import();
  require Frontier::Client;
  Frontier::Client->import();

  my $Odoo = Synchron::Odoo->new({
    LOGIN    => $username,
    PASSWORD => $password,
    URL      => $url,
    DBNAME   => $dbname,
    DEBUG    => ($debug > 4) ? $debug : 0,
    CONF     => \%conf,
    JSON     => ($attr->{JSON}) ? 1 : undef
  });

  if($Odoo->{errno}) {
    print "ERROR: Odoo $Odoo->{errno} $Odoo->{errstr}\n";
  }

  return $Odoo;
}

#**********************************************************
=head2 odoo_import();

  Arguments:
    $attr
  Results:

=cut
#**********************************************************
sub odoo_import {
  my ($attr)=@_;

  my Synchron::Odoo $Odoo = odoo_connect();

  my $sync_fields = q{};

  if($conf{SYNCHRON_ODOO_FIELDS}) {
    $conf{SYNCHRON_ODOO_FIELDS}=~s/\n//g;

    my @sync_fields_info = split(/;/, $conf{SYNCHRON_ODOO_FIELDS});
    my @sync_fields = ();
    foreach my $line (@sync_fields_info) {
      my($fld, undef)=split(/:/, $line);
      push @sync_fields, $fld;
    }
    $sync_fields = join(',', @sync_fields);
  }

  if($attr->{FIELDS_INFO}) {
    my $fields = $Odoo->fields_info();

    foreach my $key  ( sort keys %{ $fields } ) {
      print "$key : $fields->{$key}\n";
    }
  }
  else {
    my $users_list = $Odoo->user_list({
      FIELDS => $sync_fields
    });

    if($argv->{SYNC_COMPANY}) {
      company_import($users_list);
    }
    else {
      user_import($users_list);
    }

    #DEBUG:
    if(! $argv->{SKIP_SERVICE}) {
      my $service_list = $Odoo->contracts_list();

      if($argv->{SYNC_COMPANY}) {
        odoo_service_sync_company($service_list);
      }
      else {
        #Service sync
        odoo_service_sync($service_list);
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 user_import($users_list); - Sync users

  Arguments:
    $users_list_arr - list of import users

=cut
#**********************************************************
sub user_import {
  my($users_list)=@_;

  my $count        = 0;
  my $update_count = 0;
  my $domain_id    = 0;

  if($argv->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    $domain_id=$argv->{DOMAIN_ID};
  }

  if($debug > 3) {
    print "Sync fields\n";
    my $result_fields = $users_list->[0];
    print show_hash($result_fields, { DELIMITER => "\n" });
  }

  my $sync_field = 'LOGIN';

  foreach my $user_info ( @$users_list ) {
    my $sync_value = (($user_info->{$sync_field}) ? $user_info->{$sync_field} : 'Not defined');
    if ($debug > 1) {
      Encode::_utf8_off($sync_value);
      print "Sync field: $sync_field Remote filed: " . $sync_value . "\n";
    }

    #Get location_id
    my $location_id = get_location_id($user_info);

    if ($location_id) {
      $user_info->{LOCATION_ID}=$location_id;
    }

    if ($argv->{GET_LOCATION}) {
      next;
    }

    if ($argv->{ADD_GID}) {
      $user_info->{GID}=$argv->{ADD_GID};
    }

    $Users->{debug}=1 if($debug > 6);
    my $user_list = $Users->list({
      $sync_field  => $user_info->{$sync_field},
      REGISTRATION => '_SHOW',
      LOCATION_ID  => '_SHOW',
      COLS_NAME    => '_SHOW'
    });

    if ($Users->{TOTAL}) {
      if($debug > 1) {
        print "====> $user_info->{LOGIN} exists UID: $user_list->[0]->{uid} REGISTRATION: $user_list->[0]->{registration}\n";
      }

      $argv->{UPDATE}=1;
      if($argv->{UPDATE}) {
        my $uid = $user_list->[0]->{uid};
        $Users->info($uid);
        $Users->pi({ UID => $uid });

        foreach my $key ( sort keys %$Users ) {
          if(defined($user_info->{$key})) {
            $user_info->{$key} //= q{};
            if(! defined($Users->{$key})) {
              next;
            }

            if($Users->{$key} ne $user_info->{$key}) {
              if(! $Users->{$key} && ! $user_info->{$key} ) {
                next;
              }

              Encode::_utf8_off($user_info->{$key});
              Encode::_utf8_off($Users->{$key});
              print "$key: $Users->{$key} -> $user_info->{$key}\n" if($debug > 2);
              $Users->change($uid, {
                %{ $user_info },
                UID => $uid
              });

              $Users->pi_change({
                %{ $user_info },
                UID => $uid
              });
              $update_count++;
            }
          }
        }

        #sync_internet({
        #  EXT_SYSTEM => $user_info,
        #  UID        => $uid
        #});

        if($debug > 10) {
          print "--------------------------------------------\n\n";
          show_hash($user_info);
          exit;
        }
      }

      next;
    }

    if($debug > 0) {
      print "ADD LOGIN $sync_field: $sync_value\n";
    }

    if(! $user_info->{PASSWORD}) {
      $user_info->{PASSWORD} //= $user_info->{LOGIN}.'1234567890';
    }

    if ($argv->{SKIP_WRONG_MAIL} && $user_info->{EMAIL}) {
      if ($user_info->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
        delete $user_info->{EMAIL};
      }
    }

    my Users $User = $Users->add({
      %{ $user_info },
      CREATE_BILL => 1,
      DOMAIN_ID   => $domain_id
    });

    if(! $User->{errno}) {
      print "Registred UID: $User->{UID}\n";
      $user_info->{UID}=$User->{UID};
      $User->pi_add($user_info);
    }
    else {
      if($Users->{errno} == 11) {
        print "Error: $User->{errno} $User->{errstr} '$user_info->{EMAIL}'\n";
      }
      else {
        print "Error: $User->{errno} $User->{errstr}\n";
      }
    }

    $count++;
    if($count > $import_limit) {
      exit;
    }

    if ($user_info->{DEPOSIT}) {
      $user_info->{SUM}  = $user_info->{DEPOSIT};
      $user_info->{USER} = $User;
      internet_wizard_fin($user_info);
    }

    if ($user_info->{SERVICES} && $user_info->{SERVICES}->{4}) {
      $user_info->{SERVICES}->{4}->{UID}=$user_info->{UID};
      $user_info->{SERVICES}->{4}->{REGISTRATION}=1;
      $user_info->{SERVICES}->{4}->{QUITE}=1;
      internet_service_add($user_info->{SERVICES}->{4});
    }
  }

  if($debug > 1) {
    print "Count ADD: $count UPDATE: $update_count\n"
  }

  return 1;
}


##**********************************************************
#=head2 sync_internet($user_info);
#
#  Argumnets:
#    $attr
#      EXT_SYSTEM => $user_info,
#      UID        => $uid
#
#  Returns:
#
#  Examples:
#
#=cut
##**********************************************************
#sub sync_internet {
#  my ($attr)=@_;
#
#  my $user_info = $attr->{EXT_SYSTEM};
#  my $uid       = $attr->{UID};
#
#  my $internet_services = $Internet->user_list({
#    TP_ID     => '_SHOW',
#    CID       => '_SHOW',
#    IP        => '_SHOW',
#    UID       => $uid,
#    SHOW_COLS => 1
#  });
#
#  foreach my $i_info (@$internet_services) {
#    print "UID: $i_info->{UID} ID: $i_info->{ID} TP_ID: $i_info->{TP_ID} IP: $i_info->{IP}\n";
#
#    foreach my $param (keys %$i_info) {
#      print "$param: $i_info->{$param} <- ". (($user_info) ? $user_info->{$param} : q{})  ."\n";
#    }
#  }
#
#  return 1;
#}


#**********************************************************
=head2 _get_tp();


=cut
#**********************************************************
sub _get_tp {

  #$Tariffs = Tariffs->new($db, \%conf, $Admin);
  my %tps_list = ();

  my $list = $Tariffs->list({
    NAME      => '_SHOW',
    DOMAIN_ID => $admin->{DOMAIN_ID},
    COLS_NAME => 1
  });

  foreach my $line (@$list) {
    if($debug > 3) {
      print "'$line->{name}' $line->{tp_id} (DOMAIN: $admin->{DOMAIN_ID})\n";
    }
    $tps_list{$line->{name}}=$line->{tp_id}
  }

  return \%tps_list;
}


#**********************************************************
=head2 odoo_service_sync($service_list);

  Arguments:
    $service_list

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub odoo_service_sync {
  my ($service_list)=@_;

  my %login2uid = ();
  my $logins_list = $Users->list({
    LOGIN     => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });

  foreach my $line (@$logins_list) {
    $login2uid{$line->{login}}=$line->{uid};
  }

  my $tp_ids = _get_tp();
  my $Internet = Internet->new($db, $Admin, \%conf);

  my $i = 0;
  foreach my $info (@$service_list) {
    $i++;
    print $i."- $info->{id}\n" if($debug > 1);
    my %user_tp = ();
    if($info->{partner_id} &&  ref $info->{partner_id} eq 'ARRAY' && $info->{partner_id}->[0] ) {
      print "LOGIN: " . ($info->{partner_id}->[0] || 'n/d')
        . " IP: $info->{ip_antenna} TP_ID: \n" if ($debug > 1);
    }
    else {
      next;
    }

    my $ip = (ref $info->{ip_antenna}  eq '') ? $info->{ip_antenna} : '0.0.0.0';
    my $cid = (ref $info->{mac_antenna}  eq '') ? $info->{mac_antenna} : '';
    my $login = $info->{partner_id}->[0];

    foreach my $tp_name  (@{ $info->{product_id} }) {
      if($tp_ids->{$tp_name}) {
        my $tp_id = $tp_ids->{$tp_name};
        $user_tp{$tp_id}++;
        print "  $tp_name ($tp_id)\n" if($debug>2);
      }
      else {
        print "  $tp_name ('n/d')\n" if($debug>2);
      }
    }

    my $service_count = scalar(keys %user_tp);

    my $internet_list = $Internet->user_list({
      LOGIN     => $login,
      TP_ID     => '_SHOW',
      ID        => '_SHOW',
      CID       => '_SHOW',
      GROUP_BY  => 'internet.id',
      COLS_NAME => 1
    });

    if($Internet->{TOTAL}) {
      foreach my $list ( @$internet_list ) {
        if($user_tp{$list->{tp_id}}) {
          print "LOGIN: $login TP: $list->{tp_id} !!!!!!!!!!!!!!!!!!!!! exist service\n" if($debug > 1);
          if ($user_tp{$list->{tp_id}} == 1) {
            delete $user_tp{$list->{tp_id}};
          }
          else {
            $user_tp{$list->{tp_id}}--;
          }
        }
        # Change tp on main system
        elsif($service_count == 1) {
          my @tps = keys %user_tp;
          my $new_tp = $tps[0] || 0;
          if($debug > 1) {
            print "CHANGE: $internet_list->[0]->{uid} -> $new_tp\n";
          }

          if($new_tp) {
            $Internet->user_add({
              UID   => $internet_list->[0]->{uid},
              TP_ID => $new_tp,
              IP    => $ip,
              CID   => $cid,
              CHECK_EXIST_TP => 1
            });

            if($Internet->{errno}) {
              print "ERROR: $Internet->{errno} $Internet->{errstr}\n";
            }
          }

#          print "$login // ". ($internet_list->[0]->{id} || q{-})
#            .", // ". ($internet_list->[0]->{uid} || q{--})
#            .", // ". ($ip || q{---}) ."\n";

          delete $user_tp{$list->{tp_id}};
        }

        $Internet->user_change({
          ID    => $internet_list->[0]->{id},
          UID   => $internet_list->[0]->{uid},
          CID   => $cid,
          #TP_ID => $new_tp,
          IP    => $ip
        });

      }
    }

    foreach my $tp_id ( keys %user_tp ) {
      if(! $login2uid{$login}) {
        print "Unknow UID for LOGIN: $login\n ";
        next;
      }
      #print "!!! $login // $user_tp{$tp_id} //\n";
      for (my $num=1; $num<=$user_tp{$tp_id} || 0; $num++) {
        if ($debug > 0) {
          print "ADD: " . ($login2uid{$login} || qq{NO UID LOGIN: $login }) . " -> " . ($tp_id || 'n/d') . "\n";
        }

        $Internet->user_add({
          UID   => $login2uid{$login},
          TP_ID => $tp_id,
          IP    => $ip,
          CID   => $cid,
          CHECK_EXIST_TP => 1
        });

        if($Internet->{errno}) {
          print "ERROR: [$Internet->{errno}] $Internet->{errstr}\n";
        }

        if ($user_tp{$tp_id} == 1) {
          #delete $user_tp{$tp_id};
        }
        else {
          $user_tp{$tp_id}--;
        }
      }
    }
  }

  return 1;
}


#**********************************************************
=head2 company_import($users_list); - Sync users

  Arguments:
    $users_list

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub company_import {
  my($users_list)=@_;

  my $count        = 0;
  my $update_count = 0;
  my $domain_id    = 0;

  if($argv->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    $domain_id=$argv->{DOMAIN_ID};
  }

  if($debug > 3) {
    print "Sync fields\n";
    my $result_fields = $users_list->[0];
    print show_hash($result_fields, { DELIMITER => "\n" });
  }

  foreach my $user_info ( @$users_list ) {
    my $sync_field = 'LOGIN';
    print "Sync field: $sync_field Remote filed: ". (($user_info->{$sync_field}) ? $user_info->{$sync_field} : 'Not defined' )."\n" if ($debug > 1);

    my $axbills_sync_field = $sync_field;
    if($sync_field eq 'LOGIN') {
      $axbills_sync_field = '_ODOO';
      $user_info->{_ODOO} = $user_info->{$sync_field};
    }
    elsif($sync_field eq 'LOGIN') {
      $axbills_sync_field = 'COMPANY_NAME';
      $user_info->{$axbills_sync_field} = $user_info->{$sync_field};
    }

    $user_info->{NAME}=$user_info->{FIO};

    if($debug > 3) {
      print "=================================\n";
      print show_hash($user_info, { DELIMITER => "\n" });
    }

    $Companies->{debug}=1 if($debug > 6);
    my $user_list = $Companies->list({
      $axbills_sync_field => $user_info->{$sync_field},
      REGISTRATION   => '_SHOW',
      COLS_NAME      => '_SHOW',
      SKIP_DEL_CHECK => 1
    });

    if ($Companies->{TOTAL}) {
      if($debug > 1) {
        print "====> $user_info->{LOGIN} exists COMPANY_ID: $user_list->[0]->{id} REGISTRATION: $user_list->[0]->{registration}\n";
      }

#      $argv->{UPDATE}=1;
      if($argv->{UPDATE}) {
        my $company_id = $user_list->[0]->{id};
        $Companies->info($company_id);

        foreach my $key ( sort keys %$Companies ) {
          if(defined($user_info->{$key})) {
            $user_info->{$key} //= q{};
            if(! defined($Companies->{$key})) {
              next;
            }

            if($Companies->{$key} ne $user_info->{$key}) {
              if(! $Companies->{$key} && ! $user_info->{$key} ) {
                next;
              }

              Encode::_utf8_off($user_info->{$key});
              Encode::_utf8_off($Companies->{$key});
              print "$key: $Companies->{$key} -> $user_info->{$key}\n" if($debug > 2);

              $Companies->change({
                %{ $user_info },
                ID => $company_id
              });
              $update_count++;
            }
          }
        }

        #sync_internet({
        #  EXT_SYSTEM => $user_info,
        #  UID        => $uid
        #});

        if($debug > 10) {
          print "--------------------------------------------\n\n";
          show_hash($user_info);
          exit;
        }
      }

      next;
    }

    if($debug > 0) {
      print "ADD LOGIN $sync_field: $user_info->{$sync_field}\n";
    }

    if(! $user_info->{PASSWORD}) {
      $user_info->{PASSWORD} //= $user_info->{LOGIN}.'1234567890';
    }

    if ($argv->{SKIP_WRONG_MAIL} && $user_info->{EMAIL}) {
      if ($user_info->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
        delete $user_info->{EMAIL};
      }
    }

    my Companies $Company = $Companies->add({
      %{ $user_info },
      CREATE_BILL => 1,
      DOMAIN_ID   => $domain_id
    });

    if(! $Company->{errno}) {
      print "REGISTRED COMPANY_ID: $Company->{ID}\n";
      $user_info->{ID}=$Company->{ID};
    }
    else {
      if($Company->{errno} == 11) {
        print "ERROR: $Company->{errno} $Company->{errstr} '$user_info->{EMAIL}'\n";
      }
      else {
        print "ERROR: $Company->{errno} $Company->{errstr}\n";
      }
    }

    $count++;
    if($count > $import_limit) {
      return 1;
    }
  }

  if($debug > 1) {
    print "COUNT ADD: $count UPDATE: $update_count\n"
  }

  return 1;
}

#**********************************************************
=head2 company_import2($users_list); - Sync users

  Arguments:
    $users_list

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub company_import2 {
  my($users_list)=@_;

  my $count        = 0;
  my $update_count = 0;
  my $domain_id    = 0;

  if($argv->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    $domain_id=$argv->{DOMAIN_ID};
  }

  if($debug > 2) {
    print "IMPORT COUNT: ". ($#{$users_list}+1) ."\n";
  }

  if($debug > 3) {
    print "Sync fields\n";
    my $result_fields = $users_list->[0];
    print show_hash($result_fields, { DELIMITER => "\n" });
  }

  foreach my $user_info ( @$users_list ) {

    if($domain_id) {
      $user_info->{DOMAIN_ID}=$domain_id;
    }

    my $sync_field = 'COMPANY_NAME';
    print "Sync field: $sync_field Remote filed: ". (($user_info->{id}) ? $user_info->{id} : 'Not defined' )."\n" if ($debug > 1);

    my $axbills_sync_field = $sync_field;
    $axbills_sync_field = 'COMPANY_NAME';
    $user_info->{$axbills_sync_field} = $user_info->{$sync_field};
    $user_info->{COMPANY_NAME}=$user_info->{name} || $user_info->{FIO} || q{};
    $user_info->{NAME}=$user_info->{name} || $user_info->{FIO} || q{};

    if($debug > 3) {
      print "=================================\n";
      print show_hash($user_info, { DELIMITER => "\n" });
    }

    if(! $user_info->{$sync_field}) {
      print "ERROR: Key field not defined: ". ($axbills_sync_field || q{empty_key}) . " => ". ($user_info->{$sync_field} || q{empty}) . " ID: $user_info->{id}\n";
      next;
    }

    $Companies->{debug}=1 if($debug > 6);

    my $user_list = $Companies->list({
      $axbills_sync_field => $user_info->{$sync_field},
      #PHONE          => $user_info->{phone},
      REGISTRATION   => '_SHOW',
      COLS_NAME      => '_SHOW',
      SKIP_DOMAIN    => '_SHOW',
      DOMAIN_ID      => undef,
      SKIP_DEL_CHECK => 1
    });

    if ($Companies->{TOTAL}) {
      if($debug > 1) {
        print "====> $user_info->{id} exists COMPANY_ID: $user_list->[0]->{id} REGISTRATION: $user_list->[0]->{registration}\n";
      }

      #      $argv->{UPDATE}=1;
      my $company_id = $user_list->[0]->{id};
      if($argv->{UPDATE}) {
        $Companies->info($company_id);

        foreach my $key ( sort keys %$Companies ) {
          if(defined($user_info->{$key})) {
            $user_info->{$key} //= q{};
            if(! defined($Companies->{$key})) {
              next;
            }

            if($Companies->{$key} ne $user_info->{$key}) {
              if(! $Companies->{$key} && ! $user_info->{$key} ) {
                next;
              }

              Encode::_utf8_off($user_info->{$key});
              Encode::_utf8_off($Companies->{$key});
              print "$key: $Companies->{$key} -> $user_info->{$key}\n" if($debug > 2);

              $Companies->change({
                %{ $user_info },
                ID => $company_id
              });
              $update_count++;
            }
          }
        }

        #sync_internet({
        #  EXT_SYSTEM => $user_info,
        #  UID        => $uid
        #});

        if($debug > 10) {
          show_hash($user_info);
          exit;
        }
      }

      $user_info->{COMPANY_ID}=$company_id;
      add_user($user_info);
      next;
    }

    if($debug > 0) {
      print "ADD COMPANY: $sync_field: ". ($user_info->{$sync_field} || 'n/d') ." ID: $user_info->{id}\n";
    }

    if(! $user_info->{PASSWORD}) {
      $user_info->{PASSWORD} //= $user_info->{id}.'1234567890';
    }

    if ($argv->{SKIP_WRONG_MAIL} && $user_info->{EMAIL}) {
      if ($user_info->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
        delete $user_info->{EMAIL};
      }
    }

    if($debug > 7) {
      $Companies->{debug} = 1;
    }

    my Companies $Company = $Companies->add({
      %{$user_info},
      #NAME        => $user_info->{id},
      PHONE       => $user_info->{phone},
      CREATE_BILL => 1,
      DOMAIN_ID   => $domain_id,
      ID          => undef
    });

    if(! $Company->{errno}) {
      print "REGISTRED COMPANY_ID: $Company->{ID}\n";
      $user_info->{ID}=$Company->{ID};
    }
    else {
      if($Company->{errno} == 11) {
        print "ERROR: $Company->{errno} $Company->{errstr} '$user_info->{EMAIL}'\n";
      }
      elsif($Company->{errno} == 8) {
        print "ERROR: Not defined company_name $Company->{errno} $Company->{errstr}\n";
      }
      else {
        print "ERROR: COMAPNY_ADD $Company->{errno} $Company->{errstr}\n";
      }
    }

    $count++;
    if($count > $import_limit) {
      return 1;
    }
  }

  if($debug > 1) {
    print "COUNT ADD: $count UPDATE: $update_count\n"
  }

  return 1;
}


#**********************************************************
=head2 add_user($service_list);

=cut
#**********************************************************
sub add_user {
  my($services_info)=@_;

  foreach my $service_info ( @{ $services_info->{contracts} } ) {
    if($debug > 1) {
      print "\nLOGIN: " . $service_info->{contract_id} . " \n"
        . "TP_NAME: $service_info->{contract_lines}->[0]->{product_name} \n"
        . "COMPANY_ID: $services_info->{id} \n"
      ;
    }

    if($debug > 6) {
      $Users->{debug}=1;
    }

    my $u_list = $Users->list({ LOGIN => $service_info->{contract_id}, COLS_NAME => 1 });

    my %users_params = (
      LOGIN      => $service_info->{contract_id},
      PASSWORD   => $service_info->{router_password},
      COMPANY_ID => $services_info->{COMPANY_ID},
    );

    if($argv->{DOMAIN_ID}) {
      $users_params{DOMAIN_ID}=$argv->{DOMAIN_ID};
      $service_info->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    }

    if(! $Users->{TOTAL}) {
      $Users->add({
        %users_params,
        CREATE_BILL=> 1
      });

      $service_info->{UID}=$Users->{UID};
      add_internet($service_info);
    }
    else {
      $Users->change($u_list->[0]->{uid}, {
        UID        => $u_list->[0]->{uid},
        %users_params
      });

      $service_info->{UID}=$u_list->[0]->{uid};
      add_internet($service_info);
    }
  }

  return 1;
}


#**********************************************************
=head2 odoo_service_sync($service_info);

  Arguments:
    $service_info

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub add_internet {
  my ($service_info)=@_;

  my $Internet = Internet->new($db, $Admin, \%conf);

  if($debug > 6) {
    $Internet->{debug} = 1;
  }

  $Internet->user_list({ UID => $service_info->{UID} });

  my $tp_name = $service_info->{contract_lines}->[0]->{product_name};
  my $tp_ids = _get_tp();
  my $ip    = (ref $service_info->{ip_antenna}  eq '') ? $service_info->{ip_antenna} : '0.0.0.0';
  my $cid   = (ref $service_info->{mac_antenna}  eq '') ? $service_info->{mac_antenna} : '';

  Encode::_utf8_off($tp_name);
  if(! $tp_ids->{"$tp_name"}) {
    if($debug > 6) {
      $Tariffs->{debug}=1;
    }

    print ">>>>>>>>>>>>>>>>>>>>>>>>> '$tp_name' ". ($tp_ids->{$tp_name} || q{}) ."\n\n";

    $Tariffs->add({
      #ID        => 0,
      NAME      => $tp_name,
      #MONTH_FEE => $add_values{4}{MONTH_FEE},
      #USER_CREDIT_LIMIT => $add_values{4}{USER_CREDIT_LIMIT},
      MODULE    => 'Internet',
      DOMAIN_ID => $service_info->{DOMAIN_ID}
    });
    $tp_ids->{$tp_name} = $Tariffs->{TP_ID};

    if($debug > 4) {
      print "ADD TP: '$tp_name' DOMAIN_ID: ". ($service_info->{DOMAIN_ID} || q{}) ." ID: $Tariffs->{TP_ID}\n";

      foreach my $key ( sort keys %$tp_ids ) {
        print "-- '$key' '$tp_ids->{$key}'\n";
      }
    }

    exit;
  }

  if(! $Internet->{TOTAL}) {
    $Internet->user_add({
      UID   => $service_info->{UID},
      TP_ID => $tp_ids->{$tp_name} || 0,
      IP    => $ip,
      CID   => $cid,
      PASSWORD  => $service_info->{router_password},
      LOGIN  => $service_info->{router_user},
      CHECK_EXIST_TP => 1
    });
  }
  else {
    $Internet->user_change({
      UID   => $service_info->{UID},
      TP_ID => $tp_ids->{$tp_name} || 0,
      IP    => $ip,
      CID   => $cid,
      PASSWORD  => $service_info->{router_password},
      LOGIN  => $service_info->{router_user},
      CHECK_EXIST_TP => 1
    });
  }

  if($Internet->{errno}) {
    print "ERROR: $Internet->{errno} $Internet->{errstr} UID: $service_info->{UID}\n";
  }

  return 1;
}


#**********************************************************
=head2 odoo_service_sync($service_list);

  Arguments:
    $service_list

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub odoo_service_sync_company {
  my ($service_list)=@_;

  my %login2uid = ();
  my $domain_id = 0;
  if($argv->{DOMAIN_ID}) {
    $admin->{DOMAIN_ID}=$argv->{DOMAIN_ID};
    $domain_id=$argv->{DOMAIN_ID};
  }

  my $logins_list = $Users->list({
    LOGIN      => '_SHOW',
    COMPANY_ID => '_SHOW',
    CONTRACT_ID=> '_SHOW',
    COLS_NAME  => 1,
    PAGE_ROWS  => 1000000
  });

  foreach my $line (@$logins_list) {
    $login2uid{$line->{login}}=$line->{uid};
  }

  my %odoo2company = ();

  my $company_list = $Companies->list({
    _ODOO     => '_SHOW',
    COMPANY_ID=> '_SHOW',
    DOMAIN_ID => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    SKIP_DEL_CHECK => 1
  });

  foreach my $line (@$company_list) {
    $odoo2company{$line->{_odoo}}=$line->{id};
  }

  my $tp_ids = _get_tp();
  my $Internet = Internet->new($db, $Admin, \%conf);

  my $i = 0;
  foreach my $info (@$service_list) {
    $i++;
    print $i."- $info->{id}\n" if($debug > 1);

    my %user_tp = ();
    if($info->{partner_id} &&  ref $info->{partner_id} eq 'ARRAY' && $info->{partner_id}->[0] ) {
      if ($debug > 1) {
        print "LOGIN: " . ($info->{partner_id}->[0] || 'n/d')
          . " IP: $info->{ip_antenna} TP_ID: \n";
      }
    }
    else {
      next;
    }

    my $ip    = (ref $info->{ip_antenna}  eq '') ? $info->{ip_antenna} : '0.0.0.0';
    my $cid   = (ref $info->{mac_antenna}  eq '') ? $info->{mac_antenna} : '';
    my $login = $info->{partner_id}->[0];
    my $odoo_id = $info->{partner_id}->[0];
    # ABillS TP
    my $product_id = $info->{product_id}->[0];

    if(! $product_id) {
      print "-----------------------------------------\n";
      print $info->{product_id};
      print "///////\n";
      print @{ $info->{product_id} };
      print "-----------------------------------------\n";
      next;
    }

    my $uid   = $login2uid{$product_id};

    foreach my $tp_name  (@{ $info->{product_id} }) {
      if($tp_ids->{$tp_name}) {
        my $tp_id = $tp_ids->{$tp_name};
        $user_tp{$tp_id}++;
        print "  $tp_name ($tp_id)\n" if($debug>2);
      }
      else {
        print "  $tp_name ('n/d')\n" if($debug>2);
      }
    }

    if($debug > 1) {
      show_hash($info, { DELIMITER => "\n" });
    }

    if(! $uid) {
      if($debug > 3) {
        print "ADD LOGIN/CONTRACT: $info->{product_id}->[0] / \n";
      }

      if(! $odoo2company{$odoo_id}) {
        print "ERROR: No company: '_odoo' ODOO_ID: $odoo_id // $info->{id}\n";
        next;
      }

      if(! $login2uid{$info->{product_id}->[0]} ) {
        my Users $User = $Users->add({
          LOGIN       => $info->{product_id}->[0],
          COMPANY_ID  => $odoo2company{$odoo_id},
          CREATE_BILL => 1,
          DOMAIN_ID   => $domain_id
        });

        if (!$User->{errno}) {
          print "REGISTRED UID: $User->{UID}\n";
          $User->pi_add({
            CONTARCT_ID => $info->{product_id}->[0],
            UID         => $User->{UID}
          });
        }
        else {
          if ($Users->{errno} == 11) {
            print "Error: $User->{errno} $User->{errstr} '->{EMAIL}'\n";
          }
          else {
            print "Error: $User->{errno} $User->{errstr}\n";
          }
        }
      }

      exit;
    }

    next;
    my $service_count = scalar(keys %user_tp);

    my $internet_list = $Internet->user_list({
      LOGIN     => $login,
      TP_ID     => '_SHOW',
      ID        => '_SHOW',
      CID       => '_SHOW',
      GROUP_BY  => 'internet.id',
      COLS_NAME => 1
    });

    if($Internet->{TOTAL}) {
      foreach my $list ( @$internet_list ) {
        if($user_tp{$list->{tp_id}}) {
          print "LOGIN: $login TP: $list->{tp_id} !!!!!!!!!!!!!!!!!!!!! exist service\n" if($debug > 1);
          if ($user_tp{$list->{tp_id}} == 1) {
            delete $user_tp{$list->{tp_id}};
          }
          else {
            $user_tp{$list->{tp_id}}--;
          }
        }
        # Change tp on main system
        elsif($service_count == 1) {
          my @tps = keys %user_tp;
          my $new_tp = $tps[0] || 0;
          if($debug > 1) {
            print "CHANGE: $internet_list->[0]->{uid} -> $new_tp\n";
          }

          if($new_tp) {
            $Internet->add({
              UID   => $internet_list->[0]->{uid},
              TP_ID => $new_tp,
              IP    => $ip,
              CID   => $cid,
              CHECK_EXIST_TP => 1
            });

            if($Internet->{errno}) {
              print "ERROR: $Internet->{errno} $Internet->{errstr}\n";
            }
          }

          #          print "$login // ". ($internet_list->[0]->{id} || q{-})
          #            .", // ". ($internet_list->[0]->{uid} || q{--})
          #            .", // ". ($ip || q{---}) ."\n";

          delete $user_tp{$list->{tp_id}};
        }

        $Internet->user_change({
          ID    => $internet_list->[0]->{id},
          UID   => $internet_list->[0]->{uid},
          CID   => $cid,
          #TP_ID => $new_tp,
          IP    => $ip
        });

      }
    }

    foreach my $tp_id ( keys %user_tp ) {
      if(! $login2uid{$login}) {
        print "Unknow UID for LOGIN: $login\n ";
        next;
      }
      #print "!!! $login // $user_tp{$tp_id} //\n";
      for (my $num=1; $num<=$user_tp{$tp_id} || 0; $num++) {
        if ($debug > 0) {
          print "ADD: " . ($login2uid{$login} || qq{NO UID LOGIN: $login }) . " -> " . ($tp_id || 'n/d') . "\n";
        }

        $Internet->add({
          UID   => $login2uid{$login},
          TP_ID => $tp_id,
          IP    => $ip,
          CID   => $cid,
          CHECK_EXIST_TP => 1
        });

        if($Internet->{errno}) {
          print "ERROR: [$Internet->{errno}] $Internet->{errstr}\n";
        }

        if ($user_tp{$tp_id} == 1) {
          #delete $user_tp{$tp_id};
        }
        else {
          $user_tp{$tp_id}--;
        }
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 get_location_id($user_info) - Check exist location and coordinats

  Arguments:
    $user_info

  Returns:
    $location_id

=cut
#**********************************************************
sub get_location_id {
  my ($user_info)=@_;

  my $location_id = 0;
  if ($debug > 6) {
    $Address->{debug}=1;
  }

  my $builds_list = $Address->build_list({
    DISTRAICT_NAME => $user_info->{CITY},
    STREET_NAME    => $user_info->{ADDRESS_STREET},
    NUMBER         => $user_info->{ADDRESS_BUILD},
    COORDX         => '_SHOW',
    COORDY         => '_SHOW',
    COLS_NAME      => '_SHOW'
  });

  if ($Address->{TOTAL} == 0) {
    my $district_id = 1;

    my %district_params = ();
    $district_params{NAME} = $user_info->{CITY} || 'DEFAULT';

    my $districts_list = $Address->district_list({
      %district_params,
      COLS_NAME => 1
    });

    if ($Address->{TOTAL}) {
      $district_id = $districts_list->[0]->{id};
    }
    else {
      $Address->district_add({ NAME => $user_info->{CITY} || 'DEFAULT' });
      $district_id = $Address->{DISTRICT_ID};
      $Address->{debug}=0;
    }

    my $streets_list = $Address->street_list({
      STREET_NAME => $user_info->{ADDRESS_STREET},
      DISTRICT_ID => $district_id,
      COLS_NAME   => 1
    });

    my $street_id = 0;
    if($Address->{TOTAL}) {
      $street_id=$streets_list->[0]->{id};
    }
    else {
      $Address->street_add({ NAME => $user_info->{ADDRESS_STREET}, DISTRICT_ID => $district_id  });

      if ($Address->{errno}) {
        print "ERROR: NAME => $user_info->{ADDRESS_STREET}, DISTRICT_ID => $district_id\n";
      }
      else {
        $street_id = $Address->{STREET_ID};
      }
    }

    $Address->build_add({
      STREET_ID => $street_id,
      NUMBER    => $user_info->{ADDRESS_BUILD},
      COORDX    => $user_info->{ADDRESS_COORDX},
      COORDY    => $user_info->{ADDRESS_COORDY},
      ZIP       => $user_info->{ZIP},
      FLORS     => $user_info->{ADDRESS_BUILD_FLORS},
      ENTRANCES => $user_info->{ADDRESS_BUILD_ENTRANCES},
    });

    if ($Address->{errno}) {
      Encode::_utf8_off($user_info->{ADDRESS_STREET});
      Encode::_utf8_off($user_info->{ADDRESS_BUILD});
      print "ERROR: $street_id ($user_info->{ADDRESS_STREET}) $user_info->{ADDRESS_BUILD}\n";
    }
    else {
      $location_id = $Address->{LOCATION_ID};
    }
  }
  else {
    $location_id=$builds_list->[0]->{id};

    if ($user_info->{ADDRESS_COORDX} && $user_info->{ADDRESS_COORDY}
      && (
        ($user_info->{ADDRESS_COORDX} ne $builds_list->[0]->{coordx})
        || ($user_info->{ADDRESS_COORDY} ne $builds_list->[0]->{coordy})
        )
      ) {

      $Address->build_change({
        ID     => $location_id,
        COORDX => $user_info->{ADDRESS_COORDX},
        COORDY => $user_info->{ADDRESS_COORDY},
      });
    }
  }

  return $location_id;
}

1;
