<script language='JavaScript'>
  function autoReload() {
    document.iptv_user_info.add_form.value = '1';
    document.iptv_user_info.submit();
  }
</script>

<form method='POST' action='$SELF_URL' class='form form-horizontal' id='iptv_user_info' name='iptv_user_info'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='sid' value='$sid'>
  <input type='hidden' name='add_form' value=1>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border text-center'><h4 class='card-title'>_{SUBSCRIBES}_</h4></div>
    <div class='card-body'>

      <div class='form-group row text-center'>
        <label class='col-md-3 col-form-label text-md-right' for='SERVICE_ID'>_{CHOOSE_SERVICE}_:</label>
        <div class='col-md-9'>
          %SERVICE_SEL%
        </div>
      </div>

      <div class='panel panel-default'>
        %TP_SEL%
      </div>

      <div class='form-group text-center row'>
        <label class='col-md-3 col-form-label text-md-right'
               for='%SUBSCRIBE_PARAM_ID%'>%SUBSCRIBE_PARAM_NAME% %SUBSCRIBE_PARAM_DESCRIBE%:</label>
        <div class='col-md-9'>
          <input type='text' name='%SUBSCRIBE_PARAM_ID%' value='%SUBSCRIBE_PARAM_VALUE%' class='form-control'
                 id='%SUBSCRIBE_PARAM_ID%'>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input class='btn btn-primary float-right' type='submit' name=add value='_{DO_ENABLE}_'>
    </div>
  </div>
</form>
