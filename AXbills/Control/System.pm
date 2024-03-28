
=head1 NAME

  System web functions

=cut


use strict;
use warnings FATAL => 'all';
use AXbills::Defs;
use AXbills::Base qw(convert dsc2hash clearquotes int2byte days_in_month
  in_array startup_files load_pmodule urlencode encode_base64 json_former);

our ($db,
  %lang,
  $base_dir,
  %LANG,
  @MONTHES,
  @WEEKDAYS,
  @bool_vals,
  %permissions,
  @state_colors
);

our AXbills::HTML $html;
our Admins $admin;
our Conf $Conf;
our Users $users;


#**********************************************************
=head2 form_status() - service status listing


=cut
#**********************************************************
sub form_status {

  require Service;
  Service->import();

  my $Service = Service->new($db, $admin, \%conf);

  $Service->{ACTION}     = 'add';
  $Service->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $FORM{COLOR} =~ s/#// if($FORM{COLOR});
    $Service->status_add({%FORM});
    if (!$Service->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $FORM{COLOR} =~ s/#// if($FORM{COLOR});
    $FORM{GET_FEES} = 0   if(!$FORM{GET_FEES});
    $Service->status_change({%FORM});
    if (!$Service->{errno}) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} ID=". ($FORM{ID} || q{}));
    }
  }
  elsif (defined($FORM{chg})) {
    $Service->status_info({ ID => $FORM{chg} });
    $FORM{add_form} = 1;

    if (!$Service->{errno}) {
      $Service->{ACTION}     = 'change';
      $Service->{LNG_ACTION} = $lang{CHANGE};
      $Service->{GET_ABON_CHECKED} = ($Service->{GET_FEES} && $Service->{GET_FEES} == 1) ? 'checked' : '';
      $FORM{add_form}=1;
      $html->message('info', $lang{CHANGED}, "$lang{CHANGING} $Service->{ID}");
    }
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    $Service->status_del({ ID => $FORM{del} });
    if (!$Service->{errno} && $FORM{del} ne '') {
      $html->message('info', $lang{DELETED}, "ID=$FORM{del}");
    }
    else {
      $html->message('danger', $lang{NOT_DELETED}, "");
    }
  }

  _error_show($Service);

  if ($FORM{add_form}) {
    $Service->{TYPE_SEL} = $html->form_select(
      'TYPE',
      {
        SELECTED     => $Service->{TYPE} || $FORM{TYPE},
        SEL_ARRAY    => [ '', 'Critical' ],
        NO_ID        => 1,
        ARRAY_NUM_ID => 1
      }
    );

    $Service->{COLOR} = '#'.$Service->{COLOR} if($Service->{COLOR});
    $html->tpl_show(templates('form_service_status'), $Service);
  }

  result_former({
    INPUT_DATA      => $Service,
    FUNCTION        => 'status_list',
    DEFAULT_FIELDS  => 'ID,NAME,COLOR,TYPE,GET_FEES',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => {
      type     => { 0 => ' ', 1 => 'Critical' },
      get_fees => { 0 => "$lang{NO}", 1 => "$lang{YES}"}
    },
    FILTER_COLS => {
      name  => '_translate',
    },
    FILTER_VALUES => {
      color => sub { $html->color_mark($_[0], $_[0]) }
    },
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
      type       => $lang{TYPE},
      color      => $lang{COLOR},
      get_fees   => $lang{GET_FEES}
    },
    TABLE           => {
      width      => '100%',
      caption    => $lang{SERVICE_STATUS},
      qs         => $pages_qs,
      ID         => 'SERVICE_STATUS_LIST',
      EXPORT     => 1,
      MENU       => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS    => 1,
    SEARCH_FORMER=> 1,
    TOTAL        => 1
  });

  return 1;
}

#**********************************************************
=head2 form_user_status() - user status listing


=cut
#**********************************************************
sub form_user_status {

  require Users;
  Users->import();

  my $User = Users->new($db, $admin, \%conf);

  $User->{ACTION}     = 'add';
  $User->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $FORM{COLOR} =~ s/#// if($FORM{COLOR});
    $User->user_status_add({%FORM});
    if (!$User->{errno}) {
      $html->message('info', $lang{ADDED}, "ID=". ($FORM{ID} || 0));
    }
  }
  elsif ($FORM{change}) {
    $FORM{COLOR} =~ s/#// if($FORM{COLOR});
    $FORM{GET_FEES} = 0   if(!$FORM{GET_FEES});
    $User->user_status_change({%FORM});
    if (!$User->{errno}) {
      $html->message('info', $lang{CHANGED}, "$lang{EXECUTED} $lang{FOR} ID=". ($FORM{ID} || 0));
    }
  }
  elsif (defined($FORM{chg})) {
    $User->user_status_info({ ID => $FORM{chg} });
    if (!$User->{errno}) {
      $User->{ACTION}     = 'change';
      $User->{LNG_ACTION} = $lang{CHANGE};
      $FORM{add_form} = 1;
    }
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    $User->user_status_del({ ID => $FORM{del} });
    if (!$User->{errno} && $FORM{del} ne '') {
      $html->message('info', $lang{DELETED}, "ID=$FORM{del}");
    }
    else {
      $html->message('danger', $lang{NOT_DELETED}, "");
    }
  }

  _error_show($User);

  if ($FORM{add_form}) {
    $User->{COLOR} = '#'.$User->{COLOR} if($User->{COLOR});
    $html->tpl_show(templates('form_user_status'), $User);
  }

  result_former({
    INPUT_DATA      => $User,
    FUNCTION        => 'user_status_list',
    DEFAULT_FIELDS  => 'ID,NAME,COLOR,DESCRIBE',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    FILTER_COLS => {
      name  => '_translate',
    },
    FILTER_VALUES => {
      color => sub { $html->color_mark($_[0], $_[0]) }
    },
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
      color      => $lang{COLOR},
      descr      => $lang{DESCRIBE}
    },
    TABLE           => {
      width      => '100%',
      caption    => $lang{USER_STATUS},
      qs         => $pages_qs,
      ID         => 'USER_STATUS_LIST',
      EXPORT     => 1,
      MENU       => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS    => 1,
    SEARCH_FORMER=> 1,
    TOTAL        => 1
  });

  return 1;
}

#**********************************************************
=head2 form_build() - build plugin organizer

