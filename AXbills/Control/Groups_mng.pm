=head1 NAME

  Groups manage

=cut

use warnings FATAL => 'all';
use strict;
use AXbills::Defs;
use AXbills::Base qw(in_array);

our (
  $db,
  %lang,
  $admin,
  %permissions,
  @bool_vals,
);

our AXbills::HTML $html;
our Users $users;

#**********************************************************
=head2 form_groups() - users groups

=cut
#**********************************************************
sub form_groups {

  if ($FORM{add_form}) {
    if ($permissions{0} && !$permissions{0}{28}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 0
    }
    $users->{ACTION}     = 'add';
    $users->{LNG_ACTION} = $lang{ADD};
    if(in_array('Multidoms', \@MODULES)) {
      load_module('Multidoms', $html);
      $users->{DOMAIN_FORM} = $html->tpl_show(templates('form_row'), {
        ID    => '',
        NAME  => $lang{DOMAIN},
        VALUE => multidoms_domains_sel({ SHOW_ID => 1, DOMAIN_ID => $admin->{DOMAIN_ID} })
      }, { OUTPUT2RETURN => 1 });
    }

    if(in_array('Sms', \@MODULES)) {
      load_module('Sms', $html);
      $users->{SMS_FORM} = $html->tpl_show(templates('form_row'), {
        ID    => '',
        NAME  => $lang{SMS_GATEWAY},
        VALUE => sel_sms_systems({ SELECTED => $users->{SMS_SERVICE} })
      }, { OUTPUT2RETURN => 1 });
    }

    $html->tpl_show(templates('form_groups'), $users);
    return 0;
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 0;
    }

    if ($permissions{0} && !$permissions{0}{28}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    }
    else {
      if ($FORM{GID} && $FORM{GID} =~ /^(?!0\d{1,4}$)([1-9]\d{0,3}|[1-5]\d{4}|6[0-4]\d{3}|65[0-4]\d{2}|655[0-2]\d|6553[0-5])$/gm) {
        $users->group_add({ %FORM });
        $html->message('info', $lang{ADDED}, "$lang{ADDED} [" . ($FORM{GID} || q{}) . "]") if !$users->{errno};
      }
      else {
        $html->message('err', $lang{ERROR}, $lang{ERR_GID});
      }
    }
  }
  elsif ($FORM{change}) {
    if (!$permissions{0}{4}) {
      $html->message( 'err', $lang{ERROR}, $lang{ERR_ACCESS_DENY} );
      return 0;
    }

    $users->group_change($FORM{chg}, { %FORM });
    $html->message('info', $lang{CHANGED}, "$lang{CHANGED} ". ($FORM{chg} || q{})) if !$users->{errno};
  }
  elsif (defined($FORM{GID}) || $FORM{chg}) {
    if ($FORM{chg}) {
      $FORM{GID} = $FORM{chg};
      delete($FORM{chg});
    }

    $users->group_info($FORM{GID});

    $LIST_PARAMS{GID} = $users->{GID};
    delete $LIST_PARAMS{GIDS};
    $pages_qs = '&GID=' . ($users->{GID} || $FORM{GID}) . (($FORM{subf}) ? "&subf=$FORM{subf}" : q{} );

    my $groups = $html->form_main({
      CONTENT => $html->form_select('GID', {
        SELECTED => $users->{GID} || $FORM{GID},
        SEL_LIST => $users->groups_list({
          GID            => '_SHOW',
          NAME           => '_SHOW',
          DESCR          => '_SHOW',
          ALLOW_CREDIT   => '_SHOW',
          DISABLE_PAYSYS => '_SHOW',
          DISABLE_CHG_TP => '_SHOW',
          USERS_COUNT    => '_SHOW',
          COLS_NAME      => 1
        }),
        SEL_KEY    => 'gid',
        AUTOSUBMIT => 'form',
        NO_ID      => 1
      }),
      HIDDEN  => {
        index => $index,
        show  => 1
      },
      class   => 'form-inline ml-auto flex-nowrap',
    });

    func_menu({ $lang{NAME} => $groups },
      [
        $lang{CHANGE} . '::GID=' . ($users->{GID} || $FORM{GID}) . ':change',
        $lang{USERS} . ':11:GID=' . ($users->{GID} || $FORM{GID}) . ':users',
        $lang{PAYMENTS} . ':2:GID=' . ($users->{GID} || $FORM{GID}) . ':payments',
        $lang{FEES} . ':3:GID=' . ($users->{GID} || $FORM{GID}) . ':fees',
      ]
    );

    return 0 if !$permissions{0}{4};

    $users->{ACTION} = 'change';
    $users->{LNG_ACTION} = $lang{CHANGE};
    $users->{SEPARATE_DOCS} = ($users->{SEPARATE_DOCS}) ? 'checked' : '';
    $users->{ALLOW_CREDIT} = ($users->{ALLOW_CREDIT}) ? 'checked' : '';
    $users->{DISABLE_PAYSYS} = ($users->{DISABLE_PAYSYS}) ? 'checked' : '';
    $users->{DISABLE_PAYMENTS} = ($users->{DISABLE_PAYMENTS}) ? 'checked' : '';
    $users->{DISABLE_CHG_TP} = ($users->{DISABLE_CHG_TP}) ? 'checked' : '';
    $users->{BONUS} = ($users->{BONUS}) ? 'checked' : '';
    $users->{DOCUMENTS_ACCESS} = ($users->{DOCUMENTS_ACCESS}) ? 'checked' : '';
    $users->{GID_DISABLE} = 'disabled';
    $users->{DISABLE_ACCESS} = ($users->{DISABLE_ACCESS}) ? 'checked' : '';

    if(in_array('Multidoms', \@MODULES)) {
      load_module('Multidoms', $html);
      $users->{DOMAIN_FORM} = $html->tpl_show(templates('form_row'), {
        ID    => '',
        NAME  => $lang{DOMAIN},
        VALUE => multidoms_domains_sel({ SHOW_ID => 1, DOMAIN_ID => $users->{DOMAIN_ID} })
      }, { OUTPUT2RETURN => 1 });
    }

    if(in_array('Sms', \@MODULES)) {
      load_module('Sms', $html);
      $users->{SMS_FORM} = $html->tpl_show(templates('form_row'), {
        ID    => '',
        NAME  => $lang{SMS_GATEWAY},
        VALUE => sel_sms_systems({ SELECTED => $users->{SMS_SERVICE} })
      }, { OUTPUT2RETURN => 1 });
    }

    $html->tpl_show(templates('form_groups'), $users);

    return 0;
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS} && $permissions{0} && $permissions{0}{5}) {
    $FORM{del} = 0 if !$FORM{del};
    $users->list({ GID => $FORM{del} });

    if ($users->{TOTAL} && $users->{TOTAL} > 0 && $FORM{del} > 0) {
      $html->message('warning', $lang{WARNING}, $lang{GROUP_USERS_EXISTS});
    }
    else {
      $users->group_del($FORM{del});
      $html->message('info', $lang{DELETED}, "$lang{DELETED} GID: $FORM{del}")  if !$users->{errno};
    }
  }

  _error_show($users);

  my %ext_titles = (
    id               => '#',
    name             => $lang{NAME},
    bonus            => $lang{BONUS},
    users_count      => $lang{USERS},
    descr            => $lang{DESCRIBE},
    allow_credit     => "$lang{ALLOW} $lang{CREDIT}",
    disable_paysys   => "$lang{DISABLE} Paysys",
    disable_payments => "$lang{DISABLE} $lang{PAYMENTS} $lang{CASHBOX}",
    disable_chg_tp   => $lang{FORBIDDEN_TO_CHANGE_TP_BY_USER},
    documents_access => $lang{ALLOW_ACCESS_DOCUMENTS},
    disable_access   => $lang{DISABLE_USER_PORTAL_ACCESS}
  );

  my ($table, $list) = result_former({
    INPUT_DATA      => $users,
    FUNCTION        => 'groups_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'DISABLE_PAYMENTS,DISABLE_PAYMENTS,USERS_COUNT,NAME,DESCR,ALLOW_CREDIT,DISABLE_PAYSYS,DISABLE_CHG_TP,DOCUMENTS_ACCESS,DISABLE_ACCESS',
    HIDDEN_FIELDS   => 'GID',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => \%ext_titles,
    SKIP_USER_TITLE => 1,
    FILTER_VALUES   => {
      allow_credit     => sub {return $bool_vals[ shift ]},
      disable_paysys   => sub {return $bool_vals[ shift ]},
      disable_payments => sub {return $bool_vals[ shift ]},
      disable_chg_tp   => sub {return $bool_vals[ shift ]},
      documents_access => sub {return $bool_vals[ shift ]},
      disable_access   => sub {return $bool_vals[ shift ]},
      bonus            => sub {return $bool_vals[ shift ]},
      users_count => sub {
        my ($users_count, $line) = @_;

        my $users_count_button = $html->button($users_count, "index=7&GID=$line->{gid}&search_form=1&search=1&type=11");
        return $users_count_button if ($users_count && $users_count > 0);

        return 0;
      }
    },
    TABLE  => {
      width   => '100%',
      caption => $lang{GROUPS},
      ID      => 'GROUPS',
      qs      => $pages_qs,
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS  => 1,
    TOTAL      => 1
  });

  return 1;
}


1;