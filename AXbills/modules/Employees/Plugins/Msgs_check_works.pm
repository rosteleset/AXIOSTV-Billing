package Employees::Plugins::Msgs_check_works;

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw/in_array/;

my ($admin, $CONF, $db);
my $json;
my AXbills::HTML $html;
my $lang;
my $Msgs;

my $Employees;

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

  my $self = { MODULE => 'Employees', PLUGIN_NAME => 'Msgs_check_works' };

  $Msgs = $attr->{MSGS} if $attr->{MSGS};

  require Employees;
  Employees->import();
  $Employees = Employees->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME         => "Checking works before closing",
    DESCR        => $lang->{CHECKING_WORKS_BEFORE_CLOSING} ,
    BEFORE_REPLY => [ 'employee_check_ticket_works' ]
  };
}

#**********************************************************
=head2 employee_check_ticket_works($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub employee_check_ticket_works {
  my $self = shift;
  my ($attr) = @_;

  return if !$Msgs || !$Employees;
  
  my $statuses = $Msgs->status_list({ TASK_CLOSED => 1, COLS_NAME => 1 });
  my $closed_statuses = ();
  map push(@{$closed_statuses}, $_->{id}), @{$statuses};

  return if !defined($attr->{STATE}) || !in_array($attr->{STATE}, $closed_statuses);

  my $work_list = $Employees->employees_works_list({
    COLS_NAME   => 1,
    SUM         => '_SHOW',
    EXTRA_SUM   => '_SHOW',
    EXT_ID      => $attr->{ID},
    WORK_AID    => '_SHOW',
    WORK        => '_SHOW',
    WORK_DONE   => '0',
  });
  
  return if !$Employees->{TOTAL} || $Employees->{TOTAL} < 1;

  $html->message('err', $lang->{ERROR}, 'У вас остались не законченые работы!');
  
  return {
    RETURN_VALUE => 1,
    CALLBACK     => {
      FUNCTION => 'msgs_ticket_show',
      PARAMS   => {
        UID => $attr->{UID},
        ID  => $attr->{ID}
      }
    }
  };
}

1;
