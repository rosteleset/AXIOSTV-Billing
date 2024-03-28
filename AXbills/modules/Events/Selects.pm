#package Events::Selects;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Events::Selects - select functions in one place

=head2 SYNOPSIS

  This package aggregates helper functions for selects

=cut


our (
  %lang,
  $html,
  $Events,
  $admin, $db, %conf
);

use AXbills::Experimental;

#**********************************************************
=head2 _events_state_select($attr)

  Arguments:
    $attr - attributes for select

  Returns:
    HTML code for select

=cut
#**********************************************************
sub _events_state_select {
  my ($attr) = @_;
  
  return $html->form_select(
    'STATE_ID',
    {
      SELECTED    => $attr->{SELECTED} || $FORM{STATE_ID},
      SEL_LIST    => translate_list_simple($Events->state_list({ COLS_NAME => 1, SHOW_ALL_COLUMNS => 1, MODULE => 'Events' })),
      SEL_OPTIONS => { '' => '' },
      NO_ID       => 1,
    }
  );
}

#**********************************************************
=head2 _events_privacy_select($attr)

  Arguments:
    $attr - attributes for select

  Returns:
    HTML code for select

=cut
#**********************************************************
sub _events_privacy_select {
  my ($attr) = @_;
  
  return $html->form_select(
    'PRIVACY_ID',
    {
      SELECTED    => $attr->{SELECTED} || $FORM{PRIVACY_ID},
      SEL_LIST    =>
      translate_list_simple($Events->privacy_list({ COLS_NAME => 1, SHOW_ALL_COLUMNS => 1, MODULE => 'Events' })),
      SEL_OPTIONS => { '' => '' },
      NO_ID       => 1
    }
  );
}

#**********************************************************
=head2 _events_priority_select($attr)

  Arguments:
    $attr - attributes for select

  Returns:
    HTML code for select

=cut
#**********************************************************
sub _events_priority_select {
  my ($attr) = @_;
  
  return $html->form_select(
    'PRIORITY_ID',
    {
      SELECTED    => $attr->{SELECTED} || $FORM{PRIORITY_ID},
      SEL_LIST    =>
      translate_list_simple($Events->priority_list({ COLS_NAME => 1, SHOW_ALL_COLUMNS => 1, MODULE => 'Events' })),
      SEL_OPTIONS => { '' => '' },
      NO_ID       => 1
    }
  );
}

#**********************************************************
=head2 _events_group_select($attr)

  Arguments:
    $attr - attributes for select

  Returns:
    HTML code for select

=cut
#**********************************************************
sub _events_group_select {
  my ($attr) = @_;
  
  return $html->form_select(
    'GROUP_ID',
    {
      SELECTED    => $attr->{SELECTED} || $FORM{GROUP_ID},
      SEL_LIST    => translate_list_simple($Events->group_list({ COLS_NAME => 1, SHOW_ALL_COLUMNS => 1, MODULE => 'Events' })),
      NO_ID       => 1,
      SEL_OPTIONS => { '' => $lang{NO} },
      MAIN_MENU   => get_function_index('events_group_main'),
      %{ ($attr) ? $attr : {} }
    }
  );
}


1;