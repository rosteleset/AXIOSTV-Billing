package Chatdb;

=head1 NAME

 Chat system
 Help Desk SQL

=cut

use strict;
use parent qw(dbcore);
use POSIX qw(strftime);
use Admins;

my $MODULE = 'Chatdb';

#**********************************************************
=head2 new($db, $conf, $admin)

=cut
#**********************************************************
sub new {
  my $self = {};
  my $class = shift;
  $self->{db} = shift;
  $self->{conf} = shift;

  my Admins $admin = shift;
  $admin->{MODULE} = $MODULE;
  $self->{admin} = $admin;

  bless($self, $class);

  return $self;
}

#**************************************************************
=head2 chat_add($attr)  -ADD user to DB

  Arguments:
    -

  Return:
    $self

=cut
#**************************************************************
sub chat_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('msgs_chat', $attr);

  return $self;
}

#**************************************************************
=head2 chat_list($attr)  -Get chat messages

  Arguments:
    MSG_ID            - message ID

  Return:
    list              - message params list

=cut
#**************************************************************
sub chat_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM msgs_chat WHERE num_ticket = ?;",
    undef,
    {
      COLS_NAME => 1,
      Bind      => [ $attr->{MSG_ID} ]
    });

  return $self->{list};
}

#**************************************************************
=head2 chat_count($attr)  -Get count of unread messages

  Arguments:
    MSG_ID            - message ID
    SENDER            - sender (user/admin)
    AID               - admin id (AID)
    UID               - user id (UID)
    COLS_NAME         - name column

  Return:
    count             - total messages

=cut
#**************************************************************
sub chat_count {
  my $self = shift;
  my ($attr) = @_;
  my @bind_value = ();
  my $WHERE = '';

  if ($attr->{SENDER}) {
    $WHERE = "mc.num_ticket=? AND mc.msgs_unread=0 AND mc. " . $attr->{SENDER} . "= 0";
    push @bind_value, $attr->{MSG_ID};
  }
  elsif ($attr->{AID}) {
    $WHERE = "mc.msgs_unread=0 AND mc.aid=0 AND mm.resposible=?";
    push @bind_value, $attr->{AID};
  }
  elsif ($attr->{UID}) {
    $WHERE = "mc.msgs_unread=0 AND mm.uid=? AND mc.uid=0";
    push @bind_value, $attr->{UID};
  }
  $self->query("SELECT COUNT(*) as count
    FROM msgs_chat mc
    JOIN msgs_messages mm
    ON mc.num_ticket=mm.id
    WHERE $WHERE;", undef,
    {
      COLS_NAME => 1,
      Bind      => \@bind_value
    });

  return $self->{list}[0]{count} || '0';
}

#**************************************************************
=head2 chat_change($attr)  -Get count of unread messages

  ArgumentsL
    MSG_ID            - message ID
    SENDER            - sender (user/admin)

  Return:
    -

=cut
#**************************************************************
sub chat_change {
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE msgs_chat SET msgs_unread = 1 WHERE num_ticket = ? AND msgs_unread=0 AND ? = 0;",
    undef,
    {
      COLS_NAME => 1,
      Bind      => [ $attr->{MSG_ID}, $attr->{SENDER} ]
    });

  return 1;
}

#**************************************************************
=head2 chat_message_info($attr)  -Get info of unread messages for admin and user

  Arguments:
    AID               - amdin ID (AID)
    UID               - user ID (UID)

  Return:
    list

=cut
#**************************************************************
sub chat_message_info {
  my $self = shift;
  my ($attr) = @_;
  my $WHERE = '';
  my @bind_value = ();

  if ($attr->{AID}) {
    $WHERE = "mc.msgs_unread = 0 AND mc.aid = 0 AND mm.resposible = ?";
    push @bind_value, $attr->{AID};
  }

  if ($attr->{UID}) {
    $WHERE = "mc.msgs_unread = 0 AND mc.uid = 0 AND mm.uid = ?";
    push @bind_value, $attr->{UID};
  }

  $self->query("SELECT DISTINCT mc.num_ticket,mm.uid, mm.subject, mm.id
    FROM msgs_chat mc
    JOIN msgs_messages mm
    ON mc.num_ticket=mm.id
    WHERE  $WHERE ;",
    undef,
    {
      COLS_NAME => 1,
      Bind      => \@bind_value
    }
  );

  return $self->{list};
}
