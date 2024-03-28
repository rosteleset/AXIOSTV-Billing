package Extreceipt::Base;

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';

our $VERSION = 0.01;

our @EXPORT = qw(
  receipt_init
);

our @EXPORT_OK = qw(
  receipt_init
);

my ($admin, $CONF, $db);
my AXbills::HTML $html;
my $lang;
my $Extreceipt;

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

  use Extreceipt::db::Extreceipt;
  $Extreceipt = Extreceipt->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 receipt_init($attr)

  Arguments:
    $Receipts
    $attr
      API_ID: number     - API ID
      AID: number        - Admin ID
      API_NAME: string   - Api name - example: Checkbox
      DEBUG: number      - level of DEBUG
      SKIP_INIT: number  - skip init if needs public info

  Return
    $Receipt_apies

=cut
#**********************************************************
sub receipt_init {
  my $Receipt = shift;
  my ($attr) = @_;

  my $api_list = $Receipt->api_list({ API_ID => $attr->{API_ID} });
  my $debug = $attr->{DEBUG} || 0;
  my $Receipt_api = ();

  foreach my $api (@$api_list) {
    my $api_name = $api->{api_name};
    my $api_id = $api->{api_id};
    if ($attr->{API_NAME} && $attr->{API_NAME} ne $api_name) {
      next;
    }

    eval {
      require "Extreceipt/API/$api_name.pm";
    };

    if (!$@) {
      $Receipt_api->{$api_id} = $api_name->new($Receipt->{conf}, $api);
      $Receipt_api->{$api_id}->{debug} = $debug if ($debug);
      $Receipt_api->{$api_id}->init() if (!$attr->{SKIP_INIT});
    }
    else {
      print $@;
      $Receipt_api->{$api_id} = ();
    }
  }

  return $Receipt_api;
}

#**********************************************************
=head2 extreceipt_payments_maked($attr)

=cut
#**********************************************************
sub extreceipt_payments_maked {
  shift;
  my ($attr) = @_;

  ::load_module('Extreceipt');

  my $list = $Extreceipt->info($attr->{PAYMENT_ID});
  if (scalar @$list > 0) {
    return 0;
  }

  ::_extreceipt_new();
  ::_extreceipt_send($attr->{PAYMENT_ID});

  return 1;
}

1;
