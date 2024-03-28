<form class='form-horizontal' method='POST' id='type_add_form'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='ADDITIONAL_FIELDS' id='additional_fields' value='%ADDITIONAL_FIELDS%'>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'><h3 class='card-title'>_{NEW_TYPE}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='row'>
        <div class='col-md-12 col-xs-12'>

          <div class='form-group row'>
            <label class='control-label col-md-4' for='NAME'>_{TASK_TYPE_NAME}_:</label>
            <div class='col-md-8'>
              <input class='form-control' type='text' value='%NAME%' name='NAME' id='NAME'>
            </div>
          </div>
          <hr>
          <div class='form-group row' id='responsible'>
            <input type='hidden' id='RESPONSIBLE_LIST' name='RESPONSIBLE_LIST' value='%RESPONSIBLE_LIST%'>
            <label class='control-label col-md-4'>_{ASSIGNED_ADMINS}_:</label>
            <div class='col-md-8'>
              <button type='button' class='btn btn-default float-left' data-toggle='modal' data-target='#adminsModal'
                      onClick='return openModal()'>_{SELECTED}_: <span class='admin_count'></span></button>
            </div>
          </div>
          <hr>
          <div class='form-group row' id='partcipiants'>
            <input type='hidden' id='PARTCIPIANTS_LIST' name='PARTCIPIANTS_LIST' value='%PARTCIPIANTS_LIST%'>
            <label class='control-label col-md-4'>_{PARTCIPIANTS}_:</label>
            <div class='col-md-8'>
              <button type='button' class='btn btn-default float-left' data-toggle='modal'
                      data-target='#partcipiantsModal'
                      onClick='return openModal()'>_{SELECTED}_: <span class='partcipiants_count'></span></button>
            </div>
          </div>
          <hr>
          <div class='form-group row'>
            <input type='hidden' id='PLUGINS' name='PLUGINS' value='%PLUGINS%'>
            <label class='control-label col-md-4'>_{PLUGINS}_:</label>
            <div class='col-md-8'>
              <button type='button' class='btn btn-default float-left' data-toggle='modal' data-target='#pluginsModal'
                      onClick='return openModal()'>_{SELECTED}_: <span class='plugins_count'></span></button>
            </div>
          </div>
          <hr>
        </div>
        <div class='col-md-12 col-xs-12'>
          <div class='form-group row'>
            <h4>_{ADDITIONAL_FIELDS}_:</h4>
          </div>
          <div id='additional_fields_container'>
          </div>
          <div class='col-md-2 col-xs-2'>
            <a title='add field' class='btn bg-olive margin' id='add_field' href='#'><i class='fa fa-plus'></i></a>
          </div>
        </div>
      </div>

      <!-- Responsible Modal -->
      <div class='modal fade' id='adminsModal' role='dialog'>
        <div class='modal-dialog'>
          <div class='modal-content'>
            <div class='modal-header'>
              <h4 class='modal-title'>_{RESPONSIBLE}_</h4>
              <button type='button' class='close' data-dismiss='modal'>&times;</button>
            </div>
            <div class='modal-body'>
              %ADMINS_LIST%
            </div>
            <div class='modal-footer'>
              <button type='button' class='btn btn-default' data-dismiss='modal' onClick='return closeAdminModal()'>
                _{CLOSE}_
              </button>
            </div>
          </div>
        </div>
      </div>
      <!-- Partcipiants Modal -->
      <div class='modal fade' id='partcipiantsModal' role='dialog'>
        <div class='modal-dialog'>
          <div class='modal-content'>
            <div class='modal-header'>
              <h4 class='modal-title'>_{PARTCIPIANTS}_</h4>
              <button type='button' class='close' data-dismiss='modal'>&times;</button>
            </div>
            <div class='modal-body'>
              %ADMINS_LIST%
            </div>
            <div class='modal-footer'>
              <button type='button' class='btn btn-default' data-dismiss='modal'
                      onClick='return closePartcipiantsModal()'>_{CLOSE}_
              </button>
            </div>
          </div>
        </div>
      </div>
      <!-- Plugins Modal -->
      <div class='modal fade' id='pluginsModal' role='dialog'>
        <div class='modal-dialog'>
          <div class='modal-content'>
            <div class='modal-header'>
              <h4 class='modal-title'>_{PLUGINS}_</h4>
              <button type='button' class='close' data-dismiss='modal'>&times;</button>
            </div>
            <div class='modal-body'>
              %SELECT_PLUGINS%
            </div>
            <div class='modal-footer'>
              <button type='button' class='btn btn-default' data-dismiss='modal' onClick='return closePluginsModal()'>
                _{CLOSE}_
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Invisible element for clone-->
      <div class='form-group row' style='display: none;' id='blank_element'>
        <div class='col-md-2 col-xs-2'>
          <a title='remove field' class='btn btn-default margin del_btn' href='#'>
            <i class='fa fa-minus' style='pointer-events: none;'></i>
          </a>
        </div>
        <label class='control-label col-md-2 col-xs-2 margin'>_{FIELD_TYPE}_:</label>
        <div class='col-md-2 col-xs-2'>
          <input class='form-control field_type margin' type='text'>
        </div>
        <label class='control-label col-md-2 col-xs-2 margin'>_{FIELD_NAME}_:</label>
        <div class='col-md-2 col-xs-2'>
          <input class='form-control field_name margin' type='text'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type=submit name='%BTN_ACTION%' value='%BTN_NAME%' class='btn btn-primary'>
    </div>
  </div>
