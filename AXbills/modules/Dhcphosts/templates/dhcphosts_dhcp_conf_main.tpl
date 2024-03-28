# Create by ABillS DATE: %DATETIME%
#
default-lease-time 86400;
max-lease-time 172800;
ddns-update-style none;
one-lease-per-client true;
deny duplicates;

%LEASES_FILE%


#Static route
option ms-classless-static-routes code 249 = array of integer 8;
option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;
log-facility local7;


#Option 82 section
#Option 82 loging
if exists agent.circuit-id {
	log ( info, concat( "o82 Lease for ", 
	   binary-to-ascii (10, 8, ".", leased-address), 
	" interface: ",
	  binary-to-ascii (10, 8, "/", suffix ( option agent.circuit-id, 2)), 
	" VLAN: ",
	  binary-to-ascii (10, 16, "", substring( option agent.circuit-id, 2, 2)),  
	" CID: ", 
	  binary-to-ascii (16, 8, ":", substring(hardware, 1, 7))
	  ));

	log ( info, concat( "o82 Lease for ", 
	  binary-to-ascii (10, 8, ".", leased-address), 
	" switch: ", 
	  binary-to-ascii(16, 8, ":", substring( option agent.remote-id, 2, 6)),
	" AID: ",
	  binary-to-ascii(16, 8, ".", option agent.remote-id)));
}

%OPTION82_CLASS%
# reserve for old version
#shared-network NETWORK_NAME {
#List of subnets
# %_SUBNETS_%
#}

%NETWORKS%

#List of hosts
%HOSTS%
