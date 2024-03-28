=head1 NAME

  AXbills::Misc - ABillS misc functions

=cut

use strict;
no strict 'vars';
use warnings FATAL => 'all';

# To allow state
use v5.16;

use AXbills::Defs;
use AXbills::Base qw(date_diff mk_unique_value convert in_array
  days_in_month startup_files cmd check_time gen_time
  next_month load_pmodule vars2lang);
use AXbills::Filters;
use POSIX qw(strftime mktime);
our AXbills::HTML $html;
our ($db,
  $admin,
  $base_dir,
  %permissions,
  %menu_args,
  %module,
  %uf_menus,
  %conf,
  %lang,
  %err_strs,
  $DATE,
);

#**********************************************************
=head2 load_module($modulename, $attr); - Load ABillS modules

  Arguments:
    $modulename   - Perl module name
    $attr         - Use $html
      IMPORT      - Make import
      LANG_ONLY   - Load language only
      HEADER      - Add Content-Type header
      SHOW_RETURN - Result to return
      language    - Language (Default: english)
      CONFIG_ONLY
      RELOAD      - Reload module

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub load_module {
  my ($module, $attr) = @_;

  if ($attr->{LOAD_PACKAGE} || $module =~ /\//) {
    my $module_path = $module . '.pm';
    $module_path =~ s{::}{/}g;
    eval { require $module_path };
    $@ ? return 0 : return 1;
  }

  if (!$attr || ($attr && !$attr->{SKIP_LANG})) {
    my $fallback_locale = 'english';
    my $is_fallback = 0;
    if (!$attr->{language}) {
      $attr->{language} = $fallback_locale;
      $is_fallback = 1;
    }

    my $language = $attr->{language};
    $is_fallback = 1 if (!$is_fallback && $language eq $fallback_locale);

    eval { require "$module/lng_$fallback_locale.pl" };
    if (!$is_fallback) {
      eval { require "$module/lng_$language.pl" };
    }

    return 1 if ($attr->{LANG_ONLY});
  }

  if ($attr->{CONFIG_ONLY}) {
    do "$module/config";
    return 1;
  }

  #if($attr->{RELOAD}) {
  #  delete $INC{"$module/webinterface"};
  #}
  eval{ require "$module/webinterface" };
  if ($@) {
    print "Content-Type: text/html\n\n";

    my @error_body = (
      "Error: load module '$module'",
      join(', ', caller()),
      '$!',
      $@,
      '',
      'INC: ',
      @INC
    );

    print join((($html) ? $html->br() : "\n"), @error_body);
    if ($ENV{DEBUG}) {
      exit;
    }

    die;
  }

  return 1;
}

#**********************************************************
=head2 form_purchase_module($attr); - Load commercial modules

  Arguments:
    $attr
      MODULE          - Module name
      REQUIRE_VERSION - Required version
      HEADER          - Add Content-Type header
      SHOW_RETURN     - Result to return
      DEBUG           - Debug mode

=cut
#**********************************************************
sub form_purchase_module {
  my ($attr) = @_;

  my $module = $attr->{MODULE};

  eval { require $module.'.pm'; };

  if (!$@) {
    $module->import();
    my $module_version = $module->VERSION || 0;

    if ($attr->{DEBUG}) {
      if ($attr->{HEADER}) {
        print "Content-Type: text/html\n\n";
      }
      print "Version: $module_version";
    }

    if ($attr->{REQUIRE_VERSION}) {
      if (!$module_version && $html->{NO_PRINT}) {
        if ($attr->{HEADER}) {
          print "Content-Type: text/html\n\n";
        }
      }
      elsif (!$module_version || $module_version < $attr->{REQUIRE_VERSION}) {
        if ($attr->{HEADER}) {
          print "Content-Type: text/html\n\n";
        }

        $html->message('err',
          $lang{SYSTEM_REQUIRES_UPDATE} || "UPDATE",
          vars2lang(
            $lang{PLEASE_UPDATE_MODULE} || "Please update module $attr->{MODULE}",
            {
              MODULE          => $attr->{MODULE},
              REQUIRE_VERSION => $attr->{REQUIRE_VERSION},
              MODULE_VERSION  => $module_version
            }
          )
        );
        return 1;
      }
    }
  }
  else {
    if ($attr->{HEADER}) {
      print "Content-Type: text/html\n\n";
    }

    print "<div class='alert alert-block alert-danger'><p>модуль '$attr->{MODULE}' не установлен в системе, по вопросам приобретения модуля обратитесь к разработчику
    <a href='http://axbills.net.ua' target=_newa>ABillS.net.ua</a>
    </p>
    <p>
    Purchase this module '$attr->{MODULE}'. </p>
    <p>
    For more information visit <a href='http://axbills.net.ua' target=_newa>ABillS.net.ua</a>
    </p>
    </div>";

    if ($attr->{DEBUG} || $FORM{DEBUG}) {
      print "<pre>\n";
      print $@;
      print "</pre>";
    }

    return 1;
  }

  return 0;
}

#**********************************************************
=head2 _error_show($modulename, $attr); - show functions errors

  Arguments:
    $modulename - Module object
    $attr       -
      MODULE_NAME  - Module name
      ID_PREFIX
      MESSAGE
      ERROR_IDS    - Redefined error ids
      ID           - Error number
      SILENT_MODE  - Skip showin sql query for sql request
      RIZE_ERROR   -

  Returns:
    TRUE - Error
    FALSE

=cut
#**********************************************************
sub _error_show {
  my ($module, $attr)=@_;

  my $module_name = $attr->{MODULE_NAME} || $module->{MODULE} || '';

  my $message = '';
  if ($attr->{MESSAGE}) {
    $message = $lang{$attr->{MESSAGE}} || $attr->{MESSAGE};
    $message .= "\n";
  }

  my $errno = $module->{errno};

  if ($errno) {
    if ($attr->{ERROR_IDS}->{$errno}) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . $attr->{ERROR_IDS}->{$errno});
      return 1 if($attr->{RIZE_ERROR});
    }
    elsif ($errno == 15) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . " $lang{ERR_SMALL_DEPOSIT}", $attr);
      return 1 if($attr->{RIZE_ERROR});
    }
    elsif ($errno == 7) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . " $lang{EXIST}", $attr);
      return 1;
    }
    elsif ($errno == 10) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . " $lang{ERR_WRONG_NAME}", $attr);
      return 1;
    }
    elsif ($errno == 12) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . " $lang{ERR_WRONG_SUM}", $attr);
      return 1;
    }
    elsif ($errno == 699) {
      $html->message('err',
        $lang{LICENSE_EXPIRED},
        vars2lang(
          $lang{PLEASE_UPDATE_LICENSE_MODULE},
          { NUMBER => $module->{errstr} || ""}
        ),
      );
      return 1;
    }
    elsif ($errno == 14) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . "$lang{BILLS} $lang{NOT_EXIST}", $attr);
      return 1;
    }
    elsif ($errno == 2) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . $lang{NOT_EXIST}, $attr);
      return 1;
    }
    elsif ($errno == 21) {
      $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_PHONE} . (($conf{PHONE_FORMAT}) ? ' '.human_exp($conf{PHONE_FORMAT}) : q{}), $attr);
      return 1;
    }
    elsif ($errno == 3) {
      my $extra_info = join(', ', caller());
      my $local_module_name = $module_name || $lang{SYSTEM};
      my $sql_errno = ($module->{sql_errno} || $errno || '');
      my $errstr = $html->pre(($module->{sql_errstr} || $module->{errstr} || ''), { OUTPUT2RETURN => 1 });
      my $sql_code = (($module->{sql_query})
        ? $html->pre($module->{sql_query}, { OUTPUT2RETURN => 1 })
        : '');
      my $sql_title = $html->pre("[$sql_errno/$extra_info]", { OUTPUT2RETURN => 1 });

      my $card_title = $message . "SQL Error: [$errno]\n";

      my $extra_template = ($attr->{SILENT_MODE})
        ? " [$module->{sql_errno}] " . $module->{sql_errstr}
        : $html->tpl_show(
            templates('form_show_hide'),
            {
              ID      => 'QUERIES',
              NAME    => $card_title,
              CONTENT => $sql_title
                . $errstr
                . $sql_code,
              BUTTON_ICON => 'plus'
            },
            { OUTPUT2RETURN => 1 }
      );

      $html->message('err',
        "$local_module_name: $lang{ERROR}",
        " ",
        { EXTRA => $extra_template }
      );
      return 1;
    }
    elsif ($errno == 0b1010111011) {
      my $error = join('', pack( 'H*', '0050004c0045004100530045005f005500500044004100540045005f004c004900430045004e00530045'));
      $html->message('warn', $lang{$error});
      return 1;
    }
    else {
      if($module->{message}) {
        $html->message('err', "$module_name:$lang{ERROR}",
          ($lang{$module->{message}}) ? $lang{$module->{message}} : $module->{message},
          { ID => $attr->{ID} || $module->{errno} });
      }
      else {
        my $error = ($err_strs{$errno}) ? $err_strs{$errno} : ($module->{errstr} || q{});
        $html->message('err', "$module_name:$lang{ERROR}", $message . "[$errno] $error", { ID => $attr->{ID} });
      }
      return 1;
    }
  }

  return 0;
}

#**********************************************************
=head2 _message_show($attr); - show message

  Arguments:
    $attr -
      message_title
      message
      message_type
      error || ID - error number

  Returns:
    TRUE - Error
    FALSE

=cut
#**********************************************************
sub _message_show {
  my ($attr) = @_;

  return 0 if !$attr->{message};

  my $message_title = $attr->{message_title} || $lang{INFO};
  $message_title = _translate($message_title);
  my $message = _translate($attr->{message});
  my $message_type = $attr->{message_type} || 'info';

  $html->message($message_type, $message_title, $message, { ID => $attr->{ID} || $attr->{error} });

  return 1;
}

#**********************************************************
=head2 _function($index, $attr); - Exec function by index

  Arguments:
    $index         - Function index
    $attr
      IF_EXIST     - Run only if exists function
      ALL          - Show full log for errors
      DEBUG        - Debug mode

