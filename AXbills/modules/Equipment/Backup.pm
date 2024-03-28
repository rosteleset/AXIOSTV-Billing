=head1 NAME

  Equipment::Backup;

=cut

use strict;
use warnings FATAL => 'all';
use POSIX qw(strftime);
use AXbills::Base qw(int2byte);

our(
  %lang,
  $Equipment,
  $SNMP_TPL_DIR
);

our AXbills::HTML $html;
my $json = JSON->new->allow_nonref;

#********************************************************
=head2 equipment_backup()

=cut
#********************************************************
sub equipment_backup {

  equipment_show_snmp_backup_files( "BACKUP", $FORM{NAS_ID} );

  return 1;
}

#**********************************************************
=head2 _equipment_snmp_op($operation)

  Arguments:
    $operation - string, 'UPLOAD' or 'BACKUP'

=cut
#**********************************************************
sub _equipment_snmp_op {
  my $nas_id = $FORM{NAS_ID};

  unless ( $nas_id ) {
    $html->message( 'err', $lang{ERROR}, "$lang{REQUIRED_ARG}: NAS_ID" );

    my $equipment_list = $Equipment->_list( { NAS_NAME => '_SHOW', COLS_NAME => 1 } );
    _error_show( $Equipment );

    $FORM{visual} = 8;

    $html->tpl_show( _include( 'equipment_panel', 'Equipment' ), {
        DEVICE_SEL => $html->form_select( 'NAS_ID', {
            SELECTED       => '',
            SEL_LIST       => $equipment_list,
            SEL_KEY        => 'nas_id',
            SEL_VALUE      => 'nas_id,nas_name',
            NO_ID          => 1,
            MAIN_MENU      => get_function_index( 'equipment_model' ),
            MAIN_MENU_ARGV => "chg=" . ($Equipment->{MODEL_ID} || '')
          } )
      });
    return 0;
  }

  my $backup_directory = $conf{TFTP_ROOT};

  if ( !$backup_directory ) {
    $html->message( 'err', $lang{ERROR}, '$conf{TFTP_ROOT} is not defined' );
    $backup_directory = '/srv/tftp/';
    $conf{TFTP_ROOT} = '/srv/tftp/';
  }

  my $operation = $FORM{OPERATION} || 'BACKUP';

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
    COLS_NAME        => 1,
    COLS_UPPER       => 1
  } );

  if ( _error_show( $Equipment ) ) {
    return 0;
  }

  my $Equipment_info = $Equipment_list->[0];

  my $model_name = $Equipment_info->{MODEL_NAME};
  my $vendor_name = $Equipment_info->{VENDOR_NAME};
  my $nas_ip = $Equipment_info->{NAS_IP};
  my $revision = $Equipment_info->{REVISION} || '';

  my $HHMM = strftime("%H%M", localtime( time ));
  my $cur_time_string = "$DATE\_$HHMM";
  my $default_backup_name = lc "$cur_time_string\_nas\_$nas_id\_.cfg";
  my $backup_name = $FORM{BACKUP_NAME} || $default_backup_name;

  my $tftpserv = $FORM{TFTPSERV} || $conf{TFTP_SERVER_IP};

  unless ( $nas_ip && $tftpserv ){
    $FORM{action} = '';
  }

  if ( $FORM{action} ) {

    # Get community and nas_mng_ip_port
    my $community_name = $Equipment_info->{NAS_MNG_PASSWORD};

    # Read SNMP template ang get oids we need for operation
    my $oids_arr = _get_snmp_oids_array( $operation, $vendor_name, $model_name, $revision, $tftpserv, $backup_name );

    if ( $oids_arr && ref $oids_arr eq 'ARRAY' ) {

      my $snmp_community = $community_name . '@' . $nas_ip;

      $html->message( 'info', 'SNMP', $lang{SNMP_SURVEY} );

      my $success = snmp_set({
        OID            => $oids_arr,
        SNMP_COMMUNITY => $snmp_community,
      });

      if ( $success ) {

        $html->message( 'info', 'SNMP', $lang{SUCCESS} );

        if ($operation eq 'BACKUP') {

          my $timeout = 5;
          # Wait for router to upload config
          do {
            $timeout--;
            sleep 1;
          }
            while ( ! -e "$backup_directory/$backup_name" || ($timeout > 0) );

        }

        return 1;
      }
      else {
        $html->message( 'err', $lang{SNMP_SURVEY}, $lang{ERROR} );
        return 0;
      }
    }
  }

  my %template_info = (
    VENDOR_NAME => $vendor_name,
    MODEL_NAME  => $model_name,
    NAS_IP      => $nas_ip,
    TFTPSERVER  => $tftpserv,
    BACKUP_NAME => $backup_name,
    REVISION    => $revision,
  );

  $html->tpl_show( _include( 'equipment_snmp_backup', 'Equipment' ), { %template_info, %FORM } );

  return 1;
}

