#!/usr/bin/perl

use strict;
use warnings;
use File::Copy;

# Проверяем аргумент командной строки
my $arg = shift;

if ($arg eq 'mfi') {
    # Копируем файлы из /usr/axbills/misc/sorm/mfi/Sorm
    copy('/usr/axbills/misc/sorm/mfi/Sorm/Fenix.pm', '/usr/axbills/AXbills/mysql/Sorm/Fenix.pm') or die "Copy failed: $!";
    copy('/usr/axbills/misc/sorm/mfi/Sorm/Sorm.pm', '/usr/axbills/AXbills/mysql/Sorm/Sorm.pm') or die "Copy failed: $!";
} elsif ($arg eq 'norsi') {
    # Копируем файлы из /usr/axbills/misc/sorm/norsi/Sorm
    copy('/usr/axbills/misc/sorm/norsi/Sorm/Fenix.pm', '/usr/axbills/AXbills/mysql/Sorm/Fenix.pm') or die "Copy failed: $!";
    copy('/usr/axbills/misc/sorm/norsi/Sorm/Sorm.pm', '/usr/axbills/AXbills/mysql/Sorm/Sorm.pm') or die "Copy failed: $!";
} else {
    die "Ошибка, читайте инструкцию!!!\n";
}

# Читаем параметры доступа к базе данных и SORM_ARCHIVE_PATH из файла /usr/axbills/libexec/config.pl
my %conf;
open(my $config_fh, '<', '/usr/axbills/libexec/config.pl') or die "Unable to open config file: $!";
while (my $line = <$config_fh>) {
    if ($line =~ /^\$conf\{dbname\}\s+=\s+'([^']+)'/) {
        $conf{dbname} = $1;
    } elsif ($line =~ /^\$conf\{dbpasswd\}\s+=\s+'([^']+)'/) {
        $conf{dbpasswd} = $1;
    } elsif ($line =~ /^\$conf\{SORM_ARCHIVE_PATH\}\s+=\s+'([^']+)'/) {
        $conf{SORM_ARCHIVE_PATH} = $1;
    }
}
close($config_fh);

# Создаем папку из параметра SORM_ARCHIVE_PATH
mkdir $conf{SORM_ARCHIVE_PATH} unless -d $conf{SORM_ARCHIVE_PATH};

# Выполняем SQL-код
system("mysql -D $conf{dbname} -p$conf{dbpasswd} </usr/axbills/db/Sorm.sql");

# Ждем 10 секунд
sleep(10);

# Выполняем код /usr/axbills/libexec/billd sorm TYPE=Fenix START=1
system("/usr/axbills/libexec/billd sorm TYPE=Fenix START=1");

# Ждем выполнения последней команды
print "Установка завершена, нажмите любую клавишу для выхода!\n";

# Ждем нажатия любой клавиши для завершения программы
<STDIN>;
