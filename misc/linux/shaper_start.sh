#!/bin/bash
# ABillS Firefall Managment Program for Linux
#
#***********************************************************************
# /etc/rc.conf
#
#####Включить фаервол#####
#axbills_firewall="YES"
#
#####Включить старый шейпер#####
#axbills_shaper_enable="YES"
#
#####Включить новый шейпер#####
#axbills_shaper2_enable="YES"
#
#####Включить шейпер IPMARK#####
#axbills_shaper3_enable="YES"
#
#####Включить шейпер IPTABLES RATELIMIT#####
#axbills_shaper_iptables_enable="YES"
#axbills_shaper_iptables_local_ips="сеть1;сеть2"
#Добавить правила
#echo @+10.0.0.5 1000000 > /proc/net/ipt_ratelimit/world-in
#echo @+10.0.0.5 1000000 > /proc/net/ipt_ratelimit/world-out
#echo @+10.0.0.5 10000000 > /proc/net/ipt_ratelimit/local-in
#echo @+10.0.0.5 10000000 > /proc/net/ipt_ratelimit/local-out
#Удалить правила
#echo @-10.0.0.5 > /proc/net/ipt_ratelimit/world-in
#echo @-10.0.0.5 > /proc/net/ipt_ratelimit/world-out
#echo @-10.0.0.5 > /proc/net/ipt_ratelimit/local-in
#echo @-10.0.0.5 > /proc/net/ipt_ratelimit/local-out
#
#####Указать номера нас серверов модуля IPN#####
#axbills_ipn_nas_id=""
#
#####Включить NAT "Внешний_IP:подсеть;Внешний_IP:подсеть;"#####
#axbills_nat=""
#
#####Втлючть FORWARD на определённую подсеть#####
#axbills_ipn_allow_ip=""
#
#####Пул перенаправления на страницу заглушку#####
#axbills_redirect_clients_pool=""
#
#####Внутренний IP (нужен для нового шейпера)#####
#axbills_ipn_if=""
#
#####Включить IPoE шейпер#####
#axbills_dhcp_shaper="YES"
#
#####Указать IPoE NAS серверов "nas_id;nas_id;nas_id" #####
#axbills_dhcp_shaper_nas_ids="";
#
#####Ожидать загрузку сервера с базой#####
#axbills_mysql_server_status="YES"
#
#####Указать адрес сервера mysql#####
#axbills_mysql_server=""
#
#####Привязать серевые интерфейсы к ядрам#####
#axbills_irq2smp="YES"
#
#####Включить ipt_NETFLOW#####
#ipt_netflow="YES"
#
#####IP Unnumbered#####
#####Указать общую подсеть раздаваемую абонентам#####
#axbills_unnumbered="YES"
#####Указать общую подсеть раздаваемую абонентам "сеть1;сеть2"#####
#axbills_unnumbered_net="10.0.0.0/22"
#####Указать шлюз сети для абонентов "шлюз1;шлюз2"#####
#axbills_unnumbered_gw="10.0.0.1"
#axbills_unnumbered_iface="vlan740-794,vlan800-998"
#
#axbills_custom_rules=""
#
#Load to start System
#  sudo update-rc.d shaper_start.sh start 99 2 3 4 5 . stop 01 0 1 6 .
#
#Unload to start System
# sudo update-rc.d -f shaper_start.sh remove
# Enable service
# systemctl enable shaper_start.sh
#
#
### BEGIN INIT INFO
# Provides:          shaper_start
# Required-Start:    $networking
# Required-Stop:     $networking
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO


set -e

#. /lib/lsb/init-functions

PROG="shaper_start"
DESCR="shaper_start"

#DATE: 20230420
VERSION=2.04

if [ -f /etc/rc.conf ]; then
. /etc/rc.conf
else
  echo 'File not exist /etc/rc.conf';
fi;

: ${axbills_shaper_enable="NO"}
: ${axbills_shaper_if=""}
: ${axbills_nas_id=""}
: ${axbills_ip_sessions=""}

: ${axbills_nat=""}
: ${axbills_multi_gateway=""}

: ${axbills_dhcp_shaper="NO"}
: ${axbills_dhcp_shaper_log=""}
: ${axbills_dhcp_shaper_nas_ids=""}
: ${axbills_neg_deposit="NO"}
: ${axbills_neg_deposit_speed=""}
: ${axbills_neg_deposit_fwd_ip="127.0.0.1"}
: ${axbills_portal_ip="me"}
: ${axbills_mikrotik_shaper=""}
: ${axbills_squid_redirect="NO"}
: ${firewall_type=""}

: ${axbills_ipn_nas_id=""}
: ${axbills_ipn_if=""}
: ${axbills_ipn_allow_ip=""}

: ${axbills_netblock="NO"}
: ${axbills_netblock_redirect_ip=""}
: ${axbills_netblock_type=""}

