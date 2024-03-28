package Equipment::Plugins::Equipment_msgs_info;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db, $msgs_permissions);
my $json;
my AXbills::HTML $html;
my $lang;
my $Msgs;

use AXbills::Base qw/in_array/;

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
  $msgs_permissions = $attr->{MSGS_PERMISSIONS};

  my $self = {
    MODULE      => 'Equipment',
    PLUGIN_NAME => 'Equipment_msgs_info'
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
    NAME     => "Equipment info for Msgs",
    POSITION => 'RIGHT',
    DESCR    => $lang->{DISPLAYING_USER_EQUIPMENT_INFORMATION} || 'Displaying user equipment information'
  };
}

#**********************************************************
=head2 plugin_show($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub plugin_show {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$msgs_permissions->{1}{22};
  return '' if !$attr->{UID};
  return '' if (!in_array('Internet', \@::MODULES));
  return '' if ($admin->{MODULES} && !$admin->{MODULES}{Equipment});

  my $Internet = Internet->new($db, $admin, $CONF);

  my $user_info = $Internet->user_info($attr->{UID});
  my $info = $html->tpl_show(::_include('internet_equipment_form', 'Internet'), $user_info, {
    ID => 'internet_equipment_form', OUTPUT2RETURN => 1
  });

  return $info;
}


1;
