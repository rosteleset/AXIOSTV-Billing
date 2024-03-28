<style>
	.btn-tool {
		border-bottom: 1px dashed transparent;
		padding: 0;
		line-height: 1;
	}

	.btn-tool:active {
		background-color: transparent !important;
		border-color: transparent !important;
	}

	.btn-tool:hover {
		border-bottom-color: #6a6f75;
		color: #6a6f75;
		opacity: 1;
	}

  .edit-title-btn {
    font-size: 0.8rem;
  }

  .crm-product-container {
		margin-top: 10px;
		margin-bottom: 0;
		padding: 0;
		border: 1px solid transparent;
		background-color: rgba(230,234,240,0.42);
		border-radius: 7px;
		transition: max-height 500ms ease;
		overflow: hidden;
  }
</style>

<div class='col-md-3'>
  %SECTIONS%
  <input type='hidden' name='DEAL_SECTION' id='DEAL_SECTION' value='%DEAL_SECTION%'>

  <button type='button' class='btn btn-tool ml-2 mb-2' id='create-section'>_{CRM_CREATE_NEW_SECTION}_</button>
</div>

<script>
  try {
    var fields = JSON.parse('%FIELDS%');
    var checked_fields = JSON.parse('%CHECKED_FIELDS%');
  } catch (err) {
    console.log('JSON parse error');
    console.log(err);
  }

  jQuery('#create-section').on('click', createSection);
  jQuery('.delete-section').on('click', deleteSection);

  jQuery('.change-tool-btn').on('click', function () {
    let parent = jQuery(this).parent().parent().parent();
    parent.parent().find('.card.d-none').removeClass('d-none');
    parent.addClass('d-none');
  });

  jQuery('.form-address').find('.form-group').each(changeRowView);
  jQuery('.change-view').find('.form-group').each(changeRowView);
  jQuery('.choose-fields').on('click', fieldsModal);
  jQuery('.edit-title-btn').on('click', turnOnRenameSectionTitle);
  jQuery('.section-title').hover(
    function() { jQuery(this).find('.edit-title-btn').removeClass('d-none'); },
      function() { jQuery(this).find('.edit-title-btn').addClass('d-none'); });

  function changeRowView() {
    jQuery(this).removeClass('row').addClass('mb-2');
    let label = jQuery(this).find('label').removeAttr('class').addClass('text-muted font-weight-normal mb-0');
    label.text(label.text().replace(':', ''))
    jQuery(this).find('.col-md-8').removeAttr('class');
  }

  function createSection() {
    let self = this;
    sendRequest(`/api.cgi/crm/sections/`, {title: '_{CRM_NEW_SECTION}_', deal_section: jQuery('#DEAL_SECTION').val()}, 'POST')
      .then(data => {
        if (!data.insertId) return;

        let choose_fields_btn = jQuery('<button></button>').addClass('btn btn-tool m-1 choose-additional-fields')
          .text('_{CRM_CHOOSE_FIELDS}_').attr('data-id', data.insertId).on('click', fieldsModal);
        let card_footer = jQuery('<div></div>').addClass('card-footer').append(choose_fields_btn);
        let card_tools = jQuery('<div></div>').addClass('card-tools float-right');
        let turnOnInputBtn = jQuery('<a></a>').addClass('ml-2 text-muted fa fa-pencil-alt cursor-pointer d-none')
          .attr('data-id', data.insertId).on('click', turnOnRenameSectionTitle);
        let card_title = jQuery('<div></div>').addClass('card-title').append(jQuery('<span></span>').text('_{CRM_NEW_SECTION}_'))
          .append(turnOnInputBtn).hover(function() { turnOnInputBtn.removeClass('d-none'); }, function() { turnOnInputBtn.addClass('d-none'); });
        let card_input_title = jQuery('<input/>').addClass('card-title form-control d-none').val('_{CRM_NEW_SECTION}_');
        let card_header = jQuery('<div></div>').addClass('card-header with-border').append(card_title)
          .append(card_input_title).append(card_tools);
        let card_body = jQuery('<div></div>').addClass('card-body');
        let card = jQuery('<div></div>').addClass('card card-primary card-outline').append(card_header)
          .append(card_body).append(card_footer);

        card.insertBefore(self);
      });
  }

  function deleteSection() {
    let self = this;
    let section_id = jQuery(this).data('id');
    if (!section_id) return;

    let confirmModal = new AModal();
    confirmModal
      .setHeader('_{CRM_DELETE_SECTION}_')
      .setBody('<div>_{CONFIRM_DELETE_SECTION}_</div>')
      .addButton('_{NO}_', 'confirmModalCancelBtn', 'default')
      .addButton('_{YES}_', 'confirmModalConfirmBtn', 'success')
      .show(function () {
        jQuery('#confirmModalConfirmBtn').on('click', function () {
          confirmModal.hide();
          sendRequest(`/api.cgi/crm/sections/${section_id}`, undefined, 'DELETE');
          jQuery(self).parent().parent().parent().remove();
        });

        jQuery('#confirmModalCancelBtn').on('click', function () {
          confirmModal.hide();
        });
      });
  }

  function fieldsModal() {
    let section_id = jQuery(this).data('id');

    var main_fields = new AModal();
    main_fields
      .setId('main_fields')
      .setHeader('_{FIELDS}_')
      .setBody(createFieldsForm(section_id))
      .setSize('lg')
      .show(function () {
        resultFormerFillCheckboxes();
      });
  }

  function turnOnRenameSectionTitle() {
    let section_id = jQuery(this).data('id');
    let input = jQuery(this).parent().parent().find('input.d-none').removeClass('d-none');
    let title = jQuery(this).parent().addClass('d-none');
    input.focus();
    input.blur(function() {
      input.addClass('d-none');
      title.find('span').text(input.val());
      title.removeClass('d-none');

      sendRequest(`/api.cgi/crm/sections/${section_id}`, {title: input.val()}, 'PUT');
    });
  }

  function createFieldsForm(section_id) {
    if (!section_id) return jQuery();

    let section_checked_fields = checked_fields[section_id] || [];
    let checkboxes = [];

    let form = jQuery('<form></form>').attr('method', 'POST').attr('action', '%SELF_URL%');
    form.append(jQuery('<input/>').attr('name', 'index').attr('value', '%index%').attr('type', 'hidden'));
    form.append(jQuery('<input/>').attr('name', 'LEAD_ID').attr('value', '%LEAD_ID%').attr('type', 'hidden'));
    form.append(jQuery('<input/>').attr('name', 'DEAL_ID').attr('value', '%DEAL_ID%').attr('type', 'hidden'));
    form.append(jQuery('<input/>').attr('name', 'UID').attr('value', '%UIDform-section%').attr('type', 'hidden'));
    form.append(jQuery('<input/>').attr('name', 'SECTION_ID').attr('value', section_id).attr('type', 'hidden'));

    fields.forEach(function(field) {
      let key = field.key;
      let lang = field.lang;

      let label = jQuery('<label></label>').attr('FOR', key).text(lang);
      let input = jQuery('<input/>').attr('type', 'checkbox').attr('name', 'FIELDS').attr('id', key)
        .text(lang).addClass('mr-1').attr('value', key);
      if (section_checked_fields.includes(key)) input.attr('checked', 'checked');

      let div = jQuery('<div></div>').addClass('axbills-checkbox-parent').append(input).append(label);
      checkboxes.push(div);
    });

    let col_size = fields.length >= 16 ? 3 : 6;
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

    let submit_btn = jQuery('<input/>').addClass('btn btn-primary').attr('type', 'submit').attr('name', 'save_fields')
      .attr('value', '_{SAVE}_');
    jQuery('<div></div>').addClass('axbills-form-main-buttons').append(submit_btn).appendTo(form);

    return form.prop('outerHTML');
  }
