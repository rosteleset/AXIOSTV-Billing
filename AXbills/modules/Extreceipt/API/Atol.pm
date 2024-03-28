=head1 NAME

  Модуль взаимодействия с сервисом "Atol"

=cut


package Atol;
use strict;
use warnings FATAL => 'all';

use JSON;
use utf8 qw/encode/;
use Encode qw/encode_utf8/;
use AXbills::Base qw(_bp);

my $api_url = '';
my $curl    = '';

my $datetime = join('.', reverse(split('-', $main::DATE))) . " " . $main::TIME;

#**********************************************************
=head2 new($conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $conf, $attr) = @_;

  $api_url = $attr->{url};
  $curl    = $conf->{FILE_CURL} || 'curl';
  
  my $self = {
    APP_ID       => $attr->{login},
    SECRET       => $attr->{password},
    goods        => $attr->{goods_name},
    email        => $attr->{email},
    inn          => $attr->{inn},
    callback_url => $attr->{callback},
    billing_url  => $attr->{address},
    api          => $attr->{api_name},
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 init()

=cut
#**********************************************************
sub init {
  my $self = shift;

  my %data = (
    login => $self->{APP_ID},
    pass  => $self->{SECRET}
  );

  my $j_data = $self->perl2json(\%data);
  my $url = $api_url . "getToken";
  my $params = qq(-d '$j_data' -H "Content-Type: application/json");
  my $result = `$curl $params -s -X POST "$url"`;
  my $perl_hash = ();
  eval { $perl_hash = decode_json($result); 1 };
  if ($self->{debug}) {
    print "CMD: $curl -s '$url' $params\n";
    print "RESULT: $result\n";
  }

  $self->{TOKEN} = $perl_hash->{token};

  return 0 if (!$self->{TOKEN});
  
  return 1;
}

#**********************************************************
=head2 payment_register($attr)

  Регистрирует платеж в онлайн-кассе

=cut
#**********************************************************
sub payment_register {
  my $self = shift;
  my ($attr) = @_;

  if ($self->{debug}) {
    print "\nTry print Check for payment $attr->{payments_id}\n";
  }
  
  my %data = (
    external_id => $attr->{payments_id},
    timestamp   => $datetime,
    service     => {
      callback_url => $self->{callback_url}
    },
    receipt => {
      client => {
        email => $attr->{mail},
        phone => $attr->{phone} || $attr->{c_phone},
      },
      company => {
        email           => $self->{email},
        inn             => $self->{inn},
        payment_address => $self->{billing_url},
      },
      items => [{
        name           => ($self->{goods} || q{}) . ' UID: ' . $attr->{uid},
        price          => "INT:$attr->{sum}",
        quantity       => "INT:1",
        sum            => "INT:$attr->{sum}",
        payment_object => "service",
        vat            => {
          type => "none",
        }
      }],
      payments => [{
        type => "INT:1",
        sum  => "INT:$attr->{sum}",
      }],
      total => "INT:$attr->{sum}",
    }
  );

  my $p_data = $self->perl2json(\%data);

  my $params = qq(-d '$p_data' -H "Token: $self->{TOKEN}" -H "Content-type: application/json; charset=utf-8");
  my $url = $api_url . $attr->{kkt_group} . "/sell";
  my $result = `$curl $params -s -X POST "$url"`;
  my $perl_hash = ();
  eval { $perl_hash = decode_json($result); 1 };
  if ($self->{debug}) {
    print "CMD: $curl $params -s -X POST '$url'\n";
    print "RESULT: $result\n";
    if ($perl_hash->{error}) {
      my $error = encode_utf8($perl_hash->{error}{text});
      print "ERROR: $error\n";
    }
  }

  return $perl_hash->{uuid} || 0;
}

#**********************************************************
=head2 get_info($id) - Получает информацию по ранее зарегистрированному платежу

  Arguments:
    $attr
      kkt_group

  Results:
    $fiscal_document_number, $fiscal_document_attribute, $receipt_datetime,  $external_id, $error

=cut
#**********************************************************
sub get_info {
  my $self = shift;
  my ($attr) = @_;
  
  if ($self->{debug}) {
    print "\nTry get report for $attr->{command_id}\n";
  }

  delete $self->{errstr};
  delete $self->{error};

  my $params = qq(-H "Token: $self->{TOKEN}");
  my $url = $api_url . $attr->{kkt_group} . "/report/$attr->{command_id}";
  my $result = `$curl $params -s -X GET "$url"`;
  print qq{$curl $params -s -X GET "$url"} if($self->{debug});
  my $perl_hash = ();
  eval { $perl_hash = decode_json($result); 1 };

  if ($self->{debug}) {
    print "CMD: $curl $params -s -X GET '$url'\n";
    print "RESULT: $result\n";
    if ($perl_hash->{error}) {
      my $error = encode_utf8($perl_hash->{error}{text});
      print "ERROR: $error\n";
      return (0,0,0,$perl_hash->{external_id},1);
    }
  }

  if ( $perl_hash->{uuid} && $perl_hash->{external_id}) {
    my $error_code = 0;
    if ($perl_hash->{error}) {
      $self->{errstr}=encode_utf8($perl_hash->{error}{text});
      $self->{error}=1;
      $error_code = 1;
    }
    return (
      $perl_hash->{payload}->{fiscal_document_number},
      $perl_hash->{payload}->{fiscal_document_attribute},
      $perl_hash->{payload}->{receipt_datetime},
      $perl_hash->{external_id},
      $error_code
    );
  }

  return (0, 0, 0, $perl_hash->{external_id}, 1);
}

#**********************************************************
=head2 payment_cancel($attr) - Регистрирует отмену чека в онлайн-кассе

  Arguments:
    $attr

=cut
#**********************************************************
sub payment_cancel {
  my $self = shift;
  my ($attr) = @_;

  if ($self->{debug}) {
    print "\nTry \\cancel payment $attr->{payments_id}\n";
  }
  
  my %data = (
    external_id => "$attr->{payments_id}-c",
    timestamp   => $datetime,
    service     => {
      callback_url => $self->{callback_url}
    },
    receipt => {
      client => {
        email => $attr->{mail},
        phone => $attr->{phone},
      },
      company => {
        email           => $self->{email},
        inn             => $self->{inn},
        payment_address => $self->{billing_url},
      },
      items => [{
        name           => $self->{goods},
        price          => "INT:$attr->{sum}",
        quantity       => "INT:1",
        sum            => "INT:$attr->{sum}",
        payment_object => "service",
        vat            => {
          type => "none",
        }
      }],
      payments => [{
        type => "INT:1",
        sum  => "INT:$attr->{sum}",
      }],
      total => "INT:$attr->{sum}",
    }
  );

  my $p_data = $self->perl2json(\%data);

  my $params = qq(-d '$p_data' -H "Token: $self->{TOKEN}" -H "Content-type: application/json; charset=utf-8");
  my $url = $api_url . $attr->{kkt_group} . "/sell_refund";
  my $result = `$curl $params -s -X POST "$url"`;
  my $perl_hash = ();
  eval { $perl_hash = decode_json($result); 1 };
  if ($self->{debug}) {
    print "CMD: $curl $params -s -X POST '$url'\n";
    print "RESULT: $result\n";
    if ($perl_hash->{error}) {
      my $error = encode_utf8($perl_hash->{error}{text});
      print "ERROR: $error\n";
    }
  }

  return $perl_hash->{uuid} || 0;
}


#**********************************************************
=head2 perl2json($data)

  Arguments:


=cut
#**********************************************************
sub perl2json {
  my $self = shift;
  my ($data) = @_;
  my @json_arr = ();

  if (ref $data eq 'ARRAY') {
    foreach my $key (@{$data}) {
      push @json_arr, $self->perl2json($key);
    }
    return '[' . join(',', @json_arr) . "]";
  }
  elsif (ref $data eq 'HASH') {
    foreach my $key (sort keys %$data) {
      my $val = $self->perl2json($data->{$key});
      push @json_arr, qq{\"$key\":$val};
    }
    return '{' . join(',', @json_arr) . "}";
  }
  else {
    $data //='';
    if ($data =~ m/INT:(.*)/) {
      return qq{$1};
    }
    return qq{\"$data\"};
  }
}

#**********************************************************
=head2 test() - Тест подключения

=cut
#**********************************************************
sub test {
  my $self = shift;
  #my ($attr) = @_;

  return 1;
}

1;




1