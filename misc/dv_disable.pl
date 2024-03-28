#!/usr/bin/perl -w
=head1 NAME

 Users disable

=cut

use strict;
use warnings FATAL => 'all';

BEGIN{
  use FindBin '$Bin';
  require $Bin . '/../libexec/config.pl';
  unshift( @INC,
    $Bin . '/../',
    $Bin . '/../lib',
    $Bin . '/../AXbills',
    $Bin . "/../AXbills/mysql" );
}

use Sys::Hostname;
use AXbills::SQL;
use AXbills::Base qw(parse_arguments _bp sendmail in_array);
use Users;
use Admins;
use Customers;
use Dv;

our (
  %conf,
  @MODULES,
  $db,
  $html,
  $DATE,
  $TIME,
  %lang
);

my $DEBUG   = 0;
my $version = 0.7;
# Unused
my $last_payments_days = 60;

do "language/$conf{default_language}.pl";

$db = AXbills::SQL->connect( $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef } );

my $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );

my $users = Users->new( $db, $admin, \%conf );
my $Dv = Dv->new( $db, $admin, \%conf );
my $Internet;
if (in_array('Internet', \@MODULES)){
  require Internet;
  Internet->import();
  $Internet = Internet->new($db, $admin, \%conf);
}


my %ADMIN_REPORT = (HOSTNAME => hostname());

my $ARGS = parse_arguments( \@ARGV );
if ( defined( $ARGS->{help} ) ){
  help();
  exit;
}

if ( $ARGS->{CONFIG_FILE} ){
  my $parameters_from_file = parse_ini_file( $ARGS->{CONFIG_FILE} );
  #  _bp( "Parameters from file", $parameters_from_file, { TO_CONSOLE => 1 } );

  $ARGS = { %{$parameters_from_file}, %{$ARGS} };
}

$DEBUG = ($ARGS->{DEBUG}) ? $ARGS->{DEBUG} : $DEBUG;

$last_payments_days = (defined $ARGS->{LAST_PAYMENT_DAY}) ? $ARGS->{LAST_PAYMENT_DAY} : $last_payments_days;

#if ( defined( $ARGS->{LAST_PAYMENTS_DAYS} ) ){
my $output = get_debtors();
my $subject = "$lang{DEBETORS}: $lang{DISABLE}";
#}
#else{
#  $output = pop_debtors();
#  $subject = "$lang{DEBETORS}: $lang{ENABLE}";
#}

if ( $ARGS->{SENDMAIL} ){
  if ( $ARGS->{SENDMAIL} !~ /@/ ){
    print "Error: Wrong  e-mail '$ARGS->{SENDMAIL}'\n";
  }
  else{
    sendmail( "$conf{ADMIN_MAIL}", "$ARGS->{SENDMAIL}", "$ADMIN_REPORT{HOSTNAME}: $subject",
      "$output", "$conf{MAIL_CHARSET}", "2 (High)" );
  }
}
else{
  if ( $DEBUG > 0 ){
    print $output;
  }
}


#**********************************************************
=head2 get_debtors($attr) - get debetors and add to non payment status

