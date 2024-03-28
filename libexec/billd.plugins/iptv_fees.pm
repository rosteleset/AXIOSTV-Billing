=head1 NAME

 billd plugin

 DESCRIBE:  Iptv fees

=head2 ARGUMENTS

 INNER_TP_ID - TP_ID in tarif_plans table
 TP_ID       - id in tarif_plans table
 FROM_DATE
 TO_DATE

=cut

use strict;
use warnings;
use Iptv;
use Tariffs;
use AXbills::Base qw(load_pmodule parse_arguments in_array _bp);
use Pod::Usage qw/&pod2usage/;
use Date::Simple;
use Date::Range;

our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
  $OS,
  $var_dir,
  %lang
);

our $Iptv = Iptv->new($db, $Admin, \%conf);
my $Tariffs = Tariffs->new($db, $Admin, \%conf);
require Iptv::Services;

$argv->{TO_DATE} ||= $DATE;

if (!$argv->{FROM_DATE}) {
  print "Enter value FROM_DATE!\n";
  exit;
}
elsif ($argv->{FROM_DATE} gt $argv->{TO_DATE}) {
  print "FROM_DATE cannot be more than TO_DATE \n";
  exit;
}
elsif ($argv->{TO_DATE} gt $DATE) {
  print "TO_DATE cannot be more than Current date ($DATE) \n";
  exit;
}

iptv_fees();

#**********************************************************
=head2 iptv_fees($attr)

=cut
#**********************************************************
sub iptv_fees {

  my $tariffs = $Tariffs->list({
    INNER_TP_ID  => $argv->{INNER_TP_ID} || '_SHOW',
    TP_ID        => $argv->{TP_ID} || '_SHOW',
    MODULE       => 'Iptv',
    MONTH_FEE    => '_SHOW',
    NAME         => '_SHOW',
    COLS_NAME    => 1,
    NEW_MODEL_TP => 1
  });

  my @need_dates;

  my $d1 = Date::Simple->new("$argv->{FROM_DATE}");
  my $d2 = Date::Simple->new("$argv->{TO_DATE}");

  my $range = Date::Range->new($d1, $d2);

  for my $date ($range->dates) {
    push @need_dates, $date->format("%Y-%m-%d");
  }

  foreach my $tariff (@{$tariffs}) {
    my %Dates_users;
    print "TP - $tariff->{tp_id}:$tariff->{name}...\n";
    my $users_ = $Iptv->users_fees({
      TP_ID     => $tariff->{tp_id},
      TP_NAME   => $tariff->{name},
      FROM_DATE => $argv->{FROM_DATE},
      TO_DATE   => $argv->{TO_DATE}
    });

    foreach my $user (@{$users_}) {

      my @Dates = split(',', $user->{Pays_dates});

      foreach my $need_date (@need_dates) {
        next if $user->{Registration} gt $need_date;

        if (!in_array($need_date, \@Dates)) {
          if (!$Dates_users{$need_date}) {
            $Dates_users{$need_date} = $user->{LOGIN};
          }
          else {
            $Dates_users{$need_date} .= "," . $user->{LOGIN};
          }
        }
      }
    }

    foreach my $date (sort keys %Dates_users) {
      print "$date - $Dates_users{$date}\n\n";
    }
  }
}

1;