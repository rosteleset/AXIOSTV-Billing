#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

=head1 NAME mikrotik_hotspot.pl

  Automatization of hotspot configuration on mikrotik

=head2 VERSION 1.0
=head2 SYNOPSIS

  This program automates Mikrotik configuration

=head2 USAGE

  Operations:
    BACKUP                - make non-encrypted backup
    UPLOAD_KEY            - upload SSH public key (Only interactive mode)
    CONFIGURE_HOTSPOT     - configure hotspot (Only interactive mode)
    UPLOAD_CAPTIVE_PORTAL - uplodad HTML files for captive portal

  IP_ADDRESS         - Mikrotik IP address
  MASK               - Mikrotik Subnet mask
  SSH_PORT           - Mikrotik SSH port
  LOGIN              - Mikrotik administrator LOGIN

  BILLING_IP_ADDRESS - ABillS Server IP Addres
  RADIUS_SECRET      - Radius secret password

  HOTSPOT_INTERFACE  - Interface on which hotspot will be run
  HOTSPOT_ADDRESS    - Local Hotspot interface address
  HOTSPOT_NETWORK    - Local Hotspot interface network
  HOTSPOT_NETMASK    - Local Hotspot interface netmask
  MIKROTIK_GATEWAY   - Mikrotik WAN interface gateway
  DHCP_RANGE         - Local Hotspot interface DHCP clients range
  MIKROTIK_DNS       - DNS servers to use

  REMOTE_ADMIN_NAME  - ABillS admin for Mikrotik Login
  IDENTITY_FILE      - Path to SSH public key
  BACKUP_AUTO        - Backup using SSH certificate (Will not ask you for password)
  CERTS_DIR          - Directory where your SSH certificates are located

  SSH_FILE           - Path to SSH executive
  SCP_FILE           - Path to SCP executive
  PING_FILE          - Path to Ping executive

  NON_INTERACTIVE    - Die if need user input

  # Default values
    'UPLOAD_KEY'         => 'n',
    'BACKUP'             => 'n',
    'CONFIGURE_HOTSPOT'  => 'n',
    'BACKUP_AUTO'        => 'n',
    'SSH_PORT'           => '22',
    'RADIUS_SECRET'      => 'secretpass',
    'CERTS_DIR'          => '/usr/axbills/Certs/',
    'IDENTITY_FILE'      => '/usr/axbills/Certs/id_rsa.axbills_admin',
    'REMOTE_ADMIN_NAME'  => 'axbills_admin',
    'LOGIN'              => 'admin',
    'MASK'               => '255.255.255.0',
    'HOTSPOT_INTERFACE'  => 'ether2',
    'BACKUP_FILE'        => '\$IP_ADDRESS_\$DATE.backup',
    'HOTSPOT_ADDRESS'    => '192.168.4.1',
    'HOTSPOT_NETWORK'    => '192.168.4.0',
    'HOTSPOT_NETMASK'    => '24',
    'MIKROTIK_GATEWAY'   => '192.168.0.1',
    'DHCP_RANGE'         => '192.168.4.3-192.168.4.254',
    'MIKROTIK_DNS'       => '8.8.8.8',
    'HOTSPOT_DNS_NAME'   => 'hotspot.billing.axiostv.ru'

=head2 EXAMPLES

  Full automatic backup creation
  # ./mikrotik_hotspot.pl BACKUP=y BACKUP_AUTO=y BACKUP_FILE=fresh.backup NON_INTERACTIVE=y

  Configure Hotspot on Mikrotik where keys are already uploaded
  # ./mikrotik_hotspot.pl CONFIGURE_HOTSPOT=y IP_ADDRESS=192.168.0.60 BILLING_IP_ADDRESS=192.168.0.62

  Configure Hotspot on default configuration Mikrotik 192.168.0.60 and interface for Hotspot wlan1
  # ./mikrotik_hotspot.pl CONFIGURE_HOTSPOT=y IP_ADDRESS=192.168.0.60 BILLING_IP_ADDRESS=192.168.0.62 UPLOAD_KEY=y HOTSPOT_INTERFACE=wlan1

  Configure using previous configuration
  # ./mikrotik_hotspot.pl READ_CONFIG=192.168.0.64.arguments