=cut
#**********************************************************
sub _function {
  my($index, $attr) = @_;

  if ($attr->{IF_EXIST} && $attr->{FN_NAME}) {
    my $fn = $attr->{FN_NAME};
    if (! defined(&{ $fn })) {
      return '';
    }

    return eval { &{ \&$fn }($attr) };
  }

  if ($FORM{qrcode}) {
    require Control::Qrcode;
    Control::Qrcode->import();

    my $qrcode_url = $FORM{QRCODE_URL} || $SELF_URL;
    my $QRCode = Control::Qrcode->new($db, $admin, \%conf, { html => $html, functions => \%functions });
    $QRCode->qr_make($qrcode_url, \%FORM);

    print $@ if ($@);
    return 1;
  }

  my $function_name = $functions{ $index } || '';

  if (! $function_name) {
    print "Content-type: text/html\n\n";
    if ($index !~ /^\d+$/) {
      print 'ERROR: Wrong function index. Function not exist!';
    }
    else {
      print 'ERROR: Function index: ' . ($index || q{}) . ' Function not exist!';
    }
    return 0;
  }
  elsif ($function_name eq 'null') { #if menu element's function is 'null', print page with menu subelements of this menu element
    my @info_buttons = ();
    foreach my $key (sort keys %menu_items) {
      next if (!defined($menu_items{$key}{$index}) || $menu_items{$key}{$index} eq '' || $key == 10); #10 - logout

      my $ext_args = '';
      my $skip_this_key = 0;
      if (defined($menu_args{$key}) && $menu_args{$key} ne 'defaultindex') {
        my @menu_args_list = ($menu_args{$key});
        if ($menu_args{$key} =~ /,/) {
          @menu_args_list = split(',', $menu_args{$key});
        }

        foreach my $menu_arg (@menu_args_list) {
          if ($menu_arg =~ /=/) {
            $ext_args .= "&$menu_arg";
          }
          elsif (defined $FORM{$menu_arg}) {
            $ext_args .= "&$menu_arg=$FORM{$menu_arg}";
          }
          else {
            $skip_this_key = 1;
            last;
          }
        }
      }

      if ($skip_this_key) {
        next;
      }

      push @info_buttons, {
        ID     => mk_unique_value( 10 ),
        NUMBER => $html->button( $menu_items{$key}{$index}, "index=$key$ext_args", { class => 'd-block' }),
        SIZE   => 4
      };
    }

    $html->short_info_panels_row(\@info_buttons, {MENU_BUTTONS => 1});
    return 1;
  }
  elsif(! defined( &{ $function_name } )) {
    print "Content-Type: text/html\n\n";
    print "function: '". $function_name ."' defined in config but not exists\n\n";
    if (defined($module{$index})) {
      print "Module: $module{$index} ";
    }
    print join(',', caller) . "\n";
    exit;
  }

  eval {
    # Will show stacktrace on fail, but can be not installed
    require Carp::Always;
  };
  my @returns = eval { &{ \&$function_name }($attr) };

  if($@) {
    my $inputs = '';

    $attr->{ALL}=1;
    if ($attr->{ALL}) {
      $inputs = "\nFORM ========================\n";
      foreach my $key (sort keys %FORM) {
        next if ($key eq '__BUFFER');
        $inputs .= "$key -> ". ($FORM{$key} || '') ."\n";
      }

      $inputs = "\nCOOKIES ========================\n";
      foreach my $key (sort keys %COOKIES) {
        next if ($key eq '__BUFFER');
        $inputs .= "$key -> ". ($FORM{$key} || '') ."\n";
      }
    }

    print "Content-Type: text/html\n\n";
    if(! $conf{SYS_ID}) {
      system_info();
    }

    my $sys_id = $conf{SYS_ID} || '';

    my $version = get_version();
    print << "[END]";
<form action='https://support.axbills.net.ua/bugs.cgi' method='post'>
<input type=hidden name='FN_INDEX' value='$index'>
<input type=hidden name='FN_NAME' value='$function_name'>
<input type=hidden name='INPUTS' value='$inputs'>
<input type=hidden name='SYS_ID' value='$sys_id'>
<input type=hidden name='CUR_VERSION' value='$version'>

<div class='card card-outline card-danger container'>
  <div class='card-header'>
    <h4 class='card-title'>$lang{ERROR}</h4>
  </div>
  <div class='card-body'>
<div class='form-group'>
<textarea class='form-control' cols=80 rows=10 NAME=ERROR>
[END]

 if($@) {
   print $@;
 }

print << "[END]";
$inputs
</textarea>
</div>
<div class='form-group'>
  <input class='form-control' type=text name='COMMENTS' value='' placeholder='$lang{HOW_TO_REPRODUCE}' size=80>
</div>
<div class='form-group form-check'>
  <input id='NOTIFY' class='form-check-input' type=checkbox name='NOTIFY' value=1>
  <label for='NOTIFY' class='form-check-label'>$lang{NOTIFY_AFTER_FIX}</label>
</div>
<div class='form-group'>
  <input class='form-control' type=text name='NOTIFY_EMAIL' value='' placeholder='E-mail' size=80>
</div>
</div>
<div class='card-footer'>
  <input type=submit name='add' value='$lang{SEND_TO_DEVELOPERS}' class='btn btn-danger'>
</div>
  </div>
</form>
[END]

    my $caller = q{}; #join(', ', caller());
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash);
    my $i = 0;
    my @r = ();
    while (@r = caller($i)) {
      ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @r;
      $caller .= "$filename:$line $subroutine\n";
      $i++;
    }

    die "Error functionm execute: '$function_name' $! // \nCaller: "
      . $caller ."\n"
      .(($@) ? $@ : q{});
  }

  return @returns;
}

#**********************************************************
=head2 cross_modules($function_suffix, $attr) - Calls function for all registration modules if function exist

  Arguments:
    $function_suffix - Function suffix
    $attr           - Extra attributes
      SILENT       - silent mode without output (Default: enable)
      SKIP_MODULES - Skip modules
      timeout      - Max timeout for function execute (Default: 4 sec)
      DEBUG        - Debug mode
      USER_INFO    - User information hash
      HTML         - $html object
      FORM         - Form info

  Return:
    return all modules return hash

  Example:

    cross_modules('payments_maked', {
        USER_INFO    => $user,
        SUM          => $sum,
        PAYMENT_ID   => $payments->{PAYMENT_ID},
        SKIP_MODULES => 'Paysys,Sqlcmd',
        FORM         => \%FORM
    });

=cut
#**********************************************************
sub cross_modules {
  my ($function_index, $attr) = @_;
  my $timeout = $attr->{timeout} || 4;
  my $debug = $attr->{DEBUG} || 0;

  $html = $attr->{HTML} if $attr->{HTML};
  # if ($function_index && $function_index eq 'payments_maked') {
  #   require Control::Services;
  # }

  if ($attr->{SUM} && ! $attr->{USER_INFO}{PAYMENTS_ADDED}) {
    $attr->{USER_INFO}->{DEPOSIT} += $attr->{SUM};
    $attr->{USER_INFO}->{PAYMENTS_ADDED}=1;
  }

  my @users_uids = ();
  if ($attr->{USER_INFO}{COMPANY_ID}) {
    if ($users && $users->can('list')) {
      my $users_list = $users->list({ COMPANY_ID => $attr->{USER_INFO}{COMPANY_ID}, COLS_NAME => 1 });
      foreach my $user_info (@{$users_list}) {
        push @users_uids, $user_info->{uid};
      }
    }
  }
  else {
    push @users_uids, $attr->{USER_INFO}{UID} || $attr->{UID};
  }

  my $modules_dir = ($base_dir || '/usr/axbills/') . 'AXbills/modules/';
  my $silent = defined $attr->{SILENT} ? $attr->{SILENT} : 0;
  my %full_return = ();
  my $check_time = 0;
  my @skip_modules = ();
  my $SAVEOUT;
  my $output_redirect = '/dev/null';
  if ($attr->{SKIP_MODULES}) {
    $attr->{SKIP_MODULES} =~ s/\s+//g;
    @skip_modules = split(/,/, $attr->{SKIP_MODULES});
  }

  my $user_count = 0;               #FIXME: Problem 1 Part 1
  foreach my $uid (@users_uids) {
    $user_count++;
    $attr->{USER_INFO}{UID} = $uid;

    if ($debug) {
      print "Function:  ". ($function_index || q{}) ." Timout: $timeout Silent: " . ($silent || 'no') . "<br>\n";
      $check_time = check_time();
    }

    eval {
      if ($silent) {
        if ($conf{CROSS_MODULES_DEBUG}) {
          $output_redirect = $conf{CROSS_MODULES_DEBUG};
        }

        #disable stdout output
        open($SAVEOUT, ">&", \*STDOUT) or die "Save STDOUT: $!";
        #Reset out
        open STDIN, '>', '/dev/null';
        open STDOUT, '>>', $output_redirect;
        open STDERR, '>>', $output_redirect;
      }

      if ($user_count > 1) {              # problem: multiple sending checks to server
        push @skip_modules, 'Extreceipt'; #FIXME: Problem 1 Part 3
      }

      if ($silent) {
        local $SIG{ALRM} = sub {die "alarm\n"}; # NB: \n required
        alarm $timeout;
      }

      foreach my $module (@MODULES) {
        next if (in_array($module, \@skip_modules));

        my $module_path = $modules_dir . $module . '/Base.pm';
        next if !(-f $module_path);

        my $module_name = $module . '::Base';
        eval "use $module_name;";
        next if $@;
        if ($attr->{DEBUG}) {
          print " $module -> " . lc($module) .'_' . $function_index . "<br>\n";
        }

        my $function = lc $module . '_' . $function_index;

        next unless ($module_name->can('new'));
        next unless ($module_name->can($function));

        load_module($module, { %{$html || {}}, LANG_ONLY => 1 });

        eval {
          my $module_api = $module_name->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });
          $full_return{$module} = $module_api->$function($attr);
        };

        next if $@;

        if ($attr->{DEBUG} && $check_time) {
          print gen_time($check_time) . " <br>\n ";
          $check_time = check_time();
        }
      }
    };

    if ($silent && $SAVEOUT) {
      # off disable stdout output
      open(STDOUT, ">&", $SAVEOUT);
    }
  }

  if ($@) {
    print "Error: \n";
    print $@;
  }

  return \%full_return;
}

#**********************************************************
=head2 get_function_index($function_name, $attr) - Get function index

  Arguments:
    $function_name   - Function name
    $attr
      ARGS   - Extra arguments
        empty - show only with empty argv

  Returns:
    function index

