package Paysys::systems::City24;
=head1 City24

  New module for City24 payment system

  Date: 25.01.2018
  Update: 20.04.2020
  Version: 8.03
=cut

use strict;
use warnings FATAL => 'all';
use parent 'main';
use AXbills::Base qw(load_pmodule _bp);
use AXbills::Fetcher;
require Paysys::Paysys_Base;
require AXbills::Templates;
use Paysys;

my $PAYSYSTEM_NAME = 'City24';
my $PAYSYSTEM_SHORT_NAME = 'C24';
my $PAYSYSTEM_ID = 85;
my $PAYSYSTEM_VERSION = '8.03';
my $DEBUG = 1;
my %PAYSYSTEM_CONF = (
  PAYSYS_CITY24_LOGIN          => '',
  PAYSYS_CITY24_PASSWORD       => '',
  PAYSYS_CITY24_ACCOUNT_KEY    => '',
  PAYSYS_CITY24_SUBPROVIDER_ID => '',
  PAYSYS_CITY24_GID_SHOW       => '',
  PAYSYS_CITY24_FAST_PAY       => '',
);

my %STATUSES = (
  '0'  => '0',
  '1'  => '5',
  '11' => '7',
  '13' => '0'
);

my ($html);
#**********************************************************
=head2 new()

  Arguments:
     -

  Returns:


  Example:

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
=head2 proccess()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  load_pmodule('XML::Simple');

  my $request_data = eval {XML::Simple::XMLin($FORM->{__BUFFER})};

  if ($@) {
    print "ERROR XML $@";
    main::mk_log("ERROR XML $@", { PAYSYS_ID => "$PAYSYSTEM_ID/$PAYSYSTEM_SHORT_NAME", REQUEST => 'Request' });
    _get_request_info($FORM);
    return 0;
  }

  if ($request_data->{command} && $request_data->{command} eq 'check') {
    my $check_result = $self->check($request_data);
    $self->_show_response($check_result);
  }
  elsif ($request_data->{command} && $request_data->{command} eq 'pay') {
    my $pay_result = $self->pay($request_data);
    $self->_show_response($pay_result);
  }

  return 1;
}

#**********************************************************
=head2 check()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub check {
  my $self = shift;
  my ($request_data) = @_;
  _get_request_info($request_data);
  print "Content-Type: text/plain\n\n";

  my $login = $request_data->{login};
  my $password = $request_data->{password};
  my $account = $request_data->{account};
  my $CHECK_FIELD = $self->{conf}{PAYSYS_CITY24_ACCOUNT_KEY} || 'UID';

  my ($check_result, $user_info) = main::paysys_check_user({
    CHECK_FIELD => $CHECK_FIELD,
    USER_ID     => $account
  });

  if ($check_result == 0) {
    $self->account_gid_split($user_info->{GID});
  }

  if ($check_result == 0 && $login eq $self->{conf}{PAYSYS_CITY24_LOGIN} && $password eq $self->{conf}{PAYSYS_CITY24_PASSWORD}) {
    return {
      ACCOUNT           => $account,
      CHECK_RESULT      => $STATUSES{$check_result},
      FIO               => $user_info->{FIO} || '',
      DEPOSIT           => $user_info->{DEPOSIT} || '',
      GID               => $user_info->{GID} || '',
      SHOW_CHECK_RESULT => 1,
    };
  }
  else {
    return {
      ACCOUNT                 => $account,
      SHOW_WRONG_LOGIN_RESULT => 1
    };
  }
}

#**********************************************************
=head2 pay()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub pay {
  my $self = shift;
  my ($request_data) = @_;
  _get_request_info($request_data);
  print "Content-Type: text/plain\n\n";

  my $login = $request_data->{login};
  my $password = $request_data->{password};
  my $pay_id = $request_data->{payID};
  my $account = $request_data->{account};
  my $CHECK_FIELD = $self->{conf}{PAYSYS_CITY24_ACCOUNT_KEY} || 'UID';

  my ($check_result, $user_info) = main::paysys_check_user({
    CHECK_FIELD => $CHECK_FIELD,
    USER_ID     => $account
  });

  if ($check_result == 0) {
    $self->account_gid_split($user_info->{GID});
  }

  if ($check_result == 0 && $login eq $self->{conf}{PAYSYS_CITY24_LOGIN} && $password eq $self->{conf}{PAYSYS_CITY24_PASSWORD}) {
    my $date = $request_data->{payTimestamp};
    my $amount = $request_data->{amount} / 100;

    my ($pay_result, $payments_id) = main::paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      CHECK_FIELD       => $CHECK_FIELD,
      USER_ID           => $account,
      SUM               => $amount,
      EXT_ID            => $pay_id,
      DATA              => $request_data,
      DATE              => $date,
      MK_LOG            => 1,
      PAYMENT_ID        => 1,
      DEBUG             => $DEBUG,
      PAYMENT_DESCRIBE  => 'City24 payment',
    });

    my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

       $Paysys->paysys_report_add({
              TABLE          => 'paysys_city24_report',
              USER_KEY       => $user_info->{login},
              SUM            => $amount,
              TRANSACTION_ID => "C24:$pay_id",
              DATE           => $date,
      });

    return {
      ACCOUNT            => $account,
      PAY_RESULT         => $STATUSES{$pay_result},
      EXT_TRANSACTION_ID => $payments_id || '',
      SHOW_PAY_RESULT    => 1,
    };
  }
  else {
    return {
      ACCOUNT                 => $account,
      SHOW_WRONG_LOGIN_RESULT => 1
    };
  }
}

