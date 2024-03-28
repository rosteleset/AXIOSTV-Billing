package Abon::Misc::Attachments;

use strict;
use warnings FATAL => 'all';

=head1 NAME

  Abon::Misc::Attachments

=head2 SYNOPSIS

  This package is a transparent layer to work with pictures on disk

=cut

use Attach;
use Abon;

my Attach $Attach;
my Abon $Abon;

use AXbills::Base qw(in_array);

my %ATTACH_ABON_PARAMS = (
  ATTACH_PATH => 'abon'
);

my $allowed_extensions = 'jpg,jpeg,png,gif';

#**********************************************************
=head2 new($db,$admin,\%conf) - constructor for Abon::Misc::Attachments

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db           => $db,
    admin        => $admin,
    conf         => $CONF,
    save_to_disk => 1,
    files_dir    => 'abon'
  };

  bless($self, $class);

  $Attach //= Attach->new(@{$self}{qw/db admin conf/}, \%ATTACH_ABON_PARAMS);
  $Abon //= Abon->new(@{$self}{qw/db admin conf/});

  return $self;
}

#**********************************************************
=head2 save_picture($attr) - saves picture

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub save_picture {
  my ($self) = shift;
  my ($data, $id) = @_;

  my $file_name = $data->{filename};
  if (!$file_name) {
    return '';
  }

  my $file_extension;
  my @ext_arr = split(/,\s?/, $allowed_extensions);
  if ($file_name =~ /\.([a-z0-9\_]+)$/i) {
    $file_extension = $1;
    if (! in_array($file_extension, \@ext_arr)) {
      return '';
    }
  }
  my $random_name = int(rand(16777215));
  my $picture_name = "$random_name.$file_extension";
  my $args = { CONTENT => $data->{Contents} };
  $self->_save_to_disk($picture_name, $args);

  if ($id) {
    $self->delete_attachment($id);
  }

  return $picture_name;
}

#**********************************************************
=head2 delete_attachment($id) -

  Arguments:
    $attachment_id -

  Returns:
    boolean

=cut
#**********************************************************
sub delete_attachment {
  shift;
  my ($id) = @_;

  my $result = $Abon->tariff_info($id);

  my $base_dir = $main::base_dir || '/usr/axbills/';
  my $path = $base_dir . "AXbills/templates/attach/abon/" . ($result->{PICTURE} || '');

  unlink $path if ($path && -f $path);

  return 1;
}

#**********************************************************
=head2 _save_to_disk($msg_id, $reply_id, $filename, $attr) - writes file to disk

  Arguments:
    $msg_id,
    $reply_id,
    $filename,
    $attr

  Returns:
    full file path

=cut
#**********************************************************
sub _save_to_disk {
  my ($self, $filename, $attr) = @_;

  # filename should contain only alphanumeric_symbols
  $filename //= '';
  $filename =~ s/[^a-zA-Z0-9._-]/_/g;

  # Should change filename. map will replace undefined values with 0
  my $disk_filename = join('_', map {$_ // '0'} ($filename));

  my $final_path = $Attach->save_file_to_disk({
    %{$attr},
    FILENAME          => $filename,
    DISK_FILENAME     => $disk_filename,
    DIRECTORY_TO_SAVE => ''
  });

  if ($Attach->{errno}) {
    $self->{errno} = $Attach->{errno};
    $self->{errstr} = $Attach->{errstr};
    return 0;
  }

  return $final_path;
}

1;
