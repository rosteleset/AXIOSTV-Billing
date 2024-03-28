=head1 NAME

  Portal send

 Arguments:
  DATE  - date of news
  SLEEP - used to delay the execution of script logic of send

=head1 EXAMPLES

  billd portal_newsletters

=cut

use strict;
use warnings;

use AXbills::Base qw(sendmail in_array date_diff);
use AXbills::Sender::Core;
use Time::HiRes qw(usleep);

our (
  $debug,
  %conf,
  $Admin,
  $var_dir,
  $db,
  $argv,
  %LIST_PARAMS,
  %lang,
  $base_dir,
  $SELF_URL
);

use AXbills::Templates;

use Portal;
use Users;

my $Sender = AXbills::Sender::Core->new($db, $Admin, \%conf);
my $Portal = Portal->new($db, $Admin, \%conf);
my $Users = Users->new($db, $Admin, \%conf);

my $Log = Log->new($db, $Admin);
my %list_params = %LIST_PARAMS;
my $all_send_methods = \%AXbills::Sender::Core::PLUGIN_NAME_FOR_TYPE_ID;
do "$base_dir/language/$conf{default_language}.pl";

our $html = AXbills::HTML->new({ CONF => \%conf, LANG => \%lang });
%LIST_PARAMS = %list_params;

if ($debug > 2) {
  $Log->{PRINT} = 1;
}
else {
  $Log->{LOG_FILE} = $var_dir . '/log/portal_newsletter.log';
}

my @methods = (5, 6, 10);

portal_newsletter();

#**********************************************************
=head2 portal_newsletter() — Start point of Portal newsletter

=cut
#**********************************************************
sub portal_newsletter {
  my $debug_output = '';
  $debug_output .= "Portal newsletter\n" if ($debug > 1);
  $SELF_URL ||= $conf{BILLING_URL} || '';

  my $SEND_DATE = $argv->{DATE} || $DATE;
  my $send_methods = $Sender->available_types({ HASH_RETURN => 1 });
  my @read_methods = keys %$send_methods;

  $Portal->{debug} = 1 if $debug > 6;

  my $newsletter_list = $Portal->portal_newsletter_list({ STATUS => 0, COLS_NAME => 1, COLS_UPPER  => 1 });
  foreach my $letter (@$newsletter_list) {
    my $count = 0;
    my $send_method_id = $letter->{SEND_METHOD};
    my $sender_name = $send_methods->{$send_method_id};

    if (!(in_array($send_method_id, \@methods) && in_array($send_method_id, \@read_methods))) {
      $Portal->portal_newsletter_change({
        %$letter,
        STATUS => 2
      });
      next;
    }

    if (date_diff($letter->{date}, $SEND_DATE) < 0) {
      next;
    }

    $Portal->portal_newsletter_change({
      %$letter,
      STATUS => 3
    });

    my $article_sublink = $letter->{permalink} || $letter->{article_id};
    my $news_link = "$SELF_URL/?article=$article_sublink";
    my @ATTACHMENTS = ();

    if ($letter->{picture}) {
      my $base_dir = $main::base_dir || '/usr/axbills/';
      my (undef, $type) = split(/\./, $letter->{picture}, 2);
      @ATTACHMENTS = ({
        ATTACHMENT_ID => $letter->{id},
        filename      => $letter->{picture},
        content_type  => "image/$type",
        content       => "FILE: $base_dir/AXbills/templates/attach/portal/$letter->{picture}"
      });
    }

    my $message = _get_newsletter_message($letter, $news_link);
    my $sender_options = _get_newsletter_sender_options($letter, $news_link, $message, \@ATTACHMENTS);
    my $contact_name = uc(_get_newsletter_sender_name($sender_name));

    my $allowed_users = $Users->list({
      $contact_name  => '!=0',
      TAG_SEARCH_VAL => 1,
      TAGS           => $letter->{tags},
      GID            => $letter->{gid} || undef,
      DISTRICT_ID    => $letter->{district_id},
      STREET_ID      => $letter->{street_id},
      UID            => '_SHOW',
      PAGE_ROWS      => 999999,
      COLS_NAME      => 1,
    });

    foreach my $contact (@$allowed_users) {
      $contact->{value} = $contact->{lc($contact_name)} || "";

      $Log->log_print('LOG_DEBUG',
        $contact->{uid},
        "Newsletter: $letter->{id} Send method: $sender_name ($send_method_id) UID: $contact->{uid}"
      );

      if ($debug < 6) {
        $sender_options->{TO_ADDRESS} = $contact->{value};
        $sender_options->{UID} = $contact->{uid};
        $Sender->send_message($sender_options);

        $count++;
        if ($Sender->{errno}) {
          $Log->log_print('LOG_DEBUG', $contact->{uid}, "Error: $Sender->{errno} $Sender->{errstr}");
        }

        if ($argv->{SLEEP}) {
          sleep int($argv->{SLEEP});
        } else {
          usleep(50000);
        }
      }
      elsif ($debug > 7) {
        $debug_output .= "TYPE: $letter->{SEND_METHOD} TO: $contact->{uid} $message\n";
      }
    }

    $Portal->portal_newsletter_change({
      %$letter,
      STATUS => 1,
      SENT   => $count
    });
  }

  $DEBUG .= $debug_output;

  return $debug_output;
}

