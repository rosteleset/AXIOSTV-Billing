#package AXbills::Templates;

=head1 NAME

  Base ABIllS Templates Managments

=cut

use strict;

my $domain_path = '';
our (
  $Bin,
  %FORM,
  $admin,
  $html,
  %lang,
  %conf
);

use FindBin '$Bin';

#**********************************************************
=head2 _include($tpl, $module, $attr) - templates

  Arguments
    $tpl
    $module
    $attr
      CHECK_ONLY
      SUFIX
      DEBUG

  Returns:
    Retun content

=cut
#**********************************************************
sub _include {
  my ($tpl, $module, $attr) = @_;

  my $sufix = ($attr->{pdf} || $FORM{pdf}) ? '.pdf' : '.tpl';
  $tpl .= '_' . $attr->{SUFIX} if ($attr->{SUFIX});

  start:
  $domain_path = '';
  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
  }
  elsif ($FORM{DOMAIN_ID}) {
    $domain_path = "$FORM{DOMAIN_ID}/";
  }

  $FORM{NAS_GID}='' if (!$FORM{NAS_GID});
  my $language = $html->{language} || q{};

  my @search_paths = (
    $Bin . '/../AXbills/templates/' . $domain_path . '/' . $FORM{NAS_GID} . '/' . $module . '_' . $tpl . "_$language" . $sufix,
    $Bin . '/../AXbills/templates/' . $domain_path . '/' . $FORM{NAS_GID} . '/' . $module . '_' . $tpl . $sufix,
    $Bin . '/../AXbills/templates/' . $domain_path  . $module . '_' . $tpl . "_$language" . $sufix,
          '../AXbills/templates/' . $domain_path . $module . '_' . $tpl . "_$language" . $sufix,
          '../../AXbills/templates/' . $domain_path . $module . '_' . $tpl . "_$language" . $sufix,
          '../../AXbills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,
          '../AXbills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,
    $Bin . '/../AXbills/templates/'. $domain_path . $module . '_' . $tpl . $sufix,
    $Bin . '/../AXbills/templates/' . $module . '_' . $tpl . "_$language" . $sufix,
    #Fixme for unifi hotspot
    $Bin . '/../../../../../../../AXbills/templates/'. $domain_path . $module . '_' . $tpl . $sufix,
    #Fixme for paysys_cons
    $Bin . '/../../../AXbills/templates/'. $domain_path . $module . '_' . $tpl . $sufix
  );

  foreach my $result_template (@search_paths) {
    if($attr->{DEBUG}) {
      print $result_template . "\n";
    }

    if (-f $result_template) {
      if ($attr->{CHECK_ONLY}) {
        return 1;
      }
      else {
        return ($FORM{pdf}) ? $result_template : tpl_content($result_template) ;
      }
    }
  }

  if ($attr->{EXTERNAL_CALL}) {
    foreach my $prefix ('../', @INC) {
      my $realfilename = "$prefix/$module/templates/$tpl$sufix";

      if($attr->{DEBUG}) {
        print $realfilename . "\n";
      }

      if (-f $realfilename) {
        return ($FORM{pdf}) ? $realfilename : tpl_content($realfilename);
      }
    }
  }

  if ($attr->{CHECK_ONLY}) {
    return 0;
  }

  if ($module) {
    $tpl = "modules/$module/templates/$tpl";
  }

  foreach my $prefix ('../', @INC) {
    my $realfilename = "$prefix/AXbills/$tpl$sufix";

    if($attr->{DEBUG}) {
      print $realfilename . "\n";
    }

    if (-f $realfilename) {
      return ($FORM{pdf}) ? $realfilename : tpl_content($realfilename);
    }
  }

  if ($attr->{SUFIX}) {
    $tpl =~ /\/([a-z0-9\_\.\-]+)$/i;
    $tpl = $1;
    $tpl =~ s/_$attr->{SUFIX}$//;
    delete $attr->{SUFIX};
    goto start;
  }

  return "No such module template [$tpl]\n";
}

#**********************************************************
=head2 tpl_content($filename, $attr)

=cut
#**********************************************************
sub tpl_content {
  my ($filename) = @_;
  my $tpl_content = '';

  if(! %lang) {
    %lang = ();
  }

  open(my $fh, '<', $filename) || die "Can't open tpl file '$filename' $!";
    while (<$fh>) {
      if (/\$/) {
        my $res = $_;
        if($res) {
          $res =~ s/\_\{(\w+)\}\_/$lang{$1}/sg;
          $res =~ s/\{secretkey\}//g;
          $res =~ s/\{dbpasswd\}//g;
          $res = eval " \"$res\" " if($res !~ /\`/);
          $tpl_content .= $res || q{};
        }
      }
      else {
        s/\_\{(\w+)\}\_/$lang{$1}/sg;
        $tpl_content .= $_;
      }
    }
  close($fh);

  return $tpl_content;
}

#**********************************************************
=head2 templates($tpl_name) - Show template

  Arguments:
    $tpl_name

  Return:
    tpl content

=cut
#**********************************************************
sub templates {
  my ($tpl_name) = @_;

  if(! $conf{base_dir}) {
    $conf{base_dir} = '/usr/axbills/';
  }

  my @search_paths = (
    #Lang tpls
    $Bin . "/../../AXbills/templates/" . '_' . "$tpl_name" . '.tpl',
    $Bin . "/../AXbills/templates/_$tpl_name" . "_$html->{language}.tpl",

    #Main tpl
    $Bin . "/../AXbills/templates/_$tpl_name" . ".tpl",
    $Bin . "/../../AXbills/main_tpls/$tpl_name" . ".tpl",
    $Bin . "/../AXbills/main_tpls/$tpl_name" . ".tpl",
    $conf{base_dir} . "/AXbills/main_tpls/$tpl_name" . ".tpl",
    $conf{base_dir} . "/AXbills/templates/$tpl_name" . ".tpl",
  );

  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
    @search_paths = (
      $Bin . "/../../AXbills/templates/$domain_path" . '_' . "$tpl_name" . "_$html->{language}.tpl",
      $Bin . "/../AXbills/templates/$domain_path" . '_' . "$tpl_name" . "_$html->{language}.tpl",
      $Bin . "/../../AXbills/templates/$domain_path" . '_' . "$tpl_name" . '.tpl',
      $Bin . "/../AXbills/templates/$domain_path" . '_' . "$tpl_name" . ".tpl",
      @search_paths
    );
  }

  #Nas path
  if ($FORM{NAS_GID} && -f $Bin . "/../AXbills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . "_$html->{language}.tpl") {
    return tpl_content($Bin . "/../AXbills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . "_$html->{language}.tpl");
  }
  elsif ($FORM{NAS_GID} && -f $Bin . "/../AXbills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . ".tpl") {
    return tpl_content($Bin . "/../AXbills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . ".tpl");
  }
  else {
    foreach my $tpl ( @search_paths ) {
      if (-f $tpl) {
        return tpl_content($tpl);
      }
    }
  }

  return "No such template [$tpl_name]";
}

1
