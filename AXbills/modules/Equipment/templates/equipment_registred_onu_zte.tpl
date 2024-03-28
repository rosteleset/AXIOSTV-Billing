<form action='%SELF_URL%' class='form' METHOD='GET'>
  <input type='hidden' name='index' value='%index%'>
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
        <label class='col-md-4 col-form-label text-md-right' for='VENDOR'>_{VENDOR}_:</label>
        <div class='col-md-8'>
          <input id='VENDOR' name='VENDOR' value='%VENDOR%' readonly class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LLID'>LLID:</label>
        <div class='col-md-8'>
          <input id='LLID' name='LLID' value='%LLID%' readonly class='form-control' type='text'>
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

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SN'>_{SERIAL}_:</label>
        <div class='col-md-8'>
          <input id='SN' name='SN' value='%SN%' readonly class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='VLAN_ID'>VLAN:</label>
        <div class='col-md-8'>
          %VLAN_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ONU_DESC'>_{DESCRIBE}_:</label>
        <div class='col-md-8'>
          <input id='ONU_DESC' name='ONU_DESC' value='' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TEMPLATE'>_{ONU_PROFILE}_:</label>
        <div class='col-md-8'>
          %TEMPLATE%
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='btn btn-primary float-left'>
    </div>
  </div>
</form>
