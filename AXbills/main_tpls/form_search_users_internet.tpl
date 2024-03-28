<div class="col-md-6">
  <div class="card card-primary card-outline collapsed-card">
    <div class="card-header with-border">
      <h3 class="card-title">_{INFO}_</h3>
      <div class="card-tools pull-right">
        <button type="button" class="btn btn-tool" data-card-widget="collapse">
          <i class="fa fa-plus"></i>
        </button>
      </div>
    </div>
    <div class="card-body">
      <div class="form-group row">
        <label class="col-sm-4 col-md-4 control-label" for="UID">UID:</label>
        <div class="col-sm-8 col-md-8">
          <input id="UID" name="UID" value="%UID%" type="text" class="form-control" />
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 control-label" for="EMAIL">E-Mail:</label>
        <div class="col-sm-8 col-md-8">
          <input id="EMAIL" name="EMAIL" value="%EMAIL%" placeholder="%EMAIL%" class="form-control" type="text" />
        </div>
      </div>
      <div class="form-group row">
        <label class="col-sm-4 col-md-4 control-label" for="REGISTRATION">_{REGISTRATION}_:</label>
        <div class="col-sm-8 col-md-8">
          <input id="REGISTRATION" name="REGISTRATION" value="%REGISTRATION%" placeholder="%REGISTRATION%"
            class="form-control datepicker" type="text" />
        </div>
      </div>
      <div class="form-group row">
        <label class="col-sm-4 col-md-4 control-label" for="ACTIVATE">_{ACTIVATE}_:</label>
        <div class="col-sm-8 col-md-8">
          <input id="ACTIVATE" name="ACTIVATE" value="%ACTIVATE%" placeholder="%ACTIVATE%"
            class="form-control datepicker" type="text" />
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 control-label" for="EXPIRE">_{EXPIRE}_:</label>
        <div class="col-sm-8 col-md-8">
          <input id="EXPIRE" name="EXPIRE" value="%EXPIRE%" placeholder="%EXPIRE%" class="form-control datepicker"
            type="text" />
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 control-label" for="REDUCTION">_{REDUCTION}_:</label>
        <div class="col-sm-8 col-md-8">
          <input id="REDUCTION" name="REDUCTION" value="%REDUCTION%" placeholder="%REDUCTION%" class="form-control"
                type="text" />
        </div>
      </div>

      <div class="form-group row">
        <label class="col-sm-4 col-md-4 control-label" for="REDUCTION">_{REDUCTION}_ _{DATE}_:</label>
        <div class="col-sm-8 col-md-8">
          <input id="REDUCTIONDATE" name="REDUCTIONDATE" value="%REDUCTION_DATE%" placeholder="%REDUCTION_DATE%"
                class="form-control" type="text" />
        </div>
      </div>

      <div class="form-group row">
        <div class="form-check col-sm-5 col-md-5">
          <label class="control-label col-sm-9 col-md-9" for="DISABLE">_{DISABLE}_:</label>
          <input id="DISABLE" name="DISABLE" value="1" type="checkbox" />
        </div>
        <div class="form-check col-sm-7 col-md-7">
          <label class="control-label" for="DELETED">_{NOT_DELETED_USERS}_:</label>
          <input id="DELETED" name="DELETED" value="0" type="checkbox" />
        </div>
      </div>
    </div>
  </div>
</div>
