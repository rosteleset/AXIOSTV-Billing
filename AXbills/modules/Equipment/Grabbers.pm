=head1 NAME

  Base info grabber

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Filters qw(dec2hex _mac_former bin2mac);
use AXbills::Base qw(in_array sec2time);
require Equipment::Snmp_cmd;
require Equipment::Defs;

our (
  %FORM,
);

use POSIX qw(strftime);

my $debug = (defined($FORM{DEBUG})) ? $FORM{DEBUG} : 0;
our @skip_ports_types;

#********************************************************
=head2 equipment_test($attr) - get ports info or device info

  Arguments:
    $attr
      PORT_INFO       - list of OIDs to query, string, delimited by ','
      PORT_ID         - Port ID (if set, will get stats for one port)
      SNMP_TPL        - Filename of SNMP template or SNMP template in form of hash ref
      TEST_OID        - Array of OIDs. If set, will return device info instead of ports info. If equal to '1', will use all OIDs
      AUTO_PORT_SHIFT - Apply autoshift to port number. true or false
      RUN_CABLE_TEST  - Run cable test. true or false
      TIMEOUT         - SNMP timeout
      attrs for snmp_get()/snmp_set()

  Returns:
    ports_info_hash_ref
    or
    device_info_hash_ref - if TEST_OID is set

