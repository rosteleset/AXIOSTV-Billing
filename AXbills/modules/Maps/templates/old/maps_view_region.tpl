<form action='$SELF_URL' name='region_view' class='form-inline'>
<input type=hidden name=index value=$index>

_{DISTRICT}_: %DISTRICTS_TABLE%
 <input type=CHECKBOX name=SHOW_USERS %SHOW_USERS% value=1 /> _{USER}_ &nbsp;&nbsp;
 %TYPES% &nbsp;&nbsp;
 <input type=CHECKBOX name=SHOW_NAS %SHOW_NAS%   value=1 /> _{NAS}_ &nbsp;&nbsp;
 <input type=submit name=SHOW value=_{SHOW}_ class='btn btn-primary'/>


</form>