#!/usr/bin/perl
# FreeBSD Linux Vlan Create

my $action   = $ARGV[0];
my $nas_ip   = $ARGV[1];
my $vlan_id  = $ARGV[2];
my $version  = '0.02';

use POSIX qw(strftime);


BEGIN {
  my $libpath = '../../../';
  $sql_type = 'mysql';
  unshift(@INC, '/usr/axbills/lib/');
  unshift(@INC, '/usr/axbills/AXbills/');
  unshift(@INC, "/usr/axbills/AXbills/$sql_type/");

  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath . "$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'libexec/');

  eval { require Time::HiRes; };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
  }
  else {
    $begin_time = 0;
  }
}

use vars qw(%conf $base_dir);
use FindBin '$Bin';

require $Bin . '/../../../libexec/config.pl';

use Sys::Hostname;

require AXbills::Base;
AXbills::Base->import();

my $argv = parse_arguments(\@ARGV);

my $ip_helper     = $argv->{IP_HELPER} || '';
my $nas_login     = $argv->{NAS_LOGIN} || 'axbills_admin';
my $nas_passwd    = $argv->{NAS_PASSWD}|| 'password';
my $unnumbered_if = $argv->{UNNUMBERED_IF} || '';
my $debug         = $argv->{DEBUG}     || 0;
my $cisco_log     = $var_dir.'/log/cisco.log';
my $skip_vlans    = $argv->{SKIP_VLANS} || '1,2,17';
my $IFCONFIG      = $conf{FILE_IFCONFIG} || 'ifconfig';
my $SSH           = $conf{FILE_SSH} || 'ssh';

my @output     = (); 
my @cmds       = ();
my @skip_vlans = ();

if ($skip_vlans) {
  @skip_vlans = split(/,/, $skip_vlans);
}


my $nas_port = 22;
if ($nas_ip && $nas_ip ne '0.0.0.0') {
  ($nas_ip, $nas_port) = split(/:/, $nas_ip, 2);
 
  if (! $nas_port) {
    $nas_port = 22;
  }
}
else {
  $nas_ip = undef;
}

my $SUDO  = $conf{FILE_SUDO} || 'sudo';
my $SSH   = $conf{FILE_SSH} || '/usr/bin/ssh';
my $SCP   = $conf{FILE_SCP} || '/usr/bin/scp';


$conf{VLAN_IF_CREATE} = 'if [ `uname` = Linux ]; then /usr/bin/sudo /sbin/vconfig add %PARENT_INTERFACE% %VLAN_ID%; else /usr/local/bin/sudo /sbin/ifconfig vlan%VLAN_ID% create vlan %VLAN_ID% vlandev %PARENT_INTERFACE% up; fi' if (!$conf{VLAN_IF_CREATE});

$conf{VLAN_IF_IP} = 'if [ `uname` = Linux ]; then /usr/bin/sudo /sbin/ifconfig %PARENT_INTERFACE%.%VLAN_ID% %VLAN_IF_IP% netmask %VLAN_IF_NETMASK% up; else /usr/local/bin/sudo /sbin/ifconfig vlan%VLAN_ID% inet %VLAN_IF_IP% netmask %VLAN_IF_NETMASK%; fi' if (!$conf{VLAN_IF_IP});

$conf{VLAN_IP_DELETE} = 'if [ `uname` = Linux ]; then /usr/bin/sudo /sbin/ifconfig %PARENT_INTERFACE%.%VLAN_ID% delete %VLAN_IF_IP%; else /usr/local/bin/sudo /sbin/ifconfig vlan%VLAN_ID% delete %VLAN_IF_IP%; fi' if (!$conf{VLAN_IP_DELETE});

$conf{VLAN_IF_DESTROY} = 'if [ `uname` = Linux ]; then /usr/bin/sudo /sbin/ifconfig %PARENT_INTERFACE%.%VLAN_ID% down;  /usr/bin/sudo /sbin/vconfig rem %PARENT_INTERFACE%.%VLAN_ID%; else /usr/local/bin/sudo /sbin/ifconfig vlan%VLAN_ID% destroy; fi' if (!$conf{VLAN_IF_DESTROY});

$conf{VLAN_CREATE_PPPOE} = undef if (!$conf{VLAN_CREATE_PPPOE});



if ($action) {
  if ($action eq 'add') {
    &create_vlan($nas_ip, $vlan_id, $ip_helper);
  }
  elsif ($action eq 'del') {
    &del_vlan($nas_ip, $vlan_id, $ip_helper);
  }
  elsif ($action eq 'info') {
    &vlan_info($nas_ip);
  }
  elsif ($action eq 'show') {
    print &show_conf($nas_ip, $vlan_id, $ip_helper);
  }
}
else {
  &help();
  exit;
}


