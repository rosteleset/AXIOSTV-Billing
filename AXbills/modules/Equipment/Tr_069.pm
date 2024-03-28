=head1 NAME

  Tr-069 service

=cut

use strict;
use warnings;
use AXbills::Base qw(load_pmodule);

our (
  %lang,
  %html_color,
  %conf
);

our AXbills::HTML $html;
our Equipment $Equipment;

my $json_load_error = load_pmodule("JSON", { RETURN => 1 });
if ($json_load_error) {
  print $json_load_error;
  return 1;
}
else {
  require JSON;
  JSON->import(qw/to_json from_json/);
}

my $CURL = $conf{FILE_CURL} || '/usr/bin/curl';
my @cpe_sys_info = ();
my $wifi_ssid = $conf{TR069_WLAN_SSID} || 'AXbills';

my $default_wan_settings = $conf{TR069_WAN_SETTINGS} ||
  [ { connect_type => 'ipoe',
    service_list   => 'INTERNET',
    vlan           => ($conf{INTERNET_USER_VLAN} || '101'),
    nat            => '1',
    ppp_user       => '',
    ppp_pass       => '' } ];

my $default_wlan_settings = $conf{TR069_WLAN_SETTINGS} ||
  [ { ssid    => '',
    wlan_pass => '' } ];

my $default_voip_settings = $conf{TR069_VOIP_SETTINGS} ||
  { status      => '0',
    server      => '',
    port        => '5060',
    voip_user   => '',
    voip_pass   => '',
    voip_number => '' };

my $default_settings = { wan => $default_wan_settings,
  wlan                       => $default_wlan_settings,
  voip                       => $default_voip_settings };

#**********************************************************
=head2 tr_069_presets($attr) - TR-069 Presets

=cut
#**********************************************************
sub tr_069_presets {
  my ($attr) = @_;
  $attr->{COLLECTION} = 'presets';
  $FORM{COLLECTION} = 'Presets';
  $attr->{PROJECTION} = ([
    '_id'
  ]);
  my $provisions_list = tr_069_get_data($attr);
  foreach my $provision (@{$provisions_list}) {
    my $id = $provision->{'_id'};
    $attr->{COLLECTION_IDS} .= $html->li($html->button($id, "index=$index&_id=$id"),
      { class => ($id eq $FORM{'_id'}) ? 'active' : '' });
  }
  $attr->{COLLECTION_IDS} .= $html->li($html->button('<span class="text-green">Add NEW Preset</span>', "index=$index&add_form=1"),
    { class => ($FORM{'add'}) ? 'active' : '' });
  $html->tpl_show(_include('equipment_script_editor', 'Equipment'), { %FORM, %{$attr} });
}

#**********************************************************
=head2 tr_069_provisions($attr) - TR-069 Provisions

=cut
#**********************************************************
sub tr_069_provisions {
  my ($attr) = @_;

  return 0 if (!$conf{TR069_SERVER});
  $FORM{script} =~ s/\\//g if $FORM{script};

  if ($FORM{add}) {
    if (!tr_069_set_data({ PATCH => 'provisions/' . $FORM{_id} . '/', METOD => 'PUT', DATA => '', DEBUG => 0 })) {
      delete $FORM{_id};
    }
  }
  elsif ($FORM{save}) {
    if (tr_069_set_data({ PATCH => 'provisions/' . $FORM{_id} . '/', METOD => 'PUT', DATA => $FORM{script}, DEBUG => 0 })) {
      delete $FORM{script};
    }
  }
  elsif ($FORM{del}) {
    if (tr_069_set_data({ PATCH => 'provisions/' . $FORM{_id} . '/', METOD => 'DELETE' })) {
      delete $FORM{_id};
      delete $FORM{script};
    }
  }

  $attr->{COLLECTION} = 'provisions';
  $FORM{COLLECTION} = 'Provision';
  $attr->{PROJECTION} = ([
    '_id'
  ]);
  my $provisions_list = tr_069_get_data($attr);
  foreach my $provision (@{$provisions_list}) {
    my $id = $provision->{'_id'};
    $attr->{COLLECTION_IDS} .= $html->li($html->button($id, "index=$index&_id=$id"),
      { class => ($id eq $FORM{'_id'}) ? 'active' : '' });
  }
  my $provisions_data = '';
  #my $script_html = '';
  my $del_btn = $html->button($lang{DEL},
    "index=$index&_id=$FORM{_id}&del=1",
    { MESSAGE => "$lang{DEL} Provision: $FORM{_id}?", class => 'btn btn-danger' }) if $FORM{_id};
  my $script = '';
  if ($FORM{save} && $FORM{script}) {
    $attr->{HTML_CONTENT} = $html->tpl_show(_include('equipment_script', 'Equipment'),
      { %FORM, DEL_BTN => $del_btn }, { OUTPUT2RETURN => 1 });
    $script = $FORM{script};
  }
  elsif ($FORM{add_form}) {
    $attr->{HTML_CONTENT} = $html->tpl_show(_include('equipment_add_collection', 'Equipment'), { %FORM }, { OUTPUT2RETURN => 1 });
  }
  elsif ($FORM{_id}) {
    $attr->{QUERY} = ({ '_id' => $FORM{_id} });
    push @{$attr->{PROJECTION}}, 'script';

    $provisions_data = tr_069_get_data($attr);
    $attr->{HTML_CONTENT} = $html->tpl_show(_include('equipment_script', 'Equipment'),
      { %{$provisions_data->[0]}, DEL_BTN => $del_btn }, { OUTPUT2RETURN => 1 });
    $script = $provisions_data->[0]->{script};
  }

  $attr->{COLLECTION_IDS} .= $html->li($html->button('<span class="text-green">Add NEW Provision</span>', "index=$index&add_form=1"),
    { class => ($FORM{'add'}) ? 'active' : '' });
  $attr->{HTML_CONTENT} =~ s/__SCRIPT__/$script/g;
  $html->tpl_show(_include('equipment_script_editor', 'Equipment'), { %FORM, %{$attr} });

  return 1;
}

