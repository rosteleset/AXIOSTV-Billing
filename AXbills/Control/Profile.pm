
=head1 NAME

  Admin Profile

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array mk_unique_value encode_base64);

our (
  $admin,
  $db,
  %lang,
  %LANG,
  %permissions,
  %module
);

our AXbills::HTML $html;

#**********************************************************
=head2 admin_profile() - Admin profile configuration

=cut
#**********************************************************
sub admin_profile {

  _admin_info_change();

  require Control::Quick_reports;
  my $quick_reports = form_quick_reports();

  if (! $quick_reports) {
    return 1;
  }

  my $SEL_LANGUAGE = $html->form_select('language', {
    SELECTED => $html->{language},
    SEL_HASH => \%LANG
  });

  # Events groups
  my $events_groups_select = '';
  my $events_groups_show = 'hidden';
  if (in_array('Events', \@MODULES)){
    require Events;
    Events->import();

    my $Events = Events->new($db, $admin, \%conf);
    my $this_admin_groups = $Events->groups_for_admin($admin->{AID}) || '';
    _error_show($Events);

    my $group_link = '';
    if (my $group_index = get_function_index('events_group')){
      $group_link = "?index=$group_index";
    };

    $events_groups_select = _events_group_select({
      SELECTED  => $this_admin_groups || '',
      MULTIPLE  => 1,
      MAIN_MENU => $group_link,
    });
    $events_groups_show = '';
  }


  # download avatar to DB
  if ($FORM{UPLOAD_FILE}){
    my $name_value = mk_unique_value(10);
    my $file_name = 'avatar_'.$admin->{AID}.'_'.$name_value.'.png';

    my $allowed_picture_size = 500000;

    if ($FORM{UPLOAD_FILE} && $FORM{UPLOAD_FILE}{Size} && $FORM{UPLOAD_FILE}{Size} <= $allowed_picture_size){
      my $is_uploaded = upload_file($FORM{UPLOAD_FILE},
      {
        FILE_NAME => $file_name,
        EXTENTIONS => 'gif, png, jpg, jpeg',
        REWRITE   => 1
      });

      if($is_uploaded ){
        $admin->change({ AID => $admin->{AID}, AVATAR_LINK => $file_name});
      }
    }
    else {
      $html->message('err', $lang{ERROR}, "$lang{PICTURE_SIZE_NOT_ALLOWED} 500 Kb");
    }

  }

  my $subscribe_mng_block = _profile_get_admin_sender_subscribe_block($admin->{AID});

  my $auth_history = _admin_auth_history_table();

  $html->tpl_show(templates('form_admin_profile'), {
    QUICK_REPORTS        => $quick_reports,
    SEL_LANGUAGE         => $SEL_LANGUAGE,
    NO_EVENT             => $admin->{SETTINGS}->{NO_EVENT},
    NO_EVENT_SOUND       => $admin->{SETTINGS}->{NO_EVENT_SOUND},
    RIGHT_MENU_HIDDEN    => $admin->{SETTINGS}->{RIGHT_MENU_HIDDEN},
    SUBSCRIBE_BLOCK      => $subscribe_mng_block,
    HIDE_SUBSCRIBE_BLOCK => !$subscribe_mng_block ? 'd-none' : '',
    EVENT_GROUPS_SELECT  => $events_groups_select,
    EVENTS_GROUPS_HIDDEN => $events_groups_show,
    AUTH_HISTORY         => $auth_history,
  });

  _form_profile_search();

  return 1;
}

#**********************************************************
=head2 admin_auth_history_table() -

=cut
#**********************************************************
sub _admin_auth_history_table {

  return '' if (!$conf{PROFILE_AUTH_HISTORY});

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{AUTH_HISTORY},
    title_plain => [ $lang{DATE}, 'IP' ],
    ID          => 'AUTH_HISTORY'
  });

  my $logs = $admin->full_log_list({
    AID           => $admin->{AID},
    PAGE_ROWS     => 5,
    IP            => '_SHOW',
    DATETIME      => '_SHOW',
    FUNCTION_NAME => 'ADMIN_AUTH',
    COLS_NAME     => 1,
    DESC          => 'DESC'
  });

  foreach my $log (@{$logs}) {
    $table->addrow(
      $log->{datetime} || '--',
      $log->{ip} || '--'
    );
  }

  return $table->show();
}

