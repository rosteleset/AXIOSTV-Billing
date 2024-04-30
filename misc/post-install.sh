#!/usr/bin/env bash
#
# Post installation tests for ABillS

#Using alib.sh
. ./alib.sh ;

guess_pac_man;
get_os;

SQL_ERRORS_LOG_FILE='/usr/axbills/var/log/sql_errors';

# Programs that should be installed
PROGRAMS="
 mysql
 radiusd
 curl
 gzip
 mysqldump
 sudo
";

#Services for which scripts should exist in rc.d
SERVICES="
 apache2
 mysql
"

#Variables in /usr/axbills/AXbills/programs that should be declared
VARS_THAT_SHOULD_BE_DEFINED='
 WEB_SERVER_USER
 MYSQLDUMP
 GZIP
 APACHE_CONF_DIR
 RESTART_MYSQL
 RESTART_RADIUS
 RESTART_APACHE
 RESTART_DHCP
 PING';

#Files and directories that should be owned by apache user
FILES_OWNED_BY_APACHE="
 /usr/axbills/cgi-bin/
 /usr/axbills/AXbills/templates/
 /usr/axbills/backup/
";

# Files and directories that should have 777 rights
FILES_WITH_FULL_RIGHTS="
 ${SQL_ERRORS_LOG_FILE}
 /usr/axbills/var/
 /usr/axbills/var/log/
";

#Files and directories that should exist
FILES_SHOULD_EXIST="
 /usr/axbills/backup/
 /usr/axbills/var/
 /usr/axbills/var/log/
 ${SQL_ERRORS_LOG_FILE}
 /etc/crontab
";

APACHE_USER=`ps aux | egrep '(www|apache|www-data)' | grep -v root | cut -d\  -f1 | sort | uniq`;

TIP_CMD='';

NOT_INSTALLED='';

check_perl_modules(){
  perl ./perldeps.pl test || echo "
  TIP : To install missing modules, run perl ./perldeps.pl  ${PACKAGE_MANAGER}
  ";
}

check_if_user_exists(){
  not_exists="";
  getent passwd $1 > /dev/null 2>&1 || not_exists="true";

  if [ x"${not_exists}" == x"true" ]; then
    echo "  !!! $2 contains wrong username ${value}";
    echo "    Tip: check if it's right name for $2 or create user $1" ;
  fi;

}

check_owned_by_apache(){
  if [ -d ${1} ];then
    DIR_NAME=`echo "${1}" | egrep -o '[a-zA-Z0-9_-]*/{1}$' | sed 's/\///g'`;
    IS_OWNER=`ls -l ${1}/.. | grep ${DIR_NAME} | grep ${APACHE_USER}`;
    if [ x"${IS_OWNER}" = x"" ]; then
      echo "  !!! ${1} is not owned by ${APACHE_USER}; TIP: chown -R ${APACHE_USER} ${1}";
    fi;
  else
    IS_OWNER=`ls -l ${1} | grep ${APACHE_USER}`;
    if [ x"${IS_OWNER}" = x""} ]; then
      echo "  !!! ${1} is not owned by ${APACHE_USER}; TIP: chown ${APACHE_USER} ${1}";
    fi;
  fi;
}

check_full_rights(){
  echo " Checking ${1}";
  if [ -d ${1} ];then
    IS_WRITABLE_BY_OTHERS=`ls -ld ${1} | cut -c9`;
  else
    IS_WRITABLE_BY_OTHERS=`ls -l ${1} | cut -c9`;
  fi;
  
  if [ x"${IS_WRITABLE_BY_OTHERS}" != x"w" ]; then
    echo "  !!! ${1} cannot be writable by others; TIP:  chmod 777 ${1}"
  fi;
}


echo "Checking perl modules";
  check_perl_modules;


