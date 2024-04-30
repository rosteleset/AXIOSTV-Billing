=head1 NAME

  JSON API test

=cut

use strict;
use warnings;
use lib '.';
use FindBin '$Bin';

do $Bin . "/JSON.t";
do $Bin . "/JSON_REMOVE.t";

#Default IP for test
$ENV{REMOTE_ADDR} = '127.0.0.15';

my @test_list = (
  # https://demo.billing.axiostv.ru:9443/index.cgi?user=testuser&passwd=testuser&json=1
  {
    name       => 'MAIN_MENU',
    params     => {
      json => 1,
    },
    result     => '',
    valid_json => 1
  },
  # https://demo.billing.axiostv.ru:9443/index.cgi?user=testuser&passwd=testuser&json=1&get_index=form_info
  {
    name       => 'FORM_INFO',
    params     => {
      get_index => 'form_info',
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q(
    {
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "form_client_info"
  ],
  "properties": {
    "form_client_info": {
      "$id": "#/properties/form_client_info",
      "type": "object",
      "title": "The Form_client_info Schema",
      "required": [
        "INFO_TABLE_CLASS",
        "LOGIN",
        "UID",
        "DEPOSIT",
        "REDUCTION_DATE",
        "CREDIT_DATE",
        "FIO",
        "PHONE_ALL",
        "EMAIL",
        "CONTRACT_DATE",
        "STATUS",
        "ACTIVATE",
        "EXPIRE"
      ],
      "properties": {
        "__ACCEPT_RULES": {
          "$id": "#/properties/form_client_info/properties/__ACCEPT_RULES",
          "type": "object",
          "title": "The __accept_rules Schema",
          "required": [
            "_INFO"
          ],
          "properties": {
            "_INFO": {
              "$id": "#/properties/form_client_info/properties/__ACCEPT_RULES/properties/_INFO",
              "type": "object",
              "title": "The _info Schema",
              "required": [
                "FIO",
                "CHECKBOX",
                "HIDDEN"
              ],
              "properties": {
                "FIO": {
                  "$id": "#/properties/form_client_info/properties/__ACCEPT_RULES/properties/_INFO/properties/FIO",
                  "type": "string",
                  "title": "The Fio Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                },
                "CHECKBOX": {
                  "$id": "#/properties/form_client_info/properties/__ACCEPT_RULES/properties/_INFO/properties/CHECKBOX",
                  "type": "string",
                  "title": "The Checkbox Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                },
                "HIDDEN": {
                  "$id": "#/properties/form_client_info/properties/__ACCEPT_RULES/properties/_INFO/properties/HIDDEN",
                  "type": "string",
                  "title": "The Hidden Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                }
              }
            }
          }
        },
        "INFO_TABLE_CLASS": {
          "$id": "#/properties/form_client_info/properties/INFO_TABLE_CLASS",
          "type": "string",
          "title": "The Info_table_class Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "LOGIN": {
          "$id": "#/properties/form_client_info/properties/LOGIN",
          "type": "string",
          "title": "The Login Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "UID": {
          "$id": "#/properties/form_client_info/properties/UID",
          "type": "string",
          "title": "The Uid Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "DEPOSIT": {
          "$id": "#/properties/form_client_info/properties/DEPOSIT",
          "type": "string",
          "title": "The Deposit Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "REDUCTION_DATE": {
          "$id": "#/properties/form_client_info/properties/REDUCTION_DATE",
          "type": "string",
          "title": "The Reduction_date Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "CREDIT_DATE": {
          "$id": "#/properties/form_client_info/properties/CREDIT_DATE",
          "type": "string",
          "title": "The Credit_date Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "FIO": {
          "$id": "#/properties/form_client_info/properties/FIO",
          "type": "string",
          "title": "The Fio Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "PHONE_ALL": {
          "$id": "#/properties/form_client_info/properties/PHONE",
          "type": "string",
          "title": "The Phone Schema",
          "default": "",
          "pattern": "^(.*)$"
        },
        "ADDRESS_FLAT": {
          "$id": "#/properties/form_client_info/properties/ADDRESS_FLAT",
          "type": "string",
          "title": "The Address_flat Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "EMAIL": {
          "$id": "#/properties/form_client_info/properties/EMAIL",
          "type": "string",
          "title": "The Email Schema",
          "default": "",
          "examples": [
             ""
          ],
          "pattern": "^(.*)$"
        },
        "CONTRACT_ID": {
          "$id": "#/properties/form_client_info/properties/CONTRACT_ID",
          "type": "string",
          "title": "The Contract_id Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "CONTRACT_DATE": {
          "$id": "#/properties/form_client_info/properties/CONTRACT_DATE",
          "type": "string",
          "title": "The Contract_date Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "STATUS": {
          "$id": "#/properties/form_client_info/properties/STATUS",
          "type": "string",
          "title": "The Status Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "ACTIVATE": {
          "$id": "#/properties/form_client_info/properties/ACTIVATE",
          "type": "string",
          "title": "The Activate Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "EXPIRE": {
          "$id": "#/properties/form_client_info/properties/EXPIRE",
          "type": "string",
          "title": "The Expire Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        }
      }
    }
  }
}
    )
  },
  {
    name       => 'INTERNET_TP',
    params     => {
      get_index => 'internet_user_info',
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [

  ],
  "properties": {
    "ID": {
      "$id": "#/properties/ID",
      "type": "string",
      "title": "The Id Schema",
      "default": "",
      "examples": [
        ""
      ],
      "pattern": "^(.*)$"
    },
    "STATUS_VALUE": {
      "$id": "#/properties/STATUS_VALUE",
      "type": "string",
      "title": "The Status_value Schema",
      "default": "",
      "examples": [
        ""
      ],
      "pattern": "^(.*)$"
    },
    "TP_NAME": {
      "$id": "#/properties/TP_NAME",
      "type": "string",
      "title": "The Tp_name Schema",
      "default": "",
      "examples": [
        ""
      ],
      "pattern": "^(.*)$"
    },
    "__EXTRA_FIELDS": {
      "$id": "#/properties/__EXTRA_FIELDS",
      "type": "object",
      "title": "The __extra_fields Schema",
      "required": [
        "MONTH_ABON",
        "DAY_ABON",
        "TP_ACTIVATE_PRICE",
        "IP"
      ],
      "properties": {
        "MONTH_ABON": {
          "$id": "#/properties/__EXTRA_FIELDS/properties/MONTH_ABON",
          "type": "object",
          "title": "The Month_abon Schema",
          "required": [
            "NAME"
          ],
          "properties": {
            "NAME": {
              "$id": "#/properties/__EXTRA_FIELDS/properties/MONTH_ABON/properties/NAME",
              "type": "string",
              "title": "The Name Schema",
              "default": "",
              "examples": [
                ""
              ],
              "pattern": "^(.*)$"
            }
          }
        },
        "DAY_ABON": {
          "$id": "#/properties/__EXTRA_FIELDS/properties/DAY_ABON",
          "type": "object",
          "title": "The Day_abon Schema",
          "required": [
            "NAME"
          ],
          "properties": {
            "NAME": {
              "$id": "#/properties/__EXTRA_FIELDS/properties/DAY_ABON/properties/NAME",
              "type": "string",
              "title": "The Name Schema",
              "default": "",
              "examples": [
                ""
              ],
              "pattern": "^(.*)$"
            }
          }
        },
        "TP_ACTIVATE_PRICE": {
          "$id": "#/properties/__EXTRA_FIELDS/properties/TP_ACTIVATE_PRICE",
          "type": "object",
          "title": "The Tp_activate_price Schema",
          "required": [
            "NAME"
          ],
          "properties": {
            "NAME": {
              "$id": "#/properties/__EXTRA_FIELDS/properties/TP_ACTIVATE_PRICE/properties/NAME",
              "type": "string",
              "title": "The Name Schema",
              "default": "",
              "examples": [
                ""
              ],
              "pattern": "^(.*)$"
            }
          }
        },
        "IP": {
          "$id": "#/properties/__EXTRA_FIELDS/properties/IP",
          "type": "object",
          "title": "The Ip Schema",
          "required": [
            "NAME",
            "VALUE"
          ],
          "properties": {
            "NAME": {
              "$id": "#/properties/__EXTRA_FIELDS/properties/IP/properties/NAME",
              "type": "string",
              "title": "The Name Schema",
              "default": "",
              "examples": [
                ""
              ],
              "pattern": "^(.*)$"
            },
            "VALUE": {
              "$id": "#/properties/__EXTRA_FIELDS/properties/IP/properties/VALUE",
              "type": "string",
              "title": "The Value Schema",
              "default": "",
              "examples": [
                ""
              ],
              "pattern": "^(.*)$"
            }
          }
        }
      }
    }
  }
})
  },
  {
    name       => 'MSGS_LIST',
    params     => {
      get_index      => 'msgs_user',
      EXPORT_CONTENT => 'MSGS_LIST',
      json           => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "TABLE_MSGS_LIST",
    "TABLE_MSGS_LIST_TOTAL"
  ],
  "properties": {
    "TABLE_MSGS_LIST": {
      "$id": "#/properties/TABLE_MSGS_LIST",
      "type": "object",
      "title": "The Table_msgs_list Schema",
      "required": [
        "CAPTION",
        "ID",
        "TITLE",
        "DATA_1"
      ],
      "properties": {
        "CAPTION": {
          "$id": "#/properties/TABLE_MSGS_LIST/properties/CAPTION",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "ID": {
          "$id": "#/properties/TABLE_MSGS_LIST/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            "MSGS_LIST"
          ],
          "pattern": "^(.*)$"
        },
        "TITLE": {
          "$id": "#/properties/TABLE_MSGS_LIST/properties/TITLE",
          "type": "array",
          "title": "The Title Schema",
          "items": {
            "$id": "#/properties/TABLE_MSGS_LIST/properties/TITLE/items",
            "type": "string",
            "title": "The Items Schema",
            "default": "",
            "examples": [
              "#",
              "Subject",
              "Date",
              "Status",
              "-"
            ],
            "pattern": "^(.*)$"
          }
        },
        "DATA_1": {
          "$id": "#/properties/TABLE_MSGS_LIST/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema",
          "items": {
            "$id": "#/properties/TABLE_MSGS_LIST/properties/DATA_1/items",
            "type": "object",
            "title": "The Items Schema",
            "required": [
              "id",
              "subject",
              "datetime",
              "state",
              "inner_msg"
            ],
            "properties": {
              "id": {
                "$id": "#/properties/TABLE_MSGS_LIST/properties/DATA_1/items/properties/id",
                "type": "string",
                "title": "The Id Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "subject": {
                "$id": "#/properties/TABLE_MSGS_LIST/properties/DATA_1/items/properties/subject",
                "type": "string",
                "title": "The Subject Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "datetime": {
                "$id": "#/properties/TABLE_MSGS_LIST/properties/DATA_1/items/properties/datetime",
                "type": "string",
                "title": "The Datetime Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "state": {
                "$id": "#/properties/TABLE_MSGS_LIST/properties/DATA_1/items/properties/state",
                "type": "string",
                "title": "The State Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "inner_msg": {
                "$id": "#/properties/TABLE_MSGS_LIST/properties/DATA_1/items/properties/inner_msg",
                "type": "string",
                "title": "The Inner_msg Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              }
            }
          }
        }
      }
    },
    "TABLE_MSGS_LIST_TOTAL": {
      "$id": "#/properties/TABLE_MSGS_LIST_TOTAL",
      "type": "object",
      "title": "The Table_msgs_list_total Schema",
      "required": [
        "ID",
        "DATA_1"
      ],
      "properties": {
        "ID": {
          "$id": "#/properties/TABLE_MSGS_LIST_TOTAL/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            "MSGS_LIST_TOTAL"
          ],
          "pattern": "^(.*)$"
        },
        "DATA_1": {
          "$id": "#/properties/TABLE_MSGS_LIST_TOTAL/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema"
        }
      }
    }
  }
})
  },
  {
    name       => 'IPTV',
    params     => {
      get_index      => 'iptv_user_info',
      EXPORT_CONTENT => 'IPTV_USERS_LIST',
      json           => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "TABLE_IPTV_USERS_LIST",
    "TABLE_IPTV_USERS_LIST_TOTAL"
  ],
  "properties": {
    "TABLE_IPTV_USERS_LIST": {
      "$id": "#/properties/TABLE_IPTV_USERS_LIST",
      "type": "object",
      "title": "The Table_iptv_users_list Schema",
      "required": [
        "CAPTION",
        "ID",
        "TITLE",
        "DATA_1"
      ],
      "properties": {
        "CAPTION": {
          "$id": "#/properties/TABLE_IPTV_USERS_LIST/properties/CAPTION",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "ID": {
          "$id": "#/properties/TABLE_IPTV_USERS_LIST/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            "IPTV_USERS_LIST"
          ],
          "pattern": "^(.*)$"
        },
        "TITLE": {
          "$id": "#/properties/TABLE_IPTV_USERS_LIST/properties/TITLE",
          "type": "array",
          "title": "The Title Schema",
          "items": {
            "$id": "#/properties/TABLE_IPTV_USERS_LIST/properties/TITLE/items",
            "type": "string",
            "title": "The Items Schema",
            "default": "",
            "examples": [
              "Tariff",
              "Status",
              "MAC",
              "Abon mouth",
              "Abon day",
              "End",
              ""
            ],
            "pattern": "^(.*)$"
          }
        },
        "DATA_1": {
          "$id": "#/properties/TABLE_IPTV_USERS_LIST/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema"
        }
      }
    },
    "TABLE_IPTV_USERS_LIST_TOTAL": {
      "$id": "#/properties/TABLE_IPTV_USERS_LIST_TOTAL",
      "type": "object",
      "title": "The Table_iptv_users_list_total Schema",
      "required": [
        "ID",
        "DATA_1"
      ],
      "properties": {
        "ID": {
          "$id": "#/properties/TABLE_IPTV_USERS_LIST_TOTAL/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            "IPTV_USERS_LIST_TOTAL"
          ],
          "pattern": "^(.*)$"
        },
        "DATA_1": {
          "$id": "#/properties/TABLE_IPTV_USERS_LIST_TOTAL/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema"
        }
      }
    }
  }
})
  },
  {
    name       => 'CREDIT_USER',
    params     => {
      get_index => 'form_info',
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "form_client_info"
  ],
  "properties": {
    "form_client_info": {
      "$id": "#/properties/form_client_info",
      "type": "object",
      "title": "The Form_client_info Schema",
      "required": [
        "DEPOSIT",
        "CREDIT",
        "CREDIT_DATE"
      ],
      "properties": {
        "DEPOSIT": {
          "$id": "#/properties/form_client_info/properties/DEPOSIT",
          "type": "string",
          "title": "The Deposit Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "CREDIT": {
          "$id": "#/properties/form_client_info/properties/CREDIT",
          "type": "string",
          "title": "The Credit Schema",
          "default": "",
          "examples": [
           ""
          ],
          "pattern": "^(.*)$"
        },
        "CREDIT_DATE": {
          "$id": "#/properties/form_client_info/properties/CREDIT_DATE",
          "type": "string",
          "title": "The Credit_date Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        }
      }
    }
  }
})
  },
  {

    name       => 'PAYSYS_PAYMENT',
    params     => {
      get_index => 'paysys_payment',
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "PAYSYS_FORM"
  ],
  "properties": {
    "PAYSYS_FORM": {
      "$id": "#/properties/PAYSYS_FORM",
      "type": "object",
      "title": "The Paysys_form Schema",
      "required": [
        "OPERATION_ID",
        "__PAY_SYSTEM_SEL"
      ],
      "properties": {
        "OPERATION_ID": {
          "$id": "#/properties/PAYSYS_FORM/properties/OPERATION_ID",
          "type": "string",
          "title": "The Operation_id Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "__PAY_SYSTEM_SEL": {
          "$id": "#/properties/PAYSYS_FORM/properties/__PAY_SYSTEM_SEL",
          "type": "object",
          "title": "The __pay_system_sel Schema",
          "required": [
            "PAYSYS_62"
          ],
          "properties": {
            "PAYSYS_62": {
              "$id": "#/properties/PAYSYS_FORM/properties/__PAY_SYSTEM_SEL/properties/PAYSYS_62",
              "type": "object",
              "title": "The Paysys_62 Schema",
              "required": [
                "PAY_SYSTEM",
                "CHECKED",
                "PAY_SYSTEM_LC",
                "PAY_SYSTEM_NAME"
              ],
              "properties": {
                "PAY_SYSTEM": {
                  "$id": "#/properties/PAYSYS_FORM/properties/__PAY_SYSTEM_SEL/properties/PAYSYS_62/properties/PAY_SYSTEM",
                  "type": "string",
                  "title": "The Pay_system Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                },
                "CHECKED": {
                  "$id": "#/properties/PAYSYS_FORM/properties/__PAY_SYSTEM_SEL/properties/PAYSYS_62/properties/CHECKED",
                  "type": "string",
                  "title": "The Checked Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                },
                "PAY_SYSTEM_LC": {
                  "$id": "#/properties/PAYSYS_FORM/properties/__PAY_SYSTEM_SEL/properties/PAYSYS_62/properties/PAY_SYSTEM_LC",
                  "type": "string",
                  "title": "The Pay_system_lc Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                },
                "PAY_SYSTEM_NAME": {
                  "$id": "#/properties/PAYSYS_FORM/properties/__PAY_SYSTEM_SEL/properties/PAYSYS_62/properties/PAY_SYSTEM_NAME",
                  "type": "string",
                  "title": "The Pay_system_name Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                }
              }
            },
          }
        }
      }
    }
  }
})
  },
  {
    name       => 'PAYSYS_PAYMENT_LIST',
    params     => {
      get_index => 'form_finance',
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "TABLE_FEES",
    "TABLE_PAYMENTS"
  ],
  "properties": {
    "TABLE_FEES": {
      "$id": "#/properties/TABLE_FEES",
      "type": "object",
      "title": "The Table_fees Schema",
      "required": [
        "CAPTION",
        "ID",
        "TITLE",
        "DATA_1"
      ],
      "properties": {
        "CAPTION": {
          "$id": "#/properties/TABLE_FEES/properties/CAPTION",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "ID": {
          "$id": "#/properties/TABLE_FEES/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            "FEES"
          ],
          "pattern": "^(.*)$"
        },
        "TITLE": {
          "$id": "#/properties/TABLE_FEES/properties/TITLE",
          "type": "array",
          "title": "The Title Schema",
          "items": {
            "$id": "#/properties/TABLE_FEES/properties/TITLE/items",
            "type": "string",
            "title": "The Items Schema",
            "default": "",
            "examples": [
              "Date",
              "Description",
              "Sum",
              "Deposit",
              "Type"
            ],
            "pattern": "^(.*)$"
          }
        },
        "DATA_1": {
          "$id": "#/properties/TABLE_FEES/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema",
          "items": {
            "$id": "#/properties/TABLE_FEES/properties/DATA_1/items",
            "type": "object",
            "title": "The Items Schema",
            "required": [
              "id",
              "description",
              "sum",
              "deposit",
              "type"
            ],
            "properties": {
              "id": {
                "$id": "#/properties/TABLE_FEES/properties/DATA_1/items/properties/id",
                "type": "string",
                "title": "The Id Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "description": {
                "$id": "#/properties/TABLE_FEES/properties/DATA_1/items/properties/description",
                "type": "string",
                "title": "The Description Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "sum": {
                "$id": "#/properties/TABLE_FEES/properties/DATA_1/items/properties/sum",
                "type": "string",
                "title": "The Sum Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "deposit": {
                "$id": "#/properties/TABLE_FEES/properties/DATA_1/items/properties/deposit",
                "type": "string",
                "title": "The Deposit Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "type": {
                "$id": "#/properties/TABLE_FEES/properties/DATA_1/items/properties/type",
                "type": "string",
                "title": "The Type Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              }
            }
          }
        }
      }
    },
    "TABLE_PAYMENTS": {
      "$id": "#/properties/TABLE_PAYMENTS",
      "type": "object",
      "title": "The Table_payments Schema",
      "required": [
        "CAPTION",
        "ID",
        "TITLE",
        "DATA_1"
      ],
      "properties": {
        "CAPTION": {
          "$id": "#/properties/TABLE_PAYMENTS/properties/CAPTION",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "ID": {
          "$id": "#/properties/TABLE_PAYMENTS/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            "PAYMENTS"
          ],
          "pattern": "^(.*)$"
        },
        "TITLE": {
          "$id": "#/properties/TABLE_PAYMENTS/properties/TITLE",
          "type": "array",
          "title": "The Title Schema",
          "items": {
            "$id": "#/properties/TABLE_PAYMENTS/properties/TITLE/items",
            "type": "string",
            "title": "The Items Schema",
            "default": "",
            "examples": [
              "Date",
              "Description",
              "Sum",
              "Deposit"
            ],
            "pattern": "^(.*)$"
          }
        },
        "DATA_1": {
          "$id": "#/properties/TABLE_PAYMENTS/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema"
        }
      }
    }
  }
)
  },
  {
    name       => 'PAYSYS_LIQPAY',
    params     => {
      get_index      => 'paysys_payment',
      OPERATION_ID   => '62622262',
      IDENTIFIER     => '',
      SUM            => '100.00',
      DESCRIBE       => 'Пополнить',
      PAYMENT_SYSTEM => '62',
      pre            => 'Дальше',
      json           => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "_INFO"
  ],
  "properties": {
    "_INFO": {
      "$id": "#/properties/_INFO",
      "type": "object",
      "title": "The _info Schema",
      "required": [
        "LINK",
        "BODY",
        "SIGN",
        "TOTAL_SUM"
      ],
      "properties": {
        "LINK": {
          "$id": "#/properties/_INFO/properties/LINK",
          "type": "string",
          "title": "The Link Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "BODY": {
          "$id": "#/properties/_INFO/properties/BODY",
          "type": "string",
          "title": "The Body Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "SIGN": {
          "$id": "#/properties/_INFO/properties/SIGN",
          "type": "string",
          "title": "The Sign Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "TOTAL_SUM": {
          "$id": "#/properties/_INFO/properties/TOTAL_SUM",
          "type": "string",
          "title": "The Total_sum Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        }
      }
    }
  }
})
  },
  {
    name       => 'CREDIT',
    params     => {
      get_index     => 'form_info',
      json          => 1,
      change_credit => '150.00',
      set           => 'Установить'
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "CREDIT_DAYS",
    "CREDIT_SUM",
    "__ACCEPT_RULES"
  ],
  "properties": {
    "CREDIT_DAYS": {
      "$id": "#/properties/CREDIT_DAYS",
      "type": "string",
      "title": "The Credit_days Schema",
      "default": "",
      "examples": [
        ""
      ],
      "pattern": "^(.*)$"
    },
    "CREDIT_SUM": {
      "$id": "#/properties/CREDIT_SUM",
      "type": "string",
      "title": "The Credit_sum Schema",
      "default": "",
      "examples": [
        ""
      ],
      "pattern": "^(.*)$"
    },
    "__ACCEPT_RULES": {
      "$id": "#/properties/__ACCEPT_RULES",
      "type": "object",
      "title": "The __accept_rules Schema",
      "required": [
        "_INFO"
      ],
      "properties": {
        "_INFO": {
          "$id": "#/properties/__ACCEPT_RULES/properties/_INFO",
          "type": "object",
          "title": "The _info Schema",
          "required": [
            "FIO",
            "CHECKBOX",
            "HIDDEN"
          ],
          "properties": {
            "FIO": {
              "$id": "#/properties/__ACCEPT_RULES/properties/_INFO/properties/FIO",
              "type": "string",
              "title": "The Fio Schema",
              "default": "",
              "examples": [
                ""
              ],
              "pattern": "^(.*)$"
            },
            "CHECKBOX": {
              "$id": "#/properties/__ACCEPT_RULES/properties/_INFO/properties/CHECKBOX",
              "type": "string",
              "title": "The Checkbox Schema",
              "default": "",
              "examples": [
                ""
              ],
              "pattern": "^(.*)$"
            },
            "HIDDEN": {
              "$id": "#/properties/__ACCEPT_RULES/properties/_INFO/properties/HIDDEN",
              "type": "string",
              "title": "The Hidden Schema",
              "default": "",
              "examples": [
                "style='display:none;'"
              ],
              "pattern": "^(.*)$"
            }
          }
        }
      }
    }
  }
})
  },
  {
    name       => 'SERVICE',
    params     => {
      get_index      => 'abon_client',
      EXPORT_CONTENT => 'TABLE_USER_ABON',
      json           => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "TABLE_USER_ABON"
  ],
  "properties": {
    "TABLE_USER_ABON": {
      "$id": "#/properties/TABLE_USER_ABON",
      "type": "object",
      "title": "The Table_user_abon Schema",
      "required": [
        "CAPTION",
        "ID",
        "TITLE",
        "DATA_1"
      ],
      "properties": {
        "CAPTION": {
          "$id": "#/properties/TABLE_USER_ABON/properties/CAPTION",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            "Дополнительные услуги"
          ],
          "pattern": "^(.*)$"
        },
        "ID": {
          "$id": "#/properties/TABLE_USER_ABON/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            "USER_ABON"
          ],
          "pattern": "^(.*)$"
        },
        "TITLE": {
          "$id": "#/properties/TABLE_USER_ABON/properties/TITLE",
          "type": "array",
          "title": "The Title Schema",
          "items": {
            "$id": "#/properties/TABLE_USER_ABON/properties/TITLE/items",
            "type": "string",
            "title": "The Items Schema",
            "default": "",
            "examples": [
              "servise",
              "description",
              "sum",
              "period",
              "begining",
              "ending",
              "-"
            ],
            "pattern": "^(.*)$"
          }
        },
        "DATA_1": {
          "$id": "#/properties/TABLE_USER_ABON/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema",
          "items": {
            "$id": "#/properties/TABLE_USER_ABON/properties/DATA_1/items",
            "type": "string",
            "title": "The Items Schema",
            "default": "",
            "examples": [
              "name",
              "desc",
              "sum",
              "period",
              "begin",
              "end",
              "-"
            ],
            "pattern": "^(.*)$"
          }
        }
      }
    }
  }
})
  },
  # https://demo.billing.axiostv.ru:9443/index.cgi?get_index=internet_user_info&del=1&ID=&COMMENTS=test
  {
    name       => 'ACTIVE_SERVICE',
    params     => {
      get_index => 'internet_user_info',
      del       => 1,
      ID        => '',
      COMMENTS  => 'activation',
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "MESSAGE"
  ],
  "properties": {
    "MESSAGE": {
      "$id": "#/properties/MESSAGE",
      "type": "object",
      "title": "The Message Schema",
      "required": [
        "type",
        "message_type",
        "caption",
        ""
      ],
      "properties": {
        "type": {
          "$id": "#/properties/MESSAGE/properties/type",
          "type": "string",
          "title": "The Type Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "message_type": {
          "$id": "#/properties/MESSAGE/properties/message_type",
          "type": "string",
          "title": "The Message_type Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "caption": {
          "$id": "#/properties/MESSAGE/properties/caption",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "messaga": {
          "$id": "#/properties/MESSAGE/properties/messaga",
          "type": "string",
          "title": "The Messaga Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        }
      }
    }
  }
})
  },
  # https://demo.billing.axiostv.ru:9443/index.cgi?&get_index=internet_user_info&user=test&passwd=123456&activate=1
  {
    name       => 'ACTIVE_TARIFF',
    params     => {
      get_index => 'internet_user_info',
      activate  => 1,
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "MESSAGE",
    "internet_user_info"
  ],
  "properties": {
    "MESSAGE": {
      "$id": "#/properties/MESSAGE",
      "type": "object",
      "title": "The Message Schema",
      "required": [
        "type",
        "message_type",
        "caption",
        "messaga"
      ],
      "properties": {
        "type": {
          "$id": "#/properties/MESSAGE/properties/type",
          "type": "string",
          "title": "The Type Schema",
          "default": "",
          "examples": [
            "MESSAGE"
          ],
          "pattern": "^(.*)$"
        },
        "message_type": {
          "$id": "#/properties/MESSAGE/properties/message_type",
          "type": "string",
          "title": "The Message_type Schema",
          "default": "",
          "examples": [
            "info"
          ],
          "pattern": "^(.*)$"
        },
        "caption": {
          "$id": "#/properties/MESSAGE/properties/caption",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            "Информация"
          ],
          "pattern": "^(.*)$"
        },
        "messaga": {
          "$id": "#/properties/MESSAGE/properties/messaga",
          "type": "string",
          "title": "The Messaga Schema",
          "default": "",
          "examples": [
            "Активация тарифного плана"
          ],
          "pattern": "^(.*)$"
        }
      }
    },
    "internet_user_info": {
      "$id": "#/properties/internet_user_info",
      "type": "object",
      "title": "The Internet_user_info Schema",
      "required": [
        "STATUS_VALUE"
      ],
      "properties": {
        "STATUS_VALUE": {
          "$id": "#/properties/internet_user_info/properties/STATUS_VALUE",
          "type": "string",
          "title": "The Status_value Schema",
          "default": "",
          "examples": [
            "Активно"
          ],
          "pattern": "^(.*)$"
        }
      }
    }
  }
})
  },
  # https://demo.billing.axiostv.ru:9443/index.cgi?user=test&passwd=123456&ID=8254&UID=&m=&get_index=internet_user_chg_tp&TP_ID=168&ACCEPT_RULES=Приостановление&set=Установить
  {
    name       => 'CHANGE_TARIFF',
    params     => {
      get_index    => 'internet_user_chg_tp',
      ACCEPT_RULES => 'Приостановление',
      set          => 'Установить',
      TP_ID        => '',
      m            => '',
      UID          => '',
      ID           => '',
      json         => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "_INFO"
  ],
  "properties": {
    "_INFO": {
      "$id": "#/properties/_INFO",
      "type": "object",
      "title": "The _info Schema",
      "required": [
        "ID",
        "TP_NAME",
        "__TARIF_PLAN_TABLE",
        "LNG_ACTION",
        "CHG_TP_RULES",
        "ACTION"
      ],
      "properties": {
        "ID": {
          "$id": "#/properties/_INFO/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "TP_NAME": {
          "$id": "#/properties/_INFO/properties/TP_NAME",
          "type": "string",
          "title": "The Tp_name Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "__TARIF_PLAN_TABLE": {
          "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE",
          "type": "object",
          "title": "The __tarif_plan_table Schema",
          "required": [
            "TABLE_"
          ],
          "properties": {
            "TABLE_": {
              "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_",
              "type": "object",
              "title": "The Table_ Schema",
              "required": [
                "CAPTION",
                "ID",
                "DATA_1"
              ],
              "properties": {
                "CAPTION": {
                  "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/CAPTION",
                  "type": "string",
                  "title": "The Caption Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                },
                "ID": {
                  "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/ID",
                  "type": "string",
                  "title": "The Id Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                },
                "DATA_1": {
                  "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/DATA_1",
                  "type": "array",
                  "title": "The Data_1 Schema",
                  "items": {
                    "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/DATA_1/items",
                    "type": "string",
                    "title": "The Items Schema",
                    "default": "",
                    "examples": [
                      "id",
                      "name",
                      "id_radio"
                    ],
                    "pattern": "^(.*)$"
                  }
                }
              }
            }
          }
        },
        "LNG_ACTION": {
          "$id": "#/properties/_INFO/properties/LNG_ACTION",
          "type": "string",
          "title": "The Lng_action Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "CHG_TP_RULES": {
          "$id": "#/properties/_INFO/properties/CHG_TP_RULES",
          "type": "string",
          "title": "The Chg_tp_rules Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "ACTION": {
          "$id": "#/properties/_INFO/properties/ACTION",
          "type": "string",
          "title": "The Action Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        }
      }
    }
  }
})
  },
  # https://demo.billing.axiostv.ru:9443/index.cgi?index=44&user=test&passwd=123456&UID=&ID=8254&FROM_DATE=2019-09-01&TO_DATE=2100-01-01&ACCEPT_RULES=1&add=Приостановление
  {
    name       => 'SUSPENSION_OF_SERVICE',
    params     => {
      get_index    => 'internet_user_info',
      UID          => '',
      ID           => '',
      FROM_DATE    => '2019-09-01',
      TO_DATE      => '2100-01-01',
      ACCEPT_RULES => 1,
      add          => 'Приостановление',
      json         => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "MESSAGE"
  ],
  "properties": {
    "MESSAGE": {
      "$id": "#/properties/MESSAGE",
      "type": "object",
      "title": "The Message Schema",
      "required": [
        "type",
        "message_type",
        "caption",
        "messaga"
      ],
      "properties": {
        "type": {
          "$id": "#/properties/MESSAGE/properties/type",
          "type": "string",
          "title": "The Type Schema",
          "default": "",
          "examples": [
            "MESSAGE"
          ],
          "pattern": "^(.*)$"
        },
        "message_type": {
          "$id": "#/properties/MESSAGE/properties/message_type",
          "type": "string",
          "title": "The Message_type Schema",
          "default": "",
          "examples": [
            "info"
          ],
          "pattern": "^(.*)$"
        },
        "caption": {
          "$id": "#/properties/MESSAGE/properties/caption",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "messaga": {
          "$id": "#/properties/MESSAGE/properties/messaga",
          "type": "string",
          "title": "The Messaga Schema",
          "default": "",
          "examples": [
            "Удалить"
          ],
          "pattern": "^(.*)$"
        }
      }
    }
  }
})
  },
  # https://demo.billing.axiostv.ru:9443/index.cgi?get_index=internet_user_chg_tp&ID=&user=test&passwd=123456
  {
    name       => 'CHG_TARIFF',
    params     => {
      get_index => 'internet_user_chg_tp',
      ID        => '',
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "_INFO"
  ],
  "properties": {
    "_INFO": {
      "id": "#/properties/_INFO",
      "type": "object",
      "title": "The _info Schema",
      "required": [
        "ID",
        "TP_NAME",
        "__TARIF_PLAN_TABLE"
      ],
      "properties": {
        "ID": {
          "id": "#/properties/_INFO/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "TP_NAME": {
          "id": "#/properties/_INFO/properties/TP_NAME",
          "type": "string",
          "title": "The Tp_name Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "__TARIF_PLAN_TABLE": {
          "id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE",
          "type": "object",
          "title": "The __tarif_plan_table Schema",
          "required": [
            "TABLE_"
          ],
          "properties": {
            "TABLE_": {
              "id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_",
              "type": "object",
              "title": "The Table_ Schema",
              "required": [
                "CAPTION",
                "ID",
                "DATA_1"
              ],
              "properties": {
                "CAPTION": {
                  "id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/CAPTION",
                  "type": "string",
                  "title": "The Caption Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                },
                "ID": {
                  "id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/ID",
                  "type": "string",
                  "title": "The Id Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                },
                "DATA_1": {
                  "id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/DATA_1",
                  "type": "array",
                  "title": "The Data_1 Schema",
                  "items": {
                    "id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/DATA_1/items",
                    "type": "object",
                    "title": "The Items Schema",
                    "required": [
                      "id",
                      "name",
                      "btn_cheak"
                    ],
                    "properties": {
                      "id": {
                        "id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/DATA_1/items/properties/id",
                        "type": "string",
                        "title": "The Id Schema",
                        "default": "",
                        "examples": [
                          ""
                        ],
                        "pattern": "^(.*)$"
                      },
                      "name": {
                        "id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/DATA_1/items/properties/name",
                        "type": "string",
                        "title": "The Name Schema",
                        "default": "",
                        "examples": [
                          ""
                        ],
                        "pattern": "^(.*)$"
                      },
                      "btn_cheak": {
                        "id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_/properties/DATA_1/items/properties/btn_cheak",
                        "type": "string",
                        "title": "The Btn_cheak Schema",
                        "default": "",
                        "examples": [
                          ""
                        ],
                        "pattern": "^(.*)$"
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
})
  },
  # https://demo.billing.axiostv.ru:9443/index.cgi?get_index=paysys_user_log&user=test&passwd=123456&json=1
  {
    name       => 'PAYSYS_LOG',
    params     => {
      get_index => 'paysys_user_log',
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "TABLE_PAYSYS",
    "TABLE_"
  ],
  "properties": {
    "TABLE_PAYSYS": {
      "id": "#/properties/TABLE_PAYSYS",
      "type": "object",
      "title": "The Table_paysys Schema",
      "required": [
        "CAPTION",
        "ID",
        "TITLE",
        "DATA_1"
      ],
      "properties": {
        "CAPTION": {
          "id": "#/properties/TABLE_PAYSYS/properties/CAPTION",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            "Paysys"
          ],
          "pattern": "^(.*)$"
        },
        "ID": {
          "id": "#/properties/TABLE_PAYSYS/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            "PAYSYS"
          ],
          "pattern": "^(.*)$"
        },
        "TITLE": {
          "id": "#/properties/TABLE_PAYSYS/properties/TITLE",
          "type": "array",
          "title": "The Title Schema",
          "items": {
            "id": "#/properties/TABLE_PAYSYS/properties/TITLE/items",
            "type": "string",
            "title": "The Items Schema",
            "default": "",
            "examples": [
              "ID",
              "Date",
              "Sum",
              "Paysys system",
              "Transaction",
              "Status",
              "-"
            ],
            "pattern": "^(.*)$"
          }
        },
        "DATA_1": {
          "id": "#/properties/TABLE_PAYSYS/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema",
          "items": {
            "id": "#/properties/TABLE_PAYSYS/properties/DATA_1/items",
            "type": "object",
            "title": "The Items Schema",
            "required": [
              "id",
              "date",
              "sum",
              "paysys_system",
              "transaction",
              "status",
              "btn_information"
            ],
            "properties": {
              "id": {
                "id": "#/properties/TABLE_PAYSYS/properties/DATA_1/items/properties/id",
                "type": "string",
                "title": "The Id Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "date": {
                "id": "#/properties/TABLE_PAYSYS/properties/DATA_1/items/properties/date",
                "type": "string",
                "title": "The Date Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "sum": {
                "id": "#/properties/TABLE_PAYSYS/properties/DATA_1/items/properties/sum",
                "type": "string",
                "title": "The Sum Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "paysys_system": {
                "id": "#/properties/TABLE_PAYSYS/properties/DATA_1/items/properties/paysys_system",
                "type": "string",
                "title": "The Paysys_system Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "transaction": {
                "id": "#/properties/TABLE_PAYSYS/properties/DATA_1/items/properties/transaction",
                "type": "string",
                "title": "The Transaction Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "status": {
                "id": "#/properties/TABLE_PAYSYS/properties/DATA_1/items/properties/status",
                "type": "string",
                "title": "The Status Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "btn_information": {
                "id": "#/properties/TABLE_PAYSYS/properties/DATA_1/items/properties/btn_information",
                "type": "string",
                "title": "The Btn_information Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              }
            }
          }
        }
      }
    },
    "TABLE_": {
      "id": "#/properties/TABLE_",
      "type": "object",
      "title": "The Table_ Schema",
      "required": [
        "ID",
        "DATA_1"
      ],
      "properties": {
        "ID": {
          "id": "#/properties/TABLE_/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "DATA_1": {
          "id": "#/properties/TABLE_/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema"
        }
      }
    }
  }
})
  },
  # https://demo.billing.axiostv.ru:9443/index.cgi?get_index=paysys_user_log&info=506&json=1&user=test&passwd=123456
  {
    name       => 'PAYSYS_LOG_EXTRA',
    params     => {
      get_index => 'paysys_user_log',
      info      => 506,
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "TABLE_"
  ],
  "properties": {
    "TABLE_": {
      "id": "#/properties/TABLE_",
      "type": "object",
      "title": "The Table_ Schema",
      "required": [
        "ID",
        "DATA_1"
      ],
      "properties": {
        "ID": {
          "id": "#/properties/TABLE_/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "DATA_1": {
          "id": "#/properties/TABLE_/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema",
          "items": {
            "id": "#/properties/TABLE_/properties/DATA_1/items",
            "type": "object",
            "title": "The Items Schema",
            "required": [
              "id",
              "login",
              "date",
              "sum_pay",
              "paysys_system",
              "transaction",
              "user_id",
              "extra_information",
              "information"
            ],
            "properties": {
              "id": {
                "id": "#/properties/TABLE_/properties/DATA_1/items/properties/id",
                "type": "string",
                "title": "The Id Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "login": {
                "id": "#/properties/TABLE_/properties/DATA_1/items/properties/login",
                "type": "string",
                "title": "The Login Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "date": {
                "id": "#/properties/TABLE_/properties/DATA_1/items/properties/date",
                "type": "string",
                "title": "The Date Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "sum_pay": {
                "id": "#/properties/TABLE_/properties/DATA_1/items/properties/sum_pay",
                "type": "string",
                "title": "The Sum_pay Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "paysys_system": {
                "id": "#/properties/TABLE_/properties/DATA_1/items/properties/paysys_system",
                "type": "string",
                "title": "The Paysys_system Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "transaction": {
                "id": "#/properties/TABLE_/properties/DATA_1/items/properties/transaction",
                "type": "string",
                "title": "The Transaction Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "user_id": {
                "id": "#/properties/TABLE_/properties/DATA_1/items/properties/user_id",
                "type": "string",
                "title": "The User_id Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "extra_information": {
                "id": "#/properties/TABLE_/properties/DATA_1/items/properties/extra_information",
                "type": "string",
                "title": "The Extra_information Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "information": {
                "id": "#/properties/TABLE_/properties/DATA_1/items/properties/information",
                "type": "string",
                "title": "The Information Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              }
            }
          }
        }
      }
    }
  }
})
  },
  {
    name       => 'INTERNET_USER_CHG_DEL_TP',
    params     => {
      get_index => 'internet_user_chg_tp',
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    schema     => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "_INFO"
  ],
  "properties": {
    "_INFO": {
      "$id": "#/properties/_INFO",
      "type": "object",
      "title": "The _info Schema",
      "required": [
        "ID",
        "TP_NAME",
        "__TARIF_PLAN_TABLE",
        "LNG_ACTION",
        "CHG_TP_RULES"
      ],
      "properties": {
        "ID": {
          "$id": "#/properties/_INFO/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "TP_NAME": {
          "$id": "#/properties/_INFO/properties/TP_NAME",
          "type": "string",
          "title": "The Tp_name Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "__TARIF_PLAN_TABLE": {
          "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE",
          "type": "object",
          "title": "The __tarif_plan_table Schema",
          "required": [
            "TABLE_INTERNET_TP_SHEDULE",
            "SHEDULE_ID"
          ],
          "properties": {
            "TABLE_INTERNET_TP_SHEDULE": {
              "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_INTERNET_TP_SHEDULE",
              "type": "object",
              "title": "The Table_internet_tp_shedule Schema",
              "required": [
                "CAPTION",
                "ID",
                "DATA_1"
              ],
              "properties": {
                "CAPTION": {
                  "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_INTERNET_TP_SHEDULE/properties/CAPTION",
                  "type": "string",
                  "title": "The Caption Schema",
                  "default": "",
                  "examples": [
                    ""
                  ],
                  "pattern": "^(.*)$"
                },
                "ID": {
                  "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_INTERNET_TP_SHEDULE/properties/ID",
                  "type": "string",
                  "title": "The Id Schema",
                  "default": "",
                  "examples": [
                    "INTERNET_TP_SHEDULE"
                  ],
                  "pattern": "^(.*)$"
                },
                "DATA_1": {
                  "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_INTERNET_TP_SHEDULE/properties/DATA_1",
                  "type": "array",
                  "title": "The Data_1 Schema",
                  "items": {
                    "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_INTERNET_TP_SHEDULE/properties/DATA_1/items",
                    "type": "object",
                    "title": "The Items Schema",
                    "required": [
                      "name_tp",
                      "date",
                      "create_data",
                      "ID"
                    ],
                    "properties": {
                      "name_tp": {
                        "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_INTERNET_TP_SHEDULE/properties/DATA_1/items/properties/name_tp",
                        "type": "string",
                        "title": "The Name_tp Schema",
                        "default": "",
                        "examples": [
                          ""
                        ],
                        "pattern": "^(.*)$"
                      },
                      "date": {
                        "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_INTERNET_TP_SHEDULE/properties/DATA_1/items/properties/date",
                        "type": "string",
                        "title": "The Date Schema",
                        "default": "",
                        "examples": [
                          ""
                        ],
                        "pattern": "^(.*)$"
                      },
                      "create_data": {
                        "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_INTERNET_TP_SHEDULE/properties/DATA_1/items/properties/create_data",
                        "type": "string",
                        "title": "The Create_data Schema",
                        "default": "",
                        "examples": [
                          ""
                        ],
                        "pattern": "^(.*)$"
                      },
                      "ID": {
                        "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/TABLE_INTERNET_TP_SHEDULE/properties/DATA_1/items/properties/ID",
                        "type": "string",
                        "title": "The Id Schema",
                        "default": "",
                        "examples": [
                          ""
                        ],
                        "pattern": "^(.*)$"
                      }
                    }
                  }
                }
              }
            },
            "SHEDULE_ID": {
              "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/SHEDULE_ID",
              "type": "object",
              "title": "The Shedule_id Schema",
              "required": [
                "value"
              ],
              "properties": {
                "value": {
                  "$id": "#/properties/_INFO/properties/__TARIF_PLAN_TABLE/properties/SHEDULE_ID/properties/value",
                  "type": "string",
                  "title": "The Value Schema",
                  "default": "",
                  "examples": [
                    "420"
                  ],
                  "pattern": "^(.*)$"
                }
              }
            }
          }
        },
        "LNG_ACTION": {
          "$id": "#/properties/_INFO/properties/LNG_ACTION",
          "type": "string",
          "title": "The Lng_action Schema",
          "default": "",
          "examples": [
            ""
          ],
          "pattern": "^(.*)$"
        },
        "CHG_TP_RULES": {
          "$id": "#/properties/_INFO/properties/CHG_TP_RULES",
          "type": "object",
          "title": "The Chg_tp_rules Schema",
          "required": [
            "ACTION"
          ],
          "properties": {
            "ACTION": {
              "$id": "#/properties/_INFO/properties/CHG_TP_RULES/properties/ACTION",
              "type": "string",
              "title": "The Action Schema",
              "default": "",
              "examples": [
                "del"
              ],
              "pattern": "^(.*)$"
            }
          }
        }
      }
    }
  }
})
  },
  {
    name       => 'FINANCE_FORM',
    params     => {
      get_index => 'form_finance',
      json      => 1,
    },
    result     => '',
    valid_json => 1,
    scheme => q({
  "definitions": {},
  "type": "object",
  "title": "The Root Schema",
  "required": [
    "TABLE_FEES",
    "TABLE_PAYMENTS"
  ],
  "properties": {
    "TABLE_FEES": {
      "$id": "#/properties/TABLE_FEES",
      "type": "object",
      "title": "The Table_fees Schema",
      "required": [
        "CAPTION",
        "ID",
        "TITLE",
        "DATA_1"
      ],
      "properties": {
        "CAPTION": {
          "$id": "#/properties/TABLE_FEES/properties/CAPTION",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            "FEES"
          ],
          "pattern": "^(.*)$"
        },
        "ID": {
          "$id": "#/properties/TABLE_FEES/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            "FEES"
          ],
          "pattern": "^(.*)$"
        },
        "TITLE": {
          "$id": "#/properties/TABLE_FEES/properties/TITLE",
          "type": "array",
          "title": "The Title Schema",
          "items": {
            "$id": "#/properties/TABLE_FEES/properties/TITLE/items",
            "type": "string",
            "title": "The Items Schema",
            "default": "",
            "examples": [
              "date",
              "description",
              "sum",
              "deposit",
              "type"
            ],
            "pattern": "^(.*)$"
          }
        },
        "DATA_1": {
          "$id": "#/properties/TABLE_FEES/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema",
          "items": {
            "$id": "#/properties/TABLE_FEES/properties/DATA_1/items",
            "type": "object",
            "title": "The Items Schema",
            "required": [
              "date",
              "desc",
              "sum",
              "deposit",
              "type"
            ],
            "properties": {
              "date": {
                "$id": "#/properties/TABLE_FEES/properties/DATA_1/items/properties/date",
                "type": "string",
                "title": "The Date Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "desc": {
                "$id": "#/properties/TABLE_FEES/properties/DATA_1/items/properties/desc",
                "type": "string",
                "title": "The Desc Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "sum": {
                "$id": "#/properties/TABLE_FEES/properties/DATA_1/items/properties/sum",
                "type": "string",
                "title": "The Sum Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "deposit": {
                "$id": "#/properties/TABLE_FEES/properties/DATA_1/items/properties/deposit",
                "type": "string",
                "title": "The Deposit Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "type": {
                "$id": "#/properties/TABLE_FEES/properties/DATA_1/items/properties/type",
                "type": "string",
                "title": "The Type Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              }
            }
          }
        }
      }
    },
    "TABLE_PAYMENTS": {
      "$id": "#/properties/TABLE_PAYMENTS",
      "type": "object",
      "title": "The Table_payments Schema",
      "required": [
        "CAPTION",
        "ID",
        "TITLE",
        "DATA_1"
      ],
      "properties": {
        "CAPTION": {
          "$id": "#/properties/TABLE_PAYMENTS/properties/CAPTION",
          "type": "string",
          "title": "The Caption Schema",
          "default": "",
          "examples": [
            "PAYMENTS"
          ],
          "pattern": "^(.*)$"
        },
        "ID": {
          "$id": "#/properties/TABLE_PAYMENTS/properties/ID",
          "type": "string",
          "title": "The Id Schema",
          "default": "",
          "examples": [
            "PAYMENTS"
          ],
          "pattern": "^(.*)$"
        },
        "TITLE": {
          "$id": "#/properties/TABLE_PAYMENTS/properties/TITLE",
          "type": "array",
          "title": "The Title Schema",
          "items": {
            "$id": "#/properties/TABLE_PAYMENTS/properties/TITLE/items",
            "type": "string",
            "title": "The Items Schema",
            "default": "",
            "examples": [
              "date",
              "description",
              "sum",
              "deposit"
            ],
            "pattern": "^(.*)$"
          }
        },
        "DATA_1": {
          "$id": "#/properties/TABLE_PAYMENTS/properties/DATA_1",
          "type": "array",
          "title": "The Data_1 Schema",
          "items": {
            "$id": "#/properties/TABLE_PAYMENTS/properties/DATA_1/items",
            "type": "object",
            "title": "The Items Schema",
            "required": [
              "date",
              "desc",
              "sum",
              "deposit",
              "type"
            ],
            "properties": {
              "date": {
                "$id": "#/properties/TABLE_PAYMENTS/properties/DATA_1/items/properties/date",
                "type": "string",
                "title": "The Date Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "desc": {
                "$id": "#/properties/TABLE_PAYMENTS/properties/DATA_1/items/properties/desc",
                "type": "string",
                "title": "The Desc Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "sum": {
                "$id": "#/properties/TABLE_PAYMENTS/properties/DATA_1/items/properties/sum",
                "type": "string",
                "title": "The Sum Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "deposit": {
                "$id": "#/properties/TABLE_PAYMENTS/properties/DATA_1/items/properties/deposit",
                "type": "string",
                "title": "The Deposit Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              },
              "type": {
                "$id": "#/properties/TABLE_PAYMENTS/properties/DATA_1/items/properties/type",
                "type": "string",
                "title": "The Type Schema",
                "default": "",
                "examples": [
                  ""
                ],
                "pattern": "^(.*)$"
              }
            }
          }
        }
      }
    }
  }
})
  }
);

# Функція локального теста
#
# json_test(\@test_list, {
#   TEST_NAME => 'Api JSON user interface test',
#   UI        => 1
# });

# Функція відаленого теста
#
json_test_remove(\@test_list,
  {
    TEST_NAME => 'Api Test',
    UI        => 1 }
);

1;
