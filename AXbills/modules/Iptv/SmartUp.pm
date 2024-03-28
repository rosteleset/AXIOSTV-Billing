package Iptv::SmartUp;

=head1 NAME

=head1 VERSION

  VERSION: 0.02
  Revision: 20180926

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.9;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher;
use Digest::SHA qw(hmac_sha256_hex);
my $MODULE = 'SmartUp';

my ($admin, $CONF);
my $json;
my AXbills::HTML $html;
my $lang;
my $Iptv;

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

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{LANG}) {
    $lang = $attr->{LANG};
  }

  my $self = {};
  bless($self, $class);

  load_pmodule('JSON');

  $json = JSON->new->allow_nonref;
  $self->{SERVICE_NAME} = $MODULE;
  $self->{VERSION} = $VERSION;
  $self->{db} = $db;

  $self->{public_key} = $attr->{LOGIN} || q{};
  $self->{private_key} = $attr->{PASSWORD} || q{};
  $self->{URL} = $attr->{URL} || 'http://api-test.hls.tv/';
  $self->{debug} = $attr->{DEBUG};
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;

  $self->{VERSION} = $VERSION;

  return $self;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  return my $result->{OK} = "ok";
}

#**********************************************************
=head2 user_add($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $Iptv = Iptv->new($self->{db}, $admin, $CONF);

  if (!$attr->{TP_ID}) {
    $self->{errno} = '10100';
    $self->{errstr} = 'ERR_SELECT_TP';
    return $self;
  }

  $Iptv->user_list({
    SERVICE_ID    => $attr->{SERVICE_ID},
    UID           => $attr->{UID},
    COLS_NAME     => 1,
    PAGE_ROWS     => 99999,
  });

  if ($Iptv->{TOTAL} > 1) {
    $self->{errno} = '10104';
    $self->{errstr} = 'TP IS ALREADY EXIST';
    return $self;
  }
  else {
    return $self;
  }
}

#**********************************************************
=head2 user_info($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{DEVICE_ID}) {
    $Iptv = Iptv->new($self->{db}, $admin, $CONF);
    $Iptv->device_info({
      DEVICE_ID  => $attr->{DEVICE_ID},
      SERVICE_ID => $attr->{SERVICE_ID},
    });

    if (!$Iptv->{TOTAL}) {
      $Iptv->device_add({
        DEV_ID        => $attr->{DEVICE_ID},
        UID           => $attr->{UID},
        ENABLE        => (defined($attr->{ENABLE})) ? $attr->{ENABLE} : 1,
        DATE_ACTIVITY => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime()),
        IP_ACTIVITY   => $attr->{IP_ACTIVITY} || '',
        SERVICE_ID    => $attr->{SERVICE_ID},
      });
    }
    else {
      $self->{errno} = '10101';
      $self->{errstr} = 'This device is already exist!';
      return $self;
    }
  }

  if ($attr->{DEVICE_SELECT}) {
    $Iptv = Iptv->new($self->{db}, $admin, $CONF);
    $Iptv->device_change({
      ID            => $attr->{DEVICE_SELECT},
      UID           => $attr->{UID},
      DATE_ACTIVITY => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime()),
    });
  }

  return $self;
}

#**********************************************************
=head2 customer_add_device($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub customer_add_device {
  my $self = shift;
  my ($attr) = @_;

  $Iptv = Iptv->new($self->{db}, $admin, $CONF);
  my $result = $Iptv->device_list({
    UID        => 0,
    SERVICE_ID => $attr->{SERVICE_ID},
    DEV_ID     => '_SHOW',
    ENABLE     => '_SHOW',
  });

  my $select_device = $html->form_select(
    'DEVICE_SELECT',
    {
      SELECTED    => $result || 0,
      SEL_LIST    => $result,
      SEL_KEY     => 'id',
      SEL_VALUE   => 'dev_id',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
    }
  );

  $html->tpl_show(main::_include('iptv_smartup_device', 'Iptv'), {
    INDEX         => $attr->{INDEX},
    CHG           => $attr->{chg_d},
    MODULE        => $attr->{MODULE},
    UID           => $attr->{UID},
    SELECT_DEVICE => $select_device,
  });

  #  _bp('', $attr);

  return 1;
}

#**********************************************************
=head2 user_params($attr)

   Arguments:

   Results:

=cut
#**********************************************************
sub user_params {

}

1;