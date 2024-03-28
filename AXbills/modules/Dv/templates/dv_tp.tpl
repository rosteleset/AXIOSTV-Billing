<form action='$SELF_URL' class='form-horizontal' METHOD='POST'>

  <input type=hidden name='index' value='$index'>
  <input type=hidden name='TP_ID' value='%TP_ID%'>
  <div class="row">
    <div class='col-md-6'>
      <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border'><h4 class='card-title'>_{TARIF_PLAN}_</h4></div>
        <div class='card-body'>

          <div class='form-group'>
            <label class='control-label col-md-3' for='ID'>#</label>
            <div class='col-md-9'>
              <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='NAME'>_{NAME}_:</label>
            <div class='col-md-9'>
              <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='GROUP'>_{GROUP}_:</label>
            <div class='col-md-9'>
              %GROUPS_SEL%
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='ALERT'>_{UPLIMIT}_:</label>
            <div class='col-md-9'>
              <input id='ALERT' name='ALERT' value='%ALERT%' placeholder='%ALERT%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <label class='control-label col-md-3' for='SIMULTANEOUSLY'>_{SIMULTANEOUSLY}_:</label>
            <div class='col-md-9'>
              <input id='SIMULTANEOUSLY' name='SIMULTANEOUSLY' value='%SIMULTANEOUSLY%' placeholder='%SIMULTANEOUSLY%'
                     class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group'>
            <div class='form-group'>
              <label class='col-sm-offset-2 col-sm-8'>_{DESCRIBE}_</label>
              <div class='col-sm-offset-2 col-sm-8'>
                <textarea cols='40' rows='4' name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class='col-md-6'>
      <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border text-center'>
          <a data-toggle='collapse' data-parent='#accordion' href='#abon_misc'>_{ABON}_</a>
        </div>
        <div id='abon_misc' class='card-collapse collapse out'>


          <div class='card-body'>

            <div class='form-group'>
              <label for='DAY_FEE' class='control-label col-md-8'>_{DAY_FEE}_:</label>
              <div class='col-md-4'>
                <input class='form-control' id='DAY_FEE' placeholder='%DAY_FEE%' name='DAY_FEE' value='%DAY_FEE%'>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-8' for='ACTIVE_DAY_FEE'>_{ACTIVE_DAY_FEE}_:</label>
              <div class='checkbox float-left'>
                <input style='margin-left:15px;' id='ACTIVE_DAY_FEE' name='ACTIVE_DAY_FEE' value='1' %ACTIVE_DAY_FEE% type='checkbox'>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-8' for='POSTPAID_DAY_FEE'>_{DAY_FEE}_ _{POSTPAID}_:</label>
              <div class='checkbox float-left'>
                <input style='margin-left:15px;' id='POSTPAID_DAY_FEE' name='POSTPAID_DAY_FEE' value=1 %POSTPAID_DAY_FEE% type='checkbox'>
              </div>
            </div>


            <div class='form-group'>
              <label for='MONTH_FEE' class='control-label col-md-8'>_{MONTH_FEE}_:</label>
              <div class='col-md-4'>
                <input class='form-control' id='MONTH_FEE' placeholder='%MONTH_FEE%' name='MONTH_FEE'
                       value='%MONTH_FEE%'>
              </div>
            </div>


            <div class='form-group'>
              <label class='control-label col-md-8' for='POSTPAID_MONTH_FEE'>_{MONTH_FEE}_ _{POSTPAID}_:</label>
              <div class='checkbox float-left'>
                <input style='margin-left:15px;' id='POSTPAID_MONTH_FEE' name='POSTPAID_MONTH_FEE' value='1' %POSTPAID_MONTH_FEE% type='checkbox'>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-8' for='PERIOD_ALIGNMENT'>_{MONTH_ALIGNMENT}_:</label>
              <div class='checkbox float-left'>
                <input style='margin-left:15px;' id='PERIOD_ALIGNMENT' name='PERIOD_ALIGNMENT' value=1 %PERIOD_ALIGNMENT% type='checkbox'>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-8' for='ABON_DISTRIBUTION'>_{ABON_DISTRIBUTION}_:</label>
              <div class='checkbox float-left'>
                <input style='margin-left:15px;' id='ABON_DISTRIBUTION' name='ABON_DISTRIBUTION' value='1' %ABON_DISTRIBUTION%
                       type='checkbox'>
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-8' for='FIXED_FEES_DAY'>_{FIXED_FEES_DAY}_:</label>
              <div class='checkbox float-left'>
                <input style='margin-left:15px;' id='FIXED_FEES_DAY' name='FIXED_FEES_DAY' value=1 %FIXED_FEES_DAY% type='checkbox'>
              </div>
            </div>


            <div class='form-group'>
              <label for='SMALL_DEPOSIT_ACTION' class='control-label col-md-8'>_{SMALL_DEPOSIT_ACTION}_:</label>
              <div class='col-md-4'>
                %SMALL_DEPOSIT_ACTION_SEL%
              </div>
            </div>

            <div class='form-group'>
              <label class='control-label col-md-8' for='REDUCTION_FEE'>_{REDUCTION}_:</label>
              <div class='checkbox float-left'>
                <input style='margin-left:15px;' id='REDUCTION_FEE' name='REDUCTION_FEE' value='1' %REDUCTION_FEE% type='checkbox'>
              </div>
            </div>

            <div class='form-group'>
              <label for='METHOD' class='control-label col-sm-4'>_{FEES}_ _{TYPE}_:</label>
              <div class='col-md-8'>
                %SEL_METHOD%
              </div>
            </div>

            %EXT_BILL_ACCOUNT%

          </div>
        </div>
      </div>
    </div>

    <div class='col-md-6'>
      <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border text-center'>
          <a data-toggle='collapse' data-parent='#accordion' href='#_time_limit'>_{TIME_LIMIT}_ (sec)</a>
        </div>
        <div id='_time_limit' class='card-collapse collapse out'>

          <div class='card-body'>

            <div class='form-group'>
              <label for='DAY_TIME_LIMIT' class='control-label col-md-3'>_{DAY}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='DAY_TIME_LIMIT' placeholder='%DAY_TIME_LIMIT%' name='DAY_TIME_LIMIT'
                       value='%DAY_TIME_LIMIT%'>
              </div>
            </div>

            <div class='form-group'>
              <label for='WEEK_TIME_LIMIT' class='control-label col-md-3'>_{WEEK}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='WEEK_TIME_LIMIT' placeholder='%WEEK_TIME_LIMIT%'
                       name='WEEK_TIME_LIMIT' value='%WEEK_TIME_LIMIT%'>
              </div>
            </div>

            <div class='form-group'>
              <label for='MONTH_TIME_LIMIT' class='control-label col-md-3'>_{MONTH}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='MONTH_TIME_LIMIT' placeholder='%MONTH_TIME_LIMIT%'
                       name='MONTH_TIME_LIMIT' value='%MONTH_TIME_LIMIT%'>
              </div>
            </div>

            <div class='form-group'>
              <label for='TOTAL_TIME_LIMIT' class='control-label col-md-3'>_{TOTAL}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='TOTAL_TIME_LIMIT' placeholder='%TOTAL_TIME_LIMIT%'
                       name='TOTAL_TIME_LIMIT' value='%TOTAL_TIME_LIMIT%'>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class='col-md-6'>
      <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border text-center'>
          <a data-toggle='collapse' data-parent='#accordion' href='#_traf_limit'>_{TRAF_LIMIT}_ (Mb)</a>
        </div>
        <div id='_traf_limit' class='card-collapse collapse out'>

          <div class='card-body'>
            <div class='form-group'>
              <label for='DAY_TRAF_LIMIT' class='control-label col-sm-3'>_{DAY}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='DAY_TRAF_LIMIT' placeholder='%DAY_TRAF_LIMIT%' name='DAY_TRAF_LIMIT'
                       value='%DAY_TRAF_LIMIT%'>
              </div>
            </div>

            <div class='form-group'>
              <label for='WEEK_TRAF_LIMIT' class='control-label col-sm-3'>_{WEEK}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='WEEK_TRAF_LIMIT' placeholder='%WEEK_TRAF_LIMIT%'
                       name='WEEK_TRAF_LIMIT' value='%WEEK_TRAF_LIMIT%'>
              </div>
            </div>

            <div class='form-group'>
              <label for='MONTH_TRAF_LIMIT' class='control-label col-sm-3'>_{MONTH}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='MONTH_TRAF_LIMIT' placeholder='%MONTH_TRAF_LIMIT%'
                       name='MONTH_TRAF_LIMIT' value='%MONTH_TRAF_LIMIT%'>
              </div>
            </div>

            <div class='form-group'>
              <label for='TOTAL_TRAF_LIMIT' class='control-label col-sm-3'>_{TOTAL}_:</label>
              <div class='col-md-9'>
                <input class='form-control' id='TOTAL_TRAF_LIMIT' placeholder='%TOTAL_TRAF_LIMIT%'
                       name='TOTAL_TRAF_LIMIT' value='%TOTAL_TRAF_LIMIT%'>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='col-md-6'>
      <div class='card card-primary card-outline box-form'>
        <div class='card-header with-border text-center'>
          <a data-toggle='collapse' data-parent='#accordion' href='#_other'>_{OTHER}_</a>
        </div>

        <div id='_other' class='card-body box-collapse collapse out'>

          <div class='form-group'>
            <label for='OCTETS_DIRECTION' class='control-label col-sm-3'>_{OCTETS_DIRECTION}_</label>
            <div class='col-md-9'>%SEL_OCTETS_DIRECTION%</div>
          </div>

          <div class='form-group'>
            <label for='ACTIV_PRICE' class='control-label col-sm-3'>_{ACTIVATE}_:</label>
            <div class='col-md-9'>
              <input class='form-control' type='text' id='ACTIV_PRICE' placeholder='%ACTIV_PRICE%'
                     name='ACTIV_PRICE' value='%ACTIV_PRICE%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='CHANGE_PRICE' class='control-label col-sm-3'>_{CHANGE}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='CHANGE_PRICE' placeholder='%CHANGE_PRICE%' name='CHANGE_PRICE'
                     value='%CHANGE_PRICE%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='CREDIT_TRESSHOLD' class='control-label col-sm-3'>_{CREDIT_TRESSHOLD}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='CREDIT_TRESSHOLD' placeholder='%CREDIT_TRESSHOLD%'
                     name='CREDIT_TRESSHOLD' value='%CREDIT_TRESSHOLD%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='CREDIT' class='control-label col-sm-3'>_{CREDIT}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='CREDIT' placeholder='%CREDIT%' name='CREDIT' value='%CREDIT%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='USER_CREDIT_LIMIT' class='control-label col-sm-3'>_{USER_PORTAL}_ _{CREDIT}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='USER_CREDIT_LIMIT' placeholder='%USER_CREDIT_LIMIT%'
                     name='USER_CREDIT_LIMIT' value='%USER_CREDIT_LIMIT%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='MAX_SESSION_DURATION' class='control-label col-sm-3'>_{MAX_SESSION_DURATION}_
              (sec.):</label>
            <div class='col-md-9'>
              <input class='form-control' id='MAX_SESSION_DURATION' placeholder='%MAX_SESSION_DURATION%'
                     name='MAX_SESSION_DURATION' value='%MAX_SESSION_DURATION%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='FILTER_ID' class='control-label col-sm-3'>_{FILTERS}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='FILTER_ID' placeholder='%FILTER_ID%' name='FILTER_ID'
                     value='%FILTER_ID%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='PAYMENT_TYPE_SEL' class='control-label col-sm-3'>_{PAYMENT_TYPE}_:</label>
            <div class='col-md-9'>
              %PAYMENT_TYPE_SEL%
            </div>
          </div>

          <div class='form-group'>
            <label for='MIN_SESSION_COST' class='control-label col-sm-3'>_{MIN_SESSION_COST}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='MIN_SESSION_COST' placeholder='%MIN_SESSION_COST%'
                     name='MIN_SESSION_COST' value='%MIN_SESSION_COST%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='MIN_USE' class='control-label col-sm-3'>_{MIN_USE}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='MIN_USE' placeholder='%MIN_USE%' name='MIN_USE' value='%MIN_USE%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='TRAFFIC_TRANSFER_PERIOD' class='control-label col-sm-3'>_{TRAFFIC_TRANSFER_PERIOD}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='TRAFFIC_TRANSFER_PERIOD' placeholder='%TRAFFIC_TRANSFER_PERIOD%'
                     name='TRAFFIC_TRANSFER_PERIOD' value='%TRAFFIC_TRANSFER_PERIOD%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='NEG_DEPOSIT_FILTER_ID' class='control-label col-sm-3'>_{NEG_DEPOSIT_FILTER_ID}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='NEG_DEPOSIT_FILTER_ID' placeholder='%NEG_DEPOSIT_FILTER_ID%'
                     name='NEG_DEPOSIT_FILTER_ID' value='%NEG_DEPOSIT_FILTER_ID%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='NEG_DEPOSIT_IPPOOL_SEL' class='control-label col-sm-3'>_{NEG_DEPOSIT_IP_POOL}_:</label>
            <div class='col-md-9'>
              %NEG_DEPOSIT_IPPOOL_SEL%
            </div>
          </div>

          <div class='form-group'>
            <label for='IP_POOLS_SEL' class='control-label col-sm-3'>IP Pool:</label>
            <div class='col-md-9'>
              %IP_POOLS_SEL%
            </div>
          </div>

          <div class='form-group'>
            <label for='PRIORITY' class='control-label col-sm-3'>_{PRIORITY}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='PRIORITY' placeholder='%PRIORITY%' name='PRIORITY' value='%PRIORITY%'>
            </div>
          </div>

          <div class='form-group'>
            <label for='FINE' class='control-label col-sm-3'>_{FINE}_:</label>
            <div class='col-md-9'>
              <input class='form-control' id='FINE' placeholder='%FINE%' name='FINE' value='%FINE%'>
            </div>
          </div>

          <div class='form-group bg-info'>
            <label for='AGE' class='control-label col-sm-3'>_{AGE}_ (_{DAYS}_):</label>
            <div class='col-md-9'>
              <input class='form-control' id='AGE' placeholder='%AGE%' name='AGE' value='%AGE%'>
            </div>
          </div>

          <div class='form-group bg-info'>
            <label for='NEXT_TARIF_PLAN_SEL' class='control-label col-sm-3'>_{TARIF_PLAN}_ _{NEXT_PERIOD}_:</label>
            <div class='col-md-9'>
              %NEXT_TARIF_PLAN_SEL%
            </div>
          </div>

          <div class='form-group'>
            <label class='col-sm-offset-2 col-sm-8'>RADIUS Parameters (,)</label>
            <div class='col-sm-offset-2 col-sm-8'>
              <textarea cols='40' rows='4' name='RAD_PAIRS' class='form-control'>%RAD_PAIRS%</textarea>
            </div>
          </div>
          %BONUS%
        </div>

      </div>
    </div>
  </div>

  <div class='row'>
    <div class='card-footer'>
        <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>

</form>

<br/>

