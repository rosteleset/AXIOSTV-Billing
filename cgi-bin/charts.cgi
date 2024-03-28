#!/usr/bin/perl
=head1 NAME

  charts.cgi

=head2 SYNOPSIS

  This CGI is used to see a traffic by severous types.

  Traffic type can be one of:
    * NAS
    * UID (Login)
    * Tags
    * Group
    * Tarrif plans

=cut
use strict;
use warnings 'FATAL' => 'all';
use v5.16;

our $VERSION = 0.95;

our $begin_time;
BEGIN {
  eval {
    require Time::HiRes;
  };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
  else {
    $begin_time = 0;
  }

  print "Content-Type: text/html\n\n";
  # open(STDERR, ">&STDOUT");
}
use POSIX qw(strftime);
use Time::Local qw/timelocal/;
use lib '../lib';

use AXbills::Init qw/$admin $db %conf $DATE $base_dir @MODULES $var_dir/;
use AXbills::Base qw(in_array days_in_month convert gen_time _bp load_pmodule);
use AXbills::HTML;

our Admins $admin;
our (%lang, $var_dir);

# To avoid loading AXbills::Templates, redefining _error_show
{
  # Disable for this block only
  no warnings 'redefine';
  #sub _error_show;

  require AXbills::Misc;

  *_error_show = sub {
    my ($module) = @_;
    return unless ($module->{errno});

    $module->{sql_errstr} //= $module->{errstr};
    $module->{sql_errno} //= $module->{errno};

    print "<div class='alert alert-danger'>[$module->{sql_errno}] $module->{sql_errstr}</div><br>"
  };
}

my $DEBUG = 0;

#$is_ipn is global flag, that gets up if no traffic in `s_detail` table or NAS_TYPE matches listed below types
my $is_ipn = 1;

#Flag for showing 'all' of the type
my $MULTI_SEL = 0;

my $html = AXbills::HTML->new({
  CONF       => \%conf,
  NO_PRINT   => 0,
  PATH       => $conf{WEB_IMG_SCRIPT_PATH} || '../',
  CHARSET    => $conf{default_charset},
  #HTML_STYLE => 'default_adm'
});

if ($html->{language} ne 'english') {
  do $base_dir . "/language/english.pl";
}
if (-f $base_dir . "/language/$html->{language}.pl") {
  do $base_dir . "/language/$html->{language}.pl";
}

my $DAILY_PERIOD = 86400;
my $WEEKLY_PERIOD = 7 * $DAILY_PERIOD;
my $MONTHLY_PERIOD = 30 * $DAILY_PERIOD;
my $THREE_MONTHES_PERIOD = 90 * $DAILY_PERIOD;

my %TIME_PERIODS = (
  1 => {
    NAME   => $lang{DAY},
    PERIOD => $DAILY_PERIOD
  },
  2 => {
    NAME   => $lang{WEEK},
    PERIOD => $WEEKLY_PERIOD
  },
  3 => {
    NAME   => $lang{MONTH},
    PERIOD => $MONTHLY_PERIOD
  },
  4 => {
    NAME   => "3 $lang{MONTHES_A}",
    PERIOD => $THREE_MONTHES_PERIOD
  }
);

my %TRAFFIC_CLASSES = ();
my %TYPE_NAMES_FOR = ();

$lang{RECV} = $lang{RECV} || 'Received';
$lang{SENT} = $lang{SENT} || 'Sent';
$lang{LOCAL} = $lang{LOCAL} || 'Local';

my $RECV_TRAFF_NAME_GLOBAL = $lang{RECV};
my $SENT_TRAFF_NAME_GLOBAL = $lang{SENT};
my $RECV_TRAFF_NAME_LOCAL = "$lang{RECV} $lang{LOCAL}";
my $SENT_TRAFF_NAME_LOCAL = "$lang{SENT} $lang{LOCAL}";

load_pmodule('JSON');
load_pmodule('Time::Local');

if (scalar(keys %FORM) > 0) {

  #Read debug from $FORM
  $DEBUG = $FORM{DEBUG} || $DEBUG;

  #Enable DB debug if debug level is higher or equal 2
  $admin->{debug} = $DEBUG >= 2;

  #Default chart type is bits
  $FORM{type} = 'bits' if (!$FORM{type});

  #Transform from old period type
  if ($FORM{period} && $FORM{period} ne 'all') {
    $FORM{$FORM{period}} = 1;
  }

  my $EXPLICIT_DATE = 0;
  if ($FORM{DATE} && $FORM{DATE} ne '' && $FORM{DATE} =~ /\d{4}-\d{2}-\d{2}/) {
    my ($year, $mon, $mday) = split(/-/, $FORM{DATE});
    $EXPLICIT_DATE = timelocal(1, 0, 0, 0 + $mday, 0 + $mon - 1, 0 + $year);
  }
  else {
    $EXPLICIT_DATE = timelocal(localtime());
  }

  print_head();

  my @charts_config = form_charts_configuration(\%FORM);

  build_graphics(@charts_config, $EXPLICIT_DATE);

  print_footer();
}
else {
  print_head();
  $html->message('err', 'Incorrect parameters');
}


