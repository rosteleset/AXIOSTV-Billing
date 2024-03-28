<style type='text/css'>
	.rules {
		left: 0;
	}

	.social-auth-links > .btn-group {
		width: 100%;
		max-width: 150px;
		margin: 0 5px 5px 5px;
	}

	.social-auth-links > .btn-group > a.btn.btn-social {
		width: 80%;
	}

	.social-auth-links > .btn-group > a.btn.btn-social-unreg {
		width: 20%;
	}

	div#notifications-subscribe-block {
		margin-bottom: 10px;
	}

	#notifications-subscribe-block .card-body a {
	  margin-top: .25rem;
	}

	.balance-buttons a {
	  margin-top: .25rem !important;
	}

	.balance-buttons a.btn-primary {
	  font-weight: bold;
	}
</style>

<div class='modal fade' id='changeCreditModal' data-open='%OPEN_CREDIT_MODAL%'>
  <div class='modal-dialog modal-sm'>
    <form action=%SELF_URL% class='text-center pswd-confirm' id='changeCreditForm'>
      <div class='modal-content'>
        <div class='modal-header'>
          <h4 class='modal-title text-center'>_{SET_CREDIT}_</h4>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'>
            <span aria-hidden='true'>&times;</span>
          </button>
        </div>
        <div class='modal-body'>
          <input type=hidden name='index' value='10'>
          <input type=hidden name='sid' value='$sid'>
          <input type=hidden name='CREDIT_RULE' value='' ID='CREDIT_RULE'>

          <div class='form-group row'>
            <label class='col-md-7'>_{CREDIT_SUM}_: </label>
            <label class='col-md-5'>%CREDIT_SUM% %MONEY_UNIT_NAME%</label>
          </div>

          <div class='form-group row'>
            <label class='col-md-7'>_{CREDIT_PRICE}_:</label>
            <label class='col-md-5' id='CREDIT_CHG_PRICE'>%CREDIT_CHG_PRICE% %MONEY_UNIT_NAME%</label>
          </div>

          <div class='form-group row'>
            <label class='col-md-7' for='change_credit'>_{ACCEPT}_:</label>
            <div class='col-md-5'>
              <input id='change_credit' type='checkbox' required='required' value='%CREDIT_SUM%' name='change_credit'>
            </div>
          </div>
        </div>
        <div class='modal-footer'>
          <input type=submit class='btn btn-primary' value='_{SET}_' name='set'>
        </div>
      </div>
    </form>
  </div>
</div>
<!-- /.modal -->

<div class='modal fade' id='confirmationClientInfo' tabindex='-1' role='dialog'
     data-open='%CONFIRMATION_CLIENT_PHONE_OPEN_INFO%'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      %FORM_CONFIRMATION_CLIENT_PHONE%
    </div>
  </div>
</div>

<div class='modal fade' id='confirmationClientInfo2' tabindex='-1' role='dialog'
     data-open='%CONFIRMATION_EMAIL_OPEN_INFO%'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      %FORM_CONFIRMATION_CLIENT_EMAIL%
    </div>
  </div>
</div>

<div class='modal fade' id='changePersonalInfo' tabindex='-1' role='dialog' data-open='%PINFO%'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      %TEMPLATE_BODY%
    </div>
  </div>
</div>

<div class='modal fade' id='rulesModal' tabindex='-1' role='dialog' aria-labelledby='myModalLabel'>
  <div class='modal-dialog modal-lg' role='document'>
    <div class='modal-content'>
      %ACCEPT_RULES%
    </div>
  </div>
</div>

