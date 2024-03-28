<div class='col-md-6'>
  <div class='card card-primary card-outline box-big-form'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{SERVICE}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TP_ID'>_{TARIF_PLAN}_ (ID):</label>
        <div class='col-md-8'>
          %TP_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SERVICE_STATUS'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='FILTER_ID'>FILTER ID (*):</label>
        <div class='col-md-8'>
          <input id='FILTER_ID' name='FILTER_ID' value='%FILTER_ID%' placeholder='%FILTER_ID%' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SERVICE_ID'>_{SERVICE}_:</label>
        <div class='col-md-8'>
          %SERVICE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='CID'>MAC(Modem):</label>
        <div class='col-md-8'>
          <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DVCRYPT_ID'>DV Crypt(*):</label>
        <div class='col-md-8'>
          <input id='DVCRYPT_ID' name='DVCRYPT_ID' value='%DVCRYPT_ID%' placeholder='%DVCRYPT_ID%' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ID'>ID:</label>
        <div class='col-md-8'>
          <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SERVICES'>_{SERVICES}_ (>,<):</label>
        <div class='col-md-8'>
          <input id='SERVICES' name='SERVICES' value='%SERVICES%' class='form-control'
                 type='text'>
        </div>
      </div>

    </div>
  </div>
</div>

<div class='col-md-6'>
  <div class='card card-primary card-outline box-big-form collapsed-card'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{SCREENS}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-plus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='MAC_CID'>MAC/CID:</label>
        <div class='col-md-8'>
          <input id='MAC_CID' name='MAC_CID' value='%MAC_CID%' placeholder='%MAC_CID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SERIAL'>_{SERIAL}_:</label>
        <div class='col-md-8'>
          <input id='SERIAL' name='SERIAL' value='%SERIAL%' placeholder='%SERIAL%' class='form-control' type='text'>
        </div>
      </div>

    </div>
  </div>
</div>

<script>
  let tp_select = document.getElementById('TP_ID');
  if (!tp_select.value) autoReload();

  function autoReload() {
    let services = document.getElementById('SERVICE_ID');
    let result = services.value;
    jQuery.post('$SELF_URL', 'header=2&get_index=iptv_get_service_tps&SERVICE_ID=' + result, function (data) {
      tp_select.textContent = '';
      tp_select.value = '';
      tp_select.innerHTML = data;
      tp_select.focus();
    });
  }
</script>