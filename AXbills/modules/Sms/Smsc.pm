package Smsc;

=head1 NAME

   Smsc
   HTTP API
   http://smsc.ru/api/http/


   api_version = '3.0';

=head1 VERSION

  VERSION: 0.25
  REVISION: 20210730

=cut

use strict;
use parent 'dbcore';
our $VERSION = 0.25;


use AXbills::Base qw(load_pmodule);
use AXbills::Fetcher;
my $MODULE = 'Smsc';

my $md5;
my $admin;
my $db;
my $CONF;
my $json;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  ($db ,$admin, $CONF)  = @_;
  $admin->{MODULE} = $MODULE;

  my $self = {};
  bless($self, $class);

  load_pmodule('Digest::MD5');
  load_pmodule('JSON');

  $md5 = Digest::MD5->new();
  $json = JSON->new->allow_nonref;

  if ($CONF->{SMS_DEBUG}) {
    $self->{debug}=$CONF->{SMS_DEBUG};
  }

  $self->{SERVICE_NAME}      = "Smsc";
  $self->{SERVICE_VERSION}   = $VERSION;
  $self->{SMS_SMSC_USER}     = $CONF->{SMS_SMSC_USER} || q{};
  $self->{SMS_SMSC_PASSWORD} = $CONF->{SMS_SMSC_PASSWORD} || q{};

  return $self;
}


#**********************************************************
=head2 smsc_send_request($attr)

  Arguments:
    $attr

  Results:
    $self

=cut
#**********************************************************
sub smsc_send_request {
  my $self = shift;
  my ($attr) = @_;

  my $request_url = 'https://smsc.ru/sys/';
  my $result      = '';

  if ($attr->{ACTION}){
    $request_url .= "$attr->{ACTION}?";

    if ($attr->{ACTION} =~ /get\.php/) {
      $request_url .= "get_stat=1&";
    }
  }

  my $request = "login=$self->{SMS_SMSC_USER}&psw=$self->{SMS_SMSC_PASSWORD}";

  $request .= "&charset=utf-8";

  $attr->{JSON}=1;
  if($attr->{JSON}) {
    $request .= "&fmt=3";
  }

  if($attr->{TEXT}) {
    $attr->{TEXT} =~ s/[\r\n]/ /g;
    $attr->{TEXT} =~ s/ /%20/g;

    $request .= "&mes=$attr->{TEXT}";
  }

  if ($attr->{BALANCE2}) {
    $request .= "&balance2=1";
  }

  if($attr->{PHONE}) {
    $request .= "&phones=$attr->{PHONE}";
  }
  elsif($attr->{LIST_ID}) {
    $request .= "&list_id=$attr->{LIST_ID}";
  }

  if(defined($attr->{DATETIME})) {
    $request .= "&datetime=$attr->{DATETIME}";
  }

  if(defined($attr->{SMS_LIFETIME})) {
    $request .= "&sms_lifetime=$attr->{SMS_LIFETIME}";
  }

  if ($attr->{FROM_DATE} && $attr->{FROM_DATE} =~ /(\d{4})\-(\d{2})\-(\d{2})/) {
    $request .= "&start=$3.$2.$1";
  }

  if ($attr->{TO_DATE} && $attr->{TO_DATE} =~ /(\d{4})\-(\d{2})\-(\d{2})/) {
    $request .= "&end=$3.$2.$1";
  }

  if($attr->{EXT_PARAMS}) {
    $request .= $attr->{EXT_PARAMS};
  }

  if($attr->{ID}) {
    $request .= "&id=$attr->{ID}";
  }

  if($attr->{COUNTRY}) {
    $request .= "&country=$attr->{COUNTRY}";
  }

  if($attr->{SENDER}) {
    $request .= "&sender=$attr->{SENDER}";
  }

  if ($CONF->{SMS_SMSC_TEST_MODE}) {
    if ($CONF->{SMS_SMSC_TEST_MODE} > 2) {
      $request .= '&cost=1';
    }
  }

  $request_url .= $request;

  if($self->{debug}) {
    $attr->{DEBUG}=3;
  }


  $result  = web_request($request_url, { DEBUG => (($attr->{DEBUG} && $attr->{DEBUG} > 2) ? $attr->{DEBUG} : undef),
    CURL  => 1,
  });

  my %smsc_statsus_2axbills_status = (
    '' => 0,   # '� ������� ��������',
    3  => 1,   # Недостаточно средств на счете Клиента. ,
    '' => 2,   # '� �������� ��������',
    '' => 3,   # '����������',
    7  => 4,   # 'Неверный формат номера телефона.,
    '' => 5,   # '�������� ����������',
    6  => 6,   # 	Сообщение запрещено (по тексту или по имени отправителя).
    2  => 7,   # 	Неверный логин или пароль.,
    '' => 8,   # '�����',
    '' => 9,   # '�������������',
    '' => 10,  # '������� ���������',
    1  => 11,  # Ошибка в параметрах.
    4  => 12,  # IP-адрес временно заблокирован из-за частых ошибок в запросах.
    5  => 13,  # Неверный формат даты.
    8  => 14,  # Сообщение на указанный номер не может быть доставлено.
    9  => 15,  # Отправка более одного одинакового запроса на передачу SMS-сообщения либо более пяти одинаковых запросов на получение стоимости сообщения в течение минуты.
  );

  if ($result =~ /^{/) {
    my $perl_scalar = $json->decode( $result );
    if($perl_scalar->{error}) {
      my $status = $perl_scalar->{error_code};
      $self->{status} = $smsc_statsus_2axbills_status{$status};
    } elsif($perl_scalar->{status}) {

      my %sms_status = (
        '-3' => 16, #Сообщение не найдено
        '-2' => 101, #Остановлено
        '-1' => 0, #Ожидает отправки
        0  => 9, #Передано оператору
        1  => 3, #Доставлено
        2  => 3, #Прочитано
        3  => 101, #Просрочено
        4  => 3, #Нажата ссылка
        20 => 102, #Невозможно доставить
        22 => 4, #Неверный номер
        23 => 6, #Запрещено
        24 => 1, #Недостаточно средств
        25 => 4 #Недоступный номер
      );

      $self->{status} = $sms_status{$perl_scalar->{status}};
    }else {
      $self->{status} = 3;
      $self->{id} = $perl_scalar->{id} || '';
    }
  }
  elsif($result =~ /^ERROR = (\d+) (.+)/) {
    my $status = $1;
    $self->{status} = $smsc_statsus_2axbills_status{$status};
  }

  return $result;
}


#**********************************************************
=head2 send_sms($attr)

=cut
#**********************************************************
sub send_sms {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{NUMBERS}){
    foreach my $number ( sort keys %{ $attr->{NUMBERS} } ) {
      $self->smsc_send_request({
        ACTION      => 'send.php',
        TEXT        => $attr->{MESSAGE},
        PHONE       => $number,
        DEBUG       => $attr->{DEBUG},
      });
    }
  }
  else {
    $self->smsc_send_request({
      ACTION      => 'send.php',
      TEXT        => $attr->{MESSAGE},
      PHONE       => $attr->{NUMBER} ,
      DEBUG       => $attr->{DEBUG},
    });
  }

  return $self;
}

