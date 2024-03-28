package Iptv::Olltv v0.55.0;

=head1 NAME

  Olltv module

Olltv HTTP API

http://Oll.tv/
ispAPI v.2.1.4


=head1 VERSION

  Version 0.56
  Revision: 20181208

=head1 SYNOPSIS


=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.56;

use parent 'dbcore';
use AXbills::Base qw(load_pmodule);
use AXbills::Fetcher;
my $MODULE = 'Olltv';

my ($admin, $CONF);
my $md5;
my $json;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  $admin    = shift;
  $CONF     = shift;
  my $attr  = shift;

  $admin->{MODULE} = $MODULE;

  my $self = {};
  bless($self, $class);

  load_pmodule('Digest::MD5');
  load_pmodule('JSON');

  $md5 = Digest::MD5->new();
  $json = JSON->new->allow_nonref;

  if ($CONF->{IPTV_OLLTV_DEBUG} && $CONF->{IPTV_OLLTV_DEBUG} > 1) {
    $self->{debug}=$CONF->{IPTV_OLLTV_DEBUG};
  }

  $self->{SERVICE_NAME} = 'Olltv';
  $self->{VERSION}      = $VERSION;

  $self->{SERVICE_USER_FORM}          = 'olltv_user';
  $self->{SERVICE_USER_SCREEN_FORM}   = 'olltv_screens';
  $self->{SERVICE_USER_CHANNELS_FORM} = 'olltv_sub';
  $self->{SERVICE_CONSOLE}            = 'olltv_console';

  $self->{LOGIN}    = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{URL}      = $attr->{URL};
  $self->{debug}    = $attr->{DEBUG} || 0;

  $self->{request_count} = 0;

  return $self;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del{
  my $self = shift;
  my ($attr) = @_;

  #Delete serivece
  $self->user_negdeposit( $attr );
  my $result;
  #Delete account
#  if ( $attr->{FULL} ){
  $result = $self->_send_request( {
    ACTION => 'deleteAccount',
    %{$attr},
  });
#  }

  return $self;
}

#**********************************************************
=head2 _user_add($attr)

=cut
#**********************************************************
sub _user_add {
  my $self = shift;
  my ($attr) = @_;

  if (! $attr->{EMAIL}) {
    $self->{errno}=1000;
    $self->{errstr}="ERR_EMAIL_NOT_EXIST";
    return {};
  }

  my $result = $self->emailExists($attr);

  if ($result->{data} == 1) {
    $self->user_changeaccount($attr);
    if ($self->{errno} && $self->{errno} == 206) {
      delete $self->{errno};
    }
  }
  else {
    $result = $self->_send_request({
      ACTION => 'addUser',
      PARAMS => {
        email       =>  $attr->{EMAIL},
        account     =>  $attr->{ID},
        birth_date  =>  ($attr->{BIRTH_DATE}) ? $attr->{BIRTH_DATE} : undef,
        gender      =>  $attr->{GENDER},
        firstname   =>  $attr->{FIO},
        lastname    =>  $attr->{FIO2},
        password    =>  $attr->{PASSWORD},
        phone       =>  $attr->{PHONE},
        region      =>  $attr->{CITY},
        receive_news=>  ($attr->{SEND_NEWS}) ? 1 : 0,
        send_registration_email => 0,
        index       =>  $attr->{ZIP}
      },
    });
  }

  return $result;
}

#**********************************************************
=head2 emailExists($attr)

=cut
#**********************************************************
sub emailExists  {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({ ACTION => 'emailExists',
                                      PARAMS => {
                                        email       =>  $attr->{EMAIL},
                                      },
                                    });

  return $result;
}

#**********************************************************
=head2 user_changeaccount($attr)

=cut
#**********************************************************
sub user_changeaccount  {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({
    ACTION => 'changeAccount',
    PARAMS => {
      email       =>  $attr->{EMAIL},
      account     =>  $attr->{ID},
      birth_date  =>  ($attr->{BIRTH_DATE}) ? $attr->{BIRTH_DATE} : undef,
      gender      =>  $attr->{GENDER},
      firstname   =>  $attr->{FIO},
      lastname    =>  $attr->{FIO2},
      password    =>  $attr->{PASSWORD},
      phone       =>  $attr->{PHONE},
      region      =>  $attr->{CITY},
      receive_news=>  ($attr->{SEND_NEWS}) ? 1 : 0,
      send_registration_email => 0,
      index       =>  $attr->{ZIP}
    },
  });

  $self->{status} = $result->{status};

  return $self;
}

