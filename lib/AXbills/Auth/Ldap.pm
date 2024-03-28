package AXbills::Auth::Ldap;
#**********************************************************
=head1 NAME

  LDAP admin auth module

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(load_pmodule);

load_pmodule('Net::LDAP', { HEADER => 1 });

#**********************************************************
=head2 check_access($attr)

  Arguments:
    LOGIN
    PASSWORD

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my($attr) = @_;

  my $login      = $attr->{LOGIN} || q{};
  my $password   = $attr->{PASSWORD} || q{};
  my $debug      = $self->{debug} || 0;

  my $ldap_base  = $self->{conf}->{LDAP_BASE} || "dc=sqd_ldp";
  my $server     = $self->{conf}->{LDAP_IP} || "192.168.0.40";

  my $ldap = Net::LDAP->new( $server, timeout => 10 );
  my $user_name = "cn=$login,ou=users,$ldap_base";
  if ($ldap_base =~ /\@/) {
    $user_name = "$login$ldap_base";
  }
  elsif($self->{conf}->{LDAP_AUTH_UID}) {
    $user_name = "uid=$login,ou=users,$ldap_base";
  }

  if (! $ldap) {
    $self->{errno}=$@;
    $self->{errstr}='LDAP Timeout';
    return 0;
  }

  my $mesg = $ldap->bind($user_name, password => $password);

  print "Result: $mesg->{resultCode} $mesg->{errorMessage}\n" if ($debug);
  $ldap->unbind;

  if (! $mesg->{resultCode}) {
    #$self->{errno}=21;
    #$self->{errstr}='LDAP Auth Error';
    return 1;
  }
  elsif ($mesg->{resultCode} == 49) {
    $self->{errno}=$mesg->{resultCode};
    $self->{errstr}='LDAP Auth Error: ' . $mesg->{errorMessage};
    #return 0;
  }

  return 0;
}

#**********************************************************
=head2 ldap_get_objects()

=cut
#**********************************************************
sub ldap_get_objects {
  my $self = shift;

  my $ldap_base  = $self->{conf}->{LDAP_BASE} || "dc=sqd_ldp";
  my $server     = $self->{conf}->{LDAP_IP} || "127.0.0.1";

  my $ldap = Net::LDAP->new( $server ) or die $@;

  my $ldap_pass  = $self->{conf}->{LDAP_PASSWORD} || "test";
  my $mesg = $ldap->bind("cn=root,$ldap_base", password => "$ldap_pass");

  my $result = $ldap->search(
    base   => $ldap_base,
    #filter => "(&(cn=Jame*) (sn=Woodw*))",
    filter => "(&(cn=*b*))"
  );

  if ($result->{code}) {
    die $result->error . $mesg;
  }

  printf "COUNT: %s\n", $result->{count};

  foreach my $entry (@{ $result->{entries} }) {
    print $entry->{dump};
  }

  print "===============================================\n";

  #    foreach my $entry ($result->entries) {
  #        printf "%s <%s>\n",
  #            $entry->get_value("displayName"),
  #            ($entry->get_value("mail") || '');
  #    }
  $ldap->unbind;

  return 1;
}


1;
