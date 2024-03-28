
%MESSAGE%

<form method='POST' action='$SELF_URL'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='INTERACT' value='1'>

<input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>
<table width=300 class=form>
    <tr>
        <th colspan='2' class=form_title>_{BALANCE_RECHARCHE}_</th>
    </tr>
    <tr>
        <td>_{TRANSACTION}_ #:</td>
        <td>%OPERATION_ID%</td>
    </tr>
<tr><td>UID</td><td><input type='text' name='UID' value='$FORM{UID}'></td></tr>
    <tr>
        <td>_{SUM}_:</td>
        <td><input type='number' min='0' step='0.01' name='SUM' value='$FORM{SUM}'></td>
    </tr>
    <tr>
        <td>_{DESCRIBE}_:</td>
        <td><input type='text' name='DESCRIBE' value='Пополнение счёта'></td>
    </tr>
    <tr>
        <td>_{PAY_SYSTEM}_:</td>
        <td>%PAY_SYSTEM_SEL%</td>
    </tr>
    <tr>
        <th colspan='2' class=even><input type='submit' name=pre value='_{NEXT}_'></th>
    </tr>
</table>

</form>