<div class='row'>
  <div class='col-md-12'>%NEWS%</div>

  <div class='row col-md-12 pr-0'>
    <div class='col-md-8 order-2'>
      <div class='card card-teal card-outline' id='notifications-subscribe-block'>
        <div class='card-header border-0'>
          <h2 class='card-title'>
            _{BOTS}_
          </h2>
        </div>
        <div class='card-body pt-1'>
          %SENDER_SUBSCRIBE_BLOCK%
        </div>
      </div>

      <div class='card card-primary card-outline'>
        <div class='card-header border-0'>
          <h3 class='card-title'> _{INFO}_</h3>
          <div class='card-tools'>
            <button type='button' class='btn btn-success btn-xs %SHOW_ACCEPT_RULES%' data-toggle='modal' data-target='#rulesModal'>
              _{RULES}_
            </button>
            %FORM_CHG_INFO%
          </div>
        </div>
        <div class='card-body p-0'>
          <table class='table table-bordered table-sm'>
            <tr>
              <td class='font-weight-bold text-right'>_{LOGIN}_</td>
              <td>%LOGIN% (UID: %UID%)</td>
            </tr>
            <tr>
              <td class='font-weight-bold text-right'>_{FIO}_</td>
              <td>%FIO%</td>
            </tr>
            <tr>
              <td class='font-weight-bold text-right'>_{PHONE}_</td>
              <td>%PHONE_ALL%</td>
            </tr>
            <tr>
              <td class='font-weight-bold text-right'>_{CELL_PHONE}_</td>
              <td>%CELL_PHONE_ALL%</td>
            </tr>
            <tr>
              <td class='font-weight-bold text-right'>E-mail</td>
              <td>%EMAIL%</td>
            </tr>
            <tr>
              <td class='font-weight-bold text-right'>_{ADDRESS}_</td>
              <td>%ADDRESS_STREET%, %ADDRESS_BUILD%/%ADDRESS_FLAT%</td>
            </tr>
            <tr class='%SHOW_REDUCTION%'>
              <td class='font-weight-bold text-right'>_{REDUCTION}_</td>
              <td>%REDUCTION% %</td>
            </tr>
            <tr class='%SHOW_REDUCTION%'>
              <td class='font-weight-bold text-right'>_{REDUCTION}_ _{DATE}_</td>
              <td>%REDUCTION_DATE%</td>
            </tr>
            <tr>
              <td class='font-weight-bold text-right'>_{CONTRACT}_</td>
              <td>
                <div class='d-flex bd-highlight'>
                  <div class='bd-highlight'>%CONTRACT_ID%%CONTRACT_SUFIX%%NO_CONTRACT_MSG%</div>
                  <div class='ml-auto bd-highlight'>
                    <div class='bd-example' data-visible='%DOCS_VISIBLE%'>
                      <a %NO_DISPLAY% title='_{PRINT}_' target='new' class='p-2'
                         href='%SELF_URL%?qindex=10&PRINT_CONTRACT=%CONTRACT_ID%&sid=$sid&pdf=$conf{DOCS_PDF_PRINT}'>
                        <span class='fas fa-print'></span>
                      </a>

                      <a href='%SELF_URL%?index=10&CONTRACT_LIST=1&sid=$sid' title='_{LIST}_' class='p-2'>
                        <span class='fa fa-list'></span>
                      </a>
                    </div>
                  </div>
                </div>
              </td>
            </tr>
            <tr>
              <td class='font-weight-bold text-right'>_{CONTRACT}_ _{DATE}_</td>
              <td>%CONTRACT_DATE%</td>
            </tr>
            <tr>
              <td class='font-weight-bold text-right'>_{STATUS}_</td>
              <td>%STATUS% %STATUS_CHG_BUTTON%</td>
            </tr>

            %EXT_DATA%
            %INFO_FIELDS_RAWS%

          </table>
        </div>
        <div class='card-footer'>
          %CHANGE_PASSWORD% %AUTH_G2FA%
        </div>
      </div>
    </div>

    <div class='col-md-4 order-md-12 order-1 pr-0'>

      <div id='depositCard' class='card card-danger card-outline'>
        <div class='card-header border-0'>
          <h3 class='card-title'>_{BALANCE}_</h3>
        </div>

        <div class='card-body pt-3 text-center'>
          <div class='deposit-block'>
            <div class='row justify-content-center align-items-baseline'>
		<h1 id='deposit' class='text-danger mb-0'>%DEPOSIT%</h1>
			<h2 class='ml-1 mb-0'>%MONEY_UNIT_NAME%</h2>
				</div>
			<h4>_{DEPOSIT}_</h4>
				</div>
			<div class='card-body text-center'>
			<div class='row justify-content-center align-items-baseline'>
			<h2 id='payment-sum' class='display-5 text-info'>%CREDIT%</h2>
			<h2 class='ml-1 mb-0'>%MONEY_UNIT_NAME%</h2>
				</div>
			<h6>_{TO}_ %CREDIT_DATE%</h6>		  
			<h4>_{CREDIT}_</h4>
		</div>
          <div class='balance-buttons col mt-2 btn-group-vertical' style='width: 100%'>
            %CREDIT_CHG_BUTTON% %DOCS_ACCOUNT% %CARDS_PAYMENTS% %PAYSYS_PAYMENTS%
          </div>
        </div>
      </div>
      <div class='card card-info card-outline'>
        <div class='card-header border-0'>
          <h3 class='card-title'>_{LAST_PAYMENT}_</h3>
        </div>
        <div class='card-body text-center'>
          <div class='row justify-content-center align-items-baseline'>
            <h1 id='payment-sum' class='display-5 text-info'>
              %PAYMENT_SUM%
            </h1>
            <h2 class='ml-1 mb-0'>
              %MONEY_UNIT_NAME%
            </h2>
          </div>
          <div class='credit-block'>
            <h6 class='text'>%PAYMENT_DATE%</h6>
          </div>
        </div>
      </div>

      <div class='card card-orange card-outline' data-visible='%HAS_SOCIAL_BUTTONS%' style='display : none'>
        <div class='card-header border-0'>
          <h3 class='card-title'>_{SOCIAL_NETWORKS}_</h3>
        </div>
        <div class='social-auth-links text-center'>
          %SOCIAL_AUTH_BUTTONS_BLOCK%
        </div>
      </div>

    </div>

  </div>

</div>

<script>
  var UID = '$user->{UID}';
  let show = %SHOW_SUBSCRIBE_BLOCK%;
  if (!show) {
    jQuery('#notifications-subscribe-block').hide();
  }

  let depositBlock = document.getElementById('deposit');
  let depositCard = document.getElementById('depositCard');
  let deposit = parseFloat(depositBlock.innerText);

  if(deposit > 0) {
    depositBlock.classList.add('text-success');
    depositBlock.classList.remove('text-danger');
    depositCard.classList.add('card-success');
    depositCard.classList.remove('card-danger');
  }

  let creditBalanceBlock = document.getElementById('credit');
  let credit = parseFloat(creditBalanceBlock.innerText);
  let to = '_{TO}_'.toLowerCase();

  if(credit > 0) {
    creditBalanceBlock.innerText = `${to} %CREDIT_DATE%`;
  }

  let creditButton = document.getElementById('credit-button');
  if(!creditButton) {
    let creditBigBlock = document.getElementById('credit-block');
    creditBigBlock.classList.add('d-none');
  }

  let paymentSum = document.getElementById('payment-sum');

  if(paymentSum.innerText == "") {
    paymentSum.innerText = "_{PAYMENT_NOTEXIST}_";
  }

  if ('$user->{conf}->{PUSH_ENABLED}' && '$user->{conf}->{PUSH_USER_PORTAL}') {
    let scriptElement = document.createElement('script');
    scriptElement.src = '/styles/default/js/push_subscribe.js';
    document.body.appendChild(scriptElement);
  }
</script>