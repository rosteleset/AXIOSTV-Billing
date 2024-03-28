=head1 NAME

  JSON API test

=cut

use strict;
use warnings;
use lib '.';

do "/usr/axbills/t/JSON.t";

my $api_key = '1523615231263123';
my $user = 'test';
my $passwd = '123456';

my @test_list = (
  {
    name   => 'TARFIIF_PLAN_LIST',
    params => {
      get_index      => 'internet_tp',
      EXPORT_CONTENT => 'INTERNET_TARIF_PLANS',
      header         => 1,
      json           => 1,
      # API_KEY        => $api_key
      user           => $user,
      passwd         => $passwd
    },
    result     => '',
    valid_json => 1
  },
  {
    name   => 'BILLING_VERSION',
    params => {
      # API_KEY  => $api_key,
      API_INFO => 'system_information',
      json     => 1,
      user           => $user,
      passwd         => $passwd
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      properties => {
        TABLE_system_information => {
          type       => "object",
          properties => {
            ID     => { type => "string" },
            DATA_1 => {
              type    => "array",
              "items" => {
                "type"   => "object",
                required => [ "billing", "version", "date", "updated", "name", "os" ],
              },
            }
          },
          required => ["DATA_1"],
        },
      },
      required => ["TABLE_system_information"],
    }
  },
  {
    name   => 'INTERNET_TP',
    params => {
      get_index      => 'internet_tp',
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      EXPORT_CONTENT => 'INTERNET_TARIF_PLANS',
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      required   => [ "ID", "DATA_1" ],
      properties => {
        ID     => { type => "string" },
        DATA_1 => {
          type    => "array",
          "items" => {
            "type"   => "object",
            required => [ "name", "time_tarifs", "traf_tarifs", "day_fee", "month_fee", "payment_type", "module" ],
          },
        }
      }
    }
  },
  {
    name   => 'USER_FIND',
    params => {
      qindex         => 7,
      search         => 1,
      type           => 10,
      SKIP_FULL_INFO => 1,
      LOGIN          => 'axbills',
      EXPORT_CONTENT => 'USERS_LIST',
      EXPORT         => 1,
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      required   => [ "ID", "DATA_1" ],
      properties => {
        ID     => { type => "string" },
        DATA_1 => {
          type    => "array",
          "items" => {
            "type"   => "object",
            required => [ "login", "fio", "deposit", "credit", "login_status", "phone", "email", "contract_id", "comments", "uid", "city", "address_full" ],
          },
        }
      }
    }
  },

  #DOESNT WORK
  {
    name   => 'USERS_LIST',
    params => {
      qindex  => 15,
      UID     => 109058,
      EXPORT  => 1,
      # API_KEY => $api_key,
        user           => $user,
        passwd         => $passwd,
      json    => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      properties => {
        NAME       => { type => "string" },
        HEADER     => { type => "string" },
        SIZE       => { type => "string" },
        PROPORTION => { type => "string" },
      }
    }
  },
  {
    name   => 'DISTRICTS_LIST',
    params => {
      get_index      => 'form_districts',
      EXPORT_CONTENT => 'DISTRICTS_LIST',
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      required   => [ "ID", "DATA_1" ],
      properties => {
        ID     => { type => "string" },
        DATA_1 => {
          type    => "array",
          "items" => {
            "type"   => "object",
            required => [ "name", "country", "city", "zip", "street_count", "total" ],
          },
        }
      }
    }
  },
  {
    name   => 'STREETS_LIST',
    params => {
      get_index      => "form_streets",
      EXPORT_CONTENT => 'STREETS_LIST',
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      required   => [ "ID", "DATA_1" ],
      properties => {
        ID     => { type => "string" },
        DATA_1 => {
          type    => "array",
          "items" => {
            "type"   => "object",
            required => [ "street_name", "build_count", "users_count", "id" ],
          },
        }
      }
    }
  },
  {
    name   => 'BUILDS_LIST',
    params => {
      get_index      => 'form_streets',
      EXPORT_CONTENT => 'BUILDS_LIST',
      BUILDS         => 102,
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      required   => [ "ID", "DATA_1" ],
      properties => {
        ID     => { type => "string" },
        DATA_1 => {
          type    => "array",
          "items" => {
            "type"   => "object",
            required => [ "number", "flors", "entrances", "flats", "street_name", "users_count", "users_connections", "added", "coordx" ],
          },
        }
      }
    }
  },
  {
    name       => 'INFO_FIELDS',
    params     => {
      get_index       => 'form_info_fields',
        user           => $user,
        passwd         => $passwd,
      json         => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      properties => {
        TABLE_INFO_FIELDS => {
          type       => "object",
          properties => {
            ID     => { type => "string" },
            DATA_1 => {
              type    => "array",
              "items" => {
                "type"   => "object",
                required => [ "name", "sql_field", "type", "priority", "abon_portal", "sql_field", "user_chg", "company", "module", "comment" ],
              },
            }
          },
          required   => [ "DATA_1" ],
        },
      },
      required   => [ "TABLE_INFO_FIELDS" ],
    }
  },
  #DOESNT WORK
  {
    name   => 'GROUPS',
    params => {
      get_index      => 'form_groups',
      EXPORT_CONTENT => 'GROUPS',
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      required   => [ "ID", "DATA_1" ],
      properties => {
        ID     => { type => "string" },
        DATA_1 => {
          type    => "array",
          "items" => {
            "type"   => "object",
            required => [ "gid", "name", "descr", "users_count", "allow_credit", "disable_paysys", "disable_chg_tp" ],
          },
        }
      }
    }
  },
  {
    name   => 'INTERNET_USERS_LIST',
    params => {
      get_index      => 'internet_users_list',
      EXPORT_CONTENT => 'INTERNET_USERS_LIST',
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      required   => [ "ID", "DATA_1" ],
      properties => {
        ID     => { type => "string" },
        DATA_1 => {
          type    => "array",
          "items" => {
            "type"   => "object",
            required => [ "login", "fio", "deposit", "credit", "tp_name", "internet_status", "uid", "tp_id" ],
          },
        }
      }
    }
  },
  {
    name   => 'INTERNET_USERS_LIST EXTENDED',
    params => {
      get_index      => 'internet_users_list',
      search         => 1,
      header         => 1,
      SKIP_FULL_INFO => 1,
      show_columns   => 'LOGIN,UID,PORT,VLAN,SERVER_VLAN,ADDRESS_FULL,FIO,DEPOSIT,INTERNET_STATUS,NAS_ID',
      NAS_ID         => '*',
      EXPORT_CONTENT => 'INTERNET_USERS_LIST',
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => q(
      {
        "type": "object",
        "definitions": {},
        "properties": {
          "CAPTION": {
            "$id": "/properties/CAPTION",
            "type": "string",
            "title": "The Caption Schema",
            "default": "",
            "examples": [
              ""
            ]
          },
          "ID": {
            "$id": "/properties/ID",
            "type": "string",
            "title": "The Id Schema",
            "default": "",
            "examples": [
              "INTERNET_USERS_LIST"
            ]
          },
          "TITLE": {
            "$id": "/properties/TITLE",
            "type": "array",
            "items": {
              "$id": "/properties/TITLE/items",
              "type": "string",
              "title": "The 0 Schema",
              "default": "",
              "examples": [
                ""
              ]
            }
          },
          "DATA_1": {
            "$id": "/properties/DATA_1",
            "type": "array",
            "items": {
              "$id": "/properties/DATA_1/items",
              "type": "object",
              "properties": {
                "login": {
                  "$id": "/properties/DATA_1/items/properties/login",
                  "type": "string",
                  "title": "The Login Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "fio": {
                  "$id": "/properties/DATA_1/items/properties/fio",
                  "type": "string",
                  "title": "The Fio Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "deposit": {
                  "$id": "/properties/DATA_1/items/properties/deposit",
                  "type": "string",
                  "title": "The Deposit Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "address_full": {
                  "$id": "/properties/DATA_1/items/properties/address_full",
                  "type": "string",
                  "title": "The Address_full Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "vlan": {
                  "$id": "/properties/DATA_1/items/properties/vlan",
                  "type": "string",
                  "title": "The Vlan Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "server_vlan": {
                  "$id": "/properties/DATA_1/items/properties/server_vlan",
                  "type": "string",
                  "title": "The Server_vlan Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "nas_id": {
                  "$id": "/properties/DATA_1/items/properties/nas_id",
                  "type": "string",
                  "title": "The Nas_id Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "port": {
                  "$id": "/properties/DATA_1/items/properties/port",
                  "type": "string",
                  "title": "The Port Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "tp_id": {
                  "$id": "/properties/DATA_1/items/properties/tp_id",
                  "type": "string",
                  "title": "The Tp_id Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "internet_status": {
                  "$id": "/properties/DATA_1/items/properties/internet_status",
                  "type": "string",
                  "title": "The Internet_status Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "uid": {
                  "$id": "/properties/DATA_1/items/properties/uid",
                  "type": "string",
                  "title": "The Uid Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "id": {
                  "$id": "/properties/DATA_1/items/properties/id",
                  "type": "string",
                  "title": "The Id Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "total": {
                  "$id": "/properties/DATA_1/items/properties/total",
                  "type": "string",
                  "title": "The Total Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                },
                "": {
                  "type": "string",
                  "title": "The  Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                }
              }
            }
          }
        }
      }
    )
  },
  {
    name   => 'INTERNET_USER',
    params => {
      get_index => 'internet_user',
      UID       => 2,
      # API_KEY   => $api_key,
        user           => $user,
        passwd         => $passwd,
      json      => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      properties => { required => [ "NAME", "HEADER", "SIZE", "PROPORTION", "CONTENT" ] },
    }
  },
  {
    name   => 'EQUIPMENT_INFO',
    params => {
      get_index => 'equipment_info',
      NAS_ID    => 7,
      # API_KEY   => $api_key,
        user           => $user,
        passwd         => $passwd,
      json      => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      properties => {
        NAS_NAME => { type => "string" },
        NAS_IP   => { type => "string" },
        COMMENTS => { type => "string" },
      },
    }
  },
  {
    name   => 'MSGS_LIST',
    params => {
      get_index      => 'msgs_admin',
      EXPORT_CONTENT => 'MSGS_LIST',
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      STATE          => 8,
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      required   => [ "ID", "DATA_1" ],
      properties => {
        ID     => { type => "string" },
        DATA_1 => {
          type    => "array",
          "items" => {
            "type"   => "object",
            required => [ "uid", "client_id", "id", "subject", "datetime", "admin_read", "priority_id" ],
          },
        }
      }
    }
  },
  {
    name   => 'MSGS_LIST',
    params => {
      get_index      => 'msgs_admin',
      EXPORT_CONTENT => 'MSGS_LIST',
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      STATE          => 0,
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      required   => [ "ID", "DATA_1" ],
      properties => {
        ID     => { type => "string" },
        DATA_1 => {
          type    => "array",
          "items" => {
            "type"   => "object",
            required => [ "uid", "client_id", "id", "subject", "datetime", "admin_read", "priority_id", "resposible" ],
          },
        }
      }
    }
  },

  #DOESNT WORK
  {
    name   => 'form_events ',
    params => {
      get_index => 'form_events',
      even_show => 1,
      AID       => 1,
      AJAX      => 1,
      UID       => 2,
      LOGIN     => 1,
      # API_KEY   => $api_key,
        user           => $user,
        passwd         => $passwd,
      STATE     => 0,
      json      => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      properties => {
        type    => "array",
        "items" => {
          "type"   => "object",
          required => [ "TYPE", "TITLE", "TEXT", "STATUS", "DATE", "ID", "NOTICED_URL", "EXTRA", "MODULE" ],
        },
      }
    }
  },
  {
    name   => 'Live search',
    params => {
      qindex         => 7,
      search         => 1,
      type           => 10,
      SKIP_FULL_INFO => 1,
      EXPORT_CONTENT => 'USERS_LIST',
      LOGIN          => 'axbills',
      # API_KEY        => $api_key,
        user           => $user,
        passwd         => $passwd,
      STATE          => 0,
      json           => 1
    },
    result     => '',
    valid_json => 1,
    schema     => {
      type       => "object",
      required   => [ "ID", "DATA_1" ],
      properties => {
        ID     => { type => "string" },
        DATA_1 => {
          type    => "array",
          "items" => {
            "type"   => "object",
            required => [ "fio", "login", "uid", "phone", "address_full" ],
          },
        }
      }
    }
  },
  {
    name   => 'INTERNET_ONLINE',
    params => {
      get_index      => 'internet_online',
      search         => 1,
      json           => 1,
      SKIP_FULL_INFO => 1,
      EXPORT_CONTENT => 'INTERNET_ONLINE',
      show_columns   => 'LOGIN,DURATION_SEC2,CLIENT_IP_NUM,ACCT_INPUT_OCTETS,ACCT_OUTPUT_OCTETS,CID,FIO,CONNECT_INFO,GUEST,ADDRESS_FULL',
      # API_KEY        => $api_key
      user           => $user,
      passwd         => $passwd
    },
    result     => '',
    valid_json => 1,
    schema     => qq(
      {
        "type": "object",
        "definitions": {},
        "properties": {
          "CAPTION": {
            "type": "string",
            "title": "The Caption Schema",
            "default": "",
            "examples": [
              ""
            ]
          },
          "ID": {
            "type": "string",
            "title": "The Id Schema",
            "default": "",
            "examples": [
              ""
            ]
          },
          "TITLE": {
            "type": "array",
            "items": {
              "type": "string",
              "title": "The 0 Schema",
              "default": "",
              "examples": [
                ""
              ]
            }
          },
          "DATA_1": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "login": {
                  "type": "string",
                  "title": "The Login Schema",
                  "default": "",
                  "examples": [
                    ""
                  ]
                }
              }
            }
          }
        }
      }
    )
  },
  {
    name   => 'SUMMARY_SHOW',
    params => {
      qindex      => 15,
      UID         => 112,
      SUMMARY_SHOW=> 1,
      EXPORT      => 1,
      # API_KEY     => $api_key
      user           => $user,
      passwd         => $passwd
    },
    result     => '',
    valid_json => 1,
    schema     => qq()
  }
);

json_test(\@test_list, { TEST_NAME => 'Api JSON test', UI => 1 });

1;
