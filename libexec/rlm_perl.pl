#!/usr/bin/perl
=head1 NAME

  ABillS Main Freeradius RLMPerl AAA Module

=cut
#***********************************************************

use strict;
our (%RAD_REQUEST, %RAD_REPLY, %RAD_CHECK, %AUTH, $RAD_PAIRS, %ACCT, %conf, %ACCT_TYPES);

#
# This the remapping of return values
#
use constant RLM_MODULE_REJECT   => 0;    #  /* immediately reject the request */
use constant RLM_MODULE_FAIL     => 1;    #  /* module failed, don't reply */
use constant RLM_MODULE_OK       => 2;    #  /* the module is OK, continue */
use constant RLM_MODULE_HANDLED  => 3;    #  /* the module handled the request, so stop. */
use constant RLM_MODULE_INVALID  => 4;    #  /* the module considers the request invalid. */
use constant RLM_MODULE_USERLOCK => 5;    #  /* reject the request (user is locked out) */
use constant RLM_MODULE_NOTFOUND => 6;    #  /* user not found */
use constant RLM_MODULE_NOOP     => 7;    #  /* module succeeded without doing anything */
use constant RLM_MODULE_UPDATED  => 8;    #  /* OK (pairs modified) */
use constant RLM_MODULE_NUMCODES => 9;    #  /* How many return codes there are */

############################################################
# Accounting status types
# rfc2866
%ACCT_TYPES = (
  'Start'          => 1,
  'Stop'           => 2,
  'Alive'          => 3,
  'Interim-Update' => 3,
  'Accounting-On'  => 7,
  'Accounting-Off' => 8
);

my %USER_TYPES = (
  'Login-User'              => 1,
  'Framed-User'             => 2,
  'Callback-Login-User'     => 3,
  'Callback-Framed-User'    => 4,
  'Outbound-User'           => 5,
  'Administrative-User'     => 6,
  'NAS-Prompt-User'         => 7,
  'Authenticate-Only'       => 8,
  'Call-Check'              => 10,
  'Callback-Administrative' => 11,
  'Voic'                    => 12,
  'Fax'                     => 13
);

use FindBin '$Bin';
#use Test::LeakTrace;
#my @a;

require $Bin . "/config.pl";
unshift(@INC, $Bin . '/../lib/', $Bin . "/../AXbills/$conf{dbtype}");

require AXbills::Base;
AXbills::Base->import('check_time');

require AXbills::SQL;
require Nas;
Nas->import();

require Auth;
Auth->import();

require Acct;
Acct->import();

require Log;
Log->import('log_print');

my %auth_mod  = ();
my %acct_mod  = ();
my $begin_time= 0;
my $GT        = '';
my $Log;
my %NAS_INFO  = ();
#my $request_count = 0;
my $debug     = 0;

#**********************************************************
=head2 sql_connect() - SQL connect

=cut
#**********************************************************
sub sql_connect {
  my $nas;
  my $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
  $Log = Log->new($db, \%conf);

  return $db if (! $RAD_REQUEST{'NAS-IP-Address'});

  $RAD_REQUEST{'NAS-Identifier'} = '' if (!defined($RAD_REQUEST{'NAS-Identifier'}));
  if (!$NAS_INFO{ $RAD_REQUEST{'NAS-IP-Address'} . '_' . $RAD_REQUEST{'NAS-Identifier'} }) {
    $nas = get_nas_info($db, \%RAD_REQUEST);
    if (! defined($nas->{errno})) {
      $NAS_INFO{ $RAD_REQUEST{'NAS-IP-Address'} . '_' . $RAD_REQUEST{'NAS-Identifier'} } = $nas;
    }
    else {
      return 0;
    }
  }
  else {
    $nas = $NAS_INFO{ $RAD_REQUEST{'NAS-IP-Address'} . '_' . $RAD_REQUEST{'NAS-Identifier'} };
  }

  return ($db, $nas);
}

#**********************************************************
=head2 authorize() Function to handle authorize

