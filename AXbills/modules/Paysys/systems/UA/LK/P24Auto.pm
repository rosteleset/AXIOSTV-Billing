=head1 P24 Auto Client
  New module for P24 Auto Client

  Documentaion: https://docs.google.com/document/d/e/2PACX-1vS8rx2WKg69o6JvG5L4AhSXcU6vxXcJph6WK84qJcAYDBvsNYEob57jDMQhbosjc9gRS5bOTqTXf0vb/pub

  Date: 05.03.2019
  REVISION:19.06.2020

  Version: 7.04
=cut

use strict;
use warnings;

use AXbills::Base qw(_bp load_pmodule encode_base64);
use AXbills::Misc qw();
use AXbills::Fetcher qw(web_request);
# use Encode;
require Paysys::Paysys_Base;

package Paysys::systems::P24Auto;

our $PAYSYSTEM_NAME = 'P24Auto';
our $PAYSYSTEM_SHORT_NAME = 'P24A';
our $PAYSYSTEM_ID = 124;

our $PAYSYSTEM_VERSION = '7.04';

our %PAYSYSTEM_CONF = (
  PAYSYS_P24A_ID           => '',
  PAYSYS_P24A_TOKEN        => '',
  PAYSYS_P24_API_PARSE     => '',
  PAYSYS_P24_API_AUTO_INFO => '',
);

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

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
    DEBUG => $CONF->{PAYSYS_DEBUG} || 0,
  };
  $self->{conf}{PAYSYS_P24_API_PARSE} =~ s/\\\\/\\/g;
  bless($self, $class);

  return $self;
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
  #  my ($attr) = @_;

  my @merchants = split(';', $self->{conf}{PAYSYS_P24_API_AUTO_INFO}); # list of merchants
  my $url = "https://acp.privatbank.ua/api/proxy/transactions/today"; # url for api
  my $success_payments = 0;
  my $not_success_payments = 0;
  my $already_exist_payments = 0;

  foreach my $merchant (@merchants) {
    my ($bill, $id, $token) = split(':', $merchant);

    #request for transactions list
    my $json_result = main::web_request($url, {
        #      POST    => qq[{"sessionId":"$session_id"}],
        DEBUG       => 0,
        HEADERS     => [ "Content-Type: application/json; charset=utf8", "id: $id", "token: $token" ],
        JSON_RETURN => 1,
      });

    # if there is no error
    if ($json_result->{StatementsResponse}) {
      # show error if something wrong
      if (!$json_result->{StatementsResponse}->{statements} || ref $json_result->{StatementsResponse}->{statements} ne 'ARRAY') {
        print "NOT ARRAY REF";
        return 1;
      }
    }

    #BPL_SUM - сумма платежа
    #BPL_OSND - коментарий
    #DATE_TIME_DAT_OD_TIM_P - дата время
    #AUT_MY_NAM -
    #BPL_PR_PR - статус(r - проведена)
    #DATE_TIME_DAT_OD_TIM_P - дата

    # get payments list for this system
    my $payments_extid_list = 'P24A:*';
    use Payments;
    my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});
    my $payments_list = $Payments->list({ EXT_ID => $payments_extid_list,
      DATETIME                                   => '_SHOW',
      PAGE_ROWS                                  => 100000,
      COLS_NAME                                  => 1,
    });

    # make hash with added payments
    my %added_payments = ();
    foreach my $line (@$payments_list) {
      if ($line->{ext_id}) {
        $line->{ext_id} =~ s/$payments_extid_list://;
        $added_payments{ $line->{ext_id} } = "$line->{id}:" . "$line->{uid}:" . ($line->{login} || '') . ":$line->{datetime}";
      }
    }

    my $transactions = $json_result->{StatementsResponse}{statements}[0]{$bill};
    foreach my $transaction (@$transactions) {
      my ($tran_id) = keys %$transaction;
      my $transaction_info = $transaction->{$tran_id}; # get transaction info

      my $amount = $transaction_info->{BPL_SUM};
      my $comment = $transaction_info->{BPL_OSND};
      use Encode;
      $comment = decode_utf8($comment);
      my $status = $transaction_info->{BPL_PR_PR};
      my $date = $transaction_info->{DATE_TIME_DAT_OD_TIM_P};
      $date =~ s/\./\-/g;
      my ($user_identifier) = $comment =~ /$self->{conf}{PAYSYS_P24_API_PARSE}/;

      if (exists $added_payments{$tran_id}) {
        print "Payment $tran_id exist\n";
        $already_exist_payments++;
        next;
      }
      else {
        if ($self->{conf}{PAYSYS_P24A_FILTER} && $comment =~ /$self->{conf}{PAYSYS_P24A_FILTER}/) {
          next;
        }

        if ($status ne "r") {
          print "Payment $tran_id not success in private";
          $not_success_payments++;
          next;
        };

        if (!$user_identifier || $user_identifier eq "") {
          print "Payment $tran_id. User identifier is empty\n";
          $not_success_payments++;
          next;
        };

        # if payments is new - add it to base
        my $payment_status = $self->make_payment({
          TRANSACTION_ID => $tran_id,
          ACCOUNT_KEY    => $user_identifier,
          SUM            => $amount,
          #                      DATE           => $date || $DATE,
          COMMENT        => $comment || '',
        });

        print "Payment $tran_id. User $user_identifier. Payment status $payment_status\n";
        $success_payments++;
      }
    }
  }

  print "Sucecss payments - $success_payments\n";
  print "Not sucecss payments - $not_success_payments\n";
  print "Already exist payments - $already_exist_payments\n";
}

