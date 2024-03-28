package Iptv::Conax;

=head1 NAME

=head1 VERSION

  VERSION: 0.83
  Revision: 20200506

=head1 SYNOPSIS


=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.83;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher qw(web_request);
use Digest::SHA qw(hmac_sha256_hex);
use Time::Local qw(timelocal_nocheck timelocal);
use Net::FTP;
use XML::Simple;
use Users;

my $MODULE = 'Conax';

my ($admin, $CONF, $db);
my AXbills::HTML $html;
my $lang;
my $Iptv;
my $Users;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $Iptv = Iptv->new($db, $admin, $CONF);
  $Users = Users->new($db, $admin, $CONF);

  $admin->{MODULE} = $MODULE;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{LANG}) {
    $lang = $attr->{LANG};
  }

  my $self = {};
  bless($self, $class);

  load_pmodule('JSON');

  $self->{SERVICE_NAME} = $MODULE;
  $self->{VERSION} = $VERSION;
  $self->{db} = $db;

  $self->{public_key} = $attr->{LOGIN} || q{};
  $self->{private_key} = $attr->{PASSWORD} || q{};
  $self->{URL} = $attr->{URL} || '';
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;

  if ($self->{debug} && $self->{debug} > 5) {
    print "Content-Type: text/html\n\n";
  }

  $self->{VERSION} = $VERSION;

  return $self;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  return 1;
}

#**********************************************************
=head2 user_add($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{CID}) {
    my $user_cards = $Iptv->user_list({
      CID       => $attr->{CID},
      UID       => '_SHOW',
      COLS_NAME => 1,
      PAGE_ROWS => 100000
    });

    foreach my $card (@{$user_cards}) {
      if ($card->{uid} ne $attr->{UID}) {
        $self->{errno} = '10103';
        $self->{errstr} = $lang->{CARD_EXIST} . " " . $html->button($card->{uid}, "index=15&UID=$card->{uid}");
        return $self;
      }
    }

    my $user_screens = $Iptv->users_screens_list({
      CID         => $attr->{CID},
      SCREEN_ID   => '_SHOW',
      UID         => '_SHOW',
      SHOW_ASSIGN => 1,
      COLS_NAME   => 1,
      PAGE_ROWS   => 100000
    });

    foreach my $card (@{$user_screens}) {
      if ($card->{uid} ne $attr->{UID}) {
        $self->{errno} = '10103';
        $self->{errstr} = $lang->{CARD_EXIST} . " " . $html->button($card->{uid}, "index=15&UID=$card->{uid}");
        return $self;
      }
    }
  }

  $attr->{STATUS} = 0;

  my $screens = $Iptv->users_active_screens_list({
    SERVICE   => $attr->{ID},
    COLS_NAME => 1
  });

  my $count = 0;
  if (ref $screens eq 'ARRAY') {
    $count = @$screens;
  }

  if (!_additional_cards({ %$attr, CARDS => $screens, COUNT => $count })) {
    $self->{errno} = '10102';
    $self->{errstr} = $lang->{PROCESSING_ERROR};
    return $self;
  }

  return $self;
}

#**********************************************************
=head2 user_change($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  if (!defined($attr->{SILENT})) {
    $Users->info($attr->{UID});
    if ($Users->{DISABLE}) {
      $self->{errno} = '10103';
      $self->{errstr} = "$lang->{DISABLE}";
      return $self;
    }
  }

  if ($attr->{CID}) {
    my $user_cards = $Iptv->user_list({
      CID       => $attr->{CID},
      UID       => '_SHOW',
      COLS_NAME => 1,
      PAGE_ROWS => 100000
    });

    foreach my $card (@{$user_cards}) {
      if ($card->{uid} ne $attr->{UID}) {
        $self->{errno} = '10103';
        $self->{errstr} = $lang->{CARD_EXIST} . " " . $html->button($card->{uid}, "index=15&UID=$card->{uid}");
        return $self;
      }
    }

    my $user_screens = $Iptv->users_screens_list({
      CID         => $attr->{CID},
      SCREEN_ID   => '_SHOW',
      UID         => '_SHOW',
      SHOW_ASSIGN => 1,
      COLS_NAME   => 1,
      PAGE_ROWS   => 100000
    });

    foreach my $card (@{$user_screens}) {
      if ($card->{uid} ne $attr->{UID}) {
        $self->{errno} = '10103';
        $self->{errstr} = $lang->{CARD_EXIST} . " " . $html->button($card->{uid}, "index=15&UID=$card->{uid}");
        return $self;
      }
    }
  }

  if ($attr->{STATUS} == 0 || $attr->{STATUS} == 1) {
    my $screens = $Iptv->users_active_screens_list({
      SERVICE   => $attr->{ID},
      COLS_NAME => 1
    });

    my $count = 0;
    if (ref $screens eq 'ARRAY') {
      $count = @$screens;
    }

    if (!$attr->{TP_INFO_OLD}{FILTER_ID}) {
      if (!_additional_cards({ %$attr, CARDS => $screens, COUNT => $count })) {
        $self->{errno} = '10102';
        $self->{errstr} = $lang->{PROCESSING_ERROR};
        return $self;
      }
      else {
        return $self;
      }
    }

    $attr->{TP_INFO_OLD}{STATUS} = 1;
    $attr->{TP_INFO_OLD}{TP_FILTER_ID} = $attr->{TP_INFO_OLD}{FILTER_ID};
    $attr->{TP_INFO_OLD}{CID} = $attr->{CID};

    if (!_additional_cards({ %{$attr->{TP_INFO_OLD}}, CARDS => $screens, COUNT => $count })) {
      $self->{errno} = '10103';
      $self->{errstr} = $lang->{PROCESSING_ERROR};
      return $self;
    }

    if (!_additional_cards({ %$attr, CARDS => $screens, COUNT => $count })) {
      $self->{errno} = '10102';
      $self->{errstr} = $lang->{PROCESSING_ERROR};
      return $self;
    }
  }

  return $self;
}

