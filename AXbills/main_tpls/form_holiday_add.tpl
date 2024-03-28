<form name='holiday' id='form_holiday' method='post' class='form form-horizontal'>
        <input type='hidden'  name='index' value='$index'>
        <input type='hidden'  name='month' value='%NUMBER_MONTH%'>
        <input type='hidden'  name='year'  value='%YEAR%'>

<div class='card card-primary card-outline box-form'>

    <div class='card-header with-border'><h4 class='card-title'>_{HOLIDAYS}_ _{DAY}_</h4></div>
  <div class='card-body'>
      
      <div class='form-group'>
          <label class='control-label col-md-3 required' for='DAY_id'>_{DAY}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control'  required name='DAY'  id='DAY_id' value='%DAY%' readonly>
        </div>
      </div>

      <div class='form-group'>
          <label class='control-label col-md-3 required' for='MONTH_id'>_{MONTH}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control'  required name='MONTH'  id='MONTH_id' value='%MONTH%' readonly>
        </div>
      </div>

      <div class='form-group'>
          <label class='control-label col-md-3' for='MONTH_id'>_{FILE}_</label>
        <div class='col-md-7'>
          %FILE_SELECT%
        </div>
        <div class='col-md-2'>
          <a href='%UPLOAD_FILE%' class='btn btn-primary'>
            <span class='fa fa-plus' aria-hidden='true'></span>
          </a>
        </div>
        </div>      

      <div class='form-group'>
          <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control'  rows='5'  name='COMMENTS'  id='COMMENTS_id' >%COMMENTS%</textarea>
        </div>
      </div>

  </div>
  
  <div class='card-footer'>
      <button type='submit' form='form_holiday' class='btn btn-primary' name='action' value='%ACTION%'>
        %BTN_NAME%
      </button>
  </div>

</div>

</form>
            