#**********************************************************
=head2 make_payment() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub make_payment {
  my $self = shift;
  my ($attr) = @_;

  main::mk_log("Add payments for user", { PAYSYS_ID => 'P24Auto', });

  my $status = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
    CHECK_FIELD       => $self->{CONF}->{PAYSYS_P24_API_ACCOUNT_KEY} || 'UID',
    USER_ID           => $attr->{ACCOUNT_KEY},
    SUM               => $attr->{SUM},
    EXT_ID            => $attr->{TRANSACTION_ID},
    DATA              => $attr,
    DATE              => $attr->{DATE},
    # CURRENCY_ISO      => $conf{PAYSYS_OSMP_CURRENCY},
    MK_LOG            => 1,
    DEBUG             => 1,
    PAYMENT_DESCRIBE  => $attr->{COMMENT} || 'P24 Api import statements',
  });
  main::mk_log("Status - $status", { PAYSYS_ID => 'P24Auto', });
  return $status;
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
=head2 report()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub report {
  my $self = shift;

  my ($attr) = @_;
  my $html   = $attr->{HTML};
  my $lang   = $attr->{LANG};
  my $FORM   = $attr->{FORM};
  my $index  = $attr->{INDEX};

  if ($FORM->{IMPORT} && $FORM->{IDS}) {
    my @ids = split(', ', $FORM->{IDS});
    my $success_payments = 0;

    foreach my $transaction_id (@ids) {
      my $status = $self->make_payment({
        TRANSACTION_ID => $transaction_id,
        ACCOUNT_KEY    => $FORM->{"USER_$transaction_id"},
        SUM            => $FORM->{"SUM_$transaction_id"},
        DATE           => $main::DATE || $FORM->{"DATE_$transaction_id"},
        COMMENT        => $FORM->{"COMMENT_$transaction_id"} || '',
      });

      $success_payments++ if ($status == 0);
    }
  }

  my $payments_extid_list = 'P24A:*';
  my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});
  my $payments_list = $Payments->list({
    EXT_ID      => $payments_extid_list,
    DATETIME    => '_SHOW',
    PAGE_ROWS   => 100000,
    COLS_NAME   => 1,
  });

  my %added_payments = ();
  foreach my $line (@$payments_list) {
    if ($line->{ext_id}) {
      $line->{ext_id} =~ s/$payments_extid_list://;
      $added_payments{ $line->{ext_id} } = "$line->{id}:" . "$line->{uid}:" . ($line->{login} || '') . ":$line->{datetime}";
    }
  }
  my @all_merchants = split(';', $self->{conf}{PAYSYS_P24_API_AUTO_INFO});
  my @merchants = split(';', ($FORM->{MERCHANT} || $self->{conf}{PAYSYS_P24_API_AUTO_INFO})); # list of merchants
  my $url = "https://acp.privatbank.ua/api/proxy/transactions/today"; # url for api
  my $p24_api_table = $html->table({
    width   => '100%',
    caption => "P24 Application",
    title   =>  [ 'ID', $lang->{USER}, "$lang->{SUM}", "$lang->{TRANSACTION}", $lang->{COMMENTS}, $lang->{DATE}, $lang->{STATUS} ],
    ID      => 'P24_API'
  });

  my $transactions;
  foreach my $merchant (@merchants) {
    my ($bill, $id, $token) = split(':', $merchant);
    my $merchant_add = '';
    if($FORM->{MERCHANT}){
      $merchant_add = "&acc=$bill";
    }

    if ($FORM->{FROM_DATE_TO_DATE}) {
      $FORM->{FROM_DATE} =~ /(\d+)-(\d+)-(\d+)/;
      my $start_date = "$3-$2-$1";
      $FORM->{TO_DATE} =~ /(\d+)-(\d+)-(\d+)/;
      my $end_date = "$3-$2-$1";
      $url = "https://acp.privatbank.ua/api/proxy/transactions?startDate=$start_date&endDate=$end_date" . $merchant_add;
    }

    #request for transactions list
    my $json_result = main::web_request($url, {
        DEBUG       => 0,
        HEADERS     => [ "Content-Type: application/json; charset=utf8", "id: $id", "token: $token" ],
        JSON_RETURN => 1,
      });

    # if there is no error
    if ($json_result->{StatementsResponse}) {
      # show error if something wrong
      if (!$json_result->{StatementsResponse}->{statements} || ref $json_result->{StatementsResponse}->{statements} ne 'ARRAY') {
        print "NOT ARRAY REF";
        return 1;
      }
    }

    $transactions = $json_result->{StatementsResponse}{statements}[0]{$bill};

    if($FORM->{MERCHANT}){
      $transactions = $json_result->{StatementsResponse}{statements};
    }

    foreach (@$transactions) {
      my ($tran_id) = keys %$_;
      my $transaction_info = $_->{$tran_id}; # get transaction info

      # my $status = $transaction_info->{BPL_PR_PR};
      my $amount = $transaction_info->{BPL_SUM};
      my $comment = $transaction_info->{BPL_OSND};
      # $comment = decode_utf8($comment);
      my $transaction_type = $transaction_info->{TRANTYPE};
      my $date = $transaction_info->{DATE_TIME_DAT_OD_TIM_P};
      $date =~ s/\./\-/g;

      my ($user_identifier) = $comment =~ /$self->{conf}{PAYSYS_P24_API_PARSE}/;
      my $user_input = '';
      my $checkbox_input = '';

      if ($user_identifier) {
        $p24_api_table->{rowcolor} = 'table-success';
        $user_input = $html->button($user_identifier, "index=15&UID=" . $user_identifier,
          { class => 'btn btn-xs btn-primary' });
      }
      else {
        if ($transaction_type eq 'D') {
          $p24_api_table->{rowcolor} = 'table-info';
        }
        elsif (exists $added_payments{$tran_id}) {
          $p24_api_table->{rowcolor} = 'table-success';
          my ($payment_id, $uid, $login, undef) = split(':', $added_payments{$tran_id});
          $user_input = $html->button("$lang->{LOGIN}: $login", "index=15&UID=" . $uid,
            { class => 'btn btn-xs btn-success' });
          $tran_id = $html->button("$lang->{ADDED}:$tran_id", "index=2&ID=$payment_id")
        }
        elsif($comment =~ /Liqpay\:/){
          my ($liqpay_transaction) = $comment =~ /(Liqpay:\d+)/;
          my ($payment_id, $check_status) = main::paysys_pay_check({
            TRANSACTION_ID => $liqpay_transaction,
          });
          if($payment_id){
            if($check_status == 2){
              $p24_api_table->{rowcolor} = 'table-success';
              $tran_id = $html->button("$lang->{ADDED}:$payment_id", "index=2&ID=$payment_id");
              $user_input = '';
            }
          }
          else{
            $p24_api_table->{rowcolor} = 'table-danger';
          }
        }
        elsif($comment =~ /ID\:/){
          my ($p24_transaction) = $comment =~ /(ID: \d+)/;
          my ($payment_id, $check_status) = main::paysys_pay_check({
            TRANSACTION_ID => $p24_transaction,
          });
          if($payment_id){
            if($check_status == 2){
              $p24_api_table->{rowcolor} = 'table-success';
              $tran_id = $html->button("$lang->{ADDED}:$payment_id", "index=2&ID=$payment_id");
              $user_input = '';
            }
          }
          else{
            $p24_api_table->{rowcolor} = 'table-danger';
          }
        }
        else {
          $p24_api_table->{rowcolor} = 'table-danger';
          $checkbox_input = $html->form_input("IDS", $tran_id, { TYPE => 'checkbox' });
          $user_input .= $html->form_input("USER_$tran_id", $user_identifier, { TYPE => 'text' });
          $user_input .= $html->form_input("SUM_$tran_id", $amount, { TYPE => 'hidden' });
          $user_input .= $html->form_input("DATE_$tran_id", $date, { TYPE => 'hidden' });
          $user_input .= $html->form_input("COMMENT_$tran_id", $comment, { TYPE => 'hidden' });
        }
      }

      $p24_api_table->addrow($checkbox_input, $user_input, $amount, $tran_id, $comment, $date, '');
    }
  }

  my $date_range_picker = $html->form_daterangepicker({
    NAME      => 'FROM_DATE/TO_DATE',
    FORM_NAME => 'report_panel',
    VALUE     => $attr->{DATE} || $FORM->{'FROM_DATE_TO_DATE'},
    WITH_TIME => $attr->{TIME_FORM} || 0
  });

  my $merchant_select = $html->form_select('MERCHANT',
    {
      SELECTED => $FORM->{MERCHANT}|| q{},
      SEL_ARRAY => \@all_merchants,
      NO_ID    => 1,
      SEL_OPTIONS => { '0' => $lang->{ALL} }
    });

  my $show_input = $html->form_input('show', "$lang->{SHOW}", { TYPE => 'submit', OUTPUT2RETURN => 1 });

  print $html->form_main({
      CONTENT => $date_range_picker . 'Merchant:' . $merchant_select . $show_input . $p24_api_table->show(),
      HIDDEN  => {
        index       => "$index",
        IMPORT_TYPE => $FORM->{IMPORT_TYPE},
        SYSTEM_ID   => $FORM->{SYSTEM_ID},
      },
      SUBMIT  => { IMPORT => "$lang->{IMPORT}" },
      NAME    => 'FORM_P24_AUTO_FILTER'
    });

}

1;