#!/usr/bin/perl -w
# chillispot configure
#
# ! %HOTSPOT_WLAN_INTERFACE%
#  %HOTSPOT_RADIUS_IP%
#  %HOTSPOT_BILLING_IP%
# ! %RADIUS_PASSWORD% = NAS mng password
# ! %HTTPS_PORT% = $ENV{HTTP_HOST}
# 
#
#*************************************************


use strict;
use warnings 'FATAL' => 'all';

our( $DATE, $TIME, $var_dir, %conf );
BEGIN {
  my $libpath = '../';
  
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath . "AXbills/");
  unshift(@INC, $libpath . "lib/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'libexec/');
  
  # eval { require Time::HiRes; };
  # if (! $@) {
  #    Time::HiRes->import(qw(gettimeofday));
  #    $begin_time = gettimeofday();
  #   }
  # else {
  #    $begin_time = 0;
  #  }
}

require "config.pl";
use POSIX qw(strftime mktime ctime);
use AXbills::Base;
use AXbills::SQL;
use AXbills::HTML;
use Nas;
use Admins;

my $html = AXbills::HTML->new( { IMG_PATH => 'img/',
  NO_PRINT                               => 1,
  CONF                                   => \%conf,
  CHARSET                                => $conf{default_charset},
});

my $db = AXbills::SQL->connect($conf{dbtype},
  $conf{dbhost},
  $conf{dbname},
  $conf{dbuser},
  $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
#$db = $sql->{db};

our $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} } );

my $version = '0.7';
my $debug = 6;
my $log_file = $var_dir . "log/wrt_configure.log";
my $prefix_ = ''; #'axbills';

if ( $FORM{test} ) {
  print "Content-Type: text/plain\n\n";
  print "Test OK $DATE $TIME";
  exit;
}

use Conf;
my $Conf = Conf->new($db, $admin, \%conf);

my $lan_ip = "192.168.20.1";

if ( $FORM{LAN_IP} ) {
  $lan_ip = $FORM{LAN_IP};
}
elsif ( !$FORM{INTERNAL_SUBNET} ) {
  $FORM{INTERNAL_SUBNET} = '20';
  $lan_ip = "192.168.$FORM{INTERNAL_SUBNET}.1";
}

$FORM{"SSID"} = '' if (!$FORM{"SSID"});
$FORM{"DOMAIN_ID"} = 0 if (!$FORM{"DOMAIN_ID"});
if ( !$FORM{'NAS_ID'} ) {
  print "Content-Type: text/plain\n\n";
  print "Parameter NAS_ID not exist";
  exit;
}

my $Nas = Nas->new($db, \%conf, $admin);