=cut
#**********************************************************
sub form_billd_plugins {

  require Billd;
  Billd->import();
  my $Billd = Billd->new($db, $admin, \%conf);

  my $billd_plugin_dir = $base_dir . '/libexec/billd.plugins/';

  $Billd->{ACTION}     = 'add';
  $Billd->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Billd->add({%FORM});
    if (!$Billd->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change} && $FORM{ID}) {
    $Billd->change({%FORM});
    if (!$Billd->{errno}) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} ". ($Billd->{ID} || q{}));
    }
  }
  elsif (defined($FORM{chg})) {
    $Billd->info({ ID => $FORM{chg} });

    if (!$Billd->{errno}) {
      $Billd->{ACTION}     = 'change';
      $Billd->{LNG_ACTION} = $lang{CHANGE};
      $FORM{add_form}=1;
      $html->message('info', $lang{CHANGED}, "$lang{CHANGING} $Billd->{ID}");
    }
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    $Billd->del({ ID => $FORM{del} });
    if (!$Billd->{errno}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
    }
  }

  _error_show($Billd);

  $Billd->{PRIORITY_SEL} = $html->form_select(
    'PRIORITY',
    {
      SELECTED    => $Billd->{PRIORITY} || $FORM{PRIORITY} || 2,
      SEL_ARRAY   => [0..10],
      SEL_OPTIONS => { '' => '--' },
    }
  );

  if ($FORM{add_form}) {
    if (! $Billd->{PLUGIN_NAME}) {
      $Billd->{PLUGIN_NAME}=$FORM{PLUGIN_NAME};
    }

    if (! $Billd->{PERIOD}) {
      $Billd->{PERIOD}=$FORM{PERIOD} || 300;
    }

    if ($Billd->{MAKE_LOCK}) {
      $Billd->{MAKE_LOCK}='checked';
    }
    elsif(! defined($Billd->{MAKE_LOCK})) {
      $Billd->{MAKE_LOCK}='checked';
    }

    $Billd->{PRIORITY_SEL} = $html->form_select(
      'PRIORITY',
      {
        SELECTED    => $Billd->{PRIORITY} || $FORM{PRIORITY} || 2,
        SEL_ARRAY   => [0..10],
      }
    );

    $Billd->{THREADS_SEL} = $html->form_select(
      'THREADS',
      {
        SELECTED    => $Billd->{THREADS} || $FORM{THREADS} || 1,
        SEL_ARRAY   => [1..16],
      }
    );

    $Billd->{STATUS_SEL} = $html->form_select(
      'STATUS',
      {
        SELECTED   => $Billd->{STATUS} || $FORM{STATUS} || 0,
        SEL_HASH   => {
            0  => $lang{ENABLE},
            1  => $lang{DISABLE}
          },
        NO_ID      => 1,
      }
    );

    $html->tpl_show(templates('form_billd_plugin'), $Billd);
  }

  my AXbills::HTML $table;

  ($table) = result_former({
    INPUT_DATA      => $Billd,
    FUNCTION        => 'list',
    DEFAULT_FIELDS  => 'PLUGIN_NAME,PERIOD,STATUS,PRIORITY,LAST_EXECUTE,EXECUTE_TIME',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => {
      make_lock => {
        0 => $lang{NO},
        1 => $lang{YES}
      },
      status    => {
        0 => $lang{ENABLE},
        1 => "$lang{DISABLE}:text-danger"
      }
    },
    EXT_TITLES      => {
      plugin_name  => $lang{NAME},
      period       => $lang{PERIOD},
      status       => $lang{STATUS},
      threads      => 'Threads',
      make_lock    => 'Lock',
      priority     => $lang{PRIORITY},
      last_execute => 'last_execute',
      execute_time => 'EXECUTE_TIME',
    },
    TABLE           => {
      width      => '100%',
      caption    => "Active billd plugins",
      qs         => $pages_qs,
      ID         => 'BILLD_PLUGINS',
      EXPORT     => 1,
    },
    MAKE_ROWS    => 1,
    SEARCH_FORMER=> 1,
    TOTAL        => 1
  });

  opendir my $fh, "$billd_plugin_dir" or die "Can't open dir '$billd_plugin_dir' $!\n";
    my @contents = grep !/^\.\.?$/, readdir $fh;
  closedir $fh;

  $table = $html->table(
    {
      caption     => "Available billd plugins",
      title_plain => [ $lang{NAME}, $lang{DATE}, $lang{SIZE}, '-' ],
      ID          => 'FORM_BILLD',
    }
  );

  foreach my $filename (sort @contents) {
    my ($size, $mtime) = (stat("$billd_plugin_dir/$filename"))[7,9];
    my $date = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($mtime));
    $filename =~ s/\.pm//;

    $table->addrow($filename,
      $date,
      int2byte($size),
      $html->button($lang{ACTIVE}, "index=$index&PLUGIN_NAME=$filename&add_form=1", { class => 'add' })
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_templates_pdf_edit() - build plugin organizer

=cut
#**********************************************************
sub form_templates_pdf_edit {
  my $file = $FORM{file};

  if (! $file) {
    $html->message('err', $lang{ERROR}, $lang{ERROR_FILE});
    return 0
  }

  my $json_docs_vars = "{}";
  if(in_array("Docs", \@MODULES)) {
    ::load_module("Docs", $html);
    my $docs_vars = eval { docs_take_variables() } || {};
    $json_docs_vars = json_former($docs_vars);
  }

  my $pdf_content = '';
  my $dsc_parsed_data = {};

  open(my $pdf_file, '<', "$conf{TPL_DIR}/" . $file . '.pdf') if (-e "$conf{TPL_DIR}/" . $file . '.pdf');
  open(my $dsc_file, '<', "$conf{TPL_DIR}/" . $file . '.dsc') if (-e "$conf{TPL_DIR}/" . $file . '.dsc');

  if ($pdf_file) {
    while (<$pdf_file>) {
      $pdf_content .= $_;
    }

    close($pdf_file);
  }
  else {
    $html->message( 'danger text-center', $lang{ERROR}, $lang{ERROR_FILE}.$file.'.pdf');
    return 0;
  }

  if($dsc_file) {
    my $dsc_content = '';

    while (<$dsc_file>) {
      $dsc_content .= $_;
    }

    $dsc_parsed_data = dsc2hash($dsc_content);
    close($dsc_file);
  }
  else {
    $html->message( 'danger text-center', $lang{ERROR}, $lang{ERROR_FILE}.$file.'.dsc');
  }

  my $pdf_base64 = encode_base64($pdf_content);
  load_pmodule('JSON');
  my $json = JSON->new()->utf8(0);

  $html->tpl_show(templates('form_templates_pdf_edit'), {
    DOCS_VARS  => $json_docs_vars,
    FILE_NAME  => $file,
    PDF_BASE64 => $pdf_base64,
    DSC        => $json->encode($dsc_parsed_data),
    SAVE_INDEX => get_function_index('form_templates_pdf_save')
  });

  return 1;
}

#**********************************************************
=head2 form_templates_pdf_save() - build plugin organizer

=cut
#**********************************************************
sub form_templates_pdf_save {
  if(!defined($FORM{FILE_NAME})) {
    print json_former({ 'status' => 400, 'text' => 'UNDEFINED_FILE_NAME'});
    return 0;
  }

  my $dcs_file_name = $FORM{FILE_NAME} =~ s/pdf/dsc/rg;
  open(my $dsc_file, '+>', "$conf{TPL_DIR}/" . $dcs_file_name . '.dsc') || die "Can't open file $!";

  my $tpl_file_name = $FORM{FILE_NAME} =~ s/pdf/tpl/rg;
  open(my $tpl_file, '+>', "$conf{TPL_DIR}/" . $tpl_file_name . '.tpl') || die "Can't open file $!";

  print $dsc_file $FORM{DSC_CONTENT};

  close($dsc_file);
  close($tpl_file);

  # If this script breaks - printing html error by default, unfortunately
  if ($@) {
    return 0;
  }

  print json_former({ 'status' => 200, 'text' => 'SUCCESS'});
  return 0;
}

#**********************************************************
=head2 form_templates() - Create templates and manage template

=cut
#**********************************************************
sub form_templates {

  my $sys_templates      = '../../AXbills/modules';
  my $main_templates_dir = '../../AXbills/main_tpls/';
  my %info               = (TEMPLATE => '');
  my $main_tpl_name      = '';

  my $domain_path = '';
  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
    $conf{TPL_DIR} = "$conf{TPL_DIR}/$domain_path";
    if (!-d $conf{TPL_DIR}) {
      if (!mkdir($conf{TPL_DIR})) {
        $html->message('err', $lang{ERROR}, "$lang{ERR_CANT_CREATE_FILE} '$conf{TPL_DIR}' $lang{ERROR}: $!\n");
      }
    }
  }

  $info{ACTION_LNG} = $lang{CHANGE};

  if ($FORM{create}) {
    my ($module, $file, $lang) = split(/:/, $FORM{create}, 3);

    if($file !~ /\.tpl$/) {
      $file .= ".tpl";
    }

    $info{TEMPLATE} = file_op({
      FILENAME => $file,
      PATH     => ($module) ? "$sys_templates/$module/templates/" : "$main_templates_dir/"
    });

    my $filename = ($module) ? "$sys_templates/$module/templates/$file" : "$main_templates_dir/$file";
    if ( $lang  ){
      $file =~ s/\.tpl/_$lang/;
      $file .= '.tpl';
    }

    $main_tpl_name = $file;
    $info{TPL_NAME} = "$module" . '_' . "$file";

    $info{TEMPLATE} =~ s/\\"/"/g;
    show_tpl_info($filename, ($module) ? "$sys_templates/$module/templates/" : "$main_templates_dir/");
  }
  elsif ($FORM{SHOW}) {
    $html->{METATAGS} = templates('metatags');
    print $html->header();
    my ($module, $file, $lang) = split(/:/, $FORM{SHOW}, 3);
    $file =~ s/.tpl//;
    $file =~ s/ |\///g;

    $html->{language} = $lang if ($lang && $lang ne '');

    if ($module) {
      my $realfilename = "/AXbills/modules/$module/lng_$html->{language}.pl";
      my $lang_file = '';
      my $prefix = '../..';
      if (-f $realfilename) {
        $lang_file = $realfilename;
      }
      elsif (-f "$prefix/AXbills/modules/$module/lng_english.pl") {
        $lang_file = "$prefix/AXbills/modules/$module/lng_english.pl";
      }

      if ($lang_file ne '') {
        do $lang_file;
      }
    }

    if ($module) {
      $html->tpl_show(_include("$file", "$module"), { LNG_ACTION => $lang{ADD} },);
    }
    else {
      $html->tpl_show(templates("$file"), { LNG_ACTION => $lang{ADD} },);
    }

    return 0;
  }
  elsif ($FORM{change}) {
    my %FORM2 = ();
    my @pairs = split(/&/, $FORM{__BUFFER} || q{});
    $info{ACTION_LNG} = $lang{CHANGE};

    foreach my $pair (@pairs) {
      my ($side, $value) = split(/=/, $pair);
      $value =~ tr/+/ /;
      $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

      if (defined($FORM2{$side})) {
        $FORM2{$side} .= ", $value";
      }
      else {
        $FORM2{$side} = $value;
      }
    }

    if ($FORM{FORMAT} && $FORM{FORMAT} eq 'unix') {
      $FORM2{template} =~ s/\r//g;
    }

    $info{TEMPLATE} = $FORM2{template} || q{};
    $info{TPL_NAME} = $FORM{tpl_name};
    if ($info{TEMPLATE}) {
      $info{TEMPLATE} = convert($info{TEMPLATE}, { '2_tpl' => 1 });
      $info{TEMPLATE} =~ s/\"/\'/g;
      $info{TEMPLATE} =~ s/\@/\\@/g;
    }

    if ($info{TEMPLATE}) {
      file_op({ WRITE => 1,
          FILENAME    => $FORM{tpl_name},
          PATH        => $conf{TPL_DIR},
          CONTENT     => $info{TEMPLATE}
        });

      $main_tpl_name = $FORM{tpl_name};
      $main_tpl_name =~ s/^_//;
      $info{TEMPLATE} =~ s/\\"/"/g;
      $info{TEMPLATE} =~ s/\\\@/\@/g;
      $admin->system_action_add( "$lang{CHANGED} - " . ($FORM{tpl_name} || q{}), { TYPE => 60 } );
    }
    else {
      $html->message('err', 'Empty', $lang{ERR_NODATA});
    }
  }
  elsif ($FORM{FILE_UPLOAD}) {
    if($FORM{FILE_UPLOAD}{filename}) {
      upload_file($FORM{FILE_UPLOAD}, { EXTENTIONS => 'tpl,jpg,pdf,dsc,gif,jpeg,png' });
      $admin->system_action_add("$lang{ADDED} $lang{FILE} - $FORM{FILE_UPLOAD}{filename}", { TYPE => 62 });
    }
  }
  elsif ($FORM{file_del} && $FORM{COMMENTS}) {
    $FORM{file_del} =~ s/ |\///g;
    if (unlink("$conf{TPL_DIR}/$FORM{file_del}") == 1) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED}: '$FORM{file_del}'");
      $admin->system_action_add("$lang{DELETED} - $FORM{file_del} - $FORM{COMMENTS}", {TYPE => 63});
    }
    else {
      $html->message('err', $lang{DELETED}, "$lang{ERROR}");
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $FORM{del} =~ s/ |\///g;
    if (unlink("$conf{TPL_DIR}/$FORM{del}") == 1) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED}: '$FORM{del}'");
      $admin->system_action_add("$lang{DEL} - $FORM{del} - $FORM{COMMENTS}", {TYPE => 61});
    }
    else {
      $html->message('err', $lang{DELETED}, "$lang{ERROR} '$conf{TPL_DIR}/$FORM{del}' $!");
    }
  }
  elsif ($FORM{tpl_name}) {
    $info{TEMPLATE} = file_op({
      FILENAME => $FORM{tpl_name},
      PATH     => $conf{TPL_DIR},
      CONTENT  => $info{TEMPLATE}
    });

    if ($info{TEMPLATE}) {
      show_tpl_info("$conf{TPL_DIR}/$FORM{tpl_name}", $conf{TPL_DIR});

      $info{TPL_NAME} = $FORM{tpl_name};
      $html->message('info', $lang{CHAMGE}, "$lang{CHANGE}: $FORM{tpl_name}");

      $main_tpl_name = $FORM{tpl_name};
      $main_tpl_name =~ s/^_//;

      $info{TEMPLATE} =~ s/\\"/"/g;
    }
  }

  $info{TEMPLATE} = convert($info{TEMPLATE}, { from_tpl => 1 });

  $FORM{create} = '' if (!$FORM{create});
  $FORM{tpl_name} = '' if (!$FORM{create});
  $info{TPL_NAME} = '' if (!$info{TPL_NAME});

  my $tpl_ = $html->tpl_show(templates('form_template_editor'), { %info }, { OUTPUT2RETURN => 1 });
  $tpl_ =~ s/__TEMPLATE__/$info{TEMPLATE}/g;
  print $tpl_;

  if($info{TPL_NAME} =~ /_admin_menu/){
    admin_menu();
  }
  elsif($info{TPL_NAME} =~ /_client_menu/){
    client_menu();
  }

  my $templates_modules = '';
  my @caption = sort keys %LANG;

  #Main templates section
  my $table = $html->table({
    width       => '100%',
    title_plain => [ $lang{FILE}, "$lang{SIZE} (Byte)", $lang{DATE}, $lang{DESCRIBE}, $lang{MAIN}, @caption ],
    ID          => 'TEMPLATES_LIST_MAIN'
  });

  if (-d $main_templates_dir) {
    my $tpl_describe = get_tpl_describe("describe.tpls", $main_templates_dir);
    opendir my $fh, "$main_templates_dir" or die "Can't open dir '$sys_templates/main_tpls' $!\n";
      my @contents = grep !/^\.\.?$/, readdir $fh;
    closedir $fh;
    $table->{rowcolor} = undef;
    $table->{extra}    = undef;
    my $module = "";
    foreach my $file (sort @contents) {
      if (-d "$main_templates_dir" . $file) {
        next;
      }
      elsif ($file !~ /\.tpl$/) {
        next;
      }

      my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks);

      if (-f "$conf{TPL_DIR}/$module" . "_$file") {
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$conf{TPL_DIR}/$module" . "_$file");
        $mtime = POSIX::strftime("%Y-%m-%d", localtime($mtime));
      }
      else {
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$main_templates_dir" . $file);
        $mtime = POSIX::strftime("%Y-%m-%d", localtime($mtime));
      }

      # LANG
      my @rows = (
        "$file", $size, $mtime, (($tpl_describe->{$file}) ? $tpl_describe->{$file} : ''),
        $html->button($lang{SHOW}, "#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$module:$file", class => 'show' })
        . ((-f "$conf{TPL_DIR}/_$file") ? $html->button($lang{CHANGE}, "index=$index&tpl_name=" . "_$file", { class => 'change', }) : $html->button($lang{CREATE}, "index=$index&create=:$file", { class => 'add' }))
        . ((-f "$conf{TPL_DIR}/_$file") ? $html->button($lang{DEL}, "index=$index&del=" . "_$file", { MESSAGE => "$lang{DEL} '$file'", class => 'del' }) : '')
      );

      $file =~ s/\.tpl//;
      foreach my $lang (@caption) {
        my $f = '_' . $file . '_' . $lang . '.tpl';
        push @rows,
        ((-f "$conf{TPL_DIR}/$f")
          ? $html->button($lang{SHOW}, "index=$index#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$module:$file:$lang", class => 'show' }) . $html->br() . $html->button($lang{CHANGE}, "index=$index&tpl_name=$f", { class => 'change' })
          : $html->button($lang{CREATE}, "index=$index&create=:$file" . '.tpl' . ":$lang", { class => 'add' }))
        . ((-f "$conf{TPL_DIR}/$f") ? $html->button($lang{DEL}, "index=$index&del=$f", { MESSAGE => "$lang{DEL} '$f'", class => 'del' }) : '');
      }

      $table->{rowcolor} = ($file . '.tpl' eq $main_tpl_name) ? 'active' : undef;
      $table->addrow(@rows);
    }
  }

  $templates_modules .= $html->tpl_show(templates('form_template_item'), {
    TITLE => $html->b("$lang{PRIMARY}") . " ($main_templates_dir) ",
    TABLE => $table->show({ OUTPUT2RETURN => 1 }),
  },{ OUTPUT2RETURN => 1 });

  # Modules templates sections
  foreach my $module (sort @MODULES) {

    $table = $html->table({
      width       => '100%',
      title_plain => [ $lang{FILE}, "$lang{SIZE} (Byte)", $lang{DATE}, $lang{DESCRIBE}, $lang{MAIN}, @caption ],
      ID          => 'TEMPLATES_LIST_MODULES',
    });

    if (-d "$sys_templates/$module/templates") {
      my $tpl_describe = get_tpl_describe("describe.tpls", "$sys_templates/$module/templates/");

      opendir my $fh, "$sys_templates/$module/templates" or die "Can't open dir '$sys_templates/$module/templates' $!\n";
        my @contents = grep !/^\.\.?$/ && /\.tpl$/, readdir $fh;
      closedir $fh;

      $table->{rowcolor} = undef;
      $table->{extra}    = undef;

      foreach my $file (sort @contents) {
        next if (-d "$sys_templates/$module/templates/" . $file);

        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks);

        if (-f "$conf{TPL_DIR}/$module" . "_$file") {
          ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$conf{TPL_DIR}/$module" . "_$file");
          $mtime = POSIX::strftime("%Y-%m-%d", localtime($mtime));
        }
        else {
          ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$sys_templates/$module/templates/" . $file);
          $mtime = POSIX::strftime("%Y-%m-%d", localtime($mtime));
        }

        # LANG
        my @rows = (
          "$file", $size, $mtime, (($tpl_describe->{$file}) ? $tpl_describe->{$file} : ''),
          $html->button($lang{SHOW}, "index=$index#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$module:$file", class => 'show' })
          . ((-f "$conf{TPL_DIR}/$module" . "_$file") ? $html->button($lang{CHANGE}, "index=$index&tpl_name=$module" . "_$file", { class => 'change' }) : $html->button($lang{CREATE}, "index=$index&create=$module:$file", { class => 'add' }))
          . ((-f "$conf{TPL_DIR}/$module" . "_$file") ? $html->button($lang{DEL}, "index=$index&del=$module" . "_$file", { MESSAGE => "$lang{DEL} $file", class => 'del' }) : '')
        );

        $file =~ s/\.tpl//;

        foreach my $lang (@caption) {
          my $template_name = '_' . $file . '_' . $lang . '.tpl';

          my $file_exists = -f "$conf{TPL_DIR}/$module" . "$template_name";
          my $row = q{};

          if ($file_exists){
            $row .= $html->button($lang{SHOW}, "index=$index#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$module:$file:$lang",  class => 'show'  })
            . $html->button($lang{CHANGE}, "index=$index&tpl_name=$module" . "$template_name", { class => 'change' })
            . $html->button($lang{DEL}, "index=$index&del=$module" . "$template_name", { MESSAGE => "$lang{DEL} $file", class => 'del' });
          }
          else {
            $row = $html->button($lang{CREATE}, "index=$index&create=$module:$file" . '.tpl' . ":$lang", { class => 'add' });
          }

          push @rows, $row;
        }

        $table->addrow(@rows);
      }


    }

    $templates_modules .= $html->tpl_show(templates('form_template_item'), {
      TITLE => $html->b($module) . " ($sys_templates/$module/templates)",
      TABLE => $table->show({ OUTPUT2RETURN => 1 }),
    }, { OUTPUT2RETURN => 1 });

  }

  my $form_template = $html->tpl_show(templates('form_template_all'), {
    TITLE             => $lang{TEMPLATES},
    TEMPLATES_MODULES => $templates_modules,
  },{ OUTPUT2RETURN => 1 });

  print $form_template;

  # OTHER
  $table = $html->table({
    width       => '600',
    caption     => $lang{OTHER},
    title_plain => [ "FILE", "$lang{SIZE} (Byte)", "$lang{DATE}", "$lang{DESCRIBE}", "-" ],
  });

  if (-d "$conf{TPL_DIR}") {
    opendir my $fh, "$conf{TPL_DIR}" or die "Can't open dir '$conf{TPL_DIR}' $!\n";
      my @contents = grep !/^\.\.?$/ && !/\.tpl$/, readdir $fh;
    closedir $fh;

    $table->{rowcolor} = undef;
    $table->{extra}    = undef;

    my $describe = '';
    my $pdf_editor_index = get_function_index('form_templates_pdf_edit');

    foreach my $file (sort @contents) {
      next if (-d "$conf{TPL_DIR}/" . $file);

      my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks);

      ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$conf{TPL_DIR}/$file");
      $mtime = POSIX::strftime("%Y-%m-%d", localtime($mtime));

      my $file_actions = '';

      $file_actions .= $html->button(
          $lang{DEL},
          "index=$index&file_del=$file",
          {
            MESSAGE => "$lang{DEL} '$file'",
            class => 'del'
          }
        );

      if($file =~ /\.pdf$/) {
        my $file_without_extention = $file =~ s/\.pdf//r;

        $file_actions .= $html->button(
            $lang{EDIT},
            "index=$pdf_editor_index&file=$file_without_extention",
            {
              ICON => 'fa fa-pencil-alt'
            }
          );
      }

      $table->addrow(
        "$file",
        $size,
        $mtime,
        $describe,
        $file_actions
      );
    }

  }
  print $table->show();

  $html->tpl_show(templates('form_fileadd'), undef);

  return 1;
}

