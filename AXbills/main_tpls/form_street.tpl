<form action='%SELF_URL%' METHOD='post' class='form-horizontal'>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='DISTRICT_ID' value='%DISTRICT_ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>_{ADDRESS_STREET}_</div>

    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISTRICTS_SEL'>_{DISTRICTS}_:</label>
        <div class='col-md-8'>
          %DISTRICTS_SEL%
        </div>
      </div>

      <div class='form-group row' data-visible='%STREET_TYPE_VISIBLE%' style='display:none;'>
        <label class='col-md-4 col-form-label text-md-right'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %STREET_TYPE_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SECOND_NAME'>_{SECOND_NAME}_:</label>
        <div class='col-md-8'>
          <input id='SECOND_NAME' name='SECOND_NAME' value='%SECOND_NAME%' class='form-control' type='text'>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>