#**********************************************************
=head2 user_del($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATUS} = 1;

  my $screens = $Iptv->users_active_screens_list({
    SERVICE   => $attr->{ID},
    COLS_NAME => 1
  });

  my $count = 0;
  if (ref $screens eq 'ARRAY') {
    $count = @$screens;

    foreach my $screen (@{$screens}) {
      $Iptv->users_screens_del({
        SERVICE_ID => $screen->{service_id},
        SCREEN_ID  => $screen->{screen_id},
        UID        => $attr->{UID}
      }) if $screen->{service_id} && $screen->{screen_id};
    }
  }

  if (!_additional_cards({ %$attr, CARDS => $screens, COUNT => $count })) {
    $self->{errno} = '10102';
    $self->{errstr} = $lang->{PROCESSING_ERROR};
    return $self;
  }

  return $self;
}

#**********************************************************
=head2 get_user_status($attr)


=cut
#**********************************************************
sub get_user_status {
  my $self = shift;
  my ($attr) = @_;

  my @filter_ids = split(",", $attr->{TP_FILTER_ID});

  if (!$filter_ids[0]) {
    $html->message("err", $lang->{SET_FILTER_ID_IN_TARIFF});
    return 1;
  }
  my $filter = $filter_ids[0];

  if ($attr->{STATUS}) {
    $html->message("info", $lang->{ACCOUNT_NOT_ACTIVATED});
    return 1;
  }
  $attr->{STATUS} = 10;

  my $ftp = Net::FTP->new($CONF->{CONAX_FTP_HOST}, Timeout => 5, Debug => ($self->{debug} || 0)) or die print "Cannot connect to some.host.name: $@\n";

  $ftp->login($CONF->{CONAX_FTP_LOGIN}, $CONF->{CONAX_FTP_PASSWORD}) or die print "Cannot login: " . $ftp->message;

  if (!$attr->{ID} || !$attr->{TP_FILTER_ID}) {
    $html->message("err", $lang->{SET_FILTER_ID_IN_TARIFF});
    return 1;
  }

  my $card_length = length $attr->{CID};

  if ($card_length != 12) {
    $html->message("err", $lang->{ERROR_CARD});
    return 1;
  }

  my $id = int $filter + int $attr->{ID};

  while (length "$id" < 6) {
    $id = "0" . $id;
  }

  while (length $filter < 8) {
    $filter = "0" . $filter;
  }

  if ($attr->{COUNT}) {
    $attr->{COUNT}++;
  }
  else {
    $attr->{COUNT} = 1;
  }

  my $table = $html->table({
    width       => '100%',
    caption     => $lang->{INFO},
    title_plain => [ "$lang->{SERVICE}", "$lang->{CARD_NUMBER}", "$lang->{AUTHORISATION_END}" ],
    ID          => 'INFOS',
  });

  my $file_name = "";
  $file_name = "sc$id.tmp";
  my $new_file_name = "sc$id.emm";
  my $cards = _sort_cards($attr);
  my $block_cards = _get_block_cards($attr);

  my $cards_length = 0;
  if ($cards) {
    $cards_length = @{$cards};
  }
  if (!$cards_length) {
    foreach my $card (@{$block_cards}) {
      $table->addrow("", "$card->{cid}", "");
      print $table->show();
    }
    return 1;
  }

  return 1 if !$file_name;

  open(FILE, ">", "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name") or die "Couldn't open: $!";

  print FILE "U\n";
  print FILE "$id\n";
  print FILE "U\n";
  print FILE "U\n";
  print FILE "U\n";
  print FILE "U\n";
  print FILE "EMM\n";
  print FILE "U\n";
  print FILE "0000$cards_length\n";

  foreach my $card (@{$cards}) {
    $card_length = length $card->{cid};

    if ($card_length != 12) {
      $html->message("err", $lang->{ERROR_CARD});
      unlink "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name";
      return 1;
    }
    my $card_mac = $card->{cid};
    chop $card_mac;
    print FILE "$card_mac\n";
  }
  print FILE "ZZZ\n";

  close FILE;

  $ftp->cwd('/autreq/req') or die print "Cannot change directory $ftp->message";

  my $result = $ftp->put("/usr/axbills/AXbills/modules/Iptv/Conax/$file_name") or die print "Cannot put file" . $ftp->message;

  $ftp->rename("$file_name", "$new_file_name") or die print "Cannot rename file" . $ftp->message;

  unlink "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name";

  my $count = 0;
  while ($count < 5) {
    $count++;
    $ftp->cwd('/autreq/ok') or die print "Cannot change directory $ftp->message";
    $result = $ftp->get("$new_file_name", "/usr/axbills/AXbills/modules/Iptv/Conax/$new_file_name");
    $ftp->delete("$new_file_name");

    if ($result && -e "/usr/axbills/AXbills/modules/Iptv/Conax/" . $new_file_name) {
      my $Xml = XML::Simple->new();
      my $data = $Xml->XMLin("/usr/axbills/AXbills/modules/Iptv/Conax/$new_file_name");

      my $day_end = '';
      my $month_end = '';
      my $year_end = '';
      if ($data->{AuthorisationStatus} && ref($data->{AuthorisationStatus}) eq "ARRAY") {
        foreach my $card (@{$data->{AuthorisationStatus}}) {
          if ($card->{Product}{AuthorisationEnd}) {
            $day_end = $card->{Product}{AuthorisationEnd}{day} || "";
            $month_end = $card->{Product}{AuthorisationEnd}{month} || "";
            $year_end = $card->{Product}{AuthorisationEnd}{year} || "";
            $table->addrow($card->{Product}{id}, $card->{cardNo}, "$year_end-$month_end-$day_end");
          }
          else {
            foreach my $key (keys %{$card->{Product}}) {
              my $datas = $card->{Product}{$key};
              $day_end = $datas->{AuthorisationEnd}{day} || "";
              $month_end = $datas->{AuthorisationEnd}{month} || "";
              $year_end = $datas->{AuthorisationEnd}{year} || "";
              $table->addrow($card->{Product}{$key}{id}, $card->{cardNo}, "$year_end-$month_end-$day_end");
            }
          }
        }
      }
      elsif ($data->{AuthorisationStatus} && ref($data->{AuthorisationStatus}) eq "HASH") {
        if ($data->{AuthorisationStatus}{Product}{AuthorisationEnd}) {
          $day_end = $data->{AuthorisationStatus}{Product}{AuthorisationEnd}{day} || "";
          $month_end = $data->{AuthorisationStatus}{Product}{AuthorisationEnd}{month} || "";
          $year_end = $data->{AuthorisationStatus}{Product}{AuthorisationEnd}{year} || "";
          $table->addrow($data->{AuthorisationStatus}{Product}{id}, $data->{AuthorisationStatus}{cardNo}, "$year_end-$month_end-$day_end");
        }
        else {
          foreach my $key (keys %{$data->{AuthorisationStatus}{Product}}) {
            my $datas = $data->{AuthorisationStatus}{Product}{$key};
            $day_end = $datas->{AuthorisationEnd}{day} || "";
            $month_end = $datas->{AuthorisationEnd}{month} || "";
            $year_end = $datas->{AuthorisationEnd}{year} || "";
            $table->addrow($data->{AuthorisationStatus}{Product}{$key}{id}, $data->{AuthorisationStatus}{cardNo}, "$year_end-$month_end-$day_end");
          }
        }
      }

      unlink "/usr/axbills/AXbills/modules/Iptv/Conax/$new_file_name";

      foreach my $card (@{$block_cards}) {
        $table->addrow("", "$card->{cid}", "");
      }

      print $table->show();
      last;
    }
    else {
      $ftp->cwd('/autreq/err') or die print "Cannot change directory $ftp->message";
      $result = $ftp->delete("$new_file_name");
      if ($result) {
        $html->message("info", $lang->{PROCESSING_ERROR});
        return 1;
      }
    }

    if ($count eq "4") {
      $html->message("info", $lang->{PROCESSING_ERROR});
      return 0;
    }
    sleep(1);
  }

  return 1;
}

