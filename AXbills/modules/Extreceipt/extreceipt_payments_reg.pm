=head1 NAME

  Extreceipt billd plugin

=head1 ARGUMENTS

  PAYMENT_ID
  START       - Start payments ID
  CHECK
  FROM_DATE
  TO_DATE
  RESEND
  CANCEL
  PAGE_ROWS   - List size of send documents
  SLEEP       - Sleep in second after each send
  API_NAME    - Use only one API
  RENEW_SHIFT - Renew shifts
  OPEN_SHIFT  - open shifts
  CLOSE_SHIFT - close shifts

  LOGIN - coming soon
  UID

=cut

use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $Admin,
  $db,
  $argv,
  $DATE,
  $TIME,
);

use AXbills::Base qw(show_hash);
use Conf;
use Extreceipt::db::Extreceipt;
use Extreceipt::Base;

my $debug = 0;

my $Config = Conf->new($db, $Admin, \%conf);
my $Receipt = Extreceipt->new($db, $Admin, \%conf);

if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
  $Receipt->{debug} = 1 if ($debug > 4);
}
my $Receipt_api = receipt_init($Receipt, {
  API_NAME => $argv->{API_NAME},
  DEBUG    => ($debug > 2) ? 1 : 0
});

my %params = ( PAGE_ROWS => 10999 );

if($argv->{PAYMENT_ID}) {
  $params{PAYMENT_ID}=$argv->{PAYMENT_ID};
}
elsif($argv->{FROM_DATE} || $argv->{TO_DATE}) {
  $params{FROM_DATE} = $argv->{FROM_DATE} if ($argv->{FROM_DATE});
  $params{TO_DATE} = $argv->{TO_DATE} if ($argv->{TO_DATE});
}

if ($argv->{LOGIN}) {
  $params{LOGIN}=$argv->{LOGIN};
}

if ($argv->{UID}) {
  $params{UID}=$argv->{UID};
}

if ($argv->{PAGE_ROWS}) {
  $params{PAGE_ROWS} = $argv->{PAGE_ROWS};
}

if ($argv->{CANCEL}) {
  cancel_payments($argv->{CANCEL});
}
elsif ($argv->{CHECK}) {
  check_receipts();
}
elsif ($argv->{RESEND}) {
  resend_errors();
}
elsif ($argv->{RENEW_SHIFT}) {
  renew_shifts({close => 1, open => 1});
}
elsif ($argv->{OPEN_SHIFT}) {
  renew_shifts({open => 1});
}
elsif ($argv->{CLOSE_SHIFT}) {
  renew_shifts({close => 1});
}
else {
  check_receipts();
  check_payments();
  send_payments();
  resend_errors();
}

#**********************************************************
=head2 check_payments()

  Checks whether new payments appear in the payments table.
  If there are new payments, they are entered into the Receipts_main table with the status 0.

=cut
#**********************************************************
sub check_payments {
  my $start_id = $argv->{START} || $conf{EXTRECEIPT_LAST_ID} || 1;
  $Receipt->get_new_payments($start_id);

  if ($Receipt->{error}) {
    print "ERROR: $Receipt->{error} $Receipt->{errstr}\n";
    return 0;
  }

  $Config->config_add({
    PARAM   => "EXTRECEIPT_LAST_ID",
    VALUE   => $Receipt->{LAST_ID},
    REPLACE => 1
  });

  return 1;
}

#**********************************************************
=head2 send_payments() - Sends all payments with status 0, status changes to 1.

