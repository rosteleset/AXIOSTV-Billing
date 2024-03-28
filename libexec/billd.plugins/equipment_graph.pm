=head1 NAME

 billd plugin

 DESCRIBE: PON load onu info

=cut

use strict;
use AXbills::Filters;
use AXbills::Base qw(in_array);
use SNMP_Session;
use SNMP_util;
use Equipment;
use Data::Dumper;
use warnings;

our (
    $argv,
    $debug,
    %conf,
    $Admin,
    $db,
    $OS
);

my $Equipment = Equipment->new($db, $Admin, \%conf);
_equipment_graph();



#**********************************************************
=head2 _equipment_pon($attr)

  Arguments:
    
    
  Returns:
  
=cut
#**********************************************************
sub _equipment_graph {
  my $equipment_list = $Equipment->_list({COLS_NAME => 1,
                                          PAGE_ROWS => 100000,
                                          STATUS    => '0',
                                          });
  foreach my $line (@$equipment_list) {
    _equipment_graph_parse($line->{nas_id});
  }

}
#**********************************************************
=head2 _equipment_pon_load($nas_id)

=cut
#**********************************************************
sub _equipment_graph_parse {
  my ($nas_id) = @_;

  do 'AXbills/Misc.pm';
  unshift( @INC, '/usr/axbills/AXbills/modules/' );
  load_module('Equipment');
  our $SNMP_TPL_DIR = "/usr/axbills/AXbills/modules/Equipment/snmp_tpl/";

  my $Equipment_list = $Equipment->_list( {
          NAS_ID           => $nas_id,
          NAS_NAME         => '_SHOW',
          MODEL_ID         => '_SHOW',
          REVISION         => '_SHOW',
          TYPE             => '_SHOW',
          SYSTEM_ID        => '_SHOW',
          NAS_TYPE         => '_SHOW',
          MODEL_NAME       => '_SHOW',
          VENDOR_NAME      => '_SHOW',
          STATUS           => '_SHOW',
          NAS_IP           => '_SHOW',
          NAS_MNG_HOST_PORT=> '_SHOW',
          NAS_MNG_USER     => '_SHOW',
          NAS_MNG_PASSWORD => '_SHOW',
          SNMP_TPL         => '_SHOW',
          LOCATION_ID      => '_SHOW',
          VENDOR_NAME      => '_SHOW',
          TYPE_NAME        => '_SHOW',
          COLS_NAME        => 1
  } );

  my $nas_info = $Equipment_list->[0];
  $Equipment->model_info( $nas_info->{model_id} );
  my $SNMP_COMMUNITY = "$nas_info->{nas_mng_password}\@" . (($nas_info->{nas_mng_ip_port}) ? $nas_info->{nas_mng_ip_port} : $nas_info->{nas_ip});

  if($SNMP_COMMUNITY =~ /(.+):(.+)/) {
    $SNMP_COMMUNITY = $1;
    my $SNMP_PORT = $2 || 161;
    if (! in_array($SNMP_PORT, [22])) {
      $SNMP_COMMUNITY .= ':'.$SNMP_PORT;
    }
  }

  if ($nas_info->{status} eq 0) {
    if ($nas_info->{type_name} eq 'PON' ) {
      $nas_info->{NAME} = $nas_info->{vendor_name};
      my $nas_type = equipment_pon_init({NAS_INFO => $nas_info});
      if (!$nas_type) {
        return 0;
      }

      my $graph_list = $Equipment->graph_list({
        NAS_ID    => $nas_id,
        PARAM     => '_SHOW',
        MEASURE_TYPE => '_SHOW',
        PORT      => '_SHOW',
        COLS_NAME => 1
      });

      my %graph_data = ();
      foreach my $graph (@$graph_list){
        $graph_data{$graph->{param}}{$graph->{port}}{ID} = $graph->{id};
        $graph_data{$graph->{param}}{$graph->{port}}{TYPE} = $graph->{measure_type};
      }
      #print Dumper \%graph_data;
      my $onu_list = $Equipment->onu_list({NAS_ID => $nas_id, ONU_GRAPH => '_SHOW', COLS_NAME => 1});

      #my %onu_data = ();
      foreach my $onu (@$onu_list){
        my @onu_graph_types = split(',', $onu->{onu_graph});
        my $snmp = &{ \&{$nas_type} }({TYPE => $onu->{pon_type}});
        #print Dumper $snmp;
        my @onu_graph_data;
        foreach my $graph_type (@onu_graph_types) {
          if ($graph_type eq 'SIGNAL') {
            if ($snmp->{ONU_RX_POWER}->{OIDS}) {
              push @onu_graph_data, {OID => $snmp->{ONU_RX_POWER}->{OIDS}, COMMENTS => $snmp->{ONU_RX_POWER}->{NAME}, TYPE => 'GAUGE'};
            }
            if ($snmp->{OLT_RX_POWER}->{OIDS}) {
              push @onu_graph_data, {OID => $snmp->{OLT_RX_POWER}->{OIDS}, COMMENTS => $snmp->{OLT_RX_POWER}->{NAME}, TYPE => 'GAUGE'};
            }
          }
          elsif ($graph_type eq 'TEMPERATURE') {
            if ($snmp->{main_onu_info}->{TEMPERATURE}->{OIDS}) {
              push @onu_graph_data, {OID => $snmp->{main_onu_info}->{TEMPERATURE}->{OIDS}, COMMENTS => $snmp->{main_onu_info}->{TEMPERATURE}->{NAME}, TYPE => 'GAUGE'};
            }
          }
          elsif ($graph_type eq 'SPEED') {
            if ($snmp->{ONU_IN_BYTE}->{OIDS}) {
              push @onu_graph_data, {OID => $snmp->{ONU_IN_BYTE}->{OIDS}, COMMENTS => $snmp->{ONU_IN_BYTE}->{NAME}, TYPE => 'COUNTER'};
            }
            if ($snmp->{ONU_OUT_BYTE}->{OIDS}) {
              push @onu_graph_data, {OID => $snmp->{ONU_OUT_BYTE}->{OIDS}, COMMENTS => $snmp->{ONU_OUT_BYTE}->{NAME}, TYPE => 'COUNTER'};
            }
          }
        }
        foreach my $line (@onu_graph_data) {
          if ($graph_data{$line->{OID}}{$onu->{onu_snmp_id}}{ID}) {
            $graph_data{$line->{OID}}{USED} = 1;
          }
          else {
            $Equipment->graph_add($line);
            if (!$Equipment->{errno}) {
              $graph_data{ $line->{OID} }{ $onu->{onu_snmp_id} } = ({ COMMENTS => $line->{COMMENTS}, TYPE => $line->{TYPE}, USED => 1});
            }
          }
        }
      }
      foreach my $oid (keys %graph_data) {
        my $value_arr = q{};
        if ($oid) {
          $value_arr = snmp_get(
            {
              SNMP_COMMUNITY => $SNMP_COMMUNITY,
              OID            => $oid,
              WALK           => 1
            }
          );
        }
        print $SNMP_COMMUNITY . "\n";
        print $oid . "\n";
        print Dumper $value_arr;
      }
    }
  }
#    $nas_info->{NAME} = $nas_info->{vendor_name};
#    my $nas_type = equipment_pon_init({NAS_INFO => $nas_info});
#    if (!$nas_type) {
#      return 0;
#    }
#
#    my $onu_database_list = $Equipment->onu_list({
#                  NAS_ID    => $nas_id,
#                  COLS_NAME => 1,
#                  PAGE_ROWS => 100000,
#                  DESCRIPTION  => '_SHOW'
#              });
#    my $created_onu = ();
#    foreach my $onu (@$onu_database_list){
#      $created_onu->{ $onu->{onu_snmp_id} }->{ONU_DESC} = $onu->{comments};
#      $created_onu->{ $onu->{onu_snmp_id} }->{ID} = $onu->{id};
#    }
#    my $get_list_fn = $nas_type . '_onu_list';
#    if ( defined( &{$get_list_fn} ) ) {
#      my $olt_ports = equipment_pon_get_ports({SNMP_COMMUNITY => $SNMP_COMMUNITY, NAS_ID => $nas_id, NAS_TYPE => $nas_type,  SNMP_TPL => $Equipment->{SNMP_TPL}});
#      my $onu_list = &{ \&$get_list_fn }($olt_ports, { SNMP_COMMUNITY => $SNMP_COMMUNITY, DEBUG => $debug });
#      my @MULTI_QUERY = ();
#      print Dumper $onu_list;
#      foreach my $onu (@$onu_list) {
#        if ($created_onu->{ $onu->{ONU_SNMP_ID} }->{ID}) {
#          if ($created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_DESC} && $created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_DESC} ne $onu->{ONU_DESC}){
#            my $set_desc_fn = $nas_type . '_set_desc';
#            if ( defined( &{$set_desc_fn} ) ){
#              my $snmp = &{ \&{$nas_type} }({TYPE => $onu->{PON_TYPE}});
#              #print "CHANGE $onu->{ONU_SNMP_ID} TYPE: \"$onu->{PON_TYPE}\" DESC: \"$onu->{ONU_DESC}\" OID: \"$snmp->{ONU_DESC}->{OIDS}.$onu->{ONU_SNMP_ID}\"";
#              &{ \&$set_desc_fn }({ SNMP_COMMUNITY => $SNMP_COMMUNITY,
#                      OID            => $snmp->{ONU_DESC}->{OIDS}.'.'.$onu->{ONU_SNMP_ID},
#                      DESC           => $created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_DESC}
#                  });
#            }
#          }
#          #print Dumper $Equipment;
#          push @MULTI_QUERY, [
#                  $onu->{OLT_RX_POWER} || '',
#                  $onu->{ONU_RX_POWER} || '',
#                  $onu->{ONU_TX_POWER} || '',
#                  $onu->{ONU_STATUS},
#                  $onu->{ONU_IN_BYTE} || '',
#                  $onu->{ONU_OUT_BYTE} || '',
#                  $onu->{ONU_DHCP_PORT},
#                  $created_onu->{ $onu->{ONU_SNMP_ID} }->{ID}
#              ];
#          #$Equipment->onu_change( { ID => $created_onu->{ $onu->{ONU_SNMP_ID} }->{ID}, NAS_ID => $nas_id, %{$onu} } );
#          delete  $created_onu->{ $onu->{ONU_SNMP_ID} };
#        }
#        else {
#          $Equipment->onu_add( { NAS_ID => $nas_id, %{$onu} } );
#        }
#      }
#      $Equipment->onu_change( { MULTI_QUERY => \@MULTI_QUERY } );
#      foreach my $snmp_id (keys %{ $created_onu }) {
#        $Equipment->onu_del( $created_onu->{ $snmp_id }->{ID} ) if ($created_onu->{ $snmp_id }->{ID});
#      }
#    }
#  }
}
#**********************************************************
=head2 _equipment_add_graph($attr)

=cut
#**********************************************************
sub _equipment_add_graph {

  return 0;
}
1