#**********************************************************
=head2 additional_functions($attr)

=cut
#**********************************************************
sub additional_functions {
  my $self = shift;
  my ($attr) = @_;

  my $cards = $html->table({
    width       => '100%',
    caption     => $lang->{SCREENS},
    title_plain => [ "Card Number", "$lang->{SERVICE}", "", "", "" ],
    ID          => 'CARDS_ALL',
  });

  if ($attr->{card}) {
    if ($attr->{SUBSCRIBE}) {
      if (_subscribe_card($attr)) {
        $html->message("info", $lang->{CARD_SUCCESSFULLY_SIGNED});
      }
      else {
        $html->message("err", $lang->{CARD_SUBSCRIPTION_FAILED});
      }
    }
    if ($attr->{UNSUBSCRIBE}) {
      if (_unsubscribe_card($attr)) {
        $html->message("info", $lang->{CARD_UNSUBSCRIBED});
      }
      else {
        $html->message("err", $lang->{UNSUBSCRIBE_CARD_ERROR});
      }
    }
    if ($attr->{BLOCK}) {
      $attr->{UNSUBSCRIBE} = $attr->{BLOCK};
      if ($attr->{MAIN_CID}) {
        if (_unsubscribe_card($attr)) {
          $Iptv->user_change({
            ID           => $attr->{BLOCK},
            SUBSCRIBE_ID => 1,
          });
          $html->message("info", $lang->{CARD_LOCKED});
        }
      }
      elsif ($attr->{CARD_SERVICE}) {
        if (_unsubscribe_card($attr)) {
          $Iptv->users_screens_del({
            SERVICE_ID => $attr->{CARD_SERVICE},
            SCREEN_ID  => $attr->{CARD_ID},
            UID        => $attr->{UID}
          });

          $Iptv->users_screens_add({
            SERVICE_ID  => $attr->{CARD_SERVICE},
            SCREEN_ID   => $attr->{CARD_ID},
            CID         => $attr->{card},
            HARDWARE_ID => 1,
          });
          $html->message("info", $lang->{CARD_LOCKED});
        }
      }
    }
    if ($attr->{UNBLOCK}) {
      $attr->{SUBSCRIBE} = $attr->{UNBLOCK};
      if ($attr->{MAIN_CID}) {
        if (_subscribe_card($attr)) {
          $Iptv->user_change({
            ID           => $attr->{UNBLOCK},
            SUBSCRIBE_ID => 0,
          });
          $html->message("info", "Карта разблокирована");
        }
      }
      elsif ($attr->{CARD_SERVICE}) {
        if (_subscribe_card($attr)) {
          $Iptv->users_screens_del({
            SERVICE_ID => $attr->{CARD_SERVICE},
            SCREEN_ID  => $attr->{CARD_ID},
            UID        => $attr->{UID}
          });

          $Iptv->users_screens_add({
            SERVICE_ID  => $attr->{CARD_SERVICE},
            SCREEN_ID   => $attr->{CARD_ID},
            CID         => $attr->{card},
            HARDWARE_ID => 0,
          });
          $html->message("info", "Карта разблокирована");
        }
      }
    }

    return 0;
  }

  return 1 if $attr->{screen};
  if ($attr->{additional_functions} && $attr->{get_new_status}) {
    my $user_info = $Iptv->user_info($attr->{status_id});
    my $screens = $Iptv->users_active_screens_list({
      SERVICE   => $user_info->{ID},
      COLS_NAME => 1
    });

    my $count = 0;
    if (ref $screens eq 'ARRAY') {
      $count = @$screens;
    }
    $self->get_user_status({ %$attr, %$user_info, CARDS => $screens, COUNT => $count });
    return 1;
  }

  if ($attr->{additional_functions} && $attr->{work_with_cards}) {
    my $user_info = $Iptv->user_info($attr->{status_id});

    my $screens = $Iptv->users_active_screens_list({
      SERVICE   => $user_info->{ID},
      COLS_NAME => 1
    });

    my $card_sub = '';
    my $card_unsub = '';
    my $card_block = '';
    my $card_status = '';
    foreach my $card (@$screens) {
      $card_status = !$card->{hardware_id} ? "BLOCK" : "UNBLOCK";

      $card_unsub = $html->button($lang->{UNSUBSCRIBE},
        "get_index=iptv_user&UNSUBSCRIBE=$attr->{status_id}&card=$card->{cid}&UID=$attr->{UID}&CARD_ID=$card->{screen_id}&CARD_SERVICE=$card->{service_id}&SERVICE_ID=$attr->{SERVICE_ID}&additional_functions=1&header=2",
        {
          class         => 'btn-xs',
          LOAD_TO_MODAL => 1,
          BUTTON        => 1,
        });
      $card_sub = $html->button($lang->{SIGN},
        "get_index=iptv_user&SUBSCRIBE=$attr->{status_id}&card=$card->{cid}&UID=$attr->{UID}&CARD_ID=$card->{screen_id}&CARD_SERVICE=$card->{service_id}&SERVICE_ID=$attr->{SERVICE_ID}&additional_functions=1&header=2",
        {
          class         => 'btn-xs',
          LOAD_TO_MODAL => 1,
          BUTTON        => 1,
        });
      $card_block = $html->button($lang->{"$card_status"},
        "get_index=iptv_user&$card_status=$attr->{status_id}&card=$card->{cid}&UID=$attr->{UID}&CARD_ID=$card->{screen_id}&CARD_SERVICE=$card->{service_id}&SERVICE_ID=$attr->{SERVICE_ID}&additional_functions=1&header=2",
        {
          class         => 'btn-xs',
          LOAD_TO_MODAL => 1,
          BUTTON        => 1,
        });
      $cards->addrow($card->{cid}, "$user_info->{TP_NAME} ($user_info->{TP_FILTER_ID})", $card_sub, $card_unsub, $card_block);
    }

    my @buttons = _show_main_card_btn({ %{$attr}, USER_INFO => $user_info });
    $cards->addrow($user_info->{CID}, "$user_info->{TP_NAME} ($user_info->{TP_FILTER_ID})", @buttons);

    print $cards->show();
    return 1;
  }

  print $html->button("$lang->{STATUS}",
    "get_index=iptv_user&status_id=$attr->{ID}&UID=$attr->{UID}&get_new_status=1&SERVICE_ID=$attr->{SERVICE_ID}&additional_functions=1&header=2",
    {
      class         => 'btn-xs',
      LOAD_TO_MODAL => 1,
      BUTTON        => 1,
    });

  print " ";
  print $html->button("$lang->{SCREENS}",
    "get_index=iptv_user&status_id=$attr->{ID}&UID=$attr->{UID}&work_with_cards=1&SERVICE_ID=$attr->{SERVICE_ID}&additional_functions=1&header=2",
    {
      class         => 'btn-xs',
      LOAD_TO_MODAL => 1,
      BUTTON        => 1,
    });

  return 1;
}

