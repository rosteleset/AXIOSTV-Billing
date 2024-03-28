package Iptv::Iptvportal;

=head1 NAME

  Iptvporatl module
  http://iptvportal.ru/

=head1 VERSION

  Version 0.22
  Revision: 20200903

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.22;

use parent 'dbcore';
use AXbills::Base qw(load_pmodule mk_unique_value in_array);
use AXbills::Fetcher;
my $MODULE = 'Iptvportal';
my %services = ();

my ($admin, $CONF);
my $md5;
my $json;
my $html;
my $req_id = 1;
my $Iptv;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  $admin->{MODULE} = $MODULE;

  $Iptv = Iptv->new($db, $admin, $CONF);

  my $self = {};
  bless($self, $class);

  load_pmodule('Digest::MD5');
  load_pmodule('JSON');

  $md5 = Digest::MD5->new();
  $json = JSON->new->allow_nonref;
  $self->{SERVICE_NAME} = $MODULE;
  $self->{VERSION} = $VERSION;

  #  $self->{SERVICE_USER_FORM}          = 'olltv_user';
  #  $self->{SERVICE_USER_SCREEN_FORM}   = 'olltv_screens';
  #  $self->{SERVICE_USER_CHANNELS_FORM} = 'olltv_sub';
  #  $self->{SERVICE_CONSOLE}            = 'olltv_console';

  #$self->{SERVICE_TP_EXPORT}           = 'olltv_console';

  $self->{LOGIN} = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{URL} = $attr->{URL};
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{db} = $db;

  $self->{SUBSCRIBE_COUNT} = $attr->{SUBSCRIBE_COUNT} || 1;

  $self->{request_count} = 0;

  return $self;
}

#**********************************************************
=head2 service_info($attr) - Test service

  Arguments:
    $attr
      $attr
        FILTER_ID

  Results:
    $info

=cut
#**********************************************************
sub service_info {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => '/v2/subscriptions',
  });

  if (!%services) {
    foreach my $line ($result) {
      next if (ref $line ne 'ARRAY');

      foreach my $channels (@{$line}) {
        my $count = 0;
        $services{$channels->{id}} .= '<div>';
        foreach my $channal_info (@{$channels->{channels}}) {
          $services{$channels->{id}} .= $html->element('div', $html->img($channal_info->{image}, '', { class => 'img-thumbnail' }),
            { class => 'col-md-3', OUTPUT2RETURN => 1 });
          if ($count % 4) {
            $services{$channels->{id}} .= '</div><div>';
          }
          $count++;
        }
        $services{$channels->{id}} .= '</div>';
      }
    }
  }

  my $info = $services{$attr->{FILTER_ID}};

  return $info;
}

=comment
sub jsonrpc_call  {
  my ($url, $method, $params, $extra_headers) = @_;

  my %req =  (
    "jsonrpc" => '2.0',
    "id"     => $req_id++,
    "method" => $method,
    "params" => $params
  );

  json_encode(\%req);
  my $res = send ($url, \%req, $extra_headers=$extra_headers);
  #echo $res;
  $res = json_decode ($res, true);
  if (!defined($res)) {
    print "error: not result\n";
    return 0;
  }
  elsif (!in_array ('result', $res) || !defined($res->{'result'})) {
    print($res->{error});
    return 0;
  }
  else {
    return $res->{'result'};
  }

  return $res;
}


sub authorize_user {
  my ($auth_uri, $username, $password) = @_;

  global $_iptvportal_header;
  $res = jsonrpc_call ($auth_uri, $cmd="authorize_user", $params=array (
    'username' => $username,
    'password' => $password
  ));

  if (isset ($res) && array_key_exists ('session_id', $res)) {
    $_iptvportal_header = array ('Iptvportal-Authorization: ' . 'sessionid=' . $res ['session_id']);
  }

  return $res;
}
=cut

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;
  #my ($attr) = @_;

  my $result = $self->user_list({ PAGE_ROWS => 1 });

  if (!$self->{errno}) {
    $result = 'Ok';
  }
  else {
    $result = 'Error';
  }

  return $result;
}

