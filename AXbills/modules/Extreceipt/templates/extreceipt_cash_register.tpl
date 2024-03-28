<form name='KKT' id='FORM_KKT' method='post'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='change' value='%ID%'/>

  <div class='card card-primary card-outline container col-md-6'>
    <div class='card-header with-border'><h4 class='card-title'>_{CHANGE_BALANCE}_</h4></div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='SUM'>_{SUM}_:</label>
        <div class='col-md-9'>
          <input type='number' class='form-control' value='%SUM%' name='SUM' id='SUM' title='_{MANAGE_BALANCE}_'/>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>