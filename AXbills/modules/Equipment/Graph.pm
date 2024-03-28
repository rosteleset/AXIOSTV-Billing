#**********************************************************
=head1 NAME

  Equipment::Graph

=cut
#**********************************************************


use strict;
use warnings;
use AXbills::Base qw(load_pmodule);

our(
  $html,
  %lang,
  $var_dir
);

my $load_data = load_pmodule('RRDTool::OO', { SHOW_RETURN => 1 });

#**********************************************************
=head2 add_graph($attr)
   Arguments:
     $attr
       NAS_ID  - Nas id
       PORT    - Port id
       TYPE    - Graph type: SPEED, SIGNAL, TEMPERATURE
       STEP    - Step: 60, 300, 600 (default 300)
       DATA    - Data hash
=cut
#**********************************************************
sub add_graph {
  my ($attr) = @_;

  if ($load_data) {
    return 0;
  }

  my $rrd_dir = $var_dir . "db/rrd";

  if (!-d $var_dir . "db") {
    mkdir $var_dir . "db", 777;
    print "mkdir " . $var_dir . "db \n";
  }
  if (!-d $var_dir . "db/rrd") {
    mkdir $var_dir . "db/rrd", 777;
    print "mkdir " . $var_dir . "db/rrd \n";
  }

  my $archive = {
    60 => [
      archive => { rows => 1440, cpoints => 1,   cfunc => 'AVERAGE' },
      archive => { rows => 672,  cpoints => 15,  cfunc => 'AVERAGE' },
      archive => { rows => 744,  cpoints => 60,  cfunc => 'AVERAGE' },
      archive => { rows => 1460, cpoints => 360, cfunc => 'AVERAGE' },
      archive => { rows => 1440, cpoints => 1,   cfunc => 'MAX' },
      archive => { rows => 672,  cpoints => 30,  cfunc => 'MAX' },
      archive => { rows => 744,  cpoints => 120, cfunc => 'MAX' },
      archive => { rows => 1460, cpoints => 360, cfunc => 'MAX' },
    ],
    300 => [
      archive => { rows => 288,  cpoints => 1,  cfunc => 'AVERAGE' },
      archive => { rows => 672,  cpoints => 3,  cfunc => 'AVERAGE' },
      archive => { rows => 744,  cpoints => 12, cfunc => 'AVERAGE' },
      archive => { rows => 1460, cpoints => 72, cfunc => 'AVERAGE' },
      archive => { rows => 288,  cpoints => 1,  cfunc => 'MAX' },
      archive => { rows => 672,  cpoints => 3,  cfunc => 'MAX' },
      archive => { rows => 744,  cpoints => 12, cfunc => 'MAX' },
      archive => { rows => 1460, cpoints => 72, cfunc => 'MAX' },
    ],
    600 => [
      archive => { rows => 144,  cpoints => 1,  cfunc => 'AVERAGE' },
      archive => { rows => 336,  cpoints => 3,  cfunc => 'AVERAGE' },
      archive => { rows => 744,  cpoints => 6,  cfunc => 'AVERAGE' },
      archive => { rows => 1460, cpoints => 36, cfunc => 'AVERAGE' },
      archive => { rows => 144,  cpoints => 1,  cfunc => 'MAX' },
      archive => { rows => 336,  cpoints => 3,  cfunc => 'MAX' },
      archive => { rows => 744,  cpoints => 6,  cfunc => 'MAX' },
      archive => { rows => 1460, cpoints => 36, cfunc => 'MAX' },
    ],
    0 => [
      archive => { rows => 144,  cpoints => 1,  cfunc => 'AVERAGE' },
      archive => { rows => 336,  cpoints => 3,  cfunc => 'AVERAGE' },
      archive => { rows => 744,  cpoints => 6,  cfunc => 'AVERAGE' },
      archive => { rows => 1460, cpoints => 36, cfunc => 'AVERAGE' },
      archive => { rows => 144,  cpoints => 1,  cfunc => 'MAX' },
      archive => { rows => 336,  cpoints => 3,  cfunc => 'MAX' },
      archive => { rows => 744,  cpoints => 6,  cfunc => 'MAX' },
      archive => { rows => 1460, cpoints => 36, cfunc => 'MAX' },
    ]
  };

  # my $step = (defined($attr->{STEP}) && ($attr->{STEP} eq 60 || $attr->{STEP} eq 300 || $attr->{STEP} eq 600) ) ? $attr->{STEP} : '300';
  my $step = defined($attr->{STEP})? $attr->{STEP} : '300';

  my @datasource = ();
  my %values = ();
  my $rrdfile = $rrd_dir. "/" . $attr->{NAS_ID} . "_" . $attr->{PORT} . "_" . lc($attr->{TYPE}) . ".rrd";
  my $rrd = RRDTool::OO->new( file => $rrdfile );

  foreach my $line (@{$attr->{DATA}}) {
    push @datasource, ( data_source => { name => $line->{SOURCE} , type  => $line->{TYPE} } );
    $values{$line->{SOURCE}} =  $line->{DATA};
  }
  
  unless (!-f $rrdfile) {
    my $info = $rrd->info();
    if ($info->{step} != $step) {
      del_graph_data($attr);
    }
  }

  unless (-f $rrdfile) {
    $rrd->create(
      step => $step,
      @datasource,
      @{$archive->{$step} || $archive->{0}}
    );
  }

  $rrd->update( values => \%values );

  return 1;
}

