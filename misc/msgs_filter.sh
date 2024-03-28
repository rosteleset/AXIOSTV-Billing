#!/usr/bin/env sh
# Message filter managment script
# Add, del filters

# Supports:
#   * FreeBSD local ipfw redirection
#   * Remote mikrotik redirection
#
# To use with Internet module, add '$conf{MSGS_REDIRECT_INTERNET} = 1;' to libexec/config.pl
#
# On mikrotik you should define dst-nat redirection rules to portal
# IP addresses of users, who should be redirected will be added to 'message-redirect' address-list
# /ip firewall nat add chain=dst-nat protocol=tcp dst-port=80 src-address-list=message-redirect \
#   action=dst-nat to-address=%USER_PORTAL_IP_ADDRESS% to-ports=%USER_PORTAL_PORT%


USAGE='./msgs_filter.sh %action% [ UIDS ] [ IP ] (action can be add or del)';

version=0.5
DEBUG=1;
LOG=1;

SSH=`which ssh`;

BILLING_DIR="/usr/axbills/";

DB_USER=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbuser}' |awk -F"\'" '{print $2}'`
DB_PASSWD=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbpasswd}' |awk -F"\'" '{print $2}'`
DB_NAME=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbname}' |awk -F"\'" '{print $2}'`
DB_HOST=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbhost}' |awk -F"\'" '{print $2}'`
DB_CHARSET=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbcharset}' |awk -F"\'" '{print $2}'`


ONLINE_TABLE="internet_online";
USE_INTERNET_ONLINE_TABLE=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{MSGS_REDIRECT_INTERNET}'`;
if [ w"${USE_INTERNET_ONLINE_TABLE}" = w"" ]; then
  ONLINE_TABLE="dv_calls";
fi;

MYSQL=`which mysql`;
if [ x"${MYSQL}" = x ]; then
  MYSQL=/usr/local/bin/mysql
fi;

MSGS_TABLE_NUM=100

if [ w$1 = w ]; then
  echo "Add arguments";
  echo ${USAGE}
  exit 1
fi;

ACTION=$1
USER_UID=$2
IP=$3;

#OS
OS=`uname`;

#************************************************
#
#************************************************
get_online_info () {

  SQL="SELECT
     INET_NTOA(c.framed_ip_address),
     n.nas_type AS nas_type,
     n.mng_host_port,
     n.mng_user
    FROM ${ONLINE_TABLE} c
    INNER JOIN nas n ON (n.id=c.nas_id) 
    WHERE uid IN (${USER_UID});";

  ONLINE_INFO=`${MYSQL} -N -h "${DB_HOST}" -D "${DB_NAME}" -p"${DB_PASSWD}" -u ${DB_USER} -e "${SQL}"`;
}

#************************************************
#
#************************************************
mikrotik_skip () {
  HOST=$1
  USER_IP=$2
  USER_NAME=$3

  PORT=`echo ${HOST} | awk -F: '{ print $3 }'`
  HOST=`echo ${HOST} | awk -F: '{ print $1 }'`

  if [ w"${PORT}" = w ]; then
    PORT=22;
  fi;

  if [ x"${DEBUG}" != x ]; then
    echo "Mikrotik: ${HOST} User: ${USER_NAME}. ACTION: ${ACTION}";
  fi;

  CMD_CONNECT="${SSH} -p ${PORT} -o ConnectTimeout=10 -i /usr/axbills/Certs/id_rsa.${USER_NAME} ${USER_NAME}@${HOST} ";

  if [ w"${ACTION}" = wadd ]; then
    CMD="${CMD} ${CMD_CONNECT} /ip firewall address-list add list=message-redirect address=${USER_IP}; ";
  else
    CMD="${CMD} ${CMD_CONNECT} /ip firewall address-list remove [find list=message-redirect and address=${USER_IP}]; ";
  fi;
}


#************************************************
#
#************************************************
os_skip () {
  USER_IP=$1
  
  if [ w${DEBUG} != w ]; then
      echo "Msgs redirect action:'${ACTION}'. IP:'${USER_IP}'";
    fi;
    
  if [ x"${OS}" = x"FreeBSD" ]; then
    #Add online filter
    if [ w"${ACTION}" = wadd ]; then
      /sbin/ipfw table ${MSGS_TABLE_NUM} add ${USER_IP} ${USER_UID}
    else
      /sbin/ipfw table ${MSGS_TABLE_NUM} delete ${USER_IP}
    fi;
  
  else
    #If OS linux
    echo "Linux servers are not supported"
  fi;
}

# Shortcut for localhost NAS and known IP
if [ "x${OS}" = "xFreeBSD" ]; then
  if [ "x${IP}" != "x" ]; then
    os_skip ${IP}
    exit;
  fi;
fi;

# Will get info and fill $ONLINE_INFO
get_online_info

for LINE in "${ONLINE_INFO}"; do
  
    IP=`echo ${LINE} | awk '{ print $1 }'`;
    USER_NAME=`echo ${LINE} | awk '{ print $4 }'`;
    NAS_TYPE=`echo ${LINE} | awk '{ print $2 }'`;
    IS_MIKROTIK=`echo '${NAS_TYPE}' | grep 'mikrotik'`;

    if [ x"${IS_MIKROTIK}" = x'' ]; then
      HOST_IP_PORT=`echo ${LINE} | awk '{ print $3 }'`;
      mikrotik_skip ${HOST_IP_PORT} ${IP} ${USER_NAME}
    else
      os_skip ${IP}
    fi;

  done;

# Executes filters set/remove
${CMD}

# Add t commands to log
if [ x${LOG} != x ]; then
  echo "${CMD}" >> /tmp/skip_warning
fi;

exit 0;









#Multiservers starter
##!/bin/sh#
#
#ACTION=$1
#USER_UID=$2
#IP=$3
#
#echo "${ACTION} ${USER_UID}"
#
#for host in 192.168.17.2 192.168.17.4; do
#
#if [ "${ACTION}" = "add" ]; then
#  /usr/bin/ssh -i /usr/axbills/Certs/id_dsa.axbills_admin -o StrictHostKeyChecking=no -q axbills_admin@${host}  "/usr/local/bin/sudo /usr/axbills/misc/msgs_filter.sh ${ACTION} ${USER_UID}"
#else
#  /usr/bin/ssh -i /usr/axbills/Certs/id_dsa.axbills_admin -o StrictHostKeyChecking=no -q axbills_admin@${host} "/usr/local/bin/sudo /usr/axbills/misc/msgs_filter.sh
# ${IP}";
#fi;
#
#done;
