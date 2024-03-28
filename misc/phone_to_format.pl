#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

=head1 NAME

  phone_to_format.pl

=head1 SYNOPSIS

  phone_to_format.pl is used to edit phones in contacts (user_pi or users_contacts) table

=head2 ARGUMENTS

  --help, show this help and exit
    EDIT       - apply regexpressions to value (separator : ';;')
    CELL_PHONE - apply changes to cell phone values
    FILTER     - only edit values that mathes regexpressions
    PREVIEW    - only show possible translations (do not save)

=head2 EXAMPLE

  All numbers if not starts with '+380' will have trailing zero deleted and +380 appended
    ./phone_to_format.pl FILTER='!^\+380;' EDIT='^0/;;/(.*)/'

=head1 AUTHOR

  Anykey

=cut

BEGIN {
  our $Bin;
  use FindBin '$Bin';
  if ($Bin =~ m/\/axbills(\/)/) {
    my $libpath = substr($Bin, 0, $-[1]);
    unshift(@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/axbills dir \n";
  }
}

use AXbills::Init qw/$db $admin %conf/;
use Pod::Usage qw/pod2usage/;
use AXbills::Base qw/_bp parse_arguments/;

my %ARGS = %{parse_arguments(\@ARGV)};

die pod2usage() unless ($ARGS{FILTER} && $ARGS{EDIT});

use Users;
my $Users = Users->new($db, $admin, \%conf);

my $contacts_field = 'PHONE';
my $contacts_type = 2;

if ($ARGS{CELL_PHONE}) {
  $contacts_field = 'CELL_PHONE';
  $contacts_type = 1;
}

my $changes = ($conf{CONTACTS_NEW})
  ? new_contacts_format()
  : old_contacts_format();

use AXbills::Base qw/_bp/;
while (my ($uid, $new_value) = each %{$changes}) {

  if ($ARGS{PREVIEW}) {
    print "UID : $uid. ";
    if (ref $new_value eq 'ARRAY') {
      print join(', ', @$new_value);
    }
    else {
      print $new_value;
    }
    print "\n";
  }
  else {
    require Contacts;
    my $Contacts = Contacts->new($db, $admin, \%conf);
    $Contacts->contacts_change_all_of_type($contacts_type, { UID => $uid, VALUE => $new_value });
  }
}

#**********************************************************
=head2 old_contacts_format()

=cut
#**********************************************************
sub old_contacts_format {
  # Get all users with phones
  my $users_list = $Users->list({ PHONE => '_SHOW', UID => '_SHOW', COLS_NAME => 1 });
  die $Users->{errstr} if ($Users->{errno});

  my %changes = ();

  foreach my $user (@{$users_list}) {
    next if (!$user->{phone} || $user->{phone} !~ /$ARGS{FILTER}/o);

    my @phones = split('[,;]\s?', $user->{phone});
    my @new_values = ();

    foreach my $phone (@phones) {
      my $value = _expr($phone, $ARGS{EDIT});
      push(@new_values, $value);
    }

    $changes{$user->{uid}} = join(',', @new_values);
  }

  return \%changes;
}

#**********************************************************
=head2 new_contacts_format()

=cut
#**********************************************************
sub new_contacts_format {
  require Contacts;
  my $Contacts = Contacts->new($db, $admin, \%conf);

  # Get all users with phones
  my $contacts_list = $Contacts->contacts_list({
    TYPE      => $contacts_type,
    UID       => '_SHOW',
    VALUE     => '_SHOW',
    COLS_NAME => 1
  });
  die $Contacts->{errstr} if ($Contacts->{errno});

  my %changes = ();

  foreach my $contact (@{$contacts_list}) {
    next if (!$contact->{value} || $contact->{value} !~ /$ARGS{FILTER}/o);

    my @phones = split('[,;]\s?', $contact->{value});
    my @new_values = ();

    foreach my $phone (@phones) {
      my $value = _expr($phone, $ARGS{EDIT});
      push(@new_values, $value);
    }

    $changes{$contact->{uid}} = \@new_values;
  }

  return \%changes;
}

#**********************************************************
=head2 _expr($value, $expr_tpl) - Expration

  Filter expr

  Arguments:
    $value
    $expr_tpl

  Returns:
    Return result string

=cut
#**********************************************************
sub _expr {
  my ($value, $expr_tpl) = @_;

  if (!$expr_tpl) {
    return $value;
  }

  my @num_expr = split(/;;/, $expr_tpl);

  for (my $i = 0; $i <= $#num_expr; $i++) {
    my ($left, $right) = split(/\//, $num_expr[$i]);

    my $r = ($right eq '$1')
      ? '$1'
      : eval "\"$right\"";

    if ($value =~ s/$left/eval "\"$r\""/e) {
      return '' . $value;
    }
  }

  return '' . $value;
}



exit 0;