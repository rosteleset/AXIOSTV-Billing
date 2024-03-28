package Cisco_isg;
# Cisco_isg AAA functions
# FreeRadius DHCP  functions
# http://www.cisco.com/en/US/docs/ios/12_2sb/isg/coa/guide/isgcoa4.html

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.12;
@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = ();
%EXPORT_TAGS = ();

# User name expration
use main;
use Billing;
use Auth;

@ISA  = ("main");
my ($db, $conf, $Billing);

my %RAD_REPLY=();


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $conf) = @_;
  my $self = { };
  bless($self, $class);

  my $Auth = Auth->new($db, $conf);
  $Billing = Billing->new($db, $conf);  

  return $self;
}

#**********************************************************
# user_info
#**********************************************************
sub user_info {
  my $self = shift;
  my ($RAD_REQUEST, $NAS) = @_;

  my $WHERE;
  if ($RAD_REQUEST->{'DHCP_MESSAGE_TYPE'}) {
    $WHERE = " and dv.CID='$RAD_REQUEST->{USER_NAME}'";
   }
  else {
    $WHERE = " and dv.CID='$RAD_REQUEST->{USER_NAME}'";
   }

  $self->query($db, "SELECT 
   u.id,
   dv.uid, 
   dv.tp_id, 
   INET_NTOA(dv.ip),
   dv.logins,
   dv.speed,
   dv.disable,
   u.disable,
   u.reduction,
   u.bill_id,
   u.company_id,
   u.credit,
   u.activate,
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),

  tp.payment_type,
  tp.neg_deposit_filter_id,
  tp.credit,
  tp.credit_tresshold,
  tp_int.id,
  count(DISTINCT tp_int.id),
  count(DISTINCT tt.id)

   FROM (dv_main dv, users u)
   LEFT JOIN tarif_plans tp ON  (dv.tp_id=tp.id)
   LEFT JOIN intervals tp_int ON  (tp_int.tp_id=tp.id)
   LEFT JOIN trafic_tarifs tt ON  (tt.interval_id=tp_int.id)
   WHERE    u.uid=dv.uid
   $WHERE
   GROUP BY u.uid;");

  if($self->{TOTAL} < 1) {
    return $self;
   }
  elsif($self->{errno}) {
    return $self;
   }

  ($self->{USER_NAME},
   $self->{UID},
   $self->{TP_ID}, 
   $self->{IP},
   $self->{SIMULTANEOUSLY},
   $self->{SPEED},
   $self->{DV_DISABLE},
   $self->{USER_DISABLE},
   $self->{REDUCTION},
   $self->{BILL_ID},
   $self->{COMPANY_ID},
   $self->{CREDIT},
   $self->{ACCOUNT_ACTIVATE},

   $self->{SESSION_START}, 
   $self->{DAY_BEGIN}, 
   $self->{DAY_OF_WEEK}, 
   $self->{DAY_OF_YEAR},

   $self->{PAYMENT_TYPE},
   $self->{NEG_DEPOSIT_FILTER_ID},
   $self->{TP_CREDIT},
   $self->{CREDIT_TRESSHOLD},
   $self->{INTERVAL_ID},
   $self->{TT_COUNTS},
   $self->{INTERVAL_COUNTS}
  )= @{ $self->{list}->[0] };

  
  #Chack Company account if ACCOUNT_ID > 0
  $self->check_company_account() if ($self->{COMPANY_ID} > 0);
  $self->check_bill_account();

  if($self->{errno}) {
    $RAD_REPLY{'Reply-Message'}=$self->{errstr};
    return 1, \%RAD_REPLY;
   }

  return $self;
}


