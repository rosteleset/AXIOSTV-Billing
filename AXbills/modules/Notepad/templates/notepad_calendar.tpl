<link rel='stylesheet' href='/styles/default/plugins/fullcalendar/fullcalendar.min.css'/>
<script src='/styles/default/plugins/fullcalendar/fullcalendar.min.js'></script>

<script src='%CALENDAR_LOCALE_SCRIPT%'></script>

<div class='card card-primary card-outline'>
  <div class='card-body'>
    <div id='calendar'></div>
  </div>
</div>

<script>

  var status_color = {
    0 : 'green',
    1 : 'goldenrod',
    2 : 'maroon',
    3 : 'grey'
  };

  function parseEvent(eventData) {

    return {
      id   : eventData["ID"],
      title: eventData["TITLE"],
      start: eventData["DATE"],
      url  : eventData["EXTRA"],
      color: status_color[eventData['STATUS']] || 'grey'
    }
  }

  jQuery(function () {
    jQuery('#calendar').fullCalendar({
      eventSources: [
//        {  events : REMINDERS_LIST.map(parseEvent) },
          {
          url               : '/admin/index.cgi?get_index=notepad_calendar_reminders',
          eventDataTransform: parseEvent
        }
        ],

      locale     : '%CALENDAR_LOCALE%',
      defaultView: 'listWeek',
      header     : {
        left  : 'title',
        center: 'month,basicWeek,listWeek',
        right : 'today prev,next'
      },
      aspectRatio : 2

    })
  });
</script>
