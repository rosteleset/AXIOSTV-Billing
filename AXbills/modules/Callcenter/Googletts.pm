package Callcenter::Googletts;

use strict;
use warnings FATAL => 'all';

our (%EXPORT_TAGS);

use parent 'Exporter';

our $VERSION = 2.00;

our @EXPORT = qw(
  play_static
);

our @EXPORT_OK = qw(
  play_static
);

use LWP::UserAgent;
use File::Temp qw(tempfile);
use File::Copy qw(move);
use File::Path qw(mkpath);
our (
  $var_dir,
  $AGI
);

# Output audio sample rate
my $samplerate = 8000;

if (! $var_dir) {
  $var_dir = '/usr/axbills/var/';
}

# Output speed factor
my $speed = 1.2;

# SoX Version
my $sox_ver = 12;
my $intkey = "1234567890";
my $debug = 0;

#**********************************************************
=head2 play_static($text, $lang_short_)

  Arguments:
    $text
    lang_short_
    $attr
      BREAK_KEYS
      AGI

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub play_static {
  my ($filename, $lang_short_, $attr) = @_;

  if ($attr->{AGI}) {
    $AGI = $attr->{AGI};
  }

  my $cachedir = $var_dir . "/ivr/$lang_short_/";
  my $fexten = '';
  my $break_keys = $intkey;
  if ($attr->{BREAK_KEYS}) {
    $break_keys = $attr->{BREAK_KEYS};
  }

  # Setting filename extension according to sample rate.
  if ($samplerate == 16000) {
    $fexten = "sln16";
  }
  else {
    $fexten = "sln";
    $samplerate = 8000;
  }

  my $return_code = -1;
  if (-f "$cachedir/" . $filename . '.' . $fexten) {
    $AGI->verbose("$cachedir/" . $filename . '.' . $fexten);
    $return_code = playfile("$cachedir/$filename", $break_keys);
  }
  elsif (-f "$cachedir/" . $filename . '.wav') {
    $AGI->verbose("$cachedir/" . $filename . '.wav');
    convert_file($filename . '.wav', { LANG => $lang_short_ });
    $return_code = playfile("$cachedir/$filename", $break_keys);
  }

  return $return_code;
}

#**********************************************************
=head2 convert_file($filename, $attr)

  Arguments:
    $filename
    $attr

  Return:

=cut
#**********************************************************
sub convert_file {
  my ($filename, $attr) = @_;

  my $lang_short_ = $attr->{LANG} || '';
  my $name = 'convert_file';
  #my $tmpdir = '/tmp/';
  my $sox = `/usr/bin/which sox`;
  my $mpg123 = `/usr/bin/which mpg123`;
  my $cachedir = $var_dir . "/ivr/$lang_short_/";
  my $fexten = '';

  chomp($sox, $mpg123);

  # Setting filename extension according to sample rate.
  if ($samplerate == 16000) {
    $fexten = "sln16";
  }
  else {
    $fexten = "sln";
    $samplerate = 8000;
  }

  if (!-d $cachedir) {
    if (!mkdir($cachedir)) {
      ivr_log('LOG_ERR', "Can't create dir: '$cachedir' $!", { AGI_VERBOSE => 2 });
      return 0;
    }
  }

  warn "$filename Found sox in: $sox, mpg123 in: $mpg123\n" if ($debug);
  my ($tmpname, $ext) = split(/\./, $filename);

  # Convert mp3 file to 16bit 8Khz mono raw #
  if ($ext =~ /\.mp3/) {
    system($mpg123, "-q", "-w", "$cachedir/$tmpname" . '.wav', "$cachedir/$filename") == 0
      or die "$name: $mpg123 failed: $?\n";
  }

  if (!-f "$cachedir/$tmpname.$fexten") {
    my @soxargs = (
      $sox, "$cachedir/$filename", "-q", "-r", $samplerate, "-t", "raw",
      "$cachedir/$tmpname.$fexten"
    );

    if ($sox_ver >= 14) {
      push(@soxargs, ("tempo", "-s", $speed)) if ($speed != 1);
    }
    else {
      push(@soxargs, ("stretch", 1 / $speed, "200"))
        if ($speed != 1);
    }

    system(@soxargs) == 0 or die "$filename $sox failed: $?\n";
  }

  return 1;
}

#**********************************************************
=head2 playfile($file, $keys) = @_;

  Arguments:
    $file
    $keys

  Returns:
    Enter code

