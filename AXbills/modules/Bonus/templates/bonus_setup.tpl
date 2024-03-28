<form action='$SELF_URL'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>
<input type=hidden name=TP_ID value=$FORM{TP_ID}>
<table class=form>
<tr><td>_{TARIF_PLAN}_:</td><td>$FORM{TP_ID}</td></tr>
<tr><td>_{PERIOD}_ (_{DAYS}_):</td><td><input type=text name='PERIOD' value='%PERIOD%'></td></tr>
<tr><td>_{FROM}_:</td><td><input type=text name='RANGE_BEGIN' value='%RANGE_BEGIN%'></td></tr>
<tr><td>_{TO}_:</td><td><input type=text name='RANGE_END' value='%RANGE_END%'></td></tr>
<tr><td>_{SUM}_:</td><td><input type=text name='SUM' value='%SUM%'></td></tr>
<tr><th class=form_title colspan='2'>_{COMMENTS}_</th></tr>
<tr><th colspan='2'><textarea name='COMMENTS' rows='5' cols='40'>%COMMENTS%</textarea></th></tr>
<tr><th class=evan colspan=2><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>
</form>