=cut
#**********************************************************
sub authorize {
  $begin_time = AXbills::Base::check_time();
  $GT = '';
  my ($db, $nas) = sql_connect();

  my $auth_type = $RAD_CHECK{'Auth-Type'} || q{};

  if ($debug) {
    &radiusd::radlog(2, "authorize Auth-Type: $auth_type User-Name: $RAD_REQUEST{'User-Name'}");
  }

  if ($db) {
    my $r   = 1;
    if ($auth_type eq 'MSCHAP' || $auth_type eq 'MS-CHAP' || $auth_type eq 'eap') {
      $Log->{ACTION} = 'AUTH';

      if ($debug ) {
        &radiusd::radlog(2, "pre auth Auth-Type: $auth_type User-Name: $RAD_REQUEST{'User-Name'}");
      }

      my $nas_type = ($AUTH{ $nas->{NAS_TYPE} }) ? $nas->{NAS_TYPE} : 'default';

      if ($AUTH{$nas_type} && !defined($auth_mod{$nas_type})) {
        require $AUTH{$nas_type} . ".pm";
        $AUTH{$nas_type}->import();
      }

      if ($AUTH{ $nas->{NAS_TYPE} }) {
        $auth_mod{$nas_type} = $AUTH{$nas_type}->new($db, \%conf);
      }
      else {
        $auth_mod{$nas_type} = Auth->new($db, \%conf);
      }

      $r = $auth_mod{$nas_type}->pre_auth(\%RAD_REQUEST, $nas);

      if ($auth_mod{$nas_type}->{errno}) {
        if ($RAD_REQUEST{'Calling-Station-Id'}) {
          $GT = " CID: $RAD_REQUEST{'Calling-Station-Id'} ".$GT;
        }

        #$Log->log_print('LOG_WARNING', $RAD_REQUEST{'User-Name'}, "MS-CHAP PREAUTH FAILED. Wrong password or login$GT", { NAS => $nas });
      }
      else {
        while (my ($k, $v) = each(%{ $auth_mod{$nas_type}->{'RAD_CHECK'} })) {
          $RAD_CHECK{$k} = $v;
        }
        return RLM_MODULE_OK;
      }
    }
    else {
      return RLM_MODULE_OK;
    }
  }

  #mk_debug_log(\@a);

  return RLM_MODULE_REJECT;
}

#**********************************************************
=head2 authenticate() - Function to handle authenticate

=cut
#**********************************************************
sub authenticate {
  $begin_time = AXbills::Base::check_time();

  if($debug) {
    &radiusd::radlog(2, "authenticate Auth-Type: $RAD_CHECK{'Auth-Type'} User-Name: $RAD_REQUEST{'User-Name'}");
  }

  my ($db, $nas) = sql_connect();
  if ($db) {
    #mk_debug_log(\@a);
    if($nas->{errno}) {
      return RLM_MODULE_FAIL;
    }
    elsif (auth_($db, \%RAD_REQUEST, $nas) == 0) {
      return RLM_MODULE_OK;
    }
  }

  return RLM_MODULE_REJECT;
}

#**********************************************************
=head2 accounting()