=cut

my $usage = " mikrotik_hotspot.pl USAGE

  Operations:
    BACKUP            - make non-encrypted backup
    UPLOAD_KEY        - upload SSH public key (Only interactive mode)
    CONFIGURE HOTSPOT - configure hotspot (Only interactive mode)

  IP_ADDRESS         - Mikrotik IP address
  MASK               - Mikrotik Subnet mask
  SSH_PORT           - Mikrotik SSH port
  LOGIN              - Mikrotik administrator LOGIN
  
  BILLING_IP_ADDRESS - ABillS Server IP Addres
  RADIUS_SECRET      - Radius secret password

  HOTSPOT_INTERFACE  - Interface on which hotspot will be run
  HOTSPOT_ADDRESS    - Local Hotspot interface address
  HOTSPOT_NETWORK    - Local Hotspot interface network
  HOTSPOT_NETMASK    - Local Hotspot interface netmask
  MIKROTIK_GATEWAY   - Mikrotik WAN interface gateway
  DHCP_RANGE         - Local Hotspot interface DHCP clients range
  MIKROTIK_DNS       - DNS servers to use
  
  REMOTE_ADMIN_NAME  - ABillS admin for Mikrotik Login
  IDENTITY_FILE      - Path to SSH public key
  BACKUP_AUTO        - Backup using SSH certificate (Will not ask you for password)
  CERTS_DIR          - Directory where your SSH certificates are located

  SSH_FILE           - Path to SSH executive
  SCP_FILE           - Path to SCP executive
  PING_FILE          - Path to Ping executive

  NON_INTERACTIVE    - Die if need user input

  # Default values
    'UPLOAD_KEY'         => 'n',
    'BACKUP'             => 'n',
    'CONFIGURE_HOTSPOT'  => 'n',
    'BACKUP_AUTO'        => 'n',
    'SSH_PORT'           => '22',
    'RADIUS_SECRET'      => 'secretpass',
    'CERTS_DIR'          => '/usr/axbills/Certs/',
    'IDENTITY_FILE'      => '/usr/axbills/Certs/id_rsa.axbills_admin',
    'REMOTE_ADMIN_NAME'  => 'axbills_admin',
    'LOGIN'              => 'admin',
    'MASK'               => '255.255.255.0',
    'HOTSPOT_INTERFACE'  => 'ether2',
    'BACKUP_FILE'        => '\$IP_ADDRESS_\$DATE.backup',
    'HOTSPOT_ADDRESS'    => '192.168.4.1',
    'HOTSPOT_NETWORK'    => '192.168.4.0',
    'HOTSPOT_NETMASK'    => '24',
    'MIKROTIK_GATEWAY'   => '192.168.0.1',
    'DHCP_RANGE'         => '192.168.4.3-192.168.4.254',
    'MIKROTIK_DNS'       => '8.8.8.8',
    'HOTSPOT_DNS_NAME'   => 'hotspot.billing.axiostv.ru'

  Full automatic backup creation
  # ./mikrotik_hotspot.pl BACKUP=y BACKUP_AUTO=y BACKUP_FILE=fresh.backup NON_INTERACTIVE=y

  Configure Hotspot on Mikrotik where keys are already uploaded
  # ./mikrotik_hotspot.pl CONFIGURE_HOTSPOT=y IP_ADDRESS=192.168.0.60 BILLING_IP_ADDRESS=192.168.0.62

  Configure Hotspot on default configuration Mikrotik 192.168.0.60 and interface for Hotspot wlan1
  # ./mikrotik_hotspot.pl CONFIGURE_HOTSPOT=y IP_ADDRESS=192.168.0.60 BILLING_IP_ADDRESS=192.168.0.62 UPLOAD_KEY=y HOTSPOT_INTERFACE=wlan1

  Configure using previous configuration
  # ./mikrotik_hotspot.pl READ_CONFIG=192.168.0.64.arguments

";

BEGIN {
  use FindBin '$Bin';
  use lib "$Bin/../../../lib";
}

use AXbills::Base;
#use AXbills::Nas::Mikrotik;

#use AXbills::Misc;