#**********************************************************
=head2 user_del($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID     - User iptvportal id

  Resturns:

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{SUBSCRIBE_ID}) {
    return $self;
  }

  $Iptv->user_list({
    SERVICE_ID   => $attr->{SERVICE_ID},
    UID          => $attr->{UID},
    SUBSCRIBE_ID => '_SHOW',
    COLS_NAME    => 1,
    PAGE_ROWS    => 99999,
  });

  $attr->{TP_FILTER_ID} ||= $attr->{FILTER_ID};
  if ($Iptv->{TOTAL} > 0) {
    $self->subscriptions_del({ FILTER_ID => $attr->{TP_FILTER_ID}, SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID} });
    return $self;
  }

  my %fields = (
    "from"      => "subscriber_package",
    "where"     => { "in" => [ "subscriber_id", {
      "select" => {
        "data"  => "id",
        "from"  => "subscriber",
        "where" => { "eq" => [ "id", "$attr->{SUBSCRIBE_ID}" ] }
      }
    } ] },
    "returning" => "package_id"
  );

  $self->_send_request({
    CMD    => 'delete',
    PARAMS => \%fields,
  });

  $Iptv->user_add();

  return $self;
}

#**********************************************************
=head2 user_add($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{EMAIL}) {
    $self->{errno} = 1004;
    $self->{errstr} = 'EMAIL_NOT_DEFINED';
    return $self;
  }

  if (!$attr->{PASSWORD}) {
    $self->{errno} = 1005;
    $self->{errstr} = 'Password not defined';
    return $self;
  }

  #Check account
  my $exists_id = $self->user_list({ EMAIL => $attr->{EMAIL} });

  if ($exists_id) {
    $self->{errno} = 1003;
    $self->{errstr} = 'Email Exists';
    $self->{id} = $exists_id;
    return $self;
  }

  if ($attr->{FIO2}) {
    $attr->{FIO} = $attr->{FIO} . ' ' . $attr->{FIO2} . ' ' . ($attr->{FIO3} || q{});
  }

  if ($attr->{SUBSCRIBE_ID}) {
    $self->user_change({ %{$attr}, STATUS => 0 });
    return if !$self->{errno};
  }

  my ($surname, $first_name, $middle_name) = split(/ /, $attr->{FIO} || q{});

  my %fields = (
    "into"      => "subscriber",
    "columns"   => [ 'username', 'password', 'email', 'address', 'first_name', 'middle_name', 'surname', 'max_terminal', 'phone' ],
    "values"    => [
      $attr->{LOGIN},
      $attr->{PASSWORD},
      $attr->{EMAIL},
      $attr->{ADDRESS_FULL},
      $first_name,
      $middle_name,
      $surname,
      $self->{SUBSCRIBE_COUNT} || 0,
      $attr->{PHONE},
    ],
    "returning" => "id"
  );

  my $result = $self->_send_request({
    CMD    => 'insert',
    PARAMS => \%fields,
  });

  my $tp_id = $attr->{FILTER_ID} || $attr->{TP_FILTER_ID};

  if ($attr->{PAYMENTS_ADDED} && $result->{error}) {
    $attr->{FILTER_ID} = $tp_id;
    $self->subscriptions_add($attr);

    return $self;
  }

  if ($result) {
    if ($result->{result}) {
      $self->{SUBSCRIBE_ID} = $result->{result}[0];
      if ($self->{SUBSCRIBE_ID}) {
        if ($tp_id) {
          $attr->{SUBSCRIBE_ID} = $self->{SUBSCRIBE_ID};
          $attr->{FILTER_ID} = $tp_id;
          $self->subscriptions_add($attr);
          $self->_insert_inet_addr($attr);
        }
        if ($attr->{CID}) {
          $self->mac_add($attr);
        }
      }
    }
    elsif ($result->{error} && $result->{error} =~ /invalid email/) {
      $self->{errno} = 1000;
      $self->{errstr} = $result->{error};
    }
    elsif ($result->{error} && $result->{error} =~ /Username already exists/) {
      $self->{errno} = 1002;
      $self->{errstr} = $result->{id};
      $self->{id} = $attr->{ID};
    }
    elsif (!$result->{id}) {
      $self->{errno} = 1005;
      $self->{errstr} = $result->{error};
      $self->{id} = $result->{id};
    }
    elsif ($result->{error} && ref $result->{error} eq "HASH" && $result->{error}{message} =~ /subscriber_domain_id_key/) {
      my $user_sub_id = $self->user_list({ WHERE => $attr->{LOGIN} });
      if ($user_sub_id->{result} && $user_sub_id->{result}[0][0]) {
        $attr->{SUBSCRIBE_ID} = $user_sub_id->{result}[0][0];
        $self->{SUBSCRIBE_ID} = $attr->{SUBSCRIBE_ID};
        $attr->{FILTER_ID} = $tp_id;
        $self->subscriptions_add($attr);
      }
    }
  }
  else {
    $self->{errno} = 1;
    $self->{errstr} = "USER_NOT_CREATED " . $result->{error};
  }

  return $self;
}

