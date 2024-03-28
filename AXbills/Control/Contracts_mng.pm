=head1 NAME

  Users contracts web functions

=cut

use strict;
use warnings FATAL => 'all';

our (
  $db,
  $admin,
  %lang,
  $users,
  %conf,
  @MONTHES_LIT,
  %permissions,
);

our AXbills::HTML $html;
#**********************************************************
=head2 user_contract($attr)

=cut
#**********************************************************
sub user_contract {

  my $uid = $FORM{UID};
  return '' unless ($uid);

  if ($FORM{print_add_contract}) {
    load_module("Docs");
    my $list = $users->contracts_list({ UID => $uid, ID => $FORM{print_add_contract}, COLS_UPPER => 1 });
    $users->info($uid, {SHOW_PASSWORD => 1});
    $users->pi({ UID => $uid });
    my $contract_info = {};
    my ($y, $m, $d) = split( /-/, $list->[0]->{DATE} || $DATE, 3 );
    $contract_info->{CONTRACT_DATE_LIT} = "$d " . $MONTHES_LIT[ int( $m ) - 1 ] . " $y $lang{YEAR_SHORT}";
    ($y, $m, $d) = split( /-/, $DATE, 3 );
    $contract_info->{DATE_LIT} = "$d " . $MONTHES_LIT[ int( $m ) - 1 ] . " $y $lang{YEAR_SHORT}";
    my $company_info = {};

    if($users->{COMPANY_ID}){
      require Companies;
      Companies->import();
      my $Company = Companies->new($db, $admin, \%conf);
      $company_info = $Company->info($users->{COMPANY_ID});
    }

    #Modules info
    my $cross_modules_return = cross_modules('docs', { UID => $uid });
    my $service_num = 1;
    foreach my $module (sort keys %$cross_modules_return) {
      if (ref $cross_modules_return->{$module} eq 'ARRAY') {
        next if ($#{$cross_modules_return->{$module}} == -1);
        my $module_num = 1;
        foreach my $line (@{$cross_modules_return->{$module}}) {
          #$name, $describe, sum, $tp_id, tp_name
          my (undef, undef, $sum, undef, $tp_name) = split(/\|/, $line);
          my $module_info = uc($module) . (($module_num) ? "_$module_num" : '');
          $contract_info->{ "SUM_" . $module_info }   = $sum || 0;
          $contract_info->{ "NAME_" . $module_info } = $tp_name || q{};
          $contract_info->{ "SERVICE_SUM_" . $service_num } = $sum || 0;
          $contract_info->{ "SERVICE_NAME_" . $service_num } = $tp_name || q{};
          $service_num++;
          $module_num++;
        }
      }
    }
    if ($FORM{pdf}) {
      my $sig_img = "$conf{TPL_DIR}/sig.png";
      if ($list->[0]->{SIGNATURE}) {
        open( my $fh, '>', $sig_img);
        binmode $fh;
        my ($data) = $list->[0]->{SIGNATURE} =~ m/data:image\/png;base64,(.*)/;
        print $fh decode_base64($data);
        close $fh;
      }
      else {
        # open( my $fh, '>', $sig_img);
        # close $fh;
      }
      $html->tpl_show("$conf{TPL_DIR}/$list->[0]->{template}", { %$contract_info, %$users, %$company_info, %{$list->[0]}, FIO_S => $users->{FIO} }, { TITLE => "Contract" });
      unlink $sig_img;
    }
    else {
      $html->tpl_show(templates($list->[0]->{template}), { %$contract_info, %$users, %$company_info, %{$list->[0]} });
    }
    return 1;
  }
  elsif ($FORM{signature}) {
    $users->contracts_change($FORM{sign}, { SIGNATURE => $FORM{signature} });
    $html->message('info', $lang{SIGNED});
  }
  elsif ($FORM{sign}) {
    $html->tpl_show(templates('signature'), {});
    return 1;
  }
  elsif ($FORM{del}) {
    $users->contracts_del({ UID => $uid, ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $users->contracts_change($FORM{chg}, \%FORM);
  }
  elsif ($FORM{chg}) {
    my $list = $users->contracts_list({ UID => $uid, ID => $FORM{chg}, COLS_UPPER => 1 });
    if ($users->{TOTAL} != 0) {
      $html->tpl_show(templates('form_user_contract'), { 
        BTN_NAME  => 'change',
        BTN_VALUE => $lang{CHANGE},
        TYPE_SEL  => _contract_type_select($list->[0]->{type}),
        %{$list->[0]} 
      });
    }
  }
  elsif ($FORM{add}) {
    $html->tpl_show(templates('form_user_contract'), {
      BTN_NAME  => 'adding',
      BTN_VALUE => $lang{ADD},
      TYPE_SEL  => _contract_type_select('0'),
    });
  }
  elsif ($FORM{adding}) {
    $users->contracts_add(\%FORM);
  }

  print _user_contracts_table($FORM{UID});
  return 1;
}

#**********************************************************
=head2 _user_contracts_table($attr)

=cut
#**********************************************************
sub _user_contracts_table {
  my ($uid, $attr) = @_;

  $uid = $FORM{UID} unless ($uid); 
  return '' unless ($uid);

  my $f_index;

  if ($attr->{UI}) {
    $f_index = 10;
    $users = $attr->{USER_INFO} if ($attr->{USER_INFO});
  }
  else {
    $f_index = get_function_index('user_contract');
  }

  my $list = $users->contracts_list({ UID => $uid });

  my $table = $html->table({
    width               => '100%',
    caption             => "$lang{CONTRACTS} / $lang{ADDITION}",
    border              => 1,
    title_plain         => [ $lang{NAME}, "#", $lang{DATE}, $lang{SIGNATURE} ],
    ID                  => 'USER_CONTRACTS',
    HAS_FUNCTION_FIELDS => 1,
    ( $attr->{UI} ? {} : MENU => "$lang{ADD}:index=" . get_function_index('user_contract') . "&add=1&UID=$uid:add" ),
  });

  foreach my $line (@$list) {
    my $sign_button = $line->{signature} ? $lang{SIGNED} : $html->button($lang{SIGN}, "qindex=" . $f_index .
      "&UID=$uid&sign=$line->{id}&header=2", { class => 'btn btn-secondary' });

    my $print_button  = '';
    my $edit_button   = '';
    my $delete_button = '';

    if (($permissions{0} && $permissions{0}{4}) || $attr->{UI}) {
      $print_button = $html->button('', "qindex=" . $f_index . "&UID=$uid&print_add_contract=$line->{id}&pdf=1", {
        ICON      => 'fas fa-print',
        target    => '_new',
        ex_params => "data-tooltip='$lang{PRINT}' data-tooltip-position='right'"
      });

      $edit_button = $html->button('', "index=" . $f_index . "&chg=$line->{id}&UID=$uid", {
        ICON      => 'fa fa-pencil-alt',
        ex_params => "data-tooltip='$lang{EDIT}' data-tooltip-position='right'"
      });

      $delete_button = $html->button('', "index=" . $f_index . "&del=$line->{id}&UID=$uid", {
        ICON      => 'fa fa-trash text-danger',
        ex_params => "data-tooltip='$lang{DEL}' data-tooltip-position='right'"
      });
    }

    $table->addrow($line->{name}, $line->{number}, $line->{date}, $sign_button, ($attr->{UI} ? $print_button : $print_button . $edit_button . $delete_button) );
  }

  my $result = $table->show({OUTPUT2RETURN => 1});

  return $result;
}

#**********************************************************
=head2 contracts_type()

=cut
#**********************************************************
sub contracts_type {

  if ($FORM{del}) {
    $users->contracts_type_del({ ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $users->contracts_type_change($FORM{chg}, \%FORM);
  }
  elsif ($FORM{chg}) {
    my $list = $users->contracts_type_list({ ID => $FORM{chg}, COLS_UPPER => 1 });
    if ($users->{TOTAL} && $users->{TOTAL} > 0) {
       $html->tpl_show(templates('form_user_contracts_type'), { BTN_NAME => 'change', BTN_VALUE => $lang{CHANGE}, %{$list->[0]} });
    }
  }
  elsif ($FORM{add}) {
    $html->tpl_show(templates('form_user_contracts_type'), { BTN_NAME => 'adding', BTN_VALUE => $lang{ADD} });
  }
  elsif ($FORM{adding}) {
    $users->contracts_type_add(\%FORM);
  }

  print _contract_type_table();

  return 1;
}

#**********************************************************
=head2 _contract_type_table($attr)

=cut
#**********************************************************
sub _contract_type_table {
  
  my $list = $users->contracts_type_list({});

  my $table = $html->table({
    width               => '100%',
    caption             => "$lang{TYPES} $lang{CONTRACTS}",
    border              => 1,
    title_plain         => [ $lang{NAME}, $lang{TEMPLATE} ],
    ID                  => 'CONTRACTS_TYPE',
    HAS_FUNCTION_FIELDS => 1,
    MENU                => "$lang{ADD}:index=" . get_function_index('contracts_type') . "&add=1:add",
  });

  foreach my $line (@$list) {
    my $edit_button = $html->button('', "index=" . get_function_index('contracts_type') . "&chg=$line->{id}",
            { ICON => 'fa fa-pencil-alt', ex_params => "data-tooltip='$lang{EDIT}' data-tooltip-position='top'" });
    my $delete_button = $html->button('', "index=" . get_function_index('contracts_type') . "&del=$line->{id}",
            { ICON => 'fa fa-trash text-danger', ex_params => "data-tooltip='$lang{DEL}' data-tooltip-position='top'" });
    $table->addrow($line->{name}, $line->{template}, $edit_button . $delete_button);
  }

  my $result = $table->show({OUTPUT2RETURN => 1});

  return $result;
}

#**********************************************************
=head2 _contract_type_select($attr)

=cut
#**********************************************************
sub _contract_type_select {
  my ($selected) = @_;

  my $list = $users->contracts_type_list({});

  if ($users->{TOTAL} == 0) {
    my $add_btn = $html->button(
      " $lang{ADD} $lang{TYPE} $lang{CONTRACTS}",
      'add=1&index=' . get_function_index('contracts_type'),
      {
        class => 'btn btn-warning',
        ADD_ICON  => 'fa fa-plus'
  
      }
    );
    return $add_btn;
  }

  my $result = $html->form_select('TYPE', {
    SELECTED      => ($selected || ''),
    SEL_LIST      => $list,
    NO_ID         => 1,
    OUTPUT2RETURN => 1
  });

  return $result;
}

1