<form action='$SELF_URL' method='GET' class='form-horizontal'>
  <input type='hidden' name='index' value=$index>
  <div class='card card-form card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SEARCH}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %ARTICLE_TYPES_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{NAME}_:</label>
        <div class='col-md-8'>
          <div class='ARTICLES_S'>
            %ARTICLE_ID_SELECT%
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{ADMIN}_:</label>
        <div class='col-md-8'>
          %ADMIN_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>SN:</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' name='SERIAL' value='%SERIAL%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{DATE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' id='DATE_CHECKBOX' name='DATE_CHECKBOX' class='form-control-static'
                       data-input-enables='FROM_DATE_TO_DATE'/>
              </span>
            </div>
            %DATE_RANGE_PICKER%
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' name='show_reserve' value='_{SHOW}_' class='btn btn-primary'>
    </div>
  </div>
</form>

<script src='/styles/default/js/storage.js'></script>