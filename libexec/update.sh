#!/bin/sh
#**********************************************************
# AXbills updater
# License fetcher
# Amon update
#
# UPDATED: 20200410
#**********************************************************

. /usr/axbills/libexec/axbills_updater_logging

VERSION=2.51;

#ABillS Rel Version
REL_VERSION="rel-0-5";

BILLING_DIR='/usr/axbills';
FIND='/usr/bin/find';
SED=`which sed`;
DATE=`date "+%Y%m%d"`;
FULL_DATE=`date`;
TMP_DIR=/tmp
MYSQL=mysql
start_dir=`pwd`


UPDATE_LOGIN=
UPDATE_PASSWD=
UPDATE_CHECKSUM=
#SNAPHOT_URL=http://axbills.net.ua/snapshots/
UPDATE_URL="http://axbills.net.ua/misc/update.php"
CUR_FILE=$0;
ROLLBACK=""
AMON_FILE=""

SYSBENCH_DIR=/tmp
if [ -f "${BILLING_DIR}" ]; then
  SYSBENCH_DIR="${BILLING_DIR}";
fi;



#**********************************************************
# Check perl version
#**********************************************************
check_perl () {

  NEED_PERL_VERSION=512
  PERL=/usr/bin/perl
  if [ ! -f "${PERL}" ]; then
    echo "perl not instaled '${PERL}' "
    exit;
  fi;

  CHECK_VERSION=`${PERL} -e "print $^V" | sed 's/.*v\([0-9]*\.[0-9]*\)\..*/\1/'`;

  echo "Perl version: ${CHECK_VERSION}"
  echo "Recomended version: 5.20";

  CUR_PERL_VERSION=`echo "${CHECK_VERSION} * 100" | bc |cut -f1 -d "."`;

  if [ "${CUR_PERL_VERSION}" -lt "${NEED_PERL_VERSION}" ]; then
    #echo "${NEED_PERL_VERSION}" ."---". "${CUR_PERL_VERSION}"
    echo
    echo "*****************************************************************"
    echo "Please update PERL to version: 5.18 or highter "
    echo "Detail: http://axbills.net.ua/forum/viewtopic.php?f=10&t=8021"
    echo "*****************************************************************"
    echo
    exit;
  fi;

}

#**********************************************************
# Make db check
#**********************************************************
mk_db_check () {

  echo -n "Make DB check ? [Y/n]";

  read db_check

  if [ "${db_check}" != n ]; then
    echo "Starting DB check. (It may take few minutes)"
    ${BILLING_DIR}/misc/db_check/db_check.pl CREATE_NOT_EXIST_TABLES=1
    echo "db_check maked";
  fi;

}


#**********************************************************
# Get OS
#**********************************************************
get_os () {

OS=`uname -s`
OS_VERSION=`uname -r`
MACH=`uname -m`
OS_NAME=""

if [ "${OS}" = "SunOS" ] ; then
  OS=Solaris
  ARCH=`uname -p`
  OSSTR="${OS} ${OS_VERSION}(${ARCH} `uname -v`)"
elif [ "${OS}" = "AIX" ] ; then
  OSSTR="${OS} `oslevel` (`oslevel -r`)"
elif [ "${OS}" = "FreeBSD" ] ; then
  OS_NAME="FreeBSD";
  #OS_VERSION=`uname -r | awk -F\. '{ print $1 }'`
elif [ "${OS}" = "Linux" ] ; then
  #GetVersionFromFile
  KERNEL=`uname -r`
  if [ -f /etc/altlinux-release ]; then
    OS_NAME=`cat /etc/altlinux-release | awk '{ print $1 $2 }'`
    OS_VERSION=`cat /etc/altlinux-release | awk '{ print $3 }'`
  #RedHat CentOS
  elif [ -f /etc/redhat-release ] ; then
    #OS_NAME='RedHat'
    OS_NAME=`cat /etc/redhat-release | awk '{ print $1 }'`
    PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
    OS_VERSION=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
  elif [ -f /etc/SuSE-release ] ; then
    OS_NAME='openSUSE'
    #OS_NAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
    OS_VERSION=`cat /etc/SuSE-release | grep 'VERSION' | tr "\n" ' ' | sed s/.*=\ //`
  elif [ -f /etc/mandrake-release ] ; then
    OS_NAME='Mandrake'
    PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
    OS_VERSION=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
#  elif [ -f /etc/debian_version ] ; then
#    OS_NAME="Debian `cat /etc/debian_version`"
#    OS_VERSION=`cat /etc/issue | head -1 |awk '{ print $3 }'`
  elif [ -f /etc/slackware-version ]; then
    OS_NAME=`cat /etc/slackware-version | awk '{ print $1 }'`
    OS_VERSION=`cat /etc/slackware-version | awk '{ print $2 }'`
  elif [ -f /etc/gentoo-release ]; then
    OS_NAME=`cat /etc/os-release | grep "^NAME=" | awk -F= '{ print $2 }'`
    OS_VERSION=`cat /etc/gentoo-release`
  else
    #Debian
    OS_NAME=`cat /etc/issue| head -1 |awk '{ print $1 }'`
    OS_VERSION=`cat /etc/issue | head -1 |awk '{ print $3 }'`
  fi

  if [ -f /etc/UnitedLinux-release ] ; then
    OS_NAME="${OS_NAME}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
  fi

  if [ x"${OS_NAME}" = xUbuntu ]; then
    OS_VERSION=`cat /etc/issue|awk '{ print $2 }'`
  fi;
  #OSSTR="${OS} ${OS_NAME} ${OS_VERSION}(${PSUEDONAME} ${KERNEL} ${MACH})"
fi
}

#**********************************************************
#
#**********************************************************
_install () {

  for pkg in $@; do
    if [ "${OS_NAME}" = "CentOS" ]; then
      test_program="rpm -q"
      BUILD_OPTIONS=" yum -y install ";
    elif [ "${OS_NAME}" = "SHMZ" ]; then
      test_program="rpm -q"
      BUILD_OPTIONS=" yum -y install ";
    elif [ "${OS}" = "FreeBSD" ]; then
      test_program="pkg info"
      BUILD_OPTIONS="pkg install ";
    elif [ "${OS_NAME}" = "openSUSE"  ]; then
      test_program="zypper info"
      BUILD_OPTIONS="zypper install"
    else
      test_program="dpkg -s"
      BUILD_OPTIONS="apt-get -y --force-yes install";
    fi;

    ${test_program} ${pkg} > /dev/null 2>&1

    res=$?

    if [ ${res} = 1 ]; then
      ${BUILD_OPTIONS} ${pkg}
      echo "Pkg: ${BUILD_OPTIONS} ${pkg} ${res}";
    elif [ ${res} = 127 -o ${res} = 70 ]; then
      ${BUILD_OPTIONS} ${pkg}
      echo "Pkg: ${BUILD_OPTIONS} ${pkg} ${res}";
    else
      #echo -n "  ${pkg}"
      if [ "${res}" = 0 ]; then
        #echo " Installed";
        echo ""
      else
        echo " ${res}"
      fi;
    fi;

  done;
}


#**********************************************************
# fetch [output_file] [input_url]
#**********************************************************
_fetch () {

if [ "${OS}" = Linux ]; then
  FETCH="wget -q -O"
  MD5="md5sum"
else
  FETCH="fetch -q -o"
  MD5="md5"
fi;

if [ "${DEBUG}" != "" ]; then
  echo "${FETCH} $1 $2"
fi;

${FETCH} $1 $2

}

