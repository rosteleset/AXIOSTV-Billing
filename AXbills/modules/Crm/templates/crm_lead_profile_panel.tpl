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
</style>

<div class='col-md-3'>

  <div>
    <div class='card box-primary' id='info-container'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{INFO}_</h4>
        <div class='card-tools float-right'>
          %WATCHING_BUTTON%
          <button type='button' class='btn btn-tool mr-1 change-tool-btn'>_{CRM_CHANGE}_</button>
        </div>
      </div>
      <div class='card-body '>
        %MAIN_LABEL%
      </div>
      <div class='card-footer'>
        <button type='button' class='btn btn-tool m-1 choose-main-fields'>_{CRM_CHOOSE_FIELDS}_</button>
      </div>
    </div>
    <div class='card box-primary d-none' id='change-container'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{INFO}_</h4>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool mr-1 change-tool-btn'>_{CRM_CANCEL}_</button>
        </div>
      </div>
      <div class='card-body'>
        <form action='%SELF_URL%' method='POST' id='form-main-info'>
          <input type='hidden' name='index' value='%index%'>
          <input type='hidden' name='ID' value='%LEAD_ID%'>
          <input type='hidden' name='LEAD_ID' value='%LEAD_ID%'>

          %MAIN_INPUT%
        </form>
      </div>
      <div class='card-footer'>
        <button type='submit' class='btn btn-primary' name='change' form='form-main-info' value='1'>_{SAVE}_</button>
      </div>
    </div>
  </div>

  <div>
    <div class='card box-primary'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{EXTRA}_</h4>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool mr-1 change-tool-btn'>_{CRM_CHANGE}_</button>
        </div>
      </div>
      <div class='card-body '>
        %ADDITIONAL_LABEL%

        <span class='text-muted'>_{USER}_</span>
        <h6>%USER_BUTTON% %DELETE_USER_BUTTON%</h6>

        <!--        %LOG%-->
        <hr>
        %BUTTON_TO_LEAD_INFO%
        %CONVERT_DATA_BUTTON%
        %CONVERT_LEAD_BUTTON%
      </div>
      <div class='card-footer'>
        <button type='button' class='btn btn-tool m-1 choose-additional-fields'>_{CRM_CHOOSE_FIELDS}_</button>
      </div>
    </div>
    <div class='card box-primary d-none'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{EXTRA}_</h4>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool mr-1 change-tool-btn'>_{CRM_CANCEL}_</button>
        </div>
      </div>
      <div class='card-body'>
        <form action='%SELF_URL%' method='POST' id='form-additional-info'>
          <input type='hidden' name='index' value='%index%'>
          <input type='hidden' name='ID' value='%LEAD_ID%'>
          <input type='hidden' name='LEAD_ID' value='%LEAD_ID%'>

          %ADDITIONAL_INPUT%
        </form>
      </div>
      <div class='card-footer'>
        <button type='submit' class='btn btn-primary' name='change' form='form-additional-info' value='1'>_{SAVE}_
        </button>
      </div>
    </div>
  </div>
</div>

<script>
  jQuery('.change-tool-btn').on('click', function () {
    let parent = jQuery(this).parent().parent().parent();
    parent.parent().find('.card.d-none').removeClass('d-none');
    parent.addClass('d-none');
  });

  jQuery('.form-address').find('.form-group').each(changeRowView);
  jQuery('.change-view').find('.form-group').each(changeRowView);

  jQuery('.choose-main-fields').on('click', function () {
    let body = jQuery(this).parent().parent().find('.card-body').first();

    let row = jQuery('<div></div>');
    row.addClass('row');

    body.find('span.text-muted').each(function () {
      let caption = jQuery(this).text();
      let col = jQuery('<div></div>');
      row.append(col.addClass('col-auto').html(caption));
    });
    var main_fields = new AModal();
    main_fields
      .setId('main_fields')
      .isForm(true)
      .setHeader('_{FIELDS}_')
      .setBody(`%CRM_MAIN_EXTRA_FIELDS%`)
      .setSize('lg')
      .show(function () {
        resultFormerFillCheckboxes();
      });
  });

  jQuery('.choose-additional-fields').on('click', function () {
    let body = jQuery(this).parent().parent().find('.card-body').first();

    let row = jQuery('<div></div>');
    row.addClass('row');

    body.find('span.text-muted').each(function () {
      let caption = jQuery(this).text();
      let col = jQuery('<div></div>');
      row.append(col.addClass('col-auto').html(caption));
    });
    var main_fields = new AModal();
    main_fields
      .setId('additional_fields')
      .isForm(true)
      .setHeader('_{FIELDS}_')
      .setBody(`%CRM_ADDITIONAL_EXTRA_FIELDS%`)
      .setSize('lg')
      .show(function () {
        resultFormerFillCheckboxes();
      });
  });

  function changeRowView() {
    jQuery(this).removeClass('row').addClass('mb-2');
    let label = jQuery(this).find('label').removeAttr('class').addClass('text-muted font-weight-normal mb-0');
    label.text(label.text().replace(':', ''))
    jQuery(this).find('.col-md-8').removeAttr('class');
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