=head1 NAME

  Accident Reports

=cut

use strict;
use warnings FATAL => 'all';
use Accident;

our (
  $db,
  $admin,
  %conf,
  %lang,
  @MONTHES,
  %permissions
);

our AXbills::HTML $html;

my %priority = (
  0 => $lang{VERY_LOW},
  1 => $lang{LOW},
  2 => $lang{NORMAL},
  3 => $lang{HIGH},
  4 => $lang{VERY_HIGH}
);

my %type = (
  'days'   => $lang{DAYS},
  'months' => $lang{PER_MONTH}
);

my $Accident = Accident->new($db, $admin, \%conf);

#**********************************************************
=head2 accident_report () - show report with accidents

=cut
# **********************************************************
sub accident_report {

  $Accident->{LNG_ACTION} = $lang{SHOW};

  form_search({ TPL => $html->tpl_show(_include('accident_report_search', 'Accident'), {
    SELECT_PRIORITY     => $html->form_select('PRIORITY', {
      SELECTED    => $FORM{PRIORITY},
      SEL_HASH    => \%priority,
      SORT_KEY    => 1,
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '' }
    }),
    DATE_PICKER         => $html->form_daterangepicker({
      NAME         => 'FROM_DATE/TO_DATE',
      FORM_NAME    => 'accident_log',
      VALUE        => $FORM{FROM_DATE_TO_DATE},
      RETURN_INPUT => 1
    }),
    DATE_PICKER_CHECKED => $FORM{FROM_DATE_TO_DATE} ? 'checked' : '',
    SELECT_ADMIN        => sel_admins({ SELECTED => $FORM{AID} }),
    SELECT_TYPE         => $html->form_select('TYPE', {
      SELECTED    => $FORM{TYPE} || 'days',
      SEL_HASH    => \%type,
      SORT_KEY    => 1,
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '' }
    })
  }, { OUTPUT2RETURN => 1 }) });

  if ($FORM{FROM_DATE_TO_DATE}) {
    ($FORM{FROM_DATE}, $FORM{TO_DATE}) = split('/', $FORM{FROM_DATE_TO_DATE});
  }

  my $accident_report = $Accident->accident_report({
    ALL       => 1,
    COLS_NAME => 1,
    SORT      => $FORM{sort},
    DESC      => $FORM{desc},
    %FORM
  });

  my $table = $html->table({
    width   => '100%',
    caption => $lang{REPORTS},
    border  => 1,
    title   => [ (defined($FORM{TYPE}) eq 'months') ? ($lang{MONTH}) : ($lang{DATE}), $lang{ACCIDENT_QUANTITY}, $lang{HOURS} ],
    ID      => 'ACCIDENT_REPORT',
    EXPORT  => 1,
  });

  my ($total_quantity, $total_time, $button_date, $from_date, $to_date);
  my @labels_chart = ();
  my @data_chart = ();
  my $priority = defined($FORM{PRIORITY}) ? ($FORM{PRIORITY}) : '';
  my $admin = defined($FORM{AID}) ? ($FORM{AID}) : '';


  foreach my $line (@$accident_report) {


    if (defined($FORM{TYPE}) && $FORM{TYPE} eq 'months') {
      $from_date = "$line->{month}-01";
      $to_date = "$line->{month}-" . days_in_month({ DATE => $line->{month} });
      $button_date = $html->button($line->{date}, "index=414&search_form=1&search=1&PRIORITY=$priority&AID=$admin&FROM_DATE=$from_date&TO_DATE=$to_date&FROM_DATE_TO_DATE=$from_date/$to_date", { ex_params => "class=new" });
    }
    else {
      $button_date = $html->button($line->{date}, "index=414&search_form=1&search=1&PRIORITY=$priority&AID=$admin&FROM_DATE=$line->{date}&TO_DATE=$line->{date}&FROM_DATE_TO_DATE=$line->{date}/$line->{date}", { ex_params => "class=new" });
    }

    $table->addrow(
      $button_date,
      $line->{quantity},
      $line->{hour_diff},
    );

    $total_quantity += $line->{quantity};
    $total_time += $line->{hour_diff};
    push @labels_chart, ($line->{date});
    push @data_chart, $line->{quantity};
  }

  $table->addfooter(
    "$lang{TOTAL}: ", $total_quantity, $total_time
  );

  # Show chart
  _accident_report_chart(\@labels_chart, \@data_chart);

  print $table->show();

  return 0;

}


#**********************************************************
=head2 accident_report_chart () - show chart for accident

      Attr:
       $labels_chart
       $data_chart

=cut
# **********************************************************
sub _accident_report_chart {

  my ($labels_chart, $data_chart) = @_;

  print $html->chart({
    TYPE              => 'bar',
    X_LABELS          => $labels_chart,
    DATA              => {
      $lang{ACCIDENT_QUANTITY} => $data_chart,
    },
    BACKGROUND_COLORS => {
      $lang{ACCIDENT_QUANTITY} => 'rgba(34, 187, 51, 0.8)',
    },
    FILL              => 'false',
    OUTPUT2RETURN     => 1,
    IN_CONTAINER      => 1
  });

}
1