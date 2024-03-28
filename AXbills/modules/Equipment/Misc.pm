package Equipment::Misc;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Equipment::Misc

=head2 SYNOPSIS

  Equipment miscellaneous functions

=cut

use Exporter;
use base 'Exporter';

our @EXPORT = qw/equipment_get_telnet_tpl/;
our @EXPORT_OK = @EXPORT;

#**********************************************************
=head2 equipment_get_telnet_tpl($attr) - read telnet template from file and substitute params

  Arguments:
    $attr
      TEMPLATE - telnet template filename
      DEBUG - debug level
      ... - any params, which will be used for substitution in template

  Returns:
    \@reg_tpl - array of strings, template with substituted params

=cut
#**********************************************************
sub equipment_get_telnet_tpl {
  my ($attr) = @_;

  my $template = $attr->{TEMPLATE};
  my $debug    = $attr->{DEBUG} || 0;

  my @reg_tpl;

  my $base_dir = $main::base_dir || '/usr/axbills/';

  my $template_path = $base_dir . 'AXbills/modules/Equipment/snmp_tpl/' . $template;
  if (-f $template_path) {
    if ($debug > 3) {
      print "Tpl: $template_path\n";
    }

    my $content = '';
    open(my $fh, '<', $template_path) || return [];

    while(<$fh>) {
      my $line = $_;
      if ($line && $line !~ /#/) {
        while($line =~ /\%([A-Z0-9\_]+)\%/ig) {
          my $param = $1;
          if(defined($attr->{$param})) {
            print "$param -> $attr->{$param}\n" if($debug > 4);
            $line =~ s/\%$param\%/$attr->{$param}/g;
          }
          else {
            if($debug < 6) {
              $line =~ s/\%$param\%//g;
            }
            print "NO input params '$param'\n";
          }
        }

        $content .= $line;
      }
    }

    close($fh);
    print $content if($debug > 3);

    @reg_tpl = split(/\n/, $content);
  }

  return \@reg_tpl;
}

1;
