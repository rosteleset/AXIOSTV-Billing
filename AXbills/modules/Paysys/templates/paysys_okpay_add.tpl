<form  method='post' action='https://www.okpay.com/process.html'>
<input type='hidden' name='ok_receiver' value='$conf{PAYSY_OKPAY_RECEIVER}'/>
<input type='hidden' name='ok_item_1_name' value='$FORM{OPERATION_ID}'/>
<input type='hidden' name='ok_currency' value='USD'/>
<input type='hidden' name='ok_item_1_type' value='service'/>
<input type='hidden' name='ok_item_1_price' value='$FORM{SUM}'/>
<input type='hidden' name='ok_return_success' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$index&sid=$sid&TRUE=1&OPERATION_ID=$FORM{OPERATION_ID}&PAYMENT_SYSTEM=87'/>
<input type='hidden' name='ok_return_fail' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$index&sid=$sid&ERROR=1&OPERATION_ID=$FORM{OPERATION_ID}&PAYMENT_SYSTEM=87'/>
<input type='hidden' name='ok_ipn' value='http://$ENV{SERVER_NAME}/paysys_check.cgi'/>
<input type='hidden' name='ok_item_1_custom_1_title' value='UID'>
<input type='hidden' name='ok_item_1_custom_1_value' maxlength='127' value='$UID'>

<table width=400 class=form>
<tr><th class='form_title' colspan=2>OkPay</th></tr>
<tr><td colspan=2 align=center><img src='https://www.redstarpoker.ru/images/sitepics/ru/okpay-logo-150x74-white.png'></td></tr>
<tr><th colspan=2 align=center>
</a>
</td></tr>

<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
    <tr>
        <td>_{BALANCE_RECHARCHE_SUM}_:</td>
        <td>$FORM{SUM}</td>
    </tr>
    <!-- <tr><td>_{PAY_WAY}_:</td><td>%PAY_WAY_SEL%</td></tr> -->

    <tr>
        <th colspan=2 class=even><input type=submit name=submit value='_{PAY}_'></th>
    </tr>
</table>
</form>

