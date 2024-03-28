<form method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='%INDEX%'/>
  <input type='hidden' name='PAYMENT_SYSTEM' value='%PAYMENT_SYSTEM%'/>
  <input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'/>
  <input type='hidden' name='SUM' value='%SUM%'/>
  <input type='hidden' name='DESCRIBE' value='%DESCRIBE%'/>

  <div class='card card-primary card-outline form-horizontal'>
    <div class='card-header with-border text-center'><h4>Easypay _{CHOOSE_SYSTEM}_</h4></div>
    <div class='card-body'>

      <div class='col-md-12'>
        <div class='col-md-6'>
          <div class='card box-solid box-primary'>
            <div class='card-header with-border text-center'><h4>Easypay</h4></div>
            <div class='card-body'>
              <div class='col-md-12'>
                <img class='img-fluid' src='https://docs.easypay.ua/images/new_images/registration_on_site8.png'
                     alt='Easypay_provider'>
                <p>_{EASYPAY_PROVIDER}_</p>
              </div>
            </div>
            <div class='card-footer'>
              <input class='btn btn-primary' type='submit' name='easypay_provider' value='_{PAY}_'>
            </div>
          </div>
        </div>
        <div class='col-md-6'>
          <div class='card box-solid box-primary'>
            <div class='card-header with-border text-center'><h4>Easypay</h4></div>
            <div class='card-body'>
              <div class='col-md-12'>
                <img class='img-fluid' src='https://docs.easypay.ua/images/new_images/registration_on_site8.png'
                     alt='Easypay_provider'>
                <p>_{EASYPAY_MERCHANT}_</p>
                <br>
              </div>
            </div>
            <div class='card-footer'>
              <input class='btn btn-primary' type='submit' name='easypay_merchant' value='_{PAY}_'>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</form>