=cut
#**********************************************************
sub get_function_index {
  my ($function_name, $attr) = @_;
  my $function_index = 0;

  if(! $function_name) {
    return 0;
  }

  state $index_cache = {};
  if ($function_name && $index_cache->{$function_name}){
    return $index_cache->{$function_name};
  };

  foreach my $k (sort keys (%functions)) {
    my $v = $functions{$k};
    if ($v && $v eq $function_name && $k =~ /^\d+$/) {
      $function_index = $k;
      if ($attr->{ARGS} && defined($menu_args{$k})) {
        if ($attr->{ARGS} eq 'empty' && $menu_args{$k} eq '') {
        }
        elsif ($attr->{ARGS} ne $menu_args{$k}) {
          next;
        }
      }
      elsif(! $attr->{ARGS} && defined($menu_args{$k}) ) {
        next;
      }

      last;
    }
  }

  return $function_index || 0;
}

#**********************************************************
=head2 fees_dsc_former($attr) - Make fees describe

  Arguments:
    $attr
      SERVICE_NAME       - Service name
      TEMPLATE_KEY_NAME  - name for %conf key (INTERNET_FEES_DSC)
      TEMPLATE           - Template

  Results:
    $formed_string

=cut
#**********************************************************
sub fees_dsc_former {
  my ($attr) = @_;

  my $template_key_name = $attr->{TEMPLATE_KEY_NAME} || 'INTERNET_FEES_DSC';

  if (!defined($attr->{SERVICE_NAME})) {
    $attr->{SERVICE_NAME} = 'Internet';
  }

  my $text = '%SERVICE_NAME%: %FEES_PERIOD_MONTH%%FEES_PERIOD_DAY% %TP_NAME% (%TP_ID%)%ID%%EXTRA%%PERIOD%';

  if($conf{$template_key_name}) {
    $text = $conf{$template_key_name}
  }
  elsif($attr->{TEMPLATE}) {
    $text = $attr->{TEMPLATE};
  }

  while ($text =~ /\%(\w+)\%/g) {
    my $var = $1;
    if (!defined($attr->{$var})) {
      $attr->{$var} = '';
    }
    $text =~ s/\%$var\%/$attr->{$var}/g;
  }

  while ($text =~ /\$lang\{([A-Z_]+)\}/) {
    my $lang_name = $1;
    if ($lang_name && defined $lang{$lang_name}) {
      $text =~ s/\$lang\{$lang_name\}/$lang{$lang_name}/;
    }
  }

  return $text;
}

#**********************************************************
=head2 service_recalculate($Service, $attr) - Make month feee

  Arguments:
    $Service - Module object
    $attr
      SERVICE_NAME - Service name
      DATE         - date of fees
      SHEDULER     - execute from sheduler
      EXT_DESCRIBE - Extra decribe
      QUITE        - Quite mode
      MODULE       - Caller module
      DEBUG

    Extra config option:

     $conf{INTERNET_CURDATE_ACTIVATE}=1; - Activate non payment service by cur date
     $conf{INTERNET_PAY_ACTIVATE}=1; - Activate non payment service by cur date

  Returns:
    total_sum
      Hash of results
         [ ACTIVATE  => 0 ]
         [ MONTH_FEE => 0 ]

      @{ $Service->{FEES_ID} }

=cut
#**********************************************************
sub service_recalculate {
  my ($Service, $attr) = @_;

  my $rest_days     = 0;
  my $debug         = $attr->{DEBUG} || 0;
  my $rest_day_sum2 = 0;
  my $return_sum    = 0;
  my $message       = '';
  my $date          = $attr->{DATE} || $DATE;
  my $tp            = $Service->{TP_INFO};
  my $Payments      = Finance->payments($Service->{db}, $admin, \%conf);
  my $Users         = $attr->{USER_INFO};
  my $days_in_month = days_in_month({ DATE => $date });
  my (undef, undef, $d)   = split(/-/, $date, 3);
  my $service_activate = $Service->{ACTIVATE} || $Users->{ACTIVATE} || '0000-00-00';
  my $start_day = $conf{START_PERIOD_DAY} || 1;

  # my %total_sum = (
  #   ACTIVATE  => 0,
  #   MONTH_FEE => 0
  # );

  if ($debug) {
    print join("\b", caller());
    print "$Service->{TP_INFO_OLD}->{MONTH_FEE} (". ( $Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION} || q{} ) .") => $tp->{MONTH_FEE} SHEDULE: ".
      ( $attr->{SHEDULER} || 0 ) ."\n";
  }

  if (($attr->{SHEDULER} && $start_day == $d)
    || ($Service->{TP_INFO_OLD}->{MONTH_FEE} && $Service->{TP_INFO_OLD}->{MONTH_FEE} == ($tp->{MONTH_FEE} || 0)
    && $Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION} <  $Service->{TP_INFO}->{ABON_DISTRIBUTION})) {
    #if ($attr->{SHEDULER}) {
    undef $user;
    #}

    return 0;
    #return \%total_sum;
  }

  if ($service_activate eq '0000-00-00') {
    if ($d != $start_day) {
      $rest_days     = $days_in_month - $d + 1;
      $rest_day_sum2 = (! $Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION} && $Service->{TP_INFO_OLD}->{MONTH_FEE}) ? $Service->{TP_INFO_OLD}->{MONTH_FEE} /  $days_in_month * $rest_days : 0;
      $return_sum    = $rest_day_sum2;
      #PERIOD_ALIGNMENT
      $tp->{PERIOD_ALIGNMENT}=1;
    }
    # Get back full month abon in 1 day of month
    elsif (! $Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION}) {
      if (! $attr->{SHEDULER}) {
        $return_sum = $Service->{TP_INFO_OLD}->{MONTH_FEE};
      }
    }
  }
  else {
    if ( $attr->{SHEDULER} && date_diff($service_activate, $date) >= 31 ) {
      #if ($attr->{SHEDULER}) {
      undef $user;
      #}

      #return \%total_sum;
      return 0;
    }
    elsif (! $attr->{SHEDULER} && date_diff($service_activate, $date) < 31) {
      $rest_days     = 30 - date_diff($service_activate, $date);
      if($Service->{TP_INFO_OLD}->{MONTH_FEE}) {
        $rest_day_sum2 = (!$Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION} && $rest_days > 0) ? $Service->{TP_INFO_OLD}->{MONTH_FEE} / 30 * $rest_days : 0;
      }
      else {
        $rest_day_sum2 = 0;
      }
      $return_sum = $rest_day_sum2;
    }
  }

  if ($Users->{REDUCTION} && $Users->{REDUCTION} > 0 && $Service->{TP_INFO_OLD}->{REDUCTION_FEE}) {
    $return_sum = $return_sum * (100 - $Users->{REDUCTION}) / 100;
  }

  #Compensation
  if (defined($return_sum) && $return_sum > 0) {
    $Payments->add($Users, {
      SUM      => abs($return_sum),
      METHOD   => 8,
      DESCRIBE => "$lang{TARIF_PLAN}: $Service->{TP_INFO_OLD}->{NAME} (".
        ($Service->{TP_INFO_OLD}->{TP_ID} || $Service->{TP_INFO_OLD}->{ID} || q{-}) .") ($lang{DAYS}: $rest_days)",
    });

    if ($Payments->{errno}) {
      _error_show($Payments) if (!$attr->{QUITE});
    }
    else {
      $message .= "$lang{RECALCULATE}\n$lang{RETURNED}: ". sprintf("%.2f", abs($return_sum))."\n" if (!$attr->{QUITE});
    }
    return $message || 1;
  }

  return 1;
}


#**********************************************************
=head2 service_get_month_fee($Service, $attr) - Make month feee

  Arguments:
    $Service - Module object
    $attr
      SERVICE_NAME - Service name
      DATE         - date of fees
      SHEDULER     - execute from sheduler
      EXT_DESCRIBE - Extra decribe
      QUITE        - Quite mode
      MODULE       - Caller module
      USER_INFO    - User object
      DEBUG

    Extra config option:

     $conf{INTERNET_CURDATE_ACTIVATE}=1; - Activate non payment service by cur date
     $conf{INTERNET_PAY_ACTIVATE}=1; - Activate non payment service by cur date

  Returns:
    total_sum
      Hash of results
         [ ACTIVATE  => 0 ]
         [ MONTH_FEE => 0 ]

      @{ $Service->{FEES_ID} }