#**********************************************
# get sql access params
#**********************************************
sql_get_conf () {

  if [ ! -f ${BILLING_DIR}/libexec/config.pl ]; then
    return 0;
  fi;

  if [ "${DEBUG}" != "" ]; then
    echo "Get conf date";
  fi;

  DB_USER=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbuser}' |awk -F\' '{print $2}'`
  DB_PASSWD=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbpasswd}' |awk -F\' '{print $2}'`
  DB_NAME=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbname}' |awk -F\' '{print $2}'`
  DB_HOST=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbhost}' |awk -F\' '{print $2}'`
  DB_CHARSET=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbcharset}' |awk -F\' '{print $2}'`

  return 1;
}


#**********************************************************
# get sysid
#**********************************************************
get_sys_id() {
  sql_get_conf;
  SYS_ID=`${MYSQL} -s -N -u ${DB_USER} -p"${DB_PASSWD}" -h ${DB_HOST} -D ${DB_NAME} -e "SELECT value FROM config WHERE param='SYS_ID' LIMIT 1;" 2> /dev/null`
}

#**********************************************************
# make sys bench
#**********************************************************
mk_sysbench() {
  sys_id=$1

is_sysbench=`which sysbench`;

if [ "${is_sysbench}" = "" ]; then
  if [ "${OS}" = Linux ]; then
    if [ "${OS_NAME}" = "CentOS" ]; then
      _install epel-release
    fi;
    _install sysbench
  else
    cd /usr/ports/benchmarks/sysbench && make && make install clean
  fi;
fi;

test_file_size=5G
test_file_size=500M
echo "Making benchmark. Please wait..."

#CPU test
sysbench --test=cpu --cpu-max-prime=5000 --num-threads=1 run | egrep 'total time:' | sed 's/[ ^t]* total time: [ ^t]*//' > cpu.sysbench
sysbench --test=cpu --cpu-max-prime=5000 --num-threads=4 run | egrep 'total time:' | sed 's/[ ^t]* total time: [ ^t]*//' >> cpu.sysbench
#RAM test
sysbench --test=memory --memory-total-size=1G --memory-access-mode=rnd --memory-oper=write run | egrep 'total time:' | sed 's/[ ^t]* total time: [ ^t]*//' > memory.sysbench
sysbench --test=memory --memory-total-size=1G --memory-access-mode=rnd --memory-oper=read run | egrep 'total time:' | sed 's/[ ^t]* total time: [ ^t]*//' >> memory.sysbench
#HDD test
sysbench --test=fileio --file-total-size=${test_file_size} prepare
sysbench --test=fileio --file-total-size=${test_file_size} --file-test-mode=seqwr --max-time=0 run | egrep 'total time:' | sed 's/[ ^t]* total time: [ ^t]*//' > fileio.sysbench
sysbench --test=fileio --file-total-size=${test_file_size} --file-test-mode=seqrd --max-time=0 run | egrep 'total time:' | sed 's/[ ^t]* total time: [ ^t]*//' >> fileio.sysbench
sysbench --test=fileio --file-total-size=${test_file_size} cleanup

#sysbench --test=threads

CPU1=`cat cpu.sysbench | head -1`
CPU2=`cat cpu.sysbench | tail -1`
echo "CPU one thread  : ${CPU1}"
echo "CPU multi thread: ${CPU2}"

MEM1=`cat memory.sysbench | head -1`
MEM2=`cat memory.sysbench | tail -1`
echo "Memory write: ${MEM1}"
echo "Memory read : ${MEM2}"

FILE1=`cat fileio.sysbench | head -1`
FILE2=`cat fileio.sysbench | tail -1`
echo "Filesystem write: ${FILE1}"
echo "Filesystem read : ${FILE2}"

URL="http://axbills.net.ua/misc/update.php?bench=${sys_id}&CPU_ONE=${CPU1}&CPU_MULT=${CPU2}&MEM_WR=${MEM1}&MEM_RD=${MEM2}&FILE_WR=${FILE1}&FILE_RD=${FILE2}";
_fetch /tmp/bench ${URL}

if [ "${DEBUG}" != "" ] ; then
  rm *.sysbench
fi;

echo "bench=${sys_id}&CPU_ONE=${CPU1}&CPU_MULT=${CPU2}&MEM_WR=${MEM1}&MEM_RD=${MEM2}&FILE_WR=${FILE1}&FILE_RD=${FILE2}" > ${SYSBENCH_DIR}/.sysbench

#${DIALOG} --msgbox "Benchmark\n" 20  52

}