#**********************************************************
=head2 get_tpl_describe($file, $path) Get teblate describe

=cut
#**********************************************************
sub get_tpl_describe {
  my ($file, $path) = @_;
  my %tpls_describe = ();

  my $rows= file_op({ FILENAME  => $file,
                      PATH      => $path,
                      SKIP_CHECK=> 1,
                      ROWS      => 1 });

  if ( $rows ne q{} ){
    foreach my $line ( @{$rows} ){
      if ( $line =~ /^#/ ){
        next;
      }
      my ($tpl, $lang, $describe) = split( /:/, $line, 3 );

      if ( $lang eq $html->{language} ){
        $tpls_describe{$tpl} = $describe;
      }
    }
  }

  return \%tpls_describe;
}

#**********************************************************
=head2 show_tpl_info()

=cut
#**********************************************************
sub show_tpl_info {
  my ($filename, $path) = @_;

  $filename =~ s/\.tpl$//;
  my $table = $html->table({
    width       => '600',
    caption     => "$lang{INFO} - '$filename'",
    title_plain => [ $lang{NAME}, $lang{DESCRIBE}, $lang{PARAMS} ],
    ID          => 'TPL_INFO'
  });

  my $tpl_params = tpl_describe("$filename", $path);

  foreach my $key (sort keys %$tpl_params) {
    $table->addrow('%' . $key . '%', $tpl_params->{$key}->{DESCRIBE}, $tpl_params->{$key}->{PARAMS});
  }

  print $table->show();
  return 1;
}

#**********************************************************
=head2 tpl_describe($tpl_name, $path, $attr) -  Get template describe. Variables and other

  tpl describe file format
  TPL_VARIABLE:TPL_VARIABLE_DESCRIBE:DESCRIBE_LANG:PARAMS

=cut
#**********************************************************
sub tpl_describe {
  my ($tpl_name, $path, $attr) = @_;
  my $filename     = $tpl_name . '.dsc';
  my %TPL_DESCRIBE = ();

  my $rows = file_op({
    FILENAME  => $filename,
    SKIP_CHECK=> 1,
    ROWS      => 1,
    PATH      => $path
  });

  return { } if (!$rows || $rows eq q{});

  foreach my $line (@$rows) {
    if ($line =~ /^#/) {
      next;
    }
    elsif ($line =~ /^(\S+):(.+):(\S+):(\S{0,200})/) {
      my $name     = $1;
      my $describe = $2;
      my $lang     = $3;
      my $params   = $4;
      next if ($attr->{LANG} && $attr->{LANG} ne $lang);
      $TPL_DESCRIBE{$name}{DESCRIBE} = $describe;
      $TPL_DESCRIBE{$name}{LANG}     = $lang;
      $TPL_DESCRIBE{$name}{PARAMS}   = $params;
    }
  }

  return \%TPL_DESCRIBE;
}

#**********************************************************
=head2  form_dictionary() - Dictionary mangment

=cut
#**********************************************************
sub form_dictionary {
  my $sub_dict = $FORM{SUB_DICT} || '';

  if($sub_dict =~ /\D\.\D/){
    ($sub_dict, undef) = split(/\./, $sub_dict, 2);
  }

  if ($FORM{add_form}) {
    print $html->form_main(
      {
        CONTENT => "$lang{DICTIONARY}: " . $html->form_input('SUB_DICT', "" ),
        HIDDEN  => {
          index => $index,
        },
        SUBMIT  => { add => "$lang{ADD}" },
        class   => 'form-inline'
      }
    );
  }
  elsif($FORM{add} && $FORM{SUB_DICT}) {
    $sub_dict = $FORM{SUB_DICT};

    file_op({
      WRITE     => 1,
      FILENAME  => $sub_dict .".pl",
      PATH      => $libpath.'/language/',
      CREATE    => 1
    })
  }
  elsif ($FORM{change}) {
    my $out = '';
    my $i   = 0;
    while (my ($k, $v) = each %FORM) {
      if ($sub_dict && $k =~ /$sub_dict/ && $k ne '__BUFFER') {
        my (undef, $key) = split(/_/, $k, 2);
        next if(!$key || !$v);
        $key =~ s/\%40/\@/;
        if ($key =~ /@/) {
          next if !$v;      # Will break syntax if empty
          $v =~ s/\\'/'/g;
          $v =~ s/\\"/"/g;
          $v =~ s/\;$//g;
          $out .= "our  $key=$v;\n";
        }
        else {
          $key =~ s/%7B/\{/g;
          $key =~ s/%7D/\}/g;
          $key =~ s/\%24/\$/;
          $v   =~ s/'/\'/g;
          $out .= "$key='$v';\n";
        }
        $i++;
      }
    }

    file_op({
      WRITE    => 1,
      FILENAME => $sub_dict .".pl",
      PATH     => $libpath.'/language/',
      CONTENT  => $out
    });
  }

  my $table = $html->table({
    width       => '600',
    title_plain => [ "$lang{NAME}", "-" ],
    caption     => "$lang{DICTIONARY}",
    ID          => 'DICTIONARY_LIST',
    MENU        => "$lang{ADD}:index=$index&add_form=1:add",
  });

  #show dictionaries
  opendir my $fh, $libpath."/language/" or die "Can't open dir '". $libpath ."/language/' $!\n";
    my @contents = grep !/^\.\.?$/, readdir $fh;
  closedir $fh;

  if ($#contents > 0) {
    foreach my $file (@contents) {
      $file =~ s/\.pl//;

      if (-f $libpath."/language/" . $file .'.pl') {
        if ($sub_dict && $sub_dict . ".pl" eq $file) {
          $table->{rowcolor} = 'active';
        }
        else {
          undef($table->{rowcolor});
        }
        $table->addrow("$file", $html->button($lang{CHANGE}, "index=$index&SUB_DICT=$file", { class => 'change' }));
      }
    }
  }

  print $table->show();

  #Open main dictionary
  my %main_dictionary = ();

  my $rows = file_op({
    FILENAME => 'english.pl',
    PATH      => $libpath.'/language/',
    ROWS      => 1
  });

  my $i=0;
  foreach my $line (@$rows) {
    my ($name, $value) = split(/=/, $line, 2);
    $name =~ s/ //ig;
    $name =~ s/^our//;
    if ($name =~ /^@/) {
      $main_dictionary{"$name"} = $value;
    }
    elsif ($line !~ /^#|^\n/) {
      $main_dictionary{"$name"} = clearquotes($value, { EXTRA => "|\'|;" });
    }
  }

  my %sub_dictionary = ();

  if($sub_dict){
    $rows = file_op({
      FILENAME   => $sub_dict . '.pl',
      PATH       => $libpath . '/language/',
      SKIP_CHECK => 1,
      ROWS       => 1
    });

    if ($rows) {
      foreach my $line (@{$rows}) {
        $line =~ s/ = /=/ if ($line =~ / = /g);
        my ($name, $value) = split(/=/, $line, 2);
        $name =~ s/ //ig;
        $name =~ s/^our//;
        if ($name =~ /^@/) {
          $sub_dictionary{"$name"} = $value;
        }
        elsif ($line !~ /^#|^\n/) {
          $sub_dictionary{"$name"} = clearquotes($value, { EXTRA => "|\'|;" });
        }
      }
    }
  }

  $table = $html->table({
    width       => '600',
    caption     => $lang{DICTIONARY},
    title_plain => [ "$lang{NAME}", "$lang{VALUE}", "-" ],
    ID          => 'FORM_DICTIONARY'
  });

  foreach my $k (sort keys %main_dictionary) {
    my $v  = $main_dictionary{$k};
    my $v2 = '';

    if($k eq '1' || $k eq '1;') {
      next;
    }

    if (defined($sub_dictionary{"$k"})) {
      $v2 = $sub_dictionary{"$k"};
      $table->{rowcolor} = undef;
    }
    else {
      $v2 = '';
      $table->{rowcolor} = 'danger';
    }

    $table->addrow($html->form_input('NAME',
      $k, { SIZE => 30 }),
      $html->form_input($k, $v, { SIZE => 45 }),
      ($sub_dict) ? $html->form_input($sub_dict . "_" . $k, "$v2", { SIZE => 100 }) : ''
    );
    $i++;
  }

  $table->{rowcolor} = 'active';
  $table->addrow("$lang{TOTAL}", "$i", '');

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      index    => "$index",
      SUB_DICT => ($sub_dict || '')
    },
    SUBMIT  => { change => "$lang{CHANGE}" }
  });

  return 1;
}