#Extra functions
: ${axbills_mysql_server_status="NO"}
: ${axbills_mysql_server=""}
: ${axbills_unnumbered="NO"}
: ${axbills_unnumbered_net=""}
: ${axbills_unnumbered_iface=""}
: ${axbills_unnumbered_gw=""}
: ${axbills_irq2smp="NO"}
: ${axbills_redirect_clients_pool=""}
: ${axbills_iptables_custom=""}
: ${axbills_shaper2_enable="NO"}
: ${axbills_shaper3_enable="NO"}
: ${axbills_allow_dhcp_port_67=""}
: ${axbills_firewall=""}

: ${axbills_shaper_iptables_enable=""}
: ${axbills_custom_rules=""}
: ${ipt_netflow=""}
: ${axbills_shaper_iptables_local_ips=""}
name="axbills_shaper" 

#if [ x${axbills_shaper_enable} = x ]; then
#  name="axbills_nat"
#  axbills_nat_enable=YES;
#fi;

TC="/sbin/tc"
IPT="/sbin/iptables"
SED="/bin/sed"
AWK="/usr/bin/awk"
IPSET="/sbin/ipset"
BILLING_DIR="/usr/axbills"

#**********************************************************
# get_cmd_path()
#**********************************************************
get_cmd_path() {
  program_name=$1;
  if command -v ${program_name} > /dev/null 2>&1; then
    #echo \"${program_name}\" is available
    echo $(command -v "${program_name}");
  else
    echo \"${program_name}\" is not available
  fi
}

if [ ! -f "${TC}" ]; then
  TC=`which tc`;
fi;

if [ ! -f "${IPT}" ]; then
  IPT=`which iptables`;
fi;

if [ ! -f "${SED}" ]; then
  SED=`which sed`;
fi;

if [ ! -f "${AWK}" ]; then
  AWK=$(command -v awk);
fi;

if [ ! -f "${IPSET}" ]; then
  IPSET=`get_cmd_path "ipset"`
  if [ $? != 0 ]; then
    echo ${IPSET}
  fi;
fi;

#Negative deposit forward (default: )
FWD_WEB_SERVER_IP="127.0.0.1"
#Your user portal IP 
USER_PORTAL_IP="${axbills_portal_ip}"
EXTERNAL_INTERFACE=`/sbin/ip r | awk '/default/{print $5}'`

#**********************************************************
#
#**********************************************************
all_rulles(){
  ACTION=$1

if [ "${axbills_ipn_if}" != "" ]; then
  IPN_INTERFACES="";
  ifaces=`echo ${axbills_ipn_if} | sed 'N;s/\n/ /' |sed 's/,/ /g'`

  for i in ${ifaces}; do
    if [[ "${i}" =~ - ]]; then
      vlan_name=`echo ${i}|sed 's/vlan//'`
      IFS='-' read -a start_stop <<< "$vlan_name"
      for cur_iface in `seq ${start_stop[0]} ${start_stop[1]}`; do
        IPN_INTERFACES="$IPN_INTERFACES vlan${cur_iface}"
      done
    else
      IPN_INTERFACES="$IPN_INTERFACES $i"
    fi
  done
fi;

if [ x"${axbills_dhcp_shaper_nas_ids}" != x ]; then
  NAS_IDS="NAS_IDS=";
  nas_ids=`echo ${axbills_dhcp_shaper_nas_ids} | sed 'N;s/\n/ /' |sed 's/,/ /g'`
  for i in ${nas_ids}; do

    if [[ ${i} =~ - ]]; then
      IFS='-' read -a start_stop <<< "$i"
      for cur_nas_id in `seq ${start_stop[0]} ${start_stop[1]}`;
      do
        NAS_IDS="$NAS_IDS${cur_nas_id};"
      done
    else
      NAS_IDS="$NAS_IDS$i;"
    fi
  done
fi;

ip_unnumbered
#check_server
axbills_iptables
axbills_nat
axbills_shaper
axbills_shaper2
axbills_shaper3
#axbills_shaper_iptables
axbills_ipn
axbills_dhcp_shaper
#axbills_custom_rule
neg_deposit
irq2smp
}