#**********************************************************
=head2 form_charts_configuration($attr)

=cut
#**********************************************************
sub form_charts_configuration {
  my ($attr) = @_;

  #If there is no $conf{SYSTEM_ADMIN} will throw error and exit. This allows to bypass this situation
  delete $admin->{errno};

  my $type = '';
  my $CAPTION = '';

  my $WHERE = '';
  my $bind_values = [];
  my $EXT_TABLE = '';

  my @ids = ();

  if ($attr->{'ACCT_SESSION_ID'}) {
    $WHERE = "acct_session_id= ?";
    push(@{$bind_values}, $attr->{ACCT_SESSION_ID});
    $CAPTION = "ACCT_SESSION_ID";
    @ids = ($attr->{'ACCT_SESSION_ID'});
  }
  elsif ($attr->{'LOGIN'}) {
    $type = 'USER';
    $CAPTION = "LOGIN";

    my @logins_arr = split(',\s?', $FORM{LOGIN});
    my $login_placeholders = join(', ', ('?') x scalar(@logins_arr));
    $admin->query("SELECT uid FROM users WHERE id IN ($login_placeholders);", undef, { Bind => \@logins_arr });
    _error_show($admin) and return 0;

    @ids = map {$_->[0]} @{$admin->{list}};

    $WHERE = "l.uid=?";
    $EXT_TABLE = "
      INNER JOIN users u ON (u.uid=l.uid)
      ";
  }
  elsif ($attr->{'UID'}) {
    $type = 'USER';
    if ($attr->{'UID'} eq 'all') {
      $MULTI_SEL = 1;
      my $login_list = _get_login_list();
      @ids = map {$_->[0]} @$login_list;
    }
    else {
      @ids = split(',\s?', $attr->{'UID'});
    }
    $WHERE = "l.uid=?";
    push(@{$bind_values}, $attr->{UID});
    $CAPTION = "USER UID";

    #$EXT_TABLE = "INNER JOIN users u ON (u.uid=l.uid) ";
  }
  elsif ($attr->{'NAS_ID'}) {
    $CAPTION = "NAS_ID";
    $type = 'NAS';
    if ($attr->{'NAS_ID'} eq 'all') {
      $MULTI_SEL = 1;

      my $nas_list = _get_nas_list();
      @ids = map {$_->[0]} @$nas_list;
    }
    else {
      @ids = ($attr->{'NAS_ID'});
    }
    $WHERE = "l.nas_id=?";
    push(@{$bind_values}, $attr->{'NAS_ID'});
  }
  elsif ($attr->{'TP_ID'}) {
    $type = 'TP';
    $CAPTION = "TP_ID";
    if ($attr->{'TP_ID'} eq 'all') {
      $MULTI_SEL = 1;

      my $tp_list = _get_tp_list();
      @ids = map {$_->[0]} @$tp_list;
    }
    else {
      @ids = ($attr->{TP_ID});
    }

    $WHERE = "internet.tp_id= ?";

    my $internet_table = 'internet_main';

    $EXT_TABLE = "INNER JOIN users u ON (u.uid=l.uid)
      INNER JOIN $internet_table internet ON (internet.uid=u.uid) ";
  }
  elsif ($attr->{'GID'}) {
    $type = 'GROUP';
    $CAPTION = "GROUP ID";

    if ($attr->{'GID'} eq 'all') {
      $MULTI_SEL = 1;
      my $g_list = _get_group_list();
      @ids = map {$_->[0]} @$g_list;
    }
    else {
      @ids = ($attr->{'GID'});
    }

    $WHERE = "u.gid=?";
    push(@{$bind_values}, $attr->{GID});

    $EXT_TABLE = "INNER JOIN users u ON (u.uid=l.uid) ";
  }
  elsif ($attr->{'TAG_ID'}) {
    $type = 'TAG';
    $CAPTION = $lang{TAGS};

    @ids = ($attr->{'TAG_ID'});

    $WHERE = "tu.tag_id= ?";
    push(@{$bind_values}, $attr->{TAG_ID});

    $EXT_TABLE = "INNER JOIN tags_users tu ON (tu.uid=l.id) ";
  }

  if ($admin->{errno}) {
    $html->message('danger', 'SQL Error', $admin->{errstr});
    _error_show($admin);
    exit 1;
  }

  return ($EXT_TABLE, $WHERE, $bind_values, $type, \@ids);
}

#**********************************************************
=head2  build_graphics($EXT_TABLE, $WHERE, $bind_values, $type, $ids, $current_time) Parse input and make charts

  Arguments:
    $EXT_TABLE
    $WHERE
    $bind_values
    $type
    $ids
    $current_time

  Returns:

=cut
#**********************************************************
sub build_graphics {
  my ($EXT_TABLE, $WHERE, $bind_values, $type, $ids, $current_time) = @_;

  if (scalar(@$ids) > 1) {
    $MULTI_SEL = 1;
  }

  my $i = 0;
  foreach my $key (@$ids) {
    $i++;

    if ($MULTI_SEL) {
      my $search_key = $WHERE;
      $search_key =~ s/=.*$//g;
      $WHERE = "$search_key=?";
      $bind_values = [ $key ];
    }

    my @chart_periods = ($conf{IPN_DETAIL_CLEAN_PERIOD} && $conf{IPN_DETAIL_CLEAN_PERIOD} >= 90)
      ? (1 ... 4)
      : (1 ... 3);

    # Get max period
    my $max_period = $chart_periods[$#chart_periods];

    # Period we need to get from DB
    my $start_time = $current_time - $TIME_PERIODS{$max_period}{PERIOD};

    my $speed_list = get_speed_cached($EXT_TABLE, $WHERE, $bind_values, $start_time, $current_time, $type, $key);

    my $name = get_name_for($type, $key) || '';
    my %charts_for_period = ();

    $charts_for_period{1} = make_chart(
      $speed_list, "$type: '$name' ($key) ", $start_time, $current_time
    );
    show_tabbed(\%charts_for_period, $i);
  }

  return 1;
}

#**********************************************************
=head2 get_traffic($EXT_TABLE, $WHERE, $bind_values, $start, $end_time)

  Arguments:
    $EXT_TABLE
    $WHERE
    $bind_values
    $start
    $end_time

  Returns:
    $list

=cut
#**********************************************************
sub get_traffic {
  my ($EXT_TABLE, $WHERE, $bind_values, $start, $end_time) = @_;

  my $multiply_for_bytes = ($FORM{type} ne 'bytes')
    ? ' * 8 '
    : '';

  my $list;

  my $ipn_traffic = (!$conf{CHARTS_SKIP_IPN}
    ? get_ipn_traffic($multiply_for_bytes, $EXT_TABLE, $WHERE, $bind_values, $start, $end_time)
    : 0
  );

  if (!$admin->{errno} && $ipn_traffic && ref $ipn_traffic eq 'ARRAY' && scalar(@$ipn_traffic) > 0) {
    $is_ipn = 1;
    $list = $ipn_traffic;
  }
  else {
    $is_ipn = 0;
    $list = get_pppoe_traffic($multiply_for_bytes, $EXT_TABLE, $WHERE, $bind_values, $start, $end_time);
  }

  _error_show($admin) and return 0;

  return $list;
}

#**********************************************************
=head2 get_ipn_traffic($multiply_for_bytes, $EXT_TABLE, $WHERE, $bind_values, $start_time, $end_time)

=cut
#**********************************************************
sub get_ipn_traffic {
  my ($multiply_for_bytes, $EXT_TABLE, $WHERE, $bind_values, $start_time, $end_time) = @_;

  my $traffic_classes = get_traffic_classes();

  #form query for each traffic class
  my $select_query_traffic_classes = '';
  my @traffic_classes_ids = sort(keys(%{$traffic_classes}));
  my @query_fields = ('UNIX_TIMESTAMP(l.start) AS start');
  for (my ($i, $len) = (0, scalar @traffic_classes_ids); $i < $len; $i++) {
    push @query_fields, " SUM(IF(traffic_class=$i, l.traffic_in, 0)) $multiply_for_bytes",
      " SUM(IF(traffic_class=$i, l.traffic_out, 0)) $multiply_for_bytes";
    #    $select_query_traffic_classes .= ($i != $len - 1) ? ",\n" : '';
  }

  $select_query_traffic_classes = join(', ', @query_fields);

  my $sql = "SELECT $select_query_traffic_classes
      FRoM ipn_log l
      $EXT_TABLE
      WHERE $WHERE AND UNIX_TIMESTAMP(l.start) > $start_time AND UNIX_TIMESTAMP(l.start) < ($end_time)
      GROUP BY 1
      ORDER BY l.start;";

  $admin->query($sql, undef, { Bind => $bind_values });

  return $admin->{list} || [];
}

#**********************************************************
=head2 get_pppoe_traffic($multiply_for_bytes, $EXT_TABLE, $WHERE, $bind_values, $start_time, $end_time)

  Arguments:
    $multiply_for_bytes
    $EXT_TABLE
    $WHERE
    $bind_values
    $start_time
    $end_time

  Returns:
    %$list

=cut
#**********************************************************
sub get_pppoe_traffic {
  my ($multiply_for_bytes, $EXT_TABLE, $WHERE, $bind_values, $start_time, $end_time) = @_;

  $admin->query("SELECT l.last_update,
      SUM(l.recv1) $multiply_for_bytes,
      SUM(l.sent1) $multiply_for_bytes,
      SUM(l.recv2) $multiply_for_bytes,
      SUM(l.sent2) $multiply_for_bytes
      FROM s_detail l
      $EXT_TABLE
      WHERE $WHERE AND l.last_update > $start_time AND l.last_update < $end_time
      GROUP BY 1
      ORDER BY l.last_update;", undef
    , { Bind => $bind_values }
  );
  _error_show($admin);

  return $admin->{list} || [];
}

#**********************************************************
=head2 get_speed_for_traffic($attr) - forms chart series from DB list

  Each line of list must be represented as [ timestamp, recv1, sent1, ..., recvN, sentN ]

  Counts speed

  Arguments:
    $attr
      LIST - Array ref list from db
      NAMES - Array ref with names of lines. MUST contain (LIST->[0]->length-1) elements

  Returns:
    \@series

=cut
#**********************************************************
sub get_speed_for_traffic {
  my ($attr) = @_;

  if (!defined $attr->{LIST} || ref $attr->{LIST} ne 'ARRAY' || !defined $attr->{LIST}->[0]) {
    return "No data";
  }

  my @traffic_list = @{$attr->{LIST}};

  #check input params
  my $list_length = scalar @{$traffic_list[0]} || 0;
  my $series_count = $list_length - 1;
  unless ($list_length) {
    return "No data";
  };

  #init
  my @result_data_array = ();
  my @previous_row = (0);

  my $timestamp = 0;
  my $pause = 1;

  foreach my $line (@traffic_list) {
    $timestamp = +($line->[0]);
    $pause = ($timestamp - $previous_row[0]) || 300;

    my ($traffic_delta, $speed) = (0, undef);

    my @speeds = ();
    for (my $i = 1; $i <= $series_count; $i++) {
      if ($line->[$i]) {
        if ($is_ipn) {
          $traffic_delta = $line->[$i];
        }
        # Ignore negative speed values
        elsif ($previous_row[$i] && ($line->[$i] >= $previous_row[$i])) {
          $traffic_delta = +($line->[$i] - $previous_row[$i]);
        }

        $speed = $traffic_delta / $pause;
      }
      else {
        ($traffic_delta, $speed) = (0, 0);
      }

      push(@speeds, $speed);
    }

    push(@result_data_array, [ $timestamp, @speeds ]);

    @previous_row = @{$line};
  }

  # Highcharts needs data to be sorted
  @result_data_array = sort {$a->[0] <=> $b->[0]} @result_data_array;

  return \@result_data_array;
}


#**********************************************************
=head2 get_speed_cached($EXT_TABLE, $WHERE, $bind_values, $start_time, $current_time, $type, $key)

=cut
#**********************************************************
sub get_speed_cached {
  my ($EXT_TABLE, $WHERE, $bind_values, $start_time, $current_time, $type, $key) = @_;

  my $get_traffic_start_time = $start_time;
  my $traffic_classes = get_traffic_classes();

  my @speed_list = ();
  # Optimized to return ref from get_speed_traffic if any
  my $speed_list_ref = undef;

  if ($conf{CHARTS_RRD}) {
    load_pmodule("RRDTool::OO");
    my $rrd_file_name = "$var_dir\_$type\_$key.rrd";
    my $rrd = RRDTool::OO->new(file => $rrd_file_name);

    # Check if RRD file exists
    if (-f $rrd_file_name) {
      # If RRD file exists, get last date
      my $last_time = $rrd->last();

      # Max period will be 3 monthes # TODO: OPTIMIZE to max period
      if ($last_time < ($current_time - $THREE_MONTHES_PERIOD)) {
        $last_time = $current_time - $THREE_MONTHES_PERIOD;
        $get_traffic_start_time = $last_time;
      }
      # Skip fetching DB if less than 5 min gap
      elsif ($current_time < ($last_time - 300)) {
        $get_traffic_start_time = 0;
      }
      else {
        $get_traffic_start_time = $last_time;
      }
    }
    else {
      my @ds_array = ();
      my @ar_array = ();
      foreach my $traffic_class_id (sort keys %$traffic_classes) {
        push(@ds_array,
          'data_source',
          {
            name => "$traffic_class_id\_in",
            type => "GAUGE"
          },
          'data_source',
          {
            name => "$traffic_class_id\_out",
            type => "GAUGE"
          }
        );

        push(@ar_array,
          'archive',
          { rows => 105120 },
          'archive',
          { rows => 105120 }
        );
      }

      $rrd->create(
        step  => 300,
        start => $current_time - $THREE_MONTHES_PERIOD,
        @ds_array, @ar_array
      );

      $get_traffic_start_time = $current_time - $THREE_MONTHES_PERIOD;
    }

    if ($get_traffic_start_time) {
      # Get traffic from DB till $current_time
      my $traffic_list = get_traffic($EXT_TABLE, $WHERE, $bind_values, $get_traffic_start_time, $current_time);

      # If have new traffic, get last timestamp from traffic list and check if need to update RRD file
      if ($rrd && $traffic_list && ref $traffic_list eq 'ARRAY' && scalar(@$traffic_list) > 0) {

        my $speeds = get_speed_for_traffic({
          LIST         => $traffic_list,
          NAMES        => get_traffic_classes_names(),
          PERIOD_START => $get_traffic_start_time,
          PERIOD_END   => $current_time
        });

        # Here we think that all series contain same count of points as first
        my $points_count = scalar(@$speeds);

        for (my $j = 0; $j < $points_count; $j += 1) {
          my ($timestamp, @data) = @{$speeds->[$j]};
          next unless @data;
          $rrd->update(time => $timestamp, values => \@data);
        }
      }
    }

    $rrd->fetch_start(start => $start_time, resolution => 300);

    # Jump to first defined value
    $rrd->fetch_skip_undef();

    my $time = 0;
    while ($time < $current_time) {
      my @values = ();
      ($time, @values) = $rrd->fetch_next;
      push(@speed_list, [ $time, @values ]);
    }
  }
  else {
    my $traffic_list = get_traffic($EXT_TABLE, $WHERE, $bind_values, $get_traffic_start_time, $current_time);
    $speed_list_ref = get_speed_for_traffic({
      LIST         => $traffic_list,
      NAMES        => get_traffic_classes_names(),
      PERIOD_START => $get_traffic_start_time,
      PERIOD_END   => $current_time
    });
  }

  return $speed_list_ref || \@speed_list;
}


#**********************************************************
=head2 make_chart($list, $title, $start, $end) - Convert list to chart

=cut
#**********************************************************
sub make_chart {
  my ($speed_list, $title, $start, $end) = @_;
  if ($DEBUG >= 1) {
    print "<hr><b>$title</b>";
  }

  my $series = get_charts_series({
    LIST         => $speed_list,
    NAMES        => ($is_ipn) ? get_traffic_classes_names() : [
      $RECV_TRAFF_NAME_GLOBAL,
      $SENT_TRAFF_NAME_GLOBAL,
      $RECV_TRAFF_NAME_LOCAL,
      $SENT_TRAFF_NAME_LOCAL
    ],
    PERIOD_START => $start,
    PERIOD_END   => $end
  });

  #check for errors

  if (ref $series ne 'ARRAY') {
    if ($series eq "No data") {
      my $named_start = POSIX::strftime "%Y-%m-%d", localtime($start);
      my $named_end = POSIX::strftime "%Y-%m-%d", localtime($end);
      return "<br> <b>$title</b>: $named_start...$named_end : $lang{NO_RECORD} <br>";
    }
    return $series;
  }

  my $chart_type = $FORM{type} || 'bits';

  my $chart = get_highchart({
    TITLE   => $html->b($title),
    Y_TITLE => "$lang{SPEED}, $chart_type",
    TYPE    => 'area',
    SERIES  => $series,
    HEIGHT  => $FORM{height},
    WIDTH   => $FORM{width},
  });

  return $chart;
}

#**********************************************************
=head2 get_highchart($attr) - Build chart HTML from chart series

  Arguments:
    SERIES - arr_ref of hash_ref

    CONTAINER - string HTML id
    TYPE      - chart type (default bar)
    TITLE     - chart title
    Y_TITLE   - title for Y axis

    HEIGHT    - px
    WIDTH     - px

  Returns:
    HTML code

=cut
#**********************************************************
sub get_highchart {
  my ($attr) = @_;

  my $json = JSON->new->utf8(0);

  state $chartCounter = 0;

  my $buttonCounter = $chartCounter;
  my $chartDivId = $attr->{CONTAINER} || "CHART_CONTAINER_" . $chartCounter++;
  my $chartType = $attr->{TYPE} || 'bar';
  my $series = $attr->{SERIES};
  my $chartTitle = $attr->{TITLE};
  my $chartYAxisTitle = $attr->{Y_TITLE} || 'null';
  my $current_time = timelocal(localtime()) * 1000;
  my $day_start = $current_time - $TIME_PERIODS{1}{PERIOD} * 1000;
  my $week_start = $current_time - $TIME_PERIODS{2}{PERIOD} * 1000;
  my $month_start = $current_time - $TIME_PERIODS{3}{PERIOD} * 1000;
  my $months_start = $current_time - $TIME_PERIODS{4}{PERIOD} * 1000;

  my $chartSeries = $json->encode($series);
#print $chartSeries;
  my $dimensions = '; width : 700px';
  if ($attr->{HEIGHT}) {
    $dimensions = "; height : $attr->{HEIGHT}";
    if ($attr->{WIDTH}) {
      $dimensions .= "; width : $attr->{WIDTH}";
    }
  }

  my $months_button = '';
  if (exists $conf{IPN_DETAIL_CLEAN_PERIOD} && $conf{IPN_DETAIL_CLEAN_PERIOD} >= 90) {
    $months_button = qq'<button type="button" class="btn btn-secondary" id="zoom_months_$buttonCounter">3 $lang{MONTHES_A}</button>';
  }

  my $default_range = $conf{CHARTS_DEFAULT_USER_STATISTIC} || '';
  my $result = qq{
    <div class="btn-group">
      <button type="button" class="btn btn-secondary" id='zoom_day_$buttonCounter'>$lang{DAY}</button>
      <button type="button" class="btn btn-secondary" id='zoom_week_$buttonCounter'>$lang{WEEK}</button>
      <button type="button" class="btn btn-secondary" id='zoom_month_$buttonCounter'>$lang{MONTH}</button>
      $months_button
    </div>
    <div id='$chartDivId' style='margin: 5px auto; border: 1px solid silver $dimensions'></div>
    <script>
    jQuery(function () {

      Highcharts.setOptions({
        global: {
          timezoneOffset: (new Date).getTimezoneOffset()
        }
      });

      jQuery('#$chartDivId').highcharts({
        chart : { type: '$chartType', zoomType: 'x' },
        plotOptions: { series : { softTreshold : true, turboThreshold: 0, allowPointSelect: true } },
        title : { text: "$chartTitle"},
        series: $chartSeries,
        xAxis : { type : 'datetime' },
        yAxis : { title: { text: '$chartYAxisTitle' }, min : 0},
        tooltip : {formatter : labelFormatter },
        rangeSelector : {
            allButtonsEnabled: true
        }
      });

      jQuery('#zoom_day_$buttonCounter').click(function () {
        var chart = jQuery('#$chartDivId').highcharts();
        chart.xAxis[0].setExtremes($day_start, $current_time);
      });

      var default_range = '$default_range';
      if(default_range == 'day'){
        var chart = jQuery('#$chartDivId').highcharts();
        chart.xAxis[0].setExtremes($day_start, $current_time);
      } else if(default_range == 'week'){
        var chart = jQuery('#$chartDivId').highcharts();
        chart.xAxis[0].setExtremes($week_start, $current_time);
      } else if(default_range == 'month'){
        var chart = jQuery('#$chartDivId').highcharts();
        chart.xAxis[0].setExtremes($month_start, $current_time);
      }
      jQuery('#zoom_week_$buttonCounter').click(function () {
        var chart = jQuery('#$chartDivId').highcharts();
        chart.xAxis[0].setExtremes($week_start, $current_time);
      });

      jQuery('#zoom_month_$buttonCounter').click(function () {
        var chart = jQuery('#$chartDivId').highcharts();
        chart.xAxis[0].setExtremes($month_start, $current_time);
      });

      jQuery('#zoom_months_$buttonCounter').click(function () {
        var chart = jQuery('#$chartDivId').highcharts();
        chart.xAxis[0].setExtremes($months_start, $current_time);
      });
    });
    </script>
};

  return $result;
}

#**********************************************************
=head2 get_charts_series($attr) - forms chart series from DB list

  Each line of list must be represented as [ timestamp, recv1, sent1, ..., recvN, sentN ]

  Counts speed

  Arguments:
    $attr
      LIST - Array ref, list of timestamp and speed
      NAMES - Array ref with names of lines. MUST contain (LIST->[0]->length-1) elements

      PERIOD_START - timestamp
      PERIOD_END   - timestamp

  Returns:
    \@series

=cut
#**********************************************************
sub get_charts_series {
  my ($attr) = @_;

  unless (defined $attr->{LIST} && ref $attr->{LIST} eq 'ARRAY' && defined $attr->{LIST}->[0] && defined $attr->{NAMES}) {
    return "No data";
  }
  unless (defined $attr->{PERIOD_START} && defined $attr->{PERIOD_END}) {
    return "Wrong input parameters.\n PERIOD_START and PERIOD_END are mandatory.";
  }

  my @speed_list = @{$attr->{LIST}};
  my @names = @{$attr->{NAMES}};

  my $start = $attr->{PERIOD_START};
  my $end = $attr->{PERIOD_END};

  #check input params
  my $list_length = scalar @{$speed_list[0]} || 0;
  my $names_length = scalar @names || 0;

  my $series_count = $list_length - 1;

  if ($names_length < $series_count) {
    unless ($list_length) {
      return "No data";
    }
    return "Wrong input parameters.\n Count of \@lines ($series_count) MUST be more than count of \@names($names_length).";
  }

  # Init
  my @result_data_array = ();
  my @previous_row = ($start);

  for (my $i = 1; $i <= $series_count; $i++) {
    push(@previous_row, 0);
    # Start data array from timestamp that equal to period_start
    # Multiplying to 1000 because JavaScript timestamp uses milliseconds
    $result_data_array[$i] = [ { x => +($start * 1000), y => undef } ];
  }

  my $timestamp = 0;
  my $pause = 300;

  foreach my $line (@speed_list) {
    $timestamp = +($line->[0]);
    next if ($timestamp < $start);
    last if ($timestamp > $end);
    $pause = ($timestamp - $previous_row[0]) || 300;

    # Ignore periods with more than 5 min pause
    if (($pause > 300) && !$conf{CHARTS_LONG_PAUSE}) {
      for (my $i = 1; $i <= $series_count; $i++) {
        push(@{$result_data_array[$i]},
          { x => +($previous_row[0] * 1000 + 2), y => undef },
          { x => +($timestamp * 1000 - 2), y => undef }
        );
      }
    }
    else {

      for (my $i = 1; $i <= $series_count; $i++) {
        push(@{$result_data_array[$i]}, { x => $timestamp * 1000, y => +($line->[$i] || 0) });
      }

    }

    @previous_row = @{$line};
  }

  my @series = ();
  for (my $i = 1; $i <= $series_count; $i++) {
    # Finish data array with timestamp that corresponds to period end
    push @{$result_data_array[$i]}, { x => $end * 1000, y => undef };

    # Highcharts needs data to be sorted
    @{$result_data_array[$i]} = sort {$a->{x} <=> $b->{x}} @{$result_data_array[$i]};
    push @series, { name => $names[$i - 1], data => $result_data_array[$i] };
  }

  return \@series;
}


#**********************************************************
=head2 get_traffic_classes()

  If %traffic_classes are not filled, gots list from DB and fills %traffic_classes

  Returns
   hash_ref \%traffic_classes

=cut
#**********************************************************
sub get_traffic_classes {

  if (scalar keys %TRAFFIC_CLASSES <= 0) {
    $admin->query("SELECT id, name FROM traffic_classes ORDER BY id", undef, { COLS_NAME => 1 });

    foreach my $traffic_class (@{$admin->{list}}) {
      $TRAFFIC_CLASSES{$traffic_class->{id}} = $traffic_class->{name};
    }
  }

  return \%TRAFFIC_CLASSES;
}

#**********************************************************
=head2 get_traffic_classes_names()

  Returns list of traffic_names

=cut
#**********************************************************
sub get_traffic_classes_names {

  my $traffic_classes = get_traffic_classes();

  my @traffic_names = ();

  foreach my $traffic_class_id (sort keys %{$traffic_classes}) {
    my $name = $traffic_classes->{$traffic_class_id};
    push @traffic_names, "$name $lang{RECV}";
    push @traffic_names, "$name $lang{SENT}";
  }

  return \@traffic_names;
}

#**********************************************************
=head2 get_name_for($key)

=cut
#**********************************************************
sub get_name_for {
  my ($type, $key) = @_;

  if (!$TYPE_NAMES_FOR{$key}) {
    if ($type eq 'TP') {
      $TYPE_NAMES_FOR{$key} = @{_get_tp_list($key)}[0]->[1];
    }
    elsif ($type eq 'NAS') {
      $TYPE_NAMES_FOR{$key} = @{_get_nas_list($key)}[0]->[1];
    }
    elsif ($type eq 'GROUP') {
      $TYPE_NAMES_FOR{$key} = @{_get_group_list($key)}[0]->[1];
    }
    elsif ($type eq 'LOGIN') {
      $TYPE_NAMES_FOR{$key} = @{_get_login_list($key)}[0]->[1];
    }
    elsif ($type eq 'TAG') {
      $TYPE_NAMES_FOR{$key} = @{_get_tags_list($key)}[0]->[1];
    }
    elsif ($type eq 'USER') {
      $TYPE_NAMES_FOR{$key} = @{_get_uid_list($key)}[0]->[1] || do {
        print "$lang{USER} $lang{ERR_NOT_EXISTS}";
        exit 1;
      };
    }
    else {
      $TYPE_NAMES_FOR{$key} = '';
    }
  }

  return $TYPE_NAMES_FOR{$key};
}

#**********************************************************
=head show_tabbed($charts_period);

  Arguments:
    $charts_period

  Returns:

=cut
#**********************************************************
sub show_tabbed {
  my ($charts_period) = @_;

  my $tabs = qq{
   <!-- Tab panes -->
      <div>
        $charts_period->{1}
      </div>
    };

  print $tabs;
}

#**********************************************************
=head2 _get_tp_list($id)

=cut
#**********************************************************
sub _get_tp_list {
  my ($id) = @_;

  my $WHERE = '';
  my @BIND_VALUES = ();
  if ($id && $id ne '') {
    $WHERE = "tp_id=? AND";
    push @BIND_VALUES, $id;
  }

  $admin->query("SELECT tp_id, name FROM tarif_plans WHERE $WHERE module IN ('Dv', 'Internet') ORDER BY id;", undef, { Bind => \@BIND_VALUES });
  _error_show($admin);

  return $admin->{list} || [ [ 0, 0 ] ];
}

#**********************************************************
=head2 _get_nas_list($id)

=cut
#**********************************************************
sub _get_nas_list {
  my ($id) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();

  if ($id) {
    $WHERE = "id= ?  AND";
    push @BIND_VALUES, $id;
  }

  $admin->query("SELECT id, name FROM nas WHERE $WHERE disable=0 ORDER BY id;", undef, { Bind => \@BIND_VALUES });

  return $admin->{list} || [ [ 0, 0 ] ];
}

#**********************************************************
=head2 _get_group_list($id)

=cut
#**********************************************************
sub _get_group_list {
  my ($id) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();

  if ($id) {
    $WHERE = "WHERE gid=?";
    push @BIND_VALUES, $id;
  }

  $admin->query("SELECT gid, name FROM groups $WHERE ORDER BY gid;", undef, { Bind => \@BIND_VALUES });

  return $admin->{list} || [ [ 0, 0 ] ];
}

#**********************************************************
=head _get_login_list($id)

=cut
#**********************************************************
sub _get_login_list {
  my ($id) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();
  if ($id && $id ne '') {
    $WHERE = "id=? AND";
    push @BIND_VALUES, $id;
  }

  $admin->query("SELECT uid, id FROM users WHERE $WHERE disable=0 and deleted=0 ORDER BY id;", undef,
    { Bind => \@BIND_VALUES });

  return $admin->{list} || [ [ 0, 0 ] ];
}

#**********************************************************
=head _get_uid_list($uid)

=cut
#**********************************************************
sub _get_uid_list {
  my ($uid) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();
  if ($uid && $uid ne '') {
    $WHERE = "uid= ? AND";
    push @BIND_VALUES, $uid;
  }

  $admin->query("SELECT uid, id FROM users WHERE $WHERE disable=0 and deleted=0 ORDER BY uid;", undef,
    { Bind => \@BIND_VALUES });

  return $admin->{list} || [ [ 0, 0 ] ];
}

#**********************************************************
#
#**********************************************************
sub _get_tags_list {
  my ($id) = @_;
  my $WHERE = '';
  my @BIND_VALUES = ();
  if ($id && $id ne '') {
    $WHERE = "WHERE id= ?";
    push @BIND_VALUES, $id;
  }

  $admin->query("SELECT id, name FROM tags $WHERE ORDER BY name;", undef, { Bind => \@BIND_VALUES });

  return $admin->{list} || [ [ 0, 0 ] ];
}

#**********************************************************
=head2 print_head()

=cut
#**********************************************************
sub print_head {
  print <<"[END]";
<!DOCTYPE HTML>
<HTML>
<head>
  <meta charset='utf-8'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>

  <meta http-equiv='Cache-Control' content='no-cache' />
  <meta http-equiv='Pragma' content='no-cache' />

  <link href='favicon.ico' rel='shortcut icon' />

  <!-- CSS -->
  <link rel='stylesheet' type='text/css' href='/styles/$html->{HTML_STYLE}/css/adminlte.min.css' >

  <!-- Bootstrap -->
  <script src='/styles/$html->{HTML_STYLE}/js/jquery.min.js'></script>
  <script src='/styles/$html->{HTML_STYLE}/js/bootstrap.bundle.min.js'></script>

  <script src='/styles/$html->{HTML_STYLE}/js/functions.js' type='text/javascript' language='javascript'></script>

  <script src='/styles/$html->{HTML_STYLE}/plugins/moment/moment.min.js'></script>
  <script src='/styles/$html->{HTML_STYLE}/js/charts/highcharts.js'></script>
  <script src='/styles/$html->{HTML_STYLE}/js/select2.min.js'></script>
  <link rel='stylesheet' type='text/css' href='/styles/$html->{HTML_STYLE}/css/select2.css'>
  <title>ABillS Users Traffic</title>

  <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
  <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
  <!--[if lt IE 9]>
    <script src='https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js'></script>
    <script src='https://oss.maxcdn.com/respond/1.4.2/respond.min.js'></script>
  <![endif]-->
</head>
<body>
<div class='container'>
  <div class='row'>
    <noscript> JavaScript required </noscript>
[END]

  return 1;
}

#**********************************************************
=head2 print_footer()

=cut
#**********************************************************
sub print_footer {

  my $traffic_type_html = '';

  if (!$FORM{SHOW_GRAPH}) {
    foreach my $name ('bits', 'bytes') {
      if ($FORM{type} && $FORM{type} eq $name) {
        $traffic_type_html .= $html->b($name) . ' ';
      }
      else {
        $ENV{QUERY_STRING} =~ s/\&type=\S+//g;
        $traffic_type_html .= "<a href='$SELF_URL?$ENV{QUERY_STRING}&type=$name' class='btn btn-secondary'>$name</a> \n";
      }
    }
  }

  if ($begin_time > 0) {
    my $gen_time = gen_time($begin_time);
    print "<hr><div class='row' id='footer'>" . "Version: $VERSION ( $gen_time )</div>";
  }

  print <<"[FOOTER]";
    <div id='type' class='col-md-4 float-right'>  $traffic_type_html </div>

  </div> <!--row-->
  <script>
  function labelFormatter(){

      var trafficAmount = this.y;

      var result = '';
      var type = '';

      if (trafficAmount > 1000000000) {
        result = trafficAmount / (1024 * 1024 * 1024);
        type = 'G';
      }
      else if (trafficAmount > 1000000) {
        result = trafficAmount / (1024 * 1024);
        type = 'M';
      }
      else if (trafficAmount > 1000) {
        result = trafficAmount / 1024;
        type = 'K';
      }
      else {
        result = trafficAmount;
      }

      type+='$FORM{type}';

       var time = moment(this.x).local().format('YYYY-MM-D, HH:mm:ss');

      result = result.toFixed(2);

      return time + '<br>' + "<b>$lang{SPEED}</b> " + result + type + '/s' + '<br>';

    }
  function ensureLength(digit){
    return (new String(digit).length == 2) ? digit : ('0' + digit);
  }
  </script>
</div> <!--container-->
</body>
</html>
[FOOTER]

  return 1;
}

1;