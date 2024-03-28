#!/usr/bin/perl
# Cisco vlan creator

my $action   = $ARGV[0];
my $nas_ip   = $ARGV[1];
my $vlan_id  = $ARGV[2];
my $version  = '0.04';


BEGIN {
  my $libpath = '../../../';
  $sql_type = 'mysql';
  unshift(@INC, '/usr/axbills/');
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

use FindBin '$Bin';
use POSIX qw(strftime);

require $Bin . '/../../../libexec/config.pl';

use Sys::Hostname;

require AXbills::Base;
AXbills::Base->import();
require "Misc.pm";


my $argv = parse_arguments(\@ARGV);

my $ip_helper     = $argv->{IP_HELPER} || '';
my $nas_login     = $argv->{NAS_LOGIN} || 'login';
my $nas_passwd    = $argv->{NAS_PASSWD}|| 'password';
my $unnumbered_if = $argv->{UNNUMBERED_IF} || '';
my $debug         = $argv->{DEBUG}     || 0;
my $cisco_log     = $var_dir.'/log/cisco.log';
my $skip_vlans    = $argv->{SKIP_VLANS} || '1,2,17';

my @output     = (); 
my @cmds       = ();
my @skip_vlans = ();

if ($skip_vlans) {
	@skip_vlans = split(/,/, $skip_vlans);
}


my $nas_port = 23;
if ($nas_ip && $nas_ip ne '0.0.0.0') {
  ($nas_ip, $nas_port) = split(/:/, $nas_ip, 2);
 
  if (! $nas_port) {
    $nas_port = 23;
  }
}


if ($action) {
  if ($action eq 'add') {
    &create_vlan($nas_ip, $vlan_id, $ip_helper);
  }
  elsif ($action eq 'del') {
    &del_vlan($nas_ip, $vlan_id, $ip_helper);
  }
  elsif ($action eq 'info') {
    vlan_info();
  }
  elsif ($action eq 'show') {
    &show_conf($nas_ip, $vlan_id, $ip_helper);
  }
}
else {
  &help();
  exit;
}

my $output = make_cmds(\@cmds);

if ($action eq 'show'|| $debug > 2) {
  print join("", @$output);
}



#************************************************
#
#************************************************
sub make_cmds {
  my ($cmds, $attr)=@_;

  load_pmodule('Net::Telnet::Cisco');

  my $session = Net::Telnet::Cisco->new(Host      => $nas_ip, 
                                        Input_log => "$cisco_log");

  $session->login("$nas_login", "$nas_passwd");

  foreach my $cmd ( @$cmds ) {
	  if ($debug > 2) {
		  print "==> $cmd \n";
	  }
    @output = $session->cmd("$cmd");
  }

  #$session->cmd("exit");
  $session->close;	

  my $DATE = strftime "%Y%m%d", localtime(time);
  my $TIME = strftime "%H%M%S", localtime(time);

  # Copy cisco log to logs directory
  if ($debug > 1) {
    my $cur_datetime = $DATE."_".$TIME;
    use File::Copy;
    copy("$cisco_log", "$cisco_log".'_'.$nas_ip."_vlan".$vlan_id."_".$cur_datetime.".log");
  }

	
	return \@output;
}

#************************************************
#
#************************************************
sub show_conf {
  my ($nas_ip, $vlan_id, $ip_helper)=@_;

  @cmds = ('show conf');
}


#************************************************
#
#************************************************
sub vlan_info  {
  my ($nas_ip, $vlan_id, $ip_helper)=@_;

  my %VLAN_INFO=();

  @cmds = ('show conf'
           );

  my $res = make_cmds(\@cmds);
  
  my $conf_text = join('', @$res); 
  
  my $i = 0;
  while($conf_text =~ m/interface Vlan(\d+)/gi) {
  	print "$1::\n";
  	$i++;
  } 
  
  exit;
}

#************************************************
#
#************************************************
sub create_vlan () {
  my ($nas_ip, $vlan_id, $ip_helper)=@_;

  @cmds = ('conf t');

  my @vlan_array = split(/,/, $vlan_id);
  
  foreach my $vlan_info (sort @vlan_array) {
    my ($vlan_id, $ip, $netmask)=split(/:/, $vlan_info);

    if (int($vlan_id)<1) {
    	next
    }
    elsif(in_array($vlan_id, \@skip_vlans)) {
    	if ($debug > 2) {
    	  print "Skip vlan: $vlan_id\n";	
    	}
    	next;
    }

    push @cmds, 'vlan '.$vlan_id,
      'exit',

      'interface vlan '.$vlan_id,
      ($unnumbered_if) ? "ip unnumbered $unnumbered_if" : '',
      ($ip_helper) ? 'ip helper-address '.$ip_helper : '',
      'no shut',
      'exit';
  }

  push @cmds,  'exit',
    'write';

}


#************************************************
#
#************************************************
sub del_vlan () {
  my ($nas_ip, $vlan_id, $ip_helper)=@_;

  @cmds = ('conf t');

  my @vlan_array = split(/,/, $vlan_id);
  
  foreach my $vlan_info (sort @vlan_array) {
    my ($vlan_id, $ip, $netmask)=split(/:/, $vlan_info);
    if (int($vlan_id)<1) {
    	next
    }
    elsif(in_array($vlan_id, \@skip_vlans)) {
    	next;
    }

    push @cmds,  "no interface Vlan$vlan_id",
    "no vlan $vlan_id";
  }

  push @cmds, "exit",  
   "write";
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








