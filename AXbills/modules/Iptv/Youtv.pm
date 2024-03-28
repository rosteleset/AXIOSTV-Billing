package Iptv::Youtv;

=head1 NAME

=head1 VERSION

  VERSION: 0.02
  Revision: 20210112

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.02;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule in_array _bp);
use AXbills::Fetcher qw(web_request);
use AXbills::Misc;

my $MODULE = 'Youtv';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;

#**********************************************************
=head2 new($class, $db, $admin, $CONF, $attr)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $admin->{MODULE} = $MODULE;
  $html = $attr->{HTML} if ($attr->{HTML});
  $lang = $attr->{LANG} if ($attr->{LANG});

  my $self = {};
  bless($self, $class);

  load_pmodule('JSON');

  $json = JSON->new->allow_nonref;
  $self->{SERVICE_NAME} = $MODULE;
  $self->{VERSION} = $VERSION;
  $self->{db} = $db;

  $self->{LOGIN} = $attr->{LOGIN} || q{};
  $self->{PASSWORD} = $attr->{PASSWORD} || q{};
  $self->{URL} = $attr->{URL} || '';
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;

  print "Content-Type: text/html\n\n" if ($self->{debug} && $self->{debug} > 5);

  $self->{VERSION} = $VERSION;

  return $self;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;

  my $result = $self->_auth();

  $self->_send_request({
    ACTION => "dealer/11/prices",
    TOKEN  => $result
  });

  return $result;
}

#**********************************************************
=head2 _send_request($attr)

=cut
#**********************************************************
sub _send_request {
  my $self = shift;
  my ($attr) = @_;

  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};
  $debug = 2 if ($self->{DEBUG_FILE} && $debug < 2);

  my $request_url = $self->{URL} || '';
  $request_url .= $attr->{ACTION} if ($attr->{ACTION});

  my $post = $attr->{PARAMS} ? JSON::to_json($attr->{PARAMS}) : '';
  $post =~ s/\"/\\"/g;

  my @params = ();
  push @params, 'Accept: application/vnd.youtv.v8+json';
  push @params, 'Accept-Language: ru';
  push @params, 'Device-UUID: 98765432100';
  push @params, 'Content-Type: application/json';

  push @params, 'Authorization: Bearer ' . $attr->{TOKEN} if ($attr->{TOKEN});

  my $result = web_request($request_url, {
    DEBUG        => 4,
    HEADERS      => \@params,
    POST         => $post,
    DEBUG        => $debug,
    DEBUG2FILE   => $self->{DEBUG_FILE},
    CURL         => 1,
    CURL_OPTIONS => $attr->{CURL_OPTIONS} || ''
  });

  $result = "{}" if $result eq '1' || $result eq '0';
  my $perl_scalar;
  if ($result =~ /\{/) {
    $perl_scalar = $json->decode($result);
  }
  else {
    $perl_scalar->{errno} = 10;
    $perl_scalar->{err_str} = $result;
    $self->{errno} = 100;
    $self->{error} = 100;
    $self->{errstr} = $result;
  }

  return $perl_scalar;
}

#**********************************************************
=head2 user_add($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{FILTER_ID} ||= $attr->{TP_FILTER_ID};
  return $self if $self->_check_service($attr);

  my $account_id = $self->_get_account_id();
  if (!$account_id) {
    $self->{errno} = '33003';
    $self->{errstr} = 'Error account id';
    return $self;
  }

  my $token = $self->_auth();

  $self->{SUBSCRIBE_ID} = $self->user_info({ UID => $attr->{UID}, ACCOUNT_ID => $account_id });

  if ($self->{SUBSCRIBE_ID}) {
    my $user = $self->_send_request({
      ACTION => "dealer/$account_id/subscriptions",
      TOKEN  => $token,
      PARAMS => {
        user_id  => $self->{SUBSCRIBE_ID},
        price_id => $attr->{FILTER_ID},
        days     => 31
      }
    });

    return $self if $self->_show_errors($user);
  }
  else {
    my $user = $self->_send_request({
      ACTION => "dealer/$account_id/users",
      TOKEN  => $token,
      PARAMS => {
        name        => $attr->{LOGIN},
        password    => $attr->{PASSWORD},
        external_id => $attr->{UID},
        email       => $attr->{EMAIL} || ''
      }
    });

    return $self if $self->_show_errors($user);
  }

  return $self;
}

