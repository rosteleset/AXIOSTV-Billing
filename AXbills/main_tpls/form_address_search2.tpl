<div class='form-address'>
  <input type='hidden' name='LOCATION_ID' id='ADD_LOCATION_ID' value='%LOCATION_ID%' class='HIDDEN-BUILD'>
  <input type='hidden' name='MAPS_SHOW_OBJECTS' id='MAPS_SHOW_OBJECTS' value='%MAPS_SHOW_OBJECTS%'>

  <div class='form-group row' style='%EXT_SEL_STYLE%'>
    <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-DISTRICT'>_{DISTRICTS}_:</label>
    <div class='col-sm-9 col-md-8'>
      %ADDRESS_DISTRICT%
    </div>
  </div>

  <div class='form-group row' style='%EXT_SEL_STYLE%'>
    <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-STREET'>_{ADDRESS_STREET}_:</label>
    <div class='col-sm-9 col-md-8'>
      %ADDRESS_STREET%
    </div>
  </div>

  <div class='form-group row' style='%EXT_SEL_STYLE% %HIDE_BUILD%'>
    <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-BUILD'>_{ADDRESS_BUILD}_:</label>
    <div class='col-sm-9 col-md-8'>
      <div class='addBuildMenu'>
        %ADDRESS_BUILD%
        <div class='invalid-feedback'></div>
      </div>

      <div class='input-group changeBuildMenu' style='display : none;'>
        <input type='text' disabled id='ADD_ADDRESS_BUILD_ID' %BUILD_REQ% name='ADD_ADDRESS_BUILD' class='ADD_ADDRESS_BUILD form-control INPUT-ADD-BUILD'/>
        <div class='input-group-append'>
          <div class='input-group-text'>
            <a class='BUTTON-ENABLE-SEL cursor-pointer'>
              <span class='fa fa-list'></span>
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class='form-group row' style='%HIDE_FLAT%'>
    <label class='col-sm-3 col-md-4 col-form-label text-md-right' for='ADDRESS_FLAT'>_{ADDRESS_FLAT}_:</label>
    <div class='col-sm-9 col-md-8'>
      <input type='text' id='ADDRESS_FLAT' name='ADDRESS_FLAT' value='%ADDRESS_FLAT%' class='form-control INPUT-FLAT'>
      <div class='invalid-feedback'></div>
    </div>
  </div>

  %EXT_ADDRESS%

  <div class='float-right'>
    %ADDRESS_ADD_BUTTONS%
    %MAP_BTN%
    %DOM_BTN%
    <span id='map_add_btn' style='display: none'>%MAPS_BTN%</span>
  </div>
</div>

<script>
  document['FLAT_CHECK_FREE']     = '%FLAT_CHECK_FREE%' || "1";
  document['FLAT_CHECK_OCCUPIED'] = '%FLAT_CHECK_OCCUPIED%' || "0";
