=head1 NAME

  billd plugin

  DESCRIPTION: PON auto registration/deregistration

  Supported OLTs: Huawei, ZTE, BDCOM

  Arguments:

    NAS_IDS - NAS IDs, separated by ';'
    BRANCHES - branches to operate on in format 'epon:1/1/1', separated by ';'
    FORCE_FILL_NAS - register even if abonent's NAS are already filled. NAS will be overwritten
    FORCE_FILL_NAS_AND_PORT - register even if abonent's NAS and Port are already filled. NAS and Port will be overwritten
    REGISTER_NOT_ATTACHED_TO_ABONENT - will register ONUs that are not attached to abonent by CPE MAC
    EXTRA_REG_PARAMS - extra params for registration script
    DEREGISTER - deregister all ONUs on specified branches. Must be used with NAS_IDS (only one NAS ID) and BRANCHES
    DEBUG - debug level

=cut

use strict;
use warnings;
use AXbills::Filters;
use SNMP_Session;
use SNMP_util;
use Equipment;
use Internet;
use Users;
use Events;
use Events::API;
use AXbills::Base qw(load_pmodule in_array check_time gen_time);
use FindBin '$Bin';

our $SNMP_TPL_DIR = $Bin . "/../AXbills/modules/Equipment/snmp_tpl/";

our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
  $OS,
  $var_dir,
);

my $json_load_error = load_pmodule("JSON", { RETURN => 1 });
if ($json_load_error) {
  print $json_load_error;
  return 1;
}
else {
  require JSON;
  JSON->import(qw/to_json from_json/);
}

our $Equipment = Equipment->new($db, $Admin, \%conf);
my $Internet = Internet->new($db, $Admin, \%conf);
my $Users = Users->new($db, $Admin, \%conf);
my $Events = Events::API->new($db, $Admin, \%conf);
do 'AXbills/Misc.pm';

require Equipment::Pon_mng;

my @nas_ids;
if ($argv->{NAS_IDS}) {
  @nas_ids = split(/;/, $argv->{NAS_IDS});
}

my @branches;
if ($argv->{BRANCHES}) {
  @branches = split (/;/, lc($argv->{BRANCHES}));
}
foreach my $branch_pattern (@branches) {
  $branch_pattern =~ s/\*/\.\*/g;
}

if ($argv->{BRANCHES} && @nas_ids != 1) {
  my $comments = "Error: there should be one NAS ID when using BRANCHES. Use billd equipment_auto_reg NAS_IDS=\"ID\" BRANCHES=\"BRANCH1;BRANCH2;...\"\n";
  print $comments;
  _generate_new_event("Error: should be one NAS ID", $comments);

  exit 1;
}
#tr_069_setting();
if ($argv->{DEREGISTER}) {
  _auto_deregister();
}
else {
  _auto_reg();
}

