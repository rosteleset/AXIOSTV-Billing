=head1 NAME

  Task

=head1 VERSION

  VERSION: 0.01

=cut

use strict;
use warnings;

require Userside::Task;

our %task_request_list = (
  'get_list'            => {
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
              "author_id": {
                "type": "integer"
              },
              "author_employee_id": {
                "type": "integer"
              },
              "closer_employee_id": {
                "type": "integer"
              },
              "closer_operator_id": {
                "type": "integer"
              },
              "customer_id": {
                "type": "integer"
              },
              "date_do_to": {
                "type": "string"
              },
              "date_finish_to": {
                "type": "string"
              },
              "employee_id": {
                "type": "integer"
              },
              "house_id": {
                "type": "integer"
              },
              "staff_id": {
                "type": "integer"
              },
              "state_id": {
                "type": "integer"
              },
              "task_position": {
                "type": "integer"
              },
              "task_position_tadius": {
                "type": "integer"
              },
              "watcher_id": {
                "type": "integer"
              },
              "watcher_employee_id": {
                "type": "integer"
              }
            },
            "required": [

            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_catalog_type'    => {
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
              "id": {
                "type": "integer"
              },
              "name": {
                "type" : "string"
              }
            },
            "required": [

            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'show'    => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
      id        => get_msg_id(),
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^.+$": {
            "type": "object",
            "properties": {
              "id": {
                "type": "integer"
              },
              "employee_id": {
                "type": "integer"
              },
              "operator_id": {
                "type": "integer"
              }
            },
            "required": [
              "id"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
  'get_related_task_id'    => {
    params => {
      get_index => 'us_api',
      key       => '1523615231263123',
      cat       => 'module',
      json      => 1,
      id        => get_msg_id(),
    },
    schema => q(
      {
        "type": "object",
        "patternProperties": {
          "^.+$": {
            "type": "object",
            "properties": {
              "id": {
                "type": "integer"
              },
              "related_task_id": {
                "type" : "integer"
              }
            },
            "required": [
               "id"
            ]
          }
        },
        "additionalProperties": false
      }
    ),
  },
);

1;