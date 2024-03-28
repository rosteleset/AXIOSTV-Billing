package Acct3 v2.2.0;

=head1 NAME

  Accounting functions

=cut

use strict;
use parent 'main';
use Billing;

my ($conf);
my $Billing;
my $input_gigawords='Acct-Output-Gigawords';
my $output_gigawords='Acct-Input-Gigawords';

my %ACCT_TYPES = (
  'Start'          => 1,
  'Stop'           => 2,
  'Alive'          => 3,
  'Interim-Update' => 3,
  'Accounting-On'  => 7,
  'Accounting-Off' => 8
);

my %ACCT_TERMINATE_CAUSES = (
  'User-Request'             => 1,
  'Lost-Carrier'             => 2,
  'Lost-Service'             => 3,
  'Idle-Timeout'             => 4,
  'Session-Timeout'          => 5,
  'Admin-Reset'              => 6,
  'Admin-Reboot'             => 7,
  'Port-Error'               => 8,
  'NAS-Error'                => 9,
  'NAS-Request'              => 10,
  'NAS-Reboot'               => 11,
  'Port-Unneeded'            => 12,
  'Port-Preempted'           => 13,
  'Port-Suspended'           => 14,
  'Service-Unavailable'      => 15,
  'Callback'                 => 16,
  'User-Error'               => 17,
  'Host-Request'             => 18,
  'Supplicant-Restart'       => 19,
  'Reauthentication-Failure' => 20,
  'Port-Reinit'              => 21,
  'Port-Disabled'            => 22,
  'Lost-Alive'               => 23,
);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($conf)   = @_;

  my $self = {};
  bless($self, $class);

  $self->{db}=$db;
  $Billing = Billing->new($db, $conf);
  $Billing->{INTERNET}=1;

  return $self;
}

#**********************************************************
=head2  accounting($RAD, $NAS) - Accounting Work_

