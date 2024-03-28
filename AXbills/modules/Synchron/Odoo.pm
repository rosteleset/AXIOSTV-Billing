package Synchron::Odoo;

=head1 NAME

  Odoo import functions

=head1 VERSION

  VERSION: 0.01
  REVISION: 20170317


=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(load_pmodule show_hash);
use AXbills::Fetcher;
use JSON;

our $VERSION = 0.01;

#**********************************************************
=head2 new($attr)

   Arguments:
     $attr

   Examples:

   my $Odoo = AXbills::Import::Odoo->new({
     LOGIN    => $username,
     PASSWORD => $password,
     URL      => $url,
     DBNAME   => $dbname,
     debug    => $debug,
     CONF     => \%conf
   });

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $attr  = shift;

  my $self = {
    SERVICE_CONSOLE => 'Odoo',
    SEND_MESSAGE    => 1,
    SERVICE_NAME    => 'Odoo',
    VERSION         => $VERSION
  };

  bless($self, $class);

  load_pmodule('Frontier::Client');

  $self->{LOGIN}    = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{DBNAME}   = $attr->{DBNAME};
  $self->{URL}      = $attr->{URL};
  $self->{debug}    = $attr->{DEBUG} || 0;
  $self->{CONF}     = $attr->{CONF};

  if($attr->{JSON}) {
    $self->auth_json();
  }
  else {
    $self->auth();
  }

  return $self;
}

#**********************************************************
=head2 version($attr) - Test service

=cut
#**********************************************************
sub version {
  my $self = shift;

  my $server = Frontier::Client->new(
    url   => $self->{URL}. '/xmlrpc/2/common',
    debug => ($self->{debug} && $self->{debug} > 3) ? 1 : 0
  );
  my $res    = $server->call('version');

  $self->{VERSION} = $res;

  return $self;
}

#**********************************************************
=head2 user_list($attr)

  Arguments:
    $attr
      FIELDS
      EMAIL
      PAGE_ROWS

  Returns:


=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  my $models = Frontier::Client->new(url => $self->{URL} . "/xmlrpc/2/object");
  my $fields = $self->fields_info();

#  - checkbox "Is a Company" +
#  - listbox компаний

  my @fields_show = ();
  if($attr->{FIELDS}) {
    @fields_show = split(/,\s?/, $attr->{FIELDS});
  }
  else {
    @fields_show = keys %$fields;
  }

  my @WHERE = (
#    ['is_company', '=', 1],
#    ['customer', '=', 1]
  );

  if($self->{CONF}->{SYNCHRON_ODOO_TYPE}) {
    @WHERE = ();
    my @expr = split(/;/, $self->{CONF}->{SYNCHRON_ODOO_TYPE});
    foreach my $line (@expr) {
      push @WHERE,  [ split(/,\s?/, $line) ];
    }
  }

  if($self->{debug}) {
    print "REQUEST WHERE: $self->{CONF}->{SYNCHRON_ODOO_TYPE}";
    print join(', ', @WHERE) ."\n";
  }

  my $ids = $models->call('execute_kw', $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
    'res.partner',
    'search_read',
    [
     \@WHERE
    ],
  {
    'fields' => \@fields_show
  });

  return $self->_filter_result($ids, { FIELDS => $fields });
}

#**********************************************************
=head2 invoice_list($attr)

  Arguments:
    $attr
      FIELDS
      EMAIL
      PAGE_ROWS

  Returns:

=cut
#**********************************************************
sub invoice_list {
  my $self = shift;
  #my ($attr) = @_;

  my $models = Frontier::Client->new(url => $self->{URL} . "/xmlrpc/2/object");

  my $list = $models->call('execute_kw',
    $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
    'account.invoice',
    'search_read',
    [],
    {'limit' => 5}
    );

  $list = $self->_filter_result($list);

  return $list || [];
}


#**********************************************************
=head2 auth($attr)

  Arguments:
    $attr
      EMAIL
      PAGE_ROWS

  Returns:


=cut
#**********************************************************
sub auth {
  my $self = shift;

  my $server = Frontier::Client->new(
    url   => "$self->{URL}/xmlrpc/2/common",
    debug => ($self->{debug} && $self->{debug} > 3) ? 1 : 0
  );

  my $uid = $server->call('authenticate', $self->{DBNAME}, $self->{LOGIN}, $self->{PASSWORD}, [ ]);
  $self->{UID}=$uid;

#  my $models = Frontier::Client->new(url => "$url/xmlrpc/2/object");
#  my $access = $models->call('execute_kw', $dbname, $uid, $password,
#    'res.partner',
#    'check_access_rights',
#    ['read'],
#    { 'raise_exception' => 1 } );

  return $self;
}


