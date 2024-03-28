<input type='hidden' name='OSAGO' value='1'>
<input type='hidden' name='PLUGIN_ID' value='%PLUGIN_ID%' id='PLUGIN_ID'>
<input type='hidden' name='CAR_TYPE' value='%CAR_TYPE%'>
<input type='hidden' name='REG_ID' value='%REG_ID%'>
<input type='hidden' name='PRIVILEGE' value='%PRIVILEGE%'>
<input type='hidden' name='TAXI' value='%TAXI%'>
<input type='hidden' name='OTK_NEXT_DATE' value='%OTK_NEXT_DATE%'>
<input type='hidden' name='NOT_PASS_OTK' value='%NOT_PASS_OTK%'>
<input type='hidden' name='CLIENT_TYPE' value='%CLIENT_TYPE%'>
<input type='hidden' name='PROGRAM_ID' value='%PROGRAM_ID%'>
<input type='hidden' name='COSTS' value='%COSTS%'>
<input type='hidden' name='DGO_TARIFF' value='%DGO_TARIFF%'>
<input type='hidden' name='DGO_INSURE_SUM' value='%DGO_INSURE_SUM%'>
<input type='hidden' name='DGO_PAY_SUM' value='%DGO_PAY_SUM%'>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='MARK_NAME'>_{ABON_VEHICLE_MAKE}_:</label>
  <div class='col-sm-8 col-md-8'>
    %MARK_NAME%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='MODEL_NAME'>_{ABON_TECHNICAL_CERTIFICATE}_:</label>
  <div class='col-sm-8 col-md-8' id='VEHICLE_MODEL_CONTAINER'>
    %MODEL_NAME%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='PROD_YEAR'>_{ABON_VEHICLE_YEAR}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='PROD_YEAR' name='PROD_YEAR' value='%PROD_YEAR%' placeholder='2023' class='form-control' type='number'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='VIN'>_{ABON_VEHICLE_VIN_NUMBER}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='VIN' name='VIN' value='%VIN%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='REG_NUMBER'>_{ABON_LICENSE_NUMBER}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='REG_NUMBER' name='REG_NUMBER' value='%REG_NUMBER%' placeholder='AA0001AA' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='LAST_NAME'>_{FIO1}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='LAST_NAME' name='LAST_NAME' required value='%LAST_NAME%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='FIRST_NAME'>_{FIO2}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='FIRST_NAME' name='FIRST_NAME' required value='%FIRST_NAME%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='MIDDLE_NAME'>_{FIO3}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='MIDDLE_NAME' name='MIDDLE_NAME' required value='%MIDDLE_NAME%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='PHONE'>_{CELL_PHONE}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='PHONE' name='PHONE' value='%PHONE%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='EMAIL'>E-mail:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='EMAIL' name='EMAIL' value='%EMAIL%' required class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='ADDR'>_{ADDRESS}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='ADDR' name='ADDR' value='%ADDR%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='BIRTHDAY'>_{BIRTH_DATE}_:</label>
  <div class='col-sm-8 col-md-8'>
    %BIRTHDAY%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='INN'>_{INN}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='INN' name='INN' value='%INN%' required class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='DOC_TYPE'>_{ABON_IDENTITY_DOCUMENT}_:</label>
  <div class='col-sm-8 col-md-8'>
    %DOC_TYPE%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='SERIES'>_{ABON_DOCUMENT_SERIES}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='SERIES' name='SERIES' value='%SERIES%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='NUMBER'>_{ABON_DOCUMENT_NUMBER}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='NUMBER' name='NUMBER' value='%NUMBER%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='ISSUER'>_{ABON_DOCUMENT_ISSUED}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='ISSUER' name='ISSUER' value='%ISSUER%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='DATE_ISSUED'>_{ABON_DOCUMENT_DATE_ISSUED}_:</label>
  <div class='col-sm-8 col-md-8'>
    %DATE_ISSUED%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='OTP'>OTP:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='OTP' name='OTP' value='%OTP%' class='form-control' type='text' readonly='readonly'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='FULL_COST'>_{PRICE}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='FULL_COST' value='%FULL_COST%' class='form-control' type='text' readonly='readonly'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='DGO'>_{ADDITIONAL_COVERAGE}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='DGO' value='%DGO%' class='form-control' type='text' readonly='readonly'>
  </div>
</div>

<script>
  jQuery(document).ready(function () {
    jQuery('#MARK_NAME').on('change', function() {
      let brand_name = jQuery(this).val();
      if (!brand_name) return;

      jQuery('#MODEL_NAME').attr('disabled', true);
      fetch(`/api.cgi/abon/plugin/${jQuery('#PLUGIN_ID').val()}/info?OSAGO=1&MARK_NAME=${brand_name}`, {
        mode: 'cors',
        credentials: 'same-origin',
        headers: {'Content-Type': 'application/json'},
        redirect: 'follow',
        referrerPolicy: 'no-referrer',
      })
        .then(response => {
          if (!response.ok) throw response;
          return response;
        })
        .then(response => response.json())
        .then(data => {
          if (data.models) {
            let selectList = jQuery('<select></select>', {width: '100%', id: 'MODEL_NAME', name: 'MODEL_NAME'});

            data.models.forEach(function(model) {
              let option = jQuery('<option></option>', {value: model, text: model});
              selectList.append(option);
            });

            jQuery('#VEHICLE_MODEL_CONTAINER').html('').append(selectList);
            selectList.select2();
            return;
          }
          jQuery('#VEHICLE_MODEL_CONTAINER').html('');
        })
        .catch(err => {
          console.log(err);
          jQuery('#VEHICLE_MODEL_CONTAINER').html('');
        });
    });
  });
</script>
