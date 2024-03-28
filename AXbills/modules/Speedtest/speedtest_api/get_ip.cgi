#!/usr/bin/perl
use strict;
use warnings;

print "Content-Type: text/html\n\n";
print $ENV{REMOTE_ADDR}; #Отримання IP
1;
