<input type='hidden' id='WORKFLOW_ID' name='WORKFLOW_ID' value='%chg%'>
<div class='card card-primary card-outline'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{WORKFLOW}_</h4>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
    </div>
  </div>
  <div class='card-body'>
    <div class='row form-group pl-3'><h6 class='h6 m-0'>_{SPECIFY_CONDITIONS}_</h6></div>
    <div id='triggers'></div>
    <div class='row'>
      <div class='col-md-12 text-center'>
        <a type='button' class='btn-link p-0' id='add-trigger-btn'>+ _{ADD_CONDITION}_</a>
      </div>
    </div>
    <hr/>
    <div class='row form-group pl-3'><h6 class='h6 m-0'>_{SPECIFY_ACTIONS}_</h6></div>
    <div id='actions'></div>
    <div class='row'>
      <div class='col-md-12 text-center'>
        <a type='button' class='btn-link p-0' id='add-action-btn'>+ _{ADD_ACTION}_</a>
      </div>
    </div>
    <hr/>
    <div class='form-group row'>
      <label class='col-md-3 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
      <div class='col-md-9'>
        <input id='NAME' name='NAME' value='%NAME%' placeholder='_{NAME}_' class='form-control' type='text'>
      </div>
    </div>
    <div class='form-group row'>
      <label class='col-md-3 col-form-label text-md-right' for='DESCRIBE'>_{DESCRIBE}_:</label>
      <div class='col-md-9'>
        <textarea id='DESCRIBE' name='DESCRIBE' placeholder='_{DESCRIBE}_' class='form-control'
                  type='text'>%DESCRIBE%</textarea>
      </div>
    </div>
    <div class='form-group row'>
      <label class='col-md-3 col-form-label text-md-right' for='DISABLE'>_{DISABLED}_:</label>
      <div class='col-md-9'>
        <input type='checkbox' name='DISABLE' id='DISABLE' value=1 class='control-element' %DISABLE%/>
      </div>
    </div>

  </div>
  <div class='card-footer'>
    <button class='btn btn-primary' id='save-workflow'>_{SAVE}_</button>
  </div>
</div>

