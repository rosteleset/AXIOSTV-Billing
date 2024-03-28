#!/usr/bin/perl -w
=head1 Robokassa
  Module for Robokassa payment system
  Interface for Robokassa Paysystem
  Date: 14.09.2015
=cut

our %PAYSYSTEM_CONF    = ('PAYSYS_ROBOKASSA_PASSWORD_ONE' => '' ,
                          'PAYSYS_ROBOKASSA_PASSWORD_TWO' => '',
                          'PAYSYS_ROBOKASSA_MRCH_LOGIN'   => '',
                          'PAYSYS_ROBOKASSA_TEST_MODE'    => '1');
our $PAYSYSTEM_IP      = '212.24.63.49';
our $PAYSYSTEM_VERSION = 1.00;
our $PAYSYSTEM_NAME    = 'Robokassa';

my $verison = 0.01;


#**********************************************************
=head2 robokassa_check_payment($attr) - make payment

  Arguments:
    
    
  Returns:
  
=cut
#**********************************************************
sub robokassa_check_payment
{
  my ($attr) = (@_);
  load_pmodule('Digest::MD5');
  $md5 = new Digest::MD5;
  my $payment_system = 'RK';
  my $payment_system_id = 105;
  my $paysys_status = '';
  #_bp({HEADER=>1});
  print "Content-Type: text/plain\n\n";

  #my %FORM = (
  #          'OutSum'         => "5.00",
  #          'InvId'          => 42561510,
  #          'SignatureValue' => "854336C0B786976FFA4DE02FB51DF23A",
  #          'shp_Id'         => 3
  #          );
  my $signature_string = "$FORM{OutSum}:$FORM{InvId}:$conf{PAYSYS_ROBOKASSA_PASSWORD_TWO}:shp_Id=$FORM{shp_Id}";
  
  $md5->reset;
  $md5->add($signature_string);
  $compare_string = uc($md5->hexdigest());
  
  if ($compare_string eq $FORM{SignatureValue}) {
    
    $paysys_status = paysys_pay( {
      PAYMENT_SYSTEM    => $payment_system,
      PAYMENT_SYSTEM_ID => $payment_system_id,
      CHECK_FIELD       => 'UID',
      USER_ID           => $FORM{shp_Id},
      SUM               => $FORM{OutSum},
      EXT_ID            => $FORM{InvId},
      DATA              => \%FORM,
      MK_LOG            => 1,
      DEBUG             => 7
    });
    print "Content-type: text/html\n\nOK$FORM{InvId}\n";
  }
  
  print $paysys_status;
  return $paysys_status;
}

1