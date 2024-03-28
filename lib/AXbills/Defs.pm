# Default variables

use strict;
use warnings FATAL => 'all';

use AXbills::HTML;
use AXbills::SQL;
use Conf;

#our AXbills::HTML $html;
our AXbills::SQL $db;
our %FORM         = ();
our %LIST_PARAMS  = ();
our $base_dir;
our $var_dir;
our $index        = 0;
our @state_colors = ('success', 'danger', 'warning');
our @state_icon_colors = ('1', 'text-red', 'text-yellow');
our @status       = ('ENABLE', 'DISABLE');
our $SELF_URL;
#our Admins $admin;

use vars qw(
  %conf
  %FUNCTIONS_LIST
  %USER_FUNCTION_LIST
  $TIME
  $DATE

  %functions
  $libpath
  $CHARSET
  @MODULES
  $Conf
  $user
  $users
  %menu_items
  %menu_names
  $pages_qs
  $PROGRAM
  %CHARTS
  $DEBUG
  $sid
  $begin_time
);

our %LANG = (
  'english' => 'English',
  'russian' => 'Русский',
  'ukrainian' => 'Українська',
);

#Error strings
our %err_strs = (
  1   => 'ERROR',
  2   => 'ERROR_NOT_EXIST',
  3   => 'ERROR_SQL',
  4   => 'ERROR_NO_DATA_FOR_CHANGE', # 'ERROR_WRONG_PASSWORD',
  5   => 'ERROR_WRONG_CONFIRM',
  6   => 'ERROR_SHORT_PASSWORD',
  7   => 'ERROR_DUPLICATE',
  8   => 'ERROR_ENTER_NAME',
  9   => 'ERROR_LONG_USERNAME',
  10  => 'ERROR_WRONG_NAME',
  11  => 'ERROR_WRONG_EMAIL',
  12  => 'ERROR_ENTER_SUM',
  13  => 'PERMISIION_DENIED',
  14  => 'NO_BILLING_ACCOUNT',
  15  => 'SMALL_DEPOSIT',
  16  => 'WRONG_START_PERIOD',
  17  => 'WRONG_NETWORK',
  18  => 'ERROR_ENTER_UID',
  19  => 'ERROR_USER_NOT_EXIST',
  20  => 'ERROR_PHONE_NOT_EXIST',
  21  => 'ERROR_WRONG_PHONE',
  50  => 'TIMEOUT',
  91  => 'TP_NOT_EXIST',
  700 => 'PLEASE_UPDATE_LICENSE',
  113 => 'ERROR_WRONG_FIELD_VALUE'
);

#Global files
#our $SNMPWALK  = '/usr/local/bin/snmpwalk';
#our $SNMPSET   = '/usr/local/bin/snmpset';
our $GZIP      = '/usr/bin/gzip';
our $TAR       = '/usr/bin/tar';
our $MYSQLDUMP = '/usr/local/bin/mysqldump';
our $IFCONFIG  = '/sbin/ifconfig';
our $IPFW      = '/sbin/ipfw';
#our $PING      = '/sbin/ping';
our $SUDO      = '/usr/local/sbin/sudo';

1
