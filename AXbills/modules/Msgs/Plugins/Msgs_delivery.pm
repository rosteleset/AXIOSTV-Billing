package Msgs::Plugins::Msgs_delivery;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;
my $Msgs;

require Users;
Users->import();
my $users;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {
    MODULE      => 'Msgs',
    PLUGIN_NAME => 'Msgs_delivery'
  };

  if ($attr->{MSGS}) {
    $Msgs = $attr->{MSGS};
  }
  else {
    require Msgs;
    Msgs->import();
    $Msgs = Msgs->new($db, $admin, $CONF);
  }

  $users = Users->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME          => "Adding delivery",
    DESCR         => $lang->{ADDING_DELIVERY},
    BEFORE_CREATE => [ '_msgs_create_delivery', '_msgs_make_delivery' ]
  };
}

#**********************************************************
=head2 _msgs_create_delivery($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_create_delivery {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{DELIVERY_CREATE};

  $Msgs->msgs_delivery_add({
    %{$attr},
    TEXT        => $attr->{MESSAGE},
    SUBJECT     => $attr->{SUBJECT},
    SEND_DATE   => $attr->{DELIVERY_SEND_DATE},
    SEND_TIME   => $attr->{DELIVERY_SEND_TIME},
    SEND_METHOD => $attr->{DELIVERY_SEND_METHOD} || $attr->{SEND_TYPE},
    STATUS      => $attr->{DELIVERY_STATUS},
    PRIORITY    => $attr->{DELIVERY_PRIORITY},
  });

  $attr->{DELIVERY} = $Msgs->{DELIVERY_ID};
  $Msgs->{DELIVERY} = $Msgs->{DELIVERY_ID};
  $html->message('info', $lang->{INFO}, "$lang->{DELIVERY} $lang->{ADDED}") if (!$Msgs->{errno});

  return 0;
}

#**********************************************************
=head2 _msgs_make_delivery($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _msgs_make_delivery {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{DELIVERY};

  my $users_list = $attr->{USERS_LIST} ? $attr->{USERS_LIST} : ();
  my $uids = join(', ', map {$_->{uid}} @{$users_list}) || '';

  $Msgs->delivery_user_list_add({
    DELIVERY_ID => $attr->{DELIVERY},
    IDS          => $uids,
  });

  $html->message('info', $lang->{INFO}, "$Msgs->{TOTAL} $lang->{USERS_ADDED_TO_DELIVERY} №:$attr->{DELIVERY}") if (!$Msgs->{errno});

  return {
    RETURN_VALUE => $attr->{PREVIEW_FORM} ? 2 : 1,
    CALLBACK     => {
      FUNCTION     => 'msgs_admin_add_form',
      PARAMS       => { %{$attr} },
      PRINT_RESULT => 1
    }
  };
}

1;