=cut
#**********************************************************
sub service_get_month_fee {
  my ($Service, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  require Finance;
  Finance->import();
  my $Fees  = Finance->fees($Service->{db}, $admin, \%conf);
  my $Users = Users->new($Service->{db}, $admin, \%conf);

  $conf{START_PERIOD_DAY} = 1 if (!$conf{START_PERIOD_DAY});
  $DATE=$attr->{DATE} if ($attr->{DATE});
  delete $Service->{FEES_ID};

  my %total_sum = (
    ACTIVATE  => 0,
    MONTH_FEE => 0
  );

  my $service_name = $attr->{SERVICE_NAME} || 'Internet';
  my $module       = $attr->{MODULE} || 'Internet';
  my $tp           = $Service->{TP_INFO};
  my $uid          = $Service->{UID} || 0;
  if ($attr->{USER_INFO} && ref($attr->{USER_INFO}) eq 'Users') {
    $Users = $attr->{USER_INFO};
  }
  else {
    $Users = $user if ($user && $user->{UID} && !$attr->{DO_NOT_USE_GLOBAL_USER_PLS});
    if (!$Users->{BILL_ID}) {
      $user = $Users->info($uid);
    }

    $attr->{USER_INFO} = $Users;
    if ($conf{CROSS_DEBUG}) {
      my $caller = join(', ', caller());
      `echo "$caller" >> /tmp/cross_debug`;
    }
  }
  my $service_activate = $Service->{ACTIVATE} || $Users->{ACTIVATE} || '0000-00-00';

  #Get active price
  if ($tp->{ACTIV_PRICE} && $tp->{ACTIV_PRICE} > 0) {
    my $date  = ($service_activate ne '0000-00-00') ? $service_activate : $DATE;
    my $time  = ($service_activate ne '0000-00-00') ? '00:00:00' : $TIME;

    if (!$Service->{OLD_STATUS} || $Service->{OLD_STATUS} == 2) {
      $Fees->take(
        $Users,
        $tp->{ACTIV_PRICE},
        {
          DESCRIBE => '$lang{ACTIVATE_TARIF_PLAN}',
          DATE     => "$date $time"
        }
      );
      $total_sum{ACTIVATE} = $tp->{ACTIV_PRICE};
      $html->message('info', $lang{INFO}, "$lang{ACTIVATE_TARIF_PLAN}") if ($html && ! $attr->{QUITE});

      if($Fees->{FEES_ID}) {
        push @{$Service->{FEES_ID}}, $Fees->{FEES_ID};
      }
    }
  }

  my $message = '';
  #Current Month
  my ($y, $m, $d)   = split(/-/, $DATE, 3);
  my $days_in_month = days_in_month({ DATE => $DATE });

  my $TIME = "00:00:00";
  my %FEES_PARAMS = (
    DATE   => "$DATE $TIME",
    METHOD => ($tp->{FEES_METHOD}) ? $tp->{FEES_METHOD} : 1,
    EXT_BILL_METHOD => ($tp->{EXT_BILL_FEES_METHOD}) ? $tp->{EXT_BILL_FEES_METHOD} : undef,
  );

  if($Service->{PERSONAL_TP} && $Service->{PERSONAL_TP} > 0) {
    $tp->{MONTH_FEE}=$Service->{PERSONAL_TP};
    $Service->{TP_INFO_OLD}->{MONTH_FEE}=$Service->{PERSONAL_TP};
    $tp->{NAME} = $lang{PERSONAL_TP} || 'PERSONAL_TP';
  }

  if ($attr->{SHEDULER} && ($service_activate ne '0000-00-00' || $tp->{ABON_DISTRIBUTION})) {
    undef $user;
    return \%total_sum;
  }

  if (($tp->{MONTH_FEE} && $tp->{MONTH_FEE} > 0) ||
    ($Service->{TP_INFO_OLD}->{MONTH_FEE} && $Service->{TP_INFO_OLD}->{MONTH_FEE} > 0)
  ) {

    #Get back month fee
    if ( $FORM{RECALCULATE} || $attr->{RECALCULATE}) {
      #print "\n".join("\n", caller()). "\n";
      my $result = service_recalculate($Service, $attr);
      if (! $result) {
        return \%total_sum;
      }
      $message = $result if ($result ne 1);
    }

    my $sum   = $tp->{MONTH_FEE} || 0;

    if ($tp->{EXT_BILL_ACCOUNT}) {
      if ($Users->{EXT_BILL_ID}) {
        if (!$conf{BONUS_EXT_FUNCTIONS} || ($conf{BONUS_EXT_FUNCTIONS} && $Users->{EXT_BILL_DEPOSIT} > 0)) {
          $Users->{MAIN_BILL_ID} = $Users->{BILL_ID};
          $Users->{BILL_ID}      = $Users->{EXT_BILL_ID};
        }
      }
    }

    my %FEES_DSC = (
      SERVICE_NAME    => $service_name,
      MODULE          => $module . ':',
      TP_ID           => $tp->{TP_ID},
      TP_NAME         => $tp->{NAME} || '',
      FEES_PERIOD_DAY => $lang{MONTH_FEE_SHORT},
      FEES_METHOD     => ($tp->{FEES_METHOD} && $FEES_METHODS{$tp->{FEES_METHOD}}) ? $FEES_METHODS{$tp->{FEES_METHOD}} : 0,
      ID              => ($Service->{ID}) ? ' '. $Service->{ID} : undef
    );

    my $account_activate = $Service->{ACCOUNT_ACTIVATE} || $service_activate || '0000-00-00';
    my ($active_y, $active_m, $active_d) = split(/-/, $account_activate, 3);

    if (int("$y$m$d") < int("$active_y$active_m$active_d")) {
      if ($attr->{SHEDULER}) {
        undef $user;
      }

      return \%total_sum if (! $attr->{REGISTRATION} );
    }

    if($attr->{FULL_MONTH_FEE}) {

    }
    elsif ($tp->{PERIOD_ALIGNMENT} && !$tp->{ABON_DISTRIBUTION}) {
      $FEES_DSC{EXTRA} = " $lang{MONTH_ALIGNMENT},";

      if ($account_activate ne '0000-00-00') {
        $days_in_month = days_in_month({ DATE => "$active_y-$active_m" });
        $d = $active_d;
      }

      my $calculation_days = ($d < $conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} - $d : $days_in_month - $d + $conf{START_PERIOD_DAY};
      $sum = sprintf("%.2f", ($sum / $days_in_month) * $calculation_days);
    }

    if ($sum == 0) {
      if ($attr->{SHEDULER}) {
        undef $user;
      }

      $html->message('info', $lang{INFO}, $message) if ($html && !$attr->{QUITE});
      return \%total_sum
    }

    my $periods = 0;
    if (int($active_m) > 0 && int($active_m) < $m && int($active_y) < int($y)) {
      $periods = $m - $active_m;
      if (int($active_d) > int($d)) {
        $periods--;
      }

      $periods += 12 * ($y - $active_y) - 12 if ($y - $active_y);
    }
    elsif (int($active_m) > 0 && (int($active_m) >= int($m) && int($active_y) < int($y))) {
      $periods = 12 - $active_m + $m;
      if (int($active_d) > int($d)) {
        $periods--;
      }
      $periods += 12 * ($y - $active_y) - 12 if ($y - $active_y);
    }
    elsif ($tp->{FIXED_FEES_DAY} && int($active_d) <= int($d) && (int($active_m) != int($m) && int($active_y) == int($y))) {
      $periods=1;
    }

    #Make reduction
    if ($Users->{REDUCTION} && $Users->{REDUCTION} > 0 && $tp->{REDUCTION_FEE}) {
      $sum = $sum * (100 - $Users->{REDUCTION}) / 100;
    }

    if ($tp->{ABON_DISTRIBUTION}) {
      $sum = $sum / (($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($y % 400) || !($y % 4) && ($y % 25) ? 29 : 28)));
      $FEES_DSC{EXTRA} = " - $lang{ABON_DISTRIBUTION}";
    }

    if ($account_activate ne '0000-00-00') {
      if ($Service->{OLD_STATUS} && $Service->{OLD_STATUS} == 5) {
        if ( $conf{INTERNET_PAY_ACTIVATE} ){
          $periods = 0;
        }
        #if activation in cure month curmonth
        elsif ( $periods == 0 || ($periods == 1 && $d < $active_d && $active_m == $m) ){
          $periods = -1;
        }
        else{
          $periods -= 1;
        }
      }
      #Skip previe month calculations disable / hold up
      elsif( in_array($Service->{OLD_STATUS}, [1,3]) )  {
        $periods = 0;
      }
    }

    $m = $active_m if ($active_m > 0);

    for (my $i = 0 ; $i <= $periods ; $i++) {
      if ($m > 12) {
        $m = 1;
        $active_y = $active_y + 1;
      }

      $m = sprintf("%.2d", $m);

      $days_in_month = days_in_month({ DATE => "$active_y-$m" });
      if ($i > 0) {
        $FEES_DSC{EXTRA} = '';
        $message = '';
        if ($Users->{REDUCTION} > 0 && $tp->{REDUCTION_FEE}) {
          $sum = $tp->{MONTH_FEE} * (100 - $Users->{REDUCTION}) / 100;
        }
        else {
          $sum = $tp->{MONTH_FEE};
        }

        if ($account_activate) {
          $DATE = $account_activate;
          my $end_period = POSIX::strftime('%Y-%m-%d',
            localtime((POSIX::mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 30 * 86400)));
          $FEES_DSC{PERIOD} = "($active_y-$m-$active_d-$end_period)";
          if(in_array('Internet', \@MODULES)) {
            my $change_function = '';
            #@Fixme
            if($Service->can('change')) {
              $change_function = 'change';
            }
            elsif($Service->can('user_change')) {
              $change_function = 'user_change';
            }

            if($change_function) {
              $Service->$change_function({
                ACTIVATE => $DATE,
                UID      => $uid,
                ID       => $Service->{ID}
              });
            }
          }
          else {
            $Users->change(
              $uid,
              {
                ACTIVATE => $DATE,
                UID      => $uid
              }
            );
          }

          $account_activate = POSIX::strftime('%Y-%m-%d',
            localtime((POSIX::mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 31 * 86400)));
        }
        else {
          $DATE = "$active_y-$m-01";
          $FEES_DSC{PERIOD} = "($active_y-$m-01-$active_y-$m-$days_in_month)";
        }
      }
      elsif ($account_activate ne '0000-00-00') {
        my $end_period = POSIX::strftime('%Y-%m-%d',
          localtime((POSIX::mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 30 * 86400)));

        if($tp->{FIXED_FEES_DAY}) {
          $account_activate = next_month({ DATE => "$active_y-$m-$active_d", DAY => $active_d });
        }
        else {
          $account_activate = ($tp->{PERIOD_ALIGNMENT}) ? undef : POSIX::strftime('%Y-%m-%d',
            localtime((POSIX::mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 31 * 86400)));
        }

        if ($tp->{PERIOD_ALIGNMENT}) {
          if(in_array('Internet', \@MODULES)) {
            my $change_function = '';
            if($Service->can('change')) {
              $change_function = 'change';
            }
            elsif($Service->can('user_change')) {
              $change_function = 'user_change';
            }
            if($change_function) {
              $Service->$change_function({
                ACTIVATE => '0000-00-00', #$DATE,
                UID      => $uid,
                ID       => $Service->{ID}
              });
            }
          }
          else {
            $Users->change(
              $uid,
              {
                ACTIVATE => '0000-00-00',
                UID      => $uid
              }
            );
          }
          $end_period = "$y-$m-$days_in_month";
        }
        # old status "Too small deposit"
        elsif ($Service->{OLD_STATUS} && $Service->{OLD_STATUS} == 5) {
          if(in_array('Internet', \@MODULES)) {
            $Service->user_change({
              ACTIVATE => $DATE,
              UID      => $uid,
              ID       => $Service->{ID}
            });
          }
          else {
            $Users->change(
              $uid,
              {
                ACTIVATE => ($conf{INTERNET_PAY_ACTIVATE}) ? $DATE : $account_activate,
                UID      => $uid
              }
            );
          }

          if ($conf{INTERNET_PAY_ACTIVATE}) {
            ($active_y, $active_m, $active_d) = split(/-/, $DATE);
            $end_period = POSIX::strftime('%Y-%m-%d',
              localtime((POSIX::mktime(0, 0, 0, $active_d, ($active_m - 1), ($active_y - 1900), 0, 0,
                0) + 30 * 86400)));
            $m = $active_m;
          }
          else {
            ($active_y, $active_m, $active_d) = split(/-/, $account_activate);
            $end_period = POSIX::strftime('%Y-%m-%d',
              localtime((POSIX::mktime(0, 0, 0, $active_d, ($active_m - 1), ($active_y - 1900), 0, 0,
                0) + 30 * 86400)));
            $m = $active_m;
          }
        }
        else {
          $DATE = "$active_y-$m-$active_d";
          if (in_array($Service->{OLD_STATUS}, [ 1, 3 ])) {
            $DATE = strftime("%Y-%m-%d", localtime(time));
            if(in_array('Internet', \@MODULES)) {
              $Service->user_change({
                ACTIVATE => $DATE,
                UID      => $uid,
                ID       => $Service->{ID}
              });
            }
            else {
              $Users->change(
                $uid,
                {
                  ACTIVATE => $DATE,
                  UID      => $uid
                }
              );
            }
          }
        }

        $FEES_DSC{PERIOD} = "($active_y-$m-$active_d-$end_period)" if(! $tp->{ABON_DISTRIBUTION});
      }
      else {
        $days_in_month = days_in_month({ DATE => "$y-$m" });
        my $start_date = ($tp->{PERIOD_ALIGNMENT}) ? (($account_activate ne '0000-00-00') ? $account_activate : $DATE) : "$y-$m-01";
        $FEES_DSC{PERIOD} = ($tp->{ABON_DISTRIBUTION}) ? '' : "($start_date-$y-$m-$days_in_month)";
      }

      $FEES_PARAMS{DESCRIBE} = fees_dsc_former(\%FEES_DSC);
      $FEES_PARAMS{DESCRIBE} .= $attr->{EXT_DESCRIBE} if ($attr->{EXT_DESCRIBE});
      $message .= $FEES_PARAMS{DESCRIBE};

      if ($debug > 1) {
        print "SUM: $sum DESCRIBE: $FEES_PARAMS{DESCRIBE}\n";
      }

      if ($debug < 6) {
        if ($conf{EXT_BILL_ACCOUNT} && ! $conf{FEES_PRIORITY}) {
          if ($Users->{EXT_BILL_DEPOSIT} && $Users->{EXT_BILL_DEPOSIT} < $sum && $Users->{MAIN_BILL_ID}) {
            $sum = $sum - $Users->{EXT_BILL_DEPOSIT};
            $Fees->take($Users, $Users->{EXT_BILL_DEPOSIT}, \%FEES_PARAMS);
            $Users->{BILL_ID} = $Users->{MAIN_BILL_ID};
            $Users->{MAIN_BILL_ID} = undef;

            if($Fees->{FEES_ID}) {
              push @{$Service->{FEES_ID}}, $Fees->{FEES_ID};
            }
          }
        }

        if ($sum > 0) {
          $Fees->take($Users, $sum, \%FEES_PARAMS);
          $total_sum{MONTH_FEE} += $sum;
          if ($Fees->{errno}) {
            _error_show($Fees) if (!$attr->{QUITE});
          }
          else {
            $html->message('info', $lang{INFO},
              $message."\n $lang{SUM}: ".sprintf("%.2f", $sum)) if ($html && !$attr->{QUITE});

            if($Fees->{FEES_ID}) {
              push @{$Service->{FEES_ID}}, $Fees->{FEES_ID};
            }
          }
        }
      }

      $m++;
    }
  }

  # if($conf{INTERNET_CUSTOM_PERIOD}) {
  #   #print $tp->{ACTIV_PRICE};
  #   #$tp->{CHANGE_PRICE}=1;
  # }

  if($debug < 6) {
    my $external_cmd = '_EXTERNAL_CMD';
    $external_cmd = uc($module).$external_cmd;
    if ($conf{$external_cmd}) {
      if (!_external($conf{$external_cmd}, { %FORM, %$Users, %$Service, %$attr })) {
        print "Error: external cmd '$conf{$external_cmd}'\n";
      }
    }
  }

  #Undef ?
  if ($attr->{SHEDULER}) {
    undef $user;
  }

  return \%total_sum;
}

