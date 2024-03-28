<div class='col-md-6'>
  <div class='card card-primary card-outline box-big-form'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{SERVICE}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool btn-xs' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>

    <div class='card-body'>
      <div class='form-group row'>
        <label class='control-label col-md-3' for='SERVICE_ID'>_{SERVICE}_:</label>
        <div class='col-md-9'>
          %SERVICE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='TP_ID'>_{TARIF_PLAN}_ (ID):</label>
        <div class='col-md-9'>
          <input id='TP_ID' name='TP_ID' value='%TP_ID%' placeholder='%TP_ID%' class='form-control'
                 type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='SERVICE_STATUS'>_{STATUS}_:</label>
        <div class='col-md-9'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='ID'>ID:</label>
        <div class='col-md-9'>
          <input id='ID' name='ID' value='%ID%' placeholder='%ID%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='SERVICES' style='padding-right: 0'>_{SERVICES}_ (>,<)</label>
        <div class='col-md-9'>
          <input id='SERVICES' name='SERVICES' value='%SERVICES%' class='form-control'
                 type='text'>
        </div>
      </div>
    </div>
  </div>
</div>