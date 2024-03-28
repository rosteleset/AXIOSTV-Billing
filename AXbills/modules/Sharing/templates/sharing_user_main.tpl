<form method='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='TABLE_FILE' value='$FORM{TABLE_FILE}'>

<div class='card'>
  <div class='card-header align-items-center row text-center'>
    <label class='col-3 mb-0'>_{GROUP}_</label>
    <div class='col-5'>%GROUP_SELECT%</div>
    <div class='col-4'>%BUTTON_STYLE%</div>
  </div>
</div>

<div class='%ROW%'>
  %FILES%
</div>

</form>