=cut
#**********************************************************
sub get_debtors{
  #my ($attr) = @_;

  my $HAVING_DATE = ( $last_payments_days > 0 ) ? "AND max(p.date) < CURDATE() - INTERVAL $last_payments_days DAY " : '';

  my $intenet_table = 'dv_main';
  my $WHERE = 'AND dv.tp_id=tp.id';
  
  if(in_array('Internet', \@MODULES)) {
    $intenet_table = 'internet_main';
    $WHERE = 'AND dv.tp_id=tp.tp_id';
  }

  $users->query( "SELECT u.id,
  IF(company.id IS NULL, b.deposit, cb.deposit) AS u_deposit,
  IF(u.company_id=0, u.credit, IF (u.credit=0, company.credit,0)) AS u_credit,
  MAX(p.date) AS last_payment_date,
  tp.credit AS tp_credit,
  u.uid,
  COUNT(s.id),
  IF(company.id IS NULL,ext_b.deposit,ext_cb.deposit) AS ext_deposit,
  u.company_id,
  u.activate,
  u.expire,
  u.gid,
  dv.disable,
  tp.id AS tp_id
FROM (users u, $intenet_table dv, tarif_plans tp)
  LEFT JOIN payments p ON (u.uid = p.uid)
  LEFT JOIN bills b ON (u.bill_id = b.id)
  LEFT JOIN companies company ON (u.company_id=company.id)
  LEFT JOIN bills cb ON (company.bill_id=cb.id)
  LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)
  LEFT JOIN bills ext_cb ON (company.ext_bill_id=ext_cb.id)
  LEFT JOIN shedule s ON (s.uid=u.uid)
WHERE u.uid=dv.uid
      $WHERE
      AND u.disable=0
      AND dv.disable=0
      AND (u.activate<=CURDATE() OR u.activate='0000-00-00')
      AND (u.expire > CURDATE()  OR u.expire='0000-00-00')
GROUP BY u.id
HAVING (u_credit+u_deposit) < 0 $HAVING_DATE;", undef, { COLS_NAME => 1 } );

  die "$users->{sql_errstr}" if ($users->{errno});

  my $debtors_list = $users->{list};

  my $result = "Debtors\n";
  $result .= sprintf( "%-19s| %-8s | %-14s| %-30s| %-7s |\n",
    $lang{LOGIN},
    $lang{DEPOSIT},
    $lang{CREDIT},
    "$lang{PAYMENTS} $lang{DATE}",
    "TP $lang{CREDIT}"
  );
  $result .= "---------------------------------------------------------------------\n";

  foreach my $user ( @{ $debtors_list } ){
    chomp($user);
    if ( $user->{disable} == 0 && should_be_disabled( $user ) ){
      $result .= sprintf( "%-14s| %7.4f | %-8.2f| %-14s | %9.2f |\n",
        $user->{id},
        $user->{u_deposit},
        $user->{u_credit},
        $user->{last_payment_date} || '0000-00-00 00:00:00',
        $user->{tp_credit} || 0
      );

      if ( $DEBUG < 6 ){
        if (in_array('Internet', \@MODULES)){
          $Internet->user_change( {
            UID    => $user->{uid},
            STATUS => $ARGS->{SET_STATUS} || 5
          } );
        }
        else {
          $Dv->change( {
              UID    => $user->{uid},
              STATUS => $ARGS->{SET_STATUS} || 5
            } );
        }
      }
    }
  }

  $result .= "---------------------------------------------------------------------\n";
  $result .= "$lang{TOTAL}: $users->{TOTAL}\n";

  return $result;
}

#**********************************************************
=head2 should_be_disabled($user) - checks if user should be disabled according to additionals parameters

  Arguments:
    $user - DB line

  Returns:
   1 if should be disabled, 0 otherwise

=cut
#**********************************************************
sub should_be_disabled{
  my ($user) = @_;
  return 1 unless (defined $ARGS->{TP_SUM});

  my $max_allowed_debt = $ARGS->{TP_SUM}->{$user->{tp_id}} || 0;

  print "$user->{id} ($user->{u_deposit} + $user->{u_credit} + $user->{tp_credit}) <= $max_allowed_debt; \n" if ($DEBUG);
  return ($user->{u_deposit} + $user->{u_credit} + $user->{tp_credit}) <= $max_allowed_debt;
}

#**********************************************************
=head2 parse_parameters_file($filename)

  Arguments:
    $filename - path to file

  Returns:
    hash_ref

  File should look as folowing:
    [ARGS]
    PARAMETER_NAME=PARAMETER_VALUE
    DEBUG=1
    LAST_PAYMENT_DAYS=50

    [TP_SUM]
    2=24
    5=16

=cut
#**********************************************************
sub parse_ini_file{
  my ($filename) = @_;

  my %parameters = ();

  open( my $parameters_file, '<', $filename ) or die( "Can't open $filename \n" );

  my %last_hash = ();
  my $last_hash_name = '';
  while(<$parameters_file>){
    chomp( $_ );
    $_ =~ s/ //g;
    next if ($_ eq '');

    if ( $_ =~ /\[.*\]/ ){

      if ( $last_hash_name ne '' ){
        $parameters{$last_hash_name} = { %last_hash };
        %last_hash = ();
      }
      else{
        %parameters = (%last_hash);
        %last_hash = ();
      }

      ($last_hash_name) = $_ =~ /\[(.*)\]/;
    }
    else{
      my ($param, $value) = split( "=", $_ );
      next if (!(defined $param && defined $value));
      $last_hash{$param} = $value;
    }
  }
  # Save last section
  $parameters{$last_hash_name} = { %last_hash };

  close $parameters_file;

  return \%parameters;
}



