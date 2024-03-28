<form action='%SELF_URL%' METHOD='POST' ENCTYPE='multipart/form-data' id='CARDS_ADD'>
  <input type='hidden' name='index' value='$index'>
  <div class='row justify-content-center'>
    <section id='left-column' class='col-md-12 col-lg-6' style="min-height: 500px">
      <div class='card card-primary card-outline container-md'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{ICARDS}_: %TYPE_CAPTION%</h4>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='SERIAL'>_{SERIAL}_:</label>
            <div class='col-md-8'>
              <input id='SERIAL' name='SERIAL' value='%SERIAL%' placeholder='_{SERIAL}_' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='BEGIN'>_{BEGIN}_:</label>
            <div class='col-md-8'>
              <input id='BEGIN' name='BEGIN' value='%BEGIN%' placeholder='_{BEGIN}_' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='COUNT'>_{COUNT}_:</label>
            <div class='col-md-8'>
              <input id='COUNT' name='COUNT' value='%COUNT%' placeholder='_{COUNT}_' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-12'><p class='text-center'>_{PASSWD}_ / PIN:</p></label>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='PASSWD_SYMBOLS'>_{SYMBOLS}_:</label>
            <div class='col-md-8'>
              <input id='PASSWD_SYMBOLS' name='PASSWD_SYMBOLS' value='%PASSWD_SYMBOLS%'
                     placeholder='%PASSWD_SYMBOLS%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='PASSWD_LENGTH'>_{SIZE}_:</label>
            <div class='col-md-8'>
              <input id='PASSWD_LENGTH' name='PASSWD_LENGTH' value='%PASSWD_LENGTH%' placeholder='%PASSWD_LENGTH%'
                     class='form-control' type='text'>
            </div>
          </div>

        </div>
        <!-- Card type payment or service -->
        %CARDS_TYPE%
      </div>

      <div class='card card-primary card-outline container-md'>
        <div class='card-body'>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='EXPIRE'>_{EXPIRE}_:</label>
            <div class='col-md-8'>
              <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%'
                     class='form-control datepicker' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='EXPORT'>_{EXPORT}_:</label>
            <div class='col-md-8'>
              <input type='radio' class='form-control-sm' name='EXPORT' value='TEXT' checked> Text<br>
              <input type='radio' class='form-control-sm' name='EXPORT' value='XML'> XML
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='DILLER_ID'>_{DILLERS}_:</label>
            <div class='col-md-8'>
              %DILLERS_SEL%
            </div>
          </div>

        </div>

        <div class='card-footer'>
          <input type='submit' name='create' value='_{CREATE}_' class='btn btn-primary'>
        </div>
      </div>
    </section>

    %EXPARAMS%

  </div>
</form>