#**********************************************************
=head2 user_screens($attr)

=cut
#**********************************************************
sub user_screens {
  my $self = shift;
  my ($attr) = @_;

  $self->{CID} = $attr->{CID};
  $self->{SCREEN_ID} = $attr->{SCREEN_ID};
  $self->{SERIAL} = $attr->{SERIAL};

  if ($attr->{DEL}) {
    my $result = _unsubscribe_card({
      UNSUBSCRIBE => $attr->{ID},
      NOT_CHANGE  => 1,
      card        => $attr->{CID} || $attr->{MAC},
    });

    if (!$result) {
      $self->{errno} = '10103';
      $self->{errstr} = $lang->{UNSUBSCRIBE_CARD_ERROR};
      return $self;
    }

    return $self;
  }

  if ($attr->{add_screen}) {
    my $service_info = $Iptv->user_info($attr->{ID});

    if ($Iptv->{TOTAL}) {
      if ($service_info->{STATUS}) {
        $self->{errno} = '10101';
        $self->{errstr} = $lang->{IMPOSSIBLE_TO_ADD_CARD};
        return $self;
      }

      my $result = _subscribe_card({
        SUBSCRIBE => $attr->{ID},
        ONE_CARD  => 1,
        card      => $attr->{CID} || $attr->{MAC},
        SCREEN_ID => $attr->{SCREEN_ID},
      });

      if (!$result) {
        $self->{errno} = '10103';
        $self->{errstr} = $lang->{CARD_SUBSCRIPTION_FAILED};
        return $self;
      }
    }
  }
  return $self;
}

