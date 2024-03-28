<form action='%SELF_URL%' method=post name='iptv_user_info' class='form-horizontal'>
  <input type=hidden name=index value=%index%>
  <input type=hidden name=ID value='$FORM{chg}'>
  <input type=hidden name=UID value='$FORM{UID}'>
  <input type=hidden name=TP_IDS value='%TP_IDS%'>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type=hidden name='new' value=''>
  <input type=hidden name='add_form' value=''>

  <fieldset>
    %NEXT_FEES_WARNING%
    <div class='card card-primary card-outline container-md'>
      <div class='card-header with-border'><h4 class='card-title'>_{TV}_: %ID%</h4></div>
      <div class='card-body'>
        %MENU%
        %SUBSCRIBE_FORM%
        %SERVICE_FORM%
        <div class='form-group row'>
          <label class='control-label col-md-3 text-right'>_{TARIF_PLAN}_:</label>
          <div class='col-md-9'>
            %TP_ADD%
            <div class='input-group' %TP_DISPLAY_NONE%>
              <div class='input-group-prepend'>
                <span class='input-group-text bg-light'>%TP_NUM%</span>
              </div>
              <input type=text name='GRP' value='%TP_NAME% %DESCRIBE_AID%' ID='TP' class='form-control hidden-xs' readonly>
              <div class='input-group-append'>
                <div class='input-group-text'>
                  %CHANGE_TP_BUTTON%
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3 text-right'>_{STATUS}_:</label>
          <div class='col-md-9' style='background: %STATUS_COLOR%;'>
            %STATUS_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3 text-right' for='EMAIL'>E-mail:</label>
          <div class='col-md-9'>
            <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control'
                   type='text'>
          </div>
        </div>


        <div class='form-group row'>
          <label class='control-label col-md-3 text-right' for='CID'>MAC (Modem):</label>
          <div class='col-md-9'>
            <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'>
            %SEND_MESSAGE%
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
              <label class='control-label col-md-3 text-right' for='FILTER_ID'>Filter-ID:</label>
              <div class='col-md-9'>
                <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%'
                       class='form-control' type='text'>
              </div>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3 text-right' for='PIN'>PIN:</label>
              <div class='col-md-9'>
                <input id='PIN' name='PIN' value='%PIN%' placeholder='%PIN%' class='form-control'
                       type='text'>
              </div>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3 text-right' for='VOD'>VoD:</label>
              <div class='col-md-9'>
                <input id='VOD' name='VOD' value='1' %VOD% type='checkbox'>
              </div>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3 text-right' for='DVCRYPT_ID'>DvCrypt ID:</label>
              <div class='col-md-9'>
                <input id='DVCRYPT_ID' name='DVCRYPT_ID' value='%DVCRYPT_ID%'
                       placeholder='%DVCRYPT_ID%' class='form-control' type='text'>
              </div>
            </div>

            %IPTV_MODEMS%

            <div class='form-group row'>
              <label class='control-label col-md-3 text-right' for='IPTV_ACTIVATE'>_{ACTIVATE}_:</label>
              <div class='col-md-3'>
                <input id='IPTV_ACTIVATE' name='IPTV_ACTIVATE' value='%IPTV_ACTIVATE%'
                       placeholder='%IPTV_ACTIVATE%' class='datepicker form-control' type='text'>
              </div>
              <label class='control-label col-md-2 text-right' for='IPTV_EXPIRE'>_{EXPIRE}_:</label>
              <div class='col-md-4'>
                <input id='IPTV_EXPIRE' name='IPTV_EXPIRE' value='%IPTV_EXPIRE%'
                       placeholder='%IPTV_EXPIRE%' class='datepicker form-control' type='text'>
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

  </fieldset>

</form>

<script>
  var tp_select = document.getElementById('TP_ID');
  tp_select.textContent = '';
  tp_select.value = '';

  autoReload();

  function autoReload() {
    var service_id = jQuery('#SERVICE_ID').val();
    var uid = jQuery(`[name='UID']`).val();
    jQuery.post('$SELF_URL', 'header=2&get_index=iptv_get_service_tps&SERVICE_ID=' + service_id + '&UID=' + uid, function (data) {
      tp_select.textContent = '';
      tp_select.value = '';
      tp_select.innerHTML = data;
    });
  }
</script>