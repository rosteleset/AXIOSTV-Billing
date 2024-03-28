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
        %STORAGE_FORM%

        <label class='control-label col-md-3'>_{NUM}_:</label>
        <div class='col-md-9'>
          <label class='label label-primary'>%NUM% %NAME%</label>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='PIN'>PIN:</label>
        <div class='col-md-9'>
          <input id='PIN' name='PIN' value='%PIN%' placeholder='%PIN%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='CID'>MAC/CID:</label>
        <div class='col-md-9'>
          <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text' %DISABLED_INPUT%>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='SERIAL'>_{SERIAL}_:</label>
        <div class='col-md-9'>
          <input id='SERIAL' name='SERIAL' value='%SERIAL%' placeholder='%SERIAL%' class='form-control'
                 type='text' %DISABLED_INPUT%>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-sm-2 col-md-3' for='COMMENT'>_{DESCRIBE}_:</label>
        <div class='col-sm-10 col-md-9'>
          <textarea class='form-control' id='COMMENT' name='COMMENT' rows='3'>%COMMENT%</textarea>
        </div>
      </div>

      %FORM_DEVICE%

      %DEVICE_BINDING_CODE_FORM%

    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
      %DELETE%
    </div>
  </div>

</form>