#**********************************************************
=head form_sql_backup() - Make SQL backup

=cut
#**********************************************************
sub form_sql_backup {
  my ($attr) = @_;

  if ($FORM{mk_backup} || $attr->{mk_backup}) {
    $conf{dbcharset} = 'latin1' if (!$conf{dbcharset});
    my $tables      = '';
    my $backup_file = "$conf{BACKUP_DIR}/axbills-$DATE.sql.gz";
    if ($attr->{TABLES}) {
      my @tables_arr = split(/,/, $attr->{TABLES});
      $tables = join(' ', @tables_arr);
      if ($#tables_arr == 0) {
        $backup_file = "$conf{BACKUP_DIR}/axbills_$tables-$DATE.sql.gz";
      }
      else {
        $backup_file = "$conf{BACKUP_DIR}/axbills_tables-$DATE.sql.gz";
      }
    }

    our $MYSQLDUMP;
    our $GZIP;

    my $startup_files = startup_files({ TPL_DIR => $conf{TPL_DIR} });

    my $mysqldump = $startup_files->{MYSQLDUMP} || $MYSQLDUMP;
    my $gzip = $startup_files->{GZIP} || $GZIP;

    my $cmd = qq{ $mysqldump --default-character-set=$conf{dbcharset} --host=$conf{dbhost} --user="$conf{dbuser}" --password="$conf{dbpasswd}" $conf{dbname} $tables | $gzip > $backup_file };
    my $res = `$cmd`;
    $cmd =~ s/password=\"(.+)\" /password=\"\*\*\*\*\" /g;

    if ($attr->{EXTERNAL} && -s $backup_file){
      return {
        errno  => 0,
        result => "Backup created: $res ($backup_file)\n'$cmd'"
      }
    }

    $html->message('info', $lang{INFO}, "Backup created: $res ($backup_file)\n'$cmd'");
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    my $status = unlink("$conf{BACKUP_DIR}/$FORM{del}");
    $html->message('info', $lang{INFO}, "$lang{DELETED} : $conf{BACKUP_DIR}/$FORM{del} [$status]");
  }

  my $table = $html->table({
    caption     => $lang{SQL_BACKUP},
    title_plain => [ $lang{NAME}, $lang{DATE}, $lang{SIZE}, '-' ],
    ID          => 'SQL_BACKUP_LIST',
  });

  opendir my $fh, $conf{BACKUP_DIR} or do {
    $html->message( 'err', $lang{ERROR}, "Can't open dir '$conf{BACKUP_DIR}' $!\n" );
    return 0;
  };
    my @contents = grep !/^\.\.?$/, readdir $fh;
  closedir $fh;

  foreach my $filename (sort @contents) {
    my (undef, undef, undef, undef, undef, undef, undef,, $size, undef, $mtime, undef, undef, undef) = stat("$conf{BACKUP_DIR}/$filename");

    my $date = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($mtime));
    $table->addrow($filename, $date, int2byte($size), $html->button($lang{DEL}, "index=$index&del=$filename", { MESSAGE => "$lang{DEL} $filename?", class => 'del' }));
  }

  print $table->show() . $html->button($lang{CREATE}, "index=$index&mk_backup=1", { BUTTON => 1 });

  return 1;
}

#**********************************************************
=head2 form_exchange_rate() - System currensy and exchange rate

