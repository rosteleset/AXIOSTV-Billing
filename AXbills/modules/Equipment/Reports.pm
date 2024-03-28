#!perl

=head1 NAME

  Reports

  Error ID: 4xx

=cut

use strict;
use warnings FATAL => 'all';
use POSIX qw/strftime/;
use Equipment;
use Internet;
use AXbills::Base qw(in_array int2byte ip2int mk_unique_value
  load_pmodule date_format _bp int2ip);
use AXbills::Filters qw(_mac_former dec2hex);
use Nas;

our (
  $db,
  $admin,
  %conf,
  $html,
  %lang,
  $var_dir,
  $DATE,
  $TIME,
  %permissions,
  @ONU_ONLINE_STATUSES
);

load_pmodule("JSON");

our Equipment $Equipment;
require Equipment::Grabbers;

#*******************************************************************
=head2 equipment_start_page()

=cut
#*******************************************************************
sub equipment_start_page {
  #my ($attr) = @_;

  my %START_PAGE_F = (
    'equipment_count_report'  => $lang{REPORT_EQUIPMENT},
    'equipment_pon_report'    => $lang{REPORT_PON},
    'equipment_unreg_report'  => $lang{REPORT_ON_UNREGISTERED_ONU},
    'equipment_switch_report' => $lang{REPORT_ON_NUMBER_OF_BUSY_AND_FREE_PORTS_ON_SWITCHES}
  );

  return \%START_PAGE_F;
}
#*******************************************************************
=head2 equipment_count_report() - Show equipment info

=cut
#*******************************************************************
sub equipment_count_report {

  $Equipment->_list();
  my $total_count = $Equipment->{TOTAL} || '0';
  $Equipment->_list({ STATUS => 0 });
  my $active_count = $Equipment->{TOTAL} || '0';
  $Equipment->_list({ STATUS => 1 });
  my $inactive_count = $Equipment->{TOTAL} || '0';
  $Equipment->mac_log_list({ MAC_UNIQ_COUNT => '_SHOW', COLS_NAME => 1 });
  my $mac_uniq_count = $Equipment->{MAC_UNIQ_COUNT} || '0';

  my $table = $html->table(
    {
      width   => '100%',
      caption => $html->button($lang{REPORT_EQUIPMENT}, "index=" . get_function_index('equipment_list')),
      ID      => 'EQUIPMENT_INFO',
      rows    => [
        [ $lang{TOTAL_COUNT}, $total_count ],
        [ $lang{ACTIVE_COUNT}, $active_count ],
        [ $lang{PING_COUNT}, '-' ],
        [ $lang{SNMP_COUNT}, '-' ],
        [ $lang{INACTIVE_COUNT}, $inactive_count ],
        [ $lang{UNIQ_MAC_COUNT}, $mac_uniq_count ],
      ]
    }
  );

  my $report_equipment .= $table->show();

  return $report_equipment;

}

#*******************************************************************
=head2 equipment_pon_report() - Show pon info

