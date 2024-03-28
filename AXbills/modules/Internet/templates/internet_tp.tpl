<script src='/styles/default/js/copy-paste.js' defer=''></script>
<form action='%SELF_URL%' METHOD='POST'>

  <input type=hidden name='index' value='%index%'>
  <input type=hidden name='TP_ID' value='%TP_ID%'>

  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline box-big-form'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{TARIF_PLAN}_</h4>
          <div class='btn-group float-right'>
            <a title='_{COPY}_' class='btn btn-sm btn-default' id='copy_btn'><span class='fa fa-copy'></span></a>
            <a title='_{PASTE}_' class='btn btn-sm btn-default' id='paste_btn'><span class='fa fa-paste'></span></a>
            %CLONE_BTN%
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='ID'>#</label>
            <div class='col-sm-8 col-md-8'>
              <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label required' for='NAME'>_{NAME}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='GROUP'>_{GROUP}_:</label>
            <div class='col-sm-8 col-md-8'>
              %GROUPS_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='ALERT'>_{UPLIMIT}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input id='ALERT' name='ALERT' value='%ALERT%' placeholder='%ALERT%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='SIMULTANEOUSLY'>_{SIMULTANEOUSLY}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input id='SIMULTANEOUSLY' name='SIMULTANEOUSLY' value='%SIMULTANEOUSLY%' placeholder='%SIMULTANEOUSLY%'
                     class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='COMMENTS'>_{DESCRIBE_FOR_SUBSCRIBER}_:</label>
            <div class='col-sm-8 col-md-8'>
              <textarea cols='40' rows='2' name='COMMENTS' class='form-control' id='COMMENTS'>%COMMENTS%</textarea>
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
            <label class='col-sm-4 col-md-4 text-right' for='POPULAR'>_{POPULAR}_ _{TARIF_PLAN}_:</label>
            <div class='col-sm-8'>
              <div class='form-check text-left'>
                <input type='checkbox' class='form-check-input' id='POPULAR' name='POPULAR' %POPULAR% value='1'>
              </div>
            </div>
          </div>

        </div>
      </div>

      <div class='card  card-primary card-outline box-big-form collapsed-card'>
        <div class='card-header with-border text-center'>
          <h3 class='card-title'>_{EXTRA}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='OCTETS_DIRECTION'>_{OCTETS_DIRECTION}_:</label>
            <div class='col-sm-8 col-md-8'>
              %SEL_OCTETS_DIRECTION%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='ACTIV_PRICE'>_{ACTIVATE}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' type='text' id='ACTIV_PRICE' placeholder='%ACTIV_PRICE%' name='ACTIV_PRICE'
                     value='%ACTIV_PRICE%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='CHANGE_PRICE'>_{CHANGE}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='CHANGE_PRICE' placeholder='%CHANGE_PRICE%' name='CHANGE_PRICE'
                     value='%CHANGE_PRICE%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='CREDIT_TRESSHOLD'>_{CREDIT_TRESSHOLD}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='CREDIT_TRESSHOLD' placeholder='%CREDIT_TRESSHOLD%' name='CREDIT_TRESSHOLD'
                     value='%CREDIT_TRESSHOLD%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='CREDIT'>_{CREDIT}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='CREDIT' placeholder='%CREDIT%' name='CREDIT' value='%CREDIT%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='USER_CREDIT_LIMIT'>_{USER_PORTAL}_ _{CREDIT}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='USER_CREDIT_LIMIT' placeholder='%USER_CREDIT_LIMIT%'
                     name='USER_CREDIT_LIMIT' value='%USER_CREDIT_LIMIT%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='MAX_SESSION_DURATION'>_{MAX_SESSION_DURATION}_
              (sec.):</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='MAX_SESSION_DURATION' placeholder='%MAX_SESSION_DURATION%'
                     name='MAX_SESSION_DURATION' value='%MAX_SESSION_DURATION%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='PAYMENT_TYPE_SEL'>_{PAYMENT_TYPE}_:</label>
            <div class='col-sm-8 col-md-8'>
              %PAYMENT_TYPE_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='MIN_SESSION_COST'>_{MIN_SESSION_COST}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='MIN_SESSION_COST' placeholder='%MIN_SESSION_COST%' name='MIN_SESSION_COST'
                     value='%MIN_SESSION_COST%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='MIN_USE'>_{MIN_USE}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='MIN_USE' placeholder='%MIN_USE%' name='MIN_USE' value='%MIN_USE%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label'
                   for='TRAFFIC_TRANSFER_PERIOD'>_{TRAFFIC_TRANSFER_PERIOD}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='TRAFFIC_TRANSFER_PERIOD' placeholder='%TRAFFIC_TRANSFER_PERIOD%'
                     name='TRAFFIC_TRANSFER_PERIOD' value='%TRAFFIC_TRANSFER_PERIOD%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='PRIORITY'>_{PRIORITY}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='PRIORITY' placeholder='%PRIORITY%' name='PRIORITY' value='%PRIORITY%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='FINE'>_{FINE}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='FINE' placeholder='%FINE%' name='FINE' value='%FINE%'>
            </div>
          </div>

          <div class='form-group row bg-secondary'>
            <label for='AGE' class='control-label col-md-4'>_{AGE}_ (_{DAYS}_):</label>
            <div class='col-md-8'>
              <input class='form-control' id='AGE' placeholder='%AGE%' name='AGE' value='%AGE%'>
            </div>
          </div>

          <div class='form-group row bg-secondary'>
            <label for='NEXT_TARIF_PLAN_SEL' class='control-label col-md-4'>_{TARIF_PLAN}_ _{NEXT_PERIOD}_:</label>
            <div class='col-md-8'>
              %NEXT_TARIF_PLAN_SEL%
            </div>
          </div>
          %FORM_DOMAINS%

          %BONUS%

        </div>
      </div>

      <div class='card  card-primary card-outline box-big-form collapsed-card'>
        <div class='card-header with-border text-center'>
          <h3 class='card-title'>_{FILTERS}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='FILTER_ID'>_{FILTERS}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='FILTER_ID' placeholder='%FILTER_ID%' name='FILTER_ID' value='%FILTER_ID%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='IPPOOL'>IP Pool:</label>
            <div class='col-sm-8 col-md-8'>
              %IP_POOLS_SEL%
            </div>
          </div>

           <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label'
                   for='NEG_DEPOSIT_FILTER_ID'>_{NEG_DEPOSIT_FILTER_ID}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='NEG_DEPOSIT_FILTER_ID' placeholder='%NEG_DEPOSIT_FILTER_ID%'
                     name='NEG_DEPOSIT_FILTER_ID' value='%NEG_DEPOSIT_FILTER_ID%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='NEG_DEPOSIT_IPPOOL_SEL'>_{NEG_DEPOSIT_IP_POOL}_:</label>
            <div class='col-sm-8 col-md-8'>
              %NEG_DEPOSIT_IPPOOL_SEL%
            </div>
          </div>

        </div>
      </div>

      <div class='card  card-primary card-outline box-big-form collapsed-card'>
        <div class='card-header with-border text-center'>
          <h3 class='card-title'>RADIUS</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>

          %RAD_PAIRS_FORM%

        </div>
      </div>

    </div>

    <div class='col-md-6'>
      <div class='card  card-primary card-outline box-big-form'>
        <div class='card-header with-border text-center'>
          <h3 class='card-title'>_{ABON}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-minus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='DAY_FEE'>_{DAY_FEE}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='DAY_FEE' placeholder='%DAY_FEE%' name='DAY_FEE' value='%DAY_FEE%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 text-right' for='ACTIVE_DAY_FEE'>_{ACTIVE_DAY_FEE}_:</label>
            <div class='col-sm-8'>
              <div class='form-check text-left'>
                <input type='checkbox' class='form-check-input' id='ACTIVE_DAY_FEE' name='ACTIVE_DAY_FEE'
                       %ACTIVE_DAY_FEE% value='1'>
              </div>
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
            <label class='col-sm-4 col-md-4 control-label' for='MONTH_FEE'>_{MONTH_FEE}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='MONTH_FEE' placeholder='%MONTH_FEE%' name='MONTH_FEE' value='%MONTH_FEE%'>
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
            <label class='col-sm-4 col-md-4 text-right' for='ACTIVE_MONTH_FEE'>_{ACTIVE_MONTH_FEE}_:</label>
            <div class='col-sm-8'>
              <div class='form-check text-left'>
                <input type='checkbox' class='form-check-input' id='ACTIVE_MONTH_FEE' name='ACTIVE_MONTH_FEE'
                       %ACTIVE_MONTH_FEE% value='1'>
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
            <label class='col-md-4 text-right' for='FIXED_FEES_DAY'>_{FIXED_FEES_DAY}_:</label>
            <div class='col-md-8'>
              <div class='form-check text-left'>
                <input type='checkbox' class='form-check-input' id='FIXED_FEES_DAY' name='FIXED_FEES_DAY'
                       %FIXED_FEES_DAY% value='1' data-input-disables='PERIOD_ALIGNMENT,ABON_DISTRIBUTION'>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='SMALL_DEPOSIT_ACTION'>_{SMALL_DEPOSIT_ACTION}_:</label>
            <div class='col-sm-8 col-md-8'>
              %SMALL_DEPOSIT_ACTION_SEL%
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
            <label class='col-sm-4 col-md-4 control-label' for='METHOD'>_{FEES}_ _{TYPE}_:</label>
            <div class='col-sm-8 col-md-8'>
              %SEL_METHOD%
            </div>
          </div>

          %EXT_BILL_ACCOUNT%

        </div>
      </div>
      <div class='card  card-primary card-outline box-big-form collapsed-card'>
        <div class='card-header with-border text-center'>
          <h3 class='card-title'>_{TIME_LIMIT}_ (sec)</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='DAY_TIME_LIMIT'>_{DAY}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='DAY_TIME_LIMIT' placeholder='%DAY_TIME_LIMIT%' name='DAY_TIME_LIMIT'
                     value='%DAY_TIME_LIMIT%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='WEEK_TIME_LIMIT'>_{WEEK}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='WEEK_TIME_LIMIT' placeholder='%WEEK_TIME_LIMIT%' name='WEEK_TIME_LIMIT'
                     value='%WEEK_TIME_LIMIT%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='MONTH_TIME_LIMIT'>_{MONTH}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='MONTH_TIME_LIMIT' placeholder='%MONTH_TIME_LIMIT%' name='MONTH_TIME_LIMIT'
                     value='%MONTH_TIME_LIMIT%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='TOTAL_TIME_LIMIT'>_{TOTAL}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='TOTAL_TIME_LIMIT' placeholder='%TOTAL_TIME_LIMIT%' name='TOTAL_TIME_LIMIT'
                     value='%TOTAL_TIME_LIMIT%'>
            </div>
          </div>
        </div>
      </div>
      <div class='card  card-primary card-outline box-big-form collapsed-card'>
        <div class='card-header with-border text-center'>
          <h3 class='card-title'>_{TRAF_LIMIT}_ (Mb)</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='DAY_TRAF_LIMIT'>_{DAY}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='DAY_TRAF_LIMIT' placeholder='%DAY_TRAF_LIMIT%' name='DAY_TRAF_LIMIT'
                     value='%DAY_TRAF_LIMIT%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='WEEK_TRAF_LIMIT'>_{WEEK}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='WEEK_TRAF_LIMIT' placeholder='%WEEK_TRAF_LIMIT%' name='WEEK_TRAF_LIMIT'
                     value='%WEEK_TRAF_LIMIT%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='MONTH_TRAF_LIMIT'>_{MONTH}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='MONTH_TRAF_LIMIT' placeholder='%MONTH_TRAF_LIMIT%' name='MONTH_TRAF_LIMIT'
                     value='%MONTH_TRAF_LIMIT%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-sm-4 col-md-4 control-label' for='TOTAL_TRAF_LIMIT'>_{TOTAL}_:</label>
            <div class='col-sm-8 col-md-8'>
              <input class='form-control' id='TOTAL_TRAF_LIMIT' placeholder='%TOTAL_TRAF_LIMIT%' name='TOTAL_TRAF_LIMIT'
                     value='%TOTAL_TRAF_LIMIT%'>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class='row'>
    <div class='col-md-12'>
      <div class='card-footer'>
        <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
      </div>
    </div>
  </div>
  <br>
</form>