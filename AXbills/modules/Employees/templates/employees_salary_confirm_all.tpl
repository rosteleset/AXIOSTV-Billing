<form method='POST'>

  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='AID' value='%AID%'>

  <div class='card card-primary card-outline container-md'>

    <div class='card-header with-border'>_{SALARY}_</div>

    <div class='card-body'>
       %FIO_1%

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{MONTH}_</label>
        <div class='col-md-6'>
          %MONTH%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{YEAR}_</label>
        <div class='col-md-6'>
          %YEAR%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{CASHBOX}_</label>
        <div class='col-md-6'>
          %CASHBOX%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{SPENDING}_ _{TYPE}_</label>
        <div class='col-md-6'>
          %SPENDING_TYPE_ID%
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input type='submit' name='confirm' value='_{ADD}_' class='btn btn-primary'>
    </div>

  </div>

</form>