=head1 NAME

  Test for checking of correct syntax of json for SNMP templates

=cut

use strict;
use warnings;
use JSON qw/decode_json/;

BEGIN {
  use FindBin '$Bin';
  unshift(@INC,
    $Bin . '/../',
    $Bin . "/../AXbills/mysql",
    $Bin . '/../AXbills/',
    $Bin . '/../lib/',
    $Bin . '/../AXbills/modules');
}

my $TEMPLATE_DIR = substr($Bin, 0, -1);

json_test();


#**********************************************************
=head2 json_test()


=cut
#**********************************************************
sub json_test {
  print "Start test JSON syntax...\n\n";

  my @snmp_tpl_dirs = (
    $TEMPLATE_DIR,
    $TEMPLATE_DIR . 'dlink/'
  );

  my @fnames = ();

  foreach my $dir (@snmp_tpl_dirs) {

    if (opendir(DIR, $dir)) {
      @fnames = grep(/\.snmp$/, readdir(DIR));
      closedir(DIR);

      foreach my $fname (@fnames) {
        my $file_content = '';

        if (open(my $fh, '<', $dir . $fname)) {
          while (<$fh>) {
            $file_content .= $_;
          }
          close($fh);
        }

        $file_content =~ s#//.*$##gm;
        eval {decode_json($file_content)};

        if ($@) {
          print "$fname incorrect syntax: $@";
        }
        else {
          print "$fname ..... OK\n";
        }
      }
    }
    else {
      print "Can't open dir $TEMPLATE_DIR\n";
    }
  }

  return 1;
}


1;