#**********************************************************
=head2 tr_069_faults($attr) - TR-069 Faults

=cut
#**********************************************************
sub tr_069_faults {
  my ($attr) = @_;
  $attr->{COLLECTION} = 'faults';
  if ($FORM{del}) {
    tr_069_set_data({ PATCH => 'faults/' . $FORM{del} . '/', METOD => 'DELETE' });
  }
  my $faults_list = tr_069_get_data($attr);

  my @key_names = ('Device', 'Channel', 'Code', 'Message', 'Detail', 'Retries', 'Date', '');
  my @faults_rows = ();
  foreach my $line (@{$faults_list}) {
    my @row = ();
    foreach my $key (@key_names) {
      if ($key eq 'Date') {
        my $date_ = $line->{timestamp} || q{};
        $date_ =~ s/^([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9]{2}:[0-9]{2}:[0-9]{2}).*$/$1 $2/;
        push @row, $date_;
      }
      elsif (defined($line->{ lc($key) })) {
        if ($key eq 'Detail') {
          my $describe = '';
          foreach my $key_ (sort keys %{$line->{ lc($key) }}) {
            $describe .= uc($key_) . ": ";
            my $val = $line->{ lc($key) }->{$key_};
            if (ref $val eq 'ARRAY') {
              $describe .= "[";
              foreach my $line_ (@{$val}) {
                $describe .= "{";
                foreach my $key__ (sort keys %{$line_}) {
                  $describe .= '\'' . $key__ . '\': \'' . $line_->{$key__} . '\',';
                }
                $describe .= "}";
              }
              $describe .= "] " . $html->br();
            }
            else {
              $describe .= $val . $html->br();
            }
          }
          my $text = $describe;
          $text =~ s/<\/br>//g;
          $text =~ s/\n//g;
          $text =~ s/^(.{20}).*/$1\.\.\./g;
          my $em = $html->element('span', $text, { 'data-tooltip' => $describe, 'data-tooltip-position' => 'left' });
          push @row, $em;
        }
        else {
          push @row, $line->{ lc($key) };
        }
      }
    }

    my $del_btn = $html->button('', "index=$index&del=" . (($line->{_id}) ? $line->{_id} : q{}),
      { MESSAGE => "$lang{DEL} Fault?", ICON => 'fa fa-trash text-danger' });

    push @row, $del_btn;
    push @faults_rows, \@row;
  }

  my $table = $html->table({ title => \@key_names, rows => \@faults_rows });

  print $table->show();

  return 1;
}
#**********************************************************
=head2 tr_069_main($attr)

