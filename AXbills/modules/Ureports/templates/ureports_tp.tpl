<div class='d-print-none' id='UREPORTS'>
  <form action='$SELF_URL' METHOD='POST' ID='FORM_UREPORTS'>
    <input type=hidden name='index' value='$index'>
    <input type=hidden name='TP_ID' value='%TP_ID%'>

    <div class='card card-primary card-outline box-form container-md'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{TARIF_PLAN}_ #%ID%</h4>
      </div>

      <div class='card-body'>

        <div class='form-group row'>
          <label class='control-label col-md-2 col-sm-3'>_{NAME}_:</label>
          <div class='col-md-9 col-sm-8'>
            <input type=text name=NAME value='%NAME%' class='form-control'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-2 col-sm-3'>_{MSG_PRICE}_:</label>
          <div class='col-md-9 col-sm-8'>
            <input type=text name=MSG_PRICE value='%MSG_PRICE%' class='form-control'>
          </div>
        </div>

        <div class='card collapsed-card card-primary card-outline'>
          <div class='card-header with-border text-center'>
            <h3 class='card-title'>_{ABON}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>

          <div class='card-body'>

            <div class='form-group row'>
              <label class='control-label col-md-2 col-sm-3'>_{MONTH_FEE}_:</label>
              <div class='col-md-9 col-sm-8'>
                <input type=text name=MONTH_FEE value='%MONTH_FEE%' class='form-control'>
              </div>
            </div>

            <div class="row">
              <div class="form-group custom-control custom-checkbox col-md-6">
                <input class="custom-control-input" type="checkbox" id="POSTPAID_MONTH_FEE"
                       name="POSTPAID_MONTH_FEE"
                       %POSTPAID_MONTH_FEE% value='1'>
                <label for="POSTPAID_MONTH_FEE" class="custom-control-label">_{POSTPAID}_</label>
              </div>

              <div class="form-group custom-control custom-checkbox col-md-6">
                <input class="custom-control-input" type="checkbox" id="REDUCTION_FEE"
                       name="REDUCTION_FEE"
                       %REDUCTION_FEE% value='1'>
                <label for="REDUCTION_FEE" class="custom-control-label">_{REDUCTION}_</label>
              </div>
            </div>

            <!--
            <tr class=even><td>_{MONTH_ALIGNMENT}_:</td><td><input type=checkbox name='PERIOD_ALIGNMENT' value='1' %PERIOD_ALIGNMENT%></td></tr>
            <tr class=even><td>_{ABON_DISTRIBUTION}_:</td><td><input type=checkbox name='ABON_DISTRIBUTION' value='1' %ABON_DISTRIBUTION%></td></tr>
            -->


            <!-- %EXT_BILL_ACCOUNT% -->

          </div>
        </div>

        <div class='card collapsed-card card-primary card-outline'>
          <div class='card-header with-border text-center'>
            <h3 class='card-title'>_{OTHER}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>

          <div class='card-body'>
            <div class='form-group row'>
              <label class='control-label col-md-2 col-sm-3'>_{ACTIVATE}_:</label>
              <div class='col-md-9 col-sm-8'>
                <input type=text name=ACTIV_PRICE value='%ACTIV_PRICE%' class='form-control'>
              </div>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-2 col-sm-3'>_{CHANGE}_:</label>
              <div class='col-md-9 col-sm-8'>
                <input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%' class='form-control'>
              </div>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-2 col-sm-3'>_{CREDIT}_:</label>
              <div class='col-md-9 col-sm-8'>
                <input type=text name=CREDIT value='%CREDIT%' class='form-control'>
              </div>
            </div>

            <!--
              <div class='form-group'>
                  <label class='col-md-3'>_{AGE}_ (_{DAYS}_):</label>
                  <div class='col-md-9'>
                      <input type=text name=AGE value='%AGE%' class='form-control'>
                  </div>
                 </div>

              <div class='form-group'>
                  <label class='col-md-3 control-label'>_{MIN_USE}_:</label>
                  <div class='col-md-9'>
                      <input type=text name=MIN_USE value='%MIN_USE%' class='form-control'>
                  </div>
              </div>
            -->

          </div>
        </div>

      </div>
      <div class='card-footer'>
        <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
      </div>
    </div>

  </form>
</div>
