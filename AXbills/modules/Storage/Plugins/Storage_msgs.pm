package Storage::Plugins::Storage_msgs;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db, $msgs_permissions);
my $json;
my AXbills::HTML $html;
my $lang;
my $Msgs;
our (%LIST_PARAMS);

use AXbills::Base qw(in_array);

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
    MODULE      => 'Storage',
    PLUGIN_NAME => 'Storage_msgs'
  };

  if ($attr->{MSGS}) {
    $Msgs = $attr->{MSGS};
  }
  else {
    require Msgs;
    Msgs->import();
    $Msgs = Msgs->new($db, $admin, $CONF);
  }

  require Storage;
  Storage->import();
  my $Storage;
  $Storage = Storage->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME     => "Attach equipment to ticket",
    POSITION => 'BOTTOM',
    DESCR    => $lang->{ATTACH_EQUIPMENT_TO_TICKET}
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

  $attr->{UID} ||= '';
  $attr->{chg} ||= $attr->{ID};
  return '' if !$attr->{chg} || !$attr->{index} || !$attr->{UID};

  my $table = $html->table({
    width      => '100%',
    title      => [ "ID", $lang->{NAME}, "$lang->{TYPE} $lang->{NAME}", $lang->{COUNT}, "SN", $lang->{ADMIN}, $lang->{DATE} ],
    caption    => $lang->{STORAGE},
    qs         => 1,
    ID         => 'MSGS_STORAGE_ITEMS',
    MENU       => $msgs_permissions->{1}{23} ? "$lang->{ADD}:index=$attr->{index}&STORAGE_MSGS_ID=$attr->{chg}&UID=$attr->{UID}:add" : '',
    DATA_TABLE => 1
  });

  my $msgs_storages = $Msgs->msgs_storage_list({
    ID                => '_SHOW',
    ARTICLE_TYPE_NAME => '_SHOW',
    ARTICLE_NAME      => '_SHOW',
    COUNT_MEASURE     => '_SHOW',
    SERIAL            => '_SHOW',
    DATE              => '_SHOW',
    ADMIN_NAME        => '_SHOW',
    MSGS_ID           => $attr->{chg},
    COLS_NAME         => 1,
    PAGE_ROWS         => 99999
  });

  foreach my $item (@{$msgs_storages}) {
    $table->addrow($item->{id}, $item->{article_name}, $item->{article_type_name}, $item->{count_measure},
      $item->{serial}, $item->{admin_name}, $item->{date})
  }

  return $table->show() || '';
}

1;