#**********************************************************
=head2 _external($file, $attr); - Make external operations

  Arguments:
    $file     - File for executions
    $attr     - Extra arguments
      QUITE
      EXTERNAL_CMD

  Returns:
    1 - Susccess
    0 - Error

=cut
#**********************************************************
sub _external {
  my ($file, $attr) = @_;

  if ($attr->{EXTERNAL_CMD}) {
    my $external_cmd = '_EXTERNAL_CMD';
    $external_cmd = uc($attr->{EXTERNAL_CMD}).$external_cmd;

    if ($conf{$external_cmd}) {
      $file = $conf{$external_cmd};
    }
    else {
      return 1;
    }
  }

  my $result = cmd($file, {
    ARGV    => 1,
    PARAMS  => $attr,
    timeout => $conf{EXTERNAL_CMD_TIMEOUT} || 5
  });
  my $error = $!;
  my ($num, $message) = split(/:/, $result, 2);
  # 1 - ok
  if ($num && $num =~ /^\d+$/ && $num == 1) {
    $html->message('info', "EXTERNAL $lang{ADDED}", $message) if (!$attr->{QUITE});
    return 1;
  }
  else {
    $html->message('err', "EXTERNAL $lang{ERROR}", "[". ($num || '') ."] ". ($message || q{}) ." ERROR: ". ($error || q{})) if (!$attr->{QUITE});
    return 0;
  }
}


#**********************************************************
=head2 get_fees_types($attr)

  Arguments:
    $attr
      SHORT - Short info

  Returns:
    \%FEES_METHODS

=cut
#**********************************************************
sub get_fees_types {
  my ($attr) = @_;

  require Finance;
  Finance->import();

  my %FEES_METHODS = ();

  my $Fees         = Finance->fees($db, $admin, \%conf);
  my $list         = $Fees->fees_type_list({ PAGE_ROWS => 10000, COLS_NAME => 1 });

  foreach my $line (@$list) {
    if ($FORM{METHOD} && $FORM{METHOD} == $line->{id}) {
      $FORM{SUM}      = $line->{sum} if ($line->{sum} && $line->{sum} > 0);
      $FORM{DESCRIBE} = $line->{default_describe} if ($line->{default_describe});
    }
    my $sum_show = ($line->{sum} && $line->{sum} > 0) ? ($attr->{SHORT}) ? ":$line->{sum}" : " ($lang{SERVICE} $lang{PRICE}: $line->{sum})" : q{};

    $FEES_METHODS{ $line->{id} } = (($line->{name} && $line->{name} =~ /\$/) ? _translate($line->{name}) : ($line->{name} || '')) . $sum_show;
  }

  return \%FEES_METHODS;
}


#**********************************************************
=head2 get_payment_methods($attr)

  Arguments:
    $attr
      EXTRA_METHODS = Coma separated string

  Returns:
    \%PAYMENTS_METHODS

=cut
#**********************************************************
sub get_payment_methods {
  my %PAYMENTS_METHODS = ();

  require Payments;
  Payments->import();
  my $Payments = Payments->new($db, $admin, \%conf);
  my $payment_list = $Payments->payment_type_list({
    COLS_NAME => 1,
    SORT      => 'id',
  });

  _error_show($Payments) and return 0;

  foreach my $type (@$payment_list) {
    $PAYMENTS_METHODS{$type->{id}} = _translate($type->{name});
  }

  return \%PAYMENTS_METHODS;
}

#**********************************************************
=head2 _translate($text) - translate string

  Arguments:
    $text   - text for translate
  Returns:
      translated string

=cut
#**********************************************************
sub _translate {
  my ($text) = @_;

  return '' unless $text;

  if ( $text =~ /\"/ ){
    return $text;
  }
  #elsif($text =~ /\$lang\{(\S+)\}/) {
  else {
    while($text =~ /\$lang\{(\S+)\}/g) {
      my $marker = $1;
      if($lang{$marker}) {
        $text =~ s/\$lang\{$marker\}/$lang{$marker}/;
      }
    }
  }

  #OLD STYLE LANG variables
  # while( $text =~ m/\$\_?([A-Z0-9\_]+)/g ) {
  #   my $text_marker = $1;
  #   if ($lang{$text_marker}) {
  #     $text =~ s/\$\_?$text_marker/$lang{$text_marker}/g;
  #   }
  # }

  my $text2 = $text;
  while( $text2 =~ m/(\%?)([A-Z0-9\_]+)/g ) {
    if ($1 eq '%') {
      next;
    }
    my $text_marker = $2;

    if ($lang{$text_marker}) {
      $text =~ s/$text_marker/$lang{$text_marker}/g;
    }
  }

  return $text || q{};
}

#**********************************************************
=head2 _translate_list($list, @name_keys)

  Arguments:
    $list      - list of vars to translate
    @name_keys - array of hash keys to translate. default : (name)

  Returns:
    translated list

=cut
#**********************************************************
sub translate_list {
  my ($list, @name_keys) = @_;

  $name_keys[0] //= 'name';

  foreach my $line (@$list){
    foreach ( @name_keys ) {
      $line->{$_} = _translate($line->{$_}) if ($line->{$_});
    }
  }

  return $list;
}

#**********************************************************
=head2 get_oui_info($mac); - Get MAC information
  Arguments:
    $mac - mac

  Returns:
    vendor string
=cut
#**********************************************************
sub get_oui_info {
  my ($mac) = @_;

  my $result = '';
  $mac =~ s/[\-:\.]//g;
  $mac = uc($mac);
  $mac =~ /^([0-9A-F]{6})/;
  my $mac_prefix = $1;
  return '' unless ($mac_prefix);

  my $content = '';
  open(my $fh, '<', "$base_dir/misc/oui.txt") or die "Can't open file 'oui.txt' $!";
  while(<$fh>) {
    $content .= $_;
  }
  close($fh);

  my @content_arr = split(/\n\r?\n\r?/, $content);
  my %vendors_hash = ();
  foreach my $section (@content_arr) {
    my @rows = split(/\n/, $section);
    if ($#rows > 0){
      $rows[1] =~ /([A-F0-9]{6})\s+\(base 16\)\s+(.+)/;
      my $db_mac_prefix = $1;
      my $vendor_info = $2;
      $vendors_hash{$db_mac_prefix} = $vendor_info;
    }
  }

  $result = $vendors_hash{$mac_prefix} || '';

  return $result;
}