# Defaults
my %arguments = (
  'UPLOAD_KEY'         => 'n',
  'BACKUP'             => 'n',
  'CONFIGURE_HOTSPOT'  => 'n',
  'BACKUP_AUTO'        => 'n',
  'SSH_PORT'           => '22',
  'RADIUS_SECRET'      => 'secretpass',
  'CERTS_DIR'          => '/usr/axbills/Certs/',
  'IDENTITY_FILE'      => '/usr/axbills/Certs/id_rsa.axbills_admin',
  'REMOTE_ADMIN_NAME'  => 'axbills_admin',
  'LOGIN'              => 'admin',
  'MASK'               => '255.255.255.0',
  'HOTSPOT_INTERFACE'  => 'ether2',
  'BACKUP_FILE'        => '\$IP_ADDRESS_\$DATE.backup',
  'HOTSPOT_ADDRESS'    => '192.168.4.1',
  'HOTSPOT_NETWORK'    => '192.168.4.0',
  'HOTSPOT_NETMASK'    => '24',
  'MIKROTIK_GATEWAY'   => '192.168.0.1',
  'DHCP_RANGE'         => '192.168.4.3-192.168.4.254',
  'MIKROTIK_DNS'       => '8.8.8.8',
  'HOTSPOT_DNS_NAME'   => 'hotspot.billing.axiostv.ru',
  'UPLOAD_CAPTIVE_PORTAL' => 'n'
);

my $arguments_describe = {
  IP_ADDRESS         => {
    describe => "Mikrotik IP address"
  },
  MASK               => {
    describe => "Mikrotik Subnet mask",
    default  => '255.255.255.0'
  },
  SSH_PORT           => {
    describe => "Mikrotik SSH port",
    default  => '22'
  },
  LOGIN              => {
    describe => "Mikrotik administrator LOGIN",
    default  => "admin"
  },
  BILLING_IP_ADDRESS => {
    describe => "ABillS Server IP Address"
  },
  RADIUS_SECRET      => {
    describe => "Radius secret password",
    default  => "secretpass"
  },
  REMOTE_ADMIN_NAME  => {
    describe => 'ABillS admin for Mikrotik Login',
    default  => 'axbills_admin'
  },
  IDENTITY_FILE      => {
    describe => "Path to SSH public key",
    default  => "/usr/axbills/Certs/id_rsa.axbills_admin"
  },
  BACKUP_AUTO        => {
    describe => 'Backup using SSH certificate (Will not ask you for password)',
    default  => "N"
  },
  CERTS_DIR          => {
    describe => "Directory where your SSH certificates are located"
  },
  HOTSPOT_INTERFACE  => {
    describe => "Interface on which Hotspot will be run",
    default  => "ether2"
  }

};



my $base_dir = "/usr/axbills";
$arguments{CERTS_DIR} = "$base_dir/Certs/";

my $debug = 1;

main();
#guess_ip();

#**********************************************************
=head2 main() - Entry point