#Test program pathes
FILE_WITH_PATHES="/usr/axbills/AXbills/programs";
echo "Checking program definitions in ${FILE_WITH_PATHES}";
if [ -e ${FILE_WITH_PATHES} ]; then

  NOT_DEFINED='';
  for program in ${VARS_THAT_SHOULD_BE_DEFINED};do
  program_def=`grep ${program} ${FILE_WITH_PATHES}`

    #check if not empty
    if [ x"${program_def}" = x"${program}=" ]; then
      echo "  !!! Definition is empty for ${program}";
      continue;
    fi

    #check if non-empty
		value=`echo ${program_def} | sed 's/^.*=//'`;
		if [ x"${value}" = x"" ]; then
		  echo "  !!! Definition is absent for ${program} in ${FILE_WITH_PATHES}";
		  continue;
		fi;

		#check if value is right
		  #check_if_user
		  IS_USER=`echo ${program} | grep "_USER"`;
		  if [ ! x"${IS_USER}" = x"" ]; then
		    check_if_user_exists ${value} ${program};
		    continue;
		  fi;
		  #check_if_dir
		  IS_DIR=`echo ${program} | grep "_DIR"`;
		  if [ ! x"${IS_DIR}" = x"" ]; then
        if [ ! -d ${value} ]; then
          echo "  !!! ${program} contains non-existent directory ${value}"
        fi;
		    continue;
		  fi;
		  #check if exists
		  if [ ! -e "${value}" ]; then
		    echo "  !!! ${program} ${value}. File doesn't exist"
		  fi;
  done;

else
  echo "  !!! File with program pathes (/usr/axbills/AXbills/programs) not exists";
  echo "  !!! Exit with error";
  exit 1;
fi

#check programs installed

echo "Checking installed programs"
NOT_INSTALLED='';
for program in ${PROGRAMS}; do
  which ${program} > /dev/null 2>&1 || NOT_INSTALLED="${NOT_INSTALLED} ${program}";
done;

if [ ! x"${NOT_INSTALLED}" = x'' ]; then
  echo "!!! You have non-installed programs:";
  for program in ${NOT_INSTALLED}; do
    echo "  You should install: ${program}";
    echo " TIP: Please visit http://billing.axiostv.ru/wiki/doku.php/axbills:docs:manual:install_${OS_NAME}:ru for instructions";

  done
fi;

#check services

echo "Checking services"
NOT_INSTALLED='';
for program in ${SERVICES}; do
  [ -e ${program} ] || NOT_INSTALLED="${NOT_INSTALLED} ${program}";
done;

if [ ! x"${NOT_INSTALLED}" = x'' ]; then
  echo "  !!! You have non-installed services:";
  for program in ${NOT_INSTALLED}; do
    echo "  You should install if it is required in your scheme: ${program} ";
    echo " TIP: Please visit http://billing.axiostv.ru/wiki/doku.php/axbills:docs:manual:install_${OS_NAME}:ru for instructions";
  done
fi;

echo "Checking file and folder permissions"

# check permissions for apache in cgi-bin
echo " Checking /usr/axbills/cgi-bin";
for file in ${FILES_SHOULD_EXIST};do
  if [ ! -e ${file} ]; then
	  echo "  !!! ${file}. File doesn't exist"
	fi;
done;

for file in ${FILES_OWNED_BY_APACHE};do
  check_owned_by_apache ${file};
done;


for file in ${FILES_WITH_FULL_RIGHTS};do
  check_full_rights ${file};
done;
# check permissions for ${SQL_ERRORS_LOG_FILE}/

#check MySQL connection

echo "Checking DB connection";
DBUSER=`cat /usr/axbills/libexec/config.pl | grep '{dbuser}' |  egrep -o "'.*'" | sed "s/'//g"`;
DBPASS=`cat /usr/axbills/libexec/config.pl | grep '{dbpasswd}' |  egrep -o "'.*'" | sed "s/'//g"`;
DBNAME=`cat /usr/axbills/libexec/config.pl | grep '{dbname}' |  egrep -o "'.*'" | sed "s/'//g"`;
DBHOST=`cat /usr/axbills/libexec/config.pl | grep '{dbhost}' |  egrep -o "'.*'" | sed "s/'//g"`;

ERROR='OK';

mysql -u ${DBUSER} -h ${DBHOST} -p${DBPASS} -D ${DBNAME} -e 'quit' || ERROR="FAIL"

echo "  Connection to DB : ${ERROR}";

if [ x${ERROR} = x"FAIL" ]; then

  if [ x${DBHOST} = x"localhost" ]; then
    which mysql || echo "  !!! MySQL is not installed";
  else
    ping ${DBHOST} -c 3 || echo "  !!! Can't connect to ${DBHOST}";
  fi;

fi

exit 0;