#**********************************************************
=head2 form_profile_search($attr) -
=cut
#**********************************************************
sub _form_profile_search {
  my ($attr) = @_;

  if ($FORM{change_search}) {
    my $search_fields = $FORM{SEARCH_FIELDS} || q{};
    $admin->{SETTINGS}{SEARCH_FIELDS} = $search_fields;
    my $web_option = '';
    while(my($k, $v) = each %{ $admin->{SETTINGS} } ) {
      $web_option .= "$k=$v;" if (defined($v));
    }

    $admin->change({ AID => $admin->{AID}, WEB_OPTIONS => $web_option });
    $html->message('info', $lang{INFO}, "$lang{CHANGED} $search_fields");
    $admin->{SETTINGS}{SEARCH_FIELDS} = $search_fields;
  }

  our @default_search;
  if ($admin->{SETTINGS} && $admin->{SETTINGS}{SEARCH_FIELDS} ) {
    @default_search = split(/,\s+/, $admin->{SETTINGS}{SEARCH_FIELDS});
  }

  my %search_fields = (
    UID             => 'UID',
    BILL_ID         => $lang{BILL},
    LOGIN           => $lang{LOGIN},
    FIO             => $lang{FIO},
    CONTRACT_ID     => $lang{CONTRACT},
    EMAIL           => 'E-mail',
    PHONE           => $lang{PHONE},
    COMMENTS        => $lang{COMMENTS},
    ADDRESS_FULL    => $lang{ADDRESS},
    ADDRESS_STREET2 => $lang{SECOND_NAME},
    ENTRANCE        => $lang{ENTRANCE},
    ADDRESS_FLAT    => $lang{ADDRESS_FLAT},
    TELEGRAM        => 'Telegram',
    VIBER           => 'Viber',
  );

  #Get info fields
  my $prefix = $attr->{COMPANY} ? 'ifc*' : 'ifu*';
  my $list = $Conf->config_list({ PARAM => $prefix, SORT => 2 });

  my $field_id = '';
  foreach my $line (@$list) {
    if ($line->[0] =~ /$prefix(\S+)/) {
      $field_id = $1;
    }

    my (undef, undef, $name, undef) = split(/:/, $line->[1]);
    my $field_name = uc($field_id);
    $search_fields{$field_name}=_translate($name);
  }

  my $table = $html->table({
    width      => '400',
    caption    => "$lang{SEARCH} $lang{FIELDS}",
    cols_align => [ 'left', 'right', ],
    ID         => 'SEARCH_FIELDS'
  });

  foreach my $key (sort keys %search_fields) {
    $table->addrow( $html->form_input('SEARCH_FIELDS', $key, { TYPE => 'checkbox', STATE => (in_array($key, \@default_search)) ? 'ckecked' : undef }),
      $search_fields{$key}
    );
  }

  print $html->form_main({
    class   => 'form pb-3',
    CONTENT => $table->show(),
    HIDDEN  => { index => $index },
    SUBMIT  => { change_search => "$lang{CHANGE}" },
    ID      => 'FORM_SEARCH_FIELDS'
  });

  return 1;
}

#**********************************************************
=head2 flist() - Functions list

