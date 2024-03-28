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
  unshift(@INC,
    $Bin . '/../',
    $Bin . '/../lib/',
    $Bin . '/../AXbills',
    $Bin . '/../AXbills/mysql',
    $Bin . '/../AXbills/modules',
  );

}

use AXbills::Base qw/_bp/;
use AXbills::SQL;
use Extreceipt::db::Extreceipt;
use Admins;

our $db = AXbills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin    = Admins->new($db, \%conf);
my $Receipt   = Extreceipt->new($db, $admin, \%conf);

my $message = ();
my $debug = 0;

print "Content-type:text/html\n\n";
$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/ if ($ENV{'REQUEST_METHOD'});
if ($ENV{'REQUEST_METHOD'} eq "POST") {
  my $buffer = '';
  read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
  `echo '$buffer' >> /tmp/extreceipt.log`;
  $message = decode_json($buffer);
  # print '{"token":"12345678"}';
}
else {
  # print "Atol.cgi";
  exit 0;
}

message_process();
exit 1;

#**********************************************************
=head2 message_process()
  
=cut
#**********************************************************
sub message_process {
  return 1 if (!$message->{uuid} && !$message->{external_id});

  if ($message->{error}) {
    $Receipt->change({
      PAYMENTS_ID  => $message->{external_id},
      STATUS       => 4,
    });
    return 1;
  }

  $Receipt->change({
    PAYMENTS_ID  => $message->{external_id},
    FDN          => $message->{payload}->{fiscal_document_number} || '',
    FDA          => $message->{payload}->{fiscal_document_attribute} || '',
    RECEIPT_DATE => $message->{payload}->{receipt_datetime} || '',
    STATUS       => 2,
  });

  return 1;
}

1;