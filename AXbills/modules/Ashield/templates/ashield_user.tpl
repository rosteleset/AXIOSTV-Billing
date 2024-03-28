<div class='card card-primary card-outline'>
<div class='card-body'>

%MENU%


<form action=$SELF_URL method=post NAME=user_form>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=info value='$FORM{info}'>

<table cellspacing='0' cellpadding='3' width=500>
    <tr>
        <th colspan=4 class=form_title>_{ANTIVIRUS}_ Dr.Web</th>
    </tr>
    <tr>
        <td rowspan=2><input type=radio name=STATUS value='2'> _{HOLD_UP}_</td>
        <td>_{FROM}_:</td>
        <td>%DATE_FROM%</td>
    </tr>
    <tr>
        <td>_{TO}_:</td>
        <td>%DATE_TO%</td>
        <th>%RESET_BLOCK%</th>
    </tr>

<tr><td colspan=4 class=small></td></tr>
    <tr>
        <td colspan=2><input type=radio name=STATUS value='1'> _{DISABLE}_</td>
        <td>%EXPIRES_DATE%</td>
        <th>%RESET_EXPIRE%</th>
    </tr>
<tr><td colspan=4 class=small></td></tr>
    <tr>
        <td colspan=2>_{CHANGE}_ _{TARIF_PLAN}_:</td>
        <td colspan=2>%TP_SEL%</td>
    </tr>

<tr><th class=even colspan=4>%ACTION%</th></tr>
</table>

</form>

</div>
</div>