# Epon registration example
# show onu unauthentication

configure terminal
interface epon-olt_%BRANCH%
  onu %ONU_ID% type EPON_ONE mac %MAC%
exit

##############################
interface epon-onu_%BRANCH%:%ONU_ID%
  admin enable
  property description onu_%ONU_ID%_%ONU_COMMENTS%
  ems-autocfg-request disable
  sla-profile 100MB vport 1
  encrypt direction downstream  enable  vport 1
  switchport mode hybrid vport 1
  switchport vlan %VLAN%  tag vport 1
exit

##############################################
pon-onu-mng epon-onu_%BRANCH%:%ONU_ID%
auto-config
vlan port eth_0/1 mode tag vlan %VLAN% priority 0

exit;
write

