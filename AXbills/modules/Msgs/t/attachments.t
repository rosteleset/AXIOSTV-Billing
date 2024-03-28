#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Carp::Always;

our $libpath;

BEGIN {
  our $Bin;
  use FindBin '$Bin';
  
  $libpath = $Bin . '/../../../../'; #assuming we are in /usr/axbills/AXbills/modules/Msgs/t/
  if ( $Bin =~ m/\/axbills(\/)/ ) {
    $libpath = substr($Bin, 0, $-[1]);
  }
  
  unshift(@INC,
    "$libpath",
    "$libpath/AXbills",
    "$libpath/lib",
    "$libpath/AXbills/modules",
    "$libpath/AXbills/mysql"
  );
}

die "No \$libpath \n" if ( !$libpath );

our (%conf);
do "$libpath/libexec/config.pl";

use Admins;
require AXbills::SQL;
our Admins $admin;
our AXbills::SQL $db;
$db = AXbills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'}, {
    CHARSET => $conf{dbcharset},
    SCOPE   => __FILE__ . __LINE__
  });
$admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

die unless ( $db );

if ( use_ok('Msgs::Misc::Attachments') ) {
  require Msgs::Misc::Attachments;
  Msgs::Misc::Attachments->import();
}

my $TEST_UID = 2;
my %TEST_MSG_PARAMS = (
  MSG_ID   => 1,
  REPLY_ID => 2,
);
my %TEST_ATTACHMENT = (
  FILENAME     => 'test.txt',
  CONTENT      => 'test',
  FILESIZE     => 4,
  CONTENT_TYPE => 'text/plain'
);

{
  # Test saving to db
  delete $conf{MSGS_ATTACH2FILE};
  my $Attachments = Msgs::Misc::Attachments->new($db, $admin, \%conf);

  my $saved_attachment_id = $Attachments->attachment_add({ UID => $TEST_UID, %TEST_MSG_PARAMS, %TEST_ATTACHMENT });
  ok($saved_attachment_id, 'Saved attachment to DB');

  # Now read it;
  my $attachment = $Attachments->attachment_info($saved_attachment_id);
  ok($attachment->{CONTENT} eq $TEST_ATTACHMENT{CONTENT}, 'Have read attachment with same content');
  
  ok($Attachments->delete_attachment($saved_attachment_id), 'Removed attachment');
}

# Test saving to fs
{
  # Test saving to db
  $conf{MSGS_ATTACH2FILE} = 'msgs';
  my $Attachments = Msgs::Misc::Attachments->new($db, $admin, \%conf);
  
  my $saved_attachment_id = $Attachments->attachment_add({ UID => $TEST_UID, %TEST_MSG_PARAMS, %TEST_ATTACHMENT });
  ok($saved_attachment_id, 'Saved attachment to File');
  
  ok($Attachments->_read_file_from_disk($libpath . "/libexec/", 'config.pl') ne 0, 'Can read files');
  
  # Now read it;
  my $attachment = $Attachments->attachment_info($saved_attachment_id);
  ok($attachment->{CONTENT} eq $TEST_ATTACHMENT{CONTENT}, 'Have read attachment with same content');
  
  ok($Attachments->delete_attachment($saved_attachment_id), 'Removed attachment');
}

done_testing();