=cut
#**********************************************************
sub main{

  if ( scalar @ARGV == 0 ){
    print $usage;
    exit( 1 );
  }

  my $passed_args = parse_arguments( \@ARGV );

  # We will read from STDIN so need to clear @ARGV
  @ARGV = ();

  # Merging defaults and passed arguments
  %arguments = (%arguments, %{$passed_args});

  if ( $arguments{READ_CONFIG} ){
    %arguments = %{ read_config( $arguments{READ_CONFIG} ) }
  }

  unless ( $arguments{SSH_FILE} ) { $arguments{SSH_FILE} = cmd( "which ssh" ); chomp($arguments{SSH_FILE});}
  unless ( $arguments{SCP_FILE} ) { $arguments{SCP_FILE} = cmd ( "which scp" ); chomp($arguments{SCP_FILE});}
  unless ( $arguments{PING_FILE} ) { $arguments{PING_FILE} = cmd ( "which ping" ); chomp($arguments{PING_FILE});}

  need_values(
    qw( IP_ADDRESS MASK SSH_PORT LOGIN )
  );

  unless ( host_is_reachable( $arguments{IP_ADDRESS} ) ){
    die ( "Host $arguments{IP_ADDRESS} is not available" );
  }

  $debug = $arguments{DEBUG} || 0;

  my $to_make_backup = request_value( 'BACKUP', "Make backup", "Y" );
  if ( $to_make_backup =~ /y|1/i ){

    need_values( "BACKUP_AUTO" );

    if ( $arguments{BACKUP_AUTO} =~ /y|1/i ){
      # Check if SSH pubkey autentification is already configured

      need_values( qw(REMOTE_ADMIN_NAME IDENTITY_FILE) );

      $arguments{BACKUP_AUTO} = check_ssh_pubkey_auth(
        $arguments{IP_ADDRESS},
        $arguments{REMOTE_ADMIN_NAME},
        $arguments{IDENTITY_FILE}
      );
    }

    make_backup( $arguments{BACKUP_FILE} );
  }

  my $upload_key = request_value( 'UPLOAD_KEY', "Upload SSH key", "Y" );
  if ( $upload_key =~ /y|1/i ){

    need_values( qw( REMOTE_ADMIN_NAME CERTS_DIR ) );
    upload_key( $arguments{REMOTE_ADMIN_NAME}, $arguments{CERTS_DIR} );
  }

  my $configure_hotspot = request_value( "CONFIGURE_HOTSPOT", "Configure Mikrotik Hotspot", "Y" );
  if ( $configure_hotspot =~ /y|1/i ){

    need_values( qw( BILLING_IP_ADDRESS RADIUS_SECRET REMOTE_ADMIN_NAME IDENTITY_FILE ) );

    $arguments{BACKUP_AUTO} = check_ssh_pubkey_auth(
      $arguments{IP_ADDRESS},
      $arguments{REMOTE_ADMIN_NAME},
      $arguments{IDENTITY_FILE}
    );

    configure_hotspot();

    print " \n
#######################################################################
#
#  Hotspot has been configured.
#
#  Add new NAS type mikrotik in АСР AXbills to allow RADIUS authorization.
#
#  You'll also will need Cards and Paysys module for automatic user registration
#
#  Visit https://billing.axiostv.ru/
#
#######################################################################
      ";
  }

  if ( $arguments{UPLOAD_CAPTIVE_PORTAL} =~ /y|1/i ){
    upload_captive_portal();
  }

  if ( !$arguments{READ_CONFIG} ){
    write_config();
  }

  print "\n  Program finished normally \n";
  exit( 0 );
}

#**********************************************************
=head2 ssh($command) - Execute command in remote console

  Arguments:
    $command - string  or array of strings
    $attr - hash_ref
      SAVE_TO         - filename to save output
      SKIP_ERROR      - do not finish execution if error on one of commands
      SYSTEM_ADMIN    - if specified, ssh will use mikrotik System admin account
      GET_SSH_COMMAND - returns command that will be executed in console
      CHAINED         - print a dot when each command executed

  Returns:
    1
    
=cut
#**********************************************************
sub ssh{
  my ($command, $attr) = @_;
  my $identity_file_option = '';

  if ( defined $attr->{SYSTEM_ADMIN} ){
    need_values( "LOGIN" );
  }
  else{
    need_values( "REMOTE_ADMIN_NAME" );

    $arguments_describe->{IDENTITY_FILE}->{default} = "$base_dir/Certs/id_rsa.$arguments{REMOTE_ADMIN_NAME}";
    request_value( 'IDENTITY_FILE', "Path to SSH public key", "$base_dir/Certs/id_rsa.$arguments{REMOTE_ADMIN_NAME}" );

    $identity_file_option = "-i $arguments{IDENTITY_FILE}";
  }

  my $login = (defined $attr->{SYSTEM_ADMIN}) ? $arguments{LOGIN} : $arguments{REMOTE_ADMIN_NAME};

  my $port_option = '';
  if ( $arguments{SSH_PORT} ne '22' ){
    $port_option = " -p $arguments{SSH_PORT}";
  }

  $attr->{SSH_COMMAND_BASE} = "$arguments{SSH_FILE} $identity_file_option -o StrictHostKeyChecking=no $port_option $login\@$arguments{IP_ADDRESS} ";

  if ( $attr->{GET_SSH_COMMAND} ){
    return $attr->{SSH_COMMAND_BASE};
  }

  if ( ref $command eq 'ARRAY' ){
    #    print "\n" if ($attr->{CHAINED});
    foreach my $comman ( @{$command} ){
      my $result = ssh_single( $comman, $attr );
      # Handle result
      if ( !$result ){
        print " \n Error executing $comman \n" if ($debug > 1);
        print "x" if ($attr->{CHAINED});
        last unless ($attr->{SKIP_ERROR});
      } else{
        print "." if ($attr->{CHAINED});
      }
    }
    print "\n" if ($attr->{CHAINED});
  }
  else{
    ssh_single( $command, $attr );
  }
  return 1;
}

