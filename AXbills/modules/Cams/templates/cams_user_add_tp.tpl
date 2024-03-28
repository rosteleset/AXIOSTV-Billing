<script language='JavaScript'>
  function autoReload() {
    document.cams_user_info.add_form.value = '1';
    document.cams_user_info.TP_ID.value = '';
    document.cams_user_info.new.value = '$FORM{new}';
    document.cams_user_info.step.value = '$FORM{step}';
    document.cams_user_info.submit();
  }
</script>

<form action='$SELF_URL' method=post name='cams_user_info' class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=sid value='$FORM{sid}'>
  <input type=hidden name=TP_IDS value='%TP_IDS%'>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type=hidden name='new' value=''>
  <input type=hidden name='add_form' value=''>

  %NEXT_FEES_WARNING%
  <div class='card card-primary card-outline card-form card-big-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{TARIF_PLAN}_</h4></div>
    <div class='card-body'>
      %MENU%
      %SUBSCRIBE_FORM%
      %SERVICE_FORM%
      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='TP_NUM'>_{TARIF_PLAN}_:</label>
        <div class='col-md-9'>
          %TP_ADD%
          <div class='input-group' %TP_DISPLAY_NONE%>
            <div class='input-group-prepend'>
              <span class='input-group-text bg-light'>%TP_NUM%</span>
            </div>
            <input type=text name='TP' value='%TP_NAME%' ID='TP' class='form-control hidden-xs' readonly>
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='EMAIL'>E-mail:</label>
        <div class='col-md-9'>
          <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control'
                 type='text'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      %BACK_BUTTON%
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>
