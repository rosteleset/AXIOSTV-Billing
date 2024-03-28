<form action=$SELF_URL METHOD=POST>
<input type=hidden name='index' value='$index'>
<input type=hidden name='ID' value='$FORM{chg}'>
<table class=form>

<tr><td>ID:</td><td> %ID%</td></tr>
<tr><td>_{USER}_ (\$GLOBAL - _{ALL}_):</td><td><input type=text name=USER_NAME value='%USER_NAME%'></td></tr>
<tr><td>_{OPTIONS}_:</td><td><input type=text name=PREFERENCE value='%PREFERENCE%'></td></tr>
<tr><td>_{VALUE}_:</td><td><input type=text name=VALUE value='%VALUE%'></td></tr>
<tr><td>_{COMMENTS}_:</td><td><input type=text name=COMMENTS value='%COMMENTS%'></td></tr>
<tr><td>_{ADDED}_:</td><td>%ADD%</td></tr>
<tr><td>_{CHANGED}_:</td><td>%CHANGED%</td></tr>
<tr><th class=form_title colspan=2><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>
</form>
