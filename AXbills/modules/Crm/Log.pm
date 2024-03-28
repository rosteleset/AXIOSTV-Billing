use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Log - crm leads log

=cut

our (
  $Crm,
  $html,
  %lang,
  %conf,
  $admin,
  $db,
  %permissions,
  %LIST_PARAMS
);

my %action_types = (
  0 => 'Unknown',
  1 => $lang{ADDED},
  2 => $lang{CHANGED},
  3 => $lang{CRM_VIEWING_INFORMATION},
  4 => $lang{DELETED}
);

#**********************************************************
=head2 crm_log($attr)

=cut
#**********************************************************
sub crm_log {

  if ($FORM{del} && $FORM{COMMENTS}) {
    $Crm->crm_action_del($FORM{del});
    $html->message('info', $lang{INFO}, "$lang{DELETED} [$FORM{del}]") if !$Crm->{errno};
  }

  _crm_log_search() if $FORM{search_form};

  $FORM{LID} =~ s/,/;/ if $FORM{LID};
  my $logs = $Crm->crm_action_list({
    DATETIME  => $FORM{FROM_DATE_TO_DATE} || '_SHOW',
    ADMIN     => $FORM{ADMIN} || '_SHOW',
    LID       => $FORM{LID} || '_SHOW',
    ACTIONS   => $FORM{ACTIONS} || '_SHOW',
    IP        => $FORM{IP} || '_SHOW',
    TYPE      => $FORM{TYPE} || '_SHOW',
    LEAD_FIO  => '_SHOW',
    COLS_NAME => 1
  });

  my $log_table = $html->table({
    width   => '100%',
    title   => [ '#', $lang{LEAD}, $lang{FIO}, $lang{DATE}, $lang{TYPE}, $lang{CHANGED}, $lang{ADMIN}, 'IP', '-' ],
    # qs         => $pages_qs2, # $pages_qs
    caption => $lang{LOG},
    pages   => $admin->{TOTAL},
    ID      => 'СRM_ADMIN_ACTIONS',
    EXPORT  => 1,
    MENU    => "$lang{SEARCH}:search_form=1&index=$index:search;"
  });

  my $leads_function_index = get_function_index('crm_lead_info');

  foreach my $log (@{$logs}) {
    $log->{admin} ||= '';
    my $action = defined($log->{action_type}) && $action_types{$log->{action_type}} ? $action_types{$log->{action_type}} : $action_types{0};
    my $lead_button = $html->button($log->{lid}, "index=$leads_function_index&LEAD_ID=$log->{lid}");
    my $del_btn = $html->button($lang{DEL}, "index=$index&del=$log->{id}", {
      MESSAGE => "$lang{DEL} [$log->{id}]?", class => 'del'
    });

    $log_table->addrow($log->{id}, $lead_button, $log->{lead_fio}, $log->{datetime},
      $action, $log->{actions}, $log->{admin}, $log->{ip}, $del_btn);
  }

  print $log_table->show();
}

#**********************************************************
=head2 crm_recent_activity($attr)

=cut
#**********************************************************
sub crm_lead_recent_activity {
  my $lead_id = shift;

  return '' unless $lead_id;

  my $recent_activity = $Crm->crm_action_list({
    DATETIME  => '_SHOW',
    ADMIN     => '_SHOW',
    ACTIONS   => '_SHOW',
    TYPE      => '_SHOW',
    DESC      => 'desc',
    LID       => $lead_id,
    PAGE_ROWS => 5,
    COLS_NAME => 1
  });

  return '' if $Crm->{TOTAL} < 1;

  my $log = '';
  foreach my $action (@{$recent_activity}) {
    $log .= $html->tpl_show(_include('crm_lead_log_item', 'Crm'), {
      ADMIN_NAME => $action->{admin},
      DATETIME   => $action->{datetime},
      ACTION     => $action->{actions},
      TYPE       => defined($action->{action_type}) && $action_types{$action->{action_type}} ?
        $action_types{$action->{action_type}} : $action_types{0}
    }, { OUTPUT2RETURN => 1 });
  }

  return $html->tpl_show(_include('crm_lead_log', 'Crm'), { LOG => $log }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 _crm_log_search($attr)

=cut
#**********************************************************
sub _crm_log_search {

  my %search_params = ();

  $search_params{TYPE_SEL} = $html->form_select('TYPE', {
    SELECTED      => $FORM{TYPE},
    SEL_HASH      => { '' => $lang{ALL}, %action_types },
    SORT_KEY      => 1,
    OUTPUT2RETURN => 1
  });

  $search_params{ADMIN_SEL} = sel_admins();

  $search_params{PERIOD} = $html->form_daterangepicker({
    NAME      => 'FROM_DATE/TO_DATE',
    VALUE     => $FORM{'FROM_DATE_TO_DATE'} || '',
    WITH_TIME => 0,
  });

  form_search({
    SEARCH_FORM       => $html->tpl_show(_include('crm_lead_log_search_form', 'Crm'),
      { %search_params, %FORM },
      { OUTPUT2RETURN => 1 }
    ),
    PLAIN_SEARCH_FORM => 1
  });

}

1;