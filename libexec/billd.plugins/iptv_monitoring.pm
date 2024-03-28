# billd plugin
=head2 NAME
   
   DESCRIBE: Check active channels for http

=cut
#**********************************************************

iptv_monitoring();


#**********************************************************
#
#
#**********************************************************
sub iptv_monitoring { 
  my $self = shift;
  use Iptv;
  use Data::Dumper;
  my $Iptv    = Iptv->new($db, $Admin, \%conf);
  my $list = $Iptv->channel_list({DESC => '', COLS_NAME => 1, PAGE_ROWS => 10000});
  my %CHANNELS = ();
  my $status = '';
  foreach my $line (@$list) {
    if (!$line->{disable}) {
      $status = check_channel($line->{stream}, $line->{num});
      print "STATUS : $status \t| CHANNEL : $line->{name} \t| STREAM : $line->{stream} \n" if ($debug > 1);
      if ("$line->{status}" ne "$status") {
        $Iptv->query2("UPDATE iptv_channels SET status=$status WHERE id=$line->{id};", 'do');
      } 
    }
  }
}
#**********************************************************
#
#
#**********************************************************
sub check_channel {
  my ($url, $id)=@_;
  if ($url =~ /^http:\/\// ) {
    my $out = `wget -q -O /tmp/ch_mon.mpg "$url" >/dev/null 2>&1 & sleep 1; kill \$!; ls -l /tmp/ch_mon.mpg | cut -f 5 -d ' ' && rm /tmp/ch_mon.mpg`;
    return ($out =~ /[1-9]/) ? 1 : 0;    
  }
}

1
