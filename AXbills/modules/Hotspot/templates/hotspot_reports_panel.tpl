<div class='well well-sm'>
  <form method='get' name='HOTSPOT_REPORTS_FORM' class='form form-inline'>
    <input type='hidden' name='index' value='$index'/>

    <div class="form-group float-left" data-visible="%FILTER_VISIBLE%">
      <label for='FILTER'>_{FILTER}_</label>
      %FILTER_SELECT%
    </div>

    <div class="form-group">
      <label for='DATE_START'>_{DATE}_</label>
      <input type='text' class='form-control datepicker' name='DATE_START' id='DATE_START' value='%DATE_START%'/>
    </div>

    <div class="form-group">
      <label for='DATE_END'>-</label>
      <input type='text' class='form-control datepicker' name='DATE_END' id='DATE_END' value='%DATE_END%'/>
    </div>

    <input type='submit' class='btn btn-primary' value='_{SHOW}_'/>
  </form>
</div>