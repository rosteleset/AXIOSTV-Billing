=head1 NAME

  Api

=head1 VERSION

  VERSION: 0.07

=cut

use strict;
use warnings;
use Test::More;
use Test::JSON::More;
use Getopt::Long;
use FindBin '$Bin';

BEGIN {
  our $libpath = '../../../../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'lib/AXbills');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'AXbills/');
  unshift(@INC, $libpath . 'AXbills/modules/');

  eval {require Time::HiRes;};
  our $global_begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $global_begin_time = Time::HiRes::gettimeofday();
  }
}

our (
  $libpath,
  $Bin,
  $html,
  %FORM,
  %LIST_PARAMS,
  %functions,
  %conf,
);

require $Bin . "/../../../../libexec/config.pl";
my $debug = 3;
$conf{language} = 'english';
$ENV{DEBUG} = 1;
$ENV{'REQUEST_METHOD'} = 'GET';
use AXbills::Fetcher;
use Data::Dumper;

require AXbills::HTML;
require AXbills::SQL;
require Admins;
require Conf;
our $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { %conf, CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
our $admin = Admins->new($db, \%conf);
our $Conf = Conf->new($db, $admin, \%conf);
$ENV{DEBUG} = 1;
require Userside::Api;

do "./Task.t";
our %task_request_list;

do '/usr/axbills/language/english.pl';
my %request_list = (
  'get_api_information'                 => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "properties": {
          "version": {
            "type": "string"
          },
          "date": {
            "type": "string"
          }
        },
        "required": [
          "version",
          "date"
        ]
      }
    )
  },
  'get_city_district_list'              => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "id": { "type": "integer" },
              "city_id": { "type": "integer" },
              "name": { "type": "string" }
            },
            "required": [ "id", "city_id", "name" ]
          }
        },
        "additionalProperties": false
      }
    )
  },
  'get_city_list'                       => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "id": { "type": "integer" },
              "name": { "type": "string" }
            },
            "required": ["id", "name"]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_device_list'                     => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "snmp_version": {
                "type": "string"
              },
              "model_id": {
                "type": "integer"
              },
              "id": {
                "type": "integer"
              },
              "house_id": {
                "type": "integer"
              },
              "mac": {
                "type": "string"
              },
              "ip": {
                "type": "string"
              }
            },
            "required": [
              "snmp_version",
              "model_id",
              "id",
              "house_id",
              "mac",
              "ip"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_device_model'                    => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "id": { "type": "integer" },
              "type_id": { "type": "string" },
              "name": { "type": "string" },
              "iface_count": { "type": "integer" }
            },
            "required": [
                    "name",
                    "id",
                    "type_id"
                  ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_device_type'                     => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[a-zA-Z0-9]+$": {
            "type": "object",
            "properties": {
              "id": { "type": "string" },
              "name": { "type": "string" }
            },
            "required": [
              "name",
              "id"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_house_list'                      => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^.+$": {
            "type": "object",
            "properties": {
              "id": { "type": "integer" },
              "street_id": { "type": "integer" },
              "floor": { "type": "integer" },
              "entrance": { "type": "integer" },
              "full_name": { "type": "string" },
              "number": { "type": "string" },
              "street_id": { "type": "integer" }
            },
            "required": [
              "id",
              "street_id",
              "floor",
              "entrance",
              "full_name"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },


  # 'get_house_list'                      => {
  #   params => {
  #     get_index => 'us_api',
  #     key       => '1523615231263123',
  #     cat       => 'module',
  #     json      => 1,
  #   },
  #   schema => q(
  #     {
  #       "type": "object",
  #       "patternProperties": {
  #         "^[0-9]+$": {
  #           "type": "object",
  #           "properties": {
  #             "id": { "type": "integer" },
  #             "street_id": { "type": "integer" },
  #             "floor": { "type": "integer" },
  #             "entrance": { "type": "integer" },
  #             "full_name": { "type": "string" },
  #             "number": { "type": "string" },
  #             "street_id": { "type": "integer" }
  #           },
  #           "required": [
  #             "id",
  #             "street_id",
  #             "floor",
  #             "entrance",
  #             "full_name"
  #           ]
  #         }
  #       },
  #       "additionalProperties": false
  #     }
  #   ),
  # },

  'get_services_list'                   => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "id": { "type": "integer" },
              "name": { "type": "string" },
              "cost": { "type": "string" }
            },
            "required": [
              "name",
              "id",
              "cost"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_street_list'                     => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "id": { "type": "integer" },
              "name": { "type": "string" },
              "city_id": { "type": "integer" },
              "type_name": { "type": "string" },
              "full_name": { "type": "string" }
            },
            "required": [
              "name",
              "id",
              "full_name"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_supported_change_user_data_list' => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "[A-Za-z0-9]": {
            "type": "object",
            "properties": {
              "comment": { "type": "string" }
            },
            "required": [
              "comment"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_supported_method_list'           => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "[A-Za-z0-9]": {
            "type": "object",
            "properties": {
              "comment": { "type": "string" }
            },
            "required": [
              "comment"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_system_information'              => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "properties": {
          "date": {
            "type": "string"
          },
          "os": {
            "type": "string"
          },
          "billing": {
            "type": "object",
            "properties": {
              "name": {
                "type": "string"
              },
              "version": {
                "type": "string"
              }
            },
            "required": [
              "name",
              "version"
            ]
          }
        },
        "required": [
          "date",
          "os",
          "billing"
        ]
      }
    ),
  },
  'get_tariff_list'                     => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "[A-Za-z0-9]": {
            "type": "object",
                  "properties": {
                    "name": {
                      "type": "string"
                    },
                    "payment_interval": {
                      "type": "integer"
                    },
                    "speed": {
                      "type": "object",
                      "properties": {
                        "up": {
                          "type": "integer"
                        },
                        "down": {
                          "type": "integer"
                        }
                      },
                      "required": [
                        "up",
                        "down"
                      ]
                    },
                    "traffic": {
                      "type": "integer"
                    },
                    "service_type": {
                      "type": "integer"
                    },
                    "is_in_billing": {
                      "type": "integer"
                    },
                    "userside_id": {
                      "type": "integer"
                    }
                  },
                  "required": [
                    "name",
                    "payment_interval",
                    "speed",
                    "traffic",
                    "service_type"
                  ]
                }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_user_additional_data_type_list'  => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "id": {
                "type": "integer"
              },
              "name": {
                "type": "string"
              }
            },
            "required": [
              "id",
              "name"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_user_group_list'                 => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "id": {
                "type": "integer"
              },
              "name": {
                "type": "string"
              }
            },
            "required": [
              "id",
              "name"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_user_history'                    => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "date": {
                "type": "string"
              },
              "id": {
                "type": "integer"
              },
              "data": {
                "type": "string"
              },
              "comment": {
                "type": "integer"
              },
              "name": {
                "type": "string"
              },
              "type": {
                "type": "integer"
              },
              "customer_id": {
                "type": "integer"
              }
            },
            "required": [
              "date",
              "id",
              "data",
              "comment",
              "name",
              "type",
              "customer_id"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_user_list'                       => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
              "type": "object",
              "patternProperties": {
                "^[0-9]+$": {
                  "type": "object",
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "full_name": {
                      "type": "string"
                    },
                    "flag_corporate": {
                      "type": "integer"
                    },
                    "balance": {
                      "type": "string"
                    },
                    "state_id": {
                      "type": "integer"
                    },
                    "traffic": {
                      "type": "object",
                      "properties": {
                        "month": {
                          "type": "object",
                          "properties": {
                            "up": {
                              "type": "integer"
                            },
                            "down": {
                              "type": "integer"
                            }
                          },
                          "required": [
                            "up",
                            "down"
                          ]
                        }
                      },
                      "required": [
                        "month"
                      ]
                    },
                    "date_create": {
                      "type": "string"
                    },
                    "date_connect": {
                      "type": "string"
                    },
                    "date_activity": {
                      "type": "string"
                    },
                    "date_activity_inet": {
                      "type": "string"
                    },
                    "is_disable": {
                      "type": "integer"
                    },
                    "address": {
                      "type": "array",
                      "items": [
                        {
                          "type": "object",
                          "properties": {
                            "type": {
                              "type": "string"
                            },
                            "house_id": {
                              "type": "integer"
                            },
                            "apartment": {
                              "type": "object",
                              "properties": {
                                "full_name": {
                                  "type": "string"
                                },
                                "number": {
                                  "type": "string"
                                }
                              },
                              "required": [
                                "full_name",
                                "number"
                              ]
                            },
                            "entrance": {
                              "type": "integer"
                            },
                            "floor": {
                              "type": "string"
                            }
                          },
                          "required": [
                            "house_id",
                            "apartment"
                          ]
                        }
                      ]
                    },
                    "is_in_billing": {
                      "type": "integer"
                    },
                    "email": {
                      "type": "array",
                      "items": [
                        {
                          "type": "object",
                          "properties": {
                            "address": {
                              "type": "string"
                            },
                            "flag_main": {
                              "type": "integer"
                            }
                          },
                          "required": [
                            "address",
                            "flag_main"
                          ]
                        }
                      ]
                    },
                    "agreement": {
                      "type": "array",
                      "items": [
                        {
                          "type": "object",
                          "properties": {
                            "number": {
                              "type": "string"
                            },
                            "date": {
                              "type": "string"
                            }
                          },
                          "required": [
                            "number",
                            "date"
                          ]
                        }
                      ]
                    },
                    "account_number": {
                      "type": "string"
                    },
                    "login": {
                      "type": "string"
                    },
                    "phone": {
                      "type": "array",
                      "items": [
                        {
                          "type": "object",
                          "properties": {
                            "number": {
                              "type": "string"
                            },
                            "flag_main": {
                              "type": "integer"
                            }
                          },
                          "required": [
                            "number"
                          ]
                        },
                        {
                          "type": "object",
                          "properties": {
                            "number": {
                              "type": "string"
                            }
                          },
                          "required": [
                            "number"
                          ]
                        }
                      ]
                    },
                    "billing_id": {
                      "type": "string"
                    }
                  },
                  "required": [
                    "id",
                    "full_name",
                    "flag_corporate",
                    "balance",
                    "state_id",
                    "traffic",
                    "date_create",
                    "address",
                    "email",
                    "login",
                    "billing_id"
                  ]
                }
              },
              "additionalProperties": false
            }
    ),
  },
  'get_user_messages'                   => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "msg_date": {
                "type": "string"
              },
              "subject": {
                "type": "string"
              },
              "user_id": {
                "type": "integer"
              },
              "id": {
                "type": "integer"
              },
              "text": {
                "type": "string"
              }
            },
            "required": [
              "msg_date",
              "subject",
              "user_id",
              "id",
              "text"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_user_state_list'                 => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "id": {
                "type": "integer"
              },
              "name": {
                "type": "string"
              },
              "functional": {
                "type": "string"
              }
            },
            "required": [
              "id",
              "name",
              "functional"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_user_tags'                       => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^[0-9]+$": {
            "type": "object",
            "properties": {
              "id": {
                "type": "integer"
              },
              "name": {
                "type": "string"
              }
            },
            "required": [
              "id",
              "name"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
);

my %final_request_list = (%request_list, %task_request_list);

get_json(\%final_request_list);

sub get_json {
  my ($request_list) = @_;

  my %opts = ();
  GetOptions(
    'local'          => \$opts{local},
    'userside'       => \$opts{userside},
    'remote=s'       => \$opts{remote},
    'key=s'          => \$opts{key},
    'debug=s'        => \$opts{debug},
    'request=s'      => \$opts{request},
    'max_rows=s'     => \$opts{max_rows},
    'start_page=s'   => \$opts{start_page},
    'uid=s'          => \$opts{uid},
    'help'           => \$opts{help},
    'skip_traffic=s' => \$opts{skip_traffic},
  );

  if ($opts{help}) {
    help();
  }

  %LIST_PARAMS = (
    MAX_ROWS     => $opts{max_rows},
    START_PAGE   => $opts{start_page} || 0,
    DEBUG        => $opts{debug} || 0,
    UID          => $opts{uid},
    SKIP_TRAFFIC => $opts{skip_traffic},
  );

  my $count = 0;
  foreach my $request (sort keys %$request_list) {
    $count++;
    my $json = q{};
    my $start = Time::HiRes::gettimeofday();
    if ($opts{request}) {
      $request = $opts{request};
    }

    if ($opts{remote}) {
      if ($opts{key}) {
        $request_list->{$request}->{params}{key}=$opts{key};
      }

      $json = get_remote_request($opts{remote} . '/admin/index.cgi', $request_list->{$request}->{params}, $request);
    }
    elsif ($opts{userside}) {
      my $request_url = "http://demo.userside.eu/api.php?key=keyus&cat=module&request=$request";

      if ($debug > 2) {
        print "REQUEST_URL: $request_url\n";
      }

      $json = web_request($request_url, { CURL => 1, TIMEOUT => 300 });
    }
    else {
      userside_api($request, { %{$request_list->{$request}->{params}}, %opts, %LIST_PARAMS });
      $json = $html->{RESULT};
    }

    if ($opts{debug}) {
      if ($opts{debug} > 1) {
        print "COUNT:" . $count . "<json>";
      }

      print $json . "\n";

      if ($opts{debug} > 1) {
        print "<json>\n";
      }

      if ($opts{debug} > 2) {
        print $count . ".<schema>" . Dumper($request_list->{$request}->{schema}) . "<schema>\n";
      }

      $debug = $opts{remote};
    }

    my $end = Time::HiRes::gettimeofday();
    printf("%.2f ", $end - $start);
    #    print "\n------------------------------------------\n";
    #    print $json;
    #    print "\n------------------------------------------\n";
    #    print "$request_list->{$request}->{schema}\n";
    #    print "\n------------------------------------------\n";

    #{"error":"unknown_method"}
    if ($json =~ /\{"error":(.+)/) {
      print $1;
      print "\n";
      next;
    }

    ok_json_schema($json, $request_list->{$request}->{schema}, $request);
    @{$html->{JSON_OUTPUT}} = ();
    if ($opts{request}) {
      last;
    }
  }

  done_testing();
  return 1;
}

sub get_remote_request {
  my ($url, $params, $request) = @_;

  $url .= "?";
  foreach my $key (keys %$params) {
    $url .= "$key=$params->{$key}&";
  }

  $url .= "request=$request";

  return web_request($url, {
    INSECURE => 1,
    DEBUG    => ($debug && $debug > 3) ? 1 : 0
  });
}

sub help {

  print qq{
  -local
  -userside
  -remote=
    -key=[REMOTE API KEY]
  -debug=0..10
  -request=
  -max_rows=
  -start_page=
  -uid=
  -skip_traffic=
  -help
};

  exit;
  #return 1;
}


1;