if ($#cmds > -1) {
  my $cmd = join('; ', @cmds);

  if ($nas_ip && $nas_ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
    $cmd = "$SSH -p $nas_port -o StrictHostKeyChecking=no -i $base_dir/Certs/id_dsa.$nas_login $nas_login\@$nas_ip  \"$cmd\"";
  }

  if ($debug > 2) {
    print $cmd."\n";
  }

  system($cmd) if ($debug < 5);
  #$debug_output .= "$cmd\n" if ($debug > 2);

}


#************************************************
#
#************************************************
sub show_conf {
  my ($nas_ip, $vlan_id, $attr)=@_;

  my $IFCONFIG_CMD = $IFCONFIG;
  if ($nas_ip) {
    $IFCONFIG_CMD = "$SSH -p $nas_port -o StrictHostKeyChecking=no -i $base_dir/Certs/id_dsa.$nas_login $nas_login\@$nas_ip \"$IFCONFIG\"";
  }

  print $IFCONFIG_CMD. "\n" if ($debug && $debug > 2);
  my $ifconfig = '';

  open(IFCONFIG, "$IFCONFIG_CMD | ") || die "Can't open '$IFCONFIG_CMD' $!";
    while (my $l = <IFCONFIG>) {
      $ifconfig .= $l;
    }
  close(IFCONFIG);
  
  return $ifconfig;
}


#************************************************
#
#************************************************
sub vlan_info  {
  my ($nas_ip, $vlan_id, $attr)=@_;

  my %VLAN_INFO    = ();
  my $vlan_count   = 0;

  my $ifconfig = show_conf($nas_ip);

  #FreeBSD 6.xx VLANS analize
  #\s.*[\n\sa-zA-Z0-9:]+\n\s.*\n\s.*\n\s.*\n
  while ($ifconfig =~ m/vlan(\d+): .+\n((\s+inet \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}.+\n)?\s.*[\n\sa-zA-Z0-9]+\n\s.*\n)/gi) {
    my $ip        = '0.0.0.0';
    my $if_num    = $1;
    my $res       = $2;
    my $res2      = $3 || '';
    my $parent_if = '';
    my $netmask   = '';

    if ($res2 =~ /\s+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+netmask (\S+).+/) {
      $ip      = $1;
      $netmask = $2;
    }

    if ($res =~ /interface: (\S+)$/g) {
      $parent_if = $1;
    }

    $VLANS{$if_num} = $ip if (!$attr->{PARENT_IF} || $attr->{PARENT_IF} eq $parent_if);

    print "Vlan: $if_num IP: $ip NETMASK: $netmask Parent: '$parent_if'\n/$res/$res2/\n" if ($debug && $debug > 4);

    $vlan_count++;
  }

  #FreeBSD 7.xx VLANS analize
  while ($ifconfig =~ m/vlan(\d+): .+\n\s+.+\n\s+.+\n((\s+inet\s+\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\s+netmask.+\n)?\s.*[\n\sa-zA-Z0-9:]+\n\s.*\n)/gi) {
    my $ip        = '0.0.0.0';
    my $if_num    = $1;
    my $res       = $2;
    my $res2      = $3 || '';
    my $parent_if = '';
    my $netmask   = '';

    if ($res2 =~ /\s+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+netmask (\S+).+/) {
      $ip      = $1;
      $netmask = $2;
    }

    if ($res =~ /interface: (\S+)$/g) {
      $parent_if = $1;
    }

    $VLANS{$if_num} = $ip if (!$attr->{PARENT_IF} || $attr->{PARENT_IF} eq $parent_if);
    $VLANS{$if_num}{NETMASK}=$netmask;

    print "Vlan: $if_num IP: $ip NETMASK: $netmask Parent: '$parent_if'\n/$res/$res2/\n" if ($debug && $debug > 4);

    $vlan_count++;
  }

  print "Vlan count: $vlan_count\n" if ($debug && $debug > 4);

  #Linux
  while ($ifconfig =~ m/(\S+)\.(\d+) .+\n\s+inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+Bcast:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})  Mask:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/gi) {
    my $parent_if = $1;
    my $if_num    = $2;
    my $ip        = $3;
    my $brodcast  = $4 || '';
    my $netmask   = $5;

    $VLANS{$if_num} = $ip;    # if (! $attr->{PARENT_IF} || $attr->{PARENT_IF} eq $parent_if);

    print "Vlan: $if_num IP: $ip Parent: '$parent_if'\n" if ($debug && $debug > 4);
  }

  #return \%VLANS;  
  
  foreach my $vlan_id (sort keys %VLANS) {
    print "$vlan_id:$VLANS{$vlan_id}:$VLANS{$vlan_id}{NETMASK}\n";
  }
  
  exit;
}

