#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use utf8;

=head1 NAME

  sender.pl - Send message to admin via Telegram
  
=head1 SYNOPSIS

  Options:
    -A, --aid     Specify one ( -A 2 ) or few ( -A 1 -A 2 -A 3 ) admins to send message
    -M, --message Specify a message for sent ( -M 'Hello, my dear friends' )
    -S, --subject (optionally) subject for message
    -T, --type    Sender plugin name, (default : Telegram)
  Example:
    ./send_message -A 1 -M 'Have a nice day'
  
=cut

BEGIN{
  use FindBin '$Bin';
  
  # We are in /usr/axbills/bin
  unshift @INC, $Bin . '/../';
  unshift @INC, $Bin . '/../lib';
  unshift @INC, $Bin . '/../AXbills/modules';
  unshift @INC, $Bin . '/../AXbills/mysql';
  
}

our $VERSION = 0.02;

use Getopt::Long qw/GetOptions HelpMessage :config auto_help auto_version ignore_case/;
use Pod::Usage;

use AXbills::SQL;
use Admins;
use AXbills::Sender::Core;

my $admin_ids = ();
my $MESSAGE = '';
my $SUBJECT = '';
my $DEBUG = 0;
my $SENDER_TYPE = 'Telegram';

GetOptions(
  'debug|D=i'   => \$DEBUG,
  'aid|A=i@'    => \$admin_ids,
  'message|M=s' => \$MESSAGE,
  'subject|S=s' => \$SUBJECT,
  'type|T=s'    => \$SENDER_TYPE,
);

if ( !$admin_ids || ref $admin_ids ne 'ARRAY' || !scalar(@{$admin_ids}) || !$MESSAGE ) {
  pod2usage(2);
}

our (%conf);
require 'libexec/config.pl';

my $db = AXbills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/}, {CHARSET => $conf{dbcharset}});
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID} || 2, { IP => '127.0.0.1' });

####################################################################

my $Sender = AXbills::Sender::Core->new($db, $admin, \%conf, {
    SENDER_TYPE => $SENDER_TYPE || 'Telegram'
  });

foreach my $aid ( @{$admin_ids} ) {
  my $sent_message = $Sender->send_message({
    AID     => $aid,
    MESSAGE => $MESSAGE
  });
  
  if ( !$sent_message ) {
    my $err = $Sender->{errstr} || 'unknown error';
    print "Can't sent message to $aid : $err \n";
  };
}

exit 0;

1;