=cut
#********************************************************
sub equipment_test {
  my ($attr) = @_;

  my %snmp_info = ();
  my %snmp_ports_info = ();

  if (ref $attr->{SNMP_TPL} eq 'HASH') {
    %snmp_ports_info = %{ $attr->{SNMP_TPL} };
  }
  else {
    my $perl_scalar = _get_snmp_oid( $attr->{SNMP_TPL} );

    if ($perl_scalar && $perl_scalar->{ports}) {
      %snmp_ports_info = %{ $perl_scalar->{ports} };
    }

    if ($perl_scalar && $perl_scalar->{info}) {
      %snmp_info = %{ $perl_scalar->{info} };
      if ( !$snmp_info{PORTS}{OIDS} ) {
        $snmp_info{PORTS} = $perl_scalar->{ports}->{PORT_TYPE};
        $snmp_info{PORTS}{WALK} = 1;
      }
    }
  }

  my %ports_info = ();

  if ( $attr->{PORT_INFO} ){
    print "Debug" if($debug);
    if ( $attr->{PORT_INFO} =~ /TRAFFIC/ ){
      $attr->{PORT_INFO} .= ",PORT_IN,PORT_OUT";
    }

    my @port_info_list = split( /,\s?/, $attr->{PORT_INFO} );

    my @requires_cable_test_fields = grep {$snmp_ports_info{$_}->{REQUIRES_CABLE_TEST}} (keys %snmp_ports_info);

    if ($attr->{AUTO_PORT_SHIFT} && $attr->{PORT_ID} && in_array('PORT_INDEX', \@port_info_list) && $snmp_ports_info{PORT_INDEX}{OIDS}) {
      my $oid = $snmp_ports_info{PORT_INDEX}{OIDS};
      my $function = $snmp_ports_info{PORT_INDEX}{PARSER};

      my $new_port_id = snmp_get({
        %{$attr},
        OID     => $oid . ".$attr->{PORT_ID}",
        DEBUG   => ($debug > 2) ? 1 : undef
      });

      if ($function && defined( &{$function} ) ) {
        ($new_port_id) = &{ \&$function }($new_port_id);
      }

      $attr->{PORT_ID} = $new_port_id;
    }

    my $equipment_uptime;
    if (in_array('PORT_UPTIME', \@port_info_list) && $snmp_info{UPTIME}->{OIDS}) {
      $equipment_uptime = snmp_get({
        %{$attr},
        OID                       => $snmp_info{UPTIME}->{OIDS},
        NO_PRETTY_PRINT_TIMETICKS => 1,
        DEBUG                     => ($debug > 2) ? 1 : undef
      });
    }

    foreach my $type ( @port_info_list ){
      my $oid = '';
      my $function;

      if ($attr->{PORT_ID} && $type eq 'PORT_INDEX') {
        next;
      }

      if(in_array($type, \@requires_cable_test_fields)) {
        next;
      }

      if ( $snmp_ports_info{$type}{OIDS} ){
        $oid = $snmp_ports_info{$type}{OIDS};
        $function = $snmp_ports_info{$type}{PARSER};
      }
      else {
        next;
      }

      my $ports_info = snmp_get({
        %{$attr},
        OID                       => $oid . (($attr->{PORT_ID}) ? ".$attr->{PORT_ID}" : q{}),
        WALK                      => ($attr->{PORT_ID}) ? 0 : 1,
        NO_PRETTY_PRINT_TIMETICKS => ($type eq 'PORT_UPTIME') ? 1 : 0,
        DEBUG                     => ($debug > 2) ? 1 : undef
      });

      if ( !defined($ports_info) ){
        next;
      }

      if ($function && defined( &{$function} ) ) {
        ($ports_info) = &{ \&$function }($ports_info); #XXX will it work if $ports_info is array?
      }

      if ($attr->{PORT_ID}) {
        if ($type eq 'PORT_UPTIME') {
          $ports_info = (defined $equipment_uptime && defined $ports_info) ? sec2time(($equipment_uptime - $ports_info)/100, {str => 1} ) : '?';
        }

        $ports_info{$attr->{PORT_ID}}{$type} = $ports_info;
        next;
      }

      if ($attr->{AUTO_PORT_SHIFT} && $type eq 'PORT_INDEX') {
        foreach my $port ( @{$ports_info} ) {
          next if (!defined($port));
          my ($port_index, $port_id) = split( /:/, $port, 2 );

          $ports_info{$port_id}{$type} = $port_index;
        }
        next;
      }

      foreach my $port ( @{$ports_info} ) {
        next if (!defined($port));
        my ($port_id, $data) = split( /:/, $port, 2 );

        if ($type eq 'PORT_UPTIME') {
          $data = (defined $equipment_uptime && defined $data) ? sec2time(($equipment_uptime - $data)/100, {str => 1} ) : '?';
        }

        $ports_info{$port_id}{$type} = $data;
      }
    }

    if ($snmp_ports_info{RUN_CABLE_TEST}{OIDS} || $snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{OIDS}) {
      my $skip_ports = $snmp_ports_info{RUN_CABLE_TEST}{SKIP_PORTS} || $snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{SKIP_PORTS};
      if (ref $skip_ports ne 'ARRAY') {
        $skip_ports = undef;
      }

      my %cable_test_results = ();
      foreach my $port (sort { $a <=> $b } keys %ports_info) {
        if ($skip_ports && in_array($port, $skip_ports)) {
          next;
        }

        if(! $ports_info{$port}{PORT_TYPE}) {
          $ports_info{$port}{PORT_TYPE} = snmp_get({
            %{$attr},
            OID   => $snmp_ports_info{PORT_TYPE}{OIDS}.'.'.$port,
          });
        }

        if( !defined($ports_info{$port}{PORT_TYPE}) || (($ports_info{$port}{PORT_TYPE} != 6) && ($ports_info{$port}{PORT_TYPE} != 117)) ) {
          next;
        }

        if((defined($snmp_ports_info{RUN_CABLE_TEST}{PORT_NAME_REGEX})
            && defined($ports_info{$port}{PORT_NAME})
            && $ports_info{$port}{PORT_NAME} !~ $snmp_ports_info{RUN_CABLE_TEST}{PORT_NAME_REGEX})
          || (defined($snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{PORT_NAME_REGEX})
            && defined($ports_info{$port}{PORT_NAME})
            && $ports_info{$port}{PORT_NAME} !~ $snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{PORT_NAME_REGEX})) {
          next;
        }

        if($attr->{RUN_CABLE_TEST}) {
          my $result;
          if ($snmp_ports_info{RUN_CABLE_TEST}{OIDS}) {
            $result = snmp_set({
              %{$attr},
              IGNORE_ERRORS => 'commitFailed|genErr',
              TIMEOUT => 10,
              OID   => [ $snmp_ports_info{RUN_CABLE_TEST}{OIDS} . '.' . $port, 'integer', 1 ],
              DEBUG => ($debug > 2) ? 1 : undef
            });
          }

          if ($snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{OIDS}) {
            $result = snmp_set({
              %{$attr},
              IGNORE_ERRORS => 'commitFailed|genErr',
              OID   => [ $snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{OIDS}, 'integer', $port ],
              DEBUG => ($debug > 2) ? 1 : undef
            });
          }

          if ($result) {
            $cable_test_results{$port} = 1;
          }
          else {
            $ports_info{$port}{CABLE_TESTER}{ERROR} = 1;
          }

        }
        else {
          $ports_info{$port}{CABLE_TESTER} = 1; #indicates that port supports cable tester
        }
      }

      if (%cable_test_results) {
        my $sleep_time = $snmp_ports_info{RUN_CABLE_TEST}{SLEEP} || $snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{SLEEP} || 0;
        if ($sleep_time) {
          sleep $sleep_time;
        }

        my $is_cable_test_in_progress;

        my $cable_test_status_oid = $snmp_ports_info{RUN_CABLE_TEST}{CABLE_TEST_STATUS_OID} || $snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{CABLE_TEST_STATUS_OID};
        my $cable_test_status_in_progress = $snmp_ports_info{RUN_CABLE_TEST}{CABLE_TEST_STATUS_IN_PROGRESS} || $snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{CABLE_TEST_STATUS_IN_PROGRESS};
        my $cable_test_status_ok = $snmp_ports_info{RUN_CABLE_TEST}{CABLE_TEST_STATUS_OK} || $snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{CABLE_TEST_STATUS_OK};

        if ($cable_test_status_oid && $cable_test_status_in_progress && $cable_test_status_ok) {
          my $cable_test_status_info;
          do {
            $is_cable_test_in_progress = 0;

            $cable_test_status_info = snmp_get({
              %{$attr},
              OID   => $cable_test_status_oid . (($attr->{PORT_ID}) ? ".$attr->{PORT_ID}" : q{}),
              WALK  => ($attr->{PORT_ID}) ? 0 : 1,
              RETRIES => 10,
              DEBUG => ($debug > 2) ? 1 : undef
            });

            if ($attr->{PORT_ID}) {
              if ($cable_test_status_info && $cable_test_status_info == $cable_test_status_in_progress) {
                $is_cable_test_in_progress = 1;
              }
            }
            else {
              foreach my $cable_test_status_port (@$cable_test_status_info) {
                my ($port, $status) = split(/:/, $cable_test_status_port, 2);
                if ($status == $cable_test_status_in_progress && $cable_test_results{$port}) {
                  $is_cable_test_in_progress = 1;
                }
              }
            }

            if ($is_cable_test_in_progress) {
              sleep 1;
            }
          } while ($is_cable_test_in_progress);

          if ($attr->{PORT_ID}) {
            if ($cable_test_status_info && $cable_test_status_info != $cable_test_status_ok) {
              $cable_test_results{$attr->{PORT_ID}} = 0;
              $ports_info{$attr->{PORT_ID}}{CABLE_TESTER}{ERROR} = 1;
            }
          }
          else {
            foreach my $cable_test_status_port (@$cable_test_status_info) {
              my ($port, $status) = split(/:/, $cable_test_status_port, 2);
              if ($status != $cable_test_status_ok && $cable_test_results{$port}) {
                $cable_test_results{$port} = 0;
                $ports_info{$port}{CABLE_TESTER}{ERROR} = 1;
              }
            }
          }
        }

        my $pair_status_in_progress = $snmp_ports_info{RUN_CABLE_TEST}{PAIR_STATUS_IN_PROGRESS} || $snmp_ports_info{RUN_CABLE_TEST_SET_PORT}{PAIR_STATUS_IN_PROGRESS};
        do {
          $is_cable_test_in_progress = 0;
          foreach my $type (@requires_cable_test_fields) {
            if (!$snmp_ports_info{$type} || !$snmp_ports_info{$type}{OIDS}) {
              next;
            }

            my $oid = $snmp_ports_info{$type}{OIDS};
            my $function = $snmp_ports_info{$type}{PARSER};
            my $ports_info = snmp_get({
                %{$attr},
                OID     => $oid . (($attr->{PORT_ID}) ? ".$attr->{PORT_ID}" : q{}),
                WALK    => ($attr->{PORT_ID}) ? 0 : 1,
                DEBUG   => ($debug > 2) ? 1 : undef
              });

            if ($attr->{PORT_ID}) {
              if (defined($ports_info)) {
                if ($pair_status_in_progress && $type =~ /STATUS_PAIR/ && $ports_info == $pair_status_in_progress) {
                  $is_cable_test_in_progress = 1;
                  last;
                }
                if ($function && defined( &{$function} ) ) {
                  ($ports_info) = &{ \&$function }($ports_info);
                }
              }
              $ports_info{$attr->{PORT_ID}}{CABLE_TESTER}{$type} = $ports_info;
              next;
            }

            foreach my $port_info (@$ports_info) {
              my ($port, $value) = split(/:/, $port_info, 2);
              if (!$cable_test_results{$port}) {
                next;
              }

              if ( defined($value) ) {
                if ($pair_status_in_progress && $type =~ /STATUS_PAIR/ && $value == $pair_status_in_progress) {
                  $is_cable_test_in_progress = 1;
                  last;
                }
                if ($function && defined( &{$function} ) ) {
                  ($value) = &{ \&$function }($value);
                }
              }
              $ports_info{$port}{CABLE_TESTER}{$type} = $value;
            }
          }
          if ($pair_status_in_progress) {
            sleep 1;
          }
        } while ($is_cable_test_in_progress);
      }
    }
  }

  if ( $attr->{TEST_OID} ){
    my %result_hash = ();

    if ($attr->{TEST_OID} ne '1') {
      my @test_oids = split(/,\s?/, $attr->{TEST_OID});
      foreach my $k ( keys %snmp_info ) {
        if (! in_array($k, \@test_oids)) {
          delete $snmp_info{$k};
        }
      }
    }

    foreach my $key ( keys %snmp_info ){
      my $snmp_oid = $snmp_info{$key}{OIDS};

      if ($key eq 'PORTS' && $snmp_info{$key}{WALK}) {
        next;
      }
      if ( $snmp_oid ){
        my $res = snmp_get( {
          %{$attr},
          OID => $snmp_oid,
        } );

        if ( $res ){
          my $name = $snmp_info{$key}{NAME} || $key;
          my $function = $snmp_info{$key}->{PARSER};

          if ($function && defined( &{$function} ) ) {
            ($res) = &{ \&$function }($res);
          }
          $result_hash{$name} = $res;
        }
        else {
          #Last if no response
          if($key eq 'UPTIME') {
            return {};
          }
        }
      }
    }

    my %snmp_info_result = ();
    foreach my $key ( keys %result_hash ){
      my $value = $result_hash{$key};
      $snmp_info_result{$key} = $value;
    }

    #Get ports
    if ($snmp_info{'PORTS'}{WALK}) {
      my $ports_arr = snmp_get({
        %{$attr},
        OID  => $snmp_info{'PORTS'}{OIDS},
        WALK => 1
      });

      my $ports_list = ();
      for (my $i = 0; $i <= $#{ $ports_arr }; $i++) {
        next if (! $ports_arr->[$i]);
        my (undef, $type) = split(/:/, $ports_arr->[$i]);
        if (@skip_ports_types && !in_array($type, \@skip_ports_types)){
          push @{$ports_list}, $ports_arr->[$i];
        }
      }

      $snmp_info_result{'PORTS'} = $#{$ports_list} + 1;
    }
    return \%snmp_info_result;
  }

  return \%ports_info;
}

