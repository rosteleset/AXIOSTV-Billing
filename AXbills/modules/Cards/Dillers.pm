=head NAME

  Dillers interface

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array mk_unique_value sendmail);
use Cards;
use Tariffs;
use Users;

our (
  $db,
  %conf,
  $admin,
  %lang,
  $html,
  %permissions,
  @MONTHES,
  @WEEKDAYS
);

my $Diller = Dillers->new($db, $admin, \%conf);
my $Cards = Cards->new($db, $admin, \%conf);
$Cards->{INTERNET} = 1;
my $Tariffs = Tariffs->new($db, \%conf, $admin);

my @status = ($lang{ENABLE}, $lang{DISABLE}, $lang{USED}, $lang{DELETED}, $lang{RETURNED}, $lang{PROCESSING});

my @type_operation = ($lang{COMING}, $lang{CARE});

my @type_fees = ($lang{CASH}, $lang{BANK}, $lang{EXTERNAL_PAYMENTS}, 'Credit Card', $lang{BONUS}, $lang{CORRECTION},
  $lang{COMPENSATION}, $lang{MONEY_TRANSFER}, $lang{RECALCULATE});

#**********************************************************
=head2 cards_diller()

=cut
#**********************************************************
sub cards_diller {
  $Diller->{ACTION} = 'add';
  $Diller->{LNG_ACTION} = $lang{ADD};

  my $uid = $FORM{UID} || 0;

  if ($FORM{change_permits}) {
    $Diller->diller_permissions_set({ %FORM });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, $lang{ADDED});
    }
  }
  elsif (!$FORM{SERIA}) {
    if ($FORM{add}) {
      $Diller->diller_add({ %FORM });
      if (!$Diller->{errno}) {
        $html->message('info', $lang{INFO}, $lang{ADDED});
      }
      delete($FORM{add});
    }
    elsif ($FORM{change}) {
      $Diller->diller_change({ %FORM });
      if (!$Diller->{errno}) {
        $html->message('info', $lang{INFO}, $lang{CHANGED});
      }
      delete($FORM{change});
    }
    elsif ($FORM{del} && $FORM{COMMENTS}) {
      $Diller->diller_del({
        UID       => $uid,
        DILELR_ID => $FORM{DILLER_ID}
      });

      if (!$Diller->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{DELETED}");
      }
      return 0;
    }
  }

  _error_show($Diller);

  $Diller->diller_info(\%FORM);
  my $diller_id = 0;

  if ($Diller->{TOTAL} > 0) {
    $Diller->{ACTION} = 'change';
    $Diller->{LNG_ACTION} = $lang{CHANGE};
    $diller_id = $Diller->{ID};
    $pages_qs = "&UID=$uid&DILLER_ID=$Diller->{ID}";
    $LIST_PARAMS{DILLER_ID} = $Diller->{ID};
    cards_main();
  }

  $Diller->{TARIF_PLAN_SEL} = $html->form_select(
    'TP_ID',
    {
      SELECTED       => $Diller->{TP_ID} || 0,
      SEL_LIST       => $Diller->dillers_tp_list({ COLS_NAME => 1 }),
      NO_ID          => 1,
      MAIN_MENU      => get_function_index('cards_dillers_tp'),
      MAIN_MENU_ARGV => ($Diller->{TP_ID}) ? "chg=$Diller->{TP_ID}" : ''
    }
  );

  if ($permissions{0} && $permissions{0}{14} && $Diller->{ID}) {
    $Diller->{DEL_BUTTON} = $html->button($lang{DEL}, "index=$index&del=1&UID=$uid&ID=$diller_id",
      {
        MESSAGE => "$lang{DEL} $lang{SERVICE} Internet $lang{FOR} $lang{USER} $uid?",
        class   => 'btn btn-danger float-right'
      });
  }

  $Diller->{DISABLE} = ($Diller->{DISABLE} && $Diller->{DISABLE} == 1) ? 'checked' : '';

  $html->tpl_show(_include('cards_dillers', 'Cards'), { %$Diller, ID => $diller_id });

  if (in_array('Multidoms', \@MODULES) && $LIST_PARAMS{DILLER_ID}) {
    my %ACTIONS = (
      $lang{ICARDS}      => 1,
      $lang{TARIF_PLANS} => 2,
      $lang{NAS}         => 3,
      $lang{DILLERS}     => 4,
      $lang{TEMPLATES}   => 5,
      $lang{REPORTS}     => 6,
      $lang{FINANCES}    => 7
    );

    my $permits = $Diller->diller_permissions_list({ %FORM, DILLER_ID => $LIST_PARAMS{DILLER_ID} });

    my $table = $html->table(
      {
        width   => '400',
        caption => $lang{PERMISSION},
        title   => [ $lang{ACTION}, $lang{COMMENTS}, '-' ],
      }
    );

    foreach my $key (sort keys %ACTIONS) {
      $table->addrow(
        $key, '',
        $html->form_input(
          'PERMITS',
          $ACTIONS{$key},
          {
            TYPE  => 'checkbox',
            STATE => ($permits->{ $ACTIONS{$key} }) ? 'checked' : undef
          }
        )
      );
    }

    print $html->form_main(
      {
        CONTENT => $table->show(),
        HIDDEN  => {
          index     => $index,
          DILLER_ID => $LIST_PARAMS{DILLER_ID},
          UID       => $uid
        },
        SUBMIT  => { change_permits => $lang{CHANGE} },
      }
    );
  }

  return 1;
}

#**********************************************************
=head2 diller_add($attr)

