#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib '../lib';

use AXbills::Base qw/mk_unique_value _bp/;

my $passwd_length = 6;

ok(generate_and_check_passwd($passwd_length, '3:0'), 'Lower case passwd params');
ok(generate_and_check_passwd($passwd_length, '3:1'), 'Upper case passwd params');
ok(generate_and_check_passwd($passwd_length, '3:2'), 'Both case passwd params');

ok(generate_and_check_passwd($passwd_length, '0:0'), 'Lower case and cypher params');
ok(generate_and_check_passwd($passwd_length, '1:0'), 'Lower case and special params');
ok(generate_and_check_passwd($passwd_length, '2:0'), 'Lower case and both nonalphabetical params');


done_testing();

#**********************************************************
=head2 generate_and_check_passwd($length, $configuration_string)

  Arguments:
    $length
    $configuration_string
    
  Returns:
    boolean

=cut
#**********************************************************
sub generate_and_check_passwd {
  my ($length, $configuration_string) = @_;
  
  my $check_rules = get_passwd_check_rules($configuration_string);
  
  my $passwd = mk_unique_value($length, { EXTRA_RULES => $configuration_string });
  print $passwd . "\n";
  
  return 0 if ( length $passwd != $length );
  
  return check_passwd($passwd, $check_rules);
}

#**********************************************************
=head2 check_passwd($passwd, $rules)

  Arguments :
    $passwd - passwd to check
    $rules  - array_ref of symbol sets for check

  Returns:
    boolean
    
=cut
#**********************************************************
sub check_passwd {
  my ($passwd, $rules) = @_;
  
  foreach my $symbols_set ( @{$rules} ) {
    my $symbols_in_rule = join('', @$symbols_set);
    if ( $passwd !~ /[$symbols_in_rule]+/){
      _bp('PASSWD fails', [ $passwd,  $symbols_in_rule ], { TO_CONSOLE => 1 });
      return 0;
    }
  }
  
  return 1;
}

#**********************************************************
=head2 get_passwd_check_rules($configuration)
  
  Arguments:
    $configuration - encoded passwd configuration string
    
   Returns:
     array_ref of array_ref for symbols to check
   
=cut
#**********************************************************
sub get_passwd_check_rules {
  my ($configuration) = @_;
  my ($chars, $case) = split(':', $configuration, 2);
  
  my %symbols = (
    0 => [ ['a' ... 'z'] ],
    1 => [ ['A' ... 'Z'] ],
    2 => [ ['a' ... 'z'], ['A' ... 'Z'] ]
  );
  
  my %nonalphabet = (
    0 => [ [0 ... 9] ],
    1 => [ [split('', '-_!&%@#:')] ],
    2 => [ [0 ... 9], [split('', '-_!&%@#:')] ],
    3 => [ ],
  );
  
  return [ @{ $symbols{$case}}, @{ $nonalphabet{$chars} }  ];
}
