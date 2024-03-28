<form action='$SELF_URL' METHOD='POST' name='user' ID='user' class='pswd-confirm'>
  <input type=hidden name=sid value='$sid'>
  <input type=hidden name=ID value='%ID%'>
  <input type=hidden name=UID value='%UID%'>
  <input type=hidden name=m value='%m%'>
  <input type=hidden name='index' value='$index'>

  <div class='card card-outline card-primary'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{TARIF_PLANS}_</h4>
    </div>
    <div class='card-body form form-horizontal'>
      <div class='form-group row'>
        <label class='col-md-2 control-label'>_{CURRENT}_:</label>
        <label class='cold-md-10 control-label'>$user->{TP_ID} %TP_NAME% </label>
      </div>
      <div class='form-group row'>
        <label class='col-md-2 control-label'>_{CHANGE}_ _{ON}_:</label>
        <div class='col-md-10'>%TARIF_PLAN_TABLE%</div>
      </div>
      <div class='form-group row'>
        %PARAMS%
      </div>
      <div class='form-group row'>
        %SHEDULE_LIST%
      </div>

    </div>
    <div class='card-footer'>
      <div name='modalOpen_TP_CHG' class='btn btn-primary' id='modalOpen_TP_CHG'
           data-toggle='modal' data-target='#changeTPModal'>%LNG_ACTION%
      </div>
      <h5>%ERROR_DEL_SHEDULE%</h5>
    </div>
  </div>

  <div class='modal fade' id='changeTPModal'>
    <div class='modal-dialog'>
      <div class='modal-content'>
        <div class='modal-header'>
          <h4>_{CHANGE}_ _{TARIF_PLAN}_</h4>
          <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
              aria-hidden='true'>&times;</span></button>
        </div>

        <div class='modal-body'>
          <div class='form-group'>
            %CHG_TP_RULES%
          </div>
          <div class='form-group text-center'>
            <label class='control-label text-center' for='ACCEPT_RULES'>_{ACCEPT}_:</label>
            %ACTION_FLAG%
            <input type=checkbox value='1' id='ACCEPT_RULES' name='ACCEPT_RULES'>
          </div>
        </div>

        <div class='modal-footer'>
          <input type='submit' value='_{SET}_' name='%ACTION%' class='btn btn-primary' form='user'>
        </div>
      </div>
    </div>
  </div>
</form>

<script>
  if (!'%ACTION%') {
    jQuery("#modalOpen_TP_CHG").hide();
  }
</script>