=cut
#**********************************************************
sub diller_add {
  my ($attr) = @_;

  $Diller->{ACTION} = 'add';
  $Diller->{LNG_ACTION} = $lang{ADD};
  $FORM{EXPORT} = '' if (!$FORM{EXPORT});
  my $EXPIRE_DATE = q{};

  if (!$FORM{SUM}) {
    $FORM{SUM} = $FORM{SUM_NEW};
  }

  if ($FORM{add}) {
    if (!$FORM{TYPE} && defined($FORM{SUM}) && $FORM{SUM} <= 0) {
      if ($FORM{EXPORT} && $FORM{EXPORT} eq 'cards_server') {
        return { ERROR => 'ERR_WRONG_SUM' };
      }
      else {
        print $html->header();
        $html->message('err', $lang{ERROR}, "$lang{SUM}: $FORM{SUM} \n $lang{ERR_WRONG_SUM}", { ID => 673 });
        print $html->{OUTPUT};
      }
      exit;
    }

    my $fees = Finance->fees($db, $admin, \%conf);

    if ($FORM{EXPORT}) {
      if ($FORM{EXPORT} eq 'xml') {
        print "Content-Type: text/xml; filename=\"cards_$DATE.xml\"\n" . "Content-Disposition: attachment; filename=\"cards_$DATE.xml\"; size=" . "\n\n";
        print "<?xml version=\"1.0\" encoding=\"$html->{CHARSET}\"?>\n";
      }
      elsif ($FORM{EXPORT} eq 'text') {
        print "Content-Type: text/plain; filename=\"cards_$DATE.csv\"\n" . "Content-Disposition: attachment; filename=\"cards_$DATE.csv\"; size=" . "\n\n";
      }
    }
    else {
      print $html->header();
    }

    if ($COOKIES{OP_SID} && $FORM{OP_SID} && $FORM{OP_SID} eq $COOKIES{OP_SID}) {
      if ($FORM{EXPORT} eq 'cards_server') {
        return { ERROR => 'EXIST' };
      }

      $html->message('err', $lang{ERROR}, "$lang{EXIST}");
      print "$lang{ICARDS} $lang{EXIST} Error id: 674 ($FORM{OP_SID} // $COOKIES{OP_SID})";
      exit;
    }

    my $list = $Cards->cards_list(
      {
        SERIAL    => $conf{CARDS_DILLER_SERIAL} || '',
        NUMBER    => '_SHOW',
        PAGE_ROWS => 1,
        SORT      => 2,
        DESC      => 'DESC',
        COLS_NAME => 1,
      }
    );
    my $serial = 0;
    my $count = $FORM{COUNT} || 1;

    if ($Diller->{TOTAL} > 0) {
      $serial = $list->[0]->{number};
    }

    $serial++;

    if ($FORM{CARDS_PAYMENT_PIN_LENGTH}) {
      $FORM{CARDS_PAYMENT_PIN_LENGTH} = $conf{CARDS_PAYMENT_PIN_LENGTH} || 8;
    }

    #Get duiller TP info Take fees
    my $sum = 0;
    if ($Diller->{PERCENTAGE} && $Diller->{PERCENTAGE} > 0) {
    }
    else {
      $Diller->dillers_tp_info({ ID => $Diller->{TP_ID} });

      if ($Diller->{TOTAL} > 0) {
        if ($Diller->{PERCENTAGE} > 0) {
          $sum = $FORM{SUM} - ($FORM{SUM} / 100 * (100 - (100 - $Diller->{PERCENTAGE})));
        }

        if ($Diller->{OPERATION_PAYMENT} > 0) {
          $sum += $Diller->{OPERATION_PAYMENT};
        }
      }
      else {
        $sum = $FORM{SUM};
      }
    }

    my @CARDS_OUTPUT = ();
    my $diller = $Diller;
    #Import from other systems
    if ($FORM{import}) {
    }
    else {
      if ($FORM{TYPE} && !$FORM{TP_ID}) {
        $html->message('err', "$lang{INFO}", "$lang{ERR_SELECT_TARIF_PLAN}");
      }
      elsif ($FORM{TYPE}) {
        load_module('Dv', $html);
        $FORM{add} = 1;
        $FORM{create} = 1;
        if (!$FORM{BEGIN}) {
          $list = $users->list(
            {
              PAGE_ROWS => 1,
              SORT      => 8,
              DESC      => 'DESC',
              COLS_NAME => 1
            }
          );
          $FORM{BEGIN} = $list->[0]->{uid};
          $FORM{LOGIN_BEGIN} = $list->[0]->{uid};
        }

        my $return = cards_users_add(
          {
            #EXTRA_TPL => $dv_tpl,
            NO_PRINT => 1
          }
        );

        my $added_count = 0;

        if (ref($return) eq 'ARRAY') {
          foreach my $line (@$return) {
            $FORM{'1.LOGIN'} = $line->{LOGIN};
            $FORM{'1.PASSWORD'} = $line->{PASSWORD};
            $FORM{'1.CREATE_BILL'} = 1;
            $FORM{'4.TP_ID'} = $FORM{TP_ID};
            $line->{UID} = dv_wizard_user({ SHORT_REPORT => 1 });

            if ($line->{UID} < 1) {
              $html->message('err', "$lang{ERROR}", "$lang{LOGIN}: '$line->{LOGIN}'");
              last if (!$line->{SKIP_ERRORS});
            }
            else {

              #Confim card creation
              $added_count++;
              $line->{NUMBER} = sprintf("%.11d", $line->{NUMBER});
              push @CARDS_OUTPUT,
                {
                  #PIN         => $pin,
                  LOGIN       => $FORM{'1.LOGIN'},
                  PASSWORD    => $FORM{'1.PASSWORD'},
                  PIN         => $FORM{'1.PASSWORD'},
                  NUMBER      => $line->{NUMBER},
                  SERIA       => $line->{SERIA},
                  EXPIRE_DATE => ($EXPIRE_DATE ne '0000-00-00') ? $EXPIRE_DATE : '',
                  DATE        => "$DATE $TIME",
                  SUM         => sprintf("%.2f", $FORM{SUM}),
                  DILLER_ID   => $Diller->{ID},
                  TARIF_PLAN  => $FORM{TP_ID}
                };

              #If prepaid or postpaid service
              if ($Diller->{PAYMENT_TYPE} < 2) {
                if ($Diller->{PERCENTAGE} > 0) {
                  $sum = $FORM{SUM} - ($FORM{SUM} / 100 * (100 - (100 - $Diller->{PERCENTAGE})));
                }
                if ($sum > 0) {
                  $fees->take(
                    $user, $sum,
                    {
                      DESCRIBE     => "$lang{ICARDS} $line->{SERIA}$line->{NUMBER}",
                      METHOD       => 0,
                      EXT_ID       => "$Diller->{SERIAL}$line->{NUMBER}",
                      CHECK_EXT_ID => "$Diller->{SERIAL}$line->{NUMBER}"
                    }
                  );

                  _error_show($fees);
                }
              }

              if (cards_users_gen_confim({ %$line, SUM => ($FORM{'5.SUM'}) ? $FORM{'5.SUM'} : 0 }) == 0) {
                return 0;
              }
            }
          }
        }
      }
      else {
        for (my $i = $serial; $i < $serial + $count; $i++) {
          if ($FORM{TYPE}) {
            #my $password = mk_unique_value($FORM{PASSWD_LENGTH}, { SYMBOLS => $FORM{PASSWD_SYMBOLS} || $conf{PASSWD_SYMBOLS} || undef });
          }

          my $pin = mk_unique_value($FORM{CARDS_PAYMENT_PIN_LENGTH}, { SYMBOLS => $conf{CARDS_PIN_SYMBOLS} || '1234567890' });
          $EXPIRE_DATE = '0000-00-00';
          my $card_number = sprintf("%.11d", $i);

          $Cards->cards_add(
            {
              SERIAL    => $conf{CARDS_DILLER_SERIAL} || '',
              NUMBER    => $card_number,
              PIN       => $pin,
              SUM       => $FORM{SUM},
              STATUS    => 0,
              EXPIRE    => $EXPIRE_DATE,
              DILLER_ID => $diller->{ID}
            }
          );

          if ($Diller->{errno}) {
            if ($FORM{EXPORT} eq 'cards_server') {
              return { ERROR => 'CARDS_GENERATION_ERROR' };
            }

            _error_show($Diller);
            return 0;
          }
          else {
            if ($Diller->{PAYMENT_TYPE} < 2) {
              if ($diller->{PERCENTAGE} > 0) {
                $sum = $FORM{SUM} - ($FORM{SUM} / 100 * (100 - (100 - $diller->{PERCENTAGE})));
              }
              my $serial_id = $Diller->{SERIAL} || q{};
              $fees->take(
                $user, $sum,
                {
                  DESCRIBE     => "$lang{ICARDS} $serial_id$i",
                  METHOD       => 0,
                  EXT_ID       => "$serial_id$i",
                  CHECK_EXT_ID => "$serial_id$i"
                }
              );
            }

            push @CARDS_OUTPUT,
              {
                LOGIN       => $diller->{FIO} || '-',
                SERIA       => $conf{CARDS_DILLER_SERIAL} || '-',
                PIN         => $pin,
                NUMBER      => $card_number,
                EXPIRE_DATE => ($EXPIRE_DATE ne '0000-00-00') ? $EXPIRE_DATE : '',
                DATE        => "$DATE $TIME",
                SUM         => sprintf("%.2f", $FORM{SUM}),
                DILLER_ID   => $diller->{ID}
              };
          }
        }
      }
    }

    #Show cards
    if ($FORM{EXPORT} eq 'xml') {
      print "<CARDS>";
      foreach my $card_info (@CARDS_OUTPUT) {
        print "<CARD>
          <LOGIN>$card_info->{PIN}</LOGIN>
          <PIN>$card_info->{PIN}</PIN>
          <NUMBER>$card_info->{NUMBER}</NUMBER>
          <EXPIRE_DATE>$card_info->{EXPIRE_DATE}</EXPIRE_DATE>
          <CREATED_DATE>$card_info->{DATE}</CREATED_DATE>
          <SUM>$card_info->{SUM}</SUM>
          <DILLER_ID>$card_info->{DILLER_ID}</DILLER_ID></CARD>\n";
      }
      print "</CARDS>";
    }
    elsif ($FORM{EXPORT} eq 'text') {
      foreach my $card_info (@CARDS_OUTPUT) {
        print "$card_info->{LOGIN}\t$card_info->{PIN}\t$card_info->{NUMBER}\t$card_info->{EXPIRE_DATE}\t$card_info->{DATE}\t$card_info->{SUM}\t$card_info->{DILLER_ID}\n";
      }
    }
    elsif ($FORM{EXPORT} eq 'order_print') {
      my $content = "Print Cards\n";
      foreach my $card_info (@CARDS_OUTPUT) {
        $content .= "$card_info->{PIN}\t$card_info->{NUMBER}\t$card_info->{EXPIRE_DATE}\t$card_info->{DATE}\t$card_info->{SUM}\t$card_info->{DILLER_ID}\n";
      }
      sendmail("$user->{FROM}", "$conf{ADMIN_MAIL}", "Cards Print", "$content", "$conf{MAIL_CHARSET}");
      $html->message('info', "$lang{INFO}", "$lang{SENDED} $lang{ORDER_PRINT}");
    }
    elsif ($FORM{EXPORT} eq 'cards_server') {
      foreach my $card_info (@CARDS_OUTPUT) {
        return {
          LOGIN       => $card_info->{LOGIN},
          PIN         => $card_info->{PIN},
          NUMBER      => $card_info->{NUMBER},
          EXPIRE_DATE => $card_info->{EXPIRE_DATE},
          DATE        => $card_info->{DATE},
          SUM         => $card_info->{SUM},
          DILLER_ID   => $card_info->{DILLER_ID}
        };
      }
    }
    else {
      foreach my $card_info (@CARDS_OUTPUT) {
        $html->tpl_show(_include('cards_check', 'Cards'), $card_info);
      }
    }

    return 1;
  }

  $Diller->{OP_SID} = mk_unique_value(16);

  if ($attr->{RESELLER}) {
    $Diller->{TYPE_SEL} = $html->form_select(
      'TYPE',
      {
        SELECTED     => $FORM{TYPE},
        SEL_ARRAY    => [ $lang{PAYMENTS}, "$lang{SERVICES} ($lang{LOGIN} + $lang{PASSWD})" ],
        ARRAY_NUM_ID => 1,
        EX_PARAMS    => 'onchange=\'samechanged(this)\''
      }
    );

    $Diller->{TP_SEL} = $html->form_select(
      'TP_ID',
      {
        SELECTED  => $FORM{TP_ID},
        SEL_LIST  => $Tariffs->list(
          {
            PAGE_ROWS => 1,
            SORT      => 1,
            DESC      => 'desc',
            DOMAIN_ID => $user->{DOMAIN_ID},
            COLS_NAME => 1
          }),
        EX_PARAMS => '', #'STYLE=\'background-color: #dddddd\' name=\'TP_ID\'',
        NO_ID     => 1
      }
    );

    $html->tpl_show(
      _include('cards_reseller_cod_gen', 'Cards'),
      {
        COUNT => 1,
        SUM   => 0.00,
        %$Diller
      },
      { ID => 'CARD_GEN' }
    );
  }
  else {
    $html->tpl_show(_include('cards_dillers_cod_gen', 'Cards'), {
      COUNT      => 1,
      SUM        => 0.00,
      EXPIRE_DATE => $DATE,
      %$Diller
    }, { ID => 'CARD_GEN' });
  }

  return 0;
}

