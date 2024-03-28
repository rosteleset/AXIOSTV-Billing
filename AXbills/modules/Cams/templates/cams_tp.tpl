<form name='CAMS_USER_ADD' id='form_CAMS_USER_ADD' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline card-big-form'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{TARIF_PLAN}_</h4>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-minus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>

          <div class='form-group row'>
            <label for='SERVICE' class='control-label col-md-3'>_{SERVICES}_:</label>
            <div class='col-md-9'>
              %SERVICE_TP%
            </div>
          </div>

          <div class='form-group row'>
            <label for='NAME_id' class='control-label col-md-3 required'>_{NAME}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='NAME_id' required placeholder='%NAME%' name='NAME' value='%NAME%'>
            </div>
          </div>

          <div class='form-group row'>
            <label for='STREAMS_COUNT_id' class='control-label col-md-3 required'>_{MAX}_ _{STREAMS_COUNT}_:</label>
            <div class='col-md-9'>
              <input type='text' class='form-control' required name='STREAMS_COUNT' value='%STREAMS_COUNT%'
                     id='STREAMS_COUNT_id'/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_:</label>
            <div class='col-md-9'>
              <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_id'>%COMMENTS%</textarea>
            </div>
          </div>

        </div>
      </div>
    </div>
    <div class='col-md-6'>
      <div class='card card-primary card-outline card-big-form'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{ABON}_</h4>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-minus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='control-label col-md-3' for='MONTH_FEE'>_{MONTH_FEE}_:</label>
            <div class='col-md-9'>
              <input type=text id='MONTH_FEE' name='MONTH_FEE' value='%MONTH_FEE%' class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3'>_{PAYMENT_TYPE}_:</label>
            <div class='col-md-9'>%PAYMENT_TYPE_SEL%</div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='PERIOD_ALIGNMENT'>_{MONTH_ALIGNMENT}_:</label>
            <div class='col-md-9'>
              <div class='form-check'>
                <input type='checkbox' class='form-check-input' id='PERIOD_ALIGNMENT'
                       name='PERIOD_ALIGNMENT' %PERIOD_ALIGNMENT% value='1'>
              </div>
            </div>
          </div>

        </div>
      </div>
      <div class='card collapsed-card card-primary card-outline box-big-form'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{OTHER}_</h4>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='ACTIV_PRICE'>_{ACTIVATE}_:</label>
            <div class='col-md-9'>
              <input type='number' id='ACTIV_PRICE' name='ACTIV_PRICE' value='%ACTIVATE_PRICE%' class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label' for='CHANGE_PRICE'>_{CHANGE}_:</label>
            <div class='col-md-9'>
              <input type='number' id='CHANGE_PRICE' name='CHANGE_PRICE' value='%CHANGE_PRICE%' class='form-control'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='DVR'>DVR:</label>
            <div class='col-md-9'>
              <div class='form-check'>
                <input type='checkbox' class='form-check-input' id='DVR' name='DVR' %DVR% value='1'>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3' for='PTZ'>PTZ:</label>
            <div class='col-md-9'>
              <div class='form-check'>
                <input type='checkbox' class='form-check-input' id='PTZ' name='PTZ' %PTZ% value='1'>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3'>_{CAMS_ARCHIVE}_:</label>
            <div class='col-md-9'>
              %ARCHIVE_SELECT%
            </div>
          </div>

          <div class='form-group row bg-light'>
            <label for='AGE' class='control-label col-md-3'>_{AGE}_ (_{DAYS}_):</label>
            <div class='col-md-9'>
              <input class='form-control' id='AGE' placeholder='%AGE%' name='AGE' value='%AGE%'>
            </div>
          </div>

          <div class='form-group row bg-light'>
            <label for='NEXT_TARIF_PLAN_SEL' class='control-label col-md-3'>_{TARIF_PLAN}_ _{NEXT_PERIOD}_:</label>
            <div class='col-md-9'>
              %NEXT_TARIF_PLAN_SEL%
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class='card-footer'>
    <input type='submit' form='form_CAMS_USER_ADD' id='go' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</form>