#**********************************************************
=head2 get_settings()

  Arguments:
     -

  Returns:

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
=head2 _show_result()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _show_response {
  my $self = shift;
  my ($attr) = @_;

  my $show_gid = '';
  if ($self->{conf}{PAYSYS_CITY24_GID_SHOW}) {
    my $subprovider_id = defined $self->{conf}{PAYSYS_CITY24_SUBPROVIDER_ID} ? $self->{conf}{PAYSYS_CITY24_SUBPROVIDER_ID} : ($attr->{GID} || 0);
    $show_gid = qq{<field3 name="SubProviderId">$subprovider_id</field3>};
  }

  if ($attr->{SHOW_CHECK_RESULT}) {
    print qq{<?xml version="1.0" encoding="UTF-8"?>
<commandResponse>
 <account>$attr->{ACCOUNT}</account>
 <result>$attr->{CHECK_RESULT}</result>
 <fields>
 <field1 name="FIO">$attr->{FIO}</field1>
 <field2 name="balance">$attr->{DEPOSIT}</field2>
 $show_gid
 </fields>
 <comment></comment>
</commandResponse>
  };
  }
  elsif ($attr->{SHOW_PAY_RESULT}) {
    print qq{<?xml version="1.0" encoding="UTF-8"?>
<commandResponse>
<extTransactionID>$attr->{EXT_TRANSACTION_ID}</extTransactionID>
<account>$attr->{ACCOUNT}</account>
<result>$attr->{PAY_RESULT}</result>
<comment></comment>
</commandResponse>
    };
  }
  elsif ($attr->{SHOW_WRONG_LOGIN_RESULT}) {
    print qq{<?xml version="1.0" encoding="UTF-8"?>
<commandResponse>
 <account>$attr->{ACCOUNT}</account>
 <result>300</result>
 <comment>Wrong login or password!</comment>
</commandResponse>
};
  }

  return 1;
}

#***********************************************************
=head2 get_request_info() - make a log

=cut
#***********************************************************
sub _get_request_info {
  my ($FORM) = @_;
  my $request = '';

  while (my ($k, $v) = each %{$FORM}) {
    $request .= "$k => $v,\n" if ($k ne '__BUFFER');
  }
  main::mk_log("$request", { PAYSYS_ID => "$PAYSYSTEM_ID/$PAYSYSTEM_SHORT_NAME", REQUEST => 'Request' });

  return $request;
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

  if(!$user->{$self->{conf}{PAYSYS_CITY24_ACCOUNT_KEY}}){
    $user->pi();
  }
  my $link = $self->{conf}{PAYSYS_CITY24_FAST_PAY} . "?paymethodid=6". "&number=" . ($user->{$self->{conf}{PAYSYS_CITY24_ACCOUNT_KEY}} || $attr->{$self->{conf}{PAYSYS_CITY24_ACCOUNT_KEY}}) . "&amount=" . ($attr->{SUM} || 0);

  return $html->tpl_show(main::_include('paysys_city24_fastpay', 'Paysys'), {LINK => $link}, { OUTPUT2RETURN => 0 });
}
#**********************************************************
=head2 reports()

=cut
#**********************************************************
sub report {
  my $self = shift;
  my ($attr) = @_;

  $html = $attr->{HTML};
  my $lang = $attr->{LANG};

  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  my $list = $Paysys->paysys_report_list({ TABLE => 'paysys_city24_report', COLS_NAME => 1, PAGE_ROWS => 9999999 });

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "City24",
      title      =>
        [ "#", "$lang->{USER}", "$lang->{SUM}", "$lang->{DATE}", "$lang->{TRANSACTION}"  ],
      DATA_TABLE => { 'order' => [ [ 0, 'id' ] ] },
    }
  );

  foreach my $payment (@$list) {
    $table->addrow($payment->{id},
      $html->button("$payment->{user_key}", "index=15&UID=$payment->{user_key}",{ class => 'btn btn-primary btn-xs' }),
      $payment->{sum},
      $payment->{date},
      $payment->{transaction_id});
  }

  print $table->show();

  return 1;
}


1;
