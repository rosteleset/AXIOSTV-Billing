package AXbills::Random v0.1.01;

use strict;
use warnings FATAL => 'all';

use Carp;

# These are the various character sets.
my @upper = ('A' .. 'Z');
my @lower = ('a' .. 'z');
my @digit = ('0' .. '9');
my @punct = map {chr} (33 .. 47, 58 .. 64, 91 .. 96, 123 .. 126);
my @any = (@upper, @lower, @digit, @punct);

# What's important is how they relate to the pattern characters.
# These are the old patterns for randpattern/random_string.

# These are the regex-based patterns.
my %patterns = (

  # These are the regex-equivalents.
  '.'  => [ @any ],
  '\d' => [ @digit ],
  '\D' => [ @upper, @lower, @punct ],
  '\w' => [ @upper, @lower, @digit, '_' ],
  '\W' => [ grep {$_ ne '_'} @punct ],
  '\s' => [ q{ }, "\t" ], # Would anything else make sense?
  '\S' => [ @upper, @lower, @digit, @punct ],

  # These are translated to their double quoted equivalents.
  '\t' => [ "\t" ],
  '\n' => [ "\n" ],
  '\r' => [ "\r" ],
  '\f' => [ "\f" ],
  '\a' => [ "\a" ],
  '\e' => [ "\e" ],
);

# This is used for cache of parsed range patterns in %regch
my %parsed_range_patterns = ();

