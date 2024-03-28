=head1 NAME

internet_unactive_postpaid();

=head1 HELP

TP_ID=

=cut

use strict;
use warnings;

our (
$Admin,
$db,
%conf,
$argv,
$debug,
);

use Internet;
use Tariffs;

my $Internet = Internet->new($db, $Admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $Admin);

internet_unactive_postpaid();

#**********************************************************
=head2 internet_unactive_postpaid()

=cut
#**********************************************************
sub internet_unactive_postpaid {
    
    if ($debug > 1) {
        print "internet_status_postpaid\n";
        if ($debug > 6) {
            $Internet->{debug} = 1;
            $Tariffs->{debug} = 1;
        }
    }
    
    if ($argv->{TP_ID}) {
        $LIST_PARAMS{TP_ID} = $argv->{TP_ID};
    }
    
    if ($argv->{LOGIN}) {
        $LIST_PARAMS{LOGIN} = $argv->{LOGIN};
    }
    
    my $tp_list = $Tariffs->list({
    TP_ID                => '_SHOW',
    POSTPAID_MONTHLY_FEE => 1,
    ABON_DISTRIBUTION    => '_SHOW',
    MONTH_FEE            => '>0',
    ID                   => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME            => 1,
    });
    
    foreach my $tp (@$tp_list) {
        
        my $month_fee = $tp->{month_fee};
        
        my $internet_list = $Internet->user_list({
        INTERNET_ACTIVATE => '_SHOW',
        LOGIN             => '_SHOW',
        DEPOSIT           => '_SHOW',
        CREDIT            => '_SHOW',
        TP_CREDIT         => '_SHOW',
        REDUCTION         => '_SHOW',
        COMPANY_ID        => '_SHOW',
        MONTH_FEE         => '>0',
        TP_ID             => $tp->{tp_id},
        INTERNET_STATUS   => 0,
        COLS_NAME         => 1,
        PAGE_ROWS         => 10000000,
        %LIST_PARAMS
        });
        
        foreach my $internet (@$internet_list) {
            my $uid = $internet->{uid};
            my $login = $internet->{login};
            my $company_id = $internet->{company_id};
            my $deposit = $internet->{deposit} || 0;
            my $credit = $internet->{credit} + $internet->{tp_credit} || 0;
            
            if ($internet->{reduction} && $internet->{reduction} == 100) {
                next;
            }
            
            if ($company_id) {
                if ($deposit <= (-$month_fee * ( 100 - $internet->{reduction}) / 100 ) - $credit) {
                    if ($debug > 1) {
                        print "company UID: $company_id ";
                        print "UID: $uid ";
                        print "login: $login ";
                        print "company deposit: $deposit ";
                        print "company credit: $credit ";
                        print "tp ID: $tp->{tp_id} ";
                    }
                    
                    if ($debug < 6) {
                        $Internet->user_change({
                        UID    => $uid,
                        STATUS => 5,
                        });
                        print "UID: $uid status 5c \n";
                    }
                }
            }
            
            if (! $company_id) {
                if ($deposit <= (-$month_fee * ( 100 - $internet->{reduction}) / 100 ) - $credit) {
                    if ($debug > 1) {
                        print "UID: $uid ";
                        print "login: $login ";
                        print "deposit: $deposit ";
                        print "credit: $credit ";
                        print "tp: $tp->{tp_id} ";
                    }
                    
                    if ($debug < 6) {
                        $Internet->user_change({
                        UID    => $uid,
                        STATUS => 5,
                        });
                        print "UID: $uid status 5nc \n";
                    }
                }
            }
        }
    }
    
    return 1;
    
}

internet_active_postpaid();

#**********************************************************
=head2 internet_active_postpaid()

=cut
#**********************************************************
sub internet_active_postpaid {
    
    if ($debug > 1) {
        print "internet_status_postpaid\n";
        if ($debug > 6) {
            $Internet->{debug} = 1;
            $Tariffs->{debug} = 1;
        }
    }
    
    if ($argv->{TP_ID}) {
        $LIST_PARAMS{TP_ID} = $argv->{TP_ID};
    }
    
    if ($argv->{LOGIN}) {
        $LIST_PARAMS{LOGIN} = $argv->{LOGIN};
    }
    
    my $tp_list = $Tariffs->list({
    TP_ID                => '_SHOW',
    POSTPAID_MONTHLY_FEE => 1,
    ABON_DISTRIBUTION    => '_SHOW',
    MONTH_FEE            => '>0',
    ID                   => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME            => 1,
    });
    
    foreach my $tp (@$tp_list) {
        
        my $month_fee = $tp->{month_fee};
        
        my $internet_list = $Internet->user_list({
        INTERNET_ACTIVATE => '_SHOW',
        LOGIN             => '_SHOW',
        DEPOSIT           => '_SHOW',
        CREDIT            => '_SHOW',
        TP_CREDIT         => '_SHOW',
        REDUCTION         => '_SHOW',
        COMPANY_ID        => '_SHOW',
        MONTH_FEE         => '>0',
        TP_ID             => $tp->{tp_id},
        INTERNET_STATUS   => 5,
        COLS_NAME         => 1,
        PAGE_ROWS         => 10000000,
        %LIST_PARAMS
        });
        
        foreach my $internet (@$internet_list) {
            my $uid = $internet->{uid};
            my $login = $internet->{login};
            my $company_id = $internet->{company_id};
            my $deposit = $internet->{deposit} || 0;
            my $credit = $internet->{credit} + $internet->{tp_credit} || 0;
            
            if ($internet->{reduction} && $internet->{reduction} == 100) {
                next;
            }
            
            if ($company_id) {
                if ($deposit > (-$month_fee * ( 100 - $internet->{reduction}) / 100 ) - $credit) {
                    if ($debug > 1) {
                        print "company UID: $company_id ";
                        print "UID: $uid ";
                        print "login: $login ";
                        print "company deposit: $deposit ";
                        print "company credit: $credit ";
                        print "tp ID: $tp->{tp_id} ";
                    }
                    if ($debug < 6) {
                        $Internet->user_change({
                        UID    => $uid,
                        STATUS => 0,
                        });
                        print "UID: $uid status 0c \n";
                    }
                }
            }
            
            
            if (! $company_id) {
                if ($deposit > (-$month_fee * ( 100 - $internet->{reduction}) / 100 ) - $credit) {
                    if ($debug > 1) {
                        print "UID: $uid ";
                        print "login: $login ";
                        print "deposit: $deposit ";
                        print "credit: $credit ";
                        print "tp: $tp->{tp_id} ";
                    }
                    
                    if ($debug < 6) {
                        $Internet->user_change({
                        UID    => $uid,
                        STATUS => 0,
                        });
                        print "UID: $uid status 0nc \n";
                    }
                }
            }
        }
    }
    
    return 1;
    
    
}

1;
