<form action="$SELF_URL">
  <!-- <input type=hidden name=index value=$index> -->
  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{STREETS}_ _{SEARCH}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='STREET_NAME'>_{STREET}_:</label>
        <div class='col-md-8'>
          <input id='STREET_NAME' type='text' class='form-control' name='STREET_NAME' value='%NAME%'>
        </div>
      </div>
    </div>
  </div>
</form>



<!--<form action=$SELF_URL>-->
<!--<input type=hidden name=index value=$index>-->
<!--<table border=1 width=300>-->
<!--<TR><TH class='form_title' colspan='2'>_{STREETS}_ _{SEARCH}_</TH></TR>-->
<!--<tr><td>_{ADDRESS_STREET}_:</td><td>%STREET_SEL%</td></tr>-->
<!--<tr><td>_{SEARCH}_:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>-->
<!--<tr><th colspan=2>_{BUILDS}_</th></tr>-->
<!--<tr><td colspan=2>%BUILDS%</td></tr>-->
<!--<tr><th colspan=2><input type=submit name=search value='_{SEARCH}_'></th></tr>-->
<!--</table>-->
<!--</form>-->

