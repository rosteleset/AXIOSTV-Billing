<FORM action='$SELF_URL' METHOD='POST' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='ID' value='%ID%'>
  <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
  <input type='hidden' name='visual' value='%visual%'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{PORT}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PORT'>_{PORT}_:</label>
        <div class='col-md-8'>
          <input type='text' name='PORT' value='%PORT%' class='form-control' ID='PORT'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='STATUS'>Admin _{STATUS}_:</label>
        <div class='col-md-4 mb-3 mb-md-0'>
          %STATUS_SEL%
        </div>

        <label class='col-md-2 col-form-label text-md-right' for='SNMP' data-tooltip='_{PORT_STATUS_SNMP_TOOLTIP}_' data-tooltip-position='top'>SNMP:</label>
        <div class='col-md-2 mb-3 mb-md-0'>
          <div class='form-check'>
            <input type='checkbox' class='form-check-input' id='SNMP' name='SNMP' checked>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='UPLINK'>UPLINK:</label>
        <div class='col-md-8'>
          %UPLINK_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='VLAN'>VLAN:</label>
        <div class='col-md-8'>
          <input type='text' name='VLAN' value='%VLAN%' class='form-control' ID='VLAN'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <input type='text' name='COMMENTS' value='%COMMENTS%' class='form-control' ID='COMMENTS'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <button type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary float-left'>%ACTION_LNG%</button>
    </div>
  </div>
</FORM>

