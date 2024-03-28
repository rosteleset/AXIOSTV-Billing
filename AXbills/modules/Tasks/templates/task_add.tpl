<form class='form-horizontal' id='task_add_form'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='%ID%'>
  
    <div class='card card-form  card-primary card-outline box-form'>
      <div class='card-header with-border'><h3 class='card-title'>%BOX_TITLE%</h3>
        <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='card-body' id='task_form_body'>

        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right required' for='task_type'>_{TASK_TYPE}_:</label>
          <div class='col-md-8'>
            %SEL_TASK_TYPE%
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-4 col-form-label  text-md-right required' for='NAME'>_{TASK_NAME}_:</label>
          <div class='col-md-8'>
            <input class='form-control' name='NAME' id='NAME' value='%NAME%' required>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right required' for='DESCR'>_{TASK_DESCRIBE}_:</label>
          <div class='col-md-8'>
            <textarea class='form-control' rows='5' name='DESCR' id='DESCR'>%DESCR%</textarea>
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right required' for='responsible'>_{RESPONSIBLE}_:</label>
          <div class='col-md-8'>  
            %SEL_RESPONSIBLE%
          </div>
        </div>

        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='responsible'>_{PARTCIPIANTS}_:</label>
          <div class='col-md-8'>
            <input type='hidden' id='PARTCIPIANTS_LIST' name='PARTCIPIANTS_LIST' value='%PARTCIPIANTS_LIST%'>
            <button type='button' class='btn btn-primary float-left' data-toggle='modal' data-target='#myModal'
                    onClick='return openModal()'>_{SELECTED}_: <span class='admin_count'></span></button>
          </div>
        </div>
                   <!-- Modal -->
        <div class='modal fade' id='myModal' role='dialog'>
          <div class='modal-dialog'>
          
            <!-- Modal content-->
            <div class='modal-content'>
              <div class='modal-header'>
                <h4 class='modal-title'>_{PARTCIPIANTS}_</h4>
                <button type='button' class='close' data-dismiss='modal'>&times;</button>
              </div>
              <div class='modal-body'>
               %ADMINS_LIST%
              </div>
              <div class='modal-footer'>
                <button type='button' class='btn btn-default' data-dismiss='modal' onClick='return closeModal()'>_{CLOSE}_</button>
              </div>
            </div>
            
          </div>
        </div>
       <div class='col-md-12'>&nbsp;</div>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='CONTROL_DATE'>_{DUE_DATE}_:</label>
          <div class='col-md-8'>
            <input type='text' class='datepicker form-control' value='%CONTROL_DATE%' name='CONTROL_DATE' id='CONTROL_DATE'>
          </div>
        </div>

        %PLUGINS_FIELDS%

      </div>
      <div class='card-footer'>
        <input type=submit name='%BTN_ACTION%' value='%BTN_NAME%' class='btn btn-primary'>
      </div>  
    </div>
 
</form>

<script type="text/javascript">
  try {
    var arr = JSON.parse('%JSON_LIST%');
    var adminsArr = JSON.parse('%JSON_ADMINS%');
    var partcipiantsArr = JSON.parse('%JSON_PARTCIPIANTS%');
    var pluginsArr = JSON.parse('%JSON_PLUGINS_FIELDS%');
  }
  catch (err) {
    alert('JSON parse PROBLEM.');
  }
    var oldresponsible = '%RESPONSIBLE%';

  function rebuild_form(type_num) {
    jQuery('.appended_field').remove();
    jQuery('.plugin_field').remove();

    document.getElementById("PARTCIPIANTS_LIST").value = partcipiantsArr[type_num];
    setCheckboxes();

    var adminsList = adminsArr[type_num].split(',');
    jQuery('#RESPONSIBLE option').each(function() {
      var aid = jQuery(this).attr("value");
      if (aid == 0) {
        jQuery(this).hide();
      }
      else if (adminsList.indexOf(aid) >= 0 || adminsList == '') {
        jQuery(this).show();
      }
      else {
        jQuery(this).hide();
      }
    });

    var selected = adminsList[0] || 1;
    
    if (oldresponsible && adminsList.indexOf(oldresponsible) >= 0) {
      selected = oldresponsible;
    }
    jQuery("#RESPONSIBLE").val(selected).trigger("change");

    // additional fields
    jQuery.each(arr[type_num], function(field, element) {
      jQuery('#task_form_body')
        .append(
          jQuery('<div></div>')
            .addClass('form-group appended_field row')
            .append(
              jQuery('<label></label>')
                .attr('for', element['NAME'])
                .text(element['LABEL'])
                .addClass('control-label col-md-4')
            )
            .append(
              jQuery("<div></div>")
                .addClass("col-md-8")
                .append(
                  jQuery("<input />")
                    .attr('name', element['NAME'])
                    .attr('id', element['NAME'])
                    .attr('type', element['TYPE'])
                    .addClass('form-control')
                )
            )
      );
    });

    // plugin fields
    jQuery.each(pluginsArr[type_num], function(field, element) {
      jQuery('#task_form_body')
        .append(
          jQuery('<div></div>')
            .addClass('form-group plugin_field row   ')
            .append(
              jQuery('<label></label>')
                .attr('for', element['NAME'])
                .text(element['LABEL'])
                .addClass('control-label col-md-4')
            )
            .append(
              jQuery("<div></div>")
                .addClass("col-md-8")
                .append(
                  jQuery("<input />")
                    .attr('name', element['NAME'])
                    .attr('id', element['NAME'])
                    .val(element['VALUE'])
                    .addClass('form-control')
                )
            )
      );
    });

  };

  function closeModal() {
    var partcipiantsArr = [];
    jQuery( '.admin_checkbox' ).each(function() {
      if (this.checked) {
        partcipiantsArr.push(jQuery(this).attr("aid"));
      }
    });
    jQuery( '.admin_count' ).text(partcipiantsArr.length);
    document.getElementById("PARTCIPIANTS_LIST").value = partcipiantsArr.join();
  }

  function setCheckboxes() {
    var partcipiantsList = document.getElementById("PARTCIPIANTS_LIST").value;
    var partcipiantsArr = partcipiantsList.split(',');
    var count = 0;
    jQuery( '.admin_checkbox' ).each(function() {
      if ( partcipiantsArr.indexOf(jQuery(this).attr("aid")) >= 0 ) {
        jQuery(this).prop("checked", true);
        count++;
      }
      else {
        jQuery(this).prop("checked", false);
      }
    });
    jQuery( '.admin_count' ).text(count);
  }

  jQuery(function() {
    rebuild_form(jQuery( '#TASK_TYPE' ).val());

    jQuery( '#TASK_TYPE' ).change(function() {
      rebuild_form(jQuery( '#TASK_TYPE' ).val());
    });

    jQuery( '#task_add_form' ).submit(function( event ) {
      if (jQuery( '#CONTROL_DATE' ).val() === '') {
        alert( 'Укажите дату.' );
        event.preventDefault();
      }
      else if (jQuery( '#DESCR' ).val() === '') {
        alert( 'Введите описание задачи.' );
        event.preventDefault();
      }
      else if (jQuery( '#RESPONSIBLE' ).val() === '') {
        alert( 'Укажите ответственного.' );
        event.preventDefault();
      }
    });
  });
</script>
