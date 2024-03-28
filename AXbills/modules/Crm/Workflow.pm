use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Workflow - crm workflow

=cut

our (
  $Crm,
  $html,
  %lang,
  %conf,
  $admin,
  $db,
  %permissions,
  %LIST_PARAMS,
  @PRIORITY
);

sub crm_workflow {

  $html->message('info', $lang{INFO}, $FORM{MESSAGE}) if $FORM{MESSAGE};

  if ($FORM{chg}) {
    $Crm->crm_workflow_info($FORM{chg});
    $FORM{NAME} = $Crm->{NAME};
    $FORM{DESCRIBE} = $Crm->{DESCR};
    $FORM{DISABLE} = 'checked' if $Crm->{DISABLE};

    my $workflow_triggers = $Crm->crm_workflow_triggers_list({
      WORKFLOW_ID => $FORM{chg},
      TYPE        => '_SHOW',
      OLD_VALUE   => '_SHOW',
      NEW_VALUE   => '_SHOW',
      CONTAINS    => '_SHOW',
      COLS_NAME   => 1
    });

    my $workflow_actions = $Crm->crm_workflow_actions_list({
      WORKFLOW_ID => $FORM{chg},
      TYPE        => '_SHOW',
      VALUE       => '_SHOW',
      COLS_NAME   => 1
    });

    $FORM{ACTIVE_TRIGGERS} = json_former($workflow_triggers);
    $FORM{ACTIVE_ACTIONS} = json_former($workflow_actions);
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Crm->crm_workflow_del({ ID => $FORM{del} });
    $html->message('info', $lang{DELETED}, "$lang{DELETED}: #$FORM{del}") if !_error_show($Crm);
  }

  if ($FORM{add_form} || $FORM{chg}) {
    my $triggers = crm_triggers();
    my $actions = crm_actions();

    $html->tpl_show(_include('crm_workflow', 'Crm'), {
      %FORM,
      TRIGGERS => json_former($triggers),
      ACTIONS  => json_former($actions),
    });
  }

  result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'crm_workflow_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,DESCR,DISABLE,USED_TIMES',
    FUNCTION_FIELDS => 'change, del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
      descr      => $lang{DESCRIBE},
      disable    => $lang{STATUS},
      used_times => $lang{USED}
    },
    FILTER_VALUES     => {
      disable => sub {
        my $status = shift;

        return !$status ? $html->color_mark($lang{ACTIVATED}, '#009D00') : $html->color_mark($lang{DISABLED}, '#FF0000');
      },
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{WORKFLOWS},
      qs      => $pages_qs,
      ID      => 'CRM_WORKFLOWS',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1" . ':add',
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });
}

#**********************************************************
=head2 crm_triggers()

=cut
#**********************************************************
sub crm_triggers {

  my $admin_hash = sel_admins({ HASH => 1 });
  my $steps = $Crm->crm_progressbar_step_list({
    ID          => '_SHOW',
    NAME        => '_SHOW',
    STEP_NUMBER => '_SHOW',
    DEAL_STEP   => '0',
    COLS_NAME   => 1
  });
  my $steps_hash = {};
  map $steps_hash->{$_->{id}} = _translate($_->{name}), @{$steps};

  my $actions = $Crm->crm_actions_list({ NAME => '_SHOW', ACTION => '_SHOW', COLS_NAME => 1 });
  my $actions_hash = {};
  foreach my $action (@{$actions}) {
    $action->{name} =~ s/\"/\\\"/g;
    $actions_hash->{$action->{id}} = _translate($action->{name});
  }

  my $tasks_hash = {};

  if (in_array('Tasks', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{Tasks})) {
    use Tasks::db::Tasks;
    my $Tasks = Tasks->new($db, $admin, \%conf);
    my $tasks_list = $Tasks->types_list({ COLS_NAME => 1 });
    map $tasks_hash->{$_->{id}} = _translate($_->{name}), @{$tasks_list};
  }

  my %priority_hash = map { $_ => $PRIORITY[$_] } 0..$#PRIORITY;

  return [
    {
      type => 'isNew',
      lang => $lang{CRM_NEW_LEAD},
    },
    {
      type => 'isChanged',
      lang => $lang{CRM_LEAD_WAS_CHANGED},
    },
    {
      type => 'newAction',
      lang => $lang{ADDED_NEW_ACTION},
      fields => [
        {
          type        => 'select',
          placeholder => $lang{ACTION},
          options     => $actions_hash,
          name        => 'new_value',
          multiple    => 1
        },
        {
          type        => 'select',
          placeholder => $lang{RESPOSIBLE},
          options     => $admin_hash,
          name        => 'old_value',
          multiple    => 1
        }
      ],
    },
    {
      type => 'newTask',
      lang => $lang{CRM_TASK_ADDED},
      fields => [
        {
          type        => 'select',
          placeholder => $lang{TASKS},
          options     => $tasks_hash,
          name        => 'new_value',
          multiple    => 1
        }
      ],
    },
    {
      type => 'closedTask',
      lang => $lang{CRM_TASK_CLOSED},
      fields => [
        {
          type        => 'select',
          placeholder => $lang{TASKS},
          options     => $tasks_hash,
          name        => 'new_value',
          multiple    => 1
        }
      ],
    },
    {
      type   => 'responsible',
      lang   => $lang{RESPOSIBLE},
      fields => [
        {
          type        => 'select',
          placeholder => $lang{RESPOSIBLE},
          options     => $admin_hash,
          name        => 'new_value',
          multiple    => 1
        }
      ],
    },
    {
      type   => 'responsibleChanged',
      lang   => $lang{CRM_RESPONSIBLE_CHANGED},
      fields => [
        {
          type        => 'select',
          placeholder => $lang{CRM_RESPONSIBLE_CHANGED_FROM},
          options     => $admin_hash,
          name        => 'old_value',
          empty       => 1
        },
        {
          type        => 'select',
          placeholder => $lang{CRM_RESPONSIBLE_CHANGED_TO},
          options     => $admin_hash,
          name        => 'new_value',
          empty       => 1
        }
      ],
    },
    {
      type   => 'step',
      lang   => $lang{STEP},
      fields => [
        {
          type        => 'select',
          placeholder => $lang{STEP},
          options     => $steps_hash,
          name        => 'new_value',
          # empty       => 1,
          multiple    => 1
        }
      ],
    },
    {
      type   => 'priority',
      lang   => $lang{PRIORITY},
      fields => [
        {
          type        => 'select',
          placeholder => $lang{PRIORITY},
          options     => \%priority_hash,
          name        => 'new_value',
          # empty       => 1,
          multiple    => 1
        }
      ],
    },
    {
      type   => 'stepChanged',
      lang   => $lang{STEP_CHANGED},
      fields => [
        {
          type        => 'select',
          placeholder => $lang{STEP_CHANGED_FROM},
          options     => $steps_hash,
          name        => 'old_value',
          empty       => 1,
          multiple    => 1
        },
        {
          type        => 'select',
          placeholder => $lang{STEP_CHANGED_TO},
          options     => $steps_hash,
          name        => 'new_value',
          empty       => 1,
        }
      ],
    },
  ];
}

