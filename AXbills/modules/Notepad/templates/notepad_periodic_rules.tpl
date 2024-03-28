<div class='form-group'>
  <label class='control-label col-md-3'>_{PERIODICALLY}_</label>
  <div class='col-md-9'>
    %RULE_ID_SELECT%
  </div>
</div>

<!--Holidays checkbox-->
<div class='checkbox text-center show-hide-group' id='holidays_wrapper' style='display: none;'>
  <label>
    <input type='checkbox' data-return='1' data-checked='%HOLIDAYS%' name='HOLIDAYS' id='INCLUDING_HOLIDAYS'
           value='1'/>
    <strong>_{HOLIDAY}_</strong>
  </label>
</div>


<!--Month day select-->
<div class='form-group'>

  <div class='col-md-4 show-hide-group' id='mday_wrapper' style='display: none'>
    <input type='text' class='form-control' name='MONTH_DAY' value='%MONTH_DAY%'
           data-tooltip='_{DAY}_ : 1 <br /> _{DAYS}_ : 1,2,3,6'
           data-tooltip-position='left'
           placeholder='_{DAY}_'/>
  </div>

  <div class='col-md-4 show-hide-group' id='month_wrapper' style='display: none'>
    %MONTH_SELECT%
  </div>

  <!--
          <div class='col-md-4 show-hide-group' id='year_wrapper'>
            <input type='text' class='form-control' name='YEAR' value='%YEAR%' placeholder='_{YEAR}_'/>
          </div>
  -->
</div>


<!--Weekday select-->
<div class='form-group show-hide-group' id='weekday_wrapper' style='display: none;'>

  <label class='control-label col-md-3'>_{DAY}_ _{WEEK}_</label>
  <div class='col-md-9'>
    %WEEK_DAY_SELECT%
  </div>
</div>

<script src='/styles/default/js/modules/notepad/periodic.js'></script>

<hr/>
