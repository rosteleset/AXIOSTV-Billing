package AXbills::Base;

=head1 NAME

AXbills::Base - Base functions

=head1 SYNOPSIS

    use AXbills::Base;

    convert();

=cut

no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use feature 'state';
use strict;
our (%EXPORT_TAGS);

use POSIX qw(locale_h strftime mktime);
use parent 'Exporter';
use utf8;

our $VERSION = 2.00;

our @EXPORT = qw(
  null
  convert
  int2ip
  ip2int
  int2byte
  int2ml
  sec2date
  sec2time
  time2sec
  decode_base64
  encode_base64
  urlencode
  urldecode
  date_diff
  date_format
  parse_arguments
  mk_unique_value
  check_time
  gen_time
  sendmail
  in_array
  tpl_parse
  cfg2hash
  clearquotes
  cmd
  ssh_cmd
  _bp
  startup_files
  show_log
  days_in_month
  next_month
  show_hash
  load_pmodule
  date_inc
  indexof
  dirname
  json_former
  xml_former
  escape_for_sql
  camelize
  decamelize
  vars2lang
  is_html
  check_ip
  is_number
  decode_quoted_printable
  get_period_dates
);

our @EXPORT_OK = qw(
  null
  convert
  int2ip
  ip2int
  int2byte
  int2ml
  sec2date
  sec2time
  time2sec
  decode_base64
  encode_base64
  urlencode
  urldecode
  date_diff
  date_format
  parse_arguments
  mk_unique_value
  check_time
  gen_time
  sendmail
  in_array
  tpl_parse
  cfg2hash
  dsc2hash
  clearquotes
  cmd
  ssh_cmd
  _bp
  startup_files
  show_log
  days_in_month
  next_month
  show_hash
  load_pmodule
  indexof
  dirname
  json_former
  xml_former
  escape_for_sql
  camelize
  decamelize
  vars2lang
  is_html
  check_ip
  is_number
  decode_quoted_printable
  get_period_dates
);

# As said in perldoc, should be called once on a program
srand();

#**********************************************************
=head2 null() Null function

  Return:
    true

=cut
#**********************************************************
sub null {

  return 1;
}

#**********************************************************
=head2 cfg2hash($cfg, $attr) Convert cft str to hash

  Arguments:
    $cfg
      format:
        key:value;key:value;key:value;
    $attr

  Results:

=cut
#**********************************************************
sub cfg2hash {
  my ($cfg) = @_;
  my %hush = ();

  return \%hush if (!$cfg);

  $cfg =~ s/\n//g;
  my @cfg_options = split(/;/, $cfg);

  foreach my $line (@cfg_options) {
    my ($k, $v) = split(/:/, $line, 2);
    $k =~ s/^\s+//;
    $hush{$k} = $v;
  }

  return \%hush;
}

