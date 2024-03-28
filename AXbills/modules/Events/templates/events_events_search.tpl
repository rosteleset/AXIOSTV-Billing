<div class='card card-primary card-outline card-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{SEARCH}_ : _{EVENTS}_</h4></div>
  <div class='card-body'>

    <div class='form-group row'>
      <label class='control-label col-md-3' for='MODULE'>_{MODULE}_</label>
      <div class='col-md-9'>
        <input class='form-control' type='text' id='MODULE' name='MODULE'/>
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-3' for='STATE'>_{ADMIN}_</label>
      <div class='col-md-9'>
        %AID_SELECT%
      </div>
    </div>

    <div class='form-group row'>
      <div class='row'>
        <label class='control-label col-md-3'>_{CREATED}_</label>
        <div class='col-md-4'>
          <input class='form-control datepicker' type='text' name='FROM_DATE' value='%FROM_DATE%'/>
        </div>
        <div class="col-sm-1">
          <p class='form-control-static'>-</p>
        </div>
        <div class='col-md-4'>
          <input class='form-control datepicker' type='text' name='TO_DATE' value='%TO_DATE%'/>
        </div>
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-3' for='STATE'>_{STATE}_</label>
      <div class='col-md-9'>
        %STATE_SELECT%
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-3' for='PRIORITY'>_{PRIORITY}_</label>
      <div class='col-md-9'>
        %PRIORITY_SELECT%
      </div>
    </div>

    <div class='form-group row'>
      <label class='control-label col-md-3' for='GROUP'>_{GROUP}_</label>
      <div class='col-md-9'>
        %GROUP_SELECT%
      </div>
    </div>

  </div>
</div>
