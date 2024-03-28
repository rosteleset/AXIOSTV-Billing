package Sorm::Fenix;
=head1 NAME

  Fenix SORM

=head1 DOCS

  version: v3.3

=head1 VERSION

  VERSION: 0.38
  UPDATE: 20220222

=cut

use strict;
use warnings FATAL => 'all';

use Companies;
use Time::Piece;
use AXbills::Misc qw(translate_list);
use AXbills::Base qw(in_array ip2int);
use Internet;
use Data::Dumper;

my ($User, $Company, $Internet, $Sessions, $Nas, $Abon, $Admins, $Sorm, $debug);

use Sorm::Sorm;

my Payments $Payments;
my %online_mac = ();

my $service_begin_date = '2010-01-01 01:00:00';
my $service_end_date = '2030-12-31 23:59:59';
my $t = localtime;

my $month = sprintf("%02d", $t->mon());
my $year = sprintf("%04d", $t->year());
my $day = sprintf("%02d", $t->mday());
my $hour = sprintf("%02d", $t->hour());
my $min = sprintf("%02d", $t->min());

my $sufix = $year . $month . $day . "_" . $hour . $min . ".txt";
my %reports = (
  ABONENT               => "$main::var_dir/sorm/Fenix/ABONENT_" . $sufix,
  ABONENT_IDENT         => "$main::var_dir/sorm/Fenix/ABONENT_IDENT_" . $sufix,
  ABONENT_SRV           => "$main::var_dir/sorm/Fenix/ABONENT_SRV_" . $sufix,
  ABONENT_ADDR          => "$main::var_dir/sorm/Fenix/ABONENT_ADDR_" . $sufix,
  PAYMENT               => "$main::var_dir/sorm/Fenix/PAYMENT_" . $sufix,
  PAY_TYPE              => "$main::var_dir/sorm/Fenix/PAY_TYPE_" . $sufix,
  DOC_TYPE              => "$main::var_dir/sorm/Fenix/DOC_TYPE_" . $sufix,
  IP_PLAN               => "$main::var_dir/sorm/Fenix/IP_PLAN_" . $sufix,
  GATEWAY               => "$main::var_dir/sorm/Fenix/GATEWAY_" . $sufix,
  IP_GATEWAY            => "$main::var_dir/sorm/Fenix/IP_GATEWAY_" . $sufix,
  SUPPLEMENTARY_SERVICE => "$main::var_dir/sorm/Fenix/SUPPLEMENTARY_SERVICE_" . $sufix,
  REGIONS               => "$main::var_dir/sorm/Fenix/REGIONS_" . $sufix,
);

#**********************************************************
=head2 new($conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $conf, $db, $Admin, $attr) = @_;

  my $self = {
    debug => $attr->{DEBUG} || 0,
    admin => $Admin,
    db    => $db,
    conf  => $conf,
    argv  => $attr
  };

  bless($self, $class);

  $debug = $self->{debug} || 0;

  $self->init();

  return $self;
}

#**********************************************************
=head2 init()

=cut
#**********************************************************
sub init {
  my $self = shift;

  $User = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Company = Companies->new($self->{db}, $self->{admin}, $self->{conf});
  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});
  $Payments = Finance->payments($self->{db}, $self->{admin}, $self->{conf});
  $Nas = Nas->new($self->{db}, $self->{admin}, $self->{conf});
  $Admins = Admins->new($self->{db}, $self->{admin}, $self->{conf});
  $Sorm = Sorm->new($self->{db}, $self->{admin}, $self->{conf});

  my $filename;
  my $fh;
  my $argv = $self->{argv};

  if ($argv->{START}) {
    mkdir($main::var_dir . '/sorm/');
    mkdir($main::var_dir . '/sorm/Fenix');

    $self->PAY_TYPE_report(); #actual
    $self->DOC_TYPE_report(); #actual
    $Sorm->gateway_report();
    $Sorm->supplementary_service();
    $self->REGIONS_report(); #actual
    $Sorm->ipplan_report();
    $Sorm->paymentsGetOldData();
    $Sorm->abonentGetNewData();
    $self->send();

  } else {
    $Sorm->gateway_report();
    $Sorm->supplementary_service();
    $Sorm->abonentGetNewData();;
    $Sorm->paymentsGetOldData();
    $Sorm->ipplan_report();
    $self->send();
  }

  return 1;
}