#**********************************************************
=head2 user_change($attr) Change personal data

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my ($firstname, $lastname, $middlename) = split(/ /, $attr->{FIO} || q{});

  $attr->{STATUS} = $attr->{STATUS} ? 1 : 0;

  $attr->{FILTER_ID} ||= $attr->{TP_FILTER_ID};

  my %fields = (
    "table"     => "subscriber",
    "set"       => {
      username    => $attr->{LOGIN},
      password    => $attr->{PASSWORD},
      email       => $attr->{EMAIL},
      address     => $attr->{ADDRESS_FULL},
      first_name  => $firstname,
      surname     => $lastname,
      middle_name => $middlename,
      # disabled    => $attr->{STATUS},checkspeed
    },
    "where"     => { "eq" => [ "id", "$attr->{SUBSCRIBE_ID}" ] },
    "returning" => "id"
  );

  my $result = $self->_send_request({
    CMD    => 'update',
    PARAMS => \%fields,
  });

  if (!$self->{errno}) {
    $self->subscriptions_change($attr);
    $self->mac_add($attr);
    $self->_insert_inet_addr($attr);
  }

  return $self;
}

#**********************************************************
=head2 user_info($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my @fields = ('id', 'username', 'password', 'disabled');
  my $result = $self->_send_request({
    CMD    => 'select',
    PARAMS => {
      "data"  => \@fields,
      "from"  => "subscriber",
      "where" => { "eq" => [ "id", "$attr->{SUBSCRIBE_ID}" ] }
    },
  });

  if ($self->{errstr}) {
    if ($self->{errstr} =~ /not found/) {
      $self->{errno} = 404;
    }
    else {
      $self->{errno} = 1404;
    }
    return $self;
  }
  elsif ($result->{id}) {
    $self->{$result->{id}} = $result;
  }

  my $subcribes = $self->subscriptions({ SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID} });
  $result->{subcribes} = $subcribes;

  if ($self->{errstr}) {
    if ($self->{errstr} =~ /not found/) {
      $self->{errno} = 404;
    }
    else {
      $self->{errno} = 1404;
    }
  }

  $self->{RESULT}->{results} = [ $result ];

  my $mac_list = $self->mac_list($attr);
  $result->{mac_list} = $mac_list->{MAC_LIST};

  #  if($result) {
  #    if($result->{subscriptions}) {
  #      if (!  $result->{subscriptions}->{subscrstatus} ) {
  #        $self->{errno}=404;
  #        $self->{errstr}='Not found';
  #      }
  #      elsif($result->{subscriptions}->{subscrstatusid}) {
  #        $self->{errno}=$result->{subscriptions}->{subscrstatusid};
  #        $self->{errstr}=$result->{subscriptions}->{subscrstatus} || 'Blocked';
  #      }
  #    }
  #  }

  return $self;
}

#**********************************************************
=head2 user_list($attr)

  Arguments:
    $attr
      EMAIL
      PAGE_ROWS
      FIELDS

  Returns:


