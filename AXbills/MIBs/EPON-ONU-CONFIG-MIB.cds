                                                                                       "onu info table"                       
"onu info"                       "olt slot index"                       "pon index"                       "onu index"                       "onu reg status"                       "onu description"                       
"onu llid"                       "onu Vendor ID"                       "onu Model"                       	"onu mac"                       "onu software version"                       "onu hardware version"                       "onu chip Vendor"                       "onu chip Model"                       "onu chip Revision"                       "onu chip IC_Version/Date"                       "onu reset"                       "onu reset"                       "onu distance"                       "onu reg time"                       "onu ip config table"                       "onu ip config"                       "olt slot index"                       "pon index"                       "onu index"                       	"onu IP "                       "onu ipmask"                       "onu  gateway"                       "onu cvlan"                       "onu svlan"                       "onu priority"                       "onu opm diagnosis"                       "onu opm diagnosis "                       "olt slot index"                       "pon index"                       "onu index"                       "temperature , centi C"                       "voltage , centi V"                       "basi , centi mA"                       "tx power , centi mw"                       "rx power , centi mw"                       "onu opm threshold"                       "onu opm threshold"                       "olt slot index"                       "pon index"                       "onu index"                       "onu capability info"                       "onu capability info"                       "olt slot index"                       "pon index"                       "onu index"                       �"onu Servicesupported
    bit01:support GE port; bit00:not support
    bit11:support FE port; bit10:not support
    bit21:support VoIP; bit20:not support
    bit31:support TDM CES; bit30:not support
    "                       "Number of GE Ports"                       "Bitmap of GE Ports "                       "Number of FE Ports"                       "Bitmap of FE Ports"                       "Number of POTS ports"                       "Number of E1 port"                       "Number of upstream queues"                       +"Maximum queues per Ethernet port upstream"                       "Number of downstream queues"                       -"Maximum queues per Ethernet port downstream"                       8"0x00:no backup battery
     0x01:have backup battery "                       "onu capability2"               "onu capability2 info"                       "onu capability2 info"                       "olt slot index"                       "pon index"                       "onu index"                      �" onu type
    0:SFU
      1:HGU
      2: SBU
	  3: box MDU (broadband for the Ethernet interface)
      4: small card type MDU (broadband for the Ethernet interface)
      5: small card type MDU (broadband for the DSL interface)
      6: medium card type MDU (broadband for the DSL interface)
      7: mixed interface card MDU (support for Ethernet and DSL two broadband interface board mixed)
      8:MTU "                       �"
    0x00TInvalid value
    0x01TOnly single LLID is supported
      Other values indicate the number of LLIDs supported by the ONU "                       �"
    0x00 means not supported
????0x01 Indicates optical link protection that supports type c
????0x02 indicates optical link protection that supports type d
????Other to be determined "                       �"
	0x01 indicates that the number of PON ports is one
    0x02 indicates that the number of PON ports is 2
    Other to be determined "                       "
    number of slot "                       "
    number of interface"                       M" battery backup
    0x00Tno backup battery
    0x01Thave backup battery"                        "eponOnuCap2InterfaceType table"                        "eponOnuCap2InterfaceType table"                       "olt slot index"                       "pon index"                       "onu index"                       "interfaceType index"                      �" interface type
	0x00000000 Indicates the Gigabit Ethernet GE interface
    0x00000001 indicates the Fast Ethernet FE interface (maximum rate is 100M, without GE port)
    0x00000002 Indicates the VoIP interface
    0x00000003 Indicates that the TDM interface is supported
    0x00000004 that support ADSL2 + interface
    0x00000005 Indicates the VDSL2 interface
    0x00000006 Indicates WLAN
    0x00000007 indicates USB port
    0x00000008 Indicates the CATV RF port
    Other to be determined "                       "number of interface"                       "onu bind table"                       "onu sla table"                       "olt slot index"                       "pon index"                       "onu index"                       
"bind mac"                       "bind type"                       "rowStatus"                       "onu sla table"                       "onu sla table"                       "olt slot index"                       "pon index"                       "onu index"                       "Upstream sla FixedBW"                       "Upstream sla CommittedBW "                       "Upstream sla PeakBW"                       "Downstream sla FixedBW"                       "Downstream sla CommittedBW"                       "Downstream sla PeakBW"                       "onu classification table"                       "classification entry"                       "olt slot index"                       "pon index"                       "onu index"                       "uni index"                       "Number of rule precedence"                      