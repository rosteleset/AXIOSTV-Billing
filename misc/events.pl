#!/usr/bin/perl -w

=head1 NAME

  Events.pl

=head1 SYNOPSIS

  External program to accept events from external sources

=head1 VERSION
 
 0.02

=head2 CHANGELOG

  0.2 Add event with notification to admin
  0.1 Console management

=head1 USAGE

=cut

my $USAGE = << "USAGE";
  Arguments:
    SHOW   - list to show, one of (events, state, priority, privacy)
    OUTPUT - type of output, one of (Dumper, JSON, XML). Default to Dumper;

  Examples:
    List present events in JSON:
      ./events.pl SHOW=events OUTPUT=JSON

    List events created after 2016-08-03 in JSON:
      ./events.pl SHOW=events OUTPUT=JSON CREATED=">2016-08-03" SHOW_ALL_COLUMNS=1

    List all states that event can have:
      ./events.pl SHOW=state

    Same in XML
      ./events.pl SHOW=state OUTPUT=XML

    Add new state:
      ./events.pl ADD=state NAME="Cool state"

    Add new event:
      ./events.pl ADD=events MODULE="Dv" COMMENTS="Something happened"
USAGE

use strict;
use warnings FATAL => 'all';

our ( %conf, $DATE, $TIME );

my $libpath = '';
BEGIN {
  use FindBin '$Bin';
  
  $libpath = $Bin . '/../'; #assuming we are in /usr/axbills/misc/
  require "/$libpath/libexec/config.pl";
  $conf{dbtype} = 'mysql' if ( !$conf{dbtype} );
  
}

use lib $libpath;
use lib "$libpath/lib";
use lib "$libpath/AXbills";
use lib "$libpath/AXbills/modules";
use lib "$libpath/AXbills/$conf{dbtype}";

use AXbills::Base;
use AXbills::Misc;

my $ARGS = parse_arguments(\@ARGV);
my $OUTPUT_TYPE = $ARGS->{OUTPUT} ? $ARGS->{OUTPUT} : 'Dumper';
delete $ARGS->{OUTPUT};

my $xml_simple; # This have to be global;
init_output_former($OUTPUT_TYPE);

#use AXbills::Base;
#use AXbills::Server;

require AXbills::SQL;
my $db = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});

require Admins;
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID} || 2, { IP => '127.0.0.1' });

use Events;
#passing undef for $admin
#TODO: authorization
my $Events = Events->new($db, $admin, \%conf);

my $language = $ARGS->{LANGUAGE} || $conf{default_language} || 'english';
require "language/$language.pl";

main();

#**********************************************************
=head2 main() - main entry point

=cut
#**********************************************************
sub main {
  
  my $status_code = 1;
  my $result = [];
  my $list_name = "";
  
  if ( $ARGS->{SHOW} ) {
    $list_name = $ARGS->{SHOW};
    delete $ARGS->{SHOW};
    
    unless ( is_valid_list($list_name) ) {print_usage_and_exit()};
    
    my $func = "$list_name\_list";
    
    $ARGS->{SHOW_ALL_COLUMNS} = 1;
    $result = $Events->$func($ARGS);
    $status_code = $Events->{errno} || 0;
  }
  elsif ( $ARGS->{ADD} ) {
    $list_name = $ARGS->{ADD};
    delete $ARGS->{ADD};
    
    unless ( is_valid_list($list_name) ) {print_usage_and_exit()};
    
    my $func = "$list_name\_add";
    if ( $func eq 'events_add' ) {
      $status_code = add_via_api($ARGS) || 0;
      $result = [ { status => $status_code, NEW_ID => $Events->{INSERT_ID} } ];
    }
    else {
      $Events->$func($ARGS);
      $status_code = $Events->{errno} || 0;
      $result = [ { status => $status_code, NEW_ID => $Events->{INSERT_ID} } ];
    }
    
  }
  elsif ( $ARGS->{CHANGE} ) {
    $list_name = $ARGS->{CHANGE};
    delete $ARGS->{CHANGE};
    
    unless ( is_valid_list($list_name) ) {print_usage_and_exit()};
    
    my $func = "$list_name\_change";
    
    $Events->$func($ARGS);
    $status_code = $Events->{errno} || 0;
    $result = [ { status => $status_code } ];
  }
  elsif ( $ARGS->{DELETE} ) {
    $list_name = $ARGS->{DELETE};
    delete $ARGS->{DELETE};
    
    unless ( is_valid_list($list_name) ) {print_usage_and_exit()};
    
    my $func = "$list_name\_del";
    
    $Events->$func($ARGS);
    $status_code = $Events->{errno} || 0;
    $result = [ { status => $status_code } ];
  }
  else {
    print_usage_and_exit();
  }
  
  _output($result, { ITEM_NAME => $list_name });
  finish_execution($status_code);
}

