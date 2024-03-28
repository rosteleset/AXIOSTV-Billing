<form name='CABLECAT_CABLE' id='form_CABLECAT_CABLE' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='LENGTH_CALCULATED' value='%LENGTH_CALCULATED%'/>
  <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{CABLE}_:</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME_id'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' required name='NAME' value='%NAME%' id='NAME_id' autocomplete="off"/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='TYPE_ID'>_{CABLE_TYPE}_:</label>
        <div class='col-md-8'>
          %CABLE_TYPE_SELECT%
        </div>
      </div>

      <hr>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{WELL}_ 1:</label>
        <div class='col-md-8'>
          %WELL_1_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{WELL}_ 2:</label>
        <div class='col-md-8'>
          %WELL_2_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LENGTH_F_id'>_{LENGTH}_, _{METERS_SHORT}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='text' class='form-control' name='LENGTH' value='%LENGTH%' id='LENGTH_F_id'/>
            <div class='input-group-append' data-tooltip='_{CALCULATED}_'>
              <button type='button' class='btn btn-default' id='COPY_LENGTH_CALCULATED'>
                <span class='fa fa-arrow-left'></span>
                %LENGTH_CALCULATED%
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='RESERVE_id'>_{RESERVE}_, _{METERS_SHORT}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='RESERVE' value='%RESERVE%' id='RESERVE_id'/>
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

      <hr>
      %OBJECT_INFO%


    </div>
    <div class='card-footer'>
      <input type='submit' form='form_CABLECAT_CABLE' id='go' class='btn btn-primary' name='submit'
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
      jQuery("#ARTICLES_S").empty();
      jQuery("#ARTICLES_S").html(result);
      initChosen();
    });
  }

  function selectStorage() {
    jQuery('#ARTICLE_TYPE_ID').change();
  }
  jQuery(function () {


    jQuery('button#COPY_LENGTH_CALCULATED').on('click', function () {
      jQuery('input#LENGTH_F_id').val('%LENGTH_CALCULATED%');
    });

    function get_well_name(well_select, callback) {
      var well_id = well_select.val();
      var well_name = well_select.find('option[value="' + well_id + '"]').text();

      if (well_name) {
        callback(well_name);
      } else {
        return '';
//        jQuery.getJSON('?get_index=cablecat_wells&header=2&chg=' + well_id + '&json=1&TEMPLATE_ONLY=1', function(response){
//          if (response && response.NAME){
//            callback(response.NAME);
//          }
//        });
      }
    }

    function update_cable_name(well_1_name, well_2_name) {
      jQuery('input#NAME_id').val(well_1_name + '-' + well_2_name);
    }

    function on_well_changed() {
      get_well_name(jQuery('select#WELL_1'), function (well_1_name) {
        get_well_name(jQuery('select#WELL_2'), function (well_2_name) {
          update_cable_name(well_1_name, well_2_name);
        });
      })
    }

    jQuery('select#WELL_1').on('change', on_well_changed);
    jQuery('select#WELL_2').on('change', on_well_changed);

  });


</script>

