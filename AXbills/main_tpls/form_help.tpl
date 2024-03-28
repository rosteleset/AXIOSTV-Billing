<center>
<form action='$SELF_URL' METHOD=post>
<input type=hidden name='index' value='$FORM{index}'>
<input type=hidden name='FUNCTION' value='$FORM{FUNCTION}'>
<input type=hidden name='language' value='%LANGUAGE%'>
<table border='0'>
<tr><td>_{SUBJECT}_: </td><td><input type=text name=TITLE value='%TITLE%' size=40></td></tr>
<tr><th colspan='2' bgcolor='_{COLORS}_[0]'>_{HELP}_</th></tr>
<tr><th colspan='2'><textarea name='HELP' cols='50' rows='4'>%HELP%</textarea></th></tr>
<tr><td colspan='2'>%LANGUAGE%</td></tr>
<tr><th colspan='2'><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>
</form>
</center>