#**********************************************************
=head2 auth($attr)

  Arguments:
    $attr
      EMAIL
      PAGE_ROWS

  Returns:


=cut
#**********************************************************
sub auth_json {
  my $self = shift;

  use JSON::RPC::Client;

  my $client = new JSON::RPC::Client;
  $self->{client}=$client;
  my $url = $self->{URL}; # 'http://www.example.com/jsonrpc/API';


  my $callobj = {
    'debug'   => 1,
    'params'  => { 'args' => [ $self->{DBNAME}, $self->{LOGIN}, $self->{PASSWORD} ],
      'method'            => 'login',
      'service'           => 'common'
    },
    'jsonrpc' => '2.0',
    'method'  => 'call',
    'id'      => 184826094
  };

  my $res = $client->call($url, $callobj);

  if ($res) {
    if ($res->is_error) {
      print "Error : ";
      print "CODE: ". $res->error_message->{code};
      print " MESSAGE: ". $res->error_message->{message};
      print "\n----------------------------------\n";
      print %{ $res->error_message->{data} };
      print "\n----------------------------------\n";
    }
    else {
      #print $res->result;
    }
  }
  else {
    print $client->status_line;
  }

  $self->{UID}=$res->result;

  return $self;
}

#**********************************************************
=head2 fields_list($attr)

  Arguments:
    $model - (res.partner)

  Returns:


=cut
#**********************************************************
sub fields_list {
  my $self = shift;
  my ($model, $attr) = @_;

  my $models = Frontier::Client->new(url => $self->{URL} . "/xmlrpc/2/object");
  my $table = 'execute_kw';

  #$attr->{TABLE}='account.analytic.account';
  if($attr->{TABLE}) {
    $table = $attr->{TABLE};
  }

  my $list = $models->call($table, $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
    $model || q{},
    'fields_get',
    [''],
    { 'attributes' => [ 'string', 'help', 'type' ] }
  );

  return $list || [];
}


#**********************************************************
=head2 contracts_list($attr)

  Arguments:
    $attr
      PARTNER_ID
      INTERNET

  Returns:

=cut
#**********************************************************
sub contracts_list {
  my $self = shift;
  my ($attr) = @_;

  my $models = Frontier::Client->new(url => $self->{URL} . "/xmlrpc/2/object");
  my @partner_id = ();
  if($attr->{PARTNER_ID}) {
    push @partner_id, [ ("partner_id", "=", $attr->{PARTNER_ID}) ];
  }

  if($attr->{INTERNET}) {
    push @partner_id,  [ ( "recurring_invoice_line_ids.product_id.type", "=", 'internet' ) ] ;
  }

  my $list = $models->call('execute_kw',
    $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
    'account.analytic.account',
    'search_read',
    [
      \@partner_id
    ],
    {
      'fields'=> ['id', 'partner_id', 'recurring_invoice_line_ids', 'ip_antenna', 'mac_antenna', 'code' ],
    }
  );

  my $list2 = $models->call('execute_kw',
    $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
    'account.analytic.invoice.line',
    'search_read',
    [], #[[[  'id', '=', $list->[0]->{recurring _invoice_line_ids} ]]],
    {
      'fields'=> ['id', 'product_id' ],
    }
  );

  my %contracts_ids = ();
  foreach my $line (@$list2) {
    $contracts_ids{$line->{id}}=join('', @{ $line->{product_id} });
  }

  for(my $i=0; $i<=$#{ $list }; $i++) {
    my $line = $list->[$i];
    my @contracts = ();
    foreach my $id ( @{ $line->{recurring_invoice_line_ids} } ) {
      push @contracts, $contracts_ids{$id};
    }

    $list->[$i]->{product_id}=\@contracts;
  }

  return $list || [];
}

#**********************************************************
=head2 fields_info()

  Arguments:
    $model - (res.partner)

  Returns:


=cut
#**********************************************************
sub fields_info {
  #my $self = shift;

  my %fields = (
    country_id    => 'COUNTRY_ID',
    name          => 'FIO',
    id            => 'LOGIN',
    #id            => 'EXT_ID',
    comment       => 'COMMENTS',
    credit        => 'CREDIT',
    phone_account => 'PHONE',
    debit         => 'DEPOSIT',
    zip           => 'ZIP',
    display_name  => 'FIO',
    create_date   => 'REGISTRATION',
    phone         => 'PHONE',
    email         => 'EMAIL',
    street        => 'ADDRESS',
    zip           => 'ZIP',
    code          => 'CONTRACT_ID',
    # Info fields
    is_company	  => '_IS_COMPANY',
    website	      => '_WEBSITE', #char	Website	Website of Partner or Company
    category_id	  => '_CATEGORY_ID', #many2many	Tags
    fax           => '_FAX', #	char	Fax
    function	    => '_FUNCTION', #char	Job Position
    vat           => 'PASPORT_NUM',
    ip_pc         => 'IP',
    mac_antenna   => 'CID'

    #info fields
  );

  return \%fields;
}


#**********************************************************
=head2 fields_info()

  Arguments:
    $model - (res.partner)

  Returns:


=cut
#**********************************************************
sub reports_list {

  my @reports_list = (
    'invoice_list',
    'contracts_list'
  );

  return \@reports_list;
}


#**********************************************************
=head2 filter_result($list, $attr)

  Arguments:
    $list
    $attr
      FIELDS - Fields hash info

  Returns:


=cut
#**********************************************************
sub _filter_result {
  my $self = shift;
  my ($list, $attr) = @_;

  if(ref $list ne 'ARRAY') {
    return $list;
  }

  my $fields = $attr->{FIELDS};

  my @users_list = ();
  foreach my $line (@$list) {
    my %info_row = ();
    foreach my $key (keys %$line) {
      my $value = $line->{$key};
      my $type = ref $value;

      if ($type && $type =~ /Frontier::RPC2::Boolean/) {
        $value = '';
      }
      elsif ($type && $type eq 'ARRAY') {
        $value = join("<br>\n", @$value);
      }

      if ($fields && !$fields->{$key}) {
        print "Unsync field: $key\n" if ($self->{debug});
        next;
      }

      if($fields && $fields->{$key}) {
        if($fields->{$key} eq 'CREDIT') {
          $value = abs($value);
        }

        $info_row{$fields->{$key}} = $value; #. " (//$type)";
      }
      else {
        $info_row{$key} = $value;
      }
    }

    push @users_list, \%info_row;
  }

  return \@users_list;
}


#**********************************************************
=head2 read_partner_contracts($attr)

  Arguments:
    $attr
      PARTNER_ID
      INTERNET

  Returns:

=cut
#**********************************************************
sub read_partner_contracts {
  my $self = shift;
  my ($attr) = @_;

#=comments
#  data = {
#    'category_ids': [4],
#      'product_types': ['internet'],
#  }
#  from datetime import datetime
#    start = datetime.now()
#  contracts = json_rpc(SERVER_URL, 'object', 'execute', DATABASE, user_id, PASSWORD, 'axbills.api', 'get_partner_contracts', data)
#  print datetime.now() - start
#    print len(contracts)
#  print contracts
#=cut
#
#
#
#  my $models = Frontier::Client->new(
#    url => $self->{URL} . "/xmlrpc/2/object",
#    debug => 1
#  );
##  my @partner_id = ();
###  if($attr->{PARTNER_ID}) {
###    push @partner_id, [ ("partner_id", "=", $attr->{PARTNER_ID}) ];
###  }
###
###  if($attr->{INTERNET}) {
###    push @partner_id,  [ ( "recurring_invoice_line_ids.product_id.type", "=", 'internet' ) ] ;
###  }
##
#
#  my $list = $models->call('execute',
#    $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
#    'axbills.api',
#    'get_partner_contracts',
#    {
##      'category_ids'  => 4,
##      'product_types' => 'internet' ,
##       'category_ids'  => [4] ,
##       'product_types' => ['internet'] ,
#    },
#    {
#      'fields' => [ '*' ],
#    }
#  );
#
##*********************************************
##  partners = json_rpc(SERVER_URL, 'object', 'execute_kw', DATABASE, user_id, PASSWORD, 'res.partner', 'search_read',
##    [[]],
##  {'fields': ['id', 'name', 'phone', 'email', 'street', 'vat']}
##  )
#
##    my $list = $models->call('execute_kw',
##      $self->{DBNAME}, $self->{UID}, $self->{PASSWORD},
##      'res.partner',
##      'search_read',
##      [
##        [  ],
##      ],
##      {
##         'fields'=> ['*'],
##      }
##    );
#
#
#  print @$list;

  my %params = ();

  if($attr->{PRODUCT_TYPES}) {
    $params{product_types}=[$attr->{PRODUCT_TYPES}];
  }

  if($attr->{CATEGORY_IDS}) {
    $params{category_ids}=[$attr->{CATEGORY_IDS}];
  }

  my $callobj = {
    'debug' => 1,
    'params' => {
      'args' => [ $self->{DBNAME}, $self->{UID}, $self->{LOGIN}, 'axbills.api', 'get_partner_contracts',
        \%params
      ],
      'method' =>  'execute',
      'service'=> 'object'
    },
    'jsonrpc' => '2.0',
    'method'  => 'call',
    'id'      => int(rand(1000000000))
  };

  if($self->{debug}) {
    print "\nRequest:\n";
    print JSON::to_json($callobj);
    print "\n-----------------------------------\n";
  }

  my $list =  $self->{client}->call($self->{URL}, $callobj);

  my $fields = fields_custom_info();
  return $self->_filter_result($list, { FIELDS => $fields });

  #return $list || [];
}

