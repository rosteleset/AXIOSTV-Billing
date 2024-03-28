#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Encode;
use Net::Ping;
use WWW::Telegram::BotAPI;
use Socket;
use Storable qw(store_fd fd_retrieve);

our %conf;
require '/usr/axbills/libexec/config.pl';

my $statuses_file = '/tmp/nas_statuses.dat';

my %old_statuses;
if (-e $statuses_file) {
    open my $fh, '<', $statuses_file or die "Не удалось открыть файл состояний: $!";
    %old_statuses = %{ fd_retrieve($fh) };
    close $fh;
}

my $dbh = DBI->connect("dbi:mysql:$conf{dbname}", $conf{dbuser}, $conf{dbpasswd})
    or die "Не удалось подключиться к базе данных: $DBI::errstr";

my $query = "SELECT id, ip, name FROM nas";
my $sth = $dbh->prepare($query);
$sth->execute();

$query = "SELECT value FROM admins_contacts WHERE type_id = 6 LIMIT 1";
my $sth_chat_id = $dbh->prepare($query);
$sth_chat_id->execute();
my ($telegram_chat_id) = $sth_chat_id->fetchrow_array();

my $telegram_token = $conf{TELEGRAM_TOKEN};
my $api = WWW::Telegram::BotAPI->new(token => $telegram_token);

my %new_statuses;
my $changes = '';

while (my ($id, $ip_address, $name) = $sth->fetchrow_array()) {
    my $readable_ip = inet_ntoa(pack("N", $ip_address));
    my $ping = Net::Ping->new('icmp', 2, 56);

 #   $ping->bytes(64); # Установка размера пакета при проверке доступности оборудования

    if ($ping->ping($readable_ip)) {
        print "Оборудование с IP $readable_ip ($name) доступно\n";
        $new_statuses{$readable_ip} = 1;
    } else {
        print "Оборудование с IP $readable_ip ($name) недоступно. Занесение в список недоступных устройств...\n";
        $new_statuses{$readable_ip} = 0;
    }

    if ($old_statuses{$readable_ip} != $new_statuses{$readable_ip}) {
        my $message = $new_statuses{$readable_ip}
            ? "Оборудование с IP $readable_ip ($name) стало доступно"
            : "Оборудование с IP $readable_ip ($name) стало недоступно";
        $message = decode_utf8($message);
        $changes .= $message . "\n";
    }
}

if ($changes) {
    $api->api_request('sendMessage', {
        chat_id => $telegram_chat_id,
        text    => $changes,
    });
}

open my $fh, '>', $statuses_file or die "Не удалось открыть файл состояний на запись: $!";
store_fd(\%new_statuses, $fh);
close $fh;

$sth->finish();
$sth_chat_id->finish();
$dbh->disconnect();
