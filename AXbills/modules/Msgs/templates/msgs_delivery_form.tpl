<div class='card collapsed-card %PARAMS%'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{DELIVERY}_</h4>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-plus'></i>
      </button>
    </div>
  </div>
  <div id='delivery' class='card-body'>

    <div class='form-group row' id='delivery_list'>
      <label class='control-label col-md-3' for='DELIVERY_CREATE'>_{DELIVERY}_:</label>
      <div class='col-md-9 '>
        <div class='d-flex'>
          <span class='input-group-prepend input-group-text rounded-right-0 %DELIVERY_ADD_HIDE%'>_{ADD}_
            <input id='DELIVERY_CREATE' name='DELIVERY_CREATE' value='1' onClick='add_delivery();'
              title='_{CREATE}_ _{DELIVERY}_' type='checkbox' aria-label='Checkbox'>
          </span>
          %DELIVERY_SELECT_FORM%
        </div>
      </div>
    </div>

    <div class='form-group' id='new_delivery' style='display: none;'>
      <div class='form-group row'>
        <label class='control-label col-md-2' for='DELIVERY_SEND_TIME'>_{SEND_TIME}_:</label>
        <div class='col-md-5'>
          <div class='input-group'>
            %DATE_PIKER%
          </div>
        </div>
        <div class='col-md-5'>
          <div class='input-group'>
            %TIME_PIKER%
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-2' for='STATUS'>_{STATUS}_:</label>
        <div class='col-sm-12 col-md-10'>
          <div class='input-group'>
            %STATUS_SELECT%
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-2' for='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-sm-12 col-md-10'>
          <div class='input-group'>
            %PRIORITY_SELECT%
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-2' for='SEND_METHOD'>_{SEND}_:</label>
        <div class='col-sm-12 col-md-10'>
          <div class='input-group'>
            %SEND_METHOD_SELECT%
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
