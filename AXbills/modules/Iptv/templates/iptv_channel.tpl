<form action='$SELF_URL' method='post' class='form-horizontal'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name=ID value='$FORM{chg}'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{CHANNELS}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NUM'>_{NUM}_:</label>
        <div class='col-md-8'>
          <input id='NUM' name='NUM' value='%NUM%' placeholder='%NUM%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PORT'>_{PORT}_:</label>
        <div class='col-md-8'>
          <input id='PORT' name='PORT' value='%PORT%' placeholder='%PORT%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='FILTER_ID'>FILTER_ID:</label>
        <div class='col-md-8'>
          <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DISABLE'>_{DISABLE}_:</label>
        <div class='col-md-8'>
          <input id='DISABLE' name='DISABLE' value=1 placeholder='%DISABLE%' type='checkbox' %DISABLE%>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='URL'>URL:</label>
        <div class='col-md-8'>
          <input id='STREAM' name='STREAM' value='%STREAM%' placeholder='%URL%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='GENRE'>_{GENRE}_:</label>
        <div class='col-md-8'>
          %GENRE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='STATE'>_{STATE}_:</label>
        <div class='col-md-8'>
          %STATE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <textarea name=COMMENTS rows=5 class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <input type=submit name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>

