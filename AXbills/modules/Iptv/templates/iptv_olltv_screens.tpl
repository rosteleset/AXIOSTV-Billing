<form action=$SELF_URL method=post class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=screen value='$FORM{screen}'>
  <input type=hidden name=UID value='$FORM{UID}'>
  <input type=hidden name=chg value='$FORM{chg}'>
  <input type=hidden name=MODULE value='Iptv'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SCREENS}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='NUM'>_{NUM}_:</label>
        <div class='col-md-9'>
          <span class='label label-primary'>%NUM%</span>
          %NAME%
        </div>
      </div>

      %FORM_DEVICE%

      <div class='card-footer'>
        <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
        %DELETE%
      </div>
    </div>

  </div>
</form>