#**********************************************************
=head2 get_graph_data($attr)

   Arguments:
     $attr
       NAS_ID   - Nas id
       PORT     - Port id
       TYPE     - Graph type: SPEED, SIGNAL, TEMPERATURE
       DS_NAMES - Array data source names
       START_TIME - Start unixtime
       END_TIME - End unixtime

=cut
#**********************************************************
sub get_graph_data {
  my ($attr) = @_;

  if ($load_data) {
    print $load_data;
    return 0;
  }

  my $rrdfile = $var_dir."db/rrd/".$attr->{NAS_ID}."_".$attr->{PORT}."_".lc($attr->{TYPE}).".rrd";
  #$rrdfile = '/home/asm/tmp/101_4194304000.11_signal.rrd';
  #$rrdfile = '/home/asm/tmp/101_4194304000.14_speed.rrd';

  unless (-f $rrdfile) {
    $html->message( 'err', $lang{ERROR}, "Can't open file '$rrdfile' $!" );
    return 0;
  }

  my $rrd = RRDTool::OO->new( file => $rrdfile );
  my $ds_info = $rrd->info()->{ds};
  my @def = ();
  my @xport = ();

  if ($FORM{DEBUG}) {
    foreach my $ds (keys %$ds_info) {
      print "<b>$ds</b><br>";
      foreach my $key (keys %{$ds_info->{$ds}}) {
        print "$key - $ds_info->{$ds}->{$key} <br>";
      }
    }

    my $start_rrd_time = $rrd->first();
    my $stop_rrd_time = $rrd->last();

    print "START_RRD: $start_rrd_time STOP_RRD: $stop_rrd_time";
  }

  foreach my $ds_name (@{ $attr->{DS_NAMES} }) {
    if ($ds_info->{$ds_name}) {
      push @def, {
        vname  => $ds_name."_vname",
        file   => $rrdfile,
        dsname => $ds_name,
        cfunc  => "MAX"
      };

      push @xport, {
        vname  => $ds_name."_vname",
        legend => $ds_name
      };
    }
  }

  my $start_time = $attr->{START_TIME} || time() - 120 * 3600;
  my $end_time = $attr->{END_TIME} || time();

  if (@def) {
    my $results = $rrd->xport(
      start => $start_time,
      end   => $end_time,
      def   => \@def,
      xport => \@xport
    );

    return $results;
  }

  return 0;
}


#**********************************************************
=head2 del_graph_data($attr)

   Arguments:
     $attr
       NAS_ID   - Nas id
       PORT     - Port id
       TYPE     - Graph type: SPEED, SIGNAL, TEMPERATURE

=cut
#**********************************************************
sub del_graph_data {
  my ($attr) = @_;
  my $rrdfile = $var_dir."db/rrd/".$attr->{NAS_ID}."_".$attr->{PORT}."_".lc($attr->{TYPE}).".rrd";

  if(-f $rrdfile) {
    unlink($rrdfile) or $html->message('err', $lang{ERROR}, "Can't delete file '$rrdfile' $!");
  }

  return 0;
}


1
