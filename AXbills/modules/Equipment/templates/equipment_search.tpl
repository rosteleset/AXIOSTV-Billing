<div class='card card-primary card-outline'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{EQUIPMENT}_ _{SEARCH}_</h4>
  </div>
  <div class='card-body'>
    <div class='form-group row'>
      <label for='NAS_NAME' class='col-md-4 col-form-label text-md-right'>_{NAME}_:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='NAS_NAME' placeholder='%NAS_NAME%' name='NAS_NAME'
               value='%NAS_NAME%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='NAS_IP' class='col-md-4 col-form-label text-md-right'>IP:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='NAS_IP' placeholder='%NAS_IP%' name='NAS_IP'
               value='%NAS_IP%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='NAS_DESCR' class='col-md-4 col-form-label text-md-right'>_{DESCRIBE}_:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='NAS_DESCR' placeholder='%NAS_DESCR%' name='NAS_DESCR'
               value='%NAS_DESCR%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='SYSTEM_ID' class='col-md-4 col-form-label text-md-right'>System info:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='SYSTEM_ID' placeholder='%SYSTEM_ID%' name='SYSTEM_ID'
               value='%SYSTEM_ID%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='MODEL_ID' class='col-md-4 col-form-label text-md-right'>_{MODEL}_:</label>
      <div class='col-md-8'>
        %MODEL_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label for='FIRMWARE' class='col-md-4 col-form-label text-md-right'>FIRMWARE:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='FIRMWARE' placeholder='%FIRMWARE%' name='FIRMWARE'
               value='%FIRMWARE%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='PORTS' class='col-md-4 col-form-label text-md-right'>_{PORTS}_:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='PORTS' placeholder='%PORTS%' name='PORTS' value='%PORTS%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='FREE_PORTS' class='col-md-4 col-form-label text-md-right'>_{FREE_PORTS}_:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='FREE_PORTS' placeholder='%FREE_PORTS%' name='FREE_PORTS'
               value='%FREE_PORTS%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='SERIAL' class='col-md-4 col-form-label text-md-right'>_{SERIAL}_:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='SERIAL' placeholder='%SERIAL%' name='SERIAL'
               value='%SERIAL%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='START_UP_DATE' class='col-md-4 col-form-label text-md-right'>_{START_UP_DATE}_:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='START_UP_DATE' placeholder='%START_UP_DATE%'
               name='START_UP_DATE' value='%START_UP_DATE%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='STATUS' class='col-md-4 col-form-label text-md-right'>_{STATUS}_:</label>
      <div class='col-md-8'>
        %STATUS_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label for='LAST_ACTIVITY' class='col-md-4 col-form-label text-md-right'>_{LAST_ACTIVITY}_:</label>
      <div class='col-md-8'>
        <input type=text class='form-control datepicker' id='LAST_ACTIVITY' placeholder='%LAST_ACTIVITY%'
               name='LAST_ACTIVITY' value='%LAST_ACTIVITY%'>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='COMMENTS' placeholder='%COMMENTS%' name='COMMENTS'
               value='%COMMENTS%'>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='GID'>_{GROUPS}_:</label>
      <div class='col-md-8'>
        %NAS_GROUPS_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='USER_MAC'>_{USER}_ MAC:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='USER_MAC' placeholder='%USER_MAC%' name='USER_MAC'
               value='%USER_MAC%'>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='EQUIPMENT_MAC'>_{EQUIPMENT}_ MAC:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='EQUIPMENT_MAC' placeholder='%EQUIPMENT_MAC%' name='EQUIPMENT_MAC'
               value='%EQUIPMENT_MAC%'>
      </div>
    </div>
  </div>
</div>
<div class='card card-primary card-outline'>
  <div class='card-body'>
    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='S_VLAN'>SVLAN:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='S_VLAN' placeholder='%S_VLAN%' name='S_VLAN'
               value='%S_VLAN%'>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='C_VLAN'>CVLAN:</label>
      <div class='col-md-8'>
        <input type=text class='form-control' id='C_VLAN' placeholder='%C_VLAN%' name='C_VLAN'
               value='%C_VLAN%'>
      </div>
    </div>
  </div>
</div>