=cut
#**********************************************************
sub tr_069_main {

  if ($FORM{API_KEY} && ((!$FORM{json} && !$FORM{header}) || !$FORM{xml})) {
    tr_069_api();
  }
  elsif ($FORM{onu_info}) {
    tr_069_cpe_info($FORM{tr_069_id});
  }
  elsif ($FORM{onu_setting}) {
    tr_069_cpe_setting($FORM{info_pon_onu});
  }

  return;
}
#**********************************************************
=head2 tr_069_cpe_setting($id, $attr) - Devaice setting

=cut
#**********************************************************
sub tr_069_cpe_setting {
  my ($id) = @_;

  my $json = JSON->new->allow_nonref;

  my $new_settings = ($FORM{sub_menu}) ? $default_settings->{ $FORM{menu} }->[ $FORM{sub_menu} - 1 ] : $default_settings->{ $FORM{menu} };
  foreach my $key (keys %{$new_settings}) {
    $new_settings->{ $key } = $FORM{ $key } if ($FORM{ $key });
  }

  my $settings_list = $Equipment->tr_069_settings_list({
    ONU_ID    => $id,
    SETTINGS  => '_SHOW',
    COLS_NAME => 1
  });

  my $onu_setting_json = $settings_list->[0]->{settings} || "{}";
  my $onu_setting = $json->decode($onu_setting_json);
  if ($FORM{sub_menu}) {
    $onu_setting->{ $FORM{menu} }->[ $FORM{sub_menu} - 1 ] = $new_settings;
  }
  else {
    $onu_setting->{ $FORM{menu} } = $new_settings;
  }

  my $settings = JSON::to_json($onu_setting, { utf8 => 0 });
  $Equipment->tr_069_settings_change($id, { SETTINGS => $settings });

  tr_069_cpe_info($FORM{tr_069_id});
  return 1;
}

#**********************************************************
=head2 tr_069_cpe_info($id, $attr) - Devaices info

=cut
#**********************************************************
sub tr_069_cpe_info {
  my ($id, $attr) = @_;
  my $html_content = '';
  my $json = JSON->new->allow_nonref;

  my $settings_list = $Equipment->tr_069_settings_list({
    ONU_ID     => $FORM{info_pon_onu},
    CHANGETIME => '_SHOW',
    UPDATETIME => '_SHOW',
    SETTINGS   => '_SHOW',
    COLS_NAME  => 1
  });

  my $onu_setting_json = $settings_list->[0]->{settings} || "{}";
  $attr->{SETTINGS} = $json->decode($onu_setting_json);

  $attr->{OUTPUT2RETURN} = 1 if (!$FORM{sub_menu} || $FORM{change});
  my $menu = $FORM{menu} || 'status';
  my $menu_fn = 'tr_069_' . $menu;

  if (defined(&{$menu_fn})) {
    $html_content = &{\&$menu_fn}($id, $attr);
  }
  if (!$FORM{menu}) {
    $html->tpl_show(_include('equipment_tr_069_cpe_main', 'Equipment'), { HTML_CONTENT => $html_content, %FORM });
  }
  elsif (!$FORM{sub_menu}) {
    print $html_content;
  }
}

#**********************************************************
=head2 tr_069_api($attr) - Api

=cut
#**********************************************************
sub tr_069_api {

  my $json = JSON->new->allow_nonref;

  my $wifi_key = $FORM{serial};
  $wifi_key =~ s/^[A-F0-9]{8}//g;
  my $settings_list = $Equipment->tr_069_settings_list({
    #    NAS_NAME        => $FORM{oltName},
    SERIAL          => $FORM{serial},
    ONU_ID          => '_SHOW',
    UNIX_CHANGETIME => '_SHOW',
    UNIX_UPDATETIME => '_SHOW',
    SETTINGS        => '_SHOW',
    COLS_NAME       => 1
  });

  my $onu_setting_json = $settings_list->[0]->{settings} || "{}";
  my $onu_setting = $json->decode($onu_setting_json);

  if ($settings_list->[0]->{unix_changetime} && $settings_list->[0]->{unix_updatetime} && $settings_list->[0]->{unix_changetime} >= $settings_list->[0]->{unix_updatetime}) {
    $onu_setting->{ reconfigure } = 1;
    $Equipment->tr_069_settings_change($settings_list->[0]->{onu_id}, { UPDATE => 1 }) if (!$FORM{wlan});
  }

  foreach my $key (keys %{$default_settings}) {
    $onu_setting->{ $key } ||= $default_settings->{ $key };
  }

  if ($wifi_ssid) {
    $wifi_key = $FORM{serial};
    $wifi_key =~ s/^[A-F0-9]{8}//g;
    $onu_setting->{wlan}->[0]->{ssid} ||= $wifi_ssid . '-' . $wifi_key;
  }

  print "Content-Type: application/json\n\n";
  print JSON::to_json($onu_setting, { utf8 => 0 });

  return 1;
}

