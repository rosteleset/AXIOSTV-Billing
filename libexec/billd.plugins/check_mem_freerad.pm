#!/usr/bin/perl
=head1 NAME

 billd plugin

 DESCRIBE:  FreeRadius memory checker

 Arguments: MEM=...

=cut

use strict;
use warnings;

my $memory_threshold = 1 * 1024 * 1024 * 1024; # 1 гигабайт в байтах, по умолчанию

if (defined $ARGV[0] && $ARGV[0] =~ /^MEM=([0-9.]+)$/) {
     my $mem_arg = $1;
     # Проверяем, что задано число
     if ($mem_arg =~ /^[0-9.]+$/) {
              $memory_threshold = $mem_arg * 1024 * 1024; # Входной аргумент в гигабайтах, преобразуем в байты
   }
else {
     my $memory_threshold = 1 * 1024 * 1024 * 1024;
   }
}

# Проверяем, запущен ли процесс radiusd
my $is_running = `pgrep -x "radiusd" > /dev/null && echo 1 || echo 0`;
chomp($is_running);

if ($is_running) {
    print "Процесс radiusd уже запущен.\n";

    # Получаем использование памяти процессом radiusd
    my $memory_usage = `ps -o rss= -C radiusd`;
    chomp($memory_usage);

    if ($memory_usage > $memory_threshold) {
        # Перезапускаем процесс radiusd
        print "Использование памяти превысило пороговое значение. Перезапуск процесса radiusd...\n";
        system("systemctl restart radiusd");
    } else {
        print "Использование памяти процесса radiusd не превышает пороговое значение $memory_threshold.\n";
    }
} else {
    print "Процесс radiusd не запущен. Запуск процесса...\n";

    # Запускаем процесс radiusd
    system("systemctl start radiusd");

    # Получаем использование памяти процессом radiusd
    my $memory_usage = `ps -o rss= -C radiusd`;
    chomp($memory_usage);

    if ($memory_usage > $memory_threshold) {
        # Перезапускаем процесс, если использование памяти превышает порог
        print "Использование памяти превысило пороговое значение. Перезапуск процесса radiusd...\n";
        system("systemctl restart radiusd");
    } else {
        print "Использование памяти процесса radiusd не превышает пороговое значение $memory_threshold.\n";
    }
}

