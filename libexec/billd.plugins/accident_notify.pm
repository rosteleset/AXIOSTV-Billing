# billd plugin
#**********************************************************
=head1

 billd plugin

 Standart execute
    /usr/axbills/libexec/billd accident_notify

 DESCRIBE:  Notify user about accident

=cut
#*********************************************************
use strict;
use warnings FATAL => 'all';
use AXbills::Sender::Core;
use AXbills::Base qw(sendmail in_array);
use Accident;
use Users;

our (
  $db,
  $Admin,
  %conf,
  %lang,
  $debug,
  $var_dir,
  $base_dir
);
do "$base_dir/AXbills/modules/Accident/lng_$conf{default_language}.pl";

my $Accident = Accident->new($db, $Admin, \%conf);
my $Internet = Internet->new($db, $Admin, \%conf);
my $Users = Users->new($db, $Admin, \%conf);
my $Sender = AXbills::Sender::Core->new($db, $Admin, \%conf);
my $Log = Log->new($db, $Admin);

if ($debug > 2) {
  $Log->{PRINT} = 1;
}
else {
  $Log->{LOG_FILE} = $var_dir . '/log/accident_push.log';
}

if (!$conf{ACCIDENT_WARNING}) {
  print "Please add the types of sending in \$conf{ACCIDENT_WARNING} to config.pl \n";
  return 1;
}

$conf{ACCIDENT_WARNING} =~ s/ //g;
my @sender_types = split(/,\s?/, $conf{ACCIDENT_WARNING});

accident_notify_open();
accident_notify_close();
accident_equipment_notify_open();
accident_equipment_notify_close();

#**********************************************************
=head2 accident_open_notify() - send notify to abonent about opening accident

=cut
#**********************************************************
sub accident_notify_open {
  my $debug_output = '';
  $debug_output .= "Accident open notify\n" if ($debug > 1);

  $Accident->{debug} = 1 if $debug > 6;

  my $accident_list = $Accident->list({
    SKIP_STATUS => '2',
    NAME        => '_SHOW',
    FROM_DATE   => $DATE,
    TO_DATE     => '_SHOW',
    END_TIME    => '_SHOW',
    SENT_OPEN   => 0,
    COLS_NAME   => 1
  });

  return 1 if (!$Accident->{TOTAL});

  foreach my $accident (@$accident_list) {
    my $count = 0;

    my $accident_address_info = $Accident->accident_address_info($accident->{id});

    foreach my $accident_addr (@$accident_address_info) {
      my $type_id = $accident_addr->{type_id};
      my $address_id = $accident_addr->{address_id};
      my $location_info = _search_address($type_id, $address_id);

      my $users = $Users->list({
        DISTRICT_ID => ($location_info->{DISTRICT}) ? $location_info->{DISTRICT} : '',
        STREET_ID   => ($location_info->{STREET}) ? $location_info->{STREET} : '',
        LOCATION_ID => ($location_info->{BUILD}) ? $location_info->{BUILD} : '',
        UID         => '_SHOW',
        PAGE_ROWS   => 999999,
        COLS_NAME   => 1,
      });

      if ($Users->{TOTAL} > 0) {
        foreach my $user (@$users) {
          accident_send_warning({
            UID  => $user->{uid},
            TEXT => "$lang{WARNING_TIME}$accident->{end_time}"
          });
          $count++;
        }
      }
    }

    $Accident->change({
      ID        => $accident->{id},
      SENT_OPEN => $count,
    });
  }

  return 1;
}


#**********************************************************
=head2 accident_notify_close() - send notify to abonent about closing accident

=cut
#**********************************************************
sub accident_notify_close {
  my $debug_output = '';
  $debug_output .= "Accident close notify\n" if ($debug > 1);

  $Accident->{debug} = 1 if $debug > 6;

  my $accident_list = $Accident->list({
    SKIP_STATUS => '0,1',
    REALY_TIME  => ">$DATE 00:00:00",
    SENT_CLOSE  => 0,
    COLS_NAME   => 1
  });

  return 1 if (!$Accident->{TOTAL});

  foreach my $accident (@$accident_list) {
    my $count = 0;

    my $accident_address_info = $Accident->accident_address_info($accident->{id});

    foreach my $accident_addr (@$accident_address_info) {
      my $type_id = $accident_addr->{type_id};
      my $address_id = $accident_addr->{address_id};
      my $location_info = _search_address($type_id, $address_id);

      my $users = $Users->list({
        DISTRICT_ID => ($location_info->{DISTRICT}) ? $location_info->{DISTRICT} : '',
        STREET_ID   => ($location_info->{STREET}) ? $location_info->{STREET} : '',
        LOCATION_ID => ($location_info->{BUILD}) ? $location_info->{BUILD} : '',
        UID         => '_SHOW',
        PAGE_ROWS   => 999999,
        COLS_NAME   => 1,
      });

      if ($Users->{TOTAL} > 0) {
        foreach my $user (@$users) {
          accident_send_warning({
            UID  => $user->{uid},
            TEXT => $lang{ACCIDENT_FIXED}
          });
          $count++;
        }
      }
    }

    $Accident->change({
      ID         => $accident->{id},
      SENT_CLOSE => $count,
    });

  }

  return 1;
}