#**********************************************************
=head2 _auto_reg($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _auto_reg {
  #my ($attr) = @_;

  my $Equipment_list = $Equipment->_list({
    NAS_ID                        => $argv->{NAS_IDS} || '_SHOW',
    NAS_NAME                      => '_SHOW',
    MODEL_ID                      => '_SHOW',
    REVISION                      => '_SHOW',
    TYPE                          => '_SHOW',
    SYSTEM_ID                     => '_SHOW',
    NAS_TYPE                      => '_SHOW',
    MODEL_NAME                    => '_SHOW',
    VENDOR_NAME                   => '_SHOW',
    STATUS                        => '0',
    NAS_IP                        => '_SHOW',
    NAS_MNG_HOST_PORT             => '_SHOW',
    NAS_MNG_USER                  => '_SHOW',
    NAS_MNG_PASSWORD              => '_SHOW',
    SNMP_TPL                      => '_SHOW',
    LOCATION_ID                   => '_SHOW',
    SNMP_VERSION                  => '_SHOW',
    INTERNET_VLAN                 => '_SHOW',
    TR_069_VLAN                   => '_SHOW',
    IPTV_VLAN                     => '_SHOW',
    DEFAULT_ONU_REG_TEMPLATE_EPON => '_SHOW',
    DEFAULT_ONU_REG_TEMPLATE_GPON => '_SHOW',
    TYPE_NAME                     => '4',
    COLS_NAME                     => 1,
    COLS_UPPER                    => 1,
  });

  foreach my $nas (@$Equipment_list) {
    my $SNMP_COMMUNITY = "$nas->{nas_mng_password}\@" . (($nas->{nas_mng_ip_port}) ? $nas->{nas_mng_ip_port} : $nas->{nas_ip});

    if($SNMP_COMMUNITY =~ /(.+):(.+)/) {
      $SNMP_COMMUNITY = $1;
      my $SNMP_PORT = 161;
      $SNMP_COMMUNITY .= ':'.$SNMP_PORT;
    }

    $nas->{SNMP_COMMUNITY} = $SNMP_COMMUNITY;

    print "NAS_NAME: $nas->{NAS_NAME}, NAS_ID: $nas->{NAS_ID}\n" if ($debug);

    my $nas_type = equipment_pon_init($nas);
    my $unregister_fn = $nas_type . '_unregister';

    if ($debug > 6) {
      $Internet->{debug}=1;
      $Users->{debug}=1;
    }

    if (defined(&$unregister_fn)) {
      my $unregister_list = &{\&$unregister_fn}({ %$nas, NAS_INFO => $nas});

      foreach my $unreg_ont_info (@$unregister_list) {
        if ($argv->{BRANCHES}) {
          my $found_branch;
          my $current_branch = lc($unreg_ont_info->{pon_type} . ':' . $unreg_ont_info->{branch});

          foreach my $branch_pattern (@branches) {
            if ($current_branch =~ /^$branch_pattern$/) {
              $found_branch = 1;
            }
          }

          if (!$found_branch) {
            next;
          }
        }

        my $internet_list = [];
        my $internet_list1 = $Internet->user_list({
          INTERNET_ACTIVATE=> '_SHOW',
          INTERNET_STATUS  => '0',
          CPE_MAC          => $unreg_ont_info->{mac_serial} || $unreg_ont_info->{sn},
          COLS_NAME        => 1,
          PAGE_ROWS        => 10000000,
          NAS_ID           => '_SHOW',
          PORT             => '_SHOW',
          UID              => '_SHOW',
        });

        foreach my $ui (@$internet_list1) {
          push( @{$internet_list}, $ui );
        }

        if ((lc $unreg_ont_info->{pon_type}) eq 'gpon' && $unreg_ont_info->{vendor} && $unreg_ont_info->{mac_serial}) {
          $unreg_ont_info->{vendor_mac_serial} = $unreg_ont_info->{vendor} . $unreg_ont_info->{mac_serial};
          $unreg_ont_info->{vendor_mac_serial} =~ s/^([A-Z]{4})[A-F0-9]{8}/$1/g;

          my $internet_list2 = $Internet->user_list({
            INTERNET_ACTIVATE=> '_SHOW',
            INTERNET_STATUS  => '0',
            CPE_MAC          => $unreg_ont_info->{vendor_mac_serial},
            COLS_NAME        => 1,
            PAGE_ROWS        => 10000000,
            NAS_ID           => '_SHOW',
            PORT             => '_SHOW',
            UID              => '_SHOW',
          });

          foreach my $ui (@$internet_list2) {
            push( @{$internet_list}, $ui );
          }
        }

        my $ont_attached_to_abon = 0;

        foreach my $user_infos (@$internet_list) {
          if ($argv->{FORCE_FILL_NAS}) {
            delete $user_infos->{nas_id};
          }
          if ($argv->{FORCE_FILL_NAS_AND_PORT}) {
            delete $user_infos->{nas_id};
            delete $user_infos->{port};
          }

          if (!$user_infos->{nas_id} && !$user_infos->{port}) {
            my $user_info = $Users->list({
              UID       => $user_infos->{uid},
              LOGIN     => '_SHOW',
              COLS_NAME => 1,
              PAGE_ROWS => 10000000,
              %LIST_PARAMS
            });

            foreach my $key (keys %$unreg_ont_info) {
              $unreg_ont_info->{uc($key)} = $unreg_ont_info->{$key};
            }
            $unreg_ont_info->{ONU_DESC} = $user_info->[0]->{login};
            my $ont = _register_onu({
              NAS_INFO       => $nas,
              SNMP_COMMUNITY => $SNMP_COMMUNITY,
              BRANCH         => $unreg_ont_info->{branch},
              %{$unreg_ont_info}
            });

            my $triple_play_profile = $conf{HUAWEI_TRIPLE_LINE_PROFILE_NAME} || 'TRIPLE-PLAY';

            if ($ont) {
              if (($nas->{VENDOR_NAME} eq 'Huawei' || $nas->{VENDOR_NAME} eq 'ZTE')
                && $ont->{LINE_PROFILE} eq $triple_play_profile && $user_info->[0]->{_wifi_ssid} && $user_info->[0]->{_wifi_pass}) {
                tr_069_setting($ont->{DATABASE_ID}, $user_info->[0]);
              }

              $Internet->user_change({
                UID         => $user_infos->{uid},
                ID          => $user_infos->{id},
                CPE_MAC     => $unreg_ont_info->{mac_serial},
                NAS_ID      => $ont->{NAS_ID},
                PORT        => $ont->{ONU_DHCP_PORT},
                VLAN        => $ont->{VLAN},
                SERVER_VLAN => $ont->{SERVER_VLAN}
              });
            }
            last;
          }
        }

        if ($argv->{REGISTER_NOT_ATTACHED_TO_ABONENT} && !$ont_attached_to_abon) {
          foreach my $key (keys %$unreg_ont_info) {
            $unreg_ont_info->{uc($key)} = $unreg_ont_info->{$key};
          }

          my $ont = _register_onu({ NAS_INFO => $nas, SNMP_COMMUNITY => $SNMP_COMMUNITY, BRANCH => $unreg_ont_info->{branch},  %{$unreg_ont_info} });
        }
      }
    }
  }

  return 0;
}

#********************************************************
=head2 _register_onu($attr) - PON ONU registration

  Arguments:
    $attr
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub _register_onu {
  my ($attr) = @_;

  my $nas_id = $attr->{NAS_ID} || $attr->{NAS_INFO}->{NAS_ID};
  $attr->{VENDOR_NAME} = $attr->{NAS_INFO}->{VENDOR_NAME};
  $attr->{onu_registration} = 1;

  my $nas_type = equipment_pon_init($attr);

  my $cmd = $SNMP_TPL_DIR . '/register' . $nas_type . '_custom';
  $cmd = $SNMP_TPL_DIR . '/register' . $nas_type if (!-x $cmd);

  $attr->{NAS_INFO}{NAS_MNG_PASSWORD} = $conf{EQUIPMENT_OLT_PASSWORD} || $attr->{NAS_INFO}{NAS_MNG_PASSWORD};
  $attr->{NAS_INFO}{PROFILE} = $conf{EQUIPMENT_ONU_PROFILE} if ($conf{EQUIPMENT_ONU_PROFILE});
  $attr->{NAS_INFO}{ONU_TYPE} = $conf{EQUIPMENT_ONU_TYPE} if ($conf{EQUIPMENT_ONU_TYPE});

  my $port_list = $Equipment->pon_port_list({
    %$attr,
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    NAS_ID     => $nas_id
  });

  if (!$Equipment->{TOTAL}) {
    equipment_pon_get_ports({
      VERSION        => $attr->{NAS_INFO}->{snmp_version} || 1,
      SNMP_COMMUNITY => $attr->{NAS_INFO}->{SNMP_COMMUNITY},
      NAS_ID         => $nas_id,
      NAS_TYPE       => $nas_type,
      MODEL_NAME     => $attr->{NAS_INFO}->{MODEL_NAME},
      SNMP_TPL       => $attr->{NAS_INFO}->{SNMP_TPL},
    });

    $port_list = $Equipment->pon_port_list({
      %$attr,
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      NAS_ID     => $nas_id
    });
  }

  $attr->{VLAN_ID} = $port_list->[0]->{VLAN_ID} || $attr->{NAS_INFO}->{internet_vlan};
  if ($attr->{VENDOR_NAME} ne 'BDCOM' && !$attr->{VLAN_ID}) {
    my $comments = "Not exist Vlan ID\n";
    print $comments if ($debug);
    _generate_new_event('Not exist Vlan ID', $comments);

    return 0;
  }
  my $result = q{};
  my $result_code = '';

  my %extra_reg_params = ();
  if ($argv->{EXTRA_REG_PARAMS}) {
    %extra_reg_params = split (/ |\=/, $argv->{EXTRA_REG_PARAMS});
  }

  if ($attr->{VENDOR_NAME} eq 'ZTE') {
    if ($attr->{PON_TYPE}) {
      if ($attr->{PON_TYPE} eq 'epon') {
        my $onu_count = snmp_get({ #string like "1-22,28, 40-42,45-46,49, 52, 56, 60-62", ONU numbers
          %{$attr},
          OID => '.1.3.6.1.4.1.3902.1015.1010.1.7.16.1.7' . '.' . $attr->{BRANCH_NUM}
        });

        if ($onu_count =~ m/(\d+)(,|$)/) {
          my $free_llid = $1 + 1;

          if ($onu_count !~ m/^1(\-|\,|$)/g) {
            $attr->{LLID} = 1;
          }
          elsif ($free_llid != 65) {
            $attr->{LLID} = $free_llid;
          }
        }
      }
      elsif ($attr->{PON_TYPE} eq 'gpon') {
        $result = snmp_get({
          %{$attr},
          OID  => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5' . '.' . $attr->{BRANCH_NUM},
          WALK => 1,
        });

        my $next_llid = 1;

        foreach my $line (@$result) {
          print "$line<br>\n" if ($debug > 3);
          my ($id) = split(/:/, $line);
          if ($next_llid != $id) {
            last;
          }
          $next_llid++;
        }

        $attr->{LLID} = $next_llid;
      }

      if ($attr->{PON_TYPE} eq 'epon' && $attr->{NAS_INFO}->{DEFAULT_ONU_REG_TEMPLATE_EPON}) {
        $attr->{TEMPLATE} = $attr->{NAS_INFO}->{DEFAULT_ONU_REG_TEMPLATE_EPON};
      }
      elsif ($attr->{PON_TYPE} eq 'gpon' && $attr->{NAS_INFO}->{DEFAULT_ONU_REG_TEMPLATE_GPON}) {
        $attr->{TEMPLATE} = $attr->{NAS_INFO}->{DEFAULT_ONU_REG_TEMPLATE_GPON};
      }
      elsif ($conf{ZTE_DEFAULT_REGISTRATION_TEMPLATE_BY_PON_TYPE}->{$attr->{PON_TYPE}}) {
        $attr->{TEMPLATE} = $conf{ZTE_DEFAULT_REGISTRATION_TEMPLATE_BY_PON_TYPE}->{$attr->{PON_TYPE}};
      }
      else {
        $attr->{TEMPLATE} = "zte_registration_" . $attr->{PON_TYPE} . ".tpl";
      }
      if (-x $cmd) {
        my $params_for_cmd = { %$attr, %{$attr->{NAS_INFO}}, %extra_reg_params };
        $params_for_cmd = {map {(defined $params_for_cmd->{$_}) ? ($_ => $params_for_cmd->{$_}) : ()} keys %$params_for_cmd}; #cmd gives warning when there's undef in PARAMS
        foreach my $param_value (keys %$params_for_cmd) {
          next if (!$param_value);
          $param_value =~ s/\0//g;
          #Remove non anscii symbols params
          if ($params_for_cmd->{$param_value} !~ /^[a-z0-9,\.\s\-:\_\;\/\@]+$/i) {
            if ($debug > 2) {
              print "remove params -    $param_value: $params_for_cmd->{$param_value}\n";
            }
            delete $params_for_cmd->{$param_value};
          }
        }

        if ($debug > 3) {
          $params_for_cmd->{DEBUG}=1;
        }

        $result = cmd($cmd, {
          DEBUG   => ($debug > 1) ? $debug : 0,
          PARAMS  => $params_for_cmd,
          ARGV    => 1,
          timeout => 30
        });

        $result_code = $? >> 8;
      }
    }
  }
  elsif ($attr->{VENDOR_NAME} eq 'Huawei') {
    $attr->{TR_069_VLAN} = $attr->{NAS_INFO}->{tr_069_vlan} || '';
    $attr->{IPTV_VLAN} = $attr->{NAS_INFO}->{iptv_vlan} || '';
    $attr->{SRV_PROFILE} = $conf{HUAWEI_SRV_PROFILE_NAME} || 'ALL',
    $attr->{LINE_PROFILE} = $conf{HUAWEI_LINE_PROFILE_NAME} || 'ONU';

    if ($conf{"HUAWEI_SRV_PROFILE_NAME_BY_PON_TYPE"}->{lc $attr->{pon_type}}) {
      $attr->{SRV_PROFILE} = $conf{"HUAWEI_SRV_PROFILE_NAME_BY_PON_TYPE"}->{lc $attr->{pon_type}};
    }
    if ($conf{"HUAWEI_LINE_PROFILE_NAME_BY_PON_TYPE"}->{lc $attr->{pon_type}}) {
      $attr->{LINE_PROFILE} = $conf{"HUAWEI_LINE_PROFILE_NAME_BY_PON_TYPE"}->{lc $attr->{pon_type}};
    }

    if ($conf{HUAWEI_TRIPLE_PLAY_ONU} && in_array($attr->{EQUIPMENT_ID}, $conf{HUAWEI_TRIPLE_PLAY_ONU})) {
      $attr->{LINE_PROFILE} = $conf{HUAWEI_TRIPLE_LINE_PROFILE_NAME} || 'TRIPLE-PLAY';
    }

    my $parse_line_profile = $nas_type . '_prase_line_profile';
    if (defined(&$parse_line_profile)) {
      my $line_profiles = &{\&$parse_line_profile}({ %$attr });
      foreach my $key (keys %$line_profiles) {
        $attr->{LINE_PROFILE_DATA} .= "$key:";
        $attr->{LINE_PROFILE_DATA} .= join(',', @{$line_profiles->{$key}});
        $attr->{LINE_PROFILE_DATA} .= ";";
      }

      if (-x $cmd) {
        $attr->{TR_069_PROFILE} = $conf{TR_069_PROFILE} || 'ACS';
        $attr->{INTERNET_USER_VLAN} = $conf{INTERNET_USER_VLAN} || '101';
        $attr->{TR_069_USER_VLAN} = $conf{TR_069_USER_VLAN} || '102';
        $attr->{IPTV_USER_VLAN} = $conf{IPTV_USER_VLAN} || '103';

        delete $attr->{NAS_INFO}->{ACTION_LNG};

        my $params_for_cmd = { %$attr, %{$attr->{NAS_INFO}}, %extra_reg_params };
        $params_for_cmd = {map {(defined $params_for_cmd->{$_}) ? ($_ => $params_for_cmd->{$_}) : ()} keys %$params_for_cmd}; #cmd gives warning when there's undef in PARAMS

        foreach my $param_value (keys %$params_for_cmd) {
          if (defined($params_for_cmd->{$param_value}) && $params_for_cmd->{$param_value} eq '') {
            delete $params_for_cmd->{$param_value};
            next;
          }

          next if (!$param_value);
          $param_value =~ s/\0//g;

          #Remove non anscii symbols params
          if ($params_for_cmd->{$param_value} !~ /^[a-z0-9,\.\s\-:\_\;\/\@]+$/i) {
            if ($debug > 2) {
              print "remove params -    $param_value: $params_for_cmd->{$param_value}\n";
            }
            delete $params_for_cmd->{$param_value};
          }
        }

        if ($debug > 3) {
          $params_for_cmd->{DEBUG}=1;
        }

        $result = cmd($cmd, {
          DEBUG   => ($debug > 1) ? $debug : 0,
          PARAMS  => $params_for_cmd,
          ARGV    => 1,
          timeout => 30
        });
        $result_code = $? >> 8;
      }
    }
  }
  elsif ($attr->{VENDOR_NAME} eq 'BDCOM') {
    if (-x $cmd) {
      my $params_for_cmd = { %$attr, %{$attr->{NAS_INFO}}, %extra_reg_params };
      $params_for_cmd = {map {(defined $params_for_cmd->{$_}) ? ($_ => $params_for_cmd->{$_}) : ()} keys %$params_for_cmd}; #cmd gives warning when there's undef in PARAMS
      foreach my $param_value (keys %$params_for_cmd) {
        next if (!$param_value);
        $param_value =~ s/\0//g;
      }

      $result = cmd($cmd, {
        DEBUG   => ($debug > 1) ? $debug : 0,
        PARAMS  => $params_for_cmd,
        ARGV    => 1,
        timeout => 30
      });
      $result_code = $? >> 8;
    }
  }

  if ($result_code) {
    print $result . "\n";
    $result =~ s/\n/ /g;

    if ($result =~ /ONU: \d+\/\d+\/\d+\:(\d+) ADDED/) {
      my $onu = ();
      $onu->{NAS_ID} = $nas_id;
      $onu->{ONU_ID} = $1 || 0;
      $onu->{ONU_DHCP_PORT} = $port_list->[0]->{BRANCH} . ':' . $onu->{ONU_ID};
      $onu->{PORT_ID} = $port_list->[0]->{ID};
      $onu->{ONU_MAC_SERIAL} = $attr->{MAC_SERIAL};
      $onu->{ONU_DESC} = $attr->{ONU_DESC};
      $onu->{ONU_SNMP_ID} = $port_list->[0]->{SNMP_ID} . '.' . $onu->{ONU_ID};
      $onu->{LINE_PROFILE} = $attr->{LINE_PROFILE};
      $onu->{SRV_PROFILE} = $attr->{SRV_PROFILE};
      $onu->{VLAN} = $attr->{VLAN_ID};

      if ($result =~ /SVLAN:CVLAN (\d+):(\d+)/) {
        $onu->{SERVER_VLAN} = $1;
        $onu->{VLAN} = $2;
      }

      my $onu_list = $Equipment->onu_list({ COLS_NAME => 1, PORT_ID => $onu->{PORT_ID}, ONU_SNMP_ID => $onu->{ONU_SNMP_ID} });
      if ($onu_list->[0]->{id}) {
        $Equipment->onu_change({ ID => $onu_list->[0]->{id}, ONU_STATUS => 0, DELETED => 0, %{$onu} });
        $onu->{DATABASE_ID} = $onu_list->[0]->{id};
      }
      else {
        $Equipment->onu_add({ %{$onu} });
        $onu->{DATABASE_ID} = $Equipment->{INSERT_ID};
      }
      return $onu;
    }
    elsif ($result =~ /ONU ZTE: (\d+)\/(\d+)\/(\d+)\:(\d+) ADDED/) {
      return equipment_register_onu_add_zte($result, $nas_id, $port_list, $attr);
    }
    elsif ($result =~ /ONU BDCOM: (\d+)\/(\d+)\:(\d+) .* SNMP ID (\d+) DHCP PORT ([0-9a-f]{4}) ADDED/) {
      return equipment_register_onu_add_bdcom($result, $nas_id, $port_list, $attr);
    }
  }
  else {
    print $result . "\n";
  }
  return 0;
}

#**********************************************************
=head2 _auto_deregister() - Deregisters all ONU's on branch and deletes user's option 82 params

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub _auto_deregister {
  if (!$argv->{NAS_IDS}) {
    my $comments = "Not selected NAS ID. Use billd equipment_auto_reg NAS_IDS=\"ID\" BRANCHES=\"BRANCH1;BRANCH2;...\"\n";
    print $comments;
    _generate_new_event('Not selected NAS ID', $comments);

    return 0;
  }
  if (!$argv->{BRANCHES}) {
    my $comments = "Not selected branches. Use billd equipment_auto_reg NAS_IDS=\"ID\" BRANCHES=\"BRANCH1;BRANCH2;...\"\n";
    print $comments;
    _generate_new_event('Not selected branches', $comments);

    return 0;
  }

  my $nas_id = $nas_ids[0]; #there will be only one NAS
  my $nas = $Equipment->_list({
    NAS_ID           => $nas_id,
    VENDOR_NAME      => '_SHOW',
    NAS_IP           => '_SHOW',
    NAS_MNG_HOST_PORT=> '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    COLS_NAME        => 1,
    COLS_UPPER       => 1
  });
  $nas = $nas->[0];
  $nas->{NAS_MNG_PASSWORD} = $conf{EQUIPMENT_OLT_PASSWORD} || $nas->{NAS_MNG_PASSWORD};

  my $nas_type = equipment_pon_init($nas);

  my $all_port_list = $Equipment->pon_port_list({
    NAS_ID    => $nas_id,
    COLS_NAME => 1
  });
  my @port_ids = ();

  foreach my $port (@$all_port_list) {
    my $current_branch = lc($port->{pon_type} . ':' . $port->{branch});

    foreach my $branch_pattern (@branches) {
      if ($current_branch =~ /^$branch_pattern$/) {
        push @port_ids, $port->{id};
      }
    }
  }

  my $port_ids_string = join (',', @port_ids);
  if (!$port_ids_string) {
    my $comments = "No branches found, exiting";
    print $comments;
    _generate_new_event('Not selected branches', $comments);

    exit 1;
  }

  my $onus = $Equipment->onu_list({
    OLT_PORT   => $port_ids_string,
    BRANCH     => '_SHOW',
    MAC_SERIAL => '_SHOW',
    DELETED    => '_SHOW',
    COLS_NAME  => 1,
    COLS_UPPER => 1
  });

  my $cmd = $SNMP_TPL_DIR . '/register' . $nas_type . '_custom';
  $cmd = $SNMP_TPL_DIR . '/register' . $nas_type if (!-x $cmd);
  if (!-x $cmd) {
    my $comments = "Error: can't run registration script $cmd. Exiting.\n";
    print $comments;
    _generate_new_event('Error: registration script', $comments);

    return 0;
  }

  foreach my $onu (@$onus) {
    my $result;
    if (!$onu->{deleted}) {
      $result = cmd($cmd, {
        DEBUG   => ($debug > 1) ? $debug : 0,
        PARAMS  => { %$onu, %$nas, del_onu => 1 },
        ARGV    => 1,
        timeout => 30
      });
    }

    my $result_code = $? >> 8;

    if ($onu->{deleted} || $result_code && $result =~ /ONU.*DELETED/) {
      $Equipment->onu_del($onu->{id});

      if ($onu->{mac_serial}) {
        my $internet_list = $Internet->user_list({
          NAS_ID    => $nas_id,
          CPE_MAC   => $onu->{mac_serial},
          UID       => '_SHOW',
          COLS_NAME => 1,
          PAGE_ROWS => 10000000,
        });

        foreach my $user_info (@$internet_list) {
          $Internet->user_change({
            UID         => $user_info->{uid},
            ID          => $user_info->{id},
            NAS_ID1     => 0,
            PORT        => '',
            VLAN        => 0,
            SERVER_VLAN => 0,
          });
        }
      }

      if (!$onu->{deleted}) {
        print "Successfully deleted ONU $onu->{branch}:$onu->{onu_id}\n";
        print "$cmd exit code: $result_code, output: $result\n" if ($debug);
      }
      else {
        print "Successfully deleted ONU $onu->{branch}:$onu->{onu_id} from database\n";
      }
    }
    else {
      my $comments = "Failed to delete ONU $onu->{branch}:$onu->{onu_id}\n $cmd exit code: $result_code, output: $result\n";
      print $comments;
      _generate_new_event('Failed to delete ONU', $comments);

    }
  }

  return 1;
}

#**********************************************************
=head2 tr_069_setting($id, $attr) - Device setting

=cut
#**********************************************************
sub tr_069_setting {
  my ($id, $attr) = @_;

  JSON->new->allow_nonref;
  my $onu_setting->{ wan }->[ 0 ] = { ssid => $attr->{_wifi_ssid},  wlan_pass => $attr->{_wifi_pass}};
  my $settings = JSON::to_json($onu_setting, { utf8 => 0 });
  $Equipment->tr_069_settings_change($id, { SETTINGS => $settings });

  return 1;
}

#**********************************************************
=head2 _generate_new_event($title_event, $comments)

  Arguments:
    $title_event - title of message
    $comments - text of message to show

  Returns:

=cut
#**********************************************************
sub _generate_new_event {
  my ($title_event, $comments) = @_;

  $Events->add_event({
    MODULE      => 'Equipment',
    TITLE       => $title_event,
    COMMENTS    => "equipment_auto_reg - $comments",
    PRIORITY_ID => 3
  });

  return 1;
}

1