#********************************************************
=head2 equipment_change_port_status($attr) - change port status on switch/router (actually, admin port status on switch/router will be changed)

  Port's admin statuses:
    1 - Up
    2 - Down

  Arguments:
    $attr
      PORT            - Port number
      PORT_STATUS     - Change port's admin status to this
      SNMP_TPL        - Filename of SNMP template
      PORT_SHIFT      - Apply this shift to port number
      AUTO_PORT_SHIFT - Apply autoshift to port number. true or false
      SNMP_COMMUNITY
      TIMEOUT         - SNMP timeout
      attrs for snmp_get()/snmp_set()

  Returns:
    1 - if status changed successfully
    0 - if status changing failed

=cut
#********************************************************
sub equipment_change_port_status {
  my ($attr) = @_;

  my $port   = $attr->{PORT};
  my $status = $attr->{PORT_STATUS};

  if (!$port || !$status) {
    return 0;
  }

  my %snmp_ports_template = ();

  my $snmp_template = _get_snmp_oid( $attr->{SNMP_TPL} );

  if ($snmp_template && $snmp_template->{ports}) {
    %snmp_ports_template = %{ $snmp_template->{ports} };
  }
  else {
    return 0;
  }

  if ($attr->{AUTO_PORT_SHIFT}) {
    if ($snmp_ports_template{PORT_INDEX}{OIDS}) {
      my $oid = $snmp_ports_template{PORT_INDEX}{OIDS};
      my $function = $snmp_ports_template{PORT_INDEX}{PARSER};

      my $new_port_id = snmp_get({
        %{$attr},
        OID     => $oid . '.' . $port,
        DEBUG   => ($debug > 2) ? 1 : undef
      });

      if ($function && defined( &{$function} ) ) {
        ($new_port_id) = &{ \&$function }($new_port_id);
      }

      if ($new_port_id) {
        $port = $new_port_id;
      }
      else {
        return 0;
      }
    }
    else {
      return 0;
    }
  }
  elsif ($attr->{PORT_SHIFT}) {
    $port += $attr->{PORT_SHIFT};
  }

  if ($snmp_ports_template{ADMIN_PORT_STATUS}{OIDS}) {
    my $snmp_set_status = snmp_set({
      %{$attr // {}},
      SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
      OID            => [ $snmp_ports_template{ADMIN_PORT_STATUS}{OIDS} . '.' . $port, 'integer', $status ],
      IGNORE_ERRORS  => ($attr->{DEBUG}) ? undef : '.*'
    });

    return $snmp_set_status;
  }
  else {
    return 0;
  }
}

#********************************************************
=head2 get_vlans($attr) - Get VLANs

  Arguments:
    $attr
      SNMP_TPL
      NAS_INFO
      VERSION

  Returns:
    Hash of vlans

=cut
#********************************************************
sub get_vlans{
  my ($attr) = @_;

  my $oid = '.1.3.6.1.2.1.17.7.1.4.3.1.1';

  if($attr->{NAS_INFO}) {
    $attr->{VERSION} //= $attr->{NAS_INFO}->{SNMP_VERSION};
    $attr->{SNMP_TPL} //=$attr->{NAS_INFO}->{SNMP_TPL};
  }

  my $perl_scalar = _get_snmp_oid( $attr->{SNMP_TPL} );
  if($perl_scalar && $perl_scalar->{VLANS}) {
    $oid = $perl_scalar->{VLANS};
  }

  my $value = snmp_get({
    %{$attr},
    OID   => $oid,
    WALK  => 1,
    DEBUG => $FORM{DEBUG}
  });

  my %vlan_hash = ();

  foreach my $line ( @{$value} ){
    next if (!$line);

    if ( $line =~ /^(\d+):(.*)/ ){
      my $vlan_id = $1;
      my $name    = $2;
      $vlan_hash{$vlan_id}{NAME} = $name;
    }
    elsif ( $line =~ /^\d+.(\d+)\.(\d+):(.+)/ ){
      my $type = $1;
      my $vlan_id = $2;
      my $value2 = $3;

      if ( $type == 1 ){
        $vlan_hash{$vlan_id}{NAME} = $value2;
      }
      #ports
      elsif ( $type == 2 ){
        my $p = unpack( "B64", $value2 );
        my $ports = '';
        for ( my $i = 0; $i < length( $p ); $i++ ){
          my $port_val = substr( $p, $i, 1 );
          if ( $port_val == 1 ){
            $ports .= ($i + 1) . ", ";
          }
        }

        $vlan_hash{$vlan_id}{PORTS} = $ports;
      }
      elsif ( $type == 6 ){
        $vlan_hash{$vlan_id}{STATUS} = $value2;
      }
    }
  }

  if($perl_scalar && $perl_scalar->{ports}->{NATIVE_VLAN}->{OIDS}) {
    $oid = $perl_scalar->{ports}->{NATIVE_VLAN}->{OIDS};

    $value = snmp_get({
      %{$attr},
      OID  => $oid,
      WALK => 1
    });

    foreach my $line ( @{$value} ){
      next if (!$line);
      if ( $line =~ /^(\d+):(\d+)/ ){
        my $port_id = $1;
        my $vlan_id = $2;
        if (!$vlan_hash{$vlan_id}{STATUS}) {
          if (!$vlan_hash{$vlan_id}{PORTS} ) {
            $vlan_hash{$vlan_id}{PORTS} .= "$port_id";
          }
          else {
            $vlan_hash{$vlan_id}{PORTS} .= ", $port_id";
          }
        }
      }
    }
  }
  return \%vlan_hash;
}

#********************************************************
=head2 get_port_vlans($attr)

=cut
#********************************************************
sub get_port_vlans {
  my($attr) = @_;

  my %ports_vlans = ();

  my $oid = $attr->{PORT_VLAN_OID};

  my $port_vlan_list = snmp_get({
    TIMEOUT => 10,
    DEBUG   => $debug || 2,
    %{($attr) ? $attr : {}},
    OID     => $oid,
    WALK    => 1
  });

  foreach my $line (@$port_vlan_list) {
    my ($port, $vlan)=split(/:/, $line);
    $ports_vlans{$port}=$vlan;
  }

  return \%ports_vlans;
}

#********************************************************
=head2 get_fdb($attr) - Get FDB table

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO
      SNMP_TPL
      VERSION
      DEBUG

  Returns:
    \%fdb_hash

=cut
#********************************************************
sub get_fdb {
  my ($attr) = @_;

  #$Nas->info({
  #  NAS_ID    => $nas_id,
  #  COLS_NAME => 1,
  #  COLS_UPPER=> 1
  #});

  #=comments
  ## Get fdb from default table
  #  my $oid = $perl_scalar->{FDB_OID} || '.1.3.6.1.2.1.17.4.3.1';    #|| '1.3.6.1.4.1.3320.152.1.1.3';
  #  my $value = snmp_get(
  #    {
  #      %$attr,
  #      OID  => $oid,
  #      WALK => 1
  #    }
  #  );
  #  my %fdb_hash = ();
  #
  #  foreach my $line (@$value) {
  #    my ($oid, $value) = split(/:/, $line, 2);
  #    $oid =~ /(\d+)\.(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})/;
  #    my $type    = $1;
  #    my $mac_dec = $2;
  #    my $mac = _mac_former($mac_dec);
  #
  #    $fdb_hash{$mac_dec}{$type} = ($type == 1) ? $mac : $value;
  #  }
  #=cut

  #dlink version
  # '1.3.6.1.2.1.17.7.1.2.2.1.2';
  #$Equipment->vendor_info( $Equipment->{VENDOR_ID} || $attr->{VENDOR_ID} );
  #For old version

  if ($attr->{NAS_INFO}) {
    $attr->{VERSION}  //= $attr->{NAS_INFO}->{SNMP_VERSION};
    $attr->{SNMP_TPL} //= $attr->{NAS_INFO}->{SNMP_TPL};
  }

  $debug = $attr->{DEBUG} || 0;
  my $nas_type = '';
  my $vendor_name = $attr->{NAS_INFO}->{VENDOR_NAME} || $attr->{NAS_INFO}->{NAME} || q{};
  if ($attr->{NAS_INFO}->{TYPE_ID} && $attr->{NAS_INFO}->{TYPE_ID} == 4) {
    $nas_type = equipment_pon_init($attr);
  }
  elsif ($vendor_name eq 'Cisco') {
    $nas_type = 'cisco';
  }

  my $get_fdb  = $nas_type . '_get_fdb';
  my %fdb_hash = ();

  if ($debug > 3) {
    print "VENDOR: $vendor_name-- $get_fdb\n";
  }

  if (defined( &{$get_fdb} )) {
    if ($debug > 1) {
      print "Function: $get_fdb\n";
    }

    %fdb_hash = &{ \&$get_fdb }( $attr );
  }
  else {
    %fdb_hash = default_get_fdb( $attr );
  }

  return \%fdb_hash;
}

#********************************************************
=head2 default_get_fdb($attr)

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO
      SNMP_TPL
      VERSION
      DEBUG

  Returns:
    %fdb_hash

=cut
#********************************************************
sub default_get_fdb {
  my ($attr) = @_;

  $debug = $attr->{DEBUG} || 0;

  my %fdb_hash = ();
  my $port_vlans;

  my $oid = '.1.3.6.1.2.1.17.7.1.2.2.1.2';
  my $snmp_oids = _get_snmp_oid($attr->{NAS_INFO}{SNMP_TPL}, $attr);

  if ($snmp_oids) {
    if ($snmp_oids->{PORT_VLAN_UNTAGGED}) {
      $attr->{PORT_VLAN_OID} = $snmp_oids->{PORT_VLAN_UNTAGGED};
      $port_vlans = get_port_vlans($attr);
    }
    if ($snmp_oids->{FDB_OID}) {
      $oid = $snmp_oids->{FDB_OID};
    }
  }

  if ($debug > 1) {
    print "OID: $oid\n";
  }

  my $mac_port_list = snmp_get({
    TIMEOUT => 10,
    DEBUG   => $debug || 2,
    %{($attr) ? $attr : {}},
    OID     => $oid,
    WALK    => 1
  });

  my ($expr_, $values, $attribute);
  my @EXPR_IDS = ();

  if ($snmp_oids && $snmp_oids->{FDB_EXPR}) {
    $snmp_oids->{FDB_EXPR} =~ s/\%\%/\\/g;
    ($expr_, $values, $attribute) = split( /\|/, $snmp_oids->{FDB_EXPR} || '' );
    @EXPR_IDS = split( /,/, $values );
  }

  my %port_index_to_num = ();
  if ($attr->{NAS_INFO}->{FDB_USES_PORT_NUMBER_INDEX} && $attr->{NAS_INFO}->{AUTO_PORT_SHIFT}) {
    my $port_index_oid = $snmp_oids->{ports}->{PORT_INDEX}->{OIDS} || '';
    if ($port_index_oid) {
      my $ports_indexes = snmp_get({
        TIMEOUT => 10,
        DEBUG   => $debug || 2,
        %{($attr) ? $attr : {}},
        OID     => $port_index_oid,
        WALK    => 1
      });
      foreach my $line (@{ $ports_indexes }) {
        my ($num, $index) = split( /:/, $line, 2 );
        $port_index_to_num{ $index } = $num;
      }
    }
  }

  my %ports_name = ();
  my $port_name_oid = $snmp_oids->{ports}->{PORT_NAME}->{OIDS} || '';
  if ($port_name_oid) {
    my $value_ = snmp_get({
        TIMEOUT => 10,
        DEBUG   => $debug || 2,
        %{($attr) ? $attr : {}},
        OID     => $port_name_oid,
        WALK    => 1
      });
    foreach my $line (@{ $value_ }) {
      next if (!$line);
      my ($index, $name) = split( /:/, $line, 2 );

      if ($attr->{NAS_INFO}->{FDB_USES_PORT_NUMBER_INDEX}) {
        if ($attr->{NAS_INFO}->{AUTO_PORT_SHIFT}) {
          $index = $port_index_to_num{ $index } || next;
        }
        else {
          my $port_shift = $attr->{NAS_INFO}->{PORT_SHIFT} || 0;
          $index -= $port_shift;
        }
      }

      $ports_name{ $index } = $name;
    }
  }

  foreach my $line (@{ $mac_port_list }) {
    next if (!$line);
    my $vlan      = 0;
    my $mac_dec;
    my $port      = 0;
    my $port_name = '';

    if ($snmp_oids && $snmp_oids->{FDB_EXPR}) {
      my %result = ();
      if (my @res = ($line =~ /$expr_/g)) {
        for (my $i = 0; $i <= $#res; $i++) {
          $result{$EXPR_IDS[$i]} = $res[$i];
        }
      }

      if ($result{MAC_HEX}) {
        $result{MAC} = _mac_former( $result{MAC_HEX}, { BIN => 1 } );
      }

      if ($result{PORT_DEC}) {
        $result{PORT} = dec2hex($result{PORT_DEC});
      }

      $vlan      = $result{VLAN} || 0;
      $mac_dec   = $result{MAC} || '';
      $port      = $result{PORT} || '';
      $port_name = $ports_name{ $port } || '';
    }
    else { #XXX probably never gets here, as default.snmp have FDB_EXPR
      ($oid, $mac_port_list) = split( /:/, $line, 2 );

      $oid =~ /(\d+)\.(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})$/;
      my $record_type = $1;
      $mac_dec = $2 || q{};
      if( $record_type == 1) {
        #$vlan = $value;
      }
      elsif($record_type == 2) {
        $port      = $mac_port_list;
        $port_name =  $ports_name{ $port } || '';
      }
    }

    my $mac = _mac_former( $mac_dec );

    # 1 mac
    $fdb_hash{$mac_dec}{1} = $mac;
    # 2 port
    if(defined($port)) {
      $fdb_hash{$mac_dec}{2} = $port;
    }
    # 3 status
    # 4 vlan
    if($vlan) {
      $fdb_hash{$mac_dec}{4} = $vlan;
    }

    if($port_vlans && $port_vlans->{$port}) {
      $fdb_hash{$mac_dec}{4} = $port_vlans->{$port};
    }

    # 5 port name
    if($port_name) {
      $fdb_hash{$mac_dec}{5} = $port_name;
    }
  }

  return %fdb_hash;
}

