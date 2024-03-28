package Iptv::Reseller;

=head1 NAME

  Iptv Reseller interface

=head1 VERSION

  VERSION: 1.01
  REVISION: 20180103

=cut

use strict;
use warnings FATAL => 'all';
use Iptv;
use JSON;
use Tariffs;
use parent qw(Exporter);
use AXbills::Base qw/mk_unique_value _bp/;
require AXbills::Result_former;

our $VERSION = 1.01;
our (%lang);

our @EXPORT = qw(
  iptv_reseller_users_list
  diller_info
);

my $MODULE = 'Reseller';
my AXbills::HTML $html;
our $Iptv;
my $Tariffs;
my $FORM;
my Users $users;
my $admin;
my %conf;
my $Diller;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  $admin  = $attr->{ADMIN};
  $admin->{MODULE} = $MODULE;
  %lang   = %{$attr->{LANG}};
  $html   = $attr->{HTML};
  $users  = $attr->{USERS};
  %conf   = %{$attr->{CONF}};
  $FORM   = $html->{HTML_FORM};
  $Diller->{GID} = $users->{GID};
  $Diller->{UID} = $users->{UID};

  my $self = {
    db           => $attr->{DB},
    conf         => $attr->{CONF},
    admin        => $admin,
    users        => $users,
    SERVICE_NAME => 'Iptv_Reseller',
    VERSION      => $VERSION
  };

  bless($self, $class);

  $self->{debug} = $attr->{DEBUG} || 0;
  $Iptv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});
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
    "01:0:TV:iptv_reseller_users_list:" => 1,
    # "02:0:TV:iptv_user:UID"                 => 0,
    # "03:2:TARIF_PLANS:iptv_chg_tp:UID"      => 11,
    # "06:0:TV:null:"                         => 5,
    # "07:6:TARIF_PLANS:iptv_tp:"             => 5,
    # "08:7:ADD:iptv_tp:"                     => 5,
    # "09:7:INTERVALS:iptv_intervals:TP_ID"   => 5,
    # "11:7:SCREENS:iptv_screens:TP_ID"       => 5,
    # "10:7:GROUPS:form_tp_groups:"           => 5,
    # "10:7:NASS:iptv_nas:TP_ID"              => 5,
    # "20:0:TV:iptv_online:"                  => 6,
    # "30:0:TV:iptv_use:"                     => 4,
  );

  $self->{menu} = \%menu;

  return $self->{menu};
}

#**********************************************************
=head2 iptv_reseller_users_list()