#**********************************************************
=head2 REGIONS_report()

=cut
#**********************************************************
sub REGIONS_report {
  my $self = shift;

  _add_header('REGIONS');

  my @arr = (
    $self->{conf}->{SORM_ISP_ID}, # ID
    $service_begin_date, # BEGIN_TIME
    $service_end_date, # END_TIME
    $self->{conf}->{SORM_REGION}, # DESCRIPTION
    '', # MCC
    '', # MNC
  );

  _add_report("REGIONS", @arr);

  return 1;
}

#**********************************************************
=head2 PAY_TYPE_report()

=cut
#**********************************************************
sub PAY_TYPE_report {
  my $self = shift;

  _add_header("PAY_TYPE");

  do ("/usr/axbills/language/russian.pl");
  my $types = translate_list($Payments->payment_type_list({ COLS_NAME => 1 }));

  foreach my $type (@$types) {
    my @arr;
    $type->{id} =~ s/^\s+|\s+$//g;
    $arr[0] = $type->{id} || 0;
    $arr[1] = $service_begin_date;
    $arr[2] = $service_end_date;
    $arr[3] = $type->{name};
    $arr[4] = $self->{conf}->{SORM_ISP_ID};

    _add_report("PAY_TYPE", @arr);
  }
  return 1;
}
#**********************************************************
=head2 DOC_TYPE_report()

=cut
#**********************************************************
sub DOC_TYPE_report {
  my $self = shift;

  _add_header("DOC_TYPE");
  my @arr = ();
  $arr[0] = 0;
  $arr[1] = $service_begin_date;
  $arr[2] = $service_end_date;
  $arr[3] = "Паспорт";
  $arr[4] = $self->{conf}->{SORM_ISP_ID};

  _add_report("DOC_TYPE", @arr);

  return 1;
}

#**********************************************************
=head2 static_report($type)

  Argumnets:
    $type Report type

  Return:
    TRUE or FALSE

=cut
#**********************************************************
#sub static_report {
#  my ($type)=@_;
#
#  if (! -f "$main::var_dir/sorm/Fenix/static/$type" ) {
#    return 0;
#  }

  #_log("LOG_INFO", "static_reports: $type");

#  my $content = q{};
#  open(my $fh, '<', "$main::var_dir/sorm/Fenix/static/$type");
#    $content = <$fh>;
#  close($fh);
#
#  _save_report($type, $content);
#
#  return 1;
#}

#**********************************************************
=head2 GATEWAY_report()

=cut
#**********************************************************
sub GATEWAY_report {
  my $self = shift;

  _add_header("GATEWAY");
  if (static_report('GATEWAY')) {
    return 1;
  }

  my $nas_list = $Nas->list({
    COLS_NAME    => 1,
    NAS_ID       => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    DESCR        => '_SHOW',
    CHANGED	 => '_SHOW',
    PAGE_ROWS    => 60000,
  });

  for my $nas (@$nas_list) {
    my @arr = ();

    $arr[0] = $nas->{nas_id};
    $arr[1] = $nas->{CHANGED};
    $arr[2] = $service_end_date;
    $arr[3] = $nas->{descr};
    $arr[4] = 5;
    $arr[6] = 1; #ADDRESS_TYPE 1 - Unstructure
    $arr[7] = 1;
    @arr[8 .. 15] = ("") x 8;
    $arr[16] = $nas->{address_full};
    $arr[17] = $self->{conf}->{SORM_ISP_ID};

    _add_report("GATEWAY", @arr);
  }

  return 1;
}

#**********************************************************
=head2 GATEWAY_report()

