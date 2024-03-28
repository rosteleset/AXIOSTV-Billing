#!/bin/sh
# Test radius inputs and outputs uing freeradius tools radclient
#
#**********************************************************

AUTH_LOG=/usr/axbills/var/log/axbills.log
ACCT_LOG=/usr/axbills/var/log/acct.log
VERSION=0.18


USER_NAME=test
USER_PASSWORD=123456
NAS_IP_ADDRESS=127.0.0.1
ACCT_SESSION_ID='123456789012345';
RADIUS_SECRET=secretpass;

#Voip defauls
#VOIP_NAS_IP_ADDRESS=192.168.202.15
#VOIP_USER_NAME=200
#VOIP_CHAP_PASSWORD=''; #123456

RADCLIENT=radclient
PATH=${PATH}:/usr/local/freeradius/bin/
DIRNAME=`dirname $0`
RAUTH=${DIRNAME}"/rauth.pl";
RACCT=${DIRNAME}"/racct.pl";
RADTEST=radtest


#Default Alive packes
ALIVE_COUNT=1;
#Default Radius params
ACCT_INPUT_OCTETS=113459811
ACCT_INPUT_GIGAWORDS=0
ACCT_OUTPUT_OCTETS=14260000
ACCT_OUTPUT_GIGAWORDS=0
ACCT_SESSION_TIME=300

#**********************************************************
# Test coa request
#**********************************************************
_coa () {

  COA_PORT=1700;
  COA_PASSWORD=isgcontrol;
  echo "Cisco-AVPair+='subscriber:command=account-logoff',Acct-Session-Id=3568" | ${RADCLIENT} -r 1 -x ${NAS_IP_ADDRESS}:${COA_PORT} coa ${COA_PASSWORD}

}

#**********************************************************
# Test pod request
#**********************************************************
_pod () {

  COA_PORT=1700;
  COA_PASSWORD=isgcontrol;
  SESSION_ID=${ACCT_SESSION_ID}

  if [ "${COA_PASSWORD}" = "" ]; then
    COA_PASSWORD=${RADIUS_SECRET}
  fi;

  echo "Acct-Session-Id=${SESSION_ID}" | ${RADCLIENT} -r 1 -x ${NAS_IP_ADDRESS}:${COA_PORT} disconnect ${COA_PASSWORD}

}


# Proccess command-line options
#
for _switch ; do
        case ${_switch} in
        -debug)
                DEBUG=1;
                echo "Debug enable"
                shift; 
                ;;
        -v)
                echo "Version: ${VERSION}";
                exit;
                ;;
        -u)     USER_NAME=$2;
                shift; shift
                ;;
        -p)     USER_PASSWORD=$2;
                shift; shift
                ;;
        -nas)   NAS_IP_ADDRESS=$2;
                shift; shift
                ;;
        acct)   ACCOUNTING_ACTION=$2;
                ACTION=acct 
                shift; shift;
                ;;
        auth)   ACTION=auth;
                shift;
                ;;
                
        voip)   VOIP=1;
                shift;
                ;;        
        coa)    COA=1;
                shift;
                ;;
        status) RAD_STATUS=1
                shift;
                ;;
        -cid)   CALLING_STATION_ID=$2;
                shift; shift
                ;;
        -session_id) ACCT_SESSION_ID=$2;
                shift; shift
                ;;
        -rad)   RADIUS_ACTION=1;
                shift;
                ;;
        -rad_file) RAD_FILE=$2;
                shift; shift
                ;;
        -rad_secret)   RADIUS_SECRET=$2;
                shift; shift;
                ;;
        -rad_ip)RADIUS_IP=$2;
                shift; shift;
                ;;
        -rad_dict) RAD_DICT=$2;
                shift; shift;
                ;;
        -isg)  test_isg;
                shift;
                ;;
        -alive_count) ALIVE_COUNT=$2;
                shift; shift;
                ;;
        -radtest)RADTEST=$2;
                shift; shift;
                ;;
        esac
done

