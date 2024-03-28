package AXbills::Nas::Mikrotik::SSH;

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(cmd _bp ssh_cmd);

use constant {
  parseable_postfix => ' detail',
  generated_comment => 'ABillS generated'
};

use constant {
  LIST_REFS => {
    'dhcp_leases'            => "/ip dhcp-server lease print" . parseable_postfix,
    'dhcp_leases_generated'  =>
    "/ip dhcp-server lease print " . parseable_postfix . " where comment=\"" . generated_comment . "\"",

    'dhcp_servers'           => "/ip dhcp-server print" . parseable_postfix,
    'ip_a'                   => "/ip address print" . parseable_postfix,
    'dhcp_networks'          => "/ip dhcp-server network print" . parseable_postfix,
    'interfaces'             => "/interface print" . parseable_postfix,
    'adverts'                => '/ip hotspot user profile print detail where name="default"',
    'radius'                 => '/radius print' . parseable_postfix,
    'routes'                 => '/ip route print terse',
    'ppp_accounts'           => '/ppp secret print' . parseable_postfix,
    'firewall_nat'           => '/ip firewall nat print' . parseable_postfix,
    'queue_tree'             => '/queue tree print' . parseable_postfix,
    'queue_type'             => '/queue type print' . parseable_postfix,
    'queue_simple'           => '/queue simple print' . parseable_postfix,
    'firewall_address__list' => '/ip firewall address-list print' . parseable_postfix,
    'firewall_filter_list'   => '/ip firewall filter print' . parseable_postfix,
    'log_print'              => '/log print' . parseable_postfix
  }
};

my $DEBUG_ARGS = { TO_CONSOLE => 1 };
our $base_dir;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $host - NAS Info
    $attr - hash_ref
      ADMIN_NAME    - login for admin with write access (axbills_admin)
      IDENTITY_FILE - path to SSH private key (/usr/axbills/Certs/id_rsa.$attr->{ADMIN_NAME})
      SSH_PORT      - port for SSH (22)
      SSH_EXECUTIVE - ssh program path (`which ssh`)

  Returns:
    object

=cut
#**********************************************************
sub new($;$) {
  my $class = shift;
  my ($host, $CONF, $attr) = @_;

  my $self = {};
  bless($self, $class);

  $host->{nas_mng_ip_port} = $host->{nas_mng_ip_port} ? $host->{nas_mng_ip_port}
                                                      : ($host->{NAS_MNG_IP_PORT}) ? $host->{NAS_MNG_IP_PORT}
                                                                                   : 0;

  return 0 unless ($host->{nas_mng_ip_port});

  my ($nas_ip, $coa_port, $ssh_port) = split(":", $host->{nas_mng_ip_port});
  $self->{host} = $nas_ip || return 0;
  $self->{ssh_port} = $ssh_port || $coa_port || 22;

  $self->{admin} = $host->{NAS_MNG_USER} || 'axbills_admin';

  $base_dir //= '/usr/axbills';
  my $certs_dir = "$base_dir/Certs";
  $self->{ssh_key} = $attr->{IDENTITY_FILE} || $certs_dir . '/id_rsa.' . $self->{admin};
  $self->{ssh} = $attr->{SSH} || $CONF->{SSH_FILE} || `which ssh`;
  chomp($self->{ssh});

  $self->{FROM_WEB} = $attr->{FROM_WEB};

  if ($attr->{DEBUG}) {
    $self->{debug} = $attr->{DEBUG};
    if ($attr->{FROM_WEB}) {
      $DEBUG_ARGS = { TO_WEB_CONSOLE => 1 };
      #      delete $DEBUG_ARGS->{TO_CONSOLE};
    }
  }
  else {
    $self->{debug} = 0;
  }

  # Allowing to use custom message functions
  if ($attr->{MESSAGE_CALLBACK} && ref $attr->{MESSAGE_CALLBACK} eq 'CODE') {
    $self->{message_cb} = $attr->{MESSAGE_CALLBACK};
  }
  else {
    $self->{message_cb} = sub {print shift};
  }
  # Allowing to use custom error message functions
  if ($attr->{ERROR_CALLBACK} && ref $attr->{ERROR_CALLBACK} eq 'CODE') {
    $self->{error_cb} = $attr->{ERROR_CALLBACK};
  }
  else {
    $self->{error_cb} = sub {print shift};
  }

  return $self;
}

