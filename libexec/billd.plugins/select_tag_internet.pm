=head1 SELECT_TAG_INTERNET

    Argument:
      TP_NAME           - Name tarif plans
      TAG_NAME          - Name set tag
      REDUCATION_DATE   - Reduction date set

    Function:
      select_tag_internet()

=cut

use strict;
use warnings FATAL => 'all';
use Tags;
use Users;
use Internet;
use Fees;

our (
  %lang,
  $argv,
  %conf,
  $Admin,
  $db,
);

my $Tags = Tags->new($db, $Admin, \%conf);
my $Internet = Internet->new($db, $Admin, \%conf);
my $Users = Users->new($db, $Admin, \%conf);
my $Fees = Fees->new($db, $Admin, \%conf);

select_tag_internet();

#**********************************************************
=head2 select_tag_internet()

  Arguments:
    -

  Return:
    -

=cut
#**********************************************************
sub select_tag_internet {
  my $users = select_tp_user({ TP_NAME => $argv->{TP_NAME} });

  if ($users) {
    my $users_no_tags = select_nan_tags( $users );

    if ($users_no_tags) {
      if ($argv->{TAG_NAME} && $argv->{REDUCATION_DATE}) {
        set_tag_reducation($users_no_tags, {
          TAG_NAME        => $argv->{TAG_NAME},
          REDUCATION_DATE => $argv->{REDUCATION_DATE},
          TP_NAME         => $argv->{TP_NAME}
        });
      }
      else {
        print "\nNot arguments: REDUCATION_DATE || TAG_NAME\n\n";
      }
    }
  }

  return 0;
}

#**********************************************************
=head2 select_tp_user()

  Arguments:
    $attr
      TP_NAME     - tarif plan name

  Return:
    @user_sort    - ref sorted array users deposit * 10

=cut
#**********************************************************
sub select_tp_user {
  my ($attr) = @_;

  my $list_internet = $Internet->user_list({
    TP_NAME   => $attr->{TP_NAME},
    MONTH_FEE => '_SHOW',
    COLS_NAME => 1
  });

  my $list_user = $Users->list({
    DEPOSIT   => '_SHOW',
    COLS_NAME => 1
  });

  my @user_sort = ();

  foreach my $tp_list (@$list_internet) {
    foreach my $user_list (@$list_user) {
      if ($tp_list->{uid} == $user_list->{uid}) {
        my $month_fee = int($tp_list->{month_fee}) * 10;
        my $dep = int($user_list->{deposit});

        next if ($dep < $month_fee);

        push @user_sort, $user_list;
      }
    }
  }

  return \@user_sort;
}

#**********************************************************
=head2 select_nan_tags()

  Arguments:
    $user_date    - hash users date

  Return:
    @user_no_tags - ref array users not tags

=cut
#**********************************************************
sub select_nan_tags {
  my ($user_date) = @_;
  my @user_no_tags = ();

  foreach my $user_no_tag (@$user_date) {
    my $tag = $Tags->tags_list({
      UID       => $user_no_tag->{uid},
      COLS_NAME => 1
    });

    if (!$tag) {
      push @user_no_tags, $user_no_tag;
    }
  }

  return \@user_no_tags;
}

#**********************************************************
=head2 set_tag_reducation()

  Arguments:
    $no_tag             - hash users not tag
    $attr               -
      TAG_NAME          - Tag name
      TP_NAME           - Tarif plans name
      REDUCATION_DATE   - Reduction date end

  Return:
    -

=cut
#**********************************************************
sub set_tag_reducation {
  my ($no_tag, $attr) = @_;

  my $tag_id = $Tags->list({
    NAME      => $attr->{TAG_NAME},
    COLS_NAME => 1
  });

  my $list_internet = $Internet->user_list({
    TP_NAME   => $attr->{TP_NAME},
    MONTH_FEE => '_SHOW',
    COLS_NAME => 1
  });

  my $month_sum = $list_internet->[0]->{month_fee};
  $month_sum = int($month_sum) * 10 if ($month_sum);

  foreach my $set_tag (@$no_tag) {
    $Users->change($set_tag->{uid}, {
      UID               => $set_tag->{uid},
      REDUCTION_DATE    => $attr->{REDUCATION_DATE},
      REDUCTION         => '100'
    });

    my $user_info = $Users->info($set_tag->{uid});

    $Fees->take($user_info, "$month_sum", {
      DESCRIBE => "Plugin TP: $list_internet->[0]->{tp_name}",
      DATE     => "$DATE $TIME"
    });

    $Tags->tags_user_change({
      IDS => $tag_id->[0]->{id},
      UID => $set_tag->{uid}
    });
  }

  return 0;
}

1;