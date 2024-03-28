<form action=$SELF_URL name='storage_form_subreport' method=POST>
  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value=%ID%>
  <input type=hidden name=STORAGE_INCOMING_ARTICLES_ID value=$FORM{reserve}/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{RESERVE}_</h4>
    </div>
    <div class='card-body'>
<!--      <div class='form-group row'>-->
<!--        <label class='col-md-3 control-label'>_{RESERVED}_:</label>-->
<!--        <div class='col-md-9'>%AID_SEL%</div>-->
<!--      </div>-->
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{COUNT}_:</label>
        <div class='col-md-9'><input class='form-control' name='COUNT' type='text' value='%COUNT%'/></div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{COMMENTS}_</label>
        <div class='col-md-9'><textarea class='form-control col-xs-12' name='COMMENTS'>%COMMENTS%</textarea></div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
    </div>
  </div>
</form>