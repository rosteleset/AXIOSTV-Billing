=head1 NAME Snmp_console

  Console for snmp requsts

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw\_bp in_array\;
use SNMP_util;
use Carp;
our ($db, $admin, %conf, %lang, $index, %FORM, $base_dir);
our AXbills::HTML $html;

my %loaded_mibs = ();
my %OIDS_HASH = %SNMP_util::OIDS;
my $Nas = Nas->new($db, \%conf, $admin);
my $debug      = $conf{SNMP_CONSOLE_DEBUG} || $FORM{DEBUG} || 0;

#**********************************************************
=head2 snmp_info_form($attr)

=cut
#**********************************************************
sub snmp_info_form {
  my ($attr) = @_;
  my %info = ();

  $info{ACTION}     = 'add';
  $info{ACTION_LNG} = $lang{ADD};
  my $SNMP_COMMUNITY = $FORM{SNMP_COMMUNITY} || q{};
  my $snmp_host      = $FORM{SNMP_HOST} || q{};

  snmpmapOID("ipRoutingTable", "1.3.6.1.2.1.4.21");

  # $SNMP_util::Debug = 1;
  my %OIDS_EXINFO = %{
    snmputils_load_mibs(
      [
        'SNMPv2-SMI',
        'SNMPv2-MIB',
        'SNMPv2-CONF',
        'SNMPv2-TC',
        'IF-MIB',
        'IP-MIB',
        'RFC1212-MIB',
        'RFC1155-SMI',
        'RFC1213-MIB',
        'ENTITY-MIB',

        #Cisco Mibs
        'CISCO-SMI',
        'CISCO-DOT11-IF-MIB',
        'CISCO-DOT11-ASSOCIATION-MIB',

        #'livingston.mib'
        'corporat.mib',
        'common.mib',
        'product.mib',

        #DOCSIS
        'DOCS-IF-MIB',
        'DOCS-CABLE-DEVICE-MIB',
        'DOCS-IF-EXT-MIB',

        #River Delta
        'RDN-MIB',

        'RDN-CABLE-SPECTRUM',
        'RDN-CABLE-SPECTRUM-GROUP-MIB',

        #                   'RDN-CMTS-MIB',
        'RDN-SYSLOG-MIB',
      ],
      \%info
    )
    };

  $info{TYPE_SEL} = $html->form_select(
    'TYPE',
    {
      SELECTED => $FORM{TYPE} || 'dlink_ip_mac_port',
      SEL_HASH => {
        'system'            => 'RFC1213-MIB System information',
        'interfaces'        => 'IF-MIB:ifTable',
        'ipNetToMediaTable' => 'RFC1158-MIB:ipNetToMediaTable',
        'ipRoutingTable'    => 'RFC1158-MIB:ipRoutingTable',
        'tcpConnTable'      => 'RFC1213-MIB:tcpConnTable',
        'udpTable'          => 'RFC1213-MIB:udpTable',
        'zyxel_smf'         => 'Zyxel Static MAC Forwarding ',
        'dlink_ip_mac_port' => 'D-Link IP MAC Port Binding',
        'cisco_air'         => 'Cisco Aironet Asociation',
        'celan'             => 'CeLAN MAC Table',
        'ports_state'       => 'Port State',
        'mikrotik_air'      => 'Mikrotik Signal Power',
        'cpu_load'          => 'CPU Load',
        'mem_use',          => 'Menory use',
        'mem_free'          => 'Menory free',
        'uptime'            => 'Uptime',
      },
      NO_ID => 1
    }
  );

  $info{NAS_SEL} = $html->form_select(
    'NAS_ID',
    {
      SELECTED       => $FORM{NAS_ID},
      SEL_LIST       => $Nas->list({ SORT => 1, PAGE_ROWS => 10000, COLS_NAME => 1 }),
      SEL_KEY        => 'nas_id',
      SEL_VALUE      => 'nas_name',
      SEL_OPTIONS    => { '' => '--' },
      MAIN_MENU      => get_function_index('form_nas'),
      MAIN_MENU_ARGV => "NAS_ID=". ($FORM{NAS_ID} || q{})
    }
  );

  $SNMP_COMMUNITY = "$SNMP_COMMUNITY\@". $snmp_host;

  if ($FORM{NAS_ID}) {
    $Nas->info({ NAS_ID => $FORM{NAS_ID} });
    if (!$Nas->{NAS_MNG_PASSWORD}) {
      $html->message( 'err', $lang{ERROR}, "NO SNMP COMMUNITY" );
      return 0;
    }
    elsif (!$Nas->{NAS_MNG_IP_PORT}) {
      $html->message( 'err', $lang{ERROR}, "NO SNMP HOST" );
      return 0;
    }
    $SNMP_COMMUNITY = "$Nas->{NAS_MNG_PASSWORD}\@$Nas->{NAS_MNG_IP_PORT}";
    $pages_qs = "\&SNMP_COMMUNITY=$SNMP_COMMUNITY\&SNMP_HOST=$snmp_host";
  }
  else {
    $pages_qs = "\&SNMP_COMMUNITY=$SNMP_COMMUNITY\&SNMP_HOST=$snmp_host";
    $SNMP_COMMUNITY = "$SNMP_COMMUNITY\@$snmp_host";
  }


  if ($FORM{change}) {
    my %REV_HASH      = reverse %OIDS_HASH;
    my $SNMP_OID_NAME = ($FORM{SNMP_OID} && $REV_HASH{ $FORM{SNMP_OID} }) ? $REV_HASH{ $FORM{SNMP_OID} } : q{};
    if ($OIDS_EXINFO{$SNMP_OID_NAME} && $OIDS_EXINFO{$SNMP_OID_NAME}{SYNTAX} ) {
      print "-- $OIDS_EXINFO{$SNMP_OID_NAME}{SYNTAX} --";
    }

    if ($FORM{set}) {
      my $SNMP_OID = $FORM{SNMP_OID};
      $SNMP_OID .= '.' . $FORM{SNMP_INDEX} if ($FORM{SNMP_INDEX});

      if (snmpset($SNMP_COMMUNITY, $FORM{SNMP_OID}, $FORM{SNMP_TYPE}, $FORM{SNMP_VALUE})) {
        print $html->message( 'info', $lang{CHANGED}, "$FORM{SNMP_OID} => $FORM{SNMP_VALUE}" );
      }
    }

    if ($FORM{SNMP_INDEX}) {
      $FORM{SNMP_OID} = $FORM{SNMP_OID} . '.' . $FORM{SNMP_INDEX};
    }

    delete $FORM{SNMP_VALUES};
    $info{SNMP_VALUE} = snmpget($SNMP_COMMUNITY, $FORM{SNMP_OID});

    $info{SNMP_TYPE_SEL} = $html->form_select(
      'SNMP_TYPE',
      {
        SELECTED => $FORM{SNMP_TYPE},
        SEL_ARRAY =>
          [ 'int', 'integer', 'string', 'octetstring', 'octet string', 'oid', 'object id', 'object identifier', 'ipaddr', 'ip address', 'timeticks', 'uint', 'uinteger', 'uinteger32', 'unsigned int', 'unsigned integer', 'unsigned integer32', 'counter', 'counter32', 'counter64', 'gauge', 'gauge32' ],
        NO_ID => 1
      }
    );

    $html->tpl_show(_include('snmputils_set', 'Snmputils'), { %info, %FORM });
  }
  else {
    $info{DEBUG_SEL} = $html->form_select(
      'DEBUG',
      {
        SELECTED => $FORM{DEBUG} || 0,
        SEL_ARRAY => [ 0, 1, 2, 3, 4, 5 ],
        NO_ID     => 1
      }
    );

    $html->tpl_show(_include('equipment_snmp_console', 'Equipment'), { %info, %FORM });
  }

  if ($FORM{SHOW}) {
    my $rows_count = 0;
    $FORM{TYPE} = $FORM{SNMP_OID} if ($FORM{SNMP_OID});

    $SNMP_COMMUNITY = "$SNMP_COMMUNITY\@$snmp_host";

    if ($FORM{NAS_ID}) {
      $Nas->info({ NAS_ID => $FORM{NAS_ID} });
      if (!$Nas->{NAS_MNG_PASSWORD}) {
        $html->message( 'err', $lang{ERROR}, "NO SNMP COMMUNITY" );
        return 0;
      }
      elsif (!$Nas->{NAS_MNG_IP_PORT}) {
        $html->message( 'err', $lang{ERROR}, "NO SNMP HOST" );
        return 0;
      }

      $pages_qs       = "&NAS_ID=$FORM{NAS_ID}";

      if (! $Nas->{NAS_MNG_IP_PORT}) {
        $Nas->{NAS_MNG_IP_PORT}=$Nas->{nas_ip};
      }

      $SNMP_COMMUNITY = "$Nas->{NAS_MNG_PASSWORD}\@$Nas->{NAS_MNG_IP_PORT}";
    }
    else {
      $pages_qs = "\&SNMP_COMMUNITY=$FORM{SNMP_COMMUNITY}\&SNMP_HOST=$snmp_host";
      $SNMP_COMMUNITY = "$FORM{SNMP_COMMUNITY}\@$snmp_host";
    }

    my $timeout = $attr->{TIMEOUT} || 2;
    my $retries = $attr->{RETRIES} || 2;
    my $version = $attr->{VERSION} || 1;

    my ($snmp_community, $port, undef, $port3)=split(/:/, $SNMP_COMMUNITY || q{});
    if($port3) {
      $port = $port3;
    }
    elsif (! $port || in_array($port, [ 21, 22, 23, 1700, 3977 ])) {
      $port = 161;
    }
    #  my ($snmp_community, $port)=split(/:/, $attr->{SNMP_COMMUNITY});
    #  $port = 161 if (! $port || in_array($port, [ 22, 23, 1700, 3977 ]));
    $SNMP_COMMUNITY = $snmp_community.':'.$port.":$timeout:$retries:1:$version";

    #External
    my $function = 'snmputils_' . $FORM{TYPE};
    if (defined(&$function)) {
      &{ \&$function }({ SNMP_COMMUNITY => $SNMP_COMMUNITY });
      return 0;
    }

    my %_oids = (
      #cpu         => ".1.3.6.1.4.1.11.2.14.11.5.1.9.6.1",
      mem_use     => ".1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.7",
      mem_free    => ".1.3.6.1.4.1.11.2.14.11.5.1.1.2.1.1.1.7",
      uptime      => ".1.3.6.1.2.1.1.3",
    );

    if ($_oids{$FORM{TYPE}}) {
      $FORM{TYPE}=$_oids{$FORM{TYPE}};
    }

    print $SNMP_COMMUNITY;

    if(!$FORM{SNMP_OID}){
      return 1;
    }

    my %result  = &snmpwalkhash($SNMP_COMMUNITY, \&my_simple_hash, ($_oids{$FORM{TYPE}}) ? $_oids{$FORM{TYPE}} : $FORM{TYPE});
    my @CAPTION = keys %result;
    my @RES_ARR = ();

    if ($#CAPTION > -1) {
      @RES_ARR = sort {
        #$a <=> $b
        length($result{$CAPTION[0]}{$a} || 0) <=> length($result{$CAPTION[0]}{$b} || 0)
          || ($result{$CAPTION[0]}{$a} || q{}) cmp ($result{$CAPTION[0]}{$b} || q{});

      } keys %{$result{$CAPTION[0]}};
    }

    if ($SNMP_Session::errmsg) {
      print $html->message( 'err', $lang{ERROR},
        "$FORM{TYPE}" . $html->br() . "$SNMP_Session::suppress_warnings / $SNMP_Session::errmsg" );
    }

    my $table ;
    if ($#RES_ARR > 0 && $FORM{TYPE} ne 'system') {
      $table = $html->table({
        width      => '100%',
        caption    => "$lang{RESULT}: $SNMP_COMMUNITY",
        title      => [ 'index', @CAPTION ],
        ID         => 'SNMP_INFO'
      });

      foreach my $k (@RES_ARR) {
        my @arr = ($k);
        foreach my $ft (@CAPTION) {
          push @arr, ($OIDS_EXINFO{$ft}{ACCESS} && $OIDS_EXINFO{$ft}{ACCESS} eq 'read-write') ? $html->button($result{$ft}{$k}, "index=$index&change=1&SNMP_INDEX=$k&SNMP_OID=$OIDS_HASH{$ft}$pages_qs") : $result{$ft}{$k};
        }
        $table->addrow(@arr);
        $rows_count++;
      }
    }
    else {
      $table = $html->table({
        width      => '100%',
        caption    => "$FORM{TYPE} $lang{RESULT}: $SNMP_COMMUNITY",
        title      => [ 'MIB', 'OID Name', "inst", $lang{VALUE}, "ACCESS", $lang{DESCRIBE} ],
        ID         => 'SNMP_RESULT',
      });

      foreach my $oid (keys %result) {
        foreach my $inst (keys %{ $result{$oid} }) {
          $table->addrow(
            "$OIDS_EXINFO{$oid}{MIB}", "$oid", "$inst",
            $result{$oid}{$inst},
            ($OIDS_EXINFO{$oid}{ACCESS} && $OIDS_EXINFO{$oid}{ACCESS} eq 'read-write') ? $html->button($lang{CHANGE}, "index=$index&change=y&SNMP_INDEX=$inst&SNMP_OID=$OIDS_HASH{$oid}$pages_qs",
              { BUTTON => 1 } )  : $OIDS_EXINFO{$oid}{ACCESS}
            ,
            $OIDS_EXINFO{$oid}{DESCRIBE}
          );
        }
        $rows_count++;
      }
    }

    print $table->show();

    $table = $html->table(
      {
        width      => '100%',
        rows       => [ [ "$lang{TOTAL}:", $html->b( $rows_count ) ] ]
      }
    );
    print $table->show();

    snmp_form_footer(\%result, \@CAPTION, { OIDS_EXINFO => \%OIDS_EXINFO });

    if ($FORM{TYPE} eq 'ipRoutingTable') {
      print $html->tpl_show(_include('snmputils_route', 'Snmputils'), \%info);
    }
  }

  return 1;
}

