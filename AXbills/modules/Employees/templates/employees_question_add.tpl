<form action=$SELF_URL METHOD=POST class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='action' value='%ACTION%'>
<input type='hidden' name='id' value=%ID%>
<input type='hidden' name='SORT_POSITION_ID' value=%SORT_POSITION_ID%>
<input type='hidden' name='CHANG_BUTTON_ID' value=%CHANG_BUTTON_ID%>



  <div class='card box-primary box-form box-horizontal'>
    <div class='card-header with-border'><div class='card-title'>_{ADD}_ _{QUESTION}_</div></div>
    <div class='card-body'>

    <div class='form-group'>
    <label class='control-element col-md-3'>_{QUESTION}_</label>
    <div class='col-md-9'>
      <textarea  required rows='3' class='form-control' name='QUESTION' value='%QUESTION%'>%QUESTION%</textarea>
    </div>
    </div>
    <div class='form-group'>
    <label class='control-element col-md-3'>_{POSITION}_</label>
    <div class='col-md-9'>
      %POSITION_SELECT%
    </div>
    </div>
    </div>

    <div class='card-footer'>
        <p class='text-center'><input class="btn btn-primary" name="%BUTTON_NAME%" value="%BUTTON_VALUE%" type="submit"></p>
    </div>
  </div>
%QUESTION_TABLE%
</form>
