#!/bin/sh
# ABILLS Certificate creator
#
# REVISION 20201027
#
#***********************************************************

SSL=/usr/local/openssl
OPENSSL=`which openssl`
export PATH=/usr/src/crypto/${OPENSSL}/apps/:${SSL}/bin/:${SSL}/ssl/misc:${PATH}
export LD_LIBRARY_PATH=/openssl/lib
CA_pl='/usr/src/crypto/openssl/apps/CA.pl';


hostname=`hostname`;
password=whatever;
VERSION=2.13;
DAYS=730;
DATE=`date`;
CERT_TYPE=$1;
CERT_USER="";
CERT_LENGTH=2048;
OS=`uname`;
SSH_KEY_TYPE=""

if [ "$1" = "help" ]; then
  shift ;
fi;


if [ "$1" = "" ] ; then
  echo "Create SSL Certs and SSH keys. Version: ${VERSION} ";
  echo "certs_create.sh [apache|eap|postfix_tls|ssh|express_oplata] -D";
  echo " apache         - Create apache SSL cert"
  echo " eap            - Create Server and users SSL Certs"
  echo " postfix_tls    - Create postfix TLS Certs"
  echo " express_oplata - Express oplata payment system"
  echo " easysoft [public_key] - Easysoft payment system x509 certs"
  echo " privatbank [public_key] - privatbank payment system x509 certs"
  echo " info [file]    - Get info from SSL cert"
  echo " ssh [USER]     - Create SSH DSA Keys"
  echo "                USER - SSH remote user"
  echo " SSH_KEY_TYPE=dsa  (Defauls: rsa)"
  echo " -D [PATH]      - Path for ssl certs"
  echo " -U [username]  - Cert owner (Default: apache=www, postfix=vmail)"
  echo " -silent        - Silent mode"
  echo " -LENGTH        - Cert length (Default: ${CERT_LENGTH})"
  echo " -DAYS          - Cert period in days (Default: ${DAYS})"
  echo " -PASSSWORD     - Password for Certs (Default: whatever)"
  echo " -HOSTNAME      - Hostname for Certs (default: system hostname)"
  echo " -UPLOAD        - Upload ssh certs to host via ssh (default: )"
  echo " -UPLOAD_FTP    - Upload ssh certs to host via ftp (-UPLOAD_FTP user@host )"


  exit;
fi

BILLING_DIR=/usr/axbills
CERT_PATH=${BILLING_DIR}/Certs/

# Proccess command-line options
for _switch ; do
  case ${_switch} in
  ssh)    USER=$2;
          CERT_TYPE=ssh;
          shift; shift;
          ;;
  -D)     CERT_PATH=$2;
          shift; shift
          ;;
  #Cert owner
  -U)     CERT_USER="$3"
          shift; shift
          ;;
  -LENGTH) CERT_LENGTH=$2
          shift; shift
          ;;
  -DAYS) DAYS=$3
          shift; shift
          ;;
  -PASSWORD) password=$2
          shift; shift
          ;;
  -HOSTNAME) _HOSTNAME=$2
          shift; shift
          ;;
  -UPLOAD) UPLOAD=y; _HOSTNAME=$3
          shift;
          ;;
  -UPLOAD_FTP) UPLOAD_FTP=y; UPLOAD=y; _HOSTNAME=$2
          echo "Upload ftp: ${_HOSTNAME}";
          shift; shift;
          ;;
  -FTP_PASIVE) FTP_PASIVE=1
          shift;
          ;;
  -SKIP_UPLOAD_CERT) SKIP_UPLOAD_CERT=1
          shift;
          ;;
  -silent) SILENT_MODE=1
          shift;
          ;;

  esac
done


if [ ! -d ${CERT_PATH} ] ; then
  mkdir ${CERT_PATH};
fi
cd ${CERT_PATH};


