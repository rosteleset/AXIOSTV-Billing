=head1 NAME

 billd plugin

 DESCRIBE: billd plugin automatic closing of old messages

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $Admin,
  $db,
  $argv,
  %lang
);

use Msgs;
use Msgs::Notify;
use AXbills::Templates qw/templates/;
use AXbills::Base qw/date_diff/;
our $html = AXbills::HTML->new( { CONF => \%conf } );

my $date = $argv->{DATE} || $DATE;
my $Msgs = Msgs->new($db, $Admin, \%conf);
my $Log  = Log->new($db, $Admin);
my $Notify = Msgs::Notify->new($db, $Admin, \%conf, { HTML => $html });

do "../language/$html->{language}.pl";
do 'AXbills/Misc.pm';
our $admin = $Admin;
load_module('Msgs', $html);

msgs_autoclose();

#**********************************************************
=head2 msgs_autoclose()

=cut
#**********************************************************
sub msgs_autoclose {

  $Msgs->chapters_list({ AUTOCLOSE => '!', LIST2HASH => 'id,autoclose' });
  my $autoclose_list = $Msgs->{list_hash};

  my $messages_list = $Msgs->messages_list({
    LAST_REPLIE_DATE => '_SHOW',
    REPLY_STATUS      => '!3',
    CHAPTER          => join(';', keys %{$autoclose_list}),
    STATE            => 6,
    RESPOSIBLE       => '_SHOW',
    PAGE_ROWS        => 999999,
    COLS_NAME        => 1
  });

  foreach my $message (@$messages_list) {
    next if (!$message->{last_replie_date} || $message->{last_replie_date} eq '0000-00-00 00:00:00');
    next if !$autoclose_list->{$message->{chapter_id}};

    my $period = $autoclose_list->{$message->{chapter_id}};
    my $half_period = int($period / 2);

    if (date_diff($message->{last_replie_date}, $date) == $half_period) {
      my $message_body = $html->tpl_show(templates('form_msgs_autoclose'), { MSGS_ID => $message->{id} }, {
        OUTPUT2RETURN      => 1,
        SKIP_DEBUG_MARKERS => 1
      });

      $Msgs->message_reply_add({
        ID         => $message->{id},
        REPLY_TEXT => $message_body,
        STATE      => 3,
        UID        => $message->{uid},
        AID        => $message->{resposible},
      });

      $Notify->notify_user({
        REPLY_ID => $Msgs->{INSERT_ID},
        MSG_ID   => $message->{id},
        MESSAGE  => $message_body,
        UID      => $message->{uid}
      });
      next;
    }

    if (date_diff($message->{last_replie_date}, $date) == $period) {
      my $message_body = $html->tpl_show(templates('form_msgs_autoclose2'), { MSGS_ID => $message->{id} }, {
        OUTPUT2RETURN      => 1,
        SKIP_DEBUG_MARKERS => 1
      });

      $Msgs->message_reply_add({
        ID         => $message->{id},
        REPLY_TEXT => $message_body,
        STATE      => 3,
        UID        => $message->{uid},
        AID        => $message->{resposible},
      });
      next if $Msgs->{error};

      $Msgs->message_change({ ID => $message->{id}, ADMIN_READ => "$DATE $TIME", STATE => 2 });
      $Notify->notify_user({
        REPLY_ID => $Msgs->{INSERT_ID},
        MSG_ID   => $message->{id},
        MESSAGE  => $message_body,
        UID      => $message->{uid},
        STATE    => 2
      });
      next;
    }
  }
}

1;