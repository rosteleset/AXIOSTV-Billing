<script language=\"JavaScript\" type=\"text/javascript\">
<!--


function samechanged(what) {
  if ( what.value == 1 ) {
    what.form.TP_ID.disabled = false;
    what.form.TP_ID.style.backgroundColor = '#eeeeee';
  } else {
    what.form.TP_ID.disabled = true;
    what.form.TP_ID.style.backgroundColor = '#dddddd';
  }
}

samechanged('STATE');





function make_unique() {
    var pwchars = \"abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ.,:\";
    var passwordlength = 8;    // do we want that to be dynamic?  no, keep it simple :)
    var passwd = document.getElementById('OP_SID');

    passwd.value = '';

    for ( i = 0; i < passwordlength; i++ ) {
        passwd.value += pwchars.charAt( Math.floor( Math.random() * pwchars.length ) )
    }
    return passwd.value;

}
-->
</script>

<form action='$SELF_URL' METHOD='POST' TARGET=New  ENCTYPE='multipart/form-data'>

<input type='hidden' name='qindex' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<input type='hidden' name='OP_SID' value='%OP_SID%' ID=OP_SID>
<input type='hidden' name='sid' value='$sid'>
<table width=600>
<tr bgcolor='$_COLORS[0]'><th colspan=2 align=right>_{ICARDS}_</th></tr>
<tr><td>_{COUNT}_:</td><td><input type='text' name='COUNT' value='%COUNT%'></td></tr>
<tr><td>_{SUM}_:</td><td><input type='text' name='SUM' value='%SUM%'></td></tr>

<tr><td class=small colspan=2 bgcolor=$_COLORS[9]></td></tr>


<tr><td>_{TYPE}_:</td><td>%TYPE_SEL%</td></tr>
<tr><td>_{TARIF_PLAN}_:</td><td>%TP_SEL%</td></tr>

<tr><td>_{EXPORT}_:</td><td>
<input type=radio name=EXPORT value=xml>   XML
<input type=radio name=EXPORT value=text>  TEXT
<input type=radio name=EXPORT value=print CHECKED> _{PRINT}_
<input type=radio name=EXPORT value=order_print> _{ORDER_PRINT}_
</td></tr>
<tr><td>_{IMPORT}_:</td><td><input type=file name=import></td></tr>

</table>

<input type='submit' name='add' value='_{ADD}_' onclick=\"make_unique(this.form)\">
</form>