#Get users
if [ -f /usr/axbills/AXbills/programs ]; then
  CERT_USER=`cat /usr/axbills/AXbills/programs | grep WEB_SERVER_USER | awk -F= '{ print $2 }'`;
  RESTART_APACHE=`cat /usr/axbills/AXbills/programs | grep RESTART_APACHE | awk -F= '{ print $2 }'`;
fi;

#Default Cert user
if [ "${CERT_USER}" = "" ];  then
  if [ x`uname` = xLinux ]; then
     APACHE_USER="www-data";
  else
    APACHE_USER=www;
  fi;
else
  APACHE_USER=${CERT_USER};
fi;


#**********************************************************
# Create x509 key
# easysoft payments system
# http://easysoft.com.ua/
# kabanets@easysoft.com.ua
# it@easypay.ua
#**********************************************************
x509_cert () {

  SYSTEM_NAME=$1;
  SEND_EMAIL=$2;
  PUBLIC_KEY=$3;

  echo "#******************************************************************************"
  echo "#Creating ${SYSTEM_NAME} certs"
  echo "#"
  echo "#******************************************************************************"
  echo


  if [ x${PUBLIC_KEY} = x  ]; then
    echo "Enter path to ${SYSTEM_NAME} public key: ";
    read EASYSOFT_PUBLIC_KEY
  else
    PUBLIC_KEY=$3;
  fi;

  if [ x${PUBLIC_KEY} = x ]; then
    echo "Enter ${SYSTEM_NAME} public key";
    exit;
  fi;

  if [ "${PUBLIC_KEY}" != "" ]; then
    EASYSOFT_PUBLIC_KEY=${PUBLIC_KEY};
    cp ${PUBLIC_KEY} ${CERT_PATH}/${SYSTEM_NAME}_server_public.pem
    chown ${APACHE_USER} ${CERT_PATH}/${SYSTEM_NAME}_server_public.pem
    echo "Easy soft public key '${PUBLIC_KEY}' copy to ${CERT_PATH}/${SYSTEM_NAME}_server_public.pem"
  fi;

  ${OPENSSL} x509 -inform pem -in ${EASYSOFT_PUBLIC_KEY} -pubkey -out ${CERT_PATH}/${SYSTEM_NAME}_public_key.pem > ${CERT_PATH}/${SYSTEM_NAME}_server_public.pem

  CERT_LENGTH=1024;
  # Private key
  ${OPENSSL} genrsa -out ${SYSTEM_NAME}_private.ppk ${CERT_LENGTH}
  ${OPENSSL} req -new -key ${SYSTEM_NAME}_private.ppk -out ${SYSTEM_NAME}.req
  #${OPENSSL} ca -in ${SYSTEM_NAME}.req -out ${SYSTEM_NAME}.cer
  ${OPENSSL} x509 -req -days ${DAYS} -in ${SYSTEM_NAME}.req -signkey ${SYSTEM_NAME}_private.ppk -out ${SYSTEM_NAME}.cer
  ${OPENSSL} rsa -in  ${CERT_PATH}/${SYSTEM_NAME}_private.ppk -out ${CERT_PATH}/${SYSTEM_NAME}_public.pem -pubout

  chmod u=r,go= ${CERT_PATH}/${SYSTEM_NAME}.cer
  chown ${APACHE_USER} ${CERT_PATH}/${SYSTEM_NAME}.cer ${CERT_PATH}/${SYSTEM_NAME}_private.ppk ${CERT_PATH}/${SYSTEM_NAME}_public.pem

  if [ x${SEND_EMAIL} !=  x ]; then
    echo "Sert created: ";
    echo "Send this file to ${SYSTEM_NAME} (${SEND_EMAIL}): ${CERT_PATH}/${SYSTEM_NAME}.cer";
  fi;
}