=cut
#**********************************************************
sub send_payments {
  my $list = $Receipt->list({
    STATUS         => 0,
    PAYMENT_METHOD => '_SHOW',
    %params
  });

  foreach my $line (@$list) {
    next if (!$line->{api_id});
    next if (!$Receipt_api->{$line->{api_id}});
    $line->{phone} =~ s/[^0-9\+]//g if(defined($line->{phone}));
    if (!$line->{mail} && !$line->{phone}) {
      $line->{mail} = $conf{EXTRECEIPTS_FAIL_EMAIL} || ($line->{uid} . '@myisp.ru');
    }
    ($line->{check_header}, $line->{check_desc}, $line->{check_footer}) = $conf{EXTRECEIPTS_EXT_RECEIPT_INFO} ?
      _extreceipt_receipt_ext_info($line) : ('', '', '');
    my $command_id = $Receipt_api->{$line->{api_id}}->payment_register($line);

    if ($command_id) {
      if (ref $command_id eq 'HASH') {
        if ($debug) {
          print "Failed to send reason $command_id->{ERROR}";
        }
      }
      else {
        $Receipt->change({
          PAYMENTS_ID => $line->{payments_id},
          COMMAND_ID  => $command_id,
          STATUS      => 1
        });
        if ($debug) {
          print "Success to send $line->{payments_id}/$command_id";
        }
      }
    }

    if ($argv->{SLEEP}) {
      sleep int($argv->{SLEEP});
    }
  }
  return 1;
}

#**********************************************************
=head2 cancel_payments($id) -  Cancel payment, set status 3

=cut
#**********************************************************
sub cancel_payments {
  my ($id) = @_;
  my $info = $Receipt->info($id);
  return print("You have deleted the KKT or API, therefore actions with this check are not available\n")
    if (!defined($info->[0]{api_id}));
  return 1 if (!$Receipt_api->{$info->[0]{api_id}});
  ($info->[0]{check_header}, $info->[0]{check_desc}, $info->[0]{check_footer}) = $conf{EXTRECEIPTS_EXT_RECEIPT_INFO} ?
    _extreceipt_receipt_ext_info($info->[0]) : ('', '', '');
  my $command_id = $Receipt_api->{$info->[0]{api_id}}->payment_cancel($info->[0]);
  if ($command_id) {
    if (ref $command_id eq 'HASH') {
      print "Failed to send reason $command_id->{ERROR}";
    }
    else {
      $Receipt->change({ PAYMENTS_ID => $id, CANCEL_ID => $command_id, STATUS => 3 });
      if ($debug) {
        print "Success to cancel $id/$command_id"
      }
    }
  }
  else {
    if ($debug) {
      print "Failed to cancel $id/$command_id"
    }
  }

  return 1;
}

#**********************************************************
=head2 check_receipts()
  Checks the status of previously sent payments with status 1.
