package Callcenter::Ivr;
=head NAME

  IVR Base functions

=cut


use strict;
use warnings FATAL => 'all';
use parent 'Callcenter';
use Encode;

use Log;
my $Log;
our (
  %lang,
  $var_dir
);

$var_dir = '/usr/axbills/var/' if (!$var_dir);

eval { require Callcenter::Googletts; };
print $@;

my $debug = 0;
my @action_history = ();
my $log_file = $var_dir . '/log/ivr.log';

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  my ($admin, $CONF, $attr) = @_;

  my $MODULE = 'Callcenter';
  $admin->{MODULE} = $MODULE;
  my $self = {
    db          => $db,
    admin       => $admin,
    conf        => $CONF,
    module_name => $MODULE,
    LANG        => $attr->{LANG} || {},
    language    => $attr->{language},
    LANG_SHORT  => $attr->{LANG_SHORT},
    AGI         => $attr->{AGI},
    Callcenter  => $attr->{CALLCENTER},
    BREAK_KEYS  => $attr->{BREAK_KEYS} || "1234567890"
  };

  %lang = %{ $self->{LANG} } ;

  if ($self->{language}) {
    require 'language/'.$self->{language}.'.pl';
    require "Callcenter/lng_$self->{language}.pl";
    $self->{LANG} = \%lang;
  }

  if ($CONF->{CALLCENTER_IVR_DEBUG}) {
    $debug = $CONF->{CALLCENTER_IVR_DEBUG};
  }

  $debug += 5;

  $Log = Log->new($db, $CONF);
  bless($self, $class);

  return $self;
}


#**********************************************************
=head2 get_menu($attr) - Get menu
  Arguments:
    $attr
      CHAPTER

=cut
#**********************************************************
sub get_menu {
  my $self = shift;
  my ($attr)=@_;

  my %menu = ();
  my %LIST_PARAMS = ();
  $LIST_PARAMS{CHAPTER_ID}='0';
  $LIST_PARAMS{CHAPTER_NUMBER}=q{};
  if ($attr->{CHAPTER} && ref $attr->{CHAPTER} ne 'HASH' && $attr->{CHAPTER} =~ /^\@/) {
    delete $LIST_PARAMS{CHAPTER_ID};
    $LIST_PARAMS{CHAPTER_NUMBER}=$attr->{CHAPTER};
    $self->log('LOG_WARNING', "CHAPTER_NUMBER: $LIST_PARAMS{CHAPTER_NUMBER} ",
      { AGI_VERBOSE => 1 });

    `echo "CHAPTER2: $attr->{CHAPTER}" >> /tmp/ivr_log`;
  }

  `echo "CHAPTER: $LIST_PARAMS{CHAPTER_NUMBER}/ " >> /tmp/ivr_log`;

  #Make custom menu from db
  my $menu_list = $self->ivr_menu_list({
    DISABLE    => 0,
    MAIN_ID    => '_SHOW',
    NUMBER     => '_SHOW',
    NAME       => '_SHOW',
    FUNCTION   => '_SHOW',
    AUDIO_FILE => '_SHOW',
    PAGE_ROWS  => 50,
    %LIST_PARAMS,
    COLS_NAME  => 1
  });

  if ($self->{TOTAL}) {
    foreach my $line (@{$menu_list}) {
      my $function = ($line->{audio_file}) ? 'AUDIO=' . $line->{audio_file} : $line->{function};
      $menu{ $line->{main_id} || 0 }{ $line->{id} } = "$line->{number}:$function:$line->{name}";
    }

    #Load custom rules
    #eval { require Callcenter::Ivr_extra; };
  }
  #Make default menu
  else {
    my %menu_default = (
      0 => "main_menu:MAIN_MENU",
      1 => "show_deposit:SHOW_DEPOSIT",
      4 => "msgs_add:MSGS_ADD",
      5 => "full_info:FULL_INFO",
      9 => "exit:EXIT"
    );

    #Credit recharge
    if ($self->{conf}{user_credit_change}) {
      $menu_default{3} = "use_credit:USE_CREDIT";
    }

    #Cards recharge
    eval { require Cards;};
    if (!$@) {
      Cards->import();
      my $Cards = Cards->new($self->{db}, $self->{admin}, $self->{conf});
      $menu_default{2} = "cards_recharge:CARDS_RECHARGE";
    }

    if ($self->{conf}{CALLCENTER_IVR_MARKETING}) {
      $menu_default{6} = "marketing_info:MARKETING_INFO";
    }

    $menu{0} = \%menu_default;
  }

  return \%menu;
}


