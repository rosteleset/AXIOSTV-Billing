<div class='d-print-none' name='FORM_TP'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='$FORM{TP_ID}'>
<table class=form width=600>
  <tr><th colspan='2' class=form_title>_{RATING}_</th></tr>
  <tr><td>_{RATING}_:</td><td>_{FROM}_: <input type=input size=5 name=RATING_FROM value=%RATING_FROM%> _{TO}_: <input type=input size=5 name=RATING_TO value=%RATING_TO%></td></tr>
  <tr><td>_{ACTION}_:</td><td>%RATING_ACTION_SEL%</td></tr>

  <tr><th colspan=2 class=form_title>_{BONUS}_</th></tr>
  <tr><td>_{ACTIVATE}_:</td><td><input type=input size=7 name=ACTIVE_BONUS value=%ACTIVE_BONUS%> </td></tr>
  <tr><td>_{CHANGE}_:</td><td><input type=input size=7 name=CHANGE_BONUS value=%CHANGE_BONUS%> </td></tr>
  <tr><td>_{EXTRA}_ _{BILL}_:</td><td><input type=checkbox name=EXT_BILL_ACCOUNT value=1 %EXT_BILL_ACCOUNT%> </td></tr>

  <tr><th colspan=2 class=form_title>_{COMMENTS}_</th></tr>
  <tr><th colspan=2><textarea cols=50 rows=5 name=COMMENTS>%COMMENTS%</textarea></th></tr>
  <tr><th colspan='2' class=even><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>

</form>
</div>

