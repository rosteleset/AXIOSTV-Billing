<div class='card card-outline card-big-form collapsed-card mb-0 border-top'>

  <div class='card-header with-border'>
    <h3 class='card-title'>_{CONTRACT}_</h3>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-plus'></i>
      </button>
    </div>
  </div>

  <div class='card-body'>
    %ACCEPT_RULES_FORM%
    <div class='form-group row'>
      <label class='col-sm-3 col-md-2 control-label' for='CONTRACT_ID'>_{CONTRACT}_ № %CONTRACT_SUFIX%</label>
      <div class='col-sm-9 col-md-10'>
        <div class='input-group'>
          <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%'
              placeholder='%CONTRACT_ID%' class='form-control' type='text'>
          <div class='input-group-append'>
            %PRINT_CONTRACT%
            <a href='$SELF_URL?qindex=15&UID=$FORM{UID}&PRINT_CONTRACT=%CONTRACT_ID%&SEND_EMAIL=1&pdf=1'
              class='btn input-group-button' target=_new>
              <i class='fa fa-envelope'></i>
            </a>
          </div>
        </div>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-sm-3 col-md-2 control-label' for='CONTRACT_DATE'>_{DATE}_</label>
      <div class='col-sm-9 col-md-10'>
        <div class='input-group'>
          <input id='CONTRACT_DATE' type='text' name='CONTRACT_DATE'
              value='%CONTRACT_DATE%' class='datepicker form-control'>
        </div>
      </div>
    </div>

    <div class='form-group'>
      <div class='row'>
        <div class='col-sm-12 col-md-12'>
          %CONTRACT_TYPE%
        </div>
      </div>
    </div>

    %CONTRACTS_TABLE%

  </div>
</div>