=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  my $pages = -1;
  if ($attr->{PAGE_ROWS}) {
    $pages = $attr->{PAGE_ROWS};
  }

  my @fields = ("id", "username", "password");

  if ($attr->{FIELDS}) {
    @fields = split(/,\s?/, $attr->{FIELDS});
  }

  my %fields_params = (
    "data" => \@fields,
    "from" => "subscriber",
  );

  $fields_params{where} = { "eq" => [ "username", $attr->{WHERE} ] } if ($attr->{WHERE});

  my $result = $self->_send_request({
    CMD    => 'select',
    PARAMS => \%fields_params,
  });

  if ($attr->{EMAIL} && $result) {
    foreach my $user (@{$result->{accounts}}) {
      if ($user->{email} eq $attr->{EMAIL}) {
        return $user->{id};
      }
    };

    return 0;
  }

  return ($result) ? $result : [];
}

#**********************************************************
=head2 _json_former($request) - Format JSON curl string  from different date

=cut
#**********************************************************
sub _json_former {
  my ($request) = @_;
  my @text_arr = ();

  if (ref $request eq 'ARRAY') {
    foreach my $key (@{$request}) {
      push @text_arr, _json_former($key);
    }
    return '[' . join(', ', @text_arr) . "]";
  }
  elsif (ref $request eq 'HASH') {
    foreach my $key (keys %{$request}) {
      my $val = _json_former($request->{$key});
      push @text_arr, qq{ \\\"$key\\\" : $val };
    }
    return '{' . join(', ', @text_arr) . "}";
  }
  else {
    $request //= '';
    return qq{ \\\"$request\\\" };
  }
}

#**********************************************************
=head2 _send_request($attr)

  Arguments:

  Results:

=cut
#**********************************************************
sub _send_request {
  my $self = shift;
  my ($attr) = @_;

  my $request_url = $self->{URL};
  my $result = '';
  my $params = $attr->{PARAMS};

  if ($attr->{TYPE} && $attr->{TYPE} eq 'auth') {
    $request_url .= '/jsonrpc/';
  }
  else {
    $request_url .= '/jsonsql/';
  }

  my %req = (
    "jsonrpc" => '2.0',
    "id"      => $req_id++,
    "method"  => $attr->{CMD},
    "params"  => $params
  );

  if ($attr->{MAC}) {
    $params->{mac} = $attr->{MAC};
  }

  if (!$self->{session_id} && !$attr->{TYPE}) {
    $result = $self->_send_request({
      CMD    => 'authorize_user',
      PARAMS => {
        'username' => $self->{LOGIN},
        'password' => $self->{PASSWORD},
      },
      TYPE   => 'auth'
    });

    if (ref $result ne 'HASH') {
      $self->{status} = 'Incorrect response';
      $self->{errno} = 10020;
      $self->{errstr} = 'Incorrect response';
      return $result;
    }

    if ($result->{result} && $result->{result}->{session_id}) {
      $self->{session_id} = $result->{result}->{session_id};
    }

    if (!$self->{session_id}) {
      return $self;
    }
  }

  my @HEADERS = ();
  if ($self->{session_id}) {
    push @HEADERS, 'Iptvportal-Authorization: ' . 'sessionid=' . $self->{session_id};
  }

  if ($attr->{EMAIL}) {
    $params->{email} = $attr->{EMAIL};
  }

  if ($attr->{SUB_ID}) {
    $params->{sub_id} = $attr->{SUB_ID};
  }

  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};

  $self->{request_count}++;

  $result = web_request($request_url, {
    JSON_ARRAY_VARS => 1,
    POST            => _json_former(\%req),
    #GET            => ($attr->{POST}) ? undef : 1,
    #REQUEST_PARAMS_JSON => \%req,
    DEBUG           => $debug,
    HEADERS         => \@HEADERS,
    CURL_OPTIONS    => '-k',
    CURL            => 1,
    REQUEST_COUNT   => $self->{request_count}
  });

  my $perl_scalar;

  if ($result =~ /^{|^\[/) {
    delete $self->{status};
    delete $self->{errno};
    delete $self->{errstr};

    $perl_scalar = $json->decode($result);
    if (ref $perl_scalar eq 'HASH') {
      if ($perl_scalar->{status}) {
        $self->{status} = $perl_scalar->{status};
        $self->{errno} = $perl_scalar->{status};
        $self->{errstr} = $perl_scalar->{message};
      }
      elsif ($perl_scalar->{error}) {
        $self->{status} = $perl_scalar->{error}->{code};
        $self->{errno} = $perl_scalar->{error}->{code} || 10001;
        $self->{errstr} = $perl_scalar->{error}->{message};
        $self->{id} = $perl_scalar->{id};
      }
      elsif ($result eq 'null') {
        $self->{status} = 'Null response';
        $self->{errno} = 10001;
        $self->{errstr} = 'Null response';
      }

      $self->{hash} = $perl_scalar->{hash} if ($perl_scalar->{hash});
    }
  }
  elsif ($result =~ /^Timeout/) {
    $self->{status} = 'Timeout';
    $self->{errno} = 10000;
    $self->{errstr} = 'Timeout';
  }

  $perl_scalar //= '';

  return $perl_scalar;
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

  if ($attr->{TP_NUM}) {
    $self->subscriptions_change({
      FILTER_ID    => $attr->{TP_NUM},
      SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID}
    });
  }
  else {
    $self->user_del($attr);
  }

  return $self;
}

#**********************************************************
=head2 user_screens($attr)

  Arguments:
    $attr
      CID

=cut
#**********************************************************
sub user_screens {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{del}) {
    if ($attr->{CID}) {
      $self->mac_del($attr);
    }
  }
  else {
    if ($attr->{CID}) {
      my $max_terminal = $attr->{SCREEN_ID} ? $attr->{SCREEN_ID} + 1 : 1;
      my %fields = (
        "table"     => "subscriber",
        "set"       => {
          max_terminal => $max_terminal
        },
        "where"     => { "eq" => [ "id", "$attr->{SUBSCRIBE_ID}" ] },
        "returning" => "id"
      );
      $self->_send_request({
        CMD    => 'update',
        PARAMS => \%fields,
      });

      my $result = $self->mac_add({ %{$attr}, GET_RESULT => 1 });
      if ($result && $result->{result} && $result->{result}[0]) {
        $self->{CID} = $attr->{CID};
        $self->{SCREEN_ID} = $attr->{SCREEN_ID};
        $self->{SERIAL} = $attr->{SERIAL};
      }
      else {
        $self->{errno} = 1010;
        $self->{errstr} = 'SCREEN_NOT_ADDED';
      }
    }
  }

  return $self;
}

#**********************************************************
=head2 tp_export($attr)

=cut
#**********************************************************
sub tp_export {
  my $self = shift;

  my @fields = ('id', 'name', 'cost', 'disabled');
  my $result = $self->_send_request({
    CMD    => 'select',
    PARAMS => {
      "data" => \@fields,
      "from" => "package"
    },
  });

  my @tps = ();
  if ($result) {
    foreach my $tp (@{$result->{result}}) {
      push @tps, {
        ID   => $tp->[0],
        NAME => $tp->[1]
      };
    }
  }

  return \@tps;
}

#**********************************************************
=head2 reports($attr)

  Arguments:
    $attr
      TYPE

  $results:

=cut
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  my $result;
  my @result_list = ();

  my $fields = q{};
  if ($attr->{TYPE}) {
    if ($attr->{TYPE} eq 'users') {
      if ($attr->{del}) {
        $self->user_del({ SUBSCRIBE_ID => $attr->{ID} });
      }

      $fields = 'id,username,email,password,disabled';
      $result = $self->user_list({
        FIELDS => $fields
      });

      $self->{FUNCTION_FIELDS} = "iptv_console:DEL:id:&TYPE="
        . ($attr->{TYPE} || '') . "&del=1&COMMENTS=1"
        . (($attr->{SERVICE_ID}) ? "&SERVICE_ID=$attr->{SERVICE_ID}" : '');
      #":$lang{DEL}:MAC:&del=1&COMMENTS=del",
    }
    elsif ($attr->{TYPE} eq 'stb') {
      my %fields = (
        "data"     => [ { "t" => "inet_addr" }, { "t" => "mac_addr" }, { "s" => "username" } ],
        "from"     => [
          { "table" => "terminal", "as" => "t" },
          { "join" => "subscriber", "join_type" => "left", "as" => "s",
            "on"   => { "eq" => [ { "t" => "subscriber_id" }, { "s" => "id" } ] }
          }
        ],
        "order_by" => { "s" => "username" }
      );

      $fields = 'IP,MAC,USER';

      $result = $self->_send_request({
        CMD    => 'select',
        PARAMS => \%fields,
      });
    }
  }
  else {
    my %fields = (
      data    => [ 'name' => {
        "concat" => [ "protocol", "://", "inet_addr",
          { "coalesce" => [ { "concat" => [ ":", "port" ] }, "" ] },
          { "coalesce" => [ { "concat" => [ "/", "path" ] }, "" ] }
        ],
        "as"     => "mrl"
      } ],
      "from"  => "media",
      "where" => { "eq" => [ "is_tv", 1 ] }
    );

    $fields = 'name, url';

    $result = $self->_send_request({
      CMD    => 'select',
      PARAMS => \%fields,
    });
  }

  my @fields_arr = split(/,\s?/, $fields);
  foreach my $line (@{$result->{result}}) {
    my %row_hash = ();
    for (my $i = 0; $i <= $#{$line}; $i++) {
      $row_hash{$fields_arr[$i]} = $line->[$i];
    }

    push @result_list, \%row_hash;
  }


  #  my @report_list = ();
  #  foreach my $uid ( keys %{ $result->{subscribers} } ) {
  #    $result->{subscribers}->{$uid}->{uid}=$uid;
  #    push @report_list, $result->{subscribers}->{$uid};
  #  }

  my @menu = ("CHANNELS:index=$html->{index}&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
    "USERS:index=$html->{index}&TYPE=users&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
    "STB:index=$html->{index}&TYPE=stb&SERVICE_ID=$html->{HTML_FORM}->{SERVICE_ID}",
  );

  $self->{REPORT_NAME} = 'CHANNELS';
  $self->{REPORT} = \@result_list;
  $self->{MENU} = \@menu;

  return $self;
}

