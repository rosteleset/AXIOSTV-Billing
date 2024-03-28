#!/usr/bin/perl 
=head1 NAME


 ABillS Resellers Web interface

=cut

use strict;
use warnings;

our (
  %LANG,
  $CHARSET, @MODULES,
  $base_dir,
  $user,
  $admin,

  @ones,
  @twos,
  @fifth,
  @one,
  @onest,
  @ten,
  @tens,
  @hundred,
  @money_unit_names,

  %permissions,
  %conf,
  %lang,
  %menu_args
);


BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "AXbills/$sql_type/",
    $libpath . "AXbills/modules/",
    $libpath . '/lib/',
    $libpath . '/AXbills/',
    $libpath
  );

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use AXbills::Defs;
use AXbills::Misc;
use AXbills::Base qw(gen_time in_array mk_unique_value load_pmodule sendmail _bp);
use Users;
use Finance;
use Admins;
use Conf;

require Dillers;

do "../libexec/config.pl";
require AXbills::Templates;

our $html = AXbills::HTML->new({
  IMG_PATH => 'img/',
  NO_PRINT => 1,
  CONF     => \%conf,
  CHARSET  => $conf{default_charset},
  METATAGS => templates('metatags'),
  LANG     => \%lang,
  ADMIN    => $admin
});

our $db = AXbills::SQL->connect(
  $conf{dbtype},
  $conf{dbhost},
  $conf{dbname},
  $conf{dbuser},
  $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef }
);

if($html->{language} ne 'english') {
  do $libpath . "/language/english.pl";
}

if(-f $libpath . "/language/$html->{language}.pl") {
  do $libpath."/language/$html->{language}.pl";
}

our $sid = $FORM{sid} || $COOKIES{sid} || '';
#Cookie section ============================================
$html->set_cookies('OP_SID', $FORM{OP_SID}, '', '', { SKIP_SAVE => 1 });
$html->set_cookies('sid', $FORM{sid}, "Fri, 1-Jan-2038 00:00:01") if (defined($FORM{sid}));
#===========================================================

my %OUTPUT = ();
$conf{AUTH_METHOD}=1;
$admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} });

my $users = Users->new($db, $admin, \%conf);
my $Diller = Dillers->new($db, $admin, \%conf);
our $Conf = Conf->new($db, $admin, \%conf);
require Control::Auth;
require AXbills::Misc;

my $uid = 0;

($uid, $sid) = diller_auth($FORM{user}, $FORM{passwd}, $sid,
  {
    USER                => $users
  });

if( ! $uid ) {
  form_login({ TPL => 'multidoms_reseller_login', MODULE => 'Multidoms' });
  $OUTPUT{BODY} = $html->{OUTPUT};
}
else {
  fl();
  $html->{METATAGS} = templates('metatags_client');
  $OUTPUT{SKIN} = 'skin-purple';

  $OUTPUT{MENU} = $html->menu2(
    \%menu_items,
    \%menu_args,
    undef,
    {
      EX_ARGS         => "&sid=$sid",
      ALL_PERMISSIONS => 1,
      FUNCTION_LIST   => \%functions,
      SKIP_HREF       => 1
    }
  );

  if($index) {
    _function($index);
  }
  else {
    diller_dashboard();
  }

  $OUTPUT{BODY} = $html->{OUTPUT};
  $OUTPUT{BODY} = $html->tpl_show(_include( 'multidoms_reseller_main', 'Multidoms' ), \%OUTPUT, {
    ID                 => 'multidoms_reseller_main',
    SKIP_DEBUG_MARKERS => 1,
  });
}

print $html->header();
print $html->tpl_show(_include( 'multidoms_reseller_start', 'Multidoms' ), \%OUTPUT, { MAIN => 1, SKIP_DEBUG_MARKERS => 1  });
$html->fetch();
$html->test() if ($conf{debugmods} =~ /LOG_DEBUG/);


#**********************************************************
=head2 fl() -  Static menu former

=cut
#**********************************************************
sub fl {

  my @m = (
    "1:0:$lang{USERS}:null:::",
    # "11:1:$lang{LOGINS}:_form_users:::",
    "4:0:$lang{REPORTS}:null:::",
    "41:4:$lang{PAYMENTS}:_form_payments:::",
    "42:4:$lang{FEES}:_form_fees:::",
    # "5:0:$lang{SETTINGS}:null:::",
    # "50:0:$lang{PROFILE}:null:::",
    # "51:50:$lang{PASSWD}:null:::",
    "1000:0:$lang{LOGOUT}:logout:::"
  );

  my @extra_menu = ();

  # if ( $conf{user_finance_menu} ){
  #   #push @m, ":0:$lang{FINANCES}:form_finance:::";
  #   push @m, "41:4:$lang{PAYMENTS}:_form_payments:::";
  #   push @m, "42:4:$lang{FEES}:_form_fees:::";
  # }

  if($conf{RESELER_SERVICES}) {
    my @services = split(/,\s?/, $conf{RESELER_SERVICES});
    foreach my $service (@services) {
      next if $service !~ /^[\w.]+$/;
      eval { require $service . '/' . 'Reseller.pm'; };

      if(! $@) {
        my $mod = $service . "::Reseller";
        $mod->import();
        my $Service = $mod->new({
          DB    => $db,
          ADMIN => $admin,
          USERS => $users,
          CONF  => \%conf,
          HTML  => $html,
          LANG  => \%lang
        });

        push @extra_menu, { $service => $Service->menu() };
      }
      else {
        print "Content-Type: text/html\n\n";
        print "Can't load:  $service ";
        print $@;
      }
    }
  }

  mk_menu( \@m, { CUSTOM => 1, EXTRA_MENU => \@extra_menu } );
  return 1;
}

