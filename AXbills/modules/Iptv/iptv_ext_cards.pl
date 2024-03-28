#!/usr/bin/perl

=head1 NAME

   Ext cards managment

=cut

use vars qw($begin_time %FORM %LANG
  $DATE $TIME
  $CHARSET
  @MODULES
  $SNMP_Session
);


BEGIN {
  my $libpath = '../../../';
  $sql_type = 'mysql';
  unshift( @INC, './' );
  unshift( @INC, $libpath . "AXbills/$sql_type/" );
  #unshift(@INC, "/usr/axbills/AXbills/$sql_type/");
  #unshift(@INC, "/usr/axbills/");
  unshift( @INC, $libpath );
  unshift( @INC, '../../' );
  unshift( @INC, '../../AXbills/mysql' );
  unshift( @INC, '../../AXbills/' );
  unshift( @INC, $libpath . 'libexec/' );
  #unshift(@INC, "/usr/axbills/");
  #unshift(@INC, "/usr/axbills/AXbills/$sql_type/");

  eval { require Time::HiRes; };
  if ( !$@ ){
    Time::HiRes->import( qw(gettimeofday) );
    $begin_time = gettimeofday();
  }
  else{
    $begin_time = 0;
  }
}

use FindBin '$Bin';
require $Bin . '/../../../libexec/config.pl';
use AXbills::Base;
require AXbills::Misc;

my $version = '0.01';
my $CURL = $conf{FILE_CURL} || '/usr/local/bin/curl';

#Arguments
my $argv = parse_arguments( \@ARGV );

if ( defined( $argv->{help} ) ){
  help();
  exit;
}

if ( $argv->{DEBUG} ){
  $debug = $argv->{DEBUG};
  print "DEBUG: $debug\n";
}

my %status_compare = (
  0 => 6,
  1 => 0,
  2 => 2,
  3 => 3,
  4 => 4,
  5 => 5,
);

my %tps_compare = (
  1   => '1,3,4',
  2   => '2,2',
  3   => '1,5',
  197 => '1,5,6',
  105 => '4,5',
  218 => '3,5,7'
);

if ( defined( $argv->{GET_LIST} ) ){
  get_list();
}
elsif ( defined( $argv->{SET} ) ){
  set_card( $argv );
}

#**********************************************************
#
#**********************************************************
sub get_data{
  my ($attr) = @_;

  load_pmodule( 'JSON' );
  my $json = JSON->new->allow_nonref;

  my $request_url = $argv->{REQUEST_URL} || $conf{IPTV_SUBSRIBE_URL} || '';
  if ( $attr->{ACTION} ){
    $request_url .= '?' . $attr->{ACTION}
  }

  my $params = '';
  if ( $conf{IPTV_SUBSRIBE_USER} ){
    $params = "-u $conf{IPTV_SUBSRIBE_USER}:$conf{IPTV_SUBSRIBE_PASSWD} ";
  }

  $request_url =~ s/ /%20/g;
  $request_url =~ s/"/\\"/g;
  my $request_cmd = qq{ $CURL $params -s "$request_url" };
  my $result = `$request_cmd`;

  if ( $attr->{DEBUG} ){
    print "=====REQUEST=====<br>\n";
    print "<textarea cols=90 rows=10>$request_cmd</textarea><br>\n";
    print "=====RESPONCE=====<br>\n";
    print "<textarea cols=90 rows=15>$result</textarea>\n";
  }

  my $perl_scalar = $json->decode( $result );

  #if($perl_scalar->{status} && $perl_scalar->{status} eq 'error') {
  #	$self->{errno}=1;
  #	$self->{errstr}="$perl_scalar->{message}";
  #}

  return $perl_scalar;
}

#**********************************************************
#
#**********************************************************
sub set_card{
  my ($attr) = @_;

  my @action_arr = ("serial=$attr->{EXT_ID}");

  if ( defined( $attr->{SET} ) ){
    my %actions = (
      0 => 'card_activate',
      1 => 'card_block',
    );

    if ( defined( $attr->{STATUS} ) ){
      push @action_arr, "action=$actions{$attr->{STATUS}}";
    }

    if ( $attr->{TP_ID} ){
      push @action_arr, "action=card_edit&status=1";
      my @channels_arr = split( /,s?/, $attr->{CHANNELS} || $tps_compare{$attr->{TP_ID}} );

      foreach my $id ( sort @channels_arr ){
        push @action_arr, "pk" . $id . "=1";
      }
    }
  }

  my $list_hash = get_data( {
      ACTION  => join( '&', @action_arr ),
        DEBUG => $argv->{DEBUG}
    } );

  return 0;
}


#**********************************************************
#
#**********************************************************
sub get_list{
  my ($attr) = @_;

  my $list_hash = get_data( {
      ACTION  => 'list=0',
        DEBUG => $argv->{DEBUG}
    } );

  foreach my $line ( @{ $list_hash->{result} } ){
    foreach my $k ( sort keys %{$line} ){
      if ( $attr->{DEBUG} && $attr->{DEBUG} > 2 ){
        print "$k=";
        if ( ref $line->{$k} eq 'ARRAY' ){
          print join( ',', @{ $line->{$k} } );
        }
        else{
          print $line->{$k};
        }
        print "\t";
      }
    }

    print "EXT_ID=$line->{serial}\tSTATUS=$status_compare{$line->{status}}\n";
  }

  return 0;
}


#**********************************************************
#
#**********************************************************
sub help{

  print << "[END]";
Version: $version

[END]

}
