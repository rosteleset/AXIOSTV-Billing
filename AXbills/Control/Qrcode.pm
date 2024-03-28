package Control::Qrcode;
=head1 NAME

   QR code generator

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(urlencode urldecode load_pmodule encode_base64);

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    $attr
      HTML: html object
      functions: hash of available functions

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $attr) = @_;

  my $self = {
    db        => $db,
    admin     => $admin,
    conf      => $conf,
    html      => $attr->{html},
    functions => $attr->{functions},
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 qr_make($url, $attr)

  Arguments:
    $url - base url for QRCode
    $attr - hash_ref
      PARAMS      - hash to be stringified and appended to base url
      OUTPUT2RETURN  - RReturn img OBJ with html
      WRITE_TO_DISK

=cut
#**********************************************************
sub qr_make {
  my $self = shift;
  my ($url, $attr) = @_;

  $url //= q{};

  if ($attr->{WRITE_TO_DISK}) {
    return $self->_encode_url_to_img($url, $attr);
  }

  if (!$attr->{qindex} || $attr->{OUTPUT2RETURN}) {
    my $img_html_tag = $self->_generate_img_tag($url, $self->_stringify_params($attr), $attr);

    return $img_html_tag if ($attr->{OUTPUT2RETURN});

    print $img_html_tag;
    return 1;
  }

  $self->_encode_url_to_img($url, $attr);

  return 1;
}

#**********************************************************
=head2 qr_make_image_from_string() - encodes data to qrcode

  Arguments:
    $string - data to encode
    $attr   - hash_ref
      img - return encoded into base64 html element img
    
  Returns
    string - JPEG image content
    
=cut
#**********************************************************
sub qr_make_image_from_string {
  my $self = shift;
  my ($string, $attr) = @_;

  my $img = $self->_generate_image($string);

  if ($attr->{base64}) {
    return q{data:image/jpg;base64,} . encode_base64($img) . q{};
  }
  if ($attr->{img}) {
    return "<img src='data:image/jpg;base64," . encode_base64($img) . "' alt='" . ($attr->{alt} || '') . "' style='" . ($attr->{style} || '')."'>";
  }
  else {
    return $img;
  }
}

#**********************************************************
=head2 _generate_img_tag($params, $attr) - generate HTML <img> that points to same func

  Arguments:
    $params
    $attr - hash_ref

  Returns:
    HTML code for <img>

=cut
#**********************************************************
sub _generate_img_tag {
  my $self = shift;
  my ($url, $params, $attr) = @_;

  my $global_url_options = ($attr->{GLOBAL_URL}) ? "&GLOBAL_URL=" . $attr->{GLOBAL_URL} : "";

  return $self->{html}->img("$url$params&qrcode=1&qindex=100000$global_url_options", "qrcode",
    { OUTPUT2RETURN => 1, class => 'img-fluid center-block' }
  );
}

#**********************************************************
=head2 _encode_url_to_img($params, $attr) - output QRCode image

  Arguments:
    $params - params for url
    $text - link

  Returns:
    1

=cut
#**********************************************************
sub _encode_url_to_img {
  my $self = shift;
  my ($url, $attr) = @_;

  $url //= q{};

  my $url_to_encode = '';
  if ($attr->{PARAMS} && $attr->{PARAMS}->{GLOBAL_URL} && !$attr->{PARAMS}->{CONVERT_URL}) {
    $url_to_encode = urldecode($attr->{PARAMS}->{GLOBAL_URL});
  }
  elsif ($attr->{AUTH_G2FA_NAME} && $attr->{AUTH_G2FA_MAIL}) {
    $url_to_encode = "otpauth://totp/$attr->{AUTH_G2FA_MAIL}?secret=$url&issuer=$attr->{AUTH_G2FA_NAME}"
  }
  elsif ($attr->{QRCODE_URL}) {
    $url_to_encode = $attr->{QRCODE_URL};
  }
  else {
    $url_to_encode = $url . $self->_stringify_params($attr->{PARAMS}) . "&full=1";
  }

  my $img = $self->_generate_image($url_to_encode);

  if ($attr->{OUTPUT2RETURN}) {
    return $img;
  }

  if ($attr->{WRITE_TO_DISK}) {
    open(my $QRCODE, '>', $self->{conf}{TPL_DIR} . "/qrcode.jpg");
    print $QRCODE $img;
  }
  elsif (!$attr->{header}) {
    print "Content-Type: image/jpeg\n\n";
    print $img;
  }

  return 1;
}

#**********************************************************
=head2 _generate_image($data)

=cut
#**********************************************************
sub _generate_image {
  my $self = shift;
  my ($data) = @_;

  load_pmodule('Imager::QRCode');
  my $qr = Imager::QRCode->new(
    size          => 8,
    margin        => 1,
    version       => 1,
    level         => 'M',
    casesensitive => 1,
    lightcolor    => Imager::Color->new(255, 255, 255),
    darkcolor     => Imager::Color->new(0, 0, 0),
  );

  my $img = $qr->plot($data);
  my $result = '';

  $img->write(data => \$result, type => 'jpeg');

  if ($img->errstr && !$self->{conf}->{QRCODE_HIDE_ERROR}) {
    print "Content-Type: text/html\n\n";
    print $img->errstr;
  }

  return $result;
}

#**********************************************************
=head2 _stringify_params($attr) - stringify params ( %FORM ) hash

  Arguments:
    $attr - hash_ref

  Returns:
    string

=cut
#**********************************************************
sub _stringify_params {
  my $self = shift;
  my ($attr) = @_;
  my $params = '';

  if (ref $attr eq 'HASH') {
    while (my ($key, $val) = each %{$attr}) {

      next if ((!$key) || ($key eq 'qrcode' || $key eq '__BUFFER' || $key eq 'qindex'));

      if ($key eq 'index') {
        $key = 'get_index';
        $val = $self->{functions}{ $attr->{index} };
      }

      $params .= "$key=" . urlencode($val) . '&';
    }
  }

  return "?" . $params;
}

1;
