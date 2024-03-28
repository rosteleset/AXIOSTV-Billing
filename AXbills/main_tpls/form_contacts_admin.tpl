<style>
  .draggable-handler {
    cursor: move;
  }

  #contacts_wrapper.reg_wizard .contact {
    background-color: inherit;
  }

  #contacts_wrapper.reg_wizard .draggable-handler, #contacts_wrapper.reg_wizard .contact-remove-btn {
    display: none;
  }

  #contacts_wrapper.reg_wizard + #contacts_controls {
    display: none;
  }

  #contacts_wrapper.reg_wizard .contact-comments-btn {
    display: none;
  }

  .form-group.callout.callout-info.contact {
    height: auto !important;
  }

</style>

<form class='form-horizontal row justify-content-center'>
  <input type='hidden' name='subf' value='%subf%'>
  <input type='hidden' name='DEFAULT_CONTACT_TYPES' value='%DEFAULT_TYPES%'>

  <div class='form-group %SIZE_CLASS%'>
    <div class='card'>
      <div class='card-header with-border'>
        <h3 class='card-title'>_{CONTACTS}_</h3>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'>
            <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='card-body' style='display: block;'>
        <div id='contacts_wrapper'></div>
        <div id='contacts_controls'>
          <div class='col-xs-8'>
            <span class='text-success' id='contacts_response'></span>
          </div>
          <div class='col-xs-4 text-right'>
            <button role='button' id='contact_add' class='btn btn-sm btn-success'>
              <span class='fa fa-plus'></span>
            </button>

            <button role='button' id='contact_submit' class='btn btn-sm btn-primary disabled'>
              <span class='fa fa-check'></span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</form>

<script>
  var CONTACTS_LANG = {
    'COMMENTS': '_{COMMENTS}_',
    'CONTACTS': '_{CONTACTS}_',
    'EDIT': '_{EDIT}_',
    'SAVE': '_{SAVE}_',
    'CANCEL': '_{CANCEL}_',
    'ADD': '_{ADD}_',
    'REMOVE': '_{REMOVE}_'
  };
  var CONTACTS_JSON = JSON.parse('%JSON%');
</script>

<!-- Mustache.min.js template -->
<script id='contacts_modal_body' type='x-tmpl-mustache'>
    <div class='form-group contact'>
      <div class="row">
        <div class="col-sm-4 col-md-4">
          <select class='form-control' name='type_id' id='contacts_type_select'>
            {{ #types }}
              <option value='{{ id }}'>{{ name }}</option>
            {{ /types }}
          </select>
        </div>
        <div class='col-sm-8 col-md-8'>
          <input type='text' class='form-control' id='contacts_type_value' name='value' placeholder="_{CONTACTS}_"/>
        </div>
      </div>
    </div>
</script>

<script id='contact_comment_edit_template' type='x-tmpl-mustache'>
  <label class='col-sm-2 col-md-4 col-form-label'>_{COMMENTS}_</label>
  <input id="edit_contact_comments_modal_input" value="{{ comments }}" class="form-control" type="text">
</script>

<script id='contact_template' type='x-tmpl-mustache'>
  <div class='form-group row contact_template_data' data-id='{{id}}' data-priority='{{priority}}' data-position='{{position}}'>
    <span class="handle ui-sortable-handle col-md-1" style='padding-top: 8px;'>
      <i class="fa fa-ellipsis-v"></i>
      <i class="fa fa-ellipsis-v"></i>
    </span>
    <label class='col-sm-2 col-md-4 col-form-label'>{{name}}</label>
    <div class="col-sm-8 col-md-6">
      <input class='form-control contact_template_value' type='text' {{#form}}form='{{form}}'{{/form}} name='{{type_id}}' {{#value}}value='{{value}}'{{/value}}/>
    </div>
    <div class='col-sm-2 col-md-1'>
      {{^is_default}}
        <a data-target='#' class='contact-remove-btn text-red form-control-static' data-id='{{id}}'>
          <span class='fa fa-times'></span>
        </a>
      {{/is_default}}
    </div>
  </div>
</script>

<script src='/styles/default/js/contacts_form.js'></script>

<style>
  .contact {
    padding: 0.5rem !important;
  }
</style>