#**********************************************************
=head2 host_diagnostic($ip, $attr); - Diagnostic host activity

  Diagnostic methods:
    ping (Default)
  Arguments:
    IP      - IP address of host
    QUITE   - Quite mode
    TIMEOUT - Timeout
    $attr   -
  Return:
    Active or disable  (TRUE or FALSE)

=cut
#**********************************************************
sub host_diagnostic {
  my($ip, $attr) = @_;
  #my $timeout  = $attr->{TIMEOUT} || 3;

  if ($ip && $ip =~ /^$IPV4$/){
    my $pathes = startup_files( { TPL_DIR => $conf{TPL_DIR} } );
    my $PING = $pathes->{PING} || 'ping';

    my $res = cmd( "$PING -c 5 $ip", { timeout => 11 } );
    if ( !$attr->{QUITE} ){
      $html->message( 'info', $lang{INFO}, "$PING -c 5 $ip\nResult:\n" .
        $html->pre( $res, { OUTPUT2RETURN => 1 } ) );
    }

    if($attr->{RETURN_RESULT}){
      return $res ne '' ? 1 : 0;
    }
  }
  else {
    $html->message('err', $lang{ERROR}, ($lang{WRONG_DATA} || q{}) ."'". (($ip) ? $ip : '') . "' ($IPV4)");
  }

  return 1;
}

#**********************************************************
=head2 file_op($attr) File operations

  Secure file operation function, with warnings

  Arguments:

    FILENAME   - Filename
    PATH       - File folder (Default path $conf{TPL_DIR})
    WRITE      - Enable write mode (Default: 0 - read mode)
    CREATE     - Create file if not exists skip if exists
    CONTENT    - file content for writing
    SKIP_CHECK - Skip checking file exist for read mode
    SKIP_COMMENTS - Skip commenct reg expr
    ROWS       - After reading return array of rows for text file only
    QUIET      - Quite mode
      Error codes
        -1 Not found
        -2 No such files
        -3 Access denied
        -4 other error

  Returns:
    File content for reading
    TRUE OR FALSE for wrinting

  Examples:

open image file and print content

    print file_op({
      FILENAME => "$conf{TPL_DIR}/if_image/image_file.jpg",
      PATH     => "$conf{TPL_DIR}/if_image"
    });

=cut
#**********************************************************
sub file_op {
  my ($attr) = @_;
  my $content = '';

  my $filename = $attr->{FILENAME} || 'unknown';
  my $path     = $attr->{PATH} || '';
  #my $write    = $attr->{WRITE} || '';

  if (! $path) {
    $path=$filename;
    if ($path !~ s@[/\\][^/\\]+$@@) {
      $path = '.';
    }

    if ($path eq $conf{TPL_DIR}) {
      $filename =~ s/$path\/?//;
    }
  }
  else {
    $filename =~ s/$path\/?//;
  }
  if ($filename !~ /^([-\@\w\.]{0,12}\/?[-\@\w\.]+)$/) {
    $html->message('err', $lang{ERROR}, "Security error '$filename'.\n");
    return 0;
  }

  $filename = $path .'/'. $filename;

  if ($attr->{WRITE}) {
    if ($attr->{CREATE} && -f $filename) {
      $html->message('err', $lang{ERROR}, "$lang{EXIST} '$filename' \n $!");
      return 0;
    }

    $content = $attr->{CONTENT} || '';
    if (open(my $fh, '>', "$filename")) {
      print $fh $content;
      close($fh);
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} '$filename'") if ($html);
    }
    else {
      $html->message('err', $lang{ERROR}, "Can't open file '$filename'\n $!") if ($html);
      return 0;
    }
  }
  else {
    if (! -f $filename) {
      if (! $attr->{SKIP_CHECK}) {
        if(! $attr->{QUIET}) {
          $html->message('err', $lang{ERROR}, "$lang{NOT_EXIST} '$filename' \n $!") if ($html);
        }
        else {
          $content = '-1';
        }
      }
    }
    elsif (open(my $fh, '<', "$filename")) {
      while (<$fh>) {
        if($attr->{SKIP_COMMENTS} && /$attr->{SKIP_COMMENTS}/) {
          next;
        }

        $content .= $_;
      }
      close($fh);

      if ($attr->{ROWS}) {
        my @rows = split(/[\r\n]+/, $content);
        return \@rows;
      }
    }
    else {
      if(! $attr->{QUIET}) {
        $html->message('err', $lang{ERROR}, "Can't open file '$filename' $!");
      }
      else {
        return '-1';
      }

      return ;
    }
  }

  return $content;
}

#**********************************************************
=head2 upload_file($file, $attr) - Upload file to server

  Attributes:
    $file      - HTML file field object
    $attr      - Attributes
       PREFIX                   - Upload folder (Defauls: $conf{TPL_DIR})
       SAFE_FILENAME_CHARACTERS - Check file symbols
       FILE_NAME                - Filename for saving
       EXTENTIONS               - Allow extensions (String - comma separated)
       REWRITE                  - Allow rewrite file

  Retursn:
    TRUE or FALSE

  Examples:
    upload_file($FORM{FILENAME}, { EXTENTIONS => '' });

=cut
#**********************************************************
sub upload_file {
  my ($file, $attr) = @_;

  my $safe_filename_characters = ($attr->{SAFE_FILENAME_CHARACTERS}) ? $attr->{SAFE_FILENAME_CHARACTERS} : "a-zA-Z0-9_.-";
  my $file_name = ($attr->{FILE_NAME}) ? $attr->{FILE_NAME} : $file->{filename};

  if(! $file_name) {
    $html->message('err', $lang{ERROR}, "Select upload file");
    return 0;
  }

  $file_name =~ tr/ /_/;
  $file_name =~ s/[^$safe_filename_characters]//g;

  if ($attr->{EXTENTIONS}) {
    my @ext_arr = split(/,\s?/, $attr->{EXTENTIONS});
    if ($file_name =~ /\.([a-z0-9\_]+)$/i) {
      my $file_extension = $1;
      if (! in_array($file_extension, \@ext_arr)) {
        $html->message('err', $lang{ERROR}, "$lang{ERROR} Wrong extension\n $lang{FILE}: '$file_name'");
        return 0;
      }
    }
    else {
      $html->message('err', $lang{ERROR}, "$lang{ERROR} Wrong filename\n $lang{FILE}: '$file_name'");
      return 0;
    }
  }

  my $dir = ($attr->{PREFIX}) ? "$conf{TPL_DIR}/" . $attr->{PREFIX} : $conf{TPL_DIR};

  if (!-d $dir) {
    if(! mkdir($dir)) {
      $html->message('err', $lang{ERROR}, "$lang{ERROR} '$dir'  '$!'");
      return 0;
    }
  }

  if (!$attr->{REWRITE} && -f "$dir/$file_name") {
    $html->message('err', $lang{ERROR}, "$lang{EXIST} '$file_name'");
  }
  elsif(! $file->{Contents}) {
    $html->message('err', $lang{ERROR}, "NO_CONTENT'");
    return 0;
  }
  elsif (open( my $fh, '>', "$dir/$file_name")) {
    binmode $fh;
    print $fh $file->{Contents};
    close($fh);
    $html->message('info', $lang{INFO}, "$lang{ADDED}: '$file_name'. $lang{SIZE}: $file->{Size} b");
  }
  else {
    $html->message('err', $lang{ERROR}, "$lang{ERROR} '$dir/$file_name'  '$!'");
    return 0;
  }

  return 1;
}

#**********************************************************
=head2 sel_groups($attr) - show select user group

  Attributes:
    $attr
      GID
      HASH_RESULT      - Return results as hash
      SKIP_MULTISELECT - Skip multiselect
      FILTER_SEL       - Select for reports (filter)

  Returns:
    GID select form

=cut
#**********************************************************
sub sel_groups {
  my ($attr) = @_;

  my $GROUPS_SEL = '';
  if ($admin->{GID} && $admin->{GID} !~ /,/) {
    $users->group_info($admin->{GID});
    $GROUPS_SEL = "$admin->{GID}:$users->{NAME}";
    $GROUPS_SEL .= $html->form_input('GID', $admin->{GID}, { TYPE => 'hidden' });

    if($attr->{HASH_RESULT}) {
      my %group_hash = ();
      $group_hash{$admin->{GID}} = $users->{NAME};
      return \%group_hash;
    }
  }
  elsif($attr->{HASH_RESULT}) {
    my %group_hash = ();
    my $list = $users->groups_list({
      GIDS            => ($admin->{GID}) ? $admin->{GID} : undef,
      GID             => '_SHOW',
      NAME            => '_SHOW',
      DESCR           => '_SHOW',
      ALLOW_CREDIT    => '_SHOW',
      DISABLE_PAYSYS  => '_SHOW',
      DISABLE_CHG_TP  => '_SHOW',
      USERS_COUNT     => '_SHOW',
      COLS_NAME       => 1,
    });
    foreach my $line (@$list) {
      $group_hash{$line->{gid}} = "($line->{gid}) $line->{name}";
    }

    return \%group_hash;
  }
  else {
    my $gid = $attr->{GID} || $FORM{GID};
    my %PARAMS = (
      SELECTED  => $gid,
      SEL_LIST  => $users->groups_list({
        GID            => '_SHOW',
        NAME           => '_SHOW',
        DESCR          => '_SHOW',
        ALLOW_CREDIT   => '_SHOW',
        DISABLE_PAYSYS => '_SHOW',
        DISABLE_CHG_TP => '_SHOW',
        USERS_COUNT    => '_SHOW',
        GIDS           => ($admin->{GID}) ? $admin->{GID} : undef,
        DOMAIN_ID      => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef,
        COLS_NAME      => 1
      }),
      SEL_KEY   => 'gid',
      SEL_VALUE => 'name',
      EX_PARAMS => $attr->{MULTISELECT} ? 'multiple="multiple"' : $attr->{EX_PARAMS},
      ID        => $attr->{ID}
    );

    if ($attr->{FILTER_SEL}) {
      $PARAMS{SEL_OPTIONS} = ($admin->{GID}) ? undef : { '*' => "$lang{ALL}", '0' => "$lang{WITHOUT_GROUP}" };
      $PARAMS{MULTIPLE}    = 1;
    }
    else {
      $PARAMS{SEL_OPTIONS} = ($admin->{GID}) ? undef : { '' => "$lang{ALL}", '0' => "$lang{WITHOUT_GROUP}" };
      $PARAMS{MAIN_MENU}      = get_function_index('form_groups');
      $PARAMS{MAIN_MENU_ARGV} = $gid ? "GID=$gid" : '';
    }
    $GROUPS_SEL = $html->form_select('GID', \%PARAMS);
  }

  return $GROUPS_SEL;
}

