#!/usr/bin/perl

=head1 NAME

 Install perl dependencies we need for normal ABillS work

=cut

use strict;
use warnings FATAL => 'all';

my $usage = "
Arguments:
  test        - Show list of installed and missing modules
  port        - Try to install missing modules using ports (FreeBSD only)
  pkg         - Try to install missing modules using pkg (FreeBSD only)
  apt-get     - Install using apt-get when possible (Debian / Ubuntu)
  rpm         - Install using rpm packages when possible ( RHEL, CentOS, Fedora )
";

my $action = q{};

if($ARGV[0]) {
  $action = $ARGV[0];
}
else {
  print $usage;
  exit 0;
}

my $batch = $ARGV[1] || 0;


my @modules = (
  #  {
  #    cpan => "Asterisk::AGI",
  #    port => "/usr/ports/net/asterisk/",
  #    pkg => "asterisk",
  #    apt => "asterisk",
  #    rpm => ""
  #  },
  {
    cpan => "Authen::Captcha",
    port => "/usr/ports/security/p5-Authen-Captcha",
    pkg => "p5-Authen-Captcha p5-String-Random",
    apt => "libauthen-captcha-perl",
    rpm => "perl-Authen-Captcha"
  },
  {
    cpan => "Crypt::DES",
    port => "/usr/ports/security/p5-Crypt-DES",
    pkg => "p5-Crypt-DES",
    apt => "libcrypt-des-perl",
    rpm => "perl-Crypt-DES"
  },
  {
    cpan => "Crypt::OpenSSL::X509",
    port => "/usr/ports/security/p5-Crypt-OpenSSL-X509",
    pkg => "p5-Crypt-OpenSSL-X509",
    apt => "libcrypt-openssl-x509-perl",
    rpm => "perl-Crypt-OpenSSL-X509"
  },
  {
    cpan => "DBD::mysql",
    port => "/usr/ports/databases/p5-DBD-mysql",
    pkg => "p5-DBD-mysql",
    apt => "libdbd-mysql-perl",
    rpm => "perl-DBD-MySQL"
  },
  {
    cpan => "DBI",
    port => "/usr/ports/databases/p5-DBI",
    pkg => "p5-DBI",
    apt => "libdbi-perl",
    rpm => "perl-DBI"
  },
  {
    cpan => "Devel::NYTProf",
    port => "/usr/ports/devel/p5-Devel-NYTProf",
    pkg => "p5-Devel-NYTProf",
    apt => "libdevel-nytprof-perl",
    rpm => "perl-Devel-NYTProf"
  },
  {
    cpan => "Digest::MD4",
    port => "/usr/ports/security/p5-Digest-MD4",
    pkg => "p5-Digest-MD4",
    apt => "libdigest-md4-perl",
    rpm => "perl-Digest-MD4"
  },
  {
    cpan => "Digest::MD5",
    port => "/usr/ports/security/p5-Digest-MD5",
    pkg => "p5-Digest-MD5",
    apt => "libdigest-md5-file-perl",
    rpm => "perl-Digest-MD5"
  },
  {
    cpan => "Digest::SHA",
    port => "/usr/ports/security/p5-Digest-SHA",
    pkg => "p5-Digest-SHA",
    apt => "libdigest-sha-perl",
    rpm => "perl-Digest-SHA"
  },
  {
    cpan => "Imager::QRCode",
    port => "/usr/ports/graphics/p5-Imager-QRCode",
    pkg => "p5-Imager-QRCode",
    apt => "libimager-qrcode-perl",
    rpm => ""
  },
  {
    cpan => "JSON",
    port => "/usr/ports/converters/p5-JSON",
    pkg => "p5-JSON",
    apt => "libjson-perl",
    rpm => "perl-JSON"
  },
  {
    cpan => "JSON::XS",
  },
  {
    cpan => "LWP::UserAgent",
    port => "/usr/ports/www/p5-LWP-UserAgent-WithCache",
    pkg => "p5-LWP-UserAgent-WithCache",
    apt => "liblwp-useragent-determined-perl",
    rpm => "perl-libwww-perl perl-Crypt-SSLeay"
  },
  {
    cpan => "URI",
    port => "/usr/ports/net/p5-URI",
    pkg => "p5-URI",
    apt => "liburi-perl",
    rpm => "perl-URI"
  },
  {
    cpan => "PDF::API2",
    port => "/usr/ports/textproc/p5-PDF-API2",
    pkg => "p5-PDF-API2",
    apt => "libpdf-api2-perl",
    rpm => "perl-PDF-API2"
  },
  {
    cpan => "Perl::GD",
    port => "/usr/ports/graphics/p5-GD/",
    pkg => "p5-GD",
    apt => "libgd-perl",
    rpm => "perl-GD",
    use => "GD"
  },
#  {
#    cpan => "RRD::Simple",
#    port => "/usr/ports/databases/p5-RRD-Simple",
#    pkg => "p5-RRD-Simple",
#    apt => "librrd-simple-perl",
#    rpm => "rrdtool-perl",
#    use => "RRD::Simple"   # FIXME in CentOS correct check is "use RRD", but FreeBSD works with "use RRD::Simple"
#    #FIXME RRD::Simple is not used anymore, replace with RRDTool::OO
#  },
  {
    cpan => "Spreadsheet::WriteExcel",
    port => "/usr/ports/textproc/p5-Spreadsheet-WriteExcel",
    pkg => "p5-Spreadsheet-WriteExcel",
    apt => "libspreadsheet-writeexcel-perl",
    rpm => "perl-Spreadsheet-WriteExcel"
  },
  {
    cpan => "Time::HiRes",
    port => "/usr/ports/devel/p5-Time-HiRes",
    pkg => "p5-Time-HiRes",
    apt => "libtime-hr-perl",
    rpm => "perl-Time-HiRes"
  },
  {
    cpan => "XML::Simple",
    port => "/usr/ports/textproc/p5-XML-Simple",
    pkg => "p5-XML-Simple",
    apt => "libxml-simple-perl",
    rpm => "perl-XML-Simple"
  },
  {
    cpan => "DateTime",
    port => "/usr/ports/devel/p5-DateTime",
    pkg => "p5-DateTime",
    apt => "libdatetime-perl",
    rpm => "perl-DateTime"
  },

  {
    cpan => "LWP::Protocol::https"
  },
  {
    cpan => "IO::Socket::SSL"
  },
  {
    cpan => 'Text::CSV'
  },
  {
    cpan => 'AnyEvent'
  },
  {
    cpan => 'AnyEvent::HTTP'
  },
  {
    cpan => 'Net::SSLeay'
  },
  {
    cpan => 'Time::Piece'
  }
);

