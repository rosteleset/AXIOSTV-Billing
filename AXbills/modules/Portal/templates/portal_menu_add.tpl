<form action=$SELF_URL name='depot_form_types' method=POST class='form-horizontal'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>


<div class='card card-form card-primary card-outline box-form'>
  <div class='card-header with-border'>
    <h4 class='card-title'>%TITLE_NAME%</h4>
  </div>
  <div class='card-body'>
    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{NAME}_:</label>
      <div class='col-md-9'>
        <input class='form-control' name='NAME' type='text' value='%NAME%'/>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-3 control-label'>URL:</label>
      <div class='col-md-9'>
        <input class='form-control' name='URL' type='text' value='%URL%'/>
      </div>
    </div>

    <div class='form-group offset-4'>
      <div class='radio col-md-6'>
        <label><input type='radio' name='STATUS' value='1' %SHOWED%>_{SHOW}_ _{MENU}_</label>
      </div>
      <div class='radio col-md-6'>
        <label><input type='radio' name='STATUS' value='0' %HIDDEN%>_{HIDE}_ _{MENU}_</label>
      </div>
    </div>
  </div>
  <div class='card-footer'>
    <input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
  </div>
</div>

</form>