=cut
#**********************************************************
sub accounting {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  $self->{SUM}              = 0 if (!$self->{SUM});
  my $acct_status_type      = $ACCT_TYPES{ $RAD->{'Acct-Status-Type'} };
  $RAD->{$input_gigawords}  = 0 if (!$RAD->{$input_gigawords});
  $RAD->{$output_gigawords} = 0 if (!$RAD->{$output_gigawords});

  $RAD->{'Framed-IP-Address'}     = '0.0.0.0' if (!$RAD->{'Framed-IP-Address'});
  $RAD->{'Acct-Session-Time'}     = 0         if (!defined($RAD->{'Acct-Session-Time'}));
  if (length($RAD->{'Acct-Session-Id'}) > 36) {
    $RAD->{'Acct-Session-Id'} = substr($RAD->{'Acct-Session-Id'}, 0, 36);
  }

  if ($NAS->{NAS_TYPE} eq 'cid_auth') {
    $self->query2("SELECT u.uid, u.id
     FROM users u, internet_main internet WHERE internet.uid=u.uid AND internet.CID= ? ;",
      undef, { Bind => [ $RAD->{'Calling-Station-Id'} ]}
    );

    if ($self->{TOTAL} < 1) {
      $RAD->{'User-Name'} = $RAD->{'Calling-Station-Id'};
    }
    else {
      $RAD->{'User-Name'} = $self->{list}->[0]->[1];
    }
  }
  elsif($NAS->{NAS_TYPE} eq 'accel_ipoe') {
  }
  elsif ( $NAS->{NAS_TYPE} eq 'huawei_me60' ) {
    if ($RAD->{'User-Name'} =~ /^[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}\@\S+$/) {
      $RAD->{'Framed-Protocol'} = 'IPOE';
    }
  }

  #Get cisco session id
  if ($RAD->{'Cisco-Service-Info'}) {
    $RAD->{'Connect-Info'} = $RAD->{'Cisco-Service-Info'};
    if (ref $RAD->{'Cisco-AVPair'} eq 'ARRAY') {
      foreach my $params (@{ $RAD->{'Cisco-AVPair'} }) {
        if ($params =~ /parent-session-id=(.+)/) {
          $RAD->{'Acct-Session-Id'} = $1;
          last;
        }
      }
    }
    else {
      if ($RAD->{'Cisco-AVPair'} && $RAD->{'Cisco-AVPair'} =~ /parent-session-id=(.+)/) {
        $RAD->{'Acct-Session-Id'} = $1;
      }
    }
  }

  #Start
  if ($acct_status_type == 1) {
    $self->query2("SELECT acct_session_id, uid FROM internet_online
    WHERE user_name= ?
      AND nas_id= ?
      AND (framed_ip_address=INET_ATON( ? )
      OR framed_ip_address=0) FOR UPDATE;",
      undef,
      { Bind => [
          $RAD->{'User-Name'},
          $NAS->{NAS_ID},
          $RAD->{'Framed-IP-Address'}
        ] }
    );

    if ($self->{TOTAL} > 0) {
      foreach my $line (@{ $self->{list} }) {
        if ($line->[0] eq 'IP' || $line->[0] eq $RAD->{'Acct-Session-Id'}) {
          $self->{UID}=$line->[1];
          $self->query2("UPDATE internet_online SET
           status= ? ,
           started=NOW() - INTERVAL ? SECOND,
           lupdated=UNIX_TIMESTAMP(),
           nas_port_id= ? ,
           acct_session_id= ? ,
           cid= ? ,
           connect_info= ?
           WHERE user_name= ?
             AND nas_id= ?
             AND (acct_session_id='IP' OR acct_session_id= ? )
             AND (framed_ip_address=INET_ATON( ? ) OR framed_ip_address=0)
           ORDER BY started
           LIMIT 1;", 'do',
            { Bind => [
                $acct_status_type,
                $RAD->{'Acct-Session-Time'} || 0,
                $RAD->{'NAS-Port'} || 0,
                $RAD->{'Acct-Session-Id'},
                $RAD->{'Calling-Station-Id'},
                $RAD->{'Connect-Info'},
                $RAD->{'User-Name'},
                $NAS->{'NAS_ID'},
                $RAD->{'Acct-Session-Id'},
                $RAD->{'Framed-IP-Address'} ]
            });

          if (! $self->{errno}) {
            return $self;
          }

          last;
        }
      }
    }
    # If not found auth records and session > 2 sec
    else { #if($RAD->{'Acct-Session-Time'} && $RAD->{'Acct-Session-Time'} > 2) {
      $self->add_unknown_session($RAD, $NAS, { ACCT_STATUS_TYPE => $acct_status_type });
    }
    # Ignoring quick alive rad packets
    #else {
    #
    #}
  }

  # Stop status
  elsif ($acct_status_type == 2) {

    $RAD->{'Acct-Terminate-Cause'} = ($RAD->{'Acct-Terminate-Cause'} && defined($ACCT_TERMINATE_CAUSES{$RAD->{'Acct-Terminate-Cause'}})) ? $ACCT_TERMINATE_CAUSES{$RAD->{'Acct-Terminate-Cause'}} : 0;

    #IPN Service
    if ($NAS->{NAS_EXT_ACCT} || $NAS->{NAS_TYPE} eq 'ipcad') {
      $self->query2("SELECT
       online.acct_input_octets AS inbyte,
       online.acct_output_octets AS outbyte,
       online.acct_input_gigawords,
       online.acct_output_gigawords,
       online.ex_input_octets AS inbyte2,
       online.ex_output_octets AS outbyte2,
       online.tp_id AS tarif_plan,
       online.sum,
       online.uid,
       u.bill_id,
       u.company_id
    FROM internet_online online
    INNER JOIN users u ON (online.uid=u.uid)
    WHERE online.user_name= ?
      AND online.acct_session_id= ? ;",
        undef,
        { INFO => 1,
          Bind => [ $RAD->{'User-Name'} || '',
            $RAD->{'Acct-Session-Id'}
          ] }
      );

      if ($self->{errno}) {
        if ($self->{errno} == 2) {
          $self->{errno}  = 2;
          $self->{errstr} = "Session account Not Exist '". $RAD->{'Acct-Session-Id'} ."'";
          return $self;
        }
        return $self;
      }

      if ($self->{COMPANY_ID} > 0) {
        $self->query2("SELECT bill_id FROM companies WHERE id= ? ;", undef, { Bind => [ $self->{COMPANY_ID} ] });
        if ($self->{TOTAL} < 1) {
          $self->{errno}  = 2;
          $self->{errstr} = "Company not exists '$self->{COMPANY_ID}'";
          return $self;
        }
        ($self->{BILL_ID}) = @{ $self->{list}->[0] };
      }

      # if ($self->{INBYTE} > 4294967296) {
      #   $RAD->{$input_gigawords} = int($self->{INBYTE} / 4294967296);
      #   $RAD->{INBYTE}           = $self->{INBYTE} - $RAD->{$input_gigawords} * 4294967296;
      # }
      #
      # if ($self->{OUTBYTE} > 4294967296) {
      #   $RAD->{$output_gigawords} = int($self->{OUTBYTE} / 4294967296);
      #   $RAD->{OUTBYTE}           = $self->{OUTBYTE} - $RAD->{$output_gigawords} * 4294967296;
      # }

      my $ipv6 = '';
      if ($conf->{IPV6} && $RAD->{'Framed-IPv6-Prefix'}) {
        my $interface_id = $RAD->{'Framed-Interface-Id'} || q{};
        $interface_id =~ s/\/\d+//g;
        $ipv6 =  ", framed_ipv6_prefix =INET6_ATON('". $RAD->{'Framed-IPv6-Prefix'}.'::'.$interface_id ."')";
      }

      if ($self->{UID} > 0) {
        $self->query2("INSERT INTO internet_log SET
          uid= ? ,
          start=NOW() - INTERVAL ? SECOND,
          tp_id= ? ,
          duration= ? ,
          sent= ? ,
          recv= ? ,
          sum= ? ,
          nas_id= ? ,
          port_id= ? ,
          ip=INET_ATON( ? ),
          cid= ? ,
          sent2= ? ,
          recv2= ? ,
          acct_session_id= ? ,
          bill_id= ? ,
          terminate_cause= ? ,
          acct_input_gigawords= ? ,
          acct_output_gigawords= ?
          $ipv6",
          'do',
          { Bind => [
              $self->{UID} || 0,
              $RAD->{'Acct-Session-Time'},
              $self->{TARIF_PLAN},
              $RAD->{'Acct-Session-Time'},
              $RAD->{OUTBYTE},
              $RAD->{INBYTE},
              $self->{SUM},
              $NAS->{NAS_ID},
              $RAD->{'NAS-Port'} || 0,
              $RAD->{'Framed-IP-Address'},
              $RAD->{'Calling-Station-Id'} || '_1',
              $self->{OUTBYTE2},
              $self->{INBYTE2},
              $RAD->{'Acct-Session-Id'},
              $self->{BILL_ID},
              $RAD->{'Acct-Terminate-Cause'},
              $RAD->{$input_gigawords},
              $RAD->{$output_gigawords}
            ] }
        );
      }
    }
    elsif ($conf->{rt_billing}) {
      $self->rt_billing($RAD, $NAS);
      if ($self->{errno}) {
        #DEbug only
        if ($conf->{ACCT_DEBUG}) {
          require POSIX;
          POSIX->import(qw( strftime ));
          my $DATE_TIME = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time));
          `echo "$DATE_TIME $self->{UID} - $RAD->{'User-Name'} / $RAD->{'Acct-Session-Id'} / Time: $RAD->{'Acct-Session-Time'} / $self->{errstr}" >> /tmp/unknown_session.log`;
        }

        ($self->{UID},
         $self->{SUM},
         $self->{BILL_ID},
         $self->{TARIF_PLAN},
         $self->{TIME_TARIF},
         $self->{TRAF_TARIF}) = $Billing->session_sum($RAD->{'User-Name'},
                 time - $RAD->{'Acct-Session-Time'},
                 $RAD->{'Acct-Session-Time'},
                 $RAD,
          { SERVICE_ID => $self->{SERVICE_ID} }
        );
      }
      else {
        $self->{SUM} += $self->{CALLS_SUM};
      }

      $self->query2("INSERT INTO internet_log SET
          uid= ? ,
          start=NOW() - INTERVAL ? SECOND,
          tp_id= ? ,
          duration= ? ,
          sent= ? ,
          recv= ? ,
          sum= ? ,
          nas_id= ? ,
          port_id= ? ,
          ip=INET_ATON( ? ),
          CID= ? ,
          sent2= ? ,
          recv2= ? ,
          acct_session_id= ? ,
          bill_id= ? ,
          terminate_cause= ? ,
          acct_input_gigawords= ? ,
          acct_output_gigawords= ? ",
        'do',
        { Bind => [
            $self->{UID},
            $RAD->{'Acct-Session-Time'},
            $self->{TARIF_PLAN} || $self->{TP_ID} || 0,
            $RAD->{'Acct-Session-Time'},
            $RAD->{OUTBYTE},
            $RAD->{INBYTE},
            $self->{SUM} || 0,
            $NAS->{NAS_ID},
            $RAD->{'NAS-Port'} || 0,
            $RAD->{'Framed-IP-Address'},
            $RAD->{'Calling-Station-Id'} || '_2',
            $RAD->{OUTBYTE2},
            $RAD->{INBYTE2},
            $RAD->{'Acct-Session-Id'},
            $self->{BILL_ID},
            $RAD->{'Acct-Terminate-Cause'},
            $RAD->{$input_gigawords},
            $RAD->{$output_gigawords}
          ] }
      );

      if ($self->{errno}) {
        print "Error: [$self->{errno}] $self->{errstr}\n";
      }
    }
    else {
      my %EXT_ATTR = ();

      #Get connected TP
      $self->query2("SELECT uid, tp_id, connect_info, service_id FROM internet_online WHERE
          acct_session_id= ? AND nas_id= ? ;",
        undef,
        { Bind => [ $RAD->{'Acct-Session-Id'}, $NAS->{NAS_ID} ]}
      );

      ($EXT_ATTR{UID}, $EXT_ATTR{TP_ID}, $EXT_ATTR{CONNECT_INFO}, $EXT_ATTR{SERVICE_ID}) =
        @{ $self->{list}->[0] } if ($self->{TOTAL} > 0);

      ($self->{UID},
        $self->{SUM},
        $self->{BILL_ID},
        $self->{TARIF_PLAN},
        $self->{TIME_TARIF},
        $self->{TRAF_TARIF}) = $Billing->session_sum($RAD->{'User-Name'},
        (time - $RAD->{'Acct-Session-Time'}),
        $RAD->{'Acct-Session-Time'},
        $RAD,
        \%EXT_ATTR);

      $self->{TARIF_PLAN} //= $EXT_ATTR{TP_ID};
      #  return $self;
      if ($self->{UID} == -2) {
        $self->{errno}  = 1;
        $self->{errstr} = "ACCT [". $RAD->{'User-Name'} ."] Not exist";
      }
      elsif ($self->{UID} == -3) {
        my $filename      = $RAD->{'User-Name'}.$RAD->{'Acct-Session-Id'};
        $RAD->{SQL_ERROR} = "$Billing->{errno}:$Billing->{errstr}";
        $self->{errno}    = 1;
        $self->{errstr}   = "SQL Error ($Billing->{errstr}) SESSION: '$filename'";
        $Billing->mk_session_log($RAD);
        return $self;
      }
      elsif ($self->{SUM} < 0) {
        $self->{LOG_DEBUG} = "ACCT [". $RAD->{'User-Name'} ."] small session (".
          $RAD->{'Acct-Session-Time'} .", $RAD->{INBYTE}, $RAD->{OUTBYTE})";
      }
      elsif ($self->{UID} <= 0) {
        $self->{LOG_DEBUG} = 'ACCT ['. $RAD->{'User-Name'} ."] small session (".
          $RAD->{'Acct-Session-Time'} .", $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
      }
      else {
        $self->query2("INSERT INTO internet_log SET
          uid= ? ,
          start=NOW() - INTERVAL ? SECOND,
          tp_id= ? ,
          duration= ? ,
          sent= ? ,
          recv= ? ,
          sum= ? ,
          nas_id= ? ,
          port_id= ? ,
          ip=INET_ATON( ? ),
          CID= ? ,
          sent2= ? ,
          recv2= ? ,
          acct_session_id= ? ,
          bill_id= ? ,
          terminate_cause= ? ,
          acct_input_gigawords= ? ,
          acct_output_gigawords= ? ",
          'do',
          { Bind => [ $self->{UID},
              $RAD->{'Acct-Session-Time'},
              $self->{TARIF_PLAN} || $EXT_ATTR{TP_ID},
              $RAD->{'Acct-Session-Time'},
              $RAD->{OUTBYTE},
              $RAD->{INBYTE},
              $self->{SUM},
              $NAS->{NAS_ID},
              $RAD->{'NAS-Port'} || 0,
              $RAD->{'Framed-IP-Address'},
              $RAD->{'Calling-Station-Id'} || '',
              $RAD->{OUTBYTE2},
              $RAD->{INBYTE2},
              $RAD->{'Acct-Session-Id'},
              $self->{BILL_ID},
              $RAD->{'Acct-Terminate-Cause'},
              $RAD->{$input_gigawords},
              $RAD->{$output_gigawords}
            ] }
        );

        if ($self->{errno}) {
          my $filename = $RAD->{'User-Name'}.$RAD->{'Acct-Session-Id'};
          $self->{LOG_WARNING} = "ACCT [". $RAD->{'User-Name'} ."] Making accounting file '$filename'";
          $Billing->mk_session_log($RAD);
        }

        # If SQL query filed
        else {
          if ($self->{SUM} > 0) {
            $self->query2("UPDATE bills SET deposit=deposit - ? WHERE id= ? ;", 'do',
              { Bind => [  $self->{SUM}, $self->{BILL_ID} ]});
          }
        }
      }
    }

    # Delete from session
    $self->query2("DELETE FROM internet_online WHERE acct_session_id= ? AND nas_id= ? ;",
      'do', { Bind => [ $RAD->{'Acct-Session-Id'}, $NAS->{NAS_ID} ] });
  }

  #Alive status 3
  elsif ($acct_status_type eq 3) {
    $self->{SUM} = 0 if (!$self->{SUM});
    if ($NAS->{NAS_EXT_ACCT}) {
      my $ipn_fields = '';
      if ($NAS->{IPN_COLLECTOR}) {
        $ipn_fields = "sum=sum+$self->{SUM},
      acct_input_octets='$RAD->{INBYTE}',
      acct_output_octets='$RAD->{OUTBYTE}',
      ex_input_octets=ex_input_octets + $RAD->{INBYTE2},
      ex_output_octets=ex_output_octets + $RAD->{OUTBYTE2},
      acct_input_gigawords='". $RAD->{$input_gigawords} ."',
      acct_output_gigawords='". $RAD->{$output_gigawords} ."',";
      }

      $self->query2("UPDATE internet_online SET
        $ipn_fields
        status= ? ,
        acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
        framed_ip_address=INET_ATON( ? ),
        lupdated=UNIX_TIMESTAMP()
      WHERE
        acct_session_id= ? AND
        user_name= ? AND
        nas_id= ? ;", 'do', {
          Bind => [ $acct_status_type,
            $RAD->{'Framed-IP-Address'},
            $RAD->{'Acct-Session-Id'},
            $RAD->{'User-Name'} || '',
            $NAS->{NAS_ID}
          ]   });

      return $self;
    }
    elsif ($NAS->{NAS_TYPE} eq 'ipcad') {
      return $self;
    }
    elsif ($conf->{rt_billing}) {
      $self->rt_billing($RAD, $NAS);
      #add unknown session
      if ($self->{errno}) {
        if ($self->{errno}  == 2 && ($RAD->{'Acct-Session-Time'} && $RAD->{'Acct-Session-Time'} > 2)) {
          $self->add_unknown_session($RAD, $NAS, { ACCT_STATUS_TYPE => $acct_status_type });
          return $self;
        }
        #else {
        #
        #}
      }
    }

    my $ex_octets = '';
    if ($RAD->{INBYTE2} || $RAD->{OUTBYTE2}) {
      $ex_octets = "ex_input_octets='$RAD->{INBYTE2}',  ex_output_octets='$RAD->{OUTBYTE2}', ";
    }

    $self->query2("UPDATE internet_online SET
      status= ? ,
      acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
      acct_input_octets= ? ,
      acct_output_octets= ? ,
      $ex_octets
      framed_ip_address=INET_ATON( ? ),
      lupdated=UNIX_TIMESTAMP(),
      sum=sum + ? ,
      acct_input_gigawords= ? ,
      acct_output_gigawords= ?
    WHERE
      acct_session_id= ?
      AND user_name= ?
      AND nas_id= ? ;", 'do',
      { Bind => [
          $acct_status_type,
          $RAD->{'INBYTE'},
          $RAD->{'OUTBYTE'},
          $RAD->{'Framed-IP-Address'},
          $self->{'SUM'},
          $RAD->{$input_gigawords},
          $RAD->{$output_gigawords},
          $RAD->{'Acct-Session-Id'},
          $RAD->{'User-Name'} || '',
          $NAS->{'NAS_ID'} || 0
        ]}
    );
  }
  else {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [". $RAD->{'User-Name'} ."] Unknown accounting status: ". $RAD->{'Acct-Status-Type'}." (". $RAD->{'Acct-Session-Id'} .")";
    return $self;
  }

  if ($self->{errno}) {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT ". $RAD->{'Acct-Status-Type'} ." SQL Error '". $RAD->{'Acct-Session-Id'} ."'";
    return $self;
  }

  #detalization for Exppp
  if ($conf->{s_detalization} && $self->{UID}) {
    $self->query2("INSERT INTO s_detail (acct_session_id, nas_id, acct_status, last_update, recv1, sent1, recv2, sent2, uid, sum)
       VALUES (?, ?, ?, UNIX_TIMESTAMP(), ?, ?, ?, ?, ?, ?);",
      'do',
      { Bind => [
          $RAD->{'Acct-Session-Id'},
          $NAS->{NAS_ID},
          $acct_status_type,
          $RAD->{INBYTE} +  (($RAD->{$input_gigawords})  ? $RAD->{$input_gigawords} * 4294967296  : 0),
          $RAD->{OUTBYTE} + (($RAD->{$output_gigawords}) ? $RAD->{$output_gigawords} * 4294967296 : 0),
          $RAD->{INBYTE2}  || 0,
          $RAD->{OUTBYTE2} || 0,
          $self->{UID} || 0,
          $self->{SUM}
        ]}
    );
  }

  return $self;
}

