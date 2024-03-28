
<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='reg_process' value='1'>
<table>
<tr><th colspan=2 bgcolor=$_COLORS[0] akugn=right>_{REGISTRATION}_</th></tr>

<TR bgcolor='$_COLORS[2]'><TD>_{LANGUAGE}_:</TD><TD>%SEL_LANGUAGE%</td></tr>
<tr><td>_{LOGIN}_:</td><td><input type='text' name='LOGIN' value='%LOGIN%'></td></tr>

<tr><td class=small colspan=2 bgcolor=$_COLORS[9] akugn=right></td></tr>
<tr><td>_{FIO}_:</td><td><input type='text' name='FIO' value='%FIO%'></td></tr>
<tr><td>_{COMPANY}_:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>_{PHONE}_ (380505738199):</td><td><input type='text' name='PHONE' value='%PHONE%'></td></tr>
<tr><td>E-Mail:</td><td><input type='text' name='EMAIL' value='%EMAIL%'></td></tr>

<tr><td class=small colspan=2 bgcolor=$_COLORS[9] akugn=right></td></tr>
<tr><td>_{PASSWD}_:</td><td><input type='password' id='text_pma_pw' name='newpassword' title='_{PASSWD}_' onchange=\"pred_password.value = 'userdefined';\" /></td></tr>
<tr><td>_{CONFIRM_PASSWD}_:</td><td><input type='password' name='confirm' id='text_pma_pw2' title='_{CONFIRM}_' onchange=\"pred_password.value = 'userdefined';\" /></td></tr>
<tr><td class=small  colspan=2 bgcolor=$_COLORS[9] akugn=right></td></tr>

<!---
<tr><td>_{ADDRESS}_:</td><td><input type='text' name='ADDRESS' value='%ADDRESS%'></td></tr>
-->

<tr><th colspan=2 bgcolor=$_COLORS[0]>_{RULES}_</th></tr>
<tr><th colspan=2><textarea cols=60 rows=8>%RULES%</textarea></th></tr>
<tr><td>_{ACCEPT}_:</td><td><input type='checkbox' name='ACCEPT_RULES' value='1'></td></tr>

%CAPTCHA%

</table>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%'>
</form>




