#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use FindBin '$Bin';

BEGIN {
  my $libpath = "$Bin/../../";
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "AXbills/$sql_type/",
    $libpath . 'AXbills/modules/',
    $libpath . '/lib/',
    $libpath . '/AXbills/',
    $libpath
  );
}

use AXbills::Defs;
use Admins;
use Conf;
use Paysys;

our (
  %conf,
);

do '../../libexec/config.pl';

my $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET   => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug   => $conf{dbdebug},
    db_engine => 'dbcore'
  });

my $admin = Admins->new($db, \%conf);
my $Config = Conf->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);

auto_reconfigure_all_groups();

#**********************************************************s
=head2 auto_reconfigure_all_groups()

=cut
#**********************************************************
sub auto_reconfigure_all_groups {
  my $connect_system_list = $Paysys->paysys_connect_system_list({
    MODULE    => '_SHOW',
    STATUS    => 1,
    COLS_NAME => 1,
  });

  foreach my $system_obj (@{$connect_system_list}) {
    my $configure = $Paysys->merchant_for_group_list({
      PAYSYS_ID => $system_obj->{id},
      MERCH_ID  => '_SHOW',
      GID       => '_SHOW',
      LIST2HASH => 'gid,merch_id'
    });

    while (my ($gid, $merch_id) = each(%{$configure})) {
      add_settings_to_config({
        MERCHANT_ID => $merch_id,
        GID         => $gid
      });
    }
  }
}

#**********************************************************s
=head2 add_settings_to_config($attr)

  Arguments:
      MERCHANT_ID
      GID

  Returns:

=cut
#**********************************************************
sub add_settings_to_config {
  my ($attr);
  my $list = $Paysys->merchant_params_info({ MERCHANT_ID => $attr->{MERCHANT_ID} });

  foreach my $key (keys %{$list}) {
    if (defined $attr->{GID} && $attr->{GID} != 0) {
      $Config->config_add({
        PARAM     => $key . "_$attr->{GID}",
        VALUE     => $list->{$key},
        REPLACE   => 1,
        PAYSYS    => 1
      });
    }
    else {
      $Config->config_add({
        PARAM     => $key,
        VALUE     => $list->{$key},
        REPLACE   => 1,
        PAYSYS    => 1
      });
    }
  }
}

1;