#**********************************************************
#IPTABLES RULES
#**********************************************************
axbills_iptables() {

if [ "${axbills_firewall}" = "" ]; then
  return 0;
fi;

echo "ABillS Iptables ${ACTION}"
sysctl -w net.ipv4.ip_forward=1
sysctl -w  net.ipv4.conf.all.forwarding=1

if [ x"${ACTION}" = xstart ]; then
  ${IPT} -P INPUT ACCEPT
  ${IPT} -P OUTPUT ACCEPT
  ${IPT} -P FORWARD ACCEPT
  ${IPT} -t nat -I PREROUTING -j ACCEPT
  # Включить на сервере интернет
  ${IPT} -A INPUT -i lo -j ACCEPT
  # Пропускать все уже инициированные соединения, а также дочерние от них
  ${IPT} -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
  # Разрешить SSH запросы к серверу
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 22 -j ACCEPT
  # Разрешить TELNET запросы к серверу
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 23 -j ACCEPT
  # Разрешить ping к серверу доступа
  ${IPT} -A INPUT -p icmp -m icmp --icmp-type any -j ACCEPT
  # Разрешить DNS запросы к серверу
  ${IPT} -A INPUT -p UDP -s 0/0  --dport 53 -j ACCEPT
  # Разрешить DHCP запросы к серверу
  ${IPT} -A INPUT -p UDP -s 0/0  --dport 68 -j ACCEPT
  ${IPT} -A INPUT -p UDP -s 0/0  --dport 67 -j ACCEPT
  #Запретить исходящий 25 порт
  ${IPT} -I OUTPUT -p tcp -m tcp --sport 25 -j DROP
  ${IPT} -I OUTPUT -p tcp -m tcp --dport 25 -j DROP
  # Доступ к странице авторизации
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 80 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 443 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 9443 -j ACCEPT
  ${IPT} -I INPUT -p udp -m udp --dport 161 -j ACCEPT
  ${IPT} -I INPUT -p udp -m udp --dport 162 -j ACCEPT

  # MYSQL
  ${IPT} -A INPUT -p TCP -s 0/0  --sport 3306 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 3306 -j ACCEPT

  # Allow OpenVPN
  if [ "${OPEN_VPN_ALLOW}" != "" ]; then
    ${IPT} -A INPUT -p UDP -s 0/0  --dport 1194 -j ACCEPT
  fi;

  if [ x"${ipt_netflow}" = xYES ]; then
    ${IPT} -A FORWARD -j NETFLOW;
  fi;

  ${IPT} -A FORWARD -p tcp -m tcp -s 0/0 --dport 80 -j ACCEPT
  ${IPT} -A FORWARD -p tcp -m tcp -s 0/0 --dport 443 -j ACCEPT
  ${IPT} -A FORWARD -p tcp -m tcp -s 0/0 --dport 9443 -j ACCEPT


# USERS
  allownet=`${IPSET} -L |grep allownet|sed 's/ //'|awk -F: '{ print $2 }'`
  if [ x"${allownet}" = x ]; then
    echo "ADD allownet"
    ${IPSET} -N allownet nethash
  fi;

# SET
  allowip=`${IPSET} -L |grep allowip|sed 's/ //'|awk -F: '{ print $2 }'`
  if [ x"${allowip}" = x ]; then
    echo "ADD allowip"
    ${IPSET} -N allowip iphash
  fi;

  ${IPT} -A FORWARD -m set --match-set allownet src -j ACCEPT
  ${IPT} -A FORWARD -m set --match-set allownet dst -j ACCEPT
  ${IPT} -t nat -A PREROUTING -m set --match-set allownet src -j ACCEPT

  ${IPT} -A FORWARD -m set --match-set allowip src -j ACCEPT
  ${IPT} -A FORWARD -m set --match-set allowip dst -j ACCEPT
  ${IPT} -t nat -A PREROUTING -m set --match-set allowip src -j ACCEPT

  if [ "${axbills_redirect_clients_pool}" != "" ]; then
    # negative deposit user redirect
    REDIRECT_POOL=`echo ${axbills_redirect_clients_pool}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;

    if [ "${DEBUG}" != "" ]; then
	    echo "REDIRECTT POOL: ${REDIRECT_POOL}"
	  fi;

	  for REDIRECT_IPN_POOL in ${REDIRECT_POOL}; do
	    ${IPT} -t nat -A PREROUTING -s ${REDIRECT_IPN_POOL} -p tcp --dport 80 -j REDIRECT --to-ports 80
	    ${IPT} -t nat -A PREROUTING -s ${REDIRECT_IPN_POOL} -p tcp --dport 443 -j REDIRECT --to-ports 80
	    ${IPT} -t nat -A PREROUTING -s ${REDIRECT_IPN_POOL} -p tcp --dport 9443 -j REDIRECT --to-ports 80
      echo "Redirect UP ${REDIRECT_IPN_POOL}"
    done
  else
    echo "unknown ABillS IPN IFACES"
  fi;

  if [ "${axbills_ipn_allow_ip}" != "" ]; then
    ABILLS_ALLOW_IP=`echo ${axbills_ipn_allow_ip}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
    echo "Enable allow ips ${ABILLS_ALLOW_IP}";
      for IP in ${ABILLS_ALLOW_IP} ; do
        ${IPT} -I FORWARD  -d ${IP} -j ACCEPT;
        ${IPT} -I FORWARD  -s ${IP} -j ACCEPT;
        if [ "${axbills_nat}" != "" ]; then
          ${IPT} -t nat -I PREROUTING -s ${IP} -j ACCEPT;
          ${IPT} -t nat -I PREROUTING -d ${IP} -j ACCEPT;
          ${IPT} -t nat -I POSTROUTING -s ${IP} -j ACCEPT;
          ${IPT} -t nat -I POSTROUTING -d ${IP} -j ACCEPT;
        fi;
      done;
  else
    echo "UNKNOWN ABillS IPN ALLOW IP"
  fi;

elif [ "${ACTION}" = stop ]; then
  # Разрешаем всё и всем
  ${IPT} -P INPUT ACCEPT
  ${IPT} -P OUTPUT ACCEPT
  ${IPT} -P FORWARD ACCEPT

  # Чистим все правила
  ${IPT} -F
  ${IPT} -F -t nat
  ${IPT} -F -t mangle
  ${IPT} -X
  ${IPT} -X -t nat
  ${IPT} -X -t mangle

  allowip=`${IPSET} -L |grep allowip|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ x"${allowip}" != x ]; then
    echo "DELETE allowip"
      ${IPSET} destroy allowip
    fi;
  allownet=`${IPSET} -L |grep allownet|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ x"${allownet}" != x ]; then
    echo "DELETE allownet"
      ${IPSET} destroy allownet
    fi;

