package Employees::Employees_work;

=head1 NAME

  Employees work interface

=head1 VERSION

  VERSION: 1.01
  REVISION: 20201019

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use Employees;

our $VERSION = 1.01;

our @EXPORT = qw(
  employees_works_list
  employees_works
);

my $MODULE = 'Employees';

our (
  $Employees,
  $admin,
  $CONF,
  $lang,
  $db,
  $users,
  $html,
  $Fees
);

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless($self, $class);

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};
  $Employees = $attr->{EMPLOYEES} if $attr->{EMPLOYEES};

  use Users;
  $users = Users->new($db, $admin, $CONF);

  use Fees;
  $Fees = Fees->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 employees_works_list() -

  Arguments:
    $attr -


  Returns:

  Examples:

=cut

#**********************************************************
sub employees_works_list {
  my $self = shift;
  my ($attr) = @_;

  my $index = $attr->{INDEX} || $attr->{index};
  return '' if !$index;

  my $uid = $attr->{UID} || '';

  my $add_url = "?qindex=$index&header=2&EXT_ID=$attr->{EXT_ID}&UID=$uid" . ($attr->{ADD_PARAMS} || '');
  my $add_button = $html->button($lang->{ADD}, undef, {
    class          => 'add',
    ex_params      => qq/onclick=loadToModal('$add_url'\,''\,'lg')/,
    NO_LINK_FORMER => 1,
    SKIP_HREF      => 1
  });

  my $change_function = ":change:id:&UID=$uid&UID=$uid";
  $change_function .= $attr->{CHANGE_PARAMS} if $attr->{CHANGE_PARAMS};

  my $del_function = ":del:id:&UID=$uid";
  $del_function .= $attr->{DEL_PARAMS} if $attr->{DEL_PARAMS};

  my $employees_works = $Employees->employees_works_list({
    ID         => '_SHOW',
    DATE       => '_SHOW',
    WORK       => '_SHOW',
    EMPLOYEE   => '_SHOW',
    SUM        => '_SHOW',
    COMMENTS   => '_SHOW',
    FEES_ID    => '_SHOW',
    WORK_DONE  => '_SHOW',
    ADMIN_NAME => '_SHOW',
    EXT_ID     => $attr->{EXT_ID} || '_SHOW',
    COLS_NAME  => 1,
  });

  return '' if ::_error_show($Employees);

  my AXbills::HTML $table = $html->table({
    width       => '100%',
    caption     => $lang->{WORK},
    title_plain => [ '#', $lang->{DATE}, $lang->{PERFORMER}, $lang->{WORK}, $lang->{SUM}, $lang->{COMMENTS}, $lang->{FEE_TAKEN}, $lang->{WORK_DONE}, $lang->{ADMIN}, '', '' ],
    ID          => 'EMPLOYEES_WORKS',
    qs          => $attr->{pages_qs},
    DATA_TABLE  => 1,
    MENU        => [ $add_button ],
  });

  foreach my $work (@{$employees_works}) {
    my $chg_url = "?qindex=$index&header=2&chg_work=$work->{id}&UID=$uid" . ($attr->{CHANGE_PARAMS} || '');
    my $chg_button = $html->button($lang->{ADD}, undef, {
      class          => 'change',
      ex_params      => qq/onclick=loadToModal('$chg_url'\,''\,'lg')/,
      NO_LINK_FORMER => 1,
      SKIP_HREF      => 1
    });
    my $del_button = $html->button($lang->{DEL}, "index=$index&del_work=$work->{id}" . ($attr->{DEL_PARAMS} || ''), {
      class   => 'del',
      MESSAGE => "$lang->{DEL} " . ($work->{work} || $work->{id} || q{-}) . "?"
    });

    $table->addrow($work->{id}, $work->{date}, $work->{employee}, $work->{work}, $work->{sum}, $work->{comments},
      $work->{fees_id} ? $html->color_mark($lang->{YES}, 'text-primary') : $html->color_mark($lang->{NO}, 'text-danger'),
      $work->{work_done} ? $html->color_mark($lang->{YES}, 'text-success') : $html->color_mark($lang->{NO}, 'text-danger'), $work->{admin_name},
      $chg_button, $del_button
    );
  }

  my AXbills::HTML $total_table = $html->table({
    width => '100%',
    ID    => 'EMPLOYEES_WORKS_TOTAL',
    rows  => [ [ "$lang->{TOTAL}:", $html->b($Employees->{TOTAL}) ], [ "$lang->{SUM}:", $html->b($Employees->{TOTAL_SUM}) ] ]
  });
  return $table->show() . $total_table->show();
}