#**********************************************************
=head2 tr_069_set_data($attr)

=cut
#**********************************************************
sub tr_069_set_data {
  my ($attr) = @_;
  my $patch = $attr->{PATCH} || '';
  my $port = $conf{TR069_PORT} || '7557';
  my $http = ($conf{TR069_SSL}) ? 'https' : 'http';
  my $request_url = $attr->{REQUEST_URL} || $http . '://' . $conf{TR069_SERVER} . ':' . $port . '/' . $patch;

  if ($attr->{ACTION}) {
    $request_url .= '?' . $attr->{ACTION}
  }

  my $metod = '';
  if ($attr->{METOD}) {
    $metod .= ' -X ' . $attr->{METOD};
    if (defined($attr->{DATA})) {
      $attr->{DATA} =~ s/"/\\"/g;
      $metod .= " --data \"" . $attr->{DATA} . "\"";
    }
  }

  my $request_cmd = qq{ $CURL -m 10 -s "$request_url" $metod };
  my $result = `$request_cmd`;

  if ($attr->{DEBUG}) {
    print "=====REQUEST=====<br>\n";
    print "<textarea cols=90 rows=10>$request_cmd</textarea><br>\n";
    print "=====RESPONCE=====<br>\n";
    print "<textarea cols=90 rows=15>$result</textarea>\n";
  }

  if (!$result) {
    $html->message('info', $lang{INFO}, $lang{CHANGED});
    return 1;
  }
  else {
    $html->message('err', $lang{ERROR}, $result);
    return 0;
  }
  #  return [{}] if (!$attr->{REQUEST_URL} && !$conf{TR069_SERVER});
}

#**********************************************************
=head2 tr_069_get_data($attr)

=cut
#**********************************************************
sub tr_069_get_data {
  my ($attr) = @_;

  return [ {} ] if (!$attr->{REQUEST_URL} && !$conf{TR069_SERVER});

  my $json = JSON->new->allow_nonref;
  my $collection = $attr->{COLLECTION} || 'devices';
  my $port = $conf{TR069_PORT} || '7557';
  my $http = ($conf{TR069_SSL}) ? 'https' : 'http';
  my $request_url = $attr->{REQUEST_URL} || $http . '://' . $conf{TR069_SERVER} . ':' . $port . '/' . $collection . '/';
  my $query = 'query={';

  foreach my $key (keys %{$attr->{QUERY}}) {
    $query .= '"' . $key . '"%3A"' . $attr->{QUERY}->{$key} . '"';
  }

  $query =~ s/""/","/g;
  $query .= '}';
  $request_url .= '?' . $query;

  if ($attr->{PROJECTION}) {
    my @projektoin = ();
    foreach my $line (sort @{$attr->{PROJECTION}}) {
      push @projektoin, $line;
    }
    $request_url .= '&projection=' . join(',', @projektoin);
  }

  $request_url =~ s/ /%20/g;
  $request_url =~ s/"/%22/g;
  $request_url =~ s/,/%2C/g;
  $request_url =~ s/{/%7B/g;
  $request_url =~ s/}/%7D/g;

  my $request_cmd = qq{ $CURL -m 10 -s "$request_url" };
  my $result = `$request_cmd`;

  if ($attr->{DEBUG}) {
    print "=====REQUEST=====<br>\n";
    print "<textarea cols=90 rows=10>$request_cmd</textarea><br>\n";
    print "=====RESPONCE=====<br>\n";
    print "<textarea cols=90 rows=15>$result</textarea>\n";
  }
  $result ||= '[]';

  if ($result =~ /SyntaxError/) {
    $html->message('error', $lang{ERROR}, $result
      . "\n" .
      $html->pre($request_url)
    );
    return [ {} ];
  }

  my $perl_scalar = $json->decode($result);

  return $perl_scalar;
}

#**********************************************************
=head2 tr_069_status_device($id, $attr) - Device Status