=cut
#*******************************************************************
sub equipment_pon_report {
  my $equipment_list = $Equipment->_list({
    TYPE_ID              => '4',
    STATUS               => '0;3', #enable, error
    EPON_SUPPORTED_ONUS  => '_SHOW',
    GPON_SUPPORTED_ONUS  => '_SHOW',
    GEPON_SUPPORTED_ONUS => '_SHOW',
    COLS_NAME            => 1
  });
  my $index_equipment_list = get_function_index('equipment_list');
  my $index_equipment_onu_report = get_function_index('equipment_onu_report');

  my %equipment_list = map { $_->{nas_id} => $_ } @$equipment_list;
  my $olt_count = $Equipment->{TOTAL} || '0';

  my $branches = $Equipment->pon_port_list({
    STATUS => '0;3', #enable, error
    GROUP_BY => 'p.nas_id, p.branch',
    COLS_NAME => 1
  });
  my $branch_count = $Equipment->{TOTAL} || '0';

  my $possible_onu_count = 0;
  foreach my $branch (@$branches) {
    if ($branch->{pon_type} eq 'epon') {
      $possible_onu_count += $equipment_list{$branch->{nas_id}}->{epon_supported_onus} || 64;
    }
    elsif ($branch->{pon_type} eq 'gpon') {
      $possible_onu_count += $equipment_list{$branch->{nas_id}}->{gpon_supported_onus} || 128;
    }
    elsif ($branch->{pon_type} eq 'gepon') {
      $possible_onu_count += $equipment_list{$branch->{nas_id}}->{gepon_supported_onus} || 128;
    }
  }

  my $onu_info = $Equipment->pon_onus_report({
    ONU_ONLINE_STATUS => join(';', @ONU_ONLINE_STATUSES),
    STATUS            => '0;3', #enable, error
    DELETED           => 0,
    COLS_NAME         => 1
  });

  my ($onu_count, $active_onu_count, $bad_onu_count) = ($onu_info->{onu_count} || 0, $onu_info->{active_onu_count} || 0, $onu_info->{bad_onu_count} || 0);
  my $branch_total_fill = $possible_onu_count ? sprintf('%.2f%%', $onu_count / $possible_onu_count * 100) : '-';
  my $inactive_onu_count = $onu_count - $active_onu_count;
  my $table = $html->table({
    width   => '100%',
    caption => $html->button($lang{REPORT_PON}, "index=" . get_function_index('equipment_pon_form')),
    ID      => 'PON_INFO',
    rows    => [
      [ $lang{OLT_COUNT},          $html->button($olt_count, "index=$index_equipment_list&TYPE_ID=4") ],
      [ $lang{BRANCH_COUNT},       $html->button($branch_count, "index=$index_equipment_onu_report") ],
      [ $lang{BRANCH_TOTAL_FILL},  $branch_total_fill ],
      [ $lang{ONU_COUNT},          $html->button($onu_count, "index=$index_equipment_onu_report") ],
      [ $lang{ACTIVE_ONU_COUNT},   $html->button($active_onu_count, "index=$index_equipment_onu_report")],
      [ $lang{INACTIVE_ONU_COUNT}, $html->button($inactive_onu_count, "index=$index_equipment_onu_report&ONU=INACTIVE") ],
      [ $lang{BAD_ONU_COUNT},      $html->button($bad_onu_count, "index=$index_equipment_onu_report&ONU=BAD") ]
    ]
  });

  return $table->show();
}

#*******************************************************************
=head2 equipment_unreg_report()

=cut
#*******************************************************************
sub equipment_unreg_report {

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{REPORT_ON_UNREGISTERED_ONU},
    title_plain => [ "OLT", $lang{COUNT} ],
    ID          => 'UNREG_ITEMS',
  });
  my $refresh_period = ($conf{REFRESH_PERIOD_FOR_UNREG_ONU}) ? ($conf{REFRESH_PERIOD_FOR_UNREG_ONU}) : 300;

  return $html->tpl_show(_include('equipment_unreg_onu_report', 'Equipment'),
    {
      UNREG_TABLE  => $table->show(),
      PERIOD       => $refresh_period
    }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 unreg_report($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub equipment_unreg_report_date {
  my ($attr) = @_;

  my $pon_list = $Equipment->_list({
    NAS_ID           => '_SHOW',
    NAS_NAME         => '_SHOW',
    MODEL_ID         => '_SHOW',
    REVISION         => '_SHOW',
    TYPE_ID          => '4',
    SYSTEM_ID        => '_SHOW',
    NAS_TYPE         => '_SHOW',
    MODEL_NAME       => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    STATUS           => 0,
    NAS_IP           => '_SHOW',
    NAS_MNG_HOST_PORT=> '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    SNMP_TPL         => '_SHOW',
    LOCATION_ID      => '_SHOW',
    COLS_NAME        => 1,
    COLS_UPPER       => 1
  });

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{REPORT_ON_UNREGISTERED_ONU},
    title_plain => [ "OLT", $lang{COUNT} ],
    ID          => 'UNREG_ITEMS'
  });

  my $unregister_list = '';
  foreach my $nas (@$pon_list) {
    my $nas_id = $nas->{NAS_ID};
    $Equipment->vendor_info($Equipment->{VENDOR_ID});
    $nas->{VENDOR_NAME} = $Equipment->{NAME} if (!$nas->{VENDOR_NAME});

    my $nas_type = equipment_pon_init($nas);
    next if ($nas_type eq "_bdcom");

    if ($nas_type eq '_eltex') {
      require Equipment::Eltex;
    }
    elsif ($nas_type eq '_zte') {
      require Equipment::Zte;
    }
    elsif ($nas_type eq '_huawei') {
      require Equipment::Huawei;
    }
    elsif ($nas_type eq '_vsolution') {
      require Equipment::Vsolution;
    }
    elsif ($nas_type eq '_cdata') {
      require Equipment::Cdata;
    }

    $nas->{SNMP_COMMUNITY} = ($nas->{NAS_MNG_PASSWORD} || q{}) . "@" . ($nas->{NAS_MNG_IP_PORT} || q{});
    $nas->{FULL} = 1;

    my $unregister_fn = $nas_type . '_unregister';

    next unless defined(&$unregister_fn);
    $unregister_list = &{\&$unregister_fn}({ %$nas });

    my $index = get_function_index('equipment_info');
    $pages_qs = "index=$index&visual=4&NAS_ID=$nas_id&unregister_list=1";

    my $count = @$unregister_list;
    $table->addrow($nas->{NAS_NAME}, $count, $html->button('', $pages_qs, { class => "show", target => '_blank' })) if ($count > 0);
  }

  print $table->show();

  return 0;
}