#**********************************************************
=head2 _unsubscribe_card($attr)

=cut
#**********************************************************
sub _unsubscribe_card {
  my ($attr) = @_;

  my $ftp = Net::FTP->new($CONF->{CONAX_FTP_HOST}, Timeout => 5, Debug => 0) or die print "Cannot connect to some.host.name: $@\n";

  $ftp->login($CONF->{CONAX_FTP_LOGIN}, $CONF->{CONAX_FTP_PASSWORD}) or die print "Cannot login: " . $ftp->message;

  while (length "$attr->{UNSUBSCRIBE}" < 6) {
    $attr->{UNSUBSCRIBE} = "0" . $attr->{UNSUBSCRIBE};
  }

  my $filters = $Iptv->user_list({
    ID        => $attr->{UNSUBSCRIBE},
    TP_FILTER => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 99999,
  });

  if (!$Iptv->{TOTAL}) {
    $html->message('err', $lang->{ERROR}, $lang->{SET_FILTER_ID_IN_TARIFF});
    return 0;
  }

  my $card_ = $attr->{card};
  chop $card_;

  my @filter_ids = split(",", $filters->[0]{filter_id});

  foreach my $filter (@filter_ids) {
    my $id = int $filter + int $attr->{UNSUBSCRIBE};

    while (length "$id" < 6) {
      $id = "0" . $id;
    }

    while (length $filter < 8) {
      $filter = "0" . $filter;
    }

    my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));

    my ($current_year, $current_month, undef) = split(/-/, $DATE, 3);
    my ($year, $month, $day) = _get_date();

    my $file_name = "";
    $file_name = "cs$id.tmp";
    my $new_file_name = "";
    $new_file_name = "cs$id.emm";

    return 1 if !$file_name;
    open(FILE, ">", "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name") or die "Couldn't open: $!";

    print FILE "U\n";
    print FILE "$id\n";
    print FILE "$filter\n";
    print FILE "$current_year$current_month" . "010000\n";
    print FILE "$year$month$day" . "2359\n";
    print FILE "U\n";
    print FILE "EMM\n";
    print FILE "U\n";
    print FILE "00001\n";
    print FILE "$card_\n";
    print FILE "ZZZ\n";

    close FILE;

    $ftp->cwd('/autreq/req') or die print "Cannot change directory $ftp->message";

    $ftp->put("/usr/axbills/AXbills/modules/Iptv/Conax/$file_name") or die print "Cannot put file" . $ftp->message;

    $ftp->rename("$file_name", "$new_file_name") or die print "Cannot rename file" . $ftp->message;

    unlink "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name";
  }

  my $error_delete = 0;
  sleep 1;
  my $result = '';
  foreach my $filter (@filter_ids) {
    my $id = int $filter + int $attr->{UNSUBSCRIBE};

    while (length "$id" < 6) {
      $id = "0" . $id;
    }

    my $file_name = "";
    $file_name = "cs$id.emm";
    my $count = 0;

    while (1) {
      $count++;
      $ftp->cwd('/autreq/ok') or die print "Cannot change directory $ftp->message";
      $result = $ftp->delete("$file_name");
      last if $result;

      $ftp->cwd('/autreq/err') or die print "Cannot change directory $ftp->message";
      $result = $ftp->delete("$file_name");
      if ($result) {
        $error_delete = 1;
        last;
      }
      sleep 1;
      if ($count > 3) {
        return 0;
      }
    }
  }

  return 0 if $error_delete;

  return 1;
}

#**********************************************************
=head2 _subscribe_card($attr)

