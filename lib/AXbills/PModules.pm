package AXbills::PModules;

=head1 NAME

  AXbills::PModules - ABillS load and install Perl modules

=cut

no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use feature 'state';
use strict;
our (%EXPORT_TAGS);

use POSIX qw(locale_h strftime mktime);
use parent 'Exporter';
use utf8;

our @EXPORT = qw(
  module_is_exist
  get_os
  load_perl_module
);

our @EXPORT_OK = qw(
  module_is_exist
  get_os
  load_perl_module
);

#**********************************************************
=head2 module_is_exist($attr)

  Arguments:
    $module_name

  Return:
    0 - not exist, 1 - exist

=cut
#**********************************************************
sub module_is_exist {
  my $module_name = shift;

  eval "require $module_name";

  return $@ ? 0 : 1;
}

#**********************************************************
=head2 load_perl_module($attr)

  Arguments:
    $module_name

  Return:

=cut
#**********************************************************
sub load_perl_module {
  my $module_name = shift;
  my ($attr) = @_;

  my $result = ();

  if (module_is_exist($module_name)) {
    eval "require $module_name";
    return 1;
  }

  print("Install module $module_name...\n") if $attr->{debug};
  $result = install_module($module_name);

  if (ref $result eq 'HASH' && $result->{success}) {
    print("Module $module_name installed\n") if $attr->{debug};
    eval "require $module_name";
    return 1;
  }
  elsif ($result->{error}) {
    print("Some error: $result->{error}") if $attr->{debug};
  }

  return 0;
}

#**********************************************************
=head2 install_module($attr)

  Arguments:
    $module_name

  Return:
    0 - not exist, 1 - exist

=cut
#**********************************************************
sub install_module {
  my $module_name = shift;

  my $os_params = get_os();
  return('error' => 1) if !$os_params->{name} || !$os_params->{install};

  my $result = ();
  $result = install_module_by_os({
    module_name => $module_name,
    params      => $os_params
  });

  return { 'success' => 1 } if (!$result->{error} && $result->{success});

  if ($result->{error}) {
    $result = install_module_by_os({
      module_name => $module_name,
      params      => ()
    });

    return { 'success' => 1 } if (!$result->{error} && $result->{success});
  }

  return { 'error' => 1 };
}

#**********************************************************
=head2 get_os($attr)

  Arguments:

  Return:
    os_params

=cut
#**********************************************************
sub get_os {

  my $os_name = $^O;
  my $os_params = ();

  return '' if !$os_name;

  $os_params->{name} = $os_name;
  if ($os_name eq 'linux') {
    $os_params->{install} = 'sudo apt-get install lib';
  }
  elsif ($os_name eq 'freebsd') {
    $os_params->{install} = 'cd /usr/ports/databases/p5-';
  }

  return $os_params;
}

#**********************************************************
=head2 install_module_by_os($attr)

  Arguments:
    $attr
      module_name
      params

  Return:


=cut
#**********************************************************
sub install_module_by_os {
  my ($attr) = @_;

  my $install_str = join('-', split('::', $attr->{module_name}));

  if ($attr->{params} && $attr->{params}{name} eq 'linux') {
    $install_str = $attr->{params}{install} . lc($install_str) . '-perl';
  }
  elsif ($attr->{params} && $attr->{params}{name} eq 'freebsd') {
    $install_str = $attr->{params}{install} . $install_str . ' && make && make install';
  }
  else {
    $install_str = "cpan $attr->{module_name}";
  }
  
  eval system($install_str);

  if ($@) {
    return { 'error' => $! };
  }
  else {
    return { 'success' => 1 };
  }
}


1