#**********************************************************
#Apache Certs
#**********************************************************
apache_cert () {

  check_ssl_conf;

  echo "*******************************************************************************"
  echo "Creating Apache server private key and certificate"
  echo "When prompted enter the server name in the Common Name field."
  echo "*******************************************************************************"
  echo

  if [ -f "${CERT_PATH}/server.crt" ]; then
    echo "Certificate for apache exists:";
    ls ${CERT_PATH}/server.*

    if [ "${AINSTALL}" != "" ]; then
      RM_CERTS="y"
    else
      echo -n "Overwrite it and generate new certificate? [Y/n] ";
      read RM_CERTS
    fi;

    if [ "${RM_CERTS}" != "n" ]; then
      echo "Removing old certificate."
      rm ${CERT_PATH}/server.*
    else
      echo "Will not overwrite existing certificate. Exiting."
      exit 0
    fi;
  fi;

  OLD=1;

#Old way des3
if [ "${OLD}" != "" ] ; then

  ${OPENSSL} genrsa -des3 -passout pass:${password} -out server.key ${CERT_LENGTH}

  ${OPENSSL} req -new -key server.key -out server.csr \
    -passin pass:${password} -passout pass:${password}

  ${OPENSSL} x509 -req -days ${DAYS} -in server.csr -signkey server.key -out server.crt \
    -passin pass:${password}

  #Make public key
  ${OPENSSL} rsa -in ${CERT_PATH}/server.key -out ${CERT_PATH}/server_public.pem -pubout \
    -passin pass:${password}

  #PKS12 Public key
  #  ${OPENSSL} pkcs12 -export -in server.crt -inkey server.key -out server_public.pem.p12
#New way
else
#New way
   #1. Generate Private Key on the Server Running Apache + mod_ssl
   # openssl genrsa -des3 -out www.thegeekstuff.com.key 1024

   #2. Generate a Certificate Signing Request (CSR)
   #
   ${OPENSSL} req -new -newkey "rsa:${CERT_LENGTH}" -nodes -sha256 -out server.csr -keyout server.key
   #-subj "/C=UA/ST=Calvados/L=CAEN/O=INTERNET/CN=axbills.mydomain.com"

   #3. Generate a Self-Signed SSL Certificate
   ${OPENSSL} x509 -req -days ${DAYS} -in server.csr -signkey server.key -out server.crt
fi;

  #PKS12 Public key
#  ${OPENSSL} pkcs12 -export -in server.crt -inkey server.key -out server_public.pem.p12

  chmod u=r,go= ${CERT_PATH}/server.key
  chmod u=r,go= ${CERT_PATH}/server.crt
  chown ${APACHE_USER} server.crt server.csr

  cp ${CERT_PATH}/server.key ${CERT_PATH}/server.key.org

  ${OPENSSL} rsa -in server.key.org -out server.key \
   -passin pass:${password} -passout pass:${password}

  cert_info server.crt

  chmod 400 server.key

  if [ "${RESTART_APACHE}" != "" ]; then
    if [ "${AINSTALL}" != "" ]; then
      RESTART="y"
    else
      echo -n "Restart apache: [Y/n]";
      read RESTART
    fi;

    if [ "${RESTART}" != "n" ]; then
      ${RESTART_APACHE} restart
    fi;
  else
    echo "Please restart apache";
  fi;
}


