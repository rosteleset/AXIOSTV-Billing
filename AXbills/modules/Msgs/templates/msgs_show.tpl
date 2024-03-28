<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='UID' value='$FORM{UID}'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='PARENT' value='%PARENT%'/>
  <input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
  <input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>

  <div class='row' style='word-wrap: break-word;'>
    <div class='col-md-9' id='reply_wrapper'>
      <div class='card card-outline %MAIN_PANEL_COLOR%'>
        <div class='card-header'>
          <h3 class='card-title'>
            <span
                class='badge badge-primary mr-1'
                data-tooltip='_{COPIED}_!'
                data-tooltip-onclick='1'
                data-tooltip-position='top'
                onclick='copyToBuffer("#%ID%")'
                style='font-size: inherit; margin: -.03em 0; cursor: pointer;'
            >
              #%ID%
            </span>
            %SUBJECT%
          </h3>
          <div class='card-tools'>
            %CHANGE_SUBJECT_BUTTON% %MSG_TAGS% %PARENT_MSG% %INNER_MSG_TAG% %RATING_ICONS%
          </div>
        </div>

        <div class='card-body text-left'>
          %MESSAGE%
          %PROGRESSBAR%
        </div>
        <div class='card-footer text-left'>
          %ATTACHMENT%
          <div class='row'>
            <div class='col-md-3'>_{AUTHOR}_: %LOGIN%</div>
          </div>
          <div class='row'>
            <div class='col-md-3'>_{STATUS}_: %STATE_NAME%</div>
            <div class='col-md-3'>_{PRIORITY}_: %PRIORITY_TEXT%</div>
          </div>
          <div class='row'>
            <div class='col-md-3'>_{CREATED}_: %DATE%</div>
            <div class='col-md-3'>_{CHAPTER}_: %CHAPTER_NAME%</div>
            <div class='col-md-6 text-right'>%QUOTING% %DELETE% %EDIT%</div>
          </div>
        </div>
      </div>

      <div class='timeline'>
        %REPLY%
        <div>
          %TIMELINE_LAST_ITEM%
        </div>
      </div>
      %REPLY_FORM%
      %WORKPLANNING%
    </div>
    <div class='col-md-3' id='ext_wrapper'>
      %EXT_INFO%
    </div>
  </div>
</form>

<script>
  var saveStr = '_{SAVE}_';
  var cancelStr = '_{CANCEL}_';
  var replyId = 0;
  var editedStr = '_{CHANGED}_';

  function save_reply(element) {
    var replyText = jQuery('.reply-edit').val();
    var date = new Date();
    var dateStr = date.toISOString().slice(0, 10) + ' ' + date.toTimeString().slice(0, 9) + "(%ADMIN_LOGIN%)";
    replyText = replyText + "\n\n\n" + editedStr + ": " + dateStr;
    var replyHtml = replyText.replace(/\</g, "&lt")
      .replace(/\>/g, "&gt")
      .replace(/\n/g, "<br />");

    jQuery(element).parent().html(replyHtml);
    jQuery.post('$SELF_URL', 'header=2&get_index=_msgs_edit_reply&edit_reply=' + replyId + '&replyText=' + replyText);
  }

  function edit_reply(element) {
    if (replyId == 0) {
      replyId = jQuery(element).attr('reply_id');
      var replyElement = jQuery(element).closest(".timeline-item").children(".timeline-body");

      if (!replyElement.length) {
        replyElement = jQuery(element).closest(".card").children(".card-body");
      }

      var oldReplyHtml = replyElement[0].innerHTML;
      var oldReply = replyElement[0].innerText;
      replyElement.html("")
        .append("<textarea class='form-control reply-edit w-100' rows='10'>" + oldReply + "</textarea>")
        .append("<button type='button' class='btn btn-default btn-xs reply-save group-btn'>" + saveStr + "</button>")
        .append("<button type='button' class='btn btn-default btn-xs reply-cancel group-btn'>" + cancelStr + "</button>");
      replyElement.children().first().focus();

      jQuery(".reply-save").click(function (event) {
        event.preventDefault();
        save_reply(this);
        jQuery(".quoting-reply-btn").attr('disabled', false);
        replyId = 0;
      });

      jQuery(".reply-cancel").click(function (event) {
        event.preventDefault();
        jQuery(this).parent().html(oldReplyHtml);
        jQuery(".quoting-reply-btn").attr('disabled', false);
        replyId = 0;
      });
    }
  }

  function quoting_reply(element) {
    let replyElement = jQuery(element).closest('.timeline-item').children('.timeline-body');
    let oldReply = replyElement[0].innerText;

    oldReply = oldReply.replace(/^/g, '> ');
    oldReply = oldReply.replace(/\n/g, '\n> ');

    jQuery('#REPLY_TEXT').val(oldReply);
  }

  jQuery(function () {
    jQuery(".reply-edit-btn").click(function (event) {
      event.preventDefault();
      jQuery(".quoting-reply-btn").attr('disabled', true);
      edit_reply(this);
    });

    jQuery(".quoting-reply-btn").click(function (event) {
      event.preventDefault();
      quoting_reply(this);
    });

    jQuery(".reply-body").each(function () {
      let oldText = jQuery(this).html();
      jQuery(this).html(decodeURI(oldText.replaceAll('\\%', '\%')));
    })
  });
</script>