=cut
#**********************************************************
sub tr_069_status_device {
  my ($id, $attr) = @_;
  $attr->{QUERY} = ({ '_id' => $id });
  $attr->{PROJECTION} = ([
    'InternetGatewayDevice.DeviceInfo',
  ]);
  my $device_data = tr_069_get_data($attr);
  my @hash_names = (
    'InternetGatewayDevice.DeviceInfo.SpecVersion',
    'InternetGatewayDevice.DeviceInfo.HardwareVersion',
    'InternetGatewayDevice.DeviceInfo.SoftwareVersion',
    'InternetGatewayDevice.DeviceInfo.Manufacturer',
    'InternetGatewayDevice.DeviceInfo.ModelName',
    'InternetGatewayDevice.DeviceInfo.Description',
    'InternetGatewayDevice.DeviceInfo.ProductClass',
    'InternetGatewayDevice.DeviceInfo.SerialNumber',
    'InternetGatewayDevice.DeviceInfo.AdditionalSoftwareVersion'
  );
  tr_069_hash_extract($device_data->[0], { HASH_NAMES => \@hash_names }, []);

  my $table = tr_069_table({ rows => \@cpe_sys_info });

  if ($attr->{OUTPUT2RETURN}) {
    return $table;
  }
  else {
    print $table;
  }

  return;
}

#**********************************************************
=head2 tr_069_status_wan($id, $attr) - WAN Status

=cut
#**********************************************************
sub tr_069_status_wan {
  my ($id, $attr) = @_;

  $attr->{QUERY} = ({ '_id' => $id });
  $attr->{PROJECTION} = ([
    'InternetGatewayDevice.WANDevice.1.WANConnectionDevice',
  ]);

  my $device_data = tr_069_get_data($attr);
  my @key_names = ('Name', 'ExternalIPAddress', 'X_HW_SERVICELIST', 'X_HW_VLAN');
  my @hash_names = (
    'InternetGatewayDevice.WANDevice.1.WANConnectionDevice.[0-9].WANIPConnection.[0-9]',
    'InternetGatewayDevice.WANDevice.1.WANConnectionDevice.[0-9].WANPPPConnection.[0-9]'
  );
  tr_069_hash_extract($device_data->[0], { HASH_NAMES => \@hash_names, KEY_NAMES => \@key_names }, []);
  print tr_069_table({ title => \@key_names, rows => \@cpe_sys_info });

}
#**********************************************************
=head2 tr_069_status_wlan($id, $attr) - WLAN Status

=cut
#**********************************************************
sub tr_069_status_wlan {
  my ($id, $attr) = @_;

  $attr->{QUERY} = ({ '_id' => $id });
  $attr->{PROJECTION} = ([
    'InternetGatewayDevice.LANDevice.1.WLANConfiguration',
  ]);

  my $device_data = tr_069_get_data($attr);
  my @key_names = ('Name', 'SSID', 'BSSID', 'X_HW_RFBand', 'Status');
  my @hash_names = ('InternetGatewayDevice.LANDevice.1.WLANConfiguration.[0-9]');
  tr_069_hash_extract($device_data->[0], { HASH_NAMES => \@hash_names, KEY_NAMES => \@key_names }, []);
  print tr_069_table({ title => \@key_names, rows => \@cpe_sys_info });

  return 1;
}

#**********************************************************
=head2 tr_069_status_voip($id, $attr) - VoIP Status

=cut
#**********************************************************
sub tr_069_status_voip {
  my ($id, $attr) = @_;
  $attr->{QUERY} = ({ '_id' => $id });
  $attr->{PROJECTION} = ([
    'InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1',
  ]);
  my $device_data = tr_069_get_data($attr);
  my @hash_names = (
    'InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.SIP.ProxyServer',
    'InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.SIP.ProxyServerPort',
    'InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.SIP.RegistrarServer',
    'InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.SIP.RegistrarServerPort',
    #  'InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.RTP.X_HW_PortName',
    'InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.X_HW_PortName',
  );
  tr_069_hash_extract($device_data->[0], { HASH_NAMES => \@hash_names }, []);

  print tr_069_table({ rows => \@cpe_sys_info });
  @cpe_sys_info = ();

  my @key_names = ('SIP.AuthUserName', 'SIP.AuthPassword', 'DirectoryNumber', 'Status', 'Enable');
  @hash_names = ('InternetGatewayDevice.Services.VoiceService.1.VoiceProfile.1.Line.[0-9]');
  tr_069_hash_extract($device_data->[0], { HASH_NAMES => \@hash_names, KEY_NAMES => \@key_names }, []);

  print tr_069_table({ title => \@key_names, rows => \@cpe_sys_info });

  return 1;
}

