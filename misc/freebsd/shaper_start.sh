#!/bin/sh
# Shaper/NAT/Session upper for ABillS
#
# PROVIDE: axbills_shaper
# REQUIRE: NETWORKING mysql vlan_up

. /etc/rc.subr

# Add the following lines to /etc/rc.conf to enable axbills_shapper:
#
#   axbills_shaper_enable="YES" - Enable axbills shapper
#
#   axbills_shaper_if="" - ABillS shapper interface default ng*
#
#   axbills_nas_id="" - ABillS NAS ID default 1
#
#   axbills_ip_sessions="" - ABIllS IP SEssions limit
#
#   axbills_nat="EXTERNAL_IP:INTERNAL_IPS:NAT_IF;..." - Enable axbills nat
#
#   axbills_multi_gateway="GATEWAY_IF_IP:GATEWAY_GATE_IP:GATEWAY_REDIRECT_IPS"
#
#   axbills_dhcp_shaper=""  (bool) :  Set to "NO" by default.
#                                    Enable ipoe_shaper
#
#   axbills_dhcp_shaper_log="" - Enable IPoE shepper logging
#
#   axbills_dhcp_shaper_nas_ids="" : Set nas ids for shapper, Default: all nas servers
#
#   axbills_mikrotik_shaper=""  :  NAS IDS
#
#IPN Section configuration
#
#   axbills_ipn_nas_id="" ABillS IPN NAS ids, Enable IPN firewall functions
#
#   axbills_ipn_if="" IPN Shapper interface
#
#   axbills_ipn_allow_ip="" IPN Allow unauth ip
#
#Other
#
#   axbills_squid_redirect="" Redirect traffic to squid
#
#   axbills_neg_deposit="" Enable neg deposit redirect for VPN connection
#
#   axbills_neg_deposit_allow="" Neg deposit allow sites
#
#   axbills_neg_deposit_speed="512" Set default speed for negative deposit
#
#   axbills_neg_deposit_fwd_ip="127.0.0.1" Neg deposit forward ip
#


CLASSES_NUMS='2 3'
VERSION=7.21
# REVISION: 20180110

name="axbills_shaper"


rcvar=`set_rcvar`

: ${axbills_shaper_enable="NO"}

if [ "${axbills_shaper_enable}" = "NO" ]; then
  name="axbills_nat"
  axbills_nat_enable=YES;
fi;


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
: ${axbills_squid_ip="127.0.0.1"}
: ${firewall_type=""}

: ${axbills_ipn_nas_id=""}
: ${axbills_ipn_if=""}
: ${axbills_ipn_allow_ip=""}

: ${axbills_netblock="NO"}
: ${axbills_netblock_redirect_ip=""}
: ${axbills_netblock_type=""}

: ${axbills_paysys_tmp_access="NO"}

load_rc_config ${name}
#run_rc_command "$1"

IPFW=/sbin/ipfw
SED=/usr/bin/sed
BILLING_DIR=/usr/axbills
SKIP_FLUSH=""

start_cmd="axbills_shaper_start"
stop_cmd="axbills_shaper_stop"
restart_cmd="axbills_shaper_restart"

if [ x${axbills_mikrotik_shaper} != x ]; then
  ${BILLING_DIR}/libexec/billd checkspeed mikrotik NAS_IDS="${axbills_mikrotik_shaper}" RECONFIGURE=1
fi;

#Negative deposit forward (default: )
FWD_WEB_SERVER_IP=${axbills_neg_deposit_fwd_ip}
#Your user portal IP (Default: me)
USER_PORTAL_IP=${axbills_portal_ip}

#make at ipfw -q flush
if [ "$2" = "test" ]; then
  ACTION=start
  echo "${IPFW} -q flush; ${IPFW} add allow ip from any to any;" | at +10 minutes
  echo "Test mode. After 10 minutes flush all rules"
fi;

EXTERNAL_INTERFACE=`/sbin/route get default | grep interface: | awk '{ print $2 }'`

#Get external interface
if [ x${axbills_shaper_if} != x ]; then
  INTERNAL_INTERFACE=${axbills_shaper_if}
