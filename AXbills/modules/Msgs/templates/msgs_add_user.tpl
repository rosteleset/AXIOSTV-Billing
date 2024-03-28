<form action='$SELF_URL' class='form-horizontal'>
  <input type=hidden name=index value='$index'>
  <input type=hidden name=LOCATION_ID value='%LOCATION_ID%'>
  <input type=hidden name=ADDRESS_FLAT value='%ADDRESS_FLAT%'>
  <input type=hidden name=NOTIFY_FN value='msgs_unreg_requests_list'>
  <input type=hidden name=NOTIFY_ID value='%ID%'>
  <input type=hidden name=add_user value='%ID%'>

  %EXT_FIELDS%

  <fieldset>

    <div class='card card-primary card-outline card-form'>
      <div class='card-header'>
        <h4 class='card-title'>_{ADD_USER}_</h4>
        <div class='card-tools float-right'>
          <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i></button>
        </div>
      </div>
      <div class='card-body'>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='ID'>#</label>
          <p class='form-control-static col-md-9'>%ID%</p>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='LOGIN'>_{LOGIN}_:</label>
          <div class=' col-md-9'>
            <input id='LOGIN' name='LOGIN' value='%LOGIN%' placeholder='%LOGIN%' class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='FIO'>_{FIO}_:</label>
          <div class=' col-md-9'>
            <input id='FIO' name='FIO' value='%FIO%' placeholder='%FIO%' class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='TP_ID'>_{TARIF_PLAN}_:</label>
          <div class='col-md-9'>
            %TP_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='GID'>_{GROUP}_:</label>
          <div class='col-md-9'>
            %GID_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='PHONE'>_{PHONE}_:</label>
          <div class='col-md-9'>
            <input id='PHONE' name='phone' value='%PHONE%' placeholder='%PHONE%' class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='EMAIL'>E-MAIL:</label>
          <div class='col-md-9'>
            <input id='EMAIL' name='email' value='%EMAIL%' placeholder='%EMAIL%' class='form-control' type='text'>
          </div>
        </div>

        %REFERRAL_TP%

      </div>
      <div class='card-footer'>
        <input id='REG_REQUEST_BTN' type='submit' class='btn btn-primary' name='add_user_' value='%ACTION_LNG%'>
      </div>

    </div>

  </fieldset>
</form>

<script>
//    jQuery('#REG_REQUEST_BTN').prop('disabled', true);

var timeout = null;

function doDelayedSearch(val) {
  if (timeout) {
    clearTimeout(timeout);
  }
  timeout = setTimeout(function() {
    doSearch(val); //this is your existing function
  }, 500);
};

function doSearch(val) {
  if(!val){
    jQuery('#REG_REQUEST_BTN').prop('disabled', true);
    jQuery('#LOGIN').parent().parent().removeClass('has-success').addClass('has-error');
    return 1;
  }
  jQuery.post('$SELF_URL', 'header=2&qindex=' + '%CHECK_LOGIN_INDEX%' + '&login_check=' + val, function (data) {
    console.log(data);
    if(data === 'success'){
      jQuery('#REG_REQUEST_BTN').prop('disabled', false);
      jQuery('#LOGIN').parent().parent().removeClass('has-error').addClass('has-success');
    }
    else{
      jQuery('#REG_REQUEST_BTN').prop('disabled', true);
      jQuery('#LOGIN').parent().parent().removeClass('has-success').addClass('has-error');
    }

  });
}
    jQuery('#LOGIN').on('input', function(){
      var value = jQuery('#LOGIN').val();
      doDelayedSearch(value)
    });
</script>