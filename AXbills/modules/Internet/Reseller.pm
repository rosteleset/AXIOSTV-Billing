package Internet::Reseller;

=head1 NAME

  Iptv Reseller interface

=head1 VERSION

  VERSION: 1.02
  REVISION: 20180712
  
=cut

use strict;
use warnings FATAL => 'all';
use Internet;
use Tariffs;
use parent qw(Exporter);
use AXbills::Base qw/mk_unique_value _bp/;

use AXbills::Misc qw/_error_show/;
require AXbills::Result_former;

our $VERSION = 1.01;
our (%lang);

our @EXPORT = qw(
  internet_r_list
);

my $MODULE = 'Reseller';
my AXbills::HTML $html;
my $Internet;
my $Tariffs;
my $FORM;
my $users;
my $admin;
my %conf;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  $admin = $attr->{ADMIN};
  $admin->{MODULE} = $MODULE;
  %lang  = %{ $attr->{LANG} };
  $html  = $attr->{HTML};
  $users = $attr->{USERS};
  %conf  = %{ $attr->{CONF} };
  $FORM  = $html->{HTML_FORM};

  my $self = {
    db              => $attr->{DB},
    conf            => $attr->{CONF},
    admin           => $admin,
    users           => $users,
    SERVICE_NAME    => 'Internet_Reseller',
    VERSION         => $VERSION
  };

  bless($self, $class);

  
  $self->{debug}    = $attr->{DEBUG} || 0;
  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  return $self;
}

#**********************************************************
=head2 menu() - menu items

=cut
#**********************************************************
sub menu {
  my $self = shift;

  my %menu = (
    "11:0:Internet:internet_r_list:"              => 1,
    # "02:0:TV:internet_user:UID"                 => 0,
    # "03:2:TARIF_PLANS:internet_chg_tp:UID"      => 11,
    # "06:0:Internet:null:"                       => 5,
    # "07:6:TARIF_PLANS:internet_tp:"             => 5,
    # "08:7:ADD:iptv_tp:"                     => 5,
    # "09:7:INTERVALS:iptv_intervals:TP_ID"   => 5,
    # "11:7:SCREENS:iptv_screens:TP_ID"       => 5,
    # "10:7:GROUPS:form_tp_groups:"           => 5,
    # "10:7:NASS:iptv_nas:TP_ID"              => 5,
    # "20:0:TV:iptv_online:"                  => 6,
    # "30:0:TV:iptv_use:"                     => 4,
  );

  $self->{menu}=\%menu;

  return $self->{menu};
}

#**********************************************************
=head2 internet_r_list()

=cut
#**********************************************************
sub internet_r_list {
  my $self = shift;
  #my ($attr) = @_;

  if($FORM->{add_payment}) {
    $html->tpl_show('', { UID => $FORM->{add_payment}}, { TPL => 'internet_reseller_payment', MODULE => 'Internet' });
  }
  elsif($FORM->{make_payment}) {
    main::_make_payment($FORM->{UID}, $FORM->{SUM}, 'Internet');
  }

  my $list = $Internet->user_list({
    ID                 => '_SHOW',
    GID                => $users->{GID},
    UID                => '_SHOW',
    LOGIN              => '_SHOW',
    FIO                => '_SHOW',
    TP_NAME            => '_SHOW',
    DEPOSIT            => '_SHOW',
    INTERNET_STATUS_ID => '_SHOW',
    INTERNET_ACTIVATE  => '_SHOW',
    GROUP_BY           => 'internet.id',
    DOMAIN_ID          => $admin->{DOMAIN_ID},
    PG                 => $FORM->{pg},
    COLS_NAME          => 1,
  });

  my @service_status_colors = ("#000000", "#FF0000", '#808080', '#0000FF', '#FF8000', '#009999');
  my @service_status        = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{HOLD_UP},
    "$lang{DISABLE}: $lang{NON_PAYMENT}", $lang{ERR_SMALL_DEPOSIT},
    $lang{VIRUS_ALERT} );

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{USERS},
    title_plain => [ "UID", $lang{LOGIN}, $lang{FIO}, $lang{DEPOSIT}, $lang{TARIF_PLAN}, $lang{ACTIVATE}, $lang{EXPIRE}, $lang{STATUS}, ""],
    qs          => "",
    pages       => $Internet->{TOTAL},
    ID          => 'USERS',
    HAS_FUNCTION_FIELDS => 1,
  });

  foreach my $line (@$list) {
  	next if ($line->{uid} == $users->{UID});
    my $payment_button = $html->button($lang{PAYMENTS}, "index=$FORM->{index}&add_payment=$line->{uid}", { class => 'payments' });
    $table->addrow(
      $line->{uid},
      $line->{login},
      $line->{fio},
      ($line->{deposit} > 0 ? $line->{deposit} : $html->color_mark($line->{deposit}, '#FF0000')),
      $line->{tp_name},
      $line->{internet_activate},
      $line->{internet_activate} eq '0000-00-00' ? '0000-00-00' :_add_days($line->{internet_activate}, 31),
      $html->color_mark($service_status[$line->{internet_status_id}], $service_status_colors[$line->{internet_status_id}]),
      "$payment_button",
    );
  }

  print $table->show();

  $table = $html->table({
    width      => '100%',
    rows       => [ [ "$lang{TOTAL}:", $html->b( $Internet->{TOTAL} - 1 )  ] ],
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 _add_days($date, $days)

  return date

=cut
#**********************************************************
sub _add_days {
  my ($date, $days) = @_;
  
  use Time::Piece;
  my $d = Time::Piece->strptime($date, "%Y-%m-%d");
  my $sec = $days * 24 * 60 * 60;

  my Time::Piece $n = $d + $sec;

  return $n->ymd;
}

1
