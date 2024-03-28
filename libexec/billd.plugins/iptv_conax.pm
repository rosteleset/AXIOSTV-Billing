=head1 NAME

 billd plugin

 DESCRIBE:  Conax - work with SMS

 Arguments:

=cut

use strict;
use warnings;
use Iptv;
use Users;
use Tariffs;
use AXbills::Base qw(load_pmodule in_array _bp);
use threads;
use Net::FTP;
use Time::Local qw(timelocal_nocheck timelocal);

our (
  %lang,
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
  $OS,
  $var_dir
);

our $Iptv = Iptv->new($db, $Admin, \%conf);
my $Users = Users->new($db, $Admin, \%conf);
require Iptv::Services;

my $ftp = Net::FTP->new($conf{CONAX_FTP_HOST}, Timeout => 5, Debug => ($argv->{DEBUG} || 0)) or die print "Cannot connect to $conf{CONAX_FTP_HOST}: $@\n";

$ftp->login($conf{CONAX_FTP_LOGIN}, $conf{CONAX_FTP_PASSWORD}) or die print "Cannot login: " . $ftp->message;

conax_load_to_server() if ($argv->{LOAD});
conax_delete_from_server() if ($argv->{DELETE});
get_status() if ($argv->{STATUS});
users_oversubscription() if ($argv->{OVERSUBS});

#**********************************************************
=head2 conax_load_to_server($attr)

=cut
#**********************************************************
sub conax_load_to_server {

  my $services = $Iptv->services_list({
    MODULE    => 'Conax',
    COLS_NAME => 1,
    ID        => $argv->{SERVICE_ID} || '_SHOW',
  });

  return 1 if !$Iptv->{TOTAL};

  foreach my $service (@$services) {
    my $users_ = $Iptv->user_list({
      SERVICE_ID     => $service->{id},
      TP_FILTER      => '_SHOW',
      UID            => '_SHOW',
      ID             => '_SHOW',
      SERVICE_STATUS => '_SHOW',
      SUBSCRIBE_ID   => ">0",
      CID            => '_SHOW',
      COLS_NAME      => 1,
    });

    foreach my $user (@$users_) {
      next if ($user->{subscribe_id} > 3);

      my $screens = $Iptv->users_active_screens_list({
        SERVICE   => $user->{id},
        COLS_NAME => 1
      });

      my $count = 0;
      if (ref $screens eq 'ARRAY') {
        $count = @$screens;
      }

      if ($user->{subscribe_id}) {
        _additional_cards({ %$user, CARDS => $screens, COUNT => $count });
        $Iptv->user_change({
          ID           => $user->{id},
          SUBSCRIBE_ID => "99999",
        });
      }
    }
  }

  return 0;
}

#**********************************************************
=head2 conax_delete_from_server($attr)

=cut
#**********************************************************
sub conax_delete_from_server {
  my $services = $Iptv->services_list({
    MODULE    => 'Conax',
    COLS_NAME => 1,
    ID        => $argv->{SERVICE_ID} || '_SHOW',
  });

  return 1 if !$Iptv->{TOTAL};

  foreach my $service (@$services) {
    my $users_ = $Iptv->user_list({
      SERVICE_ID     => $service->{id},
      TP_FILTER      => '_SHOW',
      UID            => '_SHOW',
      ID             => '_SHOW',
      SUBSCRIBE_ID   => "1",
      CID            => '_SHOW',
      SERVICE_STATUS => '_SHOW',
      COLS_NAME      => 1,
    });

    foreach my $user (@$users_) {
      my $result = _conax_del_user($user);

      next if !$result;

      if ($result == 1) {
        $Iptv->user_change({
          ID           => $user->{id},
          SUBSCRIBE_ID => "0",
        });
      }
      elsif ($result == 2) {
        $Iptv->user_change({
          ID           => $user->{id},
          SUBSCRIBE_ID => "0",
          STATUS       => 1
        });
      }
    }
  }
}

#**********************************************************
=head2 _conax_del_user($attr)

