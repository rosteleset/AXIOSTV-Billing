package Cams::Cams;
use strict;
use warnings FATAL => 'all';

use AXbills::Base qw / cmd _bp /;
use Digest::MD5 qw / md5_base64 /;

=head2 NAME

  Cams

=head2 SYNOPSIS

  Bridge beetween ABillS and streaming server

=cut

#**********************************************************
=head2 new($Cams, $CONF)

  Arguments:
    $Cams  - ref to Cams DB object
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($Cams, $CONF) = @_;

  my $self = {
    cams => $Cams,
    conf  => $CONF,
  };

  bless( $self, $class );

  return $self;
}

#**********************************************************
=head2 cams_list($attr) - placeholder

=cut
#**********************************************************
sub cams_list {
  return ;
}

#**********************************************************
=head2 add_cam($attr) - adds new live stream

  Arguments:
    $attr -

  Returns:
    1 - if success

=cut
#**********************************************************
sub add_cam {
  my $self = shift;
  my ($attr) =  @_;

  my $stream_url = $attr->{STREAM_URL} || $attr->{URL};

  my $logo1_option = '';
  my $logo2_option = '';
  my $rotate_params = '';
  
  if ($self->{conf}{CAMS_LOGO1}){
    $logo1_option = "LOGO=$self->{conf}{CAMS_LOGO1}";
  }
  if ($self->{conf}{CAMS_LOGO2}){
    $logo2_option = "LOGO2=$self->{conf}{CAMS_LOGO2}";
  }
  if ($attr->{ORIENTATION}){
    $rotate_params = "ORIENTATION=$attr->{ORIENTATION}";
  }
  
  my $name = _name_for_stream($attr);

  cmd("/usr/axbills/libexec/cams_management.pl ADD=$name STREAM=$stream_url $logo1_option $logo2_option $rotate_params");

  return 1;
}

#**********************************************************
=head2 delete_cam($name) - deletes live cam stream

  Arguments:
    $attr - hash_ref
      NAME - to delete by name
      ID   - to delete by id

  Returns:
    1 - if success

=cut
#**********************************************************
sub delete_cam {
  my ($self, $attr) =  @_;

  if ($attr->{HASH_NAME}) {
    cmd("/usr/axbills/libexec/cams_management.pl DELETE=$attr->{HASH_NAME}");
  }
  else {
    return 0;
  }

  return 1;
}

#**********************************************************
=head2 change_cam()

=cut
#**********************************************************
sub change_cam {
  my ($self, $attr) = @_;
  
  my $name = _name_for_stream($attr);
  $self->delete_cam({HASH_NAME => $name});
  $self->add_cam($attr);

  return 1;
}

#**********************************************************
=head2 _name_for_stream()

=cut
#**********************************************************
sub _name_for_stream {
  my ($attr) = @_;

  my $stream_url = $attr->{HOST};
  my $login = $attr->{LOGIN};
  my $password = $attr->{PASSWORD};
  
  return md5_base64($stream_url, $login, $password) . '__' . ($attr->{ID} || '' );
}


1;