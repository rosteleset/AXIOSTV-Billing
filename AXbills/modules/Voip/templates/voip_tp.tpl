<form action='%SELF_URL%' METHOD='POST'>
  <input type=hidden name=index value=%index%>
  <input type=hidden name=TP_ID value=%TP_ID%>
  <div class='row'>
    <div class='col-md-6'>

      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{TARIF_PLAN}_</h4>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-minus'></i>
            </button>
          </div>
        </div>

        <div id='_main' class='card-body'>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='ID'>#:</label>
            <div class='col-md-9'>
              <input class='form-control' type=text name=ID ID=ID value='%ID%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='NAME'>_{NAME}_:</label>
            <div class='col-md-9'>
              <input class='form-control' type=text name=NAME id='NAME' value='%NAME%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='ALERT'>_{UPLIMIT}_:</label>
            <div class='col-md-9'>
              <input class='form-control' type=text id=ALERT name=ALERT value='%ALERT%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='SIMULTANEOUSLY'>_{SIMULTANEOUSLY}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='SIMULTANEOUSLY' type=text name=SIMULTANEOUSLY
                     value='%SIMULTANEOUSLY%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for=TIME_TARIF>_{HOUR_TARIF}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='TIME_TARIF' type=text name=TIME_TARIF value='%TIME_TARIF%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label' for='GROUP'>_{GROUP}_:</label>
            <div class='col-md-9'>
              %GROUPS_SEL%
            </div>
          </div>
        </div>
      </div>

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{LIMIT}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div id='_t3' class='card-body'>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='DAY_TIME_LIMIT'>_{DAY}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='DAY_TIME_LIMIT' type=text name=DAY_TIME_LIMIT
                     value='%DAY_TIME_LIMIT%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='WEEK_TIME_LIMIT'>_{WEEK}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='WEEK_TIME_LIMIT' type=text name=WEEK_TIME_LIMIT
                     value='%WEEK_TIME_LIMIT%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='MONTH_TIME_LIMIT'>_{MONTH}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='MONTH_TIME_LIMIT' type=text name=MONTH_TIME_LIMIT
                     value='%MONTH_TIME_LIMIT%'>
            </div>
          </div>
        </div>
      </div>

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{TIME}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div id='_t5' class='card-body'>
          <div class='form-group row'>
            <label class='col-md-3 control-label' FOR='FREE_TIME'>_{FREE_TIME}_:</label>
            <div class='col-md-9'>
              <input class='form-control' type='text' name='FREE_TIME' id='FREE_TIME' value='%FREE_TIME%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='FIRST_PERIOD'>_{FIRST_PERIOD}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='FIRST_PERIOD' type=text name=FIRST_PERIOD
                     value='%FIRST_PERIOD%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='FIRST_PERIOD_STEP'>_{FIRST_PERIOD_STEP}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='FIRST_PERIOD_STEP' type=text name=FIRST_PERIOD_STEP
                     value='%FIRST_PERIOD_STEP%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='NEXT_PERIOD'>_{NEXT_PERIOD}_:</label>
            <div class='col-md-9'>
              <input class='form-control' type=text id='NEXT_PERIOD' name=NEXT_PERIOD
                     value='%NEXT_PERIOD%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='NEXT_PERIOD_STEP'>_{NEXT_PERIOD_STEP}_:</label>
            <div class='col-md-9'>
              <input class='form-control' type=text id='NEXT_PERIOD_STEP' name=NEXT_PERIOD_STEP
                     value='%NEXT_PERIOD_STEP%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='TIME_DIVISION'>_{TIME_DIVISION}_ (_{SECONDS}_
              .):</label>
            <div class='col-md-9'>
              <input class='form-control' type=text id='TIME_DIVISION' name=TIME_DIVISION
                     value='%TIME_DIVISION%'>
            </div>
          </div>
        </div>
      </div>

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{EXTRA_NUMBERS}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div id='_t4' class='card-body'>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='EXTRA_NUMBERS_DAY_FEE'>_{DAY}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='EXTRA_NUMBERS_DAY_FEE' type='text' name=EXTRA_NUMBERS_DAY_FEE
                     value='%EXTRA_NUMBERS_DAY_FEE%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='EXTRA_NUMBERS_MONTH_FEE'>_{MONTH}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='EXTRA_NUMBERS_MONTH_FEE' type='text'
                     name=EXTRA_NUMBERS_MONTH_FEE value='%EXTRA_NUMBERS_MONTH_FEE%'>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{ABON}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-minus'></i>
            </button>
          </div>
        </div>
        <div id='_abon' class='card-body'>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='DAY_FEE'>_{DAY_FEE}_:</label>
            <div class='col-md-9'>
              <input class='form-control' type=text name=DAY_FEE id='DAY_FEE' value='%DAY_FEE%'>
            </div>
          </div>

          <div class='form-group custom-control custom-checkbox'>
            <input class='custom-control-input' type='checkbox' id='POSTPAID_DAY_FEE'
                   name='POSTPAID_DAY_FEE'
                   %POSTPAID_DAY_FEE% value='1'>
            <label for='POSTPAID_DAY_FEE' class='custom-control-label'>_{DAY_FEE}_ _{POSTPAID}_</label>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label' for=MONTH_FEE>_{MONTH_FEE}_:</label>
            <div class='col-md-9'>
              <input class='form-control' type=text name=MONTH_FEE id=MONTH_FEE value='%MONTH_FEE%'>
            </div>
          </div>

          <div class='form-group custom-control custom-checkbox'>
            <input class='custom-control-input' type='checkbox' id='POSTPAID_MONTH_FEE'
                   name='POSTPAID_MONTH_FEE'
                   %POSTPAID_MONTH_FEE% value='1'>
            <label for='POSTPAID_MONTH_FEE' class='custom-control-label'>_{MONTH_FEE}_ _{POSTPAID}_</label>
          </div>

          <div class='form-group row'>
            <label for='METHOD' class='control-label col-md-3'>_{FEES}_ _{TYPE}_:</label>
            <div class='col-md-9'>
              %SEL_METHOD%
            </div>
          </div>
        </div>
      </div>

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{OTHER}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div id='_other' class='card-body'>
          <div class='form-group row'>
            <label class='col-md-3 control-label'
                   for='MAX_SESSION_DURATION'>_{MAX_SESSION_DURATION}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='MAX_SESSION_DURATION' type=text name=MAX_SESSION_DURATION
                     value='%MAX_SESSION_DURATION%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{AGE}_ (_{DAYS}_):</label>
            <div class='col-md-9'>
              <input class='form-control' type=text name=AGE value='%AGE%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{PAYMENT_TYPE}_:</label>
            <div class='col-md-9'>%PAYMENT_TYPE_SEL%</div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='MIN_SESSION_COST'>_{MIN_SESSION_COST}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='MIN_SESSION_COST' type='text' name='MIN_SESSION_COST'
                     value='%MIN_SESSION_COST%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='FILTER_ID'>FILTER_ID:</label>
            <div class='col-md-9'>
              <input class='form-control' type=text id='FILTER_ID' name=FILTER_ID value='%FILTER_ID%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='ACTIV_PRICE'>_{ACTIVATE}_:</label>
            <div class='col-md-9'>
              <input class='form-control' type=text id='ACTIV_PRICE' name=ACTIV_PRICE
                     value='%ACTIV_PRICE%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='CHANGE_PRICE'>_{CHANGE}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='CHANGE_PRICE' type=text name=CHANGE_PRICE
                     value='%CHANGE_PRICE%'>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label' for='CREDIT_TRESSHOLD'>_{CREDIT_TRESSHOLD}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='CREDIT_TRESSHOLD' type=text name=CREDIT_TRESSHOLD
                     value='%CREDIT_TRESSHOLD%'>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class='row'>
    <div class='col-md-12'>
      <div class='card-footer'>
        <input class='btn btn-primary' type=submit name='%ACTION%' value='%LNG_ACTION%'>
      </div>
    </div>
  </div>
</form>
