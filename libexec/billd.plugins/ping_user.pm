#!perl
=head1 NAME

  Ping plugins diagnostic user internet conection

  Arguments:
    IP       = user IP adress
    LOGIN    = user login
    NO_CHECK = true/fals - Ping user without check in 'no_ping' list

=cut

use AXbills::Base qw/cmd in_array startup_files/;
use Conf;
use Ping;
use POSIX qw( strftime mktime );
use Dv_Sessions;
use Events;
use threads;

our ($db, $debug, $Admin, %permissions, $argv);

our $new_line = "\n";

our $Ping     = Ping->new($db, $Admin, \%conf);
our $Sessions = Dv_Sessions->new($db, $Admin, \%conf);
our $Conf     = Conf->new($db, $Admin, \%conf);
my  $Event    = Events->new($db, $Admin, \%conf);

ping_user();

#**********************************************************
=head2 ping_user() - Ping web interface setting

=cut
#**********************************************************
sub ping_user {
  my %conf_param;

  my $list = $Conf->config_list({ COLS_NAME => 1 });

  foreach my $conf_var (@$list) {
    $conf_param{ $conf_var->{param} } = $conf_var->{value};
  }

  if ($debug > 3) {
    print $LIST_PARAMS{LOGIN} if($LIST_PARAMS{LOGIN});
  }

  $LIST_PARAMS{LOGIN}     =  $argv->{LOGIN}if($argv->{LOGIN});
  $LIST_PARAMS{USER_NAME} = $LIST_PARAMS{LOGIN} if($LIST_PARAMS{LOGIN});
  $LIST_PARAMS{CLIENT_IP} = $argv->{IP} if($argv->{IP});

  my $online_users_list = $Sessions->online(
    {
      UID       => '_SHOW',
      CLIENT_IP => '_SHOW',
      USER_NAME => $LIST_PARAMS{USER_NAME},
      %LIST_PARAMS,
    }
  );

  my $threads_num = 0;

  if( $conf_param{THREADS} && $Sessions->{TOTAL} < $conf_param{THREADS}){
    $threads_num    = $Sessions->{TOTAL};
    $conf_param{THREADS}  = $Sessions->{TOTAL};
    printf "Total = $Sessions->{TOTAL} Threads = $conf_param{THREADS}";
  }
  elsif($conf_param{THREADS}){
    $threads_num =   ($Sessions->{TOTAL} % $conf_param{THREADS}) == 0 ? $conf_param{THREADS}:$Sessions->{TOTAL} % $conf_param{THREADS};
  }
  else{
    $conf_param{THREADS} = 1;
    $threads_num   = 1;
  }
    printf "Total = $Sessions->{TOTAL} Threads = $conf_param{THREADS}";

  my $i = 0;
  my %user_who_be_ping;

  foreach my $user (@{$online_users_list}) {
    my $user_online_check;

    if($argv->{NO_CHECK} || ping_access_check($user->{uid})){

      $user_online_check = $Sessions->online({UID => $user->{uid}});

      if($argv->{NO_CHECK} || $user_online_check){
        ++$i;
        $user_who_be_ping{$user->{uid}} = $user->{client_ip};

        if($threads_num == $i){
           my @threads;

          foreach my $user_uid (keys %user_who_be_ping){
            push @threads, threads->create(\&ping_comand_builder, \%conf_param, { UID => $user_uid, IP => $user_who_be_ping{$user_uid} });
            delete $user_who_be_ping{$user_uid};
          }

          foreach my $thread (@threads) {
            my (%ping_result_add, %ping_result_event_add) = $thread->join();

            $Ping->add( {%ping_result_add} );
            $Event->events_add( {%ping_result_event_add, EXTRA => "/admin/index.cgi?get_index=ping_reports&full=1&ID=$Ping->{ID}",} );
          }

          $threads_num = $conf_param{THREADS};
          $i=0;
          sleep($conf_param{PING_PERIODIC} ? $conf_param{PING_PERIODIC} : 60);
        }
      }
    }
  }

  if ($debug > 3) {
    print 'Script finish worck'."\n";
  }

  return 1;
}

#**********************************************************
=head2 ping_comand_builder() - Create comand ping (string)
                               with params
   Arguments:

    $ip      - ip of ping user
    $attr    - Extra params

   Returns:

    return command result string

  Examples:
