<div class='card card-primary card-outline'>
  <div class='card-header with-border'><h4 class='card-title'>_{OBJECT}_</h4></div>
  <div class='card-body' id='ADD_CUSTOM_POINT_PANEL_BODY'>
    <form action='$SELF_URL' class='form form-horizontal' id='ADD_CUSTOM_POINT_FORM'>
      <input type='hidden' name='COORDX' value='%COORDX%'/>
      <input type='hidden' name='COORDY' value='%COORDY%'/>
      <input type='hidden' name='LAYER_ID' value='6'/>

      <input type='hidden' name='get_index' value='maps_edit'/>
      <input type='hidden' name='header' value='2'/>
      <input type='hidden' name='add' value='1'/>
      <input type='hidden' name='AJAX' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='TYPE_ID'>_{TYPE}_</label>
        <div class='col-md-6' id='TYPE_ID_SELECT_WRAPPER'>
          %TYPE_ID_SELECT%
        </div>
        <div class='col-md-3 btn-group btn-group-sm'>
          <a href='%TYPES_PAGE_HREF%' class='btn btn-sm btn-secondary' target='_blank'>
            <span class='fa fa-list'></span>
          </a>
          <button class='btn btn-sm btn-success' id='ADD_CUSTOM_POINT_REFRESH_BUTTON'>
            <span class='fa fa-refresh'></span>
          </button>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3 required' for='NAME'>_{NAME}_</label>
        <div class='col-md-9'>
          <input class='form-control' name='NAME' id='NAME' required/>
        </div>
      </div>

      <div class='checkbox text-center'>
        <label for='PLANNED'>
          <input type='checkbox' name='PLANNED' id='PLANNED' checked='checked' value='1'/>
          <strong>_{PLANNED}_</strong>
        </label>
      </div>

      <hr>

      <div class='form-group' data-visible='%HAS_CLOSEST%0'>
        <label class='control-label col-md-3' for='CLOSEST_LOCATION_ID'>_{CLOSEST}_ _{BUILDS}_</label>
        <div class='col-md-9'>
          %CLOSEST_SELECT%
        </div>
      </div>

      <div class='form-group'>
        %ADDRESS_SEL%
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='3' name='COMMENTS' id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

    </form>
  </div>

  <div class='card-footer text-right'>
    <input type='submit' class='btn btn-primary' form='ADD_CUSTOM_POINT_FORM' id='ADD_CUSTOM_POINT_SUBMIT' name='action'
           value='_{ADD}_'/>
  </div>
</div>

<script>
  {
    var form       = jQuery('#ADD_CUSTOM_POINT_FORM');

    var type_select_wrapper = form.find('#TYPE_ID_SELECT_WRAPPER');
    var refresh_btn         = form.find('#ADD_CUSTOM_POINT_REFRESH_BUTTON');
    var refresh_btn_icon    = refresh_btn.find('span');

    var name_input = form.find('input#NAME');
    var max_ids = JSON.parse('%LAST_IDS%');

    function getTypeSelect(){
      return type_select_wrapper.find('select#TYPE_ID');
    }

    var update_input_value_according_to_select_value = function(){
      var select = getTypeSelect();
      var type_id = select.val();
      var option = select.find('option[value="' + type_id + '"]');

      if (!option.length) return;
      var option_name = option.text();

      var last_id = max_ids[type_id];
      if (!isDefined(last_id)) last_id = 1;

      jQuery(name_input).val(option_name + '_' + last_id);
    };



    function refresh_types() {
      refresh_btn_icon.addClass('fa-spin');
      var url = '?get_index=_maps_object_types_select&header=2&AJAX=1';

      var current_type = getTypeSelect().val();

      type_select_wrapper.load(url, function () {
        refresh_btn_icon.removeClass('fa-spin');

        current_type
            ? renewChosenValue(getTypeSelect(), current_type)
            : updateChosen();

        bind_type_select_logic();
      });
    }

    function bind_type_select_logic() {
      getTypeSelect().on('change', update_input_value_according_to_select_value);
    }

    // Sending form as AJAX request, to prevent tab reloading
    form.on('submit', function (e) {
      e.preventDefault();
      var formData = form.serialize();

      jQuery('#ADD_CUSTOM_POINT_SUBMIT').addClass('disabled');

      // Save added type, to send it later
      window['LAST_ADDED_OBJECT_TYPE'] = getTypeSelect().val();

      jQuery.post(form.attr('action'), formData, function (data) {
        aModal.updateBody(data);
      });
    });

    refresh_btn.on('click', function (e) {
      cancelEvent(e);
      refresh_types();
    });

    update_input_value_according_to_select_value(getTypeSelect());
    bind_type_select_logic();
  }
</script>