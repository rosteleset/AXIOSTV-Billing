<div class='row'>
  <div class='col-md-6'>
    <div class='card card-primary card-outline'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{USERS_OUTFLOW}_: _{BUILDS}_</h4>
      </div>
      <div class='card-body'>
        %BUILDS_OUTFLOW%
      </div>
    </div>
  </div>
  <div class='col-md-6'>
    <div class='card card-primary card-outline'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{USERS_OUTFLOW}_: _{STREETS}_</h4>
      </div>
      <div class='card-body'>
        %STREETS_OUTFLOW%
      </div>
    </div>
  </div>
</div>

<script>
  jQuery(function () {
    let street_select = jQuery('#STREET_ID');
    let build_select = jQuery('#BUILD_ID');

    jQuery('#DISTRICT_ID').on('change', function () {
      street_select.attr('disabled', 'disabled');

      let district_id = jQuery(this).val();
      district_id = district_id ? district_id : '_SHOW';

      fetch(`/api.cgi/streets?DISTRICT_ID=${district_id}&DISTRICT_NAME=_SHOW`)
        .then(response => {
          if (!response.ok) throw response;
          return response;
        })
        .then(response => response.json())
        .then(data => {
          street_select.html('');

          if (data.length < 1) return 1;

          feelOptionGroup(street_select, data, 'districtId', 'districtName', 'streetName');

          let feel_options = street_select.find('option[value!=""]').length;
          if (feel_options > 0) {
            initChosen();
            street_select.focus().select2('open');
          }
          street_select.removeAttr('disabled');
        });
    });

    street_select.on('change', function () {
      let street_id = jQuery(this).val();
      if (!street_id ||street_id === '0') return;

      build_select.attr('disabled', 'disabled');

      fetch(`/api.cgi/builds?STREET_ID=${street_id}&STREET_NAME=_SHOW`, {
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
          build_select.html('');
          if (data.length < 1) return 1;

          feelOptionGroup(build_select, data, 'streetId', 'streetName', 'number');

          let feel_options = build_select.find('option[value!=""]').length;
          if (feel_options > 0) {
            initChosen();
            build_select.focus().select2('open');
          }
          build_select.removeAttr('disabled');
        });
    });

    function feelOptionGroup (select, data, groupKey, groupLabel, optionName) {
      let default_option = jQuery('<option></option>', {value: '', text: '--'});
      select.append(default_option);

      let optgroups = {};
      data.forEach(address => {
        if (!optgroups[address[groupKey]]) {
          optgroups[address[groupKey]] = jQuery(`<optgroup label='== ${address[groupLabel]} =='></optgroup>`);
        }

        let option = jQuery('<option></option>', {value: address.id, text: address[optionName]});
        optgroups[address[groupKey]].append(option);
      });

      jQuery.each(optgroups, function(key, value) { select.append(value);});
    }
  });
</script>