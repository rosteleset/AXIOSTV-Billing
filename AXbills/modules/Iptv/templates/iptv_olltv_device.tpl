<div class='card card-primary card-outline'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{DEVICE}_</h4>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'><i class='fa fa-minus'></i>
      </button>
    </div>
  </div>
  <div class='card-body '>

    %STORAGE_FORM%

    <div class='form-group row'>
      <label class='control-label col-md-3' for='ID'>ID</label>
      <div class='col-md-3'>
        %ID%
      </div>

      <label class='control-label col-md-3' for='ID'>_{DATE}_</label>
      <div class='col-md-3'>
        %date_added%
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-3 required' for='SERIAL_NUMBER'>_{SERIAL}_</label>
      <div class='col-md-9'>
        <input id='SERIAL_NUMBER' name='SERIAL_NUMBER' value='%serial_number%' placeholder='%SERIAL_NUMBER%'
               class='form-control' type='text'>
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-3' for='DEVICE_TYPE'>_{DEVICE}_ _{TYPE}_</label>
      <div class='col-md-9'>
        %TYPE_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-3' for='DEVICE_ACTIVATION_TYPE'>_{ACTIVATE}_</label>
      <div class='col-md-9'>
        %DEVICE_ACTIVATION_TYPE_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-3' for='DEVICE_MODEL'>_{DEVICE}_ _{MODEL}_</label>
      <div class='col-md-8'>
        <input id='DEVICE_MODEL' name='DEVICE_MODEL' value='%DEVICE_MODEL%' placeholder='MAG255' class='form-control'
               type='text'>
      </div>
      <div class='col-md-1'>
        %DEVICE_DEL%
      </div>
    </div>

    %DEVICE_BINDING_CODE_FORM%

    <div class='form-group row'>
      <label class='control-label col-md-3' for='CID'>MAC (_{DELISMITER}_ ;):</label>
      <div class='col-md-9'>
        <input id='CID' name='CID' value='%CID%' placeholder='%CID%' class='form-control' type='text'>
        <!--  %SEND_MESSAGE% -->
      </div>
    </div>

  </div>
</div>
