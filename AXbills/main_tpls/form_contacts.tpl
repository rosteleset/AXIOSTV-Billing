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
  
  .fix-tooltip {
  	pointer-events: none;
  }

</style>

<input type='hidden' name='subf' value='%subf%'>
<input type='hidden' name='DEFAULT_CONTACT_TYPES' value='%DEFAULT_TYPES%'>

<div class='form-group %SIZE_CLASS% mb-0'>
  <div class='card card-outline card-big-form mb-0 border-top'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{CONTACTS}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body pt-0'>
      <ul id='contacts_wrapper' class='todo-list'></ul>
      <div id='contacts_controls'>
        <div class='col-xs-8'>
          <span class='text-success' id='contacts_response'></span>
        </div>
        <div class='col-xs-4 text-right pr-3'>
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
      <div class='row'>
        <div class='col-sm-4 col-md-4'>
          <select class='form-control' name='type_id' id='contacts_type_select'>
            {{ #types }}
              <option value='{{ id }}'>{{ name }}</option>
            {{ /types }}
          </select>
        </div>
        <div class='col-sm-4 col-md-4'>
          <input type='text' class='form-control' id='contacts_type_value' name='value' placeholder='_{CONTACTS}_'/>
        </div>
        <div class='col-sm-4 col-md-4'>
          <input type='text' class='form-control' id='contacts_type_comments' name='comments' placeholder='_{COMMENTS}_'/>
        </div>
      </div>
    </div>
</script>


<script id='contact_comment_edit_template' type='x-tmpl-mustache'>
  <label class='col-sm-2 col-md-4 col-form-label'>_{COMMENTS}_</label>
  <input id='edit_contact_comments_modal_input' value='{{ comments }}' class='form-control' type='text'>
</script>

<script id='contact_template' type='x-tmpl-mustache'>

  <li class='text-left contact_template_data' data-id='{{id}}' data-priority='{{priority}}' data-position='{{position}}'>
    <div class='d-flex bd-highlight'>
      <span class='pt-2 bd-highlight handle ui-sortable-handle'>
        <i class='fa fa-ellipsis-v'></i>
        <i class='fa fa-ellipsis-v'></i>
      </span>
      <div class='pl-1 pt-2 bd-highlight' style='width: 33%'>
        <label>{{name}}</label>
      </div>
      <div class='flex-grow-1 bd-highlight'>
        <input class='form-control contact_template_value' type='text' {{#form}}form='{{form}}'{{/form}} name='{{type_id}}' {{#value}}value='{{value}}'{{/value}}/>
        <input data-id='{{id}}' class='form-control contact_template_comments' type='hidden' {{#form}}form='{{form}}'{{/form}} name='COMMENTS' {{#comments}}value='{{comments}}'{{/comments}}/>
      </div>
      <div class='p-2 tools d-block'>
        <span
          data-tooltip='{{comments}}{{^comments}}_{COMMENTS_DOESNT_EXIST}_{{/comments}}'
          data-tooltip-position='left'
          data-content='{{comments}}{{^comments}}_{COMMENTS_DOESNT_EXIST}_{{/comments}}'
          data-html='true'
          data-toggle='popover'
          data-trigger='hover'
          data-placement='left'
          data-container='body'
          data-original-title=''
          title=''
          class='p-1 fa fa-comment contact-comment-edit-btn {{#comments}}text-blue{{/comments}} {{^comments}}text-secondary{{/comments}} form-control-static '
          data-id='{{id}}'>
         </span>
   
        {{^is_default}}
            <span data-target='#' class='fa fa-times contact-remove-btn text-red form-control-static' data-id='{{id}}'></span>
        {{/is_default}}
      </div>
    </div>

  </li>
</script>

<script src='/styles/default/js/contacts_form.js'></script>

<style>
  .contact {
    padding: 0.5rem !important;
  }
</style>
