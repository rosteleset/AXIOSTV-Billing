#package Sysinfo::Services;
use strict;
use warnings FATAL => 'all';

use AXbills::Base qw/startup_files _bp/;

=head1 NAME

  Sysinfo::Services - 

=head2 SYNOPSIS

  This package  

=cut

our (%conf, $db, $admin, %permissions, %lang, $html);



#**********************************************************
=head2 sysinfo_show_permissions_grant_tip($service_path)

=cut
#**********************************************************
sub sysinfo_show_permissions_grant_tip{
  my ($service_path) = @_;
  
  my @sudoers_pathes = ('/etc/sudoers.d', '/usr/local/etc/sudoers.d', $conf{SYSINFO_SUDOERS_D}  );
  my ($sudoers_path) = grep { -d $_ } @sudoers_pathes;
  
  if ( !$sudoers_path ) {
    $html->message( 'err', $lang{ERROR}, "$lang{YOU_SHOULD_DEFINE}" . ' $conf{SYSINFO_SUDOERS_D} ' );
    return 0;
  }
  elsif ( my $apache_user = sysinfo_get_defined_restart_programs({ONLY => 'WEB_SERVER_USER'}) ) {
    
    my $sudoers_string = "$apache_user ALL=(ALL) NOPASSWD: $service_path";
    $html->message( 'info', $lang{TIP},
      "$lang{EXECUTE} <pre>echo \'$sudoers_string\' >> $sudoers_path/axbills_sudoers</pre> $lang{AS} <strong>root</strong> $lang{TO_GRANT_PERMISSIONS}" );
  }
  else {
    $html->message( 'err', $lang{ERROR},
      $html->button( "$lang{YOU_SHOULD_DEFINE} WEB_SERVER_USER $lang{IN} /usr/axbills/AXbills/programs",
        "index=" . get_function_index('form_prog_pathes'), { class => 'btn btn-success' } )
    );
    
  };
}

#***************************************************************
=head2 sysinfo_get_defined_restart_programs($attr)

=cut
#***************************************************************
sub sysinfo_get_defined_restart_programs {
  my ($attr) = @_;
  
  my $startup_files = startup_files();
  
  return {} unless ($startup_files);
  
  my %restart = ();
  
  if ($attr->{ONLY}){
    return $startup_files->{ uc $attr->{ONLY} };
  }
  
  while (my ($key, $value) = each %$startup_files){
    next unless ($key && $value);
    if ($attr->{SERVICE_NAME_CMD_HASH}){
      next unless $key =~ /RESTART/ && -f $value;
      my ($service_name) = $value =~ /.*\/(.*)$/;
      $restart{$service_name} = $value;
    }
    elsif (( ($key =~ /RESTART/ && -f $value) || $attr->{ALL} ) ) {
      $restart{$key} = $value;
    }
  }
  
  return \%restart;
}


#**********************************************************
=head2 _sysinfo_restart_service($name, $path)

=cut
#**********************************************************
sub _sysinfo_restart_service {
  my ($name) = @_;
  
  if (!$name){
    $html->message('err', $lang{ERR_WRONG_DATA});
    return 0;
  }
  
  close STDERR;
  open (STDERR, '>', '/tmp/web_errors') or do {
    $html->message( 'err', $lang{ERROR}, "Can't open /tmp/web_errors $!" );
    return -1;
  };
  
  my $sudo_name = sysinfo_get_defined_restart_programs({ ONLY => 'SUDO' });
  
  if (!$sudo_name){
    $html->message('err', "$lang{ERROR}", "$lang{YOU_SHOULD_DEFINE} 'SUDO' $lang{IN} AXbills/programs");
    return -1;
  }
  elsif(! -f $sudo_name){
    $html->message('err', "$lang{ERROR}", "$lang{ERR_WRONG_DATA}: 'SUDO' $lang{IN} AXbills/programs"
        . $html->br() . $lang{FILE} . ' ' .$lang{ERR_NOT_EXISTS});
    return -1;
  }
  
  cmd("$sudo_name $name restart", { SHOW_RESULT => 1 });
  
  my $error = file_op({
    FILENAME => 'web_errors',
    PATH   => '/tmp/'
  });
  
  unlink '/tmp/web_errors';
  
  if ( $error && $error !~ /not running\?/) {
    $admin->system_action_add("SI:ERROR $name", { TYPE => 70 });
    $html->message( 'err', $lang{ERROR}, $error );
    return 0;
  }
  
  $admin->system_action_add("SI:SUCCESS $name", { TYPE => 70 });
  
  return 1;
}


1;