#**********************************************************
=head2 _user_change($attr)

=cut
#**********************************************************
sub _user_change {
  my $self = shift;
  my ($attr) = @_;

  $self->user_info({ ID => $attr->{ID} });

  #Not attached
  # attach
  if(! $self->{errno}) {
    if ($attr->{EMAIL} && $attr->{EMAIL} ne $self->{email}) {
      my $result = $self->_send_request({
        ACTION => 'changeEmail',
        PARAMS => {
          new_email => $attr->{EMAIL},
          email     => $self->{email}
        }
      });

      if ($self->{errno}) {
        return $result;
      }
    }
  }

  #List send
  my $result = $self->_send_request({
    ACTION => 'changeUserInfo',
    PARAMS => {
      ID          =>  $attr->{SUBSCRIBE_ID},
      #email       =>  $attr->{EMAIL},
      account     =>  $attr->{ID},
      birth_date  =>  ($attr->{BIRTH_DATE}) ? $attr->{BIRTH_DATE} : undef,
      gender      =>  $attr->{GENDER},
      firstname   =>  $attr->{FIO},
      lastname    =>  '',
      password    =>  $attr->{PASSWORD},
      phone       =>  $attr->{PHONE},
      region      =>  $attr->{CITY},
      receive_news=>  ($attr->{SEND_NEWS}) ? 1 : 0,
      send_registration_email => 0,
      index       =>  $attr->{ZIP}
    },
  });

  #Not attached
  # attach
  if($self->{errno} && $self->{errno} == 505) {
    $self->user_changeaccount($attr);
  }

  return $result;
}

#**********************************************************
=head2 user_info($attr)

  Arguments:
    $attr
      EMAIL           - email
      SUBSCRIBE_ID    - ID
      ID              - account

  Returns:

    $self

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $result;

  if ($attr->{FULL})   {
    if ($attr->{FULL} == 2)   {
      $result = $self->_send_request({ ACTION => 'getUserList',
                                       PARAMS => {
                                        email       =>  $attr->{EMAIL},
                                        ID          =>  $attr->{SUBSCRIBE_ID},
                                        account     =>  $attr->{ID},
                                      },
                                    });
      #my %result2;
      if ($attr->{SUBSCRIBE_ID}) {
        foreach my $val ( @{ $result->{data} } ) {
          if ($attr->{SUBSCRIBE_ID} eq $val->{ID}) {
            foreach my $id ( keys %{ $val  } ) {
              $self->{ $id } = $val->{$id};
            }
            last;
          }
        }
      }

      return $result;
    }
    else {
      $result = $self->_send_request({ ACTION => 'accountExists',
                                      PARAMS => {
                                        email       =>  $attr->{EMAIL},
                                        account     =>  $attr->{ID},
                                      },
                                    });
    }
  }
  else {
    #List send
    $result = $self->_send_request({ ACTION => 'getUserInfo',
                                      PARAMS => {
                                        email       =>  $attr->{EMAIL},
                                        account     =>  $attr->{ID},
                                      },
                                    });
  }

  if (ref $result->{data} eq 'HASH') {
    foreach my $id ( keys %{ $result->{data} } ) {
      $self->{ $id } = $result->{data}->{$id};
    }
  }

  return $result;
}

#**********************************************************
=head2 user_list($attr)

=cut
#**********************************************************
sub user_list {
  my $self = shift;
  #my ($attr) = @_;

  #List send
  my $result = $self->_send_request({ ACTION => 'getUserList',
                                    });

  return $result;
}

#**********************************************************
=head2 device_add($attr)

  Arguments:
    $attr
     ID
     SERIAL_NUMBER
     CID
     DEVICE_TYPE
     DEVICE_MODEL
     PIN or BINDING_CODE
     ACTIVATION_TYPE

  Returns:

=cut
#**********************************************************
sub device_add {
  my $self = shift;
  my ($attr) = @_;

  #List send
  my $result;
  if($attr->{DEVICE_TYPE} && $attr->{DEVICE_TYPE} eq 'smarttv') {
    return $result;
  }

  $result = $self->_send_request({ ACTION => 'addDevice',
                                      PARAMS => {
                                        account       =>  $attr->{ID},
                                        serial_number =>  $attr->{SERIAL_NUMBER},
                                        mac           =>  $attr->{CID},
                                        device_type   =>  $attr->{DEVICE_TYPE},
                                        device_model  =>  $attr->{DEVICE_MODEL},
                                        binding_code  =>  $attr->{PIN} || $attr->{BINDING_CODE},
                                        type          =>  $attr->{ACTIVATION_TYPE},
                                      },
                                    });

  return $result;
}