#**********************************************************
=head2 subscriptions($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID

=cut
#**********************************************************
sub subscriptions {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    "data"     => [ { "p" => "id" }, { "p" => "name" } ],
    "from"     => [
      { "table" => "package", "as" => "p" },
      { "join"      => "subscriber_package",
        "join_type" => "inner",
        "as"        => "s2p",
        "on"        => { "eq" => [ { "s2p" => "package_id" }, { "p" => "id" } ] }
      },
      { "join"      => "subscriber",
        "join_type" => "inner",
        "as"        => "s",
        "on"        => { "eq" => [ { "s2p" => "subscriber_id" }, { "s" => "id" } ] }
      }
    ],
    "where"    => { "eq" => [ { "s" => "id" }, "$attr->{SUBSCRIBE_ID}" ] },
    "order_by" => { "p" => "name" }
  );

  my $result = $self->_send_request({
    CMD    => 'select',
    PARAMS => \%FIELDS
  });

  return $self->{subcribes} = $result->{result};
}

#**********************************************************
=head2 subscriptions_change($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID

=cut
#**********************************************************
sub subscriptions_change {
  my $self = shift;
  my ($attr) = @_;

  my $subscribes_list = $self->subscriptions($attr);
  if ($subscribes_list) {
    foreach my $subscribe (@$subscribes_list) {
      next if $attr->{FILTER_ID} && $attr->{FILTER_ID} ne $subscribe->[0];

      $self->subscriptions_del({
        FILTER_ID    => $subscribe->[0],
        SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID}
      });
    }
  }

  my $result;
  if ($attr->{FILTER_ID} && !$attr->{STATUS}) {
    $result = $self->subscriptions_add($attr);
  }

  return $self->{subcribes} = $result;
}

