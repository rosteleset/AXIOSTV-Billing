<form action=$SELF_URL METHOD=POST class='form-horizontal'>
  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='NAS_ID' value=$FORM{NAS_ID}>
  <input type='hidden' name='subf' value=$FORM{subf}>

  <div class='card card-primary card-outline container-sm'>
    <div class='card-header with-border text-center'>
      <h3 class='card-title'>_{STATS}_(%DATE%)</h3>
    </div>
    <div class='card-body'>
      <div class="form-group row">
        <label class='col-md-3 control-label' for='USERS_ONLINE'>Online _{USERS}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input type='text' class='form-control' disabled id='USERS_ONLINE' name='USERS_ONLINE'
                   value='%USERS_ONLINE%'>
          </div>
        </div>
      </div>
      <hr>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='LAST_CONNECT'>_{LAST_LOGIN}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input type='text' class='form-control' disabled id='LAST_CONNECT' name='LAST_CONNECT'
                   value='%LAST_CONNECT%'>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='FIRST_CONNECT'>_{FIRST_LOGIN}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input type='text' class='form-control' disabled id="FIRST_CONNECT" name='FIRST_CONNECT'
                   value='%FIRST_CONNECT%'>
          </div>
        </div>
      </div>
      <hr>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='DATE'>_{DATE}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input type='text' name='DATE' id='DATE' value='%DATE%' class='form-control datepicker'>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='SUC_CONNECTS_PER_DAY'>_{SUCCESS_CONNECTIONS}_ / _{DAY}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input type='text' class='form-control' disabled name='SUC_CONNECTS_PER_DAY'
                   id='SUC_CONNECTS_PER_DAY' value='%SUC_CONNECTS_PER_DAY%'>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='SUC_ATTEMPTS_PER_DAY'>_{SUCCESS_ATTEMPTS}_ / _{DAY}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input type='text' class='form-control' disabled name='SUC_ATTEMPTS_PER_DAY'
                   id='SUC_ATTEMPTS_PER_DAY' value='%SUC_ATTEMPTS_PER_DAY%'>
            <div class="input-group-append">
              <a href='$SELF_URL?index=%FUNC_INDEX%&LOG_TYPE=%LOG_INFO%&DATE=%DATE%&search_form=1&NAS_ID=$FORM{NAS_ID}&FROM_DATE=%DATE%&TO_DATE=%DATE%'
                 class='btn btn-info'>_{SHOW}_</a>
            </div>
          </div>
        </div>
      </div>

      <div class="form-group row">
        <label class='col-md-3 control-label' for='FALSE_ATTEMPTS_PER_DAY'>_{FALSE_ATTEMPTS}_ / _{DAY}_:</label>
        <div class="col-md-9">
          <div class="input-group">
            <input type='text' class='form-control' disabled name='FALSE_ATTEMPTS_PER_DAY'
                   id='FALSE_ATTEMPTS_PER_DAY' value='%FALSE_ATTEMPTS_PER_DAY%'>
            <div class="input-group-append">
              <a href='$SELF_URL?index=%FUNC_INDEX%&LOG_TYPE=%LOG_WARN%&DATE=%DATE%&search_form=1&NAS_ID=$FORM{NAS_ID}&FROM_DATE=%DATE%&TO_DATE=%DATE%'
                 class='btn btn-danger'>_{SHOW}_</a>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <button type='submit' class='btn btn-primary'>_{SHOW}_</button>
    </div>
  </div>

</form>