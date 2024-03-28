<div id='form_4' class='card card-primary card-outline card-big-form for_sort container-md pr-0 pl-0'>
  <div class='card-header with-border'>
    <h3 class='card-title'>_{EQUIPMENT}_</h3>
    <div class='card-tools float-right'>
      <button id='reload_equipment_info_button' type='button' class='btn btn-tool' title='_{RELOAD_EQUIPMENT_INFO}_' disabled>
        <i class='fas fa-sync'></i>
      </button>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
      <button id='setting_equipment_info_button' type='button' class='btn btn-tool' title='_{EXTRA_FIELDS}_'>
        <i class='fa fa-align-left'></i>
      </button>
    </div>
  </div>
  <div class='card-body'>
    <div id='status-loading-content'>
      <div class='text-center'>
        <span class='fa fa-spinner fa-spin fa-2x'></span>
      </div>
    </div>
    <div id='equipment_info'></div>
  </div>
</div>

<script>
  let nasId = '%NAS_ID%';
  let port = '%PORT%';
  let vlan = '%VLAN%';
  let uid = '%UID%';
  let id = '%ID%';
  let errors_reset = '%ERRORS_RESET%' ? '&ERRORS_RESET=%ERRORS_RESET%' : '';

  let equipment_get_info_url = '$SELF_URL?header=2&get_index=equipment_user_info_ajax' + '&NAS_ID=' + nasId + '&PORT=' + port + '&VLAN=' +
    vlan + '&UID=' + uid + '&ID=' + id + errors_reset;

  let equipment_set_info_url = '$SELF_URL?header=2&get_index=equipment_user_info_ajax';

  let equipment_change_port_status_url = '$SELF_URL?header=2&get_index=equipment_change_port_status_ajax' + '&NAS_ID=' + nasId + '&PORT=' + port;
  let equipment_get_fields_url     = '?header=2&get_index=equipment_user_info_fields&GET_FIELDS=1';
  let equipment_change_fields_url  = '?header=2&get_index=equipment_user_info_fields&CHANGE=1';
  let equipment_default_fields_url = '?header=2&get_index=equipment_user_info_fields&DEFAULT=1';

  jQuery('#reload_equipment_info_button').on('click', function (e) {
    equipment_get_info(equipment_get_info_url);
  });

  jQuery('#setting_equipment_info_button').on('click', function (e) {
    equipment_set_info_fields();
  });

  equipment_get_info(equipment_get_info_url);

  function hide_equipment_info() {
    jQuery('#equipment_info').hide();
    jQuery('#equipment_info').parent().css('padding', '');
    jQuery('#status-loading-content').show();
    jQuery('#reload_equipment_info_button').prop('disabled', true);
  }

  function equipment_get_info(url) {
    hide_equipment_info();

    fetch(url)
      .then(function (response) {
        if (!response.ok) {
          throw Error(response.statusText);
        }

        return response.text();
      })
      .then(result => {
        jQuery('#equipment_info').html(result);
        jQuery('#equipment_info').show();
        jQuery('#status-loading-content').hide();
        jQuery('#reload_equipment_info_button').prop('disabled', false);

        let cardBody = jQuery('#equipment_info').children();
        cardBody.removeClass('card-primary');
        cardBody.css('margin-bottom', '0');
        jQuery('#equipment_info').parent().css('padding', '0');

        jQuery('#run_cable_test_button').on('click', function (e) {
          equipment_get_info(equipment_get_info_url + '&RUN_CABLE_TEST=1');
        });

        defineTooltipLogic();
        jQuery('#change_status_button').on('click', function (e) {
          hide_equipment_info();

          let atooltip = new ATooltip();
          atooltip.displayMessage({caption: '_{PORT_STATUS_CHANGING}_', message_type: 'info'});

          fetch(equipment_change_port_status_url + '&PORT_STATUS=' + jQuery('#change_status_button').data('change_to_status'))
            .then(function (response) {
              if (!response.ok)
                throw Error(response.statusText);

              return response.text();
            })
            .then(result_json => {
              let result = jQuery.parseJSON(result_json);

              atooltip.displayMessage({caption: result.comment, message_type: (result.error ? 'err' : '')});
              if (!result.error) {
                setTimeout(function() { //wait for physical status to change
                  equipment_get_info(equipment_get_info_url);
                }, 3000);
              }
              else {
                equipment_get_info(equipment_get_info_url);
              }
            })
        });
      });
  }

  function equipment_set_info_fields() {
    var equipment_user_info_fields = new AModal();
    equipment_user_info_fields
      .setId('equipment_user_info_fields')
      .setHeader('_{EQUIPMENT}_ _{FIELDS}_')
      .setBody(_create_equipment_user_info_fields())
      .setSize('xl')
      .show(function () {
        resultFormerFillCheckboxes();
      });

    _get_fields().then(res => _equipment_user_info_generate_body(res));
  }

  async function _get_fields() {
    return await (
      await fetch(equipment_get_fields_url)
    ).json();
  }

  function _create_equipment_user_info_fields() {
    let form = jQuery('<form></form>').attr('id', 'equipment_user_info_chg');

    let some_html = `<div class='text-center'>
        <span class='fa fa-spinner fa-spin fa-2x'></span>
      </div>`;
    form.html(some_html);
    return form.prop('outerHTML');
  }

  function _equipment_user_info_generate_body(res) {
    let { ONU, PORT, SW, CHECKED } = res;
    let full_list = [...ONU, ...PORT, ...SW];
    let checked_fields = CHECKED;
    let checkboxes = [];

    let form = jQuery('<form></form>').attr('method', 'POST').attr('id', 'equipment_user_info_chg').attr('action', '%SELF_URL%');

    full_list.forEach(function(field) {
      let key = field.key;
      let lang = field.lang;
      let name = field.name;

      let label = jQuery('<label></label>').attr('FOR', key).text(lang);
      let input = jQuery('<input/>').attr('type', 'checkbox').attr('name', name).attr('id', key)
        .text(lang).addClass('mr-1').attr('value', key);
      if (checked_fields.includes(key)) input.attr('checked', 'checked');

      let div = jQuery('<div></div>').addClass('axbills-checkbox-parent').append(input).append(label);
      checkboxes.push(div);
    });

    let col_size = full_list.length >= 16 ? 3 : 6;
    let fields_in_col = Math.ceil(checkboxes.length / parseInt(12 / col_size));
    let cols = Math.ceil(checkboxes.length / fields_in_col);

    let row = jQuery('<div></div>').addClass('row');
    for (const i of Array(cols).keys()) {
      let col = jQuery('<div></div>').addClass('col-md-' + col_size);
      for(let j = 0; j < fields_in_col; j++) {
        col.append(checkboxes.pop());
      }
      row.append(col);
    }
    form.append(row);

    jQuery('<hr>').appendTo(form);
    let default_btn = jQuery('<input/>')
                      .addClass('btn btn-default')
                      .attr('type', 'submit')
                      .attr('id', 'default_fields')
                      .attr('name', 'default_fields')
                      .attr('value', '_{DEFAULT}_')
    let submit_btn = jQuery('<input/>')
                      .addClass('btn btn-primary')
                      .attr('type', 'submit')
                      .attr('id', 'save_fields')
                      .attr('name', 'save_fields')
                      .attr('value', '_{SAVE}_');
    jQuery('<div></div>').addClass('axbills-form-main-buttons justify-content-between').append(default_btn).append(submit_btn).appendTo(form);

    jQuery('#equipment_user_info_chg').replaceWith(form);
    jQuery('#equipment_user_info_chg').submit(function (e) {
      cancelEvent(e);
    });
    resultFormerFillCheckboxes();
    jQuery('#save_fields').on('click', onEquipmentUserInfoSubmit);
    jQuery('#default_fields').on('click', onEquipmentUserInfoToDefault);
  }

  function onEquipmentUserInfoSubmit() {
    let form_value = jQuery('#equipment_user_info_chg').serialize();
    fetch(equipment_change_fields_url + '&' + form_value).then(() => {
      displayJSONTooltip({
        MESSAGE: {
          caption: '_{SUCCESS}_!',
          message_type: 'success'
        }
      });
    }).catch(() => {
      displayJSONTooltip({
        MESSAGE: {
          caption: '_{ERROR}_!',
          message_type: 'err'
        }
      });
    });
  }

  function onEquipmentUserInfoToDefault() {
    fetch(equipment_default_fields_url).then(() => {
      displayJSONTooltip({
        MESSAGE: {
          caption: '_{SUCCESS}_! _{DEFAULT}_.',
          message_type: 'success'
        }
      });
    }).catch(() => {
      displayJSONTooltip({
        MESSAGE: {
          caption: '_{ERROR}_!',
          message_type: 'err'
        }
      });
    });
  }
</script>