=cut
#**********************************************************
sub IP_GATEWAY_report {
  my $self = shift;

  _add_header("IP_GATEWAY");

  if (static_report('IP_GATEWAY')) {
    return 1;
  }

  my $nas_list = $Nas->list({
    NAS_ID       => '_SHOW',
    NAS_IP       => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    DESCR        => '_SHOW',
    PAGE_ROWS    => 60000,
    COLS_NAME    => 1,
  });

  for my $nas (@$nas_list) {
    my @arr = ();

    $arr[0] = $nas->{nas_id};
    $arr[1] = 0;
    $arr[2] = sprintf("%X", ip2int($nas->{ip}));
    $arr[3] = 0;
    $arr[4] = "";
    $arr[6] = $self->{conf}->{SORM_ISP_ID};

    _add_report("IP_GATEWAY", @arr);
  }

  return 1;
}

#**********************************************************
=head2 _add_report($type, @params)

  Arguments:
    $type
    @params

  Results:
   TRUE or FALSE

=cut
#**********************************************************
sub _add_report {
  my ($type, @params) = @_;

  my $string = "";
  foreach my $line (@params) {
    $line //= q{};
    $line =~ s/;/ /;
    $string .= $line . ';';
  }

  $string =~ s/\r/ /g;
  $string =~ s/\n/ /g;
  $string =~ s/\t/ /g;
  $string =~ s/;$/\n/;

  # if ($debug > 3) {
  #   print "TYPE: $type\n";
  # }

  _save_report($type, $string);

  return 1;
}

#**********************************************************
=head2 _add_header($type)

  Arguments:
    $type

  Results:
   TRUE or FALSE

=cut
#**********************************************************
sub _save_report {
  my($type, $content)=@_;

  if ($debug > 5) {
    print "$content\n";
  }

  my $filename = $reports{$type};
  open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
    print $fh $content;
  close $fh;

  return 1;
}


#**********************************************************
=head2 _add_header($type)

  Arguments:
    $type

  Results:
   TRUE or FALSE

=cut
#**********************************************************
sub _add_header {
  my ($type) = @_;

  my %headers = (
    PAY_TYPE              => [
      'ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'REGION_ID'
    ],
    DOC_TYPE              => [
      'DOC_TYPE_ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'REGION_ID'
    ],
    GATEWAY               => [
      'GATE_ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'GATE_TYPE', 'ADDRESS_TYPE_ID',
      'ADDRESS_TYPE', 'ZIP', 'COUNTRY', 'REGION', 'ZONE', 'CITY', 'STREET', 'BUILDING', 'BUILD_SECT',
      'APARTMENT', 'UNSTRUCT_INFO', 'REGION_ID'
    ],
    IP_GATEWAY            => [
      'GATE_ID', 'IP_TYPE', 'IPV4', 'IPV6', 'IP_PORT', 'REGION_ID'
    ],
    'REGIONS'             => [
      'ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'MCC', 'MNC'
    ]
  );

  my $string = "";
  foreach (@{$headers{$type}}) {
    $string .= ($_ // "") . ';';
  }
  $string =~ s/;$/\n/;

  _save_report($type, $string);

  return 1;
}

#**********************************************************
=head2 send()

=cut
#**********************************************************
sub send {
  my $self = shift;

  my $archive = $self->{conf}->{SORM_ARCHIVE} || '0';
  my $archive_path = $self->{conf}->{SORM_ARCHIVE_PATH} || '';

  for my $report (values %reports) {
    if (-e $report) {
      main::_ftp_upload({
        DIR  => "/",
        FILE => $report
      });

#История выгрузок
	if ($archive == 1 && $archive_path ne '') {
           my $dir = strftime "$archive_path/arch-%Y-%m-%d", localtime(time());
           unless(mkdir($dir))
           {
                  if ($! != 17)
                  {
                          die("Can't create arch directory: ".$!);
                  }
                  system ("cp $report $dir");
           }

        }

      if ($debug < 3) {
        unlink $report;
      }
    }
  }

  return 1;
}


1;
