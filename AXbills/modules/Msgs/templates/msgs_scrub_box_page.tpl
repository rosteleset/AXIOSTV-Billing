<form action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='SCRUB_BOX' id='scrub_box'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' id='MSGS_INDEX' name='MSGS_INDEX' value='%MSGS_INDEX%'/>

  <nav class='navbar navbar-default'>
    <div class='container-fluid'>
      <div class='navbar-form navbar-left'>
        %STATUS_SELECT%
      </div>
      <div class='form-group navbar-form navbar-left'>
        <input class='btn btn-primary' type='submit' id='SEARCH' name='SEARCH' value='_{SEARCH}_'/>
      </div>
    </div>
  </nav>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SCRUB_BOX}_</h4>
    </div>
    <div class='card-body'>
      <div class='row'>
        %MSGS_BODY%
      </div>
    </div>
  </div>
</form>
<script>
  var index = jQuery('#MSGS_INDEX').val();
  var msgs_id = '';

  jQuery('.status').each((index, value) => {
    jQuery(value).height(jQuery(value).parent().height());
  });

  function dragStart(event) {
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('Text', event.target.getAttribute('id'));
    event.dataTransfer.setDragImage(event.target, 50, 50);

    msgs_id = event.srcElement.id;

    return true;
  }

  function dragEnter(event) {
    event.preventDefault();
    return true;
  }

  function dragOver(event) {
    event.preventDefault();
  }

  function dragDrop(event) {
    var data = event.dataTransfer.getData('Text');
    var stateId = event.srcElement.id;

    var uid = jQuery('#' + msgs_id).attr('user_id');

    if (!event.target.offsetParent.offsetParent.id) {
      if (!/drop_/.test(stateId)) {
        return 1;
      }
    } else {
      stateId = event.target.offsetParent.offsetParent.id;
    }

    if (msgs_id) {
      msgs_id = msgs_id.match(/[0-9]+/);
    } else {
      return 1;
    }

    if (stateId) {
      stateId = stateId.match(/[0-9]/);
    } else {
      return 1;
    }

    jQuery('#MSGS_' + msgs_id).removeClass();
    if (stateId == 1) {
      jQuery('#MSGS_' + msgs_id).addClass('card card-outline card-danger');
    } else if (stateId == 2) {
      jQuery('#MSGS_' + msgs_id).addClass('card card-outline card-success');
    } else if (stateId == 4) {
      jQuery('#MSGS_' + msgs_id).addClass('card card-outline card-warning');
    } else {
      jQuery('#MSGS_' + msgs_id).addClass('card card-outline card-info');
    }

    jQuery('.status').each((index, value) => {
      jQuery(value).height('auto');
    });

    if (!event.target.offsetParent.offsetParent.id) {
      event.target.appendChild(document.getElementById(data));
    } else {
      document.getElementById(event.target.offsetParent.offsetParent.id).appendChild(document.getElementById(data))
    }

    event.stopPropagation();

    let url = SELF_URL + '?index=' + index + '&UID=' + uid + '&ID=' + msgs_id[0] + '&reply=close&MAIN_INNER_MESSAGE=1&STATE=' + stateId[0];

    jQuery.ajax({
      url: url,
      type: 'get',
      data: data,
      contentType: false,
      cache: false,
      processData: false,
      success: function (data) {
      }
    });

    jQuery('.status').each((index, value) => {
      jQuery(value).height(jQuery(value).parent().height());
    });

    return false;
  }
</script>
