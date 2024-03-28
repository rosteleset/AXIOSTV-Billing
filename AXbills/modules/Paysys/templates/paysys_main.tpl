<form method='POST' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='sid' value='$sid'>
  <input type='hidden' name='IDENTIFIER' value='%IDENTIFIER%'>
  <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border text-center'>
      <h4 class='card-title'>_{BALANCE_RECHARCHE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label for='transaction' class='col-sm-2 col-md-2 col-form-label'>_{TRANSACTION}_ #:</label>
        <div class='col-sm-10 col-md-10'>
          <input type='text' class='form-control' id='transaction' placeholder='_{TRANSACTION}_ #' readonly
                 value='%OPERATION_ID%'>
        </div>
      </div>

      <div class='form-group row'>
        <label for='sum' class='col-sm-2 col-md-2 col-form-label'>_{SUM}_:</label>
        <div class='col-sm-10 col-md-10'>
          <input class='form-control' type='number' min='0' step='0.01' id='sum' name='SUM' value='%SUM%' autofocus>
        </div>
      </div>

      <div class='form-group row'>
        <label for='describe' class='col-sm-2 col-md-2 col-form-label'>_{DESCRIBE}_:</label>
        <div class='col-sm-10 col-md-10'>
          <input class='form-control' type='text' id='describe' name='DESCRIBE' placeholder='_{DESCRIBE}_'
                 value='_{BALANCE_RECHARCHE}_'>
        </div>
        <label class='col-sm-3 col-md-3 mt-4 col-form-label'>_{CHOOSE_SYSTEM}_:</label>
      </div>

      <div class='form-group'>
        <div id='GooglePay'></div>
      </div>

      <div class='form-group'>
        <apple-pay-button buttonstyle='black' onclick='onApplePayButtonClicked()'  type='pay'></apple-pay-button>
      </div>

      <div class='form-group text-center'>
        %IPAY_HTML%
      </div>

      <div class='form-group row d-flex justify-content-center'>
        %PAY_SYSTEM_SEL%
      </div>
    </div>

    <div class='modal fade' id='modal' role='dialog'>
      <div class='modal-dialog'>
        <div class='modal-content'>
          <div class='modal-header'>
            <h4 class='modal-title'>_{PAYMENT_MADE}_</h4>
            <button type='button' class='close' data-dismiss='modal'>&times;</button>
          </div>

          <div class='modal-body'>
            <ul class='list-group list-group-unbordered mb-3'>
              <li class='list-group-item'>
                <b>_{BALANCE_RECHARCHE_SUM}_</b>
                <div class='float-right' id='sum-info'></div>
              </li>
              <li class='list-group-item'>
                <b>_{TRANSACTION}_ #:</b>
                <div class='float-right' id='transaction-info'></div>
              </li>
            </ul>
          </div>

          <div class='modal-footer'>
            <button type='button' class='btn btn-primary' data-dismiss='modal'>_{CLOSE}_</button>
          </div>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input class='btn btn-primary float-right' type='submit' name=pre value='_{NEXT}_'>
    </div>
  </div>
</form>

<style>
    input[type='radio']:checked + label {
        transform: scale(1.01, 1.01);
        box-shadow: 4px 4px 2px #AAAAAA;
        z-index: 100;
    }

    input[type='radio']:hover + label {
        transform: scale(1.05, 1.05);
        box-shadow: 5px 5px 3px #AAAAAA;
        z-index: 101;
    }

    label {
        border-radius: 5px;
    }

    .logo-container {
        max-width: 12rem;
    }
</style>

<script>
  let height_element = 240;
  jQuery('.logo-container').each(function (elem, val) {
    if (val.scrollHeight > height_element) {
      height_element = val.scrollHeight;
    }
  }).css('height', height_element);

  // from paysys_check
  if ('%index%' === '0') {
    const type = performance.getEntriesByType("navigation")[0]?.type;

    window.addEventListener('pageshow', function (event) {
      var historyTraversal = event.persisted ||
              (type && type === 'back_forward');
      if (historyTraversal) {
        window.location.reload();
      }
    });
  }
</script>

%MAP%
