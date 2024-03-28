<form id='form-search' name='nfrmSearchNAS' class='form-horizontal'>
  <input type='hidden' name='index' value='$index' form='form-search'/>
  <input type='hidden' name='POPUP' value='%POPUP%' form='form-search'/>
  <input type='hidden' name='NAS_SEARCH' value='1' form='form-search'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-body'>
      <div class='form-group row'>
        <label for='NAS_ID' class='col-md-4 col-form-label text-md-right'>ID:</label>
        <div class='col-md-8'>
          <input class='form-control' id='NAS_ID' placeholder='%NAS_ID%' name='NAS_ID' value='%NAS_ID%'
                 form='form-search'/>
        </div>
      </div>

      <div class='form-group row'>
        <label for='NAS_IP' class='col-md-4 col-form-label text-md-right'>IP:</label>
        <div class='col-md-8'>
          <input class='form-control' id='NAS_IP' placeholder='%NAS_IP%' name='NAS_IP' value='%NAS_IP%'
                 form='form-search'/>
        </div>
      </div>

      <div class='form-group row'>
        <label for='NAS_NAME' class='col-md-4 col-form-label text-md-right'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input class='form-control' id='NAS_NAME' placeholder='%NAS_NAME%' name='NAS_NAME'
                 value='%NAS_NAME%'
                 form='form-search'/>
        </div>
      </div>

      <div class='form-group row'>
        <label for='NAS_INDENTIFIER' class='col-md-4 col-form-label text-md-right'>Radius NAS-Identifier:</label>
        <div class='col-md-8'>
          <input class='form-control' id='NAS_INDENTIFIER' placeholder='%NAS_INDENTIFIER%'
                 name='NAS_INDENTIFIER'
                 value='%NAS_INDENTIFIER%' form='form-search'/>
        </div>
      </div>

      <div class='form-group row'>
        <label for='NAS_TYPE' class='col-md-4 col-form-label text-md-right'>_{TYPE}_:</label>
        <div class='col-md-8'>%SEL_TYPE%</div>
      </div>

      <div class='form-group row'>
        <label for='MAC' class='col-md-4 col-form-label text-md-right'>MAC:</label>
        <div class='col-md-8'>
          <input class='form-control' id='MAC' placeholder='%MAC%' name='MAC' value='%MAC%'
                 form='form-search'/>
        </div>
      </div>

      <div class='form-group row'>
        <label for='GID' class='col-md-4 col-form-label text-md-right'>_{GROUPS}_:</label>
        <div class='col-md-8'>%NAS_GROUPS_SEL%</div>
      </div>

      <div class='form-group row'>
        <label for='ADDRESS_FULL' class='col-md-4 col-form-label text-md-right'>_{ADDRESS}_:</label>
        <div class='col-md-8'>
          <input class='form-control' id='ADDRESS_FULL' placeholder='%ADDRESS_FULL%' name='ADDRESS_FULL' value='%ADDRESS_FULL%'
                 form='form-search'/>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      %SEARCH_BTN%
    </div>
  </div>
</form>
