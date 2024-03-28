<div class='card-body p-0'>
  <div class='form-group row'>
    <label class='col-md-3 col-form-label text-md-right'>_{DURATION}_:</label>
    <div class='col-md-9'>
      <div class='d-flex bd-highlight'>
        <div class='bd-highlight'>
          <input class='form-control' value='%HOURS%' id='HOURS' type='number' max='12' min='0' step='1'>
        </div>
        <div class='p-2 pl-0  bd-highlight'>_{MSGS_HOURS}_</div>
        <div class='bd-highlight'>
          <input class='form-control' value='%MINUTES%' id='MINUTES' type='number' max='60' min='0' step='1'>
        </div>
        <div class='p-2 pl-0 bd-highlight'>_{MSGS_MINUTES}_</div>
      </div>
    </div>
  </div>
</div>
<div class='card-footer'>
  <button class='btn btn-primary' id='SAVE_DURATION_POSITION'>_{SAVE}_</button>
</div>