#**********************************************************
=head2 subscriptions($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID

=cut
#**********************************************************
sub subscriptions_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{SUBSCRIBE_ID} || !$attr->{FILTER_ID}) {
    $self->{errno} = 1010;
    $self->{errstr} = 'NOT EXIST SUBSCRIBE_ID OR FILTER_ID';
    return $self;
  }

  my %fields = (
    "into"      => "subscriber_package",
    "columns"   => [ "subscriber_id", "package_id", "enabled" ],
    "select"    => {
      "data"  => [ { "s" => "id" }, { "p" => "id" }, "true" ],
      "from"  => [ {
        "table" => "subscriber", "as" => "s"
      }, {
        "table" => "package", "as" => "p"
      } ],
      "where" => {
        "and" => [ {
          "eq" => [ { "s" => "id" }, "$attr->{SUBSCRIBE_ID}" ]
        }, {
          "in" => [ { "p" => "id" }, "$attr->{FILTER_ID}" ]
        }
        ]
      }
    },
    "returning" => "package_id"
  );

  my $result = $self->_send_request({
    CMD    => 'insert',
    PARAMS => \%fields,
  });

  return $self->{subcribes} = $result;
}


#**********************************************************
=head2 subscriptions_del($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID
      FILTER_ID
      ALL        - DELETE ALL Subcribes

   #post http://nline.test.lfstrm.tv/v2/accounts/5895b294098f6b2811ba3b57/subscriptions {"id": "106", "valid": false}

   Delete ALL
     COMMAND => DELETE

=cut
#**********************************************************
sub subscriptions_del {
  my $self = shift;
  my ($attr) = @_;

  my %fields = (
    "from"      => "subscriber_package",
    "where"     => {
      "and" => [
        { "in" => [
          "subscriber_id", {
          "select" => {
            "data"  => "id",
            "from"  => "subscriber",
            "where" => { "eq" => [ "id", "$attr->{SUBSCRIBE_ID}" ] }
          }
        } ]
        },
        { "in" => [ "package_id", {
          "select" => {
            "data"  => "id",
            "from"  => "package",
            "where" => { "in" => [ "id", "$attr->{FILTER_ID}" ] }
          }
        }
        ]
        }
      ]
    },
    "returning" => "package_id"
  );

  $self->_send_request({
    CMD    => 'delete',
    PARAMS => \%fields,
  });

  return $self;
}

#**********************************************************
=head2 channels_change($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID
      FILTER_ID

=cut
#**********************************************************
sub channels_change {
  my $self = shift;
  my ($attr) = @_;

  my @filters = ();
  if ($attr->{FILTER_ID}) {
    @filters = split(',\s?', $attr->{FILTER_ID});
  }

  my $subscribes = $self->subscriptions($attr);
  my %cure_subscribes = ();
  if ($subscribes) {
    foreach my $sub (@$subscribes) {
      next if (ref $sub eq "ARRAY" || !$sub->{id});
      $cure_subscribes{$sub->{id}} = 1;
    }
  }

  if ($attr->{TP_FILTER_ID}) {
    #delete $cure_subacribes{$attr->{TP_FILTER_ID}};
    push @filters, $attr->{TP_FILTER_ID};
  }

  foreach my $filter_id (@filters) {
    if ($cure_subscribes{$filter_id}) {
      delete $cure_subscribes{$filter_id};
      next;
    }

    $attr->{FILTER_ID} = $filter_id;
    $self->subscriptions_add($attr);
  }

  #delete $cure_subacribes{$attr->{TP_FILTER_ID}};
  foreach my $subcribe_id (keys %cure_subscribes) {
    print "|DeL : $subcribe_id <br>";
    $self->subscriptions_del({ FILTER_ID => $subcribe_id, SUBSCRIBE_ID => $attr->{SUBSCRIBE_ID} });
  }

  return $self;
}

#**********************************************************
=head2 pin_add($attr)

=cut
#**********************************************************
sub pin_add {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => '/partners/user/autorizebycode',
    PARAMS => {
      localid => $attr->{ID},
      code    => $attr->{PIN},
    },
    hash   => $self->{LOGIN} . $attr->{ID} . $attr->{PIN} . $self->{PASSWORD}
  });

  return $self;
}