#**********************************************************
=head2 user_info($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $account_id = $attr->{ACCOUNT_ID} || $self->_get_account_id();
  return() if !$account_id;

  my $token = $self->_auth();

  if ($attr->{SUBSCRIBE_ID}) {
    my $user = $self->_send_request({
      ACTION => "dealer/$account_id/users/$attr->{SUBSCRIBE_ID}",
      TOKEN  => $token,
    });

    return $user->{data}{id} if ($user->{data} && $user->{data}{id});
  }

  my $user = $self->_send_request({
    ACTION => "dealer/$account_id/users/external-user-id/$attr->{UID}",
    TOKEN  => $token,
  });

  return $user->{data}{id} if ($user->{data} && $user->{data}{id});
  
  return 0;
}

#**********************************************************
=head2 user_change($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $account_id = $attr->{ACCOUNT_ID} || $self->_get_account_id();
  return() if !$account_id || !$attr->{SUBSCRIBE_ID};

  my $token = $self->_auth();

  $attr->{CHANGE_TP} = 1 if ($attr->{TP_INFO_OLD} && $attr->{TP_INFO_OLD}{FILTER_ID});
  $attr->{FILTER_ID} ||= $attr->{TP_FILTER_ID};

  if ($attr->{CHANGE_TP}) {
    return $self if $attr->{STATUS};
    $self->user_del({
      SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID},
      ACCOUNT_ID   => $account_id
    });

    $self->user_add($attr);
    return $self;
  }

  if ($attr->{STATUS}) {
    $self->user_del({
      SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID},
      ACCOUNT_ID   => $account_id
    });

    return $self;
  }

  return $self;
}

#**********************************************************
=head2 user_del($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  my $account_id = $attr->{ACCOUNT_ID} || $self->_get_account_id();
  return() if !$account_id || !$attr->{SUBSCRIBE_ID};

  my $token = $self->_auth();

  $self->_send_request({
    ACTION      => "dealer/$account_id/users/$attr->{SUBSCRIBE_ID}/block",
    TOKEN       => $token,
    CURL_OPTIONS => '-X PUT'
  });

  return 0;
}

#**********************************************************
=head2 user_negdeposit($attr)

  Arguments:
    $attr
      UID

  Results:

=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  $self->user_del({ SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID} });

  return $self;
}

#**********************************************************
=head2 tp_export()

=cut
#**********************************************************
sub tp_export {
  my $self = shift;

  my $account_id = $self->_get_account_id();
  return() if !$account_id;

  my $token = $self->_auth();

  my $tps = $self->_send_request({
    ACTION => "dealer/$account_id/prices",
    TOKEN  => $token
  });
  return() if !$tps->{data} || ref $tps->{data} ne 'ARRAY';
  
  my @finally_tps = ();
  foreach (@{$tps->{data}}) {
    next if !$_->{payment_gateways} || !$_->{payment_gateways}[0] || !$_->{payment_gateways}[0]{prices};
    next if !$_->{payment_gateways}[0]{prices}[0] || !$_->{payment_gateways}[0]{prices}[0]{id};

    my $id = $_->{payment_gateways}[0]{prices}[0]{id};
    Encode::_utf8_off($_->{name});
    push(@finally_tps, { ID => $id, NAME => $_->{name}, FILTER_ID => $id });
  }

  return \@finally_tps;
}

#**********************************************************
=head2 _check_service($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _check_service {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{SERVICE_MODULE}) {
    $self->{errno} = '33001';
    $self->{errstr} = 'Error select Service';
    return 1;
  }

  if (!$attr->{FILTER_ID}) {
    $self->{errno} = '33002';
    $self->{errstr} = 'Error filter id';
    return 1;
  }

  return 0;
}

#**********************************************************
=head2 _show_errors($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _show_errors {
  my $self = shift;
  my ($attr) = @_;

  return 0 if ((!$attr->{errors} && ref($attr->{errors}) ne 'HASH') && !$attr->{message}) || !$attr->{status_code};

  my @errors = ();

  foreach my $err (values(%{$attr->{errors}})) {
    if (ref $err ne 'ARRAY') {
      push(@errors, $err);
      next;
    }

    map push(@errors, $_), @{$err};
  }

  $self->{errstr} = $attr->{message} ? $attr->{message} : join('<br>', @errors);
  Encode::_utf8_off($self->{errstr});
  $self->{errno} = $attr->{status_code};

  return 1;
}

#**********************************************************
=head2 _auth($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _auth {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => "auth/login",
    PARAMS => {
      email    => $self->{LOGIN},
      password => $self->{PASSWORD}
    }
  });

  return $result->{token} || '';
}

#**********************************************************
=head2 _get_account_id($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_account_id {
  my $self = shift;
  my ($attr) = @_;

  my $token = $self->_auth();
  my $accounts = $self->_send_request({
    ACTION => "dealer/accounts",
    TOKEN  => $token
  });

  return 0 if !$accounts->{data} || ref $accounts->{data} ne 'ARRAY' || !$accounts->{data}[0];
  return $accounts->{data}[0]{id} || 0;
}

1;