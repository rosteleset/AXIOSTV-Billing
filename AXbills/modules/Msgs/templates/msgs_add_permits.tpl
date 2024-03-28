<form name='add_permits' id='msgs_add_permits' method='post'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ADMIN_ID' value='%ADMIN_ID%'/>

  <div class='d-flex flex-sm-row flex-column justify-content-center d-flex align-items-center pt-2 pb-2'>
    %BUTTONS%
    <input type='text' name='TYPE' class='form-control mr-1 mb-1' style='max-width: 200px'>
    <input type='submit' form='msgs_add_permits' class='btn btn-success btn-sm mb-1' name='add_permits'
           value='_{SAVE}_ _{TEMPLATE}_'>
  </div>
  %PERMISSIONS_TABLE%
  <div class='d-flex flex-sm-row flex-column justify-content-end d-flex align-items-end pt-2 pb-2'>
  <input type='submit' form='msgs_add_permits' class='btn btn-primary' name='set' value='_{SAVE}_' style='display: block;'>
</div>
</form>
