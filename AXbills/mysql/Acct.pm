package Acct v2.2.0;

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
  if (length($RAD->{'Acct-Session-Id'}) > 32) {
    $RAD->{'Acct-Session-Id'} = substr($RAD->{'Acct-Session-Id'}, 0, 32);
  }

  if ($NAS->{NAS_TYPE} eq 'cid_auth') {
    $self->query2("SELECT u.uid, u.id
     FROM users u, dv_main dv WHERE dv.uid=u.uid AND dv.CID= ? ;",
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
  #Call back function
  elsif ($RAD->{'User-Name'} =~ /(\d+):(\S+)/) {
    $RAD->{'User-Name'}          = $2;
    $RAD->{'Calling-Station-Id'} = $1;
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
    $self->query2("SELECT acct_session_id, uid FROM dv_calls
    WHERE user_name= ? 
      AND nas_id= ?
      AND (framed_ip_address=INET_ATON( ? ) 
      OR framed_ip_address=0) FOR UPDATE;",
    undef,
    { Bind => [ $RAD->{'User-Name'}, 
                $NAS->{NAS_ID}, 
                $RAD->{'Framed-IP-Address'} ] }
    );

    if ($self->{TOTAL} > 0) {
      foreach my $line (@{ $self->{list} }) {
        if ($line->[0] eq 'IP' || $line->[0] eq  "$RAD->{'Acct-Session-Id'}") {
          $self->{UID}=$line->[1];
          $self->query2("UPDATE dv_calls SET
           status= ? ,
           started=NOW() - INTERVAL ? SECOND, 
           lupdated=UNIX_TIMESTAMP(), 
           nas_port_id= ? , 
           acct_session_id= ? , 
           CID= ? , 
           CONNECT_INFO= ?
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
      #Get TP_ID
      $self->query2("SELECT u.uid, dv.tp_id, dv.join_service FROM (users u, dv_main dv)
       WHERE u.uid=dv.uid and u.id= ? ;", 
       undef,
       { Bind => [ $RAD->{'User-Name'} ] }
      );

      if ($self->{TOTAL} > 0) {
        ($self->{UID},
         $self->{TP_ID},
         $self->{JOIN_SERVICE}) = @{ $self->{list}->[0] };

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
        $RAD->{'User-Name'} = '! ' . $RAD->{'User-Name'};
      }

      my $sql = "REPLACE INTO dv_calls SET
        status= ? , 
        user_name= ? , 
        started=NOW() - INTERVAL ? SECOND, 
        lupdated=UNIX_TIMESTAMP(), 
        nas_ip_address=INET_ATON( ? ), 
        nas_port_id= ? , 
        acct_session_id= ? , 
        framed_ip_address=INET_ATON( ? ), 
        CID= ? ,
        CONNECT_INFO= ? ,
        nas_id= ? , 
        tp_id= ? ,
        uid= ? , 
        join_service = ?";

      $self->query2($sql, 'do', { Bind =>
       [ $acct_status_type,
         $RAD->{'User-Name'} || '',
         $RAD->{'Acct-Session-Time'} || 0,
         $RAD->{'NAS-IP-Address'},
         $RAD->{'NAS-Port'} || 0,
         $RAD->{'Acct-Session-Id'} || 'undef',
         $RAD->{'Framed-IP-Address'},
         $RAD->{'Calling-Station-Id'},
         $RAD->{'Connect-Info'}.'_1',
         $NAS->{'NAS_ID'},
         $self->{'TP_ID'} || 0, 
         $self->{'UID'} || 0,
         $self->{'JOIN_SERVICE'} || 0
       ]});

      $sql  = "DELETE FROM dv_calls WHERE nas_id= ? AND acct_session_id='IP' 
        AND (framed_ip_address=INET_ATON( ? ) OR UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started) > 120 );";

      $self->query2($sql, 'do', { Bind => [ $NAS->{NAS_ID}, $RAD->{'Framed-IP-Address'} ] });
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
       dv.acct_input_octets AS inbyte,
       dv.acct_output_octets AS outbyte,
       dv.acct_input_gigawords,
       dv.acct_output_gigawords,
       dv.ex_input_octets AS inbyte2,
       dv.ex_output_octets AS outbyte2,
       dv.tp_id AS tarif_plan,
       dv.sum,
       dv.uid,
       u.bill_id,
       u.company_id
    FROM (dv_calls dv, users u)
    WHERE dv.uid=u.uid AND dv.user_name= ? 
      AND dv.acct_session_id= ? ;",
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

      if ($RAD->{INBYTE} > 4294967296) {
        $RAD->{$input_gigawords} = int($RAD->{INBYTE} / 4294967296);
        $RAD->{INBYTE}                 = $RAD->{INBYTE} - $RAD->{$input_gigawords} * 4294967296;
      }

      if ($RAD->{OUTBYTE} > 4294967296) {
        $RAD->{$output_gigawords} = int($RAD->{OUTBYTE} / 4294967296);
        $RAD->{OUTBYTE}               = $RAD->{OUTBYTE} - $RAD->{$output_gigawords} * 4294967296;
      }

      if ($self->{UID} > 0) {
        $self->query2("INSERT INTO dv_log SET 
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
           $self->{TARIF_PLAN},
           $RAD->{'Acct-Session-Time'},
           $RAD->{OUTBYTE},
           $RAD->{INBYTE},
           $self->{SUM},
           $NAS->{NAS_ID},
           $RAD->{'NAS-Port'} || 0,
           $RAD->{'Framed-IP-Address'},
           $RAD->{'Calling-Station-Id'} || '_1',
           $RAD->{OUTBYTE2},
           $RAD->{INBYTE2},
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
                                    #\%EXT_ATTR
                                    );
      }
      else {
      	$self->{SUM} += $self->{CALLS_SUM};
      }

      $self->query2("INSERT INTO dv_log SET 
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
            $self->{TARIF_PLAN} || 0,
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
      $self->query2("SELECT uid, tp_id, CONNECT_INFO FROM dv_calls WHERE
          acct_session_id= ? and nas_id= ? ;",
          undef,
          { Bind => [ $RAD->{'Acct-Session-Id'}, $NAS->{NAS_ID} ]}
      );

      ($EXT_ATTR{UID}, $EXT_ATTR{TP_NUM}, $EXT_ATTR{CONNECT_INFO}) = @{ $self->{list}->[0] } if ($self->{TOTAL} > 0);

      ($self->{UID},
       $self->{SUM},
       $self->{BILL_ID},
       $self->{TARIF_PLAN},
       $self->{TIME_TARIF},
       $self->{TRAF_TARIF}) = $Billing->session_sum($RAD->{'User-Name'}, 
                                    (time - $RAD->{'Acct-Session-Time'}),
                                    $RAD->{'Acct-Session-Time'}, 
                                    $RAD, \%EXT_ATTR);

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
        $self->query2("INSERT INTO dv_log SET 
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
                    $self->{TARIF_PLAN}, 
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
    $self->query2("DELETE FROM dv_calls WHERE acct_session_id= ? AND nas_id= ? ;",
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

      $self->query2("UPDATE dv_calls SET
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
          $self->query2("SELECT u.uid, dv.tp_id, dv.join_service 
           FROM users u, dv_main dv 
           WHERE u.uid=dv.uid AND u.id=  ? ;", 
           undef,
           { INFO  => 1,
             Bind  => [ $RAD->{'User-Name'} ] });

          $self->query2("REPLACE INTO dv_calls SET
              status= ? , 
              user_name= ? , 
              started=NOW() - INTERVAL ? SECOND,
              lupdated=UNIX_TIMESTAMP(), 
              nas_ip_address=INET_ATON( ? ), 
              nas_port_id= ? , 
              acct_session_id= ? , 
              framed_ip_address=INET_ATON( ? ), 
              CID= ? , 
              CONNECT_INFO= ? ,
              acct_input_octets= ? ,
              acct_output_octets= ? ,
              acct_input_gigawords= ? ,
              acct_output_gigawords= ? ,
              nas_id= ? , 
              tp_id= ? ,
              uid= ? , 
              join_service = ? ;", 
            'do', 
            { Bind => [
             $acct_status_type,
             $RAD->{'User-Name'} || '',
             $RAD->{'Acct-Session-Time'} || 0,
             $RAD->{'NAS-IP-Address'},
             $RAD->{'NAS-Port'} || 0,
             $RAD->{'Acct-Session-Id'},
             $RAD->{'Framed-IP-Address'},
             $RAD->{'Calling-Station-Id'} || '',
             $RAD->{'Connect-Info'},
             $RAD->{'INBYTE'},
             $RAD->{'OUTBYTE'},
             $RAD->{$input_gigawords},
             $RAD->{$output_gigawords},
             $NAS->{NAS_ID},
             $self->{TP_ID} || 0, 
             $self->{UID} || 0,
             $self->{JOIN_SERVICE} || 0
             ]});
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

    $self->query2("UPDATE dv_calls SET
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
      acct_session_id= ? AND 
      user_name= ? AND
      nas_id= ? ;", 'do',
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
        $NAS->{'NAS_ID'}
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

  $self->query2("SELECT lupdated, UNIX_TIMESTAMP()-lupdated,
   IF($RAD->{INBYTE}   >= acct_input_octets AND ". $RAD->{$input_gigawords} ."=acct_input_gigawords,
        $RAD->{INBYTE} - acct_input_octets,
        IF(". $RAD->{$input_gigawords} ." - acct_input_gigawords > 0, 4294967296 * (". $RAD->{$input_gigawords} ." - acct_input_gigawords) - acct_input_octets + $RAD->{INBYTE}, 0)),
   IF($RAD->{OUTBYTE}  >= acct_output_octets AND ". $RAD->{$output_gigawords} ."=acct_output_gigawords,
        $RAD->{OUTBYTE} - acct_output_octets,
        IF(". $RAD->{$output_gigawords} ." - acct_output_gigawords > 0, 4294967296 * (". $RAD->{$output_gigawords} ." - acct_output_gigawords) - acct_output_octets + $RAD->{OUTBYTE}, 0)),
   IF($RAD->{INBYTE2}  >= ex_input_octets, $RAD->{INBYTE2}  - ex_input_octets, ex_input_octets),
   IF($RAD->{OUTBYTE2} >= ex_output_octets, $RAD->{OUTBYTE2} - ex_output_octets, ex_output_octets),
   sum,
   tp_id,
   uid
   FROM dv_calls
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
  $self->{TP_NUM},
  $self->{UID}) = @{ $self->{list}->[0] };

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
      TP_NUM     => $self->{TP_NUM},
      UID        => ($self->{TP_NUM}) ? $self->{UID} : undef,
      DOMAIN_ID  => ($NAS->{DOMAIN_ID}) ? $NAS->{DOMAIN_ID} : 0,
    }
  );

  $self->query2("SELECT traffic_type FROM dv_log_intervals 
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
      $self->query2("UPDATE dv_log_intervals SET
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
      $self->query2("INSERT INTO dv_log_intervals (interval_id, sent, recv, duration, traffic_type, sum, acct_session_id, uid, added)
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

  #  return $self;
  if ($self->{UID} == -2) {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{'User-Name'}] Not exist";
  }
  elsif ($self->{UID} == -3) {
    my $filename = "$RAD->{'User-Name'}.$RAD->{'Acct-Session-Id'}";
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{'User-Name'}] Not allow start period '$filename'";
    $Billing->mk_session_log($RAD);
  }
  elsif ($self->{UID} == -5) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{'User-Name'}] Can't find TP: $self->{TP_NUM} Session id: $RAD->{'Acct-Session-Id'}";
    $self->{errno}     = 1;
    print "ACCT [$RAD->{'User-Name'}] Can't find TP: $self->{TP_NUM} Session id: $RAD->{'Acct-Session-Id'}\n";
  }
  elsif ($self->{SUM} < 0) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{'User-Name'}] small session (". $RAD->{'Acct-Session-Time'}.", $RAD->{INBYTE}, $RAD->{OUTBYTE})";
  }
  elsif ($self->{UID} <= 0) {
    $self->{LOG_DEBUG} = "ACCT [$RAD->{'User-Name'}] small session (". $RAD->{'Acct-Session-Time'} .", $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
    $self->{errno}     = 1;
  }
  else {
    if ($self->{SUM} > 0) {
      $self->query2("UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id= ? ;", 'do', { Bind => [ $self->{BILL_ID} ]});
    }
  }
}


1
