=head1 ERIP_QR

  New module for ERIP_QR

  Date: 02.11.2023

  VERSION - 7.77
  
=cut

use strict;
use warnings;

use AXbills::Base qw(_bp load_pmodule);
use AXbills::Misc qw();

require Paysys::Paysys_Base;

package Paysys::systems::ERIP_QR;

our %PAYSYSTEM_CONF    = (
  'PAYSYS_ERIP_QR_ID'       => '',
  'PAYSYS_ERIP_QR_NAME'       => '',
  'PAYSYS_ERIP_QR_CURRENCY'       => '');
our $PAYSYSTEM_IP      = '127.0.0.1';
our $PAYSYSTEM_VERSION = 7.77;
our $PAYSYSTEM_NAME    = 'ERIP_QR';

my ($html, $json);

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
    DEBUG => $CONF->{PAYSYS_DEBUG} || 0,
  };

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  AXbills::Base::load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  bless($self, $class);

  return $self;
}
#**********************************************************
=head2 get_settings() - return hash of settings

  Arguments:


  Returns:
    HASH
=cut
#**********************************************************
sub get_settings {
  my %SETTINGS = ();

  $SETTINGS{IP} = $PAYSYSTEM_IP;
  $SETTINGS{VERSION} = $PAYSYSTEM_VERSION;
  $SETTINGS{NAME} = $PAYSYSTEM_NAME;

  $SETTINGS{CONF} = \%PAYSYSTEM_CONF;

  return %SETTINGS;
}

#**********************************************************
=head2 user_portal()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub user_portal {
  use Digest::SHA qw(sha256_hex);

  my $self = shift;
  my ($user, $attr) = @_;

my $unique_service_number = $self->{conf}{PAYSYS_ERIP_QR_ID} || $self->{conf}{PAYSYS_ERIPT_PROVIDER_SELLER_ID};
		my $length_unique_service_number = length($unique_service_number);
			$length_unique_service_number = sprintf("%02d", $length_unique_service_number);
	my $login = $user->{LOGIN};
	my $tarif_amount = $attr->{SUM};

	my $base_url = "https://pay.raschet.by/#";
	my $version_standart = "000201";
	
	my $lenght_login = length($login);
		$lenght_login = sprintf("%02d", $lenght_login);

	my $allow_change_amount = "12" . "02" . "11";

	my $object32_ids = "0010by.raschet01" . $length_unique_service_number . $unique_service_number . "10" . $lenght_login . $login . $allow_change_amount;
	my $length_id32 = length($object32_ids);

	my $object32_full = "32" . $length_id32 . $object32_ids;
	
	my $currency_code = "53" . "03" . "933";

	my $lenght_amount = length($tarif_amount);
		$lenght_amount = sprintf("%02d", $lenght_amount);
			my $payment_amount = "54" . $lenght_amount . $tarif_amount;

	my $country_code = "58" . "02" . "BY";
	my $seller_name = $self->{conf}{PAYSYS_ERIP_QR_NAME} || $self->{conf}{PAYSYS_ERIPT_PROVIDER_SELLER_NAME};
		my $lenght_seller_name = length($seller_name);
			$lenght_seller_name = sprintf("%02d", $lenght_seller_name);
		$seller_name = "59" . $lenght_seller_name . $seller_name;
	my $country_origin = "60" . "07" . "Belarus";

	my $url_code = $version_standart . $object32_full . $currency_code . $payment_amount . $country_code . $seller_name . $country_origin;
	my $sha256_hex = sha256_hex($url_code);
		$sha256_hex =~ s/-//g;
	my $checksum = substr($sha256_hex, -4);
	my $CRC = "6304" . $checksum;

	my $QR_URL = $base_url . $url_code . $CRC;

  my %info = ();
  $info{PAYMENT_AMOUNT}		= $attr->{SUM};
  $info{PAYMENT_CURRENCY}	= $self->{conf}{PAYSYS_NAME_CURRENCY} || 'руб.';
  $info{LOGIN}				= $user->{LOGIN};
  $info{QR_URL}				= $QR_URL;

  $html->tpl_show(main::_include('paysys_erip_qr', 'Paysys'), \%info);
}

1
