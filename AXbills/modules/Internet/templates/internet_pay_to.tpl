<form action='$SELF_URL' method='post' name=pay_to>

  <input type=hidden name='index' value='$index'>
  <input type=hidden name='UID' value='$FORM{UID}'>
  <input type=hidden name='SUM' value='%SUM%'>

  <div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'>
      <h4>_{PAY_TO}_</h4>
    </div>
    <div class='card-body form form-horizontal'>

      <div class='form-group'>
        <label class='control-label col-md-3' for='TI_ID'>_{TARIF_PLAN}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <span class='input-group-addon bg-primary'>%TP_ID%</span>
            <input type=text name='GRP' value='%TP_NAME%' ID='GRP' class='form-control' readonly>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='DATE'>_{DATE}_</label>
        <div class='col-md-9'>
          <input id='DATE' name='DATE' value='%DATE%' data-date-orientation='bottom' placeholder='%DATE%'
                 class='form-control datepicker' type='text' %DATE_READONLY%>
        </div>
      </div>

      <div class='form-group' data-visible='%SUM%'>
        <label class='control-label col-md-3' for='SUM'>_{SUM}_</label>
        <div class='col-md-9'>
          <h4>
            <span class='label label-primary  col-md-3' for='SUM'>%SUM%</span>
          </h4>
        </div>
      </div>

      <div class='form-group' data-visible='%SUM%'>
        <label class='control-label col-md-3' for='DAYS'>_{DAYS}_</label>
        <div class='col-md-9'>
          <h4>
            <label class='label label-success  col-md-3' for='SUM'>%DAYS%</label>
          </h4>
        </div>
      </div>

      <input type=submit name='pay_to' value='%ACTION_LNG%' class='btn btn-primary'>

    </div>
  </div>

</form>
