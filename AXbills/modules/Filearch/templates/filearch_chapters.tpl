<FORM action='$SELF_URL'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{ID}'>
<table>
<tr><td>_{NAME}_:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>_{TYPE}_:</td><td>%TYPE_SEL%</td></tr>
<tr><td>_{FOLDER}_:</td><td><input type='text' name='DIR' value='%DIR%'></td></tr>
<tr><td>_{SKIP}_:</td><td><input type='text' name='SKIP' value='%SKIP%'></td></tr>
</table>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%'>
</FORM>