=cut
#**********************************************************
sub accounting {
#  $begin_time = AXbills::Base::check_time();

  my ($db, $nas) = sql_connect();

  if(! $db) {
    print "!!!!!!!!!!!!!!!!!!!!! Nas server not defined\n";
    return RLM_MODULE_OK;
  }

  my $r = 0;

  $Log->{ACTION} = 'ACCT';
  if ( $RAD_REQUEST{'Service-Type'}
    && $USER_TYPES{ $RAD_REQUEST{'Service-Type'} }
    && $USER_TYPES{ $RAD_REQUEST{'Service-Type'} } > 5) {
    $Log->log_print('LOG_DEBUG', $RAD_REQUEST{'User-Name'}, $RAD_REQUEST{'Service-Type'}, { NAS => $nas });
    return RLM_MODULE_OK;
  }

  my $acct_status_type = $ACCT_TYPES{ $RAD_REQUEST{'Acct-Status-Type'} };

  # if ($acct_status_type > 6) {
  #   return RLM_MODULE_OK;
  # }

  # $RAD_REQUEST{INTERIUM_INBYTE}   = 0;
  # $RAD_REQUEST{INTERIUM_OUTBYTE}  = 0;
  # $RAD_REQUEST{INTERIUM_INBYTE2}  = 0;
  # $RAD_REQUEST{INTERIUM_OUTBYTE2} = 0;
  # $RAD_REQUEST{INBYTE2}           = 0;
  # $RAD_REQUEST{OUTBYTE2}          = 0;

  #Cisco-AVPair
  if ($RAD_REQUEST{'Cisco-AVPair'}) {
    if ($RAD_REQUEST{'Cisco-AVPair'} =~ /client-mac-address=([a-f0-9\.\-\:]+)/) {
      $RAD_REQUEST{'Calling-Station-Id'} = $1;
      if ($RAD_REQUEST{'Calling-Station-Id'} =~ /(\S{2})(\S{2})\.(\S{2})(\S{2})\.(\S{2})(\S{2})/) {
        $RAD_REQUEST{'Calling-Station-Id'} = "$1:$2:$3:$4:$5:$6";
      }
    }
    elsif (ref $RAD_REQUEST{'Cisco-AVPair'} eq 'ARRAY') {
      foreach my $line (@{ $RAD_REQUEST{'Cisco-AVPair'} }) {
        if ($line =~ /client-mac-address=([a-f0-9\.\-\:]+)/) {
          $RAD_REQUEST{'Calling-Station-Id'} = $1;
          if ($RAD_REQUEST{'Calling-Station-Id'} =~ /(\S{2})(\S{2})\.(\S{2})(\S{2})\.(\S{2})(\S{2})/) {
            $RAD_REQUEST{'Calling-Station-Id'} = "$1:$2:$3:$4:$5:$6";
          }
        }
      }
    }
    elsif (defined($RAD_REQUEST{'NAS-Port'}) && $RAD_REQUEST{'NAS-Port'} == 0 && ($RAD_REQUEST{'Cisco-NAS-Port'} && $RAD_REQUEST{'Cisco-NAS-Port'} =~ /\d\/\d\/\d\/(\d+)/)) {
      $RAD_REQUEST{'NAS-Port'} = $1;
    }
  }

  if ($RAD_REQUEST{'Tunnel-Client-Endpoint'} && !$RAD_REQUEST{'Calling-Station-Id'}) {
    $RAD_REQUEST{'Calling-Station-Id'} = $RAD_REQUEST{'Tunnel-Client-Endpoint'};
  }
  elsif (! defined($RAD_REQUEST{'Calling-Station-Id'})) {
    $RAD_REQUEST{'Calling-Station-Id'} = '';
  }

  if (defined($RAD_REQUEST{'mpd-iface'})) {
    $RAD_REQUEST{'Connect-Info'} = $RAD_REQUEST{'mpd-iface'} ;
  }
  elsif(! defined($RAD_REQUEST{'Connect-Info'})) {
    $RAD_REQUEST{'Connect-Info'} = '';
  }

  # Make accounting with external programs
#  if ($conf{extern_acct_dir} && -d $conf{extern_acct_dir}) {
#    $RAD_REQUEST{'NAS-Port'} = 0 if (!defined($RAD_REQUEST{'NAS-Port'}));
#    opendir my $dh, $conf{extern_acct_dir} or die "Can't open dir '$conf{extern_acct_dir}' $!\n";
#    my @contents = grep !/^\.\.?$/, readdir $dh;
#    closedir $dh;
#
#    if ($#contents > -1) {
#      my $res = "";
#      foreach my $file (@contents) {
#        if (-x "$conf{extern_acct_dir}/$file" && -f "$conf{extern_acct_dir}/$file") {
#
#          # ACCT_STATUS IP_ADDRESS NAS_PORT
#          $res = `$conf{extern_acct_dir}/$file $acct_status_type $RAD_REQUEST{'NAS-IP-Address'} $RAD_REQUEST{'NAS-Port'} $nas->{NAS_TYPE} $RAD_REQUEST{USER_NAME} $RAD_REQUEST{FRAMED_IP_ADDRESS}`;
#          $Log->log_print('LOG_DEBUG', $RAD_REQUEST{USER_NAME}, "External accounting program '$conf{extern_acct_dir}' / '$file' pairs '$res'", { NAS => $nas });
#        }
#      }
#
#      if (defined($res)) {
#        my @pairs = split(/ /, $res);
#        foreach my $pair (@pairs) {
#          my ($side, $value) = split(/=/, $pair);
#          $RAD_REQUEST{$side} = $value || '';
#        }
#      }
#    }
#  }

  my $acct_module = $ACCT{ $nas->{NAS_TYPE} } || 'Acct2';
  if (!defined($acct_mod{$acct_module})) {
    require $acct_module . '.pm';
    $acct_module->import();
  }

  $acct_mod{$acct_module} = $acct_module->new($db, \%conf);
  $r = $acct_mod{$acct_module}->accounting(\%RAD_REQUEST, $nas, {
    ACCT_STATUS_TYPE => $acct_status_type
  });

  if ($r && $r->{errno}) {
    $Log->log_print('LOG_WARNING', $RAD_REQUEST{USER_NAME}, "[$r->{errno}] $r->{errstr}", { NAS => $nas });
  }

  return RLM_MODULE_OK;
}

