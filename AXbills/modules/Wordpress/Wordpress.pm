package Wordpress::Wordpress;

=head NAME

  Wordpress API v4

=cut

use strict;
use warnings FATAL => 'all';
use utf8;

BEGIN {
  #use lib ; # Assuming we are in /usr/axbills/AXbills/modules/Wordpress/
  unshift ( @INC, "../../../lib/" );
}
use AXbills::Base qw( _bp );
use AXbills::Defs;

my $no_xml_rpc = '';

eval {require XML::RPC};
if ($@){
  $no_xml_rpc = 1;
}

our $VERSION = 0.2;

my $xmlrpc;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  $CONF->{WORDPRESS_URL} //= q{};
  $CONF->{WORDPRESS_BLOGID} //= q{};
  $CONF->{WORDPRESS_ADMIN} //= q{};
  $CONF->{WORDPRESS_PASSWORD} //= q{};

  if ($no_xml_rpc){
    return 0;
  }
  else {
    $xmlrpc = XML::RPC->new( "$CONF->{WORDPRESS_URL}/xmlrpc.php" );
    $self->{authenticate} = [ $CONF->{WORDPRESS_BLOGID}, $CONF->{WORDPRESS_ADMIN}, $CONF->{WORDPRESS_PASSWORD} ];
  }

  bless( $self, $class );
  return $self;
}

#**********************************************************
=head2 posts_list(\%filters)

  Arguments:
     \%filters - to look for (Optional)
      string   post_type
      string   post_status
      int      number
      int      offset
      string   orderby
      string   order

  Returns:
    array_ref

=cut
#**********************************************************
sub posts_list {
  my ($self, $filters) = @_;
  $filters->{number}  ||= 50;
  $filters->{orderby} ||= 'ID';
  $filters->{order}   ||= 'DESC';
  my $posts = $xmlrpc->call( 'wp.getPosts', @{$self->{authenticate}}, $filters );

  return $posts;
}

#**********************************************************
=head2 users_list($filters)

  Arguments:
     \%filters - to look for (Optional)
       string role: Restrict results to only users of a particular role.
       string who: If 'authors', then will return all non-subscriber users.
       int number
       int offset
       string orderby
       string order

  Returns:
    array_ref

=cut
#**********************************************************
sub users_list {
  my ($self, $filters) = @_;
  return $xmlrpc->call( 'wp.getUsers', @{$self->{authenticate}}, { %{ ($filters) ? $filters : { } } } );
}

#**********************************************************
=head2 authors_list()

  Arguments:
    see users($filters)

  Returns:
    array_ref

=cut
#**********************************************************
sub authors_list {
  my ($self, $filters) = @_;
  return $xmlrpc->call( 'wp.getUsers', @{$self->{authenticate}}, { %{ ($filters) ? $filters : { } }, who => 'authors' } );
}

#**********************************************************
=head2 options_list($filter)

  Arguments:
    $filter -
      array options: List of option names to retrieve. If omitted, all options will be retrieved.

  Returns:
    list - string desc
           string value
           bool   readonly

=cut
#**********************************************************
sub options_list {
  my ($self, $filter) = @_;

  return $xmlrpc->call( 'wp.getOptions', @{$self->{authenticate}}, $filter );
}

#**********************************************************
=head2 set_options() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub set_options {
  my ($self, $attr) = @_;

  return $xmlrpc->call( 'wp.setOptions', @{$self->{authenticate}}, $attr );
}

#**********************************************************
=head2 get_themes() - get list of present colors

  Returns:
    array_ref

=cut
#**********************************************************
sub get_themes {
  my ($self) = @_;
  return $xmlrpc->call('axbills.get_custom_themes',  @{$self->{authenticate}});
}

#**********************************************************
=head2 get_current_theme() - get current Bootswitch theme

=cut
#**********************************************************
sub get_current_theme {
  my ($self) = @_;
  return $xmlrpc->call('axbills.get_current_theme',  @{$self->{authenticate}});
}

#**********************************************************
=head2 get_custom_options($new_options) - updates custom options on Wordpress

  Returns:
    hash_ref - all custom options

=cut
#**********************************************************
sub get_custom_options {
  my $self = shift;

  return $xmlrpc->call('axbills.get_custom_options', @{$self->{authenticate}});
}

#**********************************************************
=head2 update_custom_options($new_options) - updates custom options on Wordpress

  Arguments:
    $new_options - hash_ref
      option_name => option_value

  Returns:
    1

=cut
#**********************************************************
sub update_custom_options {
  my $self = shift;
  my ($new_options) = @_;

  return $xmlrpc->call('axbills.update_custom_options', @{$self->{authenticate}}, $new_options);
}

1;