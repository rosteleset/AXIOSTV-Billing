<form action='$SELF_URL' id='storage_installation_form' name='storage_installation_name' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{ARTICLE}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COUNT_id'>_{COUNT}_:</label>
        <div class='col-md-8'><input class='form-control' name='COUNT' id='COUNT_id' value='%COUNT%' type='number'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='DATE_id'>_{DATE}_:</label>
        <div class='col-md-8'>
          <input class='form-control datepicker' name='DATE' id='DATE_id' value='%DATE%' type='text'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' name='COMMENTS' id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{SERIAL}_:</label>
        <div class='col-md-8'><textarea class='form-control' name='SERIAL'>%SERIAL%</textarea></div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{RESPOSIBLE}_ _{FOR_INSTALLATION}_:</label>
        <div class='col-md-8'>
          %INSTALLED_AID_SEL%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{NAS}_:</label>
        <div class='col-md-8'>%NAS%</div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LOGIN'>_{USER}_:</label>
        <input type=hidden name=UID id='UID_HIDDEN' value='%UID%'/>
        <div class='col-md-8'>
          <div class='input-group'>
            <input type='text' form='unexistent' class='form-control' name='LOGIN' value='%USER_LOGIN%' id='LOGIN'
                   readonly='readonly'/>
            <div class='input-group-append'>
              %USER_SEARCH%
            </div>
          </div>
        </div>
      </div>

      <div id='address_form_source'>
        %ADDRESS_FORM%
      </div>
    </div>
    <div class='card-footer'>
      <input type=submit name=install value='_{INSTALL}_' class='btn btn-primary'>
    </div>
  </div>
</form>