#**********************************************************
=head2 rt_billing($RAD, $NAS) Alive accounting

=cut
#**********************************************************
sub rt_billing {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  if (! $RAD->{'Acct-Session-Id'}) {
    $self->{errno}  = 2;
    $self->{errstr} = "Session account rt Not Exist '$RAD->{'Acct-Session-Id'}'";
    return $self;
  }

  $self->query2("SELECT IF(UNIX_TIMESTAMP() > lupdated, lupdated, 0), UNIX_TIMESTAMP()-lupdated,
   IF($RAD->{INBYTE}   >= acct_input_octets AND ". $RAD->{$input_gigawords} ."=acct_input_gigawords,
        $RAD->{INBYTE} - acct_input_octets,
        IF(". $RAD->{$input_gigawords} ." > acct_input_gigawords, 4294967296 * (". $RAD->{$input_gigawords} ." - acct_input_gigawords) + $RAD->{INBYTE} - acct_input_octets, 0)),

   IF($RAD->{OUTBYTE}  >= acct_output_octets AND ". $RAD->{$output_gigawords} ."=acct_output_gigawords,
        $RAD->{OUTBYTE} - acct_output_octets,
        IF(". $RAD->{$output_gigawords} ." > acct_output_gigawords, 4294967296 * (". $RAD->{$output_gigawords} ." - acct_output_gigawords) + $RAD->{OUTBYTE} - acct_output_octets, 0)),
   IF($RAD->{INBYTE2}  >= ex_input_octets, $RAD->{INBYTE2}  - ex_input_octets, ex_input_octets),
   IF($RAD->{OUTBYTE2} >= ex_output_octets, $RAD->{OUTBYTE2} - ex_output_octets, ex_output_octets),
   sum,
   tp_id,
   uid,
   service_id
   FROM internet_online
  WHERE nas_id='$NAS->{NAS_ID}' AND acct_session_id='". $RAD->{'Acct-Session-Id'} ."';");

  if ($self->{errno}) {
    return $self;
  }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = "Session account rt Not Exist '$RAD->{'Acct-Session-Id'}'";
    return $self;
  }

  ($RAD->{INTERIUM_SESSION_START},
    $RAD->{INTERIUM_ACCT_SESSION_TIME},
    $RAD->{INTERIUM_INBYTE},
    $RAD->{INTERIUM_OUTBYTE},
    $RAD->{INTERIUM_INBYTE1},
    $RAD->{INTERIUM_OUTBYTE1},
    $self->{CALLS_SUM},
    $self->{TP_ID},
    $self->{UID},
    $self->{SERVICE_ID}) = @{ $self->{list}->[0] };

  my $out_byte = $RAD->{OUTBYTE} + $RAD->{$output_gigawords} * 4294967296;
  my $in_byte  = $RAD->{INBYTE} + $RAD->{$input_gigawords} * 4294967296;

  ($self->{UID},
    $self->{SUM},
    $self->{BILL_ID},
    $self->{TARIF_PLAN},
    $self->{TIME_TARIF},
    $self->{TRAF_TARIF}) = $Billing->session_sum(
    $RAD->{'User-Name'},
    $RAD->{INTERIUM_SESSION_START},
    $RAD->{INTERIUM_ACCT_SESSION_TIME},
    {
      OUTBYTE  => ($out_byte == $RAD->{INTERIUM_OUTBYTE}) ? $RAD->{INTERIUM_OUTBYTE} : $out_byte - $RAD->{INTERIUM_OUTBYTE},
      INBYTE   => ($in_byte  == $RAD->{INTERIUM_INBYTE}) ? $RAD->{INTERIUM_INBYTE} : $in_byte - $RAD->{INTERIUM_INBYTE},
      OUTBYTE2 => $RAD->{OUTBYTE2} - $RAD->{INTERIUM_OUTBYTE1},
      INBYTE2  => $RAD->{INBYTE2} - $RAD->{INTERIUM_INBYTE1},

      INTERIUM_OUTBYTE  => $RAD->{INTERIUM_OUTBYTE},
      INTERIUM_INBYTE   => $RAD->{INTERIUM_INBYTE},
      INTERIUM_OUTBYTE1 => $RAD->{INTERIUM_OUTBYTE1},
      INTERIUM_INBYTE1  => $RAD->{INTERIUM_INBYTE1},
    },
    {
      FULL_COUNT => 1,
      TP_ID      => $self->{TP_ID},
      SERVICE_ID => $self->{SERVICE_ID},
      UID        => $self->{UID},
      DOMAIN_ID  => ($NAS->{DOMAIN_ID}) ? $NAS->{DOMAIN_ID} : 0,
    }
  );

  #  return $self;
  if ($self->{UID} == -2) {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{'User-Name'}] Not exist";
    return $self;
  }
  elsif ($self->{UID} == -3) {
    my $filename = "$RAD->{'User-Name'}.$RAD->{'Acct-Session-Id'}";
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{'User-Name'}] Not allow start period '$filename'";
    $Billing->mk_session_log($RAD);
    return $self;
  }
  elsif ($self->{UID} == -5) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{'User-Name'}] Can't find TP: $self->{TP_ID} Session id: $RAD->{'Acct-Session-Id'}";
    $self->{errno}     = 1;
    print "ACCT [$RAD->{'User-Name'}] Can't find TP: $self->{TP_ID} Session id: $RAD->{'Acct-Session-Id'}\n";
    return $self;
  }
  elsif ($self->{SUM} < 0) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{'User-Name'}] small session (". $RAD->{'Acct-Session-Time'}.", $RAD->{INBYTE}, $RAD->{OUTBYTE})";
  }
  elsif ($self->{UID} <= 0) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{'User-Name'}] small session (". $RAD->{'Acct-Session-Time'} .", $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
    $self->{errno}     = 1;
    return $self;
  }
  else {
    if ($self->{SUM} > 0) {
      $self->query2("UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id= ? ;", 'do', { Bind => [ $self->{BILL_ID} ]});
    }
  }

  $self->query2("SELECT traffic_type FROM internet_log_intervals
     WHERE acct_session_id= ?
           AND interval_id= ?
           AND uid= ? FOR UPDATE;",
    undef,
    { Bind => [ $RAD->{'Acct-Session-Id'}, $Billing->{TI_ID}, $self->{UID}  ] }
  );

  my %intrval_traffic = ();
  foreach my $line (@{ $self->{list} }) {
    $intrval_traffic{ $line->[0] } = 1;
  }

  my @RAD_TRAFF_SUFIX = ('', '1');
  $self->{SUM} = 0 if ($self->{SUM} < 0);

  for (my $traffic_type = 0 ; $traffic_type <= $#RAD_TRAFF_SUFIX ; $traffic_type++) {
    next if ($RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } + $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] } < 1);

    if ($intrval_traffic{$traffic_type}) {
      $self->query2("UPDATE internet_log_intervals SET
                sent=sent+ ? ,
                recv=recv+ ? ,
                duration=duration + ?,
                sum=sum + ?
              WHERE interval_id= ?
                AND acct_session_id= ?
                AND traffic_type= ?
                AND uid= ? ;", 'do',
        { Bind => [ $RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] },
            $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] },

            $RAD->{'INTERIUM_ACCT_SESSION_TIME'},
            $self->{SUM},
            $Billing->{TI_ID},
            $RAD->{'Acct-Session-Id'},
            $traffic_type,
            $self->{UID}
          ] }
      );
    }
    else {
      $self->query2("INSERT INTO internet_log_intervals (interval_id, sent, recv, duration, traffic_type, sum, acct_session_id, uid, added)
        VALUES ( ? , ? , ? , ? , ? , ? , ? , ?, NOW());", 'do',
        { Bind => [
            $Billing->{TI_ID},
            $RAD->{ 'INTERIUM_OUTBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] },
            $RAD->{ 'INTERIUM_INBYTE' . $RAD_TRAFF_SUFIX[$traffic_type] },
            $RAD->{INTERIUM_ACCT_SESSION_TIME},
            $traffic_type,
            $self->{SUM},
            $RAD->{'Acct-Session-Id'},
            $self->{UID}
          ] });
    }
  }
}


