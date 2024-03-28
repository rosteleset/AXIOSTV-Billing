#!/usr/bin/perl

package Webtest;
use strict;
use warnings FATAL => 'all';

use AXbills::Base qw/_bp/;

#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my ($class) = @_;

  my $self = {};
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 send_message()
  
=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  $attr->{text} =~ s/\n/<br>/g;

  print $attr->{text};
  print "<br>";
  print "<br>";
  if ($attr->{reply_markup}->{keyboard}) {
    foreach my $line (@{$attr->{reply_markup}->{keyboard}}) {
      foreach my $button (@$line) {
        print "<a href='telegram_bot.cgi?command=$button->{text}'><button>$button->{text}</button></a> ";
      }
      print "<br>";
    }
  }
  else {
    print "<br>";
    print "<a href='telegram_bot.cgi'><button>Назад</button></a>";
    print "<br>";
  }
  return 1;
}

#**********************************************************
=head2 send_contact()
  
=cut
#**********************************************************
sub send_contact {
  my $self = shift;
  my ($attr) = @_;
  print "<br>";
  print "<a href='tel:$attr->{phone_number}'><button>$attr->{first_name}</button></a>";
  print "<br>";
  print "<br>";
  print "<a href='telegram_bot.cgi'><button>Назад</button></a>";
  print "<br>";

  return 1;
}

1;