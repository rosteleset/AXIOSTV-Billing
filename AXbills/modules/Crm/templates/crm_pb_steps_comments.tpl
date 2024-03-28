<style>
	.lead-steps>.btn:not(:last-child):not(.dropdown-toggle) {
		border-bottom-left-radius: 0;
	}
	.lead-steps>.btn:not(:first-child):not(.dropdown-toggle) {
		border-bottom-right-radius: 0;
	}
  .all-steps-btn {
		border-top-left-radius: 0;
		border-top-right-radius: 0;
  }
</style>

<!--<ul class='nav nav-pills btn-group nav-justified lead-steps' id='pills-tab' role='tablist'>-->
<!--  %PILLS%-->
<!--</ul>-->
<!--%ALL_BUTTON%-->


<div class='tab-content'>
  %TIMELINE%
</div>

<script>
  jQuery(`[name='ACTION_ID']`).on('change', actionPanel);

  function actionPanel() {
    let action_id = jQuery(this).val();
    let parent = jQuery(this).parent().parent().parent();
    let plan_date = parent.find(`[name='PLANNED_DATE']`).parent().parent();
    let priority = parent.find(`[name='PRIORITY']`).parent().parent().parent();

    if (action_id) {
      plan_date.show();
      priority.show();
      return;
    }

    plan_date.hide();
    priority.hide();
  }

  jQuery('.message-del').on('click', function() {
    let message_id = jQuery(this).parent().data('message');
    if (!message_id) return;

    let message_block = jQuery(this).parent().parent().parent().parent();
    let date_block = message_block.parent();
    message_block.remove();
    if (date_block.children().length < 2) date_block.remove();

    sendRequest(`/api.cgi/crm/progressbar/messages/${message_id}/`, undefined, 'DELETE');
  })

  jQuery(`[name='add_message']`).on('click', function (e) {
    e.preventDefault();

    let data = jQuery(`#${jQuery(this).attr('form')}`).serializeArray().reduce(function (json, {name, value}) {
      json[name] = value;
      return json;
    }, {});

    sendRequest(`/api.cgi/crm/progressbar/messages/`, data, 'POST')
      .then((data) => {
        location.reload()
      })
      .catch((error) => {
        console.log(error);
        location.reload()
      });
  });

  jQuery('.steps-info').on('click', function() {
    let active_id = `#${jQuery(this).attr('aria-controls')}`;
    jQuery('#s0').removeClass('active').removeClass('in');

    if (jQuery(this).hasClass('active')) {
      jQuery('.tab-pane').removeClass('active').removeClass('show');
      jQuery('#s0').addClass('active').addClass('show');
      jQuery(this).removeClass('active');
      return;
    }

    jQuery('.steps-info').removeClass('active');
    jQuery(this).addClass('active');
    jQuery('.tab-pane').removeClass('active').removeClass('show');
    jQuery(active_id).addClass('active').addClass('show');
  });
</script>
