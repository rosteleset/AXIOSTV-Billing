enable
conf
interface EPON %BRANCH%:%ONU_ID%
 switchport port-security dynamic maximum 6
 switchport port-security mode dynamic
 epon fec enable
  epon onu port 1 ctc vlan mode tag %INTERNET_PLUS_VLAN% priority 0
  epon onu port 1 ctc loopback detect
  epon onu port 1 storm-control mode 1 threshold 256
 epon sla upstream pir 1000000 cir 15000
 epon sla downstream pir 1000000 cir 15000
ex
wr all
