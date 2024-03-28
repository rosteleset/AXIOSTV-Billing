#!/usr/bin/perl
# Trafiic grapher
#
#

#use strict;
use vars qw($begin_time $debug $DATE $TIME %conf $dbh $base_dir $db);

BEGIN {
  my $libpath  = '../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'AXbills/');
  eval { require Time::HiRes; };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
  }
  else {
    $begin_time = 0;
  }
}

BEGIN {
  my %MODS = ('RRDs' => "Graphic module");
  while (my ($mod, $desc) = each %MODS) {

    if (eval "require $mod") {
      $mod->import();    # if needed
      $MODS{"$mod"} = 1;
    }
    else {
      print "Content-Type: text/html\n\n";
      print "Can't load '$mod' ($desc); Please install RRDs. http://search.cpan.org/dist/RRD-Simple/";
      exit;
    }
  }
}

my $VERSION = 0.1;
require "config.pl";

use POSIX qw(strftime);
use AXbills::SQL;
use AXbills::HTML;
use Admins;
use Data::Dumper;
my $sql = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

$db                 = $sql->{db};
$sql->{db}->{debug} = 1;
$admin              = Admins->new($db, \%conf);

use AXbills::Base;
my $workdir = "./graphics";
my $ERROR;

#begin
$FORM{session_id} = '';

my $html = AXbills::HTML->new(
  {
    CONF     => \%conf,
    NO_PRINT => 0,
    PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
    CHARSET  => $conf{default_charset},
  }
);

$html->{language} = $FORM{language} if (defined($FORM{language}) && $FORM{language} =~ /[a-z_]/);
require "../language/$html->{language}.pl";

#Count of graphics
my %ids = ();

if ($RRDs::VERSION < 1.3003) {
  print "Content-Type: text/plain\n\n";
  print "Current version: $RRDs::VERSION
     Please Update RRDs tools to 1.3000 or lates";
  exit;
}

if ($FORM{SHOW_GRAPH}) {
  print "Content-Type: image/png\n\n";
}
else {
  print "Content-Type: text/html\n\n";
}

if (scalar %FORM > 0) {
  mk_graffic(\%FORM);
  show_page();
}
else {
  print "Put session or user id:<br>\n";
}

if ($begin_time > 0) {
  my $end_time = gettimeofday();
  my $gen_time = $end_time - $begin_time;
  print "<font size=-2><hr size=1>" . "Version: $VERSION (GT: " . sprintf("%.6f", $gen_time) . ")</font>";
}

