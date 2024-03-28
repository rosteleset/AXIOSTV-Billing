#!/usr/bin/perl

use vars qw(%conf %log_levels $db $DATE $time $var_dir
@START_FW

);
use strict;

my $vesion = 0.01;

use FindBin '$Bin';
require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . "/../AXbills/$conf{dbtype}");
require AXbills::Base;
AXbills::Base->import();
use POSIX qw(strftime);
use Data::Dumper;
use RRDs;

require AXbills::SQL;
require Admins;

my $ARGV = parse_arguments(\@ARGV);

my $debug       = $ARGV->{DEBUG} || 0;

if (!$conf{GRAPH_RRD}) {
exit;
}
sleep 60  if ($debug < 7);;
query_rrd();

#**********************************************************
#
#**********************************************************
sub db_connect {

  my $sql = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
  my $db = $sql->{db};

  return $db;
}

#**********************************************************
#
#**********************************************************
sub query_rrd {
  my ($attr) = @_;
      rrd_main ({NAME => 'NAS_ID' });
      rrd_main ({NAME => 'TP_ID' });
      rrd_main ({NAME => 'GID'});
      rrd_main ();

}
#**********************************************************
#
#**********************************************************
sub rrd_main {
  my ($attr) = @_;

  my $db = db_connect();
  my $in = 0;
  my $out = 0;
  my $in_ex = 0;
  my $out_ex = 0;
  my $GROUP_BY = '';
  my $Admin = Admins->new($db, undef, \%conf);
  $Admin->{debug} = 1 if ($debug > 7);
  my $table_name = '';
  my %SPEED = ();

   if ($attr->{NAME} eq "NAS_ID") {
     $table_name = "nas_id";
     $GROUP_BY = "GROUP BY c.nas_id";
   }
   elsif ($attr->{NAME} eq "TP_ID") {
     $table_name = "tp_id";
     $GROUP_BY = "GROUP BY tp.tp_id";
   }
   elsif ($attr->{NAME} eq "GID") {
     $attr->{GID} = 0 if (!$attr->{GID});
     $table_name = "gid";
     $GROUP_BY = "GROUP BY u.gid";
   }
   else {
     $GROUP_BY = "GROUP BY c.uid";
     $table_name = "uid";
   }
  $Admin->query(
    $db, "SELECT user_name, UNIX_TIMESTAMP() - UNIX_TIMESTAMP(started) AS duration, 
    tp.tp_id,
    INET_NTOA(c.framed_ip_address) AS ip,
    '255.255.255.255',
    u.gid,	
    c.nas_id,
    c.uid,
    SUM(c.acct_input_octets) AS acct_input_octets,
    SUM(c.acct_output_octets) AS acct_output_octets,
    SUM(c.ex_input_octets) AS ex_input_octets,
    SUM(c.ex_output_octets) AS ex_output_octets,
    n.ip as nas_ip
    FROM dv_calls c
    INNER JOIN nas n ON (n.id=c.nas_id)
    LEFT JOIN dv_main dv ON (dv.uid=c.uid)
    LEFT JOIN users u ON (u.uid=c.uid)
    LEFT JOIN tarif_plans tp  ON (tp.id=dv.tp_id AND tp.module='Dv')
    WHERE (status=1 or status=3 or status=10) $GROUP_BY
    ; ",
    undef,
    { COLS_NAME => 1 }
  );
  foreach my $line (@{ $Admin->{list} }) {
       $SPEED{ $line->{ $table_name } }{IN} = int($line->{acct_input_octets}*0.001);
       $SPEED{ $line->{ $table_name } }{OUT} = int($line->{acct_output_octets}*0.001);
       $SPEED{ $line->{ $table_name } }{IN_EX} = int($line->{ex_input_octets}*0.001);
       $SPEED{ $line->{ $table_name } }{OUT_EX} = int($line->{ex_output_octets}*0.001);
       $SPEED{ $line->{ $table_name } }{NAME} = ($table_name eq "uid") ? $line->{user_name} : $attr->{NAME} . "_" . $line->{ $table_name };
  }
    foreach my $list (keys %SPEED) {
      add_to_databace ({ IN => $SPEED{$list}{IN} , OUT => $SPEED{$list}{OUT} , IN_EX => $SPEED{$list}{IN_EX} , OUT_EX => $SPEED{$list}{OUT_EX} , NAME => $SPEED{$list}{NAME} }) if ($debug < 7);
      print "NAME => $SPEED{$list}{NAME}, IN => $SPEED{$list}{IN} , OUT => $SPEED{$list}{OUT} , IN_EX => $SPEED{$list}{IN_EX} , OUT_EX => $SPEED{$list}{OUT_EX}\n" if ($debug > 7);
    }

}


#**********************************************************
# add to databace
#**********************************************************
sub add_to_databace {
  my ($attr) = @_;
# define location of rrdtool databases
my $rrd = '/usr/axbills/var/log/rrd';

  if (!-d $rrd) {
    mkdir("$rrd");
  }

	# if rrdtool database doesn't exist, create it
	if (! -e "$rrd/$attr->{NAME}.rrd")
	{
		RRDs::create "$rrd/$attr->{NAME}.rrd",
			"-s 300",
			"DS:in:DERIVE:600:0:U",
			"DS:out:DERIVE:600:0:U",
                        "DS:in_ex:DERIVE:600:0:U",
                        "DS:out_ex:DERIVE:600:0:U",
			"RRA:AVERAGE:0.5:1:864",
			"RRA:AVERAGE:0.5:6:672",
			"RRA:AVERAGE:0.5:24:732";
	}

	# insert values into rrd
	RRDs::update "$rrd/$attr->{NAME}.rrd",
		"-t", "in:out:in_ex:out_ex",
		"N:$attr->{IN}:$attr->{OUT}:$attr->{IN_EX}:$attr->{OUT_EX}";


}


1
