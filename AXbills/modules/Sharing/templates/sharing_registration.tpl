%MESSAGE%
<FORM action='$SELF_URL' METHOD=POST>
<input type=hidden name=module value='Sharing'>
<table>
    <tr>
        <th colspan=2 align=right>_{REGISTRATION}_</th>
    </tr>
    <tr>
        <td>_{LOGIN}_:</td>
        <td><input type=text name='LOGIN' value='%LOGIN%'></td>
    </tr>
    <tr>
        <td>_{FIO}_:</td>
        <td><input type=text name='FIO' value='%FIO%'></td>
    </tr>
<tr><td>E-MAIL:</td><td><input type=text name='EMAIL' value='%EMAIL%'></td></tr>
    <tr>
        <td>_{TARIF_PLAN}_:</td>
        <td>%TP_SEL%</td>
    </tr>
%PAYMENTS%
</table>
    <input type=submit name=reg value='_{REGISTRATION}_'>
</FORM>
