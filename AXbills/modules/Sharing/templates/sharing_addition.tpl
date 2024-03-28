<div class='d-print-none'>
<form action='$SELF_URL' method='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='$FORM{TP_ID}'>
<input type=hidden name='ID' value='$FORM{chg}'>
<input type=hidden name='tt' value='1'>
<table>
    <tr>
        <td>_{TARIF}_ ID:</td>
        <td>%SEL_TT_ID%</td>
    </tr>
    <tr>
        <td>_{NAME}_:</td>
        <td><input type=text name='NAME' value='%NAME%'></td>
    </tr>
    <tr>
        <td>_{EXTRA_TRAFIC}_:</td>
        <td><input type=text name='QUANTITY' value='%QUANTITY%'></td>
    </tr>
    <tr>
        <td>_{SUM}_:</td>
        <td><input type=text name='PRICE' value='%PRICE%'></td>
    </tr>

</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>
