<style>
	.crm-list-progress-bar {
		background: #fff;
		border: 1px solid #cdd0d3;
		border-radius: 2px;
		height: 10px;
		min-width: 170px;
		max-width: 350px;
		position: relative;
  }

  .crm-progress-bar-table {
		border-spacing: 0;
		height: 9px;
		width: 100%;
  }

  .crm-progress-bar-part {
		border-bottom-style: none !important;
		border-left: 1px solid rgba(0,0,0,.1);
		padding: 0 !important;
		width: 20px !important;
  }

	.crm-progress-bar-block {
		cursor: pointer;
		height: 8px;
		margin-right: -1px;
		min-width: 5px;
		position: relative;
  }

  .crm-progress-bar-btn {
		border-top: 2px solid rgba(111,113,115,.39);
		border-bottom: 2px solid rgba(111,113,115,.39);
		display: none;
		height: 150%;
		top: -2px;
		right: 0;
		position: absolute;
		width: 100%;
  }

  .crm-progress-bar-table-row {
    background-color: transparent !important;
  }

	.crm-progress-bar-table td.crm-progress-bar-part:first-child {
		border: none !important;
	}

  .crm-progress-bar-title {
		color: #a5a9ab;
		font-size: 12px;
		padding: 5px 0 0 3px;
		line-height: 14px !important;
  }

  #CRM_DEALS_.table td {
    border-top: none !important;
  }
</style>

<script>
  let steps;
  try {
    steps = JSON.parse('%STEPS_JSON%');
  }
  catch (e) {
    steps = {};
    console.log(e);
  }

  jQuery(document).ready(function () {
    jQuery('.crm-progress-bar-part').on('click', changeStep)

    jQuery('.crm-progress-bar-part').hover(function () {
      jQuery(this).find('.crm-progress-bar-btn').show()
    }, function () {
      jQuery(this).find('.crm-progress-bar-btn').hide()
    });

    function changeStep() {
      let step_number = jQuery(this).data('id');
      if (!step_number) return;

      let progress_bar = jQuery(this).parent().parent().parent().parent();
      let color = steps[step_number].color || '';
      let title = steps[step_number].name || '';
      jQuery(this).parent().find('.crm-progress-bar-part').each(function(index) {
        jQuery(this).css('background-color', step_number > index ? color : '');
      });
      progress_bar.parent().find('.crm-progress-bar-title').text(title);

      sendRequest(`/api.cgi/crm/deals/${progress_bar.data('id')}`, {current_step: step_number}, 'PUT');
    }
  });
</script>