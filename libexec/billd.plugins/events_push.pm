# billd plugin
#
# DESCRIBE:
#
#**********************************************************

use strict;
use warnings FATAL => 'all';

BEGIN {
  use FindBin '$Bin';
  our $libpath = $Bin;

  unshift @INC, $Bin . '/../AXbills';
}

use JSON;
use utf8;
use POSIX qw/strftime/;

use AXbills::Base qw(in_array _bp);
use Events;

require AXbills::Misc;

our (
  $db,
  $debug,
  $argv,
  %conf,
  $DATE,
  $TIME,
  @MODULES,
  %lang,
  $base_dir,
  $SELF_URL,
);

our $html = AXbills::HTML->new({
  IMG_PATH   => 'img/',
  NO_PRINT   => 1,
  CONF       => \%conf,
  CHARSET    => $conf{default_charset},
  HTML_STYLE => $conf{UP_HTML_STYLE},
  LANG       => \%lang,
});

if ($html->{language} ne 'english') {
  do $libpath . "/../language/english.pl";
  do $libpath . "/../AXbills/modules/Ureports/lng_english.pl";
}

exit if (!$conf{PUSH_ENABLED});
$conf{CROSS_MODULES_DEBUG} = '/tmp/cross_modules';

$SELF_URL //= $conf{BILLING_URL} || '';

our Admins $admin;
if (!$admin) {
  $admin = Admins->new($db, \%conf);
}

use AXbills::Sender::Core;
my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf, {
  SENDER_TYPE => 'Push'
});

my $Events = Events->new($db, $admin, \%conf);

my $json = JSON->new->utf8(1);
my $DEBUG = ($argv && $argv->{DEBUG}) ? $argv->{DEBUG} : 0;

$DATE //= POSIX::strftime("%Y-%m-%d", localtime());
my (undef, $month, $day) = split('-', $DATE);

my $events = collect_events();

_bp('Events', $events) if ($DEBUG > 1);

foreach my $aid (keys %{$events}) {
  send_events($aid, $events->{$aid}) if (scalar(@{$events->{$aid}}));
}

#**********************************************************
=head2 collect_events()

=cut
#**********************************************************
sub collect_events {
  my %events_for_admin = ();
  my $admins_list = $admin->list({
    ADMIN_NAME => '_SHOW',
    BIRTHDAY   => '_SHOW',
    DISABLE    => 0,
    COLS_NAME  => 1,
  });

  _bp('Error admins', { errno => $admin->{errno}, errstr => $admin->{errstr} }) if ($DEBUG > 1 && $admin->{errno});
  my @all_aids = map {$_->{aid}} @{$admins_list};
  $events_for_admin{$_} = [] foreach (@all_aids);

  foreach my $adm (@{$admins_list}) {
    my $aid = $adm->{aid};
    my $this_adm_events = collect_admin_events($aid);

    if ($adm->{birthday}) {
      my ($adm_year, $adm_month, $adm_day) = split('-', $adm->{birthday});
      if ($adm_month && $adm_day && ($month == $adm_month && ($adm_day - $day > 0 && $adm_day - $day <= 1))) {
        my $birthday_event = _generate_birthday_reminder($adm->{admin_name} || $adm->{login} || $admin->{name});

        foreach my $other_aid (grep {$_ != $aid} @all_aids) {
          push(@{$events_for_admin{$other_aid}}, $birthday_event);
        }

        if ($adm_day - $day == 0) {
          push(@{$events_for_admin{$aid}}, {
            TITLE => 'Happy birthday!',
            TEXT  => $conf{NOTEPAD_BIRTHDAY_GREETINGS_TEXT} || $birthday_event->{TEXT}
          });
        }
      }
    }

    _bp($aid, $this_adm_events) if ($DEBUG > 1);
    push(@{$events_for_admin{$aid}}, @{$this_adm_events});
  }

  return \%events_for_admin;
}

#**********************************************************
=head2 collect_admin_events($aid)

=cut
#**********************************************************
sub collect_admin_events {
  my ($aid) = @_;

  $admin->info($aid);

  my $cross_modules_return = cross_modules('_events', {
    UID    => $user->{UID},
    PERIOD => 300,
    SILENT => $DEBUG > 0,
    DEBUG  => $DEBUG,
    HTML   => $html
  });

  my %admin_modules = ('Events' => 1, 'Notepad' => 1);
  my $admin_groups_ids = $admin->{SETTINGS}->{GROUP_ID} || '';

  if (in_array('Events', \@MODULES)) {
    if ($admin_groups_ids) {
      $admin_groups_ids =~ s/, /;/g;

      my $groups_list = $Events->group_list({
        ID         => $admin_groups_ids,
        MODULES    => '_SHOW',
        COLS_UPPER => 0
      });

      if (!_error_show($Events)) {
        foreach my $group (@{$groups_list}) {
          my $group_modules_string = $group->{modules} || '';
          my @group_modules = split(',', $group_modules_string);
          map {$admin_modules{$_} = 1} @group_modules;
        }
      }
    }
  }

  my @events = ();
  foreach my $module (sort keys %{$cross_modules_return}) {
    next if ($admin_groups_ids && !$admin_modules{$module});

    my $result = $cross_modules_return->{$module};
    if ($result && $result ne '') {
      eval {
        my $decoded_result = $json->decode('[' . $result . ']');

        if ($decoded_result && ref $decoded_result eq 'ARRAY') {
          push(@events, @{$decoded_result});
        }
      }
    }
  }

  return \@events;
}

#**********************************************************
=head2 send_events()

=cut
#**********************************************************
sub send_events {
  my ($aid, $adm_events) = @_;
  return if (!$aid);

  foreach my $reminder (@{$adm_events}) {
    $Sender->send_message({
      AID     => $aid,
      MESSAGE => $reminder->{TEXT},
      TITLE   => $reminder->{TITLE}
    });
  }
}

#**********************************************************
=head2 _generate_birthday_reminder()

=cut
#**********************************************************
sub _generate_birthday_reminder {
  my ($for_name) = @_;

  return {
    TITLE => 'Birthday',
    TEXT  => $for_name || 'Guess who :)'
  }
}

#**********************************************************
=head2 get_administrator_language()

=cut
#**********************************************************
sub get_administrator_language {
  $admin->settings_info($admin->{aid});

  if ($admin->{WEB_OPTIONS}) {
    my @WO_ARR = split(/;/, $admin->{WEB_OPTIONS});
    foreach my $line (@WO_ARR) {
      my ($k, $v) = split(/=/, $line);
      next if (!$k);
      $admin->{SETTINGS}->{$k} = $v;

      if ($html) {
        $html->{$k} = $v;
      }
    }
  }

  my $language = $admin->{SETTINGS}->{language} || $conf{default_language} || 'russian';

  if (!$html->{language} || $html->{language} ne $language) {
    %lang = ();

    my $main_english = $base_dir . '/language/english.pl';
    require $main_english;

    if ($language ne 'english') {
      my $main_file = $base_dir . '/language/' . $language . '.pl';
      require $main_file;
    }

    foreach my $module (@MODULES) {
      my $english_lang = $base_dir . "/AXbills/modules/$module/lng_english.pl";
      require $english_lang if (-f $english_lang);

      if ($language ne 'english') {
        my $lang_file = $base_dir . "/AXbills/modules/$module/lng_$language.pl";
        require $lang_file if (-f $lang_file);
      }
    }
  }

  return $language;
}

1;