#**********************************************************
=head2 post_auth()

=cut
#**********************************************************
sub post_auth {
  $begin_time = AXbills::Base::check_time();

  if ( ! $RAD_REQUEST{'NAS-IP-Address'} ) {
    if ($RAD_REQUEST{'DHCP-Gateway-IP-Address'}) {
      $RAD_REQUEST{'NAS-IP-Address'} = $RAD_REQUEST{'DHCP-Gateway-IP-Address'};
    }
    else {
      $RAD_REQUEST{'NAS-IP-Address'} = $RAD_REQUEST{'DHCP-Server-IP-Address'};
    }
  }

  my ($db, $nas) = sql_connect();
  my $reject_info= '';

  if ($debug) {
    &radiusd::radlog(2, "post_auth Auth-Type: $RAD_CHECK{'Auth-Type'} Post: $RAD_CHECK{'Post-Auth-Type'} User-Name: $RAD_REQUEST{'User-Name'} Q: $nas->{db}->{queries_count}");
  }

  if ($db) {
    $Log->{ACTION} = 'AUTH';
    # DHCP Section

    if ($RAD_REQUEST{'DHCP-Message-Type'}) {
      $RAD_REQUEST{'User-Name'} = $RAD_REQUEST{'DHCP-Client-Hardware-Address'};
      $nas->{NAS_TYPE} = 'dhcp';
      my $nas_type = 'dhcp';
      if (!defined($auth_mod{$nas_type})) {
        if (! $AUTH{ $nas_type }) {
          $AUTH{ $nas_type }='Mac_auth';
        }

        eval { require $AUTH{ $nas_type } . '.pm'; };
        if ($@) {
          my $message = "Failed to load: $AUTH{ $nas_type }.pm";
          print $@;
          print $message . "\n";
          $Log->log_print('LOG_WARNING', $RAD_REQUEST{'User-Name'}, "$message", { NAS => $nas });
          return RLM_MODULE_FAIL;
        }
        $AUTH{ $nas_type }->import();
      }

      $auth_mod{$nas_type} = $AUTH{ $nas_type }->new($db, \%conf);
      my $r;
      ($r, $RAD_PAIRS) = $auth_mod{ $nas_type }->auth(\%RAD_REQUEST, $nas);
      my $message = $RAD_PAIRS->{'Reply-Message'} || '';

      if ($auth_mod{ $nas_type }->{INFO}) {
        $message .= $auth_mod{ $nas_type }->{INFO};
      }

      if($auth_mod{ $nas_type }->{GUEST_MODE}) {
        $Log->{ACTION} = 'GUEST_MODE';
      }

      if ($r == 2) {
        $Log->log_print('LOG_INFO', $RAD_PAIRS->{'User-Name'}, $message . " " . $RAD_REQUEST{'DHCP-Client-Hardware-Address'} . (($GT) ? " $GT" : ''), { NAS => $nas });
        $r = 0;
      }
      else {
        $RAD_REPLY{'DHCP-DHCP-Error-Message'} = $message if ($message);
        access_deny($RAD_PAIRS->{'User-Name'}, $message. (($GT) ? " $GT" : ''), $nas, $db);
        $r = 1 if (!$r);
        return $r;
      }

      delete($RAD_REQUEST{'User-Name'});
      #while (my ($k, $v) = each %$RAD_PAIRS) {
      #  $RAD_REPLY{$k} = $v;
      #}
      if($RAD_PAIRS) {
        %RAD_REPLY = (%RAD_REPLY, %$RAD_PAIRS);
      }

      if ($conf{DHCP_FREERADIUS_DEBUG} && $conf{DHCP_FREERADIUS_DEBUG} == 2) {
        my $out = "\nREQUEST ======================================\n";
        while (my ($k, $v) = each %RAD_REQUEST) {
          $out .= "$k -> $v\n";
        }
        $out .= "RePLY ======================================\n";
        while (my ($k, $v) = each %RAD_REPLY) {
          $out .= "$k -> $v\n";
        }
        if (open( my $fh, '>>', '/tmp/rad_reply_' )) {
          print $fh $out;
          close( $fh );
        }
      }

      if ($r == 0) {
        return RLM_MODULE_OK;
      }
    }
    # END DHCP SECTION
    else {
      #Check pass ok
      if ($RAD_CHECK{'Post-Auth-Type'} !~ /Reject/i) {
        #Second step auth - MS chap authentification
        if ($RAD_CHECK{'Auth-Type'} eq 'MSCHAP' || $RAD_CHECK{'Auth-Type'} eq 'MS-CHAP' || $RAD_CHECK{'Auth-Type'} eq 'eap') {
          if (auth_($db, \%RAD_REQUEST, $nas) == 0) {
            if ($debug) {
              &radiusd::radlog(2, "MS CHAP OK Auth-Type: $RAD_CHECK{'Auth-Type'} Post: $RAD_CHECK{'Post-Auth-Type'} User-Name: $RAD_REQUEST{'User-Name'}");
            }
            return RLM_MODULE_OK;
          }
        }
        #Allow others
        else {
          #Fixme Temmporary skip for correct ip assign
          if($RAD_PAIRS) {
            #%RAD_REPLY = (%RAD_REPLY, %$RAD_PAIRS);
            #Only for Juniper services
            $RAD_REPLY{'ERX-Service-Activate:1'} = $RAD_PAIRS->{'ERX-Service-Activate:1'} if ($RAD_PAIRS->{'ERX-Service-Activate:1'});
            $RAD_REPLY{'ERX-Service-Activate:2'} = $RAD_PAIRS->{'ERX-Service-Activate:2'} if ($RAD_PAIRS->{'ERX-Service-Activate:2'});
            $RAD_REPLY{'ERX-Service-Activate:3'} = $RAD_PAIRS->{'ERX-Service-Activate:3'} if ($RAD_PAIRS->{'ERX-Service-Activate:3'});
            $RAD_REPLY{'ERX-Service-Statistics:1'} = $RAD_PAIRS->{'ERX-Service-Statistics:1'} if ($RAD_PAIRS->{'ERX-Service-Statistics:1'});
            $RAD_REPLY{'ERX-Service-Statistics:2'} = $RAD_PAIRS->{'ERX-Service-Statistics:2'} if ($RAD_PAIRS->{'ERX-Service-Statistics:2'});
            $RAD_REPLY{'ERX-Service-Statistics:3'} = $RAD_PAIRS->{'ERX-Service-Statistics:3'} if ($RAD_PAIRS->{'ERX-Service-Statistics:3'});
          }
    	    return RLM_MODULE_OK;
    	}
      }

      #Reject non auth
      my $CID = ($RAD_REQUEST{'Calling-Station-Id'}) ? " CID: ". $RAD_REQUEST{'Calling-Station-Id'} : '';
      if ($RAD_REPLY{'Reply-Message'}) {
      	$reject_info = $RAD_REPLY{'Reply-Message'} . $reject_info;
      }
      else {
        $reject_info = "REJECT WRONG_AUTH ($RAD_CHECK{'Post-Auth-Type'})";
        $RAD_REPLY{'Reply-Message'} = $reject_info;
      }

      $Log->log_print('LOG_WARNING', $RAD_REQUEST{'User-Name'}, "$reject_info$CID$GT", { NAS => $nas });
    }
  }
  return RLM_MODULE_REJECT;
}