#**********************************************************
=head2 sel_status($attr) - show select user group
  Attributes:
    $attr
      STATUS       - Status ID
      HASH_RESULT  - Return results as hash
      NAME         - Select element name
      COLORS       - Status colors
      ALL          - Show all item

  Returns:
    GID select form

=cut
#**********************************************************
sub sel_status {
  my ($attr, $select_params) = @_;

  my $select_name = $attr->{NAME} || 'STATUS';

  require Service;
  Service->import();
  my $Service = Service->new($db, $admin, \%conf);
  my $list = $Service->status_list({ NAME => '_SHOW', COLOR => '_SHOW', COLS_NAME => 1 });
  my %hash  = ();
  my @style = ();

  foreach my $line (@$list) {
    my $color = $line->{color} || '';
    $hash{$line->{id}} = ((exists $line->{name}) ? _translate($line->{name}) : '');

    if (!$attr->{SKIP_COLORS}) {
      $hash{$line->{id}} .= ":$color" if $attr->{HASH_RESULT};
      $style[$line->{id}] = '#'.$color;
    }
  }

  my $SERVICE_SEL = '';
  if ($attr->{COLORS}) {
    return \@style;
  }
  elsif($attr->{HASH_RESULT}) {
    return \%hash;
  }
  else {
    my $status_id = (defined($attr->{$select_name})) ? $attr->{$select_name} : $FORM{$select_name};

    $SERVICE_SEL = $html->form_select(
      $select_name,
      {
        SELECTED       => $status_id,
        SEL_HASH       => \%hash,
        STYLE          => \@style,
        SORT_KEY_NUM   => 1,
        NO_ID          => 1,
        SEL_OPTIONS    => ($attr->{ALL}) ? { '' => "$lang{ALL}" } : undef,
        EX_PARAMS      => $attr->{EX_PARAMS},
        #MAIN_MENU      => get_function_index('form_status'),
        #MAIN_MENU_ARGV => "chg=$status_id"
        %{($select_params) ? $select_params : {}}
      }
    );
  }

  return $SERVICE_SEL;
}

#**********************************************************
=head2 import_show($attr) - Show import date

  Arguments:
    $attr
      DATA  - Import data aray_of_hash
      COLS_NAMES

  Returns:
    True or False