#**********************************************************
#
#**********************************************************
rad_status () {

  echo "Message-Authenticator = 0x00, FreeRADIUS-Statistics-Type = 1, Response-Packet-Type = Access-Accept" | ${RADCLIENT} -r 1 -x 127.0.0.1:18121 status adminsecret

}

#**********************************************************
#
#**********************************************************
voip_auth () {
	
  #voip
  echo "Voip";

  if [ x${ACTION} = xauth ] ; then
   echo Auth;
     ${RAUTH}  NAS_IP_ADDRESS="${NAS_IP_ADDRESS}" \
     NAS_PORT_TYPE="Virtual" \
     NAS_IDENTIFIER="" \
     CLIENT_IP_ADDRESS="192.168.101.17" \
     CISCO_AVPAIR="h323-ivr-out=terminal-alias:100;" \
     SERVICE_TYPE="Login-User" \
     CHAP_CHALLENGE="0x43a28c01" \
     USER_NAME="${USER_NAME}" \
     CALLING_STATION_ID="3456"\
     FRAMED_IP_ADDRESS="192.168.101.23" \
     CALLED_STATION_ID="001363" \
     H323_CONF_ID="h323-conf-id=16000 647BEE1D 80F000A F453DBFD"\
     H323_CALL_ORIGIN="h323-call-origin=originate"
#     HUNTGROUP_NAME="voips" 
#     CHAP_PASSWORD="0x06a8f3fb0ab5f4a8e90a590686c845c456" \
  elif [ t${ACCOUNTING_ACTION} = 'tStart' ] ; then
    echo "Start\n";

    ${RAUTH} NAS_IP_ADDRESS="${NAS_IP_ADDRESS}" \
       CHAP_PASSWORD="0x0338b5a0e6ade0557eb9e5d208fe0f5eee" \
       H323_CONF_ID="h323-conf-id=16000 647BEE1D 80F000A F453DBFD"\
       H323_GW_ID="h323-gw-id=ASMODEUSGK"\
       NAS_PORT_TYPE="Virtual"\
       CALLING_STATION_ID="101"\
       H323_CALL_ORIGIN="h323-call-origin=originate"\
       NAS_IDENTIFIER="ASMODEUSGK"\
       SERVICE_TYPE="Login-User"\
       CLIENT_IP_ADDRESS="192.168.101.17"\
       CHAP_CHALLENGE="0x43aea616"\
       FRAMED_IP_ADDRESS="192.168.101.23"\
       USER_NAME="${USER_NAME}"\
       CALLED_STATION_ID="613"\
       H323_CALL_TYPE="h323-call-type=VoIP"\
       HUNTGROUP_NAME="voips"

# RadAliasAuth
#      ${RAUTH}  NAS_IP_ADDRESS="192.168.101.17" \
#       USER_PASSWORD="101"\
#       H323_CONF_ID="h323-conf-id=16000 647BEE1D 80F000A F453DBFD"\
#       H323_GW_ID="h323-gw-id=ASMODEUSGK"\
#       NAS_PORT_TYPE="Virtual"\
#       CALLING_STATION_ID="101"\
#       H323_CALL_ORIGIN="h323-call-origin=originate"\
#       NAS_IDENTIFIER="ASMODEUSGK"\
#       SERVICE_TYPE="Login-User"\
#       CLIENT_IP_ADDRESS="192.168.101.17"\
#       FRAMED_IP_ADDRESS="192.168.101.23"\
#       USER_NAME="101"\
#       CALLED_STATION_ID="613"\
#       H323_CALL_TYPE="h323-call-type=VoIP"\
#       HUNTGROUP_NAME="voips"


    ${RACCT}  ACCT_UNIQUE_SESSION_ID="7ae849dcfba1c03f"\
      H323_CONF_ID="h323-conf-id=16000 647BEE1D 80F000A F453DBFD"\
      NAS_PORT_TYPE="Virtual"\
      H323_CALL_ORIGIN="h323-call-origin=proxy"\
      NAS_IDENTIFIER="ASMODEUSGK"\
      CLIENT_IP_ADDRESS="192.168.101.17"\
      CISCO_AVPAIR="h323-ivr-out=h323-call-id:16000 660DB41B 209000A F453DBFD"\
      ACCT_STATUS_TYPE="Start"\
      SERVICE_TYPE="Login-User"\
      H323_SETUP_TIME="h323-setup-time=15:59:47.000 EET Sun Dec 25 2005"\
      USER_NAME="${USER_NAME}"\
      NAS_IP_ADDRESS="${NAS_IP_ADDRESS}"\
      H323_GW_ID="h323-gw-id=ASMODEUSGK"\
      CALLING_STATION_ID="101"\
      H323_REMOTE_ADDRESS="h323-remote-address=192.168.101.4"\
      ACCT_SESSION_ID="43ad25ca0000000e"\
      FRAMED_IP_ADDRESS="192.168.101.23"\
      ACCT_DELAY_TIME="0"\
      H323_CALL_TYPE="h323-call-type=VoIP"\
      CALLED_STATION_ID="613"


   elif [ t${ACCOUNTING_ACTION} = 'tStop' ] ; then
     echo "Voip Stop"
     ${RACCT}  ACCT_UNIQUE_SESSION_ID="7ae849dcfba1c03f"\
   H323_CONF_ID="h323-conf-id=16000 647BEE1D 80F000A F453DBFD"\
   NAS_PORT_TYPE="Virtual"\
   H323_CALL_ORIGIN="h323-call-origin=proxy"\
   NAS_IDENTIFIER="ASMODEUSGK"\
   CLIENT_IP_ADDRESS="192.168.101.17"\
   CISCO_AVPAIR="h323-ivr-out=h323-call-id:16000 660DB41B 209000A F453DBFD"\
   H323_DISCONNECT_CAUSE="h323-disconnect-cause=10"\
   ACCT_STATUS_TYPE="Stop"\
   SERVICE_TYPE="Login-User"\
   H323_SETUP_TIME="h323-setup-time=15:59:47.000 EET Sun Dec 25 2005"\
   H323_DISCONNECT_TIME="h323-disconnect-time=16:01:54.000 EET Sun Dec 25 2005"\
   USER_NAME="101"\
   NAS_IP_ADDRESS="${NAS_IP_ADDRESS}"\
   ACCT_SESSION_TIME="99"\
   H323_GW_ID="h323-gw-id=ASMODEUSGK"\
   CALLING_STATION_ID="101"\
   H323_CONNECT_TIME="h323-connect-time=16:00:15.000 EET Sun Dec 25 2005"\
   H323_REMOTE_ADDRESS="h323-remote-address=192.168.101.4"\
   ACCT_SESSION_ID="43ad25ca0000000e"\
   FRAMED_IP_ADDRESS="192.168.101.23"\
   H323_CALL_TYPE="h323-call-type=VoIP"\
   CALLED_STATION_ID="613"\
   ACCT_DELAY_TIME="0"\

fi
	
	exit;
}