elif [ x${ACTION} = xstatus ]; then
  ${IPT} -S
fi;

}



#**********************************************************
# AXbills Shapper
#**********************************************************
axbills_shaper() { 

  if [ x${axbills_shaper_enable} = xNO ]; then
    return 0;
  elif [ x${axbills_shaper_enable} = xNAT ]; then
    return 0;
  elif [ x${axbills_shaper_enable} = x ]; then
    return 0;
  fi;

  echo "ABillS Shapper ${ACTION}"

if [ x${ACTION} = xstart ]; then
  for INTERFACE in ${IPN_INTERFACES}; do
    TCQA="${TC} qdisc add dev ${INTERFACE}"
    TCQD="${TC} qdisc del dev ${INTERFACE}"

    ${TCQD} root &>/dev/null
    ${TCQD} ingress &>/dev/null

    ${TCQA} root handle 1: htb
    ${TCQD} handle ffff: ingress

    echo "Shaper UP ${INTERFACE}"
    
    ${IPT} -A FORWARD -j DROP -i ${INTERFACE}
  done
elif [ x${ACTION} = xstop ]; then
  for INTERFACE in ${IPN_INTERFACES}; do
    TCQA="${TC} qdisc add dev ${INTERFACE}"
    TCQD="${TC} qdisc del dev ${INTERFACE}"

    ${TCQD} root &>/dev/null
    ${TCQD} ingress &>/dev/null

    echo "Shaper DOWN ${INTERFACE}"
  done
elif [ x${ACTION} = xstatus ]; then
  for INTERFACE in ${IPN_INTERFACES}; do
    echo "Internal: ${INTERFACE}"
    ${TC} class show dev ${INTERFACE}
    ${TC} qdisc show dev ${INTERFACE}
  done
fi;
}

