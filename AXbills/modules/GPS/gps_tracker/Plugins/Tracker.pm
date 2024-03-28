package Tracker;
use warnings FATAL => 'all';
use strict;

use POSIX qw( strftime );

=head1 NAME

Abstract tracker


=head1 VERSION

  Version 0.1

=head1 SYNOPSIS


=cut

use vars qw(@ISA $VERSION);
use Exporter;

$VERSION = 1.00;

my $instance;

=head2 new

Instantiation of singleton object

=cut
sub new {

  unless (defined $instance) {
    my $class = shift;
    my $self = { };
    bless($self, $class);
    $instance = $self;

    $self->init();
  }

  return $instance;
}

sub init{
  my $self = shift;


}