#**********************************************************
=head2 employees_works() -

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub employees_works {
  my $self = shift;
  my ($attr) = @_;

  my $index = $attr->{index} || $attr->{qindex};
  return 0 if !$index;

  $Employees->{ACTION} = 'add_work';
  $Employees->{ACTION_LNG} = $lang->{ADD};
  $Employees->{HIDDEN_INPUTS} = $attr->{HIDDEN_INPUTS} if $attr->{HIDDEN_INPUTS};

  _emplayees_take_fees($attr);
  return 1 if _employees_work_query($attr);

  main::_error_show($Employees);

  if ($attr->{EXT_ID}) {
    $Employees->{EXT_ID} = $attr->{EXT_ID};
    $Employees->{UID} = $attr->{UID};
    $Employees->{WORK} = $attr->{EXT_ID};
  }

  $Employees->{ADMIN_SEL} = main::sel_admins({ SELECTED => $Employees->{EMPLOYEE_ID}, NAME => 'EMPLOYEE_ID', REQUIRED => 1 });
  $Employees->{WORK_SEL} = $html->form_select('WORK_ID', {
    SELECTED       => $Employees->{WORK_ID} || $attr->{WORK_ID},
    SEL_LIST       => $Employees->employees_list_reference_works({ COLS_NAME => 1, PAGE_ROWS => 10000 }),
    SEL_KEY        => 'id',
    SEL_VALUE      => 'name,sum',
    NO_ID          => 1,
    MAIN_MENU      => main::get_function_index('employees_reference_works'),
    MAIN_MENU_ARGV => ($Employees->{WORK_ID}) ? "chg=$Employees->{WORK_ID}" : '',
    EX_PARAMS      => 'required'
  });

  $Employees->{RATIO} ||= 1;

  if ($Employees->{FEES_ID}) {
    $Employees->{TAKE_FEES} = $html->b($lang->{GETED});
  }
  else {
    my $take_fees_element = $html->form_input('TAKE_FEES', '1', { TYPE => 'checkbox', class => 'custom-control-input' });
    my $label_element = $html->element('LABEL', $lang->{TAKE_FEE}, { class => 'custom-control-label', for => 'TAKE_FEES' });
    my $div_element = $html->element('DIV', "$take_fees_element $label_element",
      { class => "form-group custom-control custom-checkbox", style => "text-align: center;" });

    $Employees->{TAKE_FEES} = $div_element;
  }
  $Employees->{WORK_DONE} = 'checked' if ($Employees->{WORK_DONE});
  $html->tpl_show(main::_include('employees_work_add', 'Employees'), $Employees);

  return 0;
}

#**********************************************************
=head2 _employees_work_query() -

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub _employees_work_query {
  my ($attr) = @_;

  if ($attr->{add_work}) {
    delete $attr->{ID};
    $Employees->employees_works_add({ %{$attr} });

    if (!$Employees->{errno}) {
      $html->message('info', $lang->{SUCCESS}, "$lang->{WORK} $lang->{ADDED} ");
      return 1;
    }
  }
  elsif ($attr->{change_work}) {
    $attr->{WORK_DONE} = 0 if (!$attr->{WORK_DONE});
    $Employees->employees_works_change({ %{$attr}, ID => $attr->{WORK_ID} });
    if (!$Employees->{errno}) {
      $html->message('info', $lang->{WORK}, $lang->{CHANGED});
      return 1;
    }
  }
  elsif ($attr->{chg_work}) {
    $Employees->employees_works_info($attr->{chg_work});
    $Employees->{WORK_ID} = $attr->{chg_work};
    if (!$Employees->{errno}) {
      $Employees->{ACTION} = 'change_work';
      $Employees->{HIDE_ADD_WORK} = 'none';
      $Employees->{ACTION_LNG} = $lang->{CHANGE};
      return 0;
    }
  }
  elsif ($attr->{del_work} && $attr->{COMMENTS}) {
    $Employees->employees_works_del($attr->{del_work});
    if (!$Employees->{errno}) {
      $html->message('info', $lang->{WORK}, $lang->{DELETED});
      return 1;
    }
  }

  return 0;
}

#**********************************************************
=head2 _emplayees_take_fees()

  Arguments:

  Returns:

=cut
#**********************************************************
sub _emplayees_take_fees {
  my ($attr) = @_;

  return if !($attr->{TAKE_FEES} && ($attr->{add_work} || $attr->{change_work}));

  my @WORKS = split(/,\s?/, $attr->{WORK_ID});
  my @RATIOS = split(/,\s?/, $attr->{RATIO});
  my @FEES_IDS = ();

  for (my $i = 0 ; $i <= $#WORKS; $i++) {
    my $fee_sum = 0;
    if ($attr->{EXTRA_SUM}) {
      $fee_sum = $attr->{EXTRA_SUM};
    }
    else {
      my $work_info = $Employees->employees_reference_works_info($WORKS[$i]);
      $fee_sum = $work_info->{SUM} * ($RATIOS[$i] || 1) if ($Employees->{TOTAL} > 0);
    }

    $users->info($attr->{UID});
    $Fees->take($users, sprintf("%.2f", $fee_sum), { DESCRIBE => "msgs_work # $attr->{EXT_ID}" });
    $html->message('info', "$lang->{GETED}: " . sprintf("%.2f", $fee_sum)) if (!main::_error_show($Fees));
    $admin->action_add($users->{UID}, "msgs_work #$attr->{EXT_ID} $lang->{GETED}: " . sprintf("%.2f", $fee_sum), {});
    push @FEES_IDS, $Fees->{INSERT_ID} || 0;
  }

  $attr->{FEES_ID} = join(',', @FEES_IDS);
}

1;