#**********************************************************
=head2 ssh_single($command, $attr) - executes single command via SSH

  Arguments:
    $command - command to execute
    $attr
      SAVE_TO          - file to save result
      SSH_COMMAND_BASE - ssh connection command

  Returns:
   1 if success or 0

=cut
#**********************************************************
sub ssh_single{
  my ($command, $attr) = @_;

  my $export_file_postfix = '';
  if ( $attr->{SAVE_TO} ){
    $export_file_postfix = " > $attr->{SAVE_TO}";
  }

  # Form command
  my $com_base = $attr->{SSH_COMMAND_BASE};
  my $com = $com_base . "'$command' $export_file_postfix";

  print "\n $com \n" if ($debug > 1);
  print "\n Executing :  $command \n" if ($debug > 1);

  # Execute
  my $result = cmd( $com, { timeout => 30, %{$attr} } );

  # Handle result;
  if ( $result ne '' ){
    if ( $result =~ /error|failure|missing|ambiguos|invalid|does not match|expected/i ){
      print "\n Error : $result" if ($debug);
      return 0;
    }
    else{
      print "\n Result : $result \n" if ($debug > 1);
    }
  }

  return 1;

}

#**********************************************************
=head2 need_values($array_of_params)

  Arguments:
    $array_of_params

  Returns:
    1
=cut
#**********************************************************
sub need_values{
  my (@array_of_params) = @_;

  foreach my $param_name ( @array_of_params ){
    if ( $arguments{$param_name} ){ next };

    request_value( $param_name, $arguments_describe->{$param_name}->{describe},
      $arguments_describe->{$param_name}->{default} );
  }

  return 1;
}

#**********************************************************
=head2 request_value($name, $describe, $default_value) - get value from arguments or user input

  Arguments:
    $name          - name of key in %arguments
    $describe      - description of parameter
    $default_value - (optional) default_value that will be offered to user

  Returns:
   value

=cut
#**********************************************************
sub request_value($$;$$){
  my ($name, $describe, $default_value, $attr) = @_;

  if ( defined $arguments{$name} ){
    return $arguments{$name};
  }

  if ( $arguments{NON_INTERACTIVE} ){
    die "\n !!! Need $name ";
  }

  my $result = '';
  if ( defined $default_value ){
    print "$describe [$default_value] : ";
    $result = <>;
    chomp( $result );

    if ( $result eq '' ){
      $result = $default_value;
      print "\n $describe : $result \n" if ($debug);
    }
  }
  else{

    while ( $result eq '' && !$attr->{ALLOW_EMPTY} ){
      print " Request $name \n" if ($debug > 1);
      print "$describe : ";
      $result = <>;
      chomp( $result );
    }

  }

  $arguments{$name} = $result;
  return $result;
}

#**********************************************************
=head2 make_BACKUP($filename)

  Arguments:
    $filename(optional) - file to save config_to;

  Returns:
    1

=cut
#**********************************************************
sub make_backup{
  my ($filename) = @_;

  unless ( defined $filename ){
    my $name = localtime();
    $name =~ s/ /_/g;
    $name =~ s/[:]/_/g;
    $filename = "$arguments{IP_ADDRESS}_$name.backup";
  }

  print "\n Starting backup \n";

  my %arguments_for_backup = (
    SAVE_TO      => $filename,
    SYSTEM_ADMIN => 1
  );

  if ( $arguments{BACKUP_AUTO} =~ /y|1/i ){

    need_values( qw( REMOTE_ADMIN_NAME IDENTITY_FILE ) );

    print "\n Testing access via pub key : ";

    my $access_granted = check_ssh_pubkey_auth(
      $arguments{IP_ADDRESS},
      $arguments{REMOTE_ADMIN_NAME},
      $arguments{IDENTITY_FILE}
    );

    if ( $access_granted =~ /y|1/i ){
      print " Successfull \n";
      delete $arguments_for_backup{SYSTEM_ADMIN};
    }
    else{
      print " Failed. using $arguments{LOGIN} account  \n";
    };

  }

  ssh( "/export", \%arguments_for_backup );

  if ( -e $filename && -s $filename ){
    print "\n Successfully backuped configuration to $filename \n";
  }
  else{
    print "\n !!! Backup failed \n";
  }

  return 1;

}