=cut
#**********************************************************
sub flist {

  my %new_hash = ();
  while ((my ($findex, $hash) = each(%menu_items))) {
    while (my ($parent, $val) = each %$hash) {
      $new_hash{$parent}{$findex} = $val;
    }
  }

  my $h          = $new_hash{0};
  my @last_array = ();

  my @menu_sorted = sort { $b <=> $a } keys %$h;
  my %qm = ();
  if ($admin->{SETTINGS} && $admin->{SETTINGS}->{qm}) {
    my @a = split(/,/, $admin->{SETTINGS}->{qm});
    foreach my $line (@a) {
      my ($id, $custom_name) = split(/:/, $line, 2);
      $qm{$id} = ($custom_name) ? $custom_name : '';
    }
  }

  my $table = $html->table({
    width      => '100%',
    cols_align => [ 'right', 'left', 'right', 'right', 'left', 'left', 'right' ],
    ID         => 'PROFILE_FUNCTION_LIST'
  });

  my ($mi, $tag_count, $form_tags_sel);

  if (in_array('Tags', \@MODULES)) {
    load_module('Tags');
    ($form_tags_sel, $tag_count) = tags_sel({ HASH => 1 });
  }

  for (my $parent = 0 ; $parent <= $#menu_sorted ; $parent++) {
    my $val    = $h->{$parent};
    my $level  = 0;
    my $prefix = '';
    $table->{rowcolor} = 'active';

    next if (!defined($permissions{ ($parent - 1) }));
    $table->addrow("$level:", "$parent >> " . $html->button($html->b($val), "index=$parent") . "<<", '') if ($parent != 0);

    if (defined($new_hash{$parent})) {
      $table->{rowcolor} = undef;
      $level++;
      $prefix .= "&nbsp;&nbsp;&nbsp;";
      label:
      my $k;
      while (($k, $val) = each %{ $new_hash{$parent} }) {
      #foreach $k ( keys %{ $new_hash{$parent} } ) {
        $val = $new_hash{$parent}{$k};
        my $checked = undef;
        if (defined($qm{$functions{ $k }})) {
          $checked = 1;
          $val     = $html->b($val);
        }

        $table->addrow(
          "$k "
            . $html->form_input(
            'qm_item',
            $functions{ $k }, # $k,
            {
              TYPE          => 'checkbox',
              OUTPUT2RETURN => 1,
              STATE         => $checked
            }
          ),
          $prefix .' '. $html->button($val, "index=$k") . (($module{$k}) ? ' ('. $module{$k} .') '. $functions{ $k }  : ''),
          $html->form_input("qm_name_$k", $qm{$k}, { OUTPUT2RETURN => 1 })
        );

        if (defined($new_hash{$k})) {
          $mi = $new_hash{$k};
          $level++;
          $prefix .= "&nbsp;&nbsp;&nbsp;";
          push @last_array, $parent;
          $parent = $k;
        }
        delete($new_hash{$parent}{$k});
      }

      if ($#last_array > -1) {
        $parent = pop @last_array;
        $level--;

        $prefix = substr($prefix, 0, $level * 6 * 3);
        goto label;
      }
      delete($new_hash{0}{$parent});
    }
  }
  $admin->{SETTINGS}->{ql} //= '';
  my $i = 1;
  foreach my $ql (split(/,/, $admin->{SETTINGS}->{ql})) {
    my ($ql_name, $ql_url) = split(/\|/, $ql, 2);
    $table->addrow(
      '',
      $html->form_input("ql_url_$i", $ql_url, { OUTPUT2RETURN => 1 }),
      $html->form_input("ql_name_$i", $ql_name, { OUTPUT2RETURN => 1 })
    );
    $i++;
  }

  $table->addrow(
    '',
    $html->form_input("ql_url_$i", '', { EX_PARAMS => "placeholder='External link'", OUTPUT2RETURN => 1 }),
    $html->form_input("ql_name_$i", '', { EX_PARAMS => "placeholder='Link name'", OUTPUT2RETURN => 1 })
  );

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      index        => $index,
      AWEB_OPTIONS => 1,
    },
    SUBMIT  => {
      quick_set => $lang{SET}
    }
  });

  return 1;
}

#**********************************************************
=head2 form_slides_create() - Create slides