#********************************************************
#
# show_page()
#********************************************************
sub show_page {

  print << "[END]";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML>
<HEAD>
    <TITLE>ABillS Users Traffic</TITLE>
    <meta http-equiv="content-type" content="text/html; charset=windows-1251" >
    <META HTTP-EQUIV="Refresh" CONTENT="300" >
    <META HTTP-EQUIV="Cache-Control" content="no-cache" >

    <META HTTP-EQUIV="Pragma" CONTENT="no-cache" >
    <META HTTP-EQUIV="Expires" CONTENT="Mon, 15 Mar 2010 10:39:51 GMT" >
    <LINK HREF="favicon.ico" rel="shortcut icon" >
</HEAD>


<style type="text/css">

body {
  background-color: #FFFFFF;
  color: #000000;
  font-family: Arial, Tahoma, Verdana, Helvetica, sans-serif;
  font-size: 14px;
  /* this attribute sets the basis for all the other scrollbar colors (Internet Explorer 5.5+ only) */
}


A:hover {text-decoration: none; color: #000000;}
.link_button {
  font-family:  Arial, Tahoma,Verdana, Helvetica, sans-serif;
  background-color: #eeeeee;
  color: #000000;
  border-color : #9F9F9F;
  font-size: 11px;
  border: 1px outset;
  text-decoration: none;
  padding:1px 5px;
}

a.link_button:hover {
  background:#ccc;
  background-color: #dddddd;
  border:1px solid #666;
  cursor: pointer;
}

</style>


<BODY bgcolor="#ffffff" text="#000000" link="#000000" vlink="#000000" alink="#000000">
  <hr size=1>
[END]

  if ($FORM{LOGIN}) {
    print "<b>$_USER:</b> <a href='index.cgi?LOGIN_EXPR=$FORM{LOGIN}'>$FORM{LOGIN}</a><br>";
  }
  elsif ($FORM{SESSION_ID}) {
    print "<b>Session_id:</b> $FORM{SESSION_ID}<br>";
  }
  elsif ($FORM{TP_ID}) {
    print "<b>$_TARIF_PLAN:</b> $FORM{TP_ID}<br>";
  }
  elsif ($FORM{NAS_ID}) {
    print "<b>NAS:</b> $FORM{NAS_ID}<br>";
  }
  elsif ($FORM{GID}) {
    print "<b>$_GROUP:</b>$FORM{GID}<br>";
  }

  print "<b>DATE:</b> $DATE $TIME ";

  my $i = 0;
  foreach my $key (sort keys %ids) {
    $i++;
    print "<p><img src='$workdir/graphic-daily_" . $i . ".png?TIME=$TIME'></p>\n";
    if (!$FORM{DAILY}) {
      print "<p><img src='$workdir/graphic-weekly_" . $i . ".png'></p>
    <p><img src='$workdir/graphic-monthly_" . $i . ".png'></p>\n";
    }
  }

  print << "[END]";
</BODY>
</HTML>
[END]

}

#********************************************************
# Make graphic
# mk_graffic($type, $value);
#********************************************************
sub mk_graffic {
  my ($attr) = @_;
  my $period = $attr->{'PERIOD'} || 1;
  $period = 1 if ( $attr->{'PERIOD'} > 2);
  if ($attr->{'ACCT_SESSION_ID'}) {
    %ids     = ($attr->{'ACCT_SESSION_ID'} => $attr->{'ACCT_SESSION_ID'});
  }
  elsif ($attr->{'LOGIN'}) {
    %ids     = ($attr->{'LOGIN'} => $attr->{'LOGIN'});
  }
  elsif ($attr->{'UID'}) {
    %ids     = ($attr->{'UID'} => $attr->{'UID'});
  }
  elsif ($attr->{'NAS_ID'}) {
    if ($attr->{'NAS_ID'} eq 'all') {
      $admin->query($db, "SELECT id, name FROM nas WHERE disable=0 ORDER BY id;");
      foreach my $line (@{ $admin->{list} }) {
        $ids{ $line->[0] } = convert($line->[1], { win2utf8 => 1 });
      }
    }
    else {
      %ids = ($attr->{'NAS_ID'} => $attr->{'NAS_ID'});
    }
  }
  elsif ($attr->{'TP_ID'}) {
    if ($attr->{'TP_ID'} eq 'all') {
      $admin->query($db, "SELECT id, name FROM tarif_plans ORDER BY id;");
      foreach my $line (@{ $admin->{list} }) {
        $ids{ $line->[0] } = convert($line->[1], { win2utf8 => 1 });
      }
    }
    else {
      %ids = ($attr->{'TP_ID'} => $attr->{'TP_ID'});
    }
  }
  elsif ($attr->{'GID'}) {
    if ($attr->{'GID'} eq 'all') {
      $admin->query($db, "SELECT gid, name FROM groups ORDER BY gid;");
      foreach my $line (@{ $admin->{list} }) {
        $ids{ $line->[0] } = convert($line->[1], { win2utf8 => 1 });
      }
    }
    else {
      %ids = ($attr->{'GID'} => $attr->{'GID'});
    }
  }

  if (!-d $workdir) {
    mkdir("$workdir");
  }

  my $i = 0;
 foreach my $key (sort keys %ids) {
 if ($conf{GRAPH_RRD}) {
  my $graph_name = $key;
  if ($attr->{'NAS_ID'}) {
   $graph_name = "NAS_ID_$key";
  }
  elsif ($attr->{'TP_ID'}) {
   $graph_name = "TP_ID_$key";
  }
  elsif ($attr->{'GID'}) {
   $graph_name = "GID_$key";
  }
  my $rrd = '/usr/axbills/var/log/rrd';
  $i++;
  if (! -e "$rrd/$graph_name.rrd") {
    $rrd = $workdir;
        RRDs::create "$rrd/$graph_name.rrd",
             "-s 300",
             "DS:in:DERIVE:600:0:U",
             "DS:out:DERIVE:600:0:U",
             "DS:in_ex:DERIVE:600:0:U",
             "DS:out_ex:DERIVE:600:0:U",
             "RRA:AVERAGE:0.5:1:864",
             "RRA:AVERAGE:0.5:6:672",
             "RRA:AVERAGE:0.5:24:732";
  }

  if (!$attr->{'WEEKLY'}){
      my $return_hash = RRDs::graphv(
        ($attr->{SHOW_GRAPH}) ? undef : "$workdir/graphic-daily_" . $i . ".png",
                "-h", "150", "-w", "500",
                "-s -" . $period . "d",
                "-e -" . ($period - 1) . "d",
                "-t TRAFFIC DAILY $graph_name",
                "DEF:inoctets=$rrd/$graph_name.rrd:in:AVERAGE",
                "DEF:outoctets=$rrd/$graph_name.rrd:out:AVERAGE",
                "DEF:inoctets_ex=$rrd/$graph_name.rrd:in_ex:AVERAGE",
                "DEF:outoctets_ex=$rrd/$graph_name.rrd:out_ex:AVERAGE",
                "CDEF:inbits=inoctets,8000,*",
                "CDEF:outbits=outoctets,8000,*",
                "CDEF:inbits_ex=inoctets_ex,8000,*",
                "CDEF:outbits_ex=outoctets_ex,8000,*",
                "AREA:inbits#00FF00:'In    traffic MAX' ",
                "GPRINT:inbits:MAX:%.0lf %sbit/sec ",
                "LINE1:outbits#0000FF:'Out    traffic MAX' ",
                "GPRINT:outbits:MAX:%.0lf %sbit/sec\\n",
                "AREA:inbits_ex#FF6A00:'In_EX traffic MAX' ",
                "GPRINT:inbits_ex:MAX:%.0lf %sbit/sec ",
                "LINE1:outbits_ex#FF0000:'Out_EX traffic MAX' ",
                "GPRINT:outbits_ex:MAX:%.0lf %sbit/sec\\n"

      );
      $ERROR = RRDs::error();
      if ($ERROR) {
        print "$0: unable to create '$workdir/graphic-daily.png': $ERROR\n";
        return 0;
      }

      if ($attr->{SHOW_GRAPH}) {
        print $return_hash->{image};
        exit;
      }
      next if ($attr->{DAILY});
}
      my $return_hash = RRDs::graphv(
        ($attr->{SHOW_GRAPH}) ? undef : "$workdir/graphic-weekly_" . $i . ".png",
                "-h", "150", "-w", "500",
                "-s -1w",
                "-t TRAFFIC WEEKLY $graph_name",
                "DEF:inoctets=$rrd/$graph_name.rrd:in:AVERAGE",
                "DEF:outoctets=$rrd/$graph_name.rrd:out:AVERAGE",
                "DEF:inoctets_ex=$rrd/$graph_name.rrd:in_ex:AVERAGE",
                "DEF:outoctets_ex=$rrd/$graph_name.rrd:out_ex:AVERAGE",
                "CDEF:inbits=inoctets,8000,*",
                "CDEF:outbits=outoctets,8000,*",
                "CDEF:inbits_ex=inoctets_ex,8000,*",
                "CDEF:outbits_ex=outoctets_ex,8000,*",
                "AREA:inbits#00FF00:'In    traffic MAX' ",
                "GPRINT:inbits:MAX:%.0lf %sbit/sec ",
                "LINE1:outbits#0000FF:'Out    traffic MAX' ",
                "GPRINT:outbits:MAX:%.0lf %sbit/sec\\n",
                "AREA:inbits_ex#FF6A00:'In_EX traffic MAX' ",
                "GPRINT:inbits_ex:MAX:%.0lf %sbit/sec ",
                "LINE1:outbits_ex#FF0000:'Out_EX traffic MAX' ",
                "GPRINT:outbits_ex:MAX:%.0lf %sbit/sec\\n"
      );

      if ($attr->{SHOW_GRAPH}) {
        print $return_hash->{image};
        exit;
      }
      $ERROR = RRDs::error();
      if ($ERROR) {
        print "$0: unable to create '$workdir/graphic-weekly.png': $ERROR\n";
        return 0;
      }

        RRDs::graphv( "$workdir/graphic-monthly_" . $i . ".png",
                "-h", "150", "-w", "500",
                "-s -1m",
                "-t TRAFFIC MOUNTLY $graph_name",
                "DEF:inoctets=$rrd/$graph_name.rrd:in:AVERAGE",
                "DEF:outoctets=$rrd/$graph_name.rrd:out:AVERAGE",
                "DEF:inoctets_ex=$rrd/$graph_name.rrd:in_ex:AVERAGE",
                "DEF:outoctets_ex=$rrd/$graph_name.rrd:out_ex:AVERAGE",
                "CDEF:inbits=inoctets,8000,*",
                "CDEF:outbits=outoctets,8000,*",
                "CDEF:inbits_ex=inoctets_ex,8000,*",
                "CDEF:outbits_ex=outoctets_ex,8000,*",
                "AREA:inbits#00FF00:'In    traffic MAX' ",
                "GPRINT:inbits:MAX:%.0lf %sbit/sec ",
                "LINE1:outbits#0000FF:'Out    traffic MAX' ",
                "GPRINT:outbits:MAX:%.0lf %sbit/sec\\n",
                "AREA:inbits_ex#FF6A00:'In_EX traffic MAX' ",
                "GPRINT:inbits_ex:MAX:%.0lf %sbit/sec ",
                "LINE1:outbits_ex#FF0000:'Out_EX traffic MAX' ",
                "GPRINT:outbits_ex:MAX:%.0lf %sbit/sec\\n"
      );
    $ERROR = RRDs::error();
    if ($ERROR) {
      print "$0: unable to create '$workdir/graphic-monthly.png': $ERROR\n";
      return 0;
    }

  }
 } 
  return 0;
}


