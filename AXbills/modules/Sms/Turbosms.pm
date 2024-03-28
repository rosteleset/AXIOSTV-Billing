package Turbosms;

=head1 NAME

  Turbosms gate interfaca

=head1 VERSION

  VERSION: 8.05
  REVISION: 20200831

=cut

use strict;

use parent 'dbcore';

our $VERSION = 8.05;
my $MODULE = 'Turbosms';
my ($admin, $CONF);

our %SYSTEM_CONF = (
  SMS_TURBOSMS_DBHOST         => '',
  SMS_TURBOSMS_DBNAME         => 'users',
  SMS_TURBOSMS_DBCHARSET      => 'utf8',
  SMS_TURBOSMS_USER           => '',
  SMS_TURBOSMS_PASSWD         => '',
  SMS_TURBOSMS_TABLE          => '',
  SMS_TURBOSMS_SEND_TIME      => '12:00:00',
  SMS_TURBOSMS_SEND_FEES      => 1,
  SMS_TURBOSMS_DEBUG          => 0,
  SMS_TURBOSMS_MESSAGE_HEADER => '',
  SMS_TURBOSMS_SIGN           => '',
);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;

  my $self = { };
  bless( $self, $class );
  $self->{db} = $db;

  use AXbills::SQL;
  my $sql = AXbills::SQL->connect( 'mysql', $CONF->{SMS_TURBOSMS_DBHOST}, $CONF->{SMS_TURBOSMS_DBNAME},
    $CONF->{SMS_TURBOSMS_USER}, $CONF->{SMS_TURBOSMS_PASSWD},
    { CHARSET => ($CONF->{SMS_TURBOSMS_DBCHARSET}) ? $CONF->{SMS_TURBOSMS_DBCHARSET} : 'utf8' } );
  $self->{db2} = $sql->{db};

  $self->{SERVICE_NAME} = 'TurboSMS';
  $self->{SERVICE_VERSION} = $VERSION;

  return $self;
}

#**********************************************************
=head2 info($attr)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = (defined( $attr->{DESC} )) ? $attr->{DESC} : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if ($attr->{NUMBER} && $attr->{NUMBER} !~ /\+\d/){
    $attr->{NUMBER} = '+' . $attr->{NUMBER};
  } elsif ($attr->{PHONE} && $attr->{PHONE} !~ /\+\d/) {
    $attr->{PHONE} = '+' . $attr->{PHONE};
  }

  if (($attr->{FROM_DATE} && $attr->{TO_DATE}) && ($attr->{FROM_DATE} eq $attr->{TO_DATE})) {
    push @WHERE_RULES, "sended >= '$attr->{FROM_DATE} 00:00:00' AND sended <= '$attr->{FROM_DATE} 23:59:59'";
  }
  elsif ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    push @WHERE_RULES, "(sended >= '$attr->{FROM_DATE} 00:00:00' AND sended <= '$attr->{TO_DATE} 23:59:59')"
  }

  my $WHERE = $self->search_former( $attr, [
      [ 'ID',                'INT',  'id',      ],
      [ 'PHONE',             'STR',  'number'   ],
      [ 'MESSAGE',           'STR',  'message', ],
      [ 'STATUS',            'STR',  'status',  ],
    ],
    { 
      WHERE         => 1,
      WHERE_RULES   => \@WHERE_RULES
    }
  );

  if($attr->{SHOW_SENDED}) {
    $WHERE .= ($WHERE) ? "OR sended is NULL" : "WHERE sended is NULL";
  }

  $self->query( "SELECT id, msg_id, number, sign, message, wappush, cost, balance,
     send_time, sended, received AS updated, status, error_code 
  FROM `$CONF->{SMS_TURBOSMS_TABLE}`
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    { %{$attr}, DB_REF => $self->{db2} },
  );

  my $list = $self->{list};
  $self->query( "SELECT COUNT(id) AS total FROM $CONF->{SMS_TURBOSMS_TABLE} $WHERE;", undef,
    { INFO => 1, DB_REF => $self->{db2} } );

  return $list;
}

#**********************************************************
=head2 send_sms($attr)