=cut
#**********************************************************
sub form_slides_create {

  require Control::Users_slides;

  my ($base_slides, $active_slides) = form_slides_info();

  my $content = '';

  for(my $slide_num=0;  $slide_num <=  $#{ $base_slides }; $slide_num++  ) {
    my $slide_name   = $base_slides->[$slide_num]->{ID} || q{};
    my $table = $html->table({
        caption => "$slide_name - ". ($base_slides->[$slide_num]{HEADER} || q{}),
        ID      => $slide_name,
        width   => '300',
      }
    );

    my $slide_fields = $base_slides->[$slide_num]{FIELDS};
    my $slide_size = $html->form_select('s_'.$slide_name,
      {
        SELECTED    => 1, #($active_slides->{$slide_name} && $active_slides->{$slide_name}{'SIZE'}) ? $active_slides->{$slide_name}{'SIZE'} : 1,
        SEL_HASH    => { 1 => 1,
          2 => 2,
          3 => 3,
          4 => 4
        },
        NO_ID       => 1
      });

    if ( scalar keys %{ $active_slides } == 0 || ( $slide_name && $active_slides->{$slide_name})) {
      $table->{rowcolor}='info';
    }

    $table->addrow('',
      $html->form_input('ENABLED', $slide_name, { TYPE => 'checkbox', STATE => (scalar keys %$active_slides == 0 || $active_slides->{$slide_name}) ? 'checked' : ''}  ). ' '. $lang{ENABLE},
      $lang{PRIORITY} .':'. $html->form_input('p_'.$slide_name,  ($active_slides->{$slide_name}) ? $active_slides->{$slide_name}{'PRIORITY'} : '' ),
      $lang{SIZE} .':'. $slide_size
    );

    delete($table->{rowcolor});

    foreach my $field_name ( keys %{ $slide_fields } ) {
      $table->addrow(
        $html->form_input($slide_name.'_'. $field_name, '1', { TYPE => 'checkbox', STATE => ( ( $active_slides->{$slide_name} && $active_slides->{$slide_name}{$field_name} )  ) ? 'checked' : '' }),
        $slide_fields->{$field_name},
        $html->form_input('w_'.$slide_name.'_'. $field_name, ($active_slides->{$slide_name}) ? $active_slides->{$slide_name}{'w_'.$field_name} : '' , { EX_PARAMS => "placeholder='$lang{WARNING}'"  }),
        $html->form_input('c_'.$slide_name.'_'. $field_name, ($active_slides->{$slide_name}) ? $active_slides->{$slide_name}{'c_'.$field_name} : '' , { EX_PARAMS => "placeholder='$lang{COMMENTS}'" }),
      );
    }

    $content .= $table->show({ OUTPUT2RETURN => 1 });
  }

  print $html->form_main({
    CONTENT => $content,
    HIDDEN  => {
      SLIDES => join(',', @$base_slides),
      index  => $index,
    },
    SUBMIT  => { action => "$lang{CHANGE}" }
  });

  return 1;
}

#**********************************************************
=head2 _profile_get_admin_sender_subscribe_block()

