=head1 NAME

 Deals functions

=cut

use strict;
use warnings FATAL => 'all';
use Tags;
use Users;
use Crm::db::Crm;
use AXbills::Sender::Core;
use AXbills::Base qw/in_array mk_unique_value json_former sec2date date_format/;

our (
  @PRIORITY,
  %lang,
  $admin,
  %permissions,
  $db,
  %conf,
);

our AXbills::HTML $html;
my $Crm = Crm->new($db, $admin, \%conf);

#*******************************************************************
=head2 crm_users($attr)

=cut
#*******************************************************************
sub crm_users {
  my ($attr) = @_;

  $Crm->{ACTION} = 'add';
  $Crm->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Crm->crm_deals_add(\%FORM);
    if (!_error_show($Crm)) {
      $Crm->crm_deal_products_multi_add({ %FORM, DEAL_ID => $Crm->{INSERT_ID} });
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Crm->crm_deals_del({ ID => $FORM{del} });
    delete $FORM{COMMENTS};
    $html->message('info', $lang{DELETED}) if (!_error_show($Crm));
  }
  elsif ($FORM{change} && $FORM{ID}) {
    $Crm->crm_deals_change(\%FORM);
    if (!_error_show($Crm)) {
      $Crm->crm_deal_products_multi_add({ %FORM, DEAL_ID => $FORM{ID}, REWRITE => 1 });
    }
    $html->redirect("?get_index=crm_deal_info&full=1&DEAL_ID=$FORM{ID}", { WAIT => 1 });
  }
  elsif ($FORM{chg}) {
    $FORM{add_form} = 1;
    $Crm->{ACTION} = 'change';
    $Crm->{LNG_ACTION} = $lang{CHANGE};
    $Crm->crm_deal_info({ ID => $FORM{chg} });

    my $products = $Crm->crm_deal_products_list({
      ID        => $Crm->{PRODUCTS},
      NAME      => '_SHOW',
      COUNT     => '_SHOW',
      SUM       => '_SHOW',
      FEES_TYPE => '_SHOW',
      COLS_NAME => 1
    });
    $Crm->{PRODUCTS_JSON} = json_former($products);
  }

  if ($FORM{add_form}) {
    $Crm->{BEGIN_DATE} = $html->form_datepicker('BEGIN_DATE', $Crm->{BEGIN_DATE} || $DATE);
    $Crm->{CLOSE_DATE} = $html->form_datepicker('CLOSE_DATE', $Crm->{CLOSE_DATE} || date_format(sec2date(time() + 86400 * 7), '%Y-%m-%d'));
    $Crm->{STEP_SEL} = $html->form_select('CURRENT_STEP', {
      SELECTED  => $Crm->{CURRENT_STEP} || q{},
      SEL_LIST  => $Crm->crm_progressbar_step_list({
        NAME        => '_SHOW',
        STEP_NUMBER => '_SHOW',
        DEAL_STEP   => '!',
        COLS_NAME   => 1,
      }),
      SEL_VALUE => 'name',
      SEL_KEY   => 'step_number',
      NO_ID     => 1
    });

    $Crm->{FEES_TYPES} = $html->form_select('FEES_TYPES', {
      SELECTED     => '',
      SEL_HASH     => get_fees_types(),
      NORMAL_WIDTH => 1,
      SEL_OPTIONS  => { '' => '--' },
      SORT_KEY_NUM => 1
    });
    $Crm->{FEES_TYPES} =~ s/\n//g;

    $html->tpl_show(_include('crm_deals_add', 'Crm'), { %FORM, %{$Crm} });
  }

  my $progress_steps = $Crm->crm_progressbar_step_list({
    STEP_NUMBER => '_SHOW',
    NAME        => '_SHOW',
    COLOR       => '_SHOW',
    DEAL_STEP   => '!',
    DESC        => 'DESC',
    COLS_NAME   => 1
  });

  my ($table) = result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'crm_deals_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'LOGIN,NAME,UID,BEGIN_DATE,CLOSE_DATE,CURRENT_STEP,COMMENTS',
    FUNCTION_FIELDS => 'crm_deal_info:change:deal_id;uid,del',
    FUNCTION_INDEX  => $index,
    EXT_TITLES      => {
      id           => '#',
      name         => $lang{NAME},
      begin_date   => $lang{CRM_BEGIN_DATE},
      close_date   => $lang{CRM_CLOSE_DATE},
      current_step => $lang{STEP},
      comments     => $lang{COMMENTS},
    },
    FILTER_VALUES   => {
      id           => sub {
        my ($id, $line) = @_;

        return $id if !$id || !$line->{uid};
        return $html->button($id, "get_index=crm_deal_info&full=1&DEAL_ID=$id&UID=$line->{uid}");
      },
      current_step => sub {
        my ($step_number, $line) = @_;

        return _crm_progress_bar_line($line->{deal_id}, $step_number, $progress_steps);
      }
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{DEALS},
      ID      => 'CRM_DEALS',
      MENU    => "$lang{ADD}:index=$index&add_form=1" . ($FORM{UID} ? "&UID=$FORM{UID}" : "") . ":add",
      class   => 'table table-striped table-hover table-condensed no-highlight'
    },
    MAKE_ROWS       => 1,
    SKIP_TOTAL      => 1,
    SKIP_PAGES      => 1
  });

  my $steps_hash = {};
  map {$steps_hash->{$_->{step_number}} = $_} @{$progress_steps};
  $html->tpl_show(_include('crm_progressbar_line', 'Crm'), { STEPS_JSON => json_former($steps_hash) });

  return ('', $table->show()) if ($attr->{PROFILE_MODE});
  print $table->show();
}