#********************************************************
=head2 cisco_get_fdb($attr)

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO
      SNMP_TPL
      VERSION
      DEBUG

  Returns:
    %fdb_result

=cut
#********************************************************
sub cisco_get_fdb {
  my($attr)=@_;
  my %fdb_result = ();

  if($attr->{DEBUG}) {
    $debug = $attr->{DEBUG};
  }

  my $oid = '.1.3.6.1.4.1.9.9.46.1.3.1.1.2';
  my $value = snmp_get({
    TIMEOUT => 10,
    DEBUG   => $debug || 2,
    %{($attr) ? $attr : {}},
    OID     => $oid,
    WALK    => 1
  });

  my @vlans = ();
  foreach my $vlan_info (@$value) {
     if($vlan_info && $vlan_info =~ /(\d+):/) {
       push @vlans, $1;
     }
  }

  my %port_index = ();

  foreach my $vlan ( @vlans ) {
    my $vlan_snmp = $attr->{SNMP_COMMUNITY};
    $vlan_snmp =~ s|\@|\@$vlan\@|;

    my $if_indexes = snmp_get({
      TIMEOUT        => 10,
      DEBUG          => $debug || 2,
      %{($attr) ? $attr : {}},
      SNMP_COMMUNITY => $vlan_snmp,
      OID            => '.1.3.6.1.2.1.17.1.4.1.2',
      WALK           => 1
    });

    foreach my $if_index_info ( @$if_indexes  ) {
      if($if_index_info && $if_index_info =~ /(\d+):(\d+)/) {
        $port_index{$1}=$2;
      }
    }
  }

  #Get fdb per VLAN
  foreach my $vlan ( @vlans ) {
    my $vlan_snmp = $attr->{SNMP_COMMUNITY};
    $vlan_snmp =~ s|\@|\@$vlan\@|;

    my $fdb_list = snmp_get({
      TIMEOUT        => 10,
      DEBUG          => $debug || 2,
      %{($attr) ? $attr : {}},
      SNMP_COMMUNITY => $vlan_snmp,
      OID            => '.1.3.6.1.2.1.17.4.3.1',
      WALK           => 1
    });

    foreach my $fdb_info ( @$fdb_list  ) {
      if($fdb_info && $fdb_info =~ /(\d+)\.([\d\.]+):(.+)/) {
        my $id      = $1;
        my $mac_dec = $2;
        my $result  = $3;

        my $port_name = q{};
        if($id == 1 ) {
          $result = _mac_former( $mac_dec );
        }
        elsif($id == 2) {
          $port_name = $port_index{$result};
        }

        $fdb_result{$mac_dec}{$id} = $result;
        # 3 status
        # 4 vlan
        if($vlan) {
          $fdb_result{$mac_dec}{4} = $vlan;
        }
        # 5 port name

        if($port_name) {
          $fdb_result{$mac_dec}{5} = $port_name;
        }
      }
    }
  }

  return %fdb_result;
}

