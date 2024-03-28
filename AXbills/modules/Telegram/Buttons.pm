=head1 NAME

  Telegram button

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
  my @buttons_files = glob "$base_dir/AXbills/modules/Telegram/buttons-enabled/*.pm";
  my %BUTTONS = ();
  foreach my $file (@buttons_files) {
    my (undef, $button) = $file =~ m/(.*)\/(.*)\.pm/;
    next if $button !~ /^[\w.]+$/;
    if (eval { require "buttons-enabled/$button.pm"; 1; }) {
      my $obj = $button->new($db, $admin, \%conf, $attr->{bot}, $attr->{bot_db});
      next if $attr->{for_admins} && !$obj->{for_admins};
      next if !$attr->{for_admins} && $obj->{for_admins};

      $BUTTONS{$button} = $obj->btn_name() if $obj->can('btn_name');
    }
    else {
      print $@;
    }
  }

  return \%BUTTONS;
}

#**********************************************************
=head2 telegram_button_fn($attr)

  Arguments:
     $attr
       button - button pm file
       fn     - button function

  Return:
    1 or 0

=cut
#**********************************************************
sub telegram_button_fn {
  my ($attr) = @_;
  my $ret = 0;
  return if $attr->{button} !~ /^[\w.]+$/;
  if (eval { require "buttons-enabled/$attr->{button}.pm"; 1; }) {
    my $obj = $attr->{button}->new($db, $admin, \%conf, $attr->{bot}, $attr->{bot_db});
    my $fn = $attr->{fn};
    if ($obj->can($fn)) {
      $ret = $obj->$fn($attr);
    }
  }

  return $ret;
}

1;
