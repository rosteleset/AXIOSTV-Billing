=head1

  IPoE Extra reports

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(int2byte);
use Internet::Ipoe;

our(
  $db,
  $admin,
  %conf,
  $html,
  %lang,
  $var_dir
);

my $Internet_ipoe  = Internet::Ipoe->new( $db, $admin, \%conf );

#**********************************************************
=head2 ipn_unknow_ips() - List of unknown ips

=cut
#**********************************************************
sub ipoe_unknow_ips{

  if ( !$FORM{sort} ){
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'desc';
  }

  if ( !$conf{UNKNOWN_IP_LOG} ){
    $html->message( 'warn', '', "$lang{DISABLE} \$conf\{UNKNOWN_IP_LOG\}" );
  }

  if ( $FORM{del_all} && $FORM{COMMENTS} ){
    $Internet_ipoe->unknown_ips_del();
    if ( !_error_show( $Internet_ipoe ) ){
      $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
    }
  }

  my $list = $Internet_ipoe->unknown_ips_list( { %LIST_PARAMS } );
  my $table = $html->table(
    {
      caption    => "$lang{UNKNOWN} IP",
      width      => '100%',
      title      => [ $lang{DATE}, $lang{FROM}, $lang{TO}, $lang{SIZE}, 'NAS' ],
      pages      => $Internet_ipoe->{TOTAL},
      qs         => $pages_qs,
      header     => $html->button( "$lang{DEL} $lang{ALL}", "index=$index&del_all=1",
        { MESSAGE => "$lang{DEL} $lang{ALL}?", class => 'btn btn-secondary' } ),
      ID         => 'IPN_UNKNOWN_LIST'
    }
  );

  foreach my $line ( @{$list} ){
    $table->addrow( $line->[0],
      $html->button( $line->[1],
        "index=7&search=1&type=999&LOGIN=" . $line->[1],
        { ex_params => 'TARGET=ip' } ),
      $html->button( $line->[2],
        "index=7&search=1&type=999&LOGIN=" . $line->[2],
        { ex_params => 'TARGET=ip' } ),
      $line->[3],
      $line->[4]
    );
  }
  print $table->show();

  $table = $html->table(
    {
      width => '100%',
      rows  =>
        [ [ "$lang{TOTAL}: " . $html->b( $Internet_ipoe->{TOTAL} ), "$lang{TRAFFIC}: " . $html->b( int2byte( $Internet_ipoe->{TOTAL_TRAFFIC} ) ) ] ],
      ID    => 'IPN_UNKNOWN_LIST_TOTAL'
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 ipoe_ft_queue() - Flow-tools queue

=cut
#**********************************************************
sub ipoe_ft_queue{
  my $ft_dir = $conf{INTERNET_FT_DIR} || ($var_dir . '/log/ipn/');

  my @contents = ();

  if ( opendir my $fh, "$ft_dir" ){
    @contents = grep !/^\.\.?$/, readdir $fh;
    closedir $fh;
  }
  else{
    $html->message( 'err', $lang{ERROR}, "Can't open dir '$ft_dir' $!" );
    return 1;
  }

  my $table = $html->table(
    {
      width       => '600',
      caption     => "Flow-tools queue",
      title_plain => [ $lang{NAME}, $lang{DATE}, $lang{SIZE}, '-' ],
      ID          => 'IPN_FT_QUEUE',
    }
  );

  foreach my $filename ( sort @contents ){
    my ($size, $mtime) = (stat( "$ft_dir/$filename" ))[7,9];
    my $date = POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( $mtime ) );
    $table->addrow( $filename,
      $date,
      int2byte( $size ),
      #$html->button($lang{DEL}, "index=$index&del=$filename", { MESSAGE => "$lang{DEL} $filename?", class => 'del' })
    );
  }

  print $table->show();

  return 1;
}

1;