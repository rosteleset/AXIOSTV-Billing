=head1 NAME

  Viber button

=cut

use strict;
use warnings FATAL => 'all';

our (
  $base_dir,
  $db,
  %conf,
  $admin
);

#**********************************************************
=head2 buttons_list()
  
=cut
#**********************************************************
sub buttons_list {
  my ($attr) = @_;
  my @buttons_files = glob "$base_dir/AXbills/modules/Viber/buttons-enabled/*.pm";
  my %BUTTONS = ();
  foreach my $file (@buttons_files) {
    my (undef, $button) = $file =~ m/(.*)\/(.*)\.pm/;
    next if $button !~ /^[\w.]+$/;
    if (eval { require "buttons-enabled/$button.pm"; 1; }) {
      my $obj = $button->new($db, $admin, \%conf, $attr->{bot});
      if ($obj->can('btn_name')) {
        $BUTTONS{$button} = $obj->btn_name();
      }
    }
    else {
      print $@;
    }
  }

  return \%BUTTONS;
}

#**********************************************************
=head2 viber_button_fn($attr)

  Arguments:
     $attr
       button - button pm file
       fn     - button function

  Return:
    1 or 0

=cut
#**********************************************************
sub viber_button_fn {
  my ($attr) = @_;
  my $ret = 0;

  return if $attr->{button} !~ /^[\w.]+$/;
  if (eval { require "buttons-enabled/$attr->{button}.pm"; 1; }) {
    my $obj = $attr->{button}->new($db, $admin, \%conf, $attr->{bot}, $main::Bot_db);
    my $fn = $attr->{fn};
    if ($obj->can($fn)) {
      $ret = $obj->$fn($attr);
    }
  }
  return $ret;
}

1;
