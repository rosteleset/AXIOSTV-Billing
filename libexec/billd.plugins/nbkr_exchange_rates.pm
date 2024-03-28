use strict;
use warnings FATAL => 'all';

our ($db, $Admin, %conf);

use AXbills::Fetcher;
use AXbills::Base qw/load_pmodule _bp/;
use Finance;
my $finance = Finance->new($db, $Admin, \%conf);

nbkr_add_exchange_rates();

#**********************************************************
=head2 nbkr_add_exchange_rates()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub nbkr_add_exchange_rates {
  # get xml data about exchange ratas
  my $nbkr_xml_data = web_request(
    "http://www.nbkr.kg/XML/daily.xml",
    {
      CURL => 1,
    }
  );

  load_pmodule('XML::Simple');

  # decode XML into hash
  my $nbkr_data = eval {XML::Simple::XMLin("$nbkr_xml_data", forcearray => 1)};

  if ($@) {
    return 0;
  }

  # get list already added exchanges
  $finance->exchange_list({ LIST2HASH => "money, id" });
  my $exist_exchange_rate_list = $finance->{list_hash};

  # foreach for adding all exchange rates from NBKR
  foreach my $currency (@ {$nbkr_data->{Currency} }) {
    $currency->{Value}->[0] =~ s/\,/\./;
    # if already add - just change old data
    if (exists $exist_exchange_rate_list->{$currency->{ISOCode}}) {

      $finance->exchange_change($exist_exchange_rate_list->{$currency->{ISOCode}}, {
          ER_NAME       => $currency->{ISOCode},
          ER_SHORT_NAME => $currency->{ISOCode},
          ISO           => '',
          ER_RATE       => (1 / $currency->{Value}->[0]),
        });

      if ($finance->{errno}) {
        print "Cant change $currency->{ISOCode}\n";
      }
    }
    # if not added - add new exchange
    else {
      $finance->exchange_add({
        ER_NAME       => $currency->{ISOCode},
        ER_SHORT_NAME => $currency->{ISOCode},
        ISO           => '',
        ER_RATE       => (1 / $currency->{Value}->[0])
      });

      if ($finance->{errno}) {
        print "Cant add $currency->{ISOCode}\n";
      }
    }

  }
}

1;