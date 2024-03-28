<FORM>
<input type='hidden' name='index' value='$index'>

<TABLE width='100%' class=form>
    <TR class='odd'>
        <td>_{LOGIN}_:</td>
        <td colspan='3'>%LOGIN%</td>
    </tr>
<tr><th colspan='4' class='form_title'>Station Information and Status</th></tr>
    <TR class='odd'>
        <td>MAC Address</td>
        <td>%MAC%</td>
        <td>_{NAME}_</td>
        <td>%cDot11ClientName%</td>
    </tr>
<TR class='odd'><td>IP Address:</td><td>%cDot11ClientIpAddress%</td><td>Class</td><td>%cDot11ClientIpAddressType%</td></tr>
<TR class='odd'><td>Device:	</td><td>%cDot11ClientDevType%</td><td>Software Version</td><td>%cDot11ClientSoftwareVersion%</td></tr>
<TR class='odd'><td>CCX Version<td></td><td></td><td> </td></tr>

<TR class='odd'><td>State:<td>%cDot11ClientAssociationState%</td><td>Parent:</td><td>%cDot11ClientParentAddress%</td></tr>
<TR class='odd'><td>SSID<td></td><td>VLAN</td><td>%cDot11ClientVlanId%</td></tr>
<TR class='odd'><td>Hops To Infrastructure<td></td><td>Communication Over Interface</td><td> </td></tr>
<TR class='odd'><td>cDot11Clients Associated<td></td><td>Repeaters Associated</td><td> </td></tr>
<TR class='odd'><td>Key Mgmt type<td></td><td>Encryption</td><td>%cDot11ClientWepEnabled%</td></tr>
<TR class='odd'><td>Current Rate (Mb/sec)	<td>%cDot11ClientCurrentTxRateSet%</td><td>Capability</td><td> </td></tr>
<TR class='odd'><td>Supported Rates(Mb/sec)</td><td colspan='3'>%cDot11ClientDataRateSet%</td></tr>

<tr class='odd'><td>Voice Rates(Mb/sec):</td><td></td><td>Association Id</td><td>%cDot11ClientAid%</td></tr>
<TR class='odd'><td>Signal Strength (dBm)<td>%cDot11ClientSignalStrength%</td><td>Connected For (sec)</td><td>%cDot11ClientUpTime%</td></tr>
<TR class='odd'><td>Signal Quality (%)<td>%cDot11ClientSigQuality%</td><td>Activity TimeOut (sec)</td><td>%cDot11ClientAgingLeft%</td></tr>
<TR class='odd'><td>Power-save<td>%cDot11ClientPowerSaveMode%</td><td>Last Activity (sec)</td><td> </td></tr>


<tr><th colspan='4' class='form_title'>Receive/Transmit Statistics</th></tr>
<TR class='odd'><td>Total Packets Input:<td>%cDot11ClientPacketsReceived%</td><td>Total Packets Output</td><td>%cDot11ClientPacketsSent%</td></tr>
<TR class='odd'><td>Total Bytes Input:<td>%cDot11ClientBytesReceived%</td><td>Total Bytes Output:</td><td>%cDot11ClientBytesSent%</td></tr>
<TR class='odd'><td>Duplicates Received<td>%cDot11ClientDuplicates%</td><td>Maximum Data Retries</td><td>%cDot11ClientMsduRetries%</td></tr>
<TR class='odd'><td>Decrypt Errors<td>%cDot11ClientWepErrors%</td><td>Maximum RTS Retries</td><td> </td></tr>
<TR class='odd'><td>MIC Failed<td>%cDot11ClientMicErrors%</td><td></td><td> </td></tr>
<TR class='odd'><td>MIC Missing<td>%cDot11ClientMicMissingFrames%</td><td></td><td> </td></tr>
</TABLE>

</FORM>