#*******************************************************************
=head2 get_nas_info($db, $RAD);

=cut
#*******************************************************************
sub get_nas_info {
  my ($db, $RAD) = @_;

  my $nas = Nas->new($db, \%conf);

  $RAD->{'NAS-IP-Address'} = '' if (!$RAD->{'NAS-IP-Address'});
  $RAD->{'User-Name'}      = '' if (!$RAD->{'User-Name'});

  my %NAS_PARAMS = (
    IP    => $RAD->{'NAS-IP-Address'},
    SHORT => 1
  );

  if ($RAD->{'NAS-IP-Address'} eq '0.0.0.0' && !$RAD->{'DHCP-Message-Type'}) {
    %NAS_PARAMS = (CALLED_STATION_ID => $RAD->{'Called-Station-Id'});
  }

  $NAS_PARAMS{NAS_IDENTIFIER} = $RAD->{'NAS-Identifier'} if ($RAD->{'NAS-Identifier'});
  $nas->info( \%NAS_PARAMS );

  if ($nas->{errno}) {
    if ($RAD->{'Mikrotik-Host-IP'}) {
      $nas->info({ NAS_ID => $RAD->{'NAS-Identifier'} });
      if ($nas->{errno}) {
        access_deny($RAD->{'User-Name'}, "UNKNOW_SERVER: '". $RAD->{'NAS-IP-Address'} ."'" . (($RAD->{'NAS-Identifier'}) ? " Nas-Identifier: ". $RAD->{'NAS-Identifier'}  : '') . ' ' . (($RAD->{'NAS-IP-Address'} eq '0.0.0.0') ? $RAD->{'Called-Station-Id'} : ''), $nas, $db);

        $RAD_REPLY{'Reply-Message'} = "UNKNOW_SERVER: '". $RAD->{'NAS-IP-Address'} ."'";
        return $nas;
      }
      $nas->{NAS_IP} = $RAD->{'NAS-IP-Address'};
    }
    else {
      access_deny($RAD->{'User-Name'}, "UNKNOW_SERVER: '". $RAD->{'NAS-IP-Address'} ."'" .
      (($RAD->{'NAS-Identifier'}) ? " Nas-Identifier: ". $RAD->{'NAS-Identifier'} : '') .
      ' ' . (($RAD->{'NAS-IP-Address'} eq '0.0.0.0' && !$RAD->{'DHCP-Message-Type'}) ? $RAD->{'Called-Station-Id'} : ''), $nas, $db);

      $RAD_REPLY{'Reply-Message'} = "UNKNOW_SERVER: '". $RAD->{'NAS-IP-Address'} ."'";
      $nas->{errno}=1;
    }
  }
  elsif (!$nas->{NAS_TYPE} eq 'dhcp' && ! $RAD->{'User-Name'}) {
    $nas->{errno}=2;
  }
  elsif ($nas->{NAS_DISABLE} > 0) {
    access_deny($RAD->{'User-Name'}, "DISABLED_NAS_SERVER: '". $RAD->{'NAS-IP-Address'} ."'", $nas, $db);
    $nas->{errno}=3;
  }

  return $nas;
}

