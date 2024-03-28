=head1 NAME

  billd plugin

=head2  DESCRIBE

  Get sms status from remote server

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
BEGIN {
  unshift(@INC, '/usr/axbills/AXbills/modules');
}

our (
  $debug,
  %conf,
  $Admin,
  $db,
  $OS
);

use Sms;
use Sms::Init;

sms_status();


#**********************************************************
=head2 sms_status() - Request for sms status

=cut
#**********************************************************
sub sms_status {
  do 'AXbills/Misc.pm';
  load_module('Sms');
  print "Sms status\n" if ($debug > 1);
  my $Sms   = Sms->new($db, $Admin, \%conf);

  my $Sms_service = init_sms_service($db, $Admin, \%conf);
  if ($Sms_service->{errno}) {
    return 0;
  }

  if($Sms_service->can('get_status')) {
    my $list = $Sms->list({ SMS_STATUS => 0, COLS_NAME => 1, PAGE_ROWS => 100000 });
    
    foreach my $line ( @$list ) {

      if($debug > 1) {
        print "ID: $line->{id} DATE: $line->{datetime}\n";
      }

      $Sms_service->get_status({ REF_ID => $line->{datetime}, EXT_ID => ($line->{ext_id} ? $line->{ext_id} : $line->{id}) });
      
      if($debug > 1) {
        print "  STATUS: ". (defined($Sms_service->{status}) ? $Sms_service->{status} : 0) ."\n";
      }

      if (! $Sms_service->{errno}) {
        if($Sms_service->{status} || $Sms_service->{list}->[0]{status}) {
          $Sms->change({
            ID     => $line->{id},
            STATUS => ($Sms_service->{status}) ? $Sms_service->{status} : $Sms_service->{list}->[0]{status}
          });
        }
      }
    }
  }

  return 1;
}



1;
