<link rel='stylesheet' href='/styles/default/plugins/fullcalendar/fullcalendar.min.css'/>
<script src='/styles/default/plugins/fullcalendar/fullcalendar.min.js'></script>

<script src='%CALENDAR_LOCALE_SCRIPT%'></script>

<div class='row'>
    <div class='col-md-3'>
        <div class="card box-solid">
            <div class="card-header with-border">
                <h4 class="card-title">_{EMPLOYEES}_</h4>
            </div>
            <div class="card-body">
                <!-- the events -->
                <div id="external-events">
                    %ADMINS_LIST%
                </div>
            </div>
            <!-- /.box-body -->
        </div>
    </div>
    <div class='col-md-9'>
        <div class='card card-primary card-outline'>
            <div class='card-body'>
                <div id='calendar'></div>
            </div>
        </div>
    </div>
</div>


<script>
    jQuery(function () {
        jQuery('#calendar').fullCalendar({
            drop      : function (date, allDay) { // this function is called when something is dropped

                // retrieve the dropped element's stored Event Object
                var originalEventObject = jQuery(this).data('eventObject');

                // we need to copy it, so that multiple events don't have a reference to the same object
                var copiedEventObject = jQuery.extend({}, originalEventObject);

                // assign it the date that was reported
                copiedEventObject.start           = date
                copiedEventObject.end             = date
                copiedEventObject.allDay          = allDay
                copiedEventObject.backgroundColor = jQuery(this).css('background-color')
                copiedEventObject.borderColor     = jQuery(this).css('border-color');

                jQuery.post("%SELF_URL%", "header=2&qindex=" + '%INDEX%' + "&add_event=1&START_DATE=" + copiedEventObject.start.format() + "&DURATION=1" + "&AID=" + copiedEventObject.adminAid, function(data) {
                    console.log("Inesrt id - " + data);
                    copiedEventObject.id = data;
                // render the event on the calendar
                // the last `true` argument determines if the event "sticks" (http://arshaw.com/fullcalendar/docs/event_rendering/renderEvent/)
                jQuery('#calendar').fullCalendar('renderEvent', copiedEventObject, true);
                });


            },
            // this functon is called when something is redropped
            eventDrop: function(event, delta, revertFunc) {
                console.log(delta);
//                alert(event.title + " was dropped on " + event.start.format());
                jQuery('#calendar').fullCalendar('renderEvent', event, true);
                if (!confirm("Are you sure about this change?")) {
                    revertFunc();
                }
                else{
                    jQuery.post("%SELF_URL%", "header=2&qindex=" + '%INDEX%' + "&change_event=1&START_DATE=" + event.start.format() + "&ID=" + event.id);
                }

            },
            eventResize: function(event, delta, revertFunc) {
                jQuery.post("%SELF_URL%", "header=2&qindex=" + '%INDEX%' + "&change_event=1&DURATION=" + delta.days() + "&ID=" + event.id);
            },
            eventRender: function(event, element) {
                element.append( "<span class='closeon'>X</span>" );
                element.find(".closeon").click(function() {
                    console.log("Id when render - " + event.id);
                    jQuery('#calendar').fullCalendar('removeEvents',event.id);
                    jQuery.post("%SELF_URL%", "index=" + '%INDEX%' + "&delete_event=1&ID=" + event.id );
                });
            },
            events: JSON.parse('%JSON_EVENTS%'),
            locale     : '%CALENDAR_LOCALE%',
            defaultView: 'month',
            header     : {
                left  : 'title',
                right : 'today prev,next'
            },
            aspectRatio : 2,
            editable  : true,
            droppable : true, // this allows things to be dropped onto the calendar !!!

        })
    });
</script>


<script>
    jQuery(function () {

        /* initialize the external events
         -----------------------------------------------------------------*/
        function init_events(ele) {
            ele.each(function () {

                // create an Event Object (http://arshaw.com/fullcalendar/docs/event_data/Event_Object/)
                // it doesn't need to have a start or end
                var eventObject = {
                    title: jQuery.trim(jQuery(this).text()), // use the element's text as the event title
                    adminAid: jQuery.trim(jQuery(this).attr('id')) // use the element's text as the event title
                }

                // store the Event Object in the DOM element so we can get to it later
                jQuery(this).data('eventObject', eventObject)

                // make the event draggable using jQuery UI
                jQuery(this).draggable({
                    zIndex        : 1070,
                    revert        : true, // will cause the event to go back to its
                    revertDuration: 0  //  original position after the drag
                })

            })
        }

        init_events(jQuery('#external-events div.external-event'));

    })
</script>