#*******************************************************************
=head2 auth_($db, $RAD, $nas);

=cut
#*******************************************************************
sub auth_ {
  my ($db, $RAD, $nas) = @_;
  my ($r);

  $Log->{ACTION} = 'AUTH';

  if ($debug) {
    &radiusd::radlog(2, "_auth Auth-Type: $RAD_CHECK{'Auth-Type'} User-Name: $RAD->{'User-Name'}");
  }

  #accep all for tech works
  if ($conf{tech_works}) {
    $RAD_REPLY{'Reply-Message'} = $conf{tech_works};
    $RAD_CHECK{'Auth-Type'} = 'Accept';
    return 0;
  }

  if ($RAD->{'DHCP-Message-Type'}) {
    $nas->{NAS_TYPE} = 'dhcp';
  }

  my $nas_type = $nas->{NAS_TYPE} || 'default';
  my $extra_info = q{};
  #if ($AUTH{ $nas_type }) {
  my $auth_module = $AUTH{ $nas_type } || 'Auth2';
  if (!defined($auth_mod{ $nas_type })) {
    require $auth_module . ".pm";
    $auth_module->import();
  }

  delete($auth_mod{$nas_type}->{INFO});
  $auth_mod{$nas_type} = $auth_module->new($db, \%conf);
  ($r, $RAD_PAIRS) = $auth_mod{$nas_type}->auth($RAD, $nas);
  $RAD_REQUEST{'User-Name'} = $auth_mod{$nas_type}->{LOGIN} if ($auth_mod{$nas_type}->{LOGIN});

  $extra_info = ($auth_mod{$nas_type}->{INFO}) ? $auth_mod{$nas_type}->{INFO} : '';
  #}
  # else {  #if ($AUTH{ default }) {
  #   my $auth_module = $AUTH{ default } || 'Auth2';
  #   if (!defined($auth_mod{ default })) {
  #     require $auth_module . ".pm";
  #     $auth_module->import();
  #   }
  #
  #   delete($auth_mod{default}->{INFO});
  #   $auth_mod{default} = $auth_module->new($db, \%conf);
  #   ($r, $RAD_PAIRS) = $auth_mod{default}->auth($RAD, $nas);
  #   $RAD_REQUEST{'User-Name'} = $auth_mod{"default"}->{LOGIN} if ($auth_mod{"default"}->{LOGIN});
  #   $extra_info = ($auth_mod{ default }->{INFO}) ? $auth_mod{default}->{INFO} : '';
  #
  #   $nas_type = 'default';
  # }
  # else {
  #   $auth_mod{'default'} = Auth->new($db, \%conf);
  #
  #   ($r, $RAD_PAIRS) = $auth_mod{"default"}->dv_auth($RAD, $nas, { MAX_SESSION_TRAFFIC => $conf{MAX_SESSION_TRAFFIC} });
  #   $nas_type='default';
  #   $RAD->{'User-Name'} = $auth_mod{"default"}->{LOGIN} if ($auth_mod{"default"}->{LOGIN});
  # }

  if($RAD_PAIRS) {
    #@RAD_REPLY{keys %$RAD_PAIRS} = values %$RAD_PAIRS;
    %RAD_REPLY = (%RAD_REPLY, %$RAD_PAIRS);
  }

  #If Access deny
  if ($r == 1) {
    if ($RAD_PAIRS->{'Reply-Message'} eq 'SQL error') {
      %auth_mod = ();
    }

    if ($auth_mod{'default'}->{errstr} && $auth_mod{'default'}->{errno} != 2) {
      $auth_mod{'default'}->{errstr} =~ s/\n//g;
    }

    $RAD_CHECK{'Auth-Type'} = 'REJECT';
    return $r;
  }
  else {
    #GEt Nas rad pairs
    if ($nas->{NAS_RAD_PAIRS}) {
      $nas->{NAS_RAD_PAIRS} =~ tr/\n\r//d;
      my @pairs_arr = split(/,[ \n]+/, $nas->{NAS_RAD_PAIRS});
      foreach my $line (@pairs_arr) {
        if ($line =~ /([a-zA-Z0-9\-:]{6,25})\+\=(.{1,200})/) {
          my $left  = $1;
          my $right = $2;
          push @{ $RAD_REPLY{$left} }, $right;
        }
        else {
          my ($left, $right) = split(/=/, $line, 2);
          if ($left =~ s/^!//) {
            delete $RAD_REPLY{$left};
            delete $RAD_PAIRS->{$left};
          }
          else {
            $RAD_REPLY{$left} = $right;
          }
        }
      }
    }

    $RAD_CHECK{'Auth-Type'} = 'Accept' if ($RAD->{'CHAP-Password'});
  }

  my $CID = ($RAD_REQUEST{'Calling-Station-Id'}) ? " CID: ". $RAD_REQUEST{'Calling-Station-Id'} : '';

  if ($begin_time > 0 && ! $conf{CONNECT_LOG}) {
    my $gen_time = Time::HiRes::gettimeofday() - $begin_time;
    $GT = sprintf(" GT: %2.5f", $gen_time);
  }

  if ($r == 0 || $r == 8) {
    if($auth_mod{$nas_type}->{GUEST_MODE}) {
      $Log->{ACTION} = 'GUEST_MODE';
    }

    $Log->log_print( 'LOG_INFO', $RAD_REQUEST{'User-Name'}, $extra_info.$CID.$GT, { NAS => $nas } );
  }

  return $r;
}


