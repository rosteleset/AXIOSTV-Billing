<form action='$SELF_URL' method='POST' name='CRM_COMPETITORS_TP' id='CRM_COMPETITORS_TP'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' id='COMPETITOR_TP_ID' name='ID' value='%ID%'>
  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{COMPETITORS_TP}_</h4>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{COMPETITOR}_:</label>
            <div class='col-md-8'>
              %COMPETITORS_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{NAME}_:</label>
            <div class='col-md-8'>
              <input type='text' class='form-control' placeholder='_{NAME}_' name='NAME' id='NAME' value='%NAME%'/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{DAY_FEE}_:</label>
            <div class='col-md-8'>
              <input type='number' class='form-control' placeholder='_{DAY_FEE}_' name='DAY_FEE' id='DAY_FEE'
                     value='%DAY_FEE%'/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{MONTH_FEE}_:</label>
            <div class='col-md-8'>
              <input type='number' class='form-control' placeholder='_{MONTH_FEE}_' name='MONTH_FEE' id='MONTH_FEE'
                     value='%MONTH_FEE%'/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{SPEED}_:</label>
            <div class='col-md-8'>
              <input type='number' class='form-control' placeholder='_{SPEED}_' name='SPEED' id='SPEED'
                     value='%SPEED%'/>
            </div>
          </div>
        </div>
        <div class='card-footer'>
          <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
        </div>
      </div>
    </div>
    <div class='col-md-6'>
      <div class='row'>
        <div class='col-md-12' id='geolocation-tree'>
          <div class='card card-primary card-outline' id='geolocation-card-container'>
            <div class='card-header with-border'>
              <h4 class='card-title'>_{LOCALITIES_OF_THE_TP}_</h4>
            </div>
            <div class='card-body' id='geolocation-card-body'>
              %GEO_MESSAGE%
            </div>
          </div>
        </div>
        <div class='col-md-12'>
          <div class='card card-primary card-outline collapsed-card'>
            <div class='card-header with-border'>
              <h3 class='card-title'>_{INFO_FIELDS}_</h3>
              <div class='card-tools float-right'>
                <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                  <i class='fa fa-plus'></i>
                </button>
              </div>
            </div>
            <div class='card-body'>
              %INFO_FIELDS%
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
</form>

<script>
  let competitor_sel = jQuery('#COMPETITOR_ID');

  function createOverlay(divId) {
    let overlay = document.createElement('div');
    overlay.id = 'overlay-container';
    overlay.classList.add('dark');
    overlay.classList.add('overlay');

    let spin = document.createElement('i');
    spin.classList.add('fa');
    spin.classList.add('fa-3x');
    spin.classList.add('fa-sync');
    spin.classList.add('fa-spin');

    overlay.appendChild(spin);

    document.getElementById(divId).appendChild(overlay);
  }

  function loadGeolocation() {

    let competitor_id = competitor_sel.val();
    if (!jQuery('#COMPETITOR_TP_ID').val() || !competitor_id) {
      removeOverlay();
      return;
    }

    createOverlay('geolocation-card-container');

    fetch('$SELF_URL?header=2&get_index=crm_tp_geolocation_tree&chg=%ID%&PRINT_JSON=1&COMPETITOR_ID=' + competitor_id)
      .then(response => {
        if (!response.ok) throw response;

        removeOverlay();
        return response;
      })
      .then(function (response) {
        try {
          return response.text();
        } catch (e) {
          console.log(e);
        }
      })
      .then(result => {
        if (result.includes('_{ERROR}_')) {
          jQuery('#geolocation-card-body').html(result);
        } else {
          jQuery('#geolocation-tree').html(result);
        }
      })
      .catch(err => {
        console.log(err);
      });
  }

  function removeOverlay() {
    let overlay = document.getElementById('overlay-container');
    if (overlay) overlay.remove();
  }

  if (competitor_sel.val()) loadGeolocation();
</script>

