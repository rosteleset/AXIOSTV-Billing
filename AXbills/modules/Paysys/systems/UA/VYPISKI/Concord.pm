=head1 Sberbank
  New module for Concord bank payment system

  Date: 22.06.2018
  UPDATE:17.10.2019

  VERSION:8.00
=cut

package Paysys::systems::Concord;
use strict;
use warnings FATAL => 'all';

use AXbills::Fetcher qw/web_request/;
use AXbills::Base qw/_bp load_pmodule urlencode decode_base64 sendmail/;
use AXbills::Filters;
use Digest::SHA qw(hmac_sha256);

our $PAYSYSTEM_NAME = 'Concord';
our $PAYSYSTEM_SHORT_NAME = 'Cbank';
our $PAYSYSTEM_ID = 128;
my $conf_name = uc($PAYSYSTEM_NAME);

our $PAYSYSTEM_VERSION = '8.00';

our %PAYSYSTEM_CONF = (
  PAYSYS_NAME_PRIVATE_KEY => '',
  PAYSYS_NAME_PUBLIC_KEY  => '',
  PAYSYS_NAME_MAIL_TO  => '',
  PAYSYS_NAME_MAIL_FROM  => '',
);

my ($json, $users);

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

  load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  if($attr->{USER}){
    $users = $attr->{USER};
  }

  if($attr->{NAME}){
    $conf_name = uc($attr->{NAME});
  }


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

  $SETTINGS{VERSION} = $PAYSYSTEM_VERSION;
  $SETTINGS{ID} = $PAYSYSTEM_ID;
  $SETTINGS{NAME} = $PAYSYSTEM_NAME;

  $SETTINGS{CONF} = \%PAYSYSTEM_CONF;

  return %SETTINGS;
}

#**********************************************************
=head2 get_statements()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub get_statements {
  my $self = shift;
  my ($attr) = @_;

  my $url = 'https://b2b.concord.ua/api/statment/';
  my $public_key = $self->{conf}{"PAYSYS_" . $conf_name . "_PUBLIC_KEY"};
  my $private_key = $self->{conf}{"PAYSYS_" . $conf_name . "_PRIVATE_KEY"};

  my $date_from = $attr->{DATE_FROM} || $main::DATE;
  my $date_to   = $attr->{DATE_TO}   || $main::DATE;

  my $req_id = '1';

  my $signature = _make_signature($private_key, {
      DATE_FROM  => $date_from,
      DATE_TO    => $date_to,
      REQUEST_ID => $req_id,
      PUBLIC_KEY => $public_key,
    });

  if($attr->{DEBUG} > 1){
    print "FROM DATE: $date_from; TO DATE: $date_to\n";
    print "URL: $url signature=$signature&date_from=$date_from&date_to=$date_to&request_id=$req_id&public_key=$public_key\n";
  }
  my $result = web_request($url,{
      POST        => "signature=$signature&date_from=$date_from&date_to=$date_to&request_id=$req_id&public_key=$public_key",
      DEBUG       => 0,
      INSECURE    => 1,
      JSON_RETURN => 1,
    });
  if(defined $result->{result} && $result->{result} == 0){
    print "Everything ok\n";
    print "Amount of payments $result->{count}\n";
    my $json_result_data = decode_base64($result->{data});

    my $statements = $json->decode( $json_result_data );


    return $statements;
  }
  else{
    return 0;
  }

  return 1;
}

#**********************************************************
=head2 proccess()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($CHECK_FIELD, $user_info, $statement) = @_;

  my ($status_code) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
#    ORDER_ID          => "CBank:$statement->{id}",
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $user_info->{$CHECK_FIELD},
    EXT_ID            => $statement->{id},
    SUM               => $statement->{CrncyAmount},
    DATA              => $statement,
    DATE              => "$main::DATE $main::TIME",
    MK_LOG            => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => $statement->{Purpose} || 'Payments',
  });

  return $status_code;
}

#**********************************************************
=head2 user_search()

  Arguments:

  Returns:

=cut
#**********************************************************
sub user_search_by_edrpou {
  my $self = shift;
  my ($user_id, $attr) = @_;
  my $CHECK_FIELD = $attr->{CHECK_FIELD};
  my %EXTRA_FIELDS = ();
  if($attr->{EXTRA_FIELDS}) {
    %EXTRA_FIELDS = %{ $attr->{EXTRA_FIELDS} };
  }

  my $list = $users->list({
    LOGIN          => '_SHOW',
    FIO            => '_SHOW',
    DEPOSIT        => '_SHOW',
    CREDIT         => '_SHOW',
    PHONE          => '_SHOW',
    ADDRESS_FULL   => '_SHOW',
    DOMAIN_ID      => '_SHOW',
    DISABLE_PAYSYS => '_SHOW',
    GROUP_NAME     => '_SHOW',
    DISABLE        => '_SHOW',
    CONTRACT_ID    => '_SHOW',
    ACTIVATE       => '_SHOW',
    REDUCTION      => '_SHOW',
    %EXTRA_FIELDS,
    $CHECK_FIELD   => $user_id,
    #Поле расчетного счета
    _RS            => '_SHOW',
    COLS_NAME      => 1,
    COLS_UPPER     => 1,
  });

  if ($users->{errno}) {
    return 2;
  }
  elsif($users->{TOTAL} < 1) {
    return 1;
  }
  elsif($users->{TOTAL} == 1){
    return (0, $list->[0]);
  }
  else{
    return (3, $list);
  }
}

#**********************************************************
=head2 user_search_rs()

  Arguments:

  Returns:

=cut
#**********************************************************
sub user_search_by_rs {
  my $self = shift;
  my ($user_id, $attr) = @_;
  my $CHECK_FIELD = $attr->{CHECK_FIELD};
  my %EXTRA_FIELDS = ();
  if($attr->{EXTRA_FIELDS}) {
    %EXTRA_FIELDS = %{ $attr->{EXTRA_FIELDS} };
  }

  my $list = $users->list({
    LOGIN          => '_SHOW',
    FIO            => '_SHOW',
    DEPOSIT        => '_SHOW',
    CREDIT         => '_SHOW',
    PHONE          => '_SHOW',
    ADDRESS_FULL   => '_SHOW',
    DOMAIN_ID      => '_SHOW',
    DISABLE_PAYSYS => '_SHOW',
    GROUP_NAME     => '_SHOW',
    DISABLE        => '_SHOW',
    CONTRACT_ID    => '_SHOW',
    ACTIVATE       => '_SHOW',
    REDUCTION      => '_SHOW',
    %EXTRA_FIELDS,
    $CHECK_FIELD   => $user_id,
    #Поле расчетного счета
    _RS            => '_SHOW',
    COLS_NAME      => 1,
    COLS_UPPER     => 1,
  });

  if ($users->{errno}) {
    return 2;
  }
  elsif($users->{TOTAL} < 1) {
    return 1;
  }
  elsif($users->{TOTAL} == 1){
    return (0, $list->[0]);
  }
  else{
    return (3, $list);
  }
}

#**********************************************************
=head2 user_search_b()

  Arguments:

  Returns:

=cut
#**********************************************************
sub user_search_by_bill {
  my $self = shift;
  my ($user_id, $attr) = @_;
  my $CHECK_FIELD = $attr->{CHECK_FIELD};
  my %EXTRA_FIELDS = ();
  if($attr->{EXTRA_FIELDS}) {
    %EXTRA_FIELDS = %{ $attr->{EXTRA_FIELDS} };
  }

  my $list = $users->list({
    LOGIN          => '_SHOW',
    FIO            => '_SHOW',
    DEPOSIT        => '_SHOW',
    CREDIT         => '_SHOW',
    PHONE          => '_SHOW',
    ADDRESS_FULL   => '_SHOW',
    DOMAIN_ID      => '_SHOW',
    DISABLE_PAYSYS => '_SHOW',
    GROUP_NAME     => '_SHOW',
    DISABLE        => '_SHOW',
    CONTRACT_ID    => '_SHOW',
    ACTIVATE       => '_SHOW',
    REDUCTION      => '_SHOW',
    %EXTRA_FIELDS,
    $CHECK_FIELD   => $user_id,
    #Поле расчетного счета
    _RS            => '_SHOW',
    COLS_NAME      => 1,
    COLS_UPPER     => 1,
  });

  if ($users->{errno}) {
    return 2;
  }
  elsif($users->{TOTAL} < 1) {
    return 1;
  }
  elsif($users->{TOTAL} == 1){
    return (0, $list->[0]);
  }
  else{
    return (3, $list);
  }
}

#**********************************************************
=head2 _make_signature()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _make_signature {
  my ($private_key, $attr) = @_;

  my $string = "$attr->{PUBLIC_KEY};$attr->{DATE_FROM};$attr->{DATE_TO};$attr->{REQUEST_ID}";
  my $signature = Digest::SHA::hmac_sha256_hex($string, $private_key);

  return $signature;
}

