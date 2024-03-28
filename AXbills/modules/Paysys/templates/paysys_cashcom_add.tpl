
<form action='https://pay.cashcom.ru/topup.xhtml' method='POST' accept-charset='utf-8'>
<input type='hidden' name='provider' value='$conf{PAYSYS_CASHCOM_PROVIDER_ID}' />
<input type='hidden' name='num' value='$LIST_PARAMS{UID}' />
<input type='hidden' name='amount' value='$FORM{SUM}' />


<table width=400 class=form>
<tr><th class='form_title' colspan=2>CashCom</th></tr>
<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
    <tr>
        <td>_{BALANCE_RECHARCHE_SUM}_:</td>
        <td>$FORM{SUM}</td>
    </tr>

    <tr>
        <th colspan=2 class=even><input type=submit name=add value='_{PAY}_'>
</table>
</form>



