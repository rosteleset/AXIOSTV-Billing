<div class='card'>
  <div class='card-header with-border'><h4 class='card-title'>%TITLE%</h4></div>
  <div class='card-body'>
        <form name='%INPUT_NAME%' id='form_%INPUT_NAME%' method='post' class='form form-horizontal'>
        <input type='hidden' name='change' value='1' />
        <input type='hidden' name='enter_more' value='%INPUT_NAME%' />
        <input type='hidden' name='PHONE' value='%PHONE%' />
        <input type='hidden' name='EMAIL' value='%EMAIL%' />
        <input type='hidden' name='index' value='$index' />

      <div class='form-group'>
        <label class='control-label col-md-3' for='%INPUT_NAME%_ID'>_{CODE}_:</label>
        <div class='col-md-6'>
            <input type='text' class='form-control' value='' name='%INPUT_NAME%'  id='%INPUT_NAME%_ID'  />
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
      <input type='submit' form='form_%INPUT_NAME%' class='btn btn-primary' name='submit' value='_{CONFIRM}_'>
  </div>
</div>