#*******************************************************************
=head2 diller_auth($login, $password, $session_id)

=cut
#*******************************************************************
sub diller_auth {
  my ($login, $password, $session_id) = @_;

  ($uid, $session_id) = auth_user($login, $password, $session_id,
    {
      USER => $users
  });

  if($uid) {
    $Diller->diller_info({ UID => $user->{UID} });
    return 0, 0 if ($Diller->{TOTAL} < 1);
    $Diller->diller_permissions_list();

    if($user->{DOMAIN_ID}) {
      $admin->info(0, { DOMAIN_ID => $user->{DOMAIN_ID} });
    }
  }

  return $uid, $session_id;
}


#*******************************************************************
=head2 diller_dushboard()

=cut
#*******************************************************************
sub diller_dashboard {

  $html->tpl_show(_include( 'multidoms_reseller_info', 'Multidoms' ), $users);

  return 1;
}

#*******************************************************************
=head2 _make_payment($UID, $sum) - 

=cut
#*******************************************************************
sub _make_payment {
  my ($uid, $sum, $module) = @_;

  my $user_ = Users->new($db, $admin, \%conf);
  $user_->info($uid);
  $users->info($Diller->{UID});

  if ($uid == $Diller->{UID}) {
    $html->message('err', "$lang{ERROR}", "Wrong user.");
    return 0;
  }
  
  if ($module && $module eq 'Internet' && $user_->{GID} != $users->{GID}) {
    $html->message('err', "$lang{ERROR}", "Wrong group.");
    return 0;
  }

  my $Fees  = Finance->fees($db, $admin, \%conf);
  my $Payments = Finance->payments($db, $admin, \%conf);
  my $dillers_fee = $sum;
  if ($Diller->{DILLER_PERCENTAGE}) {
    $dillers_fee = $sum * (100 - $Diller->{DILLER_PERCENTAGE}) / 100;
  }

  if ($dillers_fee > ($users->{DEPOSIT} + $users->{CREDIT})) {
    $html->message('err', "$lang{ERROR}", "Insufficient funds.");
    return 0;
  }

  $Fees->take($users, $dillers_fee, {
    DESCRIBE => "Transfer '$sum' -> '$user_->{LOGIN}'",
  });
  return 0 if (_error_show($Fees));
  
  $Payments->add($user_, { 
    SUM      => $sum,
    METHOD    => 7,
    DESCRIBE => "Diller '$users->{LOGIN}' add payment sum:'$sum' for user:'$user_->{LOGIN}' $DATE $TIME",
  });
  $html->message('info', "$lang{INFO}", $lang{TRANSFER} . " '" . $html->b($sum) . "'' -> '" . $html->b($user_->{LOGIN}) . "'");
  
  if (!$Payments->{errno}) {
    cross_modules_call('_payments_maked', {
      USER_INFO   => $user_,
      SUM         => $sum,
      SILENT      => 1,
      QUITE       => 1,
      timeout     => 4,
    });
  }
  else {
    $html->message('err', "$lang{ERROR}");
  }

  return 1;
}

#**********************************************************
=head2 _form_fees()

=cut
#**********************************************************
sub _form_fees {

  # return 1 unless ($admin->{DOMAIN_ID});

  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $FEES_METHODS = get_fees_types();

  my $Fees  = Finance->fees($db, $admin, \%conf);
  my $list  = $Fees->list({
    %LIST_PARAMS,
    UID       => $users->{UID},
    LOGIN     => '_SHOW',
    DSC       => '_SHOW',
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    DEPOSIT   => '_SHOW',
    METHOD    => '_SHOW',
    LAST_DEPOSIT => '_SHOW',
    DOMAIN_ID => $admin->{DOMAIN_ID},
    COLS_NAME => 1
  });

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{FEES},
    title_plain => [ $lang{DATE}, $lang{DESCRIBE}, $lang{SUM}, $lang{TYPE} ],
    qs          => $pages_qs,
    pages       => $Fees->{TOTAL},
    ID          => 'FEES'
  });

  foreach my $line (@$list) {
    $table->addrow(
      $line->{datetime},
      $line->{dsc},
      $line->{sum},
      $FEES_METHODS->{ $line->{method} || 0 }
    );
  }

  print $table->show();

  $table = $html->table({
    width      => '100%',
    rows       => [ [ "$lang{TOTAL}:", $html->b( $Fees->{TOTAL} ), "$lang{SUM}:", $html->b( $Fees->{SUM} ) ] ],
    rowcolor   => $_COLORS[2]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 _form_payments()

=cut
#**********************************************************
sub _form_payments {

  # return 1 unless ($admin->{DOMAIN_ID});

  my $Payments = Finance->payments($db, $admin, \%conf);

  if (!$FORM{sort}) {
    $LIST_PARAMS{sort} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $list  = $Payments->list({
    %LIST_PARAMS,
    UID       => $users->{UID},
    LOGIN     => '_SHOW',
    DATETIME  => '_SHOW',
    DOMAIN_ID => $admin->{DOMAIN_ID},
    COLS_NAME => 1
  });

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{PAYMENTS},
    title_plain => [ $lang{DATE}, $lang{DESCRIBE}, $lang{SUM} ],
    qs          => $pages_qs,
    pages       => $Payments->{TOTAL},
    ID          => 'PAYMENTS'
  });

  foreach my $line (@$list) {
    $table->addrow(
      $line->{datetime},
      $line->{dsc},
      $line->{sum},
    );
  }

  print $table->show();

  $table = $html->table({
    width      => '100%',
    rows       => [ [ "$lang{TOTAL}:", $html->b( $Payments->{TOTAL} ), "$lang{SUM}:", $html->b( $Payments->{SUM} ) ] ],
  });

  print $table->show();

  return 1;
}


1