=cut
#**********************************************************
sub _subscribe_card {
  my ($attr) = @_;

  if (!$attr->{UNBLOCK}) {
    if (!$attr->{UID}) {
      my $info_ = $Iptv->user_info($attr->{SUBSCRIBE});
      $attr->{UID} = $info_->{UID} || 0;
    }
    my $user_cards = $Iptv->user_list({
      CID       => $attr->{card},
      UID       => '_SHOW',
      COLS_NAME => 1,
      PAGE_ROWS => 100000
    });

    foreach my $card (@{$user_cards}) {
      if ($card->{uid} ne $attr->{UID}) {
        $html->message('err', $lang->{ERROR}, $lang->{CARD_EXIST} . " " . $html->button($card->{uid}, "index=15&UID=$card->{uid}"));
        return 0;
      }
    }

    my $user_screens = $Iptv->users_screens_list({
      CID         => $attr->{card},
      SCREEN_ID   => '_SHOW',
      UID         => '_SHOW',
      SHOW_ASSIGN => 1,
      COLS_NAME   => 1,
      PAGE_ROWS   => 100000
    });

    foreach my $card (@{$user_screens}) {
      if ($card->{uid} ne $attr->{UID}) {
        $html->message('err', $lang->{ERROR}, $lang->{CARD_EXIST} . " " . $html->button($card->{uid}, "index=15&UID=$card->{uid}"));
        return 0;
      }
    }
  }

  if ($attr->{MAIN_CID} && !$attr->{UNBLOCK}) {
    $Iptv->user_info($attr->{SUBSCRIBE});
    if ($Iptv->{TOTAL} && $Iptv->{SUBSCRIBE_ID}) {
      $html->message('err', $lang->{ERROR}, $lang->{CARD_LOCKED});
      return 0;
    }
  }
  elsif (!$attr->{MAIN_CID} && !$attr->{UNBLOCK}) {
    $Iptv->users_screens_info($attr->{SUBSCRIBE}, { SCREEN_ID => $attr->{CARD_ID} });
    if ($Iptv->{TOTAL} && $Iptv->{HARDWARE_ID}) {
      $html->message('err', $lang->{ERROR}, $lang->{CARD_LOCKED});
      return 0;
    }
  }

  my $filters = $Iptv->user_list({
    ID        => $attr->{SUBSCRIBE},
    TP_FILTER => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 99999,
  });

  if (!$Iptv->{TOTAL}) {
    $html->message('err', $lang->{ERROR}, $lang->{SET_FILTER_ID_IN_TARIFF});
    return 0;
  }

  my $card_length = length $attr->{card};
  if ($card_length != 12) {
    $html->message('err', $lang->{ERROR}, $lang->{ERROR_CARD});
    return 1;
  }
  my $card_ = $attr->{card};
  chop $card_;

  my $ftp = Net::FTP->new($CONF->{CONAX_FTP_HOST}, Timeout => 5, Debug => 0) or die print "Cannot connect to some.host.name: $@\n";

  $ftp->login($CONF->{CONAX_FTP_LOGIN}, $CONF->{CONAX_FTP_PASSWORD}) or die print "Cannot login: " . $ftp->message;

  my @filter_ids = split(",", $filters->[0]{filter_id});

  foreach my $filter (@filter_ids) {
    my $id = int $filter + int $attr->{SUBSCRIBE};

    while (length "$id" < 6) {
      $id = "0" . $id;
    }

    while (length $filter < 8) {
      $filter = "0" . $filter;
    }

    my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));

    my ($current_year, $current_month, undef) = split(/-/, $DATE, 3);
    my ($year, $month, $day) = _get_date();

    my $file_name = "";
    $file_name = "ps$id.tmp";
    my $new_file_name = "";
    $new_file_name = "ps$id.emm";

    return 1 if !$file_name;

    open(FILE, ">", "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name") or die "Couldn't open: $!";

    print FILE "U\n";
    print FILE "$id\n";
    print FILE "$filter\n";
    print FILE "$current_year$current_month" . "010000\n";
    print FILE "$year$month$day" . "2359\n";
    print FILE "U\n";
    print FILE "EMM\n";
    print FILE "U\n";
    print FILE "00001\n";
    print FILE "$card_\n";
    print FILE "ZZZ\n";

    close FILE;

    $ftp->cwd('/autreq/req') or die print "Cannot change directory $ftp->message";

    $ftp->put("/usr/axbills/AXbills/modules/Iptv/Conax/$file_name") or die print "Cannot put file" . $ftp->message;

    $ftp->rename("$file_name", "$new_file_name") or die print "Cannot rename file" . $ftp->message;

    unlink "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name";
  }

  my $error_delete = 0;
  sleep 1;
  my $result = '';
  foreach my $filter (@filter_ids) {
    my $id = int $filter + int $attr->{SUBSCRIBE};

    while (length "$id" < 6) {
      $id = "0" . $id;
    }

    my $file_name = "";
    $file_name = "ps$id.emm";
    my $count = 0;

    while (1) {
      $count++;
      $ftp->cwd('/autreq/ok') or die print "Cannot change directory $ftp->message";
      $result = $ftp->delete("$file_name");
      if ($result && $attr->{ONE_CARD}) {
        last;
      }
      elsif ($result && !$attr->{MAIN_CID}) {
        last;
      }
      elsif ($result && $attr->{MAIN_CID}) {
        last;
      }

      $ftp->cwd('/autreq/err') or die print "Cannot change directory $ftp->message";
      $result = $ftp->delete("$file_name");
      if ($result) {
        $error_delete = 1;
        last;
      }

      sleep 1;
      if ($count > 3) {
        return 0;
      }
    }
  }

  return 0 if $error_delete;

  return 1;
}

#**********************************************************
=head2 _additional_cards($attr)