=cut
#**********************************************************
sub _conax_del_user {
  my ($attr) = @_;

  my @filter_ids = split(",", $attr->{filter_id});

  return 0 if (!$attr->{id} || !$attr->{filter_id});

  my $count = 0;

  foreach my $filter (@filter_ids) {
    my $id = int $filter + int $attr->{id};

    while (length "$id" < 6) {
      $id = "0" . $id;
    }

    while (length $filter < 8) {
      $filter = "0" . $filter;
    }

    my $file_name = "";
    $file_name = "ps$id.emm" if !$attr->{service_status};
    $file_name = "cs$id.emm" if ($attr->{service_status} eq '1');

    $ftp->cwd('/autreq/ok') or die print "Cannot change directory $ftp->message";

    my $result = $ftp->delete('/autreq/ok/' . $file_name);

    $count++ if $result;
    next if $result;

    $ftp->cwd('/autreq/err') or die print "Cannot change directory $ftp->message";

    $result = $ftp->delete('/autreq/err/' . $file_name);

    $count = -100 if $result;
  }

  return $count > 0 ? 1 : 2;

  return 0;
}

#**********************************************************
=head2 get_status($attr)

=cut
#**********************************************************
sub get_status {

  my $services = $Iptv->services_list({
    MODULE    => 'Conax',
    COLS_NAME => 1,
    ID        => $argv->{SERVICE_ID} || '_SHOW',
  });

  return 1 if !$Iptv->{TOTAL};

  foreach my $service (@$services) {
    my $users_ = $Iptv->user_list({
      SERVICE_ID     => $service->{id},
      TP_FILTER      => '_SHOW',
      UID            => '_SHOW',
      ID             => '_SHOW',
      SUBSCRIBE_ID   => "10",
      CID            => '_SHOW',
      SERVICE_STATUS => '_SHOW',
      COLS_NAME      => 1,
    });

    foreach my $user (@$users_) {
      while (length $user->{id} < 6) {
        $user->{id} = "0" . $user->{id};
      }
      my $file_name = "";
      $file_name = "sc$user->{id}.emm";

      $ftp->cwd('/autreq/ok') or die print "Cannot change directory $ftp->message";

      my $result_get = $ftp->get($file_name, "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name");

      if (!$result_get) {
        my $result = $ftp->delete("/autreq/err/$file_name");
        next if !$result;

        $Iptv->user_change({
          ID           => $user->{id},
          SUBSCRIBE_ID => "0",
        });
        next;
      }

      $ftp->delete("/autreq/ok/$file_name");
      $Iptv->user_change({
        ID           => $user->{id},
        SUBSCRIBE_ID => "11",
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 _additional_cards($attr)

=cut
#**********************************************************
sub _additional_cards {
  my ($attr) = @_;

  my @filter_ids = split(",", $attr->{filter_id});

  return 1 if (!$attr->{id} || !$attr->{filter_id});

  my $card_length = length $attr->{cid};
  if ($card_length != 12) {
    return 1;
  }
  chop $attr->{cid};

  if ($attr->{COUNT}) {
    $attr->{COUNT}++;
  }
  else {
    $attr->{COUNT} = 1;
  }

  foreach my $filter (@filter_ids) {
    my $id = int $filter + int $attr->{id};

    while (length "$id" < 6) {
      $id = "0" . $id;
    }

    while (length $filter < 8) {
      $filter = "0" . $filter;
    }

    my ($current_year, $current_month, undef) = split(/-/, $DATE, 3);
    my $next_year = $current_year + 1;
    my $days_number = (localtime(timelocal(0, 0, 0, 1, $current_month, $next_year - 1900) - 1))[3];

    my $file_name = "";
    $file_name = "ps$id.emm" if !$attr->{status};
    $file_name = "cs$id.emm" if ($attr->{status} && $attr->{status} eq '1');

    return 1 if !$file_name;

    open(FILE, ">", "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name") or die "Couldn't open: $!";

    print FILE "U\n";
    print FILE "$id\n";
    print FILE "$filter\n";
    print FILE "$current_year$current_month" . "010000\n";
    print FILE "$next_year$current_month$days_number" . "2359\n";
    print FILE "U\n";
    print FILE "EMM\n";
    print FILE "U\n";
    print FILE "0000$attr->{COUNT}\n";
    print FILE "$attr->{cid}\n";

    foreach my $card (@{$attr->{CARDS}}) {
      $card_length = length $card->{cid};

      if ($card_length != 12) {
        print "Error! Card must have 12 characters\n";
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

    unlink "/usr/axbills/AXbills/modules/Iptv/Conax/$file_name";
  }

  return 0;
}

#**********************************************************
=head2 users_oversubscription($attr)

=cut
#**********************************************************
sub users_oversubscription {

  my $services = $Iptv->services_list({
    MODULE    => 'Conax',
    COLS_NAME => 1,
    ID        => $argv->{SERVICE_ID} || '_SHOW',
  });

  foreach my $service (@$services) {
    my $users_ = $Iptv->user_list({
      SERVICE_ID     => $service->{id},
      TP_NAME        => '_SHOW',
      TP_FILTER      => '_SHOW',
      UID            => '_SHOW',
      ID             => '_SHOW',
      SERVICE_STATUS => '0',
      SUBSCRIBE_ID   => "_SHOW",
      CID            => '_SHOW',
      COLS_NAME      => 1,
      SORT           => 'service.uid',
      PAGE_ROWS      => 10000
    });

    foreach my $user (@$users_) {
      $Users->info($user->{uid});
      next if ($Users->{DISABLE});

      print "Oversubscribe user uid - $user->{uid}, TP - $user->{tp_name}...\n";
      my $screens = $Iptv->users_active_screens_list({
        SERVICE   => $user->{id},
        COLS_NAME => 1
      });

      my $count = 0;
      if (ref $screens eq 'ARRAY') {
        $count = @$screens;
      }

      $user->{status} = $user->{service_status};
      if (_subscribe_user({ %$user, CARDS => $screens, COUNT => $count })) {
        print "Successfully oversub.\n";
      }
      else {
        print "Error in the re-subscription process\n";
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 _subscribe_user($attr)

=cut
#**********************************************************
sub _subscribe_user {
  my ($attr) = @_;

  my @filter_ids = split(",", $attr->{filter_id});

  if (!$attr->{id} || !$attr->{filter_id}) {
    print "Set Filter id in tariff\n";
    return 0;
  }

  my $card_length = length $attr->{cid};
  if ($card_length != 12) {
    print "Card must have 12 characters\n";
    return 0;
  }
  my $cards = _sort_cards($attr);
  my $cards_length = @{$cards};
  if (!$cards_length) {
    print "There are no cards to activate (either blocked or missing)\n";
    return 0;
  }

  if ($attr->{COUNT}) {
    $attr->{COUNT}++;
  }
  else {
    $attr->{COUNT} = 1;
  }

  foreach my $filter (@filter_ids) {
    my $id = int $filter + int $attr->{id};

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
    $file_name = "ps$id.tmp" if !$attr->{status};
    $file_name = "cs$id.tmp" if ($attr->{status} && $attr->{status} eq '1');
    my $new_file_name = "";
    $new_file_name = "ps$id.emm" if !$attr->{status};
    $new_file_name = "cs$id.emm" if ($attr->{status} && $attr->{status} eq '1');

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
        print "Card must have 12 characters\n";
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
    my $id = int $filter + int $attr->{id};
    while (length "$id" < 6) {
      $id = "0" . $id;
    }

    my $file_name = "";
    $file_name = "ps$id.emm" if !$attr->{status};
    $file_name = "cs$id.emm" if ($attr->{status} && $attr->{status} eq '1');
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
  if (!$attr->{CARDS} && !$attr->{subscribe_id}) {
    push @cards, { cid => ($attr->{cid} || $attr->{CID}) };
    return \@cards;
  }
  elsif (!$attr->{CARDS}) {
    return \@cards;
  }

  @cards = @{$attr->{CARDS}};
  push @cards, { cid => ($attr->{cid} || $attr->{CID}) } if !$attr->{subscribe_id};

  # my $cid = "";
  # foreach my $card (@cards) {
  #   $cid = $card->{cid};
  #   chop $cid;
  #   $card->{prior} = substr($cid, -1) ne "0" ? substr($cid, -1) : 10;
  # }
  my @sorted = sort {$a->{cid} <=> $b->{cid}} @cards;
  my @return_cards = ();

  foreach my $card (@sorted) {
    if ($card->{service_id} && $card->{hardware_id}) {
      next;
    }
    else {
      push @return_cards, $card;
    }
  }

  return \@return_cards;
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
  if ($conf{CONAX_DATE} eq "12") {
    $current_year = int $current_year + 1;
    $month = int $current_month;
  }
  elsif (int $conf{CONAX_DATE} < 12) {
    my $temp = int $conf{CONAX_DATE} + $month;
    if (int $temp > 12) {
      $month = $temp % 12;
      $current_year = int $current_year + 1;
    }
    else {
      $month = $temp;
    }
  }
  else {
    $current_year = int $current_year + int($conf{CONAX_DATE} / 12);
    my $temp = int($conf{CONAX_DATE} % 12) + $month;
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