#**********************************************************
=head2 device_check_binding($attr)

=cut
#**********************************************************
sub device_check_binding {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->device_list();

  foreach my $line ( @{ $result->{data} } ) {
    if($attr->{BINDING_CODE} eq $line->{binding_code}) {
      return $line->{mac};
    }
  }

  return 0;
}

#**********************************************************
=head2 device_change($attr)

  Arguments:
    CID
    SERIAL_NUMBER

  Returns:

    $self

=cut
#**********************************************************
sub device_change {
  my $self = shift;
  my ($attr) = @_;

  if(! $attr->{CID} && ! $attr->{SERIAL_NUMBER}) {
    return $self;
  }

  my $result = $self->device_info($attr);

  $attr->{CID}=~s/://g;
  #_bp({ SHOW => ">> $result->{data}->{USER}" });

  if ( ! $result->{data} || ! $result->{data}->{USER}) {
    my $mac = $self->device_check_binding($attr);

    if($mac) {
      $self->device_del({ MAC  => $mac,
                          TYPE => 'device_change'
                        });
    }

    $self->device_add($attr);
  }

  return $self;
}

#**********************************************************
=head2 device_info($attr)

=cut
#**********************************************************
sub device_info {
  my $self = shift;
  my ($attr) = @_;

  my $result;

  if(! $attr->{CID} && ! $attr->{SERIAL_NUMBER}) {
    return $result;
  }

  #List send
  $result = $self->_send_request({ ACTION => 'deviceExists',
                                   PARAMS => {
                                     mac           =>  $attr->{CID},
                                     serial_number =>  $attr->{SERIAL_NUMBER},
                                   },
                                 });

  if ( ref $result->{data} eq 'HASH' ) {
    foreach my $id ( keys %{ $result->{data} } ) {
      $self->{ $id } = $result->{data}->{$id};
    }
  }
  else {
    $self->{errno}=406;
    $self->{errstr}='Device Not Found';
  }

  return $result;
}

#**********************************************************
=head2 device_del($attr)

=cut
#**********************************************************
sub device_del {
  my $self = shift;
  my ($attr) = @_;

  #List send
  my $result = $self->_send_request({ ACTION => 'delDevice',
                                      %$attr
                                    });

  return $result;
}

#**********************************************************
=head2 device_list($attr)

=cut
#**********************************************************
sub device_list {
  my $self = shift;
  #my ($attr) = @_;

  #List send
  my $result = $self->_send_request({ ACTION => 'getDeviceList',
                                    });

  return $result;
}

#**********************************************************
=head2 _pre_auth($attr)

=cut
#**********************************************************
sub _pre_auth {
  my $self = shift;

  my $result = $self->_send_request({ ACTION => 'auth2',
                                      DEBUG  => ($self->{debug} && $self->{debug} > 3) ? $self->{debug} : 0,
                                    });

  $self->{hash}=$result->{hash};

  return $result->{hash};
}

#**********************************************************
=head2 _send_request($attr)

  Arguments:

  Results:

