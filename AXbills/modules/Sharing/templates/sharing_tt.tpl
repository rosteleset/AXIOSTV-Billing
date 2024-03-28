<div class='d-print-none'>
<form action='$SELF_URL' method='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='$FORM{TP_ID}'>
<input type=hidden name='tt' value='%TI_ID%'>
<table>
    <tr bgcolor='$_COLORS[1]'>
        <th colspan=3 align=right>_{TRAFIC_TARIFS}_</th>
    </tr>
    <tr>
        <td colspan=2>_{INTERVALS}_:</td>
        <td bgcolor=$_COLORS[0]>%TI_ID%</td>
    </tr>
    <tr>
        <td colspan=2>_{TARIF}_ ID:</td>
        <td>%SEL_TT_ID%</td>
    </tr>
    <tr>
        <td rowspan=2>_{TRAFIC_TARIFS}_ (1 Mb):</td>
        <td>IN</td>
        <td><input type=text name='TT_PRICE_IN' value='%TT_PRICE_IN%'></td>
    </tr>
<tr><td>OUT:</td><td><input type=text name='TT_PRICE_OUT' value='%TT_PRICE_OUT%'></td></tr>
    <tr>
        <td colspan=2>_{PREPAID}_ (Mb):</td>
        <td><input type=text size=12 name='TT_PREPAID' value='%TT_PREPAID%'></td>
    </tr>
    <tr>
        <td rowspan=2>_{SPEED}_ (Kbits):</td>
        <td>IN</td>
        <td><input type=text size=12 name='TT_SPEED_IN' value='%TT_SPEED_IN%'></td>
    </tr>
<tr><td>OUT</td><td><input type=text size=12 name='TT_SPEED_OUT' value='%TT_SPEED_OUT%'></td></tr>
    <tr>
        <td colspan=2>_{DESCRIBE}_:</td>
        <td><input type=text name='TT_DESCRIBE' value='%TT_DESCRIBE%'></td>
    </tr>
    <tr>
        <td colspan=2>_{EXPRESSION}_:</td>
        <td><textarea name='TT_EXPRASSION' cols=40 rows=8>%TT_EXPRASSION%</textarea></td>
    </tr>

<tr><th colspan=3>NETS (192.168.101.0/24;10.0.0.0/28) </th></tr>
<tr><th colspan=3><textarea cols=40 rows=4 name='TT_NETS'>%TT_NETS%</textarea></th></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>
