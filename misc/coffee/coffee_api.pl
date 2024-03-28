#!/usr/bin/perl

=head1 NAME coffee_api.pl

  SOAP API to control Belkin WEMO based Mr. Coffee

=cut
use strict;
use warnings FATAL => 'all';

use lib '../../';
use lib '../../lib/'; #Assuming we are in /usr/axbills/misc/coffee
use lib '../../AXbills/mysql';

use AXbills::Defs;
use AXbills::Base qw( cmd parse_arguments _bp );
require "AXbills/Misc.pm";

=head3 Request template

POST <Service URL> HTTP/1.1
Content-Length: <variable>
SOAPACTION: "<Service Type>#<Method>"
Content-Type: text/xml; charset="utf-8"
Accept: ""

<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body>
<u:<Method> xmlns:u="<Service Type>">
<<Variable>><Value></<Variable>>
</u:<Method>>
</s:Body>
</s:Envelope>

=cut
=head3 Set Jarden Status

POST <Service URL> HTTP/1.1
Content-Length: <variable>
SOAPACTION: "SOAPACTION: \"urn:Belkin:service:basicevent:1#GetJardenStatus"
Content-Type: text/xml; charset="utf-8"
Accept: ""


=cut

my %arguments = ();


my $host = '192.168.0.109';
my $port = get_port();
my $debug = 0;

print "Started \n";

my $services_events = {
  basic_event => {
    type    => 'urn:Belkin:service:basicevent:1',
    url     => 'upnp/control/basicevent1',
    actions => {
      'GetRuleOverrideStatus' =>
      {
        'arguments' => {
          'RuleOverrideStatus' => 1
        }
      },
      'ChangeDeviceIcon'      =>
      {
        'arguments' => {
          'PictureHeight'    => 1,
          'PictureColorDeep' => 1,
          'PictureSize'      => 1
        }
      },
      'GetSerialNo'           =>
      {
        'arguments' => { }
      },
      'ShareHWInfo'           =>
      {
        'arguments' => {
          'PluginKey'    => 1,
          'Serial'       => 1,
          'Udn'          => 1,
          'Mac'          => 1,
          'HomeId'       => 1,
          'RestoreState' => 1
        }
      },
      'GetWatchdogFile'       =>
      {
        'arguments' => {
          'WDFile' => 1
        }
      },
      'SetDeviceId'           =>
      {
        'arguments' => {
          'SetDeviceId' => 1
        }
      },
      'SetLogLevelOption'     =>
      {
        'arguments' => {
          'Level'  => 1,
          'Option' => 1
        }
      },
      'SetMultiState'         =>
      {
        'arguments' => {
          'state' => 1
        }
      },
      'ControlCloudUpload'    =>
      {
        'arguments' => {
          'EnableUpload' => 1
        }
      },
      'SetCrockpotState'      =>
      {
        'arguments' => {
          'mode' => 1,
          'time' => 1
        }
      },
      'SetSmartDevInfo'       =>
      {
        'arguments' => {
          'SmartDevURL' => 1
        }
      },
      'SetServerEnvironment'  =>
      {
        'arguments' => {
          'TurnServerEnvironment' => 1,
          'ServerEnvironment'     => 1,
          'ServerEnvironmentType' => 1
        }
      },
      'GetLogFileURL'         =>
      {
        'arguments' => {
          'LOGURL' => 1
        }
      },
      'GetServerEnvironment'  =>
      {
        'arguments' => {
          'ServerEnvironment'     => 1,
          'ServerEnvironmentType' => 1,
          'TurnServerEnvironment' => 1
        }
      },
      'GetJardenStatus'       =>
      {
        'arguments' => {
          'timeStamp'  => 1,
          'cookedTime' => 1,
          'time'       => 1,
          'mode'       => 1
        }
      },
      'GetSignalStrength'     =>
      {
        'arguments' => {
          'SignalStrength' => 1
        }
      },
      'GetFriendlyName'       =>
      {
        'arguments' => {
          'FriendlyName' => 1
        }
      },
      'ChangeFriendlyName'    =>
      {
        'arguments' => {
          'FriendlyName' => 1
        }
      },
      'ReSetup'               =>
      {
        'arguments' => {
          'Reset' => 1
        }
      },
      'GetSmartDevInfo'       =>
      {
        'arguments' => { }
      },
      'GetDeviceIcon'         =>
      {
        'arguments' => {
          'DeviceIcon' => 1
        }
      },
      'GetCrockpotState'      =>
      {
        'arguments' => {
          'cookedTime' => 1,
          'timeStamp'  => 1,
          'mode'       => 1,
          'time'       => 1
        }
      },
      'SetBinaryState'        =>
      {
        'arguments' => {
          'BinaryState' => 1
        }
      },
      'GetDeviceId'           =>
      {
        'arguments' => { }
      },
      'GetBinaryState'        =>
      {
        'arguments' => {
          'BinaryState' => 1
        }
      },
      'GetMacAddr'            =>
      {
        'arguments' => { }
      },
      'GetPluginUDN'          =>
      {
        'arguments' => { }
      },
      'SetJardenStatus'       =>
      {
        'arguments' => {
          'time' => 1,
          'mode' => 1
        }
      },
      'GetIconURL'            =>
      {
        'arguments' => {
          'URL' => 1
        }
      },
      'SetHomeId'             =>
      {
        'arguments' => {
          'SetHomeId' => 1
        }
      },
      'GetHomeId'             =>
      {
        'arguments' => { }
      }
    },
  },

};

