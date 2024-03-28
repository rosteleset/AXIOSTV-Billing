<div class='well well-sm'>

  <form name='MSGS_EMPLOYEES_TASKS' id='form_MSGS_EMPLOYEES_TASKS' method='post' class='form form-inline'>
    <input type='hidden' name='index' value='$index'/>


    <div class="form-group">
      <label class='control-label required' for='AID'>_{ADMIN}_</label>
      %AID_SELECT%
    </div>


    <div class="form-group">
      <label class='control-label' for='DATE_TYPE'>_{STATE}_</label>
      %DATE_TYPE_SELECT%
    </div>

    <div class="form-group">
      <label class='control-label' for='DATE_id'>_{DATE}_ </label>
      <input type='text' class='form-control datepicker' name='DATE' id='DATE_id' placeholder='$DATE'
             value='$FORM{DATE}'/>
    </div>


    <input type='submit' class='btn btn-primary' name='action' value='_{SHOW}_'/>

  </form>

</div>