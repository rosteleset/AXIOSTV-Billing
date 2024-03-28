=head1 ZABBIX_IMPORT

    Argument:
      USER        - Zabbix user login
      PASSWORD    - Zabbix user password

   zabbix_import();

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Fetcher qw(web_request);

our (
  %lang,
  $argv,
  %conf,
  $Admin,
  $db,
);

zabbix_import_get();

#**********************************************************
=head2 zabbix_import_auth()

=cut
#**********************************************************
sub zabbix_import_auth {

  my @header = "Content-Type: application/json-rpc";

  my $result_auth = zabbix_import_auth_mess({
    USER     => $argv->{USER},
    PASSWORD => $argv->{PASSWORD}
  });

  my $auth = web_request($conf{ZABBIX_URL_IMPORT} . 'zabbix/api_jsonrpc.php', {
    POST        => $result_auth,
    HEADERS     => \@header,
    CURL        => 1,
    JSON_RETURN => 1,
  });

  return $auth || qq{ };
}

#**********************************************************
=head2 zabbix_import_get()

=cut
#**********************************************************
sub zabbix_import_get {

  require Nas;
  Nas->import();
  my $Nas = Nas->new($db, $Admin, \%conf);

  my @header = "Content-Type: application/json-rpc";
  my $date_auth = zabbix_import_auth();

  my $date_info = zabbix_import_get_mess({
    USER_KEY => $date_auth->{result} || '',
    ID       => $date_auth->{id} || 0
  });

  my $auth = web_request($conf{ZABBIX_URL_IMPORT} . 'zabbix/api_jsonrpc.php', {
    POST        => $date_info,
    HEADERS     => \@header,
    CURL        => 1,
    JSON_RETURN => 1,
  });

  my $nas_list = $Nas->list({
    NAS_ID    => '_SHOW',
    NAS_IP    => '_SHOW',
    COLS_NAME => 1
  });

  if ($auth->{result} && ref $auth->{result} eq 'ARRAY') {
    foreach my $nas_result (@{$auth->{result}}) {
      foreach my $nas_ip (@{$nas_list}) {
        if ($nas_ip->{nas_ip} && ($nas_ip->{nas_ip} eq $nas_result->{interfaces}->[0]->{ip})) {
          $Nas->del($nas_ip->{nas_id}, 1);
          $Admin->system_action_add("NAS_ID:$nas_ip->{nas_id}", { TYPE => 10 });
        }
      }

      $Nas->add({
        NAS_NAME         => $nas_result->{name},
        IP               => $nas_result->{interfaces}->[0]->{ip},
        NAS_MNG_IP_PORT  => $nas_result->{interfaces}->[0]->{ip} . ':' . $nas_result->{interfaces}->[0]->{port},
        NAS_MNG_USER     => $argv->{USER},
        NAS_MNG_PASSWORD => $argv->{PASSWORD},
        ZABBIX_HOSTID    => $nas_result->{hostid},
        NAS_DISABLE      => $nas_result->{status},
        NAS_DESCRIBE     => $nas_result->{host},
        ACTION_ADMIN     => 1
      });

      $Admin->system_action_add("NAS_ID:$Nas->{NAS_ID}", { TYPE => 1 });
    }
  }

  return 0;
}

#**********************************************************
=head2 zabbix_import_auth_mess()

  Argument:
    USER        - Zabbix user login
    PASSWORD    - Zabbix user pass

  Returns:
    $request    - Request date

=cut
#**********************************************************
sub zabbix_import_auth_mess {
  my ($attr) = @_;
  my $request_params = qq{{
    "jsonrpc": "2.0",
      "method": "user.login",
      "params": {
          "user": "$attr->{USER}",
          "password": "$attr->{PASSWORD}"
      },
      "id": 1,
      "auth": null
  }};

  $request_params =~ s/\"/\\\"/g;

  return $request_params;
}

#**********************************************************
=head2 zabbix_import_get_mess()

  Argument:
    USER_KEY    - Token auth sesions
    ID          - Sesion ID

  Returns:
    $requst     - Request date

=cut
#**********************************************************
sub zabbix_import_get_mess {
  my ($attr) = @_;

  my $reques_get_info = qq{
    {
      "jsonrpc": "2.0",
      "method": "host.get",
      "params": {
         "output": [
             "hostid",
             "host",
             "name",
             "proxy_hostid",
             "status"
         ],
         "selectInterfaces": [
             "interfaceid",
             "ip",
             "main",
             "type",
             "useip",
             "dns",
             "bulk",
             "port"
         ],
         "selectInventory": [
             "os"
         ]
      },
      "auth": "$attr->{USER_KEY}",
      "id": $attr->{ID}
    }
  };

  $reques_get_info =~ s/\"/\\\"/g;

  return $reques_get_info;
}

1;