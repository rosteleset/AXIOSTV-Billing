package AXbills::Telnet;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  AXbills::Telnet

=head2 SYNOPSIS

  Module for working with telnet

=cut

=head2 USAGE

  use AXbills::Telnet;
  my $t = AXbills::Telnet->new();

  $t->set_terminal_size(256, 1000);
  $t->prompt('\n.*#$');

  if (!$t->open($ip)) {
    $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
    return [];
  }

  if(!$t->login($username, $password)) {
    $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
    return [];
  }

  my $cmd_result = $t->cmd($cmd);


  Note for Mikrotik's:
  After log in, Mikrotik's tries to do auto detection of terminal capabilities. It will not work, because there is no real terminal, which connects to Mikrotik. In result, Mikrotik don't prints prompt for 10 seconds, because it tries to do auto detection.
  To disable auto detection (and colors), you should add "+ct" to login.
  Links about this issue:
  https://wiki.mikrotik.com/wiki/Manual%3aConsole_login_process#FAQ
  https://stackoverflow.com/questions/5926699/telnet-automation-with-expect-slow-authentication
  https://forum.mikrotik.com/viewtopic.php?p=124686

=cut

use Socket;

our $login_regexp = '(login|username)[: ]*$';
our $password_regexp = 'password[: ]*$';
our $default_prompt = '[\$%#>] $';

#**********************************************************
=head2 new($attr) - initializes new AXbills::Telnet object

  Arguments:
    $attr
      PROMPT - sets prompt to wait for - regexp (case insensitive, single line)
      TIMEOUT - sets waitfor's timeout - a whole number of seconds
      NO_CRLF - if set, prints LF ('\n') as end of line instead of required by telnet's standard CRLF ('\r\n').
                needed because some telnet servers (example - mpd's console) interprets CRLF as two newlines, not one.
                true or false

  Returns:
    $self

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  my $self = { };
  bless($self, $class);

  $self->{CLIENT_OPTIONS} = {};

  $self->{errstr} = '';

  $self->{PROMPT} = $attr->{PROMPT} || $default_prompt;
  $self->{TIMEOUT} = $attr->{TIMEOUT} || 5;
  $self->{NO_CRLF} = $attr->{NO_CRLF} ? 1 : 0;

  return $self;
}

#**********************************************************
=head2 errstr() - returns last error

  Returns:
    $errstr

=cut
#**********************************************************
sub errstr {
  my $self = shift;

  return $self->{errstr};
}

#**********************************************************
=head2 prompt($prompt) - if $prompt is set, replaces prompt with it, and returns old prompt. else just returns current prompt

  Arguments:
    $prompt

  Returns:
    $old_prompt

=cut
#**********************************************************
sub prompt {
  my $self = shift;
  my ($prompt) = @_;

  my $old_prompt = $self->{PROMPT};

  if ($prompt) {
    $self->{PROMPT} = $prompt;
  }

  return $old_prompt;
}

#**********************************************************
=head2 timeout($timeout) - if $timeout is set, replaces waitfor's timeout with it, and returns old timeout. else just returns current waitfor's timeout

  Arguments:
    $timeout - a whole number of seconds

  Returns:
    $old_timeout

=cut
#**********************************************************
sub timeout {
  my $self = shift;
  my ($timeout) = @_;

  my $old_timeout = $self->{TIMEOUT};

  if ($timeout) {
    $self->{TIMEOUT} = $timeout;
  }

  return $old_timeout;
}

