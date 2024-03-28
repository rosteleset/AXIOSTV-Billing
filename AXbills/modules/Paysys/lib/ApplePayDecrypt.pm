package Paysys::lib::ApplePayDecrypt;
=head NAME

  Paysys::lib::ApplePayDecrypt - decrypt ApplePay token

=cut

use strict;
use warnings FATAL => 'all';

use Digest::SHA;
use Crypt::OpenSSL::X509;
use Crypt::PK::ECC;
use Crypt::AuthEnc::GCM;
use JSON qw(decode_json);

use AXbills::Base qw(decode_base64 encode_base64);

our $VERSION = 1.0;
my $MERCHANT_OID = '1.2.840.113635.100.6.32';

#**********************************************************
=head2 decrypt($token) - decrypt apple pay token

  INPUT:
    $token: object - apple pay token received from user

  RESULT:
    $token: object - decoded token from apple pay

  EXAMPLE:
    INPUT:
      my $token = Paysys::lib::ApplePayDecrypt::decrypt($apple_pay_token);

      $apple_pay_token:
      {
        'data'      => 'QVxgIO2+ST+MjoSA2N32Zmu92GBx5Vdi/TmJq49Liz3U7eo1qeFCBOwOdjU8AKdinMkLJ4ZIGlJsw4G11S/OCxEp2L2GVvrDcsz/ofA8T97JkhwrsORZotiH7fq4IKupAW+pTHUr4rV92STgrFPwdiuLpmQCo5OlFAKzv3wTkylW9S4Se5lOLZbsyAdnvV0ct+pt2st+jBOj4v7DPMGoChpgMxhGVm2KaDqZO4mN9whOb8DgzAuSbl7NTaawr+JzmMfHIDTh7qFvjp3qsRqOKWY8n5y1OT71D9HU/xeKchQzzxVj1kOPZJtII3AxwPhWEBCbiFygYeBYz48T3eyvm58i1yWkm0L3s0xkeHdZg8tYwBrYw5dv5Z+51QsnUHKCOkhAn+Sd0O0zd243',
        'signature' => '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',
        'header'    => {
          'publicKeyHash'      => 'gYwPh/uW801bzKcl+0tX3R4FaGByaF01+4o+MiP5Y5A=',
          'ephemeralPublicKey' => 'MFkwEwYHKoZIzj0CAQYI43ZIzj0DAQcDQgAER0nozQaBz6ys8NWe1e5432Se6DuzvyG/jvTAZhgeG1fTV6vHI8ja85h1sVFqG5LbzP12ePZauAr8lvDgFuFkMQ==',
          'transactionId'      => '26bc3754b47e577144a3036f46248872e9b1c406768c3752d6c8f5ba95699fd3'
        },
        'version'   => 'EC_v1'
      };

    RESULT:
      $token:
       {
         'applicationExpirationDate' => '260229',
         'applicationPrimaryAccountNumber' => '1355633394086542',
         'currencyCode' => '980',
         'deviceManufacturerIdentifier' => '154330030233',
         'paymentData' => {
                            'onlinePaymentCryptogram' => 'ADzPtgTs95ORAFLxQylNJoABFA=='
                          },
         'paymentDataType' => '3DSecure',
         'transactionAmount' => 100
       };

=cut
#**********************************************************
sub decrypt {
  my ($token) = @_;
  my $ephemeral_public_key = $token->{header}->{ephemeralPublicKey};
  my $cipher_text = $token->{data};

  my $cert_pem = _load_pem_file('apple-pay-processing-cert.pem');
  return _throw_error(59001) if (!$cert_pem);
  my $private_key_pem = _load_pem_file('apple-pay-processing-private-key.pem');
  return _throw_error(59002) if (!$private_key_pem);

  my $json;

  eval {
    my $sharedSecret = _shared_secret($private_key_pem, $ephemeral_public_key);
    my $merchantId = _merchant_id($cert_pem);
    my $symmetricKey = _symmetric_key($merchantId, $sharedSecret);
    my $decrypted = _decrypt_ciphertext($symmetricKey, $cipher_text);
    $json = decode_json($decrypted);
  };

  if ($@) {
    return _throw_error(59003);
  }
  else {
    return $json;
  }
}

#**********************************************************
=head2 _shared_secret($private_pem, $ephemeral_public_key) - get secret

  INPUT:
    $private_pem: string          - private pem from apple developer console
    $ephemeral_public_key: string - parameter received inside apple pay token

  RESULT:
   $hex_secret: string: getting secret based on $private_pem and $ephemeral_public_key

