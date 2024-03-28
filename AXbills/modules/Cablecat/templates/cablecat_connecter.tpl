<div class='row'>
  <div class='%CLASS_FOR_MAIN_FORM%' id='CONNECTER_FORM_CONTAINER_DIV'>
    <div class='card card-primary card-outline'>
      <div class='card-header with-border'><h4 class='card-title'>_{CONNECTER}_</h4></div>
      <div class='card-body'>
        
        <form name='CABLECAT_CONNECTERS' id='form_CABLECAT_CONNECTERS' method='post' class='form form-horizontal'>
          <input type='hidden' name='index' value='$index'/>
          <input type='hidden' name='ID' value='%ID%'/>
          <input type='hidden' name='TYPE_ID' value='2'/>
          <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='NAME_ID'>_{NAME}_:</label>
            <div class='col-md-8'>
              <input type='text' class='form-control' value='%NAME%' name='NAME'
                     id='NAME_ID'/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right required' for='TYPE_ID'>_{CONNECTER_TYPE}_:</label>
            <div class='col-md-8'>
              %CONNECTER_TYPE_ID_SELECT%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right required' for='WELL_ID'>_{WELL}_:</label>
            <div class='col-md-8'>
              %WELL_ID_SELECT%
            </div>
          </div>

          %OBJECT_INFO%

        </form>

      </div>
      <div class='card-footer'>
        <input type='submit' form='form_CABLECAT_CONNECTERS' class='btn btn-primary' name='submit'
               value='%SUBMIT_BTN_NAME%'>
      </div>
    </div>
  </div>

  <div class='col-md-6' data-visible='%HAS_COMMUTATION_FORM%'>
    <div class='card card-primary card-outline'>
      <div class='card-body'>
        %COMMUTATION_FORM%
      </div>
    </div>
  </div>
  <div class='col-md-6' data-visible='%HAS_LINKED%'>
    <div class='card card-primary card-outline'>
      <div class='card-header with-border'><h4 class='card-title'>_{LINKED}_ _{CONNECTERS}_</h4></div>
      <div class='card-body'>
        %LINKED%
      </div>
    </div>
  </div>
</div>

%INFO_DOCS%

<script>
  jQuery(function () {
    /**
     *  Sets up listener to refresh table,
     *  when new commutation has been added
     */
    var table_selector = 'table#CONNECTER_COMMUTATION_TABLE_ID_';
    var table          = jQuery('' + table_selector);
    Events.on('AJAX_SUBMIT.CABLECAT_CREATE_COMMUTATION_FORM', function () {
      table.load(window.location.href + ' ' + table_selector, function () {
        jQuery('input[name="CABLE_IDS"]').prop('checked', false);
      });
    });

    // Auto forming name from type
    jQuery('select#CONNECTER_TYPE_ID').on('change', function () {
      var this_   = jQuery(this);
      var type_id = this_.val();

      if (!type_id) return true;

      var type_name = this_.find('option[value="' + type_id + '"]').text();

      var name_input   = jQuery('input#NAME_ID');
      // Check name already has ID
      var current_name = name_input.val();
      var current_id   = '%NEXT_TYPE_ID%';
      if (current_name) {
        var matches = current_name.match(/_(\\\d+)\$/);
        if (matches[1]) {
          current_id = matches[1];
        }
      }

      name_input.val(type_name + '_' + current_id);
    });

  })
</script>