#**********************************************
# Sysinfo
#
#**********************************************
sys_info  () {

get_os

if [ "${OS}" = "FreeBSD" ]; then
  CPU=`grep -i CPU: /var/run/dmesg.boot | cut -d \: -f2 | tail -1`

  if [ "${CPU}" = "" ]; then
    CPU=`sysctl -a | egrep -i 'hw.machine|hw.model|hw.ncpu'`
    CPU=`sysctl hw.model | sed "s/hw.model: //g"`;
  fi;

  VGA_device=`pciconf -lv |grep -B 3 VGA |grep device |awk -F \' '{print $2}' |paste -s -`
  VGA_vendor=`pciconf -lv |grep -B 3 VGA |grep vendor |awk -F \' '{print $2}' |paste -s -`

  ntf=`grep -i Network /var/run/dmesg.boot |cut -d \: -f1`
  RAM=`grep -i "real memory" /var/run/dmesg.boot | sed 's/.*(\([0-9]*\) MB)/\1/' | tail -1`
  if [ "${RAM}" = "" ]; then
    RAM=`sysctl hw.physmem | awk '{ print \$2 "/ 1048576" }' | bc`;
  fi;

  HDD=`grep -i ^ad[0-9]: /var/run/dmesg.boot | tail -1`
  if [ "${HDD}" = "" ]; then
    HDD=`grep -i ^ada[0-9]: /var/run/dmesg.boot | tail -1`
  fi;

  hdd_model=${HDD}
  hdd_serial=`echo ${HDD} | sed 's/.*<\(.*\)>.*/\1/g'`
  hdd_size=`echo ${HDD} | awk '{ print $2 }'`

  Version=`uname -r`
  INTERFACES=`ifconfig | grep "[a-z0-9]: f" | awk '{ print $1 }' | grep -v -E "ng*|vlan*|lo*|ppp*|ipfw*"`;

  #interface () {
  #  for eth in $(grep -i Network /var/run/dmesg.boot |cut -d \: -f1 |paste -s -); do
  #    eth1=`grep -i Network /var/run/dmesg.boot |grep $eth |awk -F "<" '{print $2}'|awk -F ">" '{print $1}'`
  #    eth2=`pciconf -lv |grep -A 2 $eth |grep -v $eth |awk -F "\'" \'{print $2}\' |paste -s -`
  #
  #    INTERFACES="$eth on $eth1
  #                      $eth2"
  #  done;
  #}
elif [ x"${OS}" = xLinux ]; then
   #CPU=`grep -i  "MHz proc" /var/log/dmesg |awk '{print $2, $3}'`
   # Model and current speed
   #CPU=`cat /proc/cpuinfo |egrep '(model name|cpu MHz)' | sed 's/.*\: //'|paste -s`
   CPU_COUNT=" ("`expr \`cat /proc/cpuinfo | grep '^processor' | tail -1 | sed 's/.*\: //'\` + 1`")";
   CPU=`cat /proc/cpuinfo |egrep '(model name)' | tail -1 |sed 's/.*\: //'|paste -s`

   _install pciutils bc

   INTERFACES=`lspci -mm |grep Ethernet |cut -f4- -d " "`
   RAM=`free -m |grep Mem |awk '{print $2}'`
   VGA=`lspci |grep VGA |cut -f5- -d " "`
   hdd_size=`fdisk -l |head -2 |tail -1|awk '{print $3,$4}'|sed 's/,//'`
   #Serial number
   # smartctl -a /dev/sdb
   hdd_system_name=`fdisk -l | head -2 | tail -1 |awk '{ print $2 }' | sed 's/://'`

   udevadm_program=`which udevadm`;

   if [ "${udevadm_program}" != "" ]; then
     hdd_model=`udevadm info --query=all --name=${hdd_system_name} | grep ID_MODEL= | cut -d '=' -f 2`
     hdd_model=${hdd_model:-Virtual_Disk} # Virtual Disks don't have the property
     hdd_serial=`udevadm info --query=all --name=${hdd_system_name} | grep ID_SERIAL= | cut -d '=' -f 2`
   else
     _install hdparm
     hdd_model=`hdparm -I ${hdd_system_name} |grep Model |awk -F ":" '{print $2}' |tr -cs -`
     hdd_serial=`hdparm -I ${hdd_system_name} |grep Serial |awk -F ":" '{print $2}' |tr -cs -`
   fi;

fi;

sys_info="${CPU}${CPU_COUNT}^${RAM}^${VGA}^${hdd_model}^${hdd_serial}^${hdd_size}^${OS}^${OS_VERSION}^${OS_NAME}^${INTERFACES}"

#echo "${sys_info}";

CHECKSUM=`echo "${sys_info}" | ${MD5} | awk '{print $1 }'`
get_sys_id

if [ "${REGISTRATION}" != "" ]; then
  echo "Please enter login and password for server registration"
  echo -n "Login: "
  read LOGIN
  echo -n "Password: "
  read PASSWORD
  MYHOSTNAME=`hostname`
  sys_info=`echo ${sys_info} | sed 's/\"//g'`;

  REG_URL="${UPDATE_URL}?""SIGN=${CHECKSUM}&L=${LOGIN}&P=${PASSWORD}&H=${MYHOSTNAME}&SYS_ID=${SYS_ID}&sys_info=${sys_info}"

  if [ "${DEBUG}" != "" ]; then
    echo ${REG_URL};
  fi;

  _fetch ${TMP_DIR}/update.sh ${REG_URL};
  VAR=`cat ${TMP_DIR}/update.sh;`

  echo ${VAR};
  rm -rf ~/.updater

  RESULT=`echo "${VAR}" | grep comple`;
  if [ x"${RESULT}" != x ]; then
    REGISTRATION=""
    echo ${CHECKSUM} > ~/.updater
    if [ -d "${BILLING_DIR}/libexec/" ]; then
      echo ${CHECKSUM} > ${BILLING_DIR}/libexec/.updater
    fi;
  else
    echo "Registration failed"
    exit;
  fi;

  return 0;
fi;


SYSTEM_INFO="System information
  CPU    -    ${CPU} ${CPU_COUNT}
  RAM    -    ${RAM} Mb
  VGA    -    ${VGA}
              manufacture: ${VGA_vendor}
              model: ${VGA_device}

  HDD    -    Model:  ${hdd_model}
              Serial: ${hdd_serial}
              Size:   ${hdd_size}
  INTERFACES   - ${INTERFACES}
  OS           - ${OS}
  Version      - ${OS_VERSION}
  Distributive - ${OS_NAME}
  CHECKSUM     - ${CHECKSUM}
"

  if [ "${SYS_INFO}" != "" -o ! -f "${SYSBENCH_DIR}/.sysbench" ] ; then
    echo "${SYSTEM_INFO}"
    mk_sysbench ${CHECKSUM};
  fi;

  UPDATE_CHECKSUM=${CHECKSUM}
}


#**********************************************
# Update self
#
#**********************************************
update_self () {

  if [ "${FREE_UPDATE}" != "" ]; then
    echo "update.sh check skip";
    return;
  fi;

  sys_info
  get_sys_id
  SIGN=${UPDATE_CHECKSUM}
  echo "Verifing please wait..."

  if [ -f ~/.updater ]; then
    SIGN=`cat ~/.updater`"&hn="`hostname`;
  else
    echo ${SIGN} > ~/.updater
    chmod 400 ~/.updater
    SIGN=${SIGN}"&hn="`hostname`;
  fi;

  URL="${UPDATE_URL}?sign=${SIGN}&getupdate=1&VERSION=${VERSION}&SYS_ID=${SYS_ID}";
  _fetch ${TMP_DIR}/update.sh "${URL}";

  if [ "${DEBUG}" != "" ]; then
    echo "${URL}";
  fi;

if [ -f "${TMP_DIR}/update.sh" ]; then
  RESULT=`grep "^ERROR:" ${TMP_DIR}/update.sh`;

  if [ "${RESULT}" != "" ] ; then
    echo "Please Registration:"
    REGISTRATION=1;
    sys_info;
  else
    NEW=`cat ${TMP_DIR}/update.sh |grep "^VERSION=" | sed  "s/VERSION=\([0-9\.]*\);\?/\1/"`;
    VERSION_NEW=0
    if [ x${NEW} != x ]; then
      VERSION_NEW=`echo "${NEW} * 100" |bc |cut -f1 -d "."`;
    fi;

    VERSION_OLD=`echo "${VERSION} * 100" | bc |cut -f1 -d "."`;

    if [ "${VERSION_OLD}" -lt "${VERSION_NEW}" ] > /dev/null 2>&1; then
      echo " "
      echo -n "!!! New version '${NEW}' of update.sh available update it [Y/n]: "

      read update_confirm

      if [ "${update_confirm}" != n ]; then

        #CUR_FILE=`pwd`"/update.sh"
        cp ${TMP_DIR}/update.sh ${CUR_FILE}
        echo "update.sh updated. Please restart program";
        exit;
      fi;
    fi;

  fi;
fi;

}

#**********************************************
# Check current installed MySQL version
#
#**********************************************
check_mysql_version () {
  sql_get_conf

  if [ "${DB_NAME}" = "" ]; then
    return 0;
  fi;

  EXIST_MYSQL=`which ${MYSQL}`;

  if [ "${EXIST_MYSQL}" = "" ]; then
    echo "Mysql client '${MYSQL}' not exist";
    return 0;
  fi;

  if [ "${SKIP_CHECK_SQL}" != 1 ]; then
    #Check MySQL Version
    MYSQL_VERSION=`${MYSQL} -N -u ${DB_USER} -p"${DB_PASSWD}" -h ${DB_HOST} -D ${DB_NAME} -e "SELECT version()"`
    echo "MySQL: Version: ${MYSQL_VERSION}"

    MYSQL_VERSION=`echo ${MYSQL_VERSION} | sed 's/\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*/\1\2/'`;

    if [ "${MYSQL_VERSION}" = "" ]; then
      MYSQL_VERSION=0;
    fi;

    if [ "${MYSQL_VERSION}" -lt 56 ]; then
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "! Please Update Mysql Server to version 5.6 or higher                        !"
      echo "! More information http://axbills.net.ua/forum/viewtopic.php?f=1&t=6951       !"
      echo "! use -skip_check_sql                                                        !"
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      exit;
    fi;
  fi;
}

