<form action='https://perfectmoney.com/api/step1.asp' method='POST'>
    <input type='hidden' name='PAYEE_ACCOUNT' value='$conf{PAYSYS_PERFECTMONEY_PAYEE_ACCOUNT}'>
    <input type='hidden' name='PAYEE_NAME' value='$PROGRAM'>
    <input type='hidden' name='PAYMENT_ID' value='$FORM{OPERATION_ID}'>
    <input type='hidden' name='PAYMENT_AMOUNT' value='$FORM{SUM}'>
    <input type='hidden' name='PAYMENT_UNITS' value='USD'>
    <input type='hidden' name='STATUS_URL' 
        value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi'>
    <input type='hidden' name='PAYMENT_URL' 
        value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&sid=$sid&TRUE=1&OPERATION_ID=$FORM{OPERATION_ID}&PAYMENT_SYSTEM=86'>
    <input type='hidden' name='NOPAYMENT_URL' 
        value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&sid=$sid&ERROR=1&OPERATION_ID=$FORM{OPERATION_ID}&PAYMENT_SYSTEM=86'>
   <input type='hidden' name='UID' value='$UID'>
   <input type='hidden' name='sid' value='$sid'>
   <input type='hidden' name='BAGGAGE_FIELDS' value='sid UID'>

<TABLE width='500' class=form>

<tr><th class='form_title' colspan=2>PerfectMoney</th></tr>
<tr><th colspan=2><img src='https://perfectmoney.is/img/logo3.png' border=0></th></tr>

<tr><th colspan=2>&nbsp;</th></tr>
    <tr>
        <td>_{TRANSACTION}_:</td>
        <td>$FORM{OPERATION_ID}</td>
    </tr>
    <tr>
        <td>_{SUM}_:</td>
        <td>$FORM{SUM}</td>
    </tr>
    <tr>
        <th colspan=2 class=even><input type='submit' name='PAYMENT_METHOD' value='_{PAY}_'></th>
    </tr>
</table>

</form>
