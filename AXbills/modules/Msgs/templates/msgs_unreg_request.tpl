<form action='$SELF_URL' METHOD='POST' name='reg_request_form' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{REQUESTS}_ %DATE%</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SUBJECT'>_{SUBJECT}_:</label>
        <div class='col-md-8'>
          <input id='SUBJECT' name='SUBJECT' value='_{USER_CONNECTION}_' placeholder='%SUBJECT%'
                 class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea cols='30' rows='4' name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMPANY'>_{COMPANY}_:</label>
        <div class='col-md-8'>
          <input id='COMPANY' name='COMPANY' value='%COMPANY%' placeholder='%COMPANY%'
                 class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='FIO'>_{FIO}_:</label>
        <div class='col-md-8'>
          <input id='FIO' name='FIO' value='%FIO%' placeholder='%FIO%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PHONE'>_{PHONE}_:</label>
        <div class='col-md-8'>
          <input id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='EMAIL'>E-mail:</label>
        <div class='col-md-8'>
          <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control'
                 type='text'>
        </div>
      </div>


      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SUBJECT'>_{CONNECTION_TIME}_:</label>
        <div class='col-md-8'>
          <input id='CONNECTION_TIME' name='CONNECTION_TIME' value='%CONNECTION_TIME%'
                 placeholder='%CONNECTION_TIME%'
                 class='form-control datepicker' type='text'>
        </div>
      </div>

      %ADDRESS_TPL%

      <div class='card card-outline card-default collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{EXTRA}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'><i
                class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>

          <!--- Extra info -->
          %UNREG_EXTRA_INFO%

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='STATE'>_{STATE}_:</label>
            <div class='col-md-8'>
              %STATE_SEL%
            </div>
          </div>

        </div>
      </div>

      <br>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PRIORITY'>_{PRIORITY}_:</label>
        <div class='col-md-8'>
          %PRIORITY_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RESPOSIBLE'>_{RESPOSIBLE}_:</label>
        <div class='col-md-8'>
          %RESPOSIBLE_SEL%
        </div>
      </div>


    </div>
    <div class='card-footer'>

      %BACK_BUTTON% <input type=submit name=%ACTION% value='%LNG_ACTION%' ID='submitbutton'
                           class='btn btn-primary'>
    </div>
  </div>
</form>
