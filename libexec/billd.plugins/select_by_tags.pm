=head1 SELECT_BY_TAGS

    Argument:
      NAME - Tag name, select by tag

    Function:
      tags_list_users()

=cut

use strict;
use warnings FATAL => 'all';
use Tags;
use Users;

our (
  %lang,
  $argv,
  %conf,
  $Admin,
  $db,
);

tags_list_users();

#**********************************************************
=head2 tags_list_users()

  Arguments:
    -

  Return:
    -

=cut
#**********************************************************
sub tags_list_users {

  my $Users = Users->new($db, $Admin, \%conf);
  my $Tags = Tags->new($db, $Admin, \%conf);

  my $list_user = $Users->list({
    REDUCTION => '100',
    COLS_NAME => 1
  });

  foreach my $select_user (@$list_user) {
    my $tags_list = $Tags->tags_list({
      UID       => $select_user->{uid},
      NAME      => $argv->{NAME},
      COLS_NAME => 1
    });

    if ($tags_list) {
      $Users->change($select_user->{uid}, {
        UID       => $select_user->{uid},
        REDUCTION => '0'
      });

      $Tags->user_del({ UID => $select_user->{uid}, TAG_ID => $tags_list->[0]->{id} })
    }
  }

  return 0;
}

1;