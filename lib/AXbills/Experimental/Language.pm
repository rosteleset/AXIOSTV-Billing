package AXbills::Experimental::Language;
use strict;
use warnings FATAL => 'all';

use Data::Dumper;

=head1 NAME

  AXbills::Experimental::Language - Package to load language files.
  May be renamed to AXbills::Language after accept

=head2 SYNOPSIS

  This package contains functions for dynamic loading of languages.
  It's main purpose is to incapsulate logic of loading main and modules dictionary

  Dictionaries should be stored in $base_dir/language and $base_dir/AXbills/modules/MODULE/
  
=cut

our %lang = ();

#**********************************************************
=head2 new($base_dir)

  Arguments:
    $base_dir         - string, base directory languages will be loaded from
    $default_language - (optional) string, language that will be used as default (default is 'russian')
    
  Returns:
    AXbills::Experimental::Language instance
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($base_dir, $default_language) = @_;
  
  if (! defined $base_dir){
    require FindBin;
    our $Bin;
    FindBin->import('$Bin');
    # This part will substitute $Bin to ../usr/axbills/
    if ($Bin =~ m/\/usr\/axbills(\/)/){
      $base_dir = substr($Bin, 0, $-[1]);
    }
  }
  
  my $self = {
    base_dir         => $base_dir || '/usr/axbills/',
    default_language => $default_language || 'russian',
    languages        => {},
    loaded_files => {}
  };
  
  bless($self, $class);
  
  $self->load($self->{default_language});
  
  return $self;
}

#**********************************************************
=head2 load($language, $module) - loads specified dictionary in self

  Arguments:
    $language - name of language to load
    $module   - (optionally) load lang file for specified module
    
  Returns:
    1 on successfull load
    0 otherwise
    
=cut
#**********************************************************
sub load {
  my ($self, $language, $module) = @_;
  
  # Undef on incorrect argument
  return unless ( $language );
  
  # Try to load otherwise
  my $lang_path = ($module
    ? $self->{base_dir} . "/AXbills/modules/$module/lng_$language\.pl"
    : $self->{base_dir} . "/language/$language\.pl"
  );
  
  if ( ! -f $lang_path ) {
    warn "No such file: $lang_path \n";
    return 0;
  }

  # Allows to skip duplicate loading of same file
  return 1 if ($self->{loaded_files}{$lang_path});
  
  eval {
    # Don't use our, because it cleares previous refs
    local %lang = ();
    do $lang_path;
    
    # We can load same language from different locations few times
    if ( exists $self->{languages}->{$language} && ref $self->{languages}->{$language} eq 'HASH' ) {
      
      $self->{languages}->{$language} = {
        %{$self->{languages}->{$language}},
        %lang
      };
    }
    else {
      $self->{languages}->{$language} = \%lang;
    }
  
    $self->{loaded_files}{$lang_path} = 1;
    
    return 1;
  };
  
  if ( $@ ) {
    warn "Error loading language file: $@ \n";
  }
  return 0;
}

#**********************************************************
=head2 get_lang_hash($language) - returns raw lang hash

  Arguments:
    $language -
    
  Returns:
    %lang_hash on list context
    $lang_hashref on scalar context
    0 if language was not loaded
    
=cut
#**********************************************************
sub get_lang_hash {
  my ($self, $language) = @_;
  
  # Undef on incorrect argument
  return if ( !$language );
  
  # False if language was not loaded
  return 0 if ( !exists $self->{languages}->{$language} );
  
  return wantarray ? %{$self->{languages}->{$language}} : $self->{languages}->{$language};
}

#**********************************************************
=head2 translate($text, $language) - translates given text

  Arguments:
    $text      - string, where lang vars are in template presentation ( _{[A-Z0-9_]+}_ )
    $language  - string (optional), $self->{default_language} will be used if not specified
    
  Returns:
    string - translated text. If translation was not found, text will be replaced in curly braces
    
=cut
#**********************************************************
sub translate {
  my ($self, $text, $language) = @_;
  
  return '' unless ( $text );
  
  $language ||= $self->{default_language};
  
  return $text unless exists $self->{languages}{$language};
  
  while ( $text =~ /\_\{(\w+)\}\_/g ) {
    my $to_translate = $1 or next;
    my $translation = $self->{languages}->{$language}->{$to_translate} // "{$to_translate}";
    
    $text =~ s/\_\{$to_translate\}\_/$translation/sg;
  }
  
  return $text;
}

#**********************************************************
=head2 has_language($lang_name)

  Arguments:
    $lang_name
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub has_language {
  return exists $_[0]->{languages}->{$_[1]};
}

#**********************************************************
=head2 get_languages()

=cut
#**********************************************************
sub get_languages {
  return $_[0]->{languages};
}

#**********************************************************
=head2 set_languages($new_value)

=cut
#**********************************************************
sub set_language {
  my ($self, $language, $lang_hashref) = @_;
  
  # We can load same language from different locations few times
  if ( exists $self->{languages}->{$language} && ref $self->{languages}->{$language} eq 'HASH' ) {
    # Merge languages replacing old values
    $self->{languages}->{$language} = { %{$self->{languages}->{$language}}, %$lang_hashref };
  }
  else {
    $self->{languages}->{$language} = $lang_hashref;
  }
  
  return $self;
}

#**********************************************************
=head2 get_default_language()

=cut
#**********************************************************
sub get_default_language {
  return $_[0]->{default_language};
}

#**********************************************************
=head2 set_default_language($new_value)

=cut
#**********************************************************
sub set_default_language {
  my ($self, $new_value) = @_;
  $self->{default_language} = $new_value;
  return $self;
}



1;