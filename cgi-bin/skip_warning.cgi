#!/bin/sh
#**********************************************************
#  Skip warning message
#
#**********************************************************

#MIkrotik managment
#MIKROTIK=1;
#MIKROTIK_HOSTS="10.10.10.0";

SUDO=/usr/local/bin/sudo
IPFW=/sbin/ipfw
SSH=/usr/bin/ssh
MYSQL=
SSH_USER=axbills_admin
MYSQL='/usr/local/bin/mysql';
BILLING_DIR='/usr/axbills/';
VERSION=0.4
DEBUG=
IP="${REMOTE_ADDR}";

#LOG

#Check neg deposit speed
CHECK_NEG_DEPOSIT_SPEED=`grep axbills_neg_deposit_speed /etc/rc.conf`

#************************************************
#
#************************************************
mikrotik_skip () {

  for host in ${MIKROTIK_HOSTS}; do
    CMD=${CMD}" ${SSH} -o ConnectTimeout=10 -i /usr/axbills/Certs/id_rsa.${SSH_USER} ${SSH_USER}@${host} \"/ip firewall address-list remove [find address=${IP}]\"; ";
  done;

}


#************************************************
# Freebsd version
#************************************************
freebsd_skip () {
	
	CMD="${SUDO} ${IPFW} table 32 delete ${REMOTE_ADDR}"
}

#**********************************************
# get sql access params
#**********************************************
sql_get_conf () {
  if [ ! -f ${BILLING_DIR}/libexec/config.pl ]; then
    return 0;
  fi;

  DB_USER=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbuser}' |awk -F\' '{print $2}'`
  DB_PASSWD=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbpasswd}' |awk -F\' '{print $2}'`
  DB_NAME=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbname}' |awk -F\' '{print $2}'`
  DB_HOST=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbhost}' |awk -F\' '{print $2}'`

  return 1;
}


#************************************************
# Delete from dv.filter_id
#************************************************
db_update () {

  sql_get_conf

  #Get uid

  USER_ID=`${MYSQL} -s -N -u ${DB_USER} -p"${DB_PASSWD}" -h ${DB_HOST} -D "${DB_NAME}" -e "SELECT uid FROM internet_online WHERE framed_ip_address=INET_ATON('${IP}') LIMIT 1;"`;

  #Update
  if [ "${USER_ID}" != "" ]; then
    `${MYSQL} -u ${DB_USER} -p"${DB_PASSWD}" -h ${DB_HOST} -D "${DB_NAME}" -e "UPDATE internet_main SET filter_id='' WHERE uid='${USER_ID}' LIMIT 1"`;
  fi;

}

#**********************************************************
#
#**********************************************************
show_redirect_page () {
	
if [ x"${HTTP_REFERER}" != x ]; then
   if [ x"${QUERY_STRING}" != x ]; then
     REDIRECT_LINK=`echo "${QUERY_STRING}" | sed 's/redirect=//'`
     if [ x${REDIRECT_LINK} != x ]; then    
       echo "Location: http://${REDIRECT_LINK}";
       echo
     else
       echo "Content-Type: text/html";
       echo ""

       echo "Limited mode activated";
     fi
   else 
     echo "Content-Type: text/html";
     echo ""
   
     echo "Limited mode activated";
  fi;
else
  echo "Content-Type: text/html";
  echo ""
  echo "nothing to do"
fi;
	
}

if [ "${IP}" = "" ] ; then
  #Debug only
  #if [ "${IP}" = "" -a "$1" != "" ]; then
  #  IP=$1;
  #else
    echo "No IP check \$REMOTE_ADDR ";
    exit;
  #fi;
fi;

if [ "${MIKROTIK}" != "" ]; then
  mikrotik_skip
else
  freebsd_skip
fi;

#if db_action set make filter update
if [ -f "${BILLING_DIR}/neg_deposit/db_update" ]; then
  db_update
fi;

if [ "${DEBUG}" != "" ]; then
  echo "Content-Type: text/plain";
  echo ""
  echo ${CMD}
  echo
  env
fi;

${CMD}
if [ "${LOG}" != "" ]; then
  echo "${CMD}" >> /tmp/skip_warning
fi;

if [ "${CHECK_NEG_DEPOSIT_SPEED}" = "" ]; then
  echo "Content-Type: text/plain";
  echo ""
  echo "Neg deposit speed disable"
  exit;
fi;




