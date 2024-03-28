#!/usr/bin/perl -w

=head1 NAME

 Bugs grabber

=cut

use strict;
use warnings;
BEGIN {
  our $libpath = '../';

  our $sql_type = 'mysql';
  unshift( @INC, $libpath . "AXbills/$sql_type/",
    $libpath . 'libexec/',
    $libpath . 'lib/' );

  our $begin_time = 0;
  eval { require Time::HiRes; };
  if ( !$@ ){
    Time::HiRes->import( qw(gettimeofday) );
    $begin_time = Time::HiRes::gettimeofday();
  }
}

do "config.pl";
use AXbills::SQL;
use AXbills::Defs;
use AXbills::HTML;
use Admins;
use Inventory;

our (
  $DATE,
  $TIME,
  @MODULES,
  %conf,
  $sql_type,
  $libpath,
  %lang
);


my $html = AXbills::HTML->new();
my $db = AXbills::SQL->connect( $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef } );

require AXbills::Misc;

print $html->header();
eval { do "$libpath/language/$html->{language}.pl" };

#Operation status
my $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} } );
my $Inventory = Inventory->new( $db, $admin, \%conf );

bug_form();

#**********************************************************
=head2 bug_form()

=cut
#**********************************************************
sub bug_form {
  if ( $FORM{add} ){
    if ( $FORM{ERROR} =~ /========================/ ){
      ($FORM{ERROR}, $FORM{INPUTS}) = split( /========================\n{0,10}/, $FORM{ERROR} );
    }

    $FORM{ERROR} =~ s/[\r\n]+$//g;

    if($FORM{ERROR} && ! $FORM{CUR_VERSION}) {
      print "Fix VERSION: 0.74.22";
      return 1;
    }

    my $list = $Inventory->bugs_list({
        ERROR       => $FORM{ERROR},
        STATUS      => '_SHOW',
        FIX_VERSION => '_SHOW',
        COLS_NAME   => 1
    });

    if($Inventory->{TOTAL}) {
      print "Register Error: $list->[0]->{id}<br>\n";

      if($list->[0]->{fix_version}) {
        print "Status: Done<br>\n";
        print "Fix Version: $list->[0]->{fix_version}<br>";
      }
      else {
        print "Status: In progress<br>\n";
      }
    }
    else{
      $Inventory->bug_add( \%FORM );
      print "$lang{ADDED}: $Inventory->{INSERT_ID}";
    }
    return 0;
  }

  print << "[END]";

<form action=$SELF_URL>
<br>
<input type='text' name='FN_NAME' value=''>
<br>Error:
<br>
<textarea name='ERROR' cols='70' rows='12'></textarea>
<br>
<input type='submit' name='add' value='Send'>

</form>

[END]

}


1