#**********************************************************
# AXbills Shapper
# With mangle support
#**********************************************************
axbills_shaper2() { 

  if [ x${axbills_shaper2_enable} = xNO ]; then
    return 0;
  elif [ x${axbills_shaper2_enable} = x ]; then
    return 0;
  fi;

  echo "ABillS Shapper 2 ${ACTION}"

  SPEEDUP=1000mbit
  SPEEDDOWN=1000mbit

if [ x"${ACTION}" = xstart ]; then
  ${IPT} -t mangle --flush
  ${TC} qdisc add dev ${EXTERNAL_INTERFACE} root handle 1: htb
  ${TC} class add dev ${EXTERNAL_INTERFACE} parent 1: classid 1:1 htb rate ${SPEEDDOWN} ceil ${SPEEDDOWN}

  for INTERFACE in ${IPN_INTERFACES}; do
    ${TC} qdisc add dev ${INTERFACE} root handle 1: htb
    ${TC} class add dev ${INTERFACE} parent 1: classid 1:1 htb rate ${SPEEDUP} ceil ${SPEEDUP}

#    ${IPT} -A FORWARD -j DROP -i ${INTERFACE}
    echo "Shaper UP ${INTERFACE}"
  done
elif [ x${ACTION} = xstop ]; then
  ${IPT} -t mangle --flush
  EI=`tc qdisc show dev ${EXTERNAL_INTERFACE} |grep htb | sed 's/ //g'`
  if [ x${EI} != x ]; then
    ${TC} qdisc del dev ${EXTERNAL_INTERFACE} root handle 1: htb 
  fi;
  for INTERFACE in ${IPN_INTERFACES}; do
    II=`tc qdisc show dev ${INTERFACE} |grep htb | sed 's/ //g'`
  if [ x${II} != x ]; then
    ${TC} qdisc del dev ${INTERFACE} root handle 1: htb 
    echo "Shaper DOWN ${INTERFACE}"
  fi;
  done
elif [ x${ACTION} = xstatus ]; then
  echo "External: ${EXTERNAL_INTERFACE}";  
  ${TC} class show dev ${EXTERNAL_INTERFACE}
  for INTERFACE in ${IPN_INTERFACES}; do
    echo "Internal: ${INTERFACE}"
    ${TC} class show dev ${INTERFACE}
  done
fi;
}
#**********************************************************
# AXbills Shapper
# With IPMARK support
#**********************************************************
axbills_shaper3() {

  if [ x${axbills_shaper3_enable} = xNO ]; then
    return 0;
  elif [ x${axbills_shaper3_enable} = x ]; then
    return 0;
  fi;
  echo "ABillS Shapper 3 ${ACTION}"

if [ x${ACTION} = xstart ]; then
  ${IPT} -t mangle -A POSTROUTING -o ${EXTERNAL_INTERFACE} -j IPMARK --addr src --and-mask 0xffff --or-mask 0x10000
  ${TC} qdisc add dev ${EXTERNAL_INTERFACE} root handle 1: htb
  ${TC} filter add dev ${EXTERNAL_INTERFACE} parent 1:0 protocol ip fw

  for INTERFACE in ${IPN_INTERFACES}; do
    ${IPT} -t mangle -A POSTROUTING -o ${INTERFACE} -j IPMARK --addr dst --and-mask 0xffff --or-mask 0x10000
    ${TC} qdisc add dev ${INTERFACE} root handle 1: htb
    ${TC} filter add dev ${INTERFACE} parent 1:0 protocol ip fw

    echo "Shaper 3 UP ${INTERFACE}"
  done
elif [ x${ACTION} = xstop ]; then
  ${IPT} -t mangle --flush
  EI=`tc qdisc show dev ${EXTERNAL_INTERFACE} |grep htb | sed 's/ //g'`
  if [ x${EI} != x ]; then
    ${TC} qdisc del dev ${EXTERNAL_INTERFACE} root
  fi;
  for INTERFACE in ${IPN_INTERFACES}; do
    II=`tc qdisc show dev ${INTERFACE} |grep htb | sed 's/ //g'`
  if [ x${II} != x ]; then
    ${TC} qdisc del dev ${INTERFACE} root
    echo "Shaper DOWN ${INTERFACE}"
  fi;
  done
elif [ x${ACTION} = xstatus ]; then
  echo "External: ${EXTERNAL_INTERFACE}";
  ${TC} qdisc show dev ${EXTERNAL_INTERFACE}
  for INTERFACE in ${IPN_INTERFACES}; do
    echo "Internal: ${INTERFACE}"
    ${TC} qdisc show dev ${INTERFACE}
  done
fi;
}
#**********************************************************
# AXbills Shapper
# With ipt-ratelimit support
#**********************************************************
axbills_shaper_iptables() {
  if [ "${axbills_shaper_iptables_enable}" = NO ]; then
    return 0;
  elif [ "${axbills_shaper_iptables_enable}" = "" ]; then
    return 0;
  fi;

  echo "ABillS Shapper IPTABLES ${ACTION}"
  if [ "${ACTION}" = start ]; then

    LOCAL_IP=`${IPSET} -L |grep LOCAL_IP|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ "${LOCAL_IP}" = "" ]; then
      echo "ADD LOCAL_IP TO IPSET"
      ${IPSET} -N LOCAL_IP iphash
    fi;

    LOCAL_NET=`${IPSET} -L |grep LOCAL_NET|sed 's/ //'|awk -F: '{ print $2 }'`

    if [ "${LOCAL_NET}" = "" ]; then
      echo "ADD LOCAL_NET TO IPSET"
      ${IPSET} -N LOCAL_NET nethash
    fi;

    UKRAINE=`${IPSET} -L |grep UKRAINE|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ x"${UKRAINE}" = x ]; then
      echo "ADD UKRAINE TO IPSET"
      ${IPSET} -N UKRAINE nethash
    fi;

    ${IPT} -I FORWARD -m ratelimit --ratelimit-set world-out --ratelimit-mode src -j DROP
    ${IPT} -I FORWARD -m ratelimit --ratelimit-set world-in --ratelimit-mode dst -j DROP

    LOCAL=`${IPT} -S |grep '\-N LOCAL'|awk -F" "  '{ print $2 }'`
    if [ x"${LOCAL}" = x ]; then
      ${IPT} -N LOCAL
    fi;

    UAIX=`${IPT} -S |grep '\-N UA-IX'|awk -F" "  '{ print $2 }'`
    if [ "${UAIX}" = "" ]; then
      ${IPT} -N UA-IX
    fi;

    ${IPT} -I UA-IX -m ratelimit --ratelimit-set ua-ix-out --ratelimit-mode src -j DROP
    ${IPT} -I UA-IX -m ratelimit --ratelimit-set ua-ix-in --ratelimit-mode dst -j DROP
    ${IPT} -I FORWARD -m set --match-set UKRAINE src -j UA-IX;
    ${IPT} -I FORWARD -m set --match-set UKRAINE dst -j UA-IX;

    ${IPT} -I LOCAL -m ratelimit --ratelimit-set local-out --ratelimit-mode src -j DROP
    ${IPT} -I LOCAL -m ratelimit --ratelimit-set local-in --ratelimit-mode dst -j DROP
    ${IPT} -I FORWARD -m set --match-set LOCAL_IP src -j LOCAL;
    ${IPT} -I FORWARD -m set --match-set LOCAL_IP dst -j LOCAL;
    ${IPT} -I FORWARD -m set --match-set LOCAL_NET src -j LOCAL;
    ${IPT} -I FORWARD -m set --match-set LOCAL_NET dst -j LOCAL;

    if [ "${axbills_shaper_iptables_local_ips}" != "" ]; then
      LOCAL_IPS=`echo ${axbills_shaper_iptables_local_ips}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
      for LOCAL_IP in ${LOCAL_IPS}; do
        if [[ ${LOCAL_IP} =~  ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ || ${LOCAL_IP} =~  ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/32$ ]]; then
          echo "ADD ${LOCAL_IP} TO LOCAL_IP"
          ${IPSET} -A LOCAL_IP ${LOCAL_IP} 
        elif [[ ${LOCAL_IP} =~  ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{2}$ ]]; then
          echo "ADD ${LOCAL_IP} TO LOCAL_NET"
          ${IPSET} -A LOCAL_NET ${LOCAL_IP}
        fi
#        ${IPT} -I FORWARD -d ${LOCAL_IP} -j LOCAL
      done
    fi;

  elif [ "${ACTION}" = stop ]; then
    LOCAL_IP=`${IPSET} -L |grep LOCAL_IP|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ x"${LOCAL_IP}" != x ]; then
      echo "DELETE SET LOCAL_IP"
      ${IPSET} destroy LOCAL_IP
    fi;
    LOCAL_NET=`${IPSET} -L |grep LOCAL_NET|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ x"${LOCAL_NET}" != x ]; then
      echo "DELETE SET LOCAL_NET"
      ${IPSET} destroy LOCAL_NET
    fi;
    UKRAINE=`${IPSET} -L |grep UKRAINE|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ x"${UKRAINE}" != x ]; then
      echo "DELETE SET UKRAINE"
      ${IPSET} destroy UKRAINE
    fi;
    LOCAL=`${IPT} -S |grep '\-N LOCAL'|awk -F" "  '{ print $2 }'`
    if [ x"${LOCAL}" != x ]; then
      ${IPT} -X LOCAL
    fi;
    UAIX=`${IPT} -S |grep '\-N UA-IX'|awk -F" "  '{ print $2 }'`
    if [ x"${UAIX}" != x ]; then
      ${IPT} -X UA-IX
    fi;
  fi;
}

