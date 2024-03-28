<div class='form-group'>
  <label class='col-md-12' for='PLAN_TIME'>_{EXECUTION}_:</label>
  <div class='col-md-12'>
    <input type='hidden' value='%PLAN_TIME%' name='PLAN_TIME' id='PLAN_TIME'/>
    <input type='hidden' value='%PLAN_DATE%' name='PLAN_DATE' id='PLAN_DATE'/>
    %PLAN_DATETIME_INPUT%
  </div>
  <div class='col-md-12 mt-3'>
    <a data-link='$SELF_URL?%SHEDULE_TABLE_OPEN%' id='sheduleTableBtn' class='btn btn-secondary w-100'>
      <span class='fa fa-tasks my-1'></span>
      _{SCHEDULE_BOARD}_
    </a>
  </div>
</div>