=cut
#**********************************************************
sub _additional_cards {
  my ($attr) = @_;

  my @filter_ids = split(",", $attr->{TP_FILTER_ID});

  my $ftp = Net::FTP->new($CONF->{CONAX_FTP_HOST}, Timeout => 5, Debug => 0) or die print "Cannot connect to some.host.name: $@\n";

  $ftp->login($CONF->{CONAX_FTP_LOGIN}, $CONF->{CONAX_FTP_PASSWORD}) or die print "Cannot login: " . $ftp->message;

  if (!$attr->{ID} || !$attr->{TP_FILTER_ID}) {
    return 1;
  }

  my $card_length = length $attr->{CID};
  if ($card_length != 12) {
    $html->message('err', $lang->{ERROR}, $lang->{ERROR_CARD}) if !$attr->{CONSOLE};
    print "$lang->{ERROR_CARD}\n" if $attr->{CONSOLE};
    return 0;
  }

  if ($attr->{COUNT}) {
    $attr->{COUNT}++;
  }
  else {
    $attr->{COUNT} = 1;
  }
  my $cards = _sort_cards($attr);
  my $cards_length = 0;
  if ($cards) {
    $cards_length = @{$cards};
  }
  if (!$cards_length) {
    $html->message('err', $lang->{ERROR}, $lang->{NO_CARDS}) if !$attr->{CONSOLE};
    print "$lang->{NO_CARDS}\n" if $attr->{CONSOLE};
    return 0;
  }

  foreach my $filter (@filter_ids) {
    my $id = int $filter + int $attr->{ID};

    while (length "$id" < 6) {
      $id = "0" . $id;
    }

    while (length $filter < 8) {
      $filter = "0" . $filter;
    }

    my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
    my ($current_year, $current_month, undef) = split(/-/, $DATE, 3);
    my ($year, $month, $day) = _get_date();

    my $file_name = "";
    $file_name = "ps$id.tmp" if !$attr->{STATUS};
    $file_name = "cs$id.tmp" if ($attr->{STATUS} && $attr->{STATUS} eq '1');
    my $new_file_name = "";
    $new_file_name = "ps$id.emm" if !$attr->{STATUS};
    $new_file_name = "cs$id.emm" if ($attr->{STATUS} && $attr->{STATUS} eq '1');

    return 0 if !$file_name;

    open(FILE, ">", "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name") or die "Couldn't open: $!";

    print FILE "U\n";
    print FILE "$id\n";
    print FILE "$filter\n";
    print FILE "$current_year$current_month" . "010000\n";
    print FILE "$year$month$day" . "2359\n";
    print FILE "U\n";
    print FILE "EMM\n";
    print FILE "U\n";
    print FILE "0000$cards_length\n";

    foreach my $card (@{$cards}) {
      $card_length = length $card->{cid};

      if ($card_length != 12) {
        $html->message("err", $lang->{ERROR_CARD});
        unlink "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name";
        return 1;
      }
      my $card_mac = $card->{cid};
      chop $card_mac;
      print FILE "$card_mac\n";
    }

    print FILE "ZZZ\n";

    close FILE;

    $ftp->cwd('/autreq/req') or die print "Cannot change directory $ftp->message";

    $ftp->put("/usr/axbills/AXbills/modules/Iptv/Conax/$file_name") or die print "Cannot put file" . $ftp->message;

    $ftp->rename("$file_name", "$new_file_name") or die print "Cannot rename file" . $ftp->message;

    unlink "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name";
  }

  my $error_delete = 0;
  sleep 1;
  my $result = '';
  foreach my $filter (@filter_ids) {
    my $id = int $filter + int $attr->{ID};
    while (length "$id" < 6) {
      $id = "0" . $id;
    }

    my $file_name = "";
    $file_name = "ps$id.emm" if !$attr->{STATUS};
    $file_name = "cs$id.emm" if ($attr->{STATUS} && $attr->{STATUS} eq '1');
    my $count = 0;

    while (1) {
      $count++;
      $ftp->cwd('/autreq/ok') or die print "Cannot change directory $ftp->message";
      $result = $ftp->delete("$file_name");
      if ($result) {
        last;
      }

      $ftp->cwd('/autreq/err') or die print "Cannot change directory $ftp->message";
      $result = $ftp->delete("$file_name");
      if ($result) {
        $error_delete = 1;
        last;
      }

      sleep 1;
      if ($count > 3) {
        return 0;
      }
    }
  }

  return 0 if $error_delete;

  return 1;
}

#**********************************************************
=head2 user_negdeposit($attr)

  Arguments:
    $attr
      UID

  Results:

=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  my $screens = $Iptv->users_active_screens_list({
    SERVICE   => $attr->{ID},
    COLS_NAME => 1
  });

  my $count = 0;
  if (ref $screens eq 'ARRAY') {
    $count = @$screens;
  }

  $attr->{STATUS} = 1;
  $attr->{TP_FILTER_ID} = $attr->{FILTER_ID};

  my $infos = $Iptv->user_info($attr->{ID});

  if ($Iptv->{TOTAL}) {
    $attr->{CID} = $infos->{CID} || $infos->{cid};
  }

  my $result = _additional_cards({ %$attr, CARDS => $screens, COUNT => $count, CONSOLE => 1 });
  if (!$result) {
    $self->{errno} = '10102';
    $self->{errstr} = $lang->{PROCESSING_ERROR};
    return $self;
  }
  else {
    delete $self->{errno};
    delete $self->{errstr};
  }

  return $self;
}

#**********************************************************
=head2 _sort_cards($attr)

  Arguments:
    $attr
      UID

  Results:

