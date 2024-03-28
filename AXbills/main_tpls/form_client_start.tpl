<!--CLIENT START-->
<body class='sidebar-mini container-xl %SIDEBAR_HIDDEN% text-sm client-body p-0'>
%PUSH_STATE%
<script>
  try {
    var BACKGROUND_OPTIONS     = '%BACKGROUND_COLOR%' || false;
    var BACKGROUND_URL         = '%BACKGROUND_URL%' || false;
    var BACKGROUND_HOLIDAY_IMG = '%BACKGROUND_HOLIDAY_IMG%' || false;

    if (BACKGROUND_HOLIDAY_IMG) {
      var block = '<style>'
          + 'body {'
          + 'background-size : cover !important; \n'
          + 'background : url(' + BACKGROUND_HOLIDAY_IMG + ') no-repeat fixed !important; \n'
          + '}'
          + '</style>';
      jQuery('head').append(block);
    }
    else if (BACKGROUND_URL) {
      jQuery('body').css({
        'background': 'url(' + BACKGROUND_URL + ')'
      });
    }
    else if (BACKGROUND_OPTIONS) {
      jQuery('body').css({
        'background': BACKGROUND_OPTIONS
      });
    }

  } catch (Error) {
    console.log('Somebody pasted wrong parameters for \$conf{user_background} or \$conf{user_background_url}');
  }

  document['SELF_URL'] = '$SELF_URL';
  document['DOMAIN_ID'] = '%DOMAIN_ID%';

  jQuery(function () {
    if (typeof EVENT_PARAMS !== 'undefined' && AMessageChecker) {
      AMessageChecker.start(EVENT_PARAMS);
    }

    var ConfirmChanges = '%CONFIRM_CHANGES%' || false;
    if (ConfirmChanges) {
      var ButtonName  = '';
      var ButtonValue = '';
      var ButtonText  = '';
      jQuery(".pswd-confirm [type=submit]").click(function(e) {
        ButtonName  = jQuery(this).attr('name');
        ButtonValue = jQuery(this).attr('value');
      });

      jQuery('.pswd-confirm').on('submit', function(e) {
        var formId = jQuery(this).attr('id');
        if (typeof(formId) === 'undefined') {
          formId = 'undefid';
          jQuery(this).attr('id', formId);
        }
        if (jQuery('#modal_password').val() == '') {
          e.preventDefault();
          jQuery('#modal_password').attr('form', formId);
          jQuery('#modal_submit').attr('form', formId);
          jQuery('#modal_submit').attr('name', ButtonName);
          jQuery('#modal_submit').attr('value', ButtonValue);
          jQuery('.modal').modal('hide');
          jQuery('#passwordModal').modal('show');
        }
      });
    }
  });
</script>
<!--Color-->
<div id='primary' class='bg-primary hidden'></div>
<div class='modal fade' id='comments_add' tabindex='-1' role='dialog'>
  <form id='mForm'>
    <div class='modal-dialog modal-sm'>
      <div class='modal-content'>
        <div id='mHeader' class='modal-header alert-default-info'>
          <h4 id='mTitle' class='modal-title'>&nbsp;</h4>
          <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>&times;</button>
        </div>
        <div class='modal-body'>
          <div class='row'>
            <input type='text' class='form-control' id='mInput' placeholder='_{COMMENTS}_'>
          </div>
        </div>
        <div class='modal-footer'>
          <button type='button' class='btn btn-default' data-dismiss='modal'>_{CANCEL}_</button>
          <button type='submit' class='btn btn-danger danger' id='mButton_ok'>_{EXECUTE}_!</button>
        </div>
      </div>
    </div>
  </form>
</div>

<!-- Password modal -->
<div id='passwordModal' class='modal fade' role='dialog'>
  <div class='modal-dialog'>
    <div class='modal-content'>
      <div class='modal-header'>
        <h4 class='modal-title'>_{CONFIRM_CHANGES}_</h4>
        <button type='button' class='close' data-dismiss='modal'>&times;</button>
      </div>
      <div class='modal-body'>
        <div class='form-group'>
          <input type='text' name='PASSWORD' id='modal_password' class='form-control'>
        </div>
      </div>
      <div class='modal-footer'>
        <input type='submit' class='btn btn-primary' id='modal_submit'>
      </div>
    </div>
  </div>
</div>


<div class='wrapper'>
  <!-- Modal search -->
  <div class='modal fade' tabindex='-1' id='PopupModal' role='dialog' aria-hidden='true'>
    <div class='modal-dialog'>
      <div id='modalContent' class='modal-content'></div>
    </div>
  </div>

  %BODY%