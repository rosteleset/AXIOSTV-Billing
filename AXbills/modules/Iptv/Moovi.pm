package Iptv::Moovi;

=head1 NAME

=head1 VERSION

  VERSION: 0.02
  Revision: 20201117

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

my $MODULE = 'Moovi';

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

  my $result = $self->_send_request({
    ACTION => "/getTariffs",
    PARAMS => {
      account  => $self->{LOGIN},
      password => $self->{PASSWORD}
    }
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
  push @params, 'Content-Type: application/json';

  my $result = web_request($request_url, {
    DEBUG      => 4,
    HEADERS    => \@params,
    POST       => $post,
    DEBUG      => $debug,
    DEBUG2FILE => $self->{DEBUG_FILE},
    CURL       => 1,
  });

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
=head2 user_info($attr)

   Arguments:
     $attr
       ID

   Results:

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => "/getUser",
    PARAMS => {
      account  => $self->{LOGIN},
      password => $self->{PASSWORD},
      contract => $attr->{UID}
    }
  });

  return $self;
}

#**********************************************************
=head2 user_add($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{TP_ID}) {
    $self->{errno} = '1402';
    $self->{errstr} = 'ERR_SELECT_TP';
    return $self;
  }

  if (!$attr->{SERVICE_MODULE}) {
    $self->{errno} = '1403';
    $self->{errstr} = 'Error select Service';
    return $self;
  }

  $attr->{FILTER_ID} = $attr->{TP_FILTER_ID};
  if (!$attr->{FILTER_ID}) {
    $self->{errno} = '1404';
    $self->{errstr} = $lang->{FILTER_ID_EMPTY} || "The 'Filter_id' field is empty";
    return $self;
  }

  my $user_id = $self->_get_user_id($attr->{UID});

  if (!$user_id) {
    $self->_add_new_user($attr);
  }
  elsif ($user_id && !$attr->{STATUS}) {
    $self->_user_activate($user_id);
    $self->_assign_tp($user_id, $attr->{FILTER_ID});
  }

  return $self;
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

  $attr->{FILTER_ID} = $attr->{TP_FILTER_ID};
  if (!$attr->{FILTER_ID}) {
    $self->{errno} = '14010';
    $self->{errstr} = $lang->{FILTER_ID_EMPTY} || "The 'Filter_id' field is empty";
    return $self;
  }
    
  $attr->{CHANGE_TP} = 1 if ($attr->{TP_INFO_OLD} && $attr->{TP_INFO_OLD}{TP_ID});
  
  if ($attr->{CHANGE_TP}) {
    if (!$attr->{TP_INFO_OLD}{FILTER_ID}) {
      $self->{errno} = '14011';
      $self->{errstr} = $lang->{FILTER_ID_EMPTY} || "The 'Filter_id' field is empty";
      return $self;
    }

    my $user_id = $self->_get_user_id($attr->{UID});
    if ($user_id) {
      $self->{errno} = '14012';
      $self->{errstr} = $lang->{IPTV_USER_NOT_FOUND} || "User not found";
      return $self;
    }

    $self->_remove_tp($user_id, $attr->{TP_INFO_OLD}{FILTER_ID});
    $self->_assign_tp($user_id, $attr->{FILTER_ID});
    
    return $self;
  }
  
  $self->user_del($attr) if $attr->{STATUS};

  return $self;
}

#**********************************************************
=head2 user_del($attr)

   Arguments:
     $attr
       ID

   Results:

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $attr->{FILTER_ID} = $attr->{TP_FILTER_ID};
  my $user_id = $self->_get_user_id($attr->{UID});

  $self->_remove_tp($user_id, $attr->{FILTER_ID});

  return $self;
}

#**********************************************************
=head2 user_negdeposit($attr)

  Arguments:
    ID    - User service ID

  Results:
    $self

=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;
  
  $attr->{TP_FILTER_ID} = $attr->{FILTER_ID};
  $self->user_del($attr);

  return $self;
}