#**********************************************************
=head2 upload_key($admin_name, $certs_dir)

  Arguments:
    $admin_name - name for ABillS administrator on Mikrotik
    $certs_dir - path to Certs directory

  Returns:
    1

=cut
#**********************************************************
sub upload_key{
  my ($admin_name, $certs_dir) = @_;

  my $id_rsa_file = "id_rsa.$admin_name";

  if ( !-e $id_rsa_file ){
    # generate and upload certificate
    print "  Generating certificate \n";
    my $cmd = qq { $base_dir/misc/certs_create.sh ssh $admin_name SKIP_CERT_UPLOAD };
    system ( $cmd );
    $arguments{IDENTITY_FILE} = "$certs_dir/id_rsa.$admin_name";
  }
  else{
    print "  Certificate exists \n";
  }

  print "  Uploading certificate \n";
  my $cmd = "$arguments{SCP_FILE} -o BatchMode=yes -o StrictHostKeyChecking=no $certs_dir/$id_rsa_file.pub $arguments{LOGIN}\@$arguments{IP_ADDRESS}:/";
  my $res = cmd( $cmd, { SHOW_RESULT => 1, timeout => 30 } );
  print $res;

  print "  Adding new user $admin_name \n";
  my $password = mk_unique_value( 15 );
  ssh(
    " /user add name=$admin_name group=write password=$password;",
    {
      SHOW_RESULT  => 1,
      SYSTEM_ADMIN => 1
    } );

  print "  Importing SSH certificate for $admin_name \n";
  ssh(
    " /user ssh-keys import public-key-file=$id_rsa_file.pub user=$admin_name;",
    {
      SHOW_RESULT  => 1,
      SYSTEM_ADMIN => 1
    } );

  # Give MT some time to import certificate
  sleep 1;

  print "\n Testing access via SSH cert for $admin_name : ";
  my $access_granted = check_ssh_pubkey_auth( $arguments{IP_ADDRESS}, $admin_name, $certs_dir );
  if ( $access_granted =~ /y|1/i ){
    print " Successfull \n";
  };
  ssh (
    [
      '/system identity print;',
      '/system package print where name~"system"'
    ],
    { SHOW_RESULT => 1 }
  );

  return 1;
}

#**********************************************************
=head2 configure_hotspot()