#**********************************************************
=head2 has_list_command($list_name) - checks if object has predefined command for list

  Arguments:
    $list_name -

  Returns:
    boolean

=cut
#**********************************************************
sub has_list_command {
  return unless $_[1];
  return exists LIST_REFS->{$_[1]} && defined LIST_REFS->{$_[1]};
}

#**********************************************************
=head2 execute($command) - Execute command in remote console

  Arguments:
    $command - string  or array of strings
    $attr - hash_ref
      SAVE_TO         - filename to save output
      SKIP_ERROR      - do not finish execution if error on one of commands

  Returns:
    1

=cut
#**********************************************************
sub execute {
  my $self = shift;
  my ($commands_input, $attr) = @_;

  $attr->{SSH_COMMAND_BASE} = $self->_form_ssh_command_args($attr);

  if (!ref $commands_input) {
    return $self->_ssh_single($commands_input, $attr);
  }
  else {
    foreach my $command (@{$commands_input}) {
      my $result = $self->_ssh_single($command, $attr);
      # Handle result
      if (!$result) {
        print " \n Error executing " . (ref $command ? $command->[0] : $command) . "\n" if ($self->{debug} > 1);
        next if ($attr->{SKIP_ERROR});
        $self->{errstr} = "Error executing " . (ref $command ? $command->[0] : $command);
        $self->{had_err} ||= 1;
        return 0;
      }
      return $result;
    }
    return 1;
  }
}

#**********************************************************
=head2 _form_ssh_command_args($attr) - forms command to execute in bash (without Mikrotik command)

  Arguments:
    $attr -

  Returns:


=cut
#**********************************************************
sub _form_ssh_command_args {
  my ($self) = @_;

  my $login = $self->{admin};
  my $identity_file_option = "-i $self->{ssh_key} ";

  my $port_option = ($self->{ssh_port} ne '22')
    ? " -p $self->{ssh_port}"
    : '';

  return "$self->{ssh} $identity_file_option"
    . ' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o CheckHostIP=no'
    . " $port_option $login\@$self->{host} ";
}

#**********************************************************
=head2 ssh_single($command, $attr) - executes single command via SSH

  Arguments:
    $command - command to execute
    $attr
      SAVE_TO          - file to save result
      SSH_COMMAND_BASE - ssh connection command

  Returns:
   1 if success or 0