=cut
#**********************************************************
sub iptv_reseller_users_list {
  my $self = shift;
  #my ($attr) = @_;

  if ($FORM->{add}) {
    iptv_reseller_user_add();
  }
  elsif ($FORM->{chg}) {
    my $list = $Iptv->user_list({
      ID        => $FORM->{chg},
      GID       => $Diller->{GID},
      DOMAIN_ID => $admin->{DOMAIN_ID},
      UID       => '_SHOW',
      TP_ID     => '_SHOW',
      COLS_NAME => 1,
    });

    if ($Iptv->{TOTAL} < 1) {
      $html->message('err', "$lang{ERROR}", "Wrong user.");
      return 1;
    }

    $Iptv->{TP_ID} = $list->[0]->{tp_id};
    $Iptv->{UID} = $list->[0]->{uid};
    $Iptv->{TP_ADD} = _tp_sel();
    $Iptv->{ACTION} = 'change';
    $Iptv->{LNG_ACTION} = $lang{ADD};
    $html->tpl_show('', $Iptv, { TPL => 'iptv_reseller_change_tp', MODULE => 'Iptv' });
  }
  elsif ($FORM->{add_payment}) {
    $html->tpl_show('', { UID => $FORM->{add_payment} }, { TPL => 'iptv_reseller_payment', MODULE => 'Iptv' });
  }
  elsif ($FORM->{make_payment}) {
    main::_make_payment($FORM->{UID}, $FORM->{SUM});
  }
  elsif ($FORM->{add_user}) {
    $Iptv->{TP_ADD} = _tp_sel();
    $Iptv->{ACTION} = 'add';
    $Iptv->{LNG_ACTION} = $lang{ADD};
    # $Iptv->{STATUS_SEL} = main::sel_status({ STATUS => $Iptv->{STATUS} });
    $Iptv->{RND_PSWD} = mk_unique_value(8, { SYMBOLS => '1234567890' });
    $html->tpl_show('', $Iptv, { TPL => 'iptv_reseller_user', MODULE => 'Iptv' });
  }
  elsif ($FORM->{change}) {
    require AXbills::Misc;
    require Iptv::Users;
    require Iptv::Services;

    my $tv_service_id = iptv_user_add({
      %$FORM,
      UID         => $FORM->{UID},
      SERVICE_ADD => 1,
      USER_INFO   => $users,
      ACTIVATE    => $FORM->{IPTV_ACTIVATE},
      EXPIRE      => $FORM->{IPTV_EXPIRE},
    });

    if($tv_service_id) {
      $html->message('info', $lang{CHANGED}, "# $tv_service_id");
    }
  }

  my $list = $Iptv->user_list({
    ID             => '_SHOW',
    UID            => '_SHOW',
    LOGIN          => '_SHOW',
    FIO            => '_SHOW',
    GID            => $Diller->{GID},
    TP_NAME        => '_SHOW',
    DEPOSIT        => '_SHOW',
    SERVICE_STATUS => '_SHOW',
    IPTV_EXPIRE    => '_SHOW',
    DOMAIN_ID      => $admin->{DOMAIN_ID},
    PAGE_ROWS      => 99999,
    COLS_NAME      => 1,
  });

  my $table = $html->table({
    width               => '100%',
    caption             => $lang{USERS},
    title_plain         => [ $lang{LOGIN}, $lang{FIO}, $lang{DEPOSIT}, $lang{TARIF_PLAN}, $lang{STATE}, $lang{EXPIRE}, "" ],
    ID                  => 'USERS',
    MENU                => "$lang{ADD}:index=$FORM->{index}&add_user=1:btn bg-olive margin;",
    DATA_TABLE          => 1,
  });

  foreach my $line (@$list) {
    my $payment_button = $html->button($lang{PAYMENTS}, "index=$FORM->{index}&add_payment=$line->{uid}", { class => 'payments' });
    my $edit_button    = $html->button($lang{EDIT}, "index=$FORM->{index}&chg=$line->{id}", { class => 'change' });
    $table->addrow(
      $line->{login},
      $line->{fio},
      $line->{deposit},
      $line->{tp_name},
      $line->{service_status} ? $lang{DISABLED} : $lang{ENABLE},
      $line->{iptv_expire},
      "$edit_button $payment_button",
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 iptv_reseller_user_add()

=cut
#**********************************************************
sub iptv_reseller_user_add {

  $users->add({
    CREATE_BILL => 1,
    GID         => $Diller->{GID},
    %$FORM,
  });
  ::_error_show($users);

  my $uid = $users->{INSERT_ID};
  $users->pi_add({ %$FORM, UID => $uid });
  ::_error_show($users);

  return 0 if ($users->{errno});

  if (!$FORM->{STATUS}) {
    require AXbills::Misc;
    require Iptv::Users;
    require Iptv::Services;

    my $tv_service_id = iptv_user_add({
      %$FORM,
      UID         => $uid,
      SERVICE_ADD => 1,
      USER_INFO   => $users,
      ACTIVATE    => $FORM->{IPTV_ACTIVATE},
      EXPIRE      => $FORM->{IPTV_EXPIRE},
    });

    if($tv_service_id) {
      $html->message('info', $lang{ADDED}, "# $tv_service_id");
    }
  }

  return 1;
}

#**********************************************************
=head2 iptv_reseller_change_tp() - Change user tarif plan

=cut
#**********************************************************
sub iptv_reseller_change_tp {
  


  return 1;
}

#**********************************************************
=head2 _tp_sel()

=cut
#**********************************************************
sub _tp_sel {
  return $html->form_select(
    'TP_ID',
    {
      SELECTED  => $Iptv->{TP_ID},
      SEL_LIST  => $Tariffs->list({
        MODULE       => 'Iptv',
        NEW_MODEL_TP => 1,
        COLS_NAME    => 1,
      }),
      SEL_KEY   => 'tp_id',
      SEL_VALUE => 'id,name',
    }
  );
}

1