#*******************************************************************
=head2 crm_deal_info()

=cut
#*******************************************************************
sub crm_deal_info {

  $Crm->crm_section_fields(\%FORM) if $FORM{save_fields};

  if ($FORM{change}) {
    $Crm->crm_deals_change(\%FORM);
    $html->message('info', $lang{CHANGED}) if !_error_show($Crm);
  }

  my $deal_info = $Crm->crm_deal_info({ ID => $FORM{DEAL_ID} });
  my $fields = crm_deal_fields($deal_info, { UID => $FORM{UID}, DEAL_ID => $FORM{DEAL_ID}, DEAL_SECTION => '!' });
  my $lead_profile_panel = $html->tpl_show(_include('crm_section_panel', 'Crm'),
    { DEAL_SECTION => 1, DEAL_ID => $FORM{DEAL_ID}, UID => $FORM{UID}, %{$fields} }, { OUTPUT2RETURN => 1 });

  $html->tpl_show(_include('crm_lead_info', 'Crm'), {
    LEAD_PROFILE_PANEL => $lead_profile_panel,
    PROGRESSBAR        => crm_progressbar_show($deal_info->{CURRENT_STEP}, {
      DEAL_STEP    => '!',
      DEAL_ID      => $FORM{DEAL_ID},
      OBJECT_VALUE => $FORM{DEAL_ID},
      OBJECT_TYPE  => 'deals',
      TASK_URL     => "DEAL_ID=" . ($FORM{DEAL_ID} || '')
    }),
  });

  return 1;
}

#*******************************************************************
=head2 crm_deals_list($attr)