=cut
#**********************************************************
sub _profile_get_admin_sender_subscribe_block {
  my ($aid) = @_;
  return '' unless ($aid);

  my $col_size = 12;
  my @buttons_html = ();

  if ($conf{PUSH_ENABLED}) {
    push @buttons_html, _make_subscribe_btn('Push', 'js-push-icon fa fa-bell', {
      ENABLE_PUSH           => $lang{ENABLE_PUSH},
      DISABLE_PUSH          => $lang{DISABLE_PUSH},
      PUSH_IS_NOT_SUPPORTED => $lang{PUSH_IS_NOT_SUPPORTED},
      PUSH_IS_DISABLED      => $lang{PUSH_IS_DISABLED},
    }, {
      BUTTON_CLASSES => 'js-push-button btn-info',
      TEXT_CLASS     => 'js-push-text'
    });
    # (un)subscribe is made via Javascript
  }

  my %allowed_subscribes = (
    TELEGRAM   => $conf{TELEGRAM_TOKEN},
    VIBER      => $conf{VIBER_TOKEN},
    CELL_PHONE => in_array('Sms', \@MODULES)
  );

  require Contacts;

  my @types_to_search = grep {$allowed_subscribes{$_}} keys %allowed_subscribes;
  return join('', map { $col_size && $_ ? "<div class='col-md-$col_size'>$_</div>" : $_ } @buttons_html)
    unless ( @types_to_search );

  if ($FORM{REMOVE_SUBSCRIBE}) {
    $admin->admin_contacts_del({
      AID => $aid,
      ID  => $FORM{REMOVE_SUBSCRIBE}
    });

    if (!_error_show($admin)) {
      $html->message('info', "$lang{UNSUBSCRIBE_FROM} $FORM{REMOVE_SUBSCRIBE}", $lang{SUCCESS})
    }
  }

  my $contacts_list = $admin->admins_contacts_list({
    AID   => $admin->{AID},
    TYPE  => join(';', map {$Contacts::TYPES{$_}} @types_to_search),
    VALUE => '_SHOW'
  });
  _error_show($admin);

  push @buttons_html, _telegram_button($contacts_list);
  push @buttons_html, _telegram_admin_button($contacts_list);

  if($conf{VIBER_TOKEN} && $conf{VIBER_BOT_NAME}){
    # Check if subscribed
    my $viber_cont = 0;
    foreach my $contact (@{$contacts_list}) {
      if ($contact->{type_id} == $Contacts::TYPES{VIBER}) {
        $viber_cont = $contact->{id};
        last;
      }
    }

    if (!$viber_cont) {
      if ($conf{VIBER_BOT_NAME}) {
        my $link_url = 'viber://pa?chatURI=' . $conf{VIBER_BOT_NAME} . '&context=a_' . ($admin->{SID} || $sid || $admin->{sid}).'&text=/start';
        push @buttons_html, _make_subscribe_btn(
          'Viber',
          'fa fa-phone',
          undef,
          {
            HREF => $link_url
          }
        );
      }
    } else {
      push @buttons_html, _make_subscribe_btn('Viber', 'fa fa-phone', undef, {
        HREF           => "$SELF_URL/admin/index.cgi?index=9&REMOVE_SUBSCRIBE=$viber_cont",
        UNSUBSCRIBE    => 1,
        BUTTON_CLASSES => 'btn-success'
      });
    }
  }

  my $subscribe_block = join('', map { $col_size && $_ ? "<div class='col-md-$col_size'>$_</div>" : $_ } @buttons_html);

  return $subscribe_block;
}

#**********************************************************
=head2 admin_info_change() - Admin profile change