#**********************************************************
=head2 tr_069_status_security($id, $attr) - Security Status

=cut
#**********************************************************
sub tr_069_status_security {
  my ($id, $attr) = @_;

  $attr->{QUERY} = ({ '_id' => $id });
  $attr->{PROJECTION} = ([
    'InternetGatewayDevice.X_HW_Security.AclServices',
  ]);
  my $device_data = tr_069_get_data($attr);
  my @hash_names = (
    'InternetGatewayDevice.X_HW_Security.AclServices.SamBaWanEnable',
    'InternetGatewayDevice.X_HW_Security.AclServices.SamBaLanEnable',
    'InternetGatewayDevice.X_HW_Security.AclServices.SSHWanEnable',
    'InternetGatewayDevice.X_HW_Security.AclServices.SSHLanEnable',
    'InternetGatewayDevice.X_HW_Security.AclServices.TELNETWanEnable',
    'InternetGatewayDevice.X_HW_Security.AclServices.TELNETLanEnable',
    'InternetGatewayDevice.X_HW_Security.AclServices.FTPWanEnable',
    'InternetGatewayDevice.X_HW_Security.AclServices.FTPLanEnable',
    'InternetGatewayDevice.X_HW_Security.AclServices.HTTPWanEnable',
    'InternetGatewayDevice.X_HW_Security.AclServices.HTTPLanEnable',
  );
  tr_069_hash_extract($device_data->[0], { HASH_NAMES => \@hash_names }, []);

  print tr_069_table({ rows => \@cpe_sys_info });

  return 1;
}

#**********************************************************
=head2 tr_069_status_hosts($id, $attr) - Hosts Status

=cut
#**********************************************************
sub tr_069_status_hosts {
  my ($id, $attr) = @_;

  $attr->{QUERY} = ({ '_id' => $id });
  $attr->{PROJECTION} = ([
    'InternetGatewayDevice.LANDevice.1.Hosts.Host',
  ]);

  my $device_data = tr_069_get_data($attr);
  my @key_names = ('HostName', 'IPAddress', 'MACAddress', 'AddressSource');
  my @hash_names = ('InternetGatewayDevice.LANDevice.1.Hosts.Host.[0-9]+');
  tr_069_hash_extract($device_data->[0], { HASH_NAMES => \@hash_names, KEY_NAMES => \@key_names }, []);
  print tr_069_table({ title => \@key_names, rows => \@cpe_sys_info });

  return 1;
}

#**********************************************************
=head2 tr_069_status_neighbor_ap($id, $attr) - Neighbor AP Status

=cut
#**********************************************************
sub tr_069_status_neighbor_ap {
  my ($id, $attr) = @_;

  $attr->{QUERY} = ({ '_id' => $id });
  $attr->{PROJECTION} = ([
    'InternetGatewayDevice.LANDevice.1.WiFi.Radio.1.X_HW_NeighborAP',
  ]);

  my $device_data = tr_069_get_data($attr);
  my @key_names = ('SSID', 'BSSID', 'RSSI', 'Security', 'Channel');
  my @hash_names = ('InternetGatewayDevice.LANDevice.1.WiFi.Radio.1.X_HW_NeighborAP.[0-9]+');
  tr_069_hash_extract($device_data->[0], { HASH_NAMES => \@hash_names, KEY_NAMES => \@key_names }, []);
  print tr_069_table({ title => \@key_names, rows => \@cpe_sys_info });

  return 1;
}

#**********************************************************
=head2 tr_069_status($id, $attr) - Status

=cut
#**********************************************************
sub tr_069_status {
  my ($id, $attr) = @_;
  my $html_content = '';
  my $sub_menu = $FORM{sub_menu} || 'device';

  my $menu_fn = 'tr_069_status_' . $sub_menu;

  if (defined(&{$menu_fn})) {
    $html_content = &{\&$menu_fn}($id, $attr);
  }

  if (!$FORM{sub_menu}) {
    my $sub_menu_items = $html->button('Device information', '#', { class => 'nav-link active', ID => 'device' })
      . $html->button('WAN information', '#', { class => 'nav-link', ID => 'wan' })
      . $html->button('WLAN information', '#', { class => 'nav-link', ID => 'wlan' })
      . $html->button('VoIP information', '#', { class => 'nav-link', ID => 'voip' })
      . $html->button('Security information', '#', { class => 'nav-link', ID => 'security' })
      . $html->button('Hosts information', '#', { class => 'nav-link', ID => 'hosts' });
    #      . $html->button('Neighbor AP information', '#', { class => 'nav-link', ID => 'neighbor_ap' });

    return $html->tpl_show(_include('equipment_tr_069_cpe_menu', 'Equipment'), { HTML_CONTENT => $html_content, MENU => 'status', SUB_MENU_CONTENT => $sub_menu_items, %FORM }, $attr);
  }

}


