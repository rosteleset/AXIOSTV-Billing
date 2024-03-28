=head1 NAME

  InfoFieldsNew test

=cut

use strict;
use warnings;
use Test::More;

require "./JSON.t";

my @test_list = (
  {
    name       => 'INFO_FIELDS',
    params     => {
      get_index    => 'form_info_fields',
      API_KEY      => '1523615231263123',
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
  }
  );


json_test(
  \@test_list, 
  { TEST_NAME => 'info_fields_new test' });

1;