#**********************************************************
=head2 _get_user_id($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _get_user_id {
  my $self = shift;
  my $uid = shift;

  return 0 if !$uid;

  my $result = $self->_send_request({
    ACTION => "/getUser",
    PARAMS => {
      account  => $self->{LOGIN},
      password => $self->{PASSWORD},
      contract => $uid
    }
  });

  return $result->{id} if ($result->{id} && $result->{code} && $result->{code} eq '200');

  return 0;
}

#**********************************************************
=head2 _add_new_user($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _add_new_user {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => "/addUser",
    PARAMS => {
      account  => $self->{LOGIN},
      password => $self->{PASSWORD},
      fio      => Encode::decode("UTF-8", $attr->{FIO}),
      contract => $attr->{UID}
    }
  });

  my $user_id = $result->{id};
  if (!$result->{code} || $result->{code} ne '200' || !$user_id) {
    $self->{errno} = '1405';
    $self->{errstr} = $lang->{IPTV_ERROR_CREATING_USER} || "Error creating user";
    return $self;
  }

  $result = $self->_send_request({
    ACTION => "/addUserAccount",
    PARAMS => {
      account  => $self->{LOGIN},
      password => $self->{PASSWORD},
      user_id  => $user_id,
      login    => $attr->{LOGIN},
      pin      => $attr->{PASSWORD}
    }
  });

  $self->_assign_tp($user_id, $attr->{FILTER_ID});

  return $self;
}

#**********************************************************
=head2 _user_activate($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _user_activate {
  my $self = shift;
  my $user_id = shift;

  return $self if !$user_id;

  my $result = $self->_send_request({
    ACTION => "/changeUser",
    PARAMS => {
      account  => $self->{LOGIN},
      password => $self->{PASSWORD},
      activity => '1',
      id       => $user_id
    }
  });
    
  return $self;
}

#**********************************************************
=head2 assign_tp($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _assign_tp {
  my $self = shift;
  my ($user_id, $tp_id) = @_;

  if (!$user_id || !$tp_id) {
    $self->{errno} = '1406';
    $self->{errstr} = $lang->{IPTV_ERROR_ADDING_TP} || "Error adding TP";
    return $self;
  }

  my $result = $self->_send_request({
    ACTION => "/addUserTariffs",
    PARAMS => {
      account  => $self->{LOGIN},
      password => $self->{PASSWORD},
      id       => $user_id,
      tariffs  => [ $tp_id ]
    }
  });

  if (ref $result ne 'ARRAY' || !$result->[0] || !$result->[0]{code} || $result->[0]{code} ne '200' || !$user_id) {
    $self->{errno} = '1407';
    $self->{errstr} = $lang->{IPTV_ERROR_ADDING_TP} || "Error adding TP";
    return $self;
  }

  return $self;
}

#**********************************************************
=head2 _remove_tp($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _remove_tp {
  my $self = shift;
  my ($user_id, $tp_id) = @_;

  if (!$user_id || !$tp_id) {
    $self->{errno} = '1408';
    $self->{errstr} = $lang->{IPTV_ERROR_DEL_TP} || "Tariff plan deletion error";
    return $self;
  }

  my $result = $self->_send_request({
    ACTION => "/deleteUserTariffs",
    PARAMS => {
      account  => $self->{LOGIN},
      password => $self->{PASSWORD},
      id       => $user_id,
      tariffs  => [ $tp_id ]
    }
  });

  if (ref $result ne 'ARRAY' || !$result->[0] || !$result->[0]{code} || $result->[0]{code} ne '200' || !$user_id) {
    $self->{errno} = '1409';
    $self->{errstr} = $lang->{IPTV_ERROR_DEL_TP} || "Tariff plan deletion error";
    return $self;
  }

  return $self;
}

#**********************************************************
=head2 tp_export()

=cut
#**********************************************************
sub tp_export {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => "/getTariffs",
    PARAMS => {
      account  => $self->{LOGIN},
      password => $self->{PASSWORD}
    }
  });

  if (!$result->{code} || $result->{code} ne '200' || !$result->{tariffs} || ref($result->{tariffs}) ne 'ARRAY' ) {
    $self->{errno} = 1401;
    $self->{errstr} = $lang->{TP_NOT_FOUND} || 'Tariff plans not found';
    return $self;
  }
  
  $self->{TP_LIST} = 1;
  my @tps = ();
  
  for my $tp_id (@{$result->{tariffs}}) {
    my $tp = $self->_send_request({
      ACTION => "/getTariff",
      PARAMS => {
        account  => $self->{LOGIN},
        password => $self->{PASSWORD},
        id       => $tp_id
      }
    });

    next if (!$result->{code} || $result->{code} ne '200');

    my $is_utf = Encode::is_utf8($tp->{tariff_name});
    Encode::_utf8_off($tp->{name}) if (!$is_utf);

    push @tps, { ID => $tp->{id}, NAME => $tp->{name} };
  }

  return \@tps;
}

1;