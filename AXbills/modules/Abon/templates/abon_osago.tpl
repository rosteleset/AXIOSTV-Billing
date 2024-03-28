<input type='hidden' name='OSAGO_STEP' value='1'>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='CAR_TYPE'>_{ABON_VEHICLE_TYPE}_:</label>
  <div class='col-sm-8 col-md-8'>
    %CAR_TYPE%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='CAR_REG_TYPE'>_{ABON_ZONE_OF_CITY}_:</label>
  <div class='col-sm-8 col-md-8'>
    %CAR_REG_ZONE%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='PRIVILEGE_TYPE'>_{ABON_BENEFITS}_:</label>
  <div class='col-sm-8 col-md-8'>
    %PRIVILEGE_TYPE%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='TAXI'>_{ABON_CAB}_:</label>
  <div class='col-sm-8 col-md-8'>
    <div class='form-check'>
      <input type='checkbox' class='form-check-input' id='TAXI' name='TAXI' %TAXI% value='1'>
    </div>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='OTK_NEXT_DATE'>_{ABON_GTC_DATE}_:</label>
  <div class='col-sm-8 col-md-8'>
    <div class='input-group'>
      <div class='input-group-prepend'>
        <span class='input-group-text'>
          <input type='checkbox' id='OTK_NEXT_DATE_CHECKBOX' name='OTK_NEXT_DATE_CHECKBOX' class='form-control-static'
                 data-input-enables='OTK_NEXT_DATE'/>
        </span>
      </div>
      %OTK_NEXT_DATE%
    </div>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='NOT_PASS_OTK'>_{ABON_NOT_PASS_INSPECTION}_:</label>
  <div class='col-sm-8 col-md-8'>
    <div class='form-check'>
      <input type='checkbox' class='form-check-input' id='NOT_PASS_OTK' name='NOT_PASS_OTK' %NOT_PASS_OTK% value='1'>
    </div>
  </div>
</div>

<div class='form-group row'>
  <label class='col-md-4 col-form-label text-md-right required' for='CLIENT_TYPE'>_{ABON_CUSTOMER_TYPE}_:</label>
  <div class='col-md-8'>
    %CLIENT_TYPE%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='REG_NUMBER'>_{ABON_LICENSE_NUMBER}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='REG_NUMBER' name='REG_NUMBER' required value='%REG_NUMBER%' placeholder='AA0001AA' class='form-control' type='text'>
  </div>
</div>

<script>
  jQuery(document).ready(function () {
    jQuery('#ACCEPT_LICENSE').parent().parent().remove();
  });
</script>
