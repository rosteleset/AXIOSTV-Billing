#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use feature 'say';
=head2 NAME

  hotspot_browser_detect.pl

=head2 SYNOPSIS

  To speed up login page ( and because of bad dependency management system ),
  logic defining visitor browser was separated into new script.

=cut

my $libpath = '';

BEGIN {
  use FindBin '$Bin';
  
  $libpath = "$Bin/../"; # Assuming we are in /usr/axbills/libexec/
}

use lib $libpath;
use lib $libpath . 'lib';
use lib $libpath . 'AXbills/mysql';
use lib $libpath . 'AXbills/Control';

eval {require HTTP::BrowserDetect};
if ( $@ ) {
  print ( "Please install HTTP::BrowserDetect \n" );
  exit(1);
}
HTTP::BrowserDetect->import();

our (%conf);
require "libexec/config.pl";

use Admins;
use AXbills::SQL;
use AXbills::Base qw(parse_arguments _bp);
use Hotspot;

my %ARGS = %{ parse_arguments(\@ARGV) };

my $debug = $ARGS{DEBUG} || 0;

# System initialization
my $db = AXbills::SQL->connect( $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { %conf } );
my $admin = Admins->new( $db, \%conf );
$admin->info( $conf{USERS_WEB_ADMIN_ID} || $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1', SHORT => 1 } );

my $Hotspot = Hotspot->new( $db, $admin, \%conf );
main();


#**********************************************************
=head2 main()

=cut
#**********************************************************
sub main {
  # Get all existing browsers sorted by name and version
  my %browsers = %{ get_browsers_tree() };
  my %oses = %{ get_oses_tree() };
  
  my $user_agents = $Hotspot->user_agents_list( {
      ID         => '_SHOW',
      USER_AGENT => '_SHOW'
    } );
  
  foreach ( @{$user_agents} ) {
    my $ua = detect($_->{user_agent});
    my $session_id = $_->{id};
    
    my $b_name = $ua->{BROWSER}->{NAME} || '';
    my $b_version = $ua->{BROWSER}->{VERSION} || '';
    
    my $os_name = $ua->{OS}->{NAME} || '';
    my $os_version = $ua->{OS}->{VERSION} || '';
    
    my %change_info = (
      ID => $session_id
    );
    
    if ( exists $browsers{$b_name} && $browsers{$b_name}->{$b_version} ) {
      say "Saving existing browser $b_name $b_version" if ($debug);
      $change_info{BROWSER_ID} = $browsers{$b_name}->{$b_version};
    }
    else {
      say "Adding new browser $b_name $b_version" if ($debug);
      $Hotspot->browsers_add( {
          NAME    => $b_name,
          VERSION => $b_version
        } );
      my $new_id = $Hotspot->{INSERT_ID};
      $change_info{BROWSER_ID} = $new_id;
      $browsers{$b_name}->{$b_version} = $new_id;
    }
    
    if ( exists $oses{$os_name} && $oses{$os_name}->{$os_version} ) {
      say "Saving existing os $os_name $os_version" if ($debug);
      $change_info{OS_ID} = $oses{$os_name}->{$os_version};
    }
    else {
      say "Adding new os $os_name $os_version" if ($debug);
      $Hotspot->oses_add( {
          NAME     => $os_name,
          VERSION  => $os_version,
          MOBILE   => $ua->{OS}->{MOBILE} || 0,
          LANGUAGE => $ua->{LANGUAGE} || '',
          COUNTRY  => $ua->{COUNTRY} || ''
        } );
      my $new_id = $Hotspot->{INSERT_ID};
      $change_info{OS_ID} = $new_id;
      $oses{$os_name}->{$os_version} = $new_id;
    }
    
    $Hotspot->visits_change( \%change_info );
    if ( !$Hotspot->{errno} ) {
      $Hotspot->user_agents_del( { ID => $session_id } );
    }
  }
}

#**********************************************************
=head2 detect($user_agent_string)

=cut
#**********************************************************
sub detect {
  my ($user_agent_string) = @_;
  my $ua = HTTP::BrowserDetect->new( $user_agent_string );
  
  return {
    COUNTRY  => $ua->country,
    LANGUAGE => $ua->language,
    OS       => {
      NAME    => $ua->os_string,
      VERSION => $ua->os_version,
      MOBILE  => $ua->mobile,
    },
    BROWSER  => {
      NAME    => $ua->browser_string,
      VERSION => $ua->browser_version,
    }
  }
}


#**********************************************************
=head2 get_name_version_tree()

=cut
#**********************************************************
sub get_name_version_tree {
  my ($list) = @_;
  my %tree = ();
  for ( @{$list} ) {
    $tree{$_->{name}}->{$_->{version}} = $_->{id};
  }
  return \%tree;
}

#**********************************************************
=head2 get_browsers_tree()

=cut
#**********************************************************
sub get_browsers_tree {
  return get_name_version_tree($Hotspot->browsers_list( { NAME => '_SHOW', VERSION => '_SHOW' } ));
}

#**********************************************************
=head2 get_oses_tree()

=cut
#**********************************************************
sub get_oses_tree {
  return get_name_version_tree($Hotspot->oses_list( { NAME => '_SHOW', VERSION => '_SHOW' } ));
}

exit 0;