#**********************************************************
#Ipn Sections
# Enable IPN
#**********************************************************
axbills_ipn() {

  if [ "${axbills_ipn_nas_id}" = "" ]; then
    return 0;
  fi;

  if [ x${ACTION} = xstart ]; then
    echo "Enable users IPN"
    ${BILLING_DIR}/libexec/periodic monthly MODULES=Ipn SRESTART=1 NO_ADM_REPORT=1 NO_RULE NAS_IDS="${axbills_ipn_nas_id}"
  fi;
}


#**********************************************************
# Start custom rules
#**********************************************************
axbills_custom_rule() {

  if [ x"${axbills_custom_rules}" != x ]; then
    CUSTOM_RULES=`echo ${axbills_custom_rules}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
    for CUSTOM_RULE in ${CUSTOM_RULES}; do
      echo "${CUSTOM_RULE}"
      ${IPT} ${CUSTOM_RULE}
    done
  fi;
}

#**********************************************************
#NAT Section
#**********************************************************
axbills_nat() {

  if [ "${axbills_nat}" = "" ]; then
    return 0;
  fi;

  echo "ABillS NAT ${ACTION}"

  if [ "${ACTION}" = status ]; then
    ${IPT} -t nat -L
    return 0;
  fi;

  ABILLS_IPS=`echo ${axbills_nat}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;

  for ABILLS_IPS_NAT in ${ABILLS_IPS}; do
    # NAT External IP
    NAT_IPS=`echo ${ABILLS_IPS_NAT} | awk -F: '{ print $1 }'`;
    # Fake net
    FAKE_NET=`echo ${ABILLS_IPS_NAT} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
    #NAT IF
    NAT_IF=`echo ${ABILLS_IPS_NAT} | awk -F: '{ print $3 }'`;
    echo  "NAT: ${NAT_IPS} LOCAL_NETS: ${FAKE_NET} NAT_IF: ${NAT_IF}"
    if [ "${NAT_IPS}" = "" ]; then
      NAT_IPS=all
    fi;
    # nat configuration

    NAT_INTERFACE=""
    if [ "${NAT_IF}" != "" ]; then
      NAT_INTERFACE=" -o ${NAT_IF}";
    fi;

    for IP in ${NAT_IPS}; do
      if [ "${ACTION}" = "start" ]; then
        for IP_NAT in ${FAKE_NET}; do
          if [[ "${IP}" =~ - ]]; then
            ${IPT} -t nat -A PREROUTING -s ${IP_NAT} -j SNAT --to-source ${IP} --persistent ${NAT_INTERFACE}
            echo "Enable NAT for ${IP_NAT} -> ${IP}"
          else
            ${IPT} -t nat -A POSTROUTING -s ${IP_NAT} -j SNAT --to-source ${IP} ${NAT_INTERFACE}
            echo "Enable NAT for ${IP_NAT} -> ${IP}"
          fi
        done;
      fi;
    done;
  done;

  if [ "${ACTION}" = stop ]; then
    ${IPT} -F -t nat
    ${IPT} -X -t nat
    echo "Disable NAT"
  fi;
}

#**********************************************************
#Neg deposit FWD Section
#**********************************************************
neg_deposit() {
  
  if [ "${axbills_neg_deposit}" = ""  -o "${axbills_neg_deposit}" = "NO" ]; then
    return 0;
  fi;

  #For neg filter redirect
  neg_deposit=`${IPSET} -L |grep neg_deposit|sed 's/ //'|awk -F: '{ print $2 }'`
  if [ "${neg_deposit}" = "" ]; then
    echo "ADD denyip"
    ${IPSET} -N neg_deposit iphash
  fi;

  echo "NEG_DEPOSIT"

  if [ "${axbills_neg_deposit}" = "YES" ]; then
    USER_NET="0.0.0.0/0"
  else
    # Portal IP
    USER_PORTAL_IP=`echo ${axbills_neg_deposit} | awk -F: '{ print $1 }'`;
    # Fake net
    USER_NET=`echo ${axbills_neg_deposit} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
    # Users IF
    USER_IF=`echo ${axbills_neg_deposit} | awk -F: '{ print $3 }'`;

    echo  "PORTAL: ${USER_PORTAL_IP} USER_NET: ${USER_NET} USER_IF: ${USER_IF}"
  fi;

  if [ "${USER_IF}" != "" ]; then
    USER_IF="-i ${USER_IF}"
  fi;

  for IP in ${USER_NET}; do
    #iptables -t nat -D PREROUTING -s 10.100.0.0/16 -p tcp -m tcp --dport 80 -j DNAT --to-destination 10.100.1.1:80
    #${IPT} -t nat -A PREROUTING -s ${IP} -p tcp --dport 80 -j REDIRECT --to-ports 80 ${USER_IF} --to-destination ${USER_PORTAL_IP}:80
    ${IPT} -t nat -A PREROUTING -s ${USER_NET} -p tcp --dport 80 -j DNAT ${USER_IF} --to-destination ${USER_PORTAL_IP}:80
  done;

  #Ipset redirect
  ${IPT} -t nat -A PREROUTING -m set --match-set neg_deposit src -p tcp --dport 80 -j DNAT --to-destination ${USER_PORTAL_IP}:80
  echo "${IPT} -v -A FORWARD -m set --match-set neg_deposit src -d ${USER_PORTAL_IP} -j ACCEPT"
  ${IPT} -A FORWARD -m set --match-set neg_deposit src -j DROP

}


