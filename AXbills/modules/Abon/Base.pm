package Abon::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my AXbills::HTML $html;
my $lang;
my Abon $Abon;

use AXbills::Base qw/days_in_month in_array date_diff/;

#**********************************************************
=head2 new($db, $admin, $CONF, $attr)

  Arguments:
    $db
    $admin
    $CONF
    $attr
      HTML
      LANG

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
  $CONF->{ABON_FEES_DSC} //= '%SERVICE_NAME%: %PERIOD% %TP_NAME% (%TP_ID%) %EXTRA%';

  require Abon;
  Abon->import();
  $Abon = Abon->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 abon_docs($attr) - get services for invoice

  Arguments:
    $attr
      FULL_INFO
      PAYMENT_TYPE
      FEES_INFO

=cut
#**********************************************************
sub abon_docs {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my @services = ();
  my $uid = $attr->{UID} || $form->{UID};

  my $list = $Abon->user_tariff_list($uid, {
    PAYMENT_TYPE     => $attr->{PAYMENT_TYPE},
    TP_REDUCTION_FEE => '_SHOW',
    COLS_NAME        => 1
  });

  my %info = ();
  foreach my $line (@{$list}) {
    %info = ();
    next if !$line->{date};

    $line->{price} = $line->{price} * ((100 - $line->{discount}) / 100) if $line->{discount} > 0;
    $line->{price} = $line->{price} * $line->{service_count} if $line->{service_count} > 1;

    $info{service_name} = "$lang->{ABON}: ($line->{id}) " . "$line->{tp_name}";
    $info{module_name} = $lang->{ABON};
    $info{tp_reduction_fee} = $line->{tp_reduction_fee};

    if ($line->{period} == 1) {
      $info{month} += $line->{price};
    }
    elsif ($line->{period} == 0) {
      $info{day} += $line->{price};
    }

    if ($attr->{FULL_INFO}) {
      push @services, { %info };
    }
    else {
      $line->{price} = $line->{price} * 30 if $line->{period} == 0;
      push @services, "$lang->{ABON}: ($line->{id}) " . "$line->{tp_name}" .
        "|$line->{comments} |$line->{price}|$line->{id}|$line->{tp_name}";
    }
  }

  return \%info if $attr->{FEES_INFO};

  return \@services;
}

#*******************************************************************
=head2 abon_quick_info($attr) - Abon user quick info

  Arguments:
    $attr
      UID

  Returns:

=cut
#*******************************************************************
sub abon_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $attr->{UID} || $form->{UID};

  if ($attr->{UID}) {
    my $list = $Abon->user_tariff_list($uid, { COLS_NAME => 1, ACTIVE_ONLY => 1 });
    my @result = ();
    foreach my $line (@{$list}) {
      push @result, {
        TP_NAME  => $line->{tp_name},
        COMMENTS => $line->{comments},
        PRICE    => $line->{price}
      };
    }
    return \@result;
  }
  elsif ($attr->{GET_PARAMS}) {
    my %result = (
      HEADER    => $lang->{ABON},
      QUICK_TPL => 'abon_qi_box',
      SLIDES    => [ { TP_NAME => $lang->{TARIF_PLAN} }, { SCOMMENTS => $lang->{COMMENTS} }, { PRICE => $lang->{PRICE} }, ]
    );

    return \%result;
  }

  if ($uid) {
    $Abon->user_tariff_summary({ UID => $uid });
    if ($Abon->{LOST_FEE}) {
      $Abon->{TOTAL_ACTIVE} = '!'.$Abon->{TOTAL_ACTIVE};
    }
  }

  return ($Abon->{TOTAL_ACTIVE}) ? $Abon->{TOTAL_ACTIVE} : '';
}

#**********************************************************
=head2 internet_payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO
      SUM

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub abon_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  require Abon::Services;
  Abon::Services->import();
  my $Services = Abon::Services->new($db, $admin, $CONF, { LANG => $lang });

  my $user = $attr->{USER_INFO};
  $attr->{DATE} = POSIX::strftime('%Y-%m-%d', localtime(time));
  $attr->{USER_INFO} = $user;
  $attr->{SERVICE_RECOVERY} = '>0';

  if ($Services->abon_service_activate($attr)) {
    if ($Services->{OPERATION_SUM}) {
      $html->message('info', $lang->{INFO}, ($Services->{OPERATION_DESCRIBE} || q{}) . " $lang->{SUM}: " . ($Services->{OPERATION_SUM} || 0));
    }
  }

  return $self;
}

