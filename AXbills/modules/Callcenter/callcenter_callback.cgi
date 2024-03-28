#!/usr/bin/perl

use strict;
use warnings;

our (
  %conf,
  $base_dir,
  $DATE,
  $TIME
);

BEGIN {
  do '../libexec/config.pl';
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . '/lib/',
    $libpath . "AXbills/$sql_type/",
    $libpath . "AXbills/modules/",
    $libpath . "AXbills/mysql/",
    $libpath . "AXbills/modules/Callcenter/",
  );
}

use Users;
use Admins;
use AXbills::SQL;
use Contacts;
use AXbills::Misc;

my $sql = AXbills::SQL->connect(
  $conf{dbtype},
  $conf{dbhost},
  $conf{dbname},
  $conf{dbuser},
  $conf{dbpasswd}, {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : 'utf-8'
  }
);

my $db  = $sql->{db};

my $Admin    = Admins->new($db, \%conf);
# my $Users    = Users->new($db, $Admin, \%conf);
# my $Contacts = Contacts->new($db, $Admin, \%conf);

callcenter_proccess(\%ENV, init_call_center());

#**********************************************************
=head2 init_call_center()

=cut
#**********************************************************
sub init_call_center {

  my $Callcenter_service;

  my @callcenter_systems = (
    { BINOTEL_KEY   => 'Binotel' },
  );

  foreach my $callcenter ( @callcenter_systems ) {
    my $config_key = ( keys %$callcenter )[0];
    if ($conf{ $config_key } ) {
      $Callcenter_service = $callcenter->{$config_key};

      eval {
        require "Callcenter/$Callcenter_service.pm";
      };

      if ($@) {
        print $@;
        return 0;
      }
      else {
        $Callcenter_service->import();
        $Callcenter_service = $Callcenter_service->new($db, $Admin, \%conf);
        last;
      }
    }
  }

  if (! $Callcenter_service) {
    $Callcenter_service->{errno} = 1;
    $Callcenter_service->{errstr} = 'CALLCENTER_PLUGIN_NOT_CONNECTION';
    print "$Callcenter_service->{errno} $Callcenter_service->{errstr}";
    #return 0;
  }

  return $Callcenter_service;
}

#**********************************************************
=head2 callcenter_proccess($callcenter)

  Arguments:
    $env
    $callcenter

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub callcenter_proccess {
  my $env = shift;
  my ($callcenter) = @_;

  if (! $callcenter->{errno}) {
    $callcenter->get_users_service($env);
  }

  return 1;
}

1;
