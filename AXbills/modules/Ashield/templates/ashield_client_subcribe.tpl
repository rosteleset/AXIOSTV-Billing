<form action=$SELF_URL method=post NAME=user_form>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=OP_SID value='%OP_SID%'>
<input type=hidden name=sid value='$sid'>
<table cellspacing='0' cellpadding='3' width='500'>
<tr><th class=form_title colspan=2>Dr.Web </th></tr>
<tr><td colspan=2>
%TARIF_PLAN_TABLE%
</td></tr>

<!--
<tr><th colspan=2 class=form_title>_{REGISTRATION}_ - _{ANTIVIRUS}_ Dr.Web</th></tr>
<tr><th colspan=2><a href='' target_new>_{INFO}_</a></th></tr>
<tr><td>E-mail:</td><td>%EMAIL%</td></tr>	
-->
<tr><th class=even colspan=2><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>

</form>

