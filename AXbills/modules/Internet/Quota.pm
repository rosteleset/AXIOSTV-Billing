=head1 NAME

  Quota service

=cut

use strict;
use warnings FATAL => 'all';
use Internet::Sessions;

our (
  $html,
  $Conf,
  %lang,
  $db,
  $admin,
  %conf
);

my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

#********************************************************
=head2 internet_quota_configure($attr) - Quota configure

  Arguments:
    $attr

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub internet_quota_configure {
  #my ($attr) = @_;

  my %info = (
    ACTION    =>'change',
    ACTION_LNG=>$lang{CHANGE}
  );

  if($FORM{change} && defined($FORM{QUOTA})) {
    $Conf->config_change({
      param => 'INTERNET_DAY_QUOTA',
      value => "$FORM{QUOTA}:$FORM{DAYS}:$FORM{SPEED_IN}:$FORM{SPEED_OUT}"
    });
    $html->message('info', $lang{INFO}, $lang{CHANGED});
  }

  ($info{QUOTA}, $info{DAYS}, $info{SPEED_IN}, $info{SPEED_OUT})=split(/:/, $conf{INTERNET_DAY_QUOTA}, 4);

  $html->tpl_show(_include('internet_quota_conf', 'Internet'), \%info);

  return 1;
}


#********************************************************
=head2 internet_quota_users($attr) - Quota configure

  Arguments:
    $attr

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub internet_quota_users {

  my %info = ();
  my $uid = $FORM{UID};

  my $online_list = $Sessions->online({
    UID          => $uid,
    CLIENT_IP    => '_SHOW',
    USER_NAME    => '_SHOW',
    CONNECT_INFO => '_SHOW',
    COLS_NAME    => 1
  });

  foreach my $line ( @$online_list ) {
    $info{LOGIN} = $line->{user_name};
    $info{IP}    = $line->{client_ip};
    $info{QUOTE} = $line->{connect_info};
    $line->{connect_info} =~ /QUOTA:(.+)/;
    $info{SPEED} = $1;
  }

  $html->tpl_show(_include('internet_user_quota', 'Internet'), \%info);

  return 1;
}


#********************************************************
=head2 internet_quota_reports($attr) - Quota configure

  Arguments:
    $attr

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub internet_quota_reports {
  #my ($attr) = @_;

  my $online_list = $Sessions->online({
    CLIENT_IP    => '_SHOW',
    USER_NAME    => '_SHOW',
    CONNECT_INFO => 'QUOTA*',
    COLS_NAME    => 1
  });

  my $table = $html->table({
    width      => '100%',
    caption    => 'QUOTA',
    title      => [ $lang{USER}, $lang{SPEED}, 'QUOTA' ],
    pages      => $Sessions->{TOTAL},
    ID         => 'QUOTA_LIST'
  });


  foreach my $line ( @$online_list ) {
    $table->addrow(
      $line->{user_name},
      $line->{client_ip},
      $line->{connect_info}
    );
  }

  print $table->show();

  return 1;
}

1;