# exit code;
my $error_code = 0;

my $manager = '';
my $program = '';
my $update;

if ($action eq 'dev') {
  # do what dev said to do;
  dev();
  exit($error_code);
}

if ($action eq 'test') {
  run_test();
  exit($error_code);
}
elsif ($action eq 'port') {
  $manager = 'port';
  $update = 'portsnap auto'
}
elsif ($action eq 'pkg') {
  $manager = 'pkg';
  $program = 'pkg install -y';
  $update = 'pkg update';
}
elsif ($action eq 'apt-get') {
  $manager = 'apt';
  $program = 'apt-get -y install ';
  $update = 'apt-get update';
}
elsif ($action eq 'rpm') {
  $manager = 'rpm';
  $program = 'yum -y install ';
  $update = 'yum -y update';
} else {
  die $usage;
};

if ($manager) {

  if ($> != 0) {
    die "You must be root to install required dependencies";
  }

  print "Testing modules \n";

  run_test();

  my $uninstalled_modules = get_uninstalled_modules();
  if (@$uninstalled_modules) {

    print "\n Now we'll try to install missing modules \n\n";
    sleep 1;

    print "\n But first need to update sources";

    if (!$batch){
      print "\n Would you like us to update it for you? (y/N)? ";
      my $ans = <STDIN>;
      chomp($ans);
      if ($ans =~ /y/i) {
        if (update_sources()) {
          print "\n Now we are ready to go \n\n";
        } else {
          print "\n It seems we do not have update options. We'll skip this step \n\n";
        }
      }
      sleep 1;
    }
    else {
      update_sources();
    }

    install_modules($uninstalled_modules);

    print "\n And now, let's look again\n\n";
    run_test();

  } else {
    print "\n Everything's OK \n\n";
  }
}

