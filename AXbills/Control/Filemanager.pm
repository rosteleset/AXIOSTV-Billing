=head1 NAME

  Filemanager

=cut

use strict;
use warnings FATAL => 'all';

our ($db,
 $admin,
 $html,
 %lang,
 %conf
);

if(! $conf{TPL_DIR}) {
  $conf{TPL_DIR} = '/usr/axbills/AXbills/templates';
}

my $FROM_DIR = $conf{TPL_DIR} . "/attach";

#**********************************************************
=head2 file_tree - adds content to a tree

=cut
#**********************************************************
sub file_tree {
  if($FORM{TREE}){
    $FORM{TREE} =~ s/\.{1,}\///g;
    $FORM{TREE} =~ s/\;//g;
  }

  if($FORM{del}){
    $FORM{del} =~ s/\.{1,}\///g;
    $FORM{del} =~ s/\;//g;
    my $file_name = $FROM_DIR . '/' . $FORM{del};

    if(! unlink $file_name) {
      $html->message( 'err', "Could not unlink $file_name: $!" );
    }
  }

  my $content   = ($FORM{TREE}) ? find_files($FROM_DIR . '/' . $FORM{TREE}) : find_files($FROM_DIR);
  
  my $tree_tpl = $html->tpl_show(templates('filemanager_tree'), 
    {TITLE => 'Attach/' . ($FORM{TREE} || ''), CONTENT => $content}, {OUTPUT2RETURN => 1});
  

  print $html->element('div', $tree_tpl, { class => 'col-md-5', OUTPUT2RETURN => 1 } );

  return 1;
}

#**********************************************************
=head2 find_files($path) - find files in the specified folder

  Arguments:
    $path - The path to the folder

=cut
#**********************************************************
sub find_files {

  my ($base_dir)   = @_;
  my $path         = '';
  my $open_path    = '';
  my @folders      = ();
  my @files        = ();
  my $content      = '';
  my $mtime        = '';
  my @time         = ();
  my $path_for_del = '';
  my $date_chg     = '';

  if(! -d $base_dir) {
    $html->message( 'err', "Can't opendir $base_dir not exist" );
    return 0;
  }

  opendir(my $dh, $base_dir) or warn $html->message( 'err', "Can't opendir $base_dir: $!" );
  while (my $fname = readdir $dh) {

    next if (($fname eq '.') || ($fname eq '..'));

    $mtime = (stat "$base_dir/$fname")[9];
    @time = localtime($mtime);
    $date_chg = sprintf("%02d-%02d-%04d", $time[3], (1 + $time[4]), (1900 + $time[5]));

    if (-d "$base_dir/$fname") {
      $path = "$base_dir/$fname";
      $path =~ s/$FROM_DIR\///;

      ($path_for_del) = $path =~ /(.*)\//;
      push @folders, 
       $html->button(" $fname", "index=$index&TREE=$path",
       { class => "row default col-md-7 text-left", ADD_ICON => "fa fa-folder" }) 
       . $html->element('div', $date_chg, { class => "col-md-5 text-left"}) 
    }

    if (-f "$base_dir/$fname") {

      $path      = "$base_dir/$fname";
      $path      =~ s/$FROM_DIR\/// ; 
      $open_path = $path;
      $path      =~ s/\/$fname//;
      $path      =~ s/$fname//;
      my @count_ = $fname =~ m/_/g;
      my $btn;
      if ($fname =~ /\d*_\d*_.*/){
        my ($uid)      = $path  =~ /.*\/(.*)/;
        my ($msg_chg)  = $fname =~ /(\d*)_\d*_.*/;
        my ($real_fname) = $fname =~ /\d*_\d*_(.*)/;

        $btn = $html->button(" $real_fname", "index=" . get_function_index('msgs_admin') . "&UID=$uid&chg=$msg_chg#last_msg",
          { class => "row default col-md-7 text-left", ADD_ICON => "fa fa-file" });
      }
      elsif (scalar @count_ < 2){
        $btn = $html->button(" $fname", "index=$index&TREE=$path", 
          { class => "row default col-md-7 text-left", ADD_ICON => "fa fa-file" });
      }
      else{
        my ($real_fname) = $fname =~ /.*\_(.*)/;
        $btn = $html->button(" $real_fname", "index=$index&TREE=$path", 
          { class => "row default col-md-7 text-left", ADD_ICON => "fa fa-file" });
      } 

      push @files, 
       $btn 
       . $html->element('div', $date_chg, { class => "col-md-3 text-left"})
       . $html->button("", "index=$index&del=$open_path&TREE=$path", 
        { class => "text-danger btn-sm col-md-1", ADD_ICON => "fa fa-trash" }); 
    }
  }
  closedir $dh;

  if($base_dir ne $FROM_DIR){
    ($path) = $base_dir =~ /(.*)\//;
    if($path eq $FROM_DIR){
      $path = '';
    }
    else{
      $path =~ s/$FROM_DIR\///;
    }
    $content .= "<br>" . $html->button(" /.. ", "index=$index&TREE=$path",
     { class => "row default col-md-12 text-left", ADD_ICON => "fa fa-folder-open" });
  }
  foreach my $folder (@folders) {
    $content .= $html->br() . $folder;
  }
  foreach my $file (@files) {
    $content .= $html->br() . $file;
  }

  return $content;
}

1;