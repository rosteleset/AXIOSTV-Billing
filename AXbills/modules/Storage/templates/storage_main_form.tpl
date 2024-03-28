<script language='JavaScript'>
  function autoReload() {
    document.depot_form.type.value = 'prihod';
    document.depot_form.submit();
  }
</script>

<form action='%SELF_URL%' name='depot_form' method=POST class='form-horizontal'>

  <input type=hidden name=index value='%index%'>
  <input type=hidden name=ID value=%ID%>
  <input type=hidden name=INCOMING_ID value=%STORAGE_INCOMING_ID%>
  <input type=hidden name=type value=prihod2>
  <input type=hidden name=add_article value=1>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{ARTICLE}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right'>_{INVOICE_NUMBER}_:</label>
        <div class='col-md-9'>
          <div class='addInvoiceMenu'>

            <div class='d-flex bd-highlight'>
              <div class='flex-fill bd-highlight'>
                <div class='select'>
                  <div class='input-group-append select2-append'>
                    %INVOICE_SELECT%
                  </div>
                </div>
              </div>
              <div class='bd-highlight'>
                <div class='input-group-append h-100'>
                  <a title='_{ADD}_ Invoice' class='btn input-group-button rounded-left-0 BUTTON-ENABLE-ADD'>
                    <span class='fa fa-plus p-1'></span>
                  </a>
                </div>
              </div>
            </div>
          </div>

          <div class='changeInvoiceMenu' style='display : none'>
            <div class='input-group'>
              <input type='text' name='ADD_INVOICE_NUMBER' class='form-control INPUT-ADD-INVOICE'/>
              <div class='input-group-append'>
                <a class='btn input-group-button BUTTON-ENABLE-SEL'>
                  <span class='fa fa-list'></span>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row changeInvoiceMenu' style='display : none'>
        <label class='col-md-3 col-form-label text-md-right'>_{PAYER}_:</label>
        <div class='col-md-9'>
          %PAYERS_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right'>_{TYPE}_:</label>
        <div class='col-md-9'>
          %ARTICLE_TYPES%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right'>_{NAME}_:</label>
        <div class='col-md-9'>
          <div class='ARTICLES_S'>
            %ARTICLE_ID%
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right'>_{SUPPLIERS}_:</label>
        <div class='col-md-9'>%SUPPLIER_ID%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right'>_{DATE}_:</label>
        <div class='col-md-9'>%DATE_TIME_PICKER%</div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right required' for='COUNT'>_{QUANTITY_OF_GOODS}_: </label>
        <div class='col-md-9'>
          <input class='form-control' required id='COUNT' name='COUNT' type='text' value='%COUNT%' %DISABLED%/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right required' for='SUM'>_{SUM_ALL}_: </label>
        <div class='col-md-9'>
          <input class='form-control' required id='SUM' name='SUM' type='number' step='0.01' value='%SUM%' %DISABLED%/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='SELL_PRICE'>_{SELL_PRICE}_ (_{PER_ONE_ITEM}_): </label>
        <div class='col-md-9'>
          <input class='form-control' id='SELL_PRICE' name='SELL_PRICE' type='text' value='%SELL_PRICE%'/>
        </div>
      </div>
      <div class='card card-primary card-outline collapsed-card'>
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
            <label class='col-md-3 col-form-label text-md-right' for='RENT_PRICE'>_{RENT_PRICE}_ (_{MONTH}_): </label>
            <div class='col-md-9'>
              <input class='form-control' id='RENT_PRICE' name='RENT_PRICE' type='text' value='%RENT_PRICE%'/>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 col-form-label text-md-right' for='IN_INSTALLMENTS_PRICE'>_{BY_INSTALLMENTS}_: </label>
            <div class='col-md-9'>
              <input class='form-control' id='IN_INSTALLMENTS_PRICE' name='IN_INSTALLMENTS_PRICE' type='text'
                     value='%IN_INSTALLMENTS_PRICE%'/>
            </div>
          </div>
          <div class='form-group row'>
            <label for='METHOD' class='col-form-label text-md-right col-sm-3'>_{FEES}_ _{TYPE}_:</label>
            <div class='col-md-9'>
              %SEL_METHOD%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 text-md-right' for='ABON_DISTRIBUTION'>_{ABON_DISTRIBUTION}_:</label>
            <div class='col-md-9'>
              <div class='form-check text-left'>
                <input id='ABON_DISTRIBUTION' name='ABON_DISTRIBUTION' value='1' %ABON_DISTRIBUTION% type='checkbox'>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 text-md-right' for='PUBLIC_SALE'>_{AVAILABLE_FOR_PUBLIC_SALE}_:</label>
            <div class='col-md-9'>
              <div class='form-check text-left'>
                <input id='PUBLIC_SALE' name='PUBLIC_SALE' value='1' %PUBLIC_SALE% type='checkbox'>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right'>_{DEPOT_NUM}_: </label>
        <div class='col-md-9'>%STORAGE_STORAGES%</div>
      </div>
      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='SN'>SN: </label>
        <div class='col-md-9'>
          <input class='form-control' name='SN' type='hidden' value='%SN%'/>
          <input class='form-control' id='SN' name='SERIAL' type='%INPUT_TYPE%' value='%SERIAL%'/> %DIVIDE_BTN%
        </div>
      </div>
      <div class='form-group row' %SN_COMMENTS_HIDDEN%>
        <label class='col-md-3 col-form-label text-md-right' for='SN_COMMENTS'>_{NOTES}_: </label>
        <div class='col-md-9'>
          <textarea class='form-control' id='SN_COMMENTS' name='SN_COMMENTS'>%SN_COMMENTS%</textarea>
        </div>
      </div>
      %PROPERTIES%
      <div class='form-group row'>
        <label class='col-md-3 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-9'>
          <textarea class='form-control col-xs-12' id='COMMENTS' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input type=submit id='SUBMIT_FORM_BUTTON' name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
    </div>

  </div>
</form>

<script>
  var timeout = null;
  var start_value = jQuery('#SN').val();

  function doDelayedSearch(val) {
    if (timeout) {
      clearTimeout(timeout);
    }
    timeout = setTimeout(function () {
      doSearch(val); //this is your existing function
    }, 500);
  }

  function doSearch(val) {
    if (!val) {
      jQuery('#SN').parent().parent().removeClass('has-success').addClass('has-error');
      return 1;
    }

    document.getElementById('SUBMIT_FORM_BUTTON').disabled = true;
    jQuery.post('$SELF_URL', 'header=2&qindex=' + '%CHECK_SN_INDEX%' + '&sn_check=' + val, function (data) {
      document.getElementById('SUBMIT_FORM_BUTTON').disabled = false;
      if (data === 'success') {
        jQuery('#SN').parent().parent().removeClass('has-error').addClass('has-success');
        jQuery('#SN').css('border', '3px solid green');
        document.getElementById('SN').setCustomValidity('');
      } else if (val === start_value) {
        jQuery('#SN').parent().parent().removeClass('has-error').addClass('has-success');
        jQuery('#SN').css('border', '3px solid green');
        document.getElementById('SN').setCustomValidity('');
      } else {
        jQuery('#SN').parent().parent().removeClass('has-success').addClass('has-error');
        jQuery('#SN').css('border', '3px solid red');
        document.getElementById('SN').setCustomValidity('_{SERIAL_NUMBER_IS_ALREADY_IN_USE}_');
      }
    });
  }

  jQuery('#SN').on('input', function () {
    var value = jQuery('#SN').val();
    doDelayedSearch(value)
  });

</script>

<script src='/styles/default/js/storage.js'></script>