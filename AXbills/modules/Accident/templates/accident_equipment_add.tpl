<form METHOD=POST class='form-horizontal container-md' name='accident_for_equipment'>
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='chg' value='%chg%'>
  <input type='hidden' name='add' value='%add%'>
  <input type='hidden' name='id_equipment' value='%id_equipment%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>
        _{ACCIDENT_FOR_EQUIPMENT}_
      </h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-4'>_{NAME}_:</label>
        <div class='col-md-8 col-sm-8'>
          <input type='text' name='NAME' value='%NAME%' class='form-control' readonly>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-4'>_{FROM}_:</label>
        <div class='col-md-8 col-sm-8'>
          <input type='text' class='form-control datepicker' value='%FROM_DATE%' name='FROM_DATE'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-4'>_{TO}_:</label>
        <div class='col-md-8 col-sm-8'>
          <input type='text' class='form-control datepicker' value='%TO_DATE%' name='TO_DATE'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-4'>_{RESPONSIBLE}_:</label>
        <div class='col-md-8 col-sm-8'>
          %RESPONSIBLE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4 col-sm-4'>_{STATUS}_:</label>
        <div class='col-md-8 col-sm-8'>
          %STATUS%
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary float-right' name='BUTTON_ACTION' value='%BUTTON_ACTION%'>
    </div>
  </div>
</form>