#**********************************************************
# Create SSH certs
#
#
#**********************************************************
ssh_key () {

  if [ "${SSH_KEY_TYPE}" = "" ]; then
    SSH_KEY_TYPE=rsa
  fi;

  if [ "${USER}" = "" ]; then
    USER=axbills_admin
  fi;

  if [ "${CERT_TYPE}" = "" ]; then
    id_cert_file=id_${SSH_KEY_TYPE};
  else
    id_cert_file=id_${SSH_KEY_TYPE}.${USER};
  fi;

  if [ "${SILENT_MODE}" = "" ]; then
    echo "**************************************************************************"
    echo "Creating SSH authentication Key"
    echo " Make ssh-keygen with empty password."
    echo "**************************************************************************"
    echo
    echo "Create cert for User: ${USER}"
    echo "  ${CERT_PATH}${id_cert_file}"
  fi;

  SSH_PORT=22

  # If exist only upload
  if [ -f ${CERT_PATH}${id_cert_file} ]; then
     echo "Cert exists: ${CERT_PATH}${id_cert_file}";
    if [ ! SKIP_UPLOAD_CERT ]; then
     if [ "${UPLOAD}" = "" ]; then
       echo -n "Upload to remote host via ssh [Y/n]: "
       read UPLOAD
     fi;
    fi;
  fi;

  if [ ! -f ${CERT_PATH}${id_cert_file} ]; then
    ssh-keygen -t ${SSH_KEY_TYPE} -C "ABillS remote machine manage key (${DATE})" -f "${CERT_PATH}${id_cert_file}" -N ""

    chown ${APACHE_USER} ${CERT_PATH}${id_cert_file}
    chmod u=r,go= ${CERT_PATH}/${id_cert_file}.pub
    if [ ! SKIP_UPLOAD_CERT ]; then
      echo "Set Cert user: ${CERT_USER}";
      echo -n "Upload file to remote host via ssh [Y/n]: "
      read UPLOAD
    fi;
  fi;

  if [ "${UPLOAD}" = "y" ]; then
    if [ "${_HOSTNAME}" = "x" ]; then
      echo -n "Enter host: "
      read _HOSTNAME
      SSH_PORT=`echo ${_HOSTNAME} | awk -F: '{ print $2 }'`
      _HOSTNAME=`echo ${_HOSTNAME} | awk -F: '{ print $1 }'`
      if [ "${SSH_PORT}" = "" ]; then
        SSH_PORT=22;
      fi;
    fi;

    if [ "${UPLOAD_FTP}" = "y" ]; then
      FTP_PORT=21

      FTP=`which ftp`
      if [ "${FTP}" = "" ] ; then
        echo "ftp client not install.";
        echo "Please install ftp client";
        exit;
      fi;

      FTP_PASIVE=1;
      if [ "${FTP_PASIVE}" != "" ]; then
        FTP="${FTP} -p"
      fi;

      if [ ! SKIP_UPLOAD_CERT ]; then
        echo "Make upload to: ${_HOSTNAME}:${FTP_PORT}/${id_cert_file}.pub ${CERT_PATH}${id_cert_file}.pub"
      fi;

      CHECK_USER=`echo ${_HOSTNAME} | grep @`;
      if [ "${CHECK_USER}" != "" ]; then
        USER=`echo ${_HOSTNAME} | awk -F@ '{ print $1 }'`
        _HOSTNAME=`echo ${_HOSTNAME} | awk -F@ '{ print $2 }'`
      fi;

      echo -n "Enter ftp password: "
      read FTP_PASSWD

      if [ "${OS}" = "FreeBSD" ] ; then
         ${FTP} -u ftp://${USER}:${FTP_PASSWD}@${_HOSTNAME}:${FTP_PORT}/${id_cert_file}.pub ${CERT_PATH}${id_cert_file}.pub
      else
        (echo user ${USER} "${FTP_PASSWD}"; echo "cd /"; echo "ls"; echo "lcd ${CERT_PATH}";  echo "put ${id_cert_file}.pub"; ) | ${FTP} -ivn ${_HOSTNAME}
      fi;

      _HOSTNAME=`echo ${_HOSTNAME} | awk -F@ '{print $2}'`;
      exit;
    else
      echo "Making upload to: ${USER}@${_HOSTNAME} "
      ssh -p ${SSH_PORT} ${USER}@${_HOSTNAME} "mkdir ~/.ssh"
      scp -P ${SSH_PORT} ${CERT_PATH}${id_cert_file}.pub ${USER}@${_HOSTNAME}:~/.ssh/authorized_keys
    fi;


    echo -n "Connect to remote host: ${_HOSTNAME} [y/n]: "
    read CONNECT
    if [ "${CONNECT}" = "y" ]; then
      ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no -i ${CERT_PATH}${id_cert_file}  ${USER}@${_HOSTNAME}
      exit;
    fi;
  else
    if [ ! SKIP_UPLOAD_CERT ]; then
      if [ "${SILENT_MODE}" = "" ]; then
        echo
        echo "Copy certs manual: "
        echo "${CERT_PATH}${id_cert_file}.pub to REMOTE_HOST User home dir (/home/${USER}/.ssh/authorized_keys) "
        echo
      fi;
    fi
  fi;
}