#**********************************************************
=head2 send_status($attr)

=cut
#**********************************************************
sub send_status {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->smsc_send_request({
    ACTION      => 'status.php',
    TEXT        => $attr->{MESSAGE},
    PHONE       => $attr->{NUMBER} ,
    DEBUG       => $attr->{DEBUG},
    ID          => $attr->{ID},
  });

  return $result;
}

#**********************************************************
=head2 send_balance($attr)

=cut
#**********************************************************
sub send_balance {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->smsc_send_request({
    ACTION      => 'balance.php',
    TEXT        => $attr->{MESSAGE},
    PHONE       => $attr->{NUMBER} ,
    DEBUG       => $attr->{DEBUG},
    ID          => $attr->{ID},
  });

  return $result;
}

#**********************************************************
=head2 register_sender($attr)

=cut
#**********************************************************
sub register_sender {
  my $self = shift;
  #my ($attr) = @_;
  #$self->littlesms_send_request({ ACTION     => 'registerSender',
  #                          NAME       => $littlesms_sender,
  #                          COUNTRY    => $country,
  #                        });

  return $self;
}

#**********************************************************
=head2 account_info($attr)

=cut
#**********************************************************
sub account_info {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->smsc_send_request({
    ACTION     => 'get.php',
    DEBUG      => $attr->{DEBUG},
    FROM_DATE  => $attr->{FROM_DATE},
    TO_DATE    => $attr->{TO_DATE},
    BALANCE2   => 1,
  });

  if ($self->{errno}) {
    return [];
  }

  my $perl_scalar;

  if($perl_scalar) {
    $perl_scalar = $json->decode( $result );
  }

  return $perl_scalar;
}


#**********************************************************
=head2 info($attr) - Service information

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->smsc_send_request({
    ACTION     => 'get.php',
    DEBUG      => $attr->{DEBUG},
    FROM_DATE  => $attr->{FROM_DATE},
    TO_DATE    => $attr->{TO_DATE},
  });

  if ($self->{errno} || ! $result) {
    return [];
  }

  my $perl_scalar = $json->decode( $result );
  my @list = ();

  if (! $perl_scalar) {
    return ();
  }

  my $i  = 0;
  if (ref $perl_scalar eq 'HASH') {
    for ($i=$#{ $perl_scalar->{history} }; $i>=0; $i--) {
      push @list, {
        msg_id     => $perl_scalar->{history}->[$i]->{id},
        number     => $perl_scalar->{history}->[$i]->{recipient},
        message    => $perl_scalar->{history}->[$i]->{message},
        cost       => $perl_scalar->{history}->[$i]->{price},
        sended     => (($perl_scalar->{history}->[$i]->{status} eq 'delivered') ? 1 : undef),
        send_time  => $perl_scalar->{history}->[$i]->{created_at},
        updated    => $perl_scalar->{history}->[$i]->{updated_at},
        status     => $perl_scalar->{history}->[$i]->{status},
      };
    }
  }

  $self->{TOTAL} = $i;

  return \@list;
}

#**********************************************************
=head2 get_status($attr)

=cut
#**********************************************************
sub get_status {
  my $self = shift;
  my ($attr) = @_;

  return 0 if(!$attr->{EXT_ID});



  my $Sms   = Sms->new($db, $admin, $CONF);

  my $sms = $Sms->list({
    EXT_ID     => $attr->{EXT_ID},
    COLS_NAME  => 1,
    PHONE      => '_SHOW',
  });

  return 0 if(!$sms->[0]);

  my $result = $self->smsc_send_request({
    ACTION      => 'status.php',
    ID          => $attr->{EXT_ID}.'&phone='.$sms->[0]->{phone},
  });

  return $result;
}

1;
