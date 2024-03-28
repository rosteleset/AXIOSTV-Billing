<form action=$SELF_URL name=multi_create>
<input type=hidden name=index value=$index>

%USERS_TABLE%

<table>
<tr><td>_{DATE}_:</td><td>%DATE% </td></tr>
<tr><td>_{ORDER}_:</td><td><input size=30 type=text name=ORDER value=%ORDER%></td></tr>
<tr><td>_{SUM}_:</td><td><input  type=text name=SUM value='%SUM%' size=5></td></tr>
<tr><td>_{SEND}_ E-mail:</td><td><input type=checkbox name=SEND_EMAIL value='1' checked></td></tr>
</table>

    <input type=submit name=create value='_{CREATE}_'>
</form>
