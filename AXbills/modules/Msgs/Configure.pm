=head1 NAME

 Msgs configure interface

=cut

use strict;
use warnings FATAL => 'all';

our(
  $db,
  %conf,
  $html,
  %lang,
  @bool_vals,
  $admin,
  %msgs_permissions
);

my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_admin_permissions()

=cut
#**********************************************************
sub msgs_admin_permissions {

  $FORM{ADMIN_ID} ||= $admin->{AID};
  return if !$FORM{ADMIN_ID};

  my %permits = ();
  if ($FORM{set}) {
    foreach my $key (keys %FORM) {
      next if $key !~ /(\d{1,})_(\d{1,})/;

      my $section_index = $1;
      my $action_index = $2;

      $permits{$section_index}{$action_index} = 1;
    }

    $Msgs->set_permissions($FORM{ADMIN_ID}, \%permits);
    $html->message('info', $lang{INFO}, $lang{CHANGED}) if !_error_show($Msgs);
  }
  elsif ($FORM{add_permits} && $FORM{TYPE}) {
    foreach my $key (keys %FORM) {
      next if $key !~ /(\d{1,})_(\d{1,})/;

      my $section_index = $1;
      my $action_index = $2;

      $permits{$section_index}{$action_index} = 1;
    }

    $Msgs->msgs_set_type_permits($FORM{TYPE}, \%permits);
    $html->message('info', $lang{INFO}, $lang{ADDED}) if !_error_show($Msgs);
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Msgs->msgs_del_type_permits($FORM{del}, \%permits);
    $html->message('info', $lang{INFO}, $lang{DELETED}) if !_error_show($Msgs);
  }

  my ($type_permits, $types) = _msgs_permits_types();

  my $admin_permissions = $FORM{TYPE} ? $type_permits : $Msgs->permissions_list($FORM{ADMIN_ID});
  my $permissions = _msgs_permissions_list();

  my $table = $html->table({
    caption     => $lang{PERMISSION},
    title_plain => [ 'ID', $lang{NAME}, '' ],
    ID          => 'ADMIN_MSGS_PERMISSIONS',
  });

  foreach my $section_key (sort keys(%{$permissions})) {
    my $section = $permissions->{$section_key};

    $table->{rowcolor} = 'table-active';
    $table->addrow("$section_key:", $html->b($section->{NAME}), '');

    $table->{rowcolor} = '';
    foreach my $action_key (sort {$a <=> $b} (keys %{$section->{ACTIONS}})) {
      my $action = $section->{ACTIONS}{$action_key};
      my $action_id = $section_key . '_'. $action_key;

      my $checkbox = $html->form_input($action_id, 1, {
        STATE         => defined($admin_permissions->{$section_key}{$action_key}) ? 1 : undef,
        TYPE          => 'checkbox',
        OUTPUT2RETURN => 1
      });

      $table->addrow($action_key, $html->element('label', $action, { FOR => $action_id, class => 'font-weight-normal mb-0' }), $checkbox);
    }
  }

  $html->tpl_show(_include('msgs_add_permits', 'Msgs'), {
    PERMISSIONS_TABLE => $table->show({ OUTPUT2RETURN => 1 }),
    ADMIN_ID          => $FORM{ADMIN_ID},
    BUTTONS           => $types
  });
}

#**********************************************************
=head2 msgs_admins() -  Message  system admins

