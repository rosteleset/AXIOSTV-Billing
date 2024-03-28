=head1 Yandex Money
  New module for Yandex Money payment system

  Date: 18.03.2019
=cut

package Paysys::systems::Yandex_Money;
use strict;
use warnings FATAL => 'all';

use AXbills::Fetcher qw/web_request/;
use AXbills::Base qw/_bp load_pmodule urlencode/;

our $PAYSYSTEM_NAME = 'YMoney';
our $PAYSYSTEM_SHORT_NAME = 'YM';
our $PAYSYSTEM_ID = 135;

our $PAYSYSTEM_VERSION = '7.00';

our %PAYSYSTEM_CONF = (
  PAYSYS_YANDEX_ACCOUNT     => '',
  PAYSYS_YANDEX_SECRET      => '',
  PAYSYS_YANDEX_ACCOUNT_KEY => '',
);

my ($html, $json);
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

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 get_settings() - return hash of settings

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
=head2 user_portal()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub user_portal {
  my $self = shift;
  my ($user, $attr) = @_;

  my $success_url = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$attr->{index}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}&TRANSACTION_ID=$PAYSYSTEM_SHORT_NAME:$attr->{OPERATION_ID}";

  if($user->{GID}){
    $self->account_gid_split($user->{GID});
  }

  return $html->tpl_show(
    main::_include('paysys_yandex_money_add', 'Paysys'),
    {
      %{$attr},
      ACCOUNT_KEY => $user->{$self->{conf}{PAYSYS_YANDEX_ACCOUNT_KEY}},
      UID         => $user->{UID},
      ACCOUNT     => $self->{conf}{PAYSYS_YANDEX_ACCOUNT},
      SUCCESS_URL => $success_url,
    },
    { OUTPUT2RETURN => 0 }
  );
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
  my ($FORM) = @_;

  my $info = '';
  foreach my $k (sort keys %{ $FORM }) {
    if ($k eq '__BUFFER') {
      next;
    }

    $info .= "$k, $FORM->{$k}\n";
  }

  if($self->{conf}{PAYSYS_YANDEX_PORTAL_COMMISSION}) {
    $FORM->{withdraw_amount} = $FORM->{amount};
  }

  my ($status_code) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
    CHECK_FIELD       => 'UID',
    USER_ID           => $FORM->{label},
    SUM               => $FORM->{withdraw_amount},
    EXT_ID            => $FORM->{operation_id},
    DATA              => $FORM,
    DATE              => "$main::DATE $main::TIME",
    MK_LOG            => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => $FORM->{payment_describe} || "Платёж через Яндекс-деньги",
  });

  if($status_code == 0){
    print "Content-Type: text/html\n\n";
    main::mk_log("Success!!!!!\n$info\n", {PAYSYS_ID => "YandexMoney"});
  }
  else{
    print "Content-Type: text/html\n\n";
    main::mk_log("Error!!!!!\n$info\n", {PAYSYS_ID => "YandexMoney"});
  }
}

#**********************************************************
=head2 ()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub account_gid_split {
  my $self = shift;
  my ($gid) = @_;

  if ($self->{conf}{'PAYSYS_YANDEX_ACCOUNT_'.$gid}) {
    $self->{conf}{PAYSYS_YANDEX_ACCOUNT}=$self->{conf}{'PAYSYS_YANDEX_ACCOUNT_'.$gid};
  }

  if ($self->{conf}{'PAYSYS_YANDEX_ACCOUNT_KEY_'.$gid}) {
    $self->{conf}{PAYSYS_YANDEX_ACCOUNT_KEY}=$self->{conf}{'PAYSYS_YANDEX_ACCOUNT_KEY_'.$gid};
  }
}

1;
