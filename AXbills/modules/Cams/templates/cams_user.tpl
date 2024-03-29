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
  <input type=hidden name=ID value='$FORM{chg}'>
  <input type=hidden name=UID value='$FORM{UID}'>
  <input type=hidden name=TP_IDS value='%TP_IDS%'>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type=hidden name='new' value=''>
  <input type=hidden name='add_form' value=''>

  %NEXT_FEES_WARNING%
  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{CAMERAS}_: %ID%</h3>
    </div>
    <div class='card-body'>
      %MENU%
      %SUBSCRIBE_FORM%
      %SERVICE_FORM%
      <div class='form-group row'>
        <label class='control-label col-md-3' for='TP'>_{TARIF_PLAN}_:</label>
        <div class='col-md-9'>
          %TP_ADD%
          <div class='input-group' %TP_DISPLAY_NONE%>
            <div class='input-group-prepend'>
              <span class='input-group-text bg-light'>%TP_NUM%</span>
            </div>
            <input type=text name='TP' value='%TP_NAME%' ID='TP' class='form-control hidden-xs' readonly>
            <div class='input-group-append'>
              <div class='input-group-text'>
                %CHANGE_TP_BUTTON%
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='STATUS_SEL'>_{STATUS}_:</label>
        <div class='col-md-9' style='background: %STATUS_COLOR%;'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='EMAIL'>E-mail:</label>
        <div class='col-md-9'>
          <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control' type='text'>
        </div>
      </div>

        <div class='card box-default box-big-form collapsed-card'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{EXTRA}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool btn-sm' data-card-widget='collapse'><i
                  class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>

            <div class='form-group row'>
              <label class='control-label col-md-3 text-right' for='ACTIVATE'>_{ACTIVATE}_:</label>
              <div class='col-md-3'>
                <input id='ACTIVATE' name='ACTIVATE' value='%ACTIVATE%'
                       placeholder='%ACTIVATE%' class='datepicker form-control' type='text'>
              </div>
              <label class='control-label col-md-2 text-right' for='EXPIRE'>_{EXPIRE}_:</label>
              <div class='col-md-4'>
                <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%'
                       placeholder='%EXPIRE%' class='datepicker form-control' type='text'>
              </div>
            </div>

            <div class='form-group row'>
                <label class='control-label col-md-3 text-right' for='ID'>ID:</label>
                <div class='col-md-3'>
                  <input value='%ID%' ID='ID' class='form-control' disabled>
                </div>
                <label class='control-label col-md-2 text-right' for='SUBSCRIBE_ID'>_{SERVICE}_:</label>
                <div class='col-md-4'>
                  <input value='%SUBSCRIBE_ID%' class='form-control' ID='SUBSCRIBE_ID' disabled>
                </div>
            </div>


            <div class='form-group row'>
              %EXTERNAL_INFO%
            </div>
          </div>
        </div>



    </div>
    <div class='card-footer'>
      %BACK_BUTTON%
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>

</form>

