<form action='%SELF_URL%' method='post'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='change_installation' value=1>
  <input type='hidden' name='INSTALLATION_ID' value='%INSTALLATION_ID%'>
  <input type='hidden' name='ARTICLE_ID1' value='%STA_ID%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{INSTALLATION}_</h4></div>
    <div class='card-body form form-horizontal'>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{ARTICLE}_:</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' value='%SAT_TYPE% %STA_NAME%' disabled>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>SN:</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='SERIAL' value='%SERIAL%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{COMMENTS}_:</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='INSTALLATION_COMMENTS'>%INSTALLATION_COMMENTS%</textarea>
        </div>
      </div>


    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='show_installation' value='_{CHANGE}_'>
    </div>
  </div>

</form>