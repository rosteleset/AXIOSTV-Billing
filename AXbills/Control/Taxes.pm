=head1 NAME

  Taxes

=cut

use strict;
use warnings FATAL => 'all';
use Taxes;

our (
 $db,
 $admin,
 $html,
 %lang,
 %conf,
);

my $Taxes = Taxes->new($db, $admin, \%conf);

#**********************************************************
=head2 taxes()

=cut
#**********************************************************
sub taxes {

  my $btn_action  = 'add';
  my $btn_value   = $lang{ADD};
  my @current     = ($lang{NO}, $lang{YES});
  my %TAXES_VALUE = ();

  if($FORM{add}) {
    $Taxes->add_tax(
      {
        RATECODE   => $FORM{RATECODE},
        RATEDESCR  => $FORM{RATEDESCR},
        RATEAMOUNT => $FORM{RATEAMOUNT},
        CURRENT    => $FORM{CURRENT},
      }
    );

    if(! _error_show($Taxes)) {
      $html->message("info", $lang{ADD_MASSAGE}, $lang{OPERATION});
    }
  }
  elsif($FORM{del} && $FORM{COMMENTS}) {
    $Taxes->del_tax(
      {
        ID => $FORM{del},
      }
    );

    if(! _error_show($Taxes)) {
      $html->message("info", $lang{DELETE_MASSAGE}, $lang{OPERATION});
    }  
  }
  elsif($FORM{change}){
    $Taxes->change_tax(
      {
        ID         => $FORM{ID},
        RATECODE   => $FORM{RATECODE},
        RATEDESCR  => $FORM{RATEDESCR},
        RATEAMOUNT => $FORM{RATEAMOUNT},
        CURRENT    => $FORM{CURRENT},
      }
    );

    if(! _error_show($Taxes)) {
      $html->message("info", $lang{CHANGE_MASSAGE}, $lang{OPERATION});
    }  
  }
  elsif($FORM{chg}){
    $btn_action = 'change';
    $btn_value  = $lang{CHANGE};

    my $taxes_value = $Taxes->taxes_list({ COLS_NAME => 1, DESC => "desc", ID => $FORM{chg}});

    if($Taxes->{errno}){
      $html->message("err", $lang{ERROR}, $lang{NOTABLES});
      return 1;
    }
    foreach my $item (@$taxes_value) {
      $TAXES_VALUE{ID}         = $item->{id};
      $TAXES_VALUE{RATECODE}   = $item->{ratecode};
      $TAXES_VALUE{RATEDESCR}  = $item->{ratedescr};
      $TAXES_VALUE{RATEAMOUNT} = $item->{rateamount};
      $TAXES_VALUE{CURRENT}    = $item->{current};
    }
  }

  my $taxes_list = $Taxes->taxes_list({ COLS_NAME => 1, DESC => "desc" });

  if($Taxes->{errno}){
    $html->message("err", $lang{ERROR}, $lang{NOTABLES});
    return 1;
  }

  $html->tpl_show(templates('tax_add_form'),
    {
      BTN       => $btn_value,
      ACTION    => $btn_action,
      %TAXES_VALUE,
    }
  );

  my $table = $html->table(
    {
      width   => "100%",
      caption => "$lang{TAX_MAGAZINE}",
      title   => [ "ID", $lang{CODE} . ' ' . $lang{_TAX}, $lang{PERCENT} . ' ' . $lang{_TAX} . ', (%)', $lang{DESCRIBE}, $lang{IN_USING}, "" ],
      qs      => $pages_qs,
      ID      => "TABLE_ID",
      export  => 1
    }
  );

  foreach my $item (@$taxes_list) {
    my $del_button  = $html->button("", "index=$index&del=$item->{id}", { class => "del", MESSAGE => "$lang{DEL}?", class => 'del'  });
    my $edit_button = $html->button("", "index=$index&chg=$item->{id}", { class => "",            ADD_ICON => "fa fa-pencil-alt" });
    $table->addrow($item->{id}, $item->{ratecode}, $item->{rateamount}, $item->{ratedescr}, $current[$item->{current}],  "$edit_button$del_button");
  }

  print $table->show();

  return 1;
}

1;