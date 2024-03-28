#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use JSON;

my %systems = (
  46 => {
    logname           => 'Upays\/46',
    transaction_field => 'note'
  },
);
my $hash = {};
my %payments = ();
my $is_reading_payment = 0;

my $argv = parse_arguments(\@ARGV);
parse_requests();

#**********************************************************
=head2 parse_requests(\@ARGV) - Parse comand line arguments

  Arguments:

    @ARGV   - Command line arguments

  Returns:

    return HASH_REF of values

=cut
#**********************************************************
sub parse_requests {

  print "Supported PAYSYS_IDs: \n";
  print Dumper \%systems;

  if (!$argv->{SYSTEM_ID}) {
    print 'No param SYSTEM_ID';
    return 0;
  }
  elsif (!exists $systems{$argv->{SYSTEM_ID}}) {
    print 'Add support for this SYSTEM_ID';
    return 0;
  }

  my $log_file_name = $argv->{FILE_NAME} || "/usr/axbills/var/log/paysys_check.log";

  open(my $fh, '<', $log_file_name) or die "Can't open file $log_file_name";
  while (<$fh>) {
    if ($is_reading_payment) {
      next if ($_ && ($_ =~ /Request/g || $_ =~ /=======/g));
      if ($_ && $_ =~ /\S+, \S+/g) {
        $_ =~ s/[\n\r]//;
        my @vals = split ',\s?', $_;
        $hash->{$vals[0]} = $vals[1];
      }
      elsif ($_ && $_ =~ /\S+ => \S+/g) {
        $_ =~ s/[\n\r]//;
        my @vals = split ' => ', $_;
        $hash->{$vals[0]} = $vals[1];
      }
      else {
        $is_reading_payment = 0;
        if (!$payments{$hash->{$systems{$argv->{SYSTEM_ID}}->{transaction_field}}}) {
          $payments{$hash->{$systems{$argv->{SYSTEM_ID}}->{transaction_field}}} = $hash;
        }
        $hash = {};
      }
    }

    if ($_ && $_ =~ /$systems{$argv->{SYSTEM_ID}}->{logname}/g) {
      $is_reading_payment = 1;
    }
  }

  close($fh);

  print Dumper \%payments;

  print "\n\nResult in file transactions_$argv->{SYSTEM_ID}.json\n\n";

  # Write results to file.
  open(my $json_out, ">", "transactions_$argv->{SYSTEM_ID}.json") or die "transactions_$argv->{SYSTEM_ID}.json";
  print {$json_out} encode_json(\%payments);
  close($json_out);

  return 1;
}

#**********************************************************
=head2 parse_arguments(\@ARGV) - Parse comand line arguments

  Arguments:

    @ARGV   - Command line arguments

  Returns:

    return HASH_REF of values

=cut
#**********************************************************
sub parse_arguments {
  my ($argv_) = @_;

  my %args = ();

  foreach my $line (@$argv_) {
    if ($line =~ /=/) {
      my ($k, $v) = split(/=/, $line, 2);
      $args{"$k"} = (defined($v)) ? $v : '';
    }
    else {
      $args{"$line"} = 1;
    }
  }

  return \%args;
}

1;
