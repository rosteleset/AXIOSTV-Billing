<form name='FEEDBACK' id='form_FEEDBACK' class='form form-horizontal'
      action='https://support.billing.axiostv.ru/bugs.cgi' target='_blank'
      method='post' >
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='SYS_ID' value='%SYS_ID%'/>
  <input type='hidden' name='CUR_VERSION' value='%VERSION%'/>
  <input type='hidden' name='FEEDBACK' value='1'/>

  <div class='form-group row'>
    <label class='control-label col-md-3' for='COMMENTS_ID'>_{YOUR_FEEDBACK}_</label>
    <div class='col-md-9'>
      <textarea class='form-control' rows='5' name='ERROR' id='COMMENTS_ID'>%COMMENTS%</textarea>
    </div>
  </div>

  <div class='form-group text-center'>
    <input id='go' type='submit' form='form_FEEDBACK' class='btn btn-primary' name='add' value='_{SEND}_'>
  </div>

</form>
