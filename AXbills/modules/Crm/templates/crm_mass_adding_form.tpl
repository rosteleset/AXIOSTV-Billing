<form action='$SELF_URL' class='form-horizontal' METHOD='POST'>
  <input type=hidden name='index' value='$index'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{CRM_MASS_ADDING}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{DISTRICT}_:</label>
        <div class='col-md-8'>
          %DISTRICTS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{STREET}_:</label>
        <div class='col-md-8'>
          %STREETS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{RANGE}_:</label>
        <div class='col-md-4 pt-2'>
          <div class='form-check'>
            <input class='form-check-input' disabled type='radio' id='build-range' value='1' name='range'>
            <label class='form-check-label' for='build-range'>_{BUILDS}_</label>
          </div>
        </div>
        <div class='col-md-4 pt-2'>
          <div class='form-check'>
            <input class='form-check-input' disabled type='radio' id='flat-range' value='2' name='range'>
            <label class='form-check-label' for='flat-range'>_{FLATS}_</label>
          </div>
        </div>
      </div>

      <hr>

      <div class='form-group row hidden' id='BUILDS_SELECT_CONTAINER'>
        <label class='col-form-label text-md-right col-md-4'>_{BUILD}_:</label>
        <div class='col-md-8' id='BUILD_CONTAINER'>
          %BUILDS_SEL%
        </div>
      </div>

      <div class='form-group row hidden' id='FLATS_RANGE_CONTAINER'>
        <label class='col-form-label text-md-right col-md-4'>_{FLATS}_:</label>
        <div class='col-md-3'>
          <input id='FLAT_START' name='FLAT_START' min='0' placeholder='0' class='form-control' type='number' disabled>
        </div>
        <div class='col-md-2 pt-2 text-center'>-</div>
        <div class='col-md-3'>
          <input id='FLAT_END' name='FLAT_END' min='0' placeholder='10' class='form-control' type='number' disabled>
        </div>
      </div>

      <div class='form-group row hidden' id='BUILDS_RANGE_CONTAINER'>
        <label class='col-form-label text-md-right col-md-4'>_{BUILDS}_:</label>
        <div class='col-md-3'>
          <input id='BUILD_START' name='BUILD_START' min='0' placeholder='0' class='form-control' type='number' disabled>
        </div>
        <div class='col-md-2 pt-2 text-center'>-</div>
        <div class='col-md-3'>
          <input id='BUILD_END' name='BUILD_END' min='0' placeholder='10' class='form-control' type='number' disabled>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <button type='submit' class='btn btn-primary' name='add' value='add'>_{ADD}_</button>
    </div>
  </div>
</form>

<script>
  jQuery(function () {
    let street_select = jQuery('#STREET_ID');
    let radio_buttons = jQuery("input[name='range']");

    jQuery('#DISTRICT_ID').on('change', function () {
      if (!jQuery(this).val()) return;

      let url = 'index.cgi?get_index=form_address_select2&header=2&DISTRICT_ID=' + jQuery(this).val() + '&STREET=1';
      fetch(url)
        .then(response => {
          if (!response.ok) throw response;
          return response;
        })
        .then(response => response.text())
        .then(result => {
          street_select.html(result);
          initChosen();
          street_select.focus();
          street_select.select2('open');
        })
        .catch(err => {
          console.log(err);
        });
    });

    street_select.on('change', function () {
      if (!jQuery(this).val() || jQuery(this).val() === '0') {
        offAllRange();
        radio_buttons.attr('disabled', '1');
        return;
      }

      radio_buttons.removeAttr('disabled');
      getBuildSelect(jQuery(this).val());

      let radio_checked = jQuery("input[name='range']:checked");
      if (radio_checked.val() === '1') showBuildsRange();
      else if (radio_checked.val() === '2') showFlatsRange();
    });

    jQuery('#FLAT_START').on('change', function () {
      if (!jQuery(this).val()) return;
      jQuery('#FLAT_END').attr('min', jQuery(this).val());
    });

    jQuery('#BUILD_START').on('change', function () {
      if (!jQuery(this).val()) return;
      jQuery('#BUILD_END').attr('min', jQuery(this).val());
    });

    radio_buttons.on('click', function(){
      if (!jQuery(this).val()) return;

      if (jQuery(this).val() === '1') showBuildsRange();
      else if (jQuery(this).val() === '2') showFlatsRange();
    });

  }());

  function getBuildSelect(street_id) {
    let url = 'index.cgi?get_index=form_address_select2&header=2&STREET_ID=' + street_id + '&BUILD=1';
    fetch(url)
      .then(response => {
        if (!response.ok) throw response;
        return response;
      })
      .then(response => response.text())
      .then(result => {
        let build_select = jQuery('#BUILD_ID');
        if (!build_select.length) {
          jQuery('#BUILD_CONTAINER').append(result);
          build_select = jQuery('#BUILD_ID');
        }
        else {
          build_select.html(result);
        }

        build_select.removeAttr('onchange');
        initChosen();
      })
      .catch(err => {
        console.log(err);
      });
  }

  function showFlatsRange() {
    jQuery('#BUILDS_SELECT_CONTAINER').removeClass('hidden');
    jQuery('#FLATS_RANGE_CONTAINER').removeClass('hidden');

    jQuery('#FLAT_START').removeAttr('disabled');
    jQuery('#FLAT_END').removeAttr('disabled');

    jQuery('#BUILD_START').attr('disabled', '1');
    jQuery('#BUILD_END').attr('disabled', '1');

    jQuery('#BUILDS_RANGE_CONTAINER').addClass('hidden');
  }

  function showBuildsRange() {
    jQuery('#BUILDS_SELECT_CONTAINER').addClass('hidden');
    jQuery('#FLATS_RANGE_CONTAINER').addClass('hidden');

    jQuery('#FLAT_START').attr('disabled', '1');
    jQuery('#FLAT_END').attr('disabled', '1');

    jQuery('#BUILD_START').removeAttr('disabled');
    jQuery('#BUILD_END').removeAttr('disabled');

    jQuery('#BUILDS_RANGE_CONTAINER').removeClass('hidden');
  }

  function offAllRange() {
    jQuery('#BUILDS_SELECT_CONTAINER').addClass('hidden');
    jQuery('#FLATS_RANGE_CONTAINER').addClass('hidden');
    jQuery('#BUILDS_RANGE_CONTAINER').addClass('hidden');

    jQuery('#FLAT_START').attr('disabled', '1');
    jQuery('#FLAT_END').attr('disabled', '1');
    jQuery('#BUILD_START').attr('disabled', '1');
    jQuery('#BUILD_END').attr('disabled', '1');
  }
</script>