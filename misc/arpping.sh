#!/bin/sh
# Arp ping for different OS
# 
# Mikrotik
# Linux
# FreeBSD
#******************************************

VERSION=1.02
DEBUG=
#OS=``;
NAS_MNG_IP=${NAS_MNG_IP}
NAS_MNG_USER=axbills_admin
USER_IP=${FRAMED_IP_ADDRESS}
SSH_CERT_TYPE=rsa

if [ "${NAS_TYPE}" = 'mikrotik' -o "${NAS_TYPE}" = "mikrotik_dhcp" ] ; then
  /usr/bin/ssh -o StrictHostKeyChecking=no -i /usr/axbills/Certs/id_${SSH_CERT_TYPE}.${NAS_MNG_USER} ${NAS_MNG_USER}@${NAS_MNG_IP} "ping arp-ping=yes interface=[put [ip arp get [find address=${USER_IP}] interface]] ${USER_IP} count=3"

elif [ "${NAS_TYPE}" = "Linux" ]; then


else
  OS=`uname`


fi;

