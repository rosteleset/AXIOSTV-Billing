#!/usr/bin/perl

=head1 NAME

  billing.axiostv.ru

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  our $libpath = '../../';
  eval { do "$libpath/libexec/config.pl" };
  our %conf;

  if (!%conf) {
    print "Content-Type: text/plain\n\n";
    print "Error: Can't load config file 'config.pl'\n";
    print "Create ABillS config file /usr/axbills/libexec/config.pl\n";
    exit;
  }

  my $sql_type = $conf{dbtype} || 'mysql';
  unshift(@INC,
    $libpath . 'AXbills/modules/',
    $libpath . "AXbills/$sql_type/",
    $libpath . '/lib/',
    $libpath . 'AXbills/',
    $libpath
  );

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

our (
  $base_dir,
  %err_strs,
  %LANG,
  %lang,
  @MONTHES,
  @WEEKDAYS,
  %permissions,
  @state_colors,
  %functions,
  $ui
);


use AXbills::Defs;
use AXbills::Base qw(in_array mk_unique_value decode_base64 convert gen_time);
use Admins;
use Users;
use Finance;

our $db    = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { %conf,
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    db_engine => 'dbcore'
  });

our $admin = Admins->new($db, \%conf);
our $Conf  = Conf->new($db, $admin, \%conf, { SKIP_PAYSYS => 1 });

require AXbills::Misc;
require AXbills::Result_former;

$conf{base_dir}=$base_dir if (! $conf{base_dir});

our $html = AXbills::HTML->new({
  CONF       => \%conf,
  NO_PRINT   => 0,
  PATH       => $conf{WEB_IMG_SCRIPT_PATH} || '../',
  CHARSET    => $conf{default_charset},
  LANG       => \%lang,
  HTML_SECURE=> 'SameSite=Lax'
});

require AXbills::Templates;
require Control::Auth;

if(! auth_admin() ) {
  if($ENV{DEBUG}) {
    die;
  }
  exit;
}
$html->{admin} = $admin;

our @default_search  = ( 'UID', 'LOGIN', 'FIO', 'CONTRACT_ID',
  'EMAIL', 'PHONE', 'COMMENTS', 'ADDRESS_FULL', 'CITY', 'TELEGRAM', 'VIBER' );

if($admin->{SID}) {
  $html->set_cookies('admin_sid', $admin->{SID}, '', '');
  # if ($conf{API_ENABLE}) {
    $html->set_cookies('admin_sid', $admin->{SID}, 900, '/api.cgi');
  # }
}
#Operation system ID
if ($FORM{OP_SID}) {
  $html->set_cookies('OP_SID', $FORM{OP_SID}, '', '', { SKIP_SAVE => 1 });
}

if ($index == 2) {
  if ($FORM{hold_date}) {
    $html->set_cookies('hold_date', $FORM{DATE}, "Fri, 1-Jan-2038 00:00:01", '');
  }
  elsif ($FORM{OP_SID}) {
    $html->set_cookies('hold_date', '', "Fri, 1-Jan-2038 00:00:01", '');
  }

  if ($FORM{OP_SID}) {
    $html->set_cookies('INNER_DESCRIBE', $FORM{INNER_DESCRIBE}, "Fri, 1-Jan-2038 00:00:01", '');
    delete $COOKIES{INNER_DESCRIBE} if (!$FORM{INNER_DESCRIBE});
  }

  if (!$FORM{INNER_DESCRIBE} && $COOKIES{INNER_DESCRIBE} && $conf{PAYMENTS_INNER_DESCRIBE_AUTOCOMPLETE}) {
    $FORM{INNER_DESCRIBE} = $COOKIES{INNER_DESCRIBE};
  }
}

if (defined($FORM{DOMAIN_ID})){
  $html->set_cookies('DOMAIN_ID', "$FORM{DOMAIN_ID}", "Fri, 1-Jan-2038 00:00:01", $html->{web_path});
}

#===========================================================
set_admin_params();

#Global Vars
our @bool_vals  = ($lang{NO}, $lang{YES});
our @status     = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE});
our %uf_menus   = ();  #User form menu list
our %menu_args  = ();
our %module     = ();

fl();

our $users  = Users->new($db, $admin, \%conf);
# Quick index - Show only function results whithout main windows
if ($FORM{qindex} || $FORM{get_index}) {
  quick_functions();
}

if ($FORM{POPUP} && $FORM{POPUP} == 1) {
  print "Content-type: text/html\n\n";
  get_popup_info();
  exit;
}

FULL_MODE:
#Make active lang list
if ($conf{LANGS}) {
  $conf{LANGS} =~ s/\n//g;
  my (@lang_arr) = split(/;/, $conf{LANGS});
  %LANG = ();
  foreach my $l (@lang_arr) {
    my ($lang, $lang_name) = split(/:/, $l);
    $lang =~ s/^\s+//;
    $LANG{$lang} = $lang_name;
  }
}

if ($conf{CALLCENTER_MENU}) {
  $html->{CALLCENTER_MENU} = $html->tpl_show(templates('form_callcenter_menu'),
    { CALLCENTER_MENU => '' }, { OUTPUT2RETURN => 1 });
}

$html->{METATAGS} = templates('metatags');
if ($permissions{0} && (($FORM{UID} && $FORM{UID} =~ /^(\d+)$/
   && $FORM{UID} > 0)
   || ($FORM{LOGIN} && $FORM{LOGIN} !~ /\*/
     && !$FORM{add} && !$FORM{next} ))
   ) {

  if (! $FORM{type} || $FORM{type} ne 10){
    if ( $FORM{PRE} || $FORM{NEXT} ){
      my $list = $users->list( {
        UID       => (($FORM{PRE}) ? '<' : '>') . $FORM{UID},
        PAGE_ROWS => 1,
        COLS_NAME => 1,
        SORT      => 'u.uid',
        DESC      => ($FORM{PRE}) ? 'DESC' : '',
      } );
      $FORM{UID} = $list->[0]->{uid};
    }

    $ui = user_info( $FORM{UID}, { %FORM,
      LOGIN => (! $FORM{UID} && $FORM{LOGIN}) ? $FORM{LOGIN} : undef,
      QUITE => 1
    } );

    if ( $ui ){
      $html->{WEB_TITLE} = ($conf{WEB_TITLE} || '') .'['. ( $ui->{LOGIN} || q{deleted} ) .']';
    }
  }
}

print $html->header();

my ($menu_text, $navigat_menu) = mk_navigator();

$html->{LANG} = { GO2PAGE => $lang{GO2PAGE} };

my %SEARCH_TYPES = (
  10 => $lang{UNIVERSAL},
  11 => $lang{USERS},
  2  => $lang{PAYMENTS},
  3  => $lang{FEES},
  13 => $lang{COMPANY},
  999=> "GLOBAL $lang{SEARCH}"
);

my $function_name = $functions{$index} || q{};
pre_page();

admin_quick_setting();

main_function($function_name);

post_page();

#**********************************************************
=head2 form_admin_qm() - Admin's quick menu

=cut
#**********************************************************
sub form_admin_qm {
  return 1 if !$admin->{SETTINGS};

  $admin->{SETTINGS}{qm} //= '';
  my @a = split(/,/, $admin->{SETTINGS}->{qm});
  my $i = 0;
  $admin->{QUICK_MENU} = "<ul class='nav nav-pills nav-sidebar flex-column' id='admin-quick-menu'>";
  $admin->{QUICK_MENU} .= $html->element('h5', $lang{QUICK_MENU});
  my $quick_menu_script = "<script>";
  my $qm_btns_counter = 0;

  my %rev_functions = reverse %functions;

  foreach my $line ( @a ) {
    my ($qm_id_name, $qm_name) = split(/:/, $line, 2);
    next if($qm_id_name eq 'null');
    my $qm_id = $rev_functions{$qm_id_name};

    if(! $qm_id) {
      next;
    }

    $qm_id =~ s/sub//;
    my $active = '';

    if ($qm_id eq $index) {
      $active = 'active';
      $admin->{RIGHT_MENU_OPEN} = !$admin->{SETTINGS}{RIGHT_MENU_HIDDEN} ? 'control-sidebar-slide-open' : '';
    }

    if ( !$qm_name ) {
      next if (!$menu_names{$qm_id});
      $qm_name = $menu_names{$qm_id};
    }

    my $button = '';
    if ( defined($menu_args{$qm_id}) && $menu_args{$qm_id} !~ /=/ ) { #XXX broken when there's comma (',') in $menu_args{$qm_id} or arg name is not 'LOGIN'
      $button = "<a class='$active' onclick='openModal($qm_btns_counter, \"ArrayBased\")' ><i class='nav-icon fas fa-search'></i>$qm_name</a>";
      $quick_menu_script .= "modalsSearchArray.push(['$lang{LOGIN}','LOGIN',$qm_id,'$SELF_URL']);\n";
      $qm_btns_counter++;
    }
    else {
      my $args = ($menu_args{$qm_id} && $menu_args{$qm_id} =~ /=/) ? '&' . $menu_args{$qm_id} : '';
      $button = $html->button( $html->element( 'i', '', { class => 'nav-icon far fa-circle' } ) . $qm_name, "index=$qm_id$args",
        { class => $active } );
    }
    $i++;
    $admin->{QUICK_MENU} .= $html->li( $button, { class => "nav-item $active" } );
  }

  if ($admin->{SETTINGS}{ql}) {
    foreach my $ql (split(/,/, $admin->{SETTINGS}->{ql})) {
      my ($ql_name, $ql_url) = split(/\|/, $ql, 2);
      my $custom_button = $html->button( $html->element( 'i', '', { class => 'nav-icon fas fa-external-link-alt' } )
        . $ql_name, "", { GLOBAL_URL => $ql_url, ex_params => ' target=_blank' } );
      $admin->{QUICK_MENU} .= $html->li( $custom_button, { class => 'nav-item' });
    }
  }

  $admin->{QUICK_MENU} .= $html->li( $html->button( $lang{ADD}, "index=110",
      { class => "btn bg-green btn-block btn-flat mt-2" } ) );

  $admin->{QUICK_MENU} .= $quick_menu_script . "</script>";

  if ($qm_btns_counter){
    $admin->{QUICK_MENU} .= '<script src="/styles/default/js/dynamicForms.js"></script>';
  }
  $admin->{QUICK_MENU} .= '</ul>';

  return 1;
}

#**********************************************************
=head2 form_start($attr) - Start page

  Arguments:
    $attr
       SUB_MENU

  Return:
   TRUE or FALSE

=cut
#**********************************************************
sub form_start {
  my ($attr) = @_;

  $admin->{quick_report_menu}=1;
  return 0 if ($FORM{'xml'} && $FORM{'xml'} == 1);
  my $quick_reports = '';
  my @qr_arr = ();
  if ($attr->{SUB_MENU}) {
    foreach my $mod_name (@MODULES) {
      load_module($mod_name, $html);
      my $check_function = lc($mod_name) . $attr->{SUB_MENU};
      if ( defined(&$check_function) ) {
        push @qr_arr, "$mod_name:$check_function";
      }
    }
    $quick_reports = join(', ', @qr_arr);
  }

  my %start_page = ();
  if (! $quick_reports && $admin->{SETTINGS}) {
    $quick_reports = $admin->{SETTINGS}{QUICK_REPORTS};
    @qr_arr = split(/, /, $quick_reports) if ($quick_reports);
  }

  if ($#qr_arr > -1) {
    if (in_array('Rwizard', \@MODULES)) {
      require Reports;
      Reports->import();
      my $Reports = Reports->new($db, $admin, \%conf);
      my $quick_rwizard_reports = $Reports->list({
        QUICK_REPORT => 1,
        COLS_NAME    => 1,
        AID          => $admin->{AID},
      });

      if ($Reports->{TOTAL} > 0){
        foreach (@$quick_rwizard_reports) {
          push @qr_arr, "Rwizard:quick_report:$_->{id}";
        }
      }
    }

    require Control::Quick_reports;
  }

  my %start_panels = ();

  my %loaded_modules = ();

  for(my $i=0; $i<=$#qr_arr; $i++) {
    my $fn;
    my $arg;
    if ($qr_arr[$i]=~/:/) {
      my ($mod_name, $function, $argument) = split(/:/, $qr_arr[$i]);
      next if (!in_array($mod_name, \@MODULES));
      unless (exists $loaded_modules{$mod_name}) {
        load_module($mod_name, { %$html });
      }

      if (!$@) {
        $fn = $function;
        $arg = $argument || '';
        $loaded_modules{$mod_name} = 1;
      }
      else {
        next;
      }
    }
    else {
      $fn = 'start_page_'.$qr_arr[$i];
    }

    next unless defined &$fn;

    $start_panels{"$qr_arr[$i]"} .= $html->element('div', (&{ \&{$fn} }($arg)),
        { class => 'col-lg-4 col-md-6 start-panel', id => "$qr_arr[$i]" });
  }

  my $sort_quick_reports = $admin->{SETTINGS}{QUICK_REPORTS_SORT};

  if($sort_quick_reports){
    my @sort_qr_arr = split(/, /, $sort_quick_reports);

    foreach  my $sort_panel (@sort_qr_arr){
      if($start_panels{$sort_panel}){
          $start_page{INFO} .=  $start_panels{"$sort_panel"};
          delete $start_panels{"$sort_panel"};
      }
    }

  foreach my $sort_panel (sort keys %start_panels) {
      $start_page{INFO} .= $start_panels{"$sort_panel"};
    }
  }
  else{
    foreach my $panel_name (sort keys %start_panels) {
      $start_page{INFO} .=  $start_panels{$panel_name};
      delete $start_panels{"$panel_name"};
    }
  }

  delete $admin->{quick_report_menu};

  if ($conf{CUSTOM_START_PAGE} && $conf{CUSTOM_START_PAGE} ne '1')  {
    $html->tpl_show(templates($conf{CUSTOM_START_PAGE}), \%start_page);
  }
  else {
    $html->tpl_show(templates('form_start_page'), \%start_page);
  }

  return 1;
}
# TODO: need to rewrite func_menu to normal html -> table_header
#**********************************************************
=head2 func_menu($header, $items, $f_args) - Functions menu

  Arguments:
    $header  - hash_ref
    $items   - hash_ref or arr_ref
    $f_args  -
    SILENT   -

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub func_menu {
  my ($header, $items, $f_args) = @_;

  my $elements     = '';
  my $buttons_list = '';

  if (!$FORM{pdf} && !$FORM{json}) {
    foreach my $k (sort keys %{$header}) {
      my $v = $header->{$k};
      $buttons_list .= "$v\n";
    }

    if (ref $items eq 'ARRAY') {
      foreach my $line (@$items) {
        my ($name, $subf, $ext_url, undef, $main_fn_index) = split(/:/, $line, 5);
        my $active = ($FORM{subf} && $FORM{subf} eq $subf) ? 'active' : '';
        $elements .= $html->li($html->button($name, "index=" . ($f_args->{MAIN_INDEX} ? $f_args->{MAIN_INDEX} :
          ($main_fn_index ? $main_fn_index : $index))
          . ($ext_url ? '&' . $ext_url : q{})
          . ($subf ? "&subf=$subf" : q{}), { class => "nav-link $active" }),
          { class => 'nav-item' });
      }
    }
  }

  $buttons_list = $html->element('ul', $elements, { class => 'nav-tabs navbar-nav' }) . $buttons_list;
  $buttons_list = $html->element('div', $buttons_list, { class => 'collapse navbar-collapse', id => 'AXbillsNavbar' });

  my $expand_button = $html->element('button', $html->element('span', '', { class => 'navbar-toggler-icon' }), {
    class           => 'navbar-toggler',
    type            => 'button',
    'aria-controls' => 'AXbillsNavbar',
    'aria-label'    => 'Toggle',
    'data-target'   => '#AXbillsNavbar',
    'aria-expanded' => 'false',
    'data-toggle'   => 'collapse'
  });

  $buttons_list = $html->element('span', $lang{MENU}, { class => 'navbar-brand d-lg-none pl-3' }) .
    $expand_button . $buttons_list;

  my $menu = $html->element('div', $buttons_list, { class => 'axbills-navbar navbar navbar-expand-lg navbar-light mb-2' });

  print $menu if (!$f_args->{SILENT} && !$FORM{EXPORT_CONTENT});

  if ($FORM{subf}) {
    if($index eq $FORM{subf}) {
      return 0;
    }

    if (defined($module{$FORM{subf}})) {
      load_module($module{$FORM{subf}}, $html);
    }

    _function($FORM{subf}, $f_args->{f_args});
  }

  return 1;
}

