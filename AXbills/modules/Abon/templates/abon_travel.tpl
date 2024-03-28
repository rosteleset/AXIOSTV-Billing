<input type='hidden' name='TRAVEL' value='1'>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='BEGINNING_DATE'>_{START}_:</label>
  <div class='col-sm-8 col-md-8'>
    %BEGINNING_DATE%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='ENDING_DATE'>_{END}_:</label>
  <div class='col-sm-8 col-md-8'>
    %ENDING_DATE%
  </div>
</div>

<div class='form-group row d-none'>
  <label class='col-sm-4 col-md-4 control-label required' for='MULTI_VISA_DAYS'>_{DURATION}_:</label>
  <div class='col-sm-8 col-md-8'>
    %MULTI_VISA_DAYS%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label' for='TRIPS_COUNT'>_{ABON_YEAR_POLICY}_:</label>
  <div class='col-sm-8 col-md-8'>
    <div class='form-check'>
      <input type='checkbox' class='form-check-input' id='TRIPS_COUNT' name='TRIPS_COUNT' value='1'>
    </div>
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='TRAVEL_AREA'>_{ABON_DIRECTION}_:</label>
  <div class='col-sm-8 col-md-8'>
    %TRAVEL_AREA%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='CLIENTS'>_{ABON_NUMBER_TOURISTS}_:</label>
  <div class='col-sm-8 col-md-8'>
    %CLIENTS%
  </div>
</div>

<div id='CLIENTS_AGE'></div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='INSURANCE_SUM'>_{ABON_INSURANCE_LIMIT}_:</label>
  <div class='col-sm-8 col-md-8'>
    %INSURANCE_SUM%
  </div>
</div>

<div class='form-group row'>
  <label class='col-sm-4 col-md-4 control-label required' for='PURPOSE'>_{ABON_TYPE_VACATION}_:</label>
  <div class='col-sm-8 col-md-8'>
    %PURPOSE%
  </div>
</div>

<script>
  jQuery(document).ready(function () {
    jQuery('#ACCEPT_LICENSE').parent().parent().remove();

    jQuery('#TRIPS_COUNT').on('change', function () {
      if (jQuery(this).is(':checked')) {
        jQuery('#MULTI_VISA_DAYS').parent().parent().removeClass('d-none');
        jQuery('#MULTI_VISA_DAYS').removeAttr('disabled')
        jQuery('#ENDING_DATE').parent().parent().parent().addClass('d-none');
        jQuery('#ENDING_DATE').attr('disabled', 'disabled')
      }
      else {
        jQuery('#MULTI_VISA_DAYS').parent().parent().addClass('d-none');
        jQuery('#MULTI_VISA_DAYS').attr('disabled', 'disabled')
        jQuery('#ENDING_DATE').parent().parent().parent().removeClass('d-none');
        jQuery('#ENDING_DATE').removeAttr('disabled')
      }
    })

    jQuery('#CLIENTS').on('change', function () {
      let client = jQuery(this).val();
      let ages = [];

      jQuery(`[name='CLIENT_BIRTH_YEAR']`).each(function () {
        if (jQuery(this).val()) ages.push(jQuery(this).val());
      });

      jQuery('#CLIENTS_AGE').html('');

      for (let i = 0; i < client; i++) {
        let client_id = i + 1;
        let client_birth_year = ages[i] || '';

        let label = jQuery(`<label class='col-sm-4 col-md-4 control-label required'>_{ABON_YEAR_BIRTH}_ ${client_id}_{ABON_N_CLIENT}_:</label>`);
        let date = jQuery(`<input name='CLIENT_BIRTH_YEAR' id='CLIENT_${client_id}_BIRTH_YEAR' value='${client_birth_year}' class='form-control datepicker'/>`)
        let date_col = jQuery(`<div class='col-sm-8 col-md-8'></div>`).append(date)
        let row = jQuery(`<div class='form-group row'></div>`).append(label).append(date_col);
        jQuery('#CLIENTS_AGE').append(row);

        jQuery(`#CLIENT_${client_id}_BIRTH_YEAR`).datepicker({
          format: 'yyyy',
          viewMode: 'years',
          minViewMode: 'years',
          startDate: '1900',
          endDate: new Date()
        });
      }
    });
    jQuery('#CLIENTS').change();

    jQuery('#BEGINNING_DATE').on('change', function () {
      let beginning_date = new Date(jQuery(this).val()).toISOString().substr(0, 10);
      let ending_date = new Date(jQuery('#ENDING_DATE').val()).toISOString().substr(0, 10);

      if (beginning_date >= ending_date) {
        let new_ending_date = new Date(ending_date);
        new_ending_date.setDate(new_ending_date.getDate() + 30);
        let date = new_ending_date.toISOString().substr(0, 10);

        jQuery('#ENDING_DATE').val(date);
      }
    });

    jQuery('#ENDING_DATE').on('change', function () {
      let beginning_date = new Date(jQuery('#BEGINNING_DATE').val()).toISOString().substr(0, 10);
      let ending_date = new Date(jQuery(this).val()).toISOString().substr(0, 10);

      if (beginning_date >= ending_date) {
        let new_ending_date = new Date(ending_date);
        new_ending_date.setDate(new_ending_date.getDate() + 30);
        let date = new_ending_date.toISOString().substr(0, 10);

        jQuery(this).val(date);
      }
    });
  });
</script>
