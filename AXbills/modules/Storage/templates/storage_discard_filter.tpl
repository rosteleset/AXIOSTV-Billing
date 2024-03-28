<form action='$SELF_URL' method='GET' class='form-horizontal'>
  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='storage_status' value=5>

  <div class='card card-form card-primary card-outline'>
    <div class='card-header with-border'><h4 class='card-title'>_{SEARCH}_</h4></div>

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
          <div class="ARTICLES_S">
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
        <label class='col-form-label text-md-right col-md-4'>_{DATE}_:</label>
        <div class='col-md-8'>
          %DATE_RANGE_PICKER%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' name='show_discard' value='_{SHOW}_' class='btn btn-primary'>
    </div>
  </div>
</form>

<script src='/styles/default/js/storage.js'></script>