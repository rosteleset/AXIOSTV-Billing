<form name='CABLECAT_SPLITTER' id='form_CABLECAT_SPLITTER' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{SPLITTER}_:</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' class='form-control'type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='TYPE_ID'>_{SPLITTER_TYPE}_:</label>
        <div class='col-md-8'>
          %TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='WELL_ID'>_{WELL}_:</label>
        <div class='col-md-8'>
          %WELL_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMUTATION_ID'>_{COMMUTATION}_:</label>
        <div class='col-md-8'>
          %COMMUTATION_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='COLOR_SCHEME_ID_SELECT'>_{COLOR_SCHEME}_:</label>
        <div class='col-md-8'>
          %COLOR_SCHEME_ID_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ATTENUATION'>_{ATTENUATION}_:</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' id='ATTENUATION' name='ATTENUATION'
                 value='%ATTENUATION%' pattern='^[0-9]{1,2}(\/[0-9]{1,2}){1,}'/>
        </div>
      </div>

      <hr>

      %INSTALLATIONS_TABLE%

      <div class='%HIDE_STORAGE_FORM%'>
        <div class='form-group row'>
          <label class='col-md-4 control-label'>_{STORAGE}_: </label>
          <div class='col-md-8'>%STORAGE_STORAGES%
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 control-label'>_{TYPE}_:</label>
          <div class='col-md-8'>%ARTICLE_TYPES%</div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 control-label'>_{NAME}_:</label>

          <div class='col-md-8'>
            <div id='ARTICLES_S'>
              %ARTICLE_ID%
            </div>
          </div>
        </div>
        <div class='form-group row'>
          <label class='col-md-4 control-label'>_{COUNT}_:</label>
          <div class='col-md-8'>
            <input class='form-control' name='COUNT' type='text'/>
          </div>
        </div>

      </div>

      %OBJECT_INFO%

    </div>
    <div class='card-footer'>
      <input type='submit' form='form_CABLECAT_SPLITTER' class='btn btn-primary' name='submit'
             value='%SUBMIT_BTN_NAME%'>
    </div>
  </div>
</form>

<script>
  function selectArticles() {
    let articleTypeId = jQuery('#ARTICLE_TYPE_ID').val();
    if (articleTypeId === null) return;

    let storageId = jQuery('#STORAGE_SELECT_ID').val();
    let searchFields = '&ARTICLE_TYPE_ID=' + articleTypeId;
    if (storageId) searchFields += '&STORAGE_ID=' + storageId;

    jQuery.post('/admin/index.cgi', 'header=2&get_index=storage_hardware&quick_info=1' + searchFields, function (result) {
      jQuery('#ARTICLES_S').empty();
      jQuery('#ARTICLES_S').html(result);
      initChosen();
    });
  }

  function selectStorage() {
    jQuery('#ARTICLE_TYPE_ID').change();
  }
</script>