#************************************************
#
#************************************************
sub create_vlan () {
  my ($nas_ip, $vlan_id, $ip_helper)=@_;

  @cmds = ();

  my @vlan_array = split(/,/, $vlan_id);
  
  foreach my $vlan_info (sort @vlan_array) {
    my ($vlan_id, $ip, $netmask,$parent_interface)=split(/:/, $vlan_info);

    if (int($vlan_id)<1) {
      next
    }
    elsif(in_array($vlan_id, \@skip_vlans)) {
      if ($debug > 2) {
        print "Skip vlan: $vlan_id\n";  
      }
      next;
    }

    if ($ip !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
      $ip = '0.0.0.0';
    }

    push @cmds, tpl_parse($conf{VLAN_IF_CREATE}, {
          PARENT_INTERFACE=> $parent_interface,
         VLAN_ID         => $vlan_id,
         VLAN_IF_IP      => $ip,
         VLAN_IF_NETMASK => $netmask,
     });

    if ($ip ne '0.0.0.0') {
      push @cmds, tpl_parse($conf{VLAN_IF_IP}, {
         PARENT_INTERFACE=> $parent_interface,
         VLAN_ID         => $vlan_id,
         VLAN_IF_IP      => $ip,
         VLAN_IF_NETMASK => $netmask,
         });
    }
  }

}


#************************************************
#
#************************************************
sub del_vlan () {
  my ($nas_ip, $vlan_id, $ip_helper)=@_;

  @cmds = ();

  my @vlan_array = split(/,/, $vlan_id);
  my $parent_interface = '';
  
  foreach my $vlan_info (sort @vlan_array) {
    my ($vlan_id, $ip, $netmask)=split(/:/, $vlan_info);
    if (int($vlan_id)<1) {
      next
    }
    elsif(in_array($vlan_id, \@skip_vlans)) {
      next;
    }

    push @cmds, tpl_parse(
          $conf{VLAN_IF_DESTROY},
          {
            VLAN_ID          => $vlan_id,
            PARENT_INTERFACE => $parent_interface
          }
        );

  }
}


#************************************************
#
#************************************************
sub help () {

print << "[END]";
cisco_vlan.pl action (add|del|info|show) NAS_IP VLAN_ID

Version: $version

NAS_LOGIN=  - login for NAS
NAS_PASSWD= - password for NAS
IP_HELPER=  - ip hellper ip
UNNUMBERED_IF - unnumbered if

DEBUG       - debug mode

[END]

}
      

####################################################################################################
#Приклад конфігу DCHP-сервера для трьох абонентів.
#
#
## Subnet Cisco1 /22 (165.23.4.0/22)
#subnet 165.23.4.0 netmask 255.255.252.0 {
#        option routers 165.23.4.1;
#        option domain-name-servers 8.8.8.8, 8.8.4.4;
#        default-lease-time 420;
#        min-lease-time 300;
#        max-lease-time 600;
#
#class "ip-165.23.6.2-vlan-851" {
#    match if binary-to-ascii(10, 16, "", substring(option agent.circuit-id, 2, 2)) = "851"
#    and substring(option agent.remote-id, 2, 15) = "Cisco1";
#    }
#    pool {
#        range 165.23.6.2;
#        allow members of "ip-165.23.6.2-vlan-851";
#    }
#
#class "ip-165.23.6.3-vlan-101" {
#    match if binary-to-ascii(10, 16, "", substring(option agent.circuit-id, 2, 2)) = "101"
#    and substring(option agent.remote-id, 2, 15) = "Cisco1";
#    }
#    pool {
#        range 165.23.6.3;
#        allow members of "ip-165.23.6.3-vlan-101";
#    }
#
#class "ip-165.23.6.5-vlan-651" {
#    match if binary-to-ascii(10, 16, "", substring(option agent.circuit-id, 2, 2)) = "651"
#    and substring(option agent.remote-id, 2, 15) = "Cisco1";
#    }
#    pool {
#        range 165.23.6.5;
#        allow members of "ip-176.98.6.5-vlan-651";
#    }
#    
#}
#
#Тут рядок: match if binary-to-ascii(10, 16, "", substring(option agent.circuit-id, 2, 2)) = "851"
#отримує від циски номер вілану 851, з якого надійшов DHCP-запит,
#а рядок: substring(option agent.remote-id, 2, 15) = "Cisco1"
#отримує назву циски Cisco1 з якої надійшов DHCP-запит, ця назва задається в конфігу циски,
#відповідно потрібно передбачити поле в налаштуваннях сервера доступу в біллінгу, де б цю назву
#можна було би вказати.
#Маючи номер вілану і ідентифікатор циски DHCP-сервер може точно ідентифікувати абонента.
#
#Конфіги циски і DHCP-сервера 100% робочі, перевірені на декількох провайдерах з nodeny і nodeny+.








