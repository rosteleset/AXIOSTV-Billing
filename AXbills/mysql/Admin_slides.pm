package Admin_slides;

=head1 NAME

  Administrator full view slides

=cut

use strict;
our $VERSION = 2.05;
use parent 'dbcore';

my($admin, $CONF);

#**********************************************************
#
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF)   = @_;

  my $self = {};
  bless($self, $class);

  $self->{db}=$db;

  return $self;
}

#**********************************************************
=head2 add() Add slides

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->del();

  foreach my $slide_name (split(/,\s?/, $attr->{ENABLED} || '')) {
    #print "// $slide_name //<br>";
    foreach my $key ( sort keys %$attr ) {
      if ($key =~ /^$slide_name[\_]+(.+)/) {
        my $field_id        =  $1;
        $self->query_add('admin_slides', {
          SLIDE_NAME     => $slide_name,
          FIELD_ID       => $field_id,
          FIELD_WARNING  => $attr->{'w_'. $key} || '',
          FIELD_COMMENTS => $attr->{'c_'. $key} || '',
          PRIORITY       => $attr->{'p_'. $slide_name} || '',
          SIZE           => $attr->{'s_'. $slide_name} || '',
          AID            => $admin->{AID},
          #%$attr
        });
      }
    }
  }

  return $self;
}

#**********************************************************
=head2 del() -Delete all slides

=cut
#**********************************************************
sub del {
  my $self = shift;

  $self->query_del('admin_slides', undef, { aid => $admin->{AID} });

  return $self;
}

#**********************************************************
=head2 list() - Slides list

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
      ['SIZE',         'INT',  'size',         1 ],
      ['PRIORITY',     'INT',  'priority',     1 ],
      ['AID',          'INT',  'aid',            ],
    ],
    {
      WHERE => 1
    }
  );

  $self->query("SELECT slide_name, field_id, field_warning,
     field_comments, $self->{SEARCH_FIELDS} aid
    FROM admin_slides
     $WHERE;",
    undef,
    $attr
  );

  return $self->{list};
}



1
