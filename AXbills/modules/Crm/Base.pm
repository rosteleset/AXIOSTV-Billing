package Crm::Base;
use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my AXbills::HTML $html;
my $lang;
my $Crm;
my @PRIORITY;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Crm::db::Crm;
  Crm->import();
  $Crm = Crm->new($db, $admin, $CONF);

  @PRIORITY = ($lang->{LOW} || $main::lang{LOW} || '', $lang->{NORMAL} || $main::lang{NORMAL} || '',
    $lang->{HIGH} || $main::lang{HIGH} || '');

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 internet_search($attr) - Global search submodule

  Arguments:
    $attr
      SEARCH_TEXT
      DEBUG

  Returs:
     TRUE/FALSE

=cut
#**********************************************************
sub crm_search {
  my $self = shift;
  my ($attr) = @_;

  my @default_search = ('FIO', 'PHONE', 'EMAIL', 'COMPANY', 'LEAD_CITY', 'ADDRESS', '_MULTI_HIT');
  my %LIST_PARAMS = (
    SKIP_HOLDUP     => 1,
    SKIP_RESPOSIBLE => 1
  );
  my @qs = ();
  my @info = ();

  foreach my $field (@default_search) {
    $LIST_PARAMS{$field} = "*$attr->{SEARCH_TEXT}*";
    push @qs, "$field=*$attr->{SEARCH_TEXT}*";
  }

  $Crm->{debug} = 1 if $attr->{DEBUG};

  my $lead_id = 0;
  if ($attr->{SEARCH_TEXT} !~ m/^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/) {
    my $leads = $Crm->crm_lead_list({ %LIST_PARAMS, COLS_NAME => 1 });

    if($Crm->{TOTAL} && $Crm->{TOTAL} == 1) {
      $lead_id = $leads->[0]->{lead_id};
    }
  }

  if ($Crm->{TOTAL}) {
    my $crm_link = 1 . '&get_index=crm_leads' . '&' . join('&', @qs) . "&SKIP_HOLDUP=1&search=1&full=1";
    if ($lead_id) {
      $crm_link = "1&get_index=crm_lead_info&full=1&LEAD_ID=$lead_id";
    }

    push @info, {
      TOTAL        => $Crm->{TOTAL},
      MODULE       => 'Crm',
      MODULE_NAME  => $lang->{LEADS},
      SEARCH_INDEX => $crm_link,
    };
  }
  elsif ($attr->{SEARCH_TEXT} =~ /\@/ || $attr->{SEARCH_TEXT} =~ /^\+?\d+$/) {
    my $search_type = 'EMAIL';

    if ($attr->{SEARCH_TEXT} =~ /^\+?\d+$/) {
      $search_type = 'PHONE';
    }

    push @info, {
      'TOTAL'        => 0,
      'MODULE'       => 'Crm',
      'MODULE_NAME'  => $lang->{LEADS},
      'SEARCH_INDEX' => 'crm_leads'
        . '&' . join('&', @qs) . "&search=1",
      EXTRA_LINK     => "$lang->{ADD}|get_index=" . 'crm_leads' . "&add_form=1&full=1&"
        . "$search_type=$attr->{SEARCH_TEXT}"
    };
  }

  return \@info;
}

#**********************************************************
=head2 crm_send_action_message($attr) - send action message to email

  Arguments:
    $attr
      LEAD_ID
      ACTION_ID

  Returs:
     TRUE/FALSE

