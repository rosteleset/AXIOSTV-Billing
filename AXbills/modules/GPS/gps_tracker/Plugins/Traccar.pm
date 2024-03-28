package Traccar;
use warnings FATAL => 'all';
use strict;

use POSIX qw( strftime );

=head1 NAME

Abstract tracker


=head1 VERSION

  Version 0.1

=head1 SYNOPSIS


=cut

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Exporter;

$VERSION = 1.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("Tracker");

# Singleton reference;
my $instance;


=head2 new

Instantiation of singleton db object

=cut
sub new {

  unless (defined $instance) {
    my $class = shift;
    my $db = shift;
    ($CONF) = @_;
    my $self = { };
    bless($self, $class);
    $self->{db} = $db;
    $instance = $self;

    #    $instance->{debug} = 1;
  }

  return $instance;

}