<form action=$SELF_URL name='storage_form_discard' method=POST>
  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value=%ID%>

    <div class='card card-primary card-outline card-form'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{DISCARD}_</h4>
      </div>
      <div class='card-body'>

        <div class='form-group row'>
          <label class='col-md-3 control-label' for='COUNT'>_{COUNT}_:</label>
          <div class='col-md-9'>
            <input class='form-control' id='COUNT' name='COUNT' type='text' value='%COUNT%'/>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-3 control-label' for='COMMENTS'>_{COMMENTS}_:</label>
          <div class='col-md-9'>
            <textarea class='form-control col-xs-12' id='COMMENTS' name='COMMENTS'>%COMMENTS%</textarea>
          </div>
        </div>

      </div>
      <div class='card-footer'>
        <input type=submit name=%ACTION% value=%ACTION_LNG% class='btn btn-primary'>
      </div>
    </div>
</form>