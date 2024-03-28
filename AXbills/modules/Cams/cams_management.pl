#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use feature 'say';
my $axbills_dir;
BEGIN {
  use FindBin qw/$Bin/;
  $axbills_dir = $Bin . "/../"; # Assuming we are in /usr/axbills/libexec/ or /usr/axbills/misc/
}
use lib $axbills_dir;
use lib "$axbills_dir/lib";
use lib "$axbills_dir/AXbills/mysql";

use AXbills::Defs;
use AXbills::Base qw/parse_arguments _bp cmd/;
use AXbills::SQL;

use Admins;
use Cams;

our (%conf);
require 'libexec/config.pl';

my $db = AXbills::SQL->connect( $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd} );
my $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID} || 2, { IP => '127.0.0.1' } );

my $Cams = Cams->new( $db, $admin, \%conf );

my $ARGUMENTS = parse_arguments(\@ARGV);

# Operations
my $DELETE = $ARGUMENTS->{DELETE};
my $ADD = $ARGUMENTS->{ADD};
my $RENEW = $ARGUMENTS->{RENEW};

# Arguments
my $STREAM = $ARGUMENTS->{STREAM};
my $HTML_DIR = $ARGUMENTS->{HTML_DIR} || '/var/www/ipcam/';

my $INIT_SCRIPT_DIR = $ARGUMENTS->{INIT_DIR} || '/etc/init.d/';
my $BASH_SCRIPT_PREFIX = $ARGUMENTS->{SCRIPT_PREFIX} || 'cams_';

my $DEBUG = $ARGUMENTS->{DEBUG} || 0;

my %ORIENTATIONS = (
  0 => '',
  1 => '-vf transpose=1',
  2 => '-vf vflip,hflip',
  3 => '-vf transpose=2',
  4 => q{-vf 'hflip'},
  5 => q{-vf 'vflip'},
);

main();

#**********************************************************
=head2 main()