#**********************************************************
=head2 form_image_mng($attr)

=cut
#**********************************************************
sub form_image_mng {
  my ($attr) = @_;

  if ($FORM{IMAGE}) {
    my $file_content;

    if(ref $FORM{IMAGE} eq 'HASH' && $FORM{IMAGE}{Contents}) {
      $file_content = $FORM{IMAGE};
    }
    elsif($FORM{IMAGE} eq 'URL') {
      require AXbills::Fetcher;
      AXbills::Fetcher->import('web_request');
      $file_content->{Contents} = web_request($FORM{URL});
      $file_content->{Size} = length($file_content->{Contents});
      $file_content->{'Content-Type'} = 'image/jpeg';
    }
    else {
      my $content = decode_base64($FORM{IMAGE});
      $file_content->{Contents}       = $content;
      $file_content->{Size}           = length($content);
      $file_content->{'Content-Type'} = 'image/jpeg';
    }

    if($attr->{TO_RETURN}) {
      return $file_content;
    }

    upload_file($file_content, { PREFIX    => 'if_image',
                                 FILE_NAME => "$FORM{UID}.jpg",
                                 #EXTENSIONS=> 'jpg,gif,png'
                                 REWRITE   => 1
                               });
  }
  elsif($FORM{show}) {
    print "Content-Type: image/jpeg\n\n";

    print file_op({ FILENAME => "$conf{TPL_DIR}/if_image/$FORM{UID}.jpg",
                    PATH     => "$conf{TPL_DIR}/if_image"
                  });
    return 1;
  }
  elsif($FORM{photo_del}) {
    if (unlink("$conf{TPL_DIR}/if_image/$FORM{UID}.jpg") == 1) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED}");
    }
    else {
      $html->message('err', $lang{DELETED}, "$lang{ERROR}");
    }
  }

  my @header_arr = (
    "$lang{MAIN}:index=$index&PHOTO=$FORM{PHOTO}&UID=$FORM{UID}",
      "Webcam:index=$index&PHOTO=$FORM{PHOTO}&UID=$FORM{UID}&webcam=1",
      "Upload:index=$index&PHOTO=$FORM{PHOTO}&UID=$FORM{UID}&upload=1"
  );

  my $user_pi = $users->pi();
  if ($user_pi->{_FACEBOOK} && $user_pi->{_FACEBOOK} =~ /[0-9]/) {
    push (@header_arr, "Facebook:index=$index&PHOTO=$FORM{PHOTO}&UID=$FORM{UID}&facebook=1");
  }

  if ($user_pi->{_VK} && $user_pi->{_VK} =~ /[0-9]/) {
    push (@header_arr, "Vk:index=$index&PHOTO=$FORM{PHOTO}&UID=$FORM{UID}&vk=1");
  }

  print $html->table_header(\@header_arr, { TABS => 1 });

  $FORM{EXTERNAL_ID}=$attr->{EXTERNAL_ID};

  if($FORM{webcam}) {
    $html->tpl_show(templates('form_image_webcam'), { %FORM, %$attr },
       { ID => 'form_image_webcam' });
  }
  elsif($FORM{upload}) {
    $html->tpl_show(templates('form_image_upload'), { %FORM, %$attr },
       { ID => 'form_image_upload' });
  }
  elsif($FORM{facebook}) {
    my $Auth = AXbills::Auth::Core->new({
      CONF      => \%conf,
      AUTH_TYPE => ucfirst('Facebook')
    });
    my ($fb_id) = $user_pi->{_FACEBOOK} =~ /(\d+)/;
    my $result = $Auth->get_fb_photo({
      USER_ID => $fb_id,
      SIZE    => 200,
    });
    unless(ref $result eq 'HASH' && $result->{data}->{url}){return 1;}

    print $html->form_main({
      HIDDEN  => {
        index => $index,
        UID   => $FORM{UID},
        PHOTO => $FORM{UID},
        IMAGE => 'URL',
        URL   => $result->{data}->{url},
      },
      SUBMIT  => { add => "$lang{ADD}" },
       CONTENT => "<img src='$result->{data}->{url}'><br><br>",
    });
  }
  elsif($FORM{vk}) {
    my $Auth = AXbills::Auth::Core->new({
      CONF      => \%conf,
      AUTH_TYPE => ucfirst('Vk')
    });
    my ($vk_id) = $user_pi->{_VK} =~ /(\d+)/;
    my $result = $Auth->get_info({
      CLIENT_ID => $vk_id,
    });
    unless(ref $result && ref $result->{result} eq 'HASH' && $result->{result}->{photo_big}){return 1;}
    print $html->form_main({
      HIDDEN  => {
        index => $index,
        UID   => $FORM{UID},
        PHOTO => $FORM{UID},
        IMAGE => 'URL',
        URL   => $result->{result}->{photo_big},
      },
      SUBMIT  => { add => "$lang{ADD}" },
      CONTENT => "<img src='$result->{result}->{photo_big}'><br><br>",
    });
  }
  else {
    if(-f "$conf{TPL_DIR}/if_image/$FORM{UID}.jpg") {
      print $html->img("$SELF_URL?qindex=$index&PHOTO=1&UID=$FORM{UID}&show=1");

      my $del_button = $html->button($lang{DEL}, "index=$index&PHOTO=1&UID=$FORM{UID}&photo_del=$FORM{UID}.jpg", {
          MESSAGE => "$lang{DEL}",
          class => 'del'
        });

      print $html->element('div',
        $html->element('div',
          $del_button,
          { class => 'float-left' }
        ),
        { class => 'row' }
      );
    }
  }

  return 1;
}

#**********************************************************
=head2 form_nas_allow() - Aloow NAS servers

=cut
#**********************************************************
sub form_nas_allow{
  my ($attr) = @_;

  my @allow     = ();
  my %allow_nas = ();

  if ( $FORM{ids} ){
    @allow = split( /, /, $FORM{ids} );
  }

  my %EX_HIDDEN_PARAMS = (
    subf  => $FORM{subf},
    index => $index
  );

  if ($attr->{USER_INFO}) {
    my Users $user = $attr->{USER_INFO};
    if ($FORM{change} && $permissions{0} && $permissions{0}{4}) {
      $user->nas_add(\@allow);
      if (!$user->{errno}) {
        $html->message( 'info', $lang{INFO}, "$lang{ALLOW} $lang{NAS}: ". ($FORM{ids} || '') );
      }
    }
    elsif ($FORM{default} && $permissions{0} && $permissions{0}{4}) {
      $user->nas_del();
      if (!$user->{errno}) {
        $html->message( 'info', $lang{NAS}, $lang{CHANGED} );
      }
    }

    _error_show($user);

    my $list = $user->nas_list();
    foreach my $line (@$list) {
      $allow_nas{ $line->[0] } = 'test';
    }

    $EX_HIDDEN_PARAMS{UID} = $user->{UID};
  }
  elsif ($attr->{TP}) {
    my $tarif_plan = $attr->{TP};

    if ($FORM{change}) {
      $tarif_plan->nas_add(\@allow);
      if (! _error_show($tarif_plan)) {
        $html->message( 'info', $lang{INFO}, "$lang{ALLOW} $lang{NAS}: ". ($FORM{ids} || q{}) );
      }
    }

    if( $tarif_plan->can('nas_list')) {
      my $list = $tarif_plan->nas_list();
      foreach my $nas_id (@$list) {
        $allow_nas{ $nas_id->[0] } = 1;
      }
    }

    $EX_HIDDEN_PARAMS{TP_ID} = $tarif_plan->{TP_ID} || 0;
  }
  elsif (defined($FORM{TP_ID})) {
    $FORM{chg}  = $FORM{TP_ID};
    $FORM{subf} = $index;
    if(in_array('Internet', \@MODULES)) {
      internet_tp();
    }

    return 0;
  }

  require Nas;
  Nas->import();
  my $Nas = Nas->new($db, \%conf, $admin);
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{NAS},
      title      => [ $lang{ALLOW}, $lang{NAME}, 'NAS-Identifier', 'IP', $lang{TYPE} ],
      qs         => $pages_qs,
      ID         => 'NAS_ALLOW'
    }
  );

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
  }

  my $list = $Nas->list({
    %LIST_PARAMS,
    PAGE_ROWS => 100000,
    GID       => undef,
    COLS_NAME => 1
  });

  foreach my $line (@$list) {
    $table->addrow(
      ($line->{nas_id} || '')
      . $html->form_input('ids', $line->{nas_id},
        {
          TYPE          => 'checkbox',
          OUTPUT2RETURN => 1,
          STATE         => (defined($allow_nas{ $line->{nas_id} }) || $allow_nas{all}) ? 1 : undef
        }
      ),
      $line->{nas_name},
      $line->{nas_identifier},
      $line->{nas_ip},
      $line->{nas_type}
    );
  }

  print $html->form_main(
    {
      CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {%EX_HIDDEN_PARAMS},
      SUBMIT  => {
        change  => $lang{CHANGE},
        default => $lang{DEFAULT}
      }
    }
  );

  return 1;
}

#**********************************************************
=head2 form_bills($attr) - Bill account managment

  Arguments:
    $attr
      USER_INFO
      EXT_BILL_ONLY

  Returns:
    True or False

=cut
#**********************************************************
sub form_bills {
  my ($attr) = @_;

  my $user = $attr->{USER_INFO};
  my %BILLS_HASH = ();

  if ( ! $user && ! $FORM{COMPANY_ID}) {
    $html->message('err', $lang{ERROR}, 'No user information');
    return 1;
  }

  if ($FORM{UID} && $FORM{change}) {
    form_users({ USER_INFO => $user });
    return 0;
  }

  if (!$attr->{EXT_BILL_ONLY}) {
    require Bills;
    Bills->import();

    my $Bills = Bills->new($db, $admin, \%conf);
    my $list  = $Bills->list(
      {
        COMPANY_ONLY => 1,
        UID          => ($user) ? $user->{UID} : undef,
        COLS_NAME    => 1
      }
    );

    foreach my $line (@$list) {
      if ($line->{company_name}) {
        $BILLS_HASH{ $line->{id} } = "$line->{id} : $line->{company_name} : ". sprintf('%.2f', $line->{deposit} || 0);
      }
      elsif ($line->{login}) {
        $BILLS_HASH{ $line->{id} } = ">> $line->{id} : Personal : ". sprintf('%.2f', $line->{deposit} || 0);
      }
    }

    $user->{SEL_BILLS} .= $html->form_select(
      'BILL_ID',
      {
        SELECTED => '',
        SEL_HASH => { '' => '', %BILLS_HASH },
        NO_ID    => 1
      }
    );

    $user->{CREATE_BILL}      = ' checked' if (!$FORM{COMPANY_ID} && $user->{BILL_ID} && $user->{BILL_ID} < 1);
    $user->{BILL_TYPE}        = $lang{PRIMARY};
    $user->{CREATE_BILL_TYPE} = 'CREATE_BILL';
    $html->tpl_show(templates('form_chg_bill'), $user);
  }

  if ($conf{EXT_BILL_ACCOUNT} || $attr->{EXT_BILL_ONLY}) {
    $html->tpl_show(
      templates('form_chg_bill'),
      {
        BILL_ID          => $user->{EXT_BILL_ID},
        BILL_TYPE        => $lang{EXTRA},
        CREATE_BILL_TYPE => 'CREATE_EXT_BILL',
        LOGIN            => $user->{LOGIN},
        CREATE_BILL      => (!$FORM{COMPANY_ID} && ! $user->{EXT_BILL_ID}) ? ' checked' : '',
        SEL_BILLS        => $user->{SEL_BILLS},
        UID              => $user->{UID},
        SEL_BILLS        => $html->form_select(
          'EXT_BILL_ID',
          {
            SELECTED => '',
            SEL_HASH => { '' => '', %BILLS_HASH },
            NO_ID    => 1
          }
        )
      }
    );
  }

  return 1;
}

