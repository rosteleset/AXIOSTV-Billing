<FORM ACTION='https://secure.upc.ua/ecgtest/enter' METHOD='POST'>

<table width=400 class=form>

<INPUT TYPE='HIDDEN' NAME='Version' VALUE='1'>
<INPUT TYPE='HIDDEN' NAME='MerchantID' VALUE='$conf{PAYSYS_UPC_MERCHANT_ID}'>
<INPUT TYPE='HIDDEN' NAME='TerminalID' VALUE='$conf{PAYSYS_UPC_TERMINAL_ID}'>
<INPUT TYPE='HIDDEN' NAME='TotalAmount' VALUE='$FORM{SUM}'>
<INPUT TYPE='HIDDEN' NAME='Currency' VALUE='980'>
<INPUT TYPE='HIDDEN' NAME='locale' VALUE='RU'>
<INPUT TYPE='HIDDEN' NAME='PurchaseTime' VALUE='%PURCHASETIME%'>
<INPUT TYPE='HIDDEN' NAME='OrderID' VALUE='%OPERATION_ID%'>
<INPUT TYPE='HIDDEN' NAME='PurchaseDesc' VALUE='%DESCRIBE%'>
<INPUT TYPE='HIDDEN' NAME='Signature' VALUE='%SIGN%'>

<table width=400 class=form>
<tr><th class='form_title' colspan=2>eCommerce Connect</th></tr>

<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
    <tr>
        <td>_{BALANCE_RECHARCHE_SUM}_:</td>
        <td>%TOTALSUM%</td>
    </tr>
    <tr>
        <td>_{DESCRIBE}_:</td>
        <td>%DESCRIBE%</td>
    </tr>

<tr>

    <th colspan=2 class=even><input type=submit name=add value='_{PAY}_'>
</table>


</FORM>