main();

#**********************************************************
=head2 main()

=cut
#**********************************************************
sub main{
  %arguments = %{ parse_arguments( \@ARGV ) };

  if ( $arguments{HOST} ){
    $host = $arguments{HOST};
  }

  if ( $arguments{BREW} ){
    print make_request( 'basic_event', 'GetMacAddr' );

    print "\n\n";

    print make_simple_request(qq{<?xml version="1.0" encoding="utf-8"?>
                        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                           <s:Body>
                              <u:SetAttributes xmlns:u="urn:Belkin:service:deviceevent:1">
                                 <attributeList>&lt;attribute&gt;&lt;name&gt;Mode&lt;/name&gt;&lt;value&gt;4&lt;/value&gt;&lt;/attribute&gt;&lt;attribute&gt;&lt;name&gt;ModeTime&lt;/name&gt;&lt;value&gt;NULL&lt;/value&gt;&lt;/attribute&gt;&lt;attribute&gt;&lt;name&gt;TimeRemaining&lt;/name&gt;&lt;value&gt;NULL&lt;/value&gt;&lt;/attribute&gt;&lt;attribute&gt;&lt;name&gt;WaterLevelReached&lt;/name&gt;&lt;value&gt;NULL&lt;/value&gt;&lt;/attribute&gt;&lt;attribute&gt;&lt;name&gt;CleanAdvise&lt;/name&gt;&lt;value&gt;NULL&lt;/value&gt;&lt;/attribute&gt;&lt;attribute&gt;&lt;name&gt;FilterAdvise&lt;/name&gt;&lt;value&gt;NULL&lt;/value&gt;&lt;/attribute&gt;&lt;attribute&gt;&lt;name&gt;Brewing&lt;/name&gt;&lt;value&gt;NULL&lt;/value&gt;&lt;/attribute&gt;&lt;attribute&gt;&lt;name&gt;Brewed&lt;/name&gt;&lt;value&gt;NULL&lt;/value&gt;&lt;/attribute&gt;&lt;attribute&gt;&lt;name&gt;Cleaning&lt;/name&gt;&lt;value&gt;NULL&lt;/value&gt;&lt;/attribute&gt;&lt;attribute&gt;&lt;name&gt;LastCleaned&lt;/name&gt;&lt;value&gt;NULL&lt;/value&gt;&lt;/attribute&gt;</attributeList>
                              </u:SetAttributes>
                           </s:Body>
                        </s:Envelope>});

#    print make_request( 'basic_event', 'GetDeviceId' );
  }

  exit( 0 );
}



#**********************************************************
#
#**********************************************************
sub form_xml_request_arguments{
  my ($arguments) = @_;

  my $result = "";

  while (my ($action_name, $action_value) = each %{$arguments}) {
    $result .= "<$action_name>$action_value</$action_name>";
  }

  if ( scalar ( keys %{$arguments} ) > 1 ){
    $result = "<arg0>$result</arg0>";
  }

  return $result;
}

#**********************************************************
#
#**********************************************************
sub get_port{
  my $de_port = 49152;


  print "Looking for port : ";
  my $command = "curl --connect-timeout 1 -s $host:$de_port  -D 'asd'" if ($debug);
  my $response = cmd( $command, { SHOW_RESULT => 1, timeout => 1 } );

  my $port = ( grep $response, '404' ) ? $de_port : 49153;

  print $port . "\n";

  return $port;
}

sub make_request{
  my ($service_name, $action_name) = @_;

  my $service_type = $services_events->{$service_name}->{type};
  my $service_url = $services_events->{$service_name}->{url};

  unless ( defined $services_events->{$service_name}->{actions}->{$action_name} ){
    print "\n\n Error: Unexistent action $action_name";
    return 0;
  }

  my $arguments = form_xml_request_arguments( $services_events->{$service_name}->{actions}->{$action_name}->{arguments} );

  my $data = << "EOF";
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body>
<u:$action_name xmlns:u="$service_type">
$arguments
</u:$action_name>
</s:Body>
</s:Envelope>
EOF

  $data =~ s/[\n]//g;
  #  $data =~ s/[\s]*//g;

  my $content_length = length( $data );
  $data =~ s/["]/\\\"/g;

  print "Sending request:  \n $data \n\n" if ($debug);

  my $result = web_request( "http://$host:$port/$service_url",
    {
      POST    => $data,
      CURL    => 1,
      HEADERS =>
      [
        "Content-Length: " . $content_length,
        "SOAPACTION: " . '\"' . $service_type . "#" . $action_name . '\"',
        'Content-Type: text/xml; charset=\"utf-8\"',
        'Accept: \"\"'
      ],
      TIMEOUT => 30
    }
  );

  return $result;
}

#**********************************************************
=head2 make_simple_request()

=cut
#**********************************************************
sub make_simple_request {
  my ($data) = @_;

  print "Sending request:  \n $data \n\n" if ($debug);

  my $data_length = length $data;

  my $result = web_request( "http://$host:$port/upnp/control/basicevent1",
    {
      POST    => $data,
      CURL    => 1,
      HEADERS =>
      [
        "Content-Length: " . $data_length,
        "SOAPACTION: " . '\"basic_event#SetMultiState\"',
        'Content-Type: text/xml; charset=\"utf-8\"',
        'Accept: \"text/xml\"'
      ],
      TIMEOUT => 30
    }
  );

  return $result;
}

1;