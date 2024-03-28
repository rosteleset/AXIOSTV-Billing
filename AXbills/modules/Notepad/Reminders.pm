package Notepad::Reminders;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Notepad::Reminders

=head2 SYNOPSIS

  Reminders calculator

=cut

use Exporter;
use base 'Exporter';

our @EXPORT = qw/calculate_next_periodic_time/;
our @EXPORT_OK = @EXPORT;

use AXbills::Base qw/_bp in_array days_in_month/;

use constant {
  PERIODIC_RULE_ONCE          => 0,
  PERIODIC_RULE_EVERY_DAY     => 1,
  PERIODIC_RULE_ON_WEEKDAYS   => 2,
  PERIODIC_RULE_WEEKDAYS_LIST => 3,
  PERIODIC_RULE_EVERY_WEEK    => 4,
  PERIODIC_RULE_EVERY_MONTH   => 5,
  SECONDS_IN_DAY              => 86400,
};

#**********************************************************
=head2 calculate_next_periodic_time($datetime, $rules, $start_time)

=cut
#**********************************************************
sub calculate_next_periodic_time {
  my ($prev_time, $rules, $start_time) = @_;
  return '' unless ( $prev_time );
  
  require POSIX;
  POSIX->import(qw/mktime strftime/);
  
  my ($date, $time) = split('\s+', $prev_time);
  $time ||= '09:00:00';
  
  my ($year, $mon, $mday) = split(/-/, $date);
  my ($hour, $min, $sec) = split(/:/, $time);
  
  my $prev_timestamp = POSIX::mktime($sec, $min, $hour, $mday, ($mon - 1), ($year - 1900));
  
  $start_time ||= do {
    my $DATE = POSIX::strftime "%Y-%m-%d", localtime(time);
    my $TIME = POSIX::strftime "%H:%M:%S", localtime(time);
    "$DATE $TIME";
  };
  
  my ($cur_date, $cur_time) = split(' ', $start_time);
  my ($cur_year, $cur_mon, $cur_mday) = split('-', $cur_date);
  my $curr_timestamp = POSIX::mktime(reverse(split(':', $cur_time)), $cur_mday, ($cur_mon - 1),
    ($cur_year - 1900));
  
  my $get_weekday = sub {
    my ($date_check) = @_;
    my ($check_year, $check_mon, $check_mday) = split(/-/, $date_check);
    
    my %localtime_hash = ();
    @localtime_hash{qw/sec min hour mday mon year wday/}
      = localtime(POSIX::mktime(0, 0, 0, $check_mday, ($check_mon - 1), ($check_year - 1900)));
    
    $localtime_hash{wday} -= 1;
    return $localtime_hash{wday};
  };
  
  my $res_date = $date;
  my $res_time = $time;
  
  my $result_timestamp = 0;
  my $result = '0000-00-00 00:00:00';
  
  my $i = 0;
  do {
    $i++;
    return 0 if ( $i > 1000 );
    # Next period
    if ( !$rules->{rule_id} ) {
      return $prev_time;
    }
    elsif ( $rules->{rule_id} == PERIODIC_RULE_EVERY_DAY ) {
      # every_day
      # Shortcut for huge date ranges
      if ( $curr_timestamp > $prev_timestamp + SECONDS_IN_DAY ) {
        $prev_timestamp = $curr_timestamp;
      };
      
      # Add one day to previous day
      $prev_timestamp += SECONDS_IN_DAY;
      $res_date = POSIX::strftime("%Y-%m-%d", localtime($prev_timestamp));
      ($year, $mon, $mday) = split('-', $res_date);
    }
    elsif (
      $rules->{rule_id} == PERIODIC_RULE_ON_WEEKDAYS
        || $rules->{rule_id} == PERIODIC_RULE_WEEKDAYS_LIST
        || $rules->{rule_id} == PERIODIC_RULE_EVERY_WEEK
    ) {
      # Add one day to previous day or few if it's last in a raw
      my @weekdays = split(',\s?', $rules->{week_day});
      
      # Shotcut for iterating huge date ranges
      if ( $curr_timestamp > $prev_timestamp ) {
        $prev_timestamp = $curr_timestamp
      }
      
      my $res_weekday = '';
      do {
        $prev_timestamp = $prev_timestamp + SECONDS_IN_DAY;
        $res_date = POSIX::strftime("%Y-%m-%d", localtime($prev_timestamp));
        $res_weekday = $get_weekday->($res_date);
      } while ( !in_array($res_weekday, \@weekdays) );
      
      ($year, $mon, $mday) = split('-', $res_date);
      
    }
    elsif ( $rules->{rule_id} == PERIODIC_RULE_EVERY_MONTH ) {
      
      # every_month
      # Increment month
      $mon += 1;
      if ( $mon >= 12 ) {
        $mon = 1;
        $year += 1;
      }
      
      $mday = $rules->{month_day} || $mday;
      $res_date = "$year-$mon-$mday";
      
      # Check month have such a day
      my $days_in_month = days_in_month({ DATE => $res_date });
      if ( $mday > $days_in_month ) {
        $mday = $days_in_month;
      }
      
      $res_date = "$year-$mon-$mday";
    }
    elsif ( $rules->{rule_id} == 6 ) {# every_year
      # Increment year
      $year += 1;
    }
    
    $res_date = "$year-$mon-$mday";
    
    my @res_time = reverse split(':', $res_time);
    my ($res_year, $res_mon, $res_mday ) = split('-', $res_date);
    my @res_arr = (@res_time, $res_mday, ($res_mon - 1), ($res_year - 1900));
    
    $result = POSIX::strftime("%Y-%m-%d %H:%M:%S", @res_arr);
    
    $result_timestamp = POSIX::mktime(@res_arr);
    
  } while ( $curr_timestamp > $result_timestamp );
  
  return $result;
}

1;