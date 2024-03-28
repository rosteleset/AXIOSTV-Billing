<form action='$SELF_URL' class='form form-horizontal' METHOD='GET'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
  <input type='hidden' name='TYPE' value='$FORM{TYPE}'>
  <input type='hidden' name='visual' value='$FORM{visual}'>
  <input type='hidden' name='unregister_list' value='$FORM{unregister_list}'>
  <input type='hidden' name='reg_onu' value='$FORM{reg_onu}'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'> _{REGISTRATION}_ ONU</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PON_TYPE'>PON _{TYPE}_:</label>
        <div class='col-md-8'>
          <input id='PON_TYPE' name='PON_TYPE' value='%PON_TYPE%' readonly class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='BRANCH'>BRANCH:</label>
        <div class='col-md-8'>
          <input id='BRANCH' name='BRANCH' value='%BRANCH%' readonly class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MAC'>MAC:</label>
        <div class='col-md-8'>
          <input id='MAC' name='MAC' value='%MAC%' readonly class='form-control' type='text'>
        </div>
      </div>

      <!--
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='VLAN'>VLAN:</label>
        <div class='col-md-8'>
          <input id='VLAN' name='VLAN' value='%VLAN%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='PORT'>_{PORT}_:</label>
        <div class='col-md-8'>
          <input id='PORT' name='PORT' value='%PORT%' class='form-control' type='text'>
        </div>
      </div>
      -->

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ONU_TEMPLATE'>_{TEMPLATE}_:</label>
        <div class='col-md-8'>
          %ONU_TEMPLATE%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ONU_DESC'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <input type='text' name='ONU_DESC' value='%ONU_DESC%' id='ONU_DESC' class='form-control'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary float-left'>
    </div>
  </div>
</form>
