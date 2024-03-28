package Iptv::Ezhometech;

=head1 NAME

  Ezhometech;

=head1 VERSION

  VERSION: 0.2
  REVISION: 20190503

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(load_pmodule _bp in_array);
use AXbills::Fetcher;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Iptv;
use Users;
use Time::Local qw(timelocal);

our $VERSION = 0.2;

my AXbills::HTML $html;
my $CONF;
my $MODULE = 'Ezhometech';
my $db;
my $admin;
my $lang;
my $Users;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $Users = Users->new($db, $admin, $CONF);

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{LANG}) {
    $lang = $attr->{LANG};
  }

  $admin->{MODULE} = $MODULE;

  my $self = {
    db           => $db,
    conf         => $CONF,
    admin        => $admin,
    SERVICE_NAME => 'Ezhometech',
    VERSION      => $VERSION
  };

  bless($self, $class);

  $self->{LOGIN} = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{URL} = $attr->{URL};
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};

  if ($self->{URL} && $self->{URL} !~ /\/$/) {
    $self->{URL} .= '/';
  }

  return $self;
}


#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;
  #
  #  my $result = $self->_send_request({
  #    ACTION => 'token/createtoken?userid=billing&password=@bill123',
  #  });

  my $result;

  $result = $self->_get_token();

  if (!$result) {
    $self->{errno} = '10101';
    $self->{errstr} = "Ошибка при добавлении";

    return $self;
  }

  $result = $self->_send_request({
    ACTION => "server/query_black_list?token=$result->{token}",
  });

  my @items = split " ", $result;
  my %hash;
  foreach my $item (@items) {
    my ($i, $j) = split(/=/, $item);
    $hash{$i} = $j;
    if ($item =~ /username=\w+/) {
      my (undef, $username) = split(/=/, $item);
      _bp('', $username);
    }
  }

  if (!$self->{errno}) {
    $result = 'Ok';
  }
  else {
    $result = 'Error';
  }

  return $result;
}

#**********************************************************
=head2 _send_request($attr)

=cut
#**********************************************************
sub _send_request {
  my $self = shift;
  my ($attr) = @_;

  my $request_url = $self->{URL} || '';
  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};
  if ($self->{DEBUG_FILE} && $debug < 2) {
    $debug = 2;
  }

  if ($attr->{ACTION}) {
    $request_url .= $attr->{ACTION};
  }

  my $message = ();
  if ($attr->{PARAMS}) {
    foreach my $key (keys %{$attr->{PARAMS}}) {

      if ($message) {
        $message .= '&' . ($key || q{}) . '=' . $attr->{PARAMS}->{$key};
      }
      else {
        $message = $key . '=' . ($attr->{PARAMS}->{$key} // q{});
      }
    }
  }

  my $result = web_request($request_url,
    {
      DEBUG      => 4,
      DEBUG      => $debug,
      DEBUG2FILE => $self->{DEBUG_FILE},
      CURL       => 1,
      TIMEOUT    => 10,
    }
  );

  return $result;
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

  my $result;

  my $token = $self->_get_token();

  if (!$token) {
    $self->{errno} = '10101';
    $self->{errstr} = "Ошибка при добавлении";

    return $self;
  }

  my $tp_name = $attr->{TP_NAME} || $attr->{TP_INFO}{NAME};

  my $date_ex = POSIX::strftime("%m/%d/%Y", localtime(time + 35 * 86400));
  $result = $self->_send_request({
    ACTION => "server/add_user?token=$token->{token}&username=$attr->{LOGIN}&" .
      "password=$attr->{PASSWORD}&group=$tp_name&expired_time=$date_ex",
  });

  if (!$result) {
    $self->{errno} = '10101';
    $self->{errstr} = "Ошибка при добавлении";

    return $self;
  }

  if ($result == 3) {
    $result = $self->_send_request({
      ACTION => "server/update_user?token=$token->{token}&username=$attr->{LOGIN}&" .
        "password=$attr->{PASSWORD}&group=$tp_name&expired_time=$date_ex",
    });
  }

  return $self;
}