#**********************************************************
# add debetors from non payment status
#**********************************************************
#sub pop_debtors{
#  my ($attr) = @_;
#
#  $users->query( "SELECT u.id,
#if(company.id IS NULL, b.deposit, cb.deposit) AS DEPOSIT,
#if(u.company_id=0, u.credit,
#  if (u.credit=0, company.credit, u.credit)) AS CREDIT,
#max(p.date),
#if(company.id IS NULL,ext_b.deposit,ext_cb.deposit) AS EXT_DEPOSIT,
#tp.credit,
#u.uid,
#count(s.id),
#u.company_id,
#u.activate,
#u.expire,
#u.gid
#
#FROM (users u, dv_main dv, tarif_plans tp)
#LEFT JOIN payments p ON (u.uid = p.uid)
#LEFT JOIN bills b ON (u.bill_id = b.id)
#LEFT JOIN companies company ON (u.company_id=company.id)
#LEFT JOIN bills cb ON (company.bill_id=cb.id)
#LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)
#LEFT JOIN bills ext_cb ON (company.ext_bill_id=ext_cb.id)
#LEFT JOIN shedule s ON (s.uid=u.uid)
#WHERE u.uid=dv.uid
#   and dv.tp_id=tp.id
#   and u.disable=0
#   and dv.disable<>4
#   and (u.activate<=curdate() or u.activate='0000-00-00')
#   and (u.expire > curdate()  or u.expire='0000-00-00')
#
#GROUP BY u.uid
#HAVING (tp.credit+CREDIT+DEPOSIT) > 0;" );
#
#  my $result = "Pop Debetors\n";
#  $result .= sprintf( "%-14s| %14s| %8s| %19s| %8s|\n", "$_LOGIN", "$_DEPOSIT", "$_CREDIT", "$_PAYMENTS $_DATE",
#    "TP $_CREDIT" );
#  $result .= "-----------------------------------------------------------------------------\n";
#
#  foreach my $line ( @{ $users->{list} } ){
#    $result .= sprintf( "%-14s| %14.2f| %8.2f| %-14s| %8.2f|\n", $line->[0], $line->[1], $line->[2], "$line->[3]",
#      $line->[5] || 0 );
#
#    if ( $DEBUG < 6 ){
#      $Dv->change( { UID => $line->[6],
#          STATUS         => 0
#        } );
#
#      if ( $Dv->{TP_INFO}->{MONTH_FEE} && $Dv->{TP_INFO}->{MONTH_FEE} > 0 && !$Dv->{STATUS} ){
#        dv_get_month_fee( $Dv, { QUITE => 1 } );
#      }
#    }
#
#  }
#
#  $result .= "-----------------------------------------------------------------------------\n";
#  $result .= "$_TOTAL: $users->{TOTAL}\n";
#
#  return $result;
#}


