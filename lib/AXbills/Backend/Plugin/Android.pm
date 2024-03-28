package AXbills::Backend::Plugin::Android;
use strict;
use warnings FATAL => 'all';

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use JSON;

use AXbills::Fetcher qw/web_request/;
use AXbills::Backend::Plugin::BasePlugin;
use parent 'AXbills::Backend::Plugin::BasePlugin';
use Msgs;

BEGIN {
  use AXbills::Backend::Defs;
}

use AXbills::Backend::Log;

our Admins $admin;
our (
  %conf, 
  $db, 
  $base_dir
);

my $log_file = $conf{ANDROID_LOG} || (($base_dir || '/usr/axbills') . '/var/log/android_push.log');
my $debug = $conf{ANDROID_DEBUG} || 3;
my $Log = AXbills::Backend::Log->new('FILE', $debug, 'Android push notification', { FILE => $log_file });

my $Msgs = Msgs->new($db, $admin, \%conf);

my $list_admin = $admin->admins_contacts_list({
  VALUE         => '_SHOW',
  AID           => '_SHOW',
  TYPE          => 10,
  COLS_NAME     => 1,
  GROUP_BY      => 'GROUP BY ac.value',
});

my %admin_key = map { 
  $_->{aid} => $_->{value}
} @{ $list_admin };

my $done = AnyEvent->condvar;

AnyEvent->timer (
  after     => 5,
  interval  => 300,
  cb        => sub {
    send_notification();
  }
);

$done->recv();

#**********************************************************
=head2 send_notification()

  Arguments:
    
  Returns:
  
=cut
#**********************************************************
sub send_notification {

  foreach my $key (keys %admin_key) {
    delete($admin_key{$key}) unless ($admin_key{$key});
  }

  my $admin_aids = join(',', keys %admin_key);

  my $msgs_list = $Msgs->messages_list({
    COLS_NAME       => 1,
    MSG_ID          => '_SHOW',
    STATE_ID        => '0',
    RESPOSIBLE_IDS  => $admin_aids
  });

  my @msgs_ids = ();

  push(@msgs_ids, map { 
    $_->{id}
  } @{ $msgs_list });

  my %msgs_to_aid = ();
  
  foreach my $msgs_id (@{ $msgs_list }) {
    $msgs_to_aid{"$msgs_id->{id}"} = $admin_key{ $msgs_id->{resposible} };
  }

  foreach my $msgs_id (@msgs_ids) {
    my $reply_list = $Msgs->messages_reply_list({
      MSGS_IDS    => $msgs_id,
      REPLY       => '_SHOW',
      AID         => '0',
      COLS_NAME   => 1,
      DESC        => 'DESC',
      PAGE_ROWS   => 'LIMIT 1',
    });

    _send_data_fcm(
      $reply_list->[0]->{creator_fio},
      $reply_list->[0]->{text},
      $msgs_to_aid{$msgs_id}
    );
  }

}

#**********************************************************
=head2 _send_data_fcm()

  Arguments:
    
  Returns:
  
=cut
#**********************************************************
sub _send_data_fcm {
  my ($title, $body, $token_device) = @_;
  
  my @header = (
    "Authorization: key=$conf{ANDROID_PUSH}",
    "Content-Type: application/json"
  );

  web_request($conf{ANDROID_PUSH_URL}, {
    POST         => _generet_notification_json({
      TITLE       => $title,
      BODY        => $body,
      ANDROID_ID  => $token_device
    }),
    CURL         => 1,
    CURL_OPTIONS => '-XPOST',
    HEADERS      => \@header,
    JSON_RETURN  => 1,
  });
}

#**********************************************************
=head2 _generet_notification_json()

  Arguments:
    
  Returns:
  
=cut
#**********************************************************
sub _generet_notification_json {
  my ($attr) = @_;

  my %send_data = (
    'to' => $attr->{ANDROID_ID},
    'notification' => {
      'title' => $attr->{TITLE},
      'body'  => $attr->{BODY}
    },
    'priority' => 10
  );

  my $json_send = JSON->new->utf8->encode(\%send_data);
  $json_send =~ s/\"/\\"/g;

  return $json_send;
}

1;
