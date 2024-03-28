=head1 Msgs_team_location

  Msgs Msgs_team_location

=cut

use strict;
use warnings FATAL => 'all';

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html
);

my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_team_location() -

=cut
#**********************************************************
sub msgs_team_location {

  if ($FORM{add}) {
    $Msgs->team_location_add({
      ID_TEAM     => $FORM{TEAM},
      DISTRICT_ID => $FORM{DISTRICT_ID},
      STREET_ID   => $FORM{STREET_ID},
      BUILD_ID    => $FORM{BUILD_ID},
    });

    if (!_error_show($Msgs)) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{chg}) {
    $Msgs->team_location_change($FORM{chg}, {
    ID          => $FORM{TEAM},
    DISTRICT_ID => $FORM{DISTRICT_ID},
    STREET_ID   => $FORM{STREET_ID},
    BUILD_ID    => $FORM{BUILD_ID},
  });

    if (!_error_show($Msgs)) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{del}) {
    $Msgs->team_location_del($FORM{del});

    if (!_error_show($Msgs)) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
    }
  }

  show_form_location(\%FORM);

  my $table = $html->table({
    width   => '100%',
    caption => $lang{LOCATION_BRIGADE},
    title   => [ '#', $lang{BRIGADE}, $lang{DISTRICTS}, $lang{STREET}, $lang{BUILD} ],
    ID      => 'BRIGADE_ID',
  });

  my $location_data_table = $Msgs->team_location_list({
    ID_TEAM       => '_SHOW',
    DISTRICT_ID   => '_SHOW',
    STREET_ID     => '_SHOW',
    BUILD_ID      => '_SHOW',
    NUMBER        => '_SHOW',
    NAME_DISTRICT => '_SHOW',
    NAME_STREET   => '_SHOW',
  });

  foreach my $element (@$location_data_table) {
    $table->addrow(
      $element->{id},
      $lang{BRIGADE} . ' №' . ($element->{id_team} || ''),
      $element->{name_district},
      $element->{name_street},
      $element->{number},
      $html->button($element->{id},
        "index=" . get_function_index('msgs_team_location') . '&chg_id=' . ($element->{id} || ''), { class => 'change' }),
      $html->button($element->{id}, "index=" . get_function_index('msgs_team_location')
        . "&del=" . ($element->{id} || ''), { class => 'del', MESSAGE => "$lang{DEL}?" })
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 show_form_location() -

    Arguments:
      CHG_ID      - change element id
      TEAM        - team responsible id

    Return:
      tpl_show    - template

=cut
#**********************************************************
sub show_form_location {
  my ($attr) = @_;

  my $team            = $attr->{TEAM};
  my $button_name     = $lang{ADD};
  my $param_name      = "add";
  my $chg_location_id = $attr->{chg_id};
  my $location_id     = 0;
  my $district_id     = 0;
  my $street_id       = 0;

  my $responsible_list = $Msgs->responsible_team_list();

  if ($chg_location_id) {
    my $date = $Msgs->team_location_list({
      ID          => $chg_location_id,
      DISTRICT_ID => '_SHOW',
      ID_TEAM     => '_SHOW',
      STREET_ID   => '_SHOW',
      BUILD_ID    => '_SHOW',
  });

    $team        = $date->[0]{id_team};
    $location_id = $date->[0]{build_id};
    $district_id = $date->[0]{district_id};
    $street_id   = $date->[0]{street_id};
    $button_name = $lang{CHANGE};
    $param_name  = "chg";
  }

  my $team_select = $html->form_select('TEAM', {
    SELECTED    => $team,
    SEL_LIST    => $responsible_list,
    SEL_KEY     => 'id',
    SEL_VALUE   => 'aid',
    SEL_OPTIONS => { '' => '--' },
    NO_ID       => 1,
  });

  my $address = form_address_select2({
    HIDE_FLAT             => 1,
    HIDE_ADD_BUILD_BUTTON => 1,
    LOCATION_ID           => $location_id,
    DISTRICT_ID           => $district_id,
    STREET_ID             => $street_id,
  });

  return $html->tpl_show(_include('msgs_team_address', 'Msgs'), {
    INDEX       => get_function_index('msgs_team_location'),
    TEAM        => $team_select,
    ADDRESS     => $address,
    SAVE_CHG    => $button_name,
    PARAM       => $param_name,
    CHG_ELEMENT => $chg_location_id
  });
}

1;