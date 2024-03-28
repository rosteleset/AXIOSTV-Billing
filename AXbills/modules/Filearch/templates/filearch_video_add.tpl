<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{ID}'>
<input type='hidden' name='FILENAME' value='%FILENAME%'>
<input type='hidden' name='FILEPATH' value='%PATH%'>
<input type='hidden' name='extdb_type' value='$FORM{extdb_type}'>
<input type='hidden' name='COUNTRY' value='%COUNTRY%'>



<TABLE width='90%' border='0'>
<tr><td>_{NAME}_:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>_{ORIGIN_NAME}_:</td><td><input type='text' name='ORIGIN_NAME' value='%ORIGIN_NAME%'></td></tr>
<tr><td>_{YEAR}_:</td><td><input type='text' name='YEAR' value='%YEAR%'></td></tr>
<tr><td>_{COUNTRY}_:</td><td>%COUNTRY_SEL% %COUNTRY%</td></tr>
<tr><td>_{GENRE}_:</td><td>%GENRES% %GENRE%</td></tr>
<tr><td>_{PRODUCER}_:</td><td><input type='text' name='PRODUCER' value='%PRODUCER%'></td></tr>
<tr><td>_{ACTORS}_:</td><td><input type='text' name='ACTORS' value='%ACTORS%'></td></tr>
<tr bgcolor='$_COLORS[0]'><th colspan=2>:_{DESCRIBE}_:</th></tr>
<tr><th colspan=2><textarea name='DESCR' cols='80' rows='5'>%DESCR%</textarea></th></tr>
<tr><td>_{STUDIO}_:</td><td><input type='text' name='STUDIO' value='%STUDIO%'></td></tr>
<tr><td>_{DURATION}_:</td><td><input type='text' name='DURATION' value='%DURATION%'></td></tr>
<tr><td>_{LANGUAGE}_:</td><td>%LANGUAGE_SEL%</td></tr>
<tr><td>_{COMMENTS}_:</td><td><input type='text' name='COMMENTS' value='%COMMENTS%'></td></tr>
<tr><td>_{EXTRA}_:</td><td><input type='text' name='EXTRA' value='%EXTRA%'></td></tr>
<tr bgcolor='$_COLORS[0]'><th colspan=2>FILE</th></tr>
<tr><td>_{SIZE}_:</td><td>%SIZE%</td></tr>
<tr><td>_{FORMAT}_:</td><td><input type='text' name='FILE_FORMAT' value='%FILE_FORMAT%'></td></tr>
<tr><td>_{QUALITY}_:</td><td><input type='text' name='FILE_QUALITY' value='%FILE_QUALITY%'></td></tr>
<tr><td>_{VSIZE}_:</td><td><input type='text' name='FILE_VSIZE' value='%FILE_VSIZE%'></td></tr>
<tr><td>_{SOUND}_:</td><td><input type='text' name='FILE_SOUND' value='%FILE_SOUND%'></td></tr>
<tr bgcolor='$_COLORS[2]'><td>_{COVER}_:</td><td><input type='text' name='COVER' value='%COVER%'></td></tr>
<tr bgcolor='$_COLORS[2]'><td>_{COVER}_ 2:</td><td><input type='text' name='COVER_SMALL' value='%COVER_SMALL%'></td></tr>
<tr><th colspan=2><img src='%COVER_SMALL%' alt='%NAME%'></th></tr>
<tr><th colspan=2><img src='%COVER%' alt='%NAME%'></th></tr>
<tr><td>_{PARENT}_:</td><td><input type='text' name='PARENT' value='%PARENT%'></td></tr>

<tr bgcolor='$_COLORS[0]'><th colspan=2>_{DOWNLOAD}_:</th></tr>
<tr><th colspan=2>%DOWNLOAD%</th></tr>

<tr bgcolor='$_COLORS[0]'><th colspan=2>_{INFO}_:</th></tr>
<tr><th colspan=2>%EXT_CHECK%</th></tr>
<tr><td>_{RENAME_FILE}_:</td><td><input type=checkbox name=RENAME_FILE value=1 checked></td>
<tr><td>_{PIN_ACCESS}_:</td><td><input type=checkbox name=PIN_ACCESS value=1></td>
</TABLE>

<input type='submit' name='%ACTION%' value='%LNG_ACTION%'>
</FORM>
