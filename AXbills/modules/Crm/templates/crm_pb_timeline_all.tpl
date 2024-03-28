<div id='s%ID%' class='tab-pane fade %ACTIVE%'>
  <form action='$SELF_URL' method='POST' id='FORM%ID%' class='comment-form'>
    <input type='hidden' name='index'   value='%INDEX%'>
    <input type='hidden' name='LEAD_ID' value='%LEAD_ID%' id='LEAD_ID'>
    <input type='hidden' name='STEP_ID' value='%ID%'>

  <div class='timeline mb-0' id='pined-timeline-container'></div>
  <div class='timeline mb-0'>%TIMELINE_ITEMS_ALL%</div>

  </form>
</div>

<script>
  // load items to pined-timeline-container
  jQuery('.timeline-item-all').each(function() {
    var comment_data_pin = jQuery(this).data('pin');
    var comment_id = jQuery(this).data('id');
    let parent = jQuery(this).parent();

    if (!comment_data_pin) return;

    let pinedActivity = parent.clone().appendTo('#pined-timeline-container');
    let pinButton = parent.find('.pin-button').first();

    addStyle(pinedActivity);

    pinedActivity.find('.pin-button').first().removeClass('pin-button').addClass('unpin-button');
    pinedActivity.find('.unpin-button').first().removeAttr('data-tooltip');

    pinedActivity.find('.unpin-button').first().on('click', function() {
      sendRequest(`/api.cgi/crm/progressbar/messages/${comment_id}`, {pin: 0}, 'PUT')
      pinedActivity.remove();
      pinButton.show();
    })
    pinButton.hide();
  });

  // pin-button click
  jQuery('.pin-button').on('click', function() {
    let pinButton = jQuery(this);
    let parent = jQuery(this).parent().parent().parent();
    var comment_id = jQuery(this).parent().parent().data('id');

    sendRequest(`/api.cgi/crm/progressbar/messages/${comment_id}`, {pin: 1}, 'PUT')
      .then((data) => {
      console.log(data);
    });

    let pinedActivity = parent.clone().appendTo('#pined-timeline-container');
    pinedActivity.find('.pin-button').first().addClass('unpin-button');

    addStyle(pinedActivity);

    pinedActivity.find('.unpin-button').first().on('click', function() {
      sendRequest(`/api.cgi/crm/progressbar/messages/${comment_id}`, {pin: 0}, 'PUT')
      pinedActivity.remove();
      pinButton.show();
    })

    pinButton.hide();
  });

  function addStyle(pinedActivity){
    // add background color
    pinedActivity.find('.timeline-header').first().addClass('timeline-item-pinned');
    pinedActivity.find('.timeline-body').first().addClass('timeline-item-pinned');
    pinedActivity.find('.timeline-footer').first().removeClass('timeline-item-footer').addClass('timeline-item-pinned');
    // add class for dark-mode
    pinedActivity.find('.timeline-item').first().addClass('timeline-item-black');
    pinedActivity.find('.time').first().addClass('time-black');
  }

  // modules/Crm/Api.pm
  async function sendRequest(url = '', data = {}, method = 'POST') {
    const response = await fetch(url, {
      method: method,
      mode: 'cors',
      cache: 'no-cache',
      credentials: 'same-origin',
      headers: {'Content-Type': 'application/json'},
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
      body: method === 'GET' ? undefined : JSON.stringify(data)
    });
    return response.json();
  }

  jQuery('.del-task-button').on('click', function() {
    location.reload();
  })

</script>

<style>
   .timeline-item-pinned {
     background-color: #f9f0b7;
   }

  .pin-button:hover {
  cursor: pointer;
  color: black !important;
  }
</style>


