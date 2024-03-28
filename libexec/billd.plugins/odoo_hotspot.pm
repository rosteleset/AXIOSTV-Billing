=head1 NAME

 billd plugin

 DESCRIBE: Odoo hotspot user add

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Synchron::Odoo;

our (
  $argv,
  $DATE,
  $TIME,
  $debug,
  $db,
  %conf,
  $Admin,
);

odoo_user_add();

#**********************************************************
=head2 odoo_user_add($attr);

  Argumnets:
    $attr

  Results:

=cut
#**********************************************************
sub odoo_user_add {

  if($debug > 1) {
    print "odoo_user_add\n";
  }

  my Synchron::Odoo $Odoo = odoo_connect({ JSON => 1 });

  my $users_list_json  = $Odoo->create_hotspot_user({
    %$argv
  });
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
      print "DOMAIN_ID: $Admin->{DOMAIN_ID} URL: $url DB: $dbname USER: $username PASSWORD: $password\n";
    }
  }

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