#**********************************************************
=head2 no_crlf($no_crlf) - if $no_crlf is set, replaces NO_CRLF option with it, and returns old NO_CRLF option. else just returns current NO_CRLF option

  Arguments:
    $no_crlf - if set, prints LF ('\n') as end of line instead of required by telnet's standard CRLF ('\r\n').
               needed because some telnet servers (example - mpd's console) interprets CRLF as two newlines, not one.
               true or false

  Returns:
    $old_no_crlf

=cut
#**********************************************************
sub no_crlf {
  my $self = shift;
  my ($no_crlf) = @_;

  my $old_no_crlf = $self->{NO_CRLF};

  if ($no_crlf) {
    $self->{NO_CRLF} = $no_crlf;
  }

  return $old_no_crlf;
}

#**********************************************************
=head2 open($attr) - tries to do telnet connection. sends Will for defined client's telnet options, if any

  Arguments:
    $attr
      HOST - host to connect to
      PORT - port to connect to. by default 23
    OR
    $host_and_port - host and port (optionally, by default 23), delimited by colon (':')

  Returns:
    1 - on success
    0 - on error

=cut
#**********************************************************
sub open {
  my $self = shift;
  my ($attr) = @_;

  if (ref $attr eq 'HASH') {
    $self->{HOST} = $attr->{HOST};
    $self->{PORT} = $attr->{PORT};
  }
  else {
    ($self->{HOST}, $self->{PORT}) = split(/:/, $attr, 2);
  }

  $self->{PORT} ||= 23;

  $self->{DEST} = sockaddr_in($self->{PORT}, Socket::inet_aton("$self->{HOST}")); #FIXME: inet_aton does not support IPv6

  if (!socket($self->{SH}, PF_INET, SOCK_STREAM, getprotobyname('tcp'))) {
    $self->{errstr} = "Can't init socket: $!";
    return 0;
  }

  if (CORE::connect($self->{SH}, $self->{DEST})) {
    $self->{SH}->autoflush(1);
    $self->{CONNECTED} = 1;

    foreach my $option (keys %{$self->{CLIENT_OPTIONS}}) {
      if (!$self->send_telnet_command("\xfb" . #Will
        $option)) {
        return 0;
      };
    }
    return 1;
  }
  else {
    $self->{errstr} = "Can't connect to '$self->{HOST}:$self->{PORT}': $!";
    return 0;
  }
}

#**********************************************************
=head2 close() - tries to close telnet connection

  Returns:
    1 - on success
    0 - on error

=cut
#**********************************************************
sub close {
  my $self = shift;

  $self->{CONNECTED} = 0;
  if (close($self->{SH})) {
    return 1;
  }
  else {
    $self->{errstr} = "Can't close socket: $!";
    return 0;
  }
}

#**********************************************************
=head2 put($string) - puts raw string to socket

  Arguments:
    $string

  Returns:
    1 - on success
    0 - on error

=cut
#**********************************************************
sub put {
  my $self = shift;
  my ($string) = @_;

  if (!$self->{CONNECTED}) {
    $self->{errstr} = "Not connected";
    return 0;
  }

  if (send($self->{SH}, "$string", 0, $self->{DEST})) {
    return 1;
  }
  else {
    $self->close();
    $self->{errstr} = "Can't send '$string': $!";
    return 0;
  }
}

#**********************************************************
=head2 print($string) - puts string to socket, escaping FF bytes in it, and ending it with \r\n (or just \n if NO_CRLF is set)

  Arguments:
    $string

  Returns:
    1 - on success
    0 - on error

=cut
#**********************************************************
sub print {
  my $self = shift;
  my ($string) = @_;

  $string =~ s/\xff/\xff\xff/gs; #FF byte must be escaped by another FF, to prevent interpreting it as Interpret as Command

  my $end_of_line = $self->{NO_CRLF} ? "\n" : "\r\n";

  return $self->put("$string$end_of_line");
}

#**********************************************************
=head2 send_telnet_command($command) - sends telnet command, escaping FF bytes in it

  Arguments:
    $command

  Returns:
    1 - on success
    0 - on error

=cut
#**********************************************************
sub send_telnet_command {
  my $self = shift;
  my ($command) = @_;

  $command =~ s/\xff/\xff\xff/gs; #FF byte must be escaped by another FF, to prevent interpreting it as Interpret as Command
  return $self->put("\xff" . #Interpret as Command
    $command);
}

#**********************************************************
=head2 set_client_option($option, $suboption) - sets client option

  If there is open connection, will send command Will $option, else it will be send, when connection will be opened.
  $suboption will be sent by waitfor(), when it will see command Do $option from server.

  Arguments:
    $option
    $suboption

  Returns:
    1 - on success
    0 - on error

=cut
#**********************************************************
sub set_client_option {
  my $self = shift;

  my ($option, $suboption) = @_;
  $self->{CLIENT_OPTIONS}->{$option} = $suboption;

  if ($self->{CONNECTED}) {
    return $self->send_telnet_command("\xfb" . #Will
      $option);
  }

  return 1;
}

#**********************************************************
=head2 set_terminal_size($width, $height) - sets terminal size, using telnet command Negotiate About Window Size

  Warning: terminal size will be actually sent only after next call of waitfor(). see docs of set_client_option()

  Arguments:
    $width
    $height

  Returns:
    1 - on success
    0 - on error

=cut
#**********************************************************
sub set_terminal_size {
  my $self = shift;
  my ($width, $height) = @_;

  return $self->set_client_option("\x1f", #Negotiate About Window Size
    "\xfa\x1f" . #Suboption Negotiate About Window Size
     pack("n2", $width, $height) #two short integers in network order
  );
}

#**********************************************************
=head2 waitfor($waitfor) - waits for next prompt. returns text that is before the prompt.

  Arguments:
    $waitfor - prompt to wait for. regexp (case insensitive, single line)

  Returns:
    \@result_arr - lines of result
    0 - on error

=cut
#**********************************************************
sub waitfor {
  my $self = shift;
  my ($waitfor) = @_;

  if (!$self->{CONNECTED}) {
    $self->{errstr} = "Not connected";
    return 0;
  }

  my $input = '';
  my $MAXBUF = 512;
  my $inbuf = '';
  do {
    eval {
      local $SIG{ALRM} = sub {
        $self->{errstr} = "Timed out waiting for prompt. Last input: $input";
        die "alarm\n";
      };
      alarm $self->{TIMEOUT};
      if (!defined recv($self->{SH}, $inbuf, $MAXBUF, 0)) {
        $self->{errstr} = "Can't receive from socket. Last input: $input";
        die;
      }
      alarm 0;
    };

    if ($@) {
      return 0;
    }

    $input .= $inbuf;

    #respond to telnet commands Do and Will. Without this telnet on some devices (known for Mikrotik's) will not work.
    #responds Don't to Will, and Won't to Do, if requested client option is not set
    while ($input =~ s/\xff\xfd(.)//s) { #Interpret as Command, Do
      my $option = $1;
      if ($self->{CLIENT_OPTIONS}->{$option}) {
        $self->send_telnet_command($self->{CLIENT_OPTIONS}->{$option}) or return 0;
        $self->send_telnet_command("\xf0") or return 0; #Suboption End
      }
      else {
        $self->send_telnet_command("\xfc" . #Won't
          $1) or return 0;
      }
    }

    while ($input =~ s/\xff\xfb(.)//s) { #Interpret as Command, Will
      my $option = $1;
      $self->send_telnet_command("\xfe" . #Don't
        $option) or return 0;
    }

    $input =~ s/\xff(\xfe|\xfc).//gs; #delete telnet commands Won't and Don't from input

  } while ($input !~ /$waitfor/is);

  $input =~ s/\r//g;

  my ($result, $received_prompt) = $input =~ /(.*)($waitfor)/is;
  $self->{LAST_PROMPT} = $received_prompt;

  my @result_arr = split("\n", $result);
  return \@result_arr;
}

#**********************************************************
=head2 cmd($cmd, $attr) - runs command on server. first line of result (server echoes command back) and prompt is not returned

  Arguments:
    $cmd
    $attr
      PROMPT - sets prompt to wait for - regexp (case insensitive, single line)
      TIMEOUT - sets waitfor's timeout - a whole number of seconds
      NO_CRLF - if set, prints LF ('\n') as end of line instead of required by telnet's standard CRLF ('\r\n').
                needed because some telnet servers (example - mpd's console) interprets CRLF as two newlines, not one.
                true or false

  Returns:
    \@result_arr - lines of result
    0 - on error

=cut
#**********************************************************
sub cmd {
  my $self = shift;
  my ($cmd, $attr) = @_;

  if ($attr->{TIMEOUT}) {
    $self->timeout($attr->{TIMEOUT});
  }
  if ($attr->{PROMPT}) {
    $self->prompt($attr->{PROMPT});
  }
  if ($attr->{NO_CRLF}) {
    $self->no_crlf($attr->{NO_CRLF});
  }

  $self->print($cmd) or return 0;
  my $result_arr = $self->waitfor($self->{PROMPT}) or return 0;
  shift @$result_arr;

  return $result_arr;
}

#**********************************************************
=head2 login($cmd, $attr) - performs login on server

  If after sending username and password we get login prompt again, it means login failed.

  Arguments:
    $attr
      USERNAME
      PASSWORD
      PROMPT - sets prompt to wait for - regexp (case insensitive, single line)
      TIMEOUT - sets waitfor's timeout - a whole number of seconds
      NO_CRLF - if set, prints LF ('\n') as end of line instead of required by telnet's standard CRLF ('\r\n').
                needed because some telnet servers (example - mpd's console) interprets CRLF as two newlines, not one.
                true or false
    OR
    ($username, $password, $attr) - username and password, attr (optional)

  Returns:
    1 - on success
    0 - on error

=cut
#**********************************************************
sub login {
  my $self = shift;
  my $attr;

  my $username;
  my $password;

  if (@_ == 1) {
    ($attr) = @_;
    $username = $attr->{USERNAME};
    $password = $attr->{PASSWORD};
  }
  elsif (@_ >= 2) {
    ($username, $password, $attr) = @_;
  }

  if ($attr->{TIMEOUT}) {
    $self->timeout($attr->{TIMEOUT});
  }
  if ($attr->{PROMPT}) {
    $self->prompt($attr->{PROMPT});
  }
  if ($attr->{NO_CRLF}) {
    $self->no_crlf($attr->{NO_CRLF});
  }

  $self->waitfor($login_regexp) or return 0;
  $self->print($username) or return 0;
  $self->waitfor($password_regexp) or return 0;
  $self->print($password) or return 0;
  $self->waitfor("($self->{PROMPT})|($login_regexp)") or return 0;
  if ($self->{LAST_PROMPT} =~ /$login_regexp/is) {
    $self->{errstr} = "Login failed";
    return 0;
  }

  return 1;
}

1;