sub snmputils_load_mibs {
  my ($mib_array, $info) = @_;

  my %OIDS_EXINFO = ();

  # if (-d '../../AXbills/MIBs/') {
  #
  # opendir DIR, '../../AXbills/MIBs/' or die "Can't opendir '../../AXbills/MIBs/' $!\n";
  #    my @contents = grep  !/^\.\.?$/  , readdir DIR;
  #  closedir DIR;
  #  foreach my $line (@contents) {
  #    $info->{MIBS}.=$html->form_input('MIBS', "$line", { TYPE => 'checkbox', STATE => 0 }). " $line<br>\n";
  #   }
  # }
  # if ($FORM{MIBS}) {
  #   @$mib_array = split(', ', $FORM{MIBS});
  # }

  my $message = '';
  foreach my $line (@$mib_array) {
    next if (!-f "../../AXbills/MIBs/$line");
    my (undef, $oid_hash, $oid_ex) = snmpMIB_to_OID_extended("../../AXbills/MIBs/$line");
    $message .= "MIBS: $line Loaded\n" if ($debug == 1);

    while (my ($k, $v) = each %$oid_hash) {
      $OIDS_EXINFO{$k}{DESCRIBE} = $oid_ex->{$k}{DESCRIPTION} if ($oid_ex->{$k}{DESCRIPTION});
      $OIDS_EXINFO{$k}{ACCESS}   = $oid_ex->{$k}{ACCESS}      if ($oid_ex->{$k}{ACCESS});
      $OIDS_EXINFO{$k}{SYNTAX}   = $oid_ex->{$k}{SYNTAX}      if ($oid_ex->{$k}{SYNTAX});
      $OIDS_EXINFO{$k}{MIB}      = "$line"                    if (!$OIDS_EXINFO{$k}{MIB});
      snmpmapOID("$k", "$v");
    }
  }

  if ($debug > 0) {
    $html->pre($message);
  }

  return \%OIDS_EXINFO;
}

