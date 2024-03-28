<form action='$SELF_URL' class='form form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value=$FORM{chg}>
  <input type=hidden name=TP_ID value=$FORM{TP_ID}>


  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>_{TARIF_PLAN}_</div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{TARIF_PLAN}_:</label>
        <div class='col-md-9'>
          $FORM{TP_ID}
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type=text name='NAME' class='form-control' value='%NAME%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='STATE'>_{ACTIVE}_:</label>
        <div class='col-md-8'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='STATE' name='STATE' %STATE% value='1'>
          </div>
        </div>
      </div>

      <hr/>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea name='COMMENTS' class='form-control' rows='5'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit name=%ACTION% value='%LNG_ACTION%'>
    </div>
  </div>

</form>