#Default config options
my %CONFIGS = (
  wl0_ssid            => "$FORM{SSID}" . $prefix_ . "-$FORM{NAS_ID}",
  wl_ssid             => "$FORM{SSID}" . $prefix_ . "-$FORM{NAS_ID}",
  wl_channel          => "0",
  wl0_channel         => "0",
  lan_ipaddr          => $lan_ip,
  auth_dnsmasq        => "0",
  dnsmasq_enable      => "0",
  dns_dnsmasq         => "0",
  dhcp_dnsmasq        => "0",
  action_service      => "hotspot",
  time_zone           => "+00",
  daylight_time       => "0",
  cron_enable         => "1",
  cron_jobs           => "44 * * * * root /tmp/up",
  router_name         => "router.nabat.com.ua",
  
  chilli_enable       => "1",
  chilli_nowifibridge => "1",
  chilli_radius       => "radius.nabat.com.ua",
  chilli_backup       => "radius2.nabat.com.ua",
  chilli_url          => "https://customer.nabat.com.ua:9443/hotspotlogin.cgi",
  chilli_pass         => "iwifipass",
  chilli_interface    => "eth1",
  chilli_radiusnasid  => "$FORM{NAS_ID}",
  chilli_uamsecret    => "secrete",
  chilli_uamanydns    => "1",
  chilli_macauth      => "0",
  chilli_uamallowed   => "nabat.com.ua,customer.nabat.com.ua",
  
  
  rc_startup          =>
  q{/bin/sh -c 'echo \"/usr/bin/wget \"\"http://nabat.com.ua/hotspot/wrt_configure.cgi?MAC=\`nvram get wl0_hwaddr|sed s/:/-/g\`\&NAS_ID=\`nvram get chilli_radiusnasid\`\&os_date=\`nvram get os_date|sed s/\" \"/-/g\`\&uptime=\\\\\`\`\`uptime|sed s/\\\\\\" \\\\\\"/\"\\\\\\\\\%20\"/g|sed s/:/\"\\\\\\\\\%3A\"/g|sed s/,/\"\\\\\\\\\%2C\"/g\\\\\`\`\` \"\" -O /tmp/up.html\" ' > /tmp/up ; chmod 755 /tmp/up; }
  ,
  
  rc_firewall         =>
  "iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1412:65535 -j TCPMSS --clamp-mss-to-pmtu"
  ,
  chilli_additional   => "uamhomepage https://customer.nabat.com.ua:9443/start.cgi?DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}
coaport 3799
coanoipcheck
domain key.chillispot.info
uamallowed 194.149.46.0/24,198.241.128.0/17,66.211.128.0/17,216.113.128.0/17
uamallowed 70.42.128.0/17,128.242.125.0/24,216.52.17.0/24
uamallowed 62.249.232.74,155.136.68.77,155.136.66.34,66.4.128.0/17,66.211.128.0/17,66.235.128.0/17
uamallowed 88.221.136.146,195.228.254.149,195.228.254.152,203.211.140.157,203.211.150.204
uamallowed 91.203.4.17,195.22.112.58
uamallowed www.paypal.com,www.paypalobjects.com
uamallowed www.worldpay.com,select.worldpay.com,secure.ims.worldpay.com,www.rbsworldpay.com,secure.wp3.rbsworldpay.com
uamallowed nabat.com.ua,www.nabat.com.ua,customer.nabat.com.ua",
  
  wl0_txpwr           => "100",
  is_default          => "0",
  is_modified         => "1"
);

my @COMMANDS = (
  "wget http://nabat.com.ua/hotspot/wrt_configure.cgi?MAC=`nvram get wl0_hwaddr|sed s/:/-/g`\\&NAS_ID=$FORM{NAS_ID} -O /tmp/up.html"
  ,
  "nvram commit",
  "reboot"
);

print "Content-Type: text/plain; charset=windows-1251\n\n";

if ( $FORM{MAC} ) {
  nas_registration();
}
else {
  custom_config();
  configure_point();
}


#**********************************************************
=head2 nas_registration()

=cut
#**********************************************************
sub nas_registration {
  my ($attr) = @_;
  
  if ( $FORM{MAC} !~ /^[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}$/i ) {
    print "Wrong MAC" if ($debug > 0);
    return 0;
  }
  elsif ( !$FORM{NAS_ID} ) {
    print "Wrong NAS" if ($debug > 0);
    return 0;
  }
  
  $Nas->info({
    NAS_ID => $FORM{NAS_ID}
  });
  
  if ( !$Nas->{TOTAL} ) {
    print "NAS $FORM{NAS_ID} not found";
    return 0;
  }
  else {
    my $nas = $Nas;
    if ( $nas->{NAS_IP} && $nas->{NAS_IP} ne $ENV{REMOTE_ADDR} ) {
      $Nas->query2("UPDATE nas SET mac='' WHERE mac='$FORM{MAC}';", 'do');
      $Nas->change({ NAS_ID => $FORM{NAS_ID},
        MAC                 => $FORM{MAC},
        NAS_IP              => $ENV{REMOTE_ADDR}
      });
      cmd($conf{RESTART_RADIUS});
      $Nas->info({ NAS_ID => $FORM{NAS_ID} });
      
      mk_log('LOG_INFO', "REGISTRATION IP: $ENV{REMOTE_ADDR} MAC: $FORM{MAC} NAS_ID: $FORM{NAS_ID}");
    }
    
    if ( $FORM{MAC} && $nas->{MAC} ne $FORM{MAC} ) {
      $Nas->query2("UPDATE nas SET mac='' WHERE mac='$FORM{MAC}'", 'do');
      $Nas->change({ NAS_ID => $FORM{NAS_ID},
        MAC                 => $FORM{MAC},
        NAS_IP              => $ENV{REMOTE_ADDR}
      });
      
      mk_log('LOG_INFO', "CHANGE IP: $ENV{REMOTE_ADDR} MAC: $FORM{MAC} NAS_ID: $FORM{NAS_ID}");
    }
    #UPTIME
    if ($FORM{UPTIME}) {
      $Nas->change({ NAS_ID => $FORM{NAS_ID},
        UPTIME              => $FORM{uptime}
      });
      
      mk_log('LOG_INFO', "UPDATE IP: $ENV{REMOTE_ADDR} MAC: $FORM{MAC} NAS_ID: $FORM{NAS_ID}");
    }
  }
  print "OK";
  return 0;
}

