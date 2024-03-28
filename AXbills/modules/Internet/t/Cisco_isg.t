=head NAME

  Cisco ISG testing

=cut
use strict;
use warnings;
use Test::More;

use lib '../',
  '../../../lib',
  #  '../../../../',
  '../../../AXbills/mysql';


use Dv::Cisco_isg;

subtest 'ISG testing' => sub {
  require_ok('Dv::Cisco_isg');
  like( cisco_isg_cmd(), qr/1/, 'Base test');
};

done_testing;

1;