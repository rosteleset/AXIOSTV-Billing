<form action='%SELF_URL%' METHOD='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='TP_ID' value='%TP_ID%'>
  <div class='container-fluid'>

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
              <label for='SERVICE' class='control-label col-md-4'>_{SERVICES}_:</label>
              <div class='col-md-8'>
                %SERVICE_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label for='ID' class='control-label col-md-4'>#:</label>
              <div class='col-md-8'>
                <input class='form-control' id='ID' placeholder='%ID%' name=CHG_TP_ID value='%ID%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='NAME' class='control-label col-md-4'>_{NAME}_:</label>
              <div class='col-md-8'>
                <input class='form-control' id='NAME' placeholder='%NAME%' name='NAME' value='%NAME%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='ALERT' class='control-label col-md-4'>_{UPLIMIT}_:</label>
              <div class='col-md-8'>
                <input class='form-control' id='ALERT' placeholder='%ALERT%' name='ALERT'
                       value='%ALERT%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='GROUPS_SEL' class='control-label col-md-4'>_{GROUP}_:</label>
              <div class='col-md-8'>
                %GROUPS_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-sm-4 col-md-4 control-label' for='COMMENTS'>_{DESCRIBE_FOR_SUBSCRIBER}_:</label>
              <div class='col-sm-8 col-md-8'>
              <textarea cols='40' rows='2' name='COMMENTS' class='form-control'
                        id='COMMENTS'>%COMMENTS%</textarea>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-sm-4 col-md-4 control-label' for='DESCRIBE_AID'>_{DESCRIBE_FOR_ADMIN}_:</label>
              <div class='col-sm-8 col-md-8'>
              <textarea cols='40' rows='2' name='DESCRIBE_AID' class='form-control'
                        id='DESCRIBE_AID'>%DESCRIBE_AID%</textarea>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-sm-4 col-md-4 text-right' for='STATUS'>_{HIDE_TP}_:</label>
              <div class='col-sm-8'>
                <div class='form-check text-left'>
                  <input type='checkbox' class='form-check-input' id='STATUS' name='STATUS' %STATUS% value='1'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-sm-4 col-md-4 text-right' for='PROMOTIONAL'>_{IPTV_PROMOTIONAL_TP}_:</label>
              <div class='col-sm-8'>
                <div class='form-check text-left'>
                  <input type='checkbox' class='form-check-input' id='PROMOTIONAL' name='PROMOTIONAL' %PROMOTIONAL% value='1'>
                </div>
              </div>
            </div>

          </div>
        </div>
      </div>
      <div class='col-md-6'>
        <div class='card collapsed-card card-primary card-outline box-big-form'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{ABON}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label for='DAY_FEE' class='control-label col-md-4'>_{DAY_FEE}_:</label>
              <div class='col-md-8'>
                <input class='form-control' id='DAY_FEE' placeholder='%DAY_FEE%' name='DAY_FEE'
                       value='%DAY_FEE%'>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-sm-4 col-md-4 text-right' for='POSTPAID_DAY_FEE'>_{DAY_FEE}_ _{POSTPAID}_:</label>
              <div class='col-sm-8'>
                <div class='form-check text-left'>
                  <input type='checkbox' class='form-check-input' id='POSTPAID_DAY_FEE' name='POSTPAID_DAY_FEE'
                         %POSTPAID_DAY_FEE% value='1'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label for='MONTH_FEE' class='control-label col-md-4'>_{MONTH_FEE}_:</label>
              <div class='col-md-8'>
                <input class='form-control' id='MONTH_FEE' placeholder='%MONTH_FEE%' name='MONTH_FEE'
                       value='%MONTH_FEE%'>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-sm-4 col-md-4 text-right' for='POSTPAID_MONTH_FEE'>_{MONTH_FEE}_ _{POSTPAID}_:</label>
              <div class='col-sm-8'>
                <div class='form-check text-left'>
                  <input type='checkbox' class='form-check-input' id='POSTPAID_MONTH_FEE' name='POSTPAID_MONTH_FEE'
                         %POSTPAID_MONTH_FEE% value='1'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-sm-4 col-md-4 text-right' for='PERIOD_ALIGNMENT'>_{MONTH_ALIGNMENT}_:</label>
              <div class='col-sm-8'>
                <div class='form-check text-left'>
                  <input type='checkbox' class='form-check-input' id='PERIOD_ALIGNMENT' name='PERIOD_ALIGNMENT'
                         %PERIOD_ALIGNMENT% value='1' data-input-disables='FIXED_FEES_DAY,ABON_DISTRIBUTION'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-sm-4 col-md-4 text-right' for='ABON_DISTRIBUTION'>_{ABON_DISTRIBUTION}_:</label>
              <div class='col-sm-8'>
                <div class='form-check text-left'>
                  <input type='checkbox' class='form-check-input' id='ABON_DISTRIBUTION' name='ABON_DISTRIBUTION'
                         %ABON_DISTRIBUTION% value='1' data-input-disables='PERIOD_ALIGNMENT,FIXED_FEES_DAY'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-sm-4 col-md-4 text-right' for='REDUCTION_FEE'>_{REDUCTION}_:</label>
              <div class='col-sm-8'>
                <div class='form-check text-left'>
                  <input type='checkbox' class='form-check-input' id='REDUCTION_FEE' name='REDUCTION_FEE'
                         %REDUCTION_FEE% value='1'>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label for='SMALL_DEPOSIT_ACTION_SEL' class='control-label col-md-4'>_{SMALL_DEPOSIT_ACTION}_:</label>
              <div class='col-md-8'>
                %SMALL_DEPOSIT_ACTION_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label for='METHOD' class='control-label col-md-4'>_{FEES}_ _{TYPE}_:</label>
              <div class='col-md-8'>
                %SEL_METHOD%
              </div>
            </div>

            %EXT_BILL_ACCOUNT%

          </div>
        </div>
      </div>
    </div>

    <div class='row'>
      <div class='col-md-6'>
        <div class='card collapsed-card card-primary card-outline'>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{OTHER}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>

            <div class='form-group row'>
              <label for='ACTIV_PRICE' class='control-label col-md-3'>_{ACTIVATE}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='ACTIV_PRICE' placeholder='%ACTIV_PRICE%'
                       name='ACTIV_PRICE' value='%ACTIV_PRICE%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='CHANGE_PRICE' class='control-label col-md-3'>_{CHANGE}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='CHANGE_PRICE' placeholder='%CHANGE_PRICE%'
                       name='CHANGE_PRICE' value='%CHANGE_PRICE%'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='PAYMENT_TYPE_SEL' class='control-label col-md-3'>_{PAYMENT_TYPE}_:</label>
              <div class='col-md-9'>
                %PAYMENT_TYPE_SEL%
              </div>
            </div>

            <div class='form-group row'>
              <label for='CREDIT' class='control-label col-md-3'>_{CREDIT}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='CREDIT' placeholder='%CREDIT%' name='CREDIT'
                       value='%CREDIT%'>
              </div>
            </div>
<!-- START KTK-39 -->
		<div class='form-group row'>
            <label class='control-label col-md-3' for='PRIORITY'>_{PRIORITY}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='PRIORITY' placeholder='%PRIORITY%' name='PRIORITY' value='%PRIORITY%'>
            </div>
          </div>
<!-- END KTK-39 -->
            <div class='form-group row'>
              <label for='FILTER_ID' class='control-label col-md-3'>Filter ID:</label>
              <div class='col-md-9'>
                <input class='form-control' id='FILTER_ID' placeholder='%FILTER_ID%' name='FILTER_ID'
                       value='%FILTER_ID%'>
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
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>