=cut
#**********************************************************
sub configure_hotspot{

  print "\n Prepare Mikrotik \n";

  need_values( "HOTSPOT_INTERFACE" );

  my $interface = $arguments{HOTSPOT_INTERFACE};

  my $range = $arguments{DHCP_RANGE};
  my $address = $arguments{HOTSPOT_ADDRESS};
  my $network = $arguments{HOTSPOT_NETWORK};
  my $netmask = $arguments{HOTSPOT_NETMASK};
  my $gateway = $arguments{MIKROTIK_GATEWAY};
  my $dns_server = $arguments{MIKROTIK_DNS};

  my $dns_name = $arguments{HOTSPOT_DNS_NAME};
  my $pool_name = "hotspot-pool-1";

  ssh(
    [
      # Configure WAN
      qq{/ip address add address=$address/$netmask comment=HOTSPOT disabled=no interface=$interface network=$network},
      qq{/ip route add disabled=no distance=1 dst-address=0.0.0.0/0 gateway=$gateway scope=30 target-scope=10},
      # ADD IP pool for hotspot users
      qq{/ip pool add name=hotspot-pool-1 ranges=$range},
      # Add GOOGLE DNS for resolving
      qq{/ip dns set allow-remote-requests=yes cache-max-ttl=1w cache-size=10000KiB max-udp-packet-size=512 servers=$dns_server}      ,
      # Add DHCP Server
      qq{/ip dhcp-server add address-pool=$pool_name authoritative=after-2sec-delay bootp-support=static disabled=no interface=$interface lease-time=1h name=hotspot_dhcp}      ,
      qq{/ip dhcp-server config set store-leases-disk=5m},
      qq{/ip dhcp-server network add address=$network/$netmask comment="Hotspot network" gateway=$address},
      # Prevent blocking ABillS Server
      qq{/ip hotspot ip-binding add address=$arguments{BILLING_IP_ADDRESS} type=bypassed},
      qq{/ip firewall nat add chain=pre-hotspot dst-address=$arguments{BILLING_IP_ADDRESS} action=accept},
    ],
    {
      SHOW_RESULT => 1,
      SKIP_ERROR  => 1,
      CHAINED     => 1
    }
  );

  print "\n Configuring Hotspot \n";

  ssh(
    [
      # Add HOTSPOT profile
      qq{/ip hotspot profile add name=hsprof1 dns-name=$dns_name hotspot-address=$address html-directory=hotspot http-cookie-lifetime=1d http-proxy=0.0.0.0:0 login-by=cookie,http-chap rate-limit="" smtp-server=0.0.0.0 split-user-domain=no use-radius=yes},
      qq{/ip hotspot add name=hotspot1 address-pool=$pool_name addresses-per-mac=2 disabled=no idle-timeout=5m interface=$interface keepalive-timeout=none  profile=hsprof1},
      qq{/ip hotspot user profile set default idle-timeout=none keepalive-timeout=2m name=default shared-users=1 status-autorefresh=1m transparent-proxy=no },
      qq{/ip hotspot service-port set ftp disabled=yes ports=21},
      qq{/ip hotspot walled-garden ip add action=accept disabled=no dst-address=$address},
      qq{/ip hotspot walled-garden ip add action=accept disabled=no dst-address=$arguments{BILLING_IP_ADDRESS}},
      qq{/ip hotspot set numbers=hotspot1 address-pool=none},
      qq{/ip firewall nat add action=masquerade chain=srcnat disabled=no},
      qq{/ip hotspot user add disabled=no name=admin password=admin profile=default},
      qq{/ip hotspot user add disabled=no name=zaib password=test profile=default server=hotspot1},
      qq{/ip hotspot user add disabled=no name=test-256k password=test profile=default server=hotspot1},
    ],
    {
      SHOW_RESULT => 1,
      SKIP_ERROR  => 1,
      CHAINED     => 1
    }
  );

  print "\n  Configuring RADIUS and Hotspot walled-garden \n";

  ssh(
    [
      "/radius add address=$arguments{BILLING_IP_ADDRESS} secret=$arguments{RADIUS_SECRET} service=hotspot",
      "/ip hotspot profile set hsprof1 use-radius=yes",
      "/radius set timeout=00:00:01 numbers=0",
      "/ip hotspot walled-garden ip add dst-host=8.8.8.8",
      '/ip hotspot walled-garden ip add dst-host=8.8.4.4',
      "/ip hotspot walled-garden ip add dst-host=$arguments{BILLING_IP_ADDRESS}",
      "/ip hotspot walled-garden ip add dst-host=webmoney.ru",
    ],
    {
      SHOW_RESULT => 1,
      SKIP_ERROR  => 1,
      CHAINED     => 1
    }
  );

  request_value( 'UPLOAD_CAPTIVE_PORTAL', "Do you want to upload ABillS Captive portal for Hotspot", "Y" );
  if ( $arguments{'UPLOAD_CAPTIVE_PORTAL'} =~ /y/i ) {
    upload_captive_portal();
  }

  print "\n  Done \n";

  return 1;
}

#**********************************************************
=head2 upload_captive_portal()