=cut
#**********************************************************
sub _send_request {
  my $self = shift;
  my ($attr) = @_;

  my $request_url = ($CONF->{IPTV_OLLTV_TEST}) ? 'http://dev.oll.tv/ispAPI/'  : 'http://oll.tv/ispAPI/';
  my $result      = '';
  my $request     = '';
  my $params      = $attr->{PARAMS};

  if ($attr->{ACTION}){
    $request_url .= "$attr->{ACTION}/";

    if ($attr->{ACTION} eq 'auth2') {
      $params->{login}=$self->{LOGIN} || $CONF->{IPTV_OLLTV_USER};
      $params->{password}=$self->{PASSWORD} || $CONF->{IPTV_OLLTV_PASSWORD};
    }
  }

  if($self->{hash}) {
    $params->{hash}=$self->{hash};
  }
  elsif($attr->{ACTION} ne 'auth2') {
    my $hash = $self->_pre_auth();
    $params->{hash}=$hash;
  }

  if(defined($attr->{DATETIME})) {
    $params->{datetime}=$attr->{DATETIME};
  }

  if($attr->{start_date}) {
    $params->{start_date}=$attr->{start_date};
  }

  if ($attr->{FROM_DATE} && $attr->{FROM_DATE} =~ /(\d{4})\-(\d{2})\-(\d{2})/) {
    $params->{start}="$3.$2.$1";
  }

  if ($attr->{TO_DATE} && $attr->{TO_DATE} =~ /(\d{4})\-(\d{2})\-(\d{2})/) {
    $params->{end}="$3.$2.$1";
  }

  if($attr->{EXT_PARAMS}) {
    $request .= $attr->{EXT_PARAMS};
  }

  if($attr->{ID}) {
    $params->{account}=$attr->{ID};
  }
  elsif($attr->{account}) {
    $params->{account}=$attr->{account};
  }

  if($attr->{SERIAL_NUMBER}) {
    $params->{serial_number}=$attr->{SERIAL_NUMBER};
  }

  if ($attr->{MAC}) {
    $params->{mac}=$attr->{MAC};
  }

  if ($attr->{TYPE}) {
    $params->{type}=$attr->{TYPE};
  }

  if($attr->{EMAIL}) {
    $params->{email}=$attr->{EMAIL};
  }

  #if($attr->{ID}) {
  #  $params->{id}=$attr->{ID};
  #}

  if($attr->{DS_ACCOUNT}) {
    $params->{ds_account}=$attr->{DS_ACCOUNT};
  }

  if($attr->{SUB_ID}) {
    $params->{sub_id}=$attr->{SUB_ID};
  }

  $self->{request_count}++;
  $result = web_request($request_url, {
    REQUEST_PARAMS =>  $params,
    #POST          =>  $request,
    DEBUG          =>  (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug},
    CURL           =>  1,
    REQUEST_COUNT  =>  $self->{request_count}
  });

  my $perl_scalar ;

  if ($result =~ /^{/) {
    delete $self->{status};
    delete $self->{errno};
    delete $self->{errstr};

    $perl_scalar = $json->decode( $result );
    if($perl_scalar->{status}) {
      $self->{status} = $perl_scalar->{status};
      $self->{errno}  = $perl_scalar->{status};
      $self->{errstr} = $perl_scalar->{message};
    }
    elsif($perl_scalar->{warnings}) {
      $self->{status} = $perl_scalar->{status};
      $self->{errno}  = $perl_scalar->{status} || 1;
      $self->{errstr} = $perl_scalar->{warnings}->[0];
    }

    $self->{hash}=$perl_scalar->{hash} if ($perl_scalar->{hash});
  }

  return $perl_scalar;
}

#**********************************************************
=head2 bundle_add($attr)

=cut
#**********************************************************
sub bundle_add {
  my $self = shift;
  my ($attr) = @_;

  if(! $attr->{TP_FILTER_ID}) {
    $self->{errno} = 1002;
    $self->{errstr}= "ERR_TP_FILTER_NOT_EXIST";
    return $self;
  }

  if (! $attr->{BUNDLE_TYPE}) {
    $attr->{BUNDLE_TYPE} = 'subs_renew';
  }

  #List send
  my $result = $self->_send_request({ ACTION => 'enableBundle',
                                      PARAMS => {
                                        account       =>  $attr->{ID},
                                        sub_id        =>  $attr->{TP_FILTER_ID},
                                        type          =>  $attr->{BUNDLE_TYPE},
                                      },
                                    });

  return $result;
}


#**********************************************************
=head2 device_del_types($attr)

=cut
#**********************************************************
sub device_del_types {
  #my $self = shift;

  my %device_del_types = (
    'device_break_contract' => 'Окончание контракта',
    'device_change'         => 'Сервисная проблема оборудования'
  );

  return \%device_del_types;
}

#**********************************************************
=head2 device_activation_types($attr)

=cut
#**********************************************************
sub device_activation_types {
  #my $self = shift;

  my %device_activation_type = (
    'device_free'   => 'Новый контракт - 24 мес и оборудование за 1 грн',
    'device_buy'    => 'Новый контракт - покупка оборудования',
    'device_rent'   => 'Новый контракт - аренда оборудования',
    'device_change' => 'Сервисная замена текущего оборудования',
  );

  return \%device_activation_type;
}

#**********************************************************
=head2 bundle_del_types($attr)

=cut
#**********************************************************
sub bundle_del_types {
  #my $self = shift;

  my %bundle_del_types = (
    'subs_break_contract'   => 'Разрыв договора',
    'subs_negative_balance' => 'Отрицательный баланс',
    'subs_malfunction'      => 'Технические неполадки',
    'subs_vacation'         => 'Каникулы',
  );

  return \%bundle_del_types;
}

#**********************************************************
=head2 bundle_types()

=cut
#**********************************************************
sub bundle_types {
  #my $self = shift;

  my %bundle_type = (
    'subs_free_device' => 'Новый контракт - 24 мес и оборудование за 1 грн',
	  'subs_buy_device'  => 'Новый контракт - покупка оборудования',
    'subs_rent_device' => 'Новый контракт - аренда оборудования',
	  'subs_no_device'   => 'Новый контаркт - без оборудования',
 	  'subs_renew'       => 'Восстановление текущего контракта',
  );

  return \%bundle_type;
}

#**********************************************************
=head2 bundle_change($attr)

=cut
#**********************************************************
sub bundle_change {
  my $self = shift;
  my ($attr) = @_;

  if (! $attr->{DS_ACCOUNT}) {
    my $result = $self->user_info($attr);
    $attr->{DS_ACCOUNT} = $result->{data}->{ds_account};
    foreach my $line ( @{ $result->{data}->{bought_subs} }) {
      if($line->{service_type} == 1) {
        $attr->{OLD_SUB_ID} = $line->{sub_id};
      }
    }
  }

  my $result = $self->bundle_info($attr);
  #if (! $result->{account}) {
  #  my $result = $self->bundle_add($attr);
  #  return $result;
  #}

  if ($self->{debug}) {
    print (($attr->{OLD_SUB_ID} || 'Old Not set') .' -> '. ($attr->{TP_FILTER_ID} || 'New not set'));
  }

  if (! $attr->{OLD_SUB_ID}) {
    $result = $self->bundle_add($attr);
    return $result;
  }
  elsif ($attr->{OLD_SUB_ID} eq $attr->{TP_FILTER_ID}) {
    return $result;
  }

  $result = $self->_send_request({ ACTION => 'changeBundle',
                                   PARAMS => {
                                        email       =>  $attr->{EMAIL},
                                        account     =>  $attr->{ID},
                                        ds_account  =>  $attr->{DS_ACCOUNT},
                                        new_sub_id  =>  $attr->{TP_FILTER_ID},
                                        old_sub_id  =>  $attr->{OLD_SUB_ID}
                                      },
                                    });

  return $result;
}

#**********************************************************
=head2 bundle_info($attr)

=cut
#**********************************************************
sub bundle_info {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_send_request({ ACTION => 'checkBundle',
                                      PARAMS => {
                                        #email       =>  $attr->{EMAIL},
                                        account     =>  $attr->{ID},
                                        #ds_account  =>  $attr->{DS_ACCOUNT},
                                        sub_id      =>  $attr->{TP_FILTER_ID}
                                      },
                                    });

  return $result;
}

#**********************************************************
=head2 bundle_del($attr) - Disable/enable bundle

=cut
#**********************************************************
sub bundle_del {
  my $self = shift;
  my ($attr) = @_;

  #List send
  my $result = $self->_send_request({
    ACTION => 'disableBundle',
    %$attr,
    ACCOUNT  => $attr->{ID},
    SUB_ID   => $attr->{SUB_ID} || $attr->{TP_FILTER_ID},
    TYPE     => $attr->{TYPE},
  });

  return $result;
}

#**********************************************************
=head2 bundle_list($attr)

=cut
#**********************************************************
sub bundle_list {
  my $self = shift;
  #my ($attr) = @_;

  #List send
  my $result = $self->_send_request({ ACTION => 'getAllPurchases',
                                    });

  return $result;
}

#**********************************************************
=head2 user_negdeposit($attr)

  Arguments:
    ID    - User service ID

  Results:
    $self

=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->user_info({ ID => $attr->{ID} });
  my %bundles = ();

  for (my $i = 0 ; $i <= $#{ $self->{bought_subs} } ; $i++) {
    push @{ $bundles{$self->{bought_subs}->[$i]->{service_type}} }, $self->{bought_subs}->[$i]->{sub_id};
  }

  foreach my $bundle_priority (sort { $b <=> $a } keys %bundles) {
    my $group_bundles = $bundles{$bundle_priority};
    for(my $i = $#{ $group_bundles }; $i>=0; $i--) {
      my $bundle = $group_bundles->[$i];
      print " ($bundle_priority) $bundle\n" if($self->{debug});
      $result = $self->bundle_del(
         {
           ID     => $attr->{ID},
           SUB_ID => $bundle,
           TYPE   => 'subs_negative_balance',
         }
      );

   
      if (! $result->{data}) {
        $self->{errno} = $result->{code};
        $self->{errstr}= $result->{message};
        return $self;
      }
    }
  }

  return $self;
}