#**********************************************
# Retrieve current billing version
#
#**********************************************
get_current_version () {

  if [ -f ${BILLING_DIR}/libexec/config.pl ]; then
    UPDATE_DATE=`cat ${BILLING_DIR}/libexec/config.pl |grep version |cut -f2 -d "/" |cut -f1 -d "'"`
    if [ "${UPDATE_DATE}" = "" ]; then
      UPDATE_DATE=0;
    fi;
  else
    UPDATE_DATE=0;
  fi;

  if [ -f ${BILLING_DIR}/libexec/config.pl -a -f ${BILLING_DIR}/VERSION ]; then
    UPDATE_VERSION=`cat ${BILLING_DIR}/VERSION | awk '{ print $1 }' | cut -c1-3`
    UPDATE_DATE=`cat ${BILLING_DIR}/VERSION | awk '{ print $2 }'`
    GIT_UPDATE=1;

    if [ ${UPDATE_VERSION} = "0.8" ];
        then
          CHANGELOG_URL="http://axbills.net.ua/wiki/doku.php?id=axbills:changelogs:0.8x&do=export_raw"
        else
          CHANGELOG_URL="http://axbills.net.ua/wiki/doku.php?id=axbills:changelogs:0.7x&do=export_raw"
    fi;
  else
    if [ "${UPDATE_DATE}" = '$conf{version}='  ]; then
      UPDATE_DATE=99999999
    fi;
  
    CHANGELOG_URL="http://axbills.net.ua/wiki/doku.php?id=axbills:changelogs:0.5x&do=export_raw"
  fi;
  
  if [ "${UPDATE_DATE}" = "" ]; then
    UPDATE_DATE=0;
  fi;

  echo "${UPDATE_DATE}"

}

#**********************************************
# Downloads and parses changelog from ${CHANGELOG_URL}
#
#**********************************************
download_and_parse_sql_updates () {

  echo "Downloading MySQL changelog file"

  _fetch "${TMP_DIR}/changes" "${CHANGELOG_URL}";

  cat ${TMP_DIR}/changes |sed -n '/^[0-9]/p' |sed 's/\\\\//' |sed 's/\([0-9]*\).\([0-9]*\).\([0-9]*\)/\3\2\1/' > ${TMP_DIR}/dates;

  # Clear previous changes
  rm -f ${TMP_DIR}/changes.sql

  END_RE="<\/code><\/panel><\/accordion>";
  for data in $(cat ${TMP_DIR}/dates); do
    if [ ${UPDATE_DATE} -le ${data} ]; then
      
      START_RE="<accordion title=\"$data\"><panel title=\"MySQL\"><code mysql>";
      UPDATE_SQL=`sed -n "/${START_RE}/,/${END_RE}/p" ${TMP_DIR}/changes | grep -v '^<'`;
    
      if [ "${UPDATE_SQL}" ]; then
        if [ ${OS_NAME} = "FreeBSD" ]; then
            echo ${UPDATE_SQL} | sed $'s/;/;\\\n/g' >> ${TMP_DIR}/changes.sql
        else
            echo ${UPDATE_SQL} | sed 's/;/;\n/g' >> ${TMP_DIR}/changes.sql
        fi
      fi
      
    fi;
  done

  rm -f ${TMP_DIR}/dates ${TMP_DIR}/changes;

}

#**********************************************
# Update SQL Section
#
#**********************************************
update_sql () {

  check_mysql_version
  get_current_version
  
  echo "Last update date : ${UPDATE_DATE}"

  if [ "${UPDATE_DATE}" -lt 99999999 ]; then
    echo "Updating SQL"

    download_and_parse_sql_updates

    if [ -f "${TMP_DIR}/changes.sql" ]; then

      if [ x"${DB_CHARSET}" != x ]; then
        DB_CHARSET="--default-character-set=${DB_CHARSET}"
      fi;

      while IFS=';' read line ; do
        ${MYSQL} -u "${DB_USER}" -p"${DB_PASSWD}" -h ${DB_HOST} ${DB_CHARSET} -D ${DB_NAME} -Bse "$line"
      done < ${TMP_DIR}/changes.sql

      echo "SQL Updated"
      echo " "
    else
      echo " "
      echo "Your DB is up to date"
      echo " "
    fi

  fi;

  #Add sysid
}


#**********************************************
# Restart system servers radius
#**********************************************
restart_servers () {

 #Freebsd radius Restart
 if [ -x /usr/local/etc/rc.d/radiusd ]; then
   /usr/local/etc/rc.d/radiusd restart
   echo "RADIUS restarted"
  #Ubuntu radius restart
 elif [ -x /etc/init.d/freeradius  ]; then
   /etc/init.d/freeradius restart
   echo "RADIUS restarted"
 #RHEL radius restart
 elif [ -f /etc/redhat-release ]; then
   RHVER=$(grep -o '[0-9]' /etc/redhat-release | head -n 1)
   if (( $RHVER < 7 )); then
     service radiusd restart
   else
     systemctl restart radiusd.service
   fi
   echo "RADIUS restarted"
 fi;

}

#**********************************************
#
#**********************************************
sql_innodb_optimize () {
  sql_get_conf

#  if [ "${get_conf}" = 1 ]; then
#    return 0;
#  fi;

  echo "Optimize innodb: ${DB_NAME}"

  TABLES=`${MYSQL} -N -h "${DB_HOST}" -u "${DB_USER}" --password="${DB_PASSWD}" -D "${DB_NAME}" -e "SHOW TABLES;"`
  
  for table in ${TABLES} ; do
    TYPE=`${MYSQL} -h "${DB_HOST}" -u "${DB_USER}" --password="${DB_PASSWD}" -D ${DB_NAME} -e "OPTIMIZE TABLE ${table};"`
    echo "${table} optimized"
  done;
}

#**********************************************
#
#**********************************************
download_module () {

MODULE=$1;
echo "Automatically module update";

URL="http://axbills.net.ua/misc/update.php?sign=${SIGN}&SYS_ID=${SYS_ID}&module=${MODULE}";
_fetch "${TMP_DIR}/module" "${URL}"

CHECK_MODULE=`grep ${MODULE} ${TMP_DIR}/module`;

if [ "${CHECK_MODULE}" != "" ]; then
  echo "Module ${MODULE} Downloading"

  GET_MODULE_VERSION=`grep VERSION /tmp/module`;

  echo "${MODULE} ${GET_MODULE_VERSION}"

  cp "${TMP_DIR}/module" "${TMP_DIR}/${MODULE}.pm"

  if [ -f "${BILLING_DIR}/AXbills/mysql/${MODULE}.pm" ]; then
    cp "${BILLING_DIR}/AXbills/mysql/${MODULE}.pm" "${BILLING_DIR}/AXbills/mysql/${MODULE}.pm_${DATE}"
  fi;

  cp "${TMP_DIR}/${MODULE}.pm" "${BILLING_DIR}/AXbills/mysql/"
fi;

  echo "Updated: ${MODULE}";
}

