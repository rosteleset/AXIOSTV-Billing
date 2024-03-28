=head1 NAME

  Synsc  DB via ssh

=head1 CONFIG

  $conf{SYNC_DB_HOST}='192.168.1.100:22:/usr/axbills/backup/';

  $conf{SYNC_DB_DOWNLOAD}='scp asm@192.168.1.100:22:/usr/axbills/backup/stats-%DATE%.sql.gz /usr/axbills/backup/stats-%DATE%.sql.gz; '
   .'gzip -d /usr/axbills/backup/stats-%DATE%.sql.gz --name /usr/axbills/backup/sync_dump.sql';

  $conf{SYNC_DB_NAME}='axbills_3';

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(cmd);

our (
  %conf,
  $DATE,
  $argv,
  $debug
);

my $sync_db_dir = $conf{SYNC_DB_DIR} || '/usr/axbills/backup/';

if(defined($argv->{help})) {
  sync_db_help();
}
else {
  sync_db();
}

#**********************************************************
=head2 sync_db($attr) - List users

  Arguments:
    $attr

  Returns
    TRUE or FALSE

=cut
#**********************************************************
sub sync_db {
  #my ($attr) = @_;

  if($debug > 1) {
    print "Synsc remote DB\n";
  }

  my $dump_file = download_ssh();
  upload_dump($dump_file);


  return 1
}

#**********************************************************
=head2 download_ssh($attr) - List users

  Arguments:
    $attr

  Returns
    dumpfile

=cut
#**********************************************************
sub download_ssh {
  #my ($attr) = @_;

  if($debug > 1) {
    print "Download SSH DB\n";
  }

  my ($synsc_db_hosts, $sync_db_port, $path) = split(/:/, $conf{SYNC_DB_HOST} || q{});

  if(! $sync_db_port) {
    $sync_db_port = 22;
  }

  if(! $path) {
    $path = '/usr/axbills/backup/';
  }

  my $dump_file =  'stats-'. $DATE .'.sql.gz';

  my $cmd = $conf{SYNC_DB_DOWNLOAD} || q{};

  if(! $cmd && $synsc_db_hosts) {
    $cmd = qq{scp -P $sync_db_port $synsc_db_hosts:$path/$dump_file $sync_db_dir; gzip -d  $sync_db_dir/$dump_file -c > $sync_db_dir/sync_dump.sql };
  }

  if(! $cmd  ) {
    if($debug) {
      print "Error: not find download cmd\n";
    }
    return 0;
  }

  cmd($cmd, {
    DEBUG   => ($debug && $debug > 2) ? $debug - 1 : undef,
    PARAMS  => { DATE  => $DATE },
    timeout => 0
  });

  return "$sync_db_dir/sync_dump.sql";
}

#**********************************************************
=head2 upload_dump($attr) - List users

  Arguments:
    $attr

  Returns
    TRUE or FALSE

=cut
#**********************************************************
sub upload_dump {
  my ($dump_file) = @_;

  my $db_name = $conf{SYNC_DB_NAME} || q{axbills};
  if($debug > 1) {
    print "push dump '$dump_file' to $db_name\n";
  }

  if( -f $dump_file) {
    my $MYSQL = 'mysql';
    my $cmd = qq{ $MYSQL --default-character-set=$conf{dbcharset} --host=$conf{dbhost} --user="$conf{dbuser}" --password="$conf{dbpasswd}" $db_name < $dump_file };
    cmd($cmd, {
      DEBUG   => ($debug && $debug > 2) ? 1 : undef,
      timeout => 0
    });

    return 1;
  }

  return 0;
}

#**********************************************************
=head2 upload_dump($attr) - List users

  Arguments:
    $attr

  Returns
    TRUE or FALSE

=cut
#**********************************************************
sub sync_db_help {

print << "[END]";
Sync DB
Download dumps and add it to db

  \$conf{SYNC_DB_HOST}='192.168.1.100:22:/usr/axbills/backup/';

  \$conf{SYNC_DB_DOWNLOAD}='scp asm\@192.168.1.100:22:/usr/axbills/backup/stats-%DATE%.sql.gz /usr/axbills/backup/stats-%DATE%.sql.gz; '
   .'gzip -d /usr/axbills/backup/stats-%DATE%.sql.gz --name /usr/axbills/backup/sync_dump.sql';

  \$conf{SYNC_DB_NAME}='axbills_3';


[END]
}

1;
