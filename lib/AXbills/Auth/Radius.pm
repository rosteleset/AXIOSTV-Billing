package AXbills::Auth::Radius;
=head2 NAME

  Radius check access

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 check_access($attr)

  Arguments:
    LOGIN
    PASSWORD

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr) = @_;
  my $res    = 0;

  my $check_access = $self->{conf}->{check_access};

  if(! $check_access) {
    $self->{errno}  = 20;
    $self->{errstr} = "Auth server is not defined";
    print $self->{errstr};
    exit;
  }

  my $nas_ip = $check_access->{NAS_FRAMED_IP} || '127.0.0.1';

  require Radius;
  Radius->import();
  $self->{conf}->{'dictionary'} = '../lib/dictionary' if (!exists($self->{conf}->{'dictionary'}));

  my $r = Radius->new(
    Host   => "$check_access->{NAS_IP}",
    Secret => "$check_access->{NAS_SECRET}"
  );

  if (! $r) {
    $self->{errno}  = 21;
    $self->{errstr} = "Can't connect to '$check_access->{NAS_IP}' $!";
    return $res;
  }

  $r->load_dictionary($self->{conf}->{'dictionary'}) || die("Cannot load dictionary '$self->{conf}->{dictionary}' !");

  if ($r->check_pwd($attr->{LOGIN}, $attr->{PASSWORD}, $nas_ip)) {
    $res = 1;
  }

  return $res;
}

1;
