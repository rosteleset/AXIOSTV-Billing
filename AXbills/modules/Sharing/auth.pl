#!/usr/bin/perl -w
=head1

   Sharing auth for Apache with mod_authnz_external (http://unixpapa.com/mod_authnz_external/)

=cut

use warnings;
use DBI;
use strict;

our (%conf, $DATE, $TIME);


#Main debug section
my $prog = join ' ', $0, @ARGV;

my $aa = '';
while (my ($k, $v) = each %ENV) {
  $aa .= "$k - $v\n";
}

#***************************************************
my $user = $ENV{USER} || '';
my $passwd = $ENV{PASS} || '';
my $ip = $ENV{IP} || '0.0.0.0';
my $COOKIE = $ENV{COOKIE} || '';
my $URL = $ENV{URI} || '';

#**************************************************************
# DECLARE VARIABLES                                                           #
#**************************************************************
#DB configuration
#use FindBin '$Bin';
#require $Bin . '/../../../libexec/config.pl';

require '/usr/axbills/libexec/config.pl';


#$conf{dbhost}='huan';
#$conf{dbname}='axbills_dev';
#$conf{dbuser}='stats';
#$conf{dbpasswd}='45&34';
#$conf{dbtype}='mysql';
#$conf{secretkey}="test12345678901234567890";

# open database connection
my $dbh = DBI->connect("DBI:mysql:database=$conf{dbname};$conf{dbhost}", $conf{dbuser}, $conf{dbpasswd})
  or die("Unable to connect to database. Aborting!\n");

if (!$dbh) {
  print STDERR "Could not connect to database - Rejected\n";
  exit 1;
}

#Get User ID and pass check in db
#Check cookie
my %cookies = ();
if ($COOKIE ne '') {
  my (@rawCookies) = split (/; /, $COOKIE);
  foreach(@rawCookies) {
    my ($key, $val) = split (/=/, $_);
    $cookies{$key} = $val;
  }
}

my $sth;
my $MESSAGE = '';

if ($#ARGV > - 1) {
  web_auth();
  exit 1;
}
else {
  my $debug = " URI: $ENV{URI}
 USER:      $ENV{USER}
 Password:  $ENV{PASS}
 IP         $ENV{IP}
 HTTP_HOST: $ENV{HTTP_HOST}
 ===PIPE
 $prog
 ===EXT
 $aa
 === \n";
  # $a = `echo "$debug" >> /tmp/sharing_env`;


  if (auth()) {
    exit 0;
  }
  else {
    print STDERR "$MESSAGE";
    #Make error log 

    my $query = "INSERT INTO sharing_errors
      (datetime, uid, username, file_and_path,
      client_name,
      ip,
      client_command)
    values (now(), 0, '$user', '$URL', '', INET_ATON('$ip'), \"$MESSAGE\")";

    #my $z = `echo "$query" >> /tmp/q`;

    $dbh->do($query);

    exit 1;
  }
}

exit 1;

#**********************************************************
#
#**********************************************************
sub auth {

  my ($uid, $datetime, $remote_addr, $alived, $password);
  my $auth = 0;

  #Cookie auth
  if ($cookies{sid}) {
    $cookies{sid} =~ s/\'//g;
    $cookies{sid} =~ s/\"//g;
    my $query = "SELECT uid,
    datetime, 
    login, 
    INET_NTOA(remote_addr), 
    UNIX_TIMESTAMP() - datetime,
    sid
     FROM web_users_sessions
    WHERE sid='$cookies{sid}'";

    $sth = $dbh->prepare($query);

    $sth->execute();
    if ($dbh->rows() == - 1) {
      $MESSAGE = "Wrong SID for '$user' '$cookies{sid}' - Rejected\n";
    }
    else {
      $auth = 1;
      ($uid, $datetime, $user, $remote_addr, $alived) = $sth->fetchrow_array();
    }
  }



  #Passwd Auth
  if ($auth == 0) {
    #check password
    my $query = "SELECT if(DECODE(u.password, '$conf{secretkey}')='$passwd', 1,0), u.uid
   FROM (users u, sharing_main sharing)
    WHERE u.id='$user'  AND u.uid=sharing.uid  
                    AND (u.disable=0 AND sharing.disable=0)
                    AND (sharing.cid='' OR sharing.cid='$ip')";

    $sth = $dbh->prepare($query);
    $sth->execute();

    ($password, $uid) = $sth->fetchrow_array();

    if ($sth->rows() < 0) {
      $MESSAGE = "User not found '$user' - Rejected\n";
      return 0;
    }
    elsif ($password == 0) {
      $MESSAGE = "Wrong user password '$user' - Rejected\n";
      return 0;
    }
  }


  #Get user info and ballance
  #check password
  my $query = "select
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  u.company_id,
  u.disable,
  u.bill_id,
  u.credit,
  u.activate,
  u.reduction,
  sharing.tp_id,
  tp.payment_type,
  tp.month_traf_limit,
  sharing.extra_byte,
  count(sa.tp_id)
     FROM (users u, sharing_main sharing, tarif_plans tp)
     LEFT JOIN sharing_additions sa ON (tp.id=sa.tp_id) 
     WHERE
        u.uid=sharing.uid
        AND sharing.tp_id=tp.id
        AND u.uid='$uid'
        AND (u.expire='0000-00-00' or u.expire > CURDATE())
        AND (u.activate='0000-00-00' or u.activate <= CURDATE())
       GROUP BY u.id";

  $sth = $dbh->prepare($query);
  $sth->execute();

  if ($sth->rows() < 1) {
    $MESSAGE = "[$user] Not exist or account may be expire - Rejected\n";
    return 0;
  }

  my (
    $unix_date,
    $day_begin,
    $day_of_week,
    $day_of_year,
    $company_id,
    $disable,
    $bill_id,
    $credit,
    $activate,
    $reduction,
    $tp_id,
    $payment_type,
    $month_traf_limit,
    $extra_trafic,
    $extra_traffic_count
  ) = $sth->fetchrow_array();

  if ($disable) {
    $MESSAGE = "[$user] Disabled - Rejected\n";
    return 0;
  }

  #Get Deposit
  $query = "select deposit FROM bills WHERE   id='$bill_id'";
  $sth = $dbh->prepare($query);
  $sth->execute();
  my ( $deposit ) = $sth->fetchrow_array();



  # /vids/video_506/video/200704/rtr20070403-2315_c.avi
  my $request_path = '';
  my $request_file = '';

  #if ($URL =~ /\/vids(\S+)\/(\S+)$/) {
  #if ($URL =~ /([A-Za-z0-9\.\-\_ \[\]]+)\/([A-Za-z0-9\.\-\_ \[\]]+)$/) {
  #  $request_path = $1;
  #  $request_file = $2;
  #}
  #$query  = "select server, priority, filesize from lenta.tx_t3labtvarchive_files

  # WHERE path='$request_path' and filename='$request_file';";

  if ($conf{SHARING_RMURL_PREFIX}) {
    $URL =~ s/$conf{SHARING_RMURL_PREFIX}//;
  }

  $query = "SELECT server, priority, size FROM sharing_priority WHERE file='$URL'";

  $sth = $dbh->prepare($query);
  $sth->execute();

  #my $ww =  `echo "SELECT server, priority, size FROM sharing_priority WHERE file='$URL' " > /tmp/sharing_env`;

  if ($sth->rows() > 0) {
    my ( $server, $priority, $size  ) = $sth->fetchrow_array();



    # Payment traffic
    if ($priority == 0) {
      #Get prepaid traffic and price
      my $WHERE = ($activate ne '0000-00-00') ? " and DATE_FORMAT(start, '%Y-%m-%d')>='$activate'" : "";
      $sth = $dbh->prepare("SELECT prepaid, in_price, out_price, prepaid, in_speed, out_speed
     FROM sharing_trafic_tarifs 
     WHERE tp_id='$tp_id'
     ORDER BY id;");

      $sth->execute();
      my ( $prepaid_traffic,
        $in_price,
        $out_price,
        $in_speed,
        $out_speed
      ) = $sth->fetchrow_array();

      #Get used traffic
      $query = "select sum(sl.sent)
     FROM sharing_log sl, sharing_priority sp
     WHERE 
     sl.url=sp.file
     and sl.username='$user' $WHERE";

      $sth = $dbh->prepare($query);
      $sth->execute();
      my ( $used_traffic ) = $sth->fetchrow_array();

      $prepaid_traffic = (defined($prepaid_traffic) && $prepaid_traffic > 0) ? $prepaid_traffic * 1024 * 1024 : $month_traf_limit * 1024 * 1024;
      $prepaid_traffic = $prepaid_traffic + $extra_trafic * 1048576 if ($extra_trafic > 0 && $extra_traffic_count > 0);
      $deposit = $deposit + $credit;

      my $rest_traffic = 0;
      if ($deposit < 0 && $used_traffic > $prepaid_traffic) {
        $MESSAGE = "[$user] Use all prepaid traffic - Rejected\n";
        return 0;
      }
      elsif ($deposit < 0) {
        $MESSAGE = "[$user] Negtive deposit '$deposit' - Rejected\n";
        return 0;
      }

      my $sde = `echo "$DATE $TIME: $ENV{USER} / FILESIZE: $size / $prepaid_traffic - $used_traffic / $extra_trafic; $query" >> /tmp/rrr`;

      if ($prepaid_traffic > 0) {
        $rest_traffic = $prepaid_traffic - $used_traffic;
      }

      if ($deposit > 0) {
        $rest_traffic = $rest_traffic + $deposit * $in_price * 1048576;
      }

      if ($size > $rest_traffic) {
        $MESSAGE = "[$user] Download file too large (Size: $size Rest: $rest_traffic b) - Rejected\n";
        return 0;
      }

    }
    # Free
    elsif ($priority == 1) {

    }
  }

  return 1;
}
# Get month traffic



$sth->finish();
$dbh->disconnect();

#**********************************************************
=head2 web_auth($argv) - Web auth and add url to allow download URL

=cut
#**********************************************************
sub web_auth {
  my ($argv) = @_;

  my $request_file = $argv->[0];

  if (auth()) {
    print "Location: $request_file\n\n";
  }
  else {
    print "Content-Type: text/html\n\n";
    print "$MESSAGE\n";
    return 0;
  }

  return 0;
}

#INSERT INTO sharing_priority
#(server,
# file,
# size,
# priority
# )
#SELECT
# server,  CONCAT(path, filename ),  filesize,  priority
#FROM lenta.tx_t3labtvarchive_files


exit 0;

1;