=cut
#**********************************************************
sub ping_comand_builder {
  my ($conf_param, $attr) = @_;

  my %PARAMS;
  my $ping_directory = startup_files();
  my $comand_string  = "$ping_directory->{PING} -q -v";

  if ($debug > 3) {
    print "Start ping IP:$attr->{IP} UID:$attr->{UID} $new_line";
  }

  if (!$attr->{UID}) {
    if ($debug > 3) {
      print "NO UID $new_line";
    }
    return 1;
  }

  %PARAMS = (
    -c => ($conf_param->{PACKET_NUM}  && $conf_param->{PACKET_NUM} < 100)     ? "$conf_param->{PACKET_NUM}"  : '10',
    -s => ($conf_param->{PACKET_SIZE} && $conf_param->{PACKET_SIZE} < 100000) ? "$conf_param->{PACKET_SIZE}" : '1000',
    -i => ($conf_param->{PERIODIC} && $conf_param->{PERIODIC} > 0.2 && $conf_param->{PERIODIC} < 100) ? "$conf_param->{PERIODIC}" : '1',
  );

  #-w timeout for ping if stack
  my $timeout = $PARAMS{-i} * $PARAMS{-c} + 10 + ($conf_param->{TIMEOUT} ? $conf_param->{TIMEOUT} : 30);

  if ($debug > 3) {
    print "timeout = $timeout" . $new_line;
  }

  foreach my $param_name (keys %PARAMS) {
    $comand_string .= " $param_name $PARAMS{$param_name}";
    if ($debug > 3) {
      print "$param_name = $PARAMS{$param_name}" . $new_line;
    }
  }

  my $result = cmd(
    "$comand_string" . " $attr->{IP}",
    {
      DEBUG => $debug > 8 ? 1 : 0,
      SHOW_RESULT => 1,
      timeout     => $timeout,
    }
  );

  if ($debug > 3) {
    print "Comand = $comand_string  $attr->{IP}" . $new_line;
    print "$result" . $new_line;
  }

  $result =~ s/\n/ /g;
  my %ping_result_add;
  my %ping_result_event_add;
  my ($transmitted, $racaived, $rate_loss, $avg_time) = $result =~ /.*[---]\s(\d+).*[,]\s(\d+).*[,]\s(\d+).*\%.+\/(\d+).+\/.+\/.+/;

  if (!(defined($transmitted) && defined($racaived) && defined($rate_loss) && defined($avg_time))) {
    ($transmitted, $racaived, $rate_loss) = $result =~ /.*[---]\s(\d+).*[,]\s(\d+).*[,].*\s(\d+)\%/;
    $avg_time = 0;
  }

  if ($debug > 8) {
    print "Loss rate = " .   ($rate_loss   || 0) . $new_line . "Time =" .     ($avg_time || 0) . $new_line;
    print "Transmitted = " . ($transmitted || 0) . $new_line . "Racaived =" . ($racaived || 0) . $new_line;
  }

  if (defined($transmitted) && defined($racaived) && defined($rate_loss)) {

    %ping_result_add = (
      UID         => $attr->{UID},
      LOSS_RATE   => $rate_loss,
      TRANSMITTED => $transmitted,
      RACAIVED    => $racaived,
      AVG_TIME    => $avg_time
    );

    if ($rate_loss > ($conf_param->{CRITICAL_RATE_LOSSES} ? $conf_param->{CRITICAL_RATE_LOSSES} : 90) || $transmitted != $racaived) {
      if ($transmitted != $racaived) {
        %ping_result_event_add = (
          MODULE      => "Ping",
          COMMENTS    => "No racaived on ping: $attr->{UID}",
          PRIORITY_ID => 3,
        );

      }
      if ($rate_loss > "$conf_param->{CRITICAL_RATE_LOSSES}") {
        %ping_result_event_add = (
          MODULE      => "Ping",
          COMMENTS    => "Critical packet loss in user: $attr->{UID}",
          PRIORITY_ID => 3,
        );
      }
    }
  }
  else {
    %ping_result_add = (
      UID         => $attr->{UID},
      LOSS_RATE   => 0,
      TRANSMITTED => 0,
      RACAIVED    => 0,
      AVG_TIME    => 0,
    );
    %ping_result_event_add = (
      MODULE      => "Ping",
      COMMENTS    => "Cant transmitted packets: $attr->{UID}",
      PRIORITY_ID => 3,
    );
  }

  return (%ping_result_add, %ping_result_event_add);
}

#**********************************************************
=head2 ping_access_check() - Check if can transmitted packets to user

  Arguments:
    $uid

  Returns:
    0 or 1

  Examples:
    ping_access_check($uid)

=cut
#**********************************************************
sub ping_access_check {
  my ($uid) = @_;
  my $transmitted_attempts = 0;
  my $info = $Ping->list(
    {
      TRANSMITTED => '_SHOW',
      UID         => $uid,
      PAGE_ROWS   => 2,
      DESC        => 'desc',
      COLS_NAME   => 1,
    }
  );

 if(!$Ping->{TOTAL}) {
    return 1;
  }

  foreach my $usr_info (@$info){
     $transmitted_attempts += $usr_info->{transmitted} == 0 ? 1 : 0;
  }
  if($transmitted_attempts < 2){
     return 1;
  }
  else{
     return 0;
  }

}

1