=cut
#**********************************************************
sub upload_captive_portal {

  my $command = "cd $base_dir/misc/hotspot/ && ";
  $command .= "tar -xvf hotspot.tar;";
  print "Executing cmd : $command \n" if ($debug > 1);
  cmd ( $command );

  if ( $arguments{BILLING_IP_ADDRESS} ne '10.0.0.2' ) {

    print "\n  Renaming Billing URL \n";

    my $temp_file = '/tmp/hotspot_temp';
    my $login_page = "$base_dir/misc/hotspot/hotspot/login.html";

    $command = "cat $login_page | sed 's/10[.]0[.]0[.]2/$arguments{BILLING_IP_ADDRESS}/g' > $temp_file";
    print "Executing cmd : $command \n" if ($debug > 1);
    cmd( $command );

    $command = "cat $temp_file > $login_page";
    print "Executing cmd : $command \n" if ($debug > 1);
    cmd( $command );
  }

  $command = "";
  $command .= "cd $base_dir/misc/hotspot/; ";
  $command .= "$arguments{SCP_FILE} -r hotspot $arguments{LOGIN}\@$arguments{IP_ADDRESS}:/ ; rm -rf hotspot";
  print "\n  Uploading captive portal files \n";
  print "Executing cmd : $command \n" if ($debug > 1);
  cmd( $command );

  return 1;
}

#**********************************************************
=head2 host_is_available($ip_address) - pings given address

  Arguments:
    $ip_address - IP address

  Returns:
    boolean

=cut
#**********************************************************
sub host_is_reachable{
  my ($ip_address) = @_;

  my $ping = $arguments{PING_FILE} || cmd( "which ping" );
  chomp( $ping );

  print "\n Checking host $ip_address is reachable : ";
  my $res = cmd( "$ping -c 3 -q $ip_address | grep 'received'", { SHOW_RESULT => 1 } );
  print "Res : $res";
  $res = $res =~ /3 received/;

  my $result_string = ($res eq '1') ? "OK" : 'FAIL';
  print " $result_string \n";
  return $res eq '1';
}

#**********************************************************
=head2 check_ssh_pubkey_auth($ip_address, $admin_name, $key_path)

  Arguments:
    $ip_address - Host to check
    $admin_name - login of remote administrator
    $key_path   - path to IdentityFile

  Returns:
    boolean
    
=cut
#**********************************************************
sub check_ssh_pubkey_auth{
  my ($ip_address, $admin_name, $key_path) = @_;

  if ( !-e $key_path ){
    my $answer = request_value( 'CREATE_CERT', "  SSH pub key not exists. Generate and upload?", "Y" );

    if ( $answer =~ /y|1/i ){
      upload_key( $admin_name, $arguments{CERTS_DIR} );
      $arguments{UPLOAD_KEY} = 'n';
    } else{
      return 0;
    }
  }

  my $cmd = "exec $arguments{SSH_FILE} -i $key_path -o BatchMode=yes $admin_name\@$ip_address '/quit' ";

  print "Executing : $cmd \n" if ($debug > 1);
  my $cmd_result = cmd( $cmd, { timeout => 10 } );

  my $result = ($cmd_result =~ /Permission denied/) ? 'n' : 'y';

  print "Result : $result \n" if ($debug > 1);

  return $result;
}

#**********************************************************
=head2 read_config($file_path) read arguments from a file

  Arguments:
    $file_path - path to file writed by write_config()

  Returns:
    hash_ref

=cut
#**********************************************************
sub read_config{
  my ($file_path) = @_;
  my %result = ();

  unless ( -e $file_path ){ die " !!! Not exists : $file_path "; };

  open ( my $config_file, "<", $file_path ) or die " !!! Cannot open $file_path, check permissions ";

  print "\n  Reading configuration from $file_path \n";
  while(my $line = <$config_file>){
    chomp( $line );
    my ($name, $value) = $line =~ /"(.*)"="(.*)"/;

    if ( $name && $value ){
      print "$name = $value \n";
      $result{$name} = $value;
    }

  }

  return \%result;
};

#**********************************************************
=head2 write_config() - write arguments to a file

=cut
#**********************************************************
sub write_config{

  my $content = '';
  foreach my $key ( keys %arguments ){
    $content .= qq{"$key"="$arguments{$key}"\n};
  }

  cmd ( qq{ echo '$content' > $arguments{IP_ADDRESS}.arguments } );

  print "\n  Writed config to $arguments{IP_ADDRESS}.arguments  \n";

  return 1;
}

=head2 AUTHOR Anykey
=head2 THANKS https://aacable.wordpress.com/2011/09/12/mikrotik-hotspot-quick-setup-guide-cli-version/
=cut
1
