<div class='col-md-6'>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{INFO}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='FIO'>_{FIO}_:</label>
        <div class='col-sm-8 col-md-8'>
          <div class='input-group'>
            <input id='FIO' name='FIO' value='%FIO%' class='form-control' type='text'/>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <i class='fa fa-exclamation'></i>
                <input type='checkbox' name='FIO' id='_FIO' data-input-disables='FIO' value='!'>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='EMAIL'>E-Mail:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%' class='form-control' type='text' />
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='PHONE'>_{PHONE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%' class='form-control' type='text'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='CELL_PHONE'>_{CELL_PHONE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <div class='input-group'>
            <input id='CELL_PHONE' name='CELL_PHONE' value='%CELL_PHONE%' placeholder='%CELL_PHONE%' class='form-control'
                   type='text'/>
            <div class='input-group-append'>
              <div class='input-group-text'>
                <i class='fa fa-exclamation'></i>
                <input type='checkbox' name='CELL_PHONE' data-input-disables=CELL_PHONE value='!'>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='REGISTRATION'>_{REGISTRATION}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' id='REGISTRATION' class='form-control-static' data-input-enables='REGISTRATION_FROM_REGISTRATION_TO'/>
              </span>
            </div>
            %REGISTRATION_RANGE%
          </div>
        </div>

      </div>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='ACTIVATE'>_{ACTIVATE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='ACTIVATE' name='ACTIVATE' value='%ACTIVATE%' placeholder='%ACTIVATE%'
            class='form-control datepicker' type='text' />
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='EXPIRE'>_{EXPIRE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='EXPIRE' name='EXPIRE' value='%EXPIRE%' placeholder='%EXPIRE%' class='form-control datepicker'
            type='text' />
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='REDUCTION'>_{REDUCTION}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='REDUCTION' name='REDUCTION' value='%REDUCTION%' placeholder='%REDUCTION%' class='form-control'
                type='text' />
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='REDUCTIONDATE'>_{REDUCTION}_ _{DATE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='REDUCTIONDATE' name='REDUCTIONDATE' value='%REDUCTION_DATE%' placeholder='%REDUCTION_DATE%'
                class='form-control' type='text' />
        </div>
      </div>

      <div class='form-group row'>
          <label class='col-sm-4 col-md-4 control-label' for='DISABLE'>_{STATUS}_:</label>
        <div class='col-sm-8 col-md-8'>
        %DISABLE_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='DELETED'>_{DELETED}_:</label>
        <div class='col-sm-8 col-md-8'>
          %DELETE_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='COMPANY_ID'>_{COMPANY}_ ID:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='COMPANY_ID' name='COMPANY_ID' value='%COMPANY_ID%' placeholder='%COMPANY_ID%'
                 class='form-control' type='text' />
        </div>
      </div>


    </div>
  </div>
</div>

<div class='col-md-6'>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{PASPORT}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='PASPORT_NUM'>_{NUM}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%' placeholder='%PASPORT_NUM%'
                class='form-control' type='text' />
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='PASPORT_DATE'>_{DATE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='PASPORT_DATE' name='PASPORT_DATE' value='%PASPORT_DATE%' placeholder='%PASPORT_DATE%'
                class='form-control datepicker' type='text' />
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='PASPORT_GRANT'>_{GRANT}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='PASPORT_GRANT' name='PASPORT_GRANT' value='%PASPORT_GRANT%' placeholder='%PASPORT_GRANT%'
                class='form-control' type='text' />
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-4 col-md-4 control-label' for='BIRTH_DATE'>_{BIRTH_DATE}_:</label>
        <div class='col-sm-8 col-md-8'>
          <input id='BIRTH_DATE' name='BIRTH_DATE' value='%BIRTH_DATE%' placeholder='%BIRTH_DATE%' class='form-control'
                type='text' />
        </div>
      </div>
    </div>
  </div>
</div>

<div class='col-md-6'>
  <div class='card card-primary card-outline'>
    <div class='card-header with-border'>
      <h3 class='card-title'>_{INFO_FIELDS}_</h3>
      <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
          <i class='fa fa-minus'></i>
        </button>
      </div>
    </div>
  <div class='card-body'>
      %INFO_FIELDS%
  </div>
  </div>
</div>