<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<table class=form>
<tr><td>_{LOGIN}_:</td><td>%LOGIN%</td></tr>
<tr><td>IP:</td><td>%IP%</td></tr>
<tr><td>_{TARIF_PLAN}_:</td><td>%TP_SEL%</td></tr>
<tr><td>_{SUM}_:</td><td><input type='text' name='SUM' value='%SUM%'></td></tr>
<tr><td>_{NAS}_:</td><td>%NAS_SEL%</td></tr>
<tr><td>_{ACTIVATE}_:</td><td><input type='checkbox' name='ACTIVATE' value='1' %ACTIVATE%></td></tr>
<tr><td>_{COUNT}_:</td><td><input type='text' name='COUNT' value='%COUNT%'></td></tr>
<tr><th colspan=2 class=even><input type=submit name='add' value='_{ADD}_'></th></tr>
</table>
</form>