=cut
#**********************************************************
sub send_sms {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data( $attr );

  my $debug = $attr->{DEBUG} || $CONF->{SMS_TURBOSMS_DEBUG} || 0;
  my $sign = $CONF->{SMS_TURBOSMS_SIGN} || '';
  my $send_time = '';
  my $values = '';

  if ( $attr->{PERIODIC} && $CONF->{SMS_TURBOSMS_SEND_TIME} ){
    $send_time = $CONF->{SMS_TURBOSMS_SEND_TIME};
  }

  #Convert from win1251 to utf8
  if ( !$CONF->{dbcharset} || $CONF->{dbcharset} ne 'utf8' ){
    use Encode;
    Encode::from_to( $DATA{MESSAGE}, 'windows-1251', 'utf-8' );
  }

  if ( $attr->{NUMBERS} ){
    while (my ($number, undef) = each %{ $attr->{NUMBERS} }) {
      if ( !$number ){
        delete( $attr->{NUMBERS}{$number} );
        next;
      }
      elsif ( $CONF->{SMS_TURBOSMS_NUMBER_EXPR} ){
        if ( $number =~ $CONF->{SMS_TURBOSMS_NUMBER_EXPR} ){
          delete( $attr->{NUMBERS}{$number} );
          next;
        }
      }
      $DATA{MESSAGE} =~ s/\'/\\\'/g;
      $values .= "('$number', '$sign', '$DATA{MESSAGE}', '" . (($send_time) ? "CONCAT('curdate()+interval 1 day', '$send_time')" : '') . "'),";
    }
  }
  else{
    if ( !$DATA{NUMBER} ){
      $self->{errno} = 20;
      $self->{errstr} = "ERROR_PHONE_NOT_EXIST";
      return $self;
    }
    elsif ( $CONF->{SMS_TURBOSMS_NUMBER_EXPR} ){
      if ( $DATA{NUMBER} =~ $CONF->{SMS_TURBOSMS_NUMBER_EXPR} ){
        $self->{errno} = 21;
        $self->{errstr} = "ERROR_WRONG_PHONE";
        return $self;
      }
    }
    $DATA{MESSAGE} =~ s/\'/\\\'/g;
    my @numbers  = split(/, /, $DATA{NUMBER});

    my @requests = ();
    foreach my $number (@numbers) {
      push @requests,  "('$number', '$sign', '$DATA{MESSAGE}', '" . (($send_time) ? "CONCAT('CURDATE()+interval 1 day', '$send_time')" : '') . "') ";
    }
    $values = join(', ', @requests);
  }

  chop( $values );

  my $sql = "INSERT INTO $CONF->{SMS_TURBOSMS_TABLE}  (number,sign,message, send_time)
        VALUES $values;";

  if ( $debug > 3 ){
    print "Turbosms query:$sql";
  }

  if ($self->{conf}->{SMS_TURBOSMS_VIBER} && $attr->{VIBER}) {
    my $your_number = _create_tpl_mess({
        NUMBERS => $attr->{NUMBERS} || '',
        NUMBER  => $attr->{NUMBER} || '',
        VIBER   => $attr->{VIBER} || 0
    });

    my $send_url = $self->{conf}->{SMS_TURBOSMS_VIBER_URL};
    my $token = $self->{conf}->{SMS_TURBOSMS_VIBER_TOKEN} || '';
    my $sender = $self->{conf}->{SMS_TURBOSMS_MESSAGE_HEADER} || 'Internet';
    my $message = $attr->{MESSAGE};
    
    $message =~ s/\n/\\n/g;
    
    return send_sms_viber($send_url, $your_number, $sender, $message, $token);
  }

  if ( $debug < 5 ) {
    $self->query( "$sql;", 'do', { DB_REF => $self->{db2} } );

    return $self if ($self->{errno});
  }
  
  return $self;
}

#**********************************************************
=head2 send_sms_viber()

