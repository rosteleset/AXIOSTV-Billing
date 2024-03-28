=head1 NAME

  Tasks Plugins

=cut

use strict;
use warnings FATAL => 'all';

our(
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  $base_dir,
);

my $Tasks = Tasks->new($db, $admin, \%conf);
# my @plugins_files = glob "$base_dir/AXbills/modules/Tasks/Plugins/*.pm";
# my %PLUGINS = ();
# foreach my $file (@plugins_files) {
#   my (undef, $plugin) = $file =~ m/(.*\/)(.*)\.pm/;
#   $PLUGINS{$plugin} = $file;
# }

#**********************************************************
=head2 plugins_conig($attr)
  enable/disable avaiable plugins
=cut
#**********************************************************
sub plugins_conig {
  
  check_plugins();
  my $plugins_list = $Tasks->plugins_list();
  unless (length $plugins_list) {
    print "No plugins\n";
    return 1;
  }

  if ($FORM{SAVE}) {
    foreach my $line (@$plugins_list) {
      if ($line->{enable} && !$FORM{$line->{name}}) {
        $Tasks->disable_plugin($line->{name});
        $line->{enable} = 0;
      }
      elsif (!$line->{enable} && $FORM{$line->{name}}) {
        $Tasks->enable_plugin($line->{name});
        plugins_fn_loader({ PLUGINS => "$line->{name}", FN => "enable_plugin" });
        $line->{enable} = 1;
      }
    }
  }

  my $table = _plugins_table($plugins_list, { caption => $lang{PLUGINS} });
  $html->tpl_show('', { PLUGINS_TABLE => $table }, { TPL => 'plugins_config', MODULE => 'Tasks' });

  return 1;
}

#**********************************************************
=head2 enabled_plugins($attr)
  return table with plugins enabled in config
=cut
#**********************************************************
sub enabled_plugins {
  my $plugins_list = $Tasks->plugins_list({ENABLE => '1'});
  return '' unless (length $plugins_list);
  return _plugins_table($plugins_list);
}

#**********************************************************
=head2 _plugins_table($plugins_list)
  return table with checkboxes
=cut
#**********************************************************
sub _plugins_table {
  my ($plugins_list, $attr) = @_;

  my $table = $html->table({
    %{$attr->{caption} ? { caption => $attr->{caption} } : { } },
    width               => '100%',
    title_plain         => [ '#', $lang{NAME}, $lang{DESCRIBE}],
    ID                  => 'plugins_table',
  });

  foreach my $line (@$plugins_list) {
    # my $file = "$base_dir/AXbills/modules/Tasks/Plugins/$line->{name}.pm";
    # if (eval { require $file; 1; }) {
      $table->addrow(
        $html->form_input($line->{name}, '1', { TYPE => 'checkbox', class => 'plugin_checkbox', EX_PARAMS => ($line->{enable} ? 'checked' : '') }),
        $line->{name},
        ($line->{descr} || $line->{name}),
      );
    # }
  }
  return $table->show({OUTPUT_TO_RETURN => 1});
}

#**********************************************************
=head2 _task_plugin_call($attr)
  fn - name of plugin function
  ID - task id
=cut
#**********************************************************
sub _task_plugin_call {
  my ($attr) = @_;
  my $ret = '';

  return if $attr->{plugin} !~ /^[\w.]+$/;

  if (eval { require "Tasks/Plugins/$attr->{plugin}.pm"; 1; }) {
    my $obj = $attr->{plugin}->new($Tasks, $html, \%lang);
    my $fn = $attr->{fn};
    if ($obj->can($fn)) {
      $ret = $obj->$fn($attr);
    }
    return $ret;
  }
  return $ret;
}

#**********************************************************
=head2 plugins_fn_loader($attr)
  call fn from all plugins enabled in task and return output
=cut
#**********************************************************
sub plugins_fn_loader {
  my ($attr) = @_;
  my $output = '';

  my @task_plugins = ();

  if ($attr->{PLUGINS}) {
    @task_plugins = split(',', $attr->{PLUGINS});
  }
  elsif ($attr->{ID}) {
    my $task_info = $Tasks->info({ ID => $attr->{ID} });
    @task_plugins = split(',', $task_info->{PLUGINS} || q{});
  }

  foreach my $plugin (@task_plugins) {
    $output .= _task_plugin_call({ %$attr, fn => $attr->{FN}, plugin => $plugin });
  }
  return $output;
}

#**********************************************************
=head2 check_plugins()
  add new plugins, delete removed plagins to db
=cut
#**********************************************************
sub check_plugins {
  my $plugins_list = $Tasks->plugins_list();
  my @plugins_files = glob "$base_dir/AXbills/modules/Tasks/Plugins/*.pm";
  my %plugins = ();
  foreach my $file (@plugins_files) {
    my (undef, $plugin) = $file =~ m/(.*\/)(.*)\.pm/;
    $plugins{$plugin} = $file;
  }

  foreach my $line (@$plugins_list) {
    if ($plugins{$line->{name}}) {
      delete($plugins{$line->{name}});
    }
    else {
      $Tasks->plugins_del($line->{id});
    }
  }

  foreach my $name (keys %plugins) {
    $Tasks->plugins_add({
      NAME  => $name,
      DESCR => plugins_fn_loader({ PLUGINS => $name, FN => "plugin_info" }),
    });
  }

  return 1;
}


#**********************************************************
=head2 test_plugins()
  
=cut
#**********************************************************
# sub test_plugins {
#   use Tasks::Plugins::PeriodicTasks;
#   my $obj = PeriodicTasks->new($Tasks, $html, \%lang);

#   return 1;

# }

1;
