use strict;
use warnings;

use DateTime;

use lib '../',
  '../../../lib',
#  '../../../../',
  '../../../AXbills/mysql';


use Test::More;
use Internet::Service_mng;

our %lang = ();
our %conf;

do '../../../language/english.pl';

if (-f '../../../libexec/config.pl') {
  do '../../../libexec/config.pl';
}

subtest 'creates correct object' => sub {
  isa_ok(Internet::Service_mng->new, 'Internet::Service_mng');
};

my $DATE = '2017-11-12';

my @test_list = (
  {
    params  => {
      SERVICE => { EXPIRE => '2017-10-12' },
      DATE    => $DATE
    },
    name    => 'EXPIRE',
    result  => 'Expired: 2017-10-12'
  },
  {
    params  => {
      SERVICE => { JOIN_SERVICE => 5 }
    },
    name    => 'JOIN_SERVICE',
    result  => 'Join Service'
  },
  {
    params  => {
      USER    => { REDUCTION => 100 },
      SERVICE => { REDUCTION_FEE => 1 }
    },
    name    => '100% Discount',
    result  => ''
  },
  {
    params  => {
      USER    => {
        REDUCTION => 0,
        DEPOSIT   => 10,
        CREDIT    => 0,
      },
      SERVICE => {
        STATUS        => 0,
        DISABLE       => 0,
        TP_CREDIT     => 0,
        POSTPAID_ABON => 0,
        PAYMENT_TYPE  => 0,
        REDUCTION_FEE => 1,
        DAY_ABON      => 2
      },
      DATE => $DATE
    },
    name    => 'Day Abon Get next payment period',
    result  => 'Service will stop after 5 days ' #(2017-11-18)'
  },
  {
    params  => {
      USER    => {
        REDUCTION => 0,
        DEPOSIT   => 10,
        CREDIT    => 0,
      },
      SERVICE => {
        STATUS        => 0,
        DISABLE       => 0,
        TP_CREDIT     => 0,
        POSTPAID_ABON => 0,
        PAYMENT_TYPE  => 0,
        REDUCTION_FEE => 1,
        MONTH_ABON    => 100
      },
      DATE => $DATE
    },
    name    => 'Month Abon Get next payment period',
    result  => '2017-12-01'
  },
);

subtest 'Service warnuing' => sub {
    my $Service = Internet::Service_mng->new({
      lang => \%lang
    });

    foreach my $test ( @test_list ) {
      my ($result, $msg) = $Service->service_warning( $test->{params} );
      like( $result, qr/$test->{result}/, $test->{name}.': '.$result
      );
    }
};

my $next_expire = '2017-12-03';

@test_list = (
  {
    params  => {
      SERVICE => {
      },
      DATE    => $DATE
    },
    name    => 'WITHOT_PARAMS',
    result  => '2017-11-13',
    message => 'NET_DAY_CHANGE'
  },
  #status 5
  {
    params  => {
      SERVICE => {
        STATUS => 5,
      },
      DATE    => $DATE
    },
    name    => 'STATUS_5',
    result  => $DATE,
    message => 'STATUS_5'
  },
  {
    params  => {
      SERVICE => {
        EXPIRE  => '2017-09-10',
        TP_INFO => { AGE => 10 }
      },
      DATE    => $DATE
    },
    name    => 'service expired and renew now',
    result  => $DATE,
    message => 'STATUS_5'
  },
  {
    params  => {
      SERVICE => {
        EXPIRE  => $next_expire,
        TP_INFO => { AGE => 10 }
      },
      DATE    => $DATE
    },
    name    => 'service expired laters',
    result  => $next_expire,
    message => 'STATUS_5'
  },
  {
    params  => {
      SERVICE => {
        MONTH_ABON => 10,
        TP_INFO   => { AGE => 10 },
      },
      DATE    => $DATE
    },
    name    => 'Month fee 10',
    result  => '2017-12-01',
    message => 'MONTH_FEE'
  },
  {
    params  => {
      SERVICE => {
        MONTH_ABON => 10,
        TP_INFO   => { AGE => 10 },
        ACTIVATE  => '2017-11-20'
      },
      DATE    => $DATE
    },
    name    => 'Month fee 10 with active date',
    result  => '2017-12-21',
    message => 'MONTH_FEE'
  },
  {
    params  => {
      SERVICE => {
        MONTH_ABON     => 10,
        FIXED_FEES_DAY => 1,
        TP_INFO        => { AGE => 10 },
        ACTIVATE       => '2017-11-20'
      },
      DATE    => $DATE
    },
    name    => 'Month fee 10 with active date and fixed day in tp',
    result  => '2017-12-20',
    message => 'MONTH_FEE'
  }
);

# get_next_abon_date
subtest 'get_next_abon_date' => sub {
    my $Service = Internet::Service_mng->new;

    foreach my $test ( @test_list ) {
      $Service->get_next_abon_date( $test->{params} );
      if(! like( $Service->{ABON_DATE}, qr/$test->{result}/,
          $test->{name}.': '. ($Service->{ABON_DATE} || '!!!!')
          . ' MESSAGE: ' . ($Service->{message} || q{})
          . ' ERROR: '. ($Service->{errno} || 0)
      )) {
        diag("here's what went wrong");
      }
    }
};


use Internet;
our $db    = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname},
  $conf{dbuser}, $conf{dbpasswd}, { %conf, CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
our $admin = Admins->new($db, \%conf);

my $user_service = Internet->new($db, $admin, \%conf);

@test_list = (
  {
    params  => {
    },
    name    => 'Blind test',
    result  => 'NOT_ALLOW'
  },
  {
    params  => {
      INTERNET_USER_CHG_TP => 1
    },
    name    => 'Test allow change tp',
    result  => 'NOT_DEFINED_SERVICE'
  },
  {
    params  => {
      INTERNET_USER_CHG_TP => 1,
      UID                  => 1,
    },
    name    => 'Test service obj',
    result  => 'NOT_DEFINED_SERVICE_OBJ'
  },
  {
    params  => {
      INTERNET_USER_CHG_TP => 1,
      UID                  => 1,
      SERVICE              => $user_service
    },
    name    => 'Test service',
    result  => 'NOT_DEFINED_SERVICE_ID'
  },
  {
    params  => {
      INTERNET_USER_CHG_TP => 1,
      UID                  => 1,
      SERVICE              => $user_service,
      ID                   => 1
    },
    name    => 'Test service not exist',
    result  => 'NOT_ALLOW'
  },
  {
    params  => {
      INTERNET_USER_CHG_TP => 1,
      UID                  => 1,
      SERVICE              => $user_service,
      TP_GID               => 10,
      ID                   => 1
    },
    name    => 'Test service not exist',
    result  => 'NOT_ALLOW_TP_CHANGE'
  },
  {
    params  => {
      INTERNET_USER_CHG_TP => 1,
      UID                  => 1,
      SERVICE              => $user_service,
      ID                   => 1
    },
    name    => 'Test service not exist',
    result  => 'NOT_ALLOW_TP_CHANGE'
  },

);

subtest 'Service tp change' => sub {
    my $Service = Internet::Service_mng->new;

    foreach my $test ( @test_list ) {
      $Service->service_chg_tp( $test->{params} );
      like( $Service->{message}, qr/$test->{result}/, $test->{name}.': '
       . ' MESSAGE: ' .$Service->{message}
       . ' ERROR: '. $Service->{errno}
      );
    }
};


done_testing;

1;