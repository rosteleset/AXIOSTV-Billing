<form action=$SELF_URL METHOD=POST class='form-horizontal'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='action' value='%ACTION%'>
<input type='hidden' name='id' value=%ID%>
<input type='hidden' name='wtch' value=%wtch%>


  <div class='card box-primary  box-horizontal'>
    <div class='card-header with-border'><div class='card-title'>_{EMPLOYEE_PROFILE}_ </div><p class='float-right'>%rating_icons%</p> </div>
    <div class='card-body'>

    <div class='form-group'>
    <label class='control-element col-md-3'>_{FIO}_</label>
    <div class='col-md-9'>
      %FIO%
    </div>
    </div>

    <div class='form-group'>
    <label class='control-element col-md-3'>_{BIRTHDAY}_</label>
    <div class='col-md-9'>
      %DATE_OF_BIRTH%
    </div>
    </div>

    <div class='form-group'>
    <label class='control-element col-md-3'>_{MAIL_BOX}_</label>
    <div class='col-md-9'>
      %EMAIL%
    </div>
    </div>

    <div class='form-group'>
    <label class='control-element col-md-3'>_{PHONE}_</label>
    <div class='col-md-9'>
      %PHONE%
    </div>
    </div>

    <div class='form-group'>
    <label class='control-element col-md-3'>_{POSITION}_</label>
    <div class='col-md-9'>
      %POSITION_NAME%
    </div>
    </div>

     <div class='form-group'>
    %QUESTION_TABLE%
    </div>
     <div class='form-group'>
    <label class='control-element col-md-1'>_{MARK}_</label>
    <div class='col-md-4'>
      %RATING%
    </div>
    <div class='col-md-4'>
        <input type='submit' class='btn btn-primary pull-center' name='add_rating' value='_{ADD}_'>
    </div>
    </div>
    </div>


    </div>
  </div>
</form>