#*******************************************************************
=head2 access_deny($user_name, $message, $nas, $db, $attr);

=cut
#*******************************************************************
sub access_deny {
  my ($user_name, $message, $nas) = @_;

  $Log->{ACTION} = 'AUTH';
  $Log->log_print('LOG_WARNING', $user_name, $message, { NAS => $nas });

  #External script for error connections
  # if ($conf{AUTH_ERROR_CMD}) {
  #   my @cmds = split(/;/, $conf{AUTH_ERROR_CMD});
  #   foreach my $expr_cmd (@cmds) {
  #     $RAD_REQUEST{'Nas-Port'} = 0 if (!$RAD_REQUEST{'Nas-Port'});
  #     my ($expr, $cmd) = split(/:/, $expr_cmd);
  #     if ($message =~ /$expr/) {
  #       system("$cmd USER_NAME=$user_name NAS_PORT=$RAD_REQUEST{'Nas-Port'} NAS_IP=$nas->{NAS_IP} ERROR=$message");
  #     }
  #   }
  # }

  return 1;
}

#**********************************************************
# http://chimera.labs.oreilly.com/books/1234000001527/ch06.html#vicunas-06-7
#**********************************************************
#sub mk_debug_log {
#  my ($info_arr, $attr) = @_;

=comments
use Devel::Size qw( size total_size );
$request_count++;