#**********************************************************
=head2 _get_newsletter_message($letter, $link) - creates message text for newsletter

  Arguments:
    $letter — letter object
    $link — news link

  Returns:
    $message

=cut
#**********************************************************
sub _get_newsletter_message {
  my ($letter, $link) = @_;
  my $sender_name = $all_send_methods->{$letter->{send_method}} || '';

  my $message = '';
  if ($sender_name eq 'Telegram' || !$conf{PORTAL_LINK_SEND}) {
    my $message_template = _include('portal_newsletter_message_short', 'Portal', { EXTERNAL_CALL => 1 });
    $message =  $html->tpl_show($message_template, {
      MESSAGE   => $letter->{short_description},
    }, { OUTPUT2RETURN => 1 });
    return $message;
  }

  my $template_name = $letter->{content}
    ? 'portal_newsletter_message'
    : 'portal_newsletter_message_short';

  my $message_template = _include($template_name, 'Portal', { EXTERNAL_CALL => 1 });
  $message = $html->tpl_show($message_template, {
    MESSAGE   => $letter->{short_description},
    NEWS_LINK => $link
  }, { OUTPUT2RETURN => 1 });

  return $message;
}

#**********************************************************
=head2 _get_newsletter_sender_options($letter, $link, $message, $ATTACHMENTS)

  Created sender options due to sender type

  Arguments:
    $letter — letter object
    $link — news link
    $message — text
    $ATTACHMENTS

  Returns:
    $sender_options

=cut
#**********************************************************
sub _get_newsletter_sender_options {
  my ($letter, $link, $message, $ATTACHMENTS) = @_;
  my $sender_name = $all_send_methods->{$letter->{send_method}} || '';

  my $sender_options = {};
  if ($sender_name eq 'Telegram') {
    my @keyboard = ();
    if ($letter->{content} && !$conf{PORTAL_LINK_SEND}) {
      my $read_button = $html->tpl_show(
        _include('portal_newsletter_read_button', 'Portal', { EXTERNAL_CALL => 1 }), {}, { OUTPUT2RETURN => 1 }
      );
      push @keyboard, { text => $read_button, url => $link };
    }

    my $title = "<b>$letter->{TITLE}</b>";
    $sender_options =  {
      MESSAGE       => $message,
      SUBJECT       => $title,
      SENDER_TYPE   => $sender_name,
      ATTACHMENTS   => ($#$ATTACHMENTS > -1) ? $ATTACHMENTS : undef,
      PARSE_MODE    => 'HTML',
      TELEGRAM_ATTR => {
        reply_markup => {
          inline_keyboard => [
            \@keyboard
          ]
        }
      }
    };

    return $sender_options;
  }

  $sender_options = {
    MESSAGE     => $message,
    SUBJECT     => $letter->{TITLE},
    SENDER_TYPE => $sender_name,
    ATTACHMENTS => ($#$ATTACHMENTS > -1) ? $ATTACHMENTS : undef,
    PARSE_MODE  => 'HTML',
  };

  if (!$conf{PORTAL_LINK_SEND}) {
    $sender_options->{EX_PARAMS} = {
      newsUrl => $link,
      action  => 'news'
    };
  }

  return $sender_options;
}

#**********************************************************
=head2 _get_newsletter_sender_name($name) — check sender name

    Created for incompatibility Sender name method and contact name

    Arguments:
      $name — Sender name

=cut
#**********************************************************
sub _get_newsletter_sender_name {
  my ($name) = @_;

  if ($name eq "Viber_bot") {
    return "Viber";
  }

  return $name;
}

1;
