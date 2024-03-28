<div class='col-md-6'>
  <div class='card card-primary card-outline'>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{SERIAL}_ (*):</label>
        <div class='col-md-9'><input class='form-control' type='text' name='SERIAL' value='%SERIAL%' size=8/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'> _{NUM}_ (<,>): </label>
        <div class='col-md-9'><input class='form-control' type='text' name='NUMBER' value='%NUMBER%'></div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>PIN:</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='PIN' value='%PIN%'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{SUM}_:</label>
        <div class='col-md-9'>
          <input class='form-control' type='text' name='SUM' value='%SUM%' size=8/>
        </div>
      </div>
    </div>
  </div>
</div>

<div class='col-md-12'>
  <div class='card card-primary card-outline'>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-sm-3 col-md-3 control-label' for='REGISTRATION'>_{USED}_:</label>
        <div class='col-md-3'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' class='form-control-static' data-input-enables='USED_FROM_DATE_USED_TO_DATE'/>
              </span>
            </div>
            %DATE%
          </div>
        </div>

        <div class='col-md-6 row'>
          <label class='col-md-3 control-label'>_{EXPIRE}_:</label>
          <div class='col-md-9'>%EXPIRE_DATE%</div>
        </div>

      </div>


      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{DILLERS}_:</label>
        <div class='col-md-3'>%DILLERS_SEL%</div>

        <div class='col-md-6 row'>
          <label class='col-md-3 control-label'>_{ADMINS}_:</label>
          <div class='col-md-9'>%ADMINS_SEL%</div>
        </div>
      </div>

      <div class='card card-outline collapsed-card'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{EXTRA}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{STATUS}_:</label>

            <div class='col-md-9'>%STATUS_SEL%</div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>ID:</label>

            <div class='col-md-9'>
              <input class='form-control' type='text' name='ID' value='%ID%' size=8>
            </div>
          </div>
          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{DOMAIN}_:</label>

            <div class='col-md-9'>%DOMAIN_SEL%</div>
          </div>

        </div>
      </div>
    </div>
  </div>
</div>


