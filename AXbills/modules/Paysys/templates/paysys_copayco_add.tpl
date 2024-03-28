<!-- <form action='https://www.test.copayco.com/pay.php' name='pay_form' method=POST> -->

<form action='https://www.copayco.com/pay.php' name='pay_form' method=POST>

<input name='shop_id' value='$conf{PAYSYS_COPAYCO_SHOP_ID}' type='hidden'>
<input name='ta_id' value='%OPERATION_ID%' type='hidden'>
<input name='amount' value='%SUM%' type='hidden'>
<input name='currency' value='%CURRENCY%' id='currency1' type='hidden'>
<input name='description' value='%DESCRIBE%' type='hidden'>
<input name='custom' value='%CUSTOM%' type='hidden'>
<input name='date_time' value='%DATETIME%' type='hidden'>
<input name='random' value='%RANDOM%' type='hidden'>
<input name='signature' value='%SIGN%' type='hidden'>



<table width=300 class=form>
<tr><th colspan='2' class='form_title'>CoPAYCo</th></tr>
<tr>
	<td>ID:</td>
	<td>%OPERATION_ID%</td>
</tr>
<tr>
    <td>_{SUM}_:</td>
	<td>%SUM%</td>
</tr>
<tr>
    <td>_{DESCRIBE}_:</td>
	<td>%DESCRIBE%</td>
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