#**********************************************************
=head2 crm_actions()

=cut
#**********************************************************
sub crm_actions {

  my $admin_hash = sel_admins({ HASH => 1 });
  my $steps = $Crm->crm_progressbar_step_list({
    ID          => '_SHOW',
    NAME        => '_SHOW',
    STEP_NUMBER => '_SHOW',
    DEAL_STEP   => '0',
    COLS_NAME   => 1
  });
  my $steps_hash = {};
  map $steps_hash->{$_->{id}} = _translate($_->{name}), @{$steps};

  my $actions = $Crm->crm_actions_list({ NAME => '_SHOW', ACTION => '_SHOW', COLS_NAME => 1 });
  my $actions_hash = {};
  foreach my $action (@{$actions}) {
    $action->{name} =~ s/\"/\\\"/g;
    $actions_hash->{$action->{id}} = _translate($action->{name});
  }

  my $tasks_hash = {};
  if (in_array('Tasks', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{Tasks})) {
    use Tasks::db::Tasks;
    my $Tasks = Tasks->new($db, $admin, \%conf);
    my $tasks_list = $Tasks->types_list({ COLS_NAME => 1 });
    map $tasks_hash->{$_->{id}} = _translate($_->{name}), @{$tasks_list};
  }

  my %priority_hash = map { $_ => $PRIORITY[$_] } 0..$#PRIORITY;

  return [
    {
      type   => 'setStep',
      lang   => $lang{CHANGE_STEP},
      fields => [
        {
          type        => 'select',
          options     => $steps_hash,
          placeholder => $lang{SELECT_STEP},
          name        => 'value',
          empty       => 1
        }
      ]
    },
    {
      type   => 'setResponsible',
      lang   => $lang{CRM_SET_RESPONSIBLE},
      fields => [
        {
          type        => 'select',
          options     => $admin_hash,
          placeholder => $lang{CRM_SELECT_RESPONSIBLE},
          name        => 'value',
          empty       => 1
        }
      ]
    },
    {
      type   => 'sendMessage',
      lang   => $lang{CRM_SEND_MESSAGE},
      fields => [
        {
          type        => 'textarea',
          placeholder => $lang{CRM_ENTER_MESSAGE},
          name        => 'value'
        }
      ]
    },
    {
      type   => 'setPriority',
      lang   => $lang{SET_PRIORITY},
      fields => [
        {
          type        => 'select',
          options     => \%priority_hash,
          placeholder => $lang{PRIORITY},
          name        => 'value',
          empty       => 1
        },
      ]
    },
    {
      type   => 'addAction',
      lang   => $lang{CRM_ADD_ACTION},
      fields => [
        {
          type        => 'select',
          options     => $actions_hash,
          placeholder => $lang{ACTION},
          name        => 'value',
          empty       => 1
        },
        {
          type        => 'select',
          options     => $admin_hash,
          placeholder => $lang{CRM_SELECT_RESPONSIBLE},
          name        => 'value',
          empty       => 1
        },
        {
          type        => 'select',
          options     => \%priority_hash,
          placeholder => $lang{PRIORITY},
          name        => 'value',
          empty       => 1
        },
        {
          type        => 'datepicker',
          placeholder => $lang{CRM_PLANNING_DATE},
          name        => 'value',
          empty       => 1
        },
        {
          type        => 'input',
          placeholder => $lang{COMMENTS},
          name        => 'value'
        },
      ]
    },
    {
      type   => 'addTask',
      lang   => $lang{CRM_ADD_TASK},
      fields => [
        {
          type        => 'select',
          options     => $tasks_hash,
          placeholder => $lang{CRM_TASK_TYPE},
          name        => 'value',
          empty       => 1
        },
        {
          type        => 'input',
          placeholder => $lang{CRM_TASK_NAME},
          name        => 'value'
        },
        {
          type        => 'select',
          options     => $admin_hash,
          placeholder => $lang{CRM_SELECT_RESPONSIBLE},
          name        => 'value',
          empty       => 1
        },
        {
          type        => 'datepicker',
          placeholder => $lang{CRM_DUE_DATE},
          name        => 'value',
          empty       => 1
        }
      ]
    },
  ];
}

1;