#**********************************************************
=head2 custom_config($attr)

=cut
#**********************************************************
sub custom_config {
  my ($attr) = @_;
  my $default_cfg = "../libexec/wrt_defaults.cfg";
  
  if ( -f "$conf{TPL_DIR}/wrt_defaults.cfg" ) {
    $default_cfg = "$conf{TPL_DIR}/wrt_defaults.cfg";
  }
  elsif ( !-f $default_cfg ) {
    return 1;
  }
  
  @COMMANDS = ();
  %CONFIGS = ();
  
  my $content = '';
  open(my $fh, "$default_cfg") or die "Can't open file $!\n";
  while(<$fh>) {
    if ( $_ =~ /^#/ ) {
      next;
    }
    
    $content .= $_;
  }
  close($fh);
  
  my @arr = split(/[\n\r]/, $content);
  
  foreach my $line ( @arr ) {
    #chop($line);
    next if ($line eq '' || $line =~ /^#/);
    
    $line = tpl_parse($line, \%FORM);
    
    if ( $line =~ /^exec:(.+)/ ) {
      push @COMMANDS, $1;
      print "exec: $line\n" if ($debug == 1);
    }
    else {
      my ($left, $right) = split(/\s+/, $line, 2);
      $left =~ s/^\s+|\s+$//g;
      $right =~ s/^\s+|\s+$//g;
      $right =~ s/^\"|\"$//g;
      
      if ( $CONFIGS{$left} ) {
        $CONFIGS{$left} .= "\n";
      }
      
      $CONFIGS{$left} .= $right;
      
      print "l: $left  r: $right\n" if ($debug == 1);
    }
  }
  
  return 0;
}

#**********************************************************
=head2 configure_point()

=cut
#**********************************************************
sub configure_point {
  
  if ( $FORM{version} && $FORM{version} eq 'coova' ) {
    configure_coova_chilli();
    return 0;
  }
  
  if ( $FORM{version} && $FORM{version} eq 'freebsd' ) {
    configure_freebsd();
    return 0;
  }
  
  print << "[END]";
#!/bin/sh

nvram set wl0_ssid="$CONFIGS{wl0_ssid}"
nvram set wl_ssid="$CONFIGS{wl_ssid}"
nvram set wl_channel="$CONFIGS{wl_channel}"
nvram set wl0_channel="$CONFIGS{wl0_channel}"
nvram set lan_ipaddr="$CONFIGS{lan_ipaddr}"
nvram set auth_dnsmasq="$CONFIGS{auth_dnsmasq}"
nvram set dnsmasq_enable="$CONFIGS{dnsmasq_enable}"
nvram set dns_dnsmasq="$CONFIGS{dns_dnsmasq}"
nvram set dhcp_dnsmasq="$CONFIGS{dhcp_dnsmasq}"
nvram set action_service="$CONFIGS{action_service}"
nvram set time_zone="$CONFIGS{time_zone}"
nvram set daylight_time="$CONFIGS{daylight_time}"
nvram set cron_enable="$CONFIGS{cron_enable}"
nvram set cron_jobs="$CONFIGS{cron_jobs}"

nvram set router_name="$CONFIGS{router_name}"
nvram set chilli_enable="$CONFIGS{chilli_enable}"
nvram set chilli_nowifibridge="$CONFIGS{chilli_nowifibridge}"
nvram set chilli_radius="$CONFIGS{chilli_radius}"
nvram set chilli_backup="$CONFIGS{chilli_backup}"
nvram set chilli_url="$CONFIGS{chilli_url}"
nvram set chilli_pass="$CONFIGS{chilli_pass}"
nvram set chilli_interface="$CONFIGS{chilli_interface}"
nvram set chilli_radiusnasid="$CONFIGS{chilli_radiusnasid}"
nvram set chilli_uamsecret="$CONFIGS{chilli_uamsecret}"
nvram set chilli_uamanydns="$CONFIGS{chilli_uamanydns}"
nvram set chilli_macauth="$CONFIGS{chilli_macauth}"
nvram set chilli_uamallowed="$CONFIGS{chilli_uamallowed}"


nvram set rc_startup="$CONFIGS{rc_startup}"


nvram set rc_firewall="$CONFIGS{rc_firewall}"
nvram set chilli_additional="$CONFIGS{chilli_additional}"

nvram set wl0_txpwr="$CONFIGS{wl0_txpwr}"
nvram set is_default="$CONFIGS{is_default}"
nvram set is_modified="$CONFIGS{is_modified}"

[END]
  
  foreach my $cmd ( @COMMANDS ) {
    print "$cmd\n";
  }
  
}

#**********************************************************
=head2 configure_coova_chilli()

=cut
#**********************************************************
sub configure_coova_chilli {
  
  print << "[END]";
#!/bin/sh

# wl0_ssid="$CONFIGS{wl0_ssid}"
# wl_ssid=""
# wl_channel="$CONFIGS{wl_channel}"
# wl0_channel="$CONFIGS{wl0_channel}"

# time_zone="$CONFIGS{time_zone}"
# daylight_time="$CONFIGS{daylight_time}"
# router_name="$CONFIGS{router_name}"

# Deleting configuration
echo '' > /etc/chilli/main.conf
echo '' > /etc/chilli/hs.conf

cat << 'EOF' > /etc/chilli/defaults
#HS_WANIF=eth0
HS_LANIF=$CONFIGS{chilli_interface}

HS_NETWORK=$CONFIGS{chilli_net}
HS_NETMASK=255.255.255.0
HS_UAMLISTEN=$CONFIGS{lan_ipaddr}
HS_UAMSERVER=\$HS_UAMLISTEN

HS_DNS1=208.67.222.222
HS_DNS2=208.67.220.220

HS_NASID=$FORM{NAS_ID}
HS_RADIUS=$CONFIGS{chilli_radius}
HS_RADIUS2=$CONFIGS{chilli_radius}
HS_UAMALLOW="$CONFIGS{chilli_radius}, billing.axiostv.ru"
HS_RADSECRET=$CONFIGS{chilli_pass}
HS_UAMSECRET=$CONFIGS{chilli_uamsecret}
HS_UAMALIASNAME=$CONFIGS{router_name}
HS_COAPORT=3799
HS_NASIP=$ENV{REMOTE_ADDR}
HS_UAMFORMAT=$CONFIGS{chilli_url}
HS_LOC_NAME="$CONFIGS{router_name}"
HS_TCP_PORTS="80 443 9443"

EOF

/etc/init.d/dnsmasq disable

# Register NAS
CONF_FILE="/etc/chilli/main.conf"
INTERFACE="$CONFIGS{chilli_interface}";
MAC=`ifconfig \${INTERFACE} | grep HWaddr | awk '{ print \$5 }' | sed s/:/-/g`
[ -f /tmp/up.html ] && rm /tmp/up.html
wget -O /tmp/up.html "$SELF_URL?MAC=\${MAC}&NAS_ID=$FORM{NAS_ID}"

[END]
  
  if ( $CONFIGS{cron_enable} ) {
    print qq{echo "$CONFIGS{cron_jobs}" >> /etc/crontabs/root \n};
  }
  
  print qq{reboot \n};
  
  return 1;
}


#**********************************************************
=head2 configure_freebsd($attr)

=cut
#**********************************************************
sub configure_freebsd {
  my ($attr) = @_;
  
  if ( $FORM{GET_UP_SCRIPT} ) {
    #Up script
    print << "[END]";
#!/bin/sh

NAS_ID=$FORM{NAS_ID}
DOMAIN_ID=$FORM{DOMAIN_ID}
CHILLI_CONF=/usr/local/etc/chilli.conf
UPTIME=`uptime|sed 's/ /\\\\\%20/g'|sed 's/:/\\\\\%3A/g'|sed 's/,/\\\\\%2C/g'`
MAC=`ifconfig \\`cat \${CHILLI_CONF} | grep dhcpif | awk '{ print \\\$2 }'\\` | grep ether | awk '{ print \\\$2 }' | sed s/:/-/g | sed 'y/abcdef/ABCDEF/'`

URL="$SELF_URL/hotspot/wrt_configure.cgi?MAC=\${MAC}&os_date=`date "+\%Y-\%M-\%d \%H:\%m:\%S" | sed 's/ /\\\\\%20/g'|sed 's/:/\\\\\%3A/g'|sed 's/,/\\\\\%2C/g'`&uptime=\${UPTIME}&DOMAIN_ID=\${DOMAIN_ID}&NAS_ID=\${NAS_ID}"
fetch -q -o /tmp/up.htm "\${URL}"
echo \${URL};
[END]
    
    return 0;
  }
  
  
  #Chilli install
  print << "[END]";
#!/bin/sh


CHILLI_CONF=/etc/chilli.conf
echo "Step 1. Interface configuration"

ifconfig

echo -n Enter LAN interface:
read INT_IFACE=

echo -n Enter WAN interface:
read EXT_IFACE=


#if [ ! -f \${CHILLI_CONF} ]; then
#fi;

echo "Step 2. Install Chillispot"
CHILLI=`pkg_info | grep chillispot`;
if [ "w\${CHILLI}" = w ]; then
  echo "Installation chillispot"
  pkg_add -r chillispot
fi;

echo "Step 3. Chillispot configuration"
echo "
radiusserver1 radius.nabat.com.ua
radiusserver2 radius2.nabat.com.ua
radiussecret iwifipass
dhcpif \${INT_IFACE}
uamserver https://customer.nabat.com.ua:9443/hotspotlogin.cgi
uamsecret secrete
uamanydns
uamallowed nabat.com.ua,customer.nabat.com.ua
#net $lan_ip
uamhomepage https://customer.nabat.com.ua:9443/start.cgi?DOMAIN_ID=\$FORM{DOMAIN_ID}
coaport 3799
coanoipcheck
domain key.chillispot.info
uamallowed 194.149.46.0/24,198.241.128.0/17,66.211.128.0/17,216.113.128.0/17
uamallowed 70.42.128.0/17,128.242.125.0/24,216.52.17.0/24
uamallowed 62.249.232.74,155.136.68.77,155.136.66.34,66.4.128.0/17,66.211.128.0/17,66.235.128.0/17
uamallowed 88.221.136.146,195.228.254.149,195.228.254.152,203.211.140.157,203.211.150.204
uamallowed 91.203.4.17,195.22.112.58
uamallowed www.paypal.com,www.paypalobjects.com
uamallowed www.worldpay.com,select.worldpay.com,secure.ims.worldpay.com,www.rbsworldpay.com,secure.wp3.rbsworldpay.com
" > \${CHILLI_CONF}

echo "Step 5. Make autorun for chillispot"
RC_CONF=`cat /etc/rc.conf | grep chillispot`;
if [ "w\${RC_CONF}" = w ]; then
  echo "Add chilli to autostartup"
  echo "# chillispot" >> /etc/rc.conf
  echo "chillispot_enable=\\"YES\\"" >> /etc/rc.conf
  echo "chillispot_flags=\\"--conf=\${CHILLI_CONF}\\"" >> /etc/rc.conf
  #/usr/local/etc/rc.d/chillispot restart
  /etc/rc.d/chillispot restart
else
  /etc/rc.d/chillispot restart
fi;

echo "Step 6. Make firewall configuration"
if [ w`grep  pf_enable /etc/rc.conf` = w ]; then
echo "*****************************************************";
echo "* Recompile kernle with                             *";
echo "*****************************************************";
echo "
device          pf
device          pflog
device          pfsync
options         ALTQ

Add to /etc/rc.conf
pf_enable=\\"YES\\"
pf_rules=\\"/etc/pf.rules\\"
pf_flags=\\"\\"
pflog_enable=\\"YES\\"
pflog_logfile=\\"/var/log/pflog\\"
pflog_flags=\\"\\"
"

if [ ! -f /etc/pf.rules ] ; then
  echo "
int_if = \\"\${INT_IFACE}\\"
ext_if = \\"\${EXT_IFACE}\\"
chilli_if = \\"tun0\\"

tcp_services = \\"{ 22, 113 }\\"
icmp_types = \\"echoreq\\"

priv_nets = \\"{ 127.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12, 10.0.0.0/8 }\\"

# options
set block-policy return
set loginterface \$ext_if

# scrub
scrub in all
# macros
# nat/rdr
nat on \$ext_if from 192.168.0.0/16 to any -> (\$ext_if)
nat on \$ext_if from \$chilli_if:network to any -> (\$ext_if)


# filter rules
block all

pass quick on lo0 all

block drop in  quick on \$ext_if from \$priv_nets to any
block drop out quick on \$ext_if from any to \$priv_nets
block drop on \$int_if all

pass in on \$ext_if inet proto tcp from any to (\$ext_if) port \$tcp_services flags S/SA keep state

pass in inet proto icmp all icmp-type \$icmp_types keep state

pass in  on \$chilli_if from \$chilli_if:network to any keep state
pass out on \$chilli_if from any to \$chilli_if:network keep state

pass out on \$ext_if proto tcp all modulate state flags S/SA
pass out on \$ext_if proto { udp, icmp } all keep state
  " > /etc/pf.rules;  
else 
  cp /etc/pf.rules /etc/pf.rules.old
fi;

fi;

echo "Step 7. Make autoregistration script"
#get UP scipt
fetch -q -o /usr/local/etc/rc.d/chillispot_up.sh "$SELF_URL/wrt_configure.cgi?version=freebsd&GET_UP_SCRIPT=1&NAS_ID=$FORM{NAS_ID}&DOMAIN_ID=$FORM{DOMAIN_ID}"
chmod +x /usr/local/etc/rc.d/chillispot_up.sh

/usr/local/etc/rc.d/chillispot_up.sh
CRONTAB=`grep chillispot_up.sh /etc/crontab`;
if [ "w\${CRONTAB}" = w ]; then
  DATE_MIN=`date "+\%m"`;
  echo "\${DATE_MIN} * * * * root /usr/local/etc/rc.d/chillispot_up.sh" >> /etc/crontab
fi;

echo "Configuration complete";
[END]
}



#**********************************************************
=head2 mk_log()

=cut
#**********************************************************
sub mk_log {
  my ($type, $message) = @_;
  
  return 0 if ($debug < 6 || !-f $log_file);
  
  my $DATETIME = strftime "%Y-%m-%d %H:%M:%S", localtime(time);
  
  open(my $fh, ">> $log_file") or do {
    print "Can't open file '$log_file' $!\n";
    return 0;
  };
  print $fh "$DATETIME $type: $message\n";
  close($fh);
  
  return 1;
};


1
