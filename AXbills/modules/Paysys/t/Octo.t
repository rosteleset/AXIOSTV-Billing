#!/usr/bin/perl -w

=head1 Octo

 Paysys tests for Octo

=cut

use strict;
use warnings;
use Test::More;
use Test::JSON::More;
use JSON;

our (
  %LIST_PARAMS, 
  %functions, 
  %conf, 
  $html, 
  %lang, 
  @_COLORS
);

our $PAYSYSTEM_NAME = 'Octo';
our $PAYSYSTEM_SHORT_NAME = 'OC';
our $PAYSYSTEM_ID = 145;

BEGIN {
  our $libpath = '../../../../';
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'AXbills/');
  unshift(@INC, $libpath . 'AXbills/modules/');
  unshift(@INC, $libpath . "AXbills/mysql/");
}

require "libexec/config.pl";

my $begin_time = AXbills::Base::check_time();
my $Users;

use AXbills::Init qw/$db $admin $users/;

pass("Test use other packeg");
subtest 'Use other packeg' => sub {
  use_ok('Conf');
  use_ok('AXbills::Fetcher', qw/web_request/);
  use_ok('AXbills::Base', qw/_bp load_pmodule urlencode/);

  if ( use_ok('Paysys') ) {
    use Paysys;
  }
  
  if ( use_ok('Paysys::systems::Octo') ) {
    use Paysys::systems::Octo;
  }
  
  if ( require_ok('Users') ) {
    require Users;
    $Users = Users->new($db, $admin, \%conf);
    $Users->import();
  }
};

my $shop_id = '1';
my $secret = ''; 
my $currency = '';
my $language = '';
my $test = JSON::false;
my $customer_ip = "http://merchant.site.uz/return_URL";
my $ttl = '15';
my $return_url_test = '127.0.0.1';

my $amount = int(rand(10000));
my $operation_id = int(rand(10000));
my $description = "Test paysys algorithm payment system Octo";
my $return_url = '';

subtest 'Check parameters Test' => sub {
  if ( ok($conf{PAYSYS_OC_SHOP_ID}, "Check value in config.pl PAYSYS_OC_SHOP_ID") ) {
    $shop_id = $conf{PAYSYS_OC_SHOP_ID};
  }

  if ( ok($conf{PAYSYS_OC_SECRET_KEY}, "Check value in config.pl PAYSYS_OC_SECRET_KEY") ) {
    $secret = $conf{PAYSYS_OC_SECRET_KEY};
  }

  if ( ok($conf{PAYSYS_OC_CURRENCY}, "Check value in config.pl PAYSYS_OC_CURRENCY") ) {
    $currency = $conf{PAYSYS_OC_CURRENCY};
  }

  if ( ok($conf{PAYSYS_OC_LANGUAGE}, "Check value in config.pl PAYSYS_OC_LANGUAGE") ) {
    $language = $conf{PAYSYS_OC_LANGUAGE};
  }

  if ( ok($conf{PAYSYS_OC_TEST}, "Check value in config.pl PAYSYS_OC_TEST") ) {
    $test = JSON::true;
  }

  if ( ok($conf{PAYSYS_OC_CUSTOMER_IP}, "Check value in config.pl PAYSYS_OC_CUSTOMER_IP") ) {
    $customer_ip = $conf{PAYSYS_OC_CUSTOMER_IP};
  }

  if ( ok($conf{PAYSYS_OC_TTL}, "Check value in config.pl PAYSYS_OC_TTL") ) {
    $ttl = int(rand(10000));
  }

  if ( ok($conf{PAYSYS_OC_BILLING_TEST}, "Check value in config.pl PAYSYS_OC_BILLING_TEST") ) {
    $return_url_test = $conf{PAYSYS_OC_BILLING_TEST};
  }

  done_testing();
};


subtest 'User Portal Test' => sub {
  my $user_info = $Users->pi({ UID => 1 });
  unless ( ok($user_info->{UID}, 'Get UID user') ) {
    fail("Not user exist! Failed test");
    return 0;
  }

  unless ( ok($user_info->{PHONE}, 'Get phone user') ) {
    $user_info->{PHONE} = '-';
  }

  unless ( ok($user_info->{EMAIL}, 'Get email user') ) {
    $user_info->{EMAIL} = '-';
  }

  my $Octo = Paysys::systems::Octo->new($db, $admin, \%conf);
  if (isa_ok($Octo, 'Paysys::systems::Octo')) {
    my $request_result = $Octo->user_portal($user_info, {
      PAYMENT_SYSTEM => $PAYSYSTEM_NAME,
      SUM            => $amount,
      OPERATION_ID   => $operation_id,
      UID            => $user_info->{UID},
      IP             => $return_url_test,
      REMOTE_ADDR    => $customer_ip,
      index          => 'paysys_payment',
      DESCRIBE       => 'Test Octo payment module',
      TEST_OCTO      => 1
    });
    
    if ($request_result->{error}) {
      fail($request_result->{errorMessage});
    }
    elsif ($request_result =~ /ERROR_Paysys/) {
      fail("ERROR Paysys ID: '$operation_id'");
    }
    
    my $hash_key = '453fg54j3f6g';
    my $UUID = '1145df74-bb95-47cf-a616-8d6dcee2e222';
    my $signatura = '74E55B89BEF09B02649F728A70ADD79F9755B61A';
    my $status = 'waiting_for_capture';
    my $argv = AXbills::Base::parse_arguments(\@ARGV);

    if ($argv->{-hk}) {
      $hash_key = $argv->{HASH_KEY};
    }

    my $process_status = $Octo->proccess({
      JSON_TEST   => $request_result,
      HASH_KEY    => $hash_key,
      UUID        => $UUID,
      STATUS_TEST => $status,
      SIGNATURA_TEST => $signatura,
    });

    if ($process_status && $process_status != 2) {
      pass("Test Done! Accept status responsed 'capture'");
    }
    elsif ($process_status && $process_status == 2) {
      fail("Test Failed! Wrong signatura!");
    }
    else {
      fail("Test Failed! Accept status responsed 'failed'");
    }

  }
  else {
    fail("Test Failed! Accept status responsed 'failed'");
  }
  done_testing();
};

done_testing();