=cut
#**********************************************************
sub _sort_cards {
  my ($attr) = @_;

  my @cards = ();
  my @return_cards = ();

  if (!$attr->{STATUS}) {
    if (!$attr->{CARDS} && !$attr->{SUBSCRIBE_ID}) {
      push @cards, { cid => $attr->{CID} };
      return \@cards;
    }
    elsif (!$attr->{CARDS}) {
      return @cards;
    }

    @cards = @{$attr->{CARDS}};
    push @cards, { cid => $attr->{CID} } if !$attr->{SUBSCRIBE_ID};

    my $cid = "";
    foreach my $card (@cards) {
      $cid = $card->{cid};
      chop $cid;
      $card->{prior} = substr($cid, -1) ne "0" ? substr($cid, -1) : 10;
    }
    my @sorted = sort {$a->{prior} <=> $b->{prior}} @cards;

    foreach my $card (@sorted) {
      if ($card->{service_id} && $card->{hardware_id}) {
        next;
      }
      else {
        push @return_cards, $card;
      }
    }
  }
  else {
    if (!$attr->{CARDS}) {
      push @cards, { cid => $attr->{CID} };
      return \@cards;
    }

    @cards = @{$attr->{CARDS}};
    push @cards, { cid => $attr->{CID} };

    my $cid = "";
    foreach my $card (@cards) {
      $cid = $card->{cid};
      chop $cid;
      $card->{prior} = substr($cid, -1) ne "0" ? substr($cid, -1) : 10;
    }

    # my @sorted = sort {$a->{prior} <=> $b->{prior}} @cards;
    my @sorted = sort {$a->{cid} <=> $b->{cid}} @cards;

    return \@sorted;
  }

  return \@return_cards;
}

#**********************************************************
=head2 _get_block_cards($attr)

  Arguments:
    $attr
      UID

  Results:

=cut
#**********************************************************
sub _get_block_cards {
  my ($attr) = @_;

  my @cards = ();

  if (!$attr->{CARDS} && $attr->{SUBSCRIBE_ID}) {
    push @cards, { cid => $attr->{CID} };
    return \@cards;
  }
  elsif (!$attr->{CARDS}) {
    return();
  }

  @cards = @{$attr->{CARDS}};
  push @cards, { cid => $attr->{CID} } if $attr->{SUBSCRIBE_ID};

  my @return_cards = ();

  foreach my $card (@cards) {
    if ($card->{service_id} && !$card->{hardware_id}) {
      next;
    }
    else {
      push @return_cards, $card;
    }
  }

  return \@return_cards;
}

#**********************************************************
=head2 _show_main_card_btn($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub _show_main_card_btn {
  my ($attr) = @_;

  my $card_status = !$attr->{USER_INFO}{SUBSCRIBE_ID} ? "BLOCK" : "UNBLOCK";
  my $card_sub = $html->button($lang->{SIGN},
    "get_index=iptv_user&SUBSCRIBE=$attr->{status_id}&card=$attr->{USER_INFO}{CID}&UID=$attr->{UID}&MAIN_CID=1&SERVICE_ID=$attr->{SERVICE_ID}&additional_functions=1&header=2",
    {
      class         => 'btn-xs',
      LOAD_TO_MODAL => 1,
      BUTTON        => 1,
    });
  my $card_unsub = $html->button($lang->{UNSUBSCRIBE},
    "get_index=iptv_user&UNSUBSCRIBE=$attr->{status_id}&card=$attr->{USER_INFO}{CID}&UID=$attr->{UID}&MAIN_CID=1&SERVICE_ID=$attr->{SERVICE_ID}&additional_functions=1&header=2",
    {
      class         => 'btn-xs',
      LOAD_TO_MODAL => 1,
      BUTTON        => 1,
    });
  my $card_block = $html->button($lang->{"$card_status"},
    "get_index=iptv_user&$card_status=$attr->{status_id}&card=$attr->{USER_INFO}{CID}&UID=$attr->{UID}&MAIN_CID=1&SERVICE_ID=$attr->{SERVICE_ID}&additional_functions=1&header=2",
    {
      class         => 'btn-xs',
      LOAD_TO_MODAL => 1,
      BUTTON        => 1,
    });

  return($card_sub, $card_unsub, $card_block);
}

#**********************************************************
=head2 _get_date($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub _get_date {

  my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
  my ($current_year, $current_month, undef) = split(/-/, $DATE, 3);

  my $month = int $current_month;
  if ($CONF->{CONAX_DATE} eq "12") {
    $current_year = int $current_year + 1;
    $month = int $current_month;
  }
  elsif (int $CONF->{CONAX_DATE} < 12) {
    my $temp = int $CONF->{CONAX_DATE} + $month;
    if (int $temp > 12) {
      $month = $temp % 12;
      $current_year = int $current_year + 1;
    }
    else {
      $month = $temp;
    }
  }
  else {
    $current_year = int $current_year + int($CONF->{CONAX_DATE} / 12);
    my $temp = int($CONF->{CONAX_DATE} % 12) + $month;
    if (int $temp > 12) {
      $month = $temp % 12;
      $current_year = int $current_year + 1;
    }
    else {
      $month = $temp;
    }
  }
  $month = "0" . $month if (length $month == 1);

  my $temp_month = $month eq "12" ? 11 : $month;

  my $days_number = (localtime(timelocal(0, 0, 0, 1, $temp_month, $current_year - 1900) - 1))[3];

  if ($month eq "12") {
    $days_number = 31;
  }

  return($current_year, $month, $days_number);
}

1;
