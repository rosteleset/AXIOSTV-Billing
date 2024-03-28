package Internet::Tcpdump;

=head2 NAME

  Internet::Tcpdump;

=head2 SYNOPSYS

  Tcpdump module for Internet diagnostics

=cut

use strict;
use warnings 'FATAL' => 'all';
use IPC::Open3;
use AXbills::HTML;
use AXbills::Base qw/tpl_parse/;

#**********************************************************
=head2 new($attr) - constructor for Internet::Tcpdump

  Arguments:
    $attr
      db
      admin
      conf
      html

  Returns:
    $self

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  my $self = {
    db    => $attr->{db},
    admin => $attr->{admin},
    conf  => $attr->{conf},
    html  => $attr->{html}
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 stream_cmd(@cmd) - streams cmd's output to browser via event-stream

  Arguments:
    @cmd - command and it's arguments, to be passed to IPC::Open3::open3

  Returns:
    1

=cut
#**********************************************************
sub stream_cmd {
  my $self = shift;
  my @cmd = @_;

  my $pid = open3(undef, my $process_stdout, undef, @cmd);
  $SIG{TERM} = sub {
    kill('TERM', $pid);
    waitpid($pid, 0);
    exit 0;
  };

  local $| = 1;
  while( my $line = <$process_stdout> ) {
    $line =~ s/^/data: /g;
    print $line . "\n";
  }

  waitpid($pid, 0);
  my $process_status = ($? >> 8);
  print "data: " . ($process_status ? 'ERROR: ' : '') . "$cmd[0] exited with status $process_status\n\n";

  print "event: close\ndata:\n\n";

  return 1;
}

#**********************************************************
=head2 action($diagnostic, $params, $extra_url_param) - main action in module

  Arguments:
    $diagnostic  - URL diagnostic string
    $params - params (session info, etc)
    $extra_url_param - Extra URL parameter. Here - defines if function should print HTML page or event-stream with tcpdump's output
      'event-stream' - should start event-stream
      empty string   - should print HTML page

    Returns:
      0 - if internet_online() should exit after action() returned
      1 - if internet_online() should run to the end and print full page

    Example:
      $require_module->action($diagnostic, $params, $extra_url_param);
=cut
#**********************************************************
sub action {
  my $self = shift;
  my ($diagnostic, $params, $extra_url_param) = @_;

  if ($extra_url_param && $extra_url_param eq 'event-stream') {
    print "Content-type: text/event-stream\n\n";

    use Nas;
    my $Nas = Nas->new( $self->{db}, $self->{conf}, $self->{admin} );
    my $nas_info = $Nas->info({NAS_ID => $params->{NAS_ID}});
    my $nas_type = $nas_info->{NAS_TYPE} // '';
    my (undef, undef, $nas_ssh_port) = split(':', $nas_info->{NAS_MNG_IP_PORT});
    $nas_ssh_port ||= 22;

    if ($self->{conf}->{INTERNET_EXTERNAL_DIAGNOSTIC_TCPDUMP_SSH_PORT}) {
      $nas_ssh_port = $self->{conf}->{INTERNET_EXTERNAL_DIAGNOSTIC_TCPDUMP_SSH_PORT};
    }

    $params = { %$nas_info, %$params };

    my $base_dir = $main::base_dir || '/usr/axbills/';

    my @event_stream_cmd = ();

    if ($nas_type eq 'accel_ipoe') {
      push @event_stream_cmd, '/usr/bin/ssh', '-tt', '-o', 'StrictHostKeyChecking=no', '-o', 'LogLevel=FATAL', '-p', $nas_ssh_port;
      push @event_stream_cmd, '-i', tpl_parse("$base_dir/Certs/id_rsa.%NAS_MNG_USER%", $params);
      push @event_stream_cmd, tpl_parse('%NAS_MNG_USER%@%NAS_IP_ADDRESS%', $params);

      if ($params->{ACCT_SESSION_ID}) {
        push @event_stream_cmd,
          tpl_parse('INTERFACE=`accel-cmd ' . ($self->{conf}->{INTERNET_EXTERNAL_DIAGNOSTIC_ACCEL_CMD_EXTRA_PARAMS} || '') . ' show sessions ifname match sid %ACCT_SESSION_ID% | grep -o "ipoe[0-9]\\+"`;', $params) .
          'if [ $INTERFACE ];' .
            'then sudo tcpdump -n -vv -i $INTERFACE;' .
            'else echo "Failed to find interface to listen on for given session id";' .
          'fi';
      }
    }

    if (@event_stream_cmd) {
      $self->stream_cmd(@event_stream_cmd);
    }
    else {
      print "data: Tcpdump diagnostic only works on NAS with type 'accel-ipoe'\n\n";
      print "event: close\ndata:\n\n";
    }
  }
  else {
    print "Content-type: text/html\n\n";
    $self->{html}->tpl_show(
      main::_include('internet_tcpdump','Internet'),
      {URL => "index.cgi?get_index=internet_online&diagnostic=$diagnostic event-stream"}
    );
  }
  return 0;
}

1;
