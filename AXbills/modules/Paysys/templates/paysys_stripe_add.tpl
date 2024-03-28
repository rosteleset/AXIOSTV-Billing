<form action='$SELF_URL' method='POST' id='payment-form'>
  <div class='card card-primary card-outline'>
    <input type='hidden' name='OPERATION_ID' value='$FORM{OPERATION_ID}'>
    <input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
    <input type='hidden' name='TP_ID' value='$FORM{TP_ID}'>
    <input type='hidden' name='PHONE' value='$FORM{PHONE}'>
    <input type='hidden' name='DOMAIN_ID' value='$FORM{DOMAIN_ID}'>
    <input type='hidden' name='index' value='$index'>

    <div class='card-header with-border text-center pb-0'>
      <h4>_{BALANCE_RECHARCHE}_</h4>
    </div>
    <div class='card-body pt-0'>
      <div class='text-center'>
        <img src='/styles/default/img/paysys_logo/stripe-logo.png'
             style='width: auto; max-height: 200px;'
             alt='Stripe'>
      </div>

      <ul class='list-group list-group-unbordered mb-3'>
        <li class='list-group-item'>
          <b>_{DESCRIBE}_</b>
          <div class='float-right'>Опис платежу</div>
        </li>
        <li class='list-group-item'>
          <b>_{ORDER}_</b>
          <div class='float-right'>$FORM{OPERATION_ID}</div>
        </li>
        <li class='list-group-item'>
          <b>_{SUM}_</b>
          <div class='float-right'>$FORM{SUM}</div>
        </li>
        %EXTRA_DESCRIPTIONS%
      </ul>
      <input type='submit' class='btn btn-primary float-right' value='_{PAY}_'>

      <script
              src='https://checkout.stripe.com/checkout.js'
              class='stripe-button'
              data-key='$conf{PAYSYS_STRIPE_PUBLISH_KEY}'
              data-description=_{SUM}_$FORM{SUM}
              data-image='/styles/default/img/paysys_logo/stripe-logo.png'
              data-name='$conf{WEB_TITLE}'
              data-locale='auto'
              data-amount='%AMOUNT%'
              data-currency='eur'
      >
      </script>
    </div>
    <script>
      document.getElementsByClassName('stripe-button-el')[0].style.display = 'none';
    </script>
  </div>
</form>