=cut
#**********************************************************
sub _shared_secret {
  my ($private_key_pem, $ephemeral_public_key) = @_;

  my $prv = Crypt::PK::ECC->new(\$private_key_pem);
  my $spki_der = decode_base64($ephemeral_public_key);

  my $ec_key = Crypt::PK::ECC->new(\$spki_der, 'spki');
  my $secret = $prv->shared_secret($ec_key);

  my $hex_secret = unpack('H*', $secret);

  return $hex_secret;
}

#**********************************************************
=head2 _merchant_id($cert_pem) - get secret

  INPUT:
    $cert_pem: string - cert pem received from apple developer console

  RESULT:
   $merchant_id: string: id of merchant which inside $cert_pem

=cut
#**********************************************************
sub _merchant_id {
  my ($cert_pem) = @_;
  my $cert_obj = Crypt::OpenSSL::X509->new_from_string($cert_pem);

  my $oids = $cert_obj->extensions_by_oid();
  my $merchant_id = q{};

  foreach my $oid (keys %{$oids}) {
    next if ($oid ne $MERCHANT_OID);
    my $oid_val = $oids->{$oid}->value();
    $oid_val = substr($oid_val, 1);
    $merchant_id = substr(pack('H*', ($oid_val)), 2);
    last;
  }

  return $merchant_id;
}

#**********************************************************
=head2 _symmetric_key($merchant_id, $shared_secret) - get

  INPUT:
    $merchantId: string     - merchant id received from Paysys::lib::ApplePayDecrypt::_shared_secret function
    $shared_secret: string  - secret received from Paysys::lib::ApplePayDecrypt::_merchantId function

  RESULT:
   $symmetric_key: string - key based on $merchant_id and $shared_secret

=cut
#**********************************************************
sub _symmetric_key {
  my ($merchant_id, $shared_secret) = @_;

  my $kdf_algorithm = "\x0did-aes256-GCM";
  my $kdf_party_v = pack('H*', $merchant_id);
  my $kdf_party_u = 'Apple';
  my $kdf_info = $kdf_algorithm . $kdf_party_u . $kdf_party_v;

  my $sha1 = Digest::SHA->new(256);
  $sha1->add(pack("H*", '000000'));
  $sha1->add(pack("H*", '01'));
  $sha1->add(pack("H*", $shared_secret));
  $sha1->add($kdf_info);
  my $symmetric_key = $sha1->hexdigest();

  return $symmetric_key;
}

#**********************************************************
=head2 _decrypt_ciphertext($symmetric_key, $cipher_text) - get decoded token

  INPUT:
    $symmetric_key: string  - secret received from Paysys::lib::ApplePayDecrypt::_symmetric_key function
    $cipher_text: string    - parameter received inside apple pay token

  RESULT:
   $token: string - decrypted apple pay token

=cut
#**********************************************************
sub _decrypt_ciphertext {
  my ($symmetric_key, $cipher_text) = @_;

  my $data = decode_base64($cipher_text);
  my $symmetric_key_bin = pack("H*", $symmetric_key);
  my $iv = "\x00" x 16;
  my $ciphertext = substr($data, 0, -16);

  my $decipher = Crypt::AuthEnc::GCM->new("AES", $symmetric_key_bin, $iv);
  my $token = $decipher->decrypt_add($ciphertext);

  my $expected_tag = substr($data, -16);
  my $tag = $decipher->decrypt_done();
  return '' if $tag ne $expected_tag;;

  return $token;
}

#**********************************************************
=head2 _load_pem_file($filename) - return content of pem

  INPUT:
    $filename: string - name of file

  RESULT:
   $pem_file: string  - pem file content

=cut
#**********************************************************
sub _load_pem_file {
  my ($filename) = @_;

  return '' if (!$filename);

  my $dir = $main::base_dir || '/usr/axbills/';
  my $file_loc .= $dir . "Certs/apple/$filename";

  my $pem_file = '';

  open(my $fh, '<', $file_loc) || return '';
  while (<$fh>) {
    $pem_file .= $_;
  }
  close($fh);

  return $pem_file;
}

#**********************************************************
=head2 _throw_error($id) - return error object

  INPUT:
    $id: number - id of error

  RESULT:
   {
     errno: number  - id of error
     errstr: string - description of error
   }

=cut
#**********************************************************
sub _throw_error {
  my ($id) = @_;

  my %errors = (
    unknown => {
      errno  => 59000,
      errstr => 'Unknown error',
    },
    59001 => {
      errno  => 59001,
      errstr => 'Private cert not found. Check configurations.',
    },
    59002 => {
      errno  => 59002,
      errstr => 'Private pem not found. Check configurations.',
    },
    59003 => {
      errno  => 59003,
      errstr => 'Failed to decrypt apple pay token. Please try later or write technical support',
    },
  );

  return $errors{$id} || $errors{unknown};
}

1;