#**********************************************************
=head2 tr_069_wan($id, $attr) - Wan Setting

=cut
#**********************************************************
sub tr_069_wan {
  my ($id, $attr) = @_;
  my $html_content = '';
  my $sub_menu = $FORM{sub_menu} || '1';
  my $wans_info = $attr->{SETTINGS}->{wan} || $default_settings->{ wan };
  my $wan_info = $wans_info->[$sub_menu - 1];

  $FORM{CONNECT_TYPE_SEL} = $html->form_select('connect_type', {
    SELECTED => $wan_info->{connect_type} || '',
    SEL_HASH => { ipoe => 'IPoE', pppoe => 'PPPoE' },
    NO_ID    => 1
  });

  $FORM{SERVICE_LIST_SEL} = $html->form_select('service_list', {
    SELECTED  => $wan_info->{service_list} || '',
    SEL_ARRAY => [ 'INTERNET' ],
  });

  $FORM{NAT_SEL} = $html->form_select('nat', {
    SELECTED => $wan_info->{nat} || '',
    SEL_HASH => { 1 => 'Enable', 0 => 'Disable' },
    NO_ID    => 1
  });

  $html_content = $html->tpl_show(_include('equipment_tr_069_cpe_wan', 'Equipment'),
    { %FORM, %{$wan_info},
      USERNAMEREGEXP      => $conf{USERNAMEREGEXP},
      MAX_USERNAME_LENGTH => $conf{MAX_USERNAME_LENGTH},
      sub_menu            => $sub_menu }, $attr);

  $attr->{OUTPUT2RETURN} = 0 if ($FORM{change});
  if (!$FORM{sub_menu} || $FORM{change}) {
    my $sub_menu_items = '';
    my $i = 1;
    foreach my $wan (@{$wans_info}) {
      $sub_menu_items .= $html->button(($i + 1) . '_' . $wan->{service_list} . '_R_VID_' . $wan->{vlan}, '#', { class => ($i eq $sub_menu) ? 'nav-link active' : 'nav-link', ID => $sub_menu });
      $i++;
    }
    return $html->tpl_show(_include('equipment_tr_069_cpe_menu', 'Equipment'), { HTML_CONTENT => $html_content, MENU => 'wan', SUB_MENU_CONTENT => $sub_menu_items, %FORM }, $attr);
  }
}


#**********************************************************
=head2 tr_069_wlan($id, $attr) - WLAN Setting

=cut
#**********************************************************
sub tr_069_wlan {
  my ($id, $attr) = @_;
  my $html_content = '';
  my $sub_menu = $FORM{sub_menu} || '1';
  my $wlans_info = $attr->{SETTINGS}->{wlan} || $default_settings->{ wlan };
  my $wlan_info = $wlans_info->[$sub_menu - 1];

  if (!$wlan_info->{ssid} && $wifi_ssid) {
    if ($id =~ /-[0-9A-F]{8}([0-9A-F]{8})$/) {
      $wlan_info->{ssid} = $wifi_ssid . '-' . $1;
    }
  }
  $html_content = $html->tpl_show(_include('equipment_tr_069_cpe_wlan', 'Equipment'),
    { %FORM, %{$wlan_info},
      sub_menu => $sub_menu }, $attr);

  $attr->{OUTPUT2RETURN} = 0 if ($FORM{change});
  if (!$FORM{sub_menu} || $FORM{change}) {
    my $sub_menu_items = '';
    my $i = 1;
    foreach my $wlan (@{$wlans_info}) {
      if ($wlan->{ssid}) {
        $sub_menu_items .= $html->button(($i) . '_' . $wlan->{ssid}, '#', { class => ($i eq $sub_menu) ? 'nav-link active' : 'nav-link', id => $sub_menu });
      }
      $i++;
    }
    return $html->tpl_show(_include('equipment_tr_069_cpe_menu', 'Equipment'), { HTML_CONTENT => $html_content, MENU => 'wlan', SUB_MENU_CONTENT => $sub_menu_items, %FORM }, $attr);
  }

}