=cut
#*******************************************************************
sub crm_deals_list {
  my ($attr) = @_;

  crm_deals_search() if $FORM{search_form};

  my $progress_steps = $Crm->crm_progressbar_step_list({
    STEP_NUMBER => '_SHOW',
    NAME        => '_SHOW',
    COLOR       => '_SHOW',
    DEAL_STEP   => '!',
    DESC        => 'DESC',
    COLS_NAME   => 1
  });

  result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'crm_deals_list',
    DEFAULT_FIELDS  => 'LOGIN,NAME,UID,BEGIN_DATE,CLOSE_DATE,CURRENT_STEP,COMMENTS',
    FUNCTION_FIELDS => 'crm_deal_info:change:deal_id;uid',
    FUNCTION_INDEX  => $index,
    EXT_TITLES      => {
      id           => '#',
      name         => $lang{NAME},
      login        => $lang{LOGIN},
      begin_date   => $lang{CRM_BEGIN_DATE},
      close_date   => $lang{CRM_CLOSE_DATE},
      current_step => $lang{STEP},
      comments     => $lang{COMMENTS}
    },
    FILTER_VALUES   => {
      id           => sub {
        my ($id, $line) = @_;

        return $id if !$id || !$line->{uid};
        return $html->button($id, "get_index=crm_deal_info&full=1&DEAL_ID=$id&UID=$line->{uid}");
      },
      current_step => sub {
        my ($step_number, $line) = @_;

        return _crm_progress_bar_line($line->{deal_id}, $step_number, $progress_steps);
      }
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{DEALS},
      ID      => 'CRM_DEALS',
      class   => 'table table-striped table-hover table-condensed no-highlight',
      MENU    => "$lang{SEARCH}:index=$index&search_form=1:search"
    },
    MAKE_ROWS       => 1,
    TOTAL          => ($attr->{USER_ACCOUNT} && $attr->{USER_ACCOUNT} < 5) ? 0 : 1
  });

  my $steps_hash = {};
  map {$steps_hash->{$_->{step_number}} = $_} @{$progress_steps};
  $html->tpl_show(_include('crm_progressbar_line', 'Crm'), { STEPS_JSON => json_former($steps_hash) });
}

#*******************************************************************
=head2 crm_deals_search()

=cut
#*******************************************************************
sub crm_deals_search {
  my %info = ();

  $info{BEGIN_DATE} = $html->form_datepicker('BEGIN_DATE', $FORM{BEGIN_DATE} || '');
  $info{CLOSE_DATE} = $html->form_datepicker('CLOSE_DATE', $FORM{CLOSE_DATE} || '');
  $info{STEP_SEL} = $html->form_select('CURRENT_STEP', {
    SELECTED    => $FORM{CURRENT_STEP} || '',
    SEL_LIST    => $Crm->crm_progressbar_step_list({
      NAME        => '_SHOW',
      STEP_NUMBER => '_SHOW',
      DEAL_STEP   => '!',
      COLS_NAME   => 1,
    }),
    SEL_OPTIONS => { '' => '' },
    SEL_VALUE   => 'name',
    SEL_KEY     => 'step_number',
    NO_ID       => 1
  });

  my $search_form = $html->tpl_show(_include('crm_deals_search', 'Crm'), { %FORM, %info }, { OUTPUT2RETURN => 1 });
  $search_form .= $html->tpl_show(templates('form_search_personal_info'), { %FORM, %info }, { OUTPUT2RETURN => 1 });

  form_search({ SEARCH_FORM => $search_form, ADDRESS_FORM => 1 });
}

#*******************************************************************
=head2 _crm_progress_bar_line($deal_id, $active_step, $progress_list)

=cut
#*******************************************************************
sub _crm_progress_bar_line {
  my $deal_id = shift;
  my $active_step = shift || 0;
  my ($progress_list) = @_;

  my $steps = '';
  my $color = '';
  my $title = '';
  foreach my $step (@{$progress_list}) {
    my $bar_btn = $html->element('div', '', { class => 'crm-progress-bar-btn' });
    my $bar_block = $html->element('div', $bar_btn, { class => 'crm-progress-bar-block' });
    if ($active_step == $step->{step_number}) {
      $color = $step->{color};
      $title = $html->element('div', $step->{name}, { class => 'crm-progress-bar-title' })
    }
    $steps = $html->element('td', $bar_block, {
      class     => 'crm-progress-bar-part',
      style     => "background-color: $color",
      'data-id' => $step->{step_number}
    }) . $steps;
  }

  my $table_body = $html->element('tbody', $html->element('tr', $steps, { class => 'crm-progress-bar-table-row' }));
  my $table = $html->element('table', $table_body, { class => 'crm-progress-bar-table' });

  return $html->element('div', $table, { class => 'crm-list-progress-bar', 'data-id' => $deal_id }) . $title;
}

1;