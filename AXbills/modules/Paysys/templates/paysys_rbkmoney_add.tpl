<form action='https://rbkmoney.ru/acceptpurchase.aspx' name='pay' method='POST'>
<input type='hidden' name='userField_index' value='$index'> 
<input type='hidden' name='userField_UID' value='$LIST_PARAMS{UID}'> 
<input type='hidden' name='userField_sid' value='$FORM{sid}'>
<input type='hidden' name='userField_IP' value='$ENV{REMOTE_ADDR}'> 

<input type='hidden' name='eshopId' value='$conf{PAYSYS_RBKMONEY_ID}'>
<input type='hidden' name='orderId' value='%OPERATION_ID%'>
<input type='hidden' name='successUrl' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?UID=$LIST_PARAMS{UID}&index=$index&sid=$FORM{sid}&OPERATION_ID=%OPERATION_ID%&PAYMENT_SYSTEM=2&TRUE=1'>
<input type='hidden' name='failUrl' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?UID=$LIST_PARAMS{UID}&index=$index&sid=$FORM{sid}&FALSE=1&OPERATION_ID=%OPERATION_ID%&PAYMENT_SYSTEM=2&FALSE=1'>
<table clas=form>
<tr><th colspan='2' class='form_title'>RBKmoney</th></tr>
    <tr>
        <td>_{MONEY}_:</td>
        <td>%SUM_VAL_SEL%</td>
    </tr>
    <tr>
        <td>_{SUM}_:</td>
        <td><input type='text' name='recipientAmount' value='%SUM%'></td>
    </tr>
    <tr>
        <td>_{DESCRIBE}_:</td>
        <td><input type='text' name='serviceName' value='%DESCRIBE%'></td>
    </tr>
</table>
<input type='submit' name='button' value=' оплатить '>
</form>