=cut
#**********************************************************
sub form_exchange_rate {

  my $finance = Finance->new($db, $admin, \%conf);

  if ($FORM{add_form}) {
    $finance->{ACTION}     = 'add';
    $finance->{LNG_ACTION} = "$lang{ADD}";
    $html->tpl_show(templates('form_er'), $finance);
  }
  elsif ($FORM{add}) {
    $finance->exchange_add({%FORM});
    if (! $finance->{errno}) {
      $html->message('info', $lang{EXCHANGE_RATE}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $finance->exchange_change("$FORM{chg}", {%FORM});
    if (! _error_show($finance)) {
      $html->message('info', $lang{EXCHANGE_RATE}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{chg}) {
    $finance->exchange_info("$FORM{chg}");

    if (! $finance->{errno}) {
      $finance->{ACTION}     = 'change';
      $finance->{LNG_ACTION} = "$lang{CHANGE}";
      $html->message('info', $lang{EXCHANGE_RATE}, "$lang{CHANGING}");
      $html->tpl_show(templates('form_er'), $finance);
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $finance->exchange_del("$FORM{del}");
    if (! $finance->{errno}) {
      $html->message('info', $lang{EXCHANGE_RATE}, "$lang{DELETED}");
    }
  }
  elsif ($FORM{log_del} && $FORM{COMMENTS}) {
    $finance->exchange_log_del("$FORM{log_del}");
    if (! $finance->{errno}) {
      $html->message('info', $lang{EXCHANGE_RATE}, "$lang{LOG} $lang{DELETED}");
    }
  }

  _error_show($finance);
  my ($table, $list) = result_former({
    INPUT_DATA      => $finance,
    FUNCTION        => 'exchange_list',
    BASE_FIELDS     => 5,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      money      => $lang{MONEY},
      short_name => $lang{SHORT_NAME},
      rate       => "$lang{EXCHANGE_RATE} (1 unit =)",
      iso        => 'iso',
      changed    => $lang{CHANGED},
    },
    TABLE           => {
      width      => '100%',
      caption    => "$lang{EXCHANGE_RATE}",
      qs         => $pages_qs,
      ID         => 'EXCHANGE_RATE',
      EXPORT     => 1,
      MENU       => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  });

  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'desc';
  }

  ($table, $list) = result_former({
    INPUT_DATA      => $finance,
    FUNCTION        => 'exchange_log_list',
    BASE_FIELDS     => 3,
    FUNCTION_FIELDS => 'del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      money      => $lang{MONEY},
      short_name => $lang{SHORT_NAME},
      rate       => "$lang{EXCHANGE_RATE} (1 unit =)",
      iso        => 'iso',
      changed    => $lang{CHANGED},
    },
    TABLE           => {
      width      => '100%',
      caption    => $lang{LOG},
      qs         => $pages_qs,
      ID         => 'EXCHANGE_RATE_LOG',
      EXPORT     => 1,
    },
    MAKE_ROWS    => 1,
    SEARCH_FORMER=> 1,
    TOTAL        => 1
  });

  return 1;
}

#**********************************************************
=head2 form_hollidays() - Hollidays list

  Hollidays gratulations and design

=cut
#**********************************************************
sub form_holidays {

  require Tariffs;
  Tariffs->import();
  my $holidays = Tariffs->new($db, \%conf, $admin);

  if($FORM{action} && $FORM{action} eq 'add'){
    $holidays->holidays_add({
      DAY      => "$FORM{month}-$FORM{DAY}",
      FILE     => $FORM{FILE_SELECT},
      DESCR    => $FORM{COMMENTS}
    });

    if (!$holidays->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}");
    }
  }
  elsif($FORM{action} && $FORM{action} eq 'change'){
    $holidays->holidays_change({
      DAY      => "$FORM{month}-$FORM{DAY}",
      FILE     => $FORM{FILE_SELECT},
      DESCR    => $FORM{COMMENTS}
    });

    if (!$holidays->{errno}) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
    }
  }

  # загрузка файла
  if ($FORM{FILE}){
    upload_file($FORM{FILE},
                {
                  PREFIX  => 'holiday',
                  REWRITE => 1
                });
  }

  # переход на шаблон загрузки файла
  if ($FORM{file} || $FORM{FILE}){
    $html->tpl_show(templates('form_upload_file'),
    {
      INDEX => $index
    });
    return 1;
  }

  # если выбран день из календаря для добавления
  if ($FORM{add}) {
    my ($month, $day) = split('-', $FORM{add});
    my @files_select = holiday_files_list();
    my $file_upload_link = "$SELF_URL?index=" . get_function_index('form_holidays') . "&file=1";
    $html->tpl_show(templates('form_holiday_add'),
    {
      MONTH        => $MONTHES[$month - 1],
      NUMBER_MONTH => $month,
      DAY          => $day,
      YEAR         => $FORM{year},
      ACTION       => 'add',
      BTN_NAME     => "$lang{ADD}",
      FILE_SELECT  => @files_select,
      UPLOAD_FILE  => $file_upload_link
    });
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $holidays->holidays_del($FORM{del});

    if (!$holidays->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }

  # если на календаре выбрать выходной день
  if($FORM{change} || $FORM{show}){
    my $holiday_info;
    my ($month, $day)=split(/\-/, $DATE);

    # получение данных из таблицы
    if ($FORM{change}) {
      $holiday_info = $holidays->holidays_info({ DAY => $FORM{change} });
      if (!$holiday_info->{DAY}) {
        return 0;
      }
      ($month, $day) = split('-', $holiday_info->{DAY});
    }
    elsif($FORM{show} =~ /\-/) {
      my ($m, $d) = split('-', $FORM{show});
      my $search = $m . '-' . $d;
      $holiday_info = $holidays->holidays_info({ DAY => $search });
      ($month, $day) = split('-', $holiday_info->{DAY});
    }

    my @files_select = holiday_files_list({ FILE => $holiday_info->{FILE} });      # список файлов
    my $file_upload_link = "$SELF_URL?index=" . get_function_index('form_holidays') . "&file=1"; # линк на загрузку файла

    # заполнение шаблона
    $html->tpl_show(
      templates('form_holiday_add'),
    {
      MONTH        => $MONTHES[$month - 1],
      NUMBER_MONTH => $month,
      DAY          => $day,
      YEAR         => $FORM{year},
      COMMENTS     => $holiday_info->{DESCR},
      ACTION       => 'change',
      BTN_NAME     => $lang{CHANGE},
      FILE_SELECT  => @files_select,
      UPLOAD_FILE  => $file_upload_link
    });
  }

  _error_show($holidays);

  my $list  = $holidays->holidays_list({COLS_NAME => 1});
  my $year  = $FORM{year}  || POSIX::strftime("%Y", localtime(time));
  my $month = $FORM{month} || POSIX::strftime("%m", localtime(time));
  my $next_month = $month + 1; # месяц для кнопки NEXT
  my $last_month = $month - 1; # месяц для кнопки LAST
  my $last_year = $year;       # год для кнопки LAST
  my $next_year = $year;       # год для кнопки NEXT

  if($next_month > 12){
    $next_month = 1;
    $next_year = $year + 1;
  }

  if($last_month < 1){
    $last_month = 12;
    $last_year = $year - 1;
  }

  my $tyear = $year - 1900;
  my $curtime = POSIX::mktime(0, 1, 4, 1, ($month - 1), $tyear);
  my $cur_wday = (gmtime($curtime))[6];

  my $week_row = '';
  if ($cur_wday == 0){
    $cur_wday = 7;
  }

  my $month_days =  days_in_month({ DATE =>  "$year-$month-01" });

  $week_row = table_for_calendar({
    MONTH_DAYS => $month_days,
    CUR_WDAY   => $cur_wday,
    MONTH      => $month
  });

  $html->tpl_show(templates('form_calendar_holidays'),
  {
    MONTH      => $MONTHES[$month - 1],
    NUM_MONTH  => $month,
    YEAR       => $year,
    LAST_MONTH => $last_month,
    NEXT_MONTH => $next_month,
    LAST_YEAR  => $last_year,
    NEXT_YEAR  => $next_year,
    DAYS       => $week_row,
    WEEKDAYS_1 => $WEEKDAYS[1],
    WEEKDAYS_2 => $WEEKDAYS[2],
    WEEKDAYS_3 => $WEEKDAYS[3],
    WEEKDAYS_4 => $WEEKDAYS[4],
    WEEKDAYS_5 => $WEEKDAYS[5],
    WEEKDAYS_6 => $WEEKDAYS[6],
    WEEKDAYS_7 => $WEEKDAYS[7],
    WEEKDAYS_8 => $WEEKDAYS[8],
  });

  my $table = $html->table({
    width      => '500',
    rows       => [ [ "$lang{TOTAL}:", $html->b($holidays->{TOTAL}) ] ]
  });

  print $table->show();

  $table = $html->table({
    caption    => $lang{HOLIDAYS},
    width      => '500',
    title      => [ $lang{DAY}, $lang{FILE}, $lang{DESCRIBE}, '-' ],
  });

  foreach my $line (@$list) {
    my ($m, $d) = split(/-/, $line->{day});
    my $change = $html->button($lang{CHANGE}, "index=75&change=$line->{day}", { class=>'change'});
    my $delete = $html->button($lang{DEL}, "index=75&del=$line->{day}", { MESSAGE => "$lang{DEL} $line->{day}?", class => 'del' });
    $table->addrow("$d $MONTHES[$m - 1]", $line->{file}, $line->{descr}, $change . $delete);
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 table_for_calendar() -

  Arguments:
    $attr:
      MONTH_DAYS - count of days in month
      CUR_WDAY   - when 1 day of month start in week
      MONTH      - month number

  Returns:
    $week_row - rows for table

  Examples:
    $table_rows = table_for_calendar({
                MONTH_DAYS => 30,
                CUR_WDAY   => 4,
                MONTH      => 4
                });

=cut
#**********************************************************
sub table_for_calendar{
  my ($attr) = @_;

  require Tariffs;
  Tariffs->import();
  my $holidays = Tariffs->new($db, \%conf, $admin);

  my $i       = 1;
  my $no_days = 1;
  my $week_row .= "<tr>";

  while ($no_days < $attr->{CUR_WDAY}) {
    $week_row .= "<td></td>";
    $no_days++;
  }

  while ($i <= $attr->{MONTH_DAYS}) {
    if (($no_days % 7) == 1) {
      $week_row .= "<tr>";
    }

    my $search = ($attr->{MONTH}) . "-" . $i;
    my $holi_info = $holidays->holidays_info({ DAY => $search });

    my $comment     = '';
    my $holiday_day = '';
    my $action      = 'add';
    my $delete      = '';

    if ($search && $holi_info->{DAY} && $search eq $holi_info->{DAY} ) {
      $comment     = $holi_info->{DESCR} || '';
      $holiday_day = "class='danger'";
      $action      = 'show';
      $delete = $html->button($lang{DEL}, "index=75&del=".($attr->{MONTH})."-$i", { MESSAGE => "$lang{DEL} $attr->{MONTH}-$i?", class => 'del' });
    }

    if (($no_days % 7) == 0) {
      $holiday_day = "class='danger'";
    }

    $week_row .= "<td width='100' height='100' $holiday_day>
                  <a href='/admin/index.cgi?index=75&$action=$attr->{MONTH}-$i&year=". ($FORM{year} || '') ."&month=". ($FORM{month} || '') ."' title='$comment'>
                    <h4>$i</h4><br>
                  </a>
                  $delete
                  </td>";

    if (($no_days % 7) == 0) {
      $week_row .= "</tr>";
    }
    $i++;
    $no_days++;
  }

  while (($no_days - 1) % 7 != 0) {
    $week_row .= "<td></td>";
    $no_days++;
  }

  return $week_row;
}

#**********************************************************
=head2 holiday_array($month) Return holiday array for month

=cut
#**********************************************************
sub holiday_array {
  my ($month) = @_;

  require Tariffs;
  Tariffs->import();
  my $holidays = Tariffs->new($db, \%conf, $admin);
  my $hol_list = $holidays->holidays_list({COLS_NAME => 1});
  my @HOLLIDAY;

  foreach my $line (@$hol_list){
    my ($m,$d) = split('-', $line->{day});
    if($m == $month){
      push(@HOLLIDAY, $d);
    }
  }

  return @HOLLIDAY;
}

#**********************************************************
=head2 holiday_files_list($attr)

=cut
#**********************************************************
sub holiday_files_list {
  my ($attr) = @_;

  my $holiday_path = "$conf{TPL_DIR}/holiday/";
  my $dir_len = length($holiday_path);

  my @files = glob("$holiday_path*");

  foreach my $file (@files) {
    $file = substr $file, $dir_len;
  }

  my $files_select = $html->form_select(
    'FILE_SELECT',
    {
      SELECTED    => $FORM{FILE_SELECT} || $attr->{FILE},
      SEL_ARRAY   => \@files,
      SEL_OPTIONS => { '' => '--' },
    }
  );

  return $files_select;
}

#**********************************************************
=head2 form_info_fields() - User extra fields add

  Information fields for users and companies

=cut
#**********************************************************
#@deprecated
sub form_info_fields {

  if($conf{info_fields_new}) {
    info_fields_new();
    return 1;
  }

  if ($FORM{FIELD_ID}){
    $FORM{FIELD_ID} = lc( $FORM{FIELD_ID} );
    $FORM{FIELD_ID} =~ s/[ \-]+//g;
  }

  if ($FORM{USERS_ADD}) {
    if (length($FORM{FIELD_ID}) > 15) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (Length > 15)");
    }
    else {
      $users->info_field_add({%FORM});
      if (!$users->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{ADDED}: $FORM{FIELD_ID} - $FORM{NAME}");
      }
    }
  }
  elsif ($FORM{COMPANY_ADD}) {
    $users->info_field_add({%FORM});
    if (!$users->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}: $FORM{FIELD_ID} - $FORM{NAME}");
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $users->info_field_del({ SECTION => $FORM{del}, %FORM });
    if (!$users->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}: $FORM{FIELD_ID}");
    }
  }

  _error_show($users);

  my @fields_types = (
    'String',
    'Integer',
    $lang{LIST},
    $lang{TEXT},
    'Flag',
    'Blob',
    'PCRE',
    'AUTOINCREMENT',
    'ICQ',
    'URL',
    'PHONE',
    'E-Mail',
    'Skype',
    $lang{FILE},
    $lang{DELIVERY},
    'PHOTO',
    'SOCIAL NETWORK',
    'Crypt',
    $lang{LANGUAGE},
    'Time zone'
  );

  my $fields_type_sel = $html->form_select(
    'FIELD_TYPE',
    {
      SELECTED     => $FORM{field_type},
      SEL_ARRAY    => \@fields_types,
      NO_ID        => 1,
      ARRAY_NUM_ID => 1,
    }
  );

  delete ($Conf->{COL_NAMES_ARR});
  my $list = $Conf->config_list({ PARAM => 'ifu*', SORT => 2 });

  my $table = $html->table(
    {
      width      => '500',
      caption    => "$lang{INFO_FIELDS} - $lang{USERS}",
      title      => [ $lang{NAME}, 'SQL field', $lang{TYPE}, $lang{PRIORITY}, $lang{USER_PORTAL},
        $lang{USER} . ' ' . $lang{CHANGE}, '-' ],
      EXPORT     => 1,
      FIELDS_IDS => ['NAME', 'SQL', 'TYPE'],
      ID         => 'INFO_FIELDS_USERS',
      NOT_RESPONSIVE => 1,
    }
  );

  foreach my $line (@$list) {
    my $field_name = '';

    if ($line->[0] =~ /ifu(\S+)/) {
      $field_name = $1;
    }

    my ($position, $field_type, $name, $user_portal, $can_be_changed_by_user) = split(/:/, $line->[1]);
    if (! defined($field_type)){
      $field_type = 0;
    }

    $table->addrow(
      $name,
      $field_name,
        ($field_type == 2) ? $html->button($fields_types[$field_type], "index=" . ($index + 1) . "&LIST_TABLE=$field_name" . '_list') : $fields_types[$field_type],
      $position,
      $bool_vals[(defined $user_portal && $user_portal ne '') || 0],
      $bool_vals[(defined $can_be_changed_by_user && $can_be_changed_by_user ne '') || 0],
      ($permissions{4} && $permissions{4}{3}) ? $html->button($lang{DEL}, "index=$index&del=ifu&FIELD_ID=$field_name", { MESSAGE => "$lang{DEL} $field_name?", class => 'del' }) : ''
    );
  }

  $table->{SKIP_EXPORT_CONTENT}=1;

  $table->addrow(
      $html->form_input('NAME', '', { EX_PARAMS => ' required="required" ' }),
      $html->form_input('FIELD_ID', '', { SIZE => 12 }),
      $fields_type_sel,
      $html->form_input('POSITION',     0,     { SIZE => 10 }),
      $html->form_input('USERS_PORTAL', 1,     { TYPE => 'CHECKBOX' }),
      $html->form_input('CAN_BE_CHANGED_BY_USER',    $lang{USER} . ' ' . $lang{CHANGE}, { TYPE => 'CHECKBOX' }),
      $html->form_input('USERS_ADD',    $lang{ADD}, { TYPE => 'SUBMIT' }),
  );

  print $html->form_main(
    {
      CONTENT => $table->show(),
      HIDDEN  => { index => $index, },
      NAME    => 'users_fields',
      ID      => 'FORM_FIELDS_USERS',
      EXPORT_CONTENT => 'INFO_FIELDS_USERS',
#      class => 'form form-inline'
    }
  );

  $list = $Conf->config_list({ PARAM => 'ifc*', SORT => 2 });
  $table = $html->table(
    {
      width      => '500',
      caption    => "$lang{INFO_FIELDS} - $lang{COMPANIES}",
      title      => [ $lang{NAME}, 'SQL field', $lang{TYPE}, $lang{PRIORITY}, $lang{USER_PORTAL}, '-' ],
      NOT_RESPONSIVE => 1,
    }
  );

  foreach my $line (@$list) {
    my $field_name = '';

    if ($line->[0] =~ /ifc(\S+)/) {
      $field_name = $1;
    }

    my ($position, $field_type, $name, $user_portal) = split(/:/, $line->[1]);
    if (! defined($field_type)){
      $field_type = 0;
    }

    $user_portal ||=0;

    $table->addrow(
      $name,
      $field_name,
      ($field_type == 2) ?
        $html->button($fields_types[$field_type], "index=" . ($index + 1) . "&LIST_TABLE=$field_name" . '_list') : $fields_types[$field_type],
      $position,
      $bool_vals[$user_portal],
      ($permissions{4} && $permissions{4}{3}) ? $html->button($lang{DEL}, "index=$index&del=ifc&FIELD_ID=$field_name", { MESSAGE => "$lang{DEL} $field_name ?", class => 'del' }) : '',
    );
  }

  $table->addrow($html->form_input('NAME', '', { FORM_ID => 'COMPANY_FIELDS', EX_PARAMS => ' required="required" '  }),
    $html->form_input('FIELD_ID', '', { SIZE => 12, FORM_ID => 'COMPANY_FIELDS'  }),
    $fields_type_sel,
    $html->form_input('POSITION', 0, { SIZE => 10, FORM_ID => 'COMPANY_FIELDS' }),
    $html->form_input('USERS_PORTAL', 1, { TYPE => 'CHECKBOX', FORM_ID => 'COMPANY_FIELDS' }),
    $html->form_input('COMPANY_ADD', $lang{ADD}, { TYPE => 'SUBMIT', FORM_ID => 'COMPANY_FIELDS' })
  );

  print $html->form_main(
    {
      CONTENT => $table->show(),
      HIDDEN  => { index => $index, },
      NAME    => 'company_fields',
      ID      => 'COMPANY_FIELDS',
    }
  );

  return 1;
}

#**********************************************************
=head2 form_info_lists() - Information lists

=cut
#**********************************************************
sub form_info_lists {

  my @ACTIONS = ('add', $lang{ADD});

  if ($FORM{add}) {

    $users->info_list_add({%FORM});

    if (!$users->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}: $FORM{NAME}");
    }
  }
  elsif ($FORM{change}) {
    $users->info_list_change($FORM{chg}, { ID => $FORM{chg}, %FORM });
    if (!$users->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}: $FORM{NAME}");
    }
  }
  elsif ($FORM{chg}) {
    $users->info_list_info($FORM{chg}, {%FORM});
    if (!$users->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGE}: $FORM{chg}");
      @ACTIONS = ('change', $lang{CHANGE});
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $users->info_list_del({ ID => $FORM{del}, %FORM });
    if (!$users->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}: $FORM{del}");
    }
  }

  my $list = ();
  my %lists_hash = ();
  _error_show($users);

  if($conf{info_fields_new}){
    require Info_fields;
    my $Info_fields = Info_fields->new($db, $admin, \%conf);

    $list = $Info_fields->fields_list(
        {
          TYPE => 2
        }
      );

    foreach my $line (@$list) {
      $lists_hash{ $line->{sql_field} . '_list' } = $line->{name};
    }
  }
  else{
      $list = $Conf->config_list(
        {
          PARAM => 'if*',
          VALUE => '*:2:*'
        }
      );
      foreach my $line (@$list) {
        my $field_name = '';

        if ($line->[0] =~ /if[u|c](\S+)/) {
          $field_name = $1;
        }

        # $position, $field_type
        my (undef, undef, $name) = split(/:/, $line->[1]);
        $lists_hash{ $field_name . '_list' } = $name;
      }
    }

  my $lists_sel = $html->form_select(
    'LIST_TABLE',
    {
      SELECTED => $FORM{LIST_TABLE},
      SEL_HASH => \%lists_hash,
      NO_ID    => 1,
    }
  );

  my @rows = (
    "$lang{LIST}:",
    $lists_sel,
    $html->form_input('SHOW', $lang{SHOW}, { TYPE => 'submit' })
  );

  my $info = '';
  foreach my $val ( @rows ) {
    $info  .= $html->element('div', $val, { class => 'form-group' });
  }

  my $list_form = $html->element('div', $info, {
      class => 'navbar navbar-default form-inline'
  });

  print $html->form_main({
    CONTENT => $list_form,
    HIDDEN  => { index => $index, },
    NAME    => 'tables_list'
  });

  if ($FORM{LIST_TABLE}) {
    my $table = $html->table(
      {
        width      => '450',
        caption    => "$lang{LIST}",
        title      => [ '#', $lang{NAME}, '-', '-' ],
        ID         => 'LIST'
      }
    );

    $list = $users->info_lists_list({%FORM, COLS_NAME => 1});

    foreach my $line (@$list) {
      $table->addrow(
        $line->{id}, $line->{name},
        $html->button($lang{CHANGE}, "index=$index&LIST_TABLE=$FORM{LIST_TABLE}&chg=$line->{id}", { class => 'change' })
        . (($permissions{0} && $permissions{0}{5}) ? $html->button($lang{DEL}, "index=$index&LIST_TABLE=$FORM{LIST_TABLE}&del=$line->{id}", { MESSAGE => "$lang{DEL} $line->{id} / $line->{name}?", class => 'del' }) : '')
      );
    }

    $table->addrow($users->{ID}, $html->form_input('NAME', $users->{NAME}, { SIZE => 80 }), $html->form_input($ACTIONS[0], $ACTIONS[1], { TYPE => 'SUBMIT' }));

    print $html->form_main(
      {
        CONTENT => $table->show(),
        HIDDEN  => {
          index      => $index,
          chg        => $FORM{chg},
          LIST_TABLE => $FORM{LIST_TABLE}
        },
        NAME => 'list_add'
      }
    );
  }

  return 1;
}