#**********************************************
# Check modules version for update
#
# Paysys.pm
# Ashield.pm
# Storage.pm
# Maps.pm
# Cablecat.pm
# Ureports.pm
#**********************************************
check_modules () {

CHECKDIR=${BILLING_DIR};

if [ "$1" = "PRE_CHECK" ]; then
  PRE_CHECK=1;
  CHECKDIR="${TMP_DIR}/axbills/";
  echo "Pre check modules";
fi;

IS_NEW=""

for module_name in Paysys Turbo Maps2 Storage Ureports Cablecat Callcenter; do
  DB_MODULE=${module_name}
  if [ "${DB_MODULE}" = "Maps2" ]; then
    DB_MODULE=Maps
  fi;

  if [ -e "${BILLING_DIR}/AXbills/mysql/${DB_MODULE}.pm" -a -f "${CHECKDIR}/AXbills/modules/${module_name}/webinterface" ]; then

    OLD=`cat ${BILLING_DIR}/AXbills/mysql/${DB_MODULE}.pm |grep ' VERSION' | sed 's/^[^0-9]*//;1d;s/;$//'`;
    #Old style
    #NEW=`cat ${BILLING_DIR}/AXbills/modules/${module_name}/webinterface |grep \$VERSION |sed 's/^[^0-9]*//;s/[^0-9]*$//'`

    NEW=`cat ${CHECKDIR}/AXbills/modules/${module_name}/webinterface |grep REQUIRE_VERSION |sed 's/^[^0-9]*//;s/[^0-9]*$//' | head -1`

    if [ "${NEW}" = "" ]; then
      NEW=0
    fi;

    y=`echo "${NEW} * 100" |bc |cut -f1 -d "."`;

    OLD=`echo ${OLD} | tr -d '\b\r;'`
    if [ "${OLD}" = "" ]; then
      OLD=0
    fi;
    x=`echo "${OLD} * 100" |bc |cut -f1 -d "."`;
    
    if [ ${x} -lt ${y} ] > /dev/null 2>&1; then
      echo " "
      echo "!!! PLEASE UPDATE MODULE ${DB_MODULE} (current: ${OLD} required: ${NEW}) "
      echo " New version you can download from support system: https://support.axbills.net.ua/"

      DOWNLOAD_COM_MODULES=1;
      if [ "${DOWNLOAD_COM_MODULES}" != "" ]; then
        download_module "${DB_MODULE}"
      else
        IS_NEW=1
      fi;
    fi;
  fi;
done


if [ "${PRE_CHECK}" = 1 -a "${IS_NEW}" = 1 ]; then

  echo "Require new modules. continue update [Y/n]: ";
  read COUNTINUE

  echo "Require new modules. Update automaticly [Y/n]: ";
  read COUNTINUE

  if [ "${COUNTINUE}" ne 'n' ]; then
    download_module "${module_name}";
  fi;

  PRE_CHECK=""

  if [ "${COUNTINUE}" = "n" ]; then
    echo "Update canceled";
    exit;
  fi;
fi;

}


#**********************************************
# Check files and permisions
#**********************************************
check_files () {

SYMFILE=paysys_check.cgi
REALFILE=../AXbills/modules/Paysys/paysys_check.cgi
CGIBINDIR=${BILLING_DIR}/cgi-bin/

cd ${CGIBINDIR}

if [ -L ${SYMFILE} ]; then
  echo "Symlink file ${SYMFILE} OK"
else
  if [ -f ${SYMFILE} ]; then cp -f ${SYMFILE} ${SYMFILE}.bak; fi;
  ln -fs ${REALFILE} ${SYMFILE}
  echo "Ordinary file ${SYMFILE} replaced by symlink"
fi;

# remove
if [ -f "${BILLING_DIR}/AXbills/HTML.pm" ]; then
  echo "Remove pre 0.74.xx files";
  rm ${BILLING_DIR}/AXbills/*.pm
  rm -rf ${BILLING_DIR}/Nas
  rm -rf ${BILLING_DIR}/Sender
fi;

if [ -f "${BILLING_DIR}/cgi-bin/graphics.cgi" ]; then
  echo "Remove graphics";
  rm ${BILLING_DIR}/cgi-bin/graphics.cgi
fi;


chmod 777 ${BILLING_DIR}/var/log/
touch ${BILLING_DIR}/var/log/sql_errors
chmod 777 ${BILLING_DIR}/var/log/sql_errors

}

#**********************************************
# Check free space
#
#**********************************************
check_free_space () {

if [ -d ${BILLING_DIR} ]; then
  axbills_size=`du -s ${BILLING_DIR} |awk '{print $1}'`
else
  axbills_size=0
fi;

ext_free_space=`expr ${axbills_size} + 100000`

if [ x${OS} = xLinux ]; then
  free_size=`df /usr | awk '{print $3}' |tail -1`
else
  free_size=`df /usr | awk '{print $4}' |tail -1`
fi;

if [ "${free_size}" -le "${ext_free_space}" ]; then
  echo " "
  echo !!! YOU HAVE NOT ENOUGH FREE SPACE ON /usr \( you have `df -h /usr | awk '{print $4}' |tail -1`, axbills is `du -hs ${BILLING_DIR}` \)
  echo " "
  exit;
fi

}


#**********************************************
#
#**********************************************
beep () {
  for i in 3 2 1; do
    echo -e '\a\a';
    echo -n " Start update $i";
    sleep 1;
  done;
}

#**********************************************
# Help
#**********************************************
usage () {
  echo "ABillS Updater Help";
  echo " Version ${VERSION}";
  
  echo "
  -rollback [DATE]  - Rollback
  -win2utf          - Convert to UTF
  -amon             - Make AMon Checksum
  -full             - Make full Source update
  -speedy           - Replace perl to speedy
  -myisam2inodb     - Convert MyISAM table to InoDB
  -sql_optimize     - Innodb optimize
  -skip_tables      - Skip tables in converting
  -h,help,-help     - Help
  -debug            - Debug mode
  -clean            - Clean tmp files
  -v                - show version
  -b                - Branch name
  -prefix           - Prefix DIR
  -tmp              - Change tmp dir (Default: /tmp)
  -skip_backup      - Skip current system backup
  -skip_sql_update  - Skip SQL update
  -skip_perl_check  - SKip check perl
  -gs               - Update from snapshot system (Alternative way)
  -skip_update      - Skip check new version of update.sh
  -check_modules    - Check new version of modules
  -dl               - Update license key
  -skip_check_sql   - Skip check mysql version
  -m [MODULE]       - Update only modules
"
}


#**********************************************
# Convert MyISAM table to InoDB
#
#**********************************************
convert2inodb () {
  echo -n "DB host [localhost]: ";
  read db_host
  
  if [ "${db_host}" = "" ]; then
    db_host="localhost"
  fi;
  
  echo -n "DB user [root]: ";
  read db_user

  if [ "${db_user}" = "" ]; then
    db_user="root"
  fi;

  echo -n "DB password: ";
  read db_password

  echo -n "DB name [axbills]: ";
  read db_name

  if [ "${db_name}" = "" ]; then
    db_name="axbills"
  fi;

  if [ w${DEBUG} != w ]; then
    echo "db_host: ${db_host}";
    echo "db_user: ${db_user}";
    echo "db_password: ${db_password}";
    echo "db_name: ${db_name}";
  fi;
  
  TABLES=`${MYSQL} -N -h "${db_host}" -u "${db_user}" --password="${db_password}" -D ${db_name} -e "SHOW TABLES;"`
  SKIP_TABLES=`echo ${SKIP_TABLES} | sed 's/\%/\.\*/g'`
  
  echo "SKIP_TABLES: ${SKIP_TABLES}"
  
  for table in ${TABLES} ; do
    TYPE=`${MYSQL} -N -h "${db_host}" -u "${db_user}" --password="${db_password}" -D ${db_name} -e "SHOW TABLE STATUS LIKE '${table}';" | tail -1 | awk '{ print \$2 }'`
    IGNORE=""
    
    if [ "${TYPE}" = "InnoDB" ]; then
      echo " ${table} (${TYPE}) Already converted"
      IGNORE=1;
    fi;
  
    for IGNORE_TABLE in ${SKIP_TABLES}; do
      if [ "${table}" = "${IGNORE_TABLE}" ]; then
        IGNORE=1
      else
        RESULT=`echo ${table} | sed "s/${IGNORE_TABLE}/y/"`;
        if [ "${RESULT}" = "y" ]; then
          IGNORE=1
        fi;
      fi;
    done
  
    if [ "${IGNORE}" = "" ]; then
      echo "Start convert: ${table}"
      query="ALTER TABLE ${table} ENGINE=InnoDB;";
      res=`mysql -h "${db_host}" -u "${db_user}" --password="${db_password}" -D ${db_name} -e "${query};"`
      echo "${table} ${res}"
      if [ "${DEBUG}" != "" ]; then
        echo ${query};
      fi;
    else
      echo "Ignore"
    fi;
  done;

}