#**********************************************************
=head2 device_add($attr)

  Arguments:
    $attr
     ID
     SERIAL_NUMBER
     CID
     DEVICE_TYPE
     DEVICE_MODEL
     PIN or BINDING_CODE
     ACTIVATION_TYPE

  Returns:

=cut
#**********************************************************
sub parent_control  {
  my $self = shift;
  my ($attr) = @_;

  #List send
  my $result = $self->_send_request({ ACTION => 'resetParentControl',
                                      PARAMS => {
                                        account       =>  $attr->{ID},
                                        serial_number =>  $attr->{SERIAL_NUMBER},
                                        mac           =>  $attr->{CID},
                                        device_type   =>  $attr->{DEVICE_TYPE},
                                        device_model  =>  $attr->{DEVICE_MODEL},
                                        binding_code  =>  $attr->{PIN} || $attr->{BINDING_CODE},
                                        type          =>  $attr->{ACTIVATION_TYPE},
                                      },
                                    });

  return $result;
}


#**********************************************************
=head2 user_add($attr)

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->_user_add($attr);

  if ( !$attr->{TP_FILTER_ID} ){
    $self->{errno} = 1001;
    $self->{errstr} = 'Not found TP_FILTER_ID';
    $result = 1;
  }
  elsif ( !$self->{errno} ){
    $self->{SUBSCRIBE_ID}=$result->{data};

    if ( defined( $result->{status} ) && $result->{status} == 0 ){
      $result = $self->bundle_add( $attr );
      $attr->{BINDING_CODE} = $result->{data};
    }
    if ( $attr->{CID} && $attr->{BINDING_CODE} ){
      $attr->{DEVICE_MODEL} = 'MAG255' if (!$attr->{DEVICE_MODEL});
      $self->device_add( $attr );
    }
  }
  else{
    print "///// $self->{errno} ///////";
    $self->{errstr} = ($self->{errno} == 1000) ? 'WRONG_EMAIL' : $self->{errstr};
    $result = 1;
  }

  return $result;
}