#**********************************************************
# 
#**********************************************************
sub auth {
  my $self = shift;
  my ($RAD_REQUEST, $NAS) = @_;

  my %RAD_REPLY=();
  
#ISG Section  
#Make TP
  if ($RAD_REQUEST->{USER_NAME} =~ /^TP_/) {
    return  $self->make_tp($RAD_REQUEST);
    }
  elsif ($RAD_REQUEST->{USER_NAME} =~ /\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}/) {
#Get statis DHCP address
    $RAD_REQUEST->{CALLING_STATION_ID}=$RAD_REQUEST->{USER_NAME};
    $self->query($db, "SELECT dhcphosts_hosts.mac
      FROM dhcphosts_hosts, users u
    WHERE dhcphosts_hosts.uid=u.uid 
    and dhcphosts_hosts.ip=INET_ATON('$RAD_REQUEST->{USER_NAME}');");

    if ($self->{TOTAL} > 0) {
      ($RAD_REQUEST->{USER_NAME}
       )= @{ $self->{list}->[0] };
     }
    else {
      if ($conf->{DHCPHOSTS_LEASES} eq 'db') {
        $self->query($db, "SELECT hardware, UNIX_TIMESTAMP(ends)-UNIX_TIMESTAMP() FROM dhcphosts_leases
          WHERE ip=INET_ATON('$RAD_REQUEST->{USER_NAME}');");
 
        if ($self->{TOTAL} > 0) {
          ($RAD_REQUEST->{USER_NAME},
           $RAD_REPLY{'Session-Timeout'}
           )= @{ $self->{list}->[0] };
         }
       }
      else {
        $RAD_REQUEST->{USER_NAME} = get_isg_mac($RAD_REQUEST->{USER_NAME});  
       }
     }

    if ($RAD_REQUEST->{USER_NAME} eq '') {
      $RAD_REPLY{'Reply-Message'}="Can't find MAC in DHCP";
      return 1, \%RAD_REPLY;
     }
   }
  # Free radius dhcp
  elsif ($RAD_REQUEST->{DHCP_CLIENT_HARDWARE_ADDRESS}) {
    $RAD_REQUEST->{USER_NAME}=$RAD_REQUEST->{DHCP_CLIENT_HARDWARE_ADDRESS};
   }  

  $self->user_info($RAD_REQUEST, $NAS);

  if($self->{errno}) {
    $RAD_REPLY{'Reply-Message'}=$self->{errstr};
    return 1, \%RAD_REPLY;
   }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    $RAD_REPLY{'Reply-Message'}="User Not Exist '$RAD_REQUEST->{USER_NAME}'";
    return 1, \%RAD_REPLY;
   }
  elsif (! defined($self->{PAYMENT_TYPE})) {
    $RAD_REPLY{'Reply-Message'}="Service not allow";
    return 1, \%RAD_REPLY;
   }


  $RAD_REPLY{'User-Name'}=$self->{USER_NAME};
  $RAD_REQUEST->{USER_NAME}=$self->{USER_NAME};

#DIsable
if ($self->{DISABLE} ||  $self->{DV_DISABLE} || $self->{USER_DISABLE}) {
  $RAD_REPLY{'Reply-Message'}="Account Disable";
  return 1, \%RAD_REPLY;
}

my $service = "TP_$self->{TP_ID}"; 
#$self->{PAYMENT_TYPE} = 1;
if ($self->{PAYMENT_TYPE} == 0) {
  $self->{CREDIT} = $self->{TP_CREDIT} if ($self->{CREDIT} == 0);

  $self->{DEPOSIT}=$self->{DEPOSIT}+$self->{CREDIT} - $self->{CREDIT_TRESSHOLD};
  #Check deposit

  if($self->{DEPOSIT}  <= 0) {
    if (! $self->{NEG_DEPOSIT_FILTER_ID}) {
      $RAD_REPLY{'Reply-Message'}="Negativ deposit '$self->{DEPOSIT}'. Rejected!";
      return 1, \%RAD_REPLY;
     }
    $service = $self->{NEG_DEPOSIT_FILTER_ID};
   }
}
else {
  $self->{DEPOSIT}=0;
}



if ($NAS->{NAS_TYPE} eq 'dhcp') {
  # Do nothing if port is magistral, i.e. 25.26.27.28
  #if($port == 25 || $port == 26 || $port == 27 || $port == 28) {
  #   &radiusd::radlog(L_ERR, " --- Port is gigabit upling, returinig NOOP --- ");
  #   return RLM_MODULE_NOOP;
  # }

  my $REQUEST_TYPE = $RAD_REQUEST->{'DHCP_MESSAGE_TYPE'};

  if ($self->{IP} ne '0.0.0.0') {
    $RAD_REPLY{'DHCP-Your-IP-Address'}=$self->{IP};
   }
  else {
    my $ip = $self->get_ip($NAS->{NAS_ID}, "$RAD_REQUEST->{NAS_IP_ADDRESS}", { TP_IPPOOL => $self->{TP_IPPOOL} });
    if ($ip eq '-1') {
      $RAD_REPLY{'Reply-Message'}="Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS})";
      return 1, \%RAD_REPLY;
     }
    elsif($ip eq '0') {
      #$RAD_REPLY->{'Reply-Message'}="$self->{errstr} ($NAS->{NAS_ID})";
      #return 1, $RAD_REPLY;
     }
    else {
      $RAD_REPLY{'DHCP-Your-IP-Address'} = "$ip";
     }
   }

   $RAD_REPLY{'DHCP-Subnet-Mask'}        = '255.255.255.255';
   $RAD_REPLY{'DHCP-IP-Address-Lease-Time'} = 86000;

   if($REQUEST_TYPE eq "DHCP-Request") {
#      # Writing lease to DB
#      $dbh->do("INSERT INTO ip_dhcp_leases(date_leased, date_updated, ip, mask, gw, mac, switch, port)
#                                VALUES(unix_timestamp(), unix_timestamp(), inet_aton('$ip'), inet_aton('$mask'), inet_aton('$gw'),
#                                '$UMAC', '$switch', '$port')");
#      &radiusd::radlog(L_ERR, " --- DHCP-Request END.Lease writen. --- ") if $DEBUG;
#                                return RLM_MODULE_OK;
    }
   elsif($REQUEST_TYPE eq "DHCP-Discover") {
     # Just return OK
#     &radiusd::radlog(L_ERR, " --- RLM_MODULE_OK ---") if $DEBUG;
     return 2;
    }
   
   #$self->dhcp_accounting($RAD_REQUEST, $NAS);
 }
#Cisco ISG section
else {
  #IP
  if ($self->{IP} ne '0.0.0.0') {
    $RAD_REPLY{'Framed-IP-Address'}=$self->{IP};
   }

  my $debug = 0;
  if ($self->{TT_COUNTS} > 0) {
    $self->query($db, "SELECT id FROM trafic_tarifs WHERE interval_id='$self->{INTERVAL_ID}';");
    foreach my $line ( @{ $self->{list} }) {
      push @{ $RAD_REPLY{'Cisco-Account-Info'} }, "ATP_$self->{TP_ID}_$line->[0]";
     }
   }
  else {
    push @{ $RAD_REPLY{'Cisco-Account-Info'} }, "A$service";
  }

  if ($service =~ /^TP/) {
    push @{ $RAD_REPLY{'Cisco-Account-Info'} }, "NTURBO_SPEED1";
    push @{ $RAD_REPLY{'Cisco-Account-Info'} }, "NTURBO_SPEED2";
    push @{ $RAD_REPLY{'Cisco-Account-Info'} }, "NTURBO_SPEED3";
   }
  push @{ $RAD_REPLY{'cisco-avpair'} }, "subscriber:accounting-list=BH_ACCNT_LIST1";

  $RAD_REPLY{'Idle-Timeout'} = 1800;
  $RAD_REPLY{'Acct-Interim-Interval'}=6000;
}

  return 0, \%RAD_REPLY;
}

