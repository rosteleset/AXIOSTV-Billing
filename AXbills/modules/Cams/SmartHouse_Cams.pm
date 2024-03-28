package Cams::SmartHouse_Cams;

=head1 NAME

=head1 VERSION

  VERSION: 0.02
  Revision: 20191204

=head1 SYNOPSIS

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.02;

use parent qw(dbcore);
use AXbills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use AXbills::Fetcher;
use Digest::SHA qw(hmac_sha256_hex);
my $MODULE = 'SmartHouse_Cams';

my ($admin, $CONF);
my AXbills::HTML $html;
my $lang;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  my ($host, $dbname) = split(";", $attr->{URL});
  $db = AXbills::SQL->connect('mysql', $host, $dbname, $attr->{LOGIN}, $attr->{PASSWORD});

  $admin->{MODULE} = $MODULE;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{LANG}) {
    $lang = $attr->{LANG};
  }

  my $self = {};
  bless($self, $class);

  load_pmodule('JSON');

  $self->{SERVICE_NAME} = $MODULE;
  $self->{VERSION} = $VERSION;
  $self->{db} = $db;

  $self->{LOGIN} = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{URL} = $attr->{URL} || '';
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;

  $self->{VERSION} = $VERSION;

  if ($self->{debug}) {
    print "Content-Type: text/html\n\n";
  }

  return $self;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;

  $self->query("SELECT id FROM operators WHERE id=1;", undef, { COLS_NAME => 1, COLS_UPPER => 1 });

  return [ ] if ($self->{errno});

  return 1;
}

#**********************************************************
=head2 user_add($attr)

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{LOGIN} = $attr->{USER} ? $attr->{USER}{LOGIN} ? $attr->{USER}{LOGIN} : $attr->{LOGIN} : $attr->{LOGIN};
  $self->query("SELECT id FROM operators WHERE name='$attr->{LOGIN}';", undef, { COLS_NAME => 1, COLS_UPPER => 1 });

  if ($self->{TOTAL}) {
    $self->query("UPDATE operators SET is_active=1 WHERE domain_id=(SELECT id FROM domains WHERE name='$attr->{LOGIN}');",
      'do', {
        Bind => []
      }
    );

    return $self;
  }

  $self->query("INSERT INTO domains (name, org_id, lang) VALUES (?, ?, ?);",
    'do', {
      Bind => [
        $attr->{LOGIN},
        1,
        136
      ]
    }
  );

  $self->query("INSERT INTO operators (name, login, password, org_id, domain_id, roles, contacts, is_active) VALUES (?, ?, MD5('$attr->{PASSWORD}'), ?, ?, ?, ?, ?);",
    'do', {
      Bind => [
        $attr->{LOGIN},
        $attr->{LOGIN},
        1,
        $self->{INSERT_ID},
        63488 + 65536,
        $attr->{PHONE},
        1
      ]
    }
  );

  return 1;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query("DELETE FROM operators WHERE domain_id=(SELECT id FROM domains WHERE name='$attr->{LOGIN}');",
    'do', {
      Bind => []
    }
  );

  $self->query("DELETE FROM domains WHERE name='$attr->{LOGIN}';",
    'do', {
      Bind => []
    }
  );

  return 1;
}

#**********************************************************
=head2 user_change($attr)

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{NEW_PASSWORD}) {
    $self->query("UPDATE operators SET password=MD5($attr->{NEW_PASSWORD}) WHERE name='$attr->{LOGIN}';",
      'do', {
        Bind => []
      }
    );

    return $self;
  }

  if ($attr->{STATUS}) {
    $self->query("UPDATE operators SET is_active=0 WHERE domain_id=(SELECT id FROM domains WHERE name='$attr->{LOGIN}');",
      'do', {
        Bind => []
      }
    );
  }
  else {
    $self->query("UPDATE operators SET is_active=1 WHERE domain_id=(SELECT id FROM domains WHERE name='$attr->{LOGIN}');",
      'do', {
        Bind => []
      }
    );
  }

  $self->query("UPDATE operators SET password=MD5($attr->{PASSWORD}) WHERE name='$attr->{LOGIN}';",
    'do', {
      Bind => []
    }
  );

  return $self;
}

#**********************************************************
=head2 user_negdeposit($attr)

=cut
#**********************************************************
sub user_negdeposit {
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE operators SET is_active=0 WHERE domain_id=(SELECT id FROM domains WHERE name='$attr->{LOGIN}');",
    'do', {
      Bind => []
    }
  );

  return $self;
}

1;