else
  INTERNAL_INTERFACE=ng\*
fi;

if [ "${axbills_nas_id}" = "" ]; then
  if [ "${axbills_ipn_nas_id}" != "" ]; then
    axbills_nas_id=${axbills_ipn_nas_id};
  else
    axbills_nas_id=1;
  fi;
fi;


#**********************************************************
#
#**********************************************************
axbills_shaper_start() {
  ACTION=start

sleep 5;

  axbills_zap_active
  axbills_shaper
  axbills_dhcp_shaper
  axbills_ipn
  axbills_nat
  external_fw_rules
  neg_deposit
  axbills_ip_sessions
  squid_redirect
  netblock_active

}

#**********************************************************
#
#**********************************************************
axbills_shaper_stop() {

  ACTION=stop

  axbills_shaper
  axbills_dhcp_shaper
  axbills_ipn
  axbills_nat
  neg_deposit
  axbills_ip_sessions
  squid_redirect
  netblock_active

}

#**********************************************************
#
#**********************************************************
axbills_shaper_restart() {
  axbills_shaper_stop
  axbills_shaper_start
}


#**********************************************************
# Zap old sessions
#**********************************************************
axbills_zap_active() {

if [ -f "$BILLING_DIR}/misc/autozh.pl" ]; then
  ${BILLING_DIR}/misc/autozh.pl NAS_ID=${axbills_nas_id}
  echo "Zapped ald session from NAS ID: ${axbills_nas_id}"
fi;

}

#**********************************************************
# AXbills Shapper
#**********************************************************
axbills_shaper() {

  if [ "${axbills_shaper_enable}" = "NO" ]; then
    return 0;
  elif [ "${axbills_shaper_enable}" = "NAT" ]; then
    return 0;
  fi;

  echo "ABillS Shapper ${ACTION}"

  #Octets direction
  PKG_DIRECTION=`cat ${BILLING_DIR}/libexec/config.pl | grep octets_direction | ${SED} "s/\\$conf{octets_direction}='\(.*\)'.*/\1/"`

  if [ "${PKG_DIRECTION}" = "user" ] ; then
    IN_DIRECTION="in recv ${INTERNAL_INTERFACE}"
    OUT_DIRECTION="out xmit ${INTERNAL_INTERFACE}"
  else
    IN_DIRECTION="out xmit ${EXTERNAL_INTERFACE}"
    OUT_DIRECTION="in recv ${EXTERNAL_INTERFACE}"
  fi;

  #Enable NG shapper
  if [ w != w`grep '^\$conf{ng_car}=1;' ${BILLING_DIR}/libexec/config.pl` ]; then
    NG_SHAPPER=1
  fi;

  #Main users table num
  USERS_TABLE_NUM=10
  #First Class traffic users
  USER_CLASS_TRAFFIC_NUM=10

  #NG Shaper enable
  if [ "${ACTION}" = start -a "${NG_SHAPPER}" != "" ]; then
    echo -n "ng_car shapper"
    #Load kernel modules
    kldload ng_ether
    kldload ng_car
    kldload ng_ipfw

    for num in ${CLASSES_NUMS}; do
      #  FW_NUM=`expr  `;
      echo "Traffic: ${num} "
      #Shaped traffic
      ${IPFW} add ` expr 10000 - ${num} \* 10 ` skipto ` expr 10100 + ${num} \* 10 ` ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to table\(${num}\) ${IN_DIRECTION}
      ${IPFW} add ` expr 10000 - ${num} \* 10 + 5 ` skipto ` expr 10100 + ${num} \* 10 + 5 ` ip from table\(${num}\) to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) ${OUT_DIRECTION}

      ${IPFW} add ` expr 10100 + ${num} \* 10 ` netgraph tablearg ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to any ${IN_DIRECTION}
      ${IPFW} add ` expr 10100 + ${num} \* 10 + 5 ` netgraph tablearg ip from any to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) ${OUT_DIRECTION}

      #Unlim traffic
      ${IPFW} add ` expr 10200 + ${num} \* 10 ` allow ip from table\(9\) to table\(${num}\) ${IN_DIRECTION}
      ${IPFW} add ` expr 10200 + ${num} \* 10 + 5 ` allow ip from table\(${num}\) to table\(9\) ${OUT_DIRECTION}
    done;

    echo "Global shaper"
    ${IPFW} add 10000 netgraph tablearg ip from table\(10\) to any ${IN_DIRECTION}
    ${IPFW} add 10010 netgraph tablearg ip from any to table\(11\) ${OUT_DIRECTION}
    ${IPFW} add 10020 allow ip from table\(9\) to any ${IN_DIRECTION}
    ${IPFW} add 10025 allow ip from any to table\(9\) ${OUT_DIRECTION}

    #if [ "${INTERNAL_INTERFACE}" = "ng*" ]; then
    #  ${IPFW} add 10030 allow ip from any to any via ${INTERNAL_INTERFACE}
    #fi;
  #done
  #Stop ng_car shaper
  elif [ w${ACTION} = wstop -a w$2 = w ]; then
    echo "Stop shapper"

    for num in ${CLASSES_NUMS}; do
      ${IPFW} delete ` expr 9100 + ${num} \* 10 + 5 ` ` expr 9100 + ${num} \* 10 `  ` expr 9000 + ${num} \* 10 ` ` expr 10000 - ${num} \* 10 ` ` expr 10100 + ${num} \* 10 ` ` expr 10200 + ${num} \* 10 ` ` expr 9000 + ${num} \* 10 + 5 ` ` expr 10000 - ${num} \* 10 + 5 ` ` expr 10100 + ${num} \* 10 + 5 ` ` expr 10200 + ${num} \* 10 + 5 `
    done;

    ${IPFW} delete 9000 9005 10000 10010 10015 08000 08010  09010 10020 10025
  else
    echo "DUMMYNET shaper"

    ${BILLING_DIR}/libexec/billd checkspeed RECONFIGURE=1 ${SKIP_FLUSH} NAS_IDS=${axbills_nas_id} FW_DIRECTION_OUT="${OUT_DIRECTION}" FW_DIRECTION_IN="${IN_DIRECTION}";
  fi;

}


