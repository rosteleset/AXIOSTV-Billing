<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=%UID%>
<input type=hidden name=sid value=$FORM{sid}>

<table width=400 class=form>
<tr><th colspan=2 class=form_title>_{RATING}_</th></tr>
<tr><td>_{RATING}_:</td><td>%RATING_PER%</td></tr>
<tr><td>_{UP_RATING}_:</td><td><input type=text name='UP_RATING' value='%UP_RATING%' size=7> ( 1\% = %ONE_PERCENT_SUM%)</td></tr>
<tr><th colspan=2 class=even><input type=submit name=UP_RATING_PRE value='_{UP_RATING}_'></th></tr>
</table>


</form>