</script>

<script>
  let competitors_sel = jQuery('#COMPETITOR_ID');
  let tps_container = jQuery('#tps-container');

  loadTps();

  function loadTps() {
    jQuery('#tps-row').addClass('hidden');
    jQuery('#assessment-row').addClass('hidden');

    if (!competitors_sel.val()) {
      jQuery('#TP_ID').attr('disabled', 1);
      jQuery('#ASSESSMENTS').attr('disabled', 1);
      return;
    }

    fetch('$SELF_URL?header=2&get_index=crm_competitor_tps_select&COMPETITOR_ID=' +
      competitors_sel.val() + '&TP_ID=' + (jQuery('#TP_ID_INPUT').val() || ''))
      .then(response => {
        if (!response.ok) throw response;

        return response;
      })
      .then(function (response) {
        try {
          return response.text();
        } catch (e) {
          console.log(e);
        }
      })
      .then(result => {
        jQuery('#tps-row').removeClass('hidden');
        jQuery('#assessment-row').removeClass('hidden');
        jQuery('#ASSESSMENTS').removeAttr('disabled');
        tps_container.html(result);
        initChosen();
      })
      .catch(err => {
        jQuery('#tps-row').removeClass('hidden');
        jQuery('#assessment-row').removeClass('hidden');
        jQuery('#ASSESSMENTS').removeAttr('disabled');
        console.log(err);
      });
  }
</script>