#**********************************************************
=head2 add_unknown_session($RAD)

  Arguments:
    $RAD,
    $NAS,
    $attr
      ACCT_STATUS_TYPE


=cut
#**********************************************************
sub add_unknown_session {
  my $self = shift;
  my ($RAD, $NAS, $attr)=@_;
  my $guest_mode = '';
  if (!$RAD->{'Framed-Protocol'} || $RAD->{'Framed-Protocol'} ne 'PPP') {
    use Auth3;
    my $Auth = Auth3->new($self->{db}, $conf);
    $Auth->auth($RAD, $NAS, { GET_USER => 1 });
    $RAD->{'User-Name'} = $self->{LOGIN} || $self->{USER_NAME} || $RAD->{'User-Name'};
    if($Auth->{UID}) {
      $self->{UID} = $Auth->{UID};
      $self->{SERVICE_ID} = $Auth->{SERVICE_ID};
    }
    else {
      $guest_mode=', guest=1';
    }
    #print "INFO: $Auth->{INFO} - $Auth->{UID} \n";
  }
  else {
    #Get TP_ID
    $self->query2("SELECT u.uid, internet.tp_id, internet.join_service, internet.id AS service_id
       FROM (users u, internet_main internet)
       WHERE u.uid=internet.uid AND u.id= ? ;",
      undef,
      { Bind => [ $RAD->{'User-Name'} ] }
    );

    if ($self->{TOTAL} > 0) {
      ($self->{UID},
        $self->{TP_ID},
        $self->{JOIN_SERVICE},
        $self->{SERVICE_ID},
      ) = @{ $self->{list}->[0] };

      if ($self->{JOIN_SERVICE}) {
        if ($self->{JOIN_SERVICE} == 1) {
          $self->{JOIN_SERVICE} = $self->{UID};
        }
        else {
          $self->{TP_ID} = '0';
        }
      }
    }
    else {
      #$RAD->{'User-Name'} = '! ' . $RAD->{'User-Name'};
      $guest_mode=', guest=1';
    }
  }

  my $sql = "REPLACE INTO internet_online SET
        status= ? ,
        user_name= ? ,
        started=NOW() - INTERVAL ? SECOND,
        lupdated=UNIX_TIMESTAMP(),
        nas_ip_address=INET_ATON( ? ),
        nas_port_id= ? ,
        acct_session_id= ? ,
        framed_ip_address=INET_ATON( ? ),
        cid= ? ,
        connect_info= ? ,
        nas_id= ? ,
        tp_id= ? ,
        uid= ? ,
        service_id = ? $guest_mode";

  $self->query2($sql, 'do', { Bind =>
    [ $attr->{ACCT_STATUS_TYPE},
      $RAD->{'User-Name'} || '',
      $RAD->{'Acct-Session-Time'} || 0,
      $RAD->{'NAS-IP-Address'},
      $RAD->{'NAS-Port'} || 0,
      $RAD->{'Acct-Session-Id'} || 'undef',
      $RAD->{'Framed-IP-Address'},
      $RAD->{'Calling-Station-Id'},
      $RAD->{'Connect-Info'}.'LOST_START_SESSION',
      $NAS->{'NAS_ID'},
      $self->{'TP_ID'} || 0,
      $self->{'UID'} || 0,
      $self->{'SERVICE_ID'} || 0,
    ]});

  $sql  = "DELETE FROM internet_online WHERE nas_id= ? AND acct_session_id='IP'
        AND (framed_ip_address=INET_ATON( ? ) OR UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started) > 120 );";

  $self->query2($sql, 'do', { Bind => [ $NAS->{NAS_ID}, $RAD->{'Framed-IP-Address'} ] });

  return 1;
}

1
