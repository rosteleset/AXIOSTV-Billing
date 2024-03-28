<div class='row'>
  <div class='col-md-6'>
    <form action='$SELF_URL' method='POST' name='CRM_COMPETITORS' id='CRM_COMPETITORS'>
      <input type='hidden' name='index' value='$index'>
      <input type='hidden' name='ID' value='%ID%'>

      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{COMPETITORS}_</h4>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{NAME}_:</label>
            <div class='col-md-8'>
              <input type='text' class='form-control' placeholder='_{NAME}_' name='NAME' id='NAME' value='%NAME%'/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{COMPETITOR_SITE}_:</label>
            <div class='col-md-8'>
              <div class='input-group'>
                <input type='text' class='form-control' placeholder='_{COMPETITOR_SITE}_' name='SITE' id='SITE'
                       value='%SITE%'/>
                <div class='input-group-append %HIDE_SITE%'>
                  <a class='btn input-group-button' href='%SITE%' target='_blank'>
                    <span class='fa fa-globe'></span>
                  </a>
                </div>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{CONNECTION_TYPE}_:</label>
            <div class='col-md-8'>
              <input type='text' class='form-control' placeholder='_{CONNECTION_TYPE}_' name='CONNECTION_TYPE'
                     id='CONNECTION_TYPE' value='%CONNECTION_TYPE%'/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='COLOR'>_{COLOR}_:</label>
            <div class='col-md-8'>
              <input type='color' class='form-control' id='COLOR' name='COLOR' VALUE='%COLOR%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='DESCR'>_{DESCRIBE}_:</label>
            <div class='col-md-8'>
          <textarea class='form-control' id='DESCR' name='DESCR' rows='2'
                    placeholder='%DESCR%'>%DESCR%</textarea>
            </div>
          </div>
        </div>
        <div class='card-footer'>
          <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
        </div>
      </div>
    </form>
  </div>
  <div class='col-md-6'>
    %GEOLOCATION_TREE%
  </div>
</div>