#**********************************************************
=head2 mac_add($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID     - User iptvportal id
      CID              - User MAC

  Results:
    $self

=cut
#**********************************************************
sub mac_add {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->mac_list($attr);

  foreach my $line (@{$result->{result}}) {
    if ($attr->{CID} && $attr->{CID} eq $line->[0]) {
      return $self;
    }
  }

  if (!$attr->{CID}) {
    return $self;
  }

  my %fields = (
    "into"      => "terminal",
    "columns"   => [ "subscriber_id", "mac_addr", "registered" ],
    "select"    => {
      "data"  => [ "$attr->{SUBSCRIBE_ID}", "$attr->{CID}", "true" ],
      "from"  => {
        "table" => "subscriber",
        "as"    => "s"
      },
      "where" => {
        "eq" => [ "id", "$attr->{SUBSCRIBE_ID}" ]
      }
    },
    "returning" => "id"
  );

  $result = $self->_send_request({
    CMD    => 'insert',
    PARAMS => \%fields,
  });

  return $result if $attr->{GET_RESULT};

  return $self;
}

#**********************************************************
=head2 mac_del($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID     - User iptvportal id
      CID              - User MAC

  Results:
    $self

=cut
#**********************************************************
sub mac_del {
  my $self = shift;
  my ($attr) = @_;

  my %fields = (
    "from"      => "terminal",
    "where"     => {
      "and" => [ {
        "eq" => [ "mac_addr", "$attr->{CID}" ] }, {
        "in" => [
          "subscriber_id", {
          "select" => {
            "data"  => "id",
            "from"  => "subscriber",
            "where" => {
              "eq" => [ "id", "$attr->{SUBSCRIBE_ID}" ]
            }
          }
        } ]
      } ]
    },
    "returning" => "id"
  );

  $self->_send_request({
    CMD    => 'delete',
    PARAMS => \%fields,
  });

  return $self;
}

#**********************************************************
=head2 mac_list($attr)

  Arguments:
    $attr
      SUBSCRIBE_ID     - User iptvportal id

  Results:

=cut
#**********************************************************
sub mac_list {
  my $self = shift;
  my ($attr) = @_;

  my %fields = (
    "data"  => [ { "t" => "id" }, { "t" => "inet_addr" }, { "t" => "mac_addr" } ],
    "from"  => [
      { "table" => "terminal", "as" => "t" },
      { "join" => "subscriber", "join_type" => "inner", "as" => "s",
        "on"   => { "eq" => [ { "t" => "subscriber_id" }, { "s" => "id" } ] }
      }
    ],
    "where" => { "eq" => [ { "s" => "id" }, "$attr->{SUBSCRIBE_ID}" ] }
  );

  my $result = $self->_send_request({
    CMD    => 'select',
    PARAMS => \%fields,
  });

  $self->{MAC_LIST} = $result->{result};

  return $self;
}

#**********************************************************
=head2 _insert_inet_addr($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _insert_inet_addr {
  my $self = shift;
  my ($attr) = @_;

  use Internet::Sessions;
  my $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $CONF);

  my $user_sessions = $Sessions->online({
    UID        => $attr->{UID},
    CLIENT_IP  => '_SHOW',
    COLS_NAME  => 1
  });

  return $self if !$Sessions->{TOTAL};

  $self->_delete_inet_addr($attr);

  foreach my $session (@{$user_sessions}) {
    next if !$session->{client_ip};

    my %fields = (
      "into"      => "subscriber_inetaddr",
      "columns"   => [ 'subscriber_id', 'inet_addr' ],
      "values"    => [
        $attr->{SUBSCRIBE_ID},
        $session->{client_ip}
      ],
      "returning" => "id"
    );

    my $result = $self->_send_request({
      CMD    => 'insert',
      PARAMS => \%fields,
    });

    delete $self->{errstr};
    delete $self->{errno};
  }

  return $self;
}

#**********************************************************
=head2 _delete_inet_addr($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _delete_inet_addr {
  my $self = shift;
  my ($attr) = @_;

  my %fields = (
    "from"      => "subscriber_inetaddr",
    "where"     => { "in" => [ "subscriber_id", {
      "select" => {
        "data"  => "id",
        "from"  => "subscriber",
        "where" => { "eq" => [ "id", "$attr->{SUBSCRIBE_ID}" ] }
      }
    } ] },
    "returning" => "id"
  );

  $self->_send_request({
    CMD    => 'delete',
    PARAMS => \%fields,
  });

  return 0;
}

1;
