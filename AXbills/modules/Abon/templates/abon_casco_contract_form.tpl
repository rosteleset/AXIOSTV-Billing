<input type='hidden' name='PROGRAM_ID' value='%PROGRAM_ID%'>
<input type='hidden' name='PLUGIN_ID' value='%PLUGIN_ID%' id='PLUGIN_ID'>
<input type='hidden' name='CITY_ID' value='%CITY_ID%'>
<input type='hidden' name='ZONE_ID' value='%ZONE_ID%'>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='SURNAME'>_{FIO1}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='SURNAME' name='SURNAME' value='%SURNAME%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='NAME'>_{FIO2}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='NAME' name='NAME' value='%NAME%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='PATRONYMIC'>_{FIO3}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='PATRONYMIC' name='PATRONYMIC' value='%PATRONYMIC%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='INN'>_{INN}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='INN' name='INN' value='%INN%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='BIRTHDAY'>_{BIRTH_DATE}_:</label>
  <div class='col-sm-8 col-md-8'>
    %BIRTHDAY%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='PHONE'>_{CELL_PHONE}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='PHONE' name='PHONE' value='%PHONE%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='EMAIL'>E-mail:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='EMAIL' name='EMAIL' value='%EMAIL%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='ADDRESS'>_{ADDRESS}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='ADDRESS' name='ADDRESS' value='%ADDRESS%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='DOC_TYPE'>_{ABON_IDENTITY_DOCUMENT}_:</label>
  <div class='col-sm-8 col-md-8'>
    %DOC_TYPE%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='DOC_SERIAL_NUMBER'>_{ABON_DOCUMENT_SERIES_NUMBER}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='DOC_SERIAL_NUMBER' name='DOC_SERIAL_NUMBER' value='%DOC_SERIAL_NUMBER%' class='form-control' type='text'>
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
  <label class='col-sm-4 col-md-4 control-label' for='MARK'>_{ABON_VEHICLE_MAKE}_:</label>
  <div class='col-sm-8 col-md-8'>
    %MARK%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='MODEL'>_{ABON_TECHNICAL_CERTIFICATE}_:</label>
  <div class='col-sm-8 col-md-8' id='VEHICLE_MODEL_CONTAINER'>
    %MODEL%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='MAKE_YEAR'>_{ABON_VEHICLE_YEAR}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='MAKE_YEAR' name='MAKE_YEAR' value='%MAKE_YEAR%' placeholder='2023' class='form-control' type='number'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='VIN'>_{ABON_VEHICLE_VIN_NUMBER}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='VIN' name='VIN' value='%VIN%' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='PLATE_NUMBER'>_{ABON_LICENSE_NUMBER}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='PLATE_NUMBER' name='PLATE_NUMBER' value='%PLATE_NUMBER%' placeholder='AA0001AA' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='CAR_DOC'>_{ABON_TECHNICAL_PASSPORT_SERIES_NUMBER}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='CAR_DOC' name='CAR_DOC' value='%CAR_DOC%' placeholder='ABC012203' class='form-control' type='text'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='OTP'>OTP:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='OTP' name='OTP' value='%OTP%' class='form-control' type='text' readonly='readonly'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='FRANCHISE'>_{FRANCHISE}_:</label>
  <div class='col-sm-8 col-md-8'>
    <input id='FRANCHISE' name='FRANCHISE' value='%FRANCHISE%' class='form-control' type='text' readonly='readonly'>
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
      fetch(`/api.cgi/abon/plugin/${jQuery('#PLUGIN_ID').val()}/info?MARK_NAME=${brand_name}`, {
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
            let selectList = jQuery('<select></select>', {width: '100%', id: 'MODEL', name: 'MODEL'});

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