#**********************************************************
=head2 abon_load_plugin($plugin_name, $attr) - Load plugin module

  Argumnets:
    $plugin_name  - service modules name
    $attr
       SERVICE_ID
       SOFT_EXCEPTION
       RETURN_ERROR

  Returns:
    Module object

=cut
#**********************************************************
sub abon_load_plugin {
  my $self = shift;
  my ($plugin_name, $attr) = @_;
  
  my $api;
  my $Service = $attr->{SERVICE} || {};
  my $main_module = $Service->{MODULE} || 'Abon';
  $plugin_name //= $Service->{PLUGIN};

  if ($attr->{SERVICE_INFO}) {
    my $service_info = $attr->{SERVICE_INFO};
    $Service = $service_info->($attr->{SERVICE_ID});
  }

  return $api if (!$plugin_name || $plugin_name !~ /^[\w.]+$/);

  $plugin_name = $main_module . '::Plugin::' . $plugin_name;

  eval " require $plugin_name; ";
  if (!$@) {
    $plugin_name->import();

    $Service->{DEBUG} = defined $attr->{DEBUG} ? $attr->{DEBUG} : $Service->{DEBUG};
    if ($plugin_name->can('new')) {
      $api = $plugin_name->new($Service->{db}, $Service->{admin}, $Service->{conf}, {
        %{$Service},
        HTML => $html,
        LANG => $lang
      });
    }
    else {
      if ($attr->{RETURN_ERROR}) {
        return {
          errno  => 9901,
          errstr => "Can't load '$plugin_name'. Purchase this module https://billing.axiostv.ru",
        };
      }
      else {
        $html->message('err', $lang->{ERROR}, "Can't load '$plugin_name'. Purchase this module https://billing.axiostv.ru");
        return $api;
      }
    }
  }
  else {
    if ($attr->{RETURN_ERROR}) {
      return {
        errno  => 9902,
        errstr => "Can't load '$plugin_name'. Purchase this module https://billing.axiostv.ru",
      };
    }
    else {
      print $@ if ($attr->{DEBUG});
      $html->message('err', $lang->{ERROR}, "Can't load '$plugin_name'. Purchase this module https://billing.axiostv.ru");
      if (!$attr->{SOFT_EXCEPTION}) {
        # die "Can't load '$plugin_name'. Purchase this module https://billing.axiostv.ru";
      }
    }
  }

  return $api;
}

#**********************************************************
=head2 abon_promotional_tp($attr)

  Arguments:
    $attr
      USER

=cut
#**********************************************************
sub abon_promotional_tp {
  my $self = shift;
  my ($attr) = @_;

  my $user_info = $attr->{USER};
  return if !$user_info || !$user_info->{UID} || $user_info->{DISABLE};

  my @PERIODS = ($lang->{DAY}, $lang->{MONTH}, $lang->{QUARTER}, $lang->{SIX_MONTH}, $lang->{YEAR});

  my $promotion_tps = $Abon->tariff_list_former({
    PROMOTIONAL     => '!',
    PRICE           => '_SHOW',
    TP_NAME         => '_SHOW',
    PERIOD          => '_SHOW',
    USER_PORTAL     => 2,
    MANUAL_ACTIVATE => 1,
    COLS_NAME       => 1
  });
  my $items = '';
  
  my $user_activated_tps = $Abon->user_tariff_list($user_info->{UID}, { ACTIVE_ONLY => 1, COLS_NAME => 1 });
  my @activated_tps = ();
  map push(@activated_tps, $_->{id}), @{$user_activated_tps};

  foreach my $tp (@{$promotion_tps}) {
    next if in_array($tp->{id}, \@activated_tps);

    my $price = $tp->{price} || 0;
    next if ($user_info->{DEPOSIT} + $user_info->{CREDIT} < $price * (100 - $user_info->{REDUCTION}) / 100);

    $items .= $html->tpl_show(::_include('abon_promotion_tp_carousel_item', 'Abon'), {
      TP_NAME => $tp->{tp_name},
      ACTIVE  => !$items ? 'active' : '',
      PRICE   => $price,
      PERIOD  => '/' . ($PERIODS[$tp->{period}] || $PERIODS[0]),
      HREF    => '?index=' . main::get_function_index('abon_client') . "&add=$tp->{id}",
    }, { OUTPUT2RETURN => 1 });
  }

  return if !$items;

  $html->message('callout', $html->tpl_show(main::_include('abon_promotion_tp_carousel', 'Abon'),
    { ITEMS => $items }, { OUTPUT2RETURN => 1 }), '', { class => 'info mb-0 p-0' });
}

1;