#**********************************************************
=head2 form config() - Show system config

=cut
#**********************************************************
sub form_config {

  my %main_checksum = ();

  if (-f $base_dir.'/VERSION') {
    if (open(my $fh, '<', $base_dir."/VERSION")) {
      $conf{VERSION} = <$fh>;
      close($fh);
    }
  }

  my($version)=split(/ /, $conf{VERSION});

  require AXbills::Fetcher;
  AXbills::Fetcher->import('web_request');
  my $output = web_request('http://axbills.net.ua/misc/checksum/'.$version, { BODY_ONLY => 1 });
  my @rows = split(/[\r\n]/, $output);

  foreach my $line (@rows) {
    my($k, $v)= split(/:/, $line) ;
    if ( defined $k ){
      $main_checksum{$k} = $v;
    }
  }

  my %file_check_sum= ();

  load_pmodule('Digest::MD5', { IMPORT => 'md5_hex' });
  get_checksum($base_dir, \%file_check_sum);

  my $table = $html->table(
    {
      caption     => 'config options',
      width       => '600',
      title_plain => [ $lang{NAME}, $lang{DATE}, "MD5", "-" ],
    }
  );

  foreach my $file (sort keys %file_check_sum) {
    my ($checksum, $date) = split(/:/, $file_check_sum{$file}, 2);
    my $compare_checksum = '';
    $table->{rowcolor}=undef;
    if ($main_checksum{$file}) {
      if ($main_checksum{$file} eq $checksum) {
        $compare_checksum='ok'
      }
      else {
        $table->{rowcolor}='danger';
        $compare_checksum='wrong sum';
      }
    }
    else {
      $table->{rowcolor}='warning';
      $compare_checksum = 'no checksum';
    }

    $table->addrow($file,
      $date,
      $checksum,
      $compare_checksum,
    );
  }

  print $table->show();

  $table = $html->table({
    caption     => 'config options',
    title_plain => [ "$lang{NAME}", "$lang{VALUE}", $lang{STATUS} ],
  });

  $table->addrow("Perl Version:", $], '');

  foreach my $k (sort keys %conf) {
    if ($k eq 'dbpasswd') {
      $conf{$k} = '*******';
    }
    $table->addrow($k, $conf{$k}, '');
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_fees_types($attr)

=cut
#**********************************************************
sub form_fees_types {

  my $Fees = Finance->fees($db, $admin, \%conf);

  $Fees->{ACTION}     = 'add';
  $Fees->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Fees->fees_type_add({%FORM});
    if (!$Fees->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Fees->fees_type_change({%FORM});
    if (!$Fees->{errno}) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
    }
  }
  elsif (defined($FORM{chg})) {
    $Fees->fees_type_info({ ID => $FORM{chg} });
    $Fees->{ACTION}     = 'change';
    $Fees->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    $Fees->fees_type_del($FORM{del});
    if (!$Fees->{errno}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
    }
  }

  _error_show($Fees);

  $html->tpl_show(templates('form_fees_types'), $Fees);

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 2;
  }

  $LIST_PARAMS{PAGE_ROWS} = 1000;

  result_former({
    INPUT_DATA      => $Fees,
    FUNCTION        => 'fees_type_list',
    BASE_FIELDS     => 4,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      tax  => $lang{TAX},
      id   => '#',
      name => $lang{NAME},
      default_describe => $lang{COMMENTS},
      sum  => $lang{SUM}
    },
    FILTER_COLS  => {
      name => '_translate',
    },
    TABLE => {
      width      => '100%',
      caption    => "$lang{FEES} $lang{TYPE}",
      qs         => $pages_qs,
      ID         => 'FEES_TYPE',
      DATA_TABLE => 1,
    },
    MAKE_ROWS    => 1,
    SEARCH_FORMER=> 1,
    TOTAL        => 1
  });

  return 1;
}

#**********************************************************
=head2 get_checksum($dir, $file_check_sum) - Get file checksum;

=cut
#**********************************************************
sub get_checksum {
  my ($dir, $file_check_sum) = @_;

  opendir my $dh, $dir or return;
    my @contents = grep !/^\.\.?$/, readdir $dh;
  closedir $dh;

  foreach my $f (@contents) {
    my $filename = $dir.'/'.$f;

    if ($f =~ /^\./ || -l $filename) {
      next;
    }

    if (-d $filename) {
      &get_checksum($filename, $file_check_sum);
    }
    elsif($filename =~ /webinterface$|\.pm|billd$|periodic$|rlm_perl.pl|index.cgi|\.js$/) {
      my $file_content = '';
      if (open(my $fh, '<', $filename)) {
        while(<$fh>) {
          $file_content .= $_;
        }

        close($fh);
      }

      my $digest = Digest::MD5::md5_hex($file_content);
      my $mtime = (stat($filename))[9];
      my $date = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($mtime));
      $filename =~ s/$base_dir\///g;
      $file_check_sum->{$filename}="$digest:$date";
    }
  }

  return $file_check_sum;
}

#**********************************************************
=head2 form_tp_groups() - Tarif plans groups

=cut
#**********************************************************
sub form_tp_groups {

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($db, \%conf, $admin);

  my $Tarrifs            = $Tariffs->tp_group_defaults();
  $Tariffs->{LNG_ACTION} = $lang{ADD};
  $Tariffs->{ACTION}     = 'ADD';

  if ($FORM{ADD}) {
    $Tariffs->tp_group_add({%FORM});
    if (!$Tariffs->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED} GID: $Tariffs->{GID}");
    }
  }
  elsif ($FORM{change}) {
    $Tariffs->tp_group_change({%FORM});
    if (!$Tariffs->{errno}) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} ");
    }
  }
  elsif (defined($FORM{chg})) {
    $Tariffs->tp_group_info($FORM{chg});
    if (!$Tariffs->{errno}) {
      $html->message('info', $lang{CHANGE}, "$lang{CHANGE} ");
    }

    $Tariffs->{ACTION}     = 'change';
    $Tariffs->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    $Tariffs->tp_group_del($FORM{del});
    if (!$Tariffs->{errno}) {
      $html->message('info', $lang{DELETE}, "$lang{DELETED} $FORM{del}");
    }
  }

  _error_show($Tariffs);

  $Tariffs->{USER_CHG_TP} = ($Tarrifs->{USER_CHG_TP}) ? 'checked' : '';
  $html->tpl_show(templates('form_tp_group'), $Tarrifs);

  result_former({
    INPUT_DATA      => $Tariffs,
    FUNCTION        => 'tp_group_list',
    BASE_FIELDS     => 4,
    FUNCTION_FIELDS => 'group_tp_user_groups:$lang{GROUPS}:id:,geolocation_group_tp:$lang{GEOLOCATION_TP}:id:,change,del',
    EXT_TITLES      => {
      id          => '#',
      name        => $lang{NAME},
      user_chg_tp => $lang{USER_CHG_TP},
      tarif_plans_count => $lang{COUNT}
    },
    SKIP_USER_TITLE => 1,
    SELECT_VALUE  => {
      user_chg_tp => { 0 => $lang{NO}, 1 => $lang{YES}  },
    },
    TABLE       => {
      width      => '100%',
      caption    => $lang{GROUPS},
      qs         => $pages_qs,
      ID         => 'TP_GROUPS',
      EXPORT     => 1,
      MENU       => "$lang{ADD}:index=$index&add_form=1:add",
    },
    MAKE_ROWS    => 1,
    TOTAL        => 1
  });

  return 1;
}

#**********************************************************
=head2 form_intervals($attr) - Time intervals

