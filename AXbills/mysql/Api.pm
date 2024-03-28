package Api;
=head NAME

  Api - module for store requests on api.cgi

=head1 VERSION

   VERSION: 0.02
   UPDATE: 20220129

=cut

use strict;
use parent qw(dbcore);

our $VERSION = 0.03;
my $MODULE = 'Api';

#**********************************************************
=head2 new($db, $admin, $conf) - create object;

 Arguments:
    db    - ref to DB
    admin - current Web session admin
    conf  - ref to %conf

  Return:
    self object

  Examples:
    my $Api   = Api->new($db, $admin, \%conf);
=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf) = @_;

  $admin->{MODULE} = $MODULE;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf
  };

  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 add($attr) - add data to database;

  Arguments:

  attr
    UID            - users identifier (if its users route);
    AID            - admins identifier (if its admins route);
    SID            - user's session id (if its users route);
    REQUEST_URL    - URL of request on billing;
    REQUEST_BODY   - BODY of request on billing;
    RESPONSE       - response from billing on request;
    HTTP_STATUS    - HTTP status of request;
    HTTP_METHOD    - HTTP method of request;
    IP             - Remote IP address of request;
    DATE           - Date time when called api path;
    RESPONSE_TIME  - Time of script running;
  Returns:
    self object;

  Examples:
    $Api->add(
          {
            UID             => 1,
            SID             => 'D3MfMwTf9NjfgcCK',
            REQUEST_URL     => 'https://example/api.cgi/users/login'
            REQUEST_BODY    => "{ "login": "test", "password": "123456" }",
            RESPONSE        => "{ "sid": "zj4BcvqkJhihNxCq", "login": "test", "uid": 1 }",
            FUNCTION        => 'auth_user',
            HTTP_STATUS     => 200
          }
      );
=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('api_log', $attr);

  return $self;
}

#**********************************************************
=head2 list($attr) - take list data from database;

  Arguments:

  attr
    SORT            - sort column;
    DESC            - DESC / ASC;
    PG              - page id;
    PAGE_ROWS       - count of raws returned
  Returns:
    list of raws;

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',              'INT',    'al.id'       ,                     1],
    [ 'ERROR_MSG',       'INT',    'al.error_msg',                     1],
    [ 'IP',              'INT',    'al.ip', 'INET_NTOA(al.ip) AS ip',  1],
    [ 'DATE',            'DATE',   'al.date',                          1],
    [ 'UID',             'INT',    'al.uid',                           1],
    [ 'AID',             'INT',    'al.aid',                           1],
    [ 'SID',             'STR',    'al.sid',                           1],
    [ 'REQUEST_URL',     'STR',    'al.request_url',                   1],
    [ 'REQUEST_BODY',    'STR',    'al.request_body',                  1],
    [ 'REQUEST_HEADERS', 'STR',    'al.request_headers',               1],
    [ 'RESPONSE',        'STR',    'al.response',                      1],
    [ 'RESPONSE_TIME',   'DOUBLE', 'al.response_time',                 1],
    [ 'HTTP_STATUS',     'INT',    'al.http_status',                   1],
    [ 'HTTP_METHOD',     'STR',    'al.http_method',                   1],
  ],
    { WHERE => 1 }
  );

  $self->query("
    SELECT
      $self->{SEARCH_FIELDS}
      al.id
    FROM api_log al
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    { %$attr,
      COLS_NAME  => 1,
      COLS_UPPER => 1
    }
  );
  my $list = $self->{list};

  return [] if ($self->{errno} || $self->{TOTAL} < 1);

  $self->query("SELECT COUNT(al.id) AS total
   FROM api_log al
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

1;