#*******************************************************************
=head2 equipment_switch_report() - Show switch information

=cut
#*******************************************************************
sub equipment_switch_report {

  my ($free_ports, $busy_ports, $ports, $switch_count) = 0;
  my $Internet = Internet->new($db, $admin, \%conf);
  my $switch_list = $Equipment->_list({
    PORTS      => '_SHOW',
    TYPE_ID    => '1',
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    PAGE_ROWS  => 100000
  });

  foreach my $switch (@$switch_list) {
    $Internet->user_list({
      NAS_ID    => $switch->{NAS_ID},
      PORT      => '_SHOW',
      COLS_NAME => 1
    });
    $switch_count++;
    $ports += $switch->{PORTS};
    $busy_ports += $Internet->{TOTAL};
    $free_ports += ($switch->{PORTS} - $Internet->{TOTAL});
  }

  my $table = $html->table(
    {
      width   => '100%',
      caption => $lang{REPORT_ON_NUMBER_OF_BUSY_AND_FREE_PORTS_ON_SWITCHES},
      ID      => 'SWITCH_INFO',
      rows    => [
        [ $lang{TOTAL_SWITCH_COUNT}, $switch_count ],
        [ $lang{TOTAL_ALL_PORTS}, $ports ],
        [ $lang{TOTAL_BUSY_PORTS}, $busy_ports ],
        [ $lang{TOTAL_FREE_PORTS}, $free_ports ],
      ]
    }
  );

  my $report_switch = $table->show();

  return $report_switch;
}

#********************************************************
=head2 equipment_onu_report() - Show onu statistic

