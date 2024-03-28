package PeriodicTasks;

use strict;
use warnings FATAL => 'all';

my $html;
my $lang;

#**********************************************************
=head2 new($Tasks, $html)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $Tasks = shift;
  $html = shift;
  $lang = shift;
  
  my $self = {
    Tasks => $Tasks
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return "Позволяет делать задачу периодической.";
}

#**********************************************************
=head2 enable_plugin()
  check db and add fields if need
=cut
#**********************************************************
sub enable_plugin {
  my $self = shift;

  my $cols_arr = $self->{Tasks}->cols_arr();

  $self->{Tasks}->add_field("p_pt_period TEXT NOT NULL") unless (_in_array('p_pt_period', $cols_arr));
  $self->{Tasks}->add_field("p_pt_plan_days TINYINT(2) UNSIGNED NOT NULL DEFAULT '0'")unless (_in_array('p_pt_plan_days', $cols_arr));
  return 1;
}

#**********************************************************
=head2 fields_for_task_add()

=cut
#**********************************************************
sub fields_for_task_add {
  my $self = shift;
  my ($attr) = @_;

  my $json = qq/[{"LABEL":"Периодичность (d m w)","NAME":"P_PT_PERIOD","VALUE":"%P_PT_PERIOD%"}, {"LABEL":"Предупреждать за ... (дней)","NAME":"P_PT_PLAN_DAYS","VALUE":"%P_PT_PLAN_DAYS%"}]/;
  return $json;
}

#**********************************************************
=head2 task_done()
  run if resposible close task with state "done"
=cut
#**********************************************************
sub task_done {
  my $self = shift;
  my ($attr) = @_;
  my $task_info = $self->{Tasks}->info({ID => $attr->{ID}});
  my $cron_str = $task_info->{P_PT_PERIOD};

  my $next_date = _calculate_next_date($task_info->{CONTROL_DATE}, $cron_str);
  my $plan_date = _calculate_plan_date($next_date, $task_info->{P_PT_PLAN_DAYS});

  return 0 unless ($next_date);

  $task_info->{CONTROL_DATE} = $next_date;
  $task_info->{PLAN_DATE} = $plan_date || $next_date;
  undef($task_info->{ID});
  undef($task_info->{COMMENTS});
  undef($task_info->{STATE});

  $self->{Tasks}->add($task_info);

  return 1;
}

#**********************************************************
=head2 task_undone()
  run if resposible close task with state "undone"
=cut
#**********************************************************
sub task_undone {
  my $self = shift;
  my ($attr) = @_;

  return 1;
}

#**********************************************************
=head2 _calculate_next_date(old_date, cron_string)
  return next date
=cut
#**********************************************************

sub _calculate_next_date {
  my ($old_date_str, $cron_str) = @_;
  my ($cron_d, $cron_m, $cron_w) = split(" ", $cron_str);
  my (@cron_d_arr, @cron_m_arr, @cron_w_arr) = ();
  my $old_date = Time::Piece->strptime($old_date_str, "%Y-%m-%d");
  my $one_day = 86400;
  
  if ( $cron_d && $cron_d =~ m/\d+/ ) {
    $cron_d =~ s/[^\d\,]//g;
    push(@cron_d_arr, split(',', $cron_d));
  }
  else {
    @cron_d_arr = (1 .. 31);
  }

  if ( $cron_m && $cron_m =~ m/\d+/) {
    $cron_m =~ s/[^\d\,]//g;
    push(@cron_m_arr, split(',', $cron_m));
  }
  else {
    @cron_m_arr = (1 .. 12);
  }

  if ( $cron_w && $cron_w =~ m/\d+/) {
    $cron_w =~ s/[^\d\,]//g;
    push(@cron_w_arr, split(',', $cron_w));
  }
  else {
    @cron_w_arr = (1 .. 7);
  }

  my $i = 0;
  my $d = $old_date;
  
  while ($i < 365) {
    $d += $one_day;
    $i++;
    if (_in_array($d->_wday, \@cron_w_arr) && _in_array($d->mon, \@cron_m_arr) && _in_array($d->mday, \@cron_d_arr)) {
      last;
    }
  }
  
  my $next_date_str = $d->ymd;
  return $next_date_str;
}

#**********************************************************
=head2 _calculate_plan_date(old_date, cron_string)
  return next date
=cut
#**********************************************************

sub _calculate_plan_date {
  my ($date_str, $days) = @_;
  my $one_day = 86400;
  my $date = Time::Piece->strptime($date_str, "%Y-%m-%d");
  my $plan_date = $date - ($days * $one_day);

  return $plan_date->ymd;
}

#**********************************************************
=head2 _in_array

=cut
#**********************************************************
sub _in_array {
  my ($value, $array) = @_;

  return 0 if (!defined($value));

  if (grep { $_ eq $value } @$array) {
    return 1;
  }
  return 0;
}

1;