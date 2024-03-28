=head1 Msgs_Plugins

  Msgs Plugins

=cut

use strict;
use warnings FATAL => 'all';
use JSON;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  $base_dir,
  %msgs_permissions
);

my $modules_dir = ($base_dir || '/usr/axbills/') . 'AXbills/modules/';
my $Msgs = Msgs->new($db, $admin, \%conf);

my @positions = (
  "RIGHT",
  "BOTTOM"
);

my @actions = (
  'BEFORE_CREATE',
  'BEFORE_REPLY',
  'AFTER_CREATE'
);

my $aid = $Msgs->{admin}->{AID};

#**********************************************************
=head2 msgs_plugins_list($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub msgs_plugins_list {

  my $table = '';

  my $enabled_plugins = ();
  if ($FORM{change}) {
    $enabled_plugins = _msgs_get_save_plugin({ HASH => 1 });

    $Msgs->msgs_plugin_del({ ID => $aid });
  }

  $table .= _created_plugins_table('POSITION', \@positions, $enabled_plugins);
  $table .= _created_plugins_table('ACTION', \@actions, $enabled_plugins);

  print $html->form_main({
    CONTENT => $table,
    HIDDEN  => { index => get_function_index('msgs_plugins_list') },
    SUBMIT  => { change => $lang{CHANGE} }
  });

  return 0;
}

#**********************************************************
=head2 _created_plugins_table($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _created_plugins_table {
  my ($type, $plugins_types, $enabled_plugins) = @_;

  my $table = '';

  foreach my $position (@{$plugins_types}) {
    my $plugins = _msgs_get_plugins({ SKIP_ENABLE => 1, $type => $position });

    $FORM{POSITION} = $position;
    $FORM{TYPE} = $type;

    $table .= _msgs_plugins_table($plugins, $enabled_plugins, \%FORM),
  }

  return $table;
}

#**********************************************************
=head2 msgs_plugin_priority($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub msgs_plugin_priority {

  unless ($FORM{PLUGINS}) {
    my $plugins = _msgs_get_plugins({ SKIP_ENABLE => 1, $FORM{TYPE} => $FORM{POSITION} });
    my $plugins_enabled = $Msgs->msgs_plugin_list({
      ID          => $aid,
      PLUGIN_NAME => '_SHOW',
      PRIORITY    => '_SHOW',
    });

    $html->tpl_show(_include('msgs_plugins_priority', 'Msgs'), {
      JSON => _plugins_to_json($plugins, $plugins_enabled)
    });
    return;
  }

  my $json_plugin = $FORM{PLUGINS};
  my $error_message = _plugin_priority_change($json_plugin);

  my %success = (
    "status"  => 0,
    "message" => $error_message
  );

  print(JSON->new->utf8->encode(\%success));
}

#**********************************************************
=head2 _plugin_priority_change($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _plugin_priority_change {
  my ($json_plugin) = @_;

  $json_plugin =~ s/\\//g;

  my $plugin_scalar = JSON->new->utf8->decode($json_plugin);

  my $error_change = 'Success';

  foreach my $plugin (@{$plugin_scalar}) {
    $Msgs->msgs_plugin_change({
      PLUGIN_NAME => $plugin->{VALUE},
      ID          => $plugin->{AID},
      PRIORITY    => $plugin->{PRIORITY}
    });

    $error_change = 'Failed' if (_error_show($Msgs));
  }

  return $error_change;
}

#**********************************************************
=head2 _plugins_to_json($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _plugins_to_json {
  my ($plugins, $plugins_enabled) = @_;

  my @plugins_to_json = ();
  my @options_to_json = ();

  foreach my $plugin (@{$plugins}) {
    my $name = $plugin->{PLUGIN};
    $name =~ s/$plugin->{MODULE}::Plugins:://g;

    for (my $i = 0; $i <= $#{$plugins_enabled}; $i++) {
      next if (!$plugins_enabled->[$i]->{plugin_name} || $plugins_enabled->[$i]->{plugin_name} ne $name);
      my %options_json = ();

      push(@plugins_to_json, {
        type_id  => $i,
        priority => $plugins_enabled->[$i]->{priority},
        name     => $plugins_enabled->[$i]->{plugin_name},
        value    => $plugins_enabled->[$i]->{plugin_name},
        aid      => $aid
      });

      $options_json{name} = @{$plugins_enabled}[$i]->{plugin_name};
      $options_json{id} = $i;

      push(@options_to_json, { name => $plugins_enabled->[$i]->{plugin_name}, id => $i });
    }
  }

  return JSON->new->utf8->encode({
    plugins => \@plugins_to_json,
    options => {
      types          => \@options_to_json,
      aid            => $aid,
      callback_index => get_function_index('msgs_plugin_priority')
    }
  });
}

#**********************************************************
=head2 _msgs_get_plugins($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_get_plugins {
  my ($attr) = @_;

  my $admin_plugins_list = $Msgs->msgs_plugin_list({
    PLUGIN_NAME => '_SHOW',
    ID          => $attr->{AID} || '_SHOW',
    PRIORITY    => '_SHOW'
  });

  @{$admin_plugins_list} = sort {$a->{priority} <=> $b->{priority}} @{$admin_plugins_list};
  return _msgs_get_enable_plugins($admin_plugins_list, $attr) if ($Msgs->{TOTAL} > 0 && !$attr->{SKIP_ENABLE});

  my @plugins = ();
  my $position = $attr->{POSITION} || '';
  my $action = $attr->{ACTION} || ();

  foreach my $module (@MODULES) {
    my $plugin_dir = $modules_dir . $module . '/Plugins';
    next unless (-d $plugin_dir);

    my $plugin_files = _get_files_in($plugin_dir, { FILTER => '\.pm' });

    foreach my $plugin (sort @{$plugin_files}) {
      next if $plugin !~ /^[\w.]+$/;
      $plugin =~ s/\.pm//g;
      my $plugin_name = $module . '::Plugins::' . $plugin;

      eval "require $plugin_name;";
      if ($@) {
        $html->message('err', $lang{ERROR}, "$lang{PLUGIN_LOADING_ERROR}: $plugin ($@)");
        next;
      }

      next unless ($plugin_name->can('new'));
      next unless ($plugin_name->can('plugin_info'));

      my $plugin_api = $plugin_name->new($db, $admin, \%conf, {
        HTML             => $html,
        LANG             => \%lang,
        MSGS_PERMISSIONS => \%msgs_permissions
      });
      my $info = $plugin_api->plugin_info();

      next if ref $info ne 'HASH';
      next if ($action && !$info->{$action});
      next if ($position && !$info->{POSITION} || ($info->{POSITION} && $position ne $info->{POSITION}));

      $info->{MODULE} = $module;
      $info->{PLUGIN} = $plugin_name;

      push(@plugins, $info);
    }
  }

  return \@plugins;
}

#**********************************************************
=head2 _msgs_get_enable_plugins($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_get_enable_plugins {
  my ($admin_plugins, $attr) = @_;

  my @plugins = ();
  my $position = $attr->{POSITION} || '';
  my $action = $attr->{ACTION} || ();

  foreach my $plugin (@{$admin_plugins}) {
    return if !$plugin->{module} || !$plugin->{plugin_name} || !defined($plugin->{priority});

    return if $plugin->{module} !~ /^[\w.]+$/;
    my $plugin_name = $plugin->{module} . '::Plugins::' . $plugin->{plugin_name};

    eval "require $plugin_name;";
    if ($@) {
      $html->message('err', $lang{ERROR}, "$lang{PLUGIN_LOADING_ERROR}: $plugin->{plugin_name} ($@)");
      next;
    }

    next unless ($plugin_name->can('plugin_info'));

    my $info = $plugin_name->plugin_info();
    next if ref $info ne 'HASH';

    next if ($action && !$info->{$action});
    next if (($position && $info->{POSITION} && $position ne $info->{POSITION}) || (!$info->{POSITION} && $position));
    $info->{MODULE} = $plugin->{module};
    $info->{PLUGIN} = $plugin_name;

    push(@plugins, $info);
  }

  return \@plugins;
}

#**********************************************************
=head2 _msgs_plugins_table($plugins_list)

=cut
#**********************************************************
sub _msgs_plugins_table {
  my ($plugins_list, $enabled_plugins, $attr) = @_;

  _plugin_enabled($plugins_list, $enabled_plugins, $attr) if ($attr->{change});
  my $plugins_enabled = _msgs_get_save_plugin();

  my $table = $html->table({
    caption     => $lang{ "MSGS_$attr->{POSITION}" },
    width       => '100%',
    title_plain => [ '#', $lang{NAME}, $lang{DESCRIBE}, $lang{MODULE} ],
    ID          => 'PLAGINS_TABLE_' . $attr->{POSITION},
    MENU        => _created_modal_priority($attr->{POSITION}, $attr->{TYPE}),
  });

  foreach my $plugin (@{$plugins_list}) {
    my $name = $plugin->{PLUGIN};
    $name =~ s/$plugin->{MODULE}::Plugins:://g;

    $table->addrow(
      $html->form_input($name, '1', {
        TYPE  => 'checkbox',
        STATE => $plugins_enabled->{$name} ? 1 : 0,
        class => 'plugin_checkbox'
      }),
      $plugin->{NAME},
      ($plugin->{DESCR} || $plugin->{NAME}),
      $plugin->{MODULE}
    );
  }

  return $table->show({ OUTPUT_TO_RETURN => 1 });
}

#**********************************************************
=head2 _created_modal_priority($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _created_modal_priority {
  my ($position, $type) = @_;

  my $index = get_function_index('msgs_plugin_priority');

  my $priority_link = "?qindex=$index&header=2&POSITION=$position&TYPE=$type";

  return $html->button('', undef, {
    JAVASCRIPT     => '',
    SKIP_HREF      => 1,
    NO_LINK_FORMER => 1,
    ICON           => 'fa fa-upload',
    ex_params      => qq/onclick=loadToModal('$priority_link')/
  });
}

#**********************************************************
=head2 _msgs_get_save_plugin($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_get_save_plugin {
  my ($attr) = @_;

  my $plugins_enabled = $Msgs->msgs_plugin_list({
    AID         => $aid,
    PLUGIN_NAME => '_SHOW',
    PRIORITY    => '_SHOW'
  });

  return $plugins_enabled if ($attr->{HASH});

  my %list = map {$_->{plugin_name} => $_->{plugin_name}} @{$plugins_enabled};

  return \%list
}

#**********************************************************
=head2 _msgs_show_right_plugins($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_show_right_plugins {
  my ($Msgs, $attr) = @_;

  my $plugins_info = '';

  my $plugins = _msgs_get_plugins({ POSITION => 'RIGHT', AID => $admin->{AID} });
  foreach my $plugin (@{$plugins}) {
    next if (!$plugin->{PLUGIN}->can('new') || !$plugin->{PLUGIN}->can('plugin_show'));

    my $plugin_api = $plugin->{PLUGIN}->new($db, $admin, \%conf, {
      HTML             => $html,
      LANG             => \%lang,
      MSGS             => $Msgs,
      MSGS_PERMISSIONS => \%msgs_permissions
    });

    $plugins_info .= $plugin_api->plugin_show($attr);
  }

  return $plugins_info;
}

#**********************************************************
=head2 _msgs_show_bottom_plugins($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_show_bottom_plugins {
  my ($Msgs, $attr) = @_;

  my $plugins_info = '';

  my $plugins = _msgs_get_plugins({ POSITION => 'BOTTOM', AID => $admin->{AID} });
  foreach my $plugin (@{$plugins}) {
    next if (!$plugin->{PLUGIN}->can('new') || !$plugin->{PLUGIN}->can('plugin_show'));

    my $plugin_api = $plugin->{PLUGIN}->new($db, $admin, \%conf, {
      HTML             => $html,
      LANG             => \%lang,
      MSGS             => $Msgs,
      MSGS_PERMISSIONS => \%msgs_permissions
    });

    $plugins_info .= $plugin_api->plugin_show($attr);
  }

  return $plugins_info;
}

#**********************************************************
=head2 msgs_get_plugin_by_name($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub msgs_get_plugin_by_name {
  my ($plugin) = @_;

  return 0 unless $plugin;

  return if $plugin !~ /^[\w.]+$/;

  foreach my $module (@MODULES) {
    my $plugin_dir = $modules_dir . $module . '/Plugins';
    next unless (-d $plugin_dir);
    next unless (-e $plugin_dir . '/' . $plugin . '.pm');

    my $plugin_name = $module . '::Plugins::' . $plugin;
    eval "require $plugin_name;";
    if ($@) {
      $html->message('err', $lang{ERROR}, "$lang{PLUGIN_LOADING_ERROR}: $plugin ($@)");
      return 0;
    }

    return 0 if (!$plugin_name->can('new'));

    return $plugin_name->new($db, $admin, \%conf, {
      HTML             => $html,
      LANG             => \%lang,
      MSGS_PERMISSIONS => \%msgs_permissions
    });
  }

  return 0;
}

#**********************************************************
=head2 _plugin_enabled($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _plugin_enabled {
  my ($plugins_list, $enabled_plugins, $attr) = @_;

  my %hash_priory = map {$_->{plugin_name} => $_->{priority}} @{$enabled_plugins};

  foreach my $plugin (@{$plugins_list}) {
    my $name = $plugin->{PLUGIN};
    $name =~ s/$plugin->{MODULE}::Plugins:://g;

    next if !$attr->{$name};
    $Msgs->msgs_plugin_add({
      MODULE      => $plugin->{MODULE},
      PLUGIN_NAME => $name,
      PRIORITY    => $hash_priory{$name} || 0,
      ID          => $aid
    });
  }

}

1;