=cut
#**********************************************************
sub send_sms_viber {
  my ($send_url, $numbers, $sender, $message, $token) = @_;

  my @headers = ("Authorization: Basic $token", " Authorization: Bearer $token", "Content-Type: application/json");

  my $request_tmp = qq{
    {
      "recipients": [
        $numbers
      ],
      "viber":{
          "sender": "$sender",
          "text": "$message"
      }
    }
  };

  my $result = web_request($send_url, {
      POST         => $request_tmp,
      HEADERS      => \@headers,
      RETURN_JSON  => 1
  });

  return $result;
}

#**********************************************************
=head2 _create_tpl_mess()

=cut
#**********************************************************
sub _create_tpl_mess {
    my ($attr) = @_;

    my $your_number = '';
    if ($attr->{NUMBERS} && $attr->{NUMBERS} ne '') {
        foreach my $number (sort keys %{$attr->{NUMBERS}}) {
            $attr->{NUMBERS} =~ s/ //g;
            $attr->{NUMBERS} =~ s/-//g;
            
            $your_number .= qq{ "$attr->{NUMBERS}" };
        }
    }
    elsif ($attr->{NUMBER} && $attr->{NUMBER} ne '') {
        foreach my $number ( split(/,\s?/, $attr->{NUMBER}) ) {
            $attr->{NUMBER} =~ s/ //g;
            $attr->{NUMBER} =~ s/-//g;

            $your_number .= qq{ "$attr->{NUMBERS}" };
        }
    }

    return $your_number;
}

#**********************************************************
=head2 error_codes()

=cut
#**********************************************************
sub error_codes {

  my %status_codes = (
    0         => 'Ошибок нет',
    2         => 'Не удалось сохранить данные, свяжитесь с отделом поддержки если ошибка будет повторяться',
    23        => 'Ошибки в номере получателя',
    34        => 'Страна получателя не поддерживается, необходима дополнительная активация',
    36        => 'Не удалось отправить сообщение, свяжитесь с отделом поддержки если ошибка будет повторяться',
    40        => 'Не достаточно кредитов на балансе',
    46        => 'Номер получателя в стоплисте',
    69        => 'Альфаимя (подпись отправителя) запрещено администратором',
    83        => 'Дубликат сообщения',
    84        => 'Отсутствует текст сообщения',
    85        => 'Неверное альфаимя (подпись отправителя)',
    86        => 'Текст сообщения содержит запрещённые слова',
    87        => 'Слишком длинный текст сообщения',
    88        => 'Ваша учётная запись заблокирована за нарушения, свяжитесь с отделом поддержки',
    999       => 'Специфическая ошибка конкретного оператора, необходимо уточнять дополнительно',

    'NULL'    => 'Сообщение ещё не обработано',
    'ACCEPTD' => 'Сообщение принято в обработку',
    'ENROUTE' => 'Сообщение отправлено в мобильную сеть',
    'DELIVRD' => 'Сообщение доставлено получателю',
    'EXPIRED' => 'Истек срок сообщения',
    'DELETED' => 'Удалено оператором',
    'UNDELIV' => 'Не доставлено',
    'REJECTD' => 'Сообщение отклонено',
    'UNKNOWN' => 'Неизвестный статус',
  );

  return \%status_codes;
}

#**********************************************************
=head2 account_info()

=cut
#**********************************************************
sub account_info{

  return [ ];
}

#**********************************************************
=head2 get_status()

=cut
#**********************************************************
sub get_status {
  my $self = shift;
  my ($attr) = @_;

  my %status_sms = (
    'UNKNOWN' => 16,
    'EXPIRED' => 16,
    'DELETED' => 16,
    'DELIVRD' => 100,
    'UNDELIV' => 101,
    'REJECTD' => 103,
  );

  my $result_request = $self->query(
    "SELECT * FROM $CONF->{SMS_TURBOSMS_TABLE} WHERE id = $attr->{EXT_ID};",
    undef, { 
      COLS_NAME => 1, 
      DB_REF    => $self->{db2} 
    } 
  );

  my $list = $result_request->{list};

  if ( $list->[0] && $list->[0]{status} ) {
    $list->[0]{status} = $status_sms{ $list->[0]{status} } || 16;
  }
  else {
    return qq{ };
  }

  return @{ $list } || qq{ };
}

1
