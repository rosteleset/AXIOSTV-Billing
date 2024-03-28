<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=%UID%>
<input type=hidden name=sid value=$FORM{sid}>
<input type=hidden name='UP_RATING' value='%UP_RATING%'>

<table width=400 class=form>
<tr><th colspan=2 class=form_title>_{RATING}_</th></tr>
<tr><td colspan=2>

_{OPERATION_FEES}_: %NEED_SUM%<br>
_{CONTINUE}_ ?


 </td></tr>
<tr><th colspan=2 class=even><input type=submit name=UP value='_{UP_RATING}_'></th></tr>
</table>


</form>