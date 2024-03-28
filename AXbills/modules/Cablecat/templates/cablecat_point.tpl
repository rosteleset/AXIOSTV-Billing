<hr/>

<div class='form-group row'>
  <label class='col-md-4 col-form-label text-md-right' for='CREATED_ID'>_{CREATED}_:</label>
  <div class='col-md-8'>
    <input id='CREATED_ID' type='text' name='CREATED' value='%CREATED%' class='datepicker form-control d-0-9'>
  </div>
</div>

<div class='form-group row'>
  <label class='col-md-4 col-form-label text-md-right' for='PLANNED_ID'>_{PLANNED}_:</label>
  <div class='col-md-8'>
    <div class='form-check'>
      <input type='checkbox' data-return='1' data-checked='%PLANNED%' name='PLANNED' id='PLANNED_ID'>
    </div>
  </div>
</div>

<div class='form-group row'>
  <label class='col-md-4 col-form-label text-md-right' for='COMMENTS_ID'>_{COMMENTS}_:</label>
  <div class='col-md-8'>
    <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_ID'>%COMMENTS%</textarea>
  </div>
</div>