</script>
<script>
  jQuery(function () {
    jQuery(document).on('keypress', 'span.select2', function (e) {
      if (e.originalEvent) jQuery(this).siblings('select').select2('open');
    });
  });

  document.addEventListener('district-change', function(event) {
    GetStreets(event.detail.district);
  });

  function GetStreets(data) {
    let street = jQuery("#%STREET_ID%");
    street.attr('disabled', 'disabled');

    let district_id = jQuery(data).val();
    district_id = district_id ? district_id : '_SHOW';

    fetch(`/api.cgi/streets?DISTRICT_ID=${district_id}&DISTRICT_NAME=_SHOW&PAGE_ROWS=1000000`, {
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
        street.html('');

        if (data.length < 1) return 1;

        feelOptionGroup(street, data, 'districtId', 'districtName', 'streetName');

        let feel_options = street.find('option[value!=""]').length;
        if (feel_options > 0) initChosen();
        if (!jQuery(data).prop('multiple') && feel_options > 0) street.focus().select2('open');
        street.removeAttr('disabled');
      });
  }

  function GetBuilds(data) {
    let build = jQuery('#%BUILD_ID%');
    build.attr('disabled', 'disabled');
    let street_id = jQuery(data).val();
    if (Array.isArray(street_id) && street_id.length > 1) street_id = street_id.join(';');

    if (!street_id || street_id == 0) {
      street_id = 0;
      jQuery('#ADD_LOCATION_ID').attr('value', '');
    }

    fetch(`/api.cgi/builds?STREET_ID=${street_id}&STREET_NAME=_SHOW&PAGE_ROWS=1000000`, {
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
        build.html('');
        if (data.length < 1) return 1;

        feelOptionGroup(build, data, 'streetId', 'streetName', 'number');

        let feel_options = build.find('option[value!=""]').length;
        if (feel_options > 0) initChosen();

        if (jQuery('#ADD_ADDRESS_BUILD_ID').is(':disabled')) {
          if (!jQuery(data).prop('multiple') && feel_options > 0) build.focus().select2('open');
          build.removeAttr('disabled');
        }
      });
  }

  //Get location_id after change build
  var item = '';
  function GetLoc(data) {
    item = jQuery(data).val();

    if (item == '--') item = '';

    if (jQuery('#MAPS_SHOW_OBJECTS').val()) {
      if (item && item !== '0') {
        jQuery('#map_add_btn').fadeIn(300);
        getObjectToMap();
      } else
        jQuery('#map_add_btn').fadeOut(200);
    }

    jQuery('#ADD_LOCATION_ID').attr('value', item);
    setTimeout(function () {
      jQuery('.INPUT-FLAT').focus();
    }, 100);
    jQuery('#ADDRESS_FLAT.INPUT-FLAT').trigger('input');
  }

  let selected_builds = jQuery('#ADD_LOCATION_ID').attr('value');
  if (selected_builds && !item && jQuery('#MAPS_SHOW_OBJECTS').val()){
    item = selected_builds;
    jQuery('#map_add_btn').fadeIn(300);
    getObjectToMap();
  }

  function getObjectToMap() {
    let url = '$SELF_URL?header=2&get_index=form_address_select2&PRINT_BUTTON=1&MAP_BUILT_BTN=' + item;
    fetch(url)
      .then(function (response) {
        if (!response.ok)
          throw Error(response.statusText);

        return response;
      })
      .then(function (response) {
        return response.text();
      })
      .then(result => async function (result) {
        jQuery('#map_add_btn').html(result);
      }(result));
  }

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

  function activateBuildButtons() {
    //Changing select to input
    jQuery('.BUTTON-ENABLE-ADD').on('click', function () {
      let buildDiv = jQuery('.addBuildMenu');
      buildDiv.removeClass('d-block');
      buildDiv.addClass('d-none');
      buildDiv.find('select').attr('disabled', 'disabled');
      jQuery('.ADD_ADDRESS_BUILD').removeAttr('disabled');

      jQuery('.changeBuildMenu').show();
      jQuery('#map_add_btn').fadeOut(300);
    });

    //Changing input to select
    jQuery('.BUTTON-ENABLE-SEL').on('click', function () {
      let buildDiv = jQuery('.addBuildMenu');
      buildDiv.removeClass('d-none');
      buildDiv.addClass('d-block');
      buildDiv.find('select').removeAttr('disabled');
      jQuery('.ADD_ADDRESS_BUILD').attr('disabled', 'disabled');

      jQuery('.changeBuildMenu').hide();
    })
  }

  activateBuildButtons();

  jQuery('#ADDRESS_FLAT.INPUT-FLAT').on('input', function () {
    let check_flat = '%CHECK_ADDRESS_FLAT%';
    if (check_flat.length === 0) return;

    let build_id = jQuery('#%BUILD_ID%').val();
    if (!build_id) return;

    let build_input = jQuery('#%BUILD_ID%').parent().parent().parent();
    build_input.removeClass('is-invalid').removeClass('is-valid').removeClass('form-control h-100 p-0');

    let flat_input = jQuery(this);
    flat_input.removeClass('is-invalid').removeClass('is-valid');
    let flat = flat_input.val() || '';

    let uid = `!${jQuery(`[name='UID']`).first().val()}`;

    if (typeof timeout !== 'undefined' && timeout) {
      clearTimeout(timeout);
    }
    timeout = setTimeout(function () {
      sendRequest(`/api.cgi/users/all?PAGE_ROWS=1&ADDRESS_FLAT=${flat}&LOCATION_ID=${build_id}&UID=${uid}`, {}, 'GET')
        .then(data => {
          let checked_input = flat_input;
          let invalidClass = 'is-invalid';
          let validClass = 'is-valid'
          if (!flat) {
            checked_input = build_input;
            invalidClass = 'is-invalid form-control h-100 p-0';
            validClass = 'is-valid form-control h-100 p-0'
          }

          if (data.length > 0) {
            checked_input.removeClass(validClass).addClass(invalidClass);
            let user_btn = jQuery('<a></a>').attr('href', `?get_index=form_users&full=1&UID=${data[0].uid}`)
              .text(data[0].login).attr('target', '_blank');
            let warning_text = `_{USER_ADDRESS_EXIST}_. _{LOGIN}_: `;
            checked_input.parent().find('.invalid-feedback').first().text(warning_text).append(user_btn);
          }
          else {
            checked_input.removeClass(invalidClass).addClass(validClass);
          }
        });
    }, 500);
  });

</script>