=cut
#**********************************************************
sub crm_send_action_message {
  my $self = shift;
  my ($attr) = @_;

  return if !$attr->{LEAD_ID} || !$attr->{ACTION_ID};

  my $action_info = $Crm->crm_actions_info({ ID => $attr->{ACTION_ID} });
  return if !$action_info->{SEND_MESSAGE} || !$action_info->{MESSAGE};

  my $lead_info = $Crm->crm_lead_info({ ID => $attr->{LEAD_ID} });
  return if !$lead_info->{EMAIL};

  _crm_fill_select_values($lead_info);

  while($action_info->{MESSAGE} =~ /\%(\S+)\%/g) {
    my $var = $1;
    next if !$var;

    $lead_info->{$var} //= '';
    $action_info->{MESSAGE} =~ s/%$var%/$lead_info->{$var}/g;
  }
  
  my $is_html = $action_info->{MESSAGE} =~ /\<\S+\>/;
  $action_info->{MESSAGE} =~ s/\n/<br>/g if $is_html;

  require AXbills::Sender::Core;
  AXbills::Sender::Core->import();
  my $Sender = AXbills::Sender::Core->new($db, $admin, $CONF);

  return $Sender->send_message({
    TO_ADDRESS   => $lead_info->{EMAIL},
    MESSAGE      => $action_info->{MESSAGE},
    SUBJECT      => $action_info->{SUBJECT},
    SENDER_TYPE  => 'Mail',
    CONTENT_TYPE => $is_html ? 'text/html' : undef,
    MAIL_HEADER  => [ "X-ABillS-LEAD-ID: $attr->{LEAD_ID}" ]
  });
}

#**********************************************************
=head2 _crm_fill_select_values($lead_info)

  Arguments:
    $lead_info

=cut
#**********************************************************
sub _crm_fill_select_values {
  my $lead_info = shift;

  if ($lead_info->{SOURCE}) {
    my $source_info = $Crm->leads_source_info({ ID => $lead_info->{SOURCE} });
    $lead_info->{SOURCE} = main::_translate($source_info->{NAME}) if $source_info->{NAME};
  }

  if ($lead_info->{RESPONSIBLE}) {
    my $admin_info = $admin->list({ AID => $lead_info->{RESPONSIBLE}, ADMIN_NAME => '_SHOW', ID => '_SHOW', COLS_NAME => 1 })->[0];
    $lead_info->{RESPONSIBLE} = $admin_info->{name} if $admin_info->{name};
  }

  if (defined $lead_info->{PRIORITY}) {
    $lead_info->{PRIORITY} = main::_translate($PRIORITY[$lead_info->{PRIORITY}]) || $lead_info->{PRIORITY};
  }

  if ($lead_info->{CURRENT_STEP}) {
    my $step_info = $Crm->crm_progressbar_step_list({
      NAME        => '_SHOW',
      STEP_NUMBER => $lead_info->{CURRENT_STEP},
      DEAL_STEP   => '0',
      COLS_NAME   => 1
    });
    $lead_info->{CURRENT_STEP} = $step_info->[0]{name} if $step_info->[0] && $step_info->[0]{name};
  }

  if ($lead_info->{COMPETITOR_ID}) {
    my $competitor_info = $Crm->crm_competitor_info({ ID => $lead_info->{COMPETITOR_ID} });
    $lead_info->{COMPETITOR_ID} = $competitor_info->{NAME} if $competitor_info->{NAME};
  }

  if ($lead_info->{TP_ID}) {
    my $competitor_tp_info = $Crm->crm_competitors_tps_info({ ID => $lead_info->{TP_ID} });
    $lead_info->{TP_ID} = $competitor_tp_info->{NAME} if $competitor_tp_info->{NAME};
  }

  if ($lead_info->{BUILD_ID}) {
    use Address;
    my $Address = Address->new($db, $admin, $CONF);
    $Address->address_info($lead_info->{BUILD_ID});
    $lead_info->{BUILD_ID} = join ', ', grep {$_ && length $_ > 0}
      $Address->{ADDRESS_DISTRICT}, $Address->{ADDRESS_STREET}, $Address->{ADDRESS_BUILD}, $lead_info->{ADDRESS_FLAT};
  }

  my $fields_list = $Crm->fields_list({ SORT => 'priority', TYPE => 2 });
  foreach my $field (@{$fields_list}) {
    next if !$lead_info->{uc $field->{SQL_FIELD}};

    my $list_info = $Crm->info_list_info($lead_info->{$field->{SQL_FIELD}}, {
      LIST_TABLE_NAME => lc $field->{SQL_FIELD},
      COLS_NAME => 1
    });
    $lead_info->{uc $field->{SQL_FIELD}} = $list_info->{NAME} if $list_info->{NAME};
  }
}

1;