<script>
  let ACTIVE_TRIGGERS;
  let ACTIVE_ACTIONS;
  let TRIGGERS = JSON.parse('%TRIGGERS%');
  let TRIGGERS_HASH = [];
  TRIGGERS.forEach(trigger => TRIGGERS_HASH[trigger.type] = trigger);

  let ACTIONS = JSON.parse('%ACTIONS%');
  let ACTIONS_HASH = [];
  ACTIONS.forEach(trigger => ACTIONS_HASH[trigger.type] = trigger);

  jQuery('#add-trigger-btn').on('click', function () { defaultRow('trigger') });
  jQuery('#add-action-btn').on('click', function () { defaultRow('action') });

  try {
    ACTIVE_TRIGGERS = JSON.parse('%ACTIVE_TRIGGERS%');
    ACTIVE_ACTIONS = JSON.parse('%ACTIVE_ACTIONS%');
  } catch ( e ) {
    jQuery('#add-trigger-btn').click();
    jQuery('#add-action-btn').click();
  }

  if (ACTIVE_TRIGGERS !== undefined) {
    ACTIVE_TRIGGERS.forEach(trigger => {
      defaultRow('trigger', trigger);
    });
  }

  if (ACTIVE_ACTIONS !== undefined) {
    ACTIVE_ACTIONS.forEach(action => {
      defaultRow('action', action);
    });
  }

  function defaultRow(type, attr = {}) {
    let CONDITIONS = type === 'action' ? ACTIONS : TRIGGERS;
    let CONDITIONS_HASH = type === 'action' ? ACTIONS_HASH : TRIGGERS_HASH;

    let container_id = `${type}s`;
    let id = Date.now().toString();
    let row = document.createElement('div');
    row.classList.add('row', 'form-group', 'bg-light', 'p-2', 'rounded');
    row.id = 'row' + id
    let type_col = document.createElement('div');
    type_col.classList.add('col-4');
    let value_col = document.createElement('div');
    value_col.classList.add('col-7', 'value-col', 'row');
    let del_col = document.createElement('div');
    del_col.classList.add('col-1', 'pr-0', 'pt-2');

    let del_btn = document.createElement('button');
    del_btn.classList.add('close');
    let del_icon = document.createElement('span');
    del_icon.innerHTML = '\&times;';
    del_btn.appendChild(del_icon);
    del_col.appendChild(del_btn);

    jQuery(del_btn).on('click', function () {
      jQuery(row).remove();
      checkSelectFields(undefined, container_id, CONDITIONS);
    });

    let types_select = document.createElement('select');
    types_select.classList.add(type);
    types_select.name = 'type';
    types_select.id = id;

    CONDITIONS.forEach(condition => {
      let option = document.createElement('option');
      option.value = condition.type;
      option.text = condition.lang;
      if (condition.type === attr.type) option.selected = 'selected';

      types_select.appendChild(option);
    });

    type_col.appendChild(types_select);

    row.appendChild(type_col);
    row.appendChild(value_col);
    row.appendChild(del_col);

    document.getElementById(container_id).appendChild(row);

    checkSelectFields(id, container_id, CONDITIONS);
    if (jQuery(`#${id} option`).length < 1 ) {
      document.getElementById(`${row.id}`).remove();
      return;
    }

    jQuery(types_select).select2({width: '100%'});
    jQuery(types_select).on('change', function (e) {
      let type = jQuery(this).val();
      let parent = jQuery('#row' + id).find('.value-col').first();
      parent.html('');

      let action = CONDITIONS_HASH[type];
      if (action === undefined) return;

      if (action.fields !== undefined) {
        action.fields.forEach(field => {
          addField(field, parent, action.type, attr)
        });
      }

      checkSelectFields(undefined, container_id, CONDITIONS);
    }).change();
  }

  function checkSelectFields (id = undefined, container_id, CONDITIONS) {
    let selectedConditions = [];
    jQuery(`#${container_id}`).find(id ? `select[name="type"]:not(#${id})` : 'select[name="type"]').each(function() {
      if (jQuery(this).val()) selectedConditions.push(jQuery(this).val());
    });

    if (id) {
      selectedConditions.forEach(condition => {
        jQuery(`#${id} option[value="${condition}"]`).remove();
      });
      if (jQuery(`#${id} option`).length < 1) return;

      selectedConditions.push(jQuery(`#${id}`).val())
    }

    jQuery(`#${container_id}`).find(id ? `select[name="type"]:not(#${id})` : 'select[name="type"]').each(function() {
      jQuery(`#${jQuery(this).attr('id')} option`).not(`[value="${jQuery(this).val()}"]`).remove();

      let select = jQuery(this);
      CONDITIONS.forEach(condition => {
        if (selectedConditions.includes(condition.type)) return;

        let option = document.createElement('option');
        option.value = condition.type;
        option.text = condition.lang;

        select.append(option);
      });
    });
  }

  function addField(fields, parent, type, attr = {}) {
    if (fields.type === 'textarea') {
      let col = document.createElement('div');
      col.classList.add('col-md-12');

      let field = document.createElement('textarea');
      field.classList.add('form-control');
      field.placeholder = fields.placeholder;
      field.name = type;
      field.dataset.name = fields.name;
      if (attr.contains) field.innerText = attr.contains;
      if (attr.value) field.innerText = attr.value;

      col.appendChild(field);
      parent.append(jQuery(col));
      return;
    }
    if (fields.type === 'select') {
      let col = document.createElement('div');
      col.classList.add('col-md-6');

      let field = document.createElement('select');
      field.name = type;
      field.dataset.name = fields.name;
      if (fields.empty !== undefined) field.appendChild(document.createElement('option'));

      Object.keys(fields.options).forEach(value => {
        let option = document.createElement('option');
        option.value = value;
        option.text = fields.options[value];

        field.appendChild(option);
      });

      col.appendChild(field);
      parent.append(jQuery(col));
      jQuery(field).select2({width: '100%', placeholder: fields.placeholder, allowClear: true, multiple: fields.multiple});

      if (attr[fields.name] !== undefined) {
        if (!attr[fields.name]) attr[fields.name] = 0;
        let selected_array = typeof attr[fields.name] === 'string' ? attr[fields.name].split(',') : [ attr[fields.name] ];
        jQuery(field).val(selected_array).change();
      }
    }
  }

  jQuery('#save-workflow').on('click', function () {
    let self = this;
    let data = {
      triggers: [],
      actions: [],
      name: jQuery('#NAME').val(),
      descr: jQuery('#DESCRIBE').val(),
      disable: jQuery('#DISABLE').is(':checked') ? 1 : 0
    };

    jQuery('#triggers').find('.trigger').each(function () {
      let trigger_data = {type: jQuery(this).val()};
      let parent = jQuery(this).parent().parent();
      let trigger = TRIGGERS_HASH[jQuery(this).val()];
      parent.find(`[name='${trigger.type}']`).each(function () {
        let trigger_value = jQuery(this).val();
        if (!trigger_value) return;
        if (Array.isArray(trigger_value)) trigger_value = trigger_value.join(',');

        trigger_data[jQuery(this).data('name')] = trigger_value;
      });
      data.triggers.push(trigger_data);
    });

    jQuery('#actions').find('.action').each(function () {
      let action_data = {type: jQuery(this).val()};
      let parent = jQuery(this).parent().parent();
      let action = ACTIONS_HASH[jQuery(this).val()];
      parent.find(`[name='${action.type}']`).each(function () {
        let action_value = jQuery(this).val();
        if (!action_value) return;
        if (Array.isArray(action_value)) action_value = action_value.join(',');

        action_data[jQuery(this).data('name')] = action_value;
      });
      data.actions.push(action_data);
    })

    let workflow_id = jQuery('#WORKFLOW_ID').val();
    postData('/api.cgi/msgs/workflow' + (workflow_id ? `/${workflow_id}` : ''), data)
      .then((data) => {
        let message = data.errstr || '_{MSGS_SAVED_SUCCESSFULLY}_'
        document.location.href = `?index=%index%&MESSAGE=${message}`;
      });
    jQuery(self).prop('disabled', true);
  });
  async function postData(url = '', data = {}) {
    const response = await fetch(url, {
      method: 'POST',
      mode: 'cors',
      cache: 'no-cache',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json' },
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
      body: JSON.stringify(data)
    });
    return response.json();
  }
</script>