#**********************************************************

=head2 accident_equipment_notify_open()

=cut

#**********************************************************
sub accident_equipment_notify_open {
  my $debug_output = '';
  $debug_output .= "Accident equipment notify\n" if ($debug > 1);

  my $accident_equipment = $Accident->accident_equipment_list({
    ID_EQUIPMENT => '_SHOW',
    DATE         => $DATE,
    STATUS       => 0,
    SENT_OPEN    => 0,
    END_DATE     => '_SHOW',
    PAGE_ROWS    => 9999,
    COLS_NAME    => 1
  });

  return 1 if (!$Accident->{TOTAL});

  foreach my $equipment (@$accident_equipment) {
    my $count = 0;

    my $users = $Internet->user_list({
      NAS_ID    => $equipment->{id_equipment},
      COLS_NAME => 1,
    });

    if ($Internet->{TOTAL} > 0) {
      foreach my $user (@$users) {
        accident_send_warning({
          UID  => $user->{uid},
          TEXT => "$lang{WARNING_TIME}$equipment->{end_date}"
        });
        $count++;
      }
    }

    $Accident->accident_equipment_chg({
      ID         => $equipment->{id},
      SENT_OPEN  => $count,
    });
  }

  return 1;
}

#**********************************************************

=head2 accident_equipment_notify_open()

=cut

#**********************************************************
sub accident_equipment_notify_close {
  my $debug_output = '';
  $debug_output .= "Accident equipment notify close\n" if ($debug > 1);

  my $accident_equipment = $Accident->accident_equipment_list({
    ID_EQUIPMENT => '_SHOW',
    STATUS       => 2,
    SENT_CLOSE   => 0,
    END_DATE     => $DATE,
    PAGE_ROWS    => 9999,
    COLS_NAME    => 1
  });

  return 1 if (!$Accident->{TOTAL});

  foreach my $equipment (@$accident_equipment) {
    my $count = 0;

    my $users = $Internet->user_list({
      NAS_ID    => $equipment->{id_equipment},
      COLS_NAME => 1,
    });

    if ($Internet->{TOTAL} > 0) {
      foreach my $user (@$users) {
        accident_send_warning({
          UID  => $user->{uid},
          TEXT => "$lang{ACCIDENT_FIXED}"
        });
        $count++;
      }
    }

    $Accident->accident_equipment_chg({
      ID         => $equipment->{id},
      SENT_CLOSE => $count,
    });
  }

  return 1;
}


#**********************************************************
=head2 accident_warning($attr) - Send warning to telegram or viber or push

 Arguments:
    $attr
      UID
      TEXT

=cut
#**********************************************************
sub accident_send_warning {
  my ($attr) = @_;

  my $message = $lang{WARNING} . " \n";
  $message .= $attr->{TEXT};

  for my $sender_type (@sender_types) {
    my $response = $Sender->send_message({
    SENDER_TYPE => $sender_type,
    UID         => $attr->{UID},
    TITLE       => $lang{WARNING},
    SUBJECT     => $lang{ACCIDENT_NOTIFICATION},
    MESSAGE     => $message,
  });

    last if $response;
  }

  return 1;
}

#**********************************************************

=head2 _search_address()

  Atributes:
    $attr
      type_id
      address_id

  Returns:
    location_info

=cut

#**********************************************************
sub _search_address {
  my ($type_id, $address_id) = @_;

  my %location_info = ();

  return \%location_info unless ($type_id && $address_id);

  if ($type_id == 1) {
    $location_info{DISTRICT} = $address_id;
    $location_info{TYPE_ID} = 1;
  }
  elsif ($type_id == 2) {
    $location_info{CITY} = $address_id;
    $location_info{TYPE_ID} = 2;
  }
  elsif ($type_id == 3) {
    $location_info{STREET} = $address_id;
    $location_info{TYPE_ID} = 3;
  }
  elsif ($type_id == 4) {
    $location_info{BUILD} = $address_id;
    $location_info{TYPE_ID} = 4;
  }

  return \%location_info;
}


1;