#**********************************************************
=head2 add_via_api($event)

=cut
#**********************************************************
sub add_via_api {
  my ($event) = @_;
  
  require Events::API;
  Events::API->import();
  
  my $API = Events::API->new($db, $admin, \%conf);
  
  return $API->add_event($event);
}

#**********************************************************
=head2 printUsageAndExit()

=cut
#**********************************************************
sub print_usage_and_exit {
  print $USAGE;
  finish_execution(1);
}


#**********************************************************
=head2 init_output_former($output_type, $auth_vals)

  Arguments:
    $output_type

  Returns:

=cut
#**********************************************************
sub init_output_former {
  my ($output_type) = @_;
  
  if ( $output_type eq 'Dumper' ) {
    use Data::Dumper qw(Dumper);
  }
  elsif ( $output_type eq 'JSON' ) {
    my $loaded_json_result = load_pmodule("JSON", { RETURN => 1 });
    if ( $loaded_json_result ) {
      print $loaded_json_result;
      finish_execution(0);
    }
  }
  elsif ( $output_type eq 'XML' ) {
    my $loaded_xml_result = load_pmodule("XML::Simple", { RETURN => 1, IMPORT => ':strict' });
    if ( $loaded_xml_result ) {
      print $loaded_xml_result;
      finish_execution(0);
    }
    $xml_simple = XML::Simple->new(ForceArray => 1, NoAttr => 1);
  }
}

#**********************************************************
=head2 _output($value, $attr)

  Arguments:
    $value - something to output
    $attr  - hash_ref
      ITEM_NAME - name for XML root element

  Returns:

=cut
#**********************************************************
sub _output {
  my ($value, $attr) = @_;
  
  if ( !defined $value ) {
    # Holding empty list
    $value = [];
  }
  my $result = "";
  
  if ( $OUTPUT_TYPE eq 'Dumper' ) {
    my $dumped = Dumper $value;
    $dumped =~ /(\$.* = )(.*)/ms;
    my $declaration = $1;
    my $struct = $2;
    
    $struct = translate_text($struct);
    $result = "$declaration $struct";
  }
  elsif ( $OUTPUT_TYPE eq 'JSON' ) {
    $result = _translate(JSON::to_json($value));
  }
  elsif ( $OUTPUT_TYPE eq 'XML' ) {
    $result = $xml_simple->XMLout({ $attr->{ITEM_NAME} => $value },
      RootName => 'result',
      KeyAttr  => [],
      XMLDecl  => '<?xml version="1.0"  encoding="utf-8" ?>',
    );
    $result = translate_text($result);
  }
  
  print $result;
  print "\n";
  
  return 1;
}

sub translate_text() {
  my ($text) = @_;
  
  while ( $text =~ /(\$_.+)\b/ ) {
    my $lang_var = $1;
    my $translation = _translate($lang_var);
    
    $text =~ s/\Q$lang_var\E/$translation/gm;
  }
  
  return $text;
}

#**********************************************************
=head2 is_valid_list($list_name)

  Arguments:
    $list_name - list name to check for validity

  Returns:
    boolean

=cut
#**********************************************************
sub is_valid_list {
  my ($list_name) = @_;
  
  no warnings 'experimental::smartmatch';
  
  my @correct_lists = ('events', 'state', 'privacy', 'priority');
  return $list_name ~~ @correct_lists;
}

#**********************************************************
=head2 finish_execution($status_code)

  Arguments:
    $status code - status code to exit with

=cut
#**********************************************************
sub finish_execution {
  my ($status_code) = @_;
  
  if ( $status_code != 0 ) {
    print "\nExit with error: $status_code\n";
  }
  
  exit($status_code);
}

print "\nExit 0\n";

1;
=head1 AUTHOR Anykey <dev@billing.axiostv.ru>

=cut