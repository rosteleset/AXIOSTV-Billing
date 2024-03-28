#!/usr/bin/perl
=head1

 Transfer attachments from base to disk

=cut

use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $DATE,
  $TIME
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../../../libexec/config.pl';
  unshift(@INC,
    $Bin . '/../../../',
    $Bin . '/../../../lib/',
    $Bin . "/../../../AXbills/$conf{dbtype}");

}

use AXbills::SQL;
use AXbills::Base qw(_bp parse_arguments);
use AXbills::Misc qw(_error_show);
use Msgs;
use Admins;

my $sql = AXbills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
my $db = ($conf{VERSION} && $conf{VERSION} < 0.70) ? $sql->{db} : $sql;
my $argv = parse_arguments(\@ARGV);

our $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.3' } );
if ( $admin->{errno} ){
  print "AID: $conf{SYSTEM_ADMIN_ID} [$admin->{errno}] $admin->{errstr}\n";
  exit 0;
}

my $debug = 0;
if($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
}

my $Msgs = Msgs->new( $db, $admin, \%conf );
my $ATTACH_DIR = $conf{TPL_DIR} . 'attach/msgs';

if($debug > 6) {
  $Msgs->{debug}=1;
}

my $attachments_list = $Msgs->attachments_list({
  MESSAGE_ID   => '_SHOW',
  FILENAME     => '_SHOW',
  CONTENT      => '_SHOW',
  CONTENT_TYPE => '_SHOW',
  PAGE_ROWS    => 1000000,
});
_error_show($Msgs);

if(!$attachments_list){
  print 'Attachments list is empty';
  exit;
}

my $count = 0;
foreach my $attach (@$attachments_list) {
  next if ($attach->{content} =~ /^FILE: $conf{TPL_DIR}/);

  my $messages_reply_list = $Msgs->messages_reply_list({
    ID        => $attach->{message_id},
    MSG_ID    => '_SHOW',
    UID       => '_SHOW',
    COLS_NAME => '_SHOW',
    PAGE_ROWS => 10000000
  });

  if(_error_show($Msgs)) {
    next;
  }

  if ($messages_reply_list && ref $messages_reply_list eq 'ARRAY' && !scalar(@$messages_reply_list)){
    next;
  }

  my $message_reply = $messages_reply_list->[0];
  if(!$message_reply->{uid} || !$message_reply->{main_msg}) {
    if($debug) {
      print "ERROR: Can't find user for $attach->{id} : $attach->{filename}\n";
    }

    $messages_reply_list = $Msgs->messages_list({
      MSG_ID    => $attach->{message_id},
      UID       => '_SHOW',
      COLS_NAME => '_SHOW',
      PAGE_ROWS => 10000000
    });

    if($Msgs->{TOTAL} && $Msgs->{TOTAL} > 0) {
      $message_reply = $messages_reply_list->[0];
      #print "/ $attach->{filename} / $message_reply->{uid} //\n";
      $message_reply->{main_msg} = '';
    }
    else {
      next;
    }
  }

  if(!$message_reply->{filename}){
    my (undef, $content_type) =  split(/\//, $attach->{content_type} || q{});
    $content_type //= q{};
    $content_type =~ s/plain/txt/;
    $message_reply->{filename} = $message_reply->{id} . 'm' . $attach->{message_id} . '.' . $content_type;
  }
  
  my $path = $ATTACH_DIR . '/' . $message_reply->{uid};

  if(! -d "$conf{TPL_DIR}/attach") {
    mkdir ("$conf{TPL_DIR}/attach") or die "Can`t create path '$conf{TPL_DIR}/attach' $!";
  }

  if(! -d $ATTACH_DIR) {
    mkdir ($ATTACH_DIR) or die "Can`t create path '$ATTACH_DIR' $!";
  }

  if (!(-d $path)) {
    mkdir ($path) or die "Can`t create path '$path' $!";
  }

  my $filename = $path . '/' . $message_reply->{main_msg} . '_' . $message_reply->{id} . '_' . $message_reply->{filename};

  open(my $fh, '>', $filename) or die "Can`t open '$filename' $!";
    print $fh $attach->{content};
  close $fh;

  $Msgs->attachment_change({
    ID      => $attach->{id},
    CONTENT => "FILE: " . $filename,
  });
  _error_show($Msgs);

  $count++;
}

print 'Number of migrated files: ' . $count . "\n";

1