#**********************************************
# Convert to UTF
#**********************************************
convert2utf () {
  ICONV="iconv";
  #BASE_CHARSET="cp1251";
  #OUTPUT_CHARSET="utf8";
  BASE_CHARSET="CP1251";
  OUTPUT_CHARSET="UTF-8";
    
  if [ w${OS} = wLinux ]; then
    COMMAND='iconv -f CP1251 -t UTF-8 {} -o {}.bak';
  else
    COMMAND='cat {} | iconv -f CP1251 -t UTF-8 > {}.bak';
  fi;

  action=$1;

  #Convert lang files
#  ${FIND} ${BILLING_DIR}/language -name "*.pl" -type f -exec ${ICONV}  -f ${BASE_CHARSET} -t ${OUTPUT_CHARSET} {} -o {}.bak `mv {}.bak {}` \;
  echo "Change lang file charset"
  for file in `ls ${BILLING_DIR}/language/*.pl` ${BILLING_DIR}/libexec/config.pl; do
    if [ w${OS} = wLinux ]; then
      ${ICONV}  -f ${BASE_CHARSET} -t ${OUTPUT_CHARSET} ${file} -o ${file}.bak
    else
      cat ${file} | ${ICONV}  -f ${BASE_CHARSET} -t ${OUTPUT_CHARSET} > ${file}.bak
    fi;

    mv ${file}.bak ${file}
    sed "s/CHARSET='.*';/CHARSET='utf-8';/" ${file} > ${file}.bak
    mv ${file}.bak ${file}
    if [ x${DEBUG} != x ]; then
      echo ${file}
    fi;
  done
  
  echo "Convert modules lang files"
  ${FIND} ${BILLING_DIR} -name "lng*.pl" -type f -exec sh -c "${COMMAND}; mv {}.bak {}" \;

  echo "Conver template describe files"
  ${FIND} ${BILLING_DIR} -name "describe.tpls" -type f -exec sh -c "${COMMAND}; mv {}.bak {}" \;
  ${FIND} ${BILLING_DIR}/AXbills/ -name "*.tpl" -type f -exec sh -c "${COMMAND}; mv {}.bak {}" \;
  #cat {} | ${ICONV} -f ${BASE_CHARSET} -t ${OUTPUT_CHARSET} > {}.bak `mv {}.bak {}` \;

  if [ w${action} = wupdate ]; then
    echo "Converted to UTF8";
  else
    echo "Dictionary convertation finishing...";
    echo "Add to ${BILLING_DIR}/libexec/config.pl"
    echo ""
    echo "\$conf{dbcharset}='utf8';"
    echo "\$conf{MAIL_CHARSET}='utf-8';"
    echo "\$conf{default_language}='russian';"
    echo "\$conf{default_charset}='utf-8';"
  fi;
}


#**********************************************
# amon
#**********************************************
amon () {
  echo "**********************************************************"
  echo "# ABillS AMon Update                                     #"
  echo "**********************************************************"
  FILENAME=${AMON_FILE};

  md5 ${FILENAME}
}


#**********************************************
# Speedy
#**********************************************
speedy () {
   SPEEDY="/usr/local/bin/speedy"
   SPEEDY_ARGS=" -- -r1";
   if [ ! -f ${SPEEDY} ]; then
     echo "speedy '${SPEEDY}' not found in system";
     exit;
   fi;

   #${FIND} ${BILLING_DIR} -type f -exec ${SED} -i '' -e "s,/usr/bin/perl,${SPEEDY},g" {} \;

   ${SED} -i '' -e "s,/usr/bin/perl,${SPEEDY}${SPEEDY_ARGS},g" "${BILLING_DIR}/cgi-bin/index.cgi"
   echo "Speedy Applied"
}

#**********************************************
# snapshot_update
#**********************************************
snapshot_update () {

  echo
  echo "**********************************************************"
  echo "# ABillS snapshot Update                                  #"
  echo "**********************************************************"


SNAPHOT_NAME=axbills_.tgz
UPDATED=updated.txt

URL="${UPDATE_URL}?sign=${SIGN}&get_snapshot=1&SYS_ID=${SYS_ID}&H=${MYHOSTNAME}";

cd ${TMP_DIR}

_fetch ${SNAPHOT_NAME} "${URL}";

RESULT=`head -1 ${SNAPHOT_NAME} | grep '\['`

if [ "${RESULT}" != "" ]; then
  echo "${RESULT}";
fi;

tar zxvf ${TMP_DIR}/${SNAPHOT_NAME} -C ${TMP_DIR}
}


#**********************************************
# git_update
#**********************************************
git_update () {
  echo "Git Update";
  GIT=`which git`
  
  if [ "${GIT}" = "" ]; then
    echo "Install GIT"
    echo -n "Make autoinstall [Y/n]: ";
    read AUTOINSTALL
    if [ "${AUTOINSTALL}" != n ]; then
    	_install git

      GIT=`which git`
    fi;

    if [ "${GIT}" = "" ]; then
      echo "Git not installed ";
      exit;
    fi;
  fi;

  if [ ! -d ~/.ssh ]; then
    mkdir ~/.ssh
    chmod 600 ~/.ssh
  fi;

  if [ "${KEY_DIR}" != "" ]; then
    start_dir=${KEY_DIR};
  fi;

  #SEARCH_KEY=`ls ${start_dir}/id_rsa.* | head -1;`
  #BASEDIR=$(dirname $0)
  #echo "Found key: ${SEARCH_KEY} (${BASEDIR} ${KEY_DIR})";
  SEARCH_KEY=`ls ${start_dir}/id_rsa.* 2> /dev/null | head -1;`

  if [ "${SEARCH_KEY}" != "" ]; then
    DEFAULT_AUTH_KEY=${SEARCH_KEY};
    BASEDIR=$(dirname $0)
    echo "Found key: ${SEARCH_KEY} (${BASEDIR} ${KEY_DIR})";
  fi;

  if [ ! -f ~/.ssh/config ]; then
    echo "Please install auth key"
    echo -n "If you have auth key hit yes [y/n]:"
    read AUTH_KEY_PRESENT;
    if [ "${AUTH_KEY_PRESENT}" != n ]; then
      echo -n "Enter path to auth key[${DEFAULT_AUTH_KEY}]: ";
      read AUTH_KEY

      if [ "${AUTH_KEY}" = "" ]; then
        AUTH_KEY=${DEFAULT_AUTH_KEY};
      fi;

      #DEFAULT_AUTH_USER=`echo "${AUTH_KEY}" | awk -F\. '{print $2}'`
      DEFAULT_AUTH_USER=`echo "${AUTH_KEY}" | sed  's/^[a-z\_\/]*\.//'`

      echo -n "Enter auth login [${DEFAULT_AUTH_USER}]: ";
      read AUTH_USER
      
      if [ "${AUTH_USER}" = "" ]; then
        AUTH_USER=${DEFAULT_AUTH_USER};
      fi;
      
      if [ -f "${AUTH_KEY}" ]; then
        echo "${AUTH_KEY} ~/.ssh/id_dsa.${AUTH_USER}"
        cp "${AUTH_KEY}" ~/.ssh/id_dsa.${AUTH_USER}
        chmod 400 ~/.ssh/id_dsa.${AUTH_USER}
        echo "Host axbills.net.ua
         User ${AUTH_USER}
         Hostname axbills.net.ua
         IdentityFile ~/.ssh/id_dsa.${AUTH_USER}" >> ~/.ssh/config
      else
        echo "Wrong key '${AUTH_KEY}' ";
        exit;
      fi;
    fi;
    
  else
    CHECK_KEY=`grep axbills.net.ua ~/.ssh/config`;
    if [ "${CHECK_KEY}" = "" ]; then
      echo "You don\'t have update key"
      echo "Contact ABillS Suppot Team"
      exit;
    fi;
  fi;


  if [ -d "${TMP_DIR}/axbills" ]; then
    CHECK_CVS=`find ${TMP_DIR}/axbills | grep CVS`
    if [ "${CHECK_CVS}" != "" ]; then
      rm -rf ${TMP_DIR}/axbills*;
    fi;
  fi;

  if [ -d "${TMP_DIR}/axbills" ]; then
    if [ "${BRANCH_NAME}" != "" ]; then
      BRANCH=" origin ${BRANCH_NAME} "
    fi;
    cd ${TMP_DIR}/axbills
    ${GIT} pull ${BRANCH}
    cd ..
  else
    if [ "${BRANCH_NAME}" != "" ]; then
      BRANCH=" -b ${BRANCH_NAME} "
    fi;
    #Git repository
    ${GIT} clone ${BRANCH} ssh://git@axbills.net.ua:22/axbills.git
  fi;
}