# These characters are treated specially in randregex().
my %regch = (
  '\\' => sub {
    my ($self, $ch, $chars, $string) = @_;
    if (@{$chars}) {
      my $tmp = shift(@{$chars});
      if ($tmp eq 'x') {

        # This is supposed to be a number in hex, so
        # there had better be at least 2 characters left.
        $tmp = shift(@{$chars}) . shift(@{$chars});
        push(@{$string}, [ chr(hex($tmp)) ]);
      }
      elsif ($tmp =~ /[0-7]/) {
        carp 'octal parsing not implemented.  treating literally.';
        push(@{$string}, [ $tmp ]);
      }
      elsif (defined($patterns{"\\$tmp"})) {
        $ch .= $tmp;
        push(@{$string}, $patterns{$ch});
      }
      else {
        push(@{$string}, [ $tmp ]);
      }
    }
    else {
      croak 'regex not terminated';
    }
  },
  '.'  => sub {
    my ($self, $ch, $chars, $string) = @_;
    push(@{$string}, $patterns{$ch});
  },
  '['  => sub {
    my ($self, $ch, $chars, $string) = @_;
    my @tmp;
    while (defined($ch = shift(@{$chars})) && ($ch ne ']')) {
      if (($ch eq '-') && @{$chars} && @tmp) {
        my $begin_ch = $tmp[-1];
        $ch = shift(@{$chars});
        my $key = "$begin_ch-$ch";
        if (defined($parsed_range_patterns{$key})) {
          push(@tmp, @{$parsed_range_patterns{$key}});
        }
        else {
          my @chs;
          for my $n ((ord($begin_ch) + 1) .. ord($ch)) {
            push @chs, chr($n);
          }
          $parsed_range_patterns{$key} = \@chs;
          push @tmp, @chs;
        }
      }
      else {
        push(@tmp, $ch);
      }
    }
    croak 'unmatched []' if ($ch && $ch ne ']');
    push(@{$string}, \@tmp);
  },
  '*'  => sub {
    my ($self, $ch, $chars, $string) = @_;
    unshift(@{$chars}, split(//, '{0,}'));
  },
  '+'  => sub {
    my ($self, $ch, $chars, $string) = @_;
    unshift(@{$chars}, split(//, '{1,}'));
  },
  '?'  => sub {
    my ($self, $ch, $chars, $string) = @_;
    unshift(@{$chars}, split(//, '{0,1}'));
  },
  '{'  => sub {
    my ($self, $ch, $chars, $string) = @_;
    my $closed;
    CLOSED:
    for my $c (@{$chars}) {
      if ($c eq '}') {
        $closed = 1;
        last CLOSED;
      }
    }
    if ($closed) {
      my $tmp;
      while (defined($ch = shift(@{$chars})) && ($ch ne '}')) {
        croak "'$ch' inside {} not supported" if ($ch !~ /[\d,]/);
        $tmp .= $ch;
      }
      if ($tmp =~ /,/) {
        if (my ($min, $max) = $tmp =~ /^(\d*),(\d*)$/) {
          if (!length($min)) {$min = 0}
          if (!length($max)) {$max = $self->{'_max'}}
          croak "bad range {$tmp}" if ($min > $max);
          if ($min == $max) {
            $tmp = $min;
          }
          else {
            $tmp = $min + $self->{'_rand'}($max - $min + 1);
          }
        }
      }
      if ($tmp) {
        my $prev_ch = $string->[-1];

        push @{$string}, (($prev_ch) x ($tmp - 1));
      }
      else {
        pop(@{$string});
      }
    }
    else {
      # { isn't closed, so treat it literally.
      push(@{$string}, [ $ch ]);
    }
  },
);


sub _rand {
  my ($max) = @_;
  return int rand $max;
}

#**********************************************************
=head2 new($text, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $attr) = @_;

  my $self = {
    _length => $attr->{length} || undef,
    _max    => $attr->{max} || 10,
    _rand   => $attr->{rand_gen} || \&_rand
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 randregex($pattern)

=cut
#**********************************************************
sub randregex {
  my $self = shift;
  my $pattern = shift;

  my $limitation = $pattern =~ /{\d+}/g;
  my $meta_escape = $pattern =~ /\$$/g;

  my @strings = ();

  if ($pattern) {
    my $ch;
    my @string = ();
    my $string = q{};

    # Split the characters in the pattern up into a list for easier parsing.
    my @chars = split(//, $pattern);

    while (defined($ch = shift(@chars))) {
      my $es_ch = "\\$ch";
      next if ($pattern !~ /[$es_ch]/g);
      if (defined($regch{$ch})) {
        $regch{$ch}->($self, $ch, \@chars, \@string);
      }
      elsif ($ch =~ /[()^*.]/) {
        next;
      }
      elsif ($meta_escape && $ch =~ /[\$]/) {
        $meta_escape = 0;
        next;
      }
      else {
        push(@string, [ $ch ]);
      }
    }

    if (!$limitation && $self->{'_length'}) {
      unshift(@string, $string[0]) for (1 ... $self->{_length} - scalar @string);
    }

    foreach my $ch_ (@string) {
      $string .= $ch_->[ $self->{'_rand'}(scalar(@{$ch_})) ];
    }

    push(@strings, $string);
  }

  return wantarray ? @strings : join(q{}, @strings);
}

#**********************************************************
=head2 randpattern()

=cut
#**********************************************************
sub randpattern {
  my $self = shift;
  my @strings = ();

  while (defined(my $pattern = shift)) {
    my $string = q{};

    for my $ch (split(//, $pattern)) {
      if (defined $self->{$ch}) {
        $string .= $self->{$ch}->[ $self->{'_rand'}(scalar(@{$self->{$ch}})) ];
      }
    }
    push(@strings, $string);
  }

  return wantarray ? @strings : join(q{}, @strings);
}

#**********************************************************
=head2 get_pattern($name)

=cut
#**********************************************************
sub get_pattern {
  my $self = shift;
  my ($name) = @_;

  return $self->{ $name };
}

#**********************************************************
=head2 set_pattern($name, $charset)

=cut
#**********************************************************
sub set_pattern {
  my $self = shift;
  my ($name, $charset) = @_;
  $self->{ $name } = $charset;
}

#**********************************************************
=head2 random_string($pattern, @list)

=cut
#**********************************************************
sub random_string {
  my $self = shift;
  my ($pattern, @list) = @_;

  for my $n (0 .. $#list) {
    $self->{$n} = [ @{$list[$n]} ];
  }

  return $self->randpattern($pattern);
}

1;