#**********************************************************
=head2 periodic()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub periodic {
  my $self = shift;
  my ($attr) = @_;

  my $statements = $self->get_statements({
    DATE_FROM => $attr->{DATE_FROM} || 0,
    DATE_TO   => $attr->{DATE_TO}   || 0,
    DEBUG     => $attr->{DEBUG}  || 0,
  });

  print "Paysys system $conf_name\n";

  my $not_success_statements_reports = "|id\t\t|EDRPOU\t\t|RS\t\t|\n";
  my $not_success_statements = 0;
  if($statements){
    # DebitState - ЕДРПОУ  - кастомное поле 1
    # DebitCode - расчетный счет - кастомное поле 2
    # Prpose - вытягивать 7 цифр
    print "Start provide statements\n";
    foreach my $statement (@$statements){
      print "----- $statement->{id} -----\n";
      delete $statement->{SourceName};
      delete $statement->{TargetName};
      #        use Encode;
      #        Encode::_utf8_off($statement->{Purpose});
      #        Encode::_utf8_off($statement->{ActionName});
      #        Encode::_utf8_off($statement->{DebitName});
      #        $statement->{Purpose} = convert($statement->{Purpose}, {utf82win => 1});
      #        $statement->{ActionName} = convert($statement->{ActionName}, {utf82win => 1});
      #        $statement->{DebitName} = convert($statement->{DebitName}, {utf82win => 1});
      $statement->{Purpose}    =_utf8_encode($statement->{Purpose});
      $statement->{CreditName} =_utf8_encode($statement->{CreditName});
      $statement->{DebitName}  =_utf8_encode($statement->{DebitName});
      $statement->{ActionName} =_utf8_encode($statement->{ActionName});
      my $edrpou_search_result = '';
      my $user_info            = '';
      ($edrpou_search_result, $user_info) = $self->user_search_by_edrpou($statement->{DebitState}, {CHECK_FIELD => '_EGRPOU'});
      print qq{$edrpou_search_result\n\n};
      if($edrpou_search_result == 0){
        my ($paysys_status) = $self->proccess('_EGRPOU', $user_info, $statement);

        print "Paysys status by EDRPOU - $paysys_status\n";
        if($paysys_status == 0 || $paysys_status == 13){
          next;
        }
      }
      elsif($edrpou_search_result == 3){
        my $paysys_status = 99;
        foreach my $u (@$user_info){
          if($u->{_SHCHET} && $u->{_SHCHET} eq $statement->{DebitCode}){
            ($paysys_status) = $self->proccess('_EDRPOU', $u, $statement);

            print "Paysys status by EDRPOU - $paysys_status\n";
          }
        }
        if($paysys_status == 0 || $paysys_status == 13){
          next;
        }
      }

      my $rs_search_result = '';
      ($rs_search_result, $user_info) = $self->user_search_by_rs($statement->{DebitCode}, {CHECK_FIELD => '_SHCHET'});
      if($rs_search_result == 0) {
        my ($paysys_status) = $self->proccess('_SHCHET', $user_info, $statement);

        print "Paysys status by RS - $paysys_status\n";
        if($paysys_status == 0 || $paysys_status == 13){
          next;
        }
      }

      my $bill_search_result = '';
      my ($bill) = $statement->{Purpose} =~ /^(\d{6,6})\D/g;
      if(!$bill){
        ($bill) = $statement->{Purpose} =~ /\D(\d{6})\D/g;
        if(!$bill){
          ($bill) = $statement->{Purpose} =~ /(\d{6})$/g;
        }
      }

      ($bill_search_result, $user_info) = $self->user_search_by_bill($bill, {CHECK_FIELD => '_PIN_ABS'});
      if ($bill_search_result == 0) {
        my ($paysys_status) = $self->proccess('_PIN_ABS', $user_info, $statement);

        print "Paysys status by bill - $paysys_status\n";
        if($paysys_status == 0 || $paysys_status == 13){
          next;
        }
      }

      $not_success_statements++;
      $not_success_statements_reports .= "|$statement->{id}\t|$statement->{DebitState}\t|$statement->{DebitCode}\t|$statement->{Purpose}\n";
    }

    my $mail_from = $self->{conf}{"PAYSYS_" . $conf_name . "_MAIL_FROM"};
    my $mail_to =  $self->{conf}{"PAYSYS_" . $conf_name . "_MAIL_TO"};
    if ($not_success_statements > 0) {
      print $not_success_statements_reports;
      if ($self->{conf}{"PAYSYS_" . $conf_name . "_MAIL_FROM"} && $self->{conf}{"PAYSYS_" . $conf_name . "_MAIL_TO"} && $attr->{SEND_EMAIL})  {
        sendmail("$mail_from", "$mail_to", "Concord fail payments for PaySystem: $conf_name", "<pre>$not_success_statements_reports</pre>", "$self->{conf}{MAIL_CHARSET}", "2 (High)", { CONTENT_TYPE => 'text/html' });
      }
    }
  }
}

1;
