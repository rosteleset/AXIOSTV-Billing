<form action=$SELF_URL name='depot_form_types' method=POST>
  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value=$FORM{chg}>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{TYPE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{TYPE}_:</label>
        <div class='col-md-8'>
          <input class='form-control' name='NAME' type='text' value='%NAME%'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
    </div>
  </div>
</form>