=cut
#********************************************************
sub equipment_onu_report {
  my $Nas = Nas->new($db, \%conf, $admin);

  my $list = $Equipment->_list({
    TYPE_ID              => 4,
    NAS_IP               => '_SHOW',
    NAS_ID               => '_SHOW',
    EPON_SUPPORTED_ONUS  => '_SHOW',
    GPON_SUPPORTED_ONUS  => '_SHOW',
    GEPON_SUPPORTED_ONUS => '_SHOW',
    PAGE_ROWS            => 1000000,
    COLS_NAME            => 1
  });

  my $full_branch_list = $Equipment->pon_port_list({
    GROUP_BY => 'p.nas_id, p.branch',
    COLS_NAME => 1
  });

  foreach my $line (@$list) {
    my $nas_info = $Nas->list({
      NAS_ID    => $line->{nas_id},
      COLS_NAME => 1,
    });

    next if(!$nas_info->[0]);

    my $onus = $Equipment->onu_list({
      NAS_ID      => $line->{nas_id},
      RX_POWER    => ($FORM{ONU} && $FORM{ONU} eq 'INACTIVE') ? '0' : '_SHOW',
      NAS_IP      => '_SHOW',
      DELETED     => 0,
      STATUS      => '_SHOW',
      PON_TYPE    => '_SHOW',
      BRANCH      => '_SHOW',
      BRANCH_DESC => '_SHOW',
      COLS_NAME   => 1,
    });

    my %branch_list = ();

    foreach my $onu (@$onus) {
      if (!%branch_list || !in_array($onu->{branch}, [ keys %branch_list ])) {
        $branch_list{$onu->{branch}} = { pon_type => $onu->{pon_type} };
      }

      $branch_list{$onu->{branch}}{total_count} += 1;
      $branch_list{$onu->{branch}}{branch_desc} = $onu->{branch_desc};

      if (in_array($onu->{status}, \@ONU_ONLINE_STATUSES)) {
        $branch_list{$onu->{branch}}{online_count} += 1;
        my $signal_status_code = pon_tx_alerts($onu->{rx_power}, 1);

        if ($signal_status_code == 1) {
          $branch_list{$onu->{branch}}{good_count} += 1;
        }
        elsif ($signal_status_code == 2) {
          $branch_list{$onu->{branch}}{bad_count} += 1;
        }
        elsif ($signal_status_code == 3) {
          $branch_list{$onu->{branch}}{worth_count} += 1;
        }
      }
    }

    my $total_count = 0;
    my $total_possible = 0;
    my $busy = 0;
    my $title_count = $lang{COUNT};

    foreach my $branch (@$full_branch_list) {
      next if ($branch->{nas_id} != $line->{nas_id});

      if ($branch->{pon_type} eq 'epon') {
        $total_possible += $line->{epon_supported_onus} || 64;
      }
      elsif ($branch->{pon_type} eq 'gpon') {
        $total_possible += $line->{gpon_supported_onus} || 128;
      }
      elsif ($branch->{pon_type} eq 'gepon') {
        $total_possible += $line->{gepon_supported_onus} || 128;
      }

      if ($branch_list{$branch->{branch}}) {
        $branch_list{$branch->{branch}}->{id} = $branch->{id};
        $total_count += $branch_list{$branch->{branch}}->{total_count} || 0;
      }
    }
    if ($total_possible != 0) {
      $busy = sprintf("%.2f", $total_count / $total_possible * 100);
    }
    if ($FORM{ONU} && $FORM{ONU} eq 'INACTIVE'){
      $title_count .= " $lang{OFFLINE}";
    }
    my $index_equipment_info = get_function_index('equipment_info');

    my $table = $html->table({
      ID      => 'info_' . $line->{nas_id},
      title   => [ $lang{INTERFACE}, $title_count, $lang{GOOD_SIGNAL}, $lang{GOOD_SIGNAL} . ' %', $lang{WORTH_SIGNAL}, $lang{WORTH_SIGNAL} . ' %', $lang{BAD_SIGNAL}, $lang{BAD_SIGNAL} . ' %', $lang{COMMENTS} ],
      caption => $html->button(
          "$nas_info->[0]->{nas_id}: $nas_info->[0]->{nas_name} ($nas_info->[0]->{nas_ip})",
          "index=" . $index_equipment_info. "&visual=4&NAS_ID=$nas_info->[0]->{nas_id}"
        ) .
        " - $lang{OLT_BUSY} $busy% ($total_count ONU $lang{REGISTERED})",
    });

    foreach my $key (sort keys %branch_list) {
      my $total = $branch_list{$key}->{total_count};
      my $online = $branch_list{$key}->{online_count};

      if ($FORM{ONU} && $FORM{ONU} eq 'INACTIVE'){
        $total = ($branch_list{$key}->{total_count} || 0) - ($branch_list{$key}->{online_count} || 0);
      }

      my $good = $branch_list{$key}->{good_count};
      my $worth = $branch_list{$key}->{worth_count};
      my $bad = $branch_list{$key}->{bad_count} || 0;
      next if ($FORM{ONU} && $FORM{ONU} eq 'BAD' && $bad == 0);

      $table->addrow(
        $html->button(
          $branch_list{$key}->{pon_type} . ' ' . $key,
          "index=" . $index_equipment_info . "&visual=4&NAS_ID=$nas_info->[0]->{nas_id}&OLT_PORT=$branch_list{$key}->{id}"
        ),
        $total,
        $html->badge($good, { TYPE => 'badge-success' }),
        $good ? sprintf("%.2f", $good / $online * 100) . '%' : '',
        $html->button($html->badge($worth, { TYPE => 'badge-warning' }), "index=$index_equipment_info&visual=4&NAS_ID=$nas_info->[0]->{nas_id}&OLT_PORT=$branch_list{$key}->{id}&RX_POWER_SIGNAL=WORTH", {target => '_blank' }),
        $worth ? sprintf("%.2f", $worth / $online * 100) . '%' : '',
        $html->button($html->badge($bad, { TYPE => 'badge-danger' }), "index=$index_equipment_info&visual=4&NAS_ID=$nas_info->[0]->{nas_id}&OLT_PORT=$branch_list{$key}->{id}&RX_POWER_SIGNAL=BAD", {target => '_blank' }),
        $bad ? sprintf("%.2f", $bad / $online * 100) . '%' : '',
        $branch_list{$key}->{branch_desc}
      );
    }

    print $table->show() if (%branch_list);
  }
  return 1;
}

1;
