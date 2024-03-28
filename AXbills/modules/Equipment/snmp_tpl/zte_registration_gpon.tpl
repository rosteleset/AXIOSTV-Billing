#Gpon registration example
# show onu unauthentication
# config terminal

configure terminal
interface gpon-olt_%BRANCH%
onu %ONU_ID% type GPON_ONE sn %ONU_SERIAL%
onu %ONU_ID% profile  line gpon remote VLAN%VLAN%
exit

interface gpon-onu_%BRANCH%:%ONU_ID%
description %ONU_COMMENTS%
switchport mode hybrid vport 1
service-port %ONU_ID% vport 1 user-vlan %VLAN% vlan %VLAN%
exit
exit
write

