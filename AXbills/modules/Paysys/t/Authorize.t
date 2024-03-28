#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Authorize;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id
);

my $Payment_plugin = Paysys::systems::Authorize->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

  #process() don't used
  our @requests = (
  {
    name      => 'PAY',
      request => qq{x_response_code=1&x_response_reason_code=1&x_response_reason_text=This+transaction+has+been+approved%2E&x_avs_code=Y&x_auth_code=ZNW7IJ&x_trans_id=40069134079&x_method=CC&x_card_type=MasterCard&x_account_number=XXXX0015&x_first_name=&x_last_name=&x_company=&x_address=&x_city=&x_state=&x_zip=&x_country=&x_phone=&x_fax=&x_email=&x_invoice_num=&x_description=&x_type=auth%5Fcapture&x_cust_id=1&x_ship_to_first_name=&x_ship_to_last_name=&x_ship_to_company=&x_ship_to_address=&x_ship_to_city=&x_ship_to_state=&x_ship_to_zip=&x_ship_to_country=&x_amount=23%2E00&x_tax=0%2E00&x_duty=0%2E00&x_freight=0%2E00&x_tax_exempt=FALSE&x_po_num=&x_MD5_Hash=&x_SHA2_Hash=F2AA65829A04876AD180CA15338967020B3C5EDBF6BFD9DE00ACD83AC0E41665E14B2D2608A614E903DC18708E4B4F71B65D6DA7F2795220C5A6D813C3B6D235&x_cvv2_resp_code=M&x_cavv_response=2&x_test_request=false},
      result  => qq{OK},
  },

  );

  test_runner($Payment_plugin, \@requests);

1;

