package Extfin::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;
my $Extfin;

use AXbills::Base qw/days_in_month in_array/;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Extfin;
  Extfin->import();
  $Extfin = Extfin->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head extfin_quick_info($attr) - Quick information

  Arguments:
    $attr
      UID

  Return:

=cut
#**********************************************************
sub extfin_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $result;
  my $form = $attr->{FORM} || {};
  my $uid = $attr->{UID} || $form->{UID};
  
  if ($attr->{UID}) {
    my $list = $Extfin->paid_periodic_list({
      UID        =>  $uid,
      COLS_NAME  => 1,
      COLS_UPPER => 1
    });

    $result = $list->[0];
    my $service_status = ::sel_status({ HASH_RESULT => 1 });
    $result->{STATUS} = (defined($result->{STATUS})) ? $service_status->{ $result->{STATUS} } : '';
    ($result->{STATUS}, undef) = split(/:/, $result->{STATUS});
    return $result;
  }
  elsif($attr->{GET_PARAMS}) {
    $result = {
      HEADER => $lang->{ACCRUALS},
      FIELDS => { UID => 'UID' }
    };

    return $result;
  }

  $Extfin->paid_periodic_list({
    UID            => $uid,
    TOTAL_SERVICES => '_SHOW',
    COLS_NAME      => 1,
    COLS_UPPER     => 1
  });

  return ($Extfin->{TOTAL_SERVICES} && $Extfin->{TOTAL_SERVICES} > 0) ? $Extfin->{TOTAL_SERVICES} : '';
}

1;