</form>

<script type='text/javascript'>
  try {
    var arr = JSON.parse('%ADDITIONAL_FIELDS%');
  } catch (err) {
    alert('JSON parse error.');
  }

  jQuery(function () {
    redrawFields();
    setCheckboxes();

    jQuery('#add_field').click(function (event) {
      event.preventDefault();
      jQuery('#blank_element').clone(true)
        .attr('id', 'field')
        .show()
        .appendTo('#additional_fields_container');

      jQuery('.del_btn').click(function (event) {
        event.preventDefault();
        this.closest('.form-group row').remove();
      });
    });

    jQuery('#type_add_form').submit(function (event) {
      var obj = [];
      jQuery('.field_name').each(function (index) {
        if (jQuery(this).val()) {
          obj[index] = {LABEL: jQuery(this).val(), NAME: 'a_field' + (index + 1)};
        }
      });
      jQuery('.field_type').each(function (index) {
        if (jQuery(this).val()) {
          obj[index]['TYPE'] = jQuery(this).val();
        }
      });

      jQuery('#additional_fields').val(JSON.stringify(obj));
    });
  });

  function redrawFields() {
    jQuery.each(arr, function (index, value) {
      var element = jQuery('#blank_element').clone(true)
        .attr('id', 'field')
        .show();

      jQuery(element).find('.field_type').val(value['TYPE']);
      jQuery(element).find('.field_name').val(value['LABEL']);
      element.appendTo('#additional_fields_container');

      jQuery('.del_btn').click(function (event) {
        event.preventDefault();
        this.closest('.form-group row').remove();
      });
    });
  }

  function setCheckboxes() {
    var responsibleList = document.getElementById("RESPONSIBLE_LIST").value;
    var responsibleArr = responsibleList.split(',');
    var count = 0;
    jQuery('#adminsModal .admin_checkbox').each(function () {
      if (responsibleList == '' || responsibleArr.indexOf(jQuery(this).attr("aid")) >= 0) {
        jQuery(this).prop("checked", true);
        count++;
      }
    });
    jQuery('.admin_count').text(count);

    var partcipiantsList = document.getElementById("PARTCIPIANTS_LIST").value;
    var partcipiantsArr = partcipiantsList.split(',');
    count = 0;
    jQuery('#partcipiantsModal .admin_checkbox').each(function () {
      if (partcipiantsArr.indexOf(jQuery(this).attr("aid")) >= 0) {
        jQuery(this).prop("checked", true);
        count++;
      }
    });
    jQuery('.partcipiants_count').text(count);

    var pluginsList = document.getElementById("PLUGINS").value;
    var pluginsArr = pluginsList.split(',');
    count = 0;
    jQuery('.plugin_checkbox').each(function () {
      console.log(this);
      if (pluginsArr.indexOf(jQuery(this).attr("name")) >= 0) {
        jQuery(this).prop("checked", true);
        count++;
      } else {
        jQuery(this).prop("checked", false);
      }
    });
    jQuery('.plugins_count').text(count);
  }

  function closeAdminModal() {
    var responsibleArr = [];
    jQuery('#adminsModal .admin_checkbox').each(function () {
      if (this.checked) {
        responsibleArr.push(jQuery(this).attr("aid"));
      }
    });
    jQuery('.admin_count').text(responsibleArr.length);
    document.getElementById("RESPONSIBLE_LIST").value = responsibleArr.join();
  }

  function closePartcipiantsModal() {
    var partcipiantsArr = [];
    jQuery('#partcipiantsModal .admin_checkbox').each(function () {
      if (this.checked) {
        partcipiantsArr.push(jQuery(this).attr("aid"));
      }
    });
    jQuery('.partcipiants_count').text(partcipiantsArr.length);
    document.getElementById("PARTCIPIANTS_LIST").value = partcipiantsArr.join();
  }

  function closePluginsModal() {
    var pluginsArr = [];
    jQuery('.plugin_checkbox').each(function () {
      if (this.checked) {
        pluginsArr.push(jQuery(this).attr("name"));
      }
    });
    jQuery('.plugins_count').text(pluginsArr.length);
    document.getElementById("PLUGINS").value = pluginsArr.join();
  }

</script>