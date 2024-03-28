<form action='$SELF_URL' METHOD='POST' name='user_tp_change' id='user_tp_change'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='sid' value='$FORM{sid}'/>
  <input type='hidden' name='ID' value='$FORM{ID}'/>
  <input type='hidden' name='SHEDULE_ID' value='$FORM{SHEDULE_ID}'/>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{TV}_: %ID%</h4>
      <div class='card-tools float-right'>
        %TP_CHANGE_BTN%
        %DISABLE_BTN%
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body p-0'>
      <table class='table table-bordered table-sm'>
        <tr>
          <td class='text-bold'>_{STATUS}_</td>
          <td>%DISABLE%</td>
        </tr>
        <tr>
          <td class='text-bold'>_{TARIF_PLAN}_</td>
          <td>%TP_NAME%</td>
        </tr>
        <tr>
          <td class='text-bold'>_{DESCRIBE}_</td>
          <td>%COMMENTS%</td>
        </tr>
        %IPTV_EXTRA_FIELDS%
      </table>
      <div class='form-group col-md-12 mt-1'>
        %M3U_LIST%
        %ADDITIONAL_BUTTON%
      </div>
    </div>

    <div id='confirmModal' class='modal fade' role='dialog'>
      <div class='modal-dialog'>
        <div class='modal-content'>
          <div class='modal-header'>
            <button type='button' class='close' data-dismiss='modal'>&times;</button>
            <h4 class='modal-title'>_{DEL}_ _{SHEDULE}_</h4>
          </div>
          <div class='modal-footer'>
            <input type='submit' name='del_shedule_tp' class='btn btn-primary' value='_{DEL}_'
                   title='Ctrl+Enter'/>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class='form-group'>
    %ACTIVE_CODE%
    %WATCH_NOW%
    %CONAX_STATUS%
  </div>
</form>

<script>
  function modal_view() {
    jQuery('.modal').modal('hide');
    jQuery('#confirmModal').modal('show');
  }
</script>

<style>
	.fa-power-off {
		cursor: pointer;
	}
</style>