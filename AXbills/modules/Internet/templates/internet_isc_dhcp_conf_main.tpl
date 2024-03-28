# Create by ABillS DATE: %DATE%
#
default-lease-time 86400;
max-lease-time 172800;
ddns-update-style none;
one-lease-per-client true;
deny duplicates;

lease-file-name "/var/lib/dhcp/dhcpd.leases";

#Static route
option ms-classless-static-routes code 249 = array of integer 8;


shared-network DHCP_NET {
#List of subnets
%SUBNETS%
}

#List of hosts
%HOSTS%