#**********************************************************
=head2 form_changes($attr) - Changes list

  Arguments:
    $attr
      ADMIN
      SEARCH_PARAMS
      PAGES_QS

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub form_changes {
  my ($attr) = @_;

  my %search_params = ();

  my %action_types = (
    0  => 'Unknown',
    1  => $lang{ADDED},
    2  => $lang{CHANGED},
    3  => "$lang{CHANGED} $lang{TARIF_PLAN}",
    4  => $lang{STATUS},
    5  => "$lang{CHANGED} $lang{CREDIT}",
    6  => $lang{INFO},
    7  => $lang{REGISTRATION},
    8  => $lang{ENABLE},
    9  => $lang{DISABLE},
    10 => $lang{DELETED},
    11 => '-',
    12 => "$lang{DELETED} $lang{USER}",
    13 => "Online $lang{DELETED}",
    14 => $lang{HOLD_UP},
    15 => $lang{HANGUP},
    16 => "$lang{PAYMENTS} $lang{DELETED}",
    17 => "$lang{FEES} $lang{DELETED}",
    18 => "$lang{INVOICE} $lang{DELETED}",
    26 => "$lang{CHANGE} $lang{GROUP}",
    27 => "$lang{SHEDULE} $lang{ADDED}",
    28 => "$lang{SHEDULE} $lang{DELETED}",
    29 => "$lang{SHEDULE} $lang{EXECUTED}",
    31 => "$lang{ICARDS} $lang{USED}",
    32 => "$lang{CHANGED} $lang{REDUCTION}",
    40 => "$lang{BILL} $lang{CHANGED}",
    43 => "$lang{SHEDULE} $lang{TARIF_PLAN}",
    43 => "$lang{SHEDULE} $lang{STATUS}",
    50 => "Send registration pin",
  );

  my $pages_qs2 = q{};
  if ($permissions{4}{3} && $FORM{del} && $FORM{COMMENTS}) {
    $admin->action_del($FORM{del});
    if (! _error_show($admin)) {
      $html->message( 'info', $lang{DELETED}, "$lang{DELETED} [$FORM{del}]" );
    }
  }
  elsif (!$FORM{search_form} && $FORM{AID} && !defined($LIST_PARAMS{AID})) {
    $index = 50;
    $FORM{subf} = 145;

    $pages_qs2 .= "&AID=$FORM{AID}";
    require Control::Admins_mng;
    form_admins();

    return 0;
  }
  elsif($FORM{subf} && (!$pages_qs || $pages_qs !~ /subf/)) {
    $index = $FORM{subf};
    $pages_qs2 = "&subf=$FORM{subf}";
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  %search_params = %FORM;

  my %hidden_fileds = ();
  if($LIST_PARAMS{UID}) {
    $hidden_fileds{UID}=$LIST_PARAMS{UID};

    $pages_qs2 .= "&UID=$LIST_PARAMS{UID}" if($pages_qs !~ /UID/);
  }

  $search_params{MODULES_SEL} = $html->form_select('MODULE', {
    SELECTED      => $FORM{MODULE},
    SEL_ARRAY     => [ '', @MODULES ],
    OUTPUT2RETURN => 1
  });

  $search_params{TYPE_SEL} = $html->form_select('TYPE', {
    SELECTED      => $FORM{TYPE},
    SEL_HASH      => { '' => $lang{ALL}, %action_types },
    SORT_KEY      => 1,
    OUTPUT2RETURN => 1
  });

  $search_params{ADMIN_SEL}=sel_admins();
  # $search_params{ADMIN} = $html->form_select(
  #   'AID',
  #   {
  #     SELECTED    => $FORM{AID} ? $FORM{AID} : '',
  #     SEL_LIST    => $admin->list({
  #       PAGE_ROWS => 999999,
  #       COLS_NAME => 1
  #     }),
  #     NO_ID       => 1,
  #     SEL_OPTIONS => { '' => 1 },
  #     SEL_KEY     => 'aid',
  #     SEL_VALUE   => 'login',
  #     OUTPUT2RETURN => 1
  #   }
  # );

  form_search({
    HIDDEN_FIELDS => \%hidden_fileds,
    SEARCH_FORM   => $html->tpl_show(templates('form_history_search'), \%search_params, { OUTPUT2RETURN => 1 }),
    SHOW_PERIOD   => 1
  });

  $pages_qs2 .= $pages_qs;

  if($attr->{SEARCH_PARAMS}) {
    %LIST_PARAMS = %{ $attr->{SEARCH_PARAMS} };
  }
  elsif(!$FORM{UID} && !$FORM{search_form}) {
    require Control::Reports;
    form_changes_summary();
  }

  my $service_status = sel_status({ HASH_RESULT => 1 });
  if (! exists($INC{"Control/Services.pm"})) {
    require Control::Services;
  }
  my $tps_hash = sel_tp({ MODULE => 'Internet;Iptv;Cams;Ureports;Voip;Dv' });

  $pages_qs .= $pages_qs2;
  # if($FORM{FROM_DATE}) {
  #   $pages_qs2 .= "&FROM_DATE=" . $FORM{FROM_DATE};
  #   $LIST_PARAMS{FROM_DATE}=$FORM{FROM_DATE};
  # }
  #
  # if($FORM{TO_DATE}) {
  #   $pages_qs2 .= "&TO_DATE=" . $FORM{TO_DATE};
  #   $LIST_PARAMS{TO_DATE}=$FORM{TO_DATE};
  # }

  my $list = $admin->action_list({
    LOGIN       => '_SHOW',
    DATETIME    => '_SHOW',
    ACTIONS     => '_SHOW',
    ADMIN_LOGIN => '_SHOW',
    IP          => '_SHOW',
    MODULE      => '_SHOW',
    TYPE        => '_SHOW',
    %LIST_PARAMS,
    ADMIN_DISABLE => '_SHOW',
    COLS_NAME     => 1
  });

  if ($attr->{PAGES_QS}) {
    $pages_qs2 .= $attr->{PAGES_QS};
  }

  my $table = $html->table({
    width      => '100%',
    title      =>
    [ '#', $lang{LOGIN}, $lang{DATE}, $lang{MODULES}, $lang{TYPE}, $lang{CHANGED}, $lang{ADMIN}, 'IP', '-' ],
    qs         => $pages_qs2, # $pages_qs
    caption    => $lang{LOG},
    pages      => $admin->{TOTAL},
    ID         => 'ADMIN_ACTIONS',
    FIELDS_IDS => $admin->{COL_NAMES_ARR},
    EXPORT     => 1,
    MENU       => "$lang{SEARCH}:search_form=1&index=$index$pages_qs2:search;"
  });

  foreach my $line (@$list) {
    my @location_ids = ();
    if ($line->{actions}) {
      @location_ids = $line->{actions} =~ m/LOCATION_ID (\d+)->(\d+)/g;
    }

    my %location_name = ();

    foreach my $location_id (@location_ids) {
      $location_name{$location_id} = short_address_name($location_id);
    }

    foreach my $name (keys %location_name) {
      $line->{actions} =~ s/$name/$location_name{$name}/g
    }

    my $delete = ($permissions{4} && $permissions{4}{3}) ? $html->button( $lang{DEL}, "index=$index$pages_qs2&del=$line->{id}",
        { MESSAGE => "$lang{DEL} [$line->{id}] ?", class => 'del' } ) : '';

    my ($value, $color);
    if ($line->{action_type}) {
      if (in_array($line->{action_type}, [ 10, 28, 13, 16, 17 ])) {
        $color = 'alert-danger';
      }
      elsif (in_array($line->{action_type}, [ 1, 7 ])) {
        $table->{rowcolor} = 'alert-warning';
      }
      elsif ($line->{action_type} == 3) {
        # change tp
        if ($line->{actions} =~ /(\d+)\-\>(\d+)/) {
          my ($tp_before, $tp_after, $comments) = $line->{actions} =~ /(\d+)\-\>(\d+)(.{0,100})/;
          $line->{actions} = ("($tp_before)" . ($tps_hash->{$tp_before} || '')) . " -> " . ("($tp_after)" . ($tps_hash->{$tp_after} || ''))
            . ($comments || '');
        }
      }
    }
    else {
      $table->{rowcolor} = undef;
    }

    my $message = $line->{actions} || q{};
    if (in_array($line->{action_type}, [ 4,8,9,14 ]) && $message =~ m/^(\d+)\-\>(\d+)(.{0,100})/) {
      my $from_status = $1;
      my $to_status   = $2;
      my $text        = $3 || '';
      $message        = $html->link_former($message);

      if($service_status->{$from_status}) {
        ($value, $color) = split(/:/, $service_status->{$from_status});
        $from_status = $html->color_mark( $value, $color );
      }
      if($service_status->{$to_status}) {
        ($value, $color) = split(/:/, $service_status->{$to_status});
        $to_status = $html->color_mark( $value, $color );
      }
      $message = $from_status. '->' .$to_status . $text;
    }

    if($message) {
      my $br = $html->br();
      my $action_text = ' '.$message;
      while($action_text =~ /\s+([A-Z\_]+)[:\s]/g) {
        my $marker = $1 || q{};
        my $colorstring = $html->b($marker).':';
        $message =~ s/$marker:?/$colorstring/g
      }
      $message =~ s/;/$br/g;
    }
    $line->{action_type} //= 0;
    $table->addrow($html->b($line->{id}),
      $html->button($line->{login}, "index=15&UID=". ($line->{uid} || q{})),
      ($color) ? $html->color_mark($line->{datetime}, $color) : $line->{datetime},
      $line->{module},
      $html->color_mark($action_types{ $line->{action_type} }, $color),
      $html->color_mark($message, $color),
      _status_color_state($line->{admin_login}, $line->{admin_disable}),
      $line->{ip},
      $delete);
  }

  print $table->show();

  $table = $html->table({
    ID         => 'ADMIN_ACTION_TOTAL',
    width      => '100%',
    rows       => [ [ "$lang{TOTAL}:", $html->b( $admin->{TOTAL} ) ] ],
    FIELDS_IDS => {
      1 => $lang{TOTAL},
      2 => $admin->{TOTAL}
    }
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_events($attr) - Show system events

=cut
#**********************************************************
sub form_events {
  my @result_array = ();

  if($conf{SKIP_EVENTS}) {
    print "Content-Type: application/json;\n\n";
    print "[ " . join(", ", @result_array) . " ]";
    return 1;
  }

  print "Content-Type: text/html\n\n" if ($FORM{DEBUG});
  my $cross_modules_return = cross_modules('_events', {
    SKIP_MODULES => 'Sqlcmd,Sysinfo',
    UID => $user->{UID},
  });

  my %admin_modules = ('Events' => 1, 'Notepad' => 1);
  my $admin_groups_ids = '';

  if (in_array('Events', \@MODULES)){

    # Cross-modules should already import and instantiate Events
    our $Events;
    if (!$Events){
      require Events;
      Events->import();
      $Events = Events->new($db, $admin, \%conf);
    }

    $admin_groups_ids = $Events->groups_for_admin($admin->{AID}) || '';

    if ($admin_groups_ids) {
      # Changing 'AND' to 'OR'
      $admin_groups_ids =~ s/, /;/g;
      my $groups_list = $Events->group_list( {
          ID         => $admin_groups_ids,
          MODULES    => '_SHOW',
          COLS_UPPER =>   0
      });

      if ( _error_show($Events) ){
        print "Events-Error: $Events->{sql_errstr}\n";
        return 0;
      }

      foreach my $group ( @{$groups_list} ) {
        my $group_modules_string = $group->{modules} || '';
        my @group_modules = split(',', $group_modules_string);
        map { $admin_modules{$_} = 1 } @group_modules;
      }
    }
  }

  foreach my $module (sort keys %$cross_modules_return) {
    next if ($admin_groups_ids && !$admin_modules{$module});

    my $result = $cross_modules_return->{$module};
    if ($result && $result ne ''){
      push (@result_array, $result);
    }
  }

  print "Content-Type: application/json;\n\n";
  print "[ " . join(", ", @result_array) . " ]";

  return 1;
}

#**********************************************************
=head2 form_back_money($type, $sum, $attr) - Back money to bill account

=cut
#**********************************************************
sub form_back_money {
  my ($type, $sum, $attr) = @_;
  my $uid;

  if ($type eq 'log') {
    if (defined($attr->{LOGIN})) {
      my $list = $users->list({ LOGIN => $attr->{LOGIN}, COLS_NAME => 1 });

      if ($users->{TOTAL} < 1) {
        $html->message( 'err', $lang{USER}, "[$users->{errno}] $err_strs{$users->{errno}}" );
        return 0;
      }
      $uid = $list->[0]->{uid};
    }
    else {
      $uid = $attr->{UID};
    }
  }

  my $user = $users->info($uid);

  my $OP_SID = ($FORM{OP_SID}) ? $FORM{OP_SID} : mk_unique_value(16);

  print $html->form_main(
    {
      HIDDEN => {
        index   => $index,
        subf    => $index,
        sum     => $sum,
        OP_SID  => $OP_SID,
        UID     => $uid,
        BILL_ID => $user->{BILL_ID}
      },
      SUBMIT => { bm => "$lang{BACK_MONEY} ?" }
    }
  );

  return 1;
}

#**********************************************************
=head2 form_passwd($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub form_passwd {
  my ($attr) = @_;

  my $password_form;
  my $ret  = 0;
  my $is_g2fa = 0;

  if (defined($FORM{AID})) {
    $password_form->{HIDDDEN_INPUT} = $html->form_input(
      'AID',
      $FORM{AID},
      {
        TYPE          => 'hidden',
        OUTPUT2RETURN => 1
      }
    );
    $index = 50;

    $is_g2fa = 1 if ($conf{AUTH_G2FA} && $attr->{ADMIN} && $attr->{ADMIN}->{G2FA});
  }
  elsif (defined($attr->{USER_INFO})) {
    $password_form->{HIDDDEN_INPUT} = $html->form_input(
      'UID',
      $FORM{UID},
      {
        TYPE          => 'hidden',
        OUTPUT2RETURN => 1
      }
    );
    $index = 15 if (!$attr->{REGISTRATION});
    if ($conf{AUTH_G2FA}) {
      $attr->{USER_INFO}->pi({ UID => $attr->{USER_INFO}->{UID} });
      $is_g2fa = 1 if ($attr->{USER_INFO}->{_G2FA});
    }
  }

  $conf{PASSWD_LENGTH} = 8 if (!$conf{PASSWD_LENGTH});

  if (! $FORM{newpassword}) {

  }
  elsif (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
    $lang{ERR_SHORT_PASSWD} =~ s/6/$conf{PASSWD_LENGTH}/;
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_SHORT_PASSWD} $conf{PASSWD_LENGTH}");
    $ret = 0;
  }
  elsif ($conf{CONFIG_PASSWORD}
    && ( defined($FORM{AID}) || ( $conf{PASSWD_POLICY_USERS} && defined $FORM{UID} ) )
    && !Conf::check_password($FORM{newpassword}, $conf{CONFIG_PASSWORD})
  ){
    load_module('Config', $html);
    my $explain_string = config_get_password_constraints($conf{CONFIG_PASSWORD});

    $html->message( 'err', $lang{ERROR}, "$lang{ERR_PASSWORD_INSECURE} $explain_string");
    $ret = 0;
  }
  elsif ($FORM{newpassword} eq $FORM{confirm}) {
    $FORM{PASSWORD} = $FORM{newpassword};
    return 1;
  }
  elsif ($FORM{newpassword} ne $FORM{confirm}) {
    $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_CONFIRM} );
    $ret = 0;
  }

  $password_form->{PW_CHARS}   = $conf{PASSWD_SYMBOLS} || "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ";
  $password_form->{PW_LENGTH}  = $conf{PASSWD_LENGTH}  || 6;
  $password_form->{ACTION}     = 'change';
  $password_form->{LNG_ACTION} = $lang{CHANGE};
  $password_form->{CONFIG_PASSWORD} = $conf{CONFIG_PASSWORD} || q{};

  if ($conf{AUTH_G2FA} && $is_g2fa) {
    $password_form->{G2FA_HIDDEN} = '';
    $password_form->{G2FA_REMOVE} = 1;
    $password_form->{G2FA_INPUT_HIDDEN} = 'hidden';
    $password_form->{G2FA_STYLE} = 'justify-content-center';
    $password_form->{G2FA_BUTTON} = $lang{DELETE};
    $password_form->{G2FA_ACTION} = 'change';
  }
  else {
    $password_form->{G2FA_HIDDEN} = 'hidden';
  }

  if(! $FORM{generated_pw} || ! $FORM{newpassword} || ! $FORM{confirm}) {
    $password_form->{newpassword}=mk_unique_value($password_form->{PW_LENGTH},
      {  SYMBOLS => $password_form->{PW_CHARS} });
    $password_form->{confirm}=$password_form->{newpassword};
  }

  $html->tpl_show(templates('form_password'), $password_form);

  return $ret;
}

#**********************************************************
=head2 fl() Main functions

=cut
#**********************************************************
sub fl {

  # ID:PARENT:NAME:FUNCTION:SHOW SUBMENU:module:
  my @m = (

    "1:0:<i class='nav-icon fa fa-user'></i><p class='d-inline'>$lang{CUSTOMERS}</p>:null:::",
    "11:1:$lang{LOGINS}:form_users_list:::",
    "16:13:$lang{ADMIN}:form_companie_admins:COMPANY_ID:Control/Companies_mng:",

    "15:11:$lang{INFO}:form_users:UID::",
    "20:15:$lang{SERVICES}:null:UID::",
    "101:15:$lang{PAYMENTS}:form_payments:UID:Control/Payments:",
    "102:15:$lang{FEES}:form_fees:UID:Control/Fees:",
    "103:15:$lang{SHEDULE}:form_shedule:UID::",
    "125:15:$lang{ADDITION}:user_contract:UID:Control/Contracts_mng:",

    "31:15:$lang{SEARCH}:user_modal_search:user_search_form::",
    "32:15:$lang{LOGIN}:check_login_availability:AJAX::",

    "2:0:<i class='nav-icon far fa-plus-square'></i><p class='d-inline'>$lang{PAYMENTS}</p>:form_payments::Control/Payments:",
    "3:0:<i class='nav-icon far fa-minus-square'></i><p class='d-inline'>$lang{FEES}</p>:form_fees::Control/Fees:",
    "6:0:<i class='nav-icon far fa-eye'></i><p class='d-inline'>$lang{MONITORING}</p>:null:::",
    "7:0:<i class='nav-icon fa fa-search'></i><p class='d-inline'>$lang{SEARCH}</p>:form_search:::",
    "8:0:<i class='nav-icon fa fa-flag'></i><p class='d-inline'>$lang{MAINTAIN}</p>:null:::",
    "9:0:<i class='nav-icon fa fa-wrench'></i><p class='d-inline'>$lang{PROFILE}</p>:admin_profile::Control/Profile:",
  );

  if ($permissions{0}) {
    require Control::Users_mng;

    if ($permissions{0}{3}) {
      push @m, "17:15:$lang{PASSWD}:form_passwd:UID::";
    }

    if ($permissions{0}{4}) {
      push @m, "30:15:$lang{USER_INFO}:user_pi:UID::";
      push @m, "18:15:$lang{NAS}:form_nas_allow:UID::";
      push @m, "19:15:$lang{BILL}:form_bills:UID::";
      push @m, "23:15:$lang{MONEY_TRANSFER}:form_money_transfer_admin:UID::";
    }

    if ($permissions{0}{28}) {
      push @m, "12:15:$lang{GROUP}:user_group:UID::";
      push @m, "27:1:$lang{GROUPS}:form_groups::Control/Groups_mng:";
    }

    if ($permissions{0}{36}) {
      push @m, "13:1:$lang{COMPANY}:form_companies::Control/Companies_mng:";
      push @m, "21:15:$lang{COMPANY}:user_company:UID:Control/Companies_mng:";
    }
    if ($permissions{0}{30}) {
      push @m, "22:15:$lang{LOG}:form_changes:UID::";
    }
  }
  if ($permissions{1}) {
    # Control/Payments;
  }

  if ($permissions{2}) {
    # Control/Fees
  }

  if ($permissions{8}){
    push @m,
      "110:9:$lang{FUNCTIONS_LIST}:flist::Control/Profile:",
      "111:9:$lang{EVENTS}:form_events:AJAX::",
      "112:9:$lang{SLIDES}:form_slides_create::Control/Profile:";
  }

  if ($conf{NON_PRIVILEGES_LOCATION_OPERATION}) {
    require Control::Address_mng;
    push @m, "70:8:$lang{LOCATIONS}:form_districts:::",
             "71:70:$lang{STREETS}:form_streets::",
             "135:70:Address update:form_address_select2:AJAX::";
  }
  else {
    require Control::Address_mng;
    if ($permissions{4}) {
      push @m, "70:5:$lang{LOCATIONS}:form_districts:::",
               "71:70:$lang{STREETS}:form_streets::",
               "72:70:$lang{ADDRESS_UNIT_TYPES}:form_address_types::",
               "73:70:$lang{BUILDING_TYPES}:form_building_types::",
               "74:70:$lang{TREE_LIKE_STRUCTURE}:form_address_tree::";
    }
    push @m, "135:70:Address update:form_address_select2:AJAX::";
  }

  push @m, "4:0:<i class='nav-icon far fa-chart-bar'></i><p class='d-inline'>$lang{REPORTS}</p>:form_reports::Control/Reports:";

  #Reports
  if($permissions{3}){
    if($permissions{3}{7}) {
      push @m, "76:4:$lang{WEB_SERVER}:report_webserver::Control/Reports:",
        "122:4:$lang{LIST_OF_LOGS}:logs_list::Control/Reports:";
    }

    if($permissions{3}{8}) {
      push @m, "131:4:$lang{USERS}:null:::";
      push @m, "132:131:$lang{REPORT_NEW_ALL_USERS}:report_new_all_customers::Control/User_reports:";
      push @m, "133:131:$lang{REPORT_NEW_ARPU_USERS}:report_new_arpu::Control/User_reports:";
      push @m, "134:131:$lang{REPORT_BALANCE_BY_STATUS}:report_balance_by_status::Control/User_reports:";
      push @m, "136:131:$lang{REPORT_SWITCH_WITH_USERS}:report_switch::Control/User_reports:";
      push @m, "137:131:$lang{REPORT_REASON_USERS_DISABLED}:report_users_disabled::Control/User_reports:";
    }

    if($conf{AUTH_FACEBOOK_ID}){
      push @m, "127:4:$lang{SOCIAL_NETWORKS}:null:::";
      push @m, "128:127:Facebook:reports_facebook_users_info::Control/Reports:";
    }

    #Payments reports
    if ($permissions{3}{2}) {
      push @m, "42:4:$lang{PAYMENTS}:report_payments::Control/Reports:",
        "43:42:$lang{MONTH}:report_payments_month::Control/Reports:";
    }
    #Allow fees reports
    if ($permissions{3}{3}) {
      push @m, "44:4:$lang{FEES}:report_fees::Control/Reports:",
        "45:44:$lang{MONTH}:report_fees_month::Control/Reports:";
    }

    if ($permissions{3}{4}) {
      push @m, "67:4:$lang{EVENTS}:form_changes::Control/Reports:";
    }

    if ($permissions{3}{5}) {
      push @m, "68:4:$lang{CONFIG}:form_system_changes::Control/Reports:",
        "86:4:$lang{USER_PORTAL}:null:::",
        "87:86:$lang{BRUTE_ATACK}:report_bruteforce::Control/Reports:",
        "88:86:$lang{SESSIONS}:report_ui_last_sessions::Control/Reports:",
        "123:86:$lang{USER_STATISTIC}:analiz_user_statistic::Control/Reports:";
    }
  }

  #config functions
  if ($permissions{4}) {
    push (@m, "5:0:<i class='nav-icon fas fa-cog'></i><p class='d-inline'>$lang{CONFIG}</p>:null:::",
      "62:5:$lang{NAS}:form_nas::Control/Nas_mng:",
      "63:62:$lang{IP_POOLS}:form_ip_pools::Control/Nas_mng:",
      "64:62:$lang{NAS_STATISTIC}:form_nas_stats::Control/Nas_mng:",
      "65:62:$lang{GROUPS}:form_nas_groups::Control/Nas_mng:",
      "145:50:$lang{LOG}:form_changes:::",
      "148:5::nas_radius_pairs_save:AJAX:Control/Nas_mng:",
      "85:5:$lang{SHEDULE}:form_shedule:::",
      "89:90:$lang{CONTACTS} $lang{TYPES}:form_contact_types:::",
      "90:5:$lang{MISC}:null:::",
      "91:90:$lang{TEMPLATES}:form_templates::Control/System:",
      "92:90:$lang{DICTIONARY}:form_dictionary::Control/System:",
      "93:90:$lang{CHECKSUM}:form_config::Control/System:",
      "94:90:$lang{PATHES}:form_prog_pathes::Control/System:",
      "95:90:$lang{SQL_BACKUP}:form_sql_backup::Control/System:",
      "96:90:$lang{INFO_FIELDS}:form_info_fields::Control/System:",
      "97:96:$lang{LIST}:form_info_lists::Control/System:",
      "98:90:$lang{TYPE} $lang{FEES}:form_fees_types::Control/System:",
      "99:90:$lang{BILLD}:form_billd_plugins::Control/System:",
      "118:90:$lang{EDIT}:form_templates_pdf_save:AJAX:Control/System:",
      "119:90:$lang{EDIT}:form_templates_pdf_edit::Control/System:",
      "120:90:$lang{SERVICE_STATUS}:form_status::Control/System:",
      "121:90:$lang{USER_STATUS}:form_user_status::Control/System:",
      "138:90:$lang{ORGANIZATION_INFO}:organization_info::Control/System:",
      "124:90:$lang{PAYMENT_METHOD}:form_payment_types::Control/System:",
      "129:90:$lang{FILE_MANAGER}:file_tree::Control/Filemanager:",
      "130:90:$lang{TAX_MAGAZINE}:taxes::Control/Taxes:",
      "126:90:$lang{TYPES} $lang{CONTRACTS}:contracts_type::Control/Contracts_mng:",
      "149:90:$lang{HOLIDAYS}:form_holidays::Control/System:",
      "150:90:$lang{EXCHANGE_RATE}:form_exchange_rate::Control/System:",
      );

    #Allow Admin managment function
    if ($permissions{4}{4}) {
      push @m, "50:5:$lang{ADMINS}:form_admins::Control/Admins_mng:",
        "51:50:$lang{LOG}:form_changes:AID::",
        "52:50:$lang{PERMISSION}:form_admin_permissions:AID:Control/Admins_mng:",
        "54:50:$lang{PASSWD}:form_passwd:AID::",
        "146:50:$lang{PAYMENT_TYPE}:form_admin_payment_types:AID:Control/Admins_mng:",
        "55:50:$lang{FEES}:form_fees:AID:Control/Fees:",
        "56:50:$lang{PAYMENTS}:form_payments:AID:Control/Payments:",
        "57:50:$lang{CHANGE}:form_admins:AID:Control/Admins_mng:",
        "59:50:$lang{ACCESS}:form_admins_access:AID:Control/Admins_mng:",
        "60:50:Paranoid:form_admins_full_log_analyze:AID:Control/Admins_mng:",
        "115:50:$lang{AUTH_HISTORY}:form_admin_auth_history:AID:Control/Admins_mng:",
        "61:50:$lang{CONTACTS}:form_admins_contacts:AID:Control/Admins_mng:",
        "69:50::form_admins_contacts_save:AID,AJAX:Control/Admins_mng:";
        push @m, "58:50:$lang{GROUPS}:form_admins_groups:AID:Control/Admins_mng:" if (! $admin->{GID} || ( $permissions{0} && $permissions{0}{28} ) );
        push @m, "113:50:Domains:form_admins_domains:AID:Control/Admins_mng:" if (in_array('Multidoms', \@MODULES));
    }
  }

  if ($permissions{0} && $permissions{0}{1}) {
    push @m, "24:11:$lang{ADD_USER}:form_wizard:::";
  }

  if ($conf{AUTH_METHOD}) {
    $permissions{9}{1}=1;
    push @m, "10:0:<i class='nav-icon fa fa-sign-out-alt'></i><p class='d-inline'>$lang{LOGOUT}</p>:null:::";
  }

  my $custom_menu = custom_menu();
  if($#{ $custom_menu } > -1) {
    mk_menu($custom_menu, { CUSTOM => 1 });
    return 1;
  }

  mk_menu(\@m);

  return 1;
}

#**********************************************************
=head2 mk_navigator()

=cut
#**********************************************************
sub mk_navigator {
  my ($menu_navigator, $menu_text_) = $html->menu(\%menu_items, \%menu_args, \%permissions, { FUNCTION_LIST => \%functions });
  if ($html->{ERROR}) {
    $html->message( 'err', $lang{ERROR}, $html->{ERROR} );
    die $html->{ERROR};
  }

  return $menu_text_, " " . $menu_navigator;
}


#**********************************************************
=head2 form_search($attr) - Search form

  Arguments:
    $attr
      SIMPLE
      TPL
      ADDRESS_FORM  - show address form
      PLAIN_SEARCH_FORM
      SEARCH_FORM   -
      SHOW_PERIOD   - Show period inputs
      CONTROL_FORM  - Control form by $FORM{search_form}
      HIDDEN_FIELDS - { key => val }

  Returns:

=cut
#**********************************************************
sub form_search {
  my ($attr) = @_;

  my %SEARCH_DATA = $admin->get_data(\%FORM);
  my %info = ();

  my $search_type = $FORM{type} || 0;

  if ($search_type =~ /^\d+$/ && ($search_type == 2 || $search_type == 3)) {
    $attr->{SHOW_PERIOD} = 1;
  }

  $FORM{DISTRICT_ID} =~ s/,/;/g if $FORM{DISTRICT_ID};
  $FORM{STREET_ID} =~ s/,/;/g if $FORM{STREET_ID};
  $FORM{LOCATION_ID} =~ s/,/;/g if $FORM{LOCATION_ID};

  if ($FORM{search}) {
    if($FORM{quick_search}) {
      print "Content-Type: text/html\n\n";
      print "Quick search";
      exit;
    }

    $pages_qs = "&search=1";
    $pages_qs .= "&type=$search_type" if ($search_type && $pages_qs !~ /&type=/);

    if($search_type =~ /^\d+$/) {

      if ($search_type == 999) {
        return form_search_all($FORM{LOGIN});
      }
      elsif ($search_type == 10) {
        $FORM{type} = 11;
        $search_type = 11;
        if ($admin->{SETTINGS} && $admin->{SETTINGS}{SEARCH_FIELDS}) {
          @default_search = split(/, /, $admin->{SETTINGS}{SEARCH_FIELDS});
        }

        my $search_string = $FORM{LOGIN} || $FORM{UNIVERSAL_SEARCH} || q{};
        $search_string =~ s/\s+$//;
        $search_string =~ s/^\s+//;
        $FORM{_MULTI_HIT} = $search_string;

        foreach my $field (@default_search) {
          $LIST_PARAMS{$field} = "*$search_string*";
        }

        delete $FORM{LOGIN};
        $FORM{UNIVERSAL_SEARCH} = $search_string;
        if ($FORM{UNIVERSAL_SEARCH}) {
          $LIST_PARAMS{sort}=1;
          $LIST_PARAMS{desc}=q{};
        }
      }
      elsif($search_type == 13 && $FORM{LOGIN}) {
        $FORM{COMPANY_NAME}=$FORM{LOGIN};
        delete $FORM{LOGIN};
      }
      elsif ($FORM{TYPE_PAGE}) {
        $FORM{type} = $FORM{TYPE_PAGE};
        $search_type = $FORM{type};
      }
    }
    else {
      $LIST_PARAMS{LOGIN} = $FORM{LOGIN};
    }

    while (my ($k, $v) = each %FORM) {
      $v //= q{};
      if ($k =~ /([A-Z0-9]+|_[a-z0-9]+)/ && $v ne '' && $k ne '__BUFFER' && $v ne ', ') {
        $LIST_PARAMS{$k} = $v;
        $v =~ s/=/%3D/g;
        $v =~ s/\+/%2B/g;
        $pages_qs .= "&$k=$v";
      }
    }

    if ($search_type ne $index && ! $FORM{subf} && $functions{ $search_type }) {

      my $return = 1;
      if ($search_type) {
        load_module($module{$search_type}, $html) if ($module{$search_type});
        $return = _function($search_type);
      }

      if (! $return) {
        return 0;
      }
      elsif($FORM{json} || $FORM{xml}) {
        return 1;
      }
    }
  }

  if ($attr->{HIDDEN_FIELDS} && ref $attr->{HIDDEN_FIELDS} eq 'HASH') {
    my $SEARCH_FIELDS = $attr->{HIDDEN_FIELDS};
    while (my ($k, $v) = each(%$SEARCH_FIELDS)) {
      $SEARCH_DATA{HIDDEN_FIELDS} .= $html->form_input(
        $k, ($v || q{}),
        {
          TYPE          => 'hidden',
          OUTPUT2RETURN => 1
        }
      );
    }
  }

  if (defined($attr->{SIMPLE})) {
    if ( $attr->{CONTROL_FORM} && ! $FORM{search_form}) {
      return '';
    }

    my $SEARCH_FIELDS = $attr->{SIMPLE};
    foreach my $k (sort keys %$SEARCH_FIELDS) {
      my $v = $SEARCH_FIELDS->{$k};
      my $input_form = '';
      if (ref $v eq 'HASH') {
        my ($field_name) = keys %$v;
        $input_form .= $html->form_select(
          (ref $v->{$field_name} eq 'HASH') ? $field_name : $k,
          {
            SELECTED => $FORM{$field_name || $k} || 0 || '',
            SEL_HASH => (ref $v->{$field_name} eq 'HASH') ? $v->{$field_name} : $v
          }
        );
      }
      else {
        $input_form .= $html->form_input($v, $FORM{$v} || '%' . $v . '%');
      }

      $SEARCH_DATA{SEARCH_FORM} .= $html->tpl_show(templates('form_row'), {
          ID    => "$k",
          NAME  => "$k",
          VALUE => $input_form
        }, { OUTPUT2RETURN => 1 });
    }

    $html->tpl_show(templates('form_search_simple'), \%SEARCH_DATA);
  }
  elsif ($attr->{TPL}) {
    print $attr->{TPL};
  }
  elsif (!$FORM{pdf}) {
    if ( $attr->{CONTROL_FORM} && ! $FORM{search_form}) {
      return '';
    }

    my %search_form = (
      2  => 'form_search_payments',
      3  => 'form_search_fees',
      11 => 'form_search_users',
      13 => 'form_search_companies'
    );

    if ($search_type == 15) {
      $FORM{type} = 11;
      $search_type= 11;
    }
    elsif($search_type == 10) {
      $FORM{UNIVERSAL_SEARCH}=$FORM{LOGIN} || q{};
      $FORM{type} = 11;
      $search_type= 11;
      $FORM{_MULTI_HIT}=$FORM{UNIVERSAL_SEARCH};
    }

    if ($FORM{LOGIN} && $admin->{MIN_SEARCH_CHARS} && length($FORM{LOGIN}) < $admin->{MIN_SEARCH_CHARS}) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_SEARCH_VAL_TOSMALL}. $lang{MIN}: $admin->{MIN_SEARCH_CHARS}" );
      return 0;
    }

    if (defined($attr->{SEARCH_FORM})) {
      $SEARCH_DATA{SEARCH_FORM} = $attr->{SEARCH_FORM};
    }
    elsif ($search_type && $search_form{ $search_type }) {
      if ($FORM{type} == 2) {
        $info{SEL_METHOD} = $html->form_select(
          'METHOD',
          {
            SELECTED     => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
            SEL_HASH     => get_payment_methods(),
            SORT_KEY_NUM => 1,
            NO_ID        => 1,
            SEL_OPTIONS  => { '' => $lang{ALL} }
          }
        );
        $SEARCH_DATA{SEARCH_FORM} = $html->tpl_show(templates('form_search_personal_info'), { %FORM, %info }, { OUTPUT2RETURN => 1 });
        $attr->{ADDRESS_FORM}=1;
      }
      elsif ($search_type == 3) {
        $info{SEL_METHOD} = $html->form_select(
          'METHOD',
          {
            SELECTED     => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
            SEL_HASH     => get_fees_types(),
            SORT_KEY_NUM => 1,
            NO_ID        => 1,
            SEL_OPTIONS  => { '' => $lang{ALL} }
          }
        );
        $SEARCH_DATA{SEARCH_FORM} = $html->tpl_show(templates('form_search_personal_info'), { %FORM, %info }, { OUTPUT2RETURN => 1 });
        $attr->{ADDRESS_FORM}=1;
      }
      elsif ($search_type == 11 || $search_type == 15) {
        if ($index == 30) {
          $index=7;
          delete $FORM{UID};
        }

        $SEARCH_DATA{SEARCH_FORM} = $html->tpl_show(templates('form_search_personal_info'), { %FORM, %info }, { OUTPUT2RETURN => 1 });
        $info{INFO_FIELDS} = form_info_field_tpl({ SKIP_DATA_RETURN => 1, SKIP_REQUIRED => 1 });

        if (in_array('Docs', \@MODULES)) {
          if ($conf{DOCS_CONTRACT_TYPES}) {
            $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
            my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});

            my %CONTRACTS_LIST_HASH = ();
            foreach my $line (@contract_types_list) {
              my ($prefix, $sufix, $name) = split(/:/, $line);
              #$prefix, $sufix, $name, $tpl_name<br>";
              $prefix =~ s/ //g;
              $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
            }

            $info{CONTRACT_SUFIX} = $html->form_select(
              'CONTRACT_SUFIX',
              {
                SELECTED => $FORM{CONTRACT_SUFIX},
                SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
                NO_ID    => 1
              }
            );

            $info{CONTRACT_TYPE_FORM} = $html->tpl_show(templates('form_row'), {
              ID    => "CONTRACT_TYPE",
              NAME  => "$lang{CONTRACT} $lang{TYPE}",
              VALUE => $info{CONTRACT_SUFIX}
              }, { OUTPUT2RETURN => 1 });
          }
        }

        if (in_array('Multidoms', \@MODULES) && $permissions{10}) {
          load_module('Multidoms', $html);

          $info{DOMAIN_FORM} = $html->tpl_show(templates('form_row'), {
            ID    => 'DOMAIN_ID',
            NAME  => "Domains:",
            VALUE => multidoms_domains_sel(),
          }, { OUTPUT2RETURN => 1 });
        }
        $attr->{ADDRESS_FORM}=1;

        $info{REGISTRATION_RANGE} = $html->form_daterangepicker({
          NAME         => 'REGISTRATION_FROM/REGISTRATION_TO',
          VALUE        => $FORM{'REGISTRATION_FROM_REGISTRATION_TO'},
          RETURN_INPUT => 1
        });

        $info{DISABLE_SELECT} = $html->form_select(
          'DISABLE',
          {
            SELECTED => $FORM{DISABLE},
            SEL_HASH => {
            ('' => ''),
              (0 => $lang{ACTIV}),
              (1 => $lang{DISABLE}),
            },
            NO_ID    => 1
          });


        $info{DELETE_SELECT} = $html->form_select(
          'DELETED',
          {
            SELECTED => $FORM{DELETED} || '',
            SEL_HASH => {
              ('' => ''),
              (0 => $lang{NO}),
              (1 => $lang{YES})
            },
            NO_ID    => 1
          });


      }
      elsif ($search_type == 13) {
        $info{INFO_FIELDS}  = form_info_field_tpl({ COMPANY => 1, SKIP_REQUIRED => 1 });
      }

      $SEARCH_DATA{SEARCH_FORM} .= $html->tpl_show(templates($search_form{ $search_type }), { %FORM, %info }, { OUTPUT2RETURN => 1 });
      $SEARCH_DATA{SEARCH_FORM} .= $html->form_input('type', $search_type, { TYPE => 'hidden', FORM_ID => 'SKIP' });
    }

    if ($attr->{ADDRESS_FORM}) {
      my $address_form = '';

      if ($conf{ADDRESS_REGISTER}) {
        my %address_info = ();
        if ($FORM{LOCATION_ID}) {
          require Address;
          my $Address = Address->new($db, $admin, \%conf);
          $Address->address_info($FORM{LOCATION_ID});
          _error_show($Address);

          %address_info = (
            ADDRESS_DISTRICT => $Address->{ADDRESS_DISTRICT},
            ADDRESS_STREET   => $Address->{ADDRESS_STREET},
            ADDRESS_BUILD    => $Address->{ADDRESS_BUILD}
          );
        }

        $address_form = form_address_select2({ %FORM,
          HIDE_ADD_BUILD_BUTTON => $conf{HIDE_SEARCH_BUILD_INPUT} ? 1 : 0,
          MULTIPLE              => 1,
          SHOW_BUTTONS          => 1
        });

        $address_form .= $html->tpl_show(templates('form_ext_address'), {
          ENTRANCE => $FORM{ENTRANCE},
          FLOOR    => $FORM{FLOOR}
        }, { OUTPUT2RETURN => 1 });
      }
      else {
        my $countries_hash;
        ($countries_hash, $users->{COUNTRY_SEL}) = sel_countries({ NAME => 'COUNTRY', COUNTRY => $users->{COUNTRY_ID} });
        $address_form = $html->tpl_show(templates('form_address'), { %FORM, %$users }, { OUTPUT2RETURN => 1, ID => 'form_address' });
      }

      $SEARCH_DATA{ADDRESS_FORM} = $html->tpl_show(templates('form_show_not_hide'),{
          CONTENT     => $address_form,
          NAME        => $lang{ADDRESS},
          ID          => 'ADDRESS_FORM',
          BUTTON_ICON => 'minus'
      }, { OUTPUT2RETURN => 1 });
    }

    $SEARCH_DATA{FROM_DATE} = $html->form_datepicker('FROM_DATE', $FORM{FROM_DATE});

    $SEARCH_DATA{TO_DATE}   = $html->form_datepicker('TO_DATE', $FORM{TO_DATE});

    if ($index == 7) {
      my @header_arr = ();
      foreach my $k ( sort keys %SEARCH_TYPES) {
        my $v = $SEARCH_TYPES{$k};
        if ($k == 10)  {

        }
        elsif ($k == 11 || $k == 13 || $permissions{ ($k - 1) }) {
          push @header_arr, "$v:index=$index&type=$k";
        }
      }

      foreach (sort @MODULES){

        my $function = lc($_) . '_users_list';
        my $function_index = get_function_index($function);
        next if(!$function_index);
        push @header_arr, "$_:index=$function_index&search_form=1";

      }

      $SEARCH_DATA{SEL_TYPE} =  $html->table_header(\@header_arr, { TABS => 1 });
    }

    if (in_array('Tags', \@MODULES)) {
      if (!$admin->{MODULES} || ($admin->{MODULES} && $admin->{MODULES}->{Tags})) {
        load_module('Tags', $html);

        my $tag_count;
        my $form_tags_sel;

        $SEARCH_DATA{TAG_SEARCH_VAL} = $html->form_select('TAG_SEARCH_VAL', {
          ID          => 'SEARCH_VAL',
          SELECTED    =>  0,
          NO_ID       =>  1,
          SEL_OPTIONS => {0 => "$lang{OR}", 1 => "$lang{AND}",},
        });

        ($form_tags_sel, $tag_count) = tags_sel({ HASH => 1, SHOW_EXT_BUTTON => 1 });
        if ($tag_count) {
          $SEARCH_DATA{TAGS_SEL} = $form_tags_sel;
        }
        else {
          $SEARCH_DATA{DISPLAY_TAGS} = 'display: none;';
        }
      }
      else {
        $SEARCH_DATA{DISPLAY_TAGS} = 'display: none;';
      }
    }

    if ($attr->{PLAIN_SEARCH_FORM}) {
      if ($SEARCH_DATA{ADDRESS_FORM}) {
        $SEARCH_DATA{ADDRESS_FORM} = $html->element('div', $SEARCH_DATA{ADDRESS_FORM}, { class => 'col-md col-xs-12' });
      }
      if ($SEARCH_DATA{SEARCH_FORM}) {
        $SEARCH_DATA{SEARCH_FORM} = $html->element('div', $SEARCH_DATA{SEARCH_FORM}, { class => 'col-md col-xs-12' });
      }
      $html->tpl_show(templates('form_search_plain'), {%SEARCH_DATA}, { ID => $attr->{ID} });
    }
    else {
      if (!$attr->{SHOW_PERIOD}){
        delete @SEARCH_DATA{'FROM_DATE', 'TO_DATE'};
        $SEARCH_DATA{HIDE_DATE} = 'hidden';
      };

      if ($admin->{permissions}->{0}->{28}) {
        my $group_sel   = sel_groups({FILTER_SEL => 1}) ;
        $SEARCH_DATA{GROUPS_SEL} = $group_sel;
      }
      else {
        $SEARCH_DATA{DISPLAY_GROUP} = 'display: none;';
      }

      $html->tpl_show(templates('form_search'), {
        %SEARCH_DATA
      }, {
        ID => $attr->{ID}
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 form_search_all($search_text)

  Arguments:
    $search_text

=cut
#**********************************************************
sub form_search_all {
  my ($search_text)=@_;

  print $html->element('div', "$lang{SEARCH}: '$search_text'",
    { class => "well well-sm" });
  my $debug = $FORM{DEBUG} || 0;

  my $cross_modules_return = cross_modules('search', {
    SEARCH_TEXT => $search_text,
    DEBUG       => $FORM{DEBUG},
  });

  #main user_search
  $cross_modules_return->{main}=form_users_search({
    SEARCH_TEXT => $search_text,
    DEBUG       => $FORM{DEBUG},
  });

  foreach my $module ( sort keys %{$cross_modules_return} ) {
    my $result = $cross_modules_return->{$module};
    if(ref $result eq 'ARRAY') {
      foreach my $res (@$result) {
        if ($res->{TOTAL}) {
          if ($debug > 3) {
            print %$res;
          }
          $html->message((! $res->{MODULE}) ? 'info' : 'warn', '',
            $html->b($res->{MODULE_NAME})
            . (($res->{MODULE}) ? " ($res->{MODULE})" : q{})
            . ": "
            . $html->button($html->badge($res->{TOTAL}), "index=" . $res->{SEARCH_INDEX}));
        }
        elsif($res->{EXTRA_LINK}) {
          my($name, $link)=split(/\|/, $res->{EXTRA_LINK});
          $html->message('warn', '',
            $html->b($res->{MODULE_NAME})
              . (($res->{MODULE}) ? " ($res->{MODULE})" : q{})
              . ": "
              . $html->button($html->badge($name, { TYPE => 'alert-success' }), $link));
        }
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 form_shedule()

=cut
#**********************************************************
sub form_shedule {

  require Shedule;
  Shedule->import();

  my $Shedule = Shedule->new($db, $admin, \%conf);
  if ($FORM{add_form}) {
    $Shedule->{SEL_D} = $html->form_select(
    'D',
    {
      SELECTED => $FORM{D},
      SEL_HASH => {
        '*' => '*',
        1   => 1,
        2   => 2,
        3   => 3,
        4   => 4,
        5   => 5,
        6   => 6,
        7   => 7,
        8   => 8,
        9   => 9,
        10  => 10,
        11  => 11,
        12  => 12,
        13  => 13,
        14  => 14,
        15  => 15,
        16  => 16,
        17  => 17,
        18  => 18,
        19  => 19,
        20  => 20,
        21  => 21,
        22  => 22,
        23  => 23,
        24  => 24,
        25  => 25,
        26  => 26,
        27  => 27,
        28  => 28,
        29  => 29,
        30  => 30,
        31  => 31
      },
      NO_ID        => 1,
      SORT_KEY_NUM => 1
    });

    $Shedule->{SEL_M} = $html->form_select('M',
    {
      SELECTED => $FORM{M},
      SEL_HASH => {
        '*' => '*',
        1   => $MONTHES[0],
        2   => $MONTHES[1],
        3   => $MONTHES[2],
        4   => $MONTHES[3],
        5   => $MONTHES[4],
        6   => $MONTHES[5],
        7   => $MONTHES[6],
        8   => $MONTHES[7],
        9   => $MONTHES[8],
        10  => $MONTHES[9],
        11  => $MONTHES[10],
        12  => $MONTHES[11],
      },
      NO_ID        => 1,
      SORT_KEY_NUM => 1
    });

    my ($YEAR) = split(/-/, $DATE);

    $Shedule->{SEL_Y} = $html->form_select('Y', {
        SELECTED     => $FORM{Y},
        SEL_HASH     => { '*' => '*', $YEAR => $YEAR, ($YEAR + 1) => ($YEAR + 1), ($YEAR + 2) => ($YEAR + 2) },
        NO_ID        => 1,
        SORT_KEY_NUM => 1
    });

    $Shedule->{SEL_TYPE} = $html->form_select('TYPE',  {
      SELECTED => $FORM{TYPE},
      SEL_HASH => { 'sql' => 'SQL' },
      NO_ID    => 1,
    });

    $html->tpl_show(templates("form_shedule"), {%$Shedule},);
  }
  elsif ($FORM{add}) {
    $FORM{D} = sprintf("%02d", $FORM{D}) if($FORM{D} && $FORM{D} =~ /\d+/);
    $FORM{M} = sprintf("%02d", $FORM{M}) if($FORM{M} && $FORM{M} =~ /\d+/);
    $Shedule->add( \%FORM );

    if (!$Shedule->{errno}) {
      $html->message( 'info', $lang{ADDED}, "$lang{ADDED} [$Shedule->{INSERT_ID}]" );
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Shedule->del({ ID => $FORM{del} });
    if (!$Shedule->{errno}) {
      $html->message( 'info', $lang{DELETED}, "$lang{DELETED} [$FORM{del}]" );
    }
  }

  _error_show($Shedule);

  my %TYPES = (
    'tp'     => "$lang{CHANGE} $lang{TARIF_PLAN}",
    'fees'   => $lang{FEES},
    'status' => $lang{STATUS},
    'sql'    => 'SQL'
  );

  if (! exists($INC{"Control/Services.pm"})) {
    require Control::Services;
  }
  my $tp_list = sel_tp({ MODULE => 'Internet;Iptv;Cams;Ureports;Voip;Dv' });

  if ($FORM{SHEDULE_DATE}) {
    $LIST_PARAMS{SHEDULE_DATE}=$FORM{SHEDULE_DATE};
  }

  my $list  = $Shedule->list({%LIST_PARAMS, COLS_NAME => 1 });

  my $service_status = sel_status({ HASH_RESULT => 1 });

  my $table = $html->table({
    width      => '100%',
    caption    => $lang{SHEDULE},
    title      =>
      [ $lang{HOURS}, $lang{DAY}, $lang{MONTH}, $lang{YEAR}, $lang{COUNT}, $lang{USER}, $lang{TYPE},
        $lang{VALUE}, $lang{MODULES}, $lang{ADMINS}, $lang{CREATED}, $lang{COMMENTS}, "-" ],
    qs         => $pages_qs,
    pages      => $Shedule->{TOTAL},
    header     => [ "$lang{ALL}:index=$index" . $pages_qs, "$lang{ERROR}:index=$index&SHEDULE_DATE=<=$DATE" . $pages_qs ],
    ID         => 'SHEDULE',
    EXPORT     => 1,
    FIELDS_IDS => $Shedule->{COL_NAMES_ARR},
    MENU       => ($FORM{UID}) ? '' : "$lang{ADD}:index=$index&add_form=1:add",
  });

  my ($y, $m, $d) = (0,0,0);

  if($DATE =~ /(\d{4})\-(\d{2})\-(\d{2})/) {
    $y = $1;
    $m = $2;
    $d = $3;
  }

  foreach my $line (@$list) {
    my $delete = ($permissions{4}{3} || $permissions{0}{4})          ? $html->button( $lang{DEL},
        "index=$index&del=$line->{id}" . (($FORM{UID}) ? "&UID=$FORM{UID}" : ''),
        { MESSAGE => "$lang{DEL} [$line->{id}]?", class => 'del' } ) : '-';
    my $value = convert($line->{action}, { text2html => 1 });

    if (! $line->{y}) {
      print "NO YEAR: $line->{id} ";
      next;
    }

    my $shedule_date = ($line->{y} || 2000) . ($line->{m} || '01') . ($line->{d} || 01);
    if ( $line->{y} ne '*'
      && $line->{m} ne '*'
      && $line->{d} ne '*'
      && $shedule_date =~ /^\d+$/ && $shedule_date <= int($y . $m . $d)
      ){
      $table->{rowcolor} = 'bg-danger';
    }
    else {
      $table->{rowcolor} = undef;
    }

    if ($line->{type}) {
      if ($line->{type} eq 'status' && defined($line->{action})) {
        my ($service_id, $action) = split(/:/, $line->{action} || q{});
        $action //= 0;
        $service_id //= '';
        my ($status_value, $color) = split(/:/, $service_status->{$action} || q{});

        $value = $html->color_mark($status_value,
          ($table->{rowcolor} && $table->{rowcolor} eq ($color || q{})) ? '#FFFFFF' : $color) .
          " ($service_id)";
      }
      elsif($line->{type} eq 'tp') {
        my ($service_id, $action) = split(/:/, $line->{action} || q{});
        $action //= q{};
        $value = (($tp_list->{$action}) ? $tp_list->{$action} : $action). " (". ( $service_id || q{}) .") TP_ID: $action";
      }
    }

    $table->addrow($html->b($line->{h}),
      $line->{d},
      $line->{m},
      $line->{y},
      $line->{counts},
      $html->button($line->{login}, "index=15&UID=$line->{uid}"),
      ($TYPES{ $line->{type} }) ? $TYPES{ $line->{type} } : $line->{type},
      $value,
      $line->{module},
      $line->{admin_name},
      $line->{date},
      $line->{comments},
      $delete);
  }
  print $table->show();

  $table = $html->table({
    width      => '100%',
    ID         => 'SHEDULE_',
    rows       => [ [ "$lang{TOTAL}:", $html->b( $Shedule->{TOTAL} ) ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_period($period, $attr)

=cut
#**********************************************************
sub form_period {
  my ($period, $attr) = @_;

  my @periods = ($lang{NOW}, $lang{NEXT_PERIOD}, $lang{DATE});
  my $date_fld = $html->date_fld2('DATE', { FORM_NAME => 'user',
      MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS, NEXT_DAY => 1 });

  my $form_period = "<label class='control-label col-md-3'>$lang{DATE}:</label><div class='col-md-9'>";

  $form_period .= "<div class='text-left'>" . $html->form_input(
    'period', "0",
    {
      TYPE          => "radio",
      STATE         => 1,
      OUTPUT2RETURN => 1
    }
  ) . $periods[0];

  $form_period .= "</div>\n";

  for (my $i = 1 ; $i <= $#periods ; $i++) {
    my $period_name = $periods[$i] || q{};

    $period = $html->form_input(
      'period', $i,
      {
        TYPE          => "radio",
        STATE         => ($i eq $period) ? 1 : undef,
        OUTPUT2RETURN => 1
      }
    );

    if ($i == 1) {
      next if (!$attr->{ABON_DATE});
      $period .= "$period_name  ($attr->{ABON_DATE})";
    }
    elsif ($i == 2) {
      $period .= "$period_name $date_fld";
    }

    $form_period .= "<div class='text-left'>$period</div>\n";
  }

  return $form_period;
}

#**********************************************************
=head2 get_popup_info()

=cut
#**********************************************************
sub get_popup_info {

  if (defined($FORM{NAS_SEARCH})) {
    require Control::Nas_mng;
    form_nas_search();
  }
  elsif(defined($FORM{FEEDBACK})){
    require Control::System;
    form_feedback();
  }

  return 1;
}

#**********************************************************
=head2 form_monitoring($attr) - monitoring quick reports

=cut
#**********************************************************
sub form_monitoring {

  form_start({ SUB_MENU => '_sp_online' });

  return 1;
}

#**********************************************************
=head2 admin_quick_setting() - Admin quick profile configuration

=cut
#**********************************************************
sub admin_quick_setting {

  #Fixme
  # Skip this futures
  #return 1;
  return 1 unless ($html && $html->{TYPE} && $html->{TYPE} eq 'html');
  my $html_content = q{};

  $html->{_RIGHT_MENU} = $html->menu_right("<i class='fa fa-wrench'></i>", "admin_setting", $html_content,
    { SKIN => $admin->{SETTINGS}->{RIGHT_MENU_SKIN} });

  return 1;
}

#**********************************************************
=head2 sel_admins($attr) - Admin select element

  Arguments:
    NAME     - Element name
    SELECTED - value
    REQUIRED - Required options
    HASH     - Hash return
    DISABLE  - 0 = Active; 1 = Disable; 2 = Fired;
    MULTIPLE - multiple admins

  Returns:
    Select element

=cut
#**********************************************************
sub sel_admins {
  my ($attr) = @_;

  my $select_name = $attr->{NAME} || 'AID';

  my $admins_list = $admin->list( {
    GID       => $admin->{GID},
    COLS_NAME => 1,
    DOMAIN_ID => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef,
    PAGE_ROWS => 10000,
    POSITION  => ($attr->{POSITION} ? $attr->{POSITION} : undef),
    DISABLE   => (defined $attr->{DISABLE} ? $attr->{DISABLE} : undef),
  } );

  if($attr->{HASH}) {
    my %admins_hash = ();
    foreach my $line (@$admins_list) {
      $admins_hash{$line->{aid}} = $line->{login};
    }

    return \%admins_hash;
  }

  return $html->form_select($select_name, {
    SELECTED           => $attr->{SELECTED} || $attr->{$select_name} || $FORM{$select_name} || 0,
    SEL_LIST           => $admins_list,
    SEL_KEY            => 'aid',
    SEL_VALUE          => 'name,login',
    NO_ID              => 1,
    SEL_OPTIONS        => { '' => '--' },
    REQUIRED           => ($attr->{REQUIRED}) ? 'required' : undef,
    ID                 => $attr->{ID} ? $attr->{ID} : undef,
    MULTIPLE           => $attr->{MULTIPLE} ? 1 : undef,
    %{($attr->{EX_PARAMS} && ref $attr->{EX_PARAMS} eq 'HASH') ? $attr->{EX_PARAMS} : {}}
  });
}

#**********************************************************
=head2 form_users_search($attr) - Admin select element

=cut
#**********************************************************
sub form_users_search {
  my ($attr)=@_;

  if ($admin->{SETTINGS} && $admin->{SETTINGS}{SEARCH_FIELDS}) {
    @default_search = split(/, /, $admin->{SETTINGS}{SEARCH_FIELDS});
  }

  my $search_string = $attr->{SEARCH_TEXT};
  $search_string=~s/\s+$//;
  $search_string=~s/^\s+//;

  my @qs = ();
  foreach my $field ( @default_search ) {
    $LIST_PARAMS{$field} = "*$search_string*";
    push @qs, "$field=*$search_string*";
  }

  if($attr->{DEBUG}) {
    $users->{debug}=1;
  }

  $users->list({
    %LIST_PARAMS,
    _MULTI_HIT => $search_string,
    UNIVERSAL_SEARCH => $search_string,
  });

  my @info = ();
    if($users->{TOTAL}) {
      push @info, {
        'TOTAL'        => $users->{TOTAL},
        'MODULE'       => '',
        'MODULE_NAME'  => $lang{USERS},
        'SEARCH_INDEX' => 7
          . '&' . "7&search=1&type=10&LOGIN="
          . $attr->{SEARCH_TEXT}
    };
  }

  return \@info;
}


#**********************************************************
=head2 quick_functions($attr) - Quick index functions

=cut
#**********************************************************
sub quick_functions {
  my $xml_start_teg = '';

  if ($FORM{get_index}) {
    $index = get_function_index($FORM{get_index});
    goto FULL_MODE if ($FORM{full});
  }
  else {
    $index = $FORM{qindex};
  }

  if ($FORM{API_INFO}) {
    require Control::Api;
    form_system_info($FORM{API_INFO});
    return 1;
  }
  elsif($FORM{key}) {
    if($conf{US_API}) {
      require Userside::Api;
      userside_api($FORM{request}, \%FORM);
    }
    else {
      print "Content-Type: text/plain\n\n";
      print 'Activate  $conf{US_API}';
    }

    if(! $ENV{DEBUG}) {
      exit;
    }
    return 1;
  }
  elsif(! $index) {
#    my $function_args = '';
#    if(%FORM) {
#      $function_args = join(", ", keys %FORM);
#    }
#    print "Content-Type: text/html\n\n";
#    print "Can't Find function ($admin->{A_LOGIN}) : '$function_args'\n";
    return 1;
  }

  if ($FORM{header}) {
    $html->{METATAGS} = templates('metatags');
    print $html->header(\%FORM);

    if ($FORM{UID} || ($FORM{type} && $FORM{type} == 11 && ! $FORM{xml} && ! $FORM{json} && ! $FORM{csv} && ! $FORM{xls})) {
      $ui = user_info($FORM{UID}, { %FORM, LOGIN => (! $FORM{UID} && $FORM{LOGIN}) ? $FORM{LOGIN} : undef });
      if ($FORM{xml} && $ui && $ui->{UID}) {
        $xml_start_teg = 'user_info';
        print "<$xml_start_teg>";
      }
      elsif($FORM{PHONE}) {
        $xml_start_teg = 'user_info';
        print "<$xml_start_teg>";
      }
    }
    else {
      if ($FORM{xml}) {
        $xml_start_teg = 'info';
        print "<$xml_start_teg>"
      }
    }
  }

  if ($index && $index == -1) {
    $html->{METATAGS} = templates('metatags');
    print $html->header();
    form_purchase_module({ MODULE => $FORM{MODULE} });
    exit;
  }

  if (defined($module{$index})) {
    load_module($module{$index}, $html);
  }

  if(! $ui || ! $ui->{errno}) {
    _function($index, { USER_INFO => $ui });
  }

  print "</$xml_start_teg>" if ($FORM{xml} && $xml_start_teg);

  if ($admin->{FULL_LOG} && $functions{$index} && $functions{$index} ne 'form_events') {
    if($begin_time) {
      $admin->{GT} = gen_time($begin_time);
    }
    $admin->full_log_add({
      FUNCTION_INDEX => $index,
      AID            => $admin->{AID},
      FUNCTION_NAME  => $functions{$index},
      DATETIME       => 'NOW()',
      IP             => $admin->{SESSION_IP},
      SID            => $admin->{SID},
      PARAMS         => ($FORM{__BUFFER} || q{}) . (($admin->{GT}) ? ' '.$admin->{GT} : q{})
    });
  }

  if($html->can('fetch')) {
    $html->fetch({ DEBUG => $ENV{DEBUG} });
  }

  if($ENV{DEBUG}) {
    return 0;
    #die 0;
  }
  else {
    exit;
  }
}

#**********************************************************
=head2 push_actions($attr) - push actions

=cut
#**********************************************************
sub push_actions {
  require Contacts;
  Contacts->import();
  my $Contacts = Contacts->new($db, $admin, \%conf);

  if ($FORM{PUSH_ENABLED}) {
    $Contacts->push_contacts_add({
      TYPE_ID => 1,
      VALUE   => $FORM{TOKEN},
      AID     => $admin->{AID},
    });
  }
  else {
    $Contacts->push_contacts_del({
      TYPE_ID => 1,
      AID     => $admin->{AID},
    });
  }
}

#**********************************************************
=head2 set_admin_params($attr) - Quick index functions

=cut
#**********************************************************
sub set_admin_params {
  push_actions() if (defined $FORM{PUSH_ENABLED});

  if ($FORM{RSCHEMA}) {
    $Conf->config_add({
      PARAM   => 'RSCHEMA_FOR_' . $admin->{AID},
      VALUE   => $FORM{VALUE_RIGHT} || '',
      REPLACE => 1
    });
  }
  if ($FORM{LSCHEMA}) {
    $Conf->config_add({
      PARAM   => 'LSCHEMA_FOR_' . $admin->{AID},
      VALUE   => $FORM{VALUE_LEFT} || '',
      REPLACE => 1
    });
  }
  #Admin Web_options
  if ($FORM{AWEB_OPTIONS}) {
    my %WEB_OPTIONS = (
      language          => 1,
      REFRESH           => 1,
      QUICK_REPORTS_SORT => 1,
      COLORS            => 1,
      PAGE_ROWS         => 1,
      QUICK_REPORTS     => 1,
      NO_EVENT          => 1,
      NO_EVENT_SOUND    => 1,
      SEARCH_FIELDS     => 1,
      SKIN              => 'navbar-white navbar-light',
      BODY_SKIN         => '',
      FIXED             => '',
      MENU_SKIN         => 1,
      RIGHT_MENU_HIDDEN => 0,
      HEADER_FIXED      => 1,
      PUSH_ENABLED      => 0,
    );

    my $web_options = '';

    if (!$FORM{default}) {
      $FORM{QUICK_REPORTS} ||= '' if $FORM{set};
      while (my ($k, undef) = each %WEB_OPTIONS) {
        if ($FORM{$k}) {
          $web_options .= "$k=$FORM{$k};";
        }
        else {
          $web_options .= "$k=$admin->{SETTINGS}{$k};" if ($admin->{SETTINGS}{$k} && ! defined($FORM{$k}));
        }
      }

      if ($admin->{SETTINGS} && $admin->{SETTINGS}{SKIN}) {
        unless ($FORM{SKIN}) {
          $web_options .= "SKIN=$admin->{SETTINGS}{SKIN};";
        }
      }
    }
    else {
      $admin->settings_del();
    }

    if ($FORM{GROUP_ID}){
      require Events;
      my $Events = Events->new($db, $admin, \%conf);
      my $event_groups = $Events->groups_for_admin($admin->{AID}) || '';
      if ($FORM{GROUP_ID} ne $event_groups){
        $Events->admin_group_add({ AID => $admin->{AID}, GROUP_ID => $FORM{GROUP_ID} }, { REPLACE => 1 });
        _error_show($Events);
      }
    }

    if (defined($FORM{quick_set})) {
      my (@qm_arr) = split(/, /, $FORM{qm_item} || q{});
      $web_options .= "qm=";
      foreach my $line (@qm_arr) {
        $web_options .= (defined($FORM{ 'qm_name_' . $line })) ? "$line:" . $FORM{ 'qm_name_' . $line } . "," : "$line:,";
      }
      chop($web_options);
      my $i = 1;
      my $ql = '';
      while ($FORM{"ql_name_$i"} && $FORM{"ql_url_$i"}) {
        $ql .= $FORM{"ql_name_$i"} . "|" . $FORM{"ql_url_$i"} . ",";
        $i++;
      }
      chop($ql);
      $web_options .= ";ql=$ql" if ($ql);
    }
    else {
      $web_options .= ($admin->{SETTINGS} && $admin->{SETTINGS}{qm}) ? "qm=$admin->{SETTINGS}{qm};" : q{};
      $web_options .= ($admin->{SETTINGS} && $admin->{SETTINGS}{ql}) ? "ql=$admin->{SETTINGS}{ql};" : q{};
    }

    $admin->change({ AID => $admin->{AID}, WEB_OPTIONS => $web_options });

    if ($FORM{QUICK}){
      print "Content-Type:text/html\n\n";
      exit;
    }

    print "Location: $SELF_URL?index=$FORM{index}\n\n";
    exit;
  }

  #TODO: need to check, some interesting

  $admin->{SETTINGS}{SKIN} = $admin->{SETTINGS}{SKIN} || 'navbar-white navbar-light';
  $admin->{SETTINGS}{SKIN} = $admin->{SETTINGS}{SKIN} || 'navbar-white navbar-light';
  $admin->{SETTINGS}{RIGHT_MENU_SKIN} = ($admin->{SETTINGS}{MENU_SKIN}) ? 'control-sidebar-light' : 'control-sidebar-dark';
  $admin->{SETTINGS}{FIXED_LAYOUT} = ($admin->{SETTINGS}{FIXED}) ? 'fixed' : '';
  $admin->{MENU_HIDDEN} = (defined($COOKIES{"menuHidden"}) && $COOKIES{menuHidden} eq 'true') ? 'sidebar-collapse' : '';
  $admin->{RIGHT_MENU_OPEN} = ($FORM{UID} && !$admin->{SETTINGS}{RIGHT_MENU_HIDDEN}) ? 'control-sidebar-slide-open' : '';

  if ($admin->{DOMAIN_ID}) {
    $conf{WEB_TITLE} = $admin->{DOMAIN_NAME};
    $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID};
    require Multidoms;
    Multidoms->import();
    my $Domains = Multidoms->new($db, $admin, \%conf);
    my $admin_domains = $Domains->admins_list({ AID => $admin->{AID}, COLS_NAME => 1 });
    if($Domains->{TOTAL}) {
      my @domains_list = ();
      foreach my $line (@$admin_domains) {
        push @domains_list, $line->{domain_id};
      }
      $LIST_PARAMS{DOMAIN_ID} = join(';', @domains_list);
      $admin->{DOMAIN_ID} = $LIST_PARAMS{DOMAIN_ID};
    }
    my @dm_modules = @{$Domains->domain_modules_info({ ID => $admin->{DOMAIN_ID} })};
    if ($#dm_modules > -1) {
      @MODULES = @dm_modules;
    }
  }

  #Domains sel
  if (in_array('Multidoms', \@MODULES) && $permissions{10}) {
    load_module('Multidoms', $html);
    $FORM{DOMAIN_ID}        = $COOKIES{DOMAIN_ID};
    $admin->{DOMAIN_ID}     = $FORM{DOMAIN_ID} if ($FORM{DOMAIN_ID});
    $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} if ($admin->{DOMAIN_ID} && $admin->{DOMAIN_ID} =~ /\d+/);

    $admin->{SEL_DOMAINS} = $html->element('div', $html->form_main(
      {
        class => 'form row justify-content-center align-items-center',
        CONTENT       => $html->element('label', "$lang{DOMAINS}: ", { class => 'mb-0' })
                        . $html->element('div', multidoms_domains_sel(), { class => 'col-md-4 col-8' }),
        HIDDEN        => {
          index      => $index,
          COMPANY_ID => $FORM{COMPANY_ID}
        },
        SUBMIT        => { action => $lang{CHANGE} },
        ID            => 'MULTIDOMS_LIST',
        OUTPUT2RETURN => 1
      }
    ), { class => 'form-group' });
  }

  if ($admin->{GID}) {
    $LIST_PARAMS{GID} = $admin->{GID};
  }

  if ($admin->{MAX_ROWS} && $admin->{MAX_ROWS} > 0) {
    $LIST_PARAMS{PAGE_ROWS} = $admin->{MAX_ROWS};
    $FORM{PAGE_ROWS}        = $admin->{MAX_ROWS};
    $html->{MAX_ROWS}       = $admin->{MAX_ROWS};
  }

  ## Visualisation begin
  $admin->{DATE} = $DATE;
  $admin->{TIME} = $TIME;

  return 1;
}

#**********************************************************
=head2 main_function($function_name) - Make main function

=cut
#**********************************************************
sub main_function {
  my ($function) = @_;

  if (! $function) {
    if (!$index) {
      form_start();
    }
    else {
      $html->message('err', $lang{ERROR}, "Function not exist ($index / $function)", { ID => '003' });
    }

    return 1;
  }

  if (defined($module{$index})) {
    load_module($module{$index}, $html);
  }

  if (($FORM{UID} && $FORM{UID} =~ /^\d+$/ && $FORM{UID} > 0) || ($FORM{LOGIN} && $FORM{LOGIN} ne '' && $FORM{LOGIN} !~ /\*/ && !$FORM{add})) {
    if ($ui && $ui->{TABLE_SHOW}) {
      print $ui->{TABLE_SHOW};
    }

    if ($ui && $ui->{errno} && $ui->{errno} == 2) {
      $html->message('err', $lang{ERROR}, "[$FORM{UID}] $lang{USER_NOT_EXIST}", { ID => '001' });
    }
    elsif ($admin->{GID} && $ui && $ui->{GID} && $admin->{GID} !~ /$ui->{GID}/) {
      $html->message('err', $lang{ERROR},
        "[$FORM{UID}] $lang{USER_NOT_EXIST} GID: $admin->{GID} / " . ($ui->{GID} || '-'), { ID => '002' });
    }
    else {
      _function($index, { USER_INFO => $ui });
    }
  }
  elsif ($index == 0) {
    form_start();
  }
  else {
    _function($index);
  }

  return 1;
}

#**********************************************************
=head2 pre_page() - Page header

=cut
#**********************************************************
sub pre_page {

  if($permissions{8} && $permissions{8}{1}){
    ($admin->{ONLINE_USERS}, $admin->{ONLINE_COUNT}) = $admin->online({
      SID     => $admin->{SID},
      ACTIVE  => 6000,
      TIMEOUT => $conf{web_session_timeout}
    });
    #my $br = $html->br();
    #$admin->{ONLINE_USERS} =~ s/\n/$br/g;
  }
  else{
    $admin->online({ SID => $admin->{SID}, TIMEOUT => $conf{web_session_timeout} });
  }

  if (defined($FORM{index}) && $FORM{index} && $FORM{index} != 7 && !defined($FORM{type})) {
    $FORM{type} = $FORM{index};
  }
  elsif (!defined $FORM{type}) {
    $FORM{type} = 15;
  }

  #Quick Menu
  if ($admin->{SETTINGS} && !$FORM{xml}) {
    form_admin_qm();
  }
  my $global_chat = '';
  if ($conf{MSGS_CHAT}) {
    $global_chat .= $html->tpl_show(templates('msgs_global_chat'), {
      FN_INDEX => get_function_index('header_online_chat'),
      SIDE_ID  => 'aid=' . $admin->{AID},
      SCRIPT   => 'chat_admin_notification.js',

    },
      { OUTPUT2RETURN => 1 });
  }
  my $selected_search_type = ( $SEARCH_TYPES{ $FORM{type} } )
    ? $FORM{type}
    : $conf{DEFAULT_LIVE_SEARCH_TYPE} || 10;

  $admin->{SEL_TYPE} = $html->form_select(
    'type',
    {
      SELECTED => $selected_search_type,
      SEL_HASH => \%SEARCH_TYPES,
      NO_ID    => 1,
      ID       => 'search_type',
      class    => 'form-control input-sm margin search-type-select not-chosen'
    }
  );

  $admin->{SEL_TYPE_SM} = $html->form_select(
    'type',
    {
      SELECTED  => $selected_search_type,
      SEL_HASH  => \%SEARCH_TYPES,
      NO_ID     => 1,
      FORM_ID   => 'SMALL_SEARCH_FORM',
      ID        => 'search_type_small',
      class     => 'form-control margin search-type-select not-chosen',
      EX_PARAMS => 'style="width: 100%"',
    }
  );

  if ($conf{ISP_EXPRESSION} && $admin->{SETTINGS} && $admin->{SETTINGS}->{ql}) {
    my @element_button = split(',', $admin->{SETTINGS}->{ql});
    my @button_info = ();

    foreach my $isp_button (@element_button) {
      my ($key, $value) = split('\|', $isp_button);
      push @button_info, { $key => $value };
    }

    $admin->{ISP_EXPRESSION} = $html->button_isp_express({
      INFO  => \@button_info,
    });
  }

  my $avatar_logo = '';
  if ($admin->{AVATAR_LINK}){
    $avatar_logo = "/images/$admin->{AVATAR_LINK}";
  }
  else {
    $avatar_logo = '/styles/default/img/admin/avatar5.png';
  }

  my $module_name   = ($module{$index}) ? "$module{$index}:" : '';

  print $html->tpl_show(templates('header'), {
    %$admin,
    HEADER_FIXED_CLASS => $admin->{SETTINGS}{HEADER_FIXED} ? 'navbar-fixed-top' : '',
    MENU               => $menu_text,
    BREADCRUMB         => $navigat_menu,
    GLOBAL_CHAT        => $global_chat || '',
    FUNCTION_NAME      => "$module_name$function_name",
    AVATAR_LOGO        => $avatar_logo,
    EVENTS_DISABLED    => !in_array('Events', \@MODULES),
    CONTENT_OFFSET     => $conf{dbdebug} ? '155px' : '94px',
  },
    { OUTPUT2RETURN => 1 });
  return 1;
}

#**********************************************************
=head2 post_page($attr) - Post page information and functions

=cut
#**********************************************************
sub post_page {

  if ($conf{dbdebug} && $admin->{db}->{queries_count}) {
    $admin->{VERSION} .= " q: $admin->{db}->{queries_count} | ";

    if ($admin->{db}->{queries_list} && $permissions{4}{5}) {
      my $output_text = '<textarea class="form-control" rows=28 style="width: 100%">';

      my $i = 0;
      my $query_list = $Conf->{db}->{queries_list};
      my $is_hash = (ref $query_list eq 'HASH');
      my @q_arr = $is_hash ? keys %{$query_list} : @{$query_list};

      foreach my $k (@q_arr) {
        $i++;
        my $is_dbcore_query = ref $k eq 'ARRAY';

        my $text = $is_dbcore_query ? $k->[0] : $k;
        my $time = sprintf("%.5f",
          $is_dbcore_query ? $k->[1] || 0 : 0
        );

        my $count = $is_hash ? " ($query_list->{$k})" : '';
        $output_text .= "$i $count";
        $output_text .= " =================================== $time s\n      $text\n";
      }
      $output_text .= '</textarea>';
      $admin->{FOOTER_DEBUG} .= $html->tpl_show(
        templates('form_show_hide'),
        {
          CONTENT => $output_text,
          NAME    => "$lang{QUERIES}: ".$i,
          ID      => 'QUERIES',
          PARAMS  => 'mx-n1',
          BUTTON_ICON => 'plus'
        },
        { OUTPUT2RETURN => 1 }
      );
    }
  }

  # Check if default password has been changed
  if (!$conf{DEFAULT_PASSWORD_CHANGED}
    && $admin->{AID} == 1
    && $admin->{A_LOGIN} && $admin->{A_LOGIN} eq 'axbills'
    && $html->{TYPE} eq 'html') {

    # Check it's not just an updated version with new password, but without conf variable
    $admin->info(1, { LOGIN => 'axbills', PASSWORD => 'axbills' });

    # $admin->{PASSWORD_MATCH}. Unexpected inverted logic
    # True means password NOT matches.
    # False means this is 'axbills' admin with 'axbills' password
    if (!$admin->{PASSWORD_MATCH}) {
      $html->message('callout', $lang{WARNING}, $html->button($lang{PLEASE_CHANGE_DEFAULT_PASSWORD}, "index=50&subf=54&AID=1"), {
        class => 'danger'
      });
    }
    else {
      $Conf->config_add({ PARAM => 'DEFAULT_PASSWORD_CHANGED', VALUE => 1, REPLACE => 1});
      _error_show($Conf);
      $conf{DEFAULT_PASSWORD_CHANGED} = 1;
    }
  }

  if ($conf{tech_works}) {
    #$admin->{TECHWORK} = $html->message('err', $conf{tech_works}, $conf{tech_works}, { OUTPUT2RETURN => 1 });
    $html->message('callout', $lang{WARNING}, $conf{tech_works}, { class => 'warning' });
  }

  if (!$conf{GUIDE_DISABLED} && $html->{TYPE} eq 'html'){
    if ($FORM{tour_ended}){
      $Conf->config_add({ PARAM => 'ADMIN_HAS_VIEWED_TOUR_' . $admin->{AID}, VALUE => 1, REPLACE => 1});
    }
    elsif(!$conf{'ADMIN_HAS_VIEWED_TOUR_' . $admin->{AID}}){
      $html->tpl_show( templates('interface_guide'));
    }
  }

  if ($begin_time > 0) {
    $conf{VERSION} = get_version();

    my $debug_mode = ($^D) ? "Debug: $^D" : '';
    $admin->{GT}= gen_time($begin_time);
    $admin->{VERSION} .= $conf{VERSION} . " ($admin->{GT}) $debug_mode";
    $admin->{FOOTER_CONTENT} .= $admin->{SEL_DOMAINS} || q{};

    if (defined($permissions{4})) {
      my $output = '';
      if(-f "$conf{TPL_DIR}/NEW_VERSION") {
        my ($ctime) = (stat("$conf{TPL_DIR}/NEW_VERSION"))[10];
        if (time - $ctime < 166000) {
          open(my $fh, '<', "$conf{TPL_DIR}/NEW_VERSION");
          $output = <$fh>;
          close($fh);
        }
      }

      if(! $output && (-w "$conf{TPL_DIR}/NEW_VERSION" || -w $conf{TPL_DIR})) {
        #Get new version
        require AXbills::Fetcher;
        AXbills::Fetcher->import('web_request');
#        $output = web_request('http://billing.axiostv.ru/VERSION', { BODY_ONLY => 1, TIMEOUT => 1, METHOD => 'GET' });
        if (!$output) {
          $output = $conf{VERSION};
        }

        if (open(my $fh, '>', "$conf{TPL_DIR}/NEW_VERSION")) {
          print $fh $output;
          close($fh);
        }
      }

      my ($cur_version, undef) = _extract_number_from_version($conf{VERSION});
      my ($new_version, $new_version_stringed) = _extract_number_from_version($output);

      if ($cur_version && $new_version > $cur_version) {
        $admin->{VERSION} .= $html->button(
          "$lang{NEW_VERSION}: $new_version_stringed",
          "",
          {
            GLOBAL_URL => 'https://billing.axiostv.ru/CHANGELOG',
            class => 'btn btn-xs btn-success ml-1',
            ex_params => ' target=_blank'
          }
        );
      }
    }
  }

  if ($admin->{FULL_LOG}) {
    $admin->full_log_add( {
      FUNCTION_INDEX => $index,
      AID            => $admin->{AID},
      FUNCTION_NAME  => $function_name,
      DATETIME       => 'NOW()',
      IP             => $admin->{SESSION_IP},
      SID            => $admin->{SID},
      PARAMS         => ($FORM{__BUFFER} || q{}) . (($admin->{GT}) ? $admin->{GT} : q{})
    });
  }

  if(! $FORM{xml}) {
    #TODO: rewrite this scary code
    if (defined($admin->{USER_MENU})) {
      $html->{_RIGHT_MENU} = $html->menu_right($html->element('i', '', { class=>'fa fa-user' }), "user_menu", $admin->{USER_MENU},
        { HTML => $html->{_RIGHT_MENU}, TITLE => $lang{USER_INFO}} ) ;
    }
    else {
      $html->{_RIGHT_MENU} = $html->menu_right($html->element('i', '', { class=>'fa fa-th-list' }), "quick_menu", $admin->{QUICK_MENU},
        { HTML => $html->{_RIGHT_MENU}, TITLE  => $lang{QUICK_MENU}} );
    }

    $html->tpl_show(templates('footer'), {
      RIGHT_MENU     => $html->{_RIGHT_MENU},
      VERSION        => $admin->{VERSION},
      FOOTER_DEBUG   => $admin->{FOOTER_DEBUG},
      FOOTER_CONTENT => $admin->{FOOTER_CONTENT},
      PUSH_SCRIPT    => ($conf{PUSH_ENABLED}
        ? "<script src='/styles/default/js/push_subscribe.js'></script>"
        . "<script src='https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js'></script>"
        . "<script src='https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js'></script>"
        . "<script>window['FIREBASE_CONFIG']='" . (AXbills::Base::json_former($conf{FIREBASE_CONFIG}) // '') . "'</script>"
        . "<script>window['FIREBASE_VAPID_KEY']='" . ($conf{FIREBASE_VAPID_KEY} // '') . "'</script>"
        : '<!-- PUSH DISABLED -->'
      )
    });
  }

  $html->test();
  return 1;
}

#**********************************************************
=head2 _status_color_state($status)

  Arguments:
    $status -

  Returns:

=cut
#**********************************************************
sub _status_color_state {
  my ($login_admin, $status_admin) = @_;

  return '' unless ($login_admin);

  my @STATUSES_COLORS = ('text-primary', 'text-danger', 'text-warning');

  $status_admin ||= 0;

  return $html->color_mark($login_admin, $STATUSES_COLORS[ $status_admin ]);
}

#**********************************************************
=head2 _status_color_state($status)

  Arguments:
    $status - with x.xx.xx-like string

  Returns:
    ($number_from_version, $only_version)

=cut
#**********************************************************
sub _extract_number_from_version {
  my ($string) = @_;
  my ($number_probably) = $string =~ /(\d+\.\d+\.\d+)/;
  my $only_version = $number_probably || 0;
  my $number_from_version = $only_version;
  $number_from_version =~ s/\.//;

  return ($number_from_version, $only_version);
}

1;
