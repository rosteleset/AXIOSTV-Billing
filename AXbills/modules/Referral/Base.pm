package Referral::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;
my $Referral;

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

  require Referral;
  Referral->import();
  $Referral = Referral->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 referral_quick_info()

=cut
#**********************************************************
sub referral_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $form->{UID};
  my $result = {};

  if ($attr->{GET_PARAMS}) {
    $result = {
      HEADER    => 'Refferral',
      QUICK_TPL => 'referral_qi_box',
      FIELDS    => {}
    };

    return $result;
  }

  $Referral->list({ REFERRAL => $uid });

  return $Referral->{TOTAL} || 0;
}

1;