#**********************************************************
=head2 menu($menu, $user_info) - Main menu

=cut
#**********************************************************
sub menu {
  my $self = shift;
  my ($menu, $user_info_) = @_;

  my $code = -1;
  my $cure_menu = $menu;
  my $try  = 0;
  my $active_code = 0;

  while ($try < 3) {
    if ($debug > 8) {
      message('STEP');
      message($try);
    }

    #$AGI->verbose("CODE:". ($code || 'NO_CODE'));
    #ivr_log('LOG_DEBUG', "========================== TRY: $try", { AGI_VERBOSE => 1, USER_NAME => $caller_id });
    #my $code2 = $code || '';
    if ($code > 0) {
      my $message = " CODE: $code";
      `echo "//-- $message" >> /tmp/ivr_log`;
      $self->log('LOG_WARNING', $message, { AGI_VERBOSE => 1,
        USER_NAME => ($user_info_ && ref $user_info_ eq '') ? $user_info_ : $user_info_->{LOGIN}
      });

      if (!$cure_menu->{$code} && $menu->{0}->{$code}) {
        $cure_menu = $menu->{0};
      }

      push @action_history, $code;
      $self->log_change({
        COMMENT => join(',', @action_history),
        ID      => $self->{MESSAGE_ID}
      });

      `echo "//-- 2 " >> /tmp/ivr_log`;
      if ($cure_menu->{$code}) {
        $self->log('LOG_DEBUG', "Menu: '$cure_menu->{$code}' User select code: " . (($code) ? $code : ''),
          { AGI_VERBOSE => 1,
            USER_NAME => ($user_info_ && ref $user_info_ eq '') ? $user_info_ : $user_info_->{LOGIN}
          }
        );

        if (ref $cure_menu->{$code} eq 'HASH') {
          $cure_menu = $menu->{$code};
          `echo "--- read menu: " >> /tmp/ivr_log`;
          my $return_code = read_menu($cure_menu);
          $active_code = $code;
          if ($return_code > 0) {
            $code = $return_code;
            next;
          }
        }
        else {
          my ($function, $message_) = split(/:/, $cure_menu->{$code});
          `echo "--- function" >> /tmp/ivr_log`;
          if (!$function) {
            $self->log('LOG_DEBUG', "Menu: $code '$cure_menu->{$code}' function not defined",
              { AGI_VERBOSE => 1,
                USER_NAME => ($user_info_ && ref $user_info_ eq '') ? $user_info_ : $user_info_->{LOGIN}
              });
          }
          elsif ($function eq 'play_menu') {
            play_menu($message_);
          }
          elsif ($function =~ /^AUDIO=(.+):?/) {
            my $audio_file = $1;
            `echo "--- AUDIO: " >> /tmp/ivr_log`;
            $audio_file =~ s/\.wav//i;
            play_static($audio_file, $self->{lang}, { AGI => $self->{AGI} });
          }
          else {
            &{\&$function}($user_info_);

            #$active_code = 0;
            #$cure_menu   = $menu;
            $code = 0;
            #$active_code = $code;
          }
        }
        $try = 0;
      }
    }
    else {
      $active_code = 0;
      `echo "--- first menu " >> /tmp/ivr_log`;
      my $return_code = read_menu($menu->{0});
      if ($return_code > -1) {
        $self->log('LOG_WARNING', 'RETURN_CODE: '. $return_code,
          { AGI_VERBOSE => 1,
            USER_NAME => ($user_info_ && ref $user_info_ eq '') ? $user_info_ : $user_info_->{LOGIN}
          });
        $code = $return_code;
        next;
      }
    }

    #Replay
    if (!defined($menu->{ $code || 0 }{0})) {
      if (!$self->{conf}{CALLCENTER_IVR_SKIP_AUTONUM}) {
        message('0');
      }
      message('REPLAY_MENU');
      $code = 0;
    }

    # #Main menu
    # if ($active_code != 0) {
    #   message('ASTERISK');
    #   message('MAIN_MENU');
    # }
    if ($self->{AGI}) {
      _verbose($self->{AGI});
      $code = $self->{AGI}->get_data('beep', "6000", "1");
    }

    sleep 2;

    my $message = "CODE: ". ($code || 'NO_CODE') . " !!!!!!!!!!!!!!!!! end beep TRY: ". ( $try || 'NO_TRY');
    `echo "--- $message " >> /tmp/ivr_log`;
    $self->log('LOG_WARNING', $message,
      { AGI_VERBOSE => 1,
        USER_NAME => ($user_info_ && ref $user_info_ eq '') ? $user_info_ : $user_info_->{LOGIN}
      });

    `echo "--- next 1" >> /tmp/ivr_log`;
    if ($code && $code =~ /\*/) {
      $cure_menu = $menu;
      $try = 0;
      $code = -1;
    }
    elsif (defined($code) && $code == 0) {
      $cure_menu = $menu;
      $code = $active_code;
      $try = 0;
    }
    $try++;
    `echo "--- next $try / " >> /tmp/ivr_log`;
  }

  return 0;
}

