#billd plugin

use JSON;
use Users;
use Contacts;
use AXbills::Auth::Core;

my $Users = Users->new($db, $admin, \%conf);
my $Contacts = Contacts->new($db, $admin, \%conf);

my $Auth = AXbills::Auth::Core->new( {
  CONF      => \%conf,
  AUTH_TYPE => ucfirst('Facebook') } );

my $json = JSON->new->utf8;

get_social_info_facebook();

#**********************************************************
=head2 get_social_info() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub get_social_info_facebook {
  my ($attr) = @_;

  my $users_list = $Users->list({ 
    _FACEBOOK  => 'facebook',
    #_INSTAGRAM => '_SHOW', 
    #_VK        => '_SHOW',
    #_GOOGLE    => '_SHOW',
    FACEBOOK   => 1,
    PAGE_ROWS  => 5000,
    COLS_NAME  => 1, });
    
  foreach $user (@$users_list){
    unless ($user->{_facebook}) {
      next;
    }

    my ($users_social_id) =  $user->{_facebook} =~ /(\d+)/;

    if(!$users_social_id || $users_social_id eq ''){
      next;
    }

    my $result = $Auth->get_info({CLIENT_ID => $users_social_id});
  
    my %only_result = map { uc($_) => $result->{result}->{$_} } keys %{$result->{result}};

    if($only_result{BIRTHDAY}){
      my ($month, $day, $year) = split '/', $only_result{BIRTHDAY};
      $only_result{BIRTHDAY} = ($year || '0000') . '-' . ($month || '00') . '-' . ($day || '00');
    }
    
    my $friends_count = 0;
    if($only_result{FRIENDS}{summary}{total_count}){
      $friends_count = $only_result{FRIENDS}{summary}{total_count};

      delete $only_result{FRIENDS}{summary}{total_count};
    }

    my $json_likes;
    if($only_result{LIKES}){
      $json_likes = $json->encode($only_result{LIKES}{data});
      
      delete $only_result{LIKES};
    }

    my $photo = '';
    if($only_result{PICTURE}{data}{url}){
      $photo = $only_result{PICTURE}{data}{url};
    }

    my $locale = '';
    if($only_result{LOCALE}){
      $locale = $only_result{LOCALE};
    }
    
    $Contacts->social_add_info({
      UID               => $user->{uid},
      SOCIAL_NETWORK_ID => 1,
      REPLACE           => 1,
      LIKES             => $json_likes,
      FRIENDS_COUNT     => $friends_count,
      LOCALE            => $locale,
      PHOTO             => $photo,
      %only_result
    });
  }

  return 1;
}


1