=cut
#**********************************************************
sub main {
  
  if ( !-d '/tmp/hls' ) {
    mkdir '/tmp/hls';
    cmd("chown -R nobody:nogroup /tmp/hls", {SHOW_RESULT => 1});
  }
  
  if ( defined ($ADD) && $ADD ne '' ) {
    for my $required_arg ( qw/HTML_DIR STREAM/ ) {
      die "No required argument $required_arg" if (!$required_arg);
    }
    
    $ADD =~ s/ /_/g;
    $ADD =~ s/\;|\`//g;
    
    add_stream($STREAM, $ADD);
    renew_monitrc([ $ADD ]);
    exit 0;
  }
  elsif ( defined ($DELETE) && $DELETE ne '' ) {
    delete_stream($DELETE);
    renew_monitrc([ $DELETE ]);
    exit 0;
  }
  elsif ( defined ($RENEW) && $RENEW ne '' ) {
    renew_all();
  }
  else {
    print <<"USAGE";
  Renew all streams from DB
    ./cams_management RENEW=1

  Add new stream:
    ./cams_management ADD=cam1 STREAM=rtsp://example.com:554/?get_params=asdasd HTML_DIR=/var/www/ipcam/

  Delete existing stream:
    ./cams_management DELETE=cam1
USAGE
    exit 1;
  }
  
  exit 0;
}

#**********************************************************
=head2 add_stream()

=cut
#**********************************************************
sub add_stream {
  my ($stream_url, $stream_name, $attr) = @_;
  
  say "Adding stream $stream_name";
  delete_stream($stream_name);

  my $ffmpeg_copy_dir = '/usr/bin/';
  my $ffmpeg_copy_name = 'ffmpeg_' . $stream_name;
  my $ffmpeg_copy_fullname =  $ffmpeg_copy_dir . $ffmpeg_copy_name;
  
  my $bash_script_name = $INIT_SCRIPT_DIR . $BASH_SCRIPT_PREFIX . "$stream_name\.sh";
  
  say "Make copy of ffmpeg" if ($DEBUG > 2);
  cmd("cp /usr/bin/ffmpeg " . $ffmpeg_copy_fullname, { SHOW_RESULT => 1 });
  
  say "Create init.d script" if ($DEBUG > 2);
  cmd("touch $bash_script_name", { SHOW_RESULT => 1 });
  
  if ( !(-d '/tmp/hls/' . $stream_name || mkdir '/tmp/hls/' . $stream_name . '/')){
    die "Error: Can't create directory for stream :  " . '/tmp/hls/' . $stream_name . '/';
  }
  
  my $bash_init_script = get_stream_init_script({
    NAME       => $stream_name,
    DIR        => $ffmpeg_copy_dir,
    COPY_NAME  => $ffmpeg_copy_name,
    STREAM_URL => $stream_url,
    STREAM     => $attr
  });
  
  open(my $init_script_fh, '>', "$bash_script_name") or die "Can't open $bash_script_name";
  print $init_script_fh $bash_init_script;
  close($init_script_fh);
  
  cmd("chmod +x $bash_script_name", { SHOW_RESULT => 1 });
  cmd("$bash_script_name start &>/dev/null", { SHOW_RESULT => 1 });
}

#**********************************************************
=head2 delete_stream()

=cut
#**********************************************************
sub delete_stream {
  my ($name) = @_;
  
  my $full_script_name = $INIT_SCRIPT_DIR . $BASH_SCRIPT_PREFIX . $name . '.sh';
  
  if ( -f $full_script_name ) {
    say "Deleting $name" if ($DEBUG > 2);
    cmd("$full_script_name stop &>/dev/null", { SHOW_RESULT => 1 });
    
    unlink "/usr/bin/ffmpeg_$name";
    unlink $full_script_name;
    
    cmd("/etc/init.d/monit restart", { SHOW_RESULT => 1 });
    say "Deleted $name" if ($DEBUG > 2);
  }
  
  return 1;
}

#**********************************************************
=head2 renew_all()

=cut
#**********************************************************
sub renew_all {
  my $streams_list = $Cams->streams_list( { DISABLED => '0', SHOW_ALL_COLUMNS => 1 } );
  
  # Streams are unique by url, login, password
  # This part is to skip transcoding same streams
  my %stream_by_name = ();
  foreach my $stream ( @{$streams_list} ) {
    $stream_by_name{$stream->{NAME_HASH}} = $stream;
  }
  
  my @names = ();
  foreach my $stream_name ( keys %stream_by_name ) {
    my $stream = $stream_by_name{$stream_name};
    add_stream('rtsp://' . $stream->{host} . ':' . $stream->{rtsp_port} . $stream->{rtsp_path}, $stream_name, $stream);
    push @names, $stream_name;
  }
  
  renew_monitrc(\@names);
}

#**********************************************************
=head2 append_to_monitrc()

=cut
#**********************************************************
sub append_to_monitrc {
  my ($name) = shift;
  
  my $content = make_monitrc_content([ $name ]);
  
  if ( $content ) {
    open(my $monitrc, '>>', '/etc/monit/monitrc') or die "Can't open monitrc";
    print $monitrc $content;
    close $monitrc;
  }
  
  return 1;
}

#**********************************************************
=head2 remove_single_from_monitrc()

=cut
#**********************************************************
sub remove_single_from_monitrc {
  my $name = shift;
  
  # Read all except specified name lines
  my $new_content = '';
  open(my $monitrc_read, '<', '/etc/monit/monitrc') or die "Can't open /etc/monit/monitrc for read";
  while(my $string = <$monitrc_read>){
    if ( $string !~ /\/$name\.(sh|pid)/o ) {
      $new_content .= $string;
    }
  }
  close($monitrc_read);
  
  # Write read lines
  open(my $monitrc_write, '>', '/etc/monit/monitrc') or die "Can't open /etc/monit/monitrc for write";
  print $monitrc_write $new_content;
  close($monitrc_write);
  
  
  return 1;
}

#**********************************************************
=head2 renew_monitrc($streams_list)

=cut
#**********************************************************
sub renew_monitrc {
  my $names = shift;
  
  my $content = make_monitrc_content($names);
  if ( $content ) {
    open(my $monitrc_fh, '>', '/etc/monit/monitrc') or die "Can't open /etc/monit/monitrc";
    print $monitrc_fh $content;
    close $monitrc_fh;
  }
  
  cmd("monit restart all &>/dev/null", { SHOW_RESULT => 1 });
  
  return 1;
}

#**********************************************************
=head2 make_monitrc_content($names)

=cut
#**********************************************************
sub make_monitrc_content {
  my ($names) = @_;
  my $content = '';
  
  foreach my $name ( @{$names} ) {
    my $script_name = $BASH_SCRIPT_PREFIX  . $name;
    $content .= <<"CONTENT";
check process ${name} with pidfile "/var/run/$script_name\.pid"
start program = "/etc/init.d/$script_name\.sh start"
stop program = "/etc/init.d/$script_name\.sh stop"

CONTENT
  }
  
  if ( $DEBUG > 2 ) {
    
    say " MONITRC CONTENT [ @$names ] START:";
    print $content;
    say " MONITRC CONTENT [ @$names ] END:";
    
  }
  
  return $content;
}

#**********************************************************
=head2 get_stream_init_script($stream_name, $ffmpeg_copy_dir, $ffmpeg_copy_name, $stream_url, $ffmpeg_params) - theredoc

=cut
#**********************************************************
sub get_stream_init_script {
  my ($attr) = @_;
  
  my ($stream_name, $ffmpeg_copy_dir, $ffmpeg_copy_name, $stream_url)
    = ($attr->{NAME}, $attr->{DIR}, $attr->{COPY_NAME}, $attr->{STREAM_URL});
  
  # Reference to original DB row
  my $stream = $attr->{STREAM} || {};
  
  my $params = '';
  my $video_codec = 'copy';
  
  $stream->{orientation} //= $ARGUMENTS->{ORIENTATION} || '';
  
  my $logo = $ARGUMENTS->{LOGO};
  my $logo2 = $ARGUMENTS->{LOGO2};
  if ( $logo && -f "$HTML_DIR$logo" ) {
    if ( $logo2 && -f "$HTML_DIR$logo2" ) {
      $params = qq{-i ${HTML_DIR}${logo} -i ${HTML_DIR}${logo2} -filter_complex "overlay=5:5,overlay=main_w-overlay_w-5:5"};
    }
    else {
      $params = qq{-i ${HTML_DIR}${logo} -filter_complex "overlay=5:5"};
    }
  }
  
  if ($stream->{orientation} && exists $ORIENTATIONS{$stream->{orientation}}){
    $params .= ' ' . $ORIENTATIONS{$stream->{orientation}};
    $video_codec = 'libx264';
  }
  
  
  my $bash_script_name = $INIT_SCRIPT_DIR . $BASH_SCRIPT_PREFIX . $stream_name . '.sh';
  my $ffmpeg_copy_full_name = $ffmpeg_copy_dir . $ffmpeg_copy_name;
  my $result = <<"CONTENT";
#!/bin/sh

name='$stream_name'
pid_file="/var/run/$stream_name.pid"

case "\$1" in
start)
  # echo "Transcoding started : ${stream_name}";
  killall -6 $ffmpeg_copy_name;
  $ffmpeg_copy_full_name -d -i "$stream_url" $params -acodec copy -vcodec $video_codec -flags -global_header -hls_time 5 -hls_list_size 6 -hls_wrap 10 -start_number 1 "/tmp/hls/\${name}/\${name}\.m3u8" &
  cam_pid=\$!
  echo \$cam_pid > \$pid_file
  echo \`( >>/dev/null )&\`;
  ;;
stop)
  #echo "Transcoding stoppped : \${name}";
  killall -6 $ffmpeg_copy_name;
  ;;
*)
  echo "Usage: $bash_script_name {start|stop}"
  exit 1
  ;;
esac
exit 0

CONTENT
  
  
  if ( $DEBUG > 3 ) {
    print $result;
  }
  
  return $result;
}
1;