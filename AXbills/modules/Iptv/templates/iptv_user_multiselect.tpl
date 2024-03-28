<div class='card card-primary card-outline %PARAMS% collapsed-card' form='iptv_users_list'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{MULTIUSER_OP}_</h4>
    <div class='card-tools float-right'>
      <button type='button' id='mu_status_box_btn' class='btn btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-plus'></i>
      </button>
    </div>
  </div>

  <div class='card-body'>

    <div class='form-group'>
      <div class='row'>
        <div class='col-md-4'>
          %MU_STATUS_CHECKBOX%
          <label class='col-form-label text-md-left form-check-label' for='MU_STATUS'>_{STATUS}_</label>
        </div>
        <div class='col-md-8'>
          %MU_STATUS_SELECT%
        </div>
      </div>
    </div>

    <div class='form-group'>
      <div class='row'>
        <div class='col-md-4'>
          %MU_TP_CHECKBOX%
          <label class='col-form-label text-md-left form-check-label' for='MU_TP'>_{TARIF_PLAN}_</label>
        </div>
        <div class='col-md-8'>
          %MU_TP_SELECT%
        </div>
      </div>
    </div>

    <div class='form-group'>
      <div class='row'>
        <div class='col-md-4'>
          <input type='checkbox' name='MU_CREDIT' value='1' form='iptv_users_list' id='MU_CREDIT'>
          <label class='col-form-label text-md-left form-check-label' for='MU_CREDIT'>_{CREDIT}_</label>
        </div>
        <div class=' col-xs-4 col-md-4'>
          <input class='form-control' type='number' name='MU_CREDIT_SUM' form='iptv_users_list'
                 id='MU_CREDIT_SUM' step='0.01'>
        </div>
        <div class='control-label col-md-1 col-xs-1'>
          <label class='control-label' style='padding-top: 5px;'>_{TO}_</label>
        </div>
        <div class='col-md-3 col-xs-3'>
          %MU_CREDIT_DATEPICKER%
        </div>
      </div>
    </div>

    <div class='form-group'>
      <div class='row'>
        <div class='col-md-4'>
          <input type='checkbox' name='MU_REDUCTION' value='1' form='iptv_users_list' id='MU_REDUCTION'>
          <label class='col-form-label text-md-left form-check-label' for='MU_REDUCTION'>_{REDUCTION}_(%)</label>
        </div>
        <div class='col-xs-4 col-md-4'>
          <input id='MU_REDUCTION_SUM' name='MU_REDUCTION_SUM' class='form-control' form='iptv_users_list'
                 type='number' min='0' max='100' value='%MU_REDUCTION_SUM%' step='0.01'>
        </div>
        <label class='control-label col-md-1 col-xs-1' for='MU_REDUCTION_DATE'>_{TO}_</label>
        <div class='col-md-3 col-xs-3'>
          <input id='MU_REDUCTION_DATE' name='MU_REDUCTION_DATE' form='iptv_users_list'
                 class='datepicker form-control' type='text' value='0000-00-00'>
        </div>
      </div>
    </div>

    <div class='form-group d-none %MU_USER_TAGS_VISIBLE%'>
      <div class='row'>
        <div class='col-md-4'>
          <input type='checkbox' name='MU_TAGS_USER' value='1' form='iptv_users_list' id='MU_TAGS_USER'>
          <label class='col-form-label text-md-left form-check-label' for='MU_TAGS_USER'>_{TAGS}_ _{USER}_</label>
        </div>
        <div class='col-md-8'>
          %MU_USER_TAGS%
        </div>
      </div>
    </div>

    <div class='form-group'>
      <div class='row'>
        <div class='col-md-4'>
          <input type='checkbox' name='MU_SERVICE_ACTIVATE' value='1' form='iptv_users_list'
                 id='MU_SERVICE_ACTIVATE'>
          <label class='col-form-label text-md-left form-check-label' for='MU_SERVICE_ACTIVATE'>_{IPTV}_:
            _{ACTIVATE}_</label>
        </div>
        <div class='col-md-8'>
          <input id='MU_SERVICE_ACTIVATE_DATE' name='MU_SERVICE_ACTIVATE_DATE' value='0000-00-00'
                 form='iptv_users_list' class='form-control datepicker' type='text'>
        </div>
      </div>
    </div>

    <div class='form-group'>
      <div class='row'>
        <div class='col-md-4'>
          <input type='checkbox' name='MU_SERVICE_EXPIRE' value='1' form='iptv_users_list' id='MU_SERVICE_EXPIRE'>
          <label class='col-form-label text-md-left form-check-label' for='MU_SERVICE_EXPIRE'>_{IPTV}_:
            _{EXPIRE}_</label>
        </div>
        <div class='col-md-8'>
          <input id='MU_SERVICE_EXPIRE_DATE' name='MU_SERVICE_EXPIRE_DATE' value='0000-00-00'
                 form='iptv_users_list' class='form-control datepicker' type='text'>
        </div>
      </div>
    </div>
  </div>

  <div class='card-footer'>
    <input name='IPTV_MULTIUSER' form='iptv_users_list' value='_{ACCEPT}_' class='btn btn-primary' type='submit'>
  </div>

</div>
</form>