<script type=\"text/javascript\" src=\"../ajax/maps/coords.js\"></script>
<form action=$SELF_URL ID=mapForm name=adress align=center>
<input type=hidden name=index value=$index>
<table>
<tr><td>
  <table class=form>
  %ADDRESS_TPL%
  </table>
</td>
<td>
<table>
<tr>
<td>_{ANGLE}_ 1:</td>
<td>X:<INPUT id=hx1 size=4 name=MAP_X>
Y:<INPUT id=hy1 size=4 name=MAP_Y></td>
</tr>
<tr>
<td>_{ANGLE}_ 2:</td>
<td>X:<INPUT id=hx2 size=4 name=MAP_X2>
Y:<INPUT id=hy2 size=4 name=MAP_Y2></td>
</tr>
<tr>
<td>_{ANGLE}_ 3:</td>
<td>
 X:<INPUT id=hx3 size=4 name=MAP_X3>
 Y:<INPUT id=hy3 size=4 name=MAP_Y3></td>
</tr>
<tr>
<td>_{ANGLE}_ 4:</td>
<td>
  X:<INPUT id=hx4 size=4 name=MAP_X4>
  Y:<INPUT id=hy4 size=4 name=MAP_Y4></td>
</tr>
</table>
</td>

<tr>
<td colspan=2 align=center>X :<label for=coordX> </label><input type=text name=coordX size=4 /> Y:<label for=coordY> </label><input type=text name=coordY size=4 /></td>
</tr>
<tr>
  <th colspan=2 class=even><input type=submit name=change value=_{CHANGE}_>
      <INPUT type=button onClick=coordsClear(); value=_{CLEAR};_/>
  </th>
</tr>
</tr></table>