=cut
#**********************************************************
sub _admin_info_change {

  $admin->info($admin->{AID});
  if ($FORM{chg_pswd} || $FORM{newpassword}) {
    form_passwd();
    if ($FORM{PASSWORD}) {
      $admin->change({
        AID      => $admin->{AID},
        PASSWORD => $FORM{PASSWORD},
      });
    }
  }
  if ($FORM{aedit}) {
    $admin->change({
      AID   => $admin->{AID},
      # EMAIL => $FORM{email},
      A_FIO => $FORM{name},
    });

    $admin->admin_contacts_change({ AID => $admin->{AID}, TYPE_ID => 9, VALUE => $FORM{email} }) if defined $FORM{email};
  }

  if ($FORM{clear_settings}){
    $admin->settings_del();
    $admin->change({
      AID   => $admin->{AID},
      WEB_OPTIONS => '',
    });

    $html->message('info', $lang{SUCCESS});
  }
  if ($FORM{reset_schema}) {
    use Conf;
    my $Config = Conf->new($db, $admin, \%conf);
    my $left_key = 'LSCHEMA_FOR_' . $admin->{AID};
    $Config->config_del($left_key);
    my $right_key = 'RSCHEMA_FOR_' . $admin->{AID};
    $Config->config_del($right_key);
    $html->message("info", "$lang{SUCCESS}");
  }
  my $passwd_btn = $html->button($lang{CHANGE_PASSWORD}, "index=$index&chg_pswd=1", { class => 'btn btn-xs btn-primary' });
  my $clear_settings_btn = $html->button($lang{CLEAR_SETTINGS}, "index=$index&clear_settings=1", { class => 'btn btn-xs btn-danger' });

  my $G2FA = '';

  if (!$admin->{G2FA}) {
    if ($FORM{add_G2FA}) {

      require AXbills::Auth::Core;
      AXbills::Auth::Core->import();
      my $Auth = AXbills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => 'OATH'
      });

      if ($FORM{PIN}) {

        if ($Auth->check_access({ PIN => $FORM{PIN}, SECRET => $FORM{add_G2FA} })) {
          $admin->change({
            AID  => $admin->{AID},
            G2FA => $FORM{add_G2FA},
          });
          $html->redirect("?index=$index", { WAIT => 1 });
        }
        else {
          $html->message('err', $lang{ERROR}, "$lang{WRONG} PIN!");
          $html->redirect("?index=$index&add_G2FA=$FORM{add_G2FA}", { WAIT => 1 });
        }

      }
      else {
        require Control::Qrcode;
        Control::Qrcode->import();
        my $QRCode = Control::Qrcode->new($db, $admin, \%conf, { html => $html, functions => \%functions });

        my $secret = AXbills::Auth::OATH::encode_base32($FORM{add_G2FA});
        my $img_qr = $QRCode->_encode_url_to_img($secret, {
          AUTH_G2FA_NAME => $conf{WEB_TITLE} || 'AXbills',
          AUTH_G2FA_MAIL => $admin->{ADMIN},
          OUTPUT2RETURN  => 1,
          %FORM
        });

        my $qr = "<img src='data:image/jpg;base64," . encode_base64($img_qr) . "'>";

        $G2FA .= $html->element('div', "$qr", { class => 'col-md-12 text-center mb-3' });
        $G2FA .= $html->element('label', "$lang{CONFIRM} PIN: ", { class => 'control-label col-md-3', for => 'PIN' });
        $G2FA .= $html->form_input('add_G2FA', $FORM{add_G2FA}, { TYPE => 'hidden' });
        $G2FA .= $html->form_input('PIN', "", { class => 'form-control col-md-9' });
      }
    }
    else {

      $G2FA = $html->button($lang{G2FA}, "index=$index&add_G2FA=" . uc(mk_unique_value(32)), {
        class   => 'btn btn-sm col-md-12 btn-secondary',
        CONFIRM => "$lang{G2FA_ADD}?",
      });
    }
  }
  else {
    if ($FORM{remove_G2FA}) {
      $admin->change({
        AID  => $admin->{AID},
        G2FA => '',
      });
      $html->redirect("?index=$index");
    }
    else {
      $G2FA = $html->button($lang{G2FA_REMOVE}, "index=$index&remove_G2FA=1", {
        class   => 'btn btn-sm col-md-12 btn-danger',
        CONFIRM => "$lang{G2FA_REMOVE}?",
      });
    }
  }

  my $admin_emails = $admin->admins_contacts_list({
    TYPE      => 9,
    VALUE     => '!',
    AID       => $admin->{AID},
    COLS_NAME => 1
  });
  my $admin_email = $admin->{TOTAL} && $admin->{TOTAL} > 0 ? { EMAIL => $admin_emails->[0]{value} } : { EMAIL => '' };

  $html->tpl_show(templates('form_admin_info_change'), {
    %$admin,
    CHG_PSW         => $passwd_btn,
    CLEAR_SETTINGS  => $clear_settings_btn,
    G2FA            => $G2FA,
    %{$admin_email}
  });

  return 1;
}

#**********************************************************
=head2 _make_subscribe_btn() - $name, $icon_classes, $lang_vars, $attr

