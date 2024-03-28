package Docs::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my AXbills::HTML $html;
my $lang;
my $Docs;

use AXbills::Base qw/days_in_month in_array/;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Docs;
  Docs->import();
  $Docs = Docs->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 docs_payments_maked($attr) - Cross module calls

  Arguments:
    $attr
      CHANGE_CREDIT


=cut
#**********************************************************
sub docs_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  return 0 if $attr->{CHANGE_CREDIT};

  my $form = $attr->{FORM} || {};

  if (!$form->{SUM} || $form->{SUM} == 0) {
    if ($form->{APPLY_TO_INVOICE} || $form->{INVOICE_ID}) {
      $html->message('err', "$lang->{DOCS}:$lang->{ERROR}", $lang->{ERR_WRONG_SUM}, { ID => 561 });
    }
    return 0;
  }

  if ($form->{APPLY_TO_INVOICE} || ($form->{INVOICE_ID} && $form->{INVOICE_ID} ne 'create')) {
    delete($form->{INVOICE_ID}) if (defined($form->{INVOICE_ID}) && $form->{INVOICE_ID} == 0);

    my $list = $Docs->invoices_list({
      UNPAIMENT => ($form->{INVOICE_ID}) ? undef : 1,
      ID        => $form->{INVOICE_ID},
      UID       => $form->{UID},
      PAGE_ROWS => 50,
      COLS_NAME => 1,
      SORT      => 1,
      DESC      => 'ASC'
    });

    my $total_payment_sum = $form->{SUM};
    my $payment_sum = $form->{SUM} || 0;

    if ($Docs->{TOTAL} > 0) {
      foreach my $doc (@{$list}) {
        if ($doc->{payment_sum} && $doc->{total_sum} < $doc->{payment_sum}) {
          print " //     my $payment_sum       = $form->{SUM}; // $doc->{total_sum} < $doc->{payment_sum} ";
          next;
        }

        if ($form->{SUM} > $doc->{total_sum} - ($doc->{payment_sum} || 0)) {
          $payment_sum = $doc->{total_sum} - ($doc->{payment_sum} || 0);

          return 1 if $attr->{USER_INFO} && $attr->{USER_INFO}->{COMPANY_ID};

          print "Pre link: ADD_SUM: $form->{SUM} total_sum: $doc->{total_sum} payment_sum: " .
            ($doc->{payment_sum} || 0) . " Doc id: $doc->{id}\n";
        }

        $Docs->invoices2payments({
          PAYMENT_ID => $attr->{PAYMENT_ID},
          INVOICE_ID => $doc->{id},
          SUM        => $payment_sum
        });

        if (!::_error_show($Docs, { MESSAGE => $lang->{INVOICE}, ID => 562 })
          && !$CONF->{PAYMENTS_NOT_CHECK_INVOICE_SUM} && $Docs->{TOTAL_SUM} != $form->{SUM}) {
          $html->message('warn', $lang->{ERROR}, "$lang->{PAYMENTS_NOT_EQUAL_DOC} \n"
            . "$lang->{INVOICE} $lang->{SUM}: $Docs->{TOTAL_SUM} \n"
            . "$lang->{PAYMENTS} $lang->{SUM}: $payment_sum", { ID => 563 });
        }

        last if $total_payment_sum - $payment_sum == 0;
      }
    }
    else {
      print "$lang->{INVOICE} $lang->{NOT_EXIST} (TOTAL: $Docs->{TOTAL})";
    }
  }

  if ($form->{CREATE_RECEIPT}) {
    ::load_module('Docs');
    ::docs_receipt_add({
      DATE       => $form->{DATE} || $main::DATE,
      CUSTOMER   => '-',
      PHONE      => '',
      UID        => $form->{UID},
      ORDER      => $form->{DESCRIBE} || '-',
      SUM        => $form->{SUM},
      create     => 1,
      PAYMENT_ID => $attr->{PAYMENT_ID},
      SEND_EMAIL => $form->{SEND_EMAIL}
    });
  }
}

#**********************************************************
=head2 docs_pre_payment($attr)

=cut
#**********************************************************
sub docs_pre_payment{
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};

  if ($form->{INVOICE_ID} && $form->{INVOICE_ID} eq 'create') {
    delete $form->{INVOICE_ID};
    ::load_module('Docs');
    ::docs_invoice({
      INVOICE_DATA => {
        INCLUDE_DEPOSIT         => 1,
        create                  => 1,
        CUSTOMER                => '-',
        ORDER                   => $form->{DESCRIBE},
        $main::LIST_PARAMS{UID} => $form->{UID},
        SUM                     => $form->{SUM}
      }
    });
  }
  elsif ($form->{INVOICE_ID}) {
    $Docs->invoice_info($form->{INVOICE_ID});
    if ($Docs->{TOTAL} == 0) {
      $form->{INVOICE_SUM} = 0;
    }
    else {
      $form->{INVOICE_SUM} = $Docs->{TOTAL_SUM};
    }
  }

  return 1;
}

1;