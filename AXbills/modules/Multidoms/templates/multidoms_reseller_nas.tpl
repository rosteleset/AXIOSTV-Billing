<div class='d-print-none'>
<a name='FORM_NAS'></a> 
<form action=$SELF_URL METHOD=post name=FORM_NAS>
<input type=hidden name='index' value='$index'>
<input type=hidden name='NAS_ID' value='%NAS_ID%'>
<TABLE>

<TR><th class=form_title colspan=2>%LNG_ACTION% _{NAS}_</th></TR>
<TR><TD>ID</TD><TD>%NAS_ID%</TD></TR>
<TR><TD>IP</TD><TD><input type=text name=NAS_IP value='%NAS_IP%'></TD></TR>
<TR><TD>_{NAME}_:</TD><TD><input type=text name=NAS_NAME value='%NAS_NAME%'></TD></TR>
<TR><TD>Radius NAS-Identifier:</TD><TD><input type=text name=NAS_INDENTIFIER value='%NAS_INDENTIFIER%'></TD></TR>
<TR><TD>_{DESCRIBE}_:</TD><TD><input type=text name=NAS_DESCRIBE value='%NAS_DESCRIBE%'></TD></TR>
<TR><TD>_{TYPE}_:</TD><TD>%SEL_TYPE%</TD></TR>
<TR><TD>Alive (sec.):</TD><TD><input type=text name=NAS_ALIVE value='%NAS_ALIVE%'></TD></TR>
<TR><TD>_{DISABLE}_:</TD><TD><input type=checkbox name=NAS_DISABLE value=1 %NAS_DISABLE%></TD></TR>
<TR><th colspan=2>:_{MANAGE}_:</th></TR>


<TR><TD>IP:PORT:</TD><TD><input type=text name=NAS_MNG_IP_PORT value='%NAS_MNG_IP_PORT%'></TD></TR>
<TR><TD>_{USER}_:</TD><TD><input type=text name=NAS_MNG_USER value='%NAS_MNG_USER%'></TD></TR>


<TR><TD>_{PASSWD}_:</TD><TD><input type=password name=NAS_MNG_PASSWORD value=''></TD></TR>
<TR><th colspan=2>RADIUS _{PARAMS}_ (,)</th></TR>
<TR><th colspan=2><textarea cols=50 rows=4 name=NAS_RAD_PAIRS>%NAS_RAD_PAIRS%</textarea></th></TR>
<TR><td align=right bgcolor='_{COLORS}_[9]' class=small colspan=2></td></TR>
<TR><TD>_{GROUP}_:</TD><TD>%NAS_GROUPS_SEL%</TD></TR>
%ADDRESS_TPL%
<TR><td align=right bgcolor='_{COLORS}_[9]' class=small colspan=2></td></TR>
<TR><TD colspan=2>%EXTRA_PARAMS%</TD></TR>

</TABLE>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>
</div>
