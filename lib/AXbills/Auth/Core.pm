package AXbills::Auth::Core;

=head1 NAME

  Authe core

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(show_hash);
use Log qw(log_print);

#**********************************************************
=head2

  Arguments:
    SELF_URL
    AUTH_TYPE
    USERNAME
    CONF

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  my $auth_type = $attr->{AUTH_TYPE} || '';
  my $conf      = $attr->{CONF};
  my $self = {
    conf      => $conf,
    self_url  => $attr->{SELF_URL} || q{},
    username  => $attr->{USERNAME} || q{},
    domain_id => $attr->{DOMAIN_ID}
  };

  bless($self, $class);

  if ($auth_type !~ /^\w+$/) {
    print "Content-Type: text/html\n\n";
    print "Can't load auth module";

    return $self
  };

  my $name = "AXbills::Auth::$auth_type";
  my $plugin_path = $name . '.pm';
  $plugin_path =~ s{::}{/}g;
  eval { require $plugin_path };

  if(! $@) {
   $name->import();
   our @ISA  = ($name);
  }
  else {
    print "Content-Type: text/html\n\n";
    print "Can't load '$name'";
    print $@;
  }

  return $self;
}

#**********************************************************
=head2 check_access($attr)

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr)=@_;

  delete ($attr->{__BUFFER});
  my $request = show_hash($attr, { OUTPUT2RETURN => 1 });

  if($self->{conf}->{auth_debug}) {
    log_print(undef, 'LOG_INFO', $self->{username}, $request, {
      LOG_LEVEL => ($self->{conf}->{auth_debug}) ? 6 : 1,
      LOG_FILE  => (($self->{conf}->{base_dir}) ? $self->{conf}->{base_dir}.'/var/log/' : '/tmp/').'auth.log'
    });
  }

  my $result = $self->SUPER::check_access($attr);

  if ($self->{conf} && $self->{conf}->{auth_debug}) {
    $request = 'Result: ';
    if($self->{USER_ID}) {
      $request .= "$self->{USER_ID} : ". ($self->{USER_NAME} || q{});
    }
    elsif($self->{errno}) {
      $request .= "$self->{errno} $self->{errstr}";
    }

    log_print(undef, 'LOG_INFO', $self->{username}, $request, {
      LOG_LEVEL => ($self->{conf}->{auth_debug}) ? 6 : 1,
      LOG_FILE  => (($self->{conf}->{base_dir}) ? $self->{conf}->{base_dir}.'/var/log/' : '/tmp/').'auth.log'
    });
  }

  return $result;
}

#**********************************************************
=head2 get_info($attr)

  Arguments:
   CLIENT_ID

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub get_info {
  my $self = shift;
  my ($attr)=@_;

  return $self->SUPER::get_info($attr);
}


1;