=cut
#**********************************************************
sub playfile {
  my ($file, $keys) = @_;

  print "STREAM FILE $file \"$keys\"\n";
  my $name = '';
  my @response = checkresponse();
  my $return_code;

  if ($response[0] >= 32 && chr($response[0]) =~ /[\w*#]/) {
    warn "$name Got digit ", chr($response[0]), "\n" if ($debug);
    $return_code = chr($response[0]);

    print "SET EXTENSION ", chr($response[0]), "\n";
    checkresponse();
    print "SET PRIORITY 1\n";
    checkresponse();
  }
  elsif ($response[0] == -1) {
    warn "$name Failed to play $file.\n";
  }

  if ($return_code) {
    return $return_code;
  }

  return $response[0];
}


#**********************************************************
=head2 checkresponse()

=cut
#**********************************************************
sub checkresponse {
  my $input = <STDIN>;
  my @values;
  my $name = '';

  chomp $input;
  if ($input =~ /^200 result=(-?\d+)\s?(.*)$/) {
    warn "name Command returned: $input\n" if ($debug);
    @values = ("$1", "$2");
  }
  else {
    $input .= <STDIN> if ($input =~ /^520-Invalid/);
    warn "$name Unexpected result: $input\n";
    @values = (-1, -1);
  }

  return @values;
}

#**********************************************************
=head2 voice_file($text, $lang_short_)

=cut
#**********************************************************
sub voice_file {
  my ($text, $lang_short_) = @_;

  my $filename = '';
  my $tmpdir = '/tmp/';

  #my $result_dir = $var_dir . '/ivr/';
  my $url = "http://translate.google.com/translate_tts";
  my $sox = `/usr/bin/which sox`;
  my $mpg123 = `/usr/bin/which mpg123`;
  my $usecache = 1;
  my $cachedir = $var_dir . "/ivr/$lang_short_/";

  #my $debug = 1;
  my $name = '';
  my $fexten = '';
  my ($fh, $tmpname);

  chomp($sox, $mpg123);
  warn "$name Found sox in: $sox, mpg123 in: $mpg123\n" if ($debug);

  # Setting filename extension according to sample rate.
  if ($samplerate == 16000) {
    $fexten = "sln16";
  }
  else {
    $fexten = "sln";
    $samplerate = 8000;
  }

  my $text_ = $text;
  if ($text =~ /^[A-Z0-9\_]+$/) {
    $text_ = eval "\"\$_$text\"";
    warn "Decode text: $text_\n" if ($debug);
  }

  $text_ =~ s/[\\|*~<>^\(\)\[\]\{\}[:cntrl:]]/ /g;
  $text_ =~ s/\s+/ /g;
  $text_ =~ s/^\s|\s$//g;
  die "No text passed for synthesis.\n" if (!length($text));

  $text_ .= "." unless ($text =~ /^.+[.,?!:;]$/);
  my @text = $text_ =~ /.{1,100}[.,?!:;]|.{1,100}\s/g;

  my $ua = LWP::UserAgent->new;
  $ua->agent("Mozilla/5.0 (X11; Linux; rv:8.0) Gecko/20110101");
  $ua->timeout(5);

  foreach my $line (@text) {
    $line =~ s/^\s+|\s+$//g;
    last if (length($line) == 0);
    if ($debug > 5) {
      warn "$name Text passed for synthesis: $line\n",
        "$name Language: $lang_short_, Interrupt keys: $intkey, Sample rate: $samplerate\n",
        "$name Caching: $usecache, Cache dir: $cachedir\n";
    }

    if ($usecache) {
      if ($text =~ /^[A-Z0-9\_]+$/) {
        $filename = $text;

        # Stream file from cache if it exists #
        if (-r "$cachedir/$filename.$fexten") {
          return "$cachedir/$filename.$fexten";
        }
      }
    }

    warn "$name URL passed: $url?tl=$lang_short_&q=$line\n" if ($debug > 5);

    my $ua_request = HTTP::Request->new('GET' => "$url?tl=$lang_short_&q=$line");
    my $ua_response = $ua->request($ua_request);
    die "$name Failed to fetch file.\n" unless ($ua_response->is_success);

    ($fh, $tmpname) = tempfile("ggl_XXXXXX", DIR => $tmpdir, UNLINK => 1);
    open($fh, ">", "$tmpname") or die "$name Failed to open file: $!\n";
    print $fh $ua_response->content;
    close $fh or warn "$name Failed to close file: $!\n";

    # Convert mp3 file to 16bit 8Khz mono raw #
    system($mpg123, "-q", "-w", "$tmpname.wav", $tmpname) == 0
      or die "$name $mpg123 failed: $?\n";

    my @soxargs = (
      $sox, "$tmpname.wav", "-q", "-r", $samplerate, "-t", "raw",
      "$tmpname.$fexten"
    );
    if ($sox_ver >= 14) {
      push(@soxargs, ("tempo", "-s", $speed)) if ($speed != 1);
    }
    else {
      push(@soxargs, ("stretch", 1 / $speed, "200")) if ($speed != 1);
    }

    system(@soxargs) == 0 or die "$name $sox failed: $?\n";

    # Playback and save file in cache #
    #$res = playback($tmpname, $intkey);
    if ($usecache) {
      mkpath("$cachedir") unless (-d "$cachedir");
      warn "$name Saving file $filename to cache\n" if ($debug > 5);
      move("$tmpname.$fexten", "$cachedir/$filename.$fexten");
    }

    #unlink glob "$tmpname*";
    #last if ($res > 0);
  }

  $filename = "$tmpname.$fexten";

  `echo "FILE: -- $filename --" >> /tmp/callcenter`;

  return $filename;
}

1;