#**********************************************
# free_update
#**********************************************
free_update () {

  echo
  echo "**********************************************************"
  echo "# ABillS Update Free version                             #"
  echo "**********************************************************"

  cd ${TMP_DIR}
  SNAPHOT_NAME=axbills_.tgz
  URL=https://netix.dl.sourceforge.net/project/axbills/axbills/0.81/axbills-0.81.16.tgz

  _fetch ${SNAPHOT_NAME} "${URL}";

  tar zxvf ${TMP_DIR}/${SNAPHOT_NAME} -C ${TMP_DIR}
}


#**********************************************
# Speedy
#**********************************************
rollback () {

  echo "Rollback last backup"

  if [ "${ROLLBACK}" != "" ]; then
    cp -rfp /usr/axbills_${ROLLBACK}/* ${BILLING_DIR}/
    echo "Rollback to '${ROLLBACK}'"
    exit
  fi;

  for backup_dirs in * ; do
     echo ${backup_dirs}
  done;
}

#**********************************************
# get_license
#**********************************************
get_license () {

  if [ "${SYS_ID}" != "" ]; then
    get_sys_id;
  fi;

  if [ -d "${TMP_DIR}/axbills/libexec/" ]; then
    if [ -f ${TMP_DIR}/axbills/libexec/license.key ]; then
      rm -f ${TMP_DIR}/axbills/libexec/license.key
    fi;
    _fetch ${TMP_DIR}/axbills/libexec/license.key "${UPDATE_URL}?sign=${SIGN}&H=${MYHOSTNAME}&getupdate=1&VERSION=${VERSION}&get_key=1&SYS_ID=${SYS_ID}";
    cp "${TMP_DIR}/axbills/libexec/license.key" "${BILLING_DIR}/libexec/license.key"
  elif [ -f "${BILLING_DIR}/libexec/license.key" ]; then
     cp "${BILLING_DIR}/libexec/license.key" "${BILLING_DIR}/libexec/license.key.old"
     rm "${BILLING_DIR}/libexec/license.key"
     _fetch ${BILLING_DIR}/libexec/license.key "${UPDATE_URL}?sign=${SIGN}&H=${MYHOSTNAME}&getupdate=1&VERSION=${VERSION}&get_key=1&SYS_ID=${SYS_ID}";
  fi;

  echo "License downloaded";
}

#**********************************************
# Start actions
#

get_os

echo "OS: ${OS} (${OS_NAME} ${OS_VERSION})"

if [ "${OS}" = Linux ]; then
  FETCH="wget -q -O"
  MD5="md5sum"
else
  FETCH="fetch -q -o"
  MD5="md5"
fi;

# Proccess command-line options
#
for _switch; do
        case ${_switch} in
        -b)     BRANCH_NAME=$2;
                echo "BRANCH_NAME: ${BRANCH_NAME}"
                shift; shift;
                ;;
#        -fu)    FILE_UPDATE=1
#                echo "File update";
#                shift;
#                ;;
        -debug)
                DEBUG=1;
                echo "Debug enable"
                shift;
                ;;
        -v)
                echo "Version: ${VERSION}";
                exit;
                ;;
        -amon)
                AMON_FILE=$1;
                shift; shift
                ;;
        -key)   KEY_DIR=$2;
                shift; shift
                ;;
        -full)  FULL=1;
                shift; 
                ;;
        -speedy) SPEEDY=1;
                shift; shift
                ;;
        -h)     HELP=1;
                ;;
        -help)  HELP=1;
                ;;
        help)   HELP=1;
                ;;
        -clean) CLEAN=1;
                shift
                ;;
        -rollback) ROLLBACK=$1
                shift; shift
                ;;
        -prefix) BILLING_DIR=$2
                shift; shift
                ;;
        -win2utf) CONVERT2UTF=1
                shift;
                ;;
        -tmp)   TMP_DIR=$2
                shift; shift
                ;;
        -myisam2inodb) INODB=1;
                shift;
                ;;
        -skip_tables) SKIP_TABLES=$2;
                shift; shift;
                ;;
        -info)  SYS_INFO=1;
                shift;
                ;;
        -cm)    DOWNLOAD_COM_MODULES=1;
                shift;
                ;;
        -m)     UPDATE_MODULE=$2
                shift; shift;
                ;;
        -skip_backup) SKIP_BACKUP=1
                shift;
                ;;
        -skip_sql_update)  SKIP_SQL_UPDATE=1
                shift;
                ;;
        -skip_perl_check) SKIP_PERL_CHECK=1
                shift;
                ;;
        -skip_update) SKIP_UPDATE=1
                shift;
                ;;
        -git) GIT_UPDATE=1
                shift;
                ;;
        -free) FREE_UPDATE=1
                shift;
                ;;
        -gs)    GET_SNAPSHOT=1
                echo "${GET_SNAPSHOT}";
                shift;
                ;;
        -check_modules) CHECK_MODULES=1
                shift;
                ;;
        -skip_check_sql) SKIP_CHECK_SQL=1
                shift;
                ;;
        -sql_optimize) OPTIMIZE_DB=1
                shift;
                ;;
        -dl)    DOWNLOAD_LICENSE=1
                shift;
                ;;
        -reg)   REGISTRATION=1;
                shift;
                ;;
        -lib)   SHOULD_EXIT=1;
                shift;
        esac
done

update_self

if [ "${SHOULD_EXIT}" != "" ]; then
  exit 1;
fi;

if [ "${DOWNLOAD_LICENSE}" != "" ]; then
  get_license;
  exit;
fi;

if [ "${SKIP_PERL_CHECK}" = "" ] ; then
  check_perl
fi;

if [ "${HELP}" != "" ] ; then
  usage;
  exit;
fi;

if [ "${OPTIMIZE_DB}" != "" ] ; then
  sql_innodb_optimize;
  exit;
fi;

if [ "${CONVERT2UTF}" != "" ] ; then
  convert2utf;
  exit;
fi;

if [ "${AMON_FILE}" != "" ] ; then
  amon
  #${AMON_FILE};
fi;

if [ "${INODB}" != "" ] ; then
  convert2inodb;
  exit;
fi;

if [ "${REGISTRATION}" != "" ]; then
  sys_info;
  exit;
elif [ "${SYS_INFO}" != "" ] ; then
  sys_info;
  exit;
fi;

if [ "{CHECK_MODULES}" != "" ]; then
  check_modules PRE_CHECK;
fi;

if [ "${ROLLBACK}" != "" ] ; then
  rollback
else
  echo "**********************************************************"
  echo "# ABillS Update                                          #"
  echo "**********************************************************"

  #show errors
  if [ -f  /var/log/httpd/axbills-error.log ]; then
    echo "Web errors";
    tail /var/log/httpd/axbills-error.log
    echo "**********************************************************"
  fi;

  check_free_space
  
  if [ -f "${BILLING_DIR}/libexec/config.pl" ]; then
    CURE_CHARSET=`cat ${BILLING_DIR}/libexec/config.pl | grep dbcharset  | sed "s/^\\\$conf{dbcharset}='\(.*\)';/\1/"`;
  
    if [ x"${CURE_CHARSET}" = xcp1251 ]; then
      echo "First convert to UTF8";
      echo "see manual: "
      echo " http://axbills.net.ua/forum/viewtopic.php?f=1&t=5795"
      exit;
    fi;
  fi;


  if [ -d ${BILLING_DIR} ]; then
    if [ "${SKIP_SQL_UPDATE}" = "" ]; then
      update_sql
    fi;

    if [ -d "${BILLING_DIR}_${DATE}" ]; then
      SKIP_BACKUP=1
      echo "Skiping backup. Today backup exist"
    fi;

    #Backup curent version
    if [ "${SKIP_BACKUP}" = "" ]; then
      if [ -d "${BILLING_DIR}" ]; then
        cp -Rfp ${BILLING_DIR} ${BILLING_DIR}_${DATE}
        echo "Backuped to '${BILLING_DIR}_${DATE}'. Please wait some minutes"
      else
        echo " '${BILLING_DIR}' Not exist. Created ${BILLING_DIR}  "
        mkdir ${BILLING_DIR}
      fi;

      if [ -f ${BILLING_DIR}/libexec/updated ]; then
        echo "Last Updated".
        UPDATED=`cat ${BILLING_DIR}/libexec/updated`;
        echo ${UPDATED};
        LAST_UPDATED=`echo ${UPDATED} | awk '{ print $1 }'`
      fi;

      cp -Rfp ${BILLING_DIR} ${BILLING_DIR}_${DATE}
     else
       echo "Skip backup...";
     fi;

    if [ "${FULL}" != "" ]; then
       echo "Make full source update";
       rm -rf ${TMP_DIR}/axbills*
    fi;
  else
    mkdir ${BILLING_DIR}
  fi;

  beep;
  echo ""

  cd ${TMP_DIR}
  #Update from snapshots
  # http://axbills.net.ua/snapshots/
  if [ "${GET_SNAPSHOT}" != "" ]; then
    snapshot_update
  #Git update
  elif [ "${FREE_UPDATE}" != "" ]; then
    free_update;
  elif [ "${GIT_UPDATE}" != "" -o -f "${BILLING_DIR}/VERSION" ]; then
    git_update;
    #Update from CVS
  else
    free_update;
  fi;
  
  cd  ${TMP_DIR}
  echo "${DATE} DATE: ${FULL_DATE} UPDATE by ABILLS update" > ${TMP_DIR}/axbills/libexec/updated;
  work_copy="axbills_rel"

  if [ ! -d ${work_copy} ]; then
    mkdir ${work_copy}
    echo "Make '${work_copy}'"
  fi;

  check_modules PRE_CHECK;

  cp -Rf axbills/* ${work_copy}/

  find ${work_copy} | grep CVS | xargs rm -Rf
  find ${work_copy} | grep .git | xargs rm -Rf

  for dir in "${work_copy}/var" "${work_copy}/var/log" "${work_copy}/var/q" "${work_copy}/var/log/ipn"; do
    if [ ! -d "${dir}" ]; then
      mkdir ${dir};
    fi;
  done;
  
  if [ "${UPDATE_MODULE}" != "" ]; then
    if [ "${DEBUG}" != "" ] ; then
      echo "cp -Rf ${TMP_DIR}/${work_copy}/AXbills/modules/${UPDATE_MODULE}/* ${BILLING_DIR}/AXbills/modules/${UPDATE_MODULE}/"
    fi;

    cp -Rf ${TMP_DIR}/${work_copy}/AXbills/modules/${UPDATE_MODULE}/* ${BILLING_DIR}/AXbills/modules/${UPDATE_MODULE}/
    if [ -f ${TMP_DIR}/${work_copy}/AXbills/mysql/${UPDATE_MODULE}.pm ]; then
      cp ${TMP_DIR}/${work_copy}/AXbills/mysql/${UPDATE_MODULE}.pm ${BILLING_DIR}/AXbills/mysql/
    fi;

    echo "Modules '${UPDATE_MODULE}' updated";
  else
    if [ w${DEBUG} != w ] ; then
      echo "cp -Rf ${TMP_DIR}/${work_copy}/* ${BILLING_DIR}"
    fi;

    get_license;

    cp -Rf ${TMP_DIR}/${work_copy}/* ${BILLING_DIR}
    #Update Version
    if [ -f  ${BILLING_DIR}/libexec/config.pl ]; then
#      OLD_VERSION=`cat ${BILLING_DIR}/libexec/config.pl | grep versi | ${SED} "s/\\$conf{version}='\([0-9]*\)\.\([0-9]*\).*'.*/\1\2/"`

#      if [ ${OLD_VERSION} -lt 61 ]; then
#        NEW_VERSION=`cat ${BILLING_DIR}/libexec/config.pl.default | grep versi | ${SED} "s/\\$conf{version}='\(.*\)'.*/\1/"`
#      else
#        NEW_VERSION=0.61
#      fi;

#      cp ${BILLING_DIR}/libexec/config.pl ${BILLING_DIR}/libexec/config.pl.bak
#      ${SED} "s/\$conf{version}='.*'/\$conf{version}='${NEW_VERSION}\/${DATE}'/" ${BILLING_DIR}/libexec/config.pl > ${BILLING_DIR}/libexec/config.pl.new
#      mv ${BILLING_DIR}/libexec/config.pl.new ${BILLING_DIR}/libexec/config.pl
#      echo "Config updated";

      if [ -f "${BILLING_DIR}/VERSION" ]; then
        VERSION=`cat ${BILLING_DIR}/VERSION | awk '{ print $1 }'`;
        echo "${VERSION} ${DATE}" > "${BILLING_DIR}/VERSION";
      fi;

      #convert to utf-8
#      if [ w != w`grep "$conf{dbcharset}='utf8'" ${BILLING_DIR}/libexec/config.pl` ]; then
#        convert2utf update
#      fi;
      restart_servers;
    fi;
  fi;

  check_modules;
  check_files;
  mk_db_check;
  echo "Done.";
fi;

if [ "${CLEAN}" != "" ] ; then
  rm -rf ${TMP_DIR}/axbills*;
fi;

if [ w${SPEEDY} != w ] ; then
  speedy;
fi;



/usr/bin/mv /usr/axbills/var/log/update.log /usr/axbills/var/log/update_"$DATE".log

exit 0;