#********************************************************
=head2 _edge_core_convert_pair_status($status)

  Arguments:
    $status

  Returns:
    $status_text

=cut
#********************************************************
sub _edge_core_convert_pair_status {
  my ($status) = @_;

  my %status_hash = (
    1  => 'notTestedYet',
    2  => 'ok:text-green',
    3  => 'open',
    4  => 'short',
    5  => 'openShort',
    6  => 'crosstalk',
    7  => 'unknown',
    8  => 'impedanceMismatch',
    9  => 'fail:text-red',
    10 => 'notSupport',
    11 => 'noCable',
    12 => 'underTesting'
  );

  return $status_hash{$status};
}

#********************************************************
=head2 _dlink_convert_pair_status($status)

  Arguments:
    $status

  Returns:
    $status_text

=cut
#********************************************************
sub _dlink_convert_pair_status {
  my ($status) = @_;

  my %status_hash = (
    0 => 'ok:text-green',
    1 => 'open',
    2 => 'short',
    3 => 'open-short',
    4 => 'crosstalk',
    5 => 'unknown',
    6 => 'count',
    7 => 'no-cable',
    8 => 'other'
  );

  return $status_hash{$status};
}

#********************************************************
=head2 _dlink_convert_link_status($status)

  Arguments:
    $status

  Returns:
    $status_text