#**********************************************************
#
#**********************************************************
axbills_dhcp_shaper() {

  if [ "${axbills_dhcp_shaper}" = NO ]; then
    return 0;
  elif [ "${axbills_dhcp_shaper}" = "" ]; then
    return 0;
  fi;

  if [ -f ${BILLING_DIR}/libexec/ipoe_shapper.pl ]; then
    if [ "${ACTION}" = start ]; then
      ${BILLING_DIR}/libexec/ipoe_shapper.pl -d ${NAS_IDS} IPN_SHAPPER
        echo " ${BILLING_DIR}/libexec/ipoe_shapper.pl -d ${NAS_IDS} IPN_SHAPPER";
    elif [ "${ACTION}" = stop ]; then
      if [ -f ${BILLING_DIR}/var/log/ipoe_shapper.pid ]; then
        IPOE_PID=`cat ${BILLING_DIR}/var/log/ipoe_shapper.pid`
        if  ps ax | grep -v grep | grep ipoe_shapper > /dev/null ; then
          echo "kill -9 ${IPOE_PID}"
          kill -9 ${IPOE_PID} ;
        fi;
        rm ${BILLING_DIR}/var/log/ipoe_shapper.pid
        else
        echo "Can\'t find 'ipoe_shapper.pid' "
      fi;
    fi;
  else
    echo "Can\'t find 'ipoe_shapper.pl' "
  fi;
}

#**********************************************************
#
#**********************************************************
check_server(){
  if [ x${axbills_mysql_server_status} = xNO ]; then
    return 0;
  elif [ x${axbills_mysql_server_status} = x ]; then
    return 0;
  fi;

  if [ "${ACTION}" = start ]; then
    while : ; do

      if ping -c5 -l5 -W2 ${axbills_mysql_server} 2>&1 | grep "64 bytes from" > /dev/null ;
      then echo "AXbills Mysql server is UP!!!" ;

      sleep 5;
      return 0;
      else echo "AXbills Mysql server is DOWN!!!" ;
      fi;
      sleep 5
    done
  fi;
}