sub dsc2hash {
  my ($dsc) = @_;
  my %hash = ();

  return \%hash if (!$dsc);

  $dsc =~ s/\n//g;

  my @dsc_options = $dsc =~ /\w+:\W*::\([\w=,;#\s]+\)/gm;

  foreach my $line (@dsc_options) {
    my ($key, $value) = $line =~ /(\w+):\W*::\(([\w=,;#\s]+)\)/gm;

    my @key_params = split(/,/, $value);
    $hash{$key} = [];

    foreach my $key_param (@key_params)
    {
      next unless ($key_param);

      my @key_param_properties = split(/;/, $key_param);
      my %key_param_hash = ();

      foreach my $key_param_property (@key_param_properties) {
        my ($key_param_property_key, $key_param_property_value) = split(/=/, $key_param_property);

        $key_param_hash{$key_param_property_key} = $key_param_property_value;
      }

      unless($key_param_hash{page}) {
        $key_param_hash{page} = 1;
      }

      $key_param_hash{page} -= 1;

      push(@{ $hash{$key} }, \%key_param_hash );
    }

  }

  return \%hash;
}

#**********************************************************
=head2 in_array($value, $array) - Check value in array

  Arguments:

    $value   - Search value
    $array   - Array ref

  Returns:

    true or false

  Examples:

    my $ret = in_array(10, \@array);

=cut
#**********************************************************
sub in_array {
  my ($value, $array) = @_;

  if (!defined($value)) {
    return 0;
  }
  elsif (ref $array ne 'ARRAY') {
    return 0;
  }

  if ( $] <= 5.010 ) {
    if (grep { $_ eq $value } @$array) {
      return 1;
    }
  }
  else {
    if ($value ~~ @$array) {
      return 1;
    }
  }

  return 0;
}

#**********************************************************
=head2 indexof($value, @array) returns

  Arguments:
    $value - scalar
    @array - array to search

  Returns:
   index of first entry of $value in @array or -1

=cut
#**********************************************************
sub indexof {
  for (my $i = 1 ; $i <= $#_ ; $i++) {
    if ($_[$i] eq $_[0]) { return $i - 1; }
  }
  return -1;
}

#**********************************************************
=head2 convert($text, $attr) - Converter text

   Attributes:
     $text     - Text for convertation
     $attr     - Params
       text2html - convert text to HTML
       html2text -
       txt2translit - text to translit
       json      - Convert \n to \\n

       Transpation
         utf82win
         win2koi
         koi2win
         win2iso
         iso2win
         win2dos
         dos2win

  Returns:

    converted text

  Examples:
     convert($text, $attr)

  Formating text

    convert($text, { text2html => 1, SHOW_URL => 1 });

=cut
#**********************************************************
sub convert {
  my ($text, $attr) = @_;

  # $str =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
  if (defined($attr->{text2html})) {
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/\"/&quot;/g;
    $text =~ s/\n/<br\/>\n/gi if (! $attr->{json});
    $text =~ s/[\r\n]/\n/gi if ($attr->{json});
    $text =~ s/\%/\&#37/g;
    $text =~ s/\*/&#42;/g;
    #$text =~ s/\+/\%2B/g;

    if ($attr->{SHOW_URL}) {
      $text =~ s/(https?:\/\/[^\s<]+)/<a href=\'$1\' target=_new>$1<\/a>/ig;
    }
  }
  elsif (defined($attr->{html2text})) {
    $text =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
  }
  elsif (defined($attr->{txt2translit})) {
    $text = txt2translit($text);
  }
  elsif ($attr->{'from_tpl'}) {
    $text =~ s/textarea/__textarea__/g;
  }
  elsif ($attr->{'2_tpl'}) {
    $text =~ s/__textarea__/textarea/g;
  }
  elsif ($attr->{win2utf8}) { $text = win2utf8($text);}
  elsif ($attr->{utf82win}) { $text = utf82win($text);}
  elsif ($attr->{win2koi})  { $text = win2koi($text); }
  elsif ($attr->{koi2win})  { $text = koi2win($text); }
  elsif ($attr->{win2iso})  { $text = win2iso($text); }
  elsif ($attr->{iso2win})  { $text = iso2win($text); }
  elsif ($attr->{win2dos})  { $text = win2dos($text); }
  elsif ($attr->{dos2win})  { $text = dos2win($text); }
  elsif ($attr->{cp8662utf8}) { $text = cp8662utf8($text); }
  elsif ($attr->{utf82cp866}) { $text = utf82cp866($text); }

  if($attr->{json}) {
    $text =~ s/\n/\\n/g;
  }

  return $text;
}

sub win2koi {
  my $pvdcoderwin = shift;
  $pvdcoderwin =~
tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1/;
  return $pvdcoderwin;
}

sub koi2win {
  my $pvdcoderwin = shift;
  $pvdcoderwin =~
tr/\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1\xA6/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF\xB3/;
  return $pvdcoderwin;
}

sub win2iso {
  my $pvdcoderiso = shift;
  $pvdcoderiso =~
tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/;
  return $pvdcoderiso;
}

sub iso2win {
  my $pvdcoderiso = shift;
  $pvdcoderiso =~
tr/\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/;
  return $pvdcoderiso;
}

sub win2dos {
  my $pvdcoderdos = shift;
  $pvdcoderdos =~
tr/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/;
  return $pvdcoderdos;
}

sub dos2win {
  my $pvdcoderdos = shift;
  $pvdcoderdos =~
tr/\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF/\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF/;
  return $pvdcoderdos;
}

#**********************************************************
=head2 txt2translit($text) - convert to translit

=cut
#**********************************************************
sub txt2translit {
  my $text = shift;

  $text =~ y/����������������������������/abvgdeezijklmnoprstufh'y'eie/;
  $text =~ y/�����Ũ������������������ݲ��/ABVGDEEZIJKLMNOPRSTUFH'Y'EI/;

  #TODO: add raw if nothing will be broken
  # require Encode;

  my $is_utf = Encode::is_utf8($text);

  if($is_utf) {
    $text = Encode::decode("UTF-8", $text);
  }

  $text =~ y/абвгдеёзийклмнопрстуфхъыьэ/abvgdeezijklmnoprstufh'y'e/;
  $text =~ y/АБВГДЕЁЗИЙКЛМНОПРСТУФХЪЫЬЭ/ABVGDEEZIJKLMNOPRSTUFH'Y'E/;

  my %mchars = (
    'ж' => 'zh',
    'і' => 'i',
    'ї' => 'ji',
    'ц' => 'ts',
    'ч' => 'ch',
    'ш' => 'sh',
    'щ' => 'shch',
    'ю' => 'ju',
    'я' => 'ja',
    'Ж' => 'Zh',
    'І' => 'I',
    'Ї' => 'Ji',
    'Ц' => 'Ts',
    'Ч' => 'Ch',
    'Ш' => 'Sh',
    'Щ' => 'Shch',
    'Ю' => 'Ju',
    'Я' => 'Ja'
  );

  for my $c (keys %mchars) {
    $text =~ s/$c/$mchars{$c}/g;
  }

  if (! $is_utf) {
    return Encode::encode( "UTF-8", $text );
  }
  else {
    return $text;
  }
}

#**********************************************************
=head2 win2utf8($text)

  http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1251.TXT

=cut
#**********************************************************
sub win2utf8 {
  my ($text, $attr) = @_;

  my $Unicode = '';

  if ($attr->{OLD}) {
    my @ChArray = split('', $text);
    my $Code    = '';
    for (@ChArray) {
      $Code = ord;

      #return $Code;
      if (($Code >= 0xc0) && ($Code <= 0xff)) { $Unicode .= "&#" . (0x350 + $Code) . ";"; }
      elsif ($Code == 0xa8) { $Unicode .= "&#" . (0x401) . ";"; }
      elsif ($Code == 0xb8) { $Unicode .= "&#" . (0x451) . ";"; }
      elsif ($Code == 0xb3) { $Unicode .= "&#" . (0x456) . ";"; }
      elsif ($Code == 0xaa) { $Unicode .= "&#" . (0x404) . ";"; }
      elsif ($Code == 0xba) { $Unicode .= "&#" . (0x454) . ";"; }
      elsif ($Code == 0xb2) { $Unicode .= "&#" . (0x406) . ";"; }
      elsif ($Code == 0xaf) { $Unicode .= "&#" . (0x407) . ";"; }
      elsif ($Code == 0xbf) { $Unicode .= "&#" . (0x457) . ";"; }
      else                  { $Unicode .= $_; }
    }
  }
  else {
    require Encode;
    Encode->import();
    $Unicode = Encode::encode('utf8', Encode::decode('cp1251', $text));
  }

  return $Unicode;
}

#**********************************************************
=head2 utf82win($text)

   http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1251.TXT
   http://www.utf8-chartable.de/unicode-utf8-table.pl

=cut
#**********************************************************
sub utf82win {
  my ($text) = @_;

  require Encode;
  Encode->import();
  my $win1251 = Encode::encode('cp1251', Encode::decode('utf8', $text));

  return $win1251;
}

#**********************************************************
=head2 cp8662utf8($text)

  Arguments:


  Returns:

=cut
#**********************************************************
sub cp8662utf8 {
  my ($text) = @_;

  require Encode;
  Encode->import();

  my $utf8 = Encode::encode('utf-8', Encode::decode('cp866', $text));
  return $utf8;
}

#**********************************************************
=head2 utf82cp866($text)

  Arguments:


  Returns:

=cut
#**********************************************************
sub utf82cp866 {
  my ($text) = @_;

  require Encode;
  Encode->import();

  my $cp866 = Encode::encode('cp866', Encode::decode('utf-8', $text));
  return $cp866;
}

#**********************************************************
=head2 parse_arguments(\@ARGV, $attr) - Parse comand line arguments

  Arguments:

    @ARGV   - Command line arguments

  Returns:

    return HASH_REF of values

  Examples:

    my $argv = parse_arguments(\@ARGV, { help => 'help' });

=cut
#**********************************************************
sub parse_arguments {
  my ($argv, $attr) = @_;

  my %args = ();

  foreach my $line (@$argv) {
    if ($line =~ /=/) {
      my ($k, $v) = split(/=/, $line, 2);
      $args{"$k"} = (defined($v)) ? $v : '';
    }
    else {
      $args{"$line"} = 1;
    }
  }

  if($attr) {
    foreach my $param ( keys %$attr ) {
      if($args{$param}) {
        my $fn = $attr->{$param};
        &{ \&$fn }();
      }
    }
  }

  return \%args;
}

#***********************************************************
=head2 sendmail($from, $to_addresses, $subject, $message, $charset, $priority, $attr) - Send mail message

  Arguments:

    $from          - Sender e-mail
    $to_addresses  - Receipt e-mail
    $subject       - Subject
    $message       - Message
    $charset       - Charset
    $priority      - Priority

    $attr          - Attributes
      ATTACHMENTS    - ARRAY of attachments
      SENDMAIL_PATH  - path to sendmail program (Default: /usr/sbin/sendmail)
      MAIL_HEADER    - Custom mail header
      TEST           - Test mode. Only show email body
      CONTENT_TYPE   - Content Type
      ACTIONS        - Make actions fields
      ID             - Message ID

  Returns:
    0 - true
    1 - error
    2 - reciever email not specified

  Examples:

    sendmail("$conf{ADMIN_MAIL}", "user@email", "Subject", "Message text",
          "$conf{MAIL_CHARSET}", "2 (High)");

=cut
#***********************************************************
sub sendmail {
  my ($from, $to_addresses, $subject, $message, $charset, $priority, $attr) = @_;

  if ($to_addresses eq '') {
    return 2;
  }
  my $SENDMAIL = (defined($attr->{SENDMAIL_PATH})) ? $attr->{SENDMAIL_PATH} : '/usr/sbin/sendmail';

  $charset //= 'utf-8';

  if (!-f $SENDMAIL) {
    if ($attr->{QUITE}) {
      return 3;
    }
    else {
      if ($ENV{SERVER_NAME}) {
        print "Content-Type: text/html\n\n";
      }

      print "Mail delivery agent doesn't exists '$SENDMAIL'\n";
    }
    return 0;
  }

  if (! $from) {
    return 0;
  }

  my $header = '';
  if ($attr->{MAIL_HEADER}) {
    foreach my $line (@{ $attr->{MAIL_HEADER} }) {
      $header .= "$line\n";
    }
  }

  my $ext_header = '';
  my $sendmail_options = '';
  $message =~ s/#.+//g;
  if ($message =~ s/Subject: (.+)[\n\r]+//g) {
    $subject = $1;
  }
  if ($message =~ s/From: (.+)[\n\r]+//g) {
    $from = $1;
    if ($attr->{TRUSTED_FROM}) {
      $sendmail_options = $from;
    }
  }
  elsif($attr->{TRUSTED_FROM} && $attr->{TRUSTED_FROM} ne '1') {
    $sendmail_options = "-f $attr->{TRUSTED_FROM}";
  }

  if ($message =~ s/X-Priority: (.+)[\n\r]+//g) {
    $priority = $1;
  }
  if ($message =~ s/To: (.+)[\r\n]+//gi) {
    $to_addresses = $1;
  }

  if ($message =~ s/Bcc: (.+)[\r\n]+//gi) {
    $ext_header = "Bcc: $1\n";
  }

  $to_addresses =~ s/[\n\r]//g;

  if ($attr->{ACTIONS}) {
    push @{ $attr->{ATTACHMENTS} }, {
      CONTENT      => qq{
        <div itemscope itemtype="http://schema.org/EmailMessage">
  <div itemprop="potentialAction" itemscope itemtype="http://schema.org/ViewAction">
    <link itemprop="target" href="$attr->{ACTIONS}"/>
    <meta itemprop="name" content="Watch message"/>
  </div>
  <meta itemprop="description" content="Watch support message"/>
</div>
      },
      CONTENT_TYPE => 'text/html'
    }
  }

  if ($attr->{ATTACHMENTS}) {
    my $boundary = "----------581DA1EE12D00AAA";
    $header .= "MIME-Version: 1.0
Content-Type: multipart/mixed;\n boundary=\"$boundary\"\n";

    $message = qq{--$boundary
Content-Type: text/plain; charset=$charset
Content-Transfer-Encoding: quoted-printable

$message};

    foreach my $attachment (@{ $attr->{ATTACHMENTS} }) {
      my $data = $attachment->{CONTENT};
      $message .= "\n--$boundary\n";

      if($ENV{SENDMAIL_SAVE_ATTACH}) {
        open(my $fh, '>', '/tmp/'.$attachment->{FILENAME});
          print $fh $attachment->{CONTENT};
        close $fh;
      }

      $message .= "Content-Type: $attachment->{CONTENT_TYPE};\n";
      $message .= " name=\"$attachment->{FILENAME}\"\n" if ($attachment->{FILENAME});
      if ($attachment->{CONTENT_TYPE} ne 'text/html') {
        $data = encode_base64($attachment->{CONTENT});
        $message .= "Content-transfer-encoding: base64\n";
      }
      $message .= "Content-Disposition: attachment;\n filename=\"$attachment->{FILENAME}\"\n" if ($attachment->{FILENAME});
      $message .= "\n";
      $message .= qq{$data};
      $message .= "\n";
    }

    $message .= "--$boundary" . "--\n\n";
  }

  if ($attr->{TEST})   {
    print "Test mode enable: $attr->{TEST}\n";
  }

  my @emails_arr = split(/;/, $to_addresses);
  foreach my $to (@emails_arr) {
    if ($attr->{TEST}) {
      print "To: $to\n";
      print "From: $from\n";
      print $ext_header;
      print "Content-Type: ". ($attr->{CONTENT_TYPE} ? $attr->{CONTENT_TYPE} : 'text/plain') . "; charset=$charset\n";
      print "X-Priority: $priority\n" if ($priority);
      print $header;
      print "Subject: $subject\n\n";
      print "$message";
    }
    else {
      open(my $mail, '|-', "$SENDMAIL -t $sendmail_options") || die "Can't open file '$SENDMAIL' $!\n";
        print $mail "To: $to\n";
        print $mail "From: $from\n";
        print $mail $ext_header;
        print $mail "Content-Type: ". ($attr->{CONTENT_TYPE} ? $attr->{CONTENT_TYPE} : 'text/plain') . "; charset=$charset\n" if (!$attr->{ATTACHMENTS});
        print $mail "X-Priority: $priority\n" if ($priority);
        print $mail "X-Mailer: ABillS\n";
        print $mail "X-ABILLS_ID: $attr->{ID}\n" if ($attr->{ID});
        print $mail $header;
        print $mail "Subject: $subject \n\n";
        print $mail "$message";

      close($mail);
    }
  }

  return 1;
}

#**********************************************************
=head2 show_log($uid, $type, $attr) - Log parser

  Attributes:
    $uid
    $type
    $attr
      PAGE_ROWS
      PG
      DATE
      LOG_TYPE

=cut
#**********************************************************
sub show_log {
  my ($login, $logfile, $attr) = @_;

  my @err_recs = ();
  my %types    = ();

  my $PAGE_ROWS = ($attr->{PAGE_ROWS})   ? $attr->{PAGE_ROWS} : 25;
  my $PG        = (defined($attr->{PG})) ? $attr->{PG}        : 1;

  $login =~ s/\*/\[\.\]\{0,100\}/g if ($login ne '');

  open(my $fh, '<', $logfile) || die "Can't open log file '$logfile' $!\n";
  my ($date, $time, $log_type, $action, $user, $message);
  while (<$fh>) {
    if (/(\d+\-\d+\-\d+) (\d+:\d+:\d+) ([A-Z_]+:) ([A-Z_]+) \[(.+)\] (.+)/) {
      $date     = $1;
      $time     = $2;
      $log_type = $3;
      $action   = $4;
      $user     = $5;
      $message  = $6;
    }
    else {
      next;
    }

    if (defined($attr->{LOG_TYPE}) && "$log_type" ne "$attr->{LOG_TYPE}:") {
      next;
    }

    if (defined($attr->{DATE}) && $date ne $attr->{DATE}) {
      next;
    }

    if ($login ne "") {
      if ($user =~ /^[ ]{0,1}$login\s{0,1}$/i) {
        push @err_recs, $_;
        $types{$log_type}++;
      }
    }
    else {
      push @err_recs, $_;
      $types{$log_type}++;
    }
  }
  close($fh);

  my $total = $#err_recs;
  my @list;

  return (\@list, \%types, $total) if ($total < 0);
  for (my $i = $total - $PG ; $i >= ($total - $PG) - $PAGE_ROWS && $i >= 0 ; $i--) {
    push @list, "$err_recs[$i]";
  }

  $total++;
  return (\@list, \%types, $total);
}

#**********************************************************
=head2 mk_unique_value($size, $attr) - Make unique value

  Arguments:
    $size  - Size of result string
    $attr
      SYMBOLS     -  string with symbols, that will be used for generation, Ex: SYMBOLS => '1234567890'
      EXTRA_RULES - '$chars:$case' (0 - num, 1 - special, 2 - both):(0 - lower, 1 - upper, 2 - both)

  Results:
    $value - Uniques string

=cut
#**********************************************************
sub mk_unique_value {
  my ($size, $attr) = @_;
  my $symbols = (defined($attr->{SYMBOLS})) ? $attr->{SYMBOLS} : "qwertyupasdfghjikzxcvbnmQWERTYUPASDFGHJKLZXCVBNM123456789";

  my @check_rules = ();
  if ( $attr->{EXTRA_RULES} ){
    my ($chars, $case) = split(':', $attr->{EXTRA_RULES}, 2);

    my $uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    my $lowercase = "abcdefghijklmnopqrstuvwxyz";

    my $numbers = "0123456789";
    my $special = "-_!&%@#:";

    $chars //= 0; # numeric
    $case //= 0;  # lowercase

    my $symbols_ = $numbers;
    if ($chars == 1) {        # Special
      $symbols_ = $special;
      push (@check_rules, $symbols_);
    }
    elsif ($chars == 2) {     # Both
      $symbols_ .= $special;
      push (@check_rules, $numbers, $special);
    }
    elsif ($chars == 3) {     # None of special
      $symbols_ = '';
    }
    else {                    # Numbers only
      push (@check_rules, $numbers);
    }

    my $literals = $lowercase;
    if ($case == 1) {         # Uppercase
      $literals = $uppercase;
      push (@check_rules, $uppercase)
    }
    elsif ($case == 2) {         # Both
      $literals .= $uppercase;
      push (@check_rules, $lowercase, $uppercase)
    }
    elsif ($case == 3) {         # No letters
      # Do not add any
    }
    else {                    # Lowercase only
      push (@check_rules, $lowercase);
    }

    $symbols = $symbols_ . $literals;
  }

  my $value  = '';
  my $random = '';
  $size = 6 if (int($size) < 1);
  my $rand_values = length($symbols);
  for (my $i = 0 ; $i < $size ; $i++) {
    $random = int(rand($rand_values));
    $value .= substr($symbols, $random, 1);
  }

  foreach my $rule (@check_rules){
    if ($rule && $value !~ /[$rule]+/ ) {
      $value = &mk_unique_value;
    }
  }

  return $value;
}

#**********************************************************
=head2 int2ip($int) Convert integer value to ip

=cut
#**********************************************************
sub int2ip {
  my $int = shift;

  my $w=($int/16777216)%256;
  my $x=($int/65536)%256;
  my $y=($int/256)%256;
  my $z=$int%256;
  return "$w.$x.$y.$z";

  #Old way
#  my @d = ();
#  $d[0] = int($int / 256 / 256 / 256);
#  $d[1] = int(($int - $d[0] * 256 * 256 * 256) / 256 / 256);
#  $d[2] = int(($int - $d[0] * 256 * 256 * 256 - $d[1] * 256 * 256) / 256);
#  $d[3] = int($int - $d[0] * 256 * 256 * 256 - $d[1] * 256 * 256 - $d[2] * 256);
#return "$d[0].$d[1].$d[2].$d[3]";
}

#**********************************************************
=head2 ip2int($ip) - Convert ip to int

=cut
#**********************************************************
sub ip2int {
  my $ip = shift;

  return unpack("N", pack("C4", split(/\./, $ip)));
}

#***********************************************************
=head2 time2sec($time, $attr) - Time to second

  Returns:
    $sec;

=cut
#***********************************************************
sub time2sec {
  my ($time) = @_;

  my ($H, $M, $S) = split(/:/, $time, 3);

  my $sec = ($H * 60 * 60) + ($M * 60) + $S;

  return $sec;
}

#**********************************************************
=head2 sec2time($value, $attr) - Seconds to date format

  Convert seconds to date format

  Arguments:
    $value - number, seconds for conversion
    $attr
      format - return in 'HH:MM:SS' format
      str    - return in '+D HH:MM:SS' format

  Returns:
    array - ($seconds, $minutes, $hours, $days)
    if $attr see 'Arguments'

  Examples:

=cut
#**********************************************************
sub sec2time {
  my ($value, $attr) = @_;
  my ($seconds, $minutes, $hours, $days);

  $seconds = int($value % 60);
  $minutes = int(($value % 3600) / 60);
  $hours = int(($value % (24 * 3600)) / 3600);
  $days = int($value / (24 * 3600));

  if ($attr->{format}) {
    $hours = int($value / 3600);
    return sprintf("%.2d:%.2d:%.2d", $hours, $minutes, $seconds);
  }
  elsif ($attr->{str}) {
    return sprintf("+%d %.2d:%.2d:%.2d", $days, $hours, $minutes, $seconds);
  }
  else {
    return ($seconds, $minutes, $hours, $days);
  }
}

#***********************************************************
=head2 sec2date($secnum) - Convert second to date

  Arguments:
    $secnum - Unixtime

  Returns:
    "$year-$mon-$mday $hour:$min:$sec"

=cut
#***********************************************************
sub sec2date {
  my ($secnum) = @_;

  return "0000-00-00 00:00:00" if ($secnum == 0);

  my ($sec, $min, $hour, $mday, $mon, $year, undef, undef, undef) = localtime($secnum);
  $year += 1900;
  $mon++;
  $sec  = sprintf("%02d", $sec);
  $min  = sprintf("%02d", $min);
  $hour = sprintf("%02d", $hour);
  $mon  = sprintf("%02d", $mon);
  $mday = sprintf("%02d", $mday);

  return "$year-$mon-$mday $hour:$min:$sec";
}

#***********************************************************
=head2 int2byte($val, $attr) - Convert Integer to byte definision

  Arguments:
    $val
    $attr
      $KBYTE_SIZE - Size of kilobyte (Standart 1024)
      DIMENSION - Mb / Gb / Kb / Bt (Default: auto)

  Result:
    $val

=cut
#***********************************************************
sub int2byte {
  my ($val, $attr) = @_;

  if ($attr->{DELIMITER}) {
    if ($val >= 0) {
      return scalar reverse join $attr->{DELIMITER}, unpack("(A3)*", reverse int($val));
    }
    else {
      return "-" . scalar reverse join $attr->{DELIMITER}, unpack("(A3)*", reverse int(-$val));
    }
  }



  my $KBYTE_SIZE = 1024;
  $KBYTE_SIZE = int($attr->{KBYTE_SIZE}) if (defined($attr->{KBYTE_SIZE}));
  my $MEGABYTE = $KBYTE_SIZE * $KBYTE_SIZE;
  my $GIGABYTE = $KBYTE_SIZE * $KBYTE_SIZE * $KBYTE_SIZE;
  $val = int($val);

  if (ref $val eq 'Math::BigInt') {
    $val = $val->numify();
  }

  if ($attr->{DIMENSION}) {
    if ($attr->{DIMENSION} eq 'Mb') {
      $val = sprintf("%.2f MB", $val / $MEGABYTE);
    }
    elsif ($attr->{DIMENSION} eq 'Gb') {
      $val = sprintf("%.2f GB", $val / $GIGABYTE);
    }
    elsif ($attr->{DIMENSION} eq 'Kb') {
      $val = sprintf("%.2f Kb", $val / $KBYTE_SIZE);
    }
    else {
      $val .= " Bt";
    }
  }
  elsif ($val > $GIGABYTE)   { $val = sprintf("%.2f GB", $val / $GIGABYTE); }     # 1024 * 1024 * 1024
  elsif ($val > $MEGABYTE)   { $val = sprintf("%.2f MB", $val / $MEGABYTE); }     # 1024 * 1024
  elsif ($val > $KBYTE_SIZE) { $val = sprintf("%.2f Kb", $val / $KBYTE_SIZE); }
  else                       { $val .= " Bt"; }

  return $val;
}

#***********************************************************
=head2 int2ml($sum, $attr) integet to money in litteral format

  Arguments:
    $sum
    $attr

  Returns:
    $literal_sum

  Examples:

    $literal_sum = int2ml(1000.20,
      {
        ONES             => \@ones,
        TWOS             => \@twos,
        FIFTH            => \@fifth,
        ONE              => \@one,
        ONEST            => \@onest,
        TEN              => \@ten,
        TENS             => \@tens,
        HUNDRED          => \@hundred,
        MONEY_UNIT_NAMES => $conf{MONEY_UNIT_NAMES},
        LOCALE           => $conf{LOCALE}
      }
    );

=cut
#***********************************************************
sub int2ml {
  my ($sum, $attr) = @_;
  my $ret = '';

  my @ones  = @{ $attr->{ONES} };
  my @twos  = @{ $attr->{TWOS} };
  my @fifth = @{ $attr->{FIFTH} };

  my @one     = @{ $attr->{ONE} };
  my @onest   = @{ $attr->{ONEST} };
  my @ten     = @{ $attr->{TEN} };
  my @tens    = @{ $attr->{TENS} };
  my @hundred = @{ $attr->{HUNDRED} };

  my @money_unit_names = ();

  if($attr->{MONEY_UNIT_NAMES}) {
    if (ref $attr->{MONEY_UNIT_NAMES} ne 'ARRAY') {
      @money_unit_names = split(/;/, $attr->{MONEY_UNIT_NAMES});
    }
    else {
      @money_unit_names = @{ $attr->{MONEY_UNIT_NAMES} };
    }
  }
  $sum =~ s/,/\./g;
  $sum =~ tr/0-9,.//cd;
  my $tmp = $sum;
  my $count = ($tmp =~ tr/.,//);

  if ($count > 1) {
    $ret .= "bad integer format\n";
    return 1;
  }

  my $second = "00";
  my ($first, @first, $i);

  if (!$count) {
    $first = $sum;
  }
  else {
    $first = $second = $sum;
    $first  =~ s/(.*)(\..*)/$1/;
    $second =~ s/(.*)(\.)(\d\d)(.*)/$3/;
    $second .= "0" if (length $second < 2);
  }

  $count = int((length $first) / 3);
  my $first_length = length $first;

  for ($i = 1 ; $i <= $count ; $i++) {
    $tmp = $first;
    $tmp   =~ s/(.*)(\d\d\d$)/$2/;
    $first =~ s/(.*)(\d\d\d$)/$1/;
    $first[$i] = $tmp;
  }

  if ($count < 4 && $count * 3 < $first_length) {
    $first[$i] = $first;
    $first_length = $i;
  }
  else {
    $first_length = $i - 1;
  }

  for ($i = $first_length ; $i >= 1 ; $i--) {
    $tmp = 0;
    for (my $j = length($first[$i]) ; $j >= 1 ; $j--) {
      if ($j == 3) {
        $tmp = $first[$i];
        $tmp =~ s/(^\d)(\d)(\d$)/$1/;
        $ret .= $hundred[$tmp];

        if ($tmp > 0) {
          $ret .= " ";
        }
      }
      if ($j == 2) {
        $tmp = $first[$i];
        $tmp =~ s/(.*)(\d)(\d$)/$2/;
        if ($tmp != 1) {
          $ret .= $ten[$tmp];
          if ($tmp > 0) {
            $ret .= " ";
          }
        }
      }
      if ($j == 1) {
        if ($tmp != 1) {
          $tmp = $first[$i];
          $tmp =~ s/(.*)(\d$)/$2/;
          if ((($i == 1) || ($i == 2)) && ($tmp == 1 || $tmp == 2)) {
            $ret .= $onest[$tmp];
            if ($tmp > 0) {
              $ret .= " ";
            }
          }
          else {
            $ret .= $one[$tmp];
            if ($tmp > 0) {
              $ret .= " ";
            }
          }
        }
        else {
          $tmp = $first[$i];
          $tmp =~ s/(.*)(\d$)/$2/;
          $ret .= $tens[$tmp];
          if ($tmp > 0) {
            $ret .= " ";
          }
          $tmp = 5;
        }
      }
    }

    $ret .= ' ';
    if ($tmp == 1) {
      $ret .= ($ones[ $i - 1 ]) ? $ones[ $i - 1 ] : $money_unit_names[0];
    }
    elsif ($tmp > 1 && $tmp < 5) {
      $ret .= ($twos[ $i - 1 ]) ? $twos[ $i - 1 ] : $money_unit_names[0];
    }
    elsif ($tmp > 4) {
      $ret .= ($fifth[ $i - 1 ]) ? $fifth[ $i - 1 ] : $money_unit_names[0];
    }
    else {
      $ret .= ($fifth[$i-1]) ? $fifth[$i-1] : $money_unit_names[0];
    }
    $ret .= ' ';
  }

  if ($second ne '') {
    $ret .= " $second  ". (( $money_unit_names[1] ) ? $money_unit_names[1] : '');
  }
  else {
    $ret .= "";
  }

  # FIXME: re-review
  use locale;

  my $locale = $attr->{LOCALE} || 'ru_RU.CP1251';
  setlocale( LC_ALL, $locale );
  $ret = ucfirst $ret;
  setlocale( LC_NUMERIC, "" );

  return $ret;
}

#**********************************************************
=head2 decode_base64()

=cut
#**********************************************************
sub decode_base64 {
  local ($^W) = 0;    # unpack("u",...) gives bogus warning in 5.00[123]
  my $str = shift;
  my $res = "";

  $str =~ tr|A-Za-z0-9+=/||cd;    # remove non-base64 chars
  $str =~ s/=+$//;                # remove padding
  $str =~ tr|A-Za-z0-9+/| -_|;    # convert to uuencoded format
  while ($str =~ /(.{1,60})/gs) {
    my $len = chr(32 + length($1) * 3 / 4);    # compute length byte
    $res .= unpack("u", $len . $1);            # uudecode
  }

  return $res;
}

#**********************************************************
=head2 encode_base64()

=cut
#**********************************************************
sub encode_base64 {

  if ($] >= 5.006) {
    require bytes;
    if (bytes::length($_[0]) > length($_[0])
      || ($] >= 5.008 && $_[0] =~ /[^\0-\xFF]/))
    {
      require Carp;
      Carp::croak("The Base64 encoding is only defined for bytes");
    }
  }

  require integer;
  integer->import();

  my $eol = $_[1];
  $eol = "\n" unless defined $eol;

  my $res = pack("u", $_[0]);

  # Remove first character of each line, remove newlines
  $res =~ s/^.//mg;
  $res =~ s/\n//g;

  $res =~ tr|` -_|AA-Za-z0-9+/|;    # `# help emacs
                                    # fix padding at the end
  my $padding = (3 - length($_[0]) % 3) % 3;
  $res =~ s/.{$padding}$/'=' x $padding/e if $padding;

  # break encoded string into lines of no more than 76 characters each
  if (length $eol) {
    $res =~ s/(.{1,72})/$1$eol/g;
  }

  return $res;
}

#**********************************************************
=head2 check_time() - time check function. Make start time point

=cut
#**********************************************************
sub check_time {
  my $begin_time = 0;

  #Check the Time::HiRes module (available from CPAN)
  eval { require Time::HiRes; };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }

  return $begin_time;
}

#**********************************************************
=head2 gen_time($begin_time) - Show generation time

  Arguments:
    $begin_time  - Start time point
    $attr
      TIME_ONLY

  Returns:
    generation time

=cut
#**********************************************************
sub gen_time {
  my ($begin_time, $attr) = @_;

  if ($begin_time > 0) {
    Time::HiRes->import(qw(gettimeofday));
    my $end_time = Time::HiRes::gettimeofday();
    return (($attr->{TIME_ONLY}) ? '' : 'GT: ') . sprintf("%2.5f", $end_time - $begin_time);
  }

  return '';
}

#**********************************************************
=head2 clearquotes($text, $attr) - For clearing quotes

=cut
#**********************************************************
sub clearquotes {
  my ($text, $attr) = @_;

  if ($text ne '""') {
    my $extra = $attr->{EXTRA} || '';
    $text =~ s/\"$extra//g;
  }
  else {
    $text = '';
  }

  return $text;
}

#**********************************************************
=head2 tpl_parse($string, \%HASH_REF, $attr); - Parse tpl

  Arguments:
    $string   - parse string
    $HASH_REF - Hash_ref of parameters
    $attr     - Extra attributes
      SET_ENV - Set enviropment values

  Return:
    result string

=cut
#**********************************************************
sub tpl_parse {
  my ($string, $HASH_REF, $attr) = @_;

  while (my ($k, $v) = each %$HASH_REF) {
    if (!defined($v)) {
      $v = '';
    }
    $string =~ s/\%$k\%/$v/g;
    if ($attr->{SET_ENV}) {
      $ENV{$k}=$v;
    }
  }

  return $string;
}

#**********************************************************
=head2 cmd($cmd, \%HASH_REF); - Execute shell command

command execute in backgroud mode without output

  Arguments:

    $cmd     - command for execute
    $attr    - Extra params
      PARAMS          - Parameters for command line (HASH_REF)
        [PARAM_NAME => PARAM_VALUE] convert to PARAM_NAME="PARAM_VALUE"
      SHOW_RESULT     - show output of execution
      timeout         - Time for command execute (Default: 5 sec.)
      RESULT_ARRAY    - Return result as ARRAY_REF
      ARGV            - Add ARGV for program
      DEBUG           - Debug mode
      COMMENT         - Comments for debug messaging

      $ENV{CMD_EMULATE_MODE}
        /usr/axbills/var/log/cmd.log

  Returns:

    return command result string

  Examples:

    my $result = cmd("/usr/axbills/misc/extended.sh %LOGIN% %IP%", { PARAMS => { LOGIN => text } });

    run as:

    /usr/axbills/misc/extended.sh test


    my $result = cmd("/usr/axbills/misc/extended.sh", { ARGV => 1, PARAMS => { LOGIN => text } });

    run as:

    /usr/axbills/misc/extended.sh LOGIN="test"

=cut
#**********************************************************
sub cmd {
  my ($cmd, $attr) = @_;

  my $debug   = $attr->{DEBUG} || 0;
  my $timeout = defined($attr->{timeout}) ? $attr->{timeout} : 5;
  my $result  = '';

  my $saveerr;
  my $error_output;
  #Close error output
  if (! $attr->{SHOW_RESULT} && ! $debug) {
    open($saveerr, '>&', \*STDERR);
    close(STDERR);
    #Add o scallar error message
    open STDERR, '>', \$error_output or die "Can't make error scalar variable $!?\n";
  }

  if ($debug > 1) {
    $attr->{PARAMS}{DEBUG}=$debug;
  }

  if ($attr->{PARAMS}) {
    $cmd = tpl_parse($cmd, $attr->{PARAMS}, { SET_ENV => $attr->{SET_ENV} });
  }

  if ($attr->{ARGV}) {
    my @skip_keys = ('EXT_TABLES', 'SEARCH_FIELDS', 'SEARCH_FIELDS_ARR', 'SEARCH_FIELDS_COUNT',
      'COL_NAMES_ARR', 'db', 'list', 'dbo', 'TP_INFO', 'TP_INFO_OLD', 'CHANGES_LOG', '__BUFFER', 'TABLE_SHOW');
    foreach my $key ( sort keys %{ $attr->{PARAMS} } ) {
      next if (in_array($key, \@skip_keys));
      next if (ref $attr->{PARAMS}->{$key} ne '');

      $cmd .= " $key=\"$attr->{PARAMS}->{$key}\"";
    }
  }

  if($debug>2) {
    if($attr->{COMMENT}) {
      print "CMD: $attr->{COMMENT}\n";
    }

    print "CMD: $cmd\n";
    if ($debug > 5) {
      return $result;
    }
  }

  if($ENV{CMD_EMULATE_MODE}) {

    my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
    my $TIME = POSIX::strftime("%H:%M:%S", localtime(time));
    if (open(my $fh, '>>', '/usr/axbills/var/log/cmd.log')) {
      print $fh "$DATE $TIME " . $cmd ."\n";
      close($fh);
    }
    else {
      die "Can't open '/usr/axbills/var/log/cmd.log' $!\n";
    }

    if ($ENV{CMD_EMULATE_MODE} > 1) {
      return [];
    }
  }

  eval {
    local $SIG{ALRM} = sub { die "alarm\n" };    # NB: \n required

    if ($timeout) {
      alarm $timeout;
    }

    #$result = system($cmd);
    $result = `$cmd`;
    alarm 0;
  };

  if ($@) {
    die unless $@ eq "alarm\n";                  # propagate unexpected errors
    print "timed out\n" if ($debug>2);
  }
  elsif($!) {
    $result = $cmd . " : " . $!
  }
  else {
    print "NO errors\n" if ($debug>2);
  }

  if ($debug) {
    print $result;
  }

  if ($saveerr) {
    close(STDERR);
    open(STDERR, '>&', $saveerr);
  }

  if($attr->{RESULT_ARRAY}) {
    my @result_rows = split(/\r\n/, $result);
    return \@result_rows
  }

  return $result;
}

#**********************************************************
=head2 ssh_cmd($cmd, $attr) - Make ssh command

  Arguments:

    $cmd     - command for execute
      extra cmd "sleep 10"
    $attr    - Extra params
      NAS_MNG_IP_PORT  - Server IP:PORT:SSH_PORT
      BASE_DIR         - Base dir for certificate BASE_DIR/Certs/id_rsa
      NAS_MNG_USER     - ssh login (Default: axbills_admin)
      SSH_CMD          - ssh command (Default: /usr/bin/ssh -p $nas_port -o StrictHostKeyChecking=no -i $base_dir/Certs/id_rsa.$nas_admin)
      SSH_KEY          - (optional) custom certificate file
      SSH_PORT         - Custom ssh port
      SINGLE_THREAD    - Make all command in one thread
      DEBUG            - Debug mode

  Returns:

    return array_ref

  Examples:

    my $result = ssh_cmd('ls', { NAS_MNG_IP_PORT => '192.168.0.12:22' });

    make

    /usr/bin/ssh -p 22 -o StrictHostKeyChecking=no -i /usr/axbills/Certs/id_rsa.axbills_admin axbills_admin@192.168.0.12 '$cmd'

=cut
#**********************************************************
sub ssh_cmd {
  my ($cmd, $attr) = @_;

  my $debug     = $attr->{DEBUG} || 0;
  my @value = ();

  if (! $attr->{NAS_MNG_IP_PORT}) {
    print "Error: NAS_MNG_IP_PORT - Not defined\n";
    return \@value;
  }

  # IP : POD/COA : SSH/TELNET : SNMP port
  my @mng_array = split(/:/, $attr->{NAS_MNG_IP_PORT});
  my $nas_host  = $mng_array[0];
  my $nas_port  = 22;

  if($attr->{SSH_PORT}) {
    if($attr->{SSH_PORT} =~ /^\d+$/) {
      $nas_port = $attr->{SSH_PORT};
    }
  }
  elsif ($#mng_array > 1) {
    if($mng_array[2] =~ /^\d+$/) {
      $nas_port = $mng_array[2];
    }
  }

  $nas_port //= 22;

  my $base_dir = $attr->{BASE_DIR} || '/usr/axbills/';

  # Check for KnownHosts file
  my $known_hosts_file = "$base_dir/Certs/known_hosts";
  my $known_hosts_option = " -o UserKnownHostsFile=$known_hosts_file"
    ." -o CheckHostIP=no";

  my $nas_admin = 'axbills_admin';

  if ($attr->{NAS_MNG_USER} && $attr->{NAS_MNG_USER} =~ /^[a-zA-Z0-9\_\-]+$/) {
    $nas_admin = $attr->{NAS_MNG_USER};
  }

  my $ssh_key   = $attr->{SSH_KEY}     || "$base_dir/Certs/id_rsa." . $nas_admin;
  my $SSH       = $attr->{SSH_CMD}     || "/usr/bin/ssh -q -p $nas_port $known_hosts_option"
                                            . " -o StrictHostKeyChecking=no -i " . $ssh_key;

  my @cmd_arr = ();
  if (ref $cmd eq 'ARRAY') {
    if($attr->{SINGLE_THREAD}) {
      push @cmd_arr, join('; ', @{$cmd});
    }
    else {
      @cmd_arr = @{$cmd};
    }
  }
  else {
    push @cmd_arr, $cmd ;
  }

  foreach my $run_cmd (@cmd_arr) {
    $run_cmd =~ s/[\r\n]+/ /g;

    if ($run_cmd =~ /sleep (\d+)/) {
      sleep $1;
      next;
    }
    elsif(! $nas_host) {
      next;
    }

    my $cmds = "$SSH $nas_admin\@$nas_host '$run_cmd'";
    if ($debug) {
      print "$cmds\n";
    }

    if($debug < 8) {
      open(my $ph, '-|', "$cmds") || die "Can't open '$cmds' $!\n";
      @value = <$ph>;
      close($ph);
    }

    if ($debug > 2) {
      print join("\n", @value);
    }
  }

  return \@value;
}

#**********************************************************
=head2 date_diff($from_date, $to_date) - period in days from date1 to date2

  Arguments:

    $from_date - From date
    $to_date   - To date

  Returns:

    integer of date

  Examples:

    my $days = date_diff('2015-10-31', '2015-12-01');

=cut
#**********************************************************
sub date_diff {
  my ($from_date, $to_date) = @_;

  return 0 if ( ($from_date eq '0000-00-00') || ($to_date eq '0000-00-00') );

  require Time::Piece unless $Time::Piece::VERSION;
  if ($from_date =~ /(.+)\s/) {
    $from_date=$1;
  }

  my $date1 = Time::Piece->strptime($from_date, "%Y-%m-%d");
  my $date2 = Time::Piece->strptime($to_date, "%Y-%m-%d");

  my Time::Piece $diff = $date2 - $date1;

  return int($diff->days());
}

#**********************************************************
=head2 date_format($date, $format, $attr) - convert date to other date format

  Arguments:

    $date     - Input date YYYY-MM-DD
    $format   - Output format (Use POSIX conver format)
    $attr     -  Extra atributes

  Returns:

    string of date

  Examples:

    date_format('2015-10-31 08:01:15', "%m.%d.%y");

    result 31.10.2015

    date_format('2015-10-31 08:01:15', "%H-%m-%S");

    result 08-01-15

=cut
#**********************************************************
sub date_format {
  my ($date, $format) = @_;
  my $year   = 0;
  my $month  = 0;
  my $day    = 0;
  my $hour   = 0;
  my $min    = 0;
  my $sec    = 0;

  if ($date =~ /(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
    $year   = $1 - 1900;
    $month  = $2 - 1;
    $day    = $3;
    $hour   = $4;
    $min    = $5;
    $sec    = $6;
  }
  elsif ($date =~ /^(\d{4})\-(\d{2})\-(\d{2})$/) {
    $year   = $1 - 1900;
    $month  = $2 - 1;
    $day    = $3;
  }
  else {
    ($sec, $min, $hour, $day, $month, $year) = (localtime time)[ 0, 1, 2, 3, 4, 5 ];
    $year = "0$year"  if ($year < 10);
    $day  = "0$day"   if ($day < 10);
    $month= "0$month" if ($month < 10);
    $hour = "0$hour"  if ($hour < 10);
    $min  = "0$min"   if ($min < 10);
    $sec  = "0$sec"   if ($sec < 10);
  }

  $date = POSIX::strftime( $format,
                  localtime(POSIX::mktime($sec, $min, $hour, $day, $month, $year) ) );

  return $date;
}

#**********************************************************
=head2 _bp($attr) - Break points for debugging

  Show file name,line number of point and input value

  Arguments:
    $explanation - Describe of value or hash_ref(legacy)
      HEADER     - show html header (Content-Type)
      SHOW       - Show input. Auto detect: string, array_ref, hash_ref, obj
      EXIT       - Exit programs
      BREAK_LINE - Break line symbols
    $value       - Value of any type STRING, ARR_REF, HASH_REF
    $attr        - hash_ref
      HEADER         - print HTTP content-type header
      EXIT           - Exit program (!!!)
      BREAK_LINE     - Break line symbols
      TO_WEB_CONSOLE - print to browser debug console via JavaScript
      TO_CONSOLE     - print without HTML formatting
      IN_JSON        - surround with JSON comment tags ( used only with IN_CONSOLE )
      TO_FILE        - print to file.

      SORT           - Sort hash keys

  Returns:
    1

  Example:
    my $hash = { id1 => 'value1' };

    Show with explanation of value
      _bp( 'Simple hash', $hash, $attr ) if ($attr->{DEBUG});
      _bp("Simple hash", $hash);

    Show value in browser console
      _bp("Simple hash", $hash, { TO_WEB_CONSOLE => 1 });

    No HTML formatting
      _bp("Simple hash", $hash, { TO_CONSOLE => 1 });

    Print to special file
      _bp("Simple hash", $hash, { TO_FILE => path/to/file });

    Print to /usr/axbills/var/log/bp.log
      _bp("Simple hash", $hash, { TO_FILE => 1 });

    Legacy:
      _bp({ SHOW => 'Some text' });

=cut
#**********************************************************
sub _bp {
  my ($explanation, $value, $attr) = @_;

  $attr->{TO_CONSOLE} = 1 if( $attr->{TO_FILE} );

  # Allow to set args one time for all cals
  state $STATIC_ARGS;
  if ($attr && $attr->{SET_ARGS}){
    $STATIC_ARGS = $attr->{SET_ARGS};
    return;
  }
  if (!$attr && defined $STATIC_ARGS){
    $attr = $STATIC_ARGS;
  }

  my $result_string = "";
  my ($package, $filename, $line) = caller;

  my $break_line = "\n";

  # Legacy for old _bp call
  if ( ref $explanation eq 'HASH' ){
    $attr = $explanation;
    $value = $attr->{SHOW};
    $explanation = "Breakpoint";
    print $value;
  }

  if ( ref $value ne '' ){
    require Data::Dumper;
    Data::Dumper->import();

    if ( $attr->{SORT} && ref $value eq 'HASH' ){
      foreach my $key ( sort { $a <=> $b } keys %$value ) {
        print "$key -> $value->{$key} $break_line";
      }
    }
    else{
      unless ( $attr->{TO_CONSOLE} || $attr->{TO_WEB_CONSOLE} ){
        $Data::Dumper::Pad = "<br>\n";
        $Data::Dumper::Indent = 3;
        $Data::Dumper::Sortkeys = 1;
      }
      $result_string = Data::Dumper::Dumper( $value );
    }
  }
  else{
    $result_string = $value || '';
  }

  if ( $attr->{HEADER} ){
    print "Content-Type: text/html\n\n";
  }

  if ( $attr->{TO_WEB_CONSOLE} ){
    $break_line = ($attr->{BREAK_LINE}) ? $attr->{BREAK_LINE} : "";

    my $log_explanation = uc ( $explanation );
    my $log_string = $result_string;

    $log_string =~ s/\n/$break_line/g;
    $log_string =~ s/\s+/ /g;
    $log_string =~ s/\"/\'/g;
    $log_string =~ s/\//\\\//g;

    print qq{<script> console.log("$log_string") </script>\n};
  }
  elsif ( $attr->{TO_CONSOLE} ){
    my $console_log_string = "[ $filename : $line ] $break_line" . uc ( $explanation ) . " : " . $result_string . $break_line;

    if ( $attr->{BREAK_LINE} ){
      $console_log_string =~ s/[\n]/$attr->{BREAK_LINE}/g;
    }

    if ($attr->{IN_JSON}){
      $console_log_string = " /* \n $console_log_string \n */ ";
    }

    if($attr->{TO_FILE}) {

      our $base_dir;
      $base_dir //= '/usr/axbills/';

      my $file = $base_dir.'var/log/bp.log';
      $file = $attr->{TO_FILE} if ($attr->{TO_FILE} ne 1);


      open(my $fh, '>>', $file) || print "[ $filename : $line ] \n Error opening '$file': $! \n";
      print $fh $console_log_string . "\n";
      close($fh);

    } else {
      print $console_log_string . "\n";
    }
  }
  else{
    $break_line = ($attr->{BREAK_LINE}) ? $attr->{BREAK_LINE} : "<br/>\n";

    $result_string =~ s/\s/\&nbsp\;/g;

    my $html_log_string = "<hr/><div class='text-left'><b>[ $filename : $line ]</b>$break_line" . uc ( $explanation ) . " : " . $result_string . "</div>";
    print $html_log_string . $break_line;
  }

  if ( $attr->{EXIT} ){
    print "$break_line Exit on breakpoint: PACKAGE: '$package', FILE:  '$filename', LINE: '$line' ";
    if ($attr->{TO_WEB_CONSOLE}){
      print "$break_line Show to Browser console";
    }
    exit ( 1 );
  }

  return 1;
}

#**********************************************************
=head2 urlencode($text) URL encode function

  Arguments:
    $text   - Text string

  Returns:
    Encoding string

=cut
#**********************************************************
sub urlencode {
  my ($text, $attr) = @_;

  $text =~ s/ /+/g if $attr->{REPLACE_SPACES};
  #$s =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
  $text =~ s/([^A-Za-z0-9\_\.\-])/sprintf("%%%2.2X", ord($1))/ge;

  return $text;
}

#**********************************************************
=head2 urldecode($text) URL decode function
  Arguments:
    $text   - Text string

  Returns:
    decoding string

=cut
#**********************************************************
sub urldecode {
  my ($text) = @_;

  $text =~ s/\+/ /g;
  $text =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

  return $text;
}

#**********************************************************
=head2 decode_quoted_printable($text) - Decode quoted printable text

   Attributes:
     $text - Text to decode

  Returns:
    Decoded text

  Examples:
     convert('=D0=9F=D1=80=D0=B8=D0=B2=D1=96=D1=82')
     # Returns 'Привіт'

=cut
#**********************************************************
sub decode_quoted_printable {
  my $text = shift;

  $text =~ s/\r\n/\n/g;
  $text =~ s/[ \t]+\n/\n/g;
  $text =~ s/=\n//g;

  if (ord('A') == 193) { # EBCDIC style machine
    if (ord('[') == 173) {
      $text =~ s/=([\da-fA-F]{2})/Encode::encode('cp1047',Encode::decode('iso-8859-1',pack("C", hex($1))))/ge;
    }
    elsif (ord('[') == 187) {
      $text =~ s/=([\da-fA-F]{2})/Encode::encode('posix-bc',Encode::decode('iso-8859-1',pack("C", hex($1))))/ge;
    }
    elsif (ord('[') == 186) {
      $text =~ s/=([\da-fA-F]{2})/Encode::encode('cp37',Encode::decode('iso-8859-1',pack("C", hex($1))))/ge;
    }
  }
  else { # ASCII style machine
    $text =~ s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;
  }
  $text;
}

#**********************************************************
=head2 startup_files($attr) - Get deamon startup information and other params of system

Analise file /usr/axbills/AXbills/programs and return hash_ref of params

  Atributes:
    $attr
      TPL_DIR

  Returns:
    hash_ref

=cut
#**********************************************************
sub startup_files {
  my ($attr) = @_;

  my %startup_files = ();
  our $base_dir;
  $base_dir //= '/usr/axbills/';

  my $startup_conf = $base_dir . '/AXbills/programs';
  if ( $attr->{TPL_DIR} ) {
    if (-e "$attr->{TPL_DIR}/programs.tpl") {
      $startup_conf = "$attr->{TPL_DIR}/programs.tpl";
    }
  }

  my $content = '';
  if(lc($^O) eq 'freebsd') {
    %startup_files = (
      WEB_SERVER_USER    => "www",
      RADIUS_SERVER_USER => "freeradius",
      APACHE_CONF_DIR    => '/usr/local/etc/apache24/Includes/',
      RESTART_MYSQL      => '/usr/local/etc/rc.d/mysql-server',
      RESTART_RADIUS     => '/usr/local/etc/rc.d/freeradius',
      RESTART_APACHE     => '/usr/local/etc/rc.d/apache24',
      RESTART_DHCP       => '/usr/local/etc/rc.d/isc-dhcp-server',
      SUDO               => '/usr/local/bin/sudo',
      POSTQUEUE          => '/usr/local/sbin/postqueue',
    );
  }
  else {
    %startup_files = (
      WEB_SERVER_USER    => "www-data",
      APACHE_CONF_DIR    => '/etc/apache2/sites-enabled/',
      RADIUS_SERVER_USER => "freerad",
      RESTART_MYSQL      => '/etc/init.d/mysqld',
      RESTART_RADIUS     => '/etc/init.d/freeradius',
      RESTART_APACHE     => '/etc/init.d/apache2',
      RESTART_DHCP       => '/etc/init.d/isc-dhcp-server',
      SUDO               => '/usr/bin/sudo',
    );
  }

  if ( -f $startup_conf ) {
    if (open(my $fh, '<', "$startup_conf") ) {
      while( <$fh> ) {
        $content .= $_;
      }
      close($fh);
    }

    my @rows = split(/[\r\n]+/, $content);
    foreach my $line (@rows) {
      my ($key, $val) = split(/=/, $line, 2);
      next if (!$key);
      next if (!$val);
      if ($val =~ /^([\/A-Za-z0-9\_\.\-]+)/) {
        $startup_files{$key}=$val;
      }
    }
  }

  return \%startup_files;
}

#**********************************************************
=head2 days_in_month($attr)

  Arguments:
    $attr
      DATE

  Returns:
    $day_in_month

  Examples:

    days_in_month({ DATE => '2016-11' });

    days_in_month({ DATE => '2016-11-01' });

=cut
#**********************************************************
sub days_in_month {
  my ($attr) = @_;

  my $DATE = '';

  if ($attr->{DATE}) {
    $DATE = $attr->{DATE};
  }
  else {
    $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
  }

  my ($Y, $M) = split(/-/, $DATE);

  my $day_in_month = ($M != 2 ? (($M % 2) ^ ($M > 7)) + 30 : (!($Y % 400) || !($Y % 4) && ($Y % 25) ? 29 : 28));

  return $day_in_month;
}

#**********************************************************
=head2 next_month($attr)

  Arguments:
    $attr
      DATE      - Curdate
      END       - End off month
      PERIOD    - Month period
      DAY

  Return:
    $next_month (YYYY-MM-DD)

  Examples:
    next_month({ DATE => '2016-03-12' });

=cut
#**********************************************************
sub next_month {
  my ($attr) = @_;

  my $DATE = '';
  my $next_month = '';

  if ($attr->{DATE}) {
    $DATE = $attr->{DATE};
  }
  else {
    $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
  }

  my ($Y, $M, $D) = split(/-/, $DATE);

  if($attr->{PERIOD}) {
    if($attr->{END}) {
      $attr->{PERIOD} += 30;
    }

    $next_month = POSIX::strftime( '%Y-%m-%d', localtime(POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + ($attr->{PERIOD}+1) * 86400));

    return $next_month;
  }

  if ($M + 1 > 12) {
    $M = 1;
    $Y++;
  }
  else {
    $M++;
  }

  $D = '01';
  if($attr->{DAY}) {
    $D = $attr->{DAY};
  }
  elsif($attr->{END}) {
    $D = ($M != 2 ? (($M % 2) ^ ($M > 7)) + 30 : (!($Y % 400) || !($Y % 4) && ($Y % 25) ? 29 : 28));
  }

  $next_month = sprintf("%4d-%02d-%02d", $Y, $M, $D);

  return $next_month;
}

#**********************************************************
=head2 show_hash($hash, $attr) - show hash

  Arguments:
    $hash_ref
    $attr
      DELIMITER
      SPACE_SHIFT
      OUTPUT2RETURN

  Results:
    True or false

=cut
#**********************************************************
sub show_hash {
  my($hash, $attr) = @_;

  if(ref $hash ne 'HASH') {
    return 0;
  }

  my $space_shift += (($attr->{SPACE_SHIFT}) ? $attr->{SPACE_SHIFT} : 0);
  my $spaces = '';

  if ($space_shift) {
    for(my $i=1; $i<=$space_shift; $i++) {
      $spaces .= ' ';
    }
  }
  else {
    $spaces .= '';
  }

  my $result = '';
  foreach my $key (sort keys %$hash) {
    $result .= "$spaces$key - ";
    if (ref $hash->{$key} eq 'HASH') {
      $result .= "\n" . show_hash($hash->{$key}, { %{ ($attr) ? $attr : {}},
        OUTPUT2RETURN => 1,
        SPACE_SHIFT => $space_shift+1
      });
    }
    elsif(ref $hash->{$key} eq 'ARRAY') {
      foreach my $key_ (sort @{ $hash->{$key} }) {
        if(ref $key_ eq 'HASH') {
          $result .= show_hash($key_, { %{ ($attr) ? $attr : {}},
            OUTPUT2RETURN => 1,
            SPACE_SHIFT   => $space_shift+1
          });
        }
        else {
          $result .= $key_;
        }
      }
    }
    else {
      $result .= (defined($hash->{$key})) ? $hash->{$key} : q{};
    }
    $result .= ($attr->{DELIMITER} || ',');
  }

  if ($attr->{OUTPUT2RETURN}) {
    return $result;
  }

  print $result;
  if ($space_shift) {
    $space_shift--;
    $spaces =~ s/\s//;
  }

  return 1;
}

#**********************************************************
=head2 load_pmodule($modulename, $attr); - Load perl module

  Arguments:
    $modulename   - Perl module name
    $attr
      IMPORT      - Function for import
      HEADER      - Add Content-Type header
      SHOW_RETURN - Result to return

  Returns:
    TRUE - Not loaded
    FALSE - Loaded

  Examples:

    use Simple::XML;
    load_pmodule('Simple::XML', { IMPORT => '' });

    use Digest::SHA qw(sha1_hex);
    load_pmodule('Digest::SHA', { IMPORT => 'sha1_hex' });

=cut
#**********************************************************
sub load_pmodule {
  my ($name, $attr) = @_;

  my $module_path = $name . '.pm';
  $module_path =~ s{::}{/}g;
  eval { require $module_path };

  my $result = '';

  if (!$@) {
    if ($attr->{IMPORT}) {
      $name->import( $attr->{IMPORT} );
    }
    else {
      $name->import();
    }
  }
  else {
    $result = "Content-Type: text/html\n\n" if ($attr->{HEADER});
    $result .= "Can't load '$name'\n".
      " Install Perl Module <a href='http://billing.axiostv.ru/wiki/doku.php/axbills:docs:manual:soft:$name' target='_install'>$name</a> \n".
      " Main Page <a href='http://billing.axiostv.ru/wiki/doku.php/axbills:docs:other:ru?&#ustanovka_perl_modulej' target='_install'>Perl modules installation</a>\n".
      " or install from <a href='http://www.cpan.org'>CPAN</a>\n";

    $result .= "$@" if ($attr->{DEBUG});

    #print "Purchase this module http://billing.axiostv.ru";
    if ($attr->{SHOW_RETURN}) {
      return $result;
    }
    elsif (! $attr->{RETURN} ) {
      print $result;
      die;
    }

    print $result;
  }

  return 0;
}

#**********************************************************
=head2 date_inc($date)

  Arguments:
    $date - '2016-01-24'

  Returns:
    string - date incremented by one day

    0 if incorrect date;

  Example:
    my $prev_date = date_inc($date);

=cut
#**********************************************************
sub date_inc {
  my ($date) = @_;

  my ($year, $month, $day) = split ('-', $date, 3);
  return 0 unless ( $year && $month && $day );

  if ( ++$day >= 29 ){
    my $days_in_month = days_in_month({ DATE => $date });
    if ( $day > $days_in_month ){
      if ( ++$month == 13 ){
        $year++;
        $month = '01';
      }
      $day = '01';
    }
  }

  return "$year-$month-$day";
}

#**********************************************************
=head2 dirname($path) - Get dirname

  Arguments:
    $path FILE_WITH_PATH

  Result:
    Dirname

=cut
#**********************************************************
sub dirname {
  my ($x) = @_;
  if ($x !~ s@[/\\][^/\\]+$@@) {
    $x = '.';
  }

  return $x;
}

#**********************************************************
=head2 json_former($request) - value to json

  Arguments
    $request (strinf|arr|hash)
    $attr
      ESCAPE_DQ           - escape double quotes on response string
      USE_CAMELIZE        - camelize keys of hash
      CONTROL_CHARACTERS  - escape \t and \n
      BOOL_VALUE          - return null, true and false as boolean value in json
      RM_SPACES           - remove all spaces from response

  Result
    JSON_string

=cut
#**********************************************************
sub json_former {
  my ($request, $attr) = @_;
  my @text_arr = ();

  #TODO: if data is string, but contains only digits, it's returned as numbers

  if (ref $request eq 'ARRAY') {
    foreach my $key (@{$request}) {
      push @text_arr, json_former($key, $attr);
    }

    $attr->{RM_SPACES} ?
      return '[' . join(',', @text_arr) . ']' :
      return '[' . join(', ', @text_arr) . ']';
  }
  elsif (ref $request eq 'HASH') {
    foreach my $key (sort keys %{$request}) {
      next if ($attr->{UNIQUE_KEYS} && !is_number($key) && $request->{lc $key} && $request->{uc $key} && $key eq uc $key);

      my $val = json_former($request->{$key}, $attr);

      if ($attr->{USE_CAMELIZE}) {
        my $new_key = camelize($key, { RM_SPACES => 1 });
        $request->{$new_key} = $request->{$key};
        $key = $new_key;
      }

      $attr->{ESCAPE_DQ} ? push @text_arr, qq{\\"$key\\":$val} :
        push @text_arr, qq{\"$key\":$val};
    }

    $attr->{RM_SPACES} ?
      return '{' . join(',', @text_arr) . '}' :
      return '{' . join(', ', @text_arr) . '}';
  }
  else {
    $request //= '';
    $attr->{ESCAPE_DQ} ? $request =~ s/"/\\\\\\"/gm : $request =~ s/"/\\"/gm;
    if ($attr->{CONTROL_CHARACTERS}){
      $request =~ s/[\t]/\\t/g;
      $request =~ s/[\n]/\\n/g;
    }

    $request =~ s/[\x{00}-\x{1f}]+//ig;

    if ($request =~/[\\]$/g) {
      $request =~ s/[\\]$/\\\\/g;
    }

    if ($request =~ '<str_>' || (!$request && $request !~ '[0]')) {
      $request =~ s/<str_>//;
      $attr->{ESCAPE_DQ} ?
        return qq{\\"$request\\"} :
        return qq{\"$request\"};
    }
    elsif (is_number($request)) {
      return qq{$request};
    }
    elsif ($attr->{BOOL_VALUES} && $request =~ /^(true|false|null)$/) {
      return qq{$request};
    }
    else {
      $attr->{ESCAPE_DQ} ?
        return qq{\\"$request\\"} :
        return qq{\"$request\"};
    }
  }
}

#**********************************************************
=head2 is_number($value) - check is argument is number

  Arguments
    $value: string | number - check value

  Result
    $result: boolean - is number or not

=cut
#**********************************************************
sub is_number {
  my ($value, $type, $unsigned) = @_;
  $unsigned = $unsigned || 0;

  if ($type) {
    return if utf8::is_utf8($value);
    return unless length((my $dummy = "") & $value);
    return unless 0 + $value eq $value;
    return 1 if $value * 0 == 0;
    return -1; # inf/nan
  }
  else {
    my $res = 0;
    if ($unsigned) {
      $res = $value =~ /^(0|[1-9]\d*)(\.\d+)?$/;
    }
    else {
      $res = $value =~ /^-?(0|[1-9]\d*)(\.\d+)?$/;
    }

    return $res;
  }
}

#**********************************************************
=head2 xml_former($response, %PARAMS) - hash2xml

  Arguments
    $response string
    %PARAMS
      PRETTY    - good looking xml
      ROOT_NAME - parent element(name)
      ENCODING  - <?xml version="1.0" encoding="$PARAMS->{ENCODING}" ?>
      VERSION   - <?xml version="1.0" ?>
  Result
    xml string

=cut
#**********************************************************
sub xml_former {
  my ($response, $params) = @_;
  my @result = ();
  my ($nl, $indent);

  $indent = "";

  if ($params->{PRETTY}) {
    $nl = "\n";
  }
  else {
    $nl = "";
  }

  if ($params->{ENCODING}) {
    push @result,
      $indent, '<', '?xml version="1.0" encoding="', $params->{ENCODING}, '" ?', '>', $nl;
  }
  elsif ($params->{VERSION}) {
    push @result,
      $indent, '<', '?xml version="1.0" ?', '>', $nl;
  }

  if ($params->{ROOT_NAME}) {
    push @result,
      $indent, '<', $params->{ROOT_NAME}, '>', $nl,
      xml_former_body($response, { indent => "$indent  ", nl => $nl }),
      $indent, '</', $params->{ROOT_NAME}, '>', $nl;
  }
  else {
    push @result,
      xml_former_body($response, { indent => "$indent  ", nl => $nl }),
  }
  return (join('', @result));
}

#**********************************************************
=head2 xml_former_body($response, %PARAMS)

  Arguments
    $response string
    %PARAMS
      indent    - spaces
      nl        - next next line
  Result
    xml string

=cut
#**********************************************************
sub xml_former_body {
  my ($response, $params) = @_;
  my @result = ();

  if (ref $response eq 'HASH') {
    foreach my $key (sort keys %{$response}) {
      if (ref $response->{$key} eq 'HASH') {
        push @result,
          $params->{indent}, '<', $key, '>', $params->{nl},
          xml_former_body($response->{$key}, { indent => "$params->{indent}  ", nl => $params->{nl} }),
          $params->{indent}, '</', $key =~ /^\S+/g, '>', $params->{nl};
      }
      if (ref $response->{$key} eq 'ARRAY') {
        push @result,
          $params->{indent}, '<', $key, '>', $params->{nl},
          xml_former_body($response->{$key}, { indent => "$params->{indent}  ", nl => $params->{nl} }),
          $params->{indent}, '</', $key =~ /^\S+/g, '>', $params->{nl};
      }
      else {
        next if (ref $response->{$key} ne '');
        push @result,
          $params->{indent}, '<', $key, '>',
          $response->{$key},
          '</', $key =~ /^\S+/g, '>', $params->{nl};
      }
    }
  }
  elsif (ref $response eq 'ARRAY') {
    foreach my $key (@{$response}) {
      push @result, xml_former_body($key, { indent => "$params->{indent}  ", nl => $params->{nl} });
    }
    return join('', @result);
  }
  return (join('', @result));
}

#***********************************************************
=head2 escape_from_sql($input) - escapes data so it will be safe to put it to DB functions

  Same escaping is done in AXbills::HTML::form_parse.
  This function is meant to be used when AXbills::HTML::form_parse is not applied.

  Arguments:
    $input - data to be escaped. if it's hashref or arrayref, it's values will be recursively escaped.
             may contain nested hashrefs/arrayrefs

  Return:
    $result - escaped data

=cut
#***********************************************************
sub escape_for_sql {
  my ($input, $processed_refs) = @_;

  if (ref $input ne '') { #prevent infinite recursion when there are circular references
    if ($processed_refs->{int($input)}) {
      return $input;
    }
    $processed_refs->{int($input)} = 1;
  }

  if (ref $input eq '') {
    $input =~ s/\\/\\\\/g;
    $input =~ s/\"/\\\"/g;
    $input =~ s/\'/\\\'/g;
  }
  elsif (ref $input eq 'ARRAY') {
    foreach my $val (@$input) {
      $val = escape_for_sql($val, $processed_refs);
    }
  }
  elsif (ref $input eq 'HASH') {
    #TODO: escape hash keys?
    foreach my $key (keys %$input) {
      $input->{$key} = escape_for_sql($input->{$key}, $processed_refs);
    }
  }
  else {
    undef $input;
  }

  return $input;
}

#**********************************************************
=head2 camelize($string)

  Arguments:
     $string - make snake_case string to camelCase
     $attr
        RM_SPACES   - remove all spaces from

   Return:
     $camel_string
=cut
#**********************************************************
sub camelize {
  my ($string, $attr) = @_;

  $string =~ s{(\w+)}{
    ($a = lc $1) =~ s<(^[a-z]|_[a-z])><
      ($b = uc $1) =~ s/^_//;
      $b;
    >eg;
    $a;
  }eg;

  if ($string =~ /_/) {
    $string =~ s/_//eg;
  }

  if ($attr->{RM_SPACES}) {
    $string =~ s/ //eg;
  }

  return lcfirst($string);
}

#**********************************************************
=head2 decamelize($string)

  Arguments:
     $string - make camelCase string to snake_case

   Return:
     $snake_case
=cut
#**********************************************************
sub decamelize {
  my ($string) = @_;

  if ($string eq uc($string)) {
    return $string;
  }

  $string = ucfirst($string);

  $string =~ s{(\w+)}{
    ($a = $1) =~ s<(^[A-Z]|(?![a-z])[A-Z])><
      "_" . lc $1
    >eg;
    substr $a, 1;
  }eg;

  return uc($string);
}


#**********************************************************
=head2 vars2lang($text, $attr) — Parsing lang for input arguments

  Arguments:
    $text — string for parsing
    $attr — parameters for string

  Returns:
    string

  Examples:
    $lang{EXAMPLE} = 'Your %EXAMPLE% is bad!';
    vars2lang($lang{EXAMPLE}, { EXAMPLE => 'code' });

=cut
#**********************************************************
sub vars2lang {
  my ($text, $attr) = @_;

  my $result = $text;
  my %vars = %{$attr};
  for my $key (keys %vars) {
    $result = $result =~ s/%$key%/$vars{$key}/r;
  }

  return $result;
}

#**********************************************************
=head2 is_html($string)

  Arguments:
     $string - string with html or not

   Return:
     $result: boolean - is html or not
=cut
#**********************************************************
sub is_html {
  my ($string) = @_;

  if ($string =~ /<\/?[a-z][\s\S]*>/gm) {
    return 1;
  }
  return 0;
}

#**********************************************************
=head2 check_ip($require_ip, $ips) - Check ip

  Arguments:
    $require_ip - Required IP
    $ips        - IP list commas separated

  Results:
    TRUE or FALSE

  Examples:
    10.10.1.2,10.20.0.0/20

=cut
#**********************************************************
sub check_ip {
  my ($require_ip, $ips) = @_;

  if(! $require_ip) {
    return 0;
  }

  my @ip_arr         = split(/,\s?/, $ips);
  my $require_ip_num = ip2int($require_ip);

  foreach my $ip (@ip_arr) {
    if ($ip =~ /^(!?)(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/?(\d{0,2})/) {
      my $neg = $1 || 0;
      $ip = ip2int($2);
      my $bit_mask = $3;
      if ($bit_mask eq '') {
        $bit_mask=32;
      }
      my $mask = unpack("N", pack( "B*", ("1" x $bit_mask . "0" x (32 - $bit_mask)) ));
      if($neg && ($require_ip_num & $mask) == ($ip & $mask)) {
        return 0;
      }
      elsif (($require_ip_num & $mask) == ($ip & $mask)) {
        return 1;
      }
    }
  }

  return 0;
}

#**********************************************************
=head2 get_period_dates($attr) - Get period  intervals

  Arguments:
    $attr
      TYPE              0 - day, 1 - month
      START_DATE
      ACCOUNT_ACTIVATE
      PERIOD_ALIGNMENT

  Returns:
    Return string of period

=cut
#**********************************************************
sub get_period_dates {
  my ($attr) = @_;

  my $START_PERIOD = $attr->{START_DATE} || POSIX::strftime('%Y-%m-%d', localtime(time));

  my ($start_date, $end_date);

  if ($attr->{ACCOUNT_ACTIVATE} && $attr->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
    $START_PERIOD = $attr->{ACCOUNT_ACTIVATE};
  }

  my ($start_y, $start_m, $start_d) = split(/-/, $START_PERIOD);
  my $type = $attr->{TYPE} || 0;

  if ($type == 1) {
    my $days_in_month = ($start_m != 2 ? (($start_m % 2) ^ ($start_m > 7)) + 30 : (!($start_y % 400) || !($start_y % 4) && ($start_y % 25) ? 29 : 28));

    $end_date = "$start_y-$start_m-$days_in_month";
    if ($attr->{PERIOD_ALIGNMENT}) {
      $start_date = $START_PERIOD;
    }
    else {
      $start_date = "$start_y-$start_m-01";
      if ($attr->{ACCOUNT_ACTIVATE} && $attr->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
        $end_date = POSIX::strftime('%Y-%m-%d', localtime((POSIX::mktime(0, 0, 0, $start_d, ($start_m - 1), ($start_y - 1900), 0, 0, 0) + 30 * 86400)));
      }
    }

    return " ($start_date-$end_date)";
  }

  return '';
}

=head1 AUTHOR

АСР AXbills - https://billing.axiostv.ru

=cut

1;