=cut
#**********************************************************
sub form_intervals {
  my ($attr) = @_;

  my @DAY_NAMES = ("$lang{ALL}", "$WEEKDAYS[7]", "$WEEKDAYS[1]", "$WEEKDAYS[2]", "$WEEKDAYS[3]", "$WEEKDAYS[4]", "$WEEKDAYS[5]", "$WEEKDAYS[6]", "$lang{HOLIDAYS}");

  my %visual_view = ();
  my Tariffs $tarif_plan;
  my $max_traffic_class_id = 0;    #Max taffic class id

  if ($attr->{TP}) {
    $tarif_plan               = $attr->{TP};
    $tarif_plan->{ACTION}     = 'add';
    $tarif_plan->{LNG_ACTION} = $lang{ADD};

    if (defined($FORM{tt})) {
      load_module('Internet', $html);
      internet_traf_tarifs({ TP => $tarif_plan });
    }
    elsif ($FORM{add}) {
      $tarif_plan->ti_add({%FORM});
      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{INTERVALS} $lang{ADDED}");
        $tarif_plan->ti_defaults();
      }
    }
    elsif ($FORM{change}) {
      $tarif_plan->ti_change($FORM{TI_ID}, {%FORM});
      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{INTERVALS} $lang{CHANGED} [$tarif_plan->{TI_ID}]");
      }
    }
    elsif (defined($FORM{chg})) {
      $tarif_plan->ti_info($FORM{chg});
      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{INTERVALS} $lang{CHANGE} [$FORM{chg}]");
      }

      $tarif_plan->{ACTION}     = 'change';
      $tarif_plan->{LNG_ACTION} = $lang{CHANGE};
    }
    elsif ($FORM{del} && $FORM{COMMENTS}) {
      $tarif_plan->ti_del($FORM{del});
      if (!$tarif_plan->{errno}) {
        $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
      }
    }
    else {
      $tarif_plan->ti_defaults();
    }

    _error_show($tarif_plan);

    if (! $tarif_plan->{TP_ID} && $FORM{TP_ID})  {
      $tarif_plan->{TP_ID} = $FORM{TP_ID};
    }

    my $list  = $tarif_plan->ti_list({ %LIST_PARAMS, COLS_NAME => 1 });
    my $table = $html->table({
      width      => '100%',
      caption    => $lang{INTERVALS},
      title      => [ '#', $lang{DAYS}, $lang{BEGIN}, $lang{END}, $lang{HOUR_TARIF}, $lang{TRAFFIC}, '-', '-', '-' ],
      qs         => $pages_qs,
      class      => 'table table-hover table-condensed table-striped table-bordered'
    });

    my $color = "AAA000";
    foreach my $line (@$list) {
      my $delete = $html->button($lang{DEL}, "index=$index$pages_qs&del=$line->{id}&subf=$FORM{subf}", { MESSAGE => "$lang{DEL} [$line->{id}] ?", class => 'del' });
      $color = sprintf("%06x", hex('0x' . $color) + 7000);

      #day, $hour|$end = color
      my ($h_b) = split(/:/, $line->{begin}, 3);
      my ($h_e) = split(/:/, $line->{end}, 3);

      push(@{ $visual_view{ $line->{day} } }, "$h_b|$h_e|$color|$line->{id}");

      if (($FORM{chg} && $FORM{tt} && $FORM{tt} eq $line->{id}) || ($FORM{chg} && $FORM{chg} eq $line->{id})) {
        $table->{rowcolor} = 'active';
      }
      else {
        undef($table->{rowcolor});
      }

      $table->addtd(
        $table->td($line->{id}, { rowspan => ($line->{traffic_classes} > 0) ? 2 : 1 }),
        $table->td($html->b($DAY_NAMES[ $line->{day} ])),
        $table->td($line->{begin}),
        $table->td($line->{end}),
        $table->td($line->{tarif}),
        $table->td($html->button($lang{TRAFFIC}, "index=$index$pages_qs&tt=$line->{id}&subf=$FORM{subf}",  { class => 'btn btn-xs btn-default traffic' })),
        $table->td($html->button($lang{CHANGE},  "index=$index$pages_qs&chg=$line->{id}&subf=$FORM{subf}", { class => 'change' })),
        $table->td($delete), $table->td("&nbsp;", { bgcolor => '#' . $color, rowspan => ($line->{traffic_classes} > 0) ? 2 : 1 })
      );

      if ($line->{traffic_classes} > 0) {
        my $TI_ID = $line->{id};

        #Traffic tariff IN (1 Mb) Traffic tariff OUT (1 Mb) Prepaid (Mb) Speed (Kbits) Describe NETS
        my $table2 = $html->table({
          width       => '100%',
          title_plain => [ "#", "$lang{TRAFIC_TARIFS} In ", "$lang{TRAFIC_TARIFS} Out ", "$lang{PREPAID} (Mb)", "$lang{SPEED} IN", "$lang{SPEED} OUT", "DESCRIBE", "NETS", "-", "-" ],
          caption     => "$lang{TRAFIC_TARIFS}",
          class       => 'table table-hover table-condensed table-striped table-bordered'
        });

        my $list_tt = $tarif_plan->tt_list({ TI_ID => $line->{id} });
        foreach my $line2 (@$list_tt) {
          $max_traffic_class_id = $line2->[0] if ($line2->[0] > $max_traffic_class_id);

          $table2->addrow(
            ($line2->[0] != 0) ? $html->color_mark($line2->[0], 'red') : $line2->[0],
            $line2->[1],
            $line2->[2],
            $line2->[3],
            int2byte($line2->[4], { KBYTE_SIZE => $conf{KBYTE_SIZE}, DELIMITER => ' ' }),
            int2byte($line2->[5], { KBYTE_SIZE => $conf{KBYTE_SIZE}, DELIMITER => ' ' }),
            $line2->[6],
            convert($line2->[7], { text2html => 1 }),
            $html->button($lang{CHANGE}, "index=$index$pages_qs&tt=$TI_ID&chg=$line2->[0]&subf=$FORM{subf}", { class => 'change' }),
            $html->button($lang{DEL}, "index=$index$pages_qs&tt=$TI_ID&del=$line2->[0]&subf=$FORM{subf}", { MESSAGE => "$lang{DEL} [$line2->[0]]?", class => 'del' })
          );
        }

        my $table_traf = $table2->show();

        $table->addtd($table->td("$table_traf", { bgcolor => $_COLORS[2], colspan => 7 }));
      }

    }

    print $table->show();
  }
  elsif ($FORM{TP_ID}) {
    $FORM{subf} = $index;
    # if (defined( &dv_tp )) {
    #   dv_tp();
    # }
    # els
    if (defined( &internet_tp )) {
      internet_tp();
    }

    return 0;
  }

  _error_show($tarif_plan);

  my $table = $html->table({
    width       => '100%',
    title_plain => [ $lang{DAYS}, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 ],
    caption     => $lang{INTERVALS},
    rowcolor    => 'odd',
    class       => 'table table-hover table-condensed table-striped table-bordered'
  });

  for (my $i = 0 ; $i < 9 ; $i++) {
    my @hours = ();
    my ($h_b, $h_e, $color, $p);

    my $link = "&nbsp;";
    my $tdcolor;
    for (my $h = 0 ; $h < 24 ; $h++) {

      if (defined($visual_view{$i})) {
        my $day_periods = $visual_view{$i};
        foreach my $line (@$day_periods) {
          ($h_b, $h_e, $color, $p) = split(/\|/, $line, 4);
          if (($h >= $h_b) && ($h < $h_e)) {
            $tdcolor = '#' . $color;
            $link = $html->button('#', "index=$index&TP_ID=$FORM{TP_ID}&subf=$FORM{subf}&chg=$p");
            last;
          }
          else {
            $link    = "&nbsp;";
            $tdcolor = $_COLORS[1];
          }
        }
      }
      else {
        $link    = "&nbsp;";
        $tdcolor = $_COLORS[1];
      }

      push(@hours, $table->td("$link", { align => 'center', bgcolor => $tdcolor }));
    }

    $table->addtd($table->td($DAY_NAMES[$i]), @hours);
  }

  print $table->show();

  $index = get_function_index('form_intervals');
  if (defined($FORM{tt})) {
    my %TT_IDS = (
      0 => "Global",
      1 => "Extended 1",
      2 => "Extended 2"
    );

    if ($max_traffic_class_id >= 2) {
      for (my $i = 3 ; $i < $max_traffic_class_id + 2 ; $i++) {
        $TT_IDS{$i} = "Extended $i";
      }
    }

    $tarif_plan->{SEL_TT_ID} = $html->form_select(
      'TT_ID',
      {
        SELECTED => $tarif_plan->{TT_ID} || 0,
        SEL_HASH => \%TT_IDS,
      }
    );

    $tarif_plan->{NETS_SEL} =  $html->form_select(
      'NET_ID',
      {
        SELECTED       => $tarif_plan->{NET_ID} // 1 // 0,
        SEL_LIST       => $tarif_plan->traffic_class_list({%LIST_PARAMS, COLS_NAME => 1 }),
        MAIN_MENU      => get_function_index( (in_array('Internet', \@MODULES)) ? 'internet_traffic_classes' : 'dv_traffic_classes'),
        SEL_OPTIONS    => { '' => '--' },
        MAIN_MENU_ARGV => "chg=". ($tarif_plan->{NET_ID} || '')
      }
    );

    if(in_array('Internet', \@MODULES)) {
      $html->tpl_show(_include('internet_tt', 'Internet'), $tarif_plan);
    }
    # else {
    #   $html->tpl_show(_include('dv_tt', 'Dv'), $tarif_plan);
    # }
  }
  else {
    my $day_id = $FORM{day} || $tarif_plan->{TI_DAY} || $FORM{TI_DAY};
    $tarif_plan->{SEL_DAYS} = $html->form_select(
      'TI_DAY',
      {
        SELECTED     => $day_id,
        SEL_ARRAY    => \@DAY_NAMES,
        ARRAY_NUM_ID => 1
      }
    );

    $html->tpl_show(templates('form_ti'), $tarif_plan);
  }

  return 1;
}


#**********************************************************
=head2 form_prog_pathes() -

=cut
#**********************************************************
sub form_prog_pathes {
  # list of programs
  my @PROGS_ARR = ("WEB_SERVER_USER", "APACHE_CONF_DIR", "RADIUS_CONF_DIR",
                   "RESTART_MYSQL", "RESTART_RADIUS", "RESTART_APACHE", "RESTART_DHCP", "RESTART_MPD",
                   "PING", "MYSQLDUMP", "GZIP", "SSH", "SCP", "CURL", "SUDO", "ARP");

  if ($FORM{action} && $FORM{action} eq "change") {
    if(!$conf{PUBLIC_MODE}){
      my $filename = "$conf{TPL_DIR}/programs.tpl";
      if (open(my $fh, '+>', $filename) ) {
        for (my $i = 0 ; $i < $#PROGS_ARR ; $i++) {
          if ($FORM{$PROGS_ARR[$i]} =~ /^([\/A-Za-z0-9_\.\-]+)/) {
            my $r = $1;
            print $fh "$PROGS_ARR[$i]=$r\n";
          }
        }
        close($fh);
      }
      else {
        $html->message('err', $lang{ERROR}, "'$filename' $!");
      }
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{ERROR_PUBLIC_MODE});
    }
  }

  # file which exist
  my $filename = (-e "$conf{TPL_DIR}/programs.tpl") ? "$conf{TPL_DIR}/programs.tpl" : "$conf{base_dir}/AXbills/programs";

  my %pathes = ();
  if (-e $filename) {
    %pathes = %{ startup_files( { TPL_DIR => $conf{TPL_DIR} } ) };
  }
  else {
    $html->message('err', $lang{ERROR}, "$lang{NOT_EXIST}: '$filename'");
  }

  $html->tpl_show(
      templates('form_prog_pathes'),
      {
        PANEL_HEADING   => "$lang{PATHES}",
        FILE_NAME       => $filename,
        ACTION          => 'change',
        SUBMIT_BTN_NAME => "$lang{CHANGE}",
        %pathes
      });

  return 1;
}

#**********************************************************
=head2 admin_menu($attr) - show admin menu functions list

  Arguments:
    attr      -

  Returns:

