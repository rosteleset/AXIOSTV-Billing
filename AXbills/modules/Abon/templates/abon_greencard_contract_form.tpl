<input type='hidden' name='PLUGIN_ID' value='%PLUGIN_ID%' id='PLUGIN_ID'>
<input type='hidden' name='CAR_TYPE' value='%CAR_TYPE%'>
<input type='hidden' name='PERIOD_ID' value='%PERIOD_ID%'>
<input type='hidden' name='ZONE_ID' value='%ZONE_ID%'>
<input type='hidden' name='CALCULATION_ID' value='%CALCULATION_ID%'>
<input type='hidden' name='COMPANY_ID' value='%COMPANY_ID%'>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='LAST_NAME'>_{FIO1}_ (_{ABON_LATIN_ALPHABET}_):</label>
  <div class='col-sm-8 col-md-8'>
    <input id='LAST_NAME' name='LAST_NAME' required data-check-for-pattern='^[A-Za-z]+\$'
           value='%LAST_NAME%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='FIRST_NAME'>_{FIO2}_ (_{ABON_LATIN_ALPHABET}_):</label>
  <div class='col-sm-8 col-md-8'>
    <input id='FIRST_NAME' name='FIRST_NAME' required data-check-for-pattern='^[A-Za-z]+\$'
           value='%FIRST_NAME%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='PHONE'>_{CELL_PHONE}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='PHONE_PATTERN_FIELD' name='PHONE_PATTERN_FIELD' value='%PHONE_PATTERN_FIELD%' required
           placeholder='_{PHONE}_' class='form-control' data-phone-field='PHONE'
           data-check-phone-pattern='%PHONE_NUMBER_PATTERN%' type='text' autocomplete='off'>
    <input id='PHONE' name='PHONE' value='' class='form-control' type='hidden'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='EMAIL'>E-mail:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='EMAIL' name='EMAIL' value='%EMAIL%' required class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='ADDRESS'>_{ADDRESS}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='ADDRESS' name='ADDRESS' value='%ADDRESS%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-md-4 col-form-label text-md-right required' for='CLIENT_TYPE'>_{ABON_CUSTOMER_TYPE}_:</label>
  <div class='col-md-8'>
    %CLIENT_TYPE%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='RESIDENT'>_{ABON_RESIDENT}_:</label>
  <div class='col-sm-8 col-md-8'>
    <div class='form-check'>
      <input type='checkbox' class='form-check-input' id='RESIDENT' name='RESIDENT' %RESIDENT% value='1'>
    </div>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='INN'>_{INN}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='INN' name='INN' value='%INN%' required class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='BIRTHDAY'>_{BIRTH_DATE}_:</label>
  <div class='col-sm-8 col-md-8'>
    %BIRTHDAY%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='MARK_NAME'>_{ABON_VEHICLE_MAKE}_:</label>
  <div class='col-sm-8 col-md-8'>
    %MARK_NAME%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='MODEL_NAME'>_{ABON_TECHNICAL_CERTIFICATE}_:</label>
  <div class='col-sm-8 col-md-8' id='VEHICLE_MODEL_CONTAINER'>
    %MODEL_NAME%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='PROD_YEAR'>_{ABON_VEHICLE_YEAR}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='PROD_YEAR' name='PROD_YEAR' value='%PROD_YEAR%' required placeholder='2023' class='form-control' type='number'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='VIN'>_{ABON_VEHICLE_VIN_NUMBER}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='VIN' name='VIN' value='%VIN%' required class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='REG_NUMBER'>_{ABON_LICENSE_NUMBER}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='REG_NUMBER' name='REG_NUMBER' required value='%REG_NUMBER%' placeholder='AA0001AA' class='form-control' type='text'>
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
  <label class='col-sm-4 col-md-4 control-label' for='DOC_SUED_BY'>_{ABON_DOCUMENT_ISSUED}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='DOC_SUED_BY' name='DOC_SUED_BY' value='%DOC_SUED_BY%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='DOC_SUE_DATE'>_{ABON_DOCUMENT_DATE_ISSUED}_:</label>
  <div class='col-sm-8 col-md-8'>
    %DOC_SUE_DATE%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='PRICE'>_{PRICE}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='PRICE' name='PRICE' value='%PRICE%' class='form-control' type='text' readonly='readonly'>
  </div>
</div>

<script>
  jQuery(document).ready(function () {
    jQuery('#MARK').on('change', function() {
      let brand_name = jQuery(this).val();
      if (!brand_name) return;

      jQuery('#MODEL').attr('disabled', true);
      fetch(`/api.cgi/abon/plugin/${jQuery('#PLUGIN_ID').val()}/info?&MARK_NAME=${brand_name}`, {
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
            let selectList = jQuery('<select></select>', {width: '100%', id: 'MODEL', name: 'MODEL', required: 'required'});

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