=cut
#**********************************************************
sub _ssh_single {
  my $self = shift;
  my ($command, $attr) = @_;

  return unless $command;

  my $result = '';

  my $export_file_postfix = '';
  if ($attr->{SAVE_TO}) {
    $export_file_postfix = " > $attr->{SAVE_TO}";
  }
  else {
    # Redirecting STDERR to see output inside program
    $export_file_postfix = " 2>&1 ";
  }

  my $remote_command = '';
  if (ref $command eq 'ARRAY') {
    my ($chapter, $arguments, $query) = @{ $command };

    #    $chapter =~ s/ //g;
    $chapter =~ s/\// /g;
    $chapter =~ s/^ /\//g;

    $remote_command = $chapter . ' ';

    my $ssh_arguments = '';
    if ($arguments) {

      if (ref $arguments ne 'HASH') {
        _bp('Wrong command', $arguments);
      }

      foreach my $arg_key (keys %{$arguments}) {
        my $value = $arguments->{$arg_key}
            || (defined $arguments->{$arg_key})
          ? $arguments->{$arg_key}
          : next;

        if ($value =~ /[ ;=]/) {
          $value = qq{"$value"};
        }
        if (!$value) {
          $value = ($value eq '0') ? "'0'" : '""';
        }
        $ssh_arguments .= "$arg_key=$value ";
      }
    }

    my $query_string = '';
    if ($query) {
      if (scalar keys %{$query} == 1 && exists $query->{name}) {
        $remote_command .= $query->{name} . ' ';
      }
      elsif (scalar keys %{$query} == 1 && $query->{numbers}) {
        $query_string .= " numbers=$query->{numbers}";
      }
      elsif (scalar keys %{$query}) {
        $query_string .= ' where ';
        foreach my $query_key (keys %{$query}) {
          next if (!defined $query->{$query_key});
          if ($query->{$query_key} =~ /^\~(.*)/) {
            $query_string .= lc($query_key) . qq{~"$1" };
          }
          else {
            $query_string .= lc($query_key) . qq{="$query->{$query_key}" };
          }
        }
      }
    }

    $remote_command .= $ssh_arguments;
    $remote_command .= $query_string;
  }
  else {
    $remote_command = $command;
  }

  _bp("command called", "$remote_command \n", $DEBUG_ARGS) if ($self->{debug});

  # Form command
  #  my $com_base = $attr->{SSH_COMMAND_BASE} || $self->_form_ssh_command_args($attr);
  #  my $com = $com_base . "'$res_comand' $export_file_postfix";
  #  _bp( "Full command", $com, $DEBUG_ARGS ) if ($self->{debug} > 1);


  # Execute
  $remote_command =~ s/[\r\n]+/ /g;

  $result = ssh_cmd($remote_command, {
    NAS_MNG_IP_PORT => $self->{host} . '::' . $self->{ssh_port},
    NAS_MNG_USER    => $self->{admin},
    SSH_PORT        => $self->{ssh_port},
    BASE_DIR        => $base_dir,
    DEBUG           => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : undef
  });

  $result = join("\n", @{$result});
  # Omit openssh warning
  $result =~ s/^\s?Warning: Permanently added .*//;

  _bp("RESULT", "'$result'", $DEBUG_ARGS) if ($self->{debug} > 1);

  # Handle result;
  if ($result ne '') {
    my $skip = 0;

    if($remote_command =~ /\/log print/) {
      $skip=1;
      $attr->{SHOW_RESULT}=1;
    }

    if (! $skip && $result =~ /(error|failure|missing|ambiguos|not match|Permission denied|expected|invalid value|bad command|no such item|syntax error)/i) {
      $self->{error_cb}->($result, $remote_command) if ($self->{debug} || $attr->{SHOW_RESULT});
      return 0;
    }
    elsif ($attr->{SHOW_RESULT}) {
      return $result;
    }
    elsif ($self->{debug} > 1) {
      print "\n Result : $result \n";
    }
  }

  return 1;
}

#**********************************************************
=head2 get_list($command, $attr)

  Arguments:
    $command
    $attr - hash_ref

  Returns:
    arr_ref

=cut
#**********************************************************
sub get_list {
  my $self = shift;
  my ($list_name, $attr) = @_;

  my $command = LIST_REFS->{$list_name};

  if ($attr && ref $attr eq 'HASH' && $attr->{FILTER}) {
    $command = [ $command, '', $attr->{FILTER} ];
  }

  my $cmd_result = $self->_ssh_single($command, { SHOW_RESULT => 1 });

  return 0 if ($cmd_result eq '0');

  if ($command =~ / terse/) {
    return $self->parse_terse_list($cmd_result, $attr);
  }

  $cmd_result =~ s/^\s?Flags.*\n//; # Omitting flags row
  $cmd_result =~ s/\n//;       # Removing first new line
  $cmd_result =~ s/ {3}/ A /g; # Omitting empty status
  $cmd_result =~ s/^ //gm;     # Remove trailing spaces
  $cmd_result =~ s/ +/ /gm;    # Max one space in row
  $cmd_result =~ s/;;;.*\n//g; # Remove comments

  _bp("Result string that will be splitted", $cmd_result, $DEBUG_ARGS) if ($self->{debug} == 2);
  my @result_rows = split(/\n\s+\n/, $cmd_result);
  _bp("Result rows before parse", \@result_rows, $DEBUG_ARGS) if ($self->{debug} == 2);

  my @result_list = ();
  foreach my $line (@result_rows) {
    my %hash = ();

    $line =~ s/\n|\s+/ /g;
    $line =~ s/ +$//g;

    next if (defined $line && $line eq '');
    my @vars = split(" ", $line);
    $hash{id} = shift @vars;
    # Removing status
    $hash{flag} = shift @vars;
    foreach my $arg_val (@vars) {
      next if ($arg_val eq 'A');
      my ($arg, $val) = split("=", $arg_val);

      $val //= '';

      $val =~ s/"//g;
      $hash{$arg} = $val;
    }

    push @result_list, \%hash;
  }

  # _bp( "Result list", \@result_list, $DEBUG_ARGS ) if ($self->{debug} == 2);

  return \@result_list;
}

