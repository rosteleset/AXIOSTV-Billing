<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=msg value='$FORM{msg}'>
<table class=form>
<tr><td>UUID:</td><td>$FORM{msg}</td></tr>
<tr><th colspan=2><textarea name=MESSAGE cols=65 rows=5>%MESSAGE%</textarea></th></tr>
    <tr>
        <th class=even colspan=2><input type=submit name='SEND' value='_{SEND}_'></th>
    </tr>
</table>
</form>