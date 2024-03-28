<style>
  #plugin_submit {
    margin-left: 25px;
  }

  .draggable-handler {
    cursor: move;
  }

  .plugin {
    background-color: #f0f0f0;
  }

  #plugins_wrapper.reg_wizard .plugin {
    background-color: inherit;
  }

  #plugins_wrapper.reg_wizard .draggable-handler, #plugins_wrapper.reg_wizard .plugin-remove-btn {
    display: none;
  }

  #plugins_wrapper.reg_wizard + #plugins_controls {
    display: none;
  }

</style>

<form action='$SELF_URL' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>

  <div class='form-group'>
    <div class='card card-primary card-outline'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{PLUGINS}_ _{PRIORITY}_</h3>
      </div>
      <div class='card-body' style='display: block;'>
        <div id='plugins_wrapper'></div>
        <div id='plugins_controls'>
          <div class='col-xs-8'>
            <span class='text-success' id='plugins_response'></span>
          </div>
          <div class='col-xs-4 text-right'>
            <div class='btn-group'>
              <button role='button' id='plugin_submit' class='btn btn-xs btn-primary disabled'>
                <span class='fa fa-check'></span>
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</form>

<script>
  var PLUGIN_JSON = JSON.parse('%JSON%');
</script>

<script id='plugin_template' type='x-tmpl-mustache'>

  <div class='form-group plugin' data-id='{{id}}' data-priority='{{priority}}' data-position='{{position}}'>
    <div class='col-xs-1 draggable-handler'>
      <span class='fa fa-ellipsis-v form-control-static'></span>
    </div>
    <label class='control-label col-xs-3'>
      <div>{{name}}</div>
    </label>
    <div class='col-xs-7'>
      <input class='form-control' readonly type='text' {{#form}}form='{{form}}'{{/form}} name='{{type_id}}' {{#value}}value='{{value}}'{{/value}}/>
    </div>
  </div>

</script>

<script src='/styles/default/js/msgs/msgs_plugin.js'></script>