#**********************************************************
#IPoE Shapper for dhcp connections
#**********************************************************
axbills_dhcp_shaper() {

  if [ "${axbills_dhcp_shaper}" = NO ]; then
    return 0;
  fi;

  if [ -f ${BILLING_DIR}/libexec/ipoe_shapper.pl ]; then
    if [ "${axbills_dhcp_shaper_nas_ids}" != "" ]; then
      NAS_IDS="NAS_IDS=${axbills_dhcp_shaper_nas_ids}"
    fi;

    if [ "${axbills_dhcp_shaper_log}" != "" ]; then
      IPOE_SHAPPER_LOG="LOG_FILE=${axbills_dhcp_shaper_log}"
    fi;

    if [ "${ACTION}" = start ]; then
      ${BILLING_DIR}/libexec/ipoe_shapper.pl -d ${NAS_IDS} ${IPOE_SHAPPER_LOG}
    elif [ "${ACTION}" = stop ]; then
      kill `cat ${BILLING_DIR}/var/log/ipoe_shapper.pid`
    fi;
  else
    echo "Can\'t find 'ipoe_shapper.pl' "
  fi;

}

#**********************************************************
#Ipn Sections
# Enable IPN
#
# IPN forward start IPFW from 60000
#
#
#**********************************************************
axbills_ipn() {

  if [ "${axbills_ipn_nas_id}" = "" ]; then
    return 0;
  fi;

  if [ "${ACTION}" = start ]; then
    if [ "${axbills_ipn_if}" != "" ]; then
       IFACE=" via ${axbills_ipn_if}"
    fi;

    #Redirect unauth ips to portal
    ${IPFW} add 60000 fwd ${FWD_WEB_SERVER_IP},80 tcp from any to any dst-port 80 ${IFACE} in

    # Allow ping to self
    ${IPFW} add 60100 allow icmp from any to me  ${IFACE}
    ${IPFW} add 60101 allow icmp from me to any  ${IFACE}

    if [ x${axbills_ipn_allow_ip} != x ]; then
      # Access to auth page
      ${IPFW} add 10 allow tcp from any to ${axbills_ipn_allow_ip} 9443  ${IFACE}
      ${IPFW} add 11 allow tcp from ${axbills_ipn_allow_ip} 9443 to any  ${IFACE}
      ${IPFW} add 12 allow tcp from any to ${axbills_ipn_allow_ip} 80  ${IFACE}
      ${IPFW} add 13 allow tcp from ${axbills_ipn_allow_ip} 80 to any  ${IFACE}

      # Allow DNS requests
      ${IPFW} add 60400 allow udp from any to ${axbills_ipn_allow_ip} 53
      ${IPFW} add 60450 allow udp from ${axbills_ipn_allow_ip} 53 to any
    fi;

    echo "Restart active sessions"

    INTERNET_MODULE='Ipn'
    INTERNTE_CHECK=`grep Internet /usr/axbills/libexec/config.pl`

    if [ "${INTERNTE_CHECK}" != "" ]; then
      INTERNET_MODULE="Internet"
    fi;

    /usr/axbills/libexec/periodic monthly MODULES=${INTERNET_MODULE} SRESTART=1 NO_ADM_REPORT=1 NAS_IDS="${axbills_ipn_nas_id}" LOCAL_NAS="${axbills_ipn_nas_id}" FN=ipoe_periodic_session_restart &

    #Start shaper
    if [ "${axbills_ipn_if}" != "" ] ; then
      INTERNAL_INTERFACE=${axbills_ipn_if}

      if [ "${axbills_nas_id}" != "" -a "${axbills_ipn_nas_id}" != "" ]; then
        SKIP_FLUSH="SKIP_FLUSH=1"
      fi;

      axbills_shaper ;
    fi;

    # Block unauth ips
    ${IPFW} add 63000 deny ip from not table\(10\) to any ${IFACE} in
    #${IPFW} add 65000 deny ip from any to any ${IFACE} in
  elif [ "${ACTION}" = "stop" ]; then
    ${IPFW} delete 10 11 12 13 60000 60100 60101  60400 60450 63000
  fi;

}