=cut
#**********************************************************
sub admin_menu {

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{FUNCTION},
    title_plain => [ 'ID', $lang{NAME}, $lang{FUNCTION} ],
    ID          => 'FUNCTIONS_LIST'
  });

  my @keys = ();
  foreach my $key (keys %functions){
    push @keys, $key if ($key =~ /^\d+$/ );
  }
  @keys = sort {$a <=> $b} @keys;

  foreach my $ID (@keys){
    $table->addrow($ID, $menu_names{$ID}, $functions{$ID});
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 client_menu($attr) - show client menu functions

  Arguments:
    attr      -

  Returns:

=cut
#**********************************************************
sub client_menu {

  admin_menu();

  return 1;
}

#**********************************************************
=head2 organization_info()

  Returns:

=cut
#**********************************************************
sub organization_info {
  my %info;

  my %name_form = (
    ORGANIZATION_ADDRESS                      => 0,
    ORGANIZATION_FAX                          => 0,
    ORGANIZATION_MAIL                         => 0,
    ORGANIZATION_NAME                         => 0,
    ORGANIZATION_PHONE                        => 0,
    ORGANIZATION_CURRENT_ACCOUNT              => 0,
    ORGANIZATION_ID_CODE                      => 0,
    ORGANIZATION_BANK_NAME                    => 0,
    ORGANIZATION_BANK_NUM                     => 0,
    ORGANIZATION_SUPPORT_TECH                 => 0,
    ORGANIZATION_SUPPORT_INFO                 => 0,
    ORGANIZATION_CUSTOM_DEPART_LEGAL_ENTITIES => 0,
    ORGANIZATION_CUSTOM_DEPART_PHYS_PERSON    => 0,
    ORGANIZATION_WEB_SITE                     => 0,
    ORGANIZATION_ADDITIONAL_INFO              => 0,
  );

  if ($FORM{chg_form}) {
    $info{BUTTON_NAME} = 'chg';
    $info{ACTION} = "$lang{CHANGE}";
    $info{OLD_PARAM} = $FORM{chg_form};
    $info{PARAM} = $FORM{chg_form};
    $info{VALUE} = $FORM{chg_form_value};
    $info{TAGS_PANEL} = $html->element('p', $FORM{chg_form}, { class => 'col-form-label' }); #need col-form-label to vertically align this text with label
    $info{VALUE_INPUT} = $html->form_input('VALUE', $FORM{chg_form_value}, { TYPE => 'text' });
    $info{TAGS_PANEL} = $FORM{chg_form};
    $Conf->config_info($FORM{change});

    $html->tpl_show(templates('form_information_about_organization'), \%info);
  }

  if ($FORM{chg}) {
    $Conf->config_change(
      '',
      {
        VALUE                => $FORM{VALUE},
        PARAM                => $FORM{OLD_PARAM},
        WITHOUT_PARAM_CHANGE => 1,
      }
    );
  }
  elsif ($FORM{add}) {
    if ($FORM{PARAM}) {
      $FORM{PARAM} = $FORM{PARAM} !~ m/ORGANIZATION_/ ? 'ORGANIZATION_' . $FORM{PARAM} : $FORM{PARAM};
    }
    $Conf->config_add(\%FORM);
  }
  elsif ($FORM{del}) {
    $Conf->config_del($FORM{del});
  }

  if ($FORM{add_form}) {
    $info{BUTTON_NAME} = 'add';
    $info{ACTION} = "$lang{ADD}";
    $info{TAGS_PANEL} = $html->form_input(
      'PARAM',
      '%PARAM%',
      {
        TYPE     => 'text',
        class    => 'form-control',
        required => ''
      }
    );

    $html->tpl_show(templates('form_information_about_organization'), \%info);
  }

  my $value_list = $Conf->config_list({
    COLS_NAME => 1,
    CUSTOM    => 1
  });

  my $table = $html->table({
    width       => '100%',
    caption     => $html->element('i', '', { class => 'fa fa-fw fa-tags' }) . $lang{ORGANIZATION_INFO},
    title_plain => [ $lang{TAGS}, $lang{VALUE} ],
    ID          => 'ORGANIZATION_INFO',
    MENU        => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
  });

  foreach my $line (@$value_list) {
    $table->addrow($line->{param},
      $line->{value},
      $html->button($lang{CHANGE}, "index=$index&chg_form=$line->{param}&chg_form_value=$line->{value}", { class => 'change' }),
      $html->button($lang{DEL}, "index=$index&del=$line->{param}", { MESSAGE => "$lang{DEL} [$line->{param}]", class => 'del' }));
    if (!($name_form{ $line->{param} })) {
      $name_form{"$line->{param}"} = 1;
    }
  }

  foreach my $name (keys %name_form) {
    if ($name_form{$name} == 0) {
      $Conf->config_add(
        {
          PARAM => "$name",
          VALUE => ''
        }
      );
    }
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_payment_types()

  Arguments:
    attr      -

  Returns:

=cut
#**********************************************************
sub form_payment_types {
  require Payments;
  Payments->import();
  my $Payments = Payments->new($db, $admin, \%conf);
  my %info;

  $info{BUTTON_LABALE} = 'add';
  $info{BUTTON_NAME}   = $lang{ADD};

  if ($FORM{add}) {
    if ($FORM{DEFAULT_PAYMENT}) {
      $Payments->payment_default_type();
    }

    $FORM{ID} = $FORM{NEW_ID};
    $Payments->payment_type_add(\%FORM);
  }
  elsif ($FORM{change}) {
    if ($FORM{DEFAULT_PAYMENT}) {
      $Payments->payment_default_type();
    }

    $Payments->payment_type_change(\%FORM);
  }
  elsif (defined($FORM{chg})) {
    $info{BUTTON_LABALE} = 'change';
    $info{BUTTON_NAME}   = $lang{CHANGE};
    $info{ID}            = $FORM{chg};

    my $payment_type = $Payments->payment_type_info(
      {
        ID => $FORM{chg},
      }
    );

    $info{NAME}  = _translate($payment_type->{NAME});
    $info{COLOR} = $payment_type->{COLOR};
    $info{CHECK_DEFAULT} = 'checked' if ($payment_type->{DEFAULT_PAYMENT});
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Payments->payment_type_del({ ID => $FORM{del} });
  }

  _error_show($Payments);

  $info{ADMIN_PAY} = $lang{ADMIN_PAY};
  $info{FEES_TYPE} = $html->form_select(
    'FEES_TYPE',
    {
      SELECTED      => $Payments->{FEES_TYPE} || 0,
      SEL_HASH      => get_fees_types(),
      NO_ID         => 1,
      SORT_KEY_NUM  => 1,
      MAIN_MENU     => get_function_index('form_fees_types'),
    }
  );

  $info{ ALLOW_SET_ID } = $info{ID} ? 'disabled' : '';

  $html->tpl_show(templates('form_payments_add_type'), \%info);
  my $types = translate_list($Payments->payment_type_list({ COLS_NAME => 1 }));

  foreach my $default_type (@$types) {
    $default_type->{default_payment} = $html->element('label', '', { class => 'fa fa-check' }) if ($default_type->{default_payment});
  }

  my $fees_types = get_fees_types();
  $fees_types->{0}=q{-};

  result_former(
    {
      INPUT_DATA      => $Payments,
      LIST            => $types,
      BASE_FIELDS     => 5,
      FUNCTION_FIELDS => 'change, del',
      DEFAULT_FIELDS  => 'ID,NAME,COLOR,DEFAULT_PAYMENT,FEES_TYPE',
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        id              => 'ID',
        name            => $lang{NAME},
        color           => $lang{COLOR},
        default_payment => $lang{DEFAULT},
        fees_type       => $lang{FEES}
      },
      SELECT_VALUE    => {
        fees_type => $fees_types
      },
      TABLE => {
        width   => '100%',
        caption => $lang{PAYMENT_METHOD},
        ID      => 'PAYMENTS_TYPE_LIST',
        EXPORT  => 1,
      },
      MAKE_ROWS => 1,
      TOTAL     => 1
    }
  );

  return 1;
}

#**********************************************************
=head2 form_feedback()

=cut
#**********************************************************
sub form_feedback {
  if(! $conf{SYS_ID}) {
    system_info();
  }

  my $sys_id = $conf{SYS_ID} || '';
  my $version = get_version();

  $html->tpl_show(templates('form_feedback'),{
    SYS_ID  => $sys_id,
    VERSION => $version
  });

  return 1;
}

#**********************************************************
=head2 info_fields_new()

=cut
#**********************************************************
sub info_fields_new {
  require Info_fields;
  require AXbills::Experimental;
  my $Info_fields = Info_fields->new($db, $admin, \%conf);

  my @fields_types = (
    'String',
    'Integer',
    $lang{LIST},
    $lang{TEXT},
    'Flag',
    'Blob',
    'PCRE',
    'AUTOINCREMENT',
    'ICQ',
    'URL',
    'PHONE',
    'E-Mail',
    'Skype',
    $lang{FILE},
    $lang{DELIVERY},
    'PHOTO',
    'SOCIAL NETWORK',
    'Crypt',
    $lang{LANGUAGE},
    'Time zone',
    $lang{DATE},
  );
  my @bool = ($lang{NO}, $lang{YES});

  my %TEMPLATE_ADVERTISEMENT = ();
  my $show_add_form = $FORM{add_form} || 0;
  my $chg_list = ();
  if ($FORM{add}) {
    if (!$FORM{SQL_FIELD}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (SQL_FIELD)");
    }
    elsif (length($FORM{SQL_FIELD}) > 20) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (Length > 20)");
    }
    else {
      $users->info_field_add({
        POSITION               => $FORM{PRIORITY},
        FIELD_TYPE             => $FORM{TYPE},
        USERS_PORTAL           => $FORM{ABON_PORTAL},
        FIELD_ID               => $FORM{SQL_FIELD},
        CAN_BE_CHANGED_BY_USER => $FORM{USER_CHG},
        NAME                   => $FORM{NAME},
        COMPANY_ADD            => $FORM{COMPANY},
      });
      $Info_fields->fields_add({ %FORM });
      $show_add_form = !show_result($Info_fields, $lang{ADDED});
    }
  }
  elsif ($FORM{change}) {
    $Info_fields->fields_change({ %FORM });
    show_result($Info_fields, $lang{CHANGED});
  }
  elsif ($FORM{chg}) {
    $show_add_form = 1;
    $chg_list = $Info_fields->fields_list({ ID => $FORM{chg} });
    if ($chg_list->[0]) {
      $chg_list->[0]{REQUIRED} = 'checked' if $chg_list->[0]{REQUIRED};
      $chg_list->[0]{ABON_PORTAL} = 'checked' if $chg_list->[0]{ABON_PORTAL};
      $chg_list->[0]{USER_CHG} = 'checked' if $chg_list->[0]{USER_CHG};
    }
    $TEMPLATE_ADVERTISEMENT{READONLY} = 'readonly';
    $TEMPLATE_ADVERTISEMENT{READONLY2} = 'disabled';
    $TEMPLATE_ADVERTISEMENT{TYPE_SELECT} = $html->element('input', '', {
      readonly => 'readonly',
      type     => 'text',
      class    => 'form-control',
      value    => ($chg_list->[0]) ? $fields_types[$chg_list->[0]->{type}] : q{},
    });
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    my $list = $Info_fields->fields_list({ ID => $FORM{del} });
    $Info_fields->fields_del($FORM{del}, COMMENTS => $FORM{COMMENTS});
    $users->info_field_del({
      FIELD_ID => $list->[0]->{SQL_FIELD},
      SECTION  => ($list->[0]->{COMPANY} ? 'ifc' : 'ifu'),
    });
    show_result($Info_fields, $lang{DELETED});
  }
  _error_show($Info_fields);

  if ($show_add_form) {
    $TEMPLATE_ADVERTISEMENT{TYPE_SELECT} //= $html->form_select('TYPE', {
      SELECTED     => $chg_list->[0]->{type} || 0,
      SEL_ARRAY    => \@fields_types,
      ARRAY_NUM_ID => 1,
      SEL_OPTIONS  => { '' => '' }
    });

    $html->tpl_show(templates('form_info_fields'), {
      %TEMPLATE_ADVERTISEMENT,
      %{($chg_list->[0]) ? $chg_list->[0] : {}},
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });
  }

  my @header_arr = (
    "$lang{ALL}:index=$index&ALL_FIELDS=1",
    "$lang{USERS}:index=$index&USR_FIELDS=1",
    "$lang{COMPANY}:index=$index&COMPANY_FIELDS=1",
  );

  my $status_bar = $html->table_header(\@header_arr);

  if ($FORM{update_table}) {
    my $usr_list = $Conf->config_list({ PARAM => 'ifu*', SORT => 2 });
    foreach my $line (@$usr_list) {

      my $field_name = '';

      if ($line->[0] =~ /ifu\_(\S+)/) {
        $field_name = $1;
      }

      my ($position, $field_type, $name, $user_portal, $can_be_changed_by_user) = split(/:/, $line->[1]);
      $can_be_changed_by_user = ($can_be_changed_by_user) ? 1 : 0;
      if (!defined($field_type)) {
        $field_type = 0;
      }

      $Info_fields->fields_add({
        NAME        => $name,
        SQL_FIELD   => $field_name,
        TYPE        => $field_type,
        PRIORITY    => $position,
        ABON_PORTAL => $user_portal,
        USER_CHG    => $can_be_changed_by_user
      });
    }
    my $company_list = $Conf->config_list({ PARAM => 'ifc*', SORT => 2 });

    foreach my $line (@$company_list) {
      my $field_name = '';

      if ($line->[0] =~ /ifc\_(\S+)/) {
        $field_name = $1;
      }
      my ($position, $field_type, $name, $user_portal) = split(/:/, $line->[1]);

      if (!defined($field_type)) {
        $field_type = 0;
      }

      $user_portal ||= 0;

      $Info_fields->fields_add({
        NAME        => $name,
        SQL_FIELD   => $field_name,
        TYPE        => $field_type,
        PRIORITY    => $position,
        ABON_PORTAL => $user_portal,
        COMPANY     => 1
      });
    }

    show_result($Info_fields, $lang{CHANGED});
  }

  if ($FORM{USR_FIELDS}) {
    $LIST_PARAMS{COMPANY} = 0;
  }
  elsif ($FORM{COMPANY_FIELDS}) {
    $LIST_PARAMS{COMPANY} = 1;
  }
  $LIST_PARAMS{NOT_ALL_FIELDS} = 1;

  result_former({
    INPUT_DATA      => $Info_fields,
    FUNCTION        => 'fields_list',
    DEFAULT_FIELDS  => 'ID,NAME,SQL_FIELD,TYPE,PRIORITY,ABON_PORTAL,USER_CHG,REQUIRED,COMPANY,MODULE,COMMENT',
    HIDDEN_FIELDS   => 'PATTERN,TITLE,ID',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id          => '#',
      name        => $lang{NAME},
      sql_field   => 'SQL_FIELD',
      type        => $lang{TYPE},
      priority    => $lang{PRIORITY},
      abon_portal => $lang{USER_PORTAL},
      user_chg    => $lang{USER} . $lang{CHANGE},
      company     => $lang{COMPANY},
      required    => $lang{REQUIRED_FIELD},
      module      => $lang{MODULE},
      comment     => $lang{COMMENTS},
    },
    FILTER_VALUES   => {
      type => sub {
        my (undef, $line) = @_;
        if ($line->{type} == 2) {
          $html->button($fields_types[2], "index=" . ($index + 1) . "&LIST_TABLE=$line->{sql_field}" . '_list');
        }
        else {
          $fields_types[$line->{type}];
        }
      }
    },
    SELECT_VALUE    => {
      abon_portal => { 0 => $bool[0], 1 => $bool[1] },
      user_chg    => { 0 => $bool[0], 1 => $bool[1] },
      company     => { 0 => $bool[0], 1 => $bool[1] },
      required    => { 0 => $bool[0], 1 => $bool[1] }
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{INFO_FIELDS},
      ID      => 'INFO_FIELDS',
      header  => $status_bar,
      MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add; :index=$index&update_table=1&$pages_qs:fa fa-reply mt-1 ml-1",
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

1
