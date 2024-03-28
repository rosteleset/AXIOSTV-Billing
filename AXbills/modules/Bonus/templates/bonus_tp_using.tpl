<form action='$SELF_URL' METHOD='POST' name='user' class='form-horizontal'>
  <input type=hidden name='ID' value='$FORM{chg}'>
  <input type=hidden name='index' value='$index'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{TARIF_PLANS}_</h4></div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-4' for='TP_ID_MAIN'>_{MAIN}_:</label>
        <div class='col-md-8'>
          %TP_ID_MAIN_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4' for='TP_ID_BONUS'>_{BONUS}_</label>
        <div class='col-md-8'>
          %TP_ID_BONUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for='PERIOD'>_{PERIOD}_ (_{MONTH}_):</label>
        <div class='col-md-8'>
          <input required='' type='text' class='form-control' id="PERIOD" name='PERIOD' value='%PERIOD%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <input required='' type='text' class='form-control' id="COMMENTS" name='COMMENTS'
                 value='%COMMENTS%'/>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name=%ACTION% value='%LNG_ACTION%'>
    </div>
  </div>
</form>