if ($request_count % 1) {
  return;
}

my $info = "$request_count -----------------------------------------\n";
#foreach my $ret ( @$info_arr ) {
#  my $varable = join(", ", @$ret)."\n";
#  $info .=  $varable;
#  print $varable;
#}

my %info_ = ();
foreach my $ps ( keys %:: ) {
  #next if ($ps eq 'ps' || $ps eq 'info');
  #$info = sprintf("%30s: %d\n", $ps, total_size( $::{ $ps } ));
  my $size = total_size( $ps );
  if ($size) {
    $info_{$ps}=$size;
  }
}

#my $i=0;
#foreach my $ps ( sort { $info_{$b} <=> $info_{$a} } keys %info_) {
#  $info .= sprintf("size %30s: %d / %d\n", $ps,  $info_{$ps}, size($ps));
#  if ($i > 10) {
#    #last;
#  }
#  $i++;
#}



# Global vars
#$info = '';
#$info .= sprintf("size_ %30s: %d / %d\n", '%RAD_REQUEST',  total_size(\%RAD_REQUEST), size(\%RAD_REQUEST));
#$info .= sprintf("size_ %30s: %d / %d\n", '%RAD_REPLY',  total_size(\%RAD_REPLY), size(\%RAD_REPLY));
#$info .= sprintf("size_ %30s: %d / %d\n", '%RAD_CHECK',  total_size(\%RAD_CHECK), size(\%RAD_CHECK));
$info .= sprintf("size_ %30s: %d / %d\n", '%auth_mod',  size(\%auth_mod), total_size(\%auth_mod )); # total_size(\%auth_mod ));
$info .= sprintf("size_ %30s: %d / %d\n", '%acct_mod',  size(\%acct_mod), 0); #, size(\%acct_mod));
#$info .= sprintf("size_ %30s: %d / \n", 'db',  size($db));
$info .= sprintf("size_ %30s: %d / \n", 'Log',  size($Log));
$info .= sprintf("size_ %30s: %d / \n", '%NAS_INFO',  size(\%NAS_INFO));

open(my $fh, ">> /tmp/mem_trace") or die "can't open file $!";
  print $fh $info;
close($fh);


sub test_vars {
  foreach my $key (keys %RAD_REQUEST ) {
  	print "!! $key / $RAD_REQUEST{$key}\n";
  }
  foreach my $key (keys %RAD_REPLY) {
  	print "__ $key / $RAD_REPLY{$key}\n";
  }
  foreach my $key (keys %RAD_CHECK) {
  	print "++ $key / $RAD_CHECK{$key}\n";
  }
}

=cut
#}

1
