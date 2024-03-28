package Dlink_auth;
#Switch Auth module

use strict;
use parent 'dbcore';

our $VERSION = 7.00;

my $db;
my $CONF;
my $debug=0;


#****************************************
# Init
#****************************************
sub new {
  my $class = shift;
  ($db, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  return $self;
}

#**********************************************************
=head2  auth($RAD, $NAS)

 Arguments:
   $RAD - Request Rad pairs
   $NAS - Nas information object

 Return $auth_code, Rad_pairs_hash_ref
   $auth_code
       0 - Allow
       1 - Deny

=cut
#**********************************************************

sub auth {
  my $self = shift;
  my ($RAD, $NAS, $attr)=@_;

  #Response Rad pairs
  my %RAD_PAIRS = (
    'dlink-Privelege-Level' => '5',
  );

  return 0, \%RAD_PAIRS;
}

1