# Get user name
if [ "${ACTION}" != "help" ]; then
  echo -n "USER_NAME (${USER_NAME}): "
  read _input
  if [ w${_input} != w ]; then
    USER_NAME=${_input}
  fi;
fi;

# Make direct radius request
if [ "${RADIUS_ACTION}" = 1 ]; then
  #if [ x${RADIUS_SECRET} = x ]; then
  #  RADIUS_SECRET=radsecret;
  #fi;

  if [ "${RADIUS_IP}" = "" ]; then
    RADIUS_IP=127.0.0.1;
  else 
    PORT=`echo ${RADIUS_IP}  | awk -F : '{ print $2 }'`
    RADIUS_IP=`echo ${RADIUS_IP}  | awk -F : '{ print $1 }'`
  fi;

  echo "RAD FILE: ${RAD_FILE}";

  if [ "${RAD_DICT}" != "" ]; then
    OPTIONS="-d ${RAD_DICT}";
  fi;


  if [ "${RAD_FILE}" != "" ]; then
    if [ "${ACTION}" = acct ]; then
      if [ "${PORT}" = "" ]; then
        PORT=1813;
      fi;
    else
      if [ "${PORT}" = "" ]; then
       PORT=1812;
      fi;
    fi;

    ${RADCLIENT} ${OPTIONS} -x -f ${RAD_FILE}  ${RADIUS_IP}:${PORT} ${ACTION} ${RADIUS_SECRET}
    echo "${RADCLIENT} -x -f ${RAD_FILE}  ${RADIUS_IP}:${PORT} ${ACTION} ${RADIUS_SECRET}";
  else

    if [ "${PORT}" = "" ]; then
       PORT=1812;
    fi;

    NAS_ADDR_ATTR="NAS-IP-Address"
    PASSWORD="User-Password"

    (
        echo "User-Name = \"${USER_NAME}\""
        echo "${PASSWORD} = \"${USER_PASSWORD}\""
        echo "${NAS_ADDR_ATTR} = ${NAS_IP_ADDRESS}"
        echo "NAS-Port = 1"
        echo "Message-Authenticator = 0x00"

        if [ "${CALLING_STATION_ID}" ]; then
          echo "Calling-Station-Id = \"${CALLING_STATION_ID}\""
        fi
    ) | ${RADCLIENT} ${OPTIONS} -x  ${RADIUS_IP}:${PORT} auth "${RADIUS_SECRET}"
  fi;

  echo "Send params to radius: ${RADIUS_IP}:${PORT}"
  exit;
