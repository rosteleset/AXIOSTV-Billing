package Paysys::Init;

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';

our $VERSION = 0.01;

our @EXPORT = qw(
  _configure_load_payment_module
);

our @EXPORT_OK = qw(
  _configure_load_payment_module
);


#**********************************************************
=head2 _configure_load_payment_module($payment_system)

  Arguments:
    $payment_system - Payment system names

  Results
    Paysys_obj

=cut
#**********************************************************
sub _configure_load_payment_module {
  my ($payment_system, $return_error) = @_;

  if (!$payment_system) {
    return 0;
  }

  #return if $paysys_name !~ /^[\w.]+$/;
  my ($paysys_name) = $payment_system =~ /(.+)\.pm/;

  if (!$paysys_name) {
    if ($return_error) {
      return {
        errno  => 601,
        errstr => 'Can\'t load module'
      }
    }
    else {
      print "Content-Type: text/html\n\n";
      print "Error loading\n";
    }
  }

  my $require_module = "Paysys::systems::$paysys_name";

  eval {require "Paysys/systems/$payment_system";};

  if (!$@) {
    $require_module->import($payment_system);
  }
  else {
    if ($return_error) {
      return {
        errno  => 600,
        errstr => 'Can\'t load module'
      }
    }
    else {
      print "Content-Type: text/html\n\n";
      print "Error loading\n";
      print $@;
    }
  }

  return $require_module;
}

1;