??If a check is made for them, it changes the status to 2, and fills with the ID check.
=cut
#**********************************************************
sub check_receipts {
  my $list;

  if ($argv->{CHECK}) {
    $list = $Receipt->info($argv->{CHECK});
  }
  else {
    $list = $Receipt->list({
      %params,
      STATUS    => 1
    });
  }

  foreach my $line (@$list) {
    if ($debug > 7) {
      print show_hash($line);
      print "\n";
      next;
    }

    next if (!$line->{api_id});
    next if (!$Receipt_api->{$line->{api_id}});
    my $Receipt_info = $Receipt_api->{$line->{api_id}};

    my ($fdn, $fda, $date, $payments_id, $error) = $Receipt_info->get_info($line);
    $payments_id ||= $line->{payments_id};

    print "GET_INFO: $payments_id (FDN: ". ($fdn || 'N/d') ." FDA: $fda DATE: ". ($date || q{n/d}) ." PAYMENT_ID: $payments_id ERROR: $error)\n" if($debug > 1);
    if ($error) {
      if($Receipt_info->{error} && $Receipt_info->{error} == 1) {
        print "ERROR: $Receipt_info->{error} PAYMENT_ID: $payments_id ";
        if($Receipt_info->{errstr}) {
          print $Receipt_info->{errstr};
        }
        print "\n";
        next;
      }

      if ($payments_id =~ m/\-e/) {
        $payments_id =~ s/\-e//;
        $Receipt->change({
          PAYMENTS_ID => $payments_id,
          STATUS      => 5,
        });
      }
      else {
        $Receipt->change({
          PAYMENTS_ID => $payments_id,
          STATUS      => 4,
        });
      }
      next;
    }

    $payments_id =~ s/\-e//;
    $date =~ s/T/ /;
    $date =~ s/\+.*//;
    if ($fda) {
      $Receipt->change({
        PAYMENTS_ID  => $payments_id,
        FDN          => $fdn || q{},
        FDA          => $fda || q{},
        RECEIPT_DATE => $date || q{},
        STATUS       => 2,
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 resend_errors() - Resend payments with status 4, status changes to 1.


=cut
#**********************************************************
sub resend_errors {
  my $list = $Receipt->list({ STATUS => 4, %params });

  foreach my $line (@$list) {
    next if (!$Receipt_api->{$line->{api_id}});
    if (!$line->{mail} && !$line->{phone}) {
      $line->{mail} = $conf{EXTRECEIPTS_FAIL_EMAIL} || ($line->{uid} . '@myisp.ru');
    }

    print "$line->{c_phone} $line->{mail}\n" if ($debug > 1);

    $line->{payments_id} .= "-e";
    ($line->{check_header}, $line->{check_desc}, $line->[0]->{check_footer}) = $conf{EXTRECEIPTS_EXT_RECEIPT_INFO} ?
      _extreceipt_receipt_ext_info($line->[0]) : ('', '', '');
    my $command_id = $Receipt_api->{$line->{api_id}}->payment_register($line);
    if ($command_id) {
      $Receipt->change({
        PAYMENTS_ID => $line->{payments_id},
        COMMAND_ID  => $command_id,
        STATUS      => 1
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 renew_shifts() - Renew cashier shift.

=cut
#**********************************************************
sub renew_shifts {
  my ($attr) = @_;

  my $kkt_list = $Receipt->kkt_list();
  my @kkt_keys = ();
  foreach my $kkt (@{$kkt_list}) {
    if (defined($kkt->{kkt_key}) && $kkt->{kkt_key}) {
      my $key_exist = q{};
      foreach my $key (@kkt_keys) {
        next if ($key ne $kkt->{kkt_key});
        $key_exist = 1;
        last;
      }

      if ($key_exist) {
        next;
      }

      if (defined($kkt->{shift_uuid}) && $kkt->{shift_uuid} && $attr->{close}) {
        my $old_shift = $Receipt_api->{$kkt->{api_id}}->shift_close({
          kkt_key  => $kkt->{kkt_key},
          shift_id => $kkt->{shift_uuid}
        }) || q{};
        if ($debug) {
          my $msg = $old_shift ? "$old_shift didn't closed" : 'successfully closed';
          print "Shift $msg\n"
        }
      }

      if ($attr->{open}) {
        my $new_shift = $Receipt_api->{$kkt->{api_id}}->shift_open({
          kkt_key => $kkt->{kkt_key}
        }) || q{};

        if ($new_shift && $new_shift =~ /\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b/gm) {
          $Receipt->kkt_change({
            KKT_ID     => $kkt->{kkt_id},
            SHIFT_UUID => $new_shift
          });
        }
        if ($debug) {
          print "Shift ID $new_shift\n"
        }
      }

      push @kkt_keys, $kkt->{kkt_key};
    }
  }

  return 1;
}

#**********************************************************
=head2 _extreceipt_receipt_ext_info()

=cut
#**********************************************************
sub _extreceipt_receipt_ext_info {
  my ($attr) = @_;

  my $kkt_info = $Receipt->kkt_list({KKT_ID => $attr->{kkt_id}});
  my $header = $kkt_info->[0]->{check_header} || '';
  my $footer = $kkt_info->[0]->{check_footer} || '';
  my $desc = '';

  if ($kkt_info->[0]->{check_desc}) {
    my $Users = Users->new($db, $Admin, \%conf);
    my $users_pi = $Users->pi({ UID => $attr->{uid} });

    my @vars = $kkt_info->[0]->{check_desc} =~ /\&(.+?)\&/g;
    foreach my $var (@vars) {
      $kkt_info->[0]->{check_desc} =~ s/\&$var\&/($users_pi->{$var} || '')/ge;
    }
    $desc = $kkt_info->[0]->{check_desc};
  }

  return ($header, $desc, $footer);
}

1;
