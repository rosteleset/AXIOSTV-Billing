package AXbills::Backend::Plugin::Telegram::Extension;
use strict;
use warnings FATAL => 'all';

our (%conf, $base_dir);
$base_dir //= '/usr/axbills';

=head2 NAME

  AXbills::Backend::Plugin::Telegram::Extension
  
=head2 SYNOPSIS

  Base extension for ABillS Telegram bot.
  You can inherit from it and define new actions.
  See AXbills::Backend::Plugin::Telegram::Extension::Example for instructions
  
=cut

#**********************************************************
=head2 add_extensions()

=cut
#**********************************************************
sub add_extensions {
  my ($Telegram_Bot) = @_;
  
  $Telegram_Bot->add_callback('/help', sub {
      my ($message, $chat_id, $client_type, $client_id) = @_;
      $Telegram_Bot->send_text("No help for you now, $client_type #$client_id", $chat_id);
    });
  
  return 1;
}

#**********************************************************
=head2 build_log_for($extension_name)

=cut
#**********************************************************
#@returns AXbills::Backend::Log
sub build_log_for {
  my ($extension_name, $file_path) = shift;
  
  my $extension_debug_key = "TELEGRAM_EXTENSION_" . uc ($extension_name) . "_DEBUG";
  $file_path //= $base_dir . '/var/log/telegram_' . lc($extension_name) . '.log';
  
  # Define debug level.
  #  If TELEGRAM_EXTENSIONS_DEBUG is defined, use it.
  #  Otherwise check for this extension debug level specified
  my $debug_level = $conf{TELEGRAM_EXTENSIONS_DEBUG}
    ? $conf{TELEGRAM_EXTENSIONS_DEBUG}
    : ($conf{$extension_debug_key})
      ? $conf{$extension_debug_key}
      : 0;
  
  my $Log = AXbills::Backend::Log->new('FILE', $debug_level, $extension_name, {
      FILE => $file_path,
    });
  
  return $Log;
}

1;