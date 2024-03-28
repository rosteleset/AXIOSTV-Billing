package Portal::Api;

=head1 NAME

  Portal Api

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(in_array);
use Portal;

my Portal $Portal;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

  $Portal = Portal->new($self->{db}, $self->{admin}, $self->{conf});

  $self->{routes_list} = ();

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }

  return $self;
}

#**********************************************************
=head2 user_routes() - Returns available API paths

  Returns:
    {
      $resource_1_name => [ # $resource_1_name, $resource_2_name - names of API resources. always equals to first path segment
        {
          method  => 'GET',          # HTTP method. Path can be queried only with this method

          path    => '/users/:uid/', # API path. May contain variables like ':uid'.
                                     # these variables will be passed to handler function as argument ($path_params).
                                     # variables are always numerical.
                                     # example: if route's path is '/users/:uid/', and queried URL
                                     # is '/users/9/', $path_params will be { uid => 9 }.
                                     # if credentials is 'USER', variable :uid will be checked to contain only
                                     # authorized user's UID.

          handler => sub {           # handler function, coderef. Arguments that are passed to handler:
            my (
                $path_params,        # params from path. look at docs of path. hashref.
                $query_params,       # params from query. for details look at AXbills::Api::Router::new(). hashref.
                                     # keys will be converted from camelCase to UPPER_SNAKE_CASE
                                     # using AXbills::Base::decamelize unless no_decamelize_params is set
                $module_obj          # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

            $module_obj->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler as $module_obj. optional.

          type    => 'HASH',         # type of returned data. may be 'HASH' or 'ARRAY'. by default (if not set) it is 'HASH'. optional.

          credentials => [           # arrayref of roles required to use this path. if API user is authorized as at least one of
                                     # these roles access to this path will be granted. optional.
            'ADMIN'                  # may be 'ADMIN' or 'USER'
          ],

          no_decamelize_params => 0, # if set, $query_params for handler will not be converted to UPPER_SNAKE_CASE. optional.

          conf_params => [ ... ]     # variables from $conf to be returned in result. arrayref.
                                     # experimental feature, currently disabled
        },
        ...
      ],
      $resource_2_name => [
        ...
      ],
      ...
    }

=cut
#**********************************************************
sub user_routes {
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/user/portal/menu/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return $self->_portal_menu({
          UID       => $path_params->{uid} || '',
          DOMAIN_ID => $query_params->{DOMAIN_ID},
          MENU      => 1,
        });
      },
      credentials => [
        'USER', 'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/portal/news/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return $self->_portal_menu({
          UID       => $path_params->{uid} || '',
          DOMAIN_ID => $query_params->{DOMAIN_ID},
          LIST      => 1
        });
      },
      credentials => [
        'USER', 'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/portal/news/:string_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return $self->_portal_menu({
          UID        => $path_params->{uid} || '',
          ARTICLE_ID => $path_params->{id},
          DOMAIN_ID  => $query_params->{DOMAIN_ID},
          LIST       => 1
        });
      },
      credentials => [
        'USER', 'PUBLIC'
      ]
    },
  ];
}

#**********************************************************
=head2 _bot_link() return subscribe link for bots

  Arguments:
    UID: int        - user identifier
    DOMAIN_ID: int  - id of domain
    LIST: boolean   - return as object with keys topics, news
    MENU: boolean   - build as array of topics inside with news

  Returns:
    List of extra modules

=cut
#**********************************************************
sub _portal_menu {
  my $self = shift;
  my ($attr) = @_;

  my %menu = ();
  my %article_params = ();
  my %menu_params = ();
  my @topics = ();
  my @news = ();
  my $uid = $attr->{UID} || '';
  my $domain_id = $attr->{DOMAIN_ID} || '';
  my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $base_attach_link = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}/images/attach/portal" : '';

  $article_params{ID} = $attr->{ARTICLE_ID} if ($attr->{ARTICLE_ID});

  my $news_list = $Portal->portal_articles_list({
    %article_params,
    ARCHIVE   => 0,
    COLS_NAME => 1
  });

  return {
    errno  => 10901,
    errstr => "News not found with id $attr->{ARTICLE_ID}",
  } if (!($Portal->{TOTAL} && $Portal->{TOTAL} > 0) && $attr->{ARTICLE_ID});

  $menu_params{ID} = $news_list->[0]->{portal_menu_id} if ($attr->{ARTICLE_ID});

  my $menu_portal = $Portal->portal_menu_list({
    %menu_params,
    MENU_SHOW => 1,
    COLS_NAME => 1,
  });

  foreach my $menu (@{$menu_portal}) {
    my %topic = (
      id   => $menu->{id},
      name => $menu->{name},
    );

    $topic{url} = $menu->{url} if ($menu->{url});

    if ($attr->{MENU}) {
      $menu{$menu->{id}} = \%topic;
    }
    else {
      $menu{$menu->{id}} = 1;
      push @topics, \%topic;
    }
  }

  my $Users = {
    DOMAIN_ID        => 0,
    GID              => 0,
    ADDRESS_DISTRICT => '',
    ADDRESS_STREET   => '',
    UID              => '--'
  };

  if ($uid) {
    require Users;
    Users->import();
    $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
    $Users->info($uid);
    $Users->pi({ UID => $uid });
  }

  my $Tags = q{};
  if (in_array('Tags', \@main::MODULES)) {
    require Tags;
    Tags->import();
    $Tags = Tags->new($self->{db}, $self->{admin}, $self->{conf});
  }

  foreach my $news (@{$news_list}) {
    my $time_check = !$news->{etimestamp} || ($news->{utimestamp} && $news->{etimestamp} >= time && $news->{utimestamp} < time);
    my $gid_check = !$news->{gid} || $news->{gid} == $Users->{GID};
    my $domain_check = (!$news->{domain_id} ||
      ($domain_id && "$news->{domain_id}" eq "$domain_id") ||
      ($Users->{DOMAIN_ID} && $news->{domain_id} == $Users->{DOMAIN_ID}));

    my $address_check = (!$news->{dis_name} || $news->{dis_name} eq $Users->{ADDRESS_DISTRICT})
      && (!$news->{st_name} || $news->{st_name} eq $Users->{ADDRESS_STREET});

    my $tag_check = ($news->{tags} && !$uid) ? 0 : 1;
    if ($Tags) {
      my $tag = $Tags->tags_user({ COLS_NAME => 1, UID => $Users->{UID}, TAG_ID => $news->{tags} });
      $tag_check = defined($tag->[0]->{date}) || !$news->{tags};
    }

    if ($time_check && $gid_check && $domain_check && $address_check && $tag_check) {
      next if (!$menu{$news->{portal_menu_id}});
      my %news = (
        id                => $news->{id},
        importance        => $news->{importance},
        title             => $news->{title},
        content           => $news->{content},
        short_description => $news->{short_description},
        picture           => $news->{picture} ? "$base_attach_link/$news->{picture}" : '',
        on_main_page      => $news->{on_main_page},
        date              => $news->{date},
        topic_id          => $news->{portal_menu_id},
        permalink         => $news->{permalink},
      );

      if ($attr->{MENU}) {
        push @{$menu{$news->{portal_menu_id}}{news}}, \%news;
      }
      else {
        push @news, \%news;
      }
    }
  }

  if ($attr->{MENU}) {
    my @menu = map {$menu{$_}} sort keys %menu;
    return \@menu;
  }
  else {
    return {
      news   => \@news,
      topics => \@topics,
    };
  }
}

1;