=cut
#********************************************************
sub _dlink_convert_link_status {
  my ($status) = @_;

  my %status_hash = (
    0 => 'link-down',
    1 => 'link-up',
    2 => 'other'
  );

  return $status_hash{$status};
}

#********************************************************
=head2 _dlink_convert_port_type($port_type)

  Arguments:
    $port_type

  Returns:
    $port_type_text

=cut
#********************************************************
sub _dlink_convert_port_type {
  my ($port_type) = @_;

  my %port_type_hash = (
    0 => 'fastEthernet',
    1 => 'gigaEthernet',
    2 => 'other'
  );

  return $port_type_hash{$port_type};
}

#********************************************************
=head2 _huawei_convert_pair_status($status)

  Arguments:
    $status

  Returns:
    $status_text

=cut
#********************************************************
sub _huawei_convert_pair_status {
  my ($status) = @_;

  my %status_hash = (
    1 => 'normal',
    2 => 'abnormalOpen',
    3 => 'abnormalShort',
    4 => 'abnormalOpenShort',
    5 => 'abnormalCrossTalk',
    6 => 'unknown',
    7 => 'notSupport'
  );

  return $status_hash{$status};
}

#********************************************************
=head2 _huawei_last_cable_test_time($seconds_ago)

  Arguments:
    $seconds_ago

  Returns:
    $time_string

=cut
#********************************************************
sub _huawei_convert_last_cable_test_time {
  my ($seconds_ago) = @_;

  return strftime("%F %T", localtime(time() - $seconds_ago));
}

1;
