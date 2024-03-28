<form action=$SELF_URL method=post>

  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='ID' value='%ID%'>

  <div class='card card-primary card-outline container-md'>

    <div class='card-header with-border text-center'><h4 class='card-title'>_{ADD}_ _{DEPARTMENT}_</h4></div>

    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{DEPARTMENT}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' required>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{POSITIONS}_:</label>
        <div class='col-md-8'>
          %POSITIONS%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' name='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <button class='btn btn-primary' type='submit' name="%ACTION%" value="%ACTION_LANG%">%ACTION_LANG%</button>
    </div>

  </div>

</form>