#**********************************************************
# Start custom shapper rules from rc.conf -> firewall_type="fw.conf"
#**********************************************************
external_fw_rules() {

  if [ ! -f /etc/fw.conf ]; then
    return 0;
  fi;

  if [ "${firewall_type}" = "/etc/fw.conf" ]; then
    cat ${firewall_type} | while read line ;   do
      RULEADD=`echo ${line} | awk '{print \$1}'`;
      NUMBERIPFW=`echo ${line} | awk '{print \$2}'`;

      if [ "${RULEADD}" = add ]; then
        NOEX=`${IPFW} show  ${NUMBERIPFW} 2>/dev/null | wc -l`;

        if [ ${NOEX} -eq 0 ]; then
          ${IPFW} ${line};
        fi;
      elif [ "${RULEADD}" = delete ]; then
        ${IPFW} ${line};
      elif [ "${RULEADD}" = nat -o "${RULEADD}" = table ]; then
        ${IPFW} ${line};
      fi;
    done;
  fi;
}

#**********************************************************
#NAT Section
# options IPFIREWALL_FORWARD
# options IPFIREWALL_NAT
# options LIBALIAS
#Nat Section
#
# NAT rule start IPFW 64000
#
#**********************************************************
axbills_nat() {

if [ x"${axbills_nat}" = x ]; then
  return 0;
fi;

echo "ABillS NAT ${ACTION}"
axbills_ips_nat=`echo ${axbills_nat} | sed 's/ //g'`;
axbills_ips_nat=`echo ${axbills_nat} | sed 's/;/ /g'`;

NAT_TABLE=20
NAT_FIRST_RULE=20
NAT_USERS_RULE=21
NAT_REAL_TO_FAKE_TABLE_NUM=33;

for IPS_NAT in ${axbills_ips_nat}; do
  # NAT External IP
  NAT_IPS=`echo ${IPS_NAT} | awk -F: '{ print $1 }'`;
  # Fake net
  FAKE_NET=`echo ${IPS_NAT} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
  #NAT IF
  NAT_IF=`echo ${IPS_NAT} | awk -F: '{ print $3 }'`;

  if [ x"${NAT_IPS}" = x ]; then
    IP=`ifconfig \`route -n get default | grep interface | awk '{ print $2 }'\` | grep "inet " | awk '{ print $2 }'`
    NAT_IPS=${IP}
  fi;

  echo " NAT ${ACTION}"

  # nat configuration
  for IP in ${NAT_IPS}; do
    if [ "${ACTION}" = "start" ]; then
      ${IPFW} nat ${NAT_USERS_RULE} config ip ${IP} log
      ${IPFW} table ${NAT_REAL_TO_FAKE_TABLE_NUM} add ${IP} ${NAT_USERS_RULE}

      for f_net in ${FAKE_NET}; do
        ${IPFW} table ` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1` add ${f_net} ${NAT_USERS_RULE}
      done;
    elif [ w${ACTION} = wstop ]; then
      ${IPFW} nat delete ${NAT_USERS_RULE}
    fi;
  done;
  NAT_USERS_RULE=`expr ${NAT_USERS_RULE} + 1`
done;

# ISP_GW2=1 For redirect to second way
if [ "${axbills_multi_gateway}" != "" ]; then
  axbills_gateways=`echo ${axbills_multi_gateway} | sed 's/ /,/g'`;
  axbills_gateways=`echo ${axbills_gateways} | sed 's/;/ /g'`;

  for GATEWAY in ${axbills_gateways}; do
    # NAT External IP
    GW2_IF_IP=`echo ${GATEWAY} | awk -F: '{ print $1 }'`;
    # Fake net
    GW2_IP=`echo ${GATEWAY} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
    #NAT IF
    GW2_REDIRECT_IPS=`echo ${GATEWAY} | awk -F: '{ print $3 }'`;

    NAT_ID=22
    #Fake IPS
    ${IPFW} table ${NAT_REAL_TO_FAKE_TABLE_NUM} add ${GW2_IF_IP} ${NAT_ID}
    #NAT configure
    ${IPFW} nat ${NAT_ID} config ip ${GW2_IF_IP} log
    #Redirect to second net IPS
    for ip_mask in ${GW2_REDIRECT_IPS} ; do
      ${IPFW} table ` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1` add ${ip_mask} ${NAT_ID}
    done;

    #Forward traffic 2 second way
    ${IPFW}  add 64015 fwd ${GW2_IP} ip from ${GW2_IF_IP} to any
    #${IPFW} add 30 add fwd ${ISP_GW2} ip from ${NAT_IPS} to any

    echo "Gateway: ${GW2_REDIRECT_IPS} -> ${GW2_IP} added";
  done;
fi;

# UP NAT
if [ "${ACTION}" = "start" ]; then
  if [ "${NAT_IF}" != "" ]; then
    NAT_IF="via ${NAT_IF}"
  fi;

  ${IPFW} add 64010 nat tablearg ip from table\(` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1 `\) to any ${NAT_IF}
  ${IPFW} add 1020 nat tablearg ip from any to table\(${NAT_REAL_TO_FAKE_TABLE_NUM}\) ${NAT_IF} in
elif [ "${ACTION}" = stop ]; then
  ${IPFW} table ${NAT_REAL_TO_FAKE_TABLE_NUM} flush
  ${IPFW} table ` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1 ` flush
  ${IPFW} delete 64010 20 64015
fi;

}


#**********************************************************
#Neg deposit FWD Section
#**********************************************************
neg_deposit() {

  if [ "${axbills_neg_deposit}" = NO ]; then
    return 0;
  fi;

  echo "Negative Deposit Forward Section (for mpd) ${ACTION}"
  DNS_IP=""

  if [ "${DNS_IP}" = "" ]; then
    DNS_IP=`cat /etc/resolv.conf | grep nameserver | awk '{ print $2 }' | head -1`
  fi;

  FWD_RULE=1014;

  #Forwarding start
  if [ "${ACTION}" = "start" ]; then
    if [ "${SKIP_FLUSH}" != "" ]; then
      INTERNAL_INTERFACE="ng*";
    fi;

    ${IPFW} add ${FWD_RULE} fwd ${FWD_WEB_SERVER_IP},80 tcp from table\(32\) to any dst-port 80,443 via ${INTERNAL_INTERFACE}
    #If use proxy
    #${IPFW} add ${FWD_RULE} fwd ${FWD_WEB_SERVER_IP},3128 tcp from table\(32\) to any dst-port 3128 via ${INTERNAL_INTERFACE}
    # if allow usin net on neg deposit
    if [ x${axbills_neg_deposit_speed} != x ]; then
      ${IPFW} add 9000 skipto ${FWD_RULE} ip from table\(32\) to any ${IN_DIRECTION}
      ${IPFW} add 9001 skipto ${FWD_RULE} ip from any to table\(32\) ${OUT_DIRECTION}

      #${IPFW} add 10020 pipe 1${axbills_neg_deposit_speed} ip from any to not table\(10\) ${IN_DIRECTION}
      #${IPFW} add 10021 pipe 1${axbills_neg_deposit_speed} ip from not table\(10\) to any ${OUT_DIRECTION}
      #${IPFW} pipe 1${axbills_neg_deposit_speed} config bw ${axbills_neg_deposit_speed}Kbit/s mask src-ip 0xfffffffff

      ${IPFW} add `expr ${FWD_RULE} + 30` pipe 1${axbills_neg_deposit_speed} ip from any to not table\(10\) ${IN_DIRECTION}
      ${IPFW} add `expr ${FWD_RULE} + 31` pipe 1${axbills_neg_deposit_speed} ip from not table\(10\) to any ${OUT_DIRECTION}
      ${IPFW} pipe 1${axbills_neg_deposit_speed} config bw ${axbills_neg_deposit_speed}Kbit/s mask src-ip 0xfffffffff
    else
      ${IPFW} add `expr ${FWD_RULE} + 10` allow udp from table\(32\) to ${DNS_IP} dst-port 53 via ${INTERNAL_INTERFACE}
      ${IPFW} add `expr ${FWD_RULE} + 20` allow tcp from table\(32\) to ${USER_PORTAL_IP} dst-port 9443 via ${INTERNAL_INTERFACE}
      ${IPFW} add `expr ${FWD_RULE} + 30` deny ip from table\(32\) to any via ${INTERNAL_INTERFACE} in
#      ${IPFW} add `expr ${FWD_RULE} + 30` deny ip from any to table\(32\) via ${INTERNAL_INTERFACE} out
    fi;
  elif [ "${ACTION}" = "stop" ]; then
    ${IPFW} delete ${FWD_RULE} ` expr ${FWD_RULE} + 10 ` ` expr ${FWD_RULE} + 20 ` ` expr ${FWD_RULE} + 30 `
  elif [ "${ACTION}" = "show" ]; then
    ${IPFW} show ${FWD_RULE}
  fi;
}

#**********************************************************
#Session limit section
#**********************************************************
axbills_ip_sessions() {

if [ x${axbills_ip_sessions} = x ]; then
  return 0;
fi;

  echo "Session limit ${axbills_ip_sessions}";
  if [ w${ACTION} = wstart ]; then
    ${IPFW} add 00400   skipto 65010 tcp from table\(34\) to any dst-port 80,443 via ${INTERNAL_INTERFACE}
    ${IPFW} add 00401   skipto 65010 udp from table\(34\) to any dst-port 53 via ${INTERNAL_INTERFACE}
    ${IPFW} add 00402   skipto 60010 tcp from table\(34\) to any via ${EXTERNAL_INTERFACE}
    ${IPFW} add 64001   allow tcp from table\(34\) to any setup via ${INTERNAL_INTERFACE} in limit src-addr ${axbills_ip_sessions}
    ${IPFW} add 64002   allow udp from table\(34\) to any via ${INTERNAL_INTERFACE} in limit src-addr ${axbills_ip_sessions}
    ${IPFW} add 64003   allow icmp from table\(34\) to any via ${INTERNAL_INTERFACE} in limit src-addr ${axbills_ip_sessions}
  elif [ w${ACTION} = wstop ]; then
    ${IPFW} delete 00400 00401 00402 64001 64002 64003
  fi;
}

#**********************************************************
#Squid Redirect
#**********************************************************
squid_redirect() {

  #FWD Section
  if [ "${axbills_squid_redirect}" = NO ]; then
    return 0;
  fi;

  SQUID_SERVER_IP=${axbills_squid_ip};

  SQUID_REDIRET_TABLE=40
  FWD_RULE=10040;

  #Forwarding start
  if [ "${ACTION}" = "start" ]; then
    echo "Squid Forward Section - start";
    ${IPFW} add ${FWD_RULE} fwd ${SQUID_SERVER_IP},8080 tcp from table\(${SQUID_REDIRET_TABLE}\) to any dst-port 80,443 via ${INTERNAL_INTERFACE}
    #If use proxy
    #${IPFW} add ${FWD_RULE} fwd ${FWD_WEB_SERVER_IP},3128 tcp from table\(32\) to any dst-port 3128 via ${INTERNAL_INTERFACE}
  elif [ "${ACTION}" = "stop" ]; then
    echo "Squid Forward Section - stop:";
    ${IPFW} delete ${FWD_RULE}
  elif [ "${ACTION}" = "show" ]; then
    echo "Squid Forward Section - status:";
    ${IPFW} show ${FWD_RULE}
  fi;
}

#**********************************************************
#Netblock
#
# Active netblock
#  IPTW
#   table 13 for blocking IP
#
#  Block rule 113
#
#**********************************************************
netblock_active() {

  #Netblock Section
  if [ "${axbills_netblock}" = "NO" ]; then
    return 0;
  fi;

  NETBLOCK_REDIRECT_IP=${axbills_netblock_redirect_ip};
  NETBLOCK_REDIRECT_PORT=82;
  NETBLOCK_IF=${EXTERNAL_INTERFACE};


  if [ "${ACTION}" = "show" ]; then
    ${IPFW} table 13 list;
    ${IPFW} show 115 116;
  elif [ "${ACTION}" = "stop" ]; then
    ${IPFW} delete 115 116;
  else
    if [ "${axbills_netblock_type}" != "" -a -f /usr/axbills/libexec/billd ]; then
      NETBLOCK_CMD="/usr/axbills/libexec/billd netblock ${axbills_netblock_type}"
      ${NETBLOCK_CMD}
    fi;
    if [ "${NETBLOCK_REDIRECT_IP}" != "" ]; then
      ${IPFW} add 115 fwd 127.0.0.1,${NETBLOCK_REDIRECT_PORT} tcp from any to "table(13)"  dst-port 80,443 via ${NETBLOCK_IF}
    fi;

    ${IPFW} add 116 deny all from any to "table(13)" via ${NETBLOCK_IF}
  fi;

}


#**********************************************************
# Paysys temporary access
#
# Active netblock
#  IPTW
#   table 16 for blocking IP / UID
#
#  Allow rule 120 121
#
#**********************************************************
paysys_tmp_access() {

  #Netblock Section
  if [ "${axbills_paysys_tmp_access}" = "NO" ]; then
    return 0;
  fi;



  if [ "${ACTION}" = "show" ]; then
    ${IPFW} table 16 list;
    ${IPFW} show 120 121;
  elif [ "${ACTION}" = "stop" ]; then
    ${IPFW} delete 120 121;
  else
    ${IPFW} add 120 allow all from "table(16)" to any via ${NETBLOCK_IF}
    ${IPFW} add 121 allow all from any to "table(16)" via ${NETBLOCK_IF}
  fi;

}


load_rc_config ${name}
run_rc_command "$1"