#**********************************************************
=head2 tr_069_voip($id, $attr) - VoIP Setting

=cut
#**********************************************************
sub tr_069_voip {
  my ($id, $attr) = @_;
  #my $json = JSON->new->allow_nonref;
  my $html_content = '';
  my $sub_menu = $FORM{sub_menu} || '';
  my $voip_info = $attr->{SETTINGS}->{voip} || $default_settings->{ voip };

  $FORM{STATUS_SEL} = $html->form_select('status', {
    SELECTED => $voip_info->{status} || '',
    SEL_HASH => { 1 => 'Enable', 0 => 'Disable' },
    NO_ID    => 1
  });

  $FORM{SERVER_FORM} = "<input type='text' name='server' value='$voip_info->{server}' class='form-control ip-input' ID='server'/>";

  if ($conf{TR069_VOIP_SERVERS}) {
    $conf{TR069_VOIP_SERVERS} =~ s/[\n\s]//g;
    my @servers_arr = split(/;/, $conf{TR069_VOIP_SERVERS});
    my %servers_hash = ();
    my $sel_data = { SEL_ARRAY => \@servers_arr };
    foreach my $server (@servers_arr) {
      if ($server =~ /.+:.+/) {
        my ($s_name, $s_ip) = split(/:/, $server, 2);
        $servers_hash{$s_ip} = "($s_name)";
      }
    }
    if (%servers_hash) {
      $sel_data = { SEL_HASH => \%servers_hash };
    }
    $FORM{SERVER_FORM} = $html->form_select('server', {
      SELECTED => $voip_info->{server} || '',
      %{$sel_data}
    });
  }

  $html_content = $html->tpl_show(_include('equipment_tr_069_cpe_voip', 'Equipment'),
    { %FORM, %{$voip_info},
      USERNAMEREGEXP      => $conf{USERNAMEREGEXP},
      MAX_USERNAME_LENGTH => $conf{MAX_USERNAME_LENGTH},
      sub_menu            => $sub_menu }, $attr);

  $attr->{OUTPUT2RETURN} = 0 if ($FORM{change});
  if (!$FORM{sub_menu} || $FORM{change}) {
    #my $sub_menu_items = '';
    return $html->tpl_show(_include('equipment_tr_069_cpe_menu', 'Equipment'), { HTML_CONTENT => $html_content, MENU => 'voip', %FORM }, $attr);
  }
}

#**********************************************************
=head2 tr_069_hash_extract($hash, $attr) -

=cut
#**********************************************************
sub tr_069_hash_extract {
  my ($hash, $attr, $arr) = @_;

  foreach my $hash_name (@{$attr->{HASH_NAMES}}) {
    my $hash_ = join('.', @$arr);
    if ($hash_ =~ /^$hash_name$/) {
      my @arr_ = ();
      if (!$attr->{KEY_NAMES} && defined($hash->{'_value'})) {
        push @arr_, $attr->{KEY};
        push @arr_, $hash->{'_value'};
      }
      else {
        foreach my $key (@{$attr->{KEY_NAMES}}) {
          if ($key =~ /^([0-9A-Za-z]+)\.([0-9A-Za-z]+)$/) {
            push @arr_, $hash->{ $1 }->{ $2 }->{'_value'};
          }
          else {
            push @arr_, $hash->{ $key }->{'_value'};
          }
        }
      }
      push @cpe_sys_info, \@arr_;
    }
  }
  foreach my $key (sort keys %$hash) {
    my $val = $hash->{$key};
    if (ref $val eq 'HASH') {
      push @$arr, $key;
      $attr->{KEY} = $key;
      tr_069_hash_extract($val, $attr, $arr);
      pop @$arr;
    }
  }

  return 1;
}


#**********************************************************
=head2 tr_069_table($attr)

=cut
#**********************************************************
sub tr_069_table {
  my ($attr) = @_;

  my $table = '<table class="table  table-bordered table-striped"><tbody>';
  if (defined($attr->{title})) {
    $table .= '<tr>';
    foreach my $line (@{$attr->{title}}) {
      $table .= '<th>' . $line . '</th>';
    }
    $table .= '</tr>';
  }

  if (defined($attr->{rows})) {
    foreach my $row (@{$attr->{rows}}) {
      $table .= '<tr>';
      foreach my $line (@$row) {
        $table .= '<td>' . $line . '</td>';
      }
      $table .= '</tr>';
    }
  }
  $table .= '</tbody></table>';

  return $table;
}

1
