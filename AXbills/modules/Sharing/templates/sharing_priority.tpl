<div class='d-print-none'>
<form action='$SELF_URL' method='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='ID' value='$FORM{chg}'>
<table>
<tr><td>Server:</td><td><input type=text name='SERVER' value='%SERVER%'></td></tr>
    <tr>
        <td>_{FILE}_:</td>
        <td><input type=text name='FILE' value='%FILE%'></td>
    </tr>
    <tr>
        <td>_{SIZE}_:</td>
        <td><input type=text name='SIZE' value='%SIZE%'></td>
    </tr>
    <tr>
        <td>_{PRIORITY}_:</td>
        <td><input type=text name='PRIORITY' value='%PRIORITY%'></td>
    </tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>
