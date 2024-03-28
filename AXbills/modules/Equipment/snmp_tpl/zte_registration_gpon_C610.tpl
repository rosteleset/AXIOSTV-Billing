#Gpon registration example
# show onu unauthentication
# config terminal

configure terminal
interface gpon_olt-%BRANCH%
onu %ONU_ID% type 1G sn %ONU_SERIAL%
exit

interface gpon_onu-%BRANCH%:%ONU_ID%
description %ONU_COMMENTS%
tcont 1 profile 1G
gemport 1 tcont 1
exit

pon-onu-mng gpon_onu-%BRANCH%:%ONU_ID%
  service INET gemport 1 vlan 101
  vlan port eth_0/1 mode tag vlan 101
exit

interface vport-%BRANCH%.%ONU_ID%:1
service-port 1 user-vlan 101 vlan %VLAN%
exit
exit
write