#**********************************************************
=head2 fields_custom_info($attr)

  Arguments:
    $attr
      PARTNER_ID
      INTERNET

  Returns:

=cut
#**********************************************************
sub fields_custom_info {

  my %fields = (
    city           => 'CITY',
    contracts      => '',
    antenna_type   => '',
    autoprovision  => '',
    contract_id    => 'LOGIN',
    contract_lines => '',
    id             => '_ODOO_ID',
    price_unit     => '',
    product_name   => 'TP_NAME',
    product_type   => '',
    quantity       => '',
    cutoff_date    => '',
    date_end       => '',
    date_start     => '',
    description    => '',
    ip_antenna     => 'IP',
    ip_pc          => '',
    iptv_login     => '',
    iptv_mac       => '',
    iptv_model     => '',
    iptv_pack      => '',
    iptv_password  => '',
    iptv_serial_number => '',
    mac_antenna    => 'CID',
    mac_ipphone    => '',
    model  => '',
    motive => '',
    ont_ip => '',
    ont_ip_lan => '',
    ont_model => '',
    ont_open_ports => '',
    ont_serial_number => '',
    ont_wifi_name => '',
    ont_wifi_password => '',
    phone_account => '',
    phone_ip => '',
    phone_mac => '',
    phone_number => '',
    phone_password => '',
    phone_user => '',
    reference => '',
    router => '',
    router_mac      => 'CID',
    router_password => 'PASSWORD',
    router_series   => '',
    router_user     => 'INTERNET_LOGIN',
    sector_bts      => '',
    signal          => '',
    speed => '',
    state => '',
    wifi_password => '',
    wifi_ssid => '',
    country => '',
    country_state => '',
    credit   => 'CREDIT',
    deposit  => 'DEPOSIT',
    email    => '',
    id       => '',
    mobile   => '',
    name     => 'NAME',
    phone    => 'PHONE',
    street   => 'ADDRESS_STREET',
    street2  => '',
    zip      => 'ZIP',
  );

  return \%fields;
}
#**********************************************************
=head2 create_hotspot_user($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub create_hotspot_user {
  my $self = shift;
  my ($attr) = @_;

  my %params = ( 'name'  => $attr->{FIO} || '-',
                 'email' => $attr->{EMAIL} || '-',
                 'phone' => $attr->{PHONE} || '0',
                 'zona'  => $attr->{ssid} || '-');

  my $callobj = {
    'debug' => 1,
    'params' => {
      'args' => [ $self->{DBNAME}, $self->{UID}, $self->{PASSWORD}, 'crm.hotspot.users', 'create',
        [\%params]
      ],
      'method' =>  'execute_kw',
      'service'=> 'object'
    },
    'jsonrpc' => '2.0',
    'method'  => 'call',
    'id'      => int(rand(1000000000))
  };

  if($self->{debug}) {
    print "\nRequest:\n";
    print JSON::to_json($callobj);
    print "\n-----------------------------------\n";
  }

  my $list =  $self->{client}->call($self->{URL}, $callobj);
  return $list || [];
}

1;
