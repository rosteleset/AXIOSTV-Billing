package Binotel;

=head1 NAME

  Module: Callcenter
  Plugin: Binotel

=head1 VERSION

  VERSION: 8.04
  DATE: 2021.06.06

=head1 DOCUMENRATION


=cut

use strict;
use warnings;
use AXbills::Fetcher qw/web_request/;
use AXbills::Misc;
use JSON qw/encode_json decode_json/;

my $host = '';

my %hash_error = (
  102 => 'No such method',
  103 => 'Not enough data',
  104 => 'Wrong data',
  105 => 'Something went wrong',
  106 => 'Requests are too frequent',
  120 => 'Your company is disabled',
  121 => 'Your key or secret is wrong',
  150 => 'Can\'t call to the ext',
  151 => 'Can\'t call to the external number',
);

print "Content-Type: text/html\n\n";

require Users;
Users->import();
my $Users;

#+++*******************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {};

  $self->{admin} = $admin;
  $self->{conf} = $CONF;
  $self->{db} = $db;

  bless($self, $class);

  $Users = Users->new(
    $self->{db},
    $self->{admin},
    $self->{conf}
  );

  return $self;
}

#**********************************************************
=head2 binotel_init($url, $attr)

=cut
#**********************************************************
sub binotel_init {
  my $self = shift;
  my ($url, $attr) = @_;

  my $json        = JSON->new->utf8(0);
  my $key         = $self->{conf}->{BINOTEL_KEY};
  my $secret      = $self->{conf}->{BINOTEL_SECRET};
  my $api_version = $self->{conf}->{BINOTEL_VERSION};
  my $api_host    = $self->{conf}->{BINOTEL_HOST};
  my $api_format  = $self->{conf}->{BINOTEL_FORMAT};
  my $debug       = $self->{conf}->{BINOTEL_DEBUG};

  if (! $api_host) {
    $self->{errno}=2;
    $self->{errstr}='NO API URL';
    return $self;
  }

  my $json_load_error = AXbills::Base::load_pmodule("JSON", { RETURN => 1 });
  if ($json_load_error) {
    print($json_load_error);
    return 0;
  }

  my $post_json = $json->encode({
    'key'    => $key,
    'secret' => $secret,
    %{$attr},
  });

  if ($debug) {
    print("[CLIENT] Send request: $json");
    return 1;
  }

  my $url_send_requst = $api_host . '/' . $api_version . '/' . $url . '.' . $api_format;
  my @header = ('Content-Type: application/json', 'Content-Length: ' . length($json));

  $post_json =~ s/\"/\\"/g;

  my $result = web_request($url_send_requst, {
    HEADER      => \@header,
    POST        => $post_json,
    CURL        => 1,
    JSON_RETURN => 1,
  });

  unless ($result) {
    return 0;
  }

  return $result;
}

#**********************************************************
=head2 get_users_service($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub get_users_service {
  my $self = shift;
  my ($attr) = @_;

  my $binotel = $self->binotel_init("stats/all-incoming-calls-since", {
    timestamp => _get_logging_time()
  });

  if ($binotel && $binotel->{status} && $binotel->{status} eq 'success') {
    $self->_process_data($attr, $self->{conf}->{BINOTEL_SERVER_DOMAIN});
  }
  else {
    print("REST API error: $hash_error{ $binotel->{error} }") if ($binotel->{error});
  }

  return 1;
}

#**********************************************************
=head2 send_users_service($binotel)

=cut
#**********************************************************
sub _send_users_service {
  my ($binotel) = @_;

  my $users_list = $Users->list({
    PHONE      => "*" . $binotel . "*",
    FIO        => '_SHOW',
    EMAIL      => '_SHOW',
    CELL_PHONE => "*" . $binotel,
    _MULTI_HIT => '_SHOW',
    COLS_NAME  => 1,
  });

  return 0 if ($#{$users_list} < 0);

  my $uid = $users_list->[0]{uid};
  my $fio = $users_list->[0]{fio};
  my $login = $users_list->[0]{login};
  #my $email = $users_list->[0]{email};

  print qq{
    { 
      "customerData" : {
        "assignedToEmployeeNumber" : "901",
        "linkToCrmTitle" : "Перейти в биллинг",
        "linkToCrmUrl" : "$host/admin/index.cgi?index=15&UID=$uid",
        "name" : "$fio ($login)"
      }
    }
  };

  return 1;
}

#**********************************************************
=head2 _process_data()

=cut
#**********************************************************
sub _process_data {
  my $self = shift;
  my $env = shift;
  #my ($server_name) = @_;

  $host .= $env->{'REQUEST_SCHEME'} . '://' if ($env->{'REQUEST_SCHEME'});
  $host .= $env->{'HTTP_HOST'} if ($env->{'HTTP_HOST'});

  if ($env->{'REQUEST_METHOD'} eq "POST") {
    my $buffer = '';

    read(STDIN, $buffer, $env->{'CONTENT_LENGTH'});
    if ($self->{debug}) {
      `echo '$buffer' >> /tmp/callcenter.log`;
    }

    my ($number) = $buffer =~ m/callDetails%5BexternalNumber%5D=([0-9]+)/g;
    my ($queryType) = $buffer =~ m/requestType=(apiCallSettings|apiCallCompleted)/g;

    if ($queryType eq 'apiCallSettings') {
      ($number) = $buffer =~ m/externalNumber=([0-9]+)/g;
    }

    exit 0 unless ($number && $queryType);

    if ($queryType && $queryType eq 'apiCallCompleted') {
      print(qq{ { "status" : "success" } });
    }

    if ($number) {
      if ($queryType eq 'apiCallSettings') {
        _send_users_service($number);
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 _get_logging_time()

=cut
#**********************************************************
sub _get_logging_time {
  my ($sec, $min, $hour, $mday, $mon, $year, undef, undef, undef) = localtime(time);

  my $nice_timestamp = sprintf("%04d%02d%02d %02d:%02d:%02d",
    $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

  return $nice_timestamp;
}

1;