#**********************************************************
#IRQ2SMP
#**********************************************************
irq2smp(){
  if [ "${axbills_irq2smp}" = NO ]; then
    return 0;
  elif [ "${axbills_irq2smp}" = "" ]; then
    return 0;
  fi;

  if [ "${ACTION}" = start ]; then
    ncpus=`grep -ciw ^processor /proc/cpuinfo`
    test "$ncpus" -gt 1 || exit 1

    n=0
    for irq in `cat /proc/interrupts | grep eth[0-9]- | awk '{print $1}' | sed s/\://g`
    do
      f="/proc/irq/$irq/smp_affinity"
      test -r "$f" || continue
      cpu=$[$ncpus - ($n % $ncpus) - 1]
      if [ ${cpu} -ge 0 ]
        then
        mask=`printf %x $[2 ** $cpu]`
        echo "Assign SMP affinity: eth$n, irq $irq, cpu $cpu, mask 0x$mask"
        echo "$mask" > "$f"
        let n+=1
      fi
    done
  fi;
}

#**********************************************************
#IP Unnumbered
#**********************************************************
ip_unnumbered(){
  if [ x${axbills_unnumbered} = xNO ]; then
    return 0;
  elif [ x${axbills_unnumbered} = x ]; then
    return 0;
  fi;

if [ "${ACTION}" = start ]; then
  sysctl -w net.ipv4.conf.default.proxy_arp=1
  if [ x"${axbills_unnumbered_net}" != x ]; then
      UNNUNBERED_NETS=`echo ${axbills_unnumbered_net}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
      for UNNUNBERED_NET in ${UNNUNBERED_NETS}; do
         /sbin/ip ro replace unreachable ${UNNUNBERED_NET}
         echo "Add route unreachable $UNNUNBERED_NET"
      done
      UNNUNBERED_GW=`echo ${axbills_unnumbered_gw}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
      for GW in ${UNNUNBERED_GW}; do
        /sbin/ip addr add ${GW} dev lo
        echo "Add  $GW dev lo"
      done

      if [ x"${axbills_unnumbered_iface}" != x ]; then
        UNNUNBERED_INTERFACES="";
        unnumbered_ifaces=`echo ${axbills_unnumbered_iface} | sed 'N;s/\n/ /' |sed 's/,/ /g'`
        for i in ${unnumbered_ifaces}; do
          if [[ ${i} =~ - ]]; then
             vlan_name=`echo ${i}|sed 's/vlan//'`
             IFS='-' read -a start_stop <<< "$vlan_name"
             for cur_iface in `seq ${start_stop[0]} ${start_stop[1]}`;
             do
                UNNUNBERED_INTERFACES="$UNNUNBERED_INTERFACES vlan${cur_iface}"
             done
          else
              UNNUNBERED_INTERFACES="$UNNUNBERED_INTERFACES $i"
          fi;
        done
        if [ x"${axbills_unnumbered_gw}" != x ]; then
          UNNUNBERED_GW=`echo ${axbills_unnumbered_gw}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
          for UNNUNBERED_INTERFACE in ${UNNUNBERED_INTERFACES}; do
               for GW in ${UNNUNBERED_GW}; do
                 /sbin/ip addr add ${GW} dev ${UNNUNBERED_INTERFACE}
                 sysctl -w net.ipv4.conf.${UNNUNBERED_INTERFACE}.proxy_arp=1
#              sysctl -w net.ipv4.conf.$UNNUNBERED_INTERFACE.proxy_arp_pvlan=0
                echo "Add  $GW dev $UNNUNBERED_INTERFACE"
              
              done
          done
        else
          echo "unknown IP Unnumbered GATEWAY"
        fi;

      else
        echo "unknown IP Unnumbered IFACE"
      fi;

  else
   echo "unknown IP Unnumbered NET"
  fi;
fi;

  if [ "${ACTION}" = stop ]; then
    /sbin/ip route flush type  unreachable
    DEVACES_ADDR=`/sbin/ip addr show |grep /32 |awk '/inet/{print $2,$5}'|sed 's/ /:/g' |sed 'N;s/\n/ /'`
    for DEV_ADDR in ${DEVACES_ADDR}; do
      IP=`echo ${DEV_ADDR} |awk -F: '{print $1}'`
      DEV=`echo ${DEV_ADDR} |awk -F: '{print $2}'`
#   if [ $DEV == "lo" ]; then
      /sbin/ip addr del ${IP} dev ${DEV}
#    /sbin/ip route flush dev $DEV
      echo "DELETE $IP for dev $DEV"
#  fi
    done
  fi;

}

#############################Скрипт################################
case "$1" in start) echo -n "START : $name"
      echo ""
	    all_rulles start
	    echo "."
	    ;; 
	stop) echo -n "STOP : $name"
	    echo ""
	    all_rulles stop
	    echo "."
	    ;; 
	restart) echo -n "RESTART : $name"
	    echo ""
	    all_rulles stop
	    all_rulles start
	    echo "."
	    ;;
	status) echo -n "STATUS : $name"
	    echo ""
	    all_rulles status
	    echo "."
	    ;;
    *) echo "Usage: shapper_start.sh
 start|stop|status|restart|clear"
    exit 1
    ;; 
    esac 


exit 0
