#!/usr/bin/perl
# ODBC sync example
#
#**********************************************************
use strict;
use warnings;
use vars qw( %conf );


use DBI;

eval { require DBD::ODBC; };
if (!$@) {
  DBD::ODBC->import();
}
else {
  print "Can't load DBD::ODBC";
  return 0;
}



my $server    = $conf{ODBC_IP}    || '192.168.11.166';
my $db_user   = $conf{ODBC_USER}  || 'mhmAbillis';
my $db_passwd = $conf{ODBC_PASSWD}|| 'abillis';
my $db_name   = $conf{ODBC_NAME}  || 'BillingNew';
my $db_dsn    = $conf{ODBC_DSN}   || 'MSSQL';


my $begin_time = 0;



my $db_o = DBI-> connect("dbi:ODBC:DSN=$db_dsn;UID=$db_user;PWD=$db_passwd") or die "CONNECT ERROR! :: $DBI::err $DBI::errstr $DBI::state $!\n";

use FindBin '$Bin';
require $Bin . '/../libexec/config.pl';
unshift(@INC, $Bin . '/../', $Bin . "/../AXbills/$conf{dbtype}");

require AXbills::Base;
AXbills::Base->import();
$begin_time = check_time();

require AXbills::SQL;
my $sql = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

my $db = $sql->{db};

require Admins;
Admins->import();
my $admin = Admins->new($db, \%conf);




my $master_info = get_sync_status();
sync_status({ MASTER_INFO => $master_info });
#show_info


#**********************************************************
#
#**********************************************************
sub sync_status {
  my ($attr) = @_;

  my $master_info = $attr->{MASTER_INFO};
  my %status_ = ( 
    # esli 2 nada emu dat internet
    2 => 0,
    #esli 4 to u neqo dolg i emu nada zakrit internet
    4 => 1,
    #elsi 6 to on sam vremenno ne xochit poluchit internet i emu ne vichislyaetsa dolg
    6 => 
  );

  $admin->query2("SELECT u.id AS login, dv.disable AS status, u.gid, u.uid 
                     FROM users u
                     LEFT JOIN dv_main dv ON (dv.uid=u.uid)", undef, { COLS_NAME => 1 });

  my $list = $admin->{list};

  foreach my $line (@$list) {
    if ( $master_info->{$line->{login}} ) {
      while(my($k, $v) = each %{ $master_info->{$line->{login}} }) {
        if ($v ne $line->{lc($k)}) {
          if ($k eq 'GID') {
            #$admin->query2("UPDATE users SET gid=? WHERE uid=?", 'do', { Bind => [ $v, $line->{uid} ] });
          }
          elsif($k eq 'STATUS') {
            my $status = $status_{$v} || 0;
            #$admin->query2("UPDATE dv_main SET disable=? WHERE uid=?", 'do', { Bind => [ $status, $line->{uid} ] });
          }
          
          print "$line->{login} $k: $v -> ". $line->{lc($k)}."\n"; 
        }
        #print %{ $master_info->{$line->{login}} };
      }
    }  
    else {
      print "Login: '$line->{login}' not found\n"; 
    }

  }

}

#**********************************************************
#
#**********************************************************
sub get_sync_status {
  my ($attr) = @_;
  
  my %master_info = ();

  my $sql = q/SELECT user__login, group__id, user_state__id FROM dbo.users/;

  my $sth = $db_o->prepare($sql);
  $sth->execute();

  while (my @row = $sth->fetchrow_array) {  # retrieve one row at a time
    $master_info{$row[0]} = {
         GID    => $row[1],
         STATUS => $row[2] 
        };
  }
  
  return \%master_info;
}


#**********************************************************
#
#**********************************************************
sub show_info {


if ($db_o) {
  print "There is a connection\n";
  my $sql = q/select group__id, user__login, user_state__id from $db_name.users/;
  my $sth = $db_o->prepare($sql);
  $sth->execute();
  my @row;
  while (@row = $sth->fetchrow_array) {  # retrieve one row at a time
    print join(", ", @row), "\n";
  }
}

}


#**********************************************************
#
#**********************************************************
sub get_users {

 my $sql = q/select group__id, user_state__id, user__login, user__pass, user__framed_ip_address, user__createdt, user__deletedt, tariff__id, connspeed__id from BillingNew..users/;

 my $sth = $db_o->prepare($sql);
 $sth->execute();

 while (my @row = $sth->fetchrow_array) {  # retrieve one row at a time

 }

}


#**********************************************************
#
#**********************************************************
sub get_odbc_info {
 
my @dsns = DBI->data_sources('ODBC');
foreach my $d (@dsns) {
  print "$d\n";
}
 
  
}


1