#********************************************************
=head2 equipment_snmp_backup()

=cut
#********************************************************
sub equipment_snmp_backup {
  return _equipment_snmp_op("BACKUP");
}

#********************************************************
=head2 equipment_snmp_upload()

=cut
#********************************************************
sub equipment_snmp_upload {
  return _equipment_snmp_op("UPLOAD");
}

#********************************************************
=head2 _get_snmp_oids_array($section, $vendor, $model_name, $revision, $hostconn, $tftpserv, $backup_name)

  Arguments:
   $vendor               - as defined in Equipment_models.sql
   $model_name           - as defined in Equipment_models.sql
   $revision             - revision of board. Required for D-Link
   $tfptpserv            - ip address of tftp server where backup will be loaded
   $backup_name          - name that config will be saved
   $section              - BACKUP / UPLOAD

 Returns:
   Success:
     array of oids
   Fail:
    0

=cut
#********************************************************
sub _get_snmp_oids_array {
  my ($section, $vendor, $model_name, $revision, $tftpserv, $backup_name) = @_;

  return 0 unless ( $vendor && $tftpserv && $backup_name);

  if ( $vendor eq 'D-Link' ) {

    if ( !defined( $model_name ) || $model_name eq '' ) {
      $html->message( 'err', $lang{ERROR}, "$lang{REQURED_ARG} : MODEL_NAME" );
      return 0;
    }

    $model_name =~ /([a-zA-Z]+)\-([0-9]+)/;
    my $model = $1;
    my $series = $2;

    unless ( defined $model_name ) {
      $html->message( 'err', $lang{ERROR}, "Can't parse D-Link model series in $model_name" );
      return 0;
    };


    my $snmp_tpl_name = '';

    my $has_general_template = -e  $SNMP_TPL_DIR . 'dlink/' .  lc "$model$series\_all\.snmp";

    if ($has_general_template) {
      $snmp_tpl_name = $SNMP_TPL_DIR . 'dlink/' . lc("$model$series\_all\.snmp");
    }
    else {
      if (!defined( $revision ) || $revision eq '' ) {
        $html->message( 'err', $lang{ERROR}, "$lang{REQUIRED_ARG} : $lang{REVISION}" );
        return 0;
      }
      else {
        my $has_specific_revision =  -e  $SNMP_TPL_DIR . 'dlink/' .  lc "$model$series\_$revision\.snmp";

        if ($has_specific_revision){
          $snmp_tpl_name =  $SNMP_TPL_DIR . 'dlink/' . lc "$model$series\_$revision\.snmp";
        }
      }
    }

    my $json_template = file_op( {
      FILENAME => $snmp_tpl_name,
      PATH   => $SNMP_TPL_DIR . 'dlink/'
    } );

    if ( !$json_template ) {
      # Check if '_all.snmp' exists

      $html->message( 'err', $lang{ERROR}, $SNMP_TPL_DIR . $snmp_tpl_name . " not found" );
      return 0;
    }

    my %template_info = ();
    $template_info{TFTP_IP} = $tftpserv;
    $template_info{BACKUP_NAME} = $backup_name;

    my $rendered_template = $html->tpl_show( $json_template, \%template_info,
      { OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 } );

    # Decode from JSON
    my $json_rendered = $json->decode( $rendered_template );

    my $backup_section = $json_rendered->{$section};

    if ( !$backup_section ) {
      $html->message( 'err', $lang{ERROR}, "No $section section in $snmp_tpl_name" );
      return 0;
    }

    my @OIDS = @{ $backup_section->{OIDS} };

    # One dimension array;
    my @flatten_array = ();
    foreach my $oid_line (@OIDS){
      push(@flatten_array, @{$oid_line}[0,1,2]);
    }

    return \@flatten_array;
  }
  else {
    $html->message( 'err', $lang{ERROR}, "$vendor not implemented" );
  }
  return 0;
}

