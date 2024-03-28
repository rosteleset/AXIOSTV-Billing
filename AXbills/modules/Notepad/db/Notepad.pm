package Notepad;

=head1 NAME

  Notepad - module for add notes

=head1 SYNOPSIS

  use Notepad;
  my $Notepad = Notepad->new($db, $admin, \%conf);

=cut

use strict;
use parent 'main';
use warnings;
my ($admin, $CONF);


#*******************************************************************
#  Инициализация обьекта
#*******************************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************

=head2 function get_sticker() - get sticker data

  Arguments:
    $attr
  Returns:
    @list

  Examples:
    my $list = $Notepad->get_sticker({COLS_NAME=>1});

=cut

#**********************************************************
sub get_sticker {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT id,subject,text FROM notepad",
    undef, $attr
  );

  return $self->{list};
}
1;