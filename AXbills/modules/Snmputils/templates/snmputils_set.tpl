<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
<input type='hidden' name='change' value='1'>
<table class=form>
<tr><td>SNMP Host:</td><td><input type='text' name='SNMP_HOST' value='%SNMP_HOST%'></td></tr>
<tr><td>SNMP Community:</td><td><input type='text' name='SNMP_COMMUNITY' value='%SNMP_COMMUNITY%'></td></tr>

<tr><td>OID, MIB:</td><td><input type='text' name='SNMP_OID' value='%SNMP_OID%'></td></tr>
<tr><td>Index:</td><td><input type='text' name='SNMP_INDEX' value='%SNMP_INDEX%'></td></tr>
<tr><td>VALUE:</td><td><input type='text' name='SNMP_VALUE' value='%SNMP_VALUE%'></td></tr>

    <tr>
        <td>_{TYPE}_:</td>
        <td>%SNMP_TYPE_SEL%</td>
    </tr>
    <tr>
        <th class=even colspan=2><input type='submit' name='change' value='_{GET}_'> <input type='submit' name='set'
                                                                                            value='_{SET}_'></th>
    </tr>
</table>

</FORM>