#**********************************************************
=head2 dillers_list()

=cut
#**********************************************************
sub dillers_list {

  my $list = $Diller->dillers_list({ %LIST_PARAMS });
  my $table = $html->table(
    {
      width   => '100%',
      caption => "$lang{DILLERS}",
      title   => [ 'ID', "$lang{LOGIN}", "$lang{NAME}", "$lang{ADDRESS}", "E-Mail", "$lang{REGISTRATION}", "$lang{PERCENTAGE}", "$lang{STATE}", "$lang{COUNT}", "$lang{ENABLE}" ],
      qs      => $pages_qs,
      pages   => $Diller->{TOTAL},
      ID      => 'CARDS_DILLERS'
    }
  );

  foreach my $line (@$list) {
    $table->addrow($line->[0],
      $html->button($line->[1], "index=15&UID=$line->[10]&MODULE=Cards"),
      $line->[2],
      $line->[3],
      $line->[4],
      $line->[5],
      $line->[6],
      $status[ $line->[7] ],
      $line->[8],
      $line->[9]
    );
  }

  print $table->show();

  $table = $html->table(
    {
      width => '100%',
      rows  => [ [ "$lang{TOTAL}:", $html->b($Diller->{TOTAL}) ] ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 cards_dillers_tp($attr)

=cut
#**********************************************************
sub cards_dillers_tp {

  $Diller->{LNG_ACTION} = $lang{ADD};
  $Diller->{ACTION} = 'add';

  my @payment_types = ($lang{PREPAID}, $lang{POSTPAID}, $lang{ACTIVATION_PAYMENTS});

  if ($FORM{add}) {
    $Diller->dillers_tp_add({ %FORM });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Diller->dillers_tp_change({ %FORM });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{chg}) {
    $Diller->dillers_tp_info({ ID => $FORM{chg} });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, $lang{CHANGING});
    }

    $FORM{add_form} = 1;
    $Diller->{ACTION} = 'change';
    $Diller->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Diller->dillers_tp_del({ ID => $FORM{del} });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }

  _error_show($Diller);

  $Diller->{PAYMENT_TYPE_SEL} = $html->form_select(
    'PAYMENT_TYPE',
    {
      SELECTED     => $Diller->{PAYMENT_TYPE},
      SEL_ARRAY    => \@payment_types,
      ARRAY_NUM_ID => 1
    }
  );

  $Diller->{NAS_TP} = ($Diller->{NAS_TP}) ? 'checked' : '';
  if ($FORM{add_form}) {
    $html->tpl_show(_include('cards_dillers_tp', 'Cards'), $Diller);
  }

  my $list = $Diller->dillers_tp_list({ %LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table(
    {
      width   => '100%',
      caption => $lang{TARIF_PLANS},
      border  => 1,
      title   => [ $lang{NAME}, $lang{PERCENTAGE}, $lang{OPERATION_PAYMENT}, $lang{PAYMENT_TYPE}, '-' ],
      ID      => 'DILLERS_TARIF_PLANS',
      MENU    => "$lang{ADD}:index=$index&add_form=1:add;"
    }
  );

  my ($delete, $change);
  foreach my $line (@$list) {
    if ($permissions{4}{1}) {
      $delete = $html->button($lang{DEL}, "index=$index&del=$line->{id}", { MESSAGE => "$lang{DEL} $line->{name}?", class => 'del' });
      $change = $html->button($lang{CHANGE}, "index=$index&chg=$line->{id}", { class => 'change' });
    }

    if ($FORM{chg} && $FORM{chg} eq $line->{id}) {
      $table->{rowcolor} = 'bg-success';
    }
    else {
      delete($table->{rowcolor});
    }

    $table->addrow($html->button($line->{name}, "index=$index&TP_ID=$line->{id}"),
      $line->{percentage},
      $line->{operation_payment},
      $payment_types[ $line->{payment_type} ],
      $change . $delete);
  }

  print $table->show();

  $table = $html->table(
    {
      width => '100%',
      rows  => [ [ "$lang{TOTAL}:", $html->b($Tariffs->{TOTAL}) ] ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 cards_diller_stats()

=cut
#**********************************************************
sub cards_diller_stats {

  %LIST_PARAMS = ();
  my $diller = $Diller;
  $LIST_PARAMS{DILLER_ID} = $diller->{ID};

  $FORM{PAGE_ROWS} = $FORM{rows} if ($FORM{rows});

  if ($FORM{print}) {
    $LIST_PARAMS{CREATED_DATE} = $FORM{print};
    print "Content-Type: text/html\n\n";

    my $list = $Cards->cards_list({
      COUNT     => '_SHOW',
      SUM       => '_SHOW',
      %LIST_PARAMS,
      PAGE_ROWS => 1000000,
      COLS_NAME => 1,
    });

    my $total_count = 0;
    my $total_sum = 0;

    foreach my $line (@$list) {
      $total_count += $line->{cards_count};
      $total_sum += $line->{sum};
    }

    $html->tpl_show(
      _include('cards_diller_sum_check', 'Cards'),
      {
        DATE        => "$DATE $TIME",
        TOTAL_COUNT => $total_count,
        TOTAL_SUM   => sprintf("%.2f", $total_sum),
        DILLER_ID   => $diller->{ID},
        DETAILS     => undef
      }
    );
    return 0;
  }
  elsif ($FORM{print_cards}) {
    cards_print();
    exit;
  }

  my $datepicker = $html->form_daterangepicker({
    NAME      => 'CREATED_FROM_DATE/CREATED_TO_DATE',
    FORM_NAME => 'report_panel',
    VALUE     => $FORM{'FROM_DATE_TO_DATE'},
  });

  $html->tpl_show(_include('cards_dillers_histori', 'Cards'), {
    INDEX         => get_function_index('cards_diller_stats'),
    STATUS_SELECT => $html->form_select(
      'STATUS',
      {
        SELECTED => $FORM{STATUS} || 0,
        SEL_HASH => {
          0  => $lang{ALL},
          1  => $lang{ENABLE},
          2  => $lang{USED}
        },
        SORT_KEY => 1,
        NO_ID    => 1
      }, { class => 'form-control' }),
    CARD_SELECT   => $html->form_select(
      'TYPE',
      {
        SELECTED => $FORM{TYPE},
        SEL_HASH => {
          CARDS => $lang{ICARDS},
          DAYS  => $lang{DAYS}
        },
        SORT_KEY => 1,
        NO_ID    => 1
      }
    ),
    DATA_PICER    => $datepicker,
    PAGE_ROWS     => $FORM{PAGE_ROWS},
    ROWS          => 25
  });

  my $table = $html->table();

  $LIST_PARAMS{LOGIN} = undef;

  my @pin = ();
  @pin = ("PIN") if ($conf{CARDS_SHOW_PINS});

  if ($FORM{ID}) {
    $FORM{ID} =~ s/, /;/g;
    $LIST_PARAMS{ID} = $FORM{ID};
  }
  elsif ($FORM{CREATED_FROM_DATE} && $FORM{CREATED_TO_DATE}) {
    $pages_qs = "&CREATED_TO_DATE=$FORM{CREATED_TO_DATE}&CREATED_FROM_DATE=$FORM{CREATED_FROM_DATE}";
    $LIST_PARAMS{CREATED_FROM_DATE} = $FORM{CREATED_FROM_DATE};
    $LIST_PARAMS{CREATED_TO_DATE} = $FORM{CREATED_TO_DATE};
    $LIST_PARAMS{PAGE_ROWS} = $FORM{rows};
  }
  else {
    my ($Y, $M) = split(/-/, $DATE);
    $LIST_PARAMS{CREATED_MONTH} = "$Y-$M";
    $pages_qs = "&CREATED_MONTH=$Y-$M";
  }

  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  if (defined($FORM{STATUS}) && $FORM{STATUS} ne '') {
    $LIST_PARAMS{STATUS} = $FORM{STATUS};
    $pages_qs .= "&STATUS=$FORM{STATUS}";
  }

  #Group by TP
  if ($FORM{TYPE} && $FORM{TYPE} eq 'TP') {
    $pages_qs .= "&TYPE=TP&PAGE_ROWS=$PAGE_ROWS";

    if ($FORM{CREATED_DATE}) {
      $LIST_PARAMS{CREATED_DATE} = "$FORM{CREATED_DATE}";
      $pages_qs .= "&CREATED_DATE=$LIST_PARAMS{CREATED_DATE}";
    }

    if ($FORM{TP_ID}) {
      $LIST_PARAMS{TP_ID} = $FORM{TP_ID};
      $pages_qs .= "&TP_ID=$FORM{TP_ID}";
    }

    $LIST_PARAMS{TYPE} = 'TP';

    if ($FORM{print_cards}) {
      cards_print();
      exit;
    }

    my @caption = ("$lang{DATE}", "$lang{TARIF_PLAN}", "$lang{COUNT}", "$lang{SUM}", "-");
    %LIST_PARAMS = (DATE => '_SHOW',
      TP_ID              => '_SHOW',
      COUNT              => '_SHOW',
      SUM                => '_SHOW',
      %LIST_PARAMS
    );

    if ($FORM{TP_ID}) {
      @caption = ("$lang{NUM}", "$lang{LOGIN}", "$lang{PASSWD}", "$lang{TARIF_PLAN}", "$lang{USED} $lang{DATE}");
      %LIST_PARAMS = (NUMBER => '_SHOW',
        LOGIN                => '_SHOW',
        PIN                  => '_SHOW',
        TP_ID                => '_SHOW',
        USED                 => '_SHOW',
        %LIST_PARAMS
      );
    }

    my $list = $Cards->cards_list({
      %LIST_PARAMS,
      COLS_NAME => 1,
    });

    $table = $html->table(
      {
        width   => '100%',
        caption => $lang{LOG},
        title   => \@caption,
        qs      => $pages_qs,
        pages   => $Diller->{TOTAL},
        ID      => 'CARDS_LIST'
      }
    );

    my @rows = ();
    foreach my $line (@$list) {
      my $tp_id = $line->{tp_id} || 0;
      if ($FORM{TP_ID}) {
        @rows = ($line->{number},
          $line->{login},
          $line->{pin},
          $line->{tp_name},
          $line->{used}
        );
      }
      else {
        @rows = (
          $html->button($line->{date}, "&index=$index&CREATED_DATE=" .
            ($LIST_PARAMS{CREATED_DATE} || q{})
            . "&PAGE_ROWS=" . ($LIST_PARAMS{PAGE_ROWS} || 25)
            . (($tp_id > 0) ? "&TYPE=TP&TP_ID=$tp_id" : '&TYPE=CARDS&PAYMENTS=1')),
          (!$line->{count}) ? $lang{PAYMENTS} : $html->button($line->{tp_name}, "&index=$index$pages_qs&TP_ID=$tp_id"),
          $line->{count},
          sprintf('%.2f', $line->{sum})
        );
      }

      $table->addrow(@rows);
    }

    print $table->show();

    my $total_cards = $Cards->{list}[0]{count} || 0;
    my $total_sum = $Cards->{list}[0]{sum} || 0;
    $table = $html->table(
      {
        width => '100%',
        rows  => [ [ "$lang{TOTAL}:", $html->b($total_cards), "$lang{SUM}:", $html->b(sprintf('%.2f', $total_sum)) ] ]
      }
    );
    print $table->show();
  }
  elsif ($FORM{TYPE} && $FORM{TYPE} eq 'CARDS') {
    if (!$FORM{sort}) {
      $LIST_PARAMS{SORT} = 1;
      $LIST_PARAMS{DESC} = 'DESC';
    }

    $pages_qs .= "&TYPE=CARDS&PAGE_ROWS=$FORM{PAGE_ROWS}";

    if ($FORM{CREATED_DATE}) {
      $LIST_PARAMS{CREATED_DATE} = "$FORM{CREATED_DATE}";
      $pages_qs .= "&CREATED_DATE=$LIST_PARAMS{CREATED_DATE}";
    }

    if ($FORM{PAYMENTS}) {
      $LIST_PARAMS{PAYMENTS} = 1;
      $pages_qs .= "&PAYMENTS=1";
    }

    if ($FORM{print_cards}) {
      cards_print();
      exit;
    }

    my $list = $Cards->cards_list({ %LIST_PARAMS,
      SERIAL_DILLERS => $conf{CARDS_DILLER_SERIAL} || '',
      NUMBER         => '_SHOW',
      LOGIN          => '_SHOW',
      SUM            => '_SHOW',
      STATUS         => ($FORM{STATUS} && ($FORM{STATUS} == 1) ? 0 : ($FORM{STATUS} ? $FORM{STATUS} : '_SHOW')),
      EXPIRE         => '_SHOW',
      CREATED        => $FORM{CREATED_DATE} || '_SHOW',
      UID            => '_SHOW',
      PAGE_ROWS      => $FORM{PAGE_ROWS} || 25,
      COLS_NAME      => 1,
      NO_GROUP       => 1
    });

    $table = $html->table(
      {
        width   => '100%',
        caption => $lang{LOG},
        title   => [ $lang{SERIAL}, $lang{NUM}, $lang{LOGIN}, $lang{SUM}, $lang{STATUS}, $lang{EXPIRE}, $lang{ADDED} ],
        qs      => $pages_qs,
        pages   => $Cards->{TOTAL},
        ID      => 'CARDS_LIST',
      }
    );

    my $count_cards = $Cards->{TOTAL_CARDS} || 0;
    my $sum_cards = $Cards->{TOTAL_SUM} || 0;

    require Users;
    Users->import();
    my $Users = Users->new($db, $admin, \%conf);

    my $user_list = $Users->list({
      UID       => '_SHOW',
      COLS_NAME => 1
    });

    foreach my $line (@$list) {
      my $user_login = '';
      foreach my $element (@$user_list) {
        if ($element->{uid} == $line->{uid}) {
          $user_login = $element->{login};
        }
      }
      @pin = ($line->{pin}) if ($conf{CARDS_SHOW_PINS});
      $table->addrow(
        $html->form_input("ID", "$line->{id}", { TYPE => 'checkbox', OUTPUT2RETURN => 1 }) . $line->{serial},
        $line->{number},
        $user_login,
        sprintf('%.2f', $line->{sum}),
        $html->color_mark($line->{status} != 2 ? $lang{ENABLE} : $lang{USED},
          ($line->{status} != 2) ? 'text-primary' : 'text-warning'),
        $line->{expire},
        $line->{created}
      );
    }

    my @button_footer = (
      $html->button("$lang{PRINT} PDF", "qindex=$index&pdf=1&print_cards=1&$pages_qs", {
        ex_params => 'target=_new',
        class     => 'btn btn-primary float-right col-md-12 col-sm-12' }),
      $html->button('CSV', "qindex=$index&csv=1&print_cards=1&$pages_qs", {
        ex_params => 'target=_new',
        class     => 'btn btn-primary float-right col-md-12 col-sm-12' })
    );

    $table->addfooter(@button_footer);

    my %hidden_params = ();
    my @p = split(/&/, $pages_qs);
    foreach my $l (@p) {
      my ($k, $v) = split(/=/, $l, 2);
      $hidden_params{$k} = $v if ($k);
    }

    print $html->form_main(
      {
        CONTENT =>
          $table->show({ OUTPUT2RETURN => 1 }),
        #ENCTYPE => 'multipart/form-data',
        HIDDEN  => { qindex => $index,
          print_cards       => 1,
          %hidden_params
        },
      }
    );

    $table = $html->table(
      {
        width => '100%',
        rows  => [ [ "$lang{TOTAL}:", $html->b($count_cards), "$lang{SUM}:", $html->b(sprintf('%.2f', $sum_cards)) ] ]
      }
    );
    print $table->show();
  }
  else {
    $table = $html->table(
      {
        width   => '100%',
        caption => $lang{LOG},
        title   => [ $lang{DATE}, $lang{COUNT}, $lang{SUM}, '-' ],
        qs      => $pages_qs,
        pages   => $Diller->{TOTAL},
        ID      => 'CARDS_REPORTS_DAYS'
      }
    );

    if ($LIST_PARAMS{STATUS} && $LIST_PARAMS{STATUS} eq '2') {
      ++$LIST_PARAMS{STATUS};
    }

    my $list = $Cards->cards_report_days({
      %LIST_PARAMS,
      SERIA     => '',
      COLS_NAME => 1
    });

    foreach my $line (@$list) {
      $table->addrow(
        $html->button($line->{date}, "index=$index&TYPE=TP$pages_qs&sid=$sid" . (($line->{date} =~ /(\d{4}-\d{2}-\d{2})/) ? "&CREATED_DATE=$1" : '')),
        $line->{count},
        sprintf('%.2f', $line->{sum}),
        $html->button(
          "$lang{PRINT} $lang{SUM}",
          '#',
          {
            NEW_WINDOW      => "$SELF_URL?qindex=$index&print=$line->{date}&sid=$sid",
            NEW_WINDOW_SIZE => "480:640",
            class           => 'print'
          }
        ),
      );
    }

    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 cards_dillers() - Cards diller interface

=cut
#**********************************************************
sub cards_dillers {

  $Diller->{ACTION} = 'add';
  $Diller->{LNG_ACTION} = $lang{ADD};

  if ($FORM{info}) {
    $pages_qs = "&info=$FORM{info}";
    $LIST_PARAMS{DILLER_ID} = $FORM{info};

    $Diller = $Diller->diller_info({ ID => $FORM{info} });
    $html->tpl_show(_include('cards_diller_info', 'Cards'), $Diller);
    cards_main();
    return 0;
  }
  elsif ($FORM{add}) {
    $Diller->diller_add({ %FORM });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, $lang{ADDED});
    }
  }
  elsif ($FORM{change}) {
    $Diller->diller_change({ %FORM });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
    }
  }
  elsif ($FORM{chg}) {
    $Diller->diller_info({ ID => $FORM{chg} });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, $lang{CHANGING});
    }
    $Diller->{ACTION} = 'change';
    $Diller->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Diller->diller_del({ ID => $FORM{del} });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }

  _error_show($Diller);

  $Diller->{TARIF_PLAN_SEL} = $html->form_select(
    'TP_ID',
    {
      SELECTED => $Diller->{TP_ID},
      SEL_LIST => $Diller->dillers_tp_list({ COLS_NAME => 1 }),
    }
  );

  $Diller->{DISABLE} = ($Diller->{DISABLE} == 1) ? 'checked' : '';
  $html->tpl_show(_include('cards_dillers', 'Cards'), $Diller);

  my $list = $Diller->dillers_list({ %LIST_PARAMS });
  my $table = $html->table(
    {
      width   => '100%',
      caption => $lang{DILLERS},
      title   => [ 'ID', $lang{NAME}, $lang{ADDRESS}, "E-Mail", $lang{REGISTRATION}, $lang{PERCENTAGE}, $lang{STATE},
        $lang{COUNT}, $lang{ENABLE}, '-' ],
      qs      => $pages_qs,
      pages   => $Diller->{TOTAL},
      ID      => 'DILLER_LIST'
    }
  );

  foreach my $line (@$list) {
    $table->addrow(
      $line->[0],
      $line->[1],
      $line->[2],
      $line->[3],
      $line->[4],
      $line->[5],
      $status[ $line->[6] ],
      $line->[7],
      $line->[8],
      $html->button($lang{INFO}, "index=$index$pages_qs&info=$line->[0]", { class => 'show' })
        . $html->button($lang{CHANGE}, "index=$index$pages_qs&chg=$line->[0]", { class => 'change' })
        . $html->button($lang{DEL}, "index=$index$pages_qs&del=$line->[0]", { MESSAGE => "$lang{DEL} [$line->[0]] ?", class => 'del' })
    );
  }

  print $table->show();

  $table = $html->table(
    {
      width => '100%',
      rows  => [ [ "$lang{TOTAL}:", $html->b($Diller->{TOTAL}) ] ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 cards_reseller_face()

=cut
#**********************************************************
sub cards_reseller_face {
  #my ($attr) = @_;
  $Diller->diller_info({ UID => $user->{UID} });

  if ($Diller->{TOTAL} < 1) {
    $html->set_cookies('sid', "", "Fri, 1-Jan-2038 00:00:01");
    $html->header() if ($FORM{qindex});
    $html->message('info', $lang{INFO}, "$lang{ACCOUNT} $lang{NOT_EXIST}");
    return 0;
  }

  if ($user->{DEPOSIT} + $user->{CREDIT} > 0) {

    #Generate Cards
    if (diller_add({ RESELLER => 1 }) > 0) {
      return 0;
    }
  }
  else {
    print "Content-Type: text/html\n\n" if ($FORM{qindex});
    $html->message('info', $lang{INFO}, "$lang{ERR_SMALL_DEPOSIT}");
  }

  $Diller->{DISABLE} = $status[ $Diller->{DISABLE} ];
  $html->tpl_show(_include('cards_diller_info', 'Cards'), { %$Diller, %$user }, { ID => 'DILLER_INFO' });

  return 0;
}

#**********************************************************
=head2 cards_diller_face()

=cut
#**********************************************************
sub cards_diller_face {
  my ($attr) = @_;

  $users = $attr->{USER_INFO};
  $Diller->diller_info({ UID => $users->{UID} });

  if (!$Diller->{ID}) {
    $html->set_cookies('sid', "", "Fri, 1-Jan-2038 00:00:01");
    $html->header() if ($FORM{qindex});
    $html->message('info', $lang{DILLERS}, "$lang{ACCOUNT} $lang{NOT_EXIST}", { ID => 671 });
    return 0;
  }

  if (($users->{DEPOSIT} + $users->{CREDIT} > 0 && $Diller->{PAYMENT_TYPE} == 0) || $Diller->{PAYMENT_TYPE} > 0) {
    if (diller_add() > 0) {
      return 0;
    }
  }
  else {
    print "Content-Type: text/html\n\n" if ($FORM{qindex});
    $html->message('info', $lang{INFO}, "$lang{ERR_SMALL_DEPOSIT}", { ID => 672 });
  }

  $Diller->{DISABLE} = $status[ $Diller->{DISABLE} ];

  return 1;
}

#**********************************************************
=head2 cards_diller_search($attr)

   Argument:
    $attr:
      USER_INFO       - user information

   Return:
    -

=cut
#**********************************************************
sub cards_diller_search {
  my ($attr) = @_;

  require Users;
  Users->import();

  require Payments;
  Payments->import();

  my $Payments = Payments->new($db, $admin, \%conf);
  my $Users = Users->new($db, $admin, \%conf);

  my $contract_list = $Users->list({
    FIO         => '_SHOW',
    CONTRACT_ID => '_SHOW',
    COLS_NAME   => 1
  });

  my $name_tariff = $Tariffs->list({
    TP_GID    => $FORM{GID} || '_SHOW',
    COLS_NAME => 1
  });

  if ($FORM{diller_payment} && !$FORM{SUM}) {
    $html->message('err', $lang{ERROR}, $lang{EMPTY_FIELD});
  }

  if ($FORM{SUM}) {
    if (sprintf('%.2f', $attr->{USER_INFO}->{DEPOSIT}) >= sprintf('%.2f', $FORM{SUM})) {

      $Payments->add({ UID => $FORM{UID} }, {
        SUM          => $FORM{SUM},
        METHOD       => $FORM{TYPE_PAYMENT} || 0,
        DESCRIBE     => $FORM{COMMENTS} || $lang{DILLER_PAY},
        BILL_ID      => $attr->{USER_INFO}->{BILL_ID},
        EXT_ID       => 50,
        CHECK_EXT_ID => undef
      });

      my $fees = Finance->fees($db, $admin, \%conf);
      $fees->take(
        $attr->{USER_INFO}, $FORM{SUM},
        {
          DESCRIBE     => $FORM{COMMENTS} || $lang{DILLER_PAY},
          METHOD       => 4,
          BILL_ID      => $attr->{USER_INFO}->{DEPOSIT},
          EXT_ID       => undef,
          CHECK_EXT_ID => undef
        }
      );

      if (!_error_show($Payments)) {
        $html->message('success', $lang{SUCCESS}, $lang{PAYMENT_DATE} . " $DATE " . "$lang{USER} $FORM{LOGIN} (UID: $FORM{UID}) " .
          "$lang{SUM}: " . sprintf('%.2f', $FORM{SUM}));
      }
      else {
        $html->message('err', $lang{ERROR}, $lang{ERROR});
      }
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{ERR_SMALL_DEPOSIT});
    }
  }

  if (!$FORM{payment_diller}) {
    my $payments_list = $Payments->list({
      LOGIN             => '_SHOW',
      UID               => '_SHOW',
      SUM               => '_SHOW',
      DSC               => '_SHOW',
      DATETIME          => '_SHOW',
      AFTER_DEPOSIT     => '_SHOW',
      PAGE_ROWS         => 5,
      ADMIN_NAME        => '_SHOW',
      INNER_DESCRIBE    => '_SHOW',
      PAYMENT_METHOD_ID => '_SHOW',
      METHOD            => '_SHOW',
      COLS_NAME         => 1,
      EXT_ID            => 50
    });

    my $datepicker = $html->form_daterangepicker({
      NAME      => 'FROM_DATE/TO_DATE',
      FORM_NAME => 'report_panel',
      VALUE     => $DATE,
    });

    form_search({
      TPL =>
        $html->tpl_show(_include('cards_dillers_search', 'Cards'), {
          INDEX       => get_function_index('card_diller_search'),
          SID         => $main::sid,
          DATE_PICKER => $datepicker
        })
    });

    if (!$FORM{search_form} && !$FORM{diller_payment} && !$FORM{index}) {
      my $table = $html->table({
        width   => '100%',
        caption => $lang{LOG},
        title   => [ 'UID', $lang{LOGIN}, $lang{FIO}, $lang{PAYMENT_DATE},
          $lang{DESCRIBE}, $lang{DEPOSIT}, $lang{SUM},
          $lang{OPERATOR}, $lang{DOCUMENT}, $lang{TYPE_OPERATION}, $lang{COMMENTS},
          $lang{PAYMENT_TYPE} ],
        qs      => $pages_qs,
        ID      => 'DILLERS_OPERATION_LOG',
      });

      foreach my $payment (@$payments_list) {
        my $contract = '';
        my $user_fio = '';
        foreach my $contract_id (@$contract_list) {
          if ($contract_id->{login} eq $payment->{login}) {
            $contract = $contract_id->{contract_id};
            $user_fio = $contract_id->{fio};
          }
        }

        my $after_pay = _format_sum($payment->{after_deposit});
        my $sum_out = _format_sum($payment->{sum});

        $table->addrow(
          $payment->{uid},
          $payment->{login},
          $user_fio,
          $payment->{datetime},
          $payment->{dsc},
          $after_pay,
          $sum_out,
          $payment->{admin_name},
          $contract,
          $type_operation[ 0 ],
          $payment->{inner_describe},
          @type_fees[ $payment->{method} ],

          $html->button($lang{PRINT}, undef, {
            GLOBAL_URL      => $SELF_URL
              . '?index=' . get_function_index("cards_diller_operations_log")
              . '&UID=' . ($payment->{uid} || '')
              . '&LOGIN=' . ($payment->{login} || '')
              . '&AFTER_DEPOSIT=' . ($payment->{after_deposit} || '')
              . '&DATE=' . ($payment->{datetime} || '')
              . '&SUM=' . ($payment->{sum} || '')
              . '&DSC=' . ($payment->{dsc} || '')
              . '&PDF=1',
            NEW_WINDOW_SIZE => "640:750",
            class           => 'print',
            target          => '_blank'
          }));
      }

      print $table->show();
    }
  }

  if ($FORM{payment_diller}) {
    $html->tpl_show(_include('cards_diller_payments', 'Cards'), {
      INDEX        => get_function_index('cards_diller_search'),
      SID          => $main::sid,
      UID          => $FORM{UID},
      TYPE_PAYMENT => $html->form_select(
        'TYPE_PAYMENT',
        {
          SELECTED => 0,
          SEL_HASH => {
            4 => $lang{BONUS},
            2 => $lang{EXTERNAL_PAYMENTS},
            3 => 'Credit Card',
            7 => $lang{MONEY_TRANSFER}
          },
          NO_ID    => 1
        }
      ),
      TP_NAME      => $name_tariff->[0]->{name} || '',
      DEPOSIT      => sprintf('%.2f', $FORM{DEPOSIT}) || '',
      ADDRESS      => $FORM{CITY} || '',
      LOGIN        => $FORM{LOGIN} || ''
    });

    my $payments_list = $Payments->list({
      LOGIN             => $FORM{LOGIN} || '_SHOW',
      UID               => $FORM{UID} || '_SHOW',
      SUM               => '_SHOW',
      DSC               => '_SHOW',
      DATETIME          => '_SHOW',
      AFTER_DEPOSIT     => '_SHOW',
      ADMIN_NAME        => '_SHOW',
      INNER_DESCRIBE    => '_SHOW',
      PAYMENT_METHOD_ID => '_SHOW',
      METHOD            => '_SHOW',
      COLS_NAME         => 1,
      EXT_ID            => 50
    });

    my $table = $html->table({
      width   => '100%',
      caption => $lang{LOG},
      title   => [ 'UID', $lang{LOGIN}, $lang{PAYMENT_DATE},
        $lang{DESCRIBE}, $lang{DEPOSIT}, $lang{SUM},
        $lang{OPERATOR}, $lang{DOCUMENT}, $lang{TYPE_OPERATION}, $lang{COMMENTS},
        $lang{PAYMENT_TYPE} ],
      qs      => $pages_qs,
      pages   => $Payments->{TOTAL},
      ID      => 'DILLERS_OPERATION_LOG',
    });

    foreach my $element (@$payments_list) {
      my $contract = '';
      foreach my $contract_id (@$contract_list) {
        if ($contract_id->{login} eq $element->{login}) {
          $contract = $contract_id->{contract_id};
        }
      }

      my $after_dep = _format_sum($element->{after_deposit});
      my $sum_out = _format_sum($element->{sum});

      $table->addrow(
        $element->{uid},
        $element->{login},
        $element->{datetime},
        $element->{dsc},
        $after_dep,
        $sum_out,
        $element->{admin_name},
        $contract,
        $type_operation[ 0 ],
        $element->{inner_describe},
        @type_fees[ $element->{method} ],

        $html->button($lang{PRINT}, undef, {
          GLOBAL_URL      => $SELF_URL
            . '?index=' . get_function_index("cards_diller_operations_log")
            . '&UID=' . ($element->{uid} || '')
            . '&LOGIN=' . ($element->{login} || '')
            . '&AFTER_DEPOSIT=' . ($element->{after_deposit} || '')
            . '&DATE=' . ($element->{datetime} || '')
            . '&SUM=' . ($element->{sum} || '')
            . '&DSC=' . ($element->{dsc} || '')
            . '&PDF=1',
          NEW_WINDOW_SIZE => "640:750",
          class           => 'print',
          target          => '_blank'
        }),
      );
    }

    print $table->show();

    return 0;
  }

  if ($FORM{search_form}) {
    my $table = $html->table({
      width   => '100%',
      caption => $lang{USER},
      title   => [ 'UID', $lang{LOGIN}, $lang{FIO}, $lang{DOCUMENT}, $lang{ADDRESS}, $lang{TARIF_PLAN} ],
      qs      => $pages_qs,
      ID      => 'DILLERS_SEARCH_USER'
    });

    my @default_search = ('FIO', 'FIO2', 'FIO3', 'ADDRESS_FLAT', 'EXT_DEPOSIT', 'DEPOSIT', 'UID', 'LOGIN', 'CONTRACT_ID',
      'CITY', 'DEPOSIT', 'GID', 'ADDRESS_STREET', 'ADDRESS_BUILD', 'TP_NAME', 'CREDIT', 'LOGIN_STATUS', 'PHONE', 'EMAIL');

    my $search_string = $FORM{UNIVERSAL_SEARCH};
    $search_string =~ s/\s+$//;
    $search_string =~ s/^\s+//;

    foreach my $field (@default_search) {
      $LIST_PARAMS{$field} = "*$search_string*";
    }

    if ($attr->{DEBUG}) {
      $Users->{debug} = 1;
    }

    require Address;
    Address->import();
    my $Address = Address->new($db, $admin, \%conf);
    my $build_list_address = $Address->build_list({
      STREET_NAME => $FORM{UNIVERSAL_SEARCH},
      LOCATION_ID => '_SHOW',
      COLS_NAME   => 1,
    });

    if ($build_list_address->[0]->{location_id}) {
      $LIST_PARAMS{ADDRESS_STREET} = $build_list_address->[0]->{street_name};
    }

    my $list = $Users->list({
      %LIST_PARAMS,
      _MULTI_HIT       => $search_string,
      UNIVERSAL_SEARCH => $search_string,
      COLS_NAME        => 1
    });

    if ($Users->{TOTAL} > 0) {
      foreach my $element (@$list) {
        my $tarrif_plan = '';
        foreach my $tarrif (@$name_tariff) {
          if ($element->{gid} == $tarrif->{tp_gid}) {
            $tarrif_plan = $tarrif->{name};
          }
        }
        $table->addrow(
          $element->{uid},
          $element->{login},
          $element->{fio},
          $element->{contract_id},
          ($element->{city} && $element->{address_street}) ? ($element->{city}
            . ', ' . $element->{address_street} . ' ' .
            ($element->{address_build} ? $element->{address_build} : 0)
            . '/' . ($element->{address_flat} ? $element->{address_flat} : 0)) : $element->{city},
          $tarrif_plan,
          $html->button($lang{PAYMENTS}, 'index=' . get_function_index('cards_diller_search') . '&payment_diller=1'
            . '&UID=' . $element->{uid} . '&GID=' . $list->[0]->{gid} . '&LOGIN=' . $element->{login}
            . '&DEPOSIT=' . $element->{deposit},
            { class => 'payments' })
        );
      }

      print $table->show();
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST});
    }
  }

  return 0;
}

#**********************************************************
=head2 cards_diller_operations_log()

  Arguments:
    -
    
  Returns:
    -
=cut
#**********************************************************
sub cards_diller_operations_log {
  require Users;
  Users->import();

  require Payments;
  Payments->import();

  my $Payments = Payments->new($db, $admin, \%conf);
  my $Users = Users->new($db, $admin, \%conf);

  if ($FORM{operations_log} && !$FORM{FROM_DATE} && !$FORM{TO_DATE}) {
    $html->message('err', $lang{ERROR}, $lang{EMPTY_FIELD});
  }
  my $payments_list = $Payments->list({
    LOGIN             => '_SHOW',
    SUM               => '_SHOW',
    DSC               => '_SHOW',
    FROM_DATE         => $FORM{FROM_DATE},
    TO_DATE           => $FORM{TO_DATE},
    UID               => '_SHOW',
    DATETIME          => '_SHOW',
    AFTER_DEPOSIT     => '_SHOW',
    ADMIN_NAME        => '_SHOW',
    INNER_DESCRIBE    => '_SHOW',
    PAYMENT_METHOD_ID => '_SHOW',
    METHOD            => '_SHOW',
    COLS_NAME         => 1,
    EXT_ID            => 50
  });

  my $users_list = $Users->list({
    FIO         => '_SHOW',
    CONTRACT_ID => '_SHOW',
    COLS_NAME   => 1
  });

  if (!$FORM{PDF}) {
    my $datepicker = $html->form_daterangepicker({
      NAME      => 'FROM_DATE/TO_DATE',
      FORM_NAME => 'report_panel',
      VALUE     => $FORM{'FROM_DATE_TO_DATE'} || '',
    });

    form_search({
      TPL =>
        $html->tpl_show(_include('cards_dillers_operation_log', 'Cards'), {
          INDEX  => get_function_index('cards_diller_operations_log'),
          SID    => $main::sid,
          PERIOD => $datepicker
        })
    });
  }

  if ($FORM{PDF}) {
    $html->tpl_show(_include('cards_print_diller', 'Cards'), {
      ORDER_NUM_1                 => $FORM{UID},
      ORDER_PERSONAL_INFO_LOGIN_1 => $FORM{LOGIN},
      ORDER_DEPOSIT_1             => $FORM{AFTER_DEPOSIT},
      ORDER_DATE_1                => $FORM{DATE},
      ORDER_SUM_1                 => $FORM{SUM},
      ORDER_DSC_1                 => $FORM{DSC}
    })
  }

  if (($FORM{FROM_DATE} && $FORM{TO_DATE}) || defined $FORM{pg}) {
    my $table = $html->table({
      width   => '100%',
      caption => $lang{LOG},
      title   => [ 'UID', $lang{LOGIN}, $lang{FIO}, $lang{PAYMENT_DATE},
        $lang{DESCRIBE}, $lang{DEPOSIT}, $lang{SUM},
        $lang{OPERATOR}, $lang{DOCUMENT}, $lang{TYPE_OPERATION}, $lang{COMMENTS},
        $lang{PAYMENT_TYPE} ],
      qs      => $pages_qs,
      pages   => $Payments->{TOTAL},
      ID      => 'DILLERS_OPERATION_LOG',
    });

    foreach my $element (@$payments_list) {
      my $contract = '';
      my $user_fio = '';
      foreach my $contract_id (@$users_list) {
        if ($contract_id->{login} eq $element->{login}) {
          $contract = $contract_id->{contract_id};
          $user_fio = $contract_id->{fio};
        }
      }

      my $after_dep = _format_sum($element->{after_deposit});
      my $sum_out = _format_sum($element->{sum});

      $table->addrow(
        $element->{uid},
        $element->{login},
        $user_fio,
        $element->{datetime},
        $element->{dsc},
        $after_dep,
        $sum_out,
        $element->{admin_name},
        $contract,
        $type_operation[ 0 ],
        $element->{inner_describe},
        @type_fees[ $element->{method} ],

        $html->button($lang{PRINT}, undef, {
          GLOBAL_URL      => $SELF_URL
            . '?index=' . get_function_index("cards_diller_operations_log")
            . '&UID=' . ($element->{uid} || '')
            . '&LOGIN=' . ($element->{login} || '')
            . '&AFTER_DEPOSIT=' . ($element->{after_deposit} || '')
            . '&DATE=' . ($element->{datetime} || '')
            . '&SUM=' . ($element->{sum} || '')
            . '&DSC=' . ($element->{dsc} || '')
            . '&PDF=1',
          NEW_WINDOW_SIZE => "640:750",
          class           => 'print',
          target          => '_blank'
        }),
      );
    }

    my $all_sum = $Payments->{SUM};
    my $all_operations = $Payments->{TOTAL};

    if ($FORM{operations_log}) {
      $html->tpl_show(_include('cards_dillers_sum_operations', 'Cards'), {
        SUM_OPERATIONS => sprintf('%.2f', $all_sum),
        PERIOD         => $FORM{FROM_DATE} . ' - ' . $FORM{TO_DATE},
        COUNT          => $all_operations
      })
    }

    print $table->show();
  }

  return 0;
}

1;