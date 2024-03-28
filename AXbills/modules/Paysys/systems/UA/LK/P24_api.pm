package Paysys::systems::P24_api;
use strict;
use warnings FATAL => 'all';

use parent 'dbcore';

use AXbills::Base qw(load_pmodule _bp);
use AXbills::Fetcher;
require Paysys::Paysys_Base;

my $PAYSYSTEM_NAME       = 'P24_API';
my $PAYSYSTEM_SHORT_NAME = 'P24_API';

my $PAYSYSTEM_ID         = 124;
my $PAYSYSTEM_IPS        = '';
my $PAYSYSTEM_EXT_PARAMS = '';

my $PAYSYSTEM_CLIENT_SHOW = 1;
my $DEBUG = 1;
my %PAYSYSTEM_CONF = (

);


#**********************************************************
=head2 new() -

  Arguments:
     -
  Returns:

  Examples:

=cut

#**********************************************************
sub new {
  my $class = shift;

  my $CONF = shift;
  my $self = {CONF => $CONF};

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 create_session() -

  Arguments:
     -
  Returns:

  Examples:

=cut

#**********************************************************
sub create_session{
  my $self = shift;

  my $create_session_result = web_request("https://link.privatbank.ua/api/auth/createSession", {
      POST    => qq[{"clientId":"$self->{CONF}->{PAYSYS_P24_API_CLIENT_ID}","clientSecret":"$self->{CONF}->{PAYSYS_P24_API_SECRET}"}],
      DEBUG   => 0,
      HEADERS => ['Content-Type: application/json'],
      JSON_RETURN => 1,
    });

  my $session_id;
  my @roles;
  if(ref $create_session_result eq 'HASH' && $create_session_result->{id}) {
    $session_id = $create_session_result->{id};
    @roles = $create_session_result->{roles};
    return $session_id, @roles;
  }
  return $create_session_result;
}

#**********************************************************
=head2 validate_session() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub validate_session {
  my $self = shift;

  my ($session_id) = @_;

  my $validate_session_result = web_request("https://link.privatbank.ua/api/auth/validateSession", {
      POST    => qq[{"sessionId":"$session_id"}],
      DEBUG   => 0,
      HEADERS => ['Content-Type: application/json'],
      JSON_RETURN => 1,
    });

  if(ref $validate_session_result eq 'HASH') {
    if($validate_session_result->{error}){
      return 0;
    }
    else{
      return 1;
    }
  }

  return 1;
}


#**********************************************************
=head2 validate_session() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub login {
  my $self = shift;

  my ($session_id, $login, $password) = @_;

  my $login_result = web_request("https://link.privatbank.ua/api/p24BusinessAuth/createSession", {
      POST    => qq[{"sessionId":"$session_id","login":"$login","password":"$password"}],
      DEBUG   => 0,
      HEADERS => ['Content-Type: application/json'],
      JSON_RETURN => 1,
    });

#  if(ref $login_result eq 'HASH') {
#    _bp("res", $login_result);
#  }

  return $login_result;
}

#**********************************************************
=head2 validate_session() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub send_otp {
  my $self = shift;

  my ($session_id, $otp) = @_;

  my $send_otp_result = web_request("https://link.privatbank.ua/api/p24BusinessAuth/checkOtp", {
      POST    => qq[{"sessionId":"$session_id", "otp":"$otp"}],
      DEBUG   => 0,
      HEADERS => ['Content-Type: application/json'],
      JSON_RETURN => 1,
    });

  if($send_otp_result->{errstr}) {
    return 0;
  }

  return 1;
}

#**********************************************************
=head2 validate_session() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub choose_phone_for_otp {
  my $self = shift;

  my ($session_id, $send_otp) = @_;

  my $send_otp_result = web_request("https://link.privatbank.ua/api/p24BusinessAuth/sendOtp ", {
      POST    => qq[{"sessionId":"$session_id", "otpDev":"$send_otp"}],
      DEBUG   => 0,
      HEADERS => ['Content-Type: application/json'],
      JSON_RETURN => 1,
    });

  if(ref $send_otp_result eq 'HASH') {
    _bp("res", $send_otp_result);
  }

  return 1;
}

#**********************************************************
=head2 get_statements() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub get_statements {
  my $self = shift;

  my ($session_id, $start_date, $end_date, $role) = @_;

  my $statements = web_request("https://link.privatbank.ua/api/p24b/statements?stdate=$start_date&endate=$end_date&showInf", {
#      POST    => qq[{"sessionId":"$session_id"}],
      DEBUG   => 0,
      HEADERS => ["Authorization: Token $session_id", "Content-Type: application/json"],
#      JSON_RETURN => 1,
    });

  return $statements;
}

#**********************************************************
=head2 get_statements() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub make_payment {
  my $self = shift;
  my ($attr) = @_;

  main::mk_log("Add payments for user", {PAYSYS_ID => 'P24_Api', });

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
    MK_LOG           => 1,
    DEBUG            => 1,
    PAYMENT_DESCRIBE => 'P24 Api import statements',
  });

  return $status;
}

1;
