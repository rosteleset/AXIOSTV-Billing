#!perl

=head1 import_userside

  Import userside plugins

  Arguments:
      USER_ID  - id of user if need
      REQUEST  - name of request
   conf Argumetns
      USER_SIDE_LINK   - Link to the userside
      USER_SIDE_APIKEY - Api key
      USER_SIDE_CAT    - Type of reqest
=cut

use AXbills::Base qw/cmd in_array convert startup_files _bp int2ip/;
use AXbills::Fetcher qw/web_request/;
use Users;
use AXbills::Misc qw/form_purchase_module _function get_function_index/;
use utf8;
use Log qw/log_print/;
use Maps;

our ($html, %lang, %conf, $index, $admin, $db, @CABLECAT_EXTRA_COLORS, %permissions, @MODULES);
our ($debug, $Admin, $argv);

require Cablecat;
Cablecat->import();

our Cablecat $Cablecat = Cablecat->new($db, $admin, \%conf);
our Maps $Maps = Maps->new($db, $admin, \%conf);
use Cablecat::Selects;
use Cablecat::Trace;
use Cablecat::Cable_blank;

require Equipment;
Equipment->import();
my $Equipment = Equipment->new($db, $admin, \%conf);

require Cablecat::Configure;
# require Cablecat::Layers;
require Cablecat::Commutation;

our %date_key_hash;
my %imported = (
  wells => {}
);

binmode STDOUT, ":utf8";

#import();

sub import {
  my $request_link = '';

  my $us_link      = $conf{USER_SIDE_LINK}   || 'http://demo.userside.eu';
  my $us_apikey    = $conf{USER_SIDE_APIKEY} || 'keyus';
  my $us_cat       = $conf{USER_SIDE_CAT}    || 'node';
  $argv->{REQUEST} = $argv->{REQUEST} || '';

  $request_link = "$us_link/api.php?key=$us_apikey&cat=$us_cat&action=get",

  print $request_link;

  my $nodes = web_request(
    $request_link,
    {
      JSON_RETURN => 1,
      JSON_UTF8   => 1,
      CURL        => 1,
    }
  );

  die "Couldn't get date info in Userside it!" unless defined $nodes;

  my %types = (
    1 => \&import_connectors,
    3 => \&import_wells
  );

  for my $node_id (keys %{ $nodes->{data} }) {
    my $node = $nodes->{data}->{$node_id};

    if(exists $types{$node->{type}}) {
      $types{$node->{type}}->($node);
    }
  }

  return 1;
}

sub import_connectors {
  my ($connector) = shift;
}

sub import_wells {
  my ($well) = shift;

  if($well->{parent_id} == 0) {
    $imported{wells}{$well->{id}} = create_well($well);
  }
  else {

  }
}

sub create_well {
  my ($well) = shift;
  my ($parr) = shift;

  my $point_id = '';

  if(ref $well->{coordinates} eq 'HASH') {
    $point_id = $Maps->points_add({
      COORDX   => $well->{coordinates}->{lat},
      COORDY   => $well->{coordinates}->{lon},
      NAME     => "Well $well->{name}",
      TYPE_ID  => 1,
      EXTERNAL => 1
    });
  }


  $Cablecat->wells_add({
    ADD_OBJECT => 1,
    NAME       => $well->{name},
    INSTALLED  => ($well->{date_add} =~ m/\d+-\d+-\d+/gm),
    TYPE_ID    => 1,
    add        => 1,
    POINT_ID   => $point_id,
    PARENT_ID  => undef
  });
}

1;