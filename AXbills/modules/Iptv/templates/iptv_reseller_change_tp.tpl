<form class='form-horizontal' action='$SELF_URL' name='reseller_users' METHOD='POST'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='UID' value='%UID%'>
  
  <div class='card card-primary card-outline box-big-form'>
    <div class='card-header with-border'><h3 class="card-title">_{CHANGE}_ _{TP}_</h3>
      <div class="card-tools float-right">
      </div>
    </div>

    <div class="card-body">

      <div class='form-group' >
        <label class='control-label col-xs-3' for='TP_ID'>_{TARIF_PLAN}_</label>
        <div class='col-xs-9'>
          %TP_ADD%
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='IPTV_ACTIVATE'>_{ACTIVATE}_:</label>
        <div class='col-md-3'>
          <input id='IPTV_ACTIVATE' name='IPTV_ACTIVATE' value='%IPTV_ACTIVATE%'
                 placeholder='%IPTV_ACTIVATE%' class='datepicker form-control' type='text'>
        </div>
        <label class='control-label col-md-2' for='IPTV_EXPIRE'>_{EXPIRE}_:</label>
        <div class='col-md-4'>
          <input id='IPTV_EXPIRE' name='IPTV_EXPIRE' value='%IPTV_EXPIRE%'
                 placeholder='%IPTV_EXPIRE%' class='datepicker form-control' type='text'>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>

</form>