#**********************************************************
# create Express Oplata Certs
# www.express-oplata.ru/
#**********************************************************
express_oplata () {
  echo "#*******************************************************************************"
  echo "#Creating Express Oplata"
  echo "#"
  echo "#*******************************************************************************"
  echo

  CERT_LENGTH=1024;
  password="whatever"
  # Private key
  echo ${OPENSSL};
  ${OPENSSL} genrsa  -passout pass:${password} -out express_oplata_private.pem ${CERT_LENGTH}


  # Publick key
  ${OPENSSL} rsa -in express_oplata_private.pem -out express_oplata_public.pem -pubout \
    -passin pass:${password}

  chmod u=r,go= ${CERT_PATH}/express_oplata_private.pem
  chmod u=r,go= ${CERT_PATH}/express_oplata_public.pem
  chown ${APACHE_USER} ${CERT_PATH}/express_oplata_private.pem ${CERT_PATH}/express_oplata_public.pem

  echo -n "Send public key '${CERT_PATH}/express_oplata_public.pem' to Express Oplata? (y/n): ";

  read _SEND_MAIL
  if [ w"${_SEND_MAIL}" = wy ]; then
    EO_EMAIL="onwave@express-oplata.ru";

    echo -n "Enter comments: "
    read COMMENTS

    echo -n "BCC: "
    read BCC_EMAIL

    if [ "${BCC_EMAIL}" != "" ]; then
      BCC_EMAIL="-b ${BCC_EMAIL}"
    fi;

    ( echo "${COMMENTS}"; uuencode /usr/axbills/Certs/express_oplata_public.pem express_oplata_public.pem ) | mail -s "Public Cert" ${BCC_EMAIL} ${EO_EMAIL}

    echo "Cert sended to Expres-Oplata"
  fi;

}

#**********************************************************
# Information about Certs
#**********************************************************
cert_info () {
  echo "******************************************************************************"
  echo "Cert info $2"
  echo "******************************************************************************"

  FILENAME=$1;
  if [ w"$FILENAME" = w ] ; then
    echo "Select Cert file";
    exit;
  else
    echo "Cert file: $FILENAME";
  fi;

  ${OPENSSL} x509 -in ${FILENAME} -noout -subject  -startdate -enddate -fingerprint -sha256
}

#**********************************************************
# postfix
#**********************************************************
postfix_cert () {
  echo "******************************************************************************"
  echo "Make POSTFIX TLS sertificats"
  echo "******************************************************************************"

  check_ssl_conf

mkdir ${CERT_PATH}
cd ${CERT_PATH}

openssl genrsa -des3 -rand /etc/hosts -out smtpd.key 1024
#������ ������ ��� ������ �����-����� smtpd.key

chmod 600 smtpd.key
openssl req -new -key smtpd.key -out smtpd.csr
#����� ������ ������ �� smtpd.key, � ����� ��������� ����������

openssl x509 -req -days 3650 -in smtpd.csr -signkey smtpd.key -out smtpd.crt
#����� ������ �� smtpd.key

openssl rsa -in smtpd.key -out smtpd.key.unencrypted
#� ����� ������ �� smtpd.key

mv -f smtpd.key.unencrypted smtpd.key
openssl req -new -x509 -extensions v3_ca -keyout cakey.pem -out cacert.pem -days 3650
#�������� ���? ��, ������ �� smtpd.key, � ����� ���. ����������

#  ${OPENSSL} req -new -x509 -nodes -out smtpd.pem -keyout smtpd.pem -days ${DAYS} \
#    -passin pass:${password} -passout pass:${password}
}

