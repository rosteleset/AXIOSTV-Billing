=head1 NAME

  Msgs delivery


 Arguments:
  CUSTOM_DELIVERY=message_file
  ADDRESS_LIST=address_list
  SLEEP= Sleep after message send
  LOGIN=
  UID=

=head1  EXAMPLES

    billd msgs_delivery CUSTOM_DELIVERY=message_file ADDRESS_LIST=address_list

=cut

use strict;
use warnings;
use AXbills::Base qw(sendmail in_array);
use AXbills::Sender::Core;
use Msgs;
use Users;

our (
  $debug,
  %conf,
  $Admin,
  $var_dir,
  $db,
  $argv,
  %LIST_PARAMS,
  %lang
);

my $Sender = AXbills::Sender::Core->new(
  $db,
  $Admin,
  \%conf
);

my $Log = Log->new($db, $Admin);
my %list_params = %LIST_PARAMS;
our $html = AXbills::HTML->new({ CONF => \%conf });
%LIST_PARAMS = %list_params;

if ($debug > 2) {
  $Log->{PRINT} = 1;
}
else {
  $Log->{LOG_FILE} = $var_dir . '/log/msgs_delivery.log';
}

if ($argv->{CUSTOM_DELIVERY}) {
  custom_delivery();
}
else {
  msgs_delivery();
}

#**********************************************************
=head2 msgs_delivery($attr) - Msgs delivery function

=cut
#**********************************************************
sub custom_delivery {

  my $text = get_content($argv->{CUSTOM_DELIVERY});

  my $addresses = '';
  if ($argv->{ADDRESS_LIST}) {
    $addresses = get_content($argv->{ADDRESS_LIST});
  }
  else {
    print "No address list ADDRESS_LIST=address_list\n";
    exit;
  }

  my $subject = '';

  if ($text =~ s/Subject: (.+)//) {
    $subject = $1;
  }

  my @address_list = split(/\n\r?/, $addresses);

  foreach my $to_address (@address_list) {
    print "$to_address // $subject \n\n $text \n" if ($debug > 3);

    $Sender->send_message({
      TO_ADDRESS  => $to_address,
      MESSAGE     => $text,
      SUBJECT     => $subject,
      SENDER_TYPE => 'Mail',
      #UID       => 1
    });
  }

  return 1;
}

#**********************************************************
=head2 msgs_delivery($attr) - Msgs delivery function

=cut
#**********************************************************
sub get_content {
  my ($filename) = shift;

  my $content = '';

  if (open(my $fh, '<', $filename)) {
    while (<$fh>) {
      $content .= $_;
    }
    close($fh);
  }
  else {
    print "Error: '$filename' $!\n";
  }

  return $content;
}


#**********************************************************
=head2 msgs_delivery($attr) - Msgs delivery function

