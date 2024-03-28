<form action='$SELF_URL' method='GET' class='form-horizontal'>
  <input type='hidden' name='index' value=$index>

  <div class='card card-form card-primary card-outline'>

    <div class='card-header with-border'><h4 class='card-title'>_{SEARCH}_</h4></div>

    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{TYPE}_:</label>
        <div class='col-md-9'>
          %ARTICLE_TYPES_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{NAME}_:</label>
        <div class='col-md-9'>
          <div class="ARTICLES_S">
            %ARTICLE_ID_SELECT%
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3'>_{RESPOSIBLE}_:</label>
        <div class='col-md-9'>
          %ADMIN_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='SERIAL'>SN:</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' id='SERIAL' name='SERIAL' value='%SERIAL%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3'>_{DATE}_:</label>
        <div class='col-md-9'>
          %DATE_RANGE_PICKER%
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input type='submit' name='show_inner_use' value='_{SHOW}_' class='btn btn-primary'>

    </div>

  </div>

</form>

<script src='/styles/default/js/storage.js'></script>