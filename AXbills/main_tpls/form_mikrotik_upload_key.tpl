<form action='$SELF_URL' method='post' id='FORM_UPLOAD_KEY_MIKROTIK' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='%RETURN_TO%' value='1'/>
  <input type='hidden' name='%RETURN_TO%' value='1'/>
  <input type='hidden' name='upload_key' value='1'/>
  <input type='hidden' name='NAS_ID' value='%NAS_ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4>Mikrotik SSH Key Upload</h4></div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='control-label col-md-3'>_{LOGIN}_</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='SYSTEM_ADMIN' id='SYSTEM_ADMIN' value='%SYSTEM_ADMIN%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3'>_{PASSWD}_</label>
        <div class='col-md-9'>
          <input class='form-control' type='password' name='SYSTEM_PASSWD' id='SYSTEM_PASSWD' value='%SYSTEM_LOGIN%'/>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='set' value='_{SET}_' id='go'>
      <button class='btn info' type='button' id='TEST_DATA'>_{TEST}_</button>
    </div>
  </div>
</form>

<script>
  'use strict';
  jQuery(function () {
    var test_button = jQuery('button#TEST_DATA');
    var admin       = jQuery('input#SYSTEM_ADMIN');
    var passwd      = jQuery('input#SYSTEM_PASSWD');

    test_button.on('click', function (e) {
      cancelEvent(e);

      jQuery.post('$SELF_URL', {
        qindex                : INDEX,
        header : 2,
        json : 1,
        mikrotik_check_access: 1,

        NAS_ID               : '%NAS_ID%',
        USERNAME             : admin.val(),
        PASSWORD             : passwd.val()
      }, function (data) {
        console.log(data);

        if (data && data['MESSAGE']){
          aTooltip.displayMessage(data['MESSAGE'], 3000);

          if (data['MESSAGE']['message_type'] === 'info'){
            jQuery('form#FORM_UPLOAD_KEY_MIKROTIK').submit();
          }
        }


      })
    })

  });
</script>