#**********************************************************
=head2 snmpMIB_to_OID_extended($arg)

  Read in the passed MIB file, parsing it
  for their text-to-OID mappings

=cut
#**********************************************************
sub snmpMIB_to_OID_extended {
  my ($arg) = @_;

  my ($quote, $buf, $var, $code, $val, $tmp, $tmpv, $strt);
  my ($ret, $pass, $pos, $need2pass, $cnt, %prev);
  my (%Link) = (
    'org'          => 'iso',
    'dod'          => 'org',
    'internet'     => 'dod',
    'directory'    => 'internet',
    'mgmt'         => 'internet',
    'mib-2'        => 'mgmt',
    'experimental' => 'internet',
    'private'      => 'internet',
    'enterprises'  => 'private',
  );

  my %OIDS_EX = ();
  my $MIB;
  if (!open($MIB, '<', $arg)) {
    carp "snmpMIB_to_OID: Can't $arg: $!"
      unless ($SNMP_Session::suppress_warnings > 1);
    return -1;
  }

  print "snmpMIB_to_OID: loading $arg\n" if $SNMP_util::Debug;
  $ret       = 0;
  $pass      = 0;
  $need2pass = 1;
  $cnt       = 0;
  $pos       = tell($MIB);

  my %DESCRIBE_OIDS = ();

  #my @MIB_ARRAY =
  my $MIB_NAME;

  while ($need2pass) {
    while (<$MIB>) {
      s/--.*--//g;    # throw away comments (-- anything --)
      s/--.*//;       # throw away comments (-- anything EOL)
      if ($quote) {
        next unless /\"/;
        $quote = 0;
      }
      chop;

      #
      #  $buf = "$buf $_";
      # Previous line removed (and following replacement)
      # suggested by Brian Reichert, reichert@numachi.com
      #
      $buf .= ' ' . $_;
      $buf =~ s/\s+/ /g;

      if ($buf =~ / DEFINITIONS ::= BEGIN/) {

        if ($buf =~ /(\S+) DEFINITIONS/) {
          $MIB_NAME = $1;

          #print "$MIB_NAME\n";
        }

        if ($pass == 0 && $need2pass) {
          seek($MIB, $pos, 0);
          $buf       = "";
          $pass      = 1;
          $need2pass = 0;
          $cnt       = 0;
          next;
        }
        $need2pass = 0;
        $pass      = 0;
        $pos       = tell($MIB);

        #undef %Link;
        #undef %prev;

        %Link = (
          'org'          => 'iso',
          'dod'          => 'org',
          'internet'     => 'dod',
          'directory'    => 'internet',
          'mgmt'         => 'internet',
          'mib-2'        => 'mgmt',
          'experimental' => 'internet',
          'private'      => 'internet',
          'enterprises'  => 'private',
        );
        $buf = "";
        next;
      }
      elsif ($buf =~ /FROM (\S+)/) {
        if (!$loaded_mibs{$1}) {
          print "FROM $1\n" if ($debug == 1);
        }
        $buf =~ s/FROM $1//;
      }
      if ($buf =~ /DESCRIPTION.+"(.+)"+/g) {
        $DESCRIBE_OIDS{DESCRIPTION} = $1;

        #next;
      }
      elsif ($buf =~ /ACCESS (\S+)/) {
        $DESCRIBE_OIDS{ACCESS} = $1;
        $buf =~ s/ACCESS $1//;
        next;
      }
      elsif ($buf =~ /(\S+) OBJECT-TYPE/) {
        $DESCRIBE_OIDS{'OBJECT-TYPE'} = $1;
      }
      elsif ($buf =~ /SYNTAX (\w+)/) {
        $DESCRIBE_OIDS{'SYNTAX'} = $1;
        $buf =~ s/ SYNTAX .*//;
        next;
      }

      $buf =~ s/OBJECT-TYPE/OBJECT IDENTIFIER/;
      $buf =~ s/OBJECT-IDENTITY/OBJECT IDENTIFIER/;
      $buf =~ s/OBJECT-GROUP/OBJECT IDENTIFIER/;
      $buf =~ s/MODULE-IDENTITY/OBJECT IDENTIFIER/;
      $buf =~ s/ IMPORTS .*\;//;
      $buf =~ s/ SEQUENCE \{.*\}//;

      $buf =~ s/ [\w-]+ ::= OBJECT IDENTIFIER//;
      $buf =~ s/ OBJECT IDENTIFIER .* ::= \{/ OBJECT IDENTIFIER ::= \{/;
      $buf =~ s/".*"//;

      if ($buf =~ /\"/) {
        $quote = 1;
      }

      if ($buf =~ / ([\w\-]+) OBJECT IDENTIFIER ::= \{([^}]+)\}/) {

        $var = $1;
        $buf = $2;
        undef $val;
        $buf =~ s/ +$//;
        ($code, $val) = split(' ', $buf, 2);

        $OIDS_EX{$var}{SYNTAX}      = $DESCRIBE_OIDS{SYNTAX};
        $OIDS_EX{$var}{ACCESS}      = $DESCRIBE_OIDS{ACCESS};
        $OIDS_EX{$var}{DESCRIPTION} = $DESCRIBE_OIDS{DESCRIPTION};
        %DESCRIBE_OIDS              = ();

        if (!defined($val) || (length($val) <= 0)) {

          #$SNMP_util::OIDS{$var} = $code;
          $OIDS_HASH{$var} = $code;
          $cnt++;
          print "'$var' => '$code'\n" if $SNMP_util::Debug;
        }
        else {
          $strt = $code;
          while ($val =~ / /) {
            ($tmp, $val) = split(' ', $val, 2);
            if ($tmp =~ /([\w\-]+)\((\d+)\)/) {
              $tmp = $1;
              if (exists($OIDS_HASH{$strt})) {
                $tmpv = "$OIDS_HASH{$strt}.$2";
              }
              else {
                $tmpv = $2;
              }
              $Link{$tmp} = $strt;
              if (!exists($prev{$tmp}) && exists($OIDS_HASH{$tmp})) {
                if ($tmpv ne $OIDS_HASH{$tmp}) {
                  $strt = "$strt.$tmp";
                  $OIDS_HASH{$strt} = $tmpv;
                  $cnt++;
                }
              }
              else {
                $prev{$tmp}      = 1;
                $OIDS_HASH{$tmp} = $tmpv;
                $cnt++;
                $strt = $tmp;
              }
            }
          }

          if (!exists($OIDS_HASH{$strt})) {
            if ($pass) {
              carp "snmpMIB_to_OID: $arg: \"$strt\" prefix unknown, load the parent MIB first.\n"
                unless ($SNMP_Session::suppress_warnings > 1);
              print "snmpMIB_to_OID: $arg: \"$strt\" prefix unknown, load the parent MIB first." . $html->br();
            }
            else {
              $need2pass = 1;
            }
          }
          $Link{$var} = $strt;
          if (exists($OIDS_HASH{$strt})) {
            $val = "$OIDS_HASH{$strt}.$val";
          }
          if (!exists($prev{$var}) && exists($OIDS_HASH{$var})) {
            if ($val ne $OIDS_HASH{$var}) {
              $var = "$strt.$var";
            }
          }

          $OIDS_HASH{$var} = $val;
          $prev{$var}      = 1;
          $cnt++;

          print "'$var' => '$val'\n" if $SNMP_util::Debug;
        }
        undef $buf;
      }
    }

    if ($pass == 0 && $need2pass) {
      seek($MIB, $pos, 0);
      $buf  = "";
      $pass = 1;
      $cnt  = 0;
    }
    else {
      $ret += $cnt;
      $need2pass = 0;
    }
  }
  close($MIB);
  #$RevNeeded = 1;

  $loaded_mibs{$MIB_NAME} = 1;

  return ($ret, \%OIDS_HASH, \%OIDS_EX);
}
#**********************************************************
=head2 my_simple_hash($h_ref, $host, $name, $oid, $inst, $value)

=cut
#**********************************************************
sub my_simple_hash {
  my ($h_ref, undef, $name, undef, $inst, $value) = @_;
  $inst =~ s/^\.+//;

  my %ipNetToMediaType = (
    1 => 'other',
    2 => 'invalid',
    3 => 'dynamic',
    4 => 'static'
  );

  if ($name =~ /ifPhysAddress/ || $name =~ /ipNetToMediaPhysAddress/) {
    my $mac = '';
    map { $mac .= sprintf("%02X:", $_) } unpack "CCCCCC", $value;
    $value = $mac;
  }
  elsif ($name =~ /ipNetToMediaType/) {
    $value = $ipNetToMediaType{$value};
  }

  $h_ref->{$name}->{$inst} = $value;
}

#**********************************************************
#
#**********************************************************
sub snmp_form_footer {
  my ($fields, $active_fields, $attr) = @_;

  my $table2 = $html->table({ width => '100%' });
  my @arr = ();
  foreach my $name (sort keys %$fields) {
    my $ex_info = ($attr->{OIDS_EXINFO}->{$name}{DESCRIBE}) ? " ($attr->{OIDS_EXINFO}->{$name}{ACCESS})" . $html->br() . "$attr->{OIDS_EXINFO}->{$name}{DESCRIBE}" : '';
    push @arr, $html->form_input('fields', "$name", { TYPE => 'checkbox', STATE => (in_array($name, $active_fields)) ? 1 : undef }) . ' ' . $html->b($name) . "$ex_info";

    if ($#arr > 2) {
      $table2->addrow(@arr);
      @arr = ();
    }
  }

  if ($#arr > -1) {
    $table2->addrow(@arr);
  }

  my $table = $html->table(
    {
      width       => '100%',
      title_plain => [ "REFRESH (sec): " . $html->form_input( 'REFRESH', $FORM{REFRESH}, { SIZE => 4 } ),
        $html->form_input( 'SHOW', $lang{SHOW}, { TYPE => 'SUBMIT' } ) ],
    }
  );

  print $html->form_main(
    {
      CONTENT => $table2->show() . $table->show(),
      HIDDEN  => {
        index         => $index,
        NAS_TYPE      => $FORM{NAS_TYPE},
        NAS_HOST      => $FORM{NAS_HOST},
        NAS_COMMUNITY => $FORM{NAS_COMMUNITY}
      },
      METHOD => 'GET'
    }
  );

  return 1;
}

1;
