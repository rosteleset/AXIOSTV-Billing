<form action=shop/cybercrd.cgi method=post id=form1 name=form1>
<input type=hidden name=uid value=\"$LIST_PARAMS{UID}\">
<input type=hidden name=index value=\"$index\">
<center>
<table border=0 cellpadding=0 cellspacing=0 bgcolor=\"#2d6294\" width=400>
<tr>
<td>
<table border=0 cellpadding=3 cellspacing=1 width=\"100%\">
<tr>
<td align=\"center\" colspan=2 bgcolor=\"#2d6294\"><font size=2><font color=\"#ffffff\">&nbsp;<b>CyberPlat(VISA/MasterCard)</b></font></td>
</tr>
<tr>
    <td colspan=2 bgcolor=\"#6da2d4\"><font size=2><font color=\"#ffffff\">&nbsp;<b>_{ORDER}_</b></font></td>
</tr>
<tr>
<td bgcolor=\"#ecf2f8\"><font size=2>OrderID (*):</td>
<td bgcolor=\"#ffffff\"><input type=text name=orderid value=\"%PAYMENT_NO%\"></td></tr>
<tr>
<td bgcolor=\"#ecf2f8\"><font size=2>Назначение<br>платежа:</td>
<td bgcolor=\"#ffffff\"><input type=text name=paymentdetails value=\"%desc%\" ></td></tr>
<tr>
<td bgcolor=\"#ecf2f8\"><font size=2>Сумма заказа(*):</td>
<td bgcolor=\"#ffffff\"><input type=text name=amount value=\"%amount_with_point%\" maxlength=6 size=6></td></tr>
<tr>
<td bgcolor=\"#ecf2f8\"><font size=2>Валюта(*):</td>
<td bgcolor=\"#ffffff\"><select name=currency  style=\"width:120\"><option selected value=2>Ъ рубли</option></select></td></tr>

<td bgcolor=\"#ecf2f8\"><font size=2>Язык</td>
<td bgcolor=\"#ffffff\"><select name=language style=\"width:120\"><option  selected value=ru> rus </option><option value=eng> eng </option></select></td></tr>
</table>
</td></tr>
</table>
<table border=0 cellpadding=0 cellspacing=0 bgcolor=\"#2d6294\" width=400>
<tr>
<td>
<table border=0 cellpadding=3 cellspacing=1 width=\"100%\">
<tr>
<td colspan=2 bgcolor=\"#6da2d4\"><font size=2><font color=\"#ffffff\">&nbsp;<b>Данные о покупателе</b></font></td>
</tr>
<tr>
<td bgcolor=\"#ecf2f8\"><font size=2>E-mail(*):</td>
<td bgcolor=\"#ffffff\"><input type=text name=email value=\"%email%\"></td>
</tr>
<tr>
<td bgcolor=\"#ecf2f8\"><font size=2>Телефон:</td>
<td bgcolor=\"#ffffff\"><input type=text name=phone value=\"%phone%\"></td>
</tr>
<!-- <tr>
<td bgcolor=\"#ecf2f8\"><font size=2>Адрес:</td>
<td bgcolor=\"#ffffff\"><input type=text name=address value=\"Moscow, Kutuzovsky pr. 12\"></td>
</tr>
-->
<tr>
<td bgcolor=\"#ecf2f8\"><font size=2>Фамилия(*):</td>
<td bgcolor=\"#ffffff\"><input type=text name=lastname value=\"%lastname%\">
</td>
</tr>
<tr>
<td bgcolor=\"#ecf2f8\"><font size=2>Имя(*):</td>
<td bgcolor=\"#ffffff\"><input type=text name=firstname value=\"%firstname%\"></td></tr>
<tr>
<td bgcolor=\"#ecf2f8\"><font size=2>Отчество:</td>
<td bgcolor=\"#ffffff\"><input type=text name=middlename value=\"%middlename%\"></td>

<input type=hidden name=result_url value=\"https://dev.axbills.net.ua:9443/shop/result.cgi\">

</tr>
<tr>
<td bgcolor=\"#ecf2f8\"><font size=2>Зарегистрирован<br>в CyberPlatPay?</td>
<td bgcolor=\"#ffffff\"><input type=checkbox name=registered></td></tr>
<tr>
    <td colspan=2 align=center bgcolor=\"#2d6294\"><input type=submit value=\" _{ADD}_ \"></td>
</tr>
</table>
</td>
</tr>
</table>
</form>

