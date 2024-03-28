<form id=pay name=pay method='GET' action='%form_url%'>
<input type='hidden' name='ReturnUrl' value='%returnurl%'>
<input type='hidden' name='FailUrl' value='%failurl%'>
<input type='hidden' name='OrderId' value='%OrderId%'>
<input type='hidden' name='MerchantId' value='$conf{PAYSYS_PAYONLINE_MERCHANT_ID}'>
<input type='hidden' name='Amount' value='%amount%'>
<input type='hidden' name='Currency' value='RUB'>
<input type='hidden' name='OrderDescription' value='%desc%'>
<input type='hidden' name='SecurityKey' value='%securitykey%'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='PaymentSystemId' value='%payment_system_id%'>
<table width=300 class=form>
<tr><th colspan='2' class='form_title'>%payment_form_title% - Payonline</th></tr>
<tr>
	<td>ID:</td>
	<td>%OrderId%</td>
</tr>
<tr>
    <td>_{SUM}_:</td>
	<td>%amount%</td>
</tr>
<tr>
    <td>_{DESCRIBE}_:</td>
	<td>%desc%</td>
</tr>
<tr>
	<td>&nbsp;</td>
	<td>&nbsp;</td>
</tr>
    <tr>
        <th colspan='2' class='even'><input type='submit' value='_{ADD}_'></th>
    </tr>
</table>

</form>