#**********************************************************
=head2 parse_terse_list($raw_input, $attr) -

  Arguments:
    $raw_input - raw SSH output

  Returns:
    list

=cut
#**********************************************************
sub parse_terse_list {
  my (undef, $raw_input) = @_;

  my @rows = split("\n", $raw_input);

  my @parsed_rows = ();
  foreach my $element (@rows) {
    my ($id, $flags) = $element =~ /^ (\d+) ([A-Z ]+) /;
    $element =~ s/^ (\d+) ([A-Z ]+) //;

    next if (!defined $id);

    my %parsed = ();
    $parsed{id} = $id;

    $flags =~ s/ //g;
    $parsed{flags} = $flags;

    # Deal with the rest of row
    my @key_values = split (' ', $element);
    my @parsed_pairs = ();
    for (my $i = 0; $i <= $#key_values; $i++) {
      my $pair = $key_values[$i];

      # Sometimes pair is string with spaces without \" (e.g 'gateway-status=192.168.1.1 reachable via ether1')
      # In this case should append all "losen" items to previous value
      if ($pair !~ /=/) {
        my $prev_pair = $parsed_pairs[$#parsed_pairs];
        $prev_pair->{value} .= ' ' . $pair;
        next;
      }

      my ($key, $value) = split('=', $pair);
      push (@parsed_pairs, { key => $key, value => $value });
    }

    # Move current pairs to this row hash
    foreach my $parsed_pair (@parsed_pairs) {
      $parsed{$parsed_pair->{key}} = $parsed_pair->{value};
    }

    push @parsed_rows, \%parsed;
  }

  return \@parsed_rows;
}

#**********************************************************
=head2 check_access() - checks if mikrotik is accessible

  Returns:
    boolean

=cut
#**********************************************************
sub check_access {
  my $self = shift;

  my $port_option = '';
  if ($self->{ssh_port} ne '22') {
    $port_option = " -p $self->{ssh_port}";
  }

  if (!-f $self->{ssh_key}) {
    return - 5; # File not exists
  }

  my $cmd = "$self->{ssh} -i $self->{ssh_key} $port_option -o BatchMode=yes"
    . ' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o CheckHostIP=no'
    . " $self->{admin}\@$self->{host} '/quit' 2>&1";
  _bp("ssh check result command", "Executing : $cmd \n", $DEBUG_ARGS) if ($self->{debug});

  my $cmd_result = cmd($cmd, { timeout => 5, SHOW_RESULT => 1, RETURN => 1 });
  $cmd_result =~ s/Warning: Permanently added .*//;
  $cmd_result =~ s/Could not create directory .*//;
  _bp("ssh check result", $cmd_result, $DEBUG_ARGS) if ($self->{debug} > 2);

  my $ok = $cmd_result !~ /Permission denied|Failed|denied/i;
  my $not_network_accessible = $cmd_result =~ /timed out|no route to host/i;

  if ($self->{FROM_WEB} && ($cmd_result !~ /interrupted/)) {
    print 'Mikrotik check access. ' . $cmd_result . "<br/>";
    return 0;
  }

  if ($not_network_accessible) {
    print "Error : $cmd_result";
    return 0;
  }

  return $ok;
}

1;