=cut
#**********************************************************
sub msgs_delivery {
  #my ($attr) = @_;

  my $debug_output = '';
  $debug_output .= "Mdelivery\n" if ($debug > 1);

  my $send_methods = $Sender->available_types({ HASH_RETURN => 1 });

  my $Msgs_delivery = Msgs->new($db, $Admin, \%conf);
  my $SEND_DATE = $argv->{DATE} || $DATE;
  my $SEND_TIME = $TIME;
  $LIST_PARAMS{STATUS} = 0;
  $LIST_PARAMS{SEND_DATE} = "<=$SEND_DATE";
  $LIST_PARAMS{SEND_TIME} = "<=$SEND_TIME";

  $Msgs_delivery->{debug} = 1 if $debug > 6;

  my $delivery_list = $Msgs_delivery->msgs_delivery_list({ %LIST_PARAMS, COLS_NAME => 1 });

  my $users = Users->new($db, $Admin, \%conf);
  my $Internet;

  if (in_array('Internet', \@MODULES)) {
    require Internet;
    $Internet = Internet->new($db, $Admin, \%conf);
  }

  foreach my $mdelivery (@$delivery_list) {
    $Msgs_delivery->msgs_delivery_info($mdelivery->{id});

    my $send_method_id = $Msgs_delivery->{SEND_METHOD} ? $Msgs_delivery->{SEND_METHOD} : 0;

    $LIST_PARAMS{PAGE_ROWS} = 1000000;
    $LIST_PARAMS{MDELIVERY_ID} = $mdelivery->{id};

    my $attachments = $Msgs_delivery->attachments_list({
      FILENAME     => '_SHOW',
      CONTENT_TYPE => '_SHOW',
      CONTENT_SIZE => '_SHOW',
      CONTENT      => '_SHOW',
      DELIVERY_ID  => $mdelivery->{id},
      COLS_NAME    => 1
    });

    my @ATTACHMENTS = ();
    if ($Msgs_delivery->{TOTAL} > 0) {
      foreach my $attachment (@{$attachments}) {
        push @ATTACHMENTS, {
          ATTACHMENT_ID => $attachment->{id},
          FILENAME      => $attachment->{filename},
          CONTENT_TYPE  => $attachment->{content_type},
          FILESIZE      => $attachment->{content_size},
          CONTENT       => $attachment->{content}
        };
      }
    }

    my $user_list = $Msgs_delivery->delivery_user_list({
      %LIST_PARAMS,
      PASSWORD  => '_SHOW',
      STATUS    => 0,
      COLS_NAME => 1
    });

    foreach my $u (@$user_list) {
      $Msgs_delivery->{SENDER} = ($Msgs_delivery->{SENDER}) ? $Msgs_delivery->{SENDER} : $conf{ADMIN_MAIL};

      $Log->log_print('LOG_DEBUG', $u->{uid}, "Delivery: $mdelivery->{id} Send method: $send_methods->{$send_method_id} ($send_method_id) UID: $u->{uid}");

      $users->info($u->{uid});
      my $user_pi = $users->pi({ UID => $u->{uid} });
      my $internet_info = in_array('Internet', \@MODULES) ? $Internet->user_info($u->{uid}) : {};
      $internet_info->{MONTH_FEE} = $internet_info->{MONTH_ABON};
      $internet_info->{DAY_FEE} = $internet_info->{DAY_ABON};

      if ($internet_info->{MONTH_FEE} && $internet_info->{PERSONAL_TP}) {
        $internet_info->{MONTH_FEE} = $internet_info->{PERSONAL_TP};
        $internet_info->{DAY_FEE} = 0;
      }

      if ($internet_info->{REDUCTION_FEE} && $users->{REDUCTION}) {
        $internet_info->{MONTH_FEE} = $internet_info->{MONTH_FEE} - (($internet_info->{MONTH_FEE} / 100) * $users->{REDUCTION}) if $internet_info->{MONTH_FEE};
        $internet_info->{DAY_FEE} = $internet_info->{DAY_FEE} - (($internet_info->{DAY_FEE} / 100) * $users->{REDUCTION}) if $internet_info->{DAY_FEE};
      }

      my $message = $html->tpl_show($Msgs_delivery->{TEXT}, {
        %$user_pi,
        %$internet_info,
        USER_LOGIN => $u->{login},
        PASSWORD   => $u->{password}
      }, { OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });

      if ($debug < 6) {
        if (!$Msgs_delivery->{SEND_METHOD}) {
          $Msgs_delivery->message_add({
            UID        => $user_pi->{UID},
            STATE      => 6,
            ADMIN_READ => "$DATE $TIME",
            SUBJECT    => $Msgs_delivery->{SUBJECT},
            PRIORITY   => $Msgs_delivery->{PRIORITY},
            MESSAGE    => $Msgs_delivery->{TEXT},
          });
        }
        else {
          my $status = $Sender->send_message({
            SENDER      => $Msgs_delivery->{SENDER},
            MESSAGE     => $message,
            SUBJECT     => $Msgs_delivery->{SUBJECT},
            SENDER_TYPE => $Msgs_delivery->{SEND_METHOD} || 0,
            ATTACHMENTS => ($#ATTACHMENTS > -1) ? \@ATTACHMENTS : undef,
            UID         => $user_pi->{UID}
          });

          $Msgs_delivery->delivery_user_list_change({
            MDELIVERY_ID => $mdelivery->{id} || '-',
            UID          => $u->{uid},
            STATUS       => $status ? 1 : 2
          });

          if ($Sender->{errno}) {
            $Log->log_print('LOG_DEBUG', $u->{uid}, "Error: $Sender->{errno} $Sender->{errstr}");
          }
        }

        if ($argv->{SLEEP}) {
          sleep int($argv->{SLEEP});
        }
      }
      elsif ($debug > 7) {
        $debug_output .= "TYPE: $Msgs_delivery->{SEND_METHOD} TO: " . "$u->{id} " . "$message\n";
      }
    }

    if (!$LIST_PARAMS{LOGIN}) {
      $Msgs_delivery->msgs_delivery_change({
        ID          => $mdelivery->{id} || '-',
        SENDED_DATE => "$DATE $TIME",
        STATUS      => 2
      });
    }
  }

  $DEBUG .= $debug_output;

  return $debug_output;
}

1

