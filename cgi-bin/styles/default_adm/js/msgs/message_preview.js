/**
 * Created by Anykey on 21.09.2016.
 */
jQuery(function () {
  var table = $('table#MSGS_LIST_');
  var $trs = table.find('tbody').find('tr');
  var MSGS_HEADER_POSITION = 2;
  if ($trs.first().find('td').first().find('input').length > 0){
    MSGS_HEADER_POSITION = 3;
  }

  $.each($trs, function (i, tr) {
    var $td = $($(tr).find('td')[MSGS_HEADER_POSITION]);
    var $a  = $td.find('a');
    $a.attr('title', '');

    function showMessagePreview() {
      var link    = $a.attr('href');
      var message = $a.data('message');

      if (typeof (message) === 'undefined') {
        loadMessage(link, function (message) {

          if (typeof message === 'undefined'){
            message = 'error';
          }

          message = message.substr(0, 200);

          $a.data('message', message);
          renderTooltip($a, message);
          $a.popover('show');
        })
      }
      else {
        renderTooltip($a, message);
        $a.popover('show');
      }
    }

    var timeoutId;
    $a.hover(
        function () {
          if (!timeoutId) {
            timeoutId = window.setTimeout(function () {
              timeoutId = null;

              if(!$a.attr('aria-describedby'))
                showMessagePreview()
            }, 1000);
          }
        },
        function () {
          if (timeoutId) {
            window.clearTimeout(timeoutId);
            timeoutId = null;
          }
          else {
            if(!$a.attr('aria-describedby'))
              showMessagePreview()
          }
        }
    );
  });

  function loadMessage(link, callback) {
    if (link.indexOf('#') != -1) {
      var matched = link.match(/^(.*)#.*$/);
      link        = matched[1];
    }

    link = link.replace('?index=', '?qindex=');

    $.getJSON(link + '&quick=1&json=1&header=2', function (data) {

      if (data['_INFO']) {
        var message = '';

        if (data['_INFO']['__REPLY']) {
          var replies = data['_INFO']['__REPLY'];
          var reply_ids = [];
          for( var reply_id in replies) {
            if (!replies.hasOwnProperty(reply_id)) continue;
            reply_ids[reply_ids.length] = reply_id;
          }

          var last_id = reply_ids[reply_ids.length - 1];
          if (replies[last_id]['ADMIN_MSG']) {
            for(var i = reply_ids.length - 2; i >= 0; i++) {
              var id = reply_ids[i];
              if (!replies[id]['ADMIN_MSG']) {
                message = replies[id]['MESSAGE'];
                break;
              }
            }

            if (!message) {
              message = replies[last_id]['MESSAGE'];
            }
          }
          else {
            message = replies[last_id]['MESSAGE'];
          }
        }
        else {
          message = data['_INFO']['MESSAGE'];
        }
        callback(message);
      }
    }).fail(function (status, error) {
      if (error === "parsererror") {
        callback("Error processing data on server");
      }
    })
  }
} ());