#********************************************************
=head2 equipment_show_snmp_backup_files()

=cut
#********************************************************
sub equipment_show_snmp_backup_files {
  my ($operation, $nas_id) = @_;

  $operation = $operation || $FORM{OPERATION} || 'BACKUP';
  $nas_id = $nas_id || $FORM{NAS_ID} || '';

  my $backup_directory = $conf{TFTP_ROOT};

  if ( !$backup_directory ) {
    $html->message( 'err', $lang{ERROR}, '$conf{TFTP_ROOT} is not defined' );
    $backup_directory = '/srv/tftp/';
    $conf{TFTP_ROOT} = '/srv/tftp/';
  }

  if ( $FORM{download} ) {
    my $filename = $FORM{download};

    my ($size) = (stat( $filename ))[7];

    # Read file
    my $content = '';
    $content = file_op({
      FILENAME   => $filename,
      PATH       => $backup_directory,
      SKIP_CHECK => 1
    });
    if ( $content eq '' ) {
      print "Status: 404 Not found";
      exit( 1 );
    }

    # Retrive file size
    my $size_header = ($size) ? "  size=$size" : '';

    print "Content-Type: text/plain;  filename=\"$filename\"\n" . "Content-Disposition:  attachment;  filename=\"$filename\";$size_header\n\n";
    print $content;

    # End of download
    exit( 0 );
  }

  if ( $FORM{del} && $FORM{COMMENTS} ) {
    my $filename = $FORM{del};

    if ( $filename !~ /^([-\@\w.]+)$/ ) {
      $html->message( 'err', $lang{ERROR}, "Security error '$filename'.\n" );
      return 0;
    }
    else {
      my $status = unlink( "$backup_directory/$filename" );
      if ( $status ) {
        $html->message( 'info', $lang{INFO}, "$lang{DELETED} : $backup_directory/$filename" );
      }
      else {
        $html->message( 'err', $lang{INFO}, "$lang{DEL} $backup_directory/$filename [$!]" );
      }
    }
  }

  # THIS FUNCTION IS SUBFUNCTION
  my $file_operations_index = get_function_index( 'equipment_show_snmp_backup_files' );
  my $ports_index = get_function_index( 'equipment_ports' ); #XXX equipment_ports is not in config. probably is not working.

  my $v_index = $file_operations_index;
  if ($FORM{visual} && $FORM{visual} ne ''){
    $v_index = "$ports_index&visual=$FORM{visual}";
  }

  if (! $nas_id ) {
    my $equipment_list = $Equipment->_list( {
      NAS_NAME  => '_SHOW',
      COLS_NAME => 1
    } );
    _error_show( $Equipment );

    my $nas_select = $html->form_select( 'NAS_ID', {
        SELECTED       => '',
        SEL_LIST       => $equipment_list,
        SEL_KEY        => 'nas_id',
        SEL_VALUE      => 'nas_id,nas_name',
        SEL_OPTIONS    => {'' => ''},
        NO_ID          => 1,
        MAIN_MENU      => get_function_index( 'equipment_model' ),
        MAIN_MENU_ARGV => "chg=" . ($Equipment->{MODEL_ID} || '')
      } );

    $html->tpl_show( _include( 'equipment_panel', 'Equipment' ), {
        DEVICE_SEL => $nas_select
      }
    );
  }

  my $files_list_ref = _get_files_in($conf{TFTP_ROOT}, {FILTER => $nas_id ? "_nas_$nas_id\_" : ''});

  my @contents = @{ ($files_list_ref) ? $files_list_ref : [] };

  my @directory_content = ();
  foreach my $filename ( sort @contents ) {
    my $filepath = "$conf{TFTP_ROOT}/$filename";

    # Retrieve file stats
    my ($size, $mtime) = (stat( $filepath ))[7, 9];

    # Format creation date
    my $date = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( $mtime ) );

    # Count MD5 for file
    my $CRC = _md5_of($filepath);

    my $download_link = $html->button(
      '',
      "qindex=$file_operations_index&download=$filename",
      { ICON => 'fa fa-download' }
    );

    my $upload_btn = '';
    if ( $nas_id ) {

      my $upload_index = get_function_index( 'equipment_snmp_upload' );

      my $upload_link =  "?qindex=$upload_index"
        . "&header=2"
        . "&NAS_ID=$nas_id"
        . "&OPERATION=UPLOAD"
        . "&BACKUP_NAME=$filename";

      $upload_btn = $html->button( '', undef, {
          JAVASCRIPT     => '',
          SKIP_HREF      => 1,
          NO_LINK_FORMER => 1,
          class         => 'btn btn-xs btn-warning',
          ICON           => 'fa fa-upload',
          title          => $lang{ADD},
          ex_params      => qq/onclick=loadToModal('$upload_link')/
        });
    }

    my $del_link = '';
    $del_link = $html->button('',
      "index=$file_operations_index&del=$filename",
      {
        ICON    => 'fa fa-trash text-danger',
        MESSAGE => "$lang{DEL} $filename"
      }
    );

    my @file_row = (
      $filename,
      $date,
      int2byte( $size ),
      $CRC,
      $download_link,
      $upload_btn,
      $del_link
    );

    push( @directory_content, \@file_row );
  }

  my $add_index = get_function_index( 'equipment_snmp_backup' );

  my $backup_in_modal_btn = $html->button( '', undef, {
      class          => 'add',
      JAVASCRIPT     => '',
      SKIP_HREF      => 1,
      NO_LINK_FORMER => 1,
      title          => $lang{ADD},
      ex_params      => qq/onclick=loadToModal('?qindex=$add_index&header=2&NAS_ID=$nas_id&OPERATION=BACKUP')/,
    });


  my ($table) = result_former({
    DEFAULT_FIELDS    => 'NAME,DATE,SIZE,MD5,DOWNLOAD,UPLOAD,DEL',
    FUNCTION_FIELDS => 'del',
    EXT_TITLES      => {
      name     => $lang{NAME},
      date     => $lang{DATE},
      size     => $lang{SIZE},
      md5      => 'MD5',
      download => 'Download',
      upload   => 'Upload',
      del      => $lang{DEL},
    },
    TABLE      =>   {
      width            => '100%',
      caption          => ($operation eq 'UPLOAD') ? "Upload" : 'Backup',
      qs               => "index=$index&NAS_ID=$nas_id",
      SHOW_COLS_HIDDEN => {
        NAS_ID => $nas_id,
      },
      MENU             => [ ($nas_id) ? $backup_in_modal_btn : '' ],
      ID               => 'EQUIPMENT_BACKUP_LIST',
    },
    MODULE          => 'Equipment',
  });

  print result_row_former({
    table  => $table,
    ROWS   => \@directory_content,
  });

  return 1;
}


1;
