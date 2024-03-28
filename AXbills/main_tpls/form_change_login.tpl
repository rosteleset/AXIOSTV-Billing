<form method='POST' action='$SELF_URL' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='edit_login' value='%edit_login%'>
  <input type='hidden' name='UID' value='%UID%'>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{CHANGE}_ _{LOGIN}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='LOGIN'>_{LOGIN}_:</label>
        <div class='col-md-8'>
          <input required type='text' class='form-control' id='LOGIN' name='LOGIN' value='%LOGIN%'/>
          <div class='invalid-feedback'>
            _{USER_EXIST}_
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_ACTION%' value='%BTN_LNG%'>
    </div>
  </div>
</form>

<script TYPE='text/javascript'>
  'use strict';

  jQuery(function () {

    jQuery('#LOGIN').on('input', function () {
      var value = jQuery('#LOGIN').val();
      doDelayedSearch(value)
    });
  });

  var timeout = null;

  function doDelayedSearch(val) {
    if (timeout) {
      clearTimeout(timeout);
    }
    timeout = setTimeout(function () {
      doSearch(val);
    }, 500);
  }

  function doSearch(val) {
    if (!val) {
      jQuery('#LOGIN').removeClass('is-valid').addClass('is-invalid');
      return 1;
    }
    jQuery.post('$SELF_URL', 'header=2&get_index=' + 'check_login_availability' + '&login_check=' + val, function (data) {
      if (data === 'success') {
        jQuery('#LOGIN').removeClass('is-invalid').addClass('is-valid');
      } else {
        jQuery('#LOGIN').removeClass('is-valid').addClass('is-invalid');
      }

    });
  }

</script>