sub get_name {
  my ($module) = @_;
  if ($manager eq 'pkg') {
    return get_pkg_name($module->{cpan});
  }
  elsif ($manager eq 'apt') {
    return get_apt_name($module->{cpan});
  }
  elsif ($manager eq 'rpm') {
    return get_rpm_name($module->{cpan});
  }
  else {
    die "rich or get trying";
  }
}
=head2 get_apt_name

  Contains OS specific processing of Perl module name
  Apt:  the package name usually starts with lib and ends with -perl like: libsome-module-perl for Some::Module.
    For e.g. libarray-compare-perl, libarchive-zip-perl, libnet-pcap-perl or libnet-dns-perl.
=cut
sub get_apt_name {
  my ($cpan_name) = @_;

  $cpan_name = lc $cpan_name;
  $cpan_name =~ s/\:\:/\-/g;

  return "lib$cpan_name-perl";
}

#********************************************************
=head2 get_pkg_name

  Contains OS specific processing of Perl module name
    Every Perl port in FreeBSD is prefixed with p5-

=cut
#********************************************************
sub get_pkg_name {
  my ($cpan_name) = @_;

  $cpan_name =~ s/::/-/g;
  return "p5-$cpan_name";

}

#********************************************************
=head2 get_rpm_name

  Contains OS specific processing of Perl module name
    These are typically prefixed with perl-
    RedHat, Fedora, Centos RPMs
=cut
#********************************************************
sub get_rpm_name {
  my ($cpan_name) = @_;
  $cpan_name =~ s/::/-/g;
  return "perl-$cpan_name";
}

sub run_test {
  foreach my $module (@modules) {
    my $ok = test_module($module);

    my $str_ok;
    if ($ok) {
      $str_ok = '[ OK ]';
    } else {
      $str_ok = '[ FAIL ]';
      $error_code = 1;
    }

    my $len = 30 - length($module->{cpan});
    my $sep = '.' x $len;

    print $module->{cpan}."$sep";

    print "$str_ok\n";
  }
}

sub test_module {
  my ($module) = @_;

  my $module_to_use = $module->{use} || $module->{cpan};

  eval "use $module_to_use";

  if ($@) {
    return 0;
  }
  else {
    return 1;
  }

}

sub get_uninstalled_modules {
  my @uninstalled_modules = ();

  foreach my $module (@modules) {
    my $ok = test_module($module);
    if (!$ok) {
      push @uninstalled_modules, $module;
    }
  }

  return \@uninstalled_modules;
}

sub install_modules {

  my ($modules_to_install) = @_;

  if ($manager eq '') {
    print "   Error: Undefined source system manager";
    exit (1);
  } elsif ($manager eq 'port') {
    #build from sources
    foreach my $module (@$modules_to_install) {
      install_via_port($module->{port});
    }
  } else {
    #extract names
    if ($manager eq 'rpm') {
      my $epel_chk = `rpm -qs epel-release`;
      unless ($epel_chk =~ /^normal/) {
        print "\n\nWe need to install EPEL repository\n";
        sleep 2;
        my $command = "yum install epel-release";
        _cmd($command);
      }
    }

    my $names = '';
    foreach my $module (@$modules_to_install) {
      my $name = $module->{$manager} || get_name($module);
      $names .= " $name";
    }
    my $command = "$program " .  $names;
    _cmd($command);
  }
}

sub install_via_port {
  my ($port_path) = @_;

  my $command = "cd $port_path ; make && make install";

  _cmd($command);
}

#********************************************************
=head2 cmd - run system command

  Run system command

=cut
#********************************************************
sub _cmd {
  my $str = shift;
  if (system($str) != 0) {
    die "There was a problem running $str\n";
  }
}

sub update_sources {
  if ($update) {
    _cmd($update);
    return 1;
  }
  else {
    return 0;
  }
}

sub dev {
  $manager = 'rpm';
  $program = 'yum -y install ';
  $update = 'yum -y update';

  foreach my $module (@modules) {
    unless ($module->{rpm}) {
      my $name = $module->{cpan}; #get_name($module);
      #      my $command = "ssh 192.168.0.154 -t 'yum search $name | grep $name || true'";

      print "$name\n";

      #      cmd($command);
    }
  };

  return 1;
}

1
