<table width=300 class=form>
<tr><th class='form_title'>PrivatBank</th></tr>
<tr><td>

<TABLE width='500'cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='#E1E1E1'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0'>
<tr><td class='title_color'>



<table width=100%>
    <tr>
        <td>_{ORDER}_:</td>
        <td>%OPERATION_ID%</td>
    </tr>
    <tr>
        <td>_{SUM}_:</td>
        <td>$FORM{SUM}</td>
    </tr>

<tr><th colspan=2 align=center>
<a href='https://secure.privatbank.ua/help/verified_by_visa.html'
<img src='/img/v-visa.gif' width=140 height=75 border=0></a>
<a href='http://www.mastercard.com/ru/personal/ru/cardholderservices/securecode/mastercard_securecode.html'>
<img src='/img/mastercard-sc.gif' width=140 height=75 border=0>
</a>
</td></tr>

</table>


<td></tr></table>
<td></tr></table>

<FORM id='checkout' name='checkout' method=post action='https://ecommerce.liqpay.com/ecommerce/CheckOutPagen'>

  <input id='Version'           type='hidden' name='version' value='1.0.0'>
	<input id='OrderID'           type='hidden' name='orderid' value='%OPERATION_ID%' >
	<input id='MerRespURL'        type='hidden' name='merrespurl' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi'>
	<input id='MerID'             type='hidden' name='merid' value='$conf{PAYSYS_PB_MERID}' >
	<input id='AcqID'             type='hidden' name='acqid' value='414963' >
	<input id='PurchaseAmt'       type='hidden' name='purchaseamt' value='%AMOUNT%' >
	<input id='PurchaseCurrencyExponent' type='hidden' name='purchasecurrencyexponent'  value='2' >
	<input id='PurchaseCurrency'  type='hidden' name='purchasecurrency' value='980' >
	<input id='Signature'         type='hidden' name='signature' value ='%HASH%' >
	<input id='orderdescription'  type='hidden' name='orderdescription' value='$FORM{DESCRIBE}'>
	<input id='MerRespURL2'       type='hidden' value='$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi'  name='MerRespURL2'>

<!--	
  <input id='SignatureMethod'   type='text' value='%SignatureMethod%' name='SignatureMethod'>
	<input id='CaptureFlag'       type='hidden' value='A' name='CaptureFlag'>
-->
  <input id='AdditionalData' type=hidden value='%AdditionalData%' name='AdditionalData'>
 
<script>
document.getElementById('checkout').submit();
</script>
</FORM>

</td></tr>
</table>