#**********************************************************
=head2 user_info($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $result;

  $result = $self->_get_token();

  if (!$result) {
    $self->{errno} = '10101';
    $self->{errstr} = "Ошибка при добавлении";

    return $self;
  }

  $Users->info($attr->{UID}, { SHOW_PASSWORD => 1, });

  $result = $self->_send_request({
    ACTION => "server/query_user_more?token=$result->{token}&username=$attr->{LOGIN}",
  });

  return $self;
}

#**********************************************************
=head2 user_change($attr)

   Arguments:
     $attr

   Results:

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{STATUS}) {
    $self->user_del($attr);
    return $self;
  }

  my $result;
  my $tp_name = $attr->{TP_NAME} || $attr->{TP_INFO}{NAME};

  my $token = $self->_get_token();

  if (!$token) {
    $self->{errno} = '10101';
    $self->{errstr} = "Ошибка при добавлении";

    return $self;
  }

  my $date_ex = POSIX::strftime("%m/%d/%Y", localtime(time + 35 * 86400));
  $result = $self->_send_request({
    ACTION => "server/update_user?token=$token->{token}&username=$attr->{LOGIN}&" .
      "password=$attr->{PASSWORD}&group=$tp_name&expired_time=$date_ex",
  });

  return $self;
}

#**********************************************************
=head2 user_del($attr)

   Arguments:
     $attr

   Results:

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  my $result;

  $result = $self->_get_token();

  if (!$result) {
    $self->{errno} = '10101';
    $self->{errstr} = "Ошибка при добавлении";

    return $self;
  }

  $Users->info($attr->{UID});

  if ($Users->{TOTAL}) {
    $self->_send_request({
      ACTION => "server/del_user?token=$result->{token}&username=$Users->{LOGIN}",
    });

    my $delete = $self->_send_request({
      ACTION => "player/get_player_list?token=$result->{token}",
    });

    my @result_array;
    my @items = split " ", $delete;
    my %hash;
    foreach my $item (@items) {
      my ($i, $j) = split(/=/, $item);
      $hash{$i} = $j;
      if ($item =~ /group=\w+/) {
        push @result_array, { %hash };
      }
    }

    foreach my $user_stream (@result_array) {
      if ($user_stream->{username} eq $Users->{LOGIN}) {
        $self->_send_request({
          ACTION => "player/stop_player?token=$result->{token}&sessionno=$user_stream->{sessionno}&protocol=$user_stream->{group}",
        });
      }
    }
  }

  return $self;
}

#**********************************************************
=head2 user_negdeposit($attr)

   Arguments:
     $attr

   Results:

=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  $Users->info($attr->{UID}, {
    SHOW_PASSWORD => 1,
  });

  return 0 if !$Users->{TOTAL} || !$CONF->{EZ_NULL_TP};

  my $token = $self->_get_token();

  if (!$token) {
    $self->{errno} = '10101';
    $self->{errstr} = "Ошибка при добавлении";

    return $self;
  }

  my $result;

  my $date_ex = POSIX::strftime("%m/%d/%Y", localtime(time + 35 * 86400));
  $result = $self->_send_request({
    ACTION => "server/update_user?token=$token->{token}&username=$attr->{LOGIN}&" .
      "password=$Users->{PASSWORD}&group=$CONF->{EZ_NULL_TP}&expired_time=$date_ex",
  });

  my $delete = $self->_send_request({
    ACTION => "player/get_player_list?token=$token->{token}",
  });

  my @result_array;
  my @items = split " ", $delete;
  my %hash;
  foreach my $item (@items) {
    my ($i, $j) = split(/=/, $item);
    $hash{$i} = $j;
    if ($item =~ /group=\w+/) {
      push @result_array, { %hash };
    }
  }

  foreach my $user_stream (@result_array) {
    if ($user_stream->{username} eq $Users->{LOGIN}) {
      $self->_send_request({
        ACTION => "player/stop_player?token=$token->{token}&sessionno=$user_stream->{sessionno}&protocol=$user_stream->{group}",
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 _get_token($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

=cut
#**********************************************************
sub _get_token {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => "token/createtoken?userid=$self->{LOGIN}&password=$self->{PASSWORD}",
  });

  my $my_hash;
  return 0 if (!$result);

  my ($key1, $key2) = split '=', $result;

  $my_hash->{$key1} = $key2;

  $my_hash->{$key1} =~ s/\s*$//;

  return $my_hash;
}

##**********************************************************
#=head2 get_url($attr)
#
#   Arguments:
#     $attr
#       ID
#
#   Results:
#     $self->
#       {RESULT}->{results}
#
#=cut
##**********************************************************
#sub get_url {
#  my $self = shift;
#  my ($attr) = @_;
#
#  $Users->info($attr->{UID}, {SHOW_PASSWORD => 1});
#
#  if ($Users->{TOTAL}) {
#    $self->{result}{web_url} = $self->{URL} . "getlink?username=$Users->{LOGIN}:password=$Users->{PASSWORD}:type=m3u";
#  }
#
#  return $self;
#}

#**********************************************************
=head2 tp_export()

=cut
#**********************************************************
sub tp_export {
  my $self = shift;

  my @result_array = ();
  my $result = $self->_get_token();

  if (!$result) {
    $self->{errno} = '10101';
    $self->{errstr} = "Ошибка при добавлении";

    return $self;
  }

  $result = $self->_send_request({
    ACTION => "server/query_group?token=$result->{token}",
  });

  my @items = split " ", $result;
  my %hash;
  foreach my $item (@items) {
    my ($i, $j) = split(/=/, $item);
    $hash{$i} = $j;
    if ($item =~ /mc_src=\w+/) {
      push @result_array, { %hash };
    }
  }

  foreach my $res (@result_array) {
    $res->{ID} = $res->{No};
    $res->{NAME} = $res->{name};
  }

  return \@result_array;
}

#**********************************************************
=head2 additional_functions($attr)

   Arguments:
     $attr

   Results:

=cut
#**********************************************************
sub additional_functions {
  my $self = shift;
  my ($attr) = @_;

  $Users->info($attr->{UID}, { SHOW_PASSWORD => 1 });

  if ($Users->{TOTAL}) {
    if ($attr->{sid}) {
      my $btn = $html->button($lang->{INTERNAL_URL}, '', {
        class            => 'btn btn-default',
        GLOBAL_URL       => $CONF->{EZ_LOCAL_IP} . "/getlink?username=$Users->{LOGIN}:password=$Users->{PASSWORD}:type=m3u",
        target           => '_blank',
        OUTPUT_TO_RETURN => 1
      });

      my $btn1 = $html->button($lang->{EXTERNAL_URL}, '', {
        class            => 'btn btn-default',
        GLOBAL_URL       => $CONF->{EZ_EXTERNAL_IP} . "/getlink?username=$Users->{LOGIN}:password=$Users->{PASSWORD}:type=m3u",
        target           => '_blank',
        OUTPUT_TO_RETURN => 1
      });

      return { FIRST => $btn1, SECOND => $btn };
    }

    if ($CONF->{EZ_EXTERNAL_IP}) {
      print $html->button($lang->{EXTERNAL_URL}, '', {
        class            => 'btn btn-default',
        GLOBAL_URL       => $CONF->{EZ_EXTERNAL_IP} . "/getlink?username=$Users->{LOGIN}:password=$Users->{PASSWORD}:type=m3u",
        target           => '_blank',
        OUTPUT_TO_RETURN => 1
      });
    }
    print " ";
    if ($CONF->{EZ_LOCAL_IP}) {
      print $html->button($lang->{INTERNAL_URL}, '', {
        class            => 'btn btn-default',
        GLOBAL_URL       => $CONF->{EZ_LOCAL_IP} . "/getlink?username=$Users->{LOGIN}:password=$Users->{PASSWORD}:type=m3u",
        target           => '_blank',
        OUTPUT_TO_RETURN => 1
      });
    }
  }
}

1;