fi;



if [ "${VOIP}" = 1 ] ; then
  voip_auth;
elif [ "${ACTION}" = "coa" ]; then
  _coa
elif [ "${ACTION}" = 'auth' ] ; then
  echo "Auth test Begin"
  ${RAUTH} \
        SERVICE_TYPE=VPN \
        NAS_IP_ADDRESS=${NAS_IP_ADDRESS}\
        USER_PASSWORD="${USER_PASSWORD}"\
        USER_NAME="${USER_NAME}"\
        CALLING_STATION_ID="${CALLING_STATION_ID}"

   echo "" 
   echo "Auth test end"
#DHCP Freeradius test
elif [ t${ACTION} = tdhcp ]; then
   echo "DHCP test Begin"
   ${RAUTH} post_auth \
 DHCP-Your-IP-Address="0.0.0.0"\
 DHCP-Message-Type="DHCP-Discover"\
 DHCP-Vendor-Class-Identifier="MSFT 5.0"\
 DHCP-Hop-Count="1"\
 DHCP-Number-of-Seconds="0"\
 DHCP-Client-IP-Address="0.0.0.0"\
 DHCP-Gateway-IP-Address="10.2.0.1"\
 DHCP-Hardware-Type="Ethernet"\
 DHCP-Flags="Broadcast"\
 DHCP-Hardware-Address-Length="6"\
 DHCP-Hostname="\214\256\251\252\256\254\257\354\356\342\245\340"\
 DHCP-Opcode="Client-Message"\
 DHCP-Transaction-Id="2882764849"\
 DHCP-Parameter-Request-List="ARRAY(0x28560e38)"\
 DHCP-Client-Hardware-Address="00:15:17:be:d1:ae"\
 DHCP-Relay-Agent-Information="0x0106000403e9010d020800060012cffbeeb9"\
 DHCP-Server-IP-Address="0.0.0.0"\
 DHCP-Requested-IP-Address="10.2.0.15"\
 DHCP-Client-Identifier="00:15:17:be:d1:ae"

# DHCP_YOUR_IP_ADDRESS="0.0.0.0"\
# DHCP_MESSAGE_TYPE="DHCP-Request"\
# DHCP_VENDOR_CLASS_IDENTIFIER="MSFT 5.0"\
# DHCP_HOP_COUNT="1"\
# DHCP_NUMBER_OF_SECONDS="0"\
# DHCP_CLIENT_IP_ADDRESS="10.0.0.95"\
# DHCP_GATEWAY_IP_ADDRESS="10.2.0.1"\
# DHCP_HARDWARE_TYPE="ETHERNET"\
# DHCP_FLAGS="BROADCAST"\
# DHCP_HARDWARE_ADDRESS_LENGTH="6"\
# DHCP_HOSTNAME="\214\256\251\252\256\254\257\354\356\342\245\340"\
# DHCP_OPCODE="CLIENT-MESSAGE"\
# DHCP_TRANSACTION_ID="3391227009"\
# DHCP_PARAMETER_REQUEST_LIST="ARRAY(0X2855FF64)"\
# DHCP_CLIENT_HARDWARE_ADDRESS="00:15:17:be:d1:ae"\
# DHCP_RELAY_AGENT_INFORMATION="0x0106000403e9010d020800060012cffbeeb9"\
# DHCP_SERVER_IP_ADDRESS="0.0.0.0"\
# DHCP_CLIENT_FQDN="\000\000\000\214\256\251\252\256\254\257\354\356\342\245\340"\
 DHCP_CLIENT_IDENTIFIER="00:15:17:be:d1:ae"


   echo "DHCP Request";
#    DHCP_DHCP_SERVER_INDENTIFIER=192.168.1.200\
#    DHCP_YOUR_IP_ADDRESS=192.168.1.101\
#    DHCP_INTERFACE_INDEX=192.168.1.200\
#    DHCP_CLIENT_HARDWARE_ADDRESS=0x0004764ec1d5\
#    NAS_IP_ADDRESS=${NAS_IP_ADDRESS}
 #      USER_NAME="00:04:76:4e:c1:d5"\
 #      USER_PASSWORD="dhcpuser"\
 #      NAS_IP_ADDRESS=${NAS_IP_ADDRESS}\
 #      NAS_PORT="3232235816"\
 #      DHCP_MESSAGE_TYPE="DHCP-Discover"



elif [ x${ACTION} = 'xacct' ]; then
  echo "Accounting test begin";

  if [ t${ACCOUNTING_ACTION} = 'tStart' ]; then
    echo "ACCT_STATUS_TYPE: Start";
    ${RACCT} \
        USER_NAME="${USER_NAME}" \
        SERVICE_TYPE=Framed-User \
        FRAMED_PROTOCOL=PPP \
        FRAMED_IP_ADDRESS=10.0.0.1 \
        FRAMED_IP_NETMASK=0.0.0.0 \
        CISCO_AVPAIR="connect-progress=LAN Ses Up"\
        CISCO_AVPAIR="client-mac-address=0001.29d2.2695"\
        NAS_IP_ADDRESS=${NAS_IP_ADDRESS} \
        NAS_IDENTIFIER="media.intranet" \
        NAS_PORT_TYPE=Virtual \
        ACCT_STATUS_TYPE=Start \
        ACCT_SESSION_ID="${ACCT_SESSION_ID}" \
#        CALLING_STATION_ID="192.168.101.4" \

   elif [ t${ACCOUNTING_ACTION} = 'tAlive' ] ; then
     echo "ACCT_STATUS_TYPE: Alive/Interim-Update";
      
     alive=0
     IN=${ACCT_INPUT_OCTETS}
     OUT=${ACCT_OUTPUT_OCTETS}
     TIME=${ACCT_SESSION_TIME};

     while [ "${alive}" -lt ${ALIVE_COUNT} ]; do
        ACCT_INPUT_OCTETS=`expr ${alive} \* ${IN} + ${IN}`
        ACCT_OUTPUT_OCTETS=`expr ${alive} \* ${OUT} + ${OUT}`
        ACCT_SESSION_TIME=`expr ${alive} \* ${TIME} + ${TIME}`

        echo "IN: ${ACCT_INPUT_OCTETS} OUT: ${ACCT_OUTPUT_OCTETS} TIME: ${ACCT_SESSION_TIME}";

        ${RACCT} \
          USER_NAME="${USER_NAME}" \
          SERVICE_TYPE=Framed-User \
          FRAMED_PROTOCOL=PPP \
          FRAMED_IP_ADDRESS=10.0.0.1 \
          FRAMED_IP_NETMASK=0.0.0.0 \
          CALLING_STATION_ID="${CALLING_STATION_ID}" \
          NAS_IP_ADDRESS=${NAS_IP_ADDRESS} \
          NAS_IDENTIFIER="media.intranet" \
          NAS_PORT_TYPE=Virtual \
          ACCT_STATUS_TYPE=Interim-Update \
          ACCT_SESSION_ID="${ACCT_SESSION_ID}" \
          ACCT_DELAY_TIME=0 \
          ACCT_INPUT_OCTETS=${ACCT_INPUT_OCTETS} \
          ACCT_INPUT_GIGAWORDS=${ACCT_INPUT_GIGAWORDS} \
          ACCT_INPUT_PACKETS=1244553 \
          ACCT_OUTPUT_OCTETS=${ACCT_OUTPUT_OCTETS} \
          EXPPP_ACCT_LOCALINPUT_OCTETS=12000000 \
          EXPPP_ACCT_LOCALOUTPUT_OCTETS=13000000 \
          ACCT_OUTPUT_GIGAWORDS=${ACCT_OUTPUT_GIGAWORDS} \
          ACCT_OUTPUT_PACKETS=0 \
          ACCT_SESSION_TIME=${ACCT_SESSION_TIME}
        a=`expr ${a} + 1`
        read _input
     done


   elif [ t${ACCOUNTING_ACTION} = 'tStop' ] ; then
     echo "ACCT_STATUS_TYPE: Stop";
     ${RACCT}  \
        USER_NAME="${USER_NAME}" \
        SERVICE_TYPE=Framed-User \
        FRAMED_PROTOCOL=PPP \
        FRAMED_IP_ADDRESS=10.0.0.1 \
        FRAMED_IP_NETMASK=0.0.0.0 \
        CALLING_STATION_ID="${CALLING_STATION_ID}" \
        NAS_IP_ADDRESS=${NAS_IP_ADDRESS} \
        NAS_IDENTIFIER="media.intranet" \
        NAS_PORT_TYPE=Virtual \
        ACCT_STATUS_TYPE=Stop \
        ACCT_SESSION_ID="${ACCT_SESSION_ID}" \
        ACCT_DELAY_TIME=0 \
        ACCT_INPUT_OCTETS=${ACCT_INPUT_OCTETS} \
        ACCT_INPUT_GIGAWORDS=${ACCT_INPUT_GIGAWORDS} \
        ACCT_INPUT_PACKETS=125 \
        ACCT_OUTPUT_OCTETS=${ACCT_OUTPUT_OCTETS} \
        EXPPP_ACCT_LOCALINPUT_OCTETS=12000000 \
        EXPPP_ACCT_LOCALOUTPUT_OCTETS=13000000 \
        ACCT_OUTPUT_GIGAWORDS=${ACCT_OUTPUT_GIGAWORDS} \
        ACCT_OUTPUT_PACKETS=1111 \
        ACCT_SESSION_TIME=${ACCT_SESSION_TIME} \

   fi;

   echo "Accounting test end";

elif [ "${ACTION}" = 'acctgt' ]; then

  echo "Account requirest GT: "
  cat ${ACCT_LOG} | grep GT | awk '{ print $11"  "$1" "$2" "$5" "$8" "$9 }' | sort -n
elif [ t${ACTION} = 'tauthgt' ]; then
  cat ${AUTH_LOG} | grep GT | awk '{ print $10"  "$1" "$2" "$5" "$8 }' | sort -n
elif [ "${RAD_STATUS}" != "" ]; then
  rad_status;
else
  echo "Arguments (auth | acct | authgt | acctgt)"
  echo "
       auth - test authentification
       acct (Stop|Start|Alive) - test accounting
       coa  - CoA test
       authgt - show authentification generation time
       acctgt - show account generation time
VoIP Functions
       voip auth 
       voip acct (Stop|Start|Alive)
DHCP Function
       dhcp   - test radius dhcp 
       -u     - User name (Default: test)
       -p     - Userr password (Default: 123456)
       -nas   - Nas ip address (Default: 127.0.0.1)
       -cid   - CALLING_STATION_ID (Default: )
       -session_id ACCT_SESSION_ID (Default: ${ACCT_SESSION_ID})

       -rad     - Send request to RADIUS
       -rad_secret - RADIUS secret (Default: radsecret)
       -rad_ip  - RADIUS IP address (Default: 127.0.0.1)
       -rad_file- Get data from file
       -rad_dict- Radius dictionary folder 

       -debug - Debug mode
       -v     - Show version
  "
fi
