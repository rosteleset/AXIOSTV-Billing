#!/usr/bin/perl

=head1 NAME

  config_vars_search.pl

=head1 SYNOPSIS

   Config Vars Search
   Dev Tool for searching config variables in files

=head1 OPTIONS

  PATH - config search path
    default: /usr/axbills/
  BY_MODULES - split config into %module%.json, searching by PATH + /AXbills/modules
    optional
  CREATE_DIFF - create diff_%date%.json from existing axbills.json
    optional

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  our $libpath = '../';
  unshift(@INC,
    $libpath . '/lib/',
    $libpath
  );
}

use File::Find;
use POSIX 'strftime';
use JSON;

use AXbills::Base qw/parse_arguments/;

our %CONFIG_DATA = ();
our @ALLOWED_FILENAMES = ('webinterface', 'config', 'periodic');
our @ALLOWED_EXTENSIONS = ('tpl', 'pm', 'pl', 't', 'cgi');

our @REGEXPS = (
  qr/\$conf\{(.+?)\}/,
  qr/\{conf\}\{(.+?)\}/,
  qr/\$СONF->\{(.+?)\}/,
  qr/\$Сonf->\{(.+?)\}/,
  qr/\$conf->\{(.+?)\}/,
  qr/\$\D+?->\{conf\}->\{(.+?)\}/
);

my $args = parse_arguments(\@ARGV);
my $search_dir = $args->{PATH} // '/usr/axbills/';
my $is_end_slash = substr($search_dir, -1) eq '/';
my $cut_length = length($search_dir) + !$is_end_slash;
my $config_data_dir = 'config_keys';

config_vars_search();

sub config_vars_search {
  my @DIRS = ($search_dir, );
  my $options = { wanted => \&file_search };

  find($options, @DIRS);
  if ($args->{BY_MODULES}) {
    create_json_by_modules({
      DIR => $search_dir,
      CREATE_DIFF => $args->{CREATE_DIFF}
    });
  } else {
    print_result();
  }
}

sub file_search {
  my $name = $File::Find::name;
  my $dir = $File::Find::dir;
  if (-d $name) {
    return 1;
  }

  my $file_name = substr($name, length($dir) + 1);

  if (grep { $_ eq $file_name } @ALLOWED_FILENAMES) {
    file_process($name, $dir);
    return 1;
  }

  my ($extension) = $name =~ /([^.]+)$/;

  if (grep { $_ eq $extension } @ALLOWED_EXTENSIONS) {
    file_process($name, $dir);
    return 1;
  }
}

sub file_process {
  my ($file_path) = @_;

  my $i = 0;
  my $relative_path = substr($file_path, $cut_length);

  open(my $fh, '<', $file_path);
  while(<$fh>) {
    $i++;
    for my $regex (@REGEXPS) {
      my @matches = $_ =~ $regex;
      next if (!@matches);
      for my $match (@matches) {
        if (!exists $CONFIG_DATA{$match}) {
          $CONFIG_DATA{$match} = [];
        }
        push @{$CONFIG_DATA{$match}}, "$relative_path:$i"
      }
    }
  }
  close($fh);
}

sub print_result {
  my $json = _get_configured_json();
  my $result = $json->encode(\%CONFIG_DATA);

  print $result;
}

sub create_json_by_modules {
  my ($attr) = @_;
  my $module_dir = "$attr->{DIR}/AXbills/modules";

  opendir my $dh, $module_dir
    or die "$0: opendir: $!";
  my $json = _get_configured_json();

  my @probably_modules = sort grep {-d "$module_dir/$_" && ! /^\.{1,2}$/} readdir($dh);

  my $existingdir = "./$config_data_dir";
  mkdir $existingdir unless -d $existingdir;

  my %OTHER_DATA = %CONFIG_DATA;
  my %ON_MODULE = ();

  for my $module (@probably_modules) {
    my @keys = grep { /$module/gmi } keys %CONFIG_DATA;
    $ON_MODULE{$module} = [];

    my %module_data = ();
    for my $module_keys (@keys) {
      $module_data{$module_keys} = $CONFIG_DATA{$module_keys};
      push @{$ON_MODULE{$module}}, $module_keys;
      delete ($OTHER_DATA{$module_keys});
    }

    my $result = $json->encode(\%module_data);
    _create_n_write_file($existingdir, $module, $result);

    @{$ON_MODULE{$module}} = sort @{$ON_MODULE{$module}}
  }

  if ($attr->{CREATE_DIFF}) {
    my $EXISTING_DATA = eval { _read_json_from_file('axbills') };
    _create_diff($EXISTING_DATA, \%CONFIG_DATA, $existingdir);
  }

  my $result = $json->encode(\%CONFIG_DATA);
  _create_n_write_file($existingdir, 'axbills', $result);

  $result = $json->encode(\%OTHER_DATA);
  _create_n_write_file($existingdir, 'axbills_other', $result);

  $result = $json->encode(\%ON_MODULE);
  _create_n_write_file($existingdir, 'axbills_config_modules', $result);
}

sub _create_n_write_file {
  my ($dir, $file_name, $content) = @_;
  open my $fileHandle, ">", "$dir/$file_name.json" or die "Can't open '$dir/$file_name.json'\n";
  print $fileHandle $content;
  close $fileHandle;
}

sub _get_configured_json {
  JSON->new->utf8->space_before(0)->space_after(1)->indent(1)->canonical(1)
}

sub _read_json_from_file {
  my ($filename) = @_;
  my $json_text = do {
    open(my $json_fh, "<:encoding(UTF-8)", "config_keys/$filename.json")
      or die("Can't open \"$filename\": $!\n");
    local $/;
    <$json_fh>
  };
  my $json = JSON->new;
  $json->decode($json_text)
}

sub _create_diff {
  my ($EXISTING_DATA, $CONFIG_DATA, $dir) = @_;

  if (!$EXISTING_DATA) {
    return;
  }

  my @minus_keys = ();
  my @plus_keys = ();

  my %COPIED_CONFIG = %{$CONFIG_DATA};
  my %COPIED_EXIST = %{$EXISTING_DATA};

  for my $new_key (keys %COPIED_CONFIG) {
    if (!defined($COPIED_EXIST{$new_key})) {
      push @plus_keys, $new_key;
    }
  }

  for my $old_key (keys %COPIED_EXIST) {
    if (!defined($COPIED_CONFIG{$old_key})) {
      push @minus_keys, $old_key;
    }
  }

  if (@plus_keys || @minus_keys) {
    my $json = _get_configured_json();
    my $result = $json->encode({
      plus  => \@plus_keys,
      minus => \@minus_keys,
    });

    my $date = strftime "%Y%m%d", localtime;
    _create_n_write_file($dir, "diff_$date", $result);
  }
}
