#!/usr/bin/perl

use strict;
use warnings;
use JSON;
use Encode qw/encode_utf8/;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
  %lang
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../libexec/config.pl';
  do $Bin . '/../language/english.pl';
  unshift(@INC,
    $Bin . '/../',
    $Bin . '/../lib/',
    $Bin . '/../AXbills',
    $Bin . '/../AXbills/mysql',
  );

}

use AXbills::Base qw/_bp/;
use AXbills::SQL;
use Admins;
use Users;
use Sms;
our $db = AXbills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin   = Admins->new($db, \%conf);
# my $Contacts = Contacts->new($db, $admin, \%conf);
# my $Users    = Users->new($db, $admin, \%conf);

my $message = ();
my $debug = 0;
my $Sms = Sms->new($db, $admin, \%conf);

print "Content-type:text/html\n\n";
$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/ if ($ENV{'REQUEST_METHOD'});
if (!$ENV{'REQUEST_METHOD'}) {
  print "asd";
}
elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
  my $buffer = '';
  read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
  # `echo '$buffer' >> /tmp/sms.log`;
  my $hash = from_json($buffer);
  exit 0 unless ($hash && ref($hash) eq 'HASH' && $hash->{messages});

  $message = $hash->{messages};
}
else {
  print "Ok.";
  exit 0;
}

process();

exit 0;

#**********************************************************
=head2 process()
  
=cut
#**********************************************************
sub process {
  if (ref $message ne 'ARRAY'){
    $message = [$message];
  }
  foreach my $msg (@$message){
    my $info =  $Sms->list({
      EXT_ID         => substr($msg->{"message-id"}, 3),
      PAGE_ROWS      => 99999,
      COLS_NAME      => 1,
      SKIP_DEL_CHECK => 1,
    });
    my $status = 0;
    if($msg->{status} eq 'Delivered' || $msg->{status} eq 'Transmitted'){
      $status = 3;
    } elsif($msg->{status} eq 'NotDelivered'){
      $status = 11;
    } elsif($msg->{status} eq 'Rejected' || $msg->{status} eq 'Failed'){
      $status = 14;
    } elsif($msg->{status} eq 'Deferred'){
      $status = 10;
    }
    $Sms->change({ID => $info->[0]->{id}, EXT_STATUS => $msg->{status}, STATUS_DATE => $msg->{"status-date"}, STATUS => $status});
  }
  return 1;
}

1;