#**********************************************************
#
#Make month feee
#**********************************************************
#sub dv_get_month_fee{
#  my ($Dv, $attr) = @_;
#
#  #Get active price
#  #  if ($Dv->{TP_INFO}->{ACTIV_PRICE}) {
#  my $user = $users->info( $Dv->{UID} );
#  $Dv->{ACTIVATE} = $user->{ACTIVATE};
#  #    my $date  = ($user->{ACTIVATE} ne '0000-00-00') ? $user->{ACTIVATE} : $DATE;
#  #    my $time  = ($user->{ACTIVATE} ne '0000-00-00') ? '00:00:00' : $TIME;
#  #
#  #    $fees->take($user, $Dv->{TP_INFO}->{ACTIV_PRICE},
#  #                              { DESCRIBE  => "$_ACTIVATE $_TARIF_PLAN",
#  #   	                            DATE      => "$date $time"
#  #  	                           });
#  #
#  #    $html->message('info', $_INFO, "$_ACTIVATE $_TARIF_PLAN") if (! $attr->{QUITE});
#  #   }
#
#
#  #Get month fee
#  if ( $Dv->{TP_INFO}->{MONTH_FEE} > 0 ){
#
#    my $sum = $Dv->{TP_INFO}->{MONTH_FEE};
#
#    my $user = $users->info( $Dv->{UID} );
#
#    if ( $Dv->{TP_INFO}->{EXT_BILL_ACCOUNT} ){
#      $user->{BILL_ID} = $user->{EXT_BILL_ID} if ($user->{EXT_BILL_ID});
#    }
#
#    my $message = '';
#    #Current Month
#    my ($y, $m, $d) = split( /-/, $DATE, 3 );
#
#    my ($active_y, $active_m, $active_d) = split( /-/, $Dv->{ACTIVATE}, 3 );
#
#    if ( int( "$y$m$d" ) < int( "$active_y$active_m$active_d" ) ){
#      return;
#    }
#
#    if ( $Dv->{TP_INFO}->{PERIOD_ALIGNMENT} && !$Dv->{TP_INFO}->{ABON_DISTRIBUTION} ){
#      $message = "$_MONTH_ALIGNMENT, ";
#      my $days_in_month = ($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($y % 400) || !($y % 4) && ($y % 25) ? 29 : 28));
#
#      if ( $Dv->{ACTIVATE} && $Dv->{ACTIVATE} ne '0000-00-00' ){
#        $days_in_month = ($active_m != 2 ? (($active_m % 2) ^ ($active_m > 7)) + 30 : (!($active_y % 400) || !($active_y % 4) && ($active_y % 25) ? 29 : 28));
#        $d = $active_d;
#      }
#
#      $conf{START_PERIOD_DAY} = 1 if (!$conf{START_PERIOD_DAY});
#      $sum = sprintf( "%.2f", $sum / $days_in_month * ($days_in_month - $d + $conf{START_PERIOD_DAY}) );
#    }
#
#    return 0 if ($sum == 0);
#
#    my $periods = 0;
#    if ( $active_m > 0 && $active_m < $m ){
#      $periods = $m - $active_m;
#    }
#    elsif ( $active_m > 0 && ( $active_m >= $m && $active_y < $y) ){
#      $periods = 12 - $active_m + $m;
#    }
#
#    $message .= "$_MONTH_FEE: $sum ($Dv->{TP_INFO}->{TP_ID})";
#
#    if ( $Dv->{TP_INFO}->{ABON_DISTRIBUTION} ){
#      $sum = $sum / ( ($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($y % 400) || !($y % 4) && ($y % 25) ? 29 : 28)) );
#      $message .= " - $_ABON_DISTRIBUTION";
#    }
#
#    $m = $active_m if ($active_m > 0);
#    for ( my $i = 0; $i <= $periods; $i++ ){
#      if ( $m > 12 ){
#        $m = 1;
#        $active_y = $active_y + 1;
#      }
#
#      $m = sprintf( "%.2d", $m );
#
#      if ( $i > 0 ){
#        $sum = $Dv->{TP_INFO}->{MONTH_FEE};
#        $message = "$_MONTH_FEE: $sum ($Dv->{TP_INFO}->{TP_ID})";
#        $DATE = "$active_y-$m-01";
#        $TIME = "00:00:00";
#      }
#      elsif ( $Dv->{ACTIVATE} && $Dv->{ACTIVATE} ne '0000-00-00' ){
#        $DATE = "$active_y-$m-$active_d";
#        $TIME = "00:00:00";
#
#        if ( $Dv->{TP_INFO}->{PERIOD_ALIGNMENT} ){
#          $users->change( $Dv->{UID}, { ACTIVATE => '0000-00-00',
#              UID                                => $Dv->{UID} } );
#        }
#      }
#
#      $fees->take( $users, $sum, { DESCRIBE => $message,
#          METHOD                            => 1,
#          DATE                              => "$DATE $TIME"
#        } );
#
#      if ( $fees->{errno} ){
#        #$html->message('err', $_ERROR,
#        $output .= "[$fees->{errno}] $fees->{errstr}\n";
#      }
#      else{
#        #$html->message('info', $_INFO, $message);
#        $output .= $message . "\n";
#      }
#
#      $m++;
#    }
#
#  }
#
#}

#**********************************************************
# get arp records
#**********************************************************
sub help{

  print << "[END]";
Disable non payment users

Version $version
  dv_disable.pl
    CONFIG_FILE=         - path to ini-like file with arguments and custom tariff plan minimal deposit
    LAST_PAYMENTS_DAYS=  - last payment days (Default: 60)
    SENDMAIL=            - Add E-mail addres for sending
    DEBUG=1..7           - Debug mode (7 means dry run)
    SET_STATUS=1..6      - Status to disable user with ( Default: 5 (Too small deposit))
    help                 - this help

  Config file example:
  ---START OF EXAMPLE FILE---
    DEBUG=0
    LAST_PAYMENT_DAY=0

    [TP_SUM]
      100=-4
      102=-10
      103=-20
      104=-25
  --- END OF EXAMPLE FILE ---

  Arguments provided in console override ones defined in file

  Custom tariff plan minimal deposit - set max debt for user having defined tariff plan lower (or bigger) than 0;

[END]

}
1
