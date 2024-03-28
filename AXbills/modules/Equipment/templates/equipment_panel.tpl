<style>
  select#NAS_ID {
    min-width: 300px;
    width : 100%;
  }
</style>

<FORM action='$SELF_URL' METHOD='POST' class='form-inline'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='visual' value='$FORM{visual}'>
  <fieldset>

    <div class='form-group'>
      <label for='NAS_ID'> _{NAS}_ :</label>
      %DEVICE_SEL%
    </div>
    <input type=submit name=show value='_{SHOW}_' class='btn btn-primary'>

  </fieldset>
</form>