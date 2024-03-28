<FORM action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{ID}'>
<table>
<tr><td>ID:</td><td>%ID%</td></tr>
<tr><td>FILENAME:</td><td><input type='text' name='FILENAME' value='%FILENAME%'></td></tr>
<tr><td>_{PATH}_:</td><td><input type='text' name='PATH' value='%PATH%'></td></tr>
<tr><td>_{NAME}_:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>CHECKSUM:</td><td><input type='text' name='CHECKSUM' value='%CHECKSUM%'></td></tr>
<tr><td>_{SIZE}_:</td><td><input type='text' name='SIZE' value='%SIZE%'></td></tr>
<tr><td>_{COMMENTS}_:</td><td><input type='text' name='COMMENTS' value='%COMMENTS%'></td></tr>
<tr><td>_{STATE}_:</td><td>%STATE_SEL%</td></tr>
</table>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%'>
 </FORM>