=cut
#**********************************************************
sub import_show {
  my($attr) = @_;

  my @cols_names = ();
  my @import_data = @{ $attr->{DATA} };

  if( $#import_data < 0 ) {
    print "NO_IMPORT_DATE";
  }

  if($attr->{COLS_NAMES}) {
    @cols_names = @{$attr->{COLS_NAMES}};
  }
  else {
    @cols_names = keys %{ $import_data[0] };
  }

  my @result_rows = ();
  foreach my $line (@import_data) {
    my @table_cols = ();
    if (ref $line eq 'HASH') {
      @cols_names = sort keys %$line;
      foreach my $col ( @cols_names ) {
        push @table_cols, ($line->{$col} || '-');
      }
    }
    else {
      for (my $i = 0; $i <= $#cols_names; $i++) {
        my $col = $cols_names[$i];
        push @table_cols, $line->{$col} || '-';
      }
    }
    push @result_rows, \@table_cols;
  }

  my $table = $html->table({
    width   => '100%',
    caption => $lang{IMPORT},
    title   => \@cols_names,
    ID      => 'STORAGE_ID',
    rows    => \@result_rows
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 import_former($attr) - Multi address form

  Arguments:
    UPLOAD_FILE
    IMPORT_DELIMITER
    IMPORT_FIELDS
    IMPORT_TYPE
       CSV
       XML
       JSON
       TAB
    UPLOAD_PRE
    ENCODE

  Results:
    \@import_data_hash

=cut
#**********************************************************
sub import_former {
  my ($attr) = @_;

  my @import_data = ();

  my %file_ext = (
    csv  => '.csv',
    JSON => '.json',
    TAB  => '.txt'
  );

  my $import_type = $attr->{IMPORT_TYPE} || q{};
  my $filename = $attr->{UPLOAD_FILE}{filename} || q{};
  my @cols_names  = split(/,\s?/, $attr->{IMPORT_FIELDS});

  if ($file_ext{$import_type} && $filename !~ /$file_ext{$import_type}$/i) {
    $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_FILE_NAME}: $attr->{UPLOAD_FILE}{filename}");
    return [];
  }

  if($import_type eq 'JSON') {
    load_pmodule('JSON');
    my $json = JSON->new->allow_nonref;

    my $perl_scalar;
    eval { $perl_scalar = $json->decode( $attr->{UPLOAD_FILE}{Contents} );  };

    if ( $@ ) {
      $html->message('err', $lang{ERROR}, "Json Error". $html->pre($@));
    }

    if($perl_scalar->{DATA_1}) {
      if (ref($perl_scalar->{DATA_1}) eq 'ARRAY') {
        foreach my $info_line (@{ $perl_scalar->{DATA_1} }) {
          push @import_data, $info_line;
        }
      }
      else {
        foreach my $info_line (@{ $perl_scalar->{DATA_1} }) {
          foreach my $key ( keys %$info_line ) {
            $info_line->{ uc($key) } = $info_line->{$key};
            delete( $info_line->{$key} );
          }
          push @import_data, $info_line;
        }
      }
    }
  }
  else {
    if ($import_type eq 'csv') {
      $attr->{IMPORT_DELIMITER} = ',';
    }

    my $delimiter = $attr->{IMPORT_DELIMITER} || "\t+";
    my @rows = split(/[\r\n]+/, $attr->{UPLOAD_FILE}{Contents});

    my %user_info = ();
    foreach my $line (@rows) {
      next if (!$line || $line =~ /^\s+$/);
      if ($attr->{ENCODE}) {
        $line = convert($line, { $attr->{ENCODE} => 1 });
      }

      my @cols = split(/$delimiter/, $line);
      %user_info = ();

      for (my $i = 0; $i <= $#cols; $i++) {
        my $key = ($cols_names[$i]) ? $cols_names[$i] : $i;
        $user_info{ $key } = $cols[$i];
      }

      $user_info{ 'MAIN_ID' } = $cols_names[0];
      push @import_data, { %user_info };
    }
  }

  if ($attr->{UPLOAD_PRE}) {
    import_show({
      DATA       => \@import_data,
      COLS_NAMES => \@cols_names
    });
    @import_data = ();
  }

  return \@import_data;
}

#**********************************************************
=head2 mk_menu($menu) - Multi address form

  Arguments:
    $menu
    $attr
      USER_FUNCTION_LIST
      CUSTOM
      EXTRA_MENU

  Results:

=cut
#**********************************************************
sub mk_menu {
  my($menu, $attr) = @_;

  my $maxnumber=0;

  foreach my $line (@{ $menu }) {
    my ($ID, $PARENT, $NAME, $FUNTION_NAME, $ARGS, $module_name) = split(/:/, $line);
    $menu_items{$ID}{$PARENT || 0} = $NAME;
    $menu_names{$ID} = $NAME;
    $functions{$ID}  = $FUNTION_NAME if ($FUNTION_NAME );
    $menu_args{$ID}  = $ARGS         if (defined($ARGS) && $ARGS ne '');
    $maxnumber       = $ID           if (! defined($maxnumber) || $maxnumber < $ID);
    $module{$ID}     = $module_name  if ($module_name);
  }

  if($attr->{CUSTOM}) {
    if($attr->{EXTRA_MENU}) {
      foreach my $extra_menu ( @{ $attr->{EXTRA_MENU} } ) {
        foreach my $mod ( keys %{ $extra_menu  } ) {
          $maxnumber = mk_menu_extra($extra_menu->{$mod}, $maxnumber, $mod);
        }
      }
    }

    return 1;
  }
  #Add modules
  foreach my $mod (@MODULES) {
    next if ($admin->{MODULES} && !$admin->{MODULES}{$mod});
    load_module($mod, { %$html, CONFIG_ONLY => 1, SKIP_LANG => $attr->{SKIP_LANG} || 0 });

    if ($attr->{USER_FUNCTION_LIST}){
      $maxnumber = mk_menu_extra(\%USER_FUNCTION_LIST, $maxnumber, $mod);
    }
    else {
      $maxnumber = mk_menu_extra(\%FUNCTIONS_LIST, $maxnumber, $mod);
    }

    %USER_FUNCTION_LIST = ();
    %FUNCTIONS_LIST = ();
  }

  return 1;
}

#**********************************************************
=head2 mk_menu_extra($module_menu, $maxnumber, $module)

=cut
#**********************************************************
sub mk_menu_extra {
  my ($module_menu, $maxnumber, $module) = @_;

  my @sordet_module_menu = sort keys %$module_menu;

  my $default_index=0;
  my %module_fl = ();

  foreach my $menu_line (@sordet_module_menu) {
    $maxnumber++;
    my ($ID, $SUB, $NAME, $FUNTION_NAME, $ARGS) = split(/:/, $menu_line, 5);
    $ID = int($ID);
    my $main_menu_id = $module_menu->{$menu_line};

    $module_fl{$ID} = $maxnumber;

    if($lang{$NAME}) {
      $NAME = $lang{$NAME};
    }

    if ($ARGS) {
      if ($index < 1 && $ARGS eq 'defaultindex') {
        $default_index = $maxnumber;
        $index         = $default_index;
      }
      elsif ($ARGS ne 'defaultindex') {
        $menu_args{$maxnumber} = $ARGS;
      }

      $menu_args{$maxnumber} = $ARGS;
    }
    if ($SUB > 0) {
      my $sub_id = $module_fl{$SUB} || 0;
      $menu_items{$maxnumber}{ $sub_id } = $NAME;
    }
    else {
      $menu_items{$maxnumber}{$main_menu_id} = $NAME;
      if ($SUB == -1) {
        $uf_menus{$maxnumber} = $NAME;
      }
    }

    $menu_names{$maxnumber} = $NAME;
    $functions{$maxnumber}  = $FUNTION_NAME if ($FUNTION_NAME ne '');
    $module{$maxnumber}     = $module;
  }

  return $maxnumber;
}


#**********************************************************
=head2 custom_menu($attr)

=cut
#**********************************************************
sub custom_menu {
  my ($attr) = @_;

  my $tpl_name = $attr->{TPL_NAME} || 'admin_menu';
  my @menu = ();

  my $menu_content = templates($tpl_name);

  if ( $html && $html->{TYPE} && !$html->{TYPE} eq 'html' ) {
    $menu_content = $html->tpl_show($menu_content, {}, {
      ID            => $tpl_name,
      SKIP_ERRORS   => 1,
      OUTPUT2RETURN => 1
    });
  }

  if ( !$menu_content ) {
    return \@menu;
  }

  my @rows = split(/\n/, $menu_content);

  foreach my $line ( @rows ) {
    $line =~ s/^[\s\r]+//g;
    if ( $line =~ /^#/
      || $line =~ /^\s{0,100}$/
      || $line =~ /^</ ) {
      next;
    }
    push @menu, $line;
  }

  return \@menu;
}

#**********************************************************
=head2 get_version();

  get billing version

=cut
#**********************************************************
sub get_version {

  my $version = '';
  $base_dir //= '/usr/axbills/';

  if (-f $base_dir.'/VERSION') {
    if (open(my $fh, '<', $base_dir."/VERSION")) {
      $version = <$fh>;
      close($fh);
    }
  }

  chomp($version);

  return $version;
}

#**********************************************************
=head2 system_info();


=cut
#**********************************************************
sub system_info {

  if (! $conf{SYS_ID}) {
    $conf{SYS_ID} = mk_unique_value(32);
    load_pmodule('Digest::MD5');
    if(! $@) {
      my $md5 = Digest::MD5->new();
      $md5->add( $conf{SYS_ID} );
      $conf{SYS_ID} = $md5->hexdigest();
    }

    if(ref $Conf eq 'Conf' && $Conf->can('config_add')) {
      $Conf->config_add({
        PARAM => 'SYS_ID',
        VALUE => $conf{SYS_ID} || q{}
      });
    }
  }

  my $version     = get_version();
  my $request_url = 'http://axbills.net.ua/misc/update.php';
  my @info        = ('users', 'nas', 'tarif_plans', 'admins');
  my @info_data   = ();

  foreach my $key ( @info  ) {
    $admin->query( "SELECT count(*) FROM `$key`;" );
    push @info_data, ($admin->{list}->[0]->[0] || 0);
  }

  require AXbills::Fetcher;
  AXbills::Fetcher->import('web_request');
  web_request($request_url, {
    REQUEST_PARAMS => {
      sign => $conf{SYS_ID},
      v    => $version,
      info => join('_', @info_data)
    },
    TIMEOUT        => 1,
  });

  return $version;
}

#**********************************************************
=head2 _get_files_in($directory_path, $filter)

  Arguments:
     $directory_path
     $attr
       FILTER - regexp
       WITH_DIRS
       FULL_PATH
       RECURSIVE - get all files in underlying folders too

  Returns:
    array_ref

=cut
#**********************************************************
sub _get_files_in{
  my ($directory_path, $attr) = @_;

  my $filter = $attr->{FILTER} || '';
  my $with_dirs = $attr->{WITH_DIRS} || 0;
  my $full_path = $attr->{FULL_PATH} || 0;

  # Read files in dir
  opendir my $fh, $directory_path or do {
    $html->message( 'err', 'ERROR', "Can't open dir '$directory_path' $!\n" );
    return [];
  };

  my @contents = grep !/^\.\.?$/, readdir $fh;
  closedir $fh;

  # No .name files
  @contents = grep { ! /^\./ } @contents;
  if ($attr->{RECURSIVE}){
    my @dirs = grep { -d $directory_path . '/' . $_ } @contents;
    foreach my $dir_inside (@dirs){
      my $files_in_dir = _get_files_in($directory_path . '/' . $dir_inside, {%$attr, FULL_PATH => 0});
      if ($files_in_dir){
        push @contents, map {$dir_inside . '/' . $_} @$files_in_dir;
      }
    }
  }

  # Filter directories if needed
  @contents = grep { -f $directory_path . '/' . $_ } @contents if (!$with_dirs);

  # Apply REGEXP filter if needed
  if ( $filter && $filter ne '' ) {
    @contents = grep /$filter/, @contents;
  }

  # Concat directory path if needed
  @contents = map { $directory_path .'/' . $_ } @contents if ($full_path);

  return \@contents;
}

#**********************************************************
=head2 md5_of($file)

=cut
#**********************************************************
sub _md5_of{
  my ($filepath) = @_;

  load_pmodule( "Digest::MD5" );
  my $md5 = Digest::MD5->new();

  my $CRC = '';

  if ( open( my $o_fh, '<', $filepath ) ) {
    $md5->addfile( $o_fh );
    $CRC = $md5->hexdigest();
  }
  else {
    $html->message( 'err', $lang{ERROR}, "Can't open file '$filepath' $!\n" );
  };

  return $CRC;
}

#**********************************************************
=head2 _stats_for_file($file)

  Arguments:
    $file - path to file

  Returns:
    hash_ref
     file    - name of file with stats
     dev     - number of filesystem
     ino     - inode number
     mode    - file mode  (type and permissions)
     nlink   - number of (hard) links to the file
     uid     - numeric user ID of file's owner
     gid     - numeric group ID of file's owner
     rdev    - the device identifier (special files only)
     size    - total size of file, in bytes
     atime   - last access time in seconds since the epoch
     mtime   - last modify time in seconds since the epoch
     ctime   - inode change time in seconds since the epoch (*)
     blksize - preferred I/O size in bytes for interacting with the file (may vary from file to file)
     blocks  - actual number of system-specific blocks allocated on disk (often, but not always, 512 bytes each)

=cut
#**********************************************************
sub _stats_for_file {
  my ($file) = @_;

  my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat( $file );

  return {
    file    => $file,
    dev     => $dev,     # number of filesystem
    ino     => $ino,     # inode number
    mode    => $mode,    # file mode  (type and permissions)
    nlink   => $nlink,   # number of (hard) links to the file
    uid     => $uid,     # numeric user ID of file's owner
    gid     => $gid,     # numeric group ID of file's owner
    rdev    => $rdev,    # the device identifier (special files only)
    size    => $size,    # total size of file, in bytes
    atime   => $atime,   # last access time in seconds since the epoch
    mtime   => $mtime,   # last modify time in seconds since the epoch
    ctime   => $ctime,   # inode change time in seconds since the epoch (*)
    blksize => $blksize, # preferred I/O size in bytes for interacting with the file (may vary from file to file)
    blocks  => $blocks,  # actual number of system-specific blocks allocated on disk (often, but not always, 512 bytes each)
  }
}

#**********************************************************
=head1 recomended_pay($user, $attr) - Clculate all module fees

  Arguments:
    $attr
      SKIP_DEPOSIT_CHECK

  Results:
    TOTAL_PAYMENT_SUM

=cut
#**********************************************************
sub recomended_pay {
  my ($user_, $attr) = @_;

  $user_->{TOTAL_DEBET} = 0;
  my $cross_modules_return = cross_modules('docs', {
    UID       => $user_->{UID},
    REDUCTION => $user_->{REDUCTION},
    USER_INFO => $user_
    #PAYMENT_TYPE => 0
  });

  foreach my $module (sort keys %$cross_modules_return) {
    if (ref $cross_modules_return->{$module} eq 'ARRAY') {
      next if ($#{ $cross_modules_return->{$module} } == -1);
      foreach my $line (@{ $cross_modules_return->{$module} }) {
        # $name, $describe
        my (undef, undef, $sum) = split(/\|/, $line);
        $user_->{TOTAL_DEBET} += $sum if($sum);

        if ($user_->{REDUCTION} && $module ne 'Abon') {
          $user_->{TOTAL_DEBET} = sprintf("%.2f", $user_->{TOTAL_DEBET} * (100 - $user_->{REDUCTION}) / 100);
        }
      }
    }
  }

  if(! defined($user_->{DEPOSIT})) {
    return 0;
  }

  if(! $attr->{SKIP_DEPOSIT_CHECK}) {
    $user_->{TOTAL_DEBET} = ($user_->{DEPOSIT} < 0) ? $user_->{TOTAL_DEBET} + abs($user_->{DEPOSIT}) : ($user_->{DEPOSIT} > $user_->{TOTAL_DEBET}) ? 0 : $user_->{TOTAL_DEBET} - $user_->{DEPOSIT};
  }

  if ($user_->{TOTAL_DEBET} > int($user_->{TOTAL_DEBET})) {
    $user_->{TOTAL_DEBET} = sprintf("%.2f", int($user_->{TOTAL_DEBET}) + 1);
  }

  $user_->{TOTAL_DEBET} += ($conf{PAYSYS_ADD_TO_RECOMMENDED_SUMM} || 0);

  return $user_->{TOTAL_DEBET};
}

#**********************************************************
=head1 format_sum($sum, $attr) - Format sum

  Arguments:
    $sum
    $attr
      DEPOSIT_FORMAT - use $conf{DEPOSIT_FORMAT}
      ...
      TODO - more formats

  Results:
    well formated number

=cut
#**********************************************************
sub format_sum {
  my ($sum, $attr) = @_;
  $sum //= 0;
  my $result = $sum;

  if ($attr->{DEPOSIT_FORMAT}) {
    $result = sprintf($conf{DEPOSIT_FORMAT} || '%.2f', $sum);
  }
  else {
    my $negative = '';
    if ($sum < 0) {
      $sum = 0 - $sum;
      $negative = '-';
    }

    my $integer  = int($sum);
    my $fraction = int(($sum*100) - ($integer*100));
    $fraction = sprintf('%02d', $fraction);
    my $rev = scalar reverse ($integer);
    $result = scalar reverse (join (' ', $rev =~ m/\d{1,3}/g));
    $result = $negative . $result . "." . $fraction;
  }

  return $result;
}

1;
