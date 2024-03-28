package Iptv::test_api v0.59.0;

=head1 NAME

  Olltv module

Olltv HTTP API

http://Oll.tv/
ispAPI v.2.1.4


=head1 VERSION

  Version 0.59
  Revision: 20200115

=head1 SYNOPSIS


=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.59;

use parent 'dbcore';
use AXbills::Base qw(load_pmodule);
use AXbills::HTML;
use AXbills::Fetcher;
my $MODULE = 'test_api';

my ($admin, $CONF);
my $md5;
my $json;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $admin->{MODULE} = $MODULE;

  my $self = {};
  bless($self, $class);

  load_pmodule('Digest::MD5');
  load_pmodule('JSON');

  $md5 = Digest::MD5->new();
  $json = JSON->new->allow_nonref;

  if ($CONF->{IPTV_OLLTV_DEBUG} && $CONF->{IPTV_OLLTV_DEBUG} > 1) {
    $self->{debug} = $CONF->{IPTV_OLLTV_DEBUG};
  }

  $self->{SERVICE_NAME} = 'test_api';
  $self->{VERSION} = $VERSION;

  $self->{LOGIN} = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{URL} = $attr->{URL};
  $self->{debug} = $attr->{DEBUG} || 0;

  $self->{request_count} = 0;

  return $self;
}

sub user_add {
  my $self = shift;
  my ($attr) = @_;
  
  AXbills::Base::_bp('Add', $attr->{STATUS}, {HEADER=>1});
  # AXbills::Base::_bp('Add', $attr, {HEADER=>1});
}

sub user_change {
  my $self = shift;
  my ($attr) = @_;

  AXbills::Base::_bp('Change', $attr->{STATUS}, {TO_CONSOLE=>1});
  AXbills::Base::_bp('Change', $attr->{FILTER_ID}, {TO_CONSOLE=>1});
  AXbills::Base::_bp('Change', $attr->{TP_FILTER_ID}, {TO_CONSOLE=>1});

  return 1;
}

sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  AXbills::Base::_bp('', "Negdeposit: " . ($attr->{STATUS} || ''), {TO_CONSOLE=>1});

  return 1;
}


#**********************************************************
=head2 hangup($attr)

=cut
#**********************************************************
sub hangup {
  my $self = shift;
  my ($attr) = @_;

  AXbills::Base::_bp('', 'Hangup', {HEADER=>1});
  AXbills::Base::_bp('', $attr, {HEADER=>1});

  return $self;
}

#**********************************************************
=head2 get_iptv_portal_extra_fields($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub get_iptv_portal_extra_fields {
  my ($attr) = @_;

  my @array = ({ id => 1, name => '111', value => '111'});
  return \@array;
}

#**********************************************************
=head2 channels_change($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub channels_change {
  my $self = shift;
  my ($attr) = @_;
  # AXbills::Base::_bp('', "change_channels ", {HEADER=>1});
  # AXbills::Base::_bp('', $attr->{ADD_ID}, {HEADER=>1});
  # #
  $self->{errno} = '10100';
  $self->{errstr} = 'ERR_SELECT_TP';
  return $self;

  # return 0;
}

#**********************************************************
=head2 user_import($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub user_import {
  my $self = shift;
  my ($attr) = @_;

  $self->{errno} = '10100';
  $self->{errstr} = 'ERR_SELECT_TP';
  return $self;
}

#**********************************************************
=head2 user_del($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  return $self;
}

# #**********************************************************
# =head2 user_screens($attr)
#
#   Arguments:
#     $attr
#       CID
#       OLD_CID
#
#   Returns:
#     $self
#
# =cut
# #**********************************************************
# sub user_screens {
#   my $self = shift;
#   my ($attr) = @_;
#
#   AXbills::Base::_bp('', $attr, {HEADER=>1});
# }

1;