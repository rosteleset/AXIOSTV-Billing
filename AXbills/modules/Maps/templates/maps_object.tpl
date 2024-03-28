<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{OBJECT}_</h4></div>
  <div class='card-body'>

    <form name='MAPS_OBJECT' id='form_MAPS_OBJECT' method='post' action='$SELF_URL' class='form form-horizontal %FORM_SUBMIT%'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='TYPE_ID_SELECT'>_{TYPE}_</label>
        <div class='col-md-9'>
          %TYPE_ID_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PLANNED_id'>_{INSTALLED}_</label>
        <div class='col-md-9'>
          %PLANNED_SELECT%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PARENT_ID_id'>_{PARENT_M}_ _{OBJECT}_</label>
        <div class='col-md-9'>
          %PARENT_ID_SELECT%
        </div>
      </div>
      
      <div class='form-group text-left'>
        <label class='form-control-label col-md-3'>_{OBJECTS}_</label>
        <div class='col-md-9'>
          %CHILDREN_LINKS%
        </div>
      </div>

      <hr>

      <div class='form-group' data-visible='%SHOW_MAP_BTN%'>
        <label class='form-control-label col-md-3'>_{MAP}_</label>
        <div class='col-md-9'>%MAP_BTN%</div>
      </div>

      <div class='form-group'>
        %ADDRESS_SEL%
      </div>

      <hr>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_id'>%COMMENTS%</textarea>
        </div>
      </div>

    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_MAPS_OBJECT' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>

<script>
  jQuery(function () {

    var select     = jQuery('select#TYPE_ID');
    var name_input = jQuery('input#NAME_id');
    var max_ids = JSON.parse('%LAST_IDS%');

    var update_input_value_according_to_select_value = function () {
      if (jQuery(name_input).val()) return true;

      var type_id = select.val();
      var option  = select.find('option[value='' + type_id + '']');

      if (!option.length) return;
      var option_name = option.text();

      var last_id = max_ids[type_id];
      if (!isDefined(last_id)) last_id = 1;

      jQuery(name_input).val(option_name + '_' + last_id);
    };

    function bind_type_select_logic() {
      select.on('change', update_input_value_according_to_select_value);
    }

    bind_type_select_logic();

  });
</script>

<!--<script src='/styles/default_adm/js/jquery.marcopolo.min.js'></script>-->
<!--<script src='/styles/default_adm/js/modules/maps_objects_live_search.js'></script>-->

