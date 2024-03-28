package AXbills::Sender::Iptv_message;
=head1 NAME

  Send message on Iptv

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Sender::Plugin;
use parent 'AXbills::Sender::Plugin';

use AXbills::Base qw(_bp);
use Iptv;

my $Iptv;

#**********************************************************
=head2 new($conf, $attr) - Create new Iptv_message object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $attr) = @_ or return 0;

  my $self = {
    conf  => $conf,
    db    => $attr->{db} || {},
    admin => $attr->{admin} || {}
  };

  $Iptv = Iptv->new($self->{db}, $self->{admin}, $conf);

  bless $self, $class;

  return $self;
}

#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    PRIORITY_ID
    MAIL_TPL
    UID

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  my $Iptv_user = $Iptv->user_list({
    UID             => $attr->{UID},
    SUBSCRIBE_ID    => '_SHOW',
    SERVICE_ID      => '_SHOW',
    TV_SERVICE_NAME => '_SHOW',
    LOGIN           => '_SHOW',
    COLS_NAME       => 1,
    COLS_UPPER      => 1,
    PAGE_ROWS       => 99999,
  });

  my %Tv_services = ();

  my $total = 0;
  foreach my $user (@{$Iptv_user}) {
    next if $Tv_services{$user->{service_id}} || $user->{SERVICE_STATUS};

    my $tv_service = _load_service({ SERVICE_ID => $user->{service_id} });
    $Tv_services{$user->{service_id}} = $tv_service;

    next if !$tv_service || !$tv_service->can('send_iptv_message');

    $tv_service->send_iptv_message({ %{$attr}, %{$user} });
    $total += 1;
  }

  return $total;
}

#**********************************************************
=head2 _load_service($service_name, $attr) - Load service module

  Argumnets:
    $service_name  - service modules name
    $attr
       SERVICE_ID

  Returns:
    Module object

=cut
#**********************************************************
sub _load_service {
  my ($attr) = @_;
  my $api_object;
  my $service_name = '';

  if ($attr->{SERVICE_ID}) {
    $Iptv->services_info($attr->{SERVICE_ID});
    $service_name = $Iptv->{MODULE} || q{};
  }

  return $api_object if !$service_name;

  $service_name = 'Iptv::' . $service_name;

  eval " require $service_name; ";
  if (!$@) {
    $service_name->import();

    if ($service_name->can('new')) {
      $api_object = $service_name->new($Iptv->{db}, $Iptv->{admin} || {}, $Iptv->{conf}, { %$Iptv });
    }
    else {
      print "\nCan't load '$service_name'.";
      return $api_object;
    }
  }
  else {
    print $@;
    print "\nCan't load '$service_name'.";
  }

  return $api_object;
}

1;