#**********************************************************
=head2 message($text, $attr) - Voicing message

  Arguments:
    $text - Text for plaing
    $attr - Extra attributes
      BREAK_KEYS  - break keys
      utf_text    - UTF8 text
      lang_short  - Short lang (ru,ua,en)

  Returns:
    $result

=cut
#**********************************************************
sub message {
  my $self = shift;
  my ($text, $attr) = @_;


  # if ($attr->{AGI}) {
  #   $self->{AGI} = $attr->{AGI};
  #   $self->{AGI}->verbose("MESSAGE_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
  # }

  # $self->{AGI}->verbose(">> TEXT: $text");
  # $self->{AGI}->verbose(">> TEXT: $text");
  # $self->{AGI}->verbose(">> TEXT: $text");
  $self->{AGI}->verbose(">> TEXT: $text");

  my $EXTENSION = $self->{AGI}->get_variable('EXTENSION') || q{};
  my $EXTEN = $self->{AGI}->get_variable('EXTEN') || q{};

  $self->{AGI}->verbose("!!! $text !!! EXTENSION: $EXTENSION EXTEN: $EXTEN");

  #$self->_verbose($text, { AGI => $self->{AGI} });
  return 0;
  my $BASE_EXT = $self->{AGI}->get_variable('EXTEN') || q{};
  my $break_keys = $attr->{BREAK_KEYS} || $self->{BREAK_KEYS};
  my $lang_short = $self->{LANG_SHORT} || 'ru';
  my $caller_id = $self->{CALLER_ID} || q{};

  $self->_verbose();

  #$attr->{AGI} = $self->{AGI};


  #$self->{AGI}->verbose("TEXT: $text");

  my $self_sound = 0;
  $text .= $attr->{utf_text} if ($attr->{utf_text});

  my $googletts = ($self->{conf}{CALLCENTER_GOOGLETTS}) ? $self->{conf}{CALLCENTER_GOOGLETTS} : '/usr/axbills/AXbills/modules/Callcenter/googletts.agi';

  if ($attr->{lang_short}) {
    $lang_short = $attr->{lang_short};
  }

  my $file = $text || q{};
  if (defined($text)) {
    if ($self_sound) {
      #my $file_name =
      voice_file($text, $lang_short);
    }
    else {
      if ($text =~ /^[\$\_]{0,2}([A-Z\_0-9]+)$/) {
        $text = $1;
        $self->log('LOG_DEBUG', "Base text: $text");
        my $result = Callcenter::Googletts::play_static($text, $lang_short, $attr);
        #$AGI->verbose('PLAY STATIC: '. $result);
        if ($result < 0) {
          if ($text && $text !~ /^\d+$/) {
            if ($self->{LANG}{$text}) {
              $text = $self->{LANG}{$text};
            }
            # else {
            #   $text = '$_' . $text;
            #   $text = _translate($text);
            # }
            # if (!defined($text)) {
            #   $text = '';
            # }
          }
        }
        else {
          return $result;
        }

        Encode::_utf8_off($text);
      }

      my $return = $self->{AGI}->exec('AGI', "$googletts,$text,$lang_short,$break_keys,,$lang_short/$file");
      $self->{AGI}->verbose("STOP- $text / $lang_short/$file ------------------");

      my $EXTENSION = $self->{AGI}->get_variable('EXTENSION') || q{};
      my $EXTEN = $self->{AGI}->get_variable('EXTEN') || q{};
      $self->_verbose();
      #$AGI->verbose(">>>>>>> $BASE_EXT >> $EXTEN ne $EXTENSION ");
      #if ($EXTENSION && $EXTEN ne $EXTENSION) {
      if ($BASE_EXT ne $EXTEN) {
        $self->{AGI}->verbose("!!!!!!!!!!!!!!!!!!!!! CHANGE BASE_EXT: $BASE_EXT ENT: $EXTEN !!!!!!!!!!!!!!!!!");

        #$AGI->verbose("RETURN EXT: $EXTEN ne $EXTENSION ");
        #Return new extension
        $return = $EXTEN || q{-1};
        #$AGI->set_extension($EXTENSION);
        $EXTEN = $self->{AGI}->get_variable('EXTEN');
      }
      $self->{AGI}->verbose("RESULT: ". ($return || q{UNDEF}) ." BASE_EXT: $BASE_EXT EXTEN: ". ($EXTEN || q{}) ." EXTENSION: $EXTENSION");

      $self->log('LOG_DEBUG', "$googletts,$text,$lang_short Return:" . ((!defined($return)) ? 'No return' : $return),
        { AGI_VERBOSE => 2, USER_NAME => $caller_id });

      return $return;
    }
  }

  return -1;
}