#**********************************************************
=head2 user_change($attr)

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  if ( $attr->{DELETE} ){
    $self->user_del( { ID => $attr->{ID} } );
  }
  else{
    my @actions = ('_user_change', 'bundle_change', 'device_change');
    if ( $attr->{CHANGE_TP} ){
      @actions = ('bundle_change');
    }

    for ( my $i = 0; $i <= $#actions; $i++ ){
      my $fn = $actions[$i];
      $self->$fn( $attr );
      if ( $self->{errno} ){
        return $self;
      }
    }
  }

  return $self;
}

#**********************************************************
=head2 user_screens($attr)

  Arguments:
    $attr
      CID             - Device CID
      ID              -
      SERIAL_NUMBER   -
      DEVICE_TYPE     -
      DEVICE_MODEL    -
      BINDING_CODE    -
      ACTIVATION_TYPE -

=cut
#**********************************************************
sub user_screens {
  my $self = shift;
  my ($attr) = @_;

  if($attr->{del}) {
    if ( $attr->{CID} ){
      $self->device_del({
        %$attr,
        TYPE => $attr->{DEVICE_DEL_TYPE} || 'device_break_contract'
      });
    }

    $self->bundle_del( $attr );
  }
  else {
    if($attr->{CID}) {
      $self->device_info($attr);
      if (! $self->{errno}) {
        if($self->{USER}) {
          $self->{errno} = 119;
          $self->{errstr} = 'Device Exists';
          $self->{DEVICE_ID} = $self->{ID};
          return $self;
        }
      }
    }
    #http://dev.oll.tv/ispAPI/deviceExists/?hash=вставьтетутухеш&serial=122015j028685&mac=001a793330f5

    my $res = $self->bundle_add( $attr );

    if ($self->{errno}) {
      return $self;
    }

    my $result = $res->{data} || '';
    $attr->{BINDING_CODE} = $result;

    if ($attr->{CID} && $attr->{BINDING_CODE}) {
      $self->device_add(
        {
          ID              => $attr->{ID},
          SERIAL_NUMBER   => $attr->{SERIAL_NUMBER},
          CID             => $attr->{CID},
          DEVICE_TYPE     => $attr->{DEVICE_TYPE},
          DEVICE_MODEL    => $attr->{DEVICE_MODEL},
          BINDING_CODE    => $attr->{BINDING_CODE} || $result,
          ACTIVATION_TYPE => $attr->{ACTIVATION_TYPE}
        }
      );
    }
  }

  return $self;
}

1
