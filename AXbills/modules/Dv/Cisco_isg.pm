=head2 NAME

  Cisco ISG web requests

  Cisco_isg AAA functions
  FreeRadius DHCP  functions
  http://www.cisco.com/en/US/docs/ios/12_2sb/isg/coa/guide/isgcoa4.html


=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(ip2int);
use Radius;
use Nas;
use Log;

our (
  $db,
  $admin,
  %conf,
  $html,
  $base_dir,
  %lang,
  $Isg
);

#our Log $Log;
my $Log = Log->new($db, \%conf);
my $Nas = Nas->new($db, \%conf, $admin);

#**********************************************************
=head2 cisco_isg_cmd($user_ip, $command, $attr) - Cisco ISG functions

  Arguments:
    $user_ip - User IP
    $command - Command
       account-status-query
       account-logon
       deactivate-service
       activate-service
       account-logon
       account-logoff

    $attr    -
      USER_NAME
      NAS_ID
      SERVICE_NAME
      CURE_SERVICE
      User-Password

  Results:
    True or False

=cut
#**********************************************************
sub cisco_isg_cmd {
  my ($user_ip, $command, $attr) = @_;

  my $debug = $conf{ISG_DEBUG} || 0;
  my $service_name = $attr->{SERVICE_NAME};

  if ($debug > 0) {
    print "Content-Type: text/html\n\n";
    print "Command: $command" . $html->br();
    print "User name: $attr->{USER_NAME}" . $html->br();
    print "User IP: $user_ip" . $html->br();
  }

  if (! $conf{DV_ISG} && ! $conf{INTERNET_ISG}) {
    return 1;
  }

  `echo "test isg: $user_ip" >> /usr/axbills_new/cgi-bin/isg`;

  #Get user NAS server from ip pools
  if ($attr->{NAS_ID}) {
    $Nas->info({ NAS_ID => $attr->{NAS_ID} });
  }
  else {
    my $list = $Nas->nas_ip_pools_list({
      ACTIVE_NAS_ID => '_SHOW',
      IP            => '_SHOW',
      LAST_IP_NUM   => '_SHOW',
      COLS_NAME     => 1
    });

    foreach my $line (@$list) {
      if ($line->{ip} <= ip2int($user_ip) && ip2int($user_ip) <= $line->{last_ip_num}) {
        $Nas->info({ NAS_ID => $line->{active_nas_id} });
        last;
      }
    }
  }

  if (!$Nas->{NAS_ID}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_UNKNOWN_IP}, { ID => 913 });
    return 0;
  }

  #Get Active session info
  my @RAD_REQUEST = (
    { 'User-Name'          => $attr->{USER_NAME} },
    { 'Cisco-Account-Info' => "S$user_ip" },
    { 'Cisco-AVPair'       => "subscriber:command=$command" }
  );

  # Deactivate cur service
  if ($attr->{CURE_SERVICE}) {
    push @RAD_REQUEST, { 'Cisco-AVPair' => "subscriber:service-name=$attr->{CURE_SERVICE}" };
  }

  if ($attr->{'User-Password'}) {
    push @RAD_REQUEST, { 'User-Password' => $attr->{'User-Password'} };
  }

  my %RAD_REPLY = ();
  my $type;

  my $r = Radius->new(
    Host   => $Nas->{NAS_MNG_IP_PORT},
    Secret => $Nas->{NAS_MNG_PASSWORD}
  ) or return "Can't connect '$Nas->{NAS_MNG_IP_PORT}' $!";


  $conf{'dictionary'} = $base_dir . '/lib/dictionary' if (!$conf{'dictionary'});
  $r->load_dictionary($conf{'dictionary'});
  $r->clear_attributes();
  $r->add_attributes(@RAD_REQUEST);
  $r->send_packet(43) and $type = $r->recv_packet;

  if (!defined $type) {
    my $message = "No responce from CoA server NAS ID: $Nas->{NAS_ID} '$Nas->{NAS_MNG_IP_PORT}' $! / ";

    $html->message('err', $lang{ERROR}, $message, { ID => 106 });
    $Log->log_add(
      {
        LOG_TYPE  => $Log::log_levels{'LOG_WARNING'},
        ACTION    => 'AUTH',
        USER_NAME => $attr->{USER_NAME} || '-',
        MESSAGE   => $message,
        NAS_ID    => $Nas->{NAS_ID} || 0
      }
    );

    return 0;
  }

  #Reply
  for my $ra ($r->get_attributes) {
    if ($ra->{'Value'} =~ /\$MA(\S+)/) {
      $Isg->{ISG_CID_CUR} = $1 || '';
    }
    elsif ($ra->{'Value'} =~ /^S(\S+)/) {
      $Isg->{ISG_CID_CUR} = $1 || '';
    }
    elsif ($ra->{'Name'} eq 'Reply-Message') {
      $Isg->{MESSAGE} = $ra->{'Value'};
    }
    elsif ($ra->{'Value'} =~ /^N1TURBO_SPEED(\d+);(\d+)/) {
      $Isg->{TURBO_MODE_RUN} = $2 || '';
    }
    elsif ($ra->{'Value'} =~ /^N1(TP_[0-9\_]+);(\d+)/) {
      $Isg->{CURE_SERVICE} = $1 || '';
      $Isg->{ISG_SESSION_DURATION} = $2 || 0;
    }

    $RAD_REPLY{ $ra->{'Name'} } = $ra->{'Value'};
    if ($debug > 0) {
      print "$ra->{'Name'} -> $ra->{'Value'}" . $html->br();
    }
  }

  if ($RAD_REPLY{'Error-Cause'}) {
    my $message = "ISG: $command, ERROR: $RAD_REPLY{'Error-Cause'}, MESSAGE: $RAD_REPLY{'Reply-Message'}";
    $html->message('err', $lang{ERROR}, $message, { ID => 100 });
    $Log->log_add(
      {
        LOG_TYPE  => $Log::log_levels{'LOG_WARNING'},
        ACTION    => 'AUTH',
        USER_NAME => $attr->{USER_NAME} || '-',
        MESSAGE   => $message,
        NAS_ID    => $Nas->{NAS_ID} || 0
      }
    );

    return 0;
  }

  my $return = 1;
  my $log_message = q{};

  if ($command eq 'account-status-query') {
    if (!$Isg->{ISG_CID_CUR}) {
      $html->message('err', $lang{ERROR}, "$lang{NOT_EXIST} ID: '$user_ip' ", { ID => 11 });
    }
    elsif ($Isg->{ISG_CID_CUR} =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
      my $DHCP_INFO;

      if($conf{INTERNET_ISG}) {
        $DHCP_INFO = internet_dhcp_get_mac($Isg->{ISG_CID_CUR});
      }
      else {
        $DHCP_INFO = dv_dhcp_get_mac($Isg->{ISG_CID_CUR});
      }

      $Isg->{ISG_CID_CUR} = $DHCP_INFO->{MAC} || '';
      if ($Isg->{ISG_CID_CUR} eq '') {
        $html->message('err', $lang{ERROR}, "IP: '$user_ip', MAC $lang{NOT_EXIST}. DHCP $lang{ERROR} ", { ID => 12 });
        return 0;
      }
    }
  }
  elsif ($command eq 'deactivate-service') {
  }
  elsif ($command eq 'activate-service') {
    $html->message('info', $lang{INFO}, "$lang{SERVICE} $lang{ENABLE}");
    $log_message = "SERVICE_ENABLE: '$service_name', IP: $user_ip";
  }
  elsif ($command eq 'account-logon') {
    $html->message('info', $lang{INFO}, "$lang{LOGON}");
    $log_message = "LOGON";
    $return = 0;
  }
  elsif ($command eq 'account-logoff') {
    $html->message('info', $lang{INFO}, $lang{LOGOFF});
    $log_message = "LOGOFF";
    $return = 0;
  }

  if( $log_message) {
    $Log->log_add(
      {
        LOG_TYPE  => $Log::log_levels{'LOG_INFO'},
        ACTION    => 'AUTH',
        USER_NAME => $attr->{USER_NAME} || '-',
        MESSAGE   => $log_message,
        NAS_ID    => $Nas->{NAS_ID} || 0
      }
    );
  }

  return $return;
}


1;
