<form name='report_panel' id='report_panel' method='get'>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'/>

  <div class='form-row align-items-center justify-content-center my-3'>
    <div class='col-sm-3 my-1'>
      <label class='sr-only' for='FILTER'>_{FILTERS}_: </label>
      <input type='text' placeholder="_{FILTERS}_" name='FILTER' value='%FILTER%' class='form-control' id='FILTER'>
    </div>

    <div class='col-sm-3 my-1'>
      <label class='sr-only' for='FILTER_FIELD'>_{FIELDS}_: </label>
      <div style='min-width: 150px'>
        %FIELDS_SEL%
      </div>
    </div>

    <div class='col-auto my-1'>
      <label class='sr-only' for='REFRESH'>_{REFRESH}_ (sec): </label>
      <input type='text' placeholder='_{REFRESH}_ (sec):' name='REFRESH' value='%REFRESH%'  class='form-control' id='REFRESH'>
    </div>

    <div class='col-auto my-1'>
      <input type='SUBMIT' name='SHOW' value='_{SHOW}_' class='btn btn-primary' id='SHOW'>
    </div>
  </div>
</form>