=cut
#**********************************************************
sub _make_subscribe_btn {
  my ($name, $icon_classes, $lang_vars, $attr) = @_;

  my $button_text = (!$attr->{UNSUBSCRIBE}) ? "$lang{SUBSCRIBE_TO} $name" : "$lang{UNSUBSCRIBE_FROM} $name";

  my $icon_html = $html->element('span', '', { class => $icon_classes, OUTPUT2RETURN => 1 });
  my $text = $html->element('strong', $button_text, { class => $attr->{TEXT_CLASS}, OUTPUT2RETURN => 1 });

  my $button = '';
  if ($attr->{HREF}) {
    my $btn_class = $attr->{BUTTON_CLASSES} || ' btn-info ';
    my $same_button = $html->element('a', $icon_html . ' ' . $text, {
      href          => $attr->{HREF},
      class         => "btn form-control $btn_class",
      target        => '_blank',
      OUTPUT2RETURN => 1
    });

    my $qr_icon = $html->element('i', '', { class => 'fa fa-qrcode', OUTPUT2RETURN => 1 });
    my $qr_button = $html->element('a', $qr_icon,
      {
        class => "btn $btn_class border-left-1",
        onclick => "showImgInModal('$SELF_URL?qrcode=1&qindex=10010&QRCODE_URL=$attr->{HREF}', '$name $lang{QR_CODE}');",
        OUTPUT2RETURN => 1
      }
    );
    $button = $html->element('div',
      $same_button.$qr_button,
      {
        class => 'btn-group w-100',
        OUTPUT2RETURN => 1
      }
    );
  }
  else {
    $button = $html->element('button', $icon_html . ' ' . $text, {
      class         => 'btn form-control ' . ($attr->{BUTTON_CLASSES} || ' btn-info '),
      OUTPUT2RETURN => 1
    });
  }

  my $lang_text = '';
  if ($lang_vars && ref $lang_vars eq 'HASH') {
    $lang_text = join "; \n", map {
      qq{window['$_'] = '$lang_vars->{$_}'};
    } keys %{$lang_vars};
  }

  my $lang_script = ($lang_text) ? $html->element('script', $lang_text) : '';

  return $button . $lang_script;
}

#**********************************************************
=head2 _telegram_button() - $contacts_list

=cut
#**********************************************************
sub _telegram_button {
  my ($contacts_list) = @_;

  return '' if !$conf{TELEGRAM_TOKEN};

  foreach my $contact (@{$contacts_list}) {
    if ($contact->{type_id} == $Contacts::TYPES{TELEGRAM} && $contact->{value} !~ /e\_.*/) {
      return _make_subscribe_btn('Telegram', 'fa fa-bell-slash', undef, {
        HREF           => $SELF_URL . '/admin/index.cgi?index=9&REMOVE_SUBSCRIBE=' . $contact->{id},
        UNSUBSCRIBE    => 1,
        BUTTON_CLASSES => 'btn-success'
      });
    }
  }

  if (!$conf{TELEGRAM_BOT_NAME}) {
    require AXbills::Sender::Telegram;
    AXbills::Sender::Telegram->import();
    my $Telegram = AXbills::Sender::Telegram->new(\%conf);
    $conf{TELEGRAM_BOT_NAME} = $Telegram->get_bot_name(\%conf, $db);
  }

  return '' if !$conf{TELEGRAM_BOT_NAME};

  my $link_url = 'https://t.me/' . $conf{TELEGRAM_BOT_NAME} . '?start=a_' . ($admin->{SID} || $sid || $admin->{sid});
  return _make_subscribe_btn('Telegram', 'fab fa-telegram', undef, { HREF => $link_url });
}

#**********************************************************
=head2 _telegram_admin_button() - $contacts_list

=cut
#**********************************************************
sub _telegram_admin_button {
  my ($contacts_list) = @_;

  return '' if !$conf{TELEGRAM_ADMIN_TOKEN};

  foreach my $contact (@{$contacts_list}) {
    if ($contact->{type_id} == $Contacts::TYPES{TELEGRAM} && $contact->{value} =~ /e\_.*/) {
      return _make_subscribe_btn($lang{TELEGRAM_FOR_ADMINS}, 'fa fa-bell-slash', undef, {
        HREF           => $SELF_URL . '/admin/index.cgi?index=9&REMOVE_SUBSCRIBE=' . $contact->{id},
        UNSUBSCRIBE    => 1,
        BUTTON_CLASSES => 'btn-success'
      });
    }
  }
  return '' if !$conf{TELEGRAM_ADMIN_BOT_NAME};

  my $link_url = 'https://t.me/' . $conf{TELEGRAM_ADMIN_BOT_NAME} . '?start=e_' . ($admin->{SID} || $sid || $admin->{sid});
  return _make_subscribe_btn($lang{TELEGRAM_FOR_ADMINS}, 'fab fa-telegram', undef, { HREF => $link_url });
}

1;