=cut
#**********************************************************
sub msgs_admins {

  if ($FORM{change}) {
    $Msgs->admin_change({%FORM});
    $html->message( 'info', $lang{INFO}, $lang{CHANGED} ) if (!$Msgs->{errno});
  }
  elsif ($FORM{chg}) {
    my $admin_permissions = $Msgs->permissions_list($FORM{AID});

    my $chapters = $Msgs->chapters_list({
      CHAPTER   => !$admin_permissions->{4} ? '_SHOW' : join(';', keys %{$admin_permissions->{4}}),
      AID       => $FORM{AID},
      COLS_NAME => 1,
    });

    my $table = $html->table({
      width => '100%',
      title => [ 'Id', $lang{CHAPTERS}, $lang{PRIORITY} ],
      ID    => 'ADMIN_ACCESS'
    });

    foreach my $chapter (@{$chapters}) {
      my $delegation_level = $html->form_select('DELIGATION_LEVEL_' . $chapter->{id}, {
        SELECTED     => $admin_permissions->{deligation_level}{$chapter->{id}} || 0,
        SEL_ARRAY    => [ 0 .. 10 ],
        ARRAY_NUM_ID => 1
      });

      $table->addrow($html->element('input', $chapter->{id}, { value => $chapter->{id}, name => 'IDS', type => 'hidden' }),
        $chapter->{name}, $delegation_level);
    }

    $Msgs->{CHAPTERS} = $table->show();
    $html->tpl_show(_include('msgs_admin', 'Msgs'), $Msgs);
  }

  _error_show($Msgs);

  my $list = $Msgs->admins_list({ %LIST_PARAMS, DISABLE => 0, COLS_NAME => 1 });
  my $table = $html->table({
    width   => '100%',
    caption => $lang{ADMINS},
	### START KTK-39
    title   => [ $lang{ADMIN}, $lang{FIO}, $lang{CHAPTERS}, $lang{PRIORITY}, "$lang{ACTION}" ],
	### END KTK-39
    qs      => $pages_qs,
    ID      => 'MSGS_ADMINS'
  });

  my %A_PRIVILEGES = ();
  foreach my $line (@$list) {
    $line->{chapter_name} = $line->{chapter_name} || '';
    $line->{deligation_level} = $line->{deligation_level} || '';
    $line->{aid} = $line->{aid} || '';
    $line->{chapter_id} = $line->{chapter_id} || '';
	### START KTK-39
	$line->{admin_name} = $line->{admin_name} || '';
    push @{ $A_PRIVILEGES{ $line->{admin_login} } }, "$line->{chapter_name}|$line->{deligation_level}|$line->{aid}|$line->{chapter_id}|$line->{admin_name}";
	### START END-39
  }
  my $permissions_index = get_function_index('msgs_admin_permissions');
  foreach my $admin_id (sort keys %A_PRIVILEGES) {
    my $rows = $#{ $A_PRIVILEGES{$admin_id} } || 0;
    my @arr = @{ $A_PRIVILEGES{$admin_id} };
	### START KTK-39
    my ($chapter_name, $deligation_level, $aid, $chapter_id,$admin_name) = split(/\|/, $arr[0]);
	### START END-39
    $table->{rowcolor} = ($FORM{chg} && $FORM{chg} eq $aid) ? $table->{rowcolor} = 'bg-success' : undef;

    $table->addtd(
      $table->td($admin_id, { rowspan => ($rows > 0) ? $rows + 1 : 1 }),
	  ### START END-39
	  $table->td($admin_name),
	  ### END END-39
      $table->td($chapter_name),
      $table->td($deligation_level || ($chapter_name ? '0' : '')),
      $table->td($html->button($lang{CHANGE}, "index=$index&chg=$aid&AID=$aid", { class => 'change' }) .
        $html->button($lang{PERMISSION}, "index=$permissions_index&ADMIN_ID=$aid", { ICON => 'fa fa-check' }),
        { rowspan => (($rows > 0) ? $rows + 1 : 1) })
    );

    next if $rows <= 0;
    for (my $i = 1; $i <= $rows; $i++) {
      ($chapter_name, $deligation_level, undef, undef) = split(/\|/, $arr[$i]);
      $table->addrow($chapter_name, $deligation_level || '0');
    }
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 msgs_progress_bar()

=cut
#**********************************************************
sub msgs_progress_bar {

  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};
  $LIST_PARAMS{CHAPTER_ID} = $FORM{PROGRES_BAR};
  $FORM{CHAPTER_ID} = $FORM{PROGRES_BAR};
  $pages_qs .= "&PROGRES_BAR=$FORM{CHAPTER_ID}"if($FORM{CHAPTER_ID});

  $FORM{USER_NOTICE}          = $FORM{USER_NOTICE}        ? 1:0;
  $FORM{RESPONSIBLE_NOTICE}   = $FORM{RESPONSIBLE_NOTICE} ? 1:0;
  $FORM{FOLLOWER_NOTICE}      = $FORM{FOLLOWER_NOTICE}    ? 1:0;

  $Msgs->{USER_NOTICE}        = $FORM{USER_NOTICE}        ? 'checked':'';
  $Msgs->{RESPONSIBLE_NOTICE} = $FORM{RESPONSIBLE_NOTICE} ? 'checked':'';
  $Msgs->{FOLLOWER_NOTICE}    = $FORM{FOLLOWER_NOTICE}    ? 'checked':'';

  if ($FORM{add}) {
    $Msgs->pb_add({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{ADDED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{change}) {
    $Msgs->pb_change({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{chg}) {
    $Msgs->pb_info($FORM{chg});

    $Msgs->{USER_NOTICE}        = $Msgs->{USER_NOTICE}        ? 'checked':'';
    $Msgs->{RESPONSIBLE_NOTICE} = $Msgs->{RESPONSIBLE_NOTICE} ? 'checked':'';
    $Msgs->{FOLLOWER_NOTICE}    = $Msgs->{FOLLOWER_NOTICE}    ? 'checked':'';

    $FORM{add_form} = 1;
    if (!$Msgs->{errno}) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" ) if (!$Msgs->{errno});
      $Msgs->{ACTION} = 'change';
      $Msgs->{LNG_ACTION} = $lang{CHANGE};
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Msgs->pb_del({ ID => $FORM{del} });
    $html->message( 'info', $lang{INFO}, "$lang{DELETED}" ) if (!$Msgs->{errno});
  }

  _error_show($Msgs);
  $html->tpl_show(_include('msgs_pb', 'Msgs'), $Msgs);

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'pb_list',
    BASE_FIELDS     => 3,
    DEFAULT_FIELDS  => 'STEP_NUM,STEP_NAME,STEP_TIPS',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      'step_num'  => $lang{NUM},
      'step_name' => $lang{NAME},
      'step_tip'  => $lang{TIPS},
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{PROGRESS_BAR}",
      qs      => $pages_qs,
      ID      => 'PROGRESS_BAR_LIST',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}


#**********************************************************
=head2 msgs_chapters()

=cut
#**********************************************************
sub msgs_chapters {
  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};

  if ($FORM{PROGRES_BAR}) {
    msgs_progress_bar();
    return 1;
  }
  elsif ($FORM{add}) {
    $Msgs->chapter_add({%FORM});
    if (!$Msgs->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}" ) if (!$Msgs->{errno});

      if ($FORM{UPLOAD_FILE}) {
        upload_file($FORM{UPLOAD_FILE}, {
          PREFIX    => '/chapters/',
          FILE_NAME => 'chapter_' . $Msgs->{INSERT_ID} . '.png',
        });
      }
    }
    else {
      $html->message('err', $lang{ERROR});
    }
  }
  elsif ($FORM{change}) {
    $Msgs->chapter_change({%FORM});

    if (!$Msgs->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
      if ($FORM{UPLOAD_FILE}) {
        upload_file($FORM{UPLOAD_FILE}, {
          PREFIX    => '/chapters/',
          FILE_NAME => 'chapter_' . $FORM{ID} . '.png',
          REWRITE   => 1
        });
      }
    }
    else {
      $html->message('err', $lang{ERROR});
    }
  }
  elsif ($FORM{chg}) {
    $Msgs->chapter_info($FORM{chg});
    $FORM{add_form} = 1;
    if (!$Msgs->{errno}) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" ) if (!$Msgs->{errno});
      $Msgs->{ACTION} = 'change';
      $Msgs->{LNG_ACTION} = $lang{CHANGE};
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Msgs->chapter_del({ ID => $FORM{del} });

    $html->message( 'info', $lang{INFO}, "$lang{DELETED}" ) if (!$Msgs->{errno});
  }

  _error_show($Msgs);

  if ($FORM{add_form}) {
    $Msgs->{RESPONSIBLE_SEL} = sel_admins({
      NORMAL_WIDTH => 1,
      NAME         => 'RESPONSIBLE',
      RESPONSIBLE  => $Msgs->{RESPONSIBLE} ? $Msgs->{RESPONSIBLE} : ''
    });
    $Msgs->{INNER_CHAPTER} = ($Msgs->{INNER_CHAPTER}) ? '  checked' : '';
    $html->tpl_show(_include('msgs_chapter', 'Msgs'), $Msgs);
  }

  my $list = $Msgs->chapters_list({
    %LIST_PARAMS,
    COLOR      => '_SHOW',
    MSG_COUNTS => '_SHOW',
    COLS_NAME  => 1
  });

  my $table = $html->table({
    width   => '100%',
    caption => $lang{CHAPTERS},
    title   => [ '#', $lang{NAME}, $lang{PRIVATE}, $lang{MESSAGES}, $lang{RESPOSIBLE}, $lang{COLOR}, $lang{ICON}, $lang{AUTO_CLOSE}, "-", "-" ],
    qs      => $pages_qs,
    MENU    => "$lang{ADD}:add_form=1&index=$index:add",
    ID      => 'MSGS_CHAPTERS'
  });

  foreach my $line (@$list) {
    $table->{rowcolor} = ($FORM{chg} && $FORM{chg} eq $line->{id}) ? $table->{rowcolor} = 'bg-success' : undef;

    $line->{id} //= 0;
    $line->{name} //= '';
    $line->{inner_chapter} //= 0;
    $line->{msg_counts} //= 0;
    $line->{color} //= "";

    my $icon = "$conf{TPL_DIR}chapters/chapter_$line->{id}.png";
    $line->{icon} = -e $icon ? "<img src='/images/chapters/chapter_$line->{id}.png' />" : "";

    $table->addrow(
      $line->{id},
      $line->{name},
        defined($line->{inner_chapter}) ? $bool_vals[ $line->{inner_chapter} ] : '',
      $html->button($line->{msg_counts}, "index=". get_function_index('msgs_admin')."&CHAPTER=$line->{id}&ALL_MSGS=1"),
      $line->{admin_login} || '',
      $html->color_mark($line->{color},$line->{color}),
      $line->{icon},
      $line->{autoclose},
      $html->button( "$lang{PROGRESS_BAR}", "index=$index&PROGRES_BAR=$line->{id}",
        { TITLE => $lang{PROGRESS_BAR}, ICON => 'fa fa-tasks' } ),
      $html->button( "$lang{CHANGE}", "index=$index&chg=$line->{id}", { class => 'change' } ),
      $html->button( $lang{DEL}, "index=$index&del=$line->{id}",
        { MESSAGE => "$lang{DEL} $line->{id}?", class => 'del' } )
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 msgs_dispatch_category()

=cut
#**********************************************************
sub msgs_dispatch_category {
  #my %info;

  if($FORM{add_form}){
    $Msgs->{ACTION} = 'added';
    $Msgs->{ACTION_LNG} = $lang{ADD};

    $html->message( 'info', $lang{INFO}, "$lang{ADD}" );

    $html->tpl_show(_include('msgs_dispatch_category','Msgs'), { %$Msgs });
  }
  elsif($FORM{added}){
    $Msgs->dispatch_category_add({%FORM});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{ADDED}" );
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{del}){
    $Msgs->dispatch_category_del({ID => $FORM{del}});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{chg}){
    $Msgs->dispatch_category_info($FORM{chg});

    if (!$Msgs->{errno}) {
      $Msgs->{ACTION} = 'change';
      $Msgs->{ACTION_LNG} = $lang{CHANGE};

      $html->message( 'info', $lang{INFO}, "$lang{CHANGE}" );

      $html->tpl_show(_include('msgs_dispatch_category','Msgs'), { %$Msgs });
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{change}){
    $Msgs->dispatch_category_change({%FORM});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'dispatch_category_list',
    DEFAULT_FIELDS  => 'ID,NAME',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => "$lang{DISPACTH_CATEGORY}",
      qs      => $pages_qs,
      ID      => 'DISPACTH_CATEGORY',
      MENU    => "$lang{ADD}:add_form=1&index=$index:add"
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });

  return 1;
}

#**********************************************************
=head2 msgs_survey() - Msgs survey

=cut
#**********************************************************
sub msgs_survey {
  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};

  my $i = 1;
  if ($FORM{ 'FILE_UPLOAD_' . $i }{filename}) {
    $FORM{FILENAME}          = $FORM{ 'FILE_UPLOAD_' . $i }{filename};
    $FORM{FILE_CONTENT_TYPE} = $FORM{ 'FILE_UPLOAD_' . $i }{'Content-Type'};
    $FORM{FILE_SIZE}         = $FORM{ 'FILE_UPLOAD_' . $i }{Size};
    $FORM{FILE_CONTENTS}     = $FORM{ 'FILE_UPLOAD_' . $i }{Contents};
  }

  if ($FORM{SURVEY_ID}) {
    msgs_survey_questions();
    return 0;
  }
  elsif ($FORM{add}) {
    $Msgs->survey_subject_add({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{ADDED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{change}) {
    $Msgs->survey_subject_change({%FORM});

    $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{chg}) {
    $Msgs->survey_subject_info($FORM{chg});

#    if($FORM{ajax}){
#      print "$Msgs->{TPL}";
#      return 1;
#    }

    $Msgs->{ACTION} = 'change';
    $Msgs->{LNG_ACTION} = $lang{CHANGE};
    $FORM{add_form} = 1;

    $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Msgs->survey_subject_del({ ID => $FORM{del} });

    $html->message( 'info', $lang{INFO}, "$lang{DELETED}" ) if (!$Msgs->{errno});
  }

  _error_show($Msgs);

  my %status_hash = (
    0 => $lang{ENABLE},
    1 => $lang{DISABLE}
  );

  if ($FORM{add_form}) {
    $Msgs->{STATUS_SEL} = $html->form_select(
      'STATUS',
      {
        SELECTED  => $Msgs->{STATUS} || 0,
        SEL_HASH  => \%status_hash,
        NO_ID     => 1
      }
    );
    if($Msgs->{TPL}) {
      $Msgs->{TPL} =~ s/\%/\&#37/g;
    }
    $html->tpl_show(_include('msgs_survey_subject', 'Msgs'), $Msgs);
  }

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'survey_subjects_list',
    BASE_FIELDS     => 2,
    DEFAULT_FIELDS  => 'ID,NAME,COMMENTS,STATUS,ADMIN_NAME,CREATED',
    FUNCTION_FIELDS => 'msgs_survey:$lang{QUESTIONS}:survey_id,change,del',
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
      comments   => $lang{COMMENTS},
      tpl        => $lang{TEMLATE},
      status     => $lang{STATUS},
      admin_name => $lang{ADMIN},
      created    => $lang{CREATED},
    },
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => { status => \%status_hash, },
    FILTER_COLS     => { users_count => 'search_link:form_search:LOCATION_ID,type=11', },
    TABLE           => {
      width   => '100%',
      caption => "$lang{SURVEY}",
      qs      => $pages_qs,
      ID      => 'SURVEY_LIST',
      MENU    => "$lang{ADD}:add_form=1&index=$index:add"
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });

  return 1;
}

#**********************************************************
=head2 msgs_status() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_status {
  #my ($attr) = @_;

  my %task_closed = (0 => $lang{NO}, 1 => $lang{YES});

  $Msgs->{ACTION} = 'add';
  $Msgs->{ACTION_LNG} = $lang{ADD};

  if($FORM{add}){
    $Msgs->status_add({ %FORM, TASK_CLOSED => $FORM{TASK_CLOSED} || '0' });
    $html->message('success', $lang{INFO}, $lang{ADDED}) if !$Msgs->{errno};
  }
  elsif ($FORM{change}) {
    $Msgs->status_change({ %FORM, TASK_CLOSED => $FORM{TASK_CLOSED} || '0' });
    $html->message('success', $lang{INFO}, $lang{CHANGED}) if !$Msgs->{errno};
  }
  elsif($FORM{chg}){
    $Msgs->{ACTION}   = 'change';
    $Msgs->{ACTION_LNG} = $lang{CHANGE};
    $Msgs->status_info($FORM{chg});
    $Msgs->{CHECKED}  = 'checked' if ($Msgs->{TASK_CLOSED});
  }
  elsif($FORM{del} && $FORM{del} =~ /\d+/ && $FORM{COMMENTS}){
    $Msgs->status_del({ID => $FORM{del}});

    if(!$Msgs->{errno}){
      $html->message('success', $lang{INFO}, $lang{DELETED});
    }
  }

  _error_show($Msgs);

  $html->tpl_show(_include('msgs_status', 'Msgs'), $Msgs);

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'status_list',

    DEFAULT_FIELDS  => 'ID,NAME,READINESS,TASK_CLOSED,COLOR,ICON',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id          => '#',
      name        => $lang{NAME},
      readiness   => "$lang{READINESS}, %",
      task_closed => $lang{TASK_CLOSED},
      color       => $lang{COLOR},
      icon        => $lang{ICON},
    },
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => { task_closed => \%task_closed, },
    FILTER_COLS  => {
      name => '_translate',
      icon => '_msgs_get_icon:ICON'
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{STATUS}",
      qs      => $pages_qs,
      ID      => 'STATUS_LIST',
      MENU    => ""
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });

  return 1;
}

#**********************************************************
=head2 msgs_quick_replys_types()

=cut
#**********************************************************
sub msgs_quick_replys_types {

  if($FORM{add_form}){
    $Msgs->{ACTION} = 'added';
    $Msgs->{ACTION_LNG} = $lang{ADD};

    $html->tpl_show(_include('msgs_quick_replys_types','Msgs'), { %$Msgs });
  }
  elsif($FORM{added}){
    $Msgs->messages_quick_replys_types_add({%FORM});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{ADDED}" );
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{del}){
    $Msgs->messages_quick_replys_types_del({ID => $FORM{del}});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{chg}){
    $Msgs->messages_quick_replys_types_info($FORM{chg});

    if (!$Msgs->{errno}) {
      $Msgs->{ACTION} = 'change';
      $Msgs->{ACTION_LNG} = $lang{CHANGE};

      $html->tpl_show(_include('msgs_quick_replys_types','Msgs'), { %$Msgs });
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{change}){
    $Msgs->messages_quick_replys_types_change({%FORM});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'messages_quick_replys_types_list',
    DEFAULT_FIELDS  => 'ID,NAME',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => "$lang{MSGS_TAGS_TYPES}",
      qs      => $pages_qs,
      ID      => 'QUICK_REPLYS_TYPES',
      MENU    => "$lang{ADD}:add_form=1&index=$index:add"
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });

  return 1;
}

#**********************************************************
=head2 msgs_survey_questions()

=cut
#**********************************************************
sub msgs_survey_questions {
  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};
  $Msgs->{FILL_DEFAULT} = 1;

  if ($FORM{add}) {
    $Msgs->survey_question_add({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{ADDED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{change}) {
    $Msgs->survey_question_change({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{chg}) {
    $Msgs->survey_question_info($FORM{chg});

    $Msgs->{ACTION} = 'change';
    $Msgs->{LNG_ACTION} = $lang{CHANGE};

    $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Msgs->survey_question_del({ ID => $FORM{del} });

    $html->message( 'info', $lang{INFO}, "$lang{DELETED}" ) if (!$Msgs->{errno});
  }

  _error_show($Msgs);

  $Msgs->{USER_COMMENTS} = ($Msgs->{USER_COMMENTS}) ? 'checked' : '';
  $Msgs->{FILL_DEFAULT} = ($Msgs->{FILL_DEFAULT})  ? 'checked' : '';

  $html->tpl_show(_include('msgs_survey_question', 'Msgs'), $Msgs);
  my $list = $Msgs->survey_questions_list(
    {
      SURVEY_ID => $FORM{SURVEY_ID},
      %LIST_PARAMS,
      COLS_NAME => 1
    }
  );

  my $table = $html->table({
    width       => '100%',
    caption     => "$lang{SURVEY}",
    title_plain => [ '#', $lang{QUESTION}, $lang{PARAMS}, $lang{COMMENTS}, "$lang{USER} $lang{COMMENTS}", $lang{DEFAULT}, '-',
      '-' ],
    qs         => $pages_qs,
  });

  foreach my $line (@$list) {
    my $params =
        ($line->{params})
      ? $html->form_select(
        'PARAMS_' . $line->{num},
        {
          SELECTED     => '',
          SEL_ARRAY    => [ split(/;/, $line->{params}) ],
          ARRAY_NUM_ID => 1
        }
      )
      : '';
    $table->addrow(
      $line->{num}, $line->{question}, $line->{comments}, $params,
        ($line->{user_comments}) ? $html->form_input('USER_COMMENTS', '') : '',
      $bool_vals[ $line->{fill_default} ],
      $html->button( "$lang{CHANGE}", "index=$index&chg=$line->{id}&SURVEY_ID=$FORM{SURVEY_ID}", { class => 'change' } )
      ,
      $html->button( $lang{DEL}, "index=$index&del=$line->{id}&SURVEY_ID=$FORM{SURVEY_ID}",
        { MESSAGE => "$lang{DEL}  $line->{num}?", class => 'del' })
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 msgs_quick_replys()

=cut
#**********************************************************
sub msgs_quick_replys {

  if ($FORM{add_form}) {
    $Msgs->{ACTION} = 'added';
    $Msgs->{ACTION_LNG} = $lang{ADD};

    $Msgs->{QUICK_REPLYS_CATEGORY} = $html->form_select('TYPE_ID', {
      SEL_LIST => $Msgs->messages_quick_replys_types_list({ COLS_NAME => 1 }),
      NO_ID    => 1,
      REQUIRED => 1,
    });

    $html->tpl_show(_include('msgs_quick_replys', 'Msgs'), { %{$Msgs} });
  }
  elsif ($FORM{added}) {
    $Msgs->messages_quick_replys_add({ %FORM });
    $html->message('success', $lang{INFO}, $lang{ADDED}) if !_error_show($Msgs);
  }
  elsif ($FORM{del}) {
    $Msgs->messages_quick_replys_del({ ID => $FORM{del} });
    $html->message('success', $lang{INFO}, $lang{DELETED}) if !_error_show($Msgs);
  }
  elsif ($FORM{chg}) {
    $Msgs->messages_quick_replys_info($FORM{chg});

    $Msgs->{QUICK_REPLYS_CATEGORY} = $html->form_select('TYPE_ID', {
      SELECTED => $Msgs->{TYPE_ID} ? $Msgs->{TYPE_ID} : 1,
      SEL_LIST => $Msgs->messages_quick_replys_types_list({ COLS_NAME => 1 }),
      NO_ID    => 1,
      REQUIRED => 1,
    });

    if (!_error_show($Msgs)) {
      $Msgs->{ACTION} = 'change';
      $Msgs->{ACTION_LNG} = $lang{CHANGE};

      $html->tpl_show(_include('msgs_quick_replys', 'Msgs'), { %{$Msgs} });
    }
  }
  elsif ($FORM{change}) {
    $Msgs->messages_quick_replys_change({ %FORM });
    $html->message('success', $lang{INFO}, $lang{CHANGED}) if !_error_show($Msgs);
  }

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'messages_quick_replys_list',
    DEFAULT_FIELDS  => 'ID,REPLY,TYPE,COLOR,COMMENT',
    HIDDEN_FIELDS   => 'TYPE_ID',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id      => '#',
      reply   => $lang{TAGS},
      type_id => "$lang{TYPE} ID",
      type    => $lang{TYPE},
      color   => $lang{COLOR},
      comment => $lang{COMMENTS}
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{MSGS_TAGS},
      qs      => $pages_qs,
      ID      => 'QUICK_REPLYS',
      MENU    => "$lang{ADD}:add_form=1&index=$index:add"
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 msgs_subjects()

=cut
#**********************************************************
sub msgs_subjects {

  $Msgs->{ACTION} = 'add';
  $Msgs->{ACTION_LNG} = $lang{ADD};

  if ($FORM{add}) {
    $Msgs->subject_add(\%FORM);
    $html->message('success', $lang{INFO}, $lang{ADDED}) if !_error_show($Msgs);
  }
  elsif ($FORM{change}) {
    $Msgs->subject_change({ %FORM, TASK_CLOSED => $FORM{TASK_CLOSED} || '0' });
    $html->message('success', $lang{INFO}, $lang{CHANGED}) if !_error_show($Msgs);
  }
  elsif ($FORM{chg}) {
    $Msgs->{ACTION} = 'change';
    $Msgs->{ACTION_LNG} = $lang{CHANGE};
    $Msgs->subject_info($FORM{chg});
  }
  elsif ($FORM{del} && $FORM{del} =~ /\d+/s && $FORM{COMMENTS}) {
    $Msgs->subject_del({ ID => $FORM{del} });
    $html->message('success', $lang{INFO}, $lang{DELETED}) if !_error_show($Msgs);
  }

  $html->tpl_show(_include('msgs_subject', 'Msgs'), $Msgs);

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'subjects_list',
    DEFAULT_FIELDS  => 'ID,NAME',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id          => '#',
      name        => $lang{NAME}
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{SUBJECTS},
      qs      => $pages_qs,
      ID      => 'SUBJECTS_LIST'
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });

  return 1;
}

#**********************************************************
=head2 _msgs_permissions_list()

=cut
#**********************************************************
sub _msgs_permissions_list {

  my $chapters = {};
  map $chapters->{$_->{id}} = $_->{name}, @{ $Msgs->chapters_list({ COLS_NAME => 1 }) };

  return {
    1 => {
      NAME    => $lang{MESSAGES},
      ACTIONS => {
        0  => $lang{ADDING_MESSAGES},
        1  => $lang{DELETING_MESSAGES},
        2  => $lang{EDITING_MESSAGES},
        3  => $lang{CLOSING_MESSAGES},
        4  => $lang{CHANGING_MESSAGE_SUBJECT},
        5  => $lang{EDITING_MAIN_MESSAGE},
        6  => $lang{CREATE_MESSAGES_LINKED_TO_ADDRESS},
        7  => $lang{ABILITY_TO_SEND_PRIVATE_MESSAGES},
        8  => $lang{ABILITY_CHANGE_MESSAGE_SECTION},
        9  => $lang{DELIGATE},
        10 => $lang{EDITING_REPLY},
        11 => $lang{DELETING_REPLY},
        12 => $lang{QUOTING_REPLIES},
        13 => $lang{CHANGE_PRIORITY},
        14 => $lang{PRINT},
        15 => $lang{EXPORTING_MESSAGES},
        16 => $lang{CHANGE_OF_RESPONSIBLE},
        17 => $lang{MESSAGE_MONITORING},
        18 => $lang{VIEW_TAGS},
        19 => $lang{TAG_ASSIGNMENT},
        20 => $lang{ACCESS_TO_QUICK_RESPONSE_TEMPLATES},
        21 => $lang{SHOW_ONLY_ASSIGNED_TICKETS},
        22 => $lang{VIEW_EQUIPMENT},
        23 => $lang{ADDING_EQUIPMENT},
        24 => $lang{NOTIFICATIONS_ASSIGNED_MESSAGES_ONLY},
        25 => $lang{PUTTING_MESSAGE_IN_SEPARATE_SUBJECT},
        26 => $lang{CHANGE_OF_DISPATCH}
      }
    },
    2 => {
      NAME    => $lang{DELIVERY},
      ACTIONS => {
        0 => $lang{VIEW_DELIVERY},
        1 => $lang{ADDING_DELIVERY},
        2 => $lang{EDITING_DELIVERY},
        3 => $lang{DELETING_DELIVERY},
        4 => $lang{USERS_CHOICE}
      }
    },
    3 => {
      NAME    => $lang{DISPATCH},
      ACTIONS => {
        0 => $lang{VIEW_DISPATCHES},
        1 => $lang{ADDING_DISPATCHES},
        2 => $lang{EDITING_DISPATCHES},
        3 => $lang{DELETING_DISPATCHES},
        4 => $lang{PRINT},
      }
    },
    4 => {
      NAME    => $lang{CHAPTER},
      ACTIONS => $chapters
    },
    5 => {
      NAME    => $lang{NOTIFICATIONS},
      ACTIONS => {
        0  => 'Browser',
        1  => 'Sms',
        5  => 'Viber_bot',
        6  => 'Telegram',
        9  => 'Mail',
        10 => 'Push',
        13 => 'Iptv_message',
        14 => 'Viber',
      }
    },
    6 => {
      NAME    => "$lang{NOTIFICATIONS}: $lang{CHAPTERS}",
      ACTIONS => $chapters
    }
  };
}

#**********************************************************
=head2 _msgs_permits_types()

=cut
#**********************************************************
sub _msgs_permits_types {

  my $permits_types = $Msgs->msgs_type_permits_list({ COLS_NAME => 1 });
  return '' if _error_show($Msgs);

  my $buttons = '';
  my %admin_types = ();

  foreach my $item (@{$permits_types}) {
    $item->{type} = _translate($item->{type});
    $admin_types{$item->{type}}{$item->{section}}{$item->{actions}} = 1;
  }

  foreach my $type (sort keys %admin_types) {
    my $class = 'btn btn-default btn-sm ' . (!$FORM{add_permits} && $FORM{TYPE} && $FORM{TYPE} eq  $type ? 'active' : '');
    my $type_btn = $html->button($type, "index=$index&ADMIN_ID=$FORM{ADMIN_ID}&TYPE=$type", { class => $class });
    my $del_btn = $html->button('', "index=$index&ADMIN_ID=$FORM{ADMIN_ID}&del=$type", {
      class   => "$class text-danger",
      ICON    => 'fa fa-times',
      MESSAGE => "$lang{DEL} $lang{TEMPLATE}?"
    });

    $buttons .= $html->element('div', $type_btn . $del_btn, { class => 'btn-group mb-1 mr-1' })
  }

  return ($FORM{TYPE} ? $admin_types{$FORM{TYPE}} : {}, $buttons)
}

1;