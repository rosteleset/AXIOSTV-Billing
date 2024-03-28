#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use URI::Escape;
use POSIX qw(strftime);

my ($number, $text);

# Обработка аргументов командной строки
GetOptions("number=s" => \$number, "text=s" => \$text);

if (!isValidPhoneNumber($number) || !$text) {
    die("Использование: sms_sender.pm --number=902xxxxx --text=\"Текст сообщения\"\n");
}

# Преобразование URL-кодированных символов обратно в текст
$text = uri_unescape($text);

# Добавление символа "+" к номеру, если он начинается с "79"
if ($number =~ /^79\d{9}$/) {
    $number = "+$number";
}

# Формирование команды для выполнения
my $command = "gammu-smsd-inject TEXT $number -textutf8 \"$text\"";

# Выполнение команды и получение результата
my $response = qx($command);

# Формирование строки для записи в лог
my $log_entry = strftime("%Y-%m-%d %H:%M:%S", localtime) . " - Phone Number: $number\nText message:\n$text\nResponse: $response\n\n";

# Запись результата в файл
my $log_file = '/usr/axbills/var/log/sms_result.log';
open(my $log_fh, '>>', $log_file) or die "Не удалось открыть файл '$log_file' для записи: $!";
print $log_fh $log_entry;
close($log_fh);

# Вывод результата
print "Сообщение отправлено и записано в лог-файл: $log_file\n";

sub isValidPhoneNumber {
    my ($phone) = @_;
    if ($phone =~ /^\+?79\d{9}$/ || $phone =~ /^79\d{9}$/) {
        return 1;
    }
    return 0;
}
