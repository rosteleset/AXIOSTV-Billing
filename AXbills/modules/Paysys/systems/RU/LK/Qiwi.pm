=head1 NAME

  OSMP Qiwi

=cut
#**********************************************************
# OSMP - Qiwi
# Qiwi version 4.00
#
# version 0.4
#**********************************************************

my $version          = 0.4;
my $protocol_version = 4.00;
my $CURL             = $conf{FILE_CURL} || '/usr/local/bin/curl';

$debug = 0;

if ($conf{PAYSYS_DEBUG} > 2) {
	$debug = 1;
}


#**********************************************************
=head2 qiwi_status($attr)

=cut
#**********************************************************
sub qiwi_status {
  my ($attr) = @_;

  $debug = $attr->{DEBUG} if ($attr->{DEBUG});

  my $request = qq{<?xml version="1.0" encoding="utf-8"?>
<request>
<protocol-version>$protocol_version</protocol-version>
<request-type>33</request-type>
<terminal-id>$conf{PAYSYS_QIWI_TERMINAL_ID}</terminal-id>
<extra name="password">$conf{PAYSYS_QIWI_PASSWD}</extra>
<bills-list>};

  foreach my $id (@{ $attr->{IDS} }) {
    $request .= "<bill txn-id=\"$id\" />\n";
  }

  $request .= qq{</bills-list>
</request> };

  return mk_request($request, $attr);
}

#**********************************************************
=head2 mk_request($request, $attr)

=cut
#**********************************************************
sub mk_request {
  my ($request, $attr) = @_;

  $request =~ s/"/\\"/g;
  open STDERR, '/dev/null';

  my $url = ($conf{dbcharset} ne 'utf8') ? 'http://ishop.qiwi.ru/xmlcp' : 'http://ishop.qiwi.ru/xml';
  my $result = `$CURL --header "Content-Type: text/xml" -d "$request" $url`;
  $debug = $attr->{DEBUG} if ($attr->{DEBUG});

  if ($debug > 0) {
    print "Content-Type: text/html\n\n";
    print "=====REQUEST=====<br>\n";
    print qq{<textarea cols=90 rows=10>$CURL  --header "Content-Type: text/xml" -d "$request" $url</textarea><br>\n};
    print "=====RESPONCE=====<br>\n";
    print "<textarea cols=90 rows=15>$result</textarea>\n";
  }

  eval { require XML::Simple; };
  if (!$@) {
    XML::Simple->import();
  }
  else {
    print "Content-Type: text/html\n\n";
    print "Can't load 'XML::Simple' check http://www.cpan.org";
    exit;
  }

  my $_xml = eval { XML::Simple::XMLin($result, forcearray => 1) };

  if ($@) {
    print "Incorrect XML\n";
    print "<textarea cols=40 rows=5>$result</textarea>";
    open(my $fh, '>>', 'paysys_xml.log') or die "Can't open file 'paysys_xml.log' $!\n";
      print $fh "----\n";
      print $fh $result;
      print $fh "\n----\n";
      print $fh $@;
      print $fh "\n----\n";
    close($fh);
    return {};
  }

  return $_xml;
}

#**********************************************************
#
#**********************************************************
sub qiwi_invoice_request {
  my ($attr) = @_;

 my $ALARM_SMS=($attr->{ALARM_SMS}) ? 1 : 0;

  my $request = qq{<?xml version="1.0" encoding="utf-8"?>
<request>
<protocol-version>$protocol_version</protocol-version>
<request-type>30</request-type>
<terminal-id>$conf{PAYSYS_QIWI_TERMINAL_ID}</terminal-id>
<extra name="password">$conf{PAYSYS_QIWI_PASSWD}</extra>
<extra name="txn-id">$attr->{OPERATION_ID}</extra>
<extra name="to-account">$attr->{PHONE}</extra>
<extra name="amount">$attr->{SUM}</extra>
<extra name="comment">$attr->{COMMENT}</extra>
<extra name="create-agt">0</extra>
<extra name="ltime">48.5</extra>
<extra name="ALARM_SMS">$ALARM_SMS</extra>
<extra name="ACCEPT_CALL">0</extra>
</request>};

  return mk_request($request);
}
1