#**********************************************************
#
#**********************************************************
sub dhcp_accounting {
  my $self = shift;
  my ($RAD_REQUEST, $NAS) = @_;

  
  return $self;
}


#**********************************************************
#
# Make TP RAD pairs
#**********************************************************
sub make_tp {
  my $self = shift;
  my ($RAD_REQUEST, $NAS) = @_;

  my %speeds = ();
  my %expr   = ();
  my %names  = ();
  my $TP_ID  = 0;
  my $TT_ID  = 0;
  my $debug  = 0;

  if ($RAD_REQUEST->{USER_NAME} =~ /TP_(\d+)_(\d+)/) {
    $TP_ID = $1;
    $TT_ID = $2;
   }
  elsif ($RAD_REQUEST->{USER_NAME} =~ /TP_(\d+)/) {
    $TP_ID = $1;
   }
  my $RAD_REPLY ;


$self->query($db, "select  
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  tp.rad_pairs,
  tt.in_speed,
  tt.out_speed
     FROM tarif_plans tp
     LEFT JOIN intervals i ON (tp.id = i.tp_id)
     LEFT JOIN trafic_tarifs tt ON (tt.interval_id = i.id)
     WHERE tp.id='$TP_ID' and tt.id='$TT_ID'
  ;");


  if($self->{errno}) {
    $RAD_REPLY->{'Reply-Message'}='SQL error';
    return 1, $RAD_REPLY;
   }
  elsif ($self->{TOTAL} < 1) {
    $RAD_REPLY->{'Reply-Message'}="Can't find TP '$TP_ID' TT: '$TT_ID'";
    return 1, $RAD_REPLY;
   }

   (
     $self->{SESSION_START}, 
     $self->{DAY_BEGIN}, 
     $self->{DAY_OF_WEEK}, 
     $self->{DAY_OF_YEAR},
     $self->{TP_RAD_REPLY},
     $self->{IN_SPEED},
     $self->{OUT_SPEED}
    ) = @{ $self->{list}->[0] };

#chack TP Radius Pairs

  if ($TT_ID > 0) {
     push @{ $RAD_REPLY->{'cisco-avpair'} }, "ip:traffic-class=input access-group name ACL_IN_INTERNET_$TT_ID priority ". (($TT_ID + 1) * 100);
     push @{ $RAD_REPLY->{'cisco-avpair'} }, "ip:traffic-class=output access-group name ACL_OUT_INTERNET_$TT_ID priority ". (($TT_ID + 1) * 100);
     push @{ $RAD_REPLY->{'cisco-avpair'} }, "ip:traffic-class=out default drop";
     push @{ $RAD_REPLY->{'cisco-avpair'} }, "ip:traffic-class=in default drop";
     push @{ $RAD_REPLY->{'cisco-avpair'} }, "subscriber:accounting-list=BH_ACCNT_LIST_$TT_ID";
    }
  else {

  if ($self->{TP_RAD_REPLY}) {
    my @p = split(/,/, $self->{TP_RAD_REPLY});
    foreach my $line (@p) {
      if ($line =~ /([a-zA-Z0-9\-]{6,25})\+\=(.{1,200})/gi) {
        my $left = $1;
        my $right= $2;
        $right =~ s/\"//g;
        push @{ $RAD_REPLY->{"$left"} }, $right; 
       }      
      else {
         my($left, $right)=split(/=/, $line, 2);
         if ($left =~ s/^!//) {
           delete $RAD_REPLY->{"$left"};
           }
          else {  
            $RAD_REPLY->{"$left"}="$right";
           }
       }
     }
   }
}


    ($self->{TIME_INTERVALS},
     $self->{INTERVAL_TIME_TARIF}, 
     $self->{INTERVAL_TRAF_TARIF}) = $Billing->time_intervals($TP_ID);

    my ($remaining_time, $ret_attr) = $Billing->remaining_time(0, {
          TIME_INTERVALS      => $self->{TIME_INTERVALS},
          INTERVAL_TIME_TARIF => $self->{INTERVAL_TIME_TARIF},
          INTERVAL_TRAF_TARIF => $self->{INTERVAL_TRAF_TARIF},
          SESSION_START       => $self->{SESSION_START},
          DAY_BEGIN           => $self->{DAY_BEGIN},
          DAY_OF_WEEK         => $self->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $self->{DAY_OF_YEAR},
          REDUCTION           => 0,
          POSTPAID            => 1,
          GET_INTERVAL        => 1
#          debug               => ($debug > 0) ? 1 : undef
         });
#
##    print "RT: $remaining_time\n"  if ($debug == 1);
    my %TT_IDS = %$ret_attr;


    if (keys %TT_IDS > 0) {
      require Tariffs;
      Tariffs->import();
      my $tariffs = Tariffs->new($db, $conf, undef);

      #Get intervals
      while(my($k, $v)=each( %TT_IDS)) {
        #print "> $k, $v\n" if ($debug > 0);
         next if ($k ne 'TT');
         my $list = $tariffs->tt_list({ TI_ID => $v });
         foreach my $line (@$list)  {
           $speeds{$line->[0]}{IN}="$line->[4]";
           $speeds{$line->[0]}{OUT}="$line->[5]";
           $names{$line->[0]}= ($line->[6]) ? "$line->[6]" : "Service_$line->[0]";
           $expr{$line->[0]}="$line->[8]" if (length($line->[8]) > 5);
           #print "$line->[0] $line->[6] $line->[4]\n";
          }
       }
    }
  
#   }
#
#
#  
#print "Expresion:================================\n" if ($debug > 0);
#  my $RESULT = $Billing->expression($self->{UID}, \%expr, { START_PERIOD => $self->{ACCOUNT_ACTIVATE}, 
#                                                          debug        => $debug } );
#print "\nEND: =====================================\n" if ($debug > 0);
#  
#  if (! $RESULT->{SPEED}) {
#    $speeds{0}{IN}=$RESULT->{SPEED_IN} if($RESULT->{SPEED_IN});
#    $speeds{0}{OUT}=$RESULT->{SPEED_OUT} if($RESULT->{SPEED_OUT});
#   }
#  else {
#    $speeds{0}{IN}=$RESULT->{SPEED};
#    $speeds{0}{OUT}=$RESULT->{SPEED};
#   }
#
#  
#  #Make speed

    my $speed = $speeds{$TT_ID};
    
    my $speed_in  = (defined($speed->{IN}))  ? $speed->{IN}  : 0;
    my $speed_out = (defined($speed->{OUT})) ? $speed->{OUT} : 0;
  
    my $speed_in_rule = '';
    my $speed_out_rule = '';

    if ($speed_in > 0) {
      $speed_in_rule = "D;" . ($speed_in * 1000) .";". 
      ( $speed_in / 8 * 1000 ).';'.
      ( $speed_in / 4 * 1000 ).';';
     }

    if ($speed_out > 0) {
      $speed_out_rule = "U;". ($speed_out * 1000 ) .";". 
      ( $speed_out / 8 * 1000 ).';'.
      ( $speed_out / 4 * 1000 );
     }

    
    if ($speed_in_rule ne '' || $speed_out_rule ne '') {
      $RAD_REPLY->{'Cisco-Service-Info'} = "Q$speed_out_rule;$speed_in_rule";
     }

  return 0, $RAD_REPLY;
}



#**********************************************************
# Get MAC from hcl leaseds
#**********************************************************
sub get_isg_mac {
  my ($ip) = @_;

  my $logfile = $conf->{DHCPHOSTS_LEASES} || '/var/db/dhcpd/dhcpd.leases';
  my %list = ();
  my $l_ip = ();

 open (FILE, "$logfile") or print "Can't read file '$logfile' $!";
   while (<FILE>) {
      next if /^#|^$/;

      if (/^lease (\d+\.\d+\.\d+\.\d+)/) {
         $l_ip = $1; 
         $list{$ip}{ip}=sprintf("%-17s", $ip);
       }
      elsif (/^\s*hardware ethernet (.*);/) {
        my $mac = $1;
        if ($ip eq $l_ip) {
          $list{$ip}{hardware}=sprintf("%s", $mac);
          last if ($list{$ip}{active});
         }
       }
      elsif (/^\s+binding state active/) {
         $list{$l_ip}{active}=1;
       }
   }
 close FILE;
  
  return ($list{$ip}{hardware}) ?  $list{$ip}{hardware} : '';
}


1
