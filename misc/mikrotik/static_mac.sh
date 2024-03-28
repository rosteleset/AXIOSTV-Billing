#!/bin/sh
# Mikrotik Static mac assign from ipguard file
#
#

MICROTIK_IP=
MIKROTK_USER=axbills_admin
MICROTIC_CERTS=/usr/axbills/Certs/id_dsa.${MIKROTK_USER}
GUARD_FILE=/usr/axbills/var/ipguard

IF_NETWORKS="Norq\-ETH 10.10.16.0 255.255.248.0
Norashen1-SFP 10.10.24.0 255.255.248.0
Norashen2-SFP 10.10.32.0 255.255.248.0
Norashen3-SFP 10.10.40.0 255.255.248.0
Nazarbekyan-ETH 10.10.48.0 255.255.248.0
Halabyan 10.10.56.0 255.255.248.0
Davitashen1-ETH 10.10.64.0 255.255.248.0
Davitashen2-ETH 10.10.72.0 255.255.248.0
Davitashen3-ETH 10.10.80.0 255.255.248.0
Davitashen4-ETH 10.10.88.0 255.255.248.0"

AWK=awk

#**********************************************************
#
#**********************************************************
get_network () {
  IP=$1;
  MASK=$2;

i1=`echo "${IP}" | ${AWK} -F. '{ print $1 }'`;
i2=`echo "${IP}" | ${AWK} -F. '{ print $2 }'`;
i3=`echo "${IP}" | ${AWK} -F. '{ print $3 }'`;
i4=`echo "${IP}" | ${AWK} -F. '{ print $4 }'`;

m1=`echo "${MASK}" | ${AWK} -F. '{ print $1 }'`;
m2=`echo "${MASK}" | ${AWK} -F. '{ print $2 }'`;
m3=`echo "${MASK}" | ${AWK} -F. '{ print $3 }'`;
m4=`echo "${MASK}" | ${AWK} -F. '{ print $4 }'`;

NETWORK=`printf "%d.%d.%d.%d\n" "$(($i1 & $m1))" "$(($i2 & $m2))" "$(($i3 & $m3))" $(($i4 & $m4))` 
}


#**********************************************************
#
#**********************************************************
get_if () {
   MY_IP=$1;
   MICROTIK_IF="zzz";

echo "$IF_NETWORKS" | { while read line; do 

   MICROTIK_IF=`echo "${line}" | ${AWK} -F ' '  '{print $1}'`;
   NET_IP=`echo "${line}" | ${AWK} '{print $2}'`;
   NETMASK=`echo "${line}" | ${AWK} '{ print $3 }'`;
   if [ "${DEBUG}" != "" ]; then
     echo "IF: ${MICROTIK_IF} IP: ${NET_IP} / ${NETMASK} "
   fi;

   get_network $MY_IP $NETMASK;
   if [ "${NET_IP}" = "${NETWORK}" ]; then
     if [ "${DEBUG}" != "" ]; then
       echo " IF: ${MICROTIK_IF} NETWORK: ${NETWORK}" 
     fi;
     IF=${MICROTIK_IF}
     
     break;
   fi;
done
 
  echo "${IF}";
}
}

#**********************************************************
#
#**********************************************************
get_mikrotik_macs () {


}


#**********************************************************
#
#**********************************************************
compare_list


#make mikrotik cmd
/usr/bin/ssh -t -i ${MIKROTIK_CERT} ${MIKROTK_USER}@${MICROTIK_IP}  "/ip arp remove [/ip arp find]"
cat ${GUARD_FILE}  | while read guard_line; do 

MY_MAC=`echo ${guard_line} | ${AWK} '$1 !~ /#/ { print $1; }'`
if [ "${MY_MAC}" != "" ]; then
  MY_IP=`echo ${guard_line}  | ${AWK} '\$1 !~ /#/ { print \$2; }'`
  IF=`get_if ${MY_IP}`
  if [ "${DEBUG}" != "" ]; then
    echo "IP: ${MY_IP} MAC: ${MY_MAC} IF: ${IF}"
  fi;

  echo print "/ip arp add address=${MY_IP} mac-address=${MY_MAC} interface=${IF} " | /usr/bin/ssh -t -i ${MIKROTIK_CERT} ${MIKROTK_USER}@${MICROTIK_IP}
fi;


done 


exit;






