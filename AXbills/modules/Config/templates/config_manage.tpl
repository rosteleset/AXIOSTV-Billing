<form action=$SELF_URL METHOD=post>
<input type=hidden name=index value='%index%'>

<div class='card card-primary card-outline container-md'>
  <div class='card-header'>
    <h3 class='card-title'>_{CONFIGURATION}_ %LNG_ACTION%</h3>
  </div>
  <div class='card-body'>

    <div class='form-group row'>
      <label class='col-form-label text-md-right col-md-4'>_{VARIABLE}_:</label>
      <div class='col-md-8'>
        <input type=text name=PARAM value='%PARAM%' size=30 class='form-control'>
      </div>
    </div>
    <div class='form-group row'>
      <label class='col-form-label text-md-right col-md-4'>_{TYPE}_</label>
      <div class='col-md-8'>
        %TYPE_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-form-label text-md-right col-md-4'>_{DEFAULT_VALUE}_</label>
      <div class='col-md-8'>
        %VALUE_INPUT%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-form-label text-md-right col-md-4'>REGEX</label>
      <div class='col-md-8'>
        <input type=text name=REGEX value='%REGEX%' size=30 class='form-control' %IS_DISABLED%>
      </div>
    </div>
  </div>

  <div class='card-footer'>
    <button type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>%LNG_ACTION%</button>
  </div>
</div>

</form>
