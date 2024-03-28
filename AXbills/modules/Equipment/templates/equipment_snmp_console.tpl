<form action='$SELF_URL'>
  <input type='hidden' name='index' value='$index'>

  <div class='card card-primary card-outline box-form form-horizontal'>
      <div class='card-header'>
        <h4 class="card-title">SNMP _{INFO}_</h4>
      </div>
      <div class='card-body'>
        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='SNMP_HOST'>SNMP Host</label>
          <div class='col-sm-10'>
            <input class='form-control' type='text' name='SNMP_HOST' value='%SNMP_HOST%'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='SNMP_COMMUNITY'>SNMP Community</label>
          <div class='col-sm-10'>
            <input class='form-control' type='text' name='SNMP_COMMUNITY' value='%SNMP_COMMUNITY%'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label'>_{NAS}_</label>
          <div class='col-sm-10' style="padding-right: 65px;">
            %NAS_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label' for='SNMP_OID'>SNMP OID</label>
          <div class='col-sm-10'>
            <input class='form-control' type='text' name='SNMP_OID' value='%SNMP_OID%'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label'>_{TYPE}_</label>
          <div class='col-sm-10'>
            %TYPE_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label'>DEBUG</label>
          <div class='col-sm-10'>
            %DEBUG_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-sm-2 col-form-label'>MIBS</label>
          <div class='col-sm-10'>
            %MIBS%
          </div>
        </div>
      </div>

      <div class='card-footer'>
        <input class='btn btn-primary' type='submit' name='SHOW' value='_{SHOW}_'>
      </div>
  </div>
</form>