#**********************************************************
# eap for radius
#**********************************************************
eap_cert () {
  echo "*******************************************************************************"
  echo "Make RADIUS EAP"
  echo "*******************************************************************************"

  CERT_EAP_PATH=${CERT_PATH}/eap
  if [ ! -d ${CERT_EAP_PATH} ] ; then
    mkdir ${CERT_EAP_PATH};
  fi

  cd ${CERT_EAP_PATH}
  echo
  pwd

if [ w$2 = wclient ]; then
  echo "*******************************************************************************"
  echo "Creating client private key and certificate"
  echo "When prompted enter the client name in the Common Name field. This is the same"
  echo " used as the Username in FreeRADIUS"
  echo "*******************************************************************************"
  echo

  # Request a new PKCS#10 certificate.
  # First, newreq.pem will be overwritten with the new certificate request
  ${OPENSSL} req -new -keyout newreq.pem -out newreq.pem -days ${DAYS} \
   -passin pass:${password} -passout pass:${password}


  # Sign the certificate request. The policy is defined in the ${OPENSSL}.cnf file.
  # The request generated in the previous step is specified with the -infiles option and
  # the output is in newcert.pem
  # The -extensions option is necessary to add the OID for the extended key for client authentication
  ${OPENSSL} ca -policy policy_anything -out newcert.pem -passin pass:${password} \
    -key ${password} -extensions xpclient_ext -extfile xpextensions \
    -infiles newreq.pem

  # Create a PKCS#12 file from the new certificate and its private key found in newreq.pem
  # and place in file cert-clt.p12
  ${OPENSSL} pkcs12 -export -in newcert.pem -inkey newreq.pem -out cert-clt.p12 -clcerts \
    -passin pass:${password} -passout pass:${password}

  # parse the PKCS#12 file just created and produce a PEM format certificate and key in cert-clt.pem
  ${OPENSSL} pkcs12 -in cert-clt.p12 -out cert-clt.pem \
   -passin pass:${password} -passout pass:${password}

  # Convert certificate from PEM format to DER format
  ${OPENSSL} x509 -inform PEM -outform DER -in cert-clt.pem -out cert-clt.der
  exit;
fi;


  echo "
[ xpclient_ext]
extendedKeyUsage = 1.3.6.1.5.5.7.3.2
[ xpserver_ext ]
extendedKeyUsage = 1.3.6.1.5.5.7.3.1
   " > xpextensions;

  #
  # Generate DH stuff...
  #
  ${OPENSSL} gendh > ${CERT_EAP_PATH}/dh
  date > ${CERT_EAP_PATH}/random

  # needed if you need to start from scratch otherwise the CA.pl -newca command doesn't copy the new
  # private key into the CA directories

  rm -rf demoCA

  echo "*******************************************************************************"
  echo "Creating self-signed private key and certificate"
  echo "When prompted override the default value for the Common Name field"
  echo "*******************************************************************************"
  echo

  # Generate a new self-signed certificate.
  # After invocation, newreq.pem will contain a private key and certificate
  # newreq.pem will be used in the next step
  ${OPENSSL} req -new -x509 -keyout newreq.pem -out newreq.pem -days ${DAYS} \
   -passin pass:${password} -passout pass:${password}


  echo "*******************************************************************************"
  echo "Creating a new CA hierarchy (used later by the "ca" command) with the certificate"
  echo "and private key created in the last step"
  echo "*******************************************************************************"
  echo

  #CA_pl=`which ${CA_pl}`;
  if [ -f ${CA_pl} ] ; then
    echo "newreq.pem" | ${CA_pl} -newca > /dev/null
  else
    echo "Can't find CA.pl";
    exit;
  fi;

  echo "*******************************************************************************"
  echo "Creating ROOT CA"
  echo "*******************************************************************************"
  echo

  # Create a PKCS#12 file, using the previously created CA certificate/key
  # The certificate in demoCA/cacert.pem is the same as in newreq.pem. Instead of
  # using "-in demoCA/cacert.pem" we could have used "-in newreq.pem" and then omitted
  # the "-inkey newreq.pem" because newreq.pem contains both the private key and certificate
  ${OPENSSL} pkcs12 -export -in demoCA/cacert.pem -inkey newreq.pem -out root.p12 -cacerts \
   -passin pass:${password} -passout pass:${password}

  # parse the PKCS#12 file just created and produce a PEM format certificate and key in root.pem
  ${OPENSSL} pkcs12 -in root.p12 -out root.pem \
    -passin pass:${password} -passout pass:${password}

  # Convert root certificate from PEM format to DER format
  ${OPENSSL} x509 -inform PEM -outform DER -in root.pem -out root.der

echo "*******************************************************************************"
echo "Creating server private key and certificate"
echo "When prompted enter the server name in the Common Name field."
echo "*******************************************************************************"
echo

# Request a new PKCS#10 certificate.
# First, newreq.pem will be overwritten with the new certificate request
${OPENSSL} req -new -keyout newreq.pem -out newreq.pem -days ${DAYS} \
-passin pass:${password} -passout pass:${password}

# Sign the certificate request. The policy is defined in the ${OPENSSL}.cnf file.
# The request generated in the previous step is specified with the -infiles option and
# the output is in newcert.pem
# The -extensions option is necessary to add the OID for the extended key for server authentication

${OPENSSL} ca -policy policy_anything -out newcert.pem -passin pass:${password} -key ${password} \
-extensions xpserver_ext -extfile xpextensions -infiles newreq.pem

# Create a PKCS#12 file from the new certificate and its private key found in newreq.pem
# and place in file cert-srv.p12
${OPENSSL} pkcs12 -export -in newcert.pem -inkey newreq.pem -out cert-srv.p12 -clcerts \
-passin pass:${password} -passout pass:${password}

# parse the PKCS#12 file just created and produce a PEM format certificate and key in cert-srv.pem
${OPENSSL} pkcs12 -in cert-srv.p12 -out cert-srv.pem -passin pass:${password} -passout pass:${password}

# Convert certificate from PEM format to DER format
${OPENSSL} x509 -inform PEM -outform DER -in cert-srv.pem -out cert-srv.der

#clean up
rm newcert.pem newreq.pem

}

#**********************************************************
# check ssl config
#**********************************************************
check_ssl_conf () {
  #Freebsd
  if [ -f /usr/local/openssl/openssl.cnf.sample -a ! -d /usr/local/openssl/openssl.cnf ]  ; then
    cp /usr/local/openssl/openssl.cnf.sample /usr/local/openssl/openssl.cnf
    echo "Maked openssl config '/usr/local/openssl/openssl.cnf'";
  fi;
}

#Cert functions
case ${CERT_TYPE} in
  ssh)
        ssh_key;
        ;;
  apache)
        apache_cert;
        ;;
  wexpress_oplata)
        wexpress_oplata;
        ;;
  info)
        cert_info $2;
        ;;
  postfix_tls)
        postfix_cert;
        ;;
  easysoft)
        x509_cert "easysoft" "kabanets@easysoft.com.ua,it@easypay.ua" "$2";
        ;;
  privatbank)
        x509_cert "privatbank" "" "$2";
        ;;
  eap)
        eap_cert;
        ;;
esac;

if [ "${SILENT_MODE}" = "" ]; then
  echo "${CERT_TYPE} Done...";
fi;