#**********************************************************
=head2 log($debug_level, $message, $attr) - IVR debug message

  Arguments:
    $debug_level  - Debug level
    $message      - Message
    $attr         - Extra attr
      AGI_VERBOSE - Agi verbose level form 1 to 4
      HISTORY

=cut
#**********************************************************
sub log {
  my $self = shift;
  my ($debug_level, $message, $attr) = @_;

  $debug_level = 'LOG_DEBUG' if (!$debug_level);

  if ($attr->{HISTORY}) {
    $self->{Callcenter}->log_change({
      COMMENT => join(',', @action_history),
      ID      => $self->{MESSAGE_ID}
    });
  }

  $Log->log_print($debug_level, $attr->{USER_NAME}, $message,
    { LOG_FILE => $log_file, LOG_LEVEL => $debug });

  if ($attr->{AGI_VERBOSE}
    && $Log::log_levels{$debug_level}
    && $Log::log_levels{$debug_level} <= $debug) {
    $self->{AGI}->verbose($message); #, $attr->{AGI_VERBOSE});
  }

  return 1;
}


sub _verbose {
  my $self = shift;
  my ($text, $attr) = @_;

  $text //= q{};

  my Asterisk::AGI $agi = $self->{AGI};

  my %params = $agi->ReadParse();
  $agi->verbose("/$text/  AGI Environment Dump:");
  foreach my $i (sort keys %params) {
    $agi->verbose("  $i = $params{$i}");
  }

  my $EXTENSION = $agi->get_variable('EXTENSION') || q{};
  my $EXTEN = $agi->get_variable('EXTEN') || q{};

  $agi->verbose("EXTENSION: $EXTENSION EXTEN: $EXTEN");

  if (! $EXTEN) {
    my $